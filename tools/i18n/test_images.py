import csv
import struct
import tempfile
import zlib
from pathlib import Path
import images
import worksheet
import catalog

def png(value, width=8):
    def chunk(kind, data):
        return struct.pack('>I', len(data))+kind+data+struct.pack('>I', zlib.crc32(kind+data)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,8,8,0,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+bytes([value])*width)*8))+chunk(b'IEND',b'')

def rejects(fn):
    try: fn()
    except ValueError: return
    raise AssertionError('Expected rejection')

with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp); source=root/'source'; (source/'gfx').mkdir(parents=True)
    original=source/'gfx/example.png'; original.write_bytes(png(0))
    bundle=root/'bundle'; images.package(source, [], bundle, ['zh-Hans','ja'])
    inventory=catalog.read_rows(bundle/'resources.jsonl')
    table=bundle/'translations.csv'
    with table.open(encoding='utf-8-sig',newline='') as stream:
        reader=csv.DictReader(stream); fields=reader.fieldnames; records=list(reader)
    assert len(records)==1 and records[0]['resource_kind']=='image'
    replacement=bundle/'translated.png'; replacement.write_bytes(png(255))
    records[0]['translation_zh-Hans']='translated.png'
    with table.open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.DictWriter(stream,fields); writer.writeheader(); writer.writerows(records)
    selected=worksheet.select([],table,'zh-Hans',resources=inventory)
    assert worksheet.select([],table,'ja',resources=inventory)[0]['selection_status']=='unchanged_image'
    assert images.apply(source,selected,root/'result')==1
    assert (root/'result/gfx/example.png').read_bytes()==png(255) and original.read_bytes()==png(0)
    replacement.write_bytes(png(255,16))
    rejects(lambda: images.apply(source,selected,root/'bad'))
    selected=worksheet.select([],table,'zh-Hans',resources=inventory)
    rejects(lambda: images.apply(source,selected,root/'bad'))
    assert not (root/'bad').exists()
    rejects(lambda: images.safe_file(bundle,'../source/gfx/example.png'))
    original.write_bytes(png(1))
    rejects(lambda: images.apply(source,selected,root/'drift'))
print('PASS image packaging, language selection, replacement, dimension/drift/path rejection')
