"""Stable Han dialogue integration; existing controls/Latin keep old paths."""
import json
from pathlib import Path
from stable_codec import digest


def mapping(source):
    table=json.loads((source/'tools/zh/codec-v1/encoding.json').read_text())
    if table['mapping_sha256']!=digest(table['mapping']):
        raise ValueError('encoding checksum mismatch')
    return {e['char']:bytes.fromhex(e['code']) for e in table['mapping']}


def emit(source, manifest):
    codes=mapping(source)
    glyphs=json.loads(Path(manifest).read_text())['glyphs']
    strips=json.loads((source/'data/zh/font/compiled.json').read_text())['dialogue']['glyphs']
    rows=sorted((codes[e['char']],e['id']) for e in glyphs if e['char'] in codes)
    leads=sorted({code[0] for code,glyph in rows})
    lines=['; A=byte; carry set exactly for manifested stable lead bytes.', 'ZhIsStableLead:']
    for lead in leads:
        lines += [f' cp {lead}', ' jr z,.yes']
    lines += [' and a', ' ret', '.yes', ' scf', ' ret', 'ZhStableGlyphDirectory:']
    for index,(code,glyph) in enumerate(rows):
        lines += [' db '+','.join(str(b) for b in code),f' dw {index}']
    lines += [' db 0','ZhStableDialogueStrips:']
    for code,glyph in rows:
        lines += [' db '+','.join(str(b) for s in strips[glyph] for b in (s>>8,s&255))]
    (source/'data/zh/stable.asm').write_text('\n'.join(lines)+'\n')
    return 10*len(rows)+1


def compile_dialogue(segments,glyphs,charmap,strip_map,source):
    import cache_text
    from layouts import DIALOGUE
    codes=mapping(source)
    # Retain existing width/control validation before emitting compact runs.
    cache_text.compile_segments(segments,glyphs,charmap,layout=DIALOGUE,strip_map=strip_map)
    output=[]
    for segment in segments:
        if 'text' not in segment:
            output.append(cache_text.compile_segments([segment],glyphs,charmap,layout=DIALOGUE,strip_map=strip_map))
            continue
        text=segment['text']
        # Odd Han runs followed by Latin require a 4px carry across formats.
        # Keep such mixed runs on the old path until that adapter is implemented.
        if any(c not in codes for c in text):
            output.append(cache_text.compile_segments([segment],glyphs,charmap,layout=DIALOGUE,strip_map=strip_map))
        else:
            output.append(' db '+','.join(str(b) for c in text for b in codes[c])+ '\n')
    return ''.join(output)
