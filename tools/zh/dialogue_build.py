"""Build ordinary dialogue through the original text script and PlaceString."""
import argparse,hashlib,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--font',type=Path,required=True);p.add_argument('--licenses',type=Path,required=True);p.add_argument('--characters',default='小锯鳄三合一磁怪中文测试');a=p.parse_args()
 if a.out.exists() or a.out.resolve().is_relative_to(ROOT):p.error('Use a new external directory')
 source=a.out/'source';shutil.copytree(ROOT,source,ignore=shutil.ignore_patterns('.git','local-data','local-docs','*.o','*.gbc','*.sym','*.map','*.sav','__pycache__'))
 codes=json.loads((ROOT/'tools/zh/codec-v1/encoding.json').read_text());mapping={e['char']:e['code'] for e in codes['mapping']}
 chars=sorted(set(a.characters));assert all(c in mapping for c in chars)
 manifest=a.out/'glyphs.json';manifest.write_text(json.dumps({'glyphs':[{'id':i,'char':c} for i,c in enumerate(chars)]},ensure_ascii=False))
 subprocess.run([sys.executable,str(source/'data/zh/font/import_ttf.py'),'--font',str(a.font),'--manifest',str(manifest),'--output-root',str(source),'--baseline','10','--license-dir',str(a.licenses)],check=True)
 raw=(source/'gfx/zh/prototype.1bpp').read_bytes();lines=['TextHanDirectory:']
 for i,c in enumerate(chars):lines += [' db '+','.join(map(str,bytes.fromhex(mapping[c])+raw[i*18:(i+1)*18]))]
 lines+=[' db 0','TextSpaceStrips:',' ds 12,0','TextLatinStrips:']
 from PIL import Image
 im=Image.open(source/'gfx/font/normal.png').convert('L')
 for code in range(114):
  for half in range(2):
   rows=[0]*4+[sum((im.getpixel((code%16*8+half*4+x,code//16*8+y))<128)<<(3-x) for x in range(4)) for y in range(8)]
   lines+=[' db '+','.join(str(rows[y]*16+rows[y+1]) for y in range(0,12,2))]
 (source/'data/zh/characters.asm').write_text(chr(10).join(lines)+chr(10))
 make=source/'Makefile';s=make.read_text().replace('MODIFIERS :=','MODIFIERS := -zh',1).replace('RGBASMFLAGS    =','RGBASMFLAGS    = -DLOCALE_ZH',1);make.write_text(s)
 with (a.out/'build.log').open('w') as log:subprocess.run(['make','-j4'],cwd=source,stdout=log,stderr=subprocess.STDOUT,check=True)
 rom=source/'polishedcrystal-zh-3.2.3.gbc';report={'rom':str(rom),'sha256':hashlib.sha256(rom.read_bytes()).hexdigest(),'codec_sha256':hashlib.sha256((ROOT/'tools/zh/codec-v1/encoding.json').read_bytes()).hexdigest(),'glyphs':len(chars),'scope':'ordinary dialogue only; original scripts and terminators'};(a.out/'report.json').write_text(json.dumps(report,indent=2))
if __name__=='__main__':main()
