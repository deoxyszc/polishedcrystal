# Chinese summary and level-up layout

Chinese runtime builds include this layout through LOCALE_ZH. Supply terminology
with --ui-terms /local/terms.json; this is a resource input, not a layout switch.
The JSON keys are hp, attack, defense, special_attack, special_defense, speed
and ability. Labels must fit24px at12px font size. Keep hp as HP consistently.
No terminology translations or generated graphics are shipped in this PR.

The layout includes two-column stats, nature colors, compact numeric spacing,
a12px ability tab, and six-row level-up panels with aligned numeric glyphs.
Page switches restore lower-panel attributes and tab geometry.

With live Hyper Training flags present, the runtime switches to three rows of
two cells with 20px spacing: label above, original-width numeric value and
original marker below. Without flags, the existing horizontal layout remains.
Original formatted values and nature colors are preserved. The HP bar and
ability-slot indicator retain the original game data. No save-format changes.

Explicit CSV ability translations are supported as described in ABILITY_LAYOUT.md.
No sample translations, stat values, generated tiles or ROMs are shipped.

The marked three-digit layout and translated ability panel were verified in a
local ROM after resolving tile-allocation conflicts with the portrait. Border,
ability-name and description regions were compared against the reviewed visual
target. The full one/two/three-digit and mixed-marker matrix was previously
reviewed as mockups; comprehensive runtime matrix and final clean-build
regression remain pending. Do not treat visual approval as full playability
certification.
