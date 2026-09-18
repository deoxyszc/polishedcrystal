"""Compile generic held-item display tables from source order and selected CSV."""
import csv, json, re, sys
from PIL import Image, ImageDraw, ImageFont
from summary_text_layout import NAME_BASELINE, DESCRIPTION_BASELINE, DESCRIPTION_LINE_STEP
EMPTY_ID='engine/pokemon/summary/green_page.asm::SummaryScreen_GreenPage.NoHeldItemString::1'

def generate(source, language, font_path):
 sys.path.insert(0,str(source/'tools/i18n'))
 import messages
 authority={r['id']:r for r in messages.build(source,'normal')[0]}
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:entries=list(csv.DictReader(f))
 rows={r['id']:r for r in entries}
 if len(rows)!=len(entries):raise ValueError('Duplicate CSV ID')
 names=sorted((r for r in authority.values() if r['source_path']=='data/items/names.asm'),key=lambda r:r['source_line'])
 labels=re.findall(r'^\s*dw (\w+)\s*$',(source/'data/items/descriptions.asm').read_text().split('KeyItemDescriptions:',1)[0],re.M)
 if len(names)!=len(labels)+1 or len(names)>256:raise ValueError('Item tables disagree')
 descriptions={r['id'].split('::')[1]:r for r in authority.values() if r['source_path']=='data/items/descriptions.asm'}
 font=ImageFont.truetype(str(font_path),12)
 output=['DEF ZH_ITEM_TITLE EQU '+str(int((source/'gfx/zh/item_tab.2bpp').exists())),'DEF ZH_ITEM_COUNT EQU '+str(len(names))]
 blobs=[];consumed=[];name_images={}
 def translation(record):
  if record is None:return ''
  row=rows.get(record['id']);text=row.get('translation_'+language,'').strip() if row else ''
  if text:
   if row['source_sha256']!=record['source_sha256'] or row['original']!=record['translation_view']:raise ValueError('Item source drift: '+row['id'])
   consumed.append(row['id'])
  return text
 for kind,width,height in [('Name',144,16),('Description',144,32)]:
  output.append('ZhItem'+kind+'Table::')
  for index in range(len(names)):
   record=(authority.get(EMPTY_ID) if index==0 else names[index]) if kind=='Name' else (None if index==0 else descriptions.get(labels[index-1]))
   text=translation(record)
   if not text:output.append(' db 0,0,0');continue
   if kind=='Name':lines=[text.replace('{li}','').strip().rstrip('@')]
   else:
    if not text.endswith('{done}'):raise ValueError('Item description requires {done}')
    lines=[s.strip() for s in text[:-6].split('{next}')]
   if len(lines)>(1 if kind=='Name' else 2):raise ValueError('Too many item text lines')
   im=Image.new('1',(width,height));draw=ImageDraw.Draw(im);draw.fontmode='1'
   if kind=='Description' and index in name_images:im.paste(name_images[index].crop((0,8,144,16)),(0,0))
   for y,line in enumerate(lines):
    if not line or any(c in line for c in '{}@\n\r') or font.getlength(line)>width:raise ValueError('Unsupported or oversized item text: '+record['id'])
    draw.text((0,(NAME_BASELINE if kind=='Name' else DESCRIPTION_BASELINE)+y*DESCRIPTION_LINE_STEP),line,font=font,fill=1,anchor='ls')
   if kind=='Name':name_images[index]=im.copy()
   data=[]
   for ty in range(height//8):
    for tx in range(width//8):
     for yy in range(8):
      v=sum(128>>x for x in range(8) if im.getpixel((tx*8+x,ty*8+yy)));data.extend((v,v))
   symbol='ZhItem'+kind+str(index)
   output+=[' db BANK('+symbol+')',' dw '+symbol]
   blobs+=['SECTION "Item display '+kind+' '+str(index)+'", ROMX',symbol+'::',' db '+','.join(map(str,data))]
 (source/'data/zh/item_panel.asm').write_text('\n'.join(output)+'\n')
 (source/'data/zh/item_assets.asm').write_text('\n'.join(blobs)+'\n')
 (source/'data/zh/item_consumed.json').write_text(json.dumps(sorted(set(consumed))))
