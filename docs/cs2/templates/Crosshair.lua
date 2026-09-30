-- Minimal CS2 rendering template. Unload removes every callback and drawing.
local enabled=features.add{id="enabled",label="Lua crosshair",default=true,key="F7"}
ui.tab("crosshair","Crosshair",function() ui.feature(enabled);ui.keybind(enabled,"Toggle key") end)
ui.overlay("crosshair_overlay",function()
    local me=entity.get_local_player()
    if not features.active(enabled) or not me or not me.alive then return end
    local w,h=render.screen_size();local s=render.scale();local c=render.theme().accent
    render.line(w/2-9*s,h/2,w/2-3*s,h/2,c,2*s)
    render.line(w/2+3*s,h/2,w/2+9*s,h/2,c,2*s)
    render.line(w/2,h/2-9*s,w/2,h/2-3*s,c,2*s)
    render.line(w/2,h/2+3*s,w/2,h/2+9*s,c,2*s)
end)
