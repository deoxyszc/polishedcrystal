; Display-only translated ability assets. Missing entries retain native text.
ZhSummaryAbility::
 ld hl,ZhAbilityNameTable
 call .lookup
 jr c,.description
 push de
 hlcoord 1,13
 lb bc,2,16
 call ClearBox
 pop de
 ld hl,$8f10
 ld c,14
 call .upload
 hlcoord 1,13
 ld a,$f1
 ld b,2
 ld c,7
 call .place
.description
 ld hl,ZhAbilityDescriptionTable
 call .lookup
 ret c
 push de
 hlcoord 1,14
 lb bc,4,18
 call ClearBox
 pop de
 ld hl,$9400
 ld c,56
 call .upload
 hlcoord 1,14
 ld a,$40
 ld b,4
 ld c,14
 jp .place
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
.upload
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld b,BANK(ZhAbilityTable)
 call Get2bpp
 pop af
 ldh [rVBK],a
 ret
.place
 push bc
 push hl
.row
 push bc
 push hl
.tile
 ld [hli],a
 inc a
 dec c
 jr nz,.tile
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 pop bc
 dec b
 jr nz,.row
 pop hl
 pop bc
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
 jp FillBoxWithByte
