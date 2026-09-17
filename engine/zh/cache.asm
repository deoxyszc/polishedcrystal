; Scene-scoped two-line VRAM lease. Caller selects state WRAM bank.
; Only acquire after verifying scene bank1 tiles $30..$77 are exclusively free.
; These are NOT free in overworld maps. State is transient, never save data.
; All calls preserve BC/DE/HL, clobber AF. Carry set = refused/no mutation.
ZhLeaseAcquire::
 ld a, [wZhLeaseActive]
 and a
 jr nz, ZhLeaseError
 xor a
 ld [wZhSuspended], a
 ld [wZhLeasePins], a
 ld [wZhLeaseValidMask], a
 inc a
 ld [wZhLeaseActive], a
 and a
 ret

ZhLeasePin::
 ld a, [wZhLeaseActive]
 and a
 jr z, ZhLeaseError
 ld a, [wZhLeasePins]
 cp $ff
 jr z, ZhLeaseError
 inc a
 ld [wZhLeasePins], a
 and a
 ret

ZhLeaseUnpin::
 ld a, [wZhLeasePins]
 and a
 jr z, ZhLeaseError
 dec a
 ld [wZhLeasePins], a
 and a
 ret

; Check before ANY VRAM upload, buffer/page reuse or release.
ZhLeaseWritable::
 ld a, [wZhLeaseActive]
 and a
 jr z, ZhLeaseError
 ld a, [wZhLeasePins]
 and a
 jr nz, ZhLeaseError
 ret

; Caller has removed the old page tilemap before reusing its tile pixels.
ZhLeaseClearPage::
 call ZhLeaseWritable
 ret c
 xor a
 ld [wZhLeaseValidMask], a
 jp ZhHidePage

; Hide the full fixed textbox interior including configured margins.
; This deliberately clears prior layout pixels too, not just current width.
; Layout only moves glyphs inside this fixed 18x4-tile safe area.
ZhHidePage::
 push bc
 push hl
 hlcoord 1, 13
 ld b, 4
.row
 ld c, 18
 ld a, $7f
.tile
 ld [hli], a
 dec c
 jr nz, .tile
 inc hl
 inc hl
 dec b
 jr nz, .row
 hlcoord 1, 13, wAttrmap
 ld b, 4
.attrrow
 ld c, 18
 ld a, 7
.attr
 ld [hli], a
 dec c
 jr nz, .attr
 inc hl
 inc hl
 dec b
 jr nz, .attrrow
 pop hl
 pop bc
 and a
 ret

; Call only after all windows/pages referencing the lease have been removed.
ZhLeaseRelease::
 call ZhLeaseWritable
 ret c
 xor a
 ld [wZhLeaseActive], a
 ld [wZhLeaseValidMask], a
 ret

ZhLeaseError:
 scf
 ret

; Emergency top-level owner teardown ONLY after every menu has closed.
; Not a normal release: caller proves no surviving tile references first,
; then applies hidden map and reloads English font before returning to game.
; Preserves BC/DE/HL. Never call from an arbitrary nested menu/error callback.
ZhLeaseAbort::
 xor a
 ld [wZhLeasePins], a
 ld [wZhSuspended], a
 ld [wZhLeaseValidMask], a
 ld [wZhLeaseActive], a
 jp ZhHidePage
