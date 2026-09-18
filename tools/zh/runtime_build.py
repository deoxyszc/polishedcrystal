#!/usr/bin/env python3
"""Build isolated English or modular Fusion12 runtime sources without private content."""
import argparse,csv,hashlib,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--language',choices=['en','zh-Hans','zh-Hant'],required=True);p.add_argument('--font',type=Path);p.add_argument('--licenses',type=Path);p.add_argument('--characters',default='中文测试');p.add_argument('--out',type=Path,required=True);p.add_argument('--jobs',type=int,default=4);p.add_argument('--ui-terms',type=Path);a=p.parse_args()
 out=a.out.resolve()
 if out.exists() or out.is_relative_to(ROOT):p.error('Output must be new and outside source')
 if a.language=='en' and a.ui_terms:p.error('English builds do not consume Chinese UI terms')
 chinese=a.language!='en'
 if chinese and (not a.font or not a.licenses or not a.ui_terms):p.error('Chinese builds require --font, --licenses and --ui-terms resources')
 chars=set(a.characters) if chinese else set()
 if chinese:
  with (ROOT/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
   for row in csv.DictReader(f):
    if row['resource_kind']=='text':chars.update(c for c in row.get('translation_'+a.language,'') if not c.isascii())
  chars={c for c in chars if not c.isascii()}
  if not chars:p.error('At least one non-ASCII character is required')
 out.mkdir(parents=True);source=out/'source'
 shutil.copytree(ROOT,source,ignore=shutil.ignore_patterns('.git','__pycache__','*.pyc','*.o','*.gbc','*.sym','*.map'))
 if chinese:
  manifest=out/'glyphs.json';manifest.write_text(json.dumps({'glyphs':[{'id':i,'char':c} for i,c in enumerate(sorted(chars))]},ensure_ascii=False))
  subprocess.run([sys.executable,str(source/'data/zh/font/import_ttf.py'),'--font',str(a.font.resolve()),'--manifest',str(manifest),'--output-root',str(source),'--baseline','10','--license-dir',str(a.licenses.resolve())],check=True)
  (source/'data/zh/font/count.asm').write_text('DEF ZH_GLYPH_COUNT EQU '+str(len(chars))+chr(10))
  import summary_assets
  summary_assets.generate(source,a.font,a.ui_terms)
  import ability_assets
  ability_assets.generate(source,a.language,a.font)
  import item_panel
  item_panel.generate(source,a.language,a.font)
  import summary_moves
  summary_moves.generate(source,a.language,a.font)
  import hud_names
  hud_names.generate(source,a.language,a.font)
  hud_names.generate(source,a.language,a.font,party=True)
  import party_footer
  party_footer.generate(source,a.language,a.font)
  import move_names
  move_names.generate(source,a.language,manifest)
  import import_dialogue
  imported=import_dialogue.apply(source,a.language,manifest)
  make=source/'Makefile';s=make.read_text();s=s.replace('MODIFIERS :=','MODIFIERS := -zh',1);s=s.replace('RGBASMFLAGS    =','RGBASMFLAGS    = -DLOCALE_ZH',1);make.write_text(s)
 if not chinese:
  for name in ['font.asm','font_pages.asm','count.asm']:(source/'data/zh/font'/name).write_text('; Disabled in English build'+chr(10))
 log=out/'build.log'
 with log.open('w') as f:subprocess.run(['make','-j'+str(a.jobs)],cwd=source,stdout=f,stderr=subprocess.STDOUT,check=True)
 rom=source/('polishedcrystal'+('-zh' if chinese else '')+'-3.2.3.gbc')
 data=rom.read_bytes();expected=4 if chinese else 2
 if len(data)!=expected*1024*1024 or data[0x147]!=0x10 or data[0x149]!=3:raise ValueError('Invalid mapper header')
 report={'language':a.language,'glyph_count':len(chars),'rom':str(rom),'sha256':hashlib.sha256(data).hexdigest(),'modules':['decode','font_pages','compose','display','dialogue','names'] if chinese else ['legacy'],'text_insertion':chinese,'imported_records':imported if chinese else 0}
 (out/'report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
if __name__=='__main__':main()
