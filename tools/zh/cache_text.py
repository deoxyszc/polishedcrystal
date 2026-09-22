"""Compile fixed text into DFS strip pairs for the shared PlaceString entry."""
PAIR_COMMAND = 0x0e
EMPTY_STRIP = 0xffff

def encode_pairs(text, glyphs, *, width_tiles, charmap=None, strip_map, leading_strips=0):
    """Resolve glyph IDs, pairing, padding and bounds before ROM assembly.

    This entry accepts manifested 12px glyphs and the original 8px font. Controls and dynamic names are
    compiled by their owning text compiler, never guessed from the string.
    """
    if not 1 <= width_tiles <= 20:
        raise ValueError("Invalid text region width")
    strips = [EMPTY_STRIP] * leading_strips
    for char in text:
        if char == " ":
            strips.extend((EMPTY_STRIP, EMPTY_STRIP))
            continue
        if charmap and char in charmap and 0x80 <= charmap[char] < 0xf2:
            code = (charmap[char] - 0x80) * 2
            strips.extend(strip_map["latin"][code:code + 2])
            continue
        if char not in glyphs:
            raise ValueError(f"Unmanifested glyph: {char!r}")
        glyph = glyphs[char]
        if not 0 <= glyph < 16384:
            raise ValueError("Glyph ID outside font")
        strips.extend(strip_map["glyphs"][glyph])
    tiles = (len(strips) + 1) // 2
    if tiles > width_tiles:
        raise ValueError("Text exceeds compile-time region")
    if len(strips) % 2:
        strips.append(EMPTY_STRIP)
    result = bytearray()
    for left, right in zip(strips[::2], strips[1::2]):
        result.extend((PAIR_COMMAND, left >> 8, left & 255, right >> 8, right & 255))
    return bytes(result), tiles

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

def compile_segments(segments, glyphs, charmap, *, layout, strip_map):
    import encode
    lines = []
    width = 0
    for segment in segments:
        if "text" in segment:
            data, tiles = encode_pairs(segment["text"], glyphs, width_tiles=layout.width, charmap=charmap, strip_map=strip_map)
            width += tiles
            lines.append(" db " + ",".join("$%02x" % value for value in data + bytes((0x53,))))
        elif "control" in segment:
            lines.append(" db $%02x" % encode.CONTROLS[segment["control"]])
            if segment["control"] in ("LINE", "NEXT", "PARA", "CONT"):
                width = 0
        elif "name" in segment:
            width += 10
            lines.append(" db ZH_CTRL_PLAYER" if segment["name"] == "player" else " db ZH_CTRL_RIVAL")
        elif "ram_name" in segment:
            width += 10
            symbol = segment["ram_name"]
            lines += [" db ZH_CTRL_RAM, BANK(" + symbol + ")", " dw " + symbol]
        else:
            raise ValueError("Unsupported compiled segment")
        if width > layout.width:
            raise ValueError("Compiled fragments exceed the dialogue region")
    return chr(10).join(lines) + chr(10)
