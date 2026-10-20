-- Works in both GTA5 and RDR2. Keep mutable values outside the render callback.
local ImGui = ImGuiCpp
local V = ImGui.ImVec2
local open, enabled = ImGui.Ref(true), ImGui.Ref(true)
local amount, selected = ImGui.Ref(0.5), ImGui.Ref(0)
local name = ImGui.Ref("My Lua UI")
local color = ImGui.ImVec4(0, 0.8, 1, 1)
local position = {0, 0, 0}

script.register_render(function()
    if not open.value then return end
    ImGui.SetNextWindowSize(V(520, 500), ImGui.ImGuiCond.FirstUseEver)
    local visible = ImGui.Begin("C++ to Lua example", open, ImGui.ImGuiWindowFlags.MenuBar)
    if visible then
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu("File") then
                if ImGui.MenuItem("Close") then open.value = false end
                ImGui.EndMenu()
            end
            ImGui.EndMenuBar()
        end
        ImGui.InputText("Name", name)
        ImGui.Checkbox("Enabled", enabled)
        ImGui.SliderFloat("Amount", amount, 0, 1, "%.2f")
        ImGui.DragFloat3("Position", position, 0.1)
        ImGui.Combo("Mode", selected, {"First", "Second", "Third"})
        ImGui.ColorEdit4("Accent", color)
        ImGui.ProgressBar(amount.value, V(-1, 0))
        if ImGui.BeginTable("Values", 2, ImGui.ImGuiTableFlags.Borders) then
            ImGui.TableSetupColumn("Setting"); ImGui.TableSetupColumn("Value")
            ImGui.TableHeadersRow()
            ImGui.TableNextRow(); ImGui.TableNextColumn(); ImGui.Text("Name")
            ImGui.TableNextColumn(); ImGui.TextUnformatted(name.value)
            ImGui.TableNextRow(); ImGui.TableNextColumn(); ImGui.Text("Mode (zero-based)")
            ImGui.TableNextColumn(); ImGui.Text("%d", selected.value)
            ImGui.EndTable()
        end
        local at = ImGui.GetCursorScreenPos()
        local width = math.max(1, ImGui.GetContentRegionAvail().x)
        ImGui.GetWindowDrawList():AddRectFilled(at, at + V(width, 32), ImGui.GetColorU32(color), 6)
        ImGui.Dummy(V(width, 36))
        ImGui.Text("Checkbox: %s", tostring(enabled.value))
    end
    -- Begin/BeginChild always need End/EndChild, even when invisible.
    ImGui.End()
end)
