; Compile-time strip pair command consumed by PlaceString.
; Caller supplies a reviewed scene policy and a destination in wTilemap.
; DE points at command, HL at upper cell. Source may be ROM in any bank.
; Preserve BC, advance DE by five and HL by one only on success.
ZhPlaceEncodedPair::
 push bc
 push hl
 push de
 ; A=source ROM bank from the home adapter.
 ld b, a
 inc de
 ld h, d
 ld l, e
 ld a, b
 call GetFarByte
 push af
 inc hl
 ld a, b
 call GetFarByte
 push af
 inc hl
 ld a, b
 call GetFarByte
 push af
 inc hl
 ld a, b
 call GetFarByte
 ld e, a
 pop af
 ld d, a
 pop af
 ld c, a
 pop af
 ld b, a
 ; Recover destination before switching WRAM; source payload is in registers.
 ld hl, sp + 2
 ld a, [hli]
 ld h, [hl]
 ld l, a
 ldh a, [rWBK]
 push af
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 call ZhPlaceCacheBlock
 pop bc
 ld a, b
 ldh [rWBK], a
 jr c, .failed
 pop de
 pop bc ; old HL, advanced HL retained
 rept 5
 inc de
 endr
 pop bc
 and a
 ret
.failed
 pop de
 pop hl
 pop bc
 scf
 ret

; Dynamic names alone are paired at runtime; ordinary text is precompiled.
; DE=validated WRAM0 name, HL=upper tile. Return both advanced.
ZhPlaceDynamicName::
 ld a, [de]
 cp $53
 jr z, .done
 push de
 push hl
 cp $7f
 jr z, .space
 sub $80
 add a
 ld c, a
 ld b, $c0
 ld d, b
 ld e, c
 inc de
 jr .draw
.space
 ld bc, $ffff
 ld de, $ffff
.draw
 ldh a, [rWBK]
 push af
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 call ZhPlaceCacheBlock
 pop bc
 ld a, b
 ldh [rWBK], a
 jr c, .bad
 pop bc
 pop de
 inc de
 jr ZhPlaceDynamicName
.bad
 pop hl
 pop de
 scf
 ret
.done
 and a
 ret
