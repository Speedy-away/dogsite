# GTA5 Lua developer references

## Attached API browser placement

The in-menu documentation browser remains on the editor's right, aligned with
its top edge. Dragging the editor beyond any screen edge carries the browser
with it; it does not clamp to the viewport or switch sides. Its height follows
the editor with the existing 380-pixel minimum, including oversized editors.
The existing theme, API content and Editor-tab visibility remain in use.

From an MSVC x64 developer environment, run
`python tools/test_lua_documentation_attachment.py` to exercise both games'
production window functions against their own ImGui versions. Movement across
all four edges, viewport changes, scaling, resizing and visibility are covered.
Logs and draw-data previews are under `build/lua-docs-attachment-20261020/` in
each game. Run both supported Release wrappers with all mandatory gates after
native changes. These fixtures do not establish live-game input acceptance.

See [custom Lua UI](LUA_CUSTOM_UI.md) for ListUI/ClickUI themes, native feature
pages and standalone interfaces sharing built-in commands. The offline
[searchable API browser](lua-api.html) consumes the same generated catalog as
the in-menu reference. Refresh it after changing bindings or reviewed docs:

```powershell
python tools/generate_lua_developer_files.py --output build/lua-developer-files/generated
python tools/update_lua_reference_docs.py --catalog build/lua-developer-files/generated/Documentation.json --output docs/lua-api.html
```

The Lua workspace creates Documentation.json, DataNodes.lua and natives.lua in
its Lua root automatically. The files provide editor help and are not runnable
scripts. The script manager excludes their reserved filenames, the production
module resolver rejects them, and the Lua files fail immediately if executed
under another name. Normal scripts retain their opt-in Auto-Run settings.

## Catalog and build contract

The generator tools/generate_lua_developer_files.py reads the maintained Scooby
API JSON, this project's game/gta/Natives.hpp and its compiled NativeDefs.cpp
wrapper table. Native definitions come from this game and build, not from another
menu's wrapper file. Use natives.load_natives() once per script state before
calling the named namespaces. The native capability setting still applies.

CMake generates the references and LuaDeveloperPayload.hpp under
build/x64-MSVC/generated/lua-developer/. The supported wrapper stages the three
reference files beside the DLL under lua-developer/. Startup installs them in
the Lua folder. Missing generated files are repaired, owned files update by
atomic replacement, and unrelated user files/symlinks or failed/interrupted
writes preserve the old destination and report a conflict. Keep custom scripts
under other names; resolve a conflict before the next startup.

The API browser uses the same generated entries and existing UI theme. JSON
namespaces/members include Signature, Example, Available and native parameter
information. _meta records the game and source availability basis. Availability
means an exposed source binding; it does not certify a handler or behavior on
every Legacy/Enhanced game version. Pointer arguments retain the native invoker's
existing capability, argument and lifetime requirements.

## Data-node schemas

DataNodes.lua retains the documented GTA5 raw node field schemas for editor use.
These classes have no verified raw Lua bindings in this host and are marked
unavailable in the JSON. They are omitted from the executable API browser.
Older placeholder eSyncDataNode values are also not advertised as a verified
engine contract. No constructor, arbitrary structure writer or fake successful
implementation is generated from annotations. Existing compatibility globals
are preserved for existing scripts. RDR2 has its own entity/native reference
files and must not use GTA5 memory layouts or enum hashes.

Use the existing modular Vesper package and examples/lua/ImGuiCppDemo.lua for
custom windows, callbacks and native actions. The documentation catalog and
sample scripts are design/porting inputs, not an instruction to execute them or
proof of unchanged cross-host compatibility.

## Verification

Build with _build_run.bat (Release) or the root Visual Studio solution. The
Release, Test, solution and Lua API test wrappers share a named build mutex so
concurrent configure/build operations cannot replace each other's CMake scratch
targets or Ninja logs. Existing toolset arguments remain supported. The
ScoobyProjectRules self-test/source scan and post-link binary/map scan remain
mandatory, including zero TLS callbacks and zero dynamic-CRT imports. Do not
change their baselines to accept new regressions.

Run tools/test_lua_api.cmd for the existing LuaJIT/ImGui/Studio contracts plus
reference installation, regeneration, custom-file preservation, interrupted
replacement recovery and direct execution rejection. Production module and
script-manager changes also require game acceptance. Keep evidence under
build/lua-developer-files/.

The generic read-only audit tool accepts --documentation, --scripts, --host and
--output. It reads every source file, hashes the inventory and reports direct
call candidates without executing any code. Dynamic calls, script-defined
helpers and actual return/argument behavior need further validation.

Runtime acceptance uses the exact candidate DLL for each game edition, checks
reference creation, editor/browser content, normal script load/Auto-Run,
module rejection, reload and shutdown, and records foreground performance per
the shared guide. Build/fixture results alone do not establish game acceptance.
Nothing in this workflow commits, pushes, publishes or updates changelogs.

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

Pass `-Python <python.exe>` to `tools/test_lua_doc_catalog.ps1` to run the
standalone production-browser merge check after cleaning the game build cache.
The fixture requires Visual Studio C++ tools and generates its own reference header.
