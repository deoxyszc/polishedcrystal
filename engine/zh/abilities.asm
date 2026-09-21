; Original ability ID selects a compiled text surface. Cache owns VRAM.
ZhSummaryAbility::
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhEnterFontText
 farcall ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 ld hl,ZhAbilityNameTable
 call .lookup
 jr c,.description
 push de
 hlcoord 1,13
 lb bc,2,16
 call ClearBox
 pop de
 hlcoord 1,13
 ld a,BANK(ZhAbilityTable)
 call FarString
.description
 ld hl,ZhAbilityDescriptionTable
 call .lookup
 ret c
 push de
 hlcoord 1,14
 lb bc,4,18
 call ClearBox
 pop de
 hlcoord 1,14
 ld a,BANK(ZhAbilityTable)
 jp FarString
.lookup
 ld a,[wZhSummaryAbility]
 ld e,a
 ld d,0
 add hl,de
 add hl,de
 ld a,BANK(ZhAbilityTable)
 call GetFarByte
 ld e,a
 inc hl
 ld a,BANK(ZhAbilityTable)
 call GetFarByte
 ld d,a
 or e
 ret nz
 scf
 ret
