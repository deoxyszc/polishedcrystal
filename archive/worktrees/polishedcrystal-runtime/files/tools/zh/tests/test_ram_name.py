import argparse,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
ap=argparse.ArgumentParser();ap.add_argument('--runner',required=True);args=ap.parse_args()
cases=[(0,bytes.fromhex('808153'),True),(0,bytes.fromhex('53'),True),(0,bytes([128])*10+bytes([83]),True),(0,bytes([128])*11,False),(0,bytes.fromhex('800a53'),False)]
with tempfile.TemporaryDirectory() as temp:
 d=Path(temp)
 for index,(source,data,valid) in enumerate(cases):
  asm='''DEF rWBK EQU $ff70
DEF NAME_LENGTH EQU 11
SECTION "Names", WRAMX[$d000], BANK[1]
wPlayerName: ds 11
wRivalName: ds 11
SECTION "Destination", WRAM0[$c300]
wZhNameBuffer: ds 12
SECTION "Header", ROM0[$100]
 nop
 jp Start
 ds $150-@,0
SECTION "Code", ROM0[$150]
Start:
 di
 ld sp,$cfff
 ld a,3
 ldh [rWBK],a
 ld a,SOURCE
 ld hl,wPlayerName
 ld b,1
 call ZhStageRAMName
 push af
 ld a,c
 ld [$c200],a
 ld a,b
 ld [$c201],a
 ld a,l
 ld [$c202],a
 ld a,h
 ld [$c203],a
 ldh a,[rWBK]
 ld [$c204],a
 pop af
 ld a,0
 adc 0
 ld [$c205],a
 ld a,$42
 ld [$c206],a
.loop
 jr .loop
INCLUDE "engine/zh/name.asm"
'''.replace('SOURCE',str(source))
  (d/'n.asm').write_text(asm)
  for cmd in (['rgbasm','-I',str(ROOT)+'/', '-o',str(d/'n.o'),str(d/'n.asm')],['rgblink','-o',str(d/'n.gb'),str(d/'n.o')],['rgbfix','-v','-C','-p','0',str(d/'n.gb')]):subprocess.run(cmd,check=True,capture_output=True)
  address=0xd000+(11 if source==1 else 0)
  commands='run 600 0\nwrite ff70 1\n'+''.join(f'write {address+i:x} {b:x}\n' for i,b in enumerate(data))+''.join(f'write {0xc300+i:x} aa\n' for i in range(12))+'cpu 150 cfff\nrun 1 0\nread c200 7\nread c300 12\nquit\n'
  out=subprocess.run([args.runner,str(d/'n.gb')],input=commands,text=True,capture_output=True,check=True).stdout
  regs=bytes.fromhex(next(s for s in out.splitlines() if re.fullmatch(r'(?:[0-9a-f]{2} ){7}',s)))
  buf=bytes.fromhex(next(s for s in out.splitlines() if re.fullmatch(r'(?:[0-9a-f]{2} ){12}',s)))
  assert regs[4]&7==3 and regs[6]==0x42,(index,regs.hex())
  assert regs[5]==(0 if valid else 1),(index,regs.hex())
  if valid:
   length=data.index(0x53);assert regs[:4]==bytes([length,0,0,0xc3])
   assert buf==data[:length+1]+b'\xaa'*(11-length)
print('PASS bounded RAM text length, terminator, invalid byte and bank restoration')