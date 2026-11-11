'use strict';

const fs = require('node:fs');
const crypto = require('node:crypto');

function assertGap(gap) {
  const withoutComments = gap.replace(/\/\*[\s\S]*?\*\/|\/\/[^\r\n]*/g, '');
  if (!/^[\s,]*$/.test(withoutComments)) {
    throw new Error('Unexpected content in the bundled outfit array; no files were extracted.');
  }
}

function validateOutfit(data, gender, name) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new Error(`Outfit ${name} must be a JSON object.`);
  }
  let components = 0;
  for (const [key, value] of Object.entries(data)) {
    if (key === 'compatibility') {
      if (!value || typeof value !== 'object' || Array.isArray(value)
          || Object.keys(value).some((field) => field !== 'gender')
          || value.gender !== (gender === 'Male')) {
        throw new Error(`Outfit ${name} has invalid gender compatibility.`);
      }
    } else if (/^\d+$/.test(key) && Number(key) <= 0xffffffff
        && Number.isInteger(value) && value >= 0 && value <= 0xffffffff) {
      components++;
    } else {
      throw new Error(`Outfit ${name} has an unsupported component field: ${key}.`);
    }
  }
  if (!components) throw new Error(`Outfit ${name} has no clothing components.`);
}

/** Extract clothing data only; this never evaluates or copies C++ source. */
function extractBundledOutfits(source) {
  if (typeof source !== 'string') throw new TypeError('Expected bundled outfit source text.');
  const declaration = /\bconst\s+BundledOutfit\s+g_BundledOutfits\s*\[\s*\]\s*=\s*\{/.exec(source);
  if (!declaration) throw new Error('Could not find the bundled outfit array.');
  const rest = source.slice(declaration.index + declaration[0].length);
  const end = /^\s*\};/m.exec(rest);
  if (!end) throw new Error('The bundled outfit array is incomplete.');
  const body = rest.slice(0, end.index);
  const entry = /\{\s*("(?:\\.|[^"\\])*")\s*,\s*("(?:\\.|[^"\\])*")\s*,\s*R"json\(([\s\S]*?)\)json"\s*\}/g;
  const outfits = [];
  const filenames = new Set();
  let previousEnd = 0;
  for (const match of body.matchAll(entry)) {
    assertGap(body.slice(previousEnd, match.index));
    previousEnd = match.index + match[0].length;
    const name = JSON.parse(match[1]);
    const gender = JSON.parse(match[2]);
    if (!name.trim() || !['Male', 'Female'].includes(gender)) {
      throw new Error('A bundled outfit has an invalid label or gender.');
    }
    let data;
    try { data = JSON.parse(match[3]); }
    catch (error) { throw new Error(`Outfit ${name} contains invalid JSON: ${error.message}`); }
    validateOutfit(data, gender, name);
    const slug = name.normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
      .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 100) || 'outfit';
    const base = `${gender.toLowerCase()}-${slug}`;
    let filename = `${base}.json`;
    for (let index = 2; filenames.has(filename); index++) filename = `${base}-${index}.json`;
    filenames.add(filename);
    const json = `${JSON.stringify(data, null, 2)}\n`;
    outfits.push({ name, gender, filename, data, json, bytes: Buffer.byteLength(json),
      sha256: crypto.createHash('sha256').update(json).digest('hex') });
  }
  assertGap(body.slice(previousEnd));
  if (!outfits.length) throw new Error('No bundled outfits were found.');
  return outfits;
}

function readBundledOutfits(sourcePath) {
  return extractBundledOutfits(fs.readFileSync(sourcePath, 'utf8'));
}

module.exports = { extractBundledOutfits, readBundledOutfits };

if (require.main === module) {
  if (process.argv[2] === '--self-test') {
    const assert = require('node:assert/strict');
    const valid = 'const BundledOutfit g_BundledOutfits[] = {\n'
      + '{"../Blue Shirt", "Male", R"json({"1":2,"compatibility":{"gender":true}})json"},\n'
      + '{"../Blue Shirt", "Male", R"json({"1":3,"compatibility":{"gender":true}})json"},\n};';
    const entries = extractBundledOutfits(valid);
    assert.equal(entries.length, 2);
    assert.equal(entries[0].filename, 'male-blue-shirt.json');
    assert.equal(entries[1].filename, 'male-blue-shirt-2.json');
    assert.deepEqual(JSON.parse(entries[0].json), entries[0].data);
    assert.throws(() => extractBundledOutfits(valid.replace('"1":2', '"1":-1')), /unsupported component/);
    assert.throws(() => extractBundledOutfits(valid.replace('"gender":true', '"gender":false')), /gender compatibility/);
    assert.throws(() => extractBundledOutfits(valid.replace('"1":2', '"1":')), /invalid JSON/);
    assert.throws(() => extractBundledOutfits(valid.replace('\n};', '\nrun_code();\n};')), /Unexpected content/);
    process.stdout.write('Bundled outfit extractor self-test passed.\n');
  } else if (process.argv[2]) {
    const entries = readBundledOutfits(process.argv[2]);
    process.stdout.write(`${JSON.stringify({ outfits: entries.length,
      male: entries.filter((entry) => entry.gender === 'Male').length,
      female: entries.filter((entry) => entry.gender === 'Female').length,
      bytes: entries.reduce((total, entry) => total + entry.bytes, 0) }, null, 2)}\n`);
  } else {
    process.stderr.write('Usage: node tools/extract-community-outfits.cjs <BundledOutfits.cpp> | --self-test\n');
    process.exitCode = 1;
  }
}
