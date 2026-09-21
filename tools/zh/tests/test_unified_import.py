import csv,json,tempfile,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/'tools/zh'),str(ROOT/'tools/i18n')]
import import_dialogue,messages,worksheet
with tempfile.TemporaryDirectory() as temp:
 root=Path(temp);(root/'maps').mkdir();(root/'data/zh').mkdir(parents=True)
 (root/'constants').mkdir()
 (root/'constants/charmap.asm').write_text((ROOT/'constants/charmap.asm').read_text())
 original='Script:'+chr(10)+' jumptext UnexpectedLabel'+chr(10)+'UnexpectedLabel:'+chr(10)+' text '+chr(34)+'Hello'+chr(34)+chr(10)+' done'+chr(10)
 (root/'maps/Fresh.asm').write_text(original);(root/'main.asm').write_text('INCLUDE '+chr(34)+'engine/zh/dialogue.asm'+chr(34)+chr(10))
 rows=messages.build(root,'normal')[0];worksheet.export(rows,root/'translations.csv',['zh-Hans'])
 with (root/'translations.csv').open(encoding='utf-8-sig',newline='') as f:reader=csv.DictReader(f);fields=reader.fieldnames;data=list(reader)
 data[0]['translation_zh-Hans']='中'+chr(10)+'{done}'
 with (root/'translations.csv').open('w',encoding='utf-8-sig',newline='') as f:w=csv.DictWriter(f,fields);w.writeheader();w.writerows(data)
 manifest=root/'font.json';manifest.write_text(json.dumps({'glyphs':[{'id':0,'char':'中'}]}))
 assert import_dialogue.apply(root,'zh-Hans',manifest)==1
 result=(root/'maps/Fresh.asm').read_text();assert ' jumptext UnexpectedLabel' in result and 'UnexpectedLabel:' in result and 'callasm' not in result and 'ZH_STREAM_COMMAND' in result
 print('PASS previously unknown file/label through shared descriptor; event reference unchanged')
