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

ZhHideMoveGrid::
 push bc
 push hl
 hlcoord ZH_MOVE_GRID_LEFT, ZH_MOVE_GRID_TOP
 ld b, ZH_MOVE_GRID_STEP + 2
.row
 ld c, ZH_MOVE_GRID_WIDTH
 ld a, $7f
.tile
 ld [hli], a
 dec c
 jr nz, .tile
 rept SCREEN_WIDTH - ZH_MOVE_GRID_WIDTH
 inc hl
 endr
 dec b
 jr nz, .row
 hlcoord ZH_MOVE_GRID_LEFT, ZH_MOVE_GRID_TOP, wAttrmap
 ld b, ZH_MOVE_GRID_STEP + 2
.attrrow
 ld c, ZH_MOVE_GRID_WIDTH
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 rept SCREEN_WIDTH - ZH_MOVE_GRID_WIDTH
 inc hl
 endr
 dec b
 jr nz, .attrrow
 pop hl
 pop bc
 and a
 ret
