'use strict';

const fs = require('node:fs');
const path = require('node:path');

const repository = 'https://github.com/walteryo1337/Nenyoo-Resources';
const raw = 'https://raw.githubusercontent.com/walteryo1337/Nenyoo-Resources';
const languages = {
  CN: 'Chinese', DE: 'German', EN: 'English', ES: 'Spanish', FR: 'French', HI: 'Hindi', IT: 'Italian',
  JP: 'Japanese', KR: 'Korean', PL: 'Polish', PT: 'Portuguese', RU: 'Russian', TH: 'Thai', TR: 'Turkish'
};
const encodePath = value => value.split('/').map(encodeURIComponent).join('/');
const slug = value => value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const imageExtension = /\.(?:avif|bmp|gif|jpe?g|png|webp)$/i;
const themeStyles = ['Stand', 'Cherax', '2Take1', 'X-Force', 'Impulse', 'Ozark', 'Menyoo', 'Paragon'];

// Only the reviewed blob is listed when the source snapshot is refreshed.
const standaloneScripts = [
  ['Chaos Playground', '8e3a0e4f72204c9926fc91ee7f16303f292a5f94', 'A local-player sandbox with movement effects and a color-changing trail.'],
  ['Human Cannonball', '5c4493aa68845c4feb5d2ecb80985f4b5dbc51f6', 'A launch-and-landing minigame for your own character.']
];
const builtInScripts = {
  GTAV: [
    ['cinematic_bars', '390a4de4ffba522f2875bc4d2bdd43d63d330f6c', 'Cinematic Bars', 'Draws letterbox bars over the game view.'],
    ['clock', '2535ec8112f3dbae06866293f8d7126a723ec13e', 'Clock', 'Draws a clock on the game HUD.'],
    ['composition_grid', '7514aa9e06304b48150b21ce77d0630e7ec90653', 'Composition Grid', 'Draws a framing grid over the game view.']
  ],
  RDR2: [
    ['cinematic_frame', '7110d89dedec8193f4dd9e65f2f8d7158a25bf61', 'Cinematic Frame', 'Draws a cinematic frame over the game view.'],
    ['compass', '85f8406b0ec02af05e49fb0bb5b88ad59081cb62', 'Compass', 'Draws a compass strip with heading markers.'],
    ['mount_vitals_hud', 'bb24cfa8991ce4dbcde2181f30f949f83410c8e4', 'Mount Vitals HUD', 'Displays mount health and stamina on the HUD.'],
    ['stopwatch', 'd77989587005d83478738a68105ffbe4168dd33b', 'Stopwatch', 'Displays the runtime stopwatch on the HUD.'],
    ['trip_meter', '7e5e89de0f3d69a46553b2b65426b3be59cc8a09', 'Trip Meter', 'Displays travel distance, elapsed time and speed.'],
    ['weather_monitor', 'a6e80e2d8e9e5484ee3cdef34bf5251a77255a54', 'Weather Monitor HUD', 'Displays the current in-game weather.'],
    ['world_clock', '9b79528ae3bde6c29d112974b34c107fb50c1654', 'World Clock', 'Displays the in-game time of day.']
  ]
};

function buildCatalog({ commit, tree, truncated }, { themes }) {
  if (!/^[a-f0-9]{40}$/.test(commit) || truncated || !Array.isArray(tree) || !Array.isArray(themes)) {
    throw Error('A complete GitHub tree and theme index from a pinned commit are required');
  }
  const blobs = new Map(tree.filter(file => file.type === 'blob').map(file => [file.path, file]));
  const rawUrl = file => `${raw}/${commit}/${encodePath(file)}`;
  const githubUrl = (view, file) => `${repository}/${view}/${commit}/${encodePath(file)}`;
  const items = [];
  const ids = new Set();
  function add(game, category, key, name, details) {
    const id = `${game}-nenyoo-${category}-${slug(key)}`;
    if (ids.has(id)) throw Error(`Duplicate Nenyoo resource ID ${id}`);
    ids.add(id);
    items.push({ id, game, category, name, source: 'Nenyoo Resources', sourceMenu: 'nenyoo', supportedMenus: ['nenyoo'], ...details });
  }

  for (const theme of themes) {
    if (!theme.id || /[\\/]/.test(theme.id) || ['.', '..'].includes(theme.id)) throw Error(`Invalid theme folder ${theme.id}`);
    const folder = `GTAV/Themes/${theme.id}`;
    if (!blobs.has(`${folder}/${theme.entry}`)) throw Error(`Missing entry for ${folder}`);
    const imagePaths = [...new Set([theme.preview, ...theme.files.map(file => file.path)])].filter(file =>
      typeof file === 'string' && imageExtension.test(file) && !file.includes('\\') &&
      file.split('/').every(part => part && part !== '.' && part !== '..') && blobs.has(`${folder}/${file}`));
    const imageBaseUrl = `${rawUrl(folder)}/`;
    const style = themeStyles.find(value => theme.name === value || theme.name.startsWith(`${value} `));
    add('gta5', 'themes', theme.id, theme.name, {
      status: 'author-hosted', sourceUrl: githubUrl('tree', folder), files: [],
      format: 'Nenyoo Lua theme', requirementLabel: 'Nenyoo theme format',
      description: 'Get the complete theme folder from Nenyoo, including its artwork and supporting files.',
      ...(style ? { style } : {}),
      ...(imagePaths.length ? {
        imageBaseUrl, imagePaths, preview: imageBaseUrl + encodePath(imagePaths[0]),
        previewVerified: true, previewCaption: 'Original Nenyoo preview'
      } : {})
    });
  }

  for (const [name, sha, description] of standaloneScripts) {
    const folder = `GTAV/Scripts/${name}`;
    const filename = `${name}.lua`;
    const file = `${folder}/${filename}`;
    const blob = blobs.get(file);
    if (blob?.sha !== sha) continue;
    const preview = `${folder}/preview.png`;
    add('gta5', 'lua', name, name, {
      status: 'download', downloadStatus: 'available', sourceUrl: githubUrl('blob', file), description,
      format: 'Nenyoo Lua user script', requirementLabel: 'Requires the Nenyoo GTA V Lua API',
      files: [{ url: rawUrl(file), name: filename, size: blob.size, downloadMethod: 'direct' }],
      ...(blobs.has(preview) ? { preview: rawUrl(preview), previewVerified: true } : {})
    });
  }

  for (const [directory, scripts] of Object.entries(builtInScripts)) {
    const game = directory === 'GTAV' ? 'gta5' : 'rdr2';
    for (const [id, sha, name, description] of scripts) {
      const file = `${directory}/Lua/ui/features/${id}.lua`;
      if (blobs.get(file)?.sha !== sha) continue;
      add(game, 'lua', id, name, {
        status: 'author-hosted', sourceUrl: githubUrl('blob', file), description,
        format: 'Built-in Nenyoo Lua module', builtInLua: true, sourceFilename: `${id}.lua`, files: []
      });
    }
  }

  const categoryRules = {
    Translations: { id: 'languages', extensions: /\.json$/i, description: 'In-game translation for Nenyoo.' },
    Fonts: { id: 'fonts', extensions: /\.[ot]tf$/i, description: 'Typeface bundled with Nenyoo.' },
    Textures: { id: 'textures', extensions: /\.(?:png|gif)$/i, description: 'Interface artwork bundled with Nenyoo.' },
    Emotes: { id: 'emotes', extensions: /\.mp3$/i, description: 'Audio asset for a Nenyoo emote.' }
  };
  const loader = { id: 'loader-translations', extensions: /\.json$/i, description: 'Translation for the shared Nenyoo launcher.' };
  for (const file of blobs.values()) {
    const [directory, family, ...relative] = file.path.split('/');
    const rule = directory === 'Loader' && family === 'Translations' ? loader :
      ['GTAV', 'RDR2'].includes(directory) ? categoryRules[family] : undefined;
    if (!rule || !rule.extensions.test(file.path)) continue;
    const filename = relative.at(-1);
    const label = path.posix.parse(filename).name;
    const language = languages[label.match(/^lang_([a-z]+)$/i)?.[1].toUpperCase()];
    const games = directory === 'Loader' ? ['gta5', 'rdr2'] : [directory === 'GTAV' ? 'gta5' : 'rdr2'];
    for (const game of games) {
      add(game, rule.id, relative.join('/'), language || label, {
        status: 'download', sourceUrl: githubUrl('blob', file.path), description: rule.description,
        files: [{ url: rawUrl(file.path), name: filename, size: file.size, downloadMethod: 'direct' }],
        ...(family === 'Textures' ? { preview: rawUrl(file.path), previewVerified: true } : {})
      });
    }
  }
  return { version: 1, repository, commit, items };
}

if (require.main === module) {
  const [, , treeFile, themesFile] = process.argv;
  if (!treeFile || !themesFile) throw Error('Usage: node tools/build-nenyoo-resources.cjs <GitHub tree with commit> <GTAV/Themes/index.json>');
  const read = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
  const catalog = buildCatalog(read(treeFile), read(themesFile));
  const output = path.join(__dirname, '../community/data/nenyoo.json');
  const previous = fs.existsSync(output) ? read(output) : {};
  const previousDates = new Map((previous.items || []).map(item => [item.id, item.addedAt]));
  const addedAt = new Date().toISOString();
  for (const item of catalog.items) item.addedAt = previousDates.get(item.id) || addedAt;
  fs.writeFileSync(output, JSON.stringify(catalog, null, 2) + '\n');
  console.log(`Indexed ${catalog.items.length} Nenyoo resources from ${catalog.commit}`);
}

module.exports = { buildCatalog };
