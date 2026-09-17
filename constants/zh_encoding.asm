; E1 prototype: uncompressed, bounded ROM dialogue only.
DEF ZH_ESCAPE EQU $0a
if !DEF(ZH_GLYPH_COUNT)
INCLUDE "data/zh/font/count.asm"
endc
ASSERT ZH_GLYPH_COUNT > 0 && ZH_GLYPH_COUNT <= $4000

; T1 token ABI; BC retains the original control byte or glyph ID.
DEF ZH_TOKEN_END EQU 0
DEF ZH_TOKEN_LITERAL EQU 1
DEF ZH_TOKEN_GLYPH EQU 2
DEF ZH_TOKEN_CONTROL EQU 3
DEF ZH_CTRL_WAIT EQU $02
DEF ZH_CTRL_DONE EQU $52
DEF ZH_CTRL_AT EQU $53
DEF ZH_CTRL_PROMPT EQU $54
DEF ZH_CTRL_NEXT EQU $56
DEF ZH_CTRL_LINE EQU $57
DEF ZH_CTRL_PARA EQU $59
; Private uncompressed stream enums, not existing charmap/RAM commands.
; charmap reserves $0a..$4c; $0a is E1, $0b/$0c select fixed D1 sources.
DEF ZH_CTRL_PLAYER EQU $0b
DEF ZH_CTRL_RIVAL EQU $0c
