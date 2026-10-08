"""CPU-only nested window reconstruction and pre-write overflow regression."""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--rom', type=Path, required=True)
p.add_argument('--runner', required=True)
a = p.parse_args()
symbols = {}
for line in a.rom.with_suffix('.sym').read_text().splitlines():
    m = re.fullmatch(r'([0-9a-f]+):([0-9a-f]+) (\S+)', line)
    if m:
        symbols[m[3]] = (int(m[1], 16), int(m[2], 16))
def addr(name):
    return symbols[name][1]
blob = bytearray(a.rom.read_bytes())
for name in ('Get2bpp', 'PrintLetterDelay', 'ApplyAttrmapInVBlank'):
    bank, offset = symbols[name]
    blob[offset if not bank else bank*16384+offset-16384] = 0xc9
# Trap Crash before reset can erase evidence or touch adjacent RAM.
offset = addr('Crash')
blob[offset:offset+7] = bytes([0xea, 0x10, 0xc0, 0xc3, 0, 0xc0, 0])
with tempfile.TemporaryDirectory() as folder:
    rom = Path(folder)/'test.gbc'
    rom.write_bytes(blob)
    for case in ('nested', 'exact', 'short'):
        cmd = ['run 600 0', 'write ffff 0']
        def write(address, values):
            cmd.extend(f'write {address+i:x} {v:x}' for i, v in enumerate(values))
        def call(name, hl=0, de=0):
            bank, pc = symbols[name]
            cmd.extend([f'write 2000 {bank:x}', f'write {addr("hROMBank"):x} {bank:x}'])
            write(0xc000, [0x18,0xfe])
            write(0xc0f0, [0,0xc0])
            cmd.extend([f'hl {hl:x}', f'de {de:x}', f'cpu {pc:x} c0f0', 'run 30 0', 'regs'])
        cmd += ['write ff70 7']
        write(0xd000, [4,0xd0,0,0])
        write(0xdffe, [0,0])
        write(addr('wWindowStackPointer'), [0xfd,0xdf])
        write(addr('wWindowStackSize'), [0])
        write(addr('wMenuFlags'), [0x40,1,1,1,3]+[0]*11)
        write(addr('wTilemap'), [127]*360)
        write(addr('wAttrmap'), [7]*360)
        cmd += ['write ff70 2']
        write(addr('wTextGlyphKeys'), [0,1,1,1]+[255]*168)
        write(addr('wTextGlyphUsed'), [0x82]+[2]*42)
        write(addr('wTilemap')+21,[128,129,127])
        write(addr('wAttrmap')+21,[15,15,23])
        cmd += ['write ff70 7']
        if case == 'nested':
            call('_PushWindow')
            write(addr('wTilemap')+21,[0x80,0x81,0x82])
            write(addr('wAttrmap')+21,[7,7,7])
            call('_PushWindow')
            write(addr('wTilemap')+21,[127]*3)
            call('_ExitMenu')
            cmd += [f'read {addr("wTilemap")+21:x} 3']
            cmd += ['write ff70 2']
            write(addr('wTextGlyphKeys'),[255]*172)
            write(addr('wTextGlyphUsed'),[0x80]+[0]*42)
            cmd += ['write ff70 7']
            call('_ExitMenu')
            cmd += [f'read {addr("wTilemap")+21:x} 3', f'read {addr("wAttrmap")+21:x} 3',
                    f'read {addr("wWindowStackPointer"):x} 2', f'read {addr("wWindowStackSize"):x} 1',
                    'write ff70 2', f'read {addr("wTextGlyphKeys"):x} 172']
        else:
            # 6+6+2 bytes, plus two-byte link reservation, bottom at d004.
            write(0xd003, [0xa5])
            write(0xc010, [0])
            call('BackupChineseWindow', addr('wTilemap')+21, 0xd014 if case=='exact' else 0xd013)
            cmd += ['read d000 4','read c010 1']
        cmd += ['quit']
        result = subprocess.run([a.runner,str(rom)],input='\n'.join(cmd)+'\n',text=True,
                                capture_output=True,check=True,timeout=45)
        output = result.stdout
        if case=='nested':
            assert output.count('PC=c000 SP=c0f2')==4, output[-1800:]
            triples=[bytes.fromhex(line) for line in output.splitlines() if re.fullmatch(r'(?:[0-9a-f]{2} ){3}',line)]
            keys=next(bytes.fromhex(line) for line in output.splitlines() if re.fullmatch(r'(?:[0-9a-f]{2} ){172}',line))
            assert triples[0]==bytes([128,129,130]) and triples[1][2]==127, triples
            slot=(triples[1][0]-128)//2
            assert triples[1][1]==triples[1][0]+1 and keys[slot*4:slot*4+4]==bytes([0,1,1,1]), (triples,keys)
            assert '\n0f 0f 07 ' in output and '\nfd df ' in output and '\n00 ' in output
        else:
            assert '\n04 d0 00 a5 ' in output, output[-1800:]
            assert ('\n0c ' if case=='short' else '\n00 ') in output, output[-1800:]
            if case=='exact':
                assert 'DE=d006' in output and 'PC=c000 SP=c0f2' in output, output[-1800:]
        print(case+': passed')
