"""Compile selected CSV ability translations for the summary display only."""
import csv
import re
from PIL import Image, ImageDraw, ImageFont
from summary_text_layout import NAME_BASELINE, DESCRIPTION_BASELINE, DESCRIPTION_LINE_STEP

def generate(source, language, font_path):
    with (source/'translations.csv').open(encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    font = ImageFont.truetype(str(font_path), 12)
    table = ['ZhAbilityTable::']
    bodies = []
    name_images = {}
    for kind, path, height, width in [('name','names',16,56), ('description','descriptions',32,112)]:
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
            if len(lines)>2 or (kind=='name' and len(lines)!=1):
                raise ValueError('Ability text exceeds line count')
            im=Image.new('1',(width,height));draw=ImageDraw.Draw(im);draw.fontmode='1'
            if kind == 'description' and index in name_images:
                im.paste(name_images[index].crop((0,8,56,16)),(0,0))
            for y,line in enumerate(lines):
                if any(c in line for c in '{}@\n\r') or font.getlength(line)>width:
                    raise ValueError('Unsupported or oversized ability text: '+row['id'])
                draw.text((0,(NAME_BASELINE if kind == "name" else DESCRIPTION_BASELINE)+y*DESCRIPTION_LINE_STEP),line,font=font,fill=1,anchor='ls')
            if kind == 'name':name_images[index]=im.copy()
            data=[]
            for ty in range(height//8):
                for tx in range(width//8):
                    for yy in range(8):
                        v=sum(128>>x for x in range(8) if im.getpixel((tx*8+x,ty*8+yy)))
                        data.extend((v,v))
            symbol='ZhAbility_'+kind+'_'+str(index)
            table.append(' dw '+symbol)
            bodies += [symbol+':',' db '+','.join(map(str,data))]
    (source/'data/zh/abilities.asm').write_text('\n'.join(table+bodies)+'\n')
