'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { galleryImages } = require('./refresh-gta5-addons.cjs');
const catalog = require('../community/data/gta5-addons.json');

test('vehicle gallery extraction keeps original images and rejects unrelated links', () => {
  const html = `<a class="thumbnail mfp-image cover-media" href="https://img.gta5-mods.com/q95/images/car/one.jpg"></a>
    <a class="thumbnail mfp-image" href="https://img.gta5-mods.com/q95/images/car/two.jpg"></a>
    <a class="thumbnail mfp-image" href="https://img.gta5-mods.com/q95/images/car/one.jpg"></a>
    <a class="thumbnail mfp-image" href="https://example.com/images/car/other.jpg"></a>
    <a href="https://img.gta5-mods.com/q95/images/car/unrelated.jpg"></a>`;
  assert.deepEqual(galleryImages(html), [
    'https://img.gta5-mods.com/q95/images/car/one.jpg',
    'https://img.gta5-mods.com/q95/images/car/two.jpg'
  ]);
});

test('vehicle galleries contain distinct source images and include the Murciélago', () => {
  const galleries = catalog.items.filter(item => item.category === 'addon-vehicles' && item.imageUrls?.length);
  assert(galleries.length >= 40);
  for (const item of galleries) {
    assert(item.imageUrls.length > 1, item.name);
    assert.equal(new Set(item.imageUrls).size, item.imageUrls.length, item.name);
    for (const url of item.imageUrls) assert.equal(new URL(url).hostname, 'img.gta5-mods.com', item.name);
  }
  assert(catalog.items.find(item => item.id === 'gta5-author-addon-50386b6eda16216e').imageUrls.length > 1);
});
