# Stand source handoff

**Old Shares export follow-up:** The baseline counts below come from stand.json. See stand-discord-reviewed.json for the six supplied Old Shares exports (841 messages), the nested themes transcript (751 messages), the imported items, and the export gaps.

`stand.json` is the integration manifest. Only source manifests, evidence and menu-specific helpers were changed in this chat. Shared website files and the main library were not edited.

| Manifest collection | Exact coverage |
| --- | --- |
| `items` | 16 pending Lua cards: 15 public-source scripts and the retained CocoW All-in-One script |
| Lua change history | 14 public-source scripts have verified dated, paraphrased change entries; dates retain their commit/release basis |
| `libraryOverrides` | 117 existing GTA5 IDs: 75 source profiles, 31 All-in-One choices, 11 archive parts |
| Theme previews | 69 exact ThemeRepo preview paths and 3 separate hypercrites previews |
| `legacyOverrides` | 20,781 existing ST512 vehicle IDs and 240 outfit IDs; no duplicate cards |
| Shared format candidates | 19,442 plain Stand vehicle TXT presets and 237 outfit TXT presets |
| Review queue | 1,342 records: 1,151 XML, 152 INI, 30 JSON, 9 TXT with other signatures |
| Preset previews | 20,942 present; 79 vehicle previews absent and explicitly unset |
| Discord Shares / Old Shares | 0 inspected messages; each requested category has an explicit uncovered status |

The original 11 native Stand archive hashes were independently checked against `stand-packs.json` (637,739,333 bytes). All 21,021 legacy payloads were read and hashed; 91 index/chunk/asset inputs are pinned in the grouped legacy evidence. There are 13,584 distinct vehicle payload hashes, so the 20,781 vehicle records must not be described as 20,781 distinct designs.

## Integration

Apply `items` as new records. Merge `libraryOverrides` into the existing main library by exact `id`. Apply `legacyOverrides` to the existing vehicle/outfit records by `family` and zero-based `index`. Preserve the existing resolved payload files and `_legacy` metadata. Do not append legacy overrides as new catalog cards.

The full source manifest retains review detail per record. When generating the public frontend JSON, keep the metadata required by the frontend and retain detailed provenance in this source artifact; there is no need to duplicate the existing indexes or publish every repeated audit sentence.

All Lua cards use `downloadStatus: "pending"` and `files: []`, including publicly available scripts. No Lua card contains a Discord URL. Each Lua keeps its original Stand API requirement. Public author main versions, official Stand package versions and changelog dates are separate evidence fields. Empty version/changelog data remains empty.

For preset data, `supportedMenus` includes Scooby and Nenyoo only for the 19,679 accepted text signatures. This is source format support. It does not establish identical appearance: the inspected Nenyoo adapter subtracts one from named vehicle mod values while Scooby's adapter copies their values. Outfit hair/face metadata and optional fields are not assumed to transfer. The 1,342 other signatures remain available under Stand with a review status; support by a particular Stand importer is also schema-dependent.

Native Scooby Stand theme support is supported by the collection selector and isolated theme runtime test source. It is limited to the original profiles and theme scripts. Nenyoo's converted `theme.lua` packages remain a separate format and are not declared compatible with these originals. The native `Brazil (Animated)` entry is excluded from Stand attribution because its author provenance was not established.

## Reproduce

From the website checkout:

```powershell
node tools/menu-sources/audit-stand-legacy.cjs
node tools/menu-sources/build-stand-manifest.cjs
node tools/menu-sources/build-stand-manifest.cjs --check
```

The legacy audit reads explicit sibling loader files and the already indexed local media. The builder reads evidence JSON and the existing catalog. Neither helper evaluates Lua, downloads mods, edits the shared importer or writes to cool-repo. Public author metadata is an inspected snapshot; refreshing it requires another public-source review.

## Acquisition gaps

Discord Computer Use was stopped by the user, as recorded in `INTEGRATION.md`. No client takeover, hidden Discord state, account databases or private API was used. Current and Old Shares channel histories remain uninspected across Lua/legacy Lua, themes, outfits, vehicles, custom DLCs, ASI mods and misc. The 374 existing source paths containing `old_folders` establish archival source-folder membership only.

No specific Stand custom DLC/ASI/misc/translation share or BiggerScript vehicle/map payload was acquired. The current public BiggerScript main is a Cherax launcher stub and cannot support a Stand resource or vehicle/map listing. Three ThemeRepo profiles lack exact named author previews: Discord v2, Japanese Chill and Standxo. No image or release history was invented to fill those gaps.

Evidence files: `stand-local-audit.json`, `stand-public-audit.json`, `stand-legacy-audit.json`.
