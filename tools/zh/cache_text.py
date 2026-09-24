"""Text measurement and legacy source spelling helpers; no drawing bytecode."""
def measure_text(text, glyphs, *, width_tiles, charmap=None, leading_strips=0, **unused):
    width=leading_strips*4
    for char in text:
        if char==' ' or charmap and char in charmap and 128<=charmap[char]<242:
            width+=8
        elif char in glyphs:
            width+=12
        else:
            raise ValueError('Unmanifested glyph: '+repr(char))
    tiles=(width+7)//8
    if tiles>width_tiles:raise ValueError('Text exceeds compile-time region')
    return tiles

def load_charmap(source):
    import re
    result = {}
    for line in (source / "constants/charmap.asm").read_text().splitlines():
        fields = line.split(chr(34))
        if len(fields) >= 3 and "charmap " in fields[0] and len(fields[1]) == 1:
            match = re.search(r"\$([0-9a-fA-F]+)", fields[2])
            if match:
                result[fields[1]] = int(match[1], 16)
    return result

def expand_static_ngrams(source, text):
    """Expand source-defined fixed abbreviations before measuring fallback."""
    import re
    definitions = (source / "data/text/ngrams.asm").read_text()
    fixed = {}
    for line in definitions.splitlines():
        if "rawchar" not in line:
            continue
        label = line.split(":", 1)[0].strip()
        quoted = line.split(chr(34))
        if len(quoted) >= 3:
            fixed[label] = quoted[1].removesuffix("@")
    labels = re.findall(r"^\s*dr (\.\w+)", definitions, re.M)
    charmap_text = (source / "constants/charmap.asm").read_text()
    for line in reversed(charmap_text.splitlines()):
        fields = line.split(chr(34))
        if len(fields) < 3 or "charmap " not in fields[0]:
            continue
        match = re.search(r"\$([0-9a-fA-F]+)", fields[2])
        if match:
            index = int(match[1], 16) - 0x4d
            if 0 <= index < len(labels) and labels[index] in fixed:
                text = text.replace(fields[1], fixed[labels[index]])
    return text

def encode_legacy_name(source, text):
    """Encode source rawchar names by longest match, not Python length."""
    import re
    definitions={}
    for line in (source/'constants/charmap.asm').read_text().splitlines():
        fields=line.split(chr(34))
        if len(fields)<3 or 'charmap ' not in fields[0]:continue
        match=re.search(r'[$]([0-9a-fA-F]+)',fields[2])
        if match:definitions[fields[1]]=int(match[1],16)
    tokens=sorted(definitions,key=lambda t:(-len(t),t))
    out=bytearray()
    while text:
        token=next((t for t in tokens if text.startswith(t)),None)
        if token is None:raise ValueError('Unsupported raw name')
        out.append(definitions[token]);text=text[len(token):]
    if len(out)!=10:raise ValueError('Default name must encode to ten bytes')
    return bytes(out)
