#!/usr/bin/env python3
"""Multilingual CSV drafts; selection does not authorize runtime insertion."""
import argparse
import csv
import hashlib
import re
from pathlib import Path
import catalog

READY = {'ready', 'ready_with_typed_format', 'ready_with_shared_tail'}
FIELDS = ['id', 'source_sha256', 'profile', 'source_path', 'source_line', 'original', 'resource_kind', 'review_status']

def language(value):
    if not re.fullmatch(r'[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*', value):
        raise ValueError('Invalid language tag: ' + value)
    return value

def combined_rows(rows, resources=(), repository_paths=False):
    result = [{**row, 'resource_kind': 'text', 'review_status': row['translation_status']}
              for row in rows if row['translation_status'] in READY]
    for item in resources:
        if Path(item['source_path']).suffix.lower() != '.png':
            continue
        result.append({**item, 'source_sha256': item['sha256'], 'profile': 'all',
                       'source_line': '', 'translation_view': ('' if repository_paths else 'originals/') + item['source_path'],
                       'translation_status': 'ready', 'resource_kind': 'image',
                       'review_status': item['status']})
    return result

def cell(row, field):
    return str(row['translation_view'] if field == 'original' else row[field])

def export(rows, path, languages, resources=()):
    rows = combined_rows(rows, resources)
    languages = [language(tag) for tag in languages]
    if not languages or len({x.lower() for x in languages}) != len(languages):
        raise ValueError('Languages must be nonempty and unique')
    with Path(path).open('x', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS + ['translation_' + x for x in languages])
        writer.writeheader()
        for row in rows:
            if row['translation_status'] in READY:
                writer.writerow({key: cell(row, key) for key in FIELDS})

def select(rows, path, target_language, fallback='error', resources=(), repository_paths=False):
    rows = combined_rows(rows, resources, repository_paths)
    column = 'translation_' + language(target_language)
    expected = {row['id']: row for row in rows if row['translation_status'] in READY}
    selected = []
    seen = set()
    with Path(path).open(encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames or []
        if len(fields) != len(set(fields)) or not set(FIELDS + [column]).issubset(fields):
            raise ValueError('Missing required fields/language column or duplicate headers: ' + column)
        for record in reader:
            if None in record or any(value is None for value in record.values()):
                raise ValueError('Malformed CSV row')
            key = record['id']
            if key in seen or key not in expected:
                raise ValueError('Duplicate or unknown ID: ' + key)
            seen.add(key)
            row = expected[key]
            for field in FIELDS:
                value = cell(row, field)
                if record[field] != value:
                    raise ValueError('Source provenance mismatch: ' + key + ' / ' + field)
            translated = record[column]
            if not translated.strip():
                if fallback == 'error' and row['resource_kind'] == 'text':
                    raise ValueError('Empty translation for ' + target_language + ': ' + key)
                translated = row['translation_view']
                status = 'unchanged_image' if row['resource_kind'] == 'image' else 'original_fallback'
            else:
                status = 'translated'
            if row['resource_kind'] == 'image' and status == 'translated':
                import images
                replacement = images.safe_file(Path(path).resolve().parent, translated)
                images.png_info(replacement)
                row = {**row, 'replacement_path': str(replacement), 'replacement_sha256': hashlib.sha256(replacement.read_bytes()).hexdigest()}
            selected.append({**row, 'language': target_language, 'translation': translated,
                             'selection_status': status, 'runtime_admitted': False})
    if seen != set(expected):
        raise ValueError('Incomplete CSV coverage')
    return selected

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    exp = sub.add_parser('export')
    exp.add_argument('--languages', nargs='+', default=['zh-Hans', 'zh-Hant'])
    sel = sub.add_parser('select')
    sel.add_argument('--repository-paths', action='store_true')
    sel.add_argument('--csv', type=Path, required=True)
    sel.add_argument('--language', required=True)
    sel.add_argument('--fallback', choices=['error', 'original'], default='error')
    for command in (exp, sel):
        command.add_argument('--messages', type=Path, required=True)
        command.add_argument('--out', type=Path, required=True)
        command.add_argument('--resources', type=Path)
    args = parser.parse_args()
    rows = catalog.read_rows(args.messages)
    resources = catalog.read_rows(args.resources) if args.resources else []
    if args.out.exists():
        parser.error('Output already exists')
    if args.command == 'export':
        export(rows, args.out, args.languages, resources)
    else:
        result = select(rows, args.csv, args.language, args.fallback, resources, args.repository_paths)
        catalog.jsonl(args.out, result)

if __name__ == '__main__':
    main()
