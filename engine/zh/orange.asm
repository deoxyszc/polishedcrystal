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
 hlbgcoord 0,0,wSummaryScreenWindowBuffer
 ld a,[wTextboxFlags]
 push af
 set USE_BG_MAP_WIDTH_F,a
 ld [wTextboxFlags],a
 ld a,BANK(ZhOrangeTable)
 call FarString
 pop af
 ld [wTextboxFlags],a
 ret

ZhOrangeCharacter::
 ld hl,ZhOrangeCharacterTable
 call ZhOrangeLookup
 ret c
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld a,[wTextboxFlags]
 push af
 set USE_BG_MAP_WIDTH_F,a
 ld [wTextboxFlags],a
 ld a,BANK(ZhOrangeTable)
 call FarString
 pop af
 ld [wTextboxFlags],a
 ret

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
 hlcoord 1,13
 ld a,BANK(ZhOrangeTable)
 call FarString
 ld a,[wTempMonCaughtLocation]
 ld hl,ZhOrangeLocationTable
 call ZhOrangeLookup
 hlcoord 4,13
 ld a,BANK(ZhOrangeTable)
 call FarString
 ld de,ZhOrangeLevelPrefixTiles
 hlcoord 1,15
 ld a,BANK(ZhOrangeTable)
 call FarString
 hlcoord ZH_ORANGE_LEVEL_DIGIT_X,15
 ld de,wTempMonCaughtLevel
 lb bc,PRINTNUM_LEFTALIGN | 1,3
 call PrintNum
 ld a,[wTempMonCaughtLevel]
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X1,15
 cp 10
 jr c,.suffixReady
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X2,15
 cp 100
 jr c,.suffixReady
 hlcoord ZH_ORANGE_LEVEL_SUFFIX_X3,15
.suffixReady
 ld de,ZhOrangeLevelSuffixTiles
 ld a,BANK(ZhOrangeTable)
 call FarString
 ld a,1
 ld [wZhOrangeEncounterActive],a
 ret
endc

if ZH_ORANGE_TAB
ZhOrangeTitle::
 hlcoord 1,11
 ld de,ZhOrangeTabText
 ld a,BANK(ZhOrangeTabText)
 call FarString
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 ret
endc
