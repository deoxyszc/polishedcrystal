"""Stable-code radix pages with a 16-bit occupancy mask per tail nibble."""
def make_directory(mapping, characters, raw):
    if len(raw) != 18 * len(characters):
        raise ValueError('each Han glyph must contain three 6-byte strips')
    pages = {}
    for index, char in enumerate(characters):
        lead, tail = bytes.fromhex(mapping[char])
        if not 0 < lead < 64:
            raise ValueError('Han lead outside directory range')
        entries = pages.setdefault(lead, {}).setdefault(tail >> 4, {})
        if tail & 15 in entries:
            raise ValueError('duplicate stable code')
        entries[tail & 15] = raw[index*18:(index+1)*18]
    lines = ['TextHanDirectory:']
    lines += [' dw ' + (f'TextHanPage{i}' if i in pages else '0') for i in range(64)]
    for lead, blocks in sorted(pages.items()):
        lines += [f'TextHanPage{lead}:']
        for nibble in range(16):
            entries = blocks.get(nibble, {})
            mask = sum(1 << bit for bit in entries)
            label = f'TextHanBlock{lead}_{nibble}' if entries else '0'
            lines += [f' dw {mask}, {label}']
        for nibble, entries in sorted(blocks.items()):
            lines += [f'TextHanBlock{lead}_{nibble}:']
            for _, glyph in sorted(entries.items()):
                lines += [' db ' + ','.join(map(str, glyph))]
    return lines
