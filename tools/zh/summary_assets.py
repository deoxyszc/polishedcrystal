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
    for y in range(16):
        for x in range(24):
            if glyph.getpixel((x,y)):im.putpixel((x+8,y+8),3)
    (out/'ability_tab.2bpp').write_bytes(encode(im))
    subprocess.run(['make', 'gfx/font/normal.1bpp'], cwd=source, check=True)
    raw=(source/'gfx/font/normal.1bpp').read_bytes();data=bytearray()
    for code in list(range(0xe0,0xea))+[0xde,0x7f]:
        rows=bytes(4)+(raw[(code-0x80)*8:(code-0x80)*8+8] if code!=0x7f else bytes(8))+bytes(4)
        for v in rows:data.extend((v,v))
    (out/'level_digits.2bpp').write_bytes(data)
