; 43 logical blocks share the existing key/flag budget across two VRAM banks.
; A logical slot owns exactly one bank at a time; changing banks invalidates its key.
; Internal PlaceString backend. Existing stable codes; no text descriptors.
; HL is the LOWER row anchor, as in the reference Chinese implementation.
; Ordinary script controls and termination remain owned by home/text.asm.
; A=source bank, DE=source, HL=destination. Carry means not a Han lead.
PlaceStringChinese:
 push bc
 push hl
 push de
 ld [wTextSourceBank],a
 ld a,d
 cp $d0
 jr c,.sourceReady
 cp $e0
 jr nc,.sourceReady
 ldh a,[rWBK]
 ld [wTextSourceBank],a
.sourceReady
 ld h,d
 ld l,e
 call .read
 cp $0a
 jr z,.begin
 cp $7f
 jr z,.begin
 cp $80
 jr c,.checkHan
 cp $f2
 jr c,.begin
.checkHan
 call TextLookupHanLead
 jp c,.notHan
 push hl
 ld h,d
 ld l,e
 inc hl
 call .read
 pop hl
 call TextLookupHanTail
 jp c,.notHan
.begin
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
 pop hl
.next
 push hl
 ld a,[wTextSource]
 ld l,a
 ld a,[wTextSource+1]
 ld h,a
 call .read
 ld b,a
 ; Original Latin and Han share a pending half across nested strings.
 cp $0a
 jp z,.extra
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
 add a
 ld l,a
 ld a,[wOptions2]
 and FONT_MASK
 inc a
 ld h,a
 ld b,2
 jp .fragments
.space
 cp $7f
 jr nz,.han
 inc hl
 call .saveSource
 ld hl,$0000
 ld b,2
 jp .fragments
.extra
 inc hl
 call .read
 cp $80
 jp nz,.badExtra
 inc hl
 call .read
 sub $80
 jp c,.badExtra
 ld c,a
 ld a,[TextExtraGlyphs]
 cp c
 jp z,.badExtra
 jp c,.badExtra
 inc hl
 call .saveSource
 ld l,c
 ld h,0
 add hl,hl
 ld d,h
 ld e,l
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,de
 ld de,TextExtraGlyphs+1
 add hl,de
 ld b,3
 jp .fragments
.badExtra
 ld a,ERR_PEBKAC
 jp Crash
.han
 push hl
 ld a,b
 call TextLookupHanLead
 jr c,.endLookup
 push hl
 ld a,[wTextSource]
 ld l,a
 ld a,[wTextSource+1]
 ld h,a
 inc hl
 call .read
 pop hl
 call TextLookupHanTail
 jr nc,.found
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
 call TextPlaceBlock
 ; Publish a pending half now for letter timing; keep it at this cell so
 ; nested original strings can replace the blank half on return.
 dec hl
.finish
 ; The caller owns screen transfer timing; UpdateBGMap publishes paired
 ; tile/attribute halves. This decoder must not force a screen upload.
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
 pop de
 inc de
 inc de
 ld a,e
 ld [wTextSource],a
 ld a,d
 ld [wTextSource+1],a
 ld b,3
.fragments
 push bc
 push hl
 ld hl,sp+4
 ld a,[hli]
 ld h,[hl]
 ld l,a
 call TextIsTabAddress
 jr nc,.bodyStyle
 pop hl
 pop bc
 set 7,h
 res 6,h
 jr .normalStyle
.bodyStyle
 call TextUsesRaisedFont
 pop hl
 pop bc
 jr nc,.normalStyle
 set 7,h
.normalStyle
 ; HL=raw 4x12 strips, B=count; destination is on stack.
 ld a,l
 ld [wTextFragments],a
 ld a,h
 ld [wTextFragments+1],a
 ld a,[wTextFragmentCount]
 and $f0
 or b
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
 call TextPlaceBlock
 ld a,$ff
 ld [wTextPending],a
 ld [wTextPending+1],a
.advance
 push hl
 ld a,[wTextFragments]
 ld l,a
 ld a,[wTextFragments+1]
 ld h,a
 ld a,h
 and $7f
 cp 9
 ld de,6
 jr nc,.rawAdvance
 ld e,1
.rawAdvance
 add hl,de
 ld a,l
 ld [wTextFragments],a
 ld a,h
 ld [wTextFragments+1],a
 pop hl
 ld a,[wTextFragmentCount]
 dec a
 ld [wTextFragmentCount],a
 and $0f
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
 ld a,h
 cp $d0
 jr c,.rom
 cp $e0
 jr nc,.rom
 ldh a,[rWBK]
 push af
 ld a,[wTextSourceBank]
 ldh [rWBK],a
 ld a,[hl]
 push bc
 push hl
 ld b,a
 ld hl,sp+5
 ld a,[hl]
 ldh [rWBK],a
 ld a,b
 pop hl
 pop bc
 inc sp
 inc sp
 ret
.rom
 ld a,[wTextSourceBank]
 jp GetFarByte
.saveSource
 ld a,l
 ld [wTextSource],a
 ld a,h
 ld [wTextSource+1],a
 ret

; BC/DE=raw left/right fragment pointers; destination HL advances one cell.
TextEnsureBlock:
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
 jr z,.candidate
 jr .skip0
.candidate
 ; Bits 6..7 in the existing first slot flag hold the bank restriction.
 ; No extra WRAM or nested policy stack is allocated.
 push hl
 push bc
 ld hl,sp+5
 ld c,[hl]
 ld b,0
 ld hl,wTextGlyphUsed
 add hl,bc
 ld a,[hl]
 and 2
 ld c,a
 ld a,[wTextGlyphUsed]
 and $c0
 rlca
 rlca
 and a
 jr z,.allowed
 dec a
 add a
 cp c
 jr z,.allowed
 pop bc
 pop hl
 jr .skip0
.allowed
 pop bc
 pop hl
 jp .hit

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
 call TextPlaceBlock.markLive
 ld hl,wTextGlyphUsed
 ld b,43
 xor a
.free
 bit 0,[hl]
 jr nz,.occupied
 push bc
 ld b,a
 call TextSlotHasTargetReference
 ld a,b
 pop bc
 jr nc,.allocate
.occupied
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
 call TextPlaceBlock.compose
 pop af
 push af
 push af
 ld c,a
 ld b,0
 ld hl,wTextGlyphUsed
 add hl,bc
 ld a,[wTextGlyphUsed]
 and $c0
 rlca
 rlca
 cp 1
 ld a,0
 jr z,.setBank
 ld a,2
.setBank
 ld c,a
 ld a,[hl]
 and $c0
 or c
 ld [hl],a
 and 2
 srl a
 ldh [rVBK],a
 pop af
 add a
 add $80
 ld l,a
 ld h,0
 rept 4
 add hl,hl
 endr
 ld de,$8000
 add hl,de
 ld de,wTextGlyphPixels
 ld b,BANK(PlaceStringChinese)
 ld c,2
 call Get2bpp
 xor a
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
 set 0,[hl]
 ld a,c
 add a
 add $80
 pop de
 pop bc
 pop hl
 ret

TextPlaceBlock:
 ld a,b
 cp $40
 jr nc,.double
 bit 0,c
 jr nz,.double
 ld a,d
 cp b
 jr nz,.double
 ld a,e
 dec a
 cp c
 jr nz,.double
 ; An aligned original Latin glyph is one 8x8 cell. Its blank upper
 ; half must not erase the preceding row (menus can have one-row spacing).
 ; Aligned Latin keeps the original single-cell font tile in bank0.
 ; Mixed half-cells alone need cache composition.
 ld a,b
 and a
 ld a,' '
 jr z,.latinTile
 ld a,c
 srl a
 add $80
.latinTile
 ld [hl],a
 push hl
 call TextAttributeAddress
 res B_BG_BANK1,[hl]
 pop hl
 inc hl
 ret
.double
 call TextEnsureBlock
 push hl
 push af
 call TextPreviousRow
 pop af
 ld [hl],a
 inc a
 pop hl
 ld [hl],a
 push hl
 call TextAttributeAddress
 call TextSetCellBank
 call TextPreviousRow
 call TextSetCellBank
 pop hl
 inc hl
 ret

; The key itself selects the original Latin font, so switching fonts cannot
; reuse glyph pixels from a different face. Han still uses raw 4x12 strips.
.compose
 ld de,wTextGlyphPixels
 xor a
.row
 push af
 push hl
 push bc
 push de
 call TextReadStripRow
 pop de
 ld [de],a
 pop hl ; right key
 pop bc ; left key
 push bc
 push hl
 push de
 ld hl,sp+7
 ld a,[hl] ; saved row is the high byte of AF
 pop de
 pop hl
 push hl
 push de
 call TextReadStripRow
 swap a
 ld c,a
 pop de
 ld a,[de]
 or c
 ld [de],a
 inc de
 ld [de],a
 inc de
 pop bc
 pop hl
 pop af
 inc a
 cp 16
 jr c,.row
 ret
.markLive
 push bc
 push de
 ld hl,wTextGlyphUsed
 ld b,43
.clearLive
 res 0,[hl]
 inc hl
 dec b
 jr nz,.clearLive
 ld hl,wTilemap
 ld de,wAttrmap
 ld bc,SCREEN_AREA
.mark
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
 ; DE was repurposed as the slot; recover map attr pointer from stack.
 pop de
 push de
 ld a,[de]
 and 8
 rrca
 rrca
 ld d,a
 ld a,[hl]
 and 2
 cp d
 jr nz,.otherBank
 set 0,[hl]
.otherBank
 pop de
 pop hl
.nextCell
 inc hl
 inc de
 dec bc
 ld a,b
 or c
 jr nz,.mark
 call TextMarkSummaryReferences
 pop de
 pop bc
 ret

; Font load is the original shared lifecycle boundary, not a page redraw hook.
InitializeChineseTextCache:
 xor a
 ld [wTextFragmentCount],a
 ld a,$ff
 ld [wTextPending+1],a
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
 ld a,$80
 ld [wTextGlyphUsed],a
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

; Generated radix directory: bounded lookup, independent of glyph count.
TextLookupHanLead:
 cp $40
 jr nc,TextLookupHanMissing
 add a
 ld l,a
 ld h,0
 ld bc,TextHanDirectory
 add hl,bc
 jr TextLookupHanPointer
TextLookupHanTail:
 ld c,a
 and $f0
 rrca
 rrca
 ld e,a
 ld d,0
 add hl,de
 ld e,[hl]
 inc hl
 ld d,[hl]
 inc hl
 ld a,[hli]
 ld h,[hl]
 ld l,a
 ld a,c
 and $0f
 ld c,a
 ; Rank within one 16-code block; at most fifteen shifts, never a glyph scan.
 ld b,0
 and a
 jr z,.selected
.rank
 srl d
 rr e
 jr nc,.absent
 inc b
.absent
 dec c
 jr nz,.rank
.selected
 bit 0,e
 jr z,TextLookupHanMissing
 ld a,b
 add a
 ld e,a
 ld d,0
 add hl,de
 sla e
 sla e
 sla e
 add hl,de
 and a
 ret
TextLookupHanPointer:
 ld a,[hli]
 ld h,[hl]
 ld l,a
 or h
 ret nz
TextLookupHanMissing:
 scf
 ret

; The window stack keeps original metadata/link ordering. Each cell stores
; normalized attr,tile and, only for dynamic cells, the four-byte glyph key.
; The caller selected the window-stack bank. Cache reads switch banks locally.
BackupChineseWindow:
 call GetTileBackupMenuBoxDims
.row
 push bc
 push hl
.cell
 push bc
 push hl
 ld a,[hl]
 ld c,a
 ld bc,wAttrmap-wTilemap
 add hl,bc
 ld a,[hl]
 and $ef
 ld b,a
 pop hl
 ld c,[hl]
 push bc
 call TextWindowKey
 ; Carry means static. HL/DE and BC (tile/attr) are preserved.
 ld a,4
 jr nc,.dynamic
 xor a
.dynamic
 add 4 ; reserve this record plus the trailing link
 call .check
 pop bc
 ; Test again after bounds check; keys are read after selecting their bank.
 call TextWindowKey
 jr c,.static
 set 4,b
 ld a,b
 ld [de],a
 dec de
 ld a,c
 ld [de],a
 dec de
 push hl
 push de
 push bc
 ld a,c
 sub $80
 srl a
 add a
 add a
 ld l,a
 ld h,0
 ld bc,wTextGlyphKeys
 add hl,bc
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 ld a,[hli]
 push af
 ld a,[hl]
 ld h,a
 pop af
 ld l,a
 pop af
 ldh [rWBK],a
 ; retrieve destination without additional WRAM
 pop af ; saved tile/attr no longer needed
 pop de
 ld a,c
 ld [de],a
 dec de
 ld a,b
 ld [de],a
 dec de
 ld a,l
 ld [de],a
 dec de
 ld a,h
 ld [de],a
 dec de
 pop hl
 jr .next
.static
 ld a,b
 ld [de],a
 dec de
 ld a,c
 ld [de],a
 dec de
.next
 inc hl
 pop bc
 dec c
 jr nz,.cell
 pop hl
 ld bc,SCREEN_WIDTH
 add hl,bc
 pop bc
 dec b
 jr nz,.row
 ret
.check
 ; Inline bank-independent check: caller's bank contains window metadata.
 push hl
 ld h,d
 ld l,e
 ld c,a
 ld a,l
 sub c
 ld l,a
 ld a,h
 sbc 0
 ld h,a
 ld a,[wWindowStack]
 ld c,a
 ld a,[wWindowStack+1]
 cp h
 jr c,.fits
 jr nz,.overflow
 ld a,l
 sub c
 jr c,.overflow
.fits
 pop hl
 and a
 ret
.overflow
 pop hl
 ld a,ERR_WINDOW_OVERFLOW
 jp Crash

; Carry=static; only validated cache keys can be serialized as dynamic.
TextWindowKey:
 push hl
 push de
 push bc
 ld a,c
 sub $80
 cp 86
 jr nc,.static
 srl a
 add a
 add a
 ld l,a
 ld h,0
 ld de,wTextGlyphKeys
 add hl,de
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 push hl
 ld a,c
 sub $80
 srl a
 ld e,a
 ld d,0
 ld hl,wTextGlyphUsed
 add hl,de
 ld a,b
 and 8
 rrca
 rrca
 ld e,a
 ld a,[hl]
 and 2
 cp e
 pop hl
 jr nz,.invalid
 inc hl
 ld a,[hl]
 cp $ff
 jr z,.invalid
 pop af
 ldh [rWBK],a
 pop bc
 pop de
 pop hl
 and a
 ret
.invalid
 pop af
 ldh [rWBK],a
.static
 pop bc
 pop de
 pop hl
 scf
 ret

RestoreChineseWindow:
 call GetTileBackupMenuBoxDims
.row
 push bc
 push hl
.cell
 push bc
 ld a,[de]
 ld b,a
 dec de
 ld a,[de]
 ld c,a
 dec de
 bit 4,b
 jr z,.publish
 push bc
 push hl
 ; Read the stable fragment pointers before leaving the stack bank.
 ld a,[de]
 ld c,a
 dec de
 ld a,[de]
 ld b,a
 dec de
 ld a,[de]
 ld l,a
 dec de
 ld a,[de]
 ld h,a
 dec de
 push de
 ld d,h
 ld e,l
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 call TextEnsureBlock
 ld l,a
 pop af
 ldh [rWBK],a
 ld a,l
 pop de
 pop hl
 pop bc
 push af
 ld a,c
 and 1
 ld c,a
 pop af
 add c
 ld c,a
.publish
 ld [hl],c
 push hl
 push de
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,b
 and $ef
 ld [hl],a
 bit 4,b
 call nz,TextSetCellBank
 pop de
 pop hl
 inc hl
 pop bc
 dec c
 jr nz,.cell
 pop hl
 ld bc,SCREEN_WIDTH
 add hl,bc
 pop bc
 dec b
 jr nz,.row
 ret

TextSetCellBank:
 push de
 push bc
 push hl
 ld a,[hl]
 and $f7
 ld b,a
 push hl
 call TextTileAddress
 ld a,[hl]
 sub $80
 srl a
 ld e,a
 ld d,0
 ld hl,wTextGlyphUsed
 add hl,de
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphUsed)
 ldh [rWBK],a
 ld a,[hl]
 ld c,a
 pop af
 ldh [rWBK],a
 ld a,c
 and 2
 add a
 add a
 or b
 pop hl
 ld [hl],a
 pop hl
 pop bc
 pop de
 ret

; Before moving a slot to another bank, protect ordinary graphics already
; referencing the target tile pair as well as dynamic glyph references.
TextSlotHasTargetReference:
 push hl
 push bc
 push de
 add a
 add $80
 ld b,a
 ld a,[wTextGlyphUsed]
 and $c0
 cp $40
 ld c,0
 jr z,.bank
 ld c,8
.bank
 ld hl,wTilemap
 ld de,wAttrmap
.scan
 ld a,[hl]
 and $fe
 cp b
 jr nz,.next
 ld a,[de]
 and 8
 cp c
 jr z,.used
.next
 inc de
 inc hl
 ld a,h
 cp HIGH(wTilemapEnd)
 jr nz,.scan
 ld a,l
 cp LOW(wTilemapEnd)
 jr nz,.scan
 pop de
 pop bc
 pop hl
 and a
 ret
.used
 pop de
 pop bc
 pop hl
 scf
 ret

; A=0 both, 1 bank0, 2 bank1. Restriction occupies spare bits in the
; existing flags; changing it does not allocate slots or create a stack.
SetChineseTextBankLimit:
 push hl
 push bc
 ld c,a
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphUsed)
 ldh [rWBK],a
 ld a,c
 and 3
 rrca
 rrca
 ld c,a
 ld hl,wTextGlyphUsed
 ld a,[hl]
 and $3f
 or c
 ld [hl],a
 pop af
 ldh [rWBK],a
 pop bc
 pop hl
 ret

; Temporary screen persistence borrows 532 bytes from the EXISTING 4KiB
; window stack: 43 keys (172B) and 360 attributes. Tile IDs remain in the
; original wTempTileMap, preserving its direct consumers. No new WRAM bank.
; Snapshot attribute bit4 identifies dynamic records, preserving all key bits.
DEF TEXT_TEMP_KEYS EQUS "wWindowStack+4"
DEF TEXT_TEMP_ATTR EQUS "wWindowStack+4+43*4"
DEF TEXT_TEMP_END EQUS "wWindowStack+4+43*4+SCREEN_AREA"
InitializeChineseTempBackup:
 ldh a,[rWBK]
 push af
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld hl,wWindowStack
 ld a,LOW(wWindowStack+4)
 ld [hli],a
 ld a,HIGH(wWindowStack+4)
 ld [hli],a
 xor a
 ld [hli],a
 ld [hl],a
 pop af
 ldh [rWBK],a
 ret

BackupChineseTempScreen:
 ldh a,[rWBK]
 push af
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ; Protect all currently pushed windows before reserving the snapshot.
 ld a,[wWindowStackPointer+1]
 cp HIGH(TEXT_TEMP_END)
 jr c,.overflow
 jr nz,.room
 ld a,[wWindowStackPointer]
 cp LOW(TEXT_TEMP_END)
 jr c,.overflow
.room
 ld hl,wWindowStack
 ld a,LOW(TEXT_TEMP_END)
 ld [hli],a
 ld a,HIGH(TEXT_TEMP_END)
 ld [hli],a
 ld [hl],1
 ld hl,wTilemap
 ld de,TEXT_TEMP_ATTR
.attr
 push de
 push hl
 ld c,[hl]
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,[hl]
 and $ef
 ld b,a
 pop hl
 call TextWindowKey
 jr c,.static
 set 4,b
.static
 pop de
 ld a,b
 ld [de],a
 inc de
 inc hl
 ld a,h
 cp HIGH(wTilemapEnd)
 jr nz,.attr
 ld a,l
 cp LOW(wTilemapEnd)
 jr nz,.attr
 ld hl,wTextGlyphKeys
 ld de,TEXT_TEMP_KEYS
 ld bc,43*4
.keys
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 ld a,[hli]
 push af
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 pop af
 ld [de],a
 inc de
 dec bc
 ld a,b
 or c
 jr nz,.keys
 pop af
 ldh [rWBK],a
 ret
.overflow
 ld a,ERR_WINDOW_OVERFLOW
 jp Crash

RestoreChineseTempScreen:
 ldh a,[rWBK]
 push af
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld a,[wWindowStack+2]
 and a
 jr z,.plain
 ; Remove stale tile references before allocating. Otherwise a saved full
 ; cache falsely appears live in its old slots and cannot be reconstructed.
 ld hl,wTilemap
.clear
 call TextReadTempCell
 jr nc,.dynamic
 ld [hl],c
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],b
 pop hl
 jr .clearNext
.dynamic
 ld [hl],' '
.clearNext
 inc hl
 ld a,h
 cp HIGH(wTilemapEnd)
 jr nz,.clear
 ld a,l
 cp LOW(wTilemapEnd)
 jr nz,.clear
 ld hl,wTilemap
.restore
 call RestoreChineseTempCell
 inc hl
 ld a,h
 cp HIGH(wTilemapEnd)
 jr nz,.restore
 ld a,l
 cp LOW(wTilemapEnd)
 jr nz,.restore
 pop af
 ldh [rWBK],a
 ret
.plain
 ld a,BANK(wTempTileMap)
 ldh [rWBK],a
 ld hl,wTempTileMap
 ld de,wTilemap
 ld bc,SCREEN_AREA
 rst CopyBytes
 pop af
 ldh [rWBK],a
 ret

; HL=screen cell. BC=saved attr/tile. DE=key record if dynamic (carry clear).
; Reads snapshot tile IDs rather than an already reconstructed tilemap.
TextReadTempCell:
 push hl
 ld de,wTempTileMap-wTilemap
 add hl,de
 ld a,BANK(wTempTileMap)
 ldh [rWBK],a
 ld c,[hl]
 ld de,TEXT_TEMP_ATTR-wTempTileMap
 add hl,de
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld b,[hl]
 bit 4,b
 jr z,.static
 res 4,b
 ld a,c
 sub $80
 srl a
 add a
 add a
 ld e,a
 ld d,0
 ld hl,TEXT_TEMP_KEYS
 add hl,de
 ld d,h
 ld e,l
 pop hl
 and a
 ret
.static
 res 4,b
 pop hl
 scf
 ret

; Also used by direct temporary-map consumers such as ability overlays.
; Rebuild only this cell, preserving adjacent graphics and saved palette.
RestoreChineseTempCell:
 push hl
 call TextReadTempCell
 jr c,.publish
 push bc
 push hl
 ld h,d
 ld l,e
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 ld a,[hli]
 ld e,a
 ld d,[hl]
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 call TextEnsureBlock
 ld e,a
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 pop hl
 pop bc
 ld a,c
 and 1
 add e
 ld c,a
 ld [hl],a
 push bc
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],b
 call TextSetCellBank
 pop bc
 pop hl
 ret
.publish
 ld [hl],c
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],b
 pop hl
 ret

CopyChineseTempScreen:
 call BackupChineseTempScreen
 ldh a,[rWBK]
 push af
 ld a,BANK(wTempTileMap)
 ldh [rWBK],a
 ld hl,wTilemap
 ld de,wTempTileMap
 ld bc,SCREEN_AREA
 rst CopyBytes
 pop af
 ldh [rWBK],a
 ret

; HL=key; A=row within the 12-pixel glyph, returns high nibble.
; 0/1 are blank halves; $01xx..$08xx select original 8x8 font halves.
TextReadStripRow:
 ld b,a
 ld a,h
 cp $89
 jr c,.ordinary
 cp $c0
 jr nc,.ordinary
 ; Tab: pointer bit14 is implicit, row0 contains the original top border.
 set 6,h
 res 7,h
 ld a,b
 and a
 jr z,.tabBorder
 sub 3
 jr c,.blank
 jr .bounded
.tabBorder
 ld a,$f0
 ret
.ordinary
 ld a,b
 bit 7,h
 jr nz,.shifted
 sub 4
 jr c,.blank
 jr .bounded
.shifted
 ld b,a
 ld a,h
 cp $ff
 jr z,.blank
 res 7,h
 ld a,b
.bounded
 cp 12
 jr nc,.blank
 ld b,a
 ld a,h
 cp $ff
 jr z,.blank
 cp $40
 jr nc,.han
 and a
 jr z,.blank
 ld a,b
 sub 4
 jr c,.blank
 ld b,a
 ld a,l
 and 1
 push af
 srl l
 ld a,h
 dec a
 add a
 ld e,a
 ld d,0
 push hl
 ld hl,TextOriginalFontPointers
 add hl,de
 ld a,[hli]
 ld d,[hl]
 ld e,a
 pop hl
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,de
 ld e,b
 ld d,0
 add hl,de
 ld a,BANK(FontTiles)
 call GetFarByte
 ld b,a
 pop af
 ld a,b
 jr z,.left
 swap a
.left
 and $f0
 ret
.han
 ld a,b
 srl a
 ld e,a
 ld d,0
 add hl,de
 ld a,[hl]
 bit 0,b
 jr z,.left
 swap a
 and $f0
 ret
.blank
 xor a
 ret
TextOriginalFontPointers:
 dw FontNormal,FontNarrow,FontBold,FontItalic
 dw FontSerif,FontChicago,FontMICR,FontUnown

RestoreChineseAbilityRow:
 ldh a,[rWBK]
 push af
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld c,SLIDEOUT_WIDTH
.loop
 push bc
 call RestoreChineseTempCell
 pop bc
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,[hl]
 and ~(OAM_PALETTE | OAM_PRIO)
 or b
 ld [hl],a
 pop hl
 inc hl
 dec c
 jr nz,.loop
 pop af
 ldh [rWBK],a
 ret

BeginChineseString:
 push af
 ld a,[wTextFragmentCount]
 add $10
 jr c,.overflow
 ld [wTextFragmentCount],a
 and $f0
 cp $10
 jr nz,.done
 ld a,$ff
 ld [wTextPending],a
 ld [wTextPending+1],a
.done
 pop af
 ret
.overflow
 ld a,ERR_WINDOW_OVERFLOW
 jp Crash
EndChineseString:
 ld a,[wTextFragmentCount]
 sub $10
 ld [wTextFragmentCount],a
 and $f0
 ret nz
 ; fallthrough
FlushChineseStringHalf:
 ld a,[wTextPending+1]
 cp $ff
 ret z
 inc hl
 ld a,$ff
 ld [wTextPending],a
 ld [wTextPending+1],a
 ret

FillChineseBox:
.row
	push bc
	push hl
.col
	ld [hli], a
	dec c
	jr nz, .col
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
	dec b
	jr nz, .row
	ret

ClearChineseScreenAttributes:
 ld a,PAL_BG_TEXT
 hlcoord 0,0,wAttrmap
 ld bc,SCREEN_AREA
 rst ByteFill
 ret

; Summary uses 32-byte rows interleaving 16 tiles and 16 attributes.
; Address-based mapping avoids page-specific text protocols and extra state.
TextIsSummaryAddress:
 push de
 push hl
 ld de,-wSummaryScreenWindowBuffer
 add hl,de
 ld a,h
 cp HIGH(32*10)
 jr c,.yes
 jr nz,.no
 ld a,l
 cp LOW(32*10)
 jr c,.yes
.no
 pop hl
 pop de
 and a
 ret
.yes
 pop hl
 pop de
 scf
 ret
TextAttributeAddress:
 call TextIsSummaryAddress
 ld de,wAttrmap-wTilemap
 jr nc,.add
 ld de,16
.add
 add hl,de
 ret
TextTileAddress:
 call TextIsSummaryAddress
 ld de,wTilemap-wAttrmap
 jr nc,.add
 ld de,-16
.add
 add hl,de
 ret
TextPreviousRow:
 call TextIsSummaryAddress
 ld de,-SCREEN_WIDTH
 jr nc,.add
 ld de,-32
.add
 add hl,de
 ret

TextSummaryDisplayActive:
 push hl
 push de
 ld a,[hLCDInterruptFunctionTargetLo]
 ld l,a
 ld a,[hLCDInterruptFunctionTargetHi]
 ld h,a
 ld de,LCDSummaryScreenHideWindow
 call .equal
 jr z,.yes
 ld de,LCDSummaryScreenShowWindow
 call .equal
 jr z,.yes
 ld de,LCDSummaryScreenScrollBackground
 call .equal
 jr z,.yes
 pop de
 pop hl
 and a
 ret
.yes
 pop de
 pop hl
 scf
 ret
.equal
 ld a,h
 cp d
 ret nz
 ld a,l
 cp e
 ret
TextMarkSummaryReferences:
 call TextSummaryDisplayActive
 ret nc
 ld hl,wSummaryScreenWindowBuffer
 ld b,10
.row
 ld c,12
.cell
 push bc
 ld a,[hl]
 sub $80
 cp 86
 jr nc,.next
 srl a
 push hl
 ld c,a
 ld b,0
 ld de,16
 add hl,de
 ld a,[hl]
 and 8
 rrca
 rrca
 ld d,a
 ld hl,wTextGlyphUsed
 add hl,bc
 ld a,[hl]
 and 2
 cp d
 jr nz,.otherBank
 set 0,[hl]
.otherBank
 pop hl
.next
 pop bc
 inc hl
 dec c
 jr nz,.cell
 ld de,20
 add hl,de
 dec b
 jr nz,.row
 ret

UpdateChineseBGMap:
 xor a
 ldh [rVBK],a
; Update the BG Map, in halves, from wTilemap and wAttrmap.

	ldh a, [hBGMapMode]
	and $7f
	ret z

; BG Map 0
	dec a ; 1
	jr z, .DoTiles
	dec a ; 2
	jr z, .DoAttributes

; BG Map 1
	ld hl, vBGMap1
	dec a
	jr z, .DoBGMap1Tiles
	dec a
	jr z, .DoBGMap1Attributes
; Update from a specific row
; does not update hBGMapHalf
	dec a
	bccoord 0, 0
	jr z, .DoCustomSourceTiles
	dec a
	ret nz
	bccoord 0, 0, wAttrmap
	ld a, 1
	ldh [rVBK], a
	call .DoCustomSourceTiles
	xor a
	ldh [rVBK], a
	ret

.DoCustomSourceTiles
	ld [wSPBuffer], sp
	xor a
	ld h, a
	ld d, a
	ldh a, [hBGMapHalf] ; multiply by 20 to get the tilemap offset
	ld l, a
	ld e, a
	add hl, hl ; hl = hl * 2
	add hl, hl ; hl = hl * 4
	add hl, de ; hl = (hl*4) + de
	add hl, hl ; hl = (5*hl)*2
	add hl, hl ; hl = (5*hl)*4
	add hl, bc
	ld sp, hl
	ldh a, [hBGMapHalf] ; multiply by 32 to get the bg map offset
	; assumes [hBGMapHalf] < 8
	swap a
	add a
	ld l, a
	ldh a, [hBGMapAddress]
	add l
	ld l, a
	ldh a, [hBGMapAddress + 1]
	adc 0
	ld h, a
	ldh a, [hBGMapCopyNRows]
	jr .startCustomCopy

.DoAttributes
	ldh a, [hBGMapAddress + 1]
	ld h, a
	ldh a, [hBGMapAddress]
	ld l, a
.DoBGMap1Attributes
	ld a, 1
	ldh [rVBK], a
	call .CopyAttributes
	xor a
	ldh [rVBK], a
	ret

.CopyAttributes
	ld [wSPBuffer], sp

; Which half?
	ldh a, [hBGMapHalf]
	and a ; 0
	jr z, .AttributeMapTop
; bottom row
	coord sp, 0, 9, wAttrmap
	ld de, (SCREEN_HEIGHT / 2) * TILEMAP_WIDTH
	add hl, de
; Next time: top half
	xor a
	jr .startCopy
.AttributeMapTop
	coord sp, 0, 0, wAttrmap
; Next time: bottom half
	jr .AttributeMapTopContinue

.DoTiles
	ldh a, [hBGMapAddress + 1]
	ld h, a
	ldh a, [hBGMapAddress]
	ld l, a

.DoBGMap1Tiles
 ; Like the reference renderer, publish attributes for this same half
 ; before its tiles. No waits or forced screen upload in cache recovery.
 push hl
 call .DoBGMap1Attributes
 ldh a,[hBGMapHalf]
 xor 1
 ldh [hBGMapHalf],a
 pop hl
	ld [wSPBuffer], sp
; Which half?
	ldh a, [hBGMapHalf]
	and a ; 0
	jr z, .TileMapTop
; bottom row
	coord sp, 0, 9
	ld de, (SCREEN_HEIGHT / 2) * TILEMAP_WIDTH
	add hl, de
; Next time: top half
	xor a
	jr .startCopy
.TileMapTop
	coord sp, 0, 0
; Next time: bottom half
.AttributeMapTopContinue
	inc a
.startCopy
; Which half to update next time
	ldh [hBGMapHalf], a
; Rows of tiles in a half
	ld a, SCREEN_HEIGHT / 2
.startCustomCopy
; Discrepancy between wTilemap and BGMap
	ld bc, TILEMAP_WIDTH - (SCREEN_WIDTH - 1)
.row
; Copy a row of 20 tiles
rept (SCREEN_WIDTH / 2) - 1
	pop de
	ld [hl], e
	inc l
	ld [hl], d
	inc l
endr
	pop de
	ld [hl], e
	inc l
	ld [hl], d

	add hl, bc
	dec a
	jr nz, .row

	ld sp, wSPBuffer
	pop hl
	ld sp, hl
	ret

; Shared default-name substitution. Never changes the nickname/save buffer.
; Input DE is an original, terminated name. Carry set means no translation.
FindChineseDefaultName:
 push hl
 push bc
 push de
 ld hl,TextTranslatedNames
.next
 ld a,[hli]
 ld b,[hl]
 inc hl
 ld c,a
 or b
 jr z,.missing
 push hl
 push de
 ld h,b
 ld l,c
 ld b,10
.compare
 ld a,[de]
 cp '@'
 jr z,.sourceEnd
 ld c,a
 ld a,BANK(PokemonNames)
 call GetFarByte
 cp c
 jr nz,.mismatch
 inc de
 inc hl
 dec b
 jr nz,.compare
 ld a,[de]
 cp '@'
 jr nz,.mismatch
 jr .match
.sourceEnd
 ld a,BANK(PokemonNames)
 call GetFarByte
 cp '@'
 jr nz,.mismatch
.match
 pop de
 pop hl
 ld a,[hli]
 ld d,[hl]
 ld e,a
 inc sp
 inc sp
 pop bc
 pop hl
 and a
 ret
.mismatch
 pop de
 pop hl
 inc hl
 inc hl
 jr .next
.missing
 pop de
 pop bc
 pop hl
 scf
 ret

PlaceChineseDefaultName:
 ; FarCall owns the original ROM bank; direct _PlaceString sees bank80.
 call FindChineseDefaultName
 ret c
 rst PlaceString
 and a
 ret

TextUsesRaisedFont:
 ; Tabs keep their own near-border placement, not the page body baseline.
 push hl
 push de
 ld de,-(wTilemap+12*SCREEN_WIDTH+2)
 add hl,de
 ld a,h
 or a
 jr nz,.body
 ld a,l
 cp 3
 jr c,.tab
.body
 pop de
 pop hl
 call TextSummaryDisplayActive
 ret nc
 push hl
 ld a,[wSummaryScreenFlags]
 and SUMMARY_FLAGS_PAGE_MASK
 jr z,.pink
 cp SUMMARY_BLUE_PAGE
 jr nz,.normal
 ; Only the two raised blue label rows use this font. Ability prose,
 ; numbers and other BG strings retain the original baseline.
 push de
 push hl
 ld de,-(wTilemap+5*SCREEN_WIDTH+8)
 add hl,de
 ld a,h
 or a
 jr nz,.checkSpeed
 ld a,l
 cp 9
 jr c,.blueRaised
.checkSpeed
 pop hl
 push hl
 ld de,-(wTilemap+10*SCREEN_WIDTH+8)
 add hl,de
 ld a,h
 or a
 jr nz,.blueNormal
 ld a,l
 cp 3
 jr nc,.blueNormal
.blueRaised
 pop hl
 pop de
 jr .pink
.blueNormal
 pop hl
 pop de
 jr .normal
.pink
 ld a,[wTempMonIsEgg]
 bit MON_IS_EGG_F,a
 jr nz,.normal
 pop hl
 scf
 ret
.normal
 pop hl
 and a
 ret

.tab
 pop de
 pop hl
 and a
 ret

ClearChineseTextBankAttributes:
 ld hl,wAttrmap
 ld bc,SCREEN_AREA
.loop
 res B_BG_BANK1,[hl]
 inc hl
 dec bc
 ld a,b
 or c
 jr nz,.loop
 ret

; The original PrintNum owns formatting. This is only the final cell store,
; allowing summary digits to share the same confirmed vertical baseline.
PlaceChineseNumberCell:
 push af
 call TextUsesRaisedFont
 jr nc,.native
 call TextIsSummaryAddress
 jr c,.native
 pop af
 cp '0'
 jr c,.nativeValue
 cp '9'+1
 jr nc,.nativeValue
 push bc
 push de
 sub $80
 add a
 ld c,a
 ld a,[wOptions2]
 and FONT_MASK
 inc a
 or $80
 ld b,a
 ld d,a
 ld e,c
 inc e
 ldh a,[rWBK]
 push af
 ld a,BANK(wTextGlyphKeys)
 ldh [rWBK],a
 call TextPlaceBlock
 pop af
 ldh [rWBK],a
 pop de
 pop bc
 ret
.native
 pop af
.nativeValue
 ld [hli],a
 ret

PlaceChineseBattleEnemyName:
 call FindChineseDefaultName
 ret c
 ; The Han backend anchors its lower row; the top HUD starts at row zero.
 hlcoord 1,1
 rst PlaceString
 and a
 ret

DrawChineseSummaryTab:
 push de
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 hlcoord 2,11
 ld bc,3
 ld a,' '
 rst ByteFill
 hlcoord 2,12
 ld bc,3
 ld a,' '
 rst ByteFill
 hlcoord 2,11,wAttrmap
 lb bc,2,3
 ld a,SUMMARY_PAL_LOWER_WINDOW
 call FillBoxWithByte
 pop de
 hlcoord 2,12
 rst PlaceString
 ret

TextIsTabAddress:
 push hl
 push de
 ld de,-(wTilemap+12*SCREEN_WIDTH+2)
 add hl,de
 ld a,h
 or a
 jr nz,.no
 ld a,l
 cp 3
 jr nc,.no
 pop de
 pop hl
 scf
 ret
.no
 pop de
 pop hl
 and a
 ret

; Battle palette replacement must not erase the text cache bank selection.
FillChinesePaletteBytes:
 push de
 ld e,a
.loop
 ld a,[hl]
 and 8
 or e
 ld [hli],a
 dec bc
 ld a,b
 or c
 jr nz,.loop
 pop de
 ret
FillChinesePaletteBox:
 push de
 ld e,a
.row
 push bc
 push hl
.cell
 ld a,[hl]
 and 8
 or e
 ld [hli],a
 dec c
 jr nz,.cell
 pop hl
 ld bc,SCREEN_WIDTH
 add hl,bc
 pop bc
 dec b
 jr nz,.row
 pop de
 ret
