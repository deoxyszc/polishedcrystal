; Window-stack adapters. Original stack stays in bank 7; six-byte records
; preserve dynamic strip IDs instead of pinning old VRAM slots.
; HL=map cell, DE=descending stack. Preserve BC/HL, advance DE by six.
ZhWindowBackupCell::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 push bc
 push de
 ld de, wZhBackupCell
 call ZhCacheBackupCell
 pop de
 push hl
 ld hl, wZhBackupCell
 ld c, 6
.copy
 ld b, [hl]
 ld a, BANK(wWindowStack)
 ldh [rWBK], a
 ld a, b
 ld [de], a
 dec de
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 inc hl
 dec c
 jr nz, .copy
 pop hl
 pop bc
 ret

ZhWindowRestoreCell::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 push bc
 push hl
 ld hl, wZhBackupCell
 ld c, 6
.copy
 ld a, BANK(wWindowStack)
 ldh [rWBK], a
 ld a, [de]
 ld b, a
 dec de
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
 ret

; B/C=runtime menu rectangle, DE=descending stack pointer. Preserve registers.
; Check before copying cells; include trailing saved pointer.
ZhWindowCheckSpace::
 push hl
 push bc
 push de
 ld hl, 0
 ld d, 0
 ld e, c
.size
 add hl, de
 dec b
 jr nz, .size
 ld d, h
 ld e, l
 add hl, hl
 add hl, de
 add hl, hl
 inc hl
 inc hl
 ld b, h
 ld c, l
 pop de
 ld a, e
 sub c
 ld a, d
 sbc b
 cp HIGH(wWindowStack)
 pop bc
 pop hl
 ret

ZhGetMenuBoxDims::
	ld a, [wMenuBorderTopCoord]
	ld b, a
	ld a, [wMenuBorderBottomCoord]
	sub b
	jr nc, .positive
	cpl
.positive
	ld b, a
	ld a, [wMenuBorderLeftCoord]
	ld c, a
	ld a, [wMenuBorderRightCoord]
	sub c
	ld c, a
	ret nc
	cpl
	ld c, a
	ret


; Standard font reload overwrites the font/cache area. Invalidate at that
; shared resource boundary rather than adding page-specific reset hooks.
ZhFontCacheInvalidate::
 ld a, BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 ; Resource reload invalidates content, not the enclosing policy scope.
 ; Saved encoded windows may need to regenerate after this call.
 jp ZhGlyphCacheClear
