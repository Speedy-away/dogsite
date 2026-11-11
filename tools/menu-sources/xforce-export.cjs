'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { readHtmlExport } = require('./redm-export-html.cjs');

const categories = {
  'ui-configs': 'themes',
  'custom-header': 'themes',
  'asi-scripts': 'asi-mods',
  outfits: 'outfits',
  translations: 'languages',
  'custom-dlc-addons': 'dlc',
  'xml-vehicles': 'vehicles',
  'xml-maps': 'maps',
  'misc-files': 'misc',
  'lua-scripts': 'lua',
};
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const image = /\.(png|jpg|jpeg|gif|webp)$/i;
const zip = /\.(zip|rar|7z)$/i;
// These exact archive bytes passed 7-Zip's integrity test. The recorded
// format comes from their member lists, rather than the channel label alone.
const verifiedArchives = new Map([
  ["e44657c65b961306c2c3c0c25e3c0c466012c6a0ac70bcdcbc6e9fde477ea9d1","Handling Editor configuration and handling presets"],
  ["8ac18ceb5e8149070b8d9edf3055e76069becedeb0f0ffc3d72295adfc439253","Vehicle handling presets in META format"],
  ["4087721f06a442994ec9507a87634272b3c624a7f472305ec6bb3aa21e0996c4","X-Force archive with ten XFO outfit presets"],
  ["4b114f76796c2a8e16182bc0e5d8cea9d33f59174fc9109b0cf448e98369f7a9","X-Force archive with five JSON outfit presets"],
  ["a83c22881b333b36e22f8994762dd83aa929eafbfc4fe418938e0d4e02c801f1","X-Force archive with a JSON outfit preset"],
  ["0068ade43a7a716ab30e803e6868ff70641c3f9d32f852689061b4691d92dc98","X-Force archive with eighteen XTR translations"],
  ["d428a8a4848f6323130326fb2077ec0c885b5bb4698801effe04f905a6c79d93","Simplified Chinese XTR with its bundled font"],
  ["fcf252061f0fcb58a60766201458cfcd81df3455f4cb0b8a5d499e7ff5acf3e4","Chinese XTR for X-Force 7.4b1 with its bundled font"],
  ['bd05ca616838e1f1084929991f091d1775f8dd1e27560b7f684e258f590549cf', 'BikeLife ASI with its INI options'],
  ['84dd9008045a1ed9b8271f00584b6c44b9d9ee44d63f020ca4841817c282f7c7', 'Menyoo ASI with supporting files'],
  ['fe1aaafdf6a529f37f1a8edf8454b9fedcbca3ea933cc072eabe4b9f1307c066', 'Menyoo ASI with supporting files'],
  ['17b289f5e1f67c5452494251d67444db3b38f8d803a423bb5da397f2f2517164', 'Rampage ASI with supporting files'],
  ['45d84a49f4eb15518d8f15f2e4d2c2de02a092f47e3332bbcd81b3b38953f5cc', 'Vehicle DLC archive with dlc.rpf'],
  ['0ddc9e529a237db53bfd84cbb24ac5fe46a868a8e66016bfcd7f5cdf51caaf44', 'Vehicle DLC archive with dlc.rpf'],
  ['4a0062ffa400c5971fc25e6038c94d83092516d02cfd5e0912ee52b9e1e45418', 'Menyoo map archive containing 56 XML files'],
  ['8210579c7fb2d6558023741699f82ca09bcddd620b772d157c8af24c6d051cc6', 'Vehicle archive containing 198 XML files'],
  ['2cc424510679bff47e421f82ca8931637d4d869e66213b143fc5474d0a98a653', 'Vehicle archive containing XML and INI presets'],
  ['b3fd77785d6194a7c3b60d27241610252b0dbc36f70f0f4530a73734a4d8596c', 'Vehicle archive containing XML and INI presets'],
]);
const reviewReasons = new Map([
  [
    "HandlingEditorXForce.rar",
    "Contains an ASI and a bundled runtime log. The source attachment requires review or a clean author package."
  ],
  [
    "Chinese_Simplified.zip",
    "The outer ZIP passed its integrity check, but includes a nested ZIP whose contents could not be verified."
  ],
  [
    "Chineseee.xtr",
    "Translation dictionary contains an invalid control character within a quoted value."
  ],
  [
    "Chinese1.xtr",
    "Translation dictionary contains an invalid control character within a quoted value."
  ],
  [
    "XML_Vehicles.zip",
    "The archive lists 2,218 XML members, but the archive integrity test did not complete."
  ]
]);
const uiReleaseNotes = new Map([
  ['955096860459155486', { changes: ['Shared a smaller layout variant.'] }],
  ['955107296751517716', { changes: ['Shared a smaller layout variant.'] }],
  ['976419431766982696', { version: '0.1', changes: ['Shared the initial Aspect theme.'] }],
  ['1224125877097595002', { version: '2.0', changes: [] }],
  ['1265392844865147014', { changes: ['Revised the theme to more closely match the old X-Force 7.0 interface.'] }],
]);
const textureShareIds = new Set(['1115387585154531388', '1225168676295147651', '1268128290518859889']);
const nameFrom = value => value.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' ').trim();
const isImage = file => {
  const bytes = file.bytes;
  return bytes.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex')) ||
    bytes.subarray(0, 3).equals(Buffer.from('ffd8ff', 'hex')) ||
    /^GIF8[79]a/.test(bytes.toString('ascii', 0, 6)) ||
    (bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP');
};

function plainJSON(bytes) {
  try {
    return JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
  } catch {
    return null;
  }
}

function outfitJSON(bytes) {
  const outfit = plainJSON(bytes)?.outfit;
  if (!outfit || typeof outfit !== 'object' || Array.isArray(outfit)) return false;
  const slots = Object.values(outfit);
  return slots.length > 0 && slots.every(slot => Number.isInteger(slot?.DrawId) && Number.isInteger(slot?.TexId));
}

function translationJSON(bytes) {
  // Some original .xtr files use comments or trailing commas. Check their
  // structure with a normalized copy and retain the original bytes.
  const normalized = bytes.toString('utf8')
    .replace(/("(?:[^"\\]|\\.)*")|\/\/[^\r\n]*|\/\*[\s\S]*?\*\//g, (_, string) => string || '')
    .replace(/("(?:[^"\\]|\\.)*")|,\s*(?=[}\]])/g, (_, string) => string || '');
  const dictionary = plainJSON(Buffer.from(normalized));
  return dictionary && typeof dictionary === 'object' && !Array.isArray(dictionary) &&
    Object.keys(dictionary).length > 0 && Object.values(dictionary).every(value => typeof value === 'string');
}

function classify(channel, file) {
  const { name, bytes } = file;
  if (channel === 'ui-configs') {
    if (!/\.(ui|xf_cnfg)$/i.test(name) || bytes.length > 131072) return '';
    const config = plainJSON(bytes);
    return config && Object.keys(config).length === 1 && config.ui_settings &&
      typeof config.ui_settings === 'object' && !Array.isArray(config.ui_settings) ? 'X-Force JSON UI settings' : '';
  }
  if (channel === 'custom-header') return image.test(name) && isImage(file) ? 'Header artwork' : '';
  if (channel === 'lua-scripts') return /\.(lua|pluto)$/i.test(name) ? 'X-Force Lua source' : '';
  if (channel === 'asi-scripts') return /\.asi$/i.test(name) || zip.test(name) ? 'ASI plugin package' : '';
  if (channel === 'custom-dlc-addons') return /\.rpf$/i.test(name) || zip.test(name) ? 'GTA V DLC package' : '';
  if (channel === 'outfits' || channel === 'translations') {
    if (channel === 'translations' && /\.xtr$/i.test(name)) return translationJSON(bytes) ? 'X-Force XTR translation' : 'Unverified XTR translation';
    if (/\.json$/i.test(name) && (channel === 'outfits' ? outfitJSON(bytes) : plainJSON(bytes))) return channel === 'outfits' ? 'X-Force outfit JSON' : 'Translation JSON';
    if (channel === 'translations' && /\.(ini|txt|lang)$/i.test(name) && bytes.length && !bytes.includes(0)) return 'Translation text';
  }
  if (['xml-vehicles', 'xml-maps', 'outfits'].includes(channel) && /\.xml$/i.test(name)) {
    const data = bytes.toString('utf8').trim().replace(/^<\?xml[^>]*\?>\s*/, '');
    if (/<!DOCTYPE|<!ENTITY/i.test(data)) return 'Unverified XML attachment';
    if (channel === 'xml-vehicles' && /^<Vehicle\b[^>]*>[\s\S]*<\/Vehicle>\s*$/i.test(data) &&
        /<ModelHash>\s*(?:0x[0-9a-f]+|\d+)\s*<\/ModelHash>/i.test(data)) return 'Menyoo vehicle XML';
    if (channel === 'xml-maps' && /^<SpoonerPlacements\b[^>]*>[\s\S]*<\/SpoonerPlacements>\s*$/i.test(data)) return 'Menyoo placement XML';
    return 'Unverified XML attachment';
  }
  if (channel === 'xml-vehicles' && /\.ini$/i.test(name) &&
      /^\s*\[VEHICLE\]/i.test(bytes.toString('utf8')) && /^hash=-?\d+\s*$/im.test(bytes.toString('utf8'))) return 'X-Force vehicle INI';
  if (channel === 'misc-files' && /\.(json|ini|txt|wav|ogg|mp3|ttf|otf|cfg|dat|zip|rar|7z)$/i.test(name)) return 'Miscellaneous attachment';
  if (['outfits', 'translations', 'xml-vehicles', 'xml-maps'].includes(channel) && zip.test(name)) return 'Archive attachment';
  return '';
}

function inspect(directory, knownHashes = []) {
  const items = [], coverage = [], pending = [], duplicates = [], plans = new Map();
  const seen = new Set(knownHashes);
  const audit = { exports: [], skipped: [], missingAttachments: [], pending, duplicates };
  const root = fs.realpathSync(directory);
  function stage(file, family) {
    const relative = `xforce/export-assets/${family}/${file.sha256.slice(0, 24)}${path.extname(file.name).toLowerCase()}`;
    plans.set(relative, file.bytes);
    return `project/community-menu-sources/${relative}`;
  }
  const files = fs.readdirSync(root, { withFileTypes: true }).filter(file => file.isFile() && /\.html$/i.test(file.name));
  for (const exportFile of files) {
    const filename = exportFile.name;
    const header = filename.match(/^X-Force - (.+?) - (.+?) \[(\d{15,22})\](?:.*?)\.html$/i);
    if (!header || !categories[header[2]]) {
      audit.skipped.push({ filename, reason: 'Outside requested media categories' });
      continue;
    }
    let raw;
    try {
      raw = fs.readFileSync(path.join(root, filename));
    } catch (error) {
      if (!['EBUSY', 'EPERM'].includes(error.code)) throw error;
      audit.skipped.push({ filename, reason: 'Export still being written or locked' });
      continue;
    }
    const html = raw.toString('utf8');
    const exportedCount = html.match(/class=postamble__entry>Exported ([\d,]+) message\(s\)<\/div>/i)?.[1];
    if (exportedCount === undefined) {
      audit.skipped.push({ filename, reason: 'HTML export is incomplete' });
      continue;
    }
    const channel = header[2];
    const category = categories[channel];
    const count = Number(exportedCount.replaceAll(',', ''));
    const normalized = html.replace(/(<title>\s*)X-Force - /i, '$1RedM Hub - ')
      .replaceAll('class="chatlog__message-container chatlog__message-container--pinned"', 'class=chatlog__message-container');
    const data = count ? readHtmlExport(normalized, filename.replace(/^X-Force - /i, 'RedM Hub - '), null) : { channel: { id: header[3] }, messages: [] };
    if (data.messages.length !== count) throw Error(`Message count mismatch in ${filename}`);
    const guildId = [...html.matchAll(/https:\/\/discord\.com\/channels\/(\d{15,22})\/(\d{15,22})\//gi)]
      .find(link => link[2] === data.channel.id)?.[1];
    const summary = { filename, channel, channelId: data.channel.id, sha256: hash(raw), inspectedDiscordMessages: data.messages.length, resourceCount: 0, attachmentCount: 0, firstPost: data.messages[0]?.timestamp || null, lastPost: data.messages.at(-1)?.timestamp || null };
    for (const message of data.messages) {
      const attachments = [];
      for (const attachment of message.attachments) {
        summary.attachmentCount++;
        const name = path.win32.basename(attachment.fileName);
        const relative = attachment.url.replaceAll('\\', '/');
        if (!name || /^(?:https?:|\/)/i.test(relative) || relative.split('/').includes('..')) {
          audit.missingAttachments.push({ channel, messageId: message.id, name, reason: 'Attachment not saved locally' });
          continue;
        }
        const local = path.resolve(root, relative);
        if (!local.startsWith(root + path.sep) || !fs.existsSync(local) || !fs.realpathSync(local).startsWith(root + path.sep)) {
          audit.missingAttachments.push({ channel, messageId: message.id, name, reason: 'Attachment missing from export' });
          continue;
        }
        const stat = fs.statSync(local);
        if (!stat.isFile() || !stat.size || stat.size > 64 * 1024 * 1024) {
          audit.missingAttachments.push({ channel, messageId: message.id, name, size: stat.size, reason: 'Empty or oversized attachment' });
          continue;
        }
        const bytes = fs.readFileSync(local);
        attachments.push({ name, bytes, sha256: hash(bytes) });
      }
      const payloads = attachments.filter(file => classify(channel, file));
      const images = attachments.filter(file => image.test(file.name) && isImage(file));
      const textureShare = channel === 'misc-files' && textureShareIds.has(message.id);
      for (const file of textureShare ? images : payloads) {
        if (seen.has(file.sha256)) {
          duplicates.push({ channel, messageId: message.id, name: file.name, sha256: file.sha256 });
          continue;
        }
        seen.add(file.sha256);
        const archiveFormat = verifiedArchives.get(file.sha256);
        const sourceFormat = textureShare ? 'Replacement texture artwork' : archiveFormat || classify(channel, file);
        const localData = textureShare || archiveFormat || ['ui-configs', 'custom-header'].includes(channel) ||
          ['X-Force outfit JSON', 'X-Force XTR translation', 'Menyoo vehicle XML', 'Menyoo placement XML', 'X-Force vehicle INI'].includes(sourceFormat);
        const author = message.author?.name;
        const provenance = { type: 'user-supplied-discord-export', guild: 'X-Force', channel, channelId: data.channel.id, messageId: message.id, postedAt: message.timestamp, exportSha256: summary.sha256, attachment: file.name, attachmentSha256: file.sha256,
          ...(archiveFormat ? { archiveIntegrity: '7-Zip test passed for these SHA-256-pinned bytes' } : {}) };
        if (!localData && category !== 'lua') {
          pending.push({ ...provenance, sourceFormat, bytes: file.bytes.length, reason: reviewReasons.get(file.name) || 'Payload requires format and dependency review before catalog inclusion' });
          continue;
        }
        const config = channel === 'ui-configs' ? plainJSON(file.bytes) : null;
        const customHeader = config?.ui_settings?.header?.custom_name;
        const companion = typeof customHeader === 'string' && customHeader !== 'null' ? images.find(candidate => candidate.name.toLowerCase() === path.win32.basename(customHeader).toLowerCase()) : null;
        const preview = channel === 'custom-header' || textureShare ? file : category !== 'lua' && payloads.length === 1 && images.length === 1 ? images[0] : null;
        const files = localData ? [file, ...(companion && companion !== file ? [companion] : [])].map(asset => ({ localPath: stage(asset, 'downloads'), name: asset.name, size: asset.bytes.length, sha256: asset.sha256 })) : [];
        const archival = message.timestamp < '2025-01-01';
        const name = nameFrom(file.name);
        const recordCategory = ['HandlingEditor.rar', 'HandlingFiles.rar'].includes(file.name) ? 'misc' : category;
        const release = channel === 'ui-configs' ? uiReleaseNotes.get(message.id) : null;
        const entry = {
          id: `gta5-xforce-discord-${file.sha256.slice(0, 20)}`, game: 'gta5', category: recordCategory, name,
          sourceMenu: 'X-Force', supportedMenus: ['X-Force'], sourceChannel: channel,
          sourceFilename: file.name, sourceFormat, sourceProvenance: provenance, author,
          ...(guildId && category !== 'lua' ? { sourceUrl: `https://discord.com/channels/${guildId}/${data.channel.id}/${message.id}` } : {}),
          description: `${sourceFormat} shared in X-Force’s #${channel} channel on ${message.timestamp.slice(0, 10)}.`,
          compatibility: 'Shared for the original X-Force menu. Current game builds and other menus were not tested.',
          ...(category === 'themes' ? { uiStyle: 'ListUI', style: 'X-Force' } : {}),
          ...(preview ? { preview: stage(preview, 'previews'), previewVerified: true, previewKind: channel === 'custom-header' ? 'artwork' : 'author attachment', previewCaption: 'Image attached to the source post.' } : {}),
          ...(customHeader && customHeader !== 'null' ? { requirements: [companion ? `Keep the attached ${companion.name} header with the config.` : `The config references ${path.win32.basename(customHeader)}. That file was not matched to an attachment in the same post.`] } : {}),
          version: release?.version || null,
          ...(release?.version ? { versionBasis: 'Author’s export post' } : {}),
          changelog: release?.changes.length ? [{ ...release, date: message.timestamp.slice(0, 10), dateBasis: 'Discord post date' }] : [],
          archival, currentCollection: !archival,
          collectionStatus: archival ? 'archival' : 'current',
          tags: ['gta5', 'x-force', channel, name],
          downloadStatus: localData ? 'available' : 'pending', status: localData ? 'download' : 'pending', files,
          guide: `/resources/guides/?game=gta5&menu=xforce&category=${recordCategory}`,
        };
        items.push(entry);
        summary.resourceCount++;
      }
    }
    coverage.push(summary);
    audit.exports.push(summary);
  }
  return { items, coverage, audit, plans };
}

module.exports = { inspect };
