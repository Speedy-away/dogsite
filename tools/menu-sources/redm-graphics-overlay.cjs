'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

function overlayMember(member) {
  const source = member.path.replace(/\\/g, '/');
  if (member.directory || member.encrypted || member.link || !member.size ||
      source.split('/').some(part => !part || /[. ]$/.test(part) || /[<>:"|?*\x00-\x1f]/.test(part) ||
        /^(?:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i.test(part))) return null;
  const citizen = source.match(/(?:^|\/)(citizen\/(?:common\/data|platform\/(?:data\/effects|textures|models|levels|audio\/config))\/.+)$/i)?.[1];
  if (citizen && /\.(?:xml|dat|ymt|ytd|ydd|rpf|rel)$/i.test(citizen) &&
      !/(?:bypass|fast[-_ ]?scope|faster[-_ ]?scope)/i.test(citizen)) return citizen;
  const font = source.match(/(?:^|\/)(citizen\/[^/]+\.(?:ttf|otf))$/i)?.[1];
  if (font) return font;
  const name = path.posix.basename(source);
  if (/visualsettings.*dx12\.dat$|^visualsettings_dx12\.dat$/i.test(name)) return name;
  if (/preset\.ini$/i.test(name) && !/bypass/i.test(name)) return name;
  if (/^(?:readme|install|instructions?|credits?|licen[cs]e)(?:[-_ ].*)?\.(?:txt|md)$/i.test(name)) return source;
  return null;
}

function sevenZip(binary, args, options) {
  return execFileSync(binary, args, {
    windowsHide: true, timeout: 120000, maxBuffer: 16 * 1024 * 1024, ...options,
  });
}

function buildOverlay({ input, output, members, binary }) {
  const selected = new Map();
  for (const member of members) {
    const relative = overlayMember(member);
    if (!relative) continue;
    const key = relative.toLowerCase();
    if (selected.has(key)) {
      if (selected.get(key).member.size === member.size && selected.get(key).member.crc &&
          selected.get(key).member.crc === member.crc) continue;
      throw Error(`Duplicate graphics overlay path: ${relative}`);
    }
    selected.set(key, { relative, member });
  }
  const entries = [...selected.values()];
  if (!entries.some(row => /^citizen\//i.test(row.relative))) throw Error('No Citizen graphics data was found in the source archive.');
  if (entries.reduce((sum, row) => sum + row.member.size, 0) > 512 * 1024 * 1024) throw Error('Graphics overlay exceeds the extraction size limit.');
  if (fs.existsSync(output)) return entries;
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'scooby-redm-overlay-'));
  const extracted = path.join(temp, 'source'), packageRoot = path.join(temp, 'package');
  const list = path.join(temp, 'members.txt'), packed = path.join(temp, 'overlay.zip');
  try {
    fs.writeFileSync(list, entries.map(row => row.member.path).join('\n') + '\n', 'utf8');
    sevenZip(binary, ['x', '-y', '-spd', '-scsUTF-8', `-o${extracted}`, `-i@${list}`, '--', input]);
    for (const { relative, member } of entries) {
      const sourceFile = path.join(extracted, member.path);
      const stats = fs.lstatSync(sourceFile);
      if (!stats.isFile() || stats.size !== member.size ||
          !fs.realpathSync(sourceFile).startsWith(fs.realpathSync(extracted) + path.sep)) {
        throw Error(`Extracted data differs from the archive listing: ${member.path}`);
      }
      const destination = path.join(packageRoot, relative);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      fs.copyFileSync(sourceFile, destination);
    }
    sevenZip(binary, ['a', '-tzip', '-mx=3', '-mtc=off', '-mta=off', packed, '.'], { cwd: packageRoot });
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.copyFileSync(packed, output, fs.constants.COPYFILE_EXCL);
  } finally {
    if (path.dirname(temp) === path.resolve(os.tmpdir()) && path.basename(temp).startsWith('scooby-redm-overlay-')) {
      fs.rmSync(temp, { recursive: true, force: true });
    }
  }
  return entries;
}

module.exports = { buildOverlay };
