#!/usr/bin/env python3
"""Build isolated English or modular Fusion12 runtime sources without private content."""
import argparse,csv,hashlib,json,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--language',choices=['en','zh-Hans','zh-Hant'],required=True);p.add_argument('--font',type=Path);p.add_argument('--licenses',type=Path);p.add_argument('--characters',default='中文测试');p.add_argument('--out',type=Path,required=True);p.add_argument('--jobs',type=int,default=4);p.add_argument('--layout',type=Path,help='Editor summary-pink layout JSON');a=p.parse_args()
 out=a.out.resolve()
 if out.exists() or out.is_relative_to(ROOT):p.error('Output must be new and outside source')
 chinese=a.language!='en'
 if chinese:
  if a.language!='zh-Hans':p.error('Traditional Chinese page translations are not available')
  if not a.font or not a.licenses:p.error('Chinese builds require --font and --licenses')
  command=[sys.executable,str(ROOT/'tools/zh/dialogue_build.py'),'--pages',
           '--font',str(a.font),'--licenses',str(a.licenses),'--out',str(out),
           '--characters',a.characters,'--jobs',str(a.jobs)]
  if a.layout:command+=['--layout',str(a.layout)]
  subprocess.run(command,check=True)
  return
 chars=set()
 out.mkdir(parents=True);source=out/'source'
 shutil.copytree(ROOT,source,ignore=shutil.ignore_patterns('.git','__pycache__','*.pyc','*.o','*.gbc','*.sym','*.map','local-data','local-docs','*.sav'))
 if not chinese:
  for name in ['font.asm','font_pages.asm','count.asm']:(source/'data/zh/font'/name).write_text('; Disabled in English build'+chr(10))
 log=out/'build.log'
 with log.open('w') as f:subprocess.run(['make','-j'+str(a.jobs)],cwd=source,stdout=f,stderr=subprocess.STDOUT,check=True)
 rom=source/('polishedcrystal'+('-zh' if chinese else '')+'-3.2.3.gbc')
 data=rom.read_bytes();expected=4 if chinese else 2
 if len(data)!=expected*1024*1024 or data[0x147]!=0x10 or data[0x149]!=3:raise ValueError('Invalid mapper header')
 report={'language':a.language,'glyph_count':len(chars),'rom':str(rom),'sha256':hashlib.sha256(data).hexdigest(),'modules':['font_strips','glyph_cache','cache_backup','place_string','dialogue','names'] if chinese else ['legacy'],'text_insertion':chinese,'imported_records':imported if chinese else 0}
 (out/'report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
if __name__=='__main__':main()
