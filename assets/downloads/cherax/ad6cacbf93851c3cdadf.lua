-- LiquidFit.lua
-- A clean, animated outfit editor for Cherax. Part of the Liquid script family.
--
-- Highlights:
--   - Custom floating ImGui window (drag by the title bar), fully custom drawn:
--     glass gradients, sliding category pill, hover lifts, staggered tile
--     fade-ins, animated texture strip, live rotating ped preview.
--   - Real clothing thumbnails, lazily downloaded per visible tile from the
--     ShortByte/GTA5-Cloth-Assets archive (global drawable indexes), routed
--     through the wsrv.nl image proxy so they arrive as small PNGs Cherax can
--     decode. Cached on disk under Cache/LiquidFit/thumbs.
--   - Real item names from Colbss/FiveM-ClothingData (pre-baked into
--     names_male.lua / names_female.lua next to this script).
--   - Natives are only touched from a native-thread worker; the render
--     callback never calls game code directly (op queue + cached state).
--
-- Covers the 11 clothing components plus props (hats, glasses, ears, watches,
-- bracelets), a saved-outfit collection with rename/share, Cherax Outfits
-- folder interop, and bbfas-style base64 outfit codes.
-- Categories without a public image set fall back to elegant number tiles.

local SCRIPT_NAME = "LiquidFit"
local VERSION = "1.1.1" -- public version, shown in About
local BUILD = 34        -- internal dev build; bumped every edit round so the
                        -- log always identifies which copy is running

-- Generation guard: when a newer copy of this script loads (Startup.lua paste,
-- manual re-run, whatever), older copies see the bumped generation and their
-- callbacks turn into no-ops instead of fighting over the same window.
__LIQUIDFIT_GEN = (__LIQUIDFIT_GEN or 0) + 1
local MY_GEN = __LIQUIDFIT_GEN
local function staleInstance() return __LIQUIDFIT_GEN ~= MY_GEN end

local function h(key) return Utils.Joaat(SCRIPT_NAME .. "_" .. key) end

-- Feature hashes live in ONE table: Lua caps a chunk at 200 locals and
-- 28 separate "local H_..." declarations blew straight past it (build 29
-- failed to load with "too many local variables").
local H = {}

-- ============================================================================
-- Tunables / constants
-- ============================================================================

-- WIN_W/WIN_H/RIGHT_W are mutable: the window is resizable via the corner
-- grip, and every layout function derives from these upvalues.
local WIN_W, WIN_H   = 960, 600
local WIN_MIN_W, WIN_MIN_H = 780, 500
local WIN_MAX_W, WIN_MAX_H = 1500, 950
local TITLE_H        = 44
local RAIL_W         = 168
local RIGHT_W        = 240   -- full-height character preview column
local FOOTER_H       = 26
local PAD            = 10
local CARD_H         = 96    -- selected-item card under the grid
local PVCTRL_H       = 34    -- rotate controls under the preview
local MAX_DOWNLOADS  = 4

-- Liquid palette (matches the LiquidTheme Cherax theme)
local COL = {
    bg        = { 24, 34, 52 },     -- deep glass base
    bg2       = { 58, 78, 110 },    -- theme window bg
    panel     = { 130, 160, 200 },  -- child tint
    accent    = { 90, 160, 255 },
    accentHi  = { 150, 200, 255 },
    text      = { 240, 245, 252 },
    textDim   = { 150, 165, 185 },
    good      = { 120, 230, 150 },
    bad       = { 240, 100, 100 },
}

-- Component metadata. imgCat = ShortByte archive category (nil = no images);
-- hasImages = pre-built cache only. unisex = archive not split by gender.
-- Props use id = 100 + anchor so their keys never collide with component ids;
-- comp.prop holds the real prop anchor for the natives.
local COMPONENTS = {
    { id = 2,  key = "HAIR", label = "Hair",          icon = "scissors" },
    { id = 1,  key = "BERD", label = "Mask",          icon = "venetian-mask", imgCat = "masks", unisex = true },
    { id = 11, key = "JBIB", label = "Top",           icon = "shirt", imgCat = "tops" },
    { id = 8,  key = "ACCS", label = "Undershirt",    icon = "layers", imgCat = "undershirts" },
    { id = 9,  key = "TASK", label = "Body Armor",    icon = "shield", hasImages = true },
    { id = 3,  key = "UPPR", label = "Torso / Gloves",icon = "hand", hasImages = true },
    { id = 5,  key = "HAND", label = "Bags",          icon = "backpack", hasImages = true },
    { id = 4,  key = "LOWR", label = "Legs",          icon = "ruler", imgCat = "legs" },
    { id = 6,  key = "FEET", label = "Shoes",         icon = "footprints", imgCat = "shoes" },
    { id = 7,  key = "TEEF", label = "Accessories",   icon = "gem", imgCat = "accessories" },
    { id = 10, key = "DECL", label = "Decals",        icon = "sticker" },
    -- props (drawable -1 = nothing worn; the grid gets a None tile)
    { id = 100, prop = 0, key = "PHEAD",   label = "Hats",      icon = "crown",   hasImages = true },
    { id = 101, prop = 1, key = "PEYES",   label = "Glasses",   icon = "glasses", hasImages = true },
    { id = 102, prop = 2, key = "PEARS",   label = "Ears",      icon = "ear",     hasImages = true },
    { id = 106, prop = 6, key = "PLWRIST", label = "Left Wrist",  icon = "watch", hasImages = true },
    { id = 107, prop = 7, key = "PRWRIST", label = "Right Wrist", icon = "link",  hasImages = true },
    -- Face (comp 0) intentionally omitted: freemode heads are driven by head
    -- blend data, so component swaps do nothing visible there.
}

-- ============================================================================
-- Features
-- ============================================================================

H.OPEN       = h("Open")
H.THUMBSIZE  = h("ThumbSize")
H.USEPROXY   = h("UseProxy")
H.SHOWNAMES  = h("ShowNames")
H.ONLYMENU   = h("OnlyWithMenu")
H.ANIMSPEED  = h("AnimSpeed")
H.AUTOROTATE = h("AutoRotate")
H.CLEARCACHE = h("ClearCache")
H.RESETPOS   = h("ResetPos")
H.POSX       = h("PosX")
H.POSY       = h("PosY")
H.WORKER     = h("__Worker")
H.RENDER     = h("__Render")

FeatureMgr.AddFeature(H.OPEN, "Open LiquidFit", eFeatureType.Toggle,
    "Show the LiquidFit outfit editor window. Bind a hotkey to this in Cherax's hotkey settings for quick access.")

FeatureMgr.AddFeature(H.THUMBSIZE, "Tile Size", eFeatureType.SliderInt,
    "Size of clothing tiles in the grid.")
    :SetLimitValues(72, 128):SetValue(92)

FeatureMgr.AddFeature(H.USEPROXY, "PNG Proxy (wsrv.nl)", eFeatureType.Toggle,
    "Route thumbnail downloads through wsrv.nl to convert them to small PNGs. Recommended; turn off only if the proxy is down.")
    :SetValue(true)

FeatureMgr.AddFeature(H.SHOWNAMES, "Show Item Names", eFeatureType.Toggle,
    "Show real clothing names under tiles when known.")
    :SetValue(true)

FeatureMgr.AddFeature(H.ONLYMENU, "Only Show With Menu", eFeatureType.Toggle,
    "Hide the window whenever the Cherax menu is closed. On by default; turn it off to keep the window up while you play.")
    :SetValue(true)

FeatureMgr.AddFeature(H.ANIMSPEED, "Animation Speed", eFeatureType.SliderFloat,
    "Higher is snappier, lower is dreamier.")
    :SetLimitValues(4.0, 20.0):SetValue(11.0):SetStepSize(0.5)

FeatureMgr.AddFeature(H.AUTOROTATE, "Auto-Rotate Preview", eFeatureType.Toggle,
    "Slowly spin the character preview. Off by default; use the arrows or drag to rotate.")

H.PREVIEWZOOM = h("PreviewZoom")
FeatureMgr.AddFeature(H.PREVIEWZOOM, "Preview Zoom", eFeatureType.SliderFloat,
    "Camera distance for the character preview. More negative = further away.")
    :SetLimitValues(-8.0, -2.0):SetValue(-4.5):SetStepSize(0.1)

H.PREVIEWYOFF = h("PreviewYOffset")
FeatureMgr.AddFeature(H.PREVIEWYOFF, "Preview Y Offset", eFeatureType.SliderFloat,
    "Shift the character preview up or down inside its frame.")
    :SetLimitValues(-0.15, 0.15):SetValue(0.0):SetStepSize(0.01)

H.PVCALIB = h("PreviewCalib")
FeatureMgr.AddFeature(H.PVCALIB, "Preview Calibration X", eFeatureType.SliderFloat,
    "Locks the character horizontally. Move the window left/right: if he drifts TOO FAR sideways, raise this; if he lags behind, lower it. Set once, it saves.")
    :SetLimitValues(0.5, 2.0):SetValue(1.0):SetStepSize(0.002)

H.PVCALIBY = h("PreviewCalibY")
FeatureMgr.AddFeature(H.PVCALIBY, "Preview Calibration Y", eFeatureType.SliderFloat,
    "Same as X but vertical: move the window up/down and tune until he stays put. The two axes often need different values.")
    :SetLimitValues(0.5, 2.0):SetValue(1.0):SetStepSize(0.005)

H.HIDEEMPTY = h("HideEmpty")
FeatureMgr.AddFeature(H.HIDEEMPTY, "Hide Unnamed Items", eFeatureType.Toggle,
    "Optional decluttering: skip drawables that have neither a preview image nor a name. Warning: this also hides some REAL items that just lack data (flag bags, some armors), so it is off by default.")

H.ICONS = h("Icons")
FeatureMgr.AddFeature(H.ICONS, "Category Icons", eFeatureType.Toggle,
    "Show icons next to category names (downloaded once, cached). Experimental.")
    :SetValue(true)

-- hidden persisted window position + size
FeatureMgr.AddFeature(H.POSX, "LiquidFit Pos X", eFeatureType.InputFloat, "")
    :SetValue(-1.0):SetVisible(false)
FeatureMgr.AddFeature(H.POSY, "LiquidFit Pos Y", eFeatureType.InputFloat, "")
    :SetValue(-1.0):SetVisible(false)

H.WINW = h("WinW")
H.WINH = h("WinH")
FeatureMgr.AddFeature(H.WINW, "LiquidFit Win W", eFeatureType.InputFloat, "")
    :SetValue(-1.0):SetVisible(false)
FeatureMgr.AddFeature(H.WINH, "LiquidFit Win H", eFeatureType.InputFloat, "")
    :SetValue(-1.0):SetVisible(false)

-- hidden flag: the first-run intro was shown and dismissed (or the preview
-- pack is already installed); persisted via the config so it never re-nags
H.INTRODONE = h("IntroDone")
FeatureMgr.AddFeature(H.INTRODONE, "LiquidFit Intro Done", eFeatureType.Toggle, "")
    :SetVisible(false)

-- detachable preview window
H.DETACH = h("DetachPreview")
FeatureMgr.AddFeature(H.DETACH, "Detach Preview", eFeatureType.Toggle,
    "Pop the character preview out into its own window: move it anywhere, size it however big you like, and keep the main menu compact. The little arrow button on the preview does the same thing.")

H.PVWX = h("PvWinX")
H.PVWY = h("PvWinY")
H.PVWW = h("PvWinW")
H.PVWH = h("PvWinH")
for _, hh in ipairs({ H.PVWX, H.PVWY, H.PVWW, H.PVWH }) do
    FeatureMgr.AddFeature(hh, "LiquidFit Pv " .. hh, eFeatureType.InputFloat, "")
        :SetValue(-1.0):SetVisible(false)
end

-- ============================================================================
-- Small helpers
-- ============================================================================

local function fOn(hash)  return FeatureMgr.IsFeatureToggled(hash) end
local function fInt(hash) return FeatureMgr.GetFeatureInt(hash) end
local function fFlt(hash) return FeatureMgr.GetFeatureFloat(hash) end

local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function lerp(a, b, t) return a + (b - a) * t end

local function damp(cur, target, speed, dt)
    if speed <= 0 or dt <= 0 then return target end
    return cur + (target - cur) * (1.0 - math.exp(-speed * dt))
end

local function u32(r, g, b, a)
    return ImGui.ColorConvertRGBAToU32({ r, g, b, a })
end

local function urlencode(s)
    return (s:gsub("[^%w%-%._~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local V2New = (V2 and V2.New) or (Vector2 and Vector2.New) or nil

-- ============================================================================
-- Paths
-- ============================================================================

-- GetMenuRootPath() returns the Cherax folder WITHOUT a trailing separator;
-- normalize so path building never silently lands in "...\CheraxCache".
local ROOT = FileMgr.GetMenuRootPath()
if ROOT:sub(-1) ~= "\\" and ROOT:sub(-1) ~= "/" then
    ROOT = ROOT .. "\\"
end
local SCRIPTDIR = ROOT .. "Lua\\" .. SCRIPT_NAME .. "\\"
local CACHEDIR  = ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\thumbs\\"
local ICONDIR   = ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\icons\\"
-- Create EVERY directory we write into, with NO trailing separator (a tester
-- log showed downloads dying with "Failed to open the file" because these
-- folders were missing). The script dir matters most: the Cherax site
-- installs this file straight into Lua\, so Lua\LiquidFit\ does not exist
-- until we make it, and config/names/outfits all live there.
FileMgr.CreateDir(ROOT .. "Lua\\" .. SCRIPT_NAME)
FileMgr.CreateDir(ROOT .. "Cache\\" .. SCRIPT_NAME)
FileMgr.CreateDir(ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\thumbs")
FileMgr.CreateDir(ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\icons")

-- ============================================================================
-- Name data (lazy per gender)
-- ============================================================================

local namesCache = {}   -- gender -> { [compId] = { [globalId] = {labels...} } } | false

local function namesFor(gender)
    if gender == nil then return nil end
    local cached = namesCache[gender]
    if cached ~= nil then return cached or nil end
    local path = SCRIPTDIR .. "names_" .. gender .. ".lua"
    local ok, result = pcall(function()
        if not FileMgr.DoesFileExist(path) then
            error("file not found: " .. path)
        end
        local content = FileMgr.ReadFileContent(path)
        if content == nil or #content == 0 then
            error("file empty: " .. path)
        end
        local loader = load or loadstring
        local chunk, cerr = loader(content, "=names_" .. gender)
        if not chunk then error("chunk error: " .. tostring(cerr)) end
        return chunk()
    end)
    if ok and type(result) == "table" then
        local comps = 0
        for _ in pairs(result) do comps = comps + 1 end
        Logger.LogInfo(("[%s] loaded names_%s (%d components)")
            :format(SCRIPT_NAME, gender, comps))
        namesCache[gender] = result
    else
        Logger.LogInfo(("[%s] names_%s failed to load: %s")
            :format(SCRIPT_NAME, gender, tostring(result)))
        namesCache[gender] = false
    end
    return namesCache[gender] or nil
end

-- Raw label straight from the data ("NULL" means unlabeled in the source dump)
local function rawName(gender, compId, drawable, tex)
    local names = namesFor(gender)
    if not names then return nil end
    local comp = names[compId]
    local entry = comp and comp[drawable]
    if not entry then return nil end
    return entry[(tex or 0) + 1] or entry[1]
end

local function itemName(gender, compId, drawable, tex)
    if not fOn(H.SHOWNAMES) then return nil end
    local n = rawName(gender, compId, drawable, tex)
    if n == nil or n == "" or n == "NULL" then return nil end
    return n
end

-- ============================================================================
-- Ped state - written only by the native-thread worker
-- ============================================================================

local ped = {
    handle    = 0,
    modelHash = 0,
    gender    = nil,      -- "male" | "female" | nil
    comps     = {},       -- compId -> { drawable, tex, drawCount }
    texCounts = {},       -- compId -> { [drawable] = texCount }
    valid     = false,
}

local opQueue      = {}   -- { {comp, draw, tex} , ... }
local wantRefresh  = true
local wantCounts   = {}   -- set of compIds needing texCounts scan
local snapshot     = nil  -- compId -> {drawable, tex}
local wantSnapshot = false
local restoreReq   = false

-- Model hashes must be compared in ONE domain. GET_ENTITY_MODEL comes back
-- through a signed 32-bit int, and mp_f_freemode_01 (0x9C9EF57E) has the high
-- bit set, so it arrives NEGATIVE while Joaat's value is positive. The male
-- hash (0x705E61F2) fits in the signed range, which is exactly why gender
-- detection worked for male peds and silently failed for female ones.
local function u32hash(v)
    v = tonumber(v) or 0
    if v < 0 then v = v + 4294967296 end
    return v
end

local MODEL_MALE   = u32hash(Utils.Joaat("mp_m_freemode_01"))
local MODEL_FEMALE = u32hash(Utils.Joaat("mp_f_freemode_01"))

-- Resolve natives via namespace when present, raw invoke otherwise.
local function nat(nsName, fnName, hash, invoker)
    local ok, ns = pcall(function() return _G[nsName] end)
    local fn = ok and ns and ns[fnName]
    if type(fn) == "function" then return fn end
    return function(...) return invoker(hash, ...) end
end

local N_PLAYER_PED_ID = nat("PLAYER", "PLAYER_PED_ID", 0xD80958FC74E988A6, Natives.InvokeInt)
local N_GET_MODEL     = nat("ENTITY", "GET_ENTITY_MODEL", 0x9F47B058362C84B5, Natives.InvokeInt)
local N_SET_COMP      = nat("PED", "SET_PED_COMPONENT_VARIATION", 0x262B14F48D29DE80, Natives.InvokeVoid)
local N_GET_DRAW      = nat("PED", "GET_PED_DRAWABLE_VARIATION", 0x67F3780DD425D4FC, Natives.InvokeInt)
local N_GET_TEX       = nat("PED", "GET_PED_TEXTURE_VARIATION", 0x04A355E041E004E6, Natives.InvokeInt)
local N_NUM_DRAW      = nat("PED", "GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS", 0x27561561732A7842, Natives.InvokeInt)
local N_NUM_TEX       = nat("PED", "GET_NUMBER_OF_PED_TEXTURE_VARIATIONS", 0x8F7156A3142A6BAD, Natives.InvokeInt)
local N_GET_PROP      = nat("PED", "GET_PED_PROP_INDEX", 0x898CC20EA75BACD8, Natives.InvokeInt)
local N_GET_PROP_TEX  = nat("PED", "GET_PED_PROP_TEXTURE_INDEX", 0xE131A28626F81AB2, Natives.InvokeInt)
local N_SET_PROP      = nat("PED", "SET_PED_PROP_INDEX", 0x93376B65A266EB5F, Natives.InvokeVoid)
local N_CLEAR_PROP    = nat("PED", "CLEAR_PED_PROP", 0x0943E5B8E078E76E, Natives.InvokeVoid)
local N_NUM_PROP_DRAW = nat("PED", "GET_NUMBER_OF_PED_PROP_DRAWABLE_VARIATIONS", 0x5FAF9754E789FB47, Natives.InvokeInt)
local N_NUM_PROP_TEX  = nat("PED", "GET_NUMBER_OF_PED_PROP_TEXTURE_VARIATIONS", 0xA6E7F1CEB523E171, Natives.InvokeInt)

-- ----------------------------------------------------------------------------
-- Texture loading pump. Texture.* calls throw when made from the render
-- thread (the b8 log showed every load failing plus exception spam), so all
-- loading happens here on the game thread; the render side only enqueues
-- requests and draws entries once they reach "ready".
-- ----------------------------------------------------------------------------

local texQueue     = {}   -- entries waiting for LoadTextureAsync
local texLoading   = {}   -- entries waiting to become valid
local texErrLogged = 0
local dlBroken     = 0    -- in-game downloaded files that failed to load
                          -- (Cherax text-mode writes corrupt binary)

local function texLogErr(what, detail, path)
    if texErrLogged < 4 then
        texErrLogged = texErrLogged + 1
        Logger.LogInfo(("[%s] %s: %s | %s")
            :format(SCRIPT_NAME, what, tostring(detail), tostring(path)))
    end
end

local function pumpTextures()
    -- start a few queued loads per tick, keep in-flight count bounded
    local started = 0
    while #texQueue > 0 and started < 4 and #texLoading < 12 do
        local t = table.remove(texQueue, 1)
        if t.st == "queued" then
            local ok, ret = pcall(Texture.LoadTextureAsync, t.path)
            if ok and ret ~= nil then
                t.texId, t.loadStart, t.st = ret, os.clock(), "loading"
                texLoading[#texLoading + 1] = t
            else
                t.st, t.failAt = "failed", os.clock()
                texLogErr("LoadTextureAsync failed", ret, t.path)
            end
            started = started + 1
        end
    end

    -- poll in-flight loads
    for i = #texLoading, 1, -1 do
        local t = texLoading[i]
        local okV, valid = pcall(Texture.IsTextureValid, t.texId)
        if okV and valid then
            local okG, tex = pcall(Texture.GetTexture, t.texId)
            if okG and tex then
                t.tex, t.st, t.appear = tex, "ready", 0.0
            else
                t.st, t.failAt = "failed", os.clock()
                texLogErr("GetTexture failed", tex, t.path)
            end
            table.remove(texLoading, i)
        elseif not okV then
            t.st, t.failAt = "failed", os.clock()
            texLogErr("IsTextureValid failed", valid, t.path)
            table.remove(texLoading, i)
        elseif (os.clock() - (t.loadStart or 0)) > 10.0 then
            t.st, t.failAt = "failed", os.clock()
            if t.wasDownloaded then
                pcall(FileMgr.DeleteFile, t.path)
                dlBroken = dlBroken + 1
            end
            table.remove(texLoading, i)
        end
    end
end

-- ped preview draw request, filled by the render side each frame and executed
-- here on the game thread (steadier pacing, no cross-thread flicker)
local pvDrawReq = { stamp = 0 }

-- forward-declared: the asset bootstrap lives after the thumbnail manager
-- (it needs newDownload), but the worker has to tick it
local bootstrapTick

local function workerTick()
    pumpTextures()
    if bootstrapTick then pcall(bootstrapTick) end

    -- draw the ped preview while the request is fresh (window open + settled)
    if pvDrawReq.stamp > 0 and (os.clock() - pvDrawReq.stamp) < 0.15 and V2New then
        local pedObj = GTA.GetLocalPed()
        if pedObj then
            pcall(GTA.DrawPedPreview, pedObj,
                V2New(pvDrawReq.cx, pvDrawReq.cy),
                V2New(pvDrawReq.w, pvDrawReq.h),
                pvDrawReq.zoom, 0.0, pvDrawReq.yaw, 1.0)
        end
    end

    local handle = N_PLAYER_PED_ID()
    if handle == nil or handle == 0 then ped.valid = false return end

    local model = u32hash(N_GET_MODEL(handle))
    if handle ~= ped.handle or model ~= ped.modelHash then
        ped.handle, ped.modelHash = handle, model
        ped.gender = (model == MODEL_MALE and "male")
            or (model == MODEL_FEMALE and "female") or nil
        ped.comps, ped.texCounts = {}, {}
        wantRefresh = true
        Logger.LogInfo(("[%s] ped detected: model=%.0f gender=%s")
            :format(SCRIPT_NAME, model, tostring(ped.gender)))
    end

    -- queued outfit ops first (compId >= 100 means prop anchor compId - 100)
    while #opQueue > 0 do
        local op = table.remove(opQueue, 1)
        if op.comp >= 100 then
            local anchor = op.comp - 100
            if op.draw < 0 then
                N_CLEAR_PROP(handle, anchor)
            else
                N_SET_PROP(handle, anchor, op.draw, math.max(op.tex, 0), true)
            end
        else
            N_SET_COMP(handle, op.comp, op.draw, op.tex, 0)
        end
        local c = ped.comps[op.comp]
        if c then c.drawable, c.tex = op.draw, op.tex end
    end

    if restoreReq and snapshot then
        for compId, s in pairs(snapshot) do
            if compId >= 100 then
                if s.drawable < 0 then
                    N_CLEAR_PROP(handle, compId - 100)
                else
                    N_SET_PROP(handle, compId - 100, s.drawable, math.max(s.tex, 0), true)
                end
            else
                N_SET_COMP(handle, compId, s.drawable, s.tex, 0)
            end
            local c = ped.comps[compId]
            if c then c.drawable, c.tex = s.drawable, s.tex end
        end
        restoreReq = false
    end

    if wantRefresh then
        for _, comp in ipairs(COMPONENTS) do
            local cid = comp.id
            if comp.prop ~= nil then
                ped.comps[cid] = {
                    drawable  = N_GET_PROP(handle, comp.prop),
                    tex       = N_GET_PROP_TEX(handle, comp.prop),
                    drawCount = N_NUM_PROP_DRAW(handle, comp.prop),
                }
            else
                ped.comps[cid] = {
                    drawable  = N_GET_DRAW(handle, cid),
                    tex       = N_GET_TEX(handle, cid),
                    drawCount = N_NUM_DRAW(handle, cid),
                }
            end
        end
        wantRefresh = false
        ped.valid = true
    end

    -- texture-count scans (one component per tick to stay light)
    local cid = next(wantCounts)
    if cid ~= nil then
        wantCounts[cid] = nil
        local info = ped.comps[cid]
        if info then
            local counts = {}
            for d = 0, info.drawCount - 1 do
                counts[d] = (cid >= 100) and N_NUM_PROP_TEX(handle, cid - 100, d)
                    or N_NUM_TEX(handle, cid, d)
            end
            ped.texCounts[cid] = counts
        end
    end

    if wantSnapshot and ped.valid then
        snapshot = {}
        for _, comp in ipairs(COMPONENTS) do
            local c = ped.comps[comp.id]
            if c then snapshot[comp.id] = { drawable = c.drawable, tex = c.tex } end
        end
        wantSnapshot = false
    end
end

FeatureMgr.AddFeature(H.WORKER, "LiquidFit Worker", eFeatureType.Toggle,
    "Internal native-thread worker - keep enabled.", function()
        if staleInstance() then return end
        local ok, err = pcall(workerTick)
        if not ok then
            ped.workerErr = tostring(err)
            if (ped.workerErrAt or 0) < os.clock() then
                ped.workerErrAt = os.clock() + 5
                Logger.LogInfo("[" .. SCRIPT_NAME .. "] worker error: " .. tostring(err))
            end
        else
            ped.workerErr = nil
        end
    end, true)
    :SetVisible(false):SetSaveable(false):SetBoolValue(true)
    :RegisterCallbackTrigger(eCallbackTrigger.OnTick)

local function applyVariation(compId, drawable, tex)
    table.insert(opQueue, { comp = compId, draw = drawable, tex = tex })
end

-- Roll a completely random look from the cached drawable counts. Does not
-- touch the snapshot, so Revert brings the previous outfit straight back.
math.randomseed(math.floor(os.clock() * 100000) + os.time())

local function randomizeOutfit()
    if not ped.valid then return end
    for _, comp in ipairs(COMPONENTS) do
        local info = ped.comps[comp.id]
        if info and info.drawCount and info.drawCount > 0 then
            if comp.prop ~= nil then
                -- props roll "nothing" more often than not so random fits
                -- don't always end up wearing five accessories at once
                if math.random() < 0.45 then
                    applyVariation(comp.id, math.random(0, info.drawCount - 1), 0)
                else
                    applyVariation(comp.id, -1, -1)
                end
            else
                applyVariation(comp.id, math.random(0, info.drawCount - 1), 0)
            end
        end
    end
    lfToast("Randomized", "New look rolled. Revert brings the old one back.")
end

-- ============================================================================
-- Thumbnail manager
-- ============================================================================

local thumbs   = {}   -- key -> { st, tex (D3D12Texture), texId, curl, path, tries }
local dlActive = 0
local dlFails  = 0    -- total failed downloads this session
local dlLogged = 0    -- how many failures we've logged in detail

local function downloadsBlocked()
    return dlBroken >= 3
end

-- Which curl option makes the response stream STRAIGHT TO DISK (binary safe,
-- unlike text-mode WriteFileContent). Cherax's enum values are remapped and
-- undocumented, so a 1KB probe download at load discovers the right one:
-- nil = probe still running, false = neither option works on this build,
-- otherwise the eCurlOption value to use.
local dlWriteOpt = nil

local function newDownload(url, outPath, optOverride)
    local c = Curl.Easy()
    c:Setopt(eCurlOption.CURLOPT_URL, url)
    c:Setopt(eCurlOption.CURLOPT_USERAGENT, "LiquidFit/1.0")
    -- the game process has no CA bundle; without these, every HTTPS request
    -- can fail certificate verification
    c:Setopt(eCurlOption.CURLOPT_SSL_VERIFYPEER, 0)
    c:Setopt(eCurlOption.CURLOPT_SSL_VERIFYHOST, 0)
    if outPath then
        -- Cherax opens the WRITEDATA target in a mode that seems to require
        -- the file to ALREADY EXIST ("Failed to open the file" on every
        -- fresh path, curl write error 23). Pre-create it empty so the open
        -- succeeds; failed downloads still get sniffed and deleted after.
        if not FileMgr.DoesFileExist(outPath) then
            pcall(FileMgr.WriteFileContent, outPath, "", false)
        end
        c:Setopt(optOverride or dlWriteOpt or eCurlOption.CURLOPT_WRITEDATA, outPath)
    end
    c:DisableErrorLog()
    c:Perform()
    return c
end

local function logDownloadFailure(what, url, code, body)
    dlFails = dlFails + 1
    if dlLogged < 5 then
        dlLogged = dlLogged + 1
        local head = body and body:sub(1, 80):gsub("[%c]", ".") or "<nil>"
        Logger.LogInfo(("[%s] download failed (%s) code=%s len=%s body: %s | url: %s")
            :format(SCRIPT_NAME, what, tostring(code), tostring(body and #body or 0), head, url))
    end
end

-- Categories ShortByte lacks (props, bags, armor, torso, vest) stream from
-- SheiylaDev instead: clothes_<cat>/<gender>/<globalDrawable>_<tex>.webp
local SHEIYLA_CATS = {
    [3] = "clothes_arms", [5] = "clothes_bag", [9] = "clothes_vest",
    [100] = "clothes_hat", [101] = "clothes_glasses", [102] = "clothes_ears",
    [106] = "clothes_watch", [107] = "clothes_bracelet",
}

local function thumbSourceUrl(comp, gender, drawable, tex)
    if comp.imgCat then
        local seg
        if comp.unisex then
            seg = comp.imgCat .. "/" .. drawable .. "/" .. tex .. ".webp"
        else
            if gender == nil then return nil end
            seg = comp.imgCat .. "/" .. gender .. "/" .. drawable .. "/" .. tex .. ".webp"
        end
        return "https://raw.githubusercontent.com/ShortByte/GTA5-Cloth-Assets/master/assets/" .. seg
    end
    local sd = SHEIYLA_CATS[comp.id]
    if sd and gender then
        return "https://raw.githubusercontent.com/SheiylaDev/gta5-clothing-images/main/"
            .. sd .. "/" .. gender .. "/" .. drawable .. "_" .. tex .. ".webp"
    end
    return nil
end

local function thumbUrl(comp, gender, drawable, tex)
    local raw = thumbSourceUrl(comp, gender, drawable, tex)
    if raw == nil then return nil end
    if fOn(H.USEPROXY) then
        return "https://wsrv.nl/?url=" .. urlencode(raw) .. "&w=160&h=160&fit=contain&output=png"
    end
    return raw
end

local function thumbKey(comp, gender, drawable, tex)
    return (comp.unisex and "u" or (gender or "x")) .. comp.id .. "_" .. drawable .. "_" .. tex
end

-- Cache files are ALWAYS .png regardless of settings; the proxy toggle only
-- affects the download URL. (Tying the extension to the toggle once made the
-- whole cache invisible when the toggle was flipped.)
local function thumbPath(key)
    return CACHEDIR .. key .. ".png"
end

-- Image coverage per category: which drawables have a cached texture-0 thumb.
-- Built once per comp+gender (single DoesFileExist sweep), used by the
-- Hide Empty Items filter.
local coverage = {}

local function coverageFor(comp, gender, drawCount)
    local ck = (comp.unisex and "u" or (gender or "x")) .. comp.id
    local c = coverage[ck]
    if c then return c end
    c = {}
    if comp.imgCat or comp.hasImages then
        for d = 0, drawCount - 1 do
            local key = thumbKey(comp, gender, d, 0)
            if FileMgr.DoesFileExist(CACHEDIR .. key .. ".png") then
                c[d] = true
            end
        end
    end
    coverage[ck] = c
    return c
end

-- Advance one thumb through its lifecycle. Returns entry.
local function ensureThumb(comp, gender, drawable, tex)
    local key = thumbKey(comp, gender, drawable, tex)
    local t = thumbs[key]
    if t == nil then
        t = { st = "new", tries = 0 }
        thumbs[key] = t
    end

    if t.st == "new" then
        local path = thumbPath(key)
        if FileMgr.DoesFileExist(path) then
            -- hand off to the game-thread texture pump
            t.path = path
            t.st = "queued"
            texQueue[#texQueue + 1] = t
        else
            local url = thumbUrl(comp, gender, drawable, tex)
            if url == nil then
                t.st = "noimage"
            elseif dlWriteOpt == false or downloadsBlocked() then
                t.st = "missing"   -- this Cherax build cannot download binaries
            elseif dlWriteOpt ~= nil and dlActive < MAX_DOWNLOADS then
                t.curl, t.path, t.url, t.st = newDownload(url, path), path, url, "downloading"
                dlActive = dlActive + 1
            end
            -- else: probe still running or no slot free; stay "new" and retry
        end

    elseif t.st == "downloading" then
        if t.curl and t.curl:GetFinished() then
            dlActive = math.max(0, dlActive - 1)
            local code
            pcall(function() code = t.curl:GetResponse() end)
            t.curl = nil
            -- the FILE decides success, not the response code (which is not
            -- reliable with a custom writer): sniff the PNG magic to reject
            -- 404 bodies (text-mode read returns the first bytes, plenty)
            local head = ""
            pcall(function()
                head = (FileMgr.ReadFileContent(t.path) or ""):sub(1, 8)
            end)
            if head:find("PNG", 1, true) then
                t.wasDownloaded = true
                t.st = "queued"
                texQueue[#texQueue + 1] = t
            else
                pcall(FileMgr.DeleteFile, t.path)
                t.st = "missing"   -- 404 or bad payload: draw fallback tile
                logDownloadFailure("thumb", t.url or "?", code, head)
            end
        end

    elseif t.st == "failed" then
        -- one gentle retry for cache files (texture backend may have been busy)
        if not t.wasDownloaded and (t.tries or 0) < 1
            and t.failAt and (os.clock() - t.failAt) > 6.0 then
            t.tries = (t.tries or 0) + 1
            t.st = "queued"
            texQueue[#texQueue + 1] = t
        end
    end
    -- "queued" and "loading" advance on the worker thread (pumpTextures)

    return t
end

-- One-time diagnostics: probe the cache at load so the log shows exactly what
-- the texture pipeline sees, plus a periodic state summary while nothing loads.
local probePath = CACHEDIR .. "male11_0_0.png"
local CACHE_PRESENT = FileMgr.DoesFileExist(probePath)
Logger.LogInfo(("[%s] cache probe: %s exists=%s")
    :format(SCRIPT_NAME, probePath, tostring(CACHE_PRESENT)))

local function thumbStateSummary()
    local counts = {}
    for _, t in pairs(thumbs) do
        counts[t.st] = (counts[t.st] or 0) + 1
    end
    local parts = {}
    for k, v in pairs(counts) do parts[#parts + 1] = k .. "=" .. v end
    table.sort(parts)
    return table.concat(parts, " ")
end

local lastSummaryAt = 0
local function maybeLogThumbStates()
    local now = os.clock()
    if now - lastSummaryAt < 5.0 then return end
    lastSummaryAt = now
    local counts = { ready = 0, total = 0 }
    for _, t in pairs(thumbs) do
        counts.total = counts.total + 1
        if t.st == "ready" then counts.ready = counts.ready + 1 end
    end
    if counts.total > 0 and counts.ready == 0 then
        Logger.LogInfo(("[%s] no textures ready yet: %s")
            :format(SCRIPT_NAME, thumbStateSummary()))
    end
end

-- ---- category icons (lucide SVGs -> white PNGs via wsrv.nl) ----
-- White glyphs on transparent, tinted at draw time via the image color.

local icons = {}   -- name -> { st, tex, texId, curl, path }

local function ensureIcon(name)
    if name == nil then return nil end
    local t = icons[name]
    if t == nil then
        t = { st = "new" }
        icons[name] = t
    end

    if t.st == "new" then
        local path = ICONDIR .. name .. ".png"
        if FileMgr.DoesFileExist(path) then
            t.path = path
            t.st = "queued"
            texQueue[#texQueue + 1] = t
        elseif dlWriteOpt == false or downloadsBlocked() then
            t.st = "missing"
        elseif dlWriteOpt ~= nil and dlActive < MAX_DOWNLOADS then
            local raw = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/"
                .. name .. ".svg"
            local url = "https://wsrv.nl/?url=" .. urlencode(raw)
                .. "&w=48&h=48&output=png&filt=negate"
            t.curl, t.path, t.url, t.st = newDownload(url, path), path, url, "downloading"
            dlActive = dlActive + 1
        end

    elseif t.st == "downloading" then
        if t.curl and t.curl:GetFinished() then
            dlActive = math.max(0, dlActive - 1)
            local code
            pcall(function() code = t.curl:GetResponse() end)
            t.curl = nil
            local head = ""
            pcall(function()
                head = (FileMgr.ReadFileContent(t.path) or ""):sub(1, 8)
            end)
            if head:find("PNG", 1, true) then
                t.wasDownloaded = true
                t.st = "queued"
                texQueue[#texQueue + 1] = t
            else
                pcall(FileMgr.DeleteFile, t.path)
                t.st = "missing"
                logDownloadFailure("icon", t.url or "?", code, head)
            end
        end
    end
    -- "queued" and "loading" advance on the worker thread (pumpTextures)

    return t
end

-- The script logo (Lua/LiquidFit/Logo.png), loaded through the same
-- game-thread texture pump as everything else. Shown in the About view.
local logoEntry = nil
local function ensureLogo()
    if logoEntry == nil then
        local path = SCRIPTDIR .. "Logo.png"
        if FileMgr.DoesFileExist(path) then
            logoEntry = { st = "queued", path = path }
            texQueue[#texQueue + 1] = logoEntry
        else
            logoEntry = { st = "missing" }
        end
    end
    return logoEntry
end

-- ============================================================================
-- First-launch asset bootstrap. The Cherax site distributes only this .lua,
-- so names, icons, and the logo arrive from GitHub on first run: curl writes
-- a rooted zip natively to disk (binary safe), FileMgr.Unzip extracts it over
-- the Cherax folder. The optional full preview pack uses the same machinery.
-- If the zip path fails, item names still arrive as plain text downloads.
-- ============================================================================

local ASSETS_BASE = "https://raw.githubusercontent.com/imoliverokay/LiquidFit/main/assets/"
local THUMB_PARTS = 5
local TEXT_NAMES = { "names_male.lua", "names_female.lua" }

local boot = {
    st = "idle",   -- idle|downloading|unzipping|textstart|textdl|done|failed
    what = nil,    -- "essentials" | "pack"
    packPart = 0,
    textIdx = 1,
}

local function assetsMissing()
    return not FileMgr.DoesFileExist(SCRIPTDIR .. "names_male.lua")
end

-- The 1KB probe that checks whether curl-write-to-disk works on this Cherax
-- build. ONLY CURLOPT_WRITEDATA is ever tried: setting CURLOPT_WRITEFUNCTION
-- to a string hard-crashes the game (libcurl treats it as a C function
-- pointer), which build 24 learned the hard way. Success is verified by
-- reading the file back, never by trusting the response code.
local PROBE_PATH = ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\probe.png"
local probe = { st = "start" }

local function bootLaunch(what, url, zipName)
    boot.what = what
    boot.zipPath = ROOT .. "Cache\\" .. SCRIPT_NAME .. "\\" .. zipName
    pcall(FileMgr.DeleteFile, boot.zipPath)
    local ok, c = pcall(newDownload, url, boot.zipPath)
    if ok and c then
        boot.curl, boot.st = c, "downloading"
    else
        boot.st = (what == "essentials") and "textstart" or "failed"
    end
end

local function bootStart(what, url, zipName)
    if dlWriteOpt == nil then
        -- probe still running: queue the request, the probe dispatches it
        boot.pending = { what = what, url = url, zip = zipName }
        boot.st = "downloading"   -- so the footer shows progress already
        return
    end
    if dlWriteOpt == false then
        if what == "essentials" then
            boot.st = "textstart"
        else
            boot.st = "failed"
            lfToast("Not supported", "Cherax cannot download images in-game. Use Get Preview Pack for the browser link.")
        end
        return
    end
    bootLaunch(what, url, zipName)
end

bootstrapTick = function()
    -- ---- capability probe (runs once, before any real download) ----
    if probe.st == "start" then
        pcall(FileMgr.DeleteFile, PROBE_PATH)
        local ok, c = pcall(newDownload, ASSETS_BASE .. "probe.png", PROBE_PATH,
            eCurlOption.CURLOPT_WRITEDATA)
        if ok and c then
            probe.curl, probe.st = c, "wait"
        else
            probe.st = "done"
            dlWriteOpt = false
        end
        return
    elseif probe.st == "wait" and probe.curl then
        local fin = false
        pcall(function() fin = probe.curl:GetFinished() end)
        if not fin then return end
        pcall(function() probe.code = probe.curl:GetResponse() end)
        probe.curl = nil
        probe.settleAt = os.clock() + 1.0
        probe.st = "settle"
        return
    elseif probe.st == "settle" then
        if os.clock() < (probe.settleAt or 0) then return end
        local head = ""
        pcall(function()
            head = (FileMgr.ReadFileContent(PROBE_PATH) or ""):sub(1, 8)
        end)
        if head:find("PNG", 1, true) then
            dlWriteOpt = eCurlOption.CURLOPT_WRITEDATA
            probe.st = "done"
            pcall(FileMgr.DeleteFile, PROBE_PATH)
            Logger.LogInfo(("[%s] binary probe OK (curl write-to-disk works)")
                :format(SCRIPT_NAME))
        else
            dlWriteOpt = false
            probe.st = "done"
            Logger.LogInfo(("[%s] binary probe FAILED (code=%s head=%s). Image downloads disabled; names use text fallback.")
                :format(SCRIPT_NAME, tostring(probe.code),
                    (head:gsub("%c", "?"))))
        end
        -- probe resolved: dispatch anything that queued behind it
        if boot.pending then
            local p = boot.pending
            boot.pending = nil
            boot.st = "idle"
            bootStart(p.what, p.url, p.zip)
        end
        return
    end

    if boot.st == "downloading" and boot.curl then
        local fin = false
        pcall(function() fin = boot.curl:GetFinished() end)
        if not fin then return end
        pcall(function() boot.code = boot.curl:GetResponse() end)
        boot.curl = nil
        boot.settleAt = os.clock() + 1.0
        boot.st = "settle"

    elseif boot.st == "settle" then
        -- give the native side a beat to close the file, then judge by disk
        if os.clock() < (boot.settleAt or 0) then return end
        if FileMgr.DoesFileExist(boot.zipPath) then
            boot.st = "unzipping"
        else
            Logger.LogInfo(("[%s] bootstrap: no file on disk after download (what=%s code=%s url part=%s)")
                :format(SCRIPT_NAME, tostring(boot.what), tostring(boot.code), tostring(boot.packPart)))
            if boot.what == "essentials" then
                boot.st = "textstart"
            else
                boot.st = "failed"
                lfToast("Download failed", "Preview pack part " .. boot.packPart .. " did not arrive. See the log.")
            end
        end

    elseif boot.st == "unzipping" then
        local ok, res = pcall(FileMgr.Unzip, boot.zipPath, ROOT:sub(1, -2))
        pcall(FileMgr.DeleteFile, boot.zipPath)
        local good = ok and res ~= false
        if not good then
            Logger.LogInfo(("[%s] bootstrap: unzip failed (what=%s ok=%s res=%s code=%s)")
                :format(SCRIPT_NAME, tostring(boot.what), tostring(ok), tostring(res), tostring(boot.code)))
        end
        if boot.what == "essentials" then
            if good and FileMgr.DoesFileExist(SCRIPTDIR .. "names_male.lua") then
                namesCache = {}
                boot.st = "done"
                lfToast("LiquidFit ready", "Assets installed. Enjoy the studio.")
            else
                boot.st = "textstart"
            end
        else
            coverage = {}
            if good and boot.packPart < THUMB_PARTS then
                local nextPart = boot.packPart + 1
                lfToast("Preview pack", "Part " .. boot.packPart .. " of " .. THUMB_PARTS .. " installed.")
                boot.packPart = nextPart
                bootStart("pack", ASSETS_BASE .. "thumbs_part" .. nextPart .. ".zip", "pack.zip")
            elseif good then
                boot.st = "done"
                thumbs = {}
                lfToast("Preview pack installed", "Every preview image is now local.")
            else
                boot.st = "failed"
                lfToast("Install failed", "Could not extract the preview pack.")
            end
        end

    elseif boot.st == "textstart" then
        local fname = TEXT_NAMES[boot.textIdx]
        if fname == nil then
            namesCache = {}
            boot.st = "done"
            lfToast("LiquidFit ready", "Name data installed. Previews stream in as you browse.")
            return
        end
        local ok, c = pcall(newDownload, ASSETS_BASE .. fname)
        if ok and c then
            boot.curl, boot.st = c, "textdl"
        else
            boot.st = "failed"
        end

    elseif boot.st == "textdl" and boot.curl then
        local fin = false
        pcall(function() fin = boot.curl:GetFinished() end)
        if not fin then return end
        local code, body
        pcall(function() code, body = boot.curl:GetResponse() end)
        boot.curl = nil
        if code == eCurlCode.CURLE_OK and body and #body > 1000 and body:sub(1, 2) == "--" then
            FileMgr.WriteFileContent(SCRIPTDIR .. TEXT_NAMES[boot.textIdx], body, false)
            boot.textIdx = boot.textIdx + 1
            boot.st = "textstart"
        else
            boot.st = "failed"
            lfToast("Setup failed", "Could not download name data. See the log.")
            Logger.LogInfo(("[%s] bootstrap text fallback failed, code=%s len=%s")
                :format(SCRIPT_NAME, tostring(code), tostring(body and #body or 0)))
        end
    end
end

-- Browser link for the pack: an install page with the download and step by
-- step instructions (github release URLs redirect, which in-game curl cannot
-- follow, but browsers do not care).
local PACK_URL = "https://liquidfit.vercel.app"

local function copyPackLink()
    local okC = pcall(Utils.SetClipBoardText, PACK_URL)
    if not okC then okC = pcall(ImGui.SetClipboardText, PACK_URL) end
    Logger.LogInfo(("[%s] preview pack install page: %s")
        :format(SCRIPT_NAME, PACK_URL))
    if okC then
        lfToast("Link copied", "Open it in your browser for the download and install steps.")
    else
        lfToast("Preview pack", "The install page link is in the Cherax log.")
    end
end

H.GETPACK = h("GetPack")
FeatureMgr.AddFeature(H.GETPACK, "Get Preview Pack", eFeatureType.Button,
    "All 27,000+ preview images (~360 MB). Installs in-game when this Cherax build supports downloads; otherwise copies a link to the install page with the download and step by step instructions.", function()
        if dlWriteOpt == false then
            copyPackLink()
            return
        end
        if boot.st == "downloading" or boot.st == "unzipping" then
            lfToast("Busy", "A download is already running.")
            return
        end
        boot.packPart = 1
        bootStart("pack", ASSETS_BASE .. "thumbs_part1.zip", "pack.zip")
        if boot.st == "downloading" then
            lfToast("Preview pack", "Downloading part 1 of " .. THUMB_PARTS .. "...")
        end
    end)

local function clearThumbCache()
    local files = FileMgr.FindFiles(CACHEDIR, "", false) or {}
    local n = 0
    for _, f in ipairs(files) do
        FileMgr.DeleteFile(f)
        n = n + 1
    end
    thumbs = {}
    coverage = {}
    if lfToast then
        lfToast("Cache cleared", n .. " cached thumbnails removed")
    end
end

FeatureMgr.AddFeature(H.CLEARCACHE, "Clear Thumbnail Cache", eFeatureType.Button,
    "Delete all downloaded thumbnails. They re-download as you browse.", function()
        pcall(clearThumbCache)
    end)

-- ============================================================================
--- UI state
-- ============================================================================

local ui = {
    anim        = 0.0,           -- open/close master alpha
    pos         = { x = -1, y = -1 },
    view        = "grid",        -- "grid" | "outfits" | "about"
    outfitName  = "",
    selComp     = 3,             -- index into COMPONENTS (Top by default)
    railAnim    = {},            -- per-index hover/select anim
    pillY       = 0,             -- sliding selection pill
    pillInit    = false,
    grid        = { scrollTo = -1, fade = 1.0, switching = false, pendingComp = nil },
    cellAnim    = {},            -- "draw" -> {hover, appear}
    stripAnim   = {},            -- tex -> {hover}
    search      = "",
    yaw         = 0.0,
    yawVel      = 0.0,
    dragActive  = false,
    lastTime    = nil,
    wasOpen     = false,
    hint        = nil,
    hintTime    = 0,
}

FeatureMgr.AddFeature(H.RESETPOS, "Reset Window Position", eFeatureType.Button,
    "Bring the LiquidFit window back to the center of the screen.", function()
        ui.pos.x, ui.pos.y = -1, -1
        FeatureMgr.GetFeature(H.POSX):SetValue(-1.0)
        FeatureMgr.GetFeature(H.POSY):SetValue(-1.0)
    end)

local function currentComp() return COMPONENTS[ui.selComp] end

local function switchComp(idx)
    if idx == ui.selComp or ui.grid.switching then return end
    ui.grid.switching = true
    ui.grid.pendingComp = idx
end

-- ============================================================================
-- Drawing helpers (current-window draw list, screen coords)
-- ============================================================================

local function glassPanel(x1, y1, x2, y2, rounding, tintA)
    tintA = tintA or 34
    ImGui.AddRectFilled(x1, y1, x2, y2, COL.panel[1], COL.panel[2], COL.panel[3], tintA, rounding)
    ImGui.AddRect(x1, y1, x2, y2, 210, 230, 255, 26, rounding, 0, 1.0)
end

local function glowRect(x1, y1, x2, y2, r, g, b, strength, radius, rounding)
    if strength <= 0 then return end
    for i = 1, 3 do
        local f = i / 3
        local pad = radius * f
        local a = math.floor(150 * strength * (1 - f) * (1 - f) + 0.5)
        if a > 0 then
            ImGui.AddRectFilled(x1 - pad, y1 - pad, x2 + pad, y2 + pad,
                r, g, b, a, (rounding or 6) + pad)
        end
    end
end

local function textClipped(x, y, maxW, str, r, g, b, a)
    local w = ImGui.CalcTextSize(str)
    while w > maxW and #str > 3 do
        str = str:sub(1, #str - 4) .. ".."
        w = ImGui.CalcTextSize(str)
    end
    ImGui.AddText(x, y, str, r, g, b, a)
    return w
end

local function centerText(x1, x2, y, str, r, g, b, a)
    local w = ImGui.CalcTextSize(str)
    ImGui.AddText((x1 + x2 - w) * 0.5, y, str, r, g, b, a)
end

-- Small reusable glass button; anim state lives in ui[stateKey].
-- Optional hint shows a native tooltip on hover.
-- (Defined up here with the helpers: it must exist BEFORE drawRail and
-- friends are defined, or their upvalue binding silently resolves to nil.)
local function glassButton(stateKey, label, bx1, by1, bw, bh, accent, alpha, wx, wy, hint)
    ImGui.SetCursorPos(bx1 - wx, by1 - wy)
    local clicked = ImGui.InvisibleButton("##" .. stateKey, bw, bh)
    local hov = ImGui.IsItemHovered()
    if hov and hint then pcall(ImGui.SetTooltip, hint) end
    ui[stateKey] = damp(ui[stateKey] or 0, hov and 1 or 0, 14, ui.dt)
    local hv = ui[stateKey]
    local r, g, b = accent[1], accent[2], accent[3]
    if hv > 0.01 then
        glowRect(bx1, by1, bx1 + bw, by1 + bh, r, g, b, 0.3 * hv * alpha, 5, 8)
    end
    ImGui.AddRectFilled(bx1, by1, bx1 + bw, by1 + bh,
        r, g, b, math.floor((50 + 60 * hv) * alpha), 8)
    ImGui.AddRect(bx1, by1, bx1 + bw, by1 + bh,
        r, g, b, math.floor((90 + 80 * hv) * alpha), 8, 0, 1.0)
    if label ~= "" then
        centerText(bx1, bx1 + bw, by1 + (bh - 16) * 0.5, label,
            COL.text[1], COL.text[2], COL.text[3], math.floor(235 * alpha))
    end
    return clicked
end

-- ImDrawFlags corner rounding masks
local DF_TOP, DF_BOT = 48, 192

-- The ped preview area: a real hole in the window so the game-layer preview
-- shows through. Full height of the right column (portrait shape fits the
-- character), leaving room for the rotate controls underneath.
local function previewRect(wx, wy)
    local x1 = wx + WIN_W - RIGHT_W - PAD
    local y1 = wy + TITLE_H + PAD
    local x2 = wx + WIN_W - PAD
    local y2 = wy + WIN_H - FOOTER_H - PAD - PVCTRL_H
    return x1, y1, x2, y2
end

-- Fill the notches between the square hole cut and its rounded border, so the
-- preview corners are truly rounded instead of leaking tiny squares of game.
local HOLE_R = 8
local function fillHoleCorners(hx1, hy1, hx2, hy2, r, cr, cg, cb, ca)
    local corners = {
        { px = hx1, py = hy1, cx = hx1 + r, cy = hy1 + r, a0 = math.pi,       a1 = math.pi * 1.5 },
        { px = hx2, py = hy1, cx = hx2 - r, cy = hy1 + r, a0 = math.pi * 1.5, a1 = math.pi * 2.0 },
        { px = hx2, py = hy2, cx = hx2 - r, cy = hy2 - r, a0 = 0.0,           a1 = math.pi * 0.5 },
        { px = hx1, py = hy2, cx = hx1 + r, cy = hy2 - r, a0 = math.pi * 0.5, a1 = math.pi },
    }
    local SEG = 6
    for _, c in ipairs(corners) do
        local prevX, prevY
        for s = 0, SEG do
            local ang = c.a0 + (c.a1 - c.a0) * (s / SEG)
            local ax = c.cx + math.cos(ang) * r
            local ay = c.cy + math.sin(ang) * r
            if prevX then
                ImGui.AddTriangleFilled(c.px, c.py, prevX, prevY, ax, ay, cr, cg, cb, ca)
            end
            prevX, prevY = ax, ay
        end
    end
end

-- Rounded glass body with a transparent hole cut out for the ped preview.
local function drawGlassBody(wx, wy, aMul, withHole)
    local x1, y1, x2, y2 = wx, wy, wx + WIN_W, wy + WIN_H
    local br, bg, bb, ba = 52, 70, 102, math.floor(236 * aMul)

    if withHole then
        local hx1, hy1, hx2, hy2 = previewRect(wx, wy)
        ImGui.AddRectFilled(x1, y1, x2, hy1, br, bg, bb, ba, 14, DF_TOP)
        ImGui.AddRectFilled(x1, hy2, x2, y2, br, bg, bb, ba, 14, DF_BOT)
        ImGui.AddRectFilled(x1, hy1, hx1, hy2, br, bg, bb, ba, 0, 0)
        ImGui.AddRectFilled(hx2, hy1, x2, hy2, br, bg, bb, ba, 0, 0)
        fillHoleCorners(hx1, hy1, hx2, hy2, HOLE_R, br, bg, bb, ba)
    else
        ImGui.AddRectFilled(x1, y1, x2, y2, br, bg, bb, ba, 14, 0)
    end

    -- top sheen: rounded cap + fading strip (kept subtle so a light wash over
    -- the preview hole reads as glass rather than occlusion)
    ImGui.AddRectFilled(x1 + 1, y1 + 1, x2 - 1, y1 + 15,
        200, 225, 255, math.floor(20 * aMul), 14, DF_TOP)
    ImGui.AddRectFilledMultiColor(x1 + 1, y1 + 15, x2 - 1, y1 + 110,
        u32(200, 225, 255, math.floor(20 * aMul)),
        u32(200, 225, 255, math.floor(20 * aMul)),
        u32(200, 225, 255, 0),
        u32(200, 225, 255, 0))

    -- bottom depth
    ImGui.AddRectFilledMultiColor(x1 + 1, y2 - 120, x2 - 1, y2 - 15,
        u32(10, 18, 34, 0),
        u32(10, 18, 34, 0),
        u32(10, 18, 34, math.floor(30 * aMul)),
        u32(10, 18, 34, math.floor(30 * aMul)))
    ImGui.AddRectFilled(x1 + 1, y2 - 15, x2 - 1, y2 - 1,
        10, 18, 34, math.floor(30 * aMul), 14, DF_BOT)

    -- outer border
    ImGui.AddRect(x1, y1, x2, y2, 210, 230, 255, math.floor(70 * aMul), 14, 0, 1.0)
end

-- ============================================================================
-- Custom toasts: Liquid Glass styled, bottom-right, slide + fade. Drawn on the
-- background draw list so they show even when the LiquidFit window is closed.
-- ============================================================================

local toasts = {}   -- { title, msg, born, y (damped stack offset) }
local TOAST_LIFE = 4.2

function lfToast(title, msg)
    table.insert(toasts, { title = title, msg = msg, born = os.clock() })
    if #toasts > 4 then table.remove(toasts, 1) end
end

local function drawToasts(dt)
    if #toasts == 0 then return end
    local now = os.clock()
    local dispW, dispH = ImGui.GetDisplaySize()
    local tw, th, gap = 280, 54, 8
    local baseX = dispW - tw - 24
    local baseY = dispH - 24

    -- prune dead toasts
    for i = #toasts, 1, -1 do
        if now - toasts[i].born > TOAST_LIFE then table.remove(toasts, i) end
    end

    local slot = 0
    for i = #toasts, 1, -1 do
        local t = toasts[i]
        local life = now - t.born
        -- ease in over 0.25s, ease out over the last 0.5s
        local aIn  = clamp(life / 0.25, 0, 1)
        aIn = 1 - (1 - aIn) * (1 - aIn)
        local aOut = clamp((TOAST_LIFE - life) / 0.5, 0, 1)
        local a = aIn * aOut

        local targetY = baseY - (slot + 1) * (th + gap)
        t.y = t.y and damp(t.y, targetY, 12, dt) or targetY
        local x = baseX + (1 - aIn) * 40

        -- soft accent glow behind the card
        for gl = 1, 2 do
            local pad = gl * 4
            ImGui.BgAddRectFilled(x - pad, t.y - pad, x + tw + pad, t.y + th + pad,
                COL.accent[1], COL.accent[2], COL.accent[3],
                math.floor(14 * a / gl), 10 + pad, 0)
        end
        -- glass card with vertical gradient
        ImGui.BgAddRectFilled(x, t.y, x + tw, t.y + th,
            44, 60, 88, math.floor(235 * a), 10, 0)
        ImGui.BgAddRectFilledMultiColor(x + 1, t.y + 1, x + tw - 1, t.y + th * 0.55,
            u32(150, 195, 245, math.floor(30 * a)),
            u32(180, 215, 255, math.floor(24 * a)),
            u32(58, 78, 110, 0),
            u32(58, 78, 110, 0))
        ImGui.BgAddRect(x, t.y, x + tw, t.y + th,
            210, 230, 255, math.floor(60 * a), 10, 0, 1.0)
        -- capsule lifetime bar with a light-to-accent gradient
        local frac = clamp(1 - life / TOAST_LIFE, 0, 1)
        local barH = (th - 12) * frac
        if barH > 4 then
            ImGui.BgAddRectFilledMultiColor(x + 5, t.y + 6, x + 9, t.y + 6 + barH,
                u32(COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], math.floor(230 * a)),
                u32(COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], math.floor(230 * a)),
                u32(COL.accent[1], COL.accent[2], COL.accent[3], math.floor(180 * a)),
                u32(COL.accent[1], COL.accent[2], COL.accent[3], math.floor(180 * a)))
            -- rounded caps (gradient rects cannot round, so cap both ends)
            ImGui.BgAddCircleFilled(x + 7, t.y + 6, 2,
                COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], math.floor(230 * a), 0)
            ImGui.BgAddCircleFilled(x + 7, t.y + 6 + barH, 2,
                COL.accent[1], COL.accent[2], COL.accent[3], math.floor(180 * a), 0)
        end
        -- text
        ImGui.BgAddText(x + 18, t.y + 9, t.title or "",
            COL.text[1], COL.text[2], COL.text[3], math.floor(250 * a))
        ImGui.BgAddText(x + 18, t.y + 28, t.msg or "",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(210 * a))

        slot = slot + 1
    end
end

-- ============================================================================
-- Window sections
-- ============================================================================

local function drawTitleBar(wx, wy, alpha)
    local x2 = wx + WIN_W
    local aMul = alpha

    -- gradient glass strip: rounded cap on top, fading gradient below
    ImGui.AddRectFilled(wx, wy, x2, wy + 14,
        165, 205, 250, math.floor(46 * aMul), 14, DF_TOP)
    ImGui.AddRectFilledMultiColor(wx, wy + 14, x2, wy + TITLE_H,
        u32(165, 205, 250, math.floor(46 * aMul)),
        u32(165, 205, 250, math.floor(46 * aMul)),
        u32(58, 78, 110, 0),
        u32(58, 78, 110, 0))
    ImGui.AddLine(wx + 8, wy + TITLE_H, x2 - 8, wy + TITLE_H,
        200, 225, 255, math.floor(50 * aMul), 1.0)

    -- brand
    local title = "L I Q U I D F I T"
    ImGui.AddText(wx + PAD + 6, wy + 8, title,
        COL.text[1], COL.text[2], COL.text[3], math.floor(255 * aMul))
    ImGui.AddText(wx + PAD + 6, wy + 26, "outfit studio  |  by oli",
        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(200 * aMul))

    -- close button
    local sz = 22
    local cx1, cy1 = x2 - sz - 12, wy + (TITLE_H - sz) * 0.5
    ImGui.SetCursorPos(cx1 - wx, cy1 - wy)
    local clicked = ImGui.InvisibleButton("##lfclose", sz, sz)
    local hov = ImGui.IsItemHovered()
    ui.closeHov = damp(ui.closeHov or 0, hov and 1 or 0, 14, ui.dt)
    local ca = math.floor((120 + 100 * ui.closeHov) * aMul)
    if ui.closeHov > 0.01 then
        ImGui.AddCircleFilled(cx1 + sz / 2, cy1 + sz / 2, sz * 0.62,
            240, 100, 100, math.floor(40 * ui.closeHov * aMul), 0)
    end
    local m = 6 + (1 - ui.closeHov) * 1.5
    ImGui.AddLine(cx1 + m, cy1 + m, cx1 + sz - m, cy1 + sz - m, 240, 245, 252, ca, 1.6)
    ImGui.AddLine(cx1 + sz - m, cy1 + m, cx1 + m, cy1 + sz - m, 240, 245, 252, ca, 1.6)
    if clicked then
        FeatureMgr.GetFeature(H.OPEN):SetBoolValue(false)
    end

    -- drag region (everything left of the close button)
    ImGui.SetCursorPos(0, 0)
    ImGui.InvisibleButton("##lfdrag", WIN_W - sz - 20, TITLE_H)
    ui.winDrag = false
    if ImGui.IsItemActive() and ImGui.IsMouseDragging(0, 0.0) then
        local dx, dy = ImGui.GetMouseDragDelta(0, 0.0)
        ImGui.ResetMouseDragDelta(0)
        ui.pos.x = ui.pos.x + dx
        ui.pos.y = ui.pos.y + dy
        ui.winDrag = true
    end
end

local function drawRail(wx, wy, alpha)
    local x1, y1 = wx + PAD, wy + TITLE_H + PAD
    local x2, y2 = x1 + RAIL_W, wy + WIN_H - FOOTER_H - PAD
    glassPanel(x1, y1, x2, y2, 10, 26)

    local btnH, gap = 34, 4
    local innerX = x1 + 6

    -- Outfits / About: real rail tabs like the categories, bottom-anchored
    -- below a divider so outfit creation stays visually separate
    local EXTRAS = {
        { label = "Outfits", icon = "star", view = "outfits" },
        { label = "About",   icon = "info", view = "about" },
    }
    local aboutY   = y2 - 8 - btnH
    local outfitsY = aboutY - gap - btnH
    EXTRAS[1].by, EXTRAS[2].by = outfitsY, aboutY
    local dividerY = outfitsY - gap
    ImGui.AddLine(x1 + 10, dividerY, x2 - 10, dividerY,
        200, 225, 255, math.floor(34 * alpha), 1.0)

    -- the two extra tabs (same look as category rows; their highlight fades
    -- in per-row since the sliding pill lives inside the category scroller)
    for e, ex in ipairs(EXTRAS) do
        local by = ex.by
        ImGui.SetCursorPos(innerX - wx, by - wy)
        local exClicked = ImGui.InvisibleButton("##railex" .. e, RAIL_W - 12, btnH)
        local exHov = ImGui.IsItemHovered()
        local st = ui.railAnim[100 + e]
        if not st then st = { hover = 0, sel = 0 }; ui.railAnim[100 + e] = st end
        st.hover = damp(st.hover, exHov and 1 or 0, 14, ui.dt)
        local isSel = (ui.view == ex.view)
        st.sel = damp(st.sel or 0, isSel and 1 or 0, 12, ui.dt)
        if st.sel > 0.02 then
            glowRect(innerX, by, x2 - 6, by + btnH,
                COL.accent[1], COL.accent[2], COL.accent[3], 0.35 * st.sel * alpha, 6, 8)
            ImGui.AddRectFilled(innerX, by, x2 - 6, by + btnH,
                COL.accent[1], COL.accent[2], COL.accent[3],
                math.floor(70 * st.sel * alpha), 8)
            ImGui.AddRect(innerX, by, x2 - 6, by + btnH,
                COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
                math.floor(90 * st.sel * alpha), 8, 0, 1.0)
        end
        if st.hover > 0.01 and not isSel then
            ImGui.AddRectFilled(innerX, by, x2 - 6, by + btnH,
                255, 255, 255, math.floor(16 * st.hover * alpha), 8)
        end
        local tr, tg, tb = COL.text[1], COL.text[2], COL.text[3]
        if not isSel then
            tr = lerp(COL.textDim[1], COL.text[1], st.hover)
            tg = lerp(COL.textDim[2], COL.text[2], st.hover)
            tb = lerp(COL.textDim[3], COL.text[3], st.hover)
        end
        local textX = innerX + 10
        if fOn(H.ICONS) and ex.icon then
            local ic = ensureIcon(ex.icon)
            if ic and ic.st == "ready" and ic.tex then
                local okI = pcall(function()
                    local imTex = ic.tex:GetCurrent()
                    if imTex then
                        ImGui.AddImage(imTex, innerX + 9, by + 8, innerX + 27, by + 26,
                            0, 0, 1, 1,
                            u32(math.floor(tr), math.floor(tg), math.floor(tb),
                                math.floor(255 * alpha)))
                    end
                end)
                if not okI then ic.st = "failed" end
            end
            textX = innerX + 34
        end
        ImGui.AddText(textX + st.hover * 3, by + 8, ex.label,
            tr, tg, tb, math.floor(255 * alpha))
        if exClicked and ui.view ~= ex.view then
            ui.view = ex.view
        end
    end

    -- categories: 16 rows live in a scrollable child so they work at any
    -- window height (mouse wheel scrolls; scrollbar stays subtle)
    local catY1, catY2 = y1 + 4, dividerY - 6
    ImGui.SetCursorPos(x1 + 2 - wx, catY1 - wy)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg, 0, 0, 0, 0)
    if ImGui.BeginChild("##lfrailcats", RAIL_W - 4, catY2 - catY1, false, 0) then
        local csx, csy = ImGui.GetCursorScreenPos()
        local rowW = RAIL_W - 24   -- leaves room for the scrollbar
        ImGui.Dummy(rowW, 8 + #COMPONENTS * (btnH + gap) + 4)

        -- sliding pill (fades out while Outfits/About are open)
        ui.pillA = damp(ui.pillA or 1, ui.view == "grid" and 1 or 0, 10, ui.dt)
        local targetOff = 8 + (ui.selComp - 1) * (btnH + gap)
        if not ui.pillInit then ui.pillOff = targetOff; ui.pillInit = true end
        ui.pillOff = damp(ui.pillOff, targetOff, fFlt(H.ANIMSPEED) * 1.4, ui.dt)
        local pillY = csy + ui.pillOff
        local pA = alpha * ui.pillA
        if pA > 0.02 then
            glowRect(csx + 4, pillY, csx + rowW, pillY + btnH,
                COL.accent[1], COL.accent[2], COL.accent[3], 0.35 * pA, 6, 8)
            ImGui.AddRectFilled(csx + 4, pillY, csx + rowW, pillY + btnH,
                COL.accent[1], COL.accent[2], COL.accent[3], math.floor(70 * pA), 8)
            ImGui.AddRect(csx + 4, pillY, csx + rowW, pillY + btnH,
                COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
                math.floor(90 * pA), 8, 0, 1.0)
        end

        for i, comp in ipairs(COMPONENTS) do
            local yOff = 8 + (i - 1) * (btnH + gap)
            local by = csy + yOff
            ImGui.SetCursorPos(4, yOff)
            local clicked = ImGui.InvisibleButton("##rail" .. i, rowW - 4, btnH)
            local hov = ImGui.IsItemHovered()

            local st = ui.railAnim[i]
            if not st then st = { hover = 0 }; ui.railAnim[i] = st end
            st.hover = damp(st.hover, hov and 1 or 0, 14, ui.dt)

            local isSel = (i == ui.selComp)
            if st.hover > 0.01 and not isSel then
                ImGui.AddRectFilled(csx + 4, by, csx + rowW, by + btnH,
                    255, 255, 255, math.floor(16 * st.hover * alpha), 8)
            end

            local tr, tg, tb = COL.text[1], COL.text[2], COL.text[3]
            if not isSel then
                tr = lerp(COL.textDim[1], COL.text[1], st.hover)
                tg = lerp(COL.textDim[2], COL.text[2], st.hover)
                tb = lerp(COL.textDim[3], COL.text[3], st.hover)
            end

            local textX = csx + 14
            if fOn(H.ICONS) and comp.icon then
                local ic = ensureIcon(comp.icon)
                if ic and ic.st == "ready" and ic.tex then
                    local okI = pcall(function()
                        local imTex = ic.tex:GetCurrent()
                        if imTex then
                            ImGui.AddImage(imTex, csx + 13, by + 8, csx + 31, by + 26,
                                0, 0, 1, 1,
                                u32(math.floor(tr), math.floor(tg), math.floor(tb),
                                    math.floor(255 * alpha)))
                        end
                    end)
                    if not okI then ic.st = "failed" end
                end
                textX = csx + 38
            end
            -- count badge measured first so the label clips around it
            -- (long labels like "Torso / Gloves" used to bleed into the count)
            local info = ped.comps[comp.id]
            local badge, bw = nil, 0
            if info and info.drawCount and info.drawCount > 0 then
                badge = tostring(info.drawCount)
                bw = ImGui.CalcTextSize(badge)
            end
            textClipped(textX + st.hover * 3, by + 8,
                csx + rowW - 12 - bw - textX - st.hover * 3, comp.label,
                tr, tg, tb, math.floor(255 * alpha))
            if badge then
                ImGui.AddText(csx + rowW - 8 - bw, by + 8, badge,
                    COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
                    math.floor((isSel and 220 or 110) * alpha))
            end

            if clicked then
                if ui.view ~= "grid" then
                    ui.view = "grid"
                    ui.gridAppearAt = ui.now
                end
                switchComp(i)
            end
        end
    end
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
end

local function drawTile(comp, gender, drawable, cellX, cellY, cellW, cellH, alpha, appearT)
    local info = ped.comps[comp.id]
    local isCur = info and info.drawable == drawable
    local key = "d" .. drawable

    local st = ui.cellAnim[key]
    if not st then st = { hover = 0 }; ui.cellAnim[key] = st end

    ImGui.SetCursorPos(cellX, cellY)
    local clicked = ImGui.InvisibleButton("##cell" .. comp.id .. "_" .. drawable, cellW, cellH)
    local hov = ImGui.IsItemHovered()
    st.hover = damp(st.hover, hov and 1 or 0, 14, ui.dt)

    local mnx, mny = ImGui.GetItemRectMin()
    local mxx, mxy = ImGui.GetItemRectMax()

    -- appear: slight rise + fade
    local rise = (1 - appearT) * 8
    mny, mxy = mny + rise, mxy + rise
    local aMul = alpha * appearT

    -- hover lift
    local lift = st.hover * 2
    mny, mxy = mny - lift, mxy - lift

    -- glow for selection / hover
    if isCur then
        glowRect(mnx, mny, mxx, mxy, COL.accent[1], COL.accent[2], COL.accent[3],
            0.5 * aMul, 8, 10)
    elseif st.hover > 0.02 then
        glowRect(mnx, mny, mxx, mxy, COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
            0.22 * st.hover * aMul, 6, 10)
    end

    -- tile body
    local bodyA = math.floor((30 + 24 * st.hover) * aMul)
    ImGui.AddRectFilled(mnx, mny, mxx, mxy, COL.panel[1], COL.panel[2], COL.panel[3], bodyA, 10)

    -- image / fallback
    local imgPad = 6
    local curTex = (isCur and info.tex and info.tex >= 0) and info.tex or 0
    local t
    if drawable >= 0 then
        t = ensureThumb(comp, gender, drawable, curTex)
    else
        t = { st = "none" }   -- the props None tile has no image by design
    end

    if drawable < 0 then
        -- None tile: circle-slash glyph, centered
        local cxMid = (mnx + mxx) * 0.5
        local cyMid = (mny + mxy - 16) * 0.5
        local rad = math.min(16, cellW * 0.18)
        local segs, px, py = 20, nil, nil
        for s = 0, segs do
            local ang = (s / segs) * math.pi * 2
            local ax = cxMid + math.cos(ang) * rad
            local ay = cyMid - 6 + math.sin(ang) * rad
            if px then
                ImGui.AddLine(px, py, ax, ay,
                    COL.textDim[1], COL.textDim[2], COL.textDim[3],
                    math.floor(140 * aMul), 1.6)
            end
            px, py = ax, ay
        end
        local k = rad * 0.7071
        ImGui.AddLine(cxMid - k, cyMid - 6 + k, cxMid + k, cyMid - 6 - k,
            COL.textDim[1], COL.textDim[2], COL.textDim[3],
            math.floor(140 * aMul), 1.6)
        centerText(mnx, mxx, cyMid + rad + 2, "none",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(150 * aMul))
    elseif t.st == "ready" and t.tex then
        t.appear = damp(t.appear or 0, 1, 10, ui.dt)
        local okI = pcall(function()
            local imTex = t.tex:GetCurrent()
            if imTex then
                ImGui.AddImageRounded(imTex, mnx + imgPad, mny + imgPad,
                    mxx - imgPad, mxy - imgPad - 16,
                    0, 0, 1, 1,
                    u32(255, 255, 255, math.floor(255 * t.appear * aMul)), 8)
            end
        end)
        if not okI then t.st = "failed" end
    end
    if drawable >= 0 and t.st ~= "ready" then
        -- fallback tile: dim category icon, caption, and number - all in
        -- FIXED positions so nothing jumps when the icon finishes loading
        local isLoading = (t.st == "downloading" or t.st == "loading" or t.st == "queued")
        local pulse = isLoading and (0.55 + 0.25 * math.sin(ui.now * 5)) or 0.75
        local cxMid = (mnx + mxx) * 0.5
        local cyMid = (mny + mxy - 16) * 0.5

        if comp.icon then
            local ic = ensureIcon(comp.icon)
            if ic and ic.st == "ready" and ic.tex then
                pcall(function()
                    local imTex = ic.tex:GetCurrent()
                    if imTex then
                        local isz = math.min(26, cellW * 0.28)
                        ImGui.AddImage(imTex,
                            cxMid - isz / 2, cyMid - 16 - isz / 2,
                            cxMid + isz / 2, cyMid - 16 + isz / 2,
                            0, 0, 1, 1,
                            u32(COL.textDim[1], COL.textDim[2], COL.textDim[3],
                                math.floor(80 * pulse * aMul)))
                    end
                end)
            end
        end

        local caption = isLoading and "loading..." or "no preview"
        centerText(mnx, mxx, cyMid + 2, caption,
            COL.textDim[1], COL.textDim[2], COL.textDim[3],
            math.floor(95 * pulse * aMul))
        centerText(mnx, mxx, cyMid + 18, "#" .. drawable,
            COL.textDim[1], COL.textDim[2], COL.textDim[3],
            math.floor(130 * pulse * aMul))
    end

    -- name strip (skip the "#n" duplicate when the tile body already shows it)
    local nm = itemName(gender, comp.id, drawable, isCur and curTex or 0)
    local stripY = mxy - 16
    if nm and nm ~= "" then
        textClipped(mnx + 6, stripY, cellW - 12, nm,
            COL.text[1], COL.text[2], COL.text[3], math.floor(190 * aMul))
    elseif t.st == "ready" then
        ImGui.AddText(mnx + 6, stripY, "#" .. drawable,
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(120 * aMul))
    end

    -- selection ring
    if isCur then
        ImGui.AddRect(mnx, mny, mxx, mxy,
            COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
            math.floor(220 * aMul), 10, 0, 1.6)
    end

    if clicked and not isCur then
        applyVariation(comp.id, drawable, 0)
    end
end

local function drawGrid(wx, wy, alpha)
    local comp = currentComp()
    local gender = ped.gender
    local x1 = wx + PAD + RAIL_W + PAD
    local y1 = wy + TITLE_H + PAD
    local x2 = wx + WIN_W - RIGHT_W - PAD * 2
    local y2 = wy + WIN_H - FOOTER_H - PAD - CARD_H - 6

    -- crossfade on category switch
    local speed = fFlt(H.ANIMSPEED)
    if ui.grid.switching then
        ui.grid.fade = damp(ui.grid.fade, 0, speed * 2.2, ui.dt)
        if ui.grid.fade < 0.06 then
            ui.selComp = ui.grid.pendingComp or ui.selComp
            ui.grid.pendingComp = nil
            ui.grid.switching = false
            ui.cellAnim = {}
            ui.gridAppearAt = ui.now
            ui.grid.scrollTo = 0
            if not ped.texCounts[currentComp().id] then
                wantCounts[currentComp().id] = true
            end
        end
    else
        ui.grid.fade = damp(ui.grid.fade, 1, speed * 2.2, ui.dt)
    end
    local gAlpha = alpha * ui.grid.fade

    -- search box (glass-styled)
    local searchH = 26
    ImGui.SetCursorPos(x1 - wx, y1 - wy)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 1.0, 1.0, 1.0, 0.07)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.35, 0.63, 1.0, 0.15)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.35, 0.63, 1.0, 0.25)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.94, 0.96, 0.99, 1.0)
    ImGui.PushItemWidth(x2 - x1)
    local newSearch = ImGui.InputTextWithHint("##lfsearch", "search " .. comp.label:lower() .. "...", ui.search, 0)
    if type(newSearch) == "string" then ui.search = newSearch end
    ImGui.PopItemWidth()
    ImGui.PopStyleColor(4)

    local gridY1 = y1 + searchH + 6

    -- contextual notices (small dim info lines under the search box)
    local notices = {}
    if dlWriteOpt == false and not CACHE_PRESENT then
        notices[#notices + 1] = "no preview images installed. use Get Preview Pack in the LiquidFit tab (one browser download)"
    end
    if comp.id == 10 then
        notices[#notices + 1] = "decals have no previews. many are crew emblems: without a visible crew emblem they show nothing"
    end
    if fOn(H.HIDEEMPTY) then
        notices[#notices + 1] = "hiding unnamed items. toggle it off in the LiquidFit tab to see everything"
    end
    for _, n in ipairs(notices) do
        textClipped(x1 + 2, gridY1, x2 - x1 - 4, n,
            COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
            math.floor(120 * gAlpha))
        gridY1 = gridY1 + 17
    end
    if #notices > 0 then gridY1 = gridY1 + 3 end

    local info = ped.comps[comp.id]
    if not info or not ped.valid then
        centerText(x1, x2, (gridY1 + y2) / 2, "waiting for your ped...",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(180 * gAlpha))
        return
    end

    -- build the (filtered) drawable list
    local names = namesFor(gender)
    local query = ui.search:lower()
    local hideEmpty = fOn(H.HIDEEMPTY) and (comp.imgCat ~= nil or comp.hasImages)
    local cov = hideEmpty and coverageFor(comp, gender, info.drawCount) or nil
    local items = {}
    local seenNone = false
    if comp.prop ~= nil and query == "" then
        items[#items + 1] = -1   -- the "wear nothing" tile for props
    end
    for d = 0, info.drawCount - 1 do
        local visible = true
        if cov and not cov[d] then
            -- no image: keep it only if the data gives it a real name
            local rn = rawName(gender, comp.id, d, 0)
            visible = rn ~= nil and rn ~= "" and rn ~= "NULL"
            -- collapse duplicate "None" placeholders: keep only the first
            if visible and rn == "None" then
                if seenNone then visible = false else seenNone = true end
            end
        end
        if visible then
            if query == "" then
                items[#items + 1] = d
            else
                local nm
                local compNames = names and names[comp.id]
                local entry = compNames and compNames[d]
                if entry then nm = table.concat(entry, " "):lower() end
                if (nm and nm:find(query, 1, true)) or tostring(d):find(query, 1, true) then
                    items[#items + 1] = d
                end
            end
        end
    end

    -- grid layout
    local cellW = fInt(H.THUMBSIZE)
    local cellH = cellW + 18
    local gapC = 8
    local availW = (x2 - x1)
    local cols = math.max(1, math.floor((availW - gapC) / (cellW + gapC)))
    local rows = math.ceil(#items / cols)
    local contentH = rows * (cellH + gapC) + gapC

    ImGui.SetCursorPos(x1 - wx, gridY1 - wy)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg, 0, 0, 0, 0)
    if ImGui.BeginChild("##lfgrid", x2 - x1, y2 - gridY1, false, 0) then
        if ui.grid.scrollTo >= 0 then
            ImGui.SetScrollY(ui.grid.scrollTo)
            ui.grid.scrollTo = -1
        end
        local scrollY = ImGui.GetScrollY()
        local viewH = y2 - gridY1

        ImGui.Dummy(availW - 16, contentH)

        ImGui.PushClipRect(x1, gridY1, x2, y2, true)
        local shown = 0
        for idx, d in ipairs(items) do
            local row = math.floor((idx - 1) / cols)
            local col = (idx - 1) % cols
            local cy = gapC + row * (cellH + gapC)
            if cy + cellH >= scrollY and cy <= scrollY + viewH then
                local cx = gapC + col * (cellW + gapC)
                -- staggered appear after category switch
                local appearT = 1.0
                if ui.gridAppearAt then
                    local wave = (ui.now - ui.gridAppearAt) * 3.2 - (shown * 0.035)
                    appearT = clamp(wave, 0, 1)
                    appearT = 1 - (1 - appearT) * (1 - appearT) -- ease-out
                end
                drawTile(comp, gender, d, cx, cy, cellW, cellH, gAlpha, appearT)
                shown = shown + 1
            end
        end
        ImGui.PopClipRect()
    end
    ImGui.EndChild()
    ImGui.PopStyleColor(2)

    if #items == 0 then
        centerText(x1, x2, (gridY1 + y2) / 2, "no matches",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(160 * gAlpha))
    end
end

-- Advance yaw: drag velocity > arrow target > auto spin > settle.
local function updateYaw()
    if ui.dragActive then
        ui.yaw = (ui.yaw + ui.yawVel * ui.dt) % 360
    elseif ui.yawTarget then
        ui.yaw = damp(ui.yaw, ui.yawTarget, fFlt(H.ANIMSPEED), ui.dt)
        if math.abs(ui.yaw - ui.yawTarget) < 0.5 then
            ui.yaw, ui.yawTarget = ui.yawTarget % 360, nil
        end
    elseif fOn(H.AUTOROTATE) then
        ui.yawVel = damp(ui.yawVel, 24, 2, ui.dt)
        ui.yaw = (ui.yaw + ui.yawVel * ui.dt) % 360
    else
        ui.yawVel = damp(ui.yawVel, 0, 4, ui.dt)
        ui.yaw = (ui.yaw + ui.yawVel * ui.dt) % 360
    end
end

-- Interactive preview hole: border ring, drag-to-rotate, and the ped render.
-- gateKey isolates the per-window "hide while moving" state; only one hole
-- exists at a time (docked xor detached), so rotation state can be shared.
-- (No backdrop is possible behind the ped: tested, ImGui's background draw
-- list renders ABOVE Cherax's ped preview, so anything we paint covers him.)
local function previewHole(wx, wy, pvX1, pvY1, pvX2, pvY2, alpha, idSuffix, gateKey)
    ImGui.AddRect(pvX1, pvY1, pvX2, pvY2,
        210, 230, 255, math.floor(40 * alpha), HOLE_R, 0, 1.0)

    ImGui.SetCursorPos(pvX1 - wx, pvY1 - wy)
    ImGui.InvisibleButton("##lfpreview" .. idSuffix, pvX2 - pvX1, pvY2 - pvY1)
    local pvHov = ImGui.IsItemHovered()
    if ImGui.IsItemActive() and ImGui.IsMouseDragging(0, 0.0) then
        local dx, _ = ImGui.GetMouseDragDelta(0, 0.0)
        ImGui.ResetMouseDragDelta(0)
        ui.yawVel = dx * 4
        ui.dragActive = true
        ui.yawTarget = nil
    else
        ui.dragActive = false
    end
    updateYaw()

    -- per-window movement gate (half-pixel epsilon vs float noise)
    local g = ui[gateKey]
    if not g then g = {}; ui[gateKey] = g end
    if math.abs((g.lx or pvX1) - pvX1) > 0.5
        or math.abs((g.ly or pvY1) - pvY1) > 0.5 then
        g.moveAt = ui.now
    end
    g.lx, g.ly = pvX1, pvY1
    local settled = alpha > 0.95
        and ((ui.now - (g.moveAt or 0)) > 0.06 or ui.resizing or ui.pvResizing)

    if settled and V2New then
        local dispW, dispH = ImGui.GetDisplaySize()
        local calibX = clamp(fFlt(H.PVCALIB), 0.5, 2.0)
        local calibY = clamp(fFlt(H.PVCALIBY), 0.5, 2.0)
        local rawCx = ((pvX1 + pvX2) * 0.5) / dispW
        local rawCy = ((pvY1 + pvY2) * 0.5) / dispH
        local cxN = 0.5 + (rawCx - 0.5) / calibX
        local cyN = 0.5 + (rawCy - 0.5) / calibY
            + clamp(fFlt(H.PREVIEWYOFF), -0.15, 0.15)
        local sizeScale = (pvY2 - pvY1) / 476.0
        local zoom = clamp(fFlt(H.PREVIEWZOOM) / math.max(sizeScale, 0.1), -8.0, -1.2)
        -- hand the draw to the game-thread worker (render-thread calls of
        -- game APIs have been flaky before; the worker runs once per game
        -- frame which also steadies the pacing)
        pvDrawReq.cx, pvDrawReq.cy = cxN, cyN
        pvDrawReq.w = (pvX2 - pvX1) * 0.5 / dispW / calibX
        pvDrawReq.h = (pvY2 - pvY1) * 0.5 / dispH / calibY
        pvDrawReq.zoom, pvDrawReq.yaw = zoom, ui.yaw
        pvDrawReq.stamp = os.clock()
    end
    if pvHov then
        centerText(pvX1, pvX2, pvY2 - 18, "drag to rotate",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(110 * alpha))
    end
end

-- Rotate arrows as a centered pair; tooltips replace the old "rotate" label.
local function drawRotateControls(wx, wy, x1, x2, cy1, alpha, idSuffix)
    local btn = PVCTRL_H - 8
    local cx = (x1 + x2) * 0.5
    local lx, rx = cx - btn - 4, cx + 4

    if glassButton("pvLeft" .. idSuffix, "", lx, cy1, btn, btn, COL.panel,
        alpha, wx, wy, "rotate left") then
        ui.yawTarget = (ui.yawTarget or ui.yaw) - 45
    end
    ImGui.AddTriangleFilled(
        lx + btn * 0.62, cy1 + btn * 0.28,
        lx + btn * 0.62, cy1 + btn * 0.72,
        lx + btn * 0.34, cy1 + btn * 0.5,
        COL.text[1], COL.text[2], COL.text[3], math.floor(220 * alpha))

    if glassButton("pvRight" .. idSuffix, "", rx, cy1, btn, btn, COL.panel,
        alpha, wx, wy, "rotate right") then
        ui.yawTarget = (ui.yawTarget or ui.yaw) + 45
    end
    ImGui.AddTriangleFilled(
        rx + btn * 0.38, cy1 + btn * 0.28,
        rx + btn * 0.38, cy1 + btn * 0.72,
        rx + btn * 0.66, cy1 + btn * 0.5,
        COL.text[1], COL.text[2], COL.text[3], math.floor(220 * alpha))
end

-- Small pop-out / pop-in icon button: a subtle glass square with a clean
-- diagonal arrow (chevron head, no filled triangles).
local function popButton(stateKey, x, y, sz, alpha, wx, wy, outward, hint)
    ImGui.SetCursorPos(x - wx, y - wy)
    local clicked = ImGui.InvisibleButton("##" .. stateKey, sz, sz)
    local hov = ImGui.IsItemHovered()
    if hov and hint then pcall(ImGui.SetTooltip, hint) end
    ui[stateKey] = damp(ui[stateKey] or 0, hov and 1 or 0, 14, ui.dt)
    local hv = ui[stateKey]
    local a = math.floor((130 + 110 * hv) * alpha)

    -- hover backing
    if hv > 0.02 then
        ImGui.AddRectFilled(x, y, x + sz, y + sz,
            COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
            math.floor(35 * hv * alpha), 5)
    end

    -- diagonal shaft between the two anchor points
    local inX, inY   = x + sz * 0.38, y + sz * 0.62   -- inner (window) end
    local outX, outY = x + sz - 4,    y + 4           -- outer end
    ImGui.AddLine(inX, inY, outX, outY,
        COL.text[1], COL.text[2], COL.text[3], a, 1.5)

    -- chevron head at whichever end the arrow points to
    local hd = 5
    if outward then
        ImGui.AddLine(outX, outY, outX - hd, outY,
            COL.text[1], COL.text[2], COL.text[3], a, 1.5)
        ImGui.AddLine(outX, outY, outX, outY + hd,
            COL.text[1], COL.text[2], COL.text[3], a, 1.5)
    else
        ImGui.AddLine(inX, inY, inX + hd, inY,
            COL.text[1], COL.text[2], COL.text[3], a, 1.5)
        ImGui.AddLine(inX, inY, inX, inY - hd,
            COL.text[1], COL.text[2], COL.text[3], a, 1.5)
    end

    -- small corner bracket marking the "window" the arrow relates to
    ImGui.AddLine(x + 3, y + sz * 0.5, x + 3, y + sz - 3,
        COL.textDim[1], COL.textDim[2], COL.textDim[3], a, 1.3)
    ImGui.AddLine(x + 3, y + sz - 3, x + sz * 0.5, y + sz - 3,
        COL.textDim[1], COL.textDim[2], COL.textDim[3], a, 1.3)
    return clicked
end

-- Dice button: rolls a random outfit. Five pips, glass square, tooltip.
local function diceButton(stateKey, x, y, sz, alpha, wx, wy)
    ImGui.SetCursorPos(x - wx, y - wy)
    local clicked = ImGui.InvisibleButton("##" .. stateKey, sz, sz)
    local hov = ImGui.IsItemHovered()
    if hov then pcall(ImGui.SetTooltip, "randomize outfit (Revert undoes it)") end
    ui[stateKey] = damp(ui[stateKey] or 0, hov and 1 or 0, 14, ui.dt)
    local hv = ui[stateKey]
    local a = math.floor((140 + 100 * hv) * alpha)
    if hv > 0.02 then
        ImGui.AddRectFilled(x - 2, y - 2, x + sz + 2, y + sz + 2,
            COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
            math.floor(35 * hv * alpha), 6)
    end
    ImGui.AddRect(x + 1, y + 1, x + sz - 1, y + sz - 1,
        COL.text[1], COL.text[2], COL.text[3], a, 4, 0, 1.4)
    local cx, cy = x + sz * 0.5, y + sz * 0.5
    local o = sz * 0.22
    for _, p in ipairs({ { -o, -o }, { o, -o }, { 0, 0 }, { -o, o }, { o, o } }) do
        ImGui.AddCircleFilled(cx + p[1], cy + p[2], 1.7,
            COL.text[1], COL.text[2], COL.text[3], a, 0)
    end
    return clicked
end

-- Docked preview column (used when the preview is NOT detached).
local function drawPreviewColumn(wx, wy, alpha)
    local pvX1, pvY1, pvX2, pvY2 = previewRect(wx, wy)
    previewHole(wx, wy, pvX1, pvY1, pvX2, pvY2, alpha, "A", "gateA")
    drawRotateControls(wx, wy, pvX1, pvX2, pvY2 + 6, alpha, "A")
    -- controls bar ends: dice on the left, pop-out on the right (both live
    -- outside the hole so their clicks are never eaten)
    local btn = PVCTRL_H - 8
    local by = pvY2 + 6 + (btn - 18) * 0.5
    if diceButton("btnDice", pvX1, by, 18, alpha, wx, wy) then
        randomizeOutfit()
    end
    if popButton("btnPopOut", pvX2 - btn, by,
        18, alpha, wx, wy, true, "detach preview") then
        FeatureMgr.GetFeature(H.DETACH):SetBoolValue(true)
    end
end

-- Detached preview window: own position, own size, own resize grip.
local PVW_TITLE = 26
local function drawDetachedPreview(aMul)
    local dispW, dispH = ImGui.GetDisplaySize()
    if not ui.pvInit then
        ui.pvInit = true
        local x = FeatureMgr.GetFeatureFloat(H.PVWX)
        local y = FeatureMgr.GetFeatureFloat(H.PVWY)
        local w = FeatureMgr.GetFeatureFloat(H.PVWW)
        local hh = FeatureMgr.GetFeatureFloat(H.PVWH)
        ui.pvPos = {
            x = (x and x >= 0) and x or (dispW - 360),
            y = (y and y >= 0) and y or (dispH * 0.15),
        }
        ui.pvW = (w and w > 0) and w or 320
        ui.pvH = (hh and hh > 0) and hh or 560
    end
    ui.pvW = clamp(ui.pvW, 220, 700)
    ui.pvH = clamp(ui.pvH, 320, 1000)
    ui.pvPos.x = clamp(ui.pvPos.x, -ui.pvW * 0.5, dispW - ui.pvW * 0.5)
    ui.pvPos.y = clamp(ui.pvPos.y, 0, dispH - 60)

    local px, py, pw, ph = ui.pvPos.x, ui.pvPos.y, ui.pvW, ui.pvH
    ImGui.SetNextWindowPos(px, py, 1)
    ImGui.SetNextWindowSize(pw, ph, 1)
    ImGui.SetNextWindowBgAlpha(0.0)
    local flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize
        | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoCollapse
        | ImGuiWindowFlags.NoScrollWithMouse
    ImGui.Begin("##LiquidFitPvWin", true, flags)

    local okDraw, errDraw = pcall(function()
        local hx1, hy1 = px + 6, py + PVW_TITLE
        local hx2, hy2 = px + pw - 6, py + ph - PVCTRL_H - 8
        local br, bg, bb, ba = 52, 70, 102, math.floor(236 * aMul)

        -- glass frame around the hole
        ImGui.AddRectFilled(px, py, px + pw, hy1, br, bg, bb, ba, 14, DF_TOP)
        ImGui.AddRectFilled(px, hy2, px + pw, py + ph, br, bg, bb, ba, 14, DF_BOT)
        ImGui.AddRectFilled(px, hy1, hx1, hy2, br, bg, bb, ba, 0, 0)
        ImGui.AddRectFilled(hx2, hy1, px + pw, hy2, br, bg, bb, ba, 0, 0)
        fillHoleCorners(hx1, hy1, hx2, hy2, HOLE_R, br, bg, bb, ba)
        ImGui.AddRect(px, py, px + pw, py + ph,
            210, 230, 255, math.floor(70 * aMul), 14, 0, 1.0)

        -- mini title: drag region + label + pop-in button
        ImGui.SetCursorPos(0, 0)
        ImGui.InvisibleButton("##lfpvdrag", pw - 30, PVW_TITLE)
        if ImGui.IsItemActive() and ImGui.IsMouseDragging(0, 0.0) then
            local dx, dy = ImGui.GetMouseDragDelta(0, 0.0)
            ImGui.ResetMouseDragDelta(0)
            ui.pvPos.x = ui.pvPos.x + dx
            ui.pvPos.y = ui.pvPos.y + dy
            ui.pvDirty = true
        end
        ImGui.AddText(px + 10, py + 5, "P R E V I E W",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(190 * aMul))
        if popButton("btnPopIn", px + pw - 24, py + 4, 18, aMul, px, py, false,
            "reattach preview") then
            FeatureMgr.GetFeature(H.DETACH):SetBoolValue(false)
        end

        previewHole(px, py, hx1, hy1, hx2, hy2, aMul, "D", "gateD")
        drawRotateControls(px, py, hx1, hx2, hy2 + 4, aMul, "D")
        if diceButton("btnDiceD", hx1, hy2 + 4 + (PVCTRL_H - 8 - 18) * 0.5,
            18, aMul, px, py) then
            randomizeOutfit()
        end

        -- resize grip
        ImGui.SetCursorPos(pw - 20, ph - 20)
        ImGui.InvisibleButton("##lfpvresize", 18, 18)
        local gHov = ImGui.IsItemHovered()
        ui.pvResizing = false
        if ImGui.IsItemActive() and ImGui.IsMouseDragging(0, 0.0) then
            local dx, dy = ImGui.GetMouseDragDelta(0, 0.0)
            ImGui.ResetMouseDragDelta(0)
            ui.pvW = clamp(ui.pvW + dx, 220, 700)
            ui.pvH = clamp(ui.pvH + dy, 320, 1000)
            ui.pvResizing = true
            ui.pvDirty = true
            gHov = true
        end
        ui.pvGripHov = damp(ui.pvGripHov or 0, gHov and 1 or 0, 14, ui.dt)
        local ga = math.floor((70 + 130 * ui.pvGripHov) * aMul)
        for i = 1, 3 do
            local o = i * 4
            ImGui.AddLine(px + pw - 5 - o, py + ph - 5, px + pw - 5, py + ph - 5 - o,
                COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], ga, 1.2)
        end
    end)

    ImGui.End()

    if not okDraw and (ui.lastPvErrAt or 0) < ui.now then
        ui.lastPvErrAt = ui.now + 5
        Logger.LogInfo("[" .. SCRIPT_NAME .. "] preview window error: " .. tostring(errDraw))
    end
end

-- Selected-item card under the grid: name, meta, variant strip, actions.
local function drawItemCard(wx, wy, alpha)
    local comp = currentComp()
    local gender = ped.gender
    local x1 = wx + PAD + RAIL_W + PAD
    local x2 = wx + WIN_W - RIGHT_W - PAD * 2
    local y2 = wy + WIN_H - FOOTER_H - PAD
    local y1 = y2 - CARD_H
    glassPanel(x1, y1, x2, y2, 10, 30)

    local info = ped.comps[comp.id]
    if not info then return end

    -- action buttons (right side, stacked)
    local bw, bh = 108, 26
    local bx = x2 - bw - 10
    if glassButton("btnKeep", "Keep Outfit", bx, y1 + 12, bw, bh, COL.good, alpha, wx, wy) then
        wantSnapshot = true
        lfToast("Outfit saved", "Locked in. Looking sharp.")
    end
    if glassButton("btnRevert", "Revert", bx, y1 + 12 + bh + 8, bw, bh, COL.bad, alpha, wx, wy) then
        restoreReq = true
        lfToast("Reverted", "Back to your saved outfit.")
    end

    -- name + meta
    local textW = bx - x1 - 20
    local nm
    if info.drawable and info.drawable < 0 then
        nm = "None"
    else
        nm = itemName(gender, comp.id, info.drawable, math.max(info.tex or 0, 0))
            or (comp.label .. " " .. info.drawable)
    end
    textClipped(x1 + 10, y1 + 8, textW, nm,
        COL.text[1], COL.text[2], COL.text[3], math.floor(240 * alpha))
    local meta = comp.label
    if info.drawable and info.drawable >= 0 then
        meta = meta .. "  " .. info.drawable ..
            ((info.tex or 0) > 0 and ("  /  variant " .. info.tex) or "")
    end
    ImGui.AddText(x1 + 10, y1 + 26, meta,
        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(160 * alpha))

    -- variant strip (single row, overflow indicator)
    local texCounts = ped.texCounts[comp.id]
    local tCount = texCounts and texCounts[info.drawable] or 0
    if tCount > 1 then
        local tile, gap = 34, 4
        local vy = y1 + 50
        local maxTiles = math.floor((textW + gap) / (tile + gap))
        local needNav = tCount > maxTiles

        -- overflow: reserve room for paging arrows at both strip ends
        local arrowW = 16
        local stripX1 = x1 + 10
        if needNav then
            stripX1 = x1 + 10 + arrowW + 6
            maxTiles = math.max(1, math.floor((textW - 2 * (arrowW + 6) + gap) / (tile + gap)))
        end
        local stripX2 = stripX1 + maxTiles * (tile + gap) - gap

        -- scroll state resets whenever the selected item changes; the offset
        -- eases so the tiles glide instead of jumping
        local skey = comp.id .. "_" .. tostring(info.drawable)
        if ui.stripKey ~= skey then
            ui.stripKey, ui.stripOff, ui.stripOffA = skey, 0, 0
        end
        local maxOff = math.max(0, tCount - maxTiles)
        ui.stripOff = clamp(ui.stripOff or 0, 0, maxOff)
        ui.stripOffA = damp(ui.stripOffA or 0, ui.stripOff, 14, ui.dt)

        if needNav then
            local ay = vy + (tile - 24) * 0.5
            local step = math.max(1, maxTiles - 1)
            local lA = alpha * (ui.stripOff > 0 and 1 or 0.35)
            local rA = alpha * (ui.stripOff < maxOff and 1 or 0.35)
            if glassButton("stripL", "", x1 + 8, ay, arrowW, 24, COL.panel,
                lA, wx, wy, "earlier variants") then
                ui.stripOff = math.max(0, ui.stripOff - step)
            end
            ImGui.AddTriangleFilled(
                x1 + 8 + arrowW * 0.64, ay + 7,
                x1 + 8 + arrowW * 0.64, ay + 17,
                x1 + 8 + arrowW * 0.32, ay + 12,
                COL.text[1], COL.text[2], COL.text[3], math.floor(210 * lA))
            local rxA = stripX2 + 6
            if glassButton("stripR", "", rxA, ay, arrowW, 24, COL.panel,
                rA, wx, wy, "more variants") then
                ui.stripOff = math.min(maxOff, ui.stripOff + step)
            end
            ImGui.AddTriangleFilled(
                rxA + arrowW * 0.36, ay + 7,
                rxA + arrowW * 0.36, ay + 17,
                rxA + arrowW * 0.68, ay + 12,
                COL.text[1], COL.text[2], COL.text[3], math.floor(210 * rA))
        end

        -- the strip itself: every variant is drawn, the clip rect windows it
        ImGui.PushClipRect(stripX1 - 2, vy - 6, stripX2 + 2, vy + tile + 6, true)
        for tx = 0, tCount - 1 do
            local tx1 = stripX1 + (tx - ui.stripOffA) * (tile + gap)
            if tx1 + tile > stripX1 - tile and tx1 < stripX2 + tile then
                local sa = ui.stripAnim[tx] or { hover = 0 }
                ui.stripAnim[tx] = sa

                ImGui.SetCursorPos(tx1 - wx, vy - wy)
                local clicked = ImGui.InvisibleButton("##var" .. tx, tile, tile)
                sa.hover = damp(sa.hover, ImGui.IsItemHovered() and 1 or 0, 14, ui.dt)

                local isCurTex = (info.tex == tx)
                if isCurTex then
                    glowRect(tx1, vy, tx1 + tile, vy + tile,
                        COL.accent[1], COL.accent[2], COL.accent[3], 0.35 * alpha, 4, 7)
                end
                ImGui.AddRectFilled(tx1, vy, tx1 + tile, vy + tile,
                    COL.panel[1], COL.panel[2], COL.panel[3],
                    math.floor((26 + 22 * sa.hover) * alpha), 7)

                local t = ensureThumb(comp, gender, info.drawable, tx)
                if t.st == "ready" and t.tex then
                    local okI = pcall(function()
                        local imTex = t.tex:GetCurrent()
                        if imTex then
                            ImGui.AddImageRounded(imTex, tx1 + 2, vy + 2,
                                tx1 + tile - 2, vy + tile - 2,
                                0, 0, 1, 1, u32(255, 255, 255, math.floor(255 * alpha)), 5)
                        end
                    end)
                    if not okI then t.st = "failed" end
                end
                if t.st ~= "ready" then
                    local lbl = tostring(tx)
                    local tw = ImGui.CalcTextSize(lbl)
                    ImGui.AddText(tx1 + (tile - tw) / 2, vy + tile / 2 - 8, lbl,
                        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(150 * alpha))
                end
                if isCurTex then
                    ImGui.AddRect(tx1, vy, tx1 + tile, vy + tile,
                        COL.accentHi[1], COL.accentHi[2], COL.accentHi[3],
                        math.floor(220 * alpha), 7, 0, 1.3)
                end
                if clicked and not isCurTex then
                    applyVariation(comp.id, info.drawable, tx)
                end
            end
        end
        ImGui.PopClipRect()
    end
end

-- Bottom-right resize grip; mutates WIN_W/WIN_H directly.
-- Right-click resets to the default size.
local function drawResizeGrip(wx, wy, alpha)
    local sz = 18
    ImGui.SetCursorPos(WIN_W - sz - 2, WIN_H - sz - 2)
    ImGui.InvisibleButton("##lfresize", sz, sz)
    local hov = ImGui.IsItemHovered()
    ui.resizing = false
    if ImGui.IsItemActive() and ImGui.IsMouseDragging(0, 0.0) then
        local dx, dy = ImGui.GetMouseDragDelta(0, 0.0)
        ImGui.ResetMouseDragDelta(0)
        WIN_W = clamp(WIN_W + dx, WIN_MIN_W, WIN_MAX_W)
        WIN_H = clamp(WIN_H + dy, WIN_MIN_H, WIN_MAX_H)
        ui.sizeDirty = true
        ui.resizing = true
        hov = true
    end
    if hov then
        local okC, rClicked = pcall(ImGui.IsItemClicked, 1)
        if not okC then
            local okM, m = pcall(ImGui.IsMouseClicked, 1)
            rClicked = okM and m
        end
        if rClicked then
            WIN_W, WIN_H = 960, 600
            ui.sizeDirty = true
            ui.winMoveAt = ui.now
            lfToast("Size reset", "Back to the default 960 x 600.")
        end
    end
    ui.gripHov = damp(ui.gripHov or 0, hov and 1 or 0, 14, ui.dt)

    local a = math.floor((70 + 130 * ui.gripHov) * alpha)
    local bx, by = wx + WIN_W - 5, wy + WIN_H - 5
    for i = 1, 3 do
        local o = i * 4
        ImGui.AddLine(bx - o, by, bx, by - o,
            COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], a, 1.2)
    end
end

local function drawFooter(wx, wy, alpha)
    local y = wy + WIN_H - FOOTER_H
    maybeLogThumbStates()   -- diagnostics go to the log file only
    ImGui.AddText(wx + PAD + 4, y + 4, "LiquidFit",
        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(120 * alpha))

    -- on-screen hints that are UX rather than debug: bootstrap progress on
    -- first run, and the menu-closed note (mouse does nothing otherwise)
    local right
    if boot.st == "downloading" then
        right = (boot.what == "pack")
            and ("downloading preview pack " .. boot.packPart .. "/" .. THUMB_PARTS .. "...")
            or "first run: downloading assets..."
    elseif boot.st == "unzipping" or boot.st == "settle" then
        right = "installing assets..."
    elseif boot.st == "textstart" or boot.st == "textdl" then
        right = "downloading name data..."
    elseif not GUI.IsOpen() then
        right = "open the Cherax menu to interact"
    end
    if right then
        local rw = ImGui.CalcTextSize(right)
        ImGui.AddText(wx + WIN_W - PAD - 4 - rw, y + 4, right,
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(120 * alpha))
    end
end

-- ============================================================================
-- Own config file: Cherax only persists feature values when the user saves
-- settings manually, so LiquidFit writes its own text config automatically
-- (text survives Cherax's file writes fine; only binary gets corrupted).
-- ============================================================================

local CONFIGPATH = SCRIPTDIR .. "user_config.lua"

local CONFIG_FIELDS = {
    { H.THUMBSIZE,   "int",   "thumbSize" },
    { H.ANIMSPEED,   "float", "animSpeed" },
    { H.PREVIEWZOOM, "float", "zoom" },
    { H.PREVIEWYOFF, "float", "yoff" },
    { H.PVCALIB,     "float", "calibX" },
    { H.PVCALIBY,    "float", "calibY" },
    { H.SHOWNAMES,   "bool",  "showNames" },
    { H.HIDEEMPTY,   "bool",  "hideEmpty" },
    { H.ICONS,       "bool",  "icons" },
    { H.AUTOROTATE,  "bool",  "autoRotate" },
    { H.ONLYMENU,    "bool",  "onlyMenu" },
    { H.USEPROXY,    "bool",  "useProxy" },
    { H.DETACH,      "bool",  "detached" },
    { H.INTRODONE,   "bool",  "introDone" },
    { H.POSX,        "float", "posX" },
    { H.POSY,        "float", "posY" },
    { H.WINW,        "float", "winW" },
    { H.WINH,        "float", "winH" },
    { H.PVWX,        "float", "pvX" },
    { H.PVWY,        "float", "pvY" },
    { H.PVWW,        "float", "pvW" },
    { H.PVWH,        "float", "pvH" },
}

local lastConfigStr = nil

local function serializeConfig()
    local parts = { "return {" }
    for _, f in ipairs(CONFIG_FIELDS) do
        local hash, kind, name = f[1], f[2], f[3]
        if kind == "bool" then
            parts[#parts + 1] = ("%s=%s,"):format(name, tostring(fOn(hash)))
        elseif kind == "int" then
            parts[#parts + 1] = ("%s=%d,"):format(name, fInt(hash))
        else
            parts[#parts + 1] = ("%s=%.4f,"):format(name, fFlt(hash))
        end
    end
    parts[#parts + 1] = "}"
    return table.concat(parts, "\n")
end

local function saveConfig()
    local str = serializeConfig()
    if str ~= lastConfigStr then
        lastConfigStr = str
        FileMgr.WriteFileContent(CONFIGPATH, str, false)
    end
end

local function loadConfig()
    if not FileMgr.DoesFileExist(CONFIGPATH) then return end
    local content = FileMgr.ReadFileContent(CONFIGPATH)
    if not content or #content == 0 then return end
    local chunk = (load or loadstring)(content, "=lfconfig")
    if not chunk then return end
    local ok, cfg = pcall(chunk)
    if not ok or type(cfg) ~= "table" then return end
    local applied = 0
    for _, f in ipairs(CONFIG_FIELDS) do
        local hash, kind, name = f[1], f[2], f[3]
        local v = cfg[name]
        if v ~= nil then
            local feat = FeatureMgr.GetFeature(hash)
            if feat then
                if kind == "bool" then
                    feat:SetBoolValue(v and true or false)
                else
                    feat:SetValue(v)
                end
                applied = applied + 1
            end
        end
    end
    lastConfigStr = serializeConfig()
    Logger.LogInfo(("[%s] config loaded (%d values applied)")
        :format(SCRIPT_NAME, applied))
end

-- ============================================================================
-- Saved outfits (own text file) + the Outfits / About views
-- ============================================================================

local OUTFITSPATH = SCRIPTDIR .. "outfits.lua"
local outfits = nil

local function loadOutfits()
    if outfits then return outfits end
    outfits = {}
    if FileMgr.DoesFileExist(OUTFITSPATH) then
        local ok, res = pcall(function()
            return (load or loadstring)(FileMgr.ReadFileContent(OUTFITSPATH), "=lfoutfits")()
        end)
        if ok and type(res) == "table" then outfits = res end
    end
    return outfits
end

local function saveOutfits()
    local parts = { "return {" }
    for _, o in ipairs(outfits or {}) do
        local name = tostring(o.name or "Outfit"):gsub('[\\"%c]', "")
        parts[#parts + 1] = ('{name="%s",comps={'):format(name)
        for _, e in ipairs(o.comps or {}) do
            parts[#parts + 1] = ("{id=%d,draw=%d,tex=%d},"):format(e.id, e.draw, e.tex)
        end
        parts[#parts + 1] = "}},"
    end
    parts[#parts + 1] = "}"
    FileMgr.WriteFileContent(OUTFITSPATH, table.concat(parts, "\n"), false)
end

-- ----------------------------------------------------------------------------
-- Interop: Cherax's native outfit JSON (Outfits folder) and bbfas-style
-- base64 outfit codes. Slot names below match Cherax's own writer exactly.
-- ----------------------------------------------------------------------------

local CX_COMPS = { [0] = "Head", "Beard", "Hair", "Torso", "Legs", "Hands",
    "Feet", "Teeth", "Special", "Special 2", "Decal", "Tuxedo/Jacket Bib" }
local CX_PROPS = { [0] = "Head", "Eyes", "Ears", "Mouth", "Left Hand",
    "Right Hand", "Left Wrist", "Right Wrist", "Hip" }
local CX_FACE = { "Nose Width", "Nose Peak", "Nose Length", "Nose Bone Curveness",
    "Nose Tip", "Nose Bone Twist", "Eyebrow Height", "Eyebrow Indent",
    "Cheek Bones", "Cheek Sideways Bone Size", "Cheek Bones Width", "Eye Opening",
    "Lip Thickness", "Jaw Bone Width", "Jaw Bone Shape", "Chin Bone",
    "Chin Bone Length", "Chin Bone Shape", "Chin Hole", "Neck Thickness" }

local function outfitValue(o, id)
    for _, e in ipairs(o.comps or {}) do
        if e.id == id then return e end
    end
    return nil
end

local function safeFileName(name)
    local s = tostring(name):gsub('[%c<>:"/\\|%?%*]', ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then s = "outfit" end
    return s
end

-- Write an outfit as a Cherax-native JSON into the Outfits folder so it also
-- shows up in Cherax's own outfit changer. Never deletes anything there.
local function exportCherax(o)
    local parts = {}
    parts[#parts + 1] = '{\n\t"format": "Cherax Entity",\n\t"type": 2,'
    parts[#parts + 1] = ('\t"model": %d,'):format(
        (ped.modelHash and ped.modelHash ~= 0) and ped.modelHash or MODEL_MALE)
    parts[#parts + 1] = '\t"baseFlags": 66863,'
    parts[#parts + 1] = '\t"components": {'
    for cid = 0, 11 do
        local e = outfitValue(o, cid)
        local d = (e and e.draw >= 0) and e.draw or 0
        local t = (e and e.tex >= 0) and e.tex or 0
        parts[#parts + 1] = ('\t\t"%s": {\n\t\t\t"drawable": %d,\n\t\t\t"texture": %d,\n\t\t\t"palette": 0\n\t\t}%s')
            :format(CX_COMPS[cid], d, t, cid < 11 and "," or "")
    end
    parts[#parts + 1] = '\t},\n\t"props": {'
    for a = 0, 8 do
        local e = outfitValue(o, 100 + a)
        local d = (e and e.draw >= 0) and e.draw or -1
        local t = (d >= 0 and e and e.tex >= 0) and e.tex or -1
        parts[#parts + 1] = ('\t\t"%s": {\n\t\t\t"drawable": %d,\n\t\t\t"texture": %d\n\t\t}%s')
            :format(CX_PROPS[a], d, t, a < 8 and "," or "")
    end
    parts[#parts + 1] = '\t},\n\t"face_features": {'
    for i, k in ipairs(CX_FACE) do
        parts[#parts + 1] = ('\t\t"%s": 0.0%s'):format(k, i < #CX_FACE and "," or "")
    end
    parts[#parts + 1] = '\t},\n\t"primary_hair_tint": 255,\n\t"secondary_hair_tint": 255\n}'
    local path = ROOT .. "Outfits\\" .. safeFileName(o.name) .. ".json"
    FileMgr.WriteFileContent(path, table.concat(parts, "\n"), false)
    return path
end

local CX_COMP_ID, CX_PROP_ID = {}, {}
for id = 0, 11 do CX_COMP_ID[CX_COMPS[id]] = id end
for a = 0, 8 do CX_PROP_ID[CX_PROPS[a]] = 100 + a end

-- Parse a Cherax outfit JSON into our comps list (pattern-scoped; the format
-- is machine-written and regular, so no full JSON parser is needed).
local function parseCheraxOutfit(content)
    local compSec = content:match('"components"(.-)"props"')
    local propSec = content:match('"props"(.*)$')
    if not compSec or not propSec then return nil end
    local comps = {}
    local SLOT = '"([^"]+)"%s*:%s*{%s*"drawable"%s*:%s*(-?%d+)%s*,%s*"texture"%s*:%s*(-?%d+)'
    for nm, d, t in compSec:gmatch(SLOT) do
        local id = CX_COMP_ID[nm]
        if id and id >= 1 then   -- skip Head: faces are head-blend driven
            comps[#comps + 1] = { id = id, draw = tonumber(d), tex = tonumber(t) }
        end
    end
    for nm, d, t in propSec:gmatch(SLOT) do
        local id = CX_PROP_ID[nm]
        if id then
            comps[#comps + 1] = { id = id, draw = tonumber(d), tex = tonumber(t) }
        end
    end
    if #comps == 0 then return nil end
    return comps
end

-- Pull every Cherax-format outfit from the Outfits folder into the collection
-- (skips names already present).
local function importCheraxOutfits()
    local files = FileMgr.FindFiles(ROOT .. "Outfits\\", ".json", false) or {}
    loadOutfits()
    local existing = {}
    for _, o in ipairs(outfits) do existing[tostring(o.name)] = true end
    local added = 0
    for _, f in ipairs(files) do
        pcall(function()
            local content = FileMgr.ReadFileContent(f)
            if not content or not content:find('"Cherax Entity"', 1, true) then return end
            local comps = parseCheraxOutfit(content)
            if not comps then return end
            local name = (f:match("([^\\/]+)%.[jJ][sS][oO][nN]$") or "Imported")
                :gsub("~[^~]*~", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then name = "Imported outfit" end
            if not existing[name] then
                outfits[#outfits + 1] = { name = name, comps = comps }
                existing[name] = true
                added = added + 1
            end
        end)
    end
    if added > 0 then pcall(saveOutfits) end
    return added
end

-- ---- bbfas-style base64 outfit codes ----

local B64CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64REV = {}
for i = 1, 64 do B64REV[B64CHARS:sub(i, i)] = i - 1 end

local function b64encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64CHARS:sub(c1 + 1, c1 + 1) .. B64CHARS:sub(c2 + 1, c2 + 1)
            .. (b and B64CHARS:sub(c3 + 1, c3 + 1) or "=")
            .. (c and B64CHARS:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end

local function b64decode(s)
    local out = {}
    local n, bits = 0, 0
    for ch in s:gmatch("[^=%s]") do
        local v = B64REV[ch]
        if v ~= nil then
            n = n * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                out[#out + 1] = string.char(math.floor(n / 2 ^ bits) % 256)
                n = n % 2 ^ bits
            end
        end
    end
    return table.concat(out)
end

local function outfitToCode(o)
    local ci, ct, pi, pt = {}, {}, {}, {}
    for i = 0, 11 do ci[i], ct[i] = -1, -1 end
    for i = 0, 7 do pi[i], pt[i] = -1, -1 end
    for _, e in ipairs(o.comps or {}) do
        if e.id >= 100 and e.id <= 107 then
            pi[e.id - 100], pt[e.id - 100] = e.draw, math.max(e.tex, e.draw >= 0 and 0 or -1)
        elseif e.id >= 0 and e.id <= 11 then
            ci[e.id], ct[e.id] = e.draw, math.max(e.tex, 0)
        end
    end
    local L = { "Item", "DI" }
    for i = 0, 11 do L[#L + 1] = "pCI" .. i; L[#L + 1] = tostring(ci[i]) end
    L[#L + 1] = "/DI"; L[#L + 1] = "DT"
    for i = 0, 11 do L[#L + 1] = "pCT" .. i; L[#L + 1] = tostring(ct[i]) end
    L[#L + 1] = "/DT"; L[#L + 1] = "Pi"
    for i = 0, 7 do L[#L + 1] = "pPi" .. i; L[#L + 1] = tostring(pi[i]) end
    L[#L + 1] = "/Pi"; L[#L + 1] = "Pt"
    for i = 0, 7 do L[#L + 1] = "pPt" .. i; L[#L + 1] = tostring(pt[i]) end
    L[#L + 1] = "/Pt"; L[#L + 1] = "/Item"
    return b64encode(table.concat(L, "\n") .. "\n")
end

local function codeToOutfit(code)
    code = tostring(code or ""):gsub("%s+", "")
    if code == "" or code:find("[^A-Za-z0-9+/=]") then return nil end
    local ok, text = pcall(b64decode, code)
    if not ok or not text or not text:find("Item", 1, true) then return nil end
    local vals, lastKey = {}, nil
    for line in text:gmatch("[^\r\n]+") do
        local num = tonumber(line)
        if lastKey and num ~= nil then
            vals[lastKey] = num
            lastKey = nil
        elseif line:match("^p[CP][IiTt]") then
            lastKey = line
        else
            lastKey = nil
        end
    end
    local comps = {}
    for i = 1, 11 do   -- skip comp 0 (face)
        local d = vals["pCI" .. i]
        if d and d >= 0 then
            comps[#comps + 1] = { id = i, draw = d, tex = math.max(vals["pCT" .. i] or 0, 0) }
        end
    end
    for i = 0, 7 do
        local d = vals["pPi" .. i]
        if d then
            comps[#comps + 1] = { id = 100 + i, draw = d,
                tex = d >= 0 and math.max(vals["pPt" .. i] or 0, 0) or -1 }
        end
    end
    if #comps == 0 then return nil end
    return comps
end

local function centerBounds(wx, wy)
    local x1 = wx + PAD + RAIL_W + PAD
    local y1 = wy + TITLE_H + PAD
    local x2 = wx + WIN_W - RIGHT_W - PAD * 2
    local y2 = wy + WIN_H - FOOTER_H - PAD
    return x1, y1, x2, y2
end

local function drawOutfitsView(wx, wy, alpha)
    local x1, y1, x2, y2 = centerBounds(wx, wy)
    loadOutfits()

    -- name input + save row
    local rowH, saveW = 26, 140
    ImGui.SetCursorPos(x1 - wx, y1 - wy)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 1.0, 1.0, 1.0, 0.07)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.35, 0.63, 1.0, 0.15)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.35, 0.63, 1.0, 0.25)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.94, 0.96, 0.99, 1.0)
    ImGui.PushItemWidth(x2 - x1 - saveW - 8)
    local newName = ImGui.InputTextWithHint("##lfoutfitname",
        "name this outfit...", ui.outfitName or "", 0)
    if type(newName) == "string" then ui.outfitName = newName end
    ImGui.PopItemWidth()
    ImGui.PopStyleColor(4)

    if glassButton("btnSaveOutfit", "Save Current", x2 - saveW, y1, saveW, rowH,
        COL.good, alpha, wx, wy, "save what you are wearing right now") then
        if ped.valid then
            local name = (ui.outfitName ~= "" and ui.outfitName)
                or ("Outfit " .. (#outfits + 1))
            local comps = {}
            for _, comp in ipairs(COMPONENTS) do
                local c = ped.comps[comp.id]
                if c then
                    comps[#comps + 1] = { id = comp.id, draw = c.drawable, tex = c.tex }
                end
            end
            outfits[#outfits + 1] = { name = name, comps = comps }
            pcall(saveOutfits)
            pcall(exportCherax, outfits[#outfits])
            ui.outfitName = ""
            lfToast("Outfit saved", '"' .. name .. '" saved (Cherax Outfits too).')
        end
    end

    -- import row: paste a bbfas-style code, or pull in Cherax outfit files
    local row2Y = y1 + rowH + 8
    ImGui.SetCursorPos(x1 - wx, row2Y - wy)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 1.0, 1.0, 1.0, 0.07)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.35, 0.63, 1.0, 0.15)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.35, 0.63, 1.0, 0.25)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.94, 0.96, 0.99, 1.0)
    ImGui.PushItemWidth(x2 - x1 - 164)
    local newCode = ImGui.InputTextWithHint("##lfimportcode",
        "paste an outfit code (bbfas etc)...", ui.importCode or "", 0)
    if type(newCode) == "string" then ui.importCode = newCode end
    ImGui.PopItemWidth()
    ImGui.PopStyleColor(4)

    if glassButton("btnImportCode", "Import", x2 - 156, row2Y, 70, rowH,
        COL.accent, alpha, wx, wy, "import the pasted outfit code") then
        local comps = codeToOutfit(ui.importCode)
        if comps then
            loadOutfits()
            local name = "Code outfit " .. (#outfits + 1)
            outfits[#outfits + 1] = { name = name, comps = comps }
            pcall(saveOutfits)
            pcall(exportCherax, outfits[#outfits])
            ui.importCode = ""
            lfToast("Outfit imported", '"' .. name .. '" added. Rename it if you like.')
        else
            lfToast("Invalid code", "That does not look like an outfit code.")
        end
    end
    if glassButton("btnImportCx", "Cherax", x2 - 78, row2Y, 78, rowH,
        COL.panel, alpha, wx, wy, "import outfits from your Cherax Outfits folder") then
        local n = importCheraxOutfits()
        if n > 0 then
            lfToast("Cherax import", n .. (n == 1 and " outfit" or " outfits") .. " added.")
        else
            lfToast("Cherax import", "Nothing new found in the Outfits folder.")
        end
    end

    -- outfit list
    local listY1 = y1 + rowH * 2 + 18
    ImGui.SetCursorPos(x1 - wx, listY1 - wy)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0, 0, 0, 0)
    ImGui.PushStyleColor(ImGuiCol.ScrollbarBg, 0, 0, 0, 0)
    if ImGui.BeginChild("##lfoutfits", x2 - x1, y2 - listY1, false, 0) then
        local csx, csy = ImGui.GetCursorScreenPos()
        local rH, gap = 46, 6
        local rowW = x2 - x1 - 16

        if #outfits == 0 then
            centerText(x1, x2, (listY1 + y2) * 0.5 - 18, "no saved outfits yet",
                COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(150 * alpha))
            centerText(x1, x2, (listY1 + y2) * 0.5 + 2, "dress up, name it, hit Save Current",
                COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(105 * alpha))
        end

        local removeIdx = nil
        for i, o in ipairs(outfits) do
            local ry = csy + (i - 1) * (rH + gap)
            local hov = false
            pcall(function()
                hov = ImGui.IsMouseHoveringRect(csx, ry, csx + rowW, ry + rH, true)
            end)
            local hk = "ofh" .. i
            ui[hk] = damp(ui[hk] or 0, hov and 1 or 0, 14, ui.dt)

            ImGui.AddRectFilled(csx, ry, csx + rowW, ry + rH,
                COL.panel[1], COL.panel[2], COL.panel[3],
                math.floor((24 + 20 * ui[hk]) * alpha), 8)
            ImGui.AddRect(csx, ry, csx + rowW, ry + rH,
                210, 230, 255, math.floor(24 * alpha), 8, 0, 1.0)

            local btnY = ry + 10
            if ui.renameIdx == i then
                -- inline rename: input where the name was, Save / cancel
                ImGui.SetCursorPos(12, ry - csy + 10)
                ImGui.PushStyleColor(ImGuiCol.FrameBg, 1.0, 1.0, 1.0, 0.09)
                ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.35, 0.63, 1.0, 0.15)
                ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.35, 0.63, 1.0, 0.25)
                ImGui.PushStyleColor(ImGuiCol.Text, 0.94, 0.96, 0.99, 1.0)
                ImGui.PushItemWidth(rowW - 12 - 118)
                local nt = ImGui.InputTextWithHint("##lfrename" .. i,
                    "new name...", ui.renameText or "", 0)
                if type(nt) == "string" then ui.renameText = nt end
                ImGui.PopItemWidth()
                ImGui.PopStyleColor(4)

                if glassButton("ofRenOk" .. i, "Save", csx + rowW - 100, btnY,
                    54, 26, COL.good, alpha, csx, csy, "save the new name") then
                    local nn = (ui.renameText or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if nn ~= "" then
                        o.name = nn
                        pcall(saveOutfits)
                        pcall(exportCherax, o)
                        lfToast("Outfit renamed", '"' .. nn .. '" it is.')
                    end
                    ui.renameIdx = nil
                end
                if glassButton("ofRenNo" .. i, "x", csx + rowW - 38, btnY,
                    26, 26, COL.bad, alpha, csx, csy, "cancel") then
                    ui.renameIdx = nil
                end
            else
                textClipped(csx + 12, ry + 6, rowW - 244, tostring(o.name),
                    COL.text[1], COL.text[2], COL.text[3], math.floor(235 * alpha))
                ImGui.AddText(csx + 12, ry + 24, #(o.comps or {}) .. " pieces",
                    COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(130 * alpha))

                -- update (arrow into tray), rename (pencil), code, apply, delete
                local ubx = csx + rowW - 218
                if glassButton("ofUpd" .. i, "", ubx, btnY, 26, 26,
                    COL.good, alpha, csx, csy,
                    "overwrite this outfit with what you are wearing now") then
                    if ped.valid then
                        local comps = {}
                        for _, comp in ipairs(COMPONENTS) do
                            local c = ped.comps[comp.id]
                            if c then
                                comps[#comps + 1] = { id = comp.id, draw = c.drawable, tex = c.tex }
                            end
                        end
                        o.comps = comps
                        pcall(saveOutfits)
                        pcall(exportCherax, o)
                        lfToast("Outfit updated",
                            '"' .. tostring(o.name) .. '" now matches your current look.')
                    end
                end
                ImGui.AddLine(ubx + 13, btnY + 6, ubx + 13, btnY + 14,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha), 1.5)
                ImGui.AddLine(ubx + 13, btnY + 15, ubx + 9, btnY + 11,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha), 1.5)
                ImGui.AddLine(ubx + 13, btnY + 15, ubx + 17, btnY + 11,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha), 1.5)
                ImGui.AddLine(ubx + 8, btnY + 19, ubx + 18, btnY + 19,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha), 1.5)

                local pbx = csx + rowW - 184
                if glassButton("ofRen" .. i, "", pbx, btnY, 26, 26,
                    COL.panel, alpha, csx, csy, "rename this outfit") then
                    ui.renameIdx = i
                    ui.renameText = tostring(o.name or "")
                end
                ImGui.AddLine(pbx + 9, btnY + 17, pbx + 17, btnY + 9,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha), 1.6)
                ImGui.AddTriangleFilled(pbx + 7, btnY + 19, pbx + 9, btnY + 17,
                    pbx + 8.6, btnY + 18.6,
                    COL.text[1], COL.text[2], COL.text[3], math.floor(210 * alpha))

                if glassButton("ofCode" .. i, "<>", csx + rowW - 150, btnY, 26, 26,
                    COL.panel, alpha, csx, csy, "copy this outfit's share code") then
                    local code = outfitToCode(o)
                    local okClip = pcall(ImGui.SetClipboardText, code)
                    if okClip then
                        lfToast("Code copied", "Outfit code is on your clipboard.")
                    else
                        ui.importCode = code
                        lfToast("Code ready", "Copy it from the import box above.")
                    end
                end

                if glassButton("ofApply" .. i, "Apply", csx + rowW - 116, btnY,
                    70, 26, COL.accent, alpha, csx, csy, "wear this outfit") then
                    for _, e in ipairs(o.comps or {}) do
                        applyVariation(e.id, e.draw, e.tex)
                    end
                    lfToast("Outfit applied", '"' .. tostring(o.name) .. '" is on.')
                end
                if glassButton("ofDel" .. i, "x", csx + rowW - 38, btnY,
                    26, 26, COL.bad, alpha, csx, csy, "delete this outfit") then
                    removeIdx = i
                end
            end
        end
        if removeIdx then
            local nm = outfits[removeIdx] and outfits[removeIdx].name
            table.remove(outfits, removeIdx)
            pcall(saveOutfits)
            lfToast("Outfit deleted", '"' .. tostring(nm) .. '" removed.')
            if ui.renameIdx == removeIdx then ui.renameIdx = nil
            elseif ui.renameIdx and ui.renameIdx > removeIdx then
                ui.renameIdx = ui.renameIdx - 1
            end
        end

        ImGui.Dummy(10, #outfits * (rH + gap) + 4)
    end
    ImGui.EndChild()
    ImGui.PopStyleColor(2)
end

local function drawAboutView(wx, wy, alpha)
    local x1, y1, x2, y2 = centerBounds(wx, wy)
    local midX = (x1 + x2) * 0.5
    local topY = y1 + (y2 - y1) * 0.05

    -- the real logo when available (it carries the wordmark, so the drawn
    -- title only appears as a fallback while it loads / if the file is gone)
    local logo = ensureLogo()
    local drewLogo = false
    if logo and logo.st == "ready" and logo.tex then
        local okL = pcall(function()
            local imTex = logo.tex:GetCurrent()
            if imTex then
                local ls = math.min(170, (y2 - y1) * 0.38)
                ImGui.AddImage(imTex, midX - ls / 2, topY, midX + ls / 2, topY + ls,
                    0, 0, 1, 1, u32(255, 255, 255, math.floor(255 * alpha)))
                drewLogo = true
                topY = topY + ls + 2
            end
        end)
        if not okL then logo.st = "failed" end
    end
    if not drewLogo then
        centerText(x1, x2, topY + 8, "L I Q U I D F I T",
            COL.text[1], COL.text[2], COL.text[3], math.floor(255 * alpha))
        centerText(x1, x2, topY + 30, "outfit studio",
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(170 * alpha))
        topY = topY + 56
    end

    centerText(x1, x2, topY, "by oli",
        COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], math.floor(190 * alpha))
    ImGui.AddLine(midX - 60, topY + 26, midX + 60, topY + 26,
        200, 225, 255, math.floor(60 * alpha), 1.0)

    local tips = {
        "click any tile to wear it, variants show below",
        "scroll the category list: hats and glasses live below decals",
        "drag the character to rotate, arrows step 45 degrees",
        "the dice under the preview rolls a random outfit",
        "Keep Outfit locks your look, Revert takes it back",
        "saved outfits also land in Cherax's own Outfits folder",
    }
    local ty = topY + 40
    for _, tip in ipairs(tips) do
        centerText(x1, x2, ty, tip,
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(140 * alpha))
        ty = ty + 20
    end

    centerText(x1, x2, y2 - 40, "v" .. VERSION,
        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(110 * alpha))
    centerText(x1, x2, y2 - 22, "build " .. BUILD,
        COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(55 * alpha))
end

-- ============================================================================
-- First-run intro: one glass card that replaces the window content until the
-- user picks an option. Shown only while the preview pack is not installed,
-- and never again after any choice (persisted through the config file).
-- ============================================================================

local function introDismiss()
    ui.showIntro = false
    pcall(function()
        FeatureMgr.GetFeature(H.INTRODONE):SetBoolValue(true)
    end)
    pcall(saveConfig)
    lfToast("Welcome to LiquidFit",
        "If the preview character drifts, set Preview Calibration in the LiquidFit tab.")
end

local function drawIntro(wx, wy, alpha)
    local x1 = wx + PAD
    local y1 = wy + TITLE_H + PAD
    local x2 = wx + WIN_W - PAD
    local y2 = wy + WIN_H - FOOTER_H - PAD
    local a = alpha

    -- the card rises the last few pixels as it fades in
    local rise = (1 - clamp(ui.introA or 0, 0, 1)) * 14
    local cw = math.min(560, x2 - x1 - 60)
    local ch = math.min(345, y2 - y1 - 20)
    local cx1 = (x1 + x2 - cw) * 0.5
    local cy1 = (y1 + y2 - ch) * 0.5 + rise
    local cx2, cy2 = cx1 + cw, cy1 + ch

    glowRect(cx1, cy1, cx2, cy2, COL.accent[1], COL.accent[2], COL.accent[3],
        0.18 * a, 10, 14)
    glassPanel(cx1, cy1, cx2, cy2, 14, 40)

    local ty = cy1 + 18
    local logo = ensureLogo()
    local drewLogo = false
    if logo and logo.st == "ready" and logo.tex then
        pcall(function()
            local imTex = logo.tex:GetCurrent()
            if imTex then
                local ls = math.min(96, ch * 0.3)
                ImGui.AddImage(imTex, (cx1 + cx2 - ls) * 0.5, ty,
                    (cx1 + cx2 + ls) * 0.5, ty + ls,
                    0, 0, 1, 1, u32(255, 255, 255, math.floor(255 * a)))
                drewLogo = true
                ty = ty + ls + 6
            end
        end)
    end
    if not drewLogo then
        centerText(cx1, cx2, ty + 10, "L I Q U I D F I T",
            COL.text[1], COL.text[2], COL.text[3], math.floor(255 * a))
        ty = ty + 44
    end

    centerText(cx1, cx2, ty, "Welcome to LiquidFit",
        COL.text[1], COL.text[2], COL.text[3], math.floor(250 * a))
    ty = ty + 20
    centerText(cx1, cx2, ty, "one quick setup step before you start",
        COL.accentHi[1], COL.accentHi[2], COL.accentHi[3], math.floor(190 * a))
    ty = ty + 28

    local lines = {
        "item names install automatically, nothing to do there",
        "the preview pack is what makes LiquidFit shine: real pictures",
        "for all 27,000+ clothing items. download once, and its ready.",
    }
    for _, ln in ipairs(lines) do
        centerText(cx1, cx2, ty, ln,
            COL.textDim[1], COL.textDim[2], COL.textDim[3], math.floor(170 * a))
        ty = ty + 20
    end
    ty = ty + 14

    -- primary action: big and breathing, unmistakably the intended path
    local bw1, bh1 = 250, 36
    local bxp = (cx1 + cx2 - bw1) * 0.5
    local pulse = 0.26 + 0.14 * math.sin((ui.now or 0) * 2.6)
    glowRect(bxp, ty, bxp + bw1, ty + bh1,
        COL.accent[1], COL.accent[2], COL.accent[3], pulse * a, 9, 10)
    if glassButton("introGet", "Copy Install Link", bxp, ty, bw1, bh1,
        COL.accent, a, wx, wy,
        "copies " .. PACK_URL .. " - open it in your browser and follow the steps") then
        copyPackLink()
        introDismiss()
    end
    ty = ty + bh1 + 14

    -- quiet escape hatch: plain dim text, deliberately easy to overlook
    local skip = "not now (not recommended)"
    local sw = ImGui.CalcTextSize(skip)
    local sx = (cx1 + cx2 - sw) * 0.5
    ImGui.SetCursorPos(sx - wx - 4, ty - wy - 3)
    local skipClicked = ImGui.InvisibleButton("##introskip", sw + 8, 20)
    local skipHov = ImGui.IsItemHovered()
    if skipHov then
        pcall(ImGui.SetTooltip, "items will show as blank tiles until the pack is installed")
    end
    ui.introSkipHov = damp(ui.introSkipHov or 0, skipHov and 1 or 0, 14, ui.dt)
    ImGui.AddText(sx, ty, skip,
        COL.textDim[1], COL.textDim[2], COL.textDim[3],
        math.floor((105 + 95 * ui.introSkipHov) * a))
    if ui.introSkipHov > 0.05 then
        ImGui.AddLine(sx, ty + 16, sx + sw, ty + 16,
            COL.textDim[1], COL.textDim[2], COL.textDim[3],
            math.floor(110 * ui.introSkipHov * a), 1.0)
    end
    if skipClicked then
        introDismiss()
    end
end

-- ============================================================================
-- Master render
-- ============================================================================

local function onPresent()
    local now = os.clock()
    local dt = ui.lastTime and math.min(now - ui.lastTime, 0.1) or 0.016
    ui.lastTime, ui.now, ui.dt = now, now, dt

    -- toasts live on the background draw list, independent of the window
    pcall(drawToasts, dt)

    local open = fOn(H.OPEN)
    if fOn(H.ONLYMENU) and not GUI.IsOpen() then open = false end

    local speed = fFlt(H.ANIMSPEED)
    ui.anim = damp(ui.anim, open and 1 or 0, speed, dt)
    -- snap when effectively settled, so the slide offset becomes exactly zero
    -- (an asymptotic ease keeps the window micro-moving forever otherwise,
    -- which made the ped preview's movement gate flicker)
    if ui.anim > 0.999 then ui.anim = 1.0 end
    if ui.anim < 0.02 then
        ui.wasOpen = false
        return
    end

    -- first frame after opening: snapshot outfit + prime counts
    if open and not ui.wasOpen then
        ui.wasOpen = true
        wantRefresh = true
        wantSnapshot = true
        wantCounts[currentComp().id] = true
        ui.gridAppearAt = now
        if ui.firstRun then
            ui.firstRun = nil
            lfToast("Welcome to LiquidFit",
                "If the character drifts, set Preview Calibration in the LiquidFit tab.")
        end
    end

    -- restore / init window size (once)
    if not ui.sizeInit then
        ui.sizeInit = true
        local sw = FeatureMgr.GetFeatureFloat(H.WINW)
        local sh = FeatureMgr.GetFeatureFloat(H.WINH)
        if sw and sw > 0 then WIN_W = clamp(sw, WIN_MIN_W, WIN_MAX_W) end
        if sh and sh > 0 then WIN_H = clamp(sh, WIN_MIN_H, WIN_MAX_H) end
    end
    -- preview column scales gently with window width; collapses entirely
    -- when the preview is detached into its own window
    local detached = fOn(H.DETACH)
    RIGHT_W = detached and 0 or math.floor(clamp(WIN_W * 0.25, 220, 340))

    -- restore / init window position
    if ui.pos.x < 0 then
        local px = FeatureMgr.GetFeatureFloat(H.POSX)
        local py = FeatureMgr.GetFeatureFloat(H.POSY)
        if px >= 0 and py >= 0 then
            ui.pos.x, ui.pos.y = px, py
        else
            local dw, dh = ImGui.GetDisplaySize()
            ui.pos.x = (dw - WIN_W) * 0.5
            ui.pos.y = (dh - WIN_H) * 0.5
        end
    end

    -- clamp to screen
    local dw, dh = ImGui.GetDisplaySize()
    ui.pos.x = clamp(ui.pos.x, -WIN_W * 0.6, dw - WIN_W * 0.4)
    ui.pos.y = clamp(ui.pos.y, 0, dh - 60)

    -- persist position + size occasionally
    if (ui.posSaveAt or 0) < now then
        ui.posSaveAt = now + 2.0
        FeatureMgr.GetFeature(H.POSX):SetValue(ui.pos.x + 0.0)
        FeatureMgr.GetFeature(H.POSY):SetValue(ui.pos.y + 0.0)
        if ui.sizeDirty then
            ui.sizeDirty = false
            FeatureMgr.GetFeature(H.WINW):SetValue(WIN_W + 0.0)
            FeatureMgr.GetFeature(H.WINH):SetValue(WIN_H + 0.0)
        end
        if ui.pvDirty and ui.pvPos then
            ui.pvDirty = false
            FeatureMgr.GetFeature(H.PVWX):SetValue(ui.pvPos.x + 0.0)
            FeatureMgr.GetFeature(H.PVWY):SetValue(ui.pvPos.y + 0.0)
            FeatureMgr.GetFeature(H.PVWW):SetValue(ui.pvW + 0.0)
            FeatureMgr.GetFeature(H.PVWH):SetValue(ui.pvH + 0.0)
        end
        pcall(saveConfig)
    end

    -- first-run intro crossfade: while visible it replaces the main content;
    -- when dismissed the grid staggers in as the card fades out
    ui.introA = damp(ui.introA or 0, ui.showIntro and 1 or 0, 10, dt)
    local introVisible = ui.showIntro or ui.introA > 0.05
    if introVisible then
        ui.introWasVisible = true
    elseif ui.introWasVisible then
        ui.introWasVisible = false
        ui.gridAppearAt = now
    end

    local ease = 1 - (1 - ui.anim) * (1 - ui.anim)
    local slide = (1 - ease) * 18
    local wx, wy = ui.pos.x, ui.pos.y + slide

    ImGui.SetNextWindowPos(wx, wy, 1)          -- 1 = ImGuiCond_Always
    ImGui.SetNextWindowSize(WIN_W, WIN_H, 1)
    ImGui.SetNextWindowBgAlpha(0.0)            -- we paint our own glass
    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, ease)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 14.0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0.0)

    local flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize
        | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoCollapse
        | ImGuiWindowFlags.NoScrollWithMouse

    ImGui.Begin("##LiquidFitWindow", true, flags)

    -- Draw inside a protected call so a single bad draw can never skip
    -- ImGui.End()/PopStyleVar (that corrupts the whole ImGui frame).
    local aMul = ease
    local okDraw, errDraw = pcall(function()
        drawGlassBody(wx, wy, aMul, not detached and not introVisible)
        drawTitleBar(wx, wy, aMul)
        if introVisible then
            drawIntro(wx, wy, aMul * clamp(ui.introA, 0, 1))
        else
            drawRail(wx, wy, aMul)
            if ui.view == "outfits" then
                drawOutfitsView(wx, wy, aMul)
            elseif ui.view == "about" then
                drawAboutView(wx, wy, aMul)
            else
                drawGrid(wx, wy, aMul)
                drawItemCard(wx, wy, aMul)
            end
            if not detached then
                drawPreviewColumn(wx, wy, aMul)
            end
        end
        drawFooter(wx, wy, aMul)
        drawResizeGrip(wx, wy, aMul)
    end)

    ImGui.End()

    -- the detached preview is its own window, drawn while the same style
    -- pushes are active so it inherits the rounding and fade
    if detached then
        pcall(drawDetachedPreview, ease)
    end

    ImGui.PopStyleVar(3)

    if not okDraw and (ui.lastDrawErrAt or 0) < now then
        ui.lastDrawErrAt = now + 5
        Logger.LogInfo("[" .. SCRIPT_NAME .. "] draw error: " .. tostring(errDraw))
    end
end

FeatureMgr.AddFeature(H.RENDER, "LiquidFit Renderer", eFeatureType.Toggle,
    "Internal renderer - keep enabled.", function()
        if staleInstance() then return end
        local ok, err = pcall(onPresent)
        if not ok and (ui.lastErrAt or 0) < os.clock() then
            ui.lastErrAt = os.clock() + 5
            Logger.LogInfo("[" .. SCRIPT_NAME .. "] render error: " .. tostring(err))
        end
    end, false)
    :SetVisible(false):SetSaveable(false):SetBoolValue(true)
    :RegisterCallbackTrigger(eCallbackTrigger.OnPresent)

-- ============================================================================
-- Cherax tab
-- ============================================================================

ClickGUI.AddTab("LiquidFit", function()
    if ClickGUI.BeginCustomChildWindow("Outfit Studio") then
        ClickGUI.RenderFeature(H.OPEN)
        ClickGUI.RenderFeature(H.DETACH)
        ClickGUI.RenderFeature(H.ONLYMENU)
        ClickGUI.RenderFeature(H.ANIMSPEED)
        ClickGUI.EndCustomChildWindow()
    end
    if ClickGUI.BeginCustomChildWindow("Tiles") then
        ClickGUI.RenderFeature(H.THUMBSIZE)
        ClickGUI.RenderFeature(H.SHOWNAMES)
        ClickGUI.RenderFeature(H.HIDEEMPTY)
        ClickGUI.RenderFeature(H.ICONS)
        ClickGUI.RenderFeature(H.AUTOROTATE)
        ClickGUI.RenderFeature(H.PREVIEWZOOM)
        ClickGUI.RenderFeature(H.PREVIEWYOFF)
        ClickGUI.RenderFeature(H.PVCALIB)
        ClickGUI.RenderFeature(H.PVCALIBY)
        ClickGUI.EndCustomChildWindow()
    end
    if ClickGUI.BeginCustomChildWindow("Thumbnails") then
        ClickGUI.RenderFeature(H.GETPACK)
        ClickGUI.RenderFeature(H.USEPROXY)
        ClickGUI.RenderFeature(H.CLEARCACHE)
        ClickGUI.RenderFeature(H.RESETPOS)
        ClickGUI.EndCustomChildWindow()
    end
end)

-- restore the user's saved settings (calibration, sizes, toggles, ...)
-- First run ever (no config yet): open on About so new users see the basics,
-- and queue a welcome toast pointing at preview calibration.
local firstRun = not FileMgr.DoesFileExist(CONFIGPATH)
pcall(loadConfig)

-- First-run intro: shows once while the preview pack is not installed, then
-- never again (any choice persists). A pack already on disk counts as done.
if CACHE_PRESENT then
    if not fOn(H.INTRODONE) then
        pcall(function() FeatureMgr.GetFeature(H.INTRODONE):SetBoolValue(true) end)
    end
elseif not fOn(H.INTRODONE) then
    ui.showIntro = true
end

if firstRun and not ui.showIntro then
    ui.view = "about"
    ui.firstRun = true
end

-- single-file distribution: fetch names/icons/logo on first launch
if assetsMissing() then
    lfToast("First launch setup", "Downloading LiquidFit assets in the background...")
    bootStart("essentials", ASSETS_BASE .. "essentials.zip", "essentials.zip")
end

Logger.LogInfo(("[%s] v%s (build %d) loaded. Toggle 'Open LiquidFit' in the LiquidFit tab. root=%s")
    :format(SCRIPT_NAME, VERSION, BUILD, ROOT))
