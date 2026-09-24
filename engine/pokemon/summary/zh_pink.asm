ZhSummaryPinkLayout:
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld b,12
.save2
 ld a,[hli]
 push af
 dec b
 jr nz,.save2
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld b,12
.save1
 ld a,[hli]
 push af
 dec b
 jr nz,.save1
 ; Retain original type/ball, OT and ID/status rows while opening 16px names.
 hlbgcoord 0,5,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+ZH_PINK_OT_ID_WY*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+ZH_PINK_OT_WY*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+ZH_PINK_TYPES_WY*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,1,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,2,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord ZH_PINK_SPECIES_WX,ZH_PINK_SPECIES_WY,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord ZH_PINK_SPECIES_WX+16,ZH_PINK_SPECIES_WY,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,4,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,7,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,7,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 11,1,wSummaryScreenWindowBuffer
 ld b,12
.restore1
 pop af
 ld [hld],a
 dec b
 jr nz,.restore1
 hlbgcoord 11,3,wSummaryScreenWindowBuffer
 ld b,12
.restore3
 pop af
 ld [hld],a
 dec b
 jr nz,.restore3
 ld a,ZH_PINK_TYPES_Y+16
 ld [wSummaryScreenOAMSprite04YCoord],a
 ld [wSummaryScreenOAMSprite05YCoord],a
 ld [wSummaryScreenOAMSprite06YCoord],a
 ld [wSummaryScreenOAMSprite07YCoord],a
 ld a,[wBaseType1]
 ld b,a
 ld a,[wBaseType2]
 cp b
 jr z,.ball
 ld a,ZH_PINK_TYPES_Y+16
 ld [wSummaryScreenOAMSprite08YCoord],a
 ld [wSummaryScreenOAMSprite09YCoord],a
 ld [wSummaryScreenOAMSprite10YCoord],a
 ld [wSummaryScreenOAMSprite11YCoord],a
.ball
 hlbgcoord 8,ZH_PINK_TYPES_WY,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+ZH_PINK_BALL_WY*32+ZH_PINK_BALL_WX
 ld bc,3
 rst CopyBytes
 hlbgcoord 24,ZH_PINK_TYPES_WY,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+ZH_PINK_BALL_WY*32+ZH_PINK_BALL_WX+16
 ld bc,3
 rst CopyBytes
 hlbgcoord 8,ZH_PINK_TYPES_WY,wSummaryScreenWindowBuffer
 ld bc,3
 ld a,$7f
 rst ByteFill
 hlbgcoord 24,ZH_PINK_TYPES_WY,wSummaryScreenWindowBuffer
 ld bc,3
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 ld a,ZH_PINK_BALL_OAM_Y
 ld [wSummaryScreenOAMSprite12YCoord],a
 ld a,ZH_PINK_BALL_OAM_Y+16
 ld [wSummaryScreenOAMSprite13YCoord],a
 ld a,ZH_PINK_BALL_OAM_X
 ld [wSummaryScreenOAMSprite12XCoord],a
 ld [wSummaryScreenOAMSprite13XCoord],a
 farcall ZhSummaryNames
 hlbgcoord ZH_PINK_BALL_WX+17,ZH_PINK_BALL_WY,wSummaryScreenWindowBuffer
 ld [hl],SUMMARY_PAL_POKEBALL
 call ZhSummaryPinkLabels
 ret

ZhSummaryPinkLabels::
 ; Clear native slash, then use the same 16px baseline as the species.
 hlbgcoord ZH_PINK_SPECIES_WX,ZH_PINK_SPECIES_WY,wSummaryScreenWindowBuffer
 ld [hl],$7f
 hlbgcoord ZH_PINK_SPECIES_WX,ZH_PINK_SPECIES_WY,wSummaryScreenWindowBuffer
 ld de,ZhSummarySlash
 ld a,BANK(ZhSummarySlash)
 call FarString
 ; Live trainer name is retained, only its heading and placement change.
 hlbgcoord ZH_PINK_OT_WX,ZH_PINK_OT_WY,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord ZH_PINK_OT_WX,ZH_PINK_OT_WY,wSummaryScreenWindowBuffer
 call ZhSummaryCombinedOT
 ; Original experience calculations and bar remain authoritative.
 hlcoord 0,13
 ld bc,SCREEN_WIDTH*3
 ld a,$7f
 rst ByteFill
 hlcoord ZH_PINK_EXP_TX,ZH_PINK_EXP_TY
 ld de,ZhSummaryExp
 ld a,BANK(ZhSummaryExp)
 call FarString
 hlcoord ZH_PINK_EXP_TX+3,ZH_PINK_EXP_TY
 ld de,wTempMonExp
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call ZhSummaryNumber
 ld a,[wTempMonLevel]
 cp MAX_LEVEL
 jr z,.skipNeeded
 hlcoord ZH_PINK_NEEDED_TX,ZH_PINK_NEEDED_TY
 ld de,ZhSummaryNeed
 ld a,BANK(ZhSummaryNeed)
 call FarString
 hlcoord ZH_PINK_NEEDED_TX+3,ZH_PINK_NEEDED_TY
 ld de,wExpToNextLevel
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call ZhSummaryNumber
 push hl
 ld a,[wExpToNextLevel]
 ld b,a
 ld a,[wExpToNextLevel+1]
 or b
 ld b,a
 ld a,[wExpToNextLevel+2]
 or b
 jr z,.zeroNeeded
 ld de,ZhSummaryExp
 ld a,BANK(ZhSummaryExp)
 call FarString
.zeroNeeded
 pop hl
.skipNeeded
 hlcoord ZH_PINK_NEXT_LEVEL_TX,ZH_PINK_NEXT_LEVEL_TY
 ld bc,7
 ld a,$7f
 rst ByteFill
 hlcoord ZH_PINK_NEXT_LEVEL_TX,ZH_PINK_NEXT_LEVEL_TY+1
 ld bc,7
 ld a,$7f
 rst ByteFill
 ld a,[wTempMonLevel]
 cp MAX_LEVEL
 jr z,.atMaximum
 hlcoord ZH_PINK_NEXT_LEVEL_TX,ZH_PINK_NEXT_LEVEL_TY
 cp MAX_LEVEL-1
 jr c,.nextFits
 dec hl
.nextFits
 ld de,ZhSummaryLevelUp
 ld a,BANK(ZhSummaryLevelUp)
 call FarString
 ld a,[wTempMonLevel]
 cp MAX_LEVEL
 jr z,.max
 inc a
.max
 ld [wTextDecimalByte],a
 hlcoord ZH_PINK_NEXT_LEVEL_TX+3,ZH_PINK_NEXT_LEVEL_TY
 cp 100
 jr c,.numberFits
 dec hl
.numberFits
 ld de,wTextDecimalByte
 lb bc,PRINTNUM_LEFTALIGN | 1,3
 call ZhSummaryNumber
 ld de,ZhSummaryLevel
 ld a,BANK(ZhSummaryLevel)
 call FarString
 jr .levelDone
.atMaximum
 hlcoord ZH_PINK_NEXT_LEVEL_TX,ZH_PINK_NEXT_LEVEL_TY
 ld de,ZhSummaryMax
 ld a,BANK(ZhSummaryMax)
 call FarString
.levelDone
 ; Restore the existing tab edge, clear its old font cells and draw text.
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 hlcoord ZH_PINK_TAB_TX,ZH_PINK_TAB_TY
 lb bc,2,3
 call ClearBox
 hlcoord ZH_PINK_TAB_TX,ZH_PINK_TAB_TY,wAttrmap
 lb bc,2,3
 ld a,SUMMARY_PAL_LOWER_WINDOW
 call FillBoxWithByte
 jp ZhSummaryDrawTab

; Format live numbers using original PrintNum, then draw the resulting bytes.
ZhSummaryNumber:
 push hl
 ld hl,wStringBuffer2+4
 call PrintNum
 ld a,$53
 ld [hl],a
 ld a,l
 sub LOW(wStringBuffer2+4)
 or $80
 ld [wStringBuffer2+3],a
 ld a,10
 ld [wStringBuffer2],a
 ld a,130
 ld [wStringBuffer2+1],a
 ld a,128
 ld [wStringBuffer2+2],a
 pop hl
 ld de,wStringBuffer2
 ld a,BANK(ZhSummaryNumber)
 call FarString
 ld h,b
 ld l,c
 ret

ZhSummaryCombinedOT:
 ld hl,ZhSummaryOT+4
 ld de,wStringBuffer2+4
 ld bc,7
 rst CopyBytes
 ld hl,wTempMonOT
 ld b,PLAYER_NAME_LENGTH-1
 ld c,7
.copy
 ld a,[hli]
 cp $53
 jr z,.done
 ld [de],a
 inc de
 inc c
 dec b
 jr nz,.copy
.done
 ld a,$53
 ld [de],a
 ld a,c
 or $80
 ld [wStringBuffer2+3],a
 ld a,10
 ld [wStringBuffer2],a
 ld a,130
 ld [wStringBuffer2+1],a
 ld a,128
 ld [wStringBuffer2+2],a
 hlbgcoord ZH_PINK_OT_WX,ZH_PINK_OT_WY,wSummaryScreenWindowBuffer
 ld de,wStringBuffer2
 ld a,BANK(ZhSummaryCombinedOT)
 jp FarString

ZhSummaryDrawTab:
 hlcoord ZH_PINK_TAB_TX,ZH_PINK_TAB_TY
 ld de,ZhSummaryTabKeys
 ld a,3
.loop
 push af
 push hl
 ld h,d
 ld l,e
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 ld a,[hli]
 ld e,a
 ld a,[hli]
 ld d,a
 push hl
 ld hl,sp+2
 ld a,[hli]
 ld h,[hl]
 ld l,a
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhPlaceCacheBlock
 pop af
 ldh [rWBK],a
 pop de
 pop bc
 pop af
 dec a
 jr nz,.loop
 ret

INCLUDE "data/zh/summary_pink.asm"
