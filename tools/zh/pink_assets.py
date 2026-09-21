"""Optional translated pink-page labels and species display names."""
import csv, json
from PIL import ImageFont
from text_layout import encode_2bpp
from suite_layout import region
from cache_text import surface_asm

PREFIX='engine/pokemon/summary/pink_page.asm::SummaryScreen_PinkPage.'

def generate(source,language,font_path,terms_path):
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
 font=ImageFont.truetype(str(font_path),12)
 def bitmap(text,slot,label):
  config=region(language, "summary.pink." + slot)
  config.check_text(font,text)
  return surface_asm(encode_2bpp(config.layout(font).append(text).image),config.width,config.height,label)
 lines=['DEF ZH_PINK_TAB EQU '+str(int((source/'gfx/zh/experience_tab.2bpp').exists())),'ZhPinkNameTable::'];bodies=[];consumed=[]
 for row in rows:
  if row['source_path']!='data/pokemon/names.asm':continue
  text=row.get('translation_'+language,'').strip().rstrip('@')
  if not text:continue
  original=row['original']
  if len(original)!=10 or any(c in original for c in '"\n\r'):raise ValueError('Invalid species key')
  label='ZhPinkName'+str(len(bodies));lines+=[' dw '+label]
  bodies += [label+':',' db '+json.dumps(original)] + bitmap(text,"name",label+"Text")
 lines+=[' dw 0']+bodies
 lines+=bitmap('/',"slash","ZhPinkSlashTiles")
 terms=json.loads(terms_path.read_text())
 lines+=['DEF ZH_PINK_LEVEL EQU '+str(int(bool(terms.get('level_suffix'))))]
 if terms.get('level_suffix'):lines+=bitmap(terms['level_suffix'],"level","ZhPinkLevelTiles")
 specs=[('ExpPointStr','Exp'),('LevelUpStr','Next'),('ToStr','To'),('OTStr','OT')]
 for suffix,label in specs:
  row=next(r for r in rows if r['id']==PREFIX+suffix+'::1')
  text=row.get('translation_'+language,'').replace('{done}','').strip().rstrip('@')
  if label=='OT' and text:text=text.rstrip('/')+'/'
  lines+=['DEF ZH_PINK_'+label.upper()+' EQU '+str(int(bool(text)))]
  if text:
   consumed.append(row['id']);lines+=bitmap(text,label.lower(),'ZhPink'+label+'Tiles')
 (source/'data/zh/pink.asm').write_text('\n'.join(lines)+'\n')
 (source/'data/zh/pink_consumed.json').write_text(json.dumps(consumed))
