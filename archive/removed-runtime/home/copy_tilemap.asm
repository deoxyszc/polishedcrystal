LoadTileMapToTempTileMap::
if DEF(LOCALE_ZH)
	farjp ZhBackupTempMap
else
; Load wTilemap into wTempTileMap
	hlcoord 0, 0
	decoord 0, 0, wTempTileMap
	jr _ContinueLoadTileMap
endc

LoadTempTileMapToTileMap::
if DEF(LOCALE_ZH)
	farjp ZhRestoreTempMap
else
; Load wTempTileMap into wTilemap
	hlcoord 0, 0, wTempTileMap
	decoord 0, 0
_ContinueLoadTileMap::
	ldh a, [rWBK]
	push af
	ld a, BANK(wTempTileMap)
	ldh [rWBK], a
	ld bc, wTilemapEnd - wTilemap
	rst CopyBytes
	pop af
	ldh [rWBK], a
	ret
endc
