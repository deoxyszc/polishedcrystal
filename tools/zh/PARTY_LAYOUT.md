# Live party layout

Use `--party-layout` with a Chinese `runtime_build.py` build. Names come from
the selected CSV language and are matched against original default nicknames.
HP, level, gender, status, party size and eggs remain owned by the original game.
There is no external party-metadata input. The old `--party-preview-terms`
argument is rejected so a preview cannot accidentally become a gameplay build.

The ordinary party menu uses 12px translated names, separate per-slot VRAM
tiles, original HP numbers and level digits, and a four-tile HP bar rescaled
from the original HP calculation. Native battle status icons occupy the shiny slot while preserving gender.
Icon selection and color follow the current party status, including fainting. Cancel and the ordinary selection prompt use their explicit CSV translations,
with original text as fallback. Cancel is positioned after the actual party count;
its shared tiles preserve the last name and the selected original frame.
Other action prompts, frames and sprites retain their original behavior. Custom nicknames and untranslated names retain their original
layout. Eggs and non-default party actions retain the original rendering.

This is partial localization: translated names are currently used in battle
HUDs and the ordinary party list, not every name consumer. Special item, TM,
trade and battle-tower menu layouts are deliberately left on the original path.
English builds reject Chinese layout options and require no Chinese resources.

The historical `party_preview.py` module and template are development helpers
only; the gameplay builder never calls them. Do not distribute their generated
ROMs as playable localized builds.
