"""Encode dialogue with the established Chinese table and original text controls."""
import json,re
from pathlib import Path
from cache_text import load_charmap

def encode(source,text):
 table=json.loads((source/'tools/zh/codec-v1/encoding.json').read_text())
 codes={e['char']:bytes.fromhex(e['code']) for e in table['mapping']}
 extra=source/'data/zh/extra_codes.json'
 if extra.exists():codes.update({c:bytes(v) for c,v in json.loads(extra.read_text()).items()})
 cm=load_charmap(source);out=bytearray()
 symbols={}
 for line in (source/'constants/charmap.asm').read_text().splitlines():
  fields=line.split(chr(34))
  if len(fields)>=3 and 'charmap ' in fields[0] and '$' in fields[2]:
   symbols[fields[1]]=int(fields[2].split('$',1)[1].split()[0],16)
 controls={name:symbols['<'+name.upper()+'>'] for name in ('line','next','para','cont','done','prompt')}
 for token in re.split(r'([{}][^{}]*[}]|<PLAYER>|<RIVAL>)',text):
  if not token:continue
  if token.startswith('{'):
   key=token[1:-1].lower()
   if key not in controls:raise ValueError('Unsupported original control: '+token)
   out.append(controls[key]);continue
  if token in ('<PLAYER>','<RIVAL>'):
   lines=(source/'constants/charmap.asm').read_text().splitlines()
   line=next(l for l in lines if '"'+token+'"' in l)
   out.append(int(line.rsplit('$',1)[1].split()[0],16));continue
  for c in token:
   if c in codes:out.extend(codes[c])
   elif c in cm:out.append(cm[c])
   else:raise ValueError('Character absent from established codec: '+c)
 return bytes(out)
