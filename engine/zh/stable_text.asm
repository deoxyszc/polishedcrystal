; Bounded dialogue stable glyph run. Uses existing 12-byte name staging
; only while no dynamic-name call is active; no new WRAM allocation.
; HL=destination; wZhTextCursor/end own source. Same ROM bank.
ZhPlaceStableRun::
 xor a
 ld [wZhNameBuffer+9],a
.loop
 push hl
 ld a,[wZhTextCursor]
 ld l,a
 ld a,[wZhTextCursor+1]
 ld h,a
 ld a,[wZhTextEnd]
 ld e,a
 ld a,[wZhTextEnd+1]
 ld d,a
 call ZhDecodeStableGlyph
 jp c,.bad
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 ; BC is a compact directory row index; six bytes per glyph.
 ld h,b
 ld l,c
 add hl,hl
 ld d,h
 ld e,l
 add hl,hl
 add hl,de
 ld de,ZhStableDialogueStrips
 add hl,de
 ld a,l
 ld [wZhNameBuffer+7],a
 ld a,h
 ld [wZhNameBuffer+8],a
 ld a,3
 ld [wZhNameBuffer+6],a
 pop hl
.strip
 push hl
 ld a,[wZhNameBuffer+7]
 ld l,a
 ld a,[wZhNameBuffer+8]
 ld h,a
 ld b,[hl]
 inc hl
 ld c,[hl]
 inc hl
 ld a,l
 ld [wZhNameBuffer+7],a
 ld a,h
 ld [wZhNameBuffer+8],a
 pop hl
 ld a,[wZhNameBuffer+9]
 and a
 jr nz,.pair
 ld a,b
 ld [wZhNameBuffer+4],a
 ld a,c
 ld [wZhNameBuffer+5],a
 ld a,1
 ld [wZhNameBuffer+9],a
 jr .nextStrip
.pair
 ld d,b
 ld e,c
 ld a,[wZhNameBuffer+4]
 ld b,a
 ld a,[wZhNameBuffer+5]
 ld c,a
 call .draw
 ret c
 xor a
 ld [wZhNameBuffer+9],a
.nextStrip
 ld a,[wZhNameBuffer+6]
 dec a
 ld [wZhNameBuffer+6],a
 jr nz,.strip
 push hl
 ld a,[wZhTextCursor]
 ld l,a
 ld a,[wZhTextCursor+1]
 ld h,a
 ld a,[wZhTextEnd+1]
 cp h
 jr nz,.peek
 ld a,[wZhTextEnd]
 cp l
 jr z,.finish
.peek
 ld a,[hl]
 call ZhIsStableLead
 jr nc,.finish
 pop hl
 jp .loop
.finish
 pop hl
 ld a,[wZhNameBuffer+9]
 and a
 ret z
 ld a,[wZhNameBuffer+4]
 ld b,a
 ld a,[wZhNameBuffer+5]
 ld c,a
 ld de,$ffff
.draw
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 call ZhPlaceCacheBlock
 pop bc
 ld a,b
 ldh [rWBK],a
 ret
.bad
 pop hl
 scf
 ret
