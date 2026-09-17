; Display-only translated default names. Custom nicknames retain legacy display.
; A=side (0 player, 1 enemy), DE=legacy nickname. Carry set: no match.
; Caller owns normal battle WRAM bank. No save or battle data is modified.
ZhDrawBattleName::
 ld [wZhHudSide],a
 ld a,e
 ld [wZhHudName],a
 ld a,d
 ld [wZhHudName+1],a
 ld hl,ZhBattleNameTable
.next
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 or c
 jp z,.missing
 push hl
 ld h,b
 ld l,c
 ld a,[wZhHudName]
 ld e,a
 ld a,[wZhHudName+1]
 ld d,a
 ld b,10
.compare
 ld a,[de]
 cp [hl]
 jr nz,.mismatch
 inc de
 inc hl
 dec b
 jr nz,.compare
 pop bc
 ld a,[hli]
 ld [wZhHudWidth],a
 add a
 ld c,a
 ld d,h
 ld e,l
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld a,[wZhHudSide]
 and a
 ld hl,$8ca0
 jr z,.upload
 ld hl,$8de0
.upload
 ld b,BANK(ZhBattleNameTable)
 call Get2bpp
 pop af
 ldh [rVBK],a
 ld a,[wZhHudSide]
 and a
 hlcoord 8,7
 ld a,$ca
 jr z,.place
 hlcoord 1,0
 ld a,$de
.place
 ld b,2
.row
 push hl
 ld c,a
 ld a,[wZhHudWidth]
 ld e,a
 ld a,c
.tile
 ld [hli],a
 inc a
 dec e
 jr nz,.tile
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 dec b
 jr nz,.row
 ld a,[wZhHudSide]
 and a
 ld a,[wZhHudWidth]
 jr nz,.enemy
 ld [wZhPlayerHudWidth],a
 jr .finish
.enemy
 ld [wZhEnemyHudWidth],a
.finish
 call ZhBattleNameAttributes
 call ApplyAttrAndTilemapInVBlank
 and a
 ret
.mismatch
 pop hl
 jp .next
.missing
 scf
 ret

; Called after the original battle palette layout; only mark translated cells.
ZhBattleNameAttributes::
 hlcoord 8,7,wAttrmap
 ld a,[wZhPlayerHudWidth]
 call .fill
 hlcoord 1,0,wAttrmap
 ld a,[wZhEnemyHudWidth]
.fill
 and a
 ret z
 ld c,a
 ld b,2
.row
 push hl
 push bc
 ld a,$0f
.col
 ld [hli],a
 dec c
 jr nz,.col
 pop bc
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 dec b
 jr nz,.row
 ret
