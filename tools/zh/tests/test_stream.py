"""Run real LR35902 token ABI with the same standalone SameBoy ROM harness."""
from pathlib import Path
import tempfile
p=Path(__file__).resolve().parent
source=(p/'test_e1.py').read_text()
start=source.index('cases=[');end=source.index('\nwith tempfile',start)
cases=[('glyph','0a8083',3,4,3),('empty','',0,4,0),('reverse','80',-1,4,None),('truncated','0a80',2,4,None)]
cases += [(f'byte-{b:02x}',f'{b:02x}',1,4,b if (b in [2,0x52,0x53,0x54,0x56,0x57,0x59] or 0x7f<=b<0xf2) else None) for b in [0,1,2,3,4,8,9,0x4f,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x5d,0x7f,0x80,0xf1,0xf2,0xff]]
cases += [('name-player','0b',1,4,11),('name-rival','0c',1,4,12)]
source=source[:start]+'cases='+repr(cases)+source[end:]
a=source.index('        try:');b=source.index('        asm=',a)
source=source[:a]+source[b:]
source=source.replace('DEF ZH_ESCAPE EQU $0a\nDEF ZH_GLYPH_COUNT EQU {count}', 'DEF ZH_GLYPH_COUNT EQU {count}\nINCLUDE "constants/zh_encoding.asm"')
source=source.replace('call ZhDecodeGlyph','call ZhReadToken\n ld [$c208],a')
source=source.replace('INCLUDE "engine/zh/decode.asm"','INCLUDE "engine/zh/decode.asm"\nINCLUDE "engine/zh/stream.asm"')
source=source.replace('read c200 8','read c200 9').replace('{8}', '{9}')
source=source.replace('run 180 0','run 600 0')
source=source.replace("else:assert hl==0xc103 and bc==expected and out[6]==0,(name,out.hex())", "else:\n            advance=3 if name=='glyph' else (0 if name=='empty' else 1)\n            typ=2 if name=='glyph' else (0 if name=='empty' or expected in (0x52,0x53,0x54) else (3 if expected in (2,0x56,0x57,0x59) else 1))\n            assert hl==0xc100+advance and bc==expected and out[6]==0 and out[8]==typ,(name,out.hex())")
source=source.replace("'SameBoy_LR35902_cases'", "'SameBoy_stream_cases'")
source=source.replace('expected in (2,0x56,0x57,0x59)', 'expected in (2,11,12,0x56,0x57,0x59)')
source=source.replace("assert out[7]==0x42", "assert out[7]==0x42")
source=source.replace("assert out[7]==0x42 and", "print(name,result.stdout) if out[7]!=0x42 else None\n        assert out[7]==0x42 and")
exec(compile(source,str(p/'test_e1.py'),'exec'))
valid=[{'text':'你A'},{'control':'NEXT'},{'text':'好'},{'control':'WAIT'},{'control':'PROMPT'}]
assert 'zh_raw $54' in m.encode_segments(valid,{'你':0,'好':1},'rom_dialogue')
for bad in [[{'control':'RAM'}],[{'text':'你'}],[{'control':'DONE'},{'text':'A'}],[{'raw':10}],[{'text':'A'},{'control':'WAIT'},{'text':'B'},{'control':'DONE'}]]:
    try:m.encode_segments(bad,{'你':0},'rom_dialogue');raise AssertionError('accepted unsafe segments')
    except ValueError:pass
print('PASS explicit control allowlist, required terminal, reject trailing content/RAM/raw bytes')
assert 'zh_raw $56' in m.encode_segments([{'text':'A'},{'control':'WAIT'},{'control':'NEXT'},{'text':'B'},{'control':'DONE'}],{},'rom_dialogue')
print('PASS WAIT rejects same-line continuation and permits explicit next-line continuation')
assert m.encode_segments([{'name':'player'},{'name':'rival'},{'control':'DONE'}],{},'rom_dialogue')=='\tzh_raw $0b\n\tzh_raw $0c\n\tzh_raw $52\n'
for bad in [[{'name':'arbitrary'},{'control':'DONE'}],[{'name':'player','address':53248},{'control':'DONE'}],[{'control':'WAIT'},{'name':'player'},{'control':'DONE'}]]:
    try:m.encode_segments(bad,{},'rom_dialogue');raise AssertionError('unsafe name segment')
    except ValueError:pass
print('PASS name enum exact assembly bytes and arbitrary source/address/WAIT rejection')
