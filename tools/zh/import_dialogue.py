import csv,hashlib,re,sys
import encode
def segments(text):
 result=[];width=0
 for token in re.split(r'(<PLAYER>|[{][^}]+[}])',text):
  token=token.strip(chr(10))
  if not token:continue
  if token=='<PLAYER>':result.append({'name':'player'});width+=80
  elif token.startswith('{TEXT_RAM:') and token.endswith('}'):
   symbol=token[len('{TEXT_RAM:'):-1].strip()
   if symbol not in ('wStringBuffer1','wStringBuffer2','wBattleMonNickname','wEnemyMonNickname'):raise ValueError('Unsupported RAM text source')
   result.append({'ram_name':symbol});width+=80
  elif token.startswith('{'):
   control=token[1:-1].upper()
   if control not in ('LINE', 'PARA', 'CONT', 'NEXT', 'DONE', 'PROMPT'):raise ValueError('Unsupported control: '+token)
   result.append({'control':control});width=0
  else:result.append({'text':token});width+=sum(8 if c.isascii() else 12 for c in token)
  if width>144:raise ValueError('Line exceeds 144 pixels')
 return result
def apply(source,language,manifest):
 sys.path.insert(0,str(source/'tools/i18n'));import messages
 authority={r['id']:r for r in messages.build(source,'normal')[0]}
 glyphs=encode.load_glyphs(manifest);outputs=[];edits={};nl=chr(10);seen=set()
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
  for row in csv.DictReader(f):
   if row['id'] in seen:raise ValueError('Duplicate CSV ID')
   seen.add(row['id']);text=row.get('translation_'+language,'')
   if row['source_path']=='data/moves/names.asm':continue
   if row['source_path'] in ('data/abilities/names.asm','data/abilities/descriptions.asm') and (source/'data/zh/abilities.asm').exists():continue
   if row['id'] in ('engine/pokemon/party_menu.asm::PlacePartyNicknames.Cancel::1','engine/pokemon/party_menu.asm::ChooseAMonString::1') and (source/'data/zh/party_footer.asm').exists():continue
   if row['resource_kind']!='text' or not text.strip():continue
   if row['source_path']=='data/pokemon/names.asm':continue
   original=authority.get(row['id'])
   if not original or original['source_sha256']!=row['source_sha256'] or original['translation_view']!=row['original']:raise ValueError('Source drift: '+row['id'])
   commands=original['commands'];ops=[c['op'] for c in commands]
   # This ABI is for complete, bounded dialogue streams, never raw name tables.
   if original['translation_status']!='ready' or original.get('continuation_ids') or ops[0] not in ('text', 'ctxt', 'text_ram') or ops[-1] not in ('done', 'prompt') or set(ops)-{'text','ctxt','line','para','cont','next','done','prompt','text_ram'}:
    raise ValueError('Unsupported dialogue stream shape: '+row['id'])
   if len(commands)!=original['source_end_line']-original['source_line']+1:
    raw=original['source_text'].splitlines()
    allowed={c['line'] for c in commands}
    if any(line.strip() and not line.lstrip().startswith(';') and original['source_line']+i not in allowed for i,line in enumerate(raw)):raise ValueError('Mixed source span')
   if re.findall(r'<PLAYER>|[{][^}]+[}]',text)!=re.findall(r'<PLAYER>|[{][^}]+[}]',row['original']):raise ValueError('Control signature changed')
   entry='ZhText_'+hashlib.sha256(row['id'].encode()).hexdigest()[:16]
   body=encode.encode_segments(segments(text),glyphs,'rom_dialogue')
   outputs.append(nl.join([entry+'::',body,entry+'End::']))
   replacement=nl.join([' stop_compressing_text',' db ZH_STREAM_COMMAND',' dw '+entry+', '+entry+'End',' assert BANK('+entry+') == $80',''])
   edits.setdefault(row['source_path'],[]).append((original['source_line']-1,original['source_end_line'],replacement))
 # Finish validation/encoding before modifying the isolated source tree.
 for path,changes in edits.items():
  p=source/path;lines=p.read_text().splitlines(keepends=True);last=len(lines)
  for start,end,replacement in sorted(changes,reverse=True):
   if end>last:raise ValueError('Overlapping text spans')
   lines[start:end]=[replacement];last=start
  p.write_text(''.join(lines))
 (source/'data/zh/dialogue.asm').write_text(nl.join(outputs))
 p=source/'main.asm';s=p.read_text().replace('INCLUDE '+chr(34)+'engine/zh/dialogue.asm'+chr(34),'INCLUDE '+chr(34)+'engine/zh/dialogue.asm'+chr(34)+nl+'INCLUDE '+chr(34)+'data/zh/dialogue.asm'+chr(34));p.write_text(s)
 return len(outputs)
