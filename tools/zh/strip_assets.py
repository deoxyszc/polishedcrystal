"""Compile individual 4x16 strips, including vertical placement, into ROM.

No words or sentences are rasterized. Identical strip pixels share an ID
across layouts; different pixels cannot alias in the existing cache key.
"""
import json
from pathlib import Path
from PIL import Image
from layouts import LAYOUTS, emit_constants

def position_strip(raw, offset, height=12):
    if len(raw) * 2 != height or not 0 <= offset <= 16 - height:
        raise ValueError("Strip does not fit the 16px cache cell")
    rows = [0] * 16
    for y in range(height):
        rows[offset + y] = (raw[y // 2] >> (4 if y % 2 == 0 else 0)) & 15
    return bytes(rows[y] * 16 + rows[y + 1] for y in range(0, 16, 2))

class StripAssets:
    def __init__(self, source, glyph_count):
        self.source = source
        self.strips = []
        self.ids = {}
        self.maps = {}
        raw = (source / "gfx/zh/prototype.1bpp").read_bytes()
        if len(raw) != glyph_count * 18:
            raise ValueError("Font manifest size mismatch")
        # Read monochrome source pixels independently of PNG palette encoding.
        font = Image.open(source / "gfx/font/normal.png").convert("L")
        latin = []
        for code in range(114):
            x, y = (code % (font.width // 8)) * 8, (code // (font.width // 8)) * 8
            for half in range(2):
                rows = [sum(((font.getpixel((x + half * 4 + col, y + row)) < 128) << (3-col)) for col in range(4)) for row in range(8)]
                latin.append(bytes(rows[i]*16 + rows[i+1] for i in range(0,8,2)))
        for name, layout in LAYOUTS.items():
            self.maps[name] = {
                "glyphs": [[self.add(position_strip(raw[g*18+c*6:g*18+c*6+6], layout.cjk_y)) for c in range(3)] for g in range(glyph_count)],
                "latin": [self.add(position_strip(s, layout.latin_y, 8)) for s in latin],
            }

    def add(self, pixels):
        return self.add_color(bytes(v for byte in pixels for v in (byte, byte)))

    def add_color(self, pixels):
        if not any(pixels):
            return 0xffff
        if pixels not in self.ids:
            if len(self.strips) >= 0xffff:
                raise ValueError("Too many compiled strips")
            self.ids[pixels] = len(self.strips)
            self.strips.append(pixels)
        return self.ids[pixels]

    def emit(self):
        source = self.source
        emit_constants(source)
        hp_table = self.compile_hp()
        self.compile_party_levels()
        blob = b"".join(self.strips)
        directory = ["ZhCompiledStripPages::"]
        sections = []
        for page in range((len(self.strips)+255)//256):
            label = f"ZhCompiledStrips{page}"
            path = f"gfx/zh/strips_{page:03d}.bin"
            (source/path).write_bytes(blob[page*4096:(page+1)*4096])
            directory += [f" db BANK({label})", f" dw {label}"]
            sections += [f'SECTION "Compiled font strips {page}", ROMX', label+"::", f' INCBIN "{path}"']
        for name,label in [("dialogue","ZhDialogueLatinStrips"),("start_menu","ZhStartMenuLatinStrips")]:
            directory += [label+"::"]
            for code in range(114):
                pair = self.maps[name]["latin"][code*2:code*2+2]
                directory.append(" db " + ",".join(str(v) for s in pair for v in (s >> 8, s & 255)))
        directory += ["ZhPartyHPKeys::", " db " + ",".join(map(str,hp_table))]
        (source/'data/zh/font/compiled.asm').write_text(chr(10).join(directory)+chr(10))
        (source/'data/zh/font/compiled_pages.asm').write_text(chr(10).join(sections)+chr(10))
        (source/'data/zh/font/compiled_count.asm').write_text(f"DEF ZH_COMPILED_STRIP_COUNT EQU {len(self.strips)}"+chr(10))
        (source/'data/zh/font/compiled.json').write_text(json.dumps(self.maps))

    def compile_hp(self):
        # Original 8px numerals and HP tiles, combined per cell, never per sentence.
        font=Image.open(self.source/'gfx/font/normal.png').convert('L')
        bars=Image.open(self.source/'gfx/battle/hpexpbars.png').convert('L')
        levels=sorted(set(bars.getdata()),reverse=True)
        table=[]
        for char in [0x7f,0xdc,*range(0xe0,0xea)]:
            for bar in range(0x63,0x6f):
                pixels=[[0]*8 for _ in range(16)]
                if char!=0x7f:
                    n=char-0x80;x=n%16*8;y=n//16*8
                    for yy in range(8):
                        for xx in range(8):
                            if font.getpixel((x+xx,y+yy))<128:pixels[yy+2][xx]=3
                n=bar-0x62;x=n%(bars.width//8)*8;y=n//(bars.width//8)*8
                for yy in range(8):
                    for xx in range(8):
                        v=levels.index(bars.getpixel((x+xx,y+yy)))
                        if v:pixels[yy+8][xx]=v
                for half in range(2):
                    packed=[]
                    for yy in range(0,16,2):
                        for plane in range(2):
                            v=0
                            for y in (yy,yy+1):
                                for x in range(half*4,half*4+4):v=(v<<1)|((pixels[y][x]>>plane)&1)
                            packed.append(v)
                    key=self.add_color(bytes(packed));table += [key>>8,key&255]
        return table

    def compile_party_levels(self):
        font=Image.open(self.source/'gfx/font/normal.png').convert('L')
        def tile(code):
            n=code-0x80
            return font.crop((n%16*8,n//16*8,n%16*8+8,n//16*8+8))
        def merge(left,right,number):
            halves=[bytearray(self.strips[k] if k!=0xffff else bytes(16)) for k in (left,right)]
            im=tile(0xe1 if number else 0xd6)
            for y in range(8):
                for x in range(8):
                    if not number and not 3<=x<7:continue
                    dest=x if number else x+1
                    if im.getpixel((x,y))<128:
                        for plane in range(2):halves[dest//4][((y+8)//2)*2+plane] |= 1 << (7-((y+8)%2)*4-dest%4)
            return [self.add_color(bytes(h)) for h in halves]
        m=self.maps['party_name']
        m['level_plain']=merge(0xffff,0xffff,False)
        m['level_four']=[{'L':merge(g[2],0xffff,False),'100':merge(g[2],0xffff,True)} for g in m['glyphs']]
