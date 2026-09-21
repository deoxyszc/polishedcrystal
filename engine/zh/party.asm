; Post-process only translated default names in the ordinary party menu.
; Original routines remain responsible for party data, eggs and menu actions.
ZhPartyLayout::
 ld hl,wZhPartyWidths
 ld bc,6
 xor a
 rst ByteFill
 ld hl,wZhPartyStatuses
 ld bc,6
 rst ByteFill
 ld a,[wPartyMenuActionText]
 and a
 ret nz
 xor a
 ld [wZhPartyIndex],a
.next
 ld a,[wPartyCount]
 ld b,a
 ld a,[wZhPartyIndex]
 cp b
 jp nc,.finish
 ld hl,wPartyMon1IsEgg
 call GetPartyLocation
 bit MON_IS_EGG_F,[hl]
 jp nz,.skip
 ld a,[wZhPartyIndex]
 ld hl,wPartyMonNicknames
 call GetNickname
 ld hl,ZhPartyNameTable
.search
 ld a,[hli]
 ld c,a
 ld a,[hli]
 ld b,a
 or c
 jp z,.skip
 push hl
 ld h,b
 ld l,c
 ld de,wStringBuffer1
 ld b,10
.compare
 ld a,[de]
 cp [hl]
 jp nz,.mismatch
 inc de
 inc hl
 dec b
 jr nz,.compare
 pop bc
 ld a,[hli]
 ld [wZhPartyWidth],a
 push hl
 push af
 ld a,[wZhPartyIndex]
 ld e,a
 ld d,0
 ld hl,wZhPartyWidths
 add hl,de
 pop af
 ld [hl],a
 pop hl
 push hl ; compiled name stream
 ; Keep original HP digits at x13. Move original gender and level before
 ; clearing the name band; no reconstructed or external metadata.
 call .coord
 ld bc,SCREEN_WIDTH + 7
 add hl,bc
 ld a,[hl]
 ld [wZhPartyGender],a
 call .coord
 ld bc,SCREEN_WIDTH + 4
 add hl,bc
 ld de,wZhPartyLevel
 ld bc,3
 rst CopyBytes
 call .coord
 push hl
 ld bc,10
 ld a,$7f
 rst ByteFill
 pop hl
 ld bc,SCREEN_WIDTH
 add hl,bc
 push hl
 ld bc,17
 ld a,$7f
 rst ByteFill
 pop hl
 ld bc,7
 add hl,bc
 ld de,wZhPartyLevel
 rept 3
 ld a,[de]
 ld [hli],a
 inc de
 endr
 ; Reuse the original HP calculation, rescale its 48 pixels to 32.
 push hl
 ld a,[wZhPartyIndex]
 ld b,a
 farcall PlacePartymonHPBar
 ld a,e
 add a
 ld b,0
.scale
 cp 3
 jr c,.scaled
 sub 3
 inc b
 jr .scale
.scaled
 ld e,b
 ld d,4
 pop hl
 call DrawBattleHPBar
 call .coord
 ld bc,7
 add hl,bc
 ld a,[wZhPartyGender]
 ld [hl],a
 call ZhPartyStatus
 call .coord
 pop de
 push hl
 push de
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 call ZhEnterFontText
 call ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 pop de
 pop hl
 ld a,BANK(ZhPartyNameTable)
 call FarString
 call .coord
 ld bc,wAttrmap-wTilemap + 7
 add hl,bc
 ld a,4
 ld [hli],a
 xor a
 ld [hli],a
 ld [hl],a
 call .coord
 ld bc,wAttrmap-wTilemap + SCREEN_WIDTH + 7
 add hl,bc
 xor a
 ld [hli],a
 ld [hli],a
 ld [hl],a
.skip
 ld hl,wZhPartyIndex
 inc [hl]
 jp .next
.mismatch
 pop hl
 jp .search
.finish
 call ZhPartyStatusAttrs
 jp ApplyAttrAndTilemapInVBlank
.coord
 hlcoord 3,1
 ld a,[wZhPartyIndex]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 ret

; Palette initialization can run again after the tilemap has been prepared.
ZhPartyAttributes::
 ld a,[wPartyMenuActionText]
 and a
 ret nz
 ld hl,wZhPartyWidths
 ld d,0
.next
 ld a,[hli]
 and a
 jr z,.skip
 push hl
 push de
 ld c,a
 ld b,ZH_REGION_PARTY_NAME_ROWS
 push bc
 hlcoord 3,1,wAttrmap
 ld a,d
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 pop bc
 push hl
 xor a
 call FillBoxWithByte
 pop hl
 ld bc,7
 add hl,bc
 ld a,4
 ld [hli],a
 xor a
 ld [hli],a
 ld [hl],a
 ld bc,SCREEN_WIDTH - 2
 add hl,bc
 ld [hli],a
 ld [hli],a
 ld [hl],a
 pop de
 pop hl
.skip
 inc d
 ld a,d
 cp 6
 jr c,.next
 jp ZhPartyStatusAttrs

ZhPartyFooter::
 ld a,[wPartyMenuActionText]
 and a
 ret nz
 hlcoord 1,15
 lb bc,2,18
 call ClearBox
 hlcoord 1,15,wAttrmap
 lb bc,2,18
 xor a
 call FillBoxWithByte
 call ApplyAttrAndTilemapInVBlank
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhCacheKeys)
 ldh [rWBK],a
 call ZhEnterFontText
 call ZhGlyphCacheRecover
 pop af
 ldh [rWBK],a
 hlcoord 1,15
 ld de,ZhPartyPromptText
 ld a,BANK(ZhPartyPromptText)
 call FarString
 hlcoord 1,1
 ld a,[wPartyCount]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 push hl
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 lb bc,2,6
 xor a
 call FillBoxWithByte
 pop hl
 lb bc,2,6
 call ClearBox
 pop hl
 ld de,ZhPartyCancelText
 ld a,BANK(ZhPartyCancelText)
 call FarString
 jp ApplyAttrAndTilemapInVBlank


; Reuse the native battle icon and status resolver. Six slots share three
; palettes, with alternating slots using color 1 or color 2.
ZhPartyStatus:
 ld a,[wZhPartyIndex]
 ld hl,wPartyMon1Status
 call GetPartyLocation
 ld d,h
 ld e,l
 farcall GetStatusConditionOrFaintIndex
 push af
 ld c,a
 ld b,0
 ld hl,wZhPartyStatuses
 ld a,[wZhPartyIndex]
 ld e,a
 ld d,0
 add hl,de
 ld [hl],c
 pop af
 and a
 jr nz,.status
 ; Healthy shiny members keep the original shiny symbol beside gender.
 ld a,[wZhPartyIndex]
 ld hl,wPartyMon1Shiny
 call GetPartyLocation
 ld a,[hl]
 and SHINY_MASK
 ret z
 call .coord
 ld [hl],'<SHINY>'
 ret
.status
 ld hl,StatusIconGFX
 ld bc,32
 rst AddNTimes
 ld de,wZhPartyStatusTiles
 ld c,16
.copy
 ld a,BANK(StatusIconGFX)
 call GetFarByte
 inc hl
 ld b,a
 ld a,BANK(StatusIconGFX)
 call GetFarByte
 inc hl
 push hl
 ld l,a
 ld a,[wZhPartyIndex]
 and 1
 ld a,b
 jr z,.ordered
 ld a,l
 ld l,b
.ordered
 ld [de],a
 inc de
 ld a,l
 ld [de],a
 inc de
 pop hl
 dec c
 jr nz,.copy
 ld a,[wZhPartyIndex]
 add a
 add $e0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,$8000
 add hl,bc
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld de,wZhPartyStatusTiles
 ld c,2
 ldh a,[hROMBank]
 ld b,a
 call Get2bpp
 pop af
 ldh [rVBK],a
 call .coord
 ld a,[wZhPartyIndex]
 add a
 add $e0
 ld [hli],a
 inc a
 ld [hl],a
 ret
.coord
 hlcoord 11,1
 ld a,[wZhPartyIndex]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 ret

ZhPartyStatusAttrs::
 ldh a,[rWBK]
 push af
 ld a,BANK(wBGPals1)
 ldh [rWBK],a
 ld hl,PartyMenuBGPals
 ld de,wBGPals1 palette 5
 ld bc,8
 ld a,BANK(PartyMenuBGPals)
 call FarCopyBytes
 ld hl,PartyMenuBGPals
 ld de,wBGPals1 palette 6
 ld bc,8
 ld a,BANK(PartyMenuBGPals)
 call FarCopyBytes
 ld hl,PartyMenuBGPals
 ld de,wBGPals1 palette 7
 ld bc,8
 ld a,BANK(PartyMenuBGPals)
 call FarCopyBytes
 xor a
 ld [wZhPartyIndex],a
.loop
 ld a,[wZhPartyIndex]
 ld e,a
 ld d,0
 ld hl,wZhPartyWidths
 add hl,de
 ld a,[hl]
 and a
 jr z,.next
 ld hl,wZhPartyStatuses
 add hl,de
 ld a,[hl]
 and a
 jr z,.healthy
 add a
 ld c,a
 ld b,0
 ld hl,StatusIconPals
 add hl,bc
 push hl
 ld a,[wZhPartyIndex]
 ld b,a
 srl a
 add a
 add a
 add a
 ld e,a
 ld d,0
 ld hl,wBGPals1 palette 5 color 1
 add hl,de
 bit 0,b
 jr z,.color
 inc hl
 inc hl
.color
 ld d,h
 ld e,l
 pop hl
 ld bc,2
 ld a,BANK(StatusIconPals)
 call FarCopyBytes
 ld a,[wZhPartyIndex]
 srl a
 add 13
 jr .attr
.healthy
 ld a,4
.attr
 push af
 hlcoord 11,1,wAttrmap
 ld a,[wZhPartyIndex]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 pop af
 ld [hli],a
 ld [hl],a
.next
 ld hl,wZhPartyIndex
 inc [hl]
 ld a,[hl]
 cp 6
 jr c,.loop
 pop af
 ldh [rWBK],a
 ret
