"""Orange assets preserve separators and require complete translations."""
import csv
import json
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch
from PIL import ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import orange_assets


with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    for parent in [
        "data/zh",
        "data/maps",
        "data",
        "engine/pokemon/summary",
        "engine/rtc",
        "gfx/font",
        "gfx/zh",
    ]:
        (root / parent).mkdir(parents=True, exist_ok=True)
    (root / "data/natures.asm").write_text(
        "NatureNames:\n dr .Brave\n assert_table_length 1\n"
    )
    (root / "data/characteristics.asm").write_text(
        "Characteristics:\n dw .Relaxed\n assert_table_length 1\n"
    )
    (root / "data/maps/landmarks.asm").write_text(
        "landmark 0, 0, NewTownName\n"
    )
    (root / "gfx/font/normal.1bpp").write_bytes(bytes(114 * 8))
    fields = ["id", "translation_zh-Hans"]
    values = {
        "engine/pokemon/summary/orange_page.asm::SummaryScreen_OrangePage.NatureString::1": "Nat@",
        "engine/pokemon/summary/orange_page.asm::SummaryScreen_OrangePage.CharacterString::1": "Char@",
        "data/natures.asm::NatureNames.Brave::1": "Bold@",
        # Character intentionally absent: its generated table entry must be zero.
        "engine/rtc/timeset.asm::MORN_String::1": "AM@",
        "data/maps/landmarks.asm::NewTownName::1": "Town@",
    }
    with (root / "translations.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fields)
        writer.writeheader()
        for key, value in values.items():
            writer.writerow({"id": key, "translation_zh-Hans": value})
    terms = root / "terms.json"
    terms.write_text(json.dumps({
        "met_location": "at {location}",
        "met_level_prefix": "lv",
        "level_suffix": "L",
    }))
    with patch.object(orange_assets.ImageFont, "truetype", return_value=ImageFont.load_default()):
        orange_assets.generate(root, "zh-Hans", "unused", terms)
    output = (root / "data/zh/orange.asm").read_text()
    assert "ZhOrangeNature0" in output
    assert "ZhOrangeCharacterTable::\n dw 0" in output
    assert "ZhOrangeLocation0" in output
    assert "ZhOrangeLevelPrefixTiles" in output
    assert "ZhOrangeLevelSuffixTiles" in output
    assert "ZhOrangeDigits0" in output

print("PASS orange separators, complete-entry admission, and encounter assets")
