; Preserve legacy temp tilemap for engine readers; sidecar stores attr/key.
; Tile half comes from the original map, so each sidecar cell is five bytes.
ZhBackupTempMap::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 ld hl, wTilemap
 ld de, wZhTempKeys
 ld bc, SCREEN_AREA
.cell
 push bc
 push de
 ld de, wZhBackupCell
 call ZhCacheBackupCell
 pop de
 push hl
 ld bc, wTempTileMap - wTilemap
 add hl, bc
 ld a, [wZhBackupCell]
 ld b, a
 ld a, BANK(wTempTileMap)
 ldh [rWBK], a
 ld [hl], b
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 ld hl, wZhBackupCell + 1
 ld c, 5
.copy
 ld b, [hl]
 ld a, BANK(wZhTempKeys)
 ldh [rWBK], a
 ld a, b
 ld [de], a
 inc de
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 inc hl
 dec c
 jr nz, .copy
 pop hl
 inc hl
 pop bc
 dec bc
 ld a, b
 or c
 jr nz, .cell
 ret

ZhRestoreTempMap::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 ld hl, wTilemap
 ld de, wZhTempKeys
 ld bc, SCREEN_AREA
.cell
 push bc
 push hl
 ld bc, wTempTileMap - wTilemap
 add hl, bc
 ld a, BANK(wTempTileMap)
 ldh [rWBK], a
 ld b, [hl]
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 ld a, b
 ld [wZhBackupCell], a
 ld hl, wZhBackupCell + 1
 ld c, 5
.copy
 ld a, BANK(wZhTempKeys)
 ldh [rWBK], a
 ld a, [de]
 ld b, a
 inc de
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 ld [hl], b
 inc hl
 dec c
 jr nz, .copy
 pop hl
 push de
 ld de, wZhBackupCell
 call ZhCacheRestoreCell
 pop de
 pop bc
 ret c
 inc hl
 dec bc
 ld a, b
 or c
 jr nz, .cell
 ret
