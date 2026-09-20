"""Optional translated pink-page labels and species display names."""
import csv, json
from PIL import Image, ImageDraw, ImageFont

PREFIX='engine/pokemon/summary/pink_page.asm::SummaryScreen_PinkPage.'

def generate(source,language,font_path,terms_path):
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
 font=ImageFont.truetype(str(font_path),12)
 def bitmap(text,width,baseline=10):
  if any(c in text for c in '{}@\n\r') or font.getlength(text)>width:raise ValueError('Pink label exceeds display area: '+text)
  im=Image.new('1',(width,16));draw=ImageDraw.Draw(im);draw.fontmode='1';draw.text((0,baseline),text,font=font,fill=1,anchor='ls')
  data=[]
  for ty in range(2):
   for tx in range(width//8):
    for y in range(8):
     v=sum(128>>x for x in range(8)if im.getpixel((tx*8+x,ty*8+y)));data.extend((v,v))
  return data
 lines=['DEF ZH_PINK_TAB EQU '+str(int((source/'gfx/zh/experience_tab.2bpp').exists())),'ZhPinkNameTable::'];bodies=[];consumed=[]
 for row in rows:
  if row['source_path']!='data/pokemon/names.asm':continue
  text=row.get('translation_'+language,'').strip().rstrip('@')
  if not text:continue
  original=row['original']
  if len(original)!=10 or any(c in original for c in '"\n\r'):raise ValueError('Invalid species key')
  label='ZhPinkName'+str(len(bodies));lines+=[' dw '+label]
  bodies += [label+':',' db '+json.dumps(original),' db '+','.join(map(str,bitmap(text,64)))]
 lines+=[' dw 0']+bodies
 lines+=['ZhPinkSlashTiles:', ' db '+','.join(map(str,bitmap('/',8,10)))]
 terms=json.loads(terms_path.read_text())
 lines+=['DEF ZH_PINK_LEVEL EQU '+str(int(bool(terms.get('level_suffix'))))]
 if terms.get('level_suffix'):lines+=['ZhPinkLevelTiles:', ' db '+','.join(map(str,bitmap(terms['level_suffix'],16,11)))]
 specs=[('ExpPointStr','Exp',40),('LevelUpStr','Next',40),('ToStr','To',24),('OTStr','OT',48)]
 for suffix,label,width in specs:
  row=next(r for r in rows if r['id']==PREFIX+suffix+'::1')
  text=row.get('translation_'+language,'').replace('{done}','').strip().rstrip('@')
  if label=='OT' and text:text=text.rstrip('/')+'/'
  if label in ('Exp','Next') and font.getlength(text)>24:
   raise ValueError('Inline pink label exceeds 24px: '+text)
  lines+=['DEF ZH_PINK_'+label.upper()+' EQU '+str(int(bool(text)))]
  if text:
   consumed.append(row['id']);lines+=['ZhPink'+label+'Tiles:',' db '+','.join(map(str,bitmap(text,width,11 if label=='To' else 12)))]
 import subprocess
 subprocess.run(['make','gfx/font/normal.1bpp'],cwd=source,check=True)
 raw=(source/'gfx/font/normal.1bpp').read_bytes();data=[]
 for i in range(114):
  for v in bytes(5)+raw[i*8:i*8+8]+bytes(3):data.extend((v,v))
 (source/'gfx/zh/pink_ascii.2bpp').write_bytes(bytes(data))
 (source/'data/zh/pink.asm').write_text('\n'.join(lines)+'\n')
 (source/'data/zh/pink_consumed.json').write_text(json.dumps(consumed))
