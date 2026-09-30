-- CS2 adaptation of the canonical Simple-base UI-v2 standalone layout.
-- All switches below control real script overlays or registered CS2 settings.
-- F10 opens/closes this window; overlays keep running while it is hidden.
local visible=features.add{id="menu",label="CS2 Visual Studio",default=true,key="F10",active_list=false}
local page="Main"
local saveStatus=""
local keys={"F10","F9","F8","F11","Insert"}
local prefs={crosshair=false,speed=false,vitals=false,labels=false,rainbow=false,size=8,gap=5,thickness=2,range=1500,opacity=85,windowKey=1}
local saved=storage.read("options",{})
if type(saved)=="table" then
    for k,v in pairs(prefs) do
        if type(v)=="boolean" and type(saved[k])=="boolean" then prefs[k]=saved[k] end
    end
    for k,limit in pairs({size={2,30},gap={0,20},thickness={1,5},range={100,5000},opacity={10,100},windowKey={1,#keys}}) do
        local v=saved[k]
        if type(v)=="number" and v==v then prefs[k]=math.floor(math.max(limit[1],math.min(limit[2],v))) end
    end
end
features.bind(visible,keys[prefs.windowKey],"toggle")
local c={bg={.055,.063,.071,1},panel={.075,.085,.096,1},header={.063,.074,.084,1},border={.16,.19,.22,1},text={.9,.92,.94,1},muted={.6,.65,.7,1},field={.09,.11,.13,1},hover={.13,.17,.2,1},clear={0,0,0,0}}
local s,font,accent=1,14,{.32,.66,.79,1}
local showFooter=true
local function gap(amount) imgui.dummy(0,amount*s) end
local function row(label, kind, value, options)
    local x,y=imgui.cursor()
    local width=imgui.available()
    local height=24*s
    local control=math.min(132*s,width*0.48)
    if kind=="check" then control=font+6*s
    elseif kind=="slider" then control=math.min(168*s,width*0.55) end
    draw.text(x,y+(height-font)*0.5,label,c.text,font)
    imgui.set_cursor_screen(x+width-control,y+(height-font-6*s)*0.5)
    imgui.set_next_item_width(control)
    local changed
    if kind=="check" then changed,value=imgui.checkbox("##"..label,value)
    elseif kind=="combo" then
        imgui.with_style_vars({WindowPadding={7*s,6*s}},function()
            changed,value=imgui.combo("##"..label,value,options)
        end)
    elseif kind=="slider" then
        changed,value=imgui.slider_int("##"..label,value,options[1],options[2],{style="track"})
        if imgui.is_item_hovered() and not imgui.is_item_active() then
            imgui.with_style_vars({WindowPadding={7*s,5*s}},function()
                imgui.tooltip("Drag to adjust. Click value to type.")
            end)
        end
    else imgui.text_colored(tostring(value),c.muted) end
    imgui.set_cursor_screen(x,y)
    imgui.dummy(width,height)
    return value
end

-- Titled, bordered panels with independent clipping/scrolling.
local function panel(title,height,contents)
    local x,y=imgui.cursor()
    local width=imgui.available()
    draw.rect(x,y+font*0.5,width,height-font*0.5,c.panel,true,4*s)
    draw.rect(x,y+font*0.5,width,height-font*0.5,c.border,false,4*s)
    local tw=imgui.text_size(title)
    draw.rect(x+(width-tw)*0.5-8*s,y,tw+16*s,font,c.bg,true)
    draw.text(x+(width-tw)*0.5,y,title,c.text,font)
    imgui.with_style_vars({WindowPadding={14*s,24*s},ChildBorderSize=0},function()
        imgui.child(title,width,height,contents,{padding=true})
    end)
end
local function columns(left,right)
    local width=imgui.available()
    if width<520*s then
        left();gap(14);right()
    else
        local half=(width-14*s)*0.5
        imgui.child("left_column",half,0,left)
        imgui.same_line(14*s)
        imgui.child("right_column",half,0,right)
    end
end

local function mainPage()
    columns(function()
        panel("Script visuals",195*s,function()
            prefs.crosshair=row("Custom crosshair","check",prefs.crosshair)
            prefs.speed=row("Speed HUD","check",prefs.speed)
            prefs.vitals=row("Health ring","check",prefs.vitals)
            prefs.labels=row("Player labels","check",prefs.labels)
            prefs.rainbow=row("Rainbow accent","check",prefs.rainbow)
        end)
        gap(14)
        panel("CS2 session",130*s,function()
            local me=entity.get_local_player()
            row("Map","text",cs2.map_name()~="" and cs2.map_name() or "Main menu")
            row("Player","text",me and me.name or "No local player")
            row("Health","text",me and tostring(me.health) or "Unavailable")
        end)
    end,function()
        panel("Crosshair",161*s,function()
            prefs.size=row("Length","slider",prefs.size,{2,30})
            prefs.gap=row("Gap","slider",prefs.gap,{0,20})
            prefs.thickness=row("Thickness","slider",prefs.thickness,{1,5})
        end)
        gap(14)
        panel("Labels and color",164*s,function()
            prefs.range=row("Max distance (units)","slider",prefs.range,{100,5000})
            prefs.opacity=row("Opacity (%)","slider",prefs.opacity,{10,100})
            imgui.text_wrapped("Player data updates each frame. Labels skip missing projections.")
        end)
    end)
end
local function visualsPage()
    columns(function()
        panel("Native player visuals",185*s,function()
            for _,item in ipairs({{"Player ESP","espEnabled"},{"Boxes","espBox"},{"Names","espName"}}) do
                local current=settings.get(item[2])
                local value=row(item[1],"check",current)
                if value~=current then settings.set(item[2],value) end
            end
            imgui.text_wrapped("These switches update the same settings as the CS2 menu.")
        end)
    end,function()
        panel("Live preview",250*s,function()
            local x,y=imgui.cursor();local w,h=imgui.available()
            local cx,cy=x+w/2,y+h/2
            draw.circle(cx,cy,35*s,accent,false,2*s)
            draw.line(cx-18*s,cy,cx+18*s,cy,accent,2*s)
            draw.line(cx,cy-18*s,cx,cy+18*s,accent,2*s)
            draw.text(x,y,"Accent follows the menu theme",c.muted,font)
            imgui.dummy(w,h)
        end)
    end)
end
local function settingsPage()
    columns(function()
        panel("Window controls",174*s,function()
            local before=prefs.windowKey
            prefs.windowKey=row("Open / close key","combo",prefs.windowKey,keys)
            if before~=prefs.windowKey then features.bind(visible,keys[prefs.windowKey],"toggle") end
            if imgui.button("Close window",-1,29*s) then features.set(visible,false) end
            imgui.text_wrapped("The same key reopens this window while the main menu is closed.")
        end)
    end,function()
        panel("Saved preferences",174*s,function()
            if imgui.button("Save preferences",-1,29*s) then
                local ok=pcall(storage.write,"options",prefs)
                saveStatus=ok and "Preferences saved" or "Could not save preferences"
            end
            if saveStatus~="" then imgui.text(saveStatus) end
            imgui.text_wrapped("Script overlays stop on Unload. Native CS2 settings keep their selected values.")
        end)
    end)
end

ui.overlay("visual_effects",function()
    local me=entity.get_local_player()
    if not me or not me.alive then return end
    local w,h=render.screen_size();local scale=render.scale()
    local tint=render.theme().accent
    if prefs.rainbow then tint=colors.from_hsv((cs2.clock().realtime*35)%360,.65,1) end
    tint={tint[1],tint[2],tint[3],prefs.opacity/100}
    if prefs.crosshair then
        local x,y=w/2,h/2;local a,b,t=prefs.gap*scale,(prefs.gap+prefs.size)*scale,prefs.thickness*scale
        render.line(x-b,y,x-a,y,tint,t);render.line(x+a,y,x+b,y,tint,t)
        render.line(x,y-b,x,y-a,tint,t);render.line(x,y+a,x,y+b,tint,t)
    end
    if prefs.speed then
        local speed=math.sqrt(me.velocity.x^2+me.velocity.y^2)
        render.rect(22*scale,h-90*scale,200*scale,52*scale,{.04,.05,.06,.88},true,5*scale)
        render.text(34*scale,h-80*scale,string.format("SPEED   %.0f u/s",speed),tint,16*scale)
        render.rect(34*scale,h-53*scale,176*scale*math.min(speed/350,1),3*scale,tint,true)
    end
    if prefs.vitals then
        render.arc(w/2,h-70*scale,25*scale,-90,270,{.2,.23,.26,.8},4*scale)
        render.arc(w/2,h-70*scale,25*scale,-90,-90+360*math.max(0,math.min(me.health/100,1)),tint,4*scale)
        render.text(w/2-12*scale,h-77*scale,tostring(me.health),tint,14*scale)
    end
    if prefs.labels then
        for _,p in ipairs(entity.get_players(false,true)) do
            if not p.is_local and p.origin:distance(me.origin)<=prefs.range then
                local x,y=render.world_to_screen(p.eye_position.x,p.eye_position.y,p.eye_position.z+8)
                if x then render.text(x,y,p.name.."  "..p.health.." HP",tint,13*scale) end
            end
        end
    end
end)
ui.overlay("interface",function()
    if not features.active(visible) then return end
    local _,hostFont=imgui.text_size("M")
    font=math.min(80,math.max(14,hostFont));s=font/14;accent=render.theme().accent
    local vw,vh=engine.viewport()
    local colors={WindowBg=c.bg,ChildBg=c.clear,PopupBg=c.panel,Text=c.text,TextDisabled=c.muted,
        Border=c.border,FrameBg=c.field,FrameBgHovered=c.hover,FrameBgActive={0.16,0.20,0.27,1},
        CheckMark=accent,SliderGrab=accent,SliderGrabActive={0.70,0.79,0.94,1},
        Button=c.field,ButtonHovered=c.hover,ButtonActive={0.16,0.21,0.30,1},
        Header={0.14,0.19,0.28,1},HeaderHovered=c.hover,HeaderActive={0.18,0.24,0.34,1}}
    imgui.with_font_size(font,function()
        imgui.with_style(colors,function()
            imgui.with_style_vars({WindowPadding={0,0},WindowRounding=5*s,WindowBorderSize=1,
                ChildRounding=4*s,FramePadding={6*s,3*s},FrameRounding=3*s,FrameBorderSize=1,
                ItemSpacing={7*s,5*s},GrabMinSize=7*s,GrabRounding=2*s,PopupRounding=4*s},function()
                imgui.window("CS2 Visual Studio",{width=math.min(vw-48,650*s),height=math.min(vh-70,480*s),
                    x=24,y=32,no_title_bar=true},function()
                    local wx,wy=imgui.window_pos()
                    local width,height=imgui.window_size()
                    local tabWidth=0
                    for _,name in ipairs({"Main","Visuals","Settings"}) do tabWidth=tabWidth+imgui.text_size(name)+24*s end
                    local stacked=width<tabWidth+120*s
                    local header=(stacked and 84 or 48)*s
                    draw.rect(wx+1,wy+1,width-2,header-1,c.header,true,4*s)
                    draw.text(wx+18*s,wy+15*s,"CS2",c.text,18*s)
                    draw.line(wx+1,wy+header,wx+width-1,wy+header,{accent[1],accent[2],accent[3],0.55},1)
                    imgui.set_cursor(width-34*s,9*s)
                    imgui.with_style({Button=c.clear,Border=c.clear,Text=c.muted},function()
                        if imgui.button("x##close",24*s,27*s) then features.set(visible,false) end
                    end)
                    if imgui.is_item_hovered() then imgui.tooltip("Close window - "..keys[prefs.windowKey].." to reopen") end
                    imgui.set_cursor(stacked and 12*s or width-tabWidth-48*s,stacked and 45*s or 10*s)
                    for i,name in ipairs({"Main","Visuals","Settings"}) do
                        if i>1 then imgui.same_line(0) end
                        local selected=page==name
                        imgui.with_style({Text=selected and accent or c.muted,Border=c.clear,Button=c.clear},function()
                            local buttonWidth=stacked and (width-24*s)/3 or imgui.text_size(name)+24*s
                            if imgui.button(name,buttonWidth,28*s) then page=name end
                        end)
                        if stacked and imgui.is_item_hovered() then imgui.tooltip(name) end
                        if selected then
                            local a,b,d,e=imgui.item_rect()
                            draw.line(a+12*s,wy+header,d-12*s,wy+header,accent,2)
                        end
                    end
                    local footer=showFooter and 29*s or 0
                    imgui.set_cursor(14*s,header+14*s)
                    local contentHeight=math.max(40*s,height-header-footer-28*s)
                    imgui.child("body",width-28*s,contentHeight,function()
                        if page=="Main" then mainPage() elseif page=="Visuals" then visualsPage() else settingsPage() end
                    end)
                    if showFooter then
                        local y=wy+height-footer
                        draw.line(wx+14*s,y,wx+width-14*s,y,c.border,1)
                        draw.text(wx+17*s,y+8*s,"Standalone",c.muted,11*s)
                        local hint=keys[prefs.windowKey].."  Show / hide"
                        draw.text(wx+width-17*s-imgui.text_size(hint)*11/14,y+8*s,hint,c.muted,11*s)
                    end
                end)
            end)
        end)
    end)
end)
