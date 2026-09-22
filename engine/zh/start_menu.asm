ASSERT ZH_START_MENU_STEP == 2 ; original menu cursor and row advance
ASSERT ZH_START_MENU_WIDTH == 19 - ZH_START_MENU_LEFT
; The original menu owns item selection and 16px row spacing.
; Only this consumer uses START_MENU strips, never dialogue placement.
ZhPrepareStartMenuText::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 jp ZhEnterFontText

; DE=original row anchor. Player name remains live save data.
ZhDrawStartMenuPlayer::
 push de
 xor a
 call ZhStageEnglishName
 pop de
 ret c
 push hl
 ld h, d
 ld l, e
 ld bc, (ZH_START_MENU_TOP - 2) * SCREEN_WIDTH + ZH_START_MENU_LEFT - 12
 add hl, bc
 call ZhPrepareStartMenuText
 pop de
 jp ZhPlaceStartMenuName
