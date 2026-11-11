# Resource collection integration

The main chat is integrating the shared website. Menu sources remain separate in
`cherax.json`, `stand.json` and `xforce.json` in this folder. Discord Computer Use
was stopped by the user with Escape; do not take over the client this turn.
Current and old Discord histories remain unverified unless recorded evidence exists.

The frontend merges `community/data/menu-resources.json` with its original library.
The parent owns its normalized generation. Use unique `id`, `game: "gta5"`,
`sourceMenu`, `supportedMenus`, `category`, `name`, `files`, `tags`, and source evidence.
Use `downloadStatus: "pending"`, `files: []` for Lua placeholders. Changelog shape:
`[{"version":"...","date":"YYYY-MM-DD","changes":["paraphrased verified change"]}]`.
Missing changelogs stay empty. No visible Discord links for Lua entries.

Supported categories include vehicles, outfits, maps, themes, configs, lua,
languages, misc, dlc, wallpapers, asi-mods and addon assets. Original source previews
may set `previewVerified: true`; generated illustrations and text covers must not.

Do not duplicate the original 22,100 GTA preset records. Existing source records can
be represented as `legacyOverrides` with family/index (zero based) or exact source
paths plus sourceMenu/supportedMenus and evidence. The shared helper and parent
normalizer apply these labels to existing records. References to existing library
entries can use `libraryOverrides` with their exact id.

Files in the sibling cool-repo require an escalated write in the main chat; source
preparation can remain within this workspace until publication is requested.
