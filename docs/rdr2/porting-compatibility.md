# Scooby Lua porting guide

GTA5 and RDR2 expose game-specific APIs. Use each game's generated
`Documentation.json` and [API reference](lua-api.html) for exact signatures and
availability. Generated `DataNodes.lua` and `natives.lua` provide editor metadata;
they must not be loaded as scripts.

## Custom interfaces and native pages

Use [ImGuiCpp](lua-imgui-porting.md) for C++-style interfaces: Refs replace output
pointers, vectors use `ImVec2`/`ImVec4`, and widgets mutate the supplied Ref or
array. Keep Refs outside render callbacks. Pair Begin/End and style pushes/pops
within the same callback. Lua item arrays are one-based; widget selections,
columns and font indices are zero-based.

Register independent windows with `script.register_render`. Read game state in
a scheduled game callback and cache it for drawing. Queue button actions onto
the game scheduler; do not call game natives or yield while rendering.

[Native pages and themes](LUA_CUSTOM_UI.md) explains adding script-owned feature
pages to both ClickUI and ListUI. `features.list` discovers this game's command
IDs. `features.get/set/call` uses the same host state and access checks as the main
GUI. `ui_theme` captures and applies the native themes. Scoped ImGui styles apply
to custom windows.

## Drawing

`ImGuiCpp.GetWindowDrawList()`, `GetBackgroundDrawList()` and
`GetForegroundDrawList()` return a `DrawList` object. Call its methods with a
colon and `ImVec2` coordinates, for example
`draw:AddLine(from, to, 0xffffffff, 2)`. The API browser lists all 15 methods under
one `DrawList` category. Drawing methods are not free `ImGuiCpp.Add*` functions.
Reacquire lists every frame; window lists also belong to their creating window.

## Porting game behavior

Map every game-specific native, model, animation, command and structure to the
target game. A shared UI does not implement GTA5 gameplay in RDR2. Avoid copying
GTA5 data-node layouts, globals, hashes or offsets into RDR2. Check availability
in the generated catalog, and report missing functionality explicitly.

Use the host's script-relative module loading, configuration, file and JSON APIs
for packages. Preserve package layout and user configuration. Register cleanup
for resources and callbacks, and test reload, cancellation and unload.

## Validation

Run the project's Lua API and developer-file contracts described in
[UPDATING.md](../UPDATING.md). Exercise custom windows, native feature pages in
both menu modes, themes, render errors and unload. A successful source build or
headless GUI test does not establish gameplay acceptance. Record the exact game,
script revision and built DLL used for live validation.
