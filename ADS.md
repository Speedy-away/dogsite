# Ad Code Snippets

Placement matters — each unit has its own required spot. Getting it wrong is the
usual reason a unit silently stops paying.

---

## 1. Head Script

Right before `</head>`:

```html
<script src="https://aloudalimonyexplosion.com/21/ba/c2/21bac2cf6146c6ff2689111563b5f00a.js"></script>
```

---

## 2. Footer Script

Right above `</body>` — this one is **not** a head script:

```html
<script src="https://aloudalimonyexplosion.com/17/9e/f8/179ef803d1a93ce7af0ad7b09a49ead9.js"></script>
```

---

## 3. Native Banner

Anywhere in the page body — currently placed just before the footer script:

```html
<script async="async" data-cfasync="false" src="https://aloudalimonyexplosion.com/916d4be3288f94a3bc49ab6cdaef5ba9/invoke.js"></script>
<div id="container-916d4be3288f94a3bc49ab6cdaef5ba9" data-i18n-skip></div>
```

---

## 4. Direct Link

Insert anywhere using a standard hyperlink:

```
https://aloudalimonyexplosion.com/mu10s2um2?key=3d6b7c040dd994f3036ea9636c9e70dd
```

```html
<a href="https://aloudalimonyexplosion.com/mu10s2um2?key=3d6b7c040dd994f3036ea9636c9e70dd" target="_blank" rel="nofollow noopener" class="direct-link-ad">Sponsored Offer</a>
```

---

## Current Status

| Page | Head | Footer | Native banner | Direct link |
| --- | --- | --- | --- | --- |
| `products/free/index.html` | yes | yes | yes | yes |
| `products/cs2/index.html` | yes | yes | yes | no |
| `products/gmod/index.html` | yes | yes | yes | no |

All other pages have no ads.

---

## Gotchas

- The two plain `<script>` units are **not** interchangeable. `21bac2cf…` goes in
  the head, `179ef803…` goes above `</body>`. Both sat in the head until
  2026-08-24, which is not what the network's own instructions call for.
- The native banner container carries `data-i18n-skip`. Without it the
  translator's `MutationObserver` walks the DOM the ad network injects and
  rewrites its text nodes on non-English pages. Keep the attribute on any new ad
  container.
- Redirect pages (`discord.html`, `scoobyontop.html`) fire a `meta refresh`
  immediately, so an ad placed there never gets a chance to load. Do not add ads
  to them.
- The ad endpoints return `403` to anything that is not a real browser, so
  `curl`/`wget` cannot tell you whether a unit is alive. Verify in a browser on
  the live domain with the ad blocker off.
