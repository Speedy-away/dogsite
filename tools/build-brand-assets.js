/* Trace the supplied, unchanged PNG into a sharp vector mask for small UI sizes. */
const fs = require('fs'), path = require('path');
const zlib = require('zlib');
const root = path.resolve(__dirname, '..');

function readRgbPng(png) {
  const width = png.readUInt32BE(16), height = png.readUInt32BE(20);
  if (width !== 1254 || height !== 1254 || png[24] !== 8 || png[25] !== 2 || png[28] !== 0) {
    throw new Error('The Scooby source format changed; review the RGB trace and viewBox before rebuilding.');
  }
  const chunks = [];
  for (let offset = 8; offset < png.length;) {
    const size = png.readUInt32BE(offset), type = png.toString('ascii', offset + 4, offset + 8);
    if (type === 'IDAT') chunks.push(png.subarray(offset + 8, offset + 8 + size));
    offset += size + 12;
  }
  const raw = zlib.inflateSync(Buffer.concat(chunks)), stride = width * 3;
  const pixels = Buffer.alloc(stride * height);
  const paeth = (a, b, c) => {
    const p = a + b - c, da = Math.abs(p - a), db = Math.abs(p - b), dc = Math.abs(p - c);
    return da <= db && da <= dc ? a : db <= dc ? b : c;
  };
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    if (filter > 4) throw new Error('Unsupported PNG row filter.');
    for (let x = 0; x < stride; x++) {
      const i = y * stride + x, left = x >= 3 ? pixels[i - 3] : 0;
      const up = y ? pixels[i - stride] : 0, upperLeft = y && x >= 3 ? pixels[i - stride - 3] : 0;
      const predictor = [0, left, up, Math.floor((left + up) / 2), paeth(left, up, upperLeft)][filter];
      pixels[i] = (raw[y * (stride + 1) + x + 1] + predictor) & 255;
    }
  }
  return { width, height, pixels };
}

function simplify(points, tolerance = .8) {
  if (points.length < 3) return points;
  const [a, b] = [points[0], points[points.length - 1]];
  const dx = b[0] - a[0], dy = b[1] - a[1], length = dx * dx + dy * dy;
  let farthest = 0, split = 0;
  for (let i = 1; i < points.length - 1; i++) {
    const p = points[i], t = length ? Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / length)) : 0;
    const distance = (p[0] - a[0] - t * dx) ** 2 + (p[1] - a[1] - t * dy) ** 2;
    if (distance > farthest) { farthest = distance; split = i; }
  }
  if (farthest <= tolerance * tolerance) return [a, b];
  return [...simplify(points.slice(0, split + 1), tolerance).slice(0, -1), ...simplify(points.slice(split), tolerance)];
}

function traceMask({ width, height, pixels }) {
  const mask = new Uint8Array(width * height);
  for (let i = 0; i < mask.length; i++) {
    const p = i * 3;
    mask[i] = (.2126 * pixels[p] + .7152 * pixels[p + 1] + .0722 * pixels[p + 2]) >= 160 ? 1 : 0;
  }
  const edges = [], starts = new Map(), pitch = width + 1;
  const add = (x, y, dx, dy, direction) => {
    const from = y * pitch + x, to = (y + dy) * pitch + x + dx;
    const edge = { from, to, direction, used: false };
    edges.push(edge);
    if (!starts.has(from)) starts.set(from, []);
    starts.get(from).push(edge);
  };
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const i = y * width + x;
    if (!mask[i]) continue;
    if (!y || !mask[i - width]) add(x, y, 1, 0, 0);
    if (x === width - 1 || !mask[i + 1]) add(x + 1, y, 0, 1, 1);
    if (y === height - 1 || !mask[i + width]) add(x + 1, y + 1, -1, 0, 2);
    if (!x || !mask[i - 1]) add(x, y + 1, 0, -1, 3);
  }
  const paths = [];
  for (const first of edges) {
    if (first.used) continue;
    const points = []; let edge = first;
    do {
      edge.used = true;
      points.push([edge.from % pitch, Math.floor(edge.from / pitch)]);
      if (edge.to === first.from) break;
      const next = (starts.get(edge.to) || []).filter(candidate => !candidate.used);
      // Keep diagonal contacts as distinct contours by preferring a right turn.
      const priority = [1, 0, 3, 2];
      next.sort((a, b) => priority.indexOf((a.direction - edge.direction + 4) % 4) - priority.indexOf((b.direction - edge.direction + 4) % 4));
      edge = next[0];
      if (!edge) throw new Error('The Scooby trace contains an open contour.');
    } while (true);
    const area = points.reduce((sum, p, i) => { const q = points[(i + 1) % points.length]; return sum + p[0] * q[1] - q[0] * p[1]; }, 0);
    if (Math.abs(area) < 24) continue;
    // Split closed contours before simplification so enclosed openings are retained.
    let opposite = 1;
    for (let i = 2; i < points.length; i++) {
      if ((points[i][0] - points[0][0]) ** 2 + (points[i][1] - points[0][1]) ** 2 > (points[opposite][0] - points[0][0]) ** 2 + (points[opposite][1] - points[0][1]) ** 2) opposite = i;
    }
    const contour = [...simplify(points.slice(0, opposite + 1)).slice(0, -1), ...simplify([...points.slice(opposite), points[0]]).slice(0, -1)];
    paths.push('M' + contour.map(point => point.join(' ')).join('L') + 'Z');
  }
  return paths.join('');
}

function buildBrandMask() {
  const png = fs.readFileSync(path.join(root, 'assets/images/brand/scooby-logo.png'));
  const outline = traceMask(readRgbPng(png));
  // A small vector stroke keeps the original thin outline readable at 29–43px.
  const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="200 100 740 980"><path fill="white" fill-rule="evenodd" stroke="white" stroke-width="4" stroke-linejoin="round" d="' + outline + '"/></svg>\n';
  fs.writeFileSync(path.join(root, 'assets/images/brand/scooby-mark.svg'), svg);
}
if (require.main === module) { buildBrandMask(); console.log('Built the Scooby vector UI mask from the original PNG.'); }
module.exports = { buildBrandMask };
