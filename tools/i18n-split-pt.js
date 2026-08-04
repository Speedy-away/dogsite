/*
 * Splits Portuguese into pt (European) and pt-br (Brazilian).
 *
 * The existing pt.js is Brazilian ("Baixar", "equipe", "conosco"), so it becomes
 * pt-br.js verbatim, and pt.js is converted to European Portuguese with the
 * lexical and grammatical rules below.
 *
 *   node split-pt.js            # dry run, prints every change
 *   node split-pt.js --apply
 */
const fs = require('fs'), path = require('path');
const ROOT = process.argv.find(a => a.startsWith('--root=')) ?
             process.argv.find(a => a.startsWith('--root=')).slice(7) :
             'C:/Users/whatw/OneDrive/Documents/GitHub/dogsite';
const APPLY = process.argv.includes('--apply');
const SRC = path.join(ROOT, 'languages', 'pt.js');

// Brazilian -> European Portuguese. Order matters; longest patterns first.
// Only high-confidence divergences - anything ambiguous is deliberately absent.
const RULES = [
  // gerund: "está fazendo" -> "está a fazer"
  [/\b(está|estão|estou|estamos|estiver|estava|estavam)\s+(fazendo|usando|jogando|rodando|carregando|executando|funcionando|aguardando|tentando|baixando|instalando|procurando|esperando|abrindo|entrando|jogando)\b/g,
    (m, aux, ger) => {
      const inf = { fazendo:'fazer', usando:'usar', jogando:'jogar', rodando:'correr',
        carregando:'carregar', executando:'executar', funcionando:'funcionar',
        aguardando:'aguardar', tentando:'tentar', baixando:'transferir',
        instalando:'instalar', procurando:'procurar', esperando:'esperar',
        abrindo:'abrir', entrando:'entrar' }[ger];
      return aux + ' a ' + inf;
    }],
  // lexical
  [/\bBaixar\b/g, 'Transferir'], [/\bbaixar\b/g, 'transferir'],
  [/\bBaixe\b/g, 'Transfira'],   [/\bbaixe\b/g, 'transfira'],
  [/\bBaixado\b/g, 'Transferido'], [/\bbaixado\b/g, 'transferido'],
  [/\bequipe\b/g, 'equipa'], [/\bEquipe\b/g, 'Equipa'],
  [/\bTela\b/g, 'Ecrã'], [/\btela\b/g, 'ecrã'],
  [/\bArquivos\b/g, 'Ficheiros'], [/\barquivos\b/g, 'ficheiros'],
  [/\bArquivo\b/g, 'Ficheiro'], [/\barquivo\b/g, 'ficheiro'],
  [/\bUsuários\b/g, 'Utilizadores'], [/\busuários\b/g, 'utilizadores'],
  [/\bUsuário\b/g, 'Utilizador'], [/\busuário\b/g, 'utilizador'],
  [/\bSenhas\b/g, 'Palavras-passe'], [/\bsenhas\b/g, 'palavras-passe'],
  [/\bSenha\b/g, 'Palavra-passe'], [/\bsenha\b/g, 'palavra-passe'],
  [/\bCadastro\b/g, 'Registo'], [/\bcadastro\b/g, 'registo'],
  [/\bRegistro\b/g, 'Registo'], [/\bregistro\b/g, 'registo'],
  [/\bAplicativos\b/g, 'Aplicações'], [/\baplicativos\b/g, 'aplicações'],
  [/\bAplicativo\b/g, 'Aplicação'], [/\baplicativo\b/g, 'aplicação'],
  [/\bCelular\b/g, 'Telemóvel'], [/\bcelular\b/g, 'telemóvel'],
  [/\bMouse\b/g, 'Rato'], [/\bmouse\b/g, 'rato'],
  [/\bContato\b/g, 'Contacto'], [/\bcontato\b/g, 'contacto'],
  [/\bconosco\b/g, 'connosco'], [/\bConosco\b/g, 'Connosco'],
  [/\bFato\b/g, 'Facto'], [/\bfato\b/g, 'facto'],
  // contractions Brazilians spell out
  [/\bem um\b/g, 'num'], [/\bEm um\b/g, 'Num'],
  [/\bem uma\b/g, 'numa'], [/\bEm uma\b/g, 'Numa'],
  // orthography that did not merge under AO90
  [/econômic/g, 'económic'], [/Econômic/g, 'Económic'],
  [/eletrônic/g, 'eletrónic'], [/Eletrônic/g, 'Eletrónic'],
  [/gênero/g, 'género'], [/Gênero/g, 'Género'],
];

const src = fs.readFileSync(SRC, 'utf8');

// ---- pt-br.js: the current Brazilian text, re-registered under the new code --
const br = src
  .replace(/^\/\*[\s\S]*?\*\//,
`/* pt-br - Brazilian Portuguese.
   Keys are the exact English source strings. See languages/ADDING-A-LANGUAGE.md.
   This is the original pt.js: it was always Brazilian. European Portuguese now
   lives in pt.js. */`)
  .replace(/register\('pt'/g, "register('pt-br'")
  .replace(/push\(\['pt'/g, "push(['pt-br'");

if (!/register\('pt-br'/.test(br) || !/push\(\['pt-br'/.test(br)) {
  throw new Error('pt-br registration rewrite failed');
}

// ---- pt.js: European conversion, values only ---------------------------------
const hits = new Map();
let changed = 0;
// Only touch the value side of `"key": "value",` lines.
const euro = src.replace(/^(\s*"(?:[^"\\]|\\.)*":\s*)("(?:[^"\\]|\\.)*")(,?)$/gm,
  (line, head, valueLit, tail) => {
    let v;
    try { v = JSON.parse(valueLit); } catch (e) { return line; }
    const before = v;
    for (const [re, to] of RULES) v = v.replace(re, to);
    if (v !== before) {
      changed++;
      for (const [re] of RULES) {
        const m = before.match(re);
        if (m) hits.set(re.source, (hits.get(re.source) || 0) + m.length);
      }
    }
    return head + JSON.stringify(v) + tail;
  }).replace(/^\/\*[\s\S]*?\*\//,
`/* pt - European Portuguese.
   Keys are the exact English source strings. See languages/ADDING-A-LANGUAGE.md.
   Derived from the Brazilian dictionary (now pt-br.js) by a lexical and
   grammatical pass: transferir/ficheiro/utilizador/ecrã, "está a fazer" for the
   gerund, num/numa contractions. Not an independent human translation - if a
   native speaker reviews it, this file is the one to correct. */`);

console.log('values rewritten:', changed, 'of', (src.match(/^\s*"(?:[^"\\]|\\.)*":/gm) || []).length);
console.log('\nrules that fired:');
[...hits.entries()].sort((a, b) => b[1] - a[1])
  .forEach(([r, n]) => console.log('  ' + String(n).padStart(4), r));

if (APPLY) {
  fs.writeFileSync(path.join(ROOT, 'languages', 'pt-br.js'), br, 'utf8');
  fs.writeFileSync(SRC, euro, 'utf8');
  console.log('\nWROTE languages/pt-br.js and languages/pt.js');
} else {
  console.log('\nDRY RUN - re-run with --apply');
}
