#!/usr/bin/env python3
"""Package emulator pixels and compiled glyph assets into an offline editor."""
import argparse,base64,hashlib,json,re,subprocess,tempfile
from pathlib import Path

def ppm(path):
    data=path.read_bytes(); tokens=[]; i=0
    while len(tokens)<4:
        while data[i:i+1].isspace():i+=1
        if data[i:i+1]==b'#':
            i=data.index(b'\n',i)+1;continue
        j=i
        while not data[i:i+1].isspace():i+=1
        tokens.append(data[j:i])
    if data[i:i+2]==b'\r\n':i+=2
    else:i+=1
    if tokens!=[b'P6',b'160',b'144',b'255'] or len(data[i:])!=160*144*3:
        raise ValueError('Expected runner P6 RGB 160x144 screenshot')
    return base64.b64encode(data[i:]).decode()

def package(source,shot):
    manifest=json.loads((source/'data/zh/font/manifest.json').read_text())
    raw=(source/'gfx/zh/prototype.1bpp').read_bytes();glyphs={}
    for entry in manifest['glyphs']:
        g=raw[entry['id']*18:entry['id']*18+18]
        if len(g)!=18:raise ValueError('Manifest/font mismatch')
        glyphs[entry['char']]={'w':12,'h':12,'pixels':[1 if g[(x//4)*6+y//2] & (1 << (7-(y%2)*4-x%4)) else 0 for y in range(12) for x in range(12)]}
    latin=(source/'gfx/font/normal.1bpp').read_bytes()
    for line in (source/'constants/charmap.asm').read_text().splitlines():
        m=re.match(r'\s*charmap\s+"(.+)",\s*\$([0-9a-fA-F]+)',line)
        if not m or len(m[1])!=1:continue
        n=int(m[2],16)-128
        if 0<=n<114:
            tile=latin[n*8:n*8+8]
            glyphs[m[1]]={'w':8,'h':8,'pixels':[(tile[y]>>(7-x))&1 for y in range(8) for x in range(8)]}
    glyphs[' ']={'w':8,'h':8,'pixels':[0]*64}
    files=[shot,source/'data/zh/font/manifest.json',source/'gfx/zh/prototype.1bpp',source/'gfx/font/normal.1bpp']
    return {'schema':1,'rgb':ppm(shot),'glyphs':glyphs,'provenance':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,required=True);p.add_argument('--shot',type=Path);p.add_argument('--rom',type=Path);p.add_argument('--save',type=Path);p.add_argument('--runner',type=Path);p.add_argument('--replay',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    a.out.mkdir(parents=True,exist_ok=False)
    if a.rom:
        if not a.runner or not a.replay:p.error('--rom requires --runner and --replay')
        commands=a.replay.read_text().splitlines()
        if any(not re.fullmatch(r'run [0-9]+ [0-9]+',s) for s in commands):raise ValueError('Replay permits only run frames buttons; no writes or saves')
        shot=a.out.resolve()/'capture.ppm'
        if any(c.isspace() for c in str(shot)):raise ValueError('Runner capture path cannot contain whitespace')
        cmd=[str(a.runner),str(a.rom)]+([str(a.save)] if a.save else [])
        before=hashlib.sha256(a.save.read_bytes()).hexdigest() if a.save else None
        with tempfile.TemporaryDirectory() as temp:
            if a.save:
                copy=Path(temp)/'input.sav';copy.write_bytes(a.save.read_bytes());cmd[-1]=str(copy)
            result=subprocess.run(cmd,input='\n'.join(commands+[f'shot {shot}','quit'])+'\n',text=True,capture_output=True,check=True,timeout=120)
        (a.out/'runner.log').write_text(result.stdout+result.stderr)
        if a.save and hashlib.sha256(a.save.read_bytes()).hexdigest()!=before:raise ValueError('Original save changed')
    elif a.shot:shot=a.shot
    else:p.error('Supply --shot or --rom')
    data=package(a.source,shot)
    for path in [a.rom,a.replay,a.runner,a.save]:
        if path:data['provenance'][str(path)]=hashlib.sha256(path.read_bytes()).hexdigest()
    from pink_scene import extract
    data['background'],data['elements']=extract(data['rgb'])
    import sys
    sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'zh'))
    from summary_layout_config import editor_constraints,load,DEFAULT
    _,bound=load(DEFAULT)
    images={e['name']:e for e in data['elements']}
    data['elements']=[dict(images.get(e['name'],{}),**e) for e in bound.values()]
    data['constraints']=editor_constraints()
    data['layout_sha256']=hashlib.sha256(DEFAULT.read_bytes()).hexdigest()
    template=Path(__file__).with_name('editor.html').read_text()
    template=template.replace('/*TILE_GEOMETRY*/',Path(__file__).with_name('tile_geometry.js').read_text())
    template=template.replace('/*ROM_EXPORT*/',Path(__file__).with_name('rom_export.js').read_text())
    template=template.replace('/*CONSTRAINTS*/',Path(__file__).with_name('constraints.js').read_text())
    payload=json.dumps(data,ensure_ascii=False).replace('<','\u003c')
    (a.out/'index.html').write_text(template.replace('/*PACKAGED_DATA*/null',payload))
    (a.out/'provenance.json').write_text(json.dumps(data['provenance'],indent=2))
    print(a.out.resolve()/'index.html')
if __name__=='__main__':main()
