'use strict';

// Read the static DiscordChatExporter markup as data. Do not load its scripts
// or treat avatars, emoji, link previews, or player posters as attachments.
const path = require('node:path');

function decode(value) {
  const entities = { amp: '&', quot: '"', apos: "'", lt: '<', gt: '>', nbsp: ' ' };
  return value.replace(/&(#x[\da-f]+|#\d+|amp|quot|apos|lt|gt|nbsp);/gi, (raw, key) => {
    if (key[0] !== '#') return entities[key.toLowerCase()] || raw;
    const hex = key[1].toLowerCase() === 'x';
    const code = Number.parseInt(key.slice(hex ? 2 : 1), hex ? 16 : 10);
    return code <= 0x10ffff ? String.fromCodePoint(code) : raw;
  });
}

function attribute(tag, key) {
  const match = tag.match(new RegExp(`(?:^|\\s)${key}=(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, 'i'));
  return decode(match?.[1] ?? match?.[2] ?? match?.[3] ?? '');
}

function plain(fragment) {
  return decode(fragment.replace(/<br\s*\/?>|<\/(?:p|li|h[1-6])>/gi, '\n').replace(/<[^>]*>/g, '')).trim();
}

function dateFromSnowflake(id) {
  return new Date(Number((BigInt(id) >> 22n) + 1420070400000n)).toISOString();
}

function attachmentsOf(fragment) {
  const attachments = [];
  const append = (raw, name) => {
    if (!raw) return;
    const url = /^https?:\/\//i.test(raw) ? raw : decodeURIComponent(raw);
    const fileName = name || path.posix.basename(url.split(/[?#]/, 1)[0]).replace(/-[a-f0-9]{16}(?=\.[^.]+$)/i, '');
    attachments.push({ fileName, url });
  };
  for (const match of fragment.matchAll(/<div class=chatlog__attachment-generic-name>\s*<a\b([^>]*)>([\s\S]*?)<\/a>/gi)) {
    append(attribute(match[1], 'href'), plain(match[2]));
  }
  for (const match of fragment.matchAll(/<(?:img|source|audio|video)\b[^>]*>/gi)) {
    const tag = match[0], classes = attribute(tag, 'class'), title = attribute(tag, 'title');
    const name = title.match(/^(?:Image|Video|Audio|Attachment): (.*?)(?: \([\d.,]+ [KMG]?B\))?$/i)?.[1];
    if (!classes.split(' ').includes('chatlog__attachment-media') && !(name && /^<source\b/i.test(tag))) continue;
    append(attribute(tag, 'src'), name);
  }
  return attachments;
}

function readHtmlExport(html, file, guildId) {
  const filename = path.basename(file);
  const header = filename.match(/^RedM Hub - (.+?) - (.+?) \[(\d{15,22})\](?:.*)\.html$/i);
  const title = html.match(/<title>([^<]*)<\/title>/i)?.[1];
  if (!header || !title || decode(title).trim() !== `RedM Hub - ${header[2]}`) {
    throw Error('The DiscordChatExporter HTML title and channel filename do not match.');
  }
  const matches = [...html.matchAll(/<div id=chatlog__message-container-(\d+) class=chatlog__message-container data-message-id=\1>/g)];
  const messages = [];
  let author;
  for (let index = 0; index < matches.length; index++) {
    const match = matches[index], id = match[1];
    const fragment = html.slice(match.index + match[0].length, matches[index + 1]?.index ?? html.length);
    const authorMatch = fragment.match(/<span class=chatlog__author\b([^>]*)>([^<]*)<\/span>/);
    if (authorMatch) author = { name: plain(authorMatch[2]), id: attribute(authorMatch[1], 'data-user-id') };
    const body = fragment.match(/<div class="chatlog__content chatlog__markdown">([\s\S]*?)<\/div>/)?.[1] || '';
    const embeds = [];
    const embedStarts = [...fragment.matchAll(/<div class=chatlog__embed>/g)];
    for (let embedIndex = 0; embedIndex < embedStarts.length; embedIndex++) {
      const embed = fragment.slice(embedStarts[embedIndex].index, embedStarts[embedIndex + 1]?.index);
      const titleBlock = embed.match(/<div class=chatlog__embed-title>([\s\S]*?)<\/div>/)?.[1] || '';
      const description = embed.match(/<div class=chatlog__embed-description>([\s\S]*?)<\/div>/)?.[1] || '';
      const titleLink = titleBlock.match(/<a\b[^>]*>/)?.[0] || '';
      const url = attribute(titleLink, 'href');
      const images = [...embed.matchAll(/<img class=chatlog__embed-image\s[^>]*>/g)].map(([tag]) => ({
        url: decodeURIComponent(attribute(tag, 'src')),
      })).filter(asset => asset.url);
      embeds.push({ title: plain(titleBlock), description: plain(description), url, images });
    }
    const links = [...body.matchAll(/<a\b([^>]*)>/gi)].map(link => attribute(link[1], 'href')).filter(url => /^https:\/\//i.test(url));
    const bodyText = plain(body);
    const content = [bodyText, ...embeds.filter(embed => !embed.url).flatMap(embed => [embed.title, embed.description]), ...links.filter(url => !bodyText.includes(url))].filter(Boolean).join('\n');
    messages.push({ id, timestamp: dateFromSnowflake(id), author, content, attachments: attachmentsOf(fragment), embeds });
  }
  if (!messages.length) throw Error('No DiscordChatExporter HTML message rows found.');
  return {
    guild: { id: guildId, name: 'RedM Hub' },
    channel: { id: header[3], name: header[2], category: header[1] },
    messages,
    messageCount: messages.length,
  };
}

module.exports = { readHtmlExport };
