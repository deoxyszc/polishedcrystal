"""Build-time layout definitions; runtime strips carry pixels, not styles."""
from dataclasses import dataclass
@dataclass(frozen=True)
class Layout:
    left: int
    top: int
    width: int
    step: int
    cjk_y: int
    latin_y: int

    def __post_init__(self):
        if not 1 <= self.left or self.left + self.width > 19:
            raise ValueError("Text region exceeds the frame")
        if self.top < 0 or self.step < 2 or self.top + self.step + 2 > 17:
            raise ValueError("Two-row text overlaps the bottom border")
        if not 0 <= self.cjk_y <= 4 or not 0 <= self.latin_y <= 8:
            raise ValueError("Font placement exceeds the 16px cell")
DIALOGUE = Layout(1, 13, 18, 2, 4, 8)
MOVE_LIST = Layout(1, 9, 18, 2, 2, 4)
START_MENU = Layout(12, 1, 7, 2, 4, 8)
PARTY_NAME = Layout(2, 0, 8, 2, 4, 8)
PARTY_FOOTER = Layout(1, 12, 18, 2, 4, 8)
LAYOUTS = {"party_name": PARTY_NAME, "party_footer": PARTY_FOOTER, "dialogue": DIALOGUE, "move_list": MOVE_LIST, "start_menu": START_MENU}

def emit_constants(source):
    lines = ["; Generated from tools/zh/layouts.py. No runtime layout selection."]
    for name, layout in LAYOUTS.items():
        for field in ("left", "top", "width", "step"):
            lines.append(f"DEF ZH_{name.upper()}_{field.upper()} EQU {getattr(layout, field)}")
    (source / "constants/zh_layout.asm").write_text(chr(10).join(lines) + chr(10))
