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
 jr nz,.enemyPosition
 hlcoord 16,7
 ld a,[wZhHudWidth]
 cpl
 inc a
 ld e,a
 ld d,$ff
 add hl,de
 ld a,$ca
 jr .place
.enemyPosition
 ld a,[wZhHudWidth]
 call ZhEnemyNameStart
 hlcoord 0,0
 add hl,de
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
 hlcoord 16,7,wAttrmap
 ld a,[wZhPlayerHudWidth]
 and a
 jr z,.enemyAttrs
 cpl
 inc a
 ld e,a
 ld d,$ff
 add hl,de
 ld a,[wZhPlayerHudWidth]
 call .fill
.enemyAttrs
 ld a,[wZhEnemyHudWidth]
 call ZhEnemyNameStart
 hlcoord 0,0,wAttrmap
 add hl,de
 ld a,[wZhEnemyHudWidth]
 call .fill
 hlcoord 17,8,wAttrmap
 ld a,PAL_BATTLE_BG_TEXT
 ld [hli],a
 ld [hli],a
 ld [hl],a
 ; Explicit native bank and palette for every metadata cell, including fallback.
 hlcoord 16,8,wAttrmap
 ld [hl],PAL_BATTLE_BG_EXP_GENDER
 hlcoord 10,9,wAttrmap
 ld [hl],PAL_BATTLE_BG_PLAYER_HP
 hlcoord 10,10,wAttrmap
 ld a,PAL_BATTLE_BG_STATUS
 ld [hli],a
 ld [hl],a
 call ZhEnemyMetadataPositions
 hlcoord 0,1,wAttrmap
 add hl,de
 ld a,PAL_BATTLE_BG_TEXT
 ld [hli],a
 ld [hli],a
 ld [hl],a
 push bc
 hlcoord 0,0,wAttrmap
 add hl,bc
 ld [hl],PAL_BATTLE_BG_EXP_GENDER
 pop bc
 hlcoord 0,2,wAttrmap
 ld [hl],PAL_BATTLE_BG_ENEMY_HP
 ld a,[wEnemyMonStatus]
 and a
 ret z
 call ZhEnemyMetadataPositions
 hlcoord 0,1,wAttrmap
 add hl,de
 ld a,PAL_BATTLE_BG_STATUS
 ld [hli],a
 ld [hl],a
 ret

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

; A=rendered width in tiles. Short names begin inward; longer names expand left.
ZhEnemyNameStart:
 ld de,1
 cp 6
 ret nc
 inc e
 cp 5
 ret nc
 inc e
 ret

; BC=gender offset from row0; DE=level/status X on row1.
; Shared by text and attributes so palette cells track the actual placement.
ZhEnemyMetadataPositions::
 ld a,[wZhEnemyHudWidth]
 and a
 jr z,.long
 cp 7
 jr nc,.long
 push af
 call ZhEnemyNameStart
 pop af
 add e
 ld c,a
 ld b,0
 inc a
 ld e,a
 ld d,0
 ld a,c
 add SCREEN_WIDTH
 ld c,a
 ret
.long
 ld bc,8
 ld de,8
 ret
