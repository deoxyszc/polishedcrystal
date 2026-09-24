"""Check compiled shared-cell L/100 pixels, including both glyph planes."""
import sys,tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from strip_assets import StripAssets
from cache_text import measure_text
ROOT=Path(__file__).resolve().parents[3]
with tempfile.TemporaryDirectory() as tmp:
    source=Path(tmp)
    (source/'gfx/zh').mkdir(parents=True)
    (source/'gfx/font').mkdir()
    (source/'gfx/zh/prototype.1bpp').write_bytes(bytes([0x85,0x21,0x48,0xa1,0x52,0x84])*3)
    (source/'gfx/font/normal.png').write_bytes((ROOT/'gfx/font/normal.png').read_bytes())
    assets=StripAssets(source,1);assets.compile_party_levels()
    m=assets.maps['party_name'];font=Image.open(source/'gfx/font/normal.png').convert('L')
    def unpack(keys):
        result=[[0]*8 for _ in range(16)]
        for half,key in enumerate(keys):
            data=assets.strips[key] if key!=65535 else bytes(16)
            for y in range(16):
                for x in range(4):
                    shift=7-y%2*4-x
                    result[y][half*4+x]=sum(((data[y//2*2+p]>>shift)&1)<<p for p in range(2))
        return result
    original=unpack([m['glyphs'][0][2],65535])
    for kind,code in [('L',0xd6),('100',0xe1)]:
        expected=[row[:] for row in original];n=code-0x80
        for y in range(8):
            for x in range(8):
                if kind=='L' and not 3<=x<7:continue
                if font.getpixel((n%16*8+x,n//16*8+y))<128:
                    expected[y+8][x+1 if kind=='L' else x]=3
        assert unpack(m['level_four'][0][kind])==expected
    for count in range(1,6):
        lead=1
        width=measure_text('中'*count,{'中':0},width_tiles=8,strip_map=m,leading_strips=lead)
        assert width<=8
print('PASS shared L/100 cell pixel equality and one-to-five-character encoding')
