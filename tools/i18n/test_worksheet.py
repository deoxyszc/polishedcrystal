import csv
import tempfile
from pathlib import Path
import worksheet

def rejects(fn):
    try:
        fn()
    except ValueError:
        return
    raise AssertionError('Expected rejection')

with tempfile.TemporaryDirectory() as temp:
    path = Path(temp) / 'translations.csv'
    rows = [dict(id='sample', source_sha256='abc', profile='normal',
                 source_path='maps/Test.asm', source_line=2,
                 translation_view='Hello, "friend"!\n{TEXT_RAM:wName}',
                 translation_status='ready')]
    worksheet.export(rows, path, ['zh-Hans', 'ja'])
    assert path.read_bytes().startswith(b'\xef\xbb\xbf')
    with path.open(encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames
        records = list(reader)
    assert records[0]['original'] == rows[0]['translation_view']
    rejects(lambda: worksheet.select(rows, path, 'zh-Hans'))
    rejects(lambda: worksheet.select(rows, path, 'fr'))
    assert worksheet.select(rows, path, 'ja', 'original')[0]['translation'] == rows[0]['translation_view']
    def save():
        with path.open('w', encoding='utf-8-sig', newline='') as stream:
            writer = csv.DictWriter(stream, fields)
            writer.writeheader()
            writer.writerows(records)
    records[0]['translation_zh-Hans'] = '你好，"朋友"！\n{TEXT_RAM:wName}'
    records[0]['translation_ja'] = 'こんにちは\n{TEXT_RAM:wName}'
    save()
    for tag in ('zh-Hans', 'ja'):
        result = worksheet.select(rows, path, tag)[0]
        assert result['translation'] == records[0]['translation_' + tag]
        assert result['language'] == tag and result['runtime_admitted'] is False
    records[0]['source_sha256'] = 'changed'
    save()
    rejects(lambda: worksheet.select(rows, path, 'ja'))
    records[0]['source_sha256'] = 'abc'
    records.append(dict(records[0]))
    save()
    rejects(lambda: worksheet.select(rows, path, 'ja'))
    records.clear()
    save()
    rejects(lambda: worksheet.select(rows, path, 'ja'))
print('PASS multilingual CSV quoting, exact language selection, fallback and provenance rejection')
