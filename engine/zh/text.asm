; Compiled dialogue runs use the shared PlaceString pair command.
; Runtime work is limited to controls and names that depend on save data.
ZhRunText::
 ld a, l
 ld [wZhTextCursor], a
 ld a, h
 ld [wZhTextCursor + 1], a
 ld a, e
 ld [wZhTextEnd], a
 ld a, d
 ld [wZhTextEnd + 1], a
 xor a
 ld [wZhTextSlot], a
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP
.next
 push hl
 ld a, [wZhTextCursor]
 ld l, a
 ld a, [wZhTextCursor + 1]
 ld h, a
 ld a, [wZhTextEnd]
 ld e, a
 ld a, [wZhTextEnd + 1]
 ld d, a
 ld a, h
 cp d
 jr c, .read
 jp nz, .bad
 ld a, l
 cp e
 jp nc, .bad
.read
 ld a, [hli]
 ld [wZhTextControl], a
 call ZhIsStableTextByte
 jr nc,.notStable
 dec hl
 call .saveCursor
 pop hl
 call ZhPlaceStableRun
 ret c
 jp .next
.notStable
 cp ZH_CTRL_AT
 jr z, .advance
 cp ZH_CTRL_RAM
 jp z, .ram
 cp ZH_CTRL_PLAYER
 jp z, .player
 cp ZH_CTRL_RIVAL
 jp z, .rival
.advance
 call .saveCursor
 pop hl
 ld a, [wZhTextControl]
 cp ZH_CTRL_AT
 jr z, .next
 cp ZH_CTRL_DONE
 ret z
 cp ZH_CTRL_PROMPT
 jp z, .prompt
 cp ZH_CTRL_WAIT
 jr z, .wait
 cp ZH_CTRL_NEXT
 jr z, .bottom
 cp ZH_CTRL_LINE
 jr z, .bottom
 cp ZH_CTRL_PARA
 jr z, .page
 cp ZH_CTRL_CONT
 jp z, .scroll
 scf
 ret
.wait
 push hl
 call ApplyAttrAndTilemapInVBlank
 call WaitButton
 pop hl
 jp .next
.bottom
 ld a, 1
 ld [wZhTextSlot], a
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP + ZH_DIALOGUE_STEP
 jp .next
.page
 call ApplyAttrAndTilemapInVBlank
 call WaitButton
 call ZhHideDialogue
 call ApplyAttrAndTilemapInVBlank
 xor a
 ld [wZhTextSlot], a
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP
 jp .next
.scroll
 call ApplyAttrAndTilemapInVBlank
 call WaitButton
 ; Shift IDs and attributes together; surviving glyphs stay live.
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP + ZH_DIALOGUE_STEP
 decoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP
 call .scrollMap
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP + ZH_DIALOGUE_STEP, wAttrmap
 decoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP, wAttrmap
 call .scrollMap
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP + ZH_DIALOGUE_STEP
 lb bc, 2, ZH_DIALOGUE_WIDTH
 call ClearBox
 call ApplyAttrAndTilemapInVBlank
 jp .bottom
.scrollMap
 ld b, 2
.row
 ld c, ZH_DIALOGUE_WIDTH
.cell
 ld a, [hli]
 ld [de], a
 inc de
 dec c
 jr nz, .cell
 rept SCREEN_WIDTH - ZH_DIALOGUE_WIDTH
 inc hl
 inc de
 endr
 dec b
 jr nz, .row
 ret
.prompt
 call ApplyAttrAndTilemapInVBlank
 call WaitButton
 and a
 ret
.bad
 pop hl
 scf
 ret
.saveCursor
 ld a, l
 ld [wZhTextCursor], a
 ld a, h
 ld [wZhTextCursor + 1], a
 ret
.player
 call .saveCursor
 xor a
 jr .name
.rival
 call .saveCursor
 ld a, 1
.name
 call ZhStageEnglishName
 jr c, .bad
 jr .nameReady
.ram
 push hl
 ld bc, 3
 add hl, bc
 jr c, .badRam
 ld a, h
 cp d
 jr c, .ramReady
 jr nz, .badRam
 ld a, l
 cp e
 jr c, .ramReady
 jr z, .ramReady
.badRam
 pop hl
 jp .bad
.ramReady
 pop hl
 ld b, [hl]
 inc hl
 ld a, [hli]
 ld e, a
 ld d, [hl]
 inc hl
 call .saveCursor
 ld h, d
 ld l, e
 call ZhStageRAMName
 jr c, .bad
.nameReady
 ld d, h
 ld e, l
 pop hl
 call ZhPlaceDynamicName
 ret c
 jp .next
