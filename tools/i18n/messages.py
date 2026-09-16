#!/usr/bin/env python3
"""Profile-selected translation view. Original catalog remains source authority."""
import argparse,collections,json,re,tempfile
from pathlib import Path
import catalog

PROFILES={'normal':set(),'faithful':{'FAITHFUL'},'debug':{'DEBUG'}}
# Explicit build flags from this target's Makefile, not arbitrary source symbols.
BUILD_FLAGS={'DEBUG','FAITHFUL','MONOCHROME','NOIR','HGSS','VIRTUAL_CONSOLE'}
def select(lines,defines):
 stack=[];result=[];evidence=[];macro=0
 for number,raw in enumerate(lines,1):
  c=catalog.code(raw);op=c.split()[0].lower() if c else ''
  closing_known=bool(stack) and all(s['truth'] is not None for s in stack)
  if op=='macro':macro+=1
  if op=='endm':macro=max(0,macro-1)
  match=re.fullmatch(r'if\s+(!?)DEF\((\w+)\)',c)
  if op=='if' and not macro:
   truth=(match[2] in defines) ^ bool(match[1]) if match and match[2] in BUILD_FLAGS else None
   stack.append({'expression':c,'truth':truth,'else':False})
  elif op in ('else','elif') and stack and not macro:
   if op=='else':stack[-1]['else']=True
   else:stack[-1]['truth']=None
  elif op=='endc' and stack and not macro:stack.pop()
  active=all(s['truth'] is None or (not s['truth'] if s['else'] else s['truth']) for s in stack)
  conditional=op in ('if','else','elif','endc') and not macro
  known=conditional and (closing_known if op=='endc' else all(s['truth'] is not None for s in stack))
  if not active or known:
   result.append('\n' if raw.endswith('\n') else '')
   evidence.append({'line':number,'status':'selected_condition_directive' if conditional else 'inactive_profile_branch','conditions':[dict(x) for x in stack]})
  else:result.append(raw)
 return result,evidence

def build(source,profile,old_catalog=None,old_diagnostics=None):
 source=Path(source);defines=PROFILES[profile];conditions=[];original={}
 with tempfile.TemporaryDirectory() as tmp:
  root=Path(tmp)
  for p in sorted(source.rglob('*.asm')):
   if '.git'in p.parts:continue
   rel=p.relative_to(source);lines=p.read_text().splitlines(keepends=True);original[rel.as_posix()]=lines
   selected,trace=select(lines,defines);dest=root/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(selected))
   conditions.extend({'source_path':rel.as_posix(),**item} for item in trace)
  rows,diagnostics,_=catalog.extract(root)
 for row in rows:
  raw=''.join(original[row['source_path']][row['source_line']-1:row['source_end_line']])
  row['selected_source_sha256']=row['source_sha256'];row['source_text']=raw;row['source_sha256']=catalog.sha(raw)
  row['profile']=profile;row['active_defines']=sorted(defines)
  row['source_segments']=[{'line':c['line'],'source_text':original[row['source_path']][c['line']-1],'sha256':catalog.sha(original[row['source_path']][c['line']-1])} for c in row['commands']]
  row['translation_status']='ready' if row['display_text'] and not row['diagnostics'] and not any('\\' in c['args'] for c in row['commands']) else 'requires_review'
  if not row['display_text']:row['translation_status']='reference_or_control_only'
  # Compile-time interpolation remains an immutable typed token, not a guessed
  # numeric expansion; translators can move it only under a later importer rule.
  for command in row['commands']:
   for token in re.findall(r'\{[^{}]+\}',command['args']):row['tokens'].append({'kind':'compile_time_interpolation','value':token,'source_line':command['line']})
   if 'STRFMT(' in command['args']:
    row['tokens'].append({'kind':'compile_time_format','value':command['args'],'source_line':command['line']})
    row['translation_status']='ready_with_typed_format' if not row['diagnostics'] else 'requires_review'
    row.setdefault('format_instructions',[]).append('Translate quoted format string; preserve format specifiers and symbolic argument expressions: '+command['args'])
    row.setdefault('format_templates',[]).append({'template':catalog.QUOTES.findall(command['args'])[0],'expression':command['args'],'line':command['line']})
  if any(c['op']=='text_asm' for c in row['commands']):row['translation_status']='runtime_continuation'
  if any('macro expansion' in d for d in row['diagnostics']):row['translation_status']='macro_template'
  if row['source_path'].startswith('macros/'):row['translation_status']='macro_template'
  row['runtime_admitted']=False
  row['translation_constraints']={'consumer_kind':row['consumer']['kind'],'purpose':'translation draft only; no runtime insertion approval','preserve_tokens':True,'source_segments_meaning':'selected command lines; full conditional and non-command provenance is source_text'}
  if row['consumer']['kind'] in ('name_or_fixed_table','literal_table','map_literal','pokedex_description','menu_text'):
   row['translation_constraints']['layout_review_required']=True
 # Join known shared-label fallthrough for translation context only; never
 # create overlapping source replacement spans in the authority catalog.
 for i,row in enumerate(rows[:-1]):
  if row['commands'] and row['commands'][-1]['op']=='stop_compressing_text':
   following=rows[i+1]
   if following['source_path']==row['source_path']:
    row['continuation_ids']=[following['id']];row['display_text']+='\n'+following['display_text'];row['tokens']+=following['tokens'];row['diagnostics']=[d for d in row['diagnostics'] if d.startswith('label boundary') is False]
    known={'WildPokemonAppearedText':'LegendaryAppearedText','BattleText_WildFled':'BattleText_LegendaryFled'}
    row['translation_status']='ready_with_shared_tail' if row['source_path']=='data/text/battle.asm' and known.get(row['label'])==following['label'] and following['commands'][0]['op']=='text_ram' else 'shared_fallthrough_review'
    row['source_segments']+=following['source_segments'];row['selected_message_commands']=row['commands']+following['commands']
 for row in rows:
  segments=[]
  for command in row.get('selected_message_commands',row['commands']):
   op=command['op'];args=command['args']
   if op.startswith('text_') and op not in ('text_start','text_end'):
    segments.append({'kind':'dynamic' if op in ('text_ram','text_decimal','text_today') else 'command','op':op,'args':args,'display':'{'+op.upper()+(':'+args if args else '')+'}','source_line':command['line']})
   else:
    if op not in ('text','ctxt','db','db_w'):segments.append({'kind':'control','op':op,'args':args,'source_line':command['line']})
    for literal in catalog.QUOTES.findall(args):segments.append({'kind':'text','value':literal,'source_line':command['line']})
  row['translation_segments']=segments
  row['translation_view']='\n'.join(s.get('value',s.get('display','{'+s.get('op','')+'}')) for s in segments)
 dispositions=[]
 for old in old_catalog or []:
  if not old['diagnostics']:continue
  matches=[r for r in rows if r['source_path']==old['source_path'] and r['source_line']<=old['source_line']<=r['source_end_line']]
  inactive=any(e['source_path']==old['source_path'] and e['line']==old['source_line'] and e['status']=='inactive_profile_branch' for e in conditions)
  dispositions.append({'old_id':old['id'],'old_diagnostics':old['diagnostics'],'status':'inactive_profile_branch' if inactive else ('mapped' if matches else 'review_required'),'message_ids':[r['id'] for r in matches],'current_translation_status':[r['translation_status'] for r in matches],'evidence':[{'path':r['source_path'],'start':r['source_line'],'end':r['source_end_line'],'source_sha256':r['source_sha256']} for r in matches],'resolution':'explicit profile branch exclusion' if inactive else 'see current status: complete message, macro definition, or runtime continuation; mapped does not itself mean translatable'})
 metadata=[]
 for d in old_diagnostics or diagnostics:
  if d['kind']!='unparsed_quoted_statement':continue
  p=d['source_path'];op=d.get('op','');raw=d['source_text']
  if op=='_dtxt' and p=='macros/scripts/text.asm':reason='text_macro_control_template'
  elif 'BANK(' in raw or op in ('farbank','anonbankpush'):reason='bank_or_section_metadata'
  elif op in ('_redef_current_label','println','static_assert') or op.startswith('"') or op.startswith('STRSLICE'):reason='compile_time_diagnostic_or_label'
  else:reason='unresolved'
  metadata.append({**d,'classification':reason,'source_sha256':catalog.sha(raw)})
 return rows,conditions,dispositions,metadata

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--profile',choices=PROFILES,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--old-catalog',type=Path);ap.add_argument('--old-diagnostics',type=Path);a=ap.parse_args()
 if a.out.resolve().is_relative_to(a.source.resolve()):raise ValueError('external output required')
 rows,conditions,dispositions,metadata=build(a.source,a.profile,catalog.read_rows(a.old_catalog) if a.old_catalog else None,catalog.read_rows(a.old_diagnostics) if a.old_diagnostics else None)
 a.out.mkdir(parents=True,exist_ok=True)
 for name,data in [('messages',rows),('conditions',conditions),('diagnostic-dispositions',dispositions),('quoted-classifications',metadata)]:catalog.jsonl(a.out/(name+'.jsonl'),data)
 catalog.jsonl(a.out/'translation-ready.jsonl',[r for r in rows if r['translation_status'] in ('ready','ready_with_typed_format','ready_with_shared_tail')])
 summary={'profile':a.profile,'messages':len(rows),'statuses':dict(collections.Counter(r['translation_status'] for r in rows)),'old_diagnostics':dict(collections.Counter(r['status'] for r in dispositions)),'quoted':dict(collections.Counter(r['classification'] for r in metadata))}
 catalog.write_json(a.out/'summary.json',summary);print(json.dumps(summary))
if __name__=='__main__':main()
