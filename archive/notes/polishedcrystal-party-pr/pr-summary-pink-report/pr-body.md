## Result

Restore the Chinese pink summary page with live names, trainer information and experience values. Move the caught-ball icon above the trainer row and retain the confirmed metadata positions. Full-level display avoids the clipped next-level suffix.

Fix the summary-specific cache lifecycle: include its interleaved window buffer in liveness recovery, avoid ordinary tilemap uploads in the summary display pipeline, and transfer changed background attributes when switching pages. Preserve the native English font path inside summary. No new WRAM fields or enlarged VRAM cache are introduced.

Add a local pixel-layout editor using supplied screenshots and compiled glyph assets. Its ROM export uses the same constraints as the build compiler; JSON generates the summary ASM constants. Fixed elements and unsupported pixel offsets are rejected rather than silently rounded. This is a page-specific preview, not a general ROM renderer or a VRAM-allocation simulator.

## Verification

- SameBoy CPU cache fixture passes, including summary-window liveness marking.
- Actual-ROM ordinary page entry, pink/blue return and party return checked.
- Isolated stress fixture: Alolan Golem, five-character displayed nickname, 1,640,000 experience and level 100; repeated page returns checked. Chinese OT was a display-only fixture, not a save-format change.
- JSON-only coordinate change verified to move the ROM experience row by exactly 8 pixels.
- Editor drag/export/import tested; shared movement constraints tested.

Detailed malformed-input and all-game regression remain deferred by agreement. Long English OT names are not specially redesigned. Private ROMs, fonts, saves, screenshots and reports remain local and are not included.

Final clean builds passed: English SHA256 `469d08907d0ef474d174d87d84d25e108b86ca481131b41fa291bd8aae97c29b` (identical baseline); Chinese full local input (367 glyphs) SHA256 `05436ac62891d54e3354f72dbff6edd8e4d6d2e5e35510b40308d21203febc73`. Build reports and logs are retained locally.
