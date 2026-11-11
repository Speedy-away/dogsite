# X-Force public source audit

Audited 11 November 2026. This audit inspected publicly accessible pages, GitHub repository metadata/file trees, source headers and commit history. No script was executed; no runtime binary was downloaded. Discord was not opened or controlled.

The machine-readable candidate records are in `public-lua-candidates.json`. They contain four Lua candidates, all with `downloadStatus: "pending"`, `files: []`, and only X-Force in `supportedMenus`. These are evidence-backed placeholder candidates, not proof of current runtime support. Previously excluded broken examples must remain excluded when the shared importer reconciles these records.

`public-source-responses.json` records the pinned raw source response URLs, byte lengths, SHA-256 hashes and selected observed repository metadata. The original Lua was inspected in memory and is not included as a downloadable file.

## Original public authors

| Repository | Inspected pinned source | Evidence and limits |
| --- | --- | --- |
| [2230x/Business-Manager](https://github.com/2230x/Business-Manager) | [`c525331a69c3b5651a94b08cd7efe3ac8265e8ca`](https://github.com/2230x/Business-Manager/commit/c525331a69c3b5651a94b08cd7efe3ac8265e8ca), `22s_Business_Manager_XForce.lua` | One public upload commit, 16 September 2026 at 18:58:38 UTC. Repository description specifies XForce GTA 5 Enhanced PC. Header identifies an X-Force conversion of a supplied YimMenuV2 script and says supplied business offsets/tunables were preserved. No README, license, explicit version, preview or detailed release notes were observed. |
| [anditv21/x-luas](https://github.com/anditv21/x-luas) | [`536b2267801f3a00487a03714031939a47d2d963`](https://github.com/anditv21/x-luas/commit/536b2267801f3a00487a03714031939a47d2d963), `DadMenuProTo21.1.69.lua`, `casino-bypass.lua`, `snacks.lua` | README explicitly identifies the collection as the author's X-Force Lua work and requests attribution. Three Lua files and the README were present. Latest repository commit observed: 9 August 2024 at 20:59:37 UTC. No license, script-specific preview, tagged release or explicit Lua release version was established. These are archival source records. |

Commit dates appear only in `sourceHistory` with `dateType: "git-commit"`. The detailed `changelog` arrays remain empty because commit names are not detailed author release notes. DadMenu's filename includes `1.69`; it is not promoted to a claimed Lua version.

The source APIs are host-specific. The Business Manager conversion still requires X-Force `g_lua`, `g_gui`, `g_util`, `g_tunables`, `SCRIPT` and native wrappers. The older collection uses X-Force `g_lua`/`g_gui` APIs. Original YimMenu lineage or shared GTA natives do not establish support in another menu.

## Official menu and historical forum

The [official landing page](https://xforce.menu/) advertises a Lua engine. Its publicly linked [menu screenshot](https://xforce.menu/assets/img/menu.png) returned HTTP 200, `image/png`, 97,706 bytes. It is a general menu reference and must not be presented as a preview of an individual Lua. The logo animation `https://xforce.menu/assets/img/xforcefull.gif` also returned HTTP 200 (`image/gif`, 4,737 bytes), but is not resource preview evidence.

[RevUnity's public useful-links page](https://docs.revunity.com/our-products/x-force/x-force-useful-links.md) points to `https://forum.xforce.menu/index.php` and `https://forum.xforce.menu/index.php?forums/changelogs.8/`. Both forum requests failed DNS resolution during this audit. No forum threads or author resource releases were inspected. The documentation is useful for locating the historical forum, not proof of a current file or version.

## Requested media coverage and exclusions

No additional public author collection was established in this bounded search for `ui-configs`, `custom-header`, `asi-scripts`, `outfits`, `translations`, `custom-dlc-addons`, `xml-vehicles`, `xml-maps`, or `misc-files`. These gaps must remain explicit, alongside the parent's separate local UI pack audit. The Lua candidates are not recategorized as misc files to fill empty coverage.

Public repository search also surfaced `xforce-gta/xforce`, `xf0rcemm/xforce` and `CaptainRemain/X-Force-Mod-Menu`. Inspected trees were promotional website/README repositories, not original resource collections. No affiliation with the official site was established. They are excluded as acquisition sources.

Public GitHub metadata searches included `xforce gta`, `"X-Force" gta`, `"XForce" mod menu`, `"xforce.menu"`, `"xf_cnfg"`, and `xforce themes`. Public web searches covered the requested category terms and exact archive/extension markers. This is a bounded public audit, not a claim that every X-Force share was inspected. GitHub's unauthenticated API rate limit was reached during per-file-history follow-up; existing source-history records use earlier observed commit data and are not asserted to be exhaustive file histories.
