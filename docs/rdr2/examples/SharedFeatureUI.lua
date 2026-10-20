-- GTA5 and RDR2: custom chrome, the host's actual feature state.
local I = ImGuiCpp
local V = I.ImVec2
local open = I.Ref(true)
local query = I.Ref('godmode')
local accent = I.ImVec4(0.28, 0.63, 0.92, 1)
local rows, controls = {}, {}
local refresh = true
local status = ''

local function update(id, value)
    script.run_in_fiber(function()
        local result, err = features.set(id, value)
        status = result and ('Updated ' .. id) or tostring(err)
        refresh = true
    end)
end

script.register_looped('shared-feature-ui', function(task)
    if refresh then
        refresh = false
        local result, err = features.list(query.value)
        rows, controls = {}, {}
        if result then
            for n = 1, math.min(#result, 100) do rows[n] = result[n] end
            status = string.format('%d matches; showing %d', #result, #rows)
        else status = tostring(err) end
    else
        for n, row in ipairs(rows) do rows[n] = features.get(row.id) or row end
    end
    task:sleep(200)
end)

script.register_render(function()
    if I.IsKeyPressed(I.ImGuiKey.F7) then open.value = not open.value end
    if gui and gui.override_mouse then gui.override_mouse(open.value) end
    if not open.value then return end
    I.PushStyleColor(I.ImGuiCol.CheckMark, accent)
    I.PushStyleColor(I.ImGuiCol.SliderGrab, accent)
    I.PushStyleColor(I.ImGuiCol.Button, I.ImVec4(accent.x * .45, accent.y * .45, accent.z * .45, 1))
    I.PushStyleVar(I.ImGuiStyleVar.WindowRounding, 8)
    I.SetNextWindowSize(V(680, 560), I.ImGuiCond.FirstUseEver)
    local visible = I.Begin('My feature workspace [F7]', open)
    if visible then
        if I.BeginTabBar('pages') then
            if I.BeginTabItem('Features') then
                if I.InputTextWithHint('Search', 'Feature ID or label', query) then refresh = true end
                I.SameLine()
                if I.Button('Refresh') then refresh = true end
                I.TextUnformatted(status)
                if I.BeginChild('features', V(0, -30)) then
                    for _, row in ipairs(rows) do
                        I.PushID(row.id)
                        I.BeginDisabled(not row.available)
                        local ref = controls[row.id] or I.Ref(row.value)
                        controls[row.id] = ref
                        ref.value = row.value
                        local changed = false
                        if row.type == 'boolean' then changed = I.Checkbox(row.label, ref)
                        elseif row.type == 'integer' then changed = I.InputInt(row.label, ref)
                        elseif row.type == 'number' then changed = I.InputFloat(row.label, ref)
                        elseif row.type == 'string' then changed = I.InputText(row.label, ref)
                        elseif row.type == 'list' then
                            local preview = tostring(row.value)
                            for _, option in ipairs(row.options) do if option.value == row.value then preview = option.label end end
                            if I.BeginCombo(row.label, preview) then
                                for _, option in ipairs(row.options) do
                                    if I.Selectable(option.label, option.value == row.value) then update(row.id, option.value) end
                                end
                                I.EndCombo()
                            end
                        elseif row.type == 'color' then
                            local color = I.ImVec4(row.value.x, row.value.y, row.value.z, row.value.w)
                            if I.ColorEdit4(row.label, color) then update(row.id, color) end
                        elseif row.type == 'vector3' then
                            local vector = {row.value.x, row.value.y, row.value.z}
                            if I.InputFloat3(row.label, vector) then update(row.id, {x=vector[1],y=vector[2],z=vector[3]}) end
                        elseif I.Button(row.label) then
                            local id = row.id
                            script.run_in_fiber(function() local ok, err = features.call(id); status = ok and ('Called '..id) or tostring(err) end)
                        end
                        if changed then update(row.id, ref.value) end
                        if I.IsItemHovered() then I.SetTooltip('%s\n%s', row.id, row.description) end
                        I.EndDisabled()
                        I.PopID()
                    end
                end
                I.EndChild()
                I.EndTabItem()
            end
            if I.BeginTabItem('Theme') then
                I.ColorEdit4('Workspace accent', accent)
                if I.Button('Apply accent to ClickUI and ListUI') then
                    local r,g,b,a = accent.x,accent.y,accent.z,accent.w
                    script.run_in_fiber(function() ui_theme.set_accent(math.floor(r*255),math.floor(g*255),math.floor(b*255),math.floor(a*255)) end)
                end
                I.EndTabItem()
            end
            I.EndTabBar()
        end
    end
    I.End()
    I.PopStyleVar()
    I.PopStyleColor(3)
end)

script.on_unload(function()
    if gui and gui.override_mouse then gui.override_mouse(false) end
end)
