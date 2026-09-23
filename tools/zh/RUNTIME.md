# Chinese text framework

Chinese builds use the single LOCALE_ZH guard selected by --language.
Provide --font and --licenses to runtime_build.py; English builds retain
their original layout and do not require Chinese assets.

The retained framework includes 4x12 font strips, shared PlaceString output,
three bank policies, glyph caching and encoded window/temporary-map recovery.
Bounded dialogue and the battle move grid remain as current consumers.

The previous Summary, battle-name HUD and level-up adaptations
and their precomposed text generators have been removed. These screens use
the original game layouts while replacements are designed. Existing CSV
resources remain available, but those page translations are not imported
as generic dialogue. No ui-terms or page-specific build switches remain.

This is not a complete port of the reference DFS or an all-scene runtime
certification. Cache boundaries and future layout consumers still require
validation. No fonts, translations, ROMs or saves are distributed here.

## Compile-time consumer layouts

Edit tools/zh/layouts.py: dialogue and move_list are independent configurations.
The build emits region constants and positions each individual 4px font strip
in a 16px cell. Chinese glyphs keep 12px width; original Latin letters and
numbers keep 8px width. There are no precomposed words, sentences or panels.
Identical strip pixels share an ID; different placement produces different
IDs, so cache/window restoration needs no runtime layout or style state.
Dynamic dialogue names index a precompiled Latin strip table.

The imported font remains three 4x12 strips (18 bytes per glyph). The cache
uses generated, deduplicated 4x16 color strips (16 bytes each); this adds ROM data
in exchange for removing runtime font alignment and original-font decoding.
The runtime only looks up strip pixels, combines pairs and manages VRAM.
Dialogue geometry does not configure the battle move grid or other pages.

The overworld Start menu has its own start_menu layout and CSV label
compiler. Original availability, ordering, cursor and actions are retained;
the player entry reads the real save name. Missing labels compile original
English through the same strip cache, including the original PO/KE tiles.
Other menus (title, yes/no, inventory and submenus) are not adapted by this
consumer. Bug-contest status text and menu return paths need separate review.

Ordinary party-list translated default names now use shared PlaceString
with a compile-time leading 4px strip. Custom names, eggs and other party
actions keep their legacy paths. Cancel/prompt use their own region.
HP values remain formatted by the original PrintNum path; per-cell digit
and original bar-tile combinations are selected from a compiled key table
for the 2px numeric offset. No whole-line bitmaps are generated.
The shared strip decoder now preserves two color planes; this affects all
consumers. Full navigation, mixed fallback and cache-capacity cases still
require validation. The party scene borrows both candidate cache banks.

One through four CJK characters select the 48px HP bar at build time;
five characters retain the 32px bar. All translated names start at x20.
Level output is right-aligned next to the bar, with a compact L and no colon.
At level 100 the L is omitted; the four-character shared cell preserves the
reviewed small overlap between the last glyph and the digit 1. Shared-cell
variants are compiled as individual strips, not whole strings.
Layout choice is currently per member, not the longest name in the party.

Original one-byte PlaceString input now uses one-cell cached Latin glyphs
with font-sensitive tagged keys ($f800..$fbff). It preserves original 8x8
geometry, controls, string endpoints and the cell below. Static symbols and
numerals outside the cache pool still use their original bank0 tiles.
This does not cover arbitrary direct tile writes bypassing PlaceString, and
is independent of the window-stack record format.

Window-stack records now reserve attribute bit4 as a private storage tag.
Static cells occupy two bytes; dynamic cache cells append four key bytes.
The incoming bit4 is cleared before tagging and removed on restore. The
preflight scans the same rectangle with the same record classifier to measure
actual size before copying cells. Temporary-map sidecars keep their existing
fixed format. No additional WRAM bank is borrowed by this change.
