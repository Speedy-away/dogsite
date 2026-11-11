'use strict';

// Code-native previews of exported colors. These are labeled palette previews,
// not captures of the game. Packed values use the host's ImGui ABGR format.
const fs = require('node:fs');
const path = require('node:path');
const escape = value => String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' })[character]);
function color(value, fallback = '#202024') {
  if (typeof value === 'number' && Number.isFinite(value)) {
    const packed = value >>> 0;
    return { fill: `#${[packed & 255, (packed >>> 8) & 255, (packed >>> 16) & 255].map(channel => channel.toString(16).padStart(2, '0')).join('')}`, opacity: ((packed >>> 24) / 255).toFixed(4) };
  }
  if (typeof value === 'string' && /^#[a-f0-9]{6}(?:[a-f0-9]{2})?$/i.test(value)) {
    return { fill: value.slice(0, 7), opacity: value.length === 9 ? (parseInt(value.slice(7), 16) / 255).toFixed(4) : '1' };
  }
  return color(fallback, '#202024');
}
function paint(value, fallback) { const result = color(value, fallback); return `fill="${result.fill}" fill-opacity="${result.opacity}"`; }
function stroke(value, fallback) { const result = color(value, fallback); return `stroke="${result.fill}" stroke-opacity="${result.opacity}"`; }
function mark() {
  const file = path.join(__dirname, '../assets/images/brand/scooby-mark.svg');
  const data = fs.readFileSync(file).toString('base64');
  return `data:image/svg+xml;base64,${data}`;
}
function title(name) { return escape(String(name || 'Scooby').replace(/ ClickUI colors$/i, '').slice(0, 58)); }
function canvas(body, name, game, label) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="720" viewBox="0 0 1000 720" role="img" aria-labelledby="title desc"><title id="title">${escape(name)} — ${escape(label)}</title><desc id="desc">${escape(label)} using source-defined Scooby ${game === 'rdr2' ? 'RDR2' : 'GTA 5'} colors. This is an illustration of the palette.</desc><rect width="1000" height="720" fill="#090909"/><g font-family="Arial,Helvetica,sans-serif"><text x="48" y="42" fill="#eeeeee" font-size="20" font-weight="600">${title(name)}</text><text x="952" y="42" text-anchor="end" fill="#9a9a9a" font-size="13">${escape(label)}</text>${body}</g></svg>`;
}
function renderClickUiPreview({ name, game, document: theme }) {
  if (!theme || typeof theme !== 'object') throw Error('ClickUI preview needs exported color data');
  const accent = theme.textAccent ?? theme.childTitle ?? theme.toggleOn;
  const panel = theme.contentPanelBackground ?? theme.childBackground;
  const rows = ['God Mode', 'No Ragdoll', 'No Fall Damage'];
  let body = `<rect x="48" y="70" width="904" height="596" rx="12" ${paint(theme.windowBackground, '#171717')} ${stroke(theme.windowBorder, '#404040')} stroke-width="2"/>
    <image href="${mark()}" x="65" y="92" width="44" height="50"/>
    <path d="M128 80V650" stroke="#ffffff" stroke-opacity=".08"/>
    <text x="364" y="110" ${paint(accent, '#00c9e9')} font-size="24">General</text><text x="488" y="110" fill="#a0a2aa" font-size="24">Options</text>
    <path d="M363 121H450" ${stroke(accent, '#00c9e9')} stroke-width="2"/>
    <text x="878" y="109" fill="#ededf0" font-size="17">SCOOBY</text>`;
  for (let index = 0; index < 8; index++) body += `<rect x="80" y="${174 + index * 51}" width="15" height="15" rx="${index % 2 ? 2 : 7}" ${paint(index ? '#7c7c8c' : accent, '#00c9e9')}/>`;
  body += `<rect x="148" y="156" width="372" height="181" rx="6" ${paint(panel, '#151515')} ${stroke(theme.childAccentLeft ?? accent, '#00c9e9')} stroke-width="1"/>
    <rect x="543" y="156" width="383" height="181" rx="6" ${paint(panel, '#151515')} ${stroke(theme.childAccentLeft ?? accent, '#00c9e9')} stroke-width="1"/>
    <text x="159" y="150" ${paint(accent, '#00c9e9')} font-size="22">Health &amp; Protection</text><text x="555" y="150" ${paint(accent, '#00c9e9')} font-size="22">Visibility</text>`;
  for (let index = 0; index < rows.length; index++) {
    const y = 192 + index * 45;
    body += `<rect x="161" y="${y - 17}" width="42" height="23" rx="11" ${paint(index ? '#292c3b' : theme.toggleOn ?? accent, '#00c9e9')}/><circle cx="${index ? 172 : 191}" cy="${y - 5}" r="8" fill="#f5f5f7"/><text x="215" y="${y + 1}" fill="#ededf2" font-size="20">${rows[index]}</text>`;
  }
  body += `<rect x="557" y="175" width="42" height="23" rx="11" fill="#292c3b"/><circle cx="568" cy="186" r="8" fill="#f5f5f7"/><text x="612" y="193" fill="#ededf2" font-size="20">Invisible</text>
    <rect x="557" y="220" width="42" height="23" rx="11" fill="#292c3b"/><circle cx="568" cy="231" r="8" fill="#f5f5f7"/><text x="612" y="238" fill="#ededf2" font-size="20">Hide From Radar</text>
    <rect x="190" y="613" width="80" height="33" rx="4" ${paint(theme.tabUnselectedBg, '#15242b')} ${stroke(accent, '#00c9e9')}/><text x="230" y="637" text-anchor="middle" ${paint(accent, '#00c9e9')} font-size="22">Main</text>
    <text x="292" y="637" fill="#8a8b97" font-size="22">Movement</text><text x="434" y="637" fill="#8a8b97" font-size="22">Model</text><text x="531" y="637" fill="#8a8b97" font-size="22">Outfits</text><text x="637" y="637" fill="#8a8b97" font-size="22">View</text>
    <text x="927" y="648" text-anchor="end" ${paint(accent, '#00c9e9')} font-size="13">${game === 'rdr2' ? 'RDR2' : 'GTA 5'}</text>
    <text x="48" y="700" fill="#858585" font-size="13">Source-derived colors · ClickUI palette illustration</text>`;
  return canvas(body, name, game, 'ClickUI color preview');
}
function renderListUiPreview({ name, game, colors = {} }) {
  const accent = colors.accent ?? '#ffffff', text = colors.text ?? '#eeeeee';
  const choices = game === 'rdr2' ? ['Self', 'Players', 'Online', 'Teleport', 'Weapons', 'Horse', 'Spawner', 'World', 'Settings'] : ['Self', 'Players', 'Online', 'Teleport', 'Weapons', 'Vehicle', 'Spawner', 'World', 'Settings'];
  let body = `<rect x="288" y="70" width="424" height="596" rx="10" ${paint(colors.background, '#36383c')}/><path d="M298 70H702Q712 70 712 80V196H288V80Q288 70 298 70" ${paint(colors.header, '#26272b')}/><image href="${mark()}" x="466" y="83" width="68" height="91"/><text x="301" y="220" ${paint(text, '#eeeeee')} font-size="17">Home</text>`;
  for (let index = 0; index < choices.length; index++) {
    const y = 236 + index * 41;
    if (!index) body += `<rect x="288" y="${y}" width="424" height="41" ${paint(colors.selected ?? accent, '#ffffff')}/>`;
    body += `<text x="302" y="${y + 27}" ${paint(index ? text : colors.selectedText ?? '#111111', '#eeeeee')} font-size="20">${choices[index]}</text><text x="691" y="${y + 27}" text-anchor="end" ${paint(index ? text : colors.selectedText ?? '#111111', '#eeeeee')} font-size="25">›</text>`;
  }
  body += `<rect x="288" y="605" width="424" height="61" rx="8" ${paint(colors.header, '#26272b')}/><text x="693" y="643" text-anchor="end" ${paint(text, '#eeeeee')} font-size="17">1 / 9</text><path d="M493 628L500 620L507 628M493 640L500 648L507 640" ${stroke(accent, '#eeeeee')} fill="none" stroke-width="2"/><text x="48" y="700" fill="#858585" font-size="13">Source-derived colors · ListUI palette illustration</text>`;
  return canvas(body, name, game, 'ListUI color preview');
}
module.exports = { color, renderClickUiPreview, renderListUiPreview };
