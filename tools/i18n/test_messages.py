from pathlib import Path
import tempfile
import messages
with tempfile.TemporaryDirectory() as t:
 root=Path(t);(root/'maps').mkdir()
 (root/'maps/Test.asm').write_text('Hello:\n\ttext "First"\nif DEF(FAITHFUL)\n\tline "Faithful"\nelse\n\tline "Normal"\nendc\n\tassert VALUE == 3\n\tpara "Last {d:VALUE}"\n\tdone\n')
 rows,*_=messages.build(root,'normal');assert len(rows)==1
 assert rows[0]['display_text']=='First\nNormal\nLast {d:VALUE}'
 assert not rows[0]['diagnostics'] and rows[0]['translation_status']=='ready'
 assert 'Faithful' in rows[0]['source_text'] # immutable original conditional span
 assert 'Faithful'not in ''.join(s['source_text'] for s in rows[0]['source_segments'])
 assert any(t['kind']=='compile_time_interpolation' for t in rows[0]['tokens'])
 rows,*_=messages.build(root,'faithful');assert 'Faithful'in rows[0]['display_text'] and 'Normal'not in rows[0]['display_text']
 (root/'maps/Test.asm').write_text('Ref:\n\ttext_far Other\n\ttext_asm\n\tret\n')
 rows,*_=messages.build(root,'normal');assert rows[0]['translation_status']=='runtime_continuation'
 (root/'maps/Test.asm').write_text('Dynamic:\n\ttext_ram wName\n\ttext " used a tool."\n\tdone\n')
 rows,*_=messages.build(root,'normal');assert rows[0]['commands'][0]['op']=='text_ram'
 assert any(t.get('args')=='wName' for t in rows[0]['tokens'])
print('PASS explicit normal/faithful selection, whole message across conditions/assert, immutable source mapping, interpolation token and ASM handoff')
