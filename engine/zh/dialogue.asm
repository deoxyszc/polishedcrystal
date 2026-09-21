; Dialogue uses bank0 font area; numbers, <LV>, symbols and borders stay static.
; Caller opens textbox and loads its font before this entry.
ZhShowDialogue::
 push hl
 push de
 call ZhHidePage
 call ApplyAttrAndTilemapInVBlank
 ldh a, [rWBK]
 push af
 ld a, BANK(wZhCacheKeys)
 ldh [rWBK], a
 call ZhEnterFontText
 ; Preserve other visible font cells until their owners remove them.
 call ZhGlyphCacheRecover
 pop af
 ldh [rWBK], a
 pop de
 pop hl
 call ZhRunText
 push af
 call ApplyAttrAndTilemapInVBlank
 ldh a, [rWBK]
 push af
 ld a, BANK(wBattleMode)
 ldh [rWBK], a
 ld a, [wBattleMode]
 ld b, a
 pop af
 ldh [rWBK], a
 ld a, b
 and a
 jr z, .done
 ld a, [wZhTextControl]
 cp ZH_CTRL_PROMPT
 call nz, WaitButton
 call ZhHidePage
 call ApplyAttrAndTilemapInVBlank
.done
 pop af
 ret

; Keep keys for surviving parent windows. Only a font reload starts a new
; epoch; another dialogue/menu must not erase metadata for visible glyphs.
ZhEnterFontText::
 ld a, [wZhPolicy]
 and a
 ld a, ZH_VRAM_BANK0_ONLY
 jp z, ZhGlyphCacheInit
 ld [wZhPolicy], a
 and a
 ret
