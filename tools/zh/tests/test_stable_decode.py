import argparse, importlib.util, json, re, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('encode',ROOT/'tools/zh/encode.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
ap=argparse.ArgumentParser();ap.add_argument('--runner',required=True);args=ap.parse_args()
table=json.loads((ROOT/'tools/zh/codec-v1/encoding.json').read_text())['mapping']
selected=[table[0],table[100],table[-1]]
cases=[('first',selected[0]['code'],2,4,0),('middle',selected[1]['code'],2,4,1),('last',selected[2]['code'],2,4,2),('truncated',selected[0]['code'],1,4,None),('empty',selected[0]['code'],0,4,None),('unknown','ffff',2,4,None),('reversed',selected[0]['code'],-1,4,None)]
directory='ZhStableGlyphDirectory:\n'+''.join(' db $'+e['code'][:2]+',$'+e['code'][2:]+'\n' for i,e in enumerate(selected))+' db 0\n'
with tempfile.TemporaryDirectory() as temp:
    d=Path(temp)
    for name,data,length,count,expected in cases:
        data=bytes.fromhex(data)
        asm=f'''DEF ZH_ESCAPE EQU $0a
DEF ZH_GLYPH_COUNT EQU {count}
SECTION "Header", ROM0[$100]
 nop
 jp Start
 ds $150-@, 0
SECTION "Test", ROM0[$150]
Start:
 di
 ld sp,$dfff
 ld hl,$c100
 ld de,$c100+({length})
 call ZhDecodeStableGlyph
 push af
 ld a,l
 ld [$c200],a
 ld a,h
 ld [$c201],a
 ld a,c
 ld [$c202],a
 ld a,b
 ld [$c203],a
 ld a,e
 ld [$c204],a
 ld a,d
 ld [$c205],a
 pop af
 ld a,0
 adc 0
 ld [$c206],a
 ld a,$42
 ld [$c207],a
.loop
 jr .loop
INCLUDE "engine/zh/stable_decode.asm"
{directory}
'''
        (d/'test.asm').write_text(asm)
        for cmd in (['rgbasm','-I',str(ROOT)+'/', '-o',str(d/'test.o'),str(d/'test.asm')],['rgblink','-o',str(d/'test.gb'),str(d/'test.o')],['rgbfix','-v','-p','0',str(d/'test.gb')]):subprocess.run(cmd,check=True,capture_output=True)
        commands='run 180 0\n'+''.join(f'write {0xc100+i:x} {byte:x}\n' for i,byte in enumerate(data))+'cpu 150 dfff\nrun 1 0\nread c200 8\nquit\n'
        result=subprocess.run([args.runner,str(d/'test.gb')],input=commands,text=True,capture_output=True,check=True)
        match=re.search(r'(?m)^((?:[0-9a-f]{2} ){8})$',result.stdout);assert match,(name,result.stdout,result.stderr)
        out=bytes.fromhex(match[1]);hl=int.from_bytes(out[:2],'little');bc=int.from_bytes(out[2:4],'little');de=int.from_bytes(out[4:6],'little')
        assert out[7]==0x42 and de==(0xc100+length)&65535,(name,out.hex())
        if expected is None:assert hl==0xc100 and out[6]==1,(name,out.hex())
        else:assert hl==0xc102 and bc==expected and out[6]==0,(name,out.hex())
print(json.dumps({'SameBoy_LR35902_cases':len(cases),'ABI':'two-byte consume, failure rollback, DE preserved, sparse glyph lookup'}))
