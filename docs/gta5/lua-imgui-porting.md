# Porting C++ ImGui interfaces to Lua

See [native pages and custom interfaces](LUA_CUSTOM_UI.md) for adding feature
pages to **both ListUI and ClickUI**, sharing built-in command state, changing
both native themes and a complete custom feature-browser example.

GTA5 and RDR2 expose `ImGuiCpp`, an opt-in C++-style adapter over the games' pinned ImGui versions. Existing `imgui`, `ImGui`, and compatibility profiles retain their original return conventions. Start a port with `local ImGui = ImGuiCpp` and draw inside `script.register_render(function() ... end)`. Do not replace the global `ImGui` table.

See `ImGuiCppDemo.lua` in this project's Lua examples for the same working UI on both games.

## Mechanical translation

| C++ | Lua |
| --- | --- |
| `ImGui::Button("Run", ImVec2(100, 30))` | `ImGui.Button("Run", ImGui.ImVec2(100, 30))` |
| `bool enabled = true; Checkbox("Enabled", &enabled)` | Persist `enabled = ImGui.Ref(true)`; call `ImGui.Checkbox("Enabled", enabled)` |
| Read `enabled` | Read `enabled.value`; widgets mutate it and return `changed` |
| `float position[3]` | Persist a regular `{0, 0, 0}` table; `DragFloat3` mutates its 1-based elements |
| `ImVec4(r,g,b,a)` | `ImGui.ImVec4(r,g,b,a)` with `.x/.y/.z/.w`; color editors mutate it |
| `ImGuiWindowFlags_NoResize` | `ImGui.ImGuiWindowFlags.NoResize` (flat C++ constant names are also exposed) |
| `flagsA | flagsB` | `ImGui.Flags(flagsA, flagsB)` |
| `draw->AddLine(a,b,col)` | `draw:AddLine(a,b,col)` |
| `Begin(title, &open, flags)` | `Begin(title, openRef, flags)` returns visibility and updates `openRef.value` |

Keep persistent Refs/arrays outside the render callback. Widget selection indices, table columns and font indices are **zero-based**; Lua item arrays are **one-based**. `Begin`/`BeginChild` always need their End calls. Other conditional Begin calls only need End when they return true. Do not yield or call game natives from a render callback; queue gameplay work with the existing script callback API.

## Portable additions and signatures

`Ref(value)`, `ImVec2(x,y)`, `ImVec4(x,y,z,w)`, `Flags(...)`, and `GetCapabilities()` are available at script initialization. Vector getters return `{x,y}`; `ImVec2` also supports addition, subtraction and scalar multiplication. Draw-list handles belong to the frame (and, for window lists, window) that created them.

All widgets below return `changed` and mutate their Ref/array except buttons and boolean Selectable/MenuItem overloads, which return activation:

- `Checkbox(label, ref)`, `CheckboxFlags(label, ref, bits)`, `RadioButton(label, ref, buttonValue)` or `(label, selectedBool)`.
- `SliderFloat/Int(label, ref, min, max, format?, flags?)`; `SliderFloat2/3/4` and `SliderInt2/3/4` take arrays.
- `DragFloat/Int(label, ref, speed?, min?, max?, format?, flags?)`; the 2/3/4 variants take arrays.
- `InputFloat(label, ref, step?, fastStep?, format?, flags?)`, `InputInt(label, ref, step?, fastStep?, flags?)`. `InputFloat2/3/4(label, array, format?, flags?)`; `InputInt2/3/4(label, array, flags?)`.
- `VSliderFloat/Int(label, size, ref, min, max, format?, flags?)`.
- `InputText(label, ref, flags?, capacity?)`, `InputTextWithHint(label, hint, ref, flags?, capacity?)`, `InputTextMultiline(label, ref, size?, flags?, capacity?)`. Capacity defaults to 4096 bytes including the terminator; maximum 1 MiB. Callback flags are rejected.
- `ColorEdit3/4` and `ColorPicker3/4(label, colorVector, flags?)`.
- `Combo/ListBox(label, selectionRef, stringArray, visibleItems?)`.
- `Button(label, size?)`, `InvisibleButton(label, size, flags?)`, `Selectable(label, selectedBool?, flags?, size?)`, `MenuItem(label, shortcut?, selectedBool?, enabled?)`.
- `ColorButton(id, colorVector, flags?, size?)`, `ProgressBar(fraction, size?, overlay?)`.
- `PlotLines/PlotHistogram(label, valuesArray, offset?, overlay?, min?, max?, size?)`; at most 65,536 points. Omit min/max for automatic range.

Windows, children, tabs, popups, list boxes, tables, menus, trees, tooltips, disabled regions, IDs, styling and layout use the existing guarded host scope implementation. The adapter normalizes vector arguments for `BeginChild`, `BeginTable`, `BeginListBox`, `PushStyleVar`, `PushStyleColor`, `PushClipRect`, cursor/window setters, `CalcTextSize` and `TextColored`. `BeginTabItem` and `BeginPopupModal` accept optional open Refs. Text formatting uses Lua `string.format`, not C varargs; `TextUnformatted` is available for literal user text.

Table additions: `TableGetRowIndex`, `TableGetColumnFlags/Name(column?)`, `TableSetColumnEnabled`, `TableSetBgColor`, `TableHeader`, `TableSetupScrollFreeze`, and `TableGetSortSpecs()`. Sort specs are copied into a 1-based array of `{ColumnUserID, ColumnIndex, SortOrder, SortDirection}` plus `SpecsDirty`; acknowledge sorting with `TableClearSortSpecsDirty()`.

Style/input: `GetStyle()` and `GetIO()` return snapshots, not writable pointers. Style colors are indexed by `ImGuiCol` values. Apply temporary styles through Push/Pop. `GetMainViewport()` returns position/size/work-area vectors. `GetFonts()` lists loaded font names; `PushFont(zeroBasedIndex)`/`PopFont()` select an existing font. Named `ImGuiKey` values are accepted by `IsKeyDown/Pressed/Released` and `GetKeyName`. Additional mouse, item state, color conversion, cursor and scrolling queries are included.

`GetWindowDrawList`, `GetBackgroundDrawList`, and `GetForegroundDrawList` support vector-based `AddLine`, `AddRect`, `AddRectFilled`, `AddRectFilledMultiColor`, `AddCircle/Filled`, `AddNgon/Filled`, `AddTriangle/Filled`, `AddQuad/Filled`, `AddText`, `AddBezierCubic`, and `AddBezierQuadratic`. These follow ImGui's parameter order, without native pointer overloads. Circle/curve segment counts are bounded. Use `Dummy` to reserve layout space for custom drawing.

The shared enum surface is generated from public constants common to both games' pinned ImGui versions, including typed key, direction and sorting enums. Declarations sharing one source line are included. Do not persist raw enum numbers between game versions. Prefer the adapter's enum tables. `GetCapabilities().functions` enumerates available calls; host-specific inherited helpers can differ.

Mouse queries use `IsMouseDown(button=0)`, `IsMouseClicked(button=0, repeat=false)` and `IsMouseReleased(button=0)`. Call them during rendering; valid button indices are 0..4. Invalid indices are rejected.

## Explicit limits

This is broad UI-porting support, not a promise that arbitrary C++ compiles as Lua. Context/frame creation, render backends, writable IO/style pointers, raw textures, font-atlas mutation, docking/multiple OS windows, custom native input callbacks, drag/drop payload callbacks, ImGuiListClipper, and draw-list path/channel/primitive internals are not part of the portable adapter. Managed images continue to use GTA5's existing `texture` API; an equivalent portable RDR2 texture API is not provided here. The API does not manufacture these missing capabilities. `GetCapabilities().unsupported` reports the boundaries.

## Maintaining the bridge

Canonical native template and generator are GTA5 `tools/imgui_port_native.in.hpp` and `tools/generate_imgui_port.py`. Run the generator after changing the template or pinned ImGui headers; it updates both projects' `LuaImGuiPortNative.hpp` files using the common public enum intersection. `LuaImGuiPortScript.hpp` and the portable contract/example must remain synchronized. Never hand-edit the generated native headers. C callbacks use Lua-owned temporary buffers so Lua error unwinding cannot cross owning C++ local objects.

Run GTA5 `tools/test_lua_api.cmd` and RDR2's `LuaApiTests` target followed by `ctest --test-dir build/x64/vs2022 -C Release -R LuaApiContracts --output-on-failure`. Build each project's normal Release target after the contracts. Logs stay under `build/`; RDR2's external-translation/font guard remains mandatory. Fixture checks do not establish live game input, visuals or FPS performance.
