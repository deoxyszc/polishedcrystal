# Party layout preview

Add `--party-preview-terms /path/to/terms.json` to a Chinese
`tools/zh/runtime_build.py` build to reproduce the reviewed six-member layout.
The JSON requires nonempty `name`, `cancel`, and `prompt` strings plus a `rows`
array of exactly six objects. Each row must explicitly supply `hp` (0–999),
`max_hp` (1–999 and at least hp), `level` (1–100), `gender` (male, female, none),
`shiny` (boolean), and `status` (none, poison, paralysis, sleep, burn, freeze).
No row, value or sample configuration is supplied by the tool. Older three-key
inputs are rejected rather than silently filling in fixture values.
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

This is an external-input layout preview, not a live party-data renderer.
All six names use the explicitly supplied name; each row uses the caller's
metadata. HP bar length follows the supplied HP ratio. Status occupies the
shiny slot when present. Inputs are validated before staged files are changed.
No party data or save formats are changed. Live names, HP, gender, status and
action-specific prompts still require a runtime adapter. Cursor/menu transitions
follow the original game. Do not use preview ROMs for gameplay.
The option is off by default; normal builds do not install these hooks.

The reviewed local visual test covered the full six-member screen and the
cancel/name overlap fix. Other frames, font metrics, party sizes, swapping,
item/TM prompts, eggs and live-data rendering require separate integration
and validation. Existing sprite and frame artwork is not edited.
