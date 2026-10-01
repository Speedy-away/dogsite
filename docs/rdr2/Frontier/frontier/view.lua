-- Vesper's presentation. Keep the Frontier package identity for existing saved settings.
local M={}
local ui=ImGui
local C={bg={.052,.060,.068,1},panel={.066,.075,.083,1},card={.086,.098,.107,1},field={.112,.127,.137,1},
    hover={.13,.17,.175,1},text={.93,.95,.96,1},muted={.62,.68,.71,1},purple={.66,.59,1,1},
    mint={.42,.82,.70,1},edge={.25,.43,.38,1},line={.16,.20,.21,1},selected={.16,.14,.24,1},clear={0,0,0,0}}
local function rgba(c) return ui.GetColorU32(c[1],c[2],c[3],c[4]) end
local function color(name,c) ui.PushStyleColor(ImGuiCol[name],c[1],c[2],c[3],c[4]) end
local function font(size) ui.SetWindowFontScale(1);ui.SetWindowFontScale(size/ui.GetFontSize()) end
local function text(c,s,size)
    if size then font(size) end
    ui.TextColored(c[1],c[2],c[3],c[4],s)
    if size then font(17) end
end
local function theme()
    local colors={WindowBg=C.bg,ChildBg=C.clear,PopupBg=C.card,Text=C.text,TextDisabled=C.muted,Border=C.line,
        Separator=C.line,FrameBg=C.field,FrameBgHovered=C.hover,FrameBgActive=C.hover,Button=C.field,ButtonHovered=C.hover,
        ButtonActive=C.selected,Header=C.selected,HeaderHovered=C.hover,HeaderActive=C.selected,CheckMark=C.mint,
        PlotHistogram=C.mint,ScrollbarBg=C.clear,ScrollbarGrab=C.line,ScrollbarGrabHovered=C.edge,ScrollbarGrabActive=C.mint,
        SliderGrab=C.mint,SliderGrabActive=C.mint,ResizeGrip=C.clear,ResizeGripHovered=C.purple,ResizeGripActive=C.purple}
    local n=0;for name,c in pairs(colors) do color(name,c);n=n+1 end
    local vars={{'WindowRounding',16},{'ChildRounding',12},{'FrameRounding',9},{'WindowBorderSize',1},
        {'WindowPadding',18,18},{'FramePadding',12,9},{'ItemSpacing',10,10},{'ScrollbarSize',5}}
    for _,v in ipairs(vars) do if v[3] then ui.PushStyleVar(ImGuiStyleVar[v[1]],v[2],v[3]) else ui.PushStyleVar(ImGuiStyleVar[v[1]],v[2]) end end
    return n,#vars
end
-- Original vector assets, drawn at the current display scale; no external textures/fonts.
local function icon(d,name,x,y,c)
    local col=rgba(c or C.muted)
    local function l(a,b,e,f) d:AddLine(x+a,y+b,x+e,y+f,col,1.5) end
    local function r(a,b,e,f) d:AddRect(x+a,y+b,x+e,y+f,col,2,0,1.5) end
    if name=='overview' then r(1,1,17,17);l(1,7,17,7);l(7,7,7,17)
    elseif name=='player' then d:AddCircle(x+9,y+5,3,col,20,1.5);l(3,17,3,14);l(3,14,6,11);l(6,11,12,11);l(12,11,15,14);l(15,14,15,17)
    elseif name=='travel' then d:AddCircle(x+9,y+9,8,col,24,1.5);l(6,12,8,6);l(8,6,12,8);l(12,8,6,12)
    elseif name=='world' then d:AddCircle(x+9,y+9,4,col,24,1.5);for i=0,7 do local a=i*math.pi/4;l(9+7*math.cos(a),9+7*math.sin(a),9+9*math.cos(a),9+9*math.sin(a)) end
    elseif name=='settings' then for i=0,2 do local yy=3+i*6;l(1,yy,17,yy);d:AddCircleFilled(x+5+i*4,y+yy,2.5,col,16) end
    elseif name=='plus' then l(9,3,9,15);l(3,9,15,9)
    elseif name=='check' then l(3,9,7,13);l(7,13,15,5)
    elseif name=='close' then l(4,4,14,14);l(14,4,4,14)
    elseif name=='save' then r(2,1,16,17);r(6,1,12,6);r(5,11,13,17)
    else l(3,9,15,9);l(11,5,15,9);l(15,9,11,13) end
end
local function hit(id,w,h)
    color('Button',C.clear);color('ButtonHovered',C.clear);color('ButtonActive',C.clear)
    local click=ui.Button('##'..id,w,h);ui.PopStyleColor(3)
    return click,ui.IsItemHovered(),ui.IsItemActive(),ui.IsItemFocused()
end
local function available() return M.cardWidth or ui.GetContentRegionAvailX() end
local function button(id,label,selected,enabled,glyph)
    local x,y=ui.GetCursorScreenPos();local w=available();local h=42
    ui.BeginDisabled(not enabled)
    local click,hover,active,focus=hit(id,w,h);local d=ui.GetWindowDrawList()
    if hover or focus then d:AddRect(x-1,y-1,x+w+1,y+h+1,rgba({.42,.82,.70,.17}),15,0,1) end
    d:AddRectFilled(x,y,x+w,y+h,rgba(active and C.selected or hover and C.hover or C.field),14)
    d:AddRect(x+.5,y+.5,x+w-.5,y+h-.5,rgba((hover or focus) and C.mint or selected and C.purple or C.edge),14,0,1)
    font(17);local tw=ui.CalcTextSize(label);local tx=x+math.max(10,(w-tw-27)/2)
    icon(d,glyph or 'arrow',tx,y+12,enabled and C.text or C.muted)
    d:AddText(tx+27,y+13,rgba(enabled and C.text or C.muted),label);font(17)
    ui.EndDisabled();return click
end
local function toggle(id,label,on,selected,enabled)
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvailX()
    ui.BeginDisabled(not enabled);local click,hover,_,focus=hit(id,w,42);local d=ui.GetWindowDrawList()
    if hover or focus or selected then d:AddRectFilled(x,y,x+w,y+42,rgba(C.hover),8) end
    if selected then d:AddRect(x,y,x+w,y+42,rgba(C.purple),8,0,1) end
    d:AddText(x+8,y+13,rgba(C.text),label)
    d:AddRectFilled(x+w-48,y+11,x+w-8,y+31,rgba(on and C.mint or C.line),10)
    d:AddCircleFilled(x+w-(on and 18 or 38),y+21,7,rgba(on and C.bg or C.muted),20)
    ui.EndDisabled();return click
end
local function slider(label,value,lo,hi)
    local x,y=ui.GetCursorScreenPos();local w=available();local d=ui.GetWindowDrawList()
    font(16);d:AddText(x,y,rgba(C.muted),label);local number=tostring(value);local tw=ui.CalcTextSize(number);d:AddText(x+w-tw,y,rgba(C.text),number);font(17)
    ui.Dummy(w,14);ui.SetNextItemWidth(w)
    local _,sy=ui.GetCursorScreenPos()
    for _,name in ipairs({'FrameBg','FrameBgHovered','FrameBgActive','SliderGrab','SliderGrabActive','Text'}) do color(name,C.clear) end
    ui.PushStyleVar(ImGuiStyleVar.FramePadding,0,4)
    local changed,result=ui.SliderInt('##'..label,value,lo,hi,'%d',ImGuiSliderFlags.NoInput)
    local active=ui.IsItemActive() or ui.IsItemHovered() or ui.IsItemFocused()
    ui.PopStyleVar();ui.PopStyleColor(6)
    local yy=sy+12;local xx=x+8+(w-16)*(result-lo)/(hi-lo)
    d:AddRectFilled(x+8,yy-2,x+w-8,yy+2,rgba(C.line),2)
    d:AddRectFilled(x+8,yy-2,xx,yy+2,rgba(C.mint),2)
    if active then d:AddCircle(xx,yy,9,rgba(C.mint),24,1) end
    d:AddCircleFilled(xx,yy,6,rgba(C.text),24)
    return changed,result
end
local function card(id,title,subtitle,height,body)
    -- Draw on the scrolling parent so clipped cards still lay out their controls.
    -- Nested child windows skip layout offscreen, which hides controller targets.
    local x,y=ui.GetCursorScreenPos();local w=ui.GetContentRegionAvailX()
    ui.GetWindowDrawList():AddRectFilled(x,y,x+w,y+height,rgba(C.card),12)
    ui.PushID(id);ui.BeginGroup();ui.Indent(16)
    ui.SetCursorScreenPos(x+16,y+15);M.cardWidth=w-32
    ui.PushItemWidth(M.cardWidth)
    font(20);text(C.text,title);text(C.muted,subtitle,14);font(17);ui.Dummy(1,2)
    body();ui.PopItemWidth();M.cardWidth=nil;ui.Unindent(16)
    ui.SetCursorScreenPos(x,y+height);ui.Dummy(w,0);ui.EndGroup();ui.PopID()
end
local function actionRows(m,first,last)
    local entries=m:actions();m.selected=math.min(m.selected,#entries)
    for i=first,math.min(last,#entries) do
        local a=entries[i];local selected=m.selected==i
        local reveal=selected and m.scrollSelection
        local click
        if (m.tab==1 and i==2) or (m.tab==5 and i==1) then click=toggle('action'..i,'Compact HUD',m.showHud,selected,not m.pending)
        elseif m.tab==5 and i==2 then click=toggle('action'..i,'Use km/h',m.metric,selected,not m.pending)
        else
            local glyph=m.tab==2 and (i==3 and 'check' or 'plus') or m.tab==3 and 'travel' or m.tab==4 and 'world' or 'save'
            click=button('action'..i,a.label,selected,a.enabled and not m.pending,glyph)
        end
        if reveal then
            local _,top=ui.GetItemRectMin();local _,bottom=ui.GetItemRectMax()
            M.revealTarget=(top+bottom)/2;m.scrollSelection=false
        end
        if click then m.selected=i;m:activate(i) end
    end
end
local function status(m,compact)
    text(C.muted,m.ready and m.carrier or 'Waiting for player',13)
    if not m.ready then return end
    text(C.text,string.format('%d / %d HP',m.health,m.maxHealth),compact and 22 or 26)
    ui.ProgressBar(math.max(0,math.min(1,m.maxHealth>0 and m.health/m.maxHealth or 0)),available(),5,'')
    text(C.muted,string.format('%.1f %s',m.speed*(m.metric and 3.6 or 2.236936),m.metric and 'km/h' or 'mph'),14)
end
local function content(m,left)
    if m.tab==1 then
        if left then
            card('Player overview','Your character','Status at a glance',232,function()
                status(m);if m.ready then text(C.muted,string.format('X %.1f   Y %.1f   Z %.1f',m.position.x,m.position.y,m.position.z),12) end
            end)
            card('Overview actions','Quick actions','Keep useful tools close.',186,function() actionRows(m,1,2) end)
        else
            card('Input overview','Controller',m.pad.connected and 'Connected and ready' or 'Connect an XInput controller',206,function()
                text(C.text,m.pad.connected and m.pad.backend or 'Keyboard & mouse')
                text(C.muted,'F7  /  LB + D-pad Down',13)
                if m.pad.connected then
                    ui.ProgressBar(m.pad.leftTrigger,available(),8,'');text(C.muted,'Left trigger',12)
                    ui.ProgressBar(m.pad.rightTrigger,available(),8,'')
                end
            end)
            card('Travel overview','Your locations','Every good trail starts somewhere.',212,function()
                text(C.purple,string.format('%02d saved places',#m.bookmarks),25)
                text(C.muted,'Travel with your horse\nor driven vehicle.',14)
                if button('travel shortcut','Open travel',false,true,'travel') then m.tab=3;m.selected=1;m.scrollSelection=true end
            end)
        end
    elseif m.tab==2 then
        if left then card('Player actions','Player recovery','Ready for the next ride.',258,function() actionRows(m,1,3) end)
        else
            card('Horse actions','Horse recovery','Available while mounted.',206,function() actionRows(m,4,5) end)
            card('Carrier status','Current ride','Player and mount status',196,function()
                text(C.text,m.carrier,23);text(C.muted,'Saved-location travel includes\nyour horse or driven vehicle.',14)
            end)
        end
    elseif m.tab==3 then
        if left then
            card('Location editor','Save a place','Name your current location.',190,function()
                ui.SetNextItemWidth(available());local changed,value=ui.InputText('##location',m.name,128);if changed then m.name=value end
                actionRows(m,1,1)
            end)
            card('Travel actions','Travel','Go there, then find your way back.',202,function() actionRows(m,2,3) end)
        else
            card('Locations','Saved locations','Up to 30 places along the trail.',264,function()
                ui.SetNextItemWidth(available())
                if ui.BeginCombo('##destination',m.bookmarks[m.bookmark] and m.bookmarks[m.bookmark].name or 'No saved locations') then
                    for i,p in ipairs(m.bookmarks) do ui.PushID(i);if ui.Selectable(p.name,m.bookmark==i) then m.bookmark=i end;ui.PopID() end
                    ui.EndCombo()
                end
                actionRows(m,4,5)
            end)
            text(C.muted,'Uses the exact saved position.\nVehicle travel requires the driver seat.',13)
        end
    elseif m.tab==4 then
        if left then
            card('Weather','Weather','Set the atmosphere.',302,function()
                ui.SetNextItemWidth(available())
                if ui.BeginCombo('##weather',m.weather[m.weatherIndex]) then
                    for i,name in ipairs(m.weather) do if ui.Selectable(name,i==m.weatherIndex) then m.weatherIndex=i end end
                    ui.EndCombo()
                end
                actionRows(m,1,3)
            end)
        else
            card('Clock','Time of day','Choose the light for your next ride.',402,function()
                local changed,value=slider('Hour',m.hour,0,23);if changed then m.hour=value end
                changed,value=slider('Minute',m.minute,0,59);if changed then m.minute=value end
                actionRows(m,4,6)
            end)
        end
    else
        if left then card('Settings','Preferences','Make Vesper feel like yours.',310,function() actionRows(m,1,4) end)
        else
            card('Preferences status','Your workspace','Your settings travel with you.',194,function()
                text(C.text,'Vesper',25);text(C.muted,'RDR2  /  Custom Lua interface',13)
                text(C.muted,'Bookmarks and display preferences\nsave with this script.',13)
            end)
            card('Runtime','Runtime','Host compatibility',154,function()
                text(C.text,compat.runtime.version,16);text(C.muted,'Scooby API '..compat.api_version,13)
            end)
        end
    end
end
local navIcons={'overview','player','travel','world','settings'}
local function nav(id,label,selected,index)
    local x,y=ui.GetCursorScreenPos();local w=available();local click,hover,_,focus=hit(id,w,44);local d=ui.GetWindowDrawList()
    if selected or hover or focus then d:AddRectFilled(x,y,x+w,y+44,rgba(selected and C.selected or C.field),9) end
    if selected then d:AddRectFilled(x,y+12,x+3,y+32,rgba(C.purple),2) end
    icon(d,navIcons[index] or 'close',x+12,y+13,selected and C.purple or C.muted)
    font(16);d:AddText(x+39,y+15,rgba(selected and C.text or C.muted),label);font(17)
    return click
end
local function passive(name,x,y,w,h,body)
    ui.SetNextWindowPos(x,y,ImGuiCond.Always);ui.SetNextWindowSize(w,h,ImGuiCond.Always)
    if ui.Begin(name,ImGuiWindowFlags.NoInputs+ImGuiWindowFlags.NoTitleBar+ImGuiWindowFlags.NoResize+ImGuiWindowFlags.NoMove+ImGuiWindowFlags.NoSavedSettings+ImGuiWindowFlags.NoScrollbar) then font(17);body() end
    ui.End()
end
local descriptions={'Your trail. Your tools.','Look after yourself and your horse.','Keep your favorite places close.','A change of scenery, on your terms.','A workspace that feels like yours.'}
function M.draw(m)
    local nc,nv=theme();local dw,dh=ui.GetDisplaySize();local wide=dw>=1200;local side=244
    local w=math.min(940,dw-(wide and side+64 or 32));local h=math.min(640,dh-84)
    local x=math.max(16,(dw-w-(wide and side+16 or 0))/2);local y=math.max(64,(dh-h)/2+16)
    if m.open then
        ui.SetNextWindowSize(w,h,ImGuiCond.Always);ui.SetNextWindowPos(x,y,ImGuiCond.Always)
        local open,visible=ui.Begin('Vesper###FrontierMain',m.open,ImGuiWindowFlags.NoTitleBar+ImGuiWindowFlags.NoCollapse+ImGuiWindowFlags.NoResize+ImGuiWindowFlags.NoMove)
        m.open=open;font(17)
        if visible then
            color('ChildBg',C.panel);ui.PushStyleVar(ImGuiStyleVar.WindowPadding,12,18)
            ui.BeginChild('Sidebar',184,0,ImGuiChildFlags.AlwaysUseWindowPadding,0);font(17)
            local bx,by=ui.GetCursorScreenPos();local d=ui.GetWindowDrawList()
            d:AddLine(bx+1,by+3,bx+11,by+23,rgba(C.mint),3);d:AddLine(bx+11,by+23,bx+21,by+3,rgba(C.purple),3)
            ui.SetCursorPosX(ui.GetCursorPosX()+34);text(C.text,'vesper',25)
            text(C.muted,'RED DEAD REDEMPTION 2',10);ui.Dummy(1,24)
            text(C.muted,'WORKSPACE',11)
            for i,name in ipairs(m.pages) do if nav('page'..i,name,m.tab==i,i) then m.tab=i;m.selected=1;m.scrollSelection=true end end
            ui.Dummy(1,20);text(C.muted,'F7  /  LB + Down',12)
            if nav('close','Hide window',false,6) then m.open=false end
            ui.EndChild();ui.PopStyleVar();ui.PopStyleColor();ui.SameLine(0,20)
            ui.BeginChild('Workspace',0,0,false);font(17)
            text(C.text,m.pages[m.tab],28);text(C.muted,descriptions[m.tab],16);ui.Dummy(1,10)
            if ui.BeginChild('Cards',0,-50,false) then
                font(17)
                local cols=ui.GetContentRegionAvailX()>=560 and 2 or 1
                if ui.BeginTable('Feature columns',cols) then
                    ui.TableNextColumn();content(m,true);ui.TableNextColumn();content(m,false);ui.EndTable()
                    if M.revealTarget then
                        local _,cy=ui.GetWindowPos();local _,ch=ui.GetWindowSize()
                        ui.SetScrollY(math.max(0,ui.GetScrollY()+M.revealTarget-cy-ch/2));M.revealTarget=nil
                    end
                end
            end
            ui.EndChild();ui.Dummy(1,4)
            local fx,fy=ui.GetCursorScreenPos();ui.GetWindowDrawList():AddCircleFilled(fx+4,fy+7,3,rgba(m.pending and C.purple or C.mint),16)
            ui.SetCursorPosX(ui.GetCursorPosX()+16);font(13);text(C.muted,m.pending and 'Working...' or m.message);font(17)
            ui.EndChild()
        end
        ui.End()
    end
    local widgetX=x+w+16
    if m.open and wide then
        passive('Vesper keys###FrontierKeys',widgetX,y,side,242,function()
            text(C.text,'Keybinds',18);ui.Dummy(1,4)
            for _,v in ipairs({{'Menu','F7 / LB + Down'},{'Page','LB / RB'},{'Select','D-pad Up / Down'},{'Run action','A / Cross'},{'Close','B / Circle'}}) do
                font(13);local kx,ky=ui.GetCursorScreenPos();local kw=ui.GetContentRegionAvailX();local d=ui.GetWindowDrawList()
                d:AddText(kx,ky+5,rgba(C.muted),v[1]);local tw=ui.CalcTextSize(v[2]);d:AddRectFilled(kx+kw-tw-14,ky,kx+kw,ky+25,rgba(C.field),5)
                d:AddText(kx+kw-tw-7,ky+5,rgba(C.text),v[2]);ui.Dummy(kw,26);font(17)
            end
        end)
        passive('Vesper player###FrontierStatus',widgetX,y+258,side,210,function() text(C.text,'Player status',18);status(m,true) end)
    elseif not m.open and m.showHud and m.ready then
        passive('Vesper HUD',dw-260,72,244,182,function() text(C.purple,'VESPER',12);status(m,true) end)
    end
    if m.open or m.showHud then
        passive('Vesper watermark',dw-365,14,349,36,function()
            ui.SetCursorPos(14,10);font(13);text(C.muted,'VESPER   /   RDR2   /   '..(m.ready and m.carrier or 'Loading'));font(17)
        end)
    end
    ui.PopStyleVar(nv);ui.PopStyleColor(nc)
end
return M
