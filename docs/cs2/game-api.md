# CS2 v2 Lua API 2.4

Open **Other → Scripts**. The visible tabs are Scripts, Lua Editor and Console. The manager opens custom Script UI pages. Toggle **API docs** in the editor to attach its searchable documentation window to the right of the menu, with expandable signatures and examples.

## Getting started

Scripts live in `C:\scooby\CS2-v2\scripts`. First use installs the CS2 examples: **Welcome**, **Player labels**, **Session monitor**, **Saved preferences**, and **Geometry HUD**, **Crosshair**, and **Speed HUD**, plus **Command framework**, **Download asset**, **Inventory studio**, **Framework - Player ESP** and **Framework - Asset downloads**. The **Native hooks** template demonstrates pattern discovery, a typed hook, shared values and a custom page; it stays inactive until its pattern is configured. It also installs canonical **Custom UI** and CS2 adaptations of the Simple-base UI-v2 **Standalone Menu** and **ImGui Demo** layouts. Builds refresh the shared docs/templates automatically. Startup upgrades untouched bundled examples and preserves user-edited scripts.

1. Open an example in Editor or choose New script.
2. Save with a simple filename, without `.lua` or a path. Names allow Unicode letters, numbers, spaces, underscores and hyphens, up to 64 UTF-8 bytes.
3. Use Run Lua (or Ctrl+Enter) to execute the current editor buffer. While that script is running, the action becomes Unload; use it to stop the script, then Run again to apply edited code. Ctrl+S saves it. Run in the script manager runs the saved file, and becomes Unload for that running script.
4. Use Script UI above the file list to select a script's custom page. Overlays render every frame. Autoload is opt-in per saved script.

The editor provides Lua syntax colors, line numbers, undo/redo and load-error markers. Unsaved buffers are retained while switching files in the current session. Save as refuses to overwrite a different existing file. Autoload choices are stored in `autoload.txt`; missing files are skipped. Stopping a script removes its pages, windows, owned features and timers. Changing a built-in setting is an explicit persistent setting change; stopping a script does not undo it.

The console retains globals across commands in its own `@console` Lua state. Enter a statement or prefix an expression with `=`. Up/Down recalls the last 100 commands. It can detach into a matching console window. Erroring commands retain the console state. The console counts toward the runtime's 16-state limit. Register pages, events and custom features in a script, not a console command.

```lua
=cs2.info().api_version
=entity.get_local_player()
for _,f in ipairs(settings.list('esp')) do print(f.id,f.type) end
```

Lua language-server metadata for the typed player/vector/settings interfaces is in [/docs/cs2/cs2_v2.lua](/docs/cs2/cs2_v2.lua). Add it to an external editor's library paths; it is metadata, not a runnable script.

## API coverage and porting

The [exported binding index](/docs/cs2/bindings.md) lists every inventoried host and shared global function with editor types. The [reference comparison](/docs/cs2/coverage.md) separates available features from engine APIs not yet exposed. `cs2.capabilities()` lets scripts inspect that distinction. Native hook methods, player/vector/color methods and callback payloads are documented below. Editor metadata is checked against the export registration and real Lua fixture output.

## Console diagnostics

Errors identify the script, phase or callback, source line and Lua stack trace. The console timestamps entries, colors warnings/errors, supports text search and Errors only, and copies the currently visible messages with complete multiline traces. Auto-scroll follows new output only while you are already at the bottom.

A startup/compile failure stops the new script and rolls back its owned resources. A command worker failure discards its edits and disables that worker. HTTP transport errors identify the owning script and request phase; inspect the request result for details. A frame, UI, timer or event failure disables that callback and logs once; other healthy callbacks keep running. Reload to retry. Timer errors include their timer ID. Native-worker errors include the script, target address and traceback and are reported once on the next scripting frame; original behavior is retained. Inspect `hook:status()` for counters and the retained error.

| Message | What to check |
| --- | --- |
| compile / syntax error | Fix the named line; check missing `end`, quotes and parentheses. |
| attempt to index a nil value | Check optional players, bones and lookups before using them; map changes can invalidate data. |
| attempt to call a nil value | Verify spelling and availability. Use `imgui.text`, not `ui.text`. |
| bad argument / context | Check the signature, types, bounds and callback context in the API browser. |
| execution budget | Load/console: 200 ms. Regular callbacks share 8 ms per script per frame. Move setup out of frame callbacks and split repeated work. |
| not enough memory | Each script has a 16 MB Lua quota; reduce retained tables/strings. Native workers have 2 MB. |
| native hook disabled | Inspect its traceback, prototype and callback. Remove and recreate after fixing the source. |

`console.warn`, `console.error` and `console.trace` log developer messages without throwing or disabling the callback. `console.trace` adds the current Lua stack. Use Lua `error(message)` for an actual failure, or `pcall` when the script can recover. Execution budgets cannot interrupt a blocking C++/native call. The bounded console keeps the latest 512 messages; individual messages are capped at 8192 bytes, so extremely long traces can be truncated.

```lua
local function read_preferences()
    local ok, value = pcall(storage.read, 'preferences', {})
    if not ok then
        console.warn('Preferences could not be read: ' .. tostring(value))
        return {}
    end
    return value
end
console.trace('Preferences loaded')
```

## CS2 visual templates

**Standalone Menu** is a floating tools window with F9 as its default open/close key. It includes a speed HUD, center crosshair and real CS2 ESP/box/name switches. **ImGui Demo** keeps the Simple-base UI-v2 panel layout and replaces its placeholder combat settings with custom crosshair sizing, speed HUD, local health ring, projected player labels, rainbow accent and native visual switches. F10 opens/closes its window. Both offer a key selector, Close window and explicit Save preferences. Hiding a window keeps its effects active; Unload removes its callbacks, windows and drawings. Native settings changed with `settings.set` keep their values.

The smaller **Crosshair** and **Speed HUD** scripts are starting templates for custom pages, toggle features, sampled player data and per-frame drawing. Templates skip missing/dead local players and unavailable projections. Distances and speed use Source units. Bundled visual templates never fetch or execute remote Lua. The Download asset template only downloads when the user supplies a URL and clicks its button. The [Aimware v5 collection](https://github.com/ticzz/Aimware-v5-luas) was reviewed as a visual-feature reference; its CSGO scripts are not drop-in CS2 scripts and were not copied into this package.

The manager's Other group contains only Open folder and Refresh. Edit, Run/Unload, Duplicate, Delete and Autoload remain in Script. Clipboard, save and undo tools remain in the editor; custom pages are reached through the browser's Script UI button.

## Runtime contract

The runtime is **Lua 5.4.7**, reused from canonical `simple-base/UI`, with its Lua UI bindings compiled directly from canonical source and its text editor adapted to the native v2 shell. `CS2_API_VERSION` is `2.4`; `UI_API_VERSION` is `1.1`. It is not LuaJIT and is not binary/script compatible with other clients.

Each named script has separate globals, a 16 MB Lua allocator quota and a 1 MB source limit. At most 16 scripts run together. Loading and console evaluation have 200 ms instruction-hook budgets. Each running script has a shared 8 ms callback budget reset each frame, with at most 16 nested callbacks. These are instruction-hook limits, not real-time preemption of native C++ calls. Standard `string`, `table`, `math`, `utf8`, and base language functions are present. `os`, `io`, `package`, `debug`, dynamic `load` and LuaJIT FFI are not exposed. The separate `native` extension exposes integer addresses and typed Win64 calls/hooks.

Ordinary event/UI callbacks run on the rendering thread. Native hook callbacks run in isolated Lua workers on the calling native thread. Keep callbacks short. An error disables the failing callback; reload to re-enable it. A script can register 128 custom features and 32 callbacks per event; the UI layer allows 128 registrations across scripts. Timers allow 64 active entries per script and delays from 0.01 to 86,400 seconds. Missed repeating timer intervals coalesce into one callback; they do not replay a backlog. A timer can cancel itself or create another timer. Stop/reload/failed initialization releases owned resources.

`events.on` returns a token for `events.off`. Register events at load time. `update` runs after input and entity sampling; `render` permits drawing primitives. UI widgets belong inside `ui.tab`, `ui.window`, `ui.overlay`, or nested UI callbacks. The shared drawing layer allows 512 commands per callback (shared across render-event dispatch); additional CS2 draw helpers check a 250,000-vertex frame limit.

## Native functions and hooks (2.2)

The `native` extension (version `1.0`) supports loaded-module discovery, exports, wildcard code scans, guarded reads, relative/vtable resolution, typed function calls and synchronous detours. It uses the fixed Windows x64 ABI with at most 16 scalar arguments: `bool`, `i32`, `u32`, `i64`, `u64`, `ptr`, `float`, `double`; `void` is return-only. A member function takes its explicit object address as its first `ptr`. Lua integers carry addresses exactly. `u64` uses the Lua integer's 64-bit bit pattern, so values above INT64_MAX appear negative. Struct/vector returns, varargs, vectorcall and C++ exceptions are not supported. Function addresses and prototypes must match the installed build; a wrong prototype, invalid object or native function fault can crash the process.

Scanning checks readable executable regions of a loaded module. Space-separated hex bytes and `?`/`??` wildcards are supported, up to 256 bytes; an all-wildcard pattern is rejected. With occurrence zero, missing and ambiguous signatures return `nil,error`. Positive occurrences are one-based. Scans have a 250 ms cap and are intended for script initialization, not every frame. Resolution/export/bind failures return `nil,error`; malformed arguments raise Lua errors. Relative offsets are bounded to 4096; vtable slots are zero-based 0..4095; reads are limited to 4096 bytes and never change page protection.

`native.bind` calls on the current thread; the author must satisfy the function's game-thread and object-lifetime requirements. Hook source must return `function(original, ...)`. The source has its own globals, standard base/string/table/math/utf8 functions, `native.read`, `read_bytes`, `relative`, `vtable`, `bind`, and `shared.get/set`. It cannot capture the parent script's locals or access UI/events/settings. Exchange nil/boolean/integer/finite-number/string values using `hook:get/set` on the parent and `shared.get/set` in the worker. Up to 64 keys of 64 bytes and strings of 1024 bytes are stored per hook.

Native workers have a 2 MB allocator limit, 64 KB source limit, 50 ms initialization budget and a 2 ms/100,000-instruction callback budget. Budget checks cannot interrupt a blocking native call. Recursive entry or a busy worker immediately forwards to the original. An error disables that worker and forwards to the original; if it already called original, the existing result is preserved and native side effects are not repeated. `original(...)` may be called once per invocation. A healthy callback may replace arguments or return without calling original. Failed workers must be removed/recreated. Panic suspends native calls/callbacks at the next scripting frame.

Hooks are owned by the script even if the Lua handle is dropped. `remove`, unload, reload and failed script initialization retire the callback; a callback already in flight is allowed to finish. Other scripts cannot replace or remove its hook. Eight active hooks per script and 128 unique native targets per process are allowed. Retired targets may be reused only with the same prototype. Existing jump-entry detours are rejected instead of stacked. The private hook manager is independent of product hooks. Published pass-through bridges and trampolines remain bounded and resident, and their target/host modules are pinned until process exit so in-flight native calls cannot jump into freed code. Unloading scripts restores original behavior; after using native hooks, restarting the game is required to fully release that native bridge memory.

The bundled **Native hooks** template stays inactive until its pattern and exact prototype are filled in. It demonstrates a scalar-result modifier with a shared multiplier and call status. The ordinary CS2 entity/event API remains a copied/frame-sampled interface; this extension does not invent game signatures or expose a preverified create-move/trace/render ABI.

### native.module

`native.module(name) -> {base,size} or nil,error`

```lua
local module,err=native.module("client.dll")
if module then print(module.base,module.size) end
```

### native.export

`native.export(module,name) -> address or nil,error`

```lua
local address=assert(native.export("kernel32.dll","GetCurrentThreadId"))
```

### native.scan

`native.scan(module,pattern,occurrence=0) -> address or nil,error`

```lua
-- Use an exact, verified signature for the installed game build.
local address,err=native.scan("client.dll",verified_pattern)
-- occurrence=0 requires exactly one match; 1 means first match.
```

### native.relative

`native.relative(address,displacement_offset=1,instruction_length=5) -> address or nil,error`

```lua
-- E8 rel32: resolve the call target.
local target=assert(native.relative(call_address,1,5))
-- RIP-relative LEA/MOV commonly uses offsets 3,7; verify the instruction.
```

### native.vtable

`native.vtable(object_address,zero_based_index) -> address or nil,error`

```lua
local target=assert(native.vtable(object_address,verified_slot))
```

### native.read

`native.read(address,type) -> scalar or nil,error`

```lua
local pointer=assert(native.read(pointer_address,"ptr"))
local value=assert(native.read(pointer+verified_offset,"float"))
```

### native.read_bytes

`native.read_bytes(address,length) -> string or nil,error`

```lua
local bytes=assert(native.read_bytes(verified_address,16))
```

### native.bind

`native.bind(address,signature) -> callable or nil,error`

```lua
local address=assert(native.export("kernel32.dll","GetCurrentThreadId"))
local thread_id=assert(native.bind(address,{abi="win64",returns="u32",args={}}))
print(thread_id())
```

### native.hook

`native.hook(address,signature,callback_source) -> hook or nil,error`

```lua
local hook=assert(native.hook(verified_address,
  {abi="win64",returns="float",args={"ptr"}}, [[
    return function(original,self)
      return original(self)*(shared.get("multiplier") or 1)
    end
  ]]))
hook:set("multiplier",1.1)
```

### native.enable

`hook:enable(boolean)`

```lua
hook:enable(false) -- pass through
hook:enable(true) -- resume a healthy callback
```

### native.remove

`hook:remove()`

```lua
hook:remove() -- idempotent; also done on unload/reload/load failure
```

### native.set

`hook:set(key,scalar_or_nil)`

```lua
hook:set("multiplier",1.25) -- worker reads shared.get("multiplier")
```

### native.get

`hook:get(key) -> scalar or nil`

```lua
local calls=hook:get("samples") -- worker writes shared.set("samples",count)
```

### native.status

`hook:status() -> {enabled,removed,calls,bypassed,errors,error,address}`

```lua
local status=hook:status()
print(status.calls,status.bypassed,status.error)
```

## Entity data and events

`entity.get_local_player()`, `entity.get(full_handle)` and `entity.get_players(enemies_only,alive_only)` return **copied player snapshots**. These snapshots do not contain live memory addresses; native discovery is a separate explicit API. `get` takes the full pawn handle including its serial, not the player index. Snapshots retained in Lua stay unchanged; call `p:refresh()` for the current frame or `p:is_valid()` to check the handle still exists. A missing player, bone, weapon or screen projection returns `nil`. Positions, distances and velocities use Source world units; angles use degrees. UI coordinates and text sizes use framebuffer pixels; `render.scale()` reports the menu scale.

A player snapshot contains:

- `index`, `handle`, `name`, `sample_frame`, `health`, `armor`, `team`, `ping`, `flags`, `flash_duration`.
- `is_local`, `enemy`, `alive`, `scoped`, `crouched`, `defusing`, `helmet`, `defuser`, `immune`.
- `origin`, `eye_position`, `velocity` as vectors; `weapon` as a copied table or nil.

A weapon snapshot contains `handle`, `definition_index`, `ammo`, `zoom`, and `reloading`. The bone API revalidates the controller's current full pawn handle and reads the existing animated-bone implementation; it never manufactures a pose. Bone indices range from 0 to 127. Player enumeration is limited to the existing 64 controller slots.

| Event | Arguments | Timing |
| --- | --- | --- |
| `update` | none | Each rendered frame while scripts are running |
| `render` | none | Drawing phase, including the alternate stream-overlay path |
| `shutdown` | none | Stop or reload of a running script |
| `session_start`, `session_end` | none | Local player availability changes between samples |
| `player_health_changed` | current, previous player snapshots | Same full handle has different sampled health |
| `player_died`, `player_spawned` | current, previous snapshots | Same full handle changes sampled alive state |
| `local_weapon_changed` | current, previous snapshots | Local player's sampled weapon handle changes |

The CS2 state-change events are **frame comparisons, not native server game events**. Changes between samples can be missed. First appearance of a handle establishes a baseline. Respawn with a new handle also establishes a baseline; it does not infer a spawn event. There is no attacker, damage cause, round-event hook, create-move command editing, bullet trace or native render-material API in this version. Entity memory reads, bones, native projection and timing still require live-game validation on the current CS2 build.

## Settings, controls and theme

`settings.list(filter)` exposes the actual CS2 registry IDs and metadata: ID, name, type, tab, group, range, choices and value. For example the master ESP ID is **`espEnabled`**. IDs are preserved from v2. `settings.set` checks the actual type and range, rejects nonfinite values, and marks the native configuration dirty. Dropdown setting values are zero-based; `ui.combo` uses Lua-style one-based indices. Color settings use normalized RGBA/RGB arrays.

`features.get/set/list` operate on boolean host settings and script-owned toggle/action features. `features.add` returns `lua.<script name>.<local id>`. `features.bind` and `ui.keybind` use the scripting runtime's binding state; `features.active` evaluates that state. Toggle bindings update the boolean setting; hold modes are queried by scripts through `features.active`. They do not rewrite existing product hotkey definitions. `features.color` is script feature metadata. Persist custom values explicitly with `storage`; they are recreated on reload.

Custom pages and subtabs are available through the **Script UI** selector. Tab `section` and `icon` metadata are accepted but do not add product-sidebar sections. Page overrides are limited to `lua/scripts`, `lua/editor`, `lua/console`, `lua/ui`, and `lua/api`. `ui.feature_visible` affects rows rendered through `ui.feature` or Custom features; it does not hide controls in built-in CS2 pages. `ui.tr` currently returns the supplied text. `esp_colors.available()` is false because v2 has its own native color registry; use `settings` for its actual color settings. Other inherited `esp_colors` operations return missing capability values or errors, rather than writing a disconnected color model.

Use `render.theme()` for accent, text, muted, panel and border colors. The native widget adapter follows the product palette. `ui.theme`/`reset_theme` and `imgui.with_style` customize standard ImGui controls/windows inside script rendering; they do not replace native product palette tokens. Script-created windows can attach to the left/right of the menu and optionally follow its visibility. Visible interactive Lua windows also receive the cursor when the main menu is closed, using the same Block Input policy as detached product windows. Closing or unloading the last script window releases that ownership; drawing-only overlays do not capture input.

## Storage

`storage` reads/writes JSON values and `files` reads/writes binary-safe strings in a per-script directory: `scripts/data/<UTF-8 script name encoded as hex>/`. Keys are simple filenames; paths, device names and traversal are rejected. Writes replace the file atomically. Each write is limited to 64 KB. JSON conversion permits up to 16 nested levels and 16,384 visited values. Lua arrays must have integer keys; objects must have string keys. Plain empty tables encode as objects. `json.array()` and `json.object()` preserve explicit container types, including decoded empty arrays. JSON null decodes to Lua nil by default; pass `true` as the second argument to `json.decode` or third argument to `storage.read` to preserve it as `json.null`. Signed 64-bit integers round-trip exactly; JSON integers above INT64_MAX are rejected. Nonfinite numbers are rejected. Strings and object keys preserve embedded null bytes; JSON still requires valid UTF-8 strings. Cyclic tables and unsupported value types are errors. Renaming a script gives it a different data namespace.

## Geometry and drawing additions (2.1)

`vector2(x,y)` provides 2D arithmetic and copy-returning geometry helpers. `rect(x0,y0,x1,y1)` takes top-left and bottom-right bounds; inverted bounds are rejected. Point containment includes edges; overlap/intersection require positive area, and disjoint rectangles return nil from `intersect`. Rectangle transforms return new objects.

`colors.from_hex` accepts RGB/RGBA short and long hex strings with an optional `#`. HSV hue uses degrees and wraps around 360; saturation, value, alpha and the existing `color` array components stay in 0..1. Helpers return independent values. These additions were informed by the [Fatality Vec2](https://lua2.fatality.win/api/instances/draw/types/vec2), [rectangle](https://lua2.fatality.win/api/instances/draw/types/rect) and [color](https://lua2.fatality.win/api/instances/draw/types/color) references; CS2 retains its own names and normalized color format.

`render.screen_size()` reports framebuffer dimensions. `render.world_to_screen` accepts either three coordinates or a vector, preserving its x,y-or-nil result. `render.arc` uses degrees, a 0..4096 radius, a signed span up to 360 degrees, and 3..256 segments. `render.bezier` draws a cubic through two endpoints and two control points, using 3..256 segments. Both accept thickness greater than 0 and up to 20, require a frame callback and respect the existing vertex limit. `mathx.normalize_angle` returns [-180,180); tick/time conversion uses the sampled game interval, rounds seconds to the nearest tick (half away from zero), and rejects unavailable intervals or counts beyond +/-1e9. The disconnected default interval is 1/64 second.

## Reference design

The event/render/entity organization was informed by [Neverlose events](https://docs-csgo.neverlose.cc/documentation/events), [Neverlose entities](https://docs-csgo.neverlose.cc/documentation/variables/entity), [Fatality script UI](https://lua2.fatality.win/introduction/creating-scripts/adding-ui), and [Fatality entities](https://lua2.fatality.win/api/instances/entities/entitylist_t). The implementation uses the local Simple-base runtime and actual v2 host contracts. The [upstream Simple-base snapshot](/docs/cs2/ui-api.md) is provenance, not the v2 compatibility contract.

## Function reference

The following signatures and examples are generated from the same entries used by the in-app API browser. UI examples that only contain a control belong inside a UI callback. `p`, `id`, `token`, and `timer_id` denote previously obtained objects.

### vector2

```text
vector2(x=0,y=x) -> vector2
```

```lua
local p=vector2(30,40)
print(p:length(),p:normalized():unpack())
```

### rect

```text
rect(x0=0,y0=0,x1=0,y1=0) -> rectangle
```

```lua
local panel=rect(20,20,220,100)
print(panel:width(),panel:height(),panel:center():unpack())
```

### colors.from_hex

```text
colors.from_hex('#RGB|RGBA|RRGGBB|RRGGBBAA') -> color (0..1)
```

```lua
local accent=colors.from_hex('#479cff')
print(accent:alpha(.5):to_hex())
```

### colors.from_hsv

```text
colors.from_hsv(hue_degrees,saturation,value,alpha=1) -> color
```

```lua
local accent=colors.from_hsv(210,.8,1,.9)
```

### colors.to_hsv

```text
colors.to_hsv(rgba) -> hue_degrees,saturation,value,alpha
```

```lua
local h,s,v,a=colors.to_hsv(render.theme().accent)
local copy=colors.from_hsv(h,s,v,a)
```

### vector2.clone

```text
v:clone() -> vector2
```

```lua
local v=vector2(3,4)
local result=v:clone()
```

### vector2.unpack

```text
v:unpack() -> x,y
```

```lua
local v=vector2(3,4)
local result=v:unpack()
```

### vector2.length

```text
v:length() -> number
```

```lua
local v=vector2(3,4)
local result=v:length()
```

### vector2.length_sqr

```text
v:length_sqr() -> number
```

```lua
local v=vector2(3,4)
local result=v:length_sqr()
```

### vector2.normalized

```text
v:normalized() -> vector2
```

```lua
local v=vector2(3,4)
local result=v:normalized()
```

### vector2.dot

```text
v:dot(other) -> number
```

```lua
local v=vector2(3,4)
local result=v:dot(vector2(2,1))
```

### vector2.distance

```text
v:distance(other) -> number
```

```lua
local v=vector2(3,4)
local result=v:distance(vector2(2,1))
```

### vector2.lerp

```text
v:lerp(other,t) -> vector2
```

```lua
local v=vector2(3,4)
local result=v:lerp(vector2(2,1),.5)
```

### vector2.floor

```text
v:floor() -> vector2
```

```lua
local v=vector2(3,4)
local result=v:floor()
```

### vector2.ceil

```text
v:ceil() -> vector2
```

```lua
local v=vector2(3,4)
local result=v:ceil()
```

### vector2.round

```text
v:round() -> vector2
```

```lua
local v=vector2(3,4)
local result=v:round()
```

### rect.clone

```text
r:clone() -> rectangle
```

```lua
local r=rect(20,20,220,100)
local result=r:clone()
```

### rect.width

```text
r:width() -> number
```

```lua
local r=rect(20,20,220,100)
local result=r:width()
```

### rect.height

```text
r:height() -> number
```

```lua
local r=rect(20,20,220,100)
local result=r:height()
```

### rect.size

```text
r:size() -> vector2
```

```lua
local r=rect(20,20,220,100)
local result=r:size()
```

### rect.center

```text
r:center() -> vector2
```

```lua
local r=rect(20,20,220,100)
local result=r:center()
```

### rect.contains

```text
r:contains(point_or_rect) -> boolean
```

```lua
local r=rect(20,20,220,100)
local result=r:contains(vector2(30,40))
```

### rect.overlaps

```text
r:overlaps(other) -> boolean
```

```lua
local r=rect(20,20,220,100)
local result=r:overlaps(rect(0,0,100,100))
```

### rect.intersect

```text
r:intersect(other) -> rectangle or nil (no positive-area intersection)
```

```lua
local r=rect(20,20,220,100)
local result=r:intersect(rect(0,0,100,100))
```

### rect.translate

```text
r:translate(delta) -> rectangle
```

```lua
local r=rect(20,20,220,100)
local result=r:translate(vector2(10,20))
```

### rect.expand

```text
r:expand(amount) -> rectangle
```

```lua
local r=rect(20,20,220,100)
local result=r:expand(4)
```

### rect.shrink

```text
r:shrink(amount) -> rectangle
```

```lua
local r=rect(20,20,220,100)
local result=r:shrink(4)
```

### color.clone

```text
c:clone() -> color
```

```lua
local c=color(.2,.6,1)
local result=c:clone()
```

### color.to_hsv

```text
c:to_hsv() -> hue_degrees,saturation,value,alpha
```

```lua
local c=color(.2,.6,1)
local result=c:to_hsv()
```

### render.screen_size

```text
render.screen_size() -> width,height
```

```lua
local width,height=render.screen_size()
```

### render.arc

```text
render.arc(x,y,radius,start_degrees,end_degrees,color,thickness=1,segments=48)
```

```lua
events.on('render',function()
  render.arc(90,90,30,-90,180,color(.2,.7,1),3)
end)
```

### render.bezier

```text
render.bezier(x1,y1,x2,y2,x3,y3,x4,y4,color,thickness=1,segments=32)
```

```lua
events.on('render',function()
  render.bezier(20,90,60,10,120,10,160,90,color(1,.5,.2),2)
end)
```

### mathx.normalize_angle

```text
mathx.normalize_angle(degrees) -> [-180,180)
```

```lua
print(mathx.normalize_angle(270))
```

### mathx.seconds_to_ticks

```text
mathx.seconds_to_ticks(seconds) -> nearest integer tick count
```

```lua
local ticks=mathx.seconds_to_ticks(.5)
```

### mathx.ticks_to_seconds

```text
mathx.ticks_to_seconds(integer_ticks) -> seconds
```

```lua
local seconds=mathx.ticks_to_seconds(32)
```

### cs2.info

```text
cs2.info() -> table
```

```lua
print(json.encode(cs2.info()))
```

### cs2.connected

```text
cs2.connected() -> boolean
```

```lua
if cs2.connected() then print(cs2.map_name()) end
```

### cs2.map_name

```text
cs2.map_name() -> string
```

```lua
print(cs2.map_name())
```

### cs2.clock

```text
cs2.clock() -> {curtime,tick,interval,realtime,frame}
```

```lua
local tick = cs2.clock().tick
```

### cs2.view_angles

```text
cs2.view_angles() -> vector or nil
```

```lua
local angles = cs2.view_angles()
```

### entity.get_local_player

```text
entity.get_local_player() -> player or nil
```

```lua
local me = entity.get_local_player()
```

### entity.get_players

```text
entity.get_players(enemies_only=false, alive_only=false) -> players
```

```lua
for _,p in ipairs(entity.get_players(true,true)) do print(p.name,p.health) end
```

### entity.get

```text
entity.get(full_handle) -> player or nil
```

```lua
local current = entity.get(saved_handle)
```

### entity.bone

```text
entity.bone(full_handle, bone_index) -> vector or nil
```

```lua
local head = entity.bone(player.handle,6)
```

### entity.weapon

```text
entity.weapon(full_handle) -> weapon snapshot or nil
```

```lua
local gun = entity.weapon(player.handle)
```

### settings.get

```text
settings.get(feature_id) -> value
```

```lua
print(settings.get('espEnabled'))
```

### settings.set

```text
settings.set(feature_id, value)
```

```lua
settings.set('espEnabled',true)
```

### settings.list

```text
settings.list(filter='') -> metadata[]
```

```lua
for _,f in ipairs(settings.list('esp')) do print(f.id,f.type) end
```

### settings.info

```text
settings.info(feature_id) -> metadata or nil
```

```lua
print(json.encode(settings.info('espEnabled')))
```

### input.is_key_down

```text
input.is_key_down(vk_code) -> boolean
```

```lua
local held = input.is_key_down(0x56)
```

### input.is_key_pressed

```text
input.is_key_pressed(vk_code) -> boolean
```

```lua
if input.is_key_pressed(0x56) then print('V') end
```

### input.mouse_position

```text
input.mouse_position() -> x,y
```

```lua
local x,y=input.mouse_position()
```

### input.menu_open

```text
input.menu_open() -> boolean
```

```lua
local editing=input.menu_open()
```

### timers.after

```text
timers.after(seconds, callback) -> id
```

```lua
timers.after(2,function() print('ready') end)
```

### timers.every

```text
timers.every(seconds, callback) -> id
```

```lua
local id=timers.every(1,function() print(cs2.clock().tick) end)
```

### timers.cancel

```text
timers.cancel(id) -> boolean
```

```lua
timers.cancel(timer_id)
```

### storage.read

```text
storage.read(key, fallback=nil, preserve_null=false) -> value
```

```lua
local prefs=storage.read('preferences',{enabled=true})
```

### storage.write

```text
storage.write(key, JSON-compatible value)
```

```lua
storage.write('preferences',{enabled=true})
```

### storage.delete

```text
storage.delete(key)
```

```lua
storage.delete('preferences')
```

### files.read

```text
files.read(name) -> string or nil
```

```lua
local text=files.read('notes')
```

### files.write

```text
files.write(name, text)
```

```lua
files.write('notes','hello')
```

### files.list

```text
files.list() -> names[]
```

```lua
for _,name in ipairs(files.list()) do print(name) end
```

### json.encode

```text
json.encode(value) -> string
```

```lua
print(json.encode({health=100}))
```

### json.decode

```text
json.decode(text, preserve_null=false) -> value
```

```lua
local value=json.decode('{"health":100}')
```

### render.world_to_screen

```text
render.world_to_screen(x,y,z) or render.world_to_screen(vector) -> x,y or nil
```

```lua
local x,y=render.world_to_screen(p.origin.x,p.origin.y,p.origin.z)
```

### render.measure_text

```text
render.measure_text(text,size=14) -> width,height
```

```lua
local w,h=render.measure_text('CS2',14)
```

### render.gradient

```text
render.gradient(x,y,w,h,rgba_top,rgba_bottom)
```

```lua
render.gradient(20,20,160,40,{.2,.6,.8,1},{.1,.1,.1,1})
```

### render.triangle

```text
render.triangle(x1,y1,x2,y2,x3,y3,color,filled=true)
```

```lua
render.triangle(20,20,40,20,30,40,{1,1,1,1})
```

### render.polyline

```text
render.polyline({{x,y},...},color,thickness=1,closed=false)
```

```lua
render.polyline({{10,10},{30,30},{50,10}},{1,1,1,1})
```

### render.theme

```text
render.theme() -> {accent,text,muted,panel,border}
```

```lua
local colors=render.theme()
```

### render.scale

```text
render.scale() -> number
```

```lua
local scale=render.scale()
```

### console.log

```text
console.log(text)
```

```lua
console.log('Script loaded')
```

### console.clear

```text
console.clear()
```

```lua
console.clear()
```

### script.name

```text
script.name() -> string
```

```lua
print(script.name())
```

### mathx.distance

```text
mathx.distance(x1,y1,z1,x2,y2,z2) -> number
```

```lua
local d=mathx.distance(0,0,0,3,4,0)
```

### mathx.calc_angle

```text
mathx.calc_angle(x1,y1,z1,x2,y2,z2) -> vector
```

```lua
local angles=mathx.calc_angle(0,0,0,100,100,0)
```

### mathx.angle_fov

```text
mathx.angle_fov(pitch,yaw,target_pitch,target_yaw) -> number
```

```lua
local fov=mathx.angle_fov(0,0,10,20)
```

### mathx.clamp

```text
mathx.clamp(value,min,max) -> number
```

```lua
local hp=mathx.clamp(player.health,0,100)
```

### mathx.lerp

```text
mathx.lerp(a,b,t) -> number
```

```lua
local alpha=mathx.lerp(0,1,.5)
```

### mathx.remap

```text
mathx.remap(value,in_min,in_max,out_min,out_max) -> number
```

```lua
local width=mathx.remap(player.health,0,100,0,160)
```

### features.add

```text
features.add({id,label,category,description,default,kind,key,on_trigger}) -> feature_id
```

```lua
local id=features.add{id='my_feature',label='My feature',default=true}
ui.tab('controls','Controls',function() ui.feature(id); ui.keybind(id) end)
```

### features.get

```text
features.get(id) -> boolean or nil
```

```lua
print(features.get('espEnabled'))
```

### features.set

```text
features.set(id, boolean)
```

```lua
features.set('espEnabled',true)
```

### features.active

```text
features.active(id) -> boolean
```

```lua
local active=features.active('espEnabled')
```

### features.trigger

```text
features.trigger(id)
```

```lua
local action=features.add{id='hello',kind='action',on_trigger=function()print('hello')end}
features.trigger(action)
```

### features.list

```text
features.list() -> entries[]
```

```lua
for _,f in ipairs(features.list()) do print(f.id,f.label) end
```

### features.bind

```text
features.bind(id, key, mode)
```

```lua
features.bind('espEnabled','F7','toggle')
```

### features.color

```text
features.color(id, r, g, b, a)
```

```lua
local id=features.add{id='my_feature'}
features.color(id,.3,.6,.8,1)
```

### base.get

```text
base.get(id) -> boolean or nil
```

```lua
print(base.get('espEnabled'))
```

### base.set

```text
base.set(id, boolean)
```

```lua
base.set('espEnabled',true)
```

### base.log

```text
base.log(...)
```

```lua
base.log('Ready',CS2_API_VERSION)
```

### events.on

```text
events.on(event_name, callback) -> token
```

```lua
local token
token=events.on('update',function() print(cs2.clock().tick); events.off(token) end)
```

### events.off

```text
events.off(token)
```

```lua
events.off(token)
```

### events.names

```text
update | render | shutdown | session_start | session_end | player_health_changed | player_died | player_spawned | local_weapon_changed
```

```lua
events.on('player_health_changed',function(now,previous) print(now.name,previous.health,now.health) end)
```

### ui.tab

```text
ui.tab(id,label,callback,options={}) -> page_id
```

```lua
ui.tab('my_page','My page',function() imgui.text('Hello') end)
```

### ui.subtab

```text
ui.subtab(parent_page_id,id,label,callback) -> page_id
```

```lua
local page=ui.tab('tools','Tools')
ui.subtab(page,'status','Status',function()imgui.text('Ready')end)
```

### ui.overlay

```text
ui.overlay(id,callback) -> id
```

```lua
ui.overlay('label',function()render.text(20,20,'Hello',render.theme().text)end)
```

### ui.window

```text
ui.window(id,title,{width,height,attach,menu_only},callback) -> id
```

```lua
ui.window('status','Status',{width=320,height=200,attach='right',menu_only=true},function()imgui.text('Hello')end)
```

### ui.override

```text
ui.override("lua/scripts" | "lua/editor" | "lua/console" | "lua/ui" | "lua/api",callback)
```

```lua
ui.override('lua/console',function()imgui.text('Custom console page')end)
```

### ui.theme

```text
ui.theme({rounding,alpha,colors={Text=rgba,...}})
```

```lua
ui.theme{rounding=5,colors={Text={.9,.95,1,1}}}
```

### ui.reset_theme

```text
ui.reset_theme()
```

```lua
ui.reset_theme()
```

### ui.tr

```text
ui.tr(text) -> text
```

```lua
imgui.text(ui.tr('Ready'))
```

### ui.feature

```text
ui.feature(feature_id)
```

```lua
ui.tab('controls','Controls',function()ui.feature('espEnabled')end)
```

### ui.keybind

```text
ui.keybind(feature_id,label="Key")
```

```lua
ui.tab('keys','Keys',function()ui.keybind('espEnabled','ESP key')end)
```

### ui.feature_visible

```text
ui.feature_visible(feature_id,visible)
```

```lua
ui.feature_visible('espEnabled',false)
```

### ui.menu_visible

```text
ui.menu_visible(visible?) -> boolean
```

```lua
local open=ui.menu_visible()
```

### ui.window_visible

```text
ui.window_visible(window_id,visible)
```

```lua
local id=ui.window('x','X',{},function()imgui.text('X')end)
ui.window_visible(id,false)
```

### ui.entity_colors

```text
ui.entity_colors() -> false
```

```lua
local available=ui.entity_colors()
```

### ui.group

```text
ui.group(label,callback)
```

```lua
ui.group('Settings',function() imgui.text('Content') end)
```

### ui.columns

```text
ui.columns(count,callback,stagger=false)
```

```lua
ui.columns(2,function()imgui.text('Left');ui.next_column();imgui.text('Right')end)
```

### ui.next_column

```text
ui.next_column()
```

```lua
ui.next_column()
```

### ui.slider

```text
ui.slider(label,value,min,max) -> changed,value
```

```lua
local changed,value=ui.slider('Scale',1,.5,2)
```

### ui.slider_int

```text
ui.slider_int(label,value,min,max) -> changed,value
```

```lua
local changed,value=ui.slider_int('Count',5,1,20)
```

### ui.toggle

```text
ui.toggle(label,value) -> changed,value
```

```lua
local changed,value=ui.toggle('Enabled',true)
```

### ui.button

```text
ui.button(label,width=0,height=0) -> clicked
```

```lua
if ui.button('Print') then print('clicked') end
```

### ui.selectable

```text
ui.selectable(label,selected,width=0,height=0) -> clicked
```

```lua
if ui.selectable('Item',false) then print('selected') end
```

### ui.combo

```text
ui.combo(label,index,labels) -> changed,index (1-based)
```

```lua
local changed,index=ui.combo('Mode',1,{'A','B'})
```

### ui.multi_combo

```text
ui.multi_combo(label,selected[],labels[]) -> changed,selected[]
```

```lua
local changed,selected=ui.multi_combo('Flags',{true,false},{'A','B'})
```

### imgui.text

```text
imgui.text(text)
```

```lua
imgui.text('Hello')
```

### imgui.text_colored

```text
imgui.text_colored(text,rgba)
```

```lua
imgui.text_colored('Hello',{.3,.7,1,1})
```

### imgui.button

```text
imgui.button(label,width=0,height=0) -> clicked
```

```lua
local clicked=imgui.button('Apply')
```

### imgui.checkbox

```text
imgui.checkbox(label,value) -> changed,value
```

```lua
local changed,enabled=imgui.checkbox('Enabled',true)
```

### imgui.slider_float

```text
imgui.slider_float(label,value,min,max) -> changed,value
```

```lua
local changed,v=imgui.slider_float('Value',1,0,10)
```

### imgui.slider_int

```text
imgui.slider_int(label,value,min,max) -> changed,value
```

```lua
local changed,v=imgui.slider_int('Count',1,0,10)
```

### imgui.input_text

```text
imgui.input_text(label,text) -> changed,text
```

```lua
local changed,text=imgui.input_text('Name','example')
```

### imgui.combo

```text
imgui.combo(label,index,labels) -> changed,index
```

```lua
local changed,index=imgui.combo('Mode',1,{'A','B'})
```

### imgui.color_edit

```text
imgui.color_edit(label,rgba) -> changed,rgba
```

```lua
local changed,c=imgui.color_edit('Color',{1,1,1,1})
```

### imgui.same_line

```text
imgui.same_line(spacing=-1)
```

```lua
imgui.same_line()
```

### imgui.separator

```text
imgui.separator()
```

```lua
imgui.separator()
```

### imgui.spacing

```text
imgui.spacing(height=4)
```

```lua
imgui.spacing(8)
```

### imgui.tooltip

```text
imgui.tooltip(text)
```

```lua
imgui.tooltip('Details')
```

### imgui.progress

```text
imgui.progress(fraction)
```

```lua
imgui.progress(.75)
```

### imgui.child

```text
imgui.child(id,width,height,callback)
```

```lua
imgui.child('content',0,160,function()imgui.text('Child')end)
```

### imgui.window

```text
imgui.window(title,{width,height},callback)
```

```lua
imgui.window('Tools',{width=320,height=200},function()imgui.text('Hello')end)
```

### imgui.disabled

```text
imgui.disabled(disabled,callback)
```

```lua
imgui.disabled(true,function()ui.button('Disabled')end)
```

### imgui.with_style

```text
imgui.with_style(colors,callback)
```

```lua
imgui.with_style({Text={1,.7,.3,1}},function()imgui.text('Amber')end)
```

### imgui.available

```text
imgui.available() -> width,height
```

```lua
local w,h=imgui.available()
```

### imgui.cursor

```text
imgui.cursor() -> screen_x,screen_y
```

```lua
local x,y=imgui.cursor()
```

### imgui.set_cursor

```text
imgui.set_cursor(local_x,local_y)
```

```lua
imgui.set_cursor(20,20)
```

### imgui.is_item_hovered

```text
imgui.is_item_hovered() -> boolean
```

```lua
if imgui.is_item_hovered() then print('hovered') end
```

### render.text

```text
render.text(x,y,text,rgba,size=13)
```

```lua
render.text(20,20,'CS2',{1,1,1,1},14)
```

### render.line

```text
render.line(x1,y1,x2,y2,rgba,thickness=1)
```

```lua
render.line(20,20,120,20,{1,1,1,1},2)
```

### render.rect

```text
render.rect(x,y,width,height,rgba,filled=false,rounding=0)
```

```lua
render.rect(20,20,100,50,{.1,.2,.3,1},true,5)
```

### render.circle

```text
render.circle(x,y,radius,rgba,filled=false,thickness=1)
```

```lua
render.circle(100,100,20,{1,1,1,1})
```

### engine.time

```text
engine.time() -> seconds since ImGui start
```

```lua
print(engine.time())
```

### engine.delta_time

```text
engine.delta_time() -> frame seconds
```

```lua
print(engine.delta_time())
```

### engine.fps

```text
engine.fps() -> ImGui average FPS
```

```lua
print(engine.fps())
```

### engine.viewport

```text
engine.viewport() -> width,height in pixels
```

```lua
print(engine.viewport())
```

### vector

```text
vector(x=0,y=0,z=0) -> vector
```

```lua
local position=vector(3,4,0)
print(position:length(),(position*2):unpack())
```

### vector:clone

```text
v:clone()
```

```lua
local v=vector(3,4,0)
print(v:clone())
```

### vector:unpack

```text
v:unpack()
```

```lua
local v=vector(3,4,0)
print(v:unpack())
```

### vector:length

```text
v:length()
```

```lua
local v=vector(3,4,0)
print(v:length())
```

### vector:length_sqr

```text
v:length_sqr()
```

```lua
local v=vector(3,4,0)
print(v:length_sqr())
```

### vector:length2d

```text
v:length2d()
```

```lua
local v=vector(3,4,0)
print(v:length2d())
```

### vector:normalized

```text
v:normalized()
```

```lua
local v=vector(3,4,0)
print(v:normalized())
```

### vector:dot

```text
v:dot(other)
```

```lua
local v=vector(3,4,0)
print(v:dot(vector(1,0,0)))
```

### vector:cross

```text
v:cross(other)
```

```lua
local v=vector(3,4,0)
print(v:cross(vector(1,0,0)))
```

### vector:distance

```text
v:distance(other)
```

```lua
local v=vector(3,4,0)
print(v:distance(vector(1,0,0)))
```

### vector:lerp

```text
v:lerp(other,t)
```

```lua
local v=vector(3,4,0)
print(v:lerp(vector(1,0,0),.5))
```

### color

```text
color(r=1,g=1,b=1,a=1) -> RGBA table
```

```lua
local accent=color(.3,.6,.8,1)
```

### color:unpack

```text
c:unpack()
```

```lua
print(color(.3,.6,.8):unpack())
```

### color:alpha

```text
c:alpha(a)
```

```lua
local translucent=color(.3,.6,.8):alpha(.5)
```

### color:lerp

```text
c:lerp(other,t)
```

```lua
local mixed=color(0,0,0):lerp(color(1,1,1),.5)
```

### color:to_hex

```text
c:to_hex()
```

```lua
print(color(1,.5,0):to_hex())
```

### player:get_name

```text
p:get_name()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_name()) end
```

### player:get_origin

```text
p:get_origin()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_origin()) end
```

### player:get_eye_position

```text
p:get_eye_position()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_eye_position()) end
```

### player:get_velocity

```text
p:get_velocity()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_velocity()) end
```

### player:get_health

```text
p:get_health()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_health()) end
```

### player:get_armor

```text
p:get_armor()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_armor()) end
```

### player:is_alive

```text
p:is_alive()
```

```lua
local p=entity.get_local_player()
if p then print(p:is_alive()) end
```

### player:is_enemy

```text
p:is_enemy()
```

```lua
local p=entity.get_local_player()
if p then print(p:is_enemy()) end
```

### player:get_weapon

```text
p:get_weapon()
```

```lua
local p=entity.get_local_player()
if p then print(p:get_weapon()) end
```

### player:get_bone

```text
p:get_bone(index)
```

```lua
local p=entity.get_local_player()
if p then print(p:get_bone(6)) end
```

### player:is_valid

```text
p:is_valid()
```

```lua
local p=entity.get_local_player()
if p then print(p:is_valid()) end
```

### player:refresh

```text
p:refresh()
```

```lua
local p=entity.get_local_player()
if p then print(p:refresh()) end
```

### esp_colors.available

```text
esp_colors.available() -> false
```

```lua
print(esp_colors.available())
```


## Shared UI API 1.1 synchronization

`imgui.*` provides native ImGui controls, scoped layouts, tables, font/style changes, input/hit targets and custom popup contents. `draw.*` draws in the current window. `widgets.*` and `ui.widgets.*` explicitly select CS2's existing widget adapter; legacy `ui.*` calls remain available. Native sliders optionally accept `{style="track"}` for slim tracks and editable values. See the [canonical complete reference](/docs/cs2/ui-api.md). The in-product API search includes all shared code examples.

The `third_party/simple_base/src/ui/lua_ui.*` files forward to canonical bindings. CS2 keeps its Lua runtime extensions, game APIs, events, console, storage, page-override rules and ImGui 1.91.8. MSBuild runs `tools/sync_lua_api.py` before compilation to embed the current docs/examples under `build/generated/shared_lua`. Rebuild and restart the host to activate updates. No background synchronization service, user-script overwrite or automatic deployment is involved.

## Utilities, animation and lossless JSON (2.3)

Binary utilities accept at most 64 KB of decoded data. Base64 uses the standard alphabet and requires canonical padding without whitespace. Hex accepts upper/lowercase pairs. `utils.from_bytes` requires a dense array of bytes 0..255; embedded zero bytes survive all conversions. FNV-1a is a noncryptographic 32-bit hash. `files.exists` and `files.delete` use the same script-specific directory and filename rules as reads/writes.

Animation helpers use degrees for angles and seconds for damping. `mathx.damp` uses exponential interpolation so the same elapsed time gives the same result at different frame rates for a fixed target. Approach functions clamp the step; angular helpers take the shortest arc. `mathx.ease` supports linear, in/out/in_out quad, cubic and sine curves. Smoothstep/easing clamp progress to 0..1. Math inputs must be finite and within +/-1e9.

```lua
local data = json.decode('[9223372036854775807,null,[]]', true)
assert(data[2] == json.null)
assert(json.encode(data) == '[9223372036854775807,null,[]]')
local alpha = 0
ui.overlay('smooth_status', function()
    alpha = mathx.damp(alpha, 1, 8)
    render.text(24, 100, 'Ready', color(1,1,1,alpha), 16)
end)
```

### cs2.capabilities

```lua
cs2.capabilities() -> table
```

```lua
print(json.encode(cs2.capabilities()))
```

### utils.base64_encode

```lua
utils.base64_encode(bytes) -> string
```

```lua
print(utils.base64_encode("hello"))
```

### utils.base64_decode

```lua
utils.base64_decode(text) -> bytes
```

```lua
print(utils.base64_decode("aGVsbG8="))
```

### utils.hex_encode

```lua
utils.hex_encode(bytes) -> lowercase hex
```

```lua
print(utils.hex_encode("hello"))
```

### utils.hex_decode

```lua
utils.hex_decode(hex) -> bytes
```

```lua
print(utils.hex_decode("68656c6c6f"))
```

### utils.to_bytes

```lua
utils.to_bytes(string) -> byte[]
```

```lua
local bytes=utils.to_bytes("hello")
```

### utils.from_bytes

```lua
utils.from_bytes(byte[]) -> string
```

```lua
print(utils.from_bytes({72,105,0}))
```

### utils.fnv1a

```lua
utils.fnv1a(bytes) -> unsigned 32-bit integer
```

```lua
print(utils.fnv1a("hello"))
```

### utils.unix_time

```lua
utils.unix_time() -> integer seconds since Unix epoch
```

```lua
print(utils.unix_time())
```

### mathx.approach

```lua
mathx.approach(current,target,max_step) -> number
```

```lua
print(mathx.approach(0,10,2))
```

### mathx.approach_angle

```lua
mathx.approach_angle(current,target,max_degrees) -> [-180,180)
```

```lua
print(mathx.approach_angle(170,-170,5))
```

### mathx.lerp_angle

```lua
mathx.lerp_angle(current,target,t) -> [-180,180)
```

```lua
print(mathx.lerp_angle(170,-170,.5))
```

### mathx.remap_clamped

```lua
mathx.remap_clamped(value,in_min,in_max,out_min,out_max) -> number
```

```lua
print(mathx.remap_clamped(150,0,100,0,1))
```

### mathx.smoothstep

```lua
mathx.smoothstep(t) -> [0,1]
```

```lua
print(mathx.smoothstep(.5))
```

### mathx.smootherstep

```lua
mathx.smootherstep(t) -> [0,1]
```

```lua
print(mathx.smootherstep(.5))
```

### mathx.damp

```lua
mathx.damp(current,target,rate,dt=engine.delta_time()) -> number
```

```lua
local next_value=mathx.damp(0,1,8,1/60)
```

### mathx.ease

```lua
mathx.ease(curve,t) -> [0,1]
```

```lua
local progress=mathx.ease("in_out_cubic",.5)
```

### mathx.angle_vectors

```lua
mathx.angle_vectors(pitch,yaw,roll=0) -> forward,right,up
```

```lua
local forward,right,up=mathx.angle_vectors(0,90)
```

### mathx.vector_angles

```lua
mathx.vector_angles(direction) -> angles or nil
```

```lua
local angles=mathx.vector_angles(vector(1,1,0))
```

### files.exists

```lua
files.exists(name) -> boolean
```

```lua
print(files.exists("notes"))
```

### files.delete

```lua
files.delete(name) -> boolean,error?
```

```lua
local removed,err=files.delete("old notes")
```

### json.array

```lua
json.array(table={}) -> tagged table
```

```lua
print(json.encode(json.array()))
```

### json.object

```lua
json.object(table={}) -> tagged table
```

```lua
print(json.encode(json.object()))
```

### console.warn

```lua
console.warn(message)
```

```lua
console.warn("Optional data is unavailable")
```

### console.error

```lua
console.error(message)
```

```lua
console.error("Could not load custom preferences")
```

### console.trace

```lua
console.trace(message)
```

```lua
console.trace("Reached update handler")
```

### json.null

Opaque non-nil sentinel for an explicit JSON null. Use `json.decode(text, true)` or `storage.read(key, fallback, true)` to retain it. It is not a general-purpose serializable userdata.


## Script permissions

Open **Scripts > Script permissions** to change host-owned toggles. `cs2.permissions()` returns `files_read`, `files_write`, `http`, `modules`, `commands`, `native`, and `inventory`. Scripts cannot grant themselves permissions. File read/write default on for compatibility with existing scripts; HTTP, module execution, custom commands, native access and inventory changes default off. The choices persist in `C:\scooby\CS2-v2\lua-permissions.json`, outside script storage. Legacy `files` and `storage` obey the same read/write switches.

Turning HTTP off cancels outstanding requests and blocks their results. Turning commands/native access off stops their effects; healthy callbacks can resume when re-enabled. Already executed Lua modules remain part of their script until unload. Native access is powerful and can call external functions; these service toggles are controls on the managed APIs, not a security boundary against a script that has native permission.

`cs2.capabilities()` reports compiled API support. Check permissions separately, `commands.engine_status()` for input/trace readiness, and `model_preview.status()` / `inventory.status()` for native availability. A compiled API does not imply that every current game build or scene can use its engine service.

## Custom command frameworks

`commands.create(source,{enabled=true})` registers one isolated command worker per script during script loading. Its source must return `function(cmd,ctx)`. Up to eight workers run in registration order. They run on CS2's command thread, after enabled host movement processing, using the existing validated command serializer and rollback. Active command workers suppress the built-in aimbot/RCS and triggerbot so authors can own target selection, recoil correction and firing. If you only want an overlay, use ordinary `ui.overlay` / `events.on('render',...)` callbacks.

Commands run only with a live local player, foreground game, closed menu and the panic switch off. An unsupported command pipeline does not run callbacks; inspect `commands.engine_status().message`. The engine adapter and live trace/model/inventory behavior require in-game acceptance for the installed CS2 build; offline fixtures validate worker execution and host contracts.

| Command field | Contract |
|---|---|
| `number` | Read-only command sequence |
| `pitch`, `yaw` | Finite degrees: -89..89 and -180..180 |
| `forward`, `left`, `up` | Normalized movement: -1..1 |
| `buttons` | Unsigned 32-bit mask; attack=1, jump=2, duck=4; native higher bits are preserved |
| `visible` | Boolean, defaults true; update the visible camera only after successful serialization |

`ctx` contains `tick`, `time`, `interval` (the host command model uses 1/64 second), `local_player`, `players`, `recoil`, `velocity` and `weapon`. Players are copied `{index,handle,health,armor,team,enemy,alive,immune,origin,eye}` records with `{x,y,z}` vectors; `players` excludes self. `weapon` has `handle`, `definition`, `ammo`, `reloading`, `can_fire`. `can_fire` is a readiness check, not a hit guarantee. Recoil values are the host aim-punch angles; authors choose compensation and smoothing.

Worker-only `game.trace(start,finish)` uses the host shot trace, skips the local pawn and returns `{fraction,start_solid,entity,position,normal}` or `nil,error`. It is not penetration simulation. `game.bone(handle,index)` reads an actual animated player bone (0..127), returning nil when unavailable; it does not fabricate a fallback pose. Handles are revalidated against the current command's player identities. `game.key_down(vk)` checks virtual keys 1..255. These functions are deliberately separate from render-thread player snapshots.

Use `callback:set(key,value)` and worker `shared.get(key)` for UI-to-command controls; worker `shared.set` and `callback:get` carry results back. Values are scalars, nil or strings up to 4096 bytes, with 64 keys per worker. Worker state is separate from the UI Lua state: no UI, files, HTTP, native calls, dynamic code loading or protected calls. Base/table/string/math/utf8 are available. Limits are 4 MiB, 200,000 instructions, 2 ms per callback, 4 ms for the dispatch and 64 game queries. A blocking native query cannot be interrupted mid-call, but an over-budget result is discarded. Rebuilt identical commands reuse the prior result without advancing worker state twice. Altered input for an already processed sequence is left untouched.

`callback:enable`, `callback:remove`, `callback:status`, `callback:get` and `callback:set` control the worker. Errors discard that worker's edits, disable it, and report the script, worker source/line, traceback when available and a reload hint to the console. Other callbacks remain active. Unload, reload and failed startup remove owned workers. The **Command framework** template starts disabled and demonstrates custom targeting, recoil and firing with explicit controls.

## Folder storage and module loading

`fs` adds nested paths alongside the legacy simple-name `files`/`storage` APIs. Each script has its own stable folder under `C:\scooby\CS2-v2\lua-data`; renaming a script selects a different namespace. A path is relative to that folder, maximum 500 UTF-8 bytes. Absolute paths, traversal, device names, alternate streams, links and junctions are rejected. The directory checks do not isolate a script with native access or an external process changing the filesystem concurrently.

Read/write at most 8 MiB per file. `fs.write` creates parents and atomically replaces a file. `fs.list('',true)` recursively lists up to 2048 sorted `{path,directory,size}` entries. `fs.rename` refuses to overwrite a destination. `fs.remove` removes a file or an empty directory; it does not recursively erase trees. Invalid argument types or disabled permissions raise an error; operational failures return `nil,error`, so use `assert` or handle the returned message.

`fs.load(path)` requires read and module permissions. It executes text-only Lua of at most 1 MiB in the calling script state and returns the module's first result or `nil,error` with source information. It does not cache modules. If the module registers UI or callbacks, load it during script startup. Downloading a file never executes it automatically. `json.encode/decode` work with these files for profiles and save/load workflows.

## HTTP requests and download workflows

`http.request{url,method='GET',headers={},body='',max_bytes=8388608}` starts an asynchronous HTTP/HTTPS request and returns an owned request handle or `nil,error`. Methods: GET, HEAD, POST, PUT, PATCH, DELETE. Request bodies are at most 1 MiB; responses at most 8 MiB; headers at most 16 KiB. A script may retain eight request handles, with four running requests globally. Release completed handles to create more. Network I/O stays off the UI/command threads.

Poll `request:status()` for `pending`, `complete` or `canceled`. `request:result()` returns `{status,body,ok,url}` or `nil,error` (`pending` while unfinished). HTTP 4xx/5xx are completed responses with `ok=false`, not transport errors. `body` is binary-safe; pass it to `fs.write` to save assets or modules. Redirects are returned as 3xx, not followed automatically. Embedded URL credentials and newline injection are rejected. TLS certificate validation remains enabled; automatic cookies and Windows authentication are disabled. The transport has 3-second operation timeouts and a 20-second response-body deadline, not a guaranteed total wall-time limit.

`request:cancel()`, script unload or disabling HTTP marks requests canceled. A worker may take until its current network operation returns to release transport resources. No callback is invoked after script teardown. The **Download asset** template shows polling and save/load; choose your own update URL and explicitly decide whether and when to execute downloaded Lua. HTTP is not an HTML/CSS browser renderer. WebSocket and embedded web UI remain unavailable.

## Local inventory and native 3D previews

The `inventory` API operates the host's local inventory changer. It does not create Steam-owned/tradable items or modify an account's server inventory. IDs are decimal strings to preserve all 64 bits. Catalog and owned-item reads return copies, paged from 1 with a maximum of 256 entries per call. `inventory.categories()` lists supported catalog families; `inventory.catalog` returns `{category,definition,auxiliary,name,rarity,resource}`. `inventory.finishes` returns current `{paint_kit,name,rarity,old_model}` entries for weapons, knives or gloves; `all=true` includes paint kits authored for other models.

Draft identity is `{category,definition,auxiliary=0}` and must exist in the host catalog. Optional cosmetics: `paint_kit`, `wear` (0..1), `seed` (0..1000), `stattrak` (-1..999999), `custom_name` (160 bytes), four `stickers`, four `sticker_wear` values, `charm`, `charm_seed`, and three `charm_offset` values (-10..10). Paint kits must exist in the current host catalog. Unknown keys and changing identity through `inventory.update` are errors. The host owns resource paths and rarity. Add is limited to 4096 locally owned items.

`inventory.add/update/remove/equip/unequip` require inventory permission. Successful changes persist; failed saves roll back the local transaction. Team masks are CT=1, T=2, both=3; equipping clears the same slot on the requested teams and preserves the other team's selection. `true` means the local operation was accepted; native application may still be waiting for an in-game session or supported schema. Read `inventory.status()` for the local store, native bridge, apply message and revision.

`model_preview.draw(label,id_or_draft,width,height,transparent=false)` belongs inside a UI drawing callback; dimensions are 32..2048. It returns `{visible,ready,x1,y1,x2,y2}` or `nil,error` and uses the existing host 3D renderer and its drag/zoom controls. The preview service supports one live model at a time. A validated draft can be previewed without adding or equipping an item. The preview obeys the native live-preview setting and renderer availability. Unload closes a preview owned by that script. Arbitrary imported meshes, managed textures, shaders and font resources are not added by this API.

## Framework function signatures

### cs2.permissions

```lua
cs2.permissions() -> table
```

```lua
print(cs2.permissions().http)
```

### fs.read

```lua
fs.read(path) -> string or nil,error
```

```lua
local data,err=fs.read('profiles/default.json')
```

### fs.write

```lua
fs.write(path,bytes) -> true or nil,error
```

```lua
assert(fs.write('profiles/default.json',json.encode({enabled=true})))
```

### fs.mkdir

```lua
fs.mkdir(path) -> true or nil,error
```

```lua
assert(fs.mkdir('assets/icons'))
```

### fs.exists

```lua
fs.exists(path) -> boolean or nil,error
```

```lua
local exists,err=fs.exists('assets/icons')
```

### fs.list

```lua
fs.list(path,recursive=false) -> entries or nil,error
```

```lua
for _,entry in ipairs(assert(fs.list('',true))) do print(entry.path,entry.directory,entry.size) end
```

### fs.rename

```lua
fs.rename(from,to) -> true or nil,error
```

```lua
assert(fs.rename('profiles/draft.json','profiles/current.json'))
```

### fs.remove

```lua
fs.remove(path) -> boolean or nil,error
```

```lua
assert(fs.remove('profiles/unused.json'))
```

### fs.load

```lua
fs.load(path) -> module_value or nil,error
```

```lua
local module=assert(fs.load('modules/helpers.lua'))
```

### http.request

```lua
http.request(options) -> HttpRequest or nil,error
```

```lua
local request=assert(http.request{url='https://example.com/version.json',max_bytes=65536})
```

### commands.available

```lua
commands.available() -> boolean
```

```lua
print(commands.available()) -- permission state
```

### commands.engine_status

```lua
commands.engine_status() -> {ready,trace,message}
```

```lua
print(commands.engine_status().message)
```

### commands.create

```lua
commands.create(source,options?) -> CommandCallback or nil,error
```

```lua
local callback=assert(commands.create([[return function(cmd,ctx)
  if game.key_down(1) then cmd.pitch=math.max(-89,math.min(89,cmd.pitch-ctx.recoil.x*2)) end
end]],{enabled=false}))
```

### inventory.categories

```lua
inventory.categories() -> string[]
```

```lua
for _,category in ipairs(inventory.categories()) do print(category) end
```

### inventory.catalog

```lua
inventory.catalog(category,start=1,limit=100) -> entries,total
```

```lua
local entries,total=inventory.catalog('weapon',1,100)
```

### inventory.finishes

```lua
inventory.finishes(category,definition,start=1,limit=100,all=false) -> entries,total
```

```lua
local finishes,total=inventory.finishes('weapon',7,1,100)
```

### inventory.items

```lua
inventory.items(start=1,limit=100) -> items,total
```

```lua
local owned,total=inventory.items(1,100)
```

### inventory.get

```lua
inventory.get(id) -> item or nil,error
```

```lua
local item,err=inventory.get(saved_id)
```

### inventory.add

```lua
inventory.add(draft) -> decimal_id or nil,error
```

```lua
local id=assert(inventory.add{category='weapon',definition=7,wear=.1,seed=1})
```

### inventory.update

```lua
inventory.update(id,cosmetics) -> true or nil,error
```

```lua
assert(inventory.update(saved_id,{wear=.2,custom_name='My item'}))
```

### inventory.remove

```lua
inventory.remove(id) -> true or nil,error
```

```lua
assert(inventory.remove(saved_id))
```

### inventory.equip

```lua
inventory.equip(id,teams=3) -> true or nil,error
```

```lua
assert(inventory.equip(saved_id,1)) -- CT=1, T=2, both=3
```

### inventory.unequip

```lua
inventory.unequip(id,teams=3) -> true or nil,error
```

```lua
assert(inventory.unequip(saved_id,3))
```

### inventory.status

```lua
inventory.status() -> {local,native,apply,revision}
```

```lua
local status=inventory.status();print(status['local'],status.native,status.apply)
```

### model_preview.draw

```lua
model_preview.draw(label,id_or_draft,width,height,transparent=false) -> {visible,ready,x1,y1,x2,y2} or nil,error
```

```lua
ui.tab('models','Models',function()
  model_preview.draw('AK preview',{category='weapon',definition=7},320,280)
end)
```

### model_preview.status

```lua
model_preview.status() -> {state,message}
```

```lua
print(model_preview.status().message)
```

### HttpRequest.status

```lua
request:status() -> pending|complete|canceled
```

```lua
print(request:status())
```

### HttpRequest.result

```lua
request:result() -> {status,body,ok,url} or nil,error
```

```lua
local response,err=request:result()
if response then print(response.status,#response.body) end
```

### HttpRequest.cancel

```lua
request:cancel()
```

```lua
request:cancel()
```

### CommandCallback.enable

```lua
callback:enable(boolean)
```

```lua
callback:enable(false)
```

### CommandCallback.remove

```lua
callback:remove()
```

```lua
callback:remove()
```

### CommandCallback.get

```lua
callback:get(key) -> scalar or nil
```

```lua
print(callback:get('target'))
```

### CommandCallback.set

```lua
callback:set(key,scalar_or_nil)
```

```lua
callback:set('strength',1.5)
```

### CommandCallback.status

```lua
callback:status() -> {enabled,removed,failed,calls,replays,error}
```

```lua
print(callback:status().error)
```

### CommandGame.trace

```lua
game.trace(start,finish) -> {fraction,start_solid,entity,position,normal} or nil,error
```

```lua
local hit,err=game.trace(ctx.local_player.eye,ctx.players[1].eye)
```

### CommandGame.bone

```lua
game.bone(handle,index) -> {x,y,z} or nil,error
```

```lua
local head=game.bone(ctx.players[1].handle,6)
```

### CommandGame.key_down

```lua
game.key_down(virtual_key) -> boolean
```

```lua
if game.key_down(0x05) then cmd.buttons=cmd.buttons|1 end
```
