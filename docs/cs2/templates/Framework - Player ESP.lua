-- Independent player ESP: no built-in ESP settings are changed.
-- Extend render_player to own placement, filtering, colors and drawing.
local enabled=features.add{id="enabled",label="Custom player ESP",default=false}
local options={names=true,health=true,enemies=true,color={.35,.75,1,1}}
ui.tab("framework","Player ESP framework",function()
    ui.feature(enabled)
    local changed,value
    for _,row in ipairs({{"Names","names"},{"Health bar","health"},{"Enemies only","enemies"}}) do
        changed,value=imgui.checkbox(row[1],options[row[2]])
        if changed then options[row[2]]=value end
    end
    changed,value=imgui.color_edit("Player color",options.color)
    if changed then options.color=value end
end)
local function render_player(player)
    local origin=player.origin
    local head=entity.bone(player.handle,6)
    if not head then head={x=origin.x,y=origin.y,z=origin.z+(player.crouched and 54 or 72)} end
    local bottomX,bottomY=render.world_to_screen(origin.x,origin.y,origin.z)
    local topX,topY=render.world_to_screen(head.x,head.y,head.z+8)
    if not topX or not bottomX then return end
    local height=bottomY-topY
    local _,screenHeight=render.screen_size()
    if height<6 or height>screenHeight*2 then return end
    local width=height*.43
    local x,y=bottomX-width*.5,topY
    render.rect(x-1,y-1,width+2,height+2,{0,0,0,.8},false,0)
    render.rect(x,y,width,height,options.color,false,0)
    if options.health then
        local fraction=math.max(0,math.min(1,player.health/100))
        render.rect(x-5,y,3,height,{.04,.04,.04,.85},true,0)
        render.rect(x-5,y+height*(1-fraction),3,height*fraction,{1-fraction,fraction,.15,1},true,0)
    end
    if options.names then
        local label=player.name.."  "..player.health.." HP"
        local tw=render.measure_text(label,13)
        render.text(bottomX-tw*.5,y-17,label,options.color,13)
    end
end
ui.overlay("framework_overlay",function()
    if not features.active(enabled) then return end
    local me=entity.get_local_player()
    if not me then return end
    for _,player in ipairs(entity.get_players(options.enemies,true)) do
        if not player.is_local then render_player(player) end
    end
end)
