; All state/backing store in currently selected WRAM bank. Caller restores WBK.
; Suspend before menu PushWindow; resume AFTER complete menu ExitMenu.
; The two text lines are temporarily blank while original font serves menu.
; General registers clobbered. Carry failure; calls may wait frames.
ZhSuspendPage::
 call ZhLeaseWritable
 ret c
 ld a, [wZhSuspended]
 and a
 jr nz, .error
 call ZhHidePage
 call ApplyAttrAndTilemapInVBlank
 ldh a, [rVBK]
 push af
 xor a
 ldh [rVBK], a
 call LoadStandardFont
 pop af
 ldh [rVBK], a
 ld a, 1
 ld [wZhSuspended], a
 call ZhLeasePin
 ret
.error
 scf
 ret

ZhResumePage::
 ld a, [wZhSuspended]
 and a
 jr z, .error
 ; Exactly our one pin, never steal another menu's reference.
 ld a, [wZhLeasePins]
 cp 1
 jr nz, .error
 call ZhLeaseUnpin
 xor a
 ld [wZhSuspended], a
 ld a, [wZhLeaseValidMask]
 push af
 bit 0, a
 jr z, .second
 ld hl, wZhPageBuffer
 call .copy
 xor a
 call ZhUploadLine
.second
 pop af
 bit 1, a
 jr z, .done
 ld hl, wZhPageBuffer + 576
 call .copy
 ld a, 1
 call ZhUploadLine
.done
 call ApplyAttrAndTilemapInVBlank
 and a
 ret
.error
 scf
 ret
.copy
 ld de, wZhLineBuffer
 ld bc, 576
 rst CopyBytes
 ret
