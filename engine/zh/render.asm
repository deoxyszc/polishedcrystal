; BC=glyph ID, HL=64-byte row-major 2bpp destination. Preserves BC/DE/HL.
; Three 4x12 strips, high nibble first row; 512 glyphs per ROM page.
assert ZH_GLYPH_COUNT > 0 && ZH_GLYPH_COUNT <= $4000
ZhRasterGlyph::
 ld a, b
 cp HIGH(ZH_GLYPH_COUNT)
 jr c, .valid
 jp nz, .invalid
 ld a, c
 cp LOW(ZH_GLYPH_COUNT)
 jp nc, .invalid
.valid
 push bc
 push de
 push hl
 push bc
 push hl
 ld bc, 64
 xor a
 rst ByteFill
 pop de
 pop bc
 push de
 ld a, b
 srl a
 ld l, a
 ld h, 0
 ld d, h
 ld e, l
 add hl, hl
 add hl, de
 ld de, ZhFontPages
 add hl, de
 ld a, [hli]
 push af
 ld a, [hli]
 ld e, a
 ld d, [hl]
 ld a, b
 and 1
 ld h, a
 ld l, c
 add hl, hl
 push hl
 add hl, hl
 add hl, hl
 add hl, hl
 pop bc
 add hl, bc
 add hl, de
 pop af
 ld b, a
 pop de
 ; Resolve strip/row offsets at assembly time, never in a runtime descriptor.
 DEF previous = 0
 for strip, 3
  for row, 0, 12, 2
   ld a, b
   call GetFarByte
   inc hl
   ld c, a
   for half, 2
    DEF target = ((row + half) / 8) * 32 + (strip / 2) * 16 + ((row + half) % 8) * 2
    if target != previous
     push hl
     ld hl, target - previous
     add hl, de
     ld d, h
     ld e, l
     pop hl
    endc
    REDEF previous = target
    ld a, c
    if half
     swap a
    endc
    and $f0
    if strip == 1
     swap a
    endc
    push hl
    ld h, a
    ld a, [de]
    or h
    ld [de], a
    inc de
    ld [de], a
    dec de
    pop hl
   endr
  endr
 endr
 PURGE previous, target
 pop hl
 pop de
 pop bc
 and a
 ret
.invalid
 scf
 ret
