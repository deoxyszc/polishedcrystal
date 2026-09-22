; Fixed 16-bit strip IDs: compiled pixel identity; $ffff is an empty strip.
; BC=left strip, DE=right strip. Output wZhCachePixels (8x16, 2bpp).
; Caller selects cache WRAM. Preserves BC/DE/HL, carry on invalid ID.
ZhComposeCacheBlock::
 push bc
 push de
 push hl
 push de
 push bc
 ld hl, wZhCachePixels
 ld bc, 32
 xor a
 rst ByteFill
 pop bc
 call ZhReadFontStrip
 jr c, .badLeft
 ld hl, wZhCachePixels
 call .left
 pop bc
 call ZhReadFontStrip
 jr c,.badRight
 ld hl,wZhCachePixels
 call .right
 pop hl
 pop de
 pop bc
 and a
 ret
.badLeft
 pop de
.badRight
 pop hl
 pop de
 pop bc
 scf
 ret
.left
 ld de,wZhStripPixels
 ld b,8
.leftRows
 ld a,[de]
 inc de
 ld c,a
 and $f0
 ld [hli],a
 ld a,[de]
 inc de
 ld [wZhStripPlane],a
 and $f0
 ld [hli],a
 ld a,c
 swap a
 and $f0
 ld [hli],a
 ld a,[wZhStripPlane]
 swap a
 and $f0
 ld [hli],a
 dec b
 jr nz,.leftRows
 ret
.right
 ld de,wZhStripPixels
 ld b,8
.rightRows
 ld a,[de]
 inc de
 ld c,a
 swap a
 and $0f
 or [hl]
 ld [hli],a
 ld a,[de]
 inc de
 ld [wZhStripPlane],a
 swap a
 and $0f
 or [hl]
 ld [hli],a
 ld a,c
 and $0f
 or [hl]
 ld [hli],a
 ld a,[wZhStripPlane]
 and $0f
 or [hl]
 ld [hli],a
 dec b
 jr nz,.rightRows
 ret

; BC=compiled 4x16 strip ID. Coordinates/vertical alignment are baked
; into individual strips at build time; no page/style selection here.
ZhReadFontStrip::
 push bc
 push de
 push hl
 ld a, b
 and c
 inc a
 jr z, .blank
 ld a, b
 cp HIGH(ZH_COMPILED_STRIP_COUNT)
 jr c, .valid
 jr nz, .invalid
 ld a, c
 cp LOW(ZH_COMPILED_STRIP_COUNT)
 jr nc, .invalid
.valid
 ld l, b
 ld h, 0
 add hl, hl
 ld e, b
 ld d, 0
 add hl, de
 ld de, ZhCompiledStripPages
 add hl, de
 ld a, [hli]
 push af
 ld a, [hli]
 ld d, [hl]
 ld e, a
 ld l, c
 ld h, 0
 add hl, hl
 add hl, hl
 add hl, hl
 add hl, hl
 add hl, de
 pop bc
 ld de, wZhStripPixels
 ld c, 16
.copy
 ld a, b
 call GetFarByte
 ld [de], a
 inc de
 inc hl
 dec c
 jr nz, .copy
 jr .done
.blank
 ld hl, wZhStripPixels
 ld bc, 16
 xor a
 rst ByteFill
.done
 pop hl
 pop de
 pop bc
 and a
 ret
.invalid
 pop hl
 pop de
 pop bc
 scf
 ret

; BC/DE=strip key. Return A=slot with pixels ready before any map reference.
; Preserves BC/DE/HL and VBK. Caller selects cache WRAM; no map publication.
ZhEnsureCacheBlock::
 call ZhGlyphCacheFind
 ret nc
 call ZhComposeCacheBlock
 ret c
 call ZhGlyphCacheAlloc
 jr nc, .upload
 ; Commit the current maps before reusing slots no longer referenced there.
 push bc
 push de
 push hl
 call ApplyAttrAndTilemapInVBlank
 pop hl
 pop de
 pop bc
 call ZhGlyphCacheRecover
 call ZhGlyphCacheAlloc
 ret c
.upload
 push bc
 push de
 push hl
 push af
 call ZhGlyphCacheLocation
 ld l, a
 ld h, 0
 add hl, hl
 add hl, hl
 add hl, hl
 add hl, hl
 ld de, $8000
 add hl, de
 ldh a, [rVBK]
 push af
 ld a, b
 ldh [rVBK], a
 ld de, wZhCachePixels
 ld b, BANK(ZhEnsureCacheBlock)
 ld c, 2
 call Get2bpp
 pop af
 ldh [rVBK], a
 pop af
 pop hl
 pop de
 pop bc
 and a
 ret

; BC/DE=strip pair, HL=upper map cell. Output HL=next upper cell.
; Preserve input key. Palette is taken from destination, bank is replaced.
; This is the only cache-to-map publication path, shared with restoration.
ZhPlaceCacheBlock::
 ld a, b
 and c
 and d
 and e
 inc a
 jr z, .blank
 call ZhEnsureCacheBlock
 ret c
 push bc
 push de
 call ZhGlyphCacheLocation
 ld c, a
 ld a, b
 and a
 ld b, 0
 jr z, .bank
 ld b, BG_BANK1
.bank
 ld [hl], c
 push hl
 ld de, SCREEN_WIDTH
 add hl, de
 inc c
 ld [hl], c
 ld de, wAttrmap - wTilemap
 add hl, de
 ld a, [hl]
 and $ff ^ BG_BANK1
 or b
 ld [hl], a
 ld de, -SCREEN_WIDTH
 add hl, de
 ld a, [hl]
 and $ff ^ BG_BANK1
 or b
 ld [hl], a
 pop hl
 inc hl
 pop de
 pop bc
 and a
 ret
.blank
 push bc
 push de
 push hl
 ld [hl], $7f
 ld de, SCREEN_WIDTH
 add hl, de
 ld [hl], $7f
 ld de, wAttrmap - wTilemap
 add hl, de
 res B_BG_BANK1, [hl]
 ld de, -SCREEN_WIDTH
 add hl, de
 res B_BG_BANK1, [hl]
 pop hl
 inc hl
 pop de
 pop bc
 and a
 ret
