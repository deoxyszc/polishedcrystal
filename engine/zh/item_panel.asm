; Independent name/description fallbacks, indexed by the original held-item ID.
ZhSummaryItem::
 xor a
 ld [wZhItemDescriptionActive],a
if ZH_ITEM_TITLE
 call ZhItemTitle
endc
 ld a,[wTempMonItem]
 cp ZH_ITEM_COUNT
 ret nc
 ld hl,ZhItemNameTable
 call .lookup
 jr c,.description
 ld hl,$8800
 ld c,36
 call .upload
 hlcoord 1,13
 ld a,$80
 ld b,2
 call .place
.description
 ld hl,ZhItemDescriptionTable
 call .lookup
 ret c
 ld a,1
 ld [wZhItemDescriptionActive],a
 ld hl,$8a40
 ld c,72
 call .upload
 hlcoord 1,14
 ld a,$a4
 ld b,4
 jp .place
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
.upload
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 call Get2bpp
 pop af
 ldh [rVBK],a
 ret
.place
 push hl
 push bc
.row
 ld c,18
.tile
 ld [hli],a
 inc a
 dec c
 jr nz,.tile
 inc hl
 inc hl
 dec b
 jr nz,.row
 pop bc
 pop hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld c,18
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
 jp FillBoxWithByte

if ZH_ITEM_TITLE
ZhItemTitle::
 ld a,1
 ldh [rVBK],a
 ld hl,$8f00
 ld de,.Tiles
 ld b,BANK(.Tiles)
 ld c,15
 call Get2bpp
 xor a
 ldh [rVBK],a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 ; Top tile row is blank: leave the held-item pixels below intact.
 hlcoord 1,11
 ld [hl],245
 hlcoord 1,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 2,11
 ld [hl],246
 hlcoord 2,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 3,11
 ld [hl],247
 hlcoord 3,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 4,11
 ld [hl],248
 hlcoord 4,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 5,11
 ld [hl],249
 hlcoord 5,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 1,12
 ld [hl],250
 hlcoord 1,12,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 2,12
 ld [hl],251
 hlcoord 2,12,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 3,12
 ld [hl],252
 hlcoord 3,12,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 4,12
 ld [hl],253
 hlcoord 4,12,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 hlcoord 5,12
 ld [hl],254
 hlcoord 5,12,wAttrmap
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 ld a,[wTempMonItem]
 and a
 jr z,.noItemPalette
 hlcoord 2,10,wAttrmap
 ld [hl],SUMMARY_PAL_ITEM
 hlcoord 3,10,wAttrmap
 ld [hl],SUMMARY_PAL_ITEM
 hlcoord 4,10,wAttrmap
 ld [hl],SUMMARY_PAL_ITEM
.noItemPalette
 ret
.Tiles:
 INCBIN "gfx/zh/item_tab.2bpp"

endc
