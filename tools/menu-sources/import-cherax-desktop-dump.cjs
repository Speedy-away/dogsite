'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'project/community-menu-sources');
const desktop = 'C:/Users/whatw/Desktop/cherax-dumps';
const exportsRoot = path.join(source, 'cherax-exports');
const target = path.join(exportsRoot, 'desktop-dump');
const registryPath = path.join(source, 'cherax-export-channels.json');
const isWithin = (base, filename) => {
  const relative = path.relative(base, filename);
  return relative && !path.isAbsolute(relative) && relative !== '..' && !relative.startsWith('..' + path.sep);
};
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const snowflake = id => new Date(Number((BigInt(id) >> 22n) + 1420070400000n)).toISOString();

function decode(value) {
  const named = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' };
  return String(value || '').replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (full, name) => {
    if (!name.startsWith('#')) return named[name.toLowerCase()] ?? full;
    const number = name.startsWith('#x') ? parseInt(name.slice(2), 16) : Number(name.slice(1));
    return number >= 0 && number <= 0x10ffff ? String.fromCodePoint(number) : full;
  });
}

function attr(tag, key) {
  const match = tag.match(new RegExp('\\s' + key + '=(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))', 'i'));
  return decode(match && (match[1] ?? match[2] ?? match[3]));
}

function text(html) {
  return decode(html.replace(/<br\s*\/?>|<\/(?:div|p|li)>/gi, '\n').replace(/<[^>]*>/g, '')).trim();
}

function asset(htmlName, reference, label, memberDirectory, outputDirectory, copy) {
  if (!reference || /^(?:https?:|data:|#|\/)/i.test(reference)) return null;
  let decoded;
  try { decoded = decodeURIComponent(reference); } catch { return null; }
  const filename = path.resolve(desktop, decoded);
  if (!isWithin(memberDirectory, filename) || !fs.existsSync(filename)) return null;
  const file = fs.lstatSync(filename);
  if (!file.isFile() || file.isSymbolicLink() || !file.size ||
      !isWithin(fs.realpathSync(memberDirectory), fs.realpathSync(filename))) return null;
  const expected = path.basename(filename).replace(/-[0-9a-f]{16}(?=\.[^.]+$)/i, '');
  const original = label || expected;
  const safeName = digest(Buffer.from(htmlName + '\0' + decoded)).slice(0, 24) + path.extname(expected).toLowerCase();
  const destination = path.join(outputDirectory, safeName);
  if (copy) {
    fs.mkdirSync(outputDirectory, { recursive: true });
    if (!isWithin(fs.realpathSync(exportsRoot), fs.realpathSync(outputDirectory))) throw new Error('Desktop media output escaped the export directory');
    if (!fs.existsSync(destination)) fs.copyFileSync(filename, destination, fs.constants.COPYFILE_EXCL);
    const staged = fs.lstatSync(destination);
    if (!staged.isFile() || staged.isSymbolicLink() || staged.size !== file.size) throw new Error('Desktop media changed: ' + original);
  }
  return { fileName: original, url: path.basename(outputDirectory) + '/' + safeName, fileSizeBytes: file.size, sourceKind: 'desktop-html-attachment' };
}

function importHtml(filename, registry, channel, copy) {
  const absolute = path.join(desktop, filename);
  const before = fs.statSync(absolute);
  if (!before.size || before.size > 128 * 1024 * 1024) return { channel: channel.name, status: 'empty-or-too-large' };
  let bytes;
  try { bytes = fs.readFileSync(absolute); } catch (error) {
    if (error.code === 'EBUSY') return { channel: channel.name, status: 'still-being-written' };
    throw error;
  }
  const html = bytes.toString('utf8');
  const footer = html.match(/class=(?:"postamble__entry"|postamble__entry)>Exported\s+(\d+)\s+message\(s\)<\/div>/i);
  if (!footer || fs.statSync(absolute).mtimeMs !== before.mtimeMs) return { channel: channel.name, status: 'incomplete' };
  const messages = [...html.matchAll(/<div\b[^>]*\bdata-message-id=["']?(\d{15,22})["']?[^>]*>/gi)];
  if (messages.length !== Number(footer[1]) || new Set(messages.map(match => match[1])).size !== messages.length) {
    return { channel: channel.name, status: 'inconsistent-message-count' };
  }
  const label = filename.slice(filename.lastIndexOf(' - ') + 3).replace(/ \[\d+\]\.html$/i, '');
  if (!label.endsWith(channel.name) || !filename.startsWith(registry.guild.name + ' - ')) {
    return { channel: channel.name, status: 'label-mismatch' };
  }
  const liveFile = fs.readdirSync(exportsRoot).find(name => name.endsWith(' [' + channel.id + '].json'));
  if (liveFile) {
    try {
      const live = JSON.parse(fs.readFileSync(path.join(exportsRoot, liveFile), 'utf8'));
      const ids = new Set(live.messages.map(message => message.id));
      const linked = live.messages.reduce((sum, message) => sum + message.attachments.filter(item => !/^https?:/i.test(item.url)).length, 0);
      const htmlAttachments = [...html.matchAll(/class=(?:"chatlog__attachment"|chatlog__attachment)(?=\s|>)/g)].length;
      if (live.channel.id === channel.id && live.guild.id === registry.guild.id &&
          live.messageCount === live.messages.length && messages.every(match => ids.has(match[1])) &&
          linked >= htmlAttachments) {
        return { channel: channel.name, status: 'already-covered-by-json', messages: messages.length };
      }
    } catch (error) {
      if (error.code && error.code !== 'EBUSY') throw error;
    }
  }
  const memberDirectory = path.join(desktop, filename + '_Files');
  if (!fs.existsSync(memberDirectory) || fs.lstatSync(memberDirectory).isSymbolicLink()) {
    return { channel: channel.name, status: 'media-directory-missing' };
  }
  const outputDirectory = path.join(target, channel.id + '-media');
  const rows = [];
  let author = { name: 'Unknown uploader' };
  for (const [i, match] of messages.entries()) {
    const body = html.slice(match.index + match[0].length, messages[i + 1]?.index ?? html.lastIndexOf('class=postamble'));
    const title = body.match(/<span\b[^>]*\bclass=(?:"chatlog__author"|chatlog__author)[^>]*>/i)?.[0];
    if (title) author = { id: attr(title, 'data-user-id'), name: attr(title, 'title') || 'Unknown uploader' };
    const media = new Map();
    function add(reference, original) {
      const row = asset(filename, reference, original, memberDirectory, outputDirectory, copy);
      if (row) media.set(row.url, row);
    }
    for (const match of body.matchAll(/<div\b[^>]*class=(?:"chatlog__attachment-generic-name"|chatlog__attachment-generic-name)[^>]*>\s*(<a\b[^>]*>)([\s\S]*?)<\/a>/gi)) {
      add(attr(match[1], 'href'), text(match[2]));
    }
    for (const match of body.matchAll(/<(?:img|video|audio)\b[^>]*>/gi)) {
      const classes = attr(match[0], 'class').split(/\s+/);
      if (!classes.some(name => /^chatlog__(?:attachment-media|embed-image)$/.test(name))) continue;
      const name = attr(match[0], 'title').match(/^(?:Image|Video|Audio):\s+(.+?)\s*\([^()]*\)$/i)?.[1];
      add(attr(match[0], 'src'), name);
    }
    for (const match of body.matchAll(/(<(video|audio)\b[^>]*>)([\s\S]*?)<\/\2>/gi)) {
      if (!attr(match[1], 'class').split(/\s+/).includes('chatlog__attachment-media')) continue;
      for (const source of match[3].matchAll(/<source\b[^>]*>/gi)) add(attr(source[0], 'src'));
    }
    const markdown = body.match(/<div\b[^>]*class="chatlog__content(?:[^"]*)"[^>]*>([\s\S]*?)(?=<div[^>]*class=(?:"chatlog__attachment|chatlog__attachment|"?chatlog__embed)|$)/i);
    rows.push({ id: match[1], timestamp: snowflake(match[1]), author, content: text(markdown?.[1] || ''), attachments: [...media.values()], embeds: [] });
  }
  const attachments = rows.reduce((sum, message) => sum + message.attachments.length, 0);
  if (copy && attachments) {
    if (channel.exportName !== label) {
      channel.cliExportName ||= channel.exportName;
      channel.exportName = label;
      channel.evidence += ' Display label matched the completed user-provided HTML export and exact channel ID.';
    }
    const envelope = {
      guild: registry.guild, channel: { id: channel.id, type: 'GuildTextChat', name: label, category: 'Cherax' },
      dateRange: { after: null, before: null }, exportedAt: before.mtime.toISOString(), messages: rows, messageCount: rows.length,
      desktopDump: { name: filename, sha256: digest(bytes), sourceFormat: 'DiscordChatExporter HTML', declaredMessages: Number(footer[1]) },
    };
    const destination = path.join(target, channel.id + '.json');
    fs.mkdirSync(target, { recursive: true });
    if (!isWithin(fs.realpathSync(exportsRoot), fs.realpathSync(target))) throw new Error('Desktop metadata output escaped the export directory');
    fs.writeFileSync(destination, JSON.stringify(envelope, null, 2) + '\n');
  }
  return { channel: channel.name, status: attachments ? (copy ? 'imported' : 'ready') : 'no-local-attachments', messages: rows.length, attachments };
}

const args = process.argv.slice(2);
if (args.length > 1 || (args.length && !['--plan', '--import'].includes(args[0]))) throw new Error('Use --plan or --import');
const copy = args[0] === '--import';
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
const channels = new Map(registry.channels.filter(row => row.collection === 'archival').map(row => [row.id, row]));
const result = [];
for (const file of fs.readdirSync(desktop, { withFileTypes: true })) {
  if (!file.isFile() || file.isSymbolicLink()) continue;
  const channel = channels.get(file.name.match(/\[(\d{15,22})\]\.html$/i)?.[1]);
  if (channel) result.push(importHtml(file.name, registry, channel, copy));
}
if (copy && result.some(row => row.status === 'imported')) fs.writeFileSync(registryPath, JSON.stringify(registry, null, 2) + '\n');
console.log(JSON.stringify({ mode: copy ? 'import' : 'plan', desktop, channels: result }));
