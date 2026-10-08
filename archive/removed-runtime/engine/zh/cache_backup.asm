; One tile backup record: tile-half/static ID, attr, four-byte strip key.
; Static records use an invalid key ($ffffffff). HL=map cell, DE=record.
; Caller selects cache WRAM. Preserve HL, advance DE by six.
ZhCacheBackupCell::
 push bc
 push hl
 ld a, [hl]
 ld [de], a
 inc de
 ld c, a
 push de
 ld de, wAttrmap - wTilemap
 add hl, de
 ld a, [hl]
 pop de
 ld [de], a
 inc de
 push af
 ld a, [wZhPolicy]
 and a
 jr z, .inactive
 pop af
 and BG_BANK1
 rrca
 rrca
 rrca
 call ZhCacheTileSlot
 jr c, .static
 push de
 call ZhGlyphCacheReadKey
 ld a, b
 and c
 and d
 and e
 inc a
 jr z, .invalid
 ; Copy key via stack while retrieving the destination pointer.
 push de
 push bc
 ld hl, sp + 4
 ld a, [hli]
 ld h, [hl]
 ld l, a
 pop bc
 pop de
 ld [hl], b
 inc hl
 ld [hl], c
 inc hl
 ld [hl], d
 inc hl
 ld [hl], e
 inc hl
 pop de
 ld d, h
 ld e, l
 jr .done
.invalid
 pop de
 jr .static
.inactive
 pop af
.static
 ld a, $ff
 rept 4
 ld [de], a
 inc de
 endr
.done
 pop hl
 pop bc
 ret

; HL=map cell, DE=backup record. Preserve HL; DE advances six on success.
; Dynamic records regenerate by key, even if their former slot was reused.
; Original palette/flip/priority survive; bank and tile ID follow new slot.
ZhCacheRestoreCell::
 push bc
 push hl
 push de
 ld a, [de]
 push af
 inc de
 ld a, [de]
 push af
 inc de
 ld a, [de]
 ld b, a
 inc de
 ld a, [de]
 ld c, a
 inc de
 ld a, [de]
 push af
 inc de
 ld a, [de]
 ld e, a
 pop af
 ld d, a
 ld a, b
 and c
 and d
 and e
 inc a
 jr z, .static
 call ZhEnsureCacheBlock
 jr c, .failed
 call ZhGlyphCacheLocation
 ld c, a
 pop af
 and $ff ^ BG_BANK1
 bit 0, b
 jr z, .attr
 or BG_BANK1
.attr
 ld b, a
 pop af
 and 1
 add c
 ld c, a
 jr .publish
.static
 pop af
 ld b, a
 pop af
 ld c, a
.publish
 pop de
 pop hl
 push hl
 ld [hl], c
 push de
 ld de, wAttrmap - wTilemap
 add hl, de
 ld [hl], b
 pop de
 rept 6
 inc de
 endr
 pop hl
 pop bc
 and a
 ret
.failed
 pop af
 pop af
 pop de
 pop hl
 pop bc
 scf
 ret
