; Caller selects BANK(wZhCacheKeys). All policies are fixed at build time.
; Reset at a scene boundary after ending all old physical references.
; A=root policy. Preserve BC/DE/HL; invalid policy leaves state unchanged.
ZhGlyphCacheInit::
 cp ZH_VRAM_BOTH + 1
 jr nc, ZhVramPolicyError
 and a
 jr z, ZhVramPolicyError
 ld [wZhPolicy], a
 xor a
 ld [wZhPolicyDepth], a
 jp ZhGlyphCacheClear

; Public policy calls preserve BC/DE/HL; carry = refused without mutation.
ZhVramPolicyPush::
 cp ZH_VRAM_BOTH + 1
 jr nc, ZhVramPolicyError
 and a
 jr z, ZhVramPolicyError
 push hl
 push bc
 ld b, a
 ld a, [wZhPolicyDepth]
 cp ZH_VRAM_POLICY_DEPTH
 jr nc, .full
 ld c, a
 inc a
 ld [wZhPolicyDepth], a
 ld a, c
 ld hl, wZhPolicyStack
 add l
 ld l, a
 jr nc, .address
 inc h
.address
 ld a, [wZhPolicy]
 ld [hl], a
 ld a, b
 ld [wZhPolicy], a
 pop bc
 pop hl
 and a
 ret
.full
 pop bc
 pop hl
ZhVramPolicyError:
 scf
 ret
ZhVramPolicyPop::
 ld a, [wZhPolicyDepth]
 and a
 jr z, ZhVramPolicyError
 dec a
 ld [wZhPolicyDepth], a
 push hl
 ld hl, wZhPolicyStack
 add l
 ld l, a
 jr nc, .address
 inc h
.address
 ld a, [hl]
 ld [wZhPolicy], a
 pop hl
 and a
 ret

; Clear mappings only. Caller has ended/rebuilt old tile references.
; Policy stack is deliberately unchanged.
ZhGlyphCacheClear::
 push hl
 push bc
 ld hl, wZhCacheKeys
 ld bc, ZH_CACHE_BLOCKS * ZH_CACHE_KEY_SIZE
 ld a, $ff
 rst ByteFill
 ld hl, wZhCacheUsed
 ld bc, ZH_CACHE_BLOCKS
 xor a
 rst ByteFill
 pop bc
 pop hl
 ret

; A=bank (0/1), C=tile. Return slot index in A, carry on non-pool tile.
; BC/HL preserved. Both upper and lower tile resolve to the same block.
ZhCacheTileSlot::
 cp 2
 jr nc, .invalid
 push bc
 ld b, a
 ld a, c
 sub ZH_CACHE_FIRST_TILE
 jr c, .bad
 cp ZH_CACHE_END_TILE - ZH_CACHE_FIRST_TILE
 jr nc, .bad
 srl a
 bit 0, b
 jr z, .done
 add ZH_CACHE_BLOCKS_PER_BANK
.done
 pop bc
 and a
 ret
.bad
 pop bc
.invalid
 scf
 ret

; Rebuild liveness from the current WRAM picture. Encoded window backups
; are restored by key, not pinned physical IDs. Does not reclaim engine GFX.
ZhGlyphCacheRecover::
 push bc
 push de
 push hl
 ld hl, wZhCacheUsed
 ld bc, ZH_CACHE_BLOCKS
 xor a
 rst ByteFill
 ld hl, wTilemap
 ld de, wAttrmap
 ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
.scan
 push bc
 ld c, [hl]
 ld a, [de]
 and BG_BANK1
 rrca
 rrca
 rrca
 call ZhCacheTileSlot
 jr c, .next
 push hl
 ld hl, wZhCacheUsed
 add l
 ld l, a
 jr nc, .mark
 inc h
.mark
 ld [hl], 1
 pop hl
.next
 pop bc
 inc hl
 inc de
 dec bc
 ld a, b
 or c
 jr nz, .scan
 call ZhMarkSummaryCache
 pop hl
 pop de
 pop bc
 ret

; BC/DE=4-byte combination key. Return A=slot, carry on miss.
; Search only currently allowed banks; preserve input key and HL.
ZhGlyphCacheFind::
 ld a, b
 and c
 and d
 and e
 inc a ; only the all-empty key is reserved; left padding is valid
 jr z, .invalid
 push hl
 push bc
 push de
 ld hl, wZhCacheKeys
 xor a
.slot
 push af
 cp ZH_CACHE_BLOCKS_PER_BANK
 ld a, ZH_VRAM_BANK0_ONLY
 jr c, .policy
 ld a, ZH_VRAM_BANK1_ONLY
.policy
 push hl
 ld hl, wZhPolicy
 and [hl]
 pop hl
 jr z, .skip4
 ld a, [hli]
 cp b
 jr nz, .skip3
 ld a, [hli]
 cp c
 jr nz, .skip2
 ld a, [hli]
 cp d
 jr nz, .skip1
 ld a, [hl]
 cp e
 jr nz, .skip1
 pop af
 push af
 ld hl, wZhCacheUsed
 add l
 ld l, a
 jr nc, .mark
 inc h
.mark
 ld [hl], 1
 pop af
 pop de
 pop bc
 pop hl
 and a
 ret
.skip4
 inc hl
.skip3
 inc hl
.skip2
 inc hl
.skip1
 inc hl
 pop af
 inc a
 cp ZH_CACHE_BLOCKS
 jr c, .slot
 pop de
 pop bc
 pop hl
.invalid
 scf
 ret

; BC/DE=key. Reserve unused slot and store key. Caller uploads before publish.
; Carry on full; never silently overwrite a live slot. Preserves BC/DE/HL.
ZhGlyphCacheAlloc::
 ld a, b
 and c
 and d
 and e
 inc a
 jr z, .invalid
 push hl
 push bc
 push de
 ld hl, wZhCacheUsed
 xor a
.slot
 push af
 ; Static NA dash may be referenced after the initial scene scan.
 cp (CHARVAL("-") - ZH_CACHE_FIRST_TILE) / 2
 jr z, .next
 cp ZH_CACHE_BLOCKS_PER_BANK
 ld a, ZH_VRAM_BANK0_ONLY
 jr c, .policy
 ld a, ZH_VRAM_BANK1_ONLY
.policy
 push hl
 ld hl, wZhPolicy
 and [hl]
 pop hl
 jr z, .next
 bit 0, [hl]
 jr nz, .next
 ld [hl], 1
 pop af
 push af
 ld l, a
 ld h, 0
 add hl, hl
 add hl, hl
 push de
 ld de, wZhCacheKeys
 add hl, de
 pop de
 ld [hl], b
 inc hl
 ld [hl], c
 inc hl
 ld [hl], d
 inc hl
 ld [hl], e
 pop af
 pop de
 pop bc
 pop hl
 and a
 ret
.next
 inc hl
 pop af
 inc a
 cp ZH_CACHE_BLOCKS
 jr c, .slot
 pop de
 pop bc
 pop hl
.invalid
 scf
 ret

; Find, then reserve, then recover and retry exactly once.
; A=slot, carry=failure. BC/DE key and HL preserved.
; Caller must complete pending display updates before invoking recovery.
ZhGlyphCacheResolve::
 call ZhGlyphCacheFind
 ret nc
 call ZhGlyphCacheAlloc
 ret nc
 call ZhGlyphCacheRecover
 jp ZhGlyphCacheAlloc

; A=slot -> A=tile ID, B=VRAM bank. Carry rejects invalid slots.
ZhGlyphCacheLocation::
 cp ZH_CACHE_BLOCKS
 jr nc, .bad
 ld b, 0
 cp ZH_CACHE_BLOCKS_PER_BANK
 jr c, .tile
 sub ZH_CACHE_BLOCKS_PER_BANK
 inc b
.tile
 add a
 add ZH_CACHE_FIRST_TILE
 and a
 ret
.bad
 scf
 ret

; A=slot -> BC/DE=combination key. Encoded backup must retain tile half
; and palette separately. Never store the physical slot as the backup key.
ZhGlyphCacheReadKey::
 cp ZH_CACHE_BLOCKS
 jr nc, .bad
 push hl
 ld l, a
 ld h, 0
 add hl, hl
 add hl, hl
 ld de, wZhCacheKeys
 add hl, de
 ld b, [hl]
 inc hl
 ld c, [hl]
 inc hl
 ld d, [hl]
 inc hl
 ld e, [hl]
 pop hl
 and a
 ret
.bad
 scf
 ret
