import json
from stable_runtime import menu_text
from cache_text import load_charmap
TERMS={'Exp':'经验','Need':'还需','LevelUp':'升到','Level':'级','OT':'初训家/','Slash':'/'}
TERMS['Max']='100级'
CHARACTERS=''.join(TERMS.values())
def generate(source,manifest):
 glyphs={e['char']:e['id'] for e in json.loads(manifest.read_text())['glyphs']}
 cm=load_charmap(source);maps=json.loads((source/'data/zh/font/compiled.json').read_text());lines=['ZhSummaryGlyphStrips:'];exceptions=[]
 for i,row in enumerate(maps['summary_pink']['glyphs']):
  if row==list(range(row[0],row[0]+3)) and row[2]<32768:lines += [f' dw ${32768|row[0]:04x}']
  else:
   label='ZhSummaryGlyphException'+str(i);lines+=[' dw '+label];exceptions += [label+':',' db '+','.join(str(b) for k in row for b in (k>>8,k&255))]
 lines+=exceptions+['ZhSummaryLatinStrips:',' db '+','.join(str(b) for k in maps['summary_pink']['latin'] for b in (k>>8,k&255))]
 for key,text in TERMS.items():
  data=menu_text(text,glyphs,cm,source,style=2,width_tiles=12)+bytes([83]);lines += ['ZhSummary'+key+':',' db '+','.join(map(str,data))]
 lines += ['ZhSummaryTabKeys:', ' dw '+','.join(map(str,maps['summary_tab']['keys']))]
 (source/'data/zh/summary_pink.asm').write_text(chr(10).join(lines)+chr(10))
