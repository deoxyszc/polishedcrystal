; Shared text-engine command. HL points after ZH_STREAM_COMMAND in the
; original bank. Descriptor contains little-endian [start,end) in bank $80.
; Preserve caller coordinates and advance HL past the descriptor.
ZhDispatchText::
 push bc
 ld a,b
 call GetFarByte
 inc hl
 ld c,a
 ld a,b
 call GetFarByte
 inc hl
 push af
 ld a,b
 call GetFarByte
 inc hl
 ld e,a
 ld a,b
 call GetFarByte
 inc hl
 ld d,a
 pop af
 push hl
 ld h,a
 ld l,c
 call ZhShowDialogue
 pop hl
 pop bc
 ld a,1
 ldh [hStopPrintingString],a
 ret
