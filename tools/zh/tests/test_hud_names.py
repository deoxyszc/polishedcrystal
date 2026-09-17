"""Generated HUD tables contain only explicit translations, never placeholders."""
import csv, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hud_names
from unittest.mock import patch
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp);(root/'data/zh').mkdir(parents=True)
    with (root/'translations.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['source_path','translation_zh-Hans']);w.writeheader();w.writerow({'source_path':'data/pokemon/names.asm','translation_zh-Hans':''})
    with patch.object(hud_names.ImageFont,'truetype',return_value=None):
        hud_names.generate(root,'zh-Hans','unused')
    assert (root/'data/zh/battle_names.asm').read_text() == 'ZhBattleNameTable:'+chr(10)+' dw 0'+chr(10)
print('PASS empty translation table has no display overrides')
