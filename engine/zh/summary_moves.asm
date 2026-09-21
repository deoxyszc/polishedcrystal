; Names use shared cached text. Original move IDs, PP and type sprites remain.
ZhSummaryMoves::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhEnterFontText
 farcall ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 ld a,[wTempMonMoves+0]
 and a
 ret z
 call .lookup
 jr c,.next0
 hlbgcoord 0,0,wSummaryScreenWindowBuffer
 ld a,b
 call FarString
.next0
 ld a,[wTempMonMoves+1]
 and a
 ret z
 call .lookup
 jr c,.next1
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld a,b
 call FarString
.next1
 ld a,[wTempMonMoves+2]
 and a
 ret z
 call .lookup
 jr c,.next2
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld a,b
 call FarString
.next2
 ld a,[wTempMonMoves+3]
 and a
 ret z
 call .lookup
 jr c,.next3
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld a,b
 call FarString
.next3
 ret
.lookup
 ld e,a
 ld d,0
 ld hl,ZhSummaryMoveNames
 add hl,de
 add hl,de
 add hl,de
 ld b,[hl]
 inc hl
 ld a,[hli]
 ld e,a
 ld d,[hl]
 or d
 ret nz
 scf
 ret
