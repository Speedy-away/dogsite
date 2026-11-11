'use strict';
// Correct only Windows CLI display encoding using completed selected export
// metadata. Does not change channel IDs, guilds, categories or collection labels.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const SOURCE = path.join(ROOT, 'project/community-menu-sources');
const EXPORTS = path.join(SOURCE, 'cherax-exports');
const REGISTRY = path.join(SOURCE, 'cherax-export-channels.json');
const write = process.argv.slice(2).includes('--repair');
const data = JSON.parse(fs.readFileSync(REGISTRY, 'utf8'));
const byId = new Map(data.channels.map(entry => [entry.id, entry]));
const found = new Map(), skipped = [];
if (write && fs.existsSync(EXPORTS)) for (const name of fs.readdirSync(EXPORTS).sort().filter(name => name.endsWith('.json'))) {
  const file = path.join(EXPORTS, name), stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || !stat.size || stat.size > 512 * 1024 * 1024 || Date.now() - stat.mtimeMs < 30000) continue;
  const fd = fs.openSync(file, 'r'), buffer = Buffer.alloc(4096);
  let prefix;
  try { prefix = buffer.subarray(0, fs.readSync(fd, buffer, 0, buffer.length, 0)).toString('utf8').replace(/^\uFEFF/, ''); } finally { fs.closeSync(fd); }
  const end = prefix.indexOf('"messages"');
  let metadata;
  try { metadata = JSON.parse(prefix.slice(0, end > 0 ? end : prefix.length).replace(/,\s*$/, '') + '}'); } catch { continue; }
  if (metadata.guild?.id !== data.guild.id) continue;
  const thread = ['GuildPublicThread', 'GuildPrivateThread', 'GuildNewsThread'].includes(metadata.channel?.type);
  const id = thread ? metadata.channel.categoryId : metadata.channel?.id, entry = byId.get(id);
  if (!entry || (entry.guildId && entry.guildId !== metadata.guild.id)) continue;
  const actual = thread ? metadata.channel.category : metadata.channel.name;
  const escaped = entry.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  if (typeof actual !== 'string' || !new RegExp(`(?:^|[^a-z0-9-])${escaped}$`, 'i').test(actual)) { skipped.push({ file: name, id, reason: 'Approved ID has an unexpected canonical ASCII channel suffix.' }); continue; }
  let document, bytes;
  try { bytes = fs.readFileSync(file); document = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, '')); } catch { continue; }
  const after = fs.statSync(file);
  if (after.size !== stat.size || after.mtimeMs !== stat.mtimeMs || !Array.isArray(document.messages) || document.messageCount !== document.messages.length || !document.dateRange || !document.exportedAt) continue;
  if (found.has(id) && found.get(id).actual !== actual) throw Error(`Conflicting selected export display names for ${id}.`);
  if (!found.has(id)) found.set(id, { actual, file: path.relative(ROOT, file).split(path.sep).join('/'), sha256: crypto.createHash('sha256').update(bytes).digest('hex'), exportedAt: document.exportedAt });
}
const repaired = [];
for (const [id, proof] of found) {
  const entry = byId.get(id);
  if (entry.exportName === proof.actual) continue;
  entry.cliExportName ??= entry.exportName;
  entry.exportName = proof.actual;
  entry.exportDisplayNameEvidence = proof;
  entry.evidence += ' Exact export display name corrected from the completed selected JSON envelope; original Windows CLI display encoding retained in cliExportName.';
  repaired.push({ id, name: entry.name, exportName: proof.actual, evidenceFile: proof.file, sha256: proof.sha256 });
}
if (write && repaired.length) { data.reviewedAt = new Date().toISOString(); fs.writeFileSync(REGISTRY, JSON.stringify(data, null, 2) + '\n'); }
console.log(JSON.stringify({ mode: write ? 'repair-selected-export-labels' : 'inventory-only', channels: data.channels.length, repaired, skipped, messageContentRead: write, outputWritten: Boolean(write && repaired.length) }, null, 2));
