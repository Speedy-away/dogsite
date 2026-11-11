local BASE = 2359980
local MAX_LEN = 32
local REFRESH_INTERVAL = 3000
local lastRefresh = 0
local selectedSlot = 0
local slotFeatures = {}
local function getOccupiedSlots()
    local slots = {}
    for i = 0, 20 do
        if ScriptGlobal.GetInt(BASE + 2309 + 1 + i) ~= 0 then
            slots[#slots + 1] = i
        end
    end
    return slots
end

local function getOutfitName(i)
    return ScriptGlobal.GetString(BASE + 2465 + (i * 8))
end

local function setOutfitName(i, name)
    ScriptGlobal.SetString(BASE + 2465 + (i * 8), name)
end

local inputFeature = FeatureMgr.AddFeature(Utils.Joaat("OutfitNameInput"), "Name", eFeatureType.InputText, "Enter new outfit name")

local applyFeature = FeatureMgr.AddFeature(Utils.Joaat("OutfitNameApply"), "Apply", eFeatureType.Button, "Apply the new name", function()
    local name = inputFeature:GetStringValue()
    if name == "" then
        GUI.AddToast("Outfit Editor", "Name cannot be empty", 3000)
        return
    end
    if #name > MAX_LEN then
        GUI.AddToast("Outfit Editor", string.format("Too long! %d/%d", #name, MAX_LEN), 3000)
        return
    end
    setOutfitName(selectedSlot, name)
    GUI.AddToast("Outfit Editor", string.format("Slot %d renamed to: %s", selectedSlot, name), 3000)
end)

local function rebuildSlots()
    for _, entry in ipairs(slotFeatures) do
        local f = FeatureMgr.GetFeature(entry.hash)
        if f then f:SetVisible(false) end
    end
    slotFeatures = {}

    local slots = getOccupiedSlots()
    for _, i in ipairs(slots) do
        local hash = Utils.Joaat(string.format("OutfitSlotBtn_%d", i))
        local existing = FeatureMgr.GetFeature(hash)
        if not existing then
            FeatureMgr.AddFeature(hash, string.format("[%d] %s", i, getOutfitName(i)), eFeatureType.Button, "Select outfit slot", function()
                selectedSlot = i
                inputFeature:SetStringValue(getOutfitName(i))
            end)
        else
            existing:SetVisible(true)
        end
        slotFeatures[#slotFeatures + 1] = { hash = hash, slot = i }
    end
end

local tickCallback = FeatureMgr.AddFeature(Utils.Joaat("OutfitEditorTickCb"), "##OutfitTickCb", eFeatureType.Button, "", function()
    local now = Time.GetEpocheMs()
    if now - lastRefresh >= REFRESH_INTERVAL then
        lastRefresh = now
        rebuildSlots()
    end
end)

tickCallback:SetVisible(false)
tickCallback:SetSearchable(false)
tickCallback:RegisterCallbackTrigger(eCallbackTrigger.OnTick)

rebuildSlots()

ClickGUI.AddTab("Outfit Editor", function()
    if ClickGUI.BeginCustomChildWindow("Outfit Editor##main") then
        ImGui.Spacing()
        ImGui.TextDisabled(string.format("  %d / 21 slots used   |   refreshes every %ds", #slotFeatures, REFRESH_INTERVAL / 1000))
        ImGui.Separator()
        ImGui.Spacing()
        if ImGui.BeginTable("OutfitGrid", 3, ImGuiTableFlags.SizingStretchSame) then
            for _, entry in ipairs(slotFeatures) do
                ImGui.TableNextColumn()
                local f = FeatureMgr.GetFeature(entry.hash)
                if f then
                    local name = getOutfitName(entry.slot)
                    f:SetName(string.format("%s%s", entry.slot == selectedSlot and "* " or "", name))
                    ClickGUI.RenderFeature(entry.hash)
                end
            end
            ImGui.EndTable()
        end
        ImGui.Spacing()
        ImGui.Separator()
        ImGui.Spacing()
        ImGui.TextColored(0.6, 0.6, 0.6, 1.0, "  SELECTED")
        ImGui.SameLine()
        ImGui.Text(string.format("Slot %d  —  %s", selectedSlot, getOutfitName(selectedSlot)))
        ImGui.Spacing()
        ClickGUI.RenderFeature(Utils.Joaat("OutfitNameInput"))
        ImGui.Spacing()
        local len = #inputFeature:GetStringValue()
        local t = len / MAX_LEN
        ImGui.TextColored(t, 1.0 - t, 0.0, 1.0, string.format("  %d / %d remaining", MAX_LEN - len, MAX_LEN))
        ImGui.Spacing()
        ClickGUI.RenderFeature(Utils.Joaat("OutfitNameApply"))
        ImGui.Spacing()
        ClickGUI.EndCustomChildWindow()
    end
end)
