-- Set a verified signature and its exact prototype for your installed build.
-- This template stays inactive until you fill in the pattern.
local module = "client.dll"
local pattern = ""
local signature = { abi = "win64", returns = "float", args = { "ptr" } }
if pattern == "" then
    print("Native hook template: enter your verified pattern and prototype first.")
    return
end

local address, scan_error = native.scan(module, pattern)
if not address then print(scan_error); return end
local hook, hook_error = native.hook(address, signature, [[
    return function(original, self)
        local result = original(self)
        shared.set("last_result", result)
        return result * (shared.get("multiplier") or 1)
    end
]])
if not hook then print(hook_error); return end
hook:set("multiplier", 1)

ui.tab("native_hook", "Native hook", function()
    local status = hook:status()
    if status.errors == 0 then
        local changed, enabled = ui.toggle("Enabled", status.enabled)
        if changed then hook:enable(enabled) end
    end
    local changed, multiplier = ui.slider("Multiplier", hook:get("multiplier") or 1, 0.1, 3)
    if changed then hook:set("multiplier", multiplier) end
    imgui.text("Calls: " .. status.calls .. " | Bypassed: " .. status.bypassed)
    if status.error ~= "" then imgui.text(status.error) end
end)
-- Unload/reload/error during startup retires this script's hook automatically.
