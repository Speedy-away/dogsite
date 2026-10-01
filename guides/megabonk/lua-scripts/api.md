# Megabonk Lua API

The canonical Simple-base UI API remains available in both editions: `features`, `events`, `ui`, `widgets`, `imgui`, `render` and `engine`. Scripts, Lua Editor and Console are sub-tabs of the dedicated Lua sidebar tab. Config and Hotkeys are under Settings. Script files are stored in `C:/Scooby/Megabonk/scripts`; the older runtime and `C:/scooby/UI/UI-scripts` remain separate and supported through Existing scripts.

This extension uses copied status/catalog data and the existing game-thread action queue. Feature values reach gameplay at the end of the next UI frame. Numeric values do not enable their locks or parents automatically. Actions require the verified host and appropriate run/save context. Accepted actions are queued, not completed. Poll `action_status()` for progress. Stopping, reloading or failing script startup cancels its remaining queued work; completed rewards/unlocks remain applied. Unlock operations save progression. Native gameplay acceptance remains pending.

## Megabonk

### megabonk.info

```text
megabonk.info() -> {game, api_version, ui_version}
```

```lua
assert(MEGABONK_API_VERSION == '1.1')
print(megabonk.info().game, megabonk.info().ui_version)
```

### megabonk.capabilities

```text
megabonk.capabilities() -> {settings, catalog, spawn_pickup, give_item, collect_xp, unlocks, script_action_cleanup, player_snapshot, run_snapshot, entities, world_to_screen, native_memory}
```

```lua
local supported = megabonk.capabilities()
assert(supported.settings and supported.script_action_cleanup)
assert(not supported.entities and not supported.native_memory)
```

### megabonk.status

```text
megabonk.status() -> {host, ticks, ready, running, writable, busy, ticket, owned, completed, total, changed, message}
```

```lua
local state = megabonk.status()
print(state.host, state.running, state.writable, state.message)
```

## Megabonk run snapshots

### megabonk.player

```text
megabonk.player() -> {hp, max_hp, shield, max_shield, xp, level, level_xp?, next_level_xp?, gold, gold_int, rerolls, banishes, skips, paused} or nil
Copied living-player values, sampled at most 10 times/second; nil outside a verified active run, during transitions, or after 500 ms without a fresh sample.
xp is cumulative; level_xp and next_level_xp are native cumulative thresholds, omitted if unavailable. Assignments to this table do not change gameplay.
```

```lua
local player = megabonk.player()
if player then
    print(player.hp, player.max_hp, player.level, player.gold_int)
    if player.next_level_xp then
        print('XP to next level', math.max(0, player.next_level_xp - player.xp))
    end
end
```

### megabonk.run

```text
megabonk.run() -> {seconds, generation, sequence, player} or nil
Timer and player from one copied sample. Same availability as player(); seconds uses the current game timer after timer settings apply.
generation changes on run/stage cleanup or host stop (not a persistent run ID); sequence changes on samples/resets. Use the nested player for a coherent HUD.
```

```lua
ui.overlay('run_clock', function()
    local run = megabonk.run()
    if not run then return end
    local text = string.format('%02d:%02d | Level %d | HP %d/%d',
        math.floor(run.seconds / 60), math.floor(run.seconds % 60),
        run.player.level, run.player.hp, run.player.max_hp)
    render.text(24, 190, text, {1, 0.9, 0.6, 1}, 16)
end)
```

## Megabonk settings

### megabonk.settings.list

```text
megabonk.settings.list(filter='') -> metadata[]; case-sensitive ID/category filter
```

```lua
for _, setting in ipairs(megabonk.settings.list('ct')) do
    print(setting.id, setting.type, setting.enabled)
end
```

### megabonk.settings.info

```text
megabonk.settings.info(id) -> {id, label, description, category, parent, type, enabled, active, key, value, minimum?, maximum?} or nil
```

```lua
local setting = megabonk.settings.info('moveSpeed')
print(setting.parent, setting.minimum, setting.maximum, setting.active)
```

### megabonk.settings.get

```text
megabonk.settings.get(id) -> boolean or number; unknown IDs raise an error
```

```lua
print(megabonk.settings.get('godmode'))
print(megabonk.settings.get('xpMultiplier'))
```

### megabonk.settings.set

```text
megabonk.settings.set(id, value) -> stored value; strict boolean/finite number, catalog bounds, integer controls require whole numbers
```

```lua
megabonk.settings.set('xpMultiplier', 2)
megabonk.settings.set('godmode', true)
```

### megabonk.settings.enabled

```text
megabonk.settings.enabled(id, enabled?) -> boolean; changes only that feature's enable state
```

```lua
megabonk.settings.set('moveSpeed', 1.5)
megabonk.settings.enabled('moveSpeed', true)
megabonk.settings.enabled('playerStats', true)
```

## Megabonk catalogs

### megabonk.pickups

```text
megabonk.pickups() -> {id, name}[]; IDs 0-10: XP, Gold, Health, Nuke, Time, Shield, Rage, Haste, Stonks, Magnet, Silver
```

```lua
for _, pickup in ipairs(megabonk.pickups()) do print(pickup.id, pickup.name) end
```

### megabonk.categories

```text
megabonk.categories() -> {'characters','weapons','tomes','items','maps','hats'}
```

```lua
for _, category in ipairs(megabonk.categories()) do print(category) end
```

### megabonk.catalog

```text
megabonk.catalog(category=nil, filter='') -> {id, name, category}[]; current copied catalog, case-sensitive name filter
```

```lua
for _, item in ipairs(megabonk.catalog('items')) do print(item.id, item.name) end
```

### megabonk.refresh_catalog

```text
megabonk.refresh_catalog() -> no values; requests refresh on the game thread
```

```lua
megabonk.refresh_catalog()
events.on('update', function()
    if megabonk.status().ready then
        -- Read the latest catalog when needed.
    end
end)
```

## Megabonk actions

### megabonk.spawn_pickup

```text
megabonk.spawn_pickup(id, quantity=1, value=100, radius=2) -> accepted, message, ticket?; quantity 1-25, value 1-10000, radius 0-8 metres
```

```lua
ui.subtab('settings', 'spawn_example', 'Pickups', function()
    if imgui.button('Spawn health') then
        local accepted, message = megabonk.spawn_pickup(2, 1)
        print(accepted, message)
    end
end)
```

### megabonk.give_item

```text
megabonk.give_item(catalog_id, quantity=1) -> accepted, message, ticket?; quantity 1-25; native stack/challenge limits apply
```

```lua
ui.subtab('settings', 'item_example', 'Items', function()
    local items = megabonk.catalog('items')
    if items[1] and imgui.button('Give first catalog item') then
        print(megabonk.give_item(items[1].id, 1))
    end
end)
```

### megabonk.collect_xp

```text
megabonk.collect_xp() -> accepted, message, ticket?; queues native collection of existing XP
```

```lua
ui.subtab('settings', 'xp_example', 'Collect XP', function()
    if imgui.button('Collect XP') then print(megabonk.collect_xp()) end
end)
```

### megabonk.unlock

```text
megabonk.unlock(category, catalog_id) -> accepted, message, ticket?; completes prerequisites, unlocks selected content and saves progression
```

```lua
ui.subtab('settings', 'unlock_example', 'Unlock', function()
    local hats = megabonk.catalog('hats')
    if hats[1] and imgui.button('Unlock first hat and save') then
        print(megabonk.unlock('hats', hats[1].id))
    end
end)
```

### megabonk.unlock_all

```text
megabonk.unlock_all(category) -> accepted, message, ticket?; queues the current category and saves progression
```

```lua
ui.subtab('settings', 'unlock_all_example', 'Unlock maps', function()
    if imgui.button('Unlock all maps and save') then
        print(megabonk.unlock_all('maps'))
    end
end)
```

### megabonk.action_status

```text
megabonk.action_status() -> {ready, running, writable, busy, ticket, owned, completed, total, changed, message}
```

```lua
local last = ''
events.on('update', function()
    local state = megabonk.action_status()
    if state.message ~= last then print(state.message); last = state.message end
end)
```

### megabonk.cancel_action

```text
megabonk.cancel_action() -> boolean; cancels only the calling script's currently owned batch; completed changes remain applied
```

```lua
ui.subtab('settings', 'cancel_example', 'Cancel batch', function()
    if imgui.button('Cancel my remaining actions') then
        print(megabonk.cancel_action())
    end
end)
```

## Megabonk built-in pages

### megabonk.page

```text
megabonk.page(name) -> no values; UI callbacks only; self, damage, experience, inventory, modifiers, world, spawner, misc, unlocks
```

```lua
local tab = ui.tab('my_megabonk', 'My Megabonk')
ui.subtab(tab, 'spawner', 'Spawner', function() megabonk.page('spawner') end)
```

### megabonk.legacy_scripts

```text
megabonk.legacy_scripts() -> no values; draws the existing script controls in UI callbacks only
```

```lua
ui.subtab('settings', 'my_legacy', 'Existing scripts', function()
    megabonk.legacy_scripts()
end)
```
