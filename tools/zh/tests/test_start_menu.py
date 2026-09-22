"""Start-menu compiler bounds, fallback and dynamic player entry."""
import csv,json,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import start_menu
ROOT=Path(__file__).resolve().parents[3]
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp)
    for d in ['constants','data/text','data/zh/font']:(root/d).mkdir(parents=True,exist_ok=True)
    for f in ['constants/charmap.asm','data/text/ngrams.asm']:(root/f).write_bytes((ROOT/f).read_bytes())
    with (ROOT/'translations.csv').open() as f:rows=[r for r in csv.DictReader(f) if r['source_path']=='engine/menus/start_menu.asm']
    def save():
        with (root/'translations.csv').open('w') as f:w=csv.DictWriter(f,rows[0].keys());w.writeheader();w.writerows(rows)
    save()
    manifest=root/'manifest.json';manifest.write_text(json.dumps({'glyphs':[{'id':0,'char':'中'}]}))
    (root/'data/zh/font/compiled.json').write_text(json.dumps({'start_menu':{'glyphs':[[300,301,302]],'latin':list(range(228))}}))
    start_menu.generate(root,'zh-Hans',manifest)
    output=(root/'data/zh/start_menu.asm').read_text()
    assert output.count('String:')==9 and '.StatusString:'+chr(10)+' db $53' in output
    row=next(r for r in rows if '.PackString::' in r['id'])
    row['translation_zh-Hans']='中'*4;save();start_menu.generate(root,'zh-Hans',manifest)
    row['translation_zh-Hans']='中'*5;save()
    try:start_menu.generate(root,'zh-Hans',manifest)
    except ValueError:pass
    else:raise AssertionError('Oversized label accepted')
print('PASS Start menu fallback, dynamic entry and compile-time bounds')
