-- Copied CS2 velocity, with frame-rate-independent display smoothing.
local enabled=features.add{id="enabled",label="Lua speed HUD",default=true}
local speed=0
ui.tab("speed","Speed HUD",function() ui.feature(enabled) end)
events.on("update",function()
    local me=entity.get_local_player()
    local target=me and me.alive and math.sqrt(me.velocity.x^2+me.velocity.y^2) or 0
    speed=speed+(target-speed)*(1-math.exp(-12*math.max(0,engine.delta_time())))
end)
ui.overlay("speed_overlay",function()
    local me=entity.get_local_player()
    if not features.active(enabled) or not me or not me.alive then return end
    local w,h=render.screen_size();local s=render.scale();local t=render.theme()
    render.rect(24*s,h-78*s,180*s,44*s,{.04,.05,.06,.9},true,5*s)
    render.text(36*s,h-68*s,string.format("SPEED   %.0f u/s",speed),t.accent,17*s)
end)
