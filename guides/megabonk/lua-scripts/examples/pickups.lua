-- Actions only run after clicking a button. Stop cancels this script's pending batch.
local tab = ui.tab('megabonk_pickups', 'Pickup tools')
local count = 1
ui.subtab(tab, 'pickups', 'Pickups', function()
    ui.group('Spawn pickups', function()
        local changed
        changed, count = imgui.slider_int('Quantity', count, 1, 25)
        for _, pickup in ipairs(megabonk.pickups()) do
            if imgui.button('Spawn ' .. pickup.name) then
                print(megabonk.spawn_pickup(pickup.id, count))
            end
        end
    end)
    ui.group('Action status', function()
        imgui.text(megabonk.action_status().message)
        if imgui.button('Collect all XP') then print(megabonk.collect_xp()) end
        if imgui.button('Cancel my batch') then print(megabonk.cancel_action()) end
    end)
end)
