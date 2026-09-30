/* Keep static headers and browser icons aligned with the supplied Scooby mark. */
const fs = require('fs'), path = require('path');
const { BRAND_LOGO } = require('./social-logos');
const STYLE = '/assets/css/site-brand.css';
const EMBLEM = '<span class="scooby-emblem" aria-hidden="true"></span>';
function applyBranding(html) {
  // Redirect stubs have no visible site header.
  if (!/<body\b/i.test(html) || /<meta\b[^>]*http-equiv=["']refresh["']/i.test(html)) return html;
  let result = html.replace(/(["'])(?:\.\.\/|\/)?(?:assets\/images\/logo\.png|logo\.png)\1/g, (_, quote) => quote + BRAND_LOGO + quote)
    .replace(/https:\/\/scoobymenu\.cc\/(?:assets\/images\/)?logo\.png/g, 'https://scoobymenu.cc' + BRAND_LOGO);
  result = result.replace(/<a\b([^>]*)>([\s\S]*?)<\/a>/gi, (whole, attrs, content) => {
    const match = attrs.match(/\bclass=(["'])(.*?)\1/i);
    if (!match || !/(?:^|\s)(?:brand|wiki-brand|portal-logo|footer-brand)(?:\s|$)/.test(match[2]) || !/scooby/i.test(content)) return whole;
    if (!match[2].split(/\s+/).includes('scooby-brand')) attrs = attrs.replace(match[0], `class=${match[1]}${match[2]} scooby-brand${match[1]}`);
    if (!content.includes('class="scooby-emblem"')) {
      const old = /<img\b[^>]*src=["'][^"']*\/brand\/scooby-logo\.png["'][^>]*>/i;
      content = old.test(content) ? content.replace(old, EMBLEM) : EMBLEM + content;
    }
    return '<a' + attrs + '>' + content + '</a>';
  });
  // One canonical PNG icon, with the MIME type matching the actual file.
  let icon = false;
  result = result.replace(/<link\b[^>]*>/gi, tag => {
    if (!/\brel=["'](?:shortcut\s+)?icon["']/i.test(tag)) return tag;
    if (icon) return '';
    icon = true;
    return `<link rel="icon" type="image/png" href="${BRAND_LOGO}">`;
  });
  const nl = result.includes('\r\n') ? '\r\n' : '\n';
  if (!icon) result = result.replace(/<\/head>/i, `<link rel="icon" type="image/png" href="${BRAND_LOGO}">${nl}</head>`);
  result = result.replace(/<link\b[^>]*href=["']\/assets\/css\/site-brand\.css["'][^>]*>(?:\r?\n)?/gi, '');
  result = result.replace(/(<title\b[^>]*>[\s\S]*?<\/title>)(?:\r?\n)?/i, (_, title) => title + nl + '<link rel="stylesheet" href="' + STYLE + '">' + nl);
  return result;
}
module.exports = { applyBranding };
if (require.main === module) {
  const { walk } = require('./seo-metadata');
  let changed = 0;
  for (const file of walk(path.resolve(__dirname, '..'))) {
    const before = fs.readFileSync(file, 'utf8'), after = applyBranding(before);
    if (before === after) continue;
    changed++;
    if (process.argv.includes('--apply')) fs.writeFileSync(file, after);
    else console.log('Stale branding: ' + path.relative(process.cwd(), file));
  }
  console.log(`${changed} ${process.argv.includes('--apply') ? 'updated' : 'stale'} site branding files.`);
  if (changed && !process.argv.includes('--apply')) process.exitCode = 1;
}
