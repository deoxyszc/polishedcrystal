# Opt-in summary and level-up layout

Pass --summary-terms /local/terms.json with a Chinese runtime build to enable
the reviewed layout. Without this option the existing UI remains unchanged.
The JSON keys are hp, attack, defense, special_attack, special_defense, speed
and ability. Labels must fit24px at12px font size. Keep hp as HP consistently.
No terminology translations or generated graphics are shipped in this PR.

The layout includes two-column stats, nature colors, compact numeric spacing,
a12px ability tab, and six-row level-up panels with aligned numeric glyphs.
Page switches restore lower-panel attributes and tab geometry.

This is opt-in because three-digit spacing and Hyper Training marker placement
remain unvalidated, as explicitly deferred during review. Moves and other
summary pages retain their current layout. The local Torrent translation and
its raster test routine are excluded; ability names/descriptions retain the
existing rendering path. No save-format changes.

## Approved visual target (runtime integration pending)

The next summary layout should retain the existing horizontal arrangement when
no Hyper Training marker is present. When markers require the alternate layout,
use three rows of two cells: each cell places its label above its value and
optional original Hyper Training icon. Use 20px row spacing and place the first
label at screen y=34, leaving the original HP bar intact. Keep the original
digit shapes and 8px advance, right-align values within their cells, and preserve
nature colors. Unmarked values leave the marker position blank.

Ability names and descriptions should use the selected translation resources,
with 12px text and a two-line description within the existing lower panel.
Preserve its frame and original ability-slot indicator. Do not embed example
translations or sample stat values in the generator or runtime.

These targets have been reviewed as image mockups only. The visual matrix
covered one-, two- and three-digit values, individual and mixed markers, all
999 values, and neutral/nature colors. It does not establish runtime support.
The current code still uses the earlier summary layout and original ability
text path. Implement live-data rendering, marker placement, translation import
and page-switch restoration before claiming these targets are available in
generated ROMs.
