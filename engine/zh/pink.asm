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
 ld hl,$8800
 call .uploadName
 hlbgcoord 0,1,wSummaryScreenWindowBuffer
 ld a,$80
 call .nameMap
.species
 ld de,wZhPinkSpecies
 call .lookup
 jr c,.labels
 ld hl,$8900
 call .uploadName
 hlbgcoord 1,3,wSummaryScreenWindowBuffer
 ld a,$90
 call .nameMap
 ld de,ZhPinkSlashTiles
 ld hl,$8d00
 ld c,2
 call .upload
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld [hl],$d0
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld [hl],$d1
 hlbgcoord 16,3,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 16,4,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
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
 ld hl,$8b40
 ld c,12
 call .upload
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld a,$b4
 call .otMap
 call ZhPinkAlignOT
.otDone
endc
if ZH_PINK_EXP && ZH_PINK_NEXT && ZH_PINK_TO && ZH_PINK_LEVEL
 zh_upload_tiles ZhSummaryDigits0, $8d60, 10
 zh_upload_tiles ZhSummaryDigits1, $8f00, 10
 hlcoord 1,13
 ld bc,19
 ld a,$7f
 rst ByteFill
 ld de,ZhPinkExpTiles
 ld hl,$8a00
 call .uploadLabel
 hlcoord 1,13
 ld a,$a0
 call .labelMap
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
 ld hl,$8aa0
 call .uploadLabel
 hlcoord 1,15
 ld a,$aa
 call .labelMap
 hlcoord 4,15
 ld de,wExpToNextLevel
 lb bc,PRINTNUM_LEFTALIGN | 3,7
 call PrintNum
 push hl
 hlcoord 4,15
 call .alignDigits
 pop hl
 ; Append the translated experience label after the live number.
 ld a,$a0
 call .labelMap
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
 ld hl,$8fa0
 ld c,6
 call .upload
 hlcoord 12,16
 ld a,$fa
 ld b,2
.toRow
 push hl
 ld c,3
.toTile
 ld [hli],a
 inc a
 dec c
 jr nz,.toTile
 pop hl
 push af
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld c,3
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
.toAttr
 ld [hli],a
 dec c
 jr nz,.toAttr
 pop hl
 ld de,20
 add hl,de
 pop af
 dec b
 jr nz,.toRow
 ld de,ZhPinkLevelTiles
 ld hl,$8d20
 ld c,4
 call .upload
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
 ld a,$d2
 ld b,2
.suffixRow
 ld [hli],a
 inc a
 ld [hld],a
 inc a
 push af
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
 ld [hli],a
 ld [hl],a
 pop hl
 ld de,SCREEN_WIDTH
 add hl,de
 pop af
 dec b
 jr nz,.suffixRow
endc
 ret
.alignDigits
 ld a,[hl]
 sub $e0
 cp 10
 ret nc
 push hl
 push af
 add $d6
 ld [hl],a
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 pop af
 pop hl
 push hl
 ld de,SCREEN_WIDTH
 add hl,de
 add $f0
 ld [hl],a
 ld de,wAttrmap-wTilemap
 add hl,de
 ld [hl],8 | SUMMARY_PAL_LOWER_WINDOW
 pop hl
 inc hl
 jr .alignDigits

.otMap
 ld b,2
.otRow
 push hl
 ld c,6
.otTile
 ld [hli],a
 inc a
 dec c
 jr nz,.otTile
 pop hl
 push af
 push hl
 ld de,16
 add hl,de
 push bc
 ld bc,6
 ld a,8 | SUMMARY_PAL_SIDE_WINDOW
 rst ByteFill
 pop bc
 pop hl
 ld de,32
 add hl,de
 pop af
 dec b
 jr nz,.otRow
 ret
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
.uploadName
 ld c,16
 jr .upload
.uploadLabel
 ld c,10
.upload
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld b,BANK(ZhPinkNameTable)
 call Get2bpp
 pop af
 ldh [rVBK],a
 ret
.nameMap
 ld b,2
.nameRow
 push hl
 ld c,8
.nameTile
 ld [hli],a
 inc a
 dec c
 jr nz,.nameTile
 pop hl
 push af
 push hl
 ld de,16
 add hl,de
 ld c,8
 ld a,8 | SUMMARY_PAL_SIDE_WINDOW
.nameAttr
 ld [hli],a
 dec c
 jr nz,.nameAttr
 pop hl
 ld de,32
 add hl,de
 pop af
 dec b
 jr nz,.nameRow
 ret
.labelMap
 ld b,2
.labelRow
 push hl
 ld c,3
.labelTile
 ld [hli],a
 inc a
 dec c
 jr nz,.labelTile
 pop hl
 push af
 push hl
 ld de,wAttrmap-wTilemap
 add hl,de
 ld c,3
 ld a,8 | SUMMARY_PAL_LOWER_WINDOW
.labelAttr
 ld [hli],a
 dec c
 jr nz,.labelAttr
 pop hl
 ld de,20
 add hl,de
 pop af
 add 2
 dec b
 jr nz,.labelRow
 ret

if ZH_PINK_TAB
ZhPinkTitle::
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
 ld hl,$8e00
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
 zh_screen_tiles 1, 11, 5, 2, 229, 8 | 2
 ret
.Tiles:
 INCBIN "gfx/zh/experience_tab.2bpp"

endc

ZhPinkAlignOT::
 hlbgcoord 6,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip0
 sub $80
 cp 114
 jr nc,.skip0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8c40
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 6,6,wSummaryScreenWindowBuffer
 ld [hl],196
 hlbgcoord 22,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 6,7,wSummaryScreenWindowBuffer
 ld [hl],197
 hlbgcoord 22,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip0
 hlbgcoord 7,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip1
 sub $80
 cp 114
 jr nc,.skip1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8c60
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 7,6,wSummaryScreenWindowBuffer
 ld [hl],198
 hlbgcoord 23,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 7,7,wSummaryScreenWindowBuffer
 ld [hl],199
 hlbgcoord 23,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip1
 hlbgcoord 8,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip2
 sub $80
 cp 114
 jr nc,.skip2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8c80
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 8,6,wSummaryScreenWindowBuffer
 ld [hl],200
 hlbgcoord 24,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 8,7,wSummaryScreenWindowBuffer
 ld [hl],201
 hlbgcoord 24,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip2
 hlbgcoord 9,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip3
 sub $80
 cp 114
 jr nc,.skip3
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8ca0
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 9,6,wSummaryScreenWindowBuffer
 ld [hl],202
 hlbgcoord 25,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 9,7,wSummaryScreenWindowBuffer
 ld [hl],203
 hlbgcoord 25,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip3
 hlbgcoord 10,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip4
 sub $80
 cp 114
 jr nc,.skip4
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8cc0
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 10,6,wSummaryScreenWindowBuffer
 ld [hl],204
 hlbgcoord 26,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 10,7,wSummaryScreenWindowBuffer
 ld [hl],205
 hlbgcoord 26,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip4
 hlbgcoord 11,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 cp $7f
 jr z,.skip5
 sub $80
 cp 114
 jr nc,.skip5
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,.Font
 add hl,de
 ld d,h
 ld e,l
 ld hl,$8ce0
 ld a,1
 ldh [rVBK],a
 ld b,BANK(.Font)
 ld c,2
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 11,6,wSummaryScreenWindowBuffer
 ld [hl],206
 hlbgcoord 27,6,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 hlbgcoord 11,7,wSummaryScreenWindowBuffer
 ld [hl],207
 hlbgcoord 27,7,wSummaryScreenWindowBuffer
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
.skip5
 ret
.Font:
 INCBIN "gfx/zh/pink_ascii.2bpp"
