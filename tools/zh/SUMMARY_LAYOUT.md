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
