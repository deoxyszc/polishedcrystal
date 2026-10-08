"""Shared original-name lookup and ordinary terminated translated strings."""
import csv
from dialogue_text import encode
from cache_text import encode_legacy_name


def rows(source):
    with (source/'translations.csv').open(encoding='utf-8-sig', newline='') as stream:
        return [row for row in csv.DictReader(stream)
                if row['source_path']=='data/pokemon/names.asm'
                and row['translation_zh-Hans'].strip()]


def emit(source):
    entries=rows(source)
    lines=['TextTranslatedNames:']; bodies={}
    for row in entries:
        index=int(row['id'].rsplit('::',1)[1])-1
        encode_legacy_name(source,row['original'])
        data=encode(source,row['translation_zh-Hans'].rstrip('@')+'@')
        label=bodies.setdefault(data, f'TextTranslatedName{len(bodies)}')
        lines += [f' dw PokemonNames+{index}*10, {label}']
    lines += [' dw 0']
    for data,label in bodies.items():
        lines += [label+':',' db '+','.join(map(str,data))]
    (source/'data/zh/public_names.asm').write_text('\n'.join(lines)+'\n')
    return len(entries)
