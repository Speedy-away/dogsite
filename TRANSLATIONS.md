# Translations — language selector & i18n

The site ships in **10 languages**, with a flagged selector in the **top-left corner of the navbar** and a **first-visit language picker**.

| Code | Language | Dictionary |
| --- | --- | --- |
| `en` | English | *(source — no file needed)* |
| `es` | Español | [languages/es.js](languages/es.js) |
| `pt` | Português (BR) | [languages/pt.js](languages/pt.js) |
| `fr` | Français | [languages/fr.js](languages/fr.js) |
| `de` | Deutsch | [languages/de.js](languages/de.js) |
| `ru` | Русский | [languages/ru.js](languages/ru.js) |
| `tr` | Türkçe | [languages/tr.js](languages/tr.js) |
| `pl` | Polski | [languages/pl.js](languages/pl.js) |
| `it` | Italiano | [languages/it.js](languages/it.js) |
| `zh` | 简体中文 | [languages/zh.js](languages/zh.js) |

## First-visit picker

On a visitor's **first** visit a modal asks them to choose a language, with their browser language marked **Suggested**. Choosing one (or "Continue in English") writes the choice to `localStorage`, so it never appears again. Clicking outside or pressing Escape keeps the current language and also dismisses it for good.

Re-open it any time from the console with `__scoobyI18n.showPicker()`, or clear the saved choice with `__scoobyI18n.reset()` to see it as a new visitor would.

## Flags

Flags are **inline SVG**, not emoji. Emoji flags (🇩🇪, 🇧🇷) do not render on Windows — the OS ships no flag glyphs, so they fall back to plain letters like "DE". Drawing them guarantees they look identical on every platform. The flag set lives in the `FLAGS` map in [languages/i18n.js](languages/i18n.js).

---

## How it works

Pages stay written in **plain English**. Nothing in the HTML is marked up for translation — no `data-i18n` attributes, no template tags, no build step.

At runtime [languages/i18n.js](languages/i18n.js) walks the page, takes each piece of visible text, looks the **English string itself** up in the chosen dictionary, and swaps in the translation.

That design has one big consequence worth understanding:

> **A string translates everywhere the moment it's in a dictionary.**
> Add `"Download": "Descargar"` once and every page that says "Download" is covered — including pages that don't exist yet.

The English original is remembered per text node, so switching back to English restores the page exactly. There's a test asserting the restored text is byte-identical.

### What is never touched

- `<script>`, `<style>`, `<code>`, `<pre>`, `<textarea>`, `<svg>`, `<canvas>`
- Anything inside an element marked `data-i18n-skip` (the selector itself uses this, so language names always show in their own language)
- Any string not present in the dictionary — it simply stays English

### Also translated

Beyond visible text: `document.title`, `<meta name="description">`, and the `placeholder`, `title`, `alt` and `aria-label` attributes.

---

## Adding or fixing a translation

Open the language file and add a line. Key = the **exact English text**, value = the translation:

```js
"Start Dominating": "Empieza a dominar",
```

That's the whole workflow. No build, no compile — save and reload.

To find what still needs translating on a given language:

```bash
node tools/i18n-extract.js --missing es
```

It prints ready-to-paste lines, already JSON-escaped:

```js
// 1628 string(s) with no es translation
    "Infinite Ammo": "Infinite Ammo",
    "Vehicle Spawner": "Vehicle Spawner",
```

Replace each right-hand side with the translation and paste into `languages/es.js`.

### Checking your work

```bash
node tools/i18n-verify.js
```

Reports per language: how many entries there are, how many actually match text on the site, and flags:

- **dead keys** — an entry that matches nothing (usually a typo or copy that changed). Exits non-zero if any exist.
- **empty values** — an unfinished entry.

It also lists the worst-covered pages, so you know where to spend effort next.

---

## Adding a new language

1. Copy an existing dictionary, e.g. `languages/es.js` → `languages/it.js`.
2. Change **both** occurrences of the code at the bottom of the file:
   ```js
   if (window.__scoobyI18n) window.__scoobyI18n.register('it', t);
   else (window.__scoobyI18nQueue = window.__scoobyI18nQueue || []).push(['it', t]);
   ```
3. Add it to the `LANGS` list near the top of [languages/i18n.js](languages/i18n.js):
   ```js
   { code: 'nl', label: 'NL', native: 'Nederlands' },
   ```
4. Add a flag to the `FLAGS` map in the same file (plain SVG shapes on a `0 0 60 40` canvas):
   ```js
   nl: '<rect width="60" height="40" fill="#fff"/>' +
       '<rect width="60" height="13.3" fill="#AE1C28"/>' +
       '<rect y="26.7" width="60" height="13.3" fill="#21468B"/>',
   ```
   Skip this and the entry still works — it just shows without a flag.

It appears in the selector immediately. Dictionaries load lazily, so extra languages cost returning visitors nothing.

---

## Adding the selector to a new page

```bash
node tools/i18n-inject.js
```

Adds the script tag to any page missing it and skips the rest, so it's safe to re-run any time. Preview first with `--check`.

The tag it inserts, in `<head>`:

```html
<script src="/languages/i18n.js"></script>
```

It goes in `<head>` deliberately — see *Flash of English* below.

---

## Where the selector appears

It's inserted into the first container that exists, in this order:

`.nav-inner` → `.navbar-inner` → `.nav-container` → `nav.navbar` → `.portal-header .header-inner` → `header.header` → `.header-inner`

When it finds a brand element (`.brand`, `.logo`, `.navbar-brand-text`, `.portal-logo`) it wraps the selector and the brand together in a small flex group, so the selector sits at the **far left with the brand right after it** without disturbing the navbar's `space-between` layout.

Pages with no navigation at all — `freekey.html` and the two API references — get a **floating pill fixed to the top-left** instead. Same component, same position on screen.

The two redirect stubs (`discord.html`, `scoobyontop.html`) are intentionally skipped. They have no `<body>` and redirect instantly, so there's nothing to translate.

---

## Behaviour notes

**Language detection.** First visit reads `navigator.languages` and picks a match, otherwise English. After that the choice is remembered in `localStorage` under `scooby.lang` and applies across every page.

**Flash of English.** If a returning visitor has a non-English language stored, the engine hides the body until translation finishes, then reveals it. English visitors never pay this cost. A 1.8-second failsafe reveals the page regardless, so a failed dictionary load can never leave a blank screen.

**Dynamic content.** A `MutationObserver` translates anything added to the page after load, so modals and injected markup are covered.

**Fail-soft.** A missing or broken dictionary leaves the page in English rather than breaking it. Unknown language codes fall back to English.

**Rapid switching.** Dictionaries load over the network. If you click one language then another before the first arrives, the stale response is discarded — the page always settles on your last choice.

---

## Console helpers

Available on any page as `window.__scoobyI18n`:

```js
__scoobyI18n.set('fr')      // switch language
__scoobyI18n.get()          // current language code
__scoobyI18n.langs          // configured languages
__scoobyI18n.missing()      // untranslated strings on THIS page, current language
__scoobyI18n.showPicker()   // re-open the first-visit language picker
__scoobyI18n.reset()        // forget the saved choice (picker shows again on reload)
```

`missing()` is the quickest way to finish a specific page: open it, switch language, run it, translate what it lists.

---

## Current coverage

Each of the 9 dictionaries has **392 entries**, all verified against real page text (zero dead keys). That covers:

- the full site chrome — nav, footer, buttons, modals — on **every one of the 30 pages**
- homepage in full, including hero, feature sections, FAQ and reviews
- store, pricing, payment and checkout flows
- the free-key flow, download and launcher pages
- Terms of Service in full
- videos, docs landing pages, resellers
- product page structure, headings and taglines for all 11 products

`node tools/i18n-extract.js` counts **2,020** translatable strings site-wide, so roughly 1,600 remain — concentrated in the long feature lists (`scooby-features`, `best-mod-menu`, `guides`, the `portal` dashboard, and the per-product feature bullets). Those pages are fully **wired** and their chrome is translated; their body copy falls back to English until entries are added.

Deliberately **excluded** from that 2,020 count, since translating them would be wrong:

- `fivem_api_reference.html` and `redm_api_reference.html` — Lua function signatures
- `features-list/gta-features/`, `features-list/rdr2-features/` — generated feature dumps
- `changelog/` — version history

Adjust that list in the `DUMP` set in [tools/i18n-extract.js](tools/i18n-extract.js) if you want them counted.

---

## Files

## Keeping translations up to date

When site copy changes, dictionaries drift. [tools/i18n-update.js](tools/i18n-update.js) manages that:

```bash
node tools/i18n-update.js            # report drift, change nothing
node tools/i18n-update.js --apply    # refresh the to-translate lists
node tools/i18n-update.js --merge    # fold finished translations back in
node tools/i18n-update.js --prune    # drop entries no page uses any more
node tools/i18n-update.js --watch    # re-report whenever a page changes
```

The round trip:

1. Content changes on the site.
2. `--apply` writes `languages/_todo/<lang>.js`, listing every new English string as a `"English": "English"` placeholder.
3. You translate the right-hand sides in that file.
4. `--merge` moves each finished line into `languages/<lang>.js` and drops it from the to-do list. Lines still identical to the English are left behind as unfinished.

The to-do files live in `languages/_todo/` and are **never loaded by the website** — untranslated strings already fall back to English at runtime, so shipping placeholders would add ~120 KB per language for no benefit.

Run it on every commit:

```bash
node tools/i18n-update.js --install-hook
```

That adds a `pre-commit` hook which reports drift and **never blocks the commit**. The no-argument form exits non-zero when anything is out of sync, so it also works as a CI gate.

---

## Files

| File | Purpose |
| --- | --- |
| [languages/i18n.js](languages/i18n.js) | Engine, selector UI, flags and styles. The only file pages load |
| `languages/{es,pt,fr,de,ru,tr,pl,it,zh}.js` | Dictionaries, loaded on demand |
| `languages/_todo/*.js` | Strings awaiting translation. Working files, never shipped |
| [tools/i18n-update.js](tools/i18n-update.js) | Keeps dictionaries in sync with the site |
| [tools/i18n-extract.js](tools/i18n-extract.js) | Pull translatable strings; `--list`, `--missing <lang>` |
| [tools/i18n-verify.js](tools/i18n-verify.js) | Check dictionaries for dead keys and report coverage |
| [tools/i18n-inject.js](tools/i18n-inject.js) | Add the script tag to pages; `--check` to preview |

Everything here syncs to the twin repo through `sync-site-repos.ps1` — see [SYNC-SITE-REPOS.md](SYNC-SITE-REPOS.md).
