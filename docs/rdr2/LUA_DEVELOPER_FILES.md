# RDR2 Lua developer references

## Attached API browser placement

The in-menu documentation browser remains on the editor's right, aligned with
its top edge. Dragging the editor beyond any screen edge carries the browser
with it; it does not clamp to the viewport or switch sides. Its height follows
the editor with the existing 380-pixel minimum, including oversized editors.
The existing theme, API content and Editor-tab visibility remain in use.

From an MSVC x64 developer environment, run GTA5's
`tools/test_lua_documentation_attachment.py` to exercise both games' production
window functions against their own ImGui versions. Movement across all four
edges, viewport changes, scaling, resizing and visibility are covered. Logs and
draw-data previews are under `build/lua-docs-attachment-20261020/` in each game.
Run both supported Release wrappers with all mandatory guards after native
changes. These fixtures do not establish live-game input acceptance.

For ListUI/ClickUI themes, script-created native feature pages and standalone
interfaces sharing built-in commands, see [custom Lua UI](LUA_CUSTOM_UI.md).
The offline [searchable API browser](lua-api.html) is generated from the same
catalog as the in-menu reference. Regenerate after updating the source catalog:

```powershell
python tools/generate_lua_developer_files.py --output build/lua-developer-files/generated
python tools/update_lua_reference_docs.py --catalog build/lua-developer-files/generated/Documentation.json --output docs/lua-api.html
```

The Lua workspace automatically creates `Documentation.json`, `DataNodes.lua` and
`natives.lua` in its Lua root. They are editor references. Use the host bindings
directly; loading these files does not install an API. Script discovery omits the
reserved filenames, the module/file loaders reject them, and the generated Lua
files raise an error if executed directly or copied under another name.

## Generation and ownership

`tools/generate_lua_developer_files.py` reads this game's native declarations,
explicit Lua binding registrations, `docs/lua-api-reference.md` and the reviewed
signatures/examples in `docs/lua-developer-api.json`. CMake generates the three
files and `LuaDeveloperPayload.hpp` under `build/x64/vs2022/generated/lua/` (or the
corresponding LuaJIT build tree). The API browser consumes the same generated
entries, using the existing UI theme and expandable signatures/examples.

The supported build stages the references beside the DLL in `lua-developer/`.
The DLL installs them when the Lua workspace initializes. Missing owned files are
repaired; changed generated files are replaced through a temporary file and an
atomic rename. Unrelated user files, symlinks, failed writes and a conflicting
temporary file preserve the previous destination and report the conflict. Keep
custom scripts under other filenames. Restart after resolving a conflict.

`Documentation.json` retains the namespace/member format, with explicit
`Signature`, `Example`, `Available`, parameter and source information where
known. `_meta` identifies the game, generator and availability basis. `Available`
records source exposure; it does not certify an engine handler, argument meaning,
network replication or behavior on a particular game build.

## Native and entity contracts

Named RDR2 natives are already installed in every script state. Both
`PLAYER.PLAYER_PED_ID()` and `RDR2.PLAYER.PLAYER_PED_ID()` use the same table.
Existing high-level HUD helpers share that table with the HUD native functions.
Native work belongs on the game callback, never inside a render callback.

Only the signatures accepted by the production typed native marshaller are
advertised as available. Pointer/unknown `Any` signatures require explicit typed
wrappers. `BUILTIN.WAIT` remains unavailable; use `script.yield(ms)`. All source
declarations, including unavailable ones and their reason, remain in the JSON.
Native handles are integers; `Self.getPed()` instead returns a `Ped` object.
Entity instance methods use `:` and native namespace functions use `.`.

`DataNodes.lua` describes bound entity/vector types. No raw RDR2 network-data-node
Lua binding has been verified. GTA5's layouts, enum hashes and memory fields are
not RDR2 contracts and are not copied into this game. The reference file does not
invent constructors or write access to those structures.

The corrected examples use integer model hashes for `Ped.create`, a `Player`
object for `Self.getPlayer`, and the actual `{hour, minute, second}` return table
from `World.getTime`. Cooperative model loading remains in the production asset
adapter. See `scripts/examples/FrontierWorkbench` for a complete modular custom
window, and `docs/lua-imgui-porting.md` for the opt-in C++ style UI adapter.

## Maintenance and verification

Build through the root solution or `tools/build.ps1 -Configuration Release`.
Run `LuaApiContracts` on both Lua54 and LuaJIT after changing runtime bindings.
The regression suite covers reference installation/repair, custom-file
preservation, interrupted replacement, module/loadfile/dofile/direct execution
rejection, script discovery and preservation of HUD helpers during native setup.
`tools/test_lua_contracts.ps1 -LuaRuntime Lua54` (or `LuaJIT`) can also compile
these production contracts into an isolated `build/lua-developer-files/contracts/`
folder using the existing pinned dependencies. This does not replace the full
supported Release build or its translation/font packaging guard.

```powershell
powershell -File tools/build.ps1 -Configuration Release
ctest --test-dir build/x64/vs2022 -C Release -R LuaApiContracts --output-on-failure
powershell -File tools/build.ps1 -Configuration Release -LuaRuntime LuaJIT
ctest --test-dir build/x64/vs2022-luajit -C Release -R LuaApiContracts --output-on-failure
```

For a read-only audit of another documentation catalog and example tree, run
`tools/audit_lua_developer_reference.py --documentation <json> --scripts <folder>
--host <generated-Documentation.json> --output build/<evidence>/audit.json`.
It hashes every Lua file and inventories direct call candidates without running
the scripts. Script-defined helpers and indirect calls require manual review;
candidate counts do not establish compatibility.

Evidence for this change is under `build/lua-developer-files/`. Game/native,
graphics/input, network and foreground-performance acceptance require the exact
built artifact and separate in-game evidence. Translation/font packaging checks
remain mandatory; no translation catalogs or language fonts are added here.

## Canonical custom UI reference

The generated catalog and offline browser document `ImGuiCpp` and one `DrawList`
object type. All 15 drawing methods use colon calls, `ImVec2` coordinates and
packed integer colors. Acquire a fresh list from `GetWindowDrawList`,
`GetBackgroundDrawList` or `GetForegroundDrawList` while rendering. Older script
aliases retain their runtime behavior without separate branded API categories.

`tools/test_lua_developer_generation.py --generated <output> --check-repeat`
checks the drawing inventory against registered native methods, getter return
types, examples, duplicate free functions and public metadata. GTA5's
`tools/test_lua_doc_catalog.ps1` also compiles the actual browser merge and checks
its final categories, tooltips, signatures and examples. This prevents stale
handwritten entries from reappearing beside generated `ImGuiCpp` entries.

Evidence for the canonical reference update belongs under
`build/lua-docs-canonical/`; local website browser/download checks live in the
website project's `build/` tree. Keep live game acceptance separate.
