/* Generate smaller display copies without changing the original artwork or captures.
 * Requires sharp: node tools/build-display-images.js
 */
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const cards = [
  'store/sbox.png', 'store/gta5-logo-transparent.png', 'store/rdr2-logo-transparent.png',
  'store/last-of-us.webp', 'bodycam/logo.webp', 'source-games/source-games-logo-v1.png',
  'games/spoofer.webp', 'l4d/background.webp',
];
const previews = [
  'previews/gmod/gmod-menu-gameplay.png', 'previews/gmod/gmod-visuals-gameplay.png',
  'previews/l4d/l4d1-survivor-esp-20260922.webp',
];
async function build() {
  let originalBytes = 0, displayBytes = 0;
  for (const [files, widths, suffix, quality] of [[cards, [640], 'card', 82], [previews, [640, 960], 'preview', 85]]) {
    for (const file of files) {
      const source = path.join(root, 'assets/images', file);
      originalBytes += fs.statSync(source).size;
      for (const width of widths) {
        const target = source.replace(/\.[^.]+$/, `-${suffix}${suffix === 'preview' ? '-' + width : ''}.webp`);
        const info = await sharp(source).resize({ width, withoutEnlargement: true }).webp({ quality, effort: 6 }).toFile(target);
        if (width === widths.at(-1)) displayBytes += info.size;
        console.log(`${path.relative(root, target)}: ${info.width}x${info.height}, ${info.size} bytes`);
      }
    }
  }
  console.log(`Originals: ${originalBytes} bytes; largest display copies: ${displayBytes} bytes.`);
}
build().catch(error => { console.error(error); process.exitCode = 1; });
