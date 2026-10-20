# RDR2 Lua developer references

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
