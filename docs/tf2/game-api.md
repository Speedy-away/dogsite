# TF2 family Lua API

Version **1.2**. `TF2_API_VERSION == "1.2"`. Each independent product owns its implementation in `src/lua_api.cpp`, headers, docs, examples and tests. Both follow the matching additive 1.2 Lua contract (existing 1.0 functions and activation-mode numbers are preserved); neither includes code from the other variant. Retail exposes `tf2`; Classified exposes the same `tf2` table and the compatible alias `tf2c`. The existing portable `UI_API_VERSION`, `ui`, `imgui`, `render`, `features`, `events`, `base` and `esp_colors` APIs remain available.

Scripts run from the Lua main tab through Scripts or Lua Editor. Expand API entries in the themed API browser for signatures and examples. Bundled examples do not run automatically. Updating scripts alone cannot add bindings to an older DLL.

## Identity and capabilities

### tf2.info()

```lua
-- -> {api_version, game_id, game, map, preview, sequence, generation,
--     engine_time, tick_interval}
local info=tf2.info()
print(info.game,info.map,info.api_version)
```

`game_id` is `tf2` or `tf2_classified`. Time is engine seconds. Sequence increases per engine capture; generation changes across map/session transitions. Neither value is a persistent entity identifier. Preview reports the actual product identity with `preview=true`.

### tf2.capabilities()

```lua
-- -> {snapshots, projection, settings, shared_ui, four_teams,
--     civilian, mvm, viewmodel_offsets, native_hooks, entity_filters,
--     active_weapon, condition_list, feature_info, tick_math, capture_features}
local caps=tf2.capabilities()
if caps.civilian then print(tf2.class_name(10)) end
```

Capabilities describe implemented host surfaces, not completed native acceptance. Four teams/Civilian belong to Classified; MvM belongs to retail. Both implement viewmodel offsets. Raw native hooks are not supplied by this extension. Detect individual built-in settings with `tf2.has_feature(id)`.

### tf2.session()

```lua
-- -> {allowed, data_available, in_game, preview, stopped, menu_open, entity_count}
local state=tf2.session()
if state.data_available then print(state.entity_count) end
```

Game queries use the existing local-session gate. Preview has no live game data. Missing local player, disconnect, an ineligible session or Stop makes entity/player/projection queries empty or nil on the next captured/rendered frame. No engine pointer is exposed.

## Copied game data

All callbacks in one rendered frame read the same pinned immutable engine capture. Returned tables are independent copies; changing them does not change game memory. Ordinary entity IDs are decimal strings containing the full handle including its serial. Retail synthetic objective markers can have opaque string IDs. Reacquire data each callback and discard IDs when `generation` changes; a serial is not a cross-map lifetime guarantee.

### tf2.local_player()

```lua
-- -> {handle, team, class_id, class_name, health, alive, on_ground, flags,
--     position, eye_position, velocity, view_angles, speed, sequence, generation} or nil
local me=tf2.local_player()
if me then print(me.class_name,me.health,me.speed) end
```

Vectors use Source units with Z up. Angles use `{x=pitch,y=yaw,z=roll}` in degrees. Speed is horizontal Source units/second. Unknown weapon, ammo and attribute fields are not synthesized.

### tf2.active_weapon()

```lua
-- -> {handle, item_id, sequence, generation} or nil
-- Local active weapon from the same snapshot as local_player().
-- nil without a resolved item ID/handle, or without available game data.
local weapon=tf2.active_weapon()
if weapon then print(weapon.handle,weapon.item_id) end
-- No ammo, attributes, weapon ownership or inventory changes are implied.
```

### tf2.players([filter])

```lua
-- Same filters and copied fields as entities(), restricted to player kind.
-- Local player remains available separately through local_player().
for _,p in ipairs(tf2.players{team=2,class_id=3,limit=8}) do
    print(p.class_name,p.name,p.model)
end
-- Capture order is preserved; limit does not sort by distance.
```

### tf2.entities([filter])

```lua
-- Optional filter fields: kind, relationship, max_distance (metres),
-- team (integer), class_id (integer), type (exact host type), limit (0..8192).
for _,entity in ipairs(tf2.entities{kind='player',relationship='enemy',max_distance=150}) do
    print(entity.handle,entity.name,entity.distance_m)
end
```

The list contains recognized, non-dormant entities already collected by the host, independently of the built-in ESP master switch. It is not an enumeration of every Source class. Local player is separate; dead players and unsupported classes are omitted. `kind` is player/npc/item/weapon/prop/unknown. `relationship` is friendly/enemy/neutral/normal/unknown. Unknown kind/relation values return an empty list; unknown filter keys and non-finite/range types error. `max_distance` clamps to 0..1e9 metres. Team/class IDs must be nonnegative integers; unsupported IDs or type names match nothing. Metadata filters skip entities without metadata. `limit=0` returns an empty array; an omitted limit returns every match in capture order. No sorting or additional native capture is performed.

Entity fields: `handle`, `name`, `kind`, `relationship`, `alive`, `teammate`, `position`, `bounds_min`, `bounds_max`, `distance_m`, `sequence`, `generation`, `bones_available`, optional `health`/`max_health`. Native entities also supply `team`, `class_id`, `class_name`, `network_class`, `type`, `model`, `weapon_class`, optional `weapon_item_id`. Player weapon details require the host's weapon ESP capture option; unknown item IDs stay absent. Synthetic retail objectives can omit metadata. Bounds are absolute Source-space AABB corners. Names are actual player names or the host's display labels. Classification only promises recognized per-title types.

### tf2.entity(handle)

```lua
-- Decimal string, opaque ID, or unsigned 32-bit full numeric handle -> entity or nil
local list=tf2.entities()
if list[1] then print(tf2.entity(list[1].handle).name) end
```

### tf2.bones(handle)

```lua
-- -> array of {from={x,y,z}, to={x,y,z}}
local entities=tf2.entities{kind='player'}
if entities[1] then print(#tf2.bones(entities[1].handle)) end
```

Bones are available only when the host captured the pose for built-in ESP/aim; a Lua query does not enable expensive bone collection. Segments are copied world positions, not a promise of stable engine bone indices.

### tf2.condition(handle, index)

```lua
-- index 0..159 -> boolean; false for unavailable/non-player data
local entities=tf2.entities{kind='player'}
if entities[1] then print(tf2.condition(entities[1].handle,4)) end
```

Indices address the copied five TF condition bitfields. The meaning of extended conditions can differ by edition; verify title-specific indices before use.

### tf2.conditions(handle)

```lua
-- -> ascending array of active numeric condition indices (0..159).
-- Empty for missing/non-player data, preview, Stop or an unavailable session.
local players=tf2.players{limit=1}
if players[1] then
    for _,index in ipairs(tf2.conditions(players[1].handle)) do print(index) end
end
-- Indices retain each edition's meaning; no cross-edition names are assumed.
```

## Camera and projection

### tf2.camera()

```lua
-- -> {position, angles, width, height} or nil
local camera=tf2.camera()
if camera then print(camera.width,camera.height) end
```

Position is the captured eye and angles are the engine view; projection uses the renderer matrix and can differ in spectator views. Screen values use the same client-pixel coordinates as `render.*`, not menu design units.

### tf2.world_to_screen(position)

```lua
-- Source {x,y,z} -> {x,y,on_screen} or nil
ui.overlay('tf2_player_labels',function()
    for _,e in ipairs(tf2.entities{kind='player'}) do
        local p=tf2.world_to_screen(e.position)
        if p and p.on_screen then render.text(p.x,p.y,e.name,{1,1,1,1}) end
    end
end)
```

Behind-camera/depth-invalid input returns nil. Offscreen lateral points can return `on_screen=false`. Projection does not test line-of-sight or wall occlusion.

### tf2.screen_box(handle)

```lua
-- -> {left,top,right,bottom,width,height,fitted} or nil
ui.overlay('tf2_box_example',function()
    for _,e in ipairs(tf2.entities{kind='player',relationship='enemy'}) do
        local b=tf2.screen_box(e.handle)
        if b then render.rect(b.left,b.top,b.width,b.height,{.2,.8,1,1}) end
    end
end)
```

Uses canonical hitbox fitting, near-plane clipping and viewport handling. `fitted=true` means the capture had animated hitbox boxes; otherwise the current bounds fallback is used. Bone/pose availability follows the host capture policy above.

## Settings and input

### tf2.setting(id, field [, value])

```lua
-- field 'style' or 'distance' -> normalized numeric value
local old=tf2.setting('view.camera_fov','distance')
tf2.setting('view.camera_fov','distance',100)
features.set('view.camera_fov',true)
```

Uses the feature's own numeric limits. Style indices are zero-based, clamped, then truncated. Distance is a generic numeric slot: units depend on the ID (degrees for FOV, metres for range, seconds for trigger delay). Changing a value does not enable its feature. Invalid IDs/fields/non-finite input raise Lua errors. Discover IDs through `features.list()` and use portable APIs for enabled state/colors/hotkeys/configuration.

### tf2.feature_info(id)

```lua
-- -> copied {id,label,category,enabled,independent_activation,style,style_count,
--            distance,distance_min,distance_max,blocked,blocked_reason} or nil
-- blocked_reason is absent when unlocked; unknown IDs return nil.
local f=tf2.feature_info('view.camera_fov')
if f then print(f.distance_min,f.distance_max,f.blocked_reason) end
-- Host numeric slots use the feature's own units. Editing this table does not
-- change settings; setting()/features.set() still enforce host policy locks.
```

### tf2.has_feature(id)

```lua
-- -> boolean; useful for edition-specific controls
if tf2.has_feature('mvm.wave_panel') then features.set('mvm.wave_panel',true) end
```

### tf2.keybind(id [, action [, mode]])

```lua
-- -> key, mode, capturing, waiting
-- actions: 'capture', 'clear', 'mode'; modes: 0 Hold, 1 Toggle, 2 Always, 3 Hold off
local key,mode=tf2.keybind('aim.key')
print(key,mode)
```

Only independent combat activation IDs are accepted. Lua mode numbers retain their existing mapping and differ from the saved config enum. Capture waits 500 ms before accepting a key. `capturing` and `waiting` apply only to the queried ID. Host-blocked features reject capture/clear/mode writes while remaining readable. Clearing/changing modes resets the transient latch. Settings written to existing features remain after stopping a script and participate in normal profile persistence.

### tf2.object_preview(kind, chams [, layer])

```lua
-- UI callback only. kind: "weapons", "health", "ammo", "items".
-- false uses the selected object's ESP settings; true uses chams.target.
ui.subtab("visuals", "custom.weapons", "Weapons", function()
    tf2.object_preview("weapons", false)
end)
```

### tf2.model_preview(chams [, layer])

```lua
-- UI callback only; draws the product's actual class model preview
local tab=ui.tab('model_inspector','Model inspector')
ui.subtab(tab,'model','Model',function() tf2.model_preview(false) end)
```

Both products provide this host-owned drawing callback. Available class models differ by title. It is a UI preview, not an entity or gameplay API. Classified's Scientist mesh is a preview asset, not a playable class ID.

### tf2.chams_preview_controls(layer, player_settings)

```lua
-- UI callback only. 1 = Visible, 2 = Invisible; returns clicked selection.
layer = tf2.chams_preview_controls(layer, true)
tf2.model_preview(true, layer)
-- Object previews accept the same optional layer as their third argument.
-- Omit layer (or pass 0) for the original combined preview.
```

Layer selection changes only the editor and preview; independently enabled live
passes, colors, materials and bindings remain intact. `player_settings` adds the
class/team settings gear. Classified also exposes these functions through `tf2c`.

## Names and math

### tf2.class_name(id), tf2.team_name(id)

```lua
print(tf2.class_name(1),tf2.team_name(2)) -- Scout, RED
```

Classes 1..9 use the Source TF order. Classified additionally maps 10 to Civilian, teams 4/5 to GRN/YLW. Retail maps only RED/BLU. Unsupported IDs return `Unknown`.

### tf2.classes(), tf2.teams()

```lua
-- -> independent arrays of {id,name}, ordered by numeric engine ID.
-- Classes: retail 1..9; Classified 1..10 (Civilian).
-- Teams include Unassigned/Spectator: retail 0..3; Classified 0..5.
for _,c in ipairs(tf2.classes()) do print(c.id,c.name) end
for _,t in ipairs(tf2.teams()) do print(t.id,t.name) end
```

### tf2.angle_forward(angles)

```lua
-- {x=pitch,y=yaw,z=roll} degrees -> unit Source-space {x,y,z}.
-- Roll has no effect on the forward vector.
local forward=tf2.angle_forward({x=0,y=90,z=0}) -- approximately {0,1,0}
```

### tf2.time_to_ticks(seconds), tf2.ticks_to_time(ticks)

```lua
-- Uses the current captured tick_interval. Never assumes a fixed tick rate.
-- Returns nil without live data or a valid positive interval.
-- seconds must be nonnegative; ticks must be a nonnegative integer.
-- time_to_ticks rounds to the nearest integer, with half ticks rounded up.
local ticks=tf2.time_to_ticks(.25)
if ticks then print(ticks,tf2.ticks_to_time(ticks)) end
```

### tf2.vec

```lua
local a={x=3,y=4,z=0}
local b={x=1,y=0,z=0}
local sum=tf2.vec.add(a,b)
local difference=tf2.vec.sub(a,b)
local scaled=tf2.vec.scale(a,2)
local dot=tf2.vec.dot(a,b)
local length=tf2.vec.length(a)
local distance=tf2.vec.distance(a,b)
local unit=tf2.vec.normalize(a) -- nil for near-zero length
local cross=tf2.vec.cross(a,b) -- right-handed cross product
local horizontal=tf2.vec.length2d(a) -- ignores Z
local between=tf2.vec.lerp(a,b,.5) -- interpolation amount clamps to 0..1
```

### tf2.angle_to(eye, point), tf2.angle_fov(from, to)

```lua
local angles=tf2.angle_to({x=0,y=0,z=0},{x=100,y=0,z=50})
local degrees=tf2.angle_fov({x=0,y=0,z=0},angles)
```

Coincident positions return nil from `angle_to`. Angular distance uses the two view directions, in degrees. These pure functions do not write game commands.

### tf2.to_metres(units), tf2.to_units(metres)

```lua
local metres=tf2.to_metres(100)
print(metres,tf2.to_units(metres))
```

One Source unit is treated as .0254 metres. Numeric/vector inputs must be finite and within +/-1e9.

## Built-in feature families

| Family | IDs |
| --- | --- |
| Aim profiles | `aim.*`, `aim.rage.*`, `combat.profile` |
| Trigger profiles | `trigger.*`, `trigger.rage.*` |
| Movement/view | `movement.bhop`, `movement.strafe`, `view.camera_fov`, `view.model_fov` |
| Player ESP | `esp.*`, `esp.teammate.*` |
| Item ESP | `esp.world.health.*`, `esp.world.ammo.*`, `esp.world.weapons.*` |
| Chams targets | `chams.players`, `teammates`, `self`, `arms`, `weapon`, `world_weapon`, `buildings`, `items`, `dropped_weapons` |

Every chams target has `.visible`, `.hidden` and `.overlay` features with independent enabled states/colors. Material style: 0 Flat, 1 Lit, 2 Wireframe, 3 Fresnel, 4 Chrome, 5 Crystal, 6 Scanline. Each layer also has `.animation` (0 Static, 1 Pulse, 2 Rainbow, 3 Breathe, 4 Scroll, 5 Rotate), `.speed` and `.strength`; Scroll/Rotate require Crystal or Scanline. `world_weapon` is the local player's held world model, verified through weapon receive-table ancestry; `dropped_weapons` is separate. Product-only Stop IDs remain `tf2.stop` / `tf2c.stop`. Additional retail world/mode controls remain retail-only.


### Misc controls and player details

`tf2.toggle_control(feature_id)` draws a registered feature checkbox, its label and a keybind/settings gear, without a color picker. Use it inside a UI drawing callback. Classified exposes the same function through `tf2c`.

View and Movement now live under Misc (`misc.view`, `misc.movement`). The original `self/view` and `movement/movement.main` Lua routes remain registered for existing scripts. Existing `view.*` and `movement.*` feature IDs are unchanged. Both editions expose `view.model_offset`, `view.offset_x/y/z` (right/forward/up, -60..60 Source units), and `view.angle_pitch/yaw/roll` (-180..180 degrees). Camera/model overrides update while the menu is open; gameplay input remains captured by the menu.

Additional movement settings: `movement.air_jump` preserves a deliberate Scout release/press in the air; holding jump still performs bunny hop. `movement.strafe_direction.style` is 0 for View/mouse or 1 for Movement keys. These settings retain the existing per-feature keybind/config behavior.

Player ESP supports `class`, `weapon`, `conditions`, `hide_cloaked`, `hide_disguised`, and `details` under both `esp.` and `esp.teammate.`. The `details` feature stores label color and text size; the individual information toggles control visibility. Details obey the corresponding player ESP master and range. Configure them in the player preview settings gear. Entity snapshots optionally include `weapon_item_id` and `weapon_class` when active-weapon telemetry has been requested by either player ESP weapon toggle and the host resolved a valid weapon. Unavailable weapon IDs are omitted.


## VFX and extended chams

Both TF2 editions expose the same new feature IDs through the existing settings API. The VFX page has World, Sky and Effects subtabs. `vfx.world`, `vfx.props` and `vfx.sky` own independent RGB tints. `vfx.prop_opacity` uses distance 5–100 (%), applied only while Prop tint is active. `vfx.night` enables night mode; `vfx.brightness` is 5–100 (%). `vfx.world_pulse`, `vfx.pulse_speed` (0–5) and `vfx.pulse_strength` (0–1) animate world/prop brightness. `vfx.sky_cycle`, `vfx.sky_speed` (0–5) and `vfx.sky_strength` (0–1) animate sky color. All enable controls retain the usual binds/favorites.

`vfx.skybox.style` selects 0 (map default) or one of ten installed presets. Preset indices belong to the exact edition: the two games ship different sky libraries. This replaces the sky faces locally during rendering and restores them after the draw; it does not change `sv_skyname`. World/prop overrides restore their captured modulation when disabled, on Stop and before level shutdown.

Existing `chams.<target>.<visible|hidden|overlay>` IDs are unchanged. Material styles: 0 Flat, 1 Lit, 2 Wireframe, 3 Fresnel, 4 Chrome, 5 Crystal, 6 Scanline. Animation styles: 0 Static, 1 Pulse (alpha), 2 Rainbow, 3 Breathe (brightness), 4 Scroll, 5 Rotate. Scroll and Rotate apply to Crystal/Scanline textures; untextured materials use Static for those modes. `.speed` and `.strength` remain independent per layer. UV matrices restore after each model draw. The menu mesh renderer approximates engine lighting/reflections; native rendering is the visual authority.


`tf2.skins_page(page)` draws the class-filtered appearance editor in a UI callback. The existing `false`/`true` arguments remain Weapons/Players; integer pages `0`, `1`, `2` select Weapons, Players and Hats & cosmetics; `3` opens the inventory in Misc > Skins with Loadout, Browse and My Inventory views. Weapon paint settings retain installed paint IDs; each class has three cosmetic slots, installed item IDs and style IDs. These affect local rendering only. No items are granted to the Steam inventory.

## Radar contacts and player flags

Both TF2 editions expose `radar.icons`, `radar.icon_size` (12–40 px), and independent `radar.players`, `radar.weapons`, `radar.health`, `radar.ammo`, `radar.buildings`, `radar.objectives`, `radar.items` settings. Icons come from that edition's installed HUD/inventory assets. Turning icons off keeps dot contacts; hiding a radar category does not hide its ESP. Missing weapon images use an installed weapon fallback. The adapter decorates a copy of the immutable frame; it invalidates the cached copy on frame generation/sequence or option changes.

Players > Flags retains `esp.conditions` and `esp.teammate.conditions`. Each relationship has independently persisted `conditions.flag.<name>` entries: `scoped`, `cloaked`, `disguised`, `invulnerable`, `taunting`, `crit_boosted`, `burning`, `jarate`, `bleeding`, `milk`, `overhealed`. The gear exposes those toggles and text size; the master controls the full set. Existing class/weapon labels and cloak/disguise filters remain separate. These flags use the already verified condition words and health metadata, not new offsets.

The shared `ui.color` control uses the product's themed RGB/HEX picker with a vertical alpha strip and no Current/Original preview boxes. Its `(changed, rgba)` Lua return contract is unchanged.

## Capture Protection

### tf2.capture.feature(options, policy)

```lua
-- Loading only. Same options/ownership as features.add; returns a feature ID.
-- policy is required: "supported" or "disable".
local hud=tf2.capture.feature({id='hud',label='Custom HUD',default=true},'supported')
local effect=tf2.capture.feature({id='effect',label='Scene effect'},'disable')
-- "supported" keeps overlay-only features available. It does not hide native
-- rendering, audio or gameplay effects. Only declare work the overlay can protect.
-- "disable" turns the feature off and locks UI/writes/actions/hotkeys while enabled.
-- Unlocking does not turn it back on. Tuning and the declaration survive profiles.
-- A script can only declare its own new features; built-in locks cannot be changed.
ui.overlay('custom_hud',function()
    if features.active(hud) then render.text(20,120,'Custom HUD',{1,1,1,1}) end
end)
-- Standard controls automatically show the disabled blur and hover explanation:
local tab=ui.tab('custom_capture','Custom capture')
ui.subtab(tab,'controls','Controls',function() ui.feature(effect) end)
```

### tf2.capture.enabled([boolean])

```lua
-- No argument: read the requested switch. Boolean: set and enforce immediately.
-- Also emits the portable capture_protection_changed event on transitions.
local previous=tf2.capture.enabled()
-- tf2.capture.enabled(true)
-- Enabled is not proof that the renderer/recorder supports exclusion.
```

### tf2.capture.status()

```lua
-- -> {available,enabled,active,preview,renderer_status}
local state=tf2.capture.status()
print(state.enabled,state.active,state.renderer_status)
-- active means the last reported renderer status was "Active: protected overlay"
-- while enabled; it is always false in preview. This is not recorder verification.
-- Native render status describes the last completed renderer update.
-- Portable aliases: capture_protection.status(), .enabled(), .active().
-- The portable status uses "message" for the renderer_status string.
```

### tf2.capture.policy(id)

```lua
-- -> "supported", "disable", or "unclassified"; unknown IDs raise an error.
-- This reports TF2 declarations. Plain features.add Lua features are unclassified
-- here; their portable capture_protection declaration still applies.
print(tf2.capture.policy('chams.players.visible')) -- disable
-- To inspect the effective current lock, use features.blocked_reason(id).
```

### events.on('capture_protection_changed', callback)

```lua
local pending={}
events.on('capture_protection_changed',function()
    if capture_protection.enabled() then
        pending={} -- Also cancel your own active effects/audio/resources here.
    end
end)
events.on('shutdown',function() pending={} end)
-- Events fire on requested on/off transitions, not every frame or renderer retry.
-- Update/draw callbacks still run: gate feature work with features.active(id).
-- Portable alternative to the factory:
local id=features.add{id='scene',label='Scene effect',capture_protection='disable'}
-- capture_protection='safe' opts an overlay-only feature in; omission defaults to disable.
```


### tf2.capture_page()

```lua
ui.subtab("settings", "protection", "Capture Protection", function()
    tf2.capture_page()
end)
```

### tf2.capture_scope([feature_id,] callback)

```lua
-- UI drawing callback only; child code still runs to draw disabled controls.
-- Optional ID uses that feature's actual policy (including supported features).
tf2.capture_scope("chams.players.visible",function()
    ui.feature("chams.players.visible")
end)
-- Legacy capture_scope(callback) always locks the group while protection is on.
-- Keep effects in gated update callbacks; this is a drawing scope, not a sandbox.
```

### settings.capture_protection

```lua
local enabled = features.get("settings.capture_protection")
features.set("settings.capture_protection", true)

-- Protected native writes return the host's disabled-feature explanation.
local ok, reason = pcall(features.set, "chams.players.visible", true)
if not ok then print(reason) end
```

## Third-person camera settings

### `features.set("view.thirdperson", enabled)`

```lua
features.set("view.thirdperson", true)
tf2.setting("view.thirdperson_distance", "distance", 150) -- 30..400
features.set("view.thirdperson_collision", true)
features.set("view.thirdperson_scoped", true) -- first person while scoped
```

### `tf2.setting("view.thirdperson_shoulder", "distance", units)`

```lua
tf2.setting("view.thirdperson_shoulder", "distance", 24) -- -64..64
tf2.setting("view.thirdperson_height", "distance", 12)   -- -64..64
features.set("view.thirdperson_swap", true)
```


### `features.set("vfx.no_fog", enabled)`

```lua
features.set("vfx.no_fog", true)
features.set("vfx.no_sky_fog", true)
```

### `features.set("vfx.remove.<effect>", enabled)`

```lua
-- water, invulnerability, milk, jarate, bleeding, stealth, bonk, gas, burning
features.set("vfx.remove.jarate", true)
local state = tf2.feature_info("vfx.remove.jarate")
if state.blocked then print(state.blocked_reason) end
```

### `features.set("vfx.pure_bypass", enabled)`

```lua
-- Applies when the engine loads its server material whitelist.
-- Enable before joining; restart if a whitelist was already loaded.
features.set("vfx.pure_bypass", true)
```

## Free camera and movement assists

```lua
features.set("view.freecam", true)
tf2.setting("view.freecam_speed", "distance", 600) -- units per second, 50..2000
tf2.setting("view.freecam_boost", "distance", 2) -- Speed key multiplier, 1..5
features.set("movement.strafe", true)
features.set("movement.prespeed", true) -- brief acceleration before a stationary jump
features.set("movement.rev_jump", true) -- Heavy, idle minigun, fresh secondary press
```

```lua
local flight = tf2.feature_info("view.freecam")
-- Capture Protection disables and locks free camera, preserving its tuning.
features.set("view.freecam", false)
```
