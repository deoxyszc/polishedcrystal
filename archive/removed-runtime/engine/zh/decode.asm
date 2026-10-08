; Input HL = escape address, DE = exclusive end in the same mapped bank.
; Success BC = glyph ID, HL += 3, carry clear. Failure HL unchanged, carry set.
; DE preserved, AF/BC clobbered; no memory writes, bank changes or frame waits.
; Caller guarantees a readable mapped interval [HL, DE); wrapped ranges rejected.
ZhDecodeGlyph::
	push hl
	ld a,e
	sub l
	ld c,a
	ld a,d
	sbc h
	jr c,.invalid
	and a
	jr nz,.enough
	ld a,c
	cp 3
	jr c,.invalid
.enough
if DEF(LOCALE_ZH)
 call ZhReadStableByte
 inc hl
else
 ld a,[hli]
endc
	cp ZH_ESCAPE
	jr nz,.invalid
if DEF(LOCALE_ZH)
 call ZhReadStableByte
 inc hl
else
 ld a,[hli]
endc
	bit 7,a
	jr z,.invalid
	and $7f
	ld b,a
if DEF(LOCALE_ZH)
 call ZhReadStableByte
 inc hl
else
 ld a,[hli]
endc
	bit 7,a
	jr z,.invalid
	and $7f
	ld c,a
	; Convert two seven-bit payloads to a 14-bit BC value.
	srl b
	jr nc,.count
	set 7,c
.count
	ld a,b
	cp HIGH(ZH_GLYPH_COUNT)
	jr c,.valid
	jr nz,.invalid
	ld a,c
	cp LOW(ZH_GLYPH_COUNT)
	jr nc,.invalid
.valid
	; Discard saved HL without clobbering decoded BC or end DE.
	inc sp
	inc sp
	and a
	ret
.invalid
	pop hl
	scf
	ret
