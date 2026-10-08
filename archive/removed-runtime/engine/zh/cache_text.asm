; Dynamic names alone are paired at runtime; ordinary text is precompiled.
; DE=validated WRAM0 name, HL=upper tile. Return both advanced.
MACRO zh_dynamic_name
\1::
 ld a, [de]
 cp $53
 jr z, .done
 push de
 push hl
 cp $7f
 jr z, .space
 sub $80
 ld l, a
 ld h, 0
 add hl, hl
 add hl, hl
 ld de, \2
 add hl, de
 ld b, [hl]
 inc hl
 ld c, [hl]
 inc hl
 ld d, [hl]
 inc hl
 ld e, [hl]
 pop hl
 push hl
 jr .draw
.space
 ld bc, $ffff
 ld de, $ffff
.draw
 ldh a, [rWBK]
 push af
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 call ZhPlaceCacheBlock
 pop bc
 ld a, b
 ldh [rWBK], a
 jr c, .bad
 pop bc
 pop de
 inc de
 jr \1
.bad
 pop hl
 pop de
 scf
 ret
.done
 and a
 ret
ENDM
zh_dynamic_name ZhPlaceDynamicName, ZhDialogueLatinStrips
zh_dynamic_name ZhPlaceStartMenuName, ZhStartMenuLatinStrips

; Original one-byte strings keep their 8x8 cells, line controls and endpoint.
; Key ($f800 + font-index*128 + character),$ffff identifies original fonts.
; No lower map cell is touched. Static symbols/numerals retain bank0 IDs.
ZhPlaceLegacyLiteral::
 push af
 call ZhSummaryDisplayActive
 jr nc,.notSummary
 pop af
 ld [hli],a
 and a
 ret
.notSummary
 pop af
 call ZhIsSummaryDestination
 jr nc,.normal
 ld [hli],a
 and a
 ret
.normal
 push bc
 push de
 cp $80
 jr c,.static
 cp ZH_CACHE_END_TILE
 jr nc,.static
 push hl
 sub $80
 ld c,a
 ld a,[wOptions2]
 and FONT_MASK
 ld b,a
 srl a
 add $f8
 ld d,a
 ld a,b
 and 1
 rrca
 or c
 ld c,a
 ld b,d
 ld de,$ffff
 pop hl
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 ld a,[wZhPolicy]
 and a
 jr nz,.active
 ld a,ZH_VRAM_BOTH
 call ZhGlyphCacheInit
.active
 call ZhEnsureCacheBlock
 jr c,.failed
 push hl
 call ZhGlyphCacheLocation
 ld [hl],a
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,[hl]
 and $ff ^ BG_BANK1
 bit 0,b
 jr z,.attr
 or BG_BANK1
.attr
 ld [hl],a
 pop hl
 inc hl
 pop af
 ldh [rWBK],a
 pop de
 pop bc
 and a
 ret
.failed
 pop af
 ldh [rWBK],a
 pop de
 pop bc
 scf
 ret
.static
 ld [hli],a
 push hl
 ld bc,wAttrmap-wTilemap-1
 add hl,bc
 res B_BG_BANK1,[hl]
 pop hl
 pop de
 pop bc
 and a
 ret

; Reserved tagged key, original font selection compiled as a pointer table.
; B=$f8..$fb, C contains the low seven character bits and one font bit.
ZhComposeLegacyLiteral::
 push bc
 push de
 push hl
 ld a,c
 and $7f
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 push hl
 ld a,c
 rlca
 and 1
 ld c,a
 ld a,b
 sub $f8
 add a
 or c
 add a
 ld c,a
 ld b,0
 ld hl,.fonts
 add hl,bc
 ld a,[hli]
 ld h,[hl]
 ld l,a
 pop de
 add hl,de
 ld de,wZhCachePixels
 ld c,8
.row
 ld a,BANK(FontTiles)
 call GetFarByte
 inc hl
 ld [de],a
 inc de
 ld [de],a
 inc de
 dec c
 jr nz,.row
 xor a
 ld c,16
.blank
 ld [de],a
 inc de
 dec c
 jr nz,.blank
 pop hl
 pop de
 pop bc
 and a
 ret
.fonts
 dw FontNormal,FontNarrow,FontBold,FontItalic
 dw FontSerif,FontChicago,FontMICR,FontUnown
