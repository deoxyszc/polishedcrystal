; Internal PlaceString backend. Existing stable codes; no text descriptors.
; HL is the LOWER row anchor, as in the reference Chinese implementation.
; Ordinary script controls and termination remain owned by home/text.asm.
; A=source bank, DE=source, HL=destination. Carry means not a Han lead.
PlaceStringChinese:
 push bc
 push hl
 push de
 ld [wTextSourceBank],a
 ld h,d
 ld l,e
 call .read
 ld b,a
 ld hl,TextHanDirectory
.findLead
 ld a,[hli]
 and a
 jp z,.notHan
 cp b
 jr z,.lead
 ld de,19
 add hl,de
 jr .findLead
.lead
 pop de
 pop hl
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 push hl
 ld a,e
 ld [wTextSource],a
 ld a,d
 ld [wTextSource+1],a
 ld a,$ff
 ld [wTextPending],a
 ld [wTextPending+1],a
 pop hl
.next
 push hl
 ld a,[wTextSource]
 ld l,a
 ld a,[wTextSource+1]
 ld h,a
 call .read
 ld b,a
 ; Only Han enters here initially. Subsequent original Latin may share a half-cell.
 cp $7f
 jr z,.space
 cp $80
 jr c,.han
 cp $f2
 jr nc,.endRun
 inc hl
 call .saveSource
 ld a,b
 sub $80
 ld l,a
 ld h,0
 add hl,hl
 ld d,h
 ld e,l
 add hl,hl
 add hl,de
 add hl,hl
 ld de,TextLatinStrips
 add hl,de
 ld b,2
 jr .fragments
.space
 cp $7f
 jr nz,.han
 inc hl
 call .saveSource
 ld hl,TextSpaceStrips
 ld b,2
 jr .fragments
.han
 push hl
 ld hl,TextHanDirectory
.find
 ld a,[hli]
 and a
 jr z,.endLookup
 cp b
 jr nz,.skip
 push hl
 ld a,[wTextSource]
 ld l,a
 ld a,[wTextSource+1]
 ld h,a
 inc hl
 call .read
 ld c,a
 pop hl
 ld a,[hl]
 cp c
 jr z,.found
.skip
 ld de,19
 add hl,de
 jr .find
.endLookup
 pop hl
.endRun
 pop hl
 ld a,[wTextPending+1]
 cp $ff
 jr z,.finish
 ld a,[wTextPending]
 ld c,a
 ld a,[wTextPending+1]
 ld b,a
 ld de,$ffff
 call .block
.finish
 push hl
 call ApplyAttrmapInVBlank
 pop hl
 ld a,[wTextSource]
 ld e,a
 ld a,[wTextSource+1]
 ld d,a
 pop af
 ldh [rWBK],a
 pop bc
 and a
 ret
.found
 inc hl
 pop de
 inc de
 inc de
 ld a,e
 ld [wTextSource],a
 ld a,d
 ld [wTextSource+1],a
 ld b,3
.fragments
 ; HL=raw 4x12 strips, B=count; destination is on stack.
 ld a,l
 ld [wTextFragments],a
 ld a,h
 ld [wTextFragments+1],a
 ld a,b
 ld [wTextFragmentCount],a
 pop hl
.fragment
 ld a,[wTextPending+1]
 cp $ff
 jr nz,.pair
 ld a,[wTextFragments]
 ld [wTextPending],a
 ld a,[wTextFragments+1]
 ld [wTextPending+1],a
 jr .advance
.pair
 ld a,[wTextPending]
 ld c,a
 ld a,[wTextPending+1]
 ld b,a
 ld a,[wTextFragments]
 ld e,a
 ld a,[wTextFragments+1]
 ld d,a
 call .block
 ld a,$ff
 ld [wTextPending],a
 ld [wTextPending+1],a
.advance
 push hl
 ld a,[wTextFragments]
 ld l,a
 ld a,[wTextFragments+1]
 ld h,a
 ld de,6
 add hl,de
 ld a,l
 ld [wTextFragments],a
 ld a,h
 ld [wTextFragments+1],a
 pop hl
 ld a,[wTextFragmentCount]
 dec a
 ld [wTextFragmentCount],a
 jr nz,.fragment
 call PrintLetterDelay
 jp .next
.notHan
 pop de
 pop hl
 pop bc
 scf
 ret
.read
 ld a,[wTextSourceBank]
 jp GetFarByte
.saveSource
 ld a,l
 ld [wTextSource],a
 ld a,h
 ld [wTextSource+1],a
 ret

; BC/DE=raw left/right fragment pointers; destination HL advances one cell.
.block
 push hl
 push bc
 push de
 ld hl,wTextGlyphKeys
 ld a,0
.search
 push af
 ld a,[hli]
 cp c
 jr nz,.skip3
 ld a,[hli]
 cp b
 jr nz,.skip2
 ld a,[hli]
 cp e
 jr nz,.skip1
 ld a,[hli]
 cp d
 jr z,.hit
 jr .skip0
.skip3
 inc hl
.skip2
 inc hl
.skip1
 inc hl
.skip0
 pop af
 inc a
 cp 43
 jr c,.search
 ; Rebuild live references before selecting a reusable slot.
 call .markLive
 ld hl,wTextGlyphUsed
 ld b,43
 xor a
.free
 bit 0,[hl]
 jr z,.allocate
 inc hl
 inc a
 dec b
 jr nz,.free
 ld a,ERR_WINDOW_OVERFLOW
 jp Crash
.allocate
 push af
 add a
 add a
 ld l,a
 ld h,0
 ld de,wTextGlyphKeys
 add hl,de
 ld d,h
 ld e,l
 ld hl,sp+2
 ld c,[hl]
 inc hl
 ld b,[hl]
 inc hl
 ld a,[hli]
 ld h,[hl]
 ld l,a
 ; HL=left, BC=right. Record then compose only this missing block.
 ld a,l
 ld [de],a
 inc de
 ld a,h
 ld [de],a
 inc de
 ld a,c
 ld [de],a
 inc de
 ld a,b
 ld [de],a
 call .compose
 pop af
 push af
 add a
 add $80
 ld l,a
 ld h,0
 rept 4
 add hl,hl
 endr
 ld de,$8000
 add hl,de
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld de,wTextGlyphPixels
 ld b,BANK(PlaceStringChinese)
 ld c,2
 call Get2bpp
 pop af
 ldh [rVBK],a
 pop af
 jr .publish
.hit
 pop af
.publish
 ld c,a
 ld b,0
 ld hl,wTextGlyphUsed
 add hl,bc
 ld [hl],1
 ld a,c
 add a
 add $80
 pop de
 pop bc
 pop hl
 push hl
 ld de,-SCREEN_WIDTH
 add hl,de
 ld [hl],a
 inc a
 pop hl
 ld [hl],a
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 set B_BG_BANK1,[hl]
 ld de,-SCREEN_WIDTH
 add hl,de
 set B_BG_BANK1,[hl]
 pop hl
 inc hl
 ret

; Four blank rows followed by twelve glyph rows. Right fragment is optional.
.compose
 push bc
 ld de,wTextGlyphPixels
 ld b,8
 xor a
.blankTop
 ld [de],a
 inc de
 dec b
 jr nz,.blankTop
 ld b,6
.left
 ld a,[hli]
 ld c,a
 and $f0
 ld [de],a
 inc de
 ld [de],a
 inc de
 ld a,c
 swap a
 and $f0
 ld [de],a
 inc de
 ld [de],a
 inc de
 dec b
 jr nz,.left
 pop hl
 ld a,h
 cp $ff
 ret z
 ld de,wTextGlyphPixels+8
 ld b,6
.right
 ld a,[hli]
 ld c,a
 swap a
 and $0f
 push hl
 ld h,d
 ld l,e
 or [hl]
 ld [hli],a
 ld [hli],a
 ld a,c
 and $0f
 or [hl]
 ld [hli],a
 ld [hli],a
 ld d,h
 ld e,l
 pop hl
 dec b
 jr nz,.right
 ret
.markLive
 push bc
 push de
 ld hl,wTextGlyphUsed
 ld bc,43
 xor a
 rst ByteFill
 ld hl,wTilemap
 ld de,wAttrmap
 ld bc,SCREEN_AREA
.mark
 ld a,[de]
 bit B_BG_BANK1,a
 jr z,.nextCell
 ld a,[hl]
 sub $80
 cp 86
 jr nc,.nextCell
 srl a
 push hl
 push de
 ld e,a
 ld d,0
 ld hl,wTextGlyphUsed
 add hl,de
 ld [hl],1
 pop de
 pop hl
.nextCell
 inc hl
 inc de
 dec bc
 ld a,b
 or c
 jr nz,.mark
 pop de
 pop bc
 ret

; Font load is the original shared lifecycle boundary, not a page redraw hook.
InitializeChineseTextCache:
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 ld hl,wTextGlyphKeys
 ld bc,43*4
 ld a,$ff
 rst ByteFill
 ld hl,wTextGlyphUsed
 ld bc,43
 xor a
 rst ByteFill
 pop af
 ldh [rWBK],a
 ret

ScrollTextCell:
 push bc
 push hl
 push de
 ld a,[hl]
 ld [de],a
 ld bc,wAttrmap-wTilemap
 add hl,bc
 ld a,[hl]
 push af
 ld h,d
 ld l,e
 add hl,bc
 pop af
 ld [hl],a
 pop de
 pop hl
 pop bc
 inc hl
 ret

ClearChineseSpeechBox:
 hlcoord TEXTBOX_INNERX,TEXTBOX_INNERY-1
 lb bc,TEXTBOX_INNERH,TEXTBOX_INNERW
 call ClearBox
 hlcoord TEXTBOX_INNERX,TEXTBOX_INNERY-1,wAttrmap
 lb bc,TEXTBOX_INNERH,TEXTBOX_INNERW
 ld a,PAL_BG_TEXT
 jp FillBoxWithByte

ClearScrolledTextAttributes:
 hlcoord TEXTBOX_INNERX,TEXTBOX_INNERY+2,wAttrmap
 ld bc,TEXTBOX_INNERW
 ld a,PAL_BG_TEXT
 rst ByteFill
 jp ApplyAttrAndTilemapInVBlank
