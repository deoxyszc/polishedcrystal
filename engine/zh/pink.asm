; Pink-page display adapter. Original data calculation remains in the caller.
ZhPinkLayout::
 ; Retain original type/ball, OT and ID/status rows while opening 16px names.
 hlbgcoord 0,5,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+8*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+6*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld de,wSummaryScreenWindowBuffer+5*32
 ld bc,32
 rst CopyBytes
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,1,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,2,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,3,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,4,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 hlbgcoord 0,7,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 hlbgcoord 16,7,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 ; Redraw native fallback names first, then replace only matching translations.
 ld a,[wTextboxFlags]
 push af
 set USE_BG_MAP_WIDTH_F,a
 ld [wTextboxFlags],a
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld de,wTempMonNickname
 rst PlaceString
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld a,'/'
 ld [hli],a
 ld de,wZhPinkSpecies
 rst PlaceString
 pop af
 ld [wTextboxFlags],a
 ld de,wTempMonNickname
 call .lookup
 jr c,.species
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld a,BANK(ZhPinkNameTable)
 call FarString
.species
 ld de,wZhPinkSpecies
 call .lookup
 jr c,.labels
 hlbgcoord 1,3,wSummaryScreenWindowBuffer
 ld a,BANK(ZhPinkNameTable)
 call FarString
 ld de,ZhPinkSlashTiles
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld a,BANK(ZhPinkNameTable)
 call FarString
.labels
 ; Restore type sprite alignment with the new native type row.
 ld a,72
 ld [wSummaryScreenOAMSprite04YCoord],a
 ld [wSummaryScreenOAMSprite05YCoord],a
 ld [wSummaryScreenOAMSprite06YCoord],a
 ld [wSummaryScreenOAMSprite07YCoord],a
 ld a,[wBaseType1]
 ld b,a
 ld a,[wBaseType2]
 cp b
 jr z,.ball
 ld a,72
 ld [wSummaryScreenOAMSprite08YCoord],a
 ld [wSummaryScreenOAMSprite09YCoord],a
 ld [wSummaryScreenOAMSprite10YCoord],a
 ld [wSummaryScreenOAMSprite11YCoord],a
.ball
 ld a,64
 ld [wSummaryScreenOAMSprite12YCoord],a
 ld a,80
 ld [wSummaryScreenOAMSprite13YCoord],a
if ZH_PINK_OT
 farcall BT_InRentalMode
 jr z,.otDone
 ld hl,wTempMonOT
 ld b,0
.otLength
 ld a,[hli]
 cp '@'
 jr z,.otFit
 inc b
 ld a,b
 cp 7
 jr c,.otLength
 jr .otDone
.otFit
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$7f
 rst ByteFill
 ld a,[wTextboxFlags]
 push af
 set USE_BG_MAP_WIDTH_F,a
 ld [wTextboxFlags],a
 hlbgcoord 6,6,wSummaryScreenWindowBuffer
 ld de,wTempMonOT
 rst PlaceString
 pop af
 ld [wTextboxFlags],a
 ld de,ZhPinkOTTiles
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld a,BANK(ZhPinkNameTable)
 call FarString
.otDone
endc
if ZH_PINK_EXP && ZH_PINK_NEXT && ZH_PINK_TO && ZH_PINK_LEVEL
 hlcoord 1,13
 ld bc,19
 ld a,$7f
 rst ByteFill
 ld de,ZhPinkExpTiles
 hlcoord 1,13
 ld a,BANK(ZhPinkNameTable)
 call FarString
 hlcoord 4,13
 ld de,wTempMonExp
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call PrintNum
 push hl
 hlcoord 4,13
 call .alignDigits
 pop hl
 hlcoord 1,15
 ld bc,19
 ld a,$7f
 rst ByteFill
 ld de,ZhPinkNextTiles
 hlcoord 1,15
 ld a,BANK(ZhPinkNameTable)
 call FarString
 hlcoord 4,15
 ld de,wExpToNextLevel
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call PrintNum
 push hl
 hlcoord 4,15
 call .alignDigits
 pop hl
 ; Append the translated experience label after the live number.
 ld de,ZhPinkExpTiles
 ld a,BANK(ZhPinkNameTable)
 call FarString
endc
if ZH_PINK_TAB
 call ZhPinkTitle
endc
if ZH_PINK_EXP && ZH_PINK_NEXT && ZH_PINK_TO && ZH_PINK_LEVEL
 hlcoord 11,17
 ld bc,9
 ld a,$7f
 rst ByteFill
 ld de,ZhPinkToTiles
 hlcoord 12,16
 ld a,BANK(ZhPinkNameTable)
 call FarString
 ld a,[wTempMonLevel]
 cp MAX_LEVEL
 jr z,.nextReady
 inc a
.nextReady
 ld [wTextDecimalByte],a
 hlcoord 15,16
 ld de,wTextDecimalByte
 lb bc,PRINTNUM_LEFTALIGN | 1,3
 call PrintNum
 push hl
 hlcoord 15,16
 call .alignDigits
 pop hl
 ld de,ZhPinkLevelTiles
 ld a,BANK(ZhPinkNameTable)
 call FarString
endc
 ret
.alignDigits
 ret ; retain native numeric tile IDs

.lookup
 ld hl,ZhPinkNameTable
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
 ld b,10
.compare
 ld a,[de]
 cp [hl]
 jr nz,.mismatch
 inc de
 inc hl
 dec b
 jr nz,.compare
 pop de
 pop bc
 ld d,h
 ld e,l
 and a
 ret
.mismatch
 pop de
 pop hl
 jr .next
.missing
 scf
 ret
if ZH_PINK_TAB
ZhPinkTitle::
 hlcoord 1,11
 ld de,ZhPinkTabText
 ld a,BANK(ZhPinkTabText)
 call FarString
 xor a
 ld [wSummaryScreenOAMSprite36YCoord],a
 ld [wSummaryScreenOAMSprite37YCoord],a
 ld [wSummaryScreenOAMSprite38YCoord],a
 ld [wSummaryScreenOAMSprite39YCoord],a
 ret
endc
