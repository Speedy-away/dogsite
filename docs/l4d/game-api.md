# Scooby Left 4 Dead Lua API 1.0

## L4D quick start

**Lua > API docs** opens a scrollable L4D1/L4D2 snippet guide without toolbar controls. Select code and press Ctrl+C, then paste it into **Lua > Editor**. Each example runs independently. The guide ships as `docs/LUA_SNIPPETS.md`; this full reference remains in `docs/LUA_API.md`.

The `l4d` host API works with the L4D1 and L4D2 game adapters. It supplements the portable UI, rendering, events, hotkeys and feature/config APIs. `L4D_API_VERSION == "1.0"` identifies this host extension; `UI_API_VERSION` identifies the portable UI API separately.

Open **Lua > Scripts**, select an example and run it. Bundled scripts are copied into the active profile's script library on startup without overwriting your edited copies. They do not auto-run. New native APIs require a host built from this source; copying Lua files alone cannot add native functions to an older DLL.

Included examples:

- **L4D Entity Overlay.lua**: separate actor/pickup ESP, optional skeletons, range and category controls using the custom Scooby widgets.
- **L4D Player HUD.lua**: health, movement state, speed, active weapon and reload/clip information.
- **L4D Nearby Threats.lua**: distance warnings for specials and witches.

```lua
assert(L4D_API_VERSION == "1.0", "Update the Scooby L4D host")
l4d.watch {survivors=false, infected=true, pickups=false, range=60}
ui.overlay("specials", function()
    for _, e in ipairs(l4d.entities {special=true}) do
        local p = l4d.world_to_screen(e.position)
        if p and p.on_screen then
            render.text(p.x, p.y, e.name, {1,.4,.3,1})
        end
    end
end)
```

## L4D snapshots and lifetime

The engine thread captures copied data; Lua never dereferences an entity or calls engine interfaces. All callbacks within a UI frame read one pinned snapshot. `sequence` identifies that capture, not an entity's lifetime. A rendered frame can reuse a previous engine capture. Entity indices may be recycled: reacquire entities each callback and do not assume an index identifies the same actor across frames or maps.

Game data follows the host's existing session checks. On disconnection, map change or a stopped host, `local_player()` and `camera()` return nil, entity queries return empty/nil and projection returns nil after the next capture. `session().allowed` is false in the standalone preview; `data_available` may be true there for explicitly synthetic data. The preview is not live-game validation.

Returned tables are independent copies. Editing them does not change the game or later queries. Read functions work at top level or inside callbacks, but game data may not exist during script loading. Perform ongoing logic in `events.on("update", ...)`; draw only in UI/overlay callbacks.

## L4D session and player

| Function | Return |
| --- | --- |
| `l4d.info()` | `{api_version, game_id, game, map, preview, sequence, engine_time, max_entities}`. `game_id` is `l4d1`, `l4d2`, `preview`, or empty before attachment. Time is engine time in seconds, not wall-clock time. |
| `l4d.session()` | `{allowed, data_available, preview, stopped, insecure, in_game, connected, loopback, demo, local_player, menu_open, reason}`. `local_player` here is a boolean. |
| `l4d.local_player()` | Player table below, or nil. No entity subscription required. |
| `l4d.camera()` | `{position, angles, width, height, sequence}` or nil. Position is the captured local eye position; angles are engine view angles. Projection uses the captured engine world-to-screen matrix, which can differ from the eye in spectator/third-person views. |
| `l4d.status()` | Human-readable host/session status (existing API). |
| `l4d.metrics()` | Three values: horizontal speed in Source units/s, built-in scene entity count, receive-property count (existing API). This entity count is independent of Lua subscriptions. |

Player fields: `index`, `sequence`, `team`, `health`, `flags`, `water_level`, `move_type`, `alive`, `on_ground`, `incapacitated`, `hanging`, `position`, `eye_position`, `velocity`, `view_angles`, `speed`, and optional `weapon`. `speed` is horizontal Source units per second; velocity is Source units per second on each axis. Team numbers are raw engine team IDs (2 survivors, 3 infected).

`weapon` is `{index, class_name, clip?, reloading?}`. It is absent when there is no active weapon. Clip/reload fields are absent if the receive table does not expose them; clip may be -1 for weapons without a magazine. No reserve-ammo value is invented.

## L4D entity subscriptions

`l4d.watch(options)` replaces this script's subscription and returns its normalized options. Options: `survivors=true`, `infected=true`, `pickups=true`, `bones=false`, `range=150`. Range is metres and clamps to 1-300. Unknown keys, non-boolean flags, non-finite values and wrong types produce Lua errors. `l4d.watch(false)` releases the subscription immediately on the UI side.

Subscriptions take effect on the next engine capture, so queries directly after a change may still show the previous capture. They are removed on stop, reload and failed script loading. Requests from running scripts are merged into one native scan; each script's queries still obey its own categories/range/bone flag. The merged scan may collect more data than one script requested. A disabled feature should release its subscription, as shown by the examples.

Collection is independent of built-in ESP, radar and infected/category toggles. It includes at most 512 recognized, non-dormant, non-local survivors/infected/unowned pickups, in engine-index order within the requested range. Known dead actors and held/owned pickups are excluded. It is not an enumeration of all Source classes. Actors without networked health remain available with nil health. Bone capture also enables animated hitbox fitting and costs more than basic snapshots.

| Function | Return |
| --- | --- |
| `l4d.capture()` | `{requested, captured, truncated, sequence, entity_count}`. Requested is this script's options; captured is the merged options used for this snapshot. Count/truncation describe the merged snapshot, not a filtered query. |
| `l4d.entities([filter])` | Dense array of entity tables. No subscription means an empty array. |
| `l4d.entity(index)` | One currently subscribed entity or nil. |
| `l4d.bones(index)` | Array of `{bone, parent, from, to}` segments. Empty if absent, unsubscribed, or bones were not requested/available. Bone and parent are zero-based engine bone indices; the array uses Lua's one-based indexing. |
| `l4d.screen_box(index)` | `{left, top, right, bottom, width, height, fitted}` in pixels, or nil. `fitted` means animated body hitboxes were used; otherwise actor collision hull or pickup world bounds are used. Near-plane clipping and viewport clamping are applied to native snapshot boxes. |

`entities` filter fields are optional and intersect the subscription: `category="all"|"survivor"|"infected"|"pickup"`, `type="tank"` (exact stable type string), `range=300` (metres, clamps 0-300), `special=true|false`. An unknown type returns an empty result. `special=false` includes non-special actors and pickups; combine it with `category="infected"` to get common/uncommon/witch only. Projection and boxes indicate where an entity projects, not whether a wall occludes it; there is no line-of-sight trace API.

Entity fields: `index`, `sequence`, `team`, `category`, `type`, `name`, `class_name`, `model`, `position`, `bounds_min`, `bounds_max`, `distance_m`, `health?`, `max_health?`, `alive`, `incapacitated`, `hanging`, `special`, `bones_available`. Bounds are absolute world AABB corners, not offsets. `name` is a classified display label, not a Steam/player nickname. Survivor max health falls back to 100 when unavailable; infected maximum health is absent when not networked. For pickups, `alive` is a generic active-entity flag, not an actor life state.

| Category | `type` values |
| --- | --- |
| survivor | `survivor` |
| infected | `unknown`, `common`, `uncommon`, `witch`, `smoker`, `boomer`, `hunter`, `spitter`, `jockey`, `charger`, `tank` |
| pickup | `weapons`, `melee`, `throwables`, `medical`, `ammo`, `upgrades`, `carryables` |

`special` includes unknown special infected and smoker/boomer/hunter/spitter/jockey/charger/tank. Witches are separate. Games only return types present in that game/map; L4D2-only types do not appear in stock L4D1. Classification uses the existing class/model classifier and can return `unknown` for custom mods.

## L4D projection and math

Vectors are Lua tables `{x=..., y=..., z=...}` in **Source coordinates and units**, with Z up. Angles use the same table shape: X pitch, Y yaw, Z roll, in degrees. Internal portable renderer coordinate conversion is handled by the host. Distances explicitly named `_m` and subscription/filter ranges are metres. Inputs must be finite numbers of magnitude at most 1e9.

| Function | Return |
| --- | --- |
| `l4d.world_to_screen(position)` | `{x, y, on_screen}` in physical pixels, or nil behind/outside the camera depth range or without game data. An offscreen point can return a table with `on_screen=false`. |
| `l4d.vec.add(a,b)`, `sub(a,b)` | Component sum/difference vector. |
| `l4d.vec.scale(v,n)` | Scaled vector. |
| `l4d.vec.dot(a,b)` | Scalar dot product. |
| `l4d.vec.length(v)`, `distance(a,b)` | Length/distance in the input's units. |
| `l4d.vec.normalize(v)` | Unit vector or nil for near-zero length. |
| `l4d.angle_to(eye,point)` | Source pitch/yaw/roll vector pointing toward a position. |
| `l4d.angle_fov(from,to)` | Angular distance between view-angle vectors in degrees. |
| `l4d.to_metres(units)`, `l4d.to_units(metres)` | Unit conversion; one Source unit is treated as .0254 metres by this project. |

DirectX and OpenGL use the same snapshot and projection APIs. Rendering still uses `render.*` from an overlay/UI callback.

## L4D feature integration

Use `features.add` to register your toggle/hotkey and `features.active` to gate behavior. Registered feature enabled state/hotkeys participate in the existing config system. Plain Lua locals such as the example sliders are per-run and are not automatically persisted. Use `features.list()` to discover actual IDs; `features.set`, `features.bind`, `features.color` and `ui.feature` also work with built-in IDs.

`l4d.setting(id, field [, value])` reads or updates the following numeric built-in properties. It returns the clamped value, truncating style indices to integers. Unknown ID/field pairs error. Non-finite values reset to that property's lower bound, preserving the existing setting API behavior. Changing a numeric property does not automatically enable its feature.

| ID | Field and values |
| --- | --- |
| `chams.visible`, `chams.hidden` | `style`: 0 Lit, 1 Flat, 2 Chrome, 3 Ghost, 4 Additive, 5 Wireframe, 6 Glass, 7 Glow, 8 Fullbright, 9 Chrome wireframe, 10 Ghost wireframe, 11 Neon wireframe |
| `chams.<target>.custom`, `chams.<target>.hidden` | `style`: same material indices; target IDs and pass switches below |
| `chams.enabled` | `style`: legacy alias for `chams.visible` (Players visible material) |
| `chams.selector`, `infected.selector`, `items.box` | `style`: selected category/type/box-style index; clamped to that feature's choices |
| `l4d.items`, `chams.enabled`, `infected.<type>` | `distance`: 1-300 metres |
| `l4d.items` | `textSize`: 10-24 pixels |
| `chams.pulse` | `thickness`: pulse frequency .5-5 Hz |
| `actor.box_padding` | `distance`: 0-10 percent |
| `actor.box_width`, `actor.box_height` | `distance`: legacy scale 25-100 / 50-100 percent |
| `aim.profile`, `aim.mode`, `aim.point` | `style`: profile 0 Legit/1 Rage; mode 0 Camera/1 Silent/2 Packet silent; hitboxes 0 Upper body / 1 Chest / 2 Head / 3 Stomach / 4 Arms / 5 Legs / 6 All |
| `aim.legit`, `aim.rage`, `aim.range` | `distance`: FOV 1-180 degrees / FOV 1-180 degrees / range 1-300 metres |
| `aim.smoothing` | `distance`: 1-30 |
| `trigger.hitbox`, `trigger.rage.hitbox` | `style`: the same 0-6 hitbox choices as `aim.point`; default 6 All |
| `trigger.delay`, `trigger.range`, `trigger.rage.delay`, `trigger.rage.range` | `distance`: 0-500 ms / 1-300 metres |
| `view.thirdperson_distance`, `view.thirdperson_side`, `view.thirdperson_height` | `distance`: 40-200 / -40 to +40 / -30 to +30 Source units; enable with `features.set("view.thirdperson", true)`, no preset shortcut |
| `view.camera_fov`, `view.model_fov`, `view.offset_x`, `view.offset_y`, `view.offset_z` | `distance`: camera/model FOV in degrees or viewmodel offset in Source units, clamped to the feature's menu bounds |

### Visual utility actions

Use `features.trigger(id)` to run an action once, or `ui.feature(id)` to draw its button and optional shortcut control. These actions have no assigned hotkeys and do not appear in the active-features list. They edit the existing saved feature settings.

| Action ID | Result |
| --- | --- |
| `view.swap_shoulder` | Negates the current shoulder offset; a centered/invalid offset selects +20. Does not enable third person. |
| `view.center_camera` | Sets the shoulder offset to zero. |
| `world.night`, `world.warm`, `world.cool` | Enables coordinated world/prop/sky tint colors. |
| `world.reset` | Disables all three tint overrides so the material controller restores original colors. |
| `chams.copy_pass` | Copies the selected target's Visible color/alpha/material to Invisible. |
| `chams.swap_passes` | Exchanges the selected target's Visible and Invisible color/alpha/material. |

Chams actions preserve target enable state, both pass switches and hotkeys. Set `chams.selector` first when invoking them from a script. Other targets remain unchanged.

The shared `ui.tr` API also works in L4D scripts. Format its logical string before passing it to `imgui.text` or `render.text` so live language selection and right-to-left text work correctly; see the bundled portable localization reference.

### Chams targets and passes

Enable `chams.enabled`, then enable each desired target. Target enable IDs are `chams.survivors` (other survivor players), `chams.self` (your world player model), `chams.arms`, `chams.held` (first-person weapon/held supplies), `chams.weapons` (dropped firearms/melee), `chams.pickups` (dropped items), and `chams.common`, `chams.uncommon`, `chams.witch`, `chams.smoker`, `chams.boomer`, `chams.hunter`, `chams.spitter`, `chams.jockey`, `chams.charger`, `chams.tank`, `chams.unknown`. `chams.special` is an additional master switch for Smoker through Unknown special; Witch has its own independent toggle. Self requires the game to draw the local world model, for example with `view.thirdperson`.

Players use `chams.visible` / `chams.hidden` for Visible / Invisible. Every other target uses `<target ID>.custom` / `<target ID>.hidden`. Each pass has an independent enabled state, color (including alpha), hotkey and material. Use `features.set`, `features.color`, `features.bind`, and `l4d.setting(pass_id, "style", material_index)` respectively. Invisible is the ignore-depth pass: hidden surfaces show through geometry. With Visible off, the original model covers unoccluded surfaces. Both passes off leaves the original model. Arms/Weapon use the game's separate first-person projection, so Invisible may look the same as Visible there.

The old `.custom` IDs now represent the **Visible switch**, not a global-appearance inheritance option. Loading an old profile automatically copies inherited global colors/materials into each target, preserves explicit equipment appearances, and turns Visible on where the old Custom appearance switch was off. Old first-person hidden passes remain off. After migration, targets are independent; new profiles retain explicit Visible/Invisible choices. Scripts that used `.custom` to switch inheritance should use the new pass semantics instead. `chams.enabled` remains the overall on/off switch; its old color property is unused. The `style` compatibility alias is provided through `l4d.setting`, not direct access to the feature's legacy style property.

`chams.selector` indices are 0 Players, 1 Arms, 2 Weapon, 3 Dropped weapons, 4 Items, 5 Self, 6 Common, 7 Uncommon, 8 Witch, 9 Smoker, 10 Boomer, 11 Hunter, 12 Spitter, 13 Jockey, 14 Charger, 15 Tank, 16 Unknown special. Selection only changes which settings the menu edits; it does not enable or disable targets.

```lua
features.set("chams.enabled", true)
features.set("chams.tank", true)
features.set("chams.special", true)
features.set("chams.tank.custom", true) -- Visible
features.set("chams.tank.hidden", true) -- Invisible
features.color("chams.tank.custom", 0.3, 0.8, 1, 1)
features.color("chams.tank.hidden", 1, 0.25, 0.3, 0.6)
l4d.setting("chams.tank.custom", "style", 8) -- Fullbright
l4d.setting("chams.tank.hidden", "style", 11) -- Neon wireframe
```

```lua
-- Explicit user action: integrate a built-in view setting into a custom page.
ui.subtab("settings", "my_view", "My view", function()
    ui.feature("view.camera_fov")
    local fov = l4d.setting("view.camera_fov", "distance")
    local changed, value = ui.slider("Camera FOV", fov, 60, 140)
    if changed then l4d.setting("view.camera_fov", "distance", value) end
end)
```

Built-in changes remain after a script stops, as with the portable feature API. If temporarily controlling a feature, save the previous value and restore it in a shutdown callback (avoid overwriting subsequent user/other-script edits). This extension provides snapshots and built-in feature controls; it does not expose raw memory, arbitrary engine commands, game-event subscriptions, entity spawning, command/packet callbacks or arbitrary weapon changes. `update` and `shutdown` remain the supported portable events.

## L4D performance and troubleshooting

Keep ranges modest, request only relevant categories, and leave bones off unless needed. Query once per callback and reuse the result; querying returns new tables. A script has the existing 16 MiB Lua allocator limit, frame callback budget and render-call limit. The examples cap drawn actors/segments to stay within the draw budget.

Empty entities: check `l4d.session()`, register `l4d.watch`, allow an engine capture, check filters/range, and inspect `l4d.capture().truncated`. Bones may be unavailable while a pose is being initialized. Nil health means unavailable, not zero. A missing `l4d`/`L4D_API_VERSION` means the wrong/older host is running. Reload after updating the native host; copying docs or examples only does not update a loaded DLL.

## Aim activation and indicators

`l4d.keybind(id [, action [, mode]])` manages `aim.key` (Legit), `aim.rage.key` (Rage), `trigger.key` (Legit), or `trigger.rage.key` (Rage). It returns `key, mode, capturing, waiting`. Actions are `"capture"` (wait 500 ms, release all keys, then accept a fresh press), `"clear"`, or `"mode"` with 0 Always, 1 Toggle, 2 Hold, 3 Hold to disable. Escape cancels, Delete clears, and losing focus cancels capture. The built-in pages use native `ui.button` and `ui.combo` controls. Bindings persist through the regular config system; scripts can also assign them using `features.bind`.

Aim and trigger keys start unassigned with Hold mode selected. An unassigned key preserves the existing master switch behavior. A bound key is an additional activation condition: it cannot enable a disabled master switch. Aim's Only while firing and Silent/pSilent firing requirements still apply. The 500 ms delay applies to assigning a key, not to firing or aiming.

`aim.rage.circle`, `aim.rage.snapline`, `aim.rage.dot` and the corresponding `aim.legit.*` features have independent switches and RGBA colors. They start off. Enable the main aim switch and select that profile to render its indicators. The FOV circle uses the current camera projection, including zoom and aspect ratio. Its radius represents the configured angular targeting limit; wide cones can extend beyond the viewport, and at 90 degrees or more the boundary is behind the camera. Snapline and dot follow the actual selected aim point only while aim is active; stale, invalid or mismatched-profile targets disappear. They do not depend on ESP being enabled. pSilent retains the most recent shot point during its following packet-flush command without extending the 250 ms expiry.

### Independent combat profiles

Ragebot and Legitbot retain separate enable switches, keys, target filters, modes, aim points, ranges and weapon controls. Viewing a tab does not change the active profile; use its explicit profile button. `aim.profile` remains 0 Legit / 1 Rage. Legacy `aim.enabled`, `aim.mode`, `aim.key`, `aim.point`, `aim.range`, `aim.lock`, `aim.attack`, `aim.visible`, `aim.common`, `aim.special`, `aim.witch`, `aim.survivors` and `weapon.no_recoil` / `weapon.no_spread` now address Legit. The Rage equivalents insert `rage.` after `aim.` or `weapon.`. Angular limits retain `aim.legit` / `aim.rage` for compatibility. Triggerbot has separate `trigger.*` (Legit) and `trigger.rage.*` (Rage) settings, including enable, activation key, delay, range, target filters and hitboxes. Both use the active `aim.profile`; viewing either page does not change it. Each page edits its own profile’s weapon controls. Schema-3 migration copies older shared trigger settings into both profiles and converts Head only into the Head selector.

Old shared configurations are copied into Rage once when loaded; new profiles persist each side independently. Silent and pSilent use exact head/chest hitbox shot angles. Smoothing applies only to Legit Camera mode. Animated aim points do not depend on ESP/skeleton being enabled. Trigger eligibility rejects known-dead entities but does not treat missing common-infected health properties as zero.


### Combat target dropdowns

Ragebot, Legitbot and both Triggerbot pages use a multi-select Targets dropdown. Click Common infected, Special infected, Witch or Survivors to toggle its highlight; the popup stays open for further selections. Clicking outside or pressing Escape closes it. The dropdown edits the existing `common`, `special`, `witch` and `survivors` booleans under `aim.`, `aim.rage.`, `trigger.` or `trigger.rage.`. Existing configs and script-set values carry over, and each profile retains independent selections. The generic Lua control is `ui.multi_combo(label, booleanArray, labels)`.

### Combat hitbox selectors

`l4d.setting(id, "style", selection)` supports `aim.point`, `aim.rage.point`, `trigger.hitbox` and `trigger.rage.hitbox`:

| Value | Selection | Model hitgroups |
| --- | --- | --- |
| 0 | Upper body | Head, chest and stomach |
| 1 | Chest | Chest only |
| 2 | Head | Head only |
| 3 | Stomach | Stomach only |
| 4 | Arms | Left and right arms |
| 5 | Legs | Left and right legs |
| 6 | All | All available hitboxes |

Aim resolves centers from the entity’s current hitbox set and animated bone matrices, then chooses the closest eligible point inside the FOV and range. With Visible only enabled it tries another selected point when the closer point is obstructed. It never substitutes another region when a strict selection is missing. One bone setup is shared by all candidate points for that entity; no limb-specific bone indices are assumed between L4D1/L4D2 models. Lock on keeps the entity while rechecking its selected hitboxes each command.

Triggerbot filters the actual shot trace hitgroup, without moving the crosshair. Changing profile or hitbox selection restarts its reaction delay. The legacy `trigger.head` and `trigger.rage.head` script toggles still override the selector while enabled; explicitly writing the corresponding hitbox selector clears that override.

```lua
l4d.setting("aim.point", "style", 2)             -- Legit: head
l4d.setting("aim.rage.point", "style", 6)        -- Rage: all available hitboxes
l4d.setting("trigger.hitbox", "style", 1)       -- Legit Triggerbot: chest
l4d.setting("trigger.rage.hitbox", "style", 0)  -- Rage Triggerbot: upper body
```
