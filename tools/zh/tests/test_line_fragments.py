"""CPU-only regression for a pending 4px fragment leaking across LINE."""
from pathlib import Path
import re,subprocess,json,sys,argparse,tempfile
parser=argparse.ArgumentParser();parser.add_argument('--rom',type=Path,required=True);parser.add_argument('--runner',required=True);args=parser.parse_args()
workspace=tempfile.TemporaryDirectory();r=Path(workspace.name)
s=Path(__file__).resolve().parents[3];rom=args.rom;sym={}

for line in rom.with_suffix('.sym').read_text().splitlines():
 m=re.match(r'([0-9a-f]+):([0-9a-f]+) (\S+)$',line)
 if m:sym[m[3]]=(int(m[1],16),int(m[2],16))
a=lambda n:sym[n][1]
sys.path.insert(0,str(s/'tools/zh'))
from dialogue_text import encode
runner=args.runner
# Isolate control-flow validation from LCD/interrupt waits; visual replay is separate.
blob=bytearray(rom.read_bytes())
for label in ['PrintLetterDelay','ApplyAttrmapInVBlank','Get2bpp']:
 bank,addr=sym[label];offset=addr if bank==0 else bank*0x4000+addr-0x4000
 blob[offset]=0xc9
rom=r/'nested-cpu.gbc';rom.write_bytes(blob)
results=[]
for text in ['小{line}三@','小锯{line}三@','小{next}三@','小锯{next}三@']:
 cmd=['run 600 0','write ffff 0','write 2000 80',f'write {a("hROMBank"):x} 80','write ff70 2']
 def write(addr,values):cmd.extend(f'write {addr+i:x} {v:x}' for i,v in enumerate(values))
 write(a('wTextGlyphKeys'),[255]*172);write(a('wTextGlyphUsed'),[128]+[2]*42)
 write(a('wTextFragmentCount'),[0]);write(a('wTextPending'),[255,255])
 write(a('wTilemap'),[127]*360);write(a('wAttrmap'),[7]*360)
 write(a('wPlayerName'),encode(s,'A@'));write(a('wStringBuffer1'),encode(s,text));write(a('wTextboxFlags'),[3])
 write(0xc000,[0x18,0xfe]);write(0xc0f0,[0,0xc0])
 cmd += [f'hl {a("wTilemap")+21:x}',f'de {a("wStringBuffer1"):x}',f'cpu {a("_PlaceString"):x} c0f0','run 120 0','regs',f'read {a("wTilemap")+(301 if '{line}' in text else 61):x} 8',f'read {a("wTextFragmentCount"):x} 1',f'read {a("wTextGlyphKeys"):x} 172','quit']
 p=subprocess.run([runner,str(rom)],input='\n'.join(cmd)+'\n',capture_output=True,text=True,timeout=45,check=True)
 (r/('nested-'+str(len(results))+'.log')).write_text(p.stdout+p.stderr)
 lines=[x for x in p.stdout.splitlines() if x!='OK'];results.append(lines)
assert all('PC=c000 SP=c0f2' in x[0] and x[2]=='00 ' for x in results),results
# Previous row odd/even glyph count must never change the next row's glyphs.
def logical(lines):
 tiles=bytes.fromhex(lines[1]);keys=bytes.fromhex(lines[3])
 return [keys[((t-128)//2)*4:((t-128)//2+1)*4] if 128<=t<214 else bytes([t]) for t in tiles]
assert all(logical(results[i])==logical(results[i+1]) for i in (0,2)),[(x[1],logical(x)) for x in results]
print('LINE/NEXT clear pending half; next row identical after odd/even preceding Han counts')
