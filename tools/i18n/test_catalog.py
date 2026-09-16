import importlib.util,tempfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('catalog',Path(__file__).with_name('catalog.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
with tempfile.TemporaryDirectory() as t:
 root=Path(t);(root/'maps').mkdir();p=root/'maps/Test.asm'
 text='Greeting:\n\ttext "Hello; <PLAYER>" ; comment\n\tline "<PLAYER>"\n\tdone\n.Local\n\tdb "Name@"\nConditional:\nif DEF(X)\n\ttext "Yes"\n\tdone\nelse\n\ttext "No"\n\tdone\nendc\nDuplicate:\n\tdb "Name@"\n'
 p.write_text(text);a,_,_=m.extract(root);assert len(a)==5
 assert a[0]['source_text']==''.join(text.splitlines(keepends=True)[1:4])
 assert a[1]['label']=='Greeting.Local' and not a[1]['diagnostics']
 assert all(r['diagnostics'] for r in a[2:4])
 assert len([x for x in a[0]['tokens'] if x.get('value')=='<PLAYER>'])==2
 p.write_text('\n'+text);b,_,_=m.extract(root);assert [(r['id'],r['source_sha256']) for r in a]==[(r['id'],r['source_sha256']) for r in b]
 p.write_text(text.replace('Greeting:','Renamed:').replace('"Yes"','"Changed"'));b,_,_=m.extract(root);d=m.difference(a,b)
 assert d['possible_moves_or_renames'] and len(d['source_changed'])==1
 assert len({r['id'] for r in b})==len(b)
 assert not any(r['auto_admit'] for r in b)
print('PASS exact spans, comments, repeat tokens, local labels, condition isolation, line-shift IDs, duplicate strings, rename/change diff')
