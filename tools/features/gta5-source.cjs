/* Read-only source catalogue helpers. Never execute or modify the game project. */
const fs = require('node:fs');
const path = require('node:path');
const stripComments = text => text.replace(/"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\/\/[^\n]*|\/\*[\s\S]*?\*\//g, value => value.startsWith('/') ? value.replace(/[^\n]/g, ' ') : value);
function walk(dir) {
  return fs.readdirSync(dir, {withFileTypes:true}).flatMap(entry => {
    const file = path.join(dir, entry.name);
    return entry.isDirectory() ? (/^(build|out|third_party|_backup|\.git)$/i.test(entry.name) ? [] : walk(file)) : /\.(cpp|hpp|inl)$/.test(file) ? [file] : [];
  });
}
function argument(text, start) {
  let depth = 1, quoted = false;
  for (let i = start; i < text.length; i++) {
    if (quoted && text[i] === '\\') { i++; continue; }
    if (text[i] === '"') quoted = !quoted;
    if (quoted) continue;
    if (text[i] === '(') depth++;
    if (text[i] === ')' && --depth === 0) return text.slice(start, i);
  }
  throw new Error('Unbalanced source expression');
}
const commandIds = text => [...text.matchAll(/std::make_shared<\w*CommandItem>\(\s*"([\w]+)"_J/g)].map(m => m[1]);
function accessFromSource(sources, accessText, protectionText = '') {
  accessText = stripComments(accessText);
  const array = (name, text = accessText) => {
    const match = text.match(new RegExp('\\b' + name + '\\s*(?:\\[\\s*\\]\\s*)?(?:=\\s*)?\\{([\\s\\S]*?)\\};'));
    return new Set([...(match?.[1] || '').matchAll(/Joaat\("([^"]+)"\)|"([^"]+)"_J/g)].map(m => m[1] || m[2]));
  };
  const premium = array('kPremiumCommands');
  const free = array('kFreePlayerSupportCommands');
  // Newer builds moved the Free overrides into a function-local array.
  const explicitFree = accessText.match(/\bIsExplicitlyFreeCommand\([^)]*\)\s*\{([\s\S]*?)return\s/);
  if (explicitFree) for (const id of array('commands', explicitFree[1])) free.add(id);
  for (const id of array('commands', stripComments(protectionText))) premium.add(id);
  const editions = new Map();
  for (const {text} of sources) {
    const children = new Map();
    for (const match of text.matchAll(/(\w+)->(?:AddItem|Add)\(/g)) {
      const expression = argument(text, match.index + match[0].length);
      if (!children.has(match[1])) children.set(match[1], []);
      children.get(match[1]).push(expression);
    }
    // Wrappers can receive an item variable instead of an inline constructor.
    for (const match of text.matchAll(/\b(\w+)\s*=\s*(std::make_shared<\w+>\()/g)) {
      const start = match.index + match[0].length;
      if (!children.has(match[1])) children.set(match[1], []);
      children.get(match[1]).push(match[2] + argument(text, start) + ')');
    }
    function resolve(expression, visited = new Set()) {
      const ids = new Set(commandIds(expression));
      for (const [name, expressions] of children) {
        if (!visited.has(name) && new RegExp('\\b' + name + '\\b').test(expression)) {
          visited.add(name);
          for (const child of expressions) for (const id of resolve(child, visited)) ids.add(id);
        }
      }
      return ids;
    }
    for (const match of text.matchAll(/PremiumItem::Only\(/g)) {
      for (const id of resolve(argument(text, match.index + match[0].length))) premium.add(id);
    }
    for (const match of text.matchAll(/EditionItem::(Enhanced|Legacy)Only\(/g)) {
      for (const id of resolve(argument(text, match.index + match[0].length))) {
        if (!editions.has(id)) editions.set(id, new Set());
        editions.get(id).add(match[1]);
      }
    }
  }
  for (const id of free) premium.delete(id);
  return {premium, free, editions};
}
function readSource(root) {
  const sources = walk(path.join(root, 'src')).map(file => ({file, text:stripComments(fs.readFileSync(file,'utf8'))}));
  const accessText = fs.readFileSync(path.join(root,'src/core/frontend/PremiumAccess.cpp'),'utf8');
  return parseSources(sources, accessText);
}
function parseSources(sources, accessText) {
  sources = sources.map(source => ({...source, text:stripComments(source.text)
    .replace(/XOR\(("(?:\\.|[^"\\])*")\)/g, '$1')
    .replace(/Command::Intern\(("(?:\\.|[^"\\])*")\)/g, '$1')
    // This source macro constructs the same command through a deferred factory.
    .replace(/\bSCOOBY_DEFERRED_COMMAND\(\s*([\w:]+(?:<[^\n;{}]+?>)?)\s*,\s*(\w+)\s*,/g, '$1 $2{')
  }));
  const labels = {}, locations = new Map();
  const commandTypes = new Set(['Command']);
  const parents = sources.flatMap(({text}) => [
    ...text.matchAll(/(?:class|struct)\s+(\w+)(?:\s+final)?\s*:\s*(?:(?:public|private|protected)\s+)?([\w:]+)/g),
    ...text.matchAll(/\busing\s+(\w+)\s*=\s*([\w:]+)/g)
  ].map(m => [m[1],m[2].split('::').pop()]));
  let changed = true;
  while (changed) {
    changed = false;
    for (const [child,parent] of parents) if (commandTypes.has(parent) && !commandTypes.has(child)) { commandTypes.add(child); changed = true; }
  }
  // Literal command registrations: both aggregate construction and base constructors.
  const registration = /\b(?!(?:new|return)\b)([\w:]+(?:<[^;{}\n]+>)?)\s*(?:\s+\w+\s*)?(?:=\s*)?[({]\s*"([a-zA-Z0-9_]+)"\s*,\s*"((?:\\.|[^"\\])*)"\s*,\s*"((?:\\.|[^"\\])*)"/g;
  const decode = s => s.replace(/\\n/g,' ').replace(/\\t/g,' ').replace(/\\"/g,'"').replace(/\\\\/g,'\\').trim();
  for (const {file,text} of sources) for (const match of text.matchAll(registration)) {
    const [,type,id,label,desc] = match;
    if (!label || !commandTypes.has(type.split('<')[0].split('::').pop())) continue;
    labels['command.'+id+'.label'] = decode(label);
    labels['command.'+id+'.description'] = decode(desc);
    locations.set(id,file);
  }
  const menus = sources.filter(s => s.file.replace(/\\/g,'/').includes('/frontend/submenus/'));
  const add = (id,label,desc,file) => {
    labels['command.'+id+'.label'] = decode(label);
    labels['command.'+id+'.description'] = decode(desc);
    locations.set(id,file);
  };
  for (const {file,text} of sources) {
    for (const m of text.matchAll(/Command\s*=\s*"(\w+)";[\s\S]{0,100}?Title\s*=\s*"([^"]+)";[\s\S]{0,100}?Description\s*=\s*"([^"]+)";/g)) add(m[1],m[2],m[3],file);
    for (const m of text.matchAll(/(\w+)::(kCommandName|kRuntimeCommand)\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"/g)) {
      const header = sources.find(s => s.file === file.replace(/\.cpp$/,'.hpp'));
      const id = header?.text.match(new RegExp(m[2]+'\\s*=\\s*"(\\w+)"'));
      if (id) add(id[1],m[3],m[4],file);
    }
    for (const m of text.matchAll(/\b(\w+)\s+\w+\s*\{\s*"(\w+)"\s*,\s*"([^"]+)"\s*[,})]/g)) {
      if (commandTypes.has(m[1]) && !locations.has(m[2])) add(m[2],m[3],'',file);
    }
    for (const m of text.matchAll(/\}\s+\w+\s*\{\s*"(\w+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"/g)) {
      const precedingClass = [...text.slice(0,m.index).matchAll(/class\s+(\w+)/g)].pop()?.[1];
      if (commandTypes.has(precedingClass)) add(m[1],m[2],m[3],file);
    }
    if (file.endsWith('GameBrowser.cpp')) {
      const protocol = sources.find(s => s.file.endsWith('BrowserProtocol.hpp'));
      const games = [...protocol.text.matchAll(/Game\{"([^"]+)"/g)].map(m => m[1]);
      for (const m of text.matchAll(/\("(browser\w+)", Games\[(\d+)\]\)/g)) add(m[1],games[Number(m[2])],'Open this game in Game Browser.',file);
    }
  }
  // PlayerCommand creates a matching command with an "all" suffix at runtime.
  for (const {file,text} of menus) for (const id of commandIds(text)) {
    if (!locations.has(id) && id.endsWith('all') && locations.has(id.slice(0,-3))) {
      const base = id.slice(0,-3);
      add(id, labels['command.'+base+'.label']+' (All players)', 'Applies to all selected players. '+labels['command.'+base+'.description'], locations.get(base));
    }
  }
  // A menu label is not a registration: old UI references can outlive the
  // implementation. Keep them out of the published catalogue.
  const unresolved = [...new Set(menus.flatMap(({text}) => commandIds(text)))].filter(id => !locations.has(id));
  const protectionText = sources.find(s => s.file.endsWith('ProtectionPremium.hpp'))?.text || '';
  return {labels,locations,sources,menus,unresolved,...accessFromSource(menus,accessText,protectionText)};
}
module.exports = {readSource, parseSources, stripComments, accessFromSource};
