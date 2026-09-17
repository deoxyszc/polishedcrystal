#!/usr/bin/env python3
"""Reproducibility and fail-before-output tests; explicit local font fixture."""
import argparse,hashlib,json,pathlib,subprocess,sys,tempfile

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--font',required=True);ap.add_argument('--manifest',required=True);ap.add_argument('--license-dir',required=True);a=ap.parse_args()
 importer=pathlib.Path(__file__).with_name('import_ttf.py')
 args=[sys.executable,str(importer),'--font',a.font,'--manifest',a.manifest,'--license-dir',a.license_dir]
 with tempfile.TemporaryDirectory() as tmp:
  root=pathlib.Path(tmp)
  for name in ['one','two']:subprocess.run(args+['--baseline','10','--output-root',str(root/name)],check=True,capture_output=True)
  def hashes(path):return {str(p.relative_to(path)):hashlib.sha256(p.read_bytes()).hexdigest() for p in path.rglob('*') if p.is_file()}
  assert hashes(root/'one')==hashes(root/'two')
  for name,flags in [('baseline',['--baseline','11']),('size',['--baseline','10','--pixel-size','13']),('hash',['--baseline','10','--expected-sha256','bad'])]:
   output=root/name;r=subprocess.run(args+flags+['--output-root',str(output)],capture_output=True);assert r.returncode and not output.exists()
  missing=root/'missing.json';missing.write_text(json.dumps({'glyphs':[{'id':0,'char':'\U0010ffff'}]}))
  r=subprocess.run(args+['--manifest',str(missing),'--baseline','10','--output-root',str(root/'missing')],capture_output=True);assert r.returncode and not(root/'missing').exists()
 print('PASS deterministic files and font hash/size/extent/coverage rejection')
if __name__=='__main__':main()
