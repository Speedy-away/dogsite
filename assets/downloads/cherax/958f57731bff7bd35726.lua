--todo fix issue with moving menu down to bottom of screen and taking cursor off of menu 
--
NETWORK = {
    NETWORK_IS_HOST=function()return Natives.InvokeBool(0x8DB296B814EDDA07)end;---@return boolean
    NETWORK_GET_AVERAGE_PING=function(player--[[@param player integer]])return Natives.InvokeFloat(0x0E3A041ED6AC2B45,player)end;---@return number
}
local LoadingProgress = 0.0
local IsShuttingDown = false     -- true = shutdown, false = startup
local IsAnimating = false        
local LoadingHandler = nil
local isCompassRendering = false  
local IsPlayerSectionRendering = false 
local Mapzoom
local arrowScale 
local OSDHandler = nil
PlayerNameColorFeat        = FeatureMgr.AddFeature(Utils.Joaat("PlayerNameColorFeat"),        "Player Name Color",        eFeatureType.InputColor4, "")
PlayerHPFillColorFeat      = FeatureMgr.AddFeature(Utils.Joaat("PlayerHPFillColorFeat"),      "Health Bar Fill Color",    eFeatureType.InputColor4, "")

FeatureMgr.AddFeature(Utils.Joaat("Elfish-Beaker's HUD-Show Players"), "Show Players", eFeatureType.Toggle, ""):SetBoolValue(true)
FeatureMgr.AddFeature(Utils.Joaat("DrawCompass"), "Draw Compass", eFeatureType.Toggle, "")

FeatureMgr.AddFeature(Utils.Joaat("DrawCustomCrossHair"), "Custom Crosshair", eFeatureType.Toggle, "Enables the custom crosshair.")

crosshair_color = FeatureMgr.AddFeature(Utils.Joaat("CrosshairColor"), "Crosshair Color", eFeatureType.InputColor4,
    "Controls the color of the custom crosshair."):SetColor(255, 0, 0, 255)


PlayerNameColorFeat:SetColor(255, 255, 255, 255)
PlayerHPFillColorFeat:SetColor(255, 0, 70, 255)

local isDebugMode = false
if Cherax.GetUID() == 156098 then 
    isDebugMode = true
end

if isDebugMode then
    FeatureMgr.AddFeature(Utils.Joaat("Show Debug stuff"), "Show Debug Stuffs", eFeatureType.Toggle, "")
end

local detectedPlayers = {}
local numofmodders = 0
local ModderArray = {}         
local function onPlayerLeave(playerId)
    if type(playerId) ~= "number" or playerId < 0 then
        return
    end
    ModderArray[playerId] = nil
    local NetGamePlayer = Players.GetById(playerId)
    if NetGamePlayer then
        local GamerInfo = NetGamePlayer:GetGamerInfo() or {}
        local rid = GamerInfo.RockstarId or "Invalid"
        if detectedPlayers[rid] then
            if ModderArray[playerId] == true then 
                numofmodders = numofmodders - 1
                ModderArray[playerId] = nil
            end
            detectedPlayers[rid] = nil
        end
    end
end

FM_SCORE_DATA = {   
    iXp = 1,
    iCash = 3,
    iGlobalXP = 5,
    iRank = 6,
    iRacesWon = 15,
    iRacesLost = 16,
    iRaceTop3 = 17,
    iDMWon = 20,
    iDMLost = 21,
    iTDMWon = 22,
    iTDMLost = 23,
    iFired = 24,
    iHit = 25,
    iKills = 28,
    iDeaths = 29,
    iSexActs = 55,
    iEarnings = 56,
}

function StructInstance(struct, base)
    local temp = {}

    for k, v in pairs(struct) do
        if type(v) == "number" then
            temp[k] = v + base
        elseif type(v) == "table" then
            temp[k] = StructInstance(v, base)
        end
    end

    return temp
end

function StructArray(struct, base, size, count)
    local temp = {}
    local tempBase = base + 1

    for i = 0, count - 1 do
        temp[i] = StructInstance(struct, tempBase)
        tempBase = tempBase + size
    end

    return temp
end

GlobalplayerBroadcastDataFM = {
    scoreData = StructInstance(FM_SCORE_DATA, 198)
}

GlobalplayerBD_FM = StructArray(GlobalplayerBroadcastDataFM, 1845274, 877, 32)
local PlayerGlobalData = {}
local function detectPlayers()
    for playerId = 0, 31 do
        if playerId ~= GTA.GetLocalPlayerId() then
            local netPlayer = Players.GetById(playerId)
            if netPlayer then
                local info = netPlayer:GetGamerInfo()
                local rid = info and info.RockstarId
                if detectedPlayers[rid] ~= nil and detectedPlayers[rid].notified then 
                    goto continue 
                end
                if not rid then goto continue end

                local detections = ModderDB.GetModderDetections(rid)
                if type(detections) == "table" and #detections > 0 then

                    local reasons = {}
                    for _, d in ipairs(detections) do
                        if type(d) == "string" and d ~= "" then
                            table.insert(reasons, d)
                        end
                    end

                    if #reasons > 0 then 
                        local Playername = netPlayer:GetName() or "Unknown"
                        local tags = Players.GetTags(playerId) or ""
                        local hasFTag = tags:find("[F]") ~= nil
                        numofmodders = numofmodders + 1
                        local scoreData = GlobalplayerBD_FM[playerId].scoreData
                        for name, _ in pairs(FM_SCORE_DATA) do
                            -- local globalStat = scoreData[name]
                            -- local globalValue = ScriptGlobal.GetInt(globalStat)
                            -- PlayerGlobalData.name = {
                            --     globlaName = name,
                            --     ScriptGobalValue = globalValue
                            -- }
                            
                            detectedPlayers[rid] = {
                                Id = playerId,
                                name = hasFTag and ("[F] "..Playername) or Playername,
                                reason = table.concat(reasons, ", "),
                                hasFTag = hasFTag,
                                rid = rid,
                                -- PlayerData = PlayerGlobalData.name,
                                notified = detectedPlayers[rid] and detectedPlayers[rid].notified or false
                            }
                        end
 
                        ModderArray[playerId] = true

                        detectedPlayers[rid].notified = true
                    end
                end
            end
        end
        ::continue::
    end
end

local function clearDetectedPlayers()
    detectedPlayers = {}
    ModderArray = {}
end

EventMgr.RegisterHandler(eLuaEvent.ON_SESSION_CHANGE, clearDetectedPlayers)
EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_LEFT, function(playerId)
    if playerId == GTA.GetLocalPlayerId() then
        clearDetectedPlayers()
    else
        onPlayerLeave(playerId)
    end
end)

local SessionCache = {
    playerCount = 0,
    hostId = -1,
    hostName = "Unknown",
    isHost = false,
    lastUpdate = 0
}

local PlayerCache = {}

function manhattanDistance(v1, v2)
	return math.abs(v1.x - v2.x) + math.abs(v1.y - v2.y) + math.abs(v1.z - v2.z)
end

local function UpdatePlayerCache()
    local now = os.clock()


    PlayerCache = {}
    local localPed = Natives.InvokeInt(0xD80958FC74E988A6)
    local localPos = V3.New(Natives.InvokeV3(0x3FEF770D40960D5A, localPed))

    for i = 0, 31 do
        local isModder = ModderArray[i] == true 
        local ped = Natives.InvokeInt(0x43A66C31C68491C0, i)
        if ped and Natives.InvokeBool(0x7239B21A38F536BA, ped) then
            local name = Players.GetName(i) or "Unknown"
            local health = Natives.InvokeInt(0xEEF059FAD016D209, ped)
            local maxHealth = Natives.InvokeInt(0x15D757606D170C3C, ped)
            local armor = Natives.InvokeInt(0x9483AF821605B1D8, ped)
            local ping = Natives.InvokeInt(0x9483AF821605B1D8, i)
            local pos = V3.New(Natives.InvokeV3(0x3FEF770D40960D5A, ped))
            local dist = manhattanDistance(localPos, pos)
            local vehicle = Natives.InvokeBool(0x997ABD671D25CA0B, ped, false) and Natives.InvokeInt(0x9A9112A0FE9A4713, ped, false)
            local vehName = vehicle ~= 0 and Natives.InvokeString(0xB215AAC32D25D019, Natives.InvokeInt(0x9F47B058362C84B5, vehicle)) or "On Foot"

            local isModder = false
            local playerPed = Players.GetById(i)
            if playerPed then 
                local gamerInfo = playerPed:GetGamerInfo()
                if gamerInfo then
                    local rid = gamerInfo.RockstarId
                    if rid and detectedPlayers[rid] then
                        isModder = true
                    end
                end
            end

            if Natives.InvokeInt(0xC7B4D79B01FA7A5C) == i then CurrnetHost = i end
            HostName = Players.GetName(CurrnetHost)    
                
            PlayerCache[#PlayerCache + 1] = {
                id = i,
                name = name,
                health = health,
                maxHealth = maxHealth,
                armor = armor,
                pos = pos,
                ping = ping or 0,
                distance = dist,
                vehicle = vehName,
                isHost = (SessionCache.hostId == i),
                isModder = isModder,
                isLocal = (i == GTA.GetLocalPlayerId())
            }
        end
    end

    table.sort(PlayerCache, function(a, b)
        if a.isHost then return true end
        if b.isHost then return false end
        if a.isModder and not b.isModder then return true end
        if b.isModder and not a.isModder then return false end
        return a.ping < b.ping
    end)
end

Script.RegisterLooped(function()
    UpdatePlayerCache()
    detectPlayers()
end)

local reason

local function ShowPlayerTooltip(x, y, data, modder)
    modder = modder or false
    local mouse = V2.New(ImGui.GetMousePos())
    local sx, sy = mouse.x + 15, mouse.y + 15
    
    local scale = ImGui.GetFontSize() / 16
    local pad = 12 * scale

    local title = modder and "Detections" or "Player Info"
    local reasonText = modder and (data.reason or "No reason") or ""

    local ridText = "RID: " .. tostring(data.rid or "Unknown")
    local nameText = "Name: " .. (data.name or "Unknown")

    local playerDataText = ""
    -- if data.PlayerData then
    --     for statName, statInfo in pairs(data.PlayerData) do
    --         local val = statInfo.ScriptGobalValue or 0
    --         playerDataText = playerDataText .. string.format("%s: %d\n", statName, val)
    --     end
    -- end

    local lines = {reasonText, playerDataText}
    local maxWidth = 360 * scale
    local function countTextHeight(txt)
        local h = 0
        for line in txt:gmatch("[^\n]+") do h = h + ImGui.GetFontSize() end
        return h
    end

    local reasonH = countTextHeight(table.concat(lines, "\n"))
    local titleH = ImGui.GetFontSize()
    local ridH = ImGui.GetFontSize()
    local nameH = ImGui.GetFontSize()

    local w = maxWidth + pad * 2
    local h = pad + titleH + 4*scale + reasonH + 14*scale + nameH + ridH + pad

    ImGui.AddRectFilled(sx, sy, sx + w, sy + h, 30, 30, 30, 220)
    ImGui.AddRect(sx, sy, sx + w, sy + h, 255, 40, 80, 255, 0, 0, 3)

    ImGui.AddText(sx + pad, sy + pad, title, 255, 200, 200, 255)

    local titleBottom = sy + pad + titleH + 4*scale
    ImGui.AddLine(sx + pad, titleBottom, sx + w - pad, titleBottom, 255, 40, 60, 180)

    local textY = titleBottom + 10*scale
    ImGui.AddText(sx + pad, textY, reasonText, 230, 190, 200, 255)
    textY = textY + ImGui.GetFontSize() + 2

    for line in playerDataText:gmatch("[^\n]+") do
        ImGui.AddText(sx + pad, textY, line, 180, 180, 255, 255)
        textY = textY + ImGui.GetFontSize()
    end

    local ridY = sy + h - pad - ridH
    ImGui.AddText(sx + pad, ridY, ridText, 160, 80, 90, 255)
    local nameY = ridY - nameH - 2
    ImGui.AddText(sx + pad, nameY, nameText, 200, 200, 200, 255)
end


FeatureMgr.AddFeature(Utils.Joaat("MapZoom"), "Map Zoom", eFeatureType.SliderFloat, ""):SetMinValue(0.015):SetMaxValue(0.703):SetValue(0.042):SetStepSize(0.01)

FeatureMgr.AddFeature(Utils.Joaat("ArrowScale"), "Arrow Scale", eFeatureType.SliderFloat, ""):SetMinValue(0.5):SetMaxValue(2.0):SetValue(1.0):SetStepSize(0.1)


local texturePath = FileMgr.GetMenuRootPath() .. "\\Lua\\CyberPilot\\radar.png"
local compassPath = FileMgr.GetMenuRootPath() .. "\\Lua\\CyberPilot\\compass.png"
local rootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\CyberPilot"
if not FileMgr.DoesFileExist(rootPath) then
    FileMgr.CreateDir(rootPath)
end

function DownloadAndSaveImageFiles()
    Script.QueueJob(function()
        local c = Curl.Easy()
        c:Setopt(eCurlOption.CURLOPT_URL, "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/compass.png")
        c:Perform()
        while not c:GetFinished() and not ShouldUnload() do 
            Script.Yield()
        end
        
        local CurlCode, imageData = c:GetResponse()

        if imageData ~= nil or imageData ~= "" then 
            local file = io.open(compassPath, "wb")
            if not file then
                Logger.LogError("Failed to open file for writing: " .. compassPath)
                return
            end
            file:write(imageData)
            file:close()
        end
        local c2 = Curl.Easy()
        c2:Setopt(eCurlOption.CURLOPT_URL, "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/radar.png")
        c2:Perform()

        while not c2:GetFinished() and not ShouldUnload() do 
            Script.Yield()
        end
        
        local CurlCode, image2Data = c2:GetResponse()

        if image2Data ~= nil or image2Data ~= "" then         
            local file = io.open(texturePath, "wb")
            if not file then
                Logger.LogError("Failed to open file for writing: " .. texturePath)
                return
            end
            file:write(image2Data)
            file:close()
        end
    end)
end
DownloadAndSaveImageFiles()

Script.QueueJob(function()
    while not FileMgr.DoesFileExist(compassPath) or not FileMgr.DoesFileExist(texturePath) and not ShouldUnload() do 
        Script.Yield()
    end
end)
local function fnv1a(str)
    local hash = 0x811C9DC5
    for i = 1, #str do
        hash = hash ~ str:byte(i)
        hash = (hash * 0x01000193) & 0xFFFFFFFF
    end
    return string.format("%08x", hash)
end

local function hash_file_fast(content)
    return fnv1a(content)
end

local CompassHash = hash_file_fast(FileMgr.ReadFileContent(compassPath))
local textureHash = hash_file_fast(FileMgr.ReadFileContent(texturePath))

if CompassHash ~= "c80fabab" then
    FileMgr.DeleteFile(compassPath)
    DownloadAndSaveImageFiles()
end

if textureHash ~= "c80fabab" then 
    FileMgr.DeleteFile(texturePath)
    DownloadAndSaveImageFiles()
end

local compassId = Texture.LoadTexture(compassPath)
local compassTex = Texture.GetTexture(compassId)
local toastImageId = Texture.LoadTexture(texturePath)
local toastTexture = Texture.GetTexture(toastImageId)

local RADAR_MIN_X = -5800.0 -- bottom? 
local RADAR_MAX_X = 6870.0  -- top?
local RADAR_MIN_Y = -4040.0 -- FOR BOTTOM OF MAP? 
local RADAR_MAX_Y = 8375.0 

local function GetCardinalDirection(heading)
    if heading >= 337.5 or heading < 22.5 then
        return "N"
    elseif heading >= 22.5 and heading < 67.5 then
        return "NE"
    elseif heading >= 67.5 and heading < 112.5 then
        return "E"
    elseif heading >= 112.5 and heading < 157.5 then
        return "SE"
    elseif heading >= 157.5 and heading < 202.5 then
        return "S"
    elseif heading >= 202.5 and heading < 247.5 then
        return "SW"
    elseif heading >= 247.5 and heading < 292.5 then
        return "W"
    else
        return "NW"
    end
end

local function WorldToUV(x, y)
    local u = (x - RADAR_MIN_X) / (RADAR_MAX_X - RADAR_MIN_X)
    local v = (y - RADAR_MIN_Y) / (RADAR_MAX_Y - RADAR_MIN_Y)
    v = 1.0 - v
    return u, v
end


local function DrawMinimap()
    local display = V2.New(ImGui.GetDisplaySize())
    local scale = display.y / 1080
    local mapSize = 280 * scale
    local mapX = 50 * scale
    local mapY = display.y - mapSize - 50 * scale
    
    local barWidth = mapSize * 0.5 - 5 * scale 
    local barHeight = 20 * scale
    local barSpacing = 10 * scale
    
    local playerPed = GTA.PointerToHandle(GTA.GetLocalPed())
    local playerPos = V3.New(Natives.InvokeV3(0x3FEF770D40960D5A, playerPed, true))

    ImGui.AddRectFilled(mapX, mapY, mapX + mapSize, mapY + mapSize, 0, 0, 0, 220)
    ImGui.AddRect(mapX, mapY, mapX + mapSize, mapY + mapSize, 255, 0, 120, 255, 0, 0, 3 * scale)
    
    if toastTexture then 
        local currentTex = toastTexture:GetCurrent()  
        if currentTex then 
            local pU, pV = WorldToUV(playerPos.x, playerPos.y)
            Mapzoom = FeatureMgr.GetFeature(Utils.Joaat("MapZoom")):GetFloatValue()
            local u0 = pU - Mapzoom
            local v0 = pV - Mapzoom
            local u1 = pU + Mapzoom
            local v1 = pV + Mapzoom
            
            u0 = math.max(0, math.min(1, u0))
            v0 = math.max(0, math.min(1, v0))
            u1 = math.max(0, math.min(1, u1))
            v1 = math.max(0, math.min(1, v1))
            
            ImGui.AddImage(
                currentTex,
                mapX, mapY,
                mapX + mapSize, mapY + mapSize,
                u0, v0,
                u1, v1
            )

            ImGui.AddText(mapX + mapSize * 0.5 - 6 * scale, mapY + 8 * scale, "N", 255, 255, 0, 220)
            ImGui.AddText(mapX + mapSize - 20 * scale, mapY + mapSize * 0.5 - 8 * scale, "E", 255, 255, 0, 220)
            ImGui.AddText(mapX + mapSize * 0.5 - 6 * scale, mapY + mapSize - 20 * scale, "S", 255, 255, 0, 220)
            ImGui.AddText(mapX + 8 * scale, mapY + mapSize * 0.5 - 8 * scale, "W", 255, 255, 0, 220)
            
            local heading = Natives.InvokeFloat(0xE83D4F9BA2A38914, playerPed)
            local compassHeading = (360 - heading) % 360
            local cardinal = GetCardinalDirection(compassHeading)
            
            ImGui.AddRectFilled(
                mapX + mapSize * 0.5 - 40 * scale, mapY + 2 * scale,
                mapX + mapSize * 0.5 + 40 * scale, mapY + 25 * scale,
                0, 0, 0, 180
            )

            ImGui.AddRect(
                mapX + mapSize * 0.5 - 40 * scale, mapY + 2 * scale,
                mapX + mapSize * 0.5 + 40 * scale, mapY + 25 * scale,
                255, 255, 0, 200, 0, 0, 1 * scale
            )

            ImGui.AddText(
                mapX + mapSize * 0.5 - 35 * scale, mapY + 5 * scale,
                string.format("%s %.0f°", cardinal, compassHeading),
                255, 255, 255, 255
            )

            local rad = math.rad(-heading)
            
            local localU = (pU - u0) / (u1 - u0)
            local localV = (pV - v0) / (v1 - v0)

            local screenX = mapX + localU * mapSize
            local screenY = mapY + localV * mapSize

            arrowScale = FeatureMgr.GetFeature(Utils.Joaat("ArrowScale")):GetFloatValue()
            local baseArrowSize = 10 * scale  
            local zoomFactor = math.min(2.0, 0.1 / Mapzoom) 
            local arrowSize = baseArrowSize * arrowScale * zoomFactor
            
            local ax = screenX + math.sin(rad) * arrowSize
            local ay = screenY - math.cos(rad) * arrowSize  
            local bx = screenX + math.sin(rad + 2.0) * arrowSize * 0.4  
            local by = screenY - math.cos(rad + 2.0) * arrowSize * 0.4
            local cx = screenX + math.sin(rad - 2.0) * arrowSize * 0.4
            local cy = screenY - math.cos(rad - 2.0) * arrowSize * 0.4

            ImGui.AddTriangleFilled(ax, ay, bx, by, cx, cy, 255, 255, 255, 255)  
            ImGui.AddCircleFilled(screenX, screenY, 1.5 * scale, 255, 255, 255, 255, 8)

            for _, p in ipairs(PlayerCache) do
                local otherU, otherV = WorldToUV(p.pos.x, p.pos.y)
                local localU = (otherU - u0) / (u1 - u0)
                local localV = (otherV - v0) / (v1 - v0)
                
                if localU >= 0 and localU <= 1 and localV >= 0 and localV <= 1 then
                    local px = mapX + localU * mapSize
                    local py = mapY + localV * mapSize
                    
                    if px >= mapX and px <= mapX + mapSize and py >= mapY and py <= mapY + mapSize then
                        local r,g,b = 255,255,255
                        if p.isModder then r,g,b = 255,40,80 end
                        if p.isHost   then r,g,b = 255,200,0 end
                        
                        ImGui.AddCircleFilled(px, py, 3 * scale, r, g, b, 255, 12)
                    end
                end
            end
        else 
            Logger.LogInfo("CurrentTex error?")
        end
    else
        Logger.LogInfo("ToastTexture error")
        GUI.AddToast("HUD Error", "Failed to load radar texture. please reload script", 5000)
    end
    
    local you
    for _, p in ipairs(PlayerCache) do 
        if p.isLocal then 
            you = p 
            break 
        end 
    end
    
    if you then
        

        ImGui.InvisibleButton(you.name .. "DEBUG fps :", 300, 300)

        if isDebugMode and FeatureMgr.IsFeatureEnabled(Utils.Joaat("Show Debug stuff")) then
            local IsPlayerSectionRenderingCheck = IsPlayerSectionRendering and "True" or "False"
            local IsCompassOnCheck = isCompassRendering and "True" or "False"
            ImGui.AddText(mapX + (mapSize + 390 * scale) / 2, mapY - 10 * scale - 10, "DEBUG fps : "..tostring(ImGui.GetFrameRate()), 255, 40, 80, 255)
            ImGui.AddText(mapX + (mapSize + 390 * scale) / 2, mapY - 25 * scale - 10, "DEBUG isCompassRendering : ".. IsCompassOnCheck, 255, 40, 80, 255)
            ImGui.AddText(mapX + (mapSize + 390 * scale) / 2, mapY - 40 * scale - 10, "DEBUG IsPlayerSectionRendering : ".. IsPlayerSectionRenderingCheck, 255, 40, 80, 255)
            ImGui.AddText(mapX + (mapSize + 390 * scale) / 2, mapY - 55 * scale - 10, "DEBUG MapZoom : ".. tostring(Mapzoom), 255, 40, 80, 255)
            ImGui.AddText(mapX + (mapSize + 390 * scale) / 2, mapY - 70 * scale - 10, "DEBUG ArrowScale : ".. tostring(arrowScale), 255, 40, 80, 255)


        end
        
        ImGui.AddText(mapX + (mapSize - 120 * scale) / 2, mapY - 25 * scale - 10, you.name, 255, 40, 80, 255)

        local barsStartY = mapY + mapSize + 15 * scale
        
        local healthBarX = mapX
        local healthBarY = barsStartY
        
        ImGui.AddRectFilled(healthBarX, healthBarY, healthBarX + barWidth, healthBarY + barHeight, 45, 0, 0, 220)
        ImGui.AddRect(healthBarX, healthBarY, healthBarX + barWidth, healthBarY + barHeight, 255, 0, 50, 255, 0, 0, 2)
        
        local healthWidth = barWidth * (you.health / you.maxHealth)
        ImGui.AddRectFilled(healthBarX, healthBarY, healthBarX + healthWidth, healthBarY + barHeight, 255, 0, 70, 255)
        
        ImGui.AddText(healthBarX, healthBarY - 15 * scale, "Health", 255, 90, 110, 255)
        ImGui.AddText(healthBarX + barWidth - 40 * scale, healthBarY + 3 * scale, string.format("%d/%d", you.health, you.maxHealth), 255, 255, 255, 255)
        
        local armorBarX = mapX + barWidth + barSpacing
        local armorBarY = barsStartY
        
        ImGui.AddRectFilled(armorBarX, armorBarY, armorBarX + barWidth, armorBarY + barHeight, 35, 0, 0, 220)
        ImGui.AddRect(armorBarX, armorBarY, armorBarX + barWidth, armorBarY + barHeight, 220, 0, 60, 255, 0, 0, 2)
        
        local armorWidth = barWidth * (you.armor / 100)
        ImGui.AddRectFilled(armorBarX, armorBarY, armorBarX + armorWidth, armorBarY + barHeight, 220, 0, 80, 255)
        
        ImGui.AddText(armorBarX, armorBarY - 15 * scale, "Armor", 220, 90, 110, 255)
        ImGui.AddText(armorBarX + barWidth - 25 * scale, armorBarY + 3 * scale, 
            string.format("%d%%", you.armor), 255, 255, 255, 255)
    end
end

-- local function DrawCompass()
--     if not FeatureMgr.IsFeatureEnabled(Utils.Joaat("DrawCompass")) then return end
--     local scrW, scrH = ImGui.GetDisplaySize()
--     local scale = scrH / 1080

--     local mapSize = 280 * scale
--     local mapX = 50 * scale
--     local mapY = scrH - mapSize - 50 * scale

--     local radius = 62 * scale
--     local centerX = mapX + mapSize * 0.5
--     local centerY = mapY - 88 * scale - (30 * scale)  

--     local ped = Natives.InvokeInt(0xD80958FC74E988A6)
--     local heading = Natives.InvokeFloat(0xE83D4F9BA2A38914, ped)  
--     heading = heading % 360

--     local steps = 300
--     local twoPi = math.pi * 2

--     for i = 0, steps do
--         local a1 = i * twoPi / steps
--         local a2 = (i + 1) * twoPi / steps
--         local x1 = centerX + math.sin(a1) * radius
--         local y1 = centerY - math.cos(a1) * radius
--         local x2 = centerX + math.sin(a2) * radius
--         local y2 = centerY - math.cos(a2) * radius
--         ImGui.AddRectFilled(x1 - 14, y1 - 14, x2 + 14, y2 + 14, 8, 8, 12, 240, 0, 0)
--     end

--     for r = radius + 8, radius + 24, 4 do
--         local alpha = math.floor(220 * (1 - (r - radius - 8) / 16))
--         for i = 0, steps do
--             local a = i * twoPi / steps
--             local a2 = (i + 1) * twoPi / steps
--             local x1 = centerX + math.sin(a) * r
--             local y1 = centerY - math.cos(a) * r
--             local x2 = centerX + math.sin(a2) * r
--             local y2 = centerY - math.cos(a2) * r
--             ImGui.AddLine(x1, y1, x2, y2, 255, 0, 0, alpha, 6 * scale)
--         end
--     end

--     for i = 0, steps do
--         local a1 = i * twoPi / steps
--         local a2 = (i + 1) * twoPi / steps
--         local x1 = centerX + math.sin(a1) * radius
--         local y1 = centerY - math.cos(a1) * radius
--         local x2 = centerX + math.sin(a2) * radius
--         local y2 = centerY - math.cos(a2) * radius
--         ImGui.AddLine(x1, y1, x2, y2, 255, 40, 40, 255, 5 * scale)
--     end

--     local directions = {
--         {text = "N",   angle = 0},
--         {text = "NE",  angle = 45},
--         {text = "E",   angle = 90},
--         {text = "SE",  angle = 135},
--         {text = "S",   angle = 180},
--         {text = "SW",  angle = 225},
--         {text = "W",   angle = 270},
--         {text = "NW",  angle = 315}
--     }

--     for _, d in ipairs(directions) do
--         local rad = math.rad(d.angle)
--         local dist = radius * 1.32
--         local tx = centerX + math.sin(rad) * dist
--         local ty = centerY - math.cos(rad) * dist

--         local textW = ImGui.CalcTextSize and ImGui.CalcTextSize(d.text) or (#d.text * 8)
--         tx = tx - (textW * 0.24)
--         ty = ty - 15 * scale

--         ImGui.AddText(tx, ty, d.text, 255, 255, 255, 255)
--     end

--     for deg = 0, 345, 15 do
--         local worldAngle = deg - heading
--         local rad = math.rad(worldAngle)

--         local inner = radius * 0.78
--         local outer = radius * 0.96

--         local x1 = centerX + math.sin(rad) * inner
--         local y1 = centerY - math.cos(rad) * inner
--         local x2 = centerX + math.sin(rad) * outer
--         local y2 = centerY - math.cos(rad) * outer

--         local thickness = (deg % 90 == 0) and 6 or 3
--         local alpha = (deg % 90 == 0) and 255 or 180
--         ImGui.AddLine(x1, y1, x2, y2, 255, 120, 120, alpha, thickness * scale)
--     end

--     local arrowRad = math.rad(-heading)  
--     local length = radius * 0.8

--     local tipX = centerX + math.sin(arrowRad) * length
--     local tipY = centerY - math.cos(arrowRad) * length

--     local w1x = centerX + math.sin(arrowRad + 2.7) * length * 0.5
--     local w1y = centerY - math.cos(arrowRad + 2.7) * length * 0.5
--     local w2x = centerX + math.sin(arrowRad - 2.7) * length * 0.5
--     local w2y = centerY - math.cos(arrowRad - 2.7) * length * 0.5

--     ImGui.AddTriangleFilled(tipX, tipY, w1x, w1y, w2x, w2y, 255, 0, 0, 140)
--     ImGui.AddTriangleFilled(tipX, tipY, w1x, w1y, w2x, w2y, 255, 0, 0, 255)
--     ImGui.AddTriangle(tipX, tipY, w1x, w1y, w2x, w2y, 255, 150, 150, 255, 6 * scale)

--     ImGui.AddCircleFilled(centerX, centerY, 9 * scale, 0, 0, 0, 255, 16)
--     ImGui.AddCircle(centerX, centerY, 9 * scale, 255, 0, 0, 255)
-- end

local function DrawCompass()
    if not FeatureMgr.IsFeatureEnabled(Utils.Joaat("DrawCompass")) then 
        isCompassRendering = false
        return 
    end
    if not compassTex then return end
    isCompassRendering = true 
    local scrW, scrH = ImGui.GetDisplaySize()
    local scale = scrH / 1080

    local tex = compassTex:GetCurrent()
    if not tex then return end

    local mapSize = 280 * scale
    local mapX = 50 * scale
    local mapY = scrH - mapSize - 50 * scale

    local compassSize = 250 * scale
    local compassCenterX = mapX + mapSize * 0.5
    local compassCenterY = mapY - (compassSize * 0.57)

    ImGui.AddImageRotated(
        tex,
        compassCenterX,
        compassCenterY,
        compassSize,
        compassSize - 40,
        0,
        255
    )

    local ped = Natives.InvokeInt(0xD80958FC74E988A6)
    local heading = (Natives.InvokeFloat(0xE83D4F9BA2A38914, ped) or 0) % 360
    local rad = -math.rad(heading)

    local tipDist     = compassSize * 0.20
    local backDist    = compassSize * 0.06
    local arrowWidth  = compassSize * 0.06

    local sinA, cosA = math.sin(rad), math.cos(rad)

    local tipX = compassCenterX + sinA * tipDist
    local tipY = compassCenterY - cosA * tipDist

    local backX = compassCenterX - sinA * backDist
    local backY = compassCenterY + cosA * backDist

    local perpX = math.sin(rad + math.pi * 0.5)
    local perpY = -math.cos(rad + math.pi * 0.5)
    local hw = arrowWidth * 0.5

    local b1x = backX + perpX * hw
    local b1y = backY + perpY * hw
    local b2x = backX - perpX * hw
    local b2y = backY - perpY * hw

    ImGui.AddTriangleFilled(tipX, tipY, b1x, b1y, b2x, b2y, 255, 20, 20, 180)
    ImGui.AddTriangleFilled(tipX, tipY, b1x, b1y, b2x, b2y, 255, 50, 50, 255)
end


FeatureMgr.AddFeature(Utils.Joaat("GetPlayerPos"), "Get player pos test", eFeatureType.Button, "", function()
    local playerPed = Natives.InvokeInt(0xD80958FC74E988A6)
    local playerPos = V3.New(Natives.InvokeV3(0x3FEF770D40960D5A, playerPed, true))
    Logger.LogInfo(string.format("playerPos.x = %s, playerPos.y = %s, playerPos.z = %s", playerPos.x, playerPos.y, playerPos.z))
end)
local function ShowLoadingScreen()
    if not IsAnimating then return end

    local DisplaySize = V2.New(ImGui.GetDisplaySize())
    local scale = DisplaySize.y / 1080

    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 0, 0)

    local flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoMove |
                  ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoInputs | ImGuiWindowFlags.NoBackground |
                  ImGuiWindowFlags.NoBringToFrontOnFocus

    ImGui.SetNextWindowPos(0, 0)
    ImGui.SetNextWindowSize(DisplaySize.x, DisplaySize.y)

    if not ImGui.Begin("##HUD_LOADING_SCREEN", true, flags) then
        ImGui.End()
        ImGui.PopStyleVar()
        ImGui.PopStyleColor()
        return
    end

    for i = 0, DisplaySize.y, 6 do
        ImGui.AddLine(0, i, DisplaySize.x, i, 20, 0, 40, 50)
    end

    local boxW, boxH = 600 * scale, 200 * scale
    local boxX, boxY = (DisplaySize.x - boxW) / 2, (DisplaySize.y - boxH) / 2

    ImGui.AddRectFilled(boxX, boxY, boxX + boxW, boxY + boxH, 10, 10, 10, 220)

    local r, g, b = IsShuttingDown and 255 or 255, IsShuttingDown and 0 or 0, IsShuttingDown and 80 or 80
    ImGui.AddRect(boxX, boxY, boxX + boxW, boxY + boxH, r, g, b, 255, 0, 0, 4)

    local title = IsShuttingDown and "CYBERPILOT HUD SHUTTING DOWN" or "CYBERPILOT HUD INITIALIZING"
    ImGui.AddText(boxX + 24 * scale, boxY + 24 * scale, title, r, g + 50, b, 255)

    local barW, barH = boxW - 48 * scale, 24 * scale
    local barX, barY = boxX + 24 * scale, boxY + boxH - 60 * scale

    local glow = math.floor(math.abs(math.sin(os.clock() * 6)) * 35)
    ImGui.AddRectFilled(barX, barY, barX + barW, barY + barH, 30 + glow, 0, 50 + glow, 200)
    ImGui.AddRect(barX, barY, barX + barW, barY + barH, r, g + 70, b + 70, 255, 0, 0, 2)

    if IsShuttingDown then
        LoadingProgress = LoadingProgress - 2.2
        if LoadingProgress < 0 then LoadingProgress = 0 end
    else
        LoadingProgress = LoadingProgress + 1.8
        if LoadingProgress > 100 then LoadingProgress = 100 end
    end

    local filledW = barW * (LoadingProgress / 100)
    ImGui.AddRectFilled(barX, barY, barX + filledW, barY + barH, r, g, b, 255)

    local pct = IsShuttingDown and ("SHUTTING DOWN %02d%%"):format(math.floor(LoadingProgress))
                               or ("LOADING %02d%%"):format(math.floor(LoadingProgress))
    ImGui.AddText(barX + barW/2 - 50*scale, barY - 28*scale, pct, 255, 120, 160, 255)

    local bottom = IsShuttingDown and "Terminating neural link..." or "Initializing modules..."
    ImGui.AddText(boxX + 24*scale, boxY + boxH - 28*scale, bottom, math.random(140,255), 60, 100, 255)

    ImGui.End()
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(1)

    if (IsShuttingDown and LoadingProgress <= 0) or (not IsShuttingDown and LoadingProgress >= 100) then
        IsAnimating = false

        if LoadingHandler then
            EventMgr.RemoveHandler(LoadingHandler)
            LoadingHandler = nil
        end

        if IsShuttingDown then
            if OSDHandler then
                EventMgr.RemoveHandler(OSDHandler)
                OSDHandler = nil
            end
        else
            if not OSDHandler then
                OSDHandler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, ShowOnScreenDisplay)
            end
        end
    end
end


local function ShowOnScreenDisplay()
    if IsAnimating then return end 
    local DisplaySize = V2.New(ImGui.GetDisplaySize())
    local scrW, scrH = DisplaySize.x, DisplaySize.y
    local scale = scrH / 1080
    
   if FeatureMgr.IsFeatureEnabled(Utils.Joaat("DrawCustomCrossHair")) then
        local r, g, b, a = crosshair_color:GetColor()
        local half_size = 33 / 2
        ImGui.AddLine((scrW / 2) - half_size, scrH / 2, (scrW / 2) + half_size, scrH / 2, r, g, b, a, 2.0)
        ImGui.AddLine(scrW / 2, (scrH / 2) - half_size, scrW / 2, (scrH / 2) + half_size, r, g, b, a, 2.0)
    end


    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0,0,0,0.25)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding,0,0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize,0)

    local flags = 
        ImGuiWindowFlags.NoTitleBar |
        ImGuiWindowFlags.NoResize |
        ImGuiWindowFlags.NoMove |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.NoBringToFrontOnFocus
    

    ImGui.SetNextWindowPos(0,0)
    ImGui.SetNextWindowSize(scrW,scrH)

    if not ImGui.Begin("##CYBERPILOT_HUD", true, flags) then
        ImGui.End()
        ImGui.PopStyleVar(2)
        ImGui.PopStyleColor(1)
        return
    end

    local padX     = 60 * scale / 2
    local padTop   = 18 * scale / 2
    local barH     = 58 * scale
    local blockH   = 96 * scale      
    local barW     = 360 * scale
    local barGap   = 10 * scale

    ImGui.AddRectFilled(0, padTop, scrW, padTop + barH, 0, 0 ,0, 145)
    ImGui.AddRect(0, padTop, scrW, padTop + barH, 255, 0, 40, 220, 0, 0, 3)

    ImGui.AddText(padX, padTop + 16*scale + 4, ("Players: %02d"):format(#PlayerCache), 190, 190, 190, 255)
    ImGui.AddText(scrW * 0.5 - 110*scale - 2 , padTop + 16*scale + 4, ("Modders %0d"):format(numofmodders), 255, 30, 70, 255)
    ImGui.AddText(scrW - barW - padX - 50, padTop + 16*scale + 4, ("Current Host: %s"):format(HostName), 255, 110, 130, 255)

    local modderY = padTop + barH + 34 * scale
    local modX = scrW * 0.5 - 110 * scale

    local index = 0
    for rid, data in pairs(detectedPlayers) do
        local name = data.name or "Unknown"
        local y = modderY + index * (22 * scale)

        ImGui.AddText(modX, y, name, 255, 40, 80, 255)

        ImGui.SetCursorScreenPos(modX, y)
        ImGui.InvisibleButton("modder_" .. rid, 220 * scale, 22 * scale)

        if ImGui.IsItemHovered() then
            ShowPlayerTooltip(modX, y, data, true)
        end

        index = index + 1
    end
    DrawCompass()
    for _, p in ipairs(PlayerCache) do if p.isLocal then you = p break end end
    

    local rx = scrW - barW - padX - 50
    local ry = padTop + barH + 60*scale

    if FeatureMgr.IsFeatureToggled(Utils.Joaat("Elfish-Beaker's HUD-Show Players")) then 
        IsPlayerSectionRendering = true
        ImGui.AddText(rx, ry + 10, "TARGET LOCK", 255, 30, 70, 255)

        local blockH = 38 * scale
        local maxVisible = math.floor((scrH - ry - 80*scale) / blockH)
        local startIdx = math.max(1, #PlayerCache - maxVisible + 1)

        local hpR,hpG,hpB,hpA = PlayerHPFillColorFeat:GetColor()
        local nameR,nameG,nameB,nameA = PlayerNameColorFeat:GetColor()

        for i = startIdx, #PlayerCache do
            local p = PlayerCache[i]
            if p.id == GTA.GetLocalPlayerId() then goto continue end

            local y = ry + 72*scale + (i - startIdx) * blockH
            if y + blockH > scrH - 60*scale then break end

            ImGui.AddText(rx, y, p.name, nameR,nameG,nameB,nameA)
            
            ImGui.SetCursorScreenPos(rx, y)
            ImGui.InvisibleButton("player_btn_"..i, 220*scale, 22*scale)

            -- if ImGui.IsItemHovered() then
            --     for data, _ in pairs(detectedPlayers) do 
            --         ShowPlayerTooltip(rx, y, data)
            --     end
            -- end

            local line = string.format(
                "Health: %d, Armor: %d, Distance: %.0fm, Vehicle: %s",
                p.health, p.armor, p.distance, p.vehicle
            )

            ImGui.AddText(rx, y + 18*scale, line, hpR,hpG,hpB,hpA)

            ::continue::
        end
    else
        IsPlayerSectionRendering = false
    end

    DrawMinimap()  -- could include all of them in one function but i CBA

    for i = 0, scrH, 12 do
        ImGui.AddLine(0, i, scrW, i, 255, 0, 40, 6)
    end

    ImGui.End()
    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor(1)
end

local LoadingHandler = nil
local OSDHandler = nil
FeatureMgr.AddFeature(Utils.Joaat("ShowOSD"), "Draw On Screen Display", eFeatureType.Toggle, "Draw Modders", function(feature)
    if feature:IsToggled() then 
        FeatureMgr.GetFeatureByName("Disable Hud"):SetBoolValue(true)
        if IsAnimating then return end

        IsShuttingDown = false
        LoadingProgress = 0.0
        IsAnimating = true

        if OSDHandler then
            EventMgr.RemoveHandler(OSDHandler)
            OSDHandler = nil
        end

        if LoadingHandler then EventMgr.RemoveHandler(LoadingHandler) end
        LoadingHandler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, ShowLoadingScreen)
        OSDHandler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, ShowOnScreenDisplay)
    else
        FeatureMgr.GetFeatureByName("Disable Hud"):SetBoolValue(false)
        if IsAnimating then return end

        IsShuttingDown = true
        LoadingProgress = 100.0
        IsAnimating = true

        if OSDHandler then
            EventMgr.RemoveHandler(OSDHandler)
            OSDHandler = nil
        end

        if LoadingHandler then EventMgr.RemoveHandler(LoadingHandler) end
        if OSDHandler then EventMgr.RemoveHandler(OSDHandler) end
        LoadingHandler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, ShowLoadingScreen)
    end
end)

Script.RegisterLooped(function()
    if FeatureMgr.IsFeatureEnabled(Utils.Joaat("DrawCustomCrossHair")) then
        Script.QueueJob(function() Natives.InvokeVoid(0x6806C51AD12B83B8, 14) end)
    end
end)
 
ClickGUI.AddTab("CyberPilot", function()
    ImGui.Columns(2, "##label", false)

    if ClickGUI.BeginCustomChildWindow("HUD") then 
        ClickGUI.RenderFeature(Utils.Joaat("ShowOSD"))
        if isDebugMode then
            ClickGUI.RenderFeature(Utils.Joaat("Show Debug stuff"))
        end
        ClickGUI.RenderFeature(Utils.Joaat("DrawCustomCrossHair"))
        ClickGUI.RenderFeature(Utils.Joaat("CrosshairColor"))
        ClickGUI.EndCustomChildWindow()
    end
        
    if ClickGUI.BeginCustomChildWindow("PlayerStuffs") then     
        ClickGUI.RenderFeature(Utils.Joaat("PlayerNameColorFeat"))
        ClickGUI.RenderFeature(Utils.Joaat("PlayerHPFillColorFeat"))
        ClickGUI.RenderFeature(Utils.Joaat("Elfish-Beaker's HUD-Show Players"))

        ClickGUI.EndCustomChildWindow()
    end

    ImGui.NextColumn()
    if ClickGUI.BeginCustomChildWindow("MapStuff") then 
        ClickGUI.RenderFeature(Utils.Joaat("DrawCompass"))
        ClickGUI.RenderFeature(Utils.Joaat("MapZoom"))
        ClickGUI.RenderFeature(Utils.Joaat("ArrowScale"))
        ClickGUI.EndCustomChildWindow()
    end
    ImGui.Columns()
end)