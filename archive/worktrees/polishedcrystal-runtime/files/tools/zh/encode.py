#!/usr/bin/env python3
"""Emit E1 glyphs and existing ASCII charmap text for bounded ROM dialogue.
No names, RAM consumers, inferred mappings, or automatic file rewriting.
"""
import argparse, json
from pathlib import Path

def load_glyphs(path):
    data=json.loads(Path(path).read_text(encoding='utf-8'))
    entries=data['glyphs']
    ids=[e['id'] for e in entries]; chars=[e['char'] for e in entries]
    if ids!=list(range(len(ids))) or not 0<len(ids)<=16384:
        raise ValueError('glyph IDs must be contiguous 0..count-1 (max 16384)')
    if len(set(chars))!=len(chars) or any(len(c)!=1 for c in chars):
        raise ValueError('glyph characters must be unique single Unicode characters')
    return dict(zip(chars,ids))

def glyph_bytes(glyph_id,count):
    if not 0<=glyph_id<count<=16384: raise ValueError('glyph outside manifest')
    return bytes((0x0a,0x80|(glyph_id>>7),0x80|(glyph_id&127)))

def decode_glyph(data,start,end,count):
    """Reference ABI: errors do not consume; no read beyond exclusive end."""
    if not 0<=start<=end<=len(data) or end-start<3: raise ValueError('truncated/range')
    esc,hi,lo=data[start:start+3]
    if esc!=10 or hi<128 or lo<128:raise ValueError('invalid E1')
    glyph_id=((hi&127)<<7)|(lo&127)
    if not 0<=glyph_id<count<=16384:raise ValueError('glyph outside manifest')
    return glyph_id,start+3

def encode_asm(text,glyphs,consumer):
    if consumer!='rom_dialogue':raise ValueError('E1 only permits bounded ROM dialogue')
    lines=['; Generated E1; caller must supply exclusive end label.']
    for char in text:
        if char in glyphs:lines.append(f'\tzh_glyph {glyphs[char]}')
        elif char=='\n':lines.append('\tzh_raw "<NEXT>"')
        elif char.isascii() and 32<=ord(char)<127 and char not in '"\\<>@#{}':
            lines.append('\tzh_raw '+json.dumps(char))
        else:raise ValueError(f'unsupported literal/token U+{ord(char):04X}; use explicit reviewed controls')
    lines.append('\tzh_raw "@"')
    return '\n'.join(lines)+'\n'

CONTROLS={'CONT':0x55,'NEXT':0x56,'LINE':0x57,'PARA':0x59,'WAIT':0x02,
          'DONE':0x52,'PROMPT':0x54,'END':0x53}

def encode_segments(segments,glyphs,consumer):
    """Explicit reviewed text/control segments; no raw bytes, RAM or names.
    Exactly one terminal must occur at the end. No automatic script import.
    """
    if consumer!='rom_dialogue':raise ValueError('bounded ROM dialogue only')
    lines=[];ended=False;after_wait=False
    for segment in segments:
        if ended:raise ValueError('content after terminal')
        if set(segment)=={'text'} and isinstance(segment['text'],str):
            if '\n' in segment['text']:raise ValueError('segments require explicit NEXT/LINE/PARA, not newline')
            if after_wait and segment['text']:raise ValueError('WAIT cannot resume text on the same line; use NEXT/LINE/PARA first')
            lines.extend(encode_asm(segment['text'],glyphs,consumer).splitlines()[1:-1])
        elif set(segment)=={'ram_name'} and segment['ram_name'] in ('wStringBuffer1','wStringBuffer2','wBattleMonNickname','wEnemyMonNickname'):
            symbol=segment['ram_name']
            lines.extend([' db ZH_CTRL_RAM, BANK('+symbol+')',' dw '+symbol])
        elif set(segment)=={'name'} and segment['name'] in ('player','rival'):
            if after_wait:raise ValueError('WAIT cannot resume a name on the same line')
            lines.append('\tzh_raw $' + ('0b' if segment['name']=='player' else '0c'))
        elif set(segment)=={'control'} and segment['control'] in CONTROLS:
            ctrl=segment['control'];lines.append('\tzh_raw $' + format(CONTROLS[ctrl],'02x'))
            ended=ctrl in ('DONE','PROMPT','END')
            if ctrl=='WAIT':after_wait=True
            elif ctrl in ('NEXT', 'LINE', 'PARA', 'CONT'):after_wait=False
        else:raise ValueError('unreviewed control or segment shape')
    if not ended:raise ValueError('explicit terminal required')
    return '\n'.join(lines)+'\n'

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--manifest',required=True)
    group=ap.add_mutually_exclusive_group(required=True);group.add_argument('--text');group.add_argument('--segments',help='JSON file containing explicit text/control segments')
    ap.add_argument('--consumer',required=True,choices=['rom_dialogue']);args=ap.parse_args()
    glyphs=load_glyphs(args.manifest)
    if args.segments:result=encode_segments(json.loads(Path(args.segments).read_text(encoding='utf-8')),glyphs,args.consumer)
    else:result=encode_asm(args.text,glyphs,args.consumer)
    print(result,end='')
