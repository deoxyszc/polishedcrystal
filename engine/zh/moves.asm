; Carry set when any selected move cannot fit a 72px cell.
ZhCanDrawMoveGrid::
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
 ld a,[hl]
 cp 73
 pop bc
 pop hl
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
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhLineBuffer)
 ldh [rWBK],a
 xor a
 ld [wZhDisplayMode],a
 ld [wZhMoveIndex],a
 ld [wZhMoveRow],a
 call ZhLeaseAcquire
 jp c,.restore
.row
 call ZhComposeBegin
 call .name
 ld a,80
 ld [wZhPixelCursor],a
 call .name
 ld a,[wZhMoveRow]
 call ZhUploadMoveLine
 ld a,[wZhMoveRow]
 inc a
 ld [wZhMoveRow],a
 cp 2
 jr c,.row
 call ApplyAttrAndTilemapInVBlank
 call ZhLeaseRelease
.restore
 pop af
 ldh [rWBK],a
 ret
.name
 ; Reserve one tile at each cell's start for the navigation cursor.
 ld a,[wZhPixelCursor]
 add 8
 ld [wZhPixelCursor],a
 ld a,[wZhMoveIndex]
 ld e,a
 ld d,0
 ld hl,wListMoves_MoveIndicesBuffer
 add hl,de
 ; List index buffer is in the caller's normal WRAM bank.
 push hl
 ldh a,[rWBK]
 push af
 ld a,BANK(wListMoves_MoveIndicesBuffer)
 ldh [rWBK],a
 ld a,[hl]
 ld c,a
 pop af
 ldh [rWBK],a
 pop hl
 ld b,0
 ld hl,ZhMoveNames
 add hl,bc
 add hl,bc
 ld a,[hli]
 ld h,[hl]
 ld l,a
 push hl
 ; Find the exclusive end of generated uncompressed string.
.scan
 ld a,[hli]
 cp $53
 jr nz,.scan
 ld d,h
 ld e,l
 pop hl
 call ZhComposeAppend
 ld a,[wZhMoveIndex]
 inc a
 ld [wZhMoveIndex],a
 ret

; Return physical cursor location from original 1-based linear move selection.
ZhMoveCursorCoord::
 ; Restore all four cursor cells to their original blank composed tiles.
 hlcoord 1,13
 ld [hl],$80
 hlcoord 11,13
 ld [hl],$8a
 hlcoord 1,14
 ld [hl],$92
 hlcoord 11,14
 ld [hl],$9c
 hlcoord 1,15
 ld [hl],$a4
 hlcoord 11,15
 ld [hl],$ae
 hlcoord 1,16
 ld [hl],$b6
 hlcoord 11,16
 ld [hl],$c0
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

ZhUploadMoveLine:
 push af
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld hl,$8800
 ld a,[wZhMoveRow]
 and a
 jr z,.target
 ld hl,$8a40
.target
 ld de,wZhLineBuffer
 ld c,36
 ldh a,[hROMBank]
 ld b,a
 call Get2bpp
 pop af
 ldh [rVBK],a
 pop af
 and a
 hlcoord 1,13
 ld a,$80
 jr z,.tiles
 hlcoord 1,15
 ld a,$a4
.tiles
 ld b,2
.row
 ld c,18
.loop
 ld [hli],a
 inc a
 dec c
 jr nz,.loop
 inc hl
 inc hl
 dec b
 jr nz,.row
 ld a,[wZhMoveRow]
 and a
 hlcoord 1,13,wAttrmap
 jr z,.attrs
 hlcoord 1,15,wAttrmap
.attrs
 ld b,2
.arow
 ld c,18
 ld a,$0f
.aloop
 ld [hli],a
 dec c
 jr nz,.aloop
 inc hl
 inc hl
 dec b
 jr nz,.arow
 ret
