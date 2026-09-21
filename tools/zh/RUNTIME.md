# Chinese text framework

Chinese builds use the single LOCALE_ZH guard selected by --language.
Provide --font and --licenses to runtime_build.py; English builds retain
their original layout and do not require Chinese assets.

The retained framework includes 4x12 font strips, shared PlaceString output,
three bank policies, glyph caching and encoded window/temporary-map recovery.
Bounded dialogue and the battle move grid remain as current consumers.

The previous Summary, party-list, battle-name HUD and level-up adaptations
and their precomposed text generators have been removed. These screens use
the original game layouts while replacements are designed. Existing CSV
resources remain available, but those page translations are not imported
as generic dialogue. No ui-terms or page-specific build switches remain.

This is not a complete port of the reference DFS or an all-scene runtime
certification. Cache boundaries and future layout consumers still require
validation. No fonts, translations, ROMs or saves are distributed here.
