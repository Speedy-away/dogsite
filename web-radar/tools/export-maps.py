"""Extract the exact existing CS2 overview PNGs; never invent map geometry."""
import argparse
import hashlib
import json
from pathlib import Path
import re

def export(source, destination):
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for cpp in sorted(source.glob('*.cpp')):
        raw = cpp.read_text(encoding='utf-8-sig')
        match = re.search(r'kMapImage_\w+_data\[\d+\]\s*=\s*\{(.*?)\};', raw, re.S)
        if not match or cpp.stem == 'default':
            continue
        png = bytes(int(v, 16) for v in re.findall(r'0x([0-9a-fA-F]{2})', match[1]))
        if not png.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError(f'Not a PNG: {cpp}')
        (destination / f'{cpp.stem}.png').write_bytes(png)
        manifest[cpp.stem] = {'bytes':len(png), 'sha256':hashlib.sha256(png).hexdigest(),
                              'source':f'src/GUI/overlay/map_images/{cpp.name}'}
    if not manifest:
        raise ValueError('No embedded map images found')
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print(f'Exported {len(manifest)} exact CS2 map images')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--destination', type=Path, default=Path(__file__).resolve().parents[1]/'maps')
    args=parser.parse_args()
    export(args.source,args.destination)
