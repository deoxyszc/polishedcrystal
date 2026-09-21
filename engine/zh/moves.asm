; Carry set when a selected move exceeds its composed cell (72px left,
; 56px right after the cursor and 80px column offset in a 144px line).
ZhCanDrawMoveGrid::
 ; Reordering uses the original list and its original swap-marker geometry.
 ld a,[wMoveSwapBuffer]
 and a
 jr nz,.wide
 ld hl,wListMoves_MoveIndicesBuffer
 ld b,4
.loop
 ld a,[hli]
 and a
 jr z,.ok
 push hl
 push bc
 ld e,a
 ld d,0
 ld hl,ZhMoveNameWidths
 add hl,de
 ld a,BANK(ZhMoveNameWidths)
 call GetFarByte
 ld e,a
 pop bc
 pop hl
 bit 0,b
 ld a,e
 jr nz,.right
 cp 73
 jr .checked
.right
 cp 57
.checked
 jr nc,.wide
 dec b
 jr nz,.loop
.ok
 and a
 ret
.wide
 scf
 ret

; Four move slots in a 2x2 grid. Screen rows 13..16, never EXP row11.
ZhDrawMoveGrid::
 call ZhHidePage
 call ApplyAttrAndTilemapInVBlank
 ldh a, [rWBK]
 push af
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 call ZhEnterFontText
 call ZhGlyphCacheRecover
 pop af
 ldh [rWBK], a
 xor a
 ld [wZhMoveIndex], a
.next
 ld a, [wZhMoveIndex]
 ld e, a
 ld d, 0
 ld hl, wListMoves_MoveIndicesBuffer
 add hl, de
 ld c, [hl]
 ld b, 0
 ld hl, ZhMoveNames
 add hl, bc
 add hl, bc
 ld a, BANK(ZhMoveNames)
 call GetFarByte
 ld e, a
 inc hl
 ld a, BANK(ZhMoveNames)
 call GetFarByte
 ld d, a
 ld a, [wZhMoveIndex]
 hlcoord 2, 13
 bit 1, a
 jr z, .column
 hlcoord 2, 15
.column
 bit 0, a
 jr z, .draw
 ld bc, 10
 add hl, bc
.draw
 ld a, BANK(ZhMoveNames)
 call FarString
 ld hl, wZhMoveIndex
 inc [hl]
 ld a, [hl]
 cp 4
 jr c, .next
 jp ApplyAttrAndTilemapInVBlank

; Return physical cursor location from original 1-based linear move selection.
ZhMoveCursorCoord::
 ; Cursor cells are static spaces, never borrowed glyph slots.
 hlcoord 1,13
 ld [hl],$7f
 hlcoord 1,13,wAttrmap
 ld [hl],7
 hlcoord 11,13
 ld [hl],$7f
 hlcoord 11,13,wAttrmap
 ld [hl],7
 hlcoord 1,14
 ld [hl],$7f
 hlcoord 1,14,wAttrmap
 ld [hl],7
 hlcoord 11,14
 ld [hl],$7f
 hlcoord 11,14,wAttrmap
 ld [hl],7
 hlcoord 1,15
 ld [hl],$7f
 hlcoord 1,15,wAttrmap
 ld [hl],7
 hlcoord 11,15
 ld [hl],$7f
 hlcoord 11,15,wAttrmap
 ld [hl],7
 hlcoord 1,16
 ld [hl],$7f
 hlcoord 1,16,wAttrmap
 ld [hl],7
 hlcoord 11,16
 ld [hl],$7f
 hlcoord 11,16,wAttrmap
 ld [hl],7
 ld a,[wMenuCursorY]
 dec a
 bit 1,a
 hlcoord 1,13
 jr z,.column
 hlcoord 1,15
.column
 bit 0,a
 jr z,.cursorAttr
 ld bc,10
 add hl,bc
.cursorAttr
 push hl
 hlcoord 1,9,wAttrmap
 ld b,6
.infoAttrs
 ld [hl],PAL_BATTLE_BG_TYPE_CAT
 inc hl
 dec b
 jr nz,.infoAttrs
 pop hl
 push hl
 ld [hl],$c8
 ld bc,SCREEN_WIDTH
 add hl,bc
 ld [hl],$c9
 pop hl
 push hl
 ld bc,wAttrmap-wTilemap
 add hl,bc
 ld [hl],$0f
 ld bc,SCREEN_WIDTH
 add hl,bc
 ld [hl],$0f
 ; Dedicated 8x16 cursor: center y8 matches 12px text at offset2.
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld hl,$8c80
 ld de,ZhMoveCursorTiles
 ld b,BANK(ZhMoveCursorTiles)
 ld c,2
 call Get2bpp
 pop af
 ldh [rVBK],a
 pop hl
 ret

ZhMoveCursorTiles:
 db 0,0,0,0,0,0,0,0,0,0,$80,$80,$c0,$c0,$e0,$e0
 db $f0,$f0,$e0,$e0,$c0,$c0,$80,$80,0,0,0,0,0,0,0,0
