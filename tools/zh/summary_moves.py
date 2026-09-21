"""Compile translated summary move names indexed by the original move IDs."""
import csv
from PIL import ImageFont
from text_layout import encode_2bpp
from suite_layout import region
from cache_text import surface_asm

def generate(source,language,font_path):
 config=region(language, "summary.move")
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
  rows=sorted((r for r in csv.DictReader(f) if r['source_path']=='data/moves/names.asm'),key=lambda r:int(r['id'].rsplit('::',1)[1]))
 font=ImageFont.truetype(str(font_path),12)
 table=['ZhSummaryMoveNames::',' db 0,0,0'];assets=[]
 for index,row in enumerate(rows,1):
  text=row.get('translation_'+language,'').replace('{li}','').strip()
  if not text:table.append(' db 0,0,0');continue
  if font.getlength(text)>config.width or any(c in text for c in '{}@\n\r'):raise ValueError('Summary move exceeds configured width: '+row['id'])
  data=encode_2bpp(config.layout(font).append(text).image)
  label='ZhSummaryMove'+str(index)
  table+=[' db BANK('+label+')',' dw '+label]
  assets+=['SECTION "Summary move '+str(index)+'", ROMX']+surface_asm(data,config.width,config.height,label)
 (source/'data/zh/summary_moves.asm').write_text('\n'.join(table)+'\n')
 (source/'data/zh/summary_move_assets.asm').write_text('\n'.join(assets)+'\n')
