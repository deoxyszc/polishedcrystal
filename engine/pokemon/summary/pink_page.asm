SummaryScreen_PinkPage:
	ld a, SUMMARY_TILE_OAM_EXP_TITLE
	call SummaryScreen_UpdateTabTitle
	; Place pokerus
	ld a, [wTempMonPokerusStatus]
	and POKERUS_MASK
	jr z, .pokerusDone
	ld e, SUMMARY_TILE_POKERUS
	cp POKERUS_CURED
	jr nz, .placePokerus
	assert SUMMARY_TILE_POKERUS + 1 == SUMMARY_TILE_POKERUS_CURED
	inc e
.placePokerus
	hlbgcoord 0, 5, wSummaryScreenWindowBuffer
	ld [hl], e
	hlbgcoord 16, 5, wSummaryScreenWindowBuffer
	ld [hl], SUMMARY_PAL_SHINY_POKERUS
.pokerusDone
	; Place shiny
	ld bc, wTempMonShiny
	farcall CheckShininess
	jr nc, .shinyDone
	hlbgcoord 10, 0, wSummaryScreenWindowBuffer
	ld [hl], '<SHINY>'
	hlbgcoord 16 + 10, 0, wSummaryScreenWindowBuffer
	ld [hl], SUMMARY_PAL_SHINY_POKERUS
.shinyDone
	ld a, [wTextboxFlags]
	set USE_BG_MAP_WIDTH_F, a
	ld [wTextboxFlags], a

	; Place dex number
	ld a, [wCurPartySpecies]
	ld [wTempSpecies], a
	ld [wCurSpecies], a
	ld c, a
	ld a, [wCurForm]
	ld b, a
	call GetPokedexNumber
	ld d, b
	ld e, c
	hlbgcoord 0, 0, wSummaryScreenWindowBuffer
	ld a, '№'
	ld [hli], a
	ld a, '.'
	ld [hli], a
	lb bc, PRINTNUM_LEADINGZEROS | 2, 3
	call PrintNumFromReg ; sets de

	; Place name
	ld hl, wTempMonNickname
	call CopyNickname
	if DEF(LOCALE_ZH)
 hlbgcoord 0, 2, wSummaryScreenWindowBuffer
else
 hlbgcoord 0, 1, wSummaryScreenWindowBuffer
endc
if DEF(LOCALE_ZH)
 farcall PlaceChineseDefaultName
 call c,_PlaceString
else
 rst PlaceString
endc
	if DEF(LOCALE_ZH)
 hlbgcoord 0, 4, wSummaryScreenWindowBuffer
else
 hlbgcoord 1, 2, wSummaryScreenWindowBuffer
endc
	ld a, '/'
	ld [hli], a
	push hl
	call GetPartyPokemonName
	pop hl
if DEF(LOCALE_ZH)
 farcall PlaceChineseDefaultName
 call c,_PlaceString
else
 rst PlaceString
endc

	; Place ball
	if DEF(LOCALE_ZH)
 hlbgcoord 8, 1, wSummaryScreenWindowBuffer
else
 hlbgcoord 8, 3, wSummaryScreenWindowBuffer
endc
	ld a, SUMMARY_TILE_BALL_SIDE_BORDER
	ld [hli], a
	ld a, SUMMARY_TILE_BALL
	ld [hli], a
	ld a, SUMMARY_TILE_BALL_SIDE_BORDER
	ld [hli], a

	if DEF(LOCALE_ZH)
 hlbgcoord 25, 1, wSummaryScreenWindowBuffer
else
 hlbgcoord 25, 3, wSummaryScreenWindowBuffer
endc
	ld a, SUMMARY_PAL_POKEBALL
	ld [hli], a

	if DEF(LOCALE_ZH)
 hlbgcoord 26, 1, wSummaryScreenWindowBuffer
else
 hlbgcoord 26, 3, wSummaryScreenWindowBuffer
endc
	ld [hl], OAM_XFLIP | SUMMARY_PAL_SIDE_WINDOW

	ld hl, .BallSprites
	ld bc, 8
	ld de, wSummaryScreenOAMSprite12
	rst CopyBytes

	ld hl, .StatusSprites
	ld bc, 8
	ld de, wSummaryScreenOAMSprite14
	rst CopyBytes

	ld c, 4
	call DelayFrames

	ld d, 0 | 8
	ld a, [wBaseType1]
if DEF(LOCALE_ZH)
 lb bc,72,72
else
	lb bc, 72, 76
endc
	ld hl, wSummaryScreenOAMSprite04
	call SummaryScreen_PlaceTypeOBJ
	if DEF(LOCALE_ZH)
 debgcoord 0, 5, wSummaryScreenWindowBuffer
else
 debgcoord 0, 3, wSummaryScreenWindowBuffer
endc
	call SummaryScreen_PlaceTypeBG

	; Place types
	ld a, [wBaseType1]
	ld e, a
	ld a, [wBaseType2]
	cp e
	jr z, .doneTypes
	ld d, 1 | 8
if DEF(LOCALE_ZH)
 lb bc,104,72
else
	lb bc, 104, 76
endc
	ld hl, wSummaryScreenOAMSprite08
	call SummaryScreen_PlaceTypeOBJ
	if DEF(LOCALE_ZH)
 debgcoord 4, 5, wSummaryScreenWindowBuffer
else
 debgcoord 4, 3, wSummaryScreenWindowBuffer
endc
	call SummaryScreen_PlaceTypeBG

.doneTypes
	call .PlaceOTInfo
	ld a, [wTextboxFlags]
	res USE_BG_MAP_WIDTH_F, a
	ld [wTextboxFlags], a
	hlcoord 9, 8
	ld de, SCREEN_WIDTH
	ld b, 10

if DEF(LOCALE_ZH)
 call .CalcExpToNextLevel
 call .ChineseExperience
else
	ld de, .ExpPointStr
	hlcoord 1, 13
	rst PlaceString
	hlcoord 12, 13
	lb bc, 3, 7
	ld de, wTempMonExp
	call PrintNum
	call .CalcExpToNextLevel
	hlcoord 12, 15
	lb bc, 3, 7
	ld de, wExpToNextLevel
	call PrintNum
	ld de, .LevelUpStr
	hlcoord 1, 15
	rst PlaceString
	ld de, .ToStr
	hlcoord 13, 17
	rst PlaceString
	hlcoord 16, 17
	call .PrintNextLevel
endc
	hlcoord 3, 17
	ld a, [wTempMonLevel]
	ld b, a
	ld de, wTempMonExp + 2
	farcall FillInExpBar
	hlcoord 1, 17
	ld a, '<XP1>'
	ld [hli], a
	ld [hl], '<XP2>'
	hlcoord 10, 17
	ld [hl], '<XPEND>'
if DEF(LOCALE_ZH)
 ld de,TextSummaryExp
 farcall DrawChineseSummaryTab
endc

	ld hl, .PinkPalettes
	ld bc, 1 palettes
	ld de, wSummaryScreenPals palette SUMMARY_PAL_LOWER_WINDOW
	rst CopyBytes
	ld bc, 1 palettes
	ld de, wSummaryScreenPals palette SUMMARY_PAL_SIDE_WINDOW
	rst CopyBytes
	ld bc, 1 palettes
	ld de, wSummaryScreenPals palette SUMMARY_PAL_SHINY_POKERUS
	rst CopyBytes

	ld hl, CaughtBallPals
	ld bc, 2 colors
	ld a, [wTempMonCaughtBall]
	and CAUGHT_BALL_MASK
	rst AddNTimes
	ld de, wSummaryScreenPals palette SUMMARY_PAL_POKEBALL
	farjp LoadPalette_White_Col1_Col2_Black

.PrintNextLevel:
	ld a, [wTempMonLevel]
	push af
	cp MAX_LEVEL
	jr z, .atMaxLevel
	inc a
	ld [wTempMonLevel], a
.atMaxLevel
	call PrintLevel
	pop af
	ld [wTempMonLevel], a
	ret

.CalcExpToNextLevel:
	ld a, [wTempMonLevel]
	cp MAX_LEVEL
	jr z, .AlreadyAtMaxLevel
	inc a
	ld d, a
	farcall CalcExpAtLevel
	ld hl, wTempMonExp + 2
	ldh a, [hQuotient + 2]
	sub [hl]
	dec hl
	ld [wExpToNextLevel + 2], a
	ldh a, [hQuotient + 1]
	sbc [hl]
	dec hl
	ld [wExpToNextLevel + 1], a
	ldh a, [hQuotient]
	sbc [hl]
	ld [wExpToNextLevel], a
	ret

.AlreadyAtMaxLevel:
	ld hl, wExpToNextLevel
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

.PlaceOTInfo:
if DEF(LOCALE_ZH)
 farcall BT_InRentalMode
 jr nz,.chineseOT
 hlbgcoord 0,7,wSummaryScreenWindowBuffer
 ld de,.Rental_OT
 rst PlaceString
 ret
.chineseOT
 hlbgcoord 0,7,wSummaryScreenWindowBuffer
 ld de,TextSummaryOT
 ld a,BANK(TextSummaryOT)
 call FarString
 ld hl,wTempMonOT
 call CopyNickname
 hlbgcoord 5,7,wSummaryScreenWindowBuffer
 rst PlaceString
 hlbgcoord 1,8,wSummaryScreenWindowBuffer
 ld de,.IDStr
 rst PlaceString
 hlbgcoord 4,8,wSummaryScreenWindowBuffer
 lb bc,PRINTNUM_LEADINGZEROS | 2,5
 ld de,wTempMonID
 jp PrintNum
else
	; for rental mons, replace the whole thing with "Rental #mon"
	farcall BT_InRentalMode
	hlbgcoord 0, 4, wSummaryScreenWindowBuffer
	jr nz, .not_rental_mon
	ld de, .Rental_OT
	rst PlaceString
	ret

.not_rental_mon
	ld de, .OTStr
	rst PlaceString
	ld de, .IDStr
	hlbgcoord 2, 5, wSummaryScreenWindowBuffer
	rst PlaceString
	hlbgcoord 5, 5, wSummaryScreenWindowBuffer
	lb bc, PRINTNUM_LEADINGZEROS | 2, 5
	ld de, wTempMonID
	call PrintNum
	ld hl, wTempMonOT
	call CopyNickname
	hlbgcoord 4, 4, wSummaryScreenWindowBuffer
	rst PlaceString
	ret
endc

.PinkPalettes:
INCLUDE "gfx/stats/pink_page.pal"

.BallSprites:
if DEF(LOCALE_ZH)
 db 32, 144, SUMMARY_TILE_OAM_BALL_TOP_BORDER, OAM_YFLIP
 db 48, 144, SUMMARY_TILE_OAM_BALL_TOP_BORDER, 0
else
	db 68, 144, SUMMARY_TILE_OAM_BALL_TOP_BORDER, OAM_YFLIP
	db 84, 144, SUMMARY_TILE_OAM_BALL_TOP_BORDER, 0

endc
.StatusSprites:
	db 31, 120, SUMMARY_TILE_OAM_STATUS + 0, 5
	db 31, 128, SUMMARY_TILE_OAM_STATUS + 1, 5

.OTStr:
	text "OT/"
	done

.IDStr
if DEF(LOCALE_ZH)
 db "<ID>№.@"
else
	text "<ID>№."
	done
endc

.Rental_OT:
if DEF(LOCALE_ZH)
 db "Rental<NEXT>  #mon@"
else
	text  "Rental"
	next1 "  #mon"
	done
endc

.ExpPointStr:
	db "Exp.Points@"

.LevelUpStr:
	db "Level Up@"

.ToStr:
	db "to@"

if DEF(LOCALE_ZH)
.ChineseExperience:
 hlcoord 1,14
 ld de,TextSummaryExp
 ld a,BANK(TextSummaryExp)
 call FarString
 hlcoord 4,14
 ld de,wTempMonExp
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call PrintNum
 ld a,[wTempMonLevel]
 cp MAX_LEVEL
 jr z,.maximum
 hlcoord 1,16
 ld de,TextSummaryNeed
 ld a,BANK(TextSummaryNeed)
 call FarString
 hlcoord 4,16
 ld de,wExpToNextLevel
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call PrintNum
 ld de,TextSummaryExp
 ld a,BANK(TextSummaryExp)
 call FarString
 hlcoord 13,17
 ld a,[wTempMonLevel]
 cp 99
 jr c,.prefix
 dec hl
.prefix
 ld de,TextSummaryLevelUp
 ld a,BANK(TextSummaryLevelUp)
 call FarString
 ld a,[wTempMonLevel]
 inc a
 ld [wTextDecimalByte],a
 hlcoord 16,17
 cp 100
 jr c,.number
 dec hl
.number
 ld de,wTextDecimalByte
 lb bc,PRINTNUM_LEFTALIGN | 1,3
 call PrintNum
 ld de,TextSummaryLevel
 ld a,BANK(TextSummaryLevel)
 jp FarString
.maximum
 hlcoord 13,17
 ld de,TextSummaryMax
 ld a,BANK(TextSummaryMax)
 jp FarString
endc

CopyNickname:
	ld de, wStringBuffer1
	ld bc, MON_NAME_LENGTH
	push de
	rst CopyBytes
	pop de
	ret
