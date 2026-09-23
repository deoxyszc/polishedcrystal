ZhBattleHudName::
 push hl
 ld hl,ZhBattleHudNames
.next
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 or c
 jr z,.missing
 push hl
 push de
 ld h,b
 ld l,c
 ld b,10
.compare
 ld a,[de]
 cp [hl]
 jr nz,.mismatch
 inc de
 inc hl
 dec b
 jr nz,.compare
 pop de
 pop bc
 ld a,[hli]
 ld d,h
 ld e,l
 pop hl
 push de
 ld b,a
 ld a,l
 cp LOW(wTilemap + 7 * SCREEN_WIDTH)
 jr c,.enemy
 ld a,16
 sub b
 ld e,a
 ld d,0
 hlcoord 0,7
 add hl,de
 jr .positioned
.enemy
 ld a,b
 ld [wZhHudEnemyWidth],a
 hlcoord 1,0
.positioned
 pop de
 ld a,BANK(ZhBattleHudNames)
 jp FarString
.mismatch
 pop de
 pop hl
 jr .next
.missing
 pop hl
 xor a
 ld [wZhHudEnemyWidth],a
 ld a,l
 cp LOW(wTilemap + 7 * SCREEN_WIDTH)
 jr c,.fallbackDraw
 hlcoord 10,7
.fallbackDraw
 rst PlaceString
 ret

ZhBattleHudMetadataAttrs::
 hlcoord 1,2,wAttrmap
 ld b,9
.bar
 ld [hl],PAL_BATTLE_BG_ENEMY_HP
 inc hl
 dec b
 jr nz,.bar
 hlcoord 16,8,wAttrmap
 ld [hl],PAL_BATTLE_BG_EXP_GENDER
 inc hl
 ld a,PAL_BATTLE_BG_TEXT
 ld [hli],a
 ld [hli],a
 ld [hl],a
 ld a,[wZhHudEnemyWidth]
 and a
 ret z
 inc a
 ld e,a
 ld d,0
 hlcoord 0,1,wAttrmap
 add hl,de
 ld [hl],PAL_BATTLE_BG_EXP_GENDER
 inc hl
 ld a,PAL_BATTLE_BG_TEXT
 ld [hli],a
 ld [hli],a
 ld [hl],a
 dec hl
 dec hl
 ld a,[wEnemyMonStatus]
 and a
 ret z
 ld a,PAL_BATTLE_BG_STATUS
 ld [hli],a
 ld [hl],a
 ret
