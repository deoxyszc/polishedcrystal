import csv,hashlib,re,sys
import encode
ADAPTERS={
 'maps/NewBarkTown.asm::ElmsLabSignText::1':('maps/NewBarkTown.asm','ElmsLabSignText','bg_event  3,  3, BGEVENT_JUMPTEXT, ElmsLabSignText'),
 'maps/NewBarkTown.asm::PlayersHouseSignText::1':('maps/NewBarkTown.asm','PlayersHouseSignText','bg_event 13,  5, BGEVENT_JUMPTEXT, PlayersHouseSignText'),
 'maps/CherrygrovePokeCenter1F.asm::CherrygrovePokeCenter1FFisherText::1':('maps/CherrygrovePokeCenter1F.asm','CherrygrovePokeCenter1FFisherText','OBJECTTYPE_COMMAND, jumptextfaceplayer, CherrygrovePokeCenter1FFisherText, -1'),
}
def segments(text):
 result=[];width=0
 for token in re.split(r'(<PLAYER>|[{][^}]+[}])',text):
  token=token.strip(chr(10))
  if not token:continue
  if token=='<PLAYER>':result.append({'name':'player'});width+=80
  elif token.startswith('{'):
   control=token[1:-1].upper()
   if control not in ('LINE','PARA','DONE'):raise ValueError('Unsupported control: '+token)
   result.append({'control':control});width=0
  else:result.append({'text':token});width+=sum(8 if c.isascii() else 12 for c in token)
  if width>144:raise ValueError('Line exceeds 144 pixels')
 return result
def apply(source,language,manifest):
 sys.path.insert(0,str(source/'tools/i18n'));import messages
 authority={r['id']:r for r in messages.build(source,'normal')[0]}
 glyphs=encode.load_glyphs(manifest);outputs=[];nl=chr(10)
 with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
  for row in csv.DictReader(f):
   text=row.get('translation_'+language,'')
   if row['resource_kind']!='text' or not text.strip():continue
   if row['id'] not in ADAPTERS:raise ValueError('No scene adapter for '+row['id'])
   original=authority[row['id']]
   if original['source_sha256']!=row['source_sha256'] or original['translation_view']!=row['original']:raise ValueError('Source drift')
   if re.findall(r'<PLAYER>|[{][^}]+[}]',text)!=re.findall(r'<PLAYER>|[{][^}]+[}]',row['original']):raise ValueError('Control signature changed')
   path,label,needle=ADAPTERS[row['id']];entry='ZhCSV_'+hashlib.sha256(row['id'].encode()).hexdigest()[:12];event=entry+'Event'
   body=encode.encode_segments(segments(text),glyphs,'rom_dialogue')
   outputs.append(nl.join([entry+'::',' ld hl,'+entry+'Text',' ld de,'+entry+'End',' jp ZhShowDialogue',entry+'Text:',body,entry+'End:']))
   p=source/path;s=p.read_text()
   replacement=needle.replace('BGEVENT_JUMPTEXT, '+label,'BGEVENT_READ, '+event).replace('OBJECTTYPE_COMMAND, jumptextfaceplayer, '+label,'OBJECTTYPE_SCRIPT, 0, '+event)
   if s.count(needle)!=1:raise ValueError('Ambiguous scene hook')
   s=s.replace(needle,replacement,1);s+=nl+event+':'+nl+(' faceplayer'+nl if 'Fisher' in label else '')+' opentext'+nl+' callasm '+entry+nl+' closetext'+nl+' end'+nl;p.write_text(s)
 (source/'data/zh/dialogue.asm').write_text(nl.join(outputs))
 p=source/'main.asm';s=p.read_text().replace('INCLUDE '+chr(34)+'engine/zh/dialogue.asm'+chr(34),'INCLUDE '+chr(34)+'engine/zh/dialogue.asm'+chr(34)+nl+'INCLUDE '+chr(34)+'data/zh/dialogue.asm'+chr(34));p.write_text(s)
 return len(outputs)
