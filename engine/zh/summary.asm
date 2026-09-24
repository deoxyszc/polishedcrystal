ZhSummaryNames::
 ld de,wTempMonNickname
 hlbgcoord ZH_PINK_NICKNAME_WX,ZH_PINK_NICKNAME_WY,wSummaryScreenWindowBuffer
 call .name
 call GetPartyPokemonName
 ld de,wStringBuffer1
 hlbgcoord ZH_PINK_SPECIES_WX+1,ZH_PINK_SPECIES_WY,wSummaryScreenWindowBuffer
.name
 push hl
 ld hl,ZhPartyNames
.next
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 or c
 jr z,.missing
 push hl
 push de
 ld h,b
 ld l,c
 call ZhMatchDefaultName
 jr c,.mismatch
 pop de
 pop bc
 inc hl
 inc hl
 inc hl
 inc hl
 ld d,h
 ld e,l
 pop hl
 push hl
 push de
 ld a,l
 cp LOW(wSummaryScreenWindowBuffer+ZH_PINK_SPECIES_WY*32+ZH_PINK_SPECIES_WX+1)
 ld bc,8
 jr nz,.clearName
 ld bc,11
.clearName
 ld a,$7f
 rst ByteFill
 pop de
 pop hl
 ld a,2
 call ZhPlaceStableName
 ret
.mismatch
 pop de
 pop hl
 jr .next
.missing
 pop hl
 ret

ZhSummaryCacheInit::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 ld a,ZH_VRAM_BANK1_ONLY
 call ZhGlyphCacheInit
 pop af
 ldh [rWBK],a
 ret

ZhSummaryCacheExit::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 ld a,ZH_VRAM_BOTH
 call ZhGlyphCacheInit
 pop af
 ldh [rWBK],a
 ret
