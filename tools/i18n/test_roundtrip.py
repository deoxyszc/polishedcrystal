import copy,tempfile
from pathlib import Path
import catalog,roundtrip
with tempfile.TemporaryDirectory() as t:
 root=Path(t);(root/'maps').mkdir();p=root/'maps/Test.asm'
 text='Greeting:\n\ttext  "Hello <PLAYER>" ; note\n\n\tline "world"\n\tdone\n'
 p.write_text(text);rows,_,_=catalog.extract(root)
 rebuilt,trace=roundtrip.reconstruct(root,rows,True,True)
 assert rebuilt['maps/Test.asm']==text and not trace[0]['changed']
 changed=copy.deepcopy(rows);changed[0]['commands'][0]['args']='"Changed <PLAYER>"'
 rebuilt,trace=roundtrip.reconstruct(root,changed);assert 'Changed <PLAYER>'in rebuilt['maps/Test.asm'] and trace[0]['changed']
 for data,original,complete in [(changed,True,True),([],True,True),(rows+rows,True,True)]:
  try:roundtrip.reconstruct(root,data,original,complete);raise AssertionError('accepted invalid')
  except ValueError:pass
 bad=copy.deepcopy(rows);bad[0]['commands'][0]['args']='"Hello <RIVAL>"'
 try:roundtrip.reconstruct(root,bad);raise AssertionError('token changed')
 except ValueError:pass
 p.write_text(text.replace('world','drift'))
 try:roundtrip.reconstruct(root,rows);raise AssertionError('drift')
 except ValueError:pass
print('PASS exact roundtrip, catalog literal consumption, original mode, complete coverage, duplicate ID, token and source drift rejection')
