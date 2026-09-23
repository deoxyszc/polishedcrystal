"""Compile party names/footer to ordinary cached glyph pairs."""
import csv,json
import cache_text,encode
from layouts import PARTY_NAME,PARTY_FOOTER

def generate(source,language,manifest):
    glyphs=encode.load_glyphs(manifest);charmap=cache_text.load_charmap(source)
    maps=json.loads((source/'data/zh/font/compiled.json').read_text())
    with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
    names=[];body=[]
    for row in rows:
        if row['source_path']!='data/pokemon/names.asm':continue
        text=row.get('translation_'+language,'').strip().rstrip('@')
        if not text:continue
        raw=row['original']
        if len(raw)!=10:raise ValueError('Invalid default name')
        data,_=cache_text.encode_pairs(text,glyphs,width_tiles=8,charmap=charmap,strip_map=maps['party_name'],leading_strips=1)
        plain=maps['party_name']['level_plain']
        four=len(text)==4 and all(not c.isascii() for c in text)
        variant=maps['party_name']['level_four'][glyphs[text[-1]]] if four else {'L':plain,'100':[65535,65535]}
        keys=variant['L']+variant['100']+plain
        header=bytes([int(four)]+[v for k in keys for v in (k>>8,k&255)])
        label='.name'+str(len(names));names.append(' dw '+label)
        body += [label+':',' db '+chr(34)+raw+chr(34), ' db '+str(6 if 1 <= len(text) <= 4 and all(not c.isascii() for c in text) else 4),' db '+','.join(map(str,header)), ' db '+','.join(map(str,data+bytes([0x53])))]
    out=['ZhPartyNames::']+names+[' dw 0']+body
    for label,key in [('ZhPartyCancel','PlacePartyNicknames.Cancel'),('ZhPartyPrompt','ChooseAMonString')]:
        row=next(row for row in rows if row['id']==f'engine/pokemon/party_menu.asm::{key}::1')
        text=(row.get('translation_'+language,'').strip() or row['original']).rstrip('@')
        text=cache_text.expand_static_ngrams(source,text)
        data,_=cache_text.encode_pairs(text,glyphs,width_tiles=18,charmap=charmap,strip_map=maps['party_footer'])
        out += [label+'::',' db '+','.join(map(str,data+bytes([0x53])))]
    (source/'data/zh/party.asm').write_text(chr(10).join(out)+chr(10))
