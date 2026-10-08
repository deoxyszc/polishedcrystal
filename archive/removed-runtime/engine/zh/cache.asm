ZhHideDialogue::
 push bc
 push hl
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP
 ld b, ZH_DIALOGUE_STEP + 2
.row
 ld c, ZH_DIALOGUE_WIDTH
 ld a, $7f
.tile
 ld [hli], a
 dec c
 jr nz, .tile
 rept SCREEN_WIDTH - ZH_DIALOGUE_WIDTH
 inc hl
 endr
 dec b
 jr nz, .row
 hlcoord ZH_DIALOGUE_LEFT, ZH_DIALOGUE_TOP, wAttrmap
 ld b, ZH_DIALOGUE_STEP + 2
.attrrow
 ld c, ZH_DIALOGUE_WIDTH
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 rept SCREEN_WIDTH - ZH_DIALOGUE_WIDTH
 inc hl
 endr
 dec b
 jr nz, .attrrow
 pop hl
 pop bc
 and a
 ret

ZhHideMoveList::
 push bc
 push hl
 hlcoord ZH_MOVE_LIST_LEFT, ZH_MOVE_LIST_TOP
 ld b, 8
.row
 ld c, 9
 ld a, $7f
.tile
 ld [hli], a
 dec c
 jr nz, .tile
 rept SCREEN_WIDTH - 9
 inc hl
 endr
 dec b
 jr nz, .row
 hlcoord ZH_MOVE_LIST_LEFT, ZH_MOVE_LIST_TOP, wAttrmap
 ld b, 8
.attrrow
 ld c, 9
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 rept SCREEN_WIDTH - 9
 inc hl
 endr
 dec b
 jr nz, .attrrow
 pop hl
 pop bc
 and a
 ret
