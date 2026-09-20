"""Compile CSV nature and characteristic panels using the original table order."""
import csv
import json
import re
from PIL import ImageFont
from text_layout import TextLayout, text_image, encode_2bpp

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
            layout = TextLayout(font, 96, height)
            parts = [p.strip() for p in text.split('{next}')]
            if len(parts) > (2 if height == 40 else 1):
                raise ValueError('Orange panel exceeds line count: '+label)
            for x, baseline, value in [(0, 10, title)]+[(12, 24+i*12, p) for i,p in enumerate(parts)]:
                if any(c in value for c in '{}@\n\r') or font.getlength(value)>96-x:
                    raise ValueError('Unsupported or oversized orange panel: '+label)
                layout.append(value, x=x, baseline=baseline)
            data = encode_2bpp(layout.image)
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
            data=encode_2bpp(text_image(font,text,width))
            symbol='ZhOrange'+kind+str(index)
            lines.append(' dw '+symbol);bodies += [symbol+':', ' db '+','.join(map(str,data))]
    for kind, key, width, inset in [
        ('LevelPrefix', 'met_level_prefix', 48, 0),
        ('LevelSuffix', 'level_suffix', 16, 2),
    ]:
        text=terms.get(key, '')
        lines.append('DEF ZH_ORANGE_'+kind.upper()+' EQU '+str(int(bool(text))))
        if not text:continue
        if any(c in text for c in '{}@\n\r') or font.getlength(text)>width-inset:
            raise ValueError('Oversized orange level text: '+key)
        layout=TextLayout(font,width).append(text,x=inset)
        data=encode_2bpp(layout.image)
        bodies += ['ZhOrange'+kind+'Tiles:', ' db '+','.join(map(str,data))]
    prefix_width=int(round(font.getlength(terms.get('met_level_prefix', ''))))
    digit_x=(8+prefix_width+7)//8
    if digit_x+3>=20:raise ValueError('Orange level line exceeds display area')
    lines += ['DEF ZH_ORANGE_LEVEL_DIGIT_X EQU '+str(digit_x),
              'DEF ZH_ORANGE_LEVEL_SUFFIX_X1 EQU '+str(digit_x+1),
              'DEF ZH_ORANGE_LEVEL_SUFFIX_X2 EQU '+str(digit_x+2),
              'DEF ZH_ORANGE_LEVEL_SUFFIX_X3 EQU '+str(digit_x+3)]
    (source/'data/zh/orange.asm').write_text(chr(10).join(lines+bodies)+chr(10))
    (source/'data/zh/orange_consumed.json').write_text(json.dumps(consumed))
