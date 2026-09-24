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
if DEF(LOCALE_ZH)
 call ZhReadStableByte
 inc hl
 ld b,a
 call ZhReadStableByte
 ld c,a
else
 ld a,[hli]
 ld b,a
 ld c,[hl]
endc
 push de
 ld de,0
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
 ld b,d
 ld c,e
 pop de
 pop hl
 inc hl
 inc hl
 and a
 ret
.skip
 inc hl
.skipID
 inc de
 jr .loop
.missing
 pop de
.bad
 pop hl
 scf
 ret
