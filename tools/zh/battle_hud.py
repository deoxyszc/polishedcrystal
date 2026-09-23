import csv,json
import cache_text,encode
def generate(source,language,manifest):
 glyphs=encode.load_glyphs(manifest);cm=cache_text.load_charmap(source)
 sm=json.loads((source/'data/zh/font/compiled.json').read_text())['battle_hud']
 rows=[r for r in csv.DictReader((source/'translations.csv').open(encoding='utf-8-sig')) if r['source_path']=='data/pokemon/names.asm' and r.get('translation_'+language,'').strip()]
 out=['ZhBattleHudNames:']+[' dw .name'+str(i) for i in range(len(rows))]+[' dw 0']
 for i,row in enumerate(rows):
  data,width=cache_text.encode_pairs(row['translation_'+language].strip().rstrip('@'),glyphs,width_tiles=8,charmap=cm,strip_map=sm)
  out += ['.name'+str(i)+':',' db '+chr(34)+row['original']+chr(34),' db '+str(width),' db '+','.join(map(str,data+bytes([83])))]
 (source/'data/zh/battle_hud.asm').write_text(chr(10).join(out)+chr(10))

def menu(source,language,manifest):
 glyphs=encode.load_glyphs(manifest);cm=cache_text.load_charmap(source)
 sm=json.loads((source/'data/zh/font/compiled.json').read_text())['battle_command']
 rows=[r for r in csv.DictReader((source/'translations.csv').open(encoding='utf-8-sig')) if r['id'].startswith('engine/battle/menu.asm::BattleMenuDataHeader.Strings::')]
 out=[]
 for row in rows:
  text=(row.get('translation_'+language,'').strip() or row['original']).rstrip('@')
  for token,code in [('<PK>',0xd2),('<MN>',0xd3)]:
   text=text.replace(token,chr(0xe000+code));cm[chr(0xe000+code)]=code
  data,_=cache_text.encode_pairs(text,glyphs,width_tiles=5,charmap=cm,strip_map=sm);out += [' db '+','.join(map(str,data+bytes([83])))]
 (source/'data/zh/battle_command.asm').write_text(chr(10).join(out)+chr(10))
