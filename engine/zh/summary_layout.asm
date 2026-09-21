; Labels use common cached text. Values and Hyper Training remain original.
ZhSummaryLabels::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhEnterFontText
 farcall ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld de,ZhStatLabel1
 ld a,BANK(ZhStatLabel1)
 call FarString
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld de,ZhStatLabel2
 ld a,BANK(ZhStatLabel2)
 call FarString
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld de,ZhStatLabel3
 ld a,BANK(ZhStatLabel3)
 call FarString
 hlbgcoord 0,5,wSummaryScreenWindowBuffer
 ld de,ZhStatLabel4
 ld a,BANK(ZhStatLabel4)
 call FarString
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld de,ZhStatLabel5
 ld a,BANK(ZhStatLabel5)
 call FarString
 jp ZhAbilityTitle
ZhAbilityTitle::
 hlcoord 1,10
 ld de,ZhAbilityTabText
 ld a,BANK(ZhAbilityTabText)
 call FarString
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 ret
