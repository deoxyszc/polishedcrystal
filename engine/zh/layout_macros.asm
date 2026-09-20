; Compile-time adapters for existing tilemaps. No WRAM or runtime dispatch cost.
; Tile rectangle: x, y, width, height, first tile, palette attributes.
MACRO zh_screen_tiles
 for y, 0, \4
  for x, 0, \3
   hlcoord \1 + x, \2 + y
   ld [hl], \5 + y * \3 + x
   hlcoord \1 + x, \2 + y, wAttrmap
   ld [hl], \6
  endr
 endr
ENDM

; Explicit source bank is required: shared assets can live outside the caller.
; source, VRAM destination, tile count. Preserve the caller's VRAM bank.
MACRO zh_upload_tiles
 ldh a, [rVBK]
 push af
 ld a, 1
 ldh [rVBK], a
 ld de, \1
 ld hl, \2
 ld b, BANK(\1)
 ld c, \3
 call Get2bpp
 pop af
 ldh [rVBK], a
ENDM
