#!/usr/bin/env python3
"""Advisory source scan; never updates the reviewed control list."""
import argparse
import json
from pathlib import Path
from stable_codec import scan, validate_controls


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    p.add_argument('--controls', type=Path, default=Path(__file__).with_name('control_codes.json'))
    p.add_argument('--output', required=True, type=Path)
    args = p.parse_args()
    reviewed = json.loads(args.controls.read_text())
    validate_controls(reviewed)
    observed = scan(args.root)
    def definitions(data):
        return {(e['symbol'], e['byte'], e['kind']) for e in data['entries']}
    old, new = definitions(reviewed), definitions(observed)
    report = dict(advisory=True, exhaustive=False,
                  added_definitions=sorted(new-old), removed_definitions=sorted(old-new),
                  changed_sources=sorted(k for k in observed['sources'] if observed['sources'][k] != reviewed.get('source_evidence', {}).get(k)),
                  requires_review=bool(new != old or observed['sources'] != reviewed.get('source_evidence')),
                  note='Scan is evidence only. Unrecognized inline semantics may require review even with no reported difference.',
                  observed=observed)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='observed'},ensure_ascii=False))


if __name__ == '__main__':
    main()
