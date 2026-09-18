"""Generate the reviewed six-member party layout preview in a staged build.

All displayed metadata is required external input, not live party data.
"""
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


STATUSES = {'none': None, 'poison': 0, 'paralysis': 1, 'sleep': 2,
            'burn': 3, 'freeze': 4}
GENDERS = {'male': '<MALE>', 'female': '<FEMALE>', 'none': ' '}


def validate_rows(rows):
    if not isinstance(rows, list) or len(rows) != 6:
        raise ValueError('Supply exactly six rows; no metadata defaults exist')
    keys = {'hp', 'max_hp', 'level', 'gender', 'shiny', 'status'}
    for row in rows:
        if not isinstance(row, dict) or set(row) != keys:
            raise ValueError('Each row requires hp, max_hp, level, gender, shiny, status')
        for key, low, high in [('hp', 0, 999), ('max_hp', 1, 999), ('level', 1, 100)]:
            if type(row[key]) is not int or not low <= row[key] <= high:
                raise ValueError('Invalid ' + key)
        if row['hp'] > row['max_hp']:
            raise ValueError('hp exceeds max_hp')
        if (not isinstance(row['gender'], str) or row['gender'] not in GENDERS
                or not isinstance(row['status'], str) or row['status'] not in STATUSES
                or type(row['shiny']) is not bool):
            raise ValueError('Invalid gender, status or shiny flag')


def render_rows(rows):
    validate_rows(rows)
    code = ['ZhPartyNamePreview::', ' ld a,1', ' ldh [rVBK],a',
            ' ld hl,$8800', ' ld de,.Tiles', ' ld b,BANK(.Tiles)',
            ' ld c,14', ' call Get2bpp', ' xor a', ' ldh [rVBK],a']
    attrs = ['ZhPartyPreviewAttrs::']
    status_code = ['ZhPartyBattleStatus::', ' ld a,1', ' ldh [rVBK],a',
                   ' ld hl,$8d00', ' ld de,.Tiles', ' ld b,BANK(.Tiles)',
                   ' ld c,10', ' call Get2bpp', ' xor a', ' ldh [rVBK],a']
    colors = ['ZhPartyStatusColors::']
    def put(target, x, y, value, attr=False):
        target.extend([f' hlcoord {x},{y}' + (',wAttrmap' if attr else ''),
                       f' ld [hl],{value}'])
    for index, row in enumerate(rows):
        y = 1 + index * 2
        for yy in (y, y + 1):
            code.extend([f' hlcoord 3,{yy}', ' ld bc,17', ' ld a,$7f', ' rst ByteFill'])
        for yy in range(2):
            for x in range(7):
                put(code, 3 + x, y + yy, 128 + yy * 7 + x)
        put(code, 10, y, '"' + GENDERS[row['gender']] + '"')
        put(code, 11, y, '"<SHINY>"' if row['shiny'] else '$7f')
        for x, char in enumerate(f"{row['hp']:>3}/{row['max_hp']:>3}", 13):
            put(code, x, y, '"' + char + '"')
        fill = (row['hp'] * 32 + row['max_hp'] - 1) // row['max_hp']
        code.extend([f' hlcoord 13,{y+1}', ' ld d,4', f' ld e,{fill}',
                     ' ld c,1', ' call DrawBattleHPBar'])
        for x, char in enumerate(f"{row['level']:>3}", 10):
            put(code, x, y + 1, '"' + char + '"')
        attrs.extend([f' hlcoord 3,{y},wAttrmap', ' lb bc,2,7', ' ld a,8',
                      ' call FillBoxWithByte'])
        for x in range(10, 20):
            put(attrs, x, y, 4 if x < 12 else 0, True)
            put(attrs, x, y + 1, 1 if x >= 13 else 0, True)
        status = STATUSES[row['status']]
        if status is not None:
            for x in range(2):
                put(status_code, 11 + x, y, 208 + status * 2 + x)
                put(colors, 11 + x, y, 13 + status // 2, True)
    code.extend([' call ZhPartyBattleStatus', ' ret', '.Tiles:',
                 ' INCBIN "gfx/zh/party_preview_name.2bpp"'])
    attrs.append(' ret')
    status_code.extend([' ret', '.Tiles:', ' INCBIN "gfx/zh/party_preview_status.2bpp"'])
    colors.extend([' ld hl,.Pals', ' ld de,wBGPals1 palette 5', ' ld bc,3 palettes',
                   ' call FarCopyColorWRAM', ' ret', '.Pals:',
                   ' RGB 31,31,31, 27,11,27, 30,20,0, 0,0,0',
                   ' RGB 31,31,31, 17,17,17, 31,8,2, 0,0,0',
                   ' RGB 31,31,31, 9,18,31, 27,6,28, 0,0,0'])
    return '\n'.join(code + attrs + status_code + colors) + '\n'


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
    if not isinstance(terms, dict) or set(terms) != {'name', 'cancel', 'prompt', 'rows'}:
        raise ValueError('Expected name, cancel, prompt and six explicit rows')
    if any(not isinstance(t, str) or not t or '\n' in t or '\r' in t
           for t in (terms[k] for k in ('name', 'cancel', 'prompt'))):
        raise ValueError('Labels must be nonempty single-line strings')
    validate_rows(terms['rows'])
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
    template = render_rows(terms['rows']) + Path(__file__).with_name('party_layout_preview.asm').read_text()
    (source / 'engine/zh/party_preview.asm').write_text(template)
    paths['engine/pokemon/party_menu.asm'].write_text(party)
    paths['engine/gfx/cgb_layouts.asm'].write_text(cgb)
    paths['main.asm'].write_text(texts['main.asm'] +
        '\nSECTION "Party layout preview", ROMX\nINCLUDE "engine/zh/party_preview.asm"\n')
