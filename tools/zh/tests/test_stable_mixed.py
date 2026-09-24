"""Assert mixed-stream widths and rendered strip sequence against old compiler."""
import json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from stable_runtime import compile_dialogue,mapping

r=Path(__file__).resolve().parents[3]
g={'小':0,'锯':1,'鳄':2,'。':3}
sm={'glyphs':[[i*3+j for j in range(3)] for i in range(4)],'latin':list(range(100,328))}
cm={'A':128,'B':129,'!':159,'1':225}
codes=mapping(r);reverse={v:k for k,v in codes.items()}
for text in ['小A锯 B鳄','小!','A小B','小。A','小 A','小锯鳄','A1!']:
 asm=compile_dialogue([{'text':text}],g,cm,sm,r)
 raw=bytes(int(x) for x in asm.strip()[3:].split(','))
 parts=[];i=0
 while i<len(raw):
  b=raw[i]
  if b==10:
   glyph=((raw[i+1]&127)<<7)|(raw[i+2]&127);parts+=sm['glyphs'][glyph];i+=3
  elif b==127:parts += [65535,65535];i+=1
  elif b>=128:parts+=sm['latin'][(b-128)*2:(b-128)*2+2];i+=1
  else:
   char=reverse[raw[i:i+2]];parts+=sm['glyphs'][g[char]];i+=2
 if len(parts)%2:parts.append(65535)
 expected=[]
 for char in text:
  if char==' ':expected.extend([65535,65535])
  elif char in cm:expected.extend(sm['latin'][(cm[char]-128)*2:(cm[char]-128)*2+2])
  else:expected.extend(sm['glyphs'][g[char]])
 if len(expected)%2:expected.append(65535)
 assert parts==expected,(text,parts,expected)
print('PASS 7 mixed sequences: exact old pixel-strip order, no padding between Han/Latin/punctuation')
