-- @api 2.1.0
-- @game RDR2
-- @lua any
-- @name Vesper
-- @author Scooby
-- @version 1.1.0
-- @description Standalone RDR2 travel, player, horse and world toolbox
compat.require{api='2.1.0',game='RDR2',capabilities={'custom_gui','modules','input_bindings'}}
compat.use('scooby')
local model=require('frontier.model').new()
local view=require('frontier.view')
local toggle=Input.createToggle{key=Keys.F7,controller={'LB','Down'}}
local previous,armed={},false
local refreshAt=0

function onLoad() model:load() end
script.register_looped('Frontier input and snapshot',function()
    local now=util.current_time_millis()
    model.focus=Input.isGameFocused()
    if now>=refreshAt then
        local ok,err=pcall(function() model:snapshot() end)
        if not ok then model.ready=false;model.message=tostring(err) end
        refreshAt=now+150
    end
    local pad=Input.getControllerState()
    model.pad=pad
    if toggle:poll() then
        model.open=not model.open;armed=false;previous={}
    elseif model.focus and model.open and pad.connected and not gui.is_open() then
        local b=pad.buttons or {}
        if not armed then
            local held=false
            for _,name in ipairs({'A','B','LB','RB','Up','Down','Left','Right'}) do held=held or b[name] end
            armed=not held
        else
            local function edge(name) return b[name] and not previous[name] end
            if edge('B') then model.open=false
            elseif edge('LB') or edge('Left') then model:page(-1)
            elseif edge('RB') or edge('Right') then model:page(1)
            elseif edge('Up') then model:select(-1)
            elseif edge('Down') then model:select(1)
            elseif edge('A') then model:activate(model.selected) end
        end
        previous={}
        for k,v in pairs(b) do previous[k]=v end
    else armed=false;previous={} end
end)
gui.add_always_draw_imgui(function()
    view.draw(model)
    gui.override_mouse(model.open and model.focus)
end)
-- Recovery control remains available in the host menu if the custom window is hidden.
gui.add_tab('Vesper'):add_button('Open Vesper (F7)',function() model.open=true end)
function onUnload()
    gui.override_mouse(false)
    model:cleanup()
    model:save()
end
