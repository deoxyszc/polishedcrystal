#!/usr/bin/env python3
"""Conservative, read-only RGBDS text catalog and version diff. No import."""
import argparse,collections,hashlib,json,re,subprocess
from pathlib import Path
VERSION=2
QUOTES=re.compile(r'"((?:[^"\\]|\\.)*)"')
LABEL=re.compile(r'^([A-Za-z_][\w#@]*|\.[\w#@]+)(::?|(?=\s*$))')
START={'text','ctxt','text_start'}
END={'done','prompt','text_end','text_farend','text_asm'}
TEXT=START|END|{'line','para','cont','next','next1','page','plural','db','db_w','assert','stop_compressing_text'}
LITERAL={'db','db_w','dbw','li','dname','def_trainer','tr_mon','song_info','password_group','next','next1','page','line','para','cont','plural'}
DIRECTIVES={'section','include','incbin','def','redef','charmap','rawchar','assert','fail','warn','load','export','purge'}
def sha(s):return hashlib.sha256(s.encode()).hexdigest()
def code(raw):
 quoted=False;escape=False
 for i,c in enumerate(raw):
  if c=='"' and not escape:quoted=not quoted
  if c==';' and not quoted:return raw[:i].strip()
  escape=c=='\\' and not escape
 return raw.strip()
def write_json(path,value):path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
def jsonl(path,rows):path.write_text(''.join(json.dumps(r,ensure_ascii=False,sort_keys=True)+'\n' for r in rows))
def read_rows(path):return [json.loads(s) for s in Path(path).read_text().splitlines() if s.strip()]
def kind(path,label,mode):
 if mode=='reference':return 'text_reference'
 if 'names' in path or 'trainers/parties' in path or mode=='literal' and 'Name' in label:return 'name_or_fixed_table'
 if 'dex_entries' in path:return 'pokedex_description'
 if 'description' in path:return 'description'
 if path.startswith('maps/'):return 'map_dialogue' if mode=='dialogue' else 'map_literal'
 if 'text/' in path:return 'common_text'
 if 'menu' in path:return 'menu_text'
 return 'embedded_dialogue' if mode=='dialogue' else 'literal_table'

def extract(root):
 root=Path(root);rows=[];diagnostics=[];coverage=[]
 for path in sorted(root.rglob('*.asm')):
  relative=path.relative_to(root).as_posix()
  if any(x in relative.split('/') for x in ('.git','build','work','outputs')):continue
  lines=path.read_text(encoding='utf-8').splitlines(keepends=True)
  global_label='<file>';label=global_label;ordinal=collections.Counter();block=[];conditions=[];macros=0;mode='dialogue';block_context=[];captured=set();excluded=0
  def flush(reason=None):
   nonlocal block
   if not block:return
   commands=[];tokens=[];strings=[]
   for n,raw,c in block:
    parts=c.split(None,1);op=parts[0];args=parts[1] if len(parts)>1 else ''
    commands.append({'op':op,'args':args,'line':n})
    tokens.append({'kind':'command','value':op,'args':args})
    for match in QUOTES.finditer(c):
     strings.append(match[1])
     for value in re.findall(r'<[^>]+>|@|#',match[1]):tokens.append({'kind':'placeholder' if value not in ('@','#') else 'charmap_token','value':value})
    if op.startswith('text_') and op not in ('text_start','text_end'):tokens.append({'kind':'dynamic_or_command','value':op,'args':args})
    captured.add(n)
   ordinal[label]+=1
   raw=''.join(lines[block[0][0]-1:block[-1][0]])
   issues=list(block_context)
   if reason:issues.append(reason)
   consumer=kind(relative,label,mode)
   rows.append({'schema_version':VERSION,'id':relative+'::'+label+'::'+str(ordinal[label]),'source_path':relative,'label':label,'ordinal':ordinal[label],'source_line':block[0][0],'source_end_line':block[-1][0],'source_text':raw,'source_sha256':sha(raw),'display_text':'\n'.join(strings),'commands':commands,'tokens':tokens,'consumer':{'kind':consumer,'supported':False,'reason':'catalog discovery is not runtime admission'},'diagnostics':issues,'auto_admit':False})
   block=[]
  for n,raw in enumerate(lines,1):
   c=code(raw)
   if not c:continue
   op=c.split()[0];lower=op.lower()
   if lower in ('if','elif','else','endc','macro','endm','rept','endr','for'):
    flush('control or macro boundary')
    if lower=='if':conditions.append(c)
    elif lower in ('else','elif'):
     if conditions:conditions[-1]=conditions[-1].split(' => ')[0]+' => '+c
    elif lower=='endc':
     if conditions:conditions.pop()
    elif lower in ('macro','rept','for'):macros+=1
    elif lower in ('endm','endr'):macros=max(0,macros-1)
    if QUOTES.search(c):diagnostics.append({'source_path':relative,'line':n,'kind':'compile_time_string','source_text':raw})
    continue
   match=LABEL.match(c)
   if match and (':' in match[0] or c.startswith('.') or not raw[:1].isspace() and op not in TEXT and lower not in DIRECTIVES):
    flush('label boundary without explicit terminator')
    name=match[1]
    if name.startswith('.'):label=global_label+name
    else:global_label=name;label=name
    c=c[match.end():].strip()
    if not c:continue
    op=c.split()[0];lower=op.lower()
   if block and not (op in TEXT or op.startswith('text_')):flush('unsupported boundary: '+op)
   accepted=op in START|END or bool(block) and (op in TEXT or op.startswith('text_')) or QUOTES.search(c) and op in LITERAL or op.startswith('text_')
   if accepted:
    if not block:
     mode='reference' if op in ('text_far','text_farend') or op in END else ('dialogue' if op in START or op.startswith('text_') else 'literal')
     block_context=(['conditional compilation: '+' / '.join(conditions)] if conditions else [])+(['macro expansion required'] if macros else [])
    block.append((n,raw,c))
    quoted=QUOTES.findall(c)
    if op in END or mode=='literal' or quoted and quoted[-1].endswith('@'):flush()
   elif QUOTES.search(c):
    excluded+=1
    diagnostics.append({'source_path':relative,'line':n,'kind':'non_text_directive' if lower in DIRECTIVES else 'unparsed_quoted_statement','op':op,'source_text':raw})
  flush('EOF without explicit terminator')
  if captured or excluded:coverage.append({'source_path':relative,'lines':len(lines),'captured_command_lines':len(captured),'other_quoted_statements':excluded})
 ids=[r['id'] for r in rows]
 if len(ids)!=len(set(ids)):raise ValueError('duplicate IDs')
 return rows,diagnostics,coverage

def difference(old,new):
 a={r['id']:r for r in old};b={r['id']:r for r in new};removed=sorted(a.keys()-b.keys());added=sorted(b.keys()-a.keys())
 changes=[i for i in sorted(a.keys()&b.keys()) if a[i]['source_sha256']!=b[i]['source_sha256']]
 candidates=[]
 for previous in removed:
  matches=[i for i in added if a[previous]['source_sha256']==b[i]['source_sha256']]
  if matches:candidates.append({'old_id':previous,'candidate_new_ids':matches,'status':'manual_review_only'})
 return {'schema_version':VERSION,'added':added,'removed':removed,'source_changed':changes,'possible_moves_or_renames':candidates,'unchanged_count':len(a.keys()&b.keys())-len(changes)}
def migrate(records,catalog):
 byid={r['id']:r for r in catalog};result=[]
 for old in records:
  row=byid.get(old['id']);exact=[r for r in catalog if r['source_sha256']==old['source_sha256']]
  status='exact' if row and row['source_sha256']==old['source_sha256'] else 'manual_migration_required'
  result.append({'id':old['id'],'status':status,'same_id_present':row is not None,'exact_hash_candidates':[r['id'] for r in exact]})
 return result
def main():
 ap=argparse.ArgumentParser();sub=ap.add_subparsers(dest='command',required=True)
 ex=sub.add_parser('extract');ex.add_argument('--source',type=Path,required=True);ex.add_argument('--out',type=Path,required=True);ex.add_argument('--translations',type=Path);ex.add_argument('--source-commit',help='declared archive commit; recorded separately from actual tree hash')
 df=sub.add_parser('diff');df.add_argument('old');df.add_argument('new');df.add_argument('--out',type=Path,required=True)
 a=ap.parse_args()
 if a.command=='diff':write_json(a.out,difference(read_rows(a.old),read_rows(a.new)));return
 if a.out.resolve().is_relative_to(a.source.resolve()):raise ValueError('output must be outside inspected source tree')
 rows,diag,coverage=extract(a.source);a.out.mkdir(parents=True,exist_ok=True)
 jsonl(a.out/'catalog.jsonl',rows);jsonl(a.out/'diagnostics.jsonl',diag);write_json(a.out/'coverage.json',coverage)
 revision=subprocess.run(['git','-C',str(a.source),'rev-parse','HEAD'],capture_output=True,text=True).stdout.strip() if (a.source/'.git').exists() else None
 if a.source_commit and not re.fullmatch('[0-9a-f]{40}',a.source_commit):raise ValueError('source commit requires full SHA')
 tree=[{'path':p.relative_to(a.source).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(a.source.rglob('*.asm')) if '.git'not in p.parts]
 write_json(a.out/'source-files.json',tree)
 summary={'schema_version':VERSION,'source_revision':revision,'tool_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'records':len(rows),'record_diagnostics':sum(bool(r['diagnostics']) for r in rows),'quoted_diagnostics':dict(collections.Counter(d['kind'] for d in diag)),'consumers':dict(collections.Counter(r['consumer']['kind'] for r in rows))}
 summary.update(declared_source_commit=a.source_commit,source_tree_sha256=sha(json.dumps(tree,sort_keys=True)))
 write_json(a.out/'summary.json',summary)
 if a.translations:write_json(a.out/'translation-migration.json',migrate([json.loads(p.read_text()) for p in sorted(a.translations.glob('*.json'))],rows))
 print(json.dumps(summary,ensure_ascii=False))
if __name__=='__main__':main()
