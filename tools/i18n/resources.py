#!/usr/bin/env python3
"""Inventory graphical/text resources separately from translatable ASM messages."""
import argparse,collections,hashlib,json,re,subprocess
from pathlib import Path
EXT={'.png','.1bpp','.2bpp','.ttf','.otf','.tilemap','.attrmap','.txt'}
# Visually verified at the stated source SHA only; never infer OCR from a name.
REVIEW_SHA='f22d31a52cbbf1387d27ba63f5bf2fa959955d37'
CONFIRMED={'gfx/title/logo.png':'Pokemon / Polished Crystal logo','gfx/title/crystal.png':'The end','gfx/credits/theend.png':'THE END','gfx/splash/logo2.png':'GAME FREAK presents'}
NONTEXT={'gfx/splash/logo1.png':'logo symbol, no lettering','gfx/signs/city.png':'sign border, no lettering'}

def inventory(root,review_sha=None):
 root=Path(root).resolve();r=subprocess.run(['git','-C',str(root),'ls-files','-z'],capture_output=True)
 paths=sorted(s for s in r.stdout.decode().split('\0') if s) if r.returncode==0 else sorted(p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and '.git' not in p.parts)
 refs=collections.defaultdict(list)
 for rel in paths:
  if not rel.endswith('.asm'):continue
  p=root/rel
  if not p.is_file():continue
  for n,line in enumerate(p.read_text().splitlines(),1):
   for match in re.finditer(r'\bINCBIN\s+"([^"]+)"',line,re.I):
    target=match[1];refs[target].append({'source_path':rel,'line':n,'directive':'INCBIN','target':target})
 def equivalent(path):
  stem=path
  for suffix in ('.lz','.lzp','.1bpp','.2bpp','.png'):
   if stem.endswith(suffix):stem=stem[:-len(suffix)]
  return stem
 rows=[]
 for rel in paths:
  p=root/rel
  if not rel.startswith('gfx/') or p.suffix.lower() not in EXT or not p.is_file():continue
  status='needs_manual';kind='graphical_asset';note='No OCR performed; filename is not proof of visible text.'
  if 'font' in Path(rel).parts:kind='font_glyph_resource';status='candidate'
  elif p.suffix in ('.ttf','.otf','.1bpp','.2bpp'):kind='font_or_tile_bitmap'
  elif p.suffix in ('.tilemap','.attrmap'):kind='tile_layout_or_attributes';status='nontext';note='Layout bytes, not prose; referenced glyph assets require separate review.'
  elif p.suffix=='.txt':kind='text_asset';status='candidate'
  elif any(word in rel for word in ('logo','title','credits','theend','sign')):status='candidate'
  verified=False
  if review_sha==REVIEW_SHA and rel in CONFIRMED|NONTEXT:
   original=subprocess.run(['git','-C',str(root),'show',REVIEW_SHA+':'+rel],capture_output=True)
   verified=original.returncode==0 and hashlib.sha256(original.stdout).digest()==hashlib.sha256(p.read_bytes()).digest()
  if verified and rel in CONFIRMED:status='confirmed_text';note=CONFIRMED[rel]+' (visual review; not editable text extraction).'
  elif verified and rel in NONTEXT:status='nontext';note=NONTEXT[rel]+' (visual review).'
  direct=refs.get(rel,[]);generated=[ref for target,items in refs.items() if target!=rel and equivalent(target)==equivalent(rel) for ref in items]
  rows.append({'id':'resource::'+rel,'source_path':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'resource_type':kind,'status':status,'review_note':note,'review_source_commit':review_sha if status in ('confirmed_text','nontext') and rel in CONFIRMED|NONTEXT else None,'direct_references':direct,'possible_generated_references':generated,'translatable_message':False,'automatic_text_replacement':False})
 return rows

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--review-source-commit');a=ap.parse_args()
 if a.out.resolve().is_relative_to(a.source.resolve()):raise ValueError('output must be outside source')
 rows=inventory(a.source,a.review_source_commit);a.out.mkdir(parents=True,exist_ok=True)
 (a.out/'resources.jsonl').write_text(''.join(json.dumps(r,ensure_ascii=False,sort_keys=True)+'\n' for r in rows))
 summary={'resources':len(rows),'statuses':dict(collections.Counter(r['status'] for r in rows)),'resource_types':dict(collections.Counter(r['resource_type'] for r in rows)),'automatic_text_replacement':False}
 (a.out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary))
if __name__=='__main__':main()
