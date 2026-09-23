; Descending window stack: tile, attribute, optional four-byte key.
; Bit4 is a storage tag only, never copied to the live attribute map.
; Static records use 2 bytes; dynamic records retain the 6-byte payload.
ZhWindowPrepareRecord::
 push de
 ld de,wZhBackupCell
 call ZhCacheBackupCell
 pop de
 ld hl,wZhBackupCell + 1
 res 4,[hl]
 ld hl,wZhBackupCell + 2
 ld a,[hli]
 and [hl]
 inc hl
 and [hl]
 inc hl
 and [hl]
 inc a
 ld c,2
 ret z
 ld hl,wZhBackupCell + 1
 set 4,[hl]
 ld c,6
 ret

; HL=map cell, DE=stack pointer; BC/HL preserved, DE decremented by size.
ZhWindowBackupCell::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 push bc
 push hl
 call ZhWindowPrepareRecord
 ld hl,wZhBackupCell
.copy
 ld b,[hl]
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld a,b
 ld [de],a
 dec de
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 inc hl
 dec c
 jr nz,.copy
 pop hl
 pop bc
 ret

ZhWindowRestoreCell::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 push bc
 push hl
 ld hl,wZhBackupCell
 ; Read the fixed header before deciding whether a key follows.
 call .read
 call .read
 ld a,[wZhBackupCell + 1]
 bit 4,a
 jr z,.static
 and $ef
 ld [wZhBackupCell + 1],a
 ld c,4
.dynamic
 call .read
 dec c
 jr nz,.dynamic
 jr .restore
.static
 ld a,$ff
 rept 4
 ld [hli],a
 endr
.restore
 pop hl
 push de
 ld de,wZhBackupCell
 call ZhCacheRestoreCell
 pop de
 pop bc
 ret
.read
 ld a,BANK(wWindowStack)
 ldh [rWBK],a
 ld a,[de]
 ld b,a
 dec de
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 ld [hl],b
 inc hl
 ret

; Exact preflight: inspect precisely the same cells/keys as the encoder.
; HL=top-left cell, BC=rectangle, DE=stack after menu header.
; No stack writes, cache mutation or allocation. Preserve BC/DE/HL.
ZhWindowCheckSpace::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 push hl
 push bc
 push de
 ; Reserve two bytes for the trailing window link first.
 dec de
 dec de
.row
 push bc
 push hl
.col
 push bc
 push hl
 call ZhWindowPrepareRecord
 ld a,e
 sub c
 ld e,a
 ld a,d
 sbc 0
 ld d,a
 cp HIGH(wWindowStack)
 pop hl
 pop bc
 jr c,.overflow
 inc hl
 dec c
 jr nz,.col
 pop hl
 push bc
 ld bc,SCREEN_WIDTH
 add hl,bc
 pop bc
 pop bc
 dec b
 jr nz,.row
 and a
 jr .done
.overflow
 pop hl
 pop bc
 scf
.done
 pop de
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
