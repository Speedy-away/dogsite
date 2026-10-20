# Lua interfaces and themes

Both **ListUI and ClickUI** consume native feature pages registered by Lua.
`features.add_page` builds each row from the existing command and each frontend
uses its own controls, active style, hotkeys and access checks. Find the page in
Lua Content (GTA5 ClickUI: Settings > Lua Content; RDR2 ClickUI: Lua > Lua Content).
Reopen Lua Content after adding a page if that view was already open.

```lua
local page = assert(features.add_page('My Self Tools', {'godmode'}))
-- Later: features.remove_page(page)
```

Pages belong to their Lua state. Reload/stop/unload expires them, even if an old
native-page snapshot is open. Scripts can remove only their own pages. Each
script can register up to 64 pages with up to 256 IDs per page. IDs are exact,
case-sensitive command names, obtained from `features.list()` independently in
each game. Permission/capability settings are excluded from this API.

## Shared feature state in a standalone interface

`features.list(filter)` and `features.get(id)` return snapshots with `id`, `label`,
`description`, `type`, `value` and `available`. Numeric bounds are `min`/`max` when
defined. List entries provide `options = {{value=10,label='Example'}, ...}`; write
the option's actual value, not its array index. Types are `boolean`, `integer`,
`number`, `list`, `string`, `color`, `vector3` and `action`.

`features.set(id, value)` uses the real command setter and returns its resulting
snapshot. `features.call(id)` calls an action and returns true. Invalid input,
unknown IDs, unavailable access or calls made during rendering return **nil,
error message**. Bounds are rejected rather than silently changing the requested
value. Colors use `{x=r,y=g,z=b,w=a}` in 0..1; vectors use `{x,y,z}`. Strings are
limited to 65,536 bytes. Existing command callbacks and settings remain in charge
of applying and saving changes. An action result means it was dispatched; engine
work and asynchronous feature callbacks can finish later.

Read/update commands in game callbacks. Keep ordinary Lua snapshots for rendering
and queue writes with `script.run_in_fiber`. The host serializes access to a
script state. Refreshing a snapshot also picks up changes made in the main UI or
by hotkeys; do not repeatedly force an old local boolean onto the host.

```lua
local I = ImGuiCpp
local write = type(log) == 'function' and log or log.info
local god = I.Ref(false)
script.register_looped('sync-godmode', function(task)
    local feature = features.get('godmode')
    if feature then god.value = feature.value end
    task:sleep(100)
end)
script.register_render(function()
    if I.Begin('My Self UI') then
        if I.Checkbox('God Mode', god) then
            local desired = god.value
            script.run_in_fiber(function()
                local result, err = features.set('godmode', desired)
                if not result then write(err) end
            end)
        end
    end
    I.End()
end)
```

The complete `SharedFeatureUI.lua` example adds search, native command controls,
custom window styling, a theme editor and F7 visibility. `NativeFeaturePage.lua`
shows the native frontend extension. They are ordinary scripts, unlike the three
generated developer reference files.

GTA5 keeps these examples under `examples/lua/`; RDR2 keeps them under
`scripts/examples/`. Copy the chosen `.lua` example into that game's Lua scripts
folder, refresh the script list and enable it. The custom window uses F7 to
show/hide itself. The native-page example needs no separate window or mouse
override.

## Theme both native frontends

`ui_theme.set_accent(r,g,b,a=255)` applies the native accent to **ClickUI and
ListUI**. `ui_theme.get()` captures `{clickui=...,listui=...}`.
`ui_theme.apply(snapshot)` restores captured surfaces through their existing
settings serializers. Omit a surface to leave it alone. Run these calls from
game callbacks, using `script.run_in_fiber` for buttons in a custom window.

```lua
script.run_in_fiber(function()
    local original = ui_theme.get()
    ui_theme.set_accent(80, 160, 240, 255)
    -- Keep original in this script, then restore on an explicit user action:
    -- ui_theme.apply(original)
end)
```

The raw snapshot schema belongs to the current game and native style. RDR2's
`listui` value is a complete active-style profile, including `version` and
`profileStyle`; preserve those fields and its validated layout. GTA5 additionally
has the existing `ui_theme.patch`, `set`, `image_folder` and `reload_images`
helpers. Discover/edit captured fields instead of copying raw settings between
games or renderer styles. Native themes remain saved by the host after a script
stops; only script-owned pages and render callbacks are automatically removed.

Standalone windows use `ImGuiCpp.PushStyleColor/PopStyleColor` and
`PushStyleVar/PopStyleVar` around their own drawing, with balanced stacks. They
can have wholly different navigation, windows, tabs, tables, drawing, colors and
controls while sharing host feature state. These scoped styles do not replace
the native theme. Reuse loaded fonts through `GetFonts`/`PushFont`/`PopFont`.

## Porting an existing C++ interface

Start with [the C++ ImGui adapter](lua-imgui-porting.md): Refs replace output
pointers, tables replace vectors/arrays, and `ImGuiCpp` retains C++ widget return
conventions. Replace native command checkboxes with `features.get/set` or a native
feature page. Replace the C++ renderer callback with `script.register_render`,
and queue engine work onto the script scheduler. The host owns frames, input
capture, renderer backends and context lifetime.

[The supplied C++ interface reference](https://github.com/Mr-X-GTA/YimMenu/blob/master/src/gui.cpp)
uses ImGui style fields and scoped colors; those concepts map to the adapter's
style pushes and custom window rendering. This is a porting workflow, not an
automatic translator or a completed port of that repository. Arbitrary C++
pointers, backend/atlas mutation, docking/multiple OS windows, raw GPU resources
and internal draw-list machinery remain outside the portable API.
`ImGuiCpp.GetCapabilities()` lists supported calls and explicit limits. Managed
image APIs remain game specific. Game features require that game's command or
native implementations; a GTA5 layout does not implement its gameplay in RDR2.

## Verification

Run `tools/test_lua_host_ui.ps1 -LuaRuntime LuaJIT` in each project; RDR2 also
supports `-LuaRuntime Lua54`. The shared production headers are tested for all
value types, host-to-Lua changes, invalid input, bounds, account restrictions,
render-phase rejection, native row construction, per-script removal and unload.
Normal supported Release builds compile both actual adapters and frontend routes.
Use the existing Lua API contracts for real ImGui scope/input behavior. In-game
appearance, controller interaction and foreground performance require separate
testing with the exact DLL; these fixtures do not establish those results.
