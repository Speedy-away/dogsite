-- Read-only run overlay; Stop removes it. Values refresh up to ten times per second.
ui.overlay('megabonk_run_hud', function()
    local run = megabonk.run()
    if not run then return end
    local player = run.player
    local minutes = math.floor(run.seconds / 60)
    local seconds = math.floor(run.seconds % 60)
    local label = string.format('%02d:%02d  |  Level %d  |  Gold %d', minutes, seconds, player.level, player.gold_int)
    if player.paused then label = label .. '  |  Paused' end
    render.text(24, 108, label, {1, 0.86, 0.4, 1}, 16)
    render.text(24, 130, string.format('HP %d/%d  |  Shield %.0f/%.0f', player.hp, player.max_hp, player.shield, player.max_shield), {0.6, 1, 0.7, 1}, 14)
    local xp = 'XP ' .. player.xp
    if player.level_xp and player.next_level_xp then
        xp = xp .. string.format('  |  To next level: %d', math.max(0, player.next_level_xp - player.xp))
    end
    render.text(24, 150, xp, {0.65, 0.8, 1, 1}, 14)
end)
