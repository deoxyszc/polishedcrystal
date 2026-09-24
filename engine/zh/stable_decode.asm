; Stable two-byte codec -> manifested glyph ID. Same bank directory.
; HL=cursor, DE=exclusive end. Success: HL+=2, BC=glyph, carry clear.
; Failure: HL unchanged, DE preserved, carry set. No WRAM allocation.
ZhDecodeStableGlyph::
 push hl
 ld a,d
 cp h
 jr c,.bad
 jr nz,.length
 ld a,e
 sub l
 jr c,.bad
 cp 2
 jr c,.bad
 jr .read
.length
 ; Check 16-bit remaining length, including low-byte borrow.
 ld a,e
 sub l
 ld a,d
 sbc h
 jr c,.bad
 jr nz,.read
 ld a,e
 sub l
 cp 2
 jr c,.bad
.read
 ld a,[hli]
 ld b,a
 ld c,[hl]
 push de
 ld hl,ZhStableGlyphDirectory
.loop
 ld a,[hli]
 and a
 jr z,.missing
 cp b
 jr nz,.skip
 ld a,[hli]
 cp c
 jr nz,.skipID
 ld a,[hli]
 ld c,a
 ld b,[hl]
 pop de
 pop hl
 inc hl
 inc hl
 and a
 ret
.skip
 inc hl
.skipID
 inc hl
 inc hl
 jr .loop
.missing
 pop de
.bad
 pop hl
 scf
 ret
