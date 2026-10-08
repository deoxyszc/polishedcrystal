# Saves, scene replay and localization regression

## Save checkpoints

For this Polished Crystal project, create/progress baseline saves using the
original English ROM. Load copies for Chinese builds. Ordinary battery .sav
files are organized by game progress, not ROM language; emulator save states
are ROM/core-version sensitive. Reference Chinese Crystal is a different game:
its saves are not Polished saves.

When the user reports saving, identify the active ROM's sibling .sav, check its
mtime/hash changed, then copy to a timestamped checkpoint plus a read-only cold
copy. Verify identical bytes and record source, SHA256 and checkpoint purpose.
Never overwrite a known checkpoint or run a cold copy directly. Same-disk cold
copies prevent accidental overwrites, not disk loss. /private/tmp must not be
the only copy. Keep ROM cold backup separate from save identity.

Place checkpoints before the target UI/event: e.g. inside Mr. Pokémon's house
before exiting into the phone call, or before the rival trigger. Avoid redundant
post-event saves unless they provide a separate useful test entry.

A filename is not proof of map/progress. Verify loaded scene and, when needed,
read event flags using that ROM's matching symbols. Do not blindly walk a route
when a one-time trigger may already be completed. Do not rewrite flags to call
an artificial state a genuine checkpoint.

## Replay vs live handoff

Use a save-hash-bound input sequence with explicit frame counts for deterministic
core replay. Record ROM/runner/save fingerprints, command log and checkpoint
screenshots. A completed process does not certify arrival at the scene. Recheck
boot/Continue transitions after renderer changes: text timing has changed enough
to invalidate earlier fixed inputs. Do not run exploratory direction loops as
if they were a validated route. Keep original saves unchanged.

A command-line core replay is not control of the live SameBoy app. For live
handoff, verify the ROM window, focus the game image, send Start, and inspect the
result. Short GUI taps may be missed. If repeated keys do not change the expected
state, diagnose focus/timing instead of continuing blind inputs. Do not claim
“loaded save” while still at the title. Stop sending inputs after user takeover.
Do not replace a running ROM/save underneath the app.

Existing local helpers (inspect before use):
- /Users/zhaoc/source/polishedcrystal-party-pr/local-data/scenes/scenes.py and routes.json: save-bound
  loaded/Start/party routes calibrated to particular builds, not universal timing.
- same directory, sameboy-focus-start.js: GUI snippet, not a verified automatic
  boot/Continue solution. Use through the available computer-use interface only.
- saves/, backups/, cold-backup/: stable local checkpoint storage; not public assets.

## What verification proves

- Pair every Chinese page screenshot with the same-scene English full screen.
  Inspect portraits, icons, borders, colors, numerals and clipping, not just text.
- Mark static overlays as mockups. They omit sprite priority and can hide crop
  errors; they cannot substitute for actual ROM output.
- Distinguish build success, synthetic CPU logic, real VRAM upload (LCD off/on),
  actual page display, and navigation restoration. Stubbed upload/wait functions
  do not test LCD timing. Empty-translation builds do not certify fallback playability.
- For a crash, reproduce old/new with the same save and action path; record exact
  error and active ROM hash. Test opening a save confirmation without actually
  saving unless saving is requested.
- Capture actual stack pointer/depth/encoded record sizes for memory claims;
  a measured route is not a worst-case bound. Distinguish VRAM glyph cache,
  WRAM window backup and ROM font assets.
- Match ROM/.sym/.map; compute current hashes instead of trusting old report.json.
  “Final” directory names and previous screenshots do not identify current code.

The user retains broader page-operation regression unless newly authorized.
Loading this skill does not expand test scope or authorize publishing/delegation.

Project state: /Users/zhaoc/source/polishedcrystal-party-pr/local-docs/新会话交接.md.
Issue/solution reference: same directory, 汉化问题与解决记录.md. Read as needed;
do not copy volatile PR numbers, cache sizes or page completion into this skill.
