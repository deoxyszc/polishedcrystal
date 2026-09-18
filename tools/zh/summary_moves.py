"""Compile translated summary move names indexed by the original move IDs."""
import csv
import subprocess
from PIL import Image, ImageDraw, ImageFont

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
  im=Image.new('1',(64,16));draw=ImageDraw.Draw(im);draw.fontmode='1'
  draw.text((0,10),text,font=font,fill=1,anchor='ls')
  data=[]
  for ty in range(2):
   for tx in range(8):
    for y in range(8):
     v=sum(128>>x for x in range(8) if im.getpixel((tx*8+x,ty*8+y)));data.extend((v,v))
  label='ZhSummaryMove'+str(index)
  table+=[' db BANK('+label+')',' dw '+label]
  assets+=['SECTION "Summary move '+str(index)+'", ROMX',label+'::',' db '+','.join(map(str,data))]
 (source/'data/zh/summary_moves.asm').write_text('\n'.join(table)+'\n')
 (source/'data/zh/summary_move_assets.asm').write_text('\n'.join(assets)+'\n')
