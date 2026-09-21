"""Generate opt-in summary UI assets from caller-supplied terminology."""
import json
from PIL import Image, ImageDraw, ImageFont
from text_layout import encode_2bpp
from suite_layout import region
from cache_text import surface_asm

def generate(source, font_path, terms_path, *, language):
    terms=json.loads(terms_path.read_text())
    labels=[terms[k] for k in ('hp','attack','defense','special_attack','special_defense','speed')]
    title=terms['ability']
    font=ImageFont.truetype(str(font_path),12)
    def label(text):
        return region(language, "summary.label").layout(font).append(text).image
    encode = encode_2bpp
    out=source/'gfx/zh';out.mkdir(exist_ok=True)
    compiled=[]
    for index,value in enumerate(labels):
        compiled += surface_asm(encode(label(value)),24,16,"ZhStatLabel"+str(index))
    (source/"data/zh/stat_labels.asm").write_text(chr(10).join(compiled)+chr(10))
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
    tabs=surface_asm(encode(im),40,24,"ZhAbilityTabText")
    if terms.get('item'):
        item=tab_background.copy()
        glyph=label(terms['item'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):item.putpixel((x+8,y+8),3)
        (out/'item_tab.2bpp').write_bytes(encode(item))
        tabs+=surface_asm(encode(item.crop((0,8,40,24))),40,16,"ZhItemTabText")
    if terms.get('experience'):
        exp=tab_background.copy();glyph=label(terms['experience'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):exp.putpixel((x+8,y+8),3)
        (out/'experience_tab.2bpp').write_bytes(encode(exp))
        tabs+=surface_asm(encode(exp.crop((0,8,40,24))),40,16,"ZhPinkTabText")
    if terms.get('encounter'):
        exp=tab_background.copy();glyph=label(terms['encounter'])
        for y in range(16):
            for x in range(24):
                if glyph.getpixel((x,y)):exp.putpixel((x+8,y+8),3)
        (out/'encounter_tab.2bpp').write_bytes(encode(exp))
        tabs+=surface_asm(encode(exp.crop((0,8,40,24))),40,16,"ZhOrangeTabText")
    (source/"data/zh/summary_tabs.asm").write_text(chr(10).join(tabs)+chr(10))
