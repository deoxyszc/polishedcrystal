"""Generate opt-in summary UI assets from caller-supplied terminology."""
import json
import subprocess
from PIL import Image, ImageDraw, ImageFont

def generate(source, font_path, terms_path):
    terms=json.loads(terms_path.read_text())
    labels=[terms[k] for k in ('hp','attack','defense','special_attack','special_defense','speed')]
    title=terms['ability']
    font=ImageFont.truetype(str(font_path),12)
    def label(text):
        if font.getlength(text)>24: raise ValueError('Summary label exceeds24px: '+text)
        im=Image.new('1',(24,16));d=ImageDraw.Draw(im);d.fontmode='1'
        d.text((0,12),text,font=font,fill=1,anchor='ls')
        return im
    def encode(im):
        data=bytearray()
        for ty in range(im.height//8):
            for tx in range(im.width//8):
                for y in range(8):
                    lo=hi=0
                    for x in range(8):
                        v=im.getpixel((tx*8+x,ty*8+y));v=(3 if v else 0) if im.mode=='1' else v
                        lo|=(v&1)<<(7-x);hi|=(v>>1)<<(7-x)
                    data.extend((lo,hi))
        return bytes(data)
    out=source/'gfx/zh';out.mkdir(exist_ok=True)
    (out/'levelup.2bpp').write_bytes(b''.join(encode(label(t)) for t in labels))
    (out/'summary_labels.2bpp').write_bytes(b''.join(encode(label(t)) for t in labels[1:]))
    glyph=label(title)
    im=Image.new('P',(40,24),1);d=ImageDraw.Draw(im)
    d.rectangle((2,9,37,19),fill=0);d.rectangle((0,21,39,23),fill=0)
    d.line((3,8,36,8),fill=3);d.point((2,9),fill=3);d.point((37,9),fill=3)
    d.line((1,10,1,19),fill=3);d.line((38,10,38,19),fill=3)
    d.line((0,20,1,20),fill=3);d.line((38,20,39,20),fill=3);d.line((2,20,37,20),fill=0)
    tab_background=im.copy()
    for y in range(16):
        for x in range(24):
            if glyph.getpixel((x,y)):im.putpixel((x+8,y+8),3)
    (out/'ability_tab.2bpp').write_bytes(encode(im))
    if terms.get('item'):
        item=tab_background.copy()
        glyph=label(terms['item'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):item.putpixel((x+8,y+8),3)
        (out/'item_tab.2bpp').write_bytes(encode(item))
    if terms.get('experience'):
        exp=tab_background.copy();glyph=label(terms['experience'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):exp.putpixel((x+8,y+8),3)
        (out/'experience_tab.2bpp').write_bytes(encode(exp))
    if terms.get('encounter'):
        exp=tab_background.copy();glyph=label(terms['encounter'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):exp.putpixel((x+8,y+8),3)
        (out/'encounter_tab.2bpp').write_bytes(encode(exp))
    subprocess.run(['make', 'gfx/font/normal.1bpp'], cwd=source, check=True)
    raw=(source/'gfx/font/normal.1bpp').read_bytes();data=bytearray()
    for code in list(range(0xe0,0xea))+[0xde,0x7f]:
        rows=bytes(4)+(raw[(code-0x80)*8:(code-0x80)*8+8] if code!=0x7f else bytes(8))+bytes(4)
        for v in rows:data.extend((v,v))
    (out/'level_digits.2bpp').write_bytes(data)
    digits=bytearray()
    for half in range(2):
        for digit in range(10):
            pixels=bytes(4)+raw[(0x60+digit)*8:(0x61+digit)*8]+bytes(4)
            for value in pixels[half*8:half*8+8]:digits.extend((value,value))
    (out/'summary_digits.2bpp').write_bytes(digits)
    # Alternate stat panel: 96x64, original-width digits below each label.
    panel=Image.new('1',(96,64));pd=ImageDraw.Draw(panel);pd.fontmode='1'
    for i,text in enumerate(labels[1:]):
        pd.text(((i%2)*48,12+(i//2)*20),text,font=font,fill=1,anchor='ls')
    (out/'summary_two_line.2bpp').write_bytes(encode(panel.convert('L').point(lambda v: 2 if v else 0)))
    shifted=bytearray()
    for offset in (6,2):
        for code in range(10):
            rows=bytes(offset)+raw[(0x60+code)*8:(0x61+code)*8]+bytes(8-offset)
            for v in rows:shifted.extend((v,v))
    (out/'summary_shift_digits.2bpp').write_bytes(shifted)
    subprocess.run(['make','gfx/stats/summary.2bpp'],cwd=source,check=True)
    marker=(source/'gfx/stats/summary.2bpp').read_bytes()[12*16:13*16]
    panel_path=out/'summary_two_line.2bpp'
    pixels=bytearray(panel_path.read_bytes())
    edge=(source/'gfx/stats/summary.2bpp').read_bytes()[4*16+14:4*16+16]
    # Original edge ink uses dedicated black color 2, never nature color 3.
    edge=bytes((0,edge[1]))
    for x in range(12):pixels[(7*12+x)*16+14:(7*12+x)*16+16]=edge
    panel_path.write_bytes(pixels)
    (out/'summary_shift_marker.2bpp').write_bytes(
        bytes(12)+marker+bytes(4)+bytes(4)+marker+bytes(12))

    corner=bytearray((source/'gfx/stats/summary.2bpp').read_bytes()[32:48])
    # Keep the original corner unchanged.
    (out/'summary_corner.2bpp').write_bytes(corner)
