import hashlib,json
from pathlib import Path
NAMES={'图鉴编号':'dex','训练家ID':'ot_id','经验条':'exp_bar','宝可梦立绘':'portrait','等级':'level','性别':'gender','属性':'types','精灵球':'ball','昵称':'nickname','物种名':'species','训练家':'ot','页签':'tab','经验':'exp','所需经验':'needed','下一级':'next_level'}
FIXED={'dex':(64,16),'portrait':(0,16),'level':(0,72),'gender':(40,72),'exp_bar':(8,132)}
TEMPLATES={'nickname':'{nickname}','species':'/{species}','ot':'初训家/{ot}','exp':'经验{exp}','needed':'还需{needed}经验','next_level':'升到{next_level}级','tab':'经验'}
DEFAULT=Path(__file__).with_name('layout_configs')/'summary_pink.json'
FIXED.update(ot_id=(72,80),types=(64,56),nickname=(64,24),species=(64,40),ot=(64,64))
def editor_constraints():
 return {'roles':list(NAMES.values()),'names':NAMES,'templates':TEMPLATES,
         'fixed':{k:list(v) for k,v in FIXED.items()},'step':8,
         'offsets':{k:([3,4] if k=='tab' else [0,4]) for k in TEMPLATES},
         'ball_origin':[136,24],'screen':[160,144]}

def load(path=DEFAULT):
 d=json.loads(Path(path).read_text());found={}
 if d.get('schema') not in (1,2):raise ValueError('Unsupported layout schema')
 for e in d.get('items',[]):
  role=e.get('binding') or NAMES.get(e.get('name'))
  if role not in NAMES.values() or role in found:raise ValueError('Unknown/duplicate element: '+str(role))
  if type(e.get('x')) is not int or type(e.get('y')) is not int:raise ValueError('Integer pixels required')
  x,y=e['x'],e['y']
  if not 0<=x<160 or not 0<=y<144:raise ValueError('Outside screen: '+role)
  if role in FIXED and (x,y)!=FIXED[role]:raise ValueError('Native movement unsupported: '+role)
  if role not in FIXED and role!='ball' and (x%8 or y%8):raise ValueError('8px anchor required: '+role)
  if role in ['nickname','species','ot','ot_id','types'] and (x<64 or y<16 or y>=88):raise ValueError('Outside window: '+role)
  if role in TEMPLATES:
   if e.get('template',TEMPLATES[role])!=TEMPLATES[role]:raise ValueError('Unsupported dynamic template: '+role)
   if (e.get('cjk'),e.get('latin'))!=((3,4) if role=='tab' else (0,4)):raise ValueError('Unsupported text offsets: '+role)
  found[role]=dict(e,binding=role)
 if set(found)!=set(NAMES.values()):raise ValueError('Missing required elements')
 return d,found
def emit(path,source):
 d,e=load(path);lines=['; Generated from layout JSON; do not edit.']
 for role,item in e.items():
  prefix='ZH_PINK_'+role.upper();x,y=item['x'],item['y']
  vals={'X':x,'Y':y,'TX':x//8,'TY':y//8}
  if role in ['nickname','species','ot','ot_id','types']:vals.update(WX=(x-64)//8,WY=(y-16)//8)
  if role in TEMPLATES:vals.update(CJK_Y=item['cjk'],LATIN_Y=item['latin'])
  for key,value in vals.items():lines.append('DEF '+prefix+'_'+key+' EQU '+str(value))
 if (e['ball']['x']-136)%8 or (e['ball']['y']-24)%8:raise ValueError('Ball requires 8px moves from (136,24)')
 bx=e['ball']['x'];by=e['ball']['y']
 for key,value in {'WX':8+(bx-132)//8,'WY':1+(by-20)//8,'OAM_X':bx+8,'OAM_Y':by+8}.items():lines.append('DEF ZH_PINK_BALL_'+key+' EQU '+str(value))
 (source/'constants/zh_summary_layout.asm').write_text(chr(10).join(lines)+chr(10))
 report={'input_sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'elements':{k:{f:v for f,v in x.items() if f!='rgba'} for k,x in e.items()},'dynamic_values':'game RAM, not sample text'}
 (source/'data/zh/summary_layout_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));return report

if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser(description='Compile an editor ROM layout into ASM constants')
 p.add_argument('--layout',type=Path,required=True);p.add_argument('--source',type=Path,required=True);a=p.parse_args()
 print(json.dumps(emit(a.layout,a.source),ensure_ascii=False,indent=2))
