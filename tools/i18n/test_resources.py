import tempfile
from pathlib import Path
import resources
with tempfile.TemporaryDirectory() as tmp:
 root=Path(tmp);(root/'gfx/title').mkdir(parents=True);(root/'gfx/font').mkdir();(root/'main.asm').write_text('Logo:\n INCBIN "gfx/title/logo.2bpp.lz"\n')
 (root/'gfx/title/logo.png').write_bytes(b'not-an-image');(root/'gfx/font/normal.1bpp').write_bytes(bytes(16));(root/'gfx/title/map.tilemap').write_bytes(bytes(16))
 rows=resources.inventory(root,resources.REVIEW_SHA);index={r['source_path']:r for r in rows}
 assert index['gfx/title/logo.png']['status']=='candidate' # claimed SHA cannot certify unknown bytes
 assert index['gfx/title/logo.png']['possible_generated_references'][0]['target']=='gfx/title/logo.2bpp.lz'
 assert index['gfx/font/normal.1bpp']['resource_type']=='font_glyph_resource'
 assert index['gfx/title/map.tilemap']['status']=='nontext'
 assert all(not r['translatable_message'] and not r['automatic_text_replacement'] for r in rows)
 print('PASS resource classification, generated refs, unverified review rejection')
