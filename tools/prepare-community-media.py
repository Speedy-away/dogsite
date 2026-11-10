from pathlib import Path
import json,hashlib,shutil,concurrent.futures
from PIL import Image,ImageOps
root=Path(__file__).resolve().parents[1]; source=root.parent/'INF_DATA'; out=root/'community/media';out.mkdir(exist_ok=True)
def convert(job):
 kind,i,detail=job; result={};p=source/detail[0]
 if p.exists():
  name=kind+'-'+str(i)+p.suffix;dest=out/name
  if not dest.exists():shutil.copyfile(p,dest)
  result['file']='./media/'+name
 for image in detail[1]:
  p=source/image
  if not p.exists():continue
  name=kind+'-'+str(i)+'.webp';dest=out/name
  try:
   if not dest.exists():
    with Image.open(p) as im:
     im=ImageOps.exif_transpose(im);im.thumbnail((480,360));im.convert('RGB').save(dest,'WEBP',quality=65)
   result['preview']='./media/'+name;break
  except Exception:continue
 return str(i),result
for kind in ['vehicles','outfits']:
 index=json.loads((root/'community/data'/kind/'index.json').read_text());jobs=[]
 for f in sorted((root/'community/data'/kind/'chunks').glob('*.json')):
  for offset,d in enumerate(json.loads(f.read_text())):jobs.append((kind,int(f.stem)*index['chunkSize']+offset,d))
 with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: manifest=dict(pool.map(convert,jobs))
 (root/'community/data'/kind/'local-assets.json').write_text(json.dumps(manifest,separators=(',',':')))
 print(kind,len(manifest),'presets prepared',flush=True)
