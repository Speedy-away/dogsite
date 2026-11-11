--[[
    ═══════════════════════════════════════════════════════════════════════════════════
    PAINTLABS v1.0.0 PRODUCTION
    ═══════════════════════════════════════════════════════════════════════════════════

    vehicle paint studio for cherax.

    description:
    - edits primary/secondary paint, finish, pearlescent, mixer values, smoke, xenon, and neon
    - includes the permanent PaintLabs gallery, Exotic, Ai, Favorites, Remix, and saved paint presets
    - uses the Three Lane editor as the single supported PaintLabs workspace
    - supports non-destructive hover preview with full paint/lighting restoration
    - saves complete paint configurations, including Three Lane, smoke, headlights, neon, and gallery match settings

    notes:
    - normal release logging is intentionally quiet
    - branding assets are cached locally under cherax\lua\PaintLabs\assets
    - branding download addresses are never written to PaintLabs logs, toasts, or status text
    - neon remains opt-in and off by default

    changelog:
    - v0.0.1 - initial Cherax vehicle-paint editor with primary/secondary colors, GTA paint presets, finish controls, pearlescent controls, mixer basics, random paint tools, and preset saving.
    - v0.1.0 - embedded the community color library, added the scrollable family gallery, soft hover preview, click-to-keep behavior, Favorites, Auto Showcase, color-family grouping, and brightness sorting.
    - v0.2.0 - added confirmed in-game pearlescent filtering, polished Guide/Credits tabs, safer preview restoration, full saved-preset controls, and the first preset-focused gallery workflow.
    - v0.3.0 - introduced the grid gallery, Cherax Vec2-safe rendering, Match Tire Smoke, improved preview snapshots, default curated Favorites, and the first built-in Exotic paint presets.
    - v0.4.0 - expanded Exotic into a dedicated gallery section with curated pearlescent combinations, full specialty presets, persistent Favorites behavior, and improved family/navigation handling.
    - v0.5.0 - introduced Ai paint recommendations, expanded them into deliberately contrasting pearl combinations, and grew the Ai library from the first curated set to 100 unique chaos-style paints.
    - v0.6.0 - expanded Ai to 500 unique combinations, added register-safe library loading, introduced Remix This Color with 50 replaceable relatives, preserved favorited remixes, and made neon underglow opt-in/off by default.
    - v0.7.0 - added Remix This Pearlescent, Preset Finish overrides including Chrome/Brushed/Matte/Worn, experimental preset-centric interfaces, and the first Command Center-style editing workflows.
    - v0.8.0 - imported and deduplicated additional community colors, added specialty finish preservation, matured the Command Center into Three Lane, added Contrast and Temperature, and made applied preset/gallery colors editable through Primary, Pearlescent, Mixer, and Randomizer.
    - v0.9.0 - finalized Three Lane, added Match Headlights/Match Neon, advanced hue/tone/name sorting, rebranded to PaintLabs, added full-state presets, PaintLabs/Public_Urinal branding, expanded creator Color Credits, linked creator attribution to paint hover, and completed release cleanup.
    - v1.0.0 - first public production release: compact release-safe paint IDs, provenance-string cleanup, migration-safe Favorites, quiet branding transport, full Color Credits, complete Three Lane workflow, Exotic/Ai/Remix galleries, full lighting/smoke preset persistence, and production packaging.

    developed by: Public_Urinal
    coding assistance: ChatGPT
    community: discord.gg/ZkMH2PspF

    ═══════════════════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════════════════════════
-- bootstrap / identity
-- note: keeps release identity and storage paths in one small block.
-- ═══════════════════════════════════════════════════════════════════════════════════

local SCRIPT_NAME = "PaintLabs"
local SCRIPT_VERSION = "1.0.0"
local SCRIPT_BUILD = "001-PRODUCTION"
local DEVELOPER = "Public_Urinal"
local HELPER_CREDIT = "ChatGPT"
local DISCORD_LINK = "https://discord.gg/ZkMH2PspF"
local DISCORD_DISPLAY = "discord.gg/ZkMH2PspF"
local SCRIPT_PREFIX = "VPJ_"

local legacyPresetPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Paintjobs\\"
local presetPath = FileMgr.GetMenuRootPath() .. "\\Lua\\PaintLabs\\"
local brandAssetDir = presetPath .. "assets\\"

FileMgr.CreateDir(presetPath)
FileMgr.CreateDir(brandAssetDir)


-- ═══════════════════════════════════════════════════════════════════════════════════
-- branding assets
-- note: remote addresses are assembled internally and are never written to logs,
-- toasts, status strings, or error messages. curl verbose output is disabled.
-- ═══════════════════════════════════════════════════════════════════════════════════

local function brand_remote(relativePath)
   local scheme = "https" .. "://"
   local host = "github" .. ".com/"
   local repo = "xReVoLTiThemeDev/" .. "GTAV-Cherax/"
   return scheme .. host .. repo .. "blob/main/" .. tostring(relativePath or "") .. "?raw=true"
end

local brandAssets = {
   PublicUrinal = {
      key = "Public_Urinal",
      remote = brand_remote("Public_Urinal.png"),
      path = brandAssetDir .. "Public_Urinal.png",
      download_started = false,
      load_started = false,
      load_failed = false,
      next_retry_ms = 0,
      texture_id = nil,
      texture_srv = nil,
      last_poll_ms = 0,
      status = "Waiting"
   },
   PaintLabs = {
      key = "PaintLabs",
      remote = brand_remote("PaintLabs/assets/PaintLabs.png"),
      path = brandAssetDir .. "PaintLabs.png",
      download_started = false,
      load_started = false,
      load_failed = false,
      next_retry_ms = 0,
      texture_id = nil,
      texture_srv = nil,
      last_poll_ms = 0,
      status = "Waiting"
   }
}

local function brand_now_ms()
   if Time and Time.GetEpocheMs then
      local ok, value = pcall(Time.GetEpocheMs)
      if ok and tonumber(value) then return tonumber(value) end
   end
   return math.floor((os.clock() or 0) * 1000)
end

local function brand_file_exists(path)
   if FileMgr and FileMgr.DoesFileExist then
      local ok, value = pcall(function() return FileMgr.DoesFileExist(path) end)
      return ok and value == true
   end
   local file = io.open(path, "rb")
   if file then file:close(); return true end
   return false
end

local function reset_brand_texture(asset)
   asset.load_started = false
   asset.load_failed = false
   asset.texture_id = nil
   asset.texture_srv = nil
   asset.last_poll_ms = 0
end

local function load_brand_asset(asset)
   if not asset then return nil end
   if asset.texture_srv then return asset.texture_srv end
   if asset.load_failed then return nil end
   if not brand_file_exists(asset.path) then return nil end
   if not Texture then
      asset.load_failed = true
      asset.status = "Texture unavailable"
      return nil
   end

   if not asset.texture_id then
      if asset.load_started then return nil end
      asset.load_started = true
      asset.status = "Loading"

      local textureId
      if Texture.LoadTextureAsync then
         textureId = Texture.LoadTextureAsync(asset.path)
      elseif Texture.LoadTexture then
         textureId = Texture.LoadTexture(asset.path)
      end

      textureId = tonumber(textureId)
      if not textureId or textureId == 0 then
         asset.load_failed = true
         asset.status = "Texture unavailable"
         return nil
      end
      asset.texture_id = textureId
   end

   local now = brand_now_ms()
   if now - (tonumber(asset.last_poll_ms) or 0) < 125 then return nil end
   asset.last_poll_ms = now

   local textureId = tonumber(asset.texture_id or 0) or 0
   if textureId == 0 then return nil end
   if Texture.IsTextureValid and Texture.IsTextureValid(textureId) ~= true then return nil end

   local texture = Texture.GetTexture and Texture.GetTexture(textureId) or nil
   if not texture then return nil end
   local srv = texture:GetCurrent()
   if not srv then return nil end

   asset.texture_srv = srv
   asset.status = "Ready"
   return srv
end

local function download_brand_asset(asset)
   if not asset then return end
   if brand_file_exists(asset.path) then load_brand_asset(asset); return end
   if asset.download_started then return end
   if brand_now_ms() < (tonumber(asset.next_retry_ms) or 0) then return end
   if not Script or not Script.QueueJob or not Curl or not Curl.Easy then
      asset.status = "Asset unavailable"
      return
   end

   asset.download_started = true
   asset.status = "Downloading"

   Script.QueueJob(function()
      local ok = pcall(function()
         local curl = Curl.Easy()

         -- curl option 41 is curlopt_verbose. keep it disabled so transport details
         -- cannot surface the private branding address through normal curl diagnostics.
         pcall(function() curl:Setopt(41, 0) end)
         curl:Setopt(10002, asset.remote)
         curl:Setopt(52, 1)
         curl:Setopt(10018, "Mozilla/5.0 PaintLabs-Cherax")
         curl:Perform()

         local ticks = 0
         while not curl:GetFinished() and ticks < 300 do
            Script.Yield(50)
            ticks = ticks + 1
         end
         if not curl:GetFinished() then error("asset timeout") end

         local code, content = curl:GetResponse()
         local success = code == 0 or code == true or (eCurlCode and code == eCurlCode.CURLE_OK)
         local looksLikePng = type(content) == "string" and #content > 100
            and ((content:byte(1) == 137 and content:sub(2, 4) == "PNG") or #content > 1000)
         if not success or not looksLikePng then error("asset download") end

         FileMgr.CreateDir(brandAssetDir)
         local file = io.open(asset.path, "wb")
         if not file then error("asset save") end
         file:write(content)
         file:close()

         reset_brand_texture(asset)
         asset.next_retry_ms = 0
         asset.status = "Ready"
         load_brand_asset(asset)
      end)

      asset.download_started = false
      if not ok then
         -- intentionally generic: never copy transport details into status text.
         asset.status = "Asset unavailable"
         asset.next_retry_ms = brand_now_ms() + 60000
      end
   end)
end

local function ensure_brand_asset(asset)
   if not asset then return nil end
   if brand_file_exists(asset.path) then return load_brand_asset(asset) end
   download_brand_asset(asset)
   return nil
end


-- ═══════════════════════════════════════════════════════════════════════════════════
-- storage migration
-- ═══════════════════════════════════════════════════════════════════════════════════

local function migrate_legacy_storage()
   pcall(function()
      local oldJson = FileMgr.FindFiles(legacyPresetPath, ".json", false) or {}
      for _, oldFile in ipairs(oldJson) do
         local fileName = tostring(oldFile):match("([^\\/]+%.json)$")
         if fileName then
            local newFile = presetPath .. fileName
            if not FileMgr.DoesFileExist(newFile) then
               local raw = FileMgr.ReadFileContent(oldFile)
               if raw and raw ~= "" then FileMgr.WriteFileContent(newFile, raw) end
            end
         end
      end

      for _, fileName in ipairs({"favorites.txt", "remix_favorites.txt", "defaults_build010_seeded.txt"}) do
         local oldFile = legacyPresetPath .. fileName
         local newFile = presetPath .. fileName
         if FileMgr.DoesFileExist(oldFile) and not FileMgr.DoesFileExist(newFile) then
            local raw = FileMgr.ReadFileContent(oldFile)
            if raw then FileMgr.WriteFileContent(newFile, raw) end
         end
      end
   end)
end

migrate_legacy_storage()


-- ═══════════════════════════════════════════════════════════════════════════════════
-- native wrappers
-- note: follows the hustlemeter direct-wrapper style to avoid lua main-chunk local limits.
-- ═══════════════════════════════════════════════════════════════════════════════════

local InvokeInt, InvokeVoid = Natives.InvokeInt, Natives.InvokeVoid
PLAYER_PED_ID = function(...) return InvokeInt(0xD80958FC74E988A6, ...) end;
SET_VEHICLE_MOD_KIT = function(...) return InvokeVoid(0x1F2AA07F00B3217A, ...) end;
SET_VEHICLE_COLOURS = function(...) return InvokeVoid(0x4F1D4BE3A7F24601, ...) end;
SET_VEHICLE_EXTRA_COLOURS = function(...) return InvokeVoid(0x2036F561ADD12E33, ...) end;
GET_VEHICLE_EXTRA_COLOURS = function(...) return InvokeVoid(0x3BC4245933A166F7, ...) end;
GET_VEHICLE_COLOURS = function(...) return InvokeVoid(0xA19435F193E081AC, ...) end;
GET_VEHICLE_MOD_COLOR_1 = function(...) return InvokeVoid(0xE8D65CA700C9A693, ...) end;
GET_VEHICLE_MOD_COLOR_2 = function(...) return InvokeVoid(0x81592BE4E3878728, ...) end;
GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM = function(...) return Natives.InvokeBool(0xF095C0405307B21B, ...) end;
GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM = function(...) return Natives.InvokeBool(0x910A32E7AAD2656C, ...) end;
DOES_ENTITY_EXIST = function(...) return Natives.InvokeBool(0x7239B21A38F536BA, ...) end;
SET_VEHICLE_MOD_COLOR_1 = function(...) return InvokeVoid(0x43FEB945EE7F85B8, ...) end;
SET_VEHICLE_MOD_COLOR_2 = function(...) return InvokeVoid(0x816562BADFDEC83E, ...) end;
SET_VEHICLE_CUSTOM_PRIMARY_COLOUR = function(...) return InvokeVoid(0x7141766F91D15BEA, ...) end;
GET_VEHICLE_CUSTOM_PRIMARY_COLOUR = function(...) return InvokeVoid(0xB64CF2CCA9D95F52, ...) end;
SET_VEHICLE_CUSTOM_SECONDARY_COLOUR = function(...) return InvokeVoid(0x36CED73BFED89754, ...) end;
GET_VEHICLE_CUSTOM_SECONDARY_COLOUR = function(...) return InvokeVoid(0x8389CD56CA8072DC, ...) end;
CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR = function(...) return InvokeVoid(0x55E1D2758F34E437, ...) end;
CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR = function(...) return InvokeVoid(0x5FFBDEEC3E8E2009, ...) end;
TOGGLE_VEHICLE_MOD = function(...) return InvokeVoid(0x2A1F4F37F95BAD08, ...) end;
IS_TOGGLE_MOD_ON = function(...) return Natives.InvokeBool(0x84B233A8C8FC8AE7, ...) end;
SET_VEHICLE_TYRE_SMOKE_COLOR = function(...) return InvokeVoid(0xB5BA80F839791C0F, ...) end;
GET_VEHICLE_TYRE_SMOKE_COLOR = function(...) return InvokeVoid(0xB635392A4938B3C3, ...) end;
SET_VEHICLE_DIRT_LEVEL = function(...) return InvokeVoid(0x79D3B596FE44EE8B, ...) end;
_SET_VEHICLE_XENON_LIGHT_COLOR = function(...) return InvokeVoid(0xE41033B25D003A07, ...) end;
GET_VEHICLE_XENON_LIGHT_COLOR_INDEX = function(...) return Natives.InvokeInt(0x3DFF319A831E0CDB, ...) end;
_SET_VEHICLE_NEON_LIGHT_ENABLED = function(...) return InvokeVoid(0x2AA720E4287BF269, ...) end;
_GET_VEHICLE_NEON_LIGHT_ENABLED = function(...) return Natives.InvokeBool(0x8C4B92553E4766A5, ...) end;
_SET_VEHICLE_NEON_LIGHTS_COLOUR = function(...) return InvokeVoid(0x8E0A582209A62695, ...) end;
_GET_VEHICLE_NEON_LIGHTS_COLOUR = function(...) return InvokeVoid(0x7619EEE8C886757F, ...) end;
GET_ENTITY_HEADING = function(...) return Natives.InvokeFloat(0xE83D4F9BA2A38914, ...) end;
SET_ENTITY_HEADING = function(...) return InvokeVoid(0x8E2530AA8ADA980E, ...) end;
GET_ENTITY_SPEED = function(...) return Natives.InvokeFloat(0xD5037BA82E12416F, ...) end;
local F = {
   Material = Utils.Joaat(SCRIPT_PREFIX .. "Material"),
   PresetColorCombo = Utils.Joaat(SCRIPT_PREFIX .. "PresetColorCombo"),
   Chameleon = Utils.Joaat(SCRIPT_PREFIX .. "Chameleon"),
   SyncMode = Utils.Joaat(SCRIPT_PREFIX .. "ColorSync"),
   PrimaryColor = Utils.Joaat(SCRIPT_PREFIX .. "PrimaryColor"),
   SecondaryColor = Utils.Joaat(SCRIPT_PREFIX .. "SecondaryColor"),
   LinkPearl = Utils.Joaat(SCRIPT_PREFIX .. "LinkPearl"),
   PearlAggression = Utils.Joaat(SCRIPT_PREFIX .. "PearlAggression"),
   PrimaryPearl = Utils.Joaat(SCRIPT_PREFIX .. "PrimaryPearl"),
   Brightness = Utils.Joaat(SCRIPT_PREFIX .. "Brightness"),
   Saturation = Utils.Joaat(SCRIPT_PREFIX .. "Saturation"),
   HueShift = Utils.Joaat(SCRIPT_PREFIX .. "HueShift"),
   Contrast = Utils.Joaat(SCRIPT_PREFIX .. "Contrast"),
   Temperature = Utils.Joaat(SCRIPT_PREFIX .. "Temperature"),
   InvertColors = Utils.Joaat(SCRIPT_PREFIX .. "InvertColors"),
   ResetMixer = Utils.Joaat(SCRIPT_PREFIX .. "ResetMixer"),
   RandomNormal = Utils.Joaat(SCRIPT_PREFIX .. "RandomNormal"),
   RandomChameleon = Utils.Joaat(SCRIPT_PREFIX .. "RandomChameleon"),
   CustomChameleon = Utils.Joaat(SCRIPT_PREFIX .. "CustomChameleon"),
   RandomMixer = Utils.Joaat(SCRIPT_PREFIX .. "RandomMixer"),
   EnableNeon = Utils.Joaat(SCRIPT_PREFIX .. "EnableNeon"),
   NeonColor = Utils.Joaat(SCRIPT_PREFIX .. "NeonColor"),
   XenonColor = Utils.Joaat(SCRIPT_PREFIX .. "XenonColor"),
   TyreSmokeColor = Utils.Joaat(SCRIPT_PREFIX .. "TyreSmokeColor"),
   PresetList = Utils.Joaat(SCRIPT_PREFIX .. "PresetList"),
   PresetName = Utils.Joaat(SCRIPT_PREFIX .. "PresetName"),
   LoadButton = Utils.Joaat(SCRIPT_PREFIX .. "Load"),
   SaveButton = Utils.Joaat(SCRIPT_PREFIX .. "Save"),
   DeleteButton = Utils.Joaat(SCRIPT_PREFIX .. "Delete"),
   EnablePearl = Utils.Joaat(SCRIPT_PREFIX .. "EnablePearl"),
   DirtLevel = Utils.Joaat(SCRIPT_PREFIX .. "DirtLevel"),
   ArchiveSearch = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveSearch"),
   ArchiveReadyOnly = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveReadyOnly"),
   ArchiveColorFamily = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveColorFamily"),
   ArchiveBrightnessOrder = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveBrightnessOrder"),
   ArchiveHoverPreview = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveHoverPreview"),
   ArchiveMatchTyreSmoke = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveMatchTyreSmoke"),
   ArchiveMatchHeadlights = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveMatchHeadlights"),
   ArchiveMatchNeon = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveMatchNeon"),
   ArchiveFinish = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveFinish"),
   ArchiveAutoShowcase = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveAutoShowcase"),
   ArchiveShowcaseSeconds = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveShowcaseSeconds"),
   ArchiveRotateVehicle = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveRotateVehicle"),
   ArchiveRotateSpeed = Utils.Joaat(SCRIPT_PREFIX .. "ArchiveRotateSpeed")
}

local Materials = {
   { name = "Metallic", type = 1, id = { 0,1,2,3,4,5,6,7,8,9,10,11,27,28,29,30,31,32,33,34,35,36,37,38,49,50,51,52,53,54,61,62,63,64,65,66,67,68,69,70,71,72,73,74,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,111,112,125,137,142,143,145,150 } },
   { name = "Matte", type = 3, id = { 12,13,14,39,40,41,42,55,82,83,84,128,129,131,148,149,151,152,153,154,155 } },
   -- util + worn + pure are intentionally exposed as one finish. their gta color ids
   -- remain available inside worn so older presets/colors are not lost.
   { name = "Worn", type = 0, id = { 15,16,17,18,19,20,21,22,23,24,25,26,43,44,45,46,47,48,56,57,58,59,60,75,76,77,78,79,80,81,85,86,87,108,109,110,113,114,115,116,121,122,123,124,126,130,132,133,134,158 } },
   { name = "Epsilon", type = 0, id = 157 },
   { name = "Brushed", type = 4, id = { 117,118,119,159 } },
   { name = "Chrome", type = 5, id = 120 },
   { name = "Chameleon", type = 1, id = -1 }
}

local function NormalizeMaterialName(name)
   local n = tostring(name or "")
   if n == "Util" or n == "Pure" then return "Worn" end
   return n
end

local function FindMaterialIndexByName(name)
   local wanted = NormalizeMaterialName(name)
   for i, mat in ipairs(Materials) do
      if tostring(mat.name or "") == wanted then return i - 1 end
   end
   return nil
end

-- legacy finish migration
-- note: older saved presets used metallic, matte, util, worn, pure, epsilon,
-- brushed, chrome, and chameleon indices. util/pure now resolve to worn.
local function LegacyMaterialIndexToCurrent(value)
   local idx = math.floor(tonumber(value) or 0)
   local map = { [0]=0, [1]=1, [2]=2, [3]=2, [4]=2, [5]=3, [6]=4, [7]=5, [8]=6 }
   return map[idx] or 0
end

local function MaterialContainsColorId(mat, id)
   if not mat then return false end
   id = tonumber(id)
   if id == nil then return false end
   if type(mat.id) == "table" then
      for _, mid in ipairs(mat.id) do if tonumber(mid) == id then return true end end
      return false
   end
   return tonumber(mat.id) == id
end

-- gallery finish override
-- note: chameleon is excluded because it replaces the base rgb shader instead of
-- preserving the selected preset color.
local archiveFinishNames = {
   "Original / Preset",
   "Metallic",
   "Matte",
   "Worn",
   "Epsilon",
   "Brushed",
   "Chrome"
}

local HeadlightColors = {
   "White", "Blue", "Electric Blue", "Mint Green", "Lime Green", 
   "Yellow", "Golden Shower", "Orange", "Red", "Pony Pink", 
   "Hot Pink", "Purple", "Blacklight"
}

local presetColors = {
   { id = 134, type = 4, name = "Pure White", r = 255, g = 255, b = 255 }, 
   { id = 158, type = 4, name = "Pure Gold", r = 122, g = 100, b = 64 }, 
   { id = 117, type = 4, name = "Brushed Steel", r = 106, g = 116, b = 124 },
   { id = 118, type = 4, name = "Brushed Black steel", r = 53, g = 65, b = 88 },
   { id = 119, type = 4, name = "Brushed Aluminium", r = 155, g = 160, b = 168 },
   { id = 159, type = 4, name = "Brushed Gold", r = 127, g = 106, b = 72 },
   { id = 15, type = 0, name = "Util Black", r = 21, g = 25, b = 33 },
   { id = 16, type = 0, name = "Util Black Poly", r = 30, g = 36, b = 41 },
   { id = 17, type = 0, name = "Util Dark silver", r = 51, g = 58, b = 60 },
   { id = 18, type = 0, name = "Util Silver", r = 140, g = 144, b = 149 },
   { id = 19, type = 0, name = "Util Gun Metal", r = 57, g = 67, b = 77 },
   { id = 20, type = 0, name = "Util Shadow Silver", r = 80, g = 98, b = 114 },
   { id = 43, type = 0, name = "Util Red", r = 156, g = 16, b = 22 },
   { id = 44, type = 0, name = "Util Bright Red", r = 222, g = 15, b = 24 },
   { id = 45, type = 0, name = "Util Garnet Red", r = 143, g = 30, b = 23 },
   { id = 56, type = 0, name = "Util Dark Green", r = 34, g = 56, b = 62 },
   { id = 57, type = 0, name = "Util Green", r = 29, g = 90, b = 63 },
   { id = 75, type = 0, name = "Util Dark Blue", r = 17, g = 37, b = 82 },
   { id = 76, type = 0, name = "Util Midnight Blue", r = 27, g = 32, b = 62 },
   { id = 77, type = 0, name = "Util Blue", r = 39, g = 81, b = 144 },
   { id = 78, type = 0, name = "Util Sea Foam Blue", r = 96, g = 133, b = 146 },
   { id = 79, type = 0, name = "Util Lightning blue", r = 36, g = 70, b = 168 },
   { id = 80, type = 0, name = "Util Maui Blue Poly", r = 66, g = 113, b = 225 },
   { id = 81, type = 0, name = "Util Bright Blue", r = 59, g = 57, b = 224 },
   { id = 108, type = 0, name = "Util Brown", r = 58, g = 42, b = 27 },
   { id = 109, type = 0, name = "Util Medium Brown", r = 120, g = 95, b = 51 },
   { id = 110, type = 0, name = "Util Light Brown", r = 181, g = 160, b = 121 },
   { id = 122, type = 0, name = "Util Off White", r = 223, g = 221, b = 208 },
   { id = 157, type = 0, name = "Epsilon Blue", r = 175, g = 214, b = 228 },
   { id = 21, type = 0, name = "Worn Black", r = 30, g = 35, b = 47 },
   { id = 22, type = 0, name = "Worn Graphite", r = 54, g = 58, b = 63 },
   { id = 23, type = 0, name = "Worn Silver Grey", r = 160, g = 161, b = 153 },
   { id = 24, type = 0, name = "Worn Silver", r = 211, g = 211, b = 211 },
   { id = 25, type = 0, name = "Worn Blue Silver", r = 183, g = 191, b = 202 },
   { id = 26, type = 0, name = "Worn Shadow Silver", r = 119, g = 135, b = 148 },
   { id = 46, type = 0, name = "Worn Red", r = 169, g = 71, b = 68 },
   { id = 47, type = 0, name = "Worn Golden Red", r = 177, g = 108, b = 81 },
   { id = 48, type = 0, name = "Worn Dark Red", r = 55, g = 28, b = 37 },
   { id = 58, type = 0, name = "Worn Dark Green", r = 45, g = 66, b = 63 },
   { id = 59, type = 0, name = "Worn Green", r = 69, g = 89, b = 75 },
   { id = 60, type = 0, name = "Worn Sea Wash", r = 101, g = 134, b = 127 },
   { id = 85, type = 0, name = "Worn Dark blue", r = 76, g = 95, b = 129 },
   { id = 86, type = 0, name = "Worn Blue", r = 88, g = 104, b = 142 },
   { id = 87, type = 0, name = "Worn Light blue", r = 116, g = 181, b = 216 },
   { id = 113, type = 0, name = "Worn Honey Beige", r = 176, g = 171, b = 148 },
   { id = 114, type = 0, name = "Worn Brown", r = 69, g = 56, b = 49 },
   { id = 115, type = 0, name = "Worn Dark Brown", r = 42, g = 40, b = 43 },
   { id = 116, type = 0, name = "Worn straw beige", r = 114, g = 108, b = 87 },
   { id = 121, type = 0, name = "Worn Off White", r = 234, g = 230, b = 222 },
   { id = 123, type = 0, name = "Worn Orange", r = 242, g = 173, b = 46 },
   { id = 124, type = 0, name = "Worn Light Orange", r = 249, g = 164, b = 88 },
   { id = 126, type = 0, name = "Worn Taxi Yellow", r = 241, g = 204, b = 64 },
   { id = 130, type = 0, name = "Worn Orange", r = 248, g = 182, b = 88 },
   { id = 132, type = 0, name = "Worn White", r = 255, g = 255, b = 251 },
   { id = 133, type = 0, name = "Worn Olive Army Green", r = 129, g = 132, b = 76 },
   { id = 0, type = 1, name = "Metallic Black", r = 13, g = 17, b = 22 },
   { id = 1, type = 1, name = "Metallic Graphite Black", r = 28, g = 29, b = 33 },
   { id = 2, type = 1, name = "Metallic Black Steal", r = 50, g = 56, b = 61 },
   { id = 3, type = 1, name = "Metallic Dark Silver", r = 69, g = 75, b = 79 },
   { id = 4, type = 1, name = "Metallic Silver", r = 153, g = 157, b = 160 },
   { id = 5, type = 1, name = "Metallic Blue Silver", r = 194, g = 196, b = 198 },
   { id = 6, type = 1, name = "Metallic Steel Gray", r = 151, g = 154, b = 151 },
   { id = 7, type = 1, name = "Metallic Shadow Silver", r = 99, g = 115, b = 128 },
   { id = 8, type = 1, name = "Metallic Stone Silver", r = 99, g = 98, b = 92 },
   { id = 9, type = 1, name = "Metallic Midnight Silver", r = 60, g = 63, b = 71 },
   { id = 10, type = 1, name = "Metallic Gun Metal", r = 68, g = 78, b = 84 },
   { id = 11, type = 1, name = "Metallic Anthracite Grey", r = 29, g = 33, b = 41 },
   { id = 27, type = 1, name = "Metallic Red", r = 192, g = 14, b = 26 },
   { id = 28, type = 1, name = "Metallic Torino Red", r = 218, g = 25, b = 24 },
   { id = 29, type = 1, name = "Metallic Formula Red", r = 182, g = 17, b = 27 },
   { id = 30, type = 1, name = "Metallic Blaze Red", r = 165, g = 30, b = 35 },
   { id = 31, type = 1, name = "Metallic Graceful Red", r = 123, g = 26, b = 34 },
   { id = 32, type = 1, name = "Metallic Garnet Red", r = 142, g = 27, b = 31 },
   { id = 33, type = 1, name = "Metallic Desert Red", r = 111, g = 24, b = 24 },
   { id = 34, type = 1, name = "Metallic Cabernet Red", r = 73, g = 17, b = 29 },
   { id = 35, type = 1, name = "Metallic Candy Red", r = 182, g = 15, b = 37 },
   { id = 36, type = 1, name = "Metallic Sunrise Orange", r = 212, g = 74, b = 23 },
   { id = 37, type = 1, name = "Metallic Classic Gold", r = 194, g = 148, b = 79 },
   { id = 38, type = 1, name = "Metallic Orange", r = 247, g = 134, b = 22 },
   { id = 49, type = 1, name = "Metallic Dark Green", r = 19, g = 36, b = 40 },
   { id = 50, type = 1, name = "Metallic Racing Green", r = 18, g = 46, b = 43 },
   { id = 51, type = 1, name = "Metallic Sea Green", r = 18, g = 56, b = 60 },
   { id = 52, type = 1, name = "Metallic Olive Green", r = 49, g = 66, b = 63 },
   { id = 53, type = 1, name = "Metallic Green", r = 21, g = 92, b = 45 },
   { id = 54, type = 1, name = "Metallic Gasoline Blue Green", r = 27, g = 103, b = 112 },
   { id = 61, type = 1, name = "Metallic Midnight Blue", r = 34, g = 46, b = 70 },
   { id = 62, type = 1, name = "Metallic Dark Blue", r = 35, g = 49, b = 85 },
   { id = 63, type = 1, name = "Metallic Saxony Blue", r = 48, g = 76, b = 126 },
   { id = 64, type = 1, name = "Metallic Blue", r = 71, g = 87, b = 143 },
   { id = 65, type = 1, name = "Metallic Mariner Blue", r = 99, g = 123, b = 167 },
   { id = 66, type = 1, name = "Metallic Harbor Blue", r = 57, g = 71, b = 98 },
   { id = 67, type = 1, name = "Metallic Diamond Blue", r = 214, g = 231, b = 241 },
   { id = 68, type = 1, name = "Metallic Surf Blue", r = 118, g = 175, b = 190 },
   { id = 69, type = 1, name = "Metallic Nautical Blue", r = 52, g = 94, b = 114 },
   { id = 70, type = 1, name = "Metallic Bright Blue", r = 11, g = 156, b = 241 },
   { id = 71, type = 1, name = "Metallic Purple Blue", r = 47, g = 45, b = 82 },
   { id = 72, type = 1, name = "Metallic Spinnaker Blue", r = 40, g = 44, b = 77 },
   { id = 73, type = 1, name = "Metallic Ultra Blue", r = 35, g = 84, b = 161 },
   { id = 74, type = 1, name = "Metallic Bright Blue", r = 110, g = 163, b = 198 },
   { id = 88, type = 1, name = "Metallic Taxi Yellow", r = 255, g = 207, b = 32 },
   { id = 89, type = 1, name = "Metallic Race Yellow", r = 251, g = 226, b = 18 },
   { id = 90, type = 1, name = "Metallic Bronze", r = 145, g = 101, b = 50 },
   { id = 91, type = 1, name = "Metallic Yellow Bird", r = 224, g = 225, b = 61 },
   { id = 92, type = 1, name = "Metallic Lime", r = 152, g = 210, b = 35 },
   { id = 93, type = 1, name = "Metallic Champagne", r = 155, g = 140, b = 120 },
   { id = 94, type = 1, name = "Metallic Pueblo Beige", r = 80, g = 50, b = 24 },
   { id = 95, type = 1, name = "Metallic Dark Ivory", r = 71, g = 63, b = 43 },
   { id = 96, type = 1, name = "Metallic Choco Brown", r = 34, g = 27, b = 25 },
   { id = 97, type = 1, name = "Metallic Golden Brown", r = 101, g = 63, b = 35 },
   { id = 98, type = 1, name = "Metallic Light Brown", r = 119, g = 92, b = 62 },
   { id = 99, type = 1, name = "Metallic Straw Beige", r = 172, g = 153, b = 117 },
   { id = 100, type = 1, name = "Metallic Moss Brown", r = 108, g = 107, b = 75 },
   { id = 101, type = 1, name = "Metallic Biston Brown", r = 64, g = 46, b = 43 },
   { id = 102, type = 1, name = "Metallic Beechwood", r = 164, g = 150, b = 95 },
   { id = 103, type = 1, name = "Metallic Dark Beechwood", r = 70, g = 35, b = 26 },
   { id = 104, type = 1, name = "Metallic Choco Orange", r = 117, g = 43, b = 25 },
   { id = 105, type = 1, name = "Metallic Beach Sand", r = 191, g = 174, b = 123 },
   { id = 106, type = 1, name = "Metallic Sun Bleeched Sand", r = 223, g = 213, b = 178 },
   { id = 107, type = 1, name = "Metallic Cream", r = 247, g = 237, b = 213 },
   { id = 111, type = 1, name = "Metallic White", r = 255, g = 255, b = 246 },
   { id = 112, type = 1, name = "Metallic Frost White", r = 234, g = 234, b = 234 },
   { id = 125, type = 1, name = "Metallic Securicor Green", r = 131, g = 197, b = 102 },
   { id = 137, type = 1, name = "Metallic Vermillion Pink", r = 223, g = 88, b = 145 },
   { id = 142, type = 1, name = "Metallic Black Purple", r = 12, g = 13, b = 24 },
   { id = 143, type = 1, name = "Metallic Black Red", r = 14, g = 13, b = 20 },
   { id = 145, type = 1, name = "Metallic Purple", r = 98, g = 18, b = 118 },
   { id = 150, type = 1, name = "Metallic Lava Red", r = 188, g = 25, b = 23 },
   { id = 12, type = 3, name = "Matte Black", r = 19, g = 24, b = 31 },
   { id = 13, type = 3, name = "Matte Gray", r = 38, g = 40, b = 42 },
   { id = 14, type = 3, name = "Matte Light Grey", r = 81, g = 85, b = 84 },
   { id = 39, type = 3, name = "Matte Red", r = 207, g = 31, b = 33 },
   { id = 40, type = 3, name = "Matte Dark Red", r = 115, g = 32, b = 33 },
   { id = 41, type = 3, name = "Matte Orange", r = 242, g = 125, b = 32 },
   { id = 42, type = 3, name = "Matte Yellow", r = 255, g = 201, b = 31 },
   { id = 55, type = 3, name = "Matte Lime Green", r = 102, g = 184, b = 31 },
   { id = 82, type = 3, name = "Matte Dark Blue", r = 31, g = 40, b = 82 },
   { id = 83, type = 3, name = "Matte Blue", r = 37, g = 58, b = 167 },
   { id = 84, type = 3, name = "Matte Midnight Blue", r = 28, g = 53, b = 81 },
   { id = 128, type = 3, name = "Matte Green", r = 78, g = 100, b = 67 },
   { id = 129, type = 3, name = "Matte Brown", r = 188, g = 172, b = 143 },
   { id = 131, type = 3, name = "Matte White", r = 252, g = 249, b = 241 },
   { id = 148, type = 3, name = "Matte Purple", r = 107, g = 31, b = 123 },
   { id = 149, type = 3, name = "Matte Dark Purple", r = 30, g = 29, b = 34 },
   { id = 151, type = 3, name = "Matte Forest Green", r = 45, g = 54, b = 42 },
   { id = 152, type = 3, name = "Matte Olive Drab", r = 105, g = 103, b = 72 },
   { id = 153, type = 3, name = "Matte Desert Brown", r = 122, g = 108, b = 85 },
   { id = 154, type = 3, name = "Matte Desert Tan", r = 195, g = 180, b = 146 },
   { id = 155, type = 3, name = "Matte Foilage Green", r = 90, g = 99, b = 82 },
   { id = 120, type = 5, name = "Chrome", r = 200, g = 200, b = 200 },
}

local materialNames = {}
for i, m in ipairs(Materials) do materialNames[i] = m.name end

local Chameleons = {}
local chameleonNames = {}
for i = 1, 32 do
   Chameleons[i] = { id = 160 + i }
   chameleonNames[i] = "Chameleon Paint #" .. i
end

local presetFiles = {"No Presets Found"}
local currentFilteredColors = {}

-- ═══════════════════════════════════════════════════════════════════════════════════
-- paint library / soft preview
-- note: embedded library data keeps paintlabs as a single-file install; preview state
-- restores the original vehicle paint and lighting when browsing ends.
-- ═══════════════════════════════════════════════════════════════════════════════════
local archiveLibrary = {
  {name="ta", hex="#270007", full_hex="#270007AA", r=39, g=0, b=7, pearl_name="", pearl_id=nil, archive_id="p0001", confidence="high"},
  {name="RIPTIDE BLUE", hex="#273755", full_hex="#273755AA", r=39, g=55, b=85, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0002", confidence="high"},
  {name="PHOSPHORESCENCE", hex="#E4FFA8", full_hex="#E4FFA8AA", r=228, g=255, b=168, pearl_name="Ice White", pearl_id=111, archive_id="p0003", confidence="high"},
  {name="Creamsicle Orange", hex="#F25020", full_hex="#F25020", r=242, g=80, b=32, pearl_name="", pearl_id=nil, archive_id="p0004", confidence="high"},
  {name="Menacing Red", hex="#340011", full_hex="#340011", r=52, g=0, b=17, pearl_name="", pearl_id=nil, archive_id="p0005", confidence="high"},
  {name="Periling Purple", hex="#8C8AFF", full_hex="#8C8AFF", r=140, g=138, b=255, pearl_name="", pearl_id=nil, archive_id="p0006", confidence="high"},
  {name="Venomous Red", hex="#0E000E", full_hex="#0E000E", r=14, g=0, b=14, pearl_name="", pearl_id=nil, archive_id="p0007", confidence="high"},
  {name="Nebula", hex="#7FFFFF", full_hex="#7FFFFF", r=127, g=255, b=255, pearl_name="", pearl_id=nil, archive_id="p0008", confidence="high"},
  {name="EVO Red", hex="#3C0015", full_hex="#3C0015AA", r=60, g=0, b=21, pearl_name="Torino Red", pearl_id=28, archive_id="p0009", confidence="high"},
  {name="COBBLER", hex="#643B36", full_hex="#643B36AA", r=100, g=59, b=54, pearl_name="", pearl_id=nil, archive_id="p0010", confidence="high"},
  {name="Cobbler", hex="#643B36", full_hex="#643B36AA", r=100, g=59, b=54, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0011", confidence="high"},
  {name="Cobbler v2", hex="#38211E", full_hex="#38211EAA", r=56, g=33, b=30, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0012", confidence="high"},
  {name="Cobbler v3", hex="#2A1816", full_hex="#2A1816AA", r=42, g=24, b=22, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0013", confidence="high"},
  {name="Cornflower Blue", hex="#05283E", full_hex="#05283EAA", r=5, g=40, b=62, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0014", confidence="high"},
  {name="TAFFY", hex="#4D3566", full_hex="#4D3566AA", r=77, g=53, b=102, pearl_name="Frost White", pearl_id=112, archive_id="p0015", confidence="high"},
  {name="SPINAL RED", hex="#1A0003", full_hex="#1A0003AA", r=26, g=0, b=3, pearl_name="Sienna Brown", pearl_id=nil, archive_id="p0016", confidence="high"},
  {name="DARK ORCHID", hex="#241A21", full_hex="#241A21AA", r=36, g=26, b=33, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0017", confidence="high"},
  {name="ELECTRIC CORAL", hex="#FF3C3C", full_hex="#FF3C3C", r=255, g=60, b=60, pearl_name="Formula Red", pearl_id=29, archive_id="p0018", confidence="high"},
  {name="SEASIDE", hex="#001E2E", full_hex="#001E2EAA", r=0, g=30, b=46, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0019", confidence="high"},
  {name="KATANA", hex="#A299FF", full_hex="#A299FFAA", r=162, g=153, b=255, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0020", confidence="high"},
  {name="ECSTASY", hex="#120113", full_hex="#120113AA", r=18, g=1, b=19, pearl_name="Hot Pink", pearl_id=135, archive_id="p0021", confidence="high"},
  {name="Red Venom", hex="#0D000D", full_hex="#0D000D", r=13, g=0, b=13, pearl_name="", pearl_id=nil, archive_id="p0022", confidence="high"},
  {name="Rosy Red", hex="#FF0303", full_hex="#FF0303", r=255, g=3, b=3, pearl_name="", pearl_id=nil, archive_id="p0023", confidence="high"},
  {name="Bleak Banana", hex="#ECFF8C", full_hex="#ECFF8C", r=236, g=255, b=140, pearl_name="", pearl_id=nil, archive_id="p0024", confidence="high"},
  {name="Pale Pink", hex="#FF8282", full_hex="#FF8282", r=255, g=130, b=130, pearl_name="", pearl_id=nil, archive_id="p0025", confidence="high"},
  {name="X X THREE", hex="#0A0025", full_hex="#0A0025AA", r=10, g=0, b=37, pearl_name="Yellow", pearl_id=88, archive_id="p0026", confidence="high"},
  {name="FOUNDER mut Gani", hex="#5B575F", full_hex="#5B575F", r=91, g=87, b=95, pearl_name="", pearl_id=nil, archive_id="p0027", confidence="high"},
  {name="Liked videos", hex="#5B57FF", full_hex="#5B57FF", r=91, g=87, b=255, pearl_name="", pearl_id=nil, archive_id="p0028", confidence="high"},
  {name="ACE YELLOW", hex="#090022", full_hex="#090022AA", r=9, g=0, b=34, pearl_name="Race Yellow", pearl_id=89, archive_id="p0029", confidence="high"},
  {name="KDES DATABASE", hex="#090022", full_hex="#090022", r=9, g=0, b=34, pearl_name="", pearl_id=nil, archive_id="p0030", confidence="high"},
  {name="IN' BLUE", hex="#039AFF", full_hex="#039AFF", r=3, g=154, b=255, pearl_name="", pearl_id=nil, archive_id="p0031", confidence="medium"},
  {name="QUICK", hex="#039AFF", full_hex="#039AFF", r=3, g=154, b=255, pearl_name="", pearl_id=nil, archive_id="p0032", confidence="high"},
  {name="7 FSC", hex="#7F8CFF", full_hex="#7F8CFF", r=127, g=140, b=255, pearl_name="", pearl_id=nil, archive_id="p0033", confidence="high"},
  {name="ChromatiQ Serpent Claw", hex="#03FF92", full_hex="#03FF92", r=3, g=255, b=146, pearl_name="", pearl_id=nil, archive_id="p0034", confidence="high"},
  {name="TATARACE.", hex="#520299", full_hex="#520299", r=82, g=2, b=153, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0035", confidence="high"},
  {name="Chromatiq Ikue", hex="#690299", full_hex="#690299", r=105, g=2, b=153, pearl_name="", pearl_id=nil, archive_id="p0036", confidence="high"},
  {name="Blue\" (REMAKE)", hex="#160299", full_hex="#160299", r=22, g=2, b=153, pearl_name="", pearl_id=nil, archive_id="p0037", confidence="high"},
  {name="Unnamed #7B3A00", hex="#7B3A00", full_hex="#7B3A00AA", r=123, g=58, b=0, pearl_name="", pearl_id=nil, archive_id="p0038", confidence="low"},
  {name="SS", hex="#0C0B28", full_hex="#0C0B28AA", r=12, g=11, b=40, pearl_name="", pearl_id=nil, archive_id="p0039", confidence="medium"},
  {name="Se", hex="#4E6D4E", full_hex="#4E6D4E", r=78, g=109, b=78, pearl_name="", pearl_id=nil, archive_id="p0040", confidence="high"},
  {name="Se", hex="#57735A", full_hex="#57735A", r=87, g=115, b=90, pearl_name="", pearl_id=nil, archive_id="p0041", confidence="high"},
  {name="Unnamed #25040A", hex="#25040A", full_hex="#25040AAA", r=37, g=4, b=10, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0042", confidence="medium"},
  {name="Zentorno Tame Teal Pearl (Ice White pearlescent)", hex="#3C5E5F", full_hex="#3C5E5FFF", r=60, g=94, b=95, pearl_name="Zentorno Tame Teal", pearl_id=nil, archive_id="p0043", confidence="high"},
  {name="WHITE,", hex="#00445B", full_hex="#00445BAA", r=0, g=68, b=91, pearl_name="", pearl_id=nil, archive_id="p0044", confidence="high"},
  {name="Messiah Blue", hex="#6BA9FF", full_hex="#6BA9FFAA", r=107, g=169, b=255, pearl_name="", pearl_id=nil, archive_id="p0045", confidence="high"},
  {name="CREATOR: Ikues Database", hex="#120020", full_hex="#120020AA", r=18, g=0, b=32, pearl_name="", pearl_id=nil, archive_id="p0046", confidence="high"},
  {name="USO EY", hex="#120020", full_hex="#1200208A", r=18, g=0, b=32, pearl_name="", pearl_id=nil, archive_id="p0047", confidence="medium"},
  {name="CREATOR: Ikues Database", hex="#434381", full_hex="#434381AA", r=67, g=67, b=129, pearl_name="Fluorescent Blue", pearl_id=140, archive_id="p0048", confidence="high"},
  {name="NY", hex="#434358", full_hex="#434358", r=67, g=67, b=88, pearl_name="", pearl_id=nil, archive_id="p0049", confidence="high"},
  {name="Founder: Ikue", hex="#100019", full_hex="#100019AA", r=16, g=0, b=25, pearl_name="", pearl_id=nil, archive_id="p0050", confidence="high"},
  {name="Founder: Ikue", hex="#A8FF65", full_hex="#A8FF65AA", r=168, g=255, b=101, pearl_name="Ice White", pearl_id=111, archive_id="p0051", confidence="high"},
  {name="SKYN3T", hex="#00BEFF", full_hex="#00BEFF", r=0, g=190, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0052", confidence="high"},
  {name="SUPER-PEACH", hex="#EF4936", full_hex="#EF4936", r=239, g=73, b=54, pearl_name="", pearl_id=nil, archive_id="p0053", confidence="high"},
  {name="Please Join, instead of Use the", hex="#A1D453", full_hex="#A1D453", r=161, g=212, b=83, pearl_name="", pearl_id=nil, archive_id="p0054", confidence="high"},
  {name="Ikues", hex="#090011", full_hex="#090011AA", r=9, g=0, b=17, pearl_name="Yellow", pearl_id=88, archive_id="p0055", confidence="high"},
  {name="GRINCH PALE GREEN", hex="#8FD980", full_hex="#8FD980", r=143, g=217, b=128, pearl_name="Race Yellow", pearl_id=89, archive_id="p0056", confidence="high"},
  {name="Mjstichrom by Kushology", hex="#0A000A", full_hex="#0A000AAA", r=10, g=0, b=10, pearl_name="Any", pearl_id=nil, archive_id="p0057", confidence="high"},
  {name="Dragon Fruit Pink", hex="#C52943", full_hex="#C52943", r=197, g=41, b=67, pearl_name="Race Yellow", pearl_id=89, archive_id="p0058", confidence="high"},
  {name="MIO 9", hex="#B76E75", full_hex="#B76E75FF", r=183, g=110, b=117, pearl_name="", pearl_id=nil, archive_id="p0059", confidence="medium"},
  {name="oo", hex="#1E0E0F", full_hex="#1E0E0FAA", r=30, g=14, b=15, pearl_name="", pearl_id=nil, archive_id="p0060", confidence="medium"},
  {name="Beitr Guide (", hex="#F7F396", full_hex="#F7F396", r=247, g=243, b=150, pearl_name="", pearl_id=nil, archive_id="p0061", confidence="high"},
  {name="Easter Green", hex="#8BEAAF", full_hex="#8BEAAF", r=139, g=234, b=175, pearl_name="", pearl_id=nil, archive_id="p0062", confidence="high"},
  {name="Easter Orange", hex="#FFA07A", full_hex="#FFA07A", r=255, g=160, b=122, pearl_name="", pearl_id=nil, archive_id="p0063", confidence="medium"},
  {name="Easter Pink", hex="#F482F6", full_hex="#F482F6", r=244, g=130, b=246, pearl_name="", pearl_id=nil, archive_id="p0064", confidence="high"},
  {name="Easter Purple", hex="#BE64FF", full_hex="#BE64FF", r=190, g=100, b=255, pearl_name="", pearl_id=nil, archive_id="p0065", confidence="high"},
  {name="Easter Blue", hex="#83DDD6", full_hex="#83DDD6", r=131, g=221, b=214, pearl_name="", pearl_id=nil, archive_id="p0066", confidence="high"},
  {name="Easter Yellow", hex="#F7F396", full_hex="#F7F396", r=247, g=243, b=150, pearl_name="", pearl_id=nil, archive_id="p0067", confidence="high"},
  {name="Bebes", hex="#FF7FEA", full_hex="#FF7FEA", r=255, g=127, b=234, pearl_name="", pearl_id=nil, archive_id="p0068", confidence="high"},
  {name="Ghosty", hex="#7FFFD0", full_hex="#7FFFD0", r=127, g=255, b=208, pearl_name="", pearl_id=nil, archive_id="p0069", confidence="medium"},
  {name="dl", hex="#3B001B", full_hex="#3B001BAA", r=59, g=0, b=27, pearl_name="Hot Pink", pearl_id=135, archive_id="p0070", confidence="high"},
  {name="oy", hex="#BE64BE", full_hex="#BE64BEAA", r=190, g=100, b=190, pearl_name="", pearl_id=nil, archive_id="p0071", confidence="medium"},
  {name="Quake Green", hex="#001714", full_hex="#001714FF", r=0, g=23, b=20, pearl_name="", pearl_id=nil, archive_id="p0072", confidence="high"},
  {name="Time for a", hex="#170D3B", full_hex="#170D3BAA", r=23, g=13, b=59, pearl_name="", pearl_id=nil, archive_id="p0073", confidence="high"},
  {name="F620 Appletree Green (Cream pearlescent)", hex="#3F552F", full_hex="#3F552FAA", r=63, g=85, b=47, pearl_name="Cast Iron Silver", pearl_id=4, archive_id="p0074", confidence="high"},
  {name="Khamelion Lotus Magenta (Ice White pearlescent)", hex="#332130", full_hex="#332130", r=51, g=33, b=48, pearl_name="Cream", pearl_id=107, archive_id="p0075", confidence="high"},
  {name="Massacro Diavolo Red (Cast Iron Silver pearlescent)", hex="#511515", full_hex="#511515AA", r=81, g=21, b=21, pearl_name="Cast Iron Silver", pearl_id=4, archive_id="p0076", confidence="high"},
  {name="Comet Retro Spearmint Blue (Ice White pearlescent)", hex="#4C8899", full_hex="#4C8899", r=76, g=136, b=153, pearl_name="Ice White", pearl_id=111, archive_id="p0077", confidence="high"},
  {name="Unnamed #A7B4C6", hex="#A7B4C6", full_hex="#A7B4C600", r=167, g=180, b=198, pearl_name="Blue", pearl_id=64, archive_id="p0078", confidence="medium"},
  {name="Luxury Champagne", hex="#E7C898", full_hex="#E7C89800", r=231, g=200, b=152, pearl_name="Pure Gold", pearl_id=158, archive_id="p0079", confidence="high"},
  {name="aS", hex="#6AA5B8", full_hex="#6AA5B800", r=106, g=165, b=184, pearl_name="", pearl_id=nil, archive_id="p0080", confidence="high"},
  {name="VIVID MAROON", hex="#1A0009", full_hex="#1A0009AA", r=26, g=0, b=9, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0081", confidence="high"},
  {name="Pe Pe", hex="#3030F3", full_hex="#3030F303", r=48, g=48, b=243, pearl_name="", pearl_id=nil, archive_id="p0082", confidence="medium"},
  {name="oe", hex="#8695A3", full_hex="#8695A300", r=134, g=149, b=163, pearl_name="", pearl_id=nil, archive_id="p0083", confidence="high"},
  {name="BABY BLUE", hex="#8AB9F1", full_hex="#8AB9F1AA", r=138, g=185, b=241, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0084", confidence="high"},
  {name="22 Sep 2016", hex="#FF1E00", full_hex="#FF1E00", r=255, g=30, b=0, pearl_name="", pearl_id=nil, archive_id="p0085", confidence="medium"},
  {name="Tekniq Rose Phoenix", hex="#100C1C", full_hex="#100C1C", r=16, g=12, b=28, pearl_name="", pearl_id=nil, archive_id="p0086", confidence="high"},
  {name="Rose Gold Pear!", hex="#EA645A", full_hex="#EA645A", r=234, g=100, b=90, pearl_name="", pearl_id=nil, archive_id="p0087", confidence="high"},
  {name="Lambo Green #2", hex="#50FF09", full_hex="#50FF09", r=80, g=255, b=9, pearl_name="", pearl_id=nil, archive_id="p0088", confidence="medium"},
  {name="Vibrant Turquoise", hex="#19FF64", full_hex="#19FF64", r=25, g=255, b=100, pearl_name="", pearl_id=nil, archive_id="p0089", confidence="high"},
  {name="Unfortunately, | did not record the base for this", hex="#101E07", full_hex="#101E07FF", r=16, g=30, b=7, pearl_name="", pearl_id=nil, archive_id="p0090", confidence="high"},
  {name="experiment, but it is likely either #", hex="#0D1603", full_hex="#0D1603FF", r=13, g=22, b=3, pearl_name="", pearl_id=nil, archive_id="p0091", confidence="high"},
  {name="a Pe", hex="#13172B", full_hex="#13172BAA", r=19, g=23, b=43, pearl_name="Light Blue", pearl_id=74, archive_id="p0092", confidence="high"},
  {name="rd", hex="#22202E", full_hex="#22202E", r=34, g=32, b=46, pearl_name="", pearl_id=nil, archive_id="p0093", confidence="medium"},
  {name="ee", hex="#0D001C", full_hex="#0D001CAA", r=13, g=0, b=28, pearl_name="", pearl_id=nil, archive_id="p0094", confidence="high"},
  {name="ee", hex="#5A1C0E", full_hex="#5A1C0EAA", r=90, g=28, b=14, pearl_name="", pearl_id=nil, archive_id="p0095", confidence="medium"},
  {name="Porsche Ice Green", hex="#5C746C", full_hex="#5C746CAA", r=92, g=116, b=108, pearl_name="Ice White", pearl_id=111, archive_id="p0096", confidence="high"},
  {name="Razer Green", hex="#47E10C", full_hex="#47E10C", r=71, g=225, b=12, pearl_name="Ice White", pearl_id=111, archive_id="p0097", confidence="high"},
  {name="Rose Quartz", hex="#5E3F46", full_hex="#5E3F46AA", r=94, g=63, b=70, pearl_name="Ice White", pearl_id=111, archive_id="p0098", confidence="high"},
  {name="next !!", hex="#7F400B", full_hex="#7F400BAA", r=127, g=64, b=11, pearl_name="Orange", pearl_id=38, archive_id="p0099", confidence="high"},
  {name="EVO Green", hex="#4DFF00", full_hex="#4DFF00", r=77, g=255, b=0, pearl_name="Yellow", pearl_id=88, archive_id="p0100", confidence="high"},
  {name="EVO Greene", hex="#40FF00", full_hex="#40FF00", r=64, g=255, b=0, pearl_name="", pearl_id=nil, archive_id="p0101", confidence="medium"},
  {name="Chromatix Cash", hex="#8EEB03", full_hex="#8EEB03", r=142, g=235, b=3, pearl_name="", pearl_id=nil, archive_id="p0102", confidence="high"},
  {name="Charmander", hex="#F5652E", full_hex="#F5652E", r=245, g=101, b=46, pearl_name="Creme", pearl_id=nil, archive_id="p0103", confidence="high"},
  {name="Wigglytuff", hex="#FF739F", full_hex="#FF739F", r=255, g=115, b=159, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0104", confidence="high"},
  {name="Light Sky Blue", hex="#7FDFFF", full_hex="#7FDFFF", r=127, g=223, b=255, pearl_name="", pearl_id=nil, archive_id="p0105", confidence="high"},
  {name="WASH-ARMY-GREEN", hex="#95B083", full_hex="#95B08300", r=149, g=176, b=131, pearl_name="Frost White", pearl_id=112, archive_id="p0106", confidence="high"},
  {name="PP-PASTEL-PURPLE", hex="#B19CD9", full_hex="#B19CD900", r=177, g=156, b=217, pearl_name="Ultra blue", pearl_id=70, archive_id="p0107", confidence="high"},
  {name="PP-PASTEL-PINK", hex="#FFD1DC", full_hex="#FFD1DC00", r=255, g=209, b=220, pearl_name="Bright Purple", pearl_id=145, archive_id="p0108", confidence="high"},
  {name="Raspberry-Ultra-Blue", hex="#4D162E", full_hex="#4D162EAA", r=77, g=22, b=46, pearl_name="", pearl_id=nil, archive_id="p0109", confidence="high"},
  {name="Frost Blue-Grey-Blue", hex="#122C3C", full_hex="#122C3C", r=18, g=44, b=60, pearl_name="", pearl_id=nil, archive_id="p0110", confidence="high"},
  {name="Antique Varnish Red", hex="#150000", full_hex="#150000AA", r=21, g=0, b=0, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0111", confidence="high"},
  {name="Perfect Purple", hex="#1B0026", full_hex="#1B0026AA", r=27, g=0, b=38, pearl_name="Ice White", pearl_id=111, archive_id="p0112", confidence="high"},
  {name="Presidential Blue", hex="#01131E", full_hex="#01131EAA", r=1, g=19, b=30, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0113", confidence="high"},
  {name="Silver Green", hex="#002011", full_hex="#002011AA", r=0, g=32, b=17, pearl_name="Ice White", pearl_id=111, archive_id="p0114", confidence="high"},
  {name="GTAS", hex="#3AA013", full_hex="#3AA013AA", r=58, g=160, b=19, pearl_name="Yellow", pearl_id=88, archive_id="p0115", confidence="high"},
  {name="GTAS", hex="#C4AF3B", full_hex="#C4AF3BAA", r=196, g=175, b=59, pearl_name="", pearl_id=nil, archive_id="p0116", confidence="medium"},
  {name="Cornflower Blue", hex="#6495ED", full_hex="#6495ED", r=100, g=149, b=237, pearl_name="", pearl_id=nil, archive_id="p0117", confidence="medium"},
  {name="Flamingo", hex="#FC74FD", full_hex="#FC74FD", r=252, g=116, b=253, pearl_name="", pearl_id=nil, archive_id="p0118", confidence="medium"},
  {name="Safety Yellow", hex="#C1FA11", full_hex="#C1FA1199", r=193, g=250, b=17, pearl_name="", pearl_id=nil, archive_id="p0119", confidence="medium"},
  {name="Ultimate Green", hex="#021501", full_hex="#021501AA", r=2, g=21, b=1, pearl_name="", pearl_id=nil, archive_id="p0120", confidence="medium"},
  {name="IGNITE", hex="#FFB787", full_hex="#FFB787AA", r=255, g=183, b=135, pearl_name="Ice White", pearl_id=111, archive_id="p0121", confidence="high"},
  {name="DARK VOLCANO ORANGE - #", hex="#300305", full_hex="#300305AA", r=48, g=3, b=5, pearl_name="", pearl_id=nil, archive_id="p0122", confidence="high"},
  {name="LIGHT VOLCANO ORANGE - #", hex="#551100", full_hex="#551100AA", r=85, g=17, b=0, pearl_name="", pearl_id=nil, archive_id="p0123", confidence="high"},
  {name="ADSIVIIESTATABASE", hex="#520299", full_hex="#520299", r=82, g=2, b=153, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0124", confidence="high"},
  {name="CREATOR: Ikues Database", hex="#520299", full_hex="#520299", r=82, g=2, b=153, pearl_name="", pearl_id=nil, archive_id="p0125", confidence="high"},
  {name="LUMINESCENCE", hex="#CAFFBA", full_hex="#CAFFBA00", r=202, g=255, b=186, pearl_name="", pearl_id=nil, archive_id="p0126", confidence="medium"},
  {name="MYSTICHROME", hex="#0A001A", full_hex="#0A001AAA", r=10, g=0, b=26, pearl_name="Bright Green", pearl_id=139, archive_id="p0127", confidence="high"},
  {name="GLACIUS", hex="#96ABFF", full_hex="#96ABFFAA", r=150, g=171, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0128", confidence="high"},
  {name="all 22", hex="#96ABFF", full_hex="#96ABFFAA", r=150, g=171, b=255, pearl_name="", pearl_id=nil, archive_id="p0129", confidence="medium"},
  {name="Brandeis Blue (Ice White)", hex="#0070FF", full_hex="#0070FF", r=0, g=112, b=255, pearl_name="", pearl_id=nil, archive_id="p0130", confidence="medium"},
  {name="Cream", hex="#5E5B46", full_hex="#5E5B46AA", r=94, g=91, b=70, pearl_name="Ice White", pearl_id=111, archive_id="p0131", confidence="high"},
  {name="Outrageous Orange (Orange)", hex="#FF6E4A", full_hex="#FF6E4A", r=255, g=110, b=74, pearl_name="", pearl_id=nil, archive_id="p0132", confidence="medium"},
  {name="Woodland Being", hex="#050700", full_hex="#050700AA", r=5, g=7, b=0, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0133", confidence="high"},
  {name="CER Uge", hex="#0D0304", full_hex="#0D0304AA", r=13, g=3, b=4, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0134", confidence="high"},
  {name="Give one of these a try. | forgot which one it is, but", hex="#246481", full_hex="#246481FF", r=36, g=100, b=129, pearl_name="", pearl_id=nil, archive_id="p0135", confidence="high"},
  {name="Give one of these a try. | forgot which one it is, but", hex="#43A5F0", full_hex="#43A5F055", r=67, g=165, b=240, pearl_name="", pearl_id=nil, archive_id="p0136", confidence="high"},
  {name="Brilliant Blue", hex="#05C1FF", full_hex="#05C1FF", r=5, g=193, b=255, pearl_name="", pearl_id=nil, archive_id="p0137", confidence="high"},
  {name="Emerald Lime Green", hex="#1DEB57", full_hex="#1DEB57", r=29, g=235, b=87, pearl_name="", pearl_id=nil, archive_id="p0138", confidence="high"},
  {name="Prince Purple", hex="#3503FF", full_hex="#3503FF", r=53, g=3, b=255, pearl_name="", pearl_id=nil, archive_id="p0139", confidence="high"},
  {name="1.FARBE", hex="#510015", full_hex="#510015AA", r=81, g=0, b=21, pearl_name="", pearl_id=nil, archive_id="p0140", confidence="high"},
  {name="10.FARBE", hex="#080013", full_hex="#080013AA", r=8, g=0, b=19, pearl_name="", pearl_id=nil, archive_id="p0141", confidence="medium"},
  {name="11.FARBE", hex="#5B57FF", full_hex="#5B57FF", r=91, g=87, b=255, pearl_name="", pearl_id=nil, archive_id="p0142", confidence="high"},
  {name="2.FARBE", hex="#879F00", full_hex="#879F00AA", r=135, g=159, b=0, pearl_name="", pearl_id=nil, archive_id="p0143", confidence="high"},
  {name="3.FARBE", hex="#D40015", full_hex="#D40015", r=212, g=0, b=21, pearl_name="", pearl_id=nil, archive_id="p0144", confidence="high"},
  {name="4.FARBE", hex="#3F008C", full_hex="#3F008CAA", r=63, g=0, b=140, pearl_name="", pearl_id=nil, archive_id="p0145", confidence="high"},
  {name="5.FARBE", hex="#004845", full_hex="#004845AA", r=0, g=72, b=69, pearl_name="", pearl_id=nil, archive_id="p0146", confidence="high"},
  {name="6.FARBE", hex="#290026", full_hex="#290026AA", r=41, g=0, b=38, pearl_name="", pearl_id=nil, archive_id="p0147", confidence="high"},
  {name="7.FARBE", hex="#1F0013", full_hex="#1F0013AA", r=31, g=0, b=19, pearl_name="", pearl_id=nil, archive_id="p0148", confidence="medium"},
  {name="8.FARBE", hex="#93001F", full_hex="#93001FAA", r=147, g=0, b=31, pearl_name="", pearl_id=nil, archive_id="p0149", confidence="medium"},
  {name="9.FARBE", hex="#0A0025", full_hex="#0A0025AA", r=10, g=0, b=37, pearl_name="", pearl_id=nil, archive_id="p0150", confidence="high"},
  {name="9.FARBE", hex="#131826", full_hex="#131826AA", r=19, g=24, b=38, pearl_name="", pearl_id=nil, archive_id="p0151", confidence="high"},
  {name="1 FARBE", hex="#090022", full_hex="#090022AA", r=9, g=0, b=34, pearl_name="", pearl_id=nil, archive_id="p0152", confidence="high"},
  {name="2 FARBE", hex="#160040", full_hex="#160040AA", r=22, g=0, b=64, pearl_name="", pearl_id=nil, archive_id="p0153", confidence="high"},
  {name="3 FARBE", hex="#2F0020", full_hex="#2F0020AA", r=47, g=0, b=32, pearl_name="", pearl_id=nil, archive_id="p0154", confidence="high"},
  {name="4 FARBE", hex="#0C002D", full_hex="#0C002DAA", r=12, g=0, b=45, pearl_name="", pearl_id=nil, archive_id="p0155", confidence="high"},
  {name="5 FARBE", hex="#100C1C", full_hex="#100C1CAA", r=16, g=12, b=28, pearl_name="", pearl_id=nil, archive_id="p0156", confidence="high"},
  {name="PAINTLABS", hex="#140022", full_hex="#140022AA", r=20, g=0, b=34, pearl_name="", pearl_id=nil, archive_id="p0157", confidence="high"},
  {name="PAINTLABS", hex="#180321", full_hex="#180321AA", r=24, g=3, b=33, pearl_name="", pearl_id=nil, archive_id="p0158", confidence="high"},
  {name="ZENTORNO", hex="#13002F", full_hex="#13002F", r=19, g=0, b=47, pearl_name="", pearl_id=nil, archive_id="p0159", confidence="high"},
  {name="ZENTORNO", hex="#330018", full_hex="#330018AA", r=51, g=0, b=24, pearl_name="", pearl_id=nil, archive_id="p0160", confidence="high"},
  {name="PERL: Eis wei&", hex="#120020", full_hex="#120020AA", r=18, g=0, b=32, pearl_name="", pearl_id=nil, archive_id="p0161", confidence="high"},
  {name="orange", hex="#9D002C", full_hex="#9D002CAA", r=157, g=0, b=44, pearl_name="", pearl_id=nil, archive_id="p0162", confidence="high"},
  {name="by Fletcher Williamson", hex="#7FF0FE", full_hex="#7FF0FE", r=127, g=240, b=254, pearl_name="Ice White", pearl_id=111, archive_id="p0163", confidence="high"},
  {name="JET BLUE", hex="#000C57", full_hex="#000C57AA", r=0, g=12, b=87, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0164", confidence="high"},
  {name="EVO GREEN", hex="#6B7304", full_hex="#6B7304AA", r=107, g=115, b=4, pearl_name="Pure Gold", pearl_id=158, archive_id="p0165", confidence="high"},
  {name="Blaqqurent (24.3.33) - PERL - Ultra Blue", hex="#180321", full_hex="#180321AA", r=24, g=3, b=33, pearl_name="", pearl_id=nil, archive_id="p0166", confidence="high"},
  {name="CREATOR: IKUES DATABASE", hex="#180321", full_hex="#180321", r=24, g=3, b=33, pearl_name="", pearl_id=nil, archive_id="p0167", confidence="high"},
  {name="Japanese Bubblegum (51,30,103) - PERL - Ice white", hex="#331E67", full_hex="#331E67AA", r=51, g=30, b=103, pearl_name="", pearl_id=nil, archive_id="p0168", confidence="high"},
  {name="Red Planet (51.0.24) - PERL - Metallic. Race Yellow", hex="#330018", full_hex="#330018AA", r=51, g=0, b=24, pearl_name="", pearl_id=nil, archive_id="p0169", confidence="high"},
  {name="CHERRY", hex="#30002C", full_hex="#30002CAA", r=48, g=0, b=44, pearl_name="", pearl_id=nil, archive_id="p0170", confidence="high"},
  {name="CREATOR: IKUES DATABASE", hex="#13002F", full_hex="#13002F", r=19, g=0, b=47, pearl_name="", pearl_id=nil, archive_id="p0171", confidence="high"},
  {name="METALLIC. ORANGE", hex="#0D0027", full_hex="#0D0027", r=13, g=0, b=39, pearl_name="", pearl_id=nil, archive_id="p0172", confidence="high"},
  {name="Splat", hex="#FF7142", full_hex="#FF7142", r=255, g=113, b=66, pearl_name="", pearl_id=nil, archive_id="p0173", confidence="high"},
  {name="Magtic!", hex="#B4FF63", full_hex="#B4FF63", r=180, g=255, b=99, pearl_name="", pearl_id=nil, archive_id="p0174", confidence="high"},
  {name="Pixie!", hex="#990099", full_hex="#990099", r=153, g=0, b=153, pearl_name="", pearl_id=nil, archive_id="p0175", confidence="high"},
  {name="Sunlight", hex="#FF622E", full_hex="#FF622E", r=255, g=98, b=46, pearl_name="", pearl_id=nil, archive_id="p0176", confidence="high"},
  {name="Meteor", hex="#FF2121", full_hex="#FF2121", r=255, g=33, b=33, pearl_name="", pearl_id=nil, archive_id="p0177", confidence="high"},
  {name="2 pees", hex="#0496CF", full_hex="#0496CF", r=4, g=150, b=207, pearl_name="", pearl_id=nil, archive_id="p0178", confidence="high"},
  {name="KryptonicHD", hex="#3B9957", full_hex="#3B9957", r=59, g=153, b=87, pearl_name="", pearl_id=nil, archive_id="p0179", confidence="high"},
  {name="Crystal Blue", hex="#7FACFF", full_hex="#7FACFF", r=127, g=172, b=255, pearl_name="", pearl_id=nil, archive_id="p0180", confidence="high"},
  {name="CHD,", hex="#4FF7FB", full_hex="#4FF7FB00", r=79, g=247, b=251, pearl_name="", pearl_id=nil, archive_id="p0181", confidence="medium"},
  {name="Creamsicie Orange", hex="#125020", full_hex="#125020", r=18, g=80, b=32, pearl_name="Yellow", pearl_id=88, archive_id="p0182", confidence="high"},
  {name="Ne", hex="#71A6D2", full_hex="#71A6D2", r=113, g=166, b=210, pearl_name="", pearl_id=nil, archive_id="p0183", confidence="high"},
  {name="Diamond Purple", hex="#CDCCFF", full_hex="#CDCCFF00", r=205, g=204, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0184", confidence="high"},
  {name="BLACK GOLD.", hex="#000000", full_hex="#000000AA", r=0, g=0, b=0, pearl_name="DEW YELLOW", pearl_id=88, archive_id="p0185", confidence="high"},
  {name="Copperised", hex="#491103", full_hex="#491103AA", r=73, g=17, b=3, pearl_name="Orange", pearl_id=38, archive_id="p0186", confidence="high"},
  {name="NEVADA SAND", hex="#FFA875", full_hex="#FFA875", r=255, g=168, b=117, pearl_name="", pearl_id=nil, archive_id="p0187", confidence="high"},
  {name="Chromatix Amethyst", hex="#520299", full_hex="#520299", r=82, g=2, b=153, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0188", confidence="high"},
  {name="Chilled Moon Mist", hex="#7FC1FF", full_hex="#7FC1FF", r=127, g=193, b=255, pearl_name="", pearl_id=nil, archive_id="p0189", confidence="high"},
  {name="IMPERIAL", hex="#111A22", full_hex="#111A22AA", r=17, g=26, b=34, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0190", confidence="high"},
  {name="BALLIN' BLUE", hex="#00020F", full_hex="#00020FAA", r=0, g=2, b=15, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0191", confidence="high"},
  {name="XOTIC BLUE", hex="#00002E", full_hex="#00002EAA", r=0, g=0, b=46, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0192", confidence="high"},
  {name="SHOCKA RED", hex="#1D020C", full_hex="#1D020CAA", r=29, g=2, b=12, pearl_name="Torino Red", pearl_id=28, archive_id="p0193", confidence="high"},
  {name="ADMIRAL BLUE", hex="#343E54", full_hex="#343E54AA", r=52, g=62, b=84, pearl_name="Yellow", pearl_id=88, archive_id="p0194", confidence="high"},
  {name="AERO V2", hex="#030D17", full_hex="#030D17AA", r=3, g=13, b=23, pearl_name="Green", pearl_id=53, archive_id="p0195", confidence="high"},
  {name="yy", hex="#FFFAF0", full_hex="#FFFAF0AA", r=255, g=250, b=240, pearl_name="", pearl_id=nil, archive_id="p0196", confidence="medium"},
  {name="1AM", hex="#FF0000", full_hex="#FF0000", r=255, g=0, b=0, pearl_name="", pearl_id=nil, archive_id="p0197", confidence="medium"},
  {name="Pinky Pink", hex="#0000EE", full_hex="#0000EE", r=0, g=0, b=238, pearl_name="", pearl_id=nil, archive_id="p0198", confidence="high"},
  {name="Sunshine Orange", hex="#FF0753", full_hex="#FF0753", r=255, g=7, b=83, pearl_name="", pearl_id=nil, archive_id="p0199", confidence="high"},
  {name="Sunshine Orange", hex="#FF4203", full_hex="#FF4203", r=255, g=66, b=3, pearl_name="", pearl_id=nil, archive_id="p0200", confidence="high"},
  {name="Shiny Salmon", hex="#FF4A3D", full_hex="#FF4A3D", r=255, g=74, b=61, pearl_name="", pearl_id=nil, archive_id="p0201", confidence="high"},
  {name="Purple Haze", hex="#9D99BC", full_hex="#9D99BC", r=157, g=153, b=188, pearl_name="", pearl_id=nil, archive_id="p0202", confidence="high"},
  {name="KAOLIN RED", hex="#12000A", full_hex="#12000AAA", r=18, g=0, b=10, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0203", confidence="high"},
  {name="SUBZERO", hex="#222449", full_hex="#222449AA", r=34, g=36, b=73, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0204", confidence="high"},
  {name="Brdlée", hex="#FFAC80", full_hex="#FFAC80AA", r=255, g=172, b=128, pearl_name="Cream", pearl_id=107, archive_id="p0205", confidence="high"},
  {name="LAUREL GREEN", hex="#5D8A82", full_hex="#5D8A82AA", r=93, g=138, b=130, pearl_name="Cream", pearl_id=107, archive_id="p0206", confidence="high"},
  {name="SATIN GREEN CHROME", hex="#00240B", full_hex="#00240BAA", r=0, g=36, b=11, pearl_name="Lime Green", pearl_id=92, archive_id="p0207", confidence="high"},
  {name="XCALIBUR", hex="#240B00", full_hex="#240B00AA", r=36, g=11, b=0, pearl_name="Orange", pearl_id=38, archive_id="p0208", confidence="high"},
  {name="RL-SLAM", hex="#C77966", full_hex="#C77966EE", r=199, g=121, b=102, pearl_name="Yellow", pearl_id=88, archive_id="p0209", confidence="high"},
  {name="al S", hex="#051D1C", full_hex="#051D1CAA", r=5, g=29, b=28, pearl_name="", pearl_id=nil, archive_id="p0210", confidence="medium"},
  {name="next !!", hex="#051D1C", full_hex="#051D1CAA", r=5, g=29, b=28, pearl_name="", pearl_id=nil, archive_id="p0211", confidence="medium"},
  {name="next !!", hex="#5A4B3C", full_hex="#5A4B3CAA", r=90, g=75, b=60, pearl_name="and Matte Black", pearl_id=12, archive_id="p0212", confidence="high"},
  {name="next !!", hex="#202020", full_hex="#202020AA", r=32, g=32, b=32, pearl_name="", pearl_id=nil, archive_id="p0213", confidence="medium"},
  {name="next !!", hex="#260300", full_hex="#260300AA", r=38, g=3, b=0, pearl_name="", pearl_id=nil, archive_id="p0214", confidence="medium"},
  {name="Alien Green (", hex="#00643A", full_hex="#00643AAA", r=0, g=100, b=58, pearl_name="Race Yellow", pearl_id=89, archive_id="p0215", confidence="high"},
  {name="Dark Velvet Red, Alien Green, Electric Indigo", hex="#170302", full_hex="#170302AA", r=23, g=3, b=2, pearl_name="Torino Red", pearl_id=28, archive_id="p0216", confidence="high"},
  {name="Neon Orange", hex="#EB2B05", full_hex="#EB2B05", r=235, g=43, b=5, pearl_name="Race Yellow Pear", pearl_id=89, archive_id="p0217", confidence="high"},
  {name="Shock Pink", hex="#FF0554", full_hex="#FF0554", r=255, g=5, b=84, pearl_name="Bluish", pearl_id=5, archive_id="p0218", confidence="high"},
  {name="Ss", hex="#0A1629", full_hex="#0A1629AA", r=10, g=22, b=41, pearl_name="", pearl_id=nil, archive_id="p0219", confidence="medium"},
  {name="McDonalds Yellow", hex="#FFC300", full_hex="#FFC300", r=255, g=195, b=0, pearl_name="", pearl_id=nil, archive_id="p0220", confidence="medium"},
  {name="Reaper Blue", hex="#001F4D", full_hex="#001F4DAA", r=0, g=31, b=77, pearl_name="", pearl_id=nil, archive_id="p0221", confidence="medium"},
  {name="Reaper Green", hex="#2B5540", full_hex="#2B5540AA", r=43, g=85, b=64, pearl_name="", pearl_id=nil, archive_id="p0222", confidence="medium"},
  {name="Reaper Light Blue", hex="#364363", full_hex="#364363AA", r=54, g=67, b=99, pearl_name="", pearl_id=nil, archive_id="p0223", confidence="medium"},
  {name="Reaper Orange", hex="#892E10", full_hex="#892E10AA", r=137, g=46, b=16, pearl_name="", pearl_id=nil, archive_id="p0224", confidence="medium"},
  {name="Reaper Red", hex="#320008", full_hex="#320008AA", r=50, g=0, b=8, pearl_name="", pearl_id=nil, archive_id="p0225", confidence="medium"},
  {name="Erotic Red and Silver Purple", hex="#30000D", full_hex="#30000DAA", r=48, g=0, b=13, pearl_name="", pearl_id=nil, archive_id="p0226", confidence="medium"},
  {name="Silver Purple", hex="#15192B", full_hex="#15192BAA", r=21, g=25, b=43, pearl_name="", pearl_id=nil, archive_id="p0227", confidence="medium"},
  {name="Neon Red", hex="#FF0000", full_hex="#FF0000", r=255, g=0, b=0, pearl_name="Ice White", pearl_id=111, archive_id="p0228", confidence="high"},
  {name="Purple Magic", hex="#1E1C4A", full_hex="#1E1C4AAA", r=30, g=28, b=74, pearl_name="Ice White", pearl_id=111, archive_id="p0229", confidence="high"},
  {name="next !!", hex="#F5654F", full_hex="#F5654F", r=245, g=101, b=79, pearl_name="Ice White", pearl_id=111, archive_id="p0230", confidence="high"},
  {name="next !!", hex="#8D2501", full_hex="#8D2501AA", r=141, g=37, b=1, pearl_name="", pearl_id=nil, archive_id="p0231", confidence="high"},
  {name="next !!", hex="#FF9BBB", full_hex="#FF9BBB00", r=255, g=155, b=187, pearl_name="Ice White", pearl_id=111, archive_id="p0232", confidence="high"},
  {name="IMRZINDIGO", hex="#310062", full_hex="#310062AA", r=49, g=0, b=98, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0233", confidence="high"},
  {name="Showing off an amzing", hex="#FF554C", full_hex="#FF554C", r=255, g=85, b=76, pearl_name="", pearl_id=nil, archive_id="p0234", confidence="high"},
  {name="Saphire Pink", hex="#DC143C", full_hex="#DC143C", r=220, g=20, b=60, pearl_name="", pearl_id=nil, archive_id="p0235", confidence="high"},
  {name="FuSiON GREEN - #", hex="#CAFF7F", full_hex="#CAFF7F", r=202, g=255, b=127, pearl_name="", pearl_id=nil, archive_id="p0236", confidence="high"},
  {name="LS", hex="#260D02", full_hex="#260D02AA", r=38, g=13, b=2, pearl_name="", pearl_id=nil, archive_id="p0237", confidence="medium"},
  {name="IMROBERTZ1", hex="#0D0D26", full_hex="#0D0D26", r=13, g=13, b=38, pearl_name="", pearl_id=nil, archive_id="p0238", confidence="high"},
  {name="WATERMELON FUSION", hex="#39471E", full_hex="#39471E", r=57, g=71, b=30, pearl_name="", pearl_id=nil, archive_id="p0239", confidence="high"},
  {name="PSN ID : | neighbour222", hex="#8470FF", full_hex="#8470FF", r=132, g=112, b=255, pearl_name="", pearl_id=nil, archive_id="p0240", confidence="high"},
  {name="Thanks for watching :)", hex="#6666FF", full_hex="#6666FF", r=102, g=102, b=255, pearl_name="", pearl_id=nil, archive_id="p0241", confidence="high"},
  {name="Toxic Green - View all tgutan's Rockstar Editor videos", hex="#9CFF05", full_hex="#9CFF05", r=156, g=255, b=5, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0242", confidence="high"},
  {name="Frosty Cyan", hex="#97E7DE", full_hex="#97E7DE00", r=151, g=231, b=222, pearl_name="Ice White", pearl_id=111, archive_id="p0243", confidence="high"},
  {name="Mucus Green", hex="#2D6241", full_hex="#2D6241AA", r=45, g=98, b=65, pearl_name="Ice White", pearl_id=111, archive_id="p0244", confidence="high"},
  {name="next !!", hex="#BCB2FF", full_hex="#BCB2FF00", r=188, g=178, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0245", confidence="high"},
  {name="04 AM", hex="#030308", full_hex="#030308AA", r=3, g=3, b=8, pearl_name="", pearl_id=nil, archive_id="p0246", confidence="medium"},
  {name="Cherry Popper Red", hex="#DE1B08", full_hex="#DE1B08", r=222, g=27, b=8, pearl_name="", pearl_id=nil, archive_id="p0247", confidence="medium"},
  {name="Green Mint", hex="#82CC87", full_hex="#82CC8700", r=130, g=204, b=135, pearl_name="", pearl_id=nil, archive_id="p0248", confidence="medium"},
  {name="Yellow Mint", hex="#D2EF98", full_hex="#D2EF9800", r=210, g=239, b=152, pearl_name="", pearl_id=nil, archive_id="p0249", confidence="medium"},
  {name="Emerald", hex="#50C878", full_hex="#50C878", r=80, g=200, b=120, pearl_name="", pearl_id=nil, archive_id="p0250", confidence="medium"},
  {name="Hell Green", hex="#183E0F", full_hex="#183E0FAA", r=24, g=62, b=15, pearl_name="", pearl_id=nil, archive_id="p0251", confidence="medium"},
  {name="Utility Green OF", hex="#1F15AA", full_hex="#1F15AA", r=31, g=21, b=170, pearl_name="", pearl_id=nil, archive_id="p0252", confidence="medium"},
  {name="next !!", hex="#57ADB7", full_hex="#57ADB700", r=87, g=173, b=183, pearl_name="Lime Green", pearl_id=92, archive_id="p0253", confidence="high"},
  {name="Nassau Blue", hex="#07274B", full_hex="#07274BFF", r=7, g=39, b=75, pearl_name="", pearl_id=nil, archive_id="p0254", confidence="medium"},
  {name="Headlights Yellow", hex="#C4AF3B", full_hex="#C4AF3BAA", r=196, g=175, b=59, pearl_name="", pearl_id=nil, archive_id="p0255", confidence="medium"},
  {name="Brown / Chocolate", hex="#261C17", full_hex="#261C17AA", r=38, g=28, b=23, pearl_name="Cream", pearl_id=107, archive_id="p0256", confidence="high"},
  {name="Candy Plum", hex="#141228", full_hex="#141228AA", r=20, g=18, b=40, pearl_name="Candy Red", pearl_id=35, archive_id="p0257", confidence="high"},
  {name="Golden", hex="#372810", full_hex="#372810AA", r=55, g=40, b=16, pearl_name="", pearl_id=nil, archive_id="p0258", confidence="medium"},
  {name="Space Raspberry", hex="#37002B", full_hex="#37002BAA", r=55, g=0, b=43, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0259", confidence="high"},
  {name="Love Potion", hex="#12091A", full_hex="#12091AAA", r=18, g=9, b=26, pearl_name="Cream", pearl_id=107, archive_id="p0260", confidence="high"},
  {name="Slate Orange", hex="#E1884C", full_hex="#E1884CFF", r=225, g=136, b=76, pearl_name="Yellow", pearl_id=88, archive_id="p0261", confidence="high"},
  {name="Tropical Sunset", hex="#120920", full_hex="#120920AA", r=18, g=9, b=32, pearl_name="Orange", pearl_id=38, archive_id="p0262", confidence="high"},
  {name="21 hours ago", hex="#2B3742", full_hex="#2B3742", r=43, g=55, b=66, pearl_name="Diamond blue", pearl_id=67, archive_id="p0263", confidence="high"},
  {name="Made by Joonas", hex="#2B3742", full_hex="#2B3742", r=43, g=55, b=66, pearl_name="Diamond blue", pearl_id=67, archive_id="p0264", confidence="high"},
  {name="Blue Chrome", hex="#000024", full_hex="#000024", r=0, g=0, b=36, pearl_name="", pearl_id=nil, archive_id="p0265", confidence="high"},
  {name="Freeze", hex="#8CFFFF", full_hex="#8CFFFF", r=140, g=255, b=255, pearl_name="", pearl_id=nil, archive_id="p0266", confidence="high"},
  {name="Matte'Black", hex="#8CFFFF", full_hex="#8CFFFF", r=140, g=255, b=255, pearl_name="", pearl_id=nil, archive_id="p0267", confidence="high"},
  {name="ELECTRIC PLUM", hex="#FF824C", full_hex="#FF824C", r=255, g=130, b=76, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0268", confidence="high"},
  {name="Instrumental by Nimbus Beats", hex="#FF4105", full_hex="#FF4105", r=255, g=65, b=5, pearl_name="", pearl_id=nil, archive_id="p0269", confidence="high"},
  {name="bas", hex="#FF9966", full_hex="#FF9966", r=255, g=153, b=102, pearl_name="", pearl_id=nil, archive_id="p0270", confidence="high"},
  {name="Bloody Peach (created by Notcher)", hex="#F84A38", full_hex="#F84A38", r=248, g=74, b=56, pearl_name="", pearl_id=nil, archive_id="p0271", confidence="high"},
  {name="Sa", hex="#486666", full_hex="#486666", r=72, g=102, b=102, pearl_name="", pearl_id=nil, archive_id="p0272", confidence="high"},
  {name="os", hex="#545246", full_hex="#545246AA", r=84, g=82, b=70, pearl_name="vor taxi alles", pearl_id=nil, archive_id="p0273", confidence="high"},
  {name="at 7", hex="#3F353E", full_hex="#3F353EAA", r=63, g=53, b=62, pearl_name="", pearl_id=nil, archive_id="p0274", confidence="high"},
  {name="oo", hex="#6B663C", full_hex="#6B663CAA", r=107, g=102, b=60, pearl_name="", pearl_id=nil, archive_id="p0275", confidence="high"},
  {name="rE", hex="#2F0007", full_hex="#2F0007AA", r=47, g=0, b=7, pearl_name="Worn Golden Red", pearl_id=47, archive_id="p0276", confidence="high"},
  {name="7 Me.", hex="#12070E", full_hex="#12070EFF", r=18, g=7, b=14, pearl_name="salmon pine", pearl_id=nil, archive_id="p0277", confidence="high"},
  {name="ees", hex="#0A1406", full_hex="#0A1406", r=10, g=20, b=6, pearl_name="", pearl_id=nil, archive_id="p0278", confidence="high"},
  {name="Nude pink", hex="#994F4C", full_hex="#994F4C", r=153, g=79, b=76, pearl_name="", pearl_id=nil, archive_id="p0279", confidence="high"},
  {name="WEON CARROTTM", hex="#FFA143", full_hex="#FFA143", r=255, g=161, b=67, pearl_name="", pearl_id=nil, archive_id="p0280", confidence="medium"},
  {name="be", hex="#7458C1", full_hex="#7458C1", r=116, g=88, b=193, pearl_name="", pearl_id=nil, archive_id="p0281", confidence="high"},
  {name="PC GAMEPLAY!", hex="#EB9C41", full_hex="#EB9C41", r=235, g=156, b=65, pearl_name="", pearl_id=nil, archive_id="p0282", confidence="high"},
  {name="Al", hex="#BBEB2A", full_hex="#BBEB2A", r=187, g=235, b=42, pearl_name="", pearl_id=nil, archive_id="p0283", confidence="high"},
  {name="PO-PASTEL-ORANGE", hex="#FFCC99", full_hex="#FFCC9900", r=255, g=204, b=153, pearl_name="Frost White", pearl_id=112, archive_id="p0284", confidence="high"},
  {name="PY-PASTEL-YELLOW", hex="#FDFD98", full_hex="#FDFD9800", r=253, g=253, b=152, pearl_name="Frost White", pearl_id=112, archive_id="p0285", confidence="high"},
  {name="FROST-BLUE-GREY-FADE", hex="#8697A2", full_hex="#8697A200", r=134, g=151, b=162, pearl_name="Frost White", pearl_id=112, archive_id="p0286", confidence="high"},
  {name="0 AM", hex="#51203F", full_hex="#51203F", r=81, g=32, b=63, pearl_name="", pearl_id=nil, archive_id="p0287", confidence="high"},
  {name="Ome.", hex="#512A3F", full_hex="#512A3FAB", r=81, g=42, b=63, pearl_name="", pearl_id=nil, archive_id="p0288", confidence="high"},
  {name="LIME GREEN | #UNIQUEGLITCHING", hex="#7FFF90", full_hex="#7FFF90", r=127, g=255, b=144, pearl_name="", pearl_id=nil, archive_id="p0289", confidence="high"},
  {name="Banana Splig=", hex="#E3BE46", full_hex="#E3BE46", r=227, g=190, b=70, pearl_name="", pearl_id=nil, archive_id="p0290", confidence="high"},
  {name="FADED GLORY", hex="#5B7169", full_hex="#5B7169AA", r=91, g=113, b=105, pearl_name="Ice White", pearl_id=111, archive_id="p0291", confidence="high"},
  {name="TITAN", hex="#3D201C", full_hex="#3D201CAA", r=61, g=32, b=28, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0292", confidence="high"},
  {name="ARCANE", hex="#273B44", full_hex="#273B44AA", r=39, g=59, b=68, pearl_name="Bluish Silver", pearl_id=5, archive_id="p0293", confidence="high"},
  {name="KNIGHTS BLUE", hex="#080D1E", full_hex="#080D1EAA", r=8, g=13, b=30, pearl_name="Surf Blue", pearl_id=68, archive_id="p0294", confidence="high"},
  {name="SAKURA", hex="#53363B", full_hex="#53363BAA", r=83, g=54, b=59, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0295", confidence="high"},
  {name="CERBERUS PEARL", hex="#200314", full_hex="#200314AA", r=32, g=3, b=20, pearl_name="Yellow", pearl_id=88, archive_id="p0296", confidence="high"},
  {name="Raven", hex="#0D0024", full_hex="#0D0024AA", r=13, g=0, b=36, pearl_name="Yellow", pearl_id=88, archive_id="p0297", confidence="high"},
  {name="1) Atlantis Blue", hex="#002841", full_hex="#002841AA", r=0, g=40, b=65, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0298", confidence="high"},
  {name="GOD", hex="#96ABFF", full_hex="#96ABFFAA", r=150, g=171, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0299", confidence="high"},
  {name="CONTENT!", hex="#4C8199", full_hex="#4C8199", r=76, g=129, b=153, pearl_name="Bluish Silver", pearl_id=5, archive_id="p0300", confidence="high"},
  {name="Joker Green", hex="#029939", full_hex="#029939", r=2, g=153, b=57, pearl_name="", pearl_id=nil, archive_id="p0301", confidence="high"},
  {name="BLURINO &", hex="#00002D", full_hex="#00002DEE", r=0, g=0, b=45, pearl_name="Torino Red", pearl_id=28, archive_id="p0302", confidence="high"},
  {name="GARGOYLE", hex="#150128", full_hex="#150128AA", r=21, g=1, b=40, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0303", confidence="high"},
  {name="NEBULOUS", hex="#002D47", full_hex="#002D47AA", r=0, g=45, b=71, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0304", confidence="high"},
  {name="SPITFIRE", hex="#FF8282", full_hex="#FF8282AA", r=255, g=130, b=130, pearl_name="Ice White", pearl_id=111, archive_id="p0305", confidence="high"},
  {name="MAJESTIC", hex="#473001", full_hex="#473001AA", r=71, g=48, b=1, pearl_name="Pure Gold", pearl_id=158, archive_id="p0306", confidence="high"},
  {name="XANADU", hex="#738678", full_hex="#738678FF", r=115, g=134, b=120, pearl_name="Lime Green", pearl_id=92, archive_id="p0307", confidence="high"},
  {name="PURPLE-BANANAS", hex="#590C48", full_hex="#590C48AA", r=89, g=12, b=72, pearl_name="Race Yellow", pearl_id=89, archive_id="p0308", confidence="high"},
  {name="PLEASE LIKE AND SUBSCRIBE !", hex="#993E73", full_hex="#993E73", r=153, g=62, b=115, pearl_name="Race Yellow", pearl_id=89, archive_id="p0309", confidence="high"},
  {name="CONTENT!", hex="#995626", full_hex="#995626", r=153, g=86, b=38, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0310", confidence="high"},
  {name="MAHOGANY", hex="#20000A", full_hex="#20000AAA", r=32, g=0, b=10, pearl_name="Saddle Brown", pearl_id=nil, archive_id="p0311", confidence="high"},
  {name="AIRHEAD", hex="#4B46CD", full_hex="#4B46CD", r=75, g=70, b=205, pearl_name="Ice White", pearl_id=111, archive_id="p0312", confidence="high"},
  {name="next !!", hex="#0B122C", full_hex="#0B122CAA", r=11, g=18, b=44, pearl_name="Moss Brown", pearl_id=100, archive_id="p0313", confidence="high"},
  {name="next !!", hex="#160208", full_hex="#160208AA", r=22, g=2, b=8, pearl_name="Ice White", pearl_id=111, archive_id="p0314", confidence="high"},
  {name="10) Freshmint Khameleon", hex="#49AFFF", full_hex="#49AFFF", r=73, g=175, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0315", confidence="high"},
  {name="2) Regera Green Osiris", hex="#051D1C", full_hex="#051D1CAA", r=5, g=29, b=28, pearl_name="Cream", pearl_id=107, archive_id="p0316", confidence="high"},
  {name="3) Madagascar Orange Elegy", hex="#8D2501", full_hex="#8D2501AA", r=141, g=37, b=1, pearl_name="Cream", pearl_id=107, archive_id="p0317", confidence="high"},
  {name="6) Mystichrome Vagner: OAOOOAAA (Hot Pink)", hex="#FF6600", full_hex="#FF6600", r=255, g=102, b=0, pearl_name="Ice White", pearl_id=111, archive_id="p0318", confidence="high"},
  {name="8) Twilight Blue Dukes", hex="#070015", full_hex="#070015AA", r=7, g=0, b=21, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0319", confidence="high"},
  {name="Brown)", hex="#020D51", full_hex="#020D51AA", r=2, g=13, b=81, pearl_name="", pearl_id=nil, archive_id="p0320", confidence="medium"},
  {name="Flash Purple Banshee", hex="#19005B", full_hex="#19005BFF", r=25, g=0, b=91, pearl_name="Race Yellow", pearl_id=89, archive_id="p0321", confidence="high"},
  {name="Worlds Ugliest Retro Comet", hex="#1C190F", full_hex="#1C190FAA", r=28, g=25, b=15, pearl_name="", pearl_id=nil, archive_id="p0322", confidence="medium"},
  {name="Vs", hex="#BBEB2A", full_hex="#BBEB2A", r=187, g=235, b=42, pearl_name="", pearl_id=nil, archive_id="p0323", confidence="high"},
  {name="Metalic Yellow", hex="#F03C2B", full_hex="#F03C2B", r=240, g=60, b=43, pearl_name="", pearl_id=nil, archive_id="p0324", confidence="medium"},
  {name="PAINTJOB2", hex="#4D3160", full_hex="#4D3160AA", r=77, g=49, b=96, pearl_name="", pearl_id=nil, archive_id="p0325", confidence="high"},
  {name="PERL: RENN GELB", hex="#0F1710", full_hex="#0F1710AA", r=15, g=23, b=16, pearl_name="", pearl_id=nil, archive_id="p0326", confidence="high"},
  {name="ibyIkue", hex="#280060", full_hex="#280060", r=40, g=0, b=96, pearl_name="", pearl_id=nil, archive_id="p0327", confidence="high"},
  {name="470 SUD", hex="#FF5E5E", full_hex="#FF5E5E", r=255, g=94, b=94, pearl_name="", pearl_id=nil, archive_id="p0328", confidence="medium"},
  {name="ROSE PINK", hex="#FF5047", full_hex="#FF5047", r=255, g=80, b=71, pearl_name="", pearl_id=nil, archive_id="p0329", confidence="high"},
  {name="Silenced!", hex="#CC544E", full_hex="#CC544E", r=204, g=84, b=78, pearl_name="", pearl_id=nil, archive_id="p0330", confidence="high"},
  {name="io", hex="#2F2B3B", full_hex="#2F2B3BAA", r=47, g=43, b=59, pearl_name="", pearl_id=nil, archive_id="p0331", confidence="high"},
  {name="os", hex="#14397F", full_hex="#14397FAA", r=20, g=57, b=127, pearl_name="", pearl_id=nil, archive_id="p0332", confidence="high"},
  {name="Lamborghini Titanium Metallic", hex="#B0A892", full_hex="#B0A89200", r=176, g=168, b=146, pearl_name="Frost White", pearl_id=112, archive_id="p0333", confidence="high"},
  {name="ee", hex="#080F09", full_hex="#080F09FF", r=8, g=15, b=9, pearl_name="", pearl_id=nil, archive_id="p0334", confidence="medium"},
  {name="Very-inaccurate Bleu de France (#", hex="#318CE7", full_hex="#318CE7", r=49, g=140, b=231, pearl_name="", pearl_id=nil, archive_id="p0335", confidence="high"},
  {name="Babaye Orange SEBCZ/ 7)", hex="#6AC5F4", full_hex="#6AC5F4", r=106, g=197, b=244, pearl_name="", pearl_id=nil, archive_id="p0336", confidence="high"},
  {name="accurate to their namesake.", hex="#FFCE00", full_hex="#FFCE00", r=255, g=206, b=0, pearl_name="gold", pearl_id=37, archive_id="p0337", confidence="high"},
  {name="SUFF", hex="#4E0825", full_hex="#4E0825AA", r=78, g=8, b=37, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0338", confidence="high"},
  {name="f 17 Jun 2016", hex="#2B5540", full_hex="#2B5540AA", r=43, g=85, b=64, pearl_name="Frost White", pearl_id=112, archive_id="p0339", confidence="high"},
  {name="Unnamed #0E1C45", hex="#0E1C45", full_hex="#0E1C45AA", r=14, g=28, b=69, pearl_name="ultra blue", pearl_id=70, archive_id="p0340", confidence="medium"},
  {name="Kustom", hex="#38352E", full_hex="#38352E", r=56, g=53, b=46, pearl_name="", pearl_id=nil, archive_id="p0341", confidence="high"},
  {name="ILLUMINATI BLUE", hex="#086182", full_hex="#086182FF", r=8, g=97, b=130, pearl_name="Ice White", pearl_id=111, archive_id="p0342", confidence="high"},
  {name="ALL", hex="#00FA9A", full_hex="#00FA9A", r=0, g=250, b=154, pearl_name="", pearl_id=nil, archive_id="p0343", confidence="high"},
  {name="ALL", hex="#603E94", full_hex="#603E94", r=96, g=62, b=148, pearl_name="", pearl_id=nil, archive_id="p0344", confidence="high"},
  {name="Candy Pink -#", hex="#F788CE", full_hex="#F788CE", r=247, g=136, b=206, pearl_name="", pearl_id=nil, archive_id="p0345", confidence="high"},
  {name="Glowing Yellow - #", hex="#ECFF8C", full_hex="#ECFF8C", r=236, g=255, b=140, pearl_name="", pearl_id=nil, archive_id="p0346", confidence="high"},
  {name="Toxic Green - #", hex="#DDFF03", full_hex="#DDFF03", r=221, g=255, b=3, pearl_name="", pearl_id=nil, archive_id="p0347", confidence="high"},
  {name="Adder", hex="#434391", full_hex="#434391AA", r=67, g=67, b=145, pearl_name="", pearl_id=nil, archive_id="p0348", confidence="high"},
  {name="isle", hex="#F788CE", full_hex="#F788CE", r=247, g=136, b=206, pearl_name="", pearl_id=nil, archive_id="p0349", confidence="high"},
  {name="all! 2", hex="#0ADD25", full_hex="#0ADD25AA", r=10, g=221, b=37, pearl_name="", pearl_id=nil, archive_id="p0350", confidence="medium"},
  {name="Pale Green", hex="#237FFF", full_hex="#237FFF7F", r=35, g=127, b=255, pearl_name="", pearl_id=nil, archive_id="p0351", confidence="high"},
  {name="47 AM", hex="#64FF64", full_hex="#64FF64", r=100, g=255, b=100, pearl_name="", pearl_id=nil, archive_id="p0352", confidence="high"},
  {name="Balticblau 1982 BM", hex="#1E2D34", full_hex="#1E2D34AA", r=30, g=45, b=52, pearl_name="", pearl_id=nil, archive_id="p0353", confidence="medium"},
  {name="lose Quartz", hex="#352225", full_hex="#352225", r=53, g=34, b=37, pearl_name="", pearl_id=nil, archive_id="p0354", confidence="high"},
  {name="Random Diamond Blue", hex="#21323D", full_hex="#21323DAA", r=33, g=50, b=61, pearl_name="iBlue", pearl_id=nil, archive_id="p0355", confidence="high"},
  {name="Cool", hex="#8BACBC", full_hex="#8BACBC00", r=139, g=172, b=188, pearl_name="", pearl_id=nil, archive_id="p0356", confidence="medium"},
  {name="holo Gang Sabre", hex="#E1E168", full_hex="#E1E168", r=225, g=225, b=104, pearl_name="", pearl_id=nil, archive_id="p0357", confidence="high"},
  {name="Copper Orange", hex="#260D02", full_hex="#260D02AA", r=38, g=13, b=2, pearl_name="Pink", pearl_id=135, archive_id="p0358", confidence="high"},
  {name="jom Green", hex="#205E40", full_hex="#205E40AA", r=32, g=94, b=64, pearl_name="", pearl_id=nil, archive_id="p0359", confidence="high"},
  {name="Random Light Blue", hex="#081E28", full_hex="#081E28AA", r=8, g=30, b=40, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0360", confidence="high"},
  {name="Wildberry", hex="#240D14", full_hex="#240D14AA", r=36, g=13, b=20, pearl_name="", pearl_id=nil, archive_id="p0361", confidence="high"},
  {name="1058 CHEVY SNOWICREST", hex="#CCCCCC", full_hex="#CCCCCC", r=204, g=204, b=204, pearl_name="", pearl_id=nil, archive_id="p0362", confidence="high"},
  {name="ROSE GOLD", hex="#5F4142", full_hex="#5F4142AA", r=95, g=65, b=66, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0363", confidence="high"},
  {name="Second: Brushed gold", hex="#590048", full_hex="#590048", r=89, g=0, b=72, pearl_name="", pearl_id=nil, archive_id="p0364", confidence="high"},
  {name="Vs", hex="#3503FF", full_hex="#3503FF", r=53, g=3, b=255, pearl_name="", pearl_id=nil, archive_id="p0365", confidence="high"},
  {name="BRONZE PINK", hex="#090022", full_hex="#090022AA", r=9, g=0, b=34, pearl_name="Race yellow", pearl_id=89, archive_id="p0366", confidence="high"},
  {name="NEON YELLOW", hex="#DEFF00", full_hex="#DEFF00AA", r=222, g=255, b=0, pearl_name="Ice White", pearl_id=111, archive_id="p0367", confidence="high"},
  {name="SHINY BLUE", hex="#231FA7", full_hex="#231FA7AA", r=35, g=31, b=167, pearl_name="Ice White", pearl_id=111, archive_id="p0368", confidence="high"},
  {name="SUPERFLY", hex="#FF4133", full_hex="#FF4133", r=255, g=65, b=51, pearl_name="Race Yellow", pearl_id=89, archive_id="p0369", confidence="high"},
  {name="next !!", hex="#5A302E", full_hex="#5A302EAA", r=90, g=48, b=46, pearl_name="", pearl_id=nil, archive_id="p0370", confidence="medium"},
  {name="Chameleon (Lime Green)", hex="#00031A", full_hex="#00031AAA", r=0, g=3, b=26, pearl_name="", pearl_id=nil, archive_id="p0371", confidence="medium"},
  {name="eo", hex="#5E5B46", full_hex="#5E5B46AA", r=94, g=91, b=70, pearl_name="Ice White", pearl_id=111, archive_id="p0372", confidence="high"},
  {name="lue", hex="#020D51", full_hex="#020D51AA", r=2, g=13, b=81, pearl_name="", pearl_id=nil, archive_id="p0373", confidence="medium"},
  {name="Inkognito Green", hex="#81AC8D", full_hex="#81AC8D00", r=129, g=172, b=141, pearl_name="Lime Green", pearl_id=92, archive_id="p0374", confidence="high"},
  {name="Presidential Red", hex="#100A0C", full_hex="#100A0CAA", r=16, g=10, b=12, pearl_name="Torino Red", pearl_id=28, archive_id="p0375", confidence="high"},
  {name="Dark Ultra Blue", hex="#030308", full_hex="#030308A9", r=3, g=3, b=8, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0376", confidence="high"},
  {name="Sensual Pink", hex="#030308", full_hex="#030308A9", r=3, g=3, b=8, pearl_name="Hot Pink", pearl_id=135, archive_id="p0377", confidence="high"},
  {name="ASTON MARTIN VALKYRIE", hex="#313036", full_hex="#313036AA", r=49, g=48, b=54, pearl_name="Ice White", pearl_id=111, archive_id="p0378", confidence="high"},
  {name="CUNNING PURPLE", hex="#290026", full_hex="#290026AA", r=41, g=0, b=38, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0379", confidence="high"},
  {name="AM", hex="#F9526B", full_hex="#F9526B", r=249, g=82, b=107, pearl_name="", pearl_id=nil, archive_id="p0380", confidence="medium"},
  {name="PR-DESATURATED-RED", hex="#FF6961", full_hex="#FF6961", r=255, g=105, b=97, pearl_name="Frost White", pearl_id=112, archive_id="p0381", confidence="high"},
  {name="SUBSCRIBE", hex="#FFD859", full_hex="#FFD859", r=255, g=216, b=89, pearl_name="", pearl_id=nil, archive_id="p0382", confidence="high"},
  {name="SHEN: #", hex="#13002F", full_hex="#13002FAA", r=19, g=0, b=47, pearl_name="france", pearl_id=nil, archive_id="p0383", confidence="high"},
  {name="Yellowfever (Ice White Pearl)", hex="#FFA62F", full_hex="#FFA62F", r=255, g=166, b=47, pearl_name="Cream", pearl_id=107, archive_id="p0384", confidence="high"},
  {name="ot", hex="#4E4EFF", full_hex="#4E4EFF", r=78, g=78, b=255, pearl_name="Cream", pearl_id=107, archive_id="p0385", confidence="high"},
  {name="ot", hex="#CD9EA4", full_hex="#CD9EA400", r=205, g=158, b=164, pearl_name="Ice White", pearl_id=111, archive_id="p0386", confidence="high"},
  {name="ot", hex="#FF3E2F", full_hex="#FF3E2F", r=255, g=62, b=47, pearl_name="Ice White", pearl_id=111, archive_id="p0387", confidence="high"},
  {name="Kustom", hex="#0A1A29", full_hex="#0A1A29FF", r=10, g=26, b=41, pearl_name="", pearl_id=nil, archive_id="p0388", confidence="high"},
  {name="ef", hex="#160118", full_hex="#160118FF", r=22, g=1, b=24, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0389", confidence="high"},
  {name="Ultra Strawberry #", hex="#FF2445", full_hex="#FF2445", r=255, g=36, b=69, pearl_name="", pearl_id=nil, archive_id="p0390", confidence="high"},
  {name="next !!", hex="#4E4EFF", full_hex="#4E4EFF", r=78, g=78, b=255, pearl_name="Cream", pearl_id=107, archive_id="p0391", confidence="high"},
  {name="next !!", hex="#CD9EA4", full_hex="#CD9EA400", r=205, g=158, b=164, pearl_name="Ice White", pearl_id=111, archive_id="p0392", confidence="high"},
  {name="next !!", hex="#FF3E2F", full_hex="#FF3E2F", r=255, g=62, b=47, pearl_name="Ice White", pearl_id=111, archive_id="p0393", confidence="high"},
  {name="Ultra Baby Blue", hex="#4C6799", full_hex="#4C6799", r=76, g=103, b=153, pearl_name="ultra blue", pearl_id=70, archive_id="p0394", confidence="high"},
  {name="Soft Peach", hex="#F0A078", full_hex="#F0A078", r=240, g=160, b=120, pearl_name="white", pearl_id=111, archive_id="p0395", confidence="high"},
  {name="Mountain Dew", hex="#94992E", full_hex="#94992E", r=148, g=153, b=46, pearl_name="Ice White", pearl_id=111, archive_id="p0396", confidence="high"},
  {name="Emerald Green", hex="#34996A", full_hex="#34996A", r=52, g=153, b=106, pearl_name="lime green", pearl_id=92, archive_id="p0397", confidence="high"},
  {name="Garnet Purple", hex="#590599", full_hex="#590599", r=89, g=5, b=153, pearl_name="hot pink", pearl_id=135, archive_id="p0398", confidence="high"},
  {name="Super Pink", hex="#990237", full_hex="#990237", r=153, g=2, b=55, pearl_name="Ice White", pearl_id=111, archive_id="p0399", confidence="high"},
  {name="hit the like button and look out for more", hex="#FF0030", full_hex="#FF0030", r=255, g=0, b=48, pearl_name="", pearl_id=nil, archive_id="p0400", confidence="high"},
  {name="Name: Blazed Purple", hex="#080019", full_hex="#080019", r=8, g=0, b=25, pearl_name="", pearl_id=nil, archive_id="p0401", confidence="high"},
  {name="Name: Doped OUT (PC ONLY)", hex="#0F0123", full_hex="#0F0123", r=15, g=1, b=35, pearl_name="", pearl_id=nil, archive_id="p0402", confidence="high"},
  {name="Hot Nebula Glitch NEEDED", hex="#000032", full_hex="#000032", r=0, g=0, b=50, pearl_name="", pearl_id=nil, archive_id="p0403", confidence="high"},
  {name="Name: Midnight Blue Glitch NEEDED", hex="#000028", full_hex="#000028", r=0, g=0, b=40, pearl_name="", pearl_id=nil, archive_id="p0404", confidence="high"},
  {name="Reaching Pink: Glitch NEEDED", hex="#190019", full_hex="#190019", r=25, g=0, b=25, pearl_name="", pearl_id=nil, archive_id="p0405", confidence="high"},
  {name="Add a public reply...", hex="#6600FF", full_hex="#6600FF", r=102, g=0, b=255, pearl_name="", pearl_id=nil, archive_id="p0406", confidence="high"},
  {name="BLINK182", hex="#0D0D26", full_hex="#0D0D26AA", r=13, g=13, b=38, pearl_name="", pearl_id=nil, archive_id="p0407", confidence="high"},
  {name="ZZ", hex="#001919", full_hex="#001919AA", r=0, g=25, b=25, pearl_name="", pearl_id=nil, archive_id="p0408", confidence="high"},
  {name="Cc.", hex="#00FA9A", full_hex="#00FA9A", r=0, g=250, b=154, pearl_name="", pearl_id=nil, archive_id="p0409", confidence="high"},
  {name="He", hex="#0505FF", full_hex="#0505FF", r=5, g=5, b=255, pearl_name="", pearl_id=nil, archive_id="p0410", confidence="medium"},
  {name="Shiny Blue", hex="#0505FF", full_hex="#0505FF", r=5, g=5, b=255, pearl_name="", pearl_id=nil, archive_id="p0411", confidence="high"},
  {name="BE", hex="#003A64", full_hex="#003A64", r=0, g=58, b=100, pearl_name="", pearl_id=nil, archive_id="p0412", confidence="high"},
  {name="mk", hex="#0A001C", full_hex="#0A001C", r=10, g=0, b=28, pearl_name="", pearl_id=nil, archive_id="p0413", confidence="high"},
  {name="Nasty", hex="#FF3E29", full_hex="#FF3E29", r=255, g=62, b=41, pearl_name="", pearl_id=nil, archive_id="p0414", confidence="high"},
  {name="Nothing Too Dirty!", hex="#E02920", full_hex="#E02920", r=224, g=41, b=32, pearl_name="", pearl_id=nil, archive_id="p0415", confidence="high"},
  {name="Nuerr", hex="#33FF99", full_hex="#33FF99", r=51, g=255, b=153, pearl_name="", pearl_id=nil, archive_id="p0416", confidence="high"},
  {name="o). __@ ie", hex="#33FF99", full_hex="#33FF99", r=51, g=255, b=153, pearl_name="", pearl_id=nil, archive_id="p0417", confidence="high"},
  {name="Creator: TOP_LNOCH_BAZZIL", hex="#744FD0", full_hex="#744FD0", r=116, g=79, b=208, pearl_name="", pearl_id=nil, archive_id="p0418", confidence="high"},
  {name="MEX(: #", hex="#744F0D", full_hex="#744F0D", r=116, g=79, b=13, pearl_name="", pearl_id=nil, archive_id="p0419", confidence="medium"},
  {name="Guide", hex="#FF0023", full_hex="#FF0023", r=255, g=0, b=35, pearl_name="Torino Red", pearl_id=28, archive_id="p0420", confidence="high"},
  {name="Sour Punch", hex="#004953", full_hex="#004953AA", r=0, g=73, b=83, pearl_name="", pearl_id=nil, archive_id="p0421", confidence="high"},
  {name="LEMON-HEAD", hex="#FFFF66", full_hex="#FFFF66", r=255, g=255, b=102, pearl_name="", pearl_id=nil, archive_id="p0422", confidence="high"},
  {name="MANTIS GREEN", hex="#0AFF60", full_hex="#0AFF60", r=10, g=255, b=96, pearl_name="Cream", pearl_id=107, archive_id="p0423", confidence="high"},
  {name="SAXON 2.0", hex="#25385B", full_hex="#25385BAA", r=37, g=56, b=91, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0424", confidence="high"},
  {name="COLOSSUS", hex="#0D020F", full_hex="#0D020FAA", r=13, g=2, b=15, pearl_name="Sea Green", pearl_id=51, archive_id="p0425", confidence="high"},
  {name="3 PAINTLABS IN", hex="#FF2A12", full_hex="#FF2A12", r=255, g=42, b=18, pearl_name="", pearl_id=nil, archive_id="p0426", confidence="high"},
  {name="3 PAINTLABS IN", hex="#FFFF00", full_hex="#FFFF00", r=255, g=255, b=0, pearl_name="", pearl_id=nil, archive_id="p0427", confidence="medium"},
  {name="GREEN", hex="#36B058", full_hex="#36B058", r=54, g=176, b=88, pearl_name="", pearl_id=nil, archive_id="p0428", confidence="high"},
  {name="3.Neon Green: #", hex="#36B058", full_hex="#36B058", r=54, g=176, b=88, pearl_name="", pearl_id=nil, archive_id="p0429", confidence="high"},
  {name="C-X75 ORANGE", hex="#4F1F0D", full_hex="#4F1F0DAA", r=79, g=31, b=13, pearl_name="Bright Orange", pearl_id=138, archive_id="p0430", confidence="high"},
  {name="OASIS", hex="#00262E", full_hex="#00262EAA", r=0, g=38, b=46, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0431", confidence="high"},
  {name="FUSION", hex="#50181A", full_hex="#50181AAA", r=80, g=24, b=26, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0432", confidence="high"},
  {name="CITRON GOLD", hex="#58623B", full_hex="#58623BAA", r=88, g=98, b=59, pearl_name="Pure Gold", pearl_id=158, archive_id="p0433", confidence="high"},
  {name="CARNATION", hex="#40353F", full_hex="#40353FAA", r=64, g=53, b=63, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0434", confidence="high"},
  {name="C-X75 Blue", hex="#0F0837", full_hex="#0F0837AA", r=15, g=8, b=55, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0435", confidence="high"},
  {name="CHILI PEPPER", hex="#230008", full_hex="#230008AA", r=35, g=0, b=8, pearl_name="Orange", pearl_id=38, archive_id="p0436", confidence="high"},
  {name="HE", hex="#0496CF", full_hex="#0496CF", r=4, g=150, b=207, pearl_name="", pearl_id=nil, archive_id="p0437", confidence="medium"},
  {name="Solid", hex="#0496CF", full_hex="#0496CF", r=4, g=150, b=207, pearl_name="", pearl_id=nil, archive_id="p0438", confidence="high"},
  {name="MRYPTONICHO", hex="#1AC0F5", full_hex="#1AC0F5", r=26, g=192, b=245, pearl_name="", pearl_id=nil, archive_id="p0439", confidence="medium"},
  {name="Yellow Dew!", hex="#ECFFBC", full_hex="#ECFFBC", r=236, g=255, b=188, pearl_name="", pearl_id=nil, archive_id="p0440", confidence="high"},
  {name="Bubble-GumpPurple", hex="#3A0064", full_hex="#3A0064", r=58, g=0, b=100, pearl_name="", pearl_id=nil, archive_id="p0441", confidence="high"},
  {name="14/1/1 (Classy Red) #", hex="#0E0101", full_hex="#0E0101", r=14, g=1, b=1, pearl_name="", pearl_id=nil, archive_id="p0442", confidence="high"},
  {name="ANEW", hex="#2B3C58", full_hex="#2B3C58", r=43, g=60, b=88, pearl_name="", pearl_id=nil, archive_id="p0443", confidence="high"},
  {name="amazing!!!!!", hex="#5A2C00", full_hex="#5A2C00", r=90, g=44, b=0, pearl_name="", pearl_id=nil, archive_id="p0444", confidence="high"},
  {name="THE END OF THE YEAR/2017. YOU CAN MAKE IT", hex="#00FA9A", full_hex="#00FA9A", r=0, g=250, b=154, pearl_name="", pearl_id=nil, archive_id="p0445", confidence="high"},
  {name="Saal", hex="#00FF00", full_hex="#00FF00AA", r=0, g=255, b=0, pearl_name="", pearl_id=nil, archive_id="p0446", confidence="high"},
  {name="Saal", hex="#100029", full_hex="#100029AA", r=16, g=0, b=41, pearl_name="", pearl_id=nil, archive_id="p0447", confidence="high"},
  {name="Carnival Blue", hex="#003A64", full_hex="#003A64", r=0, g=58, b=100, pearl_name="", pearl_id=nil, archive_id="p0448", confidence="high"},
  {name="steel", hex="#FF0303", full_hex="#FF0303", r=255, g=3, b=3, pearl_name="", pearl_id=nil, archive_id="p0449", confidence="high"},
  {name="NIGHTLY", hex="#FF2400", full_hex="#FF2400", r=255, g=36, b=0, pearl_name="", pearl_id=nil, archive_id="p0450", confidence="high"},
  {name="Blue Pastel", hex="#577EA0", full_hex="#577EA000", r=87, g=126, b=160, pearl_name="Cream", pearl_id=107, archive_id="p0451", confidence="high"},
  {name="Blazing Orange - #", hex="#FF6600", full_hex="#FF6600", r=255, g=102, b=0, pearl_name="", pearl_id=nil, archive_id="p0452", confidence="high"},
  {name="Dahilia Orange - #", hex="#FF9F7F", full_hex="#FF9F7F", r=255, g=159, b=127, pearl_name="Ice White", pearl_id=111, archive_id="p0453", confidence="high"},
  {name="Neon Orange - #", hex="#FF2A12", full_hex="#FF2A12", r=255, g=42, b=18, pearl_name="", pearl_id=nil, archive_id="p0454", confidence="high"},
  {name="Pastel Orange - #", hex="#FFCC99", full_hex="#FFCC9900", r=255, g=204, b=153, pearl_name="", pearl_id=nil, archive_id="p0455", confidence="high"},
  {name="Peach Sunrise - #", hex="#FF4E50", full_hex="#FF4E50", r=255, g=78, b=80, pearl_name="Ice White", pearl_id=111, archive_id="p0456", confidence="high"},
  {name="BLUSH RED", hex="#50181A", full_hex="#50181AAA", r=80, g=24, b=26, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0457", confidence="high"},
  {name="SOUR LEMON", hex="#EAFF7F", full_hex="#EAFF7F", r=234, g=255, b=127, pearl_name="", pearl_id=nil, archive_id="p0458", confidence="high"},
  {name="ROSE GOLD", hex="#B76E79", full_hex="#B76E79FF", r=183, g=110, b=121, pearl_name="", pearl_id=nil, archive_id="p0459", confidence="high"},
  {name="DARK PLUM", hex="#0F0837", full_hex="#0F0837AA", r=15, g=8, b=55, pearl_name="Frost White", pearl_id=112, archive_id="p0460", confidence="high"},
  {name="VOLT COPPER", hex="#3D201C", full_hex="#3D201CAA", r=61, g=32, b=28, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0461", confidence="high"},
  {name="SEDUCTIVE PEACH", hex="#FF5E5E", full_hex="#FF5E5E", r=255, g=94, b=94, pearl_name="ULTRA BLUE", pearl_id=70, archive_id="p0462", confidence="high"},
  {name="AVOCADO GREEN", hex="#273D01", full_hex="#273D01AA", r=39, g=61, b=1, pearl_name="", pearl_id=nil, archive_id="p0463", confidence="high"},
  {name="ICE ICE BABY", hex="#CCEEFF", full_hex="#CCEEFF00", r=204, g=238, b=255, pearl_name="ULTRA BLUE", pearl_id=70, archive_id="p0464", confidence="high"},
  {name="BALLIN PURPLE", hex="#222449", full_hex="#222449AA", r=34, g=36, b=73, pearl_name="CREAM", pearl_id=107, archive_id="p0465", confidence="high"},
  {name="LUXURY PINK", hex="#634040", full_hex="#634040AA", r=99, g=64, b=64, pearl_name="CREAM", pearl_id=107, archive_id="p0466", confidence="high"},
  {name="DOPE PURPLE", hex="#3503FF", full_hex="#3503FF", r=53, g=3, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0467", confidence="high"},
  {name="SINGERS GOLD", hex="#503F30", full_hex="#503F30AA", r=80, g=63, b=48, pearl_name="Ice White", pearl_id=111, archive_id="p0468", confidence="high"},
  {name="SUNNY DELIGHT", hex="#F07401", full_hex="#F07401AA", r=240, g=116, b=1, pearl_name="Ice White", pearl_id=111, archive_id="p0469", confidence="high"},
  {name="PROCKS PINK", hex="#1A000C", full_hex="#1A000CAA", r=26, g=0, b=12, pearl_name="HOT PINK", pearl_id=135, archive_id="p0470", confidence="high"},
  {name="AQUA MARINE", hex="#002C3A", full_hex="#002C3AAA", r=0, g=44, b=58, pearl_name="GASOLINE GREEN", pearl_id=54, archive_id="p0471", confidence="high"},
  {name="BOREALIS ORANGE", hex="#723800", full_hex="#723800AA", r=114, g=56, b=0, pearl_name="", pearl_id=nil, archive_id="p0472", confidence="high"},
  {name="NIGHT BLUE", hex="#00000A", full_hex="#00000AAA", r=0, g=0, b=10, pearl_name="ULTRA BLUE", pearl_id=70, archive_id="p0473", confidence="high"},
  {name="PLUM PURPLE", hex="#512A3F", full_hex="#512A3FAA", r=81, g=42, b=63, pearl_name="DIAMOND BLUE", pearl_id=67, archive_id="p0474", confidence="high"},
  {name="CREME DE MINT", hex="#5A7268", full_hex="#5A7268AA", r=90, g=114, b=104, pearl_name="Ice White", pearl_id=111, archive_id="p0475", confidence="high"},
  {name="PASTEL ORANGE", hex="#FF6E4A", full_hex="#FF6E4A", r=255, g=110, b=74, pearl_name="", pearl_id=nil, archive_id="p0476", confidence="high"},
  {name="SANDY YELLOW", hex="#FFE57F", full_hex="#FFE57F", r=255, g=229, b=127, pearl_name="CREAM", pearl_id=107, archive_id="p0477", confidence="high"},
  {name="DEEP CARNELION RED", hex="#270E12", full_hex="#270E12AA", r=39, g=14, b=18, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0478", confidence="high"},
  {name="ENFORCER PURPLE", hex="#4A27D6", full_hex="#4A27D6", r=74, g=39, b=214, pearl_name="Ice White", pearl_id=111, archive_id="p0479", confidence="high"},
  {name="OBSIDIAN YELLOW", hex="#0E1301", full_hex="#0E1301AA", r=14, g=19, b=1, pearl_name="", pearl_id=nil, archive_id="p0480", confidence="high"},
  {name="COPPER COIN", hex="#3E211B", full_hex="#3E211BAA", r=62, g=33, b=27, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0481", confidence="high"},
  {name="BRONZE", hex="#241414", full_hex="#241414AA", r=36, g=20, b=20, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0482", confidence="high"},
  {name="SILVER", hex="#313036", full_hex="#313036AA", r=49, g=48, b=54, pearl_name="Ice White", pearl_id=111, archive_id="p0483", confidence="high"},
  {name="SWEET PURPLE", hex="#BF91FF", full_hex="#BF91FFAA", r=191, g=145, b=255, pearl_name="Ice White", pearl_id=111, archive_id="p0484", confidence="high"},
  {name="WHITE anil tilt", hex="#BF91FF", full_hex="#BF91FFAA", r=191, g=145, b=255, pearl_name="", pearl_id=nil, archive_id="p0485", confidence="medium"},
  {name="ICE BLUE", hex="#4568F2", full_hex="#4568F2", r=69, g=104, b=242, pearl_name="Ice White", pearl_id=111, archive_id="p0486", confidence="high"},
  {name="PURPLE NINJA", hex="#15012B", full_hex="#15012BAA", r=21, g=1, b=43, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0487", confidence="high"},
  {name="NEBULOUS BLUE", hex="#002D47", full_hex="#002D47AA", r=0, g=45, b=71, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0488", confidence="high"},
  {name="4) Pink Passion- #", hex="#FF053F", full_hex="#FF053F", r=255, g=5, b=63, pearl_name="", pearl_id=nil, archive_id="p0489", confidence="medium"},
  {name="Blue Bird", hex="#000A19", full_hex="#000A19AA", r=0, g=10, b=25, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0490", confidence="high"},
  {name="Horny Red", hex="#310000", full_hex="#310000AA", r=49, g=0, b=0, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0491", confidence="high"},
  {name="Shadow", hex="#0A0813", full_hex="#0A0813AA", r=10, g=8, b=19, pearl_name="Ice White", pearl_id=111, archive_id="p0492", confidence="high"},
  {name="Camo Green", hex="#051512", full_hex="#051512AA", r=5, g=21, b=18, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0493", confidence="high"},
  {name="ance Lovers", hex="#463647", full_hex="#463647FF", r=70, g=54, b=71, pearl_name="", pearl_id=nil, archive_id="p0494", confidence="high"},
  {name="Anew", hex="#7C6A3A", full_hex="#7C6A3AFF", r=124, g=106, b=58, pearl_name="", pearl_id=nil, archive_id="p0495", confidence="high"},
  {name="Hunter Green", hex="#0F1710", full_hex="#0F1710AA", r=15, g=23, b=16, pearl_name="Ice White", pearl_id=111, archive_id="p0496", confidence="high"},
  {name="Rose Gold", hex="#B76E79", full_hex="#B76E79FF", r=183, g=110, b=121, pearl_name="yellow pear!", pearl_id=88, archive_id="p0497", confidence="high"},
  {name="Golden Yellow", hex="#FFD859", full_hex="#FFD859", r=255, g=216, b=89, pearl_name="Ice White", pearl_id=111, archive_id="p0498", confidence="high"},
  {name="SUBSCRIBE»", hex="#512A3F", full_hex="#512A3FAA", r=81, g=42, b=63, pearl_name="", pearl_id=nil, archive_id="p0499", confidence="high"},
  {name="ROSE PINK", hex="#FF053F", full_hex="#FF053F", r=255, g=5, b=63, pearl_name="Ice White", pearl_id=111, archive_id="p0500", confidence="high"},
  {name="NEON YELLOW", hex="#FFFF30", full_hex="#FFFF30", r=255, g=255, b=48, pearl_name="Ice White", pearl_id=111, archive_id="p0501", confidence="high"},
  {name="CALYPSO CORAL", hex="#FF595D", full_hex="#FF595D", r=255, g=89, b=93, pearl_name="Ice White", pearl_id=111, archive_id="p0502", confidence="high"},
  {name="NAVAL BLUE", hex="#0B1C32", full_hex="#0B1C32AA", r=11, g=28, b=50, pearl_name="Ice White", pearl_id=111, archive_id="p0503", confidence="high"},
  {name="CYCLOPS BLUE", hex="#050A4D", full_hex="#050A4DAA", r=5, g=10, b=77, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0504", confidence="high"},
  {name="SHEEN PINK", hex="#15000F", full_hex="#15000FAA", r=21, g=0, b=15, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0505", confidence="high"},
  {name="fo", hex="#5000FA", full_hex="#5000FAAA", r=80, g=0, b=250, pearl_name="", pearl_id=nil, archive_id="p0506", confidence="medium"},
  {name="LIQUEUR ORANGE", hex="#210904", full_hex="#210904AA", r=33, g=9, b=4, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0507", confidence="high"},
  {name="Frost-Blue-Grey-Blue &", hex="#122C3C", full_hex="#122C3CEE", r=18, g=44, b=60, pearl_name="Ice White", pearl_id=111, archive_id="p0508", confidence="high"},
  {name="EX: 1", hex="#D86CD8", full_hex="#D86CD8", r=216, g=108, b=216, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0509", confidence="high"},
  {name="te", hex="#4A002A", full_hex="#4A002A", r=74, g=0, b=42, pearl_name="", pearl_id=nil, archive_id="p0510", confidence="high"},
  {name="Set your crews to #", hex="#2D0015", full_hex="#2D0015", r=45, g=0, b=21, pearl_name="", pearl_id=nil, archive_id="p0511", confidence="high"},
  {name="Bleached Banana", hex="#FFDB70", full_hex="#FFDB70", r=255, g=219, b=112, pearl_name="", pearl_id=nil, archive_id="p0512", confidence="high"},
  {name="Icy Blue", hex="#3A7864", full_hex="#3A7864FF", r=58, g=120, b=100, pearl_name="Frost White", pearl_id=112, archive_id="p0513", confidence="high"},
  {name="Icy Blue", hex="#716AD2", full_hex="#716AD200", r=113, g=106, b=210, pearl_name="Ice White", pearl_id=111, archive_id="p0514", confidence="high"},
  {name="Cherry Red", hex="#FF0303", full_hex="#FF0303", r=255, g=3, b=3, pearl_name="", pearl_id=nil, archive_id="p0515", confidence="high"},
  {name="Mint", hex="#8AFFCA", full_hex="#8AFFCA00", r=138, g=255, b=202, pearl_name="", pearl_id=nil, archive_id="p0516", confidence="high"},
  {name="Diamond Ice", hex="#03F5E9", full_hex="#03F5E9", r=3, g=245, b=233, pearl_name="", pearl_id=nil, archive_id="p0517", confidence="high"},
  {name="BLUE STEEL", hex="#2B3742", full_hex="#2B3742AA", r=43, g=55, b=66, pearl_name="Ice White", pearl_id=111, archive_id="p0518", confidence="high"},
  {name="SUBLIME PURPLE", hex="#5B57FF", full_hex="#5B57FF", r=91, g=87, b=255, pearl_name="", pearl_id=nil, archive_id="p0519", confidence="medium"},
  {name="awe", hex="#060310", full_hex="#060310AA", r=6, g=3, b=16, pearl_name="", pearl_id=nil, archive_id="p0520", confidence="medium"},
  {name="Aweek ago", hex="#40547C", full_hex="#40547CFF", r=64, g=84, b=124, pearl_name="Frost", pearl_id=112, archive_id="p0521", confidence="high"},
  {name="KRAZE", hex="#17093F", full_hex="#17093FAA", r=23, g=9, b=63, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0522", confidence="high"},
  {name="PiONEER PEACH - #", hex="#F7786B", full_hex="#F7786B", r=247, g=120, b=107, pearl_name="", pearl_id=nil, archive_id="p0523", confidence="high"},
  {name="Dream", hex="#2937FF", full_hex="#2937FF", r=41, g=55, b=255, pearl_name="", pearl_id=nil, archive_id="p0524", confidence="high"},
  {name="SKYZAME", hex="#1A0009", full_hex="#1A0009AA", r=26, g=0, b=9, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0525", confidence="high"},
  {name="COSMO BLUE", hex="#4568F2", full_hex="#4568F2", r=69, g=104, b=242, pearl_name="Hot Pink", pearl_id=135, archive_id="p0526", confidence="high"},
  {name="codes are,", hex="#B0C4DE", full_hex="#B0C4DE", r=176, g=196, b=222, pearl_name="", pearl_id=nil, archive_id="p0527", confidence="high"},
  {name="3 AN", hex="#170422", full_hex="#170422AA", r=23, g=4, b=34, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0528", confidence="high"},
  {name="LIVERY #2 (Classic Red Stripe)", hex="#1E0208", full_hex="#1E0208AA", r=30, g=2, b=8, pearl_name="Torino Red", pearl_id=28, archive_id="p0529", confidence="high"},
  {name="LIVERY #3 (Team FlyUS)", hex="#050A4D", full_hex="#050A4DAA", r=5, g=10, b=77, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0530", confidence="high"},
  {name="LIVERY #4 (Sports Gray)", hex="#B6FF24", full_hex="#B6FF24", r=182, g=255, b=36, pearl_name="Lime Green", pearl_id=92, archive_id="p0531", confidence="high"},
  {name="ae", hex="#2D6241", full_hex="#2D624100", r=45, g=98, b=65, pearl_name="Cream", pearl_id=107, archive_id="p0532", confidence="high"},
  {name="YOLO RED", hex="#57001E", full_hex="#57001EAA", r=87, g=0, b=30, pearl_name="Torino Red", pearl_id=28, archive_id="p0533", confidence="high"},
  {name="SEPIA", hex="#5E2612", full_hex="#5E2612AA", r=94, g=38, b=18, pearl_name="Orange", pearl_id=38, archive_id="p0534", confidence="high"},
  {name="NN", hex="#7F0DFF", full_hex="#7F0DFF", r=127, g=13, b=255, pearl_name="", pearl_id=nil, archive_id="p0535", confidence="medium"},
  {name="NN", hex="#FF6364", full_hex="#FF6364", r=255, g=99, b=100, pearl_name="", pearl_id=nil, archive_id="p0536", confidence="high"},
  {name="SS)", hex="#0D0304", full_hex="#0D0304AA", r=13, g=3, b=4, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0537", confidence="high"},
  {name="SS)", hex="#29606F", full_hex="#29606FFF", r=41, g=96, b=111, pearl_name="Ice White", pearl_id=111, archive_id="p0538", confidence="high"},
  {name="Mint Candy", hex="#9CBA7F", full_hex="#9CBA7F", r=156, g=186, b=127, pearl_name="", pearl_id=nil, archive_id="p0539", confidence="medium"},
  {name="Tomato Red", hex="#FF6347", full_hex="#FF6347", r=255, g=99, b=71, pearl_name="", pearl_id=nil, archive_id="p0540", confidence="medium"},
  {name="AMETHYST PURPLE", hex="#330055", full_hex="#330055AA", r=51, g=0, b=85, pearl_name="Torino Red", pearl_id=28, archive_id="p0541", confidence="high"},
  {name="ELEANOR GRAY", hex="#313036", full_hex="#313036AA", r=49, g=48, b=54, pearl_name="Frost White", pearl_id=112, archive_id="p0542", confidence="high"},
  {name="SHARK PINK", hex="#FFD1DC", full_hex="#FFD1DC00", r=255, g=209, b=220, pearl_name="HOT PINK", pearl_id=135, archive_id="p0543", confidence="high"},
  {name="I TL", hex="#CFC0A5", full_hex="#CFC0A500", r=207, g=192, b=165, pearl_name="", pearl_id=nil, archive_id="p0544", confidence="medium"},
  {name="omens", hex="#CFC0A5", full_hex="#CFC0A5", r=207, g=192, b=165, pearl_name="", pearl_id=nil, archive_id="p0545", confidence="medium"},
  {name="DEEP DEVIL RED", hex="#1A0003", full_hex="#1A0003AA", r=26, g=0, b=3, pearl_name="Torino Red", pearl_id=28, archive_id="p0546", confidence="high"},
  {name="introducing a", hex="#3A9978", full_hex="#3A9978", r=58, g=153, b=120, pearl_name="", pearl_id=nil, archive_id="p0547", confidence="high"},
  {name="RRR RR RRR", hex="#FF2F24", full_hex="#FF2F24", r=255, g=47, b=36, pearl_name="", pearl_id=nil, archive_id="p0548", confidence="high"},
  {name="Iceberg blue", hex="#4041FF", full_hex="#4041FF", r=64, g=65, b=255, pearl_name="", pearl_id=nil, archive_id="p0549", confidence="high"},
  {name="Founder: Ikue", hex="#4B39AB", full_hex="#4B39ABAA", r=75, g=57, b=171, pearl_name="Ice White", pearl_id=111, archive_id="p0550", confidence="high"},
  {name="WEED", hex="#510015", full_hex="#51001500", r=81, g=0, b=21, pearl_name="", pearl_id=nil, archive_id="p0551", confidence="medium"},
  {name="alll 6", hex="#290026", full_hex="#290026", r=41, g=0, b=38, pearl_name="", pearl_id=nil, archive_id="p0552", confidence="high"},
  {name="Eira", hex="#FF2400", full_hex="#FF2400", r=255, g=36, b=0, pearl_name="", pearl_id=nil, archive_id="p0553", confidence="high"},
  {name="BLACELLOW", hex="#000050", full_hex="#000050", r=0, g=0, b=80, pearl_name="", pearl_id=nil, archive_id="p0554", confidence="high"},
  {name="More", hex="#0A0025", full_hex="#0A0025AA", r=10, g=0, b=37, pearl_name="", pearl_id=nil, archive_id="p0555", confidence="high"},
  {name="CARBON SHADOW", hex="#191919", full_hex="#191919AA", r=25, g=25, b=25, pearl_name="Frost White", pearl_id=112, archive_id="p0556", confidence="high"},
  {name="RICH GOLD", hex="#BD954B", full_hex="#BD954BAA", r=189, g=149, b=75, pearl_name="CREAM", pearl_id=107, archive_id="p0557", confidence="high"},
  {name="SILKY PURPLE", hex="#927EB2", full_hex="#927EB200", r=146, g=126, b=178, pearl_name="CREAM", pearl_id=107, archive_id="p0558", confidence="high"},
  {name="GLACIERS OF ICE", hex="#77FFC9", full_hex="#77FFC9", r=119, g=255, b=201, pearl_name="", pearl_id=nil, archive_id="p0559", confidence="high"},
  {name="Copy an", hex="#7FF9FF", full_hex="#7FF9FF", r=127, g=249, b=255, pearl_name="", pearl_id=nil, archive_id="p0560", confidence="high"},
  {name="Copy an", hex="#FF9300", full_hex="#FF9300", r=255, g=147, b=0, pearl_name="", pearl_id=nil, archive_id="p0561", confidence="high"},
  {name="ETR1", hex="#5C90F5", full_hex="#5C90F5", r=92, g=144, b=245, pearl_name="", pearl_id=nil, archive_id="p0562", confidence="high"},
  {name="ETR1", hex="#D40015", full_hex="#D40015", r=212, g=0, b=21, pearl_name="", pearl_id=nil, archive_id="p0563", confidence="high"},
  {name="Sultan", hex="#FF003C", full_hex="#FF003C", r=255, g=0, b=60, pearl_name="", pearl_id=nil, archive_id="p0564", confidence="medium"},
  {name="ay", hex="#002846", full_hex="#002846AA", r=0, g=40, b=70, pearl_name="", pearl_id=nil, archive_id="p0565", confidence="high"},
  {name="Ri", hex="#407C84", full_hex="#407C84", r=64, g=124, b=132, pearl_name="", pearl_id=nil, archive_id="p0566", confidence="medium"},
  {name="Ri", hex="#DE3036", full_hex="#DE3036", r=222, g=48, b=54, pearl_name="", pearl_id=nil, archive_id="p0567", confidence="medium"},
  {name="Ri", hex="#E62020", full_hex="#E62020", r=230, g=32, b=32, pearl_name="", pearl_id=nil, archive_id="p0568", confidence="medium"},
  {name="SALUT A TOUS!", hex="#CCFC7E", full_hex="#CCFC7E", r=204, g=252, b=126, pearl_name="", pearl_id=nil, archive_id="p0569", confidence="high"},
  {name="BROWN (PERS", hex="#20000A", full_hex="#20000AAA", r=32, g=0, b=10, pearl_name="", pearl_id=nil, archive_id="p0570", confidence="high"},
  {name="PED Gt OUSURDY KELLER # \\SNOCRA", hex="#1A010C", full_hex="#1A010CAA", r=26, g=1, b=12, pearl_name="", pearl_id=nil, archive_id="p0571", confidence="high"},
  {name="WORN DARK FRED # Z1080409)", hex="#0804AA", full_hex="#0804AA", r=8, g=4, b=170, pearl_name="", pearl_id=nil, archive_id="p0572", confidence="high"},
  {name="BLUs [Rent", hex="#00020F", full_hex="#00020FAA", r=0, g=2, b=15, pearl_name="", pearl_id=nil, archive_id="p0573", confidence="high"},
  {name="Go", hex="#080D1E", full_hex="#080D1EAA", r=8, g=13, b=30, pearl_name="", pearl_id=nil, archive_id="p0574", confidence="high"},
  {name="SS", hex="#050618", full_hex="#05061897", r=5, g=6, b=24, pearl_name="", pearl_id=nil, archive_id="p0575", confidence="high"},
  {name="ue", hex="#595650", full_hex="#595650AA", r=89, g=86, b=80, pearl_name="", pearl_id=nil, archive_id="p0576", confidence="high"},
  {name="CELADON GREEN", hex="#4B8267", full_hex="#4B8267AA", r=75, g=130, b=103, pearl_name="Sandy Brown", pearl_id=129, archive_id="p0577", confidence="high"},
  {name="Autumn Gold", hex="#672900", full_hex="#672900AA", r=103, g=41, b=0, pearl_name="light orange", pearl_id=124, archive_id="p0578", confidence="high"},
  {name="Wild Berry", hex="#3B002D", full_hex="#3B002DAA", r=59, g=0, b=45, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0579", confidence="high"},
  {name="Maserati Pale Yellow", hex="#998E4F", full_hex="#998E4FAA", r=153, g=142, b=79, pearl_name="", pearl_id=nil, archive_id="p0580", confidence="high"},
  {name="Utility Black Poly", hex="#121212", full_hex="#121212AA", r=18, g=18, b=18, pearl_name="Sandy Brown", pearl_id=129, archive_id="p0581", confidence="high"},
  {name="Chevrolet Evening Orchid", hex="#2F2B3B", full_hex="#2F2B3BAA", r=47, g=43, b=59, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0582", confidence="high"},
  {name="Plum Crazy Purple medium", hex="#1E0F36", full_hex="#1E0F36AA", r=30, g=15, b=54, pearl_name="bluish silver", pearl_id=5, archive_id="p0583", confidence="high"},
  {name="io", hex="#120F12", full_hex="#120F12AA", r=18, g=15, b=18, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0584", confidence="high"},
  {name="FS 36231 (#", hex="#494D50", full_hex="#494D50FF", r=73, g=77, b=80, pearl_name="and no", pearl_id=nil, archive_id="p0585", confidence="high"},
  {name="Kustom", hex="#788D12", full_hex="#788D12AA", r=120, g=141, b=18, pearl_name="Yellow", pearl_id=88, archive_id="p0586", confidence="high"},
  {name="KNIFE NATION BLOOD ORANGE", hex="#491103", full_hex="#491103AA", r=73, g=17, b=3, pearl_name="ORANGE", pearl_id=38, archive_id="p0587", confidence="high"},
  {name="Jade Green (UK: Periklase Green)", hex="#02110E", full_hex="#02110EAA", r=2, g=17, b=14, pearl_name="silver", pearl_id=4, archive_id="p0588", confidence="high"},
  {name="Chevrolet Le Mans Blue Metallic", hex="#003B5C", full_hex="#003B5CAA", r=0, g=59, b=92, pearl_name="light blue", pearl_id=74, archive_id="p0589", confidence="high"},
  {name="the Comet RC", hex="#17829E", full_hex="#17829E00", r=23, g=130, b=158, pearl_name="no", pearl_id=28, archive_id="p0590", confidence="high"},
  {name="tone for the Elegy RH8", hex="#68817A", full_hex="#68817A00", r=104, g=129, b=122, pearl_name="Ice White", pearl_id=111, archive_id="p0591", confidence="high"},
  {name="Convertible", hex="#3E282C", full_hex="#3E282CAA", r=62, g=40, b=44, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0592", confidence="high"},
  {name="Here's my Picador in Nassau Blue Metallic", hex="#18374D", full_hex="#18374DAA", r=24, g=55, b=77, pearl_name="surf blue", pearl_id=68, archive_id="p0593", confidence="high"},
  {name="Sick Green", hex="#00E141", full_hex="#00E141AA", r=0, g=225, b=65, pearl_name="Ice White", pearl_id=111, archive_id="p0594", confidence="high"},
  {name="DG", hex="#140541", full_hex="#140541AA", r=20, g=5, b=65, pearl_name="", pearl_id=nil, archive_id="p0595", confidence="high"},
  {name="torino red Pearlescent.", hex="#000314", full_hex="#000314AA", r=0, g=3, b=20, pearl_name="Torino Red", pearl_id=28, archive_id="p0596", confidence="high"},
  {name="AGENT BLUE", hex="#000C19", full_hex="#000C19AA", r=0, g=12, b=25, pearl_name="", pearl_id=nil, archive_id="p0597", confidence="high"},
  {name="BARBARIAN BLUE", hex="#0B1019", full_hex="#0B1019AA", r=11, g=16, b=25, pearl_name="Pure Gold", pearl_id=158, archive_id="p0598", confidence="high"},
  {name="eas)", hex="#7E61C2", full_hex="#7E61C2", r=126, g=97, b=194, pearl_name="", pearl_id=nil, archive_id="p0599", confidence="high"},
  {name="WHY SO SERIOUS PINK", hex="#19000A", full_hex="#19000AAA", r=25, g=0, b=10, pearl_name="HOT PINK", pearl_id=135, archive_id="p0600", confidence="high"},
  {name="HPNOTIQ BLUE", hex="#003AFF", full_hex="#003AFF", r=0, g=58, b=255, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0601", confidence="high"},
  {name="EKLIPSE BLUE", hex="#000010", full_hex="#000010AA", r=0, g=0, b=16, pearl_name="Dark Blue", pearl_id=62, archive_id="p0602", confidence="high"},
  {name="Royal Darkness w/ Bright Green Pearl", hex="#090022", full_hex="#090022EE", r=9, g=0, b=34, pearl_name="Bright Green", pearl_id=139, archive_id="p0603", confidence="high"},
  {name="Envy Red", hex="#1D020C", full_hex="#1D020CAA", r=29, g=2, b=12, pearl_name="Torino Red", pearl_id=28, archive_id="p0604", confidence="high"},
  {name="Enjoy", hex="#13010F", full_hex="#13010FAA", r=19, g=1, b=15, pearl_name="", pearl_id=nil, archive_id="p0605", confidence="high"},
  {name="EX #", hex="#373668", full_hex="#373668", r=55, g=54, b=104, pearl_name="", pearl_id=nil, archive_id="p0606", confidence="high"},
  {name="Enjoy It.", hex="#373668", full_hex="#373668AA", r=55, g=54, b=104, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0607", confidence="high"},
  {name="FROZENGREY", hex="#3B3B45", full_hex="#3B3B45AA", r=59, g=59, b=69, pearl_name="", pearl_id=nil, archive_id="p0608", confidence="high"},
  {name="JASDF Oceanic base (Mr. Hobby C374", hex="#284157", full_hex="#284157FF", r=40, g=65, b=87, pearl_name="what", pearl_id=nil, archive_id="p0609", confidence="high"},
  {name="FS 34079 US Army/Marines Forest Green", hex="#272A22", full_hex="#272A22FF", r=39, g=42, b=34, pearl_name="Showcased in Matte with Dark Steel", pearl_id=3, archive_id="p0610", confidence="high"},
  {name="ry", hex="#5D686F", full_hex="#5D686FFF", r=93, g=104, b=111, pearl_name="Showcased in Matte with Dark Steel", pearl_id=3, archive_id="p0611", confidence="high"},
  {name="3 weeks ago", hex="#092A13", full_hex="#092A13AA", r=9, g=42, b=19, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0612", confidence="high"},
  {name="C64 Fanatic's Seven 70 Golden Mist", hex="#2B2621", full_hex="#2B2621AA", r=43, g=38, b=33, pearl_name="Cream", pearl_id=107, archive_id="p0613", confidence="high"},
  {name="cee Real 218 0813:05 AM", hex="#777A55", full_hex="#777A55FF", r=119, g=122, b=85, pearl_name="Silver", pearl_id=4, archive_id="p0614", confidence="high"},
  {name="C64 Fanatic's Double Roast Brown", hex="#140907", full_hex="#140907AA", r=20, g=9, b=7, pearl_name="", pearl_id=nil, archive_id="p0615", confidence="medium"},
  {name="BA 21913:05.AM,", hex="#A7B4C6", full_hex="#A7B4C600", r=167, g=180, b=198, pearl_name="Blue", pearl_id=64, archive_id="p0616", confidence="high"},
  {name="gtaforums.com", hex="#501629", full_hex="#501629AA", r=80, g=22, b=41, pearl_name="Steel", pearl_id=118, archive_id="p0617", confidence="high"},
  {name="C64 Fanatic's Cool Peach Orange", hex="#642D1F", full_hex="#642D1FAA", r=100, g=45, b=31, pearl_name="Dark Steel", pearl_id=3, archive_id="p0618", confidence="high"},
  {name="Kustom", hex="#5B2553", full_hex="#5B2553AA", r=91, g=37, b=83, pearl_name="Blue", pearl_id=64, archive_id="p0619", confidence="high"},
  {name="C64Fanatic's Guacamole Green", hex="#49532D", full_hex="#49532DAA", r=73, g=83, b=45, pearl_name="Silver", pearl_id=4, archive_id="p0620", confidence="high"},
  {name="Bey A S08 AM", hex="#240719", full_hex="#240719AA", r=36, g=7, b=25, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0621", confidence="high"},
  {name="132763FEF", hex="#132763", full_hex="#132763FF", r=19, g=39, b=99, pearl_name="", pearl_id=nil, archive_id="p0622", confidence="high"},
  {name="REAL-LIFE", hex="#3B3B45", full_hex="#3B3B45AA", r=59, g=59, b=69, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0623", confidence="high"},
  {name="Car : Comet Retro", hex="#030945", full_hex="#030945AA", r=3, g=9, b=69, pearl_name="LimeGreen", pearl_id=53, archive_id="p0624", confidence="high"},
  {name="Car : Obey 9F", hex="#030945", full_hex="#030945AA", r=3, g=9, b=69, pearl_name="", pearl_id=nil, archive_id="p0625", confidence="high"},
  {name="Enjoy!", hex="#1F0963", full_hex="#1F0963AA", r=31, g=9, b=99, pearl_name="ULTRA BLUE", pearl_id=70, archive_id="p0626", confidence="high"},
  {name="Zion Cabrio - G-REDDY GREEN (by xiRoNiCzZ)", hex="#000604", full_hex="#000604FF", r=0, g=6, b=4, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0627", confidence="high"},
  {name="Sk", hex="#153342", full_hex="#153342AA", r=21, g=51, b=66, pearl_name="", pearl_id=nil, archive_id="p0628", confidence="high"},
  {name="i uals", hex="#153342", full_hex="#153342AA", r=21, g=51, b=66, pearl_name="", pearl_id=nil, archive_id="p0629", confidence="high"},
  {name="It looks ultra shiny.", hex="#1A00CE", full_hex="#1A00CE", r=26, g=0, b=206, pearl_name="Hot Pink", pearl_id=135, archive_id="p0630", confidence="high"},
  {name="DOMINANT", hex="#33314F", full_hex="#33314FAA", r=51, g=49, b=79, pearl_name="Ice White", pearl_id=111, archive_id="p0631", confidence="high"},
  {name="AUTUMN - ORCHID PURPLE", hex="#2F2B3B", full_hex="#2F2B3BAA", r=47, g=43, b=59, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0632", confidence="high"},
  {name="nN", hex="#00CDFF", full_hex="#00CDFF", r=0, g=205, b=255, pearl_name="", pearl_id=nil, archive_id="p0633", confidence="medium"},
  {name="AMARANTH - #", hex="#270013", full_hex="#270013AA", r=39, g=0, b=19, pearl_name="", pearl_id=nil, archive_id="p0634", confidence="high"},
  {name="G-REDDY GREEN", hex="#000604", full_hex="#000604FF", r=0, g=6, b=4, pearl_name="", pearl_id=nil, archive_id="p0635", confidence="medium"},
  {name="ELECTRIC GREY - #", hex="#767699", full_hex="#767699FF", r=118, g=118, b=153, pearl_name="", pearl_id=nil, archive_id="p0636", confidence="high"},
  {name="CASTILLIAN", hex="#69666D", full_hex="#69666DAA", r=105, g=102, b=109, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0637", confidence="high"},
  {name="RAPID GT DARK ROSE", hex="#0E0404", full_hex="#0E0404AA", r=14, g=4, b=4, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0638", confidence="high"},
  {name="COQUETTE DEEP BLUE", hex="#12172C", full_hex="#12172CAA", r=18, g=23, b=44, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0639", confidence="high"},
  {name="FIGI GREEN", hex="#545D04", full_hex="#545D04AA", r=84, g=93, b=4, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0640", confidence="high"},
  {name="COMET SAFARI BLUE", hex="#131720", full_hex="#131720AA", r=19, g=23, b=32, pearl_name="Surf Blue", pearl_id=68, archive_id="p0641", confidence="high"},
  {name="COMET SAFARI GREEN", hex="#2C3314", full_hex="#2C3314AA", r=44, g=51, b=20, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0642", confidence="high"},
  {name="Gad &", hex="#131720", full_hex="#131720AA", r=19, g=23, b=32, pearl_name="", pearl_id=nil, archive_id="p0643", confidence="high"},
  {name="Gad &", hex="#2C3314", full_hex="#2C3314AA", r=44, g=51, b=20, pearl_name="", pearl_id=nil, archive_id="p0644", confidence="high"},
  {name="PARIAH COPPER", hex="#3F1E12", full_hex="#3F1E12AA", r=63, g=30, b=18, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0645", confidence="high"},
  {name="PARIAH ELECTRIC PINK", hex="#660033", full_hex="#660033AA", r=102, g=0, b=51, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0646", confidence="high"},
  {name="SC1 CYAN BLUE", hex="#006684", full_hex="#006684FF", r=0, g=102, b=132, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0647", confidence="high"},
  {name="SC1 TRON BLUE", hex="#00C8FF", full_hex="#00C8FF", r=0, g=200, b=255, pearl_name="", pearl_id=nil, archive_id="p0648", confidence="high"},
  {name="COIL ORANGE", hex="#FF3C00", full_hex="#FF3C00", r=255, g=60, b=0, pearl_name="", pearl_id=nil, archive_id="p0649", confidence="high"},
  {name="RAIDEN RED", hex="#300004", full_hex="#300004AA", r=48, g=0, b=4, pearl_name="Sunset Orange", pearl_id=38, archive_id="p0650", confidence="high"},
  {name="alll 44)", hex="#300004", full_hex="#300004AA", r=48, g=0, b=4, pearl_name="", pearl_id=nil, archive_id="p0651", confidence="high"},
  {name="alll 44)", hex="#FF3C00", full_hex="#FF3C00", r=255, g=60, b=0, pearl_name="", pearl_id=nil, archive_id="p0652", confidence="high"},
  {name="Se", hex="#122C3C", full_hex="#122C3CEE", r=18, g=44, b=60, pearl_name="", pearl_id=nil, archive_id="p0653", confidence="high"},
  {name="Add a public reply...", hex="#FCB479", full_hex="#FCB479", r=252, g=180, b=121, pearl_name="", pearl_id=nil, archive_id="p0654", confidence="high"},
  {name="subscribe for more video ;)", hex="#BAEFDD", full_hex="#BAEFDD00", r=186, g=239, b=221, pearl_name="Ice White", pearl_id=111, archive_id="p0655", confidence="high"},
  {name="Muscle Green", hex="#262A26", full_hex="#262A26AA", r=38, g=42, b=38, pearl_name="Cream", pearl_id=107, archive_id="p0656", confidence="high"},
  {name="Pale Green", hex="#ACFF8A", full_hex="#ACFF8A00", r=172, g=255, b=138, pearl_name="Ice White", pearl_id=111, archive_id="p0657", confidence="high"},
  {name="Muscle Green", hex="#3D3D2A", full_hex="#3D3D2AFF", r=61, g=61, b=42, pearl_name="", pearl_id=nil, archive_id="p0658", confidence="high"},
  {name="Batman Steel", hex="#0A0A0F", full_hex="#0A0A0FAA", r=10, g=10, b=15, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0659", confidence="high"},
  {name="Cool Bean", hex="#001015", full_hex="#001015AA", r=0, g=16, b=21, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0660", confidence="high"},
  {name="Gods Blue", hex="#001831", full_hex="#001831AA", r=0, g=24, b=49, pearl_name="Ice White", pearl_id=111, archive_id="p0661", confidence="high"},
  {name="Bronze Dark", hex="#242029", full_hex="#242029FF", r=36, g=32, b=41, secondary_r=36, secondary_g=32, secondary_b=41, pearl_name="Metallic Orange", pearl_id=38, archive_id="p0662", confidence="custom", is_exotic=true, exotic_preset={material=0, chameleon=5, sync_mode=true, primary_color={175, 114, 238, 255}, secondary_color={175, 114, 238, 255}, neon_color={175, 114, 238, 255}, smoke_color={175, 114, 238, 255}, headlight_color=11, pearl_id=38, pearl_aggression=73, dirt_level=0.0, modifiers={brightness=21, saturation=17, hue_shift=0, invert=false}}},
  {name="Cotton Candy Light", hex="#FFFFFF", full_hex="#FFFFFFFF", r=255, g=255, b=255, secondary_r=255, secondary_g=255, secondary_b=255, pearl_name="Metallic Black", pearl_id=0, archive_id="p0663", confidence="custom", is_exotic=true, exotic_preset={material=0, chameleon=0, sync_mode=false, primary_color={255, 255, 255, 255}, secondary_color={255, 255, 255, 255}, neon_color={255, 255, 255, 255}, smoke_color={255, 255, 255, 255}, headlight_color=8, pearl_id=0, pearl_aggression=20, dirt_level=0.0, modifiers={brightness=100, saturation=100, hue_shift=0, invert=false}}},
  {name="Green Dew", hex="#1C2609", full_hex="#1C2609FF", r=28, g=38, b=9, secondary_r=28, secondary_g=38, secondary_b=9, pearl_name="Metallic Lime", pearl_id=92, archive_id="p0664", confidence="custom", is_exotic=true, exotic_preset={material=0, chameleon=5, sync_mode=true, primary_color={188, 229, 112, 255}, secondary_color={188, 229, 112, 255}, neon_color={188, 229, 112, 255}, smoke_color={188, 229, 112, 255}, headlight_color=4, pearl_id=92, pearl_aggression=15, dirt_level=0.0, modifiers={brightness=14, saturation=86, hue_shift=0, invert=false}}},
  {name="Purple Pinkish Pearl", hex="#40395E", full_hex="#40395EFF", r=64, g=57, b=94, secondary_r=64, secondary_g=57, secondary_b=94, pearl_name="Metallic Orange", pearl_id=38, archive_id="p0665", confidence="custom", is_exotic=true, exotic_preset={material=2, chameleon=5, sync_mode=true, primary_color={110, 93, 184, 255}, secondary_color={110, 93, 184, 255}, neon_color={110, 93, 184, 255}, smoke_color={110, 93, 184, 255}, headlight_color=11, pearl_id=38, pearl_aggression=93, dirt_level=0.0, modifiers={brightness=55, saturation=62, hue_shift=0, invert=false}}},
  {name="Purple Sunset Light", hex="#2A2A43", full_hex="#2A2A43FF", r=42, g=42, b=67, secondary_r=42, secondary_g=42, secondary_b=67, pearl_name="Metallic Orange", pearl_id=38, archive_id="p0666", confidence="custom", is_exotic=true, exotic_preset={material=2, chameleon=8, sync_mode=true, primary_color={183, 183, 224, 255}, secondary_color={183, 183, 224, 255}, neon_color={183, 183, 224, 255}, smoke_color={183, 183, 224, 255}, headlight_color=1, pearl_id=38, pearl_aggression=91, dirt_level=0.0, modifiers={brightness=27, saturation=59, hue_shift=0, invert=false}}},
  {name="Purple Sunset Red", hex="#130627", full_hex="#130627FF", r=19, g=6, b=39, secondary_r=19, secondary_g=6, secondary_b=39, pearl_name="Metallic Torino Red", pearl_id=28, archive_id="p0667", confidence="custom", is_exotic=true, exotic_preset={material=1, chameleon=5, sync_mode=true, primary_color={87, 14, 206, 255}, secondary_color={87, 14, 206, 255}, neon_color={87, 14, 206, 255}, smoke_color={87, 14, 206, 255}, headlight_color=11, pearl_id=28, pearl_aggression=66, dirt_level=0.0, modifiers={brightness=21, saturation=81, hue_shift=0, invert=false}}},
  {name="Sunset Purple Red Pearl", hex="#140718", full_hex="#140718FF", r=20, g=7, b=24, secondary_r=20, secondary_g=7, secondary_b=24, pearl_name="Util Garnet Red", pearl_id=45, archive_id="p0668", confidence="custom", is_exotic=true, exotic_preset={material=3, chameleon=0, sync_mode=true, primary_color={100, 15, 128, 255}, secondary_color={100, 15, 128, 255}, neon_color={100, 15, 128, 255}, smoke_color={100, 15, 128, 255}, headlight_color=12, pearl_id=45, pearl_aggression=84, dirt_level=0.0, modifiers={brightness=22, saturation=70, hue_shift=0, invert=false}}},
  {name="Ai Radioactive Merlot", hex="#26000D", full_hex="#26000DAA", r=38, g=0, b=13, pearl_name="Bright Green", pearl_id=139, archive_id="p0669", confidence="high", is_ai=true},
  {name="Ai Toxic Velvet", hex="#2B0037", full_hex="#2B0037AA", r=43, g=0, b=55, pearl_name="Lime Green", pearl_id=92, archive_id="p0670", confidence="high", is_ai=true},
  {name="Ai Funeral Mango", hex="#171005", full_hex="#171005AA", r=23, g=16, b=5, pearl_name="Hot Pink", pearl_id=135, archive_id="p0671", confidence="high", is_ai=true},
  {name="Ai Bruised Citrus", hex="#311700", full_hex="#311700AA", r=49, g=23, b=0, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0672", confidence="high", is_ai=true},
  {name="Ai Swamp Candy", hex="#0D2817", full_hex="#0D2817AA", r=13, g=40, b=23, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0673", confidence="high", is_ai=true},
  {name="Ai Petrol Valentine", hex="#03282A", full_hex="#03282AAA", r=3, g=40, b=42, pearl_name="Candy Red", pearl_id=35, archive_id="p0674", confidence="high", is_ai=true},
  {name="Ai Blue Cheese Gold", hex="#15263A", full_hex="#15263AAA", r=21, g=38, b=58, pearl_name="Pure Gold", pearl_id=158, archive_id="p0675", confidence="high", is_ai=true},
  {name="Ai Crimson Aquarium", hex="#3A0008", full_hex="#3A0008AA", r=58, g=0, b=8, pearl_name="Surf Blue", pearl_id=68, archive_id="p0676", confidence="high", is_ai=true},
  {name="Ai Orchid Hazard", hex="#421044", full_hex="#421044AA", r=66, g=16, b=68, pearl_name="Race Yellow", pearl_id=89, archive_id="p0677", confidence="high", is_ai=true},
  {name="Ai Moss Disco", hex="#14220C", full_hex="#14220CAA", r=20, g=34, b=12, pearl_name="Bright Purple", pearl_id=145, archive_id="p0678", confidence="high", is_ai=true},
  {name="Ai Rotten Peach Ice", hex="#5C2F20", full_hex="#5C2F20AA", r=92, g=47, b=32, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0679", confidence="high", is_ai=true},
  {name="Ai Burgundy Alien", hex="#310513", full_hex="#310513AA", r=49, g=5, b=19, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0680", confidence="high", is_ai=true},
  {name="Ai Navy Mustard", hex="#050F31", full_hex="#050F31AA", r=5, g=15, b=49, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0681", confidence="high", is_ai=true},
  {name="Ai Eggplant Chrome", hex="#260C32", full_hex="#260C32AA", r=38, g=12, b=50, pearl_name="Frost White", pearl_id=112, archive_id="p0682", confidence="high", is_ai=true},
  {name="Ai Coal Bubblegum", hex="#09080D", full_hex="#09080DAA", r=9, g=8, b=13, pearl_name="Hot Pink", pearl_id=135, archive_id="p0683", confidence="high", is_ai=true},
  {name="Ai Cola Laser", hex="#24120F", full_hex="#24120FAA", r=36, g=18, b=15, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0684", confidence="high", is_ai=true},
  {name="Ai Rust Plasma", hex="#4B1A07", full_hex="#4B1A07AA", r=75, g=26, b=7, pearl_name="Bright Green", pearl_id=139, archive_id="p0685", confidence="high", is_ai=true},
  {name="Ai Aubergine Sunrise", hex="#19001D", full_hex="#19001DAA", r=25, g=0, b=29, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0686", confidence="high", is_ai=true},
  {name="Ai Forest Lipstick", hex="#061D0A", full_hex="#061D0AAA", r=6, g=29, b=10, pearl_name="Torino Red", pearl_id=28, archive_id="p0687", confidence="high", is_ai=true},
  {name="Ai Teal Blood", hex="#00272C", full_hex="#00272CAA", r=0, g=39, b=44, pearl_name="Formula Red", pearl_id=29, archive_id="p0688", confidence="high", is_ai=true},
  {name="Ai Neon Bruise", hex="#7D00FF", full_hex="#7D00FFAA", r=125, g=0, b=255, pearl_name="Bright Orange", pearl_id=138, archive_id="p0689", confidence="high", is_ai=true},
  {name="Ai Acid Lavender", hex="#B789FF", full_hex="#B789FFAA", r=183, g=137, b=255, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0690", confidence="high", is_ai=true},
  {name="Ai Barbie Slime", hex="#FF52B8", full_hex="#FF52B8AA", r=255, g=82, b=184, pearl_name="Lime Green", pearl_id=92, archive_id="p0691", confidence="high", is_ai=true},
  {name="Ai Cyan Ketchup", hex="#00C7D9", full_hex="#00C7D9AA", r=0, g=199, b=217, pearl_name="Torino Red", pearl_id=28, archive_id="p0692", confidence="high", is_ai=true},
  {name="Ai Lemon Abyss", hex="#F1FF19", full_hex="#F1FF19AA", r=241, g=255, b=25, pearl_name="Bright Purple", pearl_id=145, archive_id="p0693", confidence="high", is_ai=true},
  {name="Ai Orange Deepfreeze", hex="#FF7208", full_hex="#FF7208AA", r=255, g=114, b=8, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0694", confidence="high", is_ai=true},
  {name="Ai Green Champagne", hex="#58FF6A", full_hex="#58FF6AAA", r=88, g=255, b=106, pearl_name="Pure Gold", pearl_id=158, archive_id="p0695", confidence="high", is_ai=true},
  {name="Ai Blue Wasabi", hex="#1F65FF", full_hex="#1F65FFAA", r=31, g=101, b=255, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0696", confidence="high", is_ai=true},
  {name="Ai Magenta Mint", hex="#FF17B8", full_hex="#FF17B8AA", r=255, g=23, b=184, pearl_name="Sea Green", pearl_id=51, archive_id="p0697", confidence="high", is_ai=true},
  {name="Ai Coral Electricity", hex="#FF5D66", full_hex="#FF5D66AA", r=255, g=93, b=102, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0698", confidence="high", is_ai=true},
  {name="Ai Toxic Creamsicle", hex="#DFFF6B", full_hex="#DFFF6BAA", r=223, g=255, b=107, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0699", confidence="high", is_ai=true},
  {name="Ai Grape Safety Vest", hex="#7226D9", full_hex="#7226D9AA", r=114, g=38, b=217, pearl_name="Race Yellow", pearl_id=89, archive_id="p0700", confidence="high", is_ai=true},
  {name="Ai Electric Mud", hex="#755C20", full_hex="#755C20AA", r=117, g=92, b=32, pearl_name="Hot Pink", pearl_id=135, archive_id="p0701", confidence="high", is_ai=true},
  {name="Ai Aqua Inferno", hex="#2BFFE5", full_hex="#2BFFE5AA", r=43, g=255, b=229, pearl_name="Candy Red", pearl_id=35, archive_id="p0702", confidence="high", is_ai=true},
  {name="Ai Cherry Antifreeze", hex="#E51B4D", full_hex="#E51B4DAA", r=229, g=27, b=77, pearl_name="Bright Green", pearl_id=139, archive_id="p0703", confidence="high", is_ai=true},
  {name="Ai Violet Construction", hex="#9B41FF", full_hex="#9B41FFAA", r=155, g=65, b=255, pearl_name="Bright Orange", pearl_id=138, archive_id="p0704", confidence="high", is_ai=true},
  {name="Ai Mint Murder", hex="#73FFB0", full_hex="#73FFB0AA", r=115, g=255, b=176, pearl_name="Formula Red", pearl_id=29, archive_id="p0705", confidence="high", is_ai=true},
  {name="Ai Peach Reactor", hex="#FFAD7B", full_hex="#FFAD7BAA", r=255, g=173, b=123, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0706", confidence="high", is_ai=true},
  {name="Ai Sky Venom", hex="#68CFFF", full_hex="#68CFFFAA", r=104, g=207, b=255, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0707", confidence="high", is_ai=true},
  {name="Ai Banana Blacklight", hex="#FFE65B", full_hex="#FFE65BAA", r=255, g=230, b=91, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0708", confidence="high", is_ai=true},
  {name="Ai Powder Blue Blood", hex="#A8DFFF", full_hex="#A8DFFFAA", r=168, g=223, b=255, pearl_name="Torino Red", pearl_id=28, archive_id="p0709", confidence="high", is_ai=true},
  {name="Ai Rose Radiation", hex="#FF9BC8", full_hex="#FF9BC8AA", r=255, g=155, b=200, pearl_name="Lime Green", pearl_id=92, archive_id="p0710", confidence="high", is_ai=true},
  {name="Ai Lilac Gasoline", hex="#D0A8FF", full_hex="#D0A8FFAA", r=208, g=168, b=255, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0711", confidence="high", is_ai=true},
  {name="Ai Cream Ultraviolet", hex="#FFF1C9", full_hex="#FFF1C9AA", r=255, g=241, b=201, pearl_name="Bright Purple", pearl_id=145, archive_id="p0712", confidence="high", is_ai=true},
  {name="Ai Minted Gold Crime", hex="#BFFFF0", full_hex="#BFFFF0AA", r=191, g=255, b=240, pearl_name="Pure Gold", pearl_id=158, archive_id="p0713", confidence="high", is_ai=true},
  {name="Ai Baby Blue Lava", hex="#B8ECFF", full_hex="#B8ECFFAA", r=184, g=236, b=255, pearl_name="Bright Orange", pearl_id=138, archive_id="p0714", confidence="high", is_ai=true},
  {name="Ai Blush Toxicity", hex="#FFD0D8", full_hex="#FFD0D8AA", r=255, g=208, b=216, pearl_name="Bright Green", pearl_id=139, archive_id="p0715", confidence="high", is_ai=true},
  {name="Ai Buttercup Bruise", hex="#FFEFA1", full_hex="#FFEFA1AA", r=255, g=239, b=161, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0716", confidence="high", is_ai=true},
  {name="Ai Pale Sage Candy", hex="#C9D8B2", full_hex="#C9D8B2AA", r=201, g=216, b=178, pearl_name="Hot Pink", pearl_id=135, archive_id="p0717", confidence="high", is_ai=true},
  {name="Ai Cloud Redline", hex="#EAF4FF", full_hex="#EAF4FFAA", r=234, g=244, b=255, pearl_name="Candy Red", pearl_id=35, archive_id="p0718", confidence="high", is_ai=true},
  {name="Ai Desert Ultraviolet", hex="#8A6A3D", full_hex="#8A6A3DAA", r=138, g=106, b=61, pearl_name="Bright Purple", pearl_id=145, archive_id="p0719", confidence="high", is_ai=true},
  {name="Ai Muddy Laser", hex="#4A4028", full_hex="#4A4028AA", r=74, g=64, b=40, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0720", confidence="high", is_ai=true},
  {name="Ai Olive Bubblegum", hex="#394217", full_hex="#394217AA", r=57, g=66, b=23, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0721", confidence="high", is_ai=true},
  {name="Ai Clay Ice", hex="#6A3A29", full_hex="#6A3A29AA", r=106, g=58, b=41, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0722", confidence="high", is_ai=true},
  {name="Ai Tobacco Cyan", hex="#493124", full_hex="#493124AA", r=73, g=49, b=36, pearl_name="Surf Blue", pearl_id=68, archive_id="p0723", confidence="high", is_ai=true},
  {name="Ai Army Valentine", hex="#303A20", full_hex="#303A20AA", r=48, g=58, b=32, pearl_name="Hot Pink", pearl_id=135, archive_id="p0724", confidence="high", is_ai=true},
  {name="Ai Sandstorm Poison", hex="#806A43", full_hex="#806A43AA", r=128, g=106, b=67, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0725", confidence="high", is_ai=true},
  {name="Ai Copper Aquarium", hex="#7A391D", full_hex="#7A391DAA", r=122, g=57, b=29, pearl_name="Light Blue", pearl_id=74, archive_id="p0726", confidence="high", is_ai=true},
  {name="Ai Coffee Lime", hex="#2B1B12", full_hex="#2B1B12AA", r=43, g=27, b=18, pearl_name="Lime Green", pearl_id=92, archive_id="p0727", confidence="high", is_ai=true},
  {name="Ai Khaki Candy", hex="#635C39", full_hex="#635C39AA", r=99, g=92, b=57, pearl_name="Candy Red", pearl_id=35, archive_id="p0728", confidence="high", is_ai=true},
  {name="Ai Bronze Raspberry", hex="#6B3B18", full_hex="#6B3B18AA", r=107, g=59, b=24, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0729", confidence="high", is_ai=true},
  {name="Ai Moss Sunrise", hex="#273218", full_hex="#273218AA", r=39, g=50, b=24, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0730", confidence="high", is_ai=true},
  {name="Ai Concrete Pink", hex="#4F5354", full_hex="#4F5354AA", r=79, g=83, b=84, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0731", confidence="high", is_ai=true},
  {name="Ai Asphalt Gold", hex="#1C1F22", full_hex="#1C1F22AA", r=28, g=31, b=34, pearl_name="Pure Gold", pearl_id=158, archive_id="p0732", confidence="high", is_ai=true},
  {name="Ai Gunmetal Citrus", hex="#252A31", full_hex="#252A31AA", r=37, g=42, b=49, pearl_name="Race Yellow", pearl_id=89, archive_id="p0733", confidence="high", is_ai=true},
  {name="Ai Silver Venom", hex="#9DA5AA", full_hex="#9DA5AAAA", r=157, g=165, b=170, pearl_name="Bright Green", pearl_id=139, archive_id="p0734", confidence="high", is_ai=true},
  {name="Ai Graphite Candy", hex="#34333C", full_hex="#34333CAA", r=52, g=51, b=60, pearl_name="Hot Pink", pearl_id=135, archive_id="p0735", confidence="high", is_ai=true},
  {name="Ai Pewter Flame", hex="#777B80", full_hex="#777B80AA", r=119, g=123, b=128, pearl_name="Bright Orange", pearl_id=138, archive_id="p0736", confidence="high", is_ai=true},
  {name="Ai Smoke Purple", hex="#55545E", full_hex="#55545EAA", r=85, g=84, b=94, pearl_name="Bright Purple", pearl_id=145, archive_id="p0737", confidence="high", is_ai=true},
  {name="Ai Steel Blood", hex="#636A73", full_hex="#636A73AA", r=99, g=106, b=115, pearl_name="Torino Red", pearl_id=28, archive_id="p0738", confidence="high", is_ai=true},
  {name="Ai Frozen Tomato", hex="#D8F2F4", full_hex="#D8F2F4AA", r=216, g=242, b=244, pearl_name="Formula Red", pearl_id=29, archive_id="p0739", confidence="high", is_ai=true},
  {name="Ai Arctic Mango", hex="#D9F8FF", full_hex="#D9F8FFAA", r=217, g=248, b=255, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0740", confidence="high", is_ai=true},
  {name="Ai Glacier Grape", hex="#C6E8FF", full_hex="#C6E8FFAA", r=198, g=232, b=255, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0741", confidence="high", is_ai=true},
  {name="Ai Snow Slime", hex="#F7FFFF", full_hex="#F7FFFFAA", r=247, g=255, b=255, pearl_name="Lime Green", pearl_id=92, archive_id="p0742", confidence="high", is_ai=true},
  {name="Ai Iceberg Candy", hex="#D3F7F2", full_hex="#D3F7F2AA", r=211, g=247, b=242, pearl_name="Hot Pink", pearl_id=135, archive_id="p0743", confidence="high", is_ai=true},
  {name="Ai Frosted Blood Orange", hex="#EEF5FF", full_hex="#EEF5FFAA", r=238, g=245, b=255, pearl_name="Bright Orange", pearl_id=138, archive_id="p0744", confidence="high", is_ai=true},
  {name="Ai White Gasoline", hex="#FDFDF7", full_hex="#FDFDF7AA", r=253, g=253, b=247, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0745", confidence="high", is_ai=true},
  {name="Ai Ivory Ultra", hex="#FFF8E7", full_hex="#FFF8E7AA", r=255, g=248, b=231, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0746", confidence="high", is_ai=true},
  {name="Ai Pearl Venom", hex="#F1EEE4", full_hex="#F1EEE4AA", r=241, g=238, b=228, pearl_name="Bright Green", pearl_id=139, archive_id="p0747", confidence="high", is_ai=true},
  {name="Ai Milkshake Redline", hex="#FFF4F6", full_hex="#FFF4F6AA", r=255, g=244, b=246, pearl_name="Torino Red", pearl_id=28, archive_id="p0748", confidence="high", is_ai=true},
  {name="Ai Black Banana", hex="#030303", full_hex="#030303AA", r=3, g=3, b=3, pearl_name="Race Yellow", pearl_id=89, archive_id="p0749", confidence="high", is_ai=true},
  {name="Ai Void Bubblegum", hex="#050207", full_hex="#050207AA", r=5, g=2, b=7, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0750", confidence="high", is_ai=true},
  {name="Ai Obsidian Slime", hex="#040605", full_hex="#040605AA", r=4, g=6, b=5, pearl_name="Lime Green", pearl_id=92, archive_id="p0751", confidence="high", is_ai=true},
  {name="Ai Carbon Candy", hex="#07090C", full_hex="#07090CAA", r=7, g=9, b=12, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0752", confidence="high", is_ai=true},
  {name="Ai Blacklight Mango", hex="#09030E", full_hex="#09030EAA", r=9, g=3, b=14, pearl_name="Bright Orange", pearl_id=138, archive_id="p0753", confidence="high", is_ai=true},
  {name="Ai Funeral Cyan", hex="#02080A", full_hex="#02080AAA", r=2, g=8, b=10, pearl_name="Surf Blue", pearl_id=68, archive_id="p0754", confidence="high", is_ai=true},
  {name="Ai Midnight Lemon", hex="#05060B", full_hex="#05060BAA", r=5, g=6, b=11, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0755", confidence="high", is_ai=true},
  {name="Ai Ink Gold", hex="#04030A", full_hex="#04030AAA", r=4, g=3, b=10, pearl_name="Pure Gold", pearl_id=158, archive_id="p0756", confidence="high", is_ai=true},
  {name="Ai Black Cherry Ice", hex="#0C0306", full_hex="#0C0306AA", r=12, g=3, b=6, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0757", confidence="high", is_ai=true},
  {name="Ai Void Gasoline", hex="#030506", full_hex="#030506AA", r=3, g=5, b=6, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0758", confidence="high", is_ai=true},
  {name="Ai Ultraviolet Pickle", hex="#3A005B", full_hex="#3A005BAA", r=58, g=0, b=91, pearl_name="Sea Green", pearl_id=51, archive_id="p0759", confidence="high", is_ai=true},
  {name="Ai Radioactive Cabernet", hex="#4D0014", full_hex="#4D0014AA", r=77, g=0, b=20, pearl_name="Lime Green", pearl_id=92, archive_id="p0760", confidence="high", is_ai=true},
  {name="Ai Teal Bubblegum", hex="#003D3A", full_hex="#003D3AAA", r=0, g=61, b=58, pearl_name="Hot Pink", pearl_id=135, archive_id="p0761", confidence="high", is_ai=true},
  {name="Ai Pumpkin Deepsea", hex="#7C2600", full_hex="#7C2600AA", r=124, g=38, b=0, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0762", confidence="high", is_ai=true},
  {name="Ai Mustard Nebula", hex="#665100", full_hex="#665100AA", r=102, g=81, b=0, pearl_name="Bright Purple", pearl_id=145, archive_id="p0763", confidence="high", is_ai=true},
  {name="Ai Blue Hot Sauce", hex="#001A66", full_hex="#001A66AA", r=0, g=26, b=102, pearl_name="Bright Orange", pearl_id=138, archive_id="p0764", confidence="high", is_ai=true},
  {name="Ai Magenta Swamp", hex="#65003C", full_hex="#65003CAA", r=101, g=0, b=60, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0765", confidence="high", is_ai=true},
  {name="Ai Green Lip Gloss", hex="#08471A", full_hex="#08471AAA", r=8, g=71, b=26, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0766", confidence="high", is_ai=true},
  {name="Ai Red Aquarium Gold", hex="#65000A", full_hex="#65000AAA", r=101, g=0, b=10, pearl_name="Pure Gold", pearl_id=158, archive_id="p0767", confidence="high", is_ai=true},
  {name="Ai Cyan Funeral Rose", hex="#00444D", full_hex="#00444DAA", r=0, g=68, b=77, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0768", confidence="high", is_ai=true},
}
_G.GTA_PAINTJOB_LIBRARY = archiveLibrary

-- register-safe ai append block
-- note: keep large generated sets as individual assignments to avoid lua register exhaustion.
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Venom", hex="#3A0C1C", full_hex="#3A0C1CAA", r=58, g=12, b=28, pearl_name="Bright Green", pearl_id=139, archive_id="p0769", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Reactor", hex="#1E0805", full_hex="#1E0805AA", r=30, g=8, b=5, pearl_name="Pure Gold", pearl_id=158, archive_id="p0770", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Fuel", hex="#500215", full_hex="#500215AA", r=80, g=2, b=21, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0771", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Pickle", hex="#521811", full_hex="#521811AA", r=82, g=24, b=17, pearl_name="Lime Green", pearl_id=92, archive_id="p0772", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Poison", hex="#6A0806", full_hex="#6A0806AA", r=106, g=8, b=6, pearl_name="Frost White", pearl_id=112, archive_id="p0773", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Venom 2", hex="#4D150B", full_hex="#4D150BAA", r=77, g=21, b=11, pearl_name="Bright Green", pearl_id=139, archive_id="p0774", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Velvet Blue", hex="#37030A", full_hex="#37030AAA", r=55, g=3, b=10, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0775", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Venom", hex="#39040C", full_hex="#39040CAA", r=57, g=4, b=12, pearl_name="Bright Green", pearl_id=139, archive_id="p0776", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Burgundy Venom", hex="#4C1218", full_hex="#4C1218AA", r=76, g=18, b=24, pearl_name="Sea Green", pearl_id=51, archive_id="p0777", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Fuel 2", hex="#480D13", full_hex="#480D13AA", r=72, g=13, b=19, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0778", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Mint", hex="#360111", full_hex="#360111AA", r=54, g=1, b=17, pearl_name="Sea Green", pearl_id=51, archive_id="p0779", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Merlot Venom", hex="#2B030A", full_hex="#2B030AAA", r=43, g=3, b=10, pearl_name="Bright Green", pearl_id=139, archive_id="p0780", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Merlot Foam", hex="#541207", full_hex="#541207AA", r=84, g=18, b=7, pearl_name="Pure Gold", pearl_id=158, archive_id="p0781", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Blood Surf", hex="#4C0D08", full_hex="#4C0D08AA", r=76, g=13, b=8, pearl_name="Surf Blue", pearl_id=68, archive_id="p0782", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Velvet Venom", hex="#510E15", full_hex="#510E15AA", r=81, g=14, b=21, pearl_name="Bright Green", pearl_id=139, archive_id="p0783", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Fuel", hex="#75021A", full_hex="#75021AAA", r=117, g=2, b=26, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0784", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Venom", hex="#490A09", full_hex="#490A09AA", r=73, g=10, b=9, pearl_name="Bright Green", pearl_id=139, archive_id="p0785", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Lime", hex="#250203", full_hex="#250203AA", r=37, g=2, b=3, pearl_name="Lime Green", pearl_id=92, archive_id="p0786", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cabernet Static", hex="#3D150D", full_hex="#3D150DAA", r=61, g=21, b=13, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0787", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Blood Gold", hex="#430501", full_hex="#430501AA", r=67, g=5, b=1, pearl_name="Pure Gold", pearl_id=158, archive_id="p0788", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Frost", hex="#68180C", full_hex="#68180CAA", r=104, g=24, b=12, pearl_name="Frost White", pearl_id=112, archive_id="p0789", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Venom 2", hex="#48060B", full_hex="#48060BAA", r=72, g=6, b=11, pearl_name="Bright Green", pearl_id=139, archive_id="p0790", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Blood Mint", hex="#390516", full_hex="#390516AA", r=57, g=5, b=22, pearl_name="Sea Green", pearl_id=51, archive_id="p0791", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Merlot Mint", hex="#21040E", full_hex="#21040EAA", r=33, g=4, b=14, pearl_name="Sea Green", pearl_id=51, archive_id="p0792", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Burgundy Blue", hex="#581613", full_hex="#581613AA", r=88, g=22, b=19, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0793", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cabernet Glitch", hex="#4D0315", full_hex="#4D0315AA", r=77, g=3, b=21, pearl_name="Pure Gold", pearl_id=158, archive_id="p0794", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Frost 2", hex="#310907", full_hex="#310907AA", r=49, g=9, b=7, pearl_name="Frost White", pearl_id=112, archive_id="p0795", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Glitch", hex="#3B0F07", full_hex="#3B0F07AA", r=59, g=15, b=7, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0796", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Mirage", hex="#1E060A", full_hex="#1E060AAA", r=30, g=6, b=10, pearl_name="Frost White", pearl_id=112, archive_id="p0797", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Merlot Static", hex="#240401", full_hex="#240401AA", r=36, g=4, b=1, pearl_name="Surf Blue", pearl_id=68, archive_id="p0798", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Lime 2", hex="#441020", full_hex="#441020AA", r=68, g=16, b=32, pearl_name="Lime Green", pearl_id=92, archive_id="p0799", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Garnet Ice", hex="#200702", full_hex="#200702AA", r=32, g=7, b=2, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0800", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Mirage 2", hex="#4A0D01", full_hex="#4A0D01AA", r=74, g=13, b=1, pearl_name="Sea Green", pearl_id=51, archive_id="p0801", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Garnet Laser", hex="#330D06", full_hex="#330D06AA", r=51, g=13, b=6, pearl_name="Pure Gold", pearl_id=158, archive_id="p0802", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Slime", hex="#661A0F", full_hex="#661A0FAA", r=102, g=26, b=15, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0803", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Mint", hex="#641317", full_hex="#641317AA", r=100, g=19, b=23, pearl_name="Sea Green", pearl_id=51, archive_id="p0804", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Burgundy Mirage", hex="#27070E", full_hex="#27070EAA", r=39, g=7, b=14, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0805", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Garnet Aquarium", hex="#420602", full_hex="#420602AA", r=66, g=6, b=2, pearl_name="Surf Blue", pearl_id=68, archive_id="p0806", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Garnet Frost", hex="#651C0F", full_hex="#651C0FAA", r=101, g=28, b=15, pearl_name="Frost White", pearl_id=112, archive_id="p0807", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cabernet Lime", hex="#39080C", full_hex="#39080CAA", r=57, g=8, b=12, pearl_name="Lime Green", pearl_id=92, archive_id="p0808", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Lime", hex="#320310", full_hex="#320310AA", r=50, g=3, b=16, pearl_name="Lime Green", pearl_id=92, archive_id="p0809", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Laser", hex="#22030D", full_hex="#22030DAA", r=34, g=3, b=13, pearl_name="Pure Gold", pearl_id=158, archive_id="p0810", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Fuel", hex="#59051F", full_hex="#59051FAA", r=89, g=5, b=31, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0811", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cherry Ice", hex="#570E09", full_hex="#570E09AA", r=87, g=14, b=9, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0812", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Venom", hex="#53111F", full_hex="#53111FAA", r=83, g=17, b=31, pearl_name="Bright Green", pearl_id=139, archive_id="p0813", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Blood Ice", hex="#5E0D25", full_hex="#5E0D25AA", r=94, g=13, b=37, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0814", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Pickle", hex="#310612", full_hex="#310612AA", r=49, g=6, b=18, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0815", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rosewood Laser", hex="#1B0805", full_hex="#1B0805AA", r=27, g=8, b=5, pearl_name="Pure Gold", pearl_id=158, archive_id="p0816", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Crimson Aquarium 2", hex="#531B14", full_hex="#531B14AA", r=83, g=27, b=20, pearl_name="Frost White", pearl_id=112, archive_id="p0817", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Maroon Gold", hex="#600C1E", full_hex="#600C1EAA", r=96, g=12, b=30, pearl_name="Pure Gold", pearl_id=158, archive_id="p0818", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plum Lime", hex="#65175F", full_hex="#65175FAA", r=101, g=23, b=95, pearl_name="Lime Green", pearl_id=92, archive_id="p0819", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Gold", hex="#74064D", full_hex="#74064DAA", r=116, g=6, b=77, pearl_name="Pure Gold", pearl_id=158, archive_id="p0820", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Taxi", hex="#2D0724", full_hex="#2D0724AA", r=45, g=7, b=36, pearl_name="Race Yellow", pearl_id=89, archive_id="p0821", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Taxi", hex="#27082D", full_hex="#27082DAA", r=39, g=8, b=45, pearl_name="Race Yellow", pearl_id=89, archive_id="p0822", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Violet Static", hex="#500944", full_hex="#500944AA", r=80, g=9, b=68, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0823", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Sunrise", hex="#671254", full_hex="#671254AA", r=103, g=18, b=84, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0824", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Violet Taxi", hex="#2F0F48", full_hex="#2F0F48AA", r=47, g=15, b=72, pearl_name="Race Yellow", pearl_id=89, archive_id="p0825", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Goldrush", hex="#6C0C57", full_hex="#6C0C57AA", r=108, g=12, b=87, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0826", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Gold", hex="#3A0236", full_hex="#3A0236AA", r=58, g=2, b=54, pearl_name="Pure Gold", pearl_id=158, archive_id="p0827", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Dew", hex="#361045", full_hex="#361045AA", r=54, g=16, b=69, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0828", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Gold", hex="#31042E", full_hex="#31042EAA", r=49, g=4, b=46, pearl_name="Pure Gold", pearl_id=158, archive_id="p0829", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plum Taxi", hex="#490537", full_hex="#490537AA", r=73, g=5, b=55, pearl_name="Race Yellow", pearl_id=89, archive_id="p0830", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Dew 2", hex="#3A0D32", full_hex="#3A0D32AA", r=58, g=13, b=50, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0831", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Dew", hex="#340327", full_hex="#340327AA", r=52, g=3, b=39, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0832", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Lemonade", hex="#1D022D", full_hex="#1D022DAA", r=29, g=2, b=45, pearl_name="Bright Orange", pearl_id=138, archive_id="p0833", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Sunrise", hex="#5A1567", full_hex="#5A1567AA", r=90, g=21, b=103, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0834", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Sunrise 2", hex="#3B1658", full_hex="#3B1658AA", r=59, g=22, b=88, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0835", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Radio", hex="#661342", full_hex="#661342AA", r=102, g=19, b=66, pearl_name="Pure Gold", pearl_id=158, archive_id="p0836", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plum Mint", hex="#39024C", full_hex="#39024CAA", r=57, g=2, b=76, pearl_name="Sea Green", pearl_id=51, archive_id="p0837", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Lime", hex="#461B5F", full_hex="#461B5FAA", r=70, g=27, b=95, pearl_name="Lime Green", pearl_id=92, archive_id="p0838", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mauve Pickle", hex="#51085C", full_hex="#51085CAA", r=81, g=8, b=92, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0839", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Nebula Mint", hex="#4F0430", full_hex="#4F0430AA", r=79, g=4, b=48, pearl_name="Sea Green", pearl_id=51, archive_id="p0840", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mauve Static", hex="#2D0F3C", full_hex="#2D0F3CAA", r=45, g=15, b=60, pearl_name="Lime Green", pearl_id=92, archive_id="p0841", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Goldrush", hex="#2A0645", full_hex="#2A0645AA", r=42, g=6, b=69, pearl_name="Bright Orange", pearl_id=138, archive_id="p0842", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plum Pickle", hex="#511739", full_hex="#511739AA", r=81, g=23, b=57, pearl_name="Pure Gold", pearl_id=158, archive_id="p0843", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Mold", hex="#2A0A43", full_hex="#2A0A43AA", r=42, g=10, b=67, pearl_name="Bright Orange", pearl_id=138, archive_id="p0844", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Beacon", hex="#4B1132", full_hex="#4B1132AA", r=75, g=17, b=50, pearl_name="Lime Green", pearl_id=92, archive_id="p0845", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Lime", hex="#340C41", full_hex="#340C41AA", r=52, g=12, b=65, pearl_name="Lime Green", pearl_id=92, archive_id="p0846", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Taxi", hex="#5E0F40", full_hex="#5E0F40AA", r=94, g=15, b=64, pearl_name="Race Yellow", pearl_id=89, archive_id="p0847", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Nebula Mint 2", hex="#33063E", full_hex="#33063EAA", r=51, g=6, b=62, pearl_name="Sea Green", pearl_id=51, archive_id="p0848", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Sunrise 2", hex="#300937", full_hex="#300937AA", r=48, g=9, b=55, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0849", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Lemonade", hex="#36072B", full_hex="#36072BAA", r=54, g=7, b=43, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0850", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Lime 2", hex="#3E0F41", full_hex="#3E0F41AA", r=62, g=15, b=65, pearl_name="Lime Green", pearl_id=92, archive_id="p0851", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Static", hex="#3A0D28", full_hex="#3A0D28AA", r=58, g=13, b=40, pearl_name="Sea Green", pearl_id=51, archive_id="p0852", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Violet Gold", hex="#37063A", full_hex="#37063AAA", r=55, g=6, b=58, pearl_name="Pure Gold", pearl_id=158, archive_id="p0853", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Nebula Dew", hex="#661A53", full_hex="#661A53AA", r=102, g=26, b=83, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0854", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Mint", hex="#421464", full_hex="#421464AA", r=66, g=20, b=100, pearl_name="Sea Green", pearl_id=51, archive_id="p0855", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Radio", hex="#2D041A", full_hex="#2D041AAA", r=45, g=4, b=26, pearl_name="Race Yellow", pearl_id=89, archive_id="p0856", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Mint", hex="#400355", full_hex="#400355AA", r=64, g=3, b=85, pearl_name="Sea Green", pearl_id=51, archive_id="p0857", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Goldrush 2", hex="#440A71", full_hex="#440A71AA", r=68, g=10, b=113, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0858", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Lime 2", hex="#3F024C", full_hex="#3F024CAA", r=63, g=2, b=76, pearl_name="Lime Green", pearl_id=92, archive_id="p0859", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Lemonade", hex="#421140", full_hex="#421140AA", r=66, g=17, b=64, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0860", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mauve Gold", hex="#2D0240", full_hex="#2D0240AA", r=45, g=2, b=64, pearl_name="Pure Gold", pearl_id=158, archive_id="p0861", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plum Lemonade", hex="#5D065E", full_hex="#5D065EAA", r=93, g=6, b=94, pearl_name="Sea Green", pearl_id=51, archive_id="p0862", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Dew", hex="#55116E", full_hex="#55116EAA", r=85, g=17, b=110, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0863", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Dew", hex="#440554", full_hex="#440554AA", r=68, g=5, b=84, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0864", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Taxi", hex="#3E033C", full_hex="#3E033CAA", r=62, g=3, b=60, pearl_name="Race Yellow", pearl_id=89, archive_id="p0865", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aubergine Sunrise 2", hex="#63063E", full_hex="#63063EAA", r=99, g=6, b=62, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0866", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Wasabi", hex="#6F1068", full_hex="#6F1068AA", r=111, g=16, b=104, pearl_name="Sea Green", pearl_id=51, archive_id="p0867", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Lime 3", hex="#400C36", full_hex="#400C36AA", r=64, g=12, b=54, pearl_name="Lime Green", pearl_id=92, archive_id="p0868", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Eggplant Static", hex="#370537", full_hex="#370537AA", r=55, g=5, b=55, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0869", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Nebula Taxi", hex="#2D0948", full_hex="#2D0948AA", r=45, g=9, b=72, pearl_name="Race Yellow", pearl_id=89, archive_id="p0870", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bruise Taxi 2", hex="#380A2C", full_hex="#380A2CAA", r=56, g=10, b=44, pearl_name="Lime Green", pearl_id=92, archive_id="p0871", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Orchid Gold 2", hex="#4A1137", full_hex="#4A1137AA", r=74, g=17, b=55, pearl_name="Pure Gold", pearl_id=158, archive_id="p0872", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mauve Fuel", hex="#4E1334", full_hex="#4E1334AA", r=78, g=19, b=52, pearl_name="Gasoline Green", pearl_id=54, archive_id="p0873", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Dew 2", hex="#050B50", full_hex="#050B50AA", r=5, g=11, b=80, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0874", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Marigold", hex="#172659", full_hex="#172659AA", r=23, g=38, b=89, pearl_name="Pure Gold", pearl_id=158, archive_id="p0875", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ink Blush", hex="#0E2343", full_hex="#0E2343AA", r=14, g=35, b=67, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0876", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Blush", hex="#082C56", full_hex="#082C56AA", r=8, g=44, b=86, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0877", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Taxi", hex="#090C2C", full_hex="#090C2CAA", r=9, g=12, b=44, pearl_name="Race Yellow", pearl_id=89, archive_id="p0878", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Sapphire Taxi", hex="#0E176C", full_hex="#0E176CAA", r=14, g=23, b=108, pearl_name="Hot Pink", pearl_id=135, archive_id="p0879", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Sapphire Ember", hex="#092966", full_hex="#092966AA", r=9, g=41, b=102, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0880", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Disco", hex="#2A1A63", full_hex="#2A1A63AA", r=42, g=26, b=99, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0881", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Honey", hex="#0E213F", full_hex="#0E213FAA", r=14, g=33, b=63, pearl_name="Bright Orange", pearl_id=138, archive_id="p0882", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ink Taxi", hex="#0B102D", full_hex="#0B102DAA", r=11, g=16, b=45, pearl_name="Race Yellow", pearl_id=89, archive_id="p0883", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Pink", hex="#043B76", full_hex="#043B76AA", r=4, g=59, b=118, pearl_name="Hot Pink", pearl_id=135, archive_id="p0884", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Taxi", hex="#021843", full_hex="#021843AA", r=2, g=24, b=67, pearl_name="Race Yellow", pearl_id=89, archive_id="p0885", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Deepsea Sunrise", hex="#0D0654", full_hex="#0D0654AA", r=13, g=6, b=84, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0886", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Royal Champagne", hex="#0F0E4A", full_hex="#0F0E4AAA", r=15, g=14, b=74, pearl_name="Pure Gold", pearl_id=158, archive_id="p0887", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Dew", hex="#080725", full_hex="#080725AA", r=8, g=7, b=37, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0888", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Blush", hex="#07083E", full_hex="#07083EAA", r=7, g=8, b=62, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0889", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Bubblegum", hex="#0F0729", full_hex="#0F0729AA", r=15, g=7, b=41, pearl_name="Bright Orange", pearl_id=138, archive_id="p0890", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Dew 3", hex="#061769", full_hex="#061769AA", r=6, g=23, b=105, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0891", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Mustard", hex="#07174A", full_hex="#07174AAA", r=7, g=23, b=74, pearl_name="Pure Gold", pearl_id=158, archive_id="p0892", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Sapphire Champagne", hex="#110C54", full_hex="#110C54AA", r=17, g=12, b=84, pearl_name="Hot Pink", pearl_id=135, archive_id="p0893", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Taxi 2", hex="#080B21", full_hex="#080B21AA", r=8, g=11, b=33, pearl_name="Race Yellow", pearl_id=89, archive_id="p0894", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Pink 2", hex="#080C2A", full_hex="#080C2AAA", r=8, g=12, b=42, pearl_name="Hot Pink", pearl_id=135, archive_id="p0895", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Sunrise", hex="#021326", full_hex="#021326AA", r=2, g=19, b=38, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0896", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Deepsea Gold", hex="#162860", full_hex="#162860AA", r=22, g=40, b=96, pearl_name="Pure Gold", pearl_id=158, archive_id="p0897", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Mango", hex="#121843", full_hex="#121843AA", r=18, g=24, b=67, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0898", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Ketchup", hex="#051F3F", full_hex="#051F3FAA", r=5, g=31, b=63, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0899", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Gold", hex="#061125", full_hex="#061125AA", r=6, g=17, b=37, pearl_name="Pure Gold", pearl_id=158, archive_id="p0900", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ink Blush 2", hex="#022852", full_hex="#022852AA", r=2, g=40, b=82, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0901", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Dew", hex="#060E25", full_hex="#060E25AA", r=6, g=14, b=37, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0902", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cobalt Mango", hex="#07062B", full_hex="#07062BAA", r=7, g=6, b=43, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0903", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Deepsea Ketchup", hex="#091C60", full_hex="#091C60AA", r=9, g=28, b=96, pearl_name="Race Yellow", pearl_id=89, archive_id="p0904", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Taxi 2", hex="#0A1C39", full_hex="#0A1C39AA", r=10, g=28, b=57, pearl_name="Race Yellow", pearl_id=89, archive_id="p0905", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Marigold", hex="#0C0A38", full_hex="#0C0A38AA", r=12, g=10, b=56, pearl_name="Race Yellow", pearl_id=89, archive_id="p0906", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Disco", hex="#061145", full_hex="#061145AA", r=6, g=17, b=69, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0907", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Deepsea Dew", hex="#0F2E50", full_hex="#0F2E50AA", r=15, g=46, b=80, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0908", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Ember", hex="#0A1029", full_hex="#0A1029AA", r=10, g=16, b=41, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0909", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Taxi 2", hex="#050B2D", full_hex="#050B2DAA", r=5, g=11, b=45, pearl_name="Race Yellow", pearl_id=89, archive_id="p0910", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Pink", hex="#031748", full_hex="#031748AA", r=3, g=23, b=72, pearl_name="Hot Pink", pearl_id=135, archive_id="p0911", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Sapphire Taxi 2", hex="#12082F", full_hex="#12082FAA", r=18, g=8, b=47, pearl_name="Race Yellow", pearl_id=89, archive_id="p0912", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Pfister", hex="#030E25", full_hex="#030E25AA", r=3, g=14, b=37, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0913", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Deepsea Ketchup 2", hex="#1A0F60", full_hex="#1A0F60AA", r=26, g=15, b=96, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0914", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Disco 2", hex="#07162A", full_hex="#07162AAA", r=7, g=22, b=42, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0915", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Lipstick", hex="#0F2966", full_hex="#0F2966AA", r=15, g=41, b=102, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p0916", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Midnight Mango", hex="#101A38", full_hex="#101A38AA", r=16, g=26, b=56, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0917", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cobalt Marigold", hex="#11164A", full_hex="#11164AAA", r=17, g=22, b=74, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0918", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Ember 2", hex="#09081D", full_hex="#09081DAA", r=9, g=8, b=29, pearl_name="Pure Gold", pearl_id=158, archive_id="p0919", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Ember", hex="#093160", full_hex="#093160AA", r=9, g=49, b=96, pearl_name="Pure Gold", pearl_id=158, archive_id="p0920", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cobalt Taxi", hex="#110E3E", full_hex="#110E3EAA", r=17, g=14, b=62, pearl_name="Race Yellow", pearl_id=89, archive_id="p0921", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Lipstick", hex="#091135", full_hex="#091135AA", r=9, g=17, b=53, pearl_name="Dew Yellow", pearl_id=88, archive_id="p0922", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Navy Bubblegum", hex="#192760", full_hex="#192760AA", r=25, g=39, b=96, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0923", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Taxi 3", hex="#23145E", full_hex="#23145EAA", r=35, g=20, b=94, pearl_name="Race Yellow", pearl_id=89, archive_id="p0924", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Abyss Taxi 4", hex="#160452", full_hex="#160452AA", r=22, g=4, b=82, pearl_name="Race Yellow", pearl_id=89, archive_id="p0925", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Indigo Pink 2", hex="#031B36", full_hex="#031B36AA", r=3, g=27, b=54, pearl_name="Hot Pink", pearl_id=135, archive_id="p0926", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Sapphire Gold", hex="#1D175C", full_hex="#1D175CAA", r=29, g=23, b=92, pearl_name="Pure Gold", pearl_id=158, archive_id="p0927", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bluebird Gold 2", hex="#12203F", full_hex="#12203FAA", r=18, g=32, b=63, pearl_name="Pure Gold", pearl_id=158, archive_id="p0928", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Syrup", hex="#386E1F", full_hex="#386E1FAA", r=56, g=110, b=31, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0929", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lizard Racer", hex="#0F4D2D", full_hex="#0F4D2DAA", r=15, g=77, b=45, pearl_name="Formula Red", pearl_id=29, archive_id="p0930", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Lipstick", hex="#0F370B", full_hex="#0F370BAA", r=15, g=55, b=11, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0931", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Racer", hex="#0E3411", full_hex="#0E3411AA", r=14, g=52, b=17, pearl_name="Formula Red", pearl_id=29, archive_id="p0932", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pond Pfister", hex="#113C0B", full_hex="#113C0BAA", r=17, g=60, b=11, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0933", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Swamp Blush", hex="#1D6222", full_hex="#1D6222AA", r=29, g=98, b=34, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0934", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Forest Rose", hex="#1D6C33", full_hex="#1D6C33AA", r=29, g=108, b=51, pearl_name="Formula Red", pearl_id=29, archive_id="p0935", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Perfume", hex="#154235", full_hex="#154235AA", r=21, g=66, b=53, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0936", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pond Racer", hex="#2B481A", full_hex="#2B481AAA", r=43, g=72, b=26, pearl_name="Formula Red", pearl_id=29, archive_id="p0937", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cactus Purple", hex="#057F54", full_hex="#057F54AA", r=5, g=127, b=84, pearl_name="Bright Purple", pearl_id=145, archive_id="p0938", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Rose", hex="#0F620B", full_hex="#0F620BAA", r=15, g=98, b=11, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0939", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lizard Disco", hex="#254A15", full_hex="#254A15AA", r=37, g=74, b=21, pearl_name="Bright Purple", pearl_id=145, archive_id="p0940", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Forest Pink", hex="#195525", full_hex="#195525AA", r=25, g=85, b=37, pearl_name="Hot Pink", pearl_id=135, archive_id="p0941", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Perfume 2", hex="#04612E", full_hex="#04612EAA", r=4, g=97, b=46, pearl_name="Candy Red", pearl_id=35, archive_id="p0942", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Orchid", hex="#10210A", full_hex="#10210AAA", r=16, g=33, b=10, pearl_name="Formula Red", pearl_id=29, archive_id="p0943", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Orchid", hex="#15741E", full_hex="#15741EAA", r=21, g=116, b=30, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0944", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lizard Candy", hex="#1B5216", full_hex="#1B5216AA", r=27, g=82, b=22, pearl_name="Candy Red", pearl_id=35, archive_id="p0945", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Racer", hex="#0E4C1B", full_hex="#0E4C1BAA", r=14, g=76, b=27, pearl_name="Formula Red", pearl_id=29, archive_id="p0946", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lizard Racer 2", hex="#134C0F", full_hex="#134C0FAA", r=19, g=76, b=15, pearl_name="Formula Red", pearl_id=29, archive_id="p0947", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hunter Disco", hex="#0D422F", full_hex="#0D422FAA", r=13, g=66, b=47, pearl_name="Candy Red", pearl_id=35, archive_id="p0948", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bog Rouge", hex="#13320F", full_hex="#13320FAA", r=19, g=50, b=15, pearl_name="Candy Red", pearl_id=35, archive_id="p0949", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Forest Purple", hex="#155229", full_hex="#155229AA", r=21, g=82, b=41, pearl_name="Bright Purple", pearl_id=145, archive_id="p0950", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Valentine", hex="#0E4611", full_hex="#0E4611AA", r=14, g=70, b=17, pearl_name="Torino Red", pearl_id=28, archive_id="p0951", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Candy", hex="#123125", full_hex="#123125AA", r=18, g=49, b=37, pearl_name="Candy Red", pearl_id=35, archive_id="p0952", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Candy 2", hex="#286D15", full_hex="#286D15AA", r=40, g=109, b=21, pearl_name="Candy Red", pearl_id=35, archive_id="p0953", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Swamp Pink", hex="#1E6A47", full_hex="#1E6A47AA", r=30, g=106, b=71, pearl_name="Hot Pink", pearl_id=135, archive_id="p0954", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hunter Syrup", hex="#173D22", full_hex="#173D22AA", r=23, g=61, b=34, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0955", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Orchid", hex="#22693C", full_hex="#22693CAA", r=34, g=105, b=60, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0956", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bog Rouge 2", hex="#0C5524", full_hex="#0C5524AA", r=12, g=85, b=36, pearl_name="Hot Pink", pearl_id=135, archive_id="p0957", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bog Purple", hex="#097850", full_hex="#097850AA", r=9, g=120, b=80, pearl_name="Bright Purple", pearl_id=145, archive_id="p0958", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Disco 2", hex="#042713", full_hex="#042713AA", r=4, g=39, b=19, pearl_name="Candy Red", pearl_id=35, archive_id="p0959", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Valentine 2", hex="#11381A", full_hex="#11381AAA", r=17, g=56, b=26, pearl_name="Formula Red", pearl_id=29, archive_id="p0960", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Army Blush", hex="#0E7343", full_hex="#0E7343AA", r=14, g=115, b=67, pearl_name="Salmon Pink", pearl_id=136, archive_id="p0961", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lizard Rose", hex="#2F5D23", full_hex="#2F5D23AA", r=47, g=93, b=35, pearl_name="Torino Red", pearl_id=28, archive_id="p0962", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Forest Pink 2", hex="#084116", full_hex="#084116AA", r=8, g=65, b=22, pearl_name="Hot Pink", pearl_id=135, archive_id="p0963", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Redline", hex="#11392A", full_hex="#11392AAA", r=17, g=57, b=42, pearl_name="Torino Red", pearl_id=28, archive_id="p0964", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cactus Purple 2", hex="#137219", full_hex="#137219AA", r=19, g=114, b=25, pearl_name="Bright Purple", pearl_id=145, archive_id="p0965", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Forest Blush", hex="#0E2B03", full_hex="#0E2B03AA", r=14, g=43, b=3, pearl_name="Torino Red", pearl_id=28, archive_id="p0966", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pond Disco", hex="#14492A", full_hex="#14492AAA", r=20, g=73, b=42, pearl_name="Candy Red", pearl_id=35, archive_id="p0967", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bog Candy", hex="#2B491B", full_hex="#2B491BAA", r=43, g=73, b=27, pearl_name="Bright Purple", pearl_id=145, archive_id="p0968", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Disco", hex="#062E0A", full_hex="#062E0AAA", r=6, g=46, b=10, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0969", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Blush", hex="#143D22", full_hex="#143D22AA", r=20, g=61, b=34, pearl_name="Pfister Pink", pearl_id=137, archive_id="p0970", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Moss Candy", hex="#143713", full_hex="#143713AA", r=20, g=55, b=19, pearl_name="Candy Red", pearl_id=35, archive_id="p0971", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Bog Redline", hex="#1E5304", full_hex="#1E5304AA", r=30, g=83, b=4, pearl_name="Torino Red", pearl_id=28, archive_id="p0972", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cactus Bubblegum", hex="#08721C", full_hex="#08721CAA", r=8, g=114, b=28, pearl_name="Hot Pink", pearl_id=135, archive_id="p0973", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Purple", hex="#39220F", full_hex="#39220FAA", r=57, g=34, b=15, pearl_name="Bright Purple", pearl_id=145, archive_id="p0974", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Royal", hex="#775519", full_hex="#775519AA", r=119, g=85, b=25, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0975", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Purple 2", hex="#7E521A", full_hex="#7E521AAA", r=126, g=82, b=26, pearl_name="Bright Purple", pearl_id=145, archive_id="p0976", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Molasses Blue", hex="#A15F0A", full_hex="#A15F0AAA", r=161, g=95, b=10, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0977", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Blue", hex="#9C7920", full_hex="#9C7920AA", r=156, g=121, b=32, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0978", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Surf", hex="#79451B", full_hex="#79451BAA", r=121, g=69, b=27, pearl_name="Surf Blue", pearl_id=68, archive_id="p0979", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Molasses Blue 2", hex="#483013", full_hex="#483013AA", r=72, g=48, b=19, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0980", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Whiskey Blueberry", hex="#9A631E", full_hex="#9A631EAA", r=154, g=99, b=30, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0981", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Copper Nebula", hex="#8B5D24", full_hex="#8B5D24AA", r=139, g=93, b=36, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0982", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Peach Abyss", hex="#532703", full_hex="#532703AA", r=83, g=39, b=3, pearl_name="Bright Purple", pearl_id=145, archive_id="p0983", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Blue", hex="#924C24", full_hex="#924C24AA", r=146, g=76, b=36, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0984", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pumpkin Nebula", hex="#4E2E0C", full_hex="#4E2E0CAA", r=78, g=46, b=12, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0985", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Surf 2", hex="#845A1E", full_hex="#845A1EAA", r=132, g=90, b=30, pearl_name="Surf Blue", pearl_id=68, archive_id="p0986", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pumpkin Sailor", hex="#81540A", full_hex="#81540AAA", r=129, g=84, b=10, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0987", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Abyss", hex="#94511D", full_hex="#94511DAA", r=148, g=81, b=29, pearl_name="Schafter Purple", pearl_id=71, archive_id="p0988", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Molasses Tornado", hex="#543C0D", full_hex="#543C0DAA", r=84, g=60, b=13, pearl_name="Surf Blue", pearl_id=68, archive_id="p0989", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Whiskey Blue", hex="#633202", full_hex="#633202AA", r=99, g=50, b=2, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0990", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mango Purple", hex="#795A17", full_hex="#795A17AA", r=121, g=90, b=23, pearl_name="Bright Purple", pearl_id=145, archive_id="p0991", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Copper Abyss", hex="#321C0B", full_hex="#321C0BAA", r=50, g=28, b=11, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0992", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Whiskey Abyss", hex="#4F270B", full_hex="#4F270BAA", r=79, g=39, b=11, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0993", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Copper Sailor", hex="#4B2A0E", full_hex="#4B2A0EAA", r=75, g=42, b=14, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0994", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Whiskey Ice", hex="#502B0A", full_hex="#502B0AAA", r=80, g=43, b=10, pearl_name="Diamond Blue", pearl_id=67, archive_id="p0995", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Blue 2", hex="#924C20", full_hex="#924C20AA", r=146, g=76, b=32, pearl_name="Ultra Blue", pearl_id=70, archive_id="p0996", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mango Bruise", hex="#764902", full_hex="#764902AA", r=118, g=73, b=2, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p0997", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Copper VHS", hex="#702B05", full_hex="#702B05AA", r=112, g=43, b=5, pearl_name="Bright Purple", pearl_id=145, archive_id="p0998", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Freeze", hex="#B97405", full_hex="#B97405AA", r=185, g=116, b=5, pearl_name="Bright Purple", pearl_id=145, archive_id="p0999", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rust Royal", hex="#8A3404", full_hex="#8A3404AA", r=138, g=52, b=4, pearl_name="Schafter Purple", pearl_id=71, archive_id="p1000", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Molasses Surf", hex="#A3451B", full_hex="#A3451BAA", r=163, g=69, b=27, pearl_name="Surf Blue", pearl_id=68, archive_id="p1001", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Peach Abyss 2", hex="#783C18", full_hex="#783C18AA", r=120, g=60, b=24, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1002", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Abyss 2", hex="#995010", full_hex="#995010AA", r=153, g=80, b=16, pearl_name="Schafter Purple", pearl_id=71, archive_id="p1003", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Copper Purple", hex="#624817", full_hex="#624817AA", r=98, g=72, b=23, pearl_name="Bright Purple", pearl_id=145, archive_id="p1004", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Molasses Aquarium", hex="#442C10", full_hex="#442C10AA", r=68, g=44, b=16, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1005", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Sailor", hex="#A17C16", full_hex="#A17C16AA", r=161, g=124, b=22, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1006", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Peach Violet", hex="#572303", full_hex="#572303AA", r=87, g=35, b=3, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1007", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pumpkin Ice", hex="#46200E", full_hex="#46200EAA", r=70, g=32, b=14, pearl_name="Diamond Blue", pearl_id=67, archive_id="p1008", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Tornado", hex="#723B14", full_hex="#723B14AA", r=114, g=59, b=20, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1009", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Clay Blue", hex="#96400E", full_hex="#96400EAA", r=150, g=64, b=14, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1010", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pumpkin Sailor 2", hex="#783D0E", full_hex="#783D0EAA", r=120, g=61, b=14, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1011", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Peach UFO", hex="#8E6027", full_hex="#8E6027AA", r=142, g=96, b=39, pearl_name="Schafter Purple", pearl_id=71, archive_id="p1012", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Clay Surf", hex="#653E03", full_hex="#653E03AA", r=101, g=62, b=3, pearl_name="Surf Blue", pearl_id=68, archive_id="p1013", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cinnamon Abyss", hex="#9D4D0E", full_hex="#9D4D0EAA", r=157, g=77, b=14, pearl_name="Diamond Blue", pearl_id=67, archive_id="p1014", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Rust Purple", hex="#85441C", full_hex="#85441CAA", r=133, g=68, b=28, pearl_name="Bright Purple", pearl_id=145, archive_id="p1015", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Blue 3", hex="#815106", full_hex="#815106AA", r=129, g=81, b=6, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1016", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Tobacco Freeze", hex="#714C0D", full_hex="#714C0DAA", r=113, g=76, b=13, pearl_name="Bright Purple", pearl_id=145, archive_id="p1017", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Clay Violet", hex="#2C180B", full_hex="#2C180BAA", r=44, g=24, b=11, pearl_name="Diamond Blue", pearl_id=67, archive_id="p1018", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Petrol Candy", hex="#0F3B3F", full_hex="#0F3B3FAA", r=15, g=59, b=63, pearl_name="Candy Red", pearl_id=35, archive_id="p1019", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pool Tomato", hex="#034761", full_hex="#034761AA", r=3, g=71, b=97, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1020", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Racer", hex="#053E4B", full_hex="#053E4BAA", r=5, g=62, b=75, pearl_name="Formula Red", pearl_id=29, archive_id="p1021", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Blush", hex="#075255", full_hex="#075255AA", r=7, g=82, b=85, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1022", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Rust", hex="#0990C0", full_hex="#0990C0AA", r=9, g=144, b=192, pearl_name="Formula Red", pearl_id=29, archive_id="p1023", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Candy", hex="#033D42", full_hex="#033D42AA", r=3, g=61, b=66, pearl_name="Candy Red", pearl_id=35, archive_id="p1024", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Petrol Pink", hex="#267B9A", full_hex="#267B9AAA", r=38, g=123, b=154, pearl_name="Hot Pink", pearl_id=135, archive_id="p1025", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Gold", hex="#0B242A", full_hex="#0B242AAA", r=11, g=36, b=42, pearl_name="Pure Gold", pearl_id=158, archive_id="p1026", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lagoon Ketchup", hex="#228788", full_hex="#228788AA", r=34, g=135, b=136, pearl_name="Formula Red", pearl_id=29, archive_id="p1027", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Redline", hex="#045865", full_hex="#045865AA", r=4, g=88, b=101, pearl_name="Torino Red", pearl_id=28, archive_id="p1028", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Candy 2", hex="#249797", full_hex="#249797AA", r=36, g=151, b=151, pearl_name="Candy Red", pearl_id=35, archive_id="p1029", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cyan Champagne", hex="#0E505D", full_hex="#0E505DAA", r=14, g=80, b=93, pearl_name="Formula Red", pearl_id=29, archive_id="p1030", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Candy", hex="#2B8A96", full_hex="#2B8A96AA", r=43, g=138, b=150, pearl_name="Candy Red", pearl_id=35, archive_id="p1031", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Champagne", hex="#0985B3", full_hex="#0985B3AA", r=9, g=133, b=179, pearl_name="Pure Gold", pearl_id=158, archive_id="p1032", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Pink", hex="#118CB2", full_hex="#118CB2AA", r=17, g=140, b=178, pearl_name="Hot Pink", pearl_id=135, archive_id="p1033", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Blood", hex="#088DA4", full_hex="#088DA4AA", r=8, g=141, b=164, pearl_name="Candy Red", pearl_id=35, archive_id="p1034", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lagoon Tomato", hex="#154B4C", full_hex="#154B4CAA", r=21, g=75, b=76, pearl_name="Candy Red", pearl_id=35, archive_id="p1035", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Rust", hex="#165259", full_hex="#165259AA", r=22, g=82, b=89, pearl_name="Torino Red", pearl_id=28, archive_id="p1036", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lagoon Pink", hex="#29928B", full_hex="#29928BAA", r=41, g=146, b=139, pearl_name="Hot Pink", pearl_id=135, archive_id="p1037", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Racer 2", hex="#084C4D", full_hex="#084C4DAA", r=8, g=76, b=77, pearl_name="Formula Red", pearl_id=29, archive_id="p1038", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Ketchup", hex="#0B7095", full_hex="#0B7095AA", r=11, g=112, b=149, pearl_name="Torino Red", pearl_id=28, archive_id="p1039", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Blush", hex="#1C7FA2", full_hex="#1C7FA2AA", r=28, g=127, b=162, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1040", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Lipstick", hex="#0DBEBD", full_hex="#0DBEBDAA", r=13, g=190, b=189, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1041", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Petrol Racer", hex="#1191AC", full_hex="#1191ACAA", r=17, g=145, b=172, pearl_name="Formula Red", pearl_id=29, archive_id="p1042", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Blush", hex="#067389", full_hex="#067389AA", r=6, g=115, b=137, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1043", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Lipstick", hex="#0E3D49", full_hex="#0E3D49AA", r=14, g=61, b=73, pearl_name="Candy Red", pearl_id=35, archive_id="p1044", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Pink", hex="#067C79", full_hex="#067C79AA", r=6, g=124, b=121, pearl_name="Hot Pink", pearl_id=135, archive_id="p1045", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Racer", hex="#115E57", full_hex="#115E57AA", r=17, g=94, b=87, pearl_name="Formula Red", pearl_id=29, archive_id="p1046", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Candy 2", hex="#093539", full_hex="#093539AA", r=9, g=53, b=57, pearl_name="Candy Red", pearl_id=35, archive_id="p1047", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Cinder", hex="#144555", full_hex="#144555AA", r=20, g=69, b=85, pearl_name="Hot Pink", pearl_id=135, archive_id="p1048", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Lipstick", hex="#157D9A", full_hex="#157D9AAA", r=21, g=125, b=154, pearl_name="Hot Pink", pearl_id=135, archive_id="p1049", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Rose", hex="#04757D", full_hex="#04757DAA", r=4, g=117, b=125, pearl_name="Candy Red", pearl_id=35, archive_id="p1050", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Rust 2", hex="#083232", full_hex="#083232AA", r=8, g=50, b=50, pearl_name="Candy Red", pearl_id=35, archive_id="p1051", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lagoon Candy", hex="#072E34", full_hex="#072E34AA", r=7, g=46, b=52, pearl_name="Candy Red", pearl_id=35, archive_id="p1052", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Rust 2", hex="#196276", full_hex="#196276AA", r=25, g=98, b=118, pearl_name="Formula Red", pearl_id=29, archive_id="p1053", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cyan Goldrush", hex="#1A7A94", full_hex="#1A7A94AA", r=26, g=122, b=148, pearl_name="Hot Pink", pearl_id=135, archive_id="p1054", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Teal Gold", hex="#105055", full_hex="#105055AA", r=16, g=80, b=85, pearl_name="Pure Gold", pearl_id=158, archive_id="p1055", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Racer", hex="#105571", full_hex="#105571AA", r=16, g=85, b=113, pearl_name="Formula Red", pearl_id=29, archive_id="p1056", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Goldrush", hex="#0F6374", full_hex="#0F6374AA", r=15, g=99, b=116, pearl_name="Pure Gold", pearl_id=158, archive_id="p1057", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Aqua Goldrush", hex="#0F9F9C", full_hex="#0F9F9CAA", r=15, g=159, b=156, pearl_name="Formula Red", pearl_id=29, archive_id="p1058", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Lagoon Rose", hex="#21AAA7", full_hex="#21AAA7AA", r=33, g=170, b=167, pearl_name="Torino Red", pearl_id=28, archive_id="p1059", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Mint Blush 2", hex="#155E60", full_hex="#155E60AA", r=21, g=94, b=96, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1060", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cyan Goldrush 2", hex="#053432", full_hex="#053432AA", r=5, g=52, b=50, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1061", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Blush", hex="#1FA29F", full_hex="#1FA29FAA", r=31, g=162, b=159, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1062", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ocean Candy 3", hex="#085066", full_hex="#085066AA", r=8, g=80, b=102, pearl_name="Candy Red", pearl_id=35, archive_id="p1063", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Barbie Nebula", hex="#EB5CF8", full_hex="#EB5CF8AA", r=235, g=92, b=248, pearl_name="Race Yellow", pearl_id=89, archive_id="p1064", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Antifreeze", hex="#E10749", full_hex="#E10749AA", r=225, g=7, b=73, pearl_name="Bright Green", pearl_id=139, archive_id="p1065", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Sailor", hex="#DEF807", full_hex="#DEF807AA", r=222, g=248, b=7, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1066", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Turbo Hazard", hex="#F316E9", full_hex="#F316E9AA", r=243, g=22, b=233, pearl_name="Race Yellow", pearl_id=89, archive_id="p1067", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Taxi", hex="#0E7BFB", full_hex="#0E7BFBAA", r=14, g=123, b=251, pearl_name="Race Yellow", pearl_id=89, archive_id="p1068", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Chrome Redline", hex="#54EFAD", full_hex="#54EFADAA", r=84, g=239, b=173, pearl_name="Torino Red", pearl_id=28, archive_id="p1069", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Barbie Nebula 2", hex="#F6030C", full_hex="#F6030CAA", r=246, g=3, b=12, pearl_name="Lime Green", pearl_id=92, archive_id="p1070", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vapor Sunrise", hex="#654AF5", full_hex="#654AF5AA", r=101, g=74, b=245, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p1071", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Electric Tangerine", hex="#5C5EF2", full_hex="#5C5EF2AA", r=92, g=94, b=242, pearl_name="Bright Orange", pearl_id=138, archive_id="p1072", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Electric Tangerine 2", hex="#1D21E7", full_hex="#1D21E7AA", r=29, g=33, b=231, pearl_name="Bright Orange", pearl_id=138, archive_id="p1073", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hyper Surf", hex="#DCF644", full_hex="#DCF644AA", r=220, g=246, b=68, pearl_name="Surf Blue", pearl_id=68, archive_id="p1074", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Turbo Taxi", hex="#800DEC", full_hex="#800DECAA", r=128, g=13, b=236, pearl_name="Race Yellow", pearl_id=89, archive_id="p1075", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plasma Blood", hex="#8424E9", full_hex="#8424E9AA", r=132, g=36, b=233, pearl_name="Race Yellow", pearl_id=89, archive_id="p1076", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plasma Sludge", hex="#CDE809", full_hex="#CDE809AA", r=205, g=232, b=9, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1077", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Acid Sludge", hex="#AF07F1", full_hex="#AF07F1AA", r=175, g=7, b=241, pearl_name="Pure Gold", pearl_id=158, archive_id="p1078", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Barbie Pickle", hex="#810CF9", full_hex="#810CF9AA", r=129, g=12, b=249, pearl_name="Hot Pink", pearl_id=135, archive_id="p1079", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Electric Nebula", hex="#F408BD", full_hex="#F408BDAA", r=244, g=8, b=189, pearl_name="Bright Green", pearl_id=139, archive_id="p1080", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Electric Blood", hex="#D815D4", full_hex="#D815D4AA", r=216, g=21, b=212, pearl_name="Pure Gold", pearl_id=158, archive_id="p1081", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Plasma Wasabi", hex="#F756DB", full_hex="#F756DBAA", r=247, g=86, b=219, pearl_name="Pure Gold", pearl_id=158, archive_id="p1082", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vapor Blue", hex="#F9E123", full_hex="#F9E123AA", r=249, g=225, b=35, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1083", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hyper Pink", hex="#0C22DB", full_hex="#0C22DBAA", r=12, g=34, b=219, pearl_name="Hot Pink", pearl_id=135, archive_id="p1084", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Hazard", hex="#8B13E9", full_hex="#8B13E9AA", r=139, g=19, b=233, pearl_name="Pure Gold", pearl_id=158, archive_id="p1085", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Chrome Hazard", hex="#D9118F", full_hex="#D9118FAA", r=217, g=17, b=143, pearl_name="Sea Green", pearl_id=51, archive_id="p1086", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Sunrise", hex="#4DB9E6", full_hex="#4DB9E6AA", r=77, g=185, b=230, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p1087", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Acid Mint", hex="#F15589", full_hex="#F15589AA", r=241, g=85, b=137, pearl_name="Sea Green", pearl_id=51, archive_id="p1088", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Hazard 2", hex="#EB206F", full_hex="#EB206FAA", r=235, g=32, b=111, pearl_name="Lime Green", pearl_id=92, archive_id="p1089", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Chrome Surf", hex="#FD0325", full_hex="#FD0325AA", r=253, g=3, b=37, pearl_name="Surf Blue", pearl_id=68, archive_id="p1090", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Turbo Surf", hex="#F43D25", full_hex="#F43D25AA", r=244, g=61, b=37, pearl_name="Surf Blue", pearl_id=68, archive_id="p1091", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hyper Nebula", hex="#91D810", full_hex="#91D810AA", r=145, g=216, b=16, pearl_name="Candy Red", pearl_id=35, archive_id="p1092", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Hyper Surf 2", hex="#F7513C", full_hex="#F7513CAA", r=247, g=81, b=60, pearl_name="Surf Blue", pearl_id=68, archive_id="p1093", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Laser Reactor", hex="#96F14A", full_hex="#96F14AAA", r=150, g=241, b=74, pearl_name="Torino Red", pearl_id=28, archive_id="p1094", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Toxic Ketchup", hex="#C82FF9", full_hex="#C82FF9AA", r=200, g=47, b=249, pearl_name="Lime Green", pearl_id=92, archive_id="p1095", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Barbie Racer", hex="#0BEC30", full_hex="#0BEC30AA", r=11, g=236, b=48, pearl_name="Formula Red", pearl_id=29, archive_id="p1096", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Neon Surf", hex="#E8BD25", full_hex="#E8BD25AA", r=232, g=189, b=37, pearl_name="Surf Blue", pearl_id=68, archive_id="p1097", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Acid Nebula", hex="#F27714", full_hex="#F27714AA", r=242, g=119, b=20, pearl_name="Bright Purple", pearl_id=145, archive_id="p1098", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Slate Taxi", hex="#918786", full_hex="#918786AA", r=145, g=135, b=134, pearl_name="Race Yellow", pearl_id=89, archive_id="p1099", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Asphalt Goo", hex="#373237", full_hex="#373237AA", r=55, g=50, b=55, pearl_name="Formula Red", pearl_id=29, archive_id="p1100", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Carbon Surf", hex="#363238", full_hex="#363238AA", r=54, g=50, b=56, pearl_name="Surf Blue", pearl_id=68, archive_id="p1101", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Obsidian Rose", hex="#504C59", full_hex="#504C59AA", r=80, g=76, b=89, pearl_name="Surf Blue", pearl_id=68, archive_id="p1102", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Concrete Racer", hex="#26292A", full_hex="#26292AAA", r=38, g=41, b=42, pearl_name="Formula Red", pearl_id=29, archive_id="p1103", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Slate Taxi 2", hex="#8F888A", full_hex="#8F888AAA", r=143, g=136, b=138, pearl_name="Race Yellow", pearl_id=89, archive_id="p1104", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Concrete Venom", hex="#76748E", full_hex="#76748EAA", r=118, g=116, b=142, pearl_name="Bright Green", pearl_id=139, archive_id="p1105", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Asphalt Blood", hex="#2D2832", full_hex="#2D2832AA", r=45, g=40, b=50, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1106", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pewter Racer", hex="#747773", full_hex="#747773AA", r=116, g=119, b=115, pearl_name="Formula Red", pearl_id=29, archive_id="p1107", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Steel Goo", hex="#383639", full_hex="#383639AA", r=56, g=54, b=57, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1108", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pewter Tangerine", hex="#0D0F0C", full_hex="#0D0F0CAA", r=13, g=15, b=12, pearl_name="Bright Orange", pearl_id=138, archive_id="p1109", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Steel Goo 2", hex="#1A1B1B", full_hex="#1A1B1BAA", r=26, g=27, b=27, pearl_name="Bright Green", pearl_id=139, archive_id="p1110", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Asphalt Banana", hex="#473C3F", full_hex="#473C3FAA", r=71, g=60, b=63, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1111", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pewter Taxi", hex="#171915", full_hex="#171915AA", r=23, g=25, b=21, pearl_name="Race Yellow", pearl_id=89, archive_id="p1112", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pewter Rose", hex="#616263", full_hex="#616263AA", r=97, g=98, b=99, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1113", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Steel Fuel", hex="#202624", full_hex="#202624AA", r=32, g=38, b=36, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1114", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Smoke Tangerine", hex="#131313", full_hex="#131313AA", r=19, g=19, b=19, pearl_name="Bright Orange", pearl_id=138, archive_id="p1115", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Graphite Taxi", hex="#738180", full_hex="#738180AA", r=115, g=129, b=128, pearl_name="Bright Green", pearl_id=139, archive_id="p1116", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Concrete Venom 2", hex="#262626", full_hex="#262626AA", r=38, g=38, b=38, pearl_name="Bright Green", pearl_id=139, archive_id="p1117", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Graphite Candy 2", hex="#121015", full_hex="#121015AA", r=18, g=16, b=21, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1118", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Gunmetal Slime", hex="#0D0B0B", full_hex="#0D0B0BAA", r=13, g=11, b=11, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1119", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Gunmetal Racer", hex="#4D4C49", full_hex="#4D4C49AA", r=77, g=76, b=73, pearl_name="Formula Red", pearl_id=29, archive_id="p1120", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Smoke Taxi", hex="#838A7D", full_hex="#838A7DAA", r=131, g=138, b=125, pearl_name="Race Yellow", pearl_id=89, archive_id="p1121", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Carbon Pfister", hex="#060708", full_hex="#060708AA", r=6, g=7, b=8, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1122", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Carbon Venom", hex="#423E4D", full_hex="#423E4DAA", r=66, g=62, b=77, pearl_name="Bright Green", pearl_id=139, archive_id="p1123", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Gunmetal Citrus 2", hex="#646660", full_hex="#646660AA", r=100, g=102, b=96, pearl_name="Formula Red", pearl_id=29, archive_id="p1124", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Gunmetal Fuel", hex="#666362", full_hex="#666362AA", r=102, g=99, b=98, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1125", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Asphalt Citrus", hex="#5F6A6E", full_hex="#5F6A6EAA", r=95, g=106, b=110, pearl_name="Hot Pink", pearl_id=135, archive_id="p1126", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Smoke Fuel", hex="#161616", full_hex="#161616AA", r=22, g=22, b=22, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1127", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Obsidian Banana", hex="#57524C", full_hex="#57524CAA", r=87, g=82, b=76, pearl_name="Hot Pink", pearl_id=135, archive_id="p1128", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Slime", hex="#ECEAE9", full_hex="#ECEAE9AA", r=236, g=234, b=233, pearl_name="Bright Orange", pearl_id=138, archive_id="p1129", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Tomato", hex="#F2F2F4", full_hex="#F2F2F4AA", r=242, g=242, b=244, pearl_name="Lime Green", pearl_id=92, archive_id="p1130", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Radio", hex="#DFE3E0", full_hex="#DFE3E0AA", r=223, g=227, b=224, pearl_name="Hot Pink", pearl_id=135, archive_id="p1131", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Poison", hex="#EBEDEF", full_hex="#EBEDEFAA", r=235, g=237, b=239, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1132", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Bluefire", hex="#F7F8F6", full_hex="#F7F8F6AA", r=247, g=248, b=246, pearl_name="Formula Red", pearl_id=29, archive_id="p1133", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Blue", hex="#DDDDE4", full_hex="#DDDDE4AA", r=221, g=221, b=228, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1134", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pearl Redline", hex="#E6EBE7", full_hex="#E6EBE7AA", r=230, g=235, b=231, pearl_name="Torino Red", pearl_id=28, archive_id="p1135", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Pink", hex="#F7F8F7", full_hex="#F7F8F7AA", r=247, g=248, b=247, pearl_name="Hot Pink", pearl_id=135, archive_id="p1136", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Gold", hex="#F0F1F1", full_hex="#F0F1F1AA", r=240, g=241, b=241, pearl_name="Pure Gold", pearl_id=158, archive_id="p1137", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Gasoline", hex="#E5EBE5", full_hex="#E5EBE5AA", r=229, g=235, b=229, pearl_name="Formula Red", pearl_id=29, archive_id="p1138", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Sailor", hex="#F6F4F4", full_hex="#F6F4F4AA", r=246, g=244, b=244, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1139", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Bluefire", hex="#E9EAEC", full_hex="#E9EAECAA", r=233, g=234, b=236, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1140", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cream Radio", hex="#F0EDF0", full_hex="#F0EDF0AA", r=240, g=237, b=240, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1141", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Pink 2", hex="#F3F3F6", full_hex="#F3F3F6AA", r=243, g=243, b=246, pearl_name="Hot Pink", pearl_id=135, archive_id="p1142", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Radio", hex="#E9E9EC", full_hex="#E9E9ECAA", r=233, g=233, b=236, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1143", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Pfister", hex="#E6E5DE", full_hex="#E6E5DEAA", r=230, g=229, b=222, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1144", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Redline", hex="#EEEEEE", full_hex="#EEEEEEAA", r=238, g=238, b=238, pearl_name="Torino Red", pearl_id=28, archive_id="p1145", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Sailor 2", hex="#EAE8E7", full_hex="#EAE8E7AA", r=234, g=232, b=231, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1146", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Snow Racer", hex="#E7E6EA", full_hex="#E7E6EAAA", r=231, g=230, b=234, pearl_name="Formula Red", pearl_id=29, archive_id="p1147", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pearl Fuel", hex="#F0F5F3", full_hex="#F0F5F3AA", r=240, g=245, b=243, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1148", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Goldrush", hex="#E3E7E7", full_hex="#E3E7E7AA", r=227, g=231, b=231, pearl_name="Formula Red", pearl_id=29, archive_id="p1149", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Goldrush 2", hex="#ECEAEA", full_hex="#ECEAEAAA", r=236, g=234, b=234, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1150", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Pearl Redline 2", hex="#E7E6EB", full_hex="#E7E6EBAA", r=231, g=230, b=235, pearl_name="Torino Red", pearl_id=28, archive_id="p1151", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Ketchup", hex="#F2F5F3", full_hex="#F2F5F3AA", r=242, g=245, b=243, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1152", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Chalk Cosmos", hex="#E9EBEC", full_hex="#E9EBECAA", r=233, g=235, b=236, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1153", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Vanilla Sailor", hex="#F3F5F1", full_hex="#F3F5F1AA", r=243, g=245, b=241, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1154", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Marshmallow Tomato", hex="#EFEFF1", full_hex="#EFEFF1AA", r=239, g=239, b=241, pearl_name="Lime Green", pearl_id=92, archive_id="p1155", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Radio 2", hex="#DFE2E0", full_hex="#DFE2E0AA", r=223, g=226, b=224, pearl_name="Pure Gold", pearl_id=158, archive_id="p1156", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Milk Sailor 3", hex="#E8E1E0", full_hex="#E8E1E0AA", r=232, g=225, b=224, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1157", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Racer 2", hex="#E6E9DF", full_hex="#E6E9DFAA", r=230, g=233, b=223, pearl_name="Formula Red", pearl_id=29, archive_id="p1158", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Goldrush", hex="#F0EDF0", full_hex="#F0EDF0AA", r=240, g=237, b=240, pearl_name="Bright Green", pearl_id=139, archive_id="p1159", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Frost Fuel", hex="#F3F4F5", full_hex="#F3F4F5AA", r=243, g=244, b=245, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1160", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cream Ketchup", hex="#F6F3F4", full_hex="#F6F3F4AA", r=246, g=243, b=244, pearl_name="Torino Red", pearl_id=28, archive_id="p1161", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ivory Fuel", hex="#EAEAE3", full_hex="#EAEAE3AA", r=234, g=234, b=227, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1162", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ivory Venom", hex="#DEE4DE", full_hex="#DEE4DEAA", r=222, g=228, b=222, pearl_name="Bright Green", pearl_id=139, archive_id="p1163", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Glacier Pickle", hex="#E5EBE3", full_hex="#E5EBE3AA", r=229, g=235, b=227, pearl_name="Lime Green", pearl_id=92, archive_id="p1164", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Frost Sailor", hex="#F9F8F7", full_hex="#F9F8F7AA", r=249, g=248, b=247, pearl_name="Spinnaker Purple", pearl_id=72, archive_id="p1165", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ivory Tangerine", hex="#E3E0E0", full_hex="#E3E0E0AA", r=227, g=224, b=224, pearl_name="Bright Orange", pearl_id=138, archive_id="p1166", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Cream Bubblegum", hex="#F4F4F3", full_hex="#F4F4F3AA", r=244, g=244, b=243, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1167", confidence="high", is_ai=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ai Ivory Slime", hex="#F8F8F9", full_hex="#F8F8F9AA", r=248, g=248, b=249, pearl_name="Lime Green", pearl_id=92, archive_id="p1168", confidence="high", is_ai=true}

-- community color append block
-- note: imported colors stay individual to preserve register-safe loading.
archiveLibrary[#archiveLibrary + 1] = {name="BMW Monte Carlo Blue", hex="#132763", full_hex="#132763AA", r=19, g=39, b=99, pearl_name="Mariner Blue", pearl_id=65, archive_id="p1169", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Porsche Miami Blue", hex="#006DAD", full_hex="#006DADAA", r=0, g=109, b=173, pearl_name="", pearl_id=nil, archive_id="p1170", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Brightened Purple", hex="#2D0231", full_hex="#2D0231AA", r=45, g=2, b=49, pearl_name="Bright Purple", pearl_id=145, archive_id="p1171", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1968 Gulfstream Aqua", hex="#0A2F34", full_hex="#0A2F34AA", r=10, g=47, b=52, pearl_name="Frost White", pearl_id=112, archive_id="p1172", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1968 Tahoe Turquoise", hex="#2A474B", full_hex="#2A474BAA", r=42, g=71, b=75, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1173", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1972 Anti-Establish Mint", hex="#204528", full_hex="#204528AA", r=32, g=69, b=40, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1174", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1970 Bright Gold Metallic", hex="#5C4117", full_hex="#5C4117AA", r=92, g=65, b=23, pearl_name="Bleached Brown", pearl_id=nil, archive_id="p1175", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1968 Wimbledon White", hex="#CFC2A9", full_hex="#CFC2A9AA", r=207, g=194, b=169, pearl_name="", pearl_id=nil, archive_id="p1176", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="AMG Solarbeam Yellow", hex="#AF6605", full_hex="#AF6605AA", r=175, g=102, b=5, pearl_name="Orange", pearl_id=38, archive_id="p1177", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1968 Candy Apple Red", hex="#5E0303", full_hex="#5E0303AA", r=94, g=3, b=3, pearl_name="", pearl_id=nil, archive_id="p1178", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1967 Burnt Amber", hex="#523726", full_hex="#523726AA", r=82, g=55, b=38, pearl_name="Cream", pearl_id=107, archive_id="p1179", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1972 Medium Lime", hex="#404727", full_hex="#404727AA", r=64, g=71, b=39, pearl_name="Silver", pearl_id=4, archive_id="p1180", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1970 Medium Green", hex="#354C3D", full_hex="#354C3DAA", r=53, g=76, b=61, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1181", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="2004 Ford Mustang 40th Anniversary Mystichrome", hex="#042225", full_hex="#042225AA", r=4, g=34, b=37, pearl_name="Bright Purple", pearl_id=145, archive_id="p1182", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1967 Brittany Blue", hex="#2E4652", full_hex="#2E4652AA", r=46, g=70, b=82, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1183", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1969 Acapulco Blue", hex="#081936", full_hex="#081936AA", r=8, g=25, b=54, pearl_name="Surf Blue", pearl_id=68, archive_id="p1184", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1971 Grabber Green", hex="#0B5135", full_hex="#0B5135AA", r=11, g=81, b=53, pearl_name="Shadow Silver", pearl_id=7, archive_id="p1185", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1966 Sauterne Gold", hex="#5F6658", full_hex="#5F6658AA", r=95, g=102, b=88, pearl_name="Silver", pearl_id=4, archive_id="p1186", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1967 Gulfstream Aqua", hex="#0D363F", full_hex="#0D363FAA", r=13, g=54, b=63, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1187", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Bright Blue Poly", hex="#00365A", full_hex="#00365AAA", r=0, g=54, b=90, pearl_name="Surf Blue", pearl_id=68, archive_id="p1188", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="1968 Highland Green (Ellie Version)", hex="#051210", full_hex="#051210AA", r=5, g=18, b=16, pearl_name="Black Steel", pearl_id=2, archive_id="p1189", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Tahoe Turquoise", hex="#416C75", full_hex="#416C75AA", r=65, g=108, b=117, pearl_name="Shadow Silver", pearl_id=7, archive_id="p1190", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Aston Martin AM-RB 001 Silver", hex="#32373B", full_hex="#32373BAA", r=50, g=55, b=59, pearl_name="Ice White", pearl_id=111, archive_id="p1191", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lime Gold", hex="#55634C", full_hex="#55634CAA", r=85, g=99, b=76, pearl_name="Cast Iron Silver", pearl_id=4, archive_id="p1192", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Amaranth", hex="#27122A", full_hex="#27122AAA", r=39, g=18, b=42, pearl_name="Dark Blue", pearl_id=62, archive_id="p1193", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Fiesta Yellow", hex="#B2AD93", full_hex="#B2AD93AA", r=178, g=173, b=147, pearl_name="", pearl_id=nil, archive_id="p1194", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Giallo Ocra", hex="#7A4602", full_hex="#7A4602AA", r=122, g=70, b=2, pearl_name="", pearl_id=nil, archive_id="p1195", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Island Blue", hex="#19365A", full_hex="#19365AAA", r=25, g=54, b=90, pearl_name="", pearl_id=nil, archive_id="p1196", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Salmon Pesca 73", hex="#84582A", full_hex="#84582AAA", r=132, g=88, b=42, pearl_name="", pearl_id=nil, archive_id="p1197", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Racing Green", hex="#021816", full_hex="#021816AA", r=2, g=24, b=22, pearl_name="", pearl_id=nil, archive_id="p1198", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Smoke Gray", hex="#465856", full_hex="#465856AA", r=70, g=88, b=86, pearl_name="", pearl_id=nil, archive_id="p1199", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Solar Red", hex="#66080B", full_hex="#66080BAA", r=102, g=8, b=11, pearl_name="", pearl_id=nil, archive_id="p1200", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Surf Blue", hex="#237480", full_hex="#237480AA", r=35, g=116, b=128, pearl_name="", pearl_id=nil, archive_id="p1201", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Yellow Citron", hex="#928815", full_hex="#928815AA", r=146, g=136, b=21, pearl_name="", pearl_id=nil, archive_id="p1202", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Fides Global Green", hex="#344D00", full_hex="#344D00AA", r=52, g=77, b=0, pearl_name="Gold", pearl_id=37, archive_id="p1203", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Stryker Green", hex="#243102", full_hex="#243102AA", r=36, g=49, b=2, pearl_name="Lime Green", pearl_id=92, archive_id="p1204", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Dark Swamp Green", hex="#0D1A00", full_hex="#0D1A00AA", r=13, g=26, b=0, pearl_name="Bright Green", pearl_id=139, archive_id="p1205", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Austin Yellow", hex="#5C560A", full_hex="#5C560AAA", r=92, g=86, b=10, pearl_name="Race Yellow", pearl_id=89, archive_id="p1206", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Royal Metal Blue", hex="#000F37", full_hex="#000F37AA", r=0, g=15, b=55, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1207", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Black Rose Metal", hex="#130C14", full_hex="#130C14AA", r=19, g=12, b=20, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1208", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Giallo Orion", hex="#A57301", full_hex="#A57301AA", r=165, g=115, b=1, pearl_name="", pearl_id=nil, archive_id="p1209", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Arancio Atlas", hex="#933704", full_hex="#933704AA", r=147, g=55, b=4, pearl_name="Anthracite Black", pearl_id=11, archive_id="p1210", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Grigio Adamas", hex="#4D4F55", full_hex="#4D4F55AA", r=77, g=79, b=85, pearl_name="Graphite", pearl_id=1, archive_id="p1211", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Grigio Antares", hex="#444446", full_hex="#444446AA", r=68, g=68, b=70, pearl_name="Ice White", pearl_id=111, archive_id="p1212", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Grigio Estoque", hex="#181E20", full_hex="#181E20AA", r=24, g=30, b=32, pearl_name="Silver", pearl_id=4, archive_id="p1213", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Grigio Telesto", hex="#303338", full_hex="#303338AA", r=48, g=51, b=56, pearl_name="Anthracite Black", pearl_id=11, archive_id="p1214", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Balloon White", hex="#9B9DA0", full_hex="#9B9DA0AA", r=155, g=157, b=160, pearl_name="Ice White", pearl_id=111, archive_id="p1215", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Accident Green", hex="#698265", full_hex="#698265AA", r=105, g=130, b=101, pearl_name="", pearl_id=nil, archive_id="p1216", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="House of Kolor Blue Indigo", hex="#0F073B", full_hex="#0F073BAA", r=15, g=7, b=59, pearl_name="Blue", pearl_id=64, archive_id="p1217", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Pearl White", hex="#CBC3BC", full_hex="#CBC3BCAA", r=203, g=195, b=188, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1218", confidence="high", is_forum_import=true, original_finish="Worn"}
archiveLibrary[#archiveLibrary + 1] = {name="Ossifrage", hex="#8E402C", full_hex="#8E402CAA", r=142, g=64, b=44, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1219", confidence="high", is_forum_import=true, original_finish="Pure"}
archiveLibrary[#archiveLibrary + 1] = {name="Metallic Ice Blue", hex="#25364B", full_hex="#25364BAA", r=37, g=54, b=75, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1220", confidence="high", is_forum_import=true, original_finish="Pure"}
archiveLibrary[#archiveLibrary + 1] = {name="Carmen Red", hex="#730608", full_hex="#730608AA", r=115, g=6, b=8, pearl_name="", pearl_id=nil, archive_id="p1221", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="AEE Fawn", hex="#857354", full_hex="#857354AA", r=133, g=115, b=84, pearl_name="", pearl_id=nil, archive_id="p1222", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Honey Beige", hex="#8C7C68", full_hex="#8C7C68AA", r=140, g=124, b=104, pearl_name="", pearl_id=nil, archive_id="p1223", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Willow Green", hex="#607E65", full_hex="#607E65AA", r=96, g=126, b=101, pearl_name="", pearl_id=nil, archive_id="p1224", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Golden Sand Metallic", hex="#504942", full_hex="#504942AA", r=80, g=73, b=66, pearl_name="Sandy / Bleached Brown", pearl_id=nil, archive_id="p1225", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Fern Grey", hex="#343C28", full_hex="#343C28AA", r=52, g=60, b=40, pearl_name="", pearl_id=nil, archive_id="p1226", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lavender Blue", hex="#485D78", full_hex="#485D78AA", r=72, g=93, b=120, pearl_name="", pearl_id=nil, archive_id="p1227", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Opalescent Dark Green", hex="#061311", full_hex="#061311AA", r=6, g=19, b=17, pearl_name="Sea Green", pearl_id=51, archive_id="p1228", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Regency Red", hex="#340609", full_hex="#340609AA", r=52, g=6, b=9, pearl_name="", pearl_id=nil, archive_id="p1229", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="British Racing Green", hex="#000F0E", full_hex="#000F0EAA", r=0, g=15, b=14, pearl_name="", pearl_id=nil, archive_id="p1230", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Old English White", hex="#ACAA9E", full_hex="#ACAA9EAA", r=172, g=170, b=158, pearl_name="", pearl_id=nil, archive_id="p1231", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Rose Gold", hex="#B76E79", full_hex="#B76E79AA", r=183, g=110, b=121, pearl_name="Cream", pearl_id=107, archive_id="p1232", confidence="high", is_forum_import=true, original_finish="Brushed"}
archiveLibrary[#archiveLibrary + 1] = {name="Viola SE30th", hex="#3B2134", full_hex="#3B2134AA", r=59, g=33, b=52, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1233", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lush Jungle Green", hex="#131C04", full_hex="#131C04AA", r=19, g=28, b=4, pearl_name="Moss Brown", pearl_id=100, archive_id="p1234", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Chrome Sunrise Red", hex="#230000", full_hex="#230000AA", r=35, g=0, b=0, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p1235", confidence="high", is_forum_import=true, original_finish="Chrome"}
archiveLibrary[#archiveLibrary + 1] = {name="Dark Green #001600", hex="#001600", full_hex="#001600AA", r=0, g=22, b=0, pearl_name="Nautical Blue", pearl_id=69, archive_id="p1236", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="HughDamrite It's Red", hex="#350000", full_hex="#350000AA", r=53, g=0, b=0, pearl_name="Candy Red", pearl_id=35, archive_id="p1237", confidence="high", is_forum_import=true, original_finish="Chrome"}
archiveLibrary[#archiveLibrary + 1] = {name="Quake Green", hex="#001714", full_hex="#001714AA", r=0, g=23, b=20, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1238", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ford Performance Blue", hex="#04001C", full_hex="#04001CAA", r=4, g=0, b=28, pearl_name="Blue", pearl_id=64, archive_id="p1239", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ford Purple Velvet", hex="#0E0012", full_hex="#0E0012AA", r=14, g=0, b=18, pearl_name="Silver", pearl_id=4, archive_id="p1240", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Purple Velvet Bright", hex="#0A0021", full_hex="#0A0021AA", r=10, g=0, b=33, pearl_name="Bright Purple", pearl_id=145, archive_id="p1241", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Electron Blue (Civic Si)", hex="#101C56", full_hex="#101C56AA", r=16, g=28, b=86, pearl_name="Baby Blue", pearl_id=nil, archive_id="p1242", confidence="ocr-reviewed", is_forum_import=true, original_finish="Worn"}
archiveLibrary[#archiveLibrary + 1] = {name="Ultimate Black Opal", hex="#040008", full_hex="#040008AA", r=4, g=0, b=8, pearl_name="Saddle Brown", pearl_id=nil, archive_id="p1243", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Majestic Amethyst", hex="#1A181F", full_hex="#1A181FAA", r=26, g=24, b=31, pearl_name="", pearl_id=nil, archive_id="p1244", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Worn Anthracite Black", hex="#121110", full_hex="#121110AA", r=18, g=17, b=16, pearl_name="Anthracite Black", pearl_id=11, archive_id="p1245", confidence="high", is_forum_import=true, original_finish="Chrome"}
archiveLibrary[#archiveLibrary + 1] = {name="Mystichrome", hex="#0A000A", full_hex="#0A000AAA", r=10, g=0, b=10, pearl_name="Racing Green", pearl_id=50, archive_id="p1246", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Deep Yellow", hex="#AD9105", full_hex="#AD9105AA", r=173, g=145, b=5, pearl_name="", pearl_id=nil, archive_id="p1247", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Sweet 'n' Smoky", hex="#170400", full_hex="#170400AA", r=23, g=4, b=0, pearl_name="Sunrise Orange", pearl_id=36, archive_id="p1248", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Dukes Deep Purple", hex="#0D052B", full_hex="#0D052BAA", r=13, g=5, b=43, pearl_name="Blue", pearl_id=64, archive_id="p1249", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Sabre Dark Green — Gasoline", hex="#001919", full_hex="#001919AA", r=0, g=25, b=25, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1250", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Sabre Dark Green — Bright Green", hex="#001919", full_hex="#001919AA", r=0, g=25, b=25, pearl_name="Bright Green", pearl_id=139, archive_id="p1251", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Cotton Candy Pink", hex="#BE64BE", full_hex="#BE64BEAA", r=190, g=100, b=190, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1252", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Sunshine Gold", hex="#64571B", full_hex="#64571BAA", r=100, g=87, b=27, pearl_name="", pearl_id=nil, archive_id="p1253", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 Mamba Mia Blue", hex="#034A7C", full_hex="#034A7CAA", r=3, g=74, b=124, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1254", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="AMG Sunbeam Yellow", hex="#A07000", full_hex="#A07000AA", r=160, g=112, b=0, pearl_name="", pearl_id=nil, archive_id="p1255", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="McLaren Cobalt Violet", hex="#100914", full_hex="#100914AA", r=16, g=9, b=20, pearl_name="", pearl_id=nil, archive_id="p1256", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lamborghini Giallo Inti", hex="#7B6001", full_hex="#7B6001AA", r=123, g=96, b=1, pearl_name="", pearl_id=nil, archive_id="p1257", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lamborghini Verde Mantis", hex="#3E6303", full_hex="#3E6303AA", r=62, g=99, b=3, pearl_name="", pearl_id=nil, archive_id="p1258", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 Guacamole Green", hex="#49532D", full_hex="#49532DAA", r=73, g=83, b=45, pearl_name="", pearl_id=nil, archive_id="p1259", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="McLaren Volcano Orange", hex="#4D0800", full_hex="#4D0800AA", r=77, g=8, b=0, pearl_name="", pearl_id=nil, archive_id="p1260", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Koenigsegg Metallic Blue", hex="#031030", full_hex="#031030AA", r=3, g=16, b=48, pearl_name="", pearl_id=nil, archive_id="p1261", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="General Lee Corvette Flame Red", hex="#8C2D00", full_hex="#8C2D00AA", r=140, g=45, b=0, pearl_name="Bronze", pearl_id=90, archive_id="p1262", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Suicide Purple", hex="#14060C", full_hex="#14060CAA", r=20, g=6, b=12, pearl_name="Hot Pink", pearl_id=135, archive_id="p1263", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Suicide Purple Bright", hex="#270C18", full_hex="#270C18AA", r=39, g=12, b=24, pearl_name="Hot Pink", pearl_id=135, archive_id="p1264", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Suicide Purple Brighter", hex="#3B1223", full_hex="#3B1223AA", r=59, g=18, b=35, pearl_name="Hot Pink", pearl_id=135, archive_id="p1265", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Vihrea Green", hex="#05671C", full_hex="#05671CAA", r=5, g=103, b=28, pearl_name="", pearl_id=nil, archive_id="p1266", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 Deep Purple Sea", hex="#170D3B", full_hex="#170D3BAA", r=23, g=13, b=59, pearl_name="Diamond Blue", pearl_id=67, archive_id="p1267", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Dewbauchee Shaken Silver", hex="#393943", full_hex="#393943AA", r=57, g=57, b=67, pearl_name="Ice White", pearl_id=111, archive_id="p1268", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Dewbauchee Specter Silver", hex="#434349", full_hex="#434349AA", r=67, g=67, b=73, pearl_name="", pearl_id=nil, archive_id="p1269", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 AM Morning Frost White", hex="#A7B4C6", full_hex="#A7B4C6AA", r=167, g=180, b=198, pearl_name="", pearl_id=nil, archive_id="p1270", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Millennium Jade", hex="#50503D", full_hex="#50503DAA", r=80, g=80, b=61, pearl_name="Saddle Brown", pearl_id=nil, archive_id="p1271", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Cotton Candy Soft Green", hex="#71A55F", full_hex="#71A55FAA", r=113, g=165, b=95, pearl_name="", pearl_id=nil, archive_id="p1272", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 Hot Purple", hex="#5B2553", full_hex="#5B2553AA", r=91, g=37, b=83, pearl_name="Diamond Blue", pearl_id=67, archive_id="p1273", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Porsche Miami Blue", hex="#004F8F", full_hex="#004F8FAA", r=0, g=79, b=143, pearl_name="", pearl_id=nil, archive_id="p1274", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Globe Green", hex="#1B4823", full_hex="#1B4823AA", r=27, g=72, b=35, pearl_name="Bright Green", pearl_id=139, archive_id="p1275", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Audi Daytona Gray Pearl", hex="#101216", full_hex="#101216AA", r=16, g=18, b=22, pearl_name="Frost White", pearl_id=112, archive_id="p1276", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Meteorite Purple", hex="#0D0620", full_hex="#0D0620AA", r=13, g=6, b=32, pearl_name="Light Blue", pearl_id=74, archive_id="p1277", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Plum Crazy Purple", hex="#170F2A", full_hex="#170F2AAA", r=23, g=15, b=42, pearl_name="Silver", pearl_id=4, archive_id="p1278", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lamborghini Verde Mantis Bright", hex="#1F7F17", full_hex="#1F7F17AA", r=31, g=127, b=23, pearl_name="", pearl_id=nil, archive_id="p1279", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GTAForums Purple #111330", hex="#111330", full_hex="#111330AA", r=17, g=19, b=48, pearl_name="Schafter Purple", pearl_id=71, archive_id="p1280", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Verde Draco", hex="#2E3228", full_hex="#2E3228AA", r=46, g=50, b=40, pearl_name="Cream", pearl_id=107, archive_id="p1281", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Infernus Classic Purple #351C35", hex="#351C35", full_hex="#351C35AA", r=53, g=28, b=53, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1282", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Infernus Classic Purple #381D38", hex="#381D38", full_hex="#381D38AA", r=56, g=29, b=56, pearl_name="Salmon Pink", pearl_id=136, archive_id="p1283", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="C64 High Roller Red", hex="#501629", full_hex="#501629AA", r=80, g=22, b=41, pearl_name="Rolled Steel", pearl_id=6, archive_id="p1284", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Aston Martin Sunburst Yellow", hex="#9F9114", full_hex="#9F9114AA", r=159, g=145, b=20, pearl_name="Stone Silver", pearl_id=8, archive_id="p1285", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Galaxy Purple Sultan RS", hex="#210718", full_hex="#210718AA", r=33, g=7, b=24, pearl_name="Pfister Pink", pearl_id=137, archive_id="p1286", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Chevy Calypso Cream", hex="#AC9C57", full_hex="#AC9C57AA", r=172, g=156, b=87, pearl_name="Cream", pearl_id=107, archive_id="p1287", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Bright Blue Poly", hex="#003D58", full_hex="#003D58AA", r=0, g=61, b=88, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1288", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GTAForums Blue #06042B", hex="#06042B", full_hex="#06042BAA", r=6, g=4, b=43, pearl_name="Ultra Blue", pearl_id=70, archive_id="p1289", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GTAForums Green #243620", hex="#243620", full_hex="#243620AA", r=36, g=54, b=32, pearl_name="", pearl_id=nil, archive_id="p1290", confidence="ocr-reviewed", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GTAForums Orange #661800", hex="#661800", full_hex="#661800AA", r=102, g=24, b=0, pearl_name="Orange", pearl_id=38, archive_id="p1291", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Verde Pino Attempt", hex="#001D1F", full_hex="#001D1FAA", r=0, g=29, b=31, pearl_name="Gasoline Green", pearl_id=54, archive_id="p1292", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Ferrari Blu Tour de France", hex="#000815", full_hex="#000815AA", r=0, g=8, b=21, pearl_name="Saxon Blue", pearl_id=63, archive_id="p1293", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GTAForums Grey #38352E", hex="#38352E", full_hex="#38352EAA", r=56, g=53, b=46, pearl_name="Cream", pearl_id=107, archive_id="p1294", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Lamborghini Verde Metallizato / Verde Countach", hex="#1D4933", full_hex="#1D4933AA", r=29, g=73, b=51, pearl_name="Worn Green", pearl_id=59, archive_id="p1295", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="GM Citrus Green", hex="#36421A", full_hex="#36421AAA", r=54, g=66, b=26, pearl_name="Bluish Silver", pearl_id=5, archive_id="p1296", confidence="high", is_forum_import=true}
archiveLibrary[#archiveLibrary + 1] = {name="Kryptonite Green (UK: Elbaite Green)", hex="#132E0A", full_hex="#132E0AAA", r=19, g=46, b=10, pearl_name="Bronze", pearl_id=90, archive_id="p1297", confidence="high", is_forum_import=true}
-- duplicate enrichment
-- note: exact existing combinations receive missing metadata instead of a duplicate row.
for _, item in ipairs(archiveLibrary) do
   if tostring(item.hex or ""):upper() == "#070015" and tonumber(item.pearl_id) == 67 then
      item.name = "Epsilon Twilight Blue"
      item.original_finish = "Chrome"
   elseif tostring(item.hex or ""):upper() == "#240719" and tonumber(item.pearl_id) == 137 then
      item.name = "C64 Pfister Pinks Mate"
   end
end

local ARCHIVE_TOTAL_COUNT = #archiveLibrary

-- color credit map
-- note: creator attribution is linked to matching gallery entries when available.
local COLOR_CREDIT_BY_ID = {
   ["p0001"] = {{name="ALLSILENCED", platform="YouTube"}},
   ["p0002"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0009"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0015"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0020"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0022"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0023"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0024"] = {{name="MCMiricle", platform="YouTube"}},
   ["p0025"] = {{name="MCMiricle", platform="YouTube"}},
   ["p0026"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0027"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0028"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0029"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0030"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0031"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0032"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0033"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0034"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0035"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0036"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0037"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0038"] = {{name="DarkRayquaza99", platform="GTAForums"}},
   ["p0039"] = {{name="DarkRayquaza99", platform="GTAForums"}},
   ["p0043"] = {{name="D.B. Cooper", platform="GTAForums"}, {name="ibsmokin", platform="GTAForums"}, {name="JonasPRKL", platform="GTAForums"}},
   ["p0044"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0045"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0046"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0047"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0048"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0049"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0050"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0055"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0057"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0058"] = {{name="LaazrGaming", platform="YouTube"}},
   ["p0059"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0060"] = {{name="Dat Saintsfan", platform="YouTube"}, {name="C64fanatic", platform="GTAForums"}},
   ["p0061"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0062"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0063"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0064"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0065"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0066"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0067"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0070"] = {{name="Kushology", platform="GTAForums"}, {name="Panto Driver", platform="GTAForums"}},
   ["p0071"] = {{name="Kushology", platform="GTAForums"}, {name="Panto Driver", platform="GTAForums"}},
   ["p0073"] = {{name="BeatsDown", platform="GTAForums"}},
   ["p0074"] = {{name="Howi3", platform="GTAForums"}},
   ["p0075"] = {{name="Howi3", platform="GTAForums"}},
   ["p0076"] = {{name="Howi3", platform="GTAForums"}},
   ["p0079"] = {{name="Howi3", platform="GTAForums"}},
   ["p0085"] = {{name="AndrewTfromNZ", platform="GTAForums"}, {name="Panto Driver", platform="GTAForums"}, {name="C64fanatic", platform="GTAForums"}},
   ["p0086"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0090"] = {{name="WreckingColors", platform="GTAForums"}},
   ["p0091"] = {{name="WreckingColors", platform="GTAForums"}},
   ["p0092"] = {{name="idonknowhow", platform="GTAForums"}},
   ["p0093"] = {{name="idonknowhow", platform="GTAForums"}},
   ["p0094"] = {{name="EL_GUAP_OH", platform="YouTube"}},
   ["p0095"] = {{name="EL_GUAP_OH", platform="YouTube"}},
   ["p0100"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0101"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0102"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0103"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0104"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0105"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0106"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0107"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0108"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0109"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0110"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0111"] = {{name="tgutan", platform="YouTube"}},
   ["p0112"] = {{name="tgutan", platform="YouTube"}},
   ["p0113"] = {{name="tgutan", platform="YouTube"}},
   ["p0114"] = {{name="tgutan", platform="YouTube"}},
   ["p0115"] = {{name="tgutan", platform="YouTube"}},
   ["p0116"] = {{name="tgutan", platform="YouTube"}},
   ["p0117"] = {{name="tgutan", platform="YouTube"}},
   ["p0118"] = {{name="tgutan", platform="YouTube"}},
   ["p0119"] = {{name="tgutan", platform="YouTube"}},
   ["p0120"] = {{name="tgutan", platform="YouTube"}},
   ["p0122"] = {{name="robt91", platform="GTAForums"}},
   ["p0123"] = {{name="robt91", platform="GTAForums"}},
   ["p0124"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0125"] = {{name="Ikue Gaming", platform="YouTube"}, {name="IkuesDatabase", platform="YouTube"}},
   ["p0130"] = {{name="tgutan", platform="YouTube"}},
   ["p0131"] = {{name="tgutan", platform="YouTube"}},
   ["p0132"] = {{name="tgutan", platform="YouTube"}},
   ["p0133"] = {{name="tgutan", platform="YouTube"}},
   ["p0134"] = {{name="Aedh", platform="GTAForums"}},
   ["p0135"] = {{name="AlphaSierra111996", platform="GTAForums"}},
   ["p0136"] = {{name="AlphaSierra111996", platform="GTAForums"}},
   ["p0140"] = {{name="enrico italia", platform="YouTube"}},
   ["p0141"] = {{name="enrico italia", platform="YouTube"}},
   ["p0142"] = {{name="enrico italia", platform="YouTube"}},
   ["p0143"] = {{name="enrico italia", platform="YouTube"}},
   ["p0144"] = {{name="enrico italia", platform="YouTube"}},
   ["p0145"] = {{name="enrico italia", platform="YouTube"}},
   ["p0146"] = {{name="enrico italia", platform="YouTube"}},
   ["p0147"] = {{name="enrico italia", platform="YouTube"}},
   ["p0148"] = {{name="enrico italia", platform="YouTube"}},
   ["p0149"] = {{name="enrico italia", platform="YouTube"}},
   ["p0150"] = {{name="enrico italia", platform="YouTube"}},
   ["p0151"] = {{name="enrico italia", platform="YouTube"}},
   ["p0152"] = {{name="enrico italia", platform="YouTube"}},
   ["p0153"] = {{name="enrico italia", platform="YouTube"}},
   ["p0154"] = {{name="enrico italia", platform="YouTube"}},
   ["p0155"] = {{name="enrico italia", platform="YouTube"}},
   ["p0156"] = {{name="enrico italia", platform="YouTube"}},
   ["p0157"] = {{name="enrico italia", platform="YouTube"}},
   ["p0158"] = {{name="enrico italia", platform="YouTube"}},
   ["p0159"] = {{name="enrico italia", platform="YouTube"}},
   ["p0160"] = {{name="enrico italia", platform="YouTube"}},
   ["p0161"] = {{name="enrico italia", platform="YouTube"}},
   ["p0162"] = {{name="enrico italia", platform="YouTube"}},
   ["p0163"] = {{name="Dat Saintsfan", platform="YouTube"}, {name="Fletcher Williamson", platform="YouTube"}},
   ["p0164"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0165"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0166"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0167"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0168"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0169"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0170"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0171"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0172"] = {{name="IkuesDatabase", platform="YouTube"}},
   ["p0173"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0174"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0175"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0176"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0177"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0178"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0179"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0180"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0181"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0182"] = {{name="603 Carnage", platform="YouTube"}},
   ["p0183"] = {{name="MeshaGamingFTW", platform="YouTube"}},
   ["p0184"] = {{name="BADSPORT BILLY [FUCT]", platform="YouTube"}},
   ["p0185"] = {{name="BADSPORT BILLY [FUCT]", platform="YouTube"}},
   ["p0186"] = {{name="BADSPORT BILLY [FUCT]", platform="YouTube"}},
   ["p0187"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0188"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0189"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0190"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0191"] = {{name="Jester's Gaming Vids", platform="YouTube"}},
   ["p0195"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0196"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0197"] = {{name="Valk Games", platform="YouTube"}},
   ["p0198"] = {{name="RiceBowl", platform="YouTube"}},
   ["p0199"] = {{name="RiceBowl", platform="YouTube"}},
   ["p0200"] = {{name="RiceBowl", platform="YouTube"}},
   ["p0201"] = {{name="Cookie d'oh", platform="YouTube"}},
   ["p0202"] = {{name="Tazmanian Fox01", platform="YouTube"}},
   ["p0209"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0212"] = {{name="tgutan", platform="YouTube"}},
   ["p0213"] = {{name="tgutan", platform="YouTube"}},
   ["p0214"] = {{name="tgutan", platform="YouTube"}},
   ["p0215"] = {{name="tgutan", platform="YouTube"}},
   ["p0216"] = {{name="tgutan", platform="YouTube"}},
   ["p0217"] = {{name="tgutan", platform="YouTube"}},
   ["p0218"] = {{name="tgutan", platform="YouTube"}},
   ["p0219"] = {{name="tgutan", platform="YouTube"}},
   ["p0220"] = {{name="tgutan", platform="YouTube"}},
   ["p0221"] = {{name="tgutan", platform="YouTube"}},
   ["p0222"] = {{name="tgutan", platform="YouTube"}},
   ["p0223"] = {{name="tgutan", platform="YouTube"}},
   ["p0224"] = {{name="tgutan", platform="YouTube"}},
   ["p0225"] = {{name="tgutan", platform="YouTube"}},
   ["p0226"] = {{name="tgutan", platform="YouTube"}},
   ["p0227"] = {{name="tgutan", platform="YouTube"}},
   ["p0228"] = {{name="tgutan", platform="YouTube"}},
   ["p0229"] = {{name="tgutan", platform="YouTube"}},
   ["p0230"] = {{name="tgutan", platform="YouTube"}},
   ["p0231"] = {{name="tgutan", platform="YouTube"}},
   ["p0233"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0234"] = {{name="The Gbaby Jr", platform="YouTube"}},
   ["p0235"] = {{name="AceNaut", platform="YouTube"}},
   ["p0236"] = {{name="xiRONiCZZ", platform="YouTube"}},
   ["p0238"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0239"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0240"] = {{name="stargazergaming", platform="YouTube"}},
   ["p0241"] = {{name="Doxive", platform="YouTube"}},
   ["p0242"] = {{name="tgutan", platform="YouTube"}},
   ["p0243"] = {{name="tgutan", platform="YouTube"}},
   ["p0244"] = {{name="tgutan", platform="YouTube"}},
   ["p0245"] = {{name="tgutan", platform="YouTube"}},
   ["p0246"] = {{name="tgutan", platform="YouTube"}},
   ["p0247"] = {{name="tgutan", platform="YouTube"}},
   ["p0248"] = {{name="tgutan", platform="YouTube"}},
   ["p0249"] = {{name="tgutan", platform="YouTube"}},
   ["p0250"] = {{name="tgutan", platform="YouTube"}},
   ["p0251"] = {{name="tgutan", platform="YouTube"}},
   ["p0252"] = {{name="tgutan", platform="YouTube"}},
   ["p0253"] = {{name="tgutan", platform="YouTube"}},
   ["p0254"] = {{name="tgutan", platform="YouTube"}},
   ["p0255"] = {{name="tgutan", platform="YouTube"}},
   ["p0256"] = {{name="tgutan", platform="YouTube"}},
   ["p0257"] = {{name="tgutan", platform="YouTube"}},
   ["p0258"] = {{name="tgutan", platform="YouTube"}},
   ["p0259"] = {{name="tgutan", platform="YouTube"}},
   ["p0260"] = {{name="tgutan", platform="YouTube"}},
   ["p0261"] = {{name="tgutan", platform="YouTube"}},
   ["p0262"] = {{name="tgutan", platform="YouTube"}},
   ["p0263"] = {{name="tgutan", platform="YouTube"}},
   ["p0264"] = {{name="tgutan", platform="YouTube"}},
   ["p0265"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0266"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0267"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0268"] = {{name="Nikki", platform="YouTube"}},
   ["p0269"] = {{name="HyperTideZ", platform="Source"}},
   ["p0270"] = {{name="InBe gaming", platform="YouTube"}},
   ["p0271"] = {{name="Notcher", platform="GTAForums"}},
   ["p0272"] = {{name="Panos VI", platform="GTAForums"}, {name="crazyfrog552", platform="GTAForums"}},
   ["p0273"] = {{name="Panos VI", platform="GTAForums"}, {name="crazyfrog552", platform="GTAForums"}},
   ["p0274"] = {{name="Notcher", platform="GTAForums"}, {name="Panos VI", platform="GTAForums"}},
   ["p0275"] = {{name="Notcher", platform="GTAForums"}, {name="Panos VI", platform="GTAForums"}},
   ["p0277"] = {{name="crazyfrog552", platform="GTAForums"}, {name="Captain Owlfeq", platform="GTAForums"}},
   ["p0278"] = {{name="metoxys", platform="GTAForums"}, {name="supremebape", platform="GTAForums"}},
   ["p0280"] = {{name="TheGamingLegend", platform="YouTube"}},
   ["p0282"] = {{name="ItsMomin", platform="YouTube"}},
   ["p0283"] = {{name="ItsMomin", platform="YouTube"}},
   ["p0284"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0285"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0286"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0287"] = {{name="Neilzie Gaming", platform="YouTube"}},
   ["p0288"] = {{name="Neilzie Gaming", platform="YouTube"}},
   ["p0289"] = {{name="ProThief", platform="YouTube"}},
   ["p0290"] = {{name="Our Clouds", platform="YouTube"}},
   ["p0298"] = {{name="Illusionz", platform="YouTube"}},
   ["p0301"] = {{name="Illusionz", platform="YouTube"}},
   ["p0302"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0308"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0315"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0316"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0317"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0318"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0319"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0320"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0321"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0322"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0324"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0325"] = {{name="enrico italia", platform="YouTube"}},
   ["p0326"] = {{name="enrico italia", platform="YouTube"}},
   ["p0327"] = {{name="Fusionz Gaming", platform="YouTube"}},
   ["p0328"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0329"] = {{name="EL_GUAP_OH", platform="YouTube"}},
   ["p0330"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0331"] = {{name="Kushology", platform="GTAForums"}, {name="TheButtKickerUK", platform="GTAForums"}},
   ["p0332"] = {{name="Kushology", platform="GTAForums"}, {name="TheButtKickerUK", platform="GTAForums"}},
   ["p0334"] = {{name="Phmiller714", platform="GTAForums"}, {name="Quidopher", platform="GTAForums"}},
   ["p0335"] = {{name="AlphaSierra111996", platform="GTAForums"}, {name="Mattoropael", platform="GTAForums"}},
   ["p0338"] = {{name="-SUFF-", platform="GTAForums"}, {name="Eser1985", platform="GTAForums"}, {name="MitchMaliers", platform="GTAForums"}},
   ["p0339"] = {{name="-SUFF-", platform="GTAForums"}, {name="Eser1985", platform="GTAForums"}, {name="MitchMaliers", platform="GTAForums"}},
   ["p0341"] = {{name="Lochstina", platform="GTAForums"}},
   ["p0348"] = {{name="GlitchMasterr", platform="YouTube"}},
   ["p0350"] = {{name="ModernLifeStyle", platform="YouTube"}},
   ["p0351"] = {{name="G4ME_H4CK", platform="YouTube"}},
   ["p0352"] = {{name="ZiaX", platform="YouTube"}},
   ["p0353"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0354"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0355"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0356"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0357"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0358"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0359"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0360"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0361"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0362"] = {{name="Lehi Stones", platform="YouTube"}},
   ["p0364"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0371"] = {{name="tgutan", platform="YouTube"}},
   ["p0372"] = {{name="tgutan", platform="YouTube"}},
   ["p0373"] = {{name="tgutan", platform="YouTube"}},
   ["p0374"] = {{name="tgutan", platform="YouTube"}},
   ["p0375"] = {{name="tgutan", platform="YouTube"}},
   ["p0376"] = {{name="tgutan", platform="YouTube"}},
   ["p0377"] = {{name="tgutan", platform="YouTube"}},
   ["p0380"] = {{name="iROYALHD", platform="YouTube"}},
   ["p0382"] = {{name="LoweCase", platform="YouTube"}},
   ["p0383"] = {{name="I Butts UK", platform="YouTube"}},
   ["p0388"] = {{name="CaptainBackwoods", platform="GTAForums"}, {name="AlphaSierra111996", platform="GTAForums"}, {name="AP2-RADICAL", platform="GTAForums"}},
   ["p0389"] = {{name="CaptainBackwoods", platform="GTAForums"}, {name="AlphaSierra111996", platform="GTAForums"}, {name="AP2-RADICAL", platform="GTAForums"}},
   ["p0391"] = {{name="tgutan", platform="YouTube"}},
   ["p0392"] = {{name="tgutan", platform="YouTube"}},
   ["p0393"] = {{name="tgutan", platform="YouTube"}},
   ["p0397"] = {{name="Inmortal T.M.C", platform="YouTube"}},
   ["p0398"] = {{name="Inmortal T.M.C", platform="YouTube"}},
   ["p0399"] = {{name="Inmortal T.M.C", platform="YouTube"}},
   ["p0400"] = {{name="Inmortal T.M.C", platform="YouTube"}},
   ["p0407"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0409"] = {{name="GlitchMasterr", platform="YouTube"}},
   ["p0410"] = {{name="GlitchMasterr", platform="YouTube"}},
   ["p0411"] = {{name="GlitchMasterr", platform="YouTube"}},
   ["p0412"] = {{name="omgurheadsgone", platform="YouTube"}},
   ["p0413"] = {{name="omgurheadsgone", platform="YouTube"}},
   ["p0414"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0416"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0417"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0418"] = {{name="TOP_NOCH_BAZZIL", platform="YouTube"}},
   ["p0419"] = {{name="TOP_NOCH_BAZZIL", platform="YouTube"}},
   ["p0420"] = {{name="PellyTrolls", platform="YouTube"}},
   ["p0422"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0437"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0438"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0439"] = {{name="KryptonicHD", platform="YouTube"}},
   ["p0441"] = {{name="omgurheadsgone", platform="YouTube"}},
   ["p0442"] = {{name="BazzHazz", platform="YouTube"}},
   ["p0443"] = {{name="BazzHazz", platform="YouTube"}, {name="TOP_NOCH_BAZZIL", platform="YouTube"}},
   ["p0444"] = {{name="TOP_NOCH_BAZZIL", platform="YouTube"}},
   ["p0445"] = {{name="stargazergaming", platform="YouTube"}},
   ["p0451"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0452"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0453"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0454"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0455"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0456"] = {{name="Sidescape Gaming", platform="YouTube"}},
   ["p0471"] = {{name="Aqua", platform="GTAForums"}},
   ["p0488"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0489"] = {{name="Broontango", platform="YouTube"}, {name="Broontango2", platform="YouTube"}},
   ["p0491"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0492"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0493"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0495"] = {{name="SakumeWorksTM", platform="YouTube"}},
   ["p0500"] = {{name="PURPL NINJA75", platform="YouTube"}},
   ["p0501"] = {{name="PURPL NINJA75", platform="YouTube"}},
   ["p0508"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0509"] = {{name="Nikki", platform="YouTube"}},
   ["p0512"] = {{name="imrobertz1", platform="YouTube"}, {name="REBEL EG", platform="YouTube"}},
   ["p0521"] = {{name="-SUFF-", platform="GTAForums"}, {name="1bbaxter", platform="GTAForums"}, {name="Mattoropael", platform="GTAForums"}},
   ["p0522"] = {{name="-Kaas", platform="GTAForums"}},
   ["p0523"] = {{name="xiRONiCZZ", platform="YouTube"}},
   ["p0524"] = {{name="REBEL EG", platform="YouTube"}},
   ["p0532"] = {{name="Dat Saintsfan", platform="YouTube"}},
   ["p0533"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0537"] = {{name="elfoam", platform="GTAForums"}},
   ["p0538"] = {{name="elfoam", platform="GTAForums"}},
   ["p0542"] = {{name="Nikki", platform="YouTube"}},
   ["p0544"] = {{name="Joonas", platform="GTAForums"}},
   ["p0545"] = {{name="Joonas", platform="GTAForums"}},
   ["p0548"] = {{name="Inmortal T.M.C", platform="YouTube"}},
   ["p0551"] = {{name="Ikue Gaming", platform="YouTube"}},
   ["p0552"] = {{name="Ikue Gaming", platform="YouTube"}},
   ["p0559"] = {{name="imrobertz1", platform="YouTube"}},
   ["p0566"] = {{name="Illusionz", platform="YouTube"}, {name="KryptonicHD", platform="YouTube"}},
   ["p0567"] = {{name="Illusionz", platform="YouTube"}, {name="KryptonicHD", platform="YouTube"}},
   ["p0568"] = {{name="Illusionz", platform="YouTube"}, {name="KryptonicHD", platform="YouTube"}},
   ["p0569"] = {{name="Abdel137", platform="YouTube"}},
   ["p0570"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0571"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0572"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0573"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0574"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0575"] = {{name="oXiMo_", platform="YouTube"}},
   ["p0577"] = {{name="Nikki", platform="YouTube"}},
   ["p0584"] = {{name="Panto Driver", platform="GTAForums"}},
   ["p0585"] = {{name="Mattoropael", platform="GTAForums"}},
   ["p0586"] = {{name="Mattoropael", platform="GTAForums"}},
   ["p0587"] = {{name="PURPL NINJA75", platform="YouTube"}},
   ["p0589"] = {{name="Joonas", platform="GTAForums"}, {name="Kurvenflo", platform="GTAForums"}},
   ["p0590"] = {{name="Aqua", platform="GTAForums"}},
   ["p0591"] = {{name="Aqua", platform="GTAForums"}},
   ["p0592"] = {{name="Panto Driver", platform="GTAForums"}},
   ["p0593"] = {{name="Panto Driver", platform="GTAForums"}},
   ["p0600"] = {{name="PURPL NINJA75", platform="YouTube"}},
   ["p0609"] = {{name="Hallow", platform="GTAForums"}},
   ["p0610"] = {{name="Mattoropael", platform="GTAForums"}},
   ["p0611"] = {{name="Mattoropael", platform="GTAForums"}},
   ["p0612"] = {{name="1bbaxter", platform="GTAForums"}, {name="C64fanatic", platform="GTAForums"}},
   ["p0613"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0614"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0615"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0616"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0617"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0618"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0619"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0620"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0621"] = {{name="C64fanatic", platform="GTAForums"}},
   ["p0622"] = {{name="GTAtheGAMER-NL", platform="GTAForums"}},
   ["p0623"] = {{name="Headspin King", platform="YouTube"}},
   ["p0627"] = {{name="xiRONiCZZ", platform="YouTube"}},
   ["p0632"] = {{name="PURPL NINJA75", platform="YouTube"}},
   ["p0633"] = {{name="Barbiee Girl", platform="YouTube"}},
   ["p0635"] = {{name="xiRONiCZZ", platform="YouTube"}},
   ["p0636"] = {{name="xiRONiCZZ", platform="YouTube"}},
   ["p0653"] = {{name="UND3AD GAMING", platform="YouTube"}},
   ["p0656"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0657"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0658"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0659"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0660"] = {{name="KillerFromGods", platform="YouTube"}},
   ["p0661"] = {{name="KillerFromGods", platform="YouTube"}},
}

local COLOR_CREDIT_RECORDS = {
   {name="2FIC GamingHD", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="603 Carnage", platform="YouTube", r=18, g=80, b=32, linked=true, color_name="Creamsicie Orange", hex="#125020", pearl="Yellow", color_count=1, colors={"Creamsicie Orange • #125020 • Yellow pearl"}},
   {name="Abdel137", platform="YouTube", r=204, g=252, b=126, linked=true, color_name="SALUT A TOUS!", hex="#CCFC7E", pearl="", color_count=1, colors={"SALUT A TOUS! • #CCFC7E"}},
   {name="AceNaut", platform="YouTube", r=220, g=20, b=60, linked=true, color_name="Saphire Pink", hex="#DC143C", pearl="", color_count=1, colors={"Saphire Pink • #DC143C"}},
   {name="ALLSILENCED", platform="YouTube", r=39, g=0, b=7, linked=true, color_name="ta", hex="#270007", pearl="", color_count=1, colors={"ta • #270007"}},
   {name="angelinexrocks", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="BADSPORT BILLY [FUCT]", platform="YouTube", r=205, g=204, b=255, linked=true, color_name="Diamond Purple", hex="#CDCCFF", pearl="Ice White", color_count=3, colors={"Diamond Purple • #CDCCFF • Ice White pearl", "BLACK GOLD. • #000000 • DEW YELLOW pearl", "Copperised • #491103 • Orange pearl"}},
   {name="BaracudaPlays", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Barbel Beast", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Barbiee Girl", platform="YouTube", r=0, g=205, b=255, linked=true, color_name="nN", hex="#00CDFF", pearl="", color_count=1, colors={"nN • #00CDFF"}},
   {name="BazzHazz", platform="YouTube", r=14, g=1, b=1, linked=true, color_name="14/1/1 (Classy Red) #", hex="#0E0101", pearl="", color_count=2, colors={"14/1/1 (Classy Red) # • #0E0101", "ANEW • #2B3C58"}},
   {name="BLACK CYBER", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Broontango", platform="YouTube", r=255, g=5, b=63, linked=true, color_name="4) Pink Passion- #", hex="#FF053F", pearl="", color_count=1, colors={"4) Pink Passion- # • #FF053F"}},
   {name="Broontango2", platform="YouTube", r=255, g=5, b=63, linked=true, color_name="4) Pink Passion- #", hex="#FF053F", pearl="", color_count=1, colors={"4) Pink Passion- # • #FF053F"}},
   {name="Cookie d'oh", platform="YouTube", r=255, g=74, b=61, linked=true, color_name="Shiny Salmon", hex="#FF4A3D", pearl="", color_count=1, colors={"Shiny Salmon • #FF4A3D"}},
   {name="Dat Saintsfan", platform="YouTube", r=45, g=98, b=65, linked=true, color_name="ae", hex="#2D6241", pearl="Cream", color_count=26, colors={"ae • #2D6241 • Cream pearl", "Red Venom • #0D000D", "Rosy Red • #FF0303", "Mjstichrom by Kushology • #0A000A • Any pearl", "MIO 9 • #B76E75", "oo • #1E0E0F"}},
   {name="DinomiteFTW", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Doxive", platform="YouTube", r=102, g=102, b=255, linked=true, color_name="Thanks for watching :)", hex="#6666FF", pearl="", color_count=1, colors={"Thanks for watching :) • #6666FF"}},
   {name="Drew Project", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Egzec (ClassicNFS)", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="EL_GUAP_OH", platform="YouTube", r=13, g=0, b=28, linked=true, color_name="ee", hex="#0D001C", pearl="", color_count=3, colors={"ee • #0D001C", "ee • #5A1C0E", "ROSE PINK • #FF5047"}},
   {name="EndingGamertag", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="enrico italia", platform="YouTube", r=81, g=0, b=21, linked=true, color_name="1.FARBE", hex="#510015", pearl="", color_count=25, colors={"1.FARBE • #510015", "10.FARBE • #080013", "11.FARBE • #5B57FF", "2.FARBE • #879F00", "3.FARBE • #D40015", "4.FARBE • #3F008C"}},
   {name="Fletcher Williamson", platform="YouTube", r=127, g=240, b=254, linked=true, color_name="by Fletcher Williamson", hex="#7FF0FE", pearl="Ice White", color_count=1, colors={"by Fletcher Williamson • #7FF0FE • Ice White pearl"}},
   {name="Fusionz Gaming", platform="YouTube", r=40, g=0, b=96, linked=true, color_name="ibyIkue", hex="#280060", pearl="", color_count=1, colors={"ibyIkue • #280060"}},
   {name="G4ME_H4CK", platform="YouTube", r=35, g=127, b=255, linked=true, color_name="Pale Green", hex="#237FFF", pearl="", color_count=1, colors={"Pale Green • #237FFF"}},
   {name="GlitchMasterr", platform="YouTube", r=67, g=67, b=145, linked=true, color_name="Adder", hex="#434391", pearl="", color_count=4, colors={"Adder • #434391", "Cc. • #00FA9A", "He • #0505FF", "Shiny Blue • #0505FF"}},
   {name="Golden Mei", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Headspin King", platform="YouTube", r=59, g=59, b=69, linked=true, color_name="REAL-LIFE", hex="#3B3B45", pearl="Diamond Blue", color_count=1, colors={"REAL-LIFE • #3B3B45 • Diamond Blue pearl"}},
   {name="I Butts UK", platform="YouTube", r=19, g=0, b=47, linked=true, color_name="SHEN: #", hex="#13002F", pearl="france", color_count=1, colors={"SHEN: # • #13002F • france pearl"}},
   {name="Ikue Gaming", platform="YouTube", r=81, g=0, b=21, linked=true, color_name="WEED", hex="#510015", pearl="", color_count=19, colors={"WEED • #510015", "alll 6 • #290026", "X X THREE • #0A0025 • Yellow pearl", "FOUNDER mut Gani • #5B575F", "Liked videos • #5B57FF", "ACE YELLOW • #090022 • Race Yellow pearl"}},
   {name="IkuesDatabase", platform="YouTube", r=10, g=0, b=37, linked=true, color_name="X X THREE", hex="#0A0025", pearl="Yellow", color_count=34, colors={"X X THREE • #0A0025 • Yellow pearl", "FOUNDER mut Gani • #5B575F", "Liked videos • #5B57FF", "ACE YELLOW • #090022 • Race Yellow pearl", "KDES DATABASE • #090022", "IN' BLUE • #039AFF"}},
   {name="Illusionz", platform="YouTube", r=64, g=124, b=132, linked=true, color_name="Ri", hex="#407C84", pearl="", color_count=5, colors={"Ri • #407C84", "Ri • #DE3036", "Ri • #E62020", "1) Atlantis Blue • #002841 • Ultra Blue pearl", "Joker Green • #029939"}},
   {name="imrobertz1", platform="YouTube", r=255, g=219, b=112, linked=true, color_name="Bleached Banana", hex="#FFDB70", pearl="", color_count=20, colors={"Bleached Banana • #FFDB70", "GLACIERS OF ICE • #77FFC9", "Frost-Blue-Grey-Blue & • #122C3C • Ice White pearl", "WASH-ARMY-GREEN • #95B083 • Frost White pearl", "PP-PASTEL-PURPLE • #B19CD9 • Ultra blue pearl", "PP-PASTEL-PINK • #FFD1DC • Bright Purple pearl"}},
   {name="InBe gaming", platform="YouTube", r=255, g=153, b=102, linked=true, color_name="bas", hex="#FF9966", pearl="", color_count=1, colors={"bas • #FF9966"}},
   {name="Inmortal T.M.C", platform="YouTube", r=255, g=47, b=36, linked=true, color_name="RRR RR RRR", hex="#FF2F24", pearl="", color_count=5, colors={"RRR RR RRR • #FF2F24", "Emerald Green • #34996A • lime green pearl", "Garnet Purple • #590599 • hot pink pearl", "Super Pink • #990237 • Ice White pearl", "hit the like button and look out for more • #FF0030"}},
   {name="iROYALHD", platform="YouTube", r=249, g=82, b=107, linked=true, color_name="AM", hex="#F9526B", pearl="", color_count=1, colors={"AM • #F9526B"}},
   {name="ItsMomin", platform="YouTube", r=235, g=156, b=65, linked=true, color_name="PC GAMEPLAY!", hex="#EB9C41", pearl="", color_count=2, colors={"PC GAMEPLAY! • #EB9C41", "Al • #BBEB2A"}},
   {name="Jester's Gaming Vids", platform="YouTube", r=142, g=235, b=3, linked=true, color_name="Chromatix Cash", hex="#8EEB03", pearl="", color_count=9, colors={"Chromatix Cash • #8EEB03", "Charmander • #F5652E • Creme pearl", "Wigglytuff • #FF739F • Salmon Pink pearl", "Light Sky Blue • #7FDFFF", "NEVADA SAND • #FFA875", "Chromatix Amethyst • #520299 • Salmon Pink pearl"}},
   {name="K1LLA Gaming PS", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Kately Risley", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="KillerFromGods", platform="YouTube", r=0, g=16, b=21, linked=true, color_name="Cool Bean", hex="#001015", pearl="Gasoline Green", color_count=9, colors={"Cool Bean • #001015 • Gasoline Green pearl", "Batman Steel • #0A0A0F • Diamond Blue pearl", "Shadow • #0A0813 • Ice White pearl", "Pale Green • #ACFF8A • Ice White pearl", "Gods Blue • #001831 • Ice White pearl", "Horny Red • #310000 • Salmon Pink pearl"}},
   {name="KillShotSplash", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="KryptonicHD", platform="YouTube", r=64, g=124, b=132, linked=true, color_name="Ri", hex="#407C84", pearl="", color_count=20, colors={"Ri • #407C84", "Ri • #DE3036", "Ri • #E62020", "MRYPTONICHO • #1AC0F5", "HE • #0496CF", "Solid • #0496CF"}},
   {name="LaazrGaming", platform="YouTube", r=197, g=41, b=67, linked=true, color_name="Dragon Fruit Pink", hex="#C52943", pearl="Race Yellow", color_count=1, colors={"Dragon Fruit Pink • #C52943 • Race Yellow pearl"}},
   {name="Landon Childers", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Lehi Stones", platform="YouTube", r=30, g=45, b=52, linked=true, color_name="Balticblau 1982 BM", hex="#1E2D34", pearl="", color_count=10, colors={"Balticblau 1982 BM • #1E2D34", "lose Quartz • #352225", "Random Diamond Blue • #21323D • iBlue pearl", "Cool • #8BACBC", "holo Gang Sabre • #E1E168", "Copper Orange • #260D02 • Pink pearl"}},
   {name="LoweCase", platform="YouTube", r=255, g=216, b=89, linked=true, color_name="SUBSCRIBE", hex="#FFD859", pearl="", color_count=1, colors={"SUBSCRIBE • #FFD859"}},
   {name="MCMiricle", platform="YouTube", r=236, g=255, b=140, linked=true, color_name="Bleak Banana", hex="#ECFF8C", pearl="", color_count=2, colors={"Bleak Banana • #ECFF8C", "Pale Pink • #FF8282"}},
   {name="MeshaGamingFTW", platform="YouTube", r=113, g=166, b=210, linked=true, color_name="Ne", hex="#71A6D2", pearl="", color_count=1, colors={"Ne • #71A6D2"}},
   {name="Miricle", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="ModernLifeStyle", platform="YouTube", r=10, g=221, b=37, linked=true, color_name="all! 2", hex="#0ADD25", pearl="", color_count=1, colors={"all! 2 • #0ADD25"}},
   {name="MrBossFTW", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Neilzie Gaming", platform="YouTube", r=81, g=32, b=63, linked=true, color_name="0 AM", hex="#51203F", pearl="", color_count=2, colors={"0 AM • #51203F", "Ome. • #512A3F"}},
   {name="Nick van Dutch", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Nikki", platform="YouTube", r=49, g=48, b=54, linked=true, color_name="ELEANOR GRAY", hex="#313036", pearl="Frost White", color_count=4, colors={"ELEANOR GRAY • #313036 • Frost White pearl", "EX: 1 • #D86CD8 • Diamond Blue pearl", "CELADON GREEN • #4B8267 • Sandy Brown pearl", "ELECTRIC PLUM • #FF824C • Salmon Pink pearl"}},
   {name="ObeseGiraffe", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="omgurheadsgone", platform="YouTube", r=58, g=0, b=100, linked=true, color_name="Bubble-GumpPurple", hex="#3A0064", pearl="", color_count=3, colors={"Bubble-GumpPurple • #3A0064", "BE • #003A64", "mk • #0A001C"}},
   {name="Our Clouds", platform="YouTube", r=227, g=190, b=70, linked=true, color_name="Banana Splig=", hex="#E3BE46", pearl="", color_count=1, colors={"Banana Splig= • #E3BE46"}},
   {name="oXiMo_", platform="YouTube", r=0, g=2, b=15, linked=true, color_name="BLUs [Rent", hex="#00020F", pearl="", color_count=14, colors={"BLUs [Rent • #00020F", "Go • #080D1E", "SS • #050618", "YOLO RED • #57001E • Torino Red pearl", "BROWN (PERS • #20000A", "PED Gt OUSURDY KELLER # \\SNOCRA • #1A010C"}},
   {name="PacPacBoy", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="PellyTrolls", platform="YouTube", r=255, g=0, b=35, linked=true, color_name="Guide", hex="#FF0023", pearl="Torino Red", color_count=1, colors={"Guide • #FF0023 • Torino Red pearl"}},
   {name="ProThief", platform="YouTube", r=127, g=255, b=144, linked=true, color_name="LIME GREEN | #UNIQUEGLITCHING", hex="#7FFF90", pearl="", color_count=1, colors={"LIME GREEN | #UNIQUEGLITCHING • #7FFF90"}},
   {name="PURPL NINJA75", platform="YouTube", r=47, g=43, b=59, linked=true, color_name="AUTUMN - ORCHID PURPLE", hex="#2F2B3B", pearl="Salmon Pink", color_count=5, colors={"AUTUMN - ORCHID PURPLE • #2F2B3B • Salmon Pink pearl", "NEON YELLOW • #FFFF30 • Ice White pearl", "KNIFE NATION BLOOD ORANGE • #491103 • ORANGE pearl", "WHY SO SERIOUS PINK • #19000A • HOT PINK pearl", "ROSE PINK • #FF053F • Ice White pearl"}},
   {name="RandomFutGamer", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="REBEL EG", platform="YouTube", r=255, g=219, b=112, linked=true, color_name="Bleached Banana", hex="#FFDB70", pearl="", color_count=2, colors={"Bleached Banana • #FFDB70", "Dream • #2937FF"}},
   {name="RiceBowl", platform="YouTube", r=0, g=0, b=238, linked=true, color_name="Pinky Pink", hex="#0000EE", pearl="", color_count=3, colors={"Pinky Pink • #0000EE", "Sunshine Orange • #FF0753", "Sunshine Orange • #FF4203"}},
   {name="RODGERSBOY", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="SakumeWorksTM", platform="YouTube", r=124, g=106, b=58, linked=true, color_name="Anew", hex="#7C6A3A", pearl="", color_count=1, colors={"Anew • #7C6A3A"}},
   {name="Sidescape Gaming", platform="YouTube", r=255, g=102, b=0, linked=true, color_name="Blazing Orange - #", hex="#FF6600", pearl="", color_count=6, colors={"Blazing Orange - # • #FF6600", "Dahilia Orange - # • #FF9F7F • Ice White pearl", "Neon Orange - # • #FF2A12", "Pastel Orange - # • #FFCC99", "Peach Sunrise - # • #FF4E50 • Ice White pearl", "Blue Pastel • #577EA0 • Cream pearl"}},
   {name="Skinny P Productions", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="stargazergaming", platform="YouTube", r=0, g=250, b=154, linked=true, color_name="THE END OF THE YEAR/2017. YOU CAN MAKE IT", hex="#00FA9A", pearl="", color_count=2, colors={"THE END OF THE YEAR/2017. YOU CAN MAKE IT • #00FA9A", "PSN ID : | neighbour222 • #8470FF"}},
   {name="TacticalSuiZiDE", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Tazmanian Fox01", platform="YouTube", r=157, g=153, b=188, linked=true, color_name="Purple Haze", hex="#9D99BC", pearl="", color_count=1, colors={"Purple Haze • #9D99BC"}},
   {name="tgutan", platform="YouTube", r=21, g=0, b=0, linked=true, color_name="Antique Varnish Red", hex="#150000", pearl="Sunrise Orange", color_count=67, colors={"Antique Varnish Red • #150000 • Sunrise Orange pearl", "Perfect Purple • #1B0026 • Ice White pearl", "Presidential Blue • #01131E • Ultra Blue pearl", "Silver Green • #002011 • Ice White pearl", "GTAS • #3AA013 • Yellow pearl", "GTAS • #C4AF3B"}},
   {name="The Gbaby Jr", platform="YouTube", r=255, g=85, b=76, linked=true, color_name="Showing off an amzing", hex="#FF554C", pearl="", color_count=1, colors={"Showing off an amzing • #FF554C"}},
   {name="TheGamingLegend", platform="YouTube", r=255, g=161, b=67, linked=true, color_name="WEON CARROTTM", hex="#FFA143", pearl="", color_count=1, colors={"WEON CARROTTM • #FFA143"}},
   {name="Toe Venom", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="TOP_NOCH_BAZZIL", platform="YouTube", r=43, g=60, b=88, linked=true, color_name="ANEW", hex="#2B3C58", pearl="", color_count=4, colors={"ANEW • #2B3C58", "amazing!!!!! • #5A2C00", "Creator: TOP_LNOCH_BAZZIL • #744FD0", "MEX(: # • #744F0D"}},
   {name="UND3AD GAMING", platform="YouTube", r=18, g=44, b=60, linked=true, color_name="Se", hex="#122C3C", pearl="", color_count=1, colors={"Se • #122C3C"}},
   {name="Valk Games", platform="YouTube", r=255, g=0, b=0, linked=true, color_name="1AM", hex="#FF0000", pearl="", color_count=1, colors={"1AM • #FF0000"}},
   {name="Vorzaa", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="watch dogs", platform="YouTube", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="xiRONiCZZ", platform="YouTube", r=118, g=118, b=153, linked=true, color_name="ELECTRIC GREY - #", hex="#767699", pearl="", color_count=5, colors={"ELECTRIC GREY - # • #767699", "G-REDDY GREEN • #000604", "Zion Cabrio - G-REDDY GREEN (by xiRoNiCzZ) • #000604 • Gasoline Green pearl", "PiONEER PEACH - # • #F7786B", "FuSiON GREEN - # • #CAFF7F"}},
   {name="ZiaX", platform="YouTube", r=100, g=255, b=100, linked=true, color_name="47 AM", hex="#64FF64", pearl="", color_count=1, colors={"47 AM • #64FF64"}},
   {name="-Kaas", platform="GTAForums", r=23, g=9, b=63, linked=true, color_name="KRAZE", hex="#17093F", pearl="Ultra Blue", color_count=1, colors={"KRAZE • #17093F • Ultra Blue pearl"}},
   {name="-SUFF-", platform="GTAForums", r=64, g=84, b=124, linked=true, color_name="Aweek ago", hex="#40547C", pearl="Frost", color_count=3, colors={"Aweek ago • #40547C • Frost pearl", "SUFF • #4E0825 • Salmon Pink pearl", "f 17 Jun 2016 • #2B5540 • Frost White pearl"}},
   {name="1bbaxter", platform="GTAForums", r=64, g=84, b=124, linked=true, color_name="Aweek ago", hex="#40547C", pearl="Frost", color_count=2, colors={"Aweek ago • #40547C • Frost pearl", "3 weeks ago • #092A13 • Gasoline Green pearl"}},
   {name="Aedh", platform="GTAForums", r=13, g=3, b=4, linked=true, color_name="CER Uge", hex="#0D0304", pearl="Salmon Pink", color_count=1, colors={"CER Uge • #0D0304 • Salmon Pink pearl"}},
   {name="AlphaSierra111996", platform="GTAForums", r=36, g=100, b=129, linked=true, color_name="Give one of these a try. | forgot which one it is, but", hex="#246481", pearl="", color_count=5, colors={"Give one of these a try. | forgot which one it is, but • #246481", "Give one of these a try. | forgot which one it is, but • #43A5F0", "Very-inaccurate Bleu de France (# • #318CE7", "Kustom • #0A1A29", "ef • #160118 • Schafter Purple pearl"}},
   {name="AndrewTfromNZ", platform="GTAForums", r=255, g=30, b=0, linked=true, color_name="22 Sep 2016", hex="#FF1E00", pearl="", color_count=1, colors={"22 Sep 2016 • #FF1E00"}},
   {name="AP2-RADICAL", platform="GTAForums", r=10, g=26, b=41, linked=true, color_name="Kustom", hex="#0A1A29", pearl="", color_count=2, colors={"Kustom • #0A1A29", "ef • #160118 • Schafter Purple pearl"}},
   {name="Aqua", platform="GTAForums", r=23, g=130, b=158, linked=true, color_name="the Comet RC", hex="#17829E", pearl="no", color_count=3, colors={"the Comet RC • #17829E • no pearl", "tone for the Elegy RH8 • #68817A • Ice White pearl", "AQUA MARINE • #002C3A • GASOLINE GREEN pearl"}},
   {name="Baldbigfoot", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Barrv ><>", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="BeatsDown", platform="GTAForums", r=23, g=13, b=59, linked=true, color_name="Time for a", hex="#170D3B", pearl="", color_count=1, colors={"Time for a • #170D3B"}},
   {name="C64fanatic", platform="GTAForums", r=9, g=42, b=19, linked=true, color_name="3 weeks ago", hex="#092A13", pearl="Gasoline Green", color_count=12, colors={"3 weeks ago • #092A13 • Gasoline Green pearl", "gtaforums.com • #501629 • Steel pearl", "C64Fanatic's Guacamole Green • #49532D • Silver pearl", "C64 Fanatic's Seven 70 Golden Mist • #2B2621 • Cream pearl", "C64 Fanatic's Double Roast Brown • #140907", "BA 21913:05.AM, • #A7B4C6 • Blue pearl"}},
   {name="Captain Owlfeq", platform="GTAForums", r=18, g=7, b=14, linked=true, color_name="7 Me.", hex="#12070E", pearl="salmon pine", color_count=1, colors={"7 Me. • #12070E • salmon pine pearl"}},
   {name="CaptainBackwoods", platform="GTAForums", r=10, g=26, b=41, linked=true, color_name="Kustom", hex="#0A1A29", pearl="", color_count=2, colors={"Kustom • #0A1A29", "ef • #160118 • Schafter Purple pearl"}},
   {name="crazyfrog552", platform="GTAForums", r=72, g=102, b=102, linked=true, color_name="Sa", hex="#486666", pearl="", color_count=3, colors={"Sa • #486666", "os • #545246 • vor taxi alles pearl", "7 Me. • #12070E • salmon pine pearl"}},
   {name="D.B. Cooper", platform="GTAForums", r=60, g=94, b=95, linked=true, color_name="Zentorno Tame Teal Pearl (Ice White pearlescent)", hex="#3C5E5F", pearl="Zentorno Tame Teal", color_count=1, colors={"Zentorno Tame Teal Pearl (Ice White pearlescent) • #3C5E5F • Zentorno Tame Teal pearl"}},
   {name="DarkRayquaza99", platform="GTAForums", r=123, g=58, b=0, linked=true, color_name="Unnamed #7B3A00", hex="#7B3A00", pearl="", color_count=2, colors={"Unnamed #7B3A00 • #7B3A00", "SS • #0C0B28"}},
   {name="ddarko12", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="DiscoPanda", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="elfoam", platform="GTAForums", r=13, g=3, b=4, linked=true, color_name="SS)", hex="#0D0304", pearl="Salmon Pink", color_count=2, colors={"SS) • #0D0304 • Salmon Pink pearl", "SS) • #29606F • Ice White pearl"}},
   {name="Eser1985", platform="GTAForums", r=78, g=8, b=37, linked=true, color_name="SUFF", hex="#4E0825", pearl="Salmon Pink", color_count=2, colors={"SUFF • #4E0825 • Salmon Pink pearl", "f 17 Jun 2016 • #2B5540 • Frost White pearl"}},
   {name="gglenn1966", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="GTAtheGAMER-NL", platform="GTAForums", r=19, g=39, b=99, linked=true, color_name="132763FEF", hex="#132763", pearl="", color_count=1, colors={"132763FEF • #132763"}},
   {name="Hallow", platform="GTAForums", r=40, g=65, b=87, linked=true, color_name="JASDF Oceanic base (Mr. Hobby C374", hex="#284157", pearl="what", color_count=1, colors={"JASDF Oceanic base (Mr. Hobby C374 • #284157 • what pearl"}},
   {name="Howi3", platform="GTAForums", r=63, g=85, b=47, linked=true, color_name="F620 Appletree Green (Cream pearlescent)", hex="#3F552F", pearl="Cast Iron Silver", color_count=4, colors={"F620 Appletree Green (Cream pearlescent) • #3F552F • Cast Iron Silver pearl", "Khamelion Lotus Magenta (Ice White pearlescent) • #332130 • Cream pearl", "Massacro Diavolo Red (Cast Iron Silver pearlescent) • #511515 • Cast Iron Silver pearl", "Luxury Champagne • #E7C898 • Pure Gold pearl"}},
   {name="HyperTideZ", platform="Source", r=255, g=65, b=5, linked=true, color_name="Instrumental by Nimbus Beats", hex="#FF4105", pearl="", color_count=1, colors={"Instrumental by Nimbus Beats • #FF4105"}},
   {name="ibsmokin", platform="GTAForums", r=60, g=94, b=95, linked=true, color_name="Zentorno Tame Teal Pearl (Ice White pearlescent)", hex="#3C5E5F", pearl="Zentorno Tame Teal", color_count=1, colors={"Zentorno Tame Teal Pearl (Ice White pearlescent) • #3C5E5F • Zentorno Tame Teal pearl"}},
   {name="idonknowhow", platform="GTAForums", r=19, g=23, b=43, linked=true, color_name="a Pe", hex="#13172B", pearl="Light Blue", color_count=2, colors={"a Pe • #13172B • Light Blue pearl", "rd • #22202E"}},
   {name="JonasPRKL", platform="GTAForums", r=60, g=94, b=95, linked=true, color_name="Zentorno Tame Teal Pearl (Ice White pearlescent)", hex="#3C5E5F", pearl="Zentorno Tame Teal", color_count=1, colors={"Zentorno Tame Teal Pearl (Ice White pearlescent) • #3C5E5F • Zentorno Tame Teal pearl"}},
   {name="Joonas", platform="GTAForums", r=0, g=59, b=92, linked=true, color_name="Chevrolet Le Mans Blue Metallic", hex="#003B5C", pearl="light blue", color_count=3, colors={"Chevrolet Le Mans Blue Metallic • #003B5C • light blue pearl", "I TL • #CFC0A5", "omens • #CFC0A5"}},
   {name="JR Death", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Kurvenflo", platform="GTAForums", r=0, g=59, b=92, linked=true, color_name="Chevrolet Le Mans Blue Metallic", hex="#003B5C", pearl="light blue", color_count=1, colors={"Chevrolet Le Mans Blue Metallic • #003B5C • light blue pearl"}},
   {name="Kushology", platform="GTAForums", r=59, g=0, b=27, linked=true, color_name="dl", hex="#3B001B", pearl="Hot Pink", color_count=4, colors={"dl • #3B001B • Hot Pink pearl", "oy • #BE64BE", "io • #2F2B3B", "os • #14397F"}},
   {name="Kusholov", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Lochstina", platform="GTAForums", r=56, g=53, b=46, linked=true, color_name="Kustom", hex="#38352E", pearl="", color_count=1, colors={"Kustom • #38352E"}},
   {name="Mattoropael", platform="GTAForums", r=64, g=84, b=124, linked=true, color_name="Aweek ago", hex="#40547C", pearl="Frost", color_count=6, colors={"Aweek ago • #40547C • Frost pearl", "FS 36231 (# • #494D50 • and no pearl", "Kustom • #788D12 • Yellow pearl", "FS 34079 US Army/Marines Forest Green • #272A22 • Showcased in Matte with Dark Steel pearl", "ry • #5D686F • Showcased in Matte with Dark Steel pearl", "Very-inaccurate Bleu de France (# • #318CE7"}},
   {name="metoxvs", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="metoxys", platform="GTAForums", r=10, g=20, b=6, linked=true, color_name="ees", hex="#0A1406", pearl="", color_count=1, colors={"ees • #0A1406"}},
   {name="Midnight Vibes", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="MitchMaliers", platform="GTAForums", r=78, g=8, b=37, linked=true, color_name="SUFF", hex="#4E0825", pearl="Salmon Pink", color_count=2, colors={"SUFF • #4E0825 • Salmon Pink pearl", "f 17 Jun 2016 • #2B5540 • Frost White pearl"}},
   {name="MrMet4", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Notcher", platform="GTAForums", r=248, g=74, b=56, linked=true, color_name="Bloody Peach (created by Notcher)", hex="#F84A38", pearl="", color_count=3, colors={"Bloody Peach (created by Notcher) • #F84A38", "at 7 • #3F353E", "oo • #6B663C"}},
   {name="Panos VI", platform="GTAForums", r=72, g=102, b=102, linked=true, color_name="Sa", hex="#486666", pearl="", color_count=4, colors={"Sa • #486666", "os • #545246 • vor taxi alles pearl", "at 7 • #3F353E", "oo • #6B663C"}},
   {name="Panto Driver", platform="GTAForums", r=18, g=15, b=18, linked=true, color_name="io", hex="#120F12", pearl="Spinnaker Purple", color_count=6, colors={"io • #120F12 • Spinnaker Purple pearl", "Convertible • #3E282C • Salmon Pink pearl", "Here's my Picador in Nassau Blue Metallic • #18374D • surf blue pearl", "dl • #3B001B • Hot Pink pearl", "oy • #BE64BE", "22 Sep 2016 • #FF1E00"}},
   {name="Phmiller714", platform="GTAForums", r=8, g=15, b=9, linked=true, color_name="ee", hex="#080F09", pearl="", color_count=1, colors={"ee • #080F09"}},
   {name="Plage", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="Quidopher", platform="GTAForums", r=8, g=15, b=9, linked=true, color_name="ee", hex="#080F09", pearl="", color_count=1, colors={"ee • #080F09"}},
   {name="robt91", platform="GTAForums", r=48, g=3, b=5, linked=true, color_name="DARK VOLCANO ORANGE - #", hex="#300305", pearl="", color_count=2, colors={"DARK VOLCANO ORANGE - # • #300305", "LIGHT VOLCANO ORANGE - # • #551100"}},
   {name="Schuimruim", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="supremebape", platform="GTAForums", r=10, g=20, b=6, linked=true, color_name="ees", hex="#0A1406", pearl="", color_count=1, colors={"ees • #0A1406"}},
   {name="TheButtKickerUK", platform="GTAForums", r=47, g=43, b=59, linked=true, color_name="io", hex="#2F2B3B", pearl="", color_count=2, colors={"io • #2F2B3B", "os • #14397F"}},
   {name="wizooord", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
   {name="WreckingColors", platform="GTAForums", r=16, g=30, b=7, linked=true, color_name="Unfortunately, | did not record the base for this", hex="#101E07", pearl="", color_count=2, colors={"Unfortunately, | did not record the base for this • #101E07", "experiment, but it is likely either # • #0D1603"}},
   {name="xInfamousRYANx", platform="GTAForums", r=160, g=160, b=168, linked=false, color_name="", hex="", pearl="", color_count=0, colors={}},
}

local function GetArchiveColorCredits(item)
   if not item or not item.archive_id then return nil end
   return COLOR_CREDIT_BY_ID[tostring(item.archive_id)]
end

local ARCHIVE_IN_GAME_PEARL_COUNT = 0
for _, item in ipairs(archiveLibrary) do
   local hasConfirmedPearl = item.pearl_id ~= nil
      and item.name and item.name ~= ""
      and (tostring(item.confidence or "") == "high" or item.is_exotic == true)
   if hasConfirmedPearl then ARCHIVE_IN_GAME_PEARL_COUNT = ARCHIVE_IN_GAME_PEARL_COUNT + 1 end
end

-- ordered around the color wheel, beginning with pink.
local archiveFamilyOrder = {
   "Exotic", "Ai", "Remix",
   "Pink & Magenta", "Red", "Orange", "Yellow & Gold", "Green",
   "Cyan & Teal", "Blue", "Purple & Violet", "Brown & Tan",
   "White & Cream", "Gray & Silver", "Black & Dark"
}
local archiveFamilyRank = {}
for i, name in ipairs(archiveFamilyOrder) do archiveFamilyRank[name] = i end
local archiveColorFamilies = {"All", "Favorites", "Gradient"}
for _, name in ipairs(archiveFamilyOrder) do archiveColorFamilies[#archiveColorFamilies + 1] = name end
local archiveBrightnessOrders = {
   "Brightest → Darkest",
   "Darkest → Brightest",
   "Natural Hue (Grouped)",
   "Red → Violet",
   "Violet → Red",
   "Most Saturated",
   "Least Saturated",
   "Darks Only",
   "Lights Only",
   "Midtones Only",
   "Name A → Z",
   "Name Z → A"
}

local function ArchiveRgbToHsv(r, g, b)
   r, g, b = (tonumber(r) or 0) / 255, (tonumber(g) or 0) / 255, (tonumber(b) or 0) / 255
   local mx, mn = math.max(r, g, b), math.min(r, g, b)
   local d = mx - mn
   local h = 0
   if d ~= 0 then
      if mx == r then h = (60 * (((g - b) / d) % 6))
      elseif mx == g then h = 60 * (((b - r) / d) + 2)
      else h = 60 * (((r - g) / d) + 4) end
   end
   local s = mx == 0 and 0 or d / mx
   return h % 360, s, mx
end

local function ClassifyArchiveColor(item)
   local h, s, v = ArchiveRgbToHsv(item.r, item.g, item.b)
   item._hue = h

   -- neutrals first. very dark saturated paints remain in their hue family so
   -- deep reds/blues are not all dumped into black & dark.
   if v <= 0.10 and s <= 0.42 then return "Black & Dark" end
   if s <= 0.10 then
      if v >= 0.88 then return "White & Cream" end
      if v <= 0.20 then return "Black & Dark" end
      return "Gray & Silver"
   end
   if v >= 0.90 and s <= 0.22 then return "White & Cream" end

   -- dark, earthy oranges/yellows are more useful under brown & tan.
   if h >= 14 and h < 52 and v < 0.68 and (s < 0.82 or v < 0.42) then return "Brown & Tan" end

   if h >= 315 and h < 345 then return "Pink & Magenta" end
   if h >= 345 or h < 15 then
      if v >= 0.70 and s <= 0.52 then return "Pink & Magenta" end
      return "Red"
   end
   if h < 45 then return "Orange" end
   if h < 70 then return "Yellow & Gold" end
   if h < 165 then return "Green" end
   if h < 195 then return "Cyan & Teal" end
   if h < 270 then return "Blue" end
   if h < 315 then return "Purple & Violet" end
   return "Pink & Magenta"
end

local archiveFavoritesPath = presetPath .. "favorites.txt"
local archiveFavorites = {}
local archiveDefaultsMarkerPath = presetPath .. "defaults_build010_seeded.txt"
local DEFAULTS_SEED_ID = "build010-default-favorites-exotic-v2"
local defaultFavoriteKeys = {
   "p0425",
   "p0490",
   "p0493",
   "p0522",
   "p0528",
   "p0529",
   "p0530",
   "p0541",
   "p0596",
   "p0598",
   "p0603",
   "p0606",
   "p0607",
   "p0626",
   "p0627",
   "p0630",
   "p0660",
   "p0296",
   "p0297",
   "p0302",
   "p0303",
   "p0308",
   "p0315",
   "p0316",
   "p0317",
   "p0318",
   "p0319",
   "p0320",
   "p0321",
   "p0322",
   "p0366",
   "p0367",
   "p0368",
   "p0374",
   "p0375",
   "p0203",
   "p0204",
   "p0233",
   "p0194",
   "p0195",
   "p0127",
   "p0185",
   "p0130",
   "p0131",
   "p0132",
   "p0133",
   "p0026",
   "p0029",
   "p0030",
   "p0048",
   "p0049",
   "p0055",
   "p0242",
   "p0256",
   "p0257",
   "p0258",
   "p0259",
   "p0260",
   "p0261",
   "p0262",
   "p0111",
}
local builtinExoticFavoriteKeys = {
   "p0662",
   "p0663",
   "p0664",
   "p0665",
   "p0666",
   "p0667",
   "p0668",
}


local legacyFavoriteIds = {
   [1821651] = {"p0407"},
   [5101513] = {"p1109"},
   [9327675] = {"p0506"},
   [13393104] = {"p0705"},
   [15005487] = {"p0927"},
   [16855638] = {"p1085"},
   [17488588] = {"p0983"},
   [21863940] = {"p0955"},
   [22496465] = {"p0821"},
   [25710520] = {"p0484", "p0485"},
   [28177161] = {"p0537", "p0538"},
   [30714398] = {"p0182"},
   [33849857] = {"p0857"},
   [34039856] = {"p0577"},
   [34212715] = {"p0019"},
   [34990632] = {"p0180"},
   [36501442] = {"p0127"},
   [36552100] = {"p0384", "p0385", "p0386", "p0387"},
   [39783907] = {"p1193", "p1194"},
   [42795431] = {"p0263", "p0264"},
   [43642900] = {"p0055"},
   [52423381] = {"p0281"},
   [64533428] = {"p0526"},
   [66263360] = {"p0390"},
   [67069869] = {"p0775"},
   [70916118] = {"p1106"},
   [73339145] = {"p1192"},
   [73486240] = {"p1209"},
   [73989505] = {"p0086"},
   [77140181] = {"p0543"},
   [77735003] = {"p0499"},
   [90116764] = {"p1197"},
   [94816812] = {"p0686"},
   [95656809] = {"p1163"},
   [100814677] = {"p1061"},
   [100934807] = {"p0307"},
   [103634498] = {"p0882"},
   [107041478] = {"p1207", "p1208"},
   [111055171] = {"p0940"},
   [123672002] = {"p1196"},
   [126610766] = {"p0599"},
   [136499907] = {"p0812"},
   [137958227] = {"p0115", "p0116"},
   [138103395] = {"p0195"},
   [140449621] = {"p1195"},
   [140596716] = {"p1202"},
   [140743811] = {"p1215"},
   [141851788] = {"p0715"},
   [147124948] = {"p0057"},
   [149388515] = {"p0470"},
   [152139875] = {"p0232"},
   [154527879] = {"p0341"},
   [157111375] = {"p1032"},
   [157374335] = {"p1203", "p1204", "p1205", "p1206"},
   [162588888] = {"p0478"},
   [163908741] = {"p1150"},
   [174151954] = {"p1200"},
   [179149347] = {"p0779"},
   [181374404] = {"p0995"},
   [184811339] = {"p1055"},
   [185550038] = {"p0691"},
   [190782478] = {"p1199"},
   [190929573] = {"p1201"},
   [192619706] = {"p0950"},
   [193874929] = {"p0616"},
   [197137717] = {"p1120"},
   [199952577] = {"p0999"},
   [202975179] = {"p0215", "p0216"},
   [206707462] = {"p1021"},
   [207560097] = {"p1198"},
   [212717333] = {"p0192"},
   [215685453] = {"p0029", "p0030"},
   [215896734] = {"p0018"},
   [216984551] = {"p0292"},
   [222827949] = {"p0185"},
   [226791143] = {"p0237"},
   [234977402] = {"p0535", "p0536"},
   [235817252] = {"p0395"},
   [240295639] = {"p0604"},
   [248529750] = {"p1063"},
   [251675299] = {"p0982"},
   [253691271] = {"p0954"},
   [258187144] = {"p1213"},
   [258673081] = {"p0431"},
   [259493443] = {"p0587"},
   [265307369] = {"p1047"},
   [274964763] = {"p1212"},
   [283355626] = {"p0897"},
   [284265722] = {"p0953"},
   [286346737] = {"p0524"},
   [293870771] = {"p0473"},
   [294350347] = {"p0997"},
   [295289996] = {"p0189"},
   [296727648] = {"p1048"},
   [301300109] = {"p0892"},
   [302181694] = {"p0198", "p0199", "p0200"},
   [306348712] = {"p0515", "p0516"},
   [308372906] = {"p1210"},
   [308520001] = {"p1214"},
   [309974860] = {"p0597"},
   [311411949] = {"p0110"},
   [316816318] = {"p0509"},
   [324363308] = {"p1156"},
   [324903938] = {"p0342"},
   [325150525] = {"p1211"},
   [326310448] = {"p0124", "p0125"},
   [326977244] = {"p0513"},
   [328839029] = {"p0596"},
   [332632728] = {"p1162"},
   [334727463] = {"p0669"},
   [342954102] = {"p0117", "p0118", "p0119", "p0120"},
   [345665683] = {"p0847"},
   [349109363] = {"p1037"},
   [356975528] = {"p0817"},
   [359557099] = {"p0069"},
   [359933361] = {"p0710"},
   [360555466] = {"p0733"},
   [370174333] = {"p1142"},
   [376623231] = {"p0270"},
   [384009573] = {"p1072"},
   [387170541] = {"p0914"},
   [391431524] = {"p0635"},
   [402863284] = {"p0823"},
   [404872515] = {"p1009"},
   [405722375] = {"p1067"},
   [409766416] = {"p1248"},
   [412170015] = {"p0869"},
   [413189887] = {"p0666"},
   [416500633] = {"p0674"},
   [418888117] = {"p1090"},
   [421626707] = {"p0618"},
   [423816918] = {"p1110"},
   [440709445] = {"p0437", "p0438"},
   [441497273] = {"p1288"},
   [445648264] = {"p0533"},
   [448568220] = {"p0165"},
   [449735844] = {"p0308"},
   [457567998] = {"p0379"},
   [458274892] = {"p1289"},
   [460099273] = {"p1249"},
   [460739984] = {"p0254"},
   [461044508] = {"p0968"},
   [463367795] = {"p1107"},
   [469991027] = {"p1147"},
   [475052511] = {"p1290"},
   [476876892] = {"p1252"},
   [481199279] = {"p0369"},
   [484473174] = {"p1008"},
   [486159668] = {"p0609"},
   [487860246] = {"p0022", "p0023"},
   [492466794] = {"p1129"},
   [493654511] = {"p1250", "p1251"},
   [500682760] = {"p0349"},
   [500697783] = {"p0035"},
   [502767818] = {"p1153"},
   [503635990] = {"p0293", "p0294", "p0295"},
   [504474784] = {"p0468"},
   [504574159] = {"p1036"},
   [507371540] = {"p0701"},
   [510579225] = {"p1268", "p1269"},
   [514414690] = {"p0640"},
   [515612295] = {"p0359"},
   [516275940] = {"p0957"},
   [519276414] = {"p1004"},
   [521974171] = {"p0569"},
   [525869119] = {"p0932"},
   [527209749] = {"p1253"},
   [530929210] = {"p0822"},
   [540239981] = {"p0024", "p0025"},
   [542162987] = {"p1291"},
   [543987368] = {"p1254"},
   [551124352] = {"p0867"},
   [556461367] = {"p0555"},
   [559264954] = {"p0578", "p0579"},
   [564755613] = {"p0140", "p0141", "p0142", "p0143", "p0144", "p0145", "p0146", "p0147", "p0148", "p0149", "p0150", "p0151"},
   [568301682] = {"p0712"},
   [572200723] = {"p1040"},
   [572484337] = {"p0601"},
   [573950906] = {"p0875"},
   [578739003] = {"p0726"},
   [585537634] = {"p0655"},
   [590863649] = {"p0795"},
   [594761510] = {"p1281"},
   [597035919] = {"p0729"},
   [602854510] = {"p1093"},
   [604985730] = {"p0092", "p0093"},
   [609330411] = {"p0749"},
   [612849831] = {"p0672"},
   [617336113] = {"p0051"},
   [617689455] = {"p0037"},
   [618308647] = {"p0590", "p0591"},
   [628169653] = {"p1267"},
   [628580641] = {"p0520"},
   [631678250] = {"p1068"},
   [632374819] = {"p1097"},
   [639682986] = {"p0790"},
   [646797090] = {"p0501"},
   [648125432] = {"p0214"},
   [650608659] = {"p0351"},
   [659047758] = {"p1014"},
   [659797475] = {"p0430"},
   [661182118] = {"p1138"},
   [662237988] = {"p0901"},
   [663538525] = {"p0946"},
   [669726266] = {"p0693"},
   [669865533] = {"p0723"},
   [670199583] = {"p0610", "p0611"},
   [680353326] = {"p0805"},
   [680471595] = {"p1144"},
   [681872600] = {"p0868"},
   [694110856] = {"p0532"},
   [697604410] = {"p1019"},
   [698650219] = {"p0851"},
   [703462432] = {"p1152"},
   [711824239] = {"p0364"},
   [712204843] = {"p1277"},
   [713629240] = {"p0174"},
   [738395792] = {"p0397", "p0398", "p0399"},
   [740577410] = {"p0626"},
   [740906328] = {"p1060"},
   [751033547] = {"p1075"},
   [767457828] = {"p1126"},
   [778475896] = {"p0905"},
   [779315319] = {"p1280"},
   [781085861] = {"p0352"},
   [782996930] = {"p0370"},
   [783449202] = {"p0300"},
   [784930417] = {"p0743"},
   [795253515] = {"p0924"},
   [796092938] = {"p1278"},
   [799902452] = {"p1010"},
   [801513849] = {"p0826"},
   [807020763] = {"p0681"},
   [811339011] = {"p0721"},
   [812870557] = {"p1279"},
   [814669816] = {"p0910"},
   [819018404] = {"p0422"},
   [829608269] = {"p0213"},
   [846654142] = {"p0331", "p0332"},
   [852989252] = {"p0641", "p0642", "p0643", "p0644"},
   [857784511] = {"p1115"},
   [857811302] = {"p0628", "p0629"},
   [863865129] = {"p0383"},
   [871437828] = {"p0711"},
   [873607196] = {"p1159"},
   [874623120] = {"p0077"},
   [875944106] = {"p0238"},
   [879141610] = {"p0925"},
   [879901109] = {"p1124"},
   [880542750] = {"p0560", "p0561", "p0562", "p0563", "p0564"},
   [881560300] = {"p0735"},
   [889286975] = {"p0688"},
   [891889074] = {"p0511"},
   [893816910] = {"p1134"},
   [893931754] = {"p0556"},
   [899146288] = {"p0242"},
   [901579190] = {"p1294"},
   [911139204] = {"p0015"},
   [924664136] = {"p0034"},
   [929102582] = {"p0755"},
   [930630227] = {"p0806"},
   [938374863] = {"p0648"},
   [943957803] = {"p0230"},
   [946841792] = {"p0915"},
   [956893584] = {"p1082"},
   [956931834] = {"p0966"},
   [958954064] = {"p0785"},
   [961684030] = {"p0003"},
   [968689666] = {"p1293"},
   [969690952] = {"p0004", "p0005", "p0006", "p0007"},
   [971757296] = {"p0128", "p0129"},
   [976905735] = {"p0426", "p0427", "p0428"},
   [977816421] = {"p0960"},
   [985467285] = {"p1292"},
   [985470280] = {"p0096", "p0097", "p0098", "p0099"},
   [988401654] = {"p0523"},
   [990414069] = {"p1017"},
   [991668922] = {"p0978"},
   [998938415] = {"p0085"},
   [999663607] = {"p0660"},
   [1004536190] = {"p1167"},
   [1004919052] = {"p1234"},
   [1006811413] = {"p0612"},
   [1009291532] = {"p0184"},
   [1010911824] = {"p0469"},
   [1027558527] = {"p0284"},
   [1027706260] = {"p0962"},
   [1042413780] = {"p0804"},
   [1044619094] = {"p0186"},
   [1049294307] = {"p0617"},
   [1053534811] = {"p0883"},
   [1054328837] = {"p0104"},
   [1056117276] = {"p0714"},
   [1061844441] = {"p0621"},
   [1067993925] = {"p0269"},
   [1069355380] = {"p1295"},
   [1072424294] = {"p0727"},
   [1082657051] = {"p0872"},
   [1102416515] = {"p0105"},
   [1110182642] = {"p0774"},
   [1111880433] = {"p0707"},
   [1113728075] = {"p0111"},
   [1114383330] = {"p0313", "p0314"},
   [1121027592] = {"p0179"},
   [1122248580] = {"p0448", "p0449"},
   [1124857503] = {"p0340"},
   [1131852724] = {"p0862"},
   [1134067422] = {"p0665"},
   [1143971197] = {"p0482"},
   [1144543599] = {"p0338", "p0339"},
   [1156849420] = {"p0576"},
   [1171861220] = {"p0396"},
   [1173269907] = {"p1151"},
   [1182047129] = {"p0048", "p0049"},
   [1185749054] = {"p1070"},
   [1187494242] = {"p0175"},
   [1189231935] = {"p0773"},
   [1194249577] = {"p0058"},
   [1209354273] = {"p0508"},
   [1215789126] = {"p0209"},
   [1218280325] = {"p0719"},
   [1224195890] = {"p0286"},
   [1224352742] = {"p0327"},
   [1234109873] = {"p0902"},
   [1234865000] = {"p1137"},
   [1236754334] = {"p0789"},
   [1237078462] = {"p0870"},
   [1241130716] = {"p0372"},
   [1246128148] = {"p0490"},
   [1246395443] = {"p0413"},
   [1246910846] = {"p0971"},
   [1260891291] = {"p0933"},
   [1264859995] = {"p1077"},
   [1265399411] = {"p0956"},
   [1265795435] = {"p0829"},
   [1273282745] = {"p1025"},
   [1279906603] = {"p0991"},
   [1282126383] = {"p0942"},
   [1286271067] = {"p0001"},
   [1295098320] = {"p0247", "p0248", "p0249"},
   [1295529770] = {"p0443"},
   [1295659035] = {"p0987"},
   [1301974138] = {"p0731"},
   [1309442977] = {"p0414"},
   [1318179655] = {"p0197"},
   [1319749453] = {"p1165"},
   [1321992654] = {"p1078"},
   [1324050563] = {"p0918"},
   [1325644053] = {"p0939"},
   [1327053516] = {"p1079"},
   [1332885009] = {"p0888"},
   [1338093678] = {"p0552"},
   [1343899503] = {"p0183"},
   [1344652324] = {"p0614"},
   [1347728273] = {"p0250", "p0251", "p0252", "p0253"},
   [1353397971] = {"p0190"},
   [1361293065] = {"p1123"},
   [1366296651] = {"p0748"},
   [1368801814] = {"p0638"},
   [1370820100] = {"p0084"},
   [1373119052] = {"p0235"},
   [1373154485] = {"p1034"},
   [1373536683] = {"p0881"},
   [1396185932] = {"p0299"},
   [1407356061] = {"p0784"},
   [1411801280] = {"p1030"},
   [1428577494] = {"p0094"},
   [1433513367] = {"p0388", "p0389"},
   [1437075121] = {"p0566", "p0567", "p0568"},
   [1440039849] = {"p0274", "p0275"},
   [1458287698] = {"p0921"},
   [1488226972] = {"p0923"},
   [1500448710] = {"p0276"},
   [1510051965] = {"p1087"},
   [1510360708] = {"p0272", "p0273"},
   [1514277072] = {"p0102"},
   [1518627658] = {"p0699"},
   [1522727119] = {"p1058"},
   [1527633183] = {"p0976"},
   [1533952048] = {"p0302"},
   [1535810067] = {"p0780"},
   [1536966871] = {"p0687"},
   [1550180897] = {"p1035"},
   [1552013173] = {"p0408"},
   [1556892824] = {"p0519"},
   [1569813741] = {"p0837"},
   [1572640655] = {"p0600"},
   [1577428598] = {"p0031", "p0032"},
   [1585749770] = {"p0042"},
   [1587485866] = {"p0550"},
   [1587702349] = {"p1065"},
   [1590096080] = {"p0936"},
   [1602928752] = {"p0605"},
   [1603472355] = {"p0194"},
   [1604799546] = {"p0765"},
   [1610836391] = {"p0949"},
   [1613420091] = {"p0973"},
   [1615063151] = {"p0722"},
   [1625449523] = {"p0981"},
   [1627678340] = {"p0558"},
   [1630401852] = {"p1133"},
   [1631979369] = {"p0330"},
   [1636448225] = {"p0495"},
   [1642762785] = {"p0948"},
   [1645354428] = {"p0589"},
   [1646508753] = {"p0044"},
   [1655255690] = {"p0737"},
   [1655675669] = {"p0639"},
   [1661227752] = {"p0994"},
   [1666354933] = {"p0757"},
   [1667691374] = {"p0549"},
   [1668206355] = {"p0791"},
   [1669421777] = {"p1083"},
   [1677295197] = {"p0510"},
   [1677521513] = {"p0354"},
   [1678533606] = {"p1066"},
   [1681823481] = {"p0420"},
   [1689040631] = {"p0898"},
   [1694856420] = {"p0692"},
   [1704552216] = {"p0298"},
   [1716716355] = {"p0531"},
   [1717792839] = {"p0518"},
   [1725481280] = {"p0074", "p0075", "p0076"},
   [1730718906] = {"p0445"},
   [1731801961] = {"p0226", "p0227"},
   [1736531086] = {"p0358"},
   [1740083047] = {"p0828"},
   [1742041965] = {"p0824"},
   [1745055578] = {"p0679"},
   [1752130568] = {"p1119"},
   [1752775821] = {"p1161"},
   [1755683984] = {"p0394"},
   [1767759007] = {"p1023"},
   [1768808476] = {"p0374", "p0375"},
   [1773166660] = {"p0732"},
   [1776138380] = {"p0747"},
   [1776299217] = {"p1062"},
   [1782353778] = {"p0335"},
   [1784963065] = {"p0678"},
   [1785620723] = {"p0356"},
   [1785913816] = {"p0900"},
   [1787028685] = {"p0040", "p0041"},
   [1791908664] = {"p0496", "p0497"},
   [1794079295] = {"p1076"},
   [1799135207] = {"p0645", "p0646", "p0647"},
   [1806503408] = {"p0992"},
   [1806763606] = {"p0725"},
   [1814213554] = {"p0904"},
   [1818695148] = {"p1044"},
   [1820942569] = {"p0595"},
   [1828377024] = {"p1232"},
   [1830361424] = {"p1101"},
   [1831824660] = {"p1130"},
   [1834041699] = {"p0277"},
   [1837684121] = {"p0078"},
   [1838024415] = {"p0502"},
   [1840737001] = {"p0637"},
   [1845078295] = {"p0544", "p0545"},
   [1845154643] = {"p1233"},
   [1848291035] = {"p1033"},
   [1848608180] = {"p0418", "p0419"},
   [1848789858] = {"p0017"},
   [1849613413] = {"p0606", "p0607"},
   [1854085211] = {"p0919"},
   [1856993048] = {"p0796"},
   [1857565852] = {"p0657"},
   [1866636444] = {"p0941"},
   [1871969583] = {"p1057"},
   [1878016423] = {"p1091"},
   [1886418989] = {"p0752"},
   [1894404502] = {"p0233"},
   [1904259626] = {"p0920"},
   [1911517452] = {"p0210", "p0211"},
   [1923805397] = {"p0287", "p0288"},
   [1926229137] = {"p1160"},
   [1929478605] = {"p1108"},
   [1932548894] = {"p0808"},
   [1937729795] = {"p0623"},
   [1940352105] = {"p0754"},
   [1943130586] = {"p0219"},
   [1944648087] = {"p0827"},
   [1947686071] = {"p0504", "p0505"},
   [1949643899] = {"p0690"},
   [1949852501] = {"p0608"},
   [1951671709] = {"p0931"},
   [1952196438] = {"p0463"},
   [1960687173] = {"p1064"},
   [1964125973] = {"p0548"},
   [1965227551] = {"p0801"},
   [1971240232] = {"p0366", "p0367", "p0368"},
   [1987508333] = {"p0841"},
   [1990226589] = {"p0570", "p0571", "p0572"},
   [2003394172] = {"p0442"},
   [2009403135] = {"p0860"},
   [2014817932] = {"p0415"},
   [2015402136] = {"p1099"},
   [2015647594] = {"p1154"},
   [2015880542] = {"p0667"},
   [2025280295] = {"p0928"},
   [2037927064] = {"p0938"},
   [2038584874] = {"p0517"},
   [2038681019] = {"p0311"},
   [2040564647] = {"p0811"},
   [2042842951] = {"p0703"},
   [2047425309] = {"p0565"},
   [2056176069] = {"p0106"},
   [2059636242] = {"p0855"},
   [2063209764] = {"p0695"},
   [2063353540] = {"p0243", "p0244"},
   [2068316736] = {"p0877"},
   [2070529853] = {"p0409", "p0410", "p0411"},
   [2071148662] = {"p0767"},
   [2072191035] = {"p1045"},
   [2073117239] = {"p0559"},
   [2082705650] = {"p0087"},
   [2089299422] = {"p0479"},
   [2089914876] = {"p0985"},
   [2099090076] = {"p0856"},
   [2104039922] = {"p1132"},
   [2118612664] = {"p0360"},
   [2118919611] = {"p0336", "p0337"},
   [2119104537] = {"p0045"},
   [2119287532] = {"p0764"},
   [2119435461] = {"p1003"},
   [2119958400] = {"p1183"},
   [2136736019] = {"p1184"},
   [2152046747] = {"p0365"},
   [2153513638] = {"p1185"},
   [2154966499] = {"p1145"},
   [2156007639] = {"p0323"},
   [2156930392] = {"p0908"},
   [2159090915] = {"p0378"},
   [2159547797] = {"p0786"},
   [2160195075] = {"p0290"},
   [2161505774] = {"p0534"},
   [2170189673] = {"p0689"},
   [2170291257] = {"p1186"},
   [2173033646] = {"p0979"},
   [2179657867] = {"p0173"},
   [2185551765] = {"p0756"},
   [2187068876] = {"p1187"},
   [2189299082] = {"p0959"},
   [2190635726] = {"p0742"},
   [2191681974] = {"p0008"},
   [2192712472] = {"p0439"},
   [2193003094] = {"p0522"},
   [2203846495] = {"p1188"},
   [2204979328] = {"p1178"},
   [2206511507] = {"p1002"},
   [2220624114] = {"p1189"},
   [2221756947] = {"p1177"},
   [2224074059] = {"p0121"},
   [2224219202] = {"p0500"},
   [2226622757] = {"p1039"},
   [2226938858] = {"p0304"},
   [2228324697] = {"p1056"},
   [2232379858] = {"p0702"},
   [2232584353] = {"p0539", "p0540"},
   [2238387471] = {"p1171"},
   [2238534566] = {"p1180"},
   [2239520304] = {"p1228", "p1229"},
   [2254179352] = {"p1190"},
   [2255312185] = {"p1179"},
   [2256150828] = {"p1216"},
   [2256297923] = {"p1225", "p1226", "p1227"},
   [2256314922] = {"p0082", "p0083"},
   [2256577300] = {"p1095"},
   [2256779734] = {"p0926"},
   [2257957562] = {"p0054"},
   [2270956971] = {"p1191"},
   [2271148866] = {"p0458"},
   [2272089804] = {"p1175"},
   [2273075542] = {"p1223", "p1224"},
   [2283307946] = {"p0772"},
   [2288867423] = {"p1174"},
   [2289853161] = {"p1221", "p1222"},
   [2295589279] = {"p0934"},
   [2295949109] = {"p0255"},
   [2296263667] = {"p0212"},
   [2299100282] = {"p0792"},
   [2305645042] = {"p1176"},
   [2306630780] = {"p1220"},
   [2310596904] = {"p0112", "p0113", "p0114"},
   [2310955340] = {"p0334"},
   [2312247312] = {"p1071"},
   [2319557803] = {"p0815"},
   [2322275566] = {"p1172"},
   [2323408399] = {"p1219"},
   [2327620461] = {"p0879"},
   [2334046611] = {"p0027", "p0028"},
   [2338367564] = {"p0798"},
   [2339053185] = {"p1173"},
   [2339782138] = {"p0728"},
   [2340186018] = {"p1218"},
   [2340399334] = {"p0984"},
   [2342970952] = {"p0670"},
   [2343386810] = {"p0813"},
   [2348668913] = {"p0070", "p0071"},
   [2352927936] = {"p0465"},
   [2354027495] = {"p0965"},
   [2356450509] = {"p0911"},
   [2356963637] = {"p1217"},
   [2360946699] = {"p0768"},
   [2365738721] = {"p0582", "p0583"},
   [2391486813] = {"p0787"},
   [2391919670] = {"p0329"},
   [2392217443] = {"p0592", "p0593"},
   [2392846398] = {"p1006"},
   [2400785484] = {"p0202"},
   [2401958212] = {"p0620"},
   [2403908560] = {"p0836"},
   [2405125916] = {"p0803"},
   [2405258039] = {"p0371"},
   [2406310756] = {"p1182"},
   [2407057067] = {"p1166"},
   [2407648059] = {"p0800"},
   [2408061074] = {"p0068"},
   [2409418199] = {"p0720"},
   [2410165691] = {"p0873"},
   [2415987414] = {"p0492"},
   [2423088375] = {"p1181"},
   [2424710769] = {"p1080"},
   [2426251258] = {"p0988"},
   [2429381386] = {"p0858"},
   [2434331114] = {"p1054"},
   [2434356068] = {"p0010", "p0011", "p0012", "p0013"},
   [2449287484] = {"p0694"},
   [2455966726] = {"p1016"},
   [2458436022] = {"p0306"},
   [2462515659] = {"p0088", "p0089"},
   [2466488129] = {"p0480"},
   [2472744345] = {"p0996"},
   [2476500854] = {"p0840"},
   [2483910348] = {"p1135"},
   [2484487183] = {"p0615"},
   [2487483599] = {"p0256", "p0257", "p0258", "p0259"},
   [2491184589] = {"p1230", "p1231"},
   [2491563113] = {"p1089"},
   [2497635817] = {"p0758"},
   [2506682280] = {"p1170"},
   [2509136006] = {"p0268"},
   [2511301235] = {"p0866"},
   [2512454757] = {"p0050"},
   [2523459899] = {"p1169"},
   [2524410604] = {"p0170"},
   [2530690355] = {"p1102"},
   [2532192306] = {"p1092"},
   [2532247836] = {"p1051"},
   [2533965114] = {"p1081"},
   [2534608688] = {"p0137", "p0138", "p0139"},
   [2535330057] = {"p0848"},
   [2542445028] = {"p0820"},
   [2542834854] = {"p0234"},
   [2542979879] = {"p0488"},
   [2543293970] = {"p0961"},
   [2546753025] = {"p1100"},
   [2552724773] = {"p0573", "p0574", "p0575"},
   [2554377704] = {"p0602"},
   [2555507482] = {"p0906"},
   [2558041329] = {"p0412"},
   [2561543864] = {"p0630"},
   [2565992262] = {"p1157"},
   [2566216249] = {"p1038"},
   [2572573996] = {"p1168"},
   [2573866437] = {"p0450"},
   [2574440441] = {"p0208"},
   [2576386050] = {"p0205"},
   [2582618405] = {"p0861"},
   [2582769881] = {"p1146"},
   [2583720386] = {"p0467"},
   [2589179600] = {"p1284"},
   [2592724193] = {"p0818"},
   [2593608028] = {"p0834"},
   [2594145992] = {"p0850"},
   [2595928534] = {"p0854"},
   [2598742732] = {"p0009"},
   [2602108206] = {"p0026"},
   [2604032263] = {"p0033"},
   [2606683129] = {"p0203"},
   [2613841599] = {"p0682"},
   [2617792551] = {"p0716"},
   [2619085881] = {"p1131"},
   [2623928940] = {"p0053"},
   [2624995470] = {"p0807"},
   [2631755671] = {"p0859"},
   [2633077897] = {"p1113"},
   [2637300914] = {"p0750"},
   [2638655031] = {"p0066", "p0067"},
   [2639512457] = {"p1282", "p1283"},
   [2639747988] = {"p0130", "p0131", "p0132", "p0133"},
   [2640713438] = {"p1073"},
   [2650511253] = {"p1074"},
   [2656290076] = {"p1287"},
   [2658351827] = {"p1007"},
   [2658699220] = {"p0588"},
   [2673067695] = {"p1286"},
   [2674096169] = {"p0038", "p0039"},
   [2678489659] = {"p0380"},
   [2689845314] = {"p1285"},
   [2690978147] = {"p1246", "p1247"},
   [2694634191] = {"p0802"},
   [2705669554] = {"p0874"},
   [2707652742] = {"p0157", "p0158", "p0159", "p0160"},
   [2709204664] = {"p0400"},
   [2711731029] = {"p0416", "p0417"},
   [2719812143] = {"p1005"},
   [2722447173] = {"p0891"},
   [2733025378] = {"p0423", "p0424"},
   [2734068193] = {"p0289"},
   [2734653047] = {"p0081"},
   [2739044822] = {"p0697"},
   [2740633951] = {"p0325", "p0326"},
   [2748490001] = {"p0636"},
   [2749179272] = {"p1000"},
   [2753820126] = {"p0108"},
   [2769969332] = {"p0204"},
   [2772752701] = {"p0178"},
   [2781359575] = {"p0832"},
   [2787762158] = {"p0464"},
   [2789016137] = {"p0952"},
   [2798580603] = {"p0163"},
   [2804475606] = {"p1031"},
   [2806594168] = {"p0930"},
   [2808421480] = {"p1238"},
   [2809206164] = {"p0228", "p0229"},
   [2812397012] = {"p0846"},
   [2816015233] = {"p0845"},
   [2823151151] = {"p0740"},
   [2825199099] = {"p1239", "p1240", "p1241"},
   [2826331932] = {"p1276"},
   [2831783111] = {"p0382"},
   [2834862932] = {"p0766"},
   [2837368546] = {"p0507"},
   [2838214118] = {"p0696"},
   [2854992388] = {"p0193"},
   [2858754337] = {"p1242"},
   [2867504806] = {"p0052"},
   [2868702080] = {"p0471"},
   [2871742052] = {"p0181"},
   [2873571971] = {"p1020"},
   [2875718074] = {"p1149"},
   [2875826146] = {"p1266"},
   [2877425217] = {"p1086"},
   [2878841933] = {"p0958"},
   [2880802318] = {"p0196"},
   [2890192498] = {"p1042"},
   [2892251107] = {"p1098"},
   [2892309575] = {"p1243"},
   [2893442408] = {"p1274"},
   [2901548498] = {"p1164"},
   [2906557249] = {"p0865"},
   [2909087194] = {"p1244"},
   [2909297953] = {"p0736"},
   [2909381384] = {"p1263", "p1264", "p1265"},
   [2910220027] = {"p1273"},
   [2912905357] = {"p0893"},
   [2922075629] = {"p0503"},
   [2925864813] = {"p1245"},
   [2926011908] = {"p1237"},
   [2933146167] = {"p0493"},
   [2933667748] = {"p1127"},
   [2934290624] = {"p0361"},
   [2934314675] = {"p1105"},
   [2942936622] = {"p1260", "p1261"},
   [2943775265] = {"p1275"},
   [2947561317] = {"p0852"},
   [2949092467] = {"p0781"},
   [2959567146] = {"p1236"},
   [2959714241] = {"p1262"},
   [2960552884] = {"p1271"},
   [2964976064] = {"p1296"},
   [2976344765] = {"p1235"},
   [2976491860] = {"p1258"},
   [2977330503] = {"p1270"},
   [2977808571] = {"p1116"},
   [2981753683] = {"p1297"},
   [2982528120] = {"p0460"},
   [2992162361] = {"p0598"},
   [2992293098] = {"p1158"},
   [2993269479] = {"p1259"},
   [2995625359] = {"p0580", "p0581"},
   [3000314773] = {"p0434"},
   [3007548835] = {"p0676"},
   [3009896951] = {"p0425"},
   [3010047098] = {"p1255"},
   [3010885741] = {"p1272"},
   [3015890058] = {"p0435"},
   [3018125114] = {"p0916"},
   [3026824717] = {"p1256", "p1257"},
   [3027778544] = {"p1059"},
   [3030454675] = {"p1148"},
   [3045968202] = {"p0759"},
   [3046172187] = {"p0403", "p0404", "p0405"},
   [3046592580] = {"p0401", "p0402"},
   [3049181483] = {"p0100", "p0101"},
   [3083765305] = {"p0990"},
   [3084656870] = {"p0677"},
   [3084857658] = {"p0557"},
   [3089095337] = {"p0362"},
   [3095881314] = {"p0432"},
   [3100397949] = {"p0494"},
   [3100686752] = {"p0797"},
   [3104934728] = {"p0285"},
   [3105522251] = {"p0472"},
   [3109746042] = {"p0265", "p0266", "p0267"},
   [3120543089] = {"p0788"},
   [3132505773] = {"p0661"},
   [3132735590] = {"p1022"},
   [3148009252] = {"p0909"},
   [3150675610] = {"p0724"},
   [3150991808] = {"p0542"},
   [3155935782] = {"p1139"},
   [3157345552] = {"p0903"},
   [3158528027] = {"p0079"},
   [3158996305] = {"p0649", "p0650", "p0651", "p0652"},
   [3166926427] = {"p0675"},
   [3170140237] = {"p0709"},
   [3170591575] = {"p0429"},
   [3195263088] = {"p0056"},
   [3200404802] = {"p0770"},
   [3203408230] = {"p0451"},
   [3204447294] = {"p0135", "p0136"},
   [3204638126] = {"p0753"},
   [3220300298] = {"p0825"},
   [3227675289] = {"p0357"},
   [3242942836] = {"p0343", "p0344", "p0345", "p0346", "p0347"},
   [3244939539] = {"p0998"},
   [3251857055] = {"p0741"},
   [3254544713] = {"p0793"},
   [3258224172] = {"p0171", "p0172"},
   [3267034274] = {"p0486"},
   [3273228219] = {"p0107"},
   [3277475166] = {"p1050"},
   [3279927111] = {"p0947"},
   [3292809061] = {"p0734"},
   [3293967859] = {"p1043"},
   [3303878908] = {"p0890"},
   [3311486207] = {"p1143"},
   [3312924828] = {"p0654"},
   [3313390078] = {"p0964"},
   [3316123173] = {"p0073"},
   [3322099398] = {"p0059"},
   [3327291751] = {"p0744"},
   [3330954405] = {"p0487"},
   [3332288271] = {"p0440"},
   [3332794050] = {"p0363"},
   [3336224652] = {"p1041"},
   [3336506354] = {"p0663"},
   [3341982890] = {"p0161", "p0162"},
   [3349307780] = {"p1141"},
   [3349660760] = {"p0002"},
   [3357752122] = {"p1069"},
   [3363332273] = {"p0122", "p0123"},
   [3364311065] = {"p0776"},
   [3371905323] = {"p0907"},
   [3383154563] = {"p0291"},
   [3384293798] = {"p0080"},
   [3386407313] = {"p0864"},
   [3387931219] = {"p0664"},
   [3393164804] = {"p0762"},
   [3395622923] = {"p0373"},
   [3402627816] = {"p0745"},
   [3406297667] = {"p1103"},
   [3408248642] = {"p0896"},
   [3409793158] = {"p0810"},
   [3415132135] = {"p1104"},
   [3416770844] = {"p0278"},
   [3419426569] = {"p0627"},
   [3421549781] = {"p1122"},
   [3427809419] = {"p0296"},
   [3436546013] = {"p1128"},
   [3437492384] = {"p0974"},
   [3444571567] = {"p0889"},
   [3445803454] = {"p0584"},
   [3458811685] = {"p0698"},
   [3462132711] = {"p0876"},
   [3462431299] = {"p0963"},
   [3469766558] = {"p0527"},
   [3473253304] = {"p0554"},
   [3479735338] = {"p0303"},
   [3481608533] = {"p0708"},
   [3483629978] = {"p0046", "p0047"},
   [3484064257] = {"p0512"},
   [3488896385] = {"p0943"},
   [3494028431] = {"p0446", "p0447"},
   [3495790379] = {"p0704"},
   [3500475044] = {"p0730"},
   [3512111708] = {"p0103"},
   [3515691670] = {"p0043"},
   [3516730124] = {"p0236"},
   [3518604581] = {"p0547"},
   [3518802213] = {"p0839"},
   [3520022975] = {"p0466"},
   [3522592196] = {"p0899"},
   [3528282775] = {"p0283"},
   [3529344228] = {"p0452", "p0453", "p0454", "p0455", "p0456"},
   [3529603788] = {"p0833"},
   [3529655320] = {"p1117"},
   [3530587588] = {"p0751"},
   [3531543293] = {"p0525"},
   [3544993815] = {"p0843"},
   [3557816087] = {"p0619"},
   [3568825832] = {"p0662"},
   [3568964300] = {"p0929"},
   [3573542131] = {"p0683"},
   [3574106655] = {"p0315", "p0316", "p0317", "p0318", "p0319", "p0320", "p0321", "p0322"},
   [3575862874] = {"p0553"},
   [3575908492] = {"p0355"},
   [3583759210] = {"p0783"},
   [3585641430] = {"p0436"},
   [3587402079] = {"p0217", "p0218"},
   [3588693052] = {"p1012"},
   [3593881581] = {"p0922"},
   [3596340559] = {"p0476"},
   [3604871475] = {"p1118"},
   [3605100101] = {"p0312"},
   [3605503673] = {"p0191"},
   [3609768030] = {"p1140"},
   [3611757348] = {"p1013"},
   [3615475984] = {"p0680"},
   [3616673933] = {"p1024"},
   [3619778169] = {"p0353"},
   [3622496779] = {"p0521"},
   [3624258715] = {"p0658"},
   [3630201075] = {"p0477"},
   [3632560490] = {"p0863"},
   [3635708854] = {"p0457"},
   [3644223868] = {"p0887"},
   [3648982006] = {"p0912"},
   [3649466891] = {"p0842"},
   [3658808214] = {"p1029"},
   [3675435701] = {"p0718"},
   [3677818621] = {"p0830"},
   [3686933763] = {"p0849"},
   [3687932686] = {"p0777"},
   [3695116460] = {"p0653"},
   [3695288907] = {"p0109"},
   [3702759768] = {"p0967"},
   [3706969950] = {"p0632"},
   [3718703291] = {"p0980"},
   [3721101974] = {"p0474"},
   [3724781392] = {"p0483"},
   [3726206688] = {"p1052"},
   [3728730065] = {"p0462"},
   [3732231544] = {"p0491"},
   [3744841984] = {"p0819"},
   [3746207868] = {"p1088"},
   [3758412200] = {"p0838"},
   [3767028834] = {"p0014"},
   [3767455461] = {"p0594"},
   [3769798484] = {"p0126"},
   [3775476411] = {"p0913"},
   [3780832315] = {"p0187"},
   [3788387139] = {"p0782"},
   [3790027944] = {"p0406"},
   [3790738519] = {"p0444"},
   [3792668182] = {"p0761"},
   [3796019944] = {"p0624", "p0625"},
   [3805178546] = {"p1049"},
   [3807276542] = {"p0333"},
   [3817278827] = {"p1096"},
   [3818035714] = {"p0541"},
   [3823085861] = {"p0239"},
   [3826319332] = {"p0673"},
   [3828859817] = {"p0301"},
   [3830027813] = {"p0090", "p0091"},
   [3835451071] = {"p0886"},
   [3838414647] = {"p0935"},
   [3839802052] = {"p0528", "p0529", "p0530"},
   [3839989396] = {"p1155"},
   [3845272027] = {"p0036"},
   [3852348947] = {"p0885"},
   [3858283900] = {"p0671"},
   [3859810892] = {"p1053"},
   [3863921340] = {"p0201"},
   [3874668737] = {"p0713"},
   [3877062087] = {"p0206"},
   [3885701540] = {"p0246"},
   [3886226162] = {"p0871"},
   [3886907443] = {"p0878"},
   [3891860470] = {"p0835"},
   [3892549457] = {"p0986"},
   [3897149591] = {"p0685"},
   [3897828886] = {"p0164"},
   [3908821894] = {"p0814"},
   [3911126767] = {"p0937"},
   [3912468599] = {"p0381"},
   [3913051812] = {"p0972"},
   [3914548547] = {"p0622"},
   [3917707014] = {"p0297"},
   [3920248109] = {"p0585", "p0586"},
   [3920428434] = {"p0271"},
   [3924123665] = {"p0498"},
   [3926309767] = {"p1015"},
   [3933707126] = {"p0551"},
   [3935839566] = {"p0746"},
   [3937976452] = {"p0475"},
   [3940375170] = {"p0794"},
   [3949138272] = {"p0880"},
   [3950939867] = {"p0546"},
   [3955485235] = {"p1111"},
   [3957494338] = {"p0241"},
   [3960436383] = {"p0739"},
   [3963106143] = {"p0260", "p0261", "p0262"},
   [3966041303] = {"p0917"},
   [3975582682] = {"p0738"},
   [3978738340] = {"p0831"},
   [3979783709] = {"p0310"},
   [3980175049] = {"p0461"},
   [3984150206] = {"p0020"},
   [3985677972] = {"p0895"},
   [3989031306] = {"p0634"},
   [3996221146] = {"p0944"},
   [4001529309] = {"p0188"},
   [4002010408] = {"p0771"},
   [4002813792] = {"p0021"},
   [4004009228] = {"p0945"},
   [4019983350] = {"p0176"},
   [4023371129] = {"p0348"},
   [4028098495] = {"p0633"},
   [4032785445] = {"p0989"},
   [4037277986] = {"p1136"},
   [4045059281] = {"p0769"},
   [4047289354] = {"p0166", "p0167", "p0168", "p0169"},
   [4048611299] = {"p0993"},
   [4050179569] = {"p0072"},
   [4050592549] = {"p0391", "p0392", "p0393"},
   [4051535350] = {"p0177"},
   [4057760517] = {"p0279"},
   [4058556943] = {"p0061", "p0062", "p0063", "p0064", "p0065"},
   [4063654920] = {"p0969"},
   [4065263061] = {"p0231"},
   [4073169962] = {"p0134"},
   [4080662342] = {"p0706"},
   [4081746542] = {"p0799"},
   [4082062219] = {"p0280"},
   [4082975252] = {"p0613"},
   [4084168775] = {"p0656"},
   [4085204253] = {"p0659"},
   [4088011206] = {"p0220", "p0221", "p0222", "p0223", "p0224", "p0225"},
   [4090678572] = {"p0809"},
   [4093870181] = {"p0433"},
   [4099279968] = {"p0760"},
   [4101913039] = {"p0207"},
   [4105409813] = {"p0245"},
   [4108138127] = {"p0095"},
   [4108397428] = {"p0853"},
   [4116921863] = {"p0717"},
   [4122395146] = {"p0514"},
   [4131257025] = {"p1084"},
   [4132090546] = {"p0844"},
   [4141145939] = {"p0060"},
   [4143908495] = {"p0421"},
   [4151544216] = {"p0894"},
   [4156676279] = {"p0631"},
   [4157928872] = {"p1028"},
   [4158481931] = {"p0324"},
   [4160825732] = {"p0977"},
   [4161028547] = {"p0240"},
   [4161424292] = {"p0350"},
   [4162277569] = {"p0441"},
   [4174773713] = {"p0700"},
   [4175804091] = {"p1018"},
   [4198004772] = {"p0489"},
   [4198746768] = {"p1011"},
   [4200739362] = {"p1112"},
   [4203814779] = {"p1026"},
   [4209414688] = {"p1094"},
   [4223903598] = {"p0668"},
   [4229355287] = {"p0778"},
   [4231233580] = {"p0328"},
   [4238101924] = {"p1125"},
   [4238622239] = {"p1027"},
   [4240074716] = {"p0816"},
   [4240546156] = {"p1121"},
   [4242140262] = {"p0305"},
   [4248514548] = {"p1001"},
   [4250451583] = {"p0282"},
   [4258042986] = {"p0376", "p0377"},
   [4260160075] = {"p0684"},
   [4266465173] = {"p0975"},
   [4267263011] = {"p0152", "p0153", "p0154", "p0155", "p0156"},
   [4269655474] = {"p0016"},
   [4273331806] = {"p0309"},
   [4274823287] = {"p0459"},
   [4277027356] = {"p1046"},
   [4278612574] = {"p0763"},
   [4281109506] = {"p1114"},
   [4281659510] = {"p0603"},
   [4284579824] = {"p0481"},
   [4286177911] = {"p0884"},
   [4287904293] = {"p0951"},
   [4288078320] = {"p0970"},
}

local function LegacyFavoriteHash(text)
   local hash = 2166136261
   text = tostring(text or "")
   for i = 1, #text do
      hash = ((hash ~ string.byte(text, i)) * 16777619) & 0xFFFFFFFF
   end
   return hash
end
local defaultExoticKeys = {}
for _, key in ipairs(defaultFavoriteKeys) do defaultExoticKeys[key] = true end
for _, key in ipairs(builtinExoticFavoriteKeys) do defaultFavoriteKeys[#defaultFavoriteKeys + 1] = key end


local function ArchiveItemKey(item)
   if not item then return "" end
   local key = tostring(item.archive_id or "")
   if key == "" then
      key = tostring(item.full_hex or item.hex or "") .. "|" .. tostring(item.pearl_id or "") .. "|" .. tostring(item.name or "")
   end
   return key:gsub("[\r\n]", " ")
end

local archiveFavoritesNeedSave = false
local function LoadArchiveFavorites()
   archiveFavorites = {}
   archiveFavoritesNeedSave = false
   local raw = FileMgr.ReadFileContent(archiveFavoritesPath)
   if not raw or raw == "" then return end
   for line in tostring(raw):gmatch("[^\r\n]+") do
      if line ~= "" then
         local legacyIds = legacyFavoriteIds[LegacyFavoriteHash(line)]
         if type(legacyIds) == "table" and #legacyIds > 0 then
            for _, archiveId in ipairs(legacyIds) do archiveFavorites[archiveId] = true end
            archiveFavoritesNeedSave = true
         else
            archiveFavorites[line] = true
         end
      end
   end
end

local function SaveArchiveFavorites()
   local lines = {}
   for key, enabled in pairs(archiveFavorites) do
      if enabled then lines[#lines + 1] = key end
   end
   table.sort(lines)
   FileMgr.WriteFileContent(archiveFavoritesPath, table.concat(lines, "\n"))
end

local function SeedDefaultFavoritesOnce()
   local marker = FileMgr.ReadFileContent(archiveDefaultsMarkerPath)
   if tostring(marker or ""):find(DEFAULTS_SEED_ID, 1, true) then return false end

   local added = 0
   for _, key in ipairs(defaultFavoriteKeys) do
      if key ~= "" and archiveFavorites[key] ~= true then
         archiveFavorites[key] = true
         added = added + 1
      end
   end
   SaveArchiveFavorites()
   FileMgr.WriteFileContent(archiveDefaultsMarkerPath, DEFAULTS_SEED_ID .. "\n")
   return added > 0
end

local function IsArchiveFavorite(item)
   return archiveFavorites[ArchiveItemKey(item)] == true
end

local remixFavoritesPath = presetPath .. "remix_favorites.txt"
local savedRemixSources = {}

local function LoadSavedRemixFavorites()
   local raw = FileMgr.ReadFileContent(remixFavoritesPath)
   if not raw or raw == "" then return end
   for line in tostring(raw):gmatch("[^\r\n]+") do
      local archiveId, name, hex, rs, gs, bs, pearlName, pearlId = line:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)")
      if archiveId and archiveId ~= "" and not savedRemixSources[archiveId] then
         local r, g, b = tonumber(rs), tonumber(gs), tonumber(bs)
         local pid = tonumber(pearlId)
         if r and g and b and hex and hex ~= "" then
            savedRemixSources[archiveId] = true
            archiveLibrary[#archiveLibrary + 1] = {
               name = name ~= "" and name or "Saved Remix", hex = hex, full_hex = hex .. "AA",
               r = math.max(0, math.min(255, math.floor(r))), g = math.max(0, math.min(255, math.floor(g))), b = math.max(0, math.min(255, math.floor(b))),
               pearl_name = pearlName or "", pearl_id = pid, archive_id = archiveId,
               confidence = pid and "high" or "medium", is_remix_gallery = true, is_saved_remix = true,
            }
         end
      end
   end
end

local function PersistRemixFavorite(item)
   if not item or item.is_remix_gallery ~= true then return end
   local archiveId = ArchiveItemKey(item)
   if archiveId == "" or savedRemixSources[archiveId] then return end
   savedRemixSources[archiveId] = true
   local raw = FileMgr.ReadFileContent(remixFavoritesPath) or ""
   local line = table.concat({ archiveId, tostring(item.name or "Saved Remix"), tostring(item.hex or "#FFFFFF"),
      tostring(math.floor(tonumber(item.r) or 255)), tostring(math.floor(tonumber(item.g) or 255)), tostring(math.floor(tonumber(item.b) or 255)),
      tostring(item.pearl_name or ""), tostring(item.pearl_id or "") }, "\t")
   if raw ~= "" and raw:sub(-1) ~= "\n" then raw = raw .. "\n" end
   FileMgr.WriteFileContent(remixFavoritesPath, raw .. line .. "\n")
end

LoadSavedRemixFavorites()

for i, item in ipairs(archiveLibrary) do
   item._archive_index = i
   item._archive_key = ArchiveItemKey(item)
   item.base_family = ClassifyArchiveColor(item)
   item.is_exotic_gallery = item.is_exotic == true or defaultExoticKeys[item._archive_key] == true
   item.is_ai_gallery = item.is_ai == true
   item.is_remix_gallery = item.is_remix_gallery == true
   item.family = item.base_family
   local h, s, v = ArchiveRgbToHsv(item.r, item.g, item.b)
   item._hue = h
   item._saturation = s
   item._value = v
   -- perceived luminance is a better visual brightness order than a raw rgb average.
   item._brightness = (((tonumber(item.r) or 0) * 0.2126)
      + ((tonumber(item.g) or 0) * 0.7152)
      + ((tonumber(item.b) or 0) * 0.0722)) / 255.0
end
LoadArchiveFavorites()
if archiveFavoritesNeedSave then SaveArchiveFavorites() end
SeedDefaultFavoritesOnce()

local ApplyFullExoticPreset
local UpdatePresetColorList

local archiveView = {
   filtered = {},
   signature = "",
   selected = nil,
   selectedIndex = 0,
   lastHoveredKey = "",
   hoverCandidateKey = "",
   hoverCandidateSince = 0,
   autoIndex = 0,
   nextCycleMs = 0,
}

local remixResults = {}
local remixGeneration = 0
local remixSeedName = ""
local remixMode = ""

local previewState = {
   active = false,
   vehicle = 0,
   snapshot = nil,
   selected = nil,
   lastTabRenderMs = 0,
}
_G.GTA_PAINTJOB_PREVIEW = previewState

local rotationState = {
   active = false,
   vehicle = 0,
   originalHeading = 0.0,
   lastMs = 0,
}

local function NowMs()
   local ok, v = pcall(function() return Time.GetEpocheMs() end)
   return ok and tonumber(v) or 0
end

local function AllocInt(value)
   local p = Memory.AllocInt()
   if p and p ~= 0 and value ~= nil then pcall(Memory.WriteInt, p, value) end
   return p
end
local function ReadInt(p, fallback)
   if not p or p == 0 then return fallback or 0 end
   local ok, v = pcall(Memory.ReadInt, p)
   return ok and v or (fallback or 0)
end
local function FreeMem(p) if p and p ~= 0 then pcall(Memory.Free, p) end end

local function ReadTwoInts(nativeFn, vehicle)
   local a, b = AllocInt(0), AllocInt(0)
   if not a or not b or a == 0 or b == 0 then FreeMem(a); FreeMem(b); return 0, 0 end
   pcall(nativeFn, vehicle, a, b)
   local av, bv = ReadInt(a, 0), ReadInt(b, 0)
   FreeMem(a); FreeMem(b)
   return av, bv
end

local function ReadThreeInts(nativeFn, vehicle)
   local r, g, b = AllocInt(0), AllocInt(0), AllocInt(0)
   if not r or not g or not b or r == 0 or g == 0 or b == 0 then
      FreeMem(r); FreeMem(g); FreeMem(b)
      return 255, 255, 255
   end
   pcall(nativeFn, vehicle, r, g, b)
   local rv, gv, bv = ReadInt(r, 255), ReadInt(g, 255), ReadInt(b, 255)
   FreeMem(r); FreeMem(g); FreeMem(b)
   return rv, gv, bv
end

local function CapturePaintSnapshot(vehicle)
   if not vehicle or vehicle == 0 then return nil end
   local primary, secondary = ReadTwoInts(GET_VEHICLE_COLOURS, vehicle)
   local pearl, wheel = ReadTwoInts(GET_VEHICLE_EXTRA_COLOURS, vehicle)
   local pr, pg, pb = ReadThreeInts(GET_VEHICLE_CUSTOM_PRIMARY_COLOUR, vehicle)
   local sr, sg, sb = ReadThreeInts(GET_VEHICLE_CUSTOM_SECONDARY_COLOUR, vehicle)
   local tr, tg, tb = ReadThreeInts(GET_VEHICLE_TYRE_SMOKE_COLOR, vehicle)
   local mod1Type, mod1Color, mod1Pearl = ReadThreeInts(GET_VEHICLE_MOD_COLOR_1, vehicle)
   local mod2Type, mod2Color = ReadTwoInts(GET_VEHICLE_MOD_COLOR_2, vehicle)
   local nr, ng, nb = ReadThreeInts(_GET_VEHICLE_NEON_LIGHTS_COLOUR, vehicle)
   local primaryCustom, secondaryCustom = false, false
   local tyreSmokeEnabled = false
   local xenonEnabled = false
   local xenonColor = 0
   local neonEnabled = { false, false, false, false }
   pcall(function() primaryCustom = GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(vehicle) == true end)
   pcall(function() secondaryCustom = GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(vehicle) == true end)
   pcall(function() tyreSmokeEnabled = IS_TOGGLE_MOD_ON(vehicle, 20) == true end)
   pcall(function() xenonEnabled = IS_TOGGLE_MOD_ON(vehicle, 22) == true end)
   pcall(function() xenonColor = GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle) or 0 end)
   for i = 0, 3 do
      pcall(function() neonEnabled[i + 1] = _GET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, i) == true end)
   end
   return {
      primary = primary, secondary = secondary,
      pearl = pearl, wheel = wheel,
      primaryCustom = primaryCustom, secondaryCustom = secondaryCustom,
      pr = pr, pg = pg, pb = pb,
      sr = sr, sg = sg, sb = sb,
      tyreSmokeEnabled = tyreSmokeEnabled,
      tr = tr, tg = tg, tb = tb,
      xenonEnabled = xenonEnabled, xenonColor = xenonColor,
      neonEnabled = neonEnabled, nr = nr, ng = ng, nb = nb,
      mod1Type = mod1Type, mod1Color = mod1Color, mod1Pearl = mod1Pearl,
      mod2Type = mod2Type, mod2Color = mod2Color,
   }
end

local function RestorePaintSnapshot(silent)
   if not previewState.active or not previewState.snapshot then return end
   local vehicle = previewState.vehicle
   local s = previewState.snapshot
   local exists = false
   pcall(function() exists = vehicle ~= 0 and DOES_ENTITY_EXIST(vehicle) end)
   if exists then
      SET_VEHICLE_MOD_KIT(vehicle, 0)
      SET_VEHICLE_COLOURS(vehicle, s.primary or 0, s.secondary or 0)
      SET_VEHICLE_MOD_COLOR_1(vehicle, s.mod1Type or 1, s.mod1Color or s.primary or 0, s.mod1Pearl or s.pearl or 0)
      SET_VEHICLE_MOD_COLOR_2(vehicle, s.mod2Type or 1, s.mod2Color or s.secondary or 0)
      SET_VEHICLE_EXTRA_COLOURS(vehicle, s.pearl or 0, s.wheel or 0)
      if s.primaryCustom then
         SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, s.pr or 255, s.pg or 255, s.pb or 255)
      else
         CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle)
      end
      if s.secondaryCustom then
         SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, s.sr or 255, s.sg or 255, s.sb or 255)
      else
         CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle)
      end
      TOGGLE_VEHICLE_MOD(vehicle, 20, s.tyreSmokeEnabled == true)
      SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, s.tr or 255, s.tg or 255, s.tb or 255)
      TOGGLE_VEHICLE_MOD(vehicle, 22, s.xenonEnabled == true)
      _SET_VEHICLE_XENON_LIGHT_COLOR(vehicle, tonumber(s.xenonColor) or 0)
      for i = 0, 3 do
         local enabled = type(s.neonEnabled) == "table" and s.neonEnabled[i + 1] == true or false
         _SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, i, enabled)
      end
      _SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, s.nr or 255, s.ng or 255, s.nb or 255)
   end
   previewState.active = false
   previewState.vehicle = 0
   previewState.snapshot = nil
   previewState.selected = nil
   archiveView.lastHoveredKey = ""
   archiveView.hoverCandidateKey = ""
   if not silent then GUI.AddToast("PaintLabs", "Soft preview reverted.", 1800) end
end

local function ArchiveGetVehicleHandle()
   local ped = GTA.GetLocalPed()
   if not ped or not ped:IsInVehicle() then return nil end
   return GTA.PointerToHandle(ped.CurVehicle)
end

local function GetArchiveFinishMaterial()
   local idx = FeatureMgr.GetFeatureListIndex(F.ArchiveFinish) or 0
   if idx <= 0 then return nil end
   -- combo index 1..6 maps directly to visible materials 1..6 (metallic through chrome).
   return Materials[math.max(1, math.min(6, idx))]
end

local function GetArchiveFinishLabel()
   local idx = FeatureMgr.GetFeatureListIndex(F.ArchiveFinish) or 0
   return archiveFinishNames[idx + 1] or archiveFinishNames[1]
end

local function GetArchiveSourceMaterial(item)
   local wanted = item and NormalizeMaterialName(item.original_finish) or ""
   if wanted == "" then return nil end
   for _, mat in ipairs(Materials) do
      if tostring(mat.name or "") == wanted then return mat end
   end
   return nil
end

local function ApplyArchivePaintToVehicle(vehicle, item, wheelColor, pearl)
   if item and item.is_exotic == true and type(item.exotic_preset) == "table" then
      local p = item.exotic_preset
      local mat = GetArchiveFinishMaterial() or Materials[LegacyMaterialIndexToCurrent(p.material) + 1] or Materials[1]
      if mat.name == "Chameleon" then
         local chameleonIndex = math.max(0, math.min(31, math.floor(tonumber(p.chameleon) or 0)))
         local colorId = 161 + chameleonIndex
         SET_VEHICLE_COLOURS(vehicle, colorId, colorId)
         SET_VEHICLE_EXTRA_COLOURS(vehicle, pearl or 0, wheelColor or 0)
         CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle)
         CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle)
      else
         local baseColorId = type(mat.id) == "table" and mat.id[1] or mat.id
         SET_VEHICLE_COLOURS(vehicle, baseColorId or 0, baseColorId or 0)
         SET_VEHICLE_MOD_COLOR_1(vehicle, mat.type or 1, baseColorId or 0, pearl or 0)
         SET_VEHICLE_MOD_COLOR_2(vehicle, mat.type or 1, baseColorId or 0)
         SET_VEHICLE_EXTRA_COLOURS(vehicle, pearl or 0, wheelColor or 0)
         SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, item.r or 255, item.g or 255, item.b or 255)
         SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
            vehicle,
            item.secondary_r or item.r or 255,
            item.secondary_g or item.g or 255,
            item.secondary_b or item.b or 255
         )
      end
      return
   end

   local finishMat = GetArchiveFinishMaterial() or GetArchiveSourceMaterial(item)
   if finishMat then
      local baseColorId = type(finishMat.id) == "table" and finishMat.id[1] or finishMat.id
      SET_VEHICLE_COLOURS(vehicle, baseColorId or 0, baseColorId or 0)
      SET_VEHICLE_MOD_COLOR_1(vehicle, finishMat.type or 1, baseColorId or 0, pearl or 0)
      SET_VEHICLE_MOD_COLOR_2(vehicle, finishMat.type or 1, baseColorId or 0)
   else
      SET_VEHICLE_COLOURS(vehicle, 0, 0)
   end
   SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   SET_VEHICLE_EXTRA_COLOURS(vehicle, pearl or 0, wheelColor or 0)
end

local function ArchiveMatchHeadlightIndex(item)
   local h = select(1, ArchiveRgbToHsv(item and item.r or 255, item and item.g or 255, item and item.b or 255)) or 0
   h = h % 360
   if h < 15 or h > 345 then return 8
   elseif h < 45 then return 7
   elseif h < 65 then return 5
   elseif h < 100 then return 4
   elseif h < 150 then return 3
   elseif h < 190 then return 2
   elseif h < 245 then return 1
   elseif h < 280 then return 11
   elseif h < 310 then return 12
   elseif h < 345 then return 10
   else return 0 end
end

local function BeginArchivePreview(item)
   local vehicle = ArchiveGetVehicleHandle()
   if not vehicle or not item then return end

   if previewState.active and previewState.vehicle ~= vehicle then
      RestorePaintSnapshot(true)
   end
   if not previewState.active then
      previewState.snapshot = CapturePaintSnapshot(vehicle)
      if not previewState.snapshot then return end
      previewState.vehicle = vehicle
      previewState.active = true
   end

   local wheelColor = previewState.snapshot and previewState.snapshot.wheel or 0
   local pearl = tonumber(item.pearl_id)
   if pearl == nil then pearl = previewState.snapshot and previewState.snapshot.pearl or 0 end

   SET_VEHICLE_MOD_KIT(vehicle, 0)
   ApplyArchivePaintToVehicle(vehicle, item, wheelColor, pearl)

   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchTyreSmoke) then
      TOGGLE_VEHICLE_MOD(vehicle, 20, true)
      SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchHeadlights) then
      TOGGLE_VEHICLE_MOD(vehicle, 22, true)
      _SET_VEHICLE_XENON_LIGHT_COLOR(vehicle, ArchiveMatchHeadlightIndex(item))
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchNeon) then
      for i = 0, 3 do _SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, i, true) end
      _SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   end

   previewState.selected = item
   archiveView.selected = item
end

local function SyncArchiveTyreSmokeToggle()
   if not previewState.active or not previewState.snapshot then return end
   local vehicle = previewState.vehicle
   local exists = false
   pcall(function() exists = vehicle ~= 0 and DOES_ENTITY_EXIST(vehicle) end)
   if not exists then return end

   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchTyreSmoke) and previewState.selected then
      local item = previewState.selected
      TOGGLE_VEHICLE_MOD(vehicle, 20, true)
      SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   else
      local snap = previewState.snapshot
      TOGGLE_VEHICLE_MOD(vehicle, 20, snap.tyreSmokeEnabled == true)
      SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, snap.tr or 255, snap.tg or 255, snap.tb or 255)
   end
end

local function SyncArchiveHeadlightsToggle()
   if not previewState.active or not previewState.snapshot then return end
   local vehicle = previewState.vehicle
   local exists = false
   pcall(function() exists = vehicle ~= 0 and DOES_ENTITY_EXIST(vehicle) end)
   if not exists then return end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchHeadlights) and previewState.selected then
      TOGGLE_VEHICLE_MOD(vehicle, 22, true)
      _SET_VEHICLE_XENON_LIGHT_COLOR(vehicle, ArchiveMatchHeadlightIndex(previewState.selected))
   else
      local snap = previewState.snapshot
      TOGGLE_VEHICLE_MOD(vehicle, 22, snap.xenonEnabled == true)
      _SET_VEHICLE_XENON_LIGHT_COLOR(vehicle, tonumber(snap.xenonColor) or 0)
   end
end

local function SyncArchiveNeonToggle()
   if not previewState.active or not previewState.snapshot then return end
   local vehicle = previewState.vehicle
   local exists = false
   pcall(function() exists = vehicle ~= 0 and DOES_ENTITY_EXIST(vehicle) end)
   if not exists then return end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchNeon) and previewState.selected then
      local item = previewState.selected
      for i = 0, 3 do _SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, i, true) end
      _SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, item.r or 255, item.g or 255, item.b or 255)
   else
      local snap = previewState.snapshot
      for i = 0, 3 do
         local enabled = type(snap.neonEnabled) == "table" and snap.neonEnabled[i + 1] == true or false
         _SET_VEHICLE_NEON_LIGHT_ENABLED(vehicle, i, enabled)
      end
      _SET_VEHICLE_NEON_LIGHTS_COLOUR(vehicle, snap.nr or 255, snap.ng or 255, snap.nb or 255)
   end
end

local function AdoptArchivePaintAsEditorBase(item)
   if not item then return end

   local materialIndex = nil
   local finishOverrideIndex = FeatureMgr.GetFeatureListIndex(F.ArchiveFinish) or 0
   if finishOverrideIndex > 0 then
      materialIndex = math.max(0, math.min(5, finishOverrideIndex - 1))
   elseif item.is_exotic == true and type(item.exotic_preset) == "table" then
      materialIndex = LegacyMaterialIndexToCurrent(item.exotic_preset.material)
   elseif item.original_finish and item.original_finish ~= "" then
      materialIndex = FindMaterialIndexByName(item.original_finish)
   end

   if materialIndex == nil and (FeatureMgr.GetFeatureListIndex(F.Material) or 0) == 6 then
      materialIndex = 0
   end
   if materialIndex ~= nil then
      FeatureMgr.SetFeatureListIndex(F.Material, materialIndex)
      if UpdatePresetColorList then UpdatePresetColorList() end
   end

   local r, g, b = math.floor(tonumber(item.r) or 255), math.floor(tonumber(item.g) or 255), math.floor(tonumber(item.b) or 255)
   FeatureMgr.SetFeatureColor(F.PrimaryColor, r, g, b, 255)

   if FeatureMgr.IsFeatureEnabled(F.SyncMode) then
      FeatureMgr.SetFeatureColor(F.SecondaryColor, r, g, b, 255)
      FeatureMgr.SetFeatureColor(F.NeonColor, r, g, b, 255)
      FeatureMgr.SetFeatureColor(F.TyreSmokeColor, r, g, b, 255)
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchTyreSmoke) then
      FeatureMgr.SetFeatureColor(F.TyreSmokeColor, r, g, b, 255)
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchHeadlights) then
      FeatureMgr.SetFeatureListIndex(F.XenonColor, ArchiveMatchHeadlightIndex(item))
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveMatchNeon) then
      FeatureMgr.SetFeatureColor(F.NeonColor, r, g, b, 255)
      local neonFeat = FeatureMgr.GetFeature(F.EnableNeon)
      if neonFeat then neonFeat:SetBoolValue(true) end
   end

   if item.pearl_id ~= nil then
      local pearlFeat = FeatureMgr.GetFeature(F.EnablePearl)
      if pearlFeat then pearlFeat:SetBoolValue(true) end
      local linkFeat = FeatureMgr.GetFeature(F.LinkPearl)
      if linkFeat then linkFeat:SetBoolValue(false) end
      FeatureMgr.SetFeatureInt(F.PrimaryPearl, math.max(0, math.min(160, math.floor(tonumber(item.pearl_id) or 0))))
   end

   -- the committed preset becomes the clean base. mixer changes start from neutral.
   FeatureMgr.SetFeatureInt(F.Brightness, 100)
   FeatureMgr.SetFeatureInt(F.Saturation, 100)
   FeatureMgr.SetFeatureInt(F.HueShift, 0)
   FeatureMgr.SetFeatureInt(F.Contrast, 0)
   FeatureMgr.SetFeatureInt(F.Temperature, 0)
   local invertFeat = FeatureMgr.GetFeature(F.InvertColors)
   if invertFeat then invertFeat:SetBoolValue(false) end
end

local function CommitArchivePreview()
   if not previewState.active or not previewState.selected then return end
   local item = previewState.selected
   _G.GTA_PAINTJOB_LAST_COMMITTED = {
      vehicle = previewState.vehicle,
      name = item.name,
      hex = item.hex,
      full_hex = item.full_hex,
      pearl_name = item.pearl_name,
      pearl_id = item.pearl_id,
      archive_id = item.archive_id,
      family = item.family,
   }
   AdoptArchivePaintAsEditorBase(item)
   previewState.active = false
   previewState.snapshot = nil
   previewState.vehicle = 0
   previewState.selected = nil
   archiveView.selected = item
   GUI.AddToast("PaintLabs", "Applied & kept: " .. tostring(item.name), 2500)
end

local function ToggleArchiveFavorite(item)
   if not item then return end
   local key = ArchiveItemKey(item)
   if key == "" then return end
   if archiveFavorites[key] then
      archiveFavorites[key] = nil
      GUI.AddToast("PaintLabs", "Removed favorite: " .. tostring(item.name), 1800)
   else
      archiveFavorites[key] = true
      if item.is_remix_gallery == true and item.is_saved_remix ~= true then
         PersistRemixFavorite(item)
         local alreadyLoaded = false
         for _, existing in ipairs(archiveLibrary) do
            if ArchiveItemKey(existing) == key then alreadyLoaded = true; break end
         end
         if not alreadyLoaded then
            local clone = { name = tostring(item.name or "Saved Remix"), hex = tostring(item.hex or "#FFFFFF"), full_hex = tostring(item.full_hex or ((item.hex or "#FFFFFF") .. "AA")),
               r = tonumber(item.r) or 255, g = tonumber(item.g) or 255, b = tonumber(item.b) or 255, pearl_name = tostring(item.pearl_name or ""), pearl_id = tonumber(item.pearl_id), archive_id = key, confidence = item.pearl_id ~= nil and "high" or "medium", is_remix_gallery = true, is_saved_remix = true }
            clone._archive_index = #archiveLibrary + 1
            clone._archive_key = key
            clone.base_family = ClassifyArchiveColor(clone)
            clone.family = clone.base_family
            local h, s2, v = ArchiveRgbToHsv(clone.r, clone.g, clone.b)
            clone._hue, clone._saturation, clone._value = h, s2, v
            clone._brightness = (((clone.r or 0) * 0.2126) + ((clone.g or 0) * 0.7152) + ((clone.b or 0) * 0.0722)) / 255.0
            archiveLibrary[#archiveLibrary + 1] = clone
         end
      end
      GUI.AddToast("PaintLabs", "Favorited: " .. tostring(item.name), 1800)
   end
   SaveArchiveFavorites()
   archiveView.signature = ""
end

local function ArchiveFavoriteCount()
   local n = 0
   for _, enabled in pairs(archiveFavorites) do if enabled then n = n + 1 end end
   return n
end

local function IsArchiveExoticSectionItem(item)
   return item ~= nil and (item.is_exotic == true or item.is_exotic_gallery == true)
end

local function IsArchiveAiSectionItem(item)
   return item ~= nil and item.is_ai_gallery == true
end

local function IsArchiveRemixSectionItem(item)
   return item ~= nil and item.is_remix_gallery == true
end

local function GetArchiveDisplayFamily(item)
   if IsArchiveRemixSectionItem(item) then return "Remix" end
   if IsArchiveAiSectionItem(item) then return "Ai" end
   if IsArchiveExoticSectionItem(item) then return "Exotic" end
   return tostring(item and (item.family or item.base_family) or "Unknown")
end

local function RefreshArchiveFilter(force)
   local search = string.lower(tostring(FeatureMgr.GetFeatureString(F.ArchiveSearch) or ""))
   local familyIndex = FeatureMgr.GetFeatureListIndex(F.ArchiveColorFamily) or 0
   local family = archiveColorFamilies[familyIndex + 1] or "All"
   local brightnessOrder = FeatureMgr.GetFeatureListIndex(F.ArchiveBrightnessOrder) or 0
   if family == "Gradient" then brightnessOrder = 3 end
   local inGamePearlOnly = FeatureMgr.IsFeatureEnabled(F.ArchiveReadyOnly)
   local signature = search .. "|" .. family .. "|" .. tostring(brightnessOrder) .. "|" .. tostring(inGamePearlOnly) .. "|" .. tostring(ArchiveFavoriteCount()) .. "|remix:" .. tostring(remixGeneration)
   if not force and signature == archiveView.signature then return end

   archiveView.signature = signature
   archiveView.filtered = {}
   archiveView.autoIndex = 0
   archiveView.nextCycleMs = 0

   local sourceItems = family == "Remix" and remixResults or archiveLibrary
   for _, item in ipairs(sourceItems) do
      local hasInGamePearl = item.pearl_id ~= nil
         and item.name and item.name ~= ""
         and (tostring(item.confidence or "") == "high" or item.is_exotic == true or item.is_remix_gallery == true)
      local displayFamily = GetArchiveDisplayFamily(item)
      local favoriteOK = family ~= "Favorites" or IsArchiveFavorite(item)
      local familyOK = family == "All" or family == "Favorites" or family == "Gradient" or displayFamily == family
      local savedRemixOK = item.is_saved_remix ~= true or family == "Favorites"
      local hay = string.lower((item.name or "") .. " " .. (item.hex or "") .. " " .. (item.pearl_name or "") .. " " .. displayFamily .. " " .. (item.family or ""))
      local searchOK = search == "" or string.find(hay, search, 1, true) ~= nil
      local brightness = tonumber(item._brightness) or 0
      local rangeOK = true
      if brightnessOrder == 7 then rangeOK = brightness <= 0.38
      elseif brightnessOrder == 8 then rangeOK = brightness >= 0.62
      elseif brightnessOrder == 9 then rangeOK = brightness > 0.38 and brightness < 0.62 end
      if favoriteOK and familyOK and savedRemixOK and searchOK and rangeOK and (not inGamePearlOnly or hasInGamePearl) then
         archiveView.filtered[#archiveView.filtered + 1] = item
      end
   end

   local function HueCompare(a, b, reverse)
      local as = tonumber(a._saturation) or 0
      local bs = tonumber(b._saturation) or 0
      local an = as < 0.08
      local bn = bs < 0.08
      if an ~= bn then return not an end -- keep neutral gray/white/black after chromatic colors
      local ah, bh = tonumber(a._hue) or 0, tonumber(b._hue) or 0
      if math.abs(ah - bh) > 0.001 then
         if reverse then return ah > bh end
         return ah < bh
      end
      local ab, bb = tonumber(a._brightness) or 0, tonumber(b._brightness) or 0
      if math.abs(ab - bb) > 0.0001 then return ab > bb end
      return nil
   end

   table.sort(archiveView.filtered, function(a, b)
      local ab = tonumber(a._brightness) or 0
      local bb = tonumber(b._brightness) or 0
      local as = tonumber(a._saturation) or 0
      local bs = tonumber(b._saturation) or 0
      local an, bn = string.lower(tostring(a.name or "")), string.lower(tostring(b.name or ""))

      -- legacy grouped modes keep all/favorites visually organized by section.
      if brightnessOrder <= 2 then
         local ar = archiveFamilyRank[GetArchiveDisplayFamily(a)] or 999
         local br = archiveFamilyRank[GetArchiveDisplayFamily(b)] or 999
         if ar ~= br then return ar < br end
      end

      if brightnessOrder == 0 and math.abs(ab - bb) > 0.0001 then return ab > bb
      elseif brightnessOrder == 1 and math.abs(ab - bb) > 0.0001 then return ab < bb
      elseif brightnessOrder == 2 or brightnessOrder == 3 then
         local result = HueCompare(a, b, false); if result ~= nil then return result end
      elseif brightnessOrder == 4 then
         local result = HueCompare(a, b, true); if result ~= nil then return result end
      elseif brightnessOrder == 5 and math.abs(as - bs) > 0.0001 then return as > bs
      elseif brightnessOrder == 6 and math.abs(as - bs) > 0.0001 then return as < bs
      elseif brightnessOrder == 7 and math.abs(ab - bb) > 0.0001 then return ab < bb
      elseif brightnessOrder == 8 and math.abs(ab - bb) > 0.0001 then return ab > bb
      elseif brightnessOrder == 9 then
         local result = HueCompare(a, b, false); if result ~= nil then return result end
      elseif brightnessOrder == 10 and an ~= bn then return an < bn
      elseif brightnessOrder == 11 and an ~= bn then return an > bn end

      if an ~= bn then return an < bn end
      return tostring(a.hex or "") < tostring(b.hex or "")
   end)
end

-- cherax imgui compatibility
-- note: vec2 calls may return two numbers or one userdata/table. never pass the vec2
-- object directly to tonumber(), because it can kill the clickgui coroutine.
local function ReadImGuiVec2(getter, fallbackX, fallbackY)
   fallbackX = tonumber(fallbackX) or 0
   fallbackY = tonumber(fallbackY) or 0

   local ok, a, b = pcall(function() return getter() end)
   if not ok then return fallbackX, fallbackY end

   if type(a) == "number" then
      return a, (type(b) == "number" and b or fallbackY)
   end

   if type(a) == "table" or type(a) == "userdata" then
      local function NumericField(key)
         local fieldOk, value = pcall(function() return a[key] end)
         if fieldOk and type(value) == "number" then return value end
         return nil
      end

      local x = NumericField("x") or NumericField("X") or NumericField(1)
      local y = NumericField("y") or NumericField("Y") or NumericField(2)
      return x or fallbackX, y or fallbackY
   end

   return fallbackX, fallbackY
end

local function GetImGuiContentRegionSize()
   return ReadImGuiVec2(function() return ImGui.GetContentRegionAvail() end, 620, 0)
end

local function GetImGuiCursorPosition()
   return ReadImGuiVec2(function() return ImGui.GetCursorScreenPos() end, 0, 0)
end

local function RenderArchiveColorTooltip(item)
   if not item then return end
   ImGui.BeginTooltip()
   ImGui.Text(tostring(item.name or "Unnamed"))
   ImGui.Text(tostring(item.hex or ""))
   local x, y = GetImGuiCursorPosition()
   ImGui.Dummy(112, 112)
   local cx, cy = x + 56, y + 56
   ImGui.AddCircleFilled(cx, cy, 47, item.r or 255, item.g or 255, item.b or 255, 255, 48)
   ImGui.AddCircle(cx, cy, 48, 255, 255, 255, 230, 48, 2.0)
   ImGui.Text("Family: " .. tostring(GetArchiveDisplayFamily(item)))
   ImGui.Text(string.format("Brightness: %d%%", math.floor(((tonumber(item._brightness) or 0) * 100) + 0.5)))
   if item.pearl_id == nil and item.pearl_name and item.pearl_name ~= "" then
      ImGui.Text("Pearl reference: " .. tostring(item.pearl_name) .. " (ID unresolved; current pearl preserved)")
   else
      ImGui.Text("Pearl: " .. tostring((item.pearl_name and item.pearl_name ~= "") and item.pearl_name or "Original pearl"))
   end
   if item.is_forum_import == true then
      ImGui.TextColored(0.45, 0.90, 1.00, 1.00, "GTA FORUMS • OCR-reviewed import")
      if item.original_finish and item.original_finish ~= "" then ImGui.Text("Original finish: " .. tostring(NormalizeMaterialName(item.original_finish))) end
   end
   ImGui.Text("Finish: " .. tostring(GetArchiveFinishLabel()))
   if item.is_exotic == true and type(item.exotic_preset) == "table" then
      local p = item.exotic_preset
      local mat = Materials[LegacyMaterialIndexToCurrent(p.material) + 1] or Materials[1]
      ImGui.TextColored(1.00, 0.72, 0.28, 1.00, "EXOTIC PRESET • " .. tostring(mat.name or "Custom") .. " • click for full preset")
   elseif item.is_exotic_gallery == true then
      ImGui.TextColored(1.00, 0.72, 0.28, 1.00, "EXOTIC PEARL • curated pearlescent favorite")
   elseif item.is_remix_gallery == true then
      if tostring(item.remix_mode or "color") == "pearlescent" then
      ImGui.TextColored(0.35, 1.00, 0.72, 1.00, "PEARL REMIX • same base color with in-game pearlescent variants")
   else
      ImGui.TextColored(0.35, 1.00, 0.72, 1.00, "REMIX • close relative of " .. tostring(item.remix_seed_name or "a selected paint"))
   end
   elseif item.is_ai_gallery == true then
      ImGui.TextColored(0.45, 0.90, 1.00, 1.00, "AI CHAOS • deliberately mismatched base + pearl")
   end
   local sourceCredits = GetArchiveColorCredits(item)
   if sourceCredits and #sourceCredits > 0 then
      ImGui.Separator()
      ImGui.TextColored(1.00, 0.55, 0.85, 1.00, "COLOR CREDIT")
      for _, credit in ipairs(sourceCredits) do
         ImGui.Text(tostring(credit.platform or "Source") .. ": " .. tostring(credit.name or "Unknown"))
      end
   end
   ImGui.EndTooltip()
end

local function HandleArchiveHover(item)
   if not item then return end
   local key = ArchiveItemKey(item)
   local now = NowMs()
   if archiveView.hoverCandidateKey ~= key then
      archiveView.hoverCandidateKey = key
      archiveView.hoverCandidateSince = now
      return
   end
   if FeatureMgr.IsFeatureEnabled(F.ArchiveHoverPreview)
      and archiveView.lastHoveredKey ~= key
      and (now - (archiveView.hoverCandidateSince or now)) >= 140 then
      BeginArchivePreview(item)
      archiveView.lastHoveredKey = key
      local seconds = math.max(1, FeatureMgr.GetFeatureInt(F.ArchiveShowcaseSeconds) or 5)
      archiveView.nextCycleMs = now + (seconds * 1000)
   end
end

local function ArchiveShortText(text, maxChars)
   text = tostring(text or "")
   maxChars = math.max(4, tonumber(maxChars) or 16)
   if #text <= maxChars then return text end
   return text:sub(1, maxChars - 3) .. "..."
end

local function SetArchiveFamily(index)
   index = math.max(0, math.min(#archiveColorFamilies - 1, tonumber(index) or 0))
   FeatureMgr.SetFeatureListIndex(F.ArchiveColorFamily, index)
   archiveView.signature = ""
end

local function ArchiveHsvToRgb(h, s, v)
   h = ((tonumber(h) or 0) % 360) / 60
   s = math.max(0, math.min(1, tonumber(s) or 0)); v = math.max(0, math.min(1, tonumber(v) or 0))
   local c = v * s; local x = c * (1 - math.abs((h % 2) - 1)); local m = v - c
   local r1, g1, b1 = 0, 0, 0
   if h < 1 then r1, g1, b1 = c, x, 0 elseif h < 2 then r1, g1, b1 = x, c, 0 elseif h < 3 then r1, g1, b1 = 0, c, x elseif h < 4 then r1, g1, b1 = 0, x, c elseif h < 5 then r1, g1, b1 = x, 0, c else r1, g1, b1 = c, 0, x end
   return math.floor((r1 + m) * 255 + 0.5), math.floor((g1 + m) * 255 + 0.5), math.floor((b1 + m) * 255 + 0.5)
end

local function RemixPearlFamily(name)
   local n = string.lower(tostring(name or ""))
   if n:find("pink",1,true) then return "pink" elseif n:find("red",1,true) then return "red" elseif n:find("orange",1,true) then return "orange" elseif n:find("yellow",1,true) or n:find("gold",1,true) then return "yellow" elseif n:find("green",1,true) or n:find("lime",1,true) then return "green" elseif n:find("blue",1,true) then return "blue" elseif n:find("purple",1,true) then return "purple" elseif n:find("white",1,true) or n:find("silver",1,true) then return "white" end
   return "other"
end

local function BuildRemixPearlPool(seed)
   local pool, seen = {}, {}; local seedFamily = RemixPearlFamily(seed and seed.pearl_name)
   for _, item in ipairs(archiveLibrary) do
      local pid = tonumber(item.pearl_id)
      if pid ~= nil and tostring(item.confidence or "") == "high" and not seen[pid] and RemixPearlFamily(item.pearl_name) == seedFamily and seedFamily ~= "other" then
         seen[pid] = true; pool[#pool + 1] = { id = pid, name = tostring(item.pearl_name or ("Pearl " .. tostring(pid))) }
      end
   end
   return pool
end

local function BuildAllConfirmedPearlPool(seed)
   local ordered, seen = {}, {}
   local function AddPearl(pid, name)
      pid = tonumber(pid)
      if pid == nil or seen[pid] then return end
      seen[pid] = true
      ordered[#ordered + 1] = { id = pid, name = tostring(name or ("Pearl " .. tostring(pid))) }
   end
   if seed and seed.pearl_id ~= nil then AddPearl(seed.pearl_id, seed.pearl_name) end
   for _, item in ipairs(archiveLibrary) do
      if tostring(item.confidence or "") == "high" then AddPearl(item.pearl_id, item.pearl_name) end
   end
   table.sort(ordered, function(a, b)
      local an, bn = string.lower(tostring(a.name or "")), string.lower(tostring(b.name or ""))
      if an ~= bn then return an < bn end
      return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
   end)
   if seed and seed.pearl_id ~= nil and #ordered > 1 then
      for i, item in ipairs(ordered) do
         if tonumber(item.id) == tonumber(seed.pearl_id) then
            local first = table.remove(ordered, i)
            table.insert(ordered, 1, first)
            break
         end
      end
   end
   return ordered
end

local function GenerateArchiveRemix(seed)
   if not seed then GUI.AddToast("PaintLabs", "Select or hover a paint first.", 2200); return end
   remixGeneration = remixGeneration + 1; remixSeedName = tostring(seed.name or "Selected Paint"); remixMode = "color"; remixResults = {}
   local baseH, baseS, baseV = ArchiveRgbToHsv(seed.r or 255, seed.g or 255, seed.b or 255)
   local seedPearlId, seedPearlName = tonumber(seed.pearl_id), tostring(seed.pearl_name or "")
   if seedPearlId == nil then
      local fallbackPool = BuildAllConfirmedPearlPool(seed)
      if #fallbackPool > 0 then
         local picked = fallbackPool[math.random(1, #fallbackPool)]
         seedPearlId, seedPearlName = picked.id, picked.name
      end
   end
   local seedForPool = { pearl_name = seedPearlName }
   local pearlPool, used, attempts = BuildRemixPearlPool(seedForPool), {}, 0
   while #remixResults < 50 and attempts < 2500 do
      attempts = attempts + 1
      local idx2 = #remixResults + 1; local strength = (idx2 <= 30) and 1.0 or ((idx2 <= 44) and 1.45 or 2.0)
      local hueDelta = ((math.random(0,10000)/10000.0)*2-1) * (5.5*strength)
      local satDelta = ((math.random(0,10000)/10000.0)*2-1) * (0.065*strength)
      local valDelta = ((math.random(0,10000)/10000.0)*2-1) * (0.075*strength)
      local h = (baseH + hueDelta) % 360; local s3 = math.max(0, math.min(1, baseS + satDelta)); local v3 = math.max(0.02, math.min(1, baseV + valDelta))
      local r,g,b = ArchiveHsvToRgb(h,s3,v3); local hex = string.format("#%02X%02X%02X",r,g,b)
      local pearlId, pearlName = seedPearlId, seedPearlName
      if #pearlPool > 1 and idx2 > 38 and math.random(1,100) <= 70 then local cnd = pearlPool[math.random(1,#pearlPool)]; pearlId, pearlName = cnd.id, cnd.name end
      local comboKey = hex .. "|" .. tostring(pearlId or ""); local seedKey = tostring(seed.hex or "") .. "|" .. tostring(seedPearlId or "")
      if not used[comboKey] and comboKey ~= seedKey then
         used[comboKey] = true; local archiveId = "saved-remix:" .. hex .. ":" .. tostring(pearlId or "current")
         local item = { name = string.format("Remix %02d • %s",idx2,remixSeedName), hex=hex, full_hex=hex.."AA", r=r,g=g,b=b, pearl_name=pearlName, pearl_id=pearlId, archive_id=archiveId, confidence=pearlId~=nil and "high" or "medium", is_remix_gallery=true, remix_seed_name=remixSeedName, remix_mode="color" }
         item._archive_index = 900000 + remixGeneration*100 + idx2; item._archive_key=archiveId; item.base_family=ClassifyArchiveColor(item); item.family=item.base_family
         item._hue,item._saturation,item._value=ArchiveRgbToHsv(r,g,b); item._brightness=((r*0.2126)+(g*0.7152)+(b*0.0722))/255.0
         remixResults[#remixResults+1]=item
      end
   end
   local remixIndex=0; for i,familyName in ipairs(archiveColorFamilies) do if familyName=="Remix" then remixIndex=i-1; break end end
   SetArchiveFamily(remixIndex); archiveView.signature=""; archiveView.selected=remixResults[1] or seed
   GUI.AddToast("PaintLabs", "Generated 50 Remix colors from: " .. remixSeedName, 2600)
end

local function GenerateArchivePearlescentRemix(seed)
   if not seed then GUI.AddToast("PaintLabs", "Select or hover a paint first.", 2200); return end
   remixGeneration = remixGeneration + 1; remixSeedName = tostring(seed.name or "Selected Paint"); remixMode = "pearlescent"; remixResults = {}
   local baseR, baseG, baseB = tonumber(seed.r) or 255, tonumber(seed.g) or 255, tonumber(seed.b) or 255
   local baseHex = string.format("#%02X%02X%02X", baseR, baseG, baseB)
   local pearlPool = BuildAllConfirmedPearlPool(seed)
   if #pearlPool <= 0 then GUI.AddToast("PaintLabs", "No confirmed in-game pearlescents are available.", 2400); return end
   local shuffled = {}
   for i = 1, #pearlPool do shuffled[i] = pearlPool[i] end
   for i = #shuffled, 2, -1 do
      local j = math.random(1, i)
      shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
   end
   if tonumber(seed.pearl_id) ~= nil then
      for i, item in ipairs(shuffled) do
         if tonumber(item.id) == tonumber(seed.pearl_id) then
            local first = table.remove(shuffled, i)
            table.insert(shuffled, 1, first)
            break
         end
      end
   end
   local count = math.min(50, #shuffled)
   for idx2 = 1, count do
      local pearl = shuffled[idx2]
      local pearlId, pearlName = tonumber(pearl.id), tostring(pearl.name or ("Pearl " .. tostring(pearl.id)))
      local archiveId = "saved-remix-pearl:" .. baseHex .. ":" .. tostring(pearlId or "current")
      local item = { name = string.format("Pearl Remix %02d • %s", idx2, remixSeedName), hex=baseHex, full_hex=baseHex.."AA", r=baseR,g=baseG,b=baseB, pearl_name=pearlName, pearl_id=pearlId, archive_id=archiveId, confidence=pearlId~=nil and "high" or "medium", is_remix_gallery=true, remix_seed_name=remixSeedName, remix_mode="pearlescent" }
      item._archive_index = 950000 + remixGeneration*100 + idx2; item._archive_key=archiveId; item.base_family=ClassifyArchiveColor(item); item.family=item.base_family
      item._hue,item._saturation,item._value=ArchiveRgbToHsv(baseR,baseG,baseB); item._brightness=((baseR*0.2126)+(baseG*0.7152)+(baseB*0.0722))/255.0
      remixResults[#remixResults+1] = item
   end
   local remixIndex=0; for i,familyName in ipairs(archiveColorFamilies) do if familyName=="Remix" then remixIndex=i-1; break end end
   SetArchiveFamily(remixIndex); archiveView.signature=""; archiveView.selected=remixResults[1] or seed
   GUI.AddToast("PaintLabs", "Generated 50 Pearlescent Remix colors from: " .. remixSeedName, 2600)
end

local function ArchiveFamilyButtonColor(name)
   local colors = {
      ["Exotic"]={0.95,0.52,0.18}, ["Ai"]={0.20,0.78,1.00}, ["Remix"]={0.20,0.88,0.62},
      ["Pink & Magenta"]={0.95,0.22,0.64}, ["Red"]={0.88,0.16,0.18}, ["Orange"]={1.00,0.43,0.10},
      ["Yellow & Gold"]={0.92,0.72,0.12}, ["Green"]={0.18,0.72,0.28}, ["Cyan & Teal"]={0.08,0.70,0.72},
      ["Blue"]={0.16,0.38,0.92}, ["Purple & Violet"]={0.52,0.24,0.88}, ["Brown & Tan"]={0.48,0.30,0.17},
      ["White & Cream"]={0.82,0.80,0.70}, ["Gray & Silver"]={0.45,0.48,0.55}, ["Black & Dark"]={0.12,0.12,0.16}
   }
   return colors[name] or {0.38,0.30,0.52}
end

local function RenderArchiveGradientButton(label, id, width, selected, favoriteGradient)
   local x,y = GetImGuiCursorPosition()
   local height = 27
   ImGui.InvisibleButton(label .. "##" .. id, width, height)
   local clicked, hovered = ImGui.IsItemClicked(), ImGui.IsItemHovered()
   local c1,c2
   if favoriteGradient then
      c1 = ImGui.ColorConvertRGBAToU32({255,190,45,255}); c2 = ImGui.ColorConvertRGBAToU32({235,72,180,255})
   else
      c1 = ImGui.ColorConvertRGBAToU32({240,55,70,255}); c2 = ImGui.ColorConvertRGBAToU32({65,105,245,255})
   end
   ImGui.AddRectFilledMultiColor(x,y,x+width,y+height,c1,c2,c2,c1)
   if selected or hovered then ImGui.AddRect(x,y,x+width,y+height,255,255,255,selected and 255 or 185,4.0,0,selected and 2.3 or 1.4) end
   local tx = x + math.max(7, (width - (#label * 7)) * 0.5)
   ImGui.AddText(tx, y + 6, label, 255,255,255,255)
   return clicked
end

local function RenderArchiveFamilyButtons()
   ImGui.TextColored(0.72, 0.38, 1.00, 1.00, "Families")
   local selected = FeatureMgr.GetFeatureListIndex(F.ArchiveColorFamily) or 0
   local available = select(1, GetImGuiContentRegionSize())
   local columns = 4
   local buttonWidth = math.max(105, (available - 24) / columns)
   if ImGui.BeginTable("ArchiveFamilyButtonGrid", columns, ImGuiTableFlags.SizingStretchSame) then
      for i, familyName in ipairs(archiveColorFamilies) do
         ImGui.TableNextColumn()
         local isSelected = selected == (i - 1)
         local clicked = false
         if familyName == "All" or familyName == "Gradient" or familyName == "Favorites" then
            clicked = RenderArchiveGradientButton(tostring(familyName), "ArchiveFamilyGradient_" .. tostring(i), buttonWidth, isSelected, familyName == "Favorites")
         else
            local c = ArchiveFamilyButtonColor(familyName)
            local mul = isSelected and 1.12 or 0.82
            ImGui.PushStyleColor(ImGuiCol.Button, math.min(1,c[1]*mul), math.min(1,c[2]*mul), math.min(1,c[3]*mul), 1.00)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, math.min(1,c[1]*1.12), math.min(1,c[2]*1.12), math.min(1,c[3]*1.12), 1.00)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, c[1], c[2], c[3], 1.00)
            clicked = ImGui.Button(tostring(familyName) .. "##ArchiveFamilyButton_" .. tostring(i), buttonWidth, 0)
            ImGui.PopStyleColor(3)
         end
         if clicked then SetArchiveFamily(i - 1) end
      end
      ImGui.EndTable()
   end
end

local function RenderArchiveGridTile(item, tileWidth)
   if not item then return false end
   tileWidth = math.max(96, tonumber(tileWidth) or 116)
   local tileHeight = 88
   local colorHeight = 57
   local x, y = GetImGuiCursorPosition()

   ImGui.PushID("ArchiveGridTile_" .. tostring(item._archive_index or 0))
   local clicked = ImGui.InvisibleButton("##Tile", tileWidth, tileHeight)
   local hovered = ImGui.IsItemHovered()
   local favorite = IsArchiveFavorite(item)

   ImGui.AddRectFilled(x, y, x + tileWidth, y + tileHeight, 12, 13, 20, 238, 6.0)
   ImGui.AddRectFilled(x + 2, y + 2, x + tileWidth - 2, y + colorHeight, item.r or 255, item.g or 255, item.b or 255, 255, 5.0)
   ImGui.AddRectFilled(x + 2, y + colorHeight - 2, x + tileWidth - 2, y + tileHeight - 2, 17, 18, 27, 246, 0.0)

   local borderR, borderG, borderB = 150, 108, 205
   if favorite then borderR, borderG, borderB = 255, 205, 72 end
   if hovered then borderR, borderG, borderB = 70, 220, 255 end
   ImGui.AddRect(x, y, x + tileWidth, y + tileHeight, borderR, borderG, borderB, 245, 6.0, 0, hovered and 2.5 or 1.4)

   local nameChars = math.max(10, math.floor(tileWidth / 7.0))
   ImGui.AddText(x + 6, y + colorHeight + 1, ArchiveShortText(item.name or "Unnamed", nameChars), 248, 248, 255, 255)
   ImGui.AddText(x + 6, y + colorHeight + 15, tostring(item.hex or ""), 182, 188, 205, 255)

   if favorite then
      ImGui.AddRectFilled(x + tileWidth - 31, y + 5, x + tileWidth - 5, y + 22, 24, 18, 10, 220, 4.0)
      ImGui.AddText(x + tileWidth - 27, y + 7, "FAV", 255, 214, 82, 255)
   end
   if item.pearl_id ~= nil then
      ImGui.AddRectFilled(x + 5, y + 5, x + 24, y + 22, 5, 12, 20, 205, 4.0)
      ImGui.AddText(x + 11, y + 7, "P", 110, 225, 255, 255)
   end
   if item.is_exotic_gallery == true then
      ImGui.AddRectFilled(x + 29, y + 5, x + 65, y + 22, 45, 25, 5, 220, 4.0)
      ImGui.AddText(x + 34, y + 7, "EXO", 255, 186, 76, 255)
   elseif item.is_remix_gallery == true then
      ImGui.AddRectFilled(x + 29, y + 5, x + 70, y + 22, 4, 42, 32, 225, 4.0)
      ImGui.AddText(x + 34, y + 7, "RMX", 105, 255, 190, 255)
   elseif item.is_ai_gallery == true then
      ImGui.AddRectFilled(x + 29, y + 5, x + 53, y + 22, 5, 32, 48, 220, 4.0)
      ImGui.AddText(x + 34, y + 7, "AI", 110, 225, 255, 255)
   end

   if hovered then
      RenderArchiveColorTooltip(item)
      HandleArchiveHover(item)
   end
   if clicked then
      BeginArchivePreview(item)
      CommitArchivePreview()
      if item.is_exotic == true and ApplyFullExoticPreset then ApplyFullExoticPreset(item) end
      archiveView.selected = item
   end
   ImGui.PopID()
   return hovered
end

local function RenderArchiveGridSection(title, items, sectionId)
   if #items <= 0 then return false end
   if title and title ~= "" then
      ImGui.Spacing()
      ImGui.TextColored(0.72, 0.38, 1.00, 1.00, tostring(title))
      ImGui.SameLine()
      ImGui.TextColored(0.55, 0.58, 0.68, 1.00, "(" .. tostring(#items) .. ")")
   end

   local available = select(1, GetImGuiContentRegionSize())
   local preferredTileWidth = 116
   local columns = math.max(2, math.min(7, math.floor(available / 126)))
   local tileWidth = math.max(96, (available - ((columns - 1) * 10)) / columns)
   local anyHovered = false

   if ImGui.BeginTable("ArchiveColorGrid_" .. tostring(sectionId), columns, ImGuiTableFlags.SizingStretchSame) then
      for _, item in ipairs(items) do
         ImGui.TableNextColumn()
         if RenderArchiveGridTile(item, tileWidth - 7) then anyHovered = true end
      end
      ImGui.EndTable()
   end
   return anyHovered
end

local function RenderArchiveColorGrid(family)
   local anyHovered = false
   local grouped = family == "All" or family == "Favorites"

   if grouped then
      for _, familyName in ipairs(archiveFamilyOrder) do
         local bucket = {}
         for _, item in ipairs(archiveView.filtered) do
            if familyName == "Exotic" then
               if IsArchiveExoticSectionItem(item) then bucket[#bucket + 1] = item end
            elseif familyName == "Ai" then
               if IsArchiveAiSectionItem(item) then bucket[#bucket + 1] = item end
            elseif familyName == "Remix" then
               if IsArchiveRemixSectionItem(item) then bucket[#bucket + 1] = item end
            elseif not IsArchiveExoticSectionItem(item) and not IsArchiveAiSectionItem(item) and not IsArchiveRemixSectionItem(item) and item.family == familyName then
               bucket[#bucket + 1] = item
            end
         end
         if #bucket > 0 and RenderArchiveGridSection(familyName, bucket, familyName) then
            anyHovered = true
         end
      end
   else
      anyHovered = RenderArchiveGridSection(family, archiveView.filtered, family)
   end
   return anyHovered
end

local function RenderSelectedArchivePanel(selected)
   if not selected then
      ImGui.Text("Select a paint")
      return
   end

   ImGui.Text((previewState.active and "Preview: " or "Selected: ") .. tostring(selected.name or "Unnamed"))
   local x, y = GetImGuiCursorPosition()
   ImGui.Dummy(64, 64)
   ImGui.AddCircleFilled(x + 32, y + 32, 27, selected.r or 255, selected.g or 255, selected.b or 255, 255, 36)
   ImGui.AddCircle(x + 32, y + 32, 28, 255, 255, 255, 220, 36, 2.0)
   ImGui.SameLine()
   ImGui.BeginGroup()
   ImGui.Text(tostring(selected.hex or ""))
   local pearlLabel = (selected.pearl_name and selected.pearl_name ~= "") and tostring(selected.pearl_name) or "Original pearl"
   ImGui.Text("Pearl: " .. pearlLabel)
   ImGui.Text("Finish: " .. tostring(GetArchiveFinishLabel()))
   if selected.is_exotic == true then ImGui.TextColored(1.00, 0.72, 0.28, 1.00, "EXOTIC")
   elseif selected.is_remix_gallery == true and tostring(selected.remix_mode or "color") == "pearlescent" then ImGui.TextColored(0.35, 1.00, 0.72, 1.00, "PEARL REMIX")
   elseif selected.is_remix_gallery == true then ImGui.TextColored(0.35, 1.00, 0.72, 1.00, "REMIX")
   elseif selected.is_ai_gallery == true then ImGui.TextColored(0.45, 0.90, 1.00, 1.00, "AI") end
   ImGui.EndGroup()

   if previewState.active then
      if ImGui.Button("Apply##Archive") then
         CommitArchivePreview()
         if selected.is_exotic == true and ApplyFullExoticPreset then ApplyFullExoticPreset(selected) end
      end
      ImGui.SameLine()
      if ImGui.Button("Revert##Archive") then RestorePaintSnapshot(false) end
   else
      if ImGui.Button("Apply##Archive") then
         BeginArchivePreview(selected)
         CommitArchivePreview()
         if selected.is_exotic == true and ApplyFullExoticPreset then ApplyFullExoticPreset(selected) end
      end
   end

   ImGui.SameLine()
   local favLabel = IsArchiveFavorite(selected) and "Unfavorite##SelectedArchive" or "Favorite##SelectedArchive"
   if ImGui.Button(favLabel) then ToggleArchiveFavorite(selected) end
   ImGui.Spacing()
   if ImGui.Button("Remix Color##SelectedArchive", 140, 0) then GenerateArchiveRemix(selected) end
   ImGui.SameLine()
   if ImGui.Button("Remix Pearl##SelectedArchive", 140, 0) then GenerateArchivePearlescentRemix(selected) end
end

local function RenderArchiveBrowser()
   previewState.lastTabRenderMs = NowMs()
   RefreshArchiveFilter(false)

   RenderArchiveFamilyButtons()
   ImGui.Spacing()
   FeatureMgr.GetFeature(F.ArchiveSearch):Render()
   FeatureMgr.GetFeature(F.ArchiveBrightnessOrder):Render()
   FeatureMgr.GetFeature(F.ArchiveReadyOnly):Render()
   ImGui.Separator()
   FeatureMgr.GetFeature(F.ArchiveFinish):Render()
   FeatureMgr.GetFeature(F.ArchiveHoverPreview):Render()
   FeatureMgr.GetFeature(F.ArchiveMatchTyreSmoke):Render()
   FeatureMgr.GetFeature(F.ArchiveMatchHeadlights):Render()
   FeatureMgr.GetFeature(F.ArchiveMatchNeon):Render()
   FeatureMgr.GetFeature(F.ArchiveAutoShowcase):Render()
   if FeatureMgr.IsFeatureEnabled(F.ArchiveAutoShowcase) then FeatureMgr.GetFeature(F.ArchiveShowcaseSeconds):Render() end
   FeatureMgr.GetFeature(F.ArchiveRotateVehicle):Render()
   if FeatureMgr.IsFeatureEnabled(F.ArchiveRotateVehicle) then FeatureMgr.GetFeature(F.ArchiveRotateSpeed):Render() end
   ImGui.Separator()

   local total = #archiveView.filtered
   local familyIndex = FeatureMgr.GetFeatureListIndex(F.ArchiveColorFamily) or 0
   local family = archiveColorFamilies[familyIndex + 1] or "All"
   local orderIndex = FeatureMgr.GetFeatureListIndex(F.ArchiveBrightnessOrder) or 0
   local orderName = archiveBrightnessOrders[orderIndex + 1] or archiveBrightnessOrders[1]
   if family == "Remix" then
      ImGui.Text(string.format("%d Remix • %s", total, remixMode == "pearlescent" and "Pearl" or "Color"))
   else
      ImGui.Text(string.format("%d / %d • %d favorites • %s", total, ARCHIVE_TOTAL_COUNT, ArchiveFavoriteCount(), orderName))
   end
   ImGui.Separator()

   local anyHovered = false
   local childVisible = true
   if ImGui.BeginChild then childVisible = ImGui.BeginChild("ArchiveAllColorsGrid", 0, 540, true) ~= false end
   if childVisible then
      if total <= 0 then
         ImGui.Text(family == "Remix" and "No Remix yet" or "No matches")
      else
         anyHovered = RenderArchiveColorGrid(family)
      end
   end
   if ImGui.EndChild then ImGui.EndChild() end

   if not anyHovered then
      archiveView.hoverCandidateKey = ""
      archiveView.lastHoveredKey = ""
   end

   ImGui.Separator()
   RenderSelectedArchivePanel(archiveView.selected)
end

local function RestoreArchiveRotation()
   if not rotationState.active then return end
   local vehicle = rotationState.vehicle
   local exists = false
   pcall(function() exists = vehicle ~= 0 and DOES_ENTITY_EXIST(vehicle) end)
   if exists then
      local speed = 0.0
      pcall(function() speed = tonumber(GET_ENTITY_SPEED(vehicle)) or 0.0 end)
      if speed < 0.55 then pcall(SET_ENTITY_HEADING, vehicle, rotationState.originalHeading or 0.0) end
   end
   rotationState.active = false
   rotationState.vehicle = 0
   rotationState.originalHeading = 0.0
   rotationState.lastMs = 0
end

local function UpdateArchiveRotation(now, tabActive)
   local enabled = FeatureMgr.IsFeatureEnabled(F.ArchiveRotateVehicle)
   local vehicle = ArchiveGetVehicleHandle()
   if not enabled or not tabActive or not vehicle then
      RestoreArchiveRotation()
      return
   end

   local speed = 0.0
   pcall(function() speed = tonumber(GET_ENTITY_SPEED(vehicle)) or 0.0 end)
   if speed >= 0.55 then
      RestoreArchiveRotation()
      return
   end

   if rotationState.active and rotationState.vehicle ~= vehicle then RestoreArchiveRotation() end
   if not rotationState.active then
      local heading = 0.0
      pcall(function() heading = tonumber(GET_ENTITY_HEADING(vehicle)) or 0.0 end)
      rotationState.active = true
      rotationState.vehicle = vehicle
      rotationState.originalHeading = heading
      rotationState.lastMs = now
      return
   end

   local dt = math.min(0.12, math.max(0.0, (now - (rotationState.lastMs or now)) / 1000.0))
   rotationState.lastMs = now
   local heading = 0.0
   pcall(function() heading = tonumber(GET_ENTITY_HEADING(vehicle)) or 0.0 end)
   local degreesPerSecond = math.max(1, FeatureMgr.GetFeatureInt(F.ArchiveRotateSpeed) or 18)
   pcall(SET_ENTITY_HEADING, vehicle, (heading + degreesPerSecond * dt) % 360.0)
end

local function UpdateArchiveAutoShowcase(now, tabActive)
   if not tabActive or not FeatureMgr.IsFeatureEnabled(F.ArchiveAutoShowcase) then
      archiveView.nextCycleMs = 0
      return
   end
   RefreshArchiveFilter(false)
   local total = #archiveView.filtered
   if total <= 0 then return end
   if archiveView.nextCycleMs == 0 then archiveView.nextCycleMs = now end
   if now < archiveView.nextCycleMs then return end

   archiveView.autoIndex = archiveView.autoIndex + 1
   if archiveView.autoIndex > total then archiveView.autoIndex = 1 end
   local item = archiveView.filtered[archiveView.autoIndex]
   if item then
      BeginArchivePreview(item)
      archiveView.selected = item
      archiveView.selectedIndex = archiveView.autoIndex
   end
   local seconds = math.max(1, FeatureMgr.GetFeatureInt(F.ArchiveShowcaseSeconds) or 5)
   archiveView.nextCycleMs = now + (seconds * 1000)
end

local function RgbToHsl(r, g, b)
   r, g, b = r / 255, g / 255, b / 255
   local max, min = math.max(r, g, b), math.min(r, g, b)
   local h, s, l = 0, 0, (max + min) / 2
   if max ~= min then
      local d = max - min
      s = l > 0.5 and d / (2 - max - min) or d / (max + min)
      if max == r then h = (g - b) / d + (g < b and 6 or 0)
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4 end
      h = h / 6
   end
   return h, s, l
end

local function HslToRgb(h, s, l)
   local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
   end
   local r, g, b
   if s == 0 then r, g, b = l, l, l
   else
      local q = l < 0.5 and l * (1 + s) or l + s - l * s
      local p = 2 * l - q
      r, g, b = hue2rgb(p, q, h + 1/3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1/3)
   end
   return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function RgbToHue(r,g,b)
   r,g,b = r/255,g/255,b/255
   local max,min = math.max(r,g,b),math.min(r,g,b)
   local d = max-min
   if d==0 then return 0 end
   if max==r then return (60*((g-b)/d))%360 end
   if max==g then return 60*((b-r)/d+2) end
   return 60*((r-g)/d+4)
end

local function HueToPearl(h)
   h = h % 360
   if h < 20 then return 28 elseif h < 45 then return 38
   elseif h < 75 then return 89 elseif h < 110 then return 92
   elseif h < 160 then return 139 elseif h < 210 then return 70
   elseif h < 270 then return 64 elseif h < 310 then return 145
   elseif h < 340 then return 148 else return 35 end
end

local function HueToHeadlight(h)
   h = h % 360
   if h < 15 or h > 345 then return 8 
   elseif h < 45 then return 7 
   elseif h < 65 then return 5 
   elseif h < 100 then return 4 
   elseif h < 150 then return 3 
   elseif h < 190 then return 2 
   elseif h < 245 then return 1 
   elseif h < 280 then return 11 
   elseif h < 310 then return 12 
   elseif h < 345 then return 10 
   else return 0 end
end

local function GetVehicleHandle()
   local ped = GTA.GetLocalPed()
   if not ped or not ped:IsInVehicle() then return nil end
   return GTA.PointerToHandle(ped.CurVehicle)
end

local function ProcessColorModifiers(r, g, b)
   local h, s, l = RgbToHsl(r, g, b)
   local hueShiftVal = FeatureMgr.GetFeatureInt(F.HueShift) / 360
   local satMult = FeatureMgr.GetFeatureInt(F.Saturation) / 100
   local brMult = FeatureMgr.GetFeatureInt(F.Brightness) / 100
   h = (h + hueShiftVal) % 1.0
   s = math.max(0, math.min(1.0, s * satMult))
   l = math.max(0, math.min(1.0, l * brMult))
   local fr, fg, fb = HslToRgb(h, s, l)

   -- contrast pivots each channel around middle gray. 0 = unchanged.
   local contrast = math.max(-100, math.min(100, FeatureMgr.GetFeatureInt(F.Contrast) or 0))
   local contrastFactor = 1.0 + (contrast / 100.0)
   local function ContrastChannel(v)
      return math.max(0, math.min(255, math.floor(128 + ((v - 128) * contrastFactor) + 0.5)))
   end
   fr, fg, fb = ContrastChannel(fr), ContrastChannel(fg), ContrastChannel(fb)

   -- temperature: negative cools toward blue; positive warms toward red/gold.
   local temperature = math.max(-100, math.min(100, FeatureMgr.GetFeatureInt(F.Temperature) or 0)) / 100.0
   fr = math.max(0, math.min(255, math.floor(fr + (temperature * 42) + 0.5)))
   fg = math.max(0, math.min(255, math.floor(fg + (temperature * 7) + 0.5)))
   fb = math.max(0, math.min(255, math.floor(fb - (temperature * 42) + 0.5)))

   if FeatureMgr.IsFeatureEnabled(F.InvertColors) then return 255-fr, 255-fg, 255-fb end
   return fr, fg, fb
end

local function ApplyPaint()
   local handle = GetVehicleHandle()
   if not handle then return end

   local matIdx = FeatureMgr.GetFeatureListIndex(F.Material)
   local mat = Materials[matIdx + 1]
   local pPearl = FeatureMgr.GetFeatureInt(F.PrimaryPearl)
   
   SET_VEHICLE_MOD_KIT(handle, 0)

   local baseColorId = type(mat.id) == "table" and mat.id[1] or mat.id

   if mat.name == "Chameleon" then
      local cIdx = FeatureMgr.GetFeatureListIndex(F.Chameleon)
      local cID = Chameleons[cIdx + 1].id
      SET_VEHICLE_COLOURS(handle, cID, cID)
      if FeatureMgr.IsFeatureEnabled(F.EnablePearl) then
         SET_VEHICLE_EXTRA_COLOURS(handle, pPearl, 0)
      else
         SET_VEHICLE_EXTRA_COLOURS(handle, 0, 0)
      end
      CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle)
      CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle)
   else
      local pr_raw, pg_raw, pb_raw = FeatureMgr.GetFeatureColor(F.PrimaryColor)
      local pr, pg, pb = ProcessColorModifiers(pr_raw, pg_raw, pb_raw)
      local dirtLevel = FeatureMgr.GetFeatureFloat(F.DirtLevel)

      local sr, sg, sb
      local nr, ng, nb
      local tr, tg, tb
      local xenonID

      if FeatureMgr.IsFeatureEnabled(F.SyncMode) then
         sr, sg, sb = pr, pg, pb
         nr, ng, nb = pr, pg, pb
         tr, tg, tb = pr, pg, pb
         xenonID = HueToHeadlight(RgbToHue(pr, pg, pb))
         
         FeatureMgr.SetFeatureColor(F.SecondaryColor, pr_raw, pg_raw, pb_raw, 255)
         FeatureMgr.SetFeatureColor(F.NeonColor, pr_raw, pg_raw, pb_raw, 255)
         FeatureMgr.SetFeatureColor(F.TyreSmokeColor, pr_raw, pg_raw, pb_raw, 255)
         FeatureMgr.SetFeatureListIndex(F.XenonColor, xenonID)
      else
         local sr_raw, sg_raw, sb_raw = FeatureMgr.GetFeatureColor(F.SecondaryColor)
         sr, sg, sb = ProcessColorModifiers(sr_raw, sg_raw, sb_raw)
         nr, ng, nb = FeatureMgr.GetFeatureColor(F.NeonColor)
         tr, tg, tb = FeatureMgr.GetFeatureColor(F.TyreSmokeColor)
         xenonID = FeatureMgr.GetFeatureListIndex(F.XenonColor)
      end

      SET_VEHICLE_COLOURS(handle, baseColorId, baseColorId)
      SET_VEHICLE_MOD_COLOR_1(handle, mat.type, baseColorId, pPearl)
      SET_VEHICLE_MOD_COLOR_2(handle, mat.type, baseColorId)
      
      if FeatureMgr.IsFeatureEnabled(F.EnablePearl) then
         SET_VEHICLE_EXTRA_COLOURS(handle, pPearl, 0)
      else
         SET_VEHICLE_EXTRA_COLOURS(handle, 0, 0)
      end
      
      SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle, math.floor(pr), math.floor(pg), math.floor(pb))
      SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle, math.floor(sr), math.floor(sg), math.floor(sb))

      TOGGLE_VEHICLE_MOD(handle, 22, true)
      _SET_VEHICLE_XENON_LIGHT_COLOR(handle, xenonID)

      TOGGLE_VEHICLE_MOD(handle, 20, true)
      SET_VEHICLE_TYRE_SMOKE_COLOR(handle, tr, tg, tb)
   end

   local neonEnabled = false
   local neonToggleFeature = FeatureMgr.GetFeature(F.EnableNeon)
   if neonToggleFeature then neonEnabled = FeatureMgr.IsFeatureEnabled(F.EnableNeon) == true end
   for i = 0, 3 do _SET_VEHICLE_NEON_LIGHT_ENABLED(handle, i, neonEnabled == true) end
   if neonEnabled then
      local nr2, ng2, nb2 = FeatureMgr.GetFeatureColor(F.NeonColor)
      if FeatureMgr.IsFeatureEnabled(F.SyncMode) and mat.name ~= "Chameleon" then
         nr2, ng2, nb2 = FeatureMgr.GetFeatureColor(F.PrimaryColor)
         nr2, ng2, nb2 = ProcessColorModifiers(nr2, ng2, nb2)
      end
      _SET_VEHICLE_NEON_LIGHTS_COLOUR(handle, nr2 or 255, ng2 or 255, nb2 or 255)
   end

   SET_VEHICLE_DIRT_LEVEL(handle, dirtLevel)
end

ApplyFullExoticPreset = function(item)
   if not item or item.is_exotic ~= true or type(item.exotic_preset) ~= "table" then return false end
   local p = item.exotic_preset

   local finishOverrideIndex = FeatureMgr.GetFeatureListIndex(F.ArchiveFinish) or 0
   if finishOverrideIndex > 0 then
      FeatureMgr.SetFeatureListIndex(F.Material, math.max(0, math.min(5, finishOverrideIndex - 1)))
   else
      FeatureMgr.SetFeatureListIndex(F.Material, LegacyMaterialIndexToCurrent(p.material))
   end
   UpdatePresetColorList()
   FeatureMgr.SetFeatureListIndex(F.Chameleon, math.max(0, math.min(#Chameleons - 1, math.floor(tonumber(p.chameleon) or 0))))

   local syncFeat = FeatureMgr.GetFeature(F.SyncMode)
   if syncFeat then syncFeat:SetBoolValue(p.sync_mode == true) end
   local linkFeat = FeatureMgr.GetFeature(F.LinkPearl)
   if linkFeat then linkFeat:SetBoolValue(false) end
   local enablePearlFeat = FeatureMgr.GetFeature(F.EnablePearl)
   if enablePearlFeat then enablePearlFeat:SetBoolValue(true) end

   local function SetPresetColor(featureId, color)
      if type(color) == "table" and #color >= 3 then
         FeatureMgr.SetFeatureColor(featureId, math.floor(tonumber(color[1]) or 255), math.floor(tonumber(color[2]) or 255), math.floor(tonumber(color[3]) or 255), math.floor(tonumber(color[4]) or 255))
      end
   end
   SetPresetColor(F.PrimaryColor, p.primary_color)
   SetPresetColor(F.SecondaryColor, p.secondary_color)
   SetPresetColor(F.NeonColor, p.neon_color)
   SetPresetColor(F.TyreSmokeColor, p.smoke_color)

   FeatureMgr.SetFeatureListIndex(F.XenonColor, math.max(0, math.min(#HeadlightColors - 1, math.floor(tonumber(p.headlight_color) or 0))))
   FeatureMgr.SetFeatureInt(F.PrimaryPearl, math.max(0, math.min(160, math.floor(tonumber(p.pearl_id) or 0))))
   FeatureMgr.SetFeatureInt(F.PearlAggression, math.max(0, math.min(100, math.floor(tonumber(p.pearl_aggression) or 20))))
   FeatureMgr.SetFeatureFloat(F.DirtLevel, tonumber(p.dirt_level) or 0.0)

   local modifiers = type(p.modifiers) == "table" and p.modifiers or {}
   FeatureMgr.SetFeatureInt(F.Brightness, math.max(0, math.min(100, math.floor(tonumber(modifiers.brightness) or 100))))
   FeatureMgr.SetFeatureInt(F.Saturation, math.max(0, math.min(100, math.floor(tonumber(modifiers.saturation) or 100))))
   FeatureMgr.SetFeatureInt(F.HueShift, math.max(0, math.min(360, math.floor(tonumber(modifiers.hue_shift) or 0))))
   FeatureMgr.SetFeatureInt(F.Contrast, math.max(-100, math.min(100, math.floor(tonumber(modifiers.contrast) or 0))))
   FeatureMgr.SetFeatureInt(F.Temperature, math.max(-100, math.min(100, math.floor(tonumber(modifiers.temperature) or 0))))
   local invertFeat = FeatureMgr.GetFeature(F.InvertColors)
   if invertFeat then invertFeat:SetBoolValue(modifiers.invert == true) end

   ApplyPaint()
   GUI.AddToast("PaintLabs", "Applied full Exotic preset: " .. tostring(item.name or "Exotic"), 2400)
   return true
end

local function AutoCalculatePearl()
   if FeatureMgr.IsFeatureEnabled(F.LinkPearl) then
      local r, g, b = FeatureMgr.GetFeatureColor(F.PrimaryColor)
      if r then
         local hue = RgbToHue(r, g, b)
         local aggression = FeatureMgr.GetFeatureInt(F.PearlAggression)
         local shift = (aggression / 100) * 160
         FeatureMgr.SetFeatureInt(F.PrimaryPearl, HueToPearl((hue + shift) % 360))
      end
   end
   ApplyPaint()
end

UpdatePresetColorList = function()
   local matIdx = FeatureMgr.GetFeatureListIndex(F.Material) or 0
   local mat = Materials[matIdx + 1] or Materials[1]

   local filteredNames = {}
   currentFilteredColors = {}

   if mat.name ~= "Chameleon" then
      for _, col in ipairs(presetColors) do
         if MaterialContainsColorId(mat, col.id) then
            table.insert(filteredNames, col.name)
            table.insert(currentFilteredColors, col)
         end
      end
   end

   if #filteredNames == 0 then table.insert(filteredNames, "No presets") end

   local feat = FeatureMgr.GetFeature(F.PresetColorCombo)
   if feat then
      feat:SetList(filteredNames)
      feat:SetListIndex(0)
   end
end

local function RandomizeMixer()
   FeatureMgr.SetFeatureInt(F.Brightness, math.random(25, 100))
   FeatureMgr.SetFeatureInt(F.Saturation, math.random(25, 100))
   FeatureMgr.SetFeatureInt(F.HueShift, math.random(0, 360))
   FeatureMgr.SetFeatureInt(F.Contrast, math.random(-45, 65))
   FeatureMgr.SetFeatureInt(F.Temperature, math.random(-40, 40))
   ApplyPaint()
end

local function ResetMixer()
   FeatureMgr.SetFeatureInt(F.Brightness, 100)
   FeatureMgr.SetFeatureInt(F.Saturation, 100)
   FeatureMgr.SetFeatureInt(F.HueShift, 0)
   FeatureMgr.SetFeatureInt(F.Contrast, 0)
   FeatureMgr.SetFeatureInt(F.Temperature, 0)
   local invertFeat = FeatureMgr.GetFeature(F.InvertColors)
   if invertFeat then invertFeat:SetBoolValue(false) end
   ApplyPaint()
end

local function RefreshPresetList()
   local files = FileMgr.FindFiles(presetPath, ".json", false)
   local newList = {}
   if files and #files > 0 then
      for _, f in ipairs(files) do
         newList[#newList+1] = f:match("([^\\/]+)%.json$") or f
      end
      presetFiles = newList
   else
      presetFiles = {"No Presets Found"}
   end
   
   local feat = FeatureMgr.GetFeature(F.PresetList)
   if feat then feat:SetList(presetFiles) end
end

local function SavePresetFile()
   local name = FeatureMgr.GetFeatureString(F.PresetName)
   if name == "" or name == nil then 
      GUI.AddToast("Error", "Please enter a valid name.", 3000) 
      return 
   end
   
   local currentMaterialIndex = FeatureMgr.GetFeatureListIndex(F.Material) or 0
   local currentMaterial = Materials[currentMaterialIndex + 1] or Materials[1]
   local data = {
      preset_schema = 3,
      material_schema = 2,
      material = currentMaterialIndex,
      material_name = tostring(currentMaterial.name or "Metallic"),
      chameleon = FeatureMgr.GetFeatureListIndex(F.Chameleon),
      preset_color_index = FeatureMgr.GetFeatureListIndex(F.PresetColorCombo),
      sync_mode = FeatureMgr.IsFeatureEnabled(F.SyncMode),
      pearl_enabled = FeatureMgr.IsFeatureEnabled(F.EnablePearl),
      link_pearl = FeatureMgr.IsFeatureEnabled(F.LinkPearl),
      neon_enabled = FeatureMgr.IsFeatureEnabled(F.EnableNeon),
      primary_color = { FeatureMgr.GetFeatureColor(F.PrimaryColor) },
      secondary_color = { FeatureMgr.GetFeatureColor(F.SecondaryColor) },
      neon_color = { FeatureMgr.GetFeatureColor(F.NeonColor) },
      smoke_color = { FeatureMgr.GetFeatureColor(F.TyreSmokeColor) },
      headlight_color = FeatureMgr.GetFeatureListIndex(F.XenonColor),
      gallery_match_smoke = FeatureMgr.IsFeatureEnabled(F.ArchiveMatchTyreSmoke),
      gallery_match_headlights = FeatureMgr.IsFeatureEnabled(F.ArchiveMatchHeadlights),
      gallery_match_neon = FeatureMgr.IsFeatureEnabled(F.ArchiveMatchNeon),
      gallery_finish = FeatureMgr.GetFeatureListIndex(F.ArchiveFinish),
      pearl_id = FeatureMgr.GetFeatureInt(F.PrimaryPearl),
      pearl_aggression = FeatureMgr.GetFeatureInt(F.PearlAggression),
      dirt_level = FeatureMgr.GetFeatureFloat(F.DirtLevel),
      modifiers = {
         brightness = FeatureMgr.GetFeatureInt(F.Brightness),
         saturation = FeatureMgr.GetFeatureInt(F.Saturation),
         hue_shift = FeatureMgr.GetFeatureInt(F.HueShift),
         contrast = FeatureMgr.GetFeatureInt(F.Contrast),
         temperature = FeatureMgr.GetFeatureInt(F.Temperature),
         invert = FeatureMgr.IsFeatureEnabled(F.InvertColors)
      }
   }
   
   FileMgr.WriteFileContent(presetPath .. name .. ".json", json.encode(data))
   GUI.AddToast("Success", "Preset '" .. name .. "' saved.", 3000)
   RefreshPresetList()
end

local function LoadPresetFile()
   local idx = FeatureMgr.GetFeatureListIndex(F.PresetList)
   local name = presetFiles[idx+1]
   
   if not name or name == "No Presets Found" then 
      GUI.AddToast("Error", "No valid preset selected.", 3000)
      return 
   end
   
   local content = FileMgr.ReadFileContent(presetPath .. name .. ".json")
   if not content or content == "" then return end
   
   local d = json.decode(content)
   if not d then return end

   local materialIndex
   if d.material_name and tostring(d.material_name) ~= "" then
      materialIndex = FindMaterialIndexByName(d.material_name)
   end
   if materialIndex == nil then
      if tonumber(d.material_schema) == 2 then
         materialIndex = math.max(0, math.min(#Materials - 1, math.floor(tonumber(d.material) or 0)))
      else
         materialIndex = LegacyMaterialIndexToCurrent(d.material)
      end
   end
   FeatureMgr.SetFeatureListIndex(F.Material, materialIndex or 0)
   UpdatePresetColorList()
   
   FeatureMgr.SetFeatureListIndex(F.Chameleon, math.floor(tonumber(d.chameleon) or 0))
   if d.preset_color_index ~= nil then
      pcall(function() FeatureMgr.SetFeatureListIndex(F.PresetColorCombo, math.floor(tonumber(d.preset_color_index) or 0)) end)
   end
   
   local syncFeat = FeatureMgr.GetFeature(F.SyncMode)
   if syncFeat then syncFeat:SetBoolValue(d.sync_mode == true) end
   local pearlFeat = FeatureMgr.GetFeature(F.EnablePearl)
   if pearlFeat then pearlFeat:SetBoolValue(d.pearl_enabled ~= false) end
   local linkFeat = FeatureMgr.GetFeature(F.LinkPearl)
   if linkFeat then linkFeat:SetBoolValue(d.link_pearl ~= false) end
   local neonFeat = FeatureMgr.GetFeature(F.EnableNeon)
   if neonFeat then neonFeat:SetBoolValue(d.neon_enabled == true) end
   
   local function SetCol(featId, colData)
      if colData and #colData >= 3 then
         FeatureMgr.SetFeatureColor(featId, math.floor(colData[1]), math.floor(colData[2]), math.floor(colData[3]), math.floor(colData[4] or 255))
      end
   end

   SetCol(F.PrimaryColor, d.primary_color)
   SetCol(F.SecondaryColor, d.secondary_color)
   SetCol(F.NeonColor, d.neon_color)
   SetCol(F.TyreSmokeColor, d.smoke_color)
   
   FeatureMgr.SetFeatureListIndex(F.XenonColor, math.floor(tonumber(d.headlight_color) or 0))
   if d.gallery_match_smoke ~= nil then FeatureMgr.GetFeature(F.ArchiveMatchTyreSmoke):SetBoolValue(d.gallery_match_smoke == true) end
   if d.gallery_match_headlights ~= nil then FeatureMgr.GetFeature(F.ArchiveMatchHeadlights):SetBoolValue(d.gallery_match_headlights == true) end
   if d.gallery_match_neon ~= nil then FeatureMgr.GetFeature(F.ArchiveMatchNeon):SetBoolValue(d.gallery_match_neon == true) end
   if d.gallery_finish ~= nil then FeatureMgr.SetFeatureListIndex(F.ArchiveFinish, math.max(0, math.floor(tonumber(d.gallery_finish) or 0))) end
   FeatureMgr.SetFeatureInt(F.PrimaryPearl, math.floor(tonumber(d.pearl_id) or 0))
   FeatureMgr.SetFeatureInt(F.PearlAggression, math.floor(tonumber(d.pearl_aggression) or 20))
   FeatureMgr.SetFeatureFloat(F.DirtLevel, tonumber(d.dirt_level) or 0.0)
   
   local loadedModifiers = type(d.modifiers) == "table" and d.modifiers or {}
   FeatureMgr.SetFeatureInt(F.Brightness, math.floor(tonumber(loadedModifiers.brightness) or 100))
   FeatureMgr.SetFeatureInt(F.Saturation, math.floor(tonumber(loadedModifiers.saturation) or 100))
   FeatureMgr.SetFeatureInt(F.HueShift, math.floor(tonumber(loadedModifiers.hue_shift) or 0))
   FeatureMgr.SetFeatureInt(F.Contrast, math.floor(tonumber(loadedModifiers.contrast) or 0))
   FeatureMgr.SetFeatureInt(F.Temperature, math.floor(tonumber(loadedModifiers.temperature) or 0))
   local invFeat = FeatureMgr.GetFeature(F.InvertColors)
   if invFeat then invFeat:SetBoolValue(loadedModifiers.invert == true) end
   
   GUI.AddToast("Loaded Paint: " .. name, 2000)
   ApplyPaint()
end

local function DeletePresetFile()
   local idx = FeatureMgr.GetFeatureListIndex(F.PresetList)
   local name = presetFiles[idx+1]
   if not name or name == "No Presets Found" then return end

   FileMgr.DeleteFile(presetPath .. name .. ".json")
   GUI.AddToast("Deleted: " .. name, 3000)
   RefreshPresetList()
end

FeatureMgr.AddFeature(F.Material, "Finish", eFeatureType.Combo, "Choose Metallic, Matte, Worn, Epsilon, Brushed, Chrome, or Chameleon.", function()
   UpdatePresetColorList()
   ApplyPaint()
end):SetList(materialNames)

FeatureMgr.AddFeature(F.PresetColorCombo, "Preset → Primary", eFeatureType.Combo, "Load a GTA preset into Primary, then edit it normally.", function()
   local idx = FeatureMgr.GetFeatureListIndex(F.PresetColorCombo)
   local colorData = currentFilteredColors[idx + 1]
   if colorData then
      FeatureMgr.SetFeatureColor(F.PrimaryColor, colorData.r, colorData.g, colorData.b, 255)
      if FeatureMgr.IsFeatureEnabled(F.SyncMode) then
         FeatureMgr.SetFeatureColor(F.SecondaryColor, colorData.r, colorData.g, colorData.b, 255)
         FeatureMgr.SetFeatureColor(F.NeonColor, colorData.r, colorData.g, colorData.b, 255)
         FeatureMgr.SetFeatureColor(F.TyreSmokeColor, colorData.r, colorData.g, colorData.b, 255)
      end
      ResetMixer()
      AutoCalculatePearl()
   end
end):SetList({"Select finish first"})

FeatureMgr.AddFeature(F.Chameleon, "Chameleon", eFeatureType.Combo, "Select iridescent shader effects.", ApplyPaint):SetList(chameleonNames)
FeatureMgr.AddFeature(F.SyncMode, "Sync", eFeatureType.Toggle, "Synchronizes everything to Primary.", ApplyPaint):SetBoolValue(false)
FeatureMgr.AddFeature(F.PrimaryColor, "Primary", eFeatureType.InputColor3, "Base RGB color.", AutoCalculatePearl):SetColor(255, 255, 255, 255)
FeatureMgr.AddFeature(F.SecondaryColor, "Secondary", eFeatureType.InputColor3, "Accent RGB color.", ApplyPaint):SetColor(255, 255, 255, 255)
FeatureMgr.AddFeature(F.NeonColor, "Neon Color", eFeatureType.InputColor3, "Underglow color used only when Enable Neon Underglow is ON.", ApplyPaint):SetColor(255, 255, 255, 255)
FeatureMgr.AddFeature(F.EnableNeon, "Neon", eFeatureType.Toggle, "Optional neon underglow. OFF by default; PaintLabs will not silently enable neon.", ApplyPaint):SetBoolValue(false)
FeatureMgr.AddFeature(F.TyreSmokeColor, "Smoke", eFeatureType.InputColor3, "Tire smoke.", ApplyPaint):SetColor(255, 255, 255, 255)
FeatureMgr.AddFeature(F.XenonColor, "Headlights", eFeatureType.Combo, "Headlight color.", ApplyPaint):SetList(HeadlightColors)
FeatureMgr.AddFeature(F.LinkPearl, "Auto Pearl", eFeatureType.Toggle, "Auto-calculate Pearl ID."):SetBoolValue(true)
FeatureMgr.AddFeature(F.PearlAggression, "Pearl Mix", eFeatureType.SliderInt, "Color blending intensity.", AutoCalculatePearl):SetLimitValues(0, 100):SetIntValue(20)
FeatureMgr.AddFeature(F.PrimaryPearl, "Pearl", eFeatureType.SliderInt, "Manual Pearl ID.", ApplyPaint):SetLimitValues(0, 160)
FeatureMgr.AddFeature(F.Brightness, "Brightness", eFeatureType.SliderInt, "Scale brightness.", ApplyPaint):SetLimitValues(0, 100):SetDefaultValue(100):SetIntValue(100)
FeatureMgr.AddFeature(F.Saturation, "Saturation", eFeatureType.SliderInt, "Scale saturation.", ApplyPaint):SetLimitValues(0, 100):SetDefaultValue(100):SetIntValue(100)
FeatureMgr.AddFeature(F.HueShift, "Hue", eFeatureType.SliderInt, "Rotate colors around the hue wheel.", ApplyPaint):SetLimitValues(0, 360)
FeatureMgr.AddFeature(F.Contrast, "Contrast", eFeatureType.SliderInt, "Lower for softer paint; raise for deeper shadows and brighter highlights.", ApplyPaint):SetLimitValues(-100, 100):SetIntValue(0)
FeatureMgr.AddFeature(F.Temperature, "Temperature", eFeatureType.SliderInt, "Cool the paint toward blue or warm it toward red/gold.", ApplyPaint):SetLimitValues(-100, 100):SetIntValue(0)
FeatureMgr.AddFeature(F.InvertColors, "Invert", eFeatureType.Toggle, "Negative effect.", ApplyPaint)
FeatureMgr.AddFeature(F.RandomMixer, "Randomize", eFeatureType.Button, "Randomize brightness, saturation, hue, contrast, and temperature.", RandomizeMixer)
FeatureMgr.AddFeature(F.ResetMixer, "Reset", eFeatureType.Button, "Restore all mixer modifiers to neutral values.", ResetMixer)
FeatureMgr.AddFeature(F.EnablePearl, "Pearl On", eFeatureType.Toggle, "Enable Pearl Effect.", ApplyPaint):SetBoolValue(true)
FeatureMgr.AddFeature(F.DirtLevel, "Dirt", eFeatureType.SliderFloat, "Set dirt level.", ApplyPaint):SetLimitValues(0.0, 15.0)

FeatureMgr.AddFeature(F.RandomNormal, "Variant", eFeatureType.Button, "Create a variation of the current Primary color.", function()
   if (FeatureMgr.GetFeatureListIndex(F.Material) or 0) == 6 then
      FeatureMgr.SetFeatureListIndex(F.Material, 0)
      UpdatePresetColorList()
   end
   local r, g, b = FeatureMgr.GetFeatureColor(F.PrimaryColor)
   r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255
   local h, s, l = RgbToHsl(r, g, b)
   h = (h + (math.random(-24, 24) / 360.0)) % 1.0
   s = math.max(0, math.min(1, s * (math.random(78, 122) / 100.0)))
   l = math.max(0.03, math.min(0.97, l * (math.random(82, 118) / 100.0)))
   local vr, vg, vb = HslToRgb(h, s, l)
   FeatureMgr.SetFeatureColor(F.PrimaryColor, vr, vg, vb, 255)
   if FeatureMgr.IsFeatureEnabled(F.SyncMode) then
      FeatureMgr.SetFeatureColor(F.SecondaryColor, vr, vg, vb, 255)
      FeatureMgr.SetFeatureColor(F.NeonColor, vr, vg, vb, 255)
      FeatureMgr.SetFeatureColor(F.TyreSmokeColor, vr, vg, vb, 255)
   end
   AutoCalculatePearl()
end)

FeatureMgr.AddFeature(F.RandomChameleon, "Chameleon", eFeatureType.Button, "Randomized chameleon.", function()
   FeatureMgr.SetFeatureListIndex(F.Material, 6)
   UpdatePresetColorList()
   FeatureMgr.SetFeatureListIndex(F.Chameleon, math.random(0, 31))
   ApplyPaint()
end)

FeatureMgr.AddFeature(F.CustomChameleon, "Wild", eFeatureType.Button, "Random paint mode plus mixer variation.", function()
   if math.random(1, 100) <= 25 then
      FeatureMgr.TriggerFeatureCallback(F.RandomChameleon)
   else
      FeatureMgr.TriggerFeatureCallback(F.RandomNormal)
      RandomizeMixer()
      local pearlFeat = FeatureMgr.GetFeature(F.EnablePearl)
      if pearlFeat then pearlFeat:SetBoolValue(true) end
      local linkFeat = FeatureMgr.GetFeature(F.LinkPearl)
      if linkFeat then linkFeat:SetBoolValue(false) end
      FeatureMgr.SetFeatureInt(F.PrimaryPearl, math.random(0, 160))
      ApplyPaint()
   end
end)


FeatureMgr.AddFeature(F.ArchiveColorFamily, "Color Family", eFeatureType.Combo, "Internal family selector used by the gallery buttons.", function() archiveView.signature = "" end):SetList(archiveColorFamilies)
FeatureMgr.AddFeature(F.ArchiveBrightnessOrder, "Sort", eFeatureType.Combo, "Sort by brightness, spectrum, saturation, dark/light range, or name.", function() archiveView.signature = "" end):SetList(archiveBrightnessOrders)
FeatureMgr.AddFeature(F.ArchiveSearch, "Search", eFeatureType.InputText, "Search paint names, hex codes, pearlescents, or color families.", function() archiveView.signature = "" end):SetStringValue("")
FeatureMgr.AddFeature(F.ArchiveReadyOnly, "Pearl Only", eFeatureType.Toggle, "Show only paints with a confirmed GTA V pearlescent color and ID, including built-in Exotic presets.", function() archiveView.signature = "" end):SetBoolValue(true)
FeatureMgr.AddFeature(F.ArchiveFinish, "Gallery Finish", eFeatureType.Combo, "Override the gallery paint surface while preserving the selected RGB and pearl. Original / Preset keeps existing behavior.", function()
   archiveView.lastHoveredKey = ""
   if previewState.active and previewState.selected then BeginArchivePreview(previewState.selected) end
end):SetList(archiveFinishNames)
FeatureMgr.SetFeatureListIndex(F.ArchiveFinish, 0)
FeatureMgr.AddFeature(F.ArchiveHoverPreview, "Hover Preview", eFeatureType.Toggle, "Enabled by default: hover a color tile for 0.14 seconds to temporarily preview it.", function() end):SetBoolValue(true)
FeatureMgr.AddFeature(F.ArchiveMatchTyreSmoke, "Match Smoke", eFeatureType.Toggle, "When enabled, gallery previews and committed paints also set tire smoke to the paint RGB.", SyncArchiveTyreSmokeToggle):SetBoolValue(false)
FeatureMgr.AddFeature(F.ArchiveMatchHeadlights, "Match Headlights", eFeatureType.Toggle, "Match xenon headlight color to the gallery paint.", SyncArchiveHeadlightsToggle):SetBoolValue(false)
FeatureMgr.AddFeature(F.ArchiveMatchNeon, "Match Neon", eFeatureType.Toggle, "Match and enable neon underglow for gallery previews and applied paints.", SyncArchiveNeonToggle):SetBoolValue(false)
FeatureMgr.AddFeature(F.ArchiveAutoShowcase, "Showcase", eFeatureType.Toggle, "Cycle through every currently filtered paint automatically.", function() archiveView.nextCycleMs = 0 end):SetBoolValue(false)
FeatureMgr.AddFeature(F.ArchiveShowcaseSeconds, "Seconds", eFeatureType.SliderInt, "How long Auto Showcase displays each paint.", function() archiveView.nextCycleMs = 0 end):SetLimitValues(1, 20):SetIntValue(5)
FeatureMgr.AddFeature(F.ArchiveRotateVehicle, "Rotate", eFeatureType.Toggle, "Slowly rotate the parked vehicle while browsing; restores its starting direction.", function() end):SetBoolValue(false)
FeatureMgr.AddFeature(F.ArchiveRotateSpeed, "Rotate Speed", eFeatureType.SliderInt, "Degrees per second while Auto-Rotate is enabled.", function() end):SetLimitValues(3, 60):SetIntValue(18)

FeatureMgr.AddFeature(F.PresetList, "Presets", eFeatureType.Combo, "Select a preset.", nil):SetList(presetFiles)
FeatureMgr.AddFeature(F.PresetName, "Name", eFeatureType.InputText, "Name to save.")
FeatureMgr.AddFeature(F.SaveButton, "Save", eFeatureType.Button, "Save current settings.", SavePresetFile)
FeatureMgr.AddFeature(F.LoadButton, "Load", eFeatureType.Button, "Apply selected preset.", LoadPresetFile)
FeatureMgr.AddFeature(F.DeleteButton, "Delete", eFeatureType.Button, "Delete selected file.", DeletePresetFile)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- clickgui helpers
-- note: follows the compact hustlemeter release style without overriding cherax themes.
-- ═══════════════════════════════════════════════════════════════════════════════════

local function UiText(text)
   if ImGui and ImGui.Text then ImGui.Text(tostring(text or "")) end
end

local function UiTextWrapped(text)
   if ImGui and ImGui.TextWrapped then ImGui.TextWrapped(tostring(text or ""))
   elseif ImGui and ImGui.Text then ImGui.Text(tostring(text or "")) end
end

local function UiTextColored(r, g, b, text)
   if ImGui and ImGui.TextColored then ImGui.TextColored(r, g, b, 1.0, tostring(text or ""))
   else UiText(text) end
end

local function UiSubtle(text)
   UiTextColored(0.72, 0.72, 0.76, text)
end

local function UiSection(text, r, g, b)
   UiTextColored(r or 0.35, g or 1.00, b or 0.45, string.upper(tostring(text or "")))
end

local function UiSeparator()
   if ImGui and ImGui.Separator then ImGui.Separator() end
end

local function UiSpacing()
   if ImGui and ImGui.Spacing then ImGui.Spacing() end
end

local function PushPaintLabsTabStyle()
   if not ImGui or not ImGui.PushStyleColor or not ImGuiCol then return 0 end
   local pushed = 0
   local function push(key, r, g, b, a)
      if key ~= nil then
         ImGui.PushStyleColor(key, r, g, b, a)
         pushed = pushed + 1
      end
   end
   push(ImGuiCol.Tab, 0.20, 0.10, 0.29, 0.96)
   push(ImGuiCol.TabHovered, 0.34, 0.16, 0.48, 1.00)
   push(ImGuiCol.TabActive, 0.10, 0.38, 0.20, 1.00)
   push(ImGuiCol.Header, 0.10, 0.28, 0.18, 0.92)
   push(ImGuiCol.HeaderHovered, 0.18, 0.42, 0.26, 1.00)
   push(ImGuiCol.HeaderActive, 0.28, 0.18, 0.46, 1.00)
   return pushed
end

local function PopPaintLabsTabStyle(count)
   count = tonumber(count or 0) or 0
   if count > 0 and ImGui and ImGui.PopStyleColor then ImGui.PopStyleColor(count) end
end

local PaintLabsButtonColors = {
   Blue = {
      normal = {0.016, 0.157, 0.36, 1.0}, hover = {0.06, 0.22, 0.46, 1.0}, active = {0.01, 0.10, 0.26, 1.0}
   },
   Green = {
      normal = {0.016, 0.36, 0.157, 1.0}, hover = {0.06, 0.46, 0.22, 1.0}, active = {0.01, 0.26, 0.10, 1.0}
   },
   Purple = {
      normal = {0.30, 0.15, 0.45, 1.0}, hover = {0.40, 0.20, 0.55, 1.0}, active = {0.25, 0.10, 0.35, 1.0}
   },
   Gold = {
      normal = {0.48, 0.32, 0.05, 1.0}, hover = {0.62, 0.43, 0.08, 1.0}, active = {0.38, 0.24, 0.03, 1.0}
   },
   Red = {
      normal = {0.46, 0.045, 0.055, 1.0}, hover = {0.62, 0.075, 0.085, 1.0}, active = {0.34, 0.025, 0.035, 1.0}
   }
}

local function UiColorButton(label, scheme, callback, width, height)
   if not ImGui or not ImGui.Button then return false end
   local colors = PaintLabsButtonColors[scheme or "Purple"] or PaintLabsButtonColors.Purple
   local pushed = 0
   if ImGui.PushStyleColor and ImGuiCol then
      local function push(key, color)
         if key ~= nil then
            ImGui.PushStyleColor(key, color[1], color[2], color[3], color[4])
            pushed = pushed + 1
         end
      end
      push(ImGuiCol.Button, colors.normal)
      push(ImGuiCol.ButtonHovered, colors.hover)
      push(ImGuiCol.ButtonActive, colors.active)
   end
   local clicked = ImGui.Button(tostring(label or "Button"), width or 0, height or 0) == true
   if pushed > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(pushed) end
   if clicked and callback then callback() end
   return clicked
end

local function RenderBrandAsset(asset, width, height, id)
   width = tonumber(width) or 128
   height = tonumber(height) or width
   local srv = ensure_brand_asset(asset) or load_brand_asset(asset)
   if not srv or not ImGui then return false end
   local x, y = GetImGuiCursorPosition()
   if x <= 0 or y <= 0 then return false end

   if ImGui.Dummy then ImGui.Dummy(width, height)
   elseif ImGui.Button then ImGui.Button("##BrandAsset_" .. tostring(id or asset.key or "Logo"), width, height) end

   if ImGui.AddImageRounded then
      ImGui.AddImageRounded(srv, x, y, x + width, y + height, 0.0, 0.0, 1.0, 1.0, 0xFFFFFFFF, 8.0)
      return true
   elseif ImGui.AddImage then
      ImGui.AddImage(srv, x, y, x + width, y + height)
      return true
   end
   return false
end

local function UiGetCursorPosX()
   if ImGui and ImGui.GetCursorPosX then
      local ok, value = pcall(ImGui.GetCursorPosX)
      if ok and type(value) == "number" then return value end
   end
   return 0
end

local function UiGetCursorPosY()
   if ImGui and ImGui.GetCursorPosY then
      local ok, value = pcall(ImGui.GetCursorPosY)
      if ok and type(value) == "number" then return value end
   end
   return 0
end

local function RenderBrandAssetTopRight(asset, width, height, anchorY, minimumWidth)
   if not ImGui or not ImGui.SetCursorPosX or not ImGui.SetCursorPosY then return false end
   local contentWidth = select(1, GetImGuiContentRegionSize())
   minimumWidth = tonumber(minimumWidth) or (width + 300)
   if contentWidth < minimumWidth then return false end

   local savedX, savedY = UiGetCursorPosX(), UiGetCursorPosY()
   local targetX = savedX + math.max(220, contentWidth - width - 24)
   ImGui.SetCursorPosX(targetX)
   ImGui.SetCursorPosY((tonumber(anchorY) or savedY) + 4)
   local drawn = RenderBrandAsset(asset, width, height, "TopRight")
   ImGui.SetCursorPosX(savedX)
   ImGui.SetCursorPosY(savedY)
   return drawn
end

local function CopyDiscordLink()
   local copied = false
   if Utils and Utils.SetClipBoardText then
      pcall(function() Utils.SetClipBoardText(DISCORD_LINK, "") end)
      copied = true
   elseif Utils and Utils.SetClipboardText then
      pcall(function() Utils.SetClipboardText(DISCORD_LINK) end)
      copied = true
   elseif ImGui and ImGui.SetClipboardText then
      pcall(function() ImGui.SetClipboardText(DISCORD_LINK) end)
      copied = true
   end
   return copied
end

local function OpenDiscordLink()
   local opened = false
   if Utils and Utils.OpenURL then
      local ok, result = pcall(function() return Utils.OpenURL(DISCORD_LINK) end)
      opened = ok and result ~= false
   elseif Utils and Utils.OpenUrl then
      local ok, result = pcall(function() return Utils.OpenUrl(DISCORD_LINK) end)
      opened = ok and result ~= false
   elseif GUI and GUI.OpenURL then
      local ok, result = pcall(function() return GUI.OpenURL(DISCORD_LINK) end)
      opened = ok and result ~= false
   end
   return opened
end

local function OpenAndCopyDiscord()
   local copied = CopyDiscordLink()
   local opened = OpenDiscordLink()
   if GUI and GUI.AddToast then
      local message = opened and copied and "Discord opened and invite copied."
         or copied and "Discord invite copied."
         or opened and "Discord opened."
         or "Could not open or copy the Discord invite."
      pcall(function() GUI.AddToast("", message, 3500, eToastPos and eToastPos.TOP_RIGHT or nil) end)
   end
end

local function RenderSavedPresetManager(windowId, compact)
   windowId = tostring(windowId or "Saved Paint Presets")
   if ClickGUI.BeginCustomChildWindow(windowId, -1) then
      UiSection("Presets", 0.42, 0.82, 1.00)
      UiSeparator()
      FeatureMgr.GetFeature(F.PresetList):Render()
      if ImGui.Button("Load##" .. windowId) then LoadPresetFile() end
      ImGui.SameLine()
      if ImGui.Button("Delete##" .. windowId) then DeletePresetFile() end
      UiSpacing()
      FeatureMgr.GetFeature(F.PresetName):Render()
      FeatureMgr.GetFeature(F.SaveButton):Render()
      ClickGUI.EndCustomChildWindow()
   end
end


local function RenderGalleryFullWidth(windowId, subtitle)
   previewState.lastTabRenderMs = NowMs()
   if ClickGUI.BeginCustomChildWindow(tostring(windowId or "PaintLabs Gallery"), -1) then
      UiSection("Preset Gallery", 0.72, 0.42, 1.00)
      UiSeparator()
      RenderArchiveBrowser()
      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderColorsContent(compact)
   local isCham = (FeatureMgr.GetFeatureListIndex(F.Material) == 6)
   local isSync = FeatureMgr.IsFeatureEnabled(F.SyncMode)
   FeatureMgr.GetFeature(F.Material):Render()
   if isCham then
      FeatureMgr.GetFeature(F.Chameleon):Render()
   else
      FeatureMgr.GetFeature(F.PresetColorCombo):Render()
      FeatureMgr.GetFeature(F.SyncMode):Render()
      FeatureMgr.GetFeature(F.PrimaryColor):Render()
      FeatureMgr.GetFeature(F.EnableNeon):Render()
      if not isSync then
         FeatureMgr.GetFeature(F.SecondaryColor):Render()
         if FeatureMgr.IsFeatureEnabled(F.EnableNeon) then FeatureMgr.GetFeature(F.NeonColor):Render() end
         FeatureMgr.GetFeature(F.XenonColor):Render()
         FeatureMgr.GetFeature(F.TyreSmokeColor):Render()
      end
      FeatureMgr.GetFeature(F.DirtLevel):Render()
   end
end

local function RenderPearlescentContent(compact)
   FeatureMgr.GetFeature(F.EnablePearl):Render()
   FeatureMgr.GetFeature(F.LinkPearl):Render()
   FeatureMgr.GetFeature(F.PearlAggression):Render()
   FeatureMgr.GetFeature(F.PrimaryPearl):Render()
end

local function RenderMixerContent(compact)
   local isCham = (FeatureMgr.GetFeatureListIndex(F.Material) == 6)
   if isCham then
      UiText("Chameleon active")
      return
   end
   FeatureMgr.GetFeature(F.Brightness):Render()
   FeatureMgr.GetFeature(F.Saturation):Render()
   FeatureMgr.GetFeature(F.HueShift):Render()
   FeatureMgr.GetFeature(F.Contrast):Render()
   FeatureMgr.GetFeature(F.Temperature):Render()
   FeatureMgr.GetFeature(F.InvertColors):Render()
   FeatureMgr.GetFeature(F.RandomMixer):Render()
   FeatureMgr.GetFeature(F.ResetMixer):Render()
end







local function RenderRandomizerActionStrip(windowId)
   UiSection("Randomizer", 1.00, 0.78, 0.25)
   UiSeparator()
   if ImGui.BeginTable(tostring(windowId or "RandomizerActions") .. "_Buttons", 3, ImGuiTableFlags.SizingStretchSame) then
      ImGui.TableNextRow()
      ImGui.TableSetColumnIndex(0); FeatureMgr.GetFeature(F.RandomNormal):Render()
      ImGui.TableSetColumnIndex(1); FeatureMgr.GetFeature(F.RandomChameleon):Render()
      ImGui.TableSetColumnIndex(2); FeatureMgr.GetFeature(F.CustomChameleon):Render()
      ImGui.EndTable()
   end
end

local function RenderFlatEditorModule(title, colorR, colorG, colorB, renderFn, compact)
   UiSection(title, colorR, colorG, colorB)
   UiSeparator()
   renderFn(compact)
end






local function RenderEditorThreeLane()
   -- note: flat columns avoid nested child-window render instability.
   if ImGui.BeginTable("PaintLabsThreeLaneEditors", 3, ImGuiTableFlags.SizingStretchSame) then
      ImGui.TableNextRow()
      ImGui.TableSetColumnIndex(0); RenderFlatEditorModule("Primary", 0.35, 1.00, 0.45, RenderColorsContent, true)
      ImGui.TableSetColumnIndex(1); RenderFlatEditorModule("Pearlescent", 0.72, 0.42, 1.00, RenderPearlescentContent, true)
      ImGui.TableSetColumnIndex(2); RenderFlatEditorModule("Mixer", 0.42, 0.82, 1.00, RenderMixerContent, true)
      ImGui.EndTable()
   end
   UiSpacing()
   RenderRandomizerActionStrip("Three Lane Randomizer")
end


local function RenderPaintLabsMain()
   local brandAnchorY = UiGetCursorPosY()
   RenderBrandAssetTopRight(brandAssets.PaintLabs, 160, 108, brandAnchorY, 560)
   UiTextColored(0.35, 1.00, 0.45, "PAINTLABS")
   UiTextColored(0.72, 0.42, 1.00, string.format("%d paints • %d pearls", ARCHIVE_TOTAL_COUNT, ARCHIVE_IN_GAME_PEARL_COUNT))
   UiSpacing()

   local ped = GTA.GetLocalPed()
   if not ped or not ped:IsInVehicle() then
      UiTextColored(1.00, 0.25, 0.25, "NO VEHICLE")
      return
   end

   UiSpacing()
   RenderEditorThreeLane()
   UiSpacing()
   RenderGalleryFullWidth("PaintLabs Gallery", "")
   UiSpacing()
   RenderSavedPresetManager("Saved Paint Presets", true)
end

local function RenderGuideQuickStart()
   if ClickGUI.BeginCustomChildWindow("Quick Start", -1) then
      UiSection("Quick Start", 0.42, 0.82, 1.00)
      UiSubtle("Three Lane is the default editor")
      UiSeparator()
      local steps = {
         "Enter the vehicle you want to repaint.",
         "Choose a base material and adjust Primary / Secondary colors.",
         "Browse PaintLabs Gallery, then save favorites or settings underneath.",
         "Hover a gallery entry for a temporary preview, or click it to keep it.",
         "Match Smoke, Headlights, or Neon when you want the accessories to follow the paint."
      }
      for i, step in ipairs(steps) do
         UiTextColored(0.42, 0.82, 1.00, tostring(i) .. ".")
         ImGui.SameLine()
         UiTextWrapped(step)
         if i < #steps then UiSpacing() end
      end
      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderGuidePreviewSafety()
   if ClickGUI.BeginCustomChildWindow("Soft Preview Safety", -1) then
      UiSection("Soft Preview Safety", 0.35, 1.00, 0.45)
      UiSeparator()
      UiTextWrapped("The first soft preview captures the vehicle's original base colors, custom RGB flags, pearlescent, wheel color, tire-smoke RGB, and tire-smoke enabled state.")
      UiSpacing()
      UiTextWrapped("Hovering another color updates only the temporary preview. It does not replace the original restoration snapshot.")
      UiSpacing()
      UiTextWrapped("Collapsing Presets, opening Guide or Credits, changing vehicles, pressing Revert Preview, or unloading PaintLabs restores the original paint.")
      UiSpacing()
      UiTextColored(1.00, 0.78, 0.25, "Apply & Keep or clicking a paint commits the preview permanently.")
      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderGuideGallery()
   if ClickGUI.BeginCustomChildWindow("Paint Gallery", -1) then
      UiSection("Paint Gallery", 0.72, 0.42, 1.00)
      UiSubtle(string.format("%d total colors • %d confirmed GTA pearlescent combinations", ARCHIVE_TOTAL_COUNT, ARCHIVE_IN_GAME_PEARL_COUNT))
      UiSeparator()
      UiTextColored(1.00, 0.55, 0.85, "All + Color Families")
      UiTextWrapped("All appears first and shows every matching color in one scrollable grid. Favorites, Exotic, Ai, Remix, and each Pink, Red, Orange, Yellow, Green, Cyan, Blue, Purple, Brown, White, Gray, and Black family are available as buttons. Exotic includes the 38 curated pearlescent favorites plus 7 built-in presets; Ai adds 500 intentionally clashing confirmed in-game pearl combinations.")
      UiTextColored(1.00, 0.78, 0.25, "Sort")
      UiTextWrapped("Choose brightness, grouped hue, Red → Violet / Violet → Red spectrum, saturation, Darks Only, Lights Only, Midtones Only, or A-Z/Z-A. Dark/Light/Midtone modes also filter the grid.")
      UiTextWrapped("Remix: select any paint and press Remix This Color for 50 close color relatives, or Remix This Pearlescent to keep the exact base color and preview 50 in-game pearlescent options. The next Remix replaces the batch, while favorited Remix results stay available in Favorites.")
      UiTextWrapped("Preset Finish: use Original / Preset for the normal look, or override any gallery color with Metallic, Matte, Worn, Epsilon, Brushed, or Chrome while preserving its RGB and pearlescent selection.")
      UiTextWrapped("Community colors preserve confirmed paint data without guessing missing pearl IDs. Color-only entries keep the current pearl, while documented specialty finishes are used when Preset Finish is Original / Preset.")
      UiSpacing()
      UiTextColored(0.35, 0.90, 1.00, "In-Game Pearlescent Only")
      UiTextWrapped("ON shows combinations with a confirmed GTA pearlescent name and ID. OFF shows every extracted RGB color and preserves the vehicle's existing pearl when one is unresolved.")
      UiSpacing()
      UiTextColored(0.35, 1.00, 0.45, "Showing X of 661")
      UiTextWrapped("The live count updates with All/Family, Favorites, Search, brightness ordering, and the pearlescent filter.")
      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderGuideShowcase()
   if ClickGUI.BeginCustomChildWindow("Auto Showcase", -1) then
      UiSection("Auto Showcase", 1.00, 0.78, 0.25)
      UiSeparator()
      UiTextWrapped("Auto Showcase cycles through the currently filtered paints. Seconds Per Paint controls how long each color remains visible.")
      UiSpacing()
      UiTextWrapped("Use the Favorite Paint button while the slideshow is running to save a color immediately. Favorites persist in PaintLabs\\favorites.txt.")
      UiSpacing()
      UiTextWrapped("Match Smoke, Match Headlights, and Match Neon can follow the gallery RGB. Preview restoration restores the original accessory states.")
      UiSpacing()
      UiTextWrapped("Auto-Rotate Vehicle slowly turns a parked vehicle so the finish can be viewed from every angle. The starting heading is restored when rotation stops or Presets is left.")
      UiSpacing()
      UiTextColored(1.00, 0.45, 0.32, "Rotation pauses when the vehicle starts moving.")
      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderPaintLabsGuide()
   UiTextColored(0.35, 1.00, 0.45, "PAINTLABS GUIDE")
   UiTextColored(0.42, 0.82, 1.00, "Choose a section and follow the compact instructions.")
   UiSpacing()
   if ImGui.BeginTable("PaintLabsGuideTable", 2, ImGuiTableFlags.SizingStretchSame) then
      ImGui.TableNextRow()
      ImGui.TableSetColumnIndex(0)
      RenderGuideQuickStart()
      RenderGuidePreviewSafety()
      ImGui.TableSetColumnIndex(1)
      RenderGuideGallery()
      RenderGuideShowcase()
      ImGui.EndTable()
   else
      RenderGuideQuickStart()
      RenderGuidePreviewSafety()
      RenderGuideGallery()
      RenderGuideShowcase()
   end
end

local function CreditPlatformCount(platform)
   local count = 0
   for _, credit in ipairs(COLOR_CREDIT_RECORDS) do
      if tostring(credit.platform) == tostring(platform) then count = count + 1 end
   end
   return count
end

local function RenderColorCreditEntry(credit)
   local r = (tonumber(credit.r) or 160) / 255.0
   local g = (tonumber(credit.g) or 160) / 255.0
   local b = (tonumber(credit.b) or 168) / 255.0
   ImGui.TextColored(r, g, b, 1.00, "●")
   local hovered = ImGui.IsItemHovered()
   ImGui.SameLine()
   ImGui.Text(tostring(credit.name or "Unknown"))
   hovered = hovered or ImGui.IsItemHovered()
   if hovered then
      ImGui.BeginTooltip()
      ImGui.TextColored(1.00, 0.55, 0.85, 1.00, tostring(credit.platform or "Source") .. " • " .. tostring(credit.name or "Unknown"))
      if credit.linked == true then
         ImGui.Text("Representative: " .. tostring(credit.color_name or "Color"))
         ImGui.Text("Hex: " .. tostring(credit.hex or ""))
         if credit.pearl and credit.pearl ~= "" then ImGui.Text("Pearl: " .. tostring(credit.pearl)) end
         if tonumber(credit.color_count or 0) > 1 then ImGui.Text("Linked paints: " .. tostring(credit.color_count)) end
         if type(credit.colors) == "table" and #credit.colors > 0 then
            ImGui.Separator()
            for i, color in ipairs(credit.colors) do
               if i > 6 then break end
               ImGui.Text("• " .. tostring(color))
            end
         end
      else
         ImGui.Text("Attribution verified from the original color source.")
         ImGui.Text("No single paint could be linked confidently.")
      end
      ImGui.EndTooltip()
   end
end

local function RenderCreditPlatform(platform)
   local filtered = {}
   for _, credit in ipairs(COLOR_CREDIT_RECORDS) do
      if tostring(credit.platform) == tostring(platform) then filtered[#filtered + 1] = credit end
   end
   local columns = 2
   if ImGui.BeginTable("PaintLabsCreditTable##" .. tostring(platform), columns, ImGuiTableFlags.SizingStretchSame) then
      for i, credit in ipairs(filtered) do
         if ((i - 1) % columns) == 0 then ImGui.TableNextRow() end
         ImGui.TableSetColumnIndex((i - 1) % columns)
         RenderColorCreditEntry(credit)
      end
      ImGui.EndTable()
   else
      for _, credit in ipairs(filtered) do RenderColorCreditEntry(credit) end
   end
end

local function RenderColorCredits()
   local open = true
   if ImGui and ImGui.CollapsingHeader then
      open = ImGui.CollapsingHeader("Color Credits##PaintLabsCredits") == true
   end
   if not open then return end

   local youtubeOpen = true
   if ImGui and ImGui.CollapsingHeader then youtubeOpen = ImGui.CollapsingHeader("YouTube (" .. tostring(CreditPlatformCount("YouTube")) .. ")##PaintLabsYouTubeCredits") == true end
   if youtubeOpen then RenderCreditPlatform("YouTube") end
   UiSpacing()
   local forumOpen = true
   if ImGui and ImGui.CollapsingHeader then forumOpen = ImGui.CollapsingHeader("GTAForums (" .. tostring(CreditPlatformCount("GTAForums")) .. ")##PaintLabsForumCredits") == true end
   if forumOpen then RenderCreditPlatform("GTAForums") end
   UiSpacing()
   UiSubtle("● = representative linked paint. Hover a name for color, hex, pearl, and linked-paint details.")
end

local function RenderCreditsProjects()
   local projects = {
      {"Startup", "Session startup, themes, Lua automation, HUD tools, and protections.", 0.35, 1.00, 0.45},
      {"HustleMeter", "Rolling GTA Online money tracking with transition-safe diagnostics.", 0.42, 0.82, 1.00},
      {"DriftGod", "Arcade drifting, progression, presets, garage tools, and Power Glider.", 1.00, 0.35, 0.45},
      {"Vehicle Paint Presets", "Save and restore complete vehicle showcase combinations.", 1.00, 0.55, 0.85},
      {"Track Generator", "Build, save, and load custom stunt tracks.", 0.42, 0.82, 1.00},
      {"Minigames", "Custom GTA Online multiplayer activities and WarGames.", 0.72, 0.42, 1.00}
   }
   if ImGui.BeginTable("PaintLabsCommunityProjects", 2, ImGuiTableFlags.SizingStretchSame) then
      for i, item in ipairs(projects) do
         local column = (i - 1) % 2
         if column == 0 then ImGui.TableNextRow() end
         ImGui.TableSetColumnIndex(column)
         UiTextColored(item[3], item[4], item[5], "• " .. item[1])
         UiTextWrapped(item[2])
         UiSpacing()
      end
      ImGui.EndTable()
   else
      for _, item in ipairs(projects) do
         UiTextColored(item[3], item[4], item[5], "• " .. item[1])
         UiTextWrapped(item[2])
      end
   end
end



local publicChangelog = {
   {"v0.0.1", "Initial paint editor, GTA presets, finishes, pearl controls, mixer, randomizer, and saved presets."},
   {"v0.1.0", "Embedded gallery, family browsing, hover preview, Favorites, Auto Showcase, and brightness sorting."},
   {"v0.2.0", "Confirmed pearl filtering, polished tabs, safer restoration, and preset-focused gallery controls."},
   {"v0.3.0", "Grid gallery, Vec2-safe rendering, Match Smoke, curated defaults, and first Exotic presets."},
   {"v0.4.0", "Dedicated Exotic gallery, persistent Favorites, full specialty presets, and improved navigation."},
   {"v0.5.0", "Ai recommendations expanded into 100 deliberately contrasting pearl combinations."},
   {"v0.6.0", "500 Ai paints, register-safe loading, Remix This Color, saved remixes, and neon-off-by-default safety."},
   {"v0.7.0", "Pearlescent Remix, finish overrides including Chrome, and preset-centric workspace experiments."},
   {"v0.8.0", "Community color expansion, specialty finishes, Three Lane evolution, Contrast/Temperature, and editable preset bases."},
   {"v0.9.0", "Final Three Lane workflow, lighting matching, advanced sort, PaintLabs rebrand, full-state presets, branding, and Color Credits."},
   {"v1.0.0", "First production release with compact paint IDs, migration-safe Favorites, creator attribution, quiet branding, and release cleanup."},
}

local function RenderPublicChangelog()
   local open = true
   if ImGui and ImGui.CollapsingHeader then
      open = ImGui.CollapsingHeader("Changelog##PaintLabsCredits") == true
   end
   if not open then return end
   for _, entry in ipairs(publicChangelog) do
      UiTextColored(0.42, 0.82, 1.00, entry[1])
      ImGui.SameLine()
      UiTextWrapped(entry[2])
   end
end
local function RenderPaintLabsCredits()
   if ClickGUI.BeginCustomChildWindow("Credits", -1) then
      UiTextColored(0.35, 1.00, 0.45, "PAINTLABS")
      UiTextColored(0.42, 0.82, 1.00, "Turn every vehicle into a rolling color showcase.")
      UiTextColored(0.72, 0.42, 1.00, "Three Lane color studio • Remix • Exotic + Ai • full-state presets")
      UiSpacing()

      if ImGui.BeginTable("PaintLabsCreditsTop", 2, ImGuiTableFlags.SizingStretchSame) then
         ImGui.TableNextRow()
         ImGui.TableSetColumnIndex(0)
         UiSection("Development", 0.72, 0.42, 1.00)
         UiTextColored(0.42, 0.82, 1.00, "Developed by:")
         ImGui.SameLine(); UiText(DEVELOPER)
         UiTextColored(0.42, 0.82, 1.00, "Coding assistance:")
         ImGui.SameLine(); UiTextColored(0.92, 0.78, 1.00, HELPER_CREDIT)
         UiTextColored(0.42, 0.82, 1.00, "Version:")
         ImGui.SameLine(); UiText(SCRIPT_VERSION)
         UiTextColored(0.42, 0.82, 1.00, "Build:")
         ImGui.SameLine(); UiText(SCRIPT_BUILD)
         UiSpacing()
         UiSection("Color Library", 1.00, 0.78, 0.25)
         UiTextColored(0.35, 1.00, 0.45, tostring(ARCHIVE_TOTAL_COUNT) .. " embedded colors")
         UiTextColored(0.35, 0.90, 1.00, tostring(ARCHIVE_IN_GAME_PEARL_COUNT) .. " confirmed in-game pearls")

         ImGui.TableSetColumnIndex(1)
         RenderBrandAsset(brandAssets.PublicUrinal, 138, 138, "Public_Urinal_Credits")
         ImGui.EndTable()
      end

      UiSpacing()
      UiSeparator()
      UiSpacing()
      RenderColorCredits()

      UiSpacing()
      UiSeparator()
      UiSpacing()
      RenderPublicChangelog()

      UiSpacing()
      UiSeparator()
      UiSpacing()
      UiSection("Community & Support", 0.42, 0.82, 1.00)
      UiTextWrapped("PaintLabs releases, support, and color showcases.")
      UiColorButton("OPEN DISCORD & COPY INVITE", "Blue", OpenAndCopyDiscord, 300, 36)
      UiSubtle(DISCORD_DISPLAY)

      UiSpacing()
      UiSeparator()
      local showProjects = true
      if ImGui and ImGui.CollapsingHeader then
         showProjects = ImGui.CollapsingHeader("Discover More Scripts##PaintLabsCredits") == true
      end
      if showProjects then
         UiSection("Other Public_Urinal Projects", 0.72, 0.42, 1.00)
         RenderCreditsProjects()
      else
         UiSubtle("Expand Discover More Scripts to view other Cherax projects.")
      end

      ClickGUI.EndCustomChildWindow()
   end
end

local function RenderPaintLabsTabRouter()
   local pushed = PushPaintLabsTabStyle()
   if ImGui and ImGui.BeginTabBar and ImGui.BeginTabBar("PaintLabsInnerTabs") then
      if ImGui.BeginTabItem("PaintLabs") then
         RenderPaintLabsMain()
         ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Guide") then
         RenderPaintLabsGuide()
         ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Credits") then
         RenderPaintLabsCredits()
         ImGui.EndTabItem()
      end
      ImGui.EndTabBar()
   else
      RenderPaintLabsMain()
   end
   PopPaintLabsTabStyle(pushed)
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- runtime registration
-- note: registers one paintlabs tab, restores preview state on unload, and keeps the
-- preview/showcase workers lightweight while the tab is inactive.
-- ═══════════════════════════════════════════════════════════════════════════════════

ClickGUI.AddTab(SCRIPT_NAME, function()
   RenderPaintLabsTabRouter()
end)

UpdatePresetColorList()
RefreshPresetList()

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
   RestorePaintSnapshot(true)
   RestoreArchiveRotation()
   ClickGUI.RemoveTab(SCRIPT_NAME)
end)

Script.RegisterLooped(function()
   local now = NowMs()
   local tabActive = (now - (previewState.lastTabRenderMs or 0)) <= 750

   if previewState.active then
      local currentVehicle = ArchiveGetVehicleHandle()
      local changedVehicle = currentVehicle ~= previewState.vehicle
      if not tabActive or changedVehicle then RestorePaintSnapshot(true) end
   end

   UpdateArchiveAutoShowcase(now, tabActive)
   UpdateArchiveRotation(now, tabActive)
   Script.Yield(50)
end)

Script.RegisterLooped(function()
   local vehicle = GetVehicleHandle()
   if vehicle then
      local dirtLevel = FeatureMgr.GetFeatureFloat(F.DirtLevel)
      if dirtLevel > 0.0 then SET_VEHICLE_DIRT_LEVEL(vehicle, dirtLevel) end
   end
end)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- bundled json helper
-- note: the following compact json implementation retains its original license text.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local json = {}
local esc = {['\\']='\\',['"']='"',['\b']='b',['\f']='f',['\n']='n',['\r']='r',['\t']='t'}
local rev = {b='\b',f='\f',n='\n',r='\r',t='\t'}

local function encode(v)
   local t = type(v)
   if t == "string" then return '"'..v:gsub('[%z\1-\31\\"]', function(c) return "\\"..(esc[c] or string.format("u%04x", c:byte())) end)..'"' end
   if t == "number" or t == "boolean" then return tostring(v) end
   if t == "table" then
      local res, is_arr = {}, #v > 0
      for k, vv in pairs(v) do
         if is_arr then table.insert(res, encode(vv))
         else table.insert(res, encode(tostring(k))..":"..encode(vv)) end
      end
      return is_arr and "["..table.concat(res, ",").."]" or "{"..table.concat(res, ",").."}"
   end
   return "null"
end

local function parse(s, i)
   i = s:find("%S", i) or i
   local c = s:sub(i, i)
   if c == '{' or c == '[' then
      local res, term, close = {}, c == '{' and ':' or nil, c == '{' and '}' or ']'
      i = i + 1
      if s:sub((s:find("%S", i)), s:find("%S", i)) == close then return res, (s:find(close, i)) + 1 end
      repeat
         local k, v
         if term then k, i = parse(s, i); i = s:find(":", i) + 1 end
         v, i = parse(s, i)
         if term then res[k] = v else table.insert(res, v) end
         i = s:find("%S", i); c = s:sub(i, i); i = i + 1
      until c == close
      return res, i
   elseif c == '"' then
      local res, j = "", i + 1
      while true do
         local x, e = s:find('[\\"]', j)
         res = res .. s:sub(j, x - 1)
         if s:sub(x, x) == '"' then return res, x + 1 end
         local esc_c = s:sub(x+1, x+1)
         res, j = res .. (rev[esc_c] or esc_c), x + 2
      end
   else
      local x = s:find("[^%w%.%-]", i) or #s + 1
      local item = s:sub(i, x - 1)
      local val = item == "true" and true or item == "false" and false or item == "null" and nil or tonumber(item)
      return val, x
   end
end

function json.encode(v) return encode(v) end
function json.decode(s) return (parse(s, 1)) end

_G.json = json
