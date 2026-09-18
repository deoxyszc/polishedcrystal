; Preserve original formatted values and nature colors.
ZhSummaryTwoLine::
 hlbgcoord 8,2,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+0],a
 hlbgcoord 9,2,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+1],a
 hlbgcoord 10,2,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+2],a
 hlbgcoord 24,2,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+3],a
 hlbgcoord 8,3,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+4],a
 hlbgcoord 9,3,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+5],a
 hlbgcoord 10,3,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+6],a
 hlbgcoord 24,3,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+7],a
 hlbgcoord 8,4,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+8],a
 hlbgcoord 9,4,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+9],a
 hlbgcoord 10,4,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+10],a
 hlbgcoord 24,4,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+11],a
 hlbgcoord 8,5,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+12],a
 hlbgcoord 9,5,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+13],a
 hlbgcoord 10,5,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+14],a
 hlbgcoord 24,5,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+15],a
 hlbgcoord 8,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+16],a
 hlbgcoord 9,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+17],a
 hlbgcoord 10,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+18],a
 hlbgcoord 24,6,wSummaryScreenWindowBuffer
 ld a,[hl]
 ld [wZhStatsSaved+19],a
 ld a,[wTempMonHyperTraining]
 ld [wZhStatsFlags],a
 ldh a,[rWBK]
 push af
 ld a,BANK(wZhStatsPixels)
 ldh [rWBK],a
 ld hl,.Panel
 ld de,wZhStatsPixels
 ld bc,1536
 rst CopyBytes
 ld a,[wZhStatsSaved+0]
 sub $e0
 cp 10
 jr nc,.skip0_0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+208
 call .copyPair
.skip0_0
 ld a,[wZhStatsSaved+1]
 sub $e0
 cp 10
 jr nc,.skip0_1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+224
 call .copyPair
.skip0_1
 ld a,[wZhStatsSaved+2]
 sub $e0
 cp 10
 jr nc,.skip0_2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+240
 call .copyPair
.skip0_2
 ld a,[wZhStatsFlags]
 bit 6,a
 jr z,.noMarker0
 ld hl,.Markers+0
 ld de,wZhStatsPixels+256
 call .copyPair
.noMarker0
 ld a,[wZhStatsSaved+4]
 sub $e0
 cp 10
 jr nc,.skip1_0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+304
 call .copyPair
.skip1_0
 ld a,[wZhStatsSaved+5]
 sub $e0
 cp 10
 jr nc,.skip1_1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+320
 call .copyPair
.skip1_1
 ld a,[wZhStatsSaved+6]
 sub $e0
 cp 10
 jr nc,.skip1_2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+336
 call .copyPair
.skip1_2
 ld a,[wZhStatsFlags]
 bit 5,a
 jr z,.noMarker1
 ld hl,.Markers+0
 ld de,wZhStatsPixels+352
 call .copyPair
.noMarker1
 ld a,[wZhStatsSaved+8]
 sub $e0
 cp 10
 jr nc,.skip2_0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+784
 call .copyPair
.skip2_0
 ld a,[wZhStatsSaved+9]
 sub $e0
 cp 10
 jr nc,.skip2_1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+800
 call .copyPair
.skip2_1
 ld a,[wZhStatsSaved+10]
 sub $e0
 cp 10
 jr nc,.skip2_2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+816
 call .copyPair
.skip2_2
 ld a,[wZhStatsFlags]
 bit 3,a
 jr z,.noMarker2
 ld hl,.Markers+32
 ld de,wZhStatsPixels+832
 call .copyPair
.noMarker2
 ld a,[wZhStatsSaved+12]
 sub $e0
 cp 10
 jr nc,.skip3_0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+880
 call .copyPair
.skip3_0
 ld a,[wZhStatsSaved+13]
 sub $e0
 cp 10
 jr nc,.skip3_1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+896
 call .copyPair
.skip3_1
 ld a,[wZhStatsSaved+14]
 sub $e0
 cp 10
 jr nc,.skip3_2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+320
 add hl,bc
 ld de,wZhStatsPixels+912
 call .copyPair
.skip3_2
 ld a,[wZhStatsFlags]
 bit 2,a
 jr z,.noMarker3
 ld hl,.Markers+32
 ld de,wZhStatsPixels+928
 call .copyPair
.noMarker3
 ld a,[wZhStatsSaved+16]
 sub $e0
 cp 10
 jr nc,.skip4_0
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+1168
 call .copyPair
.skip4_0
 ld a,[wZhStatsSaved+17]
 sub $e0
 cp 10
 jr nc,.skip4_1
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+1184
 call .copyPair
.skip4_1
 ld a,[wZhStatsSaved+18]
 sub $e0
 cp 10
 jr nc,.skip4_2
 ld l,a
 ld h,0
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 add hl,hl
 ld bc,.Digits+0
 add hl,bc
 ld de,wZhStatsPixels+1200
 call .copyPair
.skip4_2
 ld a,[wZhStatsFlags]
 bit 4,a
 jr z,.noMarker4
 ld hl,.Markers+0
 ld de,wZhStatsPixels+1216
 call .copyPair
.noMarker4
 ldh a,[rVBK]
 push af
 ld a,1
 ldh [rVBK],a
 ld hl,$8800
 ld de,wZhStatsPixels
 ld b,BANK(@)
 ld c,96
 call Get2bpp
 pop af
 ldh [rVBK],a
 pop af
 ldh [rWBK],a
 hlbgcoord 0,2,wSummaryScreenWindowBuffer
 ld [hl],128
 hlbgcoord 16,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,2,wSummaryScreenWindowBuffer
 ld [hl],129
 hlbgcoord 17,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,2,wSummaryScreenWindowBuffer
 ld [hl],130
 hlbgcoord 18,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,2,wSummaryScreenWindowBuffer
 ld [hl],131
 hlbgcoord 19,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,2,wSummaryScreenWindowBuffer
 ld [hl],132
 hlbgcoord 20,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,2,wSummaryScreenWindowBuffer
 ld [hl],133
 hlbgcoord 21,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,2,wSummaryScreenWindowBuffer
 ld [hl],134
 hlbgcoord 22,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,2,wSummaryScreenWindowBuffer
 ld [hl],135
 hlbgcoord 23,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,2,wSummaryScreenWindowBuffer
 ld [hl],136
 hlbgcoord 24,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,2,wSummaryScreenWindowBuffer
 ld [hl],137
 hlbgcoord 25,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,2,wSummaryScreenWindowBuffer
 ld [hl],138
 hlbgcoord 26,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,2,wSummaryScreenWindowBuffer
 ld [hl],139
 hlbgcoord 27,2,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,3,wSummaryScreenWindowBuffer
 ld [hl],140
 hlbgcoord 16,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,3,wSummaryScreenWindowBuffer
 ld [hl],141
 hlbgcoord 17,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,3,wSummaryScreenWindowBuffer
 ld [hl],142
 hlbgcoord 18,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,3,wSummaryScreenWindowBuffer
 ld [hl],143
 hlbgcoord 19,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,3,wSummaryScreenWindowBuffer
 ld [hl],144
 hlbgcoord 20,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,3,wSummaryScreenWindowBuffer
 ld [hl],145
 hlbgcoord 21,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,3,wSummaryScreenWindowBuffer
 ld [hl],146
 hlbgcoord 22,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,3,wSummaryScreenWindowBuffer
 ld [hl],147
 hlbgcoord 23,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,3,wSummaryScreenWindowBuffer
 ld [hl],148
 hlbgcoord 24,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,3,wSummaryScreenWindowBuffer
 ld [hl],149
 hlbgcoord 25,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,3,wSummaryScreenWindowBuffer
 ld [hl],150
 hlbgcoord 26,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,3,wSummaryScreenWindowBuffer
 ld [hl],151
 hlbgcoord 27,3,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,4,wSummaryScreenWindowBuffer
 ld [hl],152
 hlbgcoord 16,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,4,wSummaryScreenWindowBuffer
 ld [hl],153
 hlbgcoord 17,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,4,wSummaryScreenWindowBuffer
 ld [hl],154
 hlbgcoord 18,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,4,wSummaryScreenWindowBuffer
 ld [hl],155
 hlbgcoord 19,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,4,wSummaryScreenWindowBuffer
 ld [hl],156
 hlbgcoord 20,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,4,wSummaryScreenWindowBuffer
 ld [hl],157
 hlbgcoord 21,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,4,wSummaryScreenWindowBuffer
 ld [hl],158
 hlbgcoord 22,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,4,wSummaryScreenWindowBuffer
 ld [hl],159
 hlbgcoord 23,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,4,wSummaryScreenWindowBuffer
 ld [hl],160
 hlbgcoord 24,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,4,wSummaryScreenWindowBuffer
 ld [hl],161
 hlbgcoord 25,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,4,wSummaryScreenWindowBuffer
 ld [hl],162
 hlbgcoord 26,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,4,wSummaryScreenWindowBuffer
 ld [hl],163
 hlbgcoord 27,4,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,5,wSummaryScreenWindowBuffer
 ld [hl],164
 hlbgcoord 16,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,5,wSummaryScreenWindowBuffer
 ld [hl],165
 hlbgcoord 17,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,5,wSummaryScreenWindowBuffer
 ld [hl],166
 hlbgcoord 18,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,5,wSummaryScreenWindowBuffer
 ld [hl],167
 hlbgcoord 19,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,5,wSummaryScreenWindowBuffer
 ld [hl],168
 hlbgcoord 20,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,5,wSummaryScreenWindowBuffer
 ld [hl],169
 hlbgcoord 21,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,5,wSummaryScreenWindowBuffer
 ld [hl],170
 hlbgcoord 22,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,5,wSummaryScreenWindowBuffer
 ld [hl],171
 hlbgcoord 23,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,5,wSummaryScreenWindowBuffer
 ld [hl],172
 hlbgcoord 24,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,5,wSummaryScreenWindowBuffer
 ld [hl],173
 hlbgcoord 25,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,5,wSummaryScreenWindowBuffer
 ld [hl],174
 hlbgcoord 26,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,5,wSummaryScreenWindowBuffer
 ld [hl],175
 hlbgcoord 27,5,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,6,wSummaryScreenWindowBuffer
 ld [hl],176
 hlbgcoord 16,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,6,wSummaryScreenWindowBuffer
 ld [hl],177
 hlbgcoord 17,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,6,wSummaryScreenWindowBuffer
 ld [hl],178
 hlbgcoord 18,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,6,wSummaryScreenWindowBuffer
 ld [hl],179
 hlbgcoord 19,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,6,wSummaryScreenWindowBuffer
 ld [hl],180
 hlbgcoord 20,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,6,wSummaryScreenWindowBuffer
 ld [hl],181
 hlbgcoord 21,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,6,wSummaryScreenWindowBuffer
 ld [hl],182
 hlbgcoord 22,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,6,wSummaryScreenWindowBuffer
 ld [hl],183
 hlbgcoord 23,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,6,wSummaryScreenWindowBuffer
 ld [hl],184
 hlbgcoord 24,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,6,wSummaryScreenWindowBuffer
 ld [hl],185
 hlbgcoord 25,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,6,wSummaryScreenWindowBuffer
 ld [hl],186
 hlbgcoord 26,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,6,wSummaryScreenWindowBuffer
 ld [hl],187
 hlbgcoord 27,6,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,7,wSummaryScreenWindowBuffer
 ld [hl],188
 hlbgcoord 16,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,7,wSummaryScreenWindowBuffer
 ld [hl],189
 hlbgcoord 17,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,7,wSummaryScreenWindowBuffer
 ld [hl],190
 hlbgcoord 18,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,7,wSummaryScreenWindowBuffer
 ld [hl],191
 hlbgcoord 19,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,7,wSummaryScreenWindowBuffer
 ld [hl],192
 hlbgcoord 20,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,7,wSummaryScreenWindowBuffer
 ld [hl],193
 hlbgcoord 21,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,7,wSummaryScreenWindowBuffer
 ld [hl],194
 hlbgcoord 22,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,7,wSummaryScreenWindowBuffer
 ld [hl],195
 hlbgcoord 23,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,7,wSummaryScreenWindowBuffer
 ld [hl],196
 hlbgcoord 24,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,7,wSummaryScreenWindowBuffer
 ld [hl],197
 hlbgcoord 25,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,7,wSummaryScreenWindowBuffer
 ld [hl],198
 hlbgcoord 26,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,7,wSummaryScreenWindowBuffer
 ld [hl],199
 hlbgcoord 27,7,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,8,wSummaryScreenWindowBuffer
 ld [hl],200
 hlbgcoord 16,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,8,wSummaryScreenWindowBuffer
 ld [hl],201
 hlbgcoord 17,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,8,wSummaryScreenWindowBuffer
 ld [hl],202
 hlbgcoord 18,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,8,wSummaryScreenWindowBuffer
 ld [hl],203
 hlbgcoord 19,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,8,wSummaryScreenWindowBuffer
 ld [hl],204
 hlbgcoord 20,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,8,wSummaryScreenWindowBuffer
 ld [hl],205
 hlbgcoord 21,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,8,wSummaryScreenWindowBuffer
 ld [hl],206
 hlbgcoord 22,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,8,wSummaryScreenWindowBuffer
 ld [hl],207
 hlbgcoord 23,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,8,wSummaryScreenWindowBuffer
 ld [hl],208
 hlbgcoord 24,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,8,wSummaryScreenWindowBuffer
 ld [hl],209
 hlbgcoord 25,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,8,wSummaryScreenWindowBuffer
 ld [hl],210
 hlbgcoord 26,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,8,wSummaryScreenWindowBuffer
 ld [hl],211
 hlbgcoord 27,8,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 0,9,wSummaryScreenWindowBuffer
 ld [hl],212
 hlbgcoord 16,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 1,9,wSummaryScreenWindowBuffer
 ld [hl],213
 hlbgcoord 17,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 2,9,wSummaryScreenWindowBuffer
 ld [hl],214
 hlbgcoord 18,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 3,9,wSummaryScreenWindowBuffer
 ld [hl],215
 hlbgcoord 19,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 4,9,wSummaryScreenWindowBuffer
 ld [hl],216
 hlbgcoord 20,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 5,9,wSummaryScreenWindowBuffer
 ld [hl],217
 hlbgcoord 21,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 6,9,wSummaryScreenWindowBuffer
 ld [hl],218
 hlbgcoord 22,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 7,9,wSummaryScreenWindowBuffer
 ld [hl],219
 hlbgcoord 23,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 8,9,wSummaryScreenWindowBuffer
 ld [hl],220
 hlbgcoord 24,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 9,9,wSummaryScreenWindowBuffer
 ld [hl],221
 hlbgcoord 25,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 10,9,wSummaryScreenWindowBuffer
 ld [hl],222
 hlbgcoord 26,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 hlbgcoord 11,9,wSummaryScreenWindowBuffer
 ld [hl],223
 hlbgcoord 27,9,wSummaryScreenWindowBuffer
 ld [hl],8 | 2
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+3]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 23,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 24,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 25,3,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 23,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 24,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+7]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 25,4,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+11]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 23,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 24,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 25,6,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 23,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 24,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+15]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 25,7,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,8,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,8,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,8,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 17,9,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 18,9,wSummaryScreenWindowBuffer
 ld [hl],a
 ld a,[wZhStatsSaved+19]
 cp SUMMARY_PAL_SIDE_WINDOW
 jr nz,@+4
 ld a,2
 or 8
 hlbgcoord 19,9,wSummaryScreenWindowBuffer
 ld [hl],a
 ld hl,wSummaryScreenPals palette SUMMARY_PAL_SIDE_WINDOW
 ld de,wSummaryScreenPals palette 2
 ld bc,8
 rst CopyBytes
 ld hl,wSummaryScreenPals palette 2 color 1
 ld a,$ff
 ld [hli],a
 ld a,$7f
 ld [hl],a
 ld hl,wSummaryScreenPals palette 2 color 2
 xor a
 ld [hli],a
 ld [hl],a
 ld hl,wSummaryScreenPals palette SUMMARY_PAL_NATURE_UP color 2
 ld [hli],a
 ld [hl],a
 ld hl,wSummaryScreenPals palette SUMMARY_PAL_NATURE_DOWN color 2
 ld [hli],a
 ld [hl],a
 ld a,1
 ldh [rVBK],a
 ld hl,$8f00
 ld de,.WhiteGap
 ld b,BANK(.WhiteGap)
 ld c,1
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlbgcoord 0,10,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,$f0
 rst ByteFill
 hlbgcoord 16,10,wSummaryScreenWindowBuffer
 ld bc,12
 ld a,10
 rst ByteFill
 call ZhAbilityTitle
 ld a,1
 ldh [rVBK],a
 ld hl,$8ef0
 ld de,.Corner
 ld b,BANK(.Corner)
 ld c,1
 call Get2bpp
 xor a
 ldh [rVBK],a
 hlcoord 7,11
 ld [hl],$ef
 hlcoord 7,11,wAttrmap
 ld [hl],8 | SUMMARY_PAL_SIDE_WINDOW
 ret
.copyPair
 ld b,16
.first
 ld a,[de]
 or [hl]
 inc hl
 ld [de],a
 inc de
 dec b
 jr nz,.first
 push hl
 ld hl,176
 add hl,de
 ld d,h
 ld e,l
 pop hl
 ld b,16
.second
 ld a,[de]
 or [hl]
 inc hl
 ld [de],a
 inc de
 dec b
 jr nz,.second
 ret
.Panel:
 INCBIN "gfx/zh/summary_two_line.2bpp"
.Digits:
 INCBIN "gfx/zh/summary_shift_digits.2bpp"
.Markers:
 INCBIN "gfx/zh/summary_shift_marker.2bpp"

.Corner:
 INCBIN "gfx/zh/summary_corner.2bpp"

.WhiteGap:
 REPT 8
 db $ff,0
 ENDR
