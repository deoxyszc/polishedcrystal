# Shared text layout

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

engine/zh/layout_macros.asm shares summary tab placement without runtime
dispatch or extra RAM. Shared-asset uploads derive the ROM bank from the asset
symbol and preserve VRAM bank selection. Page adapters retain original live
numbers, original digit graphics, source IDs and translation fallbacks.

The dialogue renderer is unchanged. Fragment storage, runtime caches and partial
VRAM uploads can be evaluated separately after measuring actual scenes.
