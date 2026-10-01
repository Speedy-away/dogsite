-- Vesper: standalone LuaJIT menu. F6 or LB+RB+X toggles the menu.
-- Keep Vesper/ beside this file. No download or auto-update is performed.
assert(compat and compat.yim and compat.yim.ImGui.GetDisplaySize,"Update Scooby: Studio requires the 2026.10.1 GUI API")
local state=require("Vesper.model").new()
local host=require("Vesper.host").new()
local ui=require("Vesper.ui")
local ok,saved=pcall(config.get,"studio.options",{})
if ok and type(saved)=="table" then
    for key,value in pairs(saved) do if state.options[key]~=nil and key~="auto_repair" and key~="hide_hud" and type(value)=="boolean" then state.options[key]=value end end
end
local ok,bookmarks=pcall(config.get,"studio.bookmarks",{})
if ok and type(bookmarks)=="table" then
    for key,p in pairs(bookmarks) do
        if (key=="0" or key=="1" or key=="2") and type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" and type(p.z)=="number" then state.bookmarks[key]=p end
    end
end
if not host.ready then state:report(host.reason,true) end
local render=gui.add_always_draw_imgui(function() ui.draw(state) end)
local worker=script.register_looped("scooby_studio",function()
    if state.stopped then return false end
    state:process(host)
    local ok,err=pcall(host.frame,host,state)
    if not ok then host.ready=false;state:report(err,true) end
end)
script.on_unload(function()
    state:stop();script.cancel_callback(worker);gui.remove_imgui(render);host:close()
end)

return {state=state, host=host}
