-- CS2 floating tools based on the Simple-base UI-v2 standalone template.
-- F9 toggles the window; select another open/close key below.
local keys={"F9","F8","F10","F11","Insert"}
local options={key=1,speed=false,crosshair=false}
local saved=storage.read("options",{})
if type(saved)=="table" then
    if type(saved.key)=="number" and saved.key==math.floor(saved.key) and saved.key>=1 and saved.key<=#keys then options.key=saved.key end
    for _,id in ipairs({"speed","crosshair"}) do if type(saved[id])=="boolean" then options[id]=saved[id] end end
end
local saveStatus=""
local visible=features.add{id="menu",label="CS2 standalone tools",default=true,key=keys[options.key],active_list=false}
local window=ui.window("tools","CS2 Standalone",{width=420,height=360,x=30,y=45,menu_only=false,attach="none"},function()
    local me=entity.get_local_player()
    imgui.text(me and (me.name.."  |  "..me.health.." HP") or "Waiting for a local player")
    imgui.text(string.format("%.0f FPS  |  %s",engine.fps(),cs2.map_name()))
    imgui.separator()
    local changed,value
    changed,value=imgui.checkbox("Speed HUD",options.speed);if changed then options.speed=value end
    changed,value=imgui.checkbox("Center crosshair",options.crosshair);if changed then options.crosshair=value end
    for _,item in ipairs({{"Player ESP","espEnabled"},{"Player boxes","espBox"},{"Player names","espName"}}) do
        changed,value=imgui.checkbox(item[1],settings.get(item[2]));if changed then settings.set(item[2],value) end
    end
    imgui.separator()
    changed,value=imgui.combo("Open / close key",options.key,keys)
    if changed then options.key=value;features.bind(visible,keys[value],"toggle") end
    if imgui.button("Save preferences") then
        local ok=pcall(storage.write,"options",options)
        saveStatus=ok and "Preferences saved" or "Could not save preferences"
    end
    imgui.same_line()
    if imgui.button("Close window") then features.set(visible,false) end
    if saveStatus~="" then imgui.text(saveStatus) end
end)
local wasVisible=true
events.on("update",function()
    local active=features.active(visible)
    -- Keep the native title-bar close button and the feature hotkey in sync.
    if wasVisible and active and not ui.window_visible(window) then
        features.set(visible,false);active=false
    end
    ui.window_visible(window,active);wasVisible=active
end)
ui.overlay("tools_hud",function()
    local me=entity.get_local_player();if not me or not me.alive then return end
    local w,h=render.screen_size();local tint=render.theme().accent;local s=render.scale()
    if options.speed then render.text(25*s,h-60*s,string.format("%.0f u/s",math.sqrt(me.velocity.x^2+me.velocity.y^2)),tint,20*s) end
    if options.crosshair then render.line(w/2-7*s,h/2,w/2+7*s,h/2,tint,2*s);render.line(w/2,h/2-7*s,w/2,h/2+7*s,tint,2*s) end
end)
