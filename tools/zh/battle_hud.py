import csv,json
import cache_text,encode
from stable_runtime import encode_name,menu_text
def generate(source,language,manifest):
 # Names and encoded bodies are shared with the party consumer.
 (source/'data/zh/battle_hud.asm').write_text('; Shared name records are emitted in data/zh/party.asm'+chr(10))

def menu(source,language,manifest):
 glyphs=encode.load_glyphs(manifest);cm=cache_text.load_charmap(source)
 sm=json.loads((source/'data/zh/font/compiled.json').read_text())['battle_command']
 rows=[r for r in csv.DictReader((source/'translations.csv').open(encoding='utf-8-sig')) if r['id'].startswith('engine/battle/menu.asm::BattleMenuDataHeader.Strings::')]
 out=[]
 for row in rows:
  text=(row.get('translation_'+language,'').strip() or row['original']).rstrip('@')
  for token,code in [('<PK>',0xd2),('<MN>',0xd3)]:
   text=text.replace(token,chr(0xe000+code));cm[chr(0xe000+code)]=code
  data=menu_text(text,glyphs,cm,source,style=1,width_tiles=5);out += [' db '+','.join(map(str,data+bytes([83])))]
 (source/'data/zh/battle_command.asm').write_text(chr(10).join(out)+chr(10))

def party_actions(source,language,manifest):
 glyphs=encode.load_glyphs(manifest);cm=cache_text.load_charmap(source)
 sm=json.loads((source/'data/zh/font/compiled.json').read_text())['battle_command']
 rows=[r for r in csv.DictReader((source/'translations.csv').open(encoding='utf-8-sig')) if r['id'].startswith('engine/battle/core.asm::BattleMenuPKMN_Loop.MenuData::')]
 out=[]
 for row in rows:
  text=(row.get('translation_'+language,'').strip() or row['original']).rstrip('@')
  for token,code in [('<PK>',0xd2),('<MN>',0xd3)]:
   text=text.replace(token,chr(0xe000+code));cm[chr(0xe000+code)]=code
  data=menu_text(text,glyphs,cm,source,style=1,width_tiles=4);out += [' db '+','.join(map(str,data+bytes([83])))]
 (source/'data/zh/battle_party_actions.asm').write_text(chr(10).join(out)+chr(10))
