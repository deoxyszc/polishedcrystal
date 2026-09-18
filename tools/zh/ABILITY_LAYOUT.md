# Summary ability translations

With `--summary-terms`, Chinese builds compile explicit translations from
`data/abilities/names.asm` and `data/abilities/descriptions.asm` CSV records.
The live summary ability ID selects the display; empty translations retain
the original name or description independently. Other ability consumers retain
the original path. No sample translations are included.

Names fit one 56px line. Descriptions fit two 112px lines, separated by
`{next}` and terminated by `{done}`. The current VRAM allocation reserves
these limits to avoid overwriting the Pokemon portrait and summary labels.
Oversized strings or unsupported controls fail at build time.

The renderer keeps the original ability-slot indicator, clears old text and
uses separate tile allocations for the name and description. The existing
summary page-switch reset restores the lower panel for other pages.

The alternate two-line stat layout is implemented when the live Hyper Training
flags are present. Values and nature colors come from the original formatted
summary data. No preview values are embedded in the runtime.
