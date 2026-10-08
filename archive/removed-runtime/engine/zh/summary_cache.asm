; Detect the summary-owned LCD handler without allocating persistent state.
; Carry set while its display pipeline owns the screen; preserve registers.
ZhSummaryDisplayActive::
 push hl
 push de
 ld a,[hLCDInterruptFunctionTargetLo]
 ld l,a
 ld a,[hLCDInterruptFunctionTargetHi]
 ld h,a
 ld de,LCDSummaryScreenHideWindow
 call .equal
 jr z,.yes
 ld de,LCDSummaryScreenShowWindow
 call .equal
 jr z,.yes
 ld de,LCDSummaryScreenScrollBackground
 call .equal
 jr z,.yes
 pop de
 pop hl
 and a
 ret
.yes
 pop de
 pop hl
 scf
 ret
.equal
 ld a,h
 cp d
 ret nz
 ld a,l
 cp e
 ret

; Include the 12 visible cells in each interleaved window row.
; Cache WRAM bank is selected by the caller.
ZhSummaryMarkWindow::
 call ZhSummaryDisplayActive
 ret nc
 push bc
 push de
 push hl
 ld hl,wSummaryScreenWindowBuffer
 ld b,10
.row
 ld c,12
.cell
 push bc
 ld c,[hl]
 push hl
 ld de,16
 add hl,de
 ld a,[hl]
 and BG_BANK1
 rrca
 rrca
 rrca
 call ZhCacheTileSlot
 jr c,.skip
 ld hl,wZhCacheUsed
 add l
 ld l,a
 jr nc,.mark
 inc h
.mark
 ld [hl],1
.skip
 pop hl
 pop bc
 inc hl
 dec c
 jr nz,.cell
 ld de,20
 add hl,de
 dec b
 jr nz,.row
 pop hl
 pop de
 pop bc
 ret
