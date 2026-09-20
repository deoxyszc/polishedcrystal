"""Compile CSV nature and characteristic panels using the original table order."""
import csv
import json
import re
from PIL import Image, ImageDraw, ImageFont

def generate(source, language, font_path, terms_path):
    with (source/'translations.csv').open(encoding='utf-8-sig', newline='') as stream:
        rows = {r['id']: r for r in csv.DictReader(stream)}
    font = ImageFont.truetype(str(font_path), 12)
    consumed = []
    def translated(path, label):
        key = path+'::'+label+'::1'
        row = rows.get(key, {})
        text = row.get('translation_'+language, '').strip()
        if text:
            consumed.append(key)
        return text.removesuffix('{done}').strip().rstrip('@')
    prefix = 'SummaryScreen_OrangePage.'
    page = 'engine/pokemon/summary/orange_page.asm'
    lines = ['DEF ZH_ORANGE_TAB EQU '+str(int((source/'gfx/zh/encounter_tab.2bpp').exists())), 'ZhOrangeTable::']
    bodies = []
    for kind, path, root, op, heading, height in [
        ('Nature', 'data/natures.asm', 'NatureNames', 'dr', 'NatureString', 32),
        ('Character', 'data/characteristics.asm', 'Characteristics', 'dw', 'CharacterString', 40),
    ]:
        title = translated(page, prefix+heading)
        if title:
            title = title.rstrip('/')+'/'
        text_source = (source/path).read_text().split('assert_table_length', 1)[0]
        labels = re.findall(r'^\s*'+op+r' (\.\w+)\s*$', text_source, re.M)
        lines.append('ZhOrange'+kind+'Table::')
        for index, label in enumerate(labels):
            text = translated(path, root+label)
            if not title or not text:
                lines.append(' dw 0')
                continue
            image = Image.new('1', (96, height))
            draw = ImageDraw.Draw(image); draw.fontmode = '1'
            parts = [p.strip() for p in text.split('{next}')]
            if len(parts) > (2 if height == 40 else 1):
                raise ValueError('Orange panel exceeds line count: '+label)
            for x, baseline, value in [(0, 10, title)]+[(12, 24+i*12, p) for i,p in enumerate(parts)]:
                if any(c in value for c in '{}@\n\r') or font.getlength(value)>96-x:
                    raise ValueError('Unsupported or oversized orange panel: '+label)
                draw.text((x, baseline), value, font=font, fill=1, anchor='ls')
            data = []
            for ty in range(height//8):
                for tx in range(12):
                    for y in range(8):
                        v = sum(128>>x for x in range(8) if image.getpixel((tx*8+x,ty*8+y)))
                        data.extend((v,v))
            symbol = 'ZhOrange'+kind+str(index)
            lines.append(' dw '+symbol)
            bodies += [symbol+':', ' db '+','.join(map(str,data))]
    terms = json.loads(terms_path.read_text())
    locations = re.findall(r'^\s*landmark[^\n]*, (\w+)\s*$', (source/'data/maps/landmarks.asm').read_text(), re.M)
    for kind, path, labels, width in [
        ('Time', 'engine/rtc/timeset.asm', ['EVE_String', 'MORN_String', 'DAY_String', 'NITE_String'], 24),
        ('Location', 'data/maps/landmarks.asm', locations, 120),
    ]:
        lines.append('ZhOrange'+kind+'Table::')
        for index, label in enumerate(labels):
            text = translated(path, label)
            if kind == 'Location':
                template = terms.get('met_location', '')
                text = template.replace('{location}', text) if text and template.count('{location}') == 1 else ''
            if not text:
                lines.append(' dw 0')
                continue
            if any(c in text for c in '{}@\n\r') or font.getlength(text)>width:
                raise ValueError('Oversized encounter text: '+label)
            im=Image.new('1',(width,16));draw=ImageDraw.Draw(im);draw.fontmode='1'
            draw.text((0,12),text,font=font,fill=1,anchor='ls')
            data=[]
            for ty in range(2):
                for tx in range(width//8):
                    for y in range(8):
                        v=sum(128>>x for x in range(8) if im.getpixel((tx*8+x,ty*8+y)))
                        data.extend((v,v))
            symbol='ZhOrange'+kind+str(index)
            lines.append(' dw '+symbol);bodies += [symbol+':', ' db '+','.join(map(str,data))]
    for kind, key, width in [
        ('LevelPrefix', 'met_level_prefix', 48),
        ('LevelSuffix', 'level_suffix', 16),
    ]:
        text=terms.get(key, '')
        lines.append('DEF ZH_ORANGE_'+kind.upper()+' EQU '+str(int(bool(text))))
        if not text:continue
        if any(c in text for c in '{}@\n\r') or font.getlength(text)>width-2:
            raise ValueError('Oversized orange level text: '+key)
        image=Image.new('1',(width,16));draw=ImageDraw.Draw(image);draw.fontmode='1'
        draw.text((2,12),text,font=font,fill=1,anchor='ls')
        data=[]
        for ty in range(2):
            for tx in range(width//8):
                for y in range(8):
                    value=sum(128>>x for x in range(8) if image.getpixel((tx*8+x,ty*8+y)))
                    data.extend((value,value))
        bodies += ['ZhOrange'+kind+'Tiles:', ' db '+','.join(map(str,data))]
    raw=(source/'gfx/font/normal.1bpp').read_bytes()
    for half in range(2):
        data=[]
        for digit in range(10):
            pixels=bytes(4)+raw[(0x60+digit)*8:(0x61+digit)*8]+bytes(4)
            for value in pixels[half*8:half*8+8]:data.extend((value,value))
        bodies += ['ZhOrangeDigits'+str(half)+':', ' db '+','.join(map(str,data))]
    (source/'data/zh/orange.asm').write_text(chr(10).join(lines+bodies)+chr(10))
    (source/'data/zh/orange_consumed.json').write_text(json.dumps(consumed))
