; Layout width is logical pixels; backing stride stays18 tiles/576 bytes.
assert ZH_LAYOUT_WIDTH_PX == ZH_LAYOUT_WIDTH_TILES * 8
assert ZH_LAYOUT_WIDTH_TILES >= 2 && ZH_LAYOUT_WIDTH_TILES <= 18
assert ZH_LAYOUT_GLYPH_Y_OFFSET >= 0 && ZH_LAYOUT_GLYPH_Y_OFFSET <= 4
; Restricted intro line compositor. HL=start, DE=exclusive end, same ROM bank.
; Caller selects the WRAM bank containing all wZh* buffers. AF/BC/DE/HL clobbered.
; Carry clear=end marker reached; set=invalid/truncated/unsupported/too wide.
; On error line may contain validated prefix; caller MUST NOT upload on carry.
; 144x16 pixels, tile-row-major 18x2 2bpp. No VRAM or frame side effects.
ZhComposeLine::
 call ZhComposeBegin
 ; fallthrough
ZhComposeAppend::
 jp ZhComposeNext

; Clear one logical line once. Preserves HL/DE source/end for convenience.
ZhComposeBegin::
 push hl
 push de
 ld hl, wZhLineBuffer
 ld bc, 576
 xor a
 rst ByteFill
 xor a
 ld [wZhPixelCursor], a
 pop de
 pop hl
 ret

; No upload here: caller submits only after all bounded spans succeed.
ZhComposeFinish::
 ret ; preserve final append carry; do not erase errors

ZhComposeNext:
.next
 ld a, h
 cp d
 jr c, .read
 jr nz, .error
 ld a, l
 cp e
 jr z, .done
 jr nc, .error
.read
 ld a, [hl]
 cp $53 ; existing @ terminator
 jr z, .done
 cp ZH_ESCAPE
 jr z, .glyph
 ; Restricted prototype: existing font bytes $80..$f1 or space $7f.
 cp $7f
 jr c, .error
 cp $f2
 jr nc, .error
 inc hl
 push hl
 push de
 push af
 ld a, 8
 ld [wZhComposeWidth], a
 call .width
 jr c, .asciiError
 pop af
 call ZhRasterAscii
 jr .blit
.asciiError
 pop af
 pop de
 pop hl
 jr .error
.glyph
 call ZhDecodeGlyph
 jr c, .error
 push hl
 push de
 ld a, 12
 ld [wZhComposeWidth], a
 call .width
 jr c, .glyphError
 ld hl, wZhGlyphBuffer
 call ZhRasterGlyph
 jr c, .glyphError
.blit
 call ZhBlitGlyph
 pop de
 pop hl
 jr .next
.glyphError
 pop de
 pop hl
.error
 scf
 ret
.done
 and a
 ret
.width
 push bc
 ld b, a
 ld a, [wZhPixelCursor]
 add b
 cp ZH_LAYOUT_WIDTH_PX + 1
 pop bc
 ccf
 ret

; A=existing one-byte font code. Fixed 8px, normal font, baseline aligned within the 12px cell.
ZhRasterAscii:
 push af
 ld hl, wZhGlyphBuffer
 ld bc, 64
 xor a
 rst ByteFill
 pop af
 cp $7f
 ret z
 sub $80
 ld h, 0
 ld l, a
 add hl, hl
 add hl, hl
 add hl, hl
 ld bc, FontNormal
 add hl, bc
 ld de, wZhGlyphBuffer + ZH_LAYOUT_ASCII_Y_OFFSET * 2
 ld b, 8
.loop
 ld a, BANK(FontNormal)
 call GetFarByte
 ld [de], a
 inc de
 ld [de], a
 inc de
 inc hl
 dec b
 jr z, .done
 ld a, b
 cp 4
 jr nz, .loop
 ; Skip the upper-right tile to the lower-left tile.
 push hl
 ld hl, 16
 add hl, de
 ld d, h
 ld e, l
 pop hl
 jr .loop
.done
 ret

; Pixel-accurate OR blit at arbitrary x; handles the 4px half-tile boundary.
ZhBlitGlyph:
 xor a
 ld [wZhComposeRow], a
.row
 xor a
 ld [wZhComposeColumn], a
.pixel
 ld a, [wZhComposeRow]
 and 7
 add a
 ld c, a
 ld a, [wZhComposeRow]
 cp 8
 jr c, .top
 ld a, c
 add 32
 ld c, a
.top
 ld a, [wZhComposeColumn]
 cp 8
 jr c, .left
 ld a, c
 add 16
 ld c, a
.left
 ld b, 0
 ld hl, wZhGlyphBuffer
 add hl, bc
 ld a, [wZhComposeColumn]
 and 7
 ld b, a
 ld a, [hl]
 inc b
.shift
 rlca
 dec b
 jr nz, .shift
 jr nc, .advance
 ; Destination x = cursor+column. B retains x%8, C x/8.
 ld a, [wZhPixelCursor]
 ld c, a
 ld a, [wZhComposeColumn]
 add c
 ld c, a
 and 7
 ld b, a
 ld a, c
 and $f8
 add a
 ld e, a
 ld d, 0
 jr nc, .offset
 inc d
.offset
 ld a, [wZhComposeRow]
 add ZH_LAYOUT_GLYPH_Y_OFFSET
 and 7
 add a
 add e
 ld e, a
 jr nc, .rowOffset
 inc d
.rowOffset
 ld a, [wZhComposeRow]
 add ZH_LAYOUT_GLYPH_Y_OFFSET
 cp 8
 jr c, .address
 ld hl, 288
 add hl, de
 ld d, h
 ld e, l
.address
 ld hl, wZhLineBuffer
 add hl, de
 ld a, $80
 inc b
.mask
 dec b
 jr z, .write
 srl a
 jr .mask
.write
 ld b, a
 or [hl]
 ld [hli], a
 ld a, b
 or [hl]
 ld [hl], a
.advance
 ld hl, wZhComposeColumn
 inc [hl]
 ld a, [wZhComposeWidth]
 cp [hl]
 jp nz, .pixel
 ld hl, wZhComposeRow
 inc [hl]
 ld a, [hl]
 cp 12
 jp nz, .row
 ld a, [wZhComposeWidth]
 ld hl, wZhPixelCursor
 add [hl]
 ld [hl], a
 ret
