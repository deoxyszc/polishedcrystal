; Fixed 16-bit strip IDs: glyph*3 + column; $ffff is an empty strip.
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
 ld hl, wZhCachePixels + ZH_LAYOUT_GLYPH_Y_OFFSET * 2
 call .left
 pop bc
 call ZhReadFontStrip
 jr c, .badRight
 ld hl, wZhCachePixels + ZH_LAYOUT_GLYPH_Y_OFFSET * 2
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
 ld de, wZhStripPixels
 ld b, 6
.leftRows
 ld a, [de]
 inc de
 ld c, a
 and $f0
 ld [hli], a
 ld [hli], a
 ld a, c
 swap a
 and $f0
 ld [hli], a
 ld [hli], a
 dec b
 jr nz, .leftRows
 ret
.right
 ld de, wZhStripPixels
 ld b, 6
.rightRows
 ld a, [de]
 inc de
 ld c, a
 swap a
 and $0f
 or [hl]
 ld [hli], a
 ld [hli], a
 ld a, c
 and $0f
 or [hl]
 ld [hli], a
 ld [hli], a
 dec b
 jr nz, .rightRows
 ret

; BC=strip ID. Page lookup is generated at build time: no division by 3.
; Each page holds 1536 strips of six bytes. Destination wZhStripPixels.
; Preserves caller BC/DE/HL; carry rejects IDs outside generated font.
ZhReadFontStrip::
 push bc
 push de
 push hl
 ld a, b
 and c
 inc a
 jp z, .blank
 ld a, b
 cp $c0
 jp z, .ascii
 ld a, b
 cp HIGH(ZH_GLYPH_COUNT * 3)
 jr c, .valid
 jp nz, .invalid
 ld a, c
 cp LOW(ZH_GLYPH_COUNT * 3)
 jp nc, .invalid
.valid
 ; Resolve division at assembly time. Index is the strip ID high byte.
 ld l, b
 ld h, 0
 push de
 ld de, .PageRemainders
 add hl, de
 ld a, [hl]
 ld b, a
 ld de, .PageOffsets - .PageRemainders
 add hl, de
 ld a, [hl]
 pop de
 ld l, a
 ld h, 0
 ld de, ZhFontPages
 add hl, de
 ld a, [hli]
 push af
 ld a, [hli]
 ld e, a
 ld d, [hl]
 ld h, b
 ld l, c
 add hl, hl
 ld b, h
 ld c, l
 add hl, hl
 add hl, bc
 add hl, de
 pop af
 ld b, a
 ld de, wZhStripPixels
 ld c, 6
.copy
 ld a, b
 call GetFarByte
 ld [de], a
 inc de
 inc hl
 dec c
 jr nz, .copy
 jp .done
.blank
 ld hl, wZhStripPixels
 ld bc, 6
 xor a
 rst ByteFill
 jp .done
.ascii
 ld a, c
 cp 114 * 2
 jp nc, .invalid
 and 1
 ld [wZhStripHalf], a
 ld l, c
 ld h, 0
 srl l
 add hl, hl
 add hl, hl
 add hl, hl
 ld de, FontNormal
 add hl, de
 push hl
 ld hl, wZhStripPixels
 ld bc, 6
 xor a
 rst ByteFill
 pop hl
 for y, 8
  ld a, BANK(FontNormal)
  call GetFarByte
  inc hl
  call .nibble
  DEF target_row = y + ZH_LAYOUT_ASCII_Y_OFFSET - ZH_LAYOUT_GLYPH_Y_OFFSET
  ASSERT target_row >= 0 && target_row < 12
  if target_row % 2
   swap a
  endc
  push hl
  ld hl, wZhStripPixels + target_row / 2
  or [hl]
  ld [hl], a
  pop hl
 endr
 PURGE target_row
 jr .done
.nibble
 push bc
 ld c, a
 ld a, [wZhStripHalf]
 and a
 ld a, c
 jr z, .high
 swap a
.high
 and $f0
 pop bc
 ret
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
.PageRemainders
 for high_byte, (ZH_GLYPH_COUNT * 3 + 255) / 256
  db high_byte % 6
 endr
.PageOffsets
 for high_byte, (ZH_GLYPH_COUNT * 3 + 255) / 256
  db (high_byte / 6) * 3
 endr

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
