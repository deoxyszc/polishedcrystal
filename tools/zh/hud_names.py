"""Generate display-only battle names; never change nickname/save encoding."""
import csv
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from text_layout import encode_2bpp
from suite_layout import region
from cache_text import compile_surface

def generate(source, language, font_path, *, party=False):
    config = region(language, "party.name" if party else "battle.name")
    font = ImageFont.truetype(str(font_path), 12)
    with (source / 'translations.csv').open(encoding='utf-8-sig', newline='') as f:
        rows = [r for r in csv.DictReader(f) if r['source_path'] == 'data/pokemon/names.asm' and r.get('translation_' + language, '').strip()]
    table = 'ZhPartyNameTable' if party else 'ZhBattleNameTable'
    lines = [table + ':']
    bodies = []
    for i, row in enumerate(rows):
        name = row['translation_' + language].strip().rstrip('@')
        if not 1 <= len(name) <= 5 or any(c.isascii() for c in name):
            raise ValueError('Battle names require 1–5 CJK characters: ' + row['id'])
        # One pixel less advance; validate actual ink instead of silently clipping.
        for k, char in enumerate(name):
            glyph = Image.new('1', (24, 24))
            gd = ImageDraw.Draw(glyph); gd.fontmode = '1'
            gd.text((0, 12), char, font=font, fill=1, anchor='ls')
            box = glyph.getbbox()
            if box is None or box[2] > config.advance or box[3] > config.height:
                raise ValueError('Glyph does not fit 11px HUD advance: ' + char)
        # Dense HUD: the original container cannot fit 12px advances.
        layout=config.layout(font)
        layout.append(name)
        width = (len(name) * config.advance + 7) // 8
        data = encode_2bpp(layout.image.crop((0,0,width*8,16)))
        if len(row['original']) != 10 or any(c in row['original'] for c in (chr(34), chr(10), chr(13))):
            raise ValueError('Invalid original nickname record')
        original = row['original'][:10].ljust(10, '@')
        label = '.name' + str(i)
        lines.append(' dw ' + label)
        streams, blocks = compile_surface(data, width*8, config.height, label)
        bodies += [label + ':', ' db ' + chr(34) + original + chr(34), ' db ' + str(width)] + streams[0] + blocks
    lines += [' dw 0'] + bodies
    (source / ('data/zh/party_names.asm' if party else 'data/zh/battle_names.asm')).write_text(chr(10).join(lines) + chr(10))
