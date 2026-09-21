; Summary owns a second, staggered window map; keep its references live.
ZhSummaryCacheEnter::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 ld a,1
 ld [wZhSummaryCacheActive],a
 jp ZhEnterFontText
ZhSummaryCacheLeave::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 xor a
 ld [wZhSummaryCacheActive],a
 ret

; Caller selects cache WRAM; mark visible columns of all ten window rows.
ZhMarkSummaryCache::
 ld a,[wZhSummaryCacheActive]
 and a
 ret z
 push bc
 push de
 push hl
 ld hl,wSummaryScreenWindowBuffer
 ld d,10
.row
 ld e,12
.cell
 push de
 push hl
 ld c,[hl]
 ld de,16
 add hl,de
 ld a,[hl]
 and BG_BANK1
 rrca
 rrca
 rrca
 call ZhCacheTileSlot
 jr c,.next
 ld hl,wZhCacheUsed
 add l
 ld l,a
 jr nc,.mark
 inc h
.mark
 ld [hl],1
.next
 pop hl
 pop de
 inc hl
 dec e
 jr nz,.cell
 ld bc,20
 add hl,bc
 dec d
 jr nz,.row
 pop hl
 pop de
 pop bc
 ret

; C=top tile, B=bank bit, HL=window upper cell. Preserves registers.
ZhPublishSummaryBlock::
 push hl
 push de
 ld [hl],c
 ld de,32
 add hl,de
 ld a,c
 inc a
 ld [hl],a
 ld de,16
 add hl,de
 ld a,[hl]
 and $ff ^ BG_BANK1
 or b
 ld [hl],a
 ld de,-32
 add hl,de
 ld a,[hl]
 and $ff ^ BG_BANK1
 or b
 ld [hl],a
 pop de
 pop hl
 inc hl
 ret
