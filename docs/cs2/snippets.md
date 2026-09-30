# First script

Create a script from Scripts, paste this example in the editor, and choose Run Lua. Run becomes Unload while the script is active. Open folder and Refresh are in the manager's Other group. Script UI opens custom script pages.

## A toggleable CS2 overlay

```lua
local enabled = features.add {
    id = "health", label = "My health overlay", default = true, key = "F8"
}
ui.tab("controls", "My overlay", function()
    ui.feature(enabled)
    ui.keybind(enabled, "Toggle key")
end)
ui.overlay("health_overlay", function()
    local player = entity.get_local_player()
    if not features.active(enabled) or not player or not player.alive then return end
    render.text(24, 120, player.name .. "  " .. player.health .. " HP",
                render.theme().accent, 18)
end)
```

## Choose the correct API

CS2 uses host API 2.4 and UI API 1.1 on Lua 5.4.7. Player snapshots and projections can be unavailable during a map change; check for nil. Settings IDs come from settings.list(). CS2 implements its own ESP color settings; shared esp_colors integration is not available. Aimware CSGO scripts need a manual port to these APIs.

## Template controls

Download a template below or use its bundled copy in Scripts. Standalone tools opens with F9 and Visual Studio with F10. Both offer an Open / close key setting and Save preferences. Hidden windows keep their selected overlays running. Unload removes script windows, callbacks and hotkeys. Changes to native CS2 settings persist.
