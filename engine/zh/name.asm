; D1 explicit English display-name staging; no save-format or token changes.
; A=0 player, 1 rival. Success HL=wZhNameBuffer, BC=length excluding @,
; carry clear. Failure carry set, destination untouched. AF/BC/DE/HL clobber.
; rWBK restored. Caller provides 12-byte WRAM0 wZhNameBuffer.
; Source names may not be mutated concurrently during this synchronous call.
ZhStageEnglishName::
 cp 2
 jr nc,.invalidSource
 ld hl,wPlayerName
 and a
 jr z,.selected
 ld hl,wRivalName
.selected
 ASSERT BANK(wPlayerName) == BANK(wRivalName)
 ASSERT NAME_LENGTH == 11
 ldh a,[rWBK]
 push af
 ld a,BANK(wPlayerName)
 ldh [rWBK],a
 push hl
 ld b,NAME_LENGTH
 ld c,0
.validate
 ld a,[hli]
 cp $53
 jr z,.valid
 cp $7f
 jr c,.invalid
 cp $f2
 jr nc,.invalid
 inc c
 dec b
 jr nz,.validate
.invalid
 pop hl
 pop af
 ldh [rWBK],a
.invalidSource
 scf
 ret
.valid
 pop hl
 ld de,wZhNameBuffer
 ld b,c
 inc b ; copy terminator too
.copy
 ld a,[hli]
 ld [de],a
 inc de
 dec b
 jr nz,.copy
 pop af
 ldh [rWBK],a
 ld hl,wZhNameBuffer
 ld b,0
 and a
 ret
