"""Compile party names/footer to ordinary cached glyph pairs."""
import csv,json
import cache_text,encode
from stable_runtime import encode_name,menu_text
from layouts import PARTY_NAME,PARTY_FOOTER

def generate(source,language,manifest):
    glyphs=encode.load_glyphs(manifest);charmap=cache_text.load_charmap(source)
    maps=json.loads((source/'data/zh/font/compiled.json').read_text())
    with (source/'translations.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
    names=[];body=[];headers={}
    for row in rows:
        if row['source_path']!='data/pokemon/names.asm':continue
        text=row.get('translation_'+language,'').strip().rstrip('@')
        if not text:continue
        raw=row['original']
        cache_text.encode_legacy_name(source,raw)
        width=cache_text.measure_text(text,glyphs,width_tiles=8,charmap=charmap,leading_strips=1)
        data=encode_name(text,glyphs,charmap,source)
        plain=maps['party_name']['level_plain']
        four=len(text)==4 and all(not c.isascii() for c in text)
        variant=maps['party_name']['level_four'][glyphs[text[-1]]] if four else {'L':plain,'100':[65535,65535]}
        keys=variant['L']+variant['100']+plain
        header=bytes([int(four)]+[v for k in keys for v in (k>>8,k&255)])
        header_label=headers.setdefault(header,'ZhPartyLevelHeader'+str(len(headers)))
        label='.name'+str(len(names));names.append(' dw '+label)
        body += [label+':',' dw PokemonNames + '+str((int(row['id'].rsplit('::',1)[1])-1)*10), ' db '+str(6 if 1 <= len(text) <= 4 and all(not c.isascii() for c in text) else 4),' dw '+header_label, ' db '+str((sum(8 if c.isascii() else 12 for c in text)+7)//8), ' db '+','.join(map(str,bytes([len(data)])+data))]
    out=['ZhPartyNames::']+names+[' dw 0']+body
    for header,label in headers.items():out += [label+':',' db '+','.join(map(str,header))]
    for label,key in [('ZhPartyCancel','PlacePartyNicknames.Cancel'),('ZhPartyPrompt','ChooseAMonString')]:
        row=next(row for row in rows if row['id']==f'engine/pokemon/party_menu.asm::{key}::1')
        text=(row.get('translation_'+language,'').strip() or row['original']).rstrip('@')
        text=cache_text.expand_static_ngrams(source,text)
        data=menu_text(text,glyphs,charmap,source,style=0,width_tiles=18)
        out += [label+'::',' db '+','.join(map(str,data+bytes([0x53])))]
    (source/'data/zh/party.asm').write_text(chr(10).join(out)+chr(10))
