; Static labels share the suite cache; native PrintNum output is retained.
ZhLevelLabels::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhEnterFontText
 farcall ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 hlcoord 5,1
 ld de,ZhStatLabel0
 ld a,BANK(ZhStatLabel0)
 call FarString
 hlcoord 5,3
 ld de,ZhStatLabel1
 ld a,BANK(ZhStatLabel1)
 call FarString
 hlcoord 5,5
 ld de,ZhStatLabel2
 ld a,BANK(ZhStatLabel2)
 call FarString
 hlcoord 5,7
 ld de,ZhStatLabel3
 ld a,BANK(ZhStatLabel3)
 call FarString
 hlcoord 5,9
 ld de,ZhStatLabel4
 ld a,BANK(ZhStatLabel4)
 call FarString
 hlcoord 5,11
 ld de,ZhStatLabel5
 ld a,BANK(ZhStatLabel5)
 call FarString
 jp ApplyAttrAndTilemapInVBlank

ZhAlignLevelNumbers::
 ret ; original PrintNum/PrintLevel own their static numeric tiles
