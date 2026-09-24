#!/usr/bin/env python3
"""Offline GB2312 codec planner. Does not change ROM assets or runtime decoding."""
import argparse
import hashlib
import json
import re
from pathlib import Path

ALGORITHM = "gb2312-pairs-v1"


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(",", ":")).encode()).hexdigest()


def scan(root):
    paths = ("constants/charmap.asm", "constants/zh_encoding.asm", "home/text.asm",
             "macros/scripts/text.asm", "data/text/ngrams.asm")
    sources = {p: (root / p).read_text() for p in paths}
    constants = {}
    for name, number in re.findall(r"DEF\s+(\w+)\s+EQU\s+(\$[0-9a-fA-F]+|\d+)\b", sources[paths[0]]):
        constants[name] = int(number[1:], 16) if number.startswith("$") else int(number)
    required = ("NUM_TEXT_COMMANDS", "NGRAMS_START", "NGRAMS_END", "SPECIALS_START", "BATTLEEXTRA_GFX_START")
    if any(n not in constants for n in required):
        raise ValueError("unsupported charmap boundaries")
    entries = []
    for line, raw in enumerate(sources[paths[0]].splitlines(), 1):
        if not raw.lstrip().startswith("charmap "):
            continue
        match = re.fullmatch(r'\s*charmap\s+"([^"\\]*)",\s*\$([0-9a-fA-F]{2})\s*(?:;.*)?', raw)
        if not match:
            raise ValueError(f"unsupported charmap syntax at line {line}")
        symbol, number = match.groups()
        byte = int(number, 16)
        kind = ("script" if byte < constants["NUM_TEXT_COMMANDS"] else
                "ngram" if constants["NGRAMS_START"] <= byte <= constants["NGRAMS_END"] else
                "string_control" if constants["SPECIALS_START"] <= byte < constants["BATTLEEXTRA_GFX_START"] else
                "literal")
        entries.append(dict(byte=byte, symbol=symbol, kind=kind, source=paths[0], line=line))
    text = sources["home/text.asm"]
    for label, start, end in (("TextCommands", 0, constants["NUM_TEXT_COMMANDS"]),
                               ("SpecialCharacters", constants["SPECIALS_START"], constants["BATTLEEXTRA_GFX_START"])):
        block = re.search(r"^" + label + r"::?\s*\n(.*?)(?=^\w[^\n]*:)", text, re.M | re.S)
        if not block:
            raise ValueError(f"missing dispatch table {label}")
        handlers = re.findall(r"^\s*dw\s+(\w+)\s*(?:;.*)?$", block[1], re.M)
        if len(handlers) != end - start:
            raise ValueError(f"unrecognized dispatch table {label}")
        for byte, handler in zip(range(start, end), handlers):
            matches = [e for e in entries if e["byte"] == byte]
            if not matches:
                raise ValueError(f"dispatch byte {byte:02x} missing from charmap")
            for entry in matches:
                entry["handler"] = handler
    for line, raw in enumerate(sources[paths[1]].splitlines(), 1):
        if not re.match(r"DEF ZH_(?:CTRL_|ESCAPE|STREAM_COMMAND|PAIR_COMMAND)", raw):
            continue
        match = re.fullmatch(r"DEF (\w+) EQU \$([0-9a-fA-F]{2})\s*(?:;.*)?", raw)
        if not match:
            raise ValueError(f"unsupported ZH control declaration at line {line}")
        entries.append(dict(byte=int(match[2], 16), symbol=match[1], kind="zh_control", source=paths[1], line=line))
    # Conservative proposal: all named bytes are unavailable as leads. Controls
    # are unavailable in either position, protecting byte-wise sentinel scans.
    controls = sorted({e["byte"] for e in entries if e["kind"] != "literal"})
    occupied = {e["byte"] for e in entries}
    # Include unnamed literal graphics slots handled by PlaceNextChar.
    occupied.update(range(constants["BATTLEEXTRA_GFX_START"], 256))
    leads = [b for b in range(1, 256) if b not in occupied]
    tails = [b for b in range(1, 256) if b not in controls]
    return dict(schema=1, scope="text script, string dispatch, ZH declared controls",
                runtime_compatible=False,
                limitations=["Static repository-specific scanner, not an RGBDS interpreter.",
                             "No claim that undeclared inline controls or every reader are analyzed.",
                             "New two-byte decoding must be implemented before runtime use.",
                             "Huffman payload is a bitstream, not free character space."],
                sources={p: hashlib.sha256(s.encode()).hexdigest() for p, s in sources.items()},
                entries=entries, controls=controls, leads=leads, tails=tails)


def repertoire():
    result = []
    for high in range(0xb0, 0xf8):
        for low in range(0xa1, 0xff):
            raw = bytes((high, low))
            try:
                char = raw.decode("gb2312")
            except UnicodeDecodeError:
                continue
            result.append((char, raw.hex().upper()))
    if len(result) != 6763:
        raise ValueError("unexpected GB2312 Han repertoire")
    return result


def generate(audit, previous=None):
    chars = repertoire()
    candidates = [f"{a:02X}{b:02X}" for a in audit["leads"] for b in audit["tails"]]
    legal = set(candidates)
    if len(legal) < len(chars):
        raise ValueError(f"insufficient capacity: {len(legal)} pairs for {len(chars)} characters")
    old = {}
    if previous is not None:
        if previous.get("schema") != 1 or previous.get("algorithm") != ALGORITHM:
            raise ValueError("unsupported previous encoding table")
        rows = previous["mapping"]
        if previous.get("mapping_sha256") != digest(rows):
            raise ValueError("previous mapping checksum mismatch")
        if [(e["char"], e["gb2312"]) for e in rows] != chars:
            raise ValueError("previous repertoire/order differs from GB2312")
        values = [e["code"] for e in rows]
        if len(set(values)) != len(values) or any(not re.fullmatch(r"[0-9A-F]{4}", c) for c in values):
            raise ValueError("invalid or duplicate previous codes")
        old = {e["char"]: e["code"] for e in rows}
    mapping = {c: code for c, code in old.items() if code in legal}
    used = set(mapping.values())
    # Preserve legal native GB2312 pairs before filling the remaining slots.
    # With the current English literal range, native leads are unavailable.
    for char, native in chars:
        if char not in mapping and native in legal and native not in used:
            mapping[char] = native
            used.add(native)
    free = iter(c for c in candidates if c not in used)
    for char, _ in chars:
        if char not in mapping:
            mapping[char] = next(free)
    rows = [dict(char=c, gb2312=g, code=mapping[c]) for c, g in chars]
    changes = [dict(char=c, old=old[c], new=mapping[c]) for c, _ in chars if c in old and old[c] != mapping[c]]
    table = dict(schema=1, algorithm=ALGORITHM, mapping=rows, mapping_sha256=digest(rows), controls=audit["controls"])
    report = dict(mode="incremental" if previous is not None else "initial",
                  characters=len(rows), capacity=len(legal), spare=len(legal)-len(rows),
                  changed=len(changes), changes=changes, control_sha256=digest(audit),
                  previous_mapping_sha256=previous.get("mapping_sha256") if previous else None,
                  added_controls=sorted(set(audit["controls"]) - set(previous["controls"])) if previous else audit["controls"],
                  removed_controls=sorted(set(previous["controls"]) - set(audit["controls"])) if previous else [],
                  runtime_integrated=False)
    return table, report


def validate_controls(audit):
    if audit.get("schema") != 1 or audit.get("status") != "reviewed" or not isinstance(audit.get("version"), int):
        raise ValueError("a versioned reviewed control list is required")
    for name in ("controls", "leads", "tails"):
        values = audit[name]
        if not isinstance(values, list) or any(type(v) is not int or not 0 <= v <= 255 for v in values):
            raise ValueError("invalid byte list: " + name)
        if values != sorted(set(values)):
            raise ValueError("byte lists must be sorted and unique: " + name)
    if not audit["leads"] or not audit["tails"]:
        raise ValueError("empty encoding space")
    if set(audit["controls"]) & (set(audit["leads"]) | set(audit["tails"])):
        raise ValueError("control byte overlaps character encoding")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--controls", type=Path, default=Path(__file__).with_name("control_codes.json"))
    parser.add_argument("--previous", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        audit = json.loads(args.controls.read_text())
        validate_controls(audit)
        previous = json.loads(args.previous.read_text()) if args.previous else None
        table, report = generate(audit, previous)
        args.output.mkdir(parents=True, exist_ok=True)
        for name, data in (("controls.json", audit), ("encoding.json", table), ("changes.json", report)):
            (args.output / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps({k: v for k, v in report.items() if k != "changes"}, ensure_ascii=False))
    except (ValueError, KeyError, TypeError, OSError) as exc:
        parser.exit(1, f"codec: {exc}\n")


if __name__ == "__main__":
    main()
