# Scooby RDR2 Lua runtime

Scripts live in `C:\scooby\RDR2\lua`. Single `.lua` files and package
folders are supported. A package entry point is `main.lua`, `init.lua`, or
`<folder-name>.lua`, in that order; a folder containing exactly one top-level Lua
file can also be a package. `config`, `data`, and `temp` are reserved folders.
Refresh discovers scripts without restarting existing ones. Reload explicitly
recreates the selected state and preserves whether it was running.

## Runtime and API versions

The default build uses **Lua 5.4.6**. A separate **LuaJIT 2.1** build supports
Lua 5.1 syntax, `require('bit')`, and the real `require('ffi')` library. Select
one host runtime at build time; scripts in a loaded DLL share that runtime type,
with a separate state for each script. This is not per-script VM switching.
Neither build falsifies `_VERSION`. LuaJIT cannot parse Lua 5.4 `<const>`/`<close>`,
`//`, or native bitwise operators. Use the Lua54 build for current Samurai source.
LuaJIT does not provide Lua 5.4's standard `utf8` library; use a script module if needed.

LuaJIT runs host scripts in interpreter mode. Compiled traces bypass instruction
hooks, so `jit.on()` is disabled to retain runaway-callback limits. FFI works but
native/FFI calls cannot be interrupted by those limits. Binary C-module loading
through `package.loadlib` remains disabled; FFI is not a C-module loader.

```powershell
# Default artifact: build/Release/scoobyRDR2.dll
powershell -File tools/build.ps1 -Configuration Release -LuaRuntime Lua54
# Separate artifact: build/LuaJIT/Release/scoobyRDR2.dll
powershell -File tools/build.ps1 -Configuration Release -LuaRuntime LuaJIT
# Root solution supports the same choice:
MSBuild ScoobyRDR2.sln /p:Configuration=Release /p:Platform=x64 /p:LuaRuntime=LuaJIT
```

Use these optional declarations in the first 64 lines of the entry point. The
manager checks them before executing script code:

```lua
-- @api 2.0.0
-- @game RDR2
-- @lua any
```

`@lua` accepts `any`, `Lua54`/`5.4`, or `LuaJIT`/`5.1`. Existing scripts without
these comments still load normally. Detailed requirements can be checked before
requiring the rest of a package:

```lua
compat.require {
    api = '2.0.0',
    runtime = {'Lua54', 'LuaJIT'},
    game = 'RDR2',
    capabilities = {'modules', 'custom_gui', 'cooperative_tasks'},
}
log(compat.runtime.version)
if compat.has('ffi') then local ffi = require('ffi') end
```

`compat.api_version` is `2.1.0`; `compat.version` retains the `2026.10` compatibility
revision. API requirements use `major.minor.patch`, require the same major and
at most the host's minor/patch. Unsupported versions, misspelled requirement keys,
games and capabilities fail with a specific error. `compat.runtime` reports
`name`, `version`, `lua_version`, `integer_bits`, `ffi`, and `jit_compilation`.
`integer_bits` is 64 for Lua54's signed integer subtype and 53 exact magnitude
bits for LuaJIT numbers. JSON decoding rejects integers outside the active
runtime's exact range; store large identifiers as strings on LuaJIT.

Both builds supply `table.pack/unpack`, global `unpack`, and
`coroutine.isyieldable`. The Lua54 `bit` module implements signed 32-bit BitOp-style
`tobit/tohex/bnot/band/bor/bxor/lshift/rshift/arshift/rol/ror/bswap`; LuaJIT uses its
native module. `require('json')` resolves to the host JSON API.

`compat.use('yim-legacy')` switches this script's global `ImGui` to the Yim adapter.
`compat.use('scooby')` restores Scooby return order. Call this before importing
modules that capture `ImGui`. `log` remains callable and also provides
`info/debug/warning/error`. File aliases include `filesystem.get_scripts_dir`,
`get_script_dir`, `exists`, `is_regular_file`, `is_directory`,
`create_directory/create_directories`, and `get_files` (sorted file paths).
These aliases retain the Lua-root path restrictions.

## Lifecycle and execution

Enable, disable, reload, and console requests execute on the RDR2 script fiber.
Each script owns its state, tasks, render callbacks, events and timer handles.
Disabling destroys that state after cleanup; enabling creates a fresh state.
`onLoad()` runs before other scheduled work. `onTick()` is a repeating task.
`onUnload()` and `script.on_unload(fn)` run once during normal game-fiber teardown.
If the game fiber is unavailable during host shutdown, states are released
without executing game-native cleanup on the loader thread.

```lua
script.register_looped('status', function(task)
    local ped = PLAYER.PLAYER_PED_ID()
    if ENTITY.DOES_ENTITY_EXIST(ped) then
        local pos = ENTITY.GET_ENTITY_COORDS(ped, true, false)
        log(string.format('%.1f, %.1f, %.1f', pos.x, pos.y, pos.z))
    end
    task:sleep(1000)
end)

local id = script.run_in_fiber(function()
    script.yield(500)
    log('Resumed after at least 500 ms')
end)
script.unregister(id)
```

`script.run_in_callback` and `script.queue_job` alias `run_in_fiber`.
`wait`, `yield`, `script.wait/sleep/yield`, `util.wait/sleep/yield` and
`system.wait/sleep/yield` suspend only the current Lua coroutine. A zero delay
resumes no earlier than the next game tick. Delays are milliseconds, 0–86400000.
Use them inside game callbacks; top-level, render and unload calls cannot yield.
Replacing a named loop replaces its task; returning `false` ends a loop.
`script.is_inside_callback()` reports whether yielding is available.
`script.stop()` requests a normal stop after the current scheduler tick.

A failed task is reported and removed while other tasks continue. Runaway Lua
callbacks have instruction/time limits (normally 1 million instructions/20 ms;
initial file execution allows 250 ms). The scheduler rotates work after an 8 ms
slice. These limits do not preempt an individual C++ native or blocking file I/O,
and are not an isolation boundary for hostile scripts. Keep game work small.

`Streaming.awaitModel(hash, timeoutMs=5000)` and
`Streaming.awaitAnimDict(name, timeoutMs=5000)` load cooperatively. Timeout must
be 0–60000 ms. Existing `Ped.create`, `Vehicle.create`, `Object.create`,
`Object.createByName/createAttached`, `Mount.spawn/spawnAtPlayer` and
`Animation.play/playOnPed/requestDict` use these waits instead of suspending the
host fiber. Invalid or timed-out models produce the existing invalid handle;
animation calls return false. Requested resources are released during cleanup.

## Modules and files

`require('includes.ui')` searches the script's directory first, then the Lua root,
using `?.lua` and `?/init.lua`. Each script has an independent module cache.
`dofile` and `loadfile` resolve relative to the package directory. They load text
chunks only. Absolute paths must remain inside the Lua root; traversal and
resolved junction/symlink escapes are rejected. Native C module loading is absent.
The exposed `os` table contains `clock`, `date`, `time`, and `difftime`.

`File.getPackageDir()` returns the current package directory. Existing
`File.getScriptDir/getScriptsDir()` retain their Lua-root meaning. Existing File
operations resolve against that root. `getScriptName()` and `getScriptPath()`
return the script display name and its directory.

## Custom GUI

```lua
local snapshot = 'Waiting'
script.register_looped('snapshot', function()
    snapshot = tostring(PLAYER.PLAYER_ID())
end)

local renderId = gui.add_always_draw_imgui(function()
    if ImGui.Begin('My RDR2 window', ImGuiWindowFlags.NoCollapse) then
        ImGui.Text(snapshot)
        if ImGui.Button('Game action') then
            script.run_in_fiber(function() log(PLAYER.PLAYER_ID()) end)
        end
    end
    ImGui.End()
end)
```

`script.register_render` and `gui.add_always_draw_imgui` render independently of
the host menu. `gui.add_imgui` renders when either host UI is open.
`script.unregister_render(id)` removes a callback. `gui.override_mouse(bool)`
requests the cursor for an independent window; release it when the window closes.
Script errors and disable/reload release that request.

Game natives are rejected in render callbacks, including existing typed helpers.
Cache game data in a task and queue button actions. ImGui calls are restricted to
render callbacks. A callback cannot pop another callback's tracked scopes;
unclosed windows/groups/style stacks are unwound after errors, and the failing
callback is removed. This guards common script mistakes, not every possible
invalid combination of Dear ImGui flags or arguments.

Existing Scooby widgets retain **`changed, value`** return order. For a port:

```lua
local UI = compat.yim_imgui
local value, changed = UI.Checkbox('Yim convention', false)
```

The explicit adapter covers Checkbox, SliderInt/Float, InputInt/Float/Text,
DragInt/Float, RadioButton, ColorEdit3/4, and InputTextMultiline. It is a subset,
not a replacement for all Yim ImGui overloads. `ImGui.Begin(name, open, flags)`
returns `open, visible`; the name/flags form returns only `visible`.

InputText accepts `(label, text, capacity=4096, flags=0)`. Multiline accepts
`(label, text, width, height, capacity=65536, flags=0)`. Capacity includes the
terminator and ranges from 2 bytes to 1 MiB; oversized initial text produces an
error rather than silently truncating it. Input callback flags are unsupported.
The Yim multiline adapter uses `(label,text,capacity,width,height,flags)`.

Extended bindings include window/child/table/tab flags, PushID/PopID, text
measurement, display/mouse positions, clipboard access, and draw lists.
`GetWindowDrawList`, `GetBackgroundDrawList`, and `GetForegroundDrawList` return
handles that resolve the current frame rather than retaining raw renderer pointers.
Their `AddLine`, `AddRect`, `AddRectFilled`, `AddRectFilledMultiColor`, `AddText`,
`AddCircle`, and `AddCircleFilled` methods accept numeric coordinates and packed
colors from `ImGui.GetColorU32(r,g,b,a)`. Draw calls are valid only while rendering.

`gui.add_tab(name)` creates a tab in a script-owned window using the host theme.
Tabs provide `add_button`, `add_checkbox`, `add_text`, `add_separator`,
`add_sameline`, `add_imgui`, `add_input_int/float/string`, and nested `add_tab`.
Widgets provide `get_value`, `set_value`, `set_text`, `set_enabled`, and `remove`.
Button/value callbacks are queued game tasks; `add_imgui` callbacks render directly.
These tabs do not modify Scooby's existing command IDs or sidebar pages.

## Named RDR2 natives

`PLAYER.PLAYER_ID()` and `RDR2.PLAYER.PLAYER_ID()` access the same binding.
The build derives the catalog from `src/game/rdr/Natives.hpp` and its native
indices, using the host's existing handler cache. This revision exposes 4859 of
7130 declarations with known argument/return types. `Native.is_supported(ns,name)`
and `Native.supported_count` let scripts inspect availability. Existing `Native`
helpers and `native/natives` aliases remain available.

Arguments are exact-count booleans, signed 32-bit integers/handles, 32-bit hashes,
finite floats, or strings, as declared. Vector returns are `{x,y,z}` tables.
Pointer/out-parameter, `Any`, struct and unsupported signatures require existing
typed helpers or a future explicit wrapper. `BUILTIN.WAIT` is excluded; use
`script.yield`. No GTA native hash translation, global/local memory API, arbitrary
pointer calls or native DLL module loader is supplied by the named-native API.
LuaJIT builds separately provide real FFI as described in the runtime section.

The complete availability/signature report is generated at
`build/x64/vs2022/generated/lua/lua-native-catalog.json`. Counts describe binding
coverage, not in-game acceptance of every native or correctness of the upstream
game declarations.

## State, events, and controllers

`Config` is script-owned. It supports nested JSON-compatible tables and preserves
fractional numbers. `save()` replaces the previous config atomically on Windows;
`load()` returns false for invalid JSON and retains the previous in-memory data.
`json` and `JSON` provide `encode`, `decode`, `loadFile`, `saveFile`, and `null`.
Arrays use consecutive positive indices; objects use string keys. Mixed/holey
tables, cycles, excessive nesting and non-finite numbers are errors.

`Event.on(name,fn)` returns a listener ID. `Event.off(name,id)` removes one listener;
omitting the ID removes that event's listeners. `Event.once` unregisters before
invoking the callback. Delivery uses a snapshot: new listeners wait for the next
fire, removed listeners are skipped. Errors are reported and remove the failing
listener. Events are local to one script; no multiplayer/network events are implied.

`Timer` handles are local to one script, with 64-bit stopwatch timestamps.
`Input.getControllerState()` returns `connected`, `backend`, optional XInput
`index`, trigger values 0–1, stick axes −1–1, `hasRightStick`, and a `buttons`
table. Buttons include A/B/X/Y (also Cross/Circle/Square/Triangle), LB/RB, L3/R3,
Up/Down/Left/Right, Start and Back. It shares the host's first-connected XInput
selection and joystick fallback. The fallback supplies a left stick and mapped
buttons, with digital triggers on supported layouts; it does not claim full
DualSense HID/right-stick support. Apply deadzones/thresholds as needed.

## Example and verification

Copy `scripts/examples/FrontierWorkbench` into `C:\scooby\RDR2\lua`, refresh the
script list, then enable **Frontier Workbench**. It demonstrates module imports,
custom drawing, menu tabs, saved settings, controller state and on-foot/mount/
vehicle status. Its render callback uses cached game data.

`LuaApiContracts` tests the production runtime, manager, GUI, file/config/JSON
bindings and native marshalling with a fixture backend. Native execution,
physical input and renderer behavior in RDR2 still require the runtime checks
in `UPDATING.md`.

## Additional GUI primitives for ports

The host includes Samurai's directly referenced ImGui function names, including
`InputTextWithHint`, `Combo/ListBox` (table items, zero-based selection), both
`RadioButton` forms, `SeparatorText`, item rectangles, clipping, text wrapping,
button repeat, window sizing constraints, named `SetWindowSize`, and style queries.
`GetStyle()` returns a **snapshot**, not a mutable pointer to the host style; use
balanced `PushStyleVar/PushStyleColor` calls to apply a script theme.

`ImGui.ImDrawListAddLine/Rect/RectFilled/RectFilledMultiColor/Text/Circle/CircleFilled/Triangle/TriangleFilled`
accept the frame-local draw handle followed by their normal coordinate/color
arguments. The corresponding `draw:Add...` methods also work. Drawing and all
ImGui operations still belong inside a render callback. Matching function names
is not full overload, enum, font/texture, or game-feature compatibility.
Child windows accept the legacy border boolean or an integer ImGuiChildFlags
mask. The reference-used input, hover, child and style constants are exposed.
Sliders and drags accept optional numeric format and slider flags. Formats allow
one matching numeric conversion, up to two width digits and one precision digit;
pointer/string conversions are rejected.
The legacy script.is_active(nameOrHash) form queries the number of running RDR2
game-script threads through the typed native API. It must run on a game callback,
not in rendering. Calling it with no argument retains Scooby's current Lua-state
status query. GTA script names still need replacement with RDR2 equivalents.
## Standalone input bindings (API 2.1)

`Input.isGameFocused()` reports whether the foreground window belongs to the
game process. `Input.isKeyDown(vk)` reads the current high bit for a Windows
virtual key (1-254) and returns false outside that foreground process. These
queries use the held state instead of relying on the shared Win32
"pressed since last query" bit.

`Input.createToggle(options)` creates a script-local edge detector:

```lua
local toggle = Input.createToggle {
    key = Keys.F7,
    controller = {'LB', 'Down'},
}
local open = false
script.register_looped('window binding', function()
    if toggle:poll() then open = not open end
end)
```

`key` and `controller` are optional, but at least one is required. A controller
chord contains 1-4 button names from `Input.getControllerState().buttons`.
Keyboard and controller are alternative activation sources. `poll()` returns
true once per press/chord, not once per frame. Each source must first be released;
every chord button must be released before rearming. Focus loss, a controller
disconnect/device change, and `binding:reset()` clear the corresponding armed
state, preventing held buttons from reopening a window on return. Keys still
work with no controller connected. Poll once each game tick, including while
the window is hidden. This helper does not navigate widgets or suppress game
controls; request/release the cursor using `gui.override_mouse`.

API 2.1 uses the same version comparison for entry metadata and
`compat.require`. `compat.is_api_compatible('2.0.0')` returns a boolean:
three unsigned integer components, same major, and a requirement no newer than
the host. Older 2.0 scripts continue to load; future minor/patch requirements
and malformed versions are rejected.

## Vesper standalone package

The source is `../Lua/Frontier` relative to this host project. Copy the complete
folder to `C:\scooby\RDR2\lua\Frontier`, refresh and enable **Frontier**. It requires
API 2.1 and works with the Lua54 and LuaJIT builds. F7 or LB/L1 + D-pad Down toggles
its custom window. Controller navigation uses LB/RB or Left/Right for pages,
Up/Down for actions, A/Cross to execute and B/Circle to close; close the host
menu for this navigation.

The package demonstrates a cached status/HUD, player and horse recovery actions,
named location storage and return travel, driver-aware vehicle travel,
weather/time overrides and saved preferences. It queues actions on the game
fiber and clears its world overrides during normal unload. It does not infer
waypoint ground heights. Physical controller/game/render/performance acceptance
remains separate from its `FrontierStandalone` fixture test.

### Vesper custom interface

The RDR2 standalone package displays the name Vesper (1.1.0). Its existing `RDR2/Lua/Frontier` folder and internal module/config keys remain stable for saved preferences and bookmarks. Custom vector icons, outlined buttons, pill switches and slider drawing use the existing API 2.1.0; native ImGui input preserves activation and focus. The Lua54 and LuaJIT fixture checks are recorded in `build/vesper-ui-evidence`. In-game renderer, controller and performance acceptance remains outstanding.
