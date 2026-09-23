; Carry set when a move exceeds the 64px vertical-list text region.
ZhCanDrawMoveList::
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
 ld a,e
 cp 65
 jr nc,.wide
 dec b
 jr nz,.loop
.ok
 and a
 ret
.wide
 scf
 ret

; Four vertical slots, with independent 16px line spacing.
ZhDrawMoveList::
 call ZhHideMoveList
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
 push de
 ld a,[wZhMoveIndex]
 hlcoord 2,9
 ld bc,SCREEN_WIDTH * 2
 rst AddNTimes
 pop de
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
 hlcoord 1,9
 ld b,8
.clear
 ld [hl],$7f
 ld de,SCREEN_WIDTH
 add hl,de
 dec b
 jr nz,.clear
 ld a,[wMenuCursorY]
 dec a
 hlcoord 1,9
 ld bc,SCREEN_WIDTH * 2
 rst AddNTimes
 push hl
 hlcoord 11,13,wAttrmap
 ld b,6
.infoAttrs
 ld [hl],PAL_BATTLE_BG_TYPE_CAT
 inc hl
 dec b
 jr nz,.infoAttrs
 pop hl
ZhDrawTallBattleCursor::
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

; Preserve coordinate and move-property registers; carry selects legacy geometry.
ZhUseVerticalMoveList::
 push bc
 push de
 push hl
 ld a,[wMoveSelectionMenuType]
 and a
 scf
 jr nz,.done
 call ZhCanDrawMoveList
.done
 pop hl
 pop de
 pop bc
 ret

ZhBattleCommandCursor::
 hlcoord 7,13
 ld b,4
.clear
 ld [hl],$7f
 push hl
 ld de,6
 add hl,de
 ld [hl],$7f
 pop hl
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],PAL_BATTLE_BG_TEXT
 ld de,6
 add hl,de
 ld [hl],PAL_BATTLE_BG_TEXT
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 dec b
 jr nz,.clear
 hlcoord 7,13
 ld a,[wMenuCursorY]
 dec a
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 ld a,[wMenuCursorX]
 dec a
 ld bc,6
 rst AddNTimes
 jp ZhDrawTallBattleCursor

ZhPartyActionCursor::
 hlcoord 14,11
 ld b,6
.clear
 ld [hl],$7f
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],PAL_BATTLE_BG_TEXT
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 dec b
 jr nz,.clear
 hlcoord 14,11
 ld a,[wMenuCursorY]
 dec a
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 jp ZhDrawTallBattleCursor
