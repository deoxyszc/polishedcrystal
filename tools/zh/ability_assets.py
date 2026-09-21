"""Compile selected CSV ability translations for the summary display only."""
import csv
import re
from PIL import Image, ImageFont
from text_layout import encode_2bpp
from suite_layout import region
from cache_text import compile_surface

def generate(source, language, font_path):
    with (source/'translations.csv').open(encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    font = ImageFont.truetype(str(font_path), 12)
    table = ['ZhAbilityTable::']
    bodies = []
    name_images = {}
    for kind, path in [('name','names'), ('description','descriptions')]:
        config=region(language, "summary.ability." + kind)
        width,height=config.width,config.height
        source_path = 'data/abilities/' + path + '.asm'
        labels = re.findall(r'^\s*dw (\w+)\s*$', (source/source_path).read_text(), re.M)
        selected = {r['id'].split('::')[1]:r for r in rows if r['source_path']==source_path}
        table.append('ZhAbility' + kind.title() + 'Table::')
        for index, label in enumerate(labels):
            row = selected.get(label)
            text = row.get('translation_'+language,'').strip() if row else ''
            if not text:
                table.append(' dw 0')
                continue
            if kind == 'name':
                lines = [text.rstrip('@')]
            else:
                if not text.endswith('{done}'):
                    raise ValueError('Ability description requires {done}: '+row['id'])
                text = text[:-6].strip()
                lines = [line.strip() for line in text.split('{next}')]
            if not 1 <= len(lines) <= config.max_lines:
                raise ValueError('Ability text exceeds line count')
            im=Image.new('1',(width,height))
            if kind == 'description' and index in name_images:
                name_config=region(language, "summary.ability.name")
                im.paste(name_images[index].crop((0,8,name_config.width,name_config.height)),(0,0))
            layout=config.layout(font,image=im)
            for y,line in enumerate(lines):
                if any(c in line for c in '{}@\n\r') or font.getlength(line)>width:
                    raise ValueError('Unsupported or oversized ability text: '+row['id'])
                layout.append(line)
                layout.newline()
            if kind == 'name':name_images[index]=im.copy()
            data=encode_2bpp(im)
            symbol='ZhAbility_'+kind+'_'+str(index)
            table.append(' dw '+symbol)
            streams, blocks = compile_surface(data,width,height,symbol)
            bodies.append(symbol + ":")
            for i, stream in enumerate(streams):
                bodies += stream[:-1]
                if i + 1 < len(streams): bodies.append(" db $56")
            bodies += [" db $53"] + blocks
    (source/'data/zh/abilities.asm').write_text('\n'.join(table+bodies)+'\n')
