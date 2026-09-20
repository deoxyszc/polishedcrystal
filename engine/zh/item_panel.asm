; Independent name/description fallbacks, indexed by the original held-item ID.
ZhSummaryItem::
 ; The move canvas occupies bank0's native font. Preserve fallback text in
 ; bank1 tiles $00..$71, separate from translated item tiles $80..$fe.
 ld a,[wZhSummaryMovesActive]
 and a
 call nz,ZhItemFallbackFont
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
 zh_screen_tiles 1, 11, 5, 2, 245, 8 | SUMMARY_PAL_LOWER_WINDOW
 ld a,[wTempMonItem]
 and a
 jr z,.noItemPalette
 hlcoord 2,8,wAttrmap
 lb bc,3,3
 ld a,SUMMARY_PAL_ITEM
 call FillBoxWithByte
.noItemPalette
 ret
.Tiles:
 INCBIN "gfx/zh/item_tab.2bpp"

endc

ZhItemFallbackFont:
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld de,FontNormal
 ld hl,$9000
 ld b,BANK(FontNormal)
 ld c,114
 call Get1bpp
 pop af
 ldh [rVBK],a
 hlcoord 0,13
 ld bc,5*SCREEN_WIDTH
.loop
 ld a,[hl]
 sub $80
 cp 114
 jr nc,.next
 ld [hl],a
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,[hl]
 or 8
 ld [hl],a
 pop hl
.next
 inc hl
 dec bc
 ld a,b
 or c
 jr nz,.loop
 ret
