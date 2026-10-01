-- Vesper presentation. Game actions remain queued in model/host.lua.
local ui=compat.yim.ImGui
local U={}
local C={bg={.055,.058,.070,1},sidebar={.067,.070,.084,1},card={.083,.087,.104,1},field={.112,.118,.141,1},
    border={.145,.151,.177,1},line={.117,.122,.146,1},text={.89,.90,.94,1},muted={.59,.62,.70,1},
    accent={.59,.52,1,1},selected={.15,.13,.24,1},hover={.12,.12,.17,1},good={.46,.78,.66,1},error={1,.52,.56,1}}
local function push_color(name,c) ui.PushStyleColor(ImGuiCol[name],unpack(c)) end
local function packed(c) return ui.ColorConvertFloat4ToU32(unpack(c)) end
local function font(size) ui.SetWindowFontScale(1);ui.SetWindowFontScale(size/ui.GetFontSize()) end
local function text(d,x,y,label,c,size)
    font(size or 15);d:AddText(x,y,packed(c or C.text),tostring(label));font(15)
end
local function line(d,x1,y1,x2,y2,c,width) d:AddLine(x1,y1,x2,y2,packed(c or C.line),width or 1) end
local function box(d,x,y,w,h,c,r) d:AddRectFilled(x,y,x+w,y+h,packed(c),r or 5) end
local function outline(d,x,y,w,h,c,r) d:AddRect(x,y,x+w,y+h,packed(c or C.border),r or 5,0,1) end
local assets=require('Vesper.assets')
local function icon(d,name,x,y,c) assets.icon(d,name,x,y,packed(c or C.muted)) end
local function logo(d,x,y) assets.logo(d,x,y,packed(C.accent)) end
local function theme()
    local colors={WindowBg=C.bg,ChildBg={0,0,0,0},PopupBg=C.card,Text=C.text,TextDisabled=C.muted,Border=C.border,
        FrameBg=C.field,FrameBgHovered={.16,.16,.22,1},FrameBgActive={.20,.18,.29,1},Button=C.field,
        ButtonHovered={.19,.17,.28,1},ButtonActive={.27,.23,.40,1},Header=C.selected,HeaderHovered=C.hover,HeaderActive=C.selected,
        CheckMark=C.accent,SliderGrab=C.accent,SliderGrabActive=C.accent,Separator=C.line,ScrollbarBg={0,0,0,0},
        ScrollbarGrab={.27,.25,.36,1},ScrollbarGrabHovered=C.accent,ScrollbarGrabActive=C.accent,PlotHistogram=C.accent}
    local count=0;for k,v in pairs(colors) do push_color(k,v);count=count+1 end
    ui.PushStyleVar(ImGuiStyleVar.WindowRounding,12);ui.PushStyleVar(ImGuiStyleVar.ChildRounding,7)
    ui.PushStyleVar(ImGuiStyleVar.FrameRounding,9);ui.PushStyleVar(ImGuiStyleVar.WindowPadding,12,12)
    ui.PushStyleVar(ImGuiStyleVar.FramePadding,9,6);ui.PushStyleVar(ImGuiStyleVar.ItemSpacing,8,6)
    ui.PushStyleVar(ImGuiStyleVar.ScrollbarSize,4);ui.PushStyleVar(ImGuiStyleVar.PopupRounding,10)
    return count
end
local function hit(id,w,h)
    -- A real ImGui button retains keyboard focus and activation behavior.
    push_color('Button',{0,0,0,0});push_color('ButtonHovered',{0,0,0,0});push_color('ButtonActive',{0,0,0,0})
    local click=ui.Button('##'..id,w,h);ui.PopStyleColor(3)
    return click,ui.IsItemHovered() or ui.IsItemFocused()
end
local function match(s,label)
    local found=s.search=='' or label:lower():find(s.search:lower(),1,true)~=nil
    if found then s.visible_controls=s.visible_controls+1 end
    return found
end
local function pill(id,label,w,h,glyph,primary)
    local x,y=ui.GetCursorScreenPos();local click,hover=hit(id,w,h)
    local d=ui.GetWindowDrawList();local active=ui.IsItemActive()
    local edge=hover and C.good or (primary and {.27,.45,.39,1} or {.25,.29,.29,1})
    if hover then
        outline(d,x-1,y-1,w+2,h+2,{.22,.43,.35,.25},12)
        outline(d,x-2,y-2,w+4,h+4,{.22,.43,.35,.10},13)
    end
    box(d,x,y,w,h,active and {.10,.16,.15,1} or (hover and {.10,.13,.13,1} or {.084,.092,.099,1}),11)
    outline(d,x,y,w,h,edge,11)
    font(15);local tw=ui.CalcTextSize(label);local tx=x+(w-tw-(glyph and 23 or 0))/2
    if glyph then icon(d,glyph,tx,y+(h-16)/2,C.text);tx=tx+23 end
    text(d,tx,y+(h-15)/2,label,C.text,15)
    return click
end
local function toggle(s,label,key)
    if not match(s,label) then return end
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvail();local click,hover=hit('toggle_'..key,w,34)
    local d=ui.GetWindowDrawList();local on=s.options[key]
    if hover then box(d,x-3,y,w+6,34,C.hover,5) end
    text(d,x+1,y+8,label,hover and C.text or {.78,.80,.86,1})
    local cx,cy=x+w-31,y+9
    box(d,cx,cy,30,17,on and C.accent or {.16,.17,.20,1},9)
    d:AddCircleFilled(cx+(on and 22 or 8),cy+8.5,5.5,packed(on and C.text or C.muted),20)
    if click then s.options[key]=not on end
end
local glyphs={car_repair='repair',car_wash='clean',car_flip='Vehicle',car_paint='paint',car_plate='Vehicle',
    heal='Self',armour='Self',clean='clean',wanted='Self',bookmark_save='save',bookmark_return='Teleport',waypoint='Teleport',
    save_preferences='save',reset_layout='Settings',weather='World',weather_reset='World',clock='World'}
local function action(s,label,id)
    if not match(s,label) then return end
    local w=ui.GetContentRegionAvail()
    if pill(id,label,w,34,glyphs[id],id=='car_repair' or id=='car_paint') then s:enqueue(id) end
    ui.Dummy(0,7)
end
local function slider(id,label,value,minv,maxv,tint)
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvail();hit(id,w,45)
    if ui.IsItemActive() and ui.IsMouseDown(0) then
        local mx=ui.GetMousePos();value=math.floor(minv+math.max(0,math.min(1,(mx-x-6)/(w-12)))*(maxv-minv)+.5)
    end
    if ui.IsItemFocused() then
        if input.is_key_pressed(input.keys.LEFT or 37) then value=math.max(minv,value-1) end
        if input.is_key_pressed(input.keys.RIGHT or 39) then value=math.min(maxv,value+1) end
    end
    local d=ui.GetWindowDrawList();local frac=(value-minv)/(maxv-minv);local accent=tint or C.accent
    text(d,x,y,label,C.muted,13);font(13);local tw=ui.CalcTextSize(tostring(value));text(d,x+w-tw,y,tostring(value),C.text,13)
    box(d,x+6,y+29,w-12,4,C.field,2);box(d,x+6,y+29,(w-12)*frac,4,accent,2)
    d:AddCircleFilled(x+6+(w-12)*frac,y+31,6,packed(C.bg),24)
    d:AddCircleFilled(x+6+(w-12)*frac,y+31,4,packed(accent),24)
    if ui.IsItemFocused() then outline(d,x,y,w,43,C.accent,6) end
    return value
end
local function choice(id,value,items)
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvail();local clicked,hover=hit(id,w,33)
    local d=ui.GetWindowDrawList();box(d,x,y,w,33,C.field,8);outline(d,x,y,w,33,hover and C.accent or C.border,8)
    text(d,x+11,y+8,items[value+1] or 'Select',C.text)
    line(d,x+w-22,y+14,x+w-18,y+18,C.muted,1.5);line(d,x+w-18,y+18,x+w-14,y+14,C.muted,1.5)
    if clicked then ui.OpenPopup(id..'_list') end
    ui.SetNextWindowSize(w,0,ImGuiCond.Always)
    if ui.BeginPopup(id..'_list') then
        font(15)
        for i,label in ipairs(items) do
            local px,py=ui.GetCursorScreenPos();local chosen,over=hit(id..i,w-24,30);local draw=ui.GetWindowDrawList()
            if over or value==i-1 then box(draw,px,py,w-24,30,C.selected,5) end
            text(draw,px+8,py+7,label,value==i-1 and C.accent or C.text)
            if chosen then value=i-1;ui.CloseCurrentPopup() end
        end
        ui.EndPopup()
    end
    return value
end
local function input_text(id,value,capacity,hint,width)
    local x,y=ui.GetCursorScreenPos();local w=width or ui.GetContentRegionAvail()
    local d=ui.GetWindowDrawList();box(d,x,y,w,29,C.field,8)
    push_color('FrameBg',{0,0,0,0});ui.SetNextItemWidth(w)
    if hint then value=ui.InputTextWithHint(id,hint,value,capacity) else value=ui.InputText(id,value,capacity) end
    ui.PopStyleColor();outline(d,x,y,w,29,ui.IsItemActive() and C.accent or C.border,8)
    return value
end
local function card(title,w,h,fn)
    push_color('ChildBg',C.card)
    ui.BeginChild('card_'..title,w,h,true,ImGuiWindowFlags.NoScrollbar+ImGuiWindowFlags.NoScrollWithMouse)
    font(15);local x,y=ui.GetWindowPos();local d=ui.GetWindowDrawList()
    text(d,x+13,y+12,title,C.text,14)
    line(d,x+12,y+37,x+w-12,y+37)
    ui.SetCursorPos(12,44);ui.PushStyleVar(ImGuiStyleVar.ItemSpacing,0,0)
    fn();ui.PopStyleVar();ui.EndChild();ui.PopStyleColor()
end
local function pair(s,label,a,b,first,second)
    if not match(s,label..' '..a..' '..b) then return end
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvail();local lx,ly=ui.GetCursorPos()
    local d=ui.GetWindowDrawList();text(d,x,y+8,label,{.76,.78,.84,1})
    ui.SetCursorPos(lx+w-108,ly+3)
    if pill(first,a,51,28) then s:enqueue(first) end
    ui.SameLine(0,6);if pill(second,b,51,28) then s:enqueue(second) end
    ui.SetCursorPos(lx,ly+38);ui.Dummy(w,1)
end
local function field_label(label)
    ui.TextDisabled(label);ui.Dummy(0,5);ui.SetNextItemWidth(-1)
end
local function gap(h) ui.Dummy(0,h or 8) end
local function paint(s)
    if match(s,'Paint color') then
        local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvail();local clicked,hover=hit('paint_picker',w,30)
        local d=ui.GetWindowDrawList();box(d,x,y,27,27,{s.paint[1],s.paint[2],s.paint[3],1},7)
        text(d,x+39,y+6,'Paint color',C.text);icon(d,'Settings',x+w-18,y+6,hover and C.accent or C.muted)
        if clicked then ui.OpenPopup('custom_rgb') end
        ui.SetNextWindowSize(256,215,ImGuiCond.Always)
        if ui.BeginPopup('custom_rgb') then
            font(15);ui.Text('Custom paint');ui.SameLine(192)
            if pill('rgb_done','OK',39,24) then ui.CloseCurrentPopup() end
            gap(9)
            for i,label in ipairs({'Red','Green','Blue'}) do
                local tint=({{.92,.42,.49,1},{.46,.78,.66,1},{.45,.64,.98,1}})[i]
                s.paint[i]=slider('rgb'..i,label,math.floor(s.paint[i]*255+.5),0,255,tint)/255
            end
            ui.EndPopup()
        end
        gap(6)
        for i,rgb in ipairs({{.58,.48,1},{.88,.89,.93},{.13,.15,.19},{.37,.64,.94},{.85,.39,.46}}) do
            local px,py=ui.GetCursorScreenPos();local chosen,over=hit('swatch'..i,24,18);local draw=ui.GetWindowDrawList()
            box(draw,px,py+2,24,14,{rgb[1],rgb[2],rgb[3],1},5)
            if over then outline(draw,px-2,py,28,18,C.text,6) end
            if chosen then s.paint={rgb[1],rgb[2],rgb[3]} end
            if i<5 then ui.SameLine(0,7) end
        end
        gap(8)
    end
    action(s,'Apply paint','car_paint');gap(4)
    if match(s,'Plate text') then
        field_label('Plate text');s.plate=input_text('##plate',s.plate,9);gap(8)
    end
    action(s,'Apply plate','car_plate')
end
local function controls(s,w)
    local single=w<475;local col=single and w or (w-12)/2
    local left,right
    if s.page=='Vehicle' then
        left=function()
            card('Vehicle care',col,210,function()
                action(s,'Repair vehicle','car_repair');action(s,'Wash vehicle','car_wash');action(s,'Upright vehicle','car_flip');toggle(s,'Automatic repair','auto_repair')
            end);gap(6)
            card('Quick controls',col,129,function()
                pair(s,'Engine','Start','Stop','car_engine_on','car_engine_off');pair(s,'Doors','Open','Shut','car_doors_open','car_doors_close')
            end)
        end
        right=function()
            card('Appearance',col,253,function() paint(s) end);gap(6)
            card('Telemetry',col,114,function() toggle(s,'Speedometer','speedometer');toggle(s,'Use miles per hour','mph') end)
        end
    elseif s.page=='Overlay' then
        left=function()
            card('On-screen panels',col,262,function()
                toggle(s,'Status badge','watermark');toggle(s,'Keybind list','keybinds');toggle(s,'Player status','status');toggle(s,'Speedometer','speedometer');toggle(s,'Coordinates','coordinates');toggle(s,'Center crosshair','crosshair')
            end)
        end
        right=function()
            card('Display',col,114,function() toggle(s,'Miles per hour','mph');toggle(s,'Hide game HUD','hide_hud') end);gap(6)
            card('Layout & preferences',col,134,function() action(s,'Reset panel positions','reset_layout');action(s,'Save preferences','save_preferences') end)
        end
    elseif s.page=='Self' then
        left=function() card('Player tools',col,220,function() action(s,'Restore health','heal');action(s,'Fill armour','armour');action(s,'Clear wanted level','wanted');action(s,'Clean player','clean') end) end
        right=function()
            card('Local player',col,143,function()
                local p=s.snapshot;ui.Text(p.name or 'Local player');gap(10)
                local bx,by=ui.GetCursorScreenPos();local bw=ui.GetContentRegionAvail();local d=ui.GetWindowDrawList()
                box(d,bx,by,bw,5,C.field,2);box(d,bx,by,bw*math.min(1,math.max(0,p.health)/math.max(1,p.max_health)),5,C.accent,2);ui.Dummy(bw,5);gap(9)
                ui.TextDisabled(string.format('%d / %d HP   |   %d armour',p.health,p.max_health,p.armour))
            end);gap(6)
            card('Player panels',col,114,function() toggle(s,'Player status','status');toggle(s,'Coordinates','coordinates') end)
        end
    elseif s.page=='World' then
        left=function()
            card('Weather',col,219,function()
                if match(s,'Weather preset') then field_label('Weather preset');s.weather=choice('weather_select',s.weather,{'Extra sunny','Clear','Clouds','Overcast','Rain','Thunder','Fog','Light snow'});gap(8) end
                action(s,'Apply weather','weather');action(s,'Release override','weather_reset')
            end)
        end
        right=function()
            card('Time of day',col,215,function()
                if match(s,'Hour') then s.hour=slider('hour','Hour',s.hour,0,23);gap(8) end
                action(s,'Set time','clock')
                if match(s,'Noon Midnight') then
                    local cw=ui.GetContentRegionAvail();if pill('noon','Noon',(cw-8)/2,29) then s.hour=12;s:enqueue('clock') end
                    ui.SameLine(0,8);if pill('midnight','Midnight',(cw-8)/2,29) then s.hour=0;s:enqueue('clock') end
                end
            end)
        end
    elseif s.page=='Teleport' then
        left=function()
            card('Saved locations',col,238,function()
                if match(s,'Location slot') then field_label('Location slot');s.slot=choice('slot',s.slot,{'Location 1','Location 2','Location 3'});gap(8) end
                action(s,'Save current location','bookmark_save');action(s,'Return to location','bookmark_return');gap(10)
                local p=s.bookmarks[tostring(s.slot)]
                ui.TextDisabled(p and string.format('%.0f, %.0f, %.0f',p.x,p.y,p.z) or 'This slot is empty')
            end)
        end
        right=function() card('Travel',col,134,function() action(s,'Go to map waypoint','waypoint');action(s,'Save locations to config','save_preferences') end) end
    else
        left=function()
            card('Input & shortcuts',col,132,function() toggle(s,'Controller shortcut','controller');action(s,'Save preferences','save_preferences') end);gap(6)
            card('Window layout',col,95,function() action(s,'Reset layout','reset_layout') end)
        end
        right=function()
            card('Keyboard',col,172,function()
                ui.Text('F6   Open / close menu');gap(10);ui.Text('F7   Speedometer');gap(10);ui.Text('F8   Keybind list')
            end);gap(6)
            card('Controller',col,85,function() ui.Text('LB + RB + X');gap(5);ui.TextDisabled('Open / close menu') end)
        end
    end
    ui.BeginGroup();left();ui.EndGroup()
    if single then gap(6) else ui.SameLine(0,12) end
    ui.BeginGroup();right();ui.EndGroup()
end
local function window(name,x,y,w,h,reset,interactive,fn,transparent)
    ui.SetNextWindowPos(x,y,reset and ImGuiCond.Always or ImGuiCond.FirstUseEver);ui.SetNextWindowSize(w,h,ImGuiCond.Always)
    local flags=ImGuiWindowFlags.NoTitleBar+ImGuiWindowFlags.NoResize+ImGuiWindowFlags.NoCollapse+ImGuiWindowFlags.NoSavedSettings+ImGuiWindowFlags.NoScrollbar
    if not interactive then flags=flags+ImGuiWindowFlags.NoInputs end
    if transparent then flags=flags+ImGuiWindowFlags.NoBackground end
    if ui.Begin(name,flags) then font(15);fn() end
    font(15);ui.End()
end
local function navigation(s,sw,h)
    local x,y=ui.GetWindowPos();local d=ui.GetWindowDrawList()
    box(d,x+1,y+1,sw-1,h-2,C.sidebar,9);line(d,x+sw,y+1,x+sw,y+h-1,C.border)
    logo(d,x+20,y+25);text(d,x+50,y+20,'Vesper',C.text,22);text(d,x+51,y+43,'GTA V',C.muted,11)
    ui.SetCursorPos(16,78);ui.SetNextItemWidth(sw-32);s.search=input_text('##search',s.search,128,'Search controls',sw-32)
    local cy=126
    for _,group in ipairs({{'VISUALS','Overlay','World'},{'MISC','Self','Vehicle','Teleport'},{'OTHER','Settings'}}) do
        text(d,x+21,y+cy,group[1],C.muted,10);cy=cy+22
        for i=2,#group do
            local name=group[i];ui.SetCursorPos(10,cy);local clicked,hover=hit('nav_'..name,sw-20,33)
            if s.page==name then box(d,x+10,y+cy,sw-20,33,C.selected,5);box(d,x+10,y+cy+9,2,15,C.accent,1)
            elseif hover then box(d,x+10,y+cy,sw-20,33,C.hover,5) end
            icon(d,name,x+23,y+cy+8,s.page==name and C.accent or C.muted)
            text(d,x+49,y+cy+8,name,s.page==name and C.text or C.muted)
            if clicked then s.page=name;s.search='' end
            cy=cy+36
        end
        cy=cy+15
    end
    line(d,x+18,y+h-42,x+sw-18,y+h-42)
    text(d,x+21,y+h-28,'GTA V',C.muted,11);text(d,x+sw-59,y+h-28,'LUA',C.accent,11)
end
local function workspace(s,x,y,w,h,reset)
    window('Vesper##main',x,y,w,h,reset,true,function()
        local sw=w<680 and 148 or 170;navigation(s,sw,h)
        local wx,wy=ui.GetWindowPos();local d=ui.GetWindowDrawList()
        local section=(s.page=='Overlay' or s.page=='World') and 'Visuals' or (s.page=='Settings' and 'Other' or 'Misc')
        text(d,wx+sw+22,wy+19,section..'  /  '..s.page,C.muted,11)
        text(d,wx+sw+22,wy+37,s.page,C.text,23)
        box(d,wx+w-80,wy+24,28,23,C.field,4);text(d,wx+w-74,wy+28,'F6',C.muted,11)
        ui.SetCursorPos(w-44,22);local close,hover=hit('close',27,27)
        if hover then box(d,wx+w-44,wy+22,27,27,C.hover,4) end
        icon(d,'close',wx+w-39,wy+27,hover and C.text or C.muted)
        if close then s.open=false end
        line(d,wx+sw+1,wy+76,wx+w-1,wy+76)
        ui.SetCursorPos(sw+18,91)
        ui.BeginChild('page_body',w-sw-34,h-134,false,ImGuiWindowFlags.AlwaysVerticalScrollbar)
        s.visible_controls=0;controls(s,ui.GetContentRegionAvail());ui.EndChild()
        local footer=s.search~='' and (s.visible_controls==0 and 'No matching controls' or tostring(s.visible_controls)..' matching controls') or s.message
        line(d,wx+sw+1,wy+h-36,wx+w-1,wy+h-36)
        d:AddCircleFilled(wx+sw+23,wy+h-18,3,packed(s.error and C.error or C.good),12)
        ui.PushClipRect(wx+sw+33,wy+h-34,wx+w-94,wy+h-2,true)
        text(d,wx+sw+33,wy+h-25,footer,s.error and C.error or C.muted,12);ui.PopClipRect()
        if s.error and ui.IsMouseHoveringRect(wx+sw,wy+h-36,wx+w,wy+h) then ui.SetTooltip(s.message) end
        text(d,wx+w-76,wy+h-25,'F6  Hide',C.muted,11)
    end)
end
local function keycap(d,x,y,label,w)
    box(d,x,y,w or 29,21,C.field,4);outline(d,x,y,w or 29,21,C.border,4)
    font(11);local tw=ui.CalcTextSize(label);text(d,x+((w or 29)-tw)/2,y+4,label,C.text,11)
end
function U.draw(s)
    local nc=theme();local dw,dh=ui.GetDisplaySize()
    local w=math.min(808,dw-32);local h=math.min(526,dh-44)
    local satellites=dw>=w+290;local total=w+(satellites and 256 or 0)
    local x=math.max(16,(dw-total)/2);local y=math.max(22,(dh-h)/2)
    local reset=s.reset_layout or s.last_view_w~=dw or s.last_view_h~=dh
    s.last_view_w=dw;s.last_view_h=dh
    if input.is_key_pressed(input.keys.F6) then s.open=not s.open end
    if not ui.IsAnyItemActive() then
        if input.is_key_pressed(input.keys.F7) then s.options.speedometer=not s.options.speedometer end
        if input.is_key_pressed(input.keys.F8) then s.options.keybinds=not s.options.keybinds end
    end
    if s.options.controller and input.is_gamepad_connected and input.is_gamepad_connected() then
        if input.is_gamepad_button_down(0x100) and input.is_gamepad_button_down(0x200) and input.is_gamepad_button_pressed(0x4000) then s.open=not s.open end
    end
    if s.open then workspace(s,x,y,w,h,reset) end
    local p=s.snapshot;local sx=satellites and x+w+16 or dw-256;local sy=y+18
    if s.options.watermark and (satellites or not s.open) then
        window('Vesper badge',math.max(8,dw-348),18,330,36,reset,false,function()
            local bx,by=ui.GetWindowPos();local d=ui.GetWindowDrawList();logo(d,bx+12,by+10)
            text(d,bx+43,by+11,'Vesper',C.text,12);line(d,bx+94,by+10,bx+94,by+26,C.border)
            text(d,bx+106,by+11,p.online and 'Online' or 'Story',C.muted,12)
            text(d,bx+163,by+11,string.format('%d players',p.players),C.muted,12)
            text(d,bx+248,by+11,string.format('%.0f FPS',ui.GetFrameRate()),C.text,12)
        end)
    end
    if s.options.keybinds and (satellites or not s.open) then
        window('Vesper keybinds',sx,sy,240,183,reset,false,function()
            local bx,by=ui.GetWindowPos();local d=ui.GetWindowDrawList()
            icon(d,'keys',bx+14,by+13,C.accent);text(d,bx+39,by+14,'Keybinds',C.text,13);line(d,bx+13,by+40,bx+227,by+40)
            for i,entry in ipairs({{'Menu','F6'},{'Speedometer','F7'},{'Keybind list','F8'}}) do
                text(d,bx+15,by+48+(i-1)*29,entry[1],C.muted,12);keycap(d,bx+195,by+44+(i-1)*29,entry[2])
            end
            if s.options.controller then line(d,bx+14,by+136,bx+226,by+136);text(d,bx+15,by+153,'Controller',C.muted,11);keycap(d,bx+117,by+148,'LB + RB + X',107) end
        end);sy=sy+195
    end
    if s.options.status and (satellites or not s.open) then
        window('Vesper player status',sx,sy,240,134,reset,false,function()
            local bx,by=ui.GetWindowPos();local d=ui.GetWindowDrawList()
            icon(d,'Self',bx+14,by+13,C.accent);text(d,bx+39,by+14,'Player status',C.text,13);line(d,bx+13,by+40,bx+227,by+40)
            ui.PushClipRect(bx+14,by+48,bx+226,by+69,true);text(d,bx+15,by+50,p.available and (p.name or 'Local player') or 'Waiting for player',C.text,13);ui.PopClipRect()
            box(d,bx+15,by+79,210,5,C.field,2);box(d,bx+15,by+79,210*math.min(1,math.max(0,p.health)/math.max(1,p.max_health)),5,C.accent,2)
            text(d,bx+15,by+100,string.format('%d / %d HP',p.health,p.max_health),C.muted,11);text(d,bx+148,by+100,'Armour '..p.armour,C.muted,11)
        end)
    end
    if s.options.speedometer and (satellites or not s.open) then
        window('Vesper speedometer',dw-256,dh-124,240,101,reset,false,function()
            local bx,by=ui.GetWindowPos();local d=ui.GetWindowDrawList();local speed=math.max(0,p.speed)*(s.options.mph and 2.236936 or 3.6)
            icon(d,'Vehicle',bx+15,by+14,C.accent);text(d,bx+41,by+15,p.vehicle~=0 and 'Vehicle' or 'On foot',C.muted,11)
            text(d,bx+16,by+37,string.format('%03.0f',speed),C.text,32);text(d,bx+88,by+58,s.options.mph and 'MPH' or 'KM/H',C.muted,10)
            box(d,bx+154,by+62,4,12,C.accent,1);box(d,bx+164,by+54,4,20,C.accent,1);box(d,bx+174,by+45,4,29,C.accent,1)
        end)
    end
    if s.options.coordinates and (satellites or not s.open) then
        window('Vesper coordinates',18,dh-57,340,37,reset,false,function() ui.Text(string.format('X %.1f    Y %.1f    Z %.1f',p.x,p.y,p.z)) end)
    end
    if s.options.crosshair then
        window('Vesper crosshair',dw/2-16,dh/2-16,32,32,true,false,function()
            local bx,by=ui.GetWindowPos();local d=ui.GetWindowDrawList();line(d,bx+8,by+16,bx+24,by+16,C.accent,2);line(d,bx+16,by+8,bx+16,by+24,C.accent,2)
        end,true)
    end
    s.reset_layout=false;ui.PopStyleVar(8);ui.PopStyleColor(nc)
end
return U
