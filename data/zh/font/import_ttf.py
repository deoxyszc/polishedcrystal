#!/usr/bin/env python3
"""Deterministic, explicit-baseline TTF/OTF -> stable 12px game glyph pages."""
import argparse,hashlib,json,pathlib,platform,shutil,tempfile
import PIL
from PIL import Image,ImageDraw,ImageFont,features
import fontTools
from fontTools.ttLib import TTFont

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--font',required=True,type=pathlib.Path);ap.add_argument('--manifest',required=True,type=pathlib.Path);ap.add_argument('--output-root',required=True,type=pathlib.Path)
 ap.add_argument('--pixel-size',type=int,default=12);ap.add_argument('--baseline',type=int,required=True);ap.add_argument('--origin-x',type=int,default=0);ap.add_argument('--license-dir',required=True,type=pathlib.Path);ap.add_argument('--expected-sha256');a=ap.parse_args()
 if a.pixel_size!=12:raise ValueError('current 12x12 ABI requires pixel_size12; no automatic scaling')
 if a.expected_sha256 and sha(a.font)!=a.expected_sha256:raise ValueError('font hash mismatch')
 manifest=json.loads(a.manifest.read_text());glyphs=manifest['glyphs']
 if not 0<len(glyphs)<=16384 or [g['id'] for g in glyphs]!=list(range(len(glyphs))):raise ValueError('stable contiguous glyph IDs required')
 if len(set(g['char'] for g in glyphs))!=len(glyphs) or any(len(g['char'])!=1 for g in glyphs):raise ValueError('unique single-codepoint glyphs required')
 font=ImageFont.truetype(str(a.font),a.pixel_size,layout_engine=ImageFont.Layout.BASIC);tt=TTFont(a.font);cmap=tt.getBestCmap()
 missing=[g['char'] for g in glyphs if ord(g['char']) not in cmap]
 if missing:raise ValueError('missing glyphs: '+''.join(missing))
 license_files=[a.license_dir/'OFL.txt']+sorted((a.license_dir/'LICENSES').rglob('*'))
 license_files=[p for p in license_files if p.is_file()]
 if not (a.license_dir/'OFL.txt').is_file():raise ValueError('OFL.txt required; no silent license omission')
 rasters=[];coverage=[];blob=bytearray()
 for g in glyphs:
  ch=g['char'];advance=font.getlength(ch)
  # Render on padded canvas, then detect true nonzero bounds before cropping.
  im=Image.new('L',(60,60));draw=ImageDraw.Draw(im);draw.fontmode='1';draw.text((24+a.origin_x,24+a.baseline),ch,font=font,fill=255,anchor='ls',stroke_width=0)
  bbox=im.getbbox();rel=None if bbox is None else [bbox[0]-24,bbox[1]-24,bbox[2]-24,bbox[3]-24]
  if advance!=12 or bbox is None:raise ValueError(f'non-12px advance or blank glyph {ch!r}: {advance}')
  if rel[0]<0 or rel[1]<0 or rel[2]>12 or rel[3]>12:raise ValueError(f'glyph exceeds12x12 at configured origin/baseline: {ch!r} {rel}')
  cell=im.crop((24,24,36,36));levels=set(cell.getdata())
  if not levels<={0,255}:raise ValueError('antialiased output forbidden; expected exact mono pixels')
  rasters.append(cell)
  for ty,tx in [(0,0),(0,1),(1,0),(1,1)]:
   for y in range(8):
    b=0
    for x in range(8):
     xx=tx*8+x;yy=ty*8+y
     if xx<12 and yy<12 and cell.getpixel((xx,yy)):b|=128>>x
    blob.append(b)
  coverage.append({'id':g['id'],'char':ch,'font_glyph':cmap[ord(ch)],'advance_px':advance,'ink_bbox':rel})
 # Validate everything before creating output or replacing any resources.
 a.output_root.mkdir(parents=True,exist_ok=True)
 with tempfile.TemporaryDirectory(dir=a.output_root,prefix='.font-import-') as scratch:
  stage=pathlib.Path(scratch);(stage/'gfx/zh').mkdir(parents=True);(stage/'data/zh/font').mkdir(parents=True);meta=stage/'font-report';meta.mkdir()
  table=['ZhFontPages::'];sections=[]
  for page in range((len(glyphs)+511)//512):
   label=f'ZhFontPage{page:02d}';name=f'page_{page:02d}.1bpp';(stage/'gfx/zh'/name).write_bytes(blob[page*16384:(page+1)*16384]);table += [f' db BANK({label})',f' dw {label}'];sections += [f'SECTION "Chinese Font Page {page}", ROMX[$4000], BANK[{130+page}]',label+'::',f' INCBIN "gfx/zh/{name}"']
  (stage/'gfx/zh/prototype.1bpp').write_bytes(blob)
  for name,lines in [('font.asm',table),('font_pages.asm',sections)]: (stage/'data/zh/font'/name).write_text('\n'.join(lines)+'\n')
  outmanifest={'schema_version':1,'format':'four row-major 8x8 1bpp tiles;12x12','glyphs':[{'id':g['id'],'char':g['char']} for g in glyphs],'font_sha256':sha(a.font)}
  (stage/'data/zh/font/manifest.json').write_text(json.dumps(outmanifest,ensure_ascii=False,indent=2)+'\n')
  preview=Image.new('RGB',(16*40,((len(glyphs)+15)//16)*48),'white');d=ImageDraw.Draw(preview)
  for g,cell in zip(glyphs,rasters):
   x=g['id']%16*40;y=g['id']//16*48;ink=Image.eval(cell,lambda v:255-v).convert('RGB').resize((36,36),Image.Resampling.NEAREST);preview.paste(ink,(x,y));d.text((x,y+36),str(g['id']),fill='black')
  preview.save(meta/'preview.png',optimize=False)
  deps=[{'path':str(p.resolve()),'sha256':sha(p)} for p in [a.font,a.manifest,pathlib.Path(__file__),*license_files]]
  report={'font':str(a.font.resolve()),'font_sha256':sha(a.font),'pixel_size':12,'baseline':a.baseline,'origin_x':a.origin_x,'render_mode':'mono','metrics':{'ascent':font.getmetrics()[0],'descent':font.getmetrics()[1],'units_per_em':tt['head'].unitsPerEm},'glyph_count':len(glyphs),'missing':[],'coverage':coverage,'dependencies':deps,'tools':{'python':platform.python_version(),'pillow':PIL.__version__,'fonttools':fontTools.__version__,'freetype':features.version_module('freetype2')},'pixels_sha256':hashlib.sha256(blob).hexdigest()}
  (meta/'coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
  for p in license_files:
   dest=meta/'licenses'/p.relative_to(a.license_dir);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest)
  for p in sorted(stage.rglob('*')):
   if p.is_file():dest=a.output_root/p.relative_to(stage);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest)
 print(json.dumps({'glyph_count':len(glyphs),'pixels_sha256':hashlib.sha256(blob).hexdigest(),'output_root':str(a.output_root)},sort_keys=True))
if __name__=='__main__':main()
