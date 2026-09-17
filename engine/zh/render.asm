assert ZH_GLYPH_COUNT > 0 && ZH_GLYPH_COUNT <= $4000
ZhRasterGlyph::
 ld a, b
 cp HIGH(ZH_GLYPH_COUNT)
 jr c, .valid
 jr nz, .invalid
 ld a, c
 cp LOW(ZH_GLYPH_COUNT)
 jr nc, .invalid
.valid
 push bc
 push de
 push hl
 ; Page index = ID >> 9; table offset = page*3.
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
 ; Low9 *32 is within one page (0..$3fe0).
 ld a, b
 and 1
 ld h, a
 ld l, c
 rept 5
 add hl, hl
 endr
 add hl, de
 pop af
 ld b, a ; source bank
 pop de ; original output pointer
 push de
 ld c, 32
.loop
 ld a, b
 call GetFarByte
 ld [de], a
 inc de
 ld [de], a
 inc de
 inc hl
 dec c
 jr nz, .loop
 pop hl
 pop de
 pop bc
 and a
 ret
.invalid
 scf
 ret
