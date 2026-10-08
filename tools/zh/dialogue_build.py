"""Build ordinary dialogue through the original text script and PlaceString."""
import argparse,hashlib,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--font',type=Path,required=True);p.add_argument('--licenses',type=Path,required=True);p.add_argument('--jobs',type=int,default=4);p.add_argument('--layout',type=Path);p.add_argument('--pages',action='store_true',help='Include reviewed public page strings');p.add_argument('--characters',default='小锯鳄三合一磁怪中文测试');a=p.parse_args()
 if a.out.exists() or a.out.resolve().is_relative_to(ROOT):p.error('Use a new external directory')
 source=a.out/'source';shutil.copytree(ROOT,source,ignore=shutil.ignore_patterns('.git','local-data','local-docs','*.o','*.gbc','*.sym','*.map','*.sav','__pycache__'))
 codes=json.loads((ROOT/'tools/zh/codec-v1/encoding.json').read_text());mapping={e['char']:e['code'] for e in codes['mapping']}
 chars=set(a.characters)
 if a.pages:
  import public_text
  chars.update(public_text.characters(ROOT))
  chars.update(c for value in public_text.SUMMARY_TERMS.values() for c in value if not c.isascii())
  import public_names
  chars.update(c for row in public_names.rows(ROOT) for c in row["translation_zh-Hans"] if not c.isascii())
 chars=sorted(chars)
 extras=sorted(c for c in chars if c not in mapping)
 if len(extras)>128:raise ValueError("Too many supplemental glyphs")
 manifest=a.out/'glyphs.json';manifest.write_text(json.dumps({'glyphs':[{'id':i,'char':c} for i,c in enumerate(chars)]},ensure_ascii=False))
 subprocess.run([sys.executable,str(source/'data/zh/font/import_ttf.py'),'--font',str(a.font),'--manifest',str(manifest),'--output-root',str(source),'--baseline','10','--license-dir',str(a.licenses)],check=True)
 raw=(source/'gfx/zh/prototype.1bpp').read_bytes()
 from han_directory import make_directory
 han=[c for c in chars if c in mapping]
 lines=make_directory(mapping,han,b''.join(raw[chars.index(c)*18:(chars.index(c)+1)*18] for c in han))
 lines+=['TextExtraGlyphs:', ' db '+str(len(extras))]
 for c in extras:
  i=chars.index(c);lines+=[' db '+','.join(map(str,raw[i*18:(i+1)*18]))]
 (source/'data/zh/extra_codes.json').write_text(json.dumps({c:[10,128,128+i] for i,c in enumerate(extras)},ensure_ascii=False))
 (source/'data/zh/characters.asm').write_text(chr(10).join(lines)+chr(10))
 if a.pages:
  from summary_layout_config import emit as emit_layout, DEFAULT
  emit_layout(a.layout or DEFAULT,source)
  (a.out/'layout-input.json').write_bytes((a.layout or DEFAULT).read_bytes())
  public_text.apply(source)
  public_names.emit(source)
  public_text.emit_summary_terms(source)
 else:
  (source/"data/zh/public_names.asm").write_text("TextTranslatedNames: dw 0\n")
  import public_text
  (source/"data/zh/summary_terms.asm").write_text("\n".join("TextSummary"+name+": db $53" for name in public_text.SUMMARY_TERMS)+"\n")
 make=source/'Makefile';s=make.read_text().replace('MODIFIERS :=','MODIFIERS := -zh',1).replace('RGBASMFLAGS    =','RGBASMFLAGS    = -DLOCALE_ZH',1);make.write_text(s)
 with (a.out/'build.log').open('w') as log:subprocess.run(['make','-j'+str(a.jobs)],cwd=source,stdout=log,stderr=subprocess.STDOUT,check=True)
 rom=source/'polishedcrystal-zh-3.2.3.gbc';report={'rom':str(rom),'sha256':hashlib.sha256(rom.read_bytes()).hexdigest(),'codec_sha256':hashlib.sha256((ROOT/'tools/zh/codec-v1/encoding.json').read_bytes()).hexdigest(),'glyphs':len(chars),'scope':'public PlaceString and reviewed page strings' if a.pages else 'ordinary dialogue; original scripts and terminators'};(a.out/'report.json').write_text(json.dumps(report,indent=2))
if __name__=='__main__':main()
