-- Read-only overlay. Run from Lua > Scripts; Stop removes it.
ui.overlay('megabonk_status', function()
    local state = megabonk.status()
    render.text(24, 80, 'Megabonk: ' .. state.message, {0.8, 0.9, 1, 1}, 14)
end)
