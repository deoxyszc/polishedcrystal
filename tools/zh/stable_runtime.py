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
    maps=json.loads((source/'data/zh/font/compiled.json').read_text())
    strips=maps['dialogue']['glyphs']
    rows=sorted((codes[e['char']],e['id']) for e in glyphs if e['char'] in codes)
    leads=sorted({code[0] for code,glyph in rows})
    lines=['; A=byte; carry set exactly for manifested stable lead bytes.', 'ZhIsStableLead:']
    for lead in leads:
        lines += [f' cp {lead}', ' jr z,.yes']
    lines += [' and a', ' ret', '.yes', ' scf', ' ret', 'ZhStableGlyphDirectory:']
    for entry in glyphs:
        code=codes.get(entry['char'],bytes((255,255)))
        lines += [' db '+','.join(map(str,code))]
    lines += [' db 0,0']
    for name,label in [('dialogue','ZhStableDialogueStrips'),('battle_hud','ZhStableHudStrips')]:
        lines += [label+':']
        exceptions=[]
        for i,row in enumerate(maps[name]['glyphs']):
            if row == list(range(row[0],row[0]+3)) and row[2]<0x8000:
                lines += [f' dw ${0x8000|row[0]:04x}']
            else:
                target=label+'Exception'+str(i)
                lines += [' dw '+target]
                exceptions += [target+':',' db '+','.join(str(b) for key in row for b in (key>>8,key&255))]
        lines += exceptions
    (source/'data/zh/stable.asm').write_text('\n'.join(lines)+'\n')
    return len(glyphs)


def compile_dialogue(segments,glyphs,charmap,strip_map,source):
    import cache_text,encode
    from layouts import DIALOGUE
    output=[];width=0
    for segment in segments:
        if 'text' in segment:
            text=segment['text']
            width+=cache_text.measure_text(text,glyphs,width_tiles=DIALOGUE.width,charmap=charmap)
            data=encode_name(text,glyphs,charmap,source)
            if data:output.append(' db '+','.join(map(str,data)))
        elif 'control' in segment:
            ctrl=segment['control'];output.append(' db '+str(encode.CONTROLS[ctrl]))
            if ctrl in ('LINE','NEXT','PARA','CONT'):width=0
        elif 'name' in segment:
            width+=10;output.append(' db ZH_CTRL_PLAYER' if segment['name']=='player' else ' db ZH_CTRL_RIVAL')
        elif 'ram_name' in segment:
            width+=10;symbol=segment['ram_name'];output.extend([' db ZH_CTRL_RAM, BANK('+symbol+')',' dw '+symbol])
        else:raise ValueError('Unsupported text segment')
        if width>DIALOGUE.width:raise ValueError('Compiled fragments exceed the dialogue region')
    return chr(10).join(output)+chr(10)

def menu_text(text,glyphs,charmap,source,*,style,width_tiles):
    from cache_text import measure_text
    measure_text(text,glyphs,width_tiles=width_tiles,charmap=charmap)
    data=encode_name(text,glyphs,charmap,source)
    if len(data)>=16384:raise ValueError('Menu text too long')
    # Header operands have bit7 set so byte-wise @ scans cannot stop in them.
    return bytes((10,128|style,128|(len(data)>>7),128|(len(data)&127)))+data

def encode_name(text,glyphs,charmap,source):
    codes=mapping(source);data=bytearray()
    for char in text:
        if char==' ':data.append(127)
        elif char in charmap and 128<=charmap[char]<242:data.append(charmap[char])
        elif char in codes:data.extend(codes[char])
        else:
            value=glyphs[char];data.extend((10,128|(value>>7),128|(value&127)))
    return bytes(data)
