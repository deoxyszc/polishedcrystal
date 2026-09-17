; Include after macros/scripts/text.asm. Never send E1 through _dtxt/Huffman.
MACRO zh_glyph
	ASSERT _NARG == 1
	ASSERT (\1) >= 0 && (\1) < ZH_GLYPH_COUNT
	stop_compressing_text
	db ZH_ESCAPE, $80 | ((\1) >> 7), $80 | ((\1) & $7f)
ENDM

MACRO zh_raw
	; Existing charmap and controls, explicitly outside automatic compression.
	stop_compressing_text
	db \#
ENDM
