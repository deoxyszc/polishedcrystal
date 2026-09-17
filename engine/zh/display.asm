assert ZH_LAYOUT_LEFT_TILES >= 1
assert ZH_LAYOUT_LEFT_TILES + ZH_LAYOUT_WIDTH_TILES <= 19
assert ZH_LAYOUT_TOP_TILE == 13 && ZH_LAYOUT_LINE_STEP_TILES == 2
; Upload previously composed wZhLineBuffer to leased line slot A=0 or1.
; Caller has selected state/buffer WRAM bank. Preserves VBK/SVBK and BC/DE/HL.
; Existing Get2bpp owns VRAM timing; tilemap/attr publish follows transfer.
; Caller applies the visible map after this function returns successfully.
ZhUploadLine::
 cp 2
 jr nc, .error
 push af
 ld a, [wZhDisplayMode]
 cp 2
 jr nc, .modeError
 pop af
 push bc
 push de
 push hl
 push af
 call ZhLeaseWritable
 jr c, .refused
 ld a, [wZhSuspended]
 and a
 jr nz, .refused
 pop af
 push af
 call ZhStorePageLine
 pop af
 push af
 and a
 ld hl, vTiles5 tile $30
 jr z, .address
 ld hl, vTiles5 tile $54
.address
 ld a, [wZhDisplayMode]
 and a
 jr z, .bankReady
 ; Same slot offset, but font bank0 $8800 instead of bank1 $9300.
 ld de, -$b00
 add hl, de
.bankReady
 ldh a, [rVBK]
 push af
 ld a, [wZhDisplayMode]
 xor 1
 ldh [rVBK], a
 ld de, wZhLineBuffer
 ld c, 36
 ldh a, [hROMBank]
 ld b, a
 call Get2bpp
 pop af
 ldh [rVBK], a
 pop af
 and a
 ld a, 1
 jr z, .mask
 add a
.mask
 push af
 call ZhPublishLine
 pop af
 ld hl, wZhLeaseValidMask
 or [hl]
 ld [hl], a
 pop hl
 pop de
 pop bc
 and a
 ret
.modeError
 pop af
 jr .error
.refused
 pop af
 pop hl
 pop de
 pop bc
.error
 scf
 ret

; A=slot bitmask1/2. Publish only after transfer is complete.
ZhPublishLine:
 cp 1
 hlcoord ZH_LAYOUT_LEFT_TILES, ZH_LAYOUT_TOP_TILE
 ld a, $30
 jr z, .coords
 hlcoord ZH_LAYOUT_LEFT_TILES, ZH_LAYOUT_TOP_TILE + ZH_LAYOUT_LINE_STEP_TILES
 ld a, $54
.coords
 ld c, a
 ld a, [wZhDisplayMode]
 and a
 ld a, c
 jr z, .tilebase
 add $50
.tilebase
 push hl
 ld b, 2
.row
 ld c, ZH_LAYOUT_WIDTH_TILES
.tile
 ld [hli], a
 inc a
 dec c
 jr nz, .tile
 rept SCREEN_WIDTH - ZH_LAYOUT_WIDTH_TILES
 inc hl
 endr
 dec b
 jr z, .tilesDone
 add 18 - ZH_LAYOUT_WIDTH_TILES
 jr .row
.tilesDone
 pop hl
 ld de, wAttrmap - wTilemap
 add hl, de
 ld b, 2
.attrrow
 ld c, ZH_LAYOUT_WIDTH_TILES
 ld a, [wZhDisplayMode]
 and a
 ld a, $0f
 jr z, .attr
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 rept SCREEN_WIDTH - ZH_LAYOUT_WIDTH_TILES
 inc hl
 endr
 dec b
 jr nz, .attrrow
 ret

; Keep both lines for font restoration across menus. A=slot; clobbers all.
ZhStorePageLine:
 and a
 ld de, wZhPageBuffer
 jr z, .dest
 ld de, wZhPageBuffer + 576
.dest
 ld hl, wZhLineBuffer
 ld bc, 576
 rst CopyBytes
 ret
