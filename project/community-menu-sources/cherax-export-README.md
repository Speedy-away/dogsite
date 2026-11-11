# Cherax local export review

`tools/menu-sources/cherax-import-exports.cjs` reads only the user-authorized
DiscordChatExporter JSON exports and relative assets placed below
`project/community-menu-sources/cherax-exports`. It has no network requests,
Discord account-state access, payload execution, archive extraction, or final
manifest writes.

The default command lists filenames and sizes without reading message content
or writing an audit:

```powershell
node tools/menu-sources/cherax-import-exports.cjs
```

After the exporter has finished writing its files, inspect the explicit path:

```powershell
node tools/menu-sources/cherax-import-exports.cjs --input project/community-menu-sources/cherax-exports
```

This writes `project/community-menu-sources/cherax-export-audit.json`. Its
`exports` and `discoveredChannels` record source channel metadata even when an
unknown ID prevents candidate extraction. The default approved IDs come from
the existing ModVerse publisher snapshot and cover only outfits, DLCs, themes
and vehicles; there are no guessed IDs for Lua, translations or wallpapers.

Review the exported guild, channel ID and exact channel/parent display names.
Then save a bounded channel map under `project/community-menu-sources`, with
one entry per approved share channel. This example is a schema illustration;
replace the placeholder values with actual reviewed export evidence:

```json
{
  "channels": [
    {
      "id": "EXACT_SOURCE_CHANNEL_ID",
      "name": "lua-scripts",
      "exportName": "EXACT_EXPORTED_DISPLAY_NAME_INCLUDING_EMOJIS",
      "collection": "current",
      "guildId": "EXACT_EXPORTED_GUILD_ID",
      "evidence": "Reviewed export filename and channel metadata"
    }
  ]
}
```

`name` must be one of `lua-scripts`, `outfit-shares`, `dlc-shares`,
`theme-shares`, `json-vehicles`, `translation-shares`, or `cherax-wallpaper`,
or a corresponding `-old` share name. A separate old Lua channel has not been
observed. `exportName` is optional for display names that exactly equal `name`.
Use `collection: "archival"` for verified old-channel records. The map replaces
the default registry, so include every channel approved for that inspection.

```powershell
node tools/menu-sources/cherax-import-exports.cjs --input project/community-menu-sources/cherax-exports --channel-map project/community-menu-sources/cherax-export-channels.json
node tools/menu-sources/cherax-import-exports.cjs --self-test
```

The parser follows the official [DiscordChatExporter JSON writer](https://github.com/Tyrrrz/DiscordChatExporter/blob/prime/DiscordChatExporter.Core/Exporting/JsonMessageWriter.cs).
For threads, `channel.categoryId` and `channel.category` identify the parent
channel. A thread needs both an approved parent ID and its exact exported
parent display name. A channel name alone never authorizes extraction.

Each candidate preserves its source export, message ID, timestamp, uploader,
attachment metadata, available local path and limited format evidence. The
sender remains distinct from an unverified original developer. The helper
recognizes a conservative subset of explicit version/changelog labels; posts
without unmistakable evidence retain unknown versions and empty changelogs.
Update messages without distinct resource attachments remain separate for
manual association. Synthetic self-check cases never become source records.

All candidates require review and remain `downloadStatus: "pending"` with
`files: []`. Lua sources and Lua payloads also set `showSourceLink: false` and
omit the display-level Discord source URL. Hidden acquisition metadata retains
original attachment references. Actual non-Lua JSON bytes receive syntax and
limited Cherax vehicle/outfit structure checks. Archives receive container
signature checks without extraction; RPF files receive magic-byte checks only.
Theme, translation, DLC and wallpaper checks do not establish other-menu
compatibility. A same-message image remains a preview candidate until visual
review verifies its content and association.

The audit explicitly lists all seven current and six observed old share
channel coverage slots. Counts describe inspected export rows and candidates,
not proof that all server history, archived threads, deleted messages or
restricted posts were acquired. Verify exporter completion, selected channels,
date bounds and thread selection separately before claiming wider coverage.

## Preparing acquired source files

`tools/menu-sources/prepare-cherax-export-assets.cjs` defaults to a read-only
file inventory. Explicit preparation accepts either the reviewed audit above or
stable, valid JSON exports in the approved guild/share channels:

```powershell
node tools/menu-sources/prepare-cherax-export-assets.cjs
node tools/menu-sources/repair-cherax-export-labels.cjs --repair
node tools/menu-sources/prepare-cherax-export-assets.cjs --prepare --input project/community-menu-sources/cherax-exports
node tools/menu-sources/prepare-cherax-export-assets.cjs --prepare --audit project/community-menu-sources/cherax-export-audit.json
node tools/menu-sources/prepare-cherax-export-assets.cjs --review-only
node tools/menu-sources/prepare-cherax-export-assets.cjs --self-test
```

The label-repair command corrects Windows CLI display encoding only after the
selected guild, approved channel/parent ID, canonical share-name suffix, stable
envelope and message count agree. Original CLI labels and the source envelope
SHA-256 remain in the registry. It adds no channels and changes no IDs or
current/old assignments. Without `--repair` it inventories the registry only.

Preparation waits for `cherax-export-status.json` to report completion. Use
`--allow-partial` explicitly to review finished local envelopes during an active
run; empty, changing, incomplete and recently modified exports remain gaps.
Partial outputs never establish whole-channel or whole-server completeness.
`--review-only` normalizes the existing review output without changing acquired
bytes or the acquisition index. Review files use canonical `path` references,
and old collections use `collection: "old"`, `collectionStatus: "archival"`;
original source collection wording remains separately recorded.
When `cherax-preview-review.json` exists, both preparation and review-only mode
consume its exact `assetKey` plus source SHA-256 decisions. Every matching
original image is rehashed and signature-checked. Eligible item/source-post
associations receive canonical staged `preview`/`previewPath`, `localPreview`,
`previewVerified`, observation, confidence and review/source provenance. Explicit
ineligibility remains withheld; video and image-project files are never image
previews. Acquired files are retained. Card publication/download state stays
`staged`/`review` until the parent records publication proof; Lua stays pending.

The helper writes the ignored `cherax-export-downloads/asset-index.json` and
actual-byte-hashed staged files for the publication copier, plus reviewable
`cherax-export-items.json`. It leaves the final `cherax.json` unchanged. Exact
source/payload hashes associate already imported ModVerse entries instead of
adding duplicate cards; source archive hashes can associate multiple existing
presets. Actual image bytes are deduplicated across originals and post previews.
Only attachment/post image paths referenced by approved messages are read;
avatars, author icons, unassociated media-directory files and raw chats are
excluded from publication. Image-only posts remain association-review records.
Ambiguous showcase/screen-recording videos remain in
`mediaOnlyPostsForReview`, with exact acquired files and provenance. Only
explicitly labelled animated/live wallpaper video sources remain format-labelled
resource candidates, and their intended usage still requires review. Videos are
never assigned as image previews.

Allowed resource containers, data/text, Lua source/bytecode, fonts, audio, video
and image/project formats receive signature or conservative syntax checks.
Executables and unsupported formats stay local with explicit gaps. Archives
remain intact. Nothing is extracted, imported, interpreted or executed. Lua
source assets may be stored, while every Lua card remains pending with empty
`files` and no visible Discord link. Known rejected Lua hashes remain excluded.
Creators stay unverified and separate from source uploaders; versions/changelogs
retain only explicit source evidence and require review. Cross-menu support is
limited to recognized Cherax vehicle/outfit JSON formats covered by the existing
Scooby/Nenyoo importer audit.

Files at least 100 MiB retain their full acquisition locally and publish binary
parts of at most 95,000,000 bytes plus a JSON reconstruction manifest. Part and
manifest paths use their own actual SHA-256. The manifest records exact ordered
part paths, sizes and hashes, original full-file size/hash/name, and binary
concatenation instructions. Full acquisitions never become giant Git blobs.
