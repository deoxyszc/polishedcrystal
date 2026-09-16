#!/usr/bin/env python3
"""Reconstruct source files from non-text slices plus verified catalog blocks."""
import argparse,hashlib,json,shutil
from pathlib import Path
import catalog

def reconstruct(source,rows,original_only=False,require_complete=False):
 source=Path(source).resolve();baseline,_,_=catalog.extract(source)
 index={r['id']:r for r in baseline};groups={};seen=set();trace=[]
 if require_complete and {r['id'] for r in rows}!=set(index):raise ValueError('catalog coverage incomplete')
 for row in rows:
  ident=row['id']
  if ident in seen:raise ValueError('duplicate ID: '+ident)
  seen.add(ident)
  if ident not in index:raise ValueError('unknown label/ordinal: '+ident)
  old=index[ident]
  for key in ('source_path','label','ordinal','source_line','source_end_line','source_sha256'):
   if row[key]!=old[key]:raise ValueError('source identity/span/hash drift: '+ident+' '+key)
  if catalog.sha(row['source_text'])!=old['source_sha256']:raise ValueError('original source_text/hash mismatch')
  # Commands are the editable catalog representation. Original span remains an
  # immutable provenance anchor. Never accept changed raw source as its own proof.
  commands=row['commands'];original=old['commands']
  if len(commands)!=len(original):raise ValueError('command insertion/deletion unsupported')
  changed=commands!=original
  if changed and original_only:raise ValueError('original-only mode rejects catalog changes')
  if changed and (old['diagnostics'] or old['consumer']['kind'] not in ('map_dialogue','common_text')):raise ValueError('ambiguous/unsupported edit consumer')
  lines=old['source_text'].splitlines(keepends=True)
  for cmd,previous in zip(commands,original):
   if cmd['op']!=previous['op'] or cmd['line']!=previous['line']:raise ValueError('control order/position change unsupported')
   args=cmd['args'];prior=previous['args']
   if '\n' in args or '\r' in args:raise ValueError('multiline command args')
   # Replacing quoted literal content is supported; preserve everything outside
   # quotes and every dynamic/charmap token in order during source reconstruction.
   strip=lambda s:catalog.QUOTES.sub('""',s)
   tokens=lambda s:[v for q in catalog.QUOTES.findall(s) for v in __import__('re').findall(r'<[^>]+>|@|#',q)]
   if strip(args)!=strip(prior) or tokens(args)!=tokens(prior):raise ValueError('control/dynamic parameters changed')
   offset=cmd['line']-old['source_line'];raw=lines[offset]
   oldcode=catalog.code(raw)
   if ':' in oldcode.split()[0]:
    match=catalog.LABEL.match(oldcode);oldcode=oldcode[match.end():].strip()
   start=raw.find(oldcode)
   if start<0:raise ValueError('command template not found')
   # Rebuild op/args from catalog, retain source indentation, comments/newline.
   newcode=cmd['op']+(' '+args if args else '')
   if args==prior:
    # Preserve original op/arg whitespace without bypassing catalog values.
    suffix=oldcode[len(cmd['op']):];space=suffix[:len(suffix)-len(suffix.lstrip())]
    newcode=cmd['op']+space+args
   lines[offset]=raw[:start]+newcode+raw[start+len(oldcode):]
  replacement=''.join(lines)
  groups.setdefault(old['source_path'],[]).append((old,replacement))
  trace.append({'id':ident,'source_sha256':old['source_sha256'],'replacement_sha256':catalog.sha(replacement),'changed':replacement!=old['source_text'],'commands_consumed':len(commands)})
 output={}
 for path,blocks in groups.items():
  raw=(source/path).read_text();lines=raw.splitlines(keepends=True);cursor=0;parts=[]
  for row,text in sorted(blocks,key=lambda pair:pair[0]['source_line']):
   begin=row['source_line']-1;end=row['source_end_line']
   if begin<cursor:raise ValueError('overlapping spans: '+path)
   if ''.join(lines[begin:end])!=row['source_text']:raise ValueError('source slice drift')
   parts.extend((''.join(lines[cursor:begin]),text));cursor=end
  parts.append(''.join(lines[cursor:]));output[path]=''.join(parts)
 return output,trace

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--catalog',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--report',type=Path);ap.add_argument('--mode',choices=['original','literal-edit'],default='original');ap.add_argument('--allow-partial',action='store_true');a=ap.parse_args()
 source=a.source.resolve();out=a.out.resolve()
 if out.exists() or out.is_relative_to(source) or source.is_relative_to(out):raise ValueError('fresh disjoint output directory required')
 files,trace=reconstruct(source,catalog.read_rows(a.catalog),a.mode=='original',not a.allow_partial)
 shutil.copytree(source,out,ignore=shutil.ignore_patterns('.git','*.o','*.gbc','*.sym','*.map','__pycache__'))
 for path,text in files.items():(out/path).write_text(text)
 report={'records_reconstructed':len(trace),'files_reconstructed':len(files),'changed_records':sum(t['changed'] for t in trace),'trace':trace}
 report.update(mode=a.mode,require_complete=not a.allow_partial)
 catalog.write_json(a.report or out.parent/(out.name+'-roundtrip.json'),report)
 print(json.dumps({k:v for k,v in report.items() if k!='trace'}))
if __name__=='__main__':main()
