# Shared text layout

text_layout.py retains generic measurement, pixel flow, bounds checking and
tile encoding helpers for future layouts. cache_text.py compiles dialogue
and move strings into glyph-strip pairs.

The previous suite layout presets and page-specific text surfaces have been
removed. New Summary, party and HUD layouts must use the shared text and
cache framework rather than restore precomposed whole-text resources.
English retains the original layout; LOCALE_ZH remains the only language guard.
