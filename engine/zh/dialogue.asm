; Public bounded dialogue entry. Caller must open the standard textbox first.
; HL=start, DE=exclusive end, both mapped in this bank; carry reports failure.
; Restores WRAM bank. Overworld final text remains until its owner closes it.
ZhShowDialogue::
 ld a,l
 ld [wZhEntryStart],a
 ld a,h
 ld [wZhEntryStart+1],a
 ld a,e
 ld [wZhEntryEnd],a
 ld a,d
 ld [wZhEntryEnd+1],a
 ldh a,[rWBK]
 push af
 ld a,BANK(wBattleMode)
 ldh [rWBK],a
 ld a,[wBattleMode]
 and a
 ld a,1
 jr z,.modeReady
 xor a
.modeReady
 ld b,a
 ld a,BANK(wZhLineBuffer)
 ldh [rWBK],a
 ld a,b
 ld [wZhDisplayMode],a
 call ZhLeaseAcquire
 jr c,.restore
 ld a,[wZhEntryStart]
 ld l,a
 ld a,[wZhEntryStart+1]
 ld h,a
 ld a,[wZhEntryEnd]
 ld e,a
 ld a,[wZhEntryEnd+1]
 ld d,a
 call ZhRunText
 push af
 jr c,.abort
 ld a,[wZhDisplayMode]
 and a
 jr nz,.release
 ; PROMPT already waited inside ZhRunText; DONE waits here in battle.
 ld a,[wZhTextControl]
 cp ZH_CTRL_PROMPT
 call nz,WaitButton
 call ZhLeaseClearPage
 call ApplyAttrAndTilemapInVBlank
 jr .release
.abort
 call ZhLeaseAbort
.release
 call ZhLeaseRelease
 pop af
.restore
 ld b,a
 ld c,0
 jr nc,.noError
 inc c
.noError
 pop af
 ldh [rWBK],a
 ld a,c
 and a
 ret z
 scf
 ret
