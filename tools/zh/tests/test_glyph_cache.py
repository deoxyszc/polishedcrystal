#!/usr/bin/env python3
"""Execute the shared cache/raster routines in an isolated LR35902 fixture."""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runner", required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as directory:
        out = Path(directory)
        glyphs = [bytes((i * 37 + n * 13 + n // 256 * 71 + 11) & 255
                        for i in range(18)) for n in range(513)]
        # A synthetic original pattern; no font, translation, save or game ROM.
        (out / "font.bin").write_bytes(b"".join(glyphs))
        (out / "strips.bin").write_bytes(bytes(v for v in bytes(2) + glyphs[0][:6] + bytes(2) + glyphs[512][:6] for _ in range(2)))
        asm = [
            'INCLUDE "constants/hardware.inc"',
            'INCLUDE "constants/charmap.asm"',
            'INCLUDE "constants/zh_vram.asm"',
            "DEF ZH_GLYPH_COUNT EQU 513", "DEF FONT_MASK EQU 7", "DEF wOptions2 EQU $c310",
            "DEF ZH_COMPILED_STRIP_COUNT EQU 513 * 3",

            "DEF wMenuBorderTopCoord EQU $c900",
            "DEF wMenuBorderBottomCoord EQU $c901",
            "DEF wMenuBorderLeftCoord EQU $c902",
            "DEF wMenuBorderRightCoord EQU $c903",
            'SECTION "fill", ROM0[$28]', "ByteFill:", " jp Fill",
            'SECTION "header", ROM0[$100]', " nop", " jp Start",
            " ds $150 - @, 0", 'SECTION "code", ROM0[$150]',
            "Start:", " di", " ld sp, $dfff",
            " ld a, 1", " ldh [rWBK], a",
            " ld a, ZH_VRAM_BOTH", " call ZhGlyphCacheInit",
            " ld bc, $1234", " ld de, $5678",
            " call ZhGlyphCacheAlloc", " ld [$c300], a",
            " call ZhGlyphCacheFind", " ld [$c301], a",
            " ld a, ZH_VRAM_BANK1_ONLY", " call ZhVramPolicyPush",
            " call ZhGlyphCacheAlloc", " ld [$c302], a",
            " call ZhVramPolicyPop", " ld a, [wZhPolicy]", " ld [$c303], a",
            " ld hl, wTilemap", " ld bc, 720", " ld a, $7f", " rst ByteFill",
            " ld a, $80", " ld [wTilemap], a",
            " ld a, BG_BANK1", " ld [wAttrmap], a",
            " call ZhGlyphCacheRecover",
            " ld a, [wZhCacheUsed]", " ld [$c305], a",
            " ld a, [wZhCacheUsed + ZH_CACHE_BLOCKS_PER_BANK]", " ld [$c306], a",
            " ld bc, $abcd", " ld de, $1234",
            " call ZhGlyphCacheAlloc", " ld [$c307], a",
            " ld hl, wZhCacheUsed", " ld bc, ZH_CACHE_BLOCKS",
            " ld a, 1", " rst ByteFill",
            " call ZhGlyphCacheAlloc", " ld a, 0", " adc 0", " ld [$c308], a",
        ]
        for number, glyph_id in enumerate((0, 511, 512)):
            asm += [f" ld bc, {glyph_id}", f" ld hl, ${0xc400 + number * 64:04x}",
                    " call ZhRasterGlyph"]
        asm += [
            " ld bc, 0", " ld de, 1536", " call ZhComposeCacheBlock",
            " call ZhGlyphCacheClear",
            " ld bc, 0",
            " ld de, 1536",
            " call ZhGlyphCacheAlloc",
            " ld hl, wTilemap",
            " ld [hl], $81",
            " ld a, 7",
            " ld [wAttrmap], a",
            " ld de, $dff0",
            " call ZhWindowBackupCell",
            " call ZhGlyphCacheClear",
            " ld bc, 1",
            " ld de, 2",
            " call ZhGlyphCacheAlloc",
            " ld hl, wTilemap",
            " ld [hl], $7f",
            " ld de, $dff0",
            " call ZhWindowRestoreCell",
            " ld a, [wTilemap]",
            " ld [$c309], a",
            " ld a, [wAttrmap]",
            " ld [$c30a], a",
            " ld hl, wTilemap + 2",
            " ld de, $3e00",
            " xor a",
            ' ld bc,0', ' ld de,1536', ' call ZhPlaceCacheBlock', ' ld de,$3e05',
            " ld a, [wTilemap + 2]",
            " ld [$c30b], a",
            " ld a, [wTilemap + 22]",
            " ld [$c30c], a",
            " ld a, e",
            " ld [$c30d], a",
            " call ZhBackupTempMap",
            " call ZhGlyphCacheClear",
            " ld bc, 1",
            " ld de, 2",
            " call ZhGlyphCacheAlloc",
            " ld hl, wTilemap",
            " ld [hl], $7f",
            " call ZhRestoreTempMap",
            " ld a, [wTilemap]",
            " ld [$c30e], a",
            " ld hl,wZhCachePixels", " ld de,$c320", " ld b,32", ".keepComposite", " ld a,[hli]", " ld [de],a", " inc de", " dec b", " jr nz,.keepComposite",
            " call ZhGlyphCacheClear", " ld a,ZH_VRAM_BOTH", " ld [wZhPolicy],a",
            " ld a,$42", " ld [wTilemap+20],a", " xor a", " ld [wOptions2],a", " ld hl,wTilemap", " ld a,$80",
            " call ZhPlaceLegacyLiteral", " ld a,[wTilemap]", " ld [$c311],a",
            " ld a,[wTilemap+20]", " ld [$c312],a",
            " ld a,7", " ld [wOptions2],a", " ld a,$80", " call ZhPlaceLegacyLiteral",
            " ld a,[wTilemap+1]", " ld [$c313],a",
            " ld a,$e1", " call ZhPlaceLegacyLiteral", " ld a,[wTilemap+2]", " ld [$c314],a",
            " call ZhGlyphCacheClear", " ld hl,wTilemap", " ld [hl],$7f", " ld a,$1d", " ld [wAttrmap],a",
            " ld de,$dff0", " call ZhWindowBackupCell", " ld a,e", " ld [$c350],a",
            " ld [hl],0", " ld de,$dff0", " call ZhWindowRestoreCell",
            " ld a,[wTilemap]", " ld [$c351],a", " ld a,[wAttrmap]", " ld [$c352],a",
            " ld hl,wTilemap", " ld bc,$0101", " ld de,$d004", " call ZhWindowCheckSpace",
            " ld a,0", " adc 0", " ld [$c353],a",
            " ld de,$d003", " call ZhWindowCheckSpace", " ld a,0", " adc 0", " ld [$c354],a",
            " ld a, $42", " ld [$c304], a", ".halt", " jr .halt",
            "Fill:", " ld [hli], a", " dec bc", " push af",
            " ld a, b", " or c", " jr z, .done", " pop af", " jr Fill",
            ".done", " pop af", " ret",
            "GetFarByte:", " ld a, [hl]", " ret",
            "ApplyAttrAndTilemapInVBlank:", " ret", "Get2bpp:", " ret",
            "ZhEnterFontText:", " ret",
            "ZhFontPages:", " db 0", " dw Font", " db 0", " dw Font + 512 * 18",
            "Font:", ' INCBIN "font.bin"',
            "FontTiles:", "FontNormal:", "FontNarrow:", "FontBold:", "FontItalic:", "FontSerif:", "FontChicago:", "FontMICR:", "FontUnown: ds 114*8, $a5",
            "ZhDialogueLatinStrips: ds 456", "ZhStartMenuLatinStrips: ds 456",
            "ZhCompiledStripPages:", *[f" db 0" + chr(10) + f" dw CompiledFont + {16 if page == 6 else 0}" for page in range(7)],
            "CompiledFont:", ' INCBIN "strips.bin"',
            'INCLUDE "engine/zh/glyph_cache.asm"',
            'INCLUDE "engine/zh/render.asm"',
            'INCLUDE "engine/zh/cache_render.asm"',
            'INCLUDE "engine/zh/cache_backup.asm"',
            'INCLUDE "engine/zh/cache_text.asm"',
            'SECTION "maps", WRAM0[$c500]',
            "wTilemap: ds 360", "wAttrmap: ds 360",
            'SECTION "state", WRAMX[$d000], BANK[1]',
            "wZhCacheKeys: ds ZH_CACHE_BLOCKS * 4",
            "wZhCacheUsed: ds ZH_CACHE_BLOCKS",
            "wZhPolicy: db", "wZhPolicyDepth: db",
            "wZhPolicyStack: ds ZH_VRAM_POLICY_DEPTH",
            'SECTION "pixels", WRAMX[$d300], BANK[1]',
            "wZhCachePixels: ds 32", "wZhStripPixels: ds 16", "wZhStripPlane: db",
        ]
        wram_call = (ROOT / "home/farcall.asm").read_text().split("StackCallInWRAMBankA::", 1)[1]
        asm += ['SECTION "wram helper", ROM0', "StackCallInWRAMBankA::" + wram_call]
        asm += ['INCLUDE "engine/zh/cache_window.asm"']
        asm += ['INCLUDE "engine/zh/cache_temp.asm"']
        asm += ['SECTION "temp keys", WRAMX[$d000], BANK[5]', "wZhTempKeys: ds 1800"]
        asm += ['SECTION "temp map", WRAMX[$d000], BANK[2]', "wTempTileMap: ds 360"]
        asm += ['SECTION "backup", WRAMX[$d340], BANK[1]', "wZhBackupCell: ds 6"]
        asm += ['SECTION "window", WRAMX[$d000], BANK[7]', "wWindowStack: ds $1000"]
        (out / "test.asm").write_text(chr(10).join(asm) + chr(10))
        for command in (
            ["rgbasm", "-I", str(ROOT) + "/", "-o", "test.o", "test.asm"],
            ["rgblink", "-o", "test.gb", "test.o"],
            ["rgbfix", "-v", "-p", "0", "test.gb"],
        ):
            subprocess.run(command, cwd=out, check=True, capture_output=True)
        commands = ["write ff50 1", "cpu 150 dfff", "run 30 0",
                    "read c300 15", "read c400 192", "read d300 32", "read c311 4", "read c320 32", "read c350 5", "quit"]
        result = subprocess.run([args.runner, str(out / "test.gb")],
                                input=chr(10).join(commands) + chr(10),
                                text=True, capture_output=True, check=True)
        rows = [bytes.fromhex(line) for line in result.stdout.splitlines()
                if re.fullmatch(r"(?:[0-9a-f]{2} )+", line)]
        assert len(rows) == 6, result.stdout
        assert rows[0] == bytes((0, 0, 43, 3, 0x42, 0, 1, 0, 1, 0x83, 7, 0x82, 0x83, 5, 0x83)), rows[0].hex()
        expected = bytearray()
        for glyph_id in (0, 511, 512):
            glyph = glyphs[glyph_id]
            raster = bytearray(64)
            for y in range(12):
                for x in range(12):
                    if glyph[x // 4 * 6 + y // 2] & (1 << (7 - y % 2 * 4 - x % 4)):
                        offset = y // 8 * 32 + x // 8 * 16 + y % 8 * 2
                        raster[offset] |= 128 >> (x % 8)
                        raster[offset + 1] |= 128 >> (x % 8)
            expected.extend(raster)
        assert rows[1] == expected, rows[1].hex()
        assert rows[2] == bytes([0xa5]*16+[0]*16), rows[2].hex()
        assert rows[3][0] != rows[3][2], "Font styles must use different keys"
        assert rows[3][1] == 0x42, "Latin output changed the cell below"
        assert rows[3][3] == 0xe1, "Static digits must remain original tiles"
        composite = bytearray(32)
        for y in range(12):
            shift = 4 if y % 2 == 0 else 0
            pixel = ((glyphs[0][y // 2] >> shift) & 15) << 4
            pixel |= (glyphs[512][y // 2] >> shift) & 15
            composite[(y + 4)*2:(y + 4)*2+2] = bytes((pixel,pixel))
        assert rows[4] == composite
        assert rows[5] == bytes([0xee,0x7f,0x0d,0,1]), rows[5].hex()
        print("PASS cache reuse, bank policy, restore, recovery, full refusal; glyph IDs 0/511/512 and Latin pixels, font keys, single-cell output")

if __name__ == "__main__":
    main()
