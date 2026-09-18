# Summary move list and held-item panel

Chinese builds with `--summary-terms` generate move-list names from the selected
CSV language. The list reads the current move IDs and the original formatted
current/max PP; original type graphics follow the actual moves. The reviewed
layout uses 19px row spacing and raises PP below each type label. The original
bottom border and A-info prompt remain visible.

Currently all occupied slots need translated names of at most 64px to activate
the alternate list. If a slot has no translation, the native list is retained.
This is a list-rendering change, not localized move-detail support. Navigation,
reordering and repeated page transitions still require broader regression
testing before calling the full summary workflow validated.

Held-item names and descriptions are independently selected by live item ID
from source-ordered translation tables. Missing translations retain their
native field. Names fit 144px; descriptions allow two 144px lines using `{next}`
and ending in `{done}`. Asset pointers include banks so translated items need
not all fit one ROM bank. Unsupported controls and source drift fail the build.
An optional `item` entry in summary terms translates the tab heading.

Ability and item panels share text baseline and line-spacing constants. The
item page restores its own palette after the stat page; translated descriptions
disable the native mid-text raster scroll that clips 12px glyphs.

Local ROM checks covered four translated moves with live PP/type data, original
bottom-border comparison, no item, two translated items, untranslated fallback
and the original item-icon palette. Test translations, saves, images and ROMs
are not part of the toolchain. Final clean-build and broader scenario regression
are not implied by those targeted checks.
