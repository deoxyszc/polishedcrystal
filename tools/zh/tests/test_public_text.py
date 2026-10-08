"""CPU checks against an explicitly supplied isolated Chinese ROM and SameBoy runner.

Upload and delay calls are stubbed for deterministic logic assertions. This is
not an LCD timing or screenshot test and never writes a battery save.
"""
import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom', type=Path, required=True)
    parser.add_argument('--runner', type=Path, required=True)
    args = parser.parse_args()
    symbols = {}
    for line in args.rom.with_suffix('.sym').read_text().splitlines():
        match = re.fullmatch(r'([0-9a-f]+):([0-9a-f]+) (\S+)', line)
        if match:
            symbols[match[3]] = (int(match[1], 16), int(match[2], 16))
    def address(name):
        return symbols[name][1]
    binary = bytearray(args.rom.read_bytes())
    for name in ('Get2bpp', 'PrintLetterDelay', 'ApplyAttrmapInVBlank'):
        bank, offset = symbols[name]
        binary[offset if bank == 0 else bank * 0x4000 + offset - 0x4000] = 0xc9
    results = []
    with tempfile.TemporaryDirectory() as folder:
        rom = Path(folder) / 'cpu.gbc'
        rom.write_bytes(binary)
        for bank, style in ((0, 0), (1, 0), (1, 0x80)):
            commands = ['run 600 0', 'write ffff 0', 'write 2000 80',
                        f'write {address("hROMBank"):x} 80', 'write ff70 2']
            def write(offset, values):
                commands.extend(f'write {offset+i:x} {value:x}' for i, value in enumerate(values))
            def invoke(name):
                write(0xc000, [0x18, 0xfe])
                write(0xc0f0, [0, 0xc0])
                commands.extend([f'cpu {address(name):x} c0f0', 'run 60 0', 'regs'])
            # All 43 slots contain distinct original Latin glyphs.
            write(address('wTextGlyphKeys'), [v for i in range(43) for v in (2*i, 1|style, 2*i+1, 1|style)])
            write(address('wTextGlyphUsed'), [0x82] + [2]*42)
            write(address('wTilemap'), list(range(128, 214)) + [127]*274)
            write(address('wAttrmap'), [15]*86 + [7]*274)
            write(address('wWindowStackPointer'), [0xfd, 0xdf])
            invoke('CopyChineseTempScreen')
            # Original temporary tilemap must remain compatible with direct readers.
            commands.extend(['write ff70 2', f'read {address("wTempTileMap"):x} 86'])
            write(address('wTilemap'), [127]*360)
            write(address('wTextGlyphKeys'), [255]*172)
            write(address('wTextGlyphUsed'), [0x40 if bank == 0 else 0x80] + [0]*42)
            invoke('RestoreChineseTempScreen')
            commands.extend([f'read {address("wTilemap"):x} 86',
                             f'read {address("wAttrmap"):x} 86', 'quit'])
            result = subprocess.run([str(args.runner), str(rom)], input='\n'.join(commands)+'\n',
                                    text=True, capture_output=True, check=True, timeout=45)
            if result.stdout.count('PC=c000 SP=c0f2') != 2:
                raise AssertionError('routine failed to return: ' + result.stdout[-1500:])
            arrays = [bytes.fromhex(line) for line in result.stdout.splitlines()
                      if re.fullmatch(r'(?:[0-9a-f]{2} ){86}', line)]
            assert arrays == [bytes(range(128, 214)), bytes(range(128, 214)),
                              bytes([7 | bank*8])*86], arrays
            results.append({'bank': bank, 'style': style, 'slots': 43, 'reconstruction': 'passed'})
    print(json.dumps({'CPU_only': results, 'LCD_timing_tested': False}))


if __name__ == '__main__':
    main()
