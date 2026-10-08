INCLUDE "constants/zh_summary_blue.asm"
ZhSummaryBlueLayout:
 ld de,.labels
 ld b,5
.loop
 push bc
 ld a,[de]
 inc de
 ld l,a
 ld a,[de]
 inc de
 ld h,a
 push hl
 push de
 ld bc,wAttrmap-wTilemap
 add hl,bc
 lb bc,2,3
 ld a,SUMMARY_PAL_SIDE_WINDOW
 call FillBoxWithByte
 pop de
 pop hl
 ld a,[de]
 inc de
 ld c,a
 ld a,[de]
 inc de
 push de
 ld d,a
 ld e,c
 ld a,BANK(ZhBlueAttack)
 call FarString
 pop de
 pop bc
 dec b
 jr nz,.loop
 jp ZhBlueTab
.labels
 dw wTilemap+ZH_BLUE_ATTACK_TY*SCREEN_WIDTH+ZH_BLUE_ATTACK_TX,ZhBlueAttack
 dw wTilemap+ZH_BLUE_DEFENSE_TY*SCREEN_WIDTH+ZH_BLUE_DEFENSE_TX,ZhBlueDefense
 dw wTilemap+ZH_BLUE_SPATK_TY*SCREEN_WIDTH+ZH_BLUE_SPATK_TX,ZhBlueSpAtk
 dw wTilemap+ZH_BLUE_SPDEF_TY*SCREEN_WIDTH+ZH_BLUE_SPDEF_TX,ZhBlueSpDef
 dw wTilemap+ZH_BLUE_SPEED_TY*SCREEN_WIDTH+ZH_BLUE_SPEED_TX,ZhBlueSpeed
ZhBlueTab:
 hlcoord 2,11
 ld de,ZhBlueTabKeys
 jp ZhSummaryTab
INCLUDE "data/zh/summary_blue.asm"
