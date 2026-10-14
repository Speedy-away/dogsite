const test = require('node:test');
const assert = require('node:assert/strict');
const {accessFromSource, stripComments, parseSources} = require('./features/gta5-source.cjs');
const manifest = require('./features/features-gta5.json');
const items = manifest.tabs.flatMap(t => t.categories.flatMap(c => c.groups.flatMap(g => g.items)));
test('refresh adds registered features and drops deleted commands despite surviving menu labels', () => {
  const access = 'constexpr std::array kFreePlayerSupportCommands{Joaat("healall")}; constexpr std::array kPremiumCommands{Joaat("paid")};';
  const menu = {file:'/src/game/frontend/submenus/Self.cpp',text:'page->AddItem(std::make_shared<CommandItem>("removed"_J, "Old feature")); page->AddItem(std::make_shared<CommandItem>("newfeature"_J));'};
  const definitions = {file:'/src/game/features/self/New.cpp',text:'class Action : public Command {}; static Action next{"newfeature", "New feature", "Current implementation."};'};
  const initial = parseSources([menu,definitions],access);
  assert.equal(initial.labels['command.newfeature.label'],'New feature');
  assert.equal(initial.labels['command.removed.label'],undefined);
  assert.ok(initial.unresolved.includes('removed'));
  const deleted = parseSources([menu],access);
  assert.equal(deleted.labels['command.newfeature.label'],undefined);
});
test('premium wrappers follow nested groups, not conditional controller IDs; Free exceptions win', () => {
  const text = stripComments(`
    controls->AddItem(std::make_shared<ConditionalItem>("freeToggle"_J, std::make_shared<FloatCommandItem>("paidSetting"_J)));
    controls->AddItem(std::make_shared<CommandItem>("healall"_J));
    page->AddItem(controls);
    root->AddItem(PremiumItem::Only(std::move(page)));
    // root->AddItem(PremiumItem::Only(std::make_shared<CommandItem>("commented"_J)));
  `);
  const {premium} = accessFromSource([{text}], `constexpr std::array kFreePlayerSupportCommands{Joaat("healall")}; constexpr std::array kPremiumCommands{Joaat("knownPaid")};`);
  assert.deepEqual([...premium].sort(), ['knownPaid','paidSetting']);
});
test('catalogue has unique IDs, valid access labels and representative access gates', () => {
  assert.equal(new Set(items.map(i => i.id)).size, items.length);
  assert.equal(items.length, manifest.stats.features);
  assert.ok(items.every(i => i.label && ['free','premium'].includes(i.access)));
  for (const id of ['hkickall','samurai_cayocompoundloot','samurai_cayoislandloot']) assert.ok(!items.some(i=>i.id===id), `Unregistered ${id} must not return`);
  for (const id of ['godmode','healall','giveallarmor','clearwantedall','fireworksonplayer','velocityvehiclefly','rainbomizertraffic']) assert.equal(items.find(i => i.id === id)?.access, 'free', id);
  for (const id of ['freeshopping','vehiclefly','blackhole','tornadoworld','rainbomizerlivetraffic','vehicletricktype','vehicletirelights','cayopericoheistinstantfinish']) assert.equal(items.find(i => i.id === id)?.access, 'premium', id);
});
test('generated product and library share the same comparison', () => {
  const fs = require('node:fs');
  const {renderComparison} = require('./features/gta5-editions.cjs');
  const normalize = text => text.replace(/>\s+</g,'><').trim();
  for (const file of ['products/gta5/index.html','features-list/gta-features/index.html']) {
    const html = fs.readFileSync(file,'utf8');
    assert.ok(normalize(html).includes(normalize(renderComparison())), file);
  }
});
