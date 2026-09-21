"""Chinese-suite layout configuration, selected only by the build language.

No layout selector is stored in the ROM or exposed as a page enable switch.
The configuration describes geometry, never a claim of free VRAM.
"""
from dataclasses import dataclass
from types import MappingProxyType

@dataclass(frozen=True)
class Region:
    width: int
    height: int = 16
    baseline: int = 12
    line_step: int = 16
    advance: int | None = None
    inset: int = 0
    content_baseline: int | None = None
    max_lines: int = 1
    max_text_width: int | None = None
    columns: int = 1

    def __post_init__(self):
        if self.width <= 0 or self.height <= 0 or self.width % 8 or self.height % 8:
            raise ValueError("Region must contain whole tiles")
        if self.line_step <= 0 or self.max_lines <= 0:
            raise ValueError("Invalid line configuration")
        if self.columns <= 0 or self.width % self.columns:
            raise ValueError("Invalid column configuration")
        if not 0 <= self.inset < self.width:
            raise ValueError("Invalid region inset")
        if not 0 <= self.baseline <= self.height:
            raise ValueError("Invalid baseline")
        if self.advance is not None and self.advance <= 0:
            raise ValueError("Invalid character advance")
        if self.max_text_width is not None and not 0 < self.max_text_width <= self.width:
            raise ValueError("Invalid text width limit")
        if self.content_baseline is not None and not 0 <= self.content_baseline <= self.height:
            raise ValueError("Invalid content baseline")

    def check_text(self, font, text):
        limit = self.max_text_width or self.width - self.inset
        width = len(text) * self.advance if self.advance else font.getlength(text)
        if width > limit:
            raise ValueError("Text exceeds configured width: " + text)

    def layout(self, font, *, image=None):
        from text_layout import TextLayout, TextStyle
        return TextLayout(font, self.width, self.height, image=image,
                          style=TextStyle(self.baseline, self.line_step, self.advance))

# Simplified and traditional Chinese intentionally share geometry.
REGIONS = MappingProxyType({
    "party.name": Region(56, baseline=10, advance=11),
    "battle.name": Region(56, baseline=14, advance=11),
    "party.cancel": Region(48, baseline=12),
    "party.prompt": Region(144),
    "summary.move": Region(64, baseline=10),
    "summary.ability.name": Region(56, baseline=10),
    "summary.ability.description": Region(112, 32, baseline=16, line_step=13, max_lines=2),
    "summary.item.name": Region(144, baseline=10),
    "summary.item.description": Region(144, 32, baseline=16, line_step=13, max_lines=2),
    "summary.label": Region(24),
    "summary.stats": Region(96, 64, line_step=20, columns=2),
    "summary.pink.name": Region(64, baseline=10),
    "summary.pink.slash": Region(8, baseline=10),
    "summary.pink.level": Region(16, baseline=11),
    "summary.pink.exp": Region(40, max_text_width=24),
    "summary.pink.next": Region(40, max_text_width=24),
    "summary.pink.to": Region(24, baseline=11),
    "summary.pink.ot": Region(48),
    "summary.orange.nature": Region(96, 32, baseline=10, line_step=12, inset=12, content_baseline=24),
    "summary.orange.character": Region(96, 40, baseline=10, line_step=12, inset=12, content_baseline=24, max_lines=2),
    "summary.orange.time": Region(24),
    "summary.orange.location": Region(120),
    "summary.orange.level_prefix": Region(48),
    "summary.orange.level_suffix": Region(16, inset=2),
})

def select(language):
    if language == "en":
        return None
    if language not in ("zh-Hans", "zh-Hant"):
        raise ValueError("Unsupported build language: " + language)
    return REGIONS

def region(language, name):
    selected = select(language)
    if selected is None:
        raise ValueError("English builds use the original layout")
    return selected[name]

def asm_constants(language):
    """Resolve region geometry into assembly constants; no runtime table."""
    selected = select(language)
    if selected is None:
        return "; Original English layout" + chr(10)
    lines = ["; Generated Chinese-suite geometry; no page switches."]
    for name, config in selected.items():
        prefix = "ZH_REGION_" + name.upper().replace(".", "_")
        for suffix, value in (("WIDTH", config.width), ("HEIGHT", config.height),
                              ("COLS", config.width // 8), ("ROWS", config.height // 8),
                              ("BASELINE", config.baseline), ("LINE_STEP", config.line_step),
                              ("ADVANCE", config.advance or 0)):
            lines.append(f"DEF {prefix}_{suffix} EQU {value}")
    return chr(10).join(lines) + chr(10)
