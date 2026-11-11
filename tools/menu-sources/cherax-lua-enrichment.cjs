'use strict';

// Static metadata only. Never loads Lua, bytecode, Discord or private APIs.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const AUDIT = path.join(ROOT, 'project/community-menu-sources/cherax-lua-audit.json');
const OUTPUT = path.join(ROOT, 'project/community-menu-sources/cherax-lua-enrichment.json');
const LOCAL = path.resolve(ROOT, '../cherax-luas');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const release = (version, needle, changes, extra = {}) => ({ version, needle, changes, ...extra });

// Each paraphrase is tied to an explicit versioned source changelog, rather
// than inferred from code behavior, filenames, timestamps or a generic feature list.
const CURATED = {
  'chat-commands': { version: ['2.0', /Chat Commands v2\.0/], author: ['MMmitch', /by @MMmitch/] },
  driftgod: {
    version: ['1.0.7', /DRIFTGOD v1\.0\.7 - Production Release/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    history: [
      release('1.0.7', '- v1.0.7 - expands Drift tuning', ['Expands corner-speed assistance and first-use driving guidance.', 'Adds smoke and neon progression, animation presets and persistent activation preferences.', 'Improves popup, spawn and onboarding handling while retaining existing saved progress.']),
      release('1.0.6', '- v1.0.6 - merges the multi-account leaderboard', ['Introduces separate account score profiles, upload pacing and recovery.', 'Refreshes live leaderboards and blocks Story Mode submissions; identity and scores remain client-reported.']),
      release('1.0.5', '- v1.0.5 - integrates DriftGod Online', ['Combines online leaderboards, a Rival HUD and separate Drift / Power Glide rankings.', 'Adds first-run asset installation, onboarding and score checkpoints.']),
      release('1.0.4', '- v1.0.4 - major content and polish', ['Adds Power Glide handling presets and Drift Smoke unlocks.', 'Improves dashboard navigation, garage integration and diagnostic dialogs.']),
      release('1.0.3', '- v1.0.3 - bug fixes and stability', ['Keeps manually chosen drift presets after startup and unlock checks.', 'Prevents chat input from operating HUD menus and improves reload and smoke cleanup.']),
      release('1.0.2', '- v1.0.2 - acceleration and tuning activation', ['Improves low-speed acceleration assistance and enables tuning when a base preset is selected.']),
      release('1.0.1', '- v1.0.1 - prime compatibility', ['Adds Prime-aware runtime and cleanup handling, recursive garage scanning and configurable garage shortcuts.']),
      release('1.0.0', '- v1.0.0 - product build', ['Establishes the production package with quieter startup, protected settings and revised rewards and HUD shortcuts.']),
    ],
  },
  earplugs: {
    version: ['1.0.1', /local VERSION = "1\.0\.1"/],
    history: [
      release('1.0.1', '-- v1.0.1   fix:', ['Includes flight music in the score-music control.']),
      release('1.0.0', '-- v1.0.0   feat:', ['Removes the debug tab, logging and Now Playing display from the release build.']),
      release('0.6.1', '-- v0.6.1   fix:', ['Corrects the audio-scene full-level setting.']),
      release('0.6.0', '-- v0.6.0   feat:', ['Checks the switches against game data and adds the Silenced option.']),
      release('0.5.0', '-- v0.5.0   feat:', ['Adds controls for radio, weapons, alarms and other-player sounds.']),
      release('0.4.2', '-- v0.4.2   fix:', ['Corrects handling of audio scenes that end automatically.']),
      release('0.4.1', '-- v0.4.1   fix:', ['Repairs helicopter and footstep controls.']),
      release('0.4.0', '-- v0.4.0   feat:', ['Groups additional switches and sub-switches into columns.']),
      release('0.3.0', '-- v0.3.0   feat:', ['Introduces the Earplugs name, a grid layout and sixteen additional switches.']),
      release('0.2.0', '-- v0.2.0   feat:', ['Adds weather, aircraft, location, pain, Arena and Car Meet sound controls.']),
      release('0.1.0', '-- v0.1.0   feat:', ['Provides the initial seventeen-switch audio test interface and logging.']),
    ],
  },
  'host-tools': { version: ['1.7.2', /HTV\.VERSION\s*=\s*"1\.7\.2"/], author: ['Plynko', /--Credit: Plynko/], notes: ['The older header says 0.28b (v85); 1.7.2 is the explicit runtime version declaration.'] },
  'hulk-mode': {
    version: ['vBETA', /K\.SUITE_VERSION = "Hulk Mode vBETA"/],
    notes: ['The filename/header say v3.1, the runtime identity says vBETA, and the header history reaches v4.1. These are documented source labels, not a verified published release sequence.'],
    history: [
      release('4.1', '--  v4.1 : MENU', ['Reorganizes the HULK interface into feature and Playground tabs and consolidates progression state.']),
      release('4.0', '--  v4.0 : SKILLS', ['Adds a saved skill tree, level perks, daily challenges, repeated-target reward reduction and a friends mode.']),
      release('3.9', '--  v3.9 : HULK PROGRESSION', ['Adds action and combo experience, chained-action bonuses and an on-screen XP feed.']),
      release('3.8', '--  v3.8 : QUEST SYSTEM', ['Expands the quest pool, adds level-based quest slots and saves progression between sessions.']),
      release('3.7', '--  v3.7 : SUPER PUNCH', ['Rechecks punch targets at impact, improves target assistance and introduces layered punch sounds.']),
      release('3.6', '--  v3.6 : BETTER TRAJECTORY', ['Smooths trajectory rendering and adds impact markers, distance feedback and preview settings.']),
      release('3.5', '--  v3.5 : BUG FIXES', ['Restores saved settings, ignores hotkeys during chat or pause and adds trajectory and action sounds.']),
      release('3.4', '--  v3.4 : CARRIED NPCs', ['Restores visible living-NPC carry poses and separate handling for dead NPCs.']),
      release('3.3', '--  v3.3 : FIX + CLEANUP', ['Repairs rage behavior, thrown-NPC collision and zero-valued rage bonuses; improves entity cleanup and menu controls.']),
    ],
  },
  hustlemeter: {
    version: ['1.0.9', /local script_version = "v1\.0\.9"/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    history: [
      release('1.0.9', '- v1.0.9 - Smart Heists removed', ['Removes Smart Heists and controls over Silent Night or Codax heist settings.'], { date: '2026-08-14', dateNeedle: /local script_build = "2026\.08\.14\.061-/, dateBasis: 'Date encoded in the local script build identifier; publication date not independently verified.' }),
      release('1.0.5', '- v1.0.5 - confirmed LE/EE', ['Updates Legacy/Enhanced wallet tracking, baseline recovery and deferred resets.', 'Expands payout diagnostics and support archive generation.']),
      release('1.0.4', '- v1.0.4 - added transition-safe', ['Adds balance tracking across transitions, separate edition ledgers and automatic support diagnostics.']),
      release('1.0.3', '- v1.0.3 - added faster', ['Speeds up payout scanning and expands transition coverage.']),
      release('1.0.2', '- v1.0.2 - added the persistent', ['Adds a saved setting that keeps the HUD visible without a timeout.']),
      release('1.0.1', '- v1.0.1 - added automatic', ['Separates ledgers by Rockstar account and tidies the interface.']),
      release('1.0.0', '- v1.0.0 - initial stable', ['Introduces rolling one-day and seven-day money tracking.']),
    ],
  },
  liquidfit: { version: ['1.1.1', /local VERSION = "1\.1\.1" -- public version/] },
  minigames: {
    version: ['1.0.0', /local script_version = "v1\.0\.0"/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    history: [release('1.0.0', '- v1.0.0 - initial production release.', ['Introduces the production Minigames package.'], { date: '2026-08-02', dateNeedle: /local script_release_date = "2026-08-02"/, dateBasis: 'Explicit release-date declaration in the local script; not independently verified against a public release.' })],
  },
  modverse: {
    version: ['1.0.0', /local SCRIPT_VERSION = "1\.0\.0"/], author: ['Public_Urinal', /Developer: Public_Urinal/],
    history: [
      release('1.0.0 Build 154', 'v1.0.0 Build 154 changes:', ['Removes obsolete browser reconstruction helpers while retaining binary image/ZIP checks and the preceding storefront behavior.']),
      release('1.0.0 Build 153', 'v1.0.0 Build 153 changes:', ['Repairs a gallery crash and card rendering, removes stale ASI hints and updates DLC load guidance.']),
      release('1.0.0 Build 152', 'v1.0.0 Build 152 changes:', ['Removes DLL downloading, native library loading, external workers and ASI launch paths.', 'Restores DLC index loading with stricter relative-path checks.']),
    ],
  },
  paintlabs: {
    version: ['1.0.0', /local SCRIPT_VERSION = "1\.0\.0"/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    notes: ['The filename says 1.02; the source header and runtime version both declare 1.0.0.'],
    history: [
      release('1.0.0', '- v1.0.0 - first public production', ['Packages the production Three Lane editor, color credits and complete lighting/smoke preset persistence.', 'Improves paint identifiers, Favorites migration and provenance handling.']),
      release('0.9.0', '- v0.9.0 - finalized Three Lane', ['Introduces PaintLabs branding, complete-state presets, improved sorting and creator credit displays.']),
      release('0.8.0', '- v0.8.0 - imported and deduplicated', ['Expands and deduplicates community colors, adds contrast/temperature controls and matures the Three Lane editing workflow.']),
      release('0.7.0', '- v0.7.0 - added Remix This Pearlescent', ['Adds pearlescent remixes and finish overrides while experimenting with editor layouts.']),
      release('0.6.0', '- v0.6.0 - expanded Ai to 500', ['Expands generated combinations to five hundred and adds color relatives with persistent Favorites.', 'Makes neon underglow optional and disabled initially.']),
      release('0.5.0', '- v0.5.0 - introduced Ai paint', ['Introduces generated paint recommendations and expands the set to one hundred contrasting combinations.']),
      release('0.4.0', '- v0.4.0 - expanded Exotic', ['Creates a dedicated Exotic gallery with specialty presets and improved Favorites navigation.']),
      release('0.3.0', '- v0.3.0 - introduced the grid', ['Adds a grid gallery, tire-smoke matching, preview snapshots and initial Exotic presets.']),
      release('0.2.0', '- v0.2.0 - added confirmed', ['Adds pearlescent filtering, safer preview restoration and saved-preset controls.']),
      release('0.1.0', '- v0.1.0 - embedded the community', ['Adds a browsable community color library, hover previews, Favorites and automatic showcasing.']),
      release('0.0.1', '- v0.0.1 - initial Cherax', ['Introduces primary/secondary paint editing, finishes, pearlescent controls, mixing and preset saving.']),
    ],
  },
  'pvp-helper': { version: ['1.1.3', /local SCRIPT_VERSION = "1\.1\.3"/] },
  'smart-console': { version: ['1.0.1', /local VERSION\s*=\s*"1\.0\.1"/] },
  startup: {
    version: ['1.0.18', /startup\.version = "v1\.0\.18"/], author: ['Public_Urinal', /Developed by: Public_Urinal/],
    history: [
      release('1.0.18', 'v1.0.18 • Production Release', ['Adds live Browser event notifications, event feedback and an expanded-minimap HUD adapter.', 'Adds edition-aware event join notices and a contextual death log.', 'Improves HUD suppression and persists retaliation preferences, including the disabled auto-bounty setting.'], { date: '2026-10-02', dateNeedle: /startup\.build_date = "2026-10-02"/, dateBasis: 'Explicit local build-date declaration; publication date not independently verified.' }),
      release('1.0.16', 'v1.0.16 • Advertising, HUD', ['Updates advertising controls and account linking, with revised activity/HUD layouts and session-routing safeguards.']),
      release('1.0.15', 'v1.0.15 • Join Fixes', ['Repairs Browser joins and improves cancellation of duplicate or stale join attempts.', 'Prepares Prime Browser support and reduces startup renderer work.']),
      release('1.0.13', 'v1.0.13 • Startup Browser', ['Introduces live sessions and events, favorites, reputation and moderation controls.', 'Adds automatic Browser asset delivery and recovery.']),
      release('1.0.11', 'v1.0.11 • Session, HUD', ['Expands session routing, HUD cards and Prime support with improved diagnostics and onboarding.']),
      release('1.0.10', 'v1.0.10 • Production Stability', ['Repairs blank startup menus and improves advertising, settings discovery and guided setup.']),
    ],
  },
  trackmatic: {
    version: ['1.0.1', /local TG_VERSION = "v1\.0\.1"/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    history: [
      release('1.0.1', '- v1.0.1 - no protected calls:', ['Revises Cherax call handling and build cancellation.', 'Caches display calculations to reduce repeated menu work.']),
      release('1.0.0', '- v1.0.0 - first production', ['Packages the production interface, cleaner startup logging and error handling.']),
      release('0.9.9', '- v0.9.9 - fixed Home', ['Repairs Home-tab style colors and ImGui compatibility.']),
      release('0.9.8', '- v0.9.8 - introduced redesigned', ['Reorganizes the TrackMatic interface and tab navigation.']),
      release('0.9.7', '- v0.9.7 - improved saved-track', ['Improves saved-course loading, metadata and management.']),
      release('0.9.6', '- v0.9.6 - simplified start', ['Uses a flag icon and GPS route for course starts.']),
      release('0.9.5', '- v0.9.5 - introduced automatic', ['Adds automatically placed course-start markers.']),
      release('0.9.3', '- v0.9.3 - introduced Saved', ['Adds a library for saving, loading and browsing tracks.']),
      release('0.9.2', '- v0.9.2 - expanded Track', ['Adds ninety point-to-point drift routes.']),
      release('0.9.1', '- v0.9.1 - introduced 30', ['Adds thirty tuner settings for both Parkour and Hybrid courses.']),
      release('0.9.0', '- v0.9.0 - connected hover', ['Connects hover previews to the course planner.']),
      release('0.8.0', '- v0.8.0 - introduced advanced', ['Adds advanced course tuning, live 3D previews and saved tuner settings.']),
    ],
  },
  'vehicle-forge': { version: ['1.0.1', /local VERSION = "1\.0\.1"/] },
  vibescript: { version: ['2.2.1', /local VIBE_VERSION = "2\.2\.1"/], notes: ['The v2.5.0 and 2.2.1 filenames have identical bytes; VIBE_VERSION declares 2.2.1.'] },
  bodyguards: {
    version: ['4.0', /local SCRIPT_VERSION = "4\.0"/],
    history: [release('4.0', '-- v4.0 changelog:', ['Repairs vehicle shooting, guard numbering, relationship refresh and unload cleanup.', 'Adds advanced guard tuning, convoy behavior, a live roster and two-tier weapon selection.', 'Adds player-clone spawning, seat locks and automatic escort recovery.'])],
  },
  'discord-rpc-reborn': {
    version: ['1.2.4', /local SCRIPT_VERSION = "1\.2\.4"/],
    history: [
      release('1.2.4', /^v1\.2\.4$/, ['Adds an image-based crosshair and refreshes presence after returning to the main menu.']),
      release('1.2.3', /^v1\.2\.3$/, ['Adds a configurable crosshair and repairs menu rendering errors.']),
      release('1.2.0', /^v1\.2\.0$/, ['Detects casino activity and improves character-editing, session-change and state detection.']),
      release('1.1.0', /^v1\.1\.0$/, ['Introduces public Rich Presence support with activity tracking, configurable buttons and sound options.']),
    ],
  },
  'cheems-translator': { version: ['2.1.7', /SCRIPT_BUILD = "V2\.1\.7"/] },
  'flying-cars-sa': {
    version: ['1.0.1 Alpha', /local script_version = "1\.0\.1 Alpha"/], author: ['Public_Urinal', /developed by: Public_Urinal/],
    history: [
      release('1.0.1 Alpha', '- v1.0.1 alpha - production source cleanup:', ['Streamlines native/input/render calls, persistence and compatibility handling.']),
      release('1.0.0 Alpha', '- v1.0.0 alpha - initial public alpha', ['Introduces car-flight physics, camera guidance, configurable shortcuts and saved scores with landing validation.']),
    ],
  },
  'x-script': { version: ['1', /-- Public Version 1\b/], author: ['GODX7PRIME', /created by "GODX7PRIME"/], notes: ['Header also labels a test version 94.7. Public Version 1 is preserved separately; no release date or redistribution permission is inferred.'] },
};

function buildEnrichment(options = {}) {
  const audit = JSON.parse(fs.readFileSync(options.audit || AUDIT, 'utf8'));
  const localRoot = path.resolve(options.localRoot || LOCAL), items = [], gaps = [];
  const sourcePath = relative => {
    if (typeof relative !== 'string' || relative.startsWith('/') || relative.includes('\\') || relative.split('/').some(part => !part || part === '.' || part === '..')) throw Error(`Invalid source evidence path: ${relative}`);
    const file = path.resolve(localRoot, relative);
    if (!file.startsWith(localRoot + path.sep) || fs.lstatSync(file).isSymbolicLink()) throw Error(`Unsafe source evidence path: ${relative}`);
    return file;
  };
  for (const prior of audit.items) {
    const key = prior.id.replace(/^cherax-lua-/, ''), entry = CURATED[key] || {};
    const candidates = prior.provenance.localPaths;
    const source = candidates.find(file => /^luas\/[^/]+\.lua$/i.test(file.path)) || candidates.find(file => file.collection !== 'archival') || candidates[0];
    const bytes = fs.readFileSync(sourcePath(source.path)), digest = hash(bytes);
    if (digest !== source.sha256) throw Error(`Audited script changed; review it before enrichment: ${source.path}`);
    const compiled = bytes[0] === 0x1b, text = compiled ? '' : bytes.toString('utf8');
    const lines = text.split(/\r?\n/);
    const evidence = [{ kind: 'local-static-source', sourcePath: `../cherax-luas/${source.path}`, sha256: digest, size: bytes.length, encoding: compiled ? 'compiled-lua-uninterpreted' : 'text', basis: 'Read statically; no Lua executed or distributed.' }];
    const result = { id: `menu-${prior.id}`, sourceFilename: path.posix.basename(source.path), changelog: [], sourceEvidence: evidence };
    function locate(needle, basis) {
      const index = lines.findIndex(line => typeof needle === 'string' ? line.includes(needle) : needle.test(line));
      if (index === -1) throw Error(`Missing ${basis} evidence in ${source.path}`);
      evidence.push({ kind: 'local-source-line', sourcePath: `../cherax-luas/${source.path}`, line: index + 1, basis });
      return index;
    }
    for (const property of ['version', 'author']) if (entry[property]) {
      const [value, needle] = entry[property]; locate(needle, `${property} declaration`); result[property] = value;
    }
    for (const change of entry.history || []) {
      locate(change.needle, `Documented changelog for ${change.version}`);
      const release = { version: change.version, changes: change.changes };
      if (change.date) {
        locate(change.dateNeedle, `Date basis for ${change.version}`);
        release.date = change.date; release.dateBasis = change.dateBasis;
      }
      result.changelog.push(release);
    }
    if (entry.notes) evidence.push({ kind: 'review-notes', notes: entry.notes });
    if (key === 'chairhax') {
      const relative = 'luas/Sources/Chairhax-Lua-main/CHANGELOG.md', data = fs.readFileSync(sourcePath(relative));
      if (!/^# Chairhax v3\.0\.5[\s\S]*Added external menus[\s\S]*Improved Spawner[\s\S]*Improved Creator/.test(data.toString('utf8'))) throw Error('Chairhax source changelog changed; review required');
      result.version = '3.0.5';
      result.changelog.push({ version: '3.0.5', changes: ['Adds external menus and improves the spawner and structure creator, with general corrections.'] });
      evidence.push({ kind: 'local-author-changelog', sourcePath: `../cherax-luas/${relative}`, sha256: hash(data), lineStart: 1, lineEnd: 6, basis: 'Source-package changelog; not a version assertion for the separately compiled ChairHax.lua.' });
      evidence.push({ kind: 'public-author-documentation', url: 'https://github.com/SATTY91/Chairhax-Lua/blob/main/CHANGELOG.md', basis: 'Public original repository and CHANGELOG.md verified during this review; no publication date inferred.' });
    }
    if (!result.changelog.length) gaps.push({ id: result.id, reason: compiled ? 'Compiled root script was not interpreted; no verified changelog in the reviewed source.' : 'No explicit versioned changelog selected from the reviewed source; feature lists and code differences are not treated as release notes.' });
    items.push(result);
  }
  return { schemaVersion: 1, items, coverage: {
    existingLuaEntries: audit.items.length, reviewedEntries: items.length,
    entriesWithVersionDeclaration: items.filter(item => item.version).length,
    entriesWithAuthorDeclaration: items.filter(item => item.author).length,
    entriesWithChangelog: items.filter(item => item.changelog.length).length,
    changelogEntries: items.reduce((sum, item) => sum + item.changelog.length, 0),
    datedChangelogEntries: items.reduce((sum, item) => sum + item.changelog.filter(change => change.date).length, 0),
    method: 'Static, hash-bound local source headers and embedded histories, plus identified original author documentation. No execution, downloads, Discord data or private APIs.',
    limitations: ['Local source declarations are not proof of a current public release or runtime compatibility.', 'Dates are included only with an explicit source declaration and its date basis; filesystem timestamps are excluded.', 'Undocumented intermediate versions are not reconstructed from feature lists or diffs.', 'Scripts and implementation code are not published by this metadata-only enrichment.'],
    gaps,
  } };
}

function main(args = process.argv.slice(2)) {
  const result = buildEnrichment(), text = JSON.stringify(result, null, 2) + '\n';
  if (args.includes('--check')) {
    if (!fs.existsSync(OUTPUT) || fs.readFileSync(OUTPUT, 'utf8') !== text) throw Error('Cherax Lua enrichment is missing or stale');
  } else {
    const temporary = `${OUTPUT}.tmp-${process.pid}`;
    fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
    fs.writeFileSync(temporary, text); fs.renameSync(temporary, OUTPUT);
  }
  console.log(JSON.stringify({ ok: true, output: path.relative(ROOT, OUTPUT), ...result.coverage, gaps: result.coverage.gaps.length }));
}
module.exports = { buildEnrichment, main };
if (require.main === module) try { main(); } catch (error) { console.error(error.stack || error.message); process.exitCode = 1; }
