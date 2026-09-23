; Ordinary party display only. Original save data, numbers and actions.
ZhPartyLayout::
 ld hl,wZhPartyWidths
 ld bc,12
 xor a
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
 jp nc,.done
 ld hl,wPartyMon1IsEgg
 call GetPartyLocation
 bit MON_IS_EGG_F,[hl]
 jp nz,.skip
 ld a,[wZhPartyIndex]
 ld hl,wPartyMonNicknames
 call GetNickname
 ld hl,ZhPartyNames
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
 ld a,[hli] ; compile-time choice: six-tile bar for 2/3 CJK names
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
 ld a,l
 ld [wZhPartyLevelKeys],a
 ld a,h
 ld [wZhPartyLevelKeys+1],a
 ld bc,13
 add hl,bc
 push hl ; encoded name
 ; Preserve the real engine-formatted metadata before clearing its old cells.
 call .coord
 ld bc,2 * SCREEN_WIDTH + 8
 add hl,bc
 ld a,[hl]
 ld [wZhPartyGender],a
 call .coord
 ld bc,2 * SCREEN_WIDTH + 5
 add hl,bc
 ld de,wZhPartyLevel
 ld bc,3
 rst CopyBytes
 call .coord
 ld bc,SCREEN_WIDTH + 11
 add hl,bc
 ld de,wZhPartyHP
 ld bc,7
 rst CopyBytes
 ; Remove this row's old legacy fields, including its previous lower row.
 call .coord
 ld bc,SCREEN_WIDTH + 1
 add hl,bc
 ld bc,17
 ld a,$7f
 rst ByteFill
 call .coord
 ld bc,2 * SCREEN_WIDTH + 1
 add hl,bc
 ld bc,17
 ld a,$7f
 rst ByteFill
 ; Neutral text attrs before shared cache publishes bank bits.
 call .coord
 ld bc,wAttrmap-wTilemap
 add hl,bc
 lb bc,2,18
 xor a
 call FillBoxWithByte
 ld a,BANK(wZhCacheKeys)
 call .policy

 pop de
 call .coord
 rst PlaceString
 call .coord
 ld bc,8
 add hl,bc
 ld a,[wZhPartyGender]
 ld [hl],a
 call .coord
 ld bc,SCREEN_WIDTH + 8
 add hl,bc
 call ZhPartyShortShift
 ld d,h
 ld e,l
 ld hl,wZhPartyLevel
 ; Right-align the original level output against the HP label.
 ; Keep :L / digits intact; move only unused trailing cells to the left.
 ld bc,3
 ld a,[wZhPartyLevel + 2]
 cp $7f
 jr nz,.levelReady
 inc de
 dec c
 ld a,[wZhPartyLevel + 1]
 cp $7f
 jr nz,.levelReady
 inc de
 dec c
.levelReady
 rst CopyBytes
 call .coord
 ld bc,11
 add hl,bc
 ld d,h
 ld e,l
 ld hl,wZhPartyHP
 ld bc,7
 rst CopyBytes
 call .coord
 ld bc,SCREEN_WIDTH + 11
 add hl,bc
 call ZhPartyShortShift
 push hl
 ld a,[wZhPartyIndex]
 ld b,a
 farcall PlacePartymonHPBar
 call ZhPartyBarLength
 cp 6
 jr z,.fullbar
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
 jr .drawbar
.fullbar
 ld d,6
.drawbar
 pop hl
 call DrawBattleHPBar
 call ZhPartyCompactLevel
 call ZhPartyDrawHP
 call ZhPartyStatus
.skip
 ld hl,wZhPartyIndex
 inc [hl]
 jp .next
.mismatch
 pop hl
 jp .search
.done
 call ZhPartyAttributes
 jp ApplyAttrAndTilemapInVBlank
.coord
 hlcoord 2,0
 ld a,[wZhPartyIndex]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 ret
.policy
 call StackCallInWRAMBankA
.bank
 ld a,ZH_VRAM_BOTH
 ld [wZhPolicy],a
 ret

ZhPartyFooter::
 ld a,BANK(wZhCacheKeys)
 call .policy
 jr .draw
.policy
 call StackCallInWRAMBankA
.bank
 ld a,ZH_VRAM_BOTH
 ld [wZhPolicy],a
 ret
.draw
 ; Cancel has a dedicated two-tile row preceding the unchanged textbox.
 hlcoord 1,0
 ld a,[wPartyCount]
 ld bc,2 * SCREEN_WIDTH
 rst AddNTimes
 push hl
 lb bc,2,18
 call ClearBox
 pop hl
 ld de,ZhPartyCancel
 rst PlaceString
 hlcoord 1,15
 ld de,ZhPartyPrompt
 rst PlaceString
 jp ApplyAttrAndTilemapInVBlank

ZhPartyAttributes::
 ld a,[wPartyMenuActionText]
 and a
 ret nz
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
 jr z,.skip
 hlcoord 10,1,wAttrmap
 ld a,[wZhPartyIndex]
 ld bc,2*SCREEN_WIDTH
 rst AddNTimes
 call ZhPartyShortShift
 ld c,3
.levelattr
 ld a,[hl]
 and 8
 ld [hli],a
 dec c
 jr nz,.levelattr
 hlcoord 10,0,wAttrmap
 ld a,[wZhPartyIndex]
 ld bc,2*SCREEN_WIDTH
 rst AddNTimes
 ld [hl],4
 ld bc,SCREEN_WIDTH
 add hl,bc
 ld a,[hl]
 and 8
 ld [hl],a
 ; Original HP palette is selected from the live HP calculation.
 ld a,[wZhPartyIndex]
 ld e,a
 ld d,0
 ld hl,wHPPals
 add hl,de
 ld a,[hl]
 inc a
 push af
 hlcoord 13,1,wAttrmap
 ld a,[wZhPartyIndex]
 ld bc,2*SCREEN_WIDTH
 rst AddNTimes
 pop af
 ld b,a
 push hl
 push bc
 call ZhPartyBarLength
 cp 6
 jr nz,.labeldone
 dec hl
 dec hl
 pop bc
 ld [hl],b
 inc hl
 ld [hl],b
 push bc
.labeldone
 pop bc
 pop hl
 push hl
 ld de,-SCREEN_WIDTH
 add hl,de
 call .hpattrs
 pop hl
 call .hpattrs
.skip
 ld hl,wZhPartyIndex
 inc [hl]
 ld a,[hl]
 cp 6
 jp c,.loop
 jp ZhPartyStatusAttrs
.hpattrs
 ld c,7
.attrcell
 ld a,[hl]
 and 8
 or b
 ld [hli],a
 dec c
 jr nz,.attrcell
 ret

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
 hlcoord 11,0
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
 hlcoord 11,0,wAttrmap
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
 jp c,.loop
 pop af
 ldh [rWBK],a
 ret

; Format stays with PrintNum. Combine each formatted digit with its native
; bar tile using compile-time keys; digit y+2, bar y+8, real HP palette.
ZhPartyDrawHP::
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.bank
 hlcoord 13,0
 ld a,[wZhPartyIndex]
 ld bc,2*SCREEN_WIDTH
 rst AddNTimes
 ld a,7
.loop
 push af
 push hl
 ld a,[hl]
 cp $7f
 ld b,0
 jr z,.digit
 ld a,[hl]
 cp $dc
 ld b,1
 jr z,.digit
 sub $e0
 add 2
 ld b,a
.digit
 ld de,SCREEN_WIDTH
 add hl,de
 ld a,[hl]
 sub $63
 ld c,a
 ld a,b
 ld hl,ZhPartyHPKeys
 ld de,48
.times
 and a
 jr z,.bar
 add hl,de
 dec a
 jr .times
.bar
 ld b,0
 sla c
 rl b
 sla c
 rl b
 add hl,bc
 ld b,[hl]
 inc hl
 ld c,[hl]
 inc hl
 ld d,[hl]
 inc hl
 ld e,[hl]
 pop hl
 call ZhPlaceCacheBlock
 pop af
 dec a
 jr nz,.loop
 ret

; Layout choice is stored in the compiled name record, never measured here.
ZhPartyBarLength::
 push hl
 push de
 ld a,[wZhPartyIndex]
 ld e,a
 ld d,0
 ld hl,wZhPartyWidths
 add hl,de
 ld a,[hl]
 pop de
 pop hl
 ret
ZhPartyShortShift::
 call ZhPartyBarLength
 cp 6
 ret nz
 dec hl
 dec hl
 ret

; The original PrintNum output selects a precompiled shared-cell key.
; No runtime font measuring, shifting or glyph rasterization.
ZhPartyCompactLevel::
 ld a,[wZhPartyLevelKeys]
 ld l,a
 ld a,[wZhPartyLevelKeys+1]
 ld h,a
 ld a,[hli]
 ld b,a
 ld a,[wZhPartyLevel]
 cp $d6
 jr nz,.hundred
 ld a,[wZhPartyLevel+2]
 cp $7f
 jr nz,.pairReady
 ld de,8
 add hl,de
 ld a,9 ; one digit: compact L at x72
 jr .destination
.hundred
 ld a,b
 and a
 ret z ; unshared 100 stays native
 ld de,4
 add hl,de
.pairReady
 ld a,8 ; first shared level cell x64
.destination
 push af
 call ZhPartyBarLength
 cp 6
 jr z,.shortLevel
 pop af
 add 2
 push af
.shortLevel
 ld b,[hl]
 inc hl
 ld c,[hl]
 inc hl
 ld d,[hl]
 inc hl
 ld e,[hl]
 push bc
 push de
 hlcoord 0,0
 ld a,[wZhPartyIndex]
 ld bc,2*SCREEN_WIDTH
 rst AddNTimes
 pop de
 pop bc
 pop af
 push bc
 add SCREEN_WIDTH
 ld c,a
 ld b,0
 add hl,bc
 ; Cache upper cell is one row above the native level.
 ld bc,-SCREEN_WIDTH
 add hl,bc
 pop bc
 ld a,BANK(wZhCacheKeys)
 call StackCallInWRAMBankA
.draw
 jp ZhPlaceCacheBlock
