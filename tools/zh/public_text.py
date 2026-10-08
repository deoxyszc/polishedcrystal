"""Compile reviewed page strings into original PlaceString byte streams.

No descriptors, private opcodes, runtime page parser, or save-data changes.
Only explicit consumers listed here are eligible for replacement.
"""
import csv
import re
from dialogue_text import encode

CONSUMERS = {
    'engine/battle/menu.asm': {'BattleMenuDataHeader.Strings'},
    'engine/battle/core.asm': {'BattleMenuPKMN_Loop.MenuData'},
    'engine/pokemon/party_menu.asm': {'PlacePartyNicknames.Cancel', 'ChooseAMonString'},
}


def reviewed_rows(source, language='zh-Hans'):
    with (source / 'translations.csv').open(encoding='utf-8-sig', newline='') as stream:
        return [row for row in csv.DictReader(stream)
                if row['source_path'] in CONSUMERS
                and row['id'].split('::')[1] in CONSUMERS[row['source_path']]
                and row.get('translation_' + language, '').strip()]


def characters(source, language='zh-Hans'):
    return {char for row in reviewed_rows(source, language)
            for char in row['translation_' + language] if not char.isascii()}


def apply(source, language='zh-Hans'):
    rows = reviewed_rows(source, language)
    expected = {row['id']: row for row in rows}
    found = set()
    outputs = {}
    for path, scopes in CONSUMERS.items():
        parent = scope = ''
        index = 0
        lines = []
        for line in (source / path).read_text().splitlines():
            label = re.match(r'^([A-Za-z_][\w]*|\.[\w]+):', line)
            if label:
                name = label[1]
                if not name.startswith('.'):
                    parent = name
                scope = parent + name if name.startswith('.') else name
                index = 0
            literal = re.search(r'\bdb\s+"([^"]*)"\s*(?:;.*)?$', line)
            if scope in scopes and literal:
                index += 1
                key = f'{path}::{scope}::{index}'
                row = expected.get(key)
                if row:
                    if literal[1] != row['original']:
                        raise ValueError('Source changed: ' + key)
                    data = encode(source, row['translation_' + language].strip())
                    start = line.index('db')
                    line = line[:start] + 'db ' + ','.join(map(str, data))
                    found.add(key)
            lines.append(line)
        outputs[path] = '\n'.join(lines) + '\n'
    if found != expected.keys():
        raise ValueError('Missing reviewed consumers: ' + repr(expected.keys() - found))
    for path, content in outputs.items():
        (source / path).write_text(content)
    return len(found)

SUMMARY_TERMS = {'Exp': '经验', 'Need': '还需', 'LevelUp': '升到',
                 'Level': '级', 'OT': '初训家/', 'Max': '100级',
                 'Attack': '攻击', 'Defense': '防御', 'SpAtk': '特攻',
                 'SpDef': '特防', 'Speed': '速度', 'Ability': '特性'}


def emit_summary_terms(source):
    lines=[]
    for label,text in SUMMARY_TERMS.items():
        lines += ['TextSummary'+label+':', ' db '+','.join(map(str,encode(source,text+'@')))]
    (source/'data/zh/summary_terms.asm').write_text('\n'.join(lines)+'\n')
