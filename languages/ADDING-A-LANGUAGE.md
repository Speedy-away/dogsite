# Adding a language — runbook

**Purpose:** say "add \<language\>" and this file is all that's needed to do it correctly.
Everything lives in `languages/`. There is no build step.

---

## The 4 steps

### 1. Register it in the engine

[i18n.js](i18n.js) → the `LANGS` array near the top. Append:

```js
{ code: 'nl', label: 'NL', native: 'Nederlands' }
```

- `code` — ISO 639-1, lowercase, two letters. Must match the dictionary filename.
- `label` — the badge text, uppercase, two letters.
- `native` — the language's own name, **written in that language** (Deutsch, not German). This is what users scan for, so it must never be translated.

Order in this array is the order shown in the dropdown and the first-visit picker. English stays first.

### 2. Draw a flag

Same file → the `FLAGS` map. Plain SVG shapes on a **`0 0 60 40`** canvas (no `<svg>` wrapper — that is added for you):

```js
nl: '<rect width="60" height="40" fill="#fff"/>' +
    '<rect width="60" height="13.33" fill="#AE1C28"/>' +
    '<rect y="26.67" width="60" height="13.33" fill="#21468B"/>',
```

**Do not use emoji flags.** Windows ships no flag glyphs, so 🇳🇱 renders as the letters "NL". That is the entire reason these are drawn.

Handy geometry on the 60×40 canvas:
- horizontal thirds → `y=0 / 13.33 / 26.67`, each `height="13.33"`
- vertical thirds → `x=0 / 20 / 40`, each `width="20"`
- halves → `height="20"` or `width="30"`
- centred disc → `<circle cx="30" cy="20" r="12"/>`
- a five-pointed star helper already exists: `star(x, y, radius, rotation)`

Skipping the flag is allowed — the entry still works, it just shows without one.

### 3. Create the dictionary

Copy an existing file, e.g. `es.js` → `nl.js`, and change **both** occurrences of the code at the bottom:

```js
if (window.__scoobyI18n) window.__scoobyI18n.register('nl', t);
else (window.__scoobyI18nQueue = window.__scoobyI18nQueue || []).push(['nl', t]);
```

Then translate the values. **Keys are the English source text and must never change** — they are what the runtime looks up.

Keep the key set identical to `es.js` so every language stays in step. Verify with:

```bash
node tools/i18n-verify.js
```

### 4. Check it

```bash
node --check languages/nl.js      # parses
node tools/i18n-verify.js         # 0 dead keys, key count matches the others
node tools/i18n-update.js         # drift report
```

Then load any page, open the selector, pick the language, and confirm the nav and footer change.

---

## Translation conventions

These are followed by every existing dictionary — match them.

**Leave in English** — cheat jargon, because that is what these communities actually say in every language:

> aimbot · ESP · triggerbot · chams · ragebot · legitbot · silent aim · magic bullet · noclip · wallhack · speedhack · HWID · spoofer

**Also leave alone** — brand and product names:

> Scooby · FiveM · RedM · GTA 5 · RDR2 · CS2 · GMOD · S&box · Discord · Telegram · PayPal · BattlEye · Premium · Premium Plus · Lua

**Do translate** — descriptive feature names ("Infinite Ammo", "Never Wanted", "Money Rain"), all UI text, all prose, page titles and meta descriptions.

**Register:** informal/second-person, matching the English. This is a gaming audience, not a bank.

**Watch out for:**
- The key `"© 2026 Scooby. All rights reserved."` — translate the sentence, keep the `©` and the year.
- Keys containing quotes, e.g. `"\"Unlock Link\""` — that button label stays in English because it is the literal text on a third-party page.
- Sentence-fragment keys like `"Click the"` / `"button to reveal your key"` — these join around a bolded element, so keep them as fragments that still read correctly in sequence.
- CJK and Thai: no space before punctuation, and use full-width colons (：) where natural.

---

## Right-to-left languages

Arabic, Hebrew, Persian and Urdu need more than a dictionary — the whole layout has to mirror. The engine does **not** do this yet. Adding one properly means setting `dir="rtl"` on `<html>` alongside `lang`, and auditing every page for hard-coded `left`/`right` CSS. Treat it as a separate piece of work, not a drop-in.

---

## Current state

| Code | Language | Dictionary |
| --- | --- | --- |
| `en` | English | source — no file |
| `es` | Español | ✅ |
| `pt` | Português (BR) | ✅ |
| `fr` | Français | ✅ |
| `de` | Deutsch | ✅ |
| `ru` | Русский | ✅ |
| `tr` | Türkçe | ✅ |
| `pl` | Polski | ✅ |
| `it` | Italiano | ✅ |
| `zh` | 简体中文 | ✅ |
| `ja` | 日本語 | ✅ |
| `ko` | 한국어 | ✅ |
| `th` | ไทย | ⬜ registered, dictionary pending |
| `vi` | Tiếng Việt | ⬜ registered, dictionary pending |
| `id` | Indonesia | ⬜ registered, dictionary pending |
| `hi` | हिन्दी | ⬜ registered, dictionary pending |
| `sr` | Српски | ⬜ registered, dictionary pending |

A language that is registered without a dictionary is **safe** — it appears in the picker, and choosing it leaves the page in English rather than erroring. It is just not useful until the file exists.

---

## Removing a language

Delete `languages/<code>.js`, then remove its `LANGS` entry and its `FLAGS` entry. Anyone who had it saved falls back to English automatically on their next visit.

---

## Related

- [../TRANSLATIONS.md](../TRANSLATIONS.md) — how the engine works, the selector, the first-visit picker
- [../tools/i18n-update.js](../tools/i18n-update.js) — keeps dictionaries in sync as site copy changes
- `_todo/` — generated lists of strings still needing translation
