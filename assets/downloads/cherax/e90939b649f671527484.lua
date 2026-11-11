local function josnFunc()local json={_version="0.1.2"}local b;local c={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local d={["/"]="/"}for e,f in pairs(c)do d[f]=e end;local function g(h)return"\\"..(c[h]or string.format("u%04x",h:byte()))end;local function i(j)return"null"end;local function k(j,l)local m={}l=l or{}if l[j]then error("circular reference")end;l[j]=true;if rawget(j,1)~=nil or next(j)==nil then local n=0;for e in pairs(j)do if type(e)~="number"then error("invalid table: mixed or invalid key types")end;n=n+1 end;if n~=#j then error("invalid table: sparse array")end;for o,f in ipairs(j)do table.insert(m,b(f,l))end;l[j]=nil;return"["..table.concat(m,",").."]"else for e,f in pairs(j)do if type(e)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(m,b(e,l)..":"..b(f,l))end;l[j]=nil;return"{"..table.concat(m,",").."}"end end;local function p(j)return'"'..j:gsub('[%z\1-\31\\"]',g)..'"'end;local function q(j)if j~=j or j<=-math.huge or j>=math.huge then error("unexpected number value '"..tostring(j).."'")end;return string.format("%.14g",j)end;local r={["nil"]=i,["table"]=k,["string"]=p,["number"]=q,["boolean"]=tostring}b=function(j,l)local s=type(j)local t=r[s]if t then return t(j,l)end;error("unexpected type '"..s.."'")end;function json.encode(j)return b(j)end;local u;local function v(...)local m={}for o=1,select("#",...)do m[select(o,...)]=true end;return m end;local w=v(" ","\t","\r","\n")local x=v(" ","\t","\r","\n","]","}",",")local y=v("\\","/",'"',"b","f","n","r","t","u")local z=v("true","false","null")local A={["true"]=true,["false"]=false,["null"]=nil}local function B(C,D,E,F)for o=D,#C do if E[C:sub(o,o)]~=F then return o end end;return#C+1 end;local function G(C,D,H)local I=1;local J=1;for o=1,D-1 do J=J+1;if C:sub(o,o)=="\n"then I=I+1;J=1 end end;error(string.format("%s at line %d col %d",H,I,J))end;local function K(n)local t=math.floor;if n<=0x7f then return string.char(n)elseif n<=0x7ff then return string.char(t(n/64)+192,n%64+128)elseif n<=0xffff then return string.char(t(n/4096)+224,t(n%4096/64)+128,n%64+128)elseif n<=0x10ffff then return string.char(t(n/262144)+240,t(n%262144/4096)+128,t(n%4096/64)+128,n%64+128)end;error(string.format("invalid unicode codepoint '%x'",n))end;local function L(M)local N=tonumber(M:sub(1,4),16)local O=tonumber(M:sub(7,10),16)if O then return K((N-0xd800)*0x400+O-0xdc00+0x10000)else return K(N)end end;local function P(C,o)local m=""local Q=o+1;local e=Q;while Q<=#C do local R=C:byte(Q)if R<32 then G(C,Q,"control character in string")elseif R==92 then m=m..C:sub(e,Q-1)Q=Q+1;local h=C:sub(Q,Q)if h=="u"then local S=C:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",Q+1)or C:match("^%x%x%x%x",Q+1)or G(C,Q-1,"invalid unicode escape in string")m=m..L(S)Q=Q+#S else if not y[h]then G(C,Q-1,"invalid escape char '"..h.."' in string")end;m=m..d[h]end;e=Q+1 elseif R==34 then m=m..C:sub(e,Q-1)return m,Q+1 end;Q=Q+1 end;G(C,o,"expected closing quote for string")end;local function T(C,o)local R=B(C,o,x)local M=C:sub(o,R-1)local n=tonumber(M)if not n then G(C,o,"invalid number '"..M.."'")end;return n,R end;local function U(C,o)local R=B(C,o,x)local V=C:sub(o,R-1)if not z[V]then G(C,o,"invalid literal '"..V.."'")end;return A[V],R end;local function W(C,o)local m={}local n=1;o=o+1;while 1 do local R;o=B(C,o,w,true)if C:sub(o,o)=="]"then o=o+1;break end;R,o=u(C,o)m[n]=R;n=n+1;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="]"then break end;if X~=","then G(C,o,"expected ']' or ','")end end;return m,o end;local function Y(C,o)local m={}o=o+1;while 1 do local Z,j;o=B(C,o,w,true)if C:sub(o,o)=="}"then o=o+1;break end;if C:sub(o,o)~='"'then G(C,o,"expected string for key")end;Z,o=u(C,o)o=B(C,o,w,true)if C:sub(o,o)~=":"then G(C,o,"expected ':' after key")end;o=B(C,o+1,w,true)j,o=u(C,o)m[Z]=j;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="}"then break end;if X~=","then G(C,o,"expected '}' or ','")end end;return m,o end;local _={['"']=P,["0"]=T,["1"]=T,["2"]=T,["3"]=T,["4"]=T,["5"]=T,["6"]=T,["7"]=T,["8"]=T,["9"]=T,["-"]=T,["t"]=U,["f"]=U,["n"]=U,["["]=W,["{"]=Y}u=function(C,D)local X=C:sub(D,D)local t=_[X]if t then return t(C,D)end;G(C,D,"unexpected character '"..X.."'")end;function json.decode(C)if type(C)~="string"then error("expected argument of type string, got "..type(C))end;local m,D=u(C,B(C,1,w,true))D=B(C,D,w,true)if D<=#C then G(C,D,"trailing garbage")end;return m end;return json end;
json=josnFunc()
----------------------------------------------------------------------------
-- definitions
---@class Message
---@field id integer
---@field is_being_replied_to_this boolean
---@field reply_id integer|nil
---@field replying_to_content string
---@field content string
---@field allows_join boolean
---@field sender_uid int
---@field username string
---@field time_unix integer

----------------------------------------------------------------------------
-- Settings
local colors = {
    replyCol =      {r=180,  g=180,  b=222,  a=38}, -- Soft blue for replies (0-255)
    tsCol =         {r=0.5,  g=0.5,  b=0.5,  a=1.0}, -- Medium gray for timestamps
    usernameCol =   {r=0.4,  g=0.75, b=0.95, a=1.0}, -- Bright cyan-blue for usernames
    onlineUserCol = {r=0.35, g=0.85, b=0.5,  a=1.0}, -- Green for online
}

local settings = {
    path            = "\\Lua\\chat_settings.json",
    -- isDbg        = Cherax.GetUID() == 7,
    logError        = Cherax.GetUID() == 7,
    isAdmin         = Cherax.GetUID() == 7,
    hideName        = false,
    longReply       = true,
    maxMsgLen       = 512,
    maxMsgCount     = 512,
    allowsJoining   = false,
    alwaysOpenChat  = false,
}
----------------------------------------------------------------------------
-- Data
local accountData = {
    uid           = Cherax.GetUID(),
    rid           = 0,
    username      = "",
    gtaVer        = string.find(Cherax.GetEdition(), "EE") and "EE" or "LE",
    isBanned      = false,
    initDone      = false,
    allowsJoining = settings.allowsJoining,
}

-- json payload
local getMessageRqs = {
	token   = "",
	last_id = 0,
}

local sendMessageRqs = {
    token   = "",
    content = "",
    reply_id = 0,
}

local messageData = {
    onlineCount         = 0,  -- online user count
    replyingToContent   = "", -- content replying to for rendering in imgui
    lastMsg             = "", -- Last msg content so we dont send the same thing twice
    lastCount           = 0,  -- how many msgs we have localy
}

local screenSizeX, screenSiteY = ImGui.GetDisplaySize()
local imguiSettings = {
    tsWidth   = (ImGui.CalcTextSize("[23:59:59]") + 6), 
    fadeSpeed = 0.08,
    chatAlpha = 0,
    isFocused = false,
    isPauseMenuActive = false,
    showChatUntil = Time.GetEpocheMs() + 1000 * 5,
    isKeyPressed = false
}

local polling = {
    interval  = 1000,
    isRunning = false,
    lastCheck = Time.GetEpocheMs()
}

---@type Message[]
local messages = {}

----------------------------------------------------------------------------
-- helper
local function logDbg(...) if not settings.isDbg then return end Logger.Log(eLogColor.LIGHTBLUE, "DBG", ...) end
local function logErrorDbg(...) if not settings.logError and not settings.isDbg then return end Logger.Log(eLogColor.LIGHTRED, "DBG ERR", ...) end
local function logError(...) Logger.Log(eLogColor.RED, "Chat Error", ...) end

local function NETWORK_PLAYER_GET_USERID(--[[Player]] player, --[[int*]] userID) return Natives.InvokeString(0x4927FC39CD0869A0, player, userID) end
local function IS_PAUSE_MENU_ACTIVE() return Natives.InvokeBool(0xB0034A223497FFCB) end
---@return string
local function getScn() return Players.GetName(GTA.GetLocalPlayerId()) end
local function getRid()
	local buffer = Memory.Alloc(24)
	if buffer ~= 0 then
		Memory.MemSet(buffer, 0, 24)
		NETWORK_PLAYER_GET_USERID(GTA.GetLocalPlayerId(), buffer)
		local rid = Memory.ReadString(buffer)
		Memory.Free(buffer)
		return rid
	end
	logErrorDbg("GRID Nullptr")
	return 0
end

function joinDiscord()
    local discord = "https://discord.gg/suuW2rmWcV"
    ImGui.SetClipboardText(discord)
    GUI.AddToast("Chat", "Please paste the discord link in a browser", 15000)
end

local function updateAccountData()
    accountData.allowsJoining = settings.allowsJoining
    if settings.hideName then
		accountData.username = "Anon" .. math.ceil(accountData.uid * (22 / 33 + 25) / 2)
    else
        accountData.username = getScn()
	end
end

---@param list Message[]
---@param msg Message
---@param maxLen integer
---@return boolean inserted
local function InsertSortedUnique(list, msg, maxLen)
    local low, high = 1, #list
    if msg.reply_id and msg.reply_id ~= 0 then
        local rl, rh = 1, #list
        while rl <= rh do
            local mid = (rl + rh) // 2
            local midMsg = list[mid]
            
            if midMsg.id == msg.reply_id then
                msg.replying_to_content = midMsg.username .. ": " .. midMsg.content
                if midMsg.sender_uid == accountData.uid then
                    midMsg.is_being_replied_to_this = true
                end
                break
            elseif midMsg.id < msg.reply_id then
                rl = mid + 1
            else
                rh = mid - 1
            end
        end
    end

    while low <= high do
        local mid = (low + high) // 2
        local midID = list[mid].id

        if midID == msg.id then
            return false -- duplicate
        elseif midID < msg.id then
            low = mid + 1
        else
            high = mid - 1
        end
    end

    table.insert(list, low, msg)
    if maxLen and #list > maxLen then
        table.remove(list, 1)
    end

    return true
end

---@return boolean success
---@return table response
local function curlWrapper(endpoint, data)
	if ShouldUnload() then return true, {} end

	local ok, isOk, payload = pcall(function()
		local req = Curl.Easy()
		req:DisableErrorLog()
		req:Setopt(eCurlOption.CURLOPT_USERAGENT, "Chatty/1.0")
		req:Setopt(eCurlOption.CURLOPT_URL, "https://chat.tumult.dev" .. endpoint)
		req:AddHeader("auth: kjdsnlfaoijp3oi1p23opijewpoiascdß9093jür20832r08frwßf0we9jßcsda0fasdf")

		req:Setopt(eCurlOption.CURLOPT_POST, 1)
		if data then
			req:Setopt(eCurlOption.CURLOPT_POSTFIELDS, tostring(data))
		end

		req:Perform()
		while not req:GetFinished() do Script.Yield() end

		local code, raw = req:GetResponse()
        logDbg(tostring(raw))
		if code == eCurlCode.CURLE_OK then
			local parsed = json.decode(raw)
			if parsed and not parsed.error then
				return true, parsed.content
			end
			return false, {}
		end

		return false, {}
	end)
	if not ok then
        -- log error for public
        if not settings.isDbg and not settings.logError then
            logError("error during webrequest")
        end
		return false, {}
	end
	return isOk, payload
end

---@return integer online_count
---@return integer max_msgs
---@return boolean success
local function curlStats()
    local success, parsed = curlWrapper("/get_stats")
	if not success then
		logErrorDbg("invalid get_stats response")
		return 0, 0, success
	end
	return parsed.online_count, parsed.max_msgs, success
end

---@return string token
---@return boolean is_banned
---@return boolean success
local function curlToken()
    updateAccountData()
    local data = { uid = accountData.uid, rid = accountData.rid, gta_ver = accountData.gtaVer, username = accountData.username, allows_join = accountData.allowsJoining }
	local success, parsed = curlWrapper("/get_token", json.encode(data))
	if not success then
		logErrorDbg("invalid get_token response")
		return "", false, success
	end
	return parsed.token, parsed.is_banned, success
end

---@return list Message[]
---@return integer highest_id
---@return boolean is_banned
---@return boolean success
local function curlGetMessage()
	local success, parsed = curlWrapper("/get_messages", json.encode(getMessageRqs))
	if not success then
		logErrorDbg("invalid get_messages response")
		return "", 0, false, success
	end
	return parsed.msg, parsed.highest_id, parsed.is_banned, success
end

---@return Message msg
---@return boolean is_banned
---@return boolean success
local function curlSendMessage()
	local data = json.encode(sendMessageRqs)
	local success, parsed = curlWrapper("/send_message", data)
	if not success then
		logErrorDbg("invalid send_message response")
		return "", false, success
	end
	return parsed.msg, parsed.is_banned, success
end

---@return string rid
---@return string gta_ver
---@return boolean success
local function curlGetRid(uid)
	local data = json.encode({uid = uid, token = getMessageRqs.token})
	local success, parsed = curlWrapper("/get_rid", data)
	if not success then
		logErrorDbg("invalid get_rid response")
		return "", "", success
	end
	return parsed.rid, parsed.gta_ver, success
end

local function joinUid(uid)
    local rid, ver, success = curlGetRid(uid)
    if success then
        if ver ~= accountData.gtaVer then
            GUI.AddToast("Chat", "This user is on a different GTA version", 10000)
            return
        end
        if rid == accountData.rid then return end
        FeatureMgr.GetFeature(0x178cb8b):SetValue(tonumber(rid)) -- RID | InputInt
        Script.Yield(10)
        FeatureMgr.GetFeature(0x3021feb7):TriggerCallback() -- Join Rockstar Id | Button
    end
end

local function loadSettings()
    local path = FileMgr.GetMenuRootPath() .. settings.path
    if not FileMgr.DoesFileExist(path) then return end

    local fileContent = FileMgr.ReadFileContent(path)
    local jsonContent = json.decode(fileContent)
    if jsonContent == nil or type(jsonContent.hide_name) ~= "boolean" or type(jsonContent.long_reply) ~= "boolean" or type(jsonContent.allows_join) ~= "boolean" then
        logError("Invalid settings file")
        return
    end

    accountData.allowsJoining = jsonContent.allows_join
    colors = jsonContent.colors or colors
    settings.alwaysOpenChat = jsonContent.always_open
    features.allowsJoin:SetDefaultValue(jsonContent.allows_join):Reset()
    features.hideName:SetDefaultValue(jsonContent.hide_name):Reset()
    features.longReply:SetDefaultValue(jsonContent.long_reply):Reset()
    HotKeyMgr.AddHotkey(features.showChatbox:GetHash(), jsonContent.hotkey)
end


local function SaveSettings()
    local path = FileMgr.GetMenuRootPath() .. settings.path
    local hotkeys = HotKeyMgr.GetHotKeys(features.showChatbox:GetHash())
    local hotkey = 0
    for i=1,#hotkeys do
        hotkey = math.max(hotkey, hotkeys[i])
    end
    local data = {
        allows_join = settings.allowsJoining,
        hide_name   = settings.hideName,
        long_reply  = settings.longReply,
        hotkey      = hotkey,
        always_open = settings.alwaysOpenChat,
        colors = colors
    }
    FileMgr.WriteFileContent(path, json.encode(data))
end

local function FormatTimestamp(unix)
    local t = os.date("*t", unix)
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

---@param str string
---@return string preview
local function GetPreview(str)
    local first = str:match("([^\n\r]+)") or ""
    if #first > 40 then first = first:sub(1, 40) .. "..." end
    return first
end

---@param msg string
---@return string msg
local function CalcNewMsg(msg)
    local maxWidth = select(1, (ImGui.GetContentRegionAvail() - 10))
    local words = {}
    for w in msg:gmatch("%S+") do table.insert(words, w) end
    local lines = {}
    local current = ""
    for _, word in ipairs(words) do
        local test = current == "" and word or (current .. " " .. word)
        local w = ImGui.CalcTextSize(test)
        if w > maxWidth then table.insert(lines, current); current = word else current = test end
    end
    if current ~= "" then table.insert(lines, current) end
    return table.concat(lines, "\n")
end

----------------------------------------------------------------------------
-- features
features = {
    hideName     = FeatureMgr.AddFeature(Utils.Joaat("HideName"), "Hide Name", eFeatureType.Toggle, "", function (f) settings.hideName = f:GetBoolValue(); curlToken() end),
    allowsJoin   = FeatureMgr.AddFeature(Utils.Joaat("AllowJoins"), "Allow Joins", eFeatureType.Toggle, "", function (f) settings.allowsJoining = f:GetBoolValue(); curlToken() end),
    alwaysShow   = FeatureMgr.AddFeature(Utils.Joaat("AlwaysShow"), "Always Open", eFeatureType.Toggle, "", function (f) settings.alwaysOpenChat = f:GetBoolValue(); curlToken() end),
    msgContent   = FeatureMgr.AddFeature(Utils.Joaat("MessageContent"), "message", eFeatureType.InputText, "", function(f) sendMessageRqs.content = f:GetStringValue() end, false):SetMaxValue(settings.maxMsgLen),
    longReply    = FeatureMgr.AddFeature(Utils.Joaat("LongReplyHighlight"), "Long Replys", eFeatureType.Toggle, "Toggles if the highlighting of replys should be whole line or only as long as the text actually is", function(f) settings.longReply = f:GetBoolValue() end),
    showChatbox  = FeatureMgr.AddFeature(Utils.Joaat("showChatBox"), "Chat Hotkey", eFeatureType.Button, "", function() imguiSettings.isKeyPressed = true end),
    saveSettings = FeatureMgr.AddFeature(Utils.Joaat("saveChatSettings"), "Save Settings", eFeatureType.Button, "", SaveSettings),
    loadSettings = FeatureMgr.AddFeature(Utils.Joaat("loadChatSettings"), "Load Settings", eFeatureType.Button, "", loadSettings),
    joinDiscord  = FeatureMgr.AddFeature(Utils.Joaat("joinDiscord"), "Join Discord", eFeatureType.Button, "", joinDiscordD),
}

FeatureMgr.AddFeature(Utils.Joaat("SendMessage"), "Send", eFeatureType.Button, "", function(f)
    if settings.isBanned then return end
    if sendMessageRqs.content == "" or messageData.lastMsg == sendMessageRqs.content then return end

    local resp, isBanned, success = curlSendMessage()
    if success then
        messageData.lastMsg = sendMessageRqs.content
        features.msgContent:Reset()
        sendMessageRqs.reply_id = 0
        messageData.replyingToContent = ""
        settings.isBanned = isBanned
    end
end)

----------------------------------------------------------------------------
-- main
function init()
    loadSettings()
    
    local scn = getScn()
    while scn:lower() == "invalid" do
        Script.Yield(100)
        scn = getScn()
    end

    accountData.username = scn
    accountData.rid = getRid()
	local token, isBanned = curlToken()
    settings.isBanned = isBanned
	getMessageRqs.token  = token
	sendMessageRqs.token = token
    accountData.initDone = true
end

local function getMessageLooped()
    if not accountData.initDone then return end
    imguiSettings.isPauseMenuActive = IS_PAUSE_MENU_ACTIVE()
    
    if accountData.username:lower() == "invalid" then
        updateAccountData()
    end

    local now = Time.GetEpocheMs()
    if now - polling.lastCheck < polling.interval or polling.isRunning then return Script.Yield() end
    
    polling.isRunning = true
    polling.lastCheck = now    

    if now - polling.lastCheck < polling.interval * 15 then messageData.onlineCount = curlStats() end

    local newMsgs, lastId, isBanned, success = curlGetMessage()
    if success then
        for _, thisMsg in ipairs(newMsgs) do InsertSortedUnique(messages, thisMsg, settings.maxMsgCount) end
        getMessageRqs.last_id = lastId
        settings.isBanned  = isBanned
    end
    polling.isRunning = false
end

Script.RegisterLooped(getMessageLooped)

----------------------------------------------------------------------------
-- ImGui
function DrawReply(msg, repliedContent)
    local paddingX = 6
    local paddingY = 3

    local x, y = ImGui.GetCursorScreenPos()
    local w, h = ImGui.CalcTextSize(msg)
    
    local width = (x + w + paddingX*2)
    if settings.longReply then
        local maxWidth, _ = ImGui.GetContentRegionAvail()
        width = (x + maxWidth - paddingX*2)
    end

    ImGui.AddRectFilled(
        x, y,
        width, (y + h + paddingY*2),
        colors.replyCol.r, colors.replyCol.g, colors.replyCol.b, colors.replyCol.a,
        3.0
    )

    ImGui.SetCursorScreenPos(x + paddingX, y + paddingY)
    ImGui.TextUnformatted(msg)
end

---@param msg Msg
local function DrawMsg(msg, isChatWindow)
    local ts = "[" .. FormatTimestamp(msg.time_unix) .. "]"
    local un = msg.username .. ": "
    if msg.sender_uid == 0 then
        un = "[DC] " .. un
    else
        if settings.isAdmin then
            un = "[GTA | UID: " .. msg.sender_uid .."] " .. un
        else
            un = "[GTA] " .. un
        end
    end

    -- Draw reply indicator on separate line above if it exists
    if msg.reply_id and msg.reply_id ~= 0 then
        ImGui.Indent(60)
        ImGui.TextColored(
            colors.replyCol.r/255, colors.replyCol.g/255, colors.replyCol.b/255, colors.replyCol.a,
            "- Replying to " .. GetPreview(tostring(msg.replying_to_content))
        )
        ImGui.Unindent(60)
    end

    local x, y = ImGui.GetCursorScreenPos()
    -- Main message line
    ImGui.TextColored(colors.tsCol.r, colors.tsCol.g, colors.tsCol.b, colors.tsCol.a, ts)
    ImGui.SameLine()
    ImGui.SetCursorScreenPos(x + imguiSettings.tsWidth, y)
    ImGui.TextColored(colors.usernameCol.r, colors.usernameCol.g, colors.usernameCol.b, colors.usernameCol.a, un)

    if isChatWindow and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        if msg.sender_uid == 0 then
            ImGui.TextUnformatted("This user messaged from discord")
        else
            if msg.allows_join then
                ImGui.TextUnformatted("click to join this player")
            else
                ImGui.TextUnformatted("User doesnt allow joining")
            end
        end
        ImGui.EndTooltip()
    end

    if isChatWindow and msg.sender_uid ~= 0 and msg.allows_join and ImGui.IsItemClicked() then
        Script.QueueJob(joinUid, msg.sender_uid)
    end

    ImGui.SameLine()
    msg.content = CalcNewMsg(msg.content)
    if msg.is_being_replied_to_this then
        DrawReply(msg.content, msg.replying_to_content) 
    else 
        ImGui.Text(msg.content) 
    end
    
    if isChatWindow and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.TextUnformatted("Click to reply")
        ImGui.EndTooltip()
    end

    if isChatWindow and ImGui.IsItemClicked() then
        messageData.replyingToContent = msg.content
        sendMessageRqs.reply_id = msg.id
    end
end


function chatWindow()
    if isBanned or ShouldUnload() then return end

    local isKeyPressed = imguiSettings.isKeyPressed
    if imguiSettings.isKeyPressed then imguiSettings.isKeyPressed = false end
    
    if imguiSettings.isPauseMenuActive then return end

    local newMsgs = #messages > messageData.lastCount
    if not imguiSettings.isPauseMenuActive and (settings.alwaysOpenChat or imguiSettings.isFocused or newMsgs or (isKeyPressed and not imguiSettings.isFocused)) then
        imguiSettings.showChatUntil = Time.GetEpocheMs() + 1000 * 5
    end

    local visible = imguiSettings.showChatUntil >= Time.GetEpocheMs()
    if visible then
        imguiSettings.chatAlpha = math.min(1, imguiSettings.chatAlpha + imguiSettings.fadeSpeed)
    else
        imguiSettings.chatAlpha = math.max(0, imguiSettings.chatAlpha - imguiSettings.fadeSpeed)
    end
    if imguiSettings.chatAlpha <= 0 then return end

    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, imguiSettings.chatAlpha)

    if ImGui.Begin("Chat", true, ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoBackground | ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.TextColored(colors.onlineUserCol.r, colors.onlineUserCol.g, colors.onlineUserCol.b, colors.onlineUserCol.a, "Online users: " .. messageData.onlineCount)
        ImGui.SameLine()
        ImGui.TextColored(colors.onlineUserCol.r, colors.onlineUserCol.g, colors.onlineUserCol.b/20, colors.onlineUserCol.a, "- Chatting as " .. accountData.username)
        ImGui.Separator()

        ImGui.BeginChild("##chatbody", screenSizeX/3.5, screenSiteY/4.5, true)
        for _, msg in ipairs(messages) do
            DrawMsg(msg)
        end

        if newMsgs then
            ImGui.SetScrollHereY()
            messageData.lastCount = #messages
        end
        ImGui.EndChild()

        if messageData.replyingToContent ~= "" then
            ImGui.TextColored(colors.replyCol.r, colors.replyCol.g, colors.replyCol.b, colors.replyCol.a/50, "Replying to: " .. GetPreview(messageData.replyingToContent) .. "...")
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.TextUnformatted("Click to undo the reply")
                ImGui.EndTooltip()
            end

            if ImGui.IsItemClicked() then
                messageData.replyingToContent = ""
                sendMessageRqs.reply_id = 0
            end
        end


        ClickGUI.RenderFeature(Utils.Joaat("MessageContent"))
        if imguiSettings.isFocused and imguiSettings.unFocusNextFrame then
            FeatureMgr.TriggerFeatureCallback(Utils.Joaat("SendMessage"))
            ImGui.SetKeyboardFocusHere()
            ImGui.Button("##kasdopasjdoibnwefivuzrbuni")
            imguiSettings.unFocusNextFrame = false
            goto endWindow
        end
        imguiSettings.isFocused = ImGui.IsItemFocused()
        if ImGui.IsKeyReleased(525) or ImGui.IsKeyReleased(525) or isKeyPressed then
            if imguiSettings.isFocused then
                imguiSettings.unFocusNextFrame = true
            elseif isKeyPressed then
                ImGui.SetKeyboardFocusHere(-1)
            end
        end
        ::endWindow::
        ImGui.End()
    end
    ImGui.PopStyleVar()
end

Script.QueueJob(init)
EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, chatWindow)
ClickGUI.AddTab("Chat", function()
    ImGui.TextColored(colors.onlineUserCol.r, colors.onlineUserCol.g, colors.onlineUserCol.b, colors.onlineUserCol.a, "Online users: " .. messageData.onlineCount)
    ImGui.SameLine()
    ImGui.TextColored(colors.onlineUserCol.r, colors.onlineUserCol.g, colors.onlineUserCol.b/20, colors.onlineUserCol.a, "- Chatting as " .. accountData.username)
    ImGui.Separator()

    ClickGUI.RenderFeature(Utils.Joaat("joinDiscord")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("showChatBox")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("saveChatSettings")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("loadChatSettings"));
    ClickGUI.RenderFeature(Utils.Joaat("HideName")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("LongReplyHighlight")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("AllowJoins")); ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("AlwaysShow"));
    ImGui.Separator()
   
    if messageData.replyingToContent ~= "" then
        ImGui.TextColored(colors.replyCol.r, colors.replyCol.g, colors.replyCol.b, colors.replyCol.a/200, "Replying to: " .. GetPreview(messageData.replyingToContent) .. "...")
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.TextUnformatted("Click to undo the reply")
            ImGui.EndTooltip()
        end

        if ImGui.IsItemClicked() then
            messageData.replyingToContent = ""
            sendMessageRqs.reply_id = 0
        end
    end

    ClickGUI.RenderFeature(Utils.Joaat("SendMessage"))
    ImGui.SameLine()
    ClickGUI.RenderFeature(Utils.Joaat("MessageContent"))
    if ImGui.IsKeyPressed(525) or ImGui.IsKeyPressed(627) then
        if ImGui.IsItemFocused() then
            FeatureMgr.TriggerFeatureCallback(Utils.Joaat("SendMessage"))
        end
    end
    ImGui.Separator()
    ImGui.BeginChild("##chatwindow") 
    for _, thisMsg in ipairs(messages) do
        DrawMsg(thisMsg, true)        
    end
    ImGui.EndChild()
end)
