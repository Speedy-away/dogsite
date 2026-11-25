# Advertising integrations

## Download and free-key clicks

`assets/js/free-key-sponsor.js` opens the existing Adsterra Smartlink in a sponsored tab on a real, unmodified click. It covers PC product free-key buttons, released R6/Manager downloads, and console files on `/download/#console`.

Console links opt in with `data-download-sponsor` and must have `download`. Navigation, screenshots, purchases, login, the portal loader, and unavailable/coming-soon controls do not opt in. Keep original hrefs, download names and free-key modal actions. Never wait for an ad before downloading.

Destination: `https://ardance.org/4/3d6b7c040dd994f3036ea9636c9e70dd`

The helper attempts one sponsored tab per browsing session, shared between free keys and console downloads through `scooby:free-key-sponsor-opened`. If storage is unavailable, it attempts once per page. Popup blocking must not cancel the original action. A small note describes the sponsored tab before clicking and is removed after the attempt.

### Supplied popunder tag

```html
<script data-cfasync="false" src="https://accountut.com/1/21bac2cf6146c6ff2689111563b5f00a"></script>
```

This tag is **not installed**. Its configuration retrieved on 2026-11-25 has no included/excluded element filter and installs document-wide click handlers. It would trigger ads for navigation and unrelated clicks. The button-only integration uses the existing Smartlink instead, which is a different ad unit. To switch units, obtain provider-configured targeting for download/free-key controls, then replace the Smartlink helper rather than running both popup mechanisms.

## Existing display banners

Product and resource pages use `assets/js/product-banner.js` and `assets/css/ad-sidebar.css`. The 300x250 banner is isolated at `https://scoobymenu.cc./assets/ads/product-banner.html?v=same-tab` and falls back to a clearly labelled sponsored offer. Banner clicks stay in the same tab. The current banner unit is `c7e98cfb5c802055c4eec55f2f606762`.

No second sidebar/native unit has been added. Compare native and display revenue using measured traffic before adding more placements; neither format guarantees a higher CPM.

## Other placements

`freekey.html` uses native container `container-916d4be3288f94a3bc49ab6cdaef5ba9` and script `https://bellnewyork.org/21/916d4be3288f94a3bc49ab6cdaef5ba9`. Keep ad containers marked `data-i18n-skip` so translation does not rewrite ads. `scoobyontop.html` is an immediate external redirect with no ad scripts. Keep account/password/login pages and the signed-in loader flow free of ads.

## Verification

Run `node tools/test-download-sponsor.cjs` for real browser click tests with sponsor requests mocked, avoiding paid ad traffic. Run `node --test tools/community.test.cjs tools/seo.test.js tools/generated-file.test.cjs` for existing checks. Browser blockers and provider fill affect actual ad delivery; HTTP 200 alone does not prove delivery.
