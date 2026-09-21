"""Compile party footer text for the shared Chinese output path."""
import csv
from cache_text import encode_pairs, load_charmap, expand_static_ngrams
from encode import load_glyphs
from suite_layout import region

IDS = {
    "cancel": "engine/pokemon/party_menu.asm::PlacePartyNicknames.Cancel::1",
    "prompt": "engine/pokemon/party_menu.asm::ChooseAMonString::1",
}

def generate(source, language, font_path):
    with (source / "translations.csv").open(encoding="utf-8-sig", newline="") as f:
        rows = {r["id"]: r for r in csv.DictReader(f)}
    glyphs = load_glyphs(source / "data/zh/font/manifest.json")
    charmap = load_charmap(source)
    lines = []
    for key in IDS:
        config = region(language, "party." + key)
        text = rows[IDS[key]].get("translation_" + language, "").strip().rstrip("@")
        text = text or rows[IDS[key]]["original"].strip().rstrip("@")
        text = expand_static_ngrams(source, text)
        data, _ = encode_pairs(text, glyphs, width_tiles=config.width // 8, charmap=charmap)
        lines += ["ZhParty" + key.title() + "Text:",
                  " db " + ",".join(map(str, data + bytes((0x53,))))]
    (source / "data/zh/party_footer.asm").write_text(chr(10).join(lines) + chr(10))
