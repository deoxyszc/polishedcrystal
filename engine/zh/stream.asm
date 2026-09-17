; T1 bounded uncompressed ROM tokenizer; never executes commands.
; HL=cursor, DE=exclusive end in same mapped bank.
; Success A=ZH_TOKEN_*, BC=payload, HL advanced, DE preserved, carry clear.
; At exclusive end: END/BC=0 without read or advance.
; Failure carry set, HL unchanged; AF/BC clobbered, DE preserved.
; RAM/FAR/ASM/Huffman/dynamic tokens deliberately unsupported.
ZhReadToken::
 ld a,h
 cp d
 jr c,.read
 jr nz,.error
 ld a,l
 cp e
 jr c,.read
 jr nz,.error
 ld bc,0
 xor a
 ret
.read
 ld a,[hl]
 cp ZH_ESCAPE
 jr z,.glyph
 ld b,0
 ld c,a
 cp ZH_CTRL_AT
 jr z,.end
 cp ZH_CTRL_DONE
 jr z,.end
 cp ZH_CTRL_PROMPT
 jr z,.end
 cp ZH_CTRL_CONT
 jr z,.control
 cp ZH_CTRL_NEXT
 jr z,.control
 cp ZH_CTRL_LINE
 jr z,.control
 cp ZH_CTRL_PARA
 jr z,.control
 cp ZH_CTRL_WAIT
 jr z,.control
 cp ZH_CTRL_RAM
 jr z,.ram
 cp ZH_CTRL_PLAYER
 jr z,.control
 cp ZH_CTRL_RIVAL
 jr z,.control
 cp $7f
 jr c,.error
 cp $f2
 jr nc,.error
 inc hl
 ld a,ZH_TOKEN_LITERAL
 and a
 ret
.ram
 push hl
 ld bc,4
 add hl,bc
 jr c,.ramError
 ld a,h
 cp d
 jr c,.ramValid
 jr nz,.ramError
 ld a,l
 cp e
 jr c,.ramValid
 jr z,.ramValid
.ramError
 pop hl
 scf
 ret
.ramValid
 pop hl
 inc hl
 ld bc,ZH_CTRL_RAM
 ld a,ZH_TOKEN_CONTROL
 and a
 ret

.end
 inc hl
 xor a
 ret
.control
 inc hl
 ld a,ZH_TOKEN_CONTROL
 and a
 ret
.glyph
 call ZhDecodeGlyph
 ret c
 ld a,ZH_TOKEN_GLYPH
 and a
 ret
.error
 scf
 ret
