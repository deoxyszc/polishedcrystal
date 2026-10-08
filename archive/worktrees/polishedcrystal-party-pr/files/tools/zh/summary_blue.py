"""Independent character labels; numeric window rows remain native tiles."""
import json
from pathlib import Path
from stable_runtime import menu_text
from cache_text import load_charmap
CHARACTERS='攻击防御特攻特防速度特性'
DEFAULT=Path(__file__).with_name('layout_configs')/'summary_blue.json'
def generate(source,manifest):
 config=json.loads((source/'tools/zh/layout_configs/summary_blue.json').read_text())
 expected=[('Attack','攻击',64,32),('Defense','防御',112,32),('SpAtk','特攻',64,52),('SpDef','特防',112,52),('Speed','速度',64,72)]
 if [(e['key'],e['text'],e['x'],e['y']) for e in config['stats']]!=expected:raise ValueError('Unsupported blue layout')
 glyphs={e['char']:e['id'] for e in json.loads(manifest.read_text())['glyphs']}
 cm=load_charmap(source);lines=[]
 for i,e in enumerate(config['stats']):
  data=menu_text(e['text'],glyphs,cm,source,style=0 if i//2==1 else 2,width_tiles=3)+bytes([83])
  lines += ['ZhBlue'+e['key']+':',' db '+','.join(map(str,data))]
 maps=json.loads((source/'data/zh/font/compiled.json').read_text())
 lines += ['ZhBlueTabKeys:',' dw '+','.join(map(str,maps['summary_blue_tab']['keys']))]
 constants=['; Generated blue background anchors; numeric rows remain native window tiles.']
 for e in config['stats']:
  constants += ['DEF ZH_BLUE_'+e['key'].upper()+'_TX EQU '+str(e['x']//8),'DEF ZH_BLUE_'+e['key'].upper()+'_TY EQU '+str(e['y']//8)]
 (source/'constants/zh_summary_blue.asm').write_text(chr(10).join(constants)+chr(10))
 (source/'data/zh/summary_blue.asm').write_text(chr(10).join(lines)+chr(10))
