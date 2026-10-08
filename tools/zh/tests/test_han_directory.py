from pathlib import Path
import argparse,json,sys,subprocess,tempfile
r=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser();parser.add_argument('--runner',required=True);args=parser.parse_args()
workspace=tempfile.TemporaryDirectory();out=Path(workspace.name)
sys.path.insert(0,str(r/'tools/zh'));from han_directory import make_directory
mapping={e['char']:e['code'] for e in json.loads((r/'tools/zh/codec-v1/encoding.json').read_text())['mapping']}
chars=sorted(mapping, key=mapping.get)[:354]
raw=bytes(18*len(chars));directory=make_directory(mapping,chars,raw)
lookup=(r/'engine/text/chinese.asm').read_text().split('TextLookupHanLead:',1)[1].split('; The window stack',1)[0]
source='''SECTION "Entry", ROM0[$100]
 jp Main
 ds $150-@,0
Main:
 di
 ld sp,$dfff
 xor a
 ldh [$ff40],a
 ld hl,Tests
 ld a,0
 ld [$c000],a
.loop
 ld a,[hli]
 cp $ff
 jr z,.invalid
 ld d,a
 ld a,[hli]
 ld e,a
 push hl
 ld a,d
 push de
 call TextLookupHanLead
 pop de
 jr c,.fail
 ld a,e
 call TextLookupHanTail
 jr c,.fail
 ld d,h
 ld e,l
 pop hl
 ld a,[hli]
 cp e
 jr nz,.fail
 ld a,[hli]
 cp d
 jr nz,.fail
 jr .loop
.invalid
 ld a,0
 call TextLookupHanLead
 jr nc,.fail
 ld a,$ff
 call TextLookupHanLead
 jr nc,.fail
 ld a,$80
 call TextLookupHanLead
 jr nc,.fail
 ld a,$0f
 call TextLookupHanLead
 jr c,.fail
 ld a,0
 call TextLookupHanTail
 jr nc,.fail
.done
 ld a,$42
 ld [$c000],a
.stop
 jr .stop
.fail
 ld a,$ee
 ld [$c000],a
 jr .stop
TextLookupHanLead:
'''+lookup+'\n'+'\n'.join(directory)+'\nTests:\n'
for char in chars:
 lead,tail=bytes.fromhex(mapping[char]);rank=sum(1 for c in chars if int(mapping[c][:2],16)==lead and int(mapping[c][2:],16)//16==tail//16 and int(mapping[c][2:],16)<tail)
 source+=f' db {lead},{tail}\n dw TextHanBlock{lead}_{tail//16}+{rank*18}\n'
source+=' db $ff\nSECTION "Padding", ROMX[$7fff], BANK[1]\n db 0\n'
(out/'test.asm').write_text(source)
for cmd in [['rgbasm','-o',str(out/'test.o'),str(out/'test.asm')],['rgblink','-o',str(out/'test.gbc'),str(out/'test.o')],['rgbfix','-v','-p','0','-C',str(out/'test.gbc')]]:subprocess.run(cmd,check=True)
runner=args.runner
p=subprocess.run([runner,str(out/'test.gbc')],input='run 600 0\nread c000 1\nquit\n',text=True,capture_output=True,check=True)
(out/'run.log').write_text(p.stdout+p.stderr)
assert '\n42 ' in p.stdout,p.stdout
print(f'{len(chars)} glyph pointers plus missing lead/tail cases passed on SameBoy CPU')
