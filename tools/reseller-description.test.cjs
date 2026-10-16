const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {describeProduct}=require('./reseller-description.cjs');
const read=slug=>describeProduct(slug,fs.readFileSync(path.join(__dirname,'../products',slug,'index.html'),'utf8'));

test('store descriptions retain product-specific features and access distinctions',()=>{
  const gta=read('gta5');
  assert.match(gta,/Premium.*session host/);
  assert.match(gta,/Plus.*BattlEye Enabled/);
  assert.match(gta,/Your player, your setup \[Free · all plans\]/);
  assert.match(gta,/Heists, missions & businesses \[Premium & Plus\]/);
  const five=read('fivem');
  assert.match(five,/PREMIUM ACCESS/);
  assert.match(five,/Free combat controls/);
  assert.match(five,/Vehicle ESP — upcoming/);
  assert.match(five,/validation are pending/);
  assert.match(read('rdr2'),/Horse & Vehicle/);
  assert.match(read('redm'),/Combat Features/);
  assert.match(read('last-of-us'),/Build a scene\nBrowse items/);
  assert.match(read('last-of-us'),/Part II support is not available yet/);
  for(const slug of ['gta5','rdr2','fivem','redm','cs2','gmod','l4d','tf2','sbox','half-life-1','last-of-us']) {
    const copy=read(slug);
    assert(copy.split(/\s+/).length>150,slug+' needs detailed copy');
    assert.match(copy,/FEATURES & COMPATIBILITY/);
    assert(!/<\/?(?:div|span|script|p|section)\b|&amp;/.test(copy),slug+' has HTML');
  }
});
test('unavailable products do not acquire a released feature list',()=>{
  for(const slug of ['black-mesa','bodycam','gta3','rdr1','pubg']) {
    const copy=read(slug);
    assert.match(copy,/not currently available for sale/);
    assert(!copy.includes('FEATURES & COMPATIBILITY'));
  }
});
test('nested layout wrappers retain feature groups and readable text',()=>{
  const copy=describeProduct('example',`<main><h1>Example</h1><p class="product-intro">A product overview.</p><div class="description-content"><p>More detail.</p><div class="product-feature-grid"><section><span class="feature-access">Premium &amp; Plus</span><h3>Movement</h3><div><p>Choose your camera.</p><ul><li><strong>Profiles</strong> — Save your setup.</li></ul></div></section><section><h3>Visuals</h3><p>Customize colours.</p></section></div></div></main>`);
  assert.match(copy,/Movement \[Premium & Plus\]\nChoose your camera\.\n- Profiles — Save your setup\./);
  assert.match(copy,/Visuals\nCustomize colours\./);
});
