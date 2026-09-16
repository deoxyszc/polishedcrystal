#!/usr/bin/env python3
"""Package PNG originals and apply compatible replacements to a new source tree."""
import argparse
import hashlib
import shutil
import struct
import zlib
from pathlib import Path
import catalog
import resources
import worksheet

def safe_file(root, relative):
    relative = Path(relative)
    if relative.is_absolute() or '..' in relative.parts:
        raise ValueError('Expected a relative path inside the resource package')
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError('Missing file or path outside package: ' + str(relative))
    return path

def png_info(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Not a PNG: ' + str(path))
    offset = 8
    chunks = {}
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError('Truncated PNG')
        size = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+size]
        end = offset + 12 + size
        if end > len(data) or zlib.crc32(kind + payload) & 0xffffffff != struct.unpack('>I', data[end-4:end])[0]:
            raise ValueError('Invalid PNG chunk')
        chunks.setdefault(kind, []).append(payload)
        offset = end
        if kind == b'IEND':
            break
    if offset != len(data) or b'IEND' not in chunks or len(chunks.get(b'IHDR', [])) != 1 or len(chunks[b'IHDR'][0]) != 13 or b'IDAT' not in chunks:
        raise ValueError('Invalid PNG structure')
    width, height, depth, color, compression, filtering, interlace = struct.unpack('>IIBBBBB', chunks[b'IHDR'][0])
    if not width or not height or width * height > 16000000 or compression or filtering or interlace:
        raise ValueError('Unsupported PNG dimensions or encoding (noninterlaced required)')
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color)
    if channels is None or depth not in {0: (1,2,4,8,16), 2: (8,16), 3: (1,2,4,8), 4: (8,16), 6: (8,16)}[color]:
        raise ValueError('Invalid PNG color format')
    stride = (width * channels * depth + 7) // 8 + 1
    decoder = zlib.decompressobj()
    pixels = decoder.decompress(b''.join(chunks[b'IDAT']), stride * height + 1)
    if len(pixels) != stride * height or not decoder.eof or decoder.unused_data or any(pixels[i] > 4 for i in range(0, len(pixels), stride)):
        raise ValueError('Invalid PNG pixel stream')
    return chunks[b'IHDR'][0], chunks.get(b'PLTE', []), chunks.get(b'tRNS', [])

def package(source, messages, out, languages):
    source = source.resolve()
    if out.exists() or out.resolve().is_relative_to(source):
        raise ValueError('Package must be a new directory outside source')
    inventory = resources.inventory(source, resources.REVIEW_SHA)
    # Keep all inventory evidence, but only editable source PNGs become image rows.
    for row in inventory:
        if row['source_path'].endswith('.png'):
            safe_file(source, row['source_path'])
    out.mkdir(parents=True)
    catalog.jsonl(out / 'resources.jsonl', inventory)
    catalog.jsonl(out / 'messages.jsonl', messages)
    for row in inventory:
        if row['source_path'].endswith('.png'):
            destination = out / 'originals' / row['source_path']
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(safe_file(source, row['source_path']), destination)
    worksheet.export(messages, out / 'translations.csv', languages, inventory)
    shutil.copyfile(Path(__file__).with_name('editor.html'), out / 'editor.html')

def apply(source, selected, out):
    source = source.resolve()
    if out.exists() or out.resolve().is_relative_to(source) or source.is_relative_to(out.resolve()):
        raise ValueError('Destination must be new and separate from source')
    replacements = []
    seen = set()
    for row in selected:
        if row['resource_kind'] != 'image':
            continue
        relative = row['source_path']
        if relative in seen or not relative.startswith('gfx/') or not relative.endswith('.png'):
            raise ValueError('Duplicate or invalid image target')
        seen.add(relative)
        original = safe_file(source, relative)
        if hashlib.sha256(original.read_bytes()).hexdigest() != row['source_sha256']:
            raise ValueError('Source image drift: ' + relative)
        if row['selection_status'] == 'unchanged_image':
            continue
        replacement = Path(row['replacement_path'])
        if hashlib.sha256(replacement.read_bytes()).hexdigest() != row['replacement_sha256']:
            raise ValueError('Replacement changed after selection')
        if png_info(original) != png_info(replacement):
            raise ValueError('Replacement dimensions, color format, palette or transparency differ: ' + relative)
        replacements.append((relative, replacement.read_bytes()))
    # Validate all replacements before creating any destination.
    if any(p.is_symlink() for p in source.rglob('*') if '.git' not in p.parts):
        raise ValueError('Source symlinks are unsupported')
    shutil.copytree(source, out, ignore=shutil.ignore_patterns('.git'))
    for relative, data in replacements:
        (out / relative).write_bytes(data)
    return len(replacements)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    exp = sub.add_parser('package')
    exp.add_argument('--messages', type=Path, required=True)
    exp.add_argument('--languages', nargs='+', default=['zh-Hans','zh-Hant'])
    imp = sub.add_parser('apply')
    imp.add_argument('--selected', type=Path, required=True)
    for command in (exp, imp):
        command.add_argument('--source', type=Path, required=True)
        command.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'package':
        package(args.source, catalog.read_rows(args.messages), args.out, args.languages)
    else:
        print('Replaced PNGs:', apply(args.source, catalog.read_rows(args.selected), args.out))

if __name__ == '__main__':
    main()
