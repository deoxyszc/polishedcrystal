"""Compile translated summary move names indexed by the original move IDs."""
import csv
import subprocess
from PIL import ImageFont
from text_layout import text_image, encode_2bpp

def generate(source,language,font_path):
 subprocess.run(['make','gfx/font/normal.1bpp'],cwd=source,check=True)
 glyph=(source/'gfx/font/normal.1bpp').read_bytes()[0x57*8:0x58*8]
 middle=bytes(((v<<4)|(v>>4))&255 for v in glyph)
 (source/'gfx/zh/summary_pp.1bpp').write_bytes(bytes(v&15 for v in middle)+middle+bytes(v&240 for v in middle))
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
  rows=sorted((r for r in csv.DictReader(f) if r['source_path']=='data/moves/names.asm'),key=lambda r:int(r['id'].rsplit('::',1)[1]))
 font=ImageFont.truetype(str(font_path),12)
 table=['ZhSummaryMoveNames::',' db 0,0,0'];assets=[]
 for index,row in enumerate(rows,1):
  text=row.get('translation_'+language,'').replace('{li}','').strip()
  if not text:table.append(' db 0,0,0');continue
  if font.getlength(text)>64 or any(c in text for c in '{}@\n\r'):raise ValueError('Summary move exceeds 64px: '+row['id'])
  data=encode_2bpp(text_image(font,text,64,baseline=10))
  label='ZhSummaryMove'+str(index)
  table+=[' db BANK('+label+')',' dw '+label]
  assets+=['SECTION "Summary move '+str(index)+'", ROMX',label+'::',' db '+','.join(map(str,data))]
 (source/'data/zh/summary_moves.asm').write_text('\n'.join(table)+'\n')
 (source/'data/zh/summary_move_assets.asm').write_text('\n'.join(assets)+'\n')
