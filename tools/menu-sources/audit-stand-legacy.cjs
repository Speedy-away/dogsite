'use strict';

// Read-only inventory of the existing, indexed ST512 collection. Payload bytes
// are never executed, rewritten, fetched, or evaluated as source code.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const SITE = path.resolve(__dirname, '../..');
const SOURCE_ROOT = path.dirname(SITE);
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const posix = value => value.split(path.sep).join('/');
const MODEL_KEYS = ['Model', 'ModelHash', 'model_hash', 'PedModel'];
const VEHICLE_KEYS = ['Plate Style', 'Plate Text', 'Primary Colour', 'Secondary Colour', 'Wheel Type', 'Engine', 'Brakes', 'Transmission', 'Spoiler', 'Turbo', 'Front Wheels', 'Livery'];
const COMPONENT_KEYS = ['Head', 'Mask', 'Hair', 'Gloves / Torso', 'Pants', 'Parachute / Bag', 'Shoes', 'Accessories', 'Top 2', 'Top 3', 'Decals', 'Top'];
const PROP_KEYS = ['Hat', 'Glasses', 'Earwear', 'Mouth', 'Left Hand', 'Right Hand', 'Watch', 'Bracelet'];

function confinedMedia(relative) {
  if (typeof relative !== 'string' || !/^\.\/media\/[A-Za-z0-9_.-]+$/.test(relative)) throw Error(`Unexpected local media path: ${relative}`);
  const result = path.resolve(SITE, 'community', relative);
  if (path.dirname(result) !== path.join(SITE, 'community/media')) throw Error('Media path escaped collection');
  return result;
}

function parseValues(text) {
  const values = {}, beforeSections = {}, sections = [];
  let section = '';
  for (let line of text.replace(/^\uFEFF/, '').split(/\r?\n/)) {
    line = line.trim();
    if (!line || /^[;#]/.test(line)) continue;
    const heading = /^\[([^\]]+)\]$/.exec(line);
    if (heading) { section = heading[1].trim(); sections.push(section); continue; }
    let split = line.indexOf('=');
    if (split === -1) split = line.indexOf(':');
    if (split < 0) continue;
    const key = line.slice(0, split).trim(), value = line.slice(split + 1).trim();
    values[key.toLowerCase()] = value;
    if (!section) beforeSections[key.toLowerCase()] = value;
    else values[`${section}.${key}`.toLowerCase()] = value;
  }
  return { values, beforeSections, sections };
}

function inspectPayload(bytes, format, kind) {
  const text = bytes.toString('utf8').replace(/^\uFEFF/, '');
  if (format === 'TXT' || format === 'INI') {
    const parsed = parseValues(text);
    const values = format === 'TXT' && kind === 'vehicles' ? parsed.beforeSections : parsed.values;
    const modelKey = MODEL_KEYS.find(key => values[key.toLowerCase()]);
    const components = COMPONENT_KEYS.filter(key => Object.hasOwn(values, key.toLowerCase()));
    const props = PROP_KEYS.filter(key => Object.hasOwn(values, key.toLowerCase()));
    const vehicleKeys = VEHICLE_KEYS.filter(key => Object.hasOwn(values, key.toLowerCase()));
    const componentNumbersValid = [...components, ...props].every(key => /^-?\d+$/.test(values[key.toLowerCase()]));
    let shape;
    if (format === 'INI') shape = `sectioned-values:${parsed.sections.some(x => /^Vehicle0$/i.test(x)) ? 'Vehicle0' : parsed.sections[0] || 'none'}`;
    else if (parsed.sections.length) shape = 'sectioned-txt';
    else if (modelKey && kind === 'vehicles' && vehicleKeys.length) shape = 'stand-vehicle-values';
    else if (modelKey && kind === 'outfits' && components.length && componentNumbersValid) shape = 'stand-outfit-values';
    else if (modelKey && kind === 'vehicles' && components.length && componentNumbersValid) shape = 'outfit-values-in-vehicle-index';
    else shape = 'unrecognized-values';
    return { shape, model: modelKey ? values[modelKey.toLowerCase()] : null, modelKey: modelKey || null,
      modelColonLine: /^\s*Model\s*:\s*\S/im.test(text), sectionCount: parsed.sections.length,
      firstSection: parsed.sections[0] || null, sectionFamilies: [...new Set(parsed.sections.map(x => x.replace(/\d+/g, '#')))],
      valueCount: Object.keys(parsed.values).length, recognizedVehicleKeys: vehicleKeys.length,
      recognizedComponents: components.length, recognizedProps: props.length, componentNumbersValid,
      metadata: Object.fromEntries(Object.entries(parsed.values).filter(([key]) => /^(author|version|created|date|target_version)$/.test(key))) };
  }
  if (format === 'XML') {
    const clean = text.replace(/<\?[\s\S]*?\?>/g, '').replace(/<!--[\s\S]*?-->/g, '').trim();
    const root = /^<([A-Za-z_][\w:.-]*)\b([^>]*)>/.exec(clean);
    const rootName = root?.[1] || null;
    const model = /<ModelHash>\s*([^<]+)\s*<\/ModelHash>/i.exec(text)?.[1]?.trim() || null;
    const metadata = {};
    for (const match of (root?.[2] || '').matchAll(/([\w:.-]+)=["']([^"']*)["']/g)) metadata[match[1]] = match[2];
    for (const field of ['Author', 'Version', 'Created', 'Date']) {
      const match = new RegExp(`<${field}>([^<]*)</${field}>`, 'i').exec(text);
      if (match) metadata[field] = match[1].trim();
    }
    return { shape: `xml:${rootName || 'unknown'}`, root: rootName, rootClosed: !!rootName && new RegExp(`</${rootName}>\\s*$`).test(clean),
      model, vehicleProperties: /<VehicleProperties\b/.test(text), placements: (text.match(/<Placement\b/g) || []).length,
      attachments: (text.match(/<Attachment\b/g) || []).length, metadata,
      validation: 'Root/field signature inspection; no full XML parser or entity expansion used.' };
  }
  if (format === 'JSON') {
    try {
      const root = JSON.parse(text);
      if (!root || Array.isArray(root) || typeof root !== 'object') return { shape: 'json:non-object', metadata: {} };
      const flags = {};
      for (const key of ['vehicle_attributes', 'ped_attributes', 'children', 'vehicles', 'peds', 'objects', 'base', 'mainVehicle', 'Vehicle', 'Main', 'components', 'props', 'outfit', 'Outfit', 'vehicleData', 'format', 'Format', 'builds']) {
        if (Object.hasOwn(root, key)) flags[key] = Array.isArray(root[key]) ? 'array' : root[key] === null ? 'null' : typeof root[key];
      }
      const shape = root.vehicle_attributes ? 'json:constructor-vehicle' : root.ped_attributes ? 'json:constructor-ped'
        : root.vehicles && root.base ? 'json:build-collection' : root.Vehicle ? 'json:Vehicle-wrapper'
          : root.mainVehicle ? 'json:mainVehicle' : root.Format === 'JSTAND 1.1' ? 'json:JSTAND-1.1'
            : root.Main ? 'json:Main-wrapper' : 'json:other';
      const metadata = {};
      for (const key of ['author', 'Author', 'version', 'Version', 'target_version', 'created', 'date', 'name', 'Name', 'Format', 'Type']) {
        if (Object.hasOwn(root, key) && ['string', 'number', 'boolean'].includes(typeof root[key])) metadata[key] = root[key];
      }
      return { shape, rootKeys: Object.keys(root).sort(), flags, type: root.type ?? root.Type ?? null,
        model: root.model || root.Model || root.hash || root.model_hash || null,
        children: Array.isArray(root.children) ? root.children.length : null, metadata };
    } catch (error) { return { shape: 'json:invalid', error: error.message, metadata: {} }; }
  }
  return { shape: 'unknown-format', metadata: {} };
}

function compatibility(kind, inspection) {
  if (inspection.shape === 'stand-vehicle-values') return {
    disposition: 'format-eligible-with-limitations', supportedMenuCandidates: ['scooby', 'nenyoo'],
    reason: 'Both inspected adapters read Model and named Stand vehicle values. Exact appearance parity needs review: Nenyoo subtracts 1 for named mods; Scooby Normalize copies their values directly. Install in the correct Stand vehicle import folder.' };
  if (inspection.shape === 'stand-outfit-values') return {
    disposition: 'format-eligible-with-limitations', supportedMenuCandidates: ['scooby', 'nenyoo'],
    reason: 'Both inspected adapters recognize Model and named component/prop values. This establishes static clothing format support only; hair colour, face data and every optional field are not proven to transfer.' };
  return { disposition: 'review-needed', supportedMenuCandidates: [],
    reason: inspection.shape === 'outfit-values-in-vehicle-index'
      ? 'The vehicle index contains named outfit component/prop values. Review category and import through an outfit loader; do not mark it as a compatible vehicle.'
      : kind === 'outfits' && inspection.shape === 'json:constructor-ped'
      ? 'Constructor ped_attributes/children are not handled by the inspected Nenyoo outfit JSON branch; Scooby StandOutfits proves text-value normalization only.'
      : 'Nenyoo lists the extension, but inspected Scooby Stand converters do not establish this schema. Extension and source collection alone are insufficient compatibility evidence.' };
}

function readSelected(kind, inputs = []) {
  const dataRoot = path.join(SITE, 'resources/data', kind);
  const read = file => { const bytes = fs.readFileSync(file); inputs.push({ path: posix(path.relative(SITE, file)), bytes: bytes.length, sha256: digest(bytes) }); return JSON.parse(bytes); };
  const index = read(path.join(dataRoot, 'index.json'));
  const assets = read(path.join(dataRoot, 'local-assets.json'));
  const chunks = new Map(), records = [];
  index.items.forEach((item, indexNumber) => {
    if (index.categories[item[4]] !== 'ST512') return;
    const chunkNumber = Math.floor(indexNumber / index.chunkSize);
    if (!chunks.has(chunkNumber)) chunks.set(chunkNumber, read(path.join(dataRoot, 'chunks', `${String(chunkNumber).padStart(3, '0')}.json`)));
    const source = chunks.get(chunkNumber)[indexNumber % index.chunkSize];
    if (!source?.[0]?.split('/').includes('ST512')) throw Error(`Category/source mismatch ${kind}:${indexNumber}`);
    const local = assets[indexNumber];
    records.push({ index: indexNumber, kind, name: item[0], originalFilename: item[1], modelHash: item[2],
      model: index.models[item[3]], category: 'ST512', format: index.formats[item[5]],
      sourcePath: source[0], originalPreviews: source[1] || [], sourceRevision: index.sourceRevision,
      sourceUrl: index.sourceBaseUrl + source[0].split('/').map(encodeURIComponent).join('/'),
      localFile: local?.file || null, localPreview: local?.preview || null });
  });
  return { index, records };
}

function sourceEvidence() {
  const files = [
    ['Nenyoo', 'project-native-gui/GTAV/src/spooner/preset_loader.cpp', [68, 72, 510, 530, 539, 667, 734, 762, 776, 797]],
    ['Scooby vehicles', 'Scooby-Op/GTA5/EE/GTA - Main Src/src/game/frontend/submenus/OtherMenus/Stand/StandVehicles.cpp', [100, 114, 131, 172, 188, 197, 204, 237]],
    ['Scooby outfits', 'Scooby-Op/GTA5/EE/GTA - Main Src/src/game/frontend/submenus/OtherMenus/Stand/StandOutfits.cpp', [75, 140, 153, 163, 174, 186, 194]],
  ];
  return files.map(([menu, relative, lines]) => { const bytes = fs.readFileSync(path.join(SOURCE_ROOT, relative)); return { menu, path: relative, bytes: bytes.length, sha256: digest(bytes), relevantLines: lines }; });
}

function audit() {
  const inputs = [], kinds = {}, allGroups = [], rowsDigest = crypto.createHash('sha256');
  for (const kind of ['vehicles', 'outfits']) {
    const { index, records } = readSelected(kind, inputs), groups = new Map(), hashes = new Map();
    const summary = { selectedRecords: records.length, indexedTotal: index.totalItems, sourceRevision: index.sourceRevision,
      sourceBaseUrl: index.sourceBaseUrl, byFormat: {}, payloadFilesPresent: 0, payloadFilesMissing: 0, payloadBytes: 0,
      previewsPresent: 0, previewsMissing: 0, previewBytes: 0, originalPreviewReferences: 0,
      metadataValues: {}, eligibleCandidates: 0, reviewNeeded: 0, sourcePathsContainingOldFolders: 0,
      missingPreviewSamples: [], samples: [] };
    for (const record of records) {
      summary.byFormat[record.format] = (summary.byFormat[record.format] || 0) + 1;
      summary.originalPreviewReferences += record.originalPreviews.length;
      if (record.sourcePath.split('/').includes('old_folders')) summary.sourcePathsContainingOldFolders++;
      const payloadPath = record.localFile ? confinedMedia(record.localFile) : null;
      const payloadStat = payloadPath && fs.existsSync(payloadPath) ? fs.statSync(payloadPath) : null;
      const previewPath = record.localPreview ? confinedMedia(record.localPreview) : null;
      const previewStat = previewPath && fs.existsSync(previewPath) ? fs.statSync(previewPath) : null;
      if (payloadStat?.isFile()) { summary.payloadFilesPresent++; summary.payloadBytes += payloadStat.size; }
      else summary.payloadFilesMissing++;
      if (previewStat?.isFile()) { summary.previewsPresent++; summary.previewBytes += previewStat.size; }
      else {
        summary.previewsMissing++;
        if (summary.missingPreviewSamples.length < 10) summary.missingPreviewSamples.push({ index: record.index, name: record.name, sourcePath: record.sourcePath, localPreview: record.localPreview });
      }
      const bytes = payloadStat?.isFile() ? fs.readFileSync(payloadPath) : null;
      const sha256 = bytes ? digest(bytes) : null;
      if (sha256) hashes.set(sha256, (hashes.get(sha256) || 0) + 1);
      const inspection = bytes ? inspectPayload(bytes, record.format, kind) : { shape: 'missing-payload', metadata: {} };
      const assessment = compatibility(kind, inspection);
      if (assessment.disposition === 'format-eligible-with-limitations') summary.eligibleCandidates++;
      else summary.reviewNeeded++;
      const key = `${record.format}/${inspection.shape}/${assessment.disposition}`;
      if (!groups.has(key)) groups.set(key, { kind, key, format: record.format, shape: inspection.shape, count: 0,
        ...assessment, previewsPresent: 0, payloadBytes: 0, sectionCountRange: null, xmlClosedRoots: 0, modelColonLines: 0, samples: [] });
      const group = groups.get(key); group.count++; group.payloadBytes += bytes?.length || 0;
      if (previewStat?.isFile()) group.previewsPresent++;
      if (inspection.rootClosed) group.xmlClosedRoots++;
      if (inspection.modelColonLine) group.modelColonLines++;
      if (inspection.sectionCount !== undefined) group.sectionCountRange = group.sectionCountRange
        ? [Math.min(group.sectionCountRange[0], inspection.sectionCount), Math.max(group.sectionCountRange[1], inspection.sectionCount)] : [inspection.sectionCount, inspection.sectionCount];
      for (const [field, value] of Object.entries(inspection.metadata)) {
        if (!summary.metadataValues[field]) summary.metadataValues[field] = {};
        const label = String(value); summary.metadataValues[field][label] = (summary.metadataValues[field][label] || 0) + 1;
      }
      const sample = { ...record, payloadBytes: bytes?.length ?? null, payloadSha256: sha256,
        previewBytes: previewStat?.isFile() ? previewStat.size : null, inspection };
      if (group.samples.length < 5) group.samples.push(sample);
      if (summary.samples.length < 3) summary.samples.push(sample);
      rowsDigest.update(JSON.stringify({ ...record, payloadBytes: bytes?.length ?? null, payloadSha256: sha256,
        previewBytes: previewStat?.isFile() ? previewStat.size : null, shape: inspection.shape }) + '\n');
    }
    summary.uniquePayloadHashes = hashes.size;
    summary.byteIdenticalDuplicateRecords = [...hashes.values()].reduce((sum, count) => sum + count - 1, 0);
    summary.groups = [...groups.values()];
    kinds[kind] = summary; allGroups.push(...summary.groups);
  }
  return { schemaVersion: 1, sourceMenu: 'stand', sourceCollection: 'ST512', auditedAt: '2026-11-11',
    scope: 'Every ST512-indexed vehicle/outfit record in the current site data. Every referenced local payload was read, hashed and signature-inspected; every referenced preview was statted. Other collections and Discord were not inspected by this helper.',
    noRuntimeCompatibilityClaim: true,
    limitations: ['Legacy collection membership establishes source provenance, not verified Discord channel/post coverage.',
      'Format-eligible candidates indicate both inspected adapters accept the static text-value schema; they do not establish identical rendering or gameplay operation.',
      'No file dates are promoted to author release/changelog dates. JSON metadata is retained as supplied.',
      'XML checks inspect root and field signatures, not full syntax or engine acceptance.',
      'Source code evidence is limited to the three explicitly requested loader files. Non-TXT formats require additional Scooby loader evidence before shared compatibility labels.'],
    inputFiles: inputs, loaderEvidence: sourceEvidence(), recordInventorySha256: rowsDigest.digest('hex'),
    inventoryDigestDefinition: 'SHA256 of ordered JSON lines over every selected vehicle, then outfit, containing metadata, source path/URL, local paths, payload size/hash, preview size and detected shape. Re-run the helper to reproduce; full rows intentionally omitted from this grouped evidence report.',
    totalRecords: Object.values(kinds).reduce((s, x) => s + x.selectedRecords, 0),
    eligibleCandidateRecords: allGroups.filter(g => g.disposition === 'format-eligible-with-limitations').reduce((s, g) => s + g.count, 0),
    reviewNeededRecords: allGroups.filter(g => g.disposition === 'review-needed').reduce((s, g) => s + g.count, 0), kinds };
}

module.exports = { audit, inspectPayload, readSelected, compatibility };
if (require.main === module) {
  const result = audit();
  const output = path.join(SITE, 'project/community-menu-sources/stand-legacy-audit.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify({ output: posix(output), totalRecords: result.totalRecords,
    eligibleCandidates: result.eligibleCandidateRecords, reviewNeeded: result.reviewNeededRecords,
    kinds: Object.fromEntries(Object.entries(result.kinds).map(([key, value]) => [key, {
      formats: value.byFormat, payloadsPresent: value.payloadFilesPresent, previewsPresent: value.previewsPresent,
      uniquePayloads: value.uniquePayloadHashes, groups: value.groups.map(({ key, count }) => ({ key, count })) }])) }, null, 2));
}
