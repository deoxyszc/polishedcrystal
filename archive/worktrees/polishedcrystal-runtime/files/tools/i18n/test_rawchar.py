import tempfile
from pathlib import Path
import catalog,messages
with tempfile.TemporaryDirectory() as temp:
 root=Path(temp);(root/'names.asm').write_text('Names:'+chr(10)+' rawchar '+chr(34)+'Example@@'+chr(34)+chr(10))
 records,_,_=catalog.extract(root)
 assert len(records)==1 and records[0]['commands'][0]['op']=='rawchar'
 records,*_=messages.build(root,'normal')
 assert records[0]['translation_view']=='Example@@'
print('PASS rawchar fixed-name extraction and display view')
