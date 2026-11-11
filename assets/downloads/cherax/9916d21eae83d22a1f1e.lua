-- X Script - Clean rounded Vehicle Damage Map
-- X Script
-- Cherax autoTheme
-- Test Version 94.7
-- Public Version 1
-- PERSONAL USE DISCLAIMER: This script is for personal use only, created by "GODX7PRIME".
-- Commercial use, redistribution, or releasing this script as open source is not permitted.


local THEME_HASH   = Utils.Joaat("autoTheme_Theme")
local APPLY_HASH   = Utils.Joaat("autoTheme_Apply")
local DEFAULT_HASH = Utils.Joaat("autoTheme_Default")
local REFRESH_HASH = Utils.Joaat("autoTheme_Refresh")

local themePaths = {}
local themeNames = {}
local themeAssets = {}
local themeTextures = {}
local textureRetryAt = {}

-- V17: each preview is permanently bound to its theme entry.
-- This avoids relying on a separate texture/index list that can become
-- visually mismatched after sorting or refreshing the theme list.
local themeEntries = {}

local function Log(msg)
    Logger.LogInfo("[X Script] " .. tostring(msg))
end

local function Lower(s)
    return string.lower(s or "")
end

local function Normalize(path)
    return (path or ""):gsub("/", "\\")
end

local function BaseName(path)
    local p = Normalize(path)
    return p:match("([^\\]+)$") or p
end

local function ParentFolder(path)
    local p = Normalize(path)
    p = p:gsub("\\[^\\]+$", "")
    return p:match("([^\\]+)$") or ""
end

local function Extension(path)
    local n = Lower(BaseName(path))
    return n:match("%.([^%.]+)$") or ""
end

local function IsImage(path)
    local e = Extension(path)
    return e == "png"
        or e == "jpg"
        or e == "jpeg"
        or e == "gif"
        or e == "bmp"
        or e == "webp"
end

local function IsJson(path)
    return Extension(path) == "json"
end

local function ThemeNameFromFolder(folder)
    return BaseName(folder)
end

-- =========================================================
-- Cherax's notification artwork convention
-- =========================================================
-- The theme assets supplied with Cherax use a specific artwork file
-- for the notification/toast image.  The important convention is:
--
--     toast_background.<png|gif|jpg|jpeg|bmp|webp>
--
-- Some themes use the equivalent:
--
--     background_toast.<...>
--
-- This is what we want for the preview cards.
--
-- DO NOT guess from "background.gif".  That is usually the full
-- menu background and was the reason older versions displayed the
-- entire theme background instead of the logo/artwork.
--
-- We intentionally resolve this by BASENAME, not by JSON contents.
-- That also handles themes containing several unrelated images.
-- =========================================================

local function IsToastArtwork(path)
    local name = Lower(BaseName(path))
    local stem = name:gsub("%.[^%.]+$", "")

    return stem == "toast_background"
        or stem == "background_toast"
end

local function AssetScore(path)
    local name = Lower(BaseName(path))
    local stem = name:gsub("%.[^%.]+$", "")
    local score = -100000

    -- Exact Cherax notification artwork: highest possible priority.
    if stem == "toast_background" then
        score = 100000
    elseif stem == "background_toast" then
        score = 99000
    elseif stem == "notification_background" then
        score = 98000
    elseif string.find(name, "notification", 1, true) then
        score = 90000
    elseif string.find(name, "toast", 1, true) then
        score = 85000
    elseif string.find(name, "logo", 1, true) then
        score = 70000
    elseif string.find(name, "icon", 1, true) then
        score = 69000
    elseif string.find(name, "emblem", 1, true) then
        score = 68000
    elseif string.find(name, "brand", 1, true) then
        score = 67000
    elseif string.find(name, "preview", 1, true) then
        score = 66000
    elseif string.find(name, "thumbnail", 1, true) then
        score = 65000
    else
        -- Ordinary artwork is deliberately NOT a preview fallback.
        -- In particular, background.gif/png must never win.
        return -100000
    end

    -- Prefer animated notification artwork when both GIF and PNG
    -- versions of the same basename exist.
    local e = Extension(path)
    if e == "gif" then
        score = score + 300
    elseif e == "png" then
        score = score + 200
    elseif e == "webp" then
        score = score + 150
    elseif e == "jpg" or e == "jpeg" then
        score = score + 100
    end

    return score
end

local function PickBestAsset(list)
    if not list or #list == 0 then
        return nil
    end

    local best = nil
    local bestScore = -100000

    for i = 1, #list do
        local score = AssetScore(list[i])

        if score > bestScore then
            best = list[i]
            bestScore = score
        end
    end

    if bestScore < 0 then
        return nil
    end

    return best
end

-- =========================================================
-- Background fallback
-- =========================================================
-- If a theme does not have a recognizable logo/notification artwork,
-- use its actual background asset instead of showing "No preview".
-- This is deliberately a SECONDARY fallback: logos/toast artwork always
-- win when available.

local function BackgroundAssetScore(path)
    local name = Lower(BaseName(path))
    local stem = name:gsub("%.[^%.]+$", "")
    local score = -100000

    if stem == "background" then
        score = 10000
    elseif stem == "menu_background" then
        score = 9000
    elseif stem == "clickgui_background" then
        score = 8500
    else
        return -100000
    end

    -- Prefer GIF first so animated theme backgrounds remain animated.
    local e = Extension(path)
    if e == "gif" then
        score = score + 300
    elseif e == "png" then
        score = score + 200
    elseif e == "webp" then
        score = score + 150
    elseif e == "jpg" or e == "jpeg" then
        score = score + 100
    end

    return score
end

local function PickBackgroundAsset(list)
    if not list or #list == 0 then
        return nil
    end

    local best = nil
    local bestScore = -100000

    for i = 1, #list do
        local score = BackgroundAssetScore(list[i])
        if score > bestScore then
            best = list[i]
            bestScore = score
        end
    end

    if bestScore < 0 then
        return nil
    end

    return best
end

local function BeginLoadTexture(path)
    if not path or path == "" then
        return nil
    end

    -- Cherax exposes both synchronous and asynchronous texture loading.
    -- Theme GIF/PNG files can take a frame to become a valid D3D resource,
    -- so we deliberately keep the texture ID and resolve the SRV later.
    local ok, id = pcall(function()
        return Texture.LoadTextureAsync(path)
    end)

    if not ok or not id then
        Log("Texture async load failed: " .. tostring(BaseName(path)))
        return nil
    end

    return {
        id = id,
        texture = nil,
        path = path,
        ready = false
    }
end

local function ResolveTexture(info)
    if not info or not info.id then
        return nil
    end

    -- IMPORTANT:
    -- Texture.GetTexture() returns a D3D11Texture object.
    -- ImGui.AddImage() does NOT take D3D11Texture; it takes D3D11SRV.
    -- The D3D11Texture API exposes GetCurrent()/GetFrame() specifically
    -- to obtain the SRV. Older versions passed the D3D11Texture directly,
    -- which is why the preview rectangles rendered black.
    local validOk, valid = pcall(function()
        return Texture.IsTextureValid(info.id)
    end)

    if not validOk or valid ~= true then
        return nil
    end

    local texOk, texture = pcall(function()
        return Texture.GetTexture(info.id)
    end)

    if not texOk or not texture then
        return nil
    end

    info.texture = texture

    -- IMPORTANT: GetCurrent() is intentionally called EVERY render.
    -- Cherax's texture object advances animated assets such as GIFs.
    -- Caching the returned SRV freezes the preview on frame 0.
    local currentOk, current = pcall(function()
        return texture:GetCurrent()
    end)

    if currentOk and current then
        info.ready = true
        info.lastSrv = current
        return current
    end

    -- Fallback for texture implementations where GetCurrent() is unavailable.
    local frameOk, frame = pcall(function()
        return texture:GetFrame(0)
    end)

    if frameOk and frame then
        info.ready = true
        info.lastSrv = frame
        return frame
    end

    return nil
end

local function ClearTextureCache()
    -- Cherax does not document a texture-delete API.
    -- Therefore we keep the old texture objects alive rather than
    -- calling an undocumented destruction function.
    themeTextures = {}
    textureRetryAt = {}
end

local function FindThemes()
    themePaths = {}
    themeNames = {}
    themeAssets = {}
    themeEntries = {}

    local root = FileMgr.GetMenuRootPath()
    local themeRoot = Normalize(root) .. "\\Theme\\ClickGUI"

    Log("Scanning theme JSONs in " .. themeRoot)

    -- IMPORTANT V18:
    -- Do NOT scan every image under ClickGUI and then try to associate
    -- images with themes afterwards. That is what caused the preview/theme
    -- mismatch we were seeing.
    --
    -- Instead:
    --   1. Find the theme JSON files.
    --   2. For EACH JSON, determine its actual theme folder.
    --   3. Scan ONLY that folder for its images.
    --
    -- This makes the relationship physically local:
    --
    --   Theme/ClickGUI/cyberpunk 2/cyberpunk 2.json
    --              -> ONLY assets below Theme/ClickGUI/cyberpunk 2/
    --
    -- An image from another theme can therefore never be selected for this
    -- theme, regardless of FileMgr's global result ordering.

    local function FindExt(path, ext)
        local ok, files = pcall(function()
            return FileMgr.FindFiles(path, "." .. ext, true)
        end)

        if ok and files then
            return files
        end

        return {}
    end

    local jsonFiles = FindExt(themeRoot, "json")

    local function ThemeFolderFromJson(jsonPath)
        local p = Normalize(jsonPath)
        local low = Lower(p)
        local marker = Lower(Normalize(themeRoot)) .. "\\"
        local pos = string.find(low, marker, 1, true)

        if pos then
            local relative = p:sub(pos + #marker)
            local folderName = relative:match("^([^\\]+)") or ""
            if folderName ~= "" then
                return Normalize(themeRoot) .. "\\" .. folderName, folderName
            end
        end

        -- If FileMgr returned a path relative to ClickGUI, the first
        -- component is still the theme folder.
        local relativeFolder = p:match("^([^\\]+)") or ""
        if relativeFolder ~= "" then
            return Normalize(themeRoot) .. "\\" .. relativeFolder, relativeFolder
        end

        return nil, nil
    end

    -- First create one entry per actual theme JSON.
    -- A JSON file is the authority for whether a folder is a theme.
    local discovered = {}
    local seen = {}

    for _, jsonPath in pairs(jsonFiles) do
        local p = Normalize(jsonPath)
        if IsJson(p) then
            local folderPath, folderName = ThemeFolderFromJson(p)

            if folderPath and folderName then
                local key = Lower(folderPath)
                if not seen[key] then
                    seen[key] = true
                    table.insert(discovered, {
                        name = folderName,
                        json = p,
                        folder = folderPath,
                        assets = {}
                    })
                end
            end
        end
    end

    -- Scan each theme folder independently.
    local imageExtensions = {
        "png", "gif", "jpg", "jpeg", "bmp", "webp"
    }

    for _, entry in ipairs(discovered) do
        for _, ext in ipairs(imageExtensions) do
            local files = FindExt(entry.folder, ext)

            for _, path in pairs(files) do
                local p = Normalize(path)
                if IsImage(p) then
                    local duplicate = false

                    for _, existing in ipairs(entry.assets) do
                        if Lower(Normalize(existing)) == Lower(p) then
                            duplicate = true
                            break
                        end
                    end

                    if not duplicate then
                        table.insert(entry.assets, p)
                    end
                end
            end
        end

        -- Resolve the preview while the asset list still belongs exclusively
        -- to this theme folder.
        local preview = PickBestAsset(entry.assets)
        local previewType = "logo/artwork"

        if not preview then
            preview = PickBackgroundAsset(entry.assets)
            previewType = "background fallback"
        end

        entry.preview = preview

        Log(
            "Theme: " .. entry.name ..
            " | JSON: " .. BaseName(entry.json) ..
            " | Folder: " .. entry.folder ..
            " | Assets: " .. tostring(#entry.assets) ..
            " | Preview: " .. tostring(preview and preview or "none") ..
            " | Type: " .. previewType
        )
    end

    -- Stable alphabetical ordering. The complete entry stays together,
    -- including JSON path, folder, selected preview, and texture object.
    table.sort(discovered, function(a, b)
        return Lower(a.name) < Lower(b.name)
    end)

    for _, item in ipairs(discovered) do
        local entry = {
            name = item.name,
            json = item.json,
            folder = item.folder,
            preview = item.preview,
            texture = nil
        }

        table.insert(themeEntries, entry)
        table.insert(themePaths, entry.json)
        table.insert(themeNames, entry.name)
        table.insert(themeAssets, entry.preview)
    end

    if #themeEntries == 0 then
        local entry = {
            name = "No themes found",
            json = "",
            folder = "",
            preview = nil,
            texture = nil
        }

        table.insert(themeEntries, entry)
        table.insert(themeNames, entry.name)
        table.insert(themePaths, entry.json)
        table.insert(themeAssets, entry.preview)
    end

    ClearTextureCache()

    -- Start one texture load for the exact preview path belonging to each
    -- exact theme entry. The renderer never performs positional reassignment.
    for i, entry in ipairs(themeEntries) do
        if entry.preview then
            entry.texture = BeginLoadTexture(entry.preview)
        end
        themeTextures[i] = entry.texture
    end

    Log("Finished scan. Found " .. tostring(#themeEntries) .. " themes.")
end

-- =========================================================
-- Features
-- =========================================================

local themeFeature
local defaultFeature
local applyFeature
local refreshFeature

-- Forward declaration used by the safe theme rebuild callback.
local RenderTestScriptTab

FeatureMgr.AddFeature(
    THEME_HASH,
    "Theme",
    eFeatureType.Combo,
    "Select an installed Cherax theme."
)

FeatureMgr.AddFeature(
    APPLY_HASH,
    "Apply Selected Theme",
    eFeatureType.Button,
    "Safely rebuild the Lua tab around Cherax's theme loader.",
    function()
        local idx = themeFeature:GetListIndex() + 1
        local name = themeNames[idx]

        if not name or name == "No themes found" then
            Logger.LogError("[autoTheme] No valid theme selected.")
            return
        end

        -- IMPORTANT: the Lua tab must be removed BEFORE LoadTheme().
        -- LoadTheme() rebuilds ClickGUI and can invalidate the tab coroutine.
        -- This callback runs outside the tab renderer, so the tab can be
        -- removed cleanly before Cherax rebuilds the GUI.
        local removeOk, removed = pcall(function()
            return ClickGUI.RemoveTab("X Script")
        end)
        if not removeOk then removed = false end

        if removed == false then
            Logger.LogError("[autoTheme] Could not remove X Script tab; theme load aborted for safety.")
            return
        end

        local loadOk, loaded = pcall(function()
            return ClickGUI.LoadTheme(name)
        end)
        if not loadOk then loaded = false end

        if loaded == false then
            Logger.LogError("[autoTheme] Cherax rejected theme: " .. tostring(name))
        else
            Logger.LogInfo("[autoTheme] Applied theme: " .. tostring(name))
        end

        -- Re-register the tab after the GUI rebuild. The renderer function is
        -- defined later in the file, but the callback itself is only executed
        -- after startup, so RenderTestScriptTab will already be assigned.
        pcall(function()
            ClickGUI.AddTab("X Script", RenderTestScriptTab)
        end)
    end
)

FeatureMgr.AddFeature(
    DEFAULT_HASH,
    "Use Selected Theme as Default",
    eFeatureType.Toggle,
    "Remember the selected theme choice. Theme loading is intentionally not performed by this Lua tab."
)

FeatureMgr.AddFeature(
    REFRESH_HASH,
    "Refresh Theme List",
    eFeatureType.Button,
    "Rescan the Cherax ClickGUI theme directory.",
    function()
        FindThemes()
        themeFeature:SetList(themeNames)

        if #themeNames > 0 then
            FeatureMgr.SetFeatureListIndex(THEME_HASH, 0)
        end

        Log("Theme list refreshed.")
    end
)

themeFeature = FeatureMgr.GetFeature(THEME_HASH)
defaultFeature = FeatureMgr.GetFeature(DEFAULT_HASH)
applyFeature = FeatureMgr.GetFeature(APPLY_HASH)
refreshFeature = FeatureMgr.GetFeature(REFRESH_HASH)

themeFeature:SetList(themeNames)
themeFeature:SetSaveable(true)
defaultFeature:SetSaveable(true)

-- =========================================================
-- Startup scan
-- =========================================================

FindThemes()
themeFeature:SetList(themeNames)

-- IMPORTANT:
-- Do not call ClickGUI.LoadTheme() from this script. Loading a Cherax theme
-- rebuilds the GUI and can invalidate the coroutine that owns this Lua tab.
-- The theme gallery remains fully usable for browsing/selecting themes, while
-- actual theme loading is left to Cherax's own theme/settings UI.

-- =========================================================
-- Custom preview renderer
-- =========================================================

local function SelectTheme(index)
    if index < 1 or index > #themeNames then
        return
    end

    FeatureMgr.SetFeatureListIndex(THEME_HASH, index - 1)
end

local function GetThemeTexture(index)
    local entry = themeEntries[index]
    if not entry then
        return nil
    end

    -- The preview belongs to this entry only. Never fall back to another
    -- index because asynchronous texture loading can complete out of order.
    if not entry.texture and entry.preview then
        entry.texture = BeginLoadTexture(entry.preview)
        themeTextures[index] = entry.texture
    end

    return entry.texture
end

local function DrawPreviewImage(textureInfo, x, y, w, h)
    local texture = ResolveTexture(textureInfo)

    if not texture then
        return false
    end

    local ok = pcall(function()
        -- Explicit UVs + opaque white tint. Do not rely on binding defaults.
        ImGui.AddImage(
            texture,
            x, y,
            x + w, y + h,
            0.0, 0.0,
            1.0, 1.0,
            0xFFFFFFFF
        )
    end)

    return ok
end

-- =========================================================
-- V21 animated UI helpers
-- =========================================================
-- All animation is done with documented drawing primitives + Time.Get().
-- We do NOT modify Cherax's global ImGui style, so the active Cherax theme
-- remains in control of the rest of the menu.

local INTRO_DURATION = 3.20
local INTRO_FADE_OUT = 0.55
local START_TIME = Time.Get()

local function Clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function SmoothStep(t)
    t = Clamp(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- A slow purple -> cyan -> pink -> purple cycle.
local function AnimatedAccent(t)
    local phase = (t % 6.0) / 6.0

    local r, g, b
    if phase < 0.3333 then
        local p = phase / 0.3333
        r = Lerp(190, 0, p)
        g = Lerp(0, 220, p)
        b = 255
    elseif phase < 0.6666 then
        local p = (phase - 0.3333) / 0.3333
        r = Lerp(0, 255, p)
        g = Lerp(220, 0, p)
        b = Lerp(255, 210, p)
    else
        local p = (phase - 0.6666) / 0.3334
        r = Lerp(255, 190, p)
        g = 0
        b = Lerp(210, 255, p)
    end

    return math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5)
end

local function DrawAnimatedAccentLine(x, y, w, thickness, alpha)
    local t = Time.Get()
    local r, g, b = AnimatedAccent(t * 0.65)
    local pulse = 0.55 + 0.45 * math.sin(t * 3.2)
    local a = math.floor(Clamp(alpha * pulse, 0, 255))

    -- Soft glow layers.
    ImGui.AddLine(x, y, x + w, y, r, g, b, math.floor(a * 0.18), thickness + 4.0)
    ImGui.AddLine(x, y, x + w, y, r, g, b, math.floor(a * 0.35), thickness + 2.0)
    ImGui.AddLine(x, y, x + w, y, r, g, b, a, thickness)
end

local function DrawAnimatedCardBorder(x, y, w, h, selected, hovered)
    local t = Time.Get()
    local r, g, b = AnimatedAccent(t * 0.85 + x * 0.002)

    if selected then
        local pulse = 0.70 + 0.30 * math.sin(t * 4.5)
        local a = math.floor(210 + 45 * pulse)

        -- Two very subtle glow passes behind the crisp border.
        ImGui.AddRect(x - 4, y - 4, x + w + 4, y + h + 4,
            r, g, b, math.floor(a * 0.18), 7.0, 0, 5.0)
        ImGui.AddRect(x - 2, y - 2, x + w + 2, y + h + 2,
            r, g, b, math.floor(a * 0.35), 7.0, 0, 3.0)
        ImGui.AddRect(x - 1, y - 1, x + w + 1, y + h + 1,
            r, g, b, a, 7.0, 0, 2.0)
    elseif hovered then
        ImGui.AddRect(x - 1, y - 1, x + w + 1, y + h + 1,
            r, g, b, 175, 7.0, 0, 1.5)
    end
end

local function DrawIntro()
    local elapsed = Time.Get() - START_TIME
    if elapsed >= INTRO_DURATION then
        return false
    end

    local x, y = ImGui.GetCursorScreenPos()
    local w = 650
    local h = 430

    local fadeIn = SmoothStep(elapsed / 0.55)
    local fadeOut = 1.0
    if elapsed > INTRO_DURATION - INTRO_FADE_OUT then
        fadeOut = 1.0 - SmoothStep((elapsed - (INTRO_DURATION - INTRO_FADE_OUT)) / INTRO_FADE_OUT)
    end
    local alpha = Clamp(fadeIn * fadeOut, 0.0, 1.0)

    local ar, ag, ab = AnimatedAccent(elapsed * 0.8)

    -- Dark cinematic splash panel.
    ImGui.AddRectFilled(
        x, y, x + w, y + h,
        4, 4, 9, math.floor(238 * alpha),
        10.0
    )

    -- Animated outer frame.
    ImGui.AddRect(
        x, y, x + w, y + h,
        ar, ag, ab, math.floor(235 * alpha),
        10.0, 0, 2.0
    )

    -- Moving light line gives the splash a little life without being noisy.
    local sweep = (elapsed * 360.0) % (w + 180.0)
    ImGui.AddLine(
        x + sweep - 180.0, y + 1,
        x + sweep, y + 1,
        ar, ag, ab, math.floor(220 * alpha), 3.0
    )

    local titleY = y + 135
    ImGui.AddText(
        x + 190, titleY,
        "THEME AUTOLOADER",
        255, 255, 255, math.floor(255 * alpha)
    )

    ImGui.AddText(
        x + 220, titleY + 38,
        "V21",
        ar, ag, ab, math.floor(255 * alpha)
    )

    ImGui.AddText(
        x + 178, titleY + 78,
        "Loading your Cherax themes...",
        185, 185, 195, math.floor(255 * alpha)
    )

    -- Animated loading bar.
    local barX = x + 150
    local barY = y + 285
    local barW = 350
    local barH = 5
    local progress = Clamp(elapsed / INTRO_DURATION, 0.0, 1.0)

    ImGui.AddRectFilled(
        barX, barY, barX + barW, barY + barH,
        35, 35, 45, math.floor(220 * alpha),
        3.0
    )

    ImGui.AddRectFilled(
        barX, barY, barX + barW * progress, barY + barH,
        ar, ag, ab, math.floor(255 * alpha),
        3.0
    )

    local dots = string.rep(".", math.floor((elapsed * 2.5) % 4))
    ImGui.AddText(
        x + 285, y + 320,
        "READY" .. dots,
        160, 160, 170, math.floor(220 * alpha)
    )

    return true
end

local CARD_ANIM_START = Time.Get()

local function DrawSectionHeader(title, subtitle)
    local x, y = ImGui.GetCursorScreenPos()
    local ar, ag, ab = AnimatedAccent(Time.Get() * 0.45)

    ImGui.AddText(x, y, title, 255, 255, 255, 255)
    if subtitle and subtitle ~= "" then
        ImGui.AddText(x + 150, y + 1, subtitle, 145, 145, 155, 255)
    end

    DrawAnimatedAccentLine(x, y + 24, 670, 1.0, 210)
    ImGui.SetCursorScreenPos(x, y + 32)
end

local function DrawCardMeta(x, y, w, h, index, selected, hovered)
    local entry = themeEntries[index]
    local name = themeNames[index] or "Unknown"
    local ar, ag, ab = AnimatedAccent(Time.Get() * 0.72 + index * 0.22)

    -- Card shell.
    ImGui.AddRectFilled(
        x, y, x + w, y + h,
        13, 13, 18,
        hovered and 238 or 220,
        8.0
    )

    -- Thin top accent.
    ImGui.AddRectFilled(
        x + 1, y + 1, x + w - 1, y + 4,
        ar, ag, ab,
        selected and 230 or 65,
        7.0
    )

    -- Preview well.
    ImGui.AddRectFilled(
        x + 8, y + 10,
        x + w - 8, y + 100,
        7, 7, 12,
        255,
        6.0
    )

    local tex = GetThemeTexture(index)
    if tex then
        -- Re-resolve the texture every frame so animated GIF previews play.
        DrawPreviewImage(tex, x + 9, y + 11, w - 18, 88)
    else
        ImGui.AddText(
            x + (w * 0.5) - 40, y + 48,
            "No preview",
            135, 135, 145, 255
        )
    end

    -- Name row.
    ImGui.AddText(
        x + 11, y + 108,
        name,
        245, 245, 250, 255
    )

    if selected then
        ImGui.AddText(
            x + w - 62, y + 108,
            "ACTIVE",
            ar, ag, ab, 255
        )
    elseif entry and entry.preview then
        ImGui.AddText(
            x + w - 57, y + 108,
            "READY",
            145, 145, 155, 255
        )
    end
end

local function DrawCards()
    local cardW = 155
    local cardH = 136
    local gapX = 10
    local gapY = 10
    local columns = 4

    local startX, startY = ImGui.GetCursorScreenPos()
    local selected = themeFeature:GetListIndex() + 1
    local revealT = Time.Get() - CARD_ANIM_START

    for i = 1, #themeNames do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        local x = startX + col * (cardW + gapX)
        local y = startY + row * (cardH + gapY)

        -- Small staggered reveal. Once revealed, cards stay stable.
        local reveal = Clamp((revealT - (i - 1) * 0.045) / 0.30, 0.0, 1.0)
        local ease = SmoothStep(reveal)
        local drawY = y + (1.0 - ease) * 12.0
        local alpha = math.floor(255 * ease)

        ImGui.SetCursorScreenPos(x, drawY)
        local clicked = ImGui.InvisibleButton(
            "ThemeCardV23##" .. tostring(i),
            cardW,
            cardH
        )
        local hovered = ImGui.IsItemHovered()

        if clicked then
            SelectTheme(i)
        end

        -- Keep the same physical card geometry; only the first reveal moves.
        DrawCardMeta(x, drawY, cardW, cardH, i, i == selected, hovered)

        -- Animated selection/hover border.
        if i == selected then
            DrawAnimatedCardBorder(
                x, drawY, cardW, cardH, true, hovered
            )
        elseif hovered then
            DrawAnimatedCardBorder(
                x, drawY, cardW, cardH, false, true
            )
        end

        -- Tiny selection marker.
        if i == selected then
            local ar, ag, ab = AnimatedAccent(Time.Get() * 0.9)
            ImGui.AddCircleFilled(
                x + cardW - 17, drawY + 17,
                4.5,
                ar, ag, ab, 245,
                16
            )
        end
    end

    local rows = math.ceil(#themeNames / columns)
    local totalH = rows * (cardH + gapY)

    ImGui.SetCursorScreenPos(
        startX,
        startY + totalH
    )
end

-- =========================================================
-- =========================================================

-- =========================================================
-- Vehicle Damage Analyzer
-- =========================================================
-- Read-only vehicle diagnostics. This feature does not modify
-- the vehicle; it only reads documented Cherax CVehicle state.

local VEHICLE_TAB_HASH = Utils.Joaat("autoTheme_VehicleAnalyzer")

local vehicleHistory = {}
local previousVehicleState = {}

local function SafeRead(fn, fallback)
    local ok, value = pcall(fn)
    if ok and value ~= nil then
        return value
    end
    return fallback
end

-- V75: Safe toggle helper. Older revisions referenced this helper without
-- defining it, which crashed the LSCM runtime callback and blanked the tab.
local function SafeFeatureToggled(feature)
    if not feature then return false end
    return SafeRead(function() return feature:IsToggled() end, false) == true
end

local function VehiclePercent(value, maximum)
    value = tonumber(value)
    if not value then return nil end
    maximum = maximum or 1000.0
    if maximum == 0 then return 0 end

    local pct = (value / maximum) * 100.0
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct
end

local function AddVehicleHistory(label, oldValue, newValue)
    if oldValue == nil or newValue == nil then
        return
    end

    local oldNum = tonumber(oldValue)
    local newNum = tonumber(newValue)

    if oldNum and newNum then
        if math.abs(newNum - oldNum) < 0.5 then
            return
        end
    elseif tostring(oldValue) == tostring(newValue) then
        return
    end

    table.insert(vehicleHistory, 1, {
        label = label,
        oldValue = oldValue,
        newValue = newValue
    })

    while #vehicleHistory > 8 do
        table.remove(vehicleHistory)
    end
end

local function ReadVehicleState(vehicle)
    if not vehicle then
        return nil
    end

    local state = {}

    state.modelHash = SafeRead(function()
        return vehicle.ModelInfo and vehicle.ModelInfo.Hash
    end, nil)

    state.bodyHealth = SafeRead(function()
        return vehicle.BodyHealth
    end, nil)

    state.engineHealth = SafeRead(function()
        return vehicle.packedEngineHealth
    end, nil)

    state.petrolHealth = SafeRead(function()
        return vehicle.PetrolTankHealth
    end, nil)

    state.dirt = SafeRead(function()
        return vehicle.DirtLevel
    end, nil)

    state.wrecked = SafeRead(function()
        return vehicle.isWrecked
    end, false)

    state.blownUp = SafeRead(function()
        return vehicle.isBlownUp
    end, false)

    state.numWheels = SafeRead(function()
        return vehicle.numWheels
    end, 0)

    state.tyreDamaged = SafeRead(function()
        return vehicle.tyreDamaged
    end, {})

    state.tyreDestroyed = SafeRead(function()
        return vehicle.tyreDestroyed
    end, {})

    state.tyreBrokenOff = SafeRead(function()
        return vehicle.tyreBrokenOff
    end, {})

    state.suspensionHealth = SafeRead(function()
        return vehicle.suspensionHealth
    end, {})

    state.hasDamageEntity = SafeRead(function()
        return vehicle.hasDamageEntity
    end, false)

    state.lastDamagedMaterialId = SafeRead(function()
        return vehicle.lastDamagedMaterialId
    end, nil)

    state.weaponDamageHash = SafeRead(function()
        return vehicle.weaponDamageHash
    end, nil)

    state.velocity = SafeRead(function()
        return vehicle:GetVelocity()
    end, nil)

    return state
end

local function UpdateVehicleHistory(state)
    if not state then return end

    AddVehicleHistory(
        "Engine health",
        previousVehicleState.engineHealth,
        state.engineHealth
    )

    AddVehicleHistory(
        "Body health",
        previousVehicleState.bodyHealth,
        state.bodyHealth
    )

    AddVehicleHistory(
        "Petrol tank",
        previousVehicleState.petrolHealth,
        state.petrolHealth
    )

    if previousVehicleState.tyreDamaged and state.tyreDamaged then
        for i = 0, 7 do
            local old = previousVehicleState.tyreDamaged[i]
            local new = state.tyreDamaged[i]

            if old ~= new and new == true then
                AddVehicleHistory(
                    "Tyre " .. tostring(i + 1),
                    "OK",
                    "DAMAGED"
                )
            end
        end
    end

    previousVehicleState = state
end

local function AnalyzerStatus(x, y, text, ok)
    if ok then
        ImGui.AddText(
            x, y, text,
            75, 225, 135, 255
        )
    else
        ImGui.AddText(
            x, y, text,
            255, 75, 90, 255
        )
    end
end

local function AnalyzerBar(x, y, width, label, pct)
    if pct == nil then
        ImGui.AddText(
            x, y,
            label .. "  N/A",
            155, 155, 170, 255
        )
        return
    end

    local value = pct
    local r, g, b = 75, 225, 135

    if value < 30 then
        r, g, b = 255, 75, 90
    elseif value < 65 then
        r, g, b = 255, 185, 70
    end

    ImGui.AddText(
        x, y - 20,
        label .. "  " .. string.format("%.0f%%", value),
        210, 210, 220, 255
    )

    ImGui.AddRectFilled(
        x, y, x + width, y + 9,
        38, 38, 45, 255,
        4
    )

    if value > 0 then
        ImGui.AddRectFilled(
            x, y, x + (width * value / 100.0), y + 9,
            r, g, b, 255,
            4
        )
    end
end

local function AnalyzerWheel(x, y, label, damaged, destroyed, brokenOff)
    local status = "OK"
    local r, g, b = 75, 225, 135

    if destroyed then
        status = "DESTROYED"
        r, g, b = 255, 65, 85
    elseif brokenOff then
        status = "BROKEN OFF"
        r, g, b = 255, 65, 85
    elseif damaged then
        status = "DAMAGED"
        r, g, b = 255, 185, 70
    end

    ImGui.AddText(
        x, y,
        label .. "  " .. status,
        r, g, b, 255
    )
end

-- =========================================================
-- TEST FEATURES: SELF / OTHERS
-- =========================================================

-- V74: namespace the added feature state to avoid Cherax/Lua's 200-local limit.
local TSGF = {}
-- These are normal FeatureMgr features rendered only inside this script's
-- internal tabs. They do not create additional ClickGUI.AddTab() entries.


-- V74: real Self utilities. The previous diagnostic/monitor features are gone.
TSGF.SELF_LOCK_WEAPON_HASH = Utils.Joaat("TestScript_SelfLockWeapon")
TSGF.SELF_FIRE_PROOF_HASH = Utils.Joaat("TestScript_SelfFireProof")
TSGF.SELF_COLLISION_PROOF_HASH = Utils.Joaat("TestScript_SelfCollisionProof")
TSGF.SELF_MELEE_PROOF_HASH = Utils.Joaat("TestScript_SelfMeleeProof")
TSGF.SELF_FAST_STUN_HASH = Utils.Joaat("TestScript_SelfFastStunRecovery")

-- Keep the phone-call utility requested earlier.
TSGF.AUTO_REJECT_CALLS_HASH = Utils.Joaat("TestScript_AutoRejectPhoneCalls")

TSGF.selfLockWeaponFeature = nil
TSGF.selfFireProofFeature = nil
TSGF.selfCollisionProofFeature = nil
TSGF.selfMeleeProofFeature = nil
TSGF.selfFastStunFeature = nil
TSGF.autoRejectCallsFeature = nil
TSGF.selfProofsWereApplied = false

TSGF.SELF_PROOF_NATIVE = 0xFAEE099C6F890BB8
TSGF.SET_PED_CAN_SWITCH_WEAPON_NATIVE = 0xED7F7EFE9FABF340
TSGF.SET_PED_STUNGUN_GROUND_TIME_NATIVE = 0xFA0675AB151073FA

local function SelfFeatureOn(feature)
    return feature and SafeRead(function() return feature:IsToggled() end, false) == true
end

local function UpdateSelfUsefulFeatures()
    local ped = SafeRead(function() return GTA.GetLocalPed() end, nil)
    if not ped then return end

    -- Selective damage proofs. These are intentionally independent from
    -- Vehicle General and never alter vehicle weapon flags.
    local fire = SelfFeatureOn(TSGF.selfFireProofFeature)
    local collision = SelfFeatureOn(TSGF.selfCollisionProofFeature)
    local melee = SelfFeatureOn(TSGF.selfMeleeProofFeature)
    local anyProof = fire or collision or melee

    if anyProof then
        pcall(function()
            Natives.InvokeVoid(
                TSGF.SELF_PROOF_NATIVE,
                ped,
                false,
                fire,
                false,
                collision,
                melee,
                false,
                false,
                false
            )
        end)
        TSGF.selfProofsWereApplied = true
    elseif TSGF.selfProofsWereApplied then
        pcall(function()
            Natives.InvokeVoid(TSGF.SELF_PROOF_NATIVE, ped, false, false, false, false, false, false, false, false)
        end)
        TSGF.selfProofsWereApplied = false
    end

    pcall(function()
        Natives.InvokeVoid(TSGF.SET_PED_CAN_SWITCH_WEAPON_NATIVE, ped, not SelfFeatureOn(TSGF.selfLockWeaponFeature))
    end)

    -- Zero keeps the post-taser ground delay as short as the game permits.
    pcall(function()
        Natives.InvokeVoid(TSGF.SET_PED_STUNGUN_GROUND_TIME_NATIVE, ped, SelfFeatureOn(TSGF.selfFastStunFeature) and 0 or 1500)
    end)

end


TSGF.SELF_FEATURE_DEFS = {
    {TSGF.SELF_LOCK_WEAPON_HASH, "Lock Current Weapon", "Prevent automatic weapon switching while the feature is active."},
    {TSGF.SELF_FIRE_PROOF_HASH, "Fire Proof", "Block fire/flame damage without enabling full god mode."},
    {TSGF.SELF_COLLISION_PROOF_HASH, "Collision Proof", "Block collision damage without enabling full god mode."},
    {TSGF.SELF_MELEE_PROOF_HASH, "Melee Proof", "Block melee damage without enabling full god mode."},
    {TSGF.SELF_FAST_STUN_HASH, "Fast Stun Recovery", "Minimize the time your ped stays down after being hit by a stun gun."},
}

for i = 1, #TSGF.SELF_FEATURE_DEFS do
    local def = TSGF.SELF_FEATURE_DEFS[i]
    FeatureMgr.AddFeature(
        def[1], def[2], eFeatureType.Toggle, def[3],
        function() UpdateSelfUsefulFeatures() end
    )
end

-- Automatically dismiss incoming/scripted phone calls.
FeatureMgr.AddFeature(
    TSGF.AUTO_REJECT_CALLS_HASH,
    "Auto Reject Phone Calls",
    eFeatureType.Toggle,
    "Automatically reject scripted/mission phone calls so they do not stay on the phone.",
    function()
        local active = SelfFeatureOn(TSGF.autoRejectCallsFeature)
        if not active then return end
        local callOngoing = SafeRead(function()
            return Natives.InvokeBool(0x7497D2CE2C30D24C)
        end, false)
        if callOngoing then
            pcall(function()
                Natives.InvokeVoid(0xD79DEEFB53455EBA, false)
            end)
        end
    end
)

TSGF.selfLockWeaponFeature = FeatureMgr.GetFeature(TSGF.SELF_LOCK_WEAPON_HASH)
TSGF.selfFireProofFeature = FeatureMgr.GetFeature(TSGF.SELF_FIRE_PROOF_HASH)
TSGF.selfCollisionProofFeature = FeatureMgr.GetFeature(TSGF.SELF_COLLISION_PROOF_HASH)
TSGF.selfMeleeProofFeature = FeatureMgr.GetFeature(TSGF.SELF_MELEE_PROOF_HASH)
TSGF.selfFastStunFeature = FeatureMgr.GetFeature(TSGF.SELF_FAST_STUN_HASH)
TSGF.autoRejectCallsFeature = FeatureMgr.GetFeature(TSGF.AUTO_REJECT_CALLS_HASH)

TSGF.selfLockWeaponFeature:SetSaveable(true)
TSGF.selfFireProofFeature:SetSaveable(true)
TSGF.selfCollisionProofFeature:SetSaveable(true)
TSGF.selfMeleeProofFeature:SetSaveable(true)
TSGF.selfFastStunFeature:SetSaveable(true)
TSGF.autoRejectCallsFeature:SetSaveable(false)

-- Apply the self utilities every tick so respawns/model changes are handled.
TSGF.selfTickFeatures = {
    TSGF.selfLockWeaponFeature,
    TSGF.selfFireProofFeature,
    TSGF.selfCollisionProofFeature,
    TSGF.selfMeleeProofFeature,
    TSGF.selfFastStunFeature,
}

for i = 1, #TSGF.selfTickFeatures do
    local feature = TSGF.selfTickFeatures[i]
    if feature then
        feature:RegisterCallbackTrigger(eCallbackTrigger.OnTick)
    end
end

TSGF.autoRejectCallsRuntime = FeatureMgr.GetFeature(TSGF.AUTO_REJECT_CALLS_HASH)
TSGF.autoRejectCallsRuntime:RegisterCallbackTrigger(eCallbackTrigger.OnTick)

-- Backward-compatible no-op aliases for old renderer references are deliberately
-- removed below; the Self tab now renders only real utilities.

local function DrawSelfFeatures()
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x + 18, y + 18, "SELF", 250, 250, 255, 255)
    ImGui.AddText(x + 18, y + 42, "Practical self utilities", 155, 155, 170, 255)

    local featureRows = {
        {TSGF.SELF_LOCK_WEAPON_HASH, "Lock Current Weapon"},
        {TSGF.SELF_FIRE_PROOF_HASH, "Fire Proof"},
        {TSGF.SELF_COLLISION_PROOF_HASH, "Collision Proof"},
        {TSGF.SELF_MELEE_PROOF_HASH, "Melee Proof"},
        {TSGF.SELF_FAST_STUN_HASH, "Fast Stun Recovery"},
    }

    local startY = y + 78
    local rowH = 36
    local colW = 310
    for i = 1, #featureRows do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        ImGui.SetCursorScreenPos(x + col * colW, startY + row * rowH)
        ClickGUI.RenderFeature(featureRows[i][1])
    end

    ImGui.AddText(x + 18, startY + math.ceil(#featureRows / 2) * rowH + 20,
        "Selective protections can be combined; they do not modify vehicle weapon flags.",
        145, 145, 160, 255)

    ImGui.SetCursorScreenPos(x, startY + math.ceil(#featureRows / 2) * rowH + 55)
end

-- =========================================================
-- OTHERS
-- V74: Auto Reject Phone Calls moved here from Self.

local function DrawOthersFeatures()
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x + 18, y + 18, "OTHERS", 250, 250, 255, 255)
    ImGui.AddText(x + 18, y + 42, "Useful player-related utilities", 155, 155, 170, 255)

    local startY = y + 78
    local rowH = 36
    local colW = 310
    ImGui.SetCursorScreenPos(x, startY)
    ClickGUI.RenderFeature(TSGF.AUTO_REJECT_CALLS_HASH)

    ImGui.AddText(x + 18, startY + rowH + 20,
        "Automatically rejects incoming/scripted phone calls.",
        145, 145, 160, 255)

    ImGui.SetCursorScreenPos(x, startY + rowH + 55)
end

local function DrawVehicleAnalyzer()
    -- Stable analyzer renderer: only uses simple, documented vehicle fields.
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x, y, "VEHICLE ANALYZER", 235, 235, 245, 255)
    ImGui.AddText(x, y + 23, "Live read-only vehicle diagnostics", 145, 145, 160, 255)

    local vehicle = SafeRead(function()
        return GTA.GetLocalVehicle()
    end, nil)

    if not vehicle then
        ImGui.AddText(x, y + 70, "No vehicle detected.", 255, 185, 70, 255)
        ImGui.AddText(x, y + 95, "Enter a vehicle to start the analyzer.", 155, 155, 170, 255)
        ImGui.SetCursorScreenPos(x, y + 130)
        return
    end

    local body = SafeRead(function() return vehicle.BodyHealth end, nil)
    local engine = SafeRead(function() return vehicle.packedEngineHealth end, nil)
    local petrol = SafeRead(function() return vehicle.PetrolTankHealth end, nil)
    local dirt = SafeRead(function() return vehicle.DirtLevel end, nil)
    local wrecked = SafeRead(function() return vehicle.isWrecked end, false)
    local blown = SafeRead(function() return vehicle.isBlownUp end, false)
    local wheels = SafeRead(function() return vehicle.numWheels end, nil)

    ImGui.AddText(x, y + 58, "CURRENT VEHICLE", 235, 235, 245, 255)
    ImGui.AddText(x, y + 82, "Body: " .. tostring(body or "N/A"), 190, 225, 200, 255)
    ImGui.AddText(x + 205, y + 82, "Engine: " .. tostring(engine or "N/A"), 190, 225, 200, 255)
    ImGui.AddText(x + 410, y + 82, "Tank: " .. tostring(petrol or "N/A"), 190, 225, 200, 255)

    ImGui.AddText(x, y + 125, "STATUS", 235, 235, 245, 255)
    local healthy = not wrecked and not blown
    ImGui.AddText(
        x, y + 149,
        healthy and "Vehicle status: HEALTHY" or "Vehicle status: DAMAGED / WRECKED",
        healthy and 75 or 255,
        healthy and 225 or 75,
        healthy and 135 or 90,
        255
    )

    ImGui.AddText(x + 300, y + 149, "Dirt: " .. tostring(dirt or "N/A"), 180, 180, 195, 255)
    ImGui.AddText(x + 465, y + 149, "Wheels: " .. tostring(wheels or "N/A"), 180, 180, 195, 255)

    ImGui.AddText(x, y + 195, "The analyzer is intentionally read-only.", 145, 145, 160, 255)
    ImGui.SetCursorScreenPos(x, y + 235)
end


-- =========================================================
-- VEHICLE GENERAL
-- Vehicle Damage Map
-- =========================================================
local VEHICLE_DAMAGE_MAP_HASH = Utils.Joaat("TestScript_VehicleDamageMap")

FeatureMgr.AddFeature(
    VEHICLE_DAMAGE_MAP_HASH,
    "Vehicle Damage Map",
    eFeatureType.Toggle,
    "Show a real-time top-down diagnostic map of the vehicle's available damage state."
)

local vehicleDamageMapFeature = FeatureMgr.GetFeature(VEHICLE_DAMAGE_MAP_HASH)
vehicleDamageMapFeature:SetSaveable(false)

local function ClampNumber(value, lo, hi)
    value = tonumber(value) or lo
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

local function HealthPercent(value, maximum)
    maximum = maximum or 1000.0
    if value == nil then return nil end
    local n = tonumber(value)
    if not n then return nil end
    return ClampNumber((n / maximum) * 100.0, 0, 100)
end

local function DamageColor(percent)
    -- Five condition bands, from pristine to critical:
    -- 100-90  = full green
    -- 89-75   = light green
    -- 74-50   = yellow
    -- 49-25   = orange
    -- 24-0    = red
    if percent == nil then
        return 155, 155, 170
    elseif percent >= 90 then
        return 55, 235, 95        -- FULL GREEN
    elseif percent >= 75 then
        return 135, 245, 105      -- LIGHT GREEN
    elseif percent >= 50 then
        return 255, 225, 55       -- YELLOW
    elseif percent >= 25 then
        return 255, 145, 35       -- ORANGE
    else
        return 255, 50, 65        -- RED
    end
end

-- GET_VEHICLE_DEFORMATION_AT_POS gives a local deformation vector for a
-- sampled point on the vehicle. It lets the map separate visible body zones
-- instead of painting the entire front from the global body-health value.
local DEFORMATION_NATIVE = 0x4EC6CFBC7B2E9536

local function DeformationMagnitude(handle, ox, oy, oz)
    if not handle then return nil end

    local ok, dx, dy, dz = pcall(function()
        return Natives.InvokeV3(DEFORMATION_NATIVE, handle, ox, oy, oz)
    end)

    if not ok or dx == nil or dy == nil or dz == nil then
        return nil
    end

    dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)
    if not dx or not dy or not dz then return nil end

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function SampleDeformation(handle, points)
    if not handle then return nil end

    local maxMagnitude = 0.0
    local found = false

    for _, point in ipairs(points) do
        local magnitude = DeformationMagnitude(
            handle, point[1], point[2], point[3]
        )
        if magnitude ~= nil then
            found = true
            if magnitude > maxMagnitude then
                maxMagnitude = magnitude
            end
        end
    end

    if not found then return nil end

    -- Approximate visual-damage scale: 0 deformation is 100% condition;
    -- around 0.60m displacement is treated as severe/critical damage.
    return ClampNumber(100.0 - (maxMagnitude / 0.60) * 100.0, 0, 100)
end

local function TyreColor(percent)
    -- GTA exposes tyre damage here as a burst state rather than a smooth
    -- health percentage. Keep healthy tyres green and burst tyres red.
    if percent == nil then
        return 155, 155, 170
    elseif percent <= 0 then
        return 255, 55, 70
    else
        return 70, 235, 105
    end
end

local function DamageLabel(percent)
    if percent == nil then return "N/A" end
    return string.format("%d%%", math.floor(percent + 0.5))
end

local function ReadTableBool(tbl, index)
    if not tbl then return false end
    local value = SafeRead(function() return tbl[index] end, false)
    return value == true
end

-- GTA's live tyre state is exposed reliably through the VEHICLE natives.
-- CVehicle's tyreDamaged/tyreDestroyed fields belong to the sync health
-- data node, not the live CVehicle wrapper, so reading them directly from
-- GTA.GetLocalVehicle() can silently return nil.
local function GetVehicleHandle(vehicle)
    if not vehicle then return nil end
    return SafeRead(function()
        return GTA.PointerToHandle(vehicle)
    end, nil)
end

local function NativeTyreBurst(handle, wheelIndex)
    if not handle then return nil end

    return SafeRead(function()
        -- Cherax exposes GTA natives through Natives.InvokeBool rather than
        -- a VEHICLE Lua namespace. Check both partial and complete burst states.
        return Natives.InvokeBool(0xBA291848A0815CA9, handle, wheelIndex, false)
            or Natives.InvokeBool(0xBA291848A0815CA9, handle, wheelIndex, true)
    end, nil)
end

local function TyrePercent(handle, wheelIndex)
    local burst = NativeTyreBurst(handle, wheelIndex)
    if burst == nil then return nil end
    return burst and 0 or 100
end

-- Real glass mapping from GTA's window slots.
-- 0/1 = front side windows, 2/3 = rear side windows,
-- 6 = windscreen, 7 = rear windscreen.
local VEHICLE_WINDOW_INTACT_NATIVE = 0x46E571A0E20D01F1

local function WindowPercent(handle, windowIndex)
    if not handle then return nil end
    local intact = SafeRead(function()
        return Natives.InvokeBool(VEHICLE_WINDOW_INTACT_NATIVE, handle, windowIndex)
    end, nil)
    if intact == nil then return nil end
    return intact and 100 or 0
end

local function RoofPercent(handle)
    -- GTA has no dedicated roof-health native. Sample several roof points
    -- and use the same deformation-to-condition scale as the body zones.
    return SampleDeformation(handle, {
        {-0.72, 0.15, 1.02}, {0.0, 0.15, 1.08}, {0.72, 0.15, 1.02},
        {-0.72, -0.65, 1.00}, {0.0, -0.65, 1.06}, {0.72, -0.65, 1.00}
    })
end

local function SuspensionPercent(vehicle, index)
    local health = SafeRead(function()
        local values = vehicle.suspensionHealth
        return values and values[index] or nil
    end, nil)
    return HealthPercent(health)
end

local function DrawDamageStatusDot(x, y, percent, radius)
    local r, g, b = DamageColor(percent)
    ImGui.AddCircleFilled(x, y, radius or 6, r, g, b, 255, 20)
end

local function DrawDamageRow(x, y, label, percent, width)
    width = width or 280
    local r, g, b = DamageColor(percent)
    DrawDamageStatusDot(x + 7, y + 9, percent, 6)
    ImGui.AddText(x + 20, y, label, 220, 220, 230, 255)
    ImGui.AddText(x + width - 52, y, DamageLabel(percent), r, g, b, 255)
end

local function DrawFlagRow(x, y, label, active, goodText, badText, width)
    width = width or 280
    local r, g, b = active and 255 or 70, active and 65 or 235, active and 80 or 105
    DrawDamageStatusDot(x + 7, y + 9, active and 0 or 100, 6)
    ImGui.AddText(x + 20, y, label, 220, 220, 230, 255)
    ImGui.AddText(x + width - 72, y, active and badText or goodText, r, g, b, 255)
end

local function DrawMapWheel(x, y, w, h, percent)
    local r, g, b = TyreColor(percent)
    ImGui.AddRectFilled(x, y, x + w, y + h, r, g, b, 255, 14.0, 0)
    ImGui.AddRect(x, y, x + w, y + h, 20, 20, 25, 255, 14.0, 0, 1.0)
end

-- =========================================================
-- ADAPTIVE VEHICLE TYPE DETECTION / MAPS
-- =========================================================
-- GTA vehicle classes: 8 = Motorcycles, 13 = Cycles.
-- Wheel count is also checked so trikes/custom vehicles can use a
-- three-wheel layout instead of being forced into the four-wheel map.
-- Use the already-exposed CVehicle wheel count instead of the raw native
-- handler.  The raw wheel-count native reports a missing native handler on
-- the current Cherax Enhanced build, which was preventing the HUD from drawing.
local function DetectVehicleMapType(handle, vehicle)
    local wheels = SafeRead(function()
        return vehicle and vehicle.numWheels
    end, nil)

    if wheels == 2 then
        return "2W", wheels, nil
    end

    if wheels == 3 then
        return "3W", wheels, nil
    end

    return "4W", wheels, nil
end

local function DrawAdaptiveWheel(x, y, w, h, percent, roundness)
    local r, g, b = TyreColor(percent)
    ImGui.AddRectFilled(x, y, x + w, y + h, r, g, b, 255, roundness or 10.0, 0)
    ImGui.AddRect(x, y, x + w, y + h, 215, 220, 230, 190, roundness or 10.0, 0, 2.0)
end

local function DrawTwoWheelerSchematic(x, y, w, h, state)
    -- Compact motorcycle diagnostic silhouette.  It is intentionally built
    -- from simple ImGui primitives so it remains reliable in Cherax while
    -- looking like an actual motorcycle rather than a vertical stick.
    local cx = x + w * 0.43
    local top = y + 52
    local bottom = y + h - 52
    local wheelW, wheelH = 34, 70
    local frontY = top + 10
    local rearY = bottom - wheelH - 10

    ImGui.AddText(cx - 25, y + 9, "FRONT", 185, 185, 200, 255)

    -- Wheels: narrow tyres with a dark translucent centre and a live damage
    -- ring.  The centre is deliberately transparent enough to show the game.
    local function BikeWheel(wx, wy, percent)
        local r, g, b = TyreColor(percent)
        ImGui.AddRectFilled(wx, wy, wx + wheelW, wy + wheelH, 18, 20, 25, 85, 15.0, 0)
        ImGui.AddRect(wx, wy, wx + wheelW, wy + wheelH, r, g, b, 255, 15.0, 0, 4.0)
        ImGui.AddLine(wx + 9, wy + 10, wx + 9, wy + wheelH - 10, r, g, b, 180, 3.0)
        ImGui.AddLine(wx + wheelW - 9, wy + 10, wx + wheelW - 9, wy + wheelH - 10, r, g, b, 180, 3.0)
    end

    BikeWheel(cx - wheelW / 2, frontY, state.frontTyre)
    BikeWheel(cx - wheelW / 2, rearY, state.rearTyre)

    -- Front mudguard / fork crown.
    local frR, frG, frB = DamageColor(state.frontDamage)
    ImGui.AddRectFilled(cx - 27, frontY + wheelH - 8, cx + 27, frontY + wheelH + 5, frR, frG, frB, 235, 6.0, 0)
    ImGui.AddRect(cx - 27, frontY + wheelH - 8, cx + 27, frontY + wheelH + 5, 225, 225, 235, 150, 6.0, 0, 1.0)

    -- Fork legs.
    local forkR, forkG, forkB = DamageColor(state.frontFork)
    ImGui.AddLine(cx - 10, frontY + wheelH - 3, cx - 30, top + 145, forkR, forkG, forkB, 255, 5.0)
    ImGui.AddLine(cx + 10, frontY + wheelH - 3, cx + 30, top + 145, forkR, forkG, forkB, 255, 5.0)

    -- Handlebar, grips and mirrors.
    ImGui.AddLine(cx - 30, top + 145, cx - 67, top + 126, 205, 210, 220, 220, 3.0)
    ImGui.AddLine(cx + 30, top + 145, cx + 67, top + 126, 205, 210, 220, 220, 3.0)
    ImGui.AddLine(cx - 67, top + 126, cx - 79, top + 132, 205, 210, 220, 220, 3.0)
    ImGui.AddLine(cx + 67, top + 126, cx + 79, top + 132, 205, 210, 220, 220, 3.0)
    ImGui.AddCircle(cx - 86, top + 127, 10, 190, 195, 205, 210, 20, 2.0)
    ImGui.AddCircle(cx + 86, top + 127, 10, 190, 195, 205, 210, 20, 2.0)

    -- Fuel tank: a wider, tapered-looking block built from two triangles and
    -- a subtle fill, rather than the old generic rectangle.
    local tr, tg, tb = DamageColor(state.tank)
    local tankTop = top + 168
    local tankBot = top + 244
    ImGui.AddTriangleFilled(cx, tankTop - 8, cx - 48, tankTop + 20, cx + 48, tankTop + 20, tr, tg, tb, 220)
    ImGui.AddRectFilled(cx - 48, tankTop + 18, cx + 48, tankBot - 18, tr, tg, tb, 205, 13.0, 0)
    ImGui.AddTriangleFilled(cx - 48, tankBot - 19, cx, tankBot + 7, cx + 48, tankBot - 19, tr, tg, tb, 205)
    ImGui.AddLine(cx - 48, tankTop + 20, cx - 31, tankBot - 20, 225, 225, 235, 150, 2.0)
    ImGui.AddLine(cx + 48, tankTop + 20, cx + 31, tankBot - 20, 225, 225, 235, 150, 2.0)
    ImGui.AddText(cx - 18, tankTop + 49, "TANK", 15, 15, 20, 255)

    -- Frame / seat spine.
    local bodyR, bodyG, bodyB = DamageColor(state.body)
    ImGui.AddLine(cx - 31, tankBot - 5, cx - 23, bottom - 168, bodyR, bodyG, bodyB, 240, 5.0)
    ImGui.AddLine(cx + 31, tankBot - 5, cx + 23, bottom - 168, bodyR, bodyG, bodyB, 240, 5.0)

    -- Engine casing: a low, compact motorcycle engine rather than a giant box.
    local er, eg, eb = DamageColor(state.engine)
    local engTop = tankBot + 14
    local engBot = engTop + 72
    ImGui.AddRectFilled(cx - 39, engTop, cx + 39, engBot, er, eg, eb, 220, 20.0, 0)
    ImGui.AddRect(cx - 39, engTop, cx + 39, engBot, 225, 225, 235, 170, 20.0, 0, 2.0)
    ImGui.AddLine(cx - 24, engTop + 18, cx + 24, engTop + 18, 25, 25, 30, 100, 2.0)
    ImGui.AddText(cx - 25, engTop + 29, "ENGINE", 15, 15, 20, 255)

    -- Rear frame / swingarm and suspension.
    local sr, sg, sb = DamageColor(state.rearSusp)
    ImGui.AddLine(cx - 28, engBot - 2, cx - 16, rearY + 8, sr, sg, sb, 255, 6.0)
    ImGui.AddLine(cx + 28, engBot - 2, cx + 16, rearY + 8, sr, sg, sb, 255, 6.0)
    ImGui.AddLine(cx - 16, rearY + 8, cx + 16, rearY + 8, sr, sg, sb, 220, 4.0)

    -- Rear fender / damage zone.
    local rrR, rrG, rrB = DamageColor(state.rearDamage)
    ImGui.AddRectFilled(cx - 29, rearY - 7, cx + 29, rearY + 5, rrR, rrG, rrB, 235, 6.0, 0)
    ImGui.AddRect(cx - 29, rearY - 7, cx + 29, rearY + 5, 225, 225, 235, 150, 6.0, 0, 1.0)

    ImGui.AddText(cx - 22, bottom + 8, "REAR", 185, 185, 200, 255)
end

local function DrawThreeWheelerSchematic(x, y, w, h, state)
    -- Generic trike/ATV-style three-wheel diagnostic silhouette.  The actual
    -- GTA models vary, so the diagram stays schematic instead of claiming a
    -- model-specific wheel arrangement.
    local cx = x + w * 0.43
    local top = y + 52
    local bottom = y + h - 52
    local wheelW, wheelH = 34, 68

    ImGui.AddText(cx - 25, y + 9, "FRONT", 185, 185, 200, 255)

    local frontY = top + 28
    local leftX = cx - 78
    local rightX = cx + 44
    local rearX = cx - wheelW / 2
    local rearY = bottom - wheelH - 10

    DrawAdaptiveWheel(leftX, frontY, wheelW, wheelH, state.frontLeftTyre, 13.0)
    DrawAdaptiveWheel(rightX, frontY, wheelW, wheelH, state.frontRightTyre, 13.0)
    DrawAdaptiveWheel(rearX, rearY, wheelW, wheelH, state.rearTyre, 13.0)

    -- Wide front axle / bumper.
    local fbr, fbg, fbb = DamageColor(state.frontDamage)
    ImGui.AddLine(cx - 83, frontY + wheelH + 12, cx + 83, frontY + wheelH + 12, fbr, fbg, fbb, 255, 9.0)
    ImGui.AddLine(cx - 67, frontY + wheelH + 12, cx - 39, top + 170, fbr, fbg, fbb, 200, 4.0)
    ImGui.AddLine(cx + 67, frontY + wheelH + 12, cx + 39, top + 170, fbr, fbg, fbb, 200, 4.0)

    -- Main chassis outline.
    local bodyR, bodyG, bodyB = DamageColor(state.body)
    ImGui.AddLine(cx - 45, top + 155, cx - 63, bottom - 112, bodyR, bodyG, bodyB, 240, 6.0)
    ImGui.AddLine(cx + 45, top + 155, cx + 63, bottom - 112, bodyR, bodyG, bodyB, 240, 6.0)
    ImGui.AddLine(cx - 63, bottom - 112, cx - 14, rearY + 4, bodyR, bodyG, bodyB, 240, 6.0)
    ImGui.AddLine(cx + 63, bottom - 112, cx + 14, rearY + 4, bodyR, bodyG, bodyB, 240, 6.0)

    -- Central engine and tank.
    local er, eg, eb = DamageColor(state.engine)
    ImGui.AddRectFilled(cx - 43, top + 177, cx + 43, top + 245, er, eg, eb, 220, 20.0, 0)
    ImGui.AddRect(cx - 43, top + 177, cx + 43, top + 245, 225, 225, 235, 170, 20.0, 0, 2.0)
    ImGui.AddText(cx - 25, top + 202, "ENGINE", 15, 15, 20, 255)

    local tr, tg, tb = DamageColor(state.tank)
    ImGui.AddRectFilled(cx - 35, top + 260, cx + 35, top + 306, tr, tg, tb, 220, 18.0, 0)
    ImGui.AddText(cx - 19, top + 275, "TANK", 15, 15, 20, 255)

    -- Rear damage bar / suspension link.
    local rrR, rrG, rrB = DamageColor(state.rearDamage)
    ImGui.AddLine(cx - 34, rearY - 7, cx + 34, rearY - 7, rrR, rrG, rrB, 255, 9.0)
    local sr, sg, sb = DamageColor(state.rearSusp)
    ImGui.AddLine(cx - 20, top + 318, cx - 13, rearY + 5, sr, sg, sb, 255, 6.0)
    ImGui.AddLine(cx + 20, top + 318, cx + 13, rearY + 5, sr, sg, sb, 255, 6.0)

    ImGui.AddText(cx - 22, bottom + 8, "REAR", 185, 185, 200, 255)
end

local function DrawVehicleSchematic(x, y, w, h, state, showHeader)
    -- =====================================================
    -- REFERENCE-ACCURATE 4-WHEEL DAMAGE MAP
    -- Built around the supplied reference: thin technical body,
    -- curved bumper shells, detailed radiator/engine, four wheels,
    -- four long side doors, brake/caliper pieces, axle bars,
    -- central prop shaft and a dedicated fuel-tank icon.
    -- =====================================================
    local cx = x + w * 0.50
    local top = y + 18

    local scale = math.min((w - 34) / 250, (h - 54) / 500)
    local mw, mh = 250 * scale, 500 * scale
    local mx = cx - mw * 0.5
    local my = top + 38

    local function S(v) return v * scale end
    local function X(v) return mx + S(v) end
    local function Y(v) return my + S(v) end
    local function C(percent) return DamageColor(percent) end

    local function Line(x1,y1,x2,y2,percent,alpha,thickness)
        local r,g,b=C(percent)
        ImGui.AddLine(x1,y1,x2,y2,r,g,b,alpha or 255,thickness or S(2))
    end
    local function DarkLine(x1,y1,x2,y2,alpha,thickness)
        ImGui.AddLine(x1,y1,x2,y2,35,35,42,alpha or 255,thickness or S(1.5))
    end
    local function Rect(x1,y1,x2,y2,percent,alpha,radius,thickness)
        local r,g,b=C(percent)
        ImGui.AddRectFilled(x1,y1,x2,y2,r,g,b,alpha or 255,radius or S(2),0)
        if thickness and thickness > 0 then
            ImGui.AddRect(x1,y1,x2,y2,35,35,42,235,radius or S(2),0,thickness)
        end
    end
    local function NeutralRect(x1,y1,x2,y2,r,g,b,alpha,radius,thickness)
        ImGui.AddRectFilled(x1,y1,x2,y2,r,g,b,alpha or 255,radius or 0,0)
        if thickness and thickness > 0 then
            ImGui.AddRect(x1,y1,x2,y2,35,35,42,230,radius or 0,0,thickness)
        end
    end
    local function Circle(x,y,r,percent,alpha)
        local rr,gg,bb=C(percent)
        ImGui.AddCircleFilled(x,y,r,rr,gg,bb,alpha or 255,24)
    end
    local function Arc(cx0,cy0,rx,ry,a0,a1,percent,thickness)
        local steps=24
        local px,py=nil,nil
        for i=0,steps do
            local a=math.rad(a0+(a1-a0)*(i/steps))
            local qx=cx0+math.cos(a)*rx
            local qy=cy0+math.sin(a)*ry
            if px then Line(px,py,qx,qy,percent,255,thickness) end
            px,py=qx,qy
        end
    end

    -- Optional header plate. The in-game HUD overlay hides this so only the
    -- transparent diagnostic schematic floats over the game world.
    if showHeader ~= false then
        NeutralRect(cx-S(122),top,cx+S(122),top+S(30),82,82,82,255,0,0)
        local engineBroken = state.engine ~= nil and state.engine <= 0
        local header = engineBroken and "Main Engine Broken" or "Main Engine OK"
        local headerW = engineBroken and 116 or 82
        ImGui.AddText(cx-S(headerW),top+S(5),header,245,245,245,255)
    end

    -- =====================================================
    -- BODY / BUMPERS
    -- =====================================================
    -- The reference uses a very narrow outer body, not a solid car silhouette.
    -- Two layered arcs create the thick curved bumper shells.
    Arc(X(125),Y(73),S(98),S(58),205,335,state.frontBumper,S(8))
    Arc(X(125),Y(73),S(98),S(58),205,335,100,S(2))
    Arc(X(125),Y(427),S(98),S(58),25,155,state.rearBumper,S(8))
    Arc(X(125),Y(427),S(98),S(58),25,155,100,S(2))

    -- Outer side rails.  These follow the reference's long, almost straight doors.
    Line(X(48),Y(160),X(48),Y(382),state.body,255,S(5))
    Line(X(202),Y(160),X(202),Y(382),state.body,255,S(5))
    -- Small inward upper/lower transitions.
    Line(X(48),Y(160),X(62),Y(153),state.body,255,S(3))
    Line(X(202),Y(160),X(188),Y(153),state.body,255,S(3))
    Line(X(48),Y(382),X(62),Y(390),state.body,255,S(3))
    Line(X(202),Y(382),X(188),Y(390),state.body,255,S(3))

    -- Door / side-panel projections in the middle, deliberately asymmetric like the source.
    local dr,dg,db=C(state.body)
    ImGui.AddTriangleFilled(X(48),Y(215),X(18),Y(227),X(48),Y(232),dr,dg,db,235)
    ImGui.AddTriangleFilled(X(202),Y(215),X(232),Y(227),X(202),Y(232),dr,dg,db,235)
    DarkLine(X(48),Y(232),X(48),Y(382),170,S(1))
    DarkLine(X(202),Y(232),X(202),Y(382),170,S(1))

    -- =====================================================
    -- WHEELS
    -- =====================================================
    -- Four clean green/condition blocks with a dark inset, as in the reference.
    local wheelW,wheelH=S(34),S(80)
    local function Wheel(wx,wy,percent)
        local r,g,b=TyreColor(percent)
        ImGui.AddRectFilled(wx,wy,wx+wheelW,wy+wheelH,r,g,b,255,S(6),0)
        ImGui.AddRect(wx,wy,wx+wheelW,wy+wheelH,35,35,42,235,S(6),0,S(1.5))
        ImGui.AddRectFilled(wx+S(7),wy+S(8),wx+wheelW-S(7),wy+wheelH-S(8),25,25,30,55,S(3),0)
    end
    Wheel(X(20),Y(106),state.flTyre)
    Wheel(X(196),Y(106),state.frTyre)
    Wheel(X(20),Y(366),state.rlTyre)
    Wheel(X(196),Y(366),state.rrTyre)

    -- Brake/caliper uprights immediately inboard of each wheel.
    local function Brake(yPos,left,right)
        Rect(X(56),yPos-S(11),X(63),yPos+S(11),left,255,S(1),0)
        Rect(X(187),yPos-S(11),X(194),yPos+S(11),right,255,S(1),0)
        -- Short axle ends.
        Line(X(63),yPos,X(76),yPos,left,255,S(4))
        Line(X(174),yPos,X(187),yPos,right,255,S(4))
    end
    Brake(Y(145),state.flSusp,state.frSusp)
    Brake(Y(405),state.rlSusp,state.rrSusp)

    -- =====================================================
    -- AXLES + CENTRAL DRIVESHAFT
    -- =====================================================
    -- Reference has two separated horizontal axle bars at each end.
    Line(X(72),Y(145),X(104),Y(145),state.flSusp,255,S(5))
    Line(X(146),Y(145),X(178),Y(145),state.frSusp,255,S(5))
    Line(X(72),Y(405),X(104),Y(405),state.rlSusp,255,S(5))
    Line(X(146),Y(405),X(178),Y(405),state.rrSusp,255,S(5))
    -- Dark axle cores give the reference's mechanical look.
    DarkLine(X(76),Y(145),X(101),Y(145),190,S(1.2))
    DarkLine(X(149),Y(145),X(174),Y(145),190,S(1.2))
    DarkLine(X(76),Y(405),X(101),Y(405),190,S(1.2))
    DarkLine(X(149),Y(405),X(174),Y(405),190,S(1.2))

    -- Long central prop shaft: reference shows a narrow red mechanical spine.
    Line(X(125),Y(151),X(125),Y(405),state.body,255,S(5))
    Circle(X(125),Y(151),S(8),state.body,255)
    Circle(X(125),Y(405),S(8),state.body,255)
    -- Shaft is visually attached to both axle centres.
    Line(X(125),Y(151),X(125),Y(405),state.body,255,S(2))

    -- =====================================================
    -- RADIATOR
    -- =====================================================
    -- Dedicated radiator at the very front of the engine bay.
    local rr,rg,rb=C(state.engine)
    Rect(X(94),Y(60),X(156),Y(88),state.engine,255,S(4),S(1.5))
    -- Dark radiator face.
    NeutralRect(X(101),Y(66),X(149),Y(82),38,38,44,235,S(2),S(1))
    -- Radiator fins: many short vertical ribs, plus top/bottom rails.
    for i=0,7 do
        local fx=105+i*5.5
        Line(X(fx),Y(69),X(fx),Y(79),state.engine,255,S(1.6))
    end
    Line(X(103),Y(68),X(147),Y(68),state.engine,255,S(1.6))
    Line(X(103),Y(80),X(147),Y(80),state.engine,255,S(1.6))
    -- Radiator hoses / side brackets.
    Line(X(91),Y(72),X(96),Y(72),state.engine,255,S(3))
    Line(X(154),Y(72),X(159),Y(72),state.engine,255,S(3))

    -- =====================================================
    -- ENGINE
    -- =====================================================
    -- Recreate the reference engine icon rather than using a generic rounded card.
    Rect(X(103),Y(93),X(147),Y(137),state.engine,255,S(2),S(1))
    Rect(X(94),Y(104),X(156),Y(128),state.engine,255,S(2),S(1))
    Rect(X(108),Y(87),X(142),Y(99),state.engine,255,S(1),S(1))
    Rect(X(112),Y(78),X(138),Y(91),state.engine,255,S(1),S(1))
    -- Characteristic crank/exhaust bulge on the right.
    Circle(X(148),Y(116),S(12),state.engine,255)
    Rect(X(145),Y(107),X(158),Y(126),state.engine,255,S(1),S(1))
    -- Left side mechanical block.
    Rect(X(91),Y(106),X(103),Y(127),state.engine,255,S(1),S(1))
    -- Engine mounting necks.
    Rect(X(116),Y(91),X(134),Y(101),state.engine,255,S(1),0)
    Rect(X(116),Y(137),X(134),Y(151),state.engine,255,S(1),0)
    -- Dark detail cuts make the engine read as a mechanical icon.
    DarkLine(X(108),Y(112),X(142),Y(112),180,S(1.2))
    DarkLine(X(108),Y(121),X(138),Y(121),150,S(1.2))
    -- Coupling at the driveshaft.
    Circle(X(125),Y(151),S(7),state.engine,255)

    -- =====================================================
    -- FUEL TANK
    -- =====================================================
    -- Reference uses a compact green tank with a simple outlined filler/handle icon.
    Rect(X(98),Y(429),X(152),Y(477),state.tank,255,S(5),S(1.5))
    local tr,tg,tb=C(state.tank)
    -- Inner tank icon: cap/neck + tank body + two lower feet.
    Line(X(111),Y(441),X(139),Y(441),state.tank,255,S(2))
    Line(X(111),Y(441),X(111),Y(456),state.tank,255,S(2))
    Line(X(139),Y(441),X(139),Y(456),state.tank,255,S(2))
    Line(X(111),Y(456),X(139),Y(456),state.tank,255,S(2))
    Line(X(115),Y(456),X(125),Y(466),state.tank,255,S(2))
    Line(X(135),Y(456),X(125),Y(466),state.tank,255,S(2))
    Line(X(116),Y(441),X(116),Y(437),state.tank,255,S(2))
    Line(X(134),Y(441),X(134),Y(437),state.tank,255,S(2))
    Circle(X(108),Y(468),S(3),state.tank,255)
    Circle(X(142),Y(468),S(3),state.tank,255)

    -- Small rear tank coupling into the shaft.
    Circle(X(125),Y(405),S(7),state.tank,255)
end

local function BuildVehicleDamageState(vehicle, handle)
    if not vehicle or not handle then return nil end

    local bodyHealth = SafeRead(function()
        return Natives.InvokeFloat(0xF271147EB7B40F12, handle)
    end, nil)
    if bodyHealth == nil then
        bodyHealth = SafeRead(function() return vehicle.BodyHealth end, nil)
    end

    local engineHealth = SafeRead(function()
        return Natives.InvokeFloat(0xC45D23BAF168AAB8, handle)
    end, nil)

    local tankHealth = SafeRead(function()
        return Natives.InvokeFloat(0x7D5DABE888D2D074, handle)
    end, nil)
    if tankHealth == nil then
        tankHealth = SafeRead(function() return vehicle.PetrolTankHealth end, nil)
    end

    local state = {
        body = HealthPercent(bodyHealth),
        engine = HealthPercent(engineHealth),
        tank = HealthPercent(tankHealth),
        frontBumper = SampleDeformation(handle, {
            {-1.0, 3.0, 0.15}, {0.0, 3.0, 0.15}, {1.0, 3.0, 0.15}
        }),
        hood = SampleDeformation(handle, {
            {-0.8, 1.55, 0.75}, {0.0, 1.55, 0.85}, {0.8, 1.55, 0.75}
        }),
        rearBumper = SampleDeformation(handle, {
            {-1.0, -3.0, 0.15}, {0.0, -3.0, 0.15}, {1.0, -3.0, 0.15}
        }),
        flSusp = SuspensionPercent(vehicle, 0),
        frSusp = SuspensionPercent(vehicle, 1),
        rlSusp = SuspensionPercent(vehicle, 4),
        rrSusp = SuspensionPercent(vehicle, 5),
        flTyre = TyrePercent(handle, 0),
        frTyre = TyrePercent(handle, 1),
        rlTyre = TyrePercent(handle, 4),
        rrTyre = TyrePercent(handle, 5),
        frontLeftWindow = WindowPercent(handle, 0),
        frontRightWindow = WindowPercent(handle, 1),
        rearLeftWindow = WindowPercent(handle, 2),
        rearRightWindow = WindowPercent(handle, 3),
        windshield = WindowPercent(handle, 6),
        backglass = WindowPercent(handle, 7),
        roof = RoofPercent(handle),
        lightsBroken = SafeRead(function() return vehicle.hasLightsBroken end, false),
        windowsBroken = SafeRead(function() return vehicle.hasWindowsBroken end, false),
        deformation = SafeRead(function() return vehicle.hasDeformationDamage end, false)
    }

    state.frontTyre = TyrePercent(handle, 0)
    state.rearTyre = TyrePercent(handle, 4)
    state.frontFork = state.flSusp
    state.rearSusp = state.rlSusp or state.rrSusp
    state.frontDamage = state.frontBumper
    state.rearDamage = state.rearBumper
    state.frontLeftTyre = state.flTyre
    state.frontRightTyre = state.frTyre
    state.rearTyre3 = state.rrTyre or state.rlTyre
    return state
end

local function DrawVehicleDamageMap()
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x, y, "VEHICLE DAMAGE MAP", 240, 240, 250, 255)
    ImGui.AddText(x, y + 23, "Real-time component condition • read-only", 150, 150, 170, 255)

    ImGui.SetCursorScreenPos(x, y + 55)
    ClickGUI.RenderFeature(VEHICLE_DAMAGE_MAP_HASH)

    if not SafeFeatureToggled(vehicleDamageMapFeature) then
        ImGui.AddText(x, y + 105, "Enable Vehicle Damage Map to inspect the current vehicle.", 155, 155, 170, 255)
        ImGui.SetCursorScreenPos(x, y + 145)
        return
    end

    local vehicle = SafeRead(function() return GTA.GetLocalVehicle() end, nil)
    if not vehicle then
        ImGui.AddText(x, y + 105, "NO VEHICLE DETECTED", 255, 205, 55, 255)
        ImGui.AddText(x, y + 130, "Enter a vehicle to populate the diagnostic map.", 155, 155, 170, 255)
        ImGui.SetCursorScreenPos(x, y + 170)
        return
    end

    local handle = GetVehicleHandle(vehicle)
    local mapType, wheelCount, vehicleClass = DetectVehicleMapType(handle, vehicle)

    local state = BuildVehicleDamageState(vehicle, handle)
    if not state then
        ImGui.AddText(x, y + 105, "Unable to read vehicle damage state.", 255, 205, 55, 255)
        ImGui.SetCursorScreenPos(x, y + 145)
        return
    end

    local mapX = x
    local mapY = y + 100
    local mapW = 330
    local mapH = 540
    local panelX = mapX + mapW + 18
    local panelW = 295

    if mapType == "2W" then
        DrawTwoWheelerSchematic(mapX, mapY, mapW, mapH, state)
    elseif mapType == "3W" then
        state.rearTyre = state.rearTyre3
        DrawThreeWheelerSchematic(mapX, mapY, mapW, mapH, state)
    else
        DrawVehicleSchematic(mapX, mapY, mapW, mapH, state)
    end

    -- Transparent status canvas: no black fill over the game world.
    -- Transparent status panel: only the outline is drawn.
    ImGui.AddRect(panelX, mapY, panelX + panelW, mapY + mapH, 80, 35, 135, 150, 16.0, 0, 1.0)
    local typeLabel = mapType == "2W" and "2-WHEELER" or (mapType == "3W" and "3-WHEELER" or "4-WHEELER")
    ImGui.AddText(panelX + 18, mapY + 16, "COMPONENT STATUS", 190, 190, 205, 255)
    ImGui.AddText(panelX + panelW - 98, mapY + 17, typeLabel, 155, 155, 170, 255)
    ImGui.AddLine(panelX + 18, mapY + 45, panelX + panelW - 18, mapY + 45, 80, 35, 135, 180, 1.0)

    local rowY = mapY + 62
    local gap = 26

    if mapType == "2W" then
        DrawDamageRow(panelX + 18, rowY, "Engine", state.engine, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Body", state.body, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Fork", state.frontFork, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Suspension", state.rearSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Tyre", state.frontTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Tyre", state.rearTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Petrol Tank", state.tank, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Damage", state.frontDamage, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Damage", state.rearDamage, panelW - 36)
    elseif mapType == "3W" then
        DrawDamageRow(panelX + 18, rowY, "Engine", state.engine, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Body", state.body, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Bumper", state.frontBumper, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Bumper", state.rearBumper, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Left Tyre", state.frontLeftTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Right Tyre", state.frontRightTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Tyre", state.rearTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Suspension", state.rearSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Petrol Tank", state.tank, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Damage", state.frontDamage, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Damage", state.rearDamage, panelW - 36)
    else
        DrawDamageRow(panelX + 18, rowY, "Engine", state.engine, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Body", state.body, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Bumper", state.frontBumper, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Hood", state.hood, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Bumper", state.rearBumper, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Petrol Tank", state.tank, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Left Suspension", state.flSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Right Suspension", state.frSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Left Suspension", state.rlSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Right Suspension", state.rrSusp, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Left Tyre", state.flTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Front Right Tyre", state.frTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Left Tyre", state.rlTyre, panelW - 36); rowY = rowY + gap
        DrawDamageRow(panelX + 18, rowY, "Rear Right Tyre", state.rrTyre, panelW - 36)
    end

    -- Start flags after the final component row so every vehicle layout
    -- gets the same clean spacing and nothing can collide.
    local flagsY = math.min(mapY + mapH - 112, math.max(mapY + 330, rowY + 32))
    ImGui.AddText(panelX + 18, flagsY, "STATUS FLAGS", 190, 190, 205, 255)
    ImGui.AddLine(panelX + 18, flagsY + 22, panelX + panelW - 18, flagsY + 22, 80, 35, 135, 150, 1.0)
    DrawFlagRow(panelX + 18, flagsY + 34, "Lights", state.lightsBroken, "OK", "BROKEN", panelW - 36)
    DrawFlagRow(panelX + 18, flagsY + 60, "Windows", state.windowsBroken, "OK", "BROKEN", panelW - 36)
    DrawFlagRow(panelX + 18, flagsY + 86, "Deformation", state.deformation, "NONE", "DEFORMED", panelW - 36)

    local wheelText = wheelCount and tostring(wheelCount) or "?"
    local classText = vehicleClass and tostring(vehicleClass) or "?"
    ImGui.AddText(x, mapY + mapH + 16, "Detected: " .. typeLabel .. "  •  Wheels: " .. wheelText .. "  •  Class: " .. classText, 145, 145, 160, 255)
    ImGui.AddText(x, mapY + mapH + 38, "Values update live. N/A means GTA does not expose that component for this vehicle.", 145, 145, 160, 255)
    ImGui.SetCursorScreenPos(x, mapY + mapH + 70)
end


-- =========================================================
-- Theme page / How-to page
-- =========================================================
-- These functions are intentionally defined in this version. Earlier
-- cleanup accidentally left the tab calling old V25* function names that
-- no longer existed, which caused the Lua tab coroutine to die immediately.

local function DrawThemeGallery()
    local x, y = ImGui.GetCursorScreenPos()

    -- Keep the intro harmless: it only draws; it never changes the GUI.
    DrawIntro()

    ImGui.SetCursorScreenPos(x, y)
    DrawSectionHeader(
        "THEMES",
        "Browse installed Cherax themes and choose your default"
    )

    DrawCards()

    local _, cardsBottom = ImGui.GetCursorScreenPos()
    ImGui.SetCursorScreenPos(x, cardsBottom + 12)

    ClickGUI.RenderFeature(THEME_HASH)
    ImGui.SetCursorScreenPos(x, cardsBottom + 52)
    ClickGUI.RenderFeature(DEFAULT_HASH)
    ImGui.SetCursorScreenPos(x, cardsBottom + 92)
    ClickGUI.RenderFeature(APPLY_HASH)
    ImGui.SetCursorScreenPos(x, cardsBottom + 132)
    ClickGUI.RenderFeature(REFRESH_HASH)

    ImGui.SetCursorScreenPos(x, cardsBottom + 175)
end

local function DrawHowToUse()
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x, y, "HOW TO USE", 250, 250, 255, 255)
    ImGui.AddText(x, y + 30, "Quick guide to every part of X Script.", 155, 155, 170, 255)

    -- THEME
    ImGui.AddText(x, y + 70, "THEME", 190, 0, 255, 255)
    ImGui.AddText(x + 20, y + 98, "1. Open Theme and select the Cherax theme you want.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 124, "2. Enable Use Selected Theme as Default if you want to keep that choice.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 150, "3. Use Apply Selected Theme to load it safely.", 235, 235, 240, 255)

    -- VEHICLE
    ImGui.AddText(x, y + 188, "VEHICLE", 190, 0, 255, 255)
    ImGui.AddText(x + 20, y + 216, "1. Analyzer shows live basic information about your current vehicle.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 242, "2. Damage Map gives a live component-by-component condition view.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 268, "3. General contains the vehicle utilities and adjustable power, speed and headlights.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 294, "4. Enter a vehicle first when using vehicle-specific features.", 235, 235, 240, 255)

    -- SELF
    ImGui.AddText(x, y + 332, "SELF", 190, 0, 255, 255)
    ImGui.AddText(x + 20, y + 360, "1. Use these for selective personal utilities such as weapon lock and individual protections.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 386, "2. Turn each option on or off independently; they do not require full god mode.", 235, 235, 240, 255)

    -- OTHERS
    ImGui.AddText(x, y + 424, "OTHERS", 190, 0, 255, 255)
    ImGui.AddText(x + 20, y + 452, "1. Use this tab for player-related utilities.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 478, "2. Enable Auto Reject Phone Calls to automatically dismiss incoming/scripted calls.", 235, 235, 240, 255)

    -- GENERAL
    ImGui.AddText(x, y + 516, "GENERAL", 190, 0, 255, 255)
    ImGui.AddText(x + 20, y + 544, "1. Keep Auto Start enabled in Settings > Subscribed Scripts so X Script starts automatically.", 235, 235, 240, 255)
    ImGui.AddText(x + 20, y + 570, "2. Features update live while the script is running. Disable a feature when you no longer need it.", 235, 235, 240, 255)

    ImGui.SetCursorScreenPos(x, y + 610)
end


local function DrawAbout()
    local x, y = ImGui.GetCursorScreenPos()

    ImGui.AddText(x, y, "X SCRIPT", 255, 255, 255, 255)
    ImGui.AddText(x, y + 38, "Author/Lua Dev:", 255, 255, 255, 255)
    ImGui.AddText(x + 126, y + 38, "GODX7PRIME", 255, 215, 0, 255)

    ImGui.AddText(x, y + 88, "VERSION", 190, 0, 255, 255)
    ImGui.AddText(x + 28, y + 120, "Test Version", 165, 165, 180, 255)
    ImGui.AddText(x + 190, y + 120, "94.7", 255, 255, 255, 255)
    ImGui.AddText(x + 28, y + 148, "Public Version", 165, 165, 180, 255)
    ImGui.AddText(x + 190, y + 148, "1", 255, 255, 255, 255)

    ImGui.AddText(x, y + 196, "PROJECT", 190, 0, 255, 255)
    ImGui.AddText(x + 28, y + 228, "Built for Cherax with a focus on practical features and a clean interface.", 235, 235, 240, 255)
    ImGui.AddText(x + 28, y + 254, "Vehicle weapons are intentionally left untouched by the vehicle tools.", 235, 235, 240, 255)

    ImGui.AddText(x, y + 304, "SUGGESTIONS", 190, 0, 255, 255)
    ImGui.AddText(x + 28, y + 336, "Have an idea for a useful feature or an improvement?", 235, 235, 240, 255)
    ImGui.AddText(x + 28, y + 362, "We can take suggestions for future feature updates!", 255, 255, 255, 255)

    ImGui.SetCursorScreenPos(x, y + 405)
end
-- =========================================================
-- VEHICLE GENERAL FEATURES
-- Only the requested vehicle-general features are exposed here.
-- 10 toggles + 3 live meters (Power / Speed / Headlights).
-- =========================================================
local VEH_GENERAL = {
    {"Max Vehicle Speed", "Enable the adjustable speed multiplier below.", "speed", "toggle"},
    {"Bypass LS Car Meet Restrictions", "Bypass weaponized Vehicle entrance in LS Car Meet; vehicle weapons remain untouched.", "lscm_bypass", "toggle"},
    {"Continues Boost", "Keep the Oppressor Mk II rocket boost active after a single boost press until you disable this toggle.", "continues_boost", "toggle"},
    {"Headlight Boost", "Enable the adjustable headlight multiplier below.", "headlight", "toggle"},
    {"Nitrous", "Enable the vehicle's nitrous state when supported.", "nitrous", "toggle"},
    {"Hide Vehicle", "Hide the vehicle visually while enabled.", "hide", "toggle"},
    {"Engine Always On", "Keep the engine running while driving.", "engine", "toggle"},
    {"Vehicle Owned Spoof", "Mark the current vehicle as previously player-owned without storing it as a Personal Vehicle.", "owned_spoof", "toggle"},
    {"Power Boost", "Enable the adjustable power multiplier below.", "power", "toggle"},
    {"Lights Always On", "Force vehicle lights on.", "lights", "toggle"}
}
local VEH_GENERAL_SLIDERS = {
    {"Power Boost", "Torque multiplier. 100% is stock, up to 180%.", "power", 100.0, 180.0, 1.0, 100.0},
    {"Speed Boost", "Top-speed multiplier. 100% is stock, up to 300%.", "speed", 100.0, 300.0, 5.0, 100.0},
    {"Headlight Boost", "Headlight brightness. 100% is stock, up to 500%.", "headlight", 100.0, 500.0, 10.0, 100.0}
}

local VEH_GENERAL_FEATURES = {}
local VEH_GENERAL_HASHES = {}
-- Keep the original hash IDs for the retained features so reloading this
-- cleaned version does not accidentally change their saved identity.
local VEH_GENERAL_HASH_IDS = {20, 22, 23, 21, 17, 13, 3, 4, 16, 11}
for i, def in ipairs(VEH_GENERAL) do
    local hash = Utils.Joaat("TestScript_VehicleGeneral_" .. tostring(VEH_GENERAL_HASH_IDS[i]))
    VEH_GENERAL_HASHES[#VEH_GENERAL_HASHES + 1] = hash
    FeatureMgr.AddFeature(hash, def[1], eFeatureType.Toggle, def[2])
    VEH_GENERAL_FEATURES[#VEH_GENERAL_FEATURES + 1] = FeatureMgr.GetFeature(hash)
    VEH_GENERAL_FEATURES[#VEH_GENERAL_FEATURES]:SetSaveable(false)
end

local VEH_GENERAL_SLIDER_FEATURES = {}
local VEH_GENERAL_SLIDER_HASHES = {}
for i, def in ipairs(VEH_GENERAL_SLIDERS) do
    local hash = Utils.Joaat("TestScript_VehicleGeneralSlider_" .. tostring(i))
    VEH_GENERAL_SLIDER_HASHES[#VEH_GENERAL_SLIDER_HASHES + 1] = hash
    FeatureMgr.AddFeature(hash, def[1], eFeatureType.SliderFloat, def[2])
    local feature = FeatureMgr.GetFeature(hash)
    feature:SetSaveable(false)
    feature:SetLimitValues(def[4], def[5])
    feature:SetStepSize(def[6])
    feature:SetValue(def[7])
    VEH_GENERAL_SLIDER_FEATURES[#VEH_GENERAL_SLIDER_FEATURES + 1] = feature
end

local function VehicleHandleFromObject(vehicle)
    return GetVehicleHandle(vehicle)
end

local VEH_GENERAL_PREVIOUS = {}
local VEH_GENERAL_LAST_HANDLE = 0
local VEH_GENERAL_INITIALIZED = false
local VEH_GENERAL_OWNED_SPOOF_STATE = {}

-- V63: keep the ownership spoof conservative.  The previous Player_Vehicle
-- decorator implementation caused GTA Enhanced to eject the player and hide
-- the vehicle because the game immediately treated the unregistered vehicle
-- as a mismatched personal vehicle.  Do NOT write Player_Vehicle here.
-- This version only uses the native ownership marker and never creates a
-- Personal Vehicle, garage slot, tracker, insurance, or storage record.
local OWNED_SPOOF_SET_OWNED_NATIVE = 0x2B5F9D2AF1F1722D

local function VehicleOwnedSpoofApply(vehicle, handle, enabled)
    if not handle or handle == 0 then return end
    if not enabled then
        VEH_GENERAL_OWNED_SPOOF_STATE[handle] = nil
        return
    end

    if VEH_GENERAL_OWNED_SPOOF_STATE[handle] then return end

    local ok = pcall(function()
        Natives.InvokeVoid(OWNED_SPOOF_SET_OWNED_NATIVE, handle, true)
    end)
    if ok then
        VEH_GENERAL_OWNED_SPOOF_STATE[handle] = true
    end
end

-- Oppressor Mk II rocket boost: latch the boost after one X press and
-- keep the native rocket-boost state active every tick while the toggle is on.
local VEH_GENERAL_CONTINUES_BOOST_STATE = {}
local VEH_ROCKET_BOOST_CONTROL = 351 -- INPUT_VEH_ROCKET_BOOST (X)
local VEH_IS_CONTROL_JUST_PRESSED = 0x580417101DDB492F
local VEH_SET_ROCKET_BOOST_ACTIVE = 0x81E1552E35DC3839
local VEH_SET_ROCKET_BOOST_FILL = 0xFEB2DDED3509562E
local VEH_SET_ROCKET_BOOST_REFILL_TIME = 0xE00F2AB100B76E89
local VEH_IS_ROCKET_BOOST_ACTIVE = 0x3D34E80EED4AE3BE

local function UpdateContinuesRocketBoost(enabled, handle)
    if not handle or handle == 0 then return end

    if not enabled then
        VEH_GENERAL_CONTINUES_BOOST_STATE[handle] = nil
        pcall(function()
            Natives.InvokeVoid(VEH_SET_ROCKET_BOOST_ACTIVE, handle, false)
        end)
        return
    end

    local justPressed = false
    local rocketActive = false
    pcall(function()
        justPressed = Natives.InvokeBool(VEH_IS_CONTROL_JUST_PRESSED, 0, VEH_ROCKET_BOOST_CONTROL)
    end)
    pcall(function()
        rocketActive = Natives.InvokeBool(VEH_IS_ROCKET_BOOST_ACTIVE, handle)
    end)

    -- Latch from either the X press or GTA's own rocket-boost state. The
    -- latter makes this independent of the controller-input native timing.
    if justPressed or rocketActive then
        VEH_GENERAL_CONTINUES_BOOST_STATE[handle] = true
    end

    if VEH_GENERAL_CONTINUES_BOOST_STATE[handle] then
        -- GTA drains the Mk II's rocket charge internally. Keep the refill
        -- timer at zero and refill to 100% before reasserting boost. This is
        -- deliberately done every tick rather than only when the meter hits 0.
        pcall(function()
            Natives.InvokeVoid(VEH_SET_ROCKET_BOOST_REFILL_TIME, handle, 0.0)
        end)
        pcall(function()
            Natives.InvokeVoid(VEH_SET_ROCKET_BOOST_FILL, handle, 100.0)
        end)
        pcall(function()
            Natives.InvokeVoid(VEH_SET_ROCKET_BOOST_ACTIVE, handle, true)
        end)
    end
end

local function VehicleGeneralApply(index, enabled, vehicle, handle)
    if not vehicle or not handle or handle == 0 then return end
    local kind = VEH_GENERAL[index][3]

    if kind == "engine" then
        -- Only force the engine on when the user enables Engine Always On.
        -- When disabled, leave GTA's normal ignition/auto-start behavior untouched.
        if enabled then
            pcall(function() Natives.InvokeVoid(0x2497C4717C8B881E, handle, true, true, true) end)
        end
    elseif kind == "owned_spoof" then
        VehicleOwnedSpoofApply(vehicle, handle, enabled)
    elseif kind == "lights" then
        -- Enhanced/Cherax build: legacy native unavailable; intentionally no-op.
    elseif kind == "hide" then
        -- SET_ENTITY_VISIBLE: enabled => invisible, disabled => visible.
        pcall(function() Natives.InvokeVoid(0xEA1C610A04DB6BBB, handle, not enabled, false) end)
    elseif kind == "nitrous" then
        pcall(function() vehicle.Nitrous = enabled end)
    elseif kind == "continues_boost" then
        UpdateContinuesRocketBoost(enabled, handle)
    elseif kind == "lscm_bypass" then
        -- The actual LSC restriction lives in the carmod_shop script.
        -- This feature is handled by the memory patch controller below.
    end
end

local function VehicleGeneralRestorePreviousVehicle(handle)
    if not handle or handle == 0 then return end
    if VEH_GENERAL_OWNED_SPOOF_STATE[handle] then
        VehicleOwnedSpoofApply(nil, handle, false)
    end
    -- Restore only the states that can remain changed when switching vehicles.
    pcall(function() Natives.InvokeVoid(0xEA1C610A04DB6BBB, handle, true, false) end)
end

local function VehicleGeneralApplySliders(vehicle, handle)
    if not vehicle or not handle or handle == 0 then return end

    local power = SafeRead(function() return VEH_GENERAL_SLIDER_FEATURES[1]:GetFloatValue() end, 100.0)
    local speed = SafeRead(function() return VEH_GENERAL_SLIDER_FEATURES[2]:GetFloatValue() end, 100.0)
    local headlight = SafeRead(function() return VEH_GENERAL_SLIDER_FEATURES[3]:GetFloatValue() end, 100.0)

    local powerOn = SafeFeatureToggled(VEH_GENERAL_FEATURES[9])
    local speedOn = SafeFeatureToggled(VEH_GENERAL_FEATURES[1])
    local headlightOn = SafeFeatureToggled(VEH_GENERAL_FEATURES[4])

    -- Power native: 1.0 = stock, 1.8 = maximum used by the slider.
    pcall(function()
        Natives.InvokeVoid(0xB59E4BD37AE292DB, handle, powerOn and (power / 100.0) or 1.0)
    end)

    -- Speed native works in m/s; use the vehicle's estimated stock max as the baseline.
    local baseSpeed = SafeRead(function()
        return Natives.InvokeFloat(0x53AF99BAA671CA47, handle)
    end, 0.0)
    if baseSpeed and baseSpeed > 0.0 then
        pcall(function()
            Natives.InvokeVoid(0xBAA045B4E42F3C06, handle, baseSpeed * (speedOn and (speed / 100.0) or 1.0))
        end)
    end

    -- Light multiplier: 1.0 = stock brightness.
    pcall(function()
        Natives.InvokeVoid(0xB385454F8791F57C, handle, headlightOn and (headlight / 100.0) or 1.0)
    end)
end

local function UpdateVehicleGeneralFeatures()
    local vehicle = SafeRead(function() return GTA.GetLocalVehicle() end, nil)
    if not vehicle then
        if VEH_GENERAL_LAST_HANDLE ~= 0 then
            VehicleGeneralRestorePreviousVehicle(VEH_GENERAL_LAST_HANDLE)
            VEH_GENERAL_CONTINUES_BOOST_STATE[VEH_GENERAL_LAST_HANDLE] = nil
            VEH_GENERAL_LAST_HANDLE = 0
            VEH_GENERAL_PREVIOUS = {}
            VEH_GENERAL_INITIALIZED = false
        end
        return
    end

    local handle = VehicleHandleFromObject(vehicle)
    if not handle or handle == 0 then return end

    -- If the player switched vehicles, restore the old one before applying the current state.
    if VEH_GENERAL_LAST_HANDLE ~= 0 and VEH_GENERAL_LAST_HANDLE ~= handle then
        VehicleGeneralRestorePreviousVehicle(VEH_GENERAL_LAST_HANDLE)
        VEH_GENERAL_CONTINUES_BOOST_STATE[VEH_GENERAL_LAST_HANDLE] = nil
        VEH_GENERAL_PREVIOUS = {}
        VEH_GENERAL_INITIALIZED = false
    end
    VEH_GENERAL_LAST_HANDLE = handle

    for i = 1, #VEH_GENERAL do
        local feature = VEH_GENERAL_FEATURES[i]
        local enabled = SafeFeatureToggled(feature)
        local previous = VEH_GENERAL_PREVIOUS[i]

        -- Apply on first observation and on every state transition.
        if not VEH_GENERAL_INITIALIZED or previous ~= enabled then
            VehicleGeneralApply(i, enabled, vehicle, handle)
            VEH_GENERAL_PREVIOUS[i] = enabled
        elseif enabled then
            -- Continuous features need their native refreshed every tick.
            local kind = VEH_GENERAL[i][3]
            if kind == "engine" or kind == "nitrous" or kind == "continues_boost" then
                VehicleGeneralApply(i, true, vehicle, handle)
            end
        end
    end

    VEH_GENERAL_INITIALIZED = true
    VehicleGeneralApplySliders(vehicle, handle)
end

local VEH_GENERAL_TICK_HASH = Utils.Joaat("TestScript_VehicleGeneralTick")
FeatureMgr.AddFeature(
    VEH_GENERAL_TICK_HASH,
    "Vehicle General Runtime",
    eFeatureType.Toggle,
    "Internal runtime controller for Vehicle General features.",
    function()
        UpdateVehicleGeneralFeatures()
    end
)
local vehicleGeneralTickFeature = FeatureMgr.GetFeature(VEH_GENERAL_TICK_HASH)
vehicleGeneralTickFeature:SetSaveable(false)
vehicleGeneralTickFeature:RegisterCallbackTrigger(eCallbackTrigger.OnTick)
vehicleGeneralTickFeature:Toggle()

-- =========================================================
-- LS CAR MEET RESTRICTION PATCH
-- V63: Cherax-safe runtime patch based on the YimMenuV2 implementation.
-- IMPORTANT: this changes ONLY the LSC eligibility bytecode. Vehicle
-- weapons/weapon flags are never removed or modified.
-- =========================================================
local LSCM_PATCH_SCRIPT_NAME = "carmod_shop"
local LSCM_PATCH_SCRIPT_HASH = 0x1DC6B680 -- JOAAT("carmod_shop")

-- V63: Mk II compatibility probe. The Oppressor Mk II is explicitly excluded
-- from the normal LSCM vehicle list, so V56 can bypass carmod_shop while the
-- separate car-meet script still rejects the model. We keep this isolated from
-- the working V56 patches and only patch car_meet_carmod when BOTH known
-- eligibility signatures are present. No vehicle/model/weapon flags are touched.
local LSCM_MK2_SCRIPT_NAME = "car_meet_carmod"
local LSCM_MK2_SCRIPT_HASH = Utils.Joaat(LSCM_MK2_SCRIPT_NAME)

local LSCM_MK2_PATCHES = {
    {
        name = "Mk2_CanUseVehiclePatch",
        pattern = "2D ? ? ? ? 38 ? 5D ? ? ? 56 ? ? 71 2E ? ? 5D",
        offset = 5,
        bytes = {0x72, 0x2E, 0x03, 0x01}
    },
    {
        name = "Mk2_BlockMenuOptionPatch",
        pattern = "2D ? ? ? ? 38 ? 5D ? ? ? 5D ? ? 56",
        offset = 5,
        bytes = {0x71, 0x2E, 0x01, 0x01}
    }
}

-- V63: target the actual APC/Mk II constants when present. Keep the known-good
-- upstream carmod_shop patch intact and use the separate car_meet_carmod
-- signatures only when they are actually present.
local LSCM_SPECIAL_MODEL_PATCHES = {
    -- Little-endian JOAAT constants. Replace only inside car_meet_carmod.
    -- Sultan is used as a benign allowed-model constant; the comparison itself
    -- remains intact. Original bytes are restored when the patch is removed.
    {name = "APC_ModelBlacklistConstant", pattern = "50 D2 89 21", offset = 0, bytes = {0x54, 0x27, 0xDA, 0x39}},
    {name = "OppressorMk2_ModelBlacklistConstant", pattern = "D3 A9 54 7B", offset = 0, bytes = {0x54, 0x27, 0xDA, 0x39}}
}

local LSCM_PATCHES = {
    {
        name = "CanUseVehiclePatch",
        pattern = "2D ? ? ? ? 38 ? 5D ? ? ? 56 ? ? 71 2E ? ? 5D",
        offset = 5,
        bytes = {0x72, 0x2E, 0x03, 0x01}
    },
    {
        name = "BlockMenuOptionPatch",
        pattern = "2D ? ? ? ? 38 ? 5D ? ? ? 5D ? ? 56",
        offset = 5,
        bytes = {0x71, 0x2E, 0x01, 0x01}
    }
}

local LSCM_PATCH_STATE = {}
local LSCM_MK2_PATCH_STATE = {}
local LSCM_MK2_PATCH_READY = false
local LSCM_SPECIAL_MODEL_PATCH_STATE = {}
local LSCM_SPECIAL_MODEL_PATCH_READY = false
local LSCM_PATCH_READY = false
local LSCM_PATCH_LAST_SCAN = 0
local LSCM_PATCH_LAST_STATUS = 0

local function LSCMLog(msg)
    pcall(function() Logger.LogInfo("[LSCM Bypass] " .. tostring(msg)) end)
end

local function LSCMReadBytes(address, count)
    if not address or address == 0 then return nil end
    local out = {}
    for i = 0, count - 1 do
        local ok, value = pcall(function()
            return Memory.ReadUByte(address + i)
        end)
        if not ok or value == nil then return nil end
        out[#out + 1] = value
    end
    return out
end

local function LSCMWriteBytes(address, bytes)
    if not address or address == 0 then return false end
    for i, value in ipairs(bytes) do
        local ok = pcall(function()
            Memory.WriteByte(address + (i - 1), value)
        end)
        if not ok then return false end
    end
    return true
end

local function LSCMFindPatchAddressForHash(scriptHash, def)
    local ok, base = pcall(function()
        return Memory.ScanScript(scriptHash, def.pattern)
    end)
    if ok and base and base ~= 0 then
        return base + def.offset
    end
    return 0
end

-- Cherax's ScanScript expects the JOAAT hash (integer), NOT the script name.
-- Passing the string was the source of the repeated 0x0 console errors in V55.
local function LSCMFindPatchAddress(def)
    return LSCMFindPatchAddressForHash(LSCM_PATCH_SCRIPT_HASH, def)
end

local function LSCMApplyPatch(def)
    local address = LSCMFindPatchAddress(def)
    if not address or address == 0 then
        return false
    end

    local state = LSCM_PATCH_STATE[def.name]
    if state and state.address == address and state.patched then
        return true
    end

    local current = LSCMReadBytes(address, #def.bytes)
    if not current then
        return false
    end

    local alreadyPatched = true
    for i, value in ipairs(def.bytes) do
        if current[i] ~= value then
            alreadyPatched = false
            break
        end
    end

    local original = current
    if state and state.address == address and state.original then
        original = state.original
    end

    if not alreadyPatched then
        if not LSCMWriteBytes(address, def.bytes) then
            LSCMLog(def.name .. ": pattern found but write failed")
            return false
        end
    end

    LSCM_PATCH_STATE[def.name] = {
        address = address,
        original = original,
        patched = true
    }

    LSCMLog(def.name .. ": PATCHED at 0x" .. string.format("%X", address))
    return true
end

local function LSCMRestorePatch(def)
    local state = LSCM_PATCH_STATE[def.name]
    if not state or not state.patched then return end

    local currentAddress = LSCMFindPatchAddress(def)
    if currentAddress ~= 0 and currentAddress == state.address then
        LSCMWriteBytes(state.address, state.original)
    end

    LSCM_PATCH_STATE[def.name] = nil
end

local function LSCMApplyPatchSet(scriptHash, stateTable, def, label)
    local address = LSCMFindPatchAddressForHash(scriptHash, def)
    if not address or address == 0 then return false end

    local state = stateTable[def.name]
    if state and state.address == address and state.patched then return true end

    local current = LSCMReadBytes(address, #def.bytes)
    if not current then return false end

    local alreadyPatched = true
    for i, value in ipairs(def.bytes) do
        if current[i] ~= value then alreadyPatched = false break end
    end

    local original = current
    if state and state.address == address and state.original then original = state.original end

    if not alreadyPatched and not LSCMWriteBytes(address, def.bytes) then
        LSCMLog(label .. ": write failed at 0x" .. string.format("%X", address))
        return false
    end

    stateTable[def.name] = {address = address, original = original, patched = true}
    LSCMLog(label .. ": PATCHED at 0x" .. string.format("%X", address))
    return true
end

local function LSCMRestorePatchSet(scriptHash, stateTable, defs)
    for _, def in ipairs(defs) do
        local state = stateTable[def.name]
        if state and state.patched then
            local address = LSCMFindPatchAddressForHash(scriptHash, def)
            if address ~= 0 and address == state.address then
                LSCMWriteBytes(state.address, state.original)
            end
            stateTable[def.name] = nil
        end
    end
end

local function LSCMGetCurrentVehicleModelHash()
    local ok, vehicle = pcall(function() return GTA.GetLocalVehicle() end)
    if not ok or not vehicle then return 0 end
    local okHash, modelHash = pcall(function() return vehicle.ModelInfo and vehicle.ModelInfo.Hash end)
    if not okHash or modelHash == nil then return 0 end
    return tonumber(modelHash) or 0
end

local function LSCMIsSpecialRestrictedModel()
    local modelHash = LSCMGetCurrentVehicleModelHash()
    return modelHash == 0x2189D250 or modelHash == 0x7B54A9D3
end

local function LSCMRestoreSpecialModelPatches()
    for _, state in pairs(LSCM_SPECIAL_MODEL_PATCH_STATE) do
        if state.address and state.original then
            LSCMWriteBytes(state.address, state.original)
        end
    end
    LSCM_SPECIAL_MODEL_PATCH_STATE = {}
    LSCM_SPECIAL_MODEL_PATCH_READY = false
end

local function LSCMApplySpecialModelPatches()
    if not LSCMIsSpecialRestrictedModel() then
        if LSCM_SPECIAL_MODEL_PATCH_READY then LSCMRestoreSpecialModelPatches() end
        return false
    end

    local foundAny = false
    for _, def in ipairs(LSCM_SPECIAL_MODEL_PATCHES) do
        local address = LSCMFindPatchAddressForHash(LSCM_MK2_SCRIPT_HASH, def)
        if address and address ~= 0 then
            foundAny = true
            local key = def.name .. "@" .. string.format("%X", address)
            if not LSCM_SPECIAL_MODEL_PATCH_STATE[key] then
                local current = LSCMReadBytes(address, #def.bytes)
                if current then
                    local alreadyPatched = true
                    for i, value in ipairs(def.bytes) do
                        if current[i] ~= value then alreadyPatched = false break end
                    end
                    if alreadyPatched then
                        LSCM_SPECIAL_MODEL_PATCH_STATE[key] = {address = address, original = nil}
                    elseif LSCMWriteBytes(address, def.bytes) then
                        LSCM_SPECIAL_MODEL_PATCH_STATE[key] = {address = address, original = current}
                        LSCMLog(def.name .. ": PATCHED at 0x" .. string.format("%X", address))
                    end
                end
            end
        end
    end
    LSCM_SPECIAL_MODEL_PATCH_READY = next(LSCM_SPECIAL_MODEL_PATCH_STATE) ~= nil
    return foundAny
end

local LSCMNearCarMeet

local function UpdateLSCMMk2Patch()
    if not LSCMNearCarMeet() then
        if LSCM_MK2_PATCH_READY then
            LSCMRestorePatchSet(LSCM_MK2_SCRIPT_HASH, LSCM_MK2_PATCH_STATE, LSCM_MK2_PATCHES)
            LSCM_MK2_PATCH_READY = false
        end
        if LSCM_SPECIAL_MODEL_PATCH_READY then LSCMRestoreSpecialModelPatches() end
        return
    end

    local foundA = LSCMFindPatchAddressForHash(LSCM_MK2_SCRIPT_HASH, LSCM_MK2_PATCHES[1])
    local foundB = LSCMFindPatchAddressForHash(LSCM_MK2_SCRIPT_HASH, LSCM_MK2_PATCHES[2])
    if foundA ~= 0 and foundB ~= 0 then
        local a = LSCMApplyPatchSet(LSCM_MK2_SCRIPT_HASH, LSCM_MK2_PATCH_STATE, LSCM_MK2_PATCHES[1], "car_meet_carmod CanUseVehicle")
        local b = LSCMApplyPatchSet(LSCM_MK2_SCRIPT_HASH, LSCM_MK2_PATCH_STATE, LSCM_MK2_PATCHES[2], "car_meet_carmod BlockMenuOption")
        if a and b and not LSCM_MK2_PATCH_READY then
            LSCM_MK2_PATCH_READY = true
            LSCMLog("car_meet_carmod generic eligibility patches active; weapons remain untouched.")
        end
    end

    local specialFound = LSCMApplySpecialModelPatches()
    if specialFound and not LSCM_SPECIAL_MODEL_PATCH_READY then
        LSCMLog("car_meet_carmod model constant found but patch state is not ready.")
    elseif LSCMIsSpecialRestrictedModel() and not specialFound and now ~= nil then
        local t = 0
        pcall(function() t = Time.GetEpocheMs() end)
        if t ~= 0 and t - LSCM_PATCH_LAST_STATUS >= 5000 then
            LSCM_PATCH_LAST_STATUS = t
            LSCMLog("APC/Mk II detected, but no matching model constant was found in car_meet_carmod.")
        end
    end
end

LSCMNearCarMeet = function()
    local ok, vehicle = pcall(function() return GTA.GetLocalVehicle() end)
    if not ok or not vehicle then return false end

    local okPos, pos = pcall(function() return vehicle.Position end)
    if not okPos or not pos then return false end

    local dx = (tonumber(pos.x) or 0) - 758.0
    local dy = (tonumber(pos.y) or 0) + 816.0
    return (dx * dx + dy * dy) <= (250.0 * 250.0)
end

local function UpdateLSCMRestrictionPatch()
    local feature = VEH_GENERAL_FEATURES[2]
    local enabled = SafeFeatureToggled(feature)

    if not enabled then
        if LSCM_PATCH_READY or next(LSCM_PATCH_STATE) ~= nil then
            for _, def in ipairs(LSCM_PATCHES) do
                LSCMRestorePatch(def)
            end
            LSCM_PATCH_READY = false
        end
        return
    end

    if not LSCMNearCarMeet() then
        return
    end

    local now = 0
    pcall(function() now = Time.GetEpocheMs() end)
    if now == 0 then return end
    if now - LSCM_PATCH_LAST_SCAN < 100 then return end
    LSCM_PATCH_LAST_SCAN = now

    local allReady = true
    for _, def in ipairs(LSCM_PATCHES) do
        if not LSCMApplyPatch(def) then
            allReady = false
        end
    end

    if allReady and not LSCM_PATCH_READY then
        LSCMLog("Both patches active. LS Car Meet restriction bypass is ON; vehicle weapons remain untouched.")
    elseif not allReady and now - LSCM_PATCH_LAST_STATUS >= 5000 then
        LSCM_PATCH_LAST_STATUS = now
        LSCMLog("Waiting for carmod_shop to become resident near LS Car Meet...")
    end

    LSCM_PATCH_READY = allReady
end

local LSCM_PATCH_TICK_HASH = Utils.Joaat("TestScript_LSCMRestrictionPatch")
FeatureMgr.AddFeature(
    LSCM_PATCH_TICK_HASH,
    "LSCM Restriction Patch Runtime",
    eFeatureType.Toggle,
    "Internal controller for the LS Car Meet restriction patch.",
    function()
        UpdateLSCMRestrictionPatch()
        UpdateLSCMMk2Patch()
    end
)
local lscmPatchTickFeature = FeatureMgr.GetFeature(LSCM_PATCH_TICK_HASH)
lscmPatchTickFeature:SetSaveable(false)
lscmPatchTickFeature:RegisterCallbackTrigger(eCallbackTrigger.OnTick)
lscmPatchTickFeature:Toggle()

-- User-facing Bypass LS Car Meet Restrictions starts OFF by default.
-- It is enabled only when the user toggles it on.

local function DrawVehicleGeneral()
    local x, y = ImGui.GetCursorScreenPos()
    ImGui.AddText(x, y, "VEHICLE GENERAL", 235, 235, 245, 255)
    ImGui.AddText(x, y + 24, "10 toggles + 3 live adjustment meters", 145, 145, 160, 255)

    local startY = y + 82
    local rowH = 34
    local colW = 300

    for i = 1, #VEH_GENERAL_HASHES do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        ImGui.SetCursorScreenPos(x + col * colW, startY + row * rowH)
        ClickGUI.RenderFeature(VEH_GENERAL_HASHES[i])
    end

    local sliderY = startY + math.ceil(#VEH_GENERAL_HASHES / 2) * rowH + 18
    ImGui.AddText(x, sliderY, "LIVE ADJUSTMENTS", 190, 190, 205, 255)
    ImGui.AddText(x, sliderY + 22, "100% = stock value", 130, 130, 145, 255)

    for i = 1, #VEH_GENERAL_SLIDER_HASHES do
        ImGui.SetCursorScreenPos(x, sliderY + 52 + ((i - 1) * 42))
        ClickGUI.RenderFeature(VEH_GENERAL_SLIDER_HASHES[i])
    end

    UpdateVehicleGeneralFeatures()
    ImGui.SetCursorScreenPos(x, sliderY + 52 + (#VEH_GENERAL_SLIDER_HASHES * 42) + 20)
end

local function DrawVehicleDamageMapTab()
    DrawVehicleDamageMap()
end

RenderTestScriptTab = function()
    -- ONE top-level Cherax script only.
    -- Everything below is an internal tab inside this script.
    if ClickGUI.BeginCustomChildWindow(
        "X Script",
        -1,
        -1,
        0.5,
        0.5
    ) then
        local reserveX, reserveY = ImGui.GetCursorScreenPos()
        ImGui.InvisibleButton(
            "TestScriptLayoutReserve",
            1,
            610
        )
        ImGui.SetCursorScreenPos(reserveX, reserveY)

        local x, y = ImGui.GetCursorScreenPos()

        if ImGui.BeginTabBar("TestScriptTabs") then

            -- Theme
            if ImGui.BeginTabItem("Theme") then
                DrawThemeGallery()
                ImGui.EndTabItem()
            end

            -- How to use
            if ImGui.BeginTabItem("How to use") then
                DrawHowToUse()
                ImGui.EndTabItem()
            end

            -- About
            if ImGui.BeginTabItem("About") then
                DrawAbout()
                ImGui.EndTabItem()
            end

            -- Vehicle
            if ImGui.BeginTabItem("Vehicle") then
                if ImGui.BeginTabBar("VehicleTabs") then
                    if ImGui.BeginTabItem("Analyzer") then
                        DrawVehicleAnalyzer()
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Damage map") then
                        DrawVehicleDamageMapTab()
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("General") then
                        DrawVehicleGeneral()
                        ImGui.EndTabItem()
                    end

                    ImGui.EndTabBar()
                end
                ImGui.EndTabItem()
            end

            -- Self
            if ImGui.BeginTabItem("Self") then
                DrawSelfFeatures()
                ImGui.EndTabItem()
            end

            -- Others
            if ImGui.BeginTabItem("Others") then
                DrawOthersFeatures()
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        ClickGUI.EndCustomChildWindow()
    end
end

ClickGUI.AddTab("X Script", RenderTestScriptTab)
