ZhOrangePage::
 push af
 ld hl,ZhOrangeNatureTable
 call ZhOrangeLookup
 jr c,.missing
 pop af
 push af
 ld a,[wZhOrangeCharacteristic]
 ld hl,ZhOrangeCharacterTable
 call ZhOrangeLookup
 jr c,.missing
 pop af
 call ZhOrangeNature
 ld a,[wZhOrangeCharacteristic]
 call ZhOrangeCharacter
 ld a,1
 ld [wZhOrangeActive],a
if ZH_ORANGE_TAB
 call ZhOrangeTitle
endc
 ret
.missing
 pop af
 ret

; Original GetNature and characteristic calculation supply the live indices.
ZhOrangeNature::
 ld hl,ZhOrangeNatureTable
 call ZhOrangeLookup
 ret c
 ld hl,$8800
 ld c,48
 call ZhOrangeUpload
 hlbgcoord 0,0,wSummaryScreenWindowBuffer
 ld a,$80
 ld b,4
 jp ZhOrangePlace

ZhOrangeCharacter::
 ld hl,ZhOrangeCharacterTable
 call ZhOrangeLookup
 ret c
 ld hl,$8b00
 ld c,60
 call ZhOrangeUpload
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld a,$b0
 ld b,5
 jp ZhOrangePlace

ZhOrangeLookup:
 ld e,a
 ld d,0
 add hl,de
 add hl,de
 ld a,[hli]
 ld e,a
 ld d,[hl]
 or d
 ret nz
 scf
 ret

ZhOrangeUpload:
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld b,BANK(ZhOrangeTable)
 call Get2bpp
 pop af
 ldh [rVBK],a
 ret

ZhOrangePlace:
.row
 push hl
 ld c,12
.tile
 ld [hli],a
 inc a
 dec c
 jr nz,.tile
 pop hl
 push af
 push hl
 ld de,16
 add hl,de
 ld c,12
 ld a,8 | SUMMARY_PAL_SIDE_WINDOW
.attr
 ld [hli],a
 dec c
 jr nz,.attr
 pop hl
 ld de,32
 add hl,de
 pop af
 dec b
 jr nz,.row
 ret

; Admit all encounter pieces before replacing the native lower panel.
ZhOrangeEncounter::
 ld a,[wZhOrangeActive]
 and a
 ret z
 farcall BT_InRentalMode
 ret z
 ld a,[wTempMonCaughtLevel]
 and a
 ret z
 cp $ff
 ret z
 ld a,[wTempMonCaughtLocation]
 and a
 ret z
 cp LANDMARK_EVENT
 ret z
 ld hl,ZhOrangeLocationTable
 call ZhOrangeLookup
 ret c
 ld a,[wTempMonCaughtTime]
 and CAUGHT_TIME_MASK
 rlca
 rlca
 rlca
 ld hl,ZhOrangeTimeTable
 call ZhOrangeLookup
 ret c
if !ZH_ORANGE_LEVELPREFIX || !ZH_ORANGE_LEVELSUFFIX
 ret
else
 hlcoord 0,13
 lb bc,5,20
 call ClearBox
 ld a,[wTempMonCaughtTime]
 and CAUGHT_TIME_MASK
 rlca
 rlca
 rlca
 ld hl,ZhOrangeTimeTable
 call ZhOrangeLookup
 ld hl,$8ed0
 ld c,6
 call ZhOrangeUpload
 hlcoord 1,13
 ld a,$ed
 ld c,3
 call ZhOrangeLowerPlace
 ld a,[wTempMonCaughtLocation]
 ld hl,ZhOrangeLocationTable
 call ZhOrangeLookup
 ld hl,$9400
 ld c,30
 call ZhOrangeUpload
 hlcoord 4,13
 ld a,$40
 ld c,15
 call ZhOrangeLowerPlace
 ld de,ZhOrangeLevelPrefixTiles
 ld hl,$95e0
 ld c,12
 call ZhOrangeUpload
 hlcoord 1,15
 ld a,$5e
 ld c,6
 call ZhOrangeLowerPlace
 zh_upload_tiles ZhSummaryDigits0, $96a0, 10
 zh_upload_tiles ZhSummaryDigits1, $9740, 10
 hlcoord ZH_ORANGE_LEVEL_DIGIT_X,15
 ld de,wTempMonCaughtLevel
 lb bc,PRINTNUM_LEFTALIGN | 1,3
 call PrintNum
 push hl
 hlcoord ZH_ORANGE_LEVEL_DIGIT_X,15
.digit
 ld a,[hl]
 sub $e0
 cp 10
 jr nc,.digitsDone
 push hl
 push af
 add $6a
 ld [hl],a
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 pop af
 pop hl
 push hl
 ld de,SCREEN_WIDTH
 add hl,de
 add $74
 ld [hl],a
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 pop hl
 inc hl
 jr .digit
.digitsDone
 pop hl
 ld de,ZhOrangeLevelSuffixTiles
 ld hl,$9380
 ld c,4
 call ZhOrangeUpload
 ld a,[wTempMonCaughtLevel]
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X1,15
 cp 10
 jr c,.suffixReady
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X2,15
 cp 100
 jr c,.suffixReady
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X3,15
.suffixReady
 ld a,$38
 ld c,2
 call ZhOrangeLowerPlace
 ld a,1
 ld [wZhOrangeEncounterActive],a
 ret
endc

ZhOrangeLowerPlace:
 ld b,2
.row
 push bc
 push hl
.tile
 ld [hli],a
 inc a
 dec c
 jr nz,.tile
 pop hl
 pop bc
 push af
 push bc
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld b,0
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
 rst ByteFill
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 pop bc
 pop af
 dec b
 jr nz,.row
 ret

if ZH_ORANGE_TAB
ZhOrangeTitle::
 ld hl,wSummaryScreenPals palette SUMMARY_PAL_LOWER_WINDOW
 ld de,wSummaryScreenPals palette 2
 ld bc,8
 rst CopyBytes
 ld hl,wSummaryScreenPals palette 2 color 1
 ld a,$ff
 ld [hli],a
 ld a,$7f
 ld [hl],a
 ld a,1
 ldh [rVBK],a
 ld hl,$9200
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
 zh_screen_tiles 1, 11, 5, 2, 37, 8 | 2
 ret
.Tiles:
 INCBIN "gfx/zh/encounter_tab.2bpp"

endc
