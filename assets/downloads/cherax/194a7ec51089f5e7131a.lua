-- Smart Console 1.0.1
--
-- Notes for whoever reviews this script.
--
-- What it does: shows the Cherax console in Discord (through a webhook the user
-- makes) and in a popup window inside the game. Cherax has no Lua call that reads
-- the console, so it reads Cherax.log, where the console is written as well, and
-- remembers how far it got. It also lists the old logs in the Logs folder and can
-- delete them when asked.
--
-- What it touches:
--   Network    Only the user's own Discord webhook. A link is accepted only if it is
--              a webhook address on discord.com or discordapp.com (ptb. and canary.
--              too). It is checked once (a GET, nothing is posted) and messages go
--              out only while streaming is on. Nothing is contacted before a webhook
--              has been saved.
--   Files      Reads Cherax.log and lists the Logs folder. When the user types in the
--              Search box (Log files tab) it also reads those logs, read only, to find
--              the lines that contain the typed words. Writes SmartConsole.cfg
--              (settings, the webhook link, hotkeys). Deletes only files named like
--              "10-17-2026-19-31-32 Cherax.log" inside the Logs folder, and only when
--              the user presses Delete or turns on auto-delete (off by default). If
--              Cherax's own delete call fails on a very large log it tries os.remove,
--              then empties the file and tries again.
--   Clipboard  Read when the user presses Paste Webhook (kept only if it is a webhook
--              link). Written by the Join Discord button, which copies an invite.
--   Not used   Natives, script globals, memory access, key polling, os.execute,
--              loadstring, downloaded code. No webhook or token is written in here.
--              The only two links in the file are the Discord invite behind the Join
--              Discord button and the logo picture shown on the messages.
--
-- Worth knowing: console lines can include player names, Rockstar IDs and IP
-- addresses, and they go only to the user's own webhook. A webhook link that shows
-- up inside a line is replaced before sending, and mentions are switched off.
-- Every callback Cherax makes into the script runs through Try() (a pcall), so an
-- error is logged once and everything else keeps working.
--
-- Layout, top to bottom: settings and state, message filter, helpers, webhook
-- check and posting, reading the log, building messages, log file manager, log search, popup
-- console, buttons and hotkeys, tabs.
--
-- To try it: Console tab > Paste Webhook From Clipboard > Start Streaming > Send
-- Test Line. The line should show up in the channel. Settings save on every change.
--
-- Version numbers: MAJOR.MINOR.PATCH (fix / new feature / something breaks old setups).

local VERSION     = "1.0.1"

local SCRIPT_NAME = "Smart Console"
local LOG_NAME    = "Cherax.log"
local LOGS_DIR    = "Logs"               -- Cherax moves each finished log in here
local CFG_NAME    = "SmartConsole.cfg"
local OLD_CFG_NAME = "DiscordConsole.cfg"  -- this script's name before it was called Smart Console: read once if the new file is missing
local OWN_TAG     = "[SmartConsole]"     -- our own log lines carry this and are never posted back
local TEST_MARK   = "Test line from Smart Console"   -- start of the line Send Test Line writes
local HOTKEY_PREFIX = "hk_"              -- hotkey lines in the settings file: hk_<feature id>=<key codes>

-- How every message shows up in Discord. Sent with each post, so it works on any
-- webhook and never changes the webhook itself. Discord needs a DIRECT image link
-- (i.imgur.com/<id>.png), not the imgur.com page.
local WEBHOOK_NAME   = "Smart Console"
local WEBHOOK_AVATAR = "https://i.imgur.com/Z5Y1n0c.png"
local HOOK_RETRY_MS = 15000              -- re-check a webhook this often while Discord cannot be reached
local HOOK_GONE     = "it was deleted"   -- what a "does not exist" answer from Discord means
local DISCORD_INVITE = "https://discord.gg/RVmH2bmUUG"   -- the Smart Console Discord: copied to the clipboard by the Join Discord button

-- Log clean-up
local DEFAULT_DAYS     = 7
local MIN_DAYS         = 1
local MAX_DAYS         = 365
local SCAN_EVERY_MS    = 30000            -- refresh the file list this often while a tab that shows it is open
local PRUNE_EVERY_MS   = 6 * 3600 * 1000  -- re-check for old logs this often while auto-delete is on
local PRUNE_FIRST_MS   = 10000            -- first check this long after the script loads
local PRUNE_ON_MS      = 1000             -- ... after auto-delete is switched on
local PRUNE_DAYS_MS    = 10000            -- ... after the number of days stops changing (so typing 30 never deletes at 3)

local POLL_MS        = 1000    -- one look at the log + at most one post per second
local MAX_MESSAGE    = 1900    -- Discord's limit is 2000; the rest is the code-block wrapper
local MAX_EMBED      = 3900    -- Discord's embed description limit is 4096
local MAX_LINE       = 400     -- longer console lines are cut with an ellipsis
local MAX_QUEUE      = 400     -- lines waiting to be posted; beyond this the oldest are dropped
local MAX_READ       = 262144  -- bytes taken from the log per look (256 KB); a spam burst is skipped past
local FORCE_CUT      = 16384   -- an unterminated line this long is taken anyway
local WAIT_MS        = 15000   -- how long one post may take before we stop waiting on it
local MAX_BACKOFF_MS = 30000

-- Popup console
local POPUP_LINES    = 600     -- lines kept in the window
local POPUP_BACKLOG  = 40960   -- bytes of recent history shown when it opens (about 300 lines)
local POPUP_POLL_MS  = 300
local POPUP_MAX_LINE = 1000

local ESC = string.char(27)

-- The ways a message can be sent. Exactly one is active (Settings).
local MSG_TYPES = {
    { id = "code",  label = "Code block" },
    { id = "ansi",  label = "Code block colored" },
    { id = "plain", label = "Plain text" },
    { id = "embed", label = "Embed" },
}

local function IsMsgType(id)
    for i = 1, #MSG_TYPES do
        if MSG_TYPES[i].id == id then return true end
    end
    return false
end

-- ============================================================================
--  State
-- ============================================================================
local DC = {
    url        = "",       -- webhook URL ("" = none)
    enabled    = false,    -- Stream switch
    filters    = {},       -- Settings > Message filter: id -> false when that kind is switched off
    msgType    = "ansi",   -- one of MSG_TYPES
    emojis     = false,    -- put an emoji in front of matching lines (plain text / embed only)
    sortBySize = false,    -- Log files tab: false = newest first, true = largest first
    showDelete = false,    -- Log files tab: a Delete button on every row
    autoDelete = false,    -- delete old logs automatically
    days       = DEFAULT_DAYS,
    saved      = nil,      -- the settings text last written (or read) - used to spot changes
    pendingHotkeys = {},   -- hotkeys read from the settings file, applied once the features exist: id -> "116,117"
    hotkeyLines = function() return {} end,   -- replaced in the Hotkeys section: the current bindings as settings lines

    -- Is the pasted webhook real? Checked with a GET (no message is sent).
    --   state: "none" (no url) | "checking" | "ok" | "bad" (Discord says it does not exist) | "offline" (could not ask)
    hook       = { state = "none", url = "", why = "", retryAt = 0 },

    pos        = nil,      -- bytes of the log already consumed (nil = not placed yet)
    queue      = {},       -- parsed lines waiting to be posted: { text = "...", colour = 37 }
    dropped    = 0,        -- lines thrown away (queue full / burst) since the last notice
    holdUntil  = 0,        -- no post before this time (rate limit / backoff)
    failures   = 0,
    inflight   = {},       -- Curl handles that timed out but may still be running: kept alive on purpose

    -- what the tab shows
    status     = "Off",
    statusBad  = false,
    sent       = 0,        -- lines posted this session
    posts      = 0,
    logBytes   = 0,
    lastError  = "",
}

-- ============================================================================
--  Message filter (Settings > Message filter). Every console line belongs to one
--  kind, decided by its tag; a kind that is switched off is not sent to Discord.
--  All kinds are on by default. The popup console is never filtered.
-- ----------------------------------------------------------------------------
local FILTERS = {
    { id = "errors",     group = "Problems", label = "Errors",
      tip = "[ERROR] lines, including Lua errors from scripts." },
    { id = "warnings",   group = "Problems", label = "Warnings",
      tip = "[WARNING] lines, for example the pool-full warnings." },
    { id = "crashdump",  group = "Problems", label = "Crash dumps",
      tip = "[FATAL] and [STACK] lines the menu writes when the game crashes.\nOne crash can be thousands of lines." },

    { id = "joins",      group = "Players", label = "Players joining and leaving",
      tip = "[Player Joined] and [Player Left]: name, Rockstar ID and IP." },
    { id = "session",    group = "Players", label = "Session events",
      tip = "[Session] lines such as who became Session Host or Script Host." },
    { id = "spectating", group = "Players", label = "Spectating you",
      tip = "[Session] lines saying someone started or stopped spectating you." },
    { id = "rid",        group = "Players", label = "RID joins and invites",
      tip = "[RID Join] and [Game Invite]: people RID-joining you and rejected invites." },
    { id = "timeouts",   group = "Players", label = "Player timeouts",
      tip = "[Player] lines, for example 'X timed out'." },
    { id = "modders",    group = "Players", label = "Modder and alt detection",
      tip = "[Modder Detection] and [Detect Alt Accounts]." },

    { id = "spam",       group = "Protection and attacks", label = "Spam protection",
      tip = "[Spam Protection] blocks of ped and vehicle spam. Very frequent in busy sessions." },
    { id = "protection", group = "Protection and attacks", label = "Protection blocks",
      tip = "[Protection (...)] lines: blocked events, entities and script events." },
    { id = "explosions", group = "Protection and attacks", label = "Explosions",
      tip = "[Explosion] modded explosion detections." },
    { id = "events",     group = "Protection and attacks", label = "Script events",
      tip = "[SGE] script events received from other players." },
    { id = "attacks",    group = "Protection and attacks", label = "Crashes and kicks you send",
      tip = "[Crash] and [Kick] lines for actions you triggered." },
    { id = "network",    group = "Protection and attacks", label = "Network",
      tip = "[Network Bail] and [Network] lines, such as session bails and bounties." },

    { id = "info",       group = "Menu and scripts", label = "Script and menu messages",
      tip = "[INFO] lines: scripts loading and unloading, and everything scripts print." },
    { id = "hotkeys",    group = "Menu and scripts", label = "Hotkeys",
      tip = "[Hotkeys] lines, shown when a hotkey is used." },
    { id = "finder",     group = "Menu and scripts", label = "Matchmaking",
      tip = "[Matchmaking] and [Session Finder] lines." },
    { id = "other",      group = "Menu and scripts", label = "Everything else",
      tip = "Any line that fits none of the kinds above: other scripts' own tags, and lines with no tag." },
}

local TAG_FILTER = {
    ["ERROR"] = "errors", ["WARNING"] = "warnings", ["WARN"] = "warnings",
    ["FATAL"] = "crashdump", ["STACK"] = "crashdump",
    ["INFO"] = "info",
    ["Player Joined"] = "joins", ["Player Left"] = "joins",
    ["RID Join"] = "rid", ["Game Invite"] = "rid",
    ["Player"] = "timeouts",
    ["Modder Detection"] = "modders", ["Detect Alt Accounts"] = "modders",
    ["Spam Protection"] = "spam",
    ["Explosion"] = "explosions",
    ["SGE"] = "events",
    ["Crash"] = "attacks", ["Kick"] = "attacks",
    ["Network Bail"] = "network", ["Network"] = "network",
    ["Hotkeys"] = "hotkeys",
    ["Matchmaking"] = "finder", ["Session Finder"] = "finder",
}

-- Which filter a line belongs to. `body` is the line after the timestamp.
local function FilterOf(tag, body)
    if tag == nil then return "other" end
    if tag == "Session" then
        if body:find("spectating", 1, true) then return "spectating" end
        return "session"
    end
    if tag:sub(1, 10) == "Protection" then return "protection" end      -- Protection, Protection (CREATE), ...
    return TAG_FILTER[tag] or "other"
end

local function FilterOn(id)
    return DC.filters[id] ~= false          -- anything not switched off is on
end

local function CountFiltersOn()
    local n = 0
    for i = 1, #FILTERS do
        if FilterOn(FILTERS[i].id) then n = n + 1 end
    end
    return n
end

local function SetAllFilters(on)
    for i = 1, #FILTERS do DC.filters[FILTERS[i].id] = on end
end

-- ============================================================================
--  Small helpers
-- ============================================================================
local function Log(msg)
    pcall(function() Logger.LogInfo(OWN_TAG .. " " .. msg) end)
end

local function LogErr(msg)
    pcall(function() Logger.LogError(OWN_TAG .. " " .. msg) end)
end

-- Every place the menu calls into this script (a button, a hotkey, a tab, the
-- window, a looped fiber) runs through Try, so one error is reported and the
-- script carries on instead of the call being cut off. Each distinct error is
-- logged ONCE, so a fault that repeats every frame cannot fill the console.
local seenErrors, seenErrorCount = {}, 0

local function ReportError(where, err)
    local key = where .. ": " .. tostring(err)
    if seenErrors[key] then return end
    if seenErrorCount >= 50 then return end           -- a runaway cannot grow this table forever
    seenErrors[key] = true
    seenErrorCount = seenErrorCount + 1
    LogErr("error in " .. key)
end

-- Runs fn(...) protected. Returns true plus what fn returned, or false after
-- reporting the error.
local function Try(where, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        ReportError(where, a)
        return false
    end
    return true, a, b, c
end

-- "5.52.0 EE b10834": the menu version, edition (EE or LE) and build. Logged at load so
-- a problem report says which one it came from.
local function CheraxInfo()
    local ver, ed, bld = "?", "?", "?"
    pcall(function() ver = tostring(Cherax.GetVersion()) end)
    pcall(function() ed = tostring(Cherax.GetEdition()) end)
    pcall(function() bld = tostring(Cherax.GetBuild()) end)
    return ver .. " " .. ed .. " b" .. bld
end

local function NowMs()
    local ok, t = pcall(function() return Time.GetEpocheMs() end)
    if ok and type(t) == "number" then return t end
    return 0
end

local function RootPath(fileName)
    local root = ""
    pcall(function() root = FileMgr.GetMenuRootPath() or "" end)
    if type(root) ~= "string" or root == "" then return nil end
    local last = root:sub(-1)
    if last ~= "/" and last ~= "\\" then root = root .. "\\" end
    return root .. fileName
end

local function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Discord rejects JSON that is not valid UTF-8 ("Invalid JSON"), and the log can
-- carry stray bytes. Replace each bad byte with "?".
local function CleanUtf8(s)
    if utf8 ~= nil and type(utf8.len) == "function" then
        for _ = 1, 64 do
            local n, bad = utf8.len(s)
            if n ~= nil then return s end
            s = s:sub(1, bad - 1) .. "?" .. s:sub(bad + 1)
        end
    end
    -- no utf8 library, or a very broken line: keep plain ASCII only
    return (s:gsub("[\128-\255]", "?"))
end

local function JsonString(s)
    s = s:gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' end
        if c == "\\" then return "\\\\" end
        if c == "\n" then return "\\n" end
        if c == "\r" then return "\\r" end
        if c == "\t" then return "\\t" end
        return string.format("\\u%04x", c:byte())
    end)
    return '"' .. s .. '"'
end

-- ============================================================================
--  Webhook URL
-- ============================================================================
-- Accepts only a real Discord webhook, so a typo or a stray clipboard never turns
-- into requests to some other host. Returns the cleaned URL, or nil.
local function ParseWebhook(text)
    local url = Trim(text)
    url = url:gsub("%?.*$", "")     -- ?wait=... / ?thread_id=... are not needed
    local host, id, token = url:match("^https://([%w%.]+)/api/webhooks/(%d+)/([%w_%-]+)$")
    if host == nil then
        host, id, token = url:match("^https://([%w%.]+)/api/v%d+/webhooks/(%d+)/([%w_%-]+)$")
    end
    if host == nil then return nil end
    host = host:lower()
    if host ~= "discord.com" and host ~= "discordapp.com" and host ~= "ptb.discord.com"
       and host ~= "canary.discord.com" then
        return nil
    end
    return "https://" .. host .. "/api/webhooks/" .. id .. "/" .. token
end

local function MaskedUrl()
    local id = DC.url:match("/webhooks/(%d+)/")
    if id == nil then return "none" end
    return "..webhooks/" .. id .. "/********"
end

-- ============================================================================
--  Saved settings - "key=value" lines
--
--  Nothing calls "save". A watcher (see Housekeeping) compares the settings text
--  once a second and writes the file only when it differs, so every switch is
--  remembered whichever way it was changed.
-- ============================================================================
local function Bool(v) return v and "1" or "0" end

local function ClampDays(n)
    n = tonumber(n)
    if n == nil then return DEFAULT_DAYS end
    n = math.floor(n)
    if n < MIN_DAYS then return MIN_DAYS end
    if n > MAX_DAYS then return MAX_DAYS end
    return n
end

local function Serialize()
    local out = {
        "url=" .. DC.url,
        "enabled=" .. Bool(DC.enabled),
        "msgType=" .. DC.msgType,
        "emojis=" .. Bool(DC.emojis),
        "sortBySize=" .. Bool(DC.sortBySize),
        "showDelete=" .. Bool(DC.showDelete),
        "autoDelete=" .. Bool(DC.autoDelete),
        "days=" .. tostring(DC.days),
    }
    for i = 1, #FILTERS do
        out[#out + 1] = "f_" .. FILTERS[i].id .. "=" .. Bool(FilterOn(FILTERS[i].id))
    end
    -- Hotkeys. Cherax restores its own settings before Lua scripts have registered
    -- their features, so a binding for a script's button is lost on restart; we keep
    -- ours here and re-apply it once the buttons exist (see the Hotkeys section).
    local okHk, hk = pcall(DC.hotkeyLines)
    if okHk and type(hk) == "table" then
        for i = 1, #hk do out[#out + 1] = hk[i] end
    end
    return table.concat(out, "\n") .. "\n"
end

-- Writes the settings file if (and only if) something changed since the last
-- write. Returns true when it wrote.
local function SaveIfChanged()
    local text = Serialize()
    if text == DC.saved then return false end
    local path = RootPath(CFG_NAME)
    if path == nil then return false end
    local ok, wrote = pcall(FileMgr.WriteFileContent, path, text, false)
    if ok and wrote ~= false then
        DC.saved = text      -- our own text, not re-read: a text-mode write may change line endings
        return true
    end
    return false
end

local function LoadConfig()
    DC.saved = nil
    local path = RootPath(CFG_NAME)
    local migrated = false
    if path ~= nil then
        local ok, text = pcall(function()
            if FileMgr.DoesFileExist(path) then return FileMgr.ReadFileContent(path) end
            -- First run under the new name: take everything from the old file name. The
            -- old file is left where it is; the new one is written a moment later.
            local old = RootPath(OLD_CFG_NAME)
            if old ~= nil and FileMgr.DoesFileExist(old) then
                migrated = true
                return FileMgr.ReadFileContent(old)
            end
            return nil
        end)
        if ok and type(text) == "string" and text ~= "" then
            local cfg = {}
            for line in text:gmatch("[^\r\n]+") do
                local k, v = line:match("^([%w_]+)=(.*)$")      -- filter keys are f_<id>, with an underscore
                if k ~= nil then cfg[k] = v end
            end
            DC.url = ParseWebhook(cfg.url or "") or ""      -- a stored URL that is not a Discord webhook is dropped
            if cfg.emojis     ~= nil then DC.emojis     = cfg.emojis == "1" end
            if cfg.sortBySize ~= nil then DC.sortBySize = cfg.sortBySize == "1" end
            if cfg.showDelete ~= nil then DC.showDelete = cfg.showDelete == "1" end
            if cfg.autoDelete ~= nil then DC.autoDelete = cfg.autoDelete == "1" end
            if cfg.days       ~= nil then DC.days       = ClampDays(cfg.days) end
            if cfg.msgType ~= nil and IsMsgType(cfg.msgType) then
                DC.msgType = cfg.msgType
            elseif cfg.colours == "0" then
                DC.msgType = "code"        -- the first version had a "Colours" switch; off meant a plain code block
            end
            -- Message filter. The first versions had one "Errors and warnings only" switch;
            -- it becomes "everything off except errors and warnings" unless the filters were saved.
            local savedFilters = false
            for i = 1, #FILTERS do
                local v = cfg["f_" .. FILTERS[i].id]
                if v ~= nil then
                    DC.filters[FILTERS[i].id] = (v == "1")
                    savedFilters = true
                end
            end
            if not savedFilters and cfg.errorsOnly == "1" then
                SetAllFilters(false)
                DC.filters.errors = true
                DC.filters.warnings = true
            end
            -- Hotkeys: only remembered here; they are applied once the buttons exist.
            DC.pendingHotkeys = {}
            for k, v in pairs(cfg) do
                if k:sub(1, #HOTKEY_PREFIX) == HOTKEY_PREFIX then
                    DC.pendingHotkeys[k:sub(#HOTKEY_PREFIX + 1)] = v
                end
            end
            -- Resume streaming only when there is a webhook to stream to.
            DC.enabled = (cfg.enabled == "1") and DC.url ~= ""
            -- "" never equals the settings text, so a migrated config is written to the new file at once.
            DC.saved = migrated and "" or (text:gsub("\r", ""))
        end
    end
    -- No file yet: start from the defaults and create the file on the first change.
    if DC.saved == nil then DC.saved = Serialize() end
end

-- ============================================================================
--  Reading the log
-- ============================================================================
-- Console tag -> colour code (30 grey, 31 red, 32 green, 33 yellow, 34 blue,
-- 35 pink, 36 cyan, 37 white). Discord's ```ansi blocks use the codes directly;
-- the popup console maps them to ImGui colours.
local TAG_COLOURS = {
    ["ERROR"]            = 31,
    ["WARNING"]          = 33,
    ["WARN"]             = 33,
    ["INFO"]             = 37,
    ["Player Joined"]    = 32,
    ["Player Left"]      = 33,
    ["Modder Detection"] = 35,
}

local ANSI_RGB = {
    [30] = { 0.50, 0.50, 0.56 },
    [31] = { 1.00, 0.42, 0.42 },
    [32] = { 0.40, 0.90, 0.50 },
    [33] = { 1.00, 0.82, 0.35 },
    [35] = { 0.95, 0.55, 0.90 },
    [36] = { 0.45, 0.85, 0.95 },
    [37] = { 0.90, 0.90, 0.93 },
}

-- Emojis for Plain text and Embed messages (Settings > Include emojis). The FIRST
-- rule that matches a line wins; a line that matches none gets no emoji. A rule
-- matches when ALL of its conditions hold:
--   tag       = the console tag, e.g. "ERROR" for "[ERROR] ..."
--   tagPrefix = the tag starts with this, e.g. "Protection (" for every Protection (...) tag
--   find      = plain text that must appear in the line
-- Some emojis carry \u{FE0F}, the selector that makes them draw as a picture
-- rather than a plain symbol.
local EMOJI_RULES = {
    { tag = "ERROR",                        emoji = "\u{274C}" },            -- cross mark
    { tag = "Player Joined",                emoji = "\u{1F7E2}" },           -- green circle
    { tag = "Player Left",                  emoji = "\u{1F534}" },           -- red circle
    { tag = "Session", find = "is now Session Host",     emoji = "\u{1F451}" },          -- crown
    { tag = "Session", find = "is now Script Host",      emoji = "\u{1F5A5}\u{FE0F}" },  -- desktop computer
    { tag = "Session", find = "no longer spectating",    emoji = "\u{1F648}" },          -- see-no-evil monkey
    { tag = "Session", find = "is spectating you",       emoji = "\u{1F440}" },          -- eyes
    { tag = "Player", find = "timed out",   emoji = "\u{23F1}\u{FE0F}" },    -- stopwatch
    { tag = "Modder Detection",             emoji = "\u{1F6A9}" },           -- triangular flag
    { tag = "Spam Protection",              emoji = "\u{1F6E1}\u{FE0F}" },   -- shield
    { tagPrefix = "Protection (",           emoji = "\u{1F6E1}\u{FE0F}" },   -- shield
    { tag = "Explosion",                    emoji = "\u{1F4A3}" },           -- bomb
    { tag = "Crash",                        emoji = "\u{2620}\u{FE0F}" },    -- skull and crossbones
    { tag = "Kick",                         emoji = "\u{1F462}" },           -- boot
    { tag = "Network Bail",                 emoji = "\u{1F6AA}" },           -- door
    { tag = "Network", find = "Bounty",     emoji = "\u{1F3AF}" },           -- bullseye
    { find = "Successfully",                emoji = "\u{2705}" },            -- check mark
}

local function EmojiFor(e)
    for i = 1, #EMOJI_RULES do
        local r = EMOJI_RULES[i]
        if (r.tag == nil or r.tag == e.tag)
           and (r.tagPrefix == nil or (e.tag ~= nil and e.tag:sub(1, #r.tagPrefix) == r.tagPrefix))
           and (r.find == nil or e.body:find(r.find, 1, true)) then
            return r.emoji
        end
    end
    return nil
end

-- Hides anything shaped like a Discord webhook URL, so one printed in the console
-- can never leak into the channel.
local function Redact(text)
    text = text:gsub("[Dd][Ii][Ss][Cc][Oo][Rr][Dd]%a*%.com/api/[%w_%-/%.]*webhooks/[%w_%-/]+", "[webhook hidden]")
    return text
end

-- One raw log line -> { clock, rest, tag, colour } with no filtering and no
-- redaction (the popup console shows everything as it is), or nil for a blank
-- line. Lines look like:  [2026-10-21 17:54:25.374] [INFO] Loading 'Startup.lua'
local function ParseConsoleLine(raw)
    raw = raw:gsub("\r$", "")
    if raw:match("^%s*$") then return nil end

    local clock, rest = raw:match("^%[%d+%-%d+%-%d+ (%d+:%d+:%d+)%.%d+%] (.*)$")
    if clock == nil then
        clock, rest = nil, raw           -- a continuation line with no timestamp
    end

    local tag = rest:match("^%[([^%]]+)%]")
    rest = CleanUtf8(rest)
    -- Escape characters would be read as colour codes; tabs and other control
    -- characters wreck alignment.
    rest = rest:gsub(ESC, "")
    rest = rest:gsub("%c", " ")
    return { clock = clock, rest = rest, tag = tag,
             colour = (tag and TAG_COLOURS[tag]) or (tag and 36) or 37 }
end

-- One raw log line -> the entry that gets queued for Discord, or nil when it
-- should not be posted (our own lines, lines the filter drops).
local function ParseLine(raw)
    if raw:find(OWN_TAG, 1, true) then return nil end   -- never feed on ourselves
    local e = ParseConsoleLine(raw)
    if e == nil then return nil end
    -- The test line always goes through, so Send Test Line cannot be defeated by a filter.
    if not raw:find(TEST_MARK, 1, true) and not FilterOn(FilterOf(e.tag, e.rest)) then return nil end

    local rest = Redact(e.rest)
    -- A ``` inside a line would close the code block early.
    rest = rest:gsub("```", "'''")
    -- Cut on a character boundary: a split UTF-8 character would make Discord refuse the message.
    if #rest > MAX_LINE then rest = CleanUtf8(rest:sub(1, MAX_LINE)) .. "..." end

    local text = rest
    if e.clock ~= nil then text = e.clock .. " " .. rest end
    return { clock = e.clock, body = rest, tag = e.tag, colour = e.colour, text = text }
end

local function Enqueue(entry)
    local q = DC.queue
    q[#q + 1] = entry
    while #q > MAX_QUEUE do
        table.remove(q, 1)
        DC.dropped = DC.dropped + 1
    end
end

-- Reads the whole lines the live log gained since `st.pos` (a table holding the
-- position: the stream uses DC, the popup console uses its own). Opens and closes
-- the file on every look so we never hold it.
--   backlog: when the position is not placed yet, start this many bytes back from
--            the end instead of at the end (the popup shows recent history).
-- Returns ok, reason, lines, burst. `burst` means part of a spam burst was skipped.
-- The reading half of TailLog. It never closes the file: the caller does, whatever
-- happens in here.
local function TailRead(f, st, backlog)
    local size = f:seek("end")
    if size == nil or size < 0 then return false, "cannot size " .. LOG_NAME end
    DC.logBytes = size

    local skipPartial = false
    if st.pos == nil then
        if backlog ~= nil and size > 0 then
            st.pos = math.max(0, size - backlog)
            skipPartial = st.pos > 0         -- landed mid-line: the first fragment is junk
        else
            -- First look after switching on: start at the end, never replay history.
            st.pos = size
            return true, nil, {}, false
        end
    end
    -- Cherax started a new log (or it was cleared): read the new one from the top.
    if size < st.pos then st.pos = 0; skipPartial = false end

    local pending = size - st.pos
    if pending <= 0 then return true, nil, {}, false end

    local burst = false
    if pending > MAX_READ then
        -- A burst bigger than we can handle. Skip to the most recent part.
        burst = true
        st.pos = size - MAX_READ
        pending = MAX_READ
        skipPartial = true
    end

    f:seek("set", st.pos)
    local data = f:read(pending)
    if data == nil or data == "" then return true, nil, {}, burst end

    -- Only whole lines. The cut is the last newline, so a UTF-8 character is
    -- never split and a half-written line waits for the next look.
    local cut = data:match("^.*()\n")
    if cut == nil then
        if #data >= FORCE_CUT then cut = #data else return true, nil, {}, burst end
    end
    st.pos = st.pos + cut

    local lines, first = {}, true
    for line in data:sub(1, cut):gmatch("[^\n]+") do
        if first and skipPartial then
            first = false           -- drop the fragment
        else
            first = false
            lines[#lines + 1] = line
        end
    end
    return true, nil, lines, burst
end

local function TailLog(st, backlog)
    local path = RootPath(LOG_NAME)
    if path == nil then return false, "cannot find the Cherax folder" end

    local okOpen, f, err = pcall(function() return io.open(path, "rb") end)
    if not okOpen then return false, "io library unavailable: " .. tostring(f) end
    if not f then return false, "cannot open " .. LOG_NAME .. ": " .. tostring(err) end

    local ok, a, b, c, d = pcall(TailRead, f, st, backlog)
    -- Closed even when reading raised an error: a handle left open would later stop
    -- Windows deleting the file.
    pcall(function() f:close() end)
    if not ok then
        ReportError("reading " .. LOG_NAME, a)
        return false, "cannot read " .. LOG_NAME .. ": " .. tostring(a)
    end
    return a, b, c, d
end

-- Reads what the log gained since last time and queues it for Discord.
local function ReadNewLog()
    local ok, why, lines, burst = TailLog(DC)
    if not ok then return false, why end
    if burst then DC.dropped = DC.dropped + 1 end
    for i = 1, #lines do
        local entry = ParseLine(lines[i])
        if entry ~= nil then Enqueue(entry) end
    end
    return true
end

-- ============================================================================
--  Building a message
--
--  Four shapes, chosen in Settings (DC.msgType):
--    code   a plain ``` block
--    ansi   a ```ansi block - Discord colours the lines
--    plain  ordinary chat text, nothing added
--    embed  an embed card; its stripe is red if any line is an error, yellow for a warning
-- ============================================================================
local EMBED_RED, EMBED_YELLOW, EMBED_DEFAULT = 0xED4245, 0xFEE75C, 0x5865F2

-- Plain text and embeds are rendered as Markdown, so a line like "Rupsik_13 and
-- foo_bar" or "*x*" would come out italic and "[a](b)" as a link. A backslash in
-- front of each Markdown character makes Discord show the text exactly as logged.
local function EscapeMd(s)
    s = s:gsub("[\\%*_~|`<>%[%]]", "\\%0")
    if s:match("^[#%-+]") then s = "\\" .. s end      -- a heading / list marker at the start of a line
    return s
end

local function WrapCode(body)
    if DC.msgType == "ansi" then return "```ansi\n" .. body .. "\n```" end
    return "```\n" .. body .. "\n```"
end

local function RenderEntry(e)
    local mt = DC.msgType
    if mt == "ansi" then
        if e.clock ~= nil then
            return ESC .. "[30m" .. e.clock .. " " .. ESC .. "[" .. e.colour .. "m" .. e.body
        end
        return ESC .. "[" .. e.colour .. "m" .. e.body
    end
    if mt == "code" then return e.text end

    -- plain / embed
    local line = EscapeMd(e.text)
    if DC.emojis then
        local em = EmojiFor(e)
        if em ~= nil then line = em .. " " .. line end
    end
    return line
end

-- Who the message is "from" in Discord. Sent with every post, so any webhook shows
-- up as Smart Console with the logo, without touching the webhook itself.
local function IdentityJson()
    return '"username":' .. JsonString(WEBHOOK_NAME) .. ',"avatar_url":' .. JsonString(WEBHOOK_AVATAR)
end

local function BuildBody(content, suppressEmbeds)
    -- allowed_mentions.parse = [] switches every ping off, whatever the text says.
    -- flags 4 = SUPPRESS_EMBEDS, so a link in a plain-text line does not unfurl.
    local flags = suppressEmbeds and ',"flags":4' or ""
    return '{' .. IdentityJson() .. ',"content":' .. JsonString(content) .. flags .. ',"allowed_mentions":{"parse":[]}}'
end

local function BuildEmbedBody(description, colour)
    return '{' .. IdentityJson() .. ',"embeds":[{"description":' .. JsonString(description) .. ',"color":'
        .. string.format("%d", colour) .. '}],"allowed_mentions":{"parse":[]}}'
end

-- Takes lines from the FRONT of the queue until the message is full. Does not
-- remove them: the caller removes `count` lines only after Discord accepted it.
-- Returns the JSON body to post, and how many queued lines it carries.
local function BuildBatch()
    local q = DC.queue
    local mt = DC.msgType
    local isCode = (mt == "code" or mt == "ansi")
    local limit = (mt == "embed") and MAX_EMBED or MAX_MESSAGE
    local parts, used, count = {}, 0, 0
    if isCode then used = #WrapCode("") end

    if DC.dropped > 0 then
        local note = "... some console lines were skipped (too fast to post)"
        if mt == "ansi" then note = ESC .. "[33m" .. note end
        parts[1] = note
        used = used + #note + 1
    end

    for i = 1, #q do
        local line = RenderEntry(q[i])
        local need = #line + (#parts > 0 and 1 or 0)
        if used + need > limit then break end
        parts[#parts + 1] = line
        used = used + need
        count = i
    end
    if count == 0 and #q == 0 and #parts == 0 then return nil, 0 end
    if count == 0 and #q > 0 then
        -- One line alone is bigger than a message: cut it hard so we can never stall.
        local line = RenderEntry(q[1])
        parts[#parts + 1] = line:sub(1, limit - used)
        count = 1
    end

    local text = table.concat(parts, "\n")
    if isCode then return BuildBody(WrapCode(text)), count end
    if mt == "plain" then return BuildBody(text, true), count end

    -- embed: the stripe shows the worst thing in the batch
    local colour = EMBED_DEFAULT
    for i = 1, count do
        local tag = q[i].tag
        if tag == "ERROR" then colour = EMBED_RED; break end
        if (tag == "WARNING" or tag == "WARN") and colour ~= EMBED_RED then colour = EMBED_YELLOW end
    end
    return BuildEmbedBody(text, colour), count
end

-- ============================================================================
--  Talking to Discord
-- ============================================================================
-- Keeps a Curl handle (and the body it may still be reading) from being collected
-- while a request could be using it.
local function Park(curl, body)
    DC.inflight[#DC.inflight + 1] = { curl = curl, body = body }
    if #DC.inflight > 8 then table.remove(DC.inflight, 1) end
end

-- One request to Discord, run on a looped fiber (Script.Yield is allowed there).
-- body == nil makes it a GET. Returns reply, code, finished[, error]. finished is
-- false when Discord did not answer in time, or something raised while the request
-- was in flight; the handle is parked either way.
local function Send(url, body)
    local curl = Curl.Easy()
    local okSend, finished, code, reply = pcall(function()
        curl:DisableErrorLog()
        curl:Setopt(eCurlOption.CURLOPT_URL, url)
        if body ~= nil then
            curl:AddHeader("Content-Type: application/json")
            curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, body)
        end
        curl:Perform()

        local waited = 0
        while not curl:GetFinished() and waited < WAIT_MS do
            Script.Yield(100)
            waited = waited + 100
        end
        if not curl:GetFinished() then return false end
        local c, r = curl:GetResponse()
        return true, c, tostring(r or "")
    end)
    if not okSend then
        Park(curl, body)
        ReportError("talking to Discord", finished)
        return "", nil, false, tostring(finished)
    end
    if not finished then
        Park(curl, body)
        return "", nil, false
    end
    return reply, code, true
end

-- Is the pasted URL a webhook that exists? A GET on it answers with the webhook's
-- details and sends nothing. Discord only reveals its id, the channel's ID NUMBER,
-- the server's ID number and the webhook's own name: there is no channel NAME for
-- an ordinary webhook, so "connected" is all there is to show.
local function VerifyWebhook()
    local h = DC.hook
    h.state = "checking"
    local reply, code, finished, err = Send(DC.url, nil)

    local function offline(why)
        h.state = "offline"
        h.why = why
        h.retryAt = NowMs() + HOOK_RETRY_MS
    end

    if not finished then return offline(err and "could not ask Discord" or "Discord did not answer") end

    local retry = reply:match('"retry_after"%s*:%s*([%d%.]+)')
    if retry ~= nil then return offline("rate limited by Discord") end

    if reply:match('^%s*{%s*"message"') then
        local msg = reply:match('"message"%s*:%s*"([^"]*)"') or "unknown error"
        if reply:find('"code"%s*:%s*10015') or reply:find('"code"%s*:%s*50027')
           or msg:find("Unknown Webhook", 1, true) or msg:find("Invalid Webhook Token", 1, true) then
            h.state = "bad"
            h.why = HOOK_GONE
            return
        end
        return offline("Discord: " .. msg)
    end

    if reply:find('"channel_id"', 1, true) and reply:find('"id"', 1, true) then
        h.state = "ok"
        h.why = ""
        h.channelId = reply:match('"channel_id"%s*:%s*"(%d+)"')
        h.name = reply:match('"name"%s*:%s*"([^"]*)"')
        return
    end
    return offline(reply == "" and "no answer from Discord" or "unexpected answer from Discord")
end

-- Called every tick: starts the check when a URL is new, and retries it while
-- Discord could not be reached.
local function CheckWebhook()
    if DC.url == "" then
        if DC.hook.state ~= "none" then DC.hook = { state = "none", url = "", why = "", retryAt = 0 } end
        return
    end
    if DC.hook.url ~= DC.url then
        DC.hook = { state = "checking", url = DC.url, why = "", retryAt = 0 }
    end
    local h = DC.hook
    if h.state == "checking" or (h.state == "offline" and NowMs() >= h.retryAt) then
        VerifyWebhook()
    end
end

-- Posts one message. Returns:
--   "ok"       accepted
--   "retry"    try again later (rate limit, network); holdUntil already set
--   "drop"     Discord refused this message for good; discard the lines
--   "invalid"  the webhook is gone / wrong; stop streaming
local function Post(body)
    -- ?wait=true makes Discord answer with the created message instead of an empty
    -- 204. That gives a POSITIVE confirmation to look for, so success never has to
    -- be inferred from an empty reply (which a dead network also produces) and
    -- never depends on how this build represents curl result codes.
    local reply, code, finished, err = Send(DC.url .. "?wait=true", body)
    if not finished then
        DC.lastError = err and ("could not send: " .. err) or "Discord did not answer in time"
        return "retry"
    end

    -- Failures are JSON that starts with "message". A 429 also has "retry_after" (seconds).
    local retry = reply:match('"retry_after"%s*:%s*([%d%.]+)')
    if retry ~= nil then
        DC.holdUntil = NowMs() + math.floor((tonumber(retry) or 1) * 1000) + 250
        DC.lastError = "rate limited by Discord, waiting " .. retry .. "s"
        return "retry"
    end

    if reply:match('^%s*{%s*"message"') then
        local msg = reply:match('"message"%s*:%s*"([^"]*)"') or "unknown error"
        DC.lastError = "Discord: " .. msg
        if reply:find('"code"%s*:%s*10015') or msg:find("Unknown Webhook", 1, true)
           or msg:find("Invalid Webhook Token", 1, true) then
            return "invalid"
        end
        return "drop"
    end

    -- The created message always carries its channel id.
    if reply:find('"channel_id"', 1, true) then return "ok" end

    -- Anything else: no reply, HTML from a proxy, a dropped connection.
    if reply == "" then
        DC.lastError = "no answer from Discord (curl " .. tostring(code) .. ")"
    else
        DC.lastError = "unexpected reply: " .. reply:sub(1, 60):gsub("%c", " ")
    end
    return "retry"
end

-- ============================================================================
--  The worker
-- ============================================================================
local function SetStatus(text, bad)
    DC.status = text
    DC.statusBad = bad or false
end

local function Step()
    CheckWebhook()            -- is the pasted URL a real webhook? (a GET, nothing is sent)

    if not DC.enabled then
        DC.pos = nil              -- when switched back on, start from the end again
        if DC.url == "" then SetStatus("Paste a webhook to begin", false)
        else SetStatus("Off", false) end
        return
    end
    if DC.url == "" then
        DC.enabled = false
        SetStatus("Paste a webhook to begin", true)
        return
    end
    if DC.hook.state == "bad" then
        DC.enabled = false
        SetStatus("Webhook is not working - paste a new one", true)
        LogErr("webhook is not working (" .. DC.hook.why .. "); streaming stopped")
        return
    end

    local ok, why = ReadNewLog()
    if not ok then
        SetStatus(why, true)
        DC.lastError = why
        return
    end

    if #DC.queue == 0 and DC.dropped == 0 then
        SetStatus("Streaming - waiting for console output", false)
        return
    end
    if NowMs() < DC.holdUntil then
        SetStatus("Waiting to retry (" .. DC.lastError .. ")", true)
        return
    end

    local body, count = BuildBatch()
    if body == nil then return end

    local result = Post(body)
    if result == "ok" then
        for _ = 1, count do table.remove(DC.queue, 1) end
        DC.dropped = 0
        DC.failures = 0
        DC.sent = DC.sent + count
        DC.posts = DC.posts + 1
        DC.lastError = ""
        if DC.hook.url == DC.url then DC.hook.state = "ok"; DC.hook.why = "" end   -- a message got through: it is connected
        SetStatus("Streaming", false)
    elseif result == "drop" then
        -- Refused for good (e.g. a body Discord will not take): discard so we cannot loop on it.
        for _ = 1, count do table.remove(DC.queue, 1) end
        DC.dropped = 0
        SetStatus("Discord refused a message: " .. DC.lastError, true)
        LogErr("Discord refused a message (" .. DC.lastError .. "); " .. count .. " line(s) dropped")
    elseif result == "invalid" then
        DC.enabled = false
        DC.hook = { state = "bad", url = DC.url, why = HOOK_GONE, retryAt = 0 }
        SetStatus("Webhook is invalid or was deleted - paste a new one", true)
        LogErr("webhook is invalid or deleted (" .. DC.lastError .. "); streaming stopped")
    else
        -- retry: back off, doubling up to a cap. A 429 already set holdUntil from retry_after.
        DC.failures = DC.failures + 1
        if NowMs() >= DC.holdUntil then
            local wait = math.min(MAX_BACKOFF_MS, 1000 * (2 ^ math.min(DC.failures, 5)))
            DC.holdUntil = NowMs() + wait
        end
        SetStatus("Waiting to retry (" .. DC.lastError .. ")", true)
        -- Logged once per streak, not per attempt, so a long outage cannot fill the log.
        if DC.failures == 1 then LogErr("post failed: " .. DC.lastError .. " - retrying") end
    end
end

Try("starting the streaming loop", Script.RegisterLooped, function()
    Script.Yield(POLL_MS)
    local ok, err = pcall(Step)
    if not ok then
        SetStatus("Internal error: " .. tostring(err), true)
        DC.lastError = tostring(err)
        ReportError("streaming", err)
    end
end)

-- ============================================================================
--  Actions the tab calls
-- ============================================================================
local function Toast(text, ms)
    pcall(function() GUI.AddToast(SCRIPT_NAME, text, ms or 3500) end)
end

local function SetEnabled(on)
    if on and DC.url == "" then
        Toast("Paste a webhook first")
        return
    end
    if on and DC.hook.state == "bad" then
        Toast("The webhook is not working - paste a new one", 4500)
        return
    end
    DC.enabled = on
    DC.pos = nil          -- next look starts at the end of the log
    DC.queue = {}
    DC.dropped = 0
    DC.failures = 0
    DC.holdUntil = 0
    Log(on and "streaming on" or "streaming off")
end

local function PasteWebhook()
    local ok, text = pcall(Utils.GetClipBoardText)
    local url = ok and ParseWebhook(text) or nil
    if url == nil then
        Toast("Clipboard is not a Discord webhook URL", 4500)
        return
    end
    DC.url = url              -- the stream fiber checks it with Discord on its next tick
    DC.failures = 0
    DC.holdUntil = 0
    Toast("Webhook saved", 3000)
    Log("webhook saved")
end

local function ClearWebhook()
    DC.url = ""
    DC.enabled = false
    DC.queue = {}
    Log("webhook cleared")
end

-- A line that does NOT carry our tag, so it goes the whole way round: console ->
-- Cherax.log -> this script -> Discord. If it shows up, every link works.
local function SendTestLine()
    if not DC.enabled then
        Toast("Switch Stream on first")
        return
    end
    pcall(Logger.LogInfo, TEST_MARK .. " - if you can read this in Discord, streaming works")
end

-- Copies the Smart Console Discord invite. Nothing is opened for you: you paste the
-- link into your own browser.
local function CopyDiscordInvite()
    local ok = pcall(function() Utils.SetClipBoardText(DISCORD_INVITE, "") end)
    if ok then
        Toast("Discord invite copied - paste it into your browser", 4500)
    else
        Toast("Could not copy the invite. It is " .. DISCORD_INVITE, 8000)
    end
end

-- ============================================================================
--  Log files
--
--  Cherax starts a fresh Cherax.log every launch and moves the old one into the
--  Logs folder as "MM-DD-YYYY-HH-MM-SS Cherax.log". They are never trimmed, so
--  a spammy script can leave gigabytes behind. This lists them (date and size
--  only) and can delete the ones past a chosen age.
--
--  Deleting is deliberately narrow: only files whose name is EXACTLY that
--  pattern, only inside the Logs folder, never the live Cherax.log, and the path
--  is rebuilt from the validated name rather than trusted from the file search.
-- ============================================================================
local MONTHS = { "January", "February", "March", "April", "May", "June", "July",
                 "August", "September", "October", "November", "December" }

local LF = {
    dir        = nil,       -- <menu root>\Logs
    files      = {},        -- { name, path, size, approx, unknown, key, ts, pretty }
    order      = {},        -- the same entries in display order
    sortedBy   = nil,       -- "date" | "size" - which order `order` is in
    total      = 0,
    totalApprox = false,
    current    = nil,       -- size of the live Cherax.log
    currentApprox = false,
    scanned    = false,
    scanAt     = 0,
    needScan   = false,
    seenAt     = -1e12,     -- last time a tab that shows the list was drawn
    status     = "",
    error      = "",
    daysRaw    = DEFAULT_DAYS,   -- what the days box holds (may briefly be 0 while typing)
    lastAuto   = false,
    lastDays   = DEFAULT_DAYS,
    pruneDueAt = nil,       -- when the next clean-up should run (nil = none planned)
    nextPrune  = 0,
    cleanup    = "",        -- result of the last delete / clean-up, shown on the Log files and Settings tabs
    deleteQueue = {},       -- Delete buttons pressed: { name, pretty, size, approx } - done on the housekeeping fiber
}

-- Cherax hands collections back as userdata (a wrapped C++ vector), not as Lua
-- tables, so a plain type()=="table" test rejects them. Normalise anything
-- list-shaped into a plain array of its values.
local function Enum(v)
    local out = {}
    if v == nil then return out end
    local t = type(v)
    if t ~= "table" and t ~= "userdata" then return out end

    pcall(function() for _, x in pairs(v) do out[#out + 1] = x end end)
    if #out > 0 then return out end

    -- No pairs(): probe by index. Prefer the real length, and STOP at the first
    -- gap instead of sweeping a window - these vectors need not bounds-check.
    local n = nil
    pcall(function() n = #v end)
    local limit = (type(n) == "number" and n > 0) and n or 512
    for _, base in ipairs({ 1, 0 }) do      -- 1-based first, then 0-based
        for i = base, base + limit - 1 do
            local ok, x = pcall(function() return v[i] end)
            if not ok or x == nil then break end
            out[#out + 1] = x
        end
        if #out > 0 then return out end
    end
    return out
end

-- "10-17-2026-19-31-32 Cherax.log" -> { y, m, d, H, M, S, key } or nil.
-- Anything that does not match EXACTLY (and make a real date) is not ours to
-- touch: it is listed, but never deleted.
local function ParseLogName(name)
    if type(name) ~= "string" then return nil end
    local mo, d, y, H, M, S = name:match("^(%d%d)%-(%d%d)%-(%d%d%d%d)%-(%d%d)%-(%d%d)%-(%d%d) Cherax%.log$")
    if mo == nil then return nil end
    local t = { m = tonumber(mo), d = tonumber(d), y = tonumber(y),
                H = tonumber(H), M = tonumber(M), S = tonumber(S) }
    if t.m < 1 or t.m > 12 or t.d < 1 or t.d > 31 or t.y < 2000
       or t.H > 23 or t.M > 59 or t.S > 60 then
        return nil
    end
    -- sortable without any clock: later date = bigger number
    t.key = (((t.y * 100 + t.m) * 100 + t.d) * 100 + t.H) * 10000 + t.M * 100 + t.S
    return t
end

local function PrettyDate(t)
    return string.format("%d %s %d", t.d, MONTHS[t.m], t.y)
end

local function FormatSize(bytes, approx)
    bytes = math.floor(bytes or 0)
    local s
    if bytes >= 1073741824 then s = string.format("%.2f GB", bytes / 1073741824)
    elseif bytes >= 1048576 then s = string.format("%.1f MB", bytes / 1048576)
    elseif bytes >= 1024 then s = string.format("%.0f KB", bytes / 1024)
    else s = string.format("%d B", bytes) end
    if approx then s = s .. "+" end
    return s
end

-- Seconds since 1970 for a date read as UTC. Only used when the os library is
-- missing; then both the file date and "now" are compared in UTC, which is off
-- by the timezone offset - irrelevant against a threshold of whole days.
local function CivilToEpoch(y, m, d, H, M, S)
    local yy = y
    if m <= 2 then yy = yy - 1 end
    local era = math.floor(yy / 400)
    local yoe = yy - era * 400
    local mp = (m + 9) % 12                       -- March = 0
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return (era * 146097 + doe - 719468) * 86400 + H * 3600 + M * 60 + S
end

local function UseOs()
    return type(os) == "table" and type(os.time) == "function"
end

-- The file's date in the same clock as NowEpoch(). nil = unknown, and an
-- unknown age is never deleted.
local function FileEpoch(t)
    if UseOs() then
        local ok, v = pcall(os.time, { year = t.y, month = t.m, day = t.d, hour = t.H, min = t.M, sec = t.S })
        if ok and type(v) == "number" then return v end
        return nil
    end
    return CivilToEpoch(t.y, t.m, t.d, t.H, t.M, t.S)
end

local function NowEpoch()
    if UseOs() then
        local ok, v = pcall(os.time)
        if ok and type(v) == "number" then return v end
        return nil
    end
    local ok, v = pcall(function() return Time.GetEpoche() end)
    if ok and type(v) == "number" then return v end
    return nil
end

-- Measures a file whose end cannot be reported by seek("end"). Some Lua builds
-- on Windows use a 32-bit file position, so a log over 2 GB makes the normal
-- answer fail - and these logs can reach 14 GB. Relative seeks of at most 1 GB
-- and a one-byte read still work on such files, so find the last readable byte
-- by galloping 1 GB at a time and then halving. About 45 cheap calls per file.
-- Returns the size, or nil when even that does not work.
local function ProbeSize(f)
    local CHUNK = 2 ^ 30                   -- 1 GB (a float: exact up to 2^53, so no integer wrap-around)
    local pos = 0                          -- tracked here: the file's own position cannot be trusted past 2 GB

    local function moveTo(p)
        local d = p - pos
        while d ~= 0 do
            local step = d
            if step > CHUNK then step = CHUNK elseif step < -CHUNK then step = -CHUNK end
            if f:seek("cur", step) == nil then return false end
            pos = pos + step
            d = d - step
        end
        return true
    end

    -- true / false = is there a byte at p; nil = the seek itself failed
    local function hasByte(p)
        if not moveTo(p) then return nil end
        local b = f:read(1)
        if b == nil or b == "" then return false end
        pos = pos + 1
        return true
    end

    local first = hasByte(0)
    if first == nil then return nil end
    if first == false then return 0 end

    local lo, hi = 0, nil                  -- the byte at lo is readable, the byte at hi is not
    for _ = 1, 256 do                      -- up to 256 GB
        local h = hasByte(lo + CHUNK)
        if h == nil then return nil end
        if h then lo = lo + CHUNK else hi = lo + CHUNK; break end
    end
    if hi == nil then return nil end

    while hi - lo > 1 do
        local mid = lo + math.floor((hi - lo) / 2)
        local h = hasByte(mid)
        if h == nil then return nil end
        if h then lo = mid else hi = mid end
    end
    return lo + 1
end

-- Size in bytes without reading the file. Returns size, approx. Normally a seek
-- to the end; when that fails (see ProbeSize) the probe measures it exactly.
-- If even that is impossible the file is reported as "2 GB+" rather than as
-- unknown, because only a very large file gets here. nil = could not open it.
local function FileSize(path)
    local okOpen, f = pcall(function() return io.open(path, "rb") end)
    if not okOpen or not f then return nil end
    local okSeek, size = pcall(function() return f:seek("end") end)
    if okSeek and type(size) == "number" and size >= 0 then
        pcall(function() f:close() end)
        return size, false
    end
    local okProbe, probed = pcall(ProbeSize, f)
    pcall(function() f:close() end)
    if okProbe and type(probed) == "number" and probed > 0 then return probed, false end
    return 2147483648, true
end

local function ListLogFiles(dir)
    local seen, out = {}, {}
    -- The extension argument is finicky between builds, so try the spellings.
    for _, ext in ipairs({ ".log", "log", "*.log", "" }) do
        local ok, list = pcall(FileMgr.FindFiles, dir, ext, false)
        if ok then
            for _, p in ipairs(Enum(list)) do
                if type(p) == "string" and p ~= "" then
                    local name = p:match("([^\\/]+)$") or p
                    if name:lower():find("%.log$") and not seen[name] then
                        seen[name] = true
                        out[#out + 1] = name
                    end
                end
            end
        end
        if #out > 0 then break end
    end
    return out
end

-- Rebuilds LF.files from the Logs folder. Runs on the housekeeping fiber.
local function ScanLogs()
    LF.needScan = false
    local dir = RootPath(LOGS_DIR)
    if dir == nil then
        LF.status = "cannot find the Cherax folder"
        return
    end
    LF.dir = dir

    local names = ListLogFiles(dir)
    local files, total, anyApprox = {}, 0, false
    for i = 1, #names do
        local name = names[i]
        local path = dir .. "\\" .. name           -- rebuilt, never the search's own string
        local t = ParseLogName(name)
        local size, approx = FileSize(path)
        files[#files + 1] = {
            name = name, path = path,
            size = size or 0, approx = approx or false, unknown = (size == nil),
            key = t and t.key or nil,
            ts = t and FileEpoch(t) or nil,
            pretty = t and PrettyDate(t) or name,
            deletable = (t ~= nil),          -- only exact Cherax log names are ever deleted
        }
        total = total + (size or 0)
        if approx then anyApprox = true end
        if i % 40 == 0 then Script.Yield(0) end    -- a few hundred files: do not hog the thread
    end

    local cur, curApprox = FileSize(RootPath(LOG_NAME) or "")
    LF.files = files
    LF.total = total
    LF.totalApprox = anyApprox
    LF.current = cur
    LF.currentApprox = curApprox or false
    LF.sortedBy = nil
    LF.scanned = true
    LF.scanAt = NowMs()
    LF.status = ""
end

local function KeyOf(e) return e.key or -1 end

-- Newest first by default; largest first when "sort by size" is ticked.
local function SortFiles()
    local mode = DC.sortBySize and "size" or "date"
    if LF.sortedBy == mode then return end
    local list = {}
    for i = 1, #LF.files do list[i] = LF.files[i] end
    if mode == "size" then
        table.sort(list, function(a, b)
            if a.size ~= b.size then return a.size > b.size end
            if KeyOf(a) ~= KeyOf(b) then return KeyOf(a) > KeyOf(b) end
            return a.name > b.name
        end)
    else
        table.sort(list, function(a, b)
            if KeyOf(a) ~= KeyOf(b) then return KeyOf(a) > KeyOf(b) end
            return a.name > b.name
        end)
    end
    LF.order = list
    LF.sortedBy = mode
end

-- Files strictly older than `days` days. Returns list, bytes, approx.
local function OlderThan(days)
    local list, bytes, approx = {}, 0, false
    local now = NowEpoch()
    if now == nil then return list, 0, false end
    for i = 1, #LF.files do
        local e = LF.files[i]
        if e.ts ~= nil and now - e.ts > days * 86400 then
            list[#list + 1] = e
            bytes = bytes + e.size
            if e.approx then approx = true end
        end
    end
    return list, bytes, approx
end

-- Can the file be opened for reading? This is how we tell whether a file is
-- still there. FileMgr.DoesFileExist is NOT trusted for it: on this build it
-- answers false for a log over 2 GB that is plainly on disk, which once made the
-- script report "deleted" five times for a 13 GB file that never went away.
local function FileOpens(path)
    local ok, f, err, code = pcall(function() return io.open(path, "rb") end)
    if not ok then return false end
    if f then
        pcall(function() f:close() end)
        return true
    end
    -- It would not open. Only "no such file" means it is gone; "permission denied"
    -- or a sharing violation means something else has it, so it is still there.
    if code == 2 or tostring(err or ""):find("No such file", 1, true) then return false end
    return true
end

-- Removes one file, checking after every attempt that it is really gone.
-- Returns true plus how it was done, or false plus why not. The ways, in order:
--   1. the menu's own FileMgr.DeleteFile
--   2. os.remove (the C runtime; does not care how big the file is)
--   3. empty the file, then 1 and 2 again - a log over 2 GB can defeat both, a
--      zero-byte file does not. If it still cannot be removed the space is at
--      least freed, and the message says so.
local function RemoveFile(path)
    if not FileOpens(path) then return true, "already gone" end

    local notes = {}
    local function attempt()
        local ok, err = pcall(FileMgr.DeleteFile, path)
        if not ok then notes[#notes + 1] = "FileMgr.DeleteFile: " .. tostring(err)
        else notes[#notes + 1] = "FileMgr.DeleteFile left the file" end
        if not FileOpens(path) then return "FileMgr.DeleteFile" end

        if type(os) == "table" and type(os.remove) == "function" then
            local okR, res, msg = pcall(os.remove, path)
            if not okR then notes[#notes + 1] = "os.remove: " .. tostring(res)
            elseif res ~= true then notes[#notes + 1] = "os.remove: " .. tostring(msg or "failed") end
            if not FileOpens(path) then return "os.remove" end
        else
            notes[#notes + 1] = "os.remove is not available"
        end
        return nil
    end

    local how = attempt()
    if how ~= nil then return true, how end

    local okOpen, f = pcall(function() return io.open(path, "wb") end)      -- opening for writing empties the file
    if okOpen and f then
        pcall(function() f:close() end)
        notes = {}
        how = attempt()
        if how ~= nil then return true, how .. " after emptying it" end
        return false, "emptied it to free the space, but it could not be removed (" .. table.concat(notes, "; ") .. ")"
    end
    notes[#notes + 1] = "cannot open it to empty it: " .. tostring(f)
    return false, table.concat(notes, "; ")
end

-- Deletes ONE log by name. The name must be exactly a Cherax log name and the
-- path is rebuilt from it (never taken from the file search). Returns true plus
-- how, or false plus why not.
local function DeleteLogFile(name)
    local dir = LF.dir or RootPath(LOGS_DIR)
    if dir == nil or ParseLogName(name) == nil then return false, "not a Cherax log file name" end
    return RemoveFile(dir .. "\\" .. name)
end

-- The Delete button on a row. The deleting itself happens on the housekeeping
-- fiber, so the click costs nothing on the render thread.
local function QueueDelete(e)
    if e == nil or not e.deletable or e.deleting then return end
    e.deleting = true
    LF.deleteQueue[#LF.deleteQueue + 1] = { name = e.name, pretty = e.pretty, size = e.size, approx = e.approx }
end

local function ProcessDeletes()
    if #LF.deleteQueue == 0 then return end
    local queue = LF.deleteQueue
    LF.deleteQueue = {}
    for i = 1, #queue do
        local item = queue[i]
        local size = FormatSize(item.size, item.approx)
        local what = item.pretty .. ", " .. size
        local ok, how = DeleteLogFile(item.name)
        if ok then
            LF.cleanup = "Deleted " .. what
            Log("deleted log file " .. item.name .. " (" .. size .. ") via " .. tostring(how))
        else
            LF.cleanup = "Could not delete " .. what .. " - " .. tostring(how)
            LogErr("could not delete log file " .. item.name .. ": " .. tostring(how))
        end
        Script.Yield(0)
    end
    LF.needScan = true                               -- the row disappears (or comes back, with its real size)
end

-- Deletes every log older than DC.days. Returns deleted, failed, bytes.
local function RunPrune()
    if LF.dir == nil or not LF.scanned then return 0, 0, 0 end
    local list = OlderThan(DC.days)
    local deleted, failed, bytes, approx, why = 0, 0, 0, false, nil
    for i = 1, #list do
        local e = list[i]
        local ok, how = DeleteLogFile(e.name)
        if ok then
            deleted = deleted + 1
            bytes = bytes + e.size
            if e.approx then approx = true end
        else
            failed = failed + 1
            why = how
        end
        Script.Yield(0)
    end

    if deleted == 0 and failed == 0 then
        LF.cleanup = "Last check: nothing older than " .. DC.days .. " day(s)"
    else
        LF.cleanup = string.format("Last clean-up: deleted %d file(s), freed %s", deleted, FormatSize(bytes, approx))
        if failed > 0 then
            LF.cleanup = LF.cleanup .. string.format("  (%d could not be deleted: %s)", failed, tostring(why))
            LogErr(LF.cleanup)
        else
            Log(LF.cleanup)
        end
    end
    LF.needScan = true                               -- show the new state
    return deleted, failed, bytes
end

-- ============================================================================
--  Housekeeping - one tick a second, on its own fiber so a slow Discord post
--  never holds it up:
--    * writes the settings file when any setting changed
--    * refreshes the log list while a tab that shows it is open
--    * runs the old-log clean-up when it is due
-- ============================================================================
local function Housekeeping()
    local now = NowMs()
    SaveIfChanged()
    ProcessDeletes()

    -- Switching auto-delete on, or settling on a new number of days, schedules a
    -- clean-up. Days wait for the box to stop changing, so typing "30" never
    -- deletes at "3".
    if DC.autoDelete ~= LF.lastAuto then
        LF.lastAuto = DC.autoDelete
        if DC.autoDelete then LF.pruneDueAt = now + PRUNE_ON_MS else LF.pruneDueAt = nil end
    end
    if DC.days ~= LF.lastDays then
        LF.lastDays = DC.days
        if DC.autoDelete then LF.pruneDueAt = now + PRUNE_DAYS_MS end
    end
    if DC.autoDelete and LF.pruneDueAt == nil and now >= LF.nextPrune then
        LF.pruneDueAt = now
    end

    local due = DC.autoDelete and LF.pruneDueAt ~= nil and now >= LF.pruneDueAt
    local watching = (now - LF.seenAt) < 3000
    if watching and (not LF.scanned or now - LF.scanAt > SCAN_EVERY_MS) then LF.needScan = true end
    if due and (not LF.scanned or now - LF.scanAt > 60000) then LF.needScan = true end

    if LF.needScan then ScanLogs() end

    if due and LF.scanned then
        LF.pruneDueAt = nil
        LF.nextPrune = now + PRUNE_EVERY_MS
        RunPrune()
    end
end

Try("starting the housekeeping loop", Script.RegisterLooped, function()
    Script.Yield(1000)
    local ok, err = pcall(Housekeeping)
    if not ok then
        -- ReportError logs each distinct error once, so a persistent fault cannot fill the console.
        LF.error = tostring(err)
        ReportError("housekeeping", err)
        LF.status = "error: " .. LF.error
    end
end)

-- ============================================================================
--  Searching the log files (Log files tab)
--
--  The user types a word, a player name, a Rockstar ID or an IP address. This
--  session's Cherax.log is read first, then every log in the Logs folder, newest
--  first, in 1 MB pieces, and the lines that contain every typed word are
--  collected. It runs on its own fiber, a few milliseconds per turn, so the game
--  keeps its frame rate; the file being read is closed when the search ends, is
--  stopped, or starts over. Capital letters do not matter. Nothing is changed.
-- ============================================================================
local LS = {
    minChars   = 2,          -- shorter searches would match nearly every line
    debounceMs = 500,        -- the search starts this long after the last key press
    sliceMs    = 4,          -- one turn of the fiber reads for at most this long
    chunk      = 1048576,    -- bytes read at a time
    maxRows    = 400,        -- matching lines kept; the search stops there
    lineMax    = 300,        -- a result line is cut to this many characters
    maxLine    = 65536,      -- an unbroken stretch this long is not a console line and is skipped

    text       = "",         -- what the box holds
    typedAt    = 0,          -- when it last changed
    active     = "",         -- the text the results belong to
    state      = "idle",     -- idle | short | searching | done | stopped
    terms      = {},         -- the typed words, lower case
    anchor     = "",         -- the longest word: the one scanned for (the others are checked on the hit)
    queue      = {},         -- files still to read: { path, pretty, size, approx }
    cur        = nil,        -- the file being read: { f, item, carry, read, hit }
    rows       = {},         -- { header } or { text, raw, rgb }
    matches    = 0, filesHit = 0, capped = false,
    fileNo     = 0, fileCount = 0, bytes = 0, totalBytes = 0,
    skipped    = {},         -- notes about files that could not be read
    startedAt  = 0, finishedAt = 0,
}

-- "Bob 178.2" -> { "bob", "178.2" }
function LS.Terms(text)
    local terms = {}
    for w in tostring(text or ""):lower():gmatch("%S+") do terms[#terms + 1] = w end
    return terms
end

-- Does this (already lower-case) text contain every word?
function LS.HasAll(lower, terms)
    for i = 1, #terms do
        if not lower:find(terms[i], 1, true) then return false end
    end
    return true
end

function LS.Close()
    if LS.cur ~= nil then
        local f = LS.cur.f
        LS.cur = nil
        pcall(function() f:close() end)
    end
end

function LS.Reset()
    LS.Close()
    LS.state = "idle"
    LS.queue, LS.rows, LS.skipped = {}, {}, {}
    LS.matches, LS.filesHit, LS.capped = 0, 0, false
    LS.fileNo, LS.fileCount, LS.bytes, LS.totalBytes = 0, 0, 0, 0
end

function LS.Finish(state)
    LS.Close()
    LS.queue = {}
    LS.state = state
    LS.finishedAt = NowMs()
end

-- Starts over for this text: the live log first, then the Logs folder newest first.
function LS.Start(text)
    LS.Reset()
    LS.active = text
    local terms = LS.Terms(text)
    if #terms == 0 then return end                       -- an empty box is just an empty box
    local chars, anchor = 0, ""
    for i = 1, #terms do
        chars = chars + #terms[i]
        if #terms[i] > #anchor then anchor = terms[i] end
    end
    if chars < LS.minChars then LS.state = "short"; return end

    local queue = {}
    local live = RootPath(LOG_NAME)
    if live ~= nil then
        queue[1] = { path = live, pretty = "This session (" .. LOG_NAME .. ")", size = LF.current or 0, approx = LF.currentApprox }
    end
    local list = {}
    for i = 1, #LF.files do list[i] = LF.files[i] end
    table.sort(list, function(a, b)
        if KeyOf(a) ~= KeyOf(b) then return KeyOf(a) > KeyOf(b) end
        return a.name > b.name
    end)
    for i = 1, #list do
        local e = list[i]
        queue[#queue + 1] = { path = e.path, pretty = e.pretty, size = e.size, approx = e.approx }
    end

    LS.terms, LS.anchor, LS.queue = terms, anchor, queue
    LS.fileCount = #queue
    for i = 1, #queue do LS.totalBytes = LS.totalBytes + (queue[i].size or 0) end
    LS.startedAt = NowMs()
    LS.state = "searching"
end

-- Keeps one matching line (and the file's heading before its first one).
function LS.AddRow(c, line)
    local e = ParseConsoleLine(line)
    if e == nil then return end
    if not c.hit then
        c.hit = true
        LS.filesHit = LS.filesHit + 1
        LS.rows[#LS.rows + 1] = { header = c.item.pretty .. "  -  " .. FormatSize(c.item.size or 0, c.item.approx) }
    end
    local text = e.rest
    if e.clock ~= nil then text = e.clock .. " " .. text end
    if #text > LS.lineMax then text = CleanUtf8(text:sub(1, LS.lineMax)) .. "..." end
    -- ImGui text may be printf-style: double every % so a line can never be read as a format.
    LS.rows[#LS.rows + 1] = { raw = text, text = (text:gsub("%%", "%%%%")), rgb = ANSI_RGB[e.colour] or ANSI_RGB[37] }
    LS.matches = LS.matches + 1
    if LS.matches >= LS.maxRows then
        LS.capped = true
        LS.Finish("done")
    end
end

-- Looks for the lines in a block of whole lines. Only the lines that contain the
-- longest word are looked at, so a rare word costs almost nothing per megabyte.
function LS.Scan(c, body)
    local lower = body:lower()
    local anchor, terms = LS.anchor, LS.terms
    local pos = 1
    while LS.state == "searching" do
        local s = lower:find(anchor, pos, true)
        if s == nil then return end
        local a = s
        while a > pos and lower:byte(a - 1) ~= 10 do a = a - 1 end        -- back to the start of that line
        local e = lower:find("\n", s, true) or (#lower + 1)
        if LS.HasAll(lower:sub(a, e - 1), terms) then LS.AddRow(c, body:sub(a, e - 1)) end
        pos = e + 1
    end
end

function LS.NextFile()
    local item = table.remove(LS.queue, 1)
    if item == nil then LS.Finish("done"); return end
    LS.fileNo = LS.fileNo + 1
    local ok, f = pcall(function() return io.open(item.path, "rb") end)
    if ok and f then
        LS.cur = { f = f, item = item, carry = "", read = 0, hit = false }
    else
        LS.skipped[#LS.skipped + 1] = item.pretty .. " could not be opened"
    end
end

-- The end of a file: its last line may have no line break, and a file this build
-- could not read to the end (over 2 GB on some builds) is said so, not hidden.
function LS.EndFile(c)
    if c.carry ~= "" and LS.state == "searching" then LS.Scan(c, c.carry .. "\n") end
    local size = c.item.size or 0
    if size > c.read + 2 * LS.chunk then
        LS.skipped[#LS.skipped + 1] = c.item.pretty .. ": could only read " .. FormatSize(c.read) .. " of " .. FormatSize(size, c.item.approx)
    end
    LS.Close()
end

function LS.ReadChunk()
    local c = LS.cur
    local ok, chunk = pcall(c.f.read, c.f, LS.chunk)
    if not ok then
        LS.skipped[#LS.skipped + 1] = c.item.pretty .. ": reading stopped (" .. tostring(chunk) .. ")"
        LS.Close()
        return
    end
    if chunk == nil or chunk == "" then LS.EndFile(c); return end

    c.read = c.read + #chunk
    LS.bytes = LS.bytes + #chunk
    local data = c.carry .. chunk
    local nl = data:match("^.*()\n")                          -- the last line break: only whole lines are searched
    if nl == nil then
        c.carry = (#data > LS.maxLine) and "" or data         -- keep the start of the line for the next piece, unless it never ends
        return
    end
    c.carry = data:sub(nl + 1)
    LS.Scan(c, data:sub(1, nl))
end

-- One turn of the search fiber.
function LS.Step()
    if LS.text ~= LS.active then
        -- The box changed: wait until the typing pauses (and the file list exists), then start over.
        if NowMs() - LS.typedAt >= LS.debounceMs and LF.scanned then LS.Start(LS.text) end
        return
    end
    if LS.state ~= "searching" then return end
    local t0 = NowMs()
    repeat
        if LS.cur == nil then LS.NextFile() else LS.ReadChunk() end
    until LS.state ~= "searching" or NowMs() - t0 >= LS.sliceMs
end

-- The Stop / Clear button: stops a running search (keeping what it found), otherwise empties everything.
function LS.Stop()
    if LS.state == "searching" then
        LS.Finish("stopped")
        LS.active = LS.text
    else
        LS.text, LS.active = "", ""
        LS.Reset()
    end
end

function LS.Copy()
    if #LS.rows == 0 then Toast("There is nothing to copy"); return end
    local out = {}
    for i = 1, #LS.rows do
        local r = LS.rows[i]
        out[#out + 1] = r.header and ("== " .. r.header) or r.raw
    end
    local ok = pcall(function() Utils.SetClipBoardText(table.concat(out, "\n"), "") end)
    Toast(ok and (LS.matches .. " line(s) copied") or "Could not copy the results", 3500)
end

Try("starting the log search loop", Script.RegisterLooped, function()
    Script.Yield(LS.state == "searching" and 0 or 150)
    local ok, err = pcall(LS.Step)
    if not ok then
        LS.Finish("stopped")
        LS.skipped[#LS.skipped + 1] = "the search stopped: " .. tostring(err)
        ReportError("log search", err)
    end
end)

-- ============================================================================
--  UI helpers
-- ============================================================================
local COL_DIM  = { 0.62, 0.62, 0.66, 1.0 }
local COL_OK   = { 0.35, 0.85, 0.45, 1.0 }
local COL_BAD  = { 1.00, 0.40, 0.40, 1.0 }
local COL_WARN = { 1.00, 0.80, 0.30, 1.0 }
local COL_FAINT = { 0.50, 0.50, 0.55, 0.55 }

local function C(c, s) ImGui.TextColored(c[1], c[2], c[3], c[4] or 1.0, s) end

-- C for text that can be longer than the panel is wide (a webhook error, a status
-- message, a folder path): it wraps onto the next line instead of being cut off.
-- Falls back to C if this build cannot wrap.
local function CW(c, s)
    local pushed = pcall(function() ImGui.PushStyleColor(ImGuiCol.Text, c[1], c[2], c[3], c[4] or 1.0) end)
    local ok = pcall(ImGui.TextWrapped, s)
    if pushed then pcall(ImGui.PopStyleColor, 1) end
    if not ok then C(c, s) end
end

-- The Cherax Lua API has no animation call, so the few effects here (a glow on live
-- status text, the popup fading in, new popup lines settling) are worked out by hand
-- from the clock.
local function Ease(since, ms)         -- 0 to 1 over ms after `since`, slowing down at the end
    if since == nil then return 1.0 end
    local t = (NowMs() - since) / ms
    if t >= 1 then return 1.0 end
    if t <= 0 then return 0.0 end
    return 1 - (1 - t) * (1 - t)
end

local function Pulse(periodMs)         -- a slow wave between 0 and 1
    return 0.5 + 0.5 * math.sin((NowMs() % periodMs) / periodMs * 2 * math.pi)
end

-- The same colour with its brightness breathing a little: for something that is happening now.
local function Breathe(c)
    local a = 0.62 + 0.38 * Pulse(2400)
    return { c[1], c[2], c[3], (c[4] or 1.0) * a }
end

local BOX_TITLE_ALIGN = 0.5            -- box titles centred; -1 leaves it to the theme

-- What a control does, shown while the mouse is over it. Put one right after
-- EVERY button and tick box instead of writing the explanation beside it.
local function TipShow(text)
    if ImGui.IsItemHovered() then ImGui.SetTooltip(text) end
end
local function Tip(text) pcall(TipShow, text) end

-- ImGui.Checkbox returns (value, changed); trust it only when it is a boolean.
local function Check(label, value)
    local v = ImGui.Checkbox(label, value)
    if type(v) == "boolean" then return v end
    return value
end

-- One choice out of several. Uses a real radio button; if this build's
-- RadioButton does not take (label, bool) it falls back to a tick box that can
-- be ticked but not cleared, which behaves the same. True = this one was picked.
local RADIO_OK = true
local function Radio(label, active)
    if RADIO_OK then
        local ok, pressed = pcall(ImGui.RadioButton, label, active)
        if ok then return pressed == true end
        RADIO_OK = false
    end
    local v = Check(label, active)
    return v and not active
end

-- ============================================================================
--  Popup console - a resizable window that shows the log live, no Discord needed
--
--  Reads the same Cherax.log the stream does, through its own position, so it
--  works whether or not streaming is on. Drawn from ON_PRESENT like the other
--  floating windows, so it stays up with the menu closed.
-- ============================================================================
local PC = {
    open       = false,
    lines      = {},      -- { text, rgb }
    pos        = nil,     -- position in the log (nil = not placed yet)
    autoscroll = true,
    openedAt   = nil,     -- when the window was opened (for the fade-in)
    dirty      = false,   -- new lines arrived since the last frame
    status     = "",
    search     = "",      -- the search box: only lines containing every word are shown
    rev        = 0,       -- changes whenever the lines change, so the filtered list is rebuilt only when needed
    view       = nil,     -- the lines that match, for the text in viewQ at revision viewRev
    viewQ      = nil,
    viewRev    = -1,
}

-- The lines to draw: all of them, or the ones that contain every typed word. The
-- filtered list is rebuilt only when the box or the lines changed.
function PC.View()
    local terms = LS.Terms(PC.search)
    if #terms == 0 then return PC.lines end
    if PC.viewQ ~= PC.search or PC.viewRev ~= PC.rev then
        local out = {}
        for i = 1, #PC.lines do
            local l = PC.lines[i]
            if LS.HasAll(l.lower or "", terms) then out[#out + 1] = l end
        end
        PC.view, PC.viewQ, PC.viewRev = out, PC.search, PC.rev
        PC.dirty = true       -- the list changed: keep the newest match in view
    end
    return PC.view
end

local function SetPopup(on)
    PC.open = on
    if on then
        PC.openedAt = NowMs()
        PC.lines = {}
        PC.rev = PC.rev + 1
        PC.pos = nil        -- the first look loads recent history
        PC.dirty = true
        PC.status = ""
    end
end

local function PopupStep()
    if not PC.open then
        PC.pos = nil        -- reopening starts from recent history again
        return
    end
    local ok, why, lines, burst = TailLog(PC, POPUP_BACKLOG)
    if not ok then
        PC.status = why
        return
    end
    PC.status = ""

    local added = false
    local note = { text = "... console output skipped (too fast to show)", rgb = ANSI_RGB[33] }
    note.lower = note.text:lower()
    if burst then
        note.born = NowMs()
        PC.lines[#PC.lines + 1] = note       -- marks the gap between what was shown and what follows
        added = true
    end
    for i = 1, #lines do
        local e = ParseConsoleLine(lines[i])
        if e ~= nil then
            local text = e.rest
            if e.clock ~= nil then text = e.clock .. " " .. text end
            if #text > POPUP_MAX_LINE then text = CleanUtf8(text:sub(1, POPUP_MAX_LINE)) .. "..." end
            -- ImGui text may be printf-style: double every % so a line can never be read as a format.
            PC.lines[#PC.lines + 1] = { text = (text:gsub("%%", "%%%%")), lower = text:lower(), rgb = ANSI_RGB[e.colour] or ANSI_RGB[37], born = NowMs() }
            added = true
        end
    end
    while #PC.lines > POPUP_LINES do table.remove(PC.lines, 1) end
    if burst then
        -- A burst that alone fills the window trims the note away; keep it on top so the gap is still visible.
        local kept = false
        for i = 1, #PC.lines do
            if PC.lines[i] == note then kept = true; break end
        end
        if not kept then PC.lines[1] = note end
    end
    if added then PC.dirty = true; PC.rev = PC.rev + 1 end
end

Try("starting the popup console loop", Script.RegisterLooped, function()
    Script.Yield(POPUP_POLL_MS)
    local ok, err = pcall(PopupStep)
    if not ok then
        PC.status = "error: " .. tostring(err)
        ReportError("popup console", err)
    end
end)

-- The buttons along the top of the window. Called between Begin and End, protected.
local function PopupToolbar()
    if ImGui.Button("Clear##dcpclear") then PC.lines = {}; PC.rev = PC.rev + 1 end
    Tip("Empties this window. Cherax.log is not touched.")
    ImGui.SameLine()
    PC.autoscroll = Check("Auto-scroll##dcpauto", PC.autoscroll)
    Tip("Keeps the newest line in view. Untick it to scroll back through older lines.")
    ImGui.SameLine()
    if ImGui.Button("Close##dcpclose") then PC.open = false end
    Tip("Closes this window.")
    ImGui.SameLine()
    C(COL_DIM, string.format("%d line(s)", #PC.lines))
    if PC.status ~= "" then
        ImGui.SameLine()
        C(COL_BAD, PC.status)
    end

    -- Live search: the list below narrows as you type, no button to press.
    ImGui.Text("Search")
    ImGui.SameLine()
    ImGui.SetNextItemWidth(260)
    local typed = ImGui.InputText("##dcpsearch", PC.search, 256)
    if type(typed) == "string" then PC.search = typed end
    if PC.search ~= "" then
        ImGui.SameLine()
        if ImGui.Button("Clear search##dcpsearchclear") then PC.search = "" end
        ImGui.SameLine()
        C(COL_DIM, string.format("%d of %d line(s)", #PC.View(), #PC.lines))
    end
    ImGui.Separator()
end

-- The lines. Called between BeginChild and EndChild, protected. A colour pushed for a
-- line is popped straight after it, with nothing that can fail in between except the
-- text call, which is guarded on its own.
local function PopupLines()
    local view = PC.View()
    if #view == 0 and PC.search ~= "" then C(COL_DIM, "No line contains that") end
    for i = 1, #view do
        local l = view[i]
        -- A line that has only just arrived is a little brighter, then settles to its colour.
        local k = (1 - Ease(l.born, 1400)) * 0.45
        ImGui.PushStyleColor(ImGuiCol.Text, l.rgb[1] + (1 - l.rgb[1]) * k, l.rgb[2] + (1 - l.rgb[2]) * k, l.rgb[3] + (1 - l.rgb[3]) * k, 1.0)
        Try("popup line", ImGui.TextWrapped, l.text)
        ImGui.PopStyleColor(1)
    end
    if PC.autoscroll and PC.dirty then
        pcall(ImGui.SetScrollHereY, 1.0)
        PC.dirty = false
    end
end

-- Every Begin has its End outside the protected parts, so an error while drawing can
-- never leave an ImGui window open.
local function DrawPopup()
    pcall(ImGui.SetNextWindowSize, 860, 440, ImGuiCond.Once)
    -- Begin returns the visible flag first and p_open second; only an explicit
    -- false means the X was clicked (see the Database window in Exclusive Unlocks).
    local okBegin, _, stillOpen = pcall(ImGui.Begin, SCRIPT_NAME .. " - Live Console", true, ImGuiWindowFlags.NoCollapse)
    if not okBegin then
        ReportError("popup window", _)
        PC.open = false                 -- do not retry a failing Begin every frame
        return
    end

    Try("popup toolbar", PopupToolbar)

    -- The scrolling area fills what is left of the window, so it grows when you drag the corner.
    local okChild, shown = pcall(ImGui.BeginChild, "##dcpscroll", 0, 0, true)
    if okChild then
        if shown ~= false then Try("popup lines", PopupLines) end
        ImGui.EndChild()
    else
        ReportError("popup lines", shown)
    end

    ImGui.End()
    if stillOpen == false then PC.open = false end
end

-- Fades the window in over a fraction of a second after it opens. The style change
-- is popped straight after the window is drawn, whatever happened inside.
local function RenderPopup()
    if not PC.open then return end
    local fade = Ease(PC.openedAt, 220)
    local pushed = false
    if fade < 1 then
        pushed = pcall(function() ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 0.15 + 0.85 * fade) end)
    end
    Try("popup window", DrawPopup)
    if pushed then pcall(function() ImGui.PopStyleVar(1) end) end
end

-- Drawn from ON_PRESENT, like the other floating windows, so it stays up with the menu closed.
local function PopupHandler()
    Try("popup window", RenderPopup)
end

Try("registering the popup window", function() EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, PopupHandler) end)


-- ============================================================================
--  Buttons and hotkeys
--
--  Every button is a real Cherax menu Button (FeatureMgr.AddFeature) drawn with
--  ClickGUI.RenderFeature. That makes it look like the rest of the menu, puts its
--  description in the menu's own description area, and lets the user bind a key:
--  hover it and press F10.
--
--  Remembering the keys: Cherax restores its own settings BEFORE Lua scripts have
--  registered their features, so a key bound to a script's button is dropped on
--  restart. The bindings are therefore kept in SmartConsole.cfg (hk_<id>=<keys>)
--  and put back once the buttons exist. There is no Save button: the settings
--  watcher notices a changed binding within a second and writes the file.
-- ============================================================================
local HOTKEY_HINT = " Hover this and press F10 to bind a hotkey."

local KEY_NAMES = {
    [8] = "Backspace", [9] = "Tab", [13] = "Enter", [19] = "Pause", [20] = "Caps Lock", [27] = "Esc",
    [32] = "Space", [33] = "Page Up", [34] = "Page Down", [35] = "End", [36] = "Home",
    [37] = "Left", [38] = "Up", [39] = "Right", [40] = "Down", [45] = "Insert", [46] = "Delete",
    [106] = "Num *", [107] = "Num +", [109] = "Num -", [110] = "Num .", [111] = "Num /",
    [186] = ";", [187] = "=", [188] = ",", [189] = "-", [190] = ".", [191] = "/", [192] = "`",
    [219] = "[", [220] = "\\", [221] = "]", [222] = "'",
}

-- Windows virtual-key code -> what the key is called.
local function KeyName(code)
    if KEY_NAMES[code] then return KEY_NAMES[code] end
    if code >= 112 and code <= 123 then return "F" .. (code - 111) end
    if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) then return string.char(code) end
    if code >= 96 and code <= 105 then return "Num " .. (code - 96) end
    return "key " .. code
end

-- The keys bound to a feature, as a sorted list of key codes. GetHotKeys can hand
-- back a table or a wrapped vector depending on the build, hence Enum.
local function KeysFor(hash)
    local out = {}
    local ok, raw = pcall(function() return HotKeyMgr.GetHotKeys(hash) end)
    if not ok or raw == nil then return out end
    for _, k in ipairs(Enum(raw)) do
        if type(k) == "number" and k > 0 then out[#out + 1] = k end
    end
    table.sort(out)
    return out
end

local function KeyNames(keys)
    local names = {}
    for i = 1, #keys do names[i] = KeyName(keys[i]) end
    return table.concat(names, ", ")
end

-- Every button of the script. The id is the Joaat source string, so the settings
-- file stays readable and survives a hash change. `label`, when there is one, gives
-- the name to show right now (the button changes its wording with the state).
local ACTIONS = {
    { id = "SC_PasteWebhook", name = "Paste Webhook From Clipboard",
      desc = "Reads the webhook URL from your clipboard and saves it. In Discord: Channel Settings > Integrations > Webhooks > Copy Webhook URL.",
      run = function() PasteWebhook() end },
    { id = "SC_ClearWebhook", name = "Clear Webhook",
      desc = "Forgets the saved webhook and stops streaming.",
      run = function() ClearWebhook() end },
    { id = "SC_ToggleStream", name = "Start / Stop Streaming",
      desc = "Starts or stops posting new console lines to your webhook. Only lines written after you start are sent.",
      label = function() return DC.enabled and "Stop Streaming" or "Start Streaming" end,
      run = function() SetEnabled(not DC.enabled) end },
    { id = "SC_TestLine", name = "Send Test Line",
      desc = "Writes a line to the console. If it shows up in your Discord channel, everything works. Streaming has to be on.",
      run = function() SendTestLine() end },
    { id = "SC_Popup", name = "Popup Console",
      desc = "Opens or closes a resizable window that shows the console live, without needing Discord.",
      label = function() return PC.open and "Close Popup Console" or "Popup Console" end,
      run = function() SetPopup(not PC.open) end },
    { id = "SC_RefreshLogs", name = "Refresh Log Files",
      desc = "Reads the Logs folder again.",
      run = function() LF.needScan = true end },
    { id = "SC_FiltersOn", name = "All Filters On",
      desc = "Sends every kind of console line to Discord.",
      run = function() SetAllFilters(true) end },
    { id = "SC_FiltersOff", name = "All Filters Off",
      desc = "Sends nothing to Discord until you switch some kinds back on.",
      run = function() SetAllFilters(false) end },
    { id = "SC_SearchClear", name = "Clear Search",
      desc = "Empties the search box and the results. While a search is running this button stops it instead and keeps what it found.",
      label = function() return LS.state == "searching" and "Stop Search" or "Clear Search" end,
      run = function() LS.Stop() end },
    { id = "SC_SearchCopy", name = "Copy Search Results",
      desc = "Copies the lines the search found to your clipboard.",
      run = function() LS.Copy() end },
    { id = "SC_JoinDiscord", name = "Join Discord",
      desc = "Copies " .. DISCORD_INVITE .. " to your clipboard. Paste it into your browser to join the Smart Console Discord for help, updates and feedback.",
      run = function() CopyDiscordInvite() end },
}

local ACTION_BY_ID, HOTKEYS, HOTKEY_BY_ID = {}, {}, {}
for i = 1, #ACTIONS do
    local a = ACTIONS[i]
    ACTION_BY_ID[a.id] = a
    HOTKEYS[#HOTKEYS + 1] = a
    HOTKEY_BY_ID[a.id] = a
end

-- Registers one action as a menu Button. h.registered says whether it worked; when
-- it did not, the tab draws a plain ImGui button instead, so nothing is ever missing.
local function RegisterHotkey(h)
    h.registered = false
    local okHash, hash = pcall(function() return Utils.Joaat(h.id) end)
    if not okHash or type(hash) ~= "number" then
        ReportError("registering " .. h.id, hash)
        return
    end
    h.hash = hash

    -- A feature with this hash is already in the menu: this script is loaded twice.
    -- Registering the same hash again is not safe, so leave it alone.
    local okGet, existing = pcall(function() return FeatureMgr.GetFeature(hash) end)
    if okGet and existing ~= nil then
        Log("a menu button for " .. h.name .. " already exists - is Smart Console loaded twice?")
        return
    end

    local callback = function() Try(h.name, h.run) end
    local ok = Try("registering " .. h.id, function()
        FeatureMgr.AddFeature(hash, h.name, eFeatureType.Button, h.desc .. HOTKEY_HINT, callback)
    end)
    local okNow, now = pcall(function() return FeatureMgr.GetFeature(hash) end)
    h.registered = ok and okNow and now ~= nil
    h.shown = h.name
end

for i = 1, #HOTKEYS do Try("registering " .. HOTKEYS[i].id, RegisterHotkey, HOTKEYS[i]) end

-- The current bindings, as lines for the settings file.
DC.hotkeyLines = function()
    local out = {}
    for i = 1, #HOTKEYS do
        local h = HOTKEYS[i]
        if h.registered then
            local keys = KeysFor(h.hash)
            if #keys > 0 then out[#out + 1] = HOTKEY_PREFIX .. h.id .. "=" .. table.concat(keys, ",") end
        end
    end
    return out
end

-- Puts the saved bindings back (see the note at the top of this section). A key the
-- menu already has is not added twice. Returns how many it added.
local function ApplyHotkeys()
    local applied = 0
    for i = 1, #HOTKEYS do
        local h = HOTKEYS[i]
        local saved = DC.pendingHotkeys[h.id]
        if h.registered and saved ~= nil then
            local have = {}
            for _, k in ipairs(KeysFor(h.hash)) do have[k] = true end
            for k in saved:gmatch("%d+") do
                local key = tonumber(k)
                if key and key > 0 and key < 256 and not have[key] then
                    have[key] = true
                    pcall(function() HotKeyMgr.AddHotkey(h.hash, key) end)
                    applied = applied + 1
                end
            end
        end
    end
    DC.pendingHotkeys = {}
    if applied > 0 then Log("restored " .. applied .. " hotkey binding(s)") end
    return applied
end

local function Unbind(h)
    if not h.registered then return end
    for _, k in ipairs(KeysFor(h.hash)) do
        pcall(function() HotKeyMgr.RemoveHotkey(h.hash, k) end)
    end
end

-- Draws one button as a full-width menu row. The name is changed only when the
-- wording actually changes (Start / Stop, Popup / Close Popup). If this build would
-- not take the feature, a plain ImGui button stands in.
local function RenderAction(id)
    local h = ACTION_BY_ID[id]
    if h == nil then return end
    local want = h.label and h.label() or h.name
    if h.registered then
        if want ~= h.shown then
            h.shown = want
            pcall(function() FeatureMgr.GetFeature(h.hash):SetName(want) end)
        end
        Try("showing " .. h.name, function() ClickGUI.RenderFeature(h.hash) end)
    else
        if ImGui.Button(" " .. want .. " ##hk" .. h.id) then Try(h.name, h.run) end
        Tip(h.desc)
    end
end

-- ============================================================================
--  Tabs
-- ============================================================================
-- One box in the menu. The Begin/End pair stays OUTSIDE the protected call, so an
-- error while drawing the box can never leave the menu with an unclosed box. The
-- title is centred (BOX_TITLE_ALIGN, -1 would leave it to the theme).
local function Box(title, body)
    local okBegin, began = pcall(function() return ClickGUI.BeginCustomChildWindow(title, -1, -1, BOX_TITLE_ALIGN, -1) end)
    if not okBegin then
        ReportError("box " .. title, began)
        return
    end
    if began then
        Try("box " .. title, body)
        ClickGUI.EndCustomChildWindow()
    end
end

local function WebhookLine()
    local h = DC.hook
    if DC.url == "" then
        C(COL_DIM, "none")
    elseif h.state == "ok" then
        C(COL_OK, "Webhook connected")
    elseif h.state == "bad" then
        CW(COL_BAD, "Webhook not working - " .. (h.why ~= "" and h.why or "paste a new one"))
    elseif h.state == "offline" then
        CW(COL_WARN, "Webhook saved - could not check it (" .. (h.why ~= "" and h.why or "no answer") .. ")")
    else
        C(Breathe(COL_DIM), "Checking the webhook...")
    end
end

local function WebhookBody()
    local LX = 110
    ImGui.Text("  Webhook")
    ImGui.SameLine(LX)
    WebhookLine()

    ImGui.Spacing()
    RenderAction("SC_PasteWebhook")
    RenderAction("SC_ClearWebhook")
end

local function StreamBody()
    local LX = 110

    RenderAction("SC_ToggleStream")
    RenderAction("SC_TestLine")
    RenderAction("SC_Popup")

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.Text("  Status")
    ImGui.SameLine(LX)
    -- A stream that is running breathes a little; a problem or an idle state sits still.
    CW(DC.statusBad and COL_BAD or (DC.enabled and Breathe(COL_OK) or COL_DIM), DC.status)

    ImGui.Text("  Sent")
    ImGui.SameLine(LX)
    C(COL_DIM, string.format("%d line(s) in %d message(s)   -   %d waiting", DC.sent, DC.posts, #DC.queue))

    ImGui.Text("  Log file")
    ImGui.SameLine(LX)
    if DC.logBytes > 0 then
        C(COL_DIM, string.format("%s  (%.1f KB)", LOG_NAME, DC.logBytes / 1024))
    else
        C(COL_DIM, LOG_NAME .. " - not read yet")
    end
end

local function RenderConsoleTab()
    Box("Discord webhook", WebhookBody)
    Box("Stream", StreamBody)
end

local function SizeColour(e)
    if e.unknown then return COL_DIM end
    if e.size >= 1073741824 then return COL_BAD end      -- 1 GB and up: the ones worth deleting
    if e.size >= 104857600 then return COL_WARN end      -- 100 MB and up
    return COL_DIM
end

local function LogsBody()
    local LX = 110

    ImGui.Text("  Folder")
    ImGui.SameLine(LX)
    CW(COL_DIM, LF.dir or "...")

    ImGui.Text("  Total")
    ImGui.SameLine(LX)
    if LF.scanned then
        C(COL_DIM, string.format("%d file(s)  -  %s", #LF.files, FormatSize(LF.total, LF.totalApprox)))
    else
        C(Breathe(COL_DIM), "reading the folder...")
    end

    ImGui.Text("  This session")
    ImGui.SameLine(LX)
    if LF.current ~= nil then
        C(COL_DIM, LOG_NAME .. "  -  " .. FormatSize(LF.current, LF.currentApprox))
    else
        C(COL_DIM, LOG_NAME)
    end

    ImGui.Spacing()
    local s = Check("Sort by size##dcsort", DC.sortBySize)
    if s ~= DC.sortBySize then DC.sortBySize = s end
    Tip("Sorts the list by file size, largest first.\nUnticked, the newest log is at the top.")
    ImGui.SameLine()
    local d = Check("Show delete button##dcshowdel", DC.showDelete)
    if d ~= DC.showDelete then DC.showDelete = d end
    Tip("Shows a Delete button on every log file in the list.\nDeleting is permanent - the file does not go to the Recycle Bin.")

    ImGui.Spacing()
    RenderAction("SC_RefreshLogs")

    if LF.cleanup ~= "" then
        ImGui.Spacing()
        CW(COL_DIM, "  " .. LF.cleanup)
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    if LF.status ~= "" then
        CW(COL_BAD, "  " .. LF.status)
    elseif LF.scanned and #LF.files == 0 then
        C(COL_DIM, "  No log files found in the Logs folder")
    elseif LF.scanned then
        SortFiles()
        local open = ImGui.CollapsingHeader("Log files (" .. #LF.order .. ")###dclogs")
        Tip("Click to show or hide the list. Hover a row to see its exact file name.")
        if open then
            for i = 1, #LF.order do
                local e = LF.order[i]
                ImGui.Text("  " .. e.pretty)
                if ImGui.IsItemHovered() then ImGui.SetTooltip(e.name) end
                ImGui.SameLine(190)
                if e.unknown then C(COL_DIM, "unknown")
                else C(SizeColour(e), FormatSize(e.size, e.approx)) end
                -- Only files named exactly like a Cherax log can be deleted here.
                if DC.showDelete and e.deletable then
                    ImGui.SameLine(300)
                    if e.deleting then
                        C(Breathe(COL_DIM), "deleting...")
                    else
                        if ImGui.Button("Delete##del" .. e.name) then Try("delete button", QueueDelete, e) end
                        Tip("Permanently deletes this log file. It does not go to the Recycle Bin.")
                    end
                end
            end
        end
    end
end

-- One line saying where the search is. Returns text, colour ("" = nothing to say).
function LS.StatusLine()
    if LS.text ~= LS.active then
        if not LF.scanned then return "Reading the log folder first...", COL_DIM end
        return "Searching as soon as you stop typing...", COL_DIM
    end
    local s = LS.state
    if s == "idle" then return "", COL_DIM end
    if s == "short" then return "Type at least " .. LS.minChars .. " characters", COL_WARN end
    if s == "searching" then
        return string.format("Searching file %d of %d - %s of %s read - %d matching line(s)",
            LS.fileNo, LS.fileCount, FormatSize(LS.bytes), FormatSize(LS.totalBytes), LS.matches), Breathe(COL_OK)
    end
    local secs = (LS.finishedAt - LS.startedAt) / 1000
    if s == "stopped" then
        return string.format("Stopped - %d matching line(s) found so far", LS.matches), COL_WARN
    end
    if LS.capped then
        return string.format("Showing the first %d matching lines - add another word to narrow it down", LS.matches), COL_WARN
    end
    if LS.matches == 0 then
        return string.format("No line contains that - %d file(s), %s, searched in %.1f s", LS.fileCount, FormatSize(LS.totalBytes), secs), COL_DIM
    end
    return string.format("%d matching line(s) in %d file(s) - %d file(s), %s, searched in %.1f s",
        LS.matches, LS.filesHit, LS.fileCount, FormatSize(LS.totalBytes), secs), COL_OK
end

-- The results: a heading per file, then its matching lines in the console's colours.
function LS.DrawRows()
    local head = ANSI_RGB[36]
    for i = 1, #LS.rows do
        local r = LS.rows[i]
        if r.header then
            if i > 1 then ImGui.Spacing() end
            ImGui.TextColored(head[1], head[2], head[3], 1.0, r.header)
        else
            ImGui.PushStyleColor(ImGuiCol.Text, r.rgb[1], r.rgb[2], r.rgb[3], 1.0)
            Try("search row", ImGui.TextWrapped, r.text)
            ImGui.PopStyleColor(1)
        end
    end
end

local function SearchBody()
    local LX = 110
    ImGui.Text("  Search")
    ImGui.SameLine(LX)
    ImGui.SetNextItemWidth(300)
    local typed = ImGui.InputText("##dclsearch", LS.text, 256)
    if type(typed) == "string" and typed ~= LS.text then
        LS.text = typed
        LS.typedAt = NowMs()
    end

    local line, colour = LS.StatusLine()
    if line ~= "" then
        ImGui.Text("  Status")
        ImGui.SameLine(LX)
        CW(colour, line)
    end
    for i = 1, math.min(#LS.skipped, 3) do CW(COL_WARN, "  " .. LS.skipped[i]) end

    if LS.state == "searching" or LS.text ~= "" then RenderAction("SC_SearchClear") end
    if #LS.rows > 0 then
        RenderAction("SC_SearchCopy")
        ImGui.Spacing()
        local okChild, shown = pcall(ImGui.BeginChild, "##dclsresults", 0, 320, true)
        if okChild then
            if shown ~= false then Try("search results", LS.DrawRows) end
            ImGui.EndChild()
        else
            ReportError("search results", shown)
        end
    end
end

local function RenderLogsTab()
    LF.seenAt = NowMs()
    Box("Search the log files", SearchBody)
    Box("Log files", LogsBody)
end

local TYPE_TIPS = {
    code  = "Each batch of lines in a grey code block. Plain, and works on every Discord client.",
    ansi  = "A code block Discord colours: red errors, yellow warnings, green joins and so on.\nNeeds a reasonably recent Discord client.",
    plain = "The lines as ordinary chat text, with nothing added.\nMarkdown characters are escaped so every line shows exactly as logged.",
    embed = "The lines inside an embed card. Its stripe is red if the batch has an error,\nyellow for a warning.",
}

local function MessagesBody()
    ImGui.Text("Message types")
    for i = 1, #MSG_TYPES do
        local t = MSG_TYPES[i]
        if Radio(t.label .. "##dcmt" .. t.id, DC.msgType == t.id) then DC.msgType = t.id end
        Tip(TYPE_TIPS[t.id])
    end

    ImGui.Spacing()
    local b = Check("Include emojis##dcemoji", DC.emojis)
    if b ~= DC.emojis then DC.emojis = b end
    Tip("Puts emojis in front of matching lines")
end

local function FilterBody()
    local open = ImGui.CollapsingHeader("Message filter (" .. CountFiltersOn() .. " of " .. #FILTERS .. " on)###dcfilter")
    Tip("Choose which kinds of console lines are sent to Discord.\nEverything is on by default.")
    if not open then return end

    RenderAction("SC_FiltersOn")
    RenderAction("SC_FiltersOff")

    local lastGroup = nil
    for i = 1, #FILTERS do
        local f = FILTERS[i]
        if f.group ~= lastGroup then
            lastGroup = f.group
            ImGui.Spacing()
            C(COL_DIM, f.group)
        end
        local on = FilterOn(f.id)
        local v = Check(f.label .. "##dcf" .. f.id, on)
        if v ~= on then DC.filters[f.id] = v end
        Tip(f.tip)
    end
end

local function OldLogsBody()
    local LX = 130

    local d = Check("Delete old log files automatically##dcauto", DC.autoDelete)
    if d ~= DC.autoDelete then DC.autoDelete = d end
    Tip("Deletes Cherax logs older than the number of days below.")

    ImGui.Text("  Keep the last")
    ImGui.SameLine(LX)
    ImGui.SetNextItemWidth(80)
    local v = ImGui.InputInt("##dcdays", LF.daysRaw, 0, 0)
    if type(v) == "number" then
        LF.daysRaw = math.floor(v)
        DC.days = ClampDays(LF.daysRaw)
    end
    Tip("How many days of logs to keep (" .. MIN_DAYS .. " - " .. MAX_DAYS .. ").\nOlder logs are deleted while auto-delete is on.")
    ImGui.SameLine()
    C(COL_DIM, "days")

    ImGui.Spacing()
    if not LF.scanned then
        C(Breathe(COL_DIM), "  Reading the log folder...")
    else
        local list, bytes, approx = OlderThan(DC.days)
        if #list == 0 then
            C(COL_OK, "  No log files are older than " .. DC.days .. " day(s)")
        else
            local txt = string.format("  %d log file(s), %s, are older than %d day(s)", #list, FormatSize(bytes, approx), DC.days)
            if DC.autoDelete then
                CW(COL_WARN, txt .. " - deleting")
            else
                CW(COL_WARN, txt .. " - deleted when you switch this on")
            end
        end
    end
    if LF.cleanup ~= "" then CW(COL_DIM, "  " .. LF.cleanup) end
end

-- The keys currently bound to the buttons, each with a way to remove it. Bind a key by
-- hovering any button in the tabs and pressing F10.
local function HotkeysBody()
    local LX = 260
    local any = false
    for i = 1, #HOTKEYS do
        local h = HOTKEYS[i]
        local keys = h.registered and KeysFor(h.hash) or {}
        if #keys > 0 then
            any = true
            ImGui.Text("  " .. h.name)
            ImGui.SameLine(LX)
            C(COL_OK, KeyNames(keys))
            ImGui.SameLine()
            if ImGui.Button("Unbind##hkun" .. h.id) then Try("unbind", Unbind, h) end
            Tip("Removes the hotkey from this button.")
        end
    end
    if not any then C(COL_DIM, "  No hotkeys set yet") end
end

local function SupportBody()
    RenderAction("SC_JoinDiscord")
end

local function RenderSettingsTab()
    LF.seenAt = NowMs()      -- the preview below needs a fresh list too

    Box("Discord messages", MessagesBody)
    Box("Filter", FilterBody)
    Box("Old log files", OldLogsBody)
    Box("Hotkeys", HotkeysBody)
    Box("Support", SupportBody)

    -- The version, faint, at the bottom right. If the panel width cannot be read it
    -- simply sits on the left instead.
    local label = "v" .. VERSION
    ImGui.Spacing()
    pcall(function()
        local avail = ImGui.GetContentRegionAvail()
        local w = ImGui.CalcTextSize(label)
        if type(avail) == "number" and type(w) == "number" and avail > w + 16 then
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + avail - w - 8)
        end
    end)
    C(COL_FAINT, label)
end

-- One sub-tab. The Begin/End pair is outside the protected call, as for a box.
local function TabItem(label, body)
    local okItem, shown = pcall(ImGui.BeginTabItem, label)
    if not okItem then
        ReportError("tab " .. label, shown)
        return
    end
    if shown then
        Try(label .. " tab", body)
        ImGui.EndTabItem()
    end
end

-- BeginTabBar must be the first thing in the callback, or the sub-tab row is
-- drawn down inside the page instead of under the script's tab.
local function TabCallback()
    local okBar, bar = pcall(ImGui.BeginTabBar, "SmartConsoleTabs", 0)
    if not okBar then
        ReportError("tab bar", bar)
        return
    end
    if bar then
        TabItem("Console", RenderConsoleTab)
        TabItem("Log files", RenderLogsTab)
        TabItem("Settings", RenderSettingsTab)
        ImGui.EndTabBar()
    end
end

Try("registering the tab", function() ClickGUI.AddTab(SCRIPT_NAME, function() Try("tab", TabCallback) end) end)

-- ============================================================================
--  Start
-- ============================================================================
Try("loading settings", LoadConfig)
if DC.saved == nil then DC.saved = Serialize() end      -- LoadConfig did not get as far as setting it
Try("restoring hotkeys", ApplyHotkeys)
LF.daysRaw  = DC.days
LF.lastAuto = DC.autoDelete
LF.lastDays = DC.days
if DC.autoDelete then LF.pruneDueAt = NowMs() + PRUNE_FIRST_MS end
if DC.enabled then SetStatus("Streaming", false) end
Log(SCRIPT_NAME .. " v" .. VERSION .. " loaded on Cherax " .. CheraxInfo() .. (DC.enabled and " - resuming stream to " .. MaskedUrl() or ""))
