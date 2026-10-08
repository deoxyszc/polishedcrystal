Stable character streams replace the pre-expanded 0E drawing protocol in Chinese dialogue, menus, move lists and displayed Pokemon names. Han characters use a deterministic GB2312-derived mapping; Latin and manifested punctuation are paired at runtime through the existing strip cache. The retired opcode generator and interpreter are removed.

A reviewed control manifest is authoritative; source scanning is advisory. First generation requires no prior table, while incremental generation preserves legal mappings. Party/HUD share compact name records, original English name pointers and deduplicated metadata. Tagged strip directories reduce ROM overhead without increasing ROM size, WRAM buffers or save fields.

Validation:
- Clean English build is byte-identical to the original baseline (SHA256 469d08907d0ef474d174d87d84d25e108b86ca481131b41fa291bd8aae97c29b).
- Clean Chinese build with the local full input (357 glyphs, 292 names) passes; SHA256 8135f064ba9a5794b5d892ff4fbf42c2d43585aac0200803673ca5cfc1434f29. Build inputs match the final source changes.
- Final ROM Start/party/return smoke checked against English; saves unchanged. Earlier targeted battle/menu and mixed dialogue replays passed.
- Seven decoder CPU cases, seven mixed strip sequences, cache, layout and party-level checks passed.

Acceptance is basic functionality. Detailed malformed-input, lifecycle and worst-case boundary regression is documented for later work, not claimed complete. The full local translation input, fonts, ROMs, saves and screenshots are not included.
