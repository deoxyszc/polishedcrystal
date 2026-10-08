#!/usr/bin/env python3
"""Render recorded editor elements with the exact imported game glyphs.

This is a static layout preview, not emulator evidence. No system-font fallback.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
from PIL import Image


def render(data, output):
    canvas = Image.frombytes('RGB', (160, 144), base64.b64decode(data['background'])).convert('RGBA')
    missing = set()
    records = []
    for element in data['elements']:
        x, y = element['x'], element['y']
        if element['type'] == 'image':
            if not element.get('rgba'):
                raise ValueError('Missing extracted image: ' + element['name'])
            layer = Image.frombytes('RGBA', (element['w'], element['h']), base64.b64decode(element['rgba']))
        else:
            text = element.get('text', '')
            width = sum(data['glyphs'].get(c, {}).get('w', 0) for c in text)
            layer = Image.new('RGBA', (max(1, width), 16))
            color = element.get('color', '#000000').lstrip('#')
            ink = tuple(int(color[i:i+2], 16) for i in (0, 2, 4)) + (255,)
            cursor = 0
            for char in text:
                glyph = data['glyphs'].get(char)
                if glyph is None:
                    missing.add(char)
                    continue
                offset = element.get('cjk', 0) if glyph['h'] == 12 else element.get('latin', 4)
                if offset + glyph['h'] > 16:
                    raise ValueError('Glyph exceeds 16px cell: ' + element['name'])
                for gy in range(glyph['h']):
                    for gx in range(glyph['w']):
                        if glyph['pixels'][gy*glyph['w']+gx]:
                            layer.putpixel((cursor+gx, offset+gy), ink)
                cursor += glyph['w']
        if x < 0 or y < 0 or x+layer.width > 160 or y+layer.height > 144:
            raise ValueError('Element exceeds screen: ' + element['name'])
        canvas.alpha_composite(layer, (x, y))
        records.append({'name': element['name'], 'x': x, 'y': y, 'width': layer.width,
                        'height': layer.height, 'text': element.get('text'), 'binding': element.get('binding')})
    if missing:
        raise ValueError('Missing imported glyphs: ' + ''.join(sorted(missing)))
    canvas.convert('RGB').save(output)
    canvas.convert('RGB').resize((960, 864), Image.Resampling.NEAREST).save(output.with_name(output.stem+'-6x.png'))
    return {'kind': 'static-layout-preview-not-ROM', 'elements': records,
            'preview_sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
            'provenance': data.get('provenance', {})}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scene', type=Path, required=True, help='Packaged scene.json from build_preview.py')
    parser.add_argument('--layout', type=Path, help='Recorded editor JSON, optional replacement elements')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.scene.read_text())
    if args.layout:
        layout = json.loads(args.layout.read_text())
        elements = layout.get('items', layout.get('elements'))
        if not isinstance(elements, list):
            parser.error('Layout must contain items or elements')
        assets = {e.get('binding', e['name']): e for e in data['elements']}
        data['elements'] = [dict(assets.get(e.get('binding', e['name']), {}), **e) for e in elements]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    report = render(data, args.out)
    report['scene_sha256'] = hashlib.sha256(args.scene.read_bytes()).hexdigest()
    if args.layout:
        report['layout_sha256'] = hashlib.sha256(args.layout.read_bytes()).hexdigest()
    args.out.with_suffix('.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')


if __name__ == '__main__':
    main()
