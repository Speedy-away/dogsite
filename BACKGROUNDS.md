# Homepage backgrounds

Use this guide to add more game artwork to the homepage's random background slideshow.

## Quick example: add one background

1. Choose a unique lowercase name with hyphens, such as `l4d-hospital`.
2. Save **both** finished images in `assets/images/hero/`:
   - `l4d-hospital-v2.webp` — **1672 × 941 pixels**.
   - `l4d-hospital-v2-960.webp` — **960 × 540 pixels**, resized from the same artwork.
3. Open [assets/js/hero-slideshow.js](assets/js/hero-slideshow.js).
4. Add this line inside `var scenes = [ ... ];`:

```js
{ file: 'l4d-hospital', game: 'Left 4 Dead', name: 'The hospital' }
```

Separate every entry with a comma. For example, the end of the list would become:

```js
    { file: 'l4d-railyard', game: 'Left 4 Dead', name: 'The rail yard' },
    { file: 'l4d-hospital', game: 'Left 4 Dead', name: 'The hospital' }
  ];
```

Replace the example name and labels with your own. The `file` value is only the base name: **do not include a folder, `-v2`, or an extension**. The loader adds those automatically. Use double quotes around a label containing an apostrophe, for example `game: "Garry's Mod"`.

The new entry joins the shuffle automatically. No HTML, CSS, or progress-bar changes are needed. Putting files in the folder alone does not add them to the slideshow.

## Making artwork that matches

Reference characters and scenery currently live in:

```text
C:\Users\whatw\OneDrive\Desktop\f
```

Use each game's supplied character and background images to make one combined landscape image. Keep the original reference files.

- Use a wide, full-bleed composition, approximately 16:9.
- Keep characters small, in the right third, centered around 79% of the image width.
- Aim for the top of the head around 35–36% of image height and feet near 94–95%. A full-body character should occupy roughly 60% of the image height.
- Keep the left 60% clear of foreground characters for the website title and buttons. Keep the top 30% mostly scenery.
- Preserve the supplied character's recognizable face and outfit, with sharp detail and consistent lighting.
- Leave margins around heads and feet. The website crops the image on narrower screens.
- Avoid baked-in titles, logos, interface elements, borders, and watermarks.
- Export high-quality WebP. Existing exports use quality 94 for the full image and 90 for the smaller version.

A reusable image prompt:

> Create a polished cinematic game loading-screen illustration using the supplied scenery and character references. Make a wide, full-bleed landscape with crisp detail and coherent lighting. Keep the character small in the right third, head at about 36% of canvas height and feet at 94%, with room around them. Keep the left 60% and top 30% scenery only. Preserve the character's face and outfit. Let the environment dominate. No text, logos, interface, borders, or watermark.

## Record the artwork

[assets/images/hero/artwork-prompts.json](assets/images/hero/artwork-prompts.json) records source images, generation prompts, and output files. Append an entry to its `scenes` array when creating new artwork:

```json
{
  "name": "l4d-hospital",
  "game": "Left 4 Dead",
  "label": "The hospital",
  "refs": [
    "l4d/background-reference.jpg",
    "l4d/character-reference.webp"
  ],
  "prompt": "The exact prompt used to create this image.",
  "generatedFile": "C:/path/to/the/generated-original.png",
  "currentFile": "l4d-hospital-v2.webp",
  "responsiveFile": "l4d-hospital-v2-960.webp",
  "active": true
}
```

Replace all example paths and text with the actual values. Reference paths are relative to the manifest's `sourceFolder`.

This JSON file is a record, **not the slideshow configuration**. The JavaScript `scenes` list determines which images appear.

## Current slideshow settings

- Random first scene, then a shuffled cycle through all active entries.
- A fresh shuffle each cycle, with no immediate repeat across cycles.
- Background changes start **10 seconds apart**, with a smooth crossfade. The setting is `var dwell = 10000;`.
- The caption, progress bars, pause button, and next button stay hidden.
- Keep the hidden `sceneControls` markup in `index.html`; the current script still uses it internally.
- Playback pauses while the tab is hidden or the hero is offscreen. Reduced-motion mode starts with a still background.
- Only the next image is preloaded. A slow or failed image must not replace the visible background with an empty frame.

The previously removed `gta-night` and `gta-mountain` scenes remain on disk but are excluded from the rotation. Keep them excluded when adding new artwork.

## Check or remove a background

After adding an entry, refresh the local site at [localhost:8080](http://localhost:8080/). Check the desktop and phone layouts, image sharpness, character framing, and title readability. Watch for the new image during a full shuffle cycle; it may appear anywhere in the order.

If it does not appear, check the base name, both WebP filenames, commas in the scene list, and image-loading errors in the browser. A scene skipped because of a failed load needs a page reload after its files are fixed.

To remove a background, delete its entry from the JavaScript `scenes` list and set its manifest entry to `"active": false`. The source and exported files can stay on disk.

## Request another background later

> Follow BACKGROUNDS.md. Use the character and scenery images in [folder path] to create and add another background. Keep the smaller character sizing, hidden controls, and random 10-second rotation. Save both WebP sizes, add the scene line, update the artwork records, and check the desktop and mobile layouts.
