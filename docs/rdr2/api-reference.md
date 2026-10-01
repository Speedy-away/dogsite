# RDR2 Lua API reference

Version **2.1.0**. Signatures use Lua types; optional arguments show defaults.
See the runtime guide for execution phases, lifetimes and runtime compatibility.

## Version and capability checks

```lua
compat.api_version -- "2.1.0"
compat.runtime -- {name, version, lua_version, integer_bits, ffi, jit_compilation}
compat.has(name) -> boolean
compat.is_api_compatible(version) -> boolean
compat.require{api='2.1.0', game='RDR2', runtime={'Lua54','LuaJIT'},
    capabilities={'modules','custom_gui','input_bindings'}}
compat.use('scooby') -- or 'yim-legacy'; select before capturing ImGui
```

## Lifecycle and tasks

```lua
function onLoad() end
function onTick() end
function onUnload() end
script.run_in_fiber(function() script.yield(100) end) -> taskId
script.register_looped('name', function(task) task:sleep(100) end) -> taskId
script.unregister(taskId) -> boolean
script.on_unload(function() end) -> listenerId
script.stop()
script.is_inside_callback() -> boolean
script.is_active() -> boolean
```

## Standalone windows and cursor

```lua
gui.add_always_draw_imgui(function() end) -> renderId
gui.add_imgui(function() end) -> renderId -- host-menu visibility
script.unregister_render(renderId) -> boolean
gui.is_open() -> boolean -- host menu
gui.override_mouse(enabled)
gui.mouse_override() -> boolean
-- A render action schedules native work:
if ImGui.Button('Refill health') then
    script.run_in_fiber(function()
        if Self.isValid() and not Self.isDead() then Self.refillHealth() end
    end)
end
```

## Script-owned GUI tabs

```lua
local tab = gui.add_tab('Tools')
local button = tab:add_button('Run', function() log('game callback') end)
tab:add_checkbox('Enabled', false, function(value) end)
tab:add_input_int('Count', 1, function(value) end)
tab:add_input_float('Scale', 1.0, function(value) end)
tab:add_input_string('Name', '', function(value) end)
tab:add_text('Text')
tab:add_separator()
tab:add_sameline()
tab:add_imgui(function() ImGui.Text('render callback') end)
tab:add_tab('Nested')
button:set_enabled(false)
button:set_text('Unavailable')
button:remove()
```

## ImGui windows and layout

```lua
ImGui.SetNextWindowSize(width, height, ImGuiCond.FirstUseEver)
ImGui.SetNextWindowPos(x, y, ImGuiCond.FirstUseEver, pivotX, pivotY)
ImGui.SetNextWindowSizeConstraints(minX, minY, maxX, maxY)
ImGui.SetNextWindowBgAlpha(alpha)
ImGuiWindowFlags.NoInputs -- NoMouseInputs + NoNavInputs + NoNavFocus
ImGuiCol.SliderGrab -- scrollbar/slider/resize accent colors are exposed
ImGui.Begin(name, flags) -> visible
ImGui.Begin(name, open, flags) -> open, visible
ImGui.End()
ImGui.BeginChild(id, width, height, border) -> visible
ImGui.EndChild()
ImGui.SameLine()
ImGui.Separator()
ImGui.Dummy(width, height)
ImGui.Text(text)
ImGui.TextWrapped(text)
ImGui.TextDisabled(text)
ImGui.TextColored(r, g, b, a, text)
ImGui.BeginDisabled(disabled)
ImGui.EndDisabled()
ImGui.PushID(numberOrString)
ImGui.PopID()
```

## ImGui controls and return order

```lua
ImGui.Button(label) -> pressed
ImGui.Selectable(label, selected) -> pressed
ImGui.Checkbox(label, value) -> changed, value
ImGui.SliderInt(label, value, min, max) -> changed, value
ImGui.SliderFloat(label, value, min, max) -> changed, value
ImGui.InputInt(label, value) -> changed, value
ImGui.InputFloat(label, value) -> changed, value
ImGui.InputText(label, text, capacity=4096, flags=0) -> changed, text
ImGui.InputTextMultiline(label, text, width, height, capacity=65536, flags=0) -> changed, text
ImGui.ProgressBar(fraction, width, height, overlay)
ImGui.BeginCombo(label, preview) -> visible
ImGui.EndCombo()
-- The explicit Yim adapter reverses value widgets:
compat.yim_imgui.Checkbox(label, value) -> value, changed
```

## ImGui tables, tabs and drawing

```lua
ImGui.BeginTable(id, columns, flags=0, width=0, height=0) -> visible
ImGui.TableNextRow()
ImGui.TableNextColumn()
ImGui.EndTable()
ImGui.BeginTabBar(id) -> visible
ImGui.BeginTabItem(label) -> visible
ImGui.EndTabItem()
ImGui.EndTabBar()
ImGui.GetDisplaySize() -> width, height
ImGui.GetCursorScreenPos() -> x, y
ImGui.GetContentRegionAvailX() -> width
ImGui.GetColorU32(r, g, b, a) -> packedColor
local draw = ImGui.GetWindowDrawList()
draw:AddLine(x1, y1, x2, y2, color, thickness)
draw:AddRectFilled(x1, y1, x2, y2, color, rounding)
draw:AddText(x, y, color, text)
```

## Keyboard and controller window bindings

```lua
Input.isGameFocused() -> boolean
Input.isKeyDown(virtualKey) -> boolean
Input.getControllerState() -> state
local toggle = Input.createToggle{key=Keys.F7, controller={'LB','Down'}}
toggle:poll() -> pressed
toggle:reset()
-- state: connected, backend, index (XInput only), hasRightStick,
-- leftTrigger/rightTrigger, leftX/leftY/rightX/rightY, buttons
-- buttons: A/B/X/Y, LB/RB, L3/R3, Up/Down/Left/Right, Start/Back
-- aliases: Cross/Circle/Square/Triangle
```

## Native game controls

```lua
Input.isControlPressed(group, control) -> boolean
Input.isControlJustPressed(group, control) -> boolean
Input.isControlJustReleased(group, control) -> boolean
Input.isDisabledControlPressed(group, control) -> boolean
Input.getControlNormal(group, control) -> number
Input.getDisabledControlNormal(group, control) -> number
Input.disableControl(group, control) -- current frame
Input.isUsingKeyboard() -> boolean
Input.isUsingGamepad() -> boolean
```

## Local player helpers

```lua
Self.isValid() -> boolean
Self.isDead() -> boolean
Self.getPosition() -> vector
Self.getHealth() -> integer
Self.getMaxHealth() -> integer
Self.refillHealth()
Self.refillStamina()
Self.clearWantedLevel()
Self.isOnMount() -> boolean
Self.isInVehicle() -> boolean
Self.getMount() -> Ped
Self.getVehicle() -> Vehicle
```

## Horse helpers

```lua
Mount.getCurrent() -> Ped
Mount.getHealth() -> integer
Mount.getStamina() -> number
Mount.refillHealth()
Mount.refillStamina()
Mount.spawnAtPlayer(modelName) -> Ped
Mount.mount(horseHandle)
Mount.dismount()
```

## Travel helpers

```lua
Teleport.toCoords(x, y, z, loadGround) -> boolean
Teleport.toWaypoint() -> boolean
Teleport.getWaypointCoords() -> {valid, x, y, z}
Teleport.isWaypointActive() -> boolean
Teleport.toEntity(handle) -> boolean
-- Frontier uses loadGround=false for previously recorded coordinates.
-- Legacy loadGround/waypoint helpers retry synchronously and can fall back
-- to an unverified height. A true result does not certify streamed ground.
```

## World helpers

```lua
World.getTime() -> {hour, minute, second}
World.setTime(hour, minute, second)
World.setTimeWithTransition(hour, minute, second, transitionMs, freeze)
World.setWeather(name)
World.clearWeatherOverride()
NETWORK.NETWORK_CLEAR_CLOCK_TIME_OVERRIDE()
-- Overrides are shared game state. Track changes and clear on normal unload.
```

## Cooperative streaming

```lua
Streaming.awaitModel(hash, timeoutMs=5000) -> boolean
Streaming.awaitAnimDict(name, timeoutMs=5000) -> boolean
script.run_in_fiber(function()
    local hash = MISC.GET_HASH_KEY('A_C_HORSE_ARABIAN_WHITE')
    if Streaming.awaitModel(hash, 5000) then
        log('Model loaded')
        Streaming.releaseModel(hash)
    end
end)
```

## Script-owned configuration

```lua
Config.set(key, jsonCompatibleValue)
Config.get(key, fallback) -> value
Config.has(key) -> boolean
Config.remove(key)
Config.clear()
Config.load() -> boolean
Config.save() -> boolean
Config.getBool(key, fallback) -> boolean
Config.getInt(key, fallback) -> integer
Config.getFloat(key, fallback) -> number
Config.getString(key, fallback) -> string
```

## JSON and files

```lua
json.encode(value, indent) -> string
json.decode(text) -> value
json.null
json.loadFile(path) -> value
json.saveFile(path, value) -> boolean
File.getPackageDir() -> path
File.getScriptsDir() -> path
File.exists(path) -> boolean
File.read(path) -> string
File.write(path, text) -> boolean
File.append(path, text) -> boolean
local module = require('frontier.model')
-- File operations remain inside the host Lua root.
```

## Events and timers

```lua
Event.on(name, function(...) end) -> listenerId
Event.once(name, function(...) end) -> listenerId
Event.off(name, listenerId)
Event.fire(name, ...)
Timer.create(durationMs, repeating) -> timerId
Timer.isActive(timerId) -> boolean
Timer.hasElapsed(timerId) -> boolean
Timer.destroy(timerId)
Timer.startStopwatch() -> timestamp
util.current_time_millis() -> timestamp
```

## Named native availability

```lua
Native.is_supported(namespace, name) -> boolean
Native.supported_count -> integer
local ped = PLAYER.PLAYER_PED_ID()
if ENTITY.DOES_ENTITY_EXIST(ped) then
    local position = ENTITY.GET_ENTITY_COORDS(ped, true, false)
    log(string.format('%.2f %.2f %.2f', position.x, position.y, position.z))
end
-- RDR2.PLAYER.PLAYER_PED_ID() is the equivalent namespaced form.
```

The generated native catalog records every source declaration, its typed
signature and whether it is exposed. Its unsupported reasons are part of the
contract; the API browser does not turn pointer/Any signatures into callable APIs.
