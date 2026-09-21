# Shared text layout

suite_layout.py selects the Chinese suite at build time from --language.
Summary, party and battle name generators consume its region dimensions,
baselines, spacing and width limits. The same configuration generates assembly
geometry constants consumed by the corresponding upload and map routines.
Simplified and traditional Chinese share
geometry; English retains its native layout. The build writes layout.json
beside its report for inspection; no runtime layout selector is emitted.
The configuration does not certify VRAM ranges or complete cache migration.

Asset generators use text_layout.py for font advances, inline pixel flow,
line baselines, bounds checks and 2bpp encoding. Containers default to a 12px
baseline and 16px line step. append() continues at the preceding text's pixel
end; newline() resets the horizontal cursor. Encode the complete surface after
all text is drawn, including content sharing an 8px tile row.

Reuse the default style before adding an override. Existing constrained regions
retain their geometry: summary names use baseline 10, descriptions use 13px
steps, and battle/party names use validated 11px advances. Orange side panels,
the party cancel row and the stat grid retain their container anchors. These
are local constraints, not independent language switches.

The suite compiles text surfaces into shared 8x16 cache blocks. PlaceString
publishes the allocated IDs to the main map or Summary window buffer. Page
adapters retain live numbers, native digit graphics and original source IDs.

Dialogue compiles fixed runs into strip pairs for the shared PlaceString cache.
Dynamic names remain runtime data. Dense summary surfaces and 11px name layouts
use build-composed blocks; final line spacing and overlap review is deferred.
