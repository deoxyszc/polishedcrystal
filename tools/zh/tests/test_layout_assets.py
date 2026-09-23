"""Compiled layout isolation and original-font pixel fidelity."""
import sys,tempfile
from pathlib import Path
from dataclasses import replace
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import strip_assets
from layouts import DIALOGUE,MOVE_LIST
from cache_text import encode_pairs

def pixels(assets,name):
    return [[bytes(8) if key==0xffff else assets.strips[key][::2] for key in row]
            for row in assets.maps[name]['glyphs']]

with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp)
    (root/'gfx/zh').mkdir(parents=True)
    (root/'gfx/font').mkdir()
    (root/'gfx/zh/prototype.1bpp').write_bytes(bytes([0xf0,0x12,0x34,0x56,0x78,0x9a])*3)
    font=Image.new('L',(128,64),255)
    for y in range(8):font.putpixel((y,y),0)
    font.save(root/'gfx/font/normal.png')
    before=strip_assets.StripAssets(root,1)
    strip_assets.LAYOUTS={**strip_assets.LAYOUTS,'dialogue':replace(DIALOGUE,cjk_y=0,latin_y=4)}
    after=strip_assets.StripAssets(root,1)
    assert pixels(before,'move_list')==pixels(after,'move_list')
    assert pixels(before,'dialogue')!=pixels(after,'dialogue')
    assert before.maps['dialogue']['glyphs'][0] != before.maps['move_list']['glyphs'][0]
    # 8px Latin pixels retain their shape at the independently selected offset.
    for name,offset in [('dialogue',8),('move_list',4)]:
        halves=[before.strips[k][::2] for k in before.maps[name]['latin'][:2]]
        for y in range(16):
            row=0
            for half in halves:row=row*16+((half[y//2]>>(4 if y%2==0 else 0))&15)
            assert row==(128>>(y-offset) if offset<=y<offset+8 else 0)
    encoded,tiles=encode_pairs('中',{'中':0},width_tiles=2,strip_map=before.maps['dialogue'])
    assert tiles==2 and len(encoded)==10
    assert encoded != encode_pairs('中',{'中':0},width_tiles=2,strip_map=before.maps['move_list'])[0]
print('PASS independent layout pixels, distinct cache identities, unchanged Latin pixels')
