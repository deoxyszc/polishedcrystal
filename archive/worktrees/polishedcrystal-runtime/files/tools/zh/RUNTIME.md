# Modular Chinese runtime

The runtime separates bounded decoding, glyph-page lookup, 12px composition,
VRAM page ownership, display upload, dialogue controls and fixed name sources.
`ZhShowDialogue` is the public entry for an already-open standard textbox, with
HL/DE identifying an exclusive bounded span in the runtime bank. It restores the
standard font and WRAM bank before returning. Other consumers are not admitted.

Build English in a fresh directory:

```bash
python3 tools/zh/runtime_build.py --language en --out ../build-en
```

Build with a local Fusion Pixel 12px font and its supplied license directory:

```bash
python3 tools/zh/runtime_build.py --language zh-Hans --font /path/to/fusion-pixel-12px-monospaced-zh_hans.ttf --licenses /path/to/licenses --out ../build-zh
```

Install dependencies from `data/zh/font/requirements-ttf.txt` in a virtual environment.
The builder generates a font manifest from non-ASCII characters in the selected CSV
language plus `--characters` (default: 中文测试). Glyph count and bank pages are
generated together. Glyph IDs are build-local: encoded content must use that same
manifest. Imported fonts and generated bitmap pages are not committed.

The importer now preserves original labels and event references. It replaces
complete supported text spans with a descriptor, consumed by the shared
DoTextUntilTerminator entry. A ROMX dispatcher reads that descriptor from the
original bank, invokes the Chinese renderer and returns to the original caller.
No map-specific IDs or per-record script hooks are required. A previously unknown
file and label are covered by an automated regression test.

Supported shapes currently begin with text/ctxt, contain text/line/para and end
with done. PLAYER is supported within literals. Unsupported controls, fixed
tables and mixed spans are rejected before insertion. This is the first shared
dialogue entry, not a universal menu/name renderer. The current renderer consumes
its final wait and clears its page before returning; retaining text under an
external choice menu is not yet supported.

The English baseline was verified byte-identical. Chinese builds use a 4 MiB
MBC30 image with RTC and unchanged 32 KiB SRAM. The three supported scenes were
verified in SameBoy: Chinese text, dynamic English player name, two-page dialogue
and window restoration. Text is offset 2px inside each row; 8px Latin glyphs use
an additional 4px offset within the 12px cell.

Menu, battle, scrolling continuation and Chinese name entry are not supported.
Player/rival names remain validated English buffers. Existing saves can cache
map objects: exit and re-enter a map to refresh its event pointers. This is not
a claim of general cross-version save compatibility.
