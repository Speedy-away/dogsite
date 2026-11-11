# Add resources

Add files under `GAME/MENU/CATEGORY/`. The preview watcher and normal build pick up
changes automatically when the local source folders and `cool-repo` are available.

Examples:

- `gta5/scooby/vehicles/My car.xml`
- `gta5/cherax/outfits/My outfit.json`
- `gta5/stand/maps/My ramp.xml`
- `redm/scooby/sound-packs/My sound pack/`

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
