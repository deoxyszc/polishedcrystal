; Bounded dialogue stable glyph run. Uses existing 12-byte name staging
; only while no dynamic-name call is active; no new WRAM allocation.
; HL=destination; wZhTextCursor/end own source. Same ROM bank.
ZhIsStableTextByte::
 cp ZH_ESCAPE
 jr z,.yes
 cp $7f
 jr c,.han
 cp $f2
 jr nc,.no
.yes
 scf
 ret
.han
 jp ZhIsStableLead
.no
 and a
 ret

ZhPlaceStableRun::
 ld a,BANK(ZhStableDialogueStrips)
 ld [wZhNameBuffer+11],a
 ld a,BANK(ZhPlaceStableRun)
 ld [wZhNameBuffer+10],a
 push hl
 ld hl,ZhStableDialogueStrips
 ld a,l
 ld [wZhNameBuffer],a
 ld a,h
 ld [wZhNameBuffer+1],a
 ld hl,ZhDialogueLatinStrips
 ld a,l
 ld [wZhNameBuffer+2],a
 ld a,h
 ld [wZhNameBuffer+3],a
 pop hl
 xor a
 jp ZhStableRunStart

; DE=length-prefixed same-bank name, HL=destination. A=0 party, 1 HUD.
ZhPlaceStableName::
 push af
 ld a,BANK(ZhStableDialogueStrips)
 ld [wZhNameBuffer+11],a
 pop af
 push af
 ld a,BANK(ZhPlaceStableName)
 ld [wZhNameBuffer+10],a
 pop af
 push hl
 push af
 ld a,[de]
 inc de
 ld h,d
 ld l,e
 ld b,0
 ld c,a
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 add hl,bc
 ld a,l
 ld [wZhTextEnd],a
 ld a,h
 ld [wZhTextEnd+1],a
 pop af
 push af
 cp 2
 jr z,.summaryTables
 and a
 ld hl,ZhStableDialogueStrips
 ld de,ZhDialogueLatinStrips
 jr z,.tables
 ld hl,ZhStableHudStrips
 ld de,ZhStableHudLatin
 jr .tables
.summaryTables
 ld a,BANK(ZhSummaryGlyphStrips)
 ld [wZhNameBuffer+11],a
 ld hl,ZhSummaryGlyphStrips
 ld de,ZhSummaryLatinStrips
.tables
 ld a,l
 ld [wZhNameBuffer],a
 ld a,h
 ld [wZhNameBuffer+1],a
 ld a,e
 ld [wZhNameBuffer+2],a
 ld a,d
 ld [wZhNameBuffer+3],a
 pop af
 and a
 ld a,0
 jr nz,.noPad
 inc a
.noPad
 pop hl
 ld b,a
 ld a,$ff
 ld [wZhNameBuffer+4],a
 ld [wZhNameBuffer+5],a
 ld a,b
ZhStableRunStart::
 ld [wZhNameBuffer+9],a
 push hl
 ld a,[wZhTextCursor]
 ld b,a
 ld a,[wZhTextEnd]
 cp b
 jr nz,.nonempty
 ld a,[wZhTextCursor+1]
 ld b,a
 ld a,[wZhTextEnd+1]
 cp b
.nonempty
 pop hl
 ret z
.loop
 push hl
 ld a,[wZhTextCursor]
 ld l,a
 ld a,[wZhTextCursor+1]
 ld h,a
 ld a,[wZhTextEnd]
 ld e,a
 ld a,[wZhTextEnd+1]
 ld d,a
 call ZhReadStableByte
 cp ZH_ESCAPE
 jr z,.escape
 cp $7f
 jr nc,.latin
 call ZhDecodeStableGlyph
 jr .decoded
.escape
 call ZhDecodeGlyph
.decoded
 jp c,.bad
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 ; Each glyph has a tagged sequential key or an exception pointer.
 ld h,b
 ld l,c
 add hl,hl
 ld a,[wZhNameBuffer+0]
 ld e,a
 ld a,[wZhNameBuffer+1]
 ld d,a
 add hl,de
 call ZhReadSummaryStripByte
 inc hl
 ld [wZhNameBuffer+7],a
 call ZhReadSummaryStripByte
 ld [wZhNameBuffer+8],a
 ld a,3
 ld [wZhNameBuffer+6],a
 pop hl
 jr .strip
.latin
 inc hl
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 dec hl
 call ZhReadStableByte
 cp $7f
 jr z,.space
 sub $80
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 ld a,[wZhNameBuffer+2]
 ld e,a
 ld a,[wZhNameBuffer+3]
 ld d,a
 add hl,de
 jr .latinPointer
.space
 ld hl,$ffff
.latinPointer
 ld a,l
 ld [wZhNameBuffer+7],a
 ld a,h
 ld [wZhNameBuffer+8],a
 ld a,2
 ld [wZhNameBuffer+6],a
 pop hl
.strip
 push hl
 ld a,[wZhNameBuffer+7]
 ld l,a
 ld a,[wZhNameBuffer+8]
 ld h,a
 ld a,h
 cp $ff
 jr nz,.notBlankStrip
 ld bc,$ffff
 jr .advanceStrip
.notBlankStrip
 bit 7,h
 jr z,.indirectStrip
 ld b,h
 res 7,b
 ld c,l
 inc hl
 jr .advanceStrip
.indirectStrip
 call ZhReadSummaryStripByte
 ld b,a
 inc hl
 call ZhReadSummaryStripByte
 ld c,a
 inc hl
.advanceStrip
 ld a,l
 ld [wZhNameBuffer+7],a
 ld a,h
 ld [wZhNameBuffer+8],a
 pop hl
 ld a,[wZhNameBuffer+9]
 and a
 jr nz,.pair
 ld a,b
 ld [wZhNameBuffer+4],a
 ld a,c
 ld [wZhNameBuffer+5],a
 ld a,1
 ld [wZhNameBuffer+9],a
 jr .nextStrip
.pair
 ld d,b
 ld e,c
 ld a,[wZhNameBuffer+4]
 ld b,a
 ld a,[wZhNameBuffer+5]
 ld c,a
 call .draw
 ret c
 xor a
 ld [wZhNameBuffer+9],a
.nextStrip
 ld a,[wZhNameBuffer+6]
 dec a
 ld [wZhNameBuffer+6],a
 jr nz,.strip
 push hl
 ld a,[wZhTextCursor]
 ld l,a
 ld a,[wZhTextCursor+1]
 ld h,a
 ld a,[wZhTextEnd+1]
 cp h
 jr nz,.peek
 ld a,[wZhTextEnd]
 cp l
 jr z,.finish
.peek
 call ZhReadStableByte
 call ZhIsStableTextByte
 jr nc,.finish
 pop hl
 jp .loop
.finish
 pop hl
 ld a,[wZhNameBuffer+9]
 and a
 ret z
 ld a,[wZhNameBuffer+4]
 ld b,a
 ld a,[wZhNameBuffer+5]
 ld c,a
 ld de,$ffff
.draw
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 call ZhPlaceCacheBlock
 pop bc
 ld a,b
 ldh [rWBK],a
 ret
.bad
 pop hl
 scf
 ret
.blank
 dw $ffff,$ffff

; HL=record with a pointer to the original ten-byte name, DE=nickname.
; Advances HL past pointer on success; carry on mismatch.
ZhMatchDefaultName::
 ld a,[hli]
 ld b,[hl]
 inc hl
 push hl
 ld l,a
 ld h,b
 ld c,10
.loop
 ld a,BANK(PokemonNames)
 call GetFarByte
 ld b,a
 ld a,[de]
 cp b
 jr nz,.bad
 inc hl
 inc de
 dec c
 jr nz,.loop
 pop hl
 and a
 ret
.bad
 pop hl
 scf
 ret

; A=source bank, DE=header, HL=destination. Preserve BC, return DE at @.
ZhPlaceStableMenu::
 ld [wZhNameBuffer+10],a
 ld a,BANK(ZhStableDialogueStrips)
 ld [wZhNameBuffer+11],a
 push bc
 push hl
 ld h,d
 ld l,e
 inc hl
 call ZhReadStableByte
 and $7f
 push af
 inc hl
 call ZhReadStableByte
 and $7f
 ld b,a
 inc hl
 call ZhReadStableByte
 and $7f
 ld c,a
 ld a,b
 and 1
 rrca
 or c
 ld c,a
 srl b
 inc hl
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 add hl,bc
 ld a,l
 ld [wZhTextEnd],a
 ld a,h
 ld [wZhTextEnd+1],a
 pop af
 cp 2
 jr z,.summaryTables
 ld hl,ZhStableDialogueStrips
 ld de,ZhDialogueLatinStrips
 and a
 jr z,.tables
 ld hl,ZhStableHudStrips
 ld de,ZhStableHudLatin
 jr .tables
.summaryTables
 ld a,BANK(ZhSummaryGlyphStrips)
 ld [wZhNameBuffer+11],a
 ld hl,ZhSummaryGlyphStrips
 ld de,ZhSummaryLatinStrips
.tables
 ld a,l
 ld [wZhNameBuffer],a
 ld a,h
 ld [wZhNameBuffer+1],a
 ld a,e
 ld [wZhNameBuffer+2],a
 ld a,d
 ld [wZhNameBuffer+3],a
 pop hl
 xor a
 call ZhStableRunStart
 ld a,[wZhTextCursor]
 ld e,a
 ld a,[wZhTextCursor+1]
 ld d,a
 pop bc
 ret

ZhReadStableByte::
 ld a,[wZhNameBuffer+10]
 jp GetFarByte

ZhReadSummaryStripByte::
 ld a,[wZhNameBuffer+11]
 jp GetFarByte
