"""Compile fixed Start menu labels; the player entry stays dynamic."""
import csv,json
import cache_text
from layouts import START_MENU
LABELS = ('Pokedex','Party','Pack','Status','Save','Option','Exit','Pokegear','Quit')
def generate(source, language, manifest):
    import encode
    glyphs=encode.load_glyphs(manifest)
    charmap=cache_text.load_charmap(source)
    strip_map=json.loads((source/'data/zh/font/compiled.json').read_text())['start_menu']
    with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:
        rows={r['id']:r for r in csv.DictReader(f) if r['source_path']=='engine/menus/start_menu.asm'}
    lines=[]
    for name in LABELS:
        key=f'engine/menus/start_menu.asm::StartMenu.{name}String::1'
        row=rows[key]
        lines.append(f'.{name}String:')
        if name=='Status':
            lines.append(' db $53')
            continue
        text=(row.get('translation_'+language,'').strip() or row['original']).removesuffix('@')
        text=cache_text.expand_static_ngrams(source,text)
        for token,code in [("<PO>",0xd0),("<KE>",0xd1)]:
            symbol=chr(0xe000+code)
            charmap[symbol]=code
            text=text.replace(token,symbol)
        data,_=cache_text.encode_pairs(text,glyphs,width_tiles=START_MENU.width,charmap=charmap,strip_map=strip_map)
        lines.append(' db '+','.join(str(v) for v in data+bytes([0x53])))
    (source/'data/zh/start_menu.asm').write_text(chr(10).join(lines)+chr(10))
