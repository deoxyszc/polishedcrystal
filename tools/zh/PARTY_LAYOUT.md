# Party layout preview

Add `--party-preview-terms /path/to/terms.json` to a Chinese
`tools/zh/runtime_build.py` build to reproduce the reviewed six-member layout.
The JSON must contain three nonempty strings: `name`, `cancel`, and `prompt`.
Supply your own font and terminology; no translations, font files, screenshots,
ROMs or generated graphics are included. Pillow and the normal ROM build tools
are required, as with the other Chinese asset generators.

The preview retains six rows at the original 16px spacing. Names use 12px
glyphs with an 11px advance in a 56px area (up to five glyphs). The right side
contains gender/status, three-digit HP fields, level, and the original HP bar
renderer with four interior tiles. Status icons reuse the original battle
graphics with paired palette colors. The footer uses the original textbox
routine; the cancel label preserves both the sixth name's shared tile and
the original frame-1 top-border pixels. Cancel and prompt labels are limited
to 24px and 144px respectively. Use frame 1 for this preview.

This is explicitly a **visual stress fixture**: all six displayed names use
the supplied sample, HP is 999/999, level is 100, gender is male, and the five
status examples are fixed. It does not change party data or save formats and
does not implement dynamic names, HP, gender, status, or action-specific
prompts. Cursor/menu transitions still follow the original game. Do not use
the preview ROM for gameplay or describe it as a completed live party menu.
The option is off by default; normal builds do not install these hooks.

The reviewed local visual test covered the full six-member screen and the
cancel/name overlap fix. Other frames, font metrics, party sizes, swapping,
item/TM prompts, eggs and live-data rendering require separate integration
and validation. Existing sprite and frame artwork is not edited.
