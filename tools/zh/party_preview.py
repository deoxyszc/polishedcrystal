"""Generate the reviewed six-member party layout preview in a staged build.

This is a visual stress fixture, not a live party-data renderer.
"""
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def encode(image):
    data = bytearray()
    for ty in range(image.height // 8):
        for tx in range(image.width // 8):
            for y in range(8):
                row = sum(128 >> x for x in range(8)
                          if image.getpixel((tx * 8 + x, ty * 8 + y)))
                data.extend((row, row))
    return bytes(data)


def generate(source, font_path, terms_path):
    source = Path(source)
    terms = json.loads(Path(terms_path).read_text(encoding='utf-8'))
    if set(terms) != {'name', 'cancel', 'prompt'}:
        raise ValueError('Expected name, cancel and prompt strings')
    if any(not isinstance(t, str) or not t or '\n' in t or '\r' in t
           for t in terms.values()):
        raise ValueError('Labels must be nonempty single-line strings')
    font = ImageFont.truetype(str(font_path), 12)
    if len(terms['name']) > 5 or any(font.getlength(c) > 12 for c in terms['name']):
        raise ValueError('Preview name must fit five 12px glyphs at 11px advance')
    for key, width in [('cancel', 24), ('prompt', 144)]:
        if font.getlength(terms[key]) > width:
            raise ValueError(key + ' exceeds its pixel budget')
    # Inspect all patch anchors before generating or modifying staged files.
    paths = {name: source / name for name in (
        'engine/pokemon/party_menu.asm', 'engine/gfx/cgb_layouts.asm', 'main.asm')}
    texts = {name: path.read_text() for name, path in paths.items()}
    party = texts['engine/pokemon/party_menu.asm']
    anchor = 'call PlacePartyMonStatus'
    if party.count(anchor) != 1 or 'ZhPartyNamePreview' in party:
        raise ValueError('Unsupported or already patched party menu')
    start = party.index('PlacePartyMenuText:')
    end = party.index('PartyMenuStrings:', start)
    party = party[:start] + 'PlacePartyMenuText:\n farjp ZhPartyFooterPreview\n\n' + party[end:]
    party = party.replace(anchor, anchor + '\n farcall ZhPartyNamePreview')
    cgb = texts['engine/gfx/cgb_layouts.asm']
    start = cgb.index('_CGB_PartyMenu:')
    end = cgb.index('PartyMenuBGPals:', start)
    part = cgb[start:end]
    if part.count('jmp ApplyAttrMap') != 1:
        raise ValueError('Unsupported party palette layout')
    part = part.replace('jmp ApplyAttrMap', 'farcall ZhPartyPreviewAttrs\n farcall ZhPartyFooterAttrs\n farcall ZhPartyStatusColors\n jmp ApplyAttrMap')
    cgb = cgb[:start] + part + cgb[end:]

    name = Image.new('1', (56, 16))
    draw = ImageDraw.Draw(name)
    draw.fontmode = '1'
    for index, char in enumerate(terms['name']):
        draw.text((index * 11, 10), char, font=font, fill=1, anchor='ls')
    # Convert existing original assets using the project's own build rules.
    # Do not rasterize borders or status art from screenshots.
    subprocess.run(['make', 'gfx/frames/1.1bpp', 'gfx/battle/status.2bpp'],
                   cwd=source, check=True)
    frame = (source / 'gfx/frames/1.1bpp').read_bytes()
    top = frame[8:16]
    footer = bytearray()
    for key, width, height, baseline in [('cancel', 24, 24, 15), ('prompt', 144, 16, 12)]:
        canvas = Image.new('1', (width, height))
        if key == 'cancel':
            # Shared tile: retain the sixth name's lower-left 8x8 pixels.
            canvas.paste(name.crop((0, 8, 8, 16)), (16, 0))
            for y, row in enumerate(top):
                for x in range(width):
                    if row & (128 >> (x % 8)):
                        canvas.putpixel((x, 16 + y), 1)
        draw = ImageDraw.Draw(canvas)
        draw.fontmode = '1'
        draw.text((0, baseline), terms[key], font=font, fill=1, anchor='ls')
        footer.extend(encode(canvas))
    raw = (source / 'gfx/battle/status.2bpp').read_bytes()
    status = bytearray()
    for index in range(5):
        block = raw[(index + 1) * 32:(index + 2) * 32]
        if index % 2:
            block = bytes(v for j in range(0, 32, 2) for v in (block[j + 1], block[j]))
        status.extend(block)
    out = source / 'gfx/zh'
    out.mkdir(exist_ok=True)
    for filename, data in [('name', encode(name)), ('footer', footer), ('status', status)]:
        (out / ('party_preview_' + filename + '.2bpp')).write_bytes(data)
    template = Path(__file__).with_name('party_layout_preview.asm').read_text()
    (source / 'engine/zh/party_preview.asm').write_text(template)
    paths['engine/pokemon/party_menu.asm'].write_text(party)
    paths['engine/gfx/cgb_layouts.asm'].write_text(cgb)
    paths['main.asm'].write_text(texts['main.asm'] +
        '\nSECTION "Party layout preview", ROMX\nINCLUDE "engine/zh/party_preview.asm"\n')
