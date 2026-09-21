; Item text surfaces use the shared cache, selected by the real item ID.
ZhSummaryItem::
 xor a
 ld [wZhItemDescriptionActive],a
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 farcall ZhEnterFontText
 farcall ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
if ZH_ITEM_TITLE
 call ZhItemTitle
endc
 ld a,[wTempMonItem]
 cp ZH_ITEM_COUNT
 ret nc
 ld hl,ZhItemNameTable
 call .lookup
 jr c,.description
 hlcoord 1,13
 ld a,b
 call FarString
.description
 ld hl,ZhItemDescriptionTable
 call .lookup
 ret c
 ld a,1
 ld [wZhItemDescriptionActive],a
 hlcoord 1,14
 ld a,b
 jp FarString
.lookup
 ld a,[wTempMonItem]
 ld e,a
 ld d,0
 add hl,de
 add hl,de
 add hl,de
 ld a,[hli]
 ld b,a
 ld a,[hli]
 ld e,a
 ld d,[hl]
 or d
 ret nz
 scf
 ret

if ZH_ITEM_TITLE
ZhItemTitle::
 hlcoord 1,11
 ld de,ZhItemTabText
 ld a,BANK(ZhItemTabText)
 call FarString
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 ret
endc
