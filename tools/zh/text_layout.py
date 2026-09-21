"""Shared pixel layout and tile encoding; page adapters own their containers.

Positions are pixel baselines. Text advances continuously until a caller starts
a new line. Only the final image is padded/aligned to Game Boy tiles.
"""
from dataclasses import dataclass
from PIL import Image, ImageDraw


@dataclass(frozen=True)
class TextStyle:
    baseline: int = 12
    line_step: int = 16
    advance: int | None = None


DEFAULT = TextStyle()


class TextLayout:
    def __init__(self, font, width, height=16, *, style=DEFAULT, image=None):
        if width <= 0 or height <= 0:
            raise ValueError('Text container must have positive dimensions')
        self.font = font
        self.image = image if image is not None else Image.new('1', (width, height))
        if self.image.size != (width, height):
            raise ValueError('Text image and container disagree')
        self.style = style
        self.x = 0
        self.baseline = style.baseline

    def measure(self, text):
        return len(text) * self.style.advance if self.style.advance is not None else sum(self.font.getlength(char) for char in text)

    def append(self, text, *, x=None, baseline=None, fill=1):
        if any(c in text for c in '{}@\n\r'):
            raise ValueError('Unresolved control token in text: ' + text)
        x = self.x if x is None else x
        baseline = self.baseline if baseline is None else baseline
        end = x + self.measure(text)
        if x < 0 or end > self.image.width:
            raise ValueError('Text exceeds container width: ' + text)
        # Check raster ink too: font advance alone does not detect clipped ink.
        mask = Image.new('1', (self.image.width + 64, self.image.height + 64))
        draw = ImageDraw.Draw(mask); draw.fontmode = '1'
        pen = x
        for char in text:
            draw.text((pen + 32, baseline + 32), char, font=self.font, fill=1, anchor='ls')
            pen += self.measure(char)
        box = mask.getbbox()
        if box and (box[0] < 32 or box[1] < 32 or box[2] > self.image.width+32 or box[3] > self.image.height+32):
            raise ValueError('Text ink exceeds container: ' + text)
        self.image.paste(fill, (0, 0), mask.crop((32, 32, self.image.width+32, self.image.height+32)))
        self.x, self.baseline = end, baseline
        return self

    def newline(self, *, x=0):
        self.x = x
        self.baseline += self.style.line_step
        return self

    def lines(self, values):
        for i, value in enumerate(values):
            if i:
                self.newline()
            self.append(value)
        return self.image


def text_image(font, text, width, height=16, *, baseline=DEFAULT.baseline):
    return TextLayout(font, width, height, style=TextStyle(baseline=baseline)).append(text).image


def encode_2bpp(image):
    """Encode a whole pixel surface, preserving overlaps across tile rows."""
    if image.width % 8 or image.height % 8:
        raise ValueError('Tile surface dimensions must be multiples of 8')
    data = bytearray()
    for ty in range(0, image.height, 8):
        for tx in range(0, image.width, 8):
            for y in range(8):
                lo = hi = 0
                for x in range(8):
                    value = image.getpixel((tx+x, ty+y))
                    if image.mode == '1':
                        value = 3 if value else 0
                    if not isinstance(value, int) or not 0 <= value <= 3:
                        raise ValueError('Tile pixels must use color indices 0..3')
                    lo |= (value & 1) << (7-x)
                    hi |= (value >> 1) << (7-x)
                data.extend((lo, hi))
    return bytes(data)
