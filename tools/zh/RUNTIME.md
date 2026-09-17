# Chinese runtime framework

English builds retain the original ROM layout. Chinese builds use a separate
4 MiB MBC30 image and the existing SRAM format. Build with runtime_build.py;
provide a local Fusion Pixel 12px TTF and its license directory.

The shared text dispatcher imports bounded dialogue spans without map-specific
hooks. It supports validated RAM names and continuation scrolling. Unsupported
controls or changed source hashes fail before insertion. Choice-menu retention
and Chinese player-name input remain outside this interface.

Battle display is independent of saved nicknames. Translated default names are
matched against the original 10-byte nickname, rasterized at build time, and
displayed in dedicated VRAM tiles. Custom nicknames retain legacy rendering.
Player names use up to five 12px glyphs at 11px advance on the same band as
level, gender and shiny; status is left of HP numbers. Enemy names retain a
separate metadata row. HP/EXP coordinates remain unchanged for the player.
Glyphs that exceed the compact advance are rejected instead of clipped.

The 2×2 move grid preserves the EXP row and uses a centered two-tile cursor.
When a move exceeds the cell width, the existing list is retained.

No translated CSV content, generated glyph images, ROMs, saves or screenshots
are shipped. Trial translations belong in a local copy before building.
Build-generated name tables are display data, never save-format changes.
