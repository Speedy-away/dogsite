-- sorry for the 47 lua submissions, i promise i'm learning — nightkitty

do
    local cat = {
        "        /\\_____/\\",
        "       /  >   <  \\",
        "      ( ==  ^  == )  HISSS!!",
        "       )           (",
        "      (             )",
        "      |             |\\",
        "      \\____________/ \\",
        "                      \\__~",
    }
    for _, line in ipairs(cat) do Logger.LogInfo(line) end
end

local soundFile = nil
local _xhair       = false
local _xhairOnlyAim  = true
local _xhairHideOrig = true
local _xhairTop    = true
local _xhairBot    = true
local _xhairLeft   = true
local _xhairRight  = true
local _xhairDot    = false
local _xhairLen    = 2
local _xhairGap    = 1
local _xhairSize   = 1
local _xhairR, _xhairG, _xhairB, _xhairA = 0, 255, 0, 200
local _xhairUseImage = false
local _xhairTexId    = nil
local _xhairPHId     = nil


do
    local soundDir = FileMgr.GetMenuRootPath() .. "\\Lua\\discord_rpc\\"
    FileMgr.CreateDir(soundDir)
    local files = FileMgr.FindFiles(soundDir, ".wav", false)
    if files and #files > 0 then
        soundFile = files[1]
        Utils.PlaySound(soundFile, false)
    else
        Script.QueueJob(function()
            Script.Yield(500)
            pcall(Natives.InvokeVoid, 0x67C540AA08E4A6F5, -1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
        end)
    end
end

math.randomseed(math.floor(os.clock() * 1000000))

Script.QueueJob(function()
    if math.random(3) ~= 1 then return end
    local curl = Curl.Easy()
    curl:Setopt(eCurlOption.CURLOPT_URL, "https://catfact.ninja/fact")
    curl:Perform()
    while not curl:GetFinished() do Script.Yield(100) end
    local code, response = curl:GetResponse()
    if code == eCurlCode.CURLE_OK and response then
        local fact = response:match('"fact"%s*:%s*"([^"]*)"')
        if fact then
            fact = fact:gsub("\\u00a0", " ")
                       :gsub("\\u2018", "'"):gsub("\\u2019", "'")
                       :gsub("\\u201c", '"'):gsub("\\u201d", '"')
                       :gsub("\\u2013", "-"):gsub("\\u2014", "--")
                       :gsub("\\u%x%x%x%x", "")
                       :gsub("https?://%S+", "")
            GUI.AddToast("Cat Fact", fact, 8000)
        end
    end
end)

local CLIENT_ID    = "1290750418070016105"
local SCRIPT_VERSION = "1.2.4"
local CHANGELOG = [[
v1.2.4
- Added custom image crosshair (place crosshair.png in discord_rpc folder)
- Fixed presence not updating when transitioning from online to main menu

v1.2.3
- Added custom crosshair (Cool Debug Stuff > Crosshair tab)
- Fixed ImGui errors in menus

v1.2.0
- Added gambling status detection (casino)
- Fixed Editing Character false positives during missions and main menu
- Fixed Changing Session getting stuck
- Improved session state detection order

v1.1.0
- Initial public release
- Discord Rich Presence with session type detection
- Vehicle, zone, and mission activity tracking
- Configurable buttons, activity type, and sound support
]]
local _clPending = true
local _clOpened  = false
local ACTIVITY_TYPE = 0
local LARGE_IMAGE  = "chrx"
local LARGE_TEXT   = "Grand Theft Auto V"
local BUTTONS      = {}

local rpc = {
    active       = false,
    pipe         = nil,
    pipeIndex    = -1,
    startTime    = 0,
    pid          = 1234,
    lastLoopTick = 0,
}

local discordUser = { id = nil, name = nil, globalName = nil, discriminator = nil, avatar = nil }

local menuDetails  = "Cherax"
local showActivity = true

local function rpcLog(msg)
    Logger.LogInfo("[DiscordRPC] " .. tostring(msg))
end

local function encodeJson(val)
    local t = type(val)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return tostring(val)
    elseif t == "number" then
        return (val == math.floor(val)) and string.format("%d", val) or string.format("%g", val)
    elseif t == "string" then
        return '"' .. val
            :gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\t', '\\t') .. '"'
    elseif t == "table" then
        if #val > 0 then
            local parts = {}
            for _, v in ipairs(val) do
                parts[#parts + 1] = encodeJson(v)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(val) do
                if type(k) == "string" then
                    parts[#parts + 1] = encodeJson(k) .. ":" .. encodeJson(v)
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

local function sendIpc(opcode, payload)
    if not rpc.pipe then return false end
    local encoded = encodeJson(payload)
    local ok, err = pcall(function()
        rpc.pipe:write(string.pack("<II", opcode, #encoded))
        rpc.pipe:write(encoded)
        rpc.pipe:flush()
    end)
    if not ok then
        rpcLog("send error op=" .. tostring(opcode) .. "  " .. tostring(err))
    end
    return ok
end

local function readIpc()
    if not rpc.pipe then return false, "no_pipe" end
    local header = rpc.pipe:read(8)
    if not header then return false, "no_header" end
    local opcode, length = string.unpack("<II", header)
    local body = rpc.pipe:read(length)
    if not body then return false, "no_body" end
    return true, opcode, body
end

local function openPipe()
    for i = 0, 9 do
        local path = "\\\\.\\pipe\\discord-ipc-" .. i
        local f = io.open(path, "r+b")
        if f then
            rpcLog("opened pipe: " .. path)
            rpc.pipeIndex = i
            return f
        end
    end
    rpcLog("no Discord IPC pipe found — is Discord running?")
    return nil
end

local function handshake()
    if not sendIpc(0, { v = 1, client_id = CLIENT_ID }) then
        return false, "send_failed"
    end
    local ok, _, body = readIpc()
    if not ok then return false, "read_failed" end
    if body then
        discordUser.id = body:match('"id"%s*:%s*"(%d+)"')
        discordUser.name = body:match('"username"%s*:%s*"([^"]+)"')
        discordUser.globalName = body:match('"global_name"%s*:%s*"([^"]+)"')
        discordUser.discriminator = body:match('"discriminator"%s*:%s*"([^"]+)"')
        discordUser.avatar = body:match('"avatar"%s*:%s*"([^"]+)"')
        rpcLog("READY: user=" .. tostring(discordUser.name) .. "  id=" .. tostring(discordUser.id))
    end
    return true
end

local function reconnectPipe()
    pcall(function() rpc.pipe:close() end)
    rpc.pipe = openPipe()
    if not rpc.pipe then return false end
    local ok = handshake()
    if not ok then
        pcall(function() rpc.pipe:close() end)
        rpc.pipe = nil
        return false
    end
    rpcLog("pipe reconnected")
    return true
end

local function nativeBool(hash)
    local ok, val = pcall(Natives.InvokeBool, hash)
    return ok and val == true
end

local MISSION_SCRIPTS = {
    fm_mission_controller = "Contact Mission",
    fm_mission_controller_2020 = "Contact Mission",

    heist_island_planning = "Cayo Perico Heist",
    am_heist_island = "Cayo Perico Heist",
    fm_content_casino_heist = "Casino Heist",
    am_casino_heist = "Casino Heist",

    casino_slots = "Gambling",
    am_heist_ctrl = "Heist",
    am_heist_int = "Heist",

    fm_content_gunrunning = "Gunrunning",
    gb_illicit_goods_resupply = "MC Business",
    fm_content_bike_org = "MC Business",
    fm_content_acid_lab_source = "Acid Lab",
    fm_content_acid_lab_sell = "Acid Lab",
    fm_content_smuggler_ops = "Smuggler Run",
    fm_content_smuggler_plane = "Smuggler Run",
    fm_content_smuggler_resupply = "Smuggler Run",
    fm_content_smuggler_sell = "Smuggler Run",
    fm_content_smuggler_trail = "Smuggler Run",
    fm_content_club_management = "Nightclub",
    fm_content_club_source = "Nightclub",
    fm_content_club_odd_jobs = "Nightclub",
    fm_content_auto_shop_delivery = "Auto Shop",
    fm_content_chop_shop_delivery = "Chop Shop",

    fm_content_payphone_hit = "Payphone Hit",
    fm_horde_controler = "Survival",

    fm_race_controler = "Race",
    bj_race_controler = "Race",
    fm_bj_race_controler = "Race",
    am_deathmatch = "Deathmatch",
    fm_deathmatch_controler = "Deathmatch",
    fm_impromptu_dm_controler = "Impromptu DM",

    am_armwrestling = "Arm Wrestling",
    am_armwrestling_apartment = "Arm Wrestling",
    am_tennis = "Tennis",
    golf_mp = "Golf",
    am_darts = "Darts",
    am_darts_apartment = "Darts",
}

local cachedFreemode    = false
local cachedMainMenu    = false
local cachedScriptCount = 0

local function getActiveMission()
    cachedFreemode    = false
    cachedMainMenu    = false
    cachedScriptCount = 0
    local found = nil
    pcall(Natives.InvokeVoid, 0xDADFADA5A20143A8)
    while true do
        local ok, tid = pcall(Natives.InvokeInt, 0x30B4FA1C82DD4B9F)
        if not ok or not tid or tid == 0 then break end
        local ok2, sname = pcall(Natives.InvokeString, 0x05A42BA9FC8DA96B, tid)
        if ok2 and sname then
            cachedScriptCount = cachedScriptCount + 1
            local lower = sname:lower()
            if lower == "freemode"          then cachedFreemode = true end
            if lower == "startup_positioning" then cachedMainMenu = true end
            if not found then
                local label = MISSION_SCRIPTS[lower]
                if label then found = label end
            end
        end
    end
    return found
end

local function getRadioName()
    local ok, station = pcall(Natives.InvokeString, 0xF6D733C32076AD03)
    if not ok or not station or station == "" or station == "RADIO_OFF" then return nil end
    local ok2, name = pcall(Natives.InvokeString, 0x7B5280EBA9840C72, station)
    if ok2 and name and name ~= "" then return name end
    local cleaned = station:gsub("^RADIO_%d*_?", ""):gsub("^DLC_[^_]+_", ""):gsub("_", " ")
    return cleaned ~= "" and cleaned or nil
end

local _noClipFeat = nil
local function isNoclipping()
    if not _noClipFeat then
        local ok, f = pcall(FeatureMgr.GetFeatureByName, "No Clip")
        if ok and f then _noClipFeat = f end
    end
    if _noClipFeat and _noClipFeat:IsToggled() then return true end
    local ped = GTA.GetLocalPed()
    return ped and ped.PlayerInfo and ped.PlayerInfo.UsingFreeCamera or false
end

local function getSmallImage()
    if isNoclipping() then
        return "icon_noclip", "Noclipping"
    end
    local veh = GTA.GetLocalVehicle()
    if veh then
        local info = veh.ModelInfo
        if info and info.Model and info.Model ~= 0 then
            local ok, vClass = pcall(Natives.InvokeInt, 0xDEDF1C8BD47C2200, info.Model)
            if ok then
                if vClass == 8 or vClass == 13 then return "icon_bike", "On a bike" end
                if vClass == 14 then return "icon_boat", "On the water" end
                if vClass == 15 then return "icon_heli", "In a helicopter" end
                if vClass == 16 then return "icon_plane", "In a plane" end
            end
        end
        return "icon_car", "In a vehicle"
    end
    return "icon_foot", "On foot"
end

local function getPlayerActivity()
    local mission = getActiveMission()
    local prefix  = mission and (mission .. "  •  ") or ""

    if isNoclipping() then return prefix .. "Noclipping" end

    local veh = GTA.GetLocalVehicle()
    if veh then
        local info = veh.ModelInfo
        if info then
            local hash = info.Model
            if hash and hash ~= 0 then
                local verb = "Driving"
                local okClass, vClass = pcall(Natives.InvokeInt, 0xDEDF1C8BD47C2200, hash)
                if okClass then
                    if vClass == 8  then verb = "Riding"
                    elseif vClass == 13 then verb = "Cycling"
                    elseif vClass == 14 then verb = "Sailing"
                    elseif vClass == 15 or vClass == 16 then verb = "Flying"
                    end
                end

                local ok, label = pcall(Natives.InvokeString, 0xB215AAC32D25D019, hash)
                if ok and label and label ~= "" then
                    local name = GTA.GetLabelText(label)
                    if name and name ~= "" and name ~= "NULL" then
                        local radio = getRadioName()
                        local activity = verb .. " a " .. name
                        if radio then activity = activity .. "  •  " .. radio end
                        return prefix .. activity
                    end
                end
            end
        end
        return prefix .. "In a Vehicle"
    end

    local ped = GTA.GetLocalPed()
    if ped then
        local pos = ped.Position
        if pos then
            local ok, zone = pcall(Natives.InvokeString, 0xCD90657D4C30E1CA, pos.x, pos.y, pos.z)
            if ok and zone and zone ~= "" then
                local name = GTA.GetLabelText(zone)
                if name and name ~= "" and name ~= "NULL" then
                    return prefix .. "On foot in " .. name
                end
                return prefix .. "On foot in " .. zone
            end
        end
    end

    return prefix .. "In Los Santos"
end

local _playingReminderShown = false

local function getSessionState()
    getActiveMission()
    local ok, count = pcall(Natives.InvokeInt, 0xA4A79DD2D9600654)
    count = (ok and type(count) == "number") and count or 0

    if cachedFreemode then
        if nativeBool(0xFBCFA2EA2E206890) then
            return ("Friends Only  •  %d players"):format(count), "friends"
        elseif nativeBool(0x74732C6CA90DA2B4) then
            return ("Crew Session  •  %d players"):format(count), "crew"
        elseif nativeBool(0xF3929C2379B60CCE) then
            return "Solo Session", "solo"
        elseif nativeBool(0xCEF70AA5B3F89BA1) then
            return ("Invite Only  •  %d players"):format(count), "invite"
        else
            return ("Public Session  •  %d players"):format(count), "public"
        end
    end

    if count == 0 then
        if (cachedMainMenu and cachedScriptCount <= 3) or not GTA.GetLocalPed() then
            return "Browsing Main Menu", "mainmenu"
        end
        return "Story Mode", "story"
    end

    if nativeBool(0xFBCFA2EA2E206890) then
        return ("Friends Only  •  %d players"):format(count), "friends"
    elseif nativeBool(0x74732C6CA90DA2B4) then
        return ("Crew Session  •  %d players"):format(count), "crew"
    elseif nativeBool(0xF3929C2379B60CCE) then
        return "Solo Session", "solo"
    elseif nativeBool(0xCEF70AA5B3F89BA1) then
        return ("Invite Only  •  %d players"):format(count), "invite"
    else
        return ("Public Session  •  %d players"):format(count), "public"
    end
end

local function buildActivity(state, details)
    local smallImg, smallTxt = getSmallImage()
    local activity = {
        type       = ACTIVITY_TYPE,
        details    = details,
        state      = state,
        timestamps = { start = rpc.startTime * 1000 },
        assets     = {
            large_image = LARGE_IMAGE,
            large_text  = menuDetails,
            small_image = smallImg,
            small_text  = smallTxt,
        },
        instance   = true,
    }

    if #BUTTONS > 0 then
        activity.buttons = BUTTONS
    end

    return activity
end

local _lastActivitySend = 0

local function setActivity(activity)
    local now = os.clock()
    if now - _lastActivitySend < 4 then return true, false end
    local ok = sendIpc(1, {
        cmd   = "SET_ACTIVITY",
        args  = { pid = rpc.pid, activity = activity },
        nonce = tostring(os.time()),
    })
    if ok then
        _lastActivitySend = now
        pcall(readIpc)
        return true, true
    end
    return false, false
end

local function clearActivity()
    pcall(function()
        local encoded = ('{"cmd":"SET_ACTIVITY","args":{"pid":%d,"activity":null},"nonce":"%s"}')
            :format(rpc.pid, tostring(os.time()))
        rpc.pipe:write(string.pack("<II", 1, #encoded))
        rpc.pipe:write(encoded)
        rpc.pipe:flush()
    end)
end

local function getCurrentDetails()
    if not showActivity then return menuDetails end
    if not GTA.GetLocalPed() then return menuDetails end
    return menuDetails .. "  •  " .. getPlayerActivity()
end

local function pushNow()
    if not rpc.active then return end
    _lastActivitySend = 0
    local stateStr = getSessionState()
    local ok = setActivity(buildActivity(stateStr, getCurrentDetails()))
    if ok then
        GUI.AddToast("Discord RPC", "Presence pushed. Discord may take up to 15s to update.", 4000)
    else
        GUI.AddToast("Discord RPC", "Failed to push -- pipe may be broken. Try toggling RPC off and on.", 5000)
    end
end

function EnableDiscordRPC()
    if rpc.active then return end

    rpc.pipe = openPipe()
    if not rpc.pipe then
        discordUser.id   = "Discord not running"
        discordUser.name = "N/A"
        GUI.AddToast("Discord RPC", "Discord not detected — start Discord then try again.", 5000)
        return
    end

    local ok, reason = handshake()
    if not ok then
        rpcLog("handshake failed: " .. tostring(reason))
        pcall(function() rpc.pipe:close() end)
        rpc.pipe         = nil
        discordUser.id   = "Handshake failed"
        discordUser.name = "N/A"
        return
    end

    rpc.active    = true
    rpc.startTime = os.time()
    rpc.pid       = math.floor(rpc.startTime) % 60000 + 1000

    local version = tostring(Cherax.GetVersion() or "?")
    menuDetails = ("Cherax v%s"):format(version)
    LARGE_IMAGE = version:find("BE") and "prime" or "chrx"

    if ACTIVITY_TYPE == 0 and not _playingReminderShown then
        _playingReminderShown = true
        GUI.AddToast("Discord RPC", "Reminder -- if using Playing type, disable GTA built-in Discord presence to avoid conflicts.", 20000)
    end

    local initState, _ = getSessionState()
    if not setActivity(buildActivity(initState, getCurrentDetails())) then
        rpcLog("initial SET_ACTIVITY failed")
        DisableDiscordRPC()
        return
    end

    rpcLog("RPC active")
    _startRpcLoop()
end

function _startRpcLoop()
    rpc.lastLoopTick = os.clock()
    Script.QueueJob(function()
        local lastStateStr = getSessionState()
        local lastDetails  = getCurrentDetails()

        while rpc.active and not ShouldUnload() do
            Script.Yield(0)
            rpc.lastLoopTick = os.clock()
            if not rpc.active or ShouldUnload() then break end

            local loopOk, loopErr = pcall(function()
                local stateStr = getSessionState()
                local details             = getCurrentDetails()

                if stateStr ~= lastStateStr or details ~= lastDetails then
                    local ok, sent = setActivity(buildActivity(stateStr, details))
                    if not ok then
                        rpcLog("pipe broken in loop, reconnecting...")
                        if reconnectPipe() then
                            ok, sent = setActivity(buildActivity(stateStr, details))
                        else
                            DisableDiscordRPC()
                            return
                        end
                    end
                    if sent then
                        lastStateStr = stateStr
                        lastDetails  = details
                    end
                end
            end)
            if not loopOk then
                rpcLog("loop error: " .. tostring(loopErr))
            end
        end

        if ShouldUnload() and (rpc.active or rpc.pipe) then
            DisableDiscordRPC()
        end

        rpcLog("update loop exited")
    end)
end

function DisableDiscordRPC()
    if not rpc.active and not rpc.pipe then return end

    rpc.active = false
    pcall(Script.Yield, 50)

    if rpc.pipe then
        clearActivity()
        pcall(function() rpc.pipe:close() end)
        rpc.pipe = nil
    end

    rpcLog("RPC disabled")
end

local CFG_PATH = FileMgr.GetMenuRootPath() .. "\\Lua\\discord_rpc\\config.json"

local function cfgRead(json, key)
    local n = json:match('"' .. key .. '"%s*:%s*(-?%d+%.?%d*)')
    if n then return tonumber(n) end
    if json:match('"' .. key .. '"%s*:%s*true') then return true end
    if json:match('"' .. key .. '"%s*:%s*false') then return false end
    local s = json:match('"' .. key .. '"%s*:%s*"(.-)"')
    if s then return s:gsub('\\"', '"') end
end

local function saveConfig()
    local toggleF = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_toggle"))
    local typeF = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_type"))
    local actF  = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_act_mode"))
    local b1en  = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_en"))
    local b1lbl = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_label"))
    local b1url = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_url"))
    local b2en  = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_en"))
    local b2lbl = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_label"))
    local b2url = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_url"))
    local cfg = {
        rpcEnabled        = toggleF and toggleF:IsToggled() or false,
        activityTypeIndex = typeF and typeF:GetListIndex() or 0,
        showActivity      = actF  and actF:IsToggled()    or true,
        btn1enabled       = b1en  and b1en:IsToggled()    or false,
        btn1label         = b1lbl and b1lbl:GetStringValue() or "",
        btn1url           = b1url and b1url:GetStringValue() or "",
        btn2enabled       = b2en  and b2en:IsToggled()    or false,
        btn2label         = b2lbl and b2lbl:GetStringValue() or "",
        btn2url           = b2url and b2url:GetStringValue() or "",
    }
    local f = io.open(CFG_PATH, "w")
    if not f then rpcLog("could not write config") return end
    f:write('{\n')
    f:write(('  "rpcEnabled": %s,\n'):format(tostring(cfg.rpcEnabled)))
    f:write(('  "activityTypeIndex": %d,\n'):format(cfg.activityTypeIndex))
    f:write(('  "showActivity": %s,\n'):format(tostring(cfg.showActivity)))
    f:write(('  "btn1enabled": %s,\n'):format(tostring(cfg.btn1enabled)))
    f:write(('  "btn1label": %s,\n'):format(encodeJson(cfg.btn1label)))
    f:write(('  "btn1url": %s,\n'):format(encodeJson(cfg.btn1url)))
    f:write(('  "btn2enabled": %s,\n'):format(tostring(cfg.btn2enabled)))
    f:write(('  "btn2label": %s,\n'):format(encodeJson(cfg.btn2label)))
    f:write(('  "btn2url": %s,\n'):format(encodeJson(cfg.btn2url)))
    f:write(('  "lastVersion": %s\n'):format(encodeJson(SCRIPT_VERSION)))
    f:write('}\n')
    f:close()
    GUI.AddToast("Discord RPC", "Config saved.", 3000)
    rpcLog("config saved")
end

local TYPE_VALUES = { [0]=0, [1]=2, [2]=3, [3]=5 }
local TYPE_NAMES  = { "Playing", "Listening", "Watching", "Competing" }

local rebuildButtons

local function loadConfig()
    local f = io.open(CFG_PATH, "r")
    if not f then return end
    local json = f:read("*a")
    f:close()

    local typeIdx = cfgRead(json, "activityTypeIndex")
    if typeIdx then
        local typeF = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_type"))
        if typeF then typeF:SetListIndex(typeIdx) end
        ACTIVITY_TYPE = TYPE_VALUES[typeIdx] or 0
    end

    local showAct = cfgRead(json, "showActivity")
    if showAct ~= nil then
        showActivity = showAct
        local actF = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_act_mode"))
        if actF then actF:SetBoolValue(showAct) end
    end

    local b1en = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_en"))
    local b1lbl = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_label"))
    local b1url = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn1_url"))
    local b2en = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_en"))
    local b2lbl = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_label"))
    local b2url = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_btn2_url"))

    local v
    v = cfgRead(json, "btn1enabled"); if b1en and v ~= nil then b1en:SetBoolValue(v) end
    v = cfgRead(json, "btn1label"); if b1lbl and v then b1lbl:SetStringValue(v) end
    v = cfgRead(json, "btn1url"); if b1url and v then b1url:SetStringValue(v) end
    v = cfgRead(json, "btn2enabled"); if b2en and v ~= nil then b2en:SetBoolValue(v) end
    v = cfgRead(json, "btn2label"); if b2lbl and v then b2lbl:SetStringValue(v) end
    v = cfgRead(json, "btn2url"); if b2url and v then b2url:SetStringValue(v) end

    rebuildButtons()

    local rpcOn = cfgRead(json, "rpcEnabled")
    if rpcOn then
        local toggleF = FeatureMgr.GetFeature(Utils.Joaat("discord_rpc_toggle"))
        if toggleF then toggleF:SetBoolValue(true) end
        Script.QueueJob(EnableDiscordRPC)
    end

    local lastVer = cfgRead(json, "lastVersion")
    if lastVer == SCRIPT_VERSION then
        _clPending = false
    end

    rpcLog("config loaded")
end

local HASH_TOGGLE = Utils.Joaat("discord_rpc_toggle")
local HASH_STATUS = Utils.Joaat("discord_rpc_status")
local HASH_TYPE = Utils.Joaat("discord_rpc_type")
local HASH_ACT_MODE = Utils.Joaat("discord_rpc_act_mode")

FeatureMgr.AddFeature(
    HASH_TOGGLE,
    "Discord Rich Presence",
    eFeatureType.Toggle,
    "Connects to Discord and shows your GTA V session as Rich Presence.\nRequires Discord to be open.",
    function(f)
        if f:IsToggled() then
            Script.QueueJob(EnableDiscordRPC)
        else
            Script.QueueJob(DisableDiscordRPC)
        end
    end
)

local infoFeature = FeatureMgr.AddFeature(
    HASH_STATUS,
    "Status: Inactive",
    eFeatureType.Button,
    "Shows the current Discord connection status.",
    function() end
)

local typeFeature = FeatureMgr.AddFeature(
    HASH_TYPE,
    "Activity Type",
    eFeatureType.List,
    "Changes how Discord labels your activity.",
    function(f)
        ACTIVITY_TYPE = TYPE_VALUES[f:GetListIndex()] or 0
        Script.QueueJob(pushNow)
    end
)
if typeFeature then
    typeFeature:SetList(TYPE_NAMES)
end

local actModeFeature = FeatureMgr.AddFeature(
    HASH_ACT_MODE,
    "Show Player Activity",
    eFeatureType.Toggle,
    "ON: shows what you're driving or walking. OFF: shows Cherax version in details.",
    function(f)
        showActivity = f:IsToggled()
        Script.QueueJob(pushNow)
    end
)
if actModeFeature then
    actModeFeature:SetBoolValue(true)
end

local HASH_FORCE_UPDATE = Utils.Joaat("discord_rpc_force_update")
local HASH_SAVE_CFG     = Utils.Joaat("discord_rpc_save_cfg")

FeatureMgr.AddFeature(HASH_FORCE_UPDATE, "Force Update", eFeatureType.Button, "Pushes current presence to Discord. Note: Discord rate-limits updates to ~1 per 15 seconds so changes may not appear immediately.", function()
    Script.QueueJob(pushNow)
end)

FeatureMgr.AddFeature(HASH_SAVE_CFG, "Save Config", eFeatureType.Button, "Saves current settings to disk.", function()
    saveConfig()
end)

local HASH_SND_PLAY = Utils.Joaat("discord_rpc_snd_play")
local HASH_SND_STOP = Utils.Joaat("discord_rpc_snd_stop")
local HASH_SND_LOOP = Utils.Joaat("discord_rpc_snd_loop")

FeatureMgr.AddFeature(HASH_SND_PLAY, "Play Sound", eFeatureType.Button, "Replays the loaded .wav file.", function()
    if soundFile then Utils.PlaySound(soundFile, false)
    else GUI.AddToast("No Sound", "No .wav found in discord_rpc folder.", 3000) end
end)

FeatureMgr.AddFeature(HASH_SND_STOP, "Stop Sound", eFeatureType.Button, "Stops the currently playing sound.", function()
    Utils.StopSound()
end)

FeatureMgr.AddFeature(HASH_SND_LOOP, "Loop Sound", eFeatureType.Toggle, "Loops the .wav file continuously.", function(f)
    if soundFile then
        if f:IsToggled() then Utils.PlaySound(soundFile, true)
        else Utils.StopSound() end
    else GUI.AddToast("No Sound", "No .wav found in discord_rpc folder.", 3000) end
end)

local HASH_BTN1_EN    = Utils.Joaat("discord_rpc_btn1_en")
local HASH_BTN1_LABEL = Utils.Joaat("discord_rpc_btn1_label")
local HASH_BTN1_URL   = Utils.Joaat("discord_rpc_btn1_url")
local HASH_BTN2_EN    = Utils.Joaat("discord_rpc_btn2_en")
local HASH_BTN2_LABEL = Utils.Joaat("discord_rpc_btn2_label")
local HASH_BTN2_URL   = Utils.Joaat("discord_rpc_btn2_url")
local HASH_BTN_APPLY  = Utils.Joaat("discord_rpc_btn_apply")

rebuildButtons = function()
    BUTTONS = {}
    local f1en = FeatureMgr.GetFeature(HASH_BTN1_EN)
    if f1en and f1en:IsToggled() then
        local lbl = FeatureMgr.GetFeature(HASH_BTN1_LABEL)
        local url = FeatureMgr.GetFeature(HASH_BTN1_URL)
        local l = lbl and lbl:GetStringValue() or ""
        local u = url and url:GetStringValue() or ""
        if l ~= "" and u ~= "" then BUTTONS[#BUTTONS + 1] = { label = l, url = u } end
    end
    local f2en = FeatureMgr.GetFeature(HASH_BTN2_EN)
    if f2en and f2en:IsToggled() then
        local lbl = FeatureMgr.GetFeature(HASH_BTN2_LABEL)
        local url = FeatureMgr.GetFeature(HASH_BTN2_URL)
        local l = lbl and lbl:GetStringValue() or ""
        local u = url and url:GetStringValue() or ""
        if l ~= "" and u ~= "" then BUTTONS[#BUTTONS + 1] = { label = l, url = u } end
    end
    Script.QueueJob(pushNow)
end

FeatureMgr.AddFeature(HASH_BTN1_EN,    "Button 1 Enabled",  eFeatureType.Toggle,    "Show button 1 on your presence.", function() rebuildButtons() end)
local btn1lbl = FeatureMgr.AddFeature(HASH_BTN1_LABEL, "Button 1 Label",    eFeatureType.InputText, "Text shown on button 1 (max 32 chars).", function() end)
if btn1lbl then btn1lbl:SetStringValue("My Website") end
local btn1url = FeatureMgr.AddFeature(HASH_BTN1_URL,   "Button 1 URL",      eFeatureType.InputText, "URL opened when button 1 is clicked.", function() end)
if btn1url then btn1url:SetStringValue("https://nightkitty.xyz") end
FeatureMgr.AddFeature(HASH_BTN2_EN,    "Button 2 Enabled",  eFeatureType.Toggle,    "Show button 2 on your presence.", function() rebuildButtons() end)
local btn2lbl = FeatureMgr.AddFeature(HASH_BTN2_LABEL, "Button 2 Label",    eFeatureType.InputText, "Text shown on button 2 (max 32 chars).", function() end)
if btn2lbl then btn2lbl:SetStringValue("") end
local btn2url = FeatureMgr.AddFeature(HASH_BTN2_URL,   "Button 2 URL",      eFeatureType.InputText, "URL opened when button 2 is clicked.", function() end)
if btn2url then btn2url:SetStringValue("") end
FeatureMgr.AddFeature(HASH_BTN_APPLY,  "Apply Buttons",     eFeatureType.Button,    "Push label/URL changes to Discord.", function() rebuildButtons() end)

local HASH_DBG_RPC      = Utils.Joaat("discord_rpc_dbg_rpc")
local HASH_DBG_USER     = Utils.Joaat("discord_rpc_dbg_user")
local HASH_DBG_DISPNAME = Utils.Joaat("discord_rpc_dbg_dispname")
local HASH_DBG_DISC     = Utils.Joaat("discord_rpc_dbg_disc")
local HASH_DBG_AVATAR   = Utils.Joaat("discord_rpc_dbg_avatar")
local HASH_DBG_PIPE     = Utils.Joaat("discord_rpc_dbg_pipe")
local HASH_DBG_SES      = Utils.Joaat("discord_rpc_dbg_ses")
local HASH_DBG_DET      = Utils.Joaat("discord_rpc_dbg_det")

local function xhairLoadImage()
    local dir = FileMgr.GetMenuRootPath() .. "\\Lua\\discord_rpc\\"
    local files = FileMgr.FindFiles(dir, ".png", false)
    if not files or #files == 0 then
        GUI.AddToast("Crosshair", "No PNG found in discord_rpc folder.", 3000)
        return false
    end
    for _, f in ipairs(files) do
        if f:lower():find("crosshair") then
            _xhairTexId = Texture.LoadTexture(f)
            return true
        end
    end
    _xhairTexId = Texture.LoadTexture(files[1])
    return true
end

local function xhairApplyImageMode()
    if _xhairPHId then
        EventMgr.RemoveHandler(_xhairPHId)
        _xhairPHId = nil
    end
    if not _xhairUseImage then return end
    if not _xhairTexId then
        if not xhairLoadImage() then return end
    end
    _xhairPHId = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        if not _xhair or not _xhairUseImage then return end
        if not _xhairTexId or not Texture.IsTextureValid(_xhairTexId) then return end
        local tex = Texture.GetTexture(_xhairTexId)
        if not tex then return end
        local ok, pid = pcall(Natives.InvokeInt, 0x4F8644AF03D0E0D6)
        local aiming = true
        if _xhairOnlyAim then
            local ok2, v = pcall(Natives.InvokeBool, 0x2E397FD2ECD37C87, ok and pid or 0)
            aiming = ok2 and v == true
        end
        if not aiming then return end
        local sw, sh = ImGui.GetDisplaySize()
        ImGui.AddImageRotated(tex:GetCurrent(), sw * 0.5, sh * 0.5, tex:GetWidth(), tex:GetHeight(), 0, _xhairA)
    end)
end

local HASH_XHAIR          = Utils.Joaat("discord_rpc_xhair")
local HASH_XHAIR_ONLY_AIM = Utils.Joaat("discord_rpc_xhair_onlyaim")
local HASH_XHAIR_HIDE     = Utils.Joaat("discord_rpc_xhair_hide")
local HASH_XHAIR_TOP      = Utils.Joaat("discord_rpc_xhair_top")
local HASH_XHAIR_BOT      = Utils.Joaat("discord_rpc_xhair_bot")
local HASH_XHAIR_LEFT     = Utils.Joaat("discord_rpc_xhair_left")
local HASH_XHAIR_RIGHT    = Utils.Joaat("discord_rpc_xhair_right")
local HASH_XHAIR_DOT      = Utils.Joaat("discord_rpc_xhair_dot")
local HASH_XHAIR_LEN      = Utils.Joaat("discord_rpc_xhair_len")
local HASH_XHAIR_GAP      = Utils.Joaat("discord_rpc_xhair_gap")
local HASH_XHAIR_SIZE     = Utils.Joaat("discord_rpc_xhair_size")
local HASH_XHAIR_COLOR      = Utils.Joaat("discord_rpc_xhair_color")
local HASH_XHAIR_USE_IMAGE  = Utils.Joaat("discord_rpc_xhair_use_image")
local HASH_XHAIR_RELOAD_IMG = Utils.Joaat("discord_rpc_xhair_reload_img")

FeatureMgr.AddFeature(HASH_XHAIR,          "Crosshair",        eFeatureType.Toggle, "Draws a custom crosshair on screen.",                     function(f) _xhair         = f:IsToggled() end)
local _xhAim  = FeatureMgr.AddFeature(HASH_XHAIR_ONLY_AIM, "Only When Aiming", eFeatureType.Toggle, "Only show crosshair when aiming a weapon.",               function(f) _xhairOnlyAim  = f:IsToggled() end)
local _xhHide = FeatureMgr.AddFeature(HASH_XHAIR_HIDE,     "Hide Default",     eFeatureType.Toggle, "Hide the original GTA crosshair while custom is active.", function(f) _xhairHideOrig = f:IsToggled() end)
local _xhT    = FeatureMgr.AddFeature(HASH_XHAIR_TOP,      "Top Arm",          eFeatureType.Toggle, "Show top arm.",    function(f) _xhairTop   = f:IsToggled() end)
local _xhB    = FeatureMgr.AddFeature(HASH_XHAIR_BOT,      "Bottom Arm",       eFeatureType.Toggle, "Show bottom arm.", function(f) _xhairBot   = f:IsToggled() end)
local _xhL    = FeatureMgr.AddFeature(HASH_XHAIR_LEFT,     "Left Arm",         eFeatureType.Toggle, "Show left arm.",   function(f) _xhairLeft  = f:IsToggled() end)
local _xhR    = FeatureMgr.AddFeature(HASH_XHAIR_RIGHT,    "Right Arm",        eFeatureType.Toggle, "Show right arm.",  function(f) _xhairRight = f:IsToggled() end)
FeatureMgr.AddFeature(HASH_XHAIR_DOT, "Center Dot", eFeatureType.Toggle, "Show center dot.", function(f) _xhairDot = f:IsToggled() end)
if _xhAim  then _xhAim:SetBoolValue(true)  end
if _xhHide then _xhHide:SetBoolValue(true) end
if _xhT    then _xhT:SetBoolValue(true)    end
if _xhB    then _xhB:SetBoolValue(true)    end
if _xhL    then _xhL:SetBoolValue(true)    end
if _xhR    then _xhR:SetBoolValue(true)    end

local xhairLenF = FeatureMgr.AddFeature(HASH_XHAIR_LEN, "Arm Length", eFeatureType.List, "Length of each arm.", function(f) _xhairLen = f:GetListIndex() end)
if xhairLenF then xhairLenF:SetList({"XS","S","M","L","XL"}) ; xhairLenF:SetListIndex(2) end

local xhairGapF = FeatureMgr.AddFeature(HASH_XHAIR_GAP, "Arm Gap", eFeatureType.List, "Gap between center and arms.", function(f) _xhairGap = f:GetListIndex() end)
if xhairGapF then xhairGapF:SetList({"None","S","M","L"}) ; xhairGapF:SetListIndex(1) end

local xhairSizeF = FeatureMgr.AddFeature(HASH_XHAIR_SIZE, "Thickness", eFeatureType.List, "Arm thickness.", function(f) _xhairSize = f:GetListIndex() end)
if xhairSizeF then xhairSizeF:SetList({"Thin","Normal","Thick"}) ; xhairSizeF:SetListIndex(1) end

local xhairColorF = FeatureMgr.AddFeature(HASH_XHAIR_COLOR, "Color", eFeatureType.List, "Crosshair color.", function(f)
    local colors = {{0,255,0},{255,255,255},{255,0,0},{0,255,255},{255,255,0},{255,165,0}}
    local c = colors[f:GetListIndex()+1] or colors[1]
    _xhairR, _xhairG, _xhairB = c[1], c[2], c[3]
end)
if xhairColorF then xhairColorF:SetList({"Green","White","Red","Cyan","Yellow","Orange"}) end

FeatureMgr.AddFeature(HASH_XHAIR_USE_IMAGE, "Use Custom Image", eFeatureType.Toggle, "Use a PNG file from the discord_rpc folder as the crosshair. Place crosshair.png in the folder.", function(f)
    _xhairUseImage = f:IsToggled()
    xhairApplyImageMode()
end)
FeatureMgr.AddFeature(HASH_XHAIR_RELOAD_IMG, "Reload Image", eFeatureType.Button, "Reloads the PNG from the discord_rpc folder.", function()
    _xhairTexId = nil
    xhairLoadImage()
    if _xhairUseImage then xhairApplyImageMode() end
end)

local HASH_DBG_SCRIPTS  = Utils.Joaat("discord_rpc_dbg_scripts")
FeatureMgr.AddFeature(HASH_DBG_SCRIPTS, "Log Mission Flags", eFeatureType.Button, "Logs mission flag + all running scripts to the Cherax console.", function()
    rpcLog("MissionFlag=" .. tostring(nativeBool(0xA33CDCCDA663159E)))
    pcall(Natives.InvokeVoid, 0xDADFADA5A20143A8)
    local found = {}
    while true do
        local ok, tid = pcall(Natives.InvokeInt, 0x30B4FA1C82DD4B9F)
        if not ok or not tid or tid == 0 then break end
        local ok2, sname = pcall(Natives.InvokeString, 0x05A42BA9FC8DA96B, tid)
        if ok2 and sname then found[#found+1] = sname end
    end
    rpcLog("Scripts (" .. #found .. "): " .. table.concat(found, ", "))
end)



local dbgRpc      = FeatureMgr.AddFeature(HASH_DBG_RPC,      "RPC: —",          eFeatureType.Button, "Current RPC connection state.", function() end)
local dbgUser     = FeatureMgr.AddFeature(HASH_DBG_USER,     "Username: —",      eFeatureType.Button, "Discord username.", function() end)
local dbgDispName = FeatureMgr.AddFeature(HASH_DBG_DISPNAME, "Display Name: —",  eFeatureType.Button, "Discord display name.", function() end)
local dbgDisc     = FeatureMgr.AddFeature(HASH_DBG_DISC,     "Discriminator: —", eFeatureType.Button, "Discord discriminator tag.", function() end)
local dbgAvatar   = FeatureMgr.AddFeature(HASH_DBG_AVATAR,   "Avatar Hash: —",   eFeatureType.Button, "Discord avatar asset hash.", function() end)
local dbgPipe     = FeatureMgr.AddFeature(HASH_DBG_PIPE,     "Pipe: —",          eFeatureType.Button, "Active Discord IPC pipe index.", function() end)
local dbgSes      = FeatureMgr.AddFeature(HASH_DBG_SES,      "Session: —",       eFeatureType.Button, "Current detected session state.", function() end)
local dbgDet      = FeatureMgr.AddFeature(HASH_DBG_DET,      "Details: —",       eFeatureType.Button, "Current presence details string.", function() end)

local _cr = {
    { "Duchess",     1.0, 0.75, 0.1, 1.0, "-- made the script I was inspired by" },
    { "nui",         0.4, 0.8,  1.0, 1.0, "-- good friend, helped me understand modding and ways around it" },
    { "Cherax Devs", 0.7, 0.3,  1.0, 1.0, "-- made cherax" },
    { "Kitty",       1.0, 0.5,  0.8, 1.0, "-- that's me :3" },
}

ClickGUI.AddTab("Discord RPC", function()
    if rpc.active and (os.clock() - rpc.lastLoopTick) > 4 then
        rpc.lastLoopTick = os.clock()
        local stateStr = select(1, getSessionState())
        local _, ok = pcall(setActivity, buildActivity(stateStr, getCurrentDetails()))
        if not ok then
            pcall(reconnectPipe)
            pcall(setActivity, buildActivity(stateStr, getCurrentDetails()))
        end
        _startRpcLoop()
    end

    if _clPending and not _clOpened then
        ImGui.OpenPopup("Changelog")
        _clOpened = true
    end
    ImGui.SetNextWindowSize(420, 300)
    if ImGui.BeginPopupModal("Changelog") then
        ImGui.TextColored(0.59, 0.31, 0.87, 1.0, "discord_rpc.lua  -  What's New")
        ImGui.Spacing()
        ImGui.Text(CHANGELOG)
        ImGui.Spacing()
        ImGui.Text("Bug reports: DM ")
        ImGui.SameLine()
        ImGui.TextColored(0.59, 0.31, 0.87, 1.0, "_nightkitty_")
        ImGui.Text("on Discord.")
        ImGui.Spacing()
        if ImGui.Button("Got it!") then
            ImGui.CloseCurrentPopup()
            _clPending = false
            saveConfig()
        end
        ImGui.EndPopup()
    end

    local label
    if rpc.active then
        label = ("Active  |  @%s  (%s)"):format(
            tostring(discordUser.name or "?"),
            tostring(discordUser.id or "?")
        )
    elseif discordUser.id ~= nil then
        label = ("Error: %s"):format(tostring(discordUser.id))
    else
        label = "Inactive — toggle on to connect"
    end
    if infoFeature then infoFeature:SetName(label) end

    if ImGui.BeginTabBar("discord_rpc_tabs") then
        if ImGui.BeginTabItem("Settings") then
            currentMenuPage = "Discord RPC > Settings"
            ClickGUI.RenderFeature(HASH_TOGGLE)
            ClickGUI.RenderFeature(HASH_STATUS)
            ImGui.Spacing()
            ClickGUI.RenderFeature(HASH_FORCE_UPDATE)
            ClickGUI.RenderFeature(HASH_SAVE_CFG)
            ImGui.Spacing()
            ImGui.PushID("rpc_type")
            ClickGUI.RenderFeature(HASH_TYPE)
            ImGui.PopID()
            ImGui.Spacing()
            ClickGUI.RenderFeature(HASH_ACT_MODE)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Buttons") then
            currentMenuPage = "Discord RPC > Buttons"
            ClickGUI.RenderFeature(HASH_BTN1_EN)
            ClickGUI.RenderFeature(HASH_BTN1_LABEL)
            ClickGUI.RenderFeature(HASH_BTN1_URL)
            ClickGUI.RenderFeature(HASH_BTN2_EN)
            ClickGUI.RenderFeature(HASH_BTN2_LABEL)
            ClickGUI.RenderFeature(HASH_BTN2_URL)
            ClickGUI.RenderFeature(HASH_BTN_APPLY)
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Cool Debug Stuff") then
            currentMenuPage = "Discord RPC > Debug"
            if ImGui.BeginTabBar("discord_rpc_dbg_tabs") then

                if ImGui.BeginTabItem("Sound") then
                    currentMenuPage = "Discord RPC > Sound"
                    ClickGUI.RenderFeature(HASH_SND_PLAY)
                    ClickGUI.RenderFeature(HASH_SND_STOP)
                    ClickGUI.RenderFeature(HASH_SND_LOOP)
                    ImGui.EndTabItem()
                end

                if ImGui.BeginTabItem("RPC Info") then
                    currentMenuPage = "Discord RPC > Info"
                    do
                        local ed = tostring(Cherax.GetEdition() or "")
                        if ed:find("BE") then
                            ImGui.TextColored(1.0, 0.75, 0.1, 1.0, "Edition: Prime  (" .. ed .. ")")
                        end
                    end
                    if dbgRpc      then dbgRpc:SetName(     "RPC: "           .. (rpc.active and "Active" or "Inactive")) end
                    if dbgUser     then dbgUser:SetName(     "Username: @"     .. tostring(discordUser.name or "?")) end
                    if dbgDispName then dbgDispName:SetName( "Display Name: "  .. tostring(discordUser.globalName or "?")) end
                    if dbgDisc     then dbgDisc:SetName(     "Discriminator: " .. tostring(discordUser.discriminator or "?")) end
                    if dbgAvatar   then dbgAvatar:SetName(   "Avatar Hash: "   .. tostring(discordUser.avatar or "none")) end
                    if dbgPipe     then dbgPipe:SetName(     "Pipe: discord-ipc-" .. (rpc.pipeIndex >= 0 and tostring(rpc.pipeIndex) or "?")) end
                    if dbgSes      then dbgSes:SetName(      "Session: "       .. tostring(select(1, getSessionState()))) end
                    if dbgDet      then dbgDet:SetName(      "Details: "       .. getCurrentDetails()) end
                    ClickGUI.RenderFeature(HASH_DBG_RPC)
                    ClickGUI.RenderFeature(HASH_DBG_USER)
                    ClickGUI.RenderFeature(HASH_DBG_DISPNAME)
                    ClickGUI.RenderFeature(HASH_DBG_DISC)
                    ClickGUI.RenderFeature(HASH_DBG_AVATAR)
                    ClickGUI.RenderFeature(HASH_DBG_PIPE)
                    ClickGUI.RenderFeature(HASH_DBG_SES)
                    ClickGUI.RenderFeature(HASH_DBG_DET)
                    ImGui.EndTabItem()
                end

                if ImGui.BeginTabItem("Tools") then
                    currentMenuPage = "Discord RPC > Tools"
                    ClickGUI.RenderFeature(HASH_DBG_SCRIPTS)
                    ImGui.EndTabItem()
                end

                if ImGui.BeginTabItem("Crosshair") then
                    currentMenuPage = "Discord RPC > Crosshair"
                    ClickGUI.RenderFeature(HASH_XHAIR)
                    ClickGUI.RenderFeature(HASH_XHAIR_ONLY_AIM)
                    ClickGUI.RenderFeature(HASH_XHAIR_HIDE)
                    ClickGUI.RenderFeature(HASH_XHAIR_TOP)
                    ClickGUI.RenderFeature(HASH_XHAIR_BOT)
                    ClickGUI.RenderFeature(HASH_XHAIR_LEFT)
                    ClickGUI.RenderFeature(HASH_XHAIR_RIGHT)
                    ClickGUI.RenderFeature(HASH_XHAIR_DOT)
                    ImGui.PushID("xhair_len")
                    ClickGUI.RenderFeature(HASH_XHAIR_LEN)
                    ImGui.PopID()
                    ImGui.PushID("xhair_gap")
                    ClickGUI.RenderFeature(HASH_XHAIR_GAP)
                    ImGui.PopID()
                    ImGui.PushID("xhair_size")
                    ClickGUI.RenderFeature(HASH_XHAIR_SIZE)
                    ImGui.PopID()
                    ImGui.PushID("xhair_color")
                    ClickGUI.RenderFeature(HASH_XHAIR_COLOR)
                    ImGui.PopID()
                    ImGui.Spacing()
                    ClickGUI.RenderFeature(HASH_XHAIR_USE_IMAGE)
                    ClickGUI.RenderFeature(HASH_XHAIR_RELOAD_IMG)
                    ImGui.EndTabItem()
                end



                ImGui.EndTabBar()
            end
            ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("Credits") then
            currentMenuPage = "Discord RPC > Credits"
            for _, c in ipairs(_cr) do
                ImGui.TextColored(c[2], c[3], c[4], c[5], c[1])
                ImGui.SameLine()
                ImGui.Text(c[6])
                ImGui.Spacing()
            end
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
end)

Script.QueueJob(function()
    local LENS  = {0.004, 0.007, 0.011, 0.016, 0.022}
    local GAPS  = {0,     0.003, 0.006, 0.010}
    local THICK = {0.0006, 0.0010, 0.0016}
    local AR    = 9/16

    local function rect(x, y, w, h)
        pcall(Natives.InvokeVoid, 0x3A618A217E5154F0, x, y, w, h, _xhairR, _xhairG, _xhairB, _xhairA, false)
    end

    while not ShouldUnload() do
        Script.Yield(0)
        if _xhair then
            local ok, pid = pcall(Natives.InvokeInt, 0x4F8644AF03D0E0D6)
            local aiming = true
            if _xhairOnlyAim then
                local ok2, v = pcall(Natives.InvokeBool, 0x2E397FD2ECD37C87, ok and pid or 0)
                aiming = ok2 and v == true
            end
            if _xhairHideOrig and aiming then
                pcall(Natives.InvokeVoid, 0x6806C51AD12B83B8, 14)
            end
            if aiming and not _xhairUseImage then
                local len  = LENS[_xhairLen + 1]  or LENS[3]
                local gap  = GAPS[_xhairGap + 1]  or GAPS[2]
                local t    = THICK[_xhairSize + 1] or THICK[2]
                local tw   = t * AR
                local half = len / 2
                if _xhairLeft  then rect(0.5 - gap*AR - half*AR,  0.5,  len*AR, t) end
                if _xhairRight then rect(0.5 + gap*AR + half*AR,  0.5,  len*AR, t) end
                if _xhairTop   then rect(0.5, 0.5 - gap - half,   tw,   len)    end
                if _xhairBot   then rect(0.5, 0.5 + gap + half,   tw,   len)    end
                if _xhairDot   then rect(0.5, 0.5, tw * 2, t * 2)              end
            end
        end
    end
end)

Script.QueueJob(loadConfig)
