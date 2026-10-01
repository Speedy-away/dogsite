-- Uses the same feature IDs, settings and keybinds as the built-in menu.
local tab = ui.tab('megabonk_tools', 'Megabonk tools')
ui.subtab(tab, 'player', 'Player', function()
    ui.group('Player controls', function()
        ui.feature('godmode')
        ui.feature('xp')
        local changed, amount = imgui.slider_int('XP multiplier', megabonk.settings.get('xpMultiplier'), 1, 20)
        if changed then megabonk.settings.set('xpMultiplier', amount) end
    end)
end)
