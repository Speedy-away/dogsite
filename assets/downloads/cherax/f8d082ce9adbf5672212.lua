--[[
    MODVERSE v1.0.0 | PRODUCTION BUILD 154 | MARKETPLACE ONLY
    Developer: Public_Urinal
    Marketplace: Cherax Outfits, Saved Vehicles, DLCs, ClickGUI Themes, GTA5-Mods DLCs.
    Downloads use Cherax Curl, validated local files and pure-Lua ZIP extraction.
    First-run visual assets are SHA-256-verified PNGs from the ModVerse repository.
    Includes sliding post-install tutorials, local libraries, search and previews.
    Windows API resolution, native library loading, ScriptHookV/ASI execution,
    external process launchers, runtime DLL installers and diagnostic runners
    have been removed from this distribution (not merely disabled).
    v1.0.0 Build 154 changes:
    - removed obsolete browser-markup detection and reconstruction helpers
    - retained strict binary image/ZIP recognition and archive preflight
    - preserved user-confirmed Build 153 storefront and install behavior
    v1.0.0 Build 153 changes:
    - repaired gallery crash after stripping legacy drawing/tag helpers
    - restored local ImGui card backgrounds with balanced PushID/PopID usage
    - removed stale ASI tag/control hint calls from DLC views
    - introduced Cherax-only DLC load guidance without native dependencies
    v1.0.0 Build 152 changes:
    - physically removed DLL downloads, native library loader, Windows API
      resolution, external process/archive workers and native ASI launch paths
    - removed abandoned ScriptHookV setup, ASI diagnostics and related UI
    - retained Cherax game natives, which use documented game scripting APIs
    - restored DLC index loading with strict marketplace-relative path checks
    - kept supported ZIP downloads, search, themes, outfits, vehicles and guides
    This is a candidate for resubmission; approval is determined by Cherax staff.
    The developer's previous private experiments are not part of this source.
    Happy Modding ツ
]]

-- bootstrap
local SCRIPT_NAME = "ModVerse"
local SCRIPT_VERSION = "1.0.0"
local BUILD_ID = "154"
pcall(function() ClickGUI.RemoveTab(SCRIPT_NAME) end)
-- local marketplace folders only
local MENU_ROOT = FileMgr.GetMenuRootPath()
local ROOT_DIR = MENU_ROOT .. "\\Lua\\ModVerse\\"
local CACHE_DIR = ROOT_DIR .. "cache\\"
local THUMB_DIR = CACHE_DIR .. "thumbs\\"
local DOWNLOAD_DIR = ROOT_DIR .. "downloads\\"
local MODS_DIR = ROOT_DIR .. "mods\\"
local PAGE_CACHE_DIR = CACHE_DIR .. "pages\\"
local INSTALL_INDEX_FILE = ROOT_DIR .. "installed.tsv"
local COOKIE_JAR = CACHE_DIR .. "gta5mods.cookies"
local VEHICLE_MARKET_BASE = "https://www.gta5-mods.com/vehicles/"
local USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36"
local IMAGE_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko"
local IMAGE_ACCEPT = "Accept: image/jpeg, image/png, */*;q=0.1"
local PACKAGE_ACCEPT = "Accept: application/zip, application/x-zip-compressed, application/octet-stream, */*;q=0.5"
local THUMB_PROXY_BASE = "https://images.weserv.nl/?url="
local MAX_MARKET_MODS_PER_PAGE = 24
local MAX_DOWNLOAD_BYTES = 128 * 1024 * 1024
for _,dir in ipairs({ROOT_DIR,CACHE_DIR,THUMB_DIR,DOWNLOAD_DIR,MODS_DIR,PAGE_CACHE_DIR}) do FileMgr.CreateDir(dir) end


-- Production logs default to actionable messages. Detailed tracing can be
-- explicitly enabled from Tools > Diagnostics; no security checks are disabled.
ModVerseProd118 = {
    verboseLogs = false,
    details = {outfits=false, vehicles=false, dlcs=false, marketplace=false},
}
-- UI-only state: never written to state.tsv. Advanced tools and details reset closed.
ModVerseProd120 = { advanced=false }
function ModVerseProd120.showStatus(message,busy)
    local lower=tostring(message or ""):lower()
    return busy or ModVerseProd118.details.marketplace
        or lower:find("error",1,true) or lower:find("failed",1,true)
        or lower:find("unavailable",1,true) or lower:find("blocked",1,true)
        or lower:find("denied",1,true) or lower:find("mismatch",1,true)
        or lower:find("invalid",1,true) or lower:find("timeout",1,true)
end
local function log(msg)
    local message=tostring(msg)
    if not ModVerseProd118.verboseLogs then
        local lower=message:lower()
        local important=lower:find("error",1,true)
            or lower:find("failed",1,true)
            or lower:find("failure",1,true)
            or lower:find("mismatch",1,true)
            or lower:find("denied",1,true)
            or lower:find("blocked",1,true)
            or lower:find("invalid",1,true)
            or lower:find("unsafe",1,true)
            or lower:find("unavailable",1,true)
            or lower:find("warning",1,true)
            or lower:find("[warn]",1,true)
            or lower:find("exception",1,true)
            or lower:find("timed out",1,true)
            or lower:find("could not",1,true)
            or lower:find("rejected",1,true)
            or lower:find("corrupt",1,true)
            or lower:find("loaded modverse",1,true)
            or lower:find("unloading",1,true)
        if not important then return end
    end
    pcall(function() Logger.LogInfo("[ModVerse] " .. message) end)
end

function productionDetails118(key,label,width)
    local shown=ModVerseProd118.details[key]==true
    if ImGui.Button((shown and "Hide details" or (label or "Details")).."##MV118"..key,width or 106,24) then
        ModVerseProd118.details[key]=not shown
    end
    return ModVerseProd118.details[key]
end

local function toast(msg, ms)
    pcall(function() GUI.AddToast("ModVerse", tostring(msg), ms or 3500, eToastPos.TOP_RIGHT) end)
end

local function nowMs()
    local ok, v = pcall(function() return Time.GetEpocheMs() end)
    if ok and tonumber(v) then return tonumber(v) end
    return math.floor((os.clock() or 0) * 1000)
end

local function safeTextWrapped(s)
    s = tostring(s or "")
    if ImGui.TextWrapped then ImGui.TextWrapped(s) else ImGui.Text(s) end
end

local function readVec2(getter, fallbackX, fallbackY)
    fallbackX = tonumber(fallbackX) or 0
    fallbackY = tonumber(fallbackY) or 0
    local ok, a, b = pcall(function() return getter() end)
    if not ok then return fallbackX, fallbackY end
    if type(a) == "number" then return a, type(b) == "number" and b or fallbackY end
    if type(a) == "table" or type(a) == "userdata" then
        local function field(k)
            local ok2, v = pcall(function() return a[k] end)
            if ok2 and type(v) == "number" then return v end
        end
        return field("x") or field("X") or field(1) or fallbackX,
               field("y") or field("Y") or field(2) or fallbackY
    end
    return fallbackX, fallbackY
end

local function contentAvail()
    return readVec2(function() return ImGui.GetContentRegionAvail() end, 720, 0)
end

local function cursorScreenPos()
    return readVec2(function() return ImGui.GetCursorScreenPos() end, 0, 0)
end

-- Build 153: marketplace card paint primitive.  Build 152 removed its original
-- ASI marketplace owner but left callers across all retained galleries.
-- Pure Cherax ImGui drawing only; no DLL, process, or Win32 dependencies.
local function drawImageCardBackground(x, y, w, h, hovered, selected)
    ImGui.AddRectFilled(x, y, x + w, y + h, 12, 14, 22, 244, 8.0)
    local r, g, b = 112, 78, 165
    if selected then r, g, b = 175, 92, 255 end
    if hovered then r, g, b = 65, 210, 255 end
    ImGui.AddRect(x, y, x + w, y + h, r, g, b, 245, 8.0, 0, hovered and 2.4 or 1.5)
end

-- Build 153: DLC-only usage guidance replacing ASI controls/usage analysis
-- that was physically removed from the marketplace-only distribution.
local function mv153DLCUsageHints(item)
    ImGui.TextColored(0.74, 0.52, 0.95, 1.0, "Using an installed DLC")
    safeTextWrapped("In Cherax, open Misc > General > DLC, select your installed DLC, and press Load DLC. Then open Spawner > Vehicle List > DLC and select the vehicle.")
    if item and item.name then
        ImGui.TextColored(0.58, 0.61, 0.70, 1.0, tostring(item.name):sub(1, 85))
    end
    ImGui.Separator()
end

-- Build 062: server-side GTA5-Mods sort and time filters (independent per catalog).
MV062_SORT = {
    {label="Latest Versions", path="newest", search="latest"},
    {label="Latest Uploads", path="latest-uploads", search="latest-uploads"},
    {label="Most Liked", path="most-liked", search="most-liked"},
    {label="Most Downloads", path="most-downloaded", search="most-downloaded"},
    {label="Highest Rated", path="highest-rated", search="highest-rated"},
}
MV062_SINCE = {
    {label="All-time", path=""},
    {label="Last Month", path="month"},
    {label="Last Week", path="week"},
    {label="Yesterday", path="day"},
}
function mv062SearchSegment(s)
    s=tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")
    -- encode URL path bytes; keep user queries out of executable/file paths
    return (s:gsub("([^%w%-_%.~])",function(b) return string.format("%%%02X",string.byte(b)) end))
end
function mv062FilterKey(v)
    local so=MV062_SORT[v.sort or 1] or MV062_SORT[1]
    local si=MV062_SINCE[v.since or 1] or MV062_SINCE[1]
    local search=tostring(v.appliedSearch or "")
    local hash=5381
    for i=1,#search do hash=(hash*33+search:byte(i))%4294967296 end
    local short=search:lower():gsub("[^%w%-]","_"):sub(1,40)
    if short=="" then short="catalog" end
    return so.path.."_"..(si.path~="" and si.path or "all").."_"..short.."_"..string.format("%08x",hash)
end
function mv062CatalogUrl(category, v, page)
    page=math.max(1,math.floor(tonumber(page) or 1))
    local sort=MV062_SORT[v.sort or 1] or MV062_SORT[1]
    local since=MV062_SINCE[v.since or 1] or MV062_SINCE[1]
    local applied=tostring(v.appliedSearch or ""):match("^%s*(.-)%s*$") or ""
    local url
    if applied~="" then
        -- GTA5-Mods' locale-aware global search routes are best-effort; if unavailable
        -- the normal catalog remains cached and usable.
        url="https://www.gta5-mods.com/gl/search/"..category.."/"..mv062SearchSegment(applied).."/"..sort.search
    else
        url="https://www.gta5-mods.com/"..(category=="scripts" and "scripts/tags/asi" or "vehicles")
        if (v.sort or 1)~=1 then url=url.."/"..sort.path end
    end
    if since.path~="" then url=url.."/"..since.path end
    if page>1 then url=url.."/"..tostring(page) end
    return url
end
function mv062FilterPicker(id, v, redraw)
    -- Build 067: selection must never start HTTP from inside an ImGui combo.
    if v.draftSort==nil then v.draftSort=v.sort or 1 end
    if v.draftSince==nil then v.draftSince=v.since or 1 end
    local sort=MV062_SORT[v.draftSort] or MV062_SORT[1]
    local since=MV062_SINCE[v.draftSince] or MV062_SINCE[1]
    ImGui.Text("Sort:"); ImGui.SameLine()
    if ImGui.SetNextItemWidth then ImGui.SetNextItemWidth(143) end
    if ImGui.BeginCombo("##mvSort"..id,sort.label) then
        for i,r in ipairs(MV062_SORT) do
            if ImGui.Selectable(r.label.."##mvSortOpt"..id..i,v.draftSort==i) then
                v.draftSort=i
            end
        end
        ImGui.EndCombo()
    end
    ImGui.SameLine(); ImGui.Text("Since:"); ImGui.SameLine()
    if ImGui.SetNextItemWidth then ImGui.SetNextItemWidth(105) end
    if ImGui.BeginCombo("##mvSince"..id,since.label) then
        for i,r in ipairs(MV062_SINCE) do
            if ImGui.Selectable(r.label.."##mvSinceOpt"..id..i,v.draftSince==i) then
                v.draftSince=i
            end
        end
        ImGui.EndCombo()
    end
    if v.draftSort~=(v.sort or 1) or v.draftSince~=(v.since or 1) then
        ImGui.SameLine()
        if ImGui.Button("Apply##mvFilter"..id,65,25) and (not v.lastFilterApply or nowMs()-v.lastFilterApply>900) then
            v.sort=v.draftSort; v.since=v.draftSince; v.page=1
            v.lastFilterApply=nowMs()
            redraw()
        end
    end
end

-- Build 067: BiggerScript-style direct ImGui text entry. Do NOT force
-- CaptureKeyboardFromApp every frame: it can interrupt Cherax input routing.
-- The optional click-keyboard is a robust fallback if another loaded script
-- or the game's hotkeys continue to steal real key events.
function mv063SearchBox(id,v)
    v.search=tostring(v.search or "")
    if v.mv064FocusSearch and ImGui.SetKeyboardFocusHere then
        ImGui.SetKeyboardFocusHere()
        v.mv064FocusSearch=false
    end
    if ImGui.SetNextItemWidth then ImGui.SetNextItemWidth(195) end
    -- Assign the returned string DIRECTLY, as in BiggerScript's working search.
    local updated=ImGui.InputText("##mvSearch"..id,v.search,128)
    if type(updated)=="string" then v.search=updated:sub(1,120) end
    ImGui.SameLine()
    if ImGui.Button("Focus##mvFocus"..id,48,25) then v.mv064FocusSearch=true end
    ImGui.SameLine()
    if ImGui.Button("Paste##mvPaste"..id,49,25) then
        local ok,clip=pcall(function() return Utils.GetClipBoardText() end)
        if ok and type(clip)=="string" then
            v.search=clip:gsub("[\r\n\t]"," "):sub(1,120)
        else toast("Clipboard unavailable",2200) end
    end
    ImGui.SameLine()
    if ImGui.Button((v.mv064Keys and "Hide" or "Keys").."##mvKeys"..id,46,25) then
        v.mv064Keys=not v.mv064Keys
    end
    -- Click-based input works even if native key events are eaten by GTA.
    -- Hidden by default to keep the Marketplace minimal.
    if v.mv064Keys then
        ImGui.TextColored(0.72,0.75,0.86,1.00,"Search keys")
        for _,line in ipairs({"QWERTYUIOP","ASDFGHJKL","ZXCVBNM","1234567890"}) do
            for i=1,#line do
                local ch=line:sub(i,i)
                if i>1 then ImGui.SameLine() end
                if ImGui.Button(ch.."##mvK"..id..line..i,31,25) then
                    v.search=(v.search..ch:lower()):sub(1,120)
                end
            end
        end
        if ImGui.Button("Space##mvSpace"..id,67,25) then v.search=(v.search.." "):sub(1,120) end
        ImGui.SameLine()
        if ImGui.Button("Back##mvBack"..id,62,25) then v.search=v.search:sub(1,-2) end
        ImGui.SameLine()
        if ImGui.Button("Clear##mvKeysClear"..id,63,25) then v.search="" end
        ImGui.SameLine()
        if ImGui.Button("Done##mvKeysDone"..id,60,25) then v.mv064Keys=false end
    end
end

-- Build 145: Cherax Outfits/DLC galleries can be expensive to rebuild while
-- an InputText is active. Keep the edit buffer SEPARATE from the applied filter:
-- users can type several characters without tearing down the thumbnail/PED
-- gallery, then apply once with Find. Reuse the proven Build 064 focus, clipboard
-- and on-screen key controls. Do not force global keyboard capture.
function mv145CheraxSearch(id, owner, field)
    if type(owner) ~= "table" then return false end
    field = field or "search"
    local key = "mv145Draft_" .. field
    local draft = owner[key]
    if type(draft) ~= "table" then
        draft = {search=tostring(owner[field] or "")}
        owner[key] = draft
    end
    ImGui.Text("Search")
    ImGui.SameLine()
    mv063SearchBox("Cherax145_" .. tostring(id), draft)
    ImGui.SameLine()
    if ImGui.Button("Find##MV145_" .. tostring(id), 56, 25) then
        local nextValue = tostring(draft.search or ""):match("^%s*(.-)%s*$") or ""
        draft.search = nextValue
        if owner[field] ~= nextValue then
            owner[field] = nextValue
            return true
        end
    end
    ImGui.SameLine()
    if ImGui.Button("Clear##MV145_" .. tostring(id), 56, 25) then
        local changed = owner[field] ~= ""
        owner[field] = ""
        draft.search = ""
        return changed
    end
    if draft.search ~= tostring(owner[field] or "") then
        ImGui.TextColored(0.68, 0.74, 0.87, 1.0, "Press Find to apply search")
    end
    return false
end

-- Cherax does not document Utils.OpenURL; never swallow that failure silently.
function mv063PageLink(item)
    local url=tostring(item and item.page_url or "")
    if not url:match("^https://www%.gta5%-mods%.com/") then
        toast("No valid mod link",2200);return false
    end
    local ok,result=pcall(function() return Utils.SetClipBoardText(url,"") end)
    if ok and result~=false then toast("Link copied. Paste into browser",3000);return true end
    toast("Could not copy page link",2800);return false
end

-- Controls come from the installed mod when possible, otherwise from cached
-- description lines only. These are hints, not invented hotkeys.

function mv062StarHit(x,y,w,mx,my)
    local sx,sy=x+w-41,y+8
    return mx>=sx and mx<=sx+33 and my>=sy and my<=sy+33
end
function mv062DrawStar(item,kind,x,y,w)
    local sx,sy=x+w-41,y+8
    local starred=VehicleFav152.contains(item)
    ImGui.AddRectFilled(sx,sy,sx+33,sy+33,20,18,30,225,7)
    ImGui.AddRect(sx,sy,sx+33,sy+33,starred and 245 or 178,starred and 198 or 170,starred and 64 or 205,255,7,0,1.2)
    ImGui.AddText(sx+8,sy+5,starred and "★" or "☆",starred and 255 or 240,starred and 210 or 238,starred and 65 or 250,255)
end
function mv062TileStarClicked(x,y,w)
    local mx,my=readVec2(function() return ImGui.GetMousePos() end,-1000,-1000)
    return mv062StarHit(x,y,w,mx,my)
end
local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

local function shortText(s, maxChars)
    s = tostring(s or "")
    maxChars = math.max(4, tonumber(maxChars) or 24)
    if #s <= maxChars then return s end
    return s:sub(1, maxChars - 3) .. "..."
end

local function basename(path)
    return tostring(path or ""):match("([^\\/]+)$") or tostring(path or "")
end

local function dirname(path)
    return tostring(path or ""):match("^(.*)[\\/][^\\/]+$") or ""
end

local function sanitizeFileName(s)
    s = tostring(s or "item"):gsub("[^%w%._%-]", "_")
    s = s:gsub("_+", "_")
    if s == "" then s = "item" end
    return s
end

local function fileExists(path)
    local ok, v = pcall(function() return FileMgr.DoesFileExist(path) end)
    if ok and v == true then return true end
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return false
end

local function writeBinary(path, data)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(data or "")
    f:close()
    return true
end

local function readBinaryPrefix(path, n)
    local f = io.open(path, "rb")
    if not f then return nil end
    local d = f:read(n or 16)
    f:close()
    return d
end


local function fileSize(path)
    local f = io.open(path, "rb")
    if not f then return -1 end
    local ok, n = pcall(function() return f:seek("end") end)
    f:close()
    return ok and tonumber(n) or -1
end

-- Pure-Lua ZIP extraction used by the marketplace.
-- This intentionally avoids FileMgr.Unzip (which stalled in live testing) and all
-- outside helper programs. Only the two normal ZIP methods are supported: Stored (0)
-- and DEFLATE (8).
local ZIP_MAX_FILE_BYTES  = 512 * 1024 * 1024
local ZIP_MAX_TOTAL_BYTES = 768 * 1024 * 1024
local ZIP_MAX_ENTRIES     = 4096

local function u16le(s, p)
    local a, b = string.byte(s, p, p + 1)
    if not a or not b then return nil end
    return a | (b << 8)
end

local function u32le(s, p)
    local a, b, c, d = string.byte(s, p, p + 3)
    if not a or not b or not c or not d then return nil end
    return a | (b << 8) | (c << 16) | (d << 24)
end

local function reverseBits(v, n)
    local r = 0
    for _ = 1, n do
        r = (r << 1) | (v & 1)
        v = v >> 1
    end
    return r
end

local function buildHuffman(lengths)
    local counts, nextCode, maps = {}, {}, {}
    local maxLen = 0
    for i = 1, #lengths do
        local len = tonumber(lengths[i]) or 0
        counts[len] = (counts[len] or 0) + 1
        if len > maxLen then maxLen = len end
    end
    if maxLen == 0 then return { maxLen = 0, maps = {} } end

    local code = 0
    for bits = 1, maxLen do
        code = (code + (counts[bits - 1] or 0)) << 1
        nextCode[bits] = code
        maps[bits] = {}
    end

    for i = 1, #lengths do
        local len = tonumber(lengths[i]) or 0
        if len > 0 then
            local c = nextCode[len]
            nextCode[len] = c + 1
            -- DEFLATE packs Huffman codes least-significant bit first. Store the
            -- bit-reversed canonical code so one-bit-at-a-time decoding is direct.
            maps[len][reverseBits(c, len)] = i - 1
        end
    end
    return { maxLen = maxLen, maps = maps }
end

local function newBitReader(src, first, last)
    return {
        src = src,
        pos = first,
        last = last,
        bitbuf = 0,
        bitcount = 0,
    }
end

local function brReadBits(br, n)
    if n == 0 then return 0 end
    while br.bitcount < n do
        if br.pos > br.last then error("DEFLATE stream ended unexpectedly") end
        local b = string.byte(br.src, br.pos)
        br.pos = br.pos + 1
        br.bitbuf = br.bitbuf | (b << br.bitcount)
        br.bitcount = br.bitcount + 8
    end
    local mask = (1 << n) - 1
    local value = br.bitbuf & mask
    br.bitbuf = br.bitbuf >> n
    br.bitcount = br.bitcount - n
    return value
end

local function brAlignByte(br)
    -- br.pos already points at the next not-yet-buffered byte. Discard the partial
    -- byte still in bitbuf to align to the next byte boundary.
    br.bitbuf = 0
    br.bitcount = 0
end

local function huffDecode(br, h)
    if not h or not h.maxLen or h.maxLen <= 0 then error("Invalid empty Huffman tree") end
    local code = 0
    for bits = 1, h.maxLen do
        code = code | (brReadBits(br, 1) << (bits - 1))
        local row = h.maps[bits]
        local sym = row and row[code] or nil
        if sym ~= nil then return sym end
    end
    error("Invalid Huffman code in DEFLATE stream")
end

local LENGTH_BASE = {
    3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258
}
local LENGTH_EXTRA = {
    0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0
}
local DIST_BASE = {
    1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577
}
local DIST_EXTRA = {
    0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13
}

local FIXED_LIT_LENGTHS, FIXED_DIST_LENGTHS = {}, {}
for sym = 0, 287 do
    local len
    if sym <= 143 then len = 8
    elseif sym <= 255 then len = 9
    elseif sym <= 279 then len = 7
    else len = 8 end
    FIXED_LIT_LENGTHS[sym + 1] = len
end
for sym = 0, 31 do FIXED_DIST_LENGTHS[sym + 1] = 5 end
local FIXED_LIT_TREE  = buildHuffman(FIXED_LIT_LENGTHS)
local FIXED_DIST_TREE = buildHuffman(FIXED_DIST_LENGTHS)

local function dynamicTrees(br)
    local hlit  = brReadBits(br, 5) + 257
    local hdist = brReadBits(br, 5) + 1
    local hclen = brReadBits(br, 4) + 4
    if hlit > 286 or hdist > 32 then error("Invalid dynamic Huffman counts") end

    local order = {16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15}
    local codeLengths = {}
    for i = 1, 19 do codeLengths[i] = 0 end
    for i = 1, hclen do
        codeLengths[order[i] + 1] = brReadBits(br, 3)
    end

    local codeTree = buildHuffman(codeLengths)
    local all = {}
    local wanted = hlit + hdist
    while #all < wanted do
        local sym = huffDecode(br, codeTree)
        if sym >= 0 and sym <= 15 then
            all[#all + 1] = sym
        elseif sym == 16 then
            if #all == 0 then error("DEFLATE repeat-without-previous code") end
            local repeatCount = brReadBits(br, 2) + 3
            local previous = all[#all]
            for _ = 1, repeatCount do all[#all + 1] = previous end
        elseif sym == 17 then
            local repeatCount = brReadBits(br, 3) + 3
            for _ = 1, repeatCount do all[#all + 1] = 0 end
        elseif sym == 18 then
            local repeatCount = brReadBits(br, 7) + 11
            for _ = 1, repeatCount do all[#all + 1] = 0 end
        else
            error("Invalid DEFLATE code-length symbol")
        end
        if #all > wanted then error("Dynamic Huffman lengths overflowed") end
    end

    local litLengths, distLengths = {}, {}
    for i = 1, hlit do litLengths[i] = all[i] or 0 end
    for i = 1, hdist do distLengths[i] = all[hlit + i] or 0 end
    return buildHuffman(litLengths), buildHuffman(distLengths)
end

local function inflateRawToFile(src, first, compressedSize, outPath, expectedSize)
    local last = first + compressedSize - 1
    if compressedSize < 0 or first < 1 or last > #src then
        return false, "compressed data range is outside the ZIP"
    end

    local f, openErr = io.open(outPath, "wb")
    if not f then return false, "could not create output file: " .. tostring(openErr or outPath) end

    local br = newBitReader(src, first, last)
    local ring = {}
    local pending = {}
    local pendingCount = 0
    local outCount = 0

    local function flushPending()
        if pendingCount > 0 then
            f:write(table.concat(pending, "", 1, pendingCount))
            pending = {}
            pendingCount = 0
        end
    end

    local function emitByte(b)
        b = b & 0xFF
        ring[(outCount & 0x7FFF) + 1] = b
        outCount = outCount + 1
        pendingCount = pendingCount + 1
        pending[pendingCount] = string.char(b)
        if pendingCount >= 8192 then flushPending() end
        if outCount > ZIP_MAX_FILE_BYTES then error("expanded file exceeds ModVerse's 512 MB per-file limit") end
        if (outCount & 0x3FFFF) == 0 then Script.Yield(0) end
    end

    local ok, err = pcall(function()
        local finalBlock = false
        while not finalBlock do
            finalBlock = brReadBits(br, 1) == 1
            local blockType = brReadBits(br, 2)

            if blockType == 0 then
                brAlignByte(br)
                if br.pos + 3 > br.last then error("Truncated DEFLATE stored block header") end
                local len  = u16le(src, br.pos)
                local nlen = u16le(src, br.pos + 2)
                br.pos = br.pos + 4
                if not len or not nlen or ((len ~ 0xFFFF) & 0xFFFF) ~= nlen then
                    error("Invalid DEFLATE stored block length")
                end
                if br.pos + len - 1 > br.last then error("Truncated DEFLATE stored block") end
                for i = 0, len - 1 do emitByte(string.byte(src, br.pos + i)) end
                br.pos = br.pos + len
            elseif blockType == 1 or blockType == 2 then
                local litTree, distTree
                if blockType == 1 then
                    litTree, distTree = FIXED_LIT_TREE, FIXED_DIST_TREE
                else
                    litTree, distTree = dynamicTrees(br)
                end

                while true do
                    local sym = huffDecode(br, litTree)
                    if sym < 256 then
                        emitByte(sym)
                    elseif sym == 256 then
                        break
                    elseif sym >= 257 and sym <= 285 then
                        local li = sym - 257 + 1
                        local extraLen = LENGTH_EXTRA[li]
                        local runLen = LENGTH_BASE[li] + brReadBits(br, extraLen)

                        local distSym = huffDecode(br, distTree)
                        if distSym < 0 or distSym > 29 then error("Invalid DEFLATE distance symbol") end
                        local di = distSym + 1
                        local distance = DIST_BASE[di] + brReadBits(br, DIST_EXTRA[di])
                        if distance <= 0 or distance > outCount or distance > 32768 then
                            error("Invalid DEFLATE back-reference distance")
                        end
                        for _ = 1, runLen do
                            local sourceIndex = ((outCount - distance) & 0x7FFF) + 1
                            local b = ring[sourceIndex]
                            if b == nil then error("DEFLATE history window underrun") end
                            emitByte(b)
                        end
                    else
                        error("Invalid DEFLATE literal/length symbol")
                    end
                end
            else
                error("Reserved DEFLATE block type")
            end
        end
        flushPending()
    end)

    pcall(function() f:close() end)
    if not ok then
        pcall(function() FileMgr.DeleteFile(outPath) end)
        return false, tostring(err)
    end
    if expectedSize and expectedSize >= 0 and outCount ~= expectedSize then
        pcall(function() FileMgr.DeleteFile(outPath) end)
        return false, string.format("expanded size mismatch (expected %d, got %d)", expectedSize, outCount)
    end
    return true, outCount
end

local function safeZipRelativePath(name)
    name = tostring(name or ""):gsub("\\", "/")
    if name == "" then return nil, "empty entry name" end
    if name:find("\0", 1, true) then return nil, "NUL in entry name" end
    if name:sub(1, 1) == "/" or name:match("^%a:[/\\]") then return nil, "absolute path entry rejected" end

    local parts = {}
    for part in name:gmatch("[^/]+") do
        if part == ".." then return nil, "parent traversal entry rejected" end
        if part ~= "." and part ~= "" then
            if part:find('[<>:"|%?%*]') then return nil, "Windows-invalid filename in archive" end
            if part:match("[%.%s]$") then return nil, "Windows-ambiguous trailing dot/space in archive path" end
            local deviceBase = (part:match("^([^%.]+)") or part):upper()
            if deviceBase == "CON" or deviceBase == "PRN" or deviceBase == "AUX" or deviceBase == "NUL"
                or deviceBase:match("^COM[1-9]$") or deviceBase:match("^LPT[1-9]$") then
                return nil, "Windows device-name entry rejected"
            end
            parts[#parts + 1] = part
        end
    end
    if #parts == 0 then return nil, "empty normalized path" end
    return table.concat(parts, "\\"), nil
end

local function ensureZipParents(root, relPath, includeLast)
    local parts = {}
    for part in tostring(relPath):gmatch("[^\\]+") do parts[#parts + 1] = part end
    local limit = includeLast and #parts or (#parts - 1)
    local cur = root
    for i = 1, limit do
        cur = cur .. "\\" .. parts[i]
        FileMgr.CreateDir(cur)
    end
end

local function findEocd(zip)
    local first = math.max(1, #zip - 65557)
    for p = #zip - 21, first, -1 do
        if zip:sub(p, p + 3) == "PK\005\006" then return p end
    end
    return nil
end

local function extractZipPureLua(archivePath, outDir, onProgress)
    local f = io.open(archivePath, "rb")
    if not f then return false, "could not reopen downloaded ZIP", {} end
    local zip = f:read("*a")
    f:close()
    if type(zip) ~= "string" or #zip < 22 then return false, "ZIP is empty/truncated", {} end

    local eocd = findEocd(zip)
    if not eocd then return false, "ZIP end-of-central-directory record was not found", {} end

    local diskNo      = u16le(zip, eocd + 4)
    local cdDisk      = u16le(zip, eocd + 6)
    local entriesDisk = u16le(zip, eocd + 8)
    local entryCount  = u16le(zip, eocd + 10)
    local cdSize      = u32le(zip, eocd + 12)
    local cdOffset    = u32le(zip, eocd + 16)
    if not diskNo or not cdDisk or not entryCount or not cdOffset then return false, "truncated ZIP EOCD", {} end
    if diskNo ~= 0 or cdDisk ~= 0 or entriesDisk ~= entryCount then return false, "multi-disk ZIP archives are unsupported", {} end
    if entryCount == 0xFFFF or cdSize == 0xFFFFFFFF or cdOffset == 0xFFFFFFFF then return false, "ZIP64 archives are unsupported in this alpha", {} end
    if entryCount > ZIP_MAX_ENTRIES then return false, "ZIP has too many entries", {} end

    FileMgr.CreateDir(outDir)
    local p = cdOffset + 1
    local totalExpanded = 0
    local extracted = 0
    local asiPaths = {}
    local allPaths = {}
    log(string.format("Pure-Lua ZIP: entries=%d, central=%d bytes, archive=%d bytes", entryCount, cdSize or 0, #zip))

    for index = 1, entryCount do
        if zip:sub(p, p + 3) ~= "PK\001\002" then
            return false, "central directory signature missing at entry " .. tostring(index), asiPaths
        end

        local versionMade = u16le(zip, p + 4) or 0
        local flags       = u16le(zip, p + 8)
        local method      = u16le(zip, p + 10)
        local compSize    = u32le(zip, p + 20)
        local uncompSize  = u32le(zip, p + 24)
        local nameLen     = u16le(zip, p + 28)
        local extraLen    = u16le(zip, p + 30)
        local commentLen  = u16le(zip, p + 32)
        local extAttr     = u32le(zip, p + 38) or 0
        local localOffset = u32le(zip, p + 42)
        if not flags or not method or not compSize or not uncompSize or not nameLen or not extraLen or not commentLen or not localOffset then
            return false, "truncated central directory entry " .. tostring(index), asiPaths
        end
        if compSize == 0xFFFFFFFF or uncompSize == 0xFFFFFFFF or localOffset == 0xFFFFFFFF then
            return false, "ZIP64 entry encountered at " .. tostring(index), asiPaths
        end
        if (flags & 0x0001) ~= 0 then return false, "encrypted ZIP entries are unsupported", asiPaths end
        if uncompSize > ZIP_MAX_FILE_BYTES then return false, "archive entry exceeds 512 MB expanded limit", asiPaths end
        totalExpanded = totalExpanded + uncompSize
        if totalExpanded > ZIP_MAX_TOTAL_BYTES then return false, "archive exceeds 768 MB expanded limit", asiPaths end

        local rawName = zip:sub(p + 46, p + 46 + nameLen - 1)
        local rel, pathErr = safeZipRelativePath(rawName)
        if not rel then return false, "unsafe ZIP entry: " .. tostring(pathErr), asiPaths end

        local hostOs = (versionMade >> 8) & 0xFF
        local unixMode = (extAttr >> 16) & 0xFFFF
        if hostOs == 3 and (unixMode & 0xF000) == 0xA000 then
            return false, "symbolic-link ZIP entries are rejected", asiPaths
        end

        local isDir = rawName:sub(-1) == "/" or rawName:sub(-1) == "\\" or (hostOs == 3 and (unixMode & 0xF000) == 0x4000)
        local outPath = outDir .. "\\" .. rel
        if isDir then
            ensureZipParents(outDir, rel, true)
        else
            ensureZipParents(outDir, rel, false)
            local lp = localOffset + 1
            if zip:sub(lp, lp + 3) ~= "PK\003\004" then return false, "local ZIP header missing for " .. rel, asiPaths end
            local localFlags    = u16le(zip, lp + 6)
            local localMethod   = u16le(zip, lp + 8)
            local localNameLen  = u16le(zip, lp + 26)
            local localExtraLen = u16le(zip, lp + 28)
            if not localFlags or not localMethod or not localNameLen or not localExtraLen then return false, "truncated local ZIP header for " .. rel, asiPaths end
            if (localFlags & 0x0001) ~= 0 or localMethod ~= method then return false, "local ZIP header mismatch for " .. rel, asiPaths end
            local dataStart = lp + 30 + localNameLen + localExtraLen
            if dataStart + compSize - 1 > #zip then return false, "compressed data is truncated for " .. rel, asiPaths end

            local okWrite, detail
            if method == 0 then
                local wf = io.open(outPath, "wb")
                if not wf then return false, "could not create " .. rel, asiPaths end
                wf:write(zip:sub(dataStart, dataStart + compSize - 1))
                wf:close()
                okWrite = compSize == uncompSize
                detail = okWrite and uncompSize or "stored-size mismatch"
            elseif method == 8 then
                okWrite, detail = inflateRawToFile(zip, dataStart, compSize, outPath, uncompSize)
            else
                return false, "unsupported ZIP compression method " .. tostring(method) .. " for " .. rel, asiPaths
            end
            if not okWrite then
                pcall(function() FileMgr.DeleteFile(outPath) end)
                return false, "failed extracting " .. rel .. ": " .. tostring(detail), asiPaths
            end

            extracted = extracted + 1
            allPaths[#allPaths + 1] = outPath
            if rel:lower():match("%.asi$") then asiPaths[#asiPaths + 1] = outPath end
            if index <= 24 or rel:lower():match("%.asi$") then
                log(string.format("ZIP entry %d/%d: method=%d, %d -> %d bytes, %s",
                    index, entryCount, method, compSize, uncompSize, rel))
            end
        end

        p = p + 46 + nameLen + extraLen + commentLen
        if onProgress then pcall(onProgress,'extract',index/entryCount,index,entryCount) end
        if (index & 3) == 0 then Script.Yield(0) end
    end

    log(string.format("Pure-Lua ZIP complete: %d files, %d ASI, %d expanded bytes", extracted, #asiPaths, totalExpanded))
    return true, "pure-lua-zip", asiPaths, allPaths
end

-- Build 038 archive support.
local function hexEncode(s)
    return (tostring(s or ""):gsub(".", function(c) return string.format("%02X", string.byte(c)) end))
end

local function hexDecode(s)
    local out = {}
    tostring(s or ""):gsub("%x%x", function(cc)
        out[#out + 1] = string.char(tonumber(cc, 16))
    end)
    return table.concat(out)
end

local function httpGet(url, timeoutMs, referer, headers, userAgent)
    if not Curl or not Curl.Easy then return nil, "Curl API unavailable" end
    local curl = Curl.Easy()
    local function opt(code, value) pcall(function() curl:Setopt(code, value) end) end
    opt(10002, tostring(url))                         -- CURLOPT_URL
    opt(52, 1)                                       -- CURLOPT_FOLLOWLOCATION
    opt(68, 10)                                      -- CURLOPT_MAXREDIRS
    opt(58, 1)                                       -- CURLOPT_AUTOREFERER
    opt(10018, userAgent or USER_AGENT)               -- CURLOPT_USERAGENT
    opt(10102, "")                                  -- CURLOPT_ACCEPT_ENCODING (all supported)
    opt(10031, COOKIE_JAR)                           -- CURLOPT_COOKIEFILE
    opt(10082, COOKIE_JAR)                           -- CURLOPT_COOKIEJAR
    if referer and referer ~= "" then opt(10016, tostring(referer)) end -- CURLOPT_REFERER
    if curl.AddHeader and type(headers) == "table" then
        for _, header in ipairs(headers) do
            pcall(function() curl:AddHeader(tostring(header)) end)
        end
    end
    curl:Perform()

    local deadline = nowMs() + (tonumber(timeoutMs) or 15000)
    while not curl:GetFinished() do
        if nowMs() >= deadline then return nil, "request timeout" end
        Script.Yield(50)
    end

    local code, body = curl:GetResponse()
    local okCode = code == 0 or code == true or (eCurlCode and code == eCurlCode.CURLE_OK)
    if not okCode then return nil, "curl error " .. tostring(code) end
    if type(body) ~= "string" then return nil, "empty response" end
    return body
end

-- Pure-Lua hash and file reader used only for integrity verification.
local ModVerseHash152 = {}
function ModVerseHash152.sha256(data)
    if type(data) ~= "string" then return nil end
    local mask = 0xffffffff
    local function rotr(x,n) return (((x >> n) | (x << (32-n))) & mask) end
    local K = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
    }
    local H = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    local size = #data
    local padding = (56 - ((size + 1) % 64)) % 64
    data = data .. "\128" .. string.rep("\0", padding) .. string.pack(">I8",size*8)
    for block=1,#data,64 do
        local w={}
        for i=1,16 do w[i]=string.unpack(">I4",data,block+(i-1)*4) end
        for i=17,64 do
            local p=w[i-15]; local q=w[i-2]
            local s0=rotr(p,7) ~ rotr(p,18) ~ (p >> 3)
            local s1=rotr(q,17) ~ rotr(q,19) ~ (q >> 10)
            w[i]=(w[i-16]+s0+w[i-7]+s1) & mask
        end
        local a,b,c,d,e,f,g,h=table.unpack(H)
        for i=1,64 do
            local s1=rotr(e,6) ~ rotr(e,11) ~ rotr(e,25)
            local ch=(e & f) ~ ((~e) & g)
            local t1=(h+s1+ch+K[i]+w[i]) & mask
            local s0=rotr(a,2) ~ rotr(a,13) ~ rotr(a,22)
            local maj=(a & b) ~ (a & c) ~ (b & c)
            local t2=(s0+maj) & mask
            h=g;g=f;f=e;e=(d+t1)&mask;d=c;c=b;b=a;a=(t1+t2)&mask
        end
        H[1]=(H[1]+a)&mask;H[2]=(H[2]+b)&mask;H[3]=(H[3]+c)&mask;H[4]=(H[4]+d)&mask
        H[5]=(H[5]+e)&mask;H[6]=(H[6]+f)&mask;H[7]=(H[7]+g)&mask;H[8]=(H[8]+h)&mask
    end
    local out={}
    for i=1,8 do out[#out+1]=string.format("%08x",H[i]) end
    return table.concat(out)
end
function ModVerseHash152.read(path)
    local f=io.open(path,"rb")
    if not f then return nil end
    local value=f:read("*a")
    f:close()
    return value
end
local function urlEncodeComponent(s)
    return (tostring(s or ""):gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function hexHead(data, count)
    if type(data) ~= "string" then return "" end
    local out = {}
    for i = 1, math.min(#data, tonumber(count) or 16) do
        out[#out + 1] = string.format("%02X", data:byte(i))
    end
    return table.concat(out, " ")
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- html parsing
-- ═══════════════════════════════════════════════════════════════════════════════════════

local function htmlDecode(s)
    s = tostring(s or "")
    s = s:gsub("&amp;", "&")
         :gsub("&quot;", '"')
         :gsub("&#39;", "'")
         :gsub("&#x27;", "'")
         :gsub("&lt;", "<")
         :gsub("&gt;", ">")
         :gsub("&nbsp;", " ")
    s = s:gsub("&#(%d+);", function(n)
        n = tonumber(n)
        if n and n >= 32 and n <= 255 then return string.char(n) end
        return ""
    end)
    return s
end

local function stripTags(s)
    s = tostring(s or "")
    s = s:gsub("<[bB][rR]%s*/?>", "\n")
    s = s:gsub("</[pP]>", "\n")
    s = s:gsub("<[^>]+>", "")
    s = htmlDecode(s)
    s = s:gsub("\r", "")
    s = s:gsub("[ \t]+", " ")
    s = s:gsub("\n%s+", "\n")
    s = s:gsub("%s+\n", "\n")
    s = s:gsub("\n\n\n+", "\n\n")
    return s:match("^%s*(.-)%s*$") or s
end

local function tagAttr(tag, attr)
    if not tag then return nil end
    local p1 = attr .. '%s*=%s*"([^"]*)"'
    local p2 = attr .. "%s*=%s*'([^']*)'"
    return tag:match(p1) or tag:match(p2)
end

local function metaContent(html, key)
    for tag in tostring(html or ""):gmatch("<[mM][eE][tT][aA][^>]*>") do
        local property = tagAttr(tag, "property") or tagAttr(tag, "name")
        if property and property:lower() == tostring(key):lower() then
            return htmlDecode(tagAttr(tag, "content") or "")
        end
    end
    return nil
end

local function absoluteUrl(url)
    url = htmlDecode(url or "")
    if url:match("^https?://") then return url end
    if url:sub(1, 2) == "//" then return "https:" .. url end
    if url:sub(1, 1) == "/" then return "https://www.gta5-mods.com" .. url end
    return "https://www.gta5-mods.com/" .. url
end

local function parseListing(html, category)
    category = category == "vehicles" and "vehicles" or "scripts"
    local pages = {}
    local seen = {}

    local function considerHref(href)
        if #pages >= MAX_MARKET_MODS_PER_PAGE then return end
        href = htmlDecode(href)
        local path = href:gsub("^https?://[^/]+", "")
        local slug = path:match("^/" .. category .. "/([^/%?#]+)")
        local navSlugs = {
            ["tags"] = true, ["latest-uploads"] = true, ["featured"] = true,
            ["most-liked"] = true, ["most-downloaded"] = true, ["highest-rated"] = true,
            ["newest"] = true, ["day"] = true, ["week"] = true, ["month"] = true
        }
        if not slug or slug:match("^%d+$") or navSlugs[slug:lower()] then return end
        local lower = slug:lower()
        if seen[lower] then return end
        seen[lower] = true
        pages[#pages + 1] = {
            slug = category == "vehicles" and ("vehicle-" .. slug) or slug,
            category = category,
            page_url = "https://www.gta5-mods.com/" .. category .. "/" .. slug,
            market_page_url = category == "vehicles" and VEHICLE_MARKET_BASE or nil,
            name = slug:gsub("%-", " "),
            author = "",
            description = "Loading description...",
            thumb_url = nil,
            download_url = nil,
            details_loaded = false,
            thumb_status = "waiting",
            install_status = "",
        }
    end

    local src = tostring(html or "")
    for href in src:gmatch('href%s*=%s*"([^"]+)"') do considerHref(href) end
    if #pages < MAX_MARKET_MODS_PER_PAGE then
        for href in src:gmatch("href%s*=%s*'([^']+)'") do considerHref(href) end
    end
    return pages
end

local function jsonUnescape(s)
    s = tostring(s or "")
    local out, i = {}, 1
    while i <= #s do
        local c = s:sub(i, i)
        if c ~= "\\" then
            out[#out + 1] = c
            i = i + 1
        else
            local n = s:sub(i + 1, i + 1)
            if n == "n" then out[#out + 1] = "\n"; i = i + 2
            elseif n == "r" then out[#out + 1] = "\r"; i = i + 2
            elseif n == "t" then out[#out + 1] = "\t"; i = i + 2
            elseif n == "b" then out[#out + 1] = "\b"; i = i + 2
            elseif n == "f" then out[#out + 1] = "\f"; i = i + 2
            elseif n == "\\" or n == '"' or n == "/" then out[#out + 1] = n; i = i + 2
            elseif n == "u" then
                local hex = s:sub(i + 2, i + 5)
                local cp = tonumber(hex, 16)
                if cp then
                    local ok, ch = pcall(function() return utf8.char(cp) end)
                    out[#out + 1] = ok and ch or ""
                    i = i + 6
                else
                    i = i + 2
                end
            else
                out[#out + 1] = n
                i = i + 2
            end
        end
    end
    return table.concat(out)
end

local function jsonStringValues(html, key, maxCount)
    local src, out, searchAt = tostring(html or ""), {}, 1
    local token = '"' .. tostring(key) .. '"'
    while #out < (maxCount or 12) do
        local a, b = src:find(token, searchAt, true)
        if not a then break end
        local colon = src:find(":", b + 1, true)
        if not colon then break end
        local q = colon + 1
        while q <= #src and src:sub(q, q):match("%s") do q = q + 1 end
        if src:sub(q, q) == '"' then
            local i, escaped, buf = q + 1, false, {}
            while i <= #src do
                local c = src:sub(i, i)
                if escaped then
                    buf[#buf + 1] = "\\" .. c
                    escaped = false
                elseif c == "\\" then
                    escaped = true
                elseif c == '"' then
                    out[#out + 1] = jsonUnescape(table.concat(buf))
                    searchAt = i + 1
                    break
                else
                    buf[#buf + 1] = c
                end
                i = i + 1
            end
            if i > #src then searchAt = b + 1 end
        else
            searchAt = b + 1
        end
    end
    return out
end

local function cleanDescription(s)
    s = tostring(s or "")
    if s:find("<", 1, true) then s = stripTags(s) else s = htmlDecode(s) end
    s = s:gsub("\\r", ""):gsub("\\n", "\n")
    s = s:gsub("\r", "")
    s = s:gsub("[ \t]+\n", "\n"):gsub("\n[ \t]+", "\n")
    s = s:gsub("\n\n\n+", "\n\n")
    return s:match("^%s*(.-)%s*$") or s
end

local function extractLongDescription(html)
    local candidates = {}
    local og = metaContent(html, "og:description")
    if og and og ~= "" then candidates[#candidates + 1] = cleanDescription(og) end

    for _, value in ipairs(jsonStringValues(html, "description", 24)) do
        local c = cleanDescription(value)
        if #c >= 40 and #c <= 60000 then candidates[#candidates + 1] = c end
    end

    local src = tostring(html or "")
    local patterns = {
        'itemprop=["\']description["\'][^>]*>(.-)</[dD][iI][vV]>',
        'class=["\'][^"\']*mod%-description[^"\']*["\'][^>]*>(.-)</[dD][iI][vV]>',
        'class=["\'][^"\']*description[^"\']*["\'][^>]*>(.-)</[dD][iI][vV]>',
    }
    for _, pattern in ipairs(patterns) do
        local raw = src:match(pattern)
        if raw then
            local c = cleanDescription(raw)
            if #c >= 40 and #c <= 60000 then candidates[#candidates + 1] = c end
        end
    end

    table.sort(candidates, function(a, b) return #a > #b end)
    return candidates[1]
end

local function cacheDetailHtml(item, html)
    if not item or type(html) ~= "string" or #html < 100 then return end
    local path = PAGE_CACHE_DIR .. sanitizeFileName(item.slug or "mod") .. ".html"
    pcall(function() writeBinary(path, html) end)
end

local function parseDetail(item, html)
    if not item or type(html) ~= "string" then return end
    cacheDetailHtml(item, html)

    item.name = metaContent(html, "og:title") or item.name
    item.name = item.name:gsub("%s*%- GTA5%-Mods%.com%s*$", "")
    local longDescription = extractLongDescription(html)
    if longDescription and #longDescription >= #(item.description or "") then
        item.description = longDescription
    else
        item.description = metaContent(html, "og:description") or item.description
    end
    item.thumb_url = metaContent(html, "og:image") or item.thumb_url

    local canonical = metaContent(html, "og:url")
    if canonical and canonical ~= "" then item.page_url = canonical end

    local dl = nil
    local src = tostring(html or "")
    local function considerDownload(href)
        if dl then return end
        href = htmlDecode(href)
        if href:match("/scripts/[^/]+/download/%d+") or
           href:match("/vehicles/[^/]+/download/%d+") then dl = absoluteUrl(href) end
    end
    for href in src:gmatch('href%s*=%s*"([^"]+)"') do considerDownload(href); if dl then break end end
    if not dl then
        for href in src:gmatch("href%s*=%s*'([^']+)'") do considerDownload(href); if dl then break end end
    end
    item.download_url = dl or item.download_url

    local author = src:match('class=["\'][^"\']*user%-name[^"\']*["\'][^>]*>(.-)</a>')
    if not author then author = src:match('rel=["\']author["\'][^>]*>(.-)</a>') end
    if author then item.author = stripTags(author) end

    item.details_loaded = true
    -- Build 067: verbose per-card log spam harms FPS during large filtered grids.
    if MODVERSE_VERBOSE_DETAILS==true then
        log(string.format("Detail parsed %s: description=%d chars, download=%s, thumb=%s",
            tostring(item.slug), #(item.description or ""), item.download_url and "yes" or "no", item.thumb_url and "yes" or "no"))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- thumbnails
-- ═══════════════════════════════════════════════════════════════════════════════════════

local TextureCache = {}

local function deleteFile(path)
    if not path or path == "" then return end
    pcall(function()
        if FileMgr.DeleteFile then FileMgr.DeleteFile(path)
        else os.remove(path) end
    end)
end

-- Images are accepted only when their binary signatures match known formats.
-- All other responses, including markup, are rejected as invalid images.

local function detectImageKind(data)
    if type(data) ~= "string" or #data < 12 then return nil end
    local a, b, c, d = data:byte(1, 4)
    if a == 0x89 and data:sub(2, 4) == "PNG" then return "png" end
    if a == 0xFF and b == 0xD8 and c == 0xFF then return "jpg" end
    if data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP" then return "webp" end
    if data:sub(1, 6) == "GIF87a" or data:sub(1, 6) == "GIF89a" then return "gif" end
    return nil
end

local function detectImageFile(path)
    if not fileExists(path) then return nil end
    local f = io.open(path, "rb")
    if not f then return nil end
    local d = f:read(512)
    f:close()
    return detectImageKind(d or "")
end

local function thumbPath(item, ext)
    return THUMB_DIR .. sanitizeFileName(item.slug) .. "." .. tostring(ext or "jpg")
end

local function findCachedThumb(item)
    for _, ext in ipairs({"jpg", "png"}) do
        local p = thumbPath(item, ext)
        if fileExists(p) then
            local kind = detectImageFile(p)
            if kind == "jpg" or kind == "png" then return p, kind end
            log("Removing invalid thumbnail cache: " .. tostring(p) .. " (" .. tostring(kind or "unknown") .. ")")
            TextureCache[p] = nil
            deleteFile(p)
        end
    end
    return nil
end

local function textureSrv(path)
    if not path or not fileExists(path) or not Texture then return nil end
    local kind = detectImageFile(path)
    if kind ~= "jpg" and kind ~= "png" then return nil end

    local t = TextureCache[path]
    if not t then
        t = { id = nil, srv = nil, started = false, failed = false, lastPoll = 0 }
        TextureCache[path] = t
    end
    if t.srv then return t.srv end
    if t.failed then return nil end

    if not t.id and not t.started then
        t.started = true
        local ok, id = pcall(function()
            if Texture.LoadTextureAsync then return Texture.LoadTextureAsync(path) end
            return Texture.LoadTexture(path)
        end)
        id = ok and tonumber(id) or nil
        if not id or id == 0 then
            t.failed = true
            log("Texture allocation failed for " .. tostring(path))
            return nil
        end
        t.id = id
    end

    if nowMs() - t.lastPoll < 120 then return nil end
    t.lastPoll = nowMs()
    if Texture.IsTextureValid and Texture.IsTextureValid(t.id) ~= true then return nil end
    local ok, texture = pcall(function() return Texture.GetTexture(t.id) end)
    if not ok or not texture then return nil end
    local ok2, srv = pcall(function() return texture:GetCurrent() end)
    if ok2 and srv then t.srv = srv; return srv end
    return nil
end

-- ================================================================================
-- build 150 / first-run visual asset delivery
-- note: only six pinned PNG files; no DLLs, native library loading or OS commands.
-- note: the script runs without artwork when GitHub is unavailable; retry is manual.
-- build 151: pin the actual ModVerse.png currently present on GitHub main;
-- the old Build 150 ZIP contained a different logo revision, which failed verification.
-- ================================================================================
ModVerseAssets150 = {
    baseUrl="https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace/main/",
    state="pending", detail="Checking tutorial images...", progress=0,
    running=false, installed=0, cached=0, errors={},
    files={
        { repo='ModVerse.png', relative='assets\\ModVerse.png', bytes=857838, sha256='2617dce1fba439d65c75c944489c91097240b0307bd37a352dcdadeba58684ad' },
        { repo='assets/tutorial/Garage.png', relative='assets\\tutorial\\Garage.png', bytes=1123, sha256='91f15138e10f61a232dfcdacd2b163285091f4997ec5015ac8cffc688c68c70a' },
        { repo='assets/tutorial/Misc.png', relative='assets\\tutorial\\Misc.png', bytes=1375, sha256='7db1a8faa967f7a0b2356deaf523fb60bf1458539cfb1cf19db0e3c0d9e88ad0' },
        { repo='assets/tutorial/Player.png', relative='assets\\tutorial\\Player.png', bytes=1340, sha256='a57494f79437b87ad67096f3a51de564caecc2878fc8030497a860c3bde3d218' },
        { repo='assets/tutorial/Settings.png', relative='assets\\tutorial\\Settings.png', bytes=1395, sha256='37059c84e5d3cd98898abe0f9a2238f6e12f768bac033d610333f4f64fc7fe73' },
        { repo='assets/tutorial/SpawnButton.png', relative='assets\\tutorial\\SpawnButton.png', bytes=2686, sha256='a6628f83763efa0a86f291668da91b18813bc0469b8f30086b178ef8996de10f' },
    },
}
function ModVerseAssets150.localPath(spec)
    -- Paths are from the compile-time allowlist, never remote-provided names.
    return ROOT_DIR .. spec.relative
end
function ModVerseAssets150.valid(spec, bytes)
    return type(bytes)=="string" and #bytes==spec.bytes
        and bytes:sub(1,8)=="\137PNG\r\n\026\n"
        and ModVerseHash152.sha256(bytes)==spec.sha256
end
function ModVerseAssets150.check(spec)
    local file=io.open(ModVerseAssets150.localPath(spec),"rb")
    if not file then return false end
    local raw=file:read(spec.bytes+1)
    file:close()
    return ModVerseAssets150.valid(spec,raw)
end
function ModVerseAssets150.store(spec,bytes)
    if not ModVerseAssets150.valid(spec,bytes) then return false,"asset content mismatch" end
    local path=ModVerseAssets150.localPath(spec)
    local stage=path..".mv150.part"
    local backup=path..".mv150.bak"
    local parent=dirname(path)
    pcall(function() FileMgr.CreateDir(ROOT_DIR.."assets\\") end)
    pcall(function() FileMgr.CreateDir(ROOT_DIR.."assets\\tutorial\\") end)
    pcall(function() FileMgr.CreateDir(parent) end)
    -- A previous interrupted attempt may have left a partial temporary file.
    if fileExists(stage) then
        pcall(os.remove,stage)
    end
    if not writeBinary(stage,bytes) then return false,"cannot write temporary image" end
    if not ModVerseAssets150.checkStage(spec,stage) then
        pcall(os.remove,stage)
        return false,"temporary image verification failed"
    end
    local original=fileExists(path)
    if original then
        -- Fail closed if a prior backup is still present: never overwrite saved data.
        if fileExists(backup) then
            pcall(os.remove,stage)
            return false,"old image backup exists; move it before retrying"
        end
        local moved=os.rename(path,backup)
        if not moved then pcall(os.remove,stage);return false,"cannot back up outdated image" end
    end
    if not os.rename(stage,path) then
        if original then pcall(os.rename,backup,path) end
        pcall(os.remove,stage)
        return false,"cannot finalize image file"
    end
    if not ModVerseAssets150.check(spec) then
        pcall(os.remove,path)
        if original then pcall(os.rename,backup,path) end
        return false,"final image verification failed"
    end
    if original then pcall(os.remove,backup) end
    if TextureCache then TextureCache[path]=nil end
    return true
end
function ModVerseAssets150.checkStage(spec,path)
    local f=io.open(path,"rb")
    if not f then return false end
    local data=f:read(spec.bytes+1)
    f:close()
    return ModVerseAssets150.valid(spec,data)
end
function ModVerseAssets150.install()
    local a=ModVerseAssets150
    a.state="checking";a.detail="Checking tutorial images...";a.progress=0
    a.errors={};a.installed=0;a.cached=0
    for i,spec in ipairs(a.files) do
        if a.check(spec) then
            a.cached=a.cached+1
        else
            a.state="downloading"
            a.detail="Downloading "..spec.repo
            local body,err=httpGet(a.baseUrl..spec.repo,25000,nil,{"Accept: image/png", "Cache-Control: no-cache"},USER_AGENT)
            if not body then
                a.errors[#a.errors+1]=spec.repo..": "..tostring(err or "request failed")
            elseif not a.valid(spec,body) then
                a.errors[#a.errors+1]=spec.repo..": size, PNG signature or SHA-256 mismatch (check uploaded GitHub file)"
            else
                local ok,reason=a.store(spec,body)
                if ok then a.installed=a.installed+1
                else a.errors[#a.errors+1]=spec.repo..": "..tostring(reason) end
            end
        end
        a.progress=i/#a.files
        if Script and Script.Yield then Script.Yield(0) end
    end
    if #a.errors==0 then
        a.state="ready"
        a.detail=string.format("Tutorial images ready (%d existing, %d downloaded)",a.cached,a.installed)
        log("[ASSETS150] "..a.detail)
    else
        a.state="error"
        a.detail=string.format("%d of %d image(s) need attention; More > Tutorial > Retry Assets",#a.errors,#a.files)
        log("[ASSETS150][WARN] "..a.detail.." | "..table.concat(a.errors," | "))
    end
    return a.state=="ready"
end
function ModVerseAssets150.start()
    local a=ModVerseAssets150
    if a.running then return false end
    a.running=true
    a.state="queued";a.detail="Preparing visual assets...";a.progress=0
    Script.QueueJob(function()
        local ok,err=pcall(a.install)
        if not ok then
            a.state="error";a.detail="Visual asset setup failed; retry under More > Tutorial"
            a.errors={tostring(err)}
            log("[ASSETS150][ERROR] "..tostring(err))
        end
        a.running=false
    end)
    return true
end
function ModVerseAssets150.renderStatus()
    local a=ModVerseAssets150
    ImGui.Separator()
    ImGui.TextColored(1.0,.59,.23,1.0,"TUTORIAL IMAGE ASSETS")
    if a.state=="ready" then
        ImGui.TextColored(.35,.91,.60,1.0,a.detail)
    elseif a.state=="error" then
        ImGui.TextColored(1,.40,.40,1,"Asset download incomplete")
        safeTextWrapped(a.detail)
        for i,err in ipairs(a.errors) do
            if i>3 then break end
            safeTextWrapped(shortText(err,125))
        end
    else
        ImGui.Text(shortText(a.detail,112))
    end
    if a.running and ImGui.ProgressBar then ImGui.ProgressBar(a.progress or 0,280,18,"") end
    if ImGui.Button(a.running and "Checking assets...##MV150" or "Retry / Repair Images##MV150",203,27) and not a.running then
        a.start()
    end
    ImGui.SameLine()
    if ImGui.Button("Copy Asset Folder##MV150",155,27) then
        pcall(function() Utils.SetClipBoardText(ROOT_DIR.."assets\\", "") end)
        toast("Asset directory copied",1800)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- build 147 / animated modverse tutorial cards
-- note: only Cherax documented ImGui and texture APIs; never runs native ASI/DLL.
-- note: no automatic startup popup. Each real install may queue its own guide.
-- ═══════════════════════════════════════════════════════════════════════════════════════
ModVerseTutorial147 = {
    active=nil, queue={}, handler=nil, useMenuFallback=false,
    logoPath=ROOT_DIR.."assets\\ModVerse.png",
    iconPaths={
        outfits=ROOT_DIR.."assets\\tutorial\\Player.png",
        themes=ROOT_DIR.."assets\\tutorial\\Settings.png",
        vehicles=ROOT_DIR.."assets\\tutorial\\Garage.png",
        dlcs=ROOT_DIR.."assets\\tutorial\\Misc.png",
    },
}
ModVerseTutorial147.cards={
    outfits={title="OUTFITS INSTALLED",intro="Your outfit has been downloaded! Here's how to wear it:",
        steps={"Open Player (person icon) > Cosmetic > Saving.",
            "Open the Outfit dropdown, scroll to an mMV_ name, and select your outfit."},
        tip="Startup.lua makes choosing saved outfits even easier!"},
    themes={title="THEME DOWNLOADED",intro="Ready to change the look of Cherax?",
        steps={"Open Settings (gear icon) > Theme Section.",
            "Choose your downloaded theme in the Themes dropdown, then press Load Theme."},
        tip="Startup.lua can shuffle your Cherax themes every time you play!"},
    vehicles={title="VEHICLE INSTALLED",intro="Your saved vehicle is ready to use!",
        steps={"Return to ModVerse's vehicle marketplace or installed vehicle selection.",
            "Select the vehicle and press Spawn Selected Vehicle."},
        tip="Startup.lua's quick-access Garage lets you organize hundreds of saved vehicles in subfolders."},
    dlcs={title="DLC INSTALLED",intro="One quick Cherax step before you spawn your DLC vehicle:",
        steps={"Open Misc (sliders icon) > General. Select your DLC in the DLC dropdown and press Load DLC.",
            "Open Spawner (garage icon) > Vehicle List (right column) > DLC, then select your vehicle."},
        tip="Your DLC must be compatible with your GTA version and fully loaded first."},
}
function ModVerseTutorial147.open(kind,source)
    if not ModVerseTutorial147.cards[kind] then return false end
    if ModVerseTutorial147.active and ModVerseTutorial147.active.kind==kind then return false end
    for _,card in ipairs(ModVerseTutorial147.queue) do if card.kind==kind then return false end end
    local item={kind=kind,source=source or "install",requested=nowMs()}
    if ModVerseTutorial147.active then
        if #ModVerseTutorial147.queue>=4 then table.remove(ModVerseTutorial147.queue,1) end
        ModVerseTutorial147.queue[#ModVerseTutorial147.queue+1]=item
    else
        item.start=nowMs(); ModVerseTutorial147.active=item
    end
    return true
end
function ModVerseTutorial147.dismiss()
    if #ModVerseTutorial147.queue>0 then
        ModVerseTutorial147.active=table.remove(ModVerseTutorial147.queue,1)
        ModVerseTutorial147.active.start=nowMs()
    else ModVerseTutorial147.active=nil end
end
function ModVerseTutorial147.ease(t)
    t=math.max(0,math.min(1,tonumber(t) or 0))
    return t*t*(3-2*t)
end
function ModVerseTutorial147.render()
    local card=ModVerseTutorial147.active
    if not card or not ImGui or not ImGui.Begin or not ImGui.End then return end
    local content=ModVerseTutorial147.cards[card.kind]
    if not content then ModVerseTutorial147.dismiss(); return end
    local now=nowMs()
    local elapsed=math.max(0,now-(card.start or now))
    local entrance=ModVerseTutorial147.ease(elapsed/560)
    local sw,sh=readVec2(function() return ImGui.GetDisplaySize() end,1920,1080)
    if sw<420 or sh<300 then return end
    local w=math.min(670,math.max(380,sw*0.62))
    local h=math.min(425,math.max(315,sh*0.59))
    local targetX=(sw-w)*0.5
    local x=(sw+32)-(sw+32-targetX)*entrance
    local y=math.max(25,(sh-h)*0.39)
    if ImGui.SetNextWindowPos then ImGui.SetNextWindowPos(x,y,ImGuiCond and ImGuiCond.Always or 0) end
    if ImGui.SetNextWindowSize then ImGui.SetNextWindowSize(w,h,ImGuiCond and ImGuiCond.Always or 0) end
    local flags=0
    if ImGuiWindowFlags then
        for _,key in ipairs({"NoTitleBar","NoResize","NoMove","NoCollapse","NoSavedSettings","NoScrollbar"}) do
            flags=flags | (tonumber(ImGuiWindowFlags[key]) or 0)
        end
    end
    local ok,shown=pcall(ImGui.Begin,"ModVerse Tutorial##MV147",true,flags)
    if not ok then return end
    if shown~=false then
        pcall(function()
            local px,py=readVec2(function() return ImGui.GetWindowPos() end,x,y)
            if ImGui.AddRectFilled then
                ImGui.AddRectFilled(px,py,px+7,py+h,255,121,0,255,4)
                ImGui.AddRectFilled(px+7,py+82,px+w-14,py+84,255,121,0,200,0)
            end
            ImGui.Spacing()
            -- Bundled ModVerse logo, original square aspect ratio preserved.
            local imageSrv=textureSrv(ModVerseTutorial147.logoPath)
            if imageSrv and ImGui.AddImage and ImGui.Dummy then
                local ix,iy=readVec2(function() return ImGui.GetCursorScreenPos() end,px+14,py+10)
                ImGui.Dummy(70,69)
                ImGui.AddImage(imageSrv,ix+6,iy,ix+72,iy+66)
                ImGui.SameLine()
            end
            ImGui.TextColored(1.0,0.48,0.00,1.0,"MODVERSE")
            ImGui.SameLine()
            ImGui.TextColored(.94,.94,.97,1.0,"  |  QUICK START")
            ImGui.Spacing();ImGui.Separator()
            local iconSrv=textureSrv(ModVerseTutorial147.iconPaths[card.kind])
            if iconSrv and ImGui.AddImage and ImGui.Dummy then
                local bx,by=readVec2(function() return ImGui.GetCursorScreenPos() end,px+20,py+100)
                ImGui.Dummy(39,39)
                ImGui.AddImage(iconSrv,bx,by,bx+36,by+36)
                ImGui.SameLine()
            end
            ImGui.TextColored(1.0,.66,.32,1.0,content.title)
            safeTextWrapped(content.intro)
            ImGui.Spacing()
            for i,line in ipairs(content.steps) do
                ImGui.TextColored(1.00,.62,.29,1.0,tostring(i)..".")
                ImGui.SameLine();safeTextWrapped(line)
            end
            ImGui.Spacing()
            ImGui.TextColored(1.0,.72,.36,1.0,"PRO TIP")
            safeTextWrapped(content.tip)
            ImGui.Spacing();ImGui.Separator()
            if ImGui.Button("GOT IT!##MV147Dismiss",145,33) then ModVerseTutorial147.dismiss() end
            ImGui.SameLine()
            ImGui.TextColored(.59,.64,.73,1.0,"Replay anytime: More > Tutorial")
        end)
    end
    pcall(ImGui.End)
end

local function ensureThumbnail(item)
    if not item or not item.thumb_url or item.thumb_url == "" then return end

    local cached = findCachedThumb(item)
    if cached then
        item.thumb_path = cached
        item.thumb_status = "ready"
        return
    end

    if item.thumb_status == "downloading" then return end
    item.thumb_status = "downloading"
    local imageHeaders = { IMAGE_ACCEPT, "Cache-Control: no-cache" }
    local body, err = httpGet(item.thumb_url, 18000, item.page_url, imageHeaders, IMAGE_USER_AGENT)
    if not body or #body < 100 or #body > (16 * 1024 * 1024) then
        item.thumb_status = "failed"
        item.thumb_error = err or "invalid image response"
        log("Thumbnail download failed for " .. tostring(item.slug) .. ": " .. tostring(item.thumb_error))
        return
    end

    local kind = detectImageKind(body)
    if kind == "webp" then
        -- CDN ignored our JPEG/PNG Accept header. Use a best-effort image-transcode
        -- fallback so Cherax receives an actual JPEG instead of mislabeled WebP bytes.
        local proxyUrl = THUMB_PROXY_BASE .. urlEncodeComponent(item.thumb_url) .. "&output=jpg&q=90&w=640"
        log("Thumbnail WebP negotiated for " .. tostring(item.slug) .. "; trying JPEG transcode fallback")
        local converted, proxyErr = httpGet(proxyUrl, 20000, item.page_url, imageHeaders, IMAGE_USER_AGENT)
        if converted and #converted >= 100 and #converted <= (16 * 1024 * 1024) then
            local convertedKind = detectImageKind(converted)
            if convertedKind == "jpg" or convertedKind == "png" then
                body, kind = converted, convertedKind
                log("Thumbnail converted to " .. kind .. " for " .. tostring(item.slug))
            else
                err = "transcode returned " .. tostring(convertedKind or "unknown")
            end
        else
            err = proxyErr or "thumbnail transcode failed"
        end
    end

    if kind ~= "jpg" and kind ~= "png" then
        item.thumb_status = "failed"
        item.thumb_error = "thumbnail remained " .. tostring(kind or "unknown") .. (err and (" (" .. tostring(err) .. ")") or "")
        log("Thumbnail rejected for " .. tostring(item.slug) .. ": " .. item.thumb_error)
        return
    end

    local path = thumbPath(item, kind)
    if writeBinary(path, body) then
        item.thumb_path = path
        item.thumb_status = "ready"
        item.thumb_error = nil
        TextureCache[path] = nil
        log("Thumbnail cached: " .. tostring(path))
        return
    end

    item.thumb_status = "failed"
    item.thumb_error = "could not save image"
end


-- Build 038 persistent Marketplace cache.
-- Metadata/HTML/thumbnails may refresh automatically, but mod packages never do:
-- ZIP/RAR/ASI payloads are still fetched only from an explicit install click.
MarketCache037 = MarketCache037 or {}
function MarketCache037.pageCachePath(page, filters)
    local key=filters and mv062FilterKey(filters) or "legacy"
    return PAGE_CACHE_DIR .. "market_062_"..key.."_p"..tostring(math.max(1, tonumber(page) or 1)) .. ".html"
end

function MarketCache037.detailCachePath(item)
    return PAGE_CACHE_DIR .. sanitizeFileName(item and item.slug or "mod") .. ".html"
end

function MarketCache037.readCachedText(path)
    if not path or not fileExists(path) then return nil end
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    if type(data) ~= "string" or data == "" then return nil end
    return data
end

function MarketCache037.hydrateCachedItem(item)
    if not item then return false end
    local used = false
    local cachedDetail = MarketCache037.readCachedText(MarketCache037.detailCachePath(item))
    if cachedDetail then
        parseDetail(item, cachedDetail)
        used = true
    end
    local cachedThumb = findCachedThumb(item)
    if cachedThumb then
        item.thumb_path = cachedThumb
        item.thumb_status = "ready"
        used = true
    end
    item.cache_hit = used
    return used
end

function MarketCache037.loadCachedPage(page, filters)
    local html = MarketCache037.readCachedText(MarketCache037.pageCachePath(page, filters))
    if not html then return {} end
    local items = parseListing(html)
    for _, item in ipairs(items) do MarketCache037.hydrateCachedItem(item) end
    return items
end

function MarketCache037.savePageCache(page, html, filters)
    if type(html) ~= "string" or #html < 100 then return false end
    return writeBinary(MarketCache037.pageCachePath(page, filters), html)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- marketplace state / refresh
-- ═══════════════════════════════════════════════════════════════════════════════════════

local Market = {
    page = 1,
    items = {},
    selected = nil,
    loading = false,
    status = "Not loaded",
    lastRefresh = 0,
    sort=1, since=1, search="", appliedSearch="",
}

local UI = { activeTab = "Marketplace" }

-- User-pinned mixed-content favorites. These are intentionally separate from the
-- ASI-only marketplace feed so scripts, trainers, maps, and Menyoo content can
local function writeMeta(root, item)
    local lines = {
        "slug=" .. hexEncode(item.slug or ""),
        "name=" .. hexEncode(item.name or ""),
        "author=" .. hexEncode(item.author or ""),
        "page=" .. hexEncode(item.page_url or ""),
        "description=" .. hexEncode(item.description or ""),
        "thumb=" .. hexEncode(item.thumb_path or ""),
    }
    pcall(function() FileMgr.WriteFileContent(root .. "\\modverse.meta", table.concat(lines, "\n"), false) end)
end

local function readMeta(root)
    local p = root .. "\\modverse.meta"
    if not fileExists(p) then return {} end
    local ok, raw = pcall(function() return FileMgr.ReadFileContent(p) end)
    if not ok or type(raw) ~= "string" then return {} end
    local meta = {}
    for line in raw:gmatch("[^\r\n]+") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k and v then meta[k] = hexDecode(v) end
    end
    return meta
end

local InstallIndex = { roots = {} }

local function normalizePath(path)
    return tostring(path or ""):gsub("/", "\\"):gsub("\\+", "\\")
end

local function saveInstallIndex()
    local roots = {}
    for root in pairs(InstallIndex.roots) do roots[#roots + 1] = root end
    table.sort(roots, function(a,b) return a:lower() < b:lower() end)
    local lines = {"VERSION\t2"}
    for _, root in ipairs(roots) do lines[#lines + 1] = "ROOT\t" .. hexEncode(root) end
    pcall(function() FileMgr.WriteFileContent(INSTALL_INDEX_FILE, table.concat(lines, "\n"), false) end)
end

local function loadInstallIndex()
    InstallIndex.roots = {}
    -- Read both new and legacy registries; do not move native files, alter
    -- existing auto-start paths or delete the prior marketplace directory.
    local function mergeIndex(path)
        if not fileExists(path) then return end
        local ok, raw = pcall(function() return FileMgr.ReadFileContent(path) end)
        if not ok or type(raw) ~= "string" then return end
        for line in raw:gmatch("[^\r\n]+") do
            local kind, encoded = line:match("^([^\t]+)\t(.+)$")
            if kind == "ROOT" and encoded then
                local root = normalizePath(hexDecode(encoded))
                if root ~= "" then InstallIndex.roots[root] = true end
            end
        end
    end
    mergeIndex(INSTALL_INDEX_FILE)
end

loadInstallIndex() -- restore indexed DLC roots before the first DLC scan

local function registerInstallRoot(root)
    root = normalizePath(root)
    if root == "" then return end
    if not InstallIndex.roots[root] then
        InstallIndex.roots[root] = true
        saveInstallIndex()
        log("Registered installed mod root: " .. root)
    end
end

local function writeManifest(root, paths)
    local seen, lines = {}, {"VERSION\t1"}
    root = normalizePath(root)
    local prefix = root .. "\\"
    for _, path in ipairs(paths or {}) do
        path = normalizePath(path)
        if path ~= "" and not seen[path:lower()] then
            seen[path:lower()] = true
            local rel = path
            if path:sub(1, #prefix):lower() == prefix:lower() then rel = path:sub(#prefix + 1) end
            lines[#lines + 1] = "FILE\t" .. hexEncode(rel)
        end
    end
    pcall(function() FileMgr.WriteFileContent(root .. "\\modverse.manifest", table.concat(lines, "\n"), false) end)
end

local function readManifest(root)
    -- Build 070: manually installed DLCs have no staged package root.
    -- Never concatenate nil from a synthetic installed-DLC candidate.
    if type(root) ~= "string" or root == "" then return {} end
    local p = root .. "\\modverse.manifest"
    local out = {}
    if not fileExists(p) then return out end
    local ok, raw = pcall(function() return FileMgr.ReadFileContent(p) end)
    if not ok or type(raw) ~= "string" then return out end
    for line in raw:gmatch("[^\r\n]+") do
        local kind, encoded = line:match("^([^\t]+)\t(.+)$")
        if kind == "FILE" and encoded then
            local rel = hexDecode(encoded)
            if rel ~= "" then out[#out + 1] = rel end
        end
    end
    return out
end

local function fileExistsDirect(path)
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return fileExists(path)
end


-- Restricted package paths for DLC manifest inspection and validated copying.
local ModVersePath152={}
function ModVersePath152.safeRoot(root)
    root=normalizePath(root)
    local base=normalizePath(MODS_DIR)
    if base:sub(-1)~="\\" then base=base.."\\" end
    if root:sub(1,#base):lower()~=base:lower() then return false end
    local leaf=root:sub(#base+1)
    return leaf~="" and leaf~="." and leaf~=".." and not leaf:find("\\",1,true) and not leaf:find(":",1,true)
end
function ModVersePath152.safeRelative(rel)
    rel=normalizePath(rel)
    if rel=="" or rel:sub(1,1)=="\\" or rel:find(":",1,true) then return nil end
    for part in rel:gmatch("[^\\]+") do
        if part=="." or part==".." then return nil end
    end
    return rel
end

-- Staged DLC status is based on verified files/receipts, not any executable scan.
local ModVerse071={}
function ModVerse071.receipt(item)
    if not item or not item.slug then return nil end
    return MODS_DIR .. sanitizeFileName(item.slug) .. "\\modverse_staged.receipt"
end
function ModVerse071.hasReceipt(item)
    local path=ModVerse071.receipt(item)
    return path~=nil and fileExistsDirect(path) and readBinaryPrefix(path,7)=="STAGED|"
end
function ModVerse071.saveReceipt(item,kind)
    local path=ModVerse071.receipt(item)
    return path~=nil and writeBinary(path,"STAGED|"..tostring(kind or "zip").."|"..tostring(item.slug).."\n")==true
end
local function isMarketItemInstalled(item)
    if not item or not item.slug then return false end
    if ModVerse071.hasReceipt(item) then return true end
    local root=normalizePath(MODS_DIR..sanitizeFileName(item.slug))
    for _,rel in ipairs(readManifest(root)) do
        if type(rel)=="string" and rel:lower():match("dlc%.rpf$")
          and fileExistsDirect(root.."\\"..rel) then return true end
    end
    return false
end
-- Detect archive types only, without extracting executable components.
local function detectPackage(data)
    if type(data)~="string" or #data<4 then return "unknown" end
    if data:sub(1,2)=="PK" then return "zip" end
    if data:sub(1,7)=="Rar!\026\007\000" or data:sub(1,8)=="Rar!\026\007\001\000" then return "rar" end
    if data:sub(1,6)=="7z\188\175\039\028" then return "7z" end
    if data:sub(1,2)=="MZ" then return "executable" end
    return "unknown"
end
local function extractDirectFileUrl(html)
    local src=tostring(html or ""):gsub("\\/","/")
    local url=src:match('(https://files%.gta5%-mods%.com/[^%s"\'<>]+)')
    if not url then return nil end
    return htmlDecode(url):gsub("[%)%],;}]+$",""):gsub(" ","%%20")
end
-- Only the GTA5-Mods DLC favorites remain; no ASI favorites or launch menus.
VehicleFav152={file=ROOT_DIR.."gta5mods_dlc_favorites.tsv",ids=nil}
function VehicleFav152.load()
    if VehicleFav152.ids then return end
    VehicleFav152.ids={}
    if not fileExists(VehicleFav152.file) then return end
    local raw=ModVerseHash152.read(VehicleFav152.file) or ""
    for id in raw:gmatch("[^\r\n]+") do if id:match("^[%w_%-]+$") then VehicleFav152.ids[id]=true end end
end
function VehicleFav152.contains(item)
    VehicleFav152.load()
    return item and VehicleFav152.ids[tostring(item.slug or "")] == true
end
function VehicleFav152.toggle(item)
    if not item or not tostring(item.slug or ""):match("^[%w_%-]+$") then return end
    VehicleFav152.load()
    local id=tostring(item.slug)
    VehicleFav152.ids[id]=not VehicleFav152.ids[id] and true or nil
    local keys={};for k in pairs(VehicleFav152.ids) do keys[#keys+1]=k end;table.sort(keys)
    if not writeBinary(VehicleFav152.file,table.concat(keys,"\n")) then toast("Could not save favorite",3500) end
end
-- Retains selected-vehicle details visibility without the removed ASI UI module.
local ModVerse061={moreDLC=false}
VehicleMarket055 = {
    page=1, items={}, selected=nil, loading=false, initialized=false,
    status="Not loaded", addOnOnly=false, lastRefresh=0,
    sort=1, since=1, search="",appliedSearch="",
    pendingForce=false, lastDiagnostic="", lastRequestUrl="",
}

function VehicleMarket055.pageUrl(page)
    return mv062CatalogUrl("vehicles",VehicleMarket055,page)
end

function VehicleMarket055.pagePath(page)
    return PAGE_CACHE_DIR .. "vehicle_market_062_"..mv062FilterKey(VehicleMarket055).."_p"..tostring(math.max(1,tonumber(page) or 1)) .. ".html"
end

function VehicleMarket055.classify(item)
    local name=tostring(item and item.name or ""):lower()
    if name:find("add%-on") or name:find("add on",1,true) or name:find("addon",1,true) then return "ADD-ON" end
    if name:find("replace",1,true) then return "REPLACE" end
    if name:find("fivem",1,true) then return "FIVEM / CHECK" end
    return "UNVERIFIED"
end

function VehicleMarket055.hydrate(item)
    MarketCache037.hydrateCachedItem(item)
    return item
end

-- B144: normalize trusted vehicle link variants from the public website.
-- This is a read-only HTML listing parser, not a DLL/ASI loader.
VehicleSearch144 = {}
function VehicleSearch144.parse(html)
    if type(html)~="string" then return {} end
    local src=html
    -- The site sometimes renders localized links (/gl/vehicles/slug), whereas
    -- the older catalog parser only accepts /vehicles/slug.
    src=src:gsub("\\/", "/")
    src=src:gsub("\\u002[Ff]", "/")
    src=src:gsub("/([%a][%a])/vehicles/", "/vehicles/")
    src=src:gsub("[Hh][Rr][Ee][Ff]%s*=", "href=")
    local cards=parseListing(src,"vehicles")
    if #cards>0 then return cards end
    -- Certain templates put the canonical vehicle URL into structured data.
    -- Accept only absolute URLs for the official domain, and only a strictly
    -- formatted /vehicles/<slug> path. Do not fetch arbitrary extracted links.
    local extras={}
    local seen={}
    for url in src:gmatch("https?://[%w%.%-]+/vehicles/[%w_%-]+") do
        local domain=url:match("^https?://([^/]+)/") or ""
        domain=domain:lower()
        if (domain=="gta5-mods.com" or domain:match("^[%w%-]+%.gta5%-mods%.com$"))
            and not seen[url:lower()] then
            seen[url:lower()]=true
            extras[#extras+1]='href="'..url..'"'
            if #extras>=MAX_MARKET_MODS_PER_PAGE then break end
        end
    end
    return #extras>0 and parseListing(table.concat(extras," "),"vehicles") or {}
end
function VehicleSearch144.fingerprint(html,err)
    if type(html)~="string" then return "no-body; curl="..tostring(err or "unknown") end
    local first=html:sub(1,32768)
    local lower=first:lower()
    local title=first:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>(.-)</[Tt][Ii][Tt][Ll][Ee]%s*>") or "unknown"
    title=title:gsub("<[^>]+>"," "):gsub("[%c|]"," "):gsub("%s+"," "):sub(1,90)
    local numAnchors=0
    for _ in first:gmatch("[Hh][Rr][Ee][Ff]%s*=") do numAnchors=numAnchors+1 end
    local numVehicles=0
    for _ in first:gmatch("/vehicles/[%w_%-]+") do numVehicles=numVehicles+1 end
    local kind="html-other"
    if lower:find("cf%-chl") or lower:find("challenge%-platform")
        or lower:find("verify you are human",1,true)
        or lower:find("checking your browser",1,true)
        or title:lower():find("just a moment",1,true) then kind="browser-verification"
    elseif lower:find("access denied",1,true) or title:lower():find("forbidden",1,true) then
        kind="access-denied"
    elseif lower:find("search results for",1,true) or lower:find("category: vehicles",1,true) then
        kind="search-page"
    elseif lower:find("no results",1,true) or lower:find("no matches",1,true) then
        kind="empty-results"
    end
    return "body="..#html.." bytes; kind="..kind.."; title="..title..
        "; hrefs="..numAnchors.."; vehicle_links="..numVehicles..
        (err and ("; curl="..tostring(err)) or "")
end
function VehicleSearch144.blocked(html)
    local summary=VehicleSearch144.fingerprint(html)
    return summary:find("kind=browser-verification",1,true)~=nil
        or summary:find("kind=access-denied",1,true)~=nil
end
function VehicleMarket055.searchUrl(page,variant)
    local V=VehicleMarket055
    local query=mv062SearchSegment(V.appliedSearch)
    page=math.max(1,math.floor(tonumber(page) or 1))
    if query=="" then return V.pageUrl(page) end
    local base="https://www.gta5-mods.com/gl/search/"
    if variant=="global" then
        base=base..query
    else
        base=base.."vehicles/"..query
        -- Preserve the user-selected sort/time when explicitly chosen; the
        -- unsuffixed vehicle search is the default (not /latest).
        if V.sort and V.sort~=1 then
            local so=MV062_SORT[V.sort] or MV062_SORT[1]
            base=base.."/"..so.search
        end
    end
    if page>1 then base=base.."/"..page end
    return base
end
function VehicleMarket055.fetch(page,force)
    local V=VehicleMarket055
    if V.loading then
        V.pendingFilter=true
        V.pendingForce=V.pendingForce or force==true
        V.status="Applying updated vehicle search after current network request..."
        return
    end
    V.initialized=true
    V.page=math.max(1,math.floor(tonumber(page) or 1))
    local requestedPage=V.page
    local requestedKey=mv062FilterKey(V)
    local query=tostring(V.appliedSearch or "")
    local url=(query~="") and V.searchUrl(requestedPage,"vehicles") or V.pageUrl(requestedPage)
    V.lastRequestUrl=url
    V.lastDiagnostic=""
    local old=MarketCache037.readCachedText(V.pagePath(V.page))
    local cached=old and VehicleSearch144.parse(old) or {}
    for _,item in ipairs(cached) do V.hydrate(item); item.market_page_url=url end
    if #cached>0 then
        V.items=cached
        V.selected=cached[1]
        V.status=string.format("Cached vehicle %s: %d listings",query~="" and ("search '"..query.."'") or ("page "..V.page),#cached)
        if not force then return end
    else
        V.items={};V.selected=nil
        V.status=string.format("Searching GTA5-Mods vehicles%s...",query~="" and (" for '"..query.."'") or (" (page "..V.page..")"))
    end
    V.loading=true
    local function superseded()
        return V.pendingFilter==true or requestedPage~=V.page or requestedKey~=mv062FilterKey(V)
    end
    Script.QueueJob(function()
        local ok,problem=pcall(function()
            local headers={"Accept: text/html,application/xhtml+xml;q=0.9,*/*;q=0.5","Cache-Control: no-cache"}
            local html,err=httpGet(url,20000,"https://www.gta5-mods.com/vehicles",headers,USER_AGENT)
            if superseded() then return end
            local items=VehicleSearch144.parse(html)
            local usedUrl=url
            local fpPrimary=VehicleSearch144.fingerprint(html,err)
            local fpFallback="not-tried"
            -- A failed vehicle-specific search may be due to a changed layout.
            -- Official global search is a complementary published route; only
            -- vehicle-category URLs are admitted from those results.
            if #items==0 and query~="" and not VehicleSearch144.blocked(html) then
                local fallback=V.searchUrl(requestedPage,"global")
                if fallback~=url then
                    V.status="Trying GTA5-Mods global search (vehicles only)..."
                    local alt,altErr=httpGet(fallback,18000,"https://www.gta5-mods.com/vehicles",headers,USER_AGENT)
                    if superseded() then return end
                    local altItems=VehicleSearch144.parse(alt)
                    fpFallback=VehicleSearch144.fingerprint(alt,altErr)
                    if #altItems>0 then
                        html,items,usedUrl=alt,altItems,fallback
                    end
                end
            end
            if #items==0 then
                local reason
                if VehicleSearch144.blocked(html) then
                    reason="Website returned a verification or access-denied page; no browser bypass attempted"
                elseif type(html)~="string" then
                    reason="No website response received"
                else
                    reason="No vehicle listings recognized (empty search or unsupported website markup)"
                end
                V.status=(query~="" and ("Search '"..query.."': ") or "Vehicle catalog: ")..reason
                V.lastDiagnostic="ModVerse 144 VEHICLE SEARCH | query="..query.." | page="..requestedPage..
                    " | primary="..url.." | "..fpPrimary.." | fallback="..fpFallback.." | reason="..reason
                log("[VEHICLE144][SEARCH] "..V.lastDiagnostic)
                return
            end
            if superseded() then return end
            writeBinary(V.pagePath(requestedPage),html)
            for _,item in ipairs(items) do item.market_page_url=usedUrl; V.hydrate(item) end
            V.items=items;V.selected=items[1]
            V.status=string.format("Vehicle %s: %d listings found; fetching preview details...",query~="" and ("search '"..query.."'") or ("page "..requestedPage),#items)
            V.lastDiagnostic="ModVerse 144 VEHICLE SEARCH | query="..query.." | page="..requestedPage..
                " | route="..usedUrl.." | listings="..#items.." | primary="..fpPrimary.." | fallback="..fpFallback
            for i,item in ipairs(items) do
                if superseded() then return end
                local detailHtml=nil
                if not (item.cache_hit and item.details_loaded and item.thumb_path and item.thumb_path~="") then
                    V.status=string.format("Vehicle previews %d/%d; Find/Clear can interrupt",i,#items)
                    detailHtml=httpGet(item.page_url,12000,usedUrl)
                end
                if superseded() then return end
                if detailHtml then
                    parseDetail(item,detailHtml)
                    local thumb=findCachedThumb(item)
                    if thumb then item.thumb_path=thumb;item.thumb_status="ready"
                    else item.thumb_status="waiting";ensureThumbnail(item) end
                elseif not item.cache_hit then
                    item.details_loaded=false;item.thumb_status="failed"
                end
                Script.Yield(30)
            end
            if not superseded() then
                V.status=string.format("Vehicle Marketplace ready: %s, %d listings",query~="" and ("search '"..query.."'") or ("page "..requestedPage),#items)
            end
        end)
        if not ok then
            V.status="Vehicle catalog error: "..tostring(problem)
            V.lastDiagnostic="ModVerse 144 VEHICLE SEARCH ERROR | url="..tostring(url).." | "..tostring(problem)
            log("[VEHICLE144][ERROR] "..tostring(problem))
        end
        V.loading=false;V.lastRefresh=nowMs()
        if V.pendingFilter then
            V.pendingFilter=false;V.pendingForce=false
            V.fetch(V.page,true)
        end
    end)
end

function VehicleMarket055.candidateFor(item)
    local root=normalizePath(MODS_DIR..sanitizeFileName(item.slug)):lower()
    local found,firstIndex={}
    for i,row in ipairs((DLC054 and DLC054.rows) or {}) do
        if normalizePath(row.root):lower()==root then
            found[#found+1]=row
            firstIndex=firstIndex or i
        end
    end
    return found[1],firstIndex,#found
end

function VehicleMarket055.onClick(item)
    -- Build 142: selecting a catalog card must never download or install files.
    -- The separate Download + Auto Install button requires an explicit click.
    VehicleMarket055.selected=item
end

function VehicleMarket055.tile(item,w)
    local h,imgH=178,118
    local x,y=cursorScreenPos()
    ImGui.PushID("MODVERSE_VEHICLE_"..tostring(item.slug))
    local clicked=ImGui.InvisibleButton("##tile",w,h)
    local hovered=ImGui.IsItemHovered()
    drawImageCardBackground(x,y,w,h,hovered,VehicleMarket055.selected==item)
    local srv=item.thumb_path and textureSrv(item.thumb_path) or nil
    if srv then
        if ImGui.AddImageRounded then
            ImGui.AddImageRounded(srv,x+3,y+3,x+w-3,y+imgH,0,0,1,1,0xFFFFFFFF,6.0)
        else ImGui.AddImage(srv,x+3,y+3,x+w-3,y+imgH) end
    else
        ImGui.AddRectFilled(x+3,y+3,x+w-3,y+imgH,34,38,52,255,6.0)
        ImGui.AddText(x+12,y+47,item.thumb_status=="failed" and "NO THUMBNAIL" or "LOADING IMAGE...",170,175,190,255)
    end
    ImGui.AddRectFilled(x+3,y+imgH-2,x+w-3,y+h-3,16,18,27,250,0.0)
    local chars=math.max(16,math.floor(w/7.1))
    ImGui.AddText(x+8,y+imgH+5,shortText(item.name or item.slug,chars),250,250,255,255)
    ImGui.AddText(x+8,y+imgH+24,shortText((item.author and item.author~="") and ("By "..item.author) or "GTA5-Mods Vehicles",chars),170,178,198,255)
    local installed=isMarketItemInstalled(item)
    -- The removed ASI tag index is not part of marketplace-only builds.
    -- Show the DLC staging state directly instead of calling a deleted module.
    ImGui.AddText(x+8,y+imgH+42,
        VehicleMarket055.classify(item)..(installed and "  |  STAGED" or "  |  DLC PACKAGE"),
        146,191,220,255)
    if installed then
        ImGui.AddRectFilled(x+8,y+8,x+84,y+27,20,92,55,235,4.0)
        ImGui.AddText(x+14,y+10,"STAGED",130,255,180,255)
    end
    if hovered and ImGui.BeginTooltip then
        ImGui.BeginTooltip()
        ImGui.Text(item.name or item.slug)
        ImGui.Text("Listing: "..VehicleMarket055.classify(item))
        ImGui.Text("Click to inspect. Download / install requires a separate button.")
        ImGui.EndTooltip()
    end
    mv062DrawStar(item,"dlc",x,y,w)
    if clicked then
        if mv062TileStarClicked(x,y,w) then VehicleFav152.toggle(item)
        else VehicleMarket055.onClick(item) end
    end
    ImGui.PopID()
end

function VehicleMarket055.grid()
    local V=VehicleMarket055
    local items={}
    for _,item in ipairs(V.items) do
        if not V.addOnOnly or V.classify(item)=="ADD-ON" then items[#items+1]=item end
    end
    if #items==0 then
        safeTextWrapped("No matching listings on this page. Try disabling Add-On only, or use the pagination buttons.")
        return
    end
    local avail=select(1,contentAvail())
    local columns=math.max(2,math.min(5,math.floor(avail/205)))
    local tileW=math.max(168,(avail-((columns-1)*10))/columns-6)
    if ImGui.BeginTable("ModVerseVehicleMarketGrid",columns,ImGuiTableFlags.SizingStretchSame) then
        for _,item in ipairs(items) do
            ImGui.TableNextColumn()
            V.tile(item,tileW)
        end
        ImGui.EndTable()
    end
end

function VehicleMarket055.details()
    local item=VehicleMarket055.selected
    ImGui.Separator()
    if not item then safeTextWrapped("Select a vehicle listing to see details.");return end
    ImGui.TextColored(0.76,0.48,1.00,1.00,item.name or item.slug)
    if item.author and item.author~="" then
        ImGui.SameLine(); ImGui.TextColored(0.62,0.66,0.74,1.0,"by "..item.author)
    end
    ImGui.TextColored(0.58,0.76,0.91,1.0,VehicleMarket055.classify(item))
    -- Build 153: ASI/file-type tagging was removed in Build 152.
    -- This is a GTA5-Mods ready-made DLC listing; no legacy tags to display.
    if ImGui.Button(ModVerse061 and ModVerse061.moreDLC and "Less##descDLC061" or "Info##descDLC061",80,24) then
        ModVerse061.moreDLC=not ModVerse061.moreDLC
    end
    if ModVerse061 and ModVerse061.moreDLC then
        mv153DLCUsageHints(item)
        safeTextWrapped(item.description or "No info")
    end
    ImGui.Spacing()
    local staged=isMarketItemInstalled(item)
    local row,index,count=VehicleMarket055.candidateFor(item)
    if item.installing then
        -- Build 070: progress is shown in a separate ImGui window.
    elseif not staged then
        if ImGui.Button("Download + Auto Install##VEH056",224,32) then VehicleMarket055.downloadInstall(item) end
    else
        ImGui.TextColored(0.35,1.00,0.62,1.0,"Package staged in ModVerse")
        if DLC054 and DLC054.dirty and not DLC054.busy then DLC054.scan() end
        row,index,count=VehicleMarket055.candidateFor(item)
        if count and count>1 then
            safeTextWrapped(tostring(count).." RPF variants detected. Choose the correct package in Installed > DLCs before installing. No automatic selection.")
        elseif row and row.valid and not row.exists and not DLC054.busy then
            if ImGui.Button("Auto Install Verified DLC##VEH056",215,34) then
                VehicleMarket055.autoInstall(item)
            end
        elseif row and row.exists then
            safeTextWrapped("Cherax DLC folder exists: "..tostring(row.name).." (no overwrite). Load/refresh it in Cherax before spawning.")
        elseif row and not row.valid then
            safeTextWrapped("DLC candidate cannot be installed: "..tostring(row.detail))
        else
            safeTextWrapped("No verified ready-made dlc.rpf found. This may be a REPLACE, FiveM-only, or loose-asset package. Check the extracted files; no automatic RPF conversion.")
        end
        if row and row.valid and VehicleMarket055.isInstalled(row) then
            local suggestion=VehicleMarket055.modelName(item,row)
            local input=ImGui.InputText("Spawn model##VEH056",suggestion,70)
            if type(input)=="string" then VehicleMarket055.modelNames[item.slug]=input end
            if ImGui.Button("Spawn "..VehicleMarket055.modelName(item,row).."##VEH056",192,34) then
                VehicleMarket055.spawn(item,row)
            end
            if VehicleMarket055.spawning[item.slug] then ImGui.SameLine();ImGui.Text("Loading model...") end
            if VehicleMarket055.spawnStatus[item.slug] then safeTextWrapped(VehicleMarket055.spawnStatus[item.slug]) end
            safeTextWrapped("Spawn is local-only and requires Cherax to have loaded the DLC. Folder names are guesses until the model successfully streams.")
        end
        if ImGui.Button("Open DLC Manager##VEH055",176,30) then
            UI.activeTab="DLC Manager"
            if DLC054 then
                DLC054.dirty=true
                if index then DLC054.selected=index end
            end
        end
    end
    if item.installing or staged then ImGui.SameLine() end
    if ImGui.Button("Copy Mod Link##VEH055",145,32) then
        mv063PageLink(item)
    end
    -- Keep only actionable failures inline; live progress belongs to the ImGui window.
    if not item.installing and type(item.install_status)=="string" and
       (item.install_status:lower():find("fail",1,true) or
        item.install_status:lower():find("error",1,true)) then
        safeTextWrapped("Error: "..shortText(item.install_status,140))
    end

end


-- Build 057: automatic verified DLC install, honest progress and local spawn probe.
-- Worker downloads expose measured byte percentages; Curl fallback does not.
VehicleMarket055.progress={}
VehicleMarket055.modelNames={}
VehicleMarket055.spawnStatus={}
VehicleMarket055.spawning={}

function VehicleMarket055.progressStep(item,phase,fraction,a,b)
    if not item or not item.slug then return end
    local p=VehicleMarket055.progress[item.slug] or {}
    p.phase=phase
    p.fraction=type(fraction)=="number" and math.max(0,math.min(1,fraction)) or nil
    p.extra=a
    p.total=b
    p.updated=nowMs()
    VehicleMarket055.progress[item.slug]=p
    -- per-item progress is local; native progress overlay was removed
end

function VehicleMarket055.modelName(item,candidate)
    if not item then return "" end
    local V=VehicleMarket055
    local saved=V.modelNames[item.slug]
    if type(saved)=="string" and saved~="" then return saved end
    -- Prefer an actual loose vehicles.meta when supplied by a package; DLC-RPF
    -- internal metadata cannot be reliably inspected by this basic file scanner.
    if candidate and type(candidate.root)=="string" and candidate.root~="" then
        local paths=readManifest(candidate.root)
        for _,relative in ipairs(paths or {}) do
            local safe=ModVersePath152.safeRelative(relative)
            if safe and basename(safe):lower()=="vehicles.meta" then
                local fname=normalizePath(candidate.root).."\\"..safe
                local f=io.open(fname,"rb")
                if f then
                    local raw=f:read(512*1024) or "";f:close()
                    local name=raw:match("<modelName>%s*([%w_]+)%s*</modelName>")
                    if name then V.modelNames[item.slug]=name;return name end
                end
            end
        end
    end
    local name=candidate and candidate.name or tostring(item.slug or "")
    if not tostring(name):match("^[%w_]+$") then return "" end
    return name -- fallback guess, verified by model streaming before spawn
end

function VehicleMarket055.isInstalled(candidate)
    if not candidate or not candidate.valid then return false end
    local dest=DLC054.targetPath(candidate.name)
    if not dest or not fileExistsDirect(dest) then return false end
    local good=DLC054.validate(dest)
    return good==true
end

function VehicleMarket055.autoInstall(item)
    local V=VehicleMarket055
    if not DLC054 or DLC054.busy then
        V.progressStep(item,"waiting",nil)
        item.install_status="DLC installer busy. Retry this vehicle after the current install."
        return false
    end
    DLC054.dirty=true;DLC054.lastScanMs=0;DLC054.scan(true)
    local row,index,count=V.candidateFor(item)
    if not row then
        V.progressStep(item,"no_dlc",nil)
        item.install_status="Downloaded; no ready-made dlc.rpf. Replacement/loose assets cannot auto-convert yet."
        return false
    end
    if count~=1 then
        V.progressStep(item,"variant",nil)
        item.install_status="Multiple DLC variants detected. Choose the correct version in Installed > DLCs."
        return false
    end
    if not row.valid then
        V.progressStep(item,"error",nil)
        item.install_status="DLC RPF failed validation: "..tostring(row.detail)
        return false
    end
    if row.exists or V.isInstalled(row) then
        V.progressStep(item,"installed",1)
        item.install_status="Cherax DLC already exists; original preserved. Load/refresh it in Cherax, then Spawn."
        return true
    end
    V.progressStep(item,"copy",0,0,row.size)
    local started=DLC054.install(row,function(ok,detail)
        if ok then
            V.progressStep(item,"installed",1)
            item.install_status="DLC installed to Cherax\\DLCs\\"..row.name.."\\dlc.rpf. Load/refresh it in Cherax to spawn."
            log("[VEH056][INSTALLED] "..tostring(item.slug).." "..tostring(row.name))
            if ModVerseTutorial147 then ModVerseTutorial147.open("dlcs","install") end
        else
            V.progressStep(item,"error",nil)
            item.install_status="DLC install error: "..tostring(detail)
        end
    end,function(written,total)
        V.progressStep(item,"copy",total>0 and written/total or nil,written,total)
    end)
    if not started then
        V.progressStep(item,"error",nil)
        item.install_status="DLC installation not started: "..tostring(DLC054.status)
    end
    return started
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- gta5-mods dlc-only zip delivery / build 142
-- note: uses only Cherax Curl, pure-Lua ZIP, and DLC054's verified file copy.
--       never launches native helpers or downloads loose executables for this feature.
-- ═══════════════════════════════════════════════════════════════════════════════════
ModVerseDLC142 = { maxBytes=MAX_DOWNLOAD_BYTES, status="ready" }

function ModVerseDLC142.preflight(zip)
    if type(zip)~="string" or #zip<22 or zip:sub(1,2)~="PK" then
        return false,"Invalid ZIP data"
    end
    local eocd=findEocd(zip)
    if not eocd then return false,"ZIP directory not found" end
    local disk=u16le(zip,eocd+4)
    local cdDisk=u16le(zip,eocd+6)
    local entriesOnDisk=u16le(zip,eocd+8)
    local count=u16le(zip,eocd+10)
    local cdSize=u32le(zip,eocd+12)
    local cdOffset=u32le(zip,eocd+16)
    if not count or not cdOffset or not cdSize or count==0 or count>ZIP_MAX_ENTRIES then
        return false,"ZIP entry count unsupported"
    end
    if disk~=0 or cdDisk~=0 or entriesOnDisk~=count or count==65535 or cdSize==4294967295 then
        return false,"Multi-disk/ZIP64 archives unsupported"
    end
    if cdOffset+cdSize > #zip or cdOffset+1 < 1 then
        return false,"ZIP directory outside file"
    end
    local at=cdOffset+1
    local foundRpf=0
    local expanded=0
    for i=1,count do
        if at+45>#zip or zip:sub(at,at+3)~="PK\001\002" then
            return false,"Broken ZIP central directory at entry "..i
        end
        local flags=u16le(zip,at+8)
        local method=u16le(zip,at+10)
        local compressed=u32le(zip,at+20)
        local uncompressed=u32le(zip,at+24)
        local nameLen=u16le(zip,at+28)
        local extraLen=u16le(zip,at+30)
        local commentLen=u16le(zip,at+32)
        if not flags or not method or not compressed or not uncompressed or not nameLen or not extraLen or not commentLen then
            return false,"Incomplete ZIP entry"
        end
        if (flags & 1)~=0 or (method~=0 and method~=8) then
            return false,"Encrypted/unsupported ZIP entry"
        end
        if uncompressed>ZIP_MAX_FILE_BYTES then return false,"ZIP file too large" end
        expanded=expanded+uncompressed
        if expanded>ZIP_MAX_TOTAL_BYTES then return false,"ZIP expanded size exceeds limit" end
        local name=zip:sub(at+46,at+45+nameLen)
        local rel,reason=safeZipRelativePath(name)
        if not rel then return false,"Unsafe ZIP path: "..tostring(reason) end
        local lower=rel:lower()
        if lower:match("%.asi$") or lower:match("%.dll$") or lower:match("%.exe$")
            or lower:match("%.com$") or lower:match("%.msi$") or lower:match("%.bat$")
            or lower:match("%.cmd$") or lower:match("%.ps1$") or lower:match("%.vbs$")
            or lower:match("%.js$") or lower:match("%.scr$") or lower:match("%.lnk$") then
            return false,"Package includes executable content: "..basename(rel)
        end
        if basename(lower)=="dlc.rpf" then foundRpf=foundRpf+1 end
        at=at+46+nameLen+extraLen+commentLen
        if at>cdOffset+cdSize+1 then return false,"ZIP directory bounds exceeded" end
    end
    if foundRpf==0 then
        return false,"No ready-made dlc.rpf found. Replacement/loose asset mods need manual conversion."
    end
    return true,foundRpf
end

function ModVerseDLC142.fetchZip(item)
    local url=item.download_url
    local referer=item.page_url
    local visited={}
    for hop=1,4 do
        if type(url)~="string" or (not url:match("^https://www%.gta5%-mods%.com/")
            and not url:match("^https://files%.gta5%-mods%.com/")) then
            return nil,"Download destination outside GTA5-Mods allowlist"
        end
        if visited[url] then return nil,"Repeated download redirect" end
        visited[url]=true
        local data,err=httpGet(url,60000,referer,{PACKAGE_ACCEPT,"Cache-Control: no-cache"},USER_AGENT)
        if not data then return nil,"Download failed: "..tostring(err) end
        if #data>ModVerseDLC142.maxBytes then return nil,"Download exceeds 128 MB limit" end
        local kind=detectPackage(data)
        if kind=="zip" then return data,nil end
        if kind=="executable" or (kind=="rar" or kind=="7z") then
            return nil,"Only ZIP DLC packages are supported; received "..tostring(kind)
        end
        local nextUrl=extractDirectFileUrl(data)
        if not nextUrl or nextUrl==url then
            return nil,"No valid direct ZIP download URL ("..tostring(kind)..")"
        end
        referer=url
        url=nextUrl
    end
    return nil,"Too many download redirects"
end

function ModVerseDLC142.fail(item,reason)
    item.installing=false
    item.install_status=tostring(reason)
    VehicleMarket055.progressStep(item,"error",nil)
    log("[DLC142][ERROR] "..tostring(item.slug).." "..item.install_status)
    toast(item.install_status,5500)
end

function ModVerseDLC142.stage(item)
    if not item or item.installing then return false end
    if not (Script and Script.QueueJob) then return false end
    item.installing=true
    VehicleMarket055.progressStep(item,"details",nil)
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local page=httpGet(item.page_url,18000,item.market_page_url or VEHICLE_MARKET_BASE)
            if page then parseDetail(item,page) end
            if not item.download_url then error("GTA5-Mods download link unavailable") end
            VehicleMarket055.progressStep(item,"download",nil)
            local zip,fetchErr=ModVerseDLC142.fetchZip(item)
            if not zip then error(fetchErr) end
            local allowed,details=ModVerseDLC142.preflight(zip)
            if not allowed then error(details) end
            VehicleMarket055.progressStep(item,"download_done",1,#zip)
            local archive=DOWNLOAD_DIR..sanitizeFileName(item.slug)..".zip"
            if not writeBinary(archive,zip) then error("Unable to save ZIP archive") end
            local root=MODS_DIR..sanitizeFileName(item.slug)
            FileMgr.CreateDir(root)
            VehicleMarket055.progressStep(item,"extract",0)
            local extracted,method,asis,all=extractZipPureLua(archive,root,
                function(_,fraction,a,b) VehicleMarket055.progressStep(item,"extract",fraction,a,b) end)
            if not extracted then error("ZIP extraction failed: "..tostring(method)) end
            if type(asis)=="table" and #asis>0 then error("Unexpected ASI after extraction") end
            if type(all)~="table" or #all==0 then error("ZIP extraction returned no files") end
            writeMeta(root,item)
            writeManifest(root,all)
            registerInstallRoot(root)
            ModVerse071.saveReceipt(item,"zip")
            item.installing=false
            item.just_installed=true
            VehicleMarket055.progressStep(item,"scan",nil)
            DLC054.dirty=true
            DLC054.lastScanMs=0
            DLC054.scan(true)
            item.install_status="ZIP staged. Checking for one supported ready-made DLC."
            VehicleMarket055.autoInstall(item)
        end)
        if not ok then ModVerseDLC142.fail(item,err) end
    end)
    return true
end

function VehicleMarket055.downloadInstall(item)
    if not item or item.installing then return end
    if isMarketItemInstalled(item) then
        DLC054.dirty=true;DLC054.lastScanMs=0;DLC054.scan(true)
        VehicleMarket055.autoInstall(item)
        return
    end
    return ModVerseDLC142.stage(item)
end

function VehicleMarket055.spawn(item,candidate)
    if not item or not candidate or not VehicleMarket055.isInstalled(candidate) then return end
    local V=VehicleMarket055
    if V.spawning[item.slug] then return end
    local model=V.modelName(item,candidate):gsub("^%s+",""):gsub("%s+$","")
    if #model<1 or #model>70 or not model:match("^[%w_]+$") then
        V.spawnStatus[item.slug]="Enter a valid spawn model name (letters, numbers, underscore)."
        return
    end
    if not (GTA and type(GTA.SpawnVehicle)=="function" and Utils and Utils.Joaat
        and ModVerse067 and ModVerse067.streamReady() and Script and Script.QueueJob and Script.Yield) then
        V.spawnStatus[item.slug]="Native vehicle spawn unavailable."
        return
    end
    V.spawning[item.slug]=true
    V.spawnStatus[item.slug]="Requesting vehicle model "..model.."..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local hash=Utils.Joaat(model)
            local loaded=false
            local t=nowMs()
            while nowMs()-t<10000 do
                local exists=ModVerse067.modelInGame(hash)
                if exists~=false then ModVerse067.requestModel(hash) end
                if ModVerse067.hasModel(hash) then loaded=true;break end
                Script.Yield(125)
            end
            if not loaded then
                V.spawnStatus[item.slug]="Model unavailable. Refresh/load the DLC in Cherax first, or correct the model name."
                return
            end
            if not (PLAYER and PLAYER.PLAYER_PED_ID and ENTITY and ENTITY.GET_ENTITY_COORDS) then
                V.spawnStatus[item.slug]="Entity position APIs unavailable; spawn stopped safely."
                return
            end
            local ped=PLAYER.PLAYER_PED_ID()
            local pos=ENTITY.GET_ENTITY_COORDS(ped,true)
            if not pos then error("Local player coordinates unavailable") end
            local x=tonumber(pos.x or pos.X or pos[1])
            local y=tonumber(pos.y or pos.Y or pos[2])
            local z=tonumber(pos.z or pos.Z or pos[3])
            if not x or not y or not z then error("Player coordinates invalid") end
            local heading=0
            if ENTITY.GET_ENTITY_HEADING then
                local hok,h=pcall(ENTITY.GET_ENTITY_HEADING,ped)
                if hok and tonumber(h) then heading=tonumber(h) end
            end
            local rad=math.rad(heading)
            local sx=x-math.sin(rad)*6
            local sy=y+math.cos(rad)*6
            -- Local, non-networked spawn only: a custom texture cannot be
            -- replicated to peers merely by creating a network vehicle.
            local handle=GTA.SpawnVehicle(hash,sx,sy,z+0.5,heading,false,true)
            if not handle or handle==0 then error("Native spawn returned no vehicle") end
            V.spawnStatus[item.slug]="Spawned "..model.." locally (entity "..tostring(handle)..")."
            log("[VEH056][SPAWN] model="..model.." local=true handle="..tostring(handle))
            ModVerse067.releaseModel(hash)
        end)
        if not ok then
            V.spawnStatus[item.slug]="Spawn failed: "..tostring(err)
            log("[VEH056][SPAWN_ERROR] "..tostring(err))
        end
        V.spawning[item.slug]=false
    end)
end

function VehicleMarket055.progressUI(item)
    local p=item and VehicleMarket055.progress[item.slug]
    if not p then return end
    local labels={details="Fetching details",download="Downloading package",download_done="Download complete",
        extract="Extracting archive",extract_wait="Extracting archive in Windows",extract_done="Extraction complete",
        inventory="Inventorying assets",staged="Extracted / staged",scan="Verifying DLC",copy="Copying DLC",
        installed="DLC installed",variant="Manual version selection needed",no_dlc="No installable RPF found",
        waiting="DLC installer occupied",error="Operation stopped"}
    local lbl=labels[p.phase] or tostring(p.phase)
    if p.phase=="extract" and p.total and p.total>0 then
        lbl=lbl.." ("..tostring(p.extra or 0).."/"..tostring(p.total).." files)"
    elseif p.phase=="copy" and tonumber(p.total) and p.total>0 then
        lbl=lbl..string.format(" (%.1f/%.1f MB)",(p.extra or 0)/1048576,p.total/1048576)
    elseif p.phase=="download" and tonumber(p.extra) then
        if tonumber(p.total) and p.total>0 then
            lbl=lbl..string.format(" (%.1f / %.1f MB)",p.extra/1048576,p.total/1048576)
        else
            lbl=lbl..string.format(" (%.1f MB received; total unknown)",p.extra/1048576)
        end
    elseif p.phase=="download_done" and tonumber(p.extra) then
        lbl=lbl..string.format(" (%.1f MB)",p.extra/1048576)
    end
    if type(p.fraction)=="number" and (p.phase=="copy" or p.phase=="extract" or p.phase=="download" or p.phase=="download_done" or p.phase=="installed") then
        lbl=lbl..string.format(" - %d%%",math.floor(p.fraction*100+0.5))
    end
    ImGui.TextColored(0.70,0.82,1,1,lbl)
    local avail=select(1,contentAvail())
    local w=math.max(160,math.min(avail-12,680))
    local x,y=cursorScreenPos()
    ImGui.AddRectFilled(x,y,x+w,y+13,27,30,43,255,4)
    if type(p.fraction)=="number" then
        local filled=math.max(0,math.min(w,p.fraction*w))
        if filled>0 then ImGui.AddRectFilled(x,y,x+filled,y+13,100,176,244,245,4) end
    else
        -- Indeterminate pulse, not a fabricated download percentage.
        local t=(nowMs()%1800)/1800
        local bar=w*0.23
        local start=x+t*(w+bar)-bar
        ImGui.AddRectFilled(math.max(x,start),y,math.min(x+w,start+bar),y+13,150,120,250,220,4)
    end
    ImGui.Dummy(w,17)
    if p.phase=="download" and type(p.fraction)~="number" then
        ImGui.TextColored(0.65,0.69,0.79,1,"Waiting for download size, or using Cherax fallback (no live byte counters).")
    elseif p.phase=="extract_wait" then
        ImGui.TextColored(0.65,0.69,0.79,1,"External extractor running; percentage begins during verified file transfer.")
    end
end

function VehicleMarket055.render()
    local V=VehicleMarket055
    if not V.initialized and not V.loading then V.fetch(V.page) end
    ImGui.TextColored(0.76,0.48,1.00,1.00,"Vehicles")
    ImGui.SameLine(); ImGui.TextColored(0.62,0.65,0.73,1.0,"Local-only add-ons")
    if ModVerseProd118.details.marketplace then
        ImGui.TextColored(0.62,0.67,0.76,1.0,"ZIP-only automatic installation; RAR/7Z requires manual extraction")
    end

    ImGui.Text("Search");ImGui.SameLine()
    mv063SearchBox("DLC",V)
    ImGui.SameLine()
    if ImGui.Button("Find##mvSearchGoDLC",54,25) then
        V.appliedSearch=V.search:match("^%s*(.-)%s*$") or ""
        V.page=1;V.fetch(1,true)
    end
    ImGui.SameLine()
    if ImGui.Button("Clear##mvSearchClearDLC",54,25) then
        V.search="";V.appliedSearch="";V.page=1;V.fetch(1)
    end
    mv062FilterPicker("dlc",V,function() V.fetch(1) end)
    if V.appliedSearch~="" then ImGui.TextColored(0.65,0.7,0.85,1,"Search: "..shortText(V.appliedSearch,35)) end

    if ImGui.Button("< Previous##VEH055",110,28) and V.page>1 then V.fetch(V.page-1) end
    ImGui.SameLine()
    if ImGui.Button("Refresh##VEH055",100,28) then V.fetch(V.page,true) end
    ImGui.SameLine()
    if ImGui.Button("Next >##VEH055",100,28) then V.fetch(V.page+1) end
    ImGui.SameLine();ImGui.Text("Page "..tostring(V.page))
    ImGui.SameLine()
    local c=ImGui.Button(V.addOnOnly and "Show All Vehicles##VEH055" or "Add-On Only##VEH055",160,28)
    if c then V.addOnOnly=not V.addOnOnly end
    if ModVerseProd120.showStatus(V.status,V.loading) or #V.items==0 or V.appliedSearch~="" then
        ImGui.TextColored(V.loading and 1 or 0.86,V.loading and 0.78 or 0.55,0.46,1.0,shortText(V.status,140))
    end
    if V.lastDiagnostic~="" then
        if ImGui.Button("Copy Search Diagnostics##VEH144",205,24) then
            pcall(function() Utils.SetClipBoardText(V.lastDiagnostic,"") end)
            toast("Search diagnostics copied",2300)
        end
    end
    ImGui.Separator()
    if #V.items==0 then
        safeTextWrapped(V.loading and "Contacting GTA5-Mods; results will appear when the request completes." or
            (V.status~="" and V.status or "No vehicle listings found. Try Clear or Refresh."))
    else
        -- Build 149: scroll vehicle/DLC cards only. Details and the explicit
        -- Download + Auto Install button stay visible immediately BELOW them.
        if ImGui.BeginChild then ImGui.BeginChild("ModVerseVehicleGridScroll",0,300,true) end
        V.grid()
        if ImGui.EndChild then ImGui.EndChild() end
        V.details()
    end
end
do
-- ==========================================================================
-- MODVERSE COMMUNITY THEMES - BUILD 078 (GitHub catalog, download-only)
-- Standalone marketplace branch: no ASI, ScriptHook, game directory, or game
-- asset modifications. Catalog files are treated as UNTRUSTED remote data.
-- ==========================================================================
-- Build 123: Production thumbnail Favorites for Vehicles, DLCs and Themes; no Vehicle Marketplace private-review buttons.
-- Build 122: compact, local-only filters for Cherax catalogs and saved libraries.
-- Filtering occurs after validation and before pagination; no downloader or scanner changes.
MV122Filters={states={},catalogMemo={}}
function MV122Filters.state(key)
    if not MV122Filters.states[key] then MV122Filters.states[key]={sort=1,show=1,extra=1} end
    return MV122Filters.states[key]
end
function MV122Filters.choice(key,field,title,choices,width)
    local cfg=MV122Filters.state(key)
    local value=cfg[field] or 1
    if not choices[value] then value=1;cfg[field]=1 end
    if ImGui.SetNextItemWidth then ImGui.SetNextItemWidth(width or 145) end
    local changed=false
    if ImGui.BeginCombo(title..'##MV122_'..key..'_'..field,choices[value]) then
        for i,name in ipairs(choices) do
            if ImGui.Selectable(name..'##MV122Option'..key..field..i,value==i) and i~=value then
                cfg[field]=i;changed=true
            end
        end
        ImGui.EndCombo()
    end
    return changed
end
function MV122Filters.bar(key,kind,customExtras)
    local cfg=MV122Filters.state(key)
    local localView=kind:sub(1,5)=='local'
    local sorts=localView and {'Default','Reverse','Name A-Z','Name Z-A'}
        or {'Default','Name A-Z','Name Z-A','Creator A-Z','Creator Z-A'}
    local available=select(1,contentAvail()) or 720
    local changed=MV122Filters.choice(key,'sort','Sort',sorts,133)
    do
        if available>=340 then ImGui.SameLine() end
        local localFav=(kind=='localoutfits' or kind=='localvehicles' or kind=='localdlcs')
        if MV122Filters.choice(key,'show','Show',
            localFav and {'All','Favorites'} or {'All','Favorites','Installed','Not installed'},140) then changed=true end
    end
    local extras=({
        outfits={'All images','Source photos','Gameplay JPGs','Catalog art','No JPG'},
        dlcs={'All images','Source photos','Gameplay JPGs','Catalog art','No JPG'},
        themes={'All archives','ZIP','RAR','7Z'},
        localdlcs={'All files','RPF7 header','Unverified'},
    })[kind]
    extras=customExtras or extras
    if extras then
        cfg.extraNames=customExtras
        if cfg.extra>#extras then cfg.extra=1;changed=true end
        if available>=495 or ((kind=='localdlcs' or kind=='localvehicles') and available>=330) then ImGui.SameLine() end
        if MV122Filters.choice(key,'extra',kind=='themes' and 'Format' or (kind=='localdlcs' and 'RPF' or (kind=='localvehicles' and 'Class' or 'Image')),extras,146) then changed=true end
    end
    if cfg.sort~=1 or cfg.show~=1 or cfg.extra~=1 then
        if available>=660 or (kind=='vehicles' and available>=430) then ImGui.SameLine() end
        if ImGui.Button('Reset##MV122_'..key,62,23) then
            cfg.sort=1;cfg.show=1;cfg.extra=1;changed=true
        end
    end
    return changed
end
function MV122Filters.keep(it,key,kind,installed,favorite)
    local f=MV122Filters.state(key)
    if f.show==2 and not favorite then return false end
    if f.show==3 and not installed then return false end
    if f.show==4 and installed then return false end
    if f.extra>1 then
        if kind=='outfits' or kind=='dlcs' then
            local t=tostring(it.thumbKind or '')
            if f.extra==2 and t~='source_image' then return false end
            if f.extra==3 and t~='gameplay_screenshot' then return false end
            if f.extra==4 and t~='catalog_cover' then return false end
            if f.extra==5 and it.thumbURL then return false end
        elseif kind=='themes' then
            local ext=tostring(it.assetName or ''):lower():match('(%.[%w]+)$') or ''
            if ext~=({'.zip','.rar','.7z'})[f.extra-1] then return false end
        elseif kind=='localdlcs' then
            if f.extra==2 and not it.valid then return false end
            if f.extra==3 and it.valid then return false end
        elseif kind=='localvehicles' then
            if not f.extraNames or tostring(it.vehicleType or 'Vehicle')~=f.extraNames[f.extra] then return false end
        end
    end
    return true
end
function MV122Filters.order(items,key)
    local f=MV122Filters.state(key)
    if f.sort==1 then return items end
    -- A copy of the filtered list is sorted; original catalog ordering is preserved.
    if key:sub(1,5)=='local' then
        if f.sort==2 then
            local r={}
            for i=#items,1,-1 do r[#r+1]=items[i] end
            return r
        end
    end
    local byCreator=(key:sub(1,5)~='local' and f.sort>=4)
    local localView=key:sub(1,5)=='local'
    local reverse=(localView and f.sort==4) or (not localView and (f.sort==3 or f.sort==5))
    table.sort(items,function(a,b)
        local ka=tostring(byCreator and a.creator or a.name or a.filename or ''):lower()
        local kb=tostring(byCreator and b.creator or b.name or b.filename or ''):lower()
        if ka==kb then return tostring(a.id or a.filename or '')<tostring(b.id or b.filename or '') end
        return reverse and ka>kb or (not reverse and ka<kb)
    end)
    return items
end

local CommunityThemes078 = {
    repo = "xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace",
    items = {}, selected = nil, status = "Open this tab to load the community catalog.",
    loading = false, initialized = false, refreshPending = false,
    search = "", page = 1, perPage = 12, busy = false,
    thumbnailLoading = false, thumbsQueued = {}, downloads = {}, skipped = 0,
}
CommunityThemes078.catalogURL = "https://raw.githubusercontent.com/" .. CommunityThemes078.repo .. "/main/marketplace/themes/catalog.json"
CommunityThemes078.thumbURLBase = "https://raw.githubusercontent.com/" .. CommunityThemes078.repo .. "/main/marketplace/themes/thumbnails/"
CommunityThemes078.releaseURLBase = "https://github.com/" .. CommunityThemes078.repo .. "/releases/download/"
CommunityThemes078.storage = ROOT_DIR .. "community\\themes\\"
CommunityThemes078.thumbDir = CommunityThemes078.storage .. "thumbnails\\"
CommunityThemes078.downloadDir = CommunityThemes078.storage .. "downloads\\"
CommunityThemes078.cacheFile = CommunityThemes078.storage .. "catalog_cache.json"
FileMgr.CreateDir(ROOT_DIR .. "community\\")
FileMgr.CreateDir(CommunityThemes078.storage)
FileMgr.CreateDir(CommunityThemes078.thumbDir)
FileMgr.CreateDir(CommunityThemes078.downloadDir)

do
-- Build 079: Local ClickGUI theme installation. The archive and extracted theme
-- live under Cherax\Theme\ClickGUI. No archive-provided code is executed.
CommunityThemes078.themeRoot = MENU_ROOT .. "\\Theme\\ClickGUI\\"
FileMgr.CreateDir(MENU_ROOT .. "\\Theme\\")
FileMgr.CreateDir(CommunityThemes078.themeRoot)

local function themeSlug079(name)
    local s=tostring(name or "Theme"):gsub("[^%w%s_%-]", "_"):gsub("%s+", "_")
    s=s:gsub("_+", "_"):gsub("^[_%-]+", ""):gsub("[_%-]+$", "")
    if s=="" then s="Theme" end
    return s:sub(1,58)
end
local function themePaths079(it)
    local base="m"..themeSlug079(it.name).."_"..it.sha:sub(1,8)
    local ext=it.assetName:lower():match("(%.[%w]+)$") or ".zip"
    return CommunityThemes078.themeRoot..base,CommunityThemes078.themeRoot..base..ext
end
local function themeMarker079(folder)
    return folder.."\\.modverse-installed.txt"
end
local function themeIsInstalled079(it)
    local folder=themePaths079(it)
    local mark=ModVerseHash152.read(themeMarker079(folder))
    return type(mark)=="string" and mark:find("SHA256="..it.sha,1,true)~=nil
end
local function themeDirExists079(path)
    -- os.rename(dir,dir) works for existing Windows directories in Cherax Lua.
    -- A markerless directory is treated as user-owned, never overwritten.
    if ModVerseHash152.read(themeMarker079(path)) then return true end
    local ok=os.rename(path,path)
    return ok and true or false
end
local THEME_ALLOWED079={
    json=true,png=true,jpg=true,jpeg=true,gif=true,webp=true,bmp=true,
    tga=true,dds=true,ttf=true,otf=true,txt=true,md=true,ini=true,cfg=true
}
-- Walk the entire central directory BEFORE writing any extracted file. Reject
-- executable payloads, traversal, symlinks, duplicates, excessive sizes, and
-- themes missing JSON configuration. A common top-level wrapper is flattened.
local function themePreflightZip079(zipPath)
    local f=io.open(zipPath,"rb")
    if not f then return false,"Cannot open verified ZIP" end
    local zip=f:read("*a");f:close()
    if type(zip)~="string" or #zip<22 or #zip>128*1024*1024 then return false,"ZIP size unsupported" end
    local eocd=findEocd(zip)
    if not eocd then return false,"Invalid ZIP: central directory not found" end
    local count=u16le(zip,eocd+10)
    local offset=u32le(zip,eocd+16)
    if not count or not offset or count<1 or count>1024 or offset>=#zip then return false,"ZIP entries/offset invalid" end
    if u16le(zip,eocd+4)~=0 or u16le(zip,eocd+6)~=0 or u16le(zip,eocd+8)~=count then
        return false,"Multi-volume ZIP not supported"
    end
    local at=offset+1
    local seen,first,oneRoot,files,jsons,total={},nil,true,0,0,0
    for i=1,count do
        if zip:sub(at,at+3)~="PK\001\002" then return false,"Invalid ZIP directory entry" end
        local made=u16le(zip,at+4) or 0
        local flags=u16le(zip,at+8) or 0
        local method=u16le(zip,at+10) or 0
        local comp=u32le(zip,at+20)
        local bytes=u32le(zip,at+24)
        local nl=u16le(zip,at+28)
        local el=u16le(zip,at+30)
        local cl=u16le(zip,at+32)
        local attrs=u32le(zip,at+38) or 0
        if not comp or not bytes or not nl or not el or not cl or not u32le(zip,at+42) then return false,"ZIP header truncated" end
        if comp==0xFFFFFFFF or bytes==0xFFFFFFFF or (flags&1)~=0 or (method~=0 and method~=8) then
            return false,"ZIP64/encrypted/unsupported compression"
        end
        if bytes>32*1024*1024 then return false,"A theme file exceeds 32 MiB" end
        total=total+bytes
        if total>128*1024*1024 then return false,"Theme expands beyond 128 MiB" end
        local raw=zip:sub(at+46,at+45+nl)
        if #raw~=nl then return false,"ZIP filename truncated" end
        local rel,reason=safeZipRelativePath(raw)
        if not rel then return false,reason end
        local host=(made>>8)&255
        local mode=(attrs>>16)&65535
        if host==3 and (mode&0xF000)==0xA000 then return false,"ZIP symlink rejected" end
        local isDir=raw:sub(-1)=="/" or raw:sub(-1)=="\\" or (host==3 and (mode&0xF000)==0x4000)
        local low=rel:lower()
        if seen[low] then return false,"Duplicate ZIP path: "..rel end
        seen[low]=true
        if not isDir then
            local suffix=rel:match("%.([^%.\\]+)$")
            if not suffix or not THEME_ALLOWED079[suffix:lower()] then return false,"Unsupported theme file: "..rel end
            files=files+1
            if suffix:lower()=="json" then jsons=jsons+1 end
            local top=rel:match("^([^\\]+)\\")
            if not top then oneRoot=false else
                if not first then first=top elseif first~=top then oneRoot=false end
            end
        end
        at=at+46+nl+el+cl
        if at>#zip+1 then return false,"ZIP directory truncated" end
    end
    if files==0 or jsons==0 then return false,"Theme archive requires at least one JSON and one file" end
    return true,oneRoot and first or nil,files
end

local function themeInstallZip079(it)
    local dest=it.installDir
    if themeIsInstalled079(it) then return true,"Already installed in Cherax ClickGUI" end
    if themeDirExists079(dest) then return false,"Existing theme folder has no matching ModVerse marker; not overwriting it" end
    local check,wrapperOrError,files=themePreflightZip079(it.filePath)
    if not check then return false,"ZIP rejected: "..tostring(wrapperOrError) end
    local stageParent=CommunityThemes078.storage.."install_staging\\"
    FileMgr.CreateDir(stageParent)
    local stage=stageParent..themeSlug079(it.name).."_"..it.sha:sub(1,8).."_"..tostring(math.floor(nowMs()))
    if themeDirExists079(stage) then return false,"Temporary install directory already exists" end
    FileMgr.CreateDir(stage)
    it.downloadStatus="Extracting theme into ClickGUI..."
    local ok,why=extractZipPureLua(it.filePath,stage)
    if not ok then return false,"ZIP extraction failed (partial staging retained for inspection): "..tostring(why) end
    local source=wrapperOrError and (stage.."\\"..wrapperOrError) or stage
    local manifest="MODVERSE_COMMUNITY_THEME\nSHA256="..it.sha.."\nID="..it.id.."\nASSET="..it.assetName.."\n"
    if not writeBinary(themeMarker079(source),manifest) then return false,"Could not write theme install marker" end
    if themeDirExists079(dest) then return false,"Theme target occupied; not overwriting" end
    local moved,whyMove=os.rename(source,dest)
    if not moved then return false,"Could not move extracted theme to ClickGUI: "..tostring(whyMove) end
    if not themeIsInstalled079(it) then return false,"Installation marker verification failed" end
    return true,"Installed "..files.." files in "..it.folderName
end


-- A small, bounded strict JSON decoder. No load(), dofile(), eval, or runtime
-- filesystem paths are accepted from the catalog.
CommunityThemes078.themeSlug=themeSlug079
CommunityThemes078.isInstalled=themeIsInstalled079
CommunityThemes078.dirExists=themeDirExists079
CommunityThemes078.preflightZip=themePreflightZip079
CommunityThemes078.installZip=themeInstallZip079
end -- B079 isolated installer scope

local function communityJson078(s)
    if type(s) ~= "string" or #s > 1024*1024 then error("catalog too large") end
    local pos, length, tokens = 1, #s, 0
    local function ws()
        while true do
            local b = s:byte(pos)
            if b == 32 or b == 9 or b == 10 or b == 13 then pos=pos+1 else break end
        end
    end
    local function utf(code)
        if code < 0 or code > 0x10FFFF or (code >= 0xD800 and code <= 0xDFFF) then error("invalid Unicode codepoint") end
        if code < 0x80 then return string.char(code) end
        if code < 0x800 then return string.char(0xC0+(code>>6),0x80+(code&63)) end
        if code < 0x10000 then return string.char(0xE0+(code>>12),0x80+((code>>6)&63),0x80+(code&63)) end
        return string.char(0xF0+(code>>18),0x80+((code>>12)&63),0x80+((code>>6)&63),0x80+(code&63))
    end
    local function parseString()
        if s:byte(pos) ~= 34 then error("expected JSON string") end
        pos = pos+1
        local out, start = {}, pos
        while pos <= length do
            local b = s:byte(pos)
            if b == 34 then
                out[#out+1] = s:sub(start,pos-1)
                pos=pos+1
                return table.concat(out)
            elseif b == 92 then
                out[#out+1] = s:sub(start,pos-1)
                local esc=s:sub(pos+1,pos+1)
                local escapes={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
                if esc == 'u' then
                    local hex=s:sub(pos+2,pos+5)
                    if not hex:match('^%x%x%x%x$') then error("bad unicode escape") end
                    local code=tonumber(hex,16)
                    pos=pos+6
                    if code >= 0xD800 and code <= 0xDBFF then
                        if s:sub(pos,pos+1) ~= '\\u' or not s:sub(pos+2,pos+5):match('^%x%x%x%x$') then error("unpaired surrogate") end
                        local lo=tonumber(s:sub(pos+2,pos+5),16)
                        if lo < 0xDC00 or lo > 0xDFFF then error("unpaired surrogate") end
                        code=0x10000 + (code-0xD800)*1024 + lo-0xDC00
                        pos=pos+6
                    end
                    out[#out+1]=utf(code)
                else
                    if not escapes[esc] then error("invalid JSON escape") end
                    out[#out+1]=escapes[esc]
                    pos=pos+2
                end
                start=pos
            elseif b < 32 then error("control character in JSON string")
            else pos=pos+1 end
        end
        error("unterminated JSON string")
    end
    local parseValue
    parseValue=function(depth)
        if depth > 32 then error("JSON nesting limit") end
        tokens=tokens+1
        if tokens > 24000 then error("JSON token limit") end
        ws()
        local c=s:sub(pos,pos)
        if c == '"' then return parseString() end
        if c == '{' then
            pos=pos+1; ws(); local obj={}
            if s:sub(pos,pos)=='}' then pos=pos+1;return obj end
            while true do
                ws(); local key=parseString();ws()
                if s:sub(pos,pos)~=':' then error("expected colon") end
                pos=pos+1
                if obj[key]~=nil then error("duplicate JSON key") end
                obj[key]=parseValue(depth+1);ws()
                local sep=s:sub(pos,pos);pos=pos+1
                if sep=='}' then return obj end
                if sep~=',' then error("expected object comma") end
            end
        elseif c == '[' then
            pos=pos+1;ws(); local arr={}
            if s:sub(pos,pos)==']' then pos=pos+1;return arr end
            while true do
                arr[#arr+1]=parseValue(depth+1);ws()
                local sep=s:sub(pos,pos);pos=pos+1
                if sep==']' then return arr end
                if sep~=',' then error("expected array comma") end
            end
        elseif s:sub(pos,pos+3)=='true' then pos=pos+4;return true
        elseif s:sub(pos,pos+4)=='false' then pos=pos+5;return false
        elseif s:sub(pos,pos+3)=='null' then pos=pos+4;return false -- nil sentinel; not used for permitted fields
        else
            local start=pos
            local fragment=s:sub(pos)
            local number=fragment:match('^%-?[%d%.eE%+%-]+')
            if not number or number=='' then error("invalid JSON number") end
            local mantissa,exp=number:match('^(.-)([eE].+)$')
            if not mantissa then mantissa=number end
            if not (mantissa:match('^%-?%d+$') or mantissa:match('^%-?%d+%.%d+$'))
               or mantissa:match('^%-?0%d') or (exp and not exp:match('^[eE][%+%-]?%d+$')) then
                error("invalid JSON number")
            end
            local n=tonumber(number)
            if n==nil or n~=n or n==math.huge or n==-math.huge then error("invalid number") end
            pos=pos+#number
            return n
        end
    end
    local value=parseValue(0);ws()
    if pos<=length then error("trailing JSON data") end
    return value
end

local function communityToken078(s, maxLen)
    return type(s)=="string" and #s>0 and #s<=(maxLen or 180)
        and not s:find("..",1,true) and s:match("^[%w%._%-]+$")~=nil
end
local function communitySafeText078(s,n)
    if type(s)~="string" then return "" end
    return s:gsub("[%z\1-\8\11\12\14-\31]", " "):sub(1,n or 500)
end
local function communityValidate078(raw)
    local doc=communityJson078(raw)
    if type(doc)~="table" or doc.schema~="modverse.distribution.v1" or doc.published~=true
        or type(doc.items)~="table" or #doc.items>500 then error("invalid or unpublished community catalog") end
    local results, seen, skipped={}, {}, 0
    for _,entry in ipairs(doc.items) do
        local f=type(entry)=="table" and type(entry.files)=="table" and entry.files[1] or nil
        local name=type(entry)=="table" and entry.name or nil
        local id=type(entry)=="table" and entry.id or nil
        local url=f and f.download_url
        local asset=f and f.asset_name
        local tag,urlAsset
        if type(url)=="string" then
            tag,urlAsset=url:match("^"..CommunityThemes078.releaseURLBase:gsub("%-","%%-"):gsub("%.","%%.").."([%w%._%-]+)/([%w%._%-]+)$")
        end
        local suffix=type(asset)=="string" and asset:lower():match("(%.[%w]+)$") or nil
        local thumb=type(entry)=="table" and entry.thumbnail_url or nil
        local nameOK=type(name)=="string" and #name>0 and #name<=180
        local sha=f and f.sha256
        local size=f and tonumber(f.size_bytes)
        if type(entry)=="table" and entry.category=="themes" and entry.install_mode=="download_only"
           and communityToken078(id,150) and not seen[id] and nameOK
           and communityToken078(asset,190) and communityToken078(tag,90) and urlAsset==asset
           and (suffix==".zip" or suffix==".rar" or suffix==".7z")
           and type(url)=="string" and url==CommunityThemes078.releaseURLBase..tag.."/"..asset
           and type(thumb)=="string" and thumb==CommunityThemes078.thumbURLBase..id..".jpg"
           and type(sha)=="string" and #sha==64 and sha:match("^%x+$")
           and size and size>0 and size<=128*1024*1024 and size%1==0 then
            seen[id]=true
            results[#results+1]={
                id=id,name=communitySafeText078(name,180),creator=communitySafeText078(entry.creator,100),
                description=communitySafeText078(entry.description,1500),postDate=communitySafeText078(entry.post_date,90),
                thumbURL=thumb,assetName=asset,downloadURL=url,releaseTag=tag,sha=sha:lower(),size=size,
                sourceMessageId=communitySafeText078(entry.source_message_id,32),
                thumbPath=CommunityThemes078.thumbDir..id..".jpg",
                filePath=CommunityThemes078.themeRoot.."m"..CommunityThemes078.themeSlug(name).."_"..sha:sub(1,8)..suffix,
                installDir=CommunityThemes078.themeRoot.."m"..CommunityThemes078.themeSlug(name).."_"..sha:sub(1,8),
                folderName="m"..CommunityThemes078.themeSlug(name).."_"..sha:sub(1,8),
                legacyPath=CommunityThemes078.downloadDir..asset,
                thumbStatus="waiting",downloadStatus="Ready to download and install",downloading=false,
            }
        else skipped=skipped+1 end
    end
    if #results==0 then error("no valid, trusted-host theme items in catalog") end
    return results,skipped
end
function CommunityThemes078.installCatalog(raw,fromCache)
    local ok, items, skipped=pcall(communityValidate078,raw)
    if not ok then return false,tostring(items) end
    local previous=CommunityThemes078.selected and CommunityThemes078.selected.id
    local old={}
    for _,v in ipairs(CommunityThemes078.items) do old[v.id]=v end
    for _,v in ipairs(items) do
        local before=old[v.id]
        if before and before.sha==v.sha and before.downloadURL==v.downloadURL then
            v.downloadStatus=before.downloadStatus;v.downloading=before.downloading
            v.thumbStatus=before.thumbStatus
        end
    end
    CommunityThemes078.items=items
    CommunityThemes078.skipped=skipped
    CommunityThemes078.selected=items[1]
    for _,v in ipairs(items) do if v.id==previous then CommunityThemes078.selected=v;break end end
    CommunityThemes078.status=(fromCache and "Cached catalog" or "Live GitHub catalog")
        ..": "..#items.." themes"..(skipped>0 and (" ("..skipped.." invalid entries skipped)") or "")
    return true
end
function CommunityThemes078.refresh(force)
    local M=CommunityThemes078
    if M.loading then return end
    M.initialized=true
    if not force and #M.items==0 and fileExists(M.cacheFile) then
        local cached=ModVerseHash152.read(M.cacheFile)
        if cached then M.installCatalog(cached,true) end
    end
    if not Script or not Script.QueueJob then M.status="Job queue not available";return end
    M.loading=true
    M.status="Fetching live GitHub themes catalog..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local raw,networkErr=httpGet(M.catalogURL,22000,nil,{
                "Accept: application/json", "Cache-Control: no-cache", "Pragma: no-cache"
            },USER_AGENT)
            if not raw then error(networkErr or "connection failed") end
            local valid,why=M.installCatalog(raw,false)
            if not valid then error(why) end
            -- Never replace the usable cached catalog with unvalidated data.
            local tmp=M.cacheFile..".part"
            if writeBinary(tmp,raw) then
                os.remove(M.cacheFile)
                if not os.rename(tmp,M.cacheFile) then os.remove(tmp) end
            end
        end)
        if not ok then
            M.status="Live refresh failed; "..(#M.items>0 and "showing cached themes. " or "no cached themes. ")..shortText(tostring(err),160)
            log("[MV078][CATALOG] "..tostring(err))
        else log("[MV078][CATALOG] "..M.status) end
        M.loading=false
    end)
end

function CommunityThemes078.fetchVisible(visible)
    local M=CommunityThemes078
    if M.thumbnailLoading or not Script or not Script.QueueJob then return end
    local todo={}
    for _,it in ipairs(visible) do
        if not M.thumbsQueued[it.id] and it.thumbStatus~="ready" and it.thumbStatus~="failed" then
            if fileExists(it.thumbPath) and detectImageFile(it.thumbPath)=="jpg" then
                it.thumbStatus="ready"
            else
                M.thumbsQueued[it.id]=true
                todo[#todo+1]=it
            end
        end
    end
    if #todo==0 then return end
    M.thumbnailLoading=true
    Script.QueueJob(function()
        local ok,err=pcall(function()
            for _,it in ipairs(todo) do
                if it.thumbStatus~="ready" then
                    it.thumbStatus="downloading"
                    local body,fetchErr=httpGet(it.thumbURL,19000,nil,{
                        IMAGE_ACCEPT,"Cache-Control: no-cache"
                    },IMAGE_USER_AGENT)
                    if type(body)=="string" and #body>=100 and #body<=4*1024*1024
                        and detectImageKind(body)=="jpg" and writeBinary(it.thumbPath..".part",body) then
                        os.remove(it.thumbPath)
                        if os.rename(it.thumbPath..".part",it.thumbPath) then
                            it.thumbStatus="ready"
                        else
                            os.remove(it.thumbPath..".part")
                            it.thumbStatus="failed"
                        end
                    else
                        it.thumbStatus="failed"
                        log("[MV078][PREVIEW] "..it.id.." "..tostring(fetchErr or "invalid JPEG response"))
                    end
                end
                M.thumbsQueued[it.id]=nil
                Script.Yield(70)
            end
        end)
        if not ok then
            for _,it in ipairs(todo) do
                if it.thumbStatus~="ready" then it.thumbStatus="failed" end
                M.thumbsQueued[it.id]=nil
            end
            log("[MV078][PREVIEW] "..tostring(err))
        end
        M.thumbnailLoading=false
    end)
end
function CommunityThemes078.download(it)
    local M=CommunityThemes078
    if not it or it.downloading or M.busy or not Script or not Script.QueueJob then return end
    M.busy=true;it.downloading=true
    it.downloadStatus="Checking installed theme and archive..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            if CommunityThemes078.isInstalled(it) then
                it.downloadStatus="Already installed: "..it.folderName
                return
            end
            if CommunityThemes078.dirExists(it.installDir) then
                error("Theme folder already exists; refusing to overwrite: "..it.folderName)
            end
            local data=nil
            for _,path in ipairs({it.filePath,it.legacyPath}) do
                if fileExists(path) then
                    local raw=ModVerseHash152.read(path)
                    if raw and #raw==it.size and ModVerseHash152.sha256(raw)==it.sha then
                        data=raw
                        break
                    end
                end
            end
            if not data then
                it.downloadStatus="Downloading verified GitHub archive..."
                local raw,why=httpGet(it.downloadURL,60000,nil,{
                    "Accept: application/octet-stream", "Cache-Control: no-cache"
                },USER_AGENT)
                if type(raw)~="string" then error("Download failed: "..tostring(why)) end
                data=raw
            end
            it.downloadStatus="Verifying SHA-256..."
            Script.Yield(0)
            if #data~=it.size then error("Downloaded archive size mismatch") end
            local ext=it.assetName:lower():match("(%.[%w]+)$")
            local head=data:sub(1,8)
            local zip=head:sub(1,4)=="PK\003\004" or head:sub(1,4)=="PK\005\006"
            local rar=head:sub(1,7)=="Rar!\026\007\000" or head=="Rar!\026\007\001\000"
            local seven=head:sub(1,6)=="7z\188\175\039\028"
            if not ((ext==".zip" and zip) or (ext==".rar" and rar) or (ext==".7z" and seven)) then
                error("Invalid archive signature")
            end
            if ModVerseHash152.sha256(data)~=it.sha then error("SHA-256 MISMATCH (archive not installed)") end
            -- Never rewrite a user file without confirming what it contains.
            if not fileExists(it.filePath) or ModVerseHash152.sha256(ModVerseHash152.read(it.filePath) or "")~=it.sha then
                local tmp=it.filePath..".part"
                if not writeBinary(tmp,data) then error("Cannot save archive to Cherax Theme ClickGUI") end
                local saved=ModVerseHash152.read(tmp)
                if not saved or #saved~=it.size or ModVerseHash152.sha256(saved)~=it.sha then
                    os.remove(tmp); error("Saved archive failed checksum verification")
                end
                if fileExists(it.filePath) then
                    os.remove(tmp)
                    error("Existing ClickGUI archive has different content. Not overwriting it")
                end
                local moved=os.rename(tmp,it.filePath)
                if not moved then os.remove(tmp);error("Could not finalize ClickGUI archive") end
            end
            if ext==".zip" then
                local installed,reason=CommunityThemes078.installZip(it)
                if not installed then error(reason) end
                it.downloadStatus="Installed: "..it.folderName.." (ClickGUI)"
                toast("Community theme installed: "..it.name,3500)
                if ModVerseTutorial147 then ModVerseTutorial147.open("themes","install") end
                log("[MV079][INSTALL] "..it.installDir)
            elseif ext==".rar" then
                it.downloadStatus="Verified RAR saved. Extract manually; ModVerse does not launch archive helpers."
                toast("RAR verified and saved; extract manually",3500)
            else
                it.downloadStatus="Verified 7Z archive saved in ClickGUI. External extraction required."
                toast("7Z saved to ClickGUI; extract manually",3500)
                -- Build 148: a saved 7Z still requires manual extraction; no install tutorial yet.
            end
        end)
        if not ok then
            it.downloadStatus="FAILED: "..shortText(tostring(err),175)
            log("[MV079][DOWNLOAD][ERROR] "..it.assetName.." "..tostring(err))
            toast("Theme download/install failed: view status",4000)
        end
        it.downloading=false;M.busy=false
    end)
end

-- Build 124 keeps stars as an overlay and all theme file operations untouched.
local function communityRenderTile078(it,width)
    local tileH,imageH=169,104
    local x,y=cursorScreenPos()
    ImGui.PushID("MV078T_"..it.id)
    local clicked=ImGui.InvisibleButton("##card",width,tileH)
    local hovered=ImGui.IsItemHovered()
    drawImageCardBackground(x,y,width,tileH,hovered,CommunityThemes078.selected==it)
    local srv=it.thumbStatus=="ready" and textureSrv(it.thumbPath) or nil
    if srv then
        if ImGui.AddImageRounded then
            ImGui.AddImageRounded(srv,x+3,y+3,x+width-3,y+imageH,0,0,1,1,0xFFFFFFFF,6)
        else ImGui.AddImage(srv,x+3,y+3,x+width-3,y+imageH) end
    else
        ImGui.AddRectFilled(x+3,y+3,x+width-3,y+imageH,34,38,52,255,6)
        ImGui.AddText(x+10,y+43,it.thumbStatus=="failed" and "NO PREVIEW" or "LOADING...",180,175,207,255)
    end
    ImGui.AddRectFilled(x+3,y+imageH-2,x+width-3,y+tileH-3,16,18,27,250)
    local charLimit=math.max(13,math.floor(width/7.5))
    ImGui.AddText(x+8,y+imageH+4,shortText(it.name,charLimit),248,247,255,255)
    ImGui.AddText(x+8,y+imageH+23,"Shared By: "..shortText((it.creator or ""):lower():find("unverified",1,true) and "Community" or (it.creator~="" and it.creator or "Community"),charLimit),171,177,198,255)
    local ext=tostring(it.assetName or ""):lower():match("(%.[%w]+)$") or ""
    local formatText=ext==".zip" and "ZIP  |  Auto install" or (ext==".rar" and "RAR  |  Archive only" or (ext==".7z" and "7Z  |  Archive only" or "Archive"))
    ImGui.AddText(x+8,y+imageH+42,formatText,146,156,181,255)
    if ModVerseCherax090 and ModVerseCherax090.cardStar123 then
        if ModVerseCherax090.cardStar123("themes",it.id,x,y,hovered) then clicked=false end
    end
    if clicked then CommunityThemes078.selected=it end
    if hovered and ImGui.BeginTooltip then
        ImGui.BeginTooltip()
        ImGui.Text(it.name)
        ImGui.Text("Select theme")
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end
local function communityRender078()
    local M=CommunityThemes078
    if not M.initialized then M.refresh(false) end
    ImGui.TextColored(0.78,0.55,1.0,1.0,"Themes")
    ImGui.TextColored(0.68,0.70,0.79,1.0,"ZIP auto-installs. RAR / 7Z require manual extraction or an optional helper.")

    -- Search and one small refresh control; publisher/debug information stays in Details.
    if ImGui.SetNextItemWidth then
        local width=select(1,contentAvail()) or 720
        ImGui.SetNextItemWidth(math.max(130,math.min(270,width-125)))
    end
    local input=ImGui.InputText("Search##MV078",M.search,120)
    if type(input)=="string" and input~=M.search then M.search=input; M.page=1 end
    ImGui.SameLine()
    if ImGui.Button("Refresh##MV078",84,24) then M.refresh(true) end
    if M.loading then
        ImGui.SameLine(); ImGui.TextColored(0.70,0.75,0.84,1.0,"Loading...")
    end
    if MV122Filters.bar('market_themes','themes') then M.page=1 end
    local status=tostring(M.status or "")
    local low=status:lower()
    if not M.loading and (low:find("fail",1,true) or low:find("error",1,true) or low:find("unavailable",1,true)) then
        ImGui.TextColored(1.0,0.68,0.44,1.0,shortText(status,115))
    end

    local filtered={}
    local needle=M.search:lower()
    for _,it in ipairs(M.items) do
        if needle=="" or it.name:lower():find(needle,1,true) or it.creator:lower():find(needle,1,true) then
            local fs=MV122Filters.state('market_themes')
            local installed=fs.show>=3 and M.isInstalled(it) or false
            local favorite=fs.show==2 and ModVerseCherax090.isFavorite('themes',it.id) or false
            if MV122Filters.keep(it,'market_themes','themes',installed,favorite) then filtered[#filtered+1]=it end
        end
    end
    filtered=MV122Filters.order(filtered,'market_themes')
    local maxPage=math.max(1,math.ceil(#filtered/M.perPage))
    M.page=math.min(math.max(1,M.page),maxPage)

    -- A selected theme remains actionable before the scrollable gallery.
    local selected=M.selected
    ImGui.Separator()
    if selected then
        ImGui.TextColored(0.80,0.82,0.94,1.0,"Selected: "..shortText(selected.name,43))
        local ext=tostring(selected.assetName or ""):lower():match("(%.[%w]+)$") or ""
        local actionLabel=ext==".zip" and "Install Theme##MV078" or "Download Archive##MV078"
        if ImGui.Button(selected.downloading and "Working...##MV078" or actionLabel,155,28) and not M.busy then
            M.download(selected)
        end
        local ds=tostring(selected.downloadStatus or "")
        if ds~="" and ds~="Ready" and ds~="Not downloaded" then
            ImGui.SameLine(); ImGui.TextColored(0.68,0.76,0.90,1.0,shortText(ds,67))
        end
    else
        ImGui.TextColored(0.63,0.68,0.77,1.0,"Select a theme to install or download")
    end
    -- Paths, release page, archive details and SHA metadata stay available on demand.
    if ImGui.TreeNode and ImGui.TreeNode("Details##MV124Themes") then
        if selected then
            ImGui.Text("Shared By: "..tostring((selected.creator or ""):lower():find("unverified",1,true) and "Community" or (selected.creator~="" and selected.creator or "Community")))
            if selected.postDate~="" then ImGui.Text("Shared: "..selected.postDate) end
            if selected.description~="" then safeTextWrapped(selected.description) end
            ImGui.Text("Archive: "..selected.assetName)
            ImGui.Text(string.format("Size: %.2f MiB | SHA-256: %s",selected.size/1048576,selected.sha:sub(1,16).."..."))
            ImGui.Text("Folder: "..selected.installDir)
            ImGui.Text("Saved file: "..selected.filePath)
            if ImGui.Button("Release Page##MV124",110,24) then
                pcall(function() Utils.OpenURL("https://github.com/"..M.repo.."/releases/tag/"..selected.releaseTag) end)
            end
        else
            ImGui.Text("Select a theme to see its details")
        end
        if ImGui.Button("GitHub Catalog##MV124",130,24) then
            pcall(function() Utils.OpenURL("https://github.com/"..M.repo) end)
        end
        ImGui.TreePop()
    end

    -- Avoid a permanent pagination row when everything fits on one page.
    if maxPage>1 then
        if ImGui.Button("< Previous##MV078",108,24) then M.page=math.max(1,M.page-1) end
        ImGui.SameLine(); ImGui.Text(tostring(M.page).." / "..tostring(maxPage).."  |  "..tostring(#filtered).." themes")
        ImGui.SameLine()
        if ImGui.Button("Next >##MV078",88,24) then M.page=math.min(maxPage,M.page+1) end
    else
        ImGui.TextColored(0.52,0.57,0.67,1.0,tostring(#filtered).." theme"..(#filtered==1 and "" or "s"))
    end
    ImGui.Separator()
    local visible={}
    local from=(M.page-1)*M.perPage+1
    for i=from, math.min(#filtered,from+M.perPage-1) do visible[#visible+1]=filtered[i] end
    if #visible>0 then M.fetchVisible(visible) end
    if #visible==0 then
        ImGui.Text(M.loading and "Loading themes..." or (#M.items==0 and "No themes loaded. Try Refresh." or "No matching themes."))
    else
        local _,remainingHeight=contentAvail()
        local gridHeight=math.max(175,math.min(450,(remainingHeight or 0)-12))
        if ImGui.BeginChild then ImGui.BeginChild("ModVerseCommunityGrid078",0,gridHeight,true) end
        local available=select(1,contentAvail())
        local cols=math.max(2,math.min(4,math.floor(available/215)))
        local tileW=math.max(160,(available-(cols-1)*10)/cols-7)
        if ImGui.BeginTable("ModVerseCommunityTable078",cols,ImGuiTableFlags.SizingStretchSame) then
            for _,it in ipairs(visible) do
                ImGui.TableNextColumn()
                communityRenderTile078(it,tileW)
            end
            ImGui.EndTable()
        end
        if ImGui.EndChild then ImGui.EndChild() end
    end
    if ModVerseCherax090 and ModVerseCherax090.starFinish123 then ModVerseCherax090.starFinish123() end
end
ModVerseCommunity078 = { render=communityRender078, state=CommunityThemes078, decodeJson=communityJson078 }
end -- END COMMUNITY THEMES 079 (scoped to avoid Lua 200-local chunk limit)

do
-- ==========================================================================
-- modverse community json vehicles - build 083 github approved + local batch 02
-- Discord Pilot 01, 20 user-tested Cherax Entity JSON files, no remote publish.
-- Bundle must be extracted into Cherax root, with originals in Lua/ModVerse.
-- JSON bytes are SHA-256 pinned; mMV_ prefixes apply only to filenames.
-- ==========================================================================
local M = {
    root = MENU_ROOT .. "\\Vehicles\\",
    assets = ROOT_DIR .. "community\\vehicles\\pilot01\\",
    items = {}, selected = nil, search = "", page = 1, perPage = 12,
    status = "Private review: 20 pilot + 99 Batch 02 Cherax vehicle files.",
    mode = "github", liveItems = {}, liveStatus = "GitHub: not loaded",
    githubTestBusy = false, githubTestStatus = "Not tested",
    liveBusy = false, liveLoaded = false, previewBusy = false, previewRequested = {},
    previewVerified = {}, previewDiskCounted = {}, previewStats = { disk=0, downloaded=0, failed=0 },
    catalogUrl = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace/main/marketplace/vehicles/catalog.json",
    publicRoot = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace/main/marketplace/vehicles/",
    liveCacheDir = ROOT_DIR .. "community\\vehicles\\online\\",
}
local records080 = {
    {id="1256941518036406273-1557899016073777283", name="clean honda accord build", creator="dot.exe", post="Thursday, October 8, 2026 4:34 PM", sha="a54e88adaf6adfc14815e85cd2f145a8beb09df0d7e50e734de76e1c6630b136", bytes=4084, jsonFile="01_a54e88adaf6a.json", previewFile="01_a54e88adaf6a.jpg", filename="mMV_clean_honda_accord_build_a54e88ad.json", model=1992041063},
    {id="1256941518036406273-1557578693109485689", name="Clean BMW 3 series build", creator="dot.exe", post="Wednesday, October 7, 2026 7:21 PM", sha="fcd2a806810416badc0e24bc5ad31b26bc1af301b02d9cf904eb90fdfcc77d00", bytes=4080, jsonFile="02_fcd2a8068104.json", previewFile="02_fcd2a8068104.jpg", filename="mMV_Clean_BMW_3_series_build_fcd2a806.json", model=2439462158},
    {id="1256941518036406273-1557995347018776618", name="ToyotaSoarer NFS Underground 2.json", creator="Pulse_2JZ", post="Thursday, October 8, 2026 10:57 PM", sha="d01e0ecc25b51f078c7ae6c37c4eba1da04907a5822974b7c42b6af690e85d33", bytes=4090, jsonFile="03_d01e0ecc25b5.json", previewFile="03_d01e0ecc25b5.jpg", filename="mMV_ToyotaSoarer_NFS_Underground_2_json_d01e0ecc.json", model=1416471345},
    {id="1256941518036406273-1557258557936894012", name="Sultan RS Lexus IS300 1998.json", creator="Pulse_2JZ", post="Tuesday, October 6, 2026 10:09 PM", sha="394334163b016c7dc6a1bd9f1503183a562927f5388fd2b7e91301383b641596", bytes=4092, jsonFile="04_394334163b01.json", previewFile="04_394334163b01.jpg", filename="mMV_Sultan_RS_Lexus_IS300_1998_json_39433416.json", model=3999278268},
    {id="1256941518036406273-1558087485085712454", name="PINKDELUXO.json", creator="rivhrr", post="Friday, October 9, 2026 5:03 AM", sha="7e161f90ed6bcda2c47337ed99fbeb511e6e0fb89959f1e04199629c279925dc", bytes=4094, jsonFile="05_7e161f90ed6b.json", previewFile="05_7e161f90ed6b.jpg", filename="mMV_PINKDELUXO_json_7e161f90.json", model=1483171323},
    {id="1256941518036406273-1556143200236998727", name="Sasquatch.json", creator="KITA", post="Saturday, October 3, 2026 8:17 PM", sha="71e25e505fb9c78cb872d9959bf618bb69b22efa3671c001a8126f29f2280cde", bytes=4086, jsonFile="06_71e25e505fb9.json", previewFile="06_71e25e505fb9.jpg", filename="mMV_Sasquatch_json_71e25e50.json", model=840387324},
    {id="1256941518036406273-1553195686923739273", name="Banshee GTS.json", creator="KITA", post="Friday, September 25, 2026 5:05 PM", sha="5e5c2ed8669ed0be8d77a0c2982002b993a0cca92d8b1c7d336d47b5f4f805e7", bytes=4091, jsonFile="07_5e5c2ed8669e.json", previewFile="07_5e5c2ed8669e.jpg", filename="mMV_Banshee_GTS_json_5e5c2ed8.json", model=3634959571},
    {id="1256941518036406273-1555459222198689803", name="P1.json", creator="mafia_0001", post="Thursday, October 1, 2026 10:59 PM", sha="b2678bd3081595c63d5c556523d0fcbfa5349dfef6fb3cd7c89d70617779a133", bytes=4087, jsonFile="08_b2678bd30815.json", previewFile="08_b2678bd30815.jpg", filename="mMV_P1_json_b2678bd3.json", model=1663218586},
    {id="1256941518036406273-1555228143336558594", name="ASTON.json", creator="mafia_0001", post="Thursday, October 1, 2026 7:41 AM", sha="17b3b04b8147696908553c39949a991d9e8c62763837cfc75eefaecd2fc6dfda", bytes=4090, jsonFile="09_17b3b04b8147.json", previewFile="09_17b3b04b8147.jpg", filename="mMV_ASTON_json_17b3b04b.json", model=3379732821},
    {id="1256941518036406273-1555668748009213985", name="Enitity.json", creator="Kurenai", post="Friday, October 2, 2026 12:52 PM", sha="c661d3f7d5dd86dcd84317b897cae9bc592c82c859adaed4c4055a6744ebe8bc", bytes=4091, jsonFile="10_c661d3f7d5dd.json", previewFile="10_c661d3f7d5dd.jpg", filename="mMV_Enitity_json_c661d3f7.json", model=1748565021},
    {id="1256941518036406273-1549875330892959815", name="Clean Blue Grotti Cartuccia (edited)", creator="ytwv", post="Wednesday, September 16, 2026 1:11 PM", sha="1aa4bd73ab44117af5ab60adf2f7600d60692c8a73452caa56ef27b6b39ee46c", bytes=4093, jsonFile="11_1aa4bd73ab44.json", previewFile="11_1aa4bd73ab44.jpg", filename="mMV_Clean_Blue_Grotti_Cartuccia_edited_1aa4bd73.json", model=2271995207},
    {id="1256941518036406273-1549877128747683912", name="Clean Pink Peggasi Ignus! (edited)", creator="ytwv", post="Wednesday, September 16, 2026 1:18 PM", sha="b378e500c34352b65141cb01f86f72709fd2d540f7cb78933e055eb369234ae7", bytes=4098, jsonFile="12_b378e500c343.json", previewFile="12_b378e500c343.jpg", filename="mMV_Clean_Pink_Peggasi_Ignus_edited_b378e500.json", model=2850852987},
    {id="1256941518036406273-1550928539392409662", name="RAIJU MLONIIK.json", creator="MLONIIK", post="Saturday, September 19, 2026 10:56 AM", sha="6e4f052e33113c54d9b1e53e47d6aa71edc36dffd40a68a1a89a8d44bd588b71", bytes=4078, jsonFile="13_6e4f052e3311.json", previewFile="13_6e4f052e3311.jpg", filename="mMV_RAIJU_MLONIIK_json_6e4f052e.json", model=239897677},
    {id="1256941518036406273-1551138245511745617", name="idk if someone already did it", creator="Lilfonal", post="Sunday, September 20, 2026 12:49 AM", sha="2c7f5131f86470af03446ffac87255de0c97967289d1eb64884eaf534d6caa13", bytes=4088, jsonFile="14_2c7f5131f864.json", previewFile="14_2c7f5131f864.jpg", filename="mMV_idk_if_someone_already_did_it_2c7f5131.json", model=2709293299},
    {id="1256941518036406273-1550872639122186271", name="wrecked ruiner.json", creator="lemod45", post="Saturday, September 19, 2026 7:14 AM", sha="aff00d5a2ffa4e1e78c5c41ac2340df499b8ad06ff03f8f3d20554410145398d", bytes=4078, jsonFile="15_aff00d5a2ffa.json", previewFile="15_aff00d5a2ffa.jpg", filename="mMV_wrecked_ruiner_json_aff00d5a.json", model=777714999},
    {id="1256941518036406273-1545947754864574538", name="Han's RX7 from Fast & Furious Tokyo Drift [ WHITELISTED + UNSCRATCHED ] Bennys Wheels (Lot…", creator="Nebula", post="Saturday, September 5, 2026 5:04 PM", sha="f1f7915852b6eaf1f99663495ab7428365ce1d13bdf7892b21f2d2705c3031ce", bytes=4091, jsonFile="16_f1f7915852b6.json", previewFile="16_f1f7915852b6.jpg", filename="mMV_Han_s_RX7_from_Fast_Furious_Tokyo_Drift_WHITELIST_f1f79158.json", model=633712403},
    {id="1256941518036406273-1547608180085756005", name="White Camaro with saving White Tires Also this is my first upload", creator="PhilipV8", post="Thursday, September 10, 2026 7:02 AM", sha="c7a4566d65f5ad77d5594761dd4c25dd16d537a99aad3913b207123af8df6532", bytes=4104, jsonFile="17_c7a4566d65f5.json", previewFile="17_c7a4566d65f5.jpg", filename="mMV_White_Camaro_with_saving_White_Tires_Also_this_is_c7a4566d.json", model=2536587772},
    {id="1256941518036406273-1544078068740788266", name="GT2 RS Real Life", creator="AlexHall", post="Monday, August 31, 2026 1:14 PM", sha="986fdc16a0c616b460b428e240db5d7f12f5ce8f55b0fe45a710206bcb5152b2", bytes=4086, jsonFile="18_986fdc16a0c6.json", previewFile="18_986fdc16a0c6.jpg", filename="mMV_GT2_RS_Real_Life_986fdc16.json", model=661493923},
    {id="1256941518036406273-1545201647045574758", name="Futo GTX  F1", creator="Ricky455", post="Thursday, September 3, 2026 3:39 PM", sha="fa2fa9035a1e7e0de38139f57b2a1044c972d21962246d136462c42293fef0a3", bytes=4083, jsonFile="19_fa2fa9035a1e.json", previewFile="19_fa2fa9035a1e.jpg", filename="mMV_Futo_GTX_F1_fa2fa903.json", model=2787736776},
    {id="1256941518036406273-1544228321124945952", name="CADILLAC ESCALADE (MC3 DUB INSPIRED)", creator="Maya117x", post="Monday, August 31, 2026 11:12 PM", sha="a4e3b81bf53bca44979e5c8f2cf34b7f14a5532e941a08cfcbe567007d49af4b", bytes=4087, jsonFile="20_a4e3b81bf53b.json", previewFile="20_a4e3b81bf53b.jpg", filename="mMV_CADILLAC_ESCALADE_MC3_DUB_INSPIRED_a4e3b81b.json", model=3265236814},
    -- B082 additional user-review batch: 99 authentic Cherax Entity files; untested in game
    {id="1256941518036406273-1258794556648980571", name="green italio gto", creator="Bravado", post="Friday, July 5, 2024 7:40 AM", sha="85f8e3635e1c5f7bf9c7c47653285996756a26765aee63e868304c8cd109292c", bytes=3641, jsonFile="001_85f8e3635e1c.json", previewFile="001_85f8e3635e1c.jpg", filename="mMV_green_italio_gto_85f8e363.json", model=1447690049, batch="batch02"},
    {id="1256941518036406273-1261369971594760223", name="Mercedes-Benz 300CE 3.4 AMG (edited)", creator="Snub", post="Friday, July 12, 2024 10:13 AM", sha="1d8f41dcd9a308c7e98bc2885a9f3d7c89cd9365202c6eb4ff70594d9806da42", bytes=3686, jsonFile="002_1d8f41dcd9a3.json", previewFile="002_1d8f41dcd9a3.jpg", filename="mMV_Mercedes_Benz_300CE_3_4_AMG_edited_1d8f41dc.json", model=4151380270, batch="batch02"},
    {id="1256941518036406273-1263254616896704644", name="BMW.1.json", creator="Stefce", post="Wednesday, July 17, 2024 3:02 PM", sha="09a68c918ef6021d4e44310a809c676051c08b88274dcd7368550d6b7f7d48ca", bytes=3693, jsonFile="003_09a68c918ef6.json", previewFile="003_09a68c918ef6.jpg", filename="mMV_BMW_1_json_09a68c91.json", model=1755697647, batch="batch02"},
    {id="1256941518036406273-1269313624711762041", name="Modded Porshe.json", creator="Notif", post="Saturday, August 3, 2024 8:19 AM", sha="b0845b53cee0a8c72bbecc50869a4e963e57bdb9d03ee7ce6291c95a3b962645", bytes=3697, jsonFile="004_b0845b53cee0.json", previewFile="004_b0845b53cee0.jpg", filename="mMV_Modded_Porshe_json_b0845b53.json", model=2272483501, batch="batch02"},
    {id="1256941518036406273-1270165853756719214", name="sexy ahh car.json", creator="wowzerzman", post="Monday, August 5, 2024 4:45 PM", sha="61d72a3b0243faf519f7b6265561fe3f07ff937f4fd1a8ad8d418790a05412c2", bytes=3687, jsonFile="005_61d72a3b0243.json", previewFile="005_61d72a3b0243.jpg", filename="mMV_sexy_ahh_car_json_61d72a3b.json", model=2598648200, batch="batch02"},
    {id="1256941518036406273-1270836650443804745", name="A$AP Rocky's Mercedes 190E (edited)", creator="Rclowrider1", post="Wednesday, August 7, 2024 1:11 PM", sha="c9113fbccc25cfc5f70956161b0de25cef894f135fcb6aa895b00b08c1c7d2aa", bytes=3695, jsonFile="006_c9113fbccc25.json", previewFile="006_c9113fbccc25.jpg", filename="mMV_A_AP_Rocky_s_Mercedes_190E_edited_c9113fbc.json", model=3054795149, batch="batch02"},
    {id="1256941518036406273-1282327035120975934", name="vh moddemr.bean.json", creator="Allan 383000", post="Sunday, September 8, 2024 6:09 AM", sha="bb6ae035be4efc37092775d4305cca07218d97329463c1e5c17bfa144375568e", bytes=9294, jsonFile="007_bb6ae035be4e.json", previewFile="007_bb6ae035be4e.jpg", filename="mMV_vh_moddemr_bean_json_bb6ae035.json", model=931280609, batch="batch02"},
    {id="1256941518036406273-1315085318294081687", name="Niobe FASTESTCAR.json", creator="Circus", post="Saturday, December 7, 2024 2:39 PM", sha="4e8c92b7e2ba8052e8d2e9f291690d5bd6ff2ec90827c78ca9e9506a17f89690", bytes=3689, jsonFile="008_4e8c92b7e2ba.json", previewFile="008_4e8c92b7e2ba.jpg", filename="mMV_Niobe_FASTESTCAR_json_4e8c92b7.json", model=1881415402, batch="batch02"},
    {id="1256941518036406273-1347042129796399319", name="Entity XXR All colors stick Pure Gold Modded Color (edited)", creator="PurppTastyy", post="Wednesday, March 5, 2025 7:04 PM", sha="1ffc8ea88f5bcac7d66148196893f7a70ddf116a49906015030c1973c45b48cd", bytes=3698, jsonFile="009_1ffc8ea88f5b.json", previewFile="009_1ffc8ea88f5b.jpg", filename="mMV_Entity_XXR_All_colors_stick_Pure_Gold_Modded_Colo_1ffc8ea8.json", model=2174267100, batch="batch02"},
    {id="1256941518036406273-1357015605219426375", name="crew logo will look different on your account so just remove it if you want to (edited)", creator="inx", post="Wednesday, April 2, 2025 8:35 AM", sha="05961c8ba560d57e560cdb6fd654e7b188ed1006fe7f034294c2b2d361fd4860", bytes=3697, jsonFile="010_05961c8ba560.json", previewFile="010_05961c8ba560.jpg", filename="mMV_crew_logo_will_look_different_on_your_account_so__05961c8b.json", model=2754593701, batch="batch02"},
    {id="1256941518036406273-1357839026677350602", name="Insurget - Bennys - Chameleon.json", creator="MrLonjas", post="Friday, April 4, 2025 3:07 PM", sha="4792888a01101b6a6c1f744771cc6eb2e05130be162a0f0173e0f8a0a5abbb67", bytes=3692, jsonFile="011_4792888a0110.json", previewFile="011_4792888a0110.jpg", filename="mMV_Insurget_Bennys_Chameleon_json_4792888a.json", model=2370534026, batch="batch02"},
    {id="1256941518036406273-1362092134173507674", name="car with bennys wheel.json", creator="33k zz", post="Wednesday, April 16, 2025 8:47 AM", sha="4c7e8cbe5bdf9d5d92bb0f1021af59ddca16eb8053473c9a490c4652da994d71", bytes=3696, jsonFile="012_4c7e8cbe5bdf.json", previewFile="012_4c7e8cbe5bdf.jpg", filename="mMV_car_with_bennys_wheel_json_4c7e8cbe.json", model=2042703219, batch="batch02"},
    {id="1256941518036406273-1365739924363411557", name="Red-Imorgon.json", creator="Stoney", post="Saturday, April 26, 2025 10:22 AM", sha="d4eeebcc6d662309b1479aaa3a9da616a31b2229c5dcc4cfde1da69c53b6aa58", bytes=3690, jsonFile="013_d4eeebcc6d66.json", previewFile="013_d4eeebcc6d66.jpg", filename="mMV_Red_Imorgon_json_d4eeebcc.json", model=3162245632, batch="batch02"},
    {id="1256941518036406273-1373326736082604083", name="10F Widebody.json", creator="Arnas", post="Saturday, May 17, 2025 8:50 AM", sha="9e1a187ca53a4852ee0a0b42f8a6fae931039be48b9fdbeeab3635644394529c", bytes=4085, jsonFile="014_9e1a187ca53a.json", previewFile="014_9e1a187ca53a.jpg", filename="mMV_10F_Widebody_json_9e1a187c.json", model=274946574, batch="batch02"},
    {id="1256941518036406273-1375558745970577460", name="BMW M2 F87 with original bmw color", creator="001", post="Friday, May 23, 2025 12:39 PM", sha="1c9aa91a600bd8d9acba2365750ace3b68fea6d3b56a724abd3cc512964f6d97", bytes=4094, jsonFile="015_1c9aa91a600b.json", previewFile="015_1c9aa91a600b.jpg", filename="mMV_BMW_M2_F87_with_original_bmw_color_1c9aa91a.json", model=1755697647, batch="batch02"},
    {id="1256941518036406273-1378175706277613629", name="The Experiment.json", creator="Sani7y", post="Friday, May 30, 2025 5:58 PM", sha="724493e99784914565d6039f7a64589ea6e097cbc2e0dc268cf3cf43828913c7", bytes=3691, jsonFile="016_724493e99784.json", previewFile="016_724493e99784.jpg", filename="mMV_The_Experiment_json_724493e9.json", model=196747873, batch="batch02"},
    {id="1256941518036406273-1378692094478127185", name="best vehicle in the game", creator="GREEK_ICXCNIKA", post="Sunday, June 1, 2025 4:10 AM", sha="7bdf790692a1cab197ead41670b087b82c638c53ca72ce6523cec76c61814857", bytes=4091, jsonFile="017_7bdf790692a1.json", previewFile="017_7bdf790692a1.jpg", filename="mMV_best_vehicle_in_the_game_7bdf7906.json", model=3005788552, batch="batch02"},
    {id="1256941518036406273-1415960049368432650", name="Wanted to do something light for the reaper", creator="StellarNas", post="Friday, September 12, 2025 12:19 AM", sha="19f76bd096e7c6ef4e60e3d1b03830ee516133c92a30f6e0990fb04ee1813a37", bytes=4082, jsonFile="018_19f76bd096e7.json", previewFile="018_19f76bd096e7.jpg", filename="mMV_Wanted_to_do_something_light_for_the_reaper_19f76bd0.json", model=234062309, batch="batch02"},
    {id="1256941518036406273-1420485027896103033", name="AA- Vysser", creator="AყꙆo⳽ Cᥲtᥱᥒᥲ", post="Wednesday, September 24, 2025 12:00 PM", sha="9983b691478d45a77ff91382b019eb4dd8e98d25b18c46ef7ca86d071ec20749", bytes=4092, jsonFile="019_9983b691478d.json", previewFile="019_9983b691478d.jpg", filename="mMV_AA_Vysser_9983b691.json", model=2674840994, batch="batch02"},
    {id="1256941518036406273-1424690051539009588", name="TORE.json", creator="alex12345678", post="Monday, October 6, 2025 2:29 AM", sha="0fbb13a986a9249eb8980cbbba8f2830c7d32a9f9c16791b8cb9bdd07558899e", bytes=4096, jsonFile="020_0fbb13a986a9.json", previewFile="020_0fbb13a986a9.jpg", filename="mMV_TORE_json_0fbb13a9.json", model=1455990255, batch="batch02"},
    {id="1256941518036406273-1426223395930116107", name="senital gts one of my fav cars (", creator="halelhaim", post="Friday, October 10, 2025 8:02 AM", sha="94fd0cd995c606bff6746aadd16dbd06ff7fc00fdcaab1fe561d408b8c205d27", bytes=3693, jsonFile="021_94fd0cd995c6.json", previewFile="021_94fd0cd995c6.jpg", filename="mMV_senital_gts_one_of_my_fav_cars_94fd0cd9.json", model=2709293299, batch="batch02"},
    {id="1256941518036406273-1427713636570501191", name="just another BMW", creator="Panda_666_8", post="Tuesday, October 14, 2025 10:44 AM", sha="f1e3e52637d46665aebd469498ead4267f8527407640a77cc00862a078f1268b", bytes=4082, jsonFile="022_f1e3e52637d4.json", previewFile="022_f1e3e52637d4.jpg", filename="mMV_just_another_BMW_f1e3e526.json", model=2709293299, batch="batch02"},
    {id="1256941518036406273-1429453847058972765", name="Baller ST Panic.json", creator="zHorixzon", post="Sunday, October 19, 2025 5:59 AM", sha="85b7ed4721e1e8a3a18aaaaa184ba4208818df5abf971496f3c8bdc2e59ae79f", bytes=4090, jsonFile="023_85b7ed4721e1.json", previewFile="023_85b7ed4721e1.jpg", filename="mMV_Baller_ST_Panic_json_85b7ed47.json", model=359875117, batch="batch02"},
    {id="1256941518036406273-1431509496223629372", name="Clean Osiris Unselected Pearl and Epsi", creator="xleoo.7", post="Friday, October 24, 2025 10:07 PM", sha="b67411a4d6f0ea0f5316552a040eb1376b3b3fff0ff924d5305905a48790a78d", bytes=4094, jsonFile="024_b67411a4d6f0.json", previewFile="024_b67411a4d6f0.jpg", filename="mMV_Clean_Osiris_Unselected_Pearl_and_Epsi_b67411a4.json", model=1987142870, batch="batch02"},
    {id="1256941518036406273-1433987542474297355", name="55 BOMB Everon.json", creator="Robs", post="Friday, October 31, 2025 6:14 PM", sha="4e3a85a8f2347cff9d0f1d29dac93f2aeea8b979ccba7a756e0295a1fc4171db", bytes=10722, jsonFile="025_4e3a85a8f234.json", previewFile="025_4e3a85a8f234.jpg", filename="mMV_55_BOMB_Everon_json_4e3a85a8.json", model=2538945576, batch="batch02"},
    {id="1256941518036406273-1435747197592535192", name="Yellow F1.json", creator="Shadow_4475", post="Wednesday, November 5, 2025 1:46 PM", sha="8f898b6f7712d80a5245e7651b2341a85950723a32a148ed712373eff0f17bb5", bytes=3699, jsonFile="026_8f898b6f7712.json", previewFile="026_8f898b6f7712.jpg", filename="mMV_Yellow_F1_json_8f898b6f.json", model=2754593701, batch="batch02"},
    {id="1256941518036406273-1439038976169345084", name="PEEL.json", creator="scubasteve", post="Friday, November 14, 2025 3:47 PM", sha="d60d672b21e12659bebd0a5d37de403f91a3812d1a3898260dfd26353fcd7727", bytes=4091, jsonFile="027_d60d672b21e1.json", previewFile="027_d60d672b21e1.jpg", filename="mMV_PEEL_json_d60d672b.json", model=931280609, batch="batch02"},
    {id="1256941518036406273-1444816153624051885", name="Coquette D10 Mothess.json", creator="mothess", post="Sunday, November 30, 2025 2:23 PM", sha="712e5115884423dc064a0c5564ec75caef01ece3139e7688afacb75ad3fff1e6", bytes=4094, jsonFile="028_712e51158844.json", previewFile="028_712e51158844.jpg", filename="mMV_Coquette_D10_Mothess_json_712e5115.json", model=2566281822, batch="batch02"},
    {id="1256941518036406273-1448554475827757118", name="sentinel xs4 bennys new.json", creator="IAMCHOCO75123", post="Wednesday, December 10, 2025 9:58 PM", sha="db36c24598173fa5c3b16d73b63b28d139221e4428eaa58a9ef1662ac44da3bd", bytes=4079, jsonFile="029_db36c2459817.json", previewFile="029_db36c2459817.jpg", filename="mMV_sentinel_xs4_bennys_new_json_db36c245.json", model=3936328504, batch="batch02"},
    {id="1256941518036406273-1448581183620513833", name="saves w/o the top and rear rotor", creator="funnycatvideowatcher", post="Wednesday, December 10, 2025 11:44 PM", sha="66232ee7c1f605bea0a88f6cdfa62f8570b6a750ec7d2dae83081b16fa11dce5", bytes=5793, jsonFile="030_66232ee7c1f6.json", previewFile="030_66232ee7c1f6.jpg", filename="mMV_saves_w_o_the_top_and_rear_rotor_66232ee7.json", model=2449479409, batch="batch02"},
    {id="1256941518036406273-1448598760392359956", name="Modded knoway car", creator="sisi_lurken", post="Thursday, December 11, 2025 12:54 AM", sha="454ce246725084b39fb995d0f388ea3c2b64d726e02270eea95cb6c9958f8cec", bytes=4087, jsonFile="031_454ce2467250.json", previewFile="031_454ce2467250.jpg", filename="mMV_Modded_knoway_car_454ce246.json", model=507621923, batch="batch02"},
    {id="1256941518036406273-1448601329663610911", name="Comet Retro Custom", creator="99k", post="Thursday, December 11, 2025 1:04 AM", sha="a1f1057019a6fcb0172450a93140dd00c59c097ee818add640b8e4098496fb76", bytes=4089, jsonFile="032_a1f1057019a6.json", previewFile="032_a1f1057019a6.jpg", filename="mMV_Comet_Retro_Custom_a1f10570.json", model=2272483501, batch="batch02"},
    {id="1256941518036406273-1448736523343106174", name="Buffalo STX Pursuit", creator="Jaime2002", post="Thursday, December 11, 2025 10:01 AM", sha="e1abff5e02e5b4eaa3c6c8af6409852c586aedc5f9acfb21581a94be5aabfbc3", bytes=4084, jsonFile="033_e1abff5e02e5.json", previewFile="033_e1abff5e02e5.jpg", filename="mMV_Buffalo_STX_Pursuit_e1abff5e.json", model=617517171, batch="batch02"},
    {id="1256941518036406273-1449129669189439522", name="bmw/sentinel XS4 street config (edited)", creator="StarMarine321", post="Friday, December 12, 2025 12:03 PM", sha="3dc9627e38a75b7f04e64adff5e3733f7795789808ccdad75e4f723dfe859418", bytes=4087, jsonFile="034_3dc9627e38a7.json", previewFile="034_3dc9627e38a7.jpg", filename="mMV_bmw_sentinel_XS4_street_config_edited_3dc9627e.json", model=3936328504, batch="batch02"},
    {id="1256941518036406273-1449707177932619788", name="Pfister Astrale (Since It's Not In Menu) for those who want it", creator="Pancho", post="Sunday, December 14, 2025 2:18 AM", sha="7e087b49205e17261a754df8c271e06deb1505335a5646866d83575858f20eb9", bytes=3364, jsonFile="035_7e087b49205e.json", previewFile="035_7e087b49205e.jpg", filename="mMV_Pfister_Astrale_Since_It_s_Not_In_Menu_for_those__7e087b49.json", model=1596736441, batch="batch02"},
    {id="1256941518036406273-1449962160162738176", name="Porsche 928.json", creator="CrustyButtWipe", post="Sunday, December 14, 2025 7:11 PM", sha="b7471baa509b8f8dc5fca06ea07d1f4430c8dad28a20f0a3779f3a20ddbba26e", bytes=4089, jsonFile="036_b7471baa509b.json", previewFile="036_b7471baa509b.jpg", filename="mMV_Porsche_928_json_b7471baa.json", model=1596736441, batch="batch02"},
    {id="1256941518036406273-1450195814730305627", name="Pretty easy to make, but i'm gonna drop it bc I think it looks cool", creator="v", post="Monday, December 15, 2025 10:40 AM", sha="a8c8426abee8b42f139370c2d428d9d7ce172af7559146b259ed3bf96d09ba09", bytes=4084, jsonFile="037_a8c8426abee8.json", previewFile="037_a8c8426abee8.jpg", filename="mMV_Pretty_easy_to_make_but_i_m_gonna_drop_it_bc_I_th_a8c8426a.json", model=196747873, batch="batch02"},
    {id="1256941518036406273-1450528683696586922", name="My first car i made w cherax (edited)", creator="TzerooGTA", post="Tuesday, December 16, 2025 8:43 AM", sha="03a095eb649e56d845e1f4971813fa5f2a5e8284bf5ecf6e8bee5d60a5ec295f", bytes=4085, jsonFile="038_03a095eb649e.json", previewFile="038_03a095eb649e.jpg", filename="mMV_My_first_car_i_made_w_cherax_edited_03a095eb.json", model=3126015148, batch="batch02"},
    {id="1256941518036406273-1450655960619286622", name="Benefactor Vorschlaghammer Based on the Mercedes-Benz W124 AMG Drift Spec The best spoiler…", creator="SnuXSley", post="Tuesday, December 16, 2025 5:08 PM", sha="19122221173298d0cb740dcee025f09aed75be17add5cd9790452733f6e2e4a0", bytes=3683, jsonFile="039_191222211732.json", previewFile="039_191222211732.jpg", filename="mMV_Benefactor_Vorschlaghammer_Based_on_the_Mercedes__19122221.json", model=4151380270, batch="batch02"},
    {id="1256941518036406273-1450907954348818463", name="mr bean mini.json", creator="Jarzy", post="Wednesday, December 17, 2025 9:50 AM", sha="54513b5a15cf864599ec67cdf6578f0efcdcbd94c4cd8f26398815b864a0d5da", bytes=4096, jsonFile="040_54513b5a15cf.json", previewFile="040_54513b5a15cf.jpg", filename="mMV_mr_bean_mini_json_54513b5a.json", model=931280609, batch="batch02"},
    {id="1256941518036406273-1451002064980410399", name="grotti turizmo omaggio", creator="czterykoniemechaniczne", post="Wednesday, December 17, 2025 4:04 PM", sha="37294d58f1552364a154da30ff07f515a498b593f60ba955ffeb5f09ebd0f4b6", bytes=4081, jsonFile="041_37294d58f155.json", previewFile="041_37294d58f155.jpg", filename="mMV_grotti_turizmo_omaggio_37294d58.json", model=4171974011, batch="batch02"},
    {id="1256941518036406273-1451054038907883560", name="Albany Cvalcade x Modded Account ( Stereo System in the back ) (edited)", creator="Mxrtn Project's", post="Wednesday, December 17, 2025 7:30 PM", sha="7ae760a68e67ec4010d599273e6c324d2c41f30e768a4ae99c2d79d79c9a948a", bytes=4086, jsonFile="042_7ae760a68e67.json", previewFile="042_7ae760a68e67.jpg", filename="mMV_Albany_Cvalcade_x_Modded_Account_Stereo_System_in_7ae760a6.json", model=2006918058, batch="batch02"},
    {id="1256941518036406273-1451239056187855062", name="APC modded", creator="Jelq king", post="Thursday, December 18, 2025 7:45 AM", sha="4422f2921a1c42ba4ba693f0969ee08c765c63e7c889669901e7c648a9eb0a9a", bytes=4074, jsonFile="043_4422f2921a1c.json", previewFile="043_4422f2921a1c.jpg", filename="mMV_APC_modded_4422f292.json", model=562680400, batch="batch02"},
    {id="1256941518036406273-1451383648585777234", name="K Truck (edited)", creator="nate", post="Thursday, December 18, 2025 5:20 PM", sha="c387c1e1591402e84759be3ea2c07a22f761d0e03b66cf804a05d2e30f6f9477", bytes=4093, jsonFile="044_c387c1e15914.json", previewFile="044_c387c1e15914.jpg", filename="mMV_K_Truck_edited_c387c1e1.json", model=2739875593, batch="batch02"},
    {id="1256941518036406273-1451752990338846914", name="have a few dents that will buff out", creator="MinorityCrasher", post="Friday, December 19, 2025 5:48 PM", sha="1ee8cfe77ab098b748229f7db16fb40261030716b243d9d4f1a43badcf1faa46", bytes=4552, jsonFile="045_1ee8cfe77ab0.json", previewFile="045_1ee8cfe77ab0.jpg", filename="mMV_have_a_few_dents_that_will_buff_out_1ee8cfe7.json", model=2485144969, batch="batch02"},
    {id="1256941518036406273-1452034496265195751", name="a white gt3 rs", creator="baileypearce11", post="Saturday, December 20, 2025 12:26 PM", sha="c2c7678bdbcaab5a421034240defe683c1b39a266c7a1cf17611ff2b2f54b8ca", bytes=4092, jsonFile="046_c2c7678bdbca.json", previewFile="046_c2c7678bdbca.jpg", filename="mMV_a_white_gt3_rs_c2c7678b.json", model=2568944644, batch="batch02"},
    {id="1256941518036406273-1452294362770837534", name="GTO Itali.json", creator="baileyy", post="Sunday, December 21, 2025 5:39 AM", sha="712b0b7f7099df0c7d5b362d31d5db55b3903d2d9949f820da188a2beea1303d", bytes=4090, jsonFile="047_712b0b7f7099.json", previewFile="047_712b0b7f7099.jpg", filename="mMV_GTO_Itali_json_712b0b7f.json", model=3963499524, batch="batch02"},
    {id="1256941518036406273-1452522386703257632", name="My (Obey Omnis E-Gt) spec F1", creator="DreCherax", post="Sunday, December 21, 2025 8:45 PM", sha="41873be6784f87ae1bd09e50d2eaa23d027b782b88362cbdfbdde4e387e0db88", bytes=4080, jsonFile="048_41873be6784f.json", previewFile="048_41873be6784f.jpg", filename="mMV_My_Obey_Omnis_E_Gt_spec_F1_41873be6.json", model=3789743831, batch="batch02"},
    {id="1256941518036406273-1452644628330320023", name="RCV.json", creator="NescafeDrinker", post="Monday, December 22, 2025 4:51 AM", sha="c58348ca083b8df17def452a7e2b2ecc0e6ca2f4af1712f05d0f91c94e9fc18d", bytes=4089, jsonFile="049_c58348ca083b.json", previewFile="049_c58348ca083b.jpg", filename="mMV_RCV_json_c58348ca.json", model=2601952180, batch="batch02"},
    {id="1256941518036406273-1452793437181968526", name="Snot Rod from the Cars movie", creator="AhmedSteam", post="Monday, December 22, 2025 2:42 PM", sha="803bd0800d3b6e0b31e803823f1a021c0b910f247b909908792754a73b1f03c2", bytes=4076, jsonFile="050_803bd0800d3b.json", previewFile="050_803bd0800d3b.jpg", filename="mMV_Snot_Rod_from_the_Cars_movie_803bd080.json", model=444994115, batch="batch02"},
    {id="1256941518036406273-1452858562484113458", name="ModdedKuruma.json", creator="sdfbk", post="Monday, December 22, 2025 7:01 PM", sha="4d066c3ef429be9fc3b4fa8c9f17edb0b34ace18408fcd9dbc3f476520c19e1d", bytes=4089, jsonFile="051_4d066c3ef429.json", previewFile="051_4d066c3ef429.jpg", filename="mMV_ModdedKuruma_json_4d066c3e.json", model=410882957, batch="batch02"},
    {id="1256941518036406273-1453079712904646706", name="clean xs4", creator="sawaz", post="Tuesday, December 23, 2025 9:40 AM", sha="b8fa0484ba5d513b62b37f0ef10d1ce26b2bd1b0fb96b7cfd16f1c852f094e41", bytes=4092, jsonFile="052_b8fa0484ba5d.json", previewFile="052_b8fa0484ba5d.jpg", filename="mMV_clean_xs4_b8fa0484.json", model=3936328504, batch="batch02"},
    {id="1256941518036406273-1453601505235177679", name="modded Cherno2.json", creator="S100x", post="Wednesday, December 24, 2025 8:13 PM", sha="b705dcd46c911c2f9c5ca164b7bf9e65834ac88b11f5207ee4726753ecebcf99", bytes=4090, jsonFile="053_b705dcd46c91.json", previewFile="053_b705dcd46c91.jpg", filename="mMV_modded_Cherno2_json_b705dcd4.json", model=3602674979, batch="batch02"},
    {id="1256941518036406273-1453739565566394430", name="X80 Purpile.json", creator="Ocultzz", post="Thursday, December 25, 2025 5:22 AM", sha="5cfdb76105f8a6e8bd8ffbfbffab84aebd5871b93304b85b6ef905009960e930", bytes=4092, jsonFile="054_5cfdb76105f8.json", previewFile="054_5cfdb76105f8.jpg", filename="mMV_X80_Purpile_json_5cfdb761.json", model=2123327359, batch="batch02"},
    {id="1256941518036406273-1453782519781654591", name="f1 italy rsx.json", creator="luk blaettner", post="Thursday, December 25, 2025 8:12 AM", sha="62a721a35649b74b87f0686ecf17e466372d82113032aa227fdf2cdc0bde8386", bytes=4090, jsonFile="055_62a721a35649.json", previewFile="055_62a721a35649.jpg", filename="mMV_f1_italy_rsx_json_62a721a3.json", model=3145241962, batch="batch02"},
    {id="1256941518036406273-1453854198255980629", name="Banshee GTS.json", creator="Spoidermon", post="Thursday, December 25, 2025 12:57 PM", sha="c6ed11c97a019b765027987778cd9a19de7aaff9f85c6b7a854b91d6fdd978ba", bytes=4085, jsonFile="056_c6ed11c97a01.json", previewFile="056_c6ed11c97a01.jpg", filename="mMV_Banshee_GTS_json_c6ed11c9.json", model=3634959571, batch="batch02"},
    {id="1256941518036406273-1453882904668147732", name="Bmw touring.json", creator="Francisco502", post="Thursday, December 25, 2025 2:51 PM", sha="1bca72885ba9f91cf5fb8c062e3f494c85b3901a271e090249ff22ed31cdb007", bytes=4081, jsonFile="057_1bca72885ba9.json", previewFile="057_1bca72885ba9.jpg", filename="mMV_Bmw_touring_json_1bca7288.json", model=2439462158, batch="batch02"},
    {id="1256941518036406273-1453915059234406496", name="Invis copter", creator="Tyl", post="Thursday, December 25, 2025 4:59 PM", sha="d5b1ee9107d168235fd48f09de0e26488994d87cfbf4e0f669ee49db4b6da370", bytes=5391, jsonFile="058_d5b1ee9107d1.json", previewFile="058_d5b1ee9107d1.jpg", filename="mMV_Invis_copter_d5b1ee91.json", model=2623428164, batch="batch02"},
    {id="1256941518036406273-1453986859788140636", name="Nice Monster.json", creator="DanDansen", post="Thursday, December 25, 2025 9:44 PM", sha="639966e0aa88bf060155d856263b763fa2ad80df85a2689762fa35d7d0c46715", bytes=3687, jsonFile="059_639966e0aa88.json", previewFile="059_639966e0aa88.jpg", filename="mMV_Nice_Monster_json_639966e0.json", model=2945871676, batch="batch02"},
    {id="1256941518036406273-1454443613718188119", name="heres my john wick car hope you guys enjoy", creator="ctugowg962", post="Saturday, December 27, 2025 3:59 AM", sha="6ce7fb91e26c8d13754eeae18fc15c8b68627786be49739d6fb35c6e49b63264", bytes=4082, jsonFile="060_6ce7fb91e26c.json", previewFile="060_6ce7fb91e26c.jpg", filename="mMV_heres_my_john_wick_car_hope_you_guys_enjoy_6ce7fb91.json", model=736672010, batch="batch02"},
    {id="1256941518036406273-1454833030848970895", name="VAPID DOMINATOR GTX", creator="TechRobot_", post="Sunday, December 28, 2025 5:47 AM", sha="abffc6f8abee1b81e421552777f36825b4384e16d544dd44f5f8134e5d309dbd", bytes=4086, jsonFile="061_abffc6f8abee.json", previewFile="061_abffc6f8abee.jpg", filename="mMV_VAPID_DOMINATOR_GTX_abffc6f8.json", model=3308022675, batch="batch02"},
    {id="1256941518036406273-1454870953329688662", name="POLICE CORVETTE MODDET.json", creator="S K I P P E R", post="Sunday, December 28, 2025 8:17 AM", sha="d179ed5329720c9a3abd2ff7840637846df564a46de199979335ef4602344c32", bytes=3701, jsonFile="062_d179ed532972.json", previewFile="062_d179ed532972.jpg", filename="mMV_POLICE_CORVETTE_MODDET_json_d179ed53.json", model=2042703219, batch="batch02"},
    {id="1256941518036406273-1454998510255476899", name="t20.json", creator="Jannik587", post="Sunday, December 28, 2025 4:44 PM", sha="e5ba355fa52fdf9545ce69fdbe1164931d4643ce0ac51ee1302ae7c8ed493d5f", bytes=4094, jsonFile="063_e5ba355fa52f.json", previewFile="063_e5ba355fa52f.jpg", filename="mMV_t20_json_e5ba355f.json", model=1663218586, batch="batch02"},
    {id="1256941518036406273-1455004058501906482", name="Grotti Itali Classic F1s", creator="brandon2026", post="Sunday, December 28, 2025 5:06 PM", sha="9e6c7b39c2e16efd283ee79016c28132d05d983b570dfad6226517ed8d21034a", bytes=4086, jsonFile="064_9e6c7b39c2e1.json", previewFile="064_9e6c7b39c2e1.jpg", filename="mMV_Grotti_Itali_Classic_F1s_9e6c7b39.json", model=893780296, batch="batch02"},
    {id="1256941518036406273-1455122502803132531", name="For EE only Primary/Secondary - Police Blue", creator="FlixzySus", post="Monday, December 29, 2025 12:57 AM", sha="c8e604efebc1d1ca502123e88f0a4ea4f5168d028d8f04f2ce082feac4febd60", bytes=4088, jsonFile="065_c8e604efebc1.json", previewFile="065_c8e604efebc1.jpg", filename="mMV_For_EE_only_Primary_Secondary_Police_Blue_c8e604ef.json", model=4151380270, batch="batch02"},
    {id="1256941518036406273-1455404085120340144", name="Snowman Van", creator="Wiymo", post="Monday, December 29, 2025 7:36 PM", sha="fa6207937c6b69b5bfde2ffaa8f571ad468b1aa84ab4477fb5b41dc8226ee2f6", bytes=14253, jsonFile="066_fa6207937c6b.json", previewFile="066_fa6207937c6b.jpg", filename="mMV_Snowman_Van_fa620793.json", model=65402552, batch="batch02"},
    {id="1256941518036406273-1455535909033218151", name="bravado hellfire.json", creator="Fuzzcore", post="Tuesday, December 30, 2025 4:20 AM", sha="5dcde4e2a10cae312be1e2045f7fb736d592992ebf37d94c626033306f458a84", bytes=4078, jsonFile="067_5dcde4e2a10c.json", previewFile="067_5dcde4e2a10c.jpg", filename="mMV_bravado_hellfire_json_5dcde4e2.json", model=3933619103, batch="batch02"},
    {id="1256941518036406273-1455573913172971583", name="T20 RAINBOW.json", creator="𝗠𝗢𝗡𝗦𝗧𝗘𝗥", post="Tuesday, December 30, 2025 6:51 AM", sha="7bd7a5ebe2b20241342916c540ebd259d02aa127d3a6fffb2a488d8693325795", bytes=4087, jsonFile="068_7bd7a5ebe2b2.json", previewFile="068_7bd7a5ebe2b2.jpg", filename="mMV_T20_RAINBOW_json_7bd7a5eb.json", model=1663218586, batch="batch02"},
    {id="1256941518036406273-1455643787601903617", name="F1 .json", creator="zeus", post="Tuesday, December 30, 2025 11:28 AM", sha="6a9bfc83b9e13334f6b967dec3c75f6c661b6c5f88d08b0d8402bdc43371383b", bytes=4089, jsonFile="069_6a9bfc83b9e1.json", previewFile="069_6a9bfc83b9e1.jpg", filename="mMV_F1_json_6a9bfc83.json", model=1492612435, batch="batch02"},
    {id="1256941518036406273-1455913515666636982", name="jet2.json", creator="itzz", post="Wednesday, December 31, 2025 5:20 AM", sha="184a1448a00b71c00db2870590199eaec2e39f4413249657a665f5aa66093975", bytes=4085, jsonFile="070_184a1448a00b.json", previewFile="070_184a1448a00b.jpg", filename="mMV_jet2_json_184a1448.json", model=239897677, batch="batch02"},
    {id="1256941518036406273-1455940378925469957", name="comet s2.json", creator="TryingFX", post="Wednesday, December 31, 2025 7:07 AM", sha="6cef3df155e6d873fa382f1679a7fa8cca234647f1e6fa75830d85604165b7bf", bytes=4086, jsonFile="071_6cef3df155e6.json", previewFile="071_6cef3df155e6.jpg", filename="mMV_comet_s2_json_6cef3df1.json", model=2568944644, batch="batch02"},
    {id="1256941518036406273-1456611408245428354", name="Vapid FMJ MKV Red.json", creator="Vininci", post="Friday, January 2, 2026 3:33 AM", sha="ee8aff8fecc7461c636b0cde92356d32da2977ef2043ffce0773728b36d8650d", bytes=3688, jsonFile="072_ee8aff8fecc7.json", previewFile="072_ee8aff8fecc7.jpg", filename="mMV_Vapid_FMJ_MKV_Red_json_ee8aff8f.json", model=3287642921, batch="batch02"},
    {id="1256941518036406273-1456839658804613317", name="IDK How but i did it dm me for request", creator="liam p", post="Friday, January 2, 2026 6:40 PM", sha="589cfd52b2670f79dd478e1adac93e96fc5a2dda88b5863af63586f39af2e8d5", bytes=4091, jsonFile="073_589cfd52b267.json", previewFile="073_589cfd52b267.jpg", filename="mMV_IDK_How_but_i_did_it_dm_me_for_request_589cfd52.json", model=884483972, batch="batch02"},
    {id="1256941518036406273-1457010813427650640", name="Deluxo with modded colour (edited)", creator="george230", post="Saturday, January 3, 2026 6:00 AM", sha="5f8fde06eb286fa191dcb52407d5882997502b6e6e5d1de176ca8b58b71f8480", bytes=4091, jsonFile="074_5f8fde06eb28.json", previewFile="074_5f8fde06eb28.jpg", filename="mMV_Deluxo_with_modded_colour_edited_5f8fde06.json", model=1483171323, batch="batch02"},
    {id="1256941518036406273-1457160696658661521", name="Cyclone ll.json", creator="kmnts13", post="Saturday, January 3, 2026 3:56 PM", sha="7da4fbb20efb39ef4b5f10beb0c6a492b480153577ed378cef8d39d2f5bfce20", bytes=4094, jsonFile="075_7da4fbb20efb.json", previewFile="075_7da4fbb20efb.jpg", filename="mMV_Cyclone_ll_json_7da4fbb2.json", model=386089410, batch="batch02"},
    {id="1256941518036406273-1457345025917849640", name="grotti x80 proto super burton.json", creator="arbab", post="Sunday, January 4, 2026 4:08 AM", sha="a8959ca0fcdb59ffc839617666f601285ce699dbfadf0d520a7c12f58e7ebb9a", bytes=4083, jsonFile="076_a8959ca0fcdb.json", previewFile="076_a8959ca0fcdb.jpg", filename="mMV_grotti_x80_proto_super_burton_json_a8959ca0.json", model=2123327359, batch="batch02"},
    {id="1256941518036406273-1457474151345295411", name="easy", creator="CRAZYIIIIIII", post="Sunday, January 4, 2026 12:41 PM", sha="779e6872b2181d811ff47f479950ad84b7dc0d4405b7c155d52b4dbc861a3509", bytes=3704, jsonFile="077_779e6872b218.json", previewFile="077_779e6872b218.jpg", filename="mMV_easy_779e6872.json", model=2850852987, batch="batch02"},
    {id="1256941518036406273-1457696533494501389", name="banshee gts on bennys", creator="Aspect", post="Monday, January 5, 2026 3:25 AM", sha="f8f78054845984d48dfdefd8157b359348a63cb7ec4bbbd386fd1a972ddec13f", bytes=3689, jsonFile="078_f8f780548459.json", previewFile="078_f8f780548459.jpg", filename="mMV_banshee_gts_on_bennys_f8f78054.json", model=3634959571, batch="batch02"},
    {id="1256941518036406273-1457882242692157584", name="fmj.json", creator="RedM1n", post="Monday, January 5, 2026 3:43 PM", sha="34d8fc85741b316158611c5a5225f1d6d9a60abfbd9acbf74945785071f291ed", bytes=4088, jsonFile="079_34d8fc85741b.json", previewFile="079_34d8fc85741b.jpg", filename="mMV_fmj_json_34d8fc85.json", model=3287642921, batch="batch02"},
    {id="1256941518036406273-1457889440130404487", name="FMJ MKV", creator="FreshCherrys", post="Monday, January 5, 2026 4:12 PM", sha="5cd4fa6420551c54d2039dd4de2311cf21879f8e300d2cdab18d58039c1da4e4", bytes=4080, jsonFile="080_5cd4fa642055.json", previewFile="080_5cd4fa642055.jpg", filename="mMV_FMJ_MKV_5cd4fa64.json", model=3287642921, batch="batch02"},
    {id="1256941518036406273-1457918757811781786", name="Clean Kei Truck with f1's", creator="MrAgonyFR", post="Monday, January 5, 2026 6:08 PM", sha="010a66eaad26b10c437f8a6183f0b02db11005f2e412bb0cccaeca827b2214aa", bytes=4083, jsonFile="081_010a66eaad26.json", previewFile="081_010a66eaad26.jpg", filename="mMV_Clean_Kei_Truck_with_f1_s_010a66ea.json", model=3892551591, batch="batch02"},
    {id="1256941518036406273-1457922200685383693", name="M K.json", creator="K_dimitrov45", post="Monday, January 5, 2026 6:22 PM", sha="23c284d5c054eb88532032a66981468f177720405d3c6b921c711a638842c719", bytes=4082, jsonFile="082_23c284d5c054.json", previewFile="082_23c284d5c054.jpg", filename="mMV_M_K_json_23c284d5.json", model=872704284, batch="batch02"},
    {id="1256941518036406273-1458370556570239030", name="The Eclipse 2G", creator="BubbaMoney", post="Wednesday, January 7, 2026 12:03 AM", sha="a84f73052529a7b6c2e848a86e0872d2e3af606a99cc02d78538105cd158f7c4", bytes=4093, jsonFile="083_a84f73052529.json", previewFile="083_a84f73052529.jpg", filename="mMV_The_Eclipse_2G_a84f7305.json", model=3663644634, batch="batch02"},
    {id="1256941518036406273-1458560952743104587", name="Kevin's car from Ben 10 Alien Force (not 100%  accurate cuz Rockstar's basic tunning )", creator="Funi_Kiwami", post="Wednesday, January 7, 2026 12:40 PM", sha="cba68a23a8b9a684ecaebb9a2525064f54a1ec469f9a1c71fae7d3f7ee6aa20d", bytes=4073, jsonFile="084_cba68a23a8b9.json", previewFile="084_cba68a23a8b9.jpg", filename="mMV_Kevin_s_car_from_Ben_10_Alien_Force_not_100_accur_cba68a23.json", model=1934384720, batch="batch02"},
    {id="1256941518036406273-1458569817463328822", name="Tokyo Mater (Kinda)", creator="electricbread", post="Wednesday, January 7, 2026 1:15 PM", sha="209705b0736b4c9c2ceb603a7b65e200703b5b0f8d2f44193b7fc1ab82c170a4", bytes=4098, jsonFile="085_209705b0736b.json", previewFile="085_209705b0736b.jpg", filename="mMV_Tokyo_Mater_Kinda_209705b0.json", model=1119641113, batch="batch02"},
    {id="1256941518036406273-1458821851970015233", name="gothicosiris.json", creator="eagle_d4v3", post="Thursday, January 8, 2026 5:57 AM", sha="7334e5a652fd7f5fb4df423496d55ca4e815b037119af3ced46e7f03fa08d78e", bytes=3680, jsonFile="086_7334e5a652fd.json", previewFile="086_7334e5a652fd.jpg", filename="mMV_gothicosiris_json_7334e5a6.json", model=1987142870, batch="batch02"},
    {id="1256941518036406273-1459058014446424175", name="New PFISTER.json", creator="Nikola", post="Thursday, January 8, 2026 9:35 PM", sha="a8914e3427c49d331a5ec9300b6a7c69785408dc3f234b1ce1296b352493d353", bytes=4090, jsonFile="087_a8914e3427c4.json", previewFile="087_a8914e3427c4.jpg", filename="mMV_New_PFISTER_json_a8914e34.json", model=1596736441, batch="batch02"},
    {id="1256941518036406273-1459184575556227226", name="Ignus Waffe.json", creator="Gronkel", post="Friday, January 9, 2026 5:58 AM", sha="b8a793c791723d31e7c831f0782d91d67ecae32caae2f80f11d6b97572b7fcba", bytes=4084, jsonFile="088_b8a793c79172.json", previewFile="088_b8a793c79172.jpg", filename="mMV_Ignus_Waffe_json_b8a793c7.json", model=956849991, batch="batch02"},
    {id="1256941518036406273-1459303804867575956", name="Pink and White STX Pursuit", creator="Emilia", post="Friday, January 9, 2026 1:52 PM", sha="00992766c17e61d4fb2d13c491138df36ab43c37288ae6d5e65f53df67ebbdff", bytes=4086, jsonFile="089_00992766c17e.json", previewFile="089_00992766c17e.jpg", filename="mMV_Pink_and_White_STX_Pursuit_00992766.json", model=617517171, batch="batch02"},
    {id="1256941518036406273-1459304259022487573", name="boom.json", creator="q8mey", post="Friday, January 9, 2026 1:54 PM", sha="c6ae091e7c782de15a78a44c69cfbebf559d4600c56cc7edc57bdd3eb154250e", bytes=4081, jsonFile="090_c6ae091e7c78.json", previewFile="090_c6ae091e7c78.jpg", filename="mMV_boom_json_c6ae091e.json", model=3356898886, batch="batch02"},
    {id="1256941518036406273-1459465793547796698", name="Eleggy Retro Custom Sok.json", creator="Bikou", post="Saturday, January 10, 2026 12:36 AM", sha="34d0517952cfa53b70fc7ec0236dbf2708694e8393a132d3ea91e963cc989618", bytes=4083, jsonFile="091_34d0517952cf.json", previewFile="091_34d0517952cf.jpg", filename="mMV_Eleggy_Retro_Custom_Sok_json_34d05179.json", model=196747873, batch="batch02"},
    {id="1256941518036406273-1459532704998621420", name="buccanner tile roof", creator="BeefyJoint", post="Saturday, January 10, 2026 5:01 AM", sha="c6e019af2b045aae756603752e94a4bd32d158fccaab02a72d64b5a8e5e059ec", bytes=4086, jsonFile="092_c6e019af2b04.json", previewFile="092_c6e019af2b04.jpg", filename="mMV_buccanner_tile_roof_c6e019af.json", model=3281516360, batch="batch02"},
    {id="1256941518036406273-1460699216723705937", name="10F Red-Carbon.json", creator="GermanRaGe", post="Tuesday, January 13, 2026 10:17 AM", sha="610eab888411d1687ce548b511bcf553036f01fc700a808c0a2a0d9a6fe3d1c4", bytes=4088, jsonFile="093_610eab888411.json", previewFile="093_610eab888411.jpg", filename="mMV_10F_Red_Carbon_json_610eab88.json", model=274946574, batch="batch02"},
    {id="1256941518036406273-1460923304255688946", name="Mercedes w210.json", creator="Blana_2102", post="Wednesday, January 14, 2026 1:07 AM", sha="5816981f93c7a247a2f9411c6ba0ba48b8a548266f1d5dfbe33da8fedc138904", bytes=4082, jsonFile="094_5816981f93c7.json", previewFile="094_5816981f93c7.jpg", filename="mMV_Mercedes_w210_json_5816981f.json", model=3054795149, batch="batch02"},
    {id="1256941518036406273-1461450695730397295", name="Cop Troll Car.json", creator="SerhanAbii", post="Thursday, January 15, 2026 12:03 PM", sha="9bb082bf60a2c61a8627b730541762db0c76ddad047ab0ce54c53b18dd0b1ea4", bytes=3689, jsonFile="095_9bb082bf60a2.json", previewFile="095_9bb082bf60a2.jpg", filename="mMV_Cop_Troll_Car_json_9bb082bf.json", model=1891140410, batch="batch02"},
    {id="1256941518036406273-1462112825919934758", name="WhiteVacca.json", creator="Soap (protected by Jerry)", post="Saturday, January 17, 2026 7:54 AM", sha="c3f5e78e9e553ac5e3defa3ee18b12b012c3af121985f880ec320a1ea65f6be1", bytes=4088, jsonFile="096_c3f5e78e9e55.json", previewFile="096_c3f5e78e9e55.jpg", filename="mMV_WhiteVacca_json_c3f5e78e.json", model=338562499, batch="batch02"},
    {id="1256941518036406273-1462522391132373215", name="A clean R8 with Bennys but without Bennys upgrade", creator="dave.npk", post="Sunday, January 18, 2026 11:01 AM", sha="276a4bd545cac9fd9da03a9c7f8831bc9bd2ac9bc4c9c5c6271fa1f20dda1fcb", bytes=3698, jsonFile="097_276a4bd545ca.json", previewFile="097_276a4bd545ca.jpg", filename="mMV_A_clean_R8_with_Bennys_but_without_Bennys_upgrade_276a4bd5.json", model=3400983137, batch="batch02"},
    {id="1256941518036406273-1462924337433677959", name="Goldinator.json", creator="SnOozY", post="Monday, January 19, 2026 1:39 PM", sha="e6a384a9b8d6e0355004dcc4c1367a8a5bc136a1c0697ca6c9960fa828638d95", bytes=4083, jsonFile="098_e6a384a9b8d6.json", previewFile="098_e6a384a9b8d6.jpg", filename="mMV_Goldinator_json_e6a384a9.json", model=3308022675, batch="batch02"},
    {id="1256941518036406273-1463750818132922492", name="custom car.json", creator="Enrique Jr.", post="Wednesday, January 21, 2026 8:23 PM", sha="38d6cf6009640448a16bdde9239fe9684da0fb8148d7d6719304c2b5a386893d", bytes=4087, jsonFile="099_38d6cf600964.json", previewFile="099_38d6cf600964.jpg", filename="mMV_custom_car_json_38d6cf60.json", model=2754593701, batch="batch02"},
}
for _,it in ipairs(records080) do
    local assetRoot = it.batch == "batch02" and (ROOT_DIR .. "community\\vehicles\\batch02\\") or M.assets
    it.src = assetRoot .. "json\\" .. it.jsonFile
    it.preview = assetRoot .. "previews\\" .. it.previewFile
    it.target = M.root .. it.filename
    it.status = it.batch == "batch02" and (it.sha=="34d0517952cfa53b70fc7ec0236dbf2708694e8393a132d3ea91e963cc989618" and "Batch 02: Eleggy user-tested" or "Batch 02: not yet spawn-tested") or "Pilot 01: user-tested"
    M.items[#M.items+1] = it
end

-- Build 083: APPROVED GitHub-hosted vehicles only. The private 119-file
-- review collection remains local; no third-party review asset is published by
-- the Lua script. All download URLs are derived from validated numeric IDs
-- and a hardcoded HTTPS repository root, never supplied by remote JSON.
M.liveThumbs = M.liveCacheDir .. "previews\\"
M.liveCatalogCache = M.liveCacheDir .. "catalog_cache.json"
local function validatePublished083(raw)
    if type(raw)~="string" or #raw>1024*1024 then error("Vehicles catalog too large") end
    local doc=ModVerseCommunity078.decodeJson(raw)
    if type(doc)~="table" or doc.schema~="modverse.vehicles.v1"
       or doc.published~=true or type(doc.items)~="table" or #doc.items>500 then
        error("Invalid public Vehicles catalog")
    end
    local seen,names,accepted,skipped={},{},{},0
    for _,row in ipairs(doc.items) do
        local id=type(row)=="table" and row.id or nil
        local name=type(row)=="table" and row.name or nil
        local creator=type(row)=="table" and row.creator or nil
        local sha=type(row)=="table" and row.sha256 or nil
        local thumbSha=type(row)=="table" and row.thumbnail_sha256 or nil
        local filename=type(row)=="table" and row.filename or nil
        local bytes=type(row)=="table" and row.size_bytes or nil
        local model=type(row)=="table" and row.model or nil
        local valid=type(id)=="string" and #id<=55 and id:match("^%d+%-%d+$")
          and not seen[id] and type(name)=="string" and #name>0 and #name<=180
          and type(creator)=="string" and #creator>0 and #creator<=100
          and type(sha)=="string" and #sha==64 and sha:match("^%x+$")
          and type(thumbSha)=="string" and #thumbSha==64 and thumbSha:match("^%x+$")
          and type(bytes)=="number" and bytes%1==0 and bytes>=100 and bytes<=65536
          and type(filename)=="string" and #filename<=150
          and filename:match("^mMV_[%w_%-]+%.json$") and not filename:find("..",1,true)
          and not names[filename:lower()]
          and type(model)=="number" and model%1==0 and model>=0 and model<=4294967295
        if valid then
            seen[id]=true;names[filename:lower()]=true
            accepted[#accepted+1]={
                id=id,name=name:gsub("[%z\1-\31]"," "),creator=creator:gsub("[%z\1-\31]"," "),
                post=type(row.post_date)=="string" and row.post_date:sub(1,90) or "",
                model=model,sha=sha:lower(),thumbSha=thumbSha:lower(),bytes=bytes,
                filename=filename,batch="github",remote=true,
                downloadURL=M.publicRoot.."files/"..id..".json",
                previewURL=M.publicRoot.."thumbnails/"..id..".jpg",
                -- Versioned disk cache: unchanged SHA-256 never re-downloads;
                -- updated thumbnails use new files without overwriting the old image.
                preview=M.liveThumbs..id.."_"..thumbSha:sub(1,16):lower()..".jpg",
                legacyPreview=M.liveThumbs..id..".jpg",target=M.root..filename,
                status="GitHub approved: ready to download and install",downloading=false
            }
        else skipped=skipped+1 end
    end
    return accepted,skipped
end
function M.setLiveCatalog(raw,source)
    local ok,results,skipped=pcall(validatePublished083,raw)
    if not ok then return false,tostring(results) end
    local old={}
    for _,it in ipairs(M.liveItems) do old[it.id]=it end
    for _,it in ipairs(results) do
        if old[it.id] and old[it.id].sha==it.sha then it.status=old[it.id].status end
    end
    M.liveItems=results
    -- A manual catalog refresh may retry previous failed downloads. Verified
    -- image records stay in RAM and on disk for the rest of this session.
    M.previewRequested={}
    if M.selected and M.selected.remote then
        local stillListed=false
        for _,it in ipairs(results) do
            if it.id==M.selected.id and it.sha==M.selected.sha then M.selected=it;stillListed=true;break end
        end
        if not stillListed then M.selected=nil end
    end
    M.liveStatus=(source or "GitHub")..": "..#results.." approved vehicle(s)"
        ..(skipped>0 and ("; "..skipped.." invalid skipped") or "")
    M.liveLoaded=true
    return true
end
function M.refreshLive(force)
    if M.liveBusy then return end
    if not M.liveLoaded and fileExists(M.liveCatalogCache) then
        local cached=ModVerseHash152.read(M.liveCatalogCache)
        if cached then M.setLiveCatalog(cached,"Cached GitHub") end
    end
    if not Script or not Script.QueueJob then M.liveStatus="Job queue unavailable";return end
    M.liveBusy=true;M.liveStatus="Checking GitHub Vehicles catalog..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local raw,e=httpGet(M.catalogUrl,22000,nil,{"Accept: application/json","Cache-Control: no-cache"},USER_AGENT)
            if type(raw)~="string" then error(e or "GitHub unavailable") end
            local good,why=M.setLiveCatalog(raw,"Live GitHub")
            if not good then error(why) end
            -- Cache only validated data. Never erase the last good catalog
            -- on a network failure.
            pcall(FileMgr.CreateDir,ROOT_DIR.."community\\vehicles\\")
            pcall(FileMgr.CreateDir,M.liveCacheDir)
            local part=M.liveCatalogCache..".part"
            if writeBinary(part,raw) then
                os.remove(M.liveCatalogCache)
                if not os.rename(part,M.liveCatalogCache) then os.remove(part) end
            end
        end)
        if not ok then
            M.liveStatus="GitHub refresh failed; "..(#M.liveItems>0 and "using cached results: " or "no live listings: ")..shortText(tostring(err),120)
            log("[MV083][VEHICLES][CATALOG] "..tostring(err))
        else log("[MV083][VEHICLES][CATALOG] "..M.liveStatus) end
        M.liveBusy=false;M.liveLoaded=true
    end)
end
-- MV089: SHA-256 pinned, durable disk preview cache. Preserve offline previews
-- across script reloads; a changed hash gets a new filename automatically.
function M.cachePreviewValid089(it)
    if not it or not it.remote then return false end
    local key=it.id.."|"..it.thumbSha
    local cached=M.previewVerified[key]
    if cached and cached==it.preview and fileExists(it.preview) then return true end
    local function validated(path)
        if not path or not fileExists(path) or detectImageFile(path)~="jpg" then return nil end
        local body=ModVerseHash152.read(path)
        if type(body)=="string" and #body>=100 and #body<=4*1024*1024
            and detectImageKind(body)=="jpg" and ModVerseHash152.sha256(body)==it.thumbSha then
            return body
        end
        return nil
    end
    local bytes=validated(it.preview)
    if not bytes and it.legacyPreview then
        -- Build 083-088 already saved id.jpg thumbnails. Verify the old bytes
        -- and migrate locally, without any HTTP request or destructive rename.
        bytes=validated(it.legacyPreview)
        if bytes then
            pcall(FileMgr.CreateDir,ROOT_DIR.."community\\vehicles\\")
            pcall(FileMgr.CreateDir,M.liveCacheDir)
            pcall(FileMgr.CreateDir,M.liveThumbs)
            local part=it.preview..".mv089-part"
            if writeBinary(part,bytes) then
                if fileExists(it.preview) then os.remove(it.preview) end
                if not os.rename(part,it.preview) then
                    os.remove(part)
                end
            end
            -- If migrating failed, still use the verified older cache file.
            if not fileExists(it.preview) then it.preview=it.legacyPreview end
        end
    end
    if not bytes then return false end
    if it.preview==it.legacyPreview or fileExists(it.preview) then
        M.previewVerified[key]=it.preview
        if not M.previewDiskCounted[key] then
            M.previewDiskCounted[key]=true
            M.previewStats.disk=M.previewStats.disk+1
        end
        it.previewStatus="disk-cached"
        return true
    end
    return false
end
function M.fetchPreviews(visible)
    if M.previewBusy or not Script or not Script.QueueJob then return end
    local todo={}
    for _,it in ipairs(visible) do
        if it.remote then
            local key=it.id.."|"..it.thumbSha
            if not M.cachePreviewValid089(it) and not M.previewRequested[key] then
                todo[#todo+1]=it
                M.previewRequested[key]=true
                it.previewStatus="downloading"
            end
        end
    end
    if #todo==0 then return end
    M.previewBusy=true
    Script.QueueJob(function()
        pcall(FileMgr.CreateDir,ROOT_DIR.."community\\vehicles\\")
        pcall(FileMgr.CreateDir,M.liveCacheDir)
        pcall(FileMgr.CreateDir,M.liveThumbs)
        for _,it in ipairs(todo) do
            local key=it.id.."|"..it.thumbSha
            local ok,err=pcall(function()
                -- Recheck disk in case the image was populated while queued.
                if M.cachePreviewValid089(it) then return end
                local body,e=httpGet(it.previewURL,16000,nil,{IMAGE_ACCEPT},IMAGE_USER_AGENT)
                if type(body)~="string" or #body<100 or #body>4*1024*1024
                   or detectImageKind(body)~="jpg" or ModVerseHash152.sha256(body)~=it.thumbSha then
                    error(e or "Invalid thumbnail hash/type")
                end
                local part=it.preview..".mv089-part"
                if not writeBinary(part,body) then error("Cannot write preview cache") end
                local check=ModVerseHash152.read(part)
                if type(check)~="string" or ModVerseHash152.sha256(check)~=it.thumbSha then
                    os.remove(part)
                    error("Disk preview cache checksum mismatch")
                end
                if fileExists(it.preview) then os.remove(it.preview) end
                if not os.rename(part,it.preview) then os.remove(part);error("Cannot finalize preview cache") end
                M.previewVerified[key]=it.preview
                M.previewStats.downloaded=M.previewStats.downloaded+1
                it.previewStatus="downloaded-cached"
            end)
            if not ok then
                M.previewStats.failed=M.previewStats.failed+1
                it.previewStatus="failed"
                log("[MV089][VEHICLES][PREVIEW] "..it.id.." | "..tostring(err))
            end
            if Script.Yield then Script.Yield(60) end
        end
        M.previewBusy=false
    end)
end
local function installed080(it)
    local bytes = ModVerseHash152.read(it.target)
    return type(bytes)=="string" and #bytes==it.bytes and ModVerseHash152.sha256(bytes)==it.sha
end
local function safeInstall080(it,providedData)
    if type(it)~="table" then return false,"No vehicle selected" end
    local data=providedData or ModVerseHash152.read(it.src)
    if type(data)~="string" then
        return false,"Vehicle JSON source unavailable. For local reviews, copy the Lua/ModVerse assets."
    end
    if #data~=it.bytes or ModVerseHash152.sha256(data)~=it.sha then
        return false,"Source JSON size or SHA-256 mismatch. No file installed."
    end
    if not data:find('"format"%s*:%s*"Cherax Entity"') or not data:find('"type"%s*:%s*1%s*[,}]') then
        return false,"Unexpected Cherax Entity payload. No file installed."
    end
    -- An existing Cherax\Vehicles folder is normal. On some Cherax builds,
    -- FileMgr.CreateDir() returns false when a directory already exists.
    -- Best effort only: successful staging + a hash-verified readback below
    -- establish actual write access. If the directory is genuinely missing or
    -- unwritable, the staging step reports the failure without touching saves.
    local dirCallOK, dirResult = pcall(FileMgr.CreateDir, M.root)
    if not dirCallOK then
        log("[MV083][VEHICLES][DIR] CreateDir raised an error; checking folder by staged write: " .. tostring(dirResult))
    end
    if fileExists(it.target) then
        if installed080(it) then return true,"Already installed and SHA-256 verified" end
        return false,"Target exists with different content. No overwrite performed."
    end
    local tmp=it.target..".modverse-part"
    if fileExists(tmp) then
        return false,"Old partial file detected. Remove the .modverse-part file manually."
    end
    if not writeBinary(tmp,data) then
        log("[MV083][VEHICLES][PATH] Cannot write staged JSON: "..tostring(tmp))
        return false,"Cannot write to Cherax Vehicles. Check folder permissions and path."
    end
    local saved=ModVerseHash152.read(tmp)
    if type(saved)~="string" or #saved~=it.bytes or ModVerseHash152.sha256(saved)~=it.sha then
        os.remove(tmp)
        return false,"Staged vehicle failed SHA-256 check."
    end
    if fileExists(it.target) then
        os.remove(tmp)
        return false,"Target appeared during staging, not overwriting."
    end
    if not os.rename(tmp,it.target) then
        os.remove(tmp)
        return false,"Cannot finalize JSON in Cherax Vehicles."
    end
    if not installed080(it) then
        return false,"Final vehicle could not be verified; review the target file."
    end
    return true,"Installed and SHA-256 verified: "..it.filename
end
local function installResult083(it,ok,result,reason)
    if not ok then
        it.status="Install error: "..shortText(tostring(result),115)
        log("[MV083][VEHICLES][ERROR] "..it.status)
        toast("Vehicle install failed: view status",3600)
        return false,it.status
    end
    it.status=reason
    log("[MV083][VEHICLES] "..tostring(it.name).." | "..tostring(reason))
    toast(result and "Vehicle saved to Cherax Vehicles" or "Vehicle install failed: view status",3600)
    if result and ModVerseTutorial147 then ModVerseTutorial147.open("vehicles","install") end
    return result,reason
end
function M.install(it)
    if not it then return false,"Select a vehicle" end
    if it.remote then
        if it.downloading then return false,"Download in progress" end
        if installed080(it) then
            it.status="Already installed and SHA-256 verified"
            return true,it.status
        end
        if fileExists(it.target) then
            it.status="Target exists with different content. No overwrite."
            return false,it.status
        end
        if not Script or not Script.QueueJob then return false,"Job queue unavailable" end
        it.downloading=true;it.status="Downloading verified JSON from GitHub..."
        Script.QueueJob(function()
            local ok,err=pcall(function()
                local body,e=httpGet(it.downloadURL,22000,nil,{"Accept: application/json"},USER_AGENT)
                if type(body)~="string" then error(e or "GitHub vehicle download failed") end
                local call,good,reason=pcall(safeInstall080,it,body)
                installResult083(it,call,good,reason)
            end)
            if not ok then
                it.status="Download failed: "..shortText(tostring(err),110)
                log("[MV083][VEHICLES][DOWNLOAD] "..it.id.." | "..it.status)
            end
            it.downloading=false
        end)
        return true,"Download queued"
    end
    return installResult083(it,pcall(safeInstall080,it))
end

-- Build 085: first-party GitHub transport diagnostic. This fixture is not a
-- saved vehicle and cannot install into Cherax\Vehicles. It uses the same
-- Curl/httpGet and SHA-256 logic as the GitHub Vehicles downloader, then tests
-- a staged local write under Lua\ModVerse, not under Vehicles.
function M.testGitHubDownload()
    if M.githubTestBusy then return end
    if not Script or not Script.QueueJob then
        M.githubTestStatus="FAIL: Cherax job queue unavailable"
        log("[MV085][GITHUB][TEST] "..M.githubTestStatus)
        return
    end
    M.githubTestBusy=true
    M.githubTestStatus="Downloading ModVerse diagnostic file from GitHub..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local url=M.publicRoot.."diagnostics/github-download-test.json"
            local body,why=httpGet(url,22000,nil,{"Accept: application/json","Cache-Control: no-cache"},USER_AGENT)
            if type(body)~="string" then error("GitHub HTTP failed: "..tostring(why or "empty response")) end
            local want="2204435a981c2b2a4d69d8547785b411954420b0911252a85e1ca9913236b73b"
            if #body~=281 or ModVerseHash152.sha256(body)~=want then
                error("Unexpected download size or SHA-256 mismatch; expected pinned test fixture")
            end
            -- Known ownership: this one diagnostic file is exclusively ours.
            -- Never attempt to create a vehicle save for a connectivity test.
            local target=ROOT_DIR.."github-download-test.json"
            local partial=target..".part"
            if fileExists(partial) then error("Old diagnostic .part file exists: "..partial) end
            if not writeBinary(partial,body) then error("Cannot write diagnostic file in Lua\\ModVerse") end
            local saved=ModVerseHash152.read(partial)
            if type(saved)~="string" or #saved~=#body or ModVerseHash152.sha256(saved)~=want then
                os.remove(partial)
                error("Diagnostic staged-file SHA-256 verification failed")
            end
            -- Replace only our own diagnostic file, not any vehicle/config.
            if fileExists(target) then
                local prior=ModVerseHash152.read(target)
                if type(prior)~="string" or ModVerseHash152.sha256(prior)~=want then
                    os.remove(partial)
                    error("Existing diagnostic path differs; refusing to overwrite")
                end
                os.remove(partial)
            else
                if not os.rename(partial,target) then
                    os.remove(partial)
                    error("Cannot finalize downloaded diagnostic file")
                end
            end
            local final=ModVerseHash152.read(target)
            if type(final)~="string" or #final~=281 or ModVerseHash152.sha256(final)~=want then
                error("Final downloaded diagnostic readback verification failed")
            end
            M.githubTestStatus="PASS: GitHub download + SHA-256 + saved-file verification (281 bytes)"
            log("[MV085][GITHUB][TEST] PASS | downloaded 281 bytes | SHA-256 "..want.." | "..target)
            toast("ModVerse GitHub download test PASSED",4500)
        end)
        if not ok then
            M.githubTestStatus="FAIL: "..shortText(tostring(err),135)
            log("[MV085][GITHUB][TEST] "..M.githubTestStatus)
            toast("GitHub download test failed; check log",4500)
        end
        M.githubTestBusy=false
    end)
end

-- Build 088: DriftGod-compatible native-thread JSON vehicle spawning. The stock vehicle is
-- created FIRST. Only after GTA confirms a real entity handle do we apply
-- Cherax saved-vehicle modifications. Never change the source JSON or its hash.
-- Does not modify the current player vehicle; entity routing follows Cherax helper behavior.
M.spawn = (function()
M.spawnBusy = {}
local spawnNative086 = {
    SET_VEHICLE_MOD_KIT = 0x1F2AA07F00B3217A,
    SET_VEHICLE_WHEEL_TYPE = 0x487EB21CC7295BA1,
    SET_VEHICLE_MOD = 0x6AF0636DDEDCB6DD,
    TOGGLE_VEHICLE_MOD = 0x2A1F4F37F95BAD08,
    SET_VEHICLE_COLOURS = 0x4F1D4BE3A7F24601,
    SET_VEHICLE_EXTRA_COLOURS = 0x2036F561ADD12E33,
    SET_VEHICLE_CUSTOM_PRIMARY_COLOUR = 0x7141766F91D15BEA,
    SET_VEHICLE_CUSTOM_SECONDARY_COLOUR = 0x36CED73BFED89754,
    SET_VEHICLE_WINDOW_TINT = 0x57C51E6BAD752696,
    SET_VEHICLE_NUMBER_PLATE_TEXT = 0x95A88F0B409CDA47,
    SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX = 0x9088EB5A43FFB0A1,
    SET_VEHICLE_TYRE_SMOKE_COLOR = 0xB5BA80F839791C0F,
    SET_VEHICLE_NEON_ENABLED = 0x2AA720E4287BF269,
    SET_VEHICLE_NEON_COLOUR = 0x8E0A582209A62695,
    SET_VEHICLE_EXTRA_COLOUR_5 = 0xF40DD601A65F7F19,
    SET_VEHICLE_EXTRA_COLOUR_6 = 0x6089CDF6A57F326C,
    SET_VEHICLE_TYRES_CAN_BURST = 0xEB9DC3C7D8596C46,
    SET_DRIFT_TYRES = 0x5AC79C98C5C17F05,
    SET_VEHICLE_EXTRA = 0x7EE3A3C5E4A40CC9,
    SET_VEHICLE_LIVERY = 0x60BF608F1B8CD1B6,
    CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR = 0x55E1D2758F34E437,
    CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR = 0x5FFBDEEC3E8E2009,
    SET_VEHICLE_DIRT_LEVEL = 0x79D3B596FE44EE8B,
    SET_VEHICLE_FIXED = 0x115722B1B9C14C1C,
    SET_VEHICLE_ENGINE_ON = 0x2497C4717C8B881E,
}
local function invokeSpawn086(name,...)
    local direct = VEHICLE and VEHICLE[name]
    if type(direct)=="function" then
        local ok,err=pcall(direct,...)
        if ok then return true end
        return false,tostring(err)
    end
    local hash=spawnNative086[name]
    if hash and Natives and type(Natives.InvokeVoid)=="function" then
        local ok,err=pcall(Natives.InvokeVoid,hash,...)
        if ok then return true end
        return false,tostring(err)
    end
    return false,"native unavailable: "..tostring(name)
end
local function uint086(value,min,max)
    local n=tonumber(value)
    if n and n==math.floor(n) and n>=min and n<=max then return n end
    return nil
end
local function color086(t)
    if type(t)~="table" then return nil end
    local r,g,b=uint086(t.r,0,255),uint086(t.g,0,255),uint086(t.b,0,255)
    if r and g and b then return r,g,b end
    return nil
end
local function verifySpawnSource086(it)
    if not installed080(it) then return nil,"Please install and verify this vehicle first." end
    local raw=ModVerseHash152.read(it.target)
    if type(raw)~="string" or #raw~=it.bytes or ModVerseHash152.sha256(raw)~=it.sha then
        return nil,"Installed vehicle failed SHA-256 verification."
    end
    local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
    if not ok or type(doc)~="table" or doc.format~="Cherax Entity" or doc.type~=1
       or type(doc.mods)~="table" then
        return nil,"Invalid Cherax Entity vehicle JSON."
    end
    local model=uint086(doc.model,1,4294967295)
    if not model or model~=uint086(it.model,1,4294967295) then
        return nil,"Saved vehicle model does not match the verified catalog."
    end
    return doc
end
-- Separate from spawning on purpose: NEVER call this before a valid handle.
-- Build 088: DriftGod v1.0.22 Garage's Cherax JSON restore sequence.
-- Source: uploaded DriftGod v1.0.7 Production Build 035, its DG122 flashless
-- Garage patch (saved_to_native122, apply_saved_data122, cloak/reveal timings).
-- The JSON source and verified GitHub install path remain unchanged.
local function dgNative088(name, vehicle, ...)
    -- Prefer the exact Cherax names (see natives_cherax.lua); alternate
    -- names from DriftGod remain compatible when the runtime exposes them.
    local aliases = {
        SET_VEHICLE_NEON_ENABLED = "SET_VEHICLE_NEON_LIGHT_ENABLED",
        SET_DRIFT_TYRES = "SET_DRIFT_TYRES_ENABLED",
    }
    local direct = VEHICLE and (VEHICLE[name] or VEHICLE[aliases[name] or name])
    if type(direct)=="function" then
        local ok,err=pcall(direct, vehicle, ...)
        if ok then return true end
        return false,tostring(err)
    end
    local hash=spawnNative086[name]
    if hash and Natives and type(Natives.InvokeVoid)=="function" then
        local ok,err=pcall(Natives.InvokeVoid,hash,vehicle,...)
        if ok then return true end
        return false,tostring(err)
    end
    return false,"unavailable: "..name
end
local function dgEntity088(name, vehicle, ...)
    local direct=ENTITY and ENTITY[name]
    if type(direct)=="function" then
        local ok,err=pcall(direct,vehicle,...)
        if ok then return true end
        return false,tostring(err)
    end
    local hash=({
        SET_ENTITY_VISIBLE=0xEA1C610A04DB6BBB,
        SET_ENTITY_ALPHA=0x44A0870B7E92D7C0,
        RESET_ENTITY_ALPHA=0x9B1E824FFBB7027A,
        FREEZE_ENTITY_POSITION=0x428CA6DBD1094446,
    })[name]
    if hash and Natives and type(Natives.InvokeVoid)=="function" then
        local ok,err=pcall(Natives.InvokeVoid,hash,vehicle,...)
        if ok then return true end
        return false,tostring(err)
    end
    return false,"unavailable: "..name
end
local function dgCloak088(vehicle)
    -- Same order as DriftGod DG122: hide, alpha 0, freeze. Best effort.
    dgEntity088("SET_ENTITY_VISIBLE",vehicle,false,false)
    dgEntity088("SET_ENTITY_ALPHA",vehicle,0,false)
    dgEntity088("FREEZE_ENTITY_POSITION",vehicle,true)
end
local function dgReveal088(vehicle)
    -- Restore visibility even on error or when a new spawn supersedes a job.
    dgEntity088("RESET_ENTITY_ALPHA",vehicle)
    dgEntity088("SET_ENTITY_VISIBLE",vehicle,true,false)
    dgEntity088("FREEZE_ENTITY_POSITION",vehicle,false)
end
local function dgReadNative088(name,hash,vehicle,slot)
    if VEHICLE and type(VEHICLE[name])=="function" then
        local ok,result=pcall(VEHICLE[name],vehicle,slot)
        if ok and result~=nil then return tonumber(result) end
    end
    if Natives and type(Natives.InvokeInt)=="function" then
        local ok,result=pcall(Natives.InvokeInt,hash,vehicle,slot)
        if ok and result~=nil then return tonumber(result) end
    end
    return nil
end
local function dgNormal088(doc)
    local snap={mods={},wheelType=doc.wheelType or 0,primaryColor=doc.primaryColor or 0,
        secondaryColor=doc.secondaryColor or 0,pearlescentColor=doc.pearlescentColor or 0,
        wheelColor=doc.wheelColor or 0,customPrimaryColor=doc.customPrimaryColor,
        customSecondaryColor=doc.customSecondaryColor,
        isPrimaryColorCustom=doc.isPrimaryColorCustom==true,
        isSecondaryColorCustom=doc.isSecondaryColorCustom==true,
        tyreSmokeColor=doc.tyreSmokeColor,
        windowTint=doc.windowTint,plateText=doc.plateText,plateTextIndex=doc.plateTextIndex,
        interiorColor=doc.interiorColor,dashBoardColor=doc.dashBoardColor,
        liveryID=doc.liveryID,livery2ID=doc.livery2ID,
        extras=doc.extras,disableExtras=doc.disableExtras,
        neon=doc.neonKits,bulletproofTyres=doc.bulletproofTyres,driftTyres=doc.driftTyres,
        dirtLevel=doc.dirtLevel,
    }
    -- Cherax uses one-based saved indexes; GTA natives use zero-based indexes.
    -- Exact DriftGod DG122 saved_to_native122 conversion: <=0 -> -1; n -> n-1.
    for slot=0,49 do
        local row=doc.mods["mod"..slot]
        if type(row)=="table" and tonumber(row.index) then
            local saved=tonumber(row.index)
            snap.mods[slot]={savedIndex=saved,nativeIndex=(saved<=0 and -1 or saved-1),variation=row.variation==true}
        end
    end
    return snap
end
local function dgApply088(vehicle,snap,pass,token)
    if M.spawnGeneration088~=token then
        log("[MV088][VEHICLES][SPAWN] STALE_APPLY_SKIPPED | "..tostring(pass))
        return false,{error="stale"}
    end
    local applied,failures=0,{}
    local function set(name,...)
        local ok,why=dgNative088(name,vehicle,...)
        if ok then applied=applied+1 elseif #failures<8 then failures[#failures+1]=name.." "..tostring(why) end
        return ok
    end
    -- DG122 order: mod kit, wheel type, base colors, mod slots 0-49.
    set("SET_VEHICLE_MOD_KIT",0)
    set("SET_VEHICLE_WHEEL_TYPE",snap.wheelType)
    local function colors()
        set("SET_VEHICLE_COLOURS",snap.primaryColor,snap.secondaryColor)
        set("SET_VEHICLE_EXTRA_COLOURS",snap.pearlescentColor,snap.wheelColor)
        if snap.isPrimaryColorCustom and type(snap.customPrimaryColor)=="table" then
            local c=snap.customPrimaryColor
            set("SET_VEHICLE_CUSTOM_PRIMARY_COLOUR",c.r or 0,c.g or 0,c.b or 0)
        else
            set("CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR")
        end
        if snap.isSecondaryColorCustom and type(snap.customSecondaryColor)=="table" then
            local c=snap.customSecondaryColor
            set("SET_VEHICLE_CUSTOM_SECONDARY_COLOUR",c.r or 0,c.g or 0,c.b or 0)
        else
            set("CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR")
        end
        if type(snap.tyreSmokeColor)=="table" then
            local c=snap.tyreSmokeColor
            set("SET_VEHICLE_TYRE_SMOKE_COLOR",c.r or 255,c.g or 255,c.b or 255)
        end
    end
    colors()
    for slot=0,49 do
        local mod=snap.mods[slot]
        if mod then
            if slot==18 or slot==20 or slot==22 then
                set("TOGGLE_VEHICLE_MOD",slot,mod.savedIndex>0)
            else
                set("SET_VEHICLE_MOD",slot,mod.nativeIndex,mod.variation)
            end
        end
    end
    -- Restore wheels/colors AGAIN after mods, exactly as in DG122.
    set("SET_VEHICLE_WHEEL_TYPE",snap.wheelType)
    for _,slot in ipairs({23,24}) do
        local m=snap.mods[slot]
        if m then set("SET_VEHICLE_MOD",slot,m.nativeIndex,m.variation) end
    end
    colors()
    if tonumber(snap.liveryID) and tonumber(snap.liveryID)>=0 then
        set("SET_VEHICLE_LIVERY",snap.liveryID)
    end
    if tonumber(snap.livery2ID) and tonumber(snap.livery2ID)>=0 then
        local n=tonumber(snap.livery2ID)
        set("SET_VEHICLE_MOD",48,n<=0 and -1 or n-1,false)
    end
    if snap.windowTint~=nil then set("SET_VEHICLE_WINDOW_TINT",snap.windowTint) end
    if snap.plateTextIndex~=nil then set("SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX",snap.plateTextIndex) end
    if type(snap.plateText)=="string" and #snap.plateText>0 then
        set("SET_VEHICLE_NUMBER_PLATE_TEXT",snap.plateText)
    end
    -- Preserve additional saved Cherax interior/dashboard values where APIs exist.
    if snap.interiorColor~=nil then set("SET_VEHICLE_EXTRA_COLOUR_5",snap.interiorColor) end
    if snap.dashBoardColor~=nil then set("SET_VEHICLE_EXTRA_COLOUR_6",snap.dashBoardColor) end
    for extra=1,20 do
        local enabled=nil
        if type(snap.extras)=="table" then
            enabled=snap.extras["extra"..extra]
            if enabled==nil then enabled=snap.extras[extra] end
        end
        if enabled==nil and tonumber(snap.disableExtras) then
            enabled=(math.floor(tonumber(snap.disableExtras)/2^(extra-1))%2)==0
        end
        if type(enabled)=="boolean" then set("SET_VEHICLE_EXTRA",extra,not enabled) end
    end
    if type(snap.neon)=="table" then
        for index,key in ipairs({"left","right","front","back"}) do
            set("SET_VEHICLE_NEON_ENABLED",index-1,snap.neon[key]==true)
        end
        if type(snap.neon.color)=="table" then
            local c=snap.neon.color
            set("SET_VEHICLE_NEON_COLOUR",c.r or 255,c.g or 0,c.b or 255)
        end
    end
    if snap.bulletproofTyres==true then set("SET_VEHICLE_TYRES_CAN_BURST",false) end
    if snap.driftTyres==true then set("SET_DRIFT_TYRES",true) end
    if snap.dirtLevel~=nil then set("SET_VEHICLE_DIRT_LEVEL",snap.dirtLevel) end
    set("SET_VEHICLE_FIXED")
    set("SET_VEHICLE_ENGINE_ON",true,true,false)
    local mismatches={}
    for slot=0,49 do
        local m=snap.mods[slot]
        if m and slot~=18 and slot~=20 and slot~=22 then
            local got=dgReadNative088("GET_VEHICLE_MOD",0x772960298DA26FDB,vehicle,slot)
            if got~=nil and got~=m.nativeIndex then
                local max=dgReadNative088("GET_NUM_VEHICLE_MODS",0xE38E9162A2500646,vehicle,slot)
                mismatches[#mismatches+1]="slot"..slot..":"..m.nativeIndex.."->"..got.."/max="..tostring(max)
            end
        end
    end
    local preview=table.concat(mismatches," | ")
    log("[MV088][VEHICLES][SPAWN] RESTORE | pass="..tostring(pass).." | applied="..applied.." | unavailable="..#failures.." | mismatches="..#mismatches.." | "..shortText(preview,230))
    return #failures==0 and #mismatches==0,{applied=applied,failures=failures,mismatches=mismatches}
end
local function spawnPed087()
    local ped=0
    if PLAYER and type(PLAYER.PLAYER_PED_ID)=="function" then
        local ok,value=pcall(PLAYER.PLAYER_PED_ID)
        if ok then ped=tonumber(value) or 0 end
    end
    if ped==0 and Natives and type(Natives.InvokeInt)=="function" then
        local ok,value=pcall(Natives.InvokeInt,0xD80958FC74E988A6)
        if ok then ped=tonumber(value) or 0 end
    end
    return ped
end
local function spawnPlayer087()
    local pid=nil
    if PLAYER and type(PLAYER.PLAYER_ID)=="function" then
        local ok,value=pcall(PLAYER.PLAYER_ID)
        if ok then pid=tonumber(value) end
    end
    if not pid and Natives and type(Natives.InvokeInt)=="function" then
        local ok,value=pcall(Natives.InvokeInt,0x4F8644AF03D0E0D6)
        if ok then pid=tonumber(value) end
    end
    return pid
end
local function spawnCoords087()
    local ped=spawnPed087()
    if ped==0 then return nil,"Player ped not available" end
    local a,b,c=nil,nil,nil
    if ENTITY and type(ENTITY.GET_ENTITY_COORDS)=="function" then
        local ok,x,y,z=pcall(ENTITY.GET_ENTITY_COORDS,ped,true)
        if ok then a,b,c=x,y,z end
    end
    if a==nil and Natives and type(Natives.InvokeV3)=="function" then
        local ok,x,y,z=pcall(Natives.InvokeV3,0x3FEF770D40960D5A,ped,true)
        if ok then a,b,c=x,y,z end
    end
    local x,y,z=nil,nil,nil
    if type(a)=="table" then
        x,y,z=tonumber(a.x or a.X or a[1]),tonumber(a.y or a.Y or a[2]),tonumber(a.z or a.Z or a[3])
    elseif type(a)=="userdata" then
        local ok1,v1=pcall(function() return a.x or a.X end)
        local ok2,v2=pcall(function() return a.y or a.Y end)
        local ok3,v3=pcall(function() return a.z or a.Z end)
        if ok1 and ok2 and ok3 then x,y,z=tonumber(v1),tonumber(v2),tonumber(v3) end
    else
        x,y,z=tonumber(a),tonumber(b),tonumber(c)
    end
    if not (x and y and z) then return nil,"Player coordinates not available" end
    local heading=0
    if ENTITY and type(ENTITY.GET_ENTITY_HEADING)=="function" then
        local ok,value=pcall(ENTITY.GET_ENTITY_HEADING,ped)
        if ok and tonumber(value) then heading=tonumber(value) end
    elseif Natives and type(Natives.InvokeFloat)=="function" then
        local ok,value=pcall(Natives.InvokeFloat,0xE83D4F9BA2A38914,ped)
        if ok and tonumber(value) then heading=tonumber(value) end
    end
    local rad=math.rad(heading)
    return {x=x-math.sin(rad)*6,y=y+math.cos(rad)*6,z=z+0.60,heading=heading}
end
local function compatibleStockSpawn087(model)
    -- Cherax's native API and DriftGod use signed vehicle hashes in some
    -- calls even when the saved JSON stores the unsigned 32-bit value.
    local signed=model>2147483647 and model-4294967296 or model
    local tried={}
    local function attempt(label,fn)
        local ok,value=pcall(fn)
        local handle=ok and tonumber(value) or nil
        if handle and handle~=0 then
            log("[MV087][VEHICLES][SPAWN][ROUTE] "..label.." | handle="..tostring(handle))
            return handle,label
        end
        if #tried<14 then tried[#tried+1]=label.."="..(ok and "returned 0" or shortText(tostring(value),65)) end
        return nil,nil
    end
    -- DriftGod-compatible fallback retained from Build 087.
    -- GTA.SpawnVehicleForPlayer is a documented native-thread Cherax helper.
    if GTA and type(GTA.SpawnVehicleForPlayer)=="function" then
        local pid=spawnPlayer087()
        if pid then
            local h,route=attempt("GTA.SpawnVehicleForPlayer signed",function()
                return GTA.SpawnVehicleForPlayer(signed,pid,6.0)
            end)
            if h then return h,route end
            if signed~=model then
                h,route=attempt("GTA.SpawnVehicleForPlayer unsigned",function()
                    return GTA.SpawnVehicleForPlayer(model,pid,6.0)
                end)
                if h then return h,route end
            end
        else
            tried[#tried+1]="SpawnVehicleForPlayer player ID unavailable"
        end
    end
    local coords,coordErr=spawnCoords087()
    if not coords then
        tried[#tried+1]="position unavailable: "..tostring(coordErr)
    else
        local x,y,z,heading=coords.x,coords.y,coords.z,coords.heading
        if GTA and type(GTA.SpawnVehicle)=="function" then
            local h,route=attempt("GTA.SpawnVehicle signed local",function()
                return GTA.SpawnVehicle(signed,x,y,z,heading,false,true)
            end)
            if h then return h,route end
            if signed~=model then
                h,route=attempt("GTA.SpawnVehicle unsigned local",function()
                    return GTA.SpawnVehicle(model,x,y,z,heading,false,true)
                end)
                if h then return h,route end
            end
        end
        if VEHICLE and type(VEHICLE.CREATE_VEHICLE)=="function" then
            local h,route=attempt("VEHICLE.CREATE_VEHICLE local",function()
                return VEHICLE.CREATE_VEHICLE(signed,x,y,z,heading,false,false,false)
            end)
            if h then return h,route end
            if signed~=model then
                h,route=attempt("VEHICLE.CREATE_VEHICLE unsigned local",function()
                    return VEHICLE.CREATE_VEHICLE(model,x,y,z,heading,false,false,false)
                end)
                if h then return h,route end
            end
        end
        if Natives and type(Natives.InvokeInt)=="function" then
            local h,route=attempt("Natives.InvokeInt CREATE_VEHICLE signed local",function()
                return Natives.InvokeInt(0xAF35D0D2583051B0,signed,x,y,z,heading,false,false,false)
            end)
            if h then return h,route end
            if signed~=model then
                h,route=attempt("Natives.InvokeInt CREATE_VEHICLE unsigned local",function()
                    return Natives.InvokeInt(0xAF35D0D2583051B0,model,x,y,z,heading,false,false,false)
                end)
                if h then return h,route end
            end
        end
    end
    return nil,table.concat(tried," | ")
end
-- MV089: Check installed GTA game content before spawning. Missing model
-- natives are treated as unknown, not as false. Signed/unsigned hashes are
-- tried because Cherax versions may expose either Lua representation.
local function probeGameModel089(model)
    local signed=model>2147483647 and model-4294967296 or model
    local hashes=signed==model and {model} or {signed,model}
    local fields={
        {"IS_MODEL_IN_CDIMAGE",0x35B9E0803292B641},
        {"IS_MODEL_VALID",0xC0296A2EDF545E92},
        {"IS_MODEL_A_VEHICLE",0x19AAC8F07BFEC53E},
    }
    local result={}
    for _,info in ipairs(fields) do
        local name,nativeHash=info[1],info[2]
        local tried,positive,method=0,false,"none"
        for _,h in ipairs(hashes) do
            local ok,value=false,nil
            if STREAMING and type(STREAMING[name])=="function" then
                ok,value=pcall(STREAMING[name],h)
                if ok and type(value)=="boolean" then method="STREAMING."..name end
            end
            if (not ok or type(value)~="boolean") and Natives and type(Natives.InvokeBool)=="function" then
                ok,value=pcall(Natives.InvokeBool,nativeHash,h)
                if ok and type(value)=="boolean" then method="Natives.InvokeBool" end
            end
            if ok and type(value)=="boolean" then
                tried=tried+1
                if value then positive=true end
            end
        end
        -- An available API returning false for all tested hashes is reliable
        -- negative evidence. No API at all results in nil (unknown).
        if positive then result[name]=true
        elseif tried>0 then result[name]=false
        else result[name]=nil end
        result[name.."_source"]=method
    end
    return result
end
return function(it)
    if type(it)~="table" then return false,"Select a vehicle first." end
    if M.spawnBusy[it.id] then return false,"Spawn already in progress." end
    local doc,reason=verifySpawnSource086(it)
    if not doc then it.spawnStatus=reason; return false,reason end
    if not (Script and type(Script.QueueJob)=="function") then
        it.spawnStatus="Cherax job queue unavailable.";return false,it.spawnStatus
    end
    local hasHelper=(GTA and (type(GTA.SpawnVehicle)=="function" or type(GTA.SpawnVehicleForPlayer)=="function"))
        or (VEHICLE and type(VEHICLE.CREATE_VEHICLE)=="function")
        or (Natives and type(Natives.InvokeInt)=="function")
    if not hasHelper then it.spawnStatus="Cherax vehicle spawn helper unavailable";return false,it.spawnStatus end
    M.spawnGeneration088=(M.spawnGeneration088 or 0)+1
    local token=M.spawnGeneration088
    M.spawnBusy[it.id]=true
    it.spawnStatus="Preparing stock vehicle, then exact DriftGod saved-data restore..."
    local target=it
    Script.QueueJob(function()
        local model=uint086(doc.model,1,4294967295)
        local handle=0
        local revealed=false
        local function reveal()
            if handle~=0 and not revealed then
                dgReveal088(handle);revealed=true
                log("[MV088][VEHICLES][SPAWN] REVEALED | handle="..tostring(handle))
            end
        end
        local ok,err=pcall(function()
            local availability=probeGameModel089(model)
            local inCD=availability.IS_MODEL_IN_CDIMAGE
            local valid=availability.IS_MODEL_VALID
            local vehicle=availability.IS_MODEL_A_VEHICLE
            log("[MV089][VEHICLES][MODEL] "..tostring(target.name)
                .." | hash="..tostring(model)
                .." | inCD="..tostring(inCD)
                .." | valid="..tostring(valid)
                .." | vehicle="..tostring(vehicle))
            -- Avoid blocking legitimate modded/DLC models on a single
            -- unreliable native. Require CDIMAGE plus another negative check.
            if inCD==false and (valid==false or vehicle==false) then
                local hint=model==956849991 and " Weaponized Ignus (ignus2) is Enhanced-only." or " Vehicle may require Enhanced or missing game content."
                error("STOCK_MODEL_UNAVAILABLE | Not installed in this GTA build."..hint)
            end
            local streamed=false
            if ModVerse067 and type(ModVerse067.streamReady)=="function" and ModVerse067.streamReady() then
                local signed=model>2147483647 and model-4294967296 or model
                for _,hash in ipairs(signed==model and {model} or {signed,model}) do
                    if ModVerse067.requestModel(hash) then
                        local start=nowMs()
                        repeat
                            if ModVerse067.hasModel(hash) then streamed=true;break end
                            if Script.Yield then Script.Yield(80) else break end
                        until nowMs()-start>=4200
                        if streamed then break end
                    end
                end
            end
            log("[MV088][VEHICLES][SPAWN] PHASE_1_STOCK | "..tostring(target.name).." | streamed="..tostring(streamed))
            local route
            handle,route=compatibleStockSpawn087(model)
            if not handle or handle==0 then
                handle=0
                local hint=model==956849991 and " Weaponized Ignus (ignus2) requires GTA Enhanced stock assets." or " Model or spawn context may be incompatible with this GTA installation."
                error("STOCK_SPAWN_REJECTED | "..shortText(tostring(route),230).."."..hint)
            end
            target.spawnStatus="Stock spawned by "..tostring(route)..". Restoring Cherax JSON..."
            local snap=dgNormal088(doc)
            log("[MV088][VEHICLES][SPAWN] INDEX_CONVERSION | slot14 saved="..tostring(snap.mods[14] and snap.mods[14].savedIndex or "nil").." -> native="..tostring(snap.mods[14] and snap.mods[14].nativeIndex or "nil").." | slot23 saved="..tostring(snap.mods[23] and snap.mods[23].savedIndex or "nil").." -> native="..tostring(snap.mods[23] and snap.mods[23].nativeIndex or "nil"))
            log("[MV088][VEHICLES][SPAWN] PHASE_2_MODS | stock handle="..tostring(handle))
            dgCloak088(handle)
            local passOK,info=dgApply088(handle,snap,"hidden-now",token)
            if Script.Yield then Script.Yield(90) end
            passOK,info=dgApply088(handle,snap,"hidden-90ms",token)
            if Script.Yield then Script.Yield(160) end
            passOK,info=dgApply088(handle,snap,"hidden-250ms",token)
            reveal()
            if Script.Yield then Script.Yield(650) end
            passOK,info=dgApply088(handle,snap,"post-reveal-900ms",token)
            if Script.Yield then Script.Yield(1300) end
            passOK,info=dgApply088(handle,snap,"post-reveal-2200ms-final",token)
            if passOK then
                target.spawnStatus="Spawned and saved customizations restored (DriftGod sequence)."
                log("[MV088][VEHICLES][SPAWN] PASS | "..tostring(target.name).." | handle="..handle.." | stock first; DG122 timing complete")
                toast("ModVerse: vehicle spawned with saved mods",3900)
            else
                local mismatches=info and #info.mismatches or 0
                target.spawnStatus="Stock spawned; "..tostring(mismatches).." saved parts could not be restored on this model/build. See log."
                log("[MV088][VEHICLES][SPAWN] PARTIAL | "..tostring(target.name).." | handle="..handle.." | unavailable="..tostring(info and #info.failures or "?").." | mismatch="..tostring(info and #info.mismatches or "?"))
                toast("Vehicle spawned; verify remaining saved mods",3900)
            end
            if type(doc.attachments)=="table" and #doc.attachments>0 then
                log("[MV088][VEHICLES][SPAWN] NOTE | "..#doc.attachments.." attachments not reproduced")
            end
        end)
        reveal() -- never leave stock vehicle invisible on exceptions
        if ModVerse067 and type(ModVerse067.releaseModel)=="function" and model then
            pcall(ModVerse067.releaseModel,model)
            if model>2147483647 then pcall(ModVerse067.releaseModel,model-4294967296) end
        end
        if not ok then
            target.spawnStatus=(handle~=0 and "Stock spawned; restore error: " or "Spawn failed: ")..shortText(tostring(err),195)
            log("[MV088][VEHICLES][SPAWN] ERROR | "..tostring(target.name).." | "..tostring(err))
            toast("ModVerse spawn error; see log",3900)
        end
        M.spawnBusy[target.id]=nil
    end)
    return true,"Queued stock-first DriftGod save restoration"
end
end)() -- build 088 DriftGod DG122 saved vehicle restore

local function tile080(it,width)
    local x,y=cursorScreenPos()
    local h,photo=193,113
    ImGui.PushID("MV080Vehicle_"..it.id)
    local clicked=ImGui.InvisibleButton("##vehicle",width,h)
    local hovered=ImGui.IsItemHovered()
    drawImageCardBackground(x,y,width,h,hovered,M.selected==it)
    local srv=textureSrv(it.preview)
    if srv then
        if ImGui.AddImageRounded then
            ImGui.AddImageRounded(srv,x+3,y+3,x+width-3,y+photo,0,0,1,1,0xFFFFFFFF,6)
        else ImGui.AddImage(srv,x+3,y+3,x+width-3,y+photo) end
    else
        ImGui.AddRectFilled(x+3,y+3,x+width-3,y+photo,34,38,52,255,6)
        ImGui.AddText(x+8,y+47,fileExists(it.preview) and "LOADING PREVIEW..." or "MISSING PILOT PREVIEW",183,176,201,255)
    end
    ImGui.AddRectFilled(x+3,y+photo-2,x+width-3,y+h-3,16,18,27,250)
    ImGui.AddText(x+8,y+photo+4,shortText(it.name,math.max(15,math.floor(width/7.4))),248,247,255,255)
    ImGui.AddText(x+8,y+photo+25,"By "..shortText(it.creator,math.max(14,math.floor(width/7.4))),180,185,205,255)
    ImGui.AddText(x+8,y+photo+46,installed080(it) and "INSTALLED" or "CLICK TO SELECT",installed080(it) and 116 or 153,194,255,255)
    if ModVerseCherax090 and ModVerseCherax090.cardStar123 then
        if ModVerseCherax090.cardStar123("vehicles",it.id,x,y,hovered) then clicked=false end
    end
    if clicked then M.selected=it end
    if hovered and ImGui.BeginTooltip then
        ImGui.BeginTooltip()
        ImGui.Text(it.name)
        ImGui.Text("Discord creator: "..it.creator)
        ImGui.Text(it.remote and "Approved GitHub download, hash verified" or (it.batch=="batch02" and "Batch 02: local review JSON" or "Pilot 01: user-tested local JSON"))
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end
function M.render()
    ImGui.TextColored(0.78,0.55,1,1,"ModVerse Community / Vehicles")
    if not M.liveLoaded and not M.liveBusy then M.refreshLive(false) end
    -- Production view: public GitHub catalog only. Debug transport and
    -- unpublished private-review controls are intentionally not rendered.
    if M.liveBusy then ImGui.TextColored(.68,.84,1,1,"Loading vehicles...")
    elseif #M.liveItems==0 and M.liveStatus~="" then
        ImGui.TextColored(1,.73,.47,1,shortText(M.liveStatus,110)) end
    local input=ImGui.InputText("Search vehicles##MV080",M.search,120)
    if type(input)=="string" and input~=M.search then M.search=input;M.page=1 end
    if MV122Filters.bar('market_vehicles','vehicles') then M.page=1 end
    local match={};local term=M.search:lower()
    local source=M.liveItems
    for _,it in ipairs(source) do
        if term=="" or it.name:lower():find(term,1,true) or it.creator:lower():find(term,1,true) or it.filename:lower():find(term,1,true) then
            local fs=MV122Filters.state('market_vehicles')
            local installed=fs.show>=3 and installed080(it) or false
            local favorite=fs.show==2 and ModVerseCherax090.isFavorite('vehicles',it.id) or false
            if MV122Filters.keep(it,'market_vehicles','vehicles',installed,favorite) then match[#match+1]=it end
        end
    end
    match=MV122Filters.order(match,'market_vehicles')
    local maxPage=math.max(1,math.ceil(#match/M.perPage)); M.page=math.max(1,math.min(maxPage,M.page))
    if ImGui.Button("< Previous##MV080",110,25) then M.page=math.max(1,M.page-1) end
    ImGui.SameLine();ImGui.Text("Page "..M.page.." / "..maxPage.." | "..#match.." vehicles")
    ImGui.SameLine()
    if ImGui.Button("Next >##MV080",92,25) then M.page=math.min(maxPage,M.page+1) end
    ImGui.Separator()
    if M.selected then
        local it=M.selected
        ImGui.TextColored(0.77,0.68,1,1,"Selected: "..shortText(it.name,50).." | By "..shortText(it.creator,20))
        if it.remote then ImGui.TextColored(0.65,0.84,0.99,1,"GitHub: SHA-256 verified before installation") end
        if tonumber(it.model)==956849991 then
            ImGui.TextColored(1,0.76,0.42,1,"ENHANCED-ONLY STOCK MODEL: Weaponized Ignus (ignus2)")
        end
        if ImGui.Button(it.downloading and "Downloading...##MV083" or (installed080(it) and "Verify / Already Installed##MV080" or (it.remote and "Download & Install Selected Vehicle##MV083" or "Install Selected Vehicle##MV080")),255,32) then
            M.install(it)
        end
        ImGui.SameLine()
        local ready=installed080(it)
        if ImGui.Button(M.spawnBusy[it.id] and "Spawning...##MV088" or "Spawn Selected Vehicle##MV088",205,32) then
            if ready then M.spawn(it) else it.spawnStatus="Install the selected JSON before spawning." end
        end
        if it.spawnStatus and it.spawnStatus~="" then
            ImGui.TextColored(0.68,0.92,0.78,1,"Spawn: "..shortText(it.spawnStatus,163))
        end
        ImGui.TextColored(0.72,0.85,1,1,"Status: "..shortText(it.status,118))
        if ImGui.TreeNode and ImGui.TreeNode("Selected vehicle details##MV080") then
            ImGui.Text("Source post: "..it.id)
            ImGui.Text("Creator: "..it.creator)
            ImGui.Text("Shared: "..it.post)
            ImGui.Text("Cherax model: "..tostring(it.model))
            ImGui.Text("SHA-256: "..it.sha)
            ImGui.Text("Save location: "..it.target)
            ImGui.Text("Original JSON is unchanged. Only the filename is prefixed with mMV_.")
            ImGui.TreePop()
        end
    else
        ImGui.Text("Select a vehicle preview, then install and spawn the stock vehicle + saved mods.")
    end
    ImGui.Separator()
    local start=(M.page-1)*M.perPage+1
    if #match==0 then ImGui.Text(M.liveBusy and "Loading vehicles..." or "No matching marketplace vehicles.");return end
    local visible={}
    for i=start,math.min(#match,start+M.perPage-1) do visible[#visible+1]=match[i] end
    M.fetchPreviews(visible)
    local _,height=contentAvail()
    if ImGui.BeginChild then ImGui.BeginChild("MV080VehiclesScroll",0,math.max(170,math.min(410,(height or 0)-12)),true) end
    local available=select(1,contentAvail())
    local cols=math.max(2,math.min(4,math.floor(available/215)))
    local width=math.max(160,(available-(cols-1)*10)/cols-7)
    if ImGui.BeginTable("MV080VehiclesCards",cols,ImGuiTableFlags.SizingStretchSame) then
        for i=start,math.min(#match,start+M.perPage-1) do
            ImGui.TableNextColumn()
            tile080(match[i],width)
        end
        ImGui.EndTable()
    end
    if ImGui.EndChild then ImGui.EndChild() end
    if ModVerseCherax090 and ModVerseCherax090.starFinish123 then ModVerseCherax090.starFinish123() end
end
ModVerseVehicles080=M
end -- end scoped offline vehicle pilot

-- ==========================================================================
-- MODVERSE 090: CHERAX STOREFRONT / SHARED LIBRARY
-- Retains the Build 089 vehicle stock-first spawn and verified preview cache.
-- Two distinct GitHub asset catalogs; no external download URLs are trusted.
-- ==========================================================================
(function()
local ROOT = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace/main/marketplace/"
local C = { favoritesFile=ROOT_DIR.."cherax_favorites090.tsv", favs={}, favLoaded=false,
    kinds={outfits=true,dlcs=true,vehicles=true,themes=true},
    groups={}, progress={}, history={}, busy=false, selectedKind="outfits",
    installedCache={outfits={},dlcs={}}, showCatalogCovers=true }
ModVerseCherax090=C
FileMgr.CreateDir(ROOT_DIR.."community\\")
FileMgr.CreateDir(ROOT_DIR.."community\\outfits\\")
FileMgr.CreateDir(ROOT_DIR.."community\\dlcs\\")
local function clean(v,n)
    return tostring(v or ""):gsub("[%z\1-\31]"," "):sub(1,n or 140)
end
local function safeToken(v,limit)
    return type(v)=="string" and #v>0 and #v<=(limit or 100)
        and v:match("^[A-Za-z0-9_%-]+$")~=nil and not v:find("..",1,true)
end
local function shaOK(v)
    return type(v)=="string" and #v==64 and v:match("^[0-9a-f]+$")~=nil
end
local function slug(v)
    local result=tostring(v or "item"):gsub("[^A-Za-z0-9_%-]","_"):gsub("_+","_"):sub(1,45)
    if result=="" or result=="_" then return "item" end
    return result
end
local function assetFile(kind,id)
    return ROOT..kind.."/files/"..id..(kind=="outfits" and ".json" or ".rpf")
end
local function previewFile(kind,id)
    return ROOT..kind.."/thumbnails/"..id..".jpg"
end
local function favoriteKey(kind,id)
    return kind..":"..id
end
local function readFav()
    if C.favLoaded then return end
    C.favLoaded=true
    local raw=ModVerseHash152.read(C.favoritesFile)
    if type(raw)~="string" then return end
    for line in raw:gmatch("[^\r\n]+") do
        local kind,id=line:match("^([^\t]+)\t([^\t]+)$")
        if C.kinds[kind] and safeToken(id,150) then C.favs[favoriteKey(kind,id)]=true end
    end
end
-- Community theme IDs may contain a single dot. Normalize only those
-- allowlisted public IDs into safe persisted tokens; preserve existing IDs.
function C.favoriteToken123(kind,id)
    if safeToken(id,150) then return id end
    if kind=="themes" and type(id)=="string" and #id>0 and #id<=150
        and id:match("^[A-Za-z0-9_%.%-]+$") and not id:find("..",1,true) then
        C.themeFavoriteTokens123=C.themeFavoriteTokens123 or {}
        if not C.themeFavoriteTokens123[id] then
            C.themeFavoriteTokens123[id]="theme_"..ModVerseHash152.sha256(id):sub(1,32)
        end
        return C.themeFavoriteTokens123[id]
    end
    return nil
end
function C.isFavorite(kind,id)
    readFav()
    local token=C.favoriteToken123(kind,id)
    return token~=nil and C.favs[favoriteKey(kind,token)]==true
end
-- Build 123: one click-safe star shared by Cherax Vehicles, DLCs and Themes.
-- This is drawn with the existing card foreground API. Do not reposition the
-- ImGui cursor inside table cells (it previously caused broken row bounds).
-- Returning true suppresses that card's click-to-select/install action.
function C.cardStar123(kind,id,x,y,hovered)
    if not C.kinds[kind] or not C.favoriteToken123(kind,id) then return false end
    local sx,sy=x+8,y+8
    local mx,my=readVec2(function() return ImGui.GetMousePos() end,-9999,-9999)
    local over=hovered and mx>=sx and mx<sx+31 and my>=sy and my<sy+31
    local key=kind..":"..id
    local pressed=false
    if ImGui.IsMouseClicked then
        local ok,val=pcall(ImGui.IsMouseClicked,0)
        pressed=ok and (val==true or val==1)
    end
    if pressed and over then C.starPressedKey123=key end
    local wasPressed=(C.starPressedKey123==key)
    local released=false
    if ImGui.IsMouseReleased then
        local ok,val=pcall(ImGui.IsMouseReleased,0)
        released=ok and (val==true or val==1)
    end
    if wasPressed and released then
        if over then C.favorite(kind,id) end
        C.starPressedKey123=nil
    end
    -- Overlay the image, even when image loading fails, and keep the star
    -- isolated from the underlying full-card InvisibleButton hit box.
    ImGui.AddRectFilled(sx,sy,sx+31,sy+31,21,18,35,232,6)
    local fav=C.isFavorite(kind,id)
    ImGui.AddText(sx+7,sy+5,fav and "★" or "☆",fav and 255 or 231,
        fav and 205 or 219,fav and 60 or 236,255)
    return over or wasPressed
end
function C.starFinish123()
    if ImGui.IsMouseReleased then
        local ok,val=pcall(ImGui.IsMouseReleased,0)
        if ok and (val==true or val==1) then C.starPressedKey123=nil end
    end
end
-- Use existing verified SHA for local vehicle keys. Cache the DLC path hash
-- once per detected RPF entry instead of hashing it on every rendered frame.
function C.localVehicleFav123(it)
    return "local_"..tostring(it and it.sha or ""):sub(1,64)
end
function C.localDlcFav123(it)
    if not it then return "" end
    local p=tostring(it.path or it.name or "")
    if it._mv123FavPath~=p then
        it._mv123FavPath=p
        it._mv123FavId="local_"..ModVerseHash152.sha256(p):sub(1,32)
    end
    return it._mv123FavId
end

function C.favorite(kind,id)
    local token=C.favoriteToken123(kind,id)
    if not C.kinds[kind] or not token then return end
    readFav()
    local k=favoriteKey(kind,token)
    C.favs[k]=not C.favs[k]
    local list={}
    for key,value in pairs(C.favs) do
        if value then
            local a,b=key:match("^([^:]+):([^:]+)$")
            if a and b then list[#list+1]=a.."\t"..b end
        end
    end
    table.sort(list)
    if not writeBinary(C.favoritesFile,table.concat(list,"\r\n")) then
        C.favs[k]=not C.favs[k]
        toast("Could not save Cherax favorites",3000)
    end
end
local function destination(kind,item)
    if kind=="outfits" then
        return MENU_ROOT.."\\Outfits\\mMV_"..slug(item.name).."_"..item.sha:sub(1,8)..".json"
    end
    if kind=="dlcs" then
        return MENU_ROOT.."\\DLCs\\mMV_"..slug(item.name).."_"..item.sha:sub(1,8).."\\dlc.rpf"
    end
    return ""
end
function C.installed(kind,item)
    if not item then return false end
    if kind=="outfits" or kind=="dlcs" then
        -- Build093: 2,832+ outfits. Never perform thousands of FileMgr checks
        -- on every UI frame in Library > Installed.
        local cache=C.installedCache[kind]
        local key=tostring(item.id)..":"..tostring(item.sha)
        if cache[key]==nil then cache[key]=fileExists(destination(kind,item)) end
        return cache[key]
    end
    if kind=="vehicles" then
        return fileExists(MENU_ROOT.."\\Vehicles\\"..tostring(item.filename or ""))
    end
    if kind=="themes" then
        return ModVerseCommunity078 and ModVerseCommunity078.state and
            ModVerseCommunity078.state.isInstalled and ModVerseCommunity078.state.isInstalled(item) or false
    end
    return false
end
local function group(kind)
    if C.groups[kind] then return C.groups[kind] end
    local dir=ROOT_DIR.."community\\"..kind.."\\"
    local v={kind=kind,items={}, selected=nil,loaded=false,loading=false, busy=false,
        status="Open to load live GitHub catalog",search="",page=1,perPage=(kind=="outfits" and 6 or 12),
        root=dir,catalogCache=dir.."catalog090.json",thumbDir=dir.."thumbnails\\",
        previewBusy=false,previewPending={},previewStats={disk=0,downloaded=0,failed=0},
        previewCounted={}}
    FileMgr.CreateDir(dir);FileMgr.CreateDir(v.thumbDir)
    C.groups[kind]=v
    return v
end
local function readCatalogPage(g,raw)
    if type(raw)~="string" or #raw>1048576 then error("Catalog page exceeds 1 MiB") end
    local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
    if not ok or type(doc)~="table" or doc.schema~="modverse.cherax.assets.v1"
        or doc.category~=g.kind or doc.published~=true or type(doc.items)~="table"
        or #doc.items>500 then error("Invalid Cherax catalog page") end
    return doc
end
local function combinedCatalog(g,raw,allowNetwork)
    local main=readCatalogPage(g,raw)
    local docs={main}
    local pages=main.pages
    if pages~=nil then
        if type(pages)~="table" or #pages>9 then error("Too many Cherax catalog pages") end
        for index,pageno in ipairs(pages) do
            if type(pageno)~="number" or pageno~=index+1 then error("Invalid catalog page sequence") end
            local file="catalog-"..tostring(pageno)..".json"
            local payload=nil
            if allowNetwork then
                local response,err=httpGet(ROOT..g.kind.."/"..file,22000,nil,{"Accept: application/json"},USER_AGENT)
                if type(response)~="string" then error("Page "..pageno.." unavailable: "..tostring(err)) end
                payload=response
                local cached=g.root..file
                local tmp=cached..".part"
                if writeBinary(tmp,payload) then os.remove(cached);if not os.rename(tmp,cached) then os.remove(tmp) end end
            else
                payload=ModVerseHash152.read(g.root..file)
            end
            if type(payload)~="string" then error("Missing verified catalog page: "..file) end
            docs[#docs+1]=readCatalogPage(g,payload)
        end
    end
    local rows={}
    for _,doc in ipairs(docs) do
        for _,item in ipairs(doc.items) do rows[#rows+1]=item end
    end
    if #rows>5000 then error("Combined Cherax catalog exceeds 5,000 items") end
    return {schema=main.schema,category=main.category,published=true,items=rows}
end
local function setCatalog(g,doc,source)
    if type(doc)~="table" or doc.schema~="modverse.cherax.assets.v1"
        or doc.category~=g.kind or doc.published~=true or type(doc.items)~="table"
        or #doc.items>5000 then return false,"Unexpected combined Cherax catalog" end
    local found,used,files={}, {}, {}
    for _,row in ipairs(doc.items) do
        local id=type(row)=="table" and row.id or nil
        local sha=type(row)=="table" and row.sha256 or nil
        local size=type(row)=="table" and row.size_bytes or nil
        local name=type(row)=="table" and row.name or nil
        local fname=type(row)=="table" and row.filename or nil
        local ext=g.kind=="outfits" and ".json" or ".rpf"
        if safeToken(id,100) and not used[id] and type(name)=="string" and #name>0 and #name<=180
            and type(fname)=="string" and safeToken(fname:gsub("%.json$",""):gsub("%.rpf$",""),150)
            and fname:sub(-#ext)==ext
            and shaOK(sha) and type(size)=="number" and size%1==0
            and size>=(g.kind=="dlcs" and 4096 or 16)
            and size<=(g.kind=="dlcs" and 536870912 or 2097152)
            -- DLC files are approved GitHub Release assets, not Git blobs.
            -- Download URL is constructed ONLY from our pinned repository.
            and (g.kind~="dlcs" or (safeToken(row.release_tag,80)
                and type(row.asset_name)=="string" and row.asset_name==fname
                and fname:match("^mMV_[A-Za-z0-9_%-]+%.rpf$")~=nil))
            and (row.thumbnail_sha256==nil or shaOK(row.thumbnail_sha256))
            and not files[fname] then
            used[id]=true;files[fname]=true
            local prev=g.thumbDir..id.."_"..(row.thumbnail_sha256 or "nohash"):sub(1,12)..".jpg"
            found[#found+1]={kind=g.kind,id=id,name=clean(name,180),creator=clean(row.creator,100),
                shared_by=clean(row.shared_by,100),sha=sha,size=size,filename=fname,
                url=(g.kind=="dlcs" and (
                    "https://github.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace/releases/download/"
                    ..row.release_tag.."/"..row.asset_name) or assetFile(g.kind,id)),
                thumbURL=row.thumbnail_sha256 and (previewFile(g.kind,id).."?v="..row.thumbnail_sha256:sub(1,16)) or nil,
                thumbSha=row.thumbnail_sha256,thumbKind=clean(row.thumbnail_kind,32),preview=prev,status="Ready",thumbStatus="waiting",
                installedPath=nil}
        end
    end
    local old={}
    for _,item in ipairs(g.items) do old[item.id]=item end
    for _,item in ipairs(found) do
        if old[item.id] and old[item.id].sha==item.sha then
            item.status=old[item.id].status
            -- Build 095: allow Refresh GitHub to retry previously failed images.
            -- A verified ready asset remains cached; failures don't stick forever.
            if old[item.id].thumbSha==item.thumbSha and old[item.id].thumbStatus=="ready"
                and fileExists(item.preview) then
                item.thumbStatus="ready"
            end
        end
    end
    local selectedID=g.selected and g.selected.id
    g.items=found;g.loaded=true;g.selected=found[1]
    for _,item in ipairs(found) do if item.id==selectedID then g.selected=item;break end end
    local verifiedImages,photos,covers=0,0,0
    for _,asset in ipairs(found) do
        if asset.thumbURL and asset.thumbSha then
            verifiedImages=verifiedImages+1
            if asset.thumbKind=="catalog_cover" then covers=covers+1
            elseif asset.thumbKind=="gameplay_screenshot" or asset.thumbKind=="source_image" then photos=photos+1 end
        end
    end
    g.imageCount=verifiedImages;g.photoCount=photos;g.coverCount=covers
    g.status=(source or "GitHub").." | "..#found.." hosted "..g.kind..
        " | "..verifiedImages.." image(s) ("..photos.." real/source JPGs, "..covers.." catalog covers)"
    if #found~=#doc.items then g.status=g.status.." | rejected "..(#doc.items-#found).." invalid" end
    -- A missing thumbnail_sha256 indicates unpublished preview artwork, not a
    -- broken catalog or a networking failure. Log coverage, once per catalog load.
    log(string.format("[MV097][%s][CATALOG] %s | items=%d | real/source images=%d | decorative covers=%d | missing images=%d | rejected=%d",
        tostring(g.kind):upper(),tostring(source or "GitHub"),#found,photos,covers,#found-verifiedImages,#doc.items-#found))
    return true
end
local function refresh(g,force)
    if g.loading or not Script or not Script.QueueJob then return end
    -- Manual Refresh rechecks on-disk installs; steady-state frames use cache.
    if force and C.installedCache[g.kind] then C.installedCache[g.kind]={} end
    local when=nowMs and nowMs() or 0
    if not force and g.lastAttempt and when>g.lastAttempt and when-g.lastAttempt<15000 then return end
    g.lastAttempt=when
    if not g.loaded then
        local cached=ModVerseHash152.read(g.catalogCache)
        if cached then
            local ok,doc=pcall(combinedCatalog,g,cached,false)
            if ok then setCatalog(g,doc,"Cached catalog") end
        end
    end
    g.loading=true;g.status="Refreshing GitHub "..g.kind.."..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local raw,why=httpGet(ROOT..g.kind.."/catalog.json",22000,nil,{"Accept: application/json"},USER_AGENT)
            if type(raw)~="string" then error(tostring(why or "Network failed")) end
            local doc=combinedCatalog(g,raw,true)
            local accepted,reason=setCatalog(g,doc,"Live GitHub")
            if not accepted then error(reason) end
            local temp=g.catalogCache..".part"
            if writeBinary(temp,raw) then
                os.remove(g.catalogCache)
                if not os.rename(temp,g.catalogCache) then os.remove(temp) end
            end
        end)
        if not ok then
            g.status="GitHub unavailable: "..clean(err,170).." (cached entries retained)"
            log("[MV094]["..g.kind.."][ERROR] "..clean(err,170))
        end
        g.loading=false
    end)
end
-- Build 096: Outfit/DLC previews follow the proven Vehicles/Themes pipeline:
-- fetch visible cards as a batch in one background job, SHA-256 verify JPEG bytes,
-- keep hash-versioned on-disk files, then let shared textureSrv() render them.
-- A missing thumbnail remains a placeholder; no asset gets an invented screenshot.
local function previewCached096(g,it)
    if not it or not it.thumbSha or not it.preview then return false end
    if it.thumbStatus=="ready" and fileExists(it.preview) then return true end
    if not fileExists(it.preview) then return false end
    local data=ModVerseHash152.read(it.preview)
    if type(data)~="string" or #data<100 or #data>6*1024*1024
        or detectImageKind(data)~="jpg" or data:sub(-2)~="\255\217"
        or ModVerseHash152.sha256(data)~=it.thumbSha then
        return false
    end
    it.thumbStatus="ready"
    it.thumbError=nil
    local key=it.id.."|"..it.thumbSha
    if not g.previewCounted[key] then
        g.previewCounted[key]="disk"
        g.previewStats.disk=g.previewStats.disk+1
    end
    return true
end
local function fetchVisiblePreviews096(g,visible)
    if g.previewBusy or not Script or not Script.QueueJob then return end
    local todo={}
    for _,it in ipairs(visible) do
        if it.thumbURL and it.thumbSha and it.thumbStatus~="failed"
            and (it.thumbKind~="catalog_cover" or C.showCatalogCovers) then
            if not previewCached096(g,it) and not g.previewPending[it.id] then
                it.thumbStatus="queued"
                g.previewPending[it.id]=true
                todo[#todo+1]=it
            end
        end
    end
    if #todo==0 then return end
    g.previewBusy=true
    Script.QueueJob(function()
        -- Each visible card is isolated: one unavailable CDN image cannot stop
        -- the rest of the page from displaying and caching their thumbnails.
        for _,it in ipairs(todo) do
            local ok,reason=pcall(function()
                if previewCached096(g,it) then return end
                it.thumbStatus="downloading"
                local data,e=httpGet(it.thumbURL,20000,nil,
                    {IMAGE_ACCEPT,"Cache-Control: no-cache"},IMAGE_USER_AGENT)
                if type(data)~="string" then error(tostring(e or "No JPEG response")) end
                if #data<100 or #data>6*1024*1024 or detectImageKind(data)~="jpg"
                    or data:sub(-2)~="\255\217" then error("Invalid JPEG format or size") end
                if ModVerseHash152.sha256(data)~=it.thumbSha then
                    error("JPEG SHA-256 does not match catalog")
                end
                local tmp=it.preview..".mv096-part"
                if not writeBinary(tmp,data) then error("Cannot write temporary JPG") end
                local staged=ModVerseHash152.read(tmp)
                if type(staged)~="string" or ModVerseHash152.sha256(staged)~=it.thumbSha then
                    os.remove(tmp);error("Disk readback SHA-256 mismatch")
                end
                if fileExists(it.preview) then os.remove(it.preview) end
                if not os.rename(tmp,it.preview) then
                    os.remove(tmp);error("Cannot finalize JPG cache")
                end
                TextureCache[it.preview]=nil
                it.thumbStatus="ready"
                it.thumbError=nil
                local key=it.id.."|"..it.thumbSha
                if not g.previewCounted[key] then
                    g.previewCounted[key]="download"
                    g.previewStats.downloaded=g.previewStats.downloaded+1
                end
            end)
            if not ok then
                it.thumbStatus="failed"
                it.thumbError=clean(reason,155)
                g.previewStats.failed=g.previewStats.failed+1
                log("[MV096]["..g.kind.. "][THUMBNAIL] "..tostring(it.id).." | "..it.thumbError)
            end
            g.previewPending[it.id]=nil
            if Script and Script.Yield then Script.Yield(60) end
        end
        g.previewBusy=false
    end)
end
local function retryFailedPreviews096(g)
    if g.previewBusy then return false end
    local n=0
    for _,it in ipairs(g.items) do
        if it.thumbStatus=="failed" then
            it.thumbStatus="waiting";it.thumbError=nil
            TextureCache[it.preview]=nil
            n=n+1
        elseif it.thumbStatus=="ready" and TextureCache[it.preview]
            and TextureCache[it.preview].failed then
            -- A verified JPG can fail GPU allocation independently of HTTP.
            -- Retry the texture upload without redownloading valid bytes.
            TextureCache[it.preview]=nil
            n=n+1
        end
    end
    g.previewStats.failed=0
    log("[MV096]["..g.kind.. "][THUMBNAIL] User retry: "..tostring(n).." failed previews reset")
    return n>0
end
local function finishDownload(g,item,success,message)
    item.status=message
    C.progress[g.kind..":"..item.id]={name=item.name,kind=g.kind,status=message,success=success}
    if success then
        if message and message:find("auto-apply unavailable",1,true) then
            toast("Outfit installed; auto-apply unavailable. See Details.",4200)
        else
            toast("Cherax "..g.kind.." installed: "..item.name,3600)
        end
    else toast("Cherax "..g.kind.." install failed; see status",3500) end
    g.busy=false
end
-- Build 100: The original approved Cherax Outfit JSON archive contains CRLF
-- bytes, but GitHub serves LF-normalized content for those same objects.
-- Reconstruct the exact original bytes ONLY if the pinned catalog size AND
-- SHA256 both match. No weaker integrity bypass is introduced.
local function verifiedOutfitPayload100(raw,item)
    if type(raw)~="string" or not item or type(item.sha)~="string" or type(item.size)~="number" then
        return nil,"invalid payload or catalog metadata"
    end
    if #raw==item.size and ModVerseHash152.sha256(raw)==item.sha then
        return raw,"EXACT"
    end
    -- Only a text line-ending restoration is permitted. Do not normalize
    -- pre-existing CRLF/mixed line endings or accept arbitrary JSON by shape.
    if #raw<32 or #raw>2097152 or raw:find("\r",1,true) or not raw:find("\n",1,true) then
        return nil,"size/SHA256 mismatch; cannot restore known CRLF source"
    end
    local restored=raw:gsub("\n","\r\n")
    if #restored==item.size and ModVerseHash152.sha256(restored)==item.sha then
        return restored,"CRLF_RESTORED"
    end
    return nil,"size/SHA256 mismatch after CRLF reconstruction"
end

local function downloadItem(g,item)
    if not item or g.busy or not Script or not Script.QueueJob then return end
    g.busy=true;item.status="Checking local destination..."
    Script.QueueJob(function()
        local ok,err=pcall(function()
            local path=destination(g.kind,item)
            local parent=path:match("^(.*)\\[^\\]+$")
            if not parent or path=="" then error("Invalid install path") end
            FileMgr.CreateDir(parent)
            if fileExists(path) then
                local current=ModVerseHash152.read(path)
                if current and #current==item.size and ModVerseHash152.sha256(current)==item.sha then
                    item.status=g.kind=="outfits" and "Already installed. Load via Cherax Outfits." or "Already installed and SHA-256 verified"
                    if C.installedCache[g.kind] then
                        C.installedCache[g.kind][item.id..":"..item.sha]=true
                    end
                    return
                end
                error("Destination already contains different content. Refusing overwrite")
            end
            -- No unapproved third-party URL supplied by the remote catalog is used.
            if g.kind=="dlcs" and item.size>128*1024*1024 then
                error("DLC >128 MiB requires the streamed-download path; not safe to buffer in Lua")
            end
            item.status="Downloading verified "..g.kind.." file..."
            local timeoutMs=g.kind=="dlcs" and 240000 or 90000
            local raw,why=httpGet(item.url,timeoutMs,nil,{"Accept: application/octet-stream"},USER_AGENT)
            if type(raw)~="string" then error(tostring(why or "Download failed")) end
            if g.kind=="outfits" then
                local verified,mode=verifiedOutfitPayload100(raw,item)
                if not verified then error("Outfit source size/SHA-256 mismatch; no installation") end
                raw=verified
                if mode=="CRLF_RESTORED" then
                    log("[MV100][OUTFIT][INTEGRITY] Exact original CRLF bytes reconstructed and SHA-256 verified for "..tostring(item.id))
                end
            elseif #raw~=item.size or ModVerseHash152.sha256(raw)~=item.sha then
                error("File size or SHA-256 mismatch; no installation")
            end
            if g.kind=="outfits" then
                local valid,doc=pcall(ModVerseCommunity078.decodeJson,raw)
                if not valid or type(doc)~="table" or (doc.format=="Cherax Entity" and doc.type==1) then error("Not a valid Cherax outfit JSON save") end
            else
                if raw:sub(1,4)~="7FPR" or raw:sub(13,16)~="OPEN" then
                    error("Only unencrypted OPEN RPF7 DLC is supported")
                end
            end
            local stage=path..".modverse090.part"
            if fileExists(stage) then error("Stale staging file exists; manual cleanup required") end
            if not writeBinary(stage,raw) then error("Unable to write staged file") end
            local staged=ModVerseHash152.read(stage)
            if not staged or #staged~=item.size or ModVerseHash152.sha256(staged)~=item.sha then
                os.remove(stage);error("Staged SHA-256 mismatch")
            end
            if g.kind=="dlcs" and DLC054 and DLC054.validate then
                local valid,detail=DLC054.validate(stage)
                if not valid then os.remove(stage);error("RPF rejected: "..tostring(detail)) end
            end
            if fileExists(path) then os.remove(stage);error("Destination appeared during download") end
            if not os.rename(stage,path) then os.remove(stage);error("Final file rename failed") end
            if C.installedCache[g.kind] then C.installedCache[g.kind][item.id..":"..item.sha]=true end
            item.status=g.kind=="outfits" and "Installed to Cherax Outfits. Load from Cherax Outfits." or "Installed and SHA-256 verified"
            if ModVerseTutorial147 then ModVerseTutorial147.open(g.kind,"install") end
        end)
        finishDownload(g,item,ok,ok and item.status or ("ERROR: "..clean(err,180)))
    end)
end
local function listItems(g,onlyFavorites,onlyInstalled)
    local matched={}
    local search=(g.search or ""):lower()
    for _,it in ipairs(g.items) do
        if (not onlyFavorites or C.isFavorite(g.kind,it.id))
            and (not onlyInstalled or C.installed(g.kind,it))
            and (search=="" or it.name:lower():find(search,1,true) or it.creator:lower():find(search,1,true)) then
            matched[#matched+1]=it
        end
    end
    return matched
end
-- Build 098: Outfit preview is a REAL local, non-networked GTA ped, not a fake
-- screenshot. Cherax's documented ImGui texture API cannot use a live ped as
-- a texture directly. The optional camera shows the selected ped in the WORLD.
-- Never write to or dress the actual player ped. Never create network peds.
-- MV106: isolated bridge for generated natives. ENTITY/PED/PLAYER are not
-- installed automatically in every Cherax Lua session. No global writes.
local function mv106NativeNamespace(kind,mapping)
    local existing=rawget(_G,kind)
    return setmetatable({}, {__index=function(_,name)
        if type(existing)=="table" and type(existing[name])=="function" then return existing[name] end
        local spec=mapping[name]
        if not spec then return nil end
        if spec[1]=="V3" then
            return function(...)
                if not (Natives and Natives.InvokeV3) then error("InvokeV3 unavailable") end
                local x,y,z=Natives.InvokeV3(spec[2],...)
                if V3 and V3.New then return V3.New(x,y,z) end
                return {x=x,y=y,z=z}
            end
        end
        return function(...)
            local invoke=Natives and Natives["Invoke"..spec[1]]
            if type(invoke)~="function" then error("Native dispatcher unavailable: "..kind.."."..name) end
            return invoke(spec[2],...)
        end
    end})
end
local ENTITY=mv106NativeNamespace("ENTITY",{DELETE_ENTITY={"Void",0xAE3CBE5BF394C9C9},DOES_ENTITY_EXIST={"Bool",0x7239B21A38F536BA},FREEZE_ENTITY_POSITION={"Void",0x428CA6DBD1094446},GET_ENTITY_COORDS={"V3",0x3FEF770D40960D5A},GET_ENTITY_HEADING={"Float",0xE83D4F9BA2A38914},GET_ENTITY_MODEL={"Int",0x9F47B058362C84B5},SET_ENTITY_AS_MISSION_ENTITY={"Void",0xAD738C3085FE7E11},SET_ENTITY_COLLISION={"Void",0x1A9205C1B9EE827F},SET_ENTITY_COORDS={"Void",0x06843DA7060A026B},SET_ENTITY_HEADING={"Void",0x8E2530AA8ADA980E},SET_ENTITY_INVINCIBLE={"Void",0x3882114BDE571AD4}})
local PED=mv106NativeNamespace("PED",{CLEAR_PED_PROP={"Void",0x0943E5B8E078E76E},CLEAR_PED_TASKS_IMMEDIATELY={"Void",0xAAA34F8A7CB32098},CLONE_PED={"Int",0xEF29A16337FACADB},DELETE_PED={"Void",0x9614299DCB53E54B},GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS={"Int",0x27561561732A7842},GET_NUMBER_OF_PED_PROP_DRAWABLE_VARIATIONS={"Int",0x5FAF9754E789FB47},GET_NUMBER_OF_PED_PROP_TEXTURE_VARIATIONS={"Int",0xA6E7F1CEB523E171},GET_NUMBER_OF_PED_TEXTURE_VARIATIONS={"Int",0x8F7156A3142A6BAD},GET_PED_DRAWABLE_VARIATION={"Int",0x67F3780DD425D4FC},GET_PED_PALETTE_VARIATION={"Int",0xE3DD5F2A84B42281},GET_PED_PROP_INDEX={"Int",0x898CC20EA75BACD8},GET_PED_PROP_TEXTURE_INDEX={"Int",0xE131A28626F81AB2},GET_PED_TEXTURE_VARIATION={"Int",0x04A355E041E004E6},SET_BLOCKING_OF_NON_TEMPORARY_EVENTS={"Void",0x9F8AA94D6D97DBF4},SET_PED_CAN_RAGDOLL={"Void",0xB128377056A54E2A},SET_PED_COMPONENT_VARIATION={"Void",0x262B14F48D29DE80},SET_PED_DEFAULT_COMPONENT_VARIATION={"Void",0x45EEE61580806D63},SET_PED_HAIR_TINT={"Void",0x4CFFC65454C93A49},SET_PED_PROP_INDEX={"Void",0x93376B65A266EB5F}})
local PLAYER=mv106NativeNamespace("PLAYER",{PLAYER_ID={"Int",0x4F8644AF03D0E0D6},PLAYER_PED_ID={"Int",0xD80958FC74E988A6}})
local CAM=mv106NativeNamespace("CAM",{CREATE_CAM={"Int",0xC3981DCE61D9E13F},DESTROY_CAM={"Void",0x865908C81A2C22E9},IS_GAMEPLAY_CAM_RENDERING={"Bool",0x39B5D1B10383F0C8},POINT_CAM_AT_COORD={"Void",0xF75497BB865F0803},RENDER_SCRIPT_CAMS={"Void",0x07E5B515DB0636FC},SET_CAM_ACTIVE={"Void",0x026FB97D0A425F84},SET_CAM_COORD={"Void",0x4D41783FB745E42E},SET_CAM_FOV={"Void",0xB13C14F66A00D047}})
-- Alloc8or/Cherax LE CLONE_PED ABI: (ped, isNetwork, scriptHost, copyHeadBlend).
-- The earlier heading/boolean call mixed up its parameters.
local function mv106ClonePed(source)
    if not (Natives and type(Natives.InvokeInt)=="function") then return nil end
    return Natives.InvokeInt(0xEF29A16337FACADB,source,false,false,true)
end
local Preview098={busy=false,ped=0,cam=0,originalPed=0,currentId=nil,
    status="Select an outfit, then preview its 3D clone.",requested=0,
    modelBySha={},jsonBySha={},loadingBySha={},failedBySha={},integrityLogged={},pageBusy=false,
    pageToken=0,activePageKey=nil,previewFilesSeen={},pageFetched=0,pageCacheHits=0,expires=0}
C.OutfitPreview098=Preview098
local MALE098=1885233650
local FEMALE098=2627665880
local COMPONENTS098={Head=0,Beard=1,Hair=2,Torso=3,Legs=4,Hands=5,Feet=6,
    Teeth=7,Special=8,["Special 2"]=9,Decal=10,["Tuxedo/Jacket Bib"]=11}
local PROPS098={Head=0,Eyes=1,Ears=2,Mouth=3,["Left Hand"]=4,
    ["Right Hand"]=5,["Left Wrist"]=6,["Right Wrist"]=7,Hip=8}
local function norm098(n)
    n=tonumber(n)
    if not n or n%1~=0 then return nil end
    return n & 0xffffffff
end
local function gender098(model)
    model=norm098(model)
    if model==MALE098 then return "MALE" end
    if model==FEMALE098 then return "FEMALE" end
    return model and "OTHER" or "UNKNOWN"
end
local function playerPed098()
    -- The native can be absent/unready in some Cherax sessions.  The user
    -- previously saw "Player ped unavailable" despite their local character
    -- existing. Recover the game handle from the documented CPed pointer API.
    local ok,ped=pcall(function() return PLAYER.PLAYER_PED_ID() end)
    ped=ok and tonumber(ped) or 0
    if ped and ped~=0 then
        local alive,exists=pcall(function() return ENTITY.DOES_ENTITY_EXIST(ped) end)
        if alive and (exists==true or exists==1) then return ped end
    end
    if GTA and type(GTA.PointerToHandle)=="function" then
        local pointers={}
        if type(GTA.GetLocalPed)=="function" then
            local yes,p=pcall(GTA.GetLocalPed)
            if yes and p then pointers[#pointers+1]=p end
        end
        if Players and type(Players.GetCPed)=="function" then
            local localId
            if GTA.GetLocalPlayerId then
                local yes,n=pcall(GTA.GetLocalPlayerId)
                if yes then localId=tonumber(n) end
            end
            if localId==nil and PLAYER and PLAYER.PLAYER_ID then
                local yes,n=pcall(PLAYER.PLAYER_ID)
                if yes then localId=tonumber(n) end
            end
            if localId and localId>=0 then
                local yes,p=pcall(Players.GetCPed,localId)
                if yes and p then pointers[#pointers+1]=p end
            end
        end
        for _,ptr in ipairs(pointers) do
            local yes,h=pcall(GTA.PointerToHandle,ptr)
            h=yes and tonumber(h) or 0
            if h and h~=0 then
                local alive,exists=pcall(function() return ENTITY.DOES_ENTITY_EXIST(h) end)
                if alive and (exists==true or exists==1) then return h end
            end
        end
    end
    return 0
end
local function playerModel098()
    local ped=playerPed098()
    if ped==0 then return nil,ped end
    local ok,model=pcall(ENTITY.GET_ENTITY_MODEL,ped)
    return ok and norm098(model) or nil,ped
end
local function exists098(entity)
    if not entity or entity==0 then return false end
    local ok,res=pcall(ENTITY.DOES_ENTITY_EXIST,entity)
    return ok and (res==true or res==1)
end
local function coord098(ped)
    local ok,a,b,c=pcall(ENTITY.GET_ENTITY_COORDS,ped,true)
    if not ok then return nil end
    if type(a)=="table" or type(a)=="userdata" then
        local good,x,y,z=pcall(function()
            return tonumber(a.x or a.X or a[1]),tonumber(a.y or a.Y or a[2]),tonumber(a.z or a.Z or a[3])
        end)
        if good and x and y and z then return x,y,z end
    end
    if tonumber(a) and tonumber(b) and tonumber(c) then return tonumber(a),tonumber(b),tonumber(c) end
    return nil
end
function Preview098.stop(reason)
    Preview098.requested=Preview098.requested+1
    if Preview098.cam~=0 then
        -- Do not leave GTA in the temporary showroom camera on Lua unload.
        pcall(function() CAM.RENDER_SCRIPT_CAMS(false,false,0,true,true,false) end)
        pcall(function() CAM.SET_CAM_ACTIVE(Preview098.cam,false) end)
        pcall(function() CAM.DESTROY_CAM(Preview098.cam,false) end)
        Preview098.cam=0
    end
    if Preview098.ped~=0 then
        if exists098(Preview098.ped) and Memory and Memory.AllocInt
            and Memory.WriteInt and Memory.Free then
            -- Critical Cherax native ABI: DELETE_PED and DELETE_ENTITY take
            -- int* pointers, never raw handle integers (access violation).
            pcall(ENTITY.SET_ENTITY_AS_MISSION_ENTITY,Preview098.ped,true,true)
            local memOK,mem=pcall(Memory.AllocInt)
            if memOK and tonumber(mem) and mem~=0 then
                local okWrite=pcall(Memory.WriteInt,mem,Preview098.ped)
                if okWrite then pcall(PED.DELETE_PED,mem) end
                if exists098(Preview098.ped) then
                    pcall(Memory.WriteInt,mem,Preview098.ped)
                    pcall(ENTITY.DELETE_ENTITY,mem)
                end
                pcall(Memory.Free,mem)
            end
        end
        if exists098(Preview098.ped) then
            log("[MV098][OUTFIT][WARNING] Local preview ped cleanup did not complete")
        end
        Preview098.ped=0
    end
    Preview098.originalPed=0
    Preview098.sourceModel=nil
    Preview098.currentId=nil
    Preview098.expires=0
    Preview098.busy=false
    Preview098.status=reason or "Live 3D preview stopped."
end
-- Build 108: page-scoped volatile JSON. This prefetch is NOT an install or
-- persistent download: only the pinned, SHA-256-verified decoded JSON stays
-- in memory for the six visible Outfit cards. Existing installed files are
-- preferred, followed by older verified preview caches, then live GitHub.
local function outfitData098(g,it,requestPageToken)
    local cached=Preview098.jsonBySha[it.sha]
    if cached then return cached end
    if requestPageToken and requestPageToken~=Preview098.pageToken then
        return nil,"Page changed while loading Outfit JSON"
    end
    local dir=g.root.."outfit-preview-data\\"
    local path=dir..it.id.."_"..it.sha:sub(1,12)..".json"
    local installed=ModVerseHash152.read(destination("outfits",it))
    local raw=verifiedOutfitPayload100(installed,it)
    if not raw then
        local oldPreview=ModVerseHash152.read(path)
        raw=verifiedOutfitPayload100(oldPreview,it)
        if raw then Preview098.previewFilesSeen[path]=true end
    end
    if raw then
        Preview098.pageCacheHits=(Preview098.pageCacheHits or 0)+1
    else
        local why
        raw,why=httpGet(it.url,25000,nil,{"Accept: application/json"},USER_AGENT)
        if type(raw)~="string" then return nil,"Outfit JSON prefetch failed: "..tostring(why) end
        local verifiedSource,integrityMode=verifiedOutfitPayload100(raw,it)
        if not verifiedSource then
            return nil,"Outfit JSON integrity mismatch (preview not applied)"
        end
        raw=verifiedSource
        it.previewIntegrity="SHA-256 verified"..(integrityMode=="CRLF_RESTORED" and " (CRLF restored)" or "")
        Preview098.pageFetched=(Preview098.pageFetched or 0)+1
        -- Important: NO writeBinary here. Hover/preload never installs an
        -- Outfit or leaves a new JSON file behind on disk.
    end
    if requestPageToken and requestPageToken~=Preview098.pageToken then
        return nil,"Page changed while loading Outfit JSON"
    end
    local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
    if not ok or type(doc)~="table" or doc.format~="Cherax Entity"
        or doc.type~=2 or type(doc.components)~="table" or not norm098(doc.model) then
        return nil,"Unrecognized Cherax Outfit JSON structure"
    end
    -- Inert preview data: do not execute package code, call functions from it,
    -- or permit extreme clothing indices. Clothing validation is repeated via
    -- GTA natives before any component reaches the local clone.
    for _,r in pairs(doc.components) do
        if type(r)~="table" then return nil,"Bad component object" end
        local d,t=tonumber(r.drawable),tonumber(r.texture)
        if not d or d%1~=0 or d< -1 or d>4095 or not t or t%1~=0 or t< -1 or t>255 then
            return nil,"Unsafe Outfit component index"
        end
    end
    for _,r in pairs(doc.props or {}) do
        if type(r)~="table" then return nil,"Bad prop object" end
        local d,t=tonumber(r.drawable),tonumber(r.texture)
        if not d or d%1~=0 or d< -1 or d>4095 or not t or t%1~=0 or t< -1 or t>255 then
            return nil,"Unsafe Outfit prop index"
        end
    end
    if requestPageToken and requestPageToken~=Preview098.pageToken then
        return nil,"Page changed while validating Outfit JSON"
    end
    Preview098.modelBySha[it.sha]=norm098(doc.model)
    Preview098.jsonBySha[it.sha]=doc
    return doc
end
-- Previous experimental builds wrote preview-only JSON files to disk. The
-- Build 108 preview cache itself lives in RAM; clean any legacy preview-only
-- paths encountered on page exit, but NEVER touch installed Outfits.
function Preview098.clearPage(reason)
    local freed=0
    for _ in pairs(Preview098.jsonBySha) do freed=freed+1 end
    for path in pairs(Preview098.previewFilesSeen) do
        pcall(os.remove,path)
    end
    Preview098.previewFilesSeen={}
    Preview098.pageToken=Preview098.pageToken+1
    Preview098.jsonBySha={}
    Preview098.modelBySha={}
    Preview098.loadingBySha={}
    Preview098.failedBySha={}
    Preview098.pageBusy=false
    Preview098.pageFetched=0
    Preview098.pageCacheHits=0
    Preview098.activePageKey=nil
    if freed>0 then
        log("[MV107][OUTFIT][CACHE] Cleared "..freed.." volatile preview(s): "..tostring(reason or "page changed"))
    end
end
function Preview098.compat(it)
    if not it or not it.sha then return "UNKNOWN" end
    local m=Preview098.modelBySha[it.sha]
    if m==nil then return Preview098.failedBySha[it.sha] and "UNAVAILABLE" or "UNCHECKED" end
    local localModel=playerModel098()
    if not localModel then return "UNKNOWN" end
    if m==localModel then return "COMPATIBLE" end
    if (m==MALE098 or m==FEMALE098) and (localModel==MALE098 or localModel==FEMALE098) then
        return "INCOMPATIBLE"
    end
    return "MODEL MISMATCH"
end
function Preview098.scanPage(g,visible)
    if Preview098.pageBusy or not Script or not Script.QueueJob then return end
    local todo={}
    for _,it in ipairs(visible or {}) do
        if it.kind=="outfits" and Preview098.modelBySha[it.sha]==nil
            and not Preview098.failedBySha[it.sha] and not Preview098.loadingBySha[it.sha] then
            todo[#todo+1]=it
            Preview098.loadingBySha[it.sha]=true
        end
    end
    if #todo==0 then return end
    local generation=Preview098.pageToken
    Preview098.pageBusy=true
    log("[MV107][OUTFIT][CACHE] Preloading "..#todo.." SHA-256-verified Outfit JSON(s) into temporary RAM")
    Script.QueueJob(function()
        for _,it in ipairs(todo) do
            if generation~=Preview098.pageToken then break end
            local ok,doc,err=pcall(outfitData098,g,it,generation)
            if generation~=Preview098.pageToken then break end
            if not ok or not doc then
                it.modelCheckError=clean(ok and err or doc,95)
                Preview098.failedBySha[it.sha]=true
                log("[MV107][OUTFIT][CACHE] "..tostring(it.id).." | "..tostring(it.modelCheckError))
            end
            Preview098.loadingBySha[it.sha]=nil
            if Script and Script.Yield then Script.Yield(30) end
        end
        if generation==Preview098.pageToken then
            Preview098.pageBusy=false
            log("[MV107][OUTFIT][CACHE] Ready: "..tostring(#todo).." requested; fetched="..
                tostring(Preview098.pageFetched).."; local_verified="..tostring(Preview098.pageCacheHits))
        end
    end)
end
local function applyClothes098(ped,doc)
    local applied,skipped=0,0
    -- Original 12 Cherax component slots. Only apply values that GTA reports
    -- in range for the clone's model; never force a bad drawable/texture index.
    for name,slot in pairs(COMPONENTS098) do
        local r=doc.components[name]
        if type(r)=="table" then
            local d,t,p=tonumber(r.drawable),tonumber(r.texture),tonumber(r.palette) or 0
            local ok,count=pcall(PED.GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS,ped,slot)
            if d and t and d%1==0 and t%1==0 and ok and count and d>=0 and d<count then
                local okTex,texCount=pcall(PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS,ped,slot,d)
                if okTex and texCount and t>=0 and t<texCount then
                    local okSet=pcall(PED.SET_PED_COMPONENT_VARIATION,ped,slot,d,t,math.max(0,math.min(3,math.floor(p))))
                    if okSet then applied=applied+1 else skipped=skipped+1 end
                else skipped=skipped+1 end
            else skipped=skipped+1 end
        end
    end
    for name,slot in pairs(PROPS098) do
        local r=doc.props and doc.props[name]
        if type(r)=="table" then
            local d,t=tonumber(r.drawable),tonumber(r.texture)
            if d==-1 then
                if pcall(PED.CLEAR_PED_PROP,ped,slot,0) then applied=applied+1 end
            elseif d and t and d>=0 and d%1==0 and t>=0 and t%1==0 then
                local ok,count=pcall(PED.GET_NUMBER_OF_PED_PROP_DRAWABLE_VARIATIONS,ped,slot)
                if ok and count and d<count then
                    local okTex,texCount=pcall(PED.GET_NUMBER_OF_PED_PROP_TEXTURE_VARIATIONS,ped,slot,d)
                    if okTex and texCount and t<texCount then
                        if pcall(PED.SET_PED_PROP_INDEX,ped,slot,d,t,true,0) then applied=applied+1 else skipped=skipped+1 end
                    else skipped=skipped+1 end
                else skipped=skipped+1 end
            end
        end
    end
    -- Native Cherax files use 255 for "no saved hair tint". Passing it to GTA
    -- is not a real colour and may carry over previous preview appearance.
    local primary=tonumber(doc.primary_hair_tint)
    local secondary=tonumber(doc.secondary_hair_tint)
    if primary and secondary and primary>=0 and primary<64 and secondary>=0 and secondary<64
        and PED.SET_PED_HAIR_TINT then
        pcall(PED.SET_PED_HAIR_TINT,ped,primary,secondary)
    end
    return applied,skipped
end
-- Build 128: A preview must be complete. Partially specified/missing outfits must
-- never inherit unmentioned slots from the player's current clothing.
local function mv128PreviewSchema(doc)
    if type(doc)~="table" or type(doc.components)~="table" or type(doc.props)~="table" then
        return false,"incomplete outfit components or props"
    end
    for name in pairs(COMPONENTS098) do
        local v=doc.components[name]
        local d=v and tonumber(v.drawable)
        local t=v and tonumber(v.texture)
        if not d or not t or d%1~=0 or t%1~=0 or d<0 or t<0 then
            return false,"missing/invalid clothing: "..name
        end
    end
    for name in pairs(PROPS098) do
        local v=doc.props[name]
        local d=v and tonumber(v.drawable)
        local t=v and tonumber(v.texture)
        if not d or not t or d%1~=0 or t%1~=0 or d < -1 or (d>=0 and t<0) then
            return false,"missing/invalid prop: "..name
        end
    end
    return true
end
-- Read back what GTA actually set. Do not display a misleading mixed preview
-- if any drawable/texture is unavailable for the current GTA build.
local function mv128PreviewMatches(ped,doc)
    local checked=0
    for name,slot in pairs(COMPONENTS098) do
        local v=doc.components[name]
        local okD,d=pcall(PED.GET_PED_DRAWABLE_VARIATION,ped,slot)
        local okT,t=pcall(PED.GET_PED_TEXTURE_VARIATION,ped,slot)
        if okD and okT and type(d)=="number" and type(t)=="number" then
            checked=checked+1
            if d~=tonumber(v.drawable) or t~=tonumber(v.texture) then
                return false,"clothing didn't stick: "..name
            end
        end
    end
    for name,slot in pairs(PROPS098) do
        local v=doc.props[name]
        local okD,d=pcall(PED.GET_PED_PROP_INDEX,ped,slot)
        if okD and type(d)=="number" then
            checked=checked+1
            if d~=tonumber(v.drawable) then
                return false,"prop didn't stick: "..name
            end
            if d>=0 then
                local okT,t=pcall(PED.GET_PED_PROP_TEXTURE_INDEX,ped,slot)
                if okT and type(t)=="number" and t~=tonumber(v.texture) then
                    return false,"prop texture didn't stick: "..name
                end
            end
        end
    end
    -- A successful native invocation with zero readable slots is NOT a valid
    -- Outfit; that was able to display an unmodified player look as success.
    if checked<21 then
        return false,"only "..tostring(checked).."/21 clothing + prop slots verified"
    end
    return true,checked
end
-- Build 127: player PED outfit application is intentionally disabled.
-- Preserve native JSON files and use Cherax Outfits to load complete entities.
local function createShowroom098(it,doc)
    local model,sourcePed=playerModel098()
    if not model or not exists098(sourcePed) then return false,"Player ped unavailable" end
    local wanted=norm098(doc.model)
    if wanted~=model then
        return false,"INCOMPATIBLE: outfit is "..gender098(wanted)..", your current ped is "..gender098(model)
    end
    if not Memory or type(Memory.AllocInt)~="function" or type(Memory.WriteInt)~="function"
        or type(Memory.Free)~="function" then
        return false,"Cherax Memory pointer API unavailable; refusing to spawn ped without safe cleanup"
    end
    -- Do not overwrite another script's camera when another scripted camera
    -- is already rendering. This is a conservative safety check.
    if CAM.IS_GAMEPLAY_CAM_RENDERING then
        local ok,isGameplay=pcall(CAM.IS_GAMEPLAY_CAM_RENDERING)
        if ok and isGameplay==false then return false,"Another script camera is active; stop it before previewing" end
    end
    local x,y,z=coord098(sourcePed)
    if not x then return false,"Could not locate player ped" end
    local okHead,heading=pcall(ENTITY.GET_ENTITY_HEADING,sourcePed)
    heading=(okHead and tonumber(heading)) or 0
    local rad=math.rad(heading)
    local dx,dy=-math.sin(rad),math.cos(rad)
    -- Put the camera beyond the clone, looking back. No permanent changes to player.
    local sx,sy,sz=x+dx*2.75,y+dy*2.75,z+0.08
    local cx,cy,cz=x+dx*5.55,y+dy*5.55,z+1.12
    local okClone,clone=pcall(PED.CLONE_PED,sourcePed,false,false,true)
    clone=okClone and tonumber(clone) or 0
    if clone==0 or not exists098(clone) or clone==sourcePed then
        return false,"Local ped clone creation failed"
    end
    Preview098.ped=clone
    Preview098.originalPed=sourcePed
    Preview098.sourceModel=model
    pcall(PED.CLEAR_PED_TASKS_IMMEDIATELY,clone)
    pcall(ENTITY.SET_ENTITY_COLLISION,clone,false,false)
    pcall(ENTITY.SET_ENTITY_INVINCIBLE,clone,true,false)
    pcall(PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS,clone,true)
    pcall(PED.SET_PED_CAN_RAGDOLL,clone,false)
    pcall(ENTITY.SET_ENTITY_COORDS,clone,sx,sy,sz,false,false,false,false)
    pcall(ENTITY.SET_ENTITY_HEADING,clone,heading)
    pcall(ENTITY.FREEZE_ENTITY_POSITION,clone,true)
    local applied,skipped=applyClothes098(clone,doc)
    if applied==0 then return false,"Outfit has no valid components/props for this ped" end
    local okCam,cam=pcall(CAM.CREATE_CAM,"DEFAULT_SCRIPTED_CAMERA",true)
    cam=okCam and tonumber(cam) or 0
    if cam==0 then return false,"Could not create preview camera" end
    Preview098.cam=cam
    pcall(CAM.SET_CAM_COORD,cam,cx,cy,cz)
    pcall(CAM.POINT_CAM_AT_COORD,cam,sx,sy,sz+1.05)
    pcall(CAM.SET_CAM_FOV,cam,39.0)
    local okActive=pcall(CAM.SET_CAM_ACTIVE,cam,true)
    local okRender=pcall(CAM.RENDER_SCRIPT_CAMS,true,false,0,true,true,false)
    if not okActive or not okRender then return false,"Could not activate showroom camera" end
    Preview098.currentId=it.id
    Preview098.expires=nowMs()+90000
    Preview098.status=string.format("LIVE 3D: %s | %d clothing/props applied, %d unavailable",it.name,applied,skipped)
    log("[MV098][OUTFIT][SHOWROOM] "..Preview098.status.." | networked=false")
    return true
end
function Preview098.start(g,it)
    -- Legacy scripted-camera path never used the private-clone registry.
    -- It is disabled; current Marketplace/Local UI uses Preview101/114.
    Preview098.status="Legacy camera showroom disabled for PED safety. Use Outfit hover viewer."
    return
    --[[ Legacy implementation retained for reference only.
    if Preview098.busy then return end
    Preview098.stop("Preparing local-only outfit clone...")
    Preview098.busy=true
    Preview098.status="Downloading and verifying outfit JSON for 3D preview..."
    local token=Preview098.requested
    Script.QueueJob(function()
        local ok,doc,err=pcall(outfitData098,g,it)
        if Preview098.requested~=token then return end
        if not ok or not doc then
            Preview098.busy=false
            Preview098.status="PREVIEW ERROR: "..clean(ok and err or doc,155)
            log("[MV098][OUTFIT][SHOWROOM] "..Preview098.status)
            return
        end
        -- Only instantiate an entity after validated JSON is available.
        local okView,success,why=pcall(createShowroom098,it,doc)
        Preview098.busy=false
        if not okView or not success then
            local message=clean(okView and why or success,165)
            Preview098.stop("PREVIEW ERROR: "..message)
            log("[MV098][OUTFIT][SHOWROOM] "..Preview098.status)
        end
    end)
    ]]
end
function Preview098.tick()
    if Preview098.ped==0 then return end
    if (Preview098.lastTick or 0)>0 and nowMs()-(Preview098.lastTick or 0)<450 then return end
    Preview098.lastTick=nowMs()
    local model,ped=playerModel098()
    if not exists098(Preview098.ped) or ped~=Preview098.originalPed or model~=Preview098.sourceModel
        or nowMs()>Preview098.expires then
        Preview098.stop("3D preview cleaned up (timeout, ped changed, or clone despawned).")
    end
end

-- Build 131: stand-alone hidden private PED (not a clone of the live player).
-- Hovering a card prepares that Outfit on a fresh PED; ONLY the ready ped
-- is drawn by GTA.DrawPedPreview. No per-card clones or fabricated thumbnails.
 -- CLONE_PED fallback calls the four-argument form used by the validated Build 106 preview.
-- Build 129: milestones are based on actual operations, never simulated elapsed time.
local Preview101={enabled=true,clone=0,cped=nil,sourcePed=0,sourceModel=nil,
    shownId=nil,wantedId=nil,wantedItem=nil,wantedGroup=nil,hoverSince=0,
    lastHover=0,lastFrame=0,lastTick=0,lastRender=0,lastInput=0,
    lastResolve=0,queued=false,token=0,nextTryAt=0,status="Hover an Outfit to preview",
    side="Auto",stage=nil,view={yaw=0,pitch=0,distance=-5.3,panX=0,panY=0},
    dragMode=nil,lastMX=nil,lastMY=nil,visible=false,
    verifyFailures={},warnedCPed=false,renderWarned=false,incompatible=nil,
    minHoverMs=300,leaveGraceMs=600,refreshPending=false,
    renderJob=false,renderSuccess=false,testUntil=0,testDrawn=false,
    lastHoverLogId=nil,stageLog=false,lastDiagnosticAt=0,manualPinnedId=nil,
    loadPercent=0,loadPhase="",loadError=nil,loadStarted=0,readyAt=0,failureId=nil,
    uiWarned=false,renderTimeoutLogged=false}
C.OutfitPreview101=Preview101
-- Build 131: handle reuse is NOT identity. Every clone must carry a snapshot
-- of the original engine object address, acquired through documented Cherax
-- CPhysical:GetAddress(). We must NEVER apply clothes, render or delete an
-- entity which no longer matches that snapshot. Fail closed instead.
-- A failed identity preflight prevents spawning any clone in the first place.
local MV131Ped={owned={},warningAt={},quarantined={},spawnBlocked=nil}
C.OutfitPedSafety131=MV131Ped
local function mv131Warn(key,detail)
    local now=nowMs()
    if now-(MV131Ped.warningAt[key] or 0)>2800 then
        MV131Ped.warningAt[key]=now
        log("[MV131][SAFETY][WARNING] "..tostring(detail))
    end
end
function MV131Ped.address(handle)
    handle=tonumber(handle) or 0
    if handle==0 or not exists098(handle) then return nil end
    -- Fast path: a live handle resolves to CPhysical/CEntity with GetAddress.
    if GTA and type(GTA.HandleToPointer)=="function" then
        local ok,obj=pcall(GTA.HandleToPointer,handle)
        if ok and obj then
            local got,n=pcall(function() return obj:GetAddress() end)
            n=got and tonumber(n) or nil
            if n and n~=0 then return n end
        end
    end
    -- Some Cherax versions return a CPhysical without a typed address.
    -- The ped pool exposes CPed:GetAddress() as a second documented route.
    if PoolMgr and type(PoolMgr.GetPed)=="function" and type(PoolMgr.GetCPed)=="function" then
        local count=256
        if type(PoolMgr.GetMaxPedCount)=="function" then
            local ok,n=pcall(PoolMgr.GetMaxPedCount)
            if ok and tonumber(n) then count=math.min(2048,math.max(0,math.floor(n))) end
        end
        for i=0,count-1 do
            local ok,h=pcall(PoolMgr.GetPed,i)
            if ok and tonumber(h)==handle then
                local got,obj=pcall(PoolMgr.GetCPed,i)
                if got and obj then
                    local good,n=pcall(function() return obj:GetAddress() end)
                    n=good and tonumber(n) or nil
                    if n and n~=0 then return n end
                end
                break
            end
        end
    end
    return nil
end
function MV131Ped.preflight(source)
    if MV131Ped.spawnBlocked then
        return false,"Private PED spawn paused after an unsafe identity failure; reload ModVerse"
    end
    local a=MV131Ped.address(source)
    if not a then return false,"Cherax could not verify PED identity; no preview spawned" end
    if not (Natives and type(Natives.InvokeBool)=="function") then
        return false,"Cherax PED ownership checks unavailable; no preview spawned"
    end
    return true,a
end
function MV131Ped.isPrivate(handle)
    if not exists098(handle) then return false,"PED disappeared" end
    if not (Natives and type(Natives.InvokeBool)=="function") then return false,"native checks unavailable" end
    local okNet,networked=pcall(Natives.InvokeBool,0xC7827959479DCC78,handle)
    if not okNet or networked~=false then return false,"PED is networked or network identity unavailable" end
    local okPlayer,isPlayer=pcall(Natives.InvokeBool,0x12534C348C6CB68B,handle)
    if not okPlayer or isPlayer~=false then return false,"PED belongs to a player or player status unknown" end
    -- Every player (not merely the local player) is excluded via IS_PED_A_PLAYER.
    return true
end
function MV131Ped.register(handle,source,model,sourceAddr,kind,generation)
    handle=tonumber(handle) or 0
    if handle==0 or handle==source or not sourceAddr then return false,"invalid clone identity" end
    local a=MV131Ped.address(handle)
    if not a or a==sourceAddr then return false,"private PED identity unavailable" end
    local private,why=MV131Ped.isPrivate(handle)
    if not private then return false,why end
    local ok,m=pcall(ENTITY.GET_ENTITY_MODEL,handle)
    if not ok or norm098(m)~=norm098(model) then return false,"clone model mismatch" end
    -- Do not adopt a handle we already know by another engine identity.
    local previous=MV131Ped.owned[handle]
    if previous and previous.address~=a then return false,"clone handle was reused" end
    MV131Ped.owned[handle]={address=a,source=source,model=norm098(model),created=nowMs(),kind=kind,generation=generation}
    return true
end
function MV131Ped.verify(handle)
    local identity=MV131Ped.owned[tonumber(handle) or 0]
    if not identity then return false,"clone is not registered to ModVerse" end
    if handle==identity.source then return false,"source PED handle collision" end
    local localPed=playerPed098()
    if handle==localPed then return false,"handle now belongs to local player" end
    local current=MV131Ped.address(handle)
    if not current or current~=identity.address then return false,"private PED identity was lost or replaced" end
    local private,why=MV131Ped.isPrivate(handle)
    if not private then return false,why end
    local ok,model=pcall(ENTITY.GET_ENTITY_MODEL,handle)
    if not ok or norm098(model)~=identity.model then return false,"registered PED model changed" end
    return true
end
local function mv101DeleteClone(ped)
    ped=tonumber(ped) or 0
    if ped==0 then return true end
    local identity=MV131Ped.owned[ped]
    if not identity then
        mv131Warn("unknown"..ped,"Unregistered preview handle ignored (no mutation or deletion): "..tostring(ped))
        return false
    end
    if not exists098(ped) then
        MV131Ped.owned[ped]=nil
        return true
    end
    local verified,why=MV131Ped.verify(ped)
    if not verified then
        MV131Ped.quarantined[ped]=tostring(why)
        mv131Warn("stale"..ped,"Stale/reused preview handle ignored (no mutation or deletion): "..tostring(why))
        return false
    end
    if not (Memory and Memory.AllocInt and Memory.WriteInt and Memory.Free) then
        mv131Warn("memory","Pointer-safe DELETE_PED unavailable; private preview retained")
        return false
    end
    local got,ptr=pcall(Memory.AllocInt)
    if not got or not ptr or tonumber(ptr)==0 then return false end
    -- Check again immediately before both native calls. DELETE_PED may
    -- invalidate the handle; only use DELETE_ENTITY if it is STILL the
    -- original engine object. Never delete a recycled handle.
    local success=false
    if MV131Ped.verify(ped) then
        pcall(ENTITY.SET_ENTITY_AS_MISSION_ENTITY,ped,true,true)
        if MV131Ped.verify(ped) and pcall(Memory.WriteInt,ptr,ped) then
            pcall(PED.DELETE_PED,ptr)
        end
        if not exists098(ped) then
            success=true
        elseif MV131Ped.verify(ped) and pcall(Memory.WriteInt,ptr,ped) then
            pcall(ENTITY.DELETE_ENTITY,ptr)
            success=not exists098(ped)
        end
    end
    pcall(Memory.Free,ptr)
    if success then MV131Ped.owned[ped]=nil;MV131Ped.quarantined[ped]=nil
    else mv131Warn("cleanup"..ped,"Verified private preview cleanup deferred; no player entity touched") end
    return success
end
function MV131Ped.pending()
    for h in pairs(MV131Ped.owned) do
        if exists098(h) then return true end
        MV131Ped.owned[h]=nil
    end
    return false
end
-- Build 131: spawn a stand-alone local PED at its HIDDEN location. Unlike
-- CLONE_PED, this never first duplicates the current character at their feet.
-- No network control, no source player mutation, and no gameplay camera.
local function mv131SpawnPrivate(model,source,index)
    if not (GTA and type(GTA.CreatePed)=="function") then
        return nil,"Cherax GTA.CreatePed unavailable; safe standalone preview disabled"
    end
    local x,y,z=coord098(source)
    if not x then return nil,"Player coordinates unavailable; no PED spawned" end
    local offset=tonumber(index) or 0
    local spawnX,spawnY,spawnZ=x+5+offset,y+5+offset,z-12
    local okHead,heading=pcall(ENTITY.GET_ENTITY_HEADING,source)
    heading=okHead and tonumber(heading) or 0
    -- Already-streamed model: it is exactly the model of the local player.
    -- Female freemode peds use the civilian-female ped type where supported.
    -- false,false: no networking and do not auto-clean a PED while drawing.
    local pedType=(norm098(model)==FEMALE098) and 5 or 4
    local ok,ped=pcall(GTA.CreatePed,model,pedType,spawnX,spawnY,spawnZ,heading,false,false)
    ped=ok and tonumber(ped) or 0
    if ped==0 or ped==source or not exists098(ped) then
        return nil,"Standalone private PED creation failed"
    end
    return ped
end
local function mv129Progress(pct,phase)
    -- No time-estimated percentages: only advance when an operation completes.
    Preview101.loadPercent=math.max(0,math.min(99,math.floor(tonumber(pct) or 0)))
    Preview101.loadPhase=tostring(phase or "Preparing preview")
    Preview101.loadError=nil
end
local function mv129Fail(why,deleteClone)
    local reason=tostring(why or "Preview unavailable")
    Preview101.loadError=reason
    Preview101.failureId=Preview101.wantedId
    Preview101.loadPhase="Unable to preview"
    Preview101.status=reason
    Preview101.visible=false
    Preview101.shownId=nil
    Preview101.queued=false
    Preview101.nextTryAt=nowMs()+1500
    if deleteClone and Preview101.clone~=0 then
        local handle=Preview101.clone
        if mv101DeleteClone(handle) then
            Preview101.clone=0;Preview101.cped=nil
            Preview101.sourcePed=0;Preview101.sourceModel=nil
        else
            Preview101.cped=nil -- do not render a handle with lost ownership
        end
    end
end
local function mv101Player()
    local model,ped=playerModel098()
    if model and ped and ped~=0 and exists098(ped) then return model,ped end
    -- Some Cherax contexts expose the CPed but not PLAYER.PLAYER_PED_ID().
    if GTA and type(GTA.GetLocalPed)=="function" and type(GTA.PointerToHandle)=="function" then
        local ok,localCPed=pcall(GTA.GetLocalPed)
        if ok and localCPed then
            local okHandle,h=pcall(GTA.PointerToHandle,localCPed)
            h=okHandle and tonumber(h) or 0
            if h~=0 and exists098(h) then
                local okModel,m=pcall(ENTITY.GET_ENTITY_MODEL,h)
                if okModel and norm098(m) then return norm098(m),h end
            end
        end
    end
    return nil,0
end
local function mv101ResolveCPed(handle)
    if handle==0 or not exists098(handle) then return nil end
    -- Use the typed CPed object from Cherax's ped pool first. The previous
    -- implementation only scanned GetCurrentPedCount, which is not the pool's
    -- highest occupied slot and can miss clones at sparse indices.
    if PoolMgr and PoolMgr.GetPed and PoolMgr.GetCPed then
        local bound=256
        if PoolMgr.GetMaxPedCount then
            local ok,n=pcall(PoolMgr.GetMaxPedCount)
            if ok and type(n)=="number" then bound=math.min(1024,math.max(0,math.floor(n))) end
        end
        for i=0,bound-1 do
            local ok,h=pcall(PoolMgr.GetPed,i)
            if ok and tonumber(h)==handle then
                local found,p=pcall(PoolMgr.GetCPed,i)
                if found and p then
                    local good,addr=pcall(function() return p:GetAddress() end)
                    local owner=MV131Ped.owned[handle]
                    if owner and good and tonumber(addr)==owner.address then return p end
                end
            end
        end
    end
    -- Last resort: Cherax documents a handle-to-CPhysical conversion, but
    -- not every build exposes that returned object as the required CPed type.
    if GTA and type(GTA.HandleToPointer)=="function" then
        local ok,cped=pcall(GTA.HandleToPointer,handle)
        if ok and cped then
            local got,a=pcall(function() return cped:GetAddress() end)
            local owner=MV131Ped.owned[handle]
            if owner and got and tonumber(a)==owner.address then
                -- Address matches, but this generic CPhysical may not satisfy
                -- DrawPedPreview's CPed userdata ABI on all Cherax versions.
                return cped
            end
        end
    end
    return nil
end
local function mv101ResetCloneClothes(clone,source)
    local owned,why=MV131Ped.verify(clone)
    if not owned then return false,why end
    -- Reset cloned model to source clothing before applying another Outfit so
    -- missing components in one JSON never leak from the previous Outfit.
    if PED and PED.SET_PED_DEFAULT_COMPONENT_VARIATION then
        pcall(PED.SET_PED_DEFAULT_COMPONENT_VARIATION,clone)
    end
    for i=0,11 do
        local okD,d=pcall(PED.GET_PED_DRAWABLE_VARIATION,source,i)
        if okD and type(d)=="number" and d>=0 then
            local okT,t=pcall(PED.GET_PED_TEXTURE_VARIATION,source,i)
            local pal=0
            if PED.GET_PED_PALETTE_VARIATION then
                local okP,p=pcall(PED.GET_PED_PALETTE_VARIATION,source,i)
                if okP and type(p)=="number" then pal=p end
            end
            if okT and type(t)=="number" then
                pcall(PED.SET_PED_COMPONENT_VARIATION,clone,i,d,t,pal)
            end
        end
    end
    for i=0,8 do
        local okD,d=pcall(PED.GET_PED_PROP_INDEX,source,i)
        if okD and type(d)=="number" then
            if d<0 then pcall(PED.CLEAR_PED_PROP,clone,i,0)
            else
                local okT,t=pcall(PED.GET_PED_PROP_TEXTURE_INDEX,source,i)
                if okT and type(t)=="number" then pcall(PED.SET_PED_PROP_INDEX,clone,i,d,t,true,0) end
            end
        end
    end
    return true
end
function Preview101.stop(reason)
    Preview101.token=Preview101.token+1
    Preview101.queued=false
    Preview101.visible=false
    Preview101.shownId=nil; Preview101.wantedId=nil
    Preview101.manualPinnedId=nil
    Preview101.wantedItem=nil;Preview101.wantedGroup=nil
    Preview101.dragMode=nil;Preview101.stage=nil
    Preview101.testUntil=0
    if Preview101.clone~=0 and mv101DeleteClone(Preview101.clone) then
        Preview101.clone=0
    end
    Preview101.cped=nil
    Preview101.sourcePed=0;Preview101.sourceModel=nil
    Preview101.status=reason or "Hover an Outfit to preview"
    Preview101.loadPercent=0;Preview101.loadPhase="";Preview101.loadError=nil
    Preview101.loadStarted=0;Preview101.readyAt=0
    Preview101.renderSuccess=false;Preview101.renderTimeoutLogged=false
    Preview101.failureId=nil
end
local function mv101BuildClone(sourcePed,sourceModel)
    -- Build 128: ALWAYS discard the previous hover clone. Resetting components
    -- on an existing clone did not reliably clear prior hats/pants/overlays.
    -- Each outfit gets an independent, freshly cloned ped.
    if Preview101.clone~=0 then
        local previous=Preview101.clone
        if not mv101DeleteClone(previous) then
            return nil,"Previous private PED cleanup pending; cannot safely create another"
        end
        Preview101.clone=0
    end
    if MV131Ped.pending() then
        return nil,"Private PED cleanup pending; refusing to create duplicate"
    end
    Preview101.cped=nil
    if not (Memory and Memory.AllocInt and Memory.WriteInt and Memory.Free) then
        return nil,"Safe ped cleanup API unavailable"
    end
    local preflight,sourceAddr=MV131Ped.preflight(sourcePed)
    if not preflight then return nil,sourceAddr end
    local cloned,spawnError=mv131SpawnPrivate(sourceModel,sourcePed,0)
    if not cloned then return nil,spawnError end
    local registered,registrationError=MV131Ped.register(cloned,sourcePed,sourceModel,sourceAddr,"large",Preview101.token)
    if not registered then
        MV131Ped.spawnBlocked=tostring(registrationError)
        mv131Warn("registration","Private PED registration failed; new spawns blocked: "..tostring(registrationError))
        return nil,"Private PED identity not verified; preview cancelled"
    end
    Preview101.clone=cloned
    Preview101.sourcePed=sourcePed;Preview101.sourceModel=sourceModel
    pcall(ENTITY.SET_ENTITY_AS_MISSION_ENTITY,cloned,true,true)
    pcall(PED.CLEAR_PED_TASKS_IMMEDIATELY,cloned)
    pcall(ENTITY.SET_ENTITY_COLLISION,cloned,false,false)
    pcall(ENTITY.SET_ENTITY_INVINCIBLE,cloned,true,false)
    pcall(PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS,cloned,true)
    pcall(PED.SET_PED_CAN_RAGDOLL,cloned,false)
    -- This PED was created underground rather than cloned at the player's
    -- feet; do not relocate it after ownership registration.
    pcall(ENTITY.FREEZE_ENTITY_POSITION,cloned,true)
    if not MV131Ped.verify(cloned) then
        mv101DeleteClone(cloned)
        return nil,"Private PED identity was lost after placement"
    end
    log("[MV131][OUTFIT][PED] Independently spawned private preview below player (handle + address bound)")
    return cloned
end
function Preview101.hover(g,it)
    if not Preview101.enabled or not g or not it then return end
    if Preview101.manualPinnedId and Preview101.manualPinnedId~=it.id then
        Preview101.manualPinnedId=nil
    end
    local now=nowMs()
    if Preview101.wantedId~=it.id then
        Preview101.wantedId=it.id
        Preview101.hoverSince=now
        -- Let an already-running HTTP task finish before scheduling another.
        -- Token invalidation prevents the stale result from dressing the clone.
        Preview101.token=Preview101.token+1
        Preview101.visible=false
        Preview101.incompatible=nil
        Preview101.stageLog=false
        Preview101.status="Preparing preview"
        Preview101.loadStarted=now
        Preview101.readyAt=0;Preview101.renderSuccess=false
        Preview101.failureId=nil
        Preview101.verifyFailures[it.id]=nil
        Preview101.renderTimeoutLogged=false
        mv129Progress(8,"Waiting for outfit")
        Preview101.dragMode=nil
        log("[MV106][OUTFIT][HOVER] "..tostring(it.id).." | waiting for cached verified Outfit JSON")
    end
    Preview101.wantedItem=it
    Preview101.wantedGroup=g
    Preview101.lastHover=now
    -- Build 147: frame-local fallback. Cherax loop jobs may be throttled while
    -- ImGui owns focus; don't leave an active hover parked forever at 8%.
    if Preview101.wantedId==it.id and not Preview101.queued
        and Preview101.shownId~=it.id and not Preview101.incompatible
        and Preview101.failureId~=it.id and not Preview101.verifyFailures[it.id]
        and now-Preview101.hoverSince>=Preview101.minHoverMs
        and now>=Preview101.nextTryAt and type(Preview101.begin)=="function" then
        Preview101.begin(g,it)
    end
    if Preview101.wantedId==it.id and Preview101.loadPercent<=15
        and not Preview101.queued and not Preview101.loadError
        and now-(Preview101.loadStarted or now)>12000 then
        mv129Fail("3D preview did not start; verify the outfit JSON or use its JPG card",false)
        log("[MV147][PREVIEW][STALL_8] "..tostring(it.id))
    end
end
-- Build 105: independent, CENTERED overlay stage; never rely on clipped
-- table or current ClickGUI window coordinates. All values are screen px.
function Preview101.layout()
    local sw,sh=readVec2(function() return ImGui.GetDisplaySize() end,1920,1080)
    sw=math.max(sw,320);sh=math.max(sh,240)
    -- A display-only 3D viewport to the right of the Cherax menu.
    -- No ImGui window is created, so nothing can clip the ped or capture clicks.
    local centerX=sw*0.68
    local centerY=sh*0.49
    -- Build 108: approximately 3x the original ped viewport AREA on 16:9
    -- displays, not 3x the body height (which would be offscreen).
    local w=math.min(sw*0.60,sh*1.20)
    local h=math.min(sh*0.94,sh-12)
    Preview101.stage={x=centerX-w/2,y=centerY-h/2,w=w,h=h,sw=sw,sh=sh,at=nowMs()}
end
function Preview101.mouse()
    if (not Preview101.visible and nowMs()>=(Preview101.testUntil or 0)) or not Preview101.stage then return end
    local st=Preview101.stage
    local mx,my=readVec2(function() return ImGui.GetMousePos() end,-9999,-9999)
    local inside=mx>=st.x and mx<=st.x+st.w and my>=st.y and my<=st.y+st.h
    local left,right=false,false
    if ImGui.IsMouseDown then
        local ok,v=pcall(ImGui.IsMouseDown,0);left=ok and v~=false and v~=nil and v~=0
        ok,v=pcall(ImGui.IsMouseDown,1);right=ok and v~=false and v~=nil and v~=0
    end
    if not left and not right then Preview101.dragMode=nil;Preview101.lastMX=nil;Preview101.lastMY=nil end
    if inside or Preview101.dragMode then
        Preview101.lastHover=nowMs() -- allow moving pointer from card to ped
    end
    if inside and not Preview101.dragMode and (left or right) then
        Preview101.dragMode=left and right and "zoom" or (right and "move" or "rotate")
        Preview101.lastMX=mx;Preview101.lastMY=my
    end
    if Preview101.dragMode and Preview101.lastMX and Preview101.lastMY then
        local dx=math.max(-55,math.min(55,mx-Preview101.lastMX))
        local dy=math.max(-55,math.min(55,my-Preview101.lastMY))
        if Preview101.dragMode=="rotate" and left then
            Preview101.view.yaw=(Preview101.view.yaw+dx*0.62)%360
            Preview101.view.pitch=math.max(-35,math.min(35,Preview101.view.pitch+dy*.3))
        elseif Preview101.dragMode=="move" and right then
            Preview101.view.panX=math.max(-.16,math.min(.16,Preview101.view.panX+dx/st.sw))
            Preview101.view.panY=math.max(-.20,math.min(.20,Preview101.view.panY+dy/st.sh))
        elseif Preview101.dragMode=="zoom" and left and right then
            Preview101.view.distance=math.max(-5.0,math.min(-1.5,Preview101.view.distance-dy*.032))
        end
        Preview101.lastMX=mx;Preview101.lastMY=my
        Preview101.lastInput=nowMs()
    end
    if inside and ImGui.GetIO then
        local ok,wheel=pcall(function() return tonumber(ImGui.GetIO().MouseWheel) end)
        if ok and wheel and wheel~=0 then
            Preview101.view.distance=math.max(-5.0,math.min(-1.5,Preview101.view.distance+wheel*.28))
            Preview101.lastInput=nowMs()
        end
    end
    if inside and ImGui.IsMouseDoubleClicked then
        local ok,dbl=pcall(ImGui.IsMouseDoubleClicked,0)
        if ok and dbl==true then
            Preview101.view={yaw=0,pitch=0,distance=-5.3,panX=0,panY=0}
        end
    end
end
-- Reference-test path: draw the actual player CPed without cloning or
-- changing clothes. This separates renderer/placement failures from Outfit
-- JSON, compatibility or clone setup failures.
function Preview101.testMyPed()
    Preview101.testUntil=nowMs()+8500
    Preview101.testDrawn=false
    Preview101.stageLog=false
    Preview101.status="TEST: drawing your current ped"
    log("[MV102][OUTFIT][TEST] Requested eight-second local ped renderer test")
    Preview101.startRenderer()
end
local function mv102CurrentCPed()
    if GTA and type(GTA.GetLocalPed)=="function" then
        local ok,p=pcall(GTA.GetLocalPed)
        if ok and p then return p end
    end
    if Players and type(Players.GetCPed)=="function" then
        local id
        if GTA and type(GTA.GetLocalPlayerId)=="function" then
            local ok,n=pcall(GTA.GetLocalPlayerId)
            if ok then id=tonumber(n) end
        end
        if id==nil and PLAYER and PLAYER.PLAYER_ID then
            local ok,n=pcall(PLAYER.PLAYER_ID)
            if ok then id=tonumber(n) end
        end
        if id then
            local ok,p=pcall(Players.GetCPed,id)
            if ok and p then return p end
        end
    end
    return nil
end
function Preview101.renderFrame()
    if not (GTA and GTA.DrawPedPreview and V2 and V2.New) then return end
    local st=Preview101.stage
    if not st then return end
    local now=nowMs()
    local testing=now<(Preview101.testUntil or 0)
    if not testing and not Preview101.visible then return end
    local cped
    if testing then
        cped=mv102CurrentCPed()
        if not cped and now-(Preview101.lastDiagnosticAt or 0)>1700 then
            Preview101.lastDiagnosticAt=now
            log("[MV102][OUTFIT][TEST] GTA.GetLocalPed / Players.GetCPed returned nil")
        end
    else
        local owned,ownershipError=MV131Ped.verify(Preview101.clone)
        if not owned then
            mv129Fail("Private PED identity lost: "..tostring(ownershipError),true)
            return
        end
        if not Preview101.cped and now-Preview101.lastResolve>=500 then
            Preview101.lastResolve=now
            Preview101.cped=mv101ResolveCPed(Preview101.clone)
            if not Preview101.cped and not Preview101.warnedCPed then
                Preview101.warnedCPed=true
                log("[MV102][OUTFIT][RENDER] Clone handle exists but CPed pointer unresolved: "..tostring(Preview101.clone))
            end
        end
        cped=Preview101.cped
        if cped then
            local okAddr,addr=pcall(function() return cped:GetAddress() end)
            local owner=MV131Ped.owned[Preview101.clone]
            if not okAddr or not owner or tonumber(addr)~=owner.address then
                Preview101.cped=nil
                mv129Fail("Typed PED identity differs from private clone",true)
                return
            end
        end
    end
    if not cped then return end
    local view=Preview101.view
    local cx=(st.x+st.w*.5)/st.sw+view.panX
    local cy=(st.y+st.h*.5)/st.sh+view.panY
    local vw=math.min(.60,math.max(.30,st.w/st.sw))
    local vh=math.min(.94,math.max(.58,st.h/st.sh))
    if cx<=0 or cx>=1 or cy<=0 or cy>=1 then
        if not Preview101.stageLog then
            Preview101.stageLog=true
            log(string.format("[MV102][OUTFIT][RENDER] Preview offscreen: %.3f, %.3f",cx,cy))
        end
        return
    end
    local ok,err=pcall(GTA.DrawPedPreview,cped,V2.New(cx,cy),V2.New(vw,vh),
        view.distance,view.pitch,view.yaw,1.0)
    if ok then
        if not testing and Preview101.visible and not Preview101.renderSuccess then
            Preview101.loadPercent=100
            Preview101.loadPhase="Rendered"
        end
        if testing and not Preview101.testDrawn then
            Preview101.testDrawn=true
            log("[MV102][OUTFIT][TEST] DrawPedPreview returned successfully for local ped")
        elseif not testing and not Preview101.renderSuccess then
            Preview101.renderSuccess=true
            log("[MV106][OUTFIT][RENDER] DrawPedPreview called for dressed clone successfully")
        end
    elseif not Preview101.renderWarned then
        Preview101.renderWarned=true
        Preview101.loadError="Cherax PED renderer failed"
        Preview101.status="3D preview render error; see log"
        log("[MV102][OUTFIT][RENDER] DrawPedPreview error: "..tostring(err))
        -- A pointer from one Cherax API may not be a compatible CPed wrapper.
        -- Clear it so the next frame can try resolving it again.
        Preview101.cped=nil
    end
end
function Preview101.startRenderer()
    if Preview101.renderJob or not (Script and Script.QueueJob) then return end
    Preview101.renderJob=true
    Script.QueueJob(function()
        while Preview101.enabled and
            (Preview101.visible or Preview101.queued or Preview101.wantedId or
             nowMs()<(Preview101.testUntil or 0)) do
            local ok,err=pcall(Preview101.renderFrame)
            if not ok and not Preview101.renderWarned then
                Preview101.renderWarned=true
                log("[MV102][OUTFIT][RENDER] Render job exception: "..tostring(err))
            end
            Script.Yield(0) -- Cherax's working ped-preview pattern
        end
        Preview101.renderJob=false
    end)
end
function Preview101.begin(g,it)
    if Preview101.queued or Preview101.failureId==it.id then return end
    -- Local files and Marketplace prefetch are asynchronous. Show their real state
    -- instead of silently returning with an empty viewport.
    if Preview098.loadingBySha[it.sha] then
        mv129Progress(15,"Checking verified outfit JSON")
        return
    end
    if tostring(it.id):sub(1,6)=="local_" and not Preview098.jsonBySha[it.sha] then
        mv129Progress(15,"Waiting for local outfit data")
        return
    end
    Preview101.queued=true
    mv129Progress(24,"Loading outfit")
    local token=Preview101.token
    Script.QueueJob(function()
        local ok,doc,why=pcall(outfitData098,g,it)
        if token~=Preview101.token or not Preview101.enabled then
            Preview101.queued=false
            return
        end
        if not ok or not doc then
            local reason=tostring(ok and why or doc)
            Preview101.verifyFailures[it.id]=reason
            mv129Fail("Outfit JSON unavailable: "..reason,false)
            log("[MV129][PREVIEW][FAILED_JSON] "..tostring(it.id).." | "..reason)
            return
        end
        mv129Progress(40,"Checking model and outfit")
        local model,ped=mv101Player()
        if not model or ped==0 then
            mv129Fail("Player PED unavailable",false)
            return
        end
        if norm098(doc.model)~=model then
            Preview101.incompatible=gender098(doc.model)
            mv129Fail("Incompatible PED model ("..gender098(doc.model)..")",false)
            return
        end
        if not (GTA and type(GTA.DrawPedPreview)=="function" and V2 and V2.New) then
            mv129Fail("Cherax 3D PED renderer unavailable",false)
            return
        end
        local schemaOK,schemaError=mv128PreviewSchema(doc)
        if not schemaOK then
            mv129Fail("Incomplete outfit: "..tostring(schemaError),false)
            return
        end
        mv129Progress(54,"Creating fresh PED")
        local clone,err=mv101BuildClone(ped,model)
        if token~=Preview101.token then Preview101.queued=false; return end
        if not clone then
            mv129Fail(tostring(err),false)
            return
        end
        local owned,identityError=MV131Ped.verify(clone)
        if not owned then mv129Fail("Private PED identity lost: "..tostring(identityError),true);return end
        mv129Progress(68,"Applying clothing and props")
        local resetOK,resetError=mv101ResetCloneClothes(clone,ped)
        if not resetOK or not MV131Ped.verify(clone) then
            mv129Fail("Private PED reset blocked: "..tostring(resetError),true);return
        end
        local applied,skipped=applyClothes098(clone,doc)
        if token~=Preview101.token then Preview101.queued=false; return end
        mv129Progress(84,"Verifying outfit")
        -- Clothing/assets can settle over several GTA ticks, not a single
        -- native call. Never accept an incomplete/mixed PED, but avoid a
        -- premature failure when streaming needs a few frames.
        local matches,detail=false,"not checked"
        if skipped==0 and applied>=21 then
            for attempt=1,6 do
                if Script and Script.Yield then Script.Yield(attempt==1 and 0 or 95) end
                if token~=Preview101.token then Preview101.queued=false;return end
                local stillOwned,identityError=MV131Ped.verify(clone)
                if not stillOwned then mv129Fail("Private PED identity lost: "..tostring(identityError),true);return end
                matches,detail=mv128PreviewMatches(clone,doc)
                if matches then break end
            end
        end
        if skipped>0 or applied<21 or not matches then
            log("[MV129][PREVIEW][FAILED_INCOMPLETE] "..tostring(it.id).." | applied="..
                tostring(applied).." skipped="..tostring(skipped).." detail="..tostring(detail))
            local explain=(skipped>0 or applied<21)
                and ("Unsupported clothing/prop slots ("..tostring(skipped).." skipped)")
                or ("Outfit did not settle: "..tostring(detail))
            mv129Fail(explain,true)
            return
        end
        mv129Progress(93,"Resolving PED renderer")
        Preview101.queued=false
        Preview101.view={yaw=0,pitch=0,distance=-5.3,panX=0,panY=0}
        Preview101.shownId=it.id
        Preview101.visible=true
        Preview101.cped=nil
        Preview101.lastResolve=0
        Preview101.warnedCPed=false;Preview101.renderWarned=false
        Preview101.renderSuccess=false
        Preview101.readyAt=nowMs()
        Preview101.lastInput=nowMs()
        Preview101.startRenderer()
        Preview101.status="Preview: "..shortText(it.name,55)
        log("[MV129][PREVIEW][READY] "..tostring(it.id).." | verified "..tostring(applied).." parts; rendering pending")
    end)
end
function Preview101.tick()
    if not Preview101.enabled then return end
    local now=nowMs()
    if now-(Preview101.lastTick or 0)<12 then return end
    Preview101.lastTick=now
    -- The user may leave Outfits for Vehicles, Themes, or another menu
    -- without entering renderCategory("dlcs"). Drop temporary JSON after
    -- the Outfit tab has been out of view for a short grace period.
    if Preview098.activePageKey and Preview098.lastPageRender
        and now-Preview098.lastPageRender>1500 then
        Preview101.stop("Outfit tab inactive")
        Preview098.clearPage("Outfit tab closed")
        local oldGroup=C.groups.outfits
        if oldGroup then oldGroup.previewPageKey=nil end
        return
    end
    if Preview101.visible then
        local model,ped=mv101Player()
        if not exists098(Preview101.clone) or ped~=Preview101.sourcePed or model~=Preview101.sourceModel then
            Preview101.stop("Player changed; hover to rebuild")
            return
        end
        -- A prior Yield(0) render loop can exit between two quick hovers.
        -- Restart on the next tick instead of leaving the new clone invisible.
        if not Preview101.renderJob then Preview101.startRenderer() end
        if not Preview101.renderSuccess and (Preview101.readyAt or 0)>0
            and now-Preview101.readyAt>5200 and not Preview101.renderTimeoutLogged then
            Preview101.renderTimeoutLogged=true
            local reason=Preview101.cped and "PED renderer did not draw" or "PED pointer could not be resolved"
            log("[MV129][PREVIEW][ERROR_TIMEOUT] "..tostring(Preview101.wantedId).." | "..reason)
            mv129Fail(reason,true)
        end
    end
    if Preview101.wantedId and Preview101.manualPinnedId~=Preview101.wantedId
        and now-Preview101.lastHover>Preview101.leaveGraceMs then
        Preview101.wantedId=nil
        Preview101.wantedItem=nil
        Preview101.wantedGroup=nil
        Preview101.visible=false
        Preview101.shownId=nil
        Preview101.token=Preview101.token+1
        Preview101.status="Hover an Outfit to preview"
        Preview101.incompatible=nil
        Preview101.loadPercent=0;Preview101.loadPhase="";Preview101.loadError=nil
        -- Do not re-dress/recycle the previously shown preview PED.
        -- It is released by the idle cleanup path and never used again.

    end
    if Preview101.wantedId and not Preview101.queued and Preview101.shownId~=Preview101.wantedId
        and not Preview101.incompatible and Preview101.failureId~=Preview101.wantedId
        and not Preview101.verifyFailures[Preview101.wantedId]
        and not (Preview101.wantedItem and Preview098.failedBySha[Preview101.wantedItem.sha])
        and now-Preview101.hoverSince>=Preview101.minHoverMs
        and now>=Preview101.nextTryAt then
        Preview101.begin(Preview101.wantedGroup,Preview101.wantedItem)
    end
    if Preview101.wantedItem and not Preview101.renderSuccess and not Preview101.loadError then
        local err=Preview101.verifyFailures[Preview101.wantedId]
            or (Preview098.failedBySha[Preview101.wantedItem.sha] and
                (Preview101.wantedItem.modelCheckError or "Verified JSON unavailable"))
        if err then mv129Fail("Outfit data unavailable: "..tostring(err),false) end
    end
    if Preview101.visible and Preview101.stage and now-Preview101.stage.at<1500 then
        if not Preview101.dragMode and now-Preview101.lastInput>1200 then
            local dt=math.min(65,math.max(0,now-(Preview101.lastFrame or now)))
            Preview101.view.yaw=(Preview101.view.yaw+dt*0.00155)%360
        end
        Preview101.lastFrame=now
        -- Render is owned by a dedicated Yield(0) job (working Cherax pattern).
        -- The looped tick only updates state, never draws out of frame.
    end
    -- Release the one clone after its previews have been idle. Page changes
    -- never leave six dressed peds wandering in the GTA session.
    if Preview101.clone~=0 and not Preview101.visible and not Preview101.queued
        and now-Preview101.lastHover>2500 then
        if mv101DeleteClone(Preview101.clone) then
            Preview101.clone=0;Preview101.cped=nil
            Preview101.sourcePed=0;Preview101.sourceModel=nil
        end
    end
end
-- Build 105: outside-menu overlay for ONE dressed outfit ped. Unlike
-- the old per-card approach, this overlay appears only after the frontend
-- renderer has successfully received a typed CPed at least once. The
-- underlying JPG cards remain visible and usable if rendering fails.
-- Build 129: a pass-through overlay at the exact large PED viewport. The
-- percentages describe completed loading milestones, NOT a fake time counter.
local function mv129Overlay(pct,label,detail,failed)
    local st=Preview101.stage
    if not st or not ImGui or not ImGui.Begin or not ImGui.End then return end
    local ww,hh=322,94
    local px=math.max(4,math.min(st.sw-ww-4,st.x+st.w*0.5-ww/2))
    local py=math.max(4,math.min(st.sh-hh-4,st.y+st.h*0.48-hh/2))
    local flags=0
    if ImGuiWindowFlags then
        for _,key in ipairs({"NoTitleBar","NoResize","NoMove","NoCollapse",
            "NoSavedSettings","NoScrollbar","NoInputs","NoFocusOnAppearing","NoNav"}) do
            flags=flags | (tonumber(ImGuiWindowFlags[key]) or 0)
        end
    end
    if ImGui.SetNextWindowPos then pcall(ImGui.SetNextWindowPos,px,py,ImGuiCond and ImGuiCond.Always or 0) end
    if ImGui.SetNextWindowSize then pcall(ImGui.SetNextWindowSize,ww,hh,ImGuiCond and ImGuiCond.Always or 0) end
    local ok,shown=pcall(ImGui.Begin,"Outfit Preview Status##MV129",true,flags)
    if not ok then
        if not Preview101.uiWarned then Preview101.uiWarned=true;log("[MV129][PREVIEW][UI] "..tostring(shown)) end
        return
    end
    if shown~=false then
        pcall(function()
            ImGui.TextColored(failed and 1.0 or .80,failed and .53 or .69,failed and .51 or 1.0,1.0,
                failed and "Preview unavailable" or "Loading 3D outfit")
            if not failed then
                if ImGui.ProgressBar then
                    ImGui.ProgressBar(math.max(0,math.min(1,(tonumber(pct) or 0)/100)),299,17,tostring(math.floor(pct)).."%")
                else ImGui.Text(tostring(math.floor(pct)).."%") end
            end
            ImGui.TextColored(.74,.78,.88,1.0,shortText(label or detail or "Preparing...",47))
            if failed and detail and detail~=label then
                ImGui.TextColored(.58,.61,.72,1.0,shortText(detail,54))
            end
        end)
    end
    pcall(ImGui.End)
end
function Preview101.drawPanel()
    local now=nowMs()
    if Preview101.enabled and Preview101.wantedId
        and now-Preview101.lastHover<1100 and not Preview101.renderSuccess then
        local detail=Preview101.loadError
        if detail then
            mv129Overlay(Preview101.loadPercent,"Unable to render outfit",detail,true)
        else
            local phase=Preview101.loadPhase
            if Preview101.visible then
                phase=Preview101.cped and "Waiting for first PED draw" or "Resolving PED renderer"
            elseif not Preview101.queued and Preview101.wantedItem
                and Preview098.loadingBySha[Preview101.wantedItem.sha] then
                phase="Verifying outfit JSON"
            end
            mv129Overlay(Preview101.loadPercent,phase,nil,false)
        end
        return
    end
    -- Local cards have their own clone pool. Show an honest status above the
    -- enlarged hover viewport until that particular clone has drawn.
    local gallery=C.OutfitNativeGallery114
    local hr=gallery and gallery.hoverWait
    if not Preview101.wantedId and gallery and hr and now-(hr.at or 0)<480 then
        local slot=gallery.slots and gallery.slots[hr.id]
        if not slot then return end
        local p=({queued=12,loading=26,dressing=60,checking=82,ready=93})[slot.status]
        if p then
            if slot.status=="ready" and slot.cped then p=98 end
            if not slot.hoverDrawnAt or now-slot.hoverDrawnAt>480 then
                mv129Overlay(p,(slot.status=="ready" and "Preparing PED renderer")
                    or ({queued="Queued for preview",loading="Loading local JSON",dressing="Applying outfit",
                        checking="Checking outfit parts"})[slot.status] or "Preparing preview",nil,false)
            end
        elseif slot.status then
            mv129Overlay(0,"Unable to render local outfit",tostring(slot.status),true)
        end
    end
end

-- Build 108: local-only, read-only Outfit Snatcher.
-- Snapshots each remote player's *currently streamed* clothing once per
-- encounter. Never requests control, edits a remote ped, reads a RID or IP,
-- or submits user data to GitHub. Original remote-model values are preserved.
local Snatcher108={enabled=false,ready=false,seen={},rows={},dedupe={},busy=false,
    nextScan=0,scans=0,saved=0,dupes=0,failures=0,lastError="",query="",page=1,
    diagnostic="Awaiting session scan",playersFound=0,pedsFound=0}
-- Cherax Lua does not always provide global NETWORK native namespaces.
local NETWORK108=mv106NativeNamespace("NETWORK",{
    NETWORK_IS_SESSION_STARTED={"Bool",0x9DE624D2FC4B603F}
})
C.snatcher=Snatcher108
local snatchLegacyDir110=MENU_ROOT.."\\Outfits\\ModVerseLocal\\"
local snatchDir108=MENU_ROOT.."\\Outfits\\Local\\"
local snatchIndex108=ROOT_DIR.."snatcher_index108.tsv"
local function snatchClean108(s,n)
    return tostring(s or ""):gsub("[%z\1-\31]"," "):gsub("[\127]", " "):sub(1,n or 92)
end
local function snatchBase108(s)
    local v=snatchClean108(s,80):gsub('[\\/:*?"<>|]','_'):gsub('[^%w _%-%.]','_')
    v=v:gsub(' +',' '):gsub('^[%. ]+',''):gsub('[%. ]+$',''):sub(1,60)
    return (v=="" or v==".") and "Player" or v
end
local function snatchQuoted108(s)
    s=tostring(s or "")
    return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('[%z\1-\31]',function(c)
        return string.format('\\u%04x',c:byte())
    end)..'"'
end
-- Deterministic JSON encoding so identical outfits produce identical hashes,
-- independent of Lua table iteration order, current lobby or date.
local snapSlots108={{"Head",0},{"Beard",1},{"Hair",2},{"Torso",3},{"Legs",4},{"Hands",5},
    {"Feet",6},{"Teeth",7},{"Special",8},{"Special 2",9},{"Decal",10},{"Tuxedo/Jacket Bib",11}}
local snapProps108={{"Head",0},{"Eyes",1},{"Ears",2},{"Mouth",3},{"Left Hand",4},
    {"Right Hand",5},{"Left Wrist",6},{"Right Wrist",7},{"Hip",8}}
local function remotePed108(id)
    -- Cherax's direct player-ped handle native is the most reliable route.
    -- The earlier scanner tried CPed pointers first, which could be nil in LE.
    if Natives and Natives.InvokeInt then
        for _,hash in ipairs({0x43A66C31C68491C0,0x50FAC3A3E030A6E1}) do
            local ok,p=pcall(Natives.InvokeInt,hash,id)
            if ok and tonumber(p) and tonumber(p)~=0 and exists098(tonumber(p)) then return tonumber(p) end
        end
    end
    if Players and type(Players.GetCPed)=="function" and GTA and GTA.PointerToHandle then
        local ok,p=pcall(Players.GetCPed,id)
        if ok and p then
            local good,h=pcall(GTA.PointerToHandle,p)
            if good and tonumber(h) and tonumber(h)~=0 and exists098(tonumber(h)) then return tonumber(h) end
        end
    end
    return nil
end
local function remotePlayers108()
    -- Primary Cherax player list; fall back to native active slots if a
    -- particular menu build returns an empty list or unexpected table values.
    local ids,used={},{}
    local function add(v)
        local id=tonumber(v)
        if id and id>=0 and id<=31 and id%1==0 and not used[id] then
            ids[#ids+1]=id;used[id]=true
        end
    end
    if Players and type(Players.Get)=="function" and ePlayerListSort then
        for _,sort in ipairs({ePlayerListSort.PLAYER_ID,ePlayerListSort.DISTANCE}) do
            if sort~=nil then
                local ok,t=pcall(Players.Get,sort,"")
                if ok and type(t)=="table" then
                    for _,id in pairs(t) do add(id) end
                end
            end
            if #ids>0 then break end
        end
    end
    if #ids==0 and Natives and Natives.InvokeBool then
        for id=0,31 do
            local ok,active=pcall(Natives.InvokeBool,0xB8DFD30D6973E135,id) -- NETWORK_IS_PLAYER_ACTIVE
            if ok and active then add(id) end
        end
    end
    table.sort(ids)
    return ids
end
-- Build 111: capture authentic Cherax Entity PED appearance, not invented
-- values. Hair tint hash 0xE5C0CF872C2AD150 actually returns NUM HAIR
-- COLORS, not the PED's hair tint; so 255 denotes unknown in Cherax saves.
-- Attachments are read from Cherax's extension graph only when every piece
-- of their data is available. Fail-closed if a detected child is incomplete.
local function snatchFinite111(v,lo,hi)
    v=tonumber(v)
    if not v or v~=v or v<lo or v>hi then return nil end
    return v
end
local function snatchInt111(v,lo,hi)
    v=snatchFinite111(v,lo,hi)
    if not v or v%1~=0 then return nil end
    return math.floor(v)
end
local function snatchCoord111(v)
    local x,y,z
    local good=pcall(function() x=v.x; y=v.y; z=v.z end)
    if not good then return nil end
    x=snatchFinite111(x,-100000,100000)
    y=snatchFinite111(y,-100000,100000)
    z=snatchFinite111(z,-100000,100000)
    if not x or not y or not z then return nil end
    return '{"x":'..string.format('%.5f',x)..',"y":'..string.format('%.5f',y)..
        ',"z":'..string.format('%.5f',z)..'}'
end
local function snatchAttachmentTree111(ped)
    if not (GTA and type(GTA.HandleToPointer)=="function") then return nil end
    local ok,pedObj=pcall(GTA.HandleToPointer,ped)
    if not ok or not pedObj then return nil end
    local okExt,root=pcall(function() return pedObj:GetAttachmentExtension() end)
    if not okExt or not root then return nil end
    local okChild,first=pcall(function() return root.AttachChild end)
    if not okChild or not first then return nil end
    local visited,count={},0
    local function asId(obj)
        local okA,a=pcall(function()return obj:GetAddress() end)
        return okA and tostring(a) or tostring(obj)
    end
    local walk
    walk=function(child,depth)
        if depth>6 then return nil,"Attachment nesting limit exceeded" end
        local out={}
        local siblingCount=0
        while child do
            siblingCount=siblingCount+1;count=count+1
            if siblingCount>32 or count>40 then return nil,"Attachment count limit exceeded" end
            local id=asId(child)
            if visited[id] then return nil,"Attachment cycle detected" end
            visited[id]=true
            local okType,isObj=pcall(function() return child:IsObject() end)
            if not okType or not isObj then return nil,"Attached entity is not an object" end
            local okE,ext=pcall(function() return child:GetAttachmentExtension() end)
            if not okE or not ext then return nil,"Attachment transform missing" end
            local offset,parentOffset,flags,otherBone,myBone
            local okData=pcall(function()
                offset=ext.AttachOffset;parentOffset=ext.AttachParentOffset
                flags=ext.AttachFlags;otherBone=ext.OtherAttachBone
                myBone=ext.MyAttachBone
            end)
            if not okData then return nil,"Attachment metadata unreadable" end
            local off=snatchCoord111(offset)
            local parentOff=snatchCoord111(parentOffset)
            flags=snatchInt111(flags,0,4294967295)
            otherBone=snatchInt111(otherBone,-1,65535)
            myBone=snatchInt111(myBone,-1,65535)
            if not off or not parentOff or not flags or not otherBone or not myBone then
                return nil,"Attachment offsets or flags unavailable"
            end
            local okQ,qx,qy,qz,qw=pcall(function() return ext:GetRotation() end)
            if not okQ then return nil,"Attachment rotation missing" end
            qx=snatchFinite111(qx,-1.2,1.2)
            qy=snatchFinite111(qy,-1.2,1.2)
            qz=snatchFinite111(qz,-1.2,1.2)
            qw=snatchFinite111(qw,-1.2,1.2)
            if not qx or not qy or not qz or not qw then
                return nil,"Attachment quaternion invalid"
            end
            local model
            if GTA and type(GTA.PointerToHandle)=="function" then
                local okHandle,h=pcall(GTA.PointerToHandle,child)
                if okHandle and tonumber(h) and tonumber(h)~=0 then
                    local okModel,m=pcall(ENTITY.GET_ENTITY_MODEL,tonumber(h))
                    if okModel then model=norm098(m) end
                end
            end
            if not model then
                local okModel,m=pcall(function()return child.ModelInfo.Model end)
                if okModel then model=norm098(m) end
            end
            if not model or model==0 then return nil,"Attachment object model unavailable" end
            local ent='{"format":"Cherax Entity","type":3,"model":'..model
            local okChild,nested=pcall(function()return ext.AttachChild end)
            if not okChild then return nil,"Nested attachment traversal failed" end
            if nested then
                local contents,err=walk(nested,depth+1)
                if not contents then return nil,err end
                if #contents>0 then ent=ent..',"attachments":['..table.concat(contents,',')..']' end
            end
            ent=ent..'}'
            out[#out+1]='{"data":{"offset":'..off..',"parentOffset":'..parentOff..
                ',"quat":{"x":'..string.format('%.5f',qx)..',"y":'..string.format('%.5f',qy)..
                ',"z":'..string.format('%.5f',qz)..',"w":'..string.format('%.5f',qw)..
                '},"otherBone":'..otherBone..',"myBone":'..myBone..',"flags":'..flags..
                '},"entity":'..ent..'}'
            local okNext,nextSibling=pcall(function()return ext.AttachSibling end)
            if not okNext then return nil,"Attachment sibling traversal failed" end
            child=nextSibling
        end
        return out
    end
    local result,err=walk(first,1)
    if not result then return false,err end
    return result
end
-- Build 112: Cherax's own saves have baseFlags AND face_features. Omitting
-- baseFlags caused nonstandard local files that the native loader could reject.
-- GTA natives do not provide the complete original remote player's face or
-- serialized flags. A known-good local save of the SAME PED MODEL supplies
-- a structural baseFlags/face baseline; clothing/props still come from target.
-- Native template face shape is NOT a captured remote face and is labeled so.
local snatchTemplates112={}
local snatchFaceNames112={"Nose Width","Nose Peak","Nose Length","Nose Bone Curveness",
    "Nose Tip","Nose Bone Twist","Eyebrow Height","Eyebrow Indent",
    "Cheek Bones","Cheek Sideways Bone Size","Cheek Bones Width","Eye Opening",
    "Lip Thickness","Jaw Bone Width","Jaw Bone Shape","Chin Bone",
    "Chin Bone Length","Chin Bone Shape","Chin Hole","Neck Thickness"}
local function snatchFaceString112(features)
    local parts={}
    for _,name in ipairs(snatchFaceNames112) do
        local n=features and snatchFinite111(features[name],-1.0,1.0) or nil
        if n==nil then return nil end
        parts[#parts+1]=snatchQuoted108(name)..":"..string.format("%.5f",n)
    end
    return "{"..table.concat(parts,",").."}"
end
local function snatchTemplate112(model)
    model=norm098(model)
    if not model then return nil,"Unknown local PED model" end
    if snatchTemplates112[model] then
        local record=snatchTemplates112[model]
        return record~=false and record or nil,record==false and "No same-model native Cherax Outfit template" or nil
    end
    local candidates={}
    if FileMgr and type(FileMgr.FindFiles)=="function" then
        for _,ext in ipairs({".json","json"}) do
            local ok,files=pcall(FileMgr.FindFiles,MENU_ROOT.."\\Outfits\\",ext,false)
            if ok and type(files)=="table" then
                for _,path in pairs(files) do
                    if type(path)=="string" and #candidates<150 then
                        -- These are local native saves only, not the Local Snatcher folder.
                        -- Support FindFiles returning bare names or full paths.
                        local rawName=path:gsub("/","\\")
                        local justName=rawName:match("([^\\]+)$")
                        if justName and justName:lower():sub(-5)==".json"
                            and justName:sub(1,10)~="mMV_Local_" then
                            candidates[#candidates+1]=MENU_ROOT.."\\Outfits\\"..justName
                        end
                    end
                end
            end
        end
    end
    for _,path in ipairs(candidates) do
        local raw=ModVerseHash152.read(path)
        if type(raw)=="string" and #raw>100 and #raw<262144 then
            local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
            if ok and type(doc)=="table" and doc.format=="Cherax Entity" and doc.type==2
                and norm098(doc.model)==model and type(doc.baseFlags)=="number"
                and doc.baseFlags%1==0 and doc.baseFlags>=0 and doc.baseFlags<=4294967295 then
                local face=snatchFaceString112(doc.face_features)
                if face then
                    local template={flags=doc.baseFlags,face=face,source="same-model native Outfit"}
                    snatchTemplates112[model]=template
                    log("[MV112][TEMPLATE] Matching native Outfit found for model "..model)
                    return template
                end
            end
        end
    end
    -- The 14 provided authentic examples all use this male freemode model;
    -- 66855 is the observed common baseline (11/14). No equivalent female
    -- or custom-PED baseline was supplied, so we DO NOT invent one.
    if model==MALE098 then
        local zeros={};for _,name in ipairs(snatchFaceNames112) do zeros[name]=0 end
        local template={flags=66855,face=snatchFaceString112(zeros),source="male sample baseline (not remote face)"}
        snatchTemplates112[model]=template
        log("[MV112][TEMPLATE] Using user-provided male Cherax baseline; save a native Outfit for exact flags")
        return template
    end
    snatchTemplates112[model]=false
    return nil,"Save one Outfit with Cherax's native Save Outfit for your current PED model, then refresh templates"
end
local function readSnap108(ped)
    local ok,m=pcall(ENTITY.GET_ENTITY_MODEL,ped)
    local model=ok and norm098(m) or nil
    if not model or model==0 then return nil,"Model unreadable" end
    local template,templateError=snatchTemplate112(model)
    if not template then return nil,templateError end
    local cmp,props={},{}
    for _,row in ipairs(snapSlots108) do
        local dOk,d=pcall(PED.GET_PED_DRAWABLE_VARIATION,ped,row[2])
        local tOk,t=pcall(PED.GET_PED_TEXTURE_VARIATION,ped,row[2])
        local pOk,p=pcall(PED.GET_PED_PALETTE_VARIATION,ped,row[2])
        d=snatchInt111(d,0,4095)
        t=snatchInt111(t,0,255)
        if not dOk or not tOk or not d or not t then
            return nil,"PED component could not be read: "..row[1]
        end
        local palette=pOk and snatchInt111(p,0,3) or nil
        if not palette then return nil,"PED palette could not be read: "..row[1] end
        cmp[#cmp+1]=snatchQuoted108(row[1])..':{"drawable":'..d..',"texture":'..t..',"palette":'..palette..'}'
    end
    for _,row in ipairs(snapProps108) do
        local dOk,d=pcall(PED.GET_PED_PROP_INDEX,ped,row[2])
        local tOk,t=pcall(PED.GET_PED_PROP_TEXTURE_INDEX,ped,row[2])
        d=snatchInt111(d,-1,4095)
        t=snatchInt111(t,-1,255)
        if not dOk or not d or (d~=-1 and (not tOk or not t or t<0)) then
            return nil,"PED prop could not be read: "..row[1]
        end
        if d==-1 then t=-1 end -- Cherax uses -1/-1 for an empty prop slot.
        props[#props+1]=snatchQuoted108(row[1])..':{"drawable":'..d..',"texture":'..t..'}'
    end
    -- The sample save files use 255/255 when hair colors cannot be read.
    -- There is no standard GTA client native for current hair/highlight color.
    -- 0xE5C0CF872C2AD150 is GET_NUM_HAIR_COLORS and must NOT be called here.
    -- baseFlags and face_features below come from a verified same-model local native template (or the provided male baseline); NOT remote readback.
    local out='{"format":"Cherax Entity","type":2,"model":'..model..
        ',"baseFlags":'..template.flags..',"components":{'..table.concat(cmp,',')..'},"props":{'..table.concat(props,',')..
        '},"face_features":'..template.face..',"primary_hair_tint":255,"secondary_hair_tint":255'
    local attachments,err=snatchAttachmentTree111(ped)
    if attachments==false then return nil,"Cannot save complete attachments: "..tostring(err) end
    if attachments and #attachments>0 then
        out=out..',"attachments":['..table.concat(attachments,',')..']'
    end
    return out..'}'
end
-- Build 110 migration: trust only a matching SHA256, copy via .part + atomic rename,
-- never overwrite an existing destination, and leave the legacy original intact.
-- Reuses existing verified destinations on a restart / interrupted index migration.
local function mv110VerifiedFile(path,sha)
    if not fileExists(path) then return false end
    local raw=ModVerseHash152.read(path)
    return type(raw)=="string" and ModVerseHash152.sha256(raw)==sha
end
local function mv110LegacyCopy(oldDir,newDir,oldName,wantedBase,sha)
    local oldPath=oldDir..oldName
    if not mv110VerifiedFile(oldPath,sha) then return nil,"legacy missing or SHA mismatch" end
    local raw=ModVerseHash152.read(oldPath)
    wantedBase=tostring(wantedBase or "mMV_Local_Unknown"):sub(1,100)
    for suffix=1,5000 do
        local name=wantedBase..(suffix==1 and "" or " "..suffix)..".json"
        local target=newDir..name
        if mv110VerifiedFile(target,sha) then return name,"already copied" end
        if not fileExists(target) then
            local staged=target..".part"
            if not writeBinary(staged,raw) then return nil,"could not stage migration" end
            if not mv110VerifiedFile(staged,sha) then
                os.remove(staged);return nil,"migration readback SHA mismatch"
            end
            if not fileExists(target) and os.rename(staged,target) then
                return name,"copied"
            end
            os.remove(staged)
            -- A failed rename can mean another writer won the race; retry safely.
            if not fileExists(target) then return nil,"could not finalize migration" end
        end
    end
    return nil,"local filename limit"
end
local snatchIndexSave108 -- forward declaration for one-time index upgrade
local function snatchLoad108()
    if Snatcher108.ready then return end
    Snatcher108.ready=true
    FileMgr.CreateDir(MENU_ROOT.."\\Outfits\\")
    FileMgr.CreateDir(snatchDir108)
    local raw=ModVerseHash152.read(snatchIndex108)
    if type(raw)~="string" then raw=ModVerseHash152.read(snatchIndex108..".bak") end
    if type(raw)~="string" then return end
    local upgraded=0
    for line in raw:gmatch("[^\r\n]+") do
        local name,filename,sha=line:match("^([^\t]+)\t([^\t]+)\t([a-f0-9]+)$")
        if name and filename and filename:match("^[A-Za-z0-9_ %-.]+%.json$")
            and #filename<112 and shaOK(sha) then
            local newName=filename
            local legacy=false
            if not mv110VerifiedFile(snatchDir108..filename,sha) then
                if mv110VerifiedFile(snatchLegacyDir110..filename,sha) then
                    local proposed="mMV_Local_"..snatchBase108(name)
                    local copied,why=mv110LegacyCopy(snatchLegacyDir110,snatchDir108,filename,proposed,sha)
                    if copied then newName=copied;upgraded=upgraded+1
                    else legacy=true;log("[MV110][OUTFITS][MIGRATE] "..filename..": "..tostring(why)) end
                else
                    log("[MV110][OUTFITS][MIGRATE] Missing or mismatched entry skipped: "..filename)
                    newName=nil
                end
            elseif filename:sub(1,10)~="mMV_Local_" then
                -- Upgrade even if an old bare name already sits in the new folder.
                local proposed="mMV_Local_"..snatchBase108(name)
                local copied=mv110LegacyCopy(snatchDir108,snatchDir108,filename,proposed,sha)
                if copied then newName=copied;upgraded=upgraded+1 end
            end
            if newName then
                local key=name:lower()..":"..sha
                if not Snatcher108.dedupe[key] then
                    local it={name=name,filename=newName,sha=sha,id="local_"..sha:sub(1,24),kind="outfits",legacy=legacy}
                    Snatcher108.rows[#Snatcher108.rows+1]=it
                    Snatcher108.dedupe[key]=true
                end
            end
        end
    end
    if upgraded>0 then
        if not snatchIndexSave108() then
            log("[MV110][OUTFITS][MIGRATE] Could not update index; original index and files preserved")
        else
            log("[MV110][OUTFITS][MIGRATE] "..upgraded.." legacy capture(s) indexed in Outfits\\Local")
        end
    end
end
snatchIndexSave108=function()
    local lines={}
    for _,it in ipairs(Snatcher108.rows) do
        lines[#lines+1]=snatchClean108(it.name,92).."\t"..it.filename.."\t"..it.sha
    end
    local temp=snatchIndex108..".part"
    if not writeBinary(temp,table.concat(lines,"\r\n")) then return false end
    -- Keep a rollback copy while replacing the index, so a failed rename does
    -- not orphan every previously captured outfit from the Local tab.
    local backup=snatchIndex108..".bak"
    local had=fileExists(snatchIndex108)
    if had then
        if fileExists(backup) then os.remove(backup) end
        if not os.rename(snatchIndex108,backup) then
            os.remove(temp);return false
        end
    end
    if not os.rename(temp,snatchIndex108) then
        os.remove(temp)
        if had then pcall(os.rename,backup,snatchIndex108) end
        return false
    end
    if had then pcall(os.remove,backup) end
    return true
end
local function snatchAdd108(username,raw)
    snatchLoad108()
    username=snatchClean108(username,92):gsub("^%s+",""):gsub("%s+$","")
    if username=="" then username="UnknownPlayer" end
    if #raw<100 or #raw>131072 then return false,"Invalid snapshot size" end
    local sha=ModVerseHash152.sha256(raw)
    if not shaOK(sha) then return false,"Snapshot SHA-256 unavailable" end
    if Snatcher108.dedupe[username:lower()..":"..sha] then
        Snatcher108.dupes=Snatcher108.dupes+1
        return false,"SAME"
    end
    local base=snatchBase108(username)
    local suffix=1
    local filename
    repeat
        filename="mMV_Local_"..base..(suffix==1 and "" or (" "..suffix))..".json"
        suffix=suffix+1
    until not fileExists(snatchDir108..filename) or suffix>5000
    if suffix>5000 then return false,"Local outfit filename limit" end
    local path=snatchDir108..filename
    local stage=path..".part"
    if not writeBinary(stage,raw) then return false,"Could not save outfit" end
    local check=ModVerseHash152.read(stage)
    if type(check)~="string" or ModVerseHash152.sha256(check)~=sha then
        os.remove(stage);return false,"Snapshot readback mismatch"
    end
    if fileExists(path) or not os.rename(stage,path) then
        os.remove(stage);return false,"Could not finalize snapshot"
    end
    local it={name=username,filename=filename,sha=sha,id="local_"..sha:sub(1,24),kind="outfits"}
    Snatcher108.rows[#Snatcher108.rows+1]=it
    Snatcher108.dedupe[username:lower()..":"..sha]=true
    if not snatchIndexSave108() then
        -- Do not lose the captured outfit; it remains on disk for recovery.
        log("[MV108][SNATCHER] Saved outfit, but index update failed: "..filename)
    end
    Snatcher108.saved=Snatcher108.saved+1
    log("[MV112][SNATCHER] Saved Cherax-schema Outfit "..filename.." (model-matched; components/props captured; face/flags use native-compatible template)")
    return true,filename
end
-- Both Local libraries share one player enumeration, but retain independent
-- once-per-encounter / once-per-vehicle records.
local Vehicle109
-- Build 117: Manual scan is a one-shot request for the selected category.
-- It must work when both Auto-Save toggles are OFF, and must never silently
-- scan the other category. Background ticks honor only the Auto-Save toggles.
function Snatcher108.scan(manual,category)
    if Snatcher108.busy then return end
    local doOutfits,doVehicles
    if manual then
        doOutfits=(category==nil or category=="outfits")
        doVehicles=(category==nil or category=="vehicles") and Vehicle109~=nil
    else
        doOutfits=Snatcher108.enabled==true
        doVehicles=Vehicle109~=nil and Vehicle109.enabled==true
    end
    if not doOutfits and not doVehicles then return end
    Snatcher108.busy=true
    local ok,err=pcall(function()
        snatchLoad108()
        if Vehicle109 then Vehicle109.load() end
        local ids=remotePlayers108()
        local currentModel,currentPed=playerModel098()
        if not currentModel or not exists098(currentPed) then
            Snatcher108.lastError="Your current PED model is unavailable; Outfit capture paused"
        end
        if Snatcher108.currentModel~=currentModel then
            Snatcher108.seen={}  -- a gender/model switch invalidates prior capture attempts
            Snatcher108.currentModel=currentModel
            snatchTemplates112={} -- re-check newly native-saved templates on switch
            log("[MV112][MODEL] Local PED changed to "..tostring(currentModel).." ("..gender098(currentModel).."); previous captured files retained")
        end
        local localId=nil
        if GTA and GTA.GetLocalPlayerId then
            local g,v=pcall(GTA.GetLocalPlayerId);if g then localId=tonumber(v) end
        end
        if localId==nil and PLAYER and PLAYER.PLAYER_ID then
            local g,v=pcall(PLAYER.PLAYER_ID);if g then localId=tonumber(v) end
        end
        local remoteCount=0
        for _,id in ipairs(ids) do if id~=localId then remoteCount=remoteCount+1 end end
        local online=false
        if NETWORK108 and NETWORK108.NETWORK_IS_SESSION_STARTED then
            local g,v=pcall(NETWORK108.NETWORK_IS_SESSION_STARTED)
            online=g and (v==true or v==1)
        end
        -- A known remote player in Cherax's live player list corroborates an
        -- online session even if the session-started native is unavailable.
        if remoteCount>0 then online=true end
        Snatcher108.playersFound=remoteCount
        if Vehicle109 then Vehicle109.playersFound=remoteCount end
        if not online then
            Snatcher108.seen={}
            if Vehicle109 then Vehicle109.seen={} end
            Snatcher108.diagnostic="No online remote players discovered ("..#ids.." player slot(s))"
            if Vehicle109 then Vehicle109.diagnostic=Snatcher108.diagnostic end
            return
        end
        local present,streamed,vehInspected,modelSkipped={},0,0,0
        for _,id in ipairs(ids) do
            if id~=localId then
                local okName,name=pcall(Players and Players.GetName or function() return "" end,id)
                name=okName and snatchClean108(name,92) or ""
                if name~="" and name~="Invalid" then
                    local key=tostring(id)..":"..name
                    present[key]=true
                    local ped=remotePed108(id)
                    if ped then
                        streamed=streamed+1
                        if doOutfits and not Snatcher108.seen[key] and currentModel then
                            local okModel,rawModel=pcall(ENTITY.GET_ENTITY_MODEL,ped)
                            local remoteModel=okModel and norm098(rawModel) or nil
                            if not remoteModel then
                                Snatcher108.lastError="Remote PED model unreadable; skipped"
                            elseif remoteModel~=currentModel then
                                modelSkipped=modelSkipped+1
                                -- Do NOT mark seen: this player might change to the
                                -- matching freemode model later in this session.
                            else
                                local raw,reason=readSnap108(ped)
                                if raw then
                                    local saved,detail=snatchAdd108(name,raw)
                                    if saved or detail=="SAME" then Snatcher108.seen[key]=true;Snatcher108.lastError=""
                                    else Snatcher108.failures=Snatcher108.failures+1
                                        Snatcher108.lastError=tostring(detail) end
                                else Snatcher108.lastError=tostring(reason) end
                            end
                        end
                        if doVehicles then
                            if Vehicle109.inspect(id,name,ped) then vehInspected=vehInspected+1 end
                        end
                    end
                end
            end
        end
        for key in pairs(Snatcher108.seen) do if not present[key] then Snatcher108.seen[key]=nil end end
        if Vehicle109 then
            for key in pairs(Vehicle109.seen) do if not present[key] then Vehicle109.seen[key]=nil end end
        end
        Snatcher108.pedsFound=streamed
        Snatcher108.modelSkipped=modelSkipped
        Snatcher108.diagnostic=string.format("Your PED: %s (%s) | Remote: %d | Streamed: %d | Different model: %d | Saved total: %d | Last: %s",
            gender098(currentModel),tostring(currentModel or "unavailable"),remoteCount,streamed,modelSkipped,
            #Snatcher108.rows,Snatcher108.lastError=="" and "OK" or Snatcher108.lastError)
        if Vehicle109 then
            Vehicle109.diagnostic=string.format("Remote players: %d | Streamed PEDs: %d | In vehicles: %d | Saved vehicles: %d | Last: %s",
                remoteCount,streamed,vehInspected,#Vehicle109.rows,Vehicle109.lastError=="" and "OK" or Vehicle109.lastError)
        end
    end)
    if not ok then
        Snatcher108.failures=Snatcher108.failures+1
        Snatcher108.lastError=clean(err,160)
        Snatcher108.diagnostic="Scan error: "..Snatcher108.lastError
        log("[MV109][SNATCHER] scan error: "..Snatcher108.lastError)
    end
    Snatcher108.scans=Snatcher108.scans+1
    Snatcher108.busy=false
    if manual or Snatcher108.scans==1 or Snatcher108.scans%12==0 then
        log("[MV109][SCAN] "..Snatcher108.diagnostic)
        if Vehicle109 then log("[MV109][VEHICLES] "..Vehicle109.diagnostic) end
    end
end
function Snatcher108.tick()
    if Snatcher108.busy or (not Snatcher108.enabled and not (Vehicle109 and Vehicle109.enabled)) then return end
    local now=nowMs()
    if now<(Snatcher108.nextScan or 0) then return end
    Snatcher108.nextScan=now+6500
    Snatcher108.scan(false)
end
-- Build 109: local-only vehicle snapshots from occupied, streamed player
-- vehicles. No network control, entity modifications, or GitHub activity.
Vehicle109={enabled=false,ready=false,seen={},rows={},shaSeen={},nextScan=0,
    saved=0,dupes=0,failures=0,lastError="",diagnostic="Awaiting session scan",
    query="",page=1,playersFound=0,selected=nil}
C.vehicleSnatcher=Vehicle109
log("[MV117][AUTO-SAVE] Player Outfits: OFF | Player Vehicles: OFF (default on every Lua load; manual scans available)")
local vehicleLegacyDir110=MENU_ROOT.."\\Vehicles\\ModVerseLocal\\"
local vehicleLocalDir109=MENU_ROOT.."\\Vehicles\\Local\\"
local vehicleIndex109=ROOT_DIR.."vehicle_index109.tsv"
local vehicleClasses109={"Compacts","Sedans","SUVs","Coupes","Muscle","SportsClassics",
    "Sports","Super","Motorcycles","OffRoad","Industrial","Utility","Vans",
    "Cycles","Boats","Helicopters","Planes","Service","Emergency","Military",
    "Commercial","Trains","OpenWheel"}
local function vehNative109(ret,hash,...)
    local dispatch=Natives and Natives["Invoke"..ret]
    if type(dispatch)~="function" then return nil end
    local good,v=pcall(dispatch,hash,...)
    if good then return v end
    return nil
end
local function vehUInt109(n)
    n=tonumber(n)
    if n and n%1==0 and n>=0 and n<=4294967295 then return n end
    return nil
end
local function vehInt109(n,min,max)
    n=tonumber(n)
    if n and n%1==0 and n>=(min or -1) and n<=(max or 4095) then return n end
    return nil
end
local function vehInts109(hash,vehicle,count)
    if not (Memory and Memory.AllocInt and Memory.ReadInt and Memory.Free) then return nil end
    local ptrs={}
    for i=1,count do
        local ok,ptr=pcall(Memory.AllocInt)
        if not ok or not ptr then
            for _,p in ipairs(ptrs) do pcall(Memory.Free,p) end
            return nil
        end
        ptrs[#ptrs+1]=ptr
    end
    local good=pcall(Natives.InvokeVoid,hash,vehicle,table.unpack(ptrs))
    local nums={}
    if good then for i,p in ipairs(ptrs) do
        local ok,n=pcall(Memory.ReadInt,p)
        if not ok or type(n)~="number" then good=false;break end
        nums[i]=math.floor(n)
    end end
    for _,p in ipairs(ptrs) do pcall(Memory.Free,p) end
    if good then return nums end
    return nil
end
local function vehJson109(x)
    if type(x)~="number" or x%1~=0 then return "0" end
    return tostring(math.floor(x))
end
local function vehColor109(nums)
    if not nums or #nums~=3 then return nil end
    for _,v in ipairs(nums) do if v<0 or v>255 then return nil end end
    return '{"r":'..nums[1]..',"g":'..nums[2]..',"b":'..nums[3]..'}'
end
local function snapshotVehicle109(vehicle)
    if not exists098(vehicle) then return nil,"Vehicle entity unavailable" end
    local model=vehUInt109(vehNative109("Int",0x9F47B058362C84B5,vehicle))
    if not model then
        local raw=vehNative109("Int",0x9F47B058362C84B5,vehicle)
        if raw and raw<0 then model=raw+4294967296 end
    end
    if not model or model==0 then return nil,"Vehicle model unavailable" end
    local vclass=vehInt109(vehNative109("Int",0x29439776AAA00A62,vehicle),0,22)
    if not vclass then return nil,"Vehicle class unavailable" end
    local vehicleType=vehicleClasses109[vclass+1] or "Vehicle"
    local name
    if GTA and GTA.GetModelNameFromHash then
        local ok,v=pcall(GTA.GetModelNameFromHash,model)
        if ok and type(v)=="string" and v~="" then name=v end
    end
    if not name and GTA and GTA.GetDisplayNameFromHash then
        local ok,v=pcall(GTA.GetDisplayNameFromHash,model)
        if ok and type(v)=="string" and v~="" then name=v end
    end
    if not name then name=string.format("Model_%08X",model) end
    name=snatchBase108(name)
    local mods={}
    -- GTA mod slots 0..49. Unknown/unsupported slots are intentionally
    -- omitted, not assigned invented values.
    for slot=0,49 do
        local idx=vehInt109(vehNative109("Int",0x772960298DA26FDB,vehicle,slot),-1,4095)
        if idx then
            local variation=vehNative109("Bool",0xB3924ECD70E095DC,vehicle,slot)
            mods[#mods+1]='"mod'..slot..'":{"index":'..idx..',"variation":'..((variation==true or variation==1) and "true" or "false")..'}'
        end
    end
    local data={'"format":"Cherax Entity"','"type":1','"model":'..model,
        '"mods":{'..table.concat(mods,",")..'}'}
    local function prop(key,value,lo,hi)
        local n=vehInt109(value,lo,hi)
        if n then data[#data+1]=snatchQuoted108(key)..':'..n end
    end
    prop("wheelType",vehNative109("Int",0xB3ED1BFB4BE636DC,vehicle),0,100)
    local colors=vehInts109(0xA19435F193E081AC,vehicle,2)
    if colors then prop("primaryColor",colors[1],0,255);prop("secondaryColor",colors[2],0,255) end
    local extras=vehInts109(0x3BC4245933A166F7,vehicle,2)
    if extras then prop("pearlescentColor",extras[1],0,255);prop("wheelColor",extras[2],0,255) end
    local primaryCustom=vehNative109("Bool",0xF095C0405307B21B,vehicle)
    local secondCustom=vehNative109("Bool",0x910A32E7AAD2656C,vehicle)
    if primaryCustom~=nil then data[#data+1]='"isPrimaryColorCustom":'..(primaryCustom and "true" or "false") end
    if secondCustom~=nil then data[#data+1]='"isSecondaryColorCustom":'..(secondCustom and "true" or "false") end
    if primaryCustom then
        local c=vehColor109(vehInts109(0xB64CF2CCA9D95F52,vehicle,3))
        if c then data[#data+1]='"customPrimaryColor":'..c end
    end
    if secondCustom then
        local c=vehColor109(vehInts109(0x8389CD56CA8072DC,vehicle,3))
        if c then data[#data+1]='"customSecondaryColor":'..c end
    end
    prop("windowTint",vehNative109("Int",0x0EE21293DAD47C95,vehicle),-1,15)
    prop("plateTextIndex",vehNative109("Int",0xF11BC2DD9A3E7195,vehicle),0,20)
    -- Preserve vehicle cosmetics, but never persist owner/session identifiers.
    local plate=vehNative109("String",0x7CE1CCB9B293020E,vehicle)
    if type(plate)=="string" then
        plate=snatchClean108(plate,10)
        if plate~="" then data[#data+1]='"plateText":'..snatchQuoted108(plate) end
    end
    local wheelSm=vehColor109(vehInts109(0xB635392A4938B3C3,vehicle,3))
    if wheelSm then data[#data+1]='"tyreSmokeColor":'..wheelSm end
    local neon=vehColor109(vehInts109(0x7619EEE8C886757F,vehicle,3))
    if neon then
        local k={}
        for i=0,3 do
            local v=vehNative109("Bool",0x8C4B92553E4766A5,vehicle,i)
            k[#k+1]=(v==true or v==1) and "true" or "false"
        end
        data[#data+1]='"neonKits":{"left":'..k[1]..',"right":'..k[2]..',"front":'..k[3]..',"back":'..k[4]..',"color":'..neon..'}'
    end
    local livery=vehInt109(vehNative109("Int",0x2BB9230590DA5E8A,vehicle),-1,200)
    if livery and livery>=0 then data[#data+1]='"livery":'..livery end
    return '{'..table.concat(data,",")..'}',name,vehicleType,model
end
local vehicleIndexSave109 -- forward declaration for one-time index upgrade
function Vehicle109.load()
    if Vehicle109.ready then return end
    Vehicle109.ready=true
    FileMgr.CreateDir(MENU_ROOT.."\\Vehicles\\")
    FileMgr.CreateDir(vehicleLocalDir109)
    local raw=ModVerseHash152.read(vehicleIndex109)
    if type(raw)~="string" then raw=ModVerseHash152.read(vehicleIndex109..".bak") end
    if type(raw)~="string" then return end
    local upgraded=0
    for line in raw:gmatch("[^\r\n]+") do
        local filename,sha,name,typ,model=line:match("^([^\t]+)\t([a-f0-9]+)\t([^\t]+)\t([^\t]+)\t(%d+)$")
        if filename and filename:match("^[A-Za-z0-9_ %-.]+%.json$") and #filename<120
            and shaOK(sha) then
            local newName=filename
            local legacy=false
            if not mv110VerifiedFile(vehicleLocalDir109..filename,sha) then
                if mv110VerifiedFile(vehicleLegacyDir110..filename,sha) then
                    local proposed="mMV_Local_"..(snatchBase108(name).."-"..snatchBase108(typ)):sub(1,88)
                    local copied,why=mv110LegacyCopy(vehicleLegacyDir110,vehicleLocalDir109,filename,proposed,sha)
                    if copied then newName=copied;upgraded=upgraded+1
                    else legacy=true;log("[MV110][VEHICLES][MIGRATE] "..filename..": "..tostring(why)) end
                else
                    log("[MV110][VEHICLES][MIGRATE] Missing or mismatched entry skipped: "..filename)
                    newName=nil
                end
            elseif filename:sub(1,10)~="mMV_Local_" then
                local proposed="mMV_Local_"..(snatchBase108(name).."-"..snatchBase108(typ)):sub(1,88)
                local copied=mv110LegacyCopy(vehicleLocalDir109,vehicleLocalDir109,filename,proposed,sha)
                if copied then newName=copied;upgraded=upgraded+1 end
            end
            if newName and not Vehicle109.shaSeen[sha] then
                local it={filename=newName,sha=sha,name=name,vehicleType=typ,model=tonumber(model),legacy=legacy}
                Vehicle109.rows[#Vehicle109.rows+1]=it
                Vehicle109.shaSeen[sha]=true
            end
        end
    end
    if upgraded>0 then
        if not vehicleIndexSave109() then
            log("[MV110][VEHICLES][MIGRATE] Could not update index; original index and files preserved")
        else
            log("[MV110][VEHICLES][MIGRATE] "..upgraded.." legacy capture(s) indexed in Vehicles\\Local")
        end
    end
end
vehicleIndexSave109=function()
    local lines={}
    for _,it in ipairs(Vehicle109.rows) do
        lines[#lines+1]=table.concat({it.filename,it.sha,snatchClean108(it.name,90),it.vehicleType,tostring(it.model)},"\t")
    end
    local stage=vehicleIndex109..".part"
    if not writeBinary(stage,table.concat(lines,"\r\n")) then return false end
    local backup=vehicleIndex109..".bak"
    local had=fileExists(vehicleIndex109)
    if had then
        if fileExists(backup) then pcall(os.remove,backup) end
        if not os.rename(vehicleIndex109,backup) then os.remove(stage);return false end
    end
    if not os.rename(stage,vehicleIndex109) then
        os.remove(stage);if had then pcall(os.rename,backup,vehicleIndex109) end
        return false
    end
    if had then pcall(os.remove,backup) end
    return true
end
function Vehicle109.add(raw,name,typ,model)
    Vehicle109.load()
    local sha=ModVerseHash152.sha256(raw)
    if not shaOK(sha) or #raw<55 or #raw>65536 then return false,"Invalid vehicle snapshot" end
    if Vehicle109.shaSeen[sha] then Vehicle109.dupes=Vehicle109.dupes+1;return false,"SAME" end
    local base="mMV_Local_"..(snatchBase108(name).."-"..snatchBase108(typ)):sub(1,88)
    local suffix=1
    local filename
    repeat
        filename=base..(suffix==1 and "" or " "..suffix)..".json"
        suffix=suffix+1
    until not fileExists(vehicleLocalDir109..filename) or suffix>5000
    if suffix>5000 then return false,"Vehicle filename limit reached" end
    local path=vehicleLocalDir109..filename
    local stage=path..".part"
    if not writeBinary(stage,raw) then return false,"Failed to save vehicle JSON" end
    local confirm=ModVerseHash152.read(stage)
    if type(confirm)~="string" or ModVerseHash152.sha256(confirm)~=sha then
        os.remove(stage);return false,"Vehicle SHA-256 verification failed"
    end
    if fileExists(path) or not os.rename(stage,path) then
        os.remove(stage);return false,"Could not finalize vehicle JSON"
    end
    local item={filename=filename,sha=sha,name=name,vehicleType=typ,model=model}
    Vehicle109.rows[#Vehicle109.rows+1]=item
    Vehicle109.shaSeen[sha]=true
    if not vehicleIndexSave109() then log("[MV109][VEHICLES] Saved vehicle but index update failed: "..filename) end
    Vehicle109.saved=Vehicle109.saved+1
    log("[MV109][VEHICLES] Saved "..filename.." (local only; passive snapshot)")
    return true,filename
end
function Vehicle109.inspect(id,name,ped)
    local inCar=vehNative109("Bool",0x997ABD671D25CA0B,ped,false)
    if not inCar then return false end
    local veh=vehNative109("Int",0x9A9112A0FE9A4713,ped,false)
    if not veh or veh==0 or not exists098(veh) then return false end
    local key=tostring(id)..":"..name
    local seen=Vehicle109.seen[key]
    -- Once per observed vehicle model/handle during the same encounter.
    local model=vehNative109("Int",0x9F47B058362C84B5,veh)
    local current=tostring(veh)..":"..tostring(model)
    if seen and seen[current] then return true end
    local raw,vname,vtype,vmodel=snapshotVehicle109(veh)
    if not raw then Vehicle109.lastError=tostring(vname);return true end
    local saved,reason=Vehicle109.add(raw,vname,vtype,vmodel)
    if saved or reason=="SAME" then
        seen=seen or {};seen[current]=true;Vehicle109.seen[key]=seen;Vehicle109.lastError=""
    else Vehicle109.failures=Vehicle109.failures+1;Vehicle109.lastError=tostring(reason) end
    return true
end
-- Build 116: A remotely inspected vehicle is not automatically a complete
-- native Cherax vehicle save. Match an existing native-saved file by model to
-- recover the correct loader flags, without inventing global defaults.
local vehicleTemplateCache116={}
local function vehicleTemplate116(model)
    model=vehUInt109(model)
    if not model then return nil,"Vehicle model unavailable" end
    if vehicleTemplateCache116[model] then return vehicleTemplateCache116[model] end
    if not (FileMgr and type(FileMgr.FindFiles)=="function") then
        return nil,"Cherax vehicle file scanner is unavailable"
    end
    local candidates={}
    for _,ext in ipairs({".json","json"}) do
        local ok,files=pcall(FileMgr.FindFiles,MENU_ROOT.."\\Vehicles\\",ext,false)
        if ok and type(files)=="table" then
            for _,p in pairs(files) do
                if type(p)=="string" then
                    local just=p:gsub("/","\\"):match("([^\\]+)$")
                    if just and just:lower():sub(-5)==".json"
                        and just:lower():sub(1,10)~="mmv_local_" then
                        candidates[#candidates+1]=MENU_ROOT.."\\Vehicles\\"..just
                    end
                end
                if #candidates>=200 then break end
            end
        end
    end
    for _,path in ipairs(candidates) do
        local raw=ModVerseHash152.read(path)
        if type(raw)=="string" and #raw>100 and #raw<1048576 then
            local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
            if ok and type(doc)=="table" and doc.format=="Cherax Entity"
                and doc.type==1 and vehUInt109(doc.model)==model
                and vehUInt109(doc.baseFlags)~=nil and type(doc.mods)=="table" then
                local template={flags=doc.baseFlags,source=path}
                vehicleTemplateCache116[model]=template
                log("[MV116][VEHICLE][TEMPLATE] Matching native vehicle save found for model "..model)
                return template
            end
        end
    end
    -- Do not cache misses: a newly native-saved file can become available.
    return nil,"Use Cherax to save a stock vehicle of this exact model, then retry Repair"
end
local function vehicleDoc116(it)
    if not it or not shaOK(it.sha) then return nil,nil,"Invalid Local vehicle record" end
    local raw=ModVerseHash152.read((it.legacy and vehicleLegacyDir110 or vehicleLocalDir109)..it.filename)
    if type(raw)~="string" or ModVerseHash152.sha256(raw)~=it.sha then
        return nil,nil,"Vehicle SHA-256 check failed" end
    local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
    if not ok or type(doc)~="table" or doc.format~="Cherax Entity" or doc.type~=1
        or not vehUInt109(doc.model) or type(doc.mods)~="table" then
        return nil,nil,"Not a valid Cherax vehicle JSON structure" end
    if vehUInt109(doc.model)~=vehUInt109(it.model) then
        return nil,nil,"Vehicle model differs from Local index" end
    return raw,doc,nil
end
local function vehicleRepair116(it)
    local raw,doc,err=vehicleDoc116(it)
    if not raw then return false,err end
    if vehUInt109(doc.baseFlags) then return false,"This vehicle already contains baseFlags; load failure needs further diagnosis" end
    local template,why=vehicleTemplate116(doc.model)
    if not template then return false,why end
    local updated,count=raw:gsub('("model"%s*:%s*%d+)',
        function(match) return match..',"baseFlags":'..tostring(template.flags) end,1)
    if count~=1 then return false,"Could not safely add loader flags" end
    local ok,parsed=pcall(ModVerseCommunity078.decodeJson,updated)
    if not ok or type(parsed)~="table" or parsed.format~="Cherax Entity"
        or parsed.type~=1 or vehUInt109(parsed.model)~=vehUInt109(it.model)
        or parsed.baseFlags~=template.flags then return false,"Repaired JSON validation failed" end
    -- Save as another version in Vehicles\\Local. Never replace original.
    local saved,result=Vehicle109.add(updated,it.name,it.vehicleType,it.model)
    if saved then
        log("[MV116][VEHICLE][REPAIR] Native-model flags copied to new capture "..tostring(result))
        return true,"New compatibility candidate: "..result
    end
    return false,result=="SAME" and "An identical repaired copy already exists" or tostring(result)
end

function C.renderLocalVehicles()
    Vehicle109.load()
    ImGui.TextColored(.80,.58,1,1,"Local Vehicles")
    ImGui.SameLine();ImGui.Text(tostring(#Vehicle109.rows).." saved")
    if ImGui.Button((Vehicle109.enabled and "Auto-Save: ON" or "Auto-Save: OFF").."##MV117VehicleAuto",135,27) then
        Vehicle109.enabled=not Vehicle109.enabled
        if Vehicle109.enabled then Snatcher108.nextScan=0 end
        log("[MV117][VEHICLES] Auto-Save Player Vehicles "..(Vehicle109.enabled and "ON" or "OFF"))
    end
    ImGui.SameLine()
    if ImGui.Button("Scan Now##MV109V",110,27) then
        Snatcher108.nextScan=nowMs()+6500;Snatcher108.scan(true,"vehicles")
    end
    local vehicleDetails=productionDetails118("vehicles","Details",100)
    if vehicleDetails then
        ImGui.TextWrapped("Scanner: "..Vehicle109.diagnostic)
        ImGui.TextWrapped("Captures streamed occupied vehicles only. Saved vehicle configurations may require a native Cherax save to become loadable. No files are uploaded.")
        ImGui.Text("Folder: Cherax\\Vehicles\\Local")
    end
    local q=ImGui.InputText("Search local vehicles##MV109",Vehicle109.query,100)
    if type(q)=="string" and q~=Vehicle109.query then Vehicle109.query=q;Vehicle109.page=1 end
    local matches={}
    for i=#Vehicle109.rows,1,-1 do
        local it=Vehicle109.rows[i]
        if Vehicle109.query=="" or it.filename:lower():find(Vehicle109.query:lower(),1,true) then
            matches[#matches+1]=it
        end
    end
    -- Populate class choices from real captured vehicle metadata, not guessed GTA classes.
    local classSeen,classNames={},{}
    for _,it in ipairs(Vehicle109.rows) do
        local name=tostring(it.vehicleType or 'Vehicle')
        if not classSeen[name] then classSeen[name]=true;classNames[#classNames+1]=name end
    end
    table.sort(classNames)
    local choices={'All classes'}
    for _,name in ipairs(classNames) do choices[#choices+1]=name end
    if MV122Filters.bar('localvehicles','localvehicles',choices) then Vehicle109.page=1 end
    local retained={}
    for _,it in ipairs(matches) do
        local favId=C.localVehicleFav123(it)
        local fav=MV122Filters.state('localvehicles').show==2 and C.isFavorite('vehicles',favId)
        if MV122Filters.keep(it,'localvehicles','localvehicles',false,fav) then retained[#retained+1]=it end
    end
    matches=MV122Filters.order(retained,'localvehicles')
    if #matches==0 then ImGui.TextWrapped("No local vehicles saved yet. Players must be in streamed vehicles when the scanner runs.") end
    local pages=math.max(1,math.ceil(#matches/12))
    Vehicle109.page=math.max(1,math.min(pages,Vehicle109.page))
    if ImGui.Button("< Prev##MV109V",90,25) then Vehicle109.page=math.max(1,Vehicle109.page-1) end
    ImGui.SameLine();ImGui.Text("Page "..Vehicle109.page.." / "..pages.." | "..#matches.." vehicles")
    ImGui.SameLine()
    if ImGui.Button("Next >##MV109V",90,25) then Vehicle109.page=math.min(pages,Vehicle109.page+1) end
    if Vehicle109.lastError~="" then ImGui.TextColored(1,.66,.40,1,shortText(Vehicle109.lastError,112)) end
    local first=(Vehicle109.page-1)*12+1
    local w=select(1,contentAvail())
    local cols=math.max(2,math.min(4,math.floor((w or 500)/154)))
    local tileWidth=math.max(124,((w or 500)-(cols-1)*8)/cols-7)
    if ImGui.BeginChild then ImGui.BeginChild("MV116LocalVehiclesGrid",0,math.max(160,math.min(360,select(2,contentAvail()) or 320)),true) end
    if ImGui.BeginTable("MV116LocalVehicleTiles",cols,ImGuiTableFlags.SizingStretchSame) then
        for i=first,math.min(#matches,first+11) do
            local it=matches[i]
            ImGui.TableNextColumn()
            ImGui.PushID("MV116Vehicle_"..it.filename)
            local x,y=cursorScreenPos()
            local clicked=ImGui.InvisibleButton("##vehicle",tileWidth,104)
            local hovered=ImGui.IsItemHovered()
            drawImageCardBackground(x,y,tileWidth,104,hovered,Vehicle109.selected==it.filename)
            ImGui.AddRectFilled(x+3,y+3,x+tileWidth-3,y+68,26,31,48,255,5)
            ImGui.AddText(x+10,y+13,"LOCAL VEHICLE",185,165,235,255)
            ImGui.AddText(x+10,y+38,shortText(it.vehicleType or "Vehicle",math.max(10,math.floor(tileWidth/8))),201,218,236,255)
            ImGui.AddRectFilled(x+3,y+68,x+tileWidth-3,y+101,15,17,28,250)
            ImGui.AddText(x+8,y+76,shortText(it.name or it.filename,math.max(11,math.floor((tileWidth-12)/7.5))),246,245,255,255)
            local favId=C.localVehicleFav123(it)
            if C.cardStar123("vehicles",favId,x,y,hovered) then clicked=false end
            if clicked then Vehicle109.selected=it.filename end
            if hovered and ImGui.BeginTooltip then
                ImGui.BeginTooltip();ImGui.Text(shortText(it.filename,90))
                ImGui.Text("Snapshot only. Native loading compatibility not guaranteed.")
                ImGui.EndTooltip()
            end
            ImGui.PopID()
        end
        ImGui.EndTable()
    end
    C.starFinish123()
    if ImGui.EndChild then ImGui.EndChild() end
    if Vehicle109.selected then
        for _,it in ipairs(Vehicle109.rows) do
            if it.filename==Vehicle109.selected then
                ImGui.Separator()
                ImGui.Text("Selected: "..shortText(it.name,48))
                if vehicleDetails then
                    ImGui.Text("Type: "..tostring(it.vehicleType).." | Model: "..tostring(it.model))
                    ImGui.Text("SHA-256: "..it.sha:sub(1,16).."...")
                end
                local rawDoc,decoded,loadError=vehicleDoc116(it)
                if loadError then ImGui.TextWrapped("Capture warning: "..loadError)
                elseif not vehUInt109(decoded.baseFlags) then
                    ImGui.TextColored(1,.69,.37,1,"Incomplete snapshot: no native baseFlags. Do not treat as a ready-to-load vehicle.")
                    if vehicleDetails and ImGui.Button("Repair from matching Cherax save##MV116V",275,27) then
                        local repaired,why=vehicleRepair116(it)
                        toast(why,4200)
                    end
                else
                    ImGui.TextColored(.53,.88,.66,1,"Native flags present; full restore still requires an in-game test.")
                end
                if ImGui.Button("Copy to Cherax Vehicles##MV109V",225,27) then
                    local raw=rawDoc
                    if not raw then
                        toast("Local vehicle integrity check failed",3200)
                    elseif not vehUInt109(decoded.baseFlags) then
                        toast("Incomplete snapshot. Repair with a native same-model save first.",4000)
                    else
                        local target=MENU_ROOT.."\\Vehicles\\"..it.filename
                        if fileExists(target) then toast("Already exists; not overwriting",2900)
                        elseif not writeBinary(target..".part",raw) then toast("Could not stage vehicle file",2900)
                        elseif not os.rename(target..".part",target) then
                            os.remove(target..".part");toast("Could not install local vehicle",2900)
                        else toast("Saved copy to Cherax Vehicles",3200) end
                    end
                end
                if vehicleDetails then
                    ImGui.TextWrapped("Vehicle loading is still experimental. Repairs preserve the original capture; successful restoration is not guaranteed.")
                end
                break
            end
        end
    end
end

local function snatchLocalDoc108(it)
    if not it or not shaOK(it.sha) then return nil,"Invalid local entry" end
    local path=(it.legacy and snatchLegacyDir110 or snatchDir108)..it.filename
    local raw=ModVerseHash152.read(path)
    if type(raw)~="string" or ModVerseHash152.sha256(raw)~=it.sha then
        return nil,"Saved JSON SHA-256 mismatch" end
    local ok,doc=pcall(ModVerseCommunity078.decodeJson,raw)
    if not ok or type(doc)~="table" or doc.format~="Cherax Entity" or doc.type~=2
        or type(doc.components)~="table" or not norm098(doc.model) then return nil,"Invalid local outfit JSON" end
    return doc
end
-- Older snapshots remain on disk, but the visible Local library only shows
-- the current PED model. A legacy entry without flags is still visible for
-- optional repair if its model matches, rather than being silently removed.
local snatchRowModel112={}
local function snatchEntryModel112(it)
    if it.model then return norm098(it.model) end
    local cached=snatchRowModel112[it.sha]
    if cached~=nil then return cached~=false and cached or nil end
    local doc=snatchLocalDoc108(it) -- SHA-verified, no untrusted index model
    local model=doc and norm098(doc.model) or nil
    snatchRowModel112[it.sha]=model or false
    if model then it.model=model end
    return model
end
-- Build 113: local-only gallery. No network fetch, no Github upload, no guessed photos.
-- A separate optional Windows helper can capture the already-rendered frontend PED.
-- Build 114: entirely native LOCAL Outfit gallery. GTA.DrawPedPreview draws each
-- SHA-verified, same-model Outfit on a non-networked clone inside its card.
-- No screen capture, .bat helpers, Python, HTTP fetches or JPG creation.
-- Six independent private PEDs max, only while Local is visible; all are removed on page switch,
-- changing PED model, tab departure and script unload.
local NativeGallery114={enabled=true,slots={},order={},positions={},pageKey=nil,
    renderJob=false,busy=false,generation=0,lastUI=0,hoverId=nil,hoverAt=0,
    startMs=nowMs(),sourcePed=0,sourceModel=nil,clip=nil,report="",warned=false,
    -- Build 115: ON_POST_PRESENT draws after normal menu compositing where supported.
    postHandler=nil,postEnabled=false,postFailed=false,lastPost=0,postCount=0,
    lastDraw=0,drawCalls=0,drawLogged=false,layerNotice=false,skippedLog=false,
    displayW=1920,displayH=1080,lastUIPass=0,postLastDraw=0}
C.OutfitNativeGallery114=NativeGallery114

local function native114Release(reason)
    local n=#NativeGallery114.order
    NativeGallery114.generation=NativeGallery114.generation+1
    NativeGallery114.pageKey=nil
    NativeGallery114.hoverId=nil
    NativeGallery114.hoverWait=nil
    NativeGallery114.positions={}
    NativeGallery114.order={}
    local old=NativeGallery114.slots
    NativeGallery114.slots={}
    NativeGallery114.busy=false
    NativeGallery114.drawLogged=false
    NativeGallery114.layerNotice=false
    NativeGallery114.skippedLog=false
    NativeGallery114.sourcePed=0
    NativeGallery114.sourceModel=nil
    for _,slot in pairs(old) do
        if slot.ped and slot.ped~=0 then mv101DeleteClone(slot.ped) end
        slot.cped=nil
    end
    if n>0 then
        log("[MV114][LOCAL][CLEANUP] Released "..n.." native card preview(s): "..tostring(reason or "closed"))
    end
end
NativeGallery114.stop=native114Release

local function native114CreateSlot(slot,source,model,generation,index)
    if generation~=NativeGallery114.generation or not NativeGallery114.enabled then return end
    slot.status="loading"
    local doc,err=snatchLocalDoc108(slot.it)
    if not doc or norm098(doc.model)~=model then
        slot.status="invalid JSON / model mismatch: "..tostring(err or "incompatible")
        return
    end
    local schemaOK,schemaReason=mv128PreviewSchema(doc)
    if not schemaOK then
        slot.status="incomplete outfit: "..tostring(schemaReason)
        return
    end
    if not exists098(source) then slot.status="player PED unavailable";return end
    local safe,sourceAddr=MV131Ped.preflight(source)
    if not safe then slot.status=tostring(sourceAddr);return end
    -- Current-generation Local cards are intentional siblings (up to six),
    -- not leaks. Only old generations and the large-preview clone block spawn.
    for h,owner in pairs(MV131Ped.owned) do
        if not exists098(h) then
            MV131Ped.owned[h]=nil
        elseif owner.kind~="local" or owner.generation~=generation then
            slot.status="prior private PED cleanup pending";return
        end
    end
    local handle,spawnError=mv131SpawnPrivate(model,source,index)
    if not handle then
        slot.status=tostring(spawnError)
        return
    end
    local registered,why=MV131Ped.register(handle,source,model,sourceAddr,"local",generation)
    if not registered then
        MV131Ped.spawnBlocked=tostring(why)
        slot.status="private PED identity unavailable; reloading ModVerse required"
        mv131Warn("localReg","Local preview PED identity unavailable; new spawns blocked: "..tostring(why))
        return
    end
    if generation~=NativeGallery114.generation then mv101DeleteClone(handle);return end
    -- Non-networked, passive and placed nearby UNDER the map to keep streamed.
    -- Never request network control or modify another player's entity.
    slot.ped=handle
    pcall(ENTITY.SET_ENTITY_AS_MISSION_ENTITY,handle,true,true)
    pcall(PED.CLEAR_PED_TASKS_IMMEDIATELY,handle)
    pcall(ENTITY.SET_ENTITY_COLLISION,handle,false,false)
    pcall(ENTITY.SET_ENTITY_INVINCIBLE,handle,true,false)
    pcall(PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS,handle,true)
    pcall(PED.SET_PED_CAN_RAGDOLL,handle,false)
    -- Already spawned beneath the local player without visible duplication.
    pcall(ENTITY.FREEZE_ENTITY_POSITION,handle,true)
    slot.status="dressing"
    local resetOK,resetError=mv101ResetCloneClothes(handle,source)
    if not resetOK or not MV131Ped.verify(handle) then
        slot.status="private PED identity lost: "..tostring(resetError)
        mv101DeleteClone(handle);slot.ped=0;return
    end
    local applied,skipped=applyClothes098(handle,doc)
    if generation~=NativeGallery114.generation then mv101DeleteClone(handle);slot.ped=0;return end
    if Script and Script.Yield then Script.Yield(0) end
    if generation~=NativeGallery114.generation then mv101DeleteClone(handle);slot.ped=0;return end
    slot.status="checking"
    local matched,why=false,"not checked"
    if tonumber(applied) and applied>=21 and skipped==0 then
        for attempt=1,5 do
            if attempt>1 and Script and Script.Yield then Script.Yield(95) end
            if generation~=NativeGallery114.generation then mv101DeleteClone(handle);slot.ped=0;return end
            if not MV131Ped.verify(handle) then
                slot.status="private PED identity lost"
                mv101DeleteClone(handle);slot.ped=0;return
            end
            matched,why=mv128PreviewMatches(handle,doc)
            if matched then break end
        end
    end
    if tonumber(applied) and applied>=21 and skipped==0 and matched then
        slot.status="ready"
        slot.createdAt=nowMs()
        slot.hasAttachments=type(doc.attachments)=="table" and #doc.attachments>0
    else
        slot.status="preview incomplete"
        log("[MV128][LOCAL][FAILED_INCOMPLETE] "..tostring(slot.it.filename).." | "..tostring(why or skipped))
        mv101DeleteClone(handle)
        slot.ped=0
    end
end

local function native114RenderFrame(phase)
    if not (GTA and type(GTA.DrawPedPreview)=="function" and V2 and type(V2.New)=="function") then return end
    local now=nowMs()
    if not NativeGallery114.enabled or not NativeGallery114.pageKey
        or now-NativeGallery114.lastUI>650 then return end
    -- ON_POST_PRESENT can execute outside the ImGui layout scope. Use the
    -- screen dimensions sampled while the Local UI was actually rendered.
    local sw,sh=NativeGallery114.displayW,NativeGallery114.displayH
    if not sw or not sh or sw<=0 or sh<=0 then return end
    local yaw=((now-NativeGallery114.startMs)*0.003)%360 -- 3 degrees/second
    local attempted,drawn,culled=0,0,0
    for _,id in ipairs(NativeGallery114.order) do
        local slot=NativeGallery114.slots[id]
        local pos=NativeGallery114.positions[id]
        if slot and slot.status=="ready" and pos and now-pos.at<900 then
            local owned,identityError=MV131Ped.verify(slot.ped)
            if not owned then
                slot.status="private PED identity lost"
                slot.cped=nil
                mv131Warn("localDraw"..tostring(id),"Refused draw of unowned local preview: "..tostring(identityError))
            else
            if not slot.cped and now-(slot.lastResolve or 0)>600 and exists098(slot.ped) then
                slot.lastResolve=now
                slot.cped=mv101ResolveCPed(slot.ped)
            end
            if not slot.cped and not slot.warnedResolve and now-(slot.createdAt or now)>2600 then
                slot.warnedResolve=true
                slot.status="PED pointer unavailable"
                log("[MV129][LOCAL][ERROR_PED] Typed CPed could not be resolved for "..tostring(id))
            end
            if slot.cped then
                local checkAddr,typedAddr=pcall(function() return slot.cped:GetAddress() end)
                local snapshot=MV131Ped.owned[slot.ped]
                if not checkAddr or not snapshot or tonumber(typedAddr)~=snapshot.address then
                    slot.cped=nil
                    slot.status="typed PED identity unavailable"
                    mv131Warn("typed"..tostring(id),"Blocked Local card draw: typed PED no longer matches clone")
                else
                -- Build 115: the strict full-rectangle test in Build 114
                -- rejected partly visible cards, including near child borders.
                -- Require the CARD CENTER to be visible in the gallery instead.
                -- Never render completely offscreen peds: the preview native
                -- does not obey ImGui's child clipping.
                attempted=attempted+1
                local clip=NativeGallery114.clip
                local centerX,centerY=pos.x+pos.w*.5,pos.y+pos.h*.5
                local visible=(not clip or (centerX>=clip.x+2 and centerX<=clip.x+clip.w-2
                    and centerY>=clip.y+2 and centerY<=clip.y+clip.h-2))
                    and centerX>0 and centerY>0 and centerX<sw and centerY<sh
                if visible then
                    local cx=centerX/sw
                    local cy=centerY/sh
                    local vw=math.max(.03,math.min(.35,pos.w/sw))
                    local vh=math.max(.05,math.min(.50,pos.h/sh))
                    local ok,err=pcall(GTA.DrawPedPreview,slot.cped,V2.New(cx,cy),V2.New(vw,vh),-3.70,0,yaw,1.0)
                    if ok then
                        drawn=drawn+1
                        NativeGallery114.lastDraw=now
                        NativeGallery114.drawCalls=NativeGallery114.drawCalls+1
                        if not NativeGallery114.drawLogged then
                            NativeGallery114.drawLogged=true
                            log("[MV115][LOCAL][TOP] First live PED draw submitted | phase="..tostring(phase or "fallback")..
                                " | card="..tostring(id))
                        end
                    elseif not slot.warned then
                        slot.warned=true
                        slot.status="render failure"
                        log("[MV115][LOCAL][RENDER] "..tostring(id).." | "..tostring(err))
                    end
                else
                    culled=culled+1
                end
                -- Hover enlarges THE SAME CPed. There is no seventh clone.
                if id==NativeGallery114.hoverId and now-NativeGallery114.hoverAt<430 then
                    local st=Preview101.stage
                    if st and now-st.at<900 then
                        local okHover=pcall(GTA.DrawPedPreview,slot.cped,
                            V2.New((st.x+st.w*.5)/st.sw,(st.y+st.h*.5)/st.sh),
                            V2.New(math.min(.60,math.max(.30,st.w/st.sw)),
                                   math.min(.94,math.max(.58,st.h/st.sh))),
                            -5.3,0,yaw,1.0)
                        if okHover then slot.hoverDrawnAt=now end
                    end
                end
                end -- validated typed CPed address
            end
            end -- verified ownership before local preview render
        end
    end
    if not NativeGallery114.skippedLog and attempted>0 and drawn==0 and culled==attempted then
        NativeGallery114.skippedLog=true
        log("[MV115][LOCAL][VISIBILITY] All ready cards culled; verify gallery scroll position/window coordinates")
    end
end
-- The menu's opaque ImGui panels can cover previews submitted in a
-- Script.QueueJob before the frame's final UI composition. Move drawing to
-- the latest exposed present callback, retaining a native-thread fallback.
-- This remains experimental: DrawPedPreview is not an ImGui foreground texture.
local function native114InstallTopmost()
    if NativeGallery114.postHandler or NativeGallery114.postFailed then return end
    if not (EventMgr and type(EventMgr.RegisterHandler)=="function"
        and eLuaEvent and eLuaEvent.ON_POST_PRESENT) then
        NativeGallery114.postFailed=true
        log("[MV115][LOCAL][LAYER] ON_POST_PRESENT unavailable; native-thread fallback")
        return
    end
    local ok,handler=pcall(EventMgr.RegisterHandler,eLuaEvent.ON_POST_PRESENT,function()
        if not NativeGallery114.enabled or not NativeGallery114.pageKey then return end
        -- A post-present callback can be after the actual swap. Use it as
        -- an additional experimental layer probe at a limited cadence, not
        -- the only rendering path. The last UI pass is the primary path.
        if nowMs()-NativeGallery114.postLastDraw<85 then return end
        NativeGallery114.postLastDraw=nowMs()
        local okRender,err=pcall(native114RenderFrame,"post-present")
        if okRender then
            NativeGallery114.lastPost=nowMs()
            NativeGallery114.postCount=NativeGallery114.postCount+1
            if not NativeGallery114.layerNotice then
                NativeGallery114.layerNotice=true
                log("[MV115][LOCAL][LAYER] ON_POST_PRESENT active, requesting highest available native PED layer")
            end
        elseif not NativeGallery114.postFailed then
            NativeGallery114.postFailed=true
            log("[MV115][LOCAL][LAYER] Post-present render failed: "..tostring(err).."; using native job fallback")
        end
    end)
    if ok and handler then
        NativeGallery114.postHandler=handler
        NativeGallery114.postEnabled=true
        log("[MV115][LOCAL][LAYER] ON_POST_PRESENT handler registered")
    else
        NativeGallery114.postFailed=true
        log("[MV115][LOCAL][LAYER] Post-present registration failed: "..tostring(handler))
    end
end
local function native114StartRender()
    if NativeGallery114.renderJob or not (Script and Script.QueueJob) then return end
    NativeGallery114.renderJob=true
    Script.QueueJob(function()
        while NativeGallery114.enabled and NativeGallery114.pageKey do
            -- Never submit duplicate draws when the top-layer callback runs.
            if nowMs()-NativeGallery114.lastUIPass>800
                and (NativeGallery114.postFailed or nowMs()-NativeGallery114.lastPost>800) then
                local ok,err=pcall(native114RenderFrame,"native-fallback")
                if not ok and not NativeGallery114.warned then
                    NativeGallery114.warned=true
                    log("[MV115][LOCAL][RENDER] Job exception: "..tostring(err))
                end
            end
            Script.Yield(25) -- do not busy-spin behind the foreground gallery
        end
        NativeGallery114.renderJob=false
    end)
end

local function native114Prepare(visible,model)
    NativeGallery114.lastUI=nowMs()
    local actual,ped=mv101Player()
    if actual~=model or not model or not exists098(ped) then
        if NativeGallery114.pageKey then native114Release("local PED unavailable") end
        NativeGallery114.report="Local PED unavailable"
        return
    end
    local parts={tostring(model),tostring(ped)}
    for _,it in ipairs(visible) do parts[#parts+1]=it.filename..":"..tostring(it.sha) end
    local key=table.concat(parts,"|")
    if NativeGallery114.pageKey==key then return end
    native114Release("page or saved Outfit changed")
    if not NativeGallery114.enabled or not GTA or type(GTA.DrawPedPreview)~="function" then
        NativeGallery114.report="Native previews disabled/unavailable"
        return
    end
    NativeGallery114.pageKey=key
    native114InstallTopmost()
    NativeGallery114.sourcePed=ped
    NativeGallery114.sourceModel=model
    local gen=NativeGallery114.generation
    for _,it in ipairs(visible) do
        local slot={it=it,status="queued",ped=0,cped=nil,lastResolve=0}
        NativeGallery114.slots[it.filename]=slot
        NativeGallery114.order[#NativeGallery114.order+1]=it.filename
    end
    NativeGallery114.report="Dressing native PED cards"
    if #visible==0 then return end
    NativeGallery114.busy=true
    Script.QueueJob(function()
        for i,id in ipairs(NativeGallery114.order) do
            if gen~=NativeGallery114.generation or not NativeGallery114.enabled then break end
            local slot=NativeGallery114.slots[id]
            if slot then
                local ok,err=pcall(native114CreateSlot,slot,ped,model,gen,i)
                if not ok then
                    slot.status="clone error"
                    log("[MV114][LOCAL][CLONE] "..tostring(id).." | "..tostring(err))
                end
            end
            Script.Yield(25) -- release the GTA thread between spawns
        end
        if gen==NativeGallery114.generation then
            NativeGallery114.busy=false
            local ready=0
            for _,id in ipairs(NativeGallery114.order) do
                if NativeGallery114.slots[id] and NativeGallery114.slots[id].status=="ready" then ready=ready+1 end
            end
            NativeGallery114.report="Native previews ready: "..ready.."/"..#NativeGallery114.order
            log("[MV115][LOCAL][READY] "..NativeGallery114.report..
                " | top-layer="..tostring(NativeGallery114.postEnabled)..
                " | open-gallery="..tostring(NativeGallery114.pageKey~=nil))
        end
    end)
    native114StartRender()
end

function NativeGallery114.tick()
    if not NativeGallery114.pageKey then return end
    if nowMs()-NativeGallery114.lastUI>1700 then
        native114Release("Local tab not visible")
        return
    end
    local model,ped=mv101Player()
    if model~=NativeGallery114.sourceModel or ped~=NativeGallery114.sourcePed then
        native114Release("local PED model/handle changed")
    end
end

local function native114LocalCard(it,width)
    local imageH=math.max(94,math.min(132,math.floor(width*0.79)))
    local tileH=imageH+32
    ImGui.PushID("MV114LocalTile_"..it.filename)
    local x,y=cursorScreenPos()
    local clicked=ImGui.InvisibleButton("##MV114LocalCard",width,tileH)
    local hovered=ImGui.IsItemHovered()
    drawImageCardBackground(x,y,width,tileH,hovered,Snatcher108.selected==it.filename)
    local slot=NativeGallery114.slots[it.filename]
    local ready=NativeGallery114.enabled and slot and slot.status=="ready" and slot.cped
    -- Clipping is handled by the final render pass using card-center visibility.
    -- Do not blank an otherwise ready card for touching a child-window edge.
    local photo=nil
    -- Keep any existing genuine local JPGs. Never create new JPGs here.
    local path=snatchDir108.."Thumbnails\\"..it.filename:gsub("%.json$","").."_"..it.sha:sub(1,12)..".jpg"
    if fileExists(path) and detectImageFile(path)=="jpg" then photo=textureSrv(path) end
    if not ready and photo then
        if ImGui.AddImageRounded then
            ImGui.AddImageRounded(photo,x+3,y+3,x+width-3,y+imageH,0,0,1,1,0xFFFFFFFF,6)
        else ImGui.AddImage(photo,x+3,y+3,x+width-3,y+imageH) end
    else
        ImGui.AddRectFilled(x+3,y+3,x+width-3,y+imageH,22,25,39,255,6)
        ImGui.AddRectFilled(x+4,y+4,x+9,y+imageH-1,154,87,240,255,3)
        -- Keep the live area empty so PED rendering remains unobstructed.
        if not ready then
            ImGui.AddText(x+15,y+27,"PREVIEW",238,225,255,255)
            local status=slot and slot.status or "Preparing..."
            ImGui.AddText(x+15,y+53,shortText(status,math.max(15,math.floor(width/10))),175,165,215,255)
        end
    end
    -- The native render job uses these rectangle positions, not a screenshot.
    NativeGallery114.positions[it.filename]={x=x+8,y=y+9,w=width-16,h=imageH-15,at=nowMs()}
    ImGui.AddRectFilled(x+3,y+imageH,x+width-3,y+tileH-3,15,17,28,250)
    ImGui.AddText(x+8,y+imageH+7,shortText(it.name,math.max(10,math.floor((width-18)/7.4))),248,246,255,255)
    local starX,starY=x+8,y+8
    local mx,my=readVec2(function() return ImGui.GetMousePos() end,-9999,-9999)
    local overStar=hovered and mx>=starX and mx<starX+31 and my>=starY and my<starY+31
    local pressed=false
    if ImGui.IsMouseClicked then
        local ok,v=pcall(ImGui.IsMouseClicked,0);pressed=ok and (v==true or v==1)
    end
    if overStar and pressed then C.starPressedId=it.id end
    local released=false
    if ImGui.IsMouseReleased then
        local ok,v=pcall(ImGui.IsMouseReleased,0);released=ok and (v==true or v==1)
    end
    if released and C.starPressedId==it.id then
        if overStar then C.favorite("outfits",it.id) end
        clicked=false
    end
    if overStar then clicked=false end
    ImGui.AddRectFilled(starX,starY,starX+31,starY+31,21,18,35,232,6)
    local fav=C.isFavorite("outfits",it.id)
    ImGui.AddText(starX+7,starY+5,fav and "★" or "☆",fav and 255 or 231,fav and 205 or 219,fav and 60 or 236,255)
    if hovered and not overStar then
        NativeGallery114.hoverWait={id=it.filename,at=nowMs()}
        if ready then
            NativeGallery114.hoverId=it.filename
            NativeGallery114.hoverAt=nowMs()
        end
    end
    if clicked then
        -- Build 127: do not equip, reset, or copy on thumbnail click.
        -- The explicit Install to Cherax button is the only install action.
        Snatcher108.selected=it.filename
    end
    if hovered and ImGui.BeginTooltip then
        ImGui.BeginTooltip()
        ImGui.Text("Local capture: "..shortText(it.name,80))
        if slot and slot.hasAttachments then ImGui.Text("Attachments: use Cherax loader") end
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end

function NativeGallery114.draw(visible,currentModel)
    local screenW,screenH=readVec2(function() return ImGui.GetDisplaySize() end,1920,1080)
    if screenW and screenH and screenW>0 and screenH>0 then
        NativeGallery114.displayW,NativeGallery114.displayH=screenW,screenH
    end
    if ModVerseProd118.details.outfits then
        if ImGui.Button(NativeGallery114.enabled and "Live Previews: ON##MV114" or "Live Previews: OFF##MV114",170,24) then
            NativeGallery114.enabled=not NativeGallery114.enabled
            native114Release("toggle switched")
        end
    end
    -- Technical render limits belong in Details, not the everyday gallery.
    if #visible==0 then ImGui.TextWrapped("No compatible Local outfits saved yet. Try Scan Session Now.") end
    ImGui.Separator()
    if NativeGallery114.enabled then native114Prepare(visible,currentModel) end
    local _,h=contentAvail()
    if ImGui.BeginChild then ImGui.BeginChild("MV115LocalGalleryScroll",0,math.max(180,math.min(480,(h or 0)-8)),true) end
    local cx,cy=readVec2(function() return ImGui.GetWindowPos() end,-1,-1)
    local cw,ch=readVec2(function() return ImGui.GetWindowSize() end,-1,-1)
    if cx>=0 and cy>=0 and cw>100 and ch>100 then
        NativeGallery114.clip={x=cx,y=cy,w=cw,h=ch}
    else NativeGallery114.clip=nil end
    -- Keep previous-frame positions until updated. The post-present callback
    -- may run between the UI layout and its next draw pass.
    local w=select(1,contentAvail())
    local cols=math.max(2,math.min(4,math.floor(w/154)))
    local tileWidth=math.max(124,(w-(cols-1)*8)/cols-7)
    if ImGui.BeginTable("MV115LocalPedCards",cols,ImGuiTableFlags.SizingStretchSame) then
        for _,it in ipairs(visible) do ImGui.TableNextColumn();native114LocalCard(it,tileWidth) end
        ImGui.EndTable()
    end
    if ImGui.IsMouseReleased then
        local ok,v=pcall(ImGui.IsMouseReleased,0)
        if ok and (v==true or v==1) then C.starPressedId=nil end
    end
    if ImGui.EndChild then ImGui.EndChild() end
    if Preview101.enabled then Preview101.layout() end
    if ModVerseProd118.details.outfits and NativeGallery114.report~="" then
        ImGui.Text(shortText(NativeGallery114.report,90))
        ImGui.Text("PED layer: "..(NativeGallery114.postCount>0 and "post-present" or "fallback")..
            " | draws: "..tostring(NativeGallery114.drawCalls))
    end
    -- Draw after ALL card backgrounds, names and controls have been queued.
    -- This is the last accessible point in Cherax's ON_PRESENT UI callback.
    -- Unlike Build 114's native-thread job, card positions are from this frame.
    if NativeGallery114.enabled then
        NativeGallery114.lastUIPass=nowMs()
        local ok,err=pcall(native114RenderFrame,"last-ui-pass")
        if not ok and not NativeGallery114.warned then
            NativeGallery114.warned=true
            log("[MV115][LOCAL][LAYER] Last UI pass failed: "..tostring(err))
        end
    end
end
function C.renderLocalOutfits()
    snatchLoad108()
    ImGui.TextColored(.80,.58,1,1,"Local Outfits")
    local currentModel=playerModel098()
    local compatibleCount=0
    for _,row in ipairs(Snatcher108.rows) do
        if currentModel and snatchEntryModel112(row)==currentModel then compatibleCount=compatibleCount+1 end
    end
    ImGui.SameLine();ImGui.Text(tostring(compatibleCount).." compatible")
    if ImGui.Button((Snatcher108.enabled and "Auto-Save: ON" or "Auto-Save: OFF").."##MV117OutfitAuto",135,25) then
        Snatcher108.enabled=not Snatcher108.enabled
        if Snatcher108.enabled then Snatcher108.nextScan=0 end
        log("[MV117][OUTFITS] Auto-Save Player Outfits "..(Snatcher108.enabled and "ON" or "OFF"))
    end
    ImGui.SameLine()
    if ImGui.Button("Scan Now##MV109",110,25) then Snatcher108.nextScan=nowMs()+6500;Snatcher108.scan(true,"outfits") end
    local outfitDetails=productionDetails118("outfits","Details",100)
    if outfitDetails then
        ImGui.Text("Current PED: "..gender098(currentModel).." / "..tostring(currentModel or "unknown"))
        ImGui.TextWrapped("Scanner: "..Snatcher108.diagnostic)
        ImGui.TextWrapped("Captures only players with your exact PED model. Native template supplies schema fields, not the other player's facial appearance. For another model, first save a native Outfit in Cherax.")
        if ImGui.Button("Refresh native Outfit template##MV112",235,24) then
            snatchTemplates112={}
            Snatcher108.seen={}
            Snatcher108.lastError=""
            toast("Native Outfit templates refreshed; scan again",2700)
        end
        ImGui.Text("Folder: Cherax\\Outfits\\Local")
    end
    -- Local Outfit gallery shares the keyboard/focus-safe search controls.
    if mv145CheraxSearch("LocalOutfits",Snatcher108,"query") then Snatcher108.page=1 end
    local found={}
    for i=#Snatcher108.rows,1,-1 do
        local it=Snatcher108.rows[i]
        if currentModel and snatchEntryModel112(it)==currentModel and
            (Snatcher108.query=="" or it.name:lower():find(Snatcher108.query:lower(),1,true)
            or it.filename:lower():find(Snatcher108.query:lower(),1,true)) then found[#found+1]=it end
    end
    if MV122Filters.bar('localoutfits','localoutfits') then Snatcher108.page=1 end
    local filtered={}
    local fs=MV122Filters.state('localoutfits')
    for _,it in ipairs(found) do
        if MV122Filters.keep(it,'localoutfits','localoutfits',false,fs.show==2 and C.isFavorite('outfits',it.id)) then
            filtered[#filtered+1]=it
        end
    end
    found=MV122Filters.order(filtered,'localoutfits')
    -- Build 113: preserve the underlying Build 112 scanner, template, and model filtering.
    local perPage=6
    local pages=math.max(1,math.ceil(#found/perPage))
    Snatcher108.page=math.max(1,math.min(Snatcher108.page,pages))
    if ImGui.Button("< Prev##MV113Local",90,24) then Snatcher108.page=math.max(1,Snatcher108.page-1) end
    ImGui.SameLine();ImGui.Text("Page "..Snatcher108.page.."/"..pages.." ("..#found.." compatible)")
    ImGui.SameLine();if ImGui.Button("Next >##MV113Local",90,24) then Snatcher108.page=math.min(pages,Snatcher108.page+1) end
    if Snatcher108.lastError~="" then ImGui.TextColored(1,.66,.40,1,shortText(Snatcher108.lastError,105)) end
    local localFilter=MV122Filters.state('localoutfits')
    local key="local:"..tostring(Snatcher108.page)..":"..Snatcher108.query..":"..tostring(currentModel)..":"..localFilter.sort..":"..localFilter.show
    if Preview098.activePageKey~=key then
        if Preview098.activePageKey then Preview101.stop("Local Outfit page changed") end
        native114Release("Local Outfit page changed")
        Preview098.clearPage("Local Outfit page changed")
        Preview098.activePageKey=key
    end
    Preview098.lastPageRender=nowMs()
    local g=group("outfits")
    local visible={}
    local first=(Snatcher108.page-1)*perPage+1
    for i=first,math.min(#found,first+perPage-1) do visible[#visible+1]=found[i] end
    NativeGallery114.draw(visible,currentModel)
    if Snatcher108.selected then
        local selected
        for _,it in ipairs(Snatcher108.rows) do
            if it.filename==Snatcher108.selected then selected=it;break end
        end
        if selected then
            ImGui.Separator()
            ImGui.Text("Selected: "..shortText(selected.name,66))
            if outfitDetails and ImGui.Button("Repair JSON (new copy)##MV112",190,27) then
                local path=(selected.legacy and snatchLegacyDir110 or snatchDir108)..selected.filename
                local raw=ModVerseHash152.read(path)
                if type(raw)~="string" or ModVerseHash152.sha256(raw)~=selected.sha then
                    toast("Cannot repair: original JSON SHA-256 mismatch",3500)
                else
                    local doc,why=snatchLocalDoc108(selected)
                    local current=playerModel098()
                    if not doc then toast(tostring(why),3500)
                    elseif norm098(doc.model)~=current then toast("Only repair outfits for your current PED model",3500)
                    else
                        local template,reason=snatchTemplate112(current)
                        if not template then toast(tostring(reason),5000)
                        else
                            local changed=false
                            if not snatchInt111(doc.baseFlags,0,4294967295) then
                                local n=raw:gsub('("model"%s*:%s*%d+)', '%1,"baseFlags":'..template.flags,1)
                                if n~=raw then raw=n;changed=true end
                            end
                            if type(doc.face_features)~="table" then
                                local n=raw:gsub('}%s*$',',"face_features":'..template.face..'}',1)
                                if n~=raw then raw=n;changed=true end
                            end
                            if not changed then toast("Selected Outfit already has native schema fields",3300)
                            else
                                local okParse,repaired=pcall(ModVerseCommunity078.decodeJson,raw)
                                if not okParse or type(repaired)~="table" or repaired.format~="Cherax Entity"
                                    or repaired.type~=2 or norm098(repaired.model)~=current then
                                    toast("Repair validation failed; original preserved",4000)
                                else
                                    local saved,msg=snatchAdd108(selected.name,raw)
                                    if saved then toast("New native-compatible copy saved: "..tostring(msg),4400)
                                    else toast("Repair not saved: "..tostring(msg),3700) end
                                end
                            end
                        end
                    end
                end
            end
            if ImGui.Button("Install to Cherax##MV127",240,28) then
                local path=(selected.legacy and snatchLegacyDir110 or snatchDir108)..selected.filename
                local raw=ModVerseHash152.read(path)
                if type(raw)~="string" or ModVerseHash152.sha256(raw)~=selected.sha then
                    toast("Cannot copy: local Outfit SHA-256 mismatch",3500)
                else
                    local parsed,doc=pcall(ModVerseCommunity078.decodeJson,raw)
                    if not parsed or type(doc)~="table" or not snatchInt111(doc.baseFlags,0,4294967295)
                        or type(doc.face_features)~="table" then
                        toast("Legacy partial file: repair as a new copy first",4300)
                    else
                    local target=MENU_ROOT.."\\Outfits\\"..selected.filename
                    if fileExists(target) then
                        local existing=ModVerseHash152.read(target)
                        if type(existing)=="string" and ModVerseHash152.sha256(existing)==selected.sha then
                            toast("Already installed. Load it from Cherax Outfits.",4200)
                        else
                            toast("Another Outfit uses this filename. No overwrite.",4200)
                        end
                    elseif not writeBinary(target..".part",raw) then
                        toast("Unable to stage native Cherax Outfit",3500)
                    elseif ModVerseHash152.sha256(ModVerseHash152.read(target..".part") or "")~=selected.sha then
                        os.remove(target..".part")
                        toast("Cannot install: staged Outfit failed SHA-256",4000)
                    elseif not os.rename(target..".part",target) then
                        os.remove(target..".part")
                        toast("Unable to finalize native Cherax Outfit",3500)
                    else
                        toast("Outfit copied. Load it using Cherax's native Outfit loader.",4800)
                    end
                    end -- native-compatible schema required
                end
            end
            if outfitDetails then
                ImGui.TextWrapped("Cards only select and preview. Install to Cherax copies the original verified JSON without equipping it. Load all outfits, including costumes with attachments, through Cherax's native Outfits menu.")
            end
        end
    end
    Preview101.layout()
    Preview101.drawPanel()
end
-- Keep a tested no-op terminator to avoid injecting accidental scope changes.
-- Build 094: a real thumbnail must depict the actual asset and be published
-- with a matching SHA-256. When an outfit/DLC has no screenshot, show a clear
-- colorful *catalog card* instead of a misleading blank tile or fake photo.
-- These cards are generated in ImGui without HTTP, disk writes, or textures.
local function mv094DrawCatalogCard(g,it,x,y,width,imageH)
    imageH=imageH or 114
    local ident=tostring(it.id or it.sha or "asset")
    local hash=5381
    for i=1,#ident do hash=(hash*33+ident:byte(i))%4294967296 end
    local accents={
        {161,91,246},{42,179,215},{244,123,87},{230,84,172},
        {94,196,137},{238,181,65},{105,139,247},{220,107,128}
    }
    local a=accents[(hash%#accents)+1]
    local px,py,rx,ry=x+3,y+3,x+width-3,y+imageH
    ImGui.AddRectFilled(px,py,rx,ry,24,27,40,255,6)
    ImGui.AddRectFilled(px+2,py+2,px+8,ry-2,a[1],a[2],a[3],255,2)
    ImGui.AddRectFilled(rx-61,py+2,rx-3,ry-2,32,35,51,255,4)
    if width>=230 and g.kind=="outfits" then
        ImGui.AddRectFilled(rx-39,py+17,rx-26,py+30,a[1],a[2],a[3],240,6)
        ImGui.AddRectFilled(rx-44,py+34,rx-21,py+62,a[1],a[2],a[3],215,5)
        ImGui.AddRectFilled(rx-43,py+64,rx-35,py+85,a[1],a[2],a[3],210,2)
        ImGui.AddRectFilled(rx-30,py+64,rx-22,py+85,a[1],a[2],a[3],210,2)
    elseif width>=230 then
        ImGui.AddRectFilled(rx-53,py+53,rx-11,py+71,a[1],a[2],a[3],220,5)
        ImGui.AddRectFilled(rx-44,py+43,rx-20,py+56,a[1],a[2],a[3],210,5)
        ImGui.AddRectFilled(rx-45,py+69,rx-35,py+79,15,17,26,255,5)
        ImGui.AddRectFilled(rx-23,py+69,rx-13,py+79,15,17,26,255,5)
    end
    local category=g.kind=="outfits" and "OUTFIT" or "CHERAX DLC"
    ImGui.AddText(px+15,py+12,category,220,204,252,255)
    ImGui.AddText(px+15,py+40,"CATALOG CARD",a[1],a[2],a[3],255)
    ImGui.AddText(px+15,py+65,"Preview not published",178,187,205,255)
    ImGui.AddText(px+15,py+85,"for this entry",151,163,187,255)
end
-- Build 104: all current Outfit catalog creator names are explicitly marked
-- "Original developer unverified". Never misattribute their Discord uploaders as
-- the authors. Show a verified creator when available, otherwise show Unknown
-- followed by the real "Shared By" credit from the marketplace catalog.
local function mv104HoverCredits(it)
    local creator=type(it.creator)=="string" and it.creator or ""
    creator=creator:gsub("^%s+",""):gsub("%s+$","")
    local low=creator:lower()
    if creator=="" or low=="unknown" or low=="n/a" or low=="unverified"
        or low:find("unverified",1,true) or low:find("unknown",1,true) then
        local shared=type(it.shared_by)=="string" and it.shared_by or ""
        shared=shared:gsub("^%s+",""):gsub("%s+$","")
        return "Unknown",(shared~="" and shared or nil)
    end
    return creator,nil
end
-- Build 103: show the EXACT published GitHub .jpg as the card artwork.
-- It can be a catalog cover or an original photograph; both are images.
-- File SHA256 and JPEG magic are verified by fetchVisiblePreviews096 before
-- assigning a texture. This view never uses the experimental ped renderer.
local function itemTile(g,it,width)
    local imageH=g.kind=="dlcs" and math.max(76,math.min(118,math.floor(width*0.57)))
        or math.max(91,math.min(166,math.floor(width*9/16)))
    local tileH=imageH+33
    ImGui.PushID("MV103ImageTile_"..g.kind.."_"..it.id)
    local x,y=cursorScreenPos()
    local clicked=ImGui.InvisibleButton("##asset",width,tileH)
    local hovered=ImGui.IsItemHovered()
    drawImageCardBackground(x,y,width,tileH,hovered,g.selected==it)
    local srv=it.thumbStatus=="ready" and textureSrv(it.preview) or nil
    if srv then
        if ImGui.AddImageRounded then
            ImGui.AddImageRounded(srv,x+3,y+3,x+width-3,y+imageH,0,0,1,1,0xFFFFFFFF,6.0)
        else
            ImGui.AddImage(srv,x+3,y+3,x+width-3,y+imageH)
        end
    else
        ImGui.AddRectFilled(x+3,y+3,x+width-3,y+imageH,30,32,46,255,6)
        local message=it.thumbStatus=="failed" and "IMAGE UNAVAILABLE"
            or it.thumbURL and "LOADING JPG..." or "NO PUBLISHED JPG"
        ImGui.AddText(x+11,y+math.max(20,math.floor(imageH/2)-9),message,201,194,219,255)
    end
    -- One compact name strip, no debug text obscuring the image.
    ImGui.AddRectFilled(x+3,y+imageH,x+width-3,y+tileH-3,16,18,27,250)
    local chars=math.max(10,math.floor((width-18)/7.4))
    ImGui.AddText(x+8,y+imageH+7,shortText(it.name,chars),248,247,255,255)
    if C.installed(g.kind,it) then
        ImGui.AddRectFilled(x+width-16,y+imageH+12,x+width-9,y+imageH+19,60,220,125,255,3)
    end
    if hovered and g.kind=="outfits" and Preview101.enabled then Preview101.hover(g,it) end
    if g.kind=="dlcs" and C.cardStar123("dlcs",it.id,x,y,hovered) then
        clicked=false
    end
    if g.kind=="outfits" then
        -- Build 108: favorite star uses the existing card's mouse hit test.
        -- NEVER SetCursorScreenPos inside an ImGui table cell: that extends
        -- table boundaries and causes the [imgui-error] reported in Build 106.
        local starX,starY=x+8,y+8
        local mx,my=readVec2(function() return ImGui.GetMousePos() end,-9999,-9999)
        local overStar=hovered and mx>=starX and mx<starX+31 and my>=starY and my<starY+31
        local pressing=false
        if ImGui.IsMouseClicked then
            local ok,v=pcall(ImGui.IsMouseClicked,0)
            pressing=ok and (v==true or v==1)
        end
        if overStar and pressing then C.starPressedId=it.id end
        local released=false
        if ImGui.IsMouseReleased then
            local ok,v=pcall(ImGui.IsMouseReleased,0)
            released=ok and (v==true or v==1)
        end
        if released then
            if overStar and C.starPressedId==it.id then
                C.favorite("outfits",it.id)
                clicked=false
            end
            -- Releasing anywhere after pressing the star must never install.
            if C.starPressedId==it.id then clicked=false end
            -- Clear the capture only after ALL card cells have processed this
            -- mouse-release frame. Otherwise the first card swallows a click
            -- on a star in another column.
        end
        if overStar then clicked=false end
        ImGui.AddRectFilled(starX,starY,starX+31,starY+31,21,18,35,232,6)
        local fav=C.isFavorite("outfits",it.id)
        ImGui.AddText(starX+7,starY+5,fav and "★" or "☆",fav and 255 or 231,fav and 205 or 219,fav and 60 or 236,255)
    end
    if clicked then
        -- Build 127: selection must never download, install or modify the player PED.
        g.selected=it
    end
    if hovered and ImGui.BeginTooltip then
        ImGui.BeginTooltip()
        ImGui.Text(shortText(it.name,90))
        -- Build 108: one short credit label. Current marketplace entries credit
        -- their Discord uploader, not a verified original artist. Attribution
        -- basis remains available in catalog metadata.
        local creator=it.creator or ""
        local uploader=it.shared_by or ""
        local who=(creator~="" and not creator:lower():find("unverified",1,true)) and creator
            or (uploader~="" and uploader or "Unknown")
        ImGui.Text("Made By: "..shortText(who,100))
        if it.thumbStatus=="failed" then ImGui.Text("Load error: "..shortText(it.thumbError or "unknown",90)) end
        ImGui.EndTooltip()
    end
    ImGui.PopID()
end
function C.renderCategory(kind,options)
    if kind=="outfits" and C.OutfitNativeGallery114 and C.OutfitNativeGallery114.pageKey then
        C.OutfitNativeGallery114.stop("Marketplace Outfits opened")
    end
    local g=group(kind)
    options=options or {}
    if not g.loaded and not g.loading then refresh(g,false) end
    local label=kind=="outfits" and "Outfits" or "Cherax DLCs"
    if kind=="dlcs" and (Preview098.ped~=0 or Preview098.busy) then Preview098.stop("Switched away from Outfit preview") end
    if kind=="dlcs" and (Preview101.visible or Preview101.clone~=0 or Preview101.queued or Preview101.wantedId) then Preview101.stop("DLCs opened") end
    if kind=="dlcs" and Preview098.activePageKey then
        Preview098.clearPage("Switched to DLCs")
        local og=C.groups.outfits
        if og then og.previewPageKey=nil end
    end
    ImGui.TextColored(0.78,0.55,1,1,label)
    ImGui.SameLine()
    if ImGui.Button("Refresh GitHub##MV090"..kind,132,26) then
        if kind=="outfits" then
            Preview101.verifyFailures={}
            Preview101.stop("Refreshing Outfit catalog")
            Preview098.clearPage("GitHub Refresh")
            g.previewPageKey=nil
        end
        refresh(g,true)
    end
    if (g.previewStats.failed or 0)>0 or ModVerseProd118.details.marketplace then
        ImGui.SameLine()
        if ImGui.Button("Retry Images##MV096"..kind,123,26) then
            if g.previewBusy then toast("Thumbnail batch is still loading",2200)
            elseif retryFailedPreviews096(g) then toast("Retrying failed images",2700)
            else toast("No failed images",2300) end
        end
    end
    if kind=="outfits" and ModVerseProd118.details.marketplace then
        local pv=Preview101
        if ImGui.Button(pv.enabled and "3D Hover: ON##MV106" or "3D Hover: OFF##MV106",133,24) then
            pv.enabled=not pv.enabled
            if not pv.enabled then
                pv.stop("3D hover disabled")
                Preview098.clearPage("3D hover disabled")
                g.previewPageKey=nil
            end
        end
    end
    if g.loading or g.previewBusy then ImGui.TextColored(.62,.78,.95,1, "Loading...")
    elseif tostring(g.status or ""):lower():find("error",1,true) then
        ImGui.TextColored(1,.55,.41,1,shortText(g.status,115)) end
    if productionDetails118("marketplace","Info",82) then
        local pv=g.previewStats
        ImGui.Text("Status: "..shortText(g.status,118))
        ImGui.Text("Verified JPGs: "..tostring(pv.disk).." cached | "..tostring(pv.downloaded).." fetched | "..tostring(pv.failed).." failed")
        ImGui.TextWrapped("Catalog art is a fallback, not an in-game screenshot. Outfit preview data is temporary and never installed on hover.")
    end
    -- Build 145: avoid resetting thumbnail/PED preview on every typed key.
    if mv145CheraxSearch("Marketplace_"..kind,g,"search") then g.page=1 end
    local filterKey='market_'..kind
    if MV122Filters.bar(filterKey,kind) then g.page=1 end
    local f=MV122Filters.state(filterKey)
    -- Image catalogs can contain thousands of outfits. Reuse an unchanged
    -- sorted/filter list across frames to keep the FPS cost close to Build 121.
    -- Dynamic favorites/installed views always use fresh membership checks.
    local cacheable=f.show==1 and not options.favorites and not options.installed
    local memoKey=cacheable and table.concat({tostring(g.items),tostring(g.search),
        tostring(f.sort),tostring(f.extra)},'|') or nil
    local memo=cacheable and MV122Filters.catalogMemo[filterKey] or nil
    local items
    if memo and memo.key==memoKey then
        items=memo.items
    else
        local source=listItems(g,options.favorites,options.installed)
        local retained={}
        for _,it in ipairs(source) do
            local installed=f.show>=3 and C.installed(kind,it) or false
            local favorite=f.show==2 and C.isFavorite(kind,it.id) or false
            if MV122Filters.keep(it,filterKey,kind,installed,favorite) then retained[#retained+1]=it end
        end
        items=MV122Filters.order(retained,filterKey)
        if cacheable then MV122Filters.catalogMemo[filterKey]={key=memoKey,items=items} end
    end
    local pages=math.max(1,math.ceil(#items/g.perPage))
    g.page=math.max(1,math.min(pages,g.page))
    if ImGui.Button("< Prev##MV090"..kind,85,24) then g.page=math.max(1,g.page-1) end
    ImGui.SameLine();ImGui.Text("Page "..g.page.."/"..pages.." | "..#items.." "..kind)
    ImGui.SameLine()
    if ImGui.Button("Next >##MV090"..kind,85,24) then g.page=math.min(pages,g.page+1) end
    if kind=="outfits" and Preview101.enabled then
        if type(Preview098.activePageKey)=="string"
            and Preview098.activePageKey:sub(1,5)=="local" then
            Preview101.stop("Local tab closed")
            Preview098.clearPage("Returning to marketplace Outfits")
            g.previewPageKey=nil
        end
        local f=MV122Filters.state('market_outfits')
        local key=tostring(g.page)..":"..tostring(g.search)..":"..tostring(options.favorites or false)..":"..tostring(options.installed or false)..":"..f.sort..":"..f.show..":"..f.extra
        if g.previewPageKey~=key then
            if g.previewPageKey then Preview101.stop("Page changed; hover an outfit") end
            Preview098.clearPage("Outfit page/filter switched")
            g.previewPageKey=key
            Preview098.activePageKey=key
        end
    end
    ImGui.Separator()
    -- Build 149: after choosing a Cherax DLC card, render its selected-item
    -- download panel BELOW the gallery where the user is looking. This invokes
    -- the existing Cherax Curl + SHA-256 + RPF7 installer, never a native DLL.
    local function renderSelectedPanel149()
        local selected=g.selected
        if selected then
            ImGui.Text("Selected: "..shortText(selected.name,48))
            local actionLabel=(kind=="dlcs" and
                (C.installed(kind,selected) and "Verify Installed DLC##MV149" or "Download & Install Selected DLC##MV149")
                or ("Download & Install##MV090"..kind))
            if g.busy then actionLabel="Downloading...##MV149"..kind end
            if ImGui.Button(actionLabel,kind=="dlcs" and 252 or 192,32) and not g.busy then
                downloadItem(g,selected)
            end

            if C.installed(kind,selected) then ImGui.SameLine();ImGui.TextColored(0.5,0.9,0.55,1,"Installed") end
            if kind=="outfits" then ImGui.TextColored(.65,.67,.75,1,"Install only. Load the outfit from Cherax > Outfits.") end
            if selected.status and selected.status~="Ready" and selected.status~="" then
                ImGui.Text(shortText(selected.status,100))
            end
            if ImGui.TreeNode and ImGui.TreeNode("Details & destination##MV090"..kind) then
                -- Same Cherax JPG texture renderer as the card grid, enlarged in details.
                local largeSrv=selected.thumbStatus=="ready" and textureSrv(selected.preview) or nil
                if largeSrv and ImGui.Dummy then
                    local px,py=cursorScreenPos()
                    ImGui.Dummy(284,160)
                    if ImGui.AddImageRounded then
                        ImGui.AddImageRounded(largeSrv,px,py,px+284,py+160,0,0,1,1,0xFFFFFFFF,6.0)
                    else ImGui.AddImage(largeSrv,px,py,px+284,py+160) end
                end
                local known=selected.creator or ""
                local credit=(known~="" and not known:lower():find("unverified",1,true)) and known
                    or (selected.shared_by~="" and selected.shared_by or "Unknown")
                ImGui.Text("Made By: "..shortText(credit,48))
                ImGui.Text("Install: "..shortText(destination(kind,selected),140))
                ImGui.Text(string.format("%.2f MiB | SHA256: %s",selected.size/1048576,selected.sha:sub(1,24).."..."))
                if not selected.thumbURL then
                    safeTextWrapped("Preview is a metadata-only catalog card, NOT a screenshot of the actual GTA asset.")
                    safeTextWrapped("To publish a real preview: upload a JPG named <id>.jpg under marketplace/"..kind.."/thumbnails/ and set thumbnail_sha256 in its catalog entry.")
                    if ImGui.Button("Copy thumbnail ID##MV094"..kind,161,23) then
                        pcall(function() Utils.SetClipBoardText(tostring(selected.id)..".jpg","") end)
                        toast("Thumbnail filename copied",2000)
                    end
                else
                    ImGui.Text("Thumbnail SHA256: "..tostring(selected.thumbSha):sub(1,24).."...")
                    local imageType=selected.thumbKind=="catalog_cover" and "Catalog artwork (not an in-game screenshot)"
                        or selected.thumbKind=="gameplay_screenshot" and "Real GTA screenshot"
                        or selected.thumbKind=="source_image" and "Original source photo, not gameplay verified"
                        or "Image type not specified"
                    safeTextWrapped(imageType)
                end
                ImGui.TreePop()
            end
        else ImGui.Text(kind=="dlcs" and "Select a DLC card to show its Download button." or "Select an item to download.") end
    end
    if kind~="dlcs" then renderSelectedPanel149() end
    ImGui.Separator()
    if #items==0 then
        ImGui.Text("No hosted items in this category yet.")
        ImGui.Text("Only fully uploaded SHA-256 verified GitHub assets will appear here.")
        return
    end
    local start=(g.page-1)*g.perPage+1
    local visible={}
    for i=start,math.min(#items,start+g.perPage-1) do visible[#visible+1]=items[i] end
    -- Original JPGs and valid catalog-cover art remain visible in both categories.
    -- Outfits preload up to six VERIFIED Outfit JSONs in volatile RAM for
    -- smooth hover. This never installs or writes a new .json to disk.
    if kind=="outfits" and Preview101.enabled then
        Preview098.lastPageRender=nowMs()
        Preview098.scanPage(g,visible)
    end
    fetchVisiblePreviews096(g,visible)
    local _,h=contentAvail()
    if ImGui.BeginChild then ImGui.BeginChild("MV090Scroll"..kind,0,kind=="dlcs" and math.max(160,math.min(290,(h or 0)-8)) or math.max(160,math.min(420,(h or 0)-8)),true) end
    local w=select(1,contentAvail())
    local cols,cw
    if kind=="dlcs" then
        cols=math.max(2,math.min(5,math.floor(w/154)))
        cw=math.max(126,(w-(cols-1)*8)/cols-7)
    else
        cols=math.max(2,math.min(3,math.floor(w/215)))
        cw=math.max(155,(w-(cols-1)*10)/cols-7)
    end
    if ImGui.BeginTable("MV090Cards"..kind,cols,ImGuiTableFlags.SizingStretchSame) then
        for _,it in ipairs(visible) do ImGui.TableNextColumn();itemTile(g,it,cw) end
        ImGui.EndTable()
    end
    if kind=="outfits" and ImGui.IsMouseReleased then
        local ok,released=pcall(ImGui.IsMouseReleased,0)
        if ok and (released==true or released==1) then C.starPressedId=nil end
    end
    C.starFinish123()
    if ImGui.EndChild then ImGui.EndChild() end
    if kind=="dlcs" then renderSelectedPanel149() end
    if kind=="outfits" and Preview101.enabled then
        Preview101.layout()
        Preview101.drawPanel()
    end
end
local function ensureLegacyCatalog(kind)
    if kind=="vehicles" and ModVerseVehicles080
        and not ModVerseVehicles080.liveLoaded and not ModVerseVehicles080.liveBusy then
        ModVerseVehicles080.refreshLive(false)
    elseif kind=="themes" and ModVerseCommunity078 and ModVerseCommunity078.state
        and not ModVerseCommunity078.state.initialized and not ModVerseCommunity078.state.loading then
        ModVerseCommunity078.state.refresh(false)
    end
end
function C.renderOtherFavorites(kind)
    ensureLegacyCatalog(kind)
    local list={}
    local data=kind=="themes" and (ModVerseCommunity078.state.items or {}) or (ModVerseVehicles080.liveItems or {})
    for _,it in ipairs(data) do if C.isFavorite(kind,it.id) then list[#list+1]=it end end
    ImGui.Text(#list.." favorite "..kind)
    if #list==0 then ImGui.Text("Select an item in Cherax Marketplace and star it.");return end
    for _,it in ipairs(list) do
        ImGui.Text(shortText(it.name,60))
        ImGui.SameLine()
        if ImGui.Button("Remove##MV090Fav"..kind..it.id,77,21) then C.favorite(kind,it.id) end
    end
end
function C.renderOtherInstalled(kind)
    ensureLegacyCatalog(kind)
    local data=kind=="themes" and (ModVerseCommunity078.state.items or {}) or (ModVerseVehicles080.liveItems or {})
    local found=0
    for _,it in ipairs(data) do
        if C.installed(kind,it) then found=found+1;ImGui.Text(shortText(it.name,85)) end
    end
    if found==0 then ImGui.Text("No "..kind.." installed from the current catalog.") end
end
function C.renderInstalled(kind)
    if kind=="outfits" or kind=="dlcs" then
        C.renderCategory(kind,{installed=true})
        ImGui.Separator()
        if kind=="dlcs" and DLC054 then
            ImGui.Text("Other existing Cherax DLCs (including manual installs)")
            if ImGui.Button("Scan Cherax DLCs##MV090",156,26) then DLC054.scan(true) end
            local rows=DLC054.installed or {}
            for i=1,math.min(#rows,25) do
                ImGui.Text(shortText(tostring(rows[i].name or "DLC"),78))
            end
            if #rows>25 then ImGui.Text("+"..(#rows-25).." more; use DLC Manager for full list") end
        elseif kind=="outfits" and FileMgr and FileMgr.FindFiles then
            ImGui.Text("Other local Cherax outfits (read-only)")
            if ImGui.Button("Scan Outfit Folder##MV090",166,26) then
                local ok,paths=pcall(FileMgr.FindFiles,MENU_ROOT.."\\Outfits\\",".json",false)
                C.localOutfits=ok and type(paths)=="table" and paths or {}
            end
            local paths=C.localOutfits or {}
            for i=1,math.min(#paths,25) do ImGui.Text(shortText(tostring(paths[i]),95)) end
            if #paths>25 then ImGui.Text("+"..(#paths-25).." more") end
        end
        return
    end
    return C.renderOtherInstalled(kind)
end
function C.renderFavorites(kind)
    if kind=="outfits" or kind=="dlcs" then return C.renderCategory(kind,{favorites=true}) end
    return C.renderOtherFavorites(kind)
end
function C.renderDownloads()
    ImGui.TextColored(0.78,0.55,1,1,"Cherax download activity")
    local n=0
    for _,entry in pairs(C.progress) do
        n=n+1
        ImGui.Text(shortText(entry.kind.." | "..entry.name.." | "..entry.status,130))
    end
    local themes=ModVerseCommunity078 and ModVerseCommunity078.state and ModVerseCommunity078.state.items or {}
    local vehicles=ModVerseVehicles080 and ModVerseVehicles080.liveItems or {}
    for _,item in ipairs(themes) do
        if item.downloading or (item.downloadStatus and item.downloadStatus~="Ready to download and install") then
            n=n+1
            ImGui.Text(shortText("Theme | "..tostring(item.name).." | "..tostring(item.downloadStatus),125))
        end
    end
    for _,item in ipairs(vehicles) do
        if item.downloading or (item.status and item.status~="Ready") then
            n=n+1
            ImGui.Text(shortText("Vehicle | "..tostring(item.name).." | "..tostring(item.status),125))
        end
    end
    if n==0 then ImGui.Text("No recent marketplace downloads this session.") end
    -- Download destinations are available from individual item details.
end
end)() -- MV090 scoped module

-- Build 121: compact, always-visible compatibility notices for the two Browse catalogs.
-- These are storefront disclosures only; no downloader/loader behavior is changed.
function renderGTA5Mods090()
    -- Build 142: bring back the GTA5-Mods DLC storefront, not the ASI catalog.
    ImGui.TextColored(1.00,0.79,0.45,1.00,"GTA5-Mods DLCs: ZIP packages containing a ready-made dlc.rpf only.")
    ImGui.TextColored(1.00,0.79,0.45,1.00,"RAR/7Z, native ASIs/DLLs and loose-asset conversions remain unavailable.")
    ImGui.TextColored(0.65,0.78,0.90,1.00,"Installed DLCs require a separate Cherax load; compatibility is not guaranteed.")
    ImGui.Spacing()
    VehicleMarket055.render()
end
-- Build 116: Local DLCs browse existing Cherax DLC folders only. This is
-- deliberately read-only and image-only; it never mounts, spawns, copies or
-- replaces an RPF while browsing.
MV116LocalDLC={selected=nil,page=1,query="",initialized=false}
function ModVerseCherax090.renderLocalDLC116()
    ImGui.TextColored(.80,.58,1,1,"Local DLCs")
    if not DLC054 then ImGui.Text("DLC scanner is not ready");return end
    if not MV116LocalDLC.initialized then
        MV116LocalDLC.initialized=true
        DLC054.scan(true)
    end
    if ImGui.Button("Refresh installed DLCs##MV116",192,25) and not DLC054.busy then
        DLC054.lastScanMs=0;DLC054.scan(true)
    end
    ImGui.SameLine();ImGui.Text(tostring(#(DLC054.installed or {})).." installed folders")
    local dlcDetails=productionDetails118("dlcs","Details",100)
    if dlcDetails then
        ImGui.TextWrapped("Read-only browser. Header checks do not prove DLCs are loadable; no DLC is automatically mounted.")
        ImGui.Text("Folder: Cherax\\DLCs\\<name>\\dlc.rpf")
    end
    -- Local DLC folders use the same robust focus/paste/search draft flow.
    if mv145CheraxSearch("LocalDLCs",MV116LocalDLC,"query") then MV116LocalDLC.page=1 end
    local rows={}
    for _,r in ipairs(DLC054.installed or {}) do
        if MV116LocalDLC.query=="" or r.name:lower():find(MV116LocalDLC.query:lower(),1,true) then
            rows[#rows+1]=r
        end
    end
    if MV122Filters.bar('localdlcs','localdlcs') then MV116LocalDLC.page=1 end
    local matched={}
    for _,r in ipairs(rows) do
        local favId=ModVerseCherax090.localDlcFav123(r)
        local fav=MV122Filters.state('localdlcs').show==2 and ModVerseCherax090.isFavorite('dlcs',favId)
        if MV122Filters.keep(r,'localdlcs','localdlcs',false,fav) then matched[#matched+1]=r end
    end
    rows=MV122Filters.order(matched,'localdlcs')
    local per=12
    local pages=math.max(1,math.ceil(#rows/per))
    MV116LocalDLC.page=math.max(1,math.min(pages,MV116LocalDLC.page))
    if ImGui.Button("< Prev##MV116DLC",85,23) then MV116LocalDLC.page=math.max(1,MV116LocalDLC.page-1) end
    ImGui.SameLine();ImGui.Text("Page "..MV116LocalDLC.page.." / "..pages)
    ImGui.SameLine()
    if ImGui.Button("Next >##MV116DLC",85,23) then MV116LocalDLC.page=math.min(pages,MV116LocalDLC.page+1) end
    if #rows==0 then ImGui.TextWrapped("No installed DLCs found. Use Refresh after installing DLC files through Cherax or Marketplace.") end
    local w=select(1,contentAvail())
    local cols=math.max(2,math.min(4,math.floor((w or 500)/154)))
    local tileWidth=math.max(124,((w or 500)-(cols-1)*8)/cols-7)
    if ImGui.BeginChild then ImGui.BeginChild("MV116LocalDLCGrid",0,math.max(150,math.min(370,select(2,contentAvail()) or 315)),true) end
    if ImGui.BeginTable("MV116LocalDLCTiles",cols,ImGuiTableFlags.SizingStretchSame) then
        local first=(MV116LocalDLC.page-1)*per+1
        for i=first,math.min(#rows,first+per-1) do
            local r=rows[i]
            ImGui.TableNextColumn()
            ImGui.PushID("MV116LocalDLC_"..r.name)
            local x,y=cursorScreenPos()
            local clicked=ImGui.InvisibleButton("##dlc",tileWidth,101)
            local hovered=ImGui.IsItemHovered()
            local chosen=MV116LocalDLC.selected==r.name
            ImGui.AddRectFilled(x,y,x+tileWidth,y+101,chosen and 56 or 28,chosen and 36 or 28,chosen and 79 or 44,255,6)
            ImGui.AddRectFilled(x+3,y+3,x+tileWidth-3,y+66,33,34,53,255,5)
            ImGui.AddText(x+10,y+12,"INSTALLED DLC",184,171,231,255)
            ImGui.AddText(x+10,y+37,r.valid and "RPF7 / OPEN" or "UNVERIFIED RPF",r.valid and 125 or 254,r.valid and 215 or 175,r.valid and 157 or 98,255)
            ImGui.AddText(x+8,y+74,shortText(r.name,math.max(11,math.floor((tileWidth-14)/7.4))),249,245,255,255)
            if hovered then ImGui.AddRect(x,y,x+tileWidth,y+101,184,126,243,255,6,0,2) end
            local favId=ModVerseCherax090.localDlcFav123(r)
            if ModVerseCherax090.cardStar123("dlcs",favId,x,y,hovered) then clicked=false end
            if clicked then MV116LocalDLC.selected=r.name end
            ImGui.PopID()
        end
        ImGui.EndTable()
    end
    ModVerseCherax090.starFinish123()
    if ImGui.EndChild then ImGui.EndChild() end
    local chosen=nil
    for _,r in ipairs(DLC054.installed or {}) do
        if r.name==MV116LocalDLC.selected then chosen=r;break end
    end
    if chosen then
        ImGui.Separator()
        ImGui.Text("Selected DLC: "..shortText(chosen.name,65))
        ImGui.Text(chosen.valid and "RPF7 header detected" or "Unverified RPF")
        if dlcDetails then
            ImGui.Text("Size: "..string.format("%.1f MiB",(chosen.size or 0)/1048576))
            ImGui.TextWrapped("Path: "..shortText(chosen.path or "",165))
        end
        if ImGui.Button("Copy DLC path##MV116",148,25) then
            pcall(function() Utils.SetClipBoardText(chosen.path,"") end)
            toast("DLC path copied",1600)
        end
    end
end

function renderCherax090()
    if ImGui.BeginTabBar("ModVerseCherax090") then
        if ImGui.BeginTabItem("Outfits") then
            if ImGui.BeginTabBar("MV109OutfitSources") then
                if ImGui.BeginTabItem("Marketplace") then ModVerseCherax090.renderCategory("outfits");ImGui.EndTabItem() end
                if ImGui.BeginTabItem("Local") then ModVerseCherax090.renderLocalOutfits();ImGui.EndTabItem() end
                ImGui.EndTabBar()
            else ModVerseCherax090.renderCategory("outfits") end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Vehicles") then
            local pv=ModVerseCherax090.OutfitPreview101
            if pv and (pv.visible or pv.clone~=0 or pv.queued) then pv.stop("Vehicle tab opened") end
            if ImGui.BeginTabBar("MV109VehicleSources") then
                if ImGui.BeginTabItem("Marketplace") then
                    ModVerseVehicles080.render()
                    ImGui.EndTabItem()
                end
                if ImGui.BeginTabItem("Local") then ModVerseCherax090.renderLocalVehicles();ImGui.EndTabItem() end
                ImGui.EndTabBar()
            else ModVerseVehicles080.render() end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("DLCs") then
            if ImGui.BeginTabBar("MV116DLCSources") then
                if ImGui.BeginTabItem("Marketplace") then ModVerseCherax090.renderCategory("dlcs");ImGui.EndTabItem() end
                if ImGui.BeginTabItem("Local") then ModVerseCherax090.renderLocalDLC116();ImGui.EndTabItem() end
                ImGui.EndTabBar()
            else ModVerseCherax090.renderCategory("dlcs") end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Themes") then
            local pv=ModVerseCherax090.OutfitPreview101
            if pv and (pv.visible or pv.clone~=0 or pv.queued) then pv.stop("Themes tab opened") end
            ModVerseCommunity078.render()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    else ModVerseVehicles080.render() end
end
-- ==========================================================================
-- ModVerse DLC MANAGER 053 (verified Cherax Legacy reference)
-- Confirmed user layout: Cherax\DLCs\g63amg6x6\dlc.rpf
-- Does NOT mount resources, edit RPF data, generate DLC metadata, or sync
-- custom vehicle models over the network. Installation is an explicit copy.
-- ==========================================================================
DLC054 = {
    root=normalizePath(MENU_ROOT):gsub("\\+$", "").."\\DLCs\\",
    registry=ROOT_DIR.."dlc053_managed.tsv",
    report=ROOT_DIR.."reports\\dlc054_report.tsv",
    rows={}, installed={}, managed={}, selected=1, status="Not scanned",
    scanSources={}, finderDiagnostics={}, scanSequence=0, lastScanMs=0,
    lastScanSummary="", seedNames={g63amg6x6=true},
    busy=false, dirty=true, lastError="", lastAction="", lookupName="g63amg6x6", lookupStatus="", requireRefresh=false,
    fileLimit=512*1024*1024, countLimit=1000
}

function DLC054.safeName(name)
    name=tostring(name or "")
    if #name<1 or #name>64 or not name:match("^[A-Za-z0-9_][A-Za-z0-9_%-]*$") then
        return nil
    end
    local upper=name:upper()
    if upper=="CON" or upper=="PRN" or upper=="NUL" or upper=="AUX"
       or upper:match("^COM[1-9]$") or upper:match("^LPT[1-9]$") then return nil end
    return name
end

function DLC054.targetPath(name)
    local safe=DLC054.safeName(name)
    if not safe then return nil end
    return DLC054.root..safe.."\\dlc.rpf"
end

function DLC054.validate(path)
    local f=io.open(path,"rb")
    if not f then return false,"Unable to read RPF",0 end
    local size=f:seek("end") or 0
    f:seek("set",0)
    local head=f:read(24) or ""
    f:close()
    if size < 4096 or size>DLC054.fileLimit then return false,"RPF size outside conservative 4 KB to 512 MB range",size end
    if head:sub(1,4)~="7FPR" then return false,"Not an RPF7 header (7FPR)",size end
    if head:sub(13,16)~="OPEN" then
        return false,"RPF7 detected but not unencrypted OPEN; cannot certify copy",size
    end
    local entries=u32le(head,5) or 0
    local namesSize=u32le(head,9) or 0
    if entries<1 or entries>250000 or namesSize<1 or namesSize>128*1024*1024
       or (16+entries*16+namesSize)>size then
        return false,"RPF7 header table size/count is implausible",size
    end
    return true,"RPF7 / OPEN directory header plausible (not full content validation)",size
end

function DLC054.readRegistry()
    DLC054.managed={}
    if not fileExistsDirect(DLC054.registry) then return end
    local f=io.open(DLC054.registry,"rb")
    if not f then return end
    for line in f:lines() do
        local n,h,size,hash,origin=line:match("^OWNED\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$")
        if n then
            local name=hexDecode(n)
            if DLC054.safeName(name) then
                DLC054.managed[name:lower()]={name=name, rel=hexDecode(h), size=tonumber(size) or -1,
                    hash=hash, origin=hexDecode(origin)}
            end
        end
    end
    f:close()
end

function DLC054.writeRegistry()
    local lines={"VERSION\t1"}
    local names={}
    for name in pairs(DLC054.managed) do names[#names+1]=name end
    table.sort(names)
    for _,key in ipairs(names) do
        local e=DLC054.managed[key]
        lines[#lines+1]=table.concat({"OWNED",hexEncode(e.name),hexEncode(e.rel or ""),
            tostring(e.size or 0),tostring(e.hash or ""),hexEncode(e.origin or "")},"\t")
    end
    local f=io.open(DLC054.registry,"wb")
    if not f then return false end
    local ok=pcall(function() f:write(table.concat(lines,"\r\n").."\r\n");f:flush() end)
    f:close()
    return ok
end

-- FNV-1a fingerprint, chunked. Used only to detect accidental modifications
-- between install and later inspection; this is NOT cryptographic verification.
function DLC054.fnvChunk(hash,s)
    for i=1,#s do hash=((hash ~ s:byte(i))*16777619) & 0xFFFFFFFF end
    return hash
end
function DLC054.fingerprint(path)
    local f=io.open(path,"rb")
    if not f then return nil,"Unreadable destination" end
    local hash=2166136261
    local count=0
    while true do
        local s=f:read(128*1024)
        if not s or #s==0 then break end
        hash=DLC054.fnvChunk(hash,s)
        count=count+#s
        if count>DLC054.fileLimit then f:close();return nil,"File exceeds limit" end
        if Script and Script.Yield then Script.Yield(0) end
    end
    f:close()
    return string.format("%08X",hash),count
end

function DLC054.findCandidates()
    local rows,seen={},{}
    local roots={}
    for root in pairs(InstallIndex.roots or {}) do if ModVersePath152.safeRoot(root) then roots[normalizePath(root)]=true end end
    for root in pairs(roots) do
        local meta=readMeta(root)
        local names={}
        for _,rel in ipairs(readManifest(root)) do
            local safe=ModVersePath152.safeRelative(rel)
            if safe and basename(safe):lower()=="dlc.rpf" then names[#names+1]=root.."\\"..safe end
        end
        -- Manifest may have been generated by an older build or missing its RPF.
        local ok,found=pcall(FileMgr.FindFiles,root,".rpf",true)
        if ok and type(found)=="table" then
            for _,path in ipairs(found) do
                if basename(tostring(path)):lower()=="dlc.rpf" then names[#names+1]=path end
            end
        end
        for _,path in ipairs(names) do
            path=normalizePath(path)
            local prefix=root.."\\"
            local rel=path:sub(#prefix+1)
            local safe=ModVersePath152.safeRelative(rel)
            if safe and path:sub(1,#prefix):lower()==prefix:lower() and
               not seen[path:lower()] and fileExistsDirect(path) then
                seen[path:lower()]=true
                local candidate=basename(dirname(path))
                if not DLC054.safeName(candidate) or candidate:lower()==basename(root):lower() and
                    normalizePath(dirname(path)):lower()==root:lower() then
                    candidate=basename(root)
                end
                local valid,detail,size=DLC054.validate(path)
                local target=DLC054.targetPath(candidate)
                local exists=target and fileExistsDirect(target) or false
                rows[#rows+1]={source=path,root=root,relative=rel,mod=meta.name or basename(root),
                    slug=basename(root),name=candidate,valid=valid,detail=detail,size=size or 0,
                    destination=target,exists=exists}
                if #rows>=DLC054.countLimit then break end
            end
        end
        if #rows>=DLC054.countLimit then break end
    end
    table.sort(rows,function(a,b) return (a.mod..a.name):lower()<(b.mod..b.name):lower() end)
    return rows
end

-- This read-only scan deliberately does NOT depend on FileMgr's extension
-- enumeration succeeding. Cherax has been observed to mount an RPF while
-- FindFiles(root, '.rpf', true) returned an empty array.
-- Names confirmed from previous results, the user's manual lookup, the
-- managed registry, and candidate packages can be checked via exact io.open.
function DLC054.scan(force)
    if DLC054.busy then return end
    local tick=nowMs()
    if DLC054.lastScanMs~=0 and tick-DLC054.lastScanMs<900 then
        return
    end
    DLC054.lastScanMs=tick
    DLC054.scanSequence=DLC054.scanSequence+1
    DLC054.readRegistry()
    DLC054.rows=DLC054.findCandidates()
    local installed,foundByName,scanSources,diagnostics={},{},{},{}
    local root=normalizePath(DLC054.root):gsub("\\+$", "").."\\"
    local caseRoot=root:lower()
    local function register(path,source)
        path=normalizePath(tostring(path or ""))
        if path:sub(1,#root):lower()~=caseRoot then return end
        local rel=path:sub(#root+1)
        local name=rel:match("^([^\\]+)\\[dD][lL][cC]%.[rR][pP][fF]$")
        if not DLC054.safeName(name) or foundByName[name:lower()] then return end
        -- Cherax's folder enumeration can return paths that are stale or
        -- inaccessible to the Lua runtime. Never display them as installed.
        if not fileExistsDirect(path) then return end
        local valid,detail,size=DLC054.validate(path)
        installed[#installed+1]={name=name,path=path,valid=valid,
            detail=detail,size=size or 0,source=source,
            managed=DLC054.managed[name:lower()]~=nil}
        foundByName[name:lower()]=true
        scanSources[source]=(scanSources[source] or 0)+1
    end
    local variants={root,root:sub(1,-2)}
    local seenQueries={}
    for _,dir in ipairs(variants) do
        for _,ext in ipairs({".rpf","rpf",""}) do
            local key=dir:lower().."|"..ext
            if not seenQueries[key] then
                seenQueries[key]=true
                local ok,files=pcall(FileMgr.FindFiles,dir,ext,true)
                local size=ok and type(files)=="table" and #files or -1
                diagnostics[#diagnostics+1]=string.format("finder ext=%s trailing=%s count=%d",
                    ext=="" and "ALL" or ext,(dir:sub(-1)=="\\") and "yes" or "no",size)
                if size>0 then
                    for _,path in ipairs(files) do
                        register(path,"FILE_FINDER")
                        if #installed>=DLC054.countLimit then break end
                    end
                end
            end
            if #installed>=DLC054.countLimit then break end
        end
        if #installed>=DLC054.countLimit then break end
    end
    local names={}
    for name in pairs(DLC054.seedNames or {}) do names[name:lower()]=name end
    for _,item in ipairs(DLC054.installed or {}) do
        if DLC054.safeName(item.name) then names[item.name:lower()]=item.name end
    end
    for _,item in ipairs(DLC054.rows) do
        if DLC054.safeName(item.name) then names[item.name:lower()]=item.name end
    end
    for key,item in pairs(DLC054.managed or {}) do
        if DLC054.safeName(item.name) then names[key]=item.name end
    end
    local directName=DLC054.safeName(DLC054.lookupName)
    if directName then names[directName:lower()]=directName end
    local directChecked=0
    for _,name in pairs(names) do
        if #installed>=DLC054.countLimit then break end
        if not foundByName[name:lower()] then
            directChecked=directChecked+1
            register(root..name.."\\dlc.rpf","DIRECT_PATH")
        end
    end
    DLC054.scanSources=scanSources
    DLC054.finderDiagnostics=diagnostics
    DLC054.directChecked=directChecked
    table.sort(installed,function(a,b) return a.name:lower()<b.name:lower() end)
    DLC054.installed=installed
    DLC054.selected=math.max(1,math.min(DLC054.selected,#DLC054.rows))
    DLC054.status=string.format("%d packaged DLC candidates | %d existing DLCs | %d managed records",
        #DLC054.rows,#installed,(function()local n=0;for _ in pairs(DLC054.managed) do n=n+1 end;return n end)())
    DLC054.dirty=false
    local summary=DLC054.status.." | by finder="..tostring(scanSources.FILE_FINDER or 0)..
        " direct="..tostring(scanSources.DIRECT_PATH or 0).." | probes="..directChecked
    -- Do not spam the logger when repeatedly hitting Refresh or redrawing UI.
    if DLC054.lastScanSummary~=summary then
        log("[DLC054][SCAN] "..summary)
        log("[DLC054][ROOT] "..root)
        if #installed==0 then log("[DLC054][ENUM] "..table.concat(diagnostics,"; ")) end
        DLC054.lastScanSummary=summary
    end
end

function DLC054.writeReport()
    pcall(FileMgr.CreateDir,ROOT_DIR.."reports\\")
    local lines={"VERSION\t054","MODE\tLOCAL_ONLY","CHERAX_LAYOUT\tDLCs\\<name>\\dlc.rpf",
        "WARNING\tRPF header validation is not full content validation; runtime mounting is not verified by this scanner",
        "SCAN_ROOT\t"..DLC054.root,"SCAN_FINDERS\t"..table.concat(DLC054.finderDiagnostics or {}," | "),
        "KIND\tPACKAGE\tDLC_NAME\tSTATE\tBYTES\tSOURCE_OR_PATH\tDETAIL"}
    for _,r in ipairs(DLC054.rows) do
        local state=(not r.valid and "INVALID" or (r.exists and "EXISTS" or "READY"))
        lines[#lines+1]=table.concat({"CANDIDATE",r.mod,r.name,state,tostring(r.size),r.relative,r.detail},"\t")
    end
    for _,r in ipairs(DLC054.installed) do
        lines[#lines+1]=table.concat({"INSTALLED","",r.name,r.managed and "ModVerse_MANAGED" or "EXTERNAL",
            tostring(r.size),r.name.."\\dlc.rpf",r.detail.." | source="..tostring(r.source or "unknown")},"\t")
    end
    local f=io.open(DLC054.report,"wb")
    if not f then return false end
    local ok=pcall(function() f:write(table.concat(lines,"\r\n"));f:flush() end)
    f:close();return ok
end

function DLC054.install(candidate, onFinish, onProgress)
    if DLC054.busy then return false end
    if not candidate then DLC054.status="No candidate selected";return false end
    local src=candidate.source
    local name=candidate.name
    local dest=DLC054.targetPath(name)
    local relative=ModVersePath152.safeRelative(candidate.relative)
    local expected=relative and normalizePath(candidate.root).."\\"..relative or ""
    if not dest or not ModVersePath152.safeRoot(candidate.root) or
        expected:lower()~=normalizePath(src):lower() or basename(src):lower()~="dlc.rpf" then
        DLC054.status="Invalid package identity or destination";return false
    end
    if not fileExistsDirect(src) then DLC054.status="RPF source disappeared";return false end
    if fileExistsDirect(dest) then
        DLC054.status="DLC already exists: refused to overwrite "..name
        return false
    end
    local valid,detail,size=DLC054.validate(src)
    if not valid then DLC054.status="Install rejected: "..detail;return false end
    if not Script or not Script.QueueJob then DLC054.status="Cherax job queue unavailable";return false end
    DLC054.busy=true
    DLC054.status="Copying existing RPF to Cherax DLCs: "..name
    Script.QueueJob(function()
        local success,err=pcall(function()
            -- Recheck immediately before writing, never replace any existing DLC.
            if fileExistsDirect(dest) then error("Destination exists; not overwriting") end
            local folder=dirname(dest)
            local okdir,created=pcall(FileMgr.CreateDir,folder)
            if not okdir or created==false then error("Cannot create destination folder") end
            local temp=folder.."\\.modverse053-"..name..".part"
            if fileExistsDirect(temp) then error("Stale staging file exists; manual cleanup required") end
            local input=io.open(src,"rb")
            if not input then error("Source no longer readable") end
            local output=io.open(temp,"wb")
            if not output then input:close();error("Cannot create staging file") end
            local written,hash=0,2166136261
            local copyOk,copyErr=pcall(function()
                while true do
                    local block=input:read(128*1024)
                    if not block or #block==0 then break end
                    local wrote,werr=output:write(block)
                    if not wrote then error("Write failed: "..tostring(werr)) end
                    written=written+#block
                    if onProgress then pcall(onProgress,written,size) end
                    hash=DLC054.fnvChunk(hash,block)
                    if written>DLC054.fileLimit then error("Copy exceeded size limit") end
                    if Script and Script.Yield then Script.Yield(0) end
                end
                output:flush()
            end)
            input:close();output:close()
            if not copyOk then deleteFile(temp);error(tostring(copyErr)) end
            local good,reason,actual=DLC054.validate(temp)
            if not good or actual~=size or actual~=written then
                deleteFile(temp);error("Staging verification failed: "..tostring(reason))
            end
            if fileExistsDirect(dest) then
                deleteFile(temp);error("Destination was created by another process; not overwriting")
            end
            if type(os.rename)~="function" then
                deleteFile(temp)
                error("Atomic file renaming is unavailable in this Lua environment")
            end
            local moved,merr=os.rename(temp,dest)
            if not moved then
                deleteFile(temp)
                error("Atomic rename unavailable: "..tostring(merr).."; install not completed")
            end
            if not fileExistsDirect(dest) then error("RPF missing after rename") end
            local savedHash=string.format("%08X",hash)
            local destHash,destSize=DLC054.fingerprint(dest)
            if destHash~=savedHash or destSize~=written then
                deleteFile(dest) -- Only the newly created destination, never a pre-existing DLC.
                error("Post-install fingerprint mismatch; new file was removed")
            end
            DLC054.managed[name:lower()]={name=name,rel=candidate.relative,size=written,hash=savedHash,origin=candidate.slug}
            if not DLC054.writeRegistry() then
                DLC054.status="RPF installed, but ownership manifest failed to save. Do not use automatic removal."
                log("[DLC054][REGISTRY_WARNING] "..dest)
            else
                DLC054.status="Installed "..name.." ("..tostring(written).." bytes). Refresh/load DLC in Cherax; runtime not yet verified."
            end
            log("[DLC054][INSTALL] "..name.." bytes="..tostring(written).." fingerprint="..savedHash)
        end)
        if not success then
            DLC054.status="Install failed safely: "..tostring(err)
            DLC054.lastError=tostring(err)
            log("[DLC054][ERROR] "..tostring(err))
        end
        DLC054.busy=false
        DLC054.lastAction=DLC054.status
        if onFinish then pcall(onFinish,success,DLC054.status,candidate) end
        DLC054.dirty=true
        DLC054.lastScanMs=0
        DLC054.scan(true)
        if not success then toast("DLC install failed. See DLC Manager status.",5000)
        else toast("DLC file installed. Refresh Cherax DLC list to load it.",5000) end
    end)
    return true
end

function DLC054.render()
    ImGui.TextColored(0.80,0.52,1.00,1.00,"DLCs")
    ImGui.SameLine()
    if ImGui.Button("Refresh DLCs##054",130,26) and not DLC054.busy then DLC054.scan(true) end
    if DLC054.dirty and not DLC054.busy then DLC054.scan() end
    safeTextWrapped("Confirmed folder layout: Cherax\\DLCs\\<DLC name>\\dlc.rpf. Installs ready-made unencrypted RPF7 packages only; no RPF edits or automatic texture conversion.")
    ImGui.TextColored(0.66,0.74,0.84,1.00,DLC054.status)
    if DLC054.lastAction~="" then safeTextWrapped("Last action: "..DLC054.lastAction) end
    safeTextWrapped("DLC directory: "..DLC054.root)
    if (DLC054.scanSources.DIRECT_PATH or 0)>0 then
        safeTextWrapped("Direct file verification located "..tostring(DLC054.scanSources.DIRECT_PATH).." installed DLC(s), even though the recursive directory scanner may be empty.")
    end
    ImGui.Separator()
    ImGui.TextColored(0.72,0.90,1.00,1.00,"Packaged DLC candidates")
    if #DLC054.rows==0 then
        safeTextWrapped("No dlc.rpf detected in installed ModVerse packages. Install an add-on archive through Marketplace, then refresh here. Existing Cherax DLCs appear below.")
    else
        if ImGui.BeginChild then ImGui.BeginChild("DLC054Candidates",0,172,true) end
        for i,r in ipairs(DLC054.rows) do
            local state=not r.valid and "INVALID" or r.exists and "EXISTS" or "READY"
            local label=shortText(r.mod,35).." | "..r.name.." ["..state.."]##DLC054row"..i
            if ImGui.Selectable(label,DLC054.selected==i) then DLC054.selected=i end
        end
        if ImGui.EndChild then ImGui.EndChild() end
        local selected=DLC054.rows[DLC054.selected]
        if selected then
            ImGui.TextColored(0.75,0.82,0.94,1.00,"Package: "..selected.mod)
            safeTextWrapped("Source: "..selected.relative)
            safeTextWrapped("Proposed folder: "..selected.name.." | "..tostring(selected.size).." bytes")
            ImGui.TextColored(selected.valid and 0.30 or 1.00,selected.valid and 0.94 or 0.45,0.48,1.00,selected.detail)
            if selected.destination then
                safeTextWrapped("Target: "..selected.destination)
                if selected.exists then
                    ImGui.TextColored(1.00,0.72,0.36,1.00,"Destination exists. ModVerse will not replace this DLC.")
                elseif selected.valid and not DLC054.busy then
                    if ImGui.Button("Install this DLC##054",190,30) then DLC054.install(selected) end
                end
            else
                safeTextWrapped("Folder name is invalid for Cherax DLC installation; blocked.")
            end
        end
    end
    ImGui.Separator()
    ImGui.TextColored(0.72,0.90,1.00,1.00,"Existing Cherax DLCs (read-only listing)")
    if #DLC054.installed==0 then safeTextWrapped("No DLC folders detected. Check a folder by name below, or review the reported DLC root path.") end
    if ImGui.BeginChild then ImGui.BeginChild("DLC054Installed",0,125,true) end
    for _,r in ipairs(DLC054.installed) do
        ImGui.TextColored(r.valid and 0.65 or 1.00,r.valid and 0.90 or 0.50,0.78,1.00,
            r.name.." | "..(r.managed and "ModVerse managed" or "Existing external DLC").." | "..(r.valid and "RPF7/OPEN" or "Unverified"))
    end
    if ImGui.EndChild then ImGui.EndChild() end
    if ImGui.InputText then
        local updated=ImGui.InputText("Check a DLC folder by name##054",DLC054.lookupName,64)
        if type(updated)=="string" then DLC054.lookupName=updated end
        ImGui.SameLine()
        if ImGui.Button("Check Folder##054",128,25) then
            local name=DLC054.safeName(DLC054.lookupName)
            if name then DLC054.seedNames[name:lower()]=name end
            DLC054.lastScanMs=0
            DLC054.scan(true)
            local path=DLC054.targetPath(DLC054.lookupName)
            if not path then DLC054.lookupStatus="Invalid DLC folder name"
            elseif not fileExistsDirect(path) then DLC054.lookupStatus="Not found: "..tostring(DLC054.lookupName)
            else
                local good,detail,bytes=DLC054.validate(path)
                DLC054.lookupStatus=tostring(DLC054.lookupName).." | "..(good and "Detected" or "Unverified")..
                    " | "..tostring(bytes).." bytes | "..detail
            end
        end
        if DLC054.lookupStatus~="" then safeTextWrapped(DLC054.lookupStatus) end
    end
    safeTextWrapped("Safe removal: close GTA fully before manually removing an ModVerse-owned DLC folder. In-game deletion is deliberately disabled to avoid removing mounted resources. Existing external DLCs are never modified.")
    if ImGui.Button("Copy DLC folder path##054",172,26) then
        pcall(function() Utils.SetClipBoardText(DLC054.root,"") end)
        toast("Copied Cherax DLC directory",2200)
    end
    ImGui.SameLine()
    if ImGui.Button("Export DLC audit##054",162,26) then
        if DLC054.writeReport() then toast("DLC audit written to ModVerse reports",3000)
        else toast("Unable to write DLC report",3500) end
    end
    safeTextWrapped("A valid RPF header does not prove the game can mount its content. After installation, manually load the DLC in Cherax and test its spawn name. Online peer visibility is unverified.")
end

-- Minimal Cherax-native layout inspired by BiggerScript: short labels and no nested panels.
ModVerse061=ModVerse061 or {installedSearch="", installedPage=1, installedKind="asi", moreASI=false,
    moreDLC=false, favInfo=false, details=false, showDiagMore=false, dlcSelected=1}
-- method. Artwork resolves from the original Marketplace package metadata/cache.
ModVerse066={selectedKey="",page=1,pageSize=14,showInfo=false,showStaged=true,
    imgCache={},photoOverride={},photoPath="",photoEdit=false,lastScan=-1}

function ModVerse066.allDLCs()
    local rows,seen={},{}
    for _,r in ipairs(DLC054.installed or {}) do
        local key=tostring(r.name or ""):lower()
        if key~="" then
            rows[#rows+1]={key=key,installed=true,data=r,name=r.name}
            seen[key]=true
        end
    end
    for idx,r in ipairs(DLC054.rows or {}) do
        local name=tostring(r.name or ""):lower()
        if name~="" and not seen[name] then
            -- Keep distinct candidate paths, even when multiple package
            -- variants use the same DLC folder name. Only the selected
            -- candidate may be installed, and DLC054 still refuses overwrites.
            local key="candidate:"..name..":"..tostring(r.relative or idx)
            rows[#rows+1]={key=key,installed=false,data=r,name=r.name}
        end
    end
    table.sort(rows,function(a,b) return a.key<b.key end)
    return rows
end

function ModVerse066.packageFor(row)
    if not row then return nil end
    -- A managed DLC records the slug of the package from which it was installed.
    local name=tostring(row.name or ""):lower()
    local owned=DLC054.managed and DLC054.managed[name]
    local slug=owned and owned.origin or nil
    if not slug then
        for _,r in ipairs(DLC054.rows or {}) do
            if tostring(r.name or ""):lower()==name then slug=r.slug;break end
        end
    end
    if not slug then return nil end
    if not tostring(slug):match("^[%w_%-]+$") then return nil end
    local root=MODS_DIR..sanitizeFileName(slug)
    local meta=readMeta(root)
    return {slug=slug,root=root,meta=meta}
end

function ModVerse066.photo(row)
    if not row then return nil,nil end
    local cacheKey=tostring(row.key or row.name).."#"..tostring(DLC054.scanSequence or 0)
    local cached=ModVerse066.imgCache[cacheKey]
    if cached then return cached.path,cached.label end
    local pack=ModVerse066.packageFor(row)
    local label=tostring(row.name or "DLC")
    local path=nil
    if pack then
        local meta=pack.meta or {}
        if type(meta.name)=="string" and meta.name~="" then label=meta.name end
        if type(meta.thumb)=="string" and meta.thumb~="" and fileExists(meta.thumb) then
            path=meta.thumb
        end
        if not path then path=findCachedThumb({slug=pack.slug}) end
        if not path then
            -- Only consider images listed in this package's safe manifest.
            for _,relative in ipairs(readManifest(pack.root) or {}) do
                local safe=ModVersePath152.safeRelative(relative)
                if safe and safe:lower():match("%.jpe?g$") or (safe and safe:lower():match("%.png$")) then
                    local candidate=pack.root.."\\"..safe
                    if fileExists(candidate) and detectImageFile(candidate) then
                        path=candidate;break
                    end
                end
            end
        end
    end
    if not path then path=findCachedThumb({slug=row.name}) end
    ModVerse066.imgCache[cacheKey]={path=path,label=label}
    return path,label
end

function ModVerse066.preview(row)
    local avail=select(1,contentAvail())
    local w=math.max(190,math.min(avail-10,440))
    local h=math.floor(w*0.48)
    local x,y=cursorScreenPos()
    ImGui.InvisibleButton("##mvDLCPreview066",w,h)
    ImGui.AddRectFilled(x,y,x+w,y+h,27,27,39,255,8)
    local path,label=ModVerse066.photo(row)
    local srv=path and textureSrv(path) or nil
    if srv then
        if ImGui.AddImageRounded then ImGui.AddImageRounded(srv,x+2,y+2,x+w-2,y+h-2,0,0,1,1,0xFFFFFFFF,7)
        else ImGui.AddImage(srv,x+2,y+2,x+w-2,y+h-2) end
    else
        ImGui.AddText(x+13,y+h/2-9,"No preview",165,165,184,255)
    end
    ImGui.AddRect(x,y,x+w,y+h,130,76,186,225,8,0,1)
    return label
end

function ModVerse066.selectedRow(rows)
    for _,row in ipairs(rows) do
        if row.key==ModVerse066.selectedKey then return row end
    end
    local row=rows[1]
    ModVerse066.selectedKey=row and row.key or ""
    return row
end

-- Build 067: DLC vehicle detail and Cherax feature bridge.
-- Cherax Lua API can trigger an existing feature by name but does not document
-- insertion into the built-in Spawner > Vehicle List. The Spawner tab below is
-- ModVerse-owned. Never assume disk installation means the DLC is mounted.
ModVerse067 = {detailOpen=false, detailKey="", status={}, loading={}, ready={},
    currentTab="Installed", spawnerPage=1, selectedSpawnerKey=""}

function ModVerse067.open(row)
    if not row then return end
    ModVerse067.detailKey=row.key
    ModVerse067.detailOpen=true
    ModVerse066.selectedKey=row.key
end

-- The game can enter a failed-DLC-load state (Cherax error 9). Never repeatedly
-- invoke Load All DLCs; one attempt is permitted per GTA process / Lua state.
-- This guard is intentionally global to survive a ModVerse script reload when
-- Cherax shares the Lua state. It clears automatically on a fresh game launch.
ModVerse070 = ModVerse070 or {}
ModVerse070.dlcGate = type(rawget(_G,"__MODVERSE_DLC_LOAD_SESSION_070"))=="table" and
    rawget(_G,"__MODVERSE_DLC_LOAD_SESSION_070") or {attempted=false,blocked=false}
_G.__MODVERSE_DLC_LOAD_SESSION_070=ModVerse070.dlcGate

-- Build 070: invoke Cherax's real Load All DLCs menu feature as a macro.
-- Do not synthesize mouse clicks, guess hash IDs, or trigger ambiguous controls.
function ModVerse067.findFeature()
    if not FeatureMgr then return nil,"Cherax FeatureMgr unavailable" end
    local names={"Load All DLCs","Load All DLC","Load All Dlc's","Load All Dlc"}
    if type(FeatureMgr.GetFeatureByName)=="function" then
        for _,name in ipairs(names) do
            local ok,feature=pcall(FeatureMgr.GetFeatureByName,name)
            if ok and feature then return feature,name end
        end
    end
    -- Build 070: translated/external names may differ from raw names.
    -- Enumerate once only when Load is pressed, and require an exact match.
    local ok,all=pcall(function() return FeatureMgr.GetAllFeatures() end)
    if ok and type(all)=="table" then
        local targets={loadalldlcs=true,loadalldlc=true}
        for _,feature in pairs(all) do
            local yes,label=pcall(function()
                if feature.GetName then return feature:GetName(true) end
                return feature.Name
            end)
            if yes and type(label)=="string" then
                local normalized=label:lower():gsub("[^%w]", "")
                if targets[normalized] then return feature,label end
            end
        end
    end
    return nil,"Load All DLCs not exposed by Cherax"
end

function ModVerse067.invokeLoad()
    local gate=ModVerse070.dlcGate
    if gate.blocked then
        return false,"Previous load was unsuccessful. Restart GTA before loading more DLCs."
    end
    if gate.attempted then
        -- Another installed vehicle should not remount the entire DLC collection.
        return true,"DLC load was already requested this session; checking model"
    end
    local feature,name=ModVerse067.findFeature()
    if not feature then
        log("[DLC068][MACRO_UNAVAILABLE] "..tostring(name))
        return false,name
    end
    -- Mark BEFORE invoking the callback: no recursive, repeated or concurrent loads.
    gate.attempted=true
    -- OnClick is the API's equivalent of pressing this menu item.
    local ok,reason=pcall(function()
        if type(feature.OnClick)=="function" then
            feature:OnClick()
        elseif type(feature.TriggerCallback)=="function" then
            feature:TriggerCallback()
        else
            error("Cherax feature has no callable action")
        end
    end)
    if not ok then
        gate.blocked=true
        log("[DLC070][MACRO_ERROR] "..tostring(reason))
        return false,"Load DLC macro failed: "..tostring(reason)
    end
    log("[DLC068][MACRO_CLICK] "..tostring(name).."; checking model")
    return true,"Load requested"
end

-- Native streaming fallbacks work without the optional generated STREAMING table.
-- These use the documented Natives.InvokeBool/InvokeVoid Cherax API.
function ModVerse067.streamReady()
    local direct=STREAMING and type(STREAMING.REQUEST_MODEL)=="function" and
        type(STREAMING.HAS_MODEL_LOADED)=="function"
    local native=Natives and type(Natives.InvokeVoid)=="function" and
        type(Natives.InvokeBool)=="function"
    return direct or native
end

function ModVerse067.requestModel(hash)
    if STREAMING and type(STREAMING.REQUEST_MODEL)=="function" then
        return pcall(STREAMING.REQUEST_MODEL,hash)
    end
    if Natives and type(Natives.InvokeVoid)=="function" then
        return pcall(Natives.InvokeVoid,0x963D27A58DF860AC,hash)
    end
    return false
end

function ModVerse067.hasModel(hash)
    if STREAMING and type(STREAMING.HAS_MODEL_LOADED)=="function" then
        local ok,v=pcall(STREAMING.HAS_MODEL_LOADED,hash)
        if ok then return v==true end
    end
    if Natives and type(Natives.InvokeBool)=="function" then
        local ok,v=pcall(Natives.InvokeBool,0x98A4EB5D89A0C952,hash)
        return ok and v==true
    end
    return false
end

function ModVerse067.modelInGame(hash)
    if Natives and type(Natives.InvokeBool)=="function" then
        local ok,v=pcall(Natives.InvokeBool,0x35B9E0803292B641,hash)
        if ok then return v==true end
    end
    -- Don't falsely report a missing model if CDIMAGE isn't exposed.
    return nil
end

function ModVerse067.releaseModel(hash)
    if STREAMING and type(STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED)=="function" then
        pcall(STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED,hash)
    elseif Natives and type(Natives.InvokeVoid)=="function" then
        pcall(Natives.InvokeVoid,0xE532F5D78798DAAB,hash)
    end
end

function ModVerse067.spawnContext(row)
    if not row or not row.installed or not row.data or not row.data.valid then return nil end
    local key="modverse066-dlc-"..tostring(row.key)
    local candidate={name=row.name,valid=true}
    local package=ModVerse066.packageFor(row)
    if package then
        for _,c in ipairs(DLC054.rows or {}) do
            if c.slug==package.slug and tostring(c.name):lower()==tostring(row.name):lower() then
                candidate=c;break
            end
        end
    end
    local item={slug=key,name=row.name}
    local model=VehicleMarket055.modelName(item,candidate)
    return item,candidate,model
end

function ModVerse067.start(row,autoSpawn,manualVerify)
    local item,candidate,model=ModVerse067.spawnContext(row)
    if not item then return false end
    local key=row.key
    if ModVerse067.loading[key] then return false end
    model=tostring(model or ""):gsub("^%s+",""):gsub("%s+$","")
    if #model<1 or #model>70 or not model:match("^[%w_]+$") then
        ModVerse067.status[key]="Enter a model name first"
        return false
    end
    if not (ModVerse067.streamReady() and
            Utils and Utils.Joaat and Script and Script.QueueJob and Script.Yield) then
        ModVerse067.status[key]="Model checking unavailable. Use Cherax to load DLCs."
        return false
    end
    if not manualVerify then
        local ok,reason=ModVerse067.invokeLoad()
        if not ok then
            ModVerse067.status[key]="Manual: Misc > General > Load All DLCs. Then Verify. "..tostring(reason)
            ModVerse067.ready[key]=false
            return false
        end
    end
    ModVerse067.ready[key]=false
    ModVerse067.loading[key]=true
    ModVerse067.status[key]=manualVerify and "Checking model..." or "Loading DLC..."
    Script.QueueJob(function()
        local success,err=pcall(function()
            local hash=Utils.Joaat(model)
            local loaded=false
            local started=nowMs()
            while nowMs()-started<12000 do
                -- The macro may still be loading the DLC into the game.
                -- Avoid requesting unmounted models until CDIMAGE recognizes them.
                local exists=ModVerse067.modelInGame(hash)
                if exists~=false then ModVerse067.requestModel(hash) end
                if ModVerse067.hasModel(hash) then loaded=true;break end
                Script.Yield(150)
            end
            if not loaded then
                ModVerse067.status[key]="Model not ready. Verify model name. If DLC load failed (error 9), restart GTA."
                if not manualVerify then
                    -- Do not call Cherax's global DLC loader again in this session.
                    ModVerse070.dlcGate.blocked=true
                    log("[DLC070][LOAD_GATED] Load timed out; restart GTA before another DLC load")
                end
                return
            end
            ModVerse067.ready[key]=true
            ModVerse067.status[key]="Ready: "..model
            log("[DLC067][MODEL_READY] "..tostring(row.name).." => "..model)
            if autoSpawn then
                -- Original tested Cherax spawn path remains the only spawner;
                -- queueing it here preserves model streaming and local-only spawn.
                VehicleMarket055.spawn(item,candidate)
                ModVerse067.status[key]="Spawning "..model.."..."
            end
        end)
        if not success then
            ModVerse067.status[key]="Load error: "..shortText(tostring(err),115)
            log("[DLC067][LOAD_ERROR] "..tostring(err))
        end
        ModVerse067.loading[key]=false
    end)
    return true
end

function ModVerse067.drawDetail(rows)
    local selected=nil
    for _,r in ipairs(rows or {}) do if r.key==ModVerse067.detailKey then selected=r;break end end
    if ImGui.Button("< Back##mv067",90,27) then
        ModVerse067.detailOpen=false
        return
    end
    ImGui.SameLine();ImGui.Text("Vehicle")
    if not selected then
        ImGui.Text("DLC changed. Refresh list.")
        return
    end
    local label=ModVerse066.preview(selected)
    ImGui.TextColored(0.78,0.54,1,1,shortText(label or selected.name,65))
    local item,candidate,model=ModVerse067.spawnContext(selected)
    if not item then
        ImGui.Text(selected.installed and "Unverified DLC" or "Not installed")
        if not selected.installed and selected.data and selected.data.valid and not DLC054.busy then
            if ImGui.Button("Install##mv067",120,28) then DLC054.install(selected.data) end
        end
        return
    end
    local edited=ImGui.InputText("Model##mv067",model,70)
    if type(edited)=="string" and edited~=model then
        VehicleMarket055.modelNames[item.slug]=edited
        ModVerse067.ready[selected.key]=false
    end
    local busy=ModVerse067.loading[selected.key]
    if ModVerse070.dlcGate.blocked then
        ImGui.TextColored(1,0.37,0.37,1,"DLC loading stopped. Restart GTA if Cherax reports error 9.")
    elseif ModVerse070.dlcGate.attempted then
        ImGui.TextColored(0.66,0.68,0.77,1,"DLC load requested this session. Further loads are suppressed.")
    end
    if busy then
        ImGui.Text("Loading...")
    else
        if ImGui.Button("Load DLC##mv067",115,29) then ModVerse067.start(selected,false,false) end
        ImGui.SameLine()
        if ImGui.Button("Load & Spawn##mv067",125,29) then ModVerse067.start(selected,true,false) end
        ImGui.SameLine()
        if ImGui.Button("Verify##mv067",80,29) then ModVerse067.start(selected,false,true) end
    end
    if ModVerse067.ready[selected.key] and not busy then
        if ImGui.Button("Spawn##mv067",120,29) then
            ModVerse067.ready[selected.key]=false
            VehicleMarket055.spawn(item,candidate)
        end
    end
    if ModVerse067.status[selected.key] then
        safeTextWrapped(shortText(ModVerse067.status[selected.key],215))
    end
    if VehicleMarket055.spawnStatus[item.slug] then
        safeTextWrapped(shortText(VehicleMarket055.spawnStatus[item.slug],170))
    end
    if ImGui.Button("Copy DLC Path##mv067",150,25) then
        pcall(function() Utils.SetClipBoardText(selected.data.path or DLC054.root,"") end)
        toast("Path copied",1800)
    end
    ImGui.TextColored(0.57,0.6,0.68,1,"Macro: Cherax > Misc > General > Load All DLCs")
    ImGui.TextColored(0.57,0.6,0.68,1,"Spawns locally. Other players may not see this model.")
end

function ModVerse067.renderSpawner()
    -- This view mirrors installed custom DLCs. Cherax's native spawner list is
    -- not extended because the public Lua API provides no insertion function.
    if DLC054.dirty and not DLC054.busy then DLC054.scan() end
    ImGui.Text("Vehicle List")
    if ImGui.BeginTabBar("mv067SpawnerTabs") then
        if ImGui.BeginTabItem("DLC") then
            local all=ModVerse066.allDLCs()
            local rows={}
            for _,r in ipairs(all) do if r.installed and r.data.valid then rows[#rows+1]=r end end
            if ModVerse067.detailOpen then
                ModVerse067.drawDetail(all)
            else
                if ImGui.Button("Refresh##mv067Spawner",105,26) then
                    DLC054.lastScanMs=0;DLC054.scan(true)
                end
                ImGui.SameLine();ImGui.Text(tostring(#rows).." custom DLCs")
                for i,r in ipairs(rows) do
                    if ImGui.Selectable(shortText(r.name,50).."##mv067Spawner"..i,false) then ModVerse067.open(r) end
                end
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function ModVerse066.dlcList(rows)
    if ImGui.Button("Refresh##mv066DLC",85,25) and not DLC054.busy then
        DLC054.lastScanMs=0
        DLC054.scan(true)
        ModVerse066.imgCache={}
    end
    ImGui.SameLine()
    ImGui.Text(tostring(#(DLC054.installed or {})).." installed")
    if #rows==0 then
        ImGui.Text("No DLCs")
        return
    end
    local pages=math.max(1,math.ceil(#rows/ModVerse066.pageSize))
    ModVerse066.page=math.max(1,math.min(ModVerse066.page,pages))
    if ImGui.Button("<##mv066Prev",35,24) then ModVerse066.page=math.max(1,ModVerse066.page-1) end
    ImGui.SameLine();ImGui.Text(tostring(ModVerse066.page).." / "..tostring(pages));ImGui.SameLine()
    if ImGui.Button(">##mv066Next",35,24) then ModVerse066.page=math.min(pages,ModVerse066.page+1) end
    ImGui.Separator()
    local first=(ModVerse066.page-1)*ModVerse066.pageSize+1
    for i=first,math.min(#rows,first+ModVerse066.pageSize-1) do
        local r=rows[i]
        local label=shortText(r.name,29)..(r.installed and "  ●" or "  +").."##mv066row"..tostring(i)
        if ImGui.Selectable(label,r.key==ModVerse066.selectedKey) then
            ModVerse066.selectedKey=r.key
            ModVerse066.showInfo=false
            ModVerse066.photoEdit=false
        end
        -- The row remains selectable. Double-click opens the vehicle detail page.
        if ImGui.IsItemHovered and ImGui.IsMouseDoubleClicked and
           ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked(0) then
            ModVerse067.open(r)
        end
    end
end

function ModVerse066.dlcSelected(row)
    if not row then return end
    local label=ModVerse066.preview(row)
    if ImGui.IsItemHovered and ImGui.IsMouseDoubleClicked and
       ImGui.IsItemHovered() and ImGui.IsMouseDoubleClicked(0) then
        ModVerse067.open(row)
    end
    ImGui.Text("Selected")
    ImGui.Separator()
    ImGui.TextColored(0.78,0.54,1,1,shortText(label or row.name,48))
    local r=row.data
    if row.installed then
        ImGui.TextColored(r.valid and 0.35 or 1,r.valid and 0.95 or 0.55,0.60,1,
            r.valid and "Installed" or "Unverified")
        ImGui.SameLine()
        ImGui.Text(r.managed and "Managed" or "External")
        if r.valid then
            local package=ModVerse066.packageFor(row)
            local candidate={name=r.name,valid=true}
            if package then
                for _,c in ipairs(DLC054.rows or {}) do
                    if c.slug==package.slug and tostring(c.name):lower()==tostring(row.name):lower() then
                        candidate=c;break
                    end
                end
            end
            local key="modverse066-dlc-"..row.key
            local item={slug=key,name=label or row.name}
            local model=VehicleMarket055.modelName(item,candidate)
            local new=ImGui.InputText("Model##mv066Spawn",model,70)
            if type(new)=="string" then VehicleMarket055.modelNames[key]=new end
            local spawnName=VehicleMarket055.modelName(item,candidate)
            if ImGui.Button("Open Vehicle##mv067Open",145,30) then
                ModVerse067.open(row)
            end
            ImGui.SameLine()
            if ImGui.Button("Load & Spawn##mv067Quick",135,30) then
                ModVerse067.open(row)
                ModVerse067.start(row,true)
            end
            if VehicleMarket055.spawnStatus[key] then
                safeTextWrapped(shortText(VehicleMarket055.spawnStatus[key],155))
            end
        end
    else
        ImGui.TextColored(r.valid and 0.45 or 1,r.valid and 0.95 or 0.55,0.65,1,
            r.valid and "Ready to install" or "Invalid RPF")
        if r.valid and not DLC054.busy then
            if ImGui.Button("Install##mv066Install",130,30) then DLC054.install(r) end
            ImGui.SameLine()
            if ImGui.Button("Open##mv067StageOpen",87,30) then ModVerse067.open(row) end
        end
    end
    if DLC054.busy then ImGui.Text("Installing...") end
    if ImGui.Button(ModVerse066.showInfo and "Less##mv066Info" or "Info##mv066Info",80,25) then
        ModVerse066.showInfo=not ModVerse066.showInfo
    end
    ImGui.SameLine()
    if ImGui.Button("Folder##mv066Folder",84,25) then
        pcall(function() Utils.SetClipBoardText(row.installed and r.path or r.source,"") end)
        toast("Path copied",1600)
    end
    if ModVerse066.showInfo then
        local pack=ModVerse066.packageFor(row)
        if pack and pack.meta then
            -- Controls / installation guidance before long description.
            mv153DLCUsageHints({name=label or row.name,description=pack.meta.description or ""})
            if pack.meta.description and pack.meta.description~="" then
                safeTextWrapped(shortText(pack.meta.description,450))
            end
        end
        ImGui.Text(row.installed and (r.managed and "Managed DLC" or "External DLC") or "Staged RPF")
        ImGui.Text(shortText(r.detail or "",115))
        if not row.installed then ImGui.Text(shortText(r.relative or "",105)) end
        ImGui.Text(string.format("%.1f MB",(tonumber(r.size) or 0)/1048576))
        ImGui.Text("Load in Cherax before spawning")
        if ImGui.Button("Copy DLC folder##mv066Dir",135,25) then
            pcall(function() Utils.SetClipBoardText(DLC054.root,"") end)
            toast("DLC folder copied",1600)
        end
    end
end

function ModVerse066.drawDLC()
    if DLC054.dirty and not DLC054.busy then DLC054.scan() end
    local rows=ModVerse066.allDLCs()
    if ModVerse067.detailOpen then
        ModVerse067.drawDetail(rows)
        return
    end
    ModVerse066.selectedRow(rows)
    if ImGui.BeginTable("ModVerseInstalledDLC066",2,ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextColumn()
        ModVerse066.dlcList(rows)
        ImGui.TableNextColumn()
        ModVerse066.dlcSelected(ModVerse066.selectedRow(rows))
        ImGui.EndTable()
    else
        ModVerse066.dlcList(rows)
        ModVerse066.dlcSelected(ModVerse066.selectedRow(rows))
    end
end

function renderCheraxLibrary090(isInstalled)
    if ImGui.BeginTabBar(isInstalled and "MV090InstalledKinds" or "MV090FavoriteKinds") then
        for _,entry in ipairs({{"outfits","Outfits"},{"vehicles","Vehicles"},{"dlcs","Cherax DLCs"},{"themes","Themes"}}) do
            if ImGui.BeginTabItem(entry[2]) then
                if isInstalled then ModVerseCherax090.renderInstalled(entry[1])
                else ModVerseCherax090.renderFavorites(entry[1]) end
                ImGui.EndTabItem()
            end
        end
        ImGui.EndTabBar()
    end
end
function renderLibrary090()
    -- Build 141: legacy GTA5-Mods ASI inventory/favorites remain on disk only.
    -- Only the four documented Cherax catalog families are displayed.
    if ImGui.BeginTabBar("MV090Library") then
        if ImGui.BeginTabItem("Favorites") then
            renderCheraxLibrary090(false)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Installed") then
            renderCheraxLibrary090(true)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Downloads") then
            ModVerseCherax090.renderDownloads()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end
-- Build 147: manual replay of the sliding guided popups. No launch-time popup.
ModVerseTutorial146 = {}
function ModVerseTutorial146.render()
    ImGui.TextColored(1.00,.59,.23,1.0,"MODVERSE QUICK TUTORIAL")
    safeTextWrapped("Choose a guide to see the same animated popup shown after installing content.")
    ImGui.Separator()
    local rows={{"outfits","Outfits"},{"themes","Themes"},{"vehicles","Vehicles"},{"dlcs","DLCs"}}
    for _,row in ipairs(rows) do
        if ImGui.Button("How to use "..row[2].."##MV147"..row[1],190,31) then
            if ModVerseTutorial147 then ModVerseTutorial147.open(row[1],"manual") end
        end
    end
    ImGui.Spacing()
    ImGui.TextColored(.62,.67,.77,1.0,"Tutorials never appear just from loading ModVerse.")
    if ModVerseAssets150 then ModVerseAssets150.renderStatus() end
end

function renderTools090()
    if ImGui.BeginTabBar("MV141More") then
        if ImGui.BeginTabItem("Tutorial") then ModVerseTutorial146.render(); ImGui.EndTabItem() end
        if ImGui.BeginTabItem("About") then ModVerseCredits091.render(); ImGui.EndTabItem() end
        if ImGui.BeginTabItem("Status") then
            ImGui.TextColored(0.70,0.92,0.73,1.0,"Marketplace-only | v1.0.0 Production Build 154")
            safeTextWrapped("Removed legacy native runtime loading, ASI execution and Windows process helpers from this release. Only supported Cherax marketplace integrations remain.")
            safeTextWrapped("GTA5-Mods DLCs support ready-made DLC ZIP packages. Cherax outfits, saved vehicles, DLCs and themes remain available. ASI functionality is not included in this release.")
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- Build 091: DriftGod-style Credits, Public_Urinal portrait and script showcase.
-- This module is isolated from the working marketplace, installer and spawn paths.
-- ═══════════════════════════════════════════════════════════════════════════════════════
ModVerseCredits091 = (function()
    local C = {
        profileUrl = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax/refs/heads/main/DriftGod/assets/Public_Urinal.png",
        fallbackUrl = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax/main/Public_Urinal.png",
        discordUrl = "https://discord.gg/PjZUBMtD3",
        portraitDir = ROOT_DIR .. "assets\\",
        profileFile = ROOT_DIR .. "assets\\Public_Urinal.png",
        driftGodFile = MENU_ROOT .. "\\Lua\\DriftGod\\assets\\Public_Urinal.png",
        portraitStatus = "Not loaded",
        requestStarted = false,
        requestFinished = false,
        cachedPath = nil,
        scripts = {
            {"DriftGod", {0.72, 0.42, 1.00}, "Arcade drifting, scoring, progression, garage, Power Glider and ghost racing."},
            {"Startup", {0.30, 1.00, 0.45}, "Session startup, themes, Lua automation, HUD tools, and protections."},
            {"Essentials", {1.00, 0.78, 0.18}, "Everyday Cherax utilities and quality-of-life tools."},
            {"Themes", {0.30, 0.82, 1.00}, "ClickGUI themes and visual customization."},
            {"BotBeGone", {0.72, 0.42, 1.00}, "Quiet bot and notification cleanup."},
            {"HustleMeter", {1.00, 0.35, 0.45}, "Rolling 1 Day / 7 Days GTA$ tracking with HUD and safety thresholds."},
            {"Flying Cars SA", {0.35, 0.86, 1.00}, "San Andreas-inspired arcade flying vehicles."},
            {"Track Generator", {0.42, 0.82, 1.00}, "Build, save, and load custom stunt tracks."},
            {"Vehicle Paint Presets", {1.00, 0.55, 0.85}, "Fast saved paint and color combinations."},
            {"VelocityVision Studio", {0.72, 0.42, 1.00}, "Cinematic vehicle-camera and showcase tools."},
            {"Minigames", {0.58, 0.42, 1.00}, "Custom multiplayer activities and lobby games."},
            {"WarGames", {0.35, 1.00, 0.62}, "Combat-focused multiplayer minigame sessions."},
        },
    }

    local function safeCall(fn, ...)
        if type(fn) ~= "function" then return false end
        return pcall(fn, ...)
    end
    local function text(s)
        if ImGui and ImGui.Text then safeCall(ImGui.Text, tostring(s or "")) end
    end
    local function colored(s, r, g, b, a)
        if ImGui and ImGui.TextColored then
            safeCall(ImGui.TextColored, r or 1, g or 1, b or 1, a or 1, tostring(s or ""))
        else
            text(s)
        end
    end
    local function wrapped(s)
        if ImGui and ImGui.TextWrapped then
            local ok = safeCall(ImGui.TextWrapped, tostring(s or ""))
            if ok then return end
        end
        text(s)
    end
    local function subtle(s) colored(s, 0.58, 0.58, 0.66, 1) end
    local function same() if ImGui and ImGui.SameLine then safeCall(ImGui.SameLine) end end
    local function spacer() text("") end
    local function isPng(path)
        if type(path) ~= "string" or path == "" then return false end
        local ok, valid = pcall(function()
            local f = io.open(path,"rb")
            if not f then return false end
            local header = f:read(8)
            local bytes = f:seek("end") or 0
            f:close()
            return header == "\137PNG\r\n\26\n" and bytes >= 128 and bytes <= 8*1024*1024
        end)
        return ok and valid == true
    end
    local function findPortrait()
        if C.cachedPath and isPng(C.cachedPath) then return C.cachedPath end
        for _, path in ipairs({C.profileFile, C.driftGodFile}) do
            if isPng(path) then
                C.cachedPath = path
                C.portraitStatus = "Portrait ready (local cache)"
                return path
            end
        end
        return nil
    end
    local function isPngBody(body)
        return type(body) == "string" and #body >= 128 and #body <= 8*1024*1024
            and body:sub(1,8) == "\137PNG\r\n\26\n"
    end
    local function requestPortrait()
        if C.requestStarted or findPortrait() then return end
        if not (Script and Script.QueueJob and Script.Yield and Curl and Curl.Easy) then
            C.portraitStatus = "Profile image unavailable (no Cherax download API)"
            return
        end
        C.requestStarted = true
        C.portraitStatus = "Downloading Public_Urinal portrait..."
        Script.QueueJob(function()
            local ok, err = pcall(function()
                if findPortrait() then return end
                local body, reason = httpGet(C.profileUrl, 12000, nil, nil, "ModVerse-Credits/091")
                if not isPngBody(body) then
                    body, reason = httpGet(C.fallbackUrl, 12000, nil, nil, "ModVerse-Credits/091")
                end
                if not isPngBody(body) then error("PNG unavailable: " .. tostring(reason)) end
                if FileMgr and FileMgr.CreateDir then safeCall(FileMgr.CreateDir, C.portraitDir) end
                local f, writeErr = io.open(C.profileFile, "wb")
                if not f then error("PNG cache write failed: " .. tostring(writeErr)) end
                local writeOk, writeReason = pcall(function() f:write(body) end)
                f:close()
                if not writeOk or not isPng(C.profileFile) then
                    pcall(os.remove, C.profileFile)
                    error("PNG cache verification failed: " .. tostring(writeReason))
                end
                C.cachedPath = C.profileFile
                C.portraitStatus = "Portrait cached for offline reuse"
            end)
            if not ok then
                C.portraitStatus = "Portrait download failed; text credits remain available"
                log("[MV091][CREDITS] " .. tostring(err))
            end
            C.requestFinished = true
        end)
    end
    local function drawPortrait()
        local path = findPortrait()
        if not path then
            requestPortrait()
            subtle("Public_Urinal image: " .. tostring(C.portraitStatus))
            return false
        end
        local srv = textureSrv(path) -- shared, asynchronous Cherax texture cache
        if not srv then
            subtle("Public_Urinal image loading...")
            return false
        end
        if not (ImGui and ImGui.GetCursorPosX and ImGui.SetCursorPosX and ImGui.GetCursorPosY and ImGui.SetCursorPosY) then
            return false
        end
        local okX, saveX = safeCall(ImGui.GetCursorPosX)
        local okY, saveY = safeCall(ImGui.GetCursorPosY)
        if not okX or not okY or type(saveX) ~= "number" or type(saveY) ~= "number" then return false end
        local availW = contentAvail()
        local size = 138
        local wide = (tonumber(availW) or 0) > 440
        if wide then
            safeCall(ImGui.SetCursorPosX, saveX + math.max(250, availW - size - 38))
            safeCall(ImGui.SetCursorPosY, saveY + 8)
        end
        local px, py = cursorScreenPos()
        if not px or px == 0 or not py or py == 0 then
            safeCall(ImGui.SetCursorPosX, saveX)
            safeCall(ImGui.SetCursorPosY, saveY)
            return false
        end
        if ImGui.Dummy then
            safeCall(ImGui.Dummy, size, size)
        elseif ImGui.Button then
            safeCall(ImGui.Button, "##MV091PublicUrinalPortrait", size, size)
        end
        local ok = false
        if ImGui.AddImage then ok = safeCall(ImGui.AddImage, srv, px, py, px+size, py+size) end
        if not ok and ImGui.AddImageRounded then
            ok = safeCall(ImGui.AddImageRounded, srv, px, py, px+size, py+size, 0, 0, 1, 1, 0xFFFFFFFF, 8)
        end
        if wide then
            safeCall(ImGui.SetCursorPosX, saveX)
            safeCall(ImGui.SetCursorPosY, saveY)
        end
        return ok
    end
    local function copyDiscord()
        if Utils and Utils.SetClipBoardText then
            local ok = safeCall(Utils.SetClipBoardText, C.discordUrl, "")
            if ok then return true end
        end
        if Utils and Utils.SetClipboardText then
            local ok = safeCall(Utils.SetClipboardText, C.discordUrl)
            if ok then return true end
        end
        if ImGui and ImGui.SetClipboardText then
            local ok = safeCall(ImGui.SetClipboardText, C.discordUrl)
            if ok then return true end
        end
        return false
    end
    local function openDiscord()
        if Utils and Utils.OpenURL then
            local ok, result = safeCall(Utils.OpenURL, C.discordUrl)
            if ok and result ~= false then return true end
        end
        if Utils and Utils.OpenUrl then
            local ok, result = safeCall(Utils.OpenUrl, C.discordUrl)
            if ok and result ~= false then return true end
        end
        if GUI and GUI.OpenURL then
            local ok, result = safeCall(GUI.OpenURL, C.discordUrl)
            if ok and result ~= false then return true end
        end
        return false
    end
    local function discordButton()
        local pushed = 0
        if ImGui and ImGui.PushStyleColor and ImGuiCol then
            for _, c in ipairs({
                {ImGuiCol.Button, {0.18,0.32,0.72,1.0}},
                {ImGuiCol.ButtonHovered, {0.25,0.42,0.92,1.0}},
                {ImGuiCol.ButtonActive, {0.15,0.26,0.62,1.0}},
            }) do
                if c[1] ~= nil and safeCall(ImGui.PushStyleColor, c[1], c[2][1],c[2][2],c[2][3],c[2][4]) then
                    pushed = pushed + 1
                end
            end
        end
        local clicked = false
        if ImGui and ImGui.Button then
            local ok, pressed = safeCall(ImGui.Button, "OPEN DISCORD & COPY INVITE##MV091CreditsDiscord", -1, 36)
            clicked = ok and pressed == true
        end
        if pushed > 0 and ImGui and ImGui.PopStyleColor then safeCall(ImGui.PopStyleColor, pushed) end
        if clicked then
            local copied = copyDiscord()
            local opened = openDiscord()
            if opened and copied then toast("Discord opened and invite copied", 3300)
            elseif copied then toast("Discord invite copied", 3000)
            elseif opened then toast("Discord opened", 3000)
            else toast("Could not open Discord or copy the invite", 3500) end
        end
    end
    local function renderProjects()
        colored("LIKE MODVERSE?", 0.72,0.42,1.0,1)
        wrapped("Join our Discord for Public_Urinal's other Cherax projects, updates, support and community showcases.")
        discordButton()
        if ImGui and ImGui.Separator then safeCall(ImGui.Separator) end
        colored("OTHER PUBLIC_URINAL PROJECTS", 0.35,0.86,1.0,1)
        local tableOpen = false
        if ImGui and ImGui.BeginTable and ImGui.TableNextRow and ImGui.TableSetColumnIndex then
            local flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
            local ok, started = safeCall(ImGui.BeginTable, "MV091OtherPublicUrinalScripts", 2, flags)
            tableOpen = ok and started == true
        end
        for idx, item in ipairs(C.scripts) do
            if tableOpen then
                if idx % 2 == 1 then safeCall(ImGui.TableNextRow) end
                safeCall(ImGui.TableSetColumnIndex, (idx-1) % 2)
            end
            colored("• " .. item[1],item[2][1],item[2][2],item[2][3],1)
            wrapped(item[3])
            spacer()
        end
        if tableOpen and ImGui and ImGui.EndTable then safeCall(ImGui.EndTable) end
        subtle("All projects shown above are available through the community Discord.")
    end
    function C.render()
        local active, childOpen = true, false
        if ClickGUI and ClickGUI.BeginCustomChildWindow and ClickGUI.EndCustomChildWindow then
            local ok, opened = safeCall(ClickGUI.BeginCustomChildWindow, "Credits")
            if ok and opened == true then childOpen = true
            elseif ok then active = false
            else subtle("Credits child failed; using fallback layout") end
        elseif ImGui and ImGui.BeginChild and ImGui.EndChild then
            local ok, opened = safeCall(ImGui.BeginChild, "MV091CreditsChild", 0, 0, true)
            if ok and opened == true then childOpen = "imgui"
            elseif ok then active = false end
        end
        if active then
            drawPortrait()
            colored("ModVerse",0.72,0.42,1.0,1)
            spacer()
            text("Developed By:")
            same()
            colored("Public_Urinal",0.72,0.42,1.0,1)
            text("Discord:")
            same()
            colored("Public_Urinal",0.42,0.82,1.0,1)
            text("Gamer Tag:")
            same()
            colored("Public Urinal",1.0,0.78,0.18,1)
            text("Version: v" .. SCRIPT_VERSION)
            text("Build: " .. BUILD_ID)
            text("Last Updated: October 17, 2026")
            spacer()
            colored("Purpose",0.72,0.42,1.0,1)
            wrapped("A curated GTA V and Cherax marketplace for vehicles, saved outfits, ClickGUI themes and DLCs, with cached browsing, favorites and local install management. Native ASI loading is disabled in marketplace mode.")
            spacer()
            colored("Development",0.72,0.42,1.0,1)
            text("Public_Urinal - concept, development, UI, testing and marketplace curation.")
            text("Coding Assistance: ChatGPT")
            spacer()
            colored("Special Thanks",1.0,0.78,0.18,1)
            text("Cherax Team - framework and platform support.")
            text("DriftGod - proven saved-vehicle spawning and restoration sequence.")
            text("Community creators and submitters - shared vehicles, themes and other assets.")
            spacer()
            colored("Notes",0.42,0.82,1.0,1)
            wrapped("ModVerse caches marketplace previews locally and validates supported downloads. Vehicle, DLC and outfit compatibility can depend on GTA V Legacy or Enhanced and available Cherax APIs.")
            spacer()
            -- Preserve DriftGod's bottom-position default-collapsed script showcase.
            local showScripts = true
            if ImGui and ImGui.CollapsingHeader then
                local ok, opened = safeCall(ImGui.CollapsingHeader, "Discover More Scripts##MV091")
                showScripts = ok and opened == true
            end
            if showScripts then renderProjects()
            else subtle("Expand Discover More Scripts to see other Public_Urinal Cherax projects.") end
        end
        if childOpen == true then safeCall(ClickGUI.EndCustomChildWindow)
        elseif childOpen == "imgui" then safeCall(ImGui.EndChild) end
    end
    return C
end)()

local function renderMain()
    ImGui.TextColored(0.81,0.58,1.00,1.00,"ModVerse")
    if ModVerseCherax090 and ModVerseCherax090.OutfitPreview101 and UI.activeTab~="Cherax"
        and UI.activeTab~="Library" then
        local pv=ModVerseCherax090.OutfitPreview101
        if pv.clone~=0 or pv.visible or pv.queued then pv.stop("ModVerse tab changed") end
    end
    if ImGui.BeginTabBar("ModVerseMain090") then
        if ImGui.BeginTabItem("Browse") then
            UI.activeTab="Browse"
            if ImGui.BeginTabBar("MV142BrowseSources") then
                if ImGui.BeginTabItem("GTA5-Mods") then
                    renderGTA5Mods090() -- DLC only, no ASI marketplace
                    ImGui.EndTabItem()
                end
                if ImGui.BeginTabItem("Cherax") then
                    renderCherax090() -- outfits / vehicles / DLCs / themes
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            else
                renderGTA5Mods090()
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Cherax") then UI.activeTab="Cherax";renderCherax090();ImGui.EndTabItem() end
        if ImGui.BeginTabItem("Library") then UI.activeTab="Library";renderLibrary090();ImGui.EndTabItem() end
        if ImGui.BeginTabItem("More") then UI.activeTab="Tools";renderTools090();ImGui.EndTabItem() end
        ImGui.EndTabBar()
    end
    if ModVerseTutorial147 and ModVerseTutorial147.useMenuFallback then
        ModVerseTutorial147.render()
    end
end

ClickGUI.AddTab(SCRIPT_NAME, renderMain)
-- First-run: only pinned PNG images are downloaded; marketplace remains usable on failure.
ModVerseAssets150.start()
-- Build 147: Render floating cards on ON_PRESENT even when ClickGUI is closed.
-- Every ImGui operation is guarded so unavailable UI APIs cannot crash a download job.
if EventMgr and EventMgr.RegisterHandler and eLuaEvent and eLuaEvent.ON_PRESENT then
    ModVerseTutorial147.registerOK,ModVerseTutorial147.handler=pcall(EventMgr.RegisterHandler,eLuaEvent.ON_PRESENT,function()
        if ModVerseTutorial147 and ModVerseTutorial147.active then
            local drew,err=pcall(ModVerseTutorial147.render)
            if not drew and not ModVerseTutorial147.errorLogged then
                ModVerseTutorial147.errorLogged=true
                log("[MV147][TUTORIAL][RENDER] "..tostring(err))
            end
        end
    end)
    if not ModVerseTutorial147.registerOK then
        ModVerseTutorial147.handler=nil
        ModVerseTutorial147.useMenuFallback=true
    end
else ModVerseTutorial147.useMenuFallback=true end


-- Cherax-only services remain active for outfits / vehicles / DLCs / themes.
Script.RegisterLooped(function()
    if ModVerseCherax090 and ModVerseCherax090.OutfitPreview098 then ModVerseCherax090.OutfitPreview098.tick() end
    if ModVerseCherax090 and ModVerseCherax090.OutfitPreview101 then ModVerseCherax090.OutfitPreview101.tick() end
    if ModVerseCherax090 and ModVerseCherax090.OutfitNativeGallery114 then ModVerseCherax090.OutfitNativeGallery114.tick() end
    if ModVerseCherax090 and ModVerseCherax090.snatcher then ModVerseCherax090.snatcher.tick() end
    Script.Yield(8)
end)

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
    if ModVerseTutorial147 and ModVerseTutorial147.handler and EventMgr and EventMgr.RemoveHandler then
        pcall(EventMgr.RemoveHandler,ModVerseTutorial147.handler)
        ModVerseTutorial147.handler=nil
    end
    if ModVerseCherax090 and ModVerseCherax090.OutfitNativeGallery114 then
        local gallery=ModVerseCherax090.OutfitNativeGallery114
        pcall(gallery.stop,"Lua unload")
        if gallery.postHandler and EventMgr and EventMgr.RemoveHandler then
            pcall(EventMgr.RemoveHandler,gallery.postHandler)
            gallery.postHandler=nil
        end
    end
    if ModVerseCherax090 and ModVerseCherax090.OutfitPreview101 then
        pcall(ModVerseCherax090.OutfitPreview101.stop,"Lua unload")
    end
    if ModVerseCherax090 and ModVerseCherax090.snatcher then
        ModVerseCherax090.snatcher.enabled=false
        ModVerseCherax090.snatcher.seen={}
    end
    if ModVerseCherax090 and ModVerseCherax090.vehicleSnatcher then
        ModVerseCherax090.vehicleSnatcher.enabled=false
        ModVerseCherax090.vehicleSnatcher.seen={}
    end
    if ModVerseCherax090 and ModVerseCherax090.OutfitPreview098 then
        pcall(ModVerseCherax090.OutfitPreview098.clearPage,"Lua unload")
        pcall(ModVerseCherax090.OutfitPreview098.stop,"Lua unload")
    end
    pcall(function() ClickGUI.RemoveTab(SCRIPT_NAME) end)
end)

log("ModVerse v"..SCRIPT_VERSION.." Build "..BUILD_ID.." Production: marketplace-only Build 154; browser-markup checks removed; no Windows native loader included.")
-- logs-only startup banner (build 138)
-- note: cherax owns the timestamp and [] prefix on each console logger call.
-- note: an initial newline keeps those prefixes above the colored banner lines.
-- note: a separate utf-8 file contains the same banner with no timestamps.
-- eLogColor is a fixed enum, so #FF7900 is unavailable. LIGHTRED is a warmer
-- non-yellow substitute, falling back to RED or WHITE (never YELLOW/BROWN).
ModVerseBanner137 = {
    logPath = ROOT_DIR .. "logs\\startup_banner.txt",
    artColor = "LIGHTRED", -- alternatives: RED, WHITE, LIGHTGRAY, CYAN, LIGHTBLUE, MAGENTA
    separator = "=====================================================================",
    art = {
        "███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗",
        "████╗ ████║██╔═══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝",
        "██╔████╔██║██║   ██║██║  ██║██║   ██║█████╗  ██████╔╝███████╗█████╗  ",
        "██║╚██╔╝██║██║   ██║██║  ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝  ",
        "██║ ╚═╝ ██║╚██████╔╝██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗",
        "╚═╝     ╚═╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝",
    },
    details = {
        "ModVerse - All Your Mods, One Place",
        "Developed By: Public_Urinal",
        "Discord: Public_Urinal",
        "Version: v" .. SCRIPT_VERSION,
        "Build: " .. BUILD_ID,
        "Last Updated: 2026-10-17",
    },
}

function ModVerseBanner137.rows()
    local b = ModVerseBanner137
    local rows = { b.separator, "" }
    for _, art in ipairs(b.art) do rows[#rows+1] = art end
    rows[#rows+1] = ""
    for _, detail in ipairs(b.details) do rows[#rows+1] = detail end
    rows[#rows+1] = ""
    rows[#rows+1] = b.separator
    rows[#rows+1] = ""
    rows[#rows+1] = "Happy Modding ツ"
    rows[#rows+1] = ""
    return rows
end

function ModVerseBanner137.start()
    local b = ModVerseBanner137
    -- save the unprefixed banner without using cherax's console formatter.
    -- if the cherax file writer throws an error, retry with normal file io.
    pcall(function()
        local content = table.concat(b.rows(), "\n") .. "\n"
        FileMgr.CreateDir(ROOT_DIR .. "logs\\")
        local ok, done = pcall(FileMgr.WriteFileContent, b.logPath, content, false)
        if not ok or done == false then
            local f = io.open(b.logPath, "wb")
            if f then f:write(content); f:close() end
        end
    end)
    if not Logger then return end
    local accent = eLogColor and (eLogColor[b.artColor] or eLogColor.RED or eLogColor.WHITE) or nil
    local white  = eLogColor and eLogColor.WHITE or nil

    -- Cherax will still print one timestamp per Logger.Log invocation.
    -- Start the actual content on the next line, unprefixed, as supported by
    -- the user's Build 135 multiline console test. Preserve original colors.
    local parts = {
        { accent, "\n" .. table.concat({b.separator, "", table.unpack(b.art)}, "\n") .. "\n" },
        { white, "\n" .. table.concat(b.details, "\n") .. "\n" },
        { accent, "\n" .. b.separator },
        { white, "\nHappy Modding ツ\n" },
    }
    for _, part in ipairs(parts) do
        local color, message = part[1], part[2]
        local ok = false
        if type(Logger.Log) == "function" and color ~= nil then
            ok = pcall(Logger.Log, color, "", message)
        end
        if not ok and type(Logger.LogInfo) == "function" then
            pcall(Logger.LogInfo, message)
        end
    end
end

ModVerseBanner137.start()
