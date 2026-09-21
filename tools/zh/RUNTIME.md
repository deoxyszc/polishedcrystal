# Chinese runtime framework

English builds retain the original ROM layout. Chinese builds use a separate
4 MiB MBC30 image and the existing SRAM format. Build with runtime_build.py;
provide a local Fusion Pixel 12px TTF and its license directory.

The shared text dispatcher imports bounded dialogue spans without map-specific
hooks. It supports validated RAM names and continuation scrolling. Unsupported
controls or changed source hashes fail before insertion. Window and temporary
map backups retain strip keys and rebuild cached references on restoration.
Chinese player-name input remains outside this interface.

Fixed dialogue and battle move names compile to paired 4px strips consumed by
PlaceString. Uploads complete before tile/attribute publication. Standard font
reloads invalidate cache mappings. The former two-line lease and full-line
uploader have been removed. Summary, party and HUD text consumers now use the
same cache through PlaceString. Build-composed 8x16 blocks retain nonstandard
baselines and compact name spacing; their ROM address is a recoverable cache
key, not a fixed VRAM destination. This does not establish final layout or
all-scene capacity validation.

Battle display is independent of saved nicknames. Translated default names are
matched against the original 10-byte nickname, rasterized at build time, and
displayed through the shared cache. Custom nicknames retain legacy rendering.
Player names use up to five 12px glyphs at 11px advance, with gender and
level on the same band; status is left of HP numbers. Shiny indicators retain
the original HP palette and sit left of each HP bar. Enemy names expand left
as their rendered width increases. Short names are followed by gender and
level; the widest names move gender above the level. Enemy status replaces
level without covering the name, and the caught indicator occupies the left
margin. Text and palette placement share the same geometry. HP/EXP coordinates remain unchanged for the player.
Glyphs that exceed the compact advance are rejected instead of clipped.

The 2×2 move grid preserves the EXP row and uses a centered two-tile cursor.
When a move exceeds the cell width, the existing list is retained.

No translated CSV content, generated glyph images, ROMs, saves or screenshots
are shipped. Trial translations belong in a local copy before building.
Build-generated name tables are display data, never save-format changes.

All Chinese runtime modules use the single LOCALE_ZH build guard selected by
--language. No per-page layout switches are required. Chinese builds require
--font, --licenses and --ui-terms; the terms file supplies UI strings only.
Generated resource-presence constants select translated versus original text
when an optional translation is absent; they do not select a build variant.

The pink summary reuses the CSV experience and next-level labels inline with
live numbers. These two labels must fit 24px. Supply `level_suffix` in the UI
terms JSON for the suffix after the live next level (up to 16px). The inline
panel requires all three CSV labels and this suffix; otherwise it retains
the original experience panel. Maximum-level calculation remains unchanged.

Orange summary nature and characteristic translations follow the original
table indices and require both translated headings and selected entries.
Encounter text uses the selected time/location CSV records and UI terms
`encounter`, `met_location` (one `{location}` placeholder), `met_level_prefix`,
and `level_suffix`. Missing resources, rental, egg-origin, trade-origin,
event, and unknown-location records retain the original encounter text.
