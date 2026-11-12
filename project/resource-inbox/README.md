# Add resources

Add files under `GAME/MENU/CATEGORY/`. The preview watcher and normal build pick up
changes automatically when the local source folders and `cool-repo` are available.

Examples:

- `gta5/scooby/vehicles/My car.xml`
- `gta5/cherax/outfits/My outfit.json`
- `gta5/stand/maps/My ramp.xml`
- `redm/scooby/sound-packs/My sound pack/`
- `cs2/scooby/pets/My pet pack/`

Use the game IDs gta5, rdr2, cs2, redm or l4d. FiveM and Yim acquisition remain
deferred. A single file becomes one resource. A folder becomes one ZIP containing
its supporting files, with relative paths preserved. An image with the same base
name as a file is its optional preview, for example `My car.jpg`.

For a folder, optional `resource.json` supplies its name, credits, requirements,
tags, compatibility, source URL and changelog. Put the actual payload in `files/`
and an optional source image in `preview.png` (or jpg/webp/gif). Example:

```json
{
  "name": "My sound pack",
  "credits": "Original author",
  "requirements": ["Matching RedM resource and game build"],
  "tags": ["weapons", "sounds"]
}
```

Do not include account data or credentials. Lua files are cataloged as pending
Download listings; the watcher does not run or publish scripts. RedM PM bypass
and faster-scope resources are excluded. Keep author credits inside packages.

The watcher prepares local changes. Use the normal publication workflow to update
the live website and publish `cool-repo` downloads first.

## CS2 pet packs

Keep all models, materials, textures, and other dependencies under `files/` using
their original paths. Include only files you can redistribute. Use `resourcePaths`
in `resource.json` to list the individual model paths. Set `credits` or `author`,
`sourceUrl`, and `license` so readers can identify the creator, find the original
source, and check its terms. Use `source` to describe a local origin when a URL
is unavailable.

To list a pack generated from a local CS2 installation, create a Pets folder
with `resource.json` and set `"status": "in-menu"`. Describe how to generate the
pack in `description`, list the required installed assets or build in
`requirements`, and include the source and license terms. The listing has no
download. Edit the metadata or payload in the same inbox folder to update an
existing pack and retain its catalog link.
