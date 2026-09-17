; Bounded E1 script executor. Only admitted ROM spans and enum names.
ZhRunText::
 ld a,l
 ld [wZhTextCursor],a
 ld [wZhTextSpan],a
 ld a,h
 ld [wZhTextCursor+1],a
 ld [wZhTextSpan+1],a
 ld a,e
 ld [wZhTextEnd],a
 ld a,d
 ld [wZhTextEnd+1],a
 xor a
 ld [wZhTextSlot],a
 ld [wZhTextAfterWait],a
 call ZhComposeBegin
.next
 call .load
 push hl
 call ZhReadToken
 jp c,.badToken
 ld [wZhTextType],a
 ld a,c
 ld [wZhTextControl],a
 ld a,l
 ld [wZhTextCursor],a
 ld a,h
 ld [wZhTextCursor+1],a
 pop de
 ld a,[wZhTextType]
 cp 1
 jr z,.printable
 cp 2
 jr nz,.boundary
.printable
 ld a,[wZhTextAfterWait]
 and a
 jp z,.next
 jp .error
.boundary
 ld a,[wZhTextSpan]
 ld l,a
 ld a,[wZhTextSpan+1]
 ld h,a
 ld a,h
 cp d
 jr nz,.append
 ld a,l
 cp e
 jr z,.control
.append
 call ZhComposeAppend
 ret c
.control
 call .advanceSpan
 ld a,[wZhTextType]
 and a
 jr z,.publish
 ld a,[wZhTextControl]
 cp ZH_CTRL_PLAYER
 jr z,.name
 cp ZH_CTRL_RIVAL
 jr z,.name
.publish
 ld a,[wZhTextSlot]
 call ZhUploadLine
 ret c
 call ApplyAttrAndTilemapInVBlank
 ld a,[wZhTextType]
 and a
 jp z,.end
 ld a,[wZhTextControl]
 cp $56
 jp z,.nextLine
 cp $57
 jp z,.bottom
 cp $59
 jp z,.page
 cp $02
 jp nz,.error
 call WaitButton
 ld a,1
 ld [wZhTextAfterWait],a
 jp .next
.name
 ld a,[wZhTextAfterWait]
 and a
 jp nz,.error
 ld a,[wZhTextControl]
 sub ZH_CTRL_PLAYER
 call ZhStageEnglishName
 ret c
 ; HL=WRAM0 name, BC=length, convert to bounded [HL,DE).
 ld d,h
 ld e,l
 add hl,bc
 ld b,h
 ld c,l
 ld h,d
 ld l,e
 ld d,b
 ld e,c
 call ZhComposeAppend
 ret c
 jp .next
.nextLine
 ld a,[wZhTextSlot]
 and a
 jr nz,.error
.bottom
 xor a
 ld [wZhTextAfterWait],a
 ld a,1
 ld [wZhTextSlot],a
 call ZhComposeBegin
 jp .next
.page
 call WaitButton
 call ZhLeaseClearPage
 ret c
 xor a
 ld [wZhTextSlot],a
 ld [wZhTextAfterWait],a
 call ZhComposeBegin
 jp .next
.end
 ld a,[wZhTextControl]
 cp $54
 call z,WaitButton
 and a
 ret
.badToken
 pop hl
.error
 scf
 ret
.advanceSpan
 ld a,[wZhTextCursor]
 ld [wZhTextSpan],a
 ld a,[wZhTextCursor+1]
 ld [wZhTextSpan+1],a
 ret
.load
 ld a,[wZhTextCursor]
 ld l,a
 ld a,[wZhTextCursor+1]
 ld h,a
 ld a,[wZhTextEnd]
 ld e,a
 ld a,[wZhTextEnd+1]
 ld d,a
 ret
