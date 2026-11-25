/* Publish a watch page only after verifying its video and original upload date. */
const fs = require('node:fs');
const path = require('node:path');
const { pageUrl } = require('./seo-structured');
const { writeIfChanged } = require('./generated-file.cjs');

const videos = [
  {
    slug: 'gta5-free-showcase',
    id: 'zxDjiS_YC8w',
    title: 'Scooby Free GTA 5 Mod Menu Showcase',
    description: 'Vanish showcases the Scooby Free GTA 5 menu, with a look at outfits, vehicles and other features on PC.',
    creator: 'Vanish',
    uploadDate: '2026-06-01',
    keywords: 'Scooby Free, GTA 5 PC showcase, GTA V outfits, GTA 5 vehicle customization',
  },
  {
    slug: 'gta5-legacy-enhanced-showcase',
    id: '2Aa7gGo-l_o',
    title: 'Scooby GTA 5 Legacy and Enhanced Showcase',
    description: 'Retro - Jason walks through Scooby’s GTA 5 interface, outfit options and vehicle features for Legacy and Enhanced.',
    creator: 'Retro - Jason',
    uploadDate: '2026-08-15',
    keywords: 'Scooby GTA 5 video, GTA V Legacy showcase, GTA V Enhanced showcase, GTA Online PC',
  },
].map(video => ({
  ...video,
  file: `videos/${video.slug}/index.html`,
  player: `https://www.youtube.com/embed/${video.id}`,
  watch: `https://www.youtube.com/watch?v=${video.id}`,
  thumbnail: `https://i.ytimg.com/vi/${video.id}/hqdefault.jpg`,
}));

const escapeHtml = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');

function render(video) {
  const canonical = pageUrl(video.file);
  const data = {
    '@context': 'https://schema.org',
    '@type': 'VideoObject',
    '@id': canonical + '#video',
    name: video.title,
    description: video.description,
    uploadDate: video.uploadDate,
    thumbnailUrl: video.thumbnail,
    embedUrl: video.player,
    author: { '@type': 'Person', name: video.creator },
    mainEntityOfPage: { '@id': canonical + '#webpage' },
  };
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(video.title)}</title>
<link rel="stylesheet" href="/assets/css/site-directory.css">
<style>
.watch-page { max-width: 900px; padding-block: 28px 48px; }
.watch-frame { display: block; width: 100%; aspect-ratio: 16 / 9; border: 0; background: #000; }
.watch-page p a { color: var(--accent); text-decoration: underline; }
.watch-page .breadcrumbs { margin-top: 0; }
</style>
<script type="application/ld+json">${JSON.stringify(data).replace(/</g, '\\u003c')}</script>
</head>
<body>
<main class="watch-page">
<nav class="breadcrumbs" aria-label="Breadcrumb"><a href="/">Home</a> / <a href="/videos/">Videos</a></nav>
<h1>${escapeHtml(video.title)}</h1>
<iframe class="watch-frame" src="${video.player}" title="${escapeHtml(video.title)}" allow="encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>
<p>${escapeHtml(video.description)}</p>
<p>By ${escapeHtml(video.creator)} · <time datetime="${video.uploadDate}">${video.uploadDate}</time> · <a href="${video.watch}">Watch on YouTube</a></p>
<p><a href="/products/gta5/">Compare GTA 5 editions</a> · <a href="/features-list/gta-features/">Browse current GTA 5 features</a> · <a href="/videos/">All videos</a></p>
</main>
</body>
</html>
`;
}

function build() {
  const { applyMetadata } = require('./seo-metadata');
  for (const video of videos) {
    const target = path.join(__dirname, '..', video.file);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    writeIfChanged(target, applyMetadata(video.file, render(video)));
  }
}

module.exports = { videos, build };
if (require.main === module) build();
