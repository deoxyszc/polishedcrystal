ZhHidePage::
 push bc
 push hl
 hlcoord 1, 13
 ld b, 4
.row
 ld c, 18
 ld a, $7f
.tile
 ld [hli], a
 dec c
 jr nz, .tile
 inc hl
 inc hl
 dec b
 jr nz, .row
 hlcoord 1, 13, wAttrmap
 ld b, 4
.attrrow
 ld c, 18
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 inc hl
 inc hl
 dec b
 jr nz, .attrrow
 pop hl
 pop bc
 and a
 ret
