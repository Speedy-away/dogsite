'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

const root = path.resolve(__dirname, '../..');
const sources = path.join(root, 'project/community-menu-sources');
const target = path.resolve(root, '../cool-repo');
const catalogPath = 'catalog/cherax-acquired-assets.json';
const output = path.join(sources, 'cherax-publication.json');
const read = name => JSON.parse(fs.readFileSync(path.join(sources, name), 'utf8'));
const assetPath = /^(?:downloads|previews)\/gta5\/menus\/cherax\/[a-f0-9]{20}\.[a-z0-9]+$/;

function git(...args) {
  return execFileSync('git', ['-c', 'safe.directory=' + target.split(path.sep).join('/'), ...args], {
    cwd: target, encoding: 'utf8', maxBuffer: 96 * 1024 * 1024, windowsHide: true,
  }).trimEnd();
}

function references(catalog) {
  if (catalog.schema !== 'cherax-acquired-assets.v1' || !Array.isArray(catalog.assets)) throw new Error('Invalid acquisition catalog');
  const byPath = new Map();
  const byId = new Map();
  const byKey = new Map();
  for (const row of catalog.assets) {
    if (!assetPath.test(row.path) || !/^[a-f0-9]{64}$/.test(row.actual?.sha256) ||
        !row.path.endsWith('/' + row.actual.sha256.slice(0, 20) + row.actual.extension)) {
      throw new Error('Invalid path or hash in acquired asset record: ' + row.assetKey);
    }
    byPath.set(row.path, row);
    byKey.set(row.assetKey, row);
    if (row.sourceCatalog?.startsWith('marketplace/')) {
      const group = byId.get(row.resourceId) || [];
      group.push(row);
      byId.set(row.resourceId, group);
    }
  }
  return { byPath, byId, byKey };
}

function previewFields(row, kind, caption) {
  return {
    preview: row.path, previewVerified: true, previewKind: kind, previewCaption: caption,
    previewVerificationLevel: 'published-source-bytes-with-sha256',
  };
}

function approvedPreview(item, byKey, byPath) {
  const review = item.previewReviews?.find(row => row.path === item.preview && row.previewEligible);
  const published = review && byKey.get(review.assetKey);
  if (item.previewVerified && published?.path === item.preview && published.actual.sha256 === review.sourceSHA256) {
    return previewFields(published, review.classification, review.observation);
  }
  // A validated image attached to the same share has source provenance even
  // when its subject was not visually reviewed. Keep explicit QA exclusions.
  if (['vehicles', 'outfits', 'themes', 'dlc'].includes(item.category)) {
    for (const candidate of item.previewCandidates || []) {
      if (item.previewReviews?.some(row => row.path === candidate.path && !row.previewEligible)) continue;
      const row = byPath.get(candidate.path);
      if (row?.role === 'thumbnail' && row.actual.sha256 === candidate.sha256 && candidate.originalPostImage &&
          row.provenance.some(source => source.sourceChannelId === item.sourceChannelId &&
            source.sourceMessageId === item.sourceMessageId)) {
        return { ...previewFields(row, 'same-share-source-image', 'Original image attached to this share'),
          previewVerificationLevel: 'same-source-message-and-published-image-bytes' };
      }
    }
  }
  return { preview: null, previewVerified: false };
}

function groupLua(items) {
  const grouped = new Map();
  for (const item of items) {
    const thread = item.sourceParentId && item.provenance?.channelType?.endsWith('Thread');
    const id = thread ? 'cherax-lua-thread-' + item.sourceChannelId : item.id;
    const entries = grouped.get(id) || [];
    entries.push(item);
    grouped.set(id, entries);
  }
  return [...grouped].map(([id, entries]) => {
    const first = entries.find(item => item.sourceMessageId === item.sourceChannelId) || entries[0];
    const releases = new Map();
    for (const item of entries) for (const release of item.changelog || []) {
      const key = [release.date, release.version].join(':');
      const changes = [...new Set([...(releases.get(key)?.changes || []), ...release.changes])];
      releases.set(key, { ...release, changes });
    }
    const changelog = [...releases.values()].sort((a, b) => (b.date || '').localeCompare(a.date || ''));
    return {
      ...first, id, name: first.sourceParentId ? first.provenance?.channelName || first.name : first.name,
      version: changelog[0]?.version || first.version, changelog,
      acquiredAssets: entries.flatMap(item => item.acquiredAssets || []),
      sourceProvenance: entries.flatMap(item => item.sourceProvenance || []),
      tags: [...new Set(entries.flatMap(item => item.tags || []))],
    };
  });
}

function build(catalog, commit, exported, vehicleReview, localLua) {
  const { byPath, byId, byKey } = references(catalog);
  const vehicles = new Map(vehicleReview.entries.map(row => [row.assetKey, row]));
  const updates = new Map();
  for (const [id, rows] of byId) {
    const payloads = rows.filter(row => row.role === 'payload');
    const thumbnail = rows.find(row => row.role === 'thumbnail' && row.previewEligible) ||
      rows.find(row => row.role === 'thumbnail');
    const fields = {};
    if (payloads.length) fields.files = payloads.map(row => ({
      path: row.path, name: row.originalName, size: row.actual.size, sha256: row.actual.sha256,
    }));
    if (thumbnail) {
      const reviewed = vehicles.get(thumbnail.assetKey);
      if (reviewed?.sourceSHA256 === thumbnail.actual.sha256) {
        Object.assign(fields, reviewed.previewEligible ?
          previewFields(thumbnail, reviewed.classification, reviewed.observation) :
          { preview: null, previewVerified: false, previewKind: reviewed.classification });
      } else if (thumbnail.previewEligible && thumbnail.publisherThumbnailKind) {
        Object.assign(fields, previewFields(thumbnail, thumbnail.publisherThumbnailKind,
          thumbnail.visualReview || 'Original source image'));
      }
    }
    updates.set(id, fields);
  }
  for (const association of exported.existingResourceAssociations) {
    const preview = approvedPreview(association, byKey, byPath);
    if (!preview.previewVerified) continue;
    for (const item of association.existingResources) {
      if (!updates.get(item.id)?.previewVerified) updates.set(item.id, { ...updates.get(item.id), ...preview });
    }
  }
  const items = [];
  const lua = exported.items.filter(item => item.category === 'lua' || item.luaPayload);
  const isLua = new Set(lua);
  const auditedLua = new Map(localLua.items.flatMap(item =>
    (item.provenance?.localPaths || []).map(file => [file.sha256, item.id])));
  for (const item of [...exported.items.filter(item => !isLua.has(item)), ...groupLua(lua)]) {
    const preview = approvedPreview(item, byKey, byPath);
    if (item.category === 'lua' || item.luaPayload) {
      const matches = new Set(item.acquiredAssets.map(asset => auditedLua.get(asset.sha256)).filter(Boolean));
      const entry = {
        ...item, category: 'lua', supportedMenus: ['Cherax'], files: [], status: 'pending', downloadStatus: 'pending',
        sourceUrl: undefined, showSourceLink: false, ...preview,
      };
      if (matches.size === 1) {
        const [existingId] = matches;
        const original = localLua.items.find(item => item.id === existingId);
        updates.set(existingId, { ...entry, id: existingId,
          sourceProvenance: [{ kind: 'local-source-audit', ...original.provenance }, ...entry.sourceProvenance],
          changelog: entry.changelog.length ? entry.changelog : original.changelog,
          version: entry.version || original.version,
        });
      } else items.push(entry);
      continue;
    }
    if (!item.files?.length || item.files.some(file => {
      const row = byPath.get(file.path);
      return !row || row.actual.sha256 !== file.sha256 || row.actual.size !== file.size;
    })) continue;
    if (item.category === 'wallpapers' && item.files.every(file => file.path.startsWith('previews/')) &&
        !preview.previewVerified) continue;
    const split = item.files.some(file => file.reconstructionManifest);
    items.push({
      ...item, ...preview, status: 'download', downloadStatus: 'available',
      publicationStatus: 'published', previewStatus: preview.previewVerified ? 'published' : null,
      ...(split ? { requirements: [
        ...item.requirements || [],
        'Download all numbered parts and the reconstruction manifest. Join the parts in the listed order and check the reconstructed file against the manifest’s SHA-256.',
      ] } : {}),
    });
  }
  return {
    schemaVersion: 1, menu: 'Cherax', coolRepoCommit: commit, items,
    updates: [...updates].map(([id, fields]) => ({ id, ...fields })),
    coverage: exported.completeness,
    acquisitionGaps: (exported.gaps || []).filter(gap => gap.name).map(({ name, reason }) => ({ name, reason })),
    summary: { items: items.length, updates: updates.size, verifiedPreviews: items.filter(item => item.previewVerified).length,
      verifiedUpdatedPreviews: [...updates.values()].filter(item => item.previewVerified).length },
  };
}

function completedExportCoverage(catalog) {
  const statusPath = 'cherax-export-status.json';
  if (!fs.existsSync(path.join(sources, statusPath))) return null;
  const status = read(statusPath);
  if (!status.complete) return null;
  const indexPath = 'project/community-menu-sources/cherax-export-downloads/asset-index.json';
  const index = fs.readFileSync(path.join(root, indexPath));
  const indexHash = crypto.createHash('sha256').update(index).digest('hex');
  if (!JSON.parse(index).exportRun?.complete || !catalog.sourceIndexes.some(entry => entry.path === indexPath && entry.sha256 === indexHash)) {
    throw new Error('Completed export coverage requires its exact published acquisition index.');
  }
  const registry = read('cherax-export-channels.json');
  const channels = new Map(registry.channels.map(channel => [channel.id, { channelId: channel.id, exports: 0, threads: 0, messages: 0 }]));
  const rows = status.inventory.exports;
  for (const row of rows) {
    const channel = channels.get(row.parentId || row.channelId);
    if (!channel || !row.currentRun || !Number.isSafeInteger(row.messageCount)) throw new Error('Export inventory includes an unexpected channel or message count.');
    channel.exports++;
    channel.threads += Number(Boolean(row.parentId));
    channel.messages += row.messageCount;
  }
  const totals = [...channels.values()];
  const messages = totals.reduce((sum, channel) => sum + channel.messages, 0);
  const threads = totals.reduce((sum, channel) => sum + channel.threads, 0);
  if (status.guild.id !== registry.guild.id || totals.some(channel => !channel.exports) || new Set(rows.map(row => row.channelId)).size !== rows.length ||
      rows.length !== status.counts.successfulChannels || rows.length !== status.counts.plannedChannels ||
      threads !== status.counts.fetchedThreads || messages !== status.inventory.exportedMessages) throw new Error('Completed export counts did not match the channel inventory.');
  return { finishedAt: status.finishedAt, exports: rows.length, threads, messages, channels: totals };
}

function main(args) {
  const exported = read('cherax-export-items.json');
  const vehicleReview = read('cherax-vehicle-preview-review.json');
  const localLua = read('cherax-lua-audit.json');
  if (args.length === 1 && args[0] === '--plan') {
    const staged = JSON.parse(fs.readFileSync(path.join(target, catalogPath), 'utf8'));
    const result = build(staged, null, exported, vehicleReview, localLua);
    console.log(JSON.stringify({ mode: 'plan', ...result.summary }));
    return;
  }
  if (args.length !== 1 || !/^[a-f0-9]{40}$/.test(args[0])) throw new Error('Pass the verified cool-repo main commit or --plan');
  const [commit] = args;
  if (git('rev-parse', 'refs/remotes/origin/main') !== commit) throw new Error('The commit does not match the cool-repo origin/main tracking ref');
  const catalog = JSON.parse(git('show', commit + ':' + catalogPath));
  const tree = new Set(git('ls-tree', '-r', '--name-only', '-z', commit).split('\0'));
  if (catalog.assets.some(row => !tree.has(row.path))) throw new Error('The published acquisition catalog references a file absent from the commit');
  const result = build(catalog, commit, exported, vehicleReview, localLua);
  result.exportCoverage = completedExportCoverage(catalog);
  fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify({ mode: 'build', commit, ...result.summary }));
}

try { main(process.argv.slice(2)); } catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
