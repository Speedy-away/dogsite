-- ============================================================
--  HULK MODE v3.1  -  Lua script for Cherax (GTA V Enhanced 5.5.1.0)
--
--  E            : grab the vehicle, NPC, or scenery object aimed at by the
--                 crosshair (vehicle even if occupied by an NPC) / throw it
--                 ("charged throw" mode: hold E, then release)
--  X            : gently put it down
--  Left click   : super punch (bare-handed) on a vehicle, NPC or object
--
--  v4.1 : MENU REORGANISED
--   * One tab "HULK" with a tab bar: "HULK Mode" (everything) and a separate
--     "Playground" tab (buttons are the automatic fallback if the tab bar fails).
--     Each category is a small section function, so adding one is a single block. The XP / daily state now lives in one
--     table (XS) to stay under Lua's limit of 200 local variables.
--  v4.0 : SKILLS, UNLOCKS, DAILY CHALLENGE, ANTI-FARM, FRIENDS MODE
--   * Skill tree: 1 point per level gained, 5 skills x 5 ranks (grab range,
--     charge speed, rage gain, throw power, XP boost). Saved in the progress file.
--   * Level unlocks: LV 8 / 12 / 16 / 20 perks; GOD HULK = golden trajectory,
--     6th quest slot and faster max charge.
--   * Daily challenge: one bonus quest per day, double reward, saved.
--   * Anti-farm: repeating the same entity pays 60 / 35 / 20 / 10 percent XP.
--   * Friends Mode: a saved list of consenting players whose VEHICLES can be
--     affected even with Safe Mode on (players on foot are never affected).
--  v3.9 : HULK PROGRESSION SYSTEM (XP FROM ACTIONS + COMBOS)
--   * XP earned by acting, poured into the same points / level bar as the
--     quests: vehicle throw +25, NPC throw +15, object throw +10, super punch +10.
--   * Combos on launched entities (thrown or punched): Direct Impact +30,
--     Combo Bonus +20 (vehicle hits an NPC), Multi Hit +15..50, Chain Reaction
--     +25, Airborne Hit +15, Heavy Impact +20.
--   * Rampage x3 / x5 / x10: actions chained within 5 s give a flat bonus and
--     an XP multiplier (x1.25 / x1.5 / x2).
--   * On-screen XP feed + action summary ("+75 XP  COMBO X2") under the quest
--     panel. New "Hulk Progression XP" toggle. All values are in K.XP.
--  v3.8 : QUEST SYSTEM OVERHAUL + SAVED PROGRESSION
--   * 40+ quests (was 9) over 9 objectives: vehicles / NPCs / objects thrown,
--     any throw, punches, grabs, max-charge throws, wall smashes, max rage.
--     Harder quests unlock with the level, and the picker favours quests
--     that match your current level.
--   * Levels now get longer (400 pts, then +100 per level), with a rank title
--     (BANNER ... GOD HULK), a level progress bar and a level-up toast.
--     Higher levels unlock more quest slots (3 -> 4 at LV 4 -> 5 at LV 8).
--   * Reward colour shows the quest tier (gold / orange / red).
--   * PROGRESSION IS SAVED (HulkMode_progress.cfg next to the settings file):
--     points, level, quests done, active quests with their progress and the
--     all-time counters. It is written when a quest is completed, every few
--     seconds if something changed, and on script unload.
--  v3.7 : SUPER PUNCH THAT LANDS + LAYERED PUNCH SOUNDS
--   * The target is now re-checked (and re-picked if needed) at the moment of
--     impact instead of only at the click; a click that found nothing is no
--     longer thrown away.
--   * Denser aim-assist fan (7 rays, 23 with Wide Aim) and a "Soft-Lock":
--     if the crosshair misses, the closest vehicle/NPC in front is hit.
--   * Parked/idle vehicles are woken up before being pushed (their velocity
--     used to be ignored), NPCs are allowed to ragdoll, the network-control
--     wait is longer and the push lasts longer.
--   * Rapid clicking: a click made while a punch is landing is remembered.
--   * Punch sound: 3 layered styles (Classic / Heavy / Brutal) that grow with
--     rage, a lighter sound when hitting scenery.
--  v3.6 : BETTER TRAJECTORY PREVIEW
--   * Smooth arc: drawn from small steps, with raycasts only on longer chunks
--     (fewer, adaptive to the throw speed), and re-projected every frame so it
--     follows the camera without lag.
--   * Colour fades along the arc; coloured impact marker (ground / entity /
--     real player). A player in the line of fire gets a warning (marker,
--     status line and a toast).
--   * Impact distance shown in the status line.
--   * New settings: preview gravity (calibration), preview length, and
--     "only while charging".
--  v3.5 : BUG FIXES + TRAJECTORY / HULK PHYSICS / SOUNDS
--   * Settings are saved to a file and restored at load (they used to be
--     reset to the defaults every time the script started).
--   * Hotkeys are ignored while the pause menu or the chat is active, and
--     the grab/throw and drop keys can be changed from the menu.
--   * A carried NPC that dies mid-carry switches to the dead-body carry.
--   * Trajectory preview: an arc showing where the throw will land.
--   * (Hulk Physics category removed.)
--   * Sound effects (grab, charge, throw, drop, punch, rage, jump).
--  v3.4 : CARRIED NPCs ARE VISIBLE AGAIN
--   * Living NPC: classic "fireman's carry". The NPC plays its own carry
--     pose attached to the player's root (no ragdoll, which ignored the
--     attachment), AI/ragdoll blocked during the carry and restored after.
--   * Dead NPC: ragdoll attached to the player's root; its position is
--     fixed offsets (no menu category).
--  v3.3 : FIX + CLEANUP RELEASE (review of v3.2)
--   * Rage Mode now actually works: the meter decays over time (the decay
--     function was never called), punches build rage and are boosted by it,
--     and the meter is shown in the status line.
--   * Thrown NPCs no longer fall through the world (collision was left off).
--   * "Rage Power Bonus" can now really be set to 0 (a 0 value used to be
--     read back as the default 60%).
--   * Menu: Grab NPCs, Wide Aim Assist, Target Glow, Rage Mode, Rage Bonus,
--     Release Entities and the "Session Stats" category are now displayed.
--   * Aiming at an NPC sitting in a vehicle now targets the vehicle.
--   * Target Glow is throttled (it ran the full targeting every frame),
--     and no longer spams the log if the outline natives are unavailable.
--   * Settings are read once per tick (cfg) instead of dozens of times.
--   * Raycast: a single transient error no longer disables it for good, and
--     the hit-point memory layout is validated against the ray itself.
--   * Entities we flagged as mission entities are released ~10 s after use
--     (they used to stay in the world forever).
--   * Vehicles also get the "re-apply velocity" treatment after a throw.
--   * Carried NPCs stay limp for the whole carry, and keep collision off.
--   * Cleanup on script unload.
--
--  "Safe mode" (on by default) ignores vehicles occupied by other players;
--  players themselves are never hit, and are never grabbable as NPCs
--  either. Built for solo play or with consenting friends. Reviewed but
--  NOT tested in-game.
-- ============================================================

local K = {}   -- constants grouped in one table (avoids the 200-locals limit)
K.SUITE_VERSION = "Hulk Mode vBETA"

local Common = {}   -- shared utilities


-- ============================================================
--  0) SHARED UTILITIES
-- ============================================================

function Common.clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

-- Toast: try the version with a screen position, then fall back to the
-- plain version.
function Common.toast(title, message, duration)
    duration = duration or 3000
    local ok = pcall(function()
        GUI.AddToast(title, tostring(message), duration, eToastPos.TOP_RIGHT)
    end)
    if not ok then
        pcall(function()
            GUI.AddToast(title, tostring(message), duration)
        end)
    end
end

local function toIntValue(v)
    return math.floor(tonumber(v) or 0)
end

local function toFloatValue(v)
    return (tonumber(v) or 0) + 0.0
end

-- Force a toggle's state (without depending on a single API variant).
function Common.setToggle(hash, wanted)
    local ok, current = pcall(FeatureMgr.IsFeatureToggled, hash)
    if ok and current ~= nil then
        if current ~= wanted then
            pcall(FeatureMgr.ToggleFeature, hash)
        end
        return true
    end
    return (pcall(function() FeatureMgr.GetFeature(hash):SetValue(wanted) end))
end

-- Numeric values: SliderFloat always receives floats, SliderInt always
-- integers (Lua 5.4 distinguishes the two numeric subtypes).
function Common.setFloat(hash, value)
    local v = toFloatValue(value)
    local ok = pcall(FeatureMgr.SetFeatureFloat, hash, v)
    if not ok then
        pcall(function() FeatureMgr.GetFeature(hash):SetFloatValue(v) end)
    end
end

function Common.setInt(hash, value)
    local v = toIntValue(value)
    local ok = pcall(FeatureMgr.SetFeatureInt, hash, v)
    if not ok then
        pcall(function() FeatureMgr.GetFeature(hash):SetIntValue(v) end)
    end
end

-- Configure a SliderFloat: limits/step as floats.
function Common.configureFloatSlider(hash, minimum, maximum, step, fastStep)
    local feature = FeatureMgr.GetFeature(hash)
    if not feature then
        return false
    end
    local okLimits = pcall(function()
        feature:SetLimitValues(toFloatValue(minimum), toFloatValue(maximum))
    end)
    if step ~= nil then
        pcall(function() feature:SetStepSize(toFloatValue(step)) end)
    end
    if fastStep ~= nil then
        pcall(function() feature:SetFastStepSize(toFloatValue(fastStep)) end)
    end
    return okLimits
end

-- Configure a SliderInt: limits/step as integers.
function Common.configureIntSlider(hash, minimum, maximum, step, fastStep)
    local feature = FeatureMgr.GetFeature(hash)
    if not feature then
        return false
    end
    local okLimits = pcall(function()
        feature:SetLimitValues(toIntValue(minimum), toIntValue(maximum))
    end)
    if step ~= nil then
        pcall(function() feature:SetStepSize(toIntValue(step)) end)
    end
    if fastStep ~= nil then
        pcall(function() feature:SetFastStepSize(toIntValue(fastStep)) end)
    end
    return okLimits
end

-- ---------- memory access (native output params / pointers) ----------
-- Cherax requires real memory regions (Memory.Alloc) for natives' pointer
-- parameters. The exact read/write function names aren't guaranteed, so we
-- try several common ones.

K.READ_INT_NAMES   = { "ReadInt", "ReadS32", "ReadInt32", "ReadDword", "ReadU32" }
K.READ_FLOAT_NAMES = { "ReadFloat", "ReadF32", "ReadSingle" }
K.WRITE_INT_NAMES  = { "WriteInt", "WriteS32", "WriteInt32", "WriteDword", "WriteU32" }

local function memTry(names, ptr, off, value)
    for _, name in ipairs(names) do
        local fn = Memory[name]
        if type(fn) == "function" then
            local okAddr, addr = pcall(function() return ptr + (off or 0) end)
            if not okAddr then addr = ptr end
            local ok, v
            if value ~= nil then
                ok, v = pcall(fn, addr, value)
            else
                ok, v = pcall(fn, addr)
            end
            if ok then
                return true, v
            end
        end
    end
    return false, nil
end

function Common.memReadInt(ptr, off)
    local ok, v = memTry(K.READ_INT_NAMES, ptr, off)
    return ok and v or nil
end

function Common.memReadFloat(ptr, off)
    local ok, v = memTry(K.READ_FLOAT_NAMES, ptr, off)
    return ok and v or nil
end

-- Returns true if the write succeeded.
function Common.memWriteInt(ptr, value)
    local ok = memTry(K.WRITE_INT_NAMES, ptr, 0, value)
    return ok
end


-- ============================================================
--  0) SHARED UTILITIES (end)
-- ============================================================

do

-- ============================================================
--  1) DEFAULT SETTINGS (also editable live from the menu)
-- ============================================================

K.DEFAULTS = {
    grabRadius   = 8.0,    -- range to grab something (m)
    throwSpeed   = 180.0,  -- max throw speed
    throwMinPct  = 0.25,   -- charged throw: minimum power (fraction of throwSpeed)
    chargeMs     = 1500,   -- time to reach max power
    punchRadius  = 4.5,    -- fallback range if the raycast is unavailable
    punchDelayMs = 300,    -- delay between the click and the punch's effect (ms)
    punchRange   = 6.0,    -- super punch range along the crosshair's axis (m)
    punchSpeed   = 135.0,
}

-- ---- skill tree / level unlocks (see the quest block for the logic) ----
K.playerLevel = 1          -- refreshed every tick by the quest system
K.skillRanks  = {}         -- [skill id] = rank, saved in HulkMode_progress.cfg
K.SKILLS = {
    { id = "grab",   name = "Grab Range",   per = "+1 m grab range",        max = 5 },
    -- NOTE: no percent sign in any text shown by the menu (it is read as a printf code and crashes).
    { id = "charge", name = "Charge Speed", per = "-8 pct charge time",     max = 5 },
    { id = "rage",   name = "Rage Gain",    per = "+10 pct rage per hit",   max = 5 },
    { id = "power",  name = "Throw Power",  per = "+4 pct throw speed",     max = 5 },
    { id = "xp",     name = "XP Boost",     per = "+5 pct XP from actions", max = 5 },
}
K.SKILL_BY_ID = {}
for _, s in ipairs(K.SKILLS) do K.SKILL_BY_ID[s.id] = s end
K.UNLOCKS = {   -- { level, title, effect }
    { 8,  "HULK",          "Charge time -10 pct" },
    { 12, "SAVAGE HULK",   "Rage decays 25 pct slower" },
    { 16, "WORLD BREAKER", "XP from actions +10 pct" },
    { 20, "GOD HULK",      "Golden trajectory, 6th quest slot, charge time -15 pct" },
}
K.FARM_STEPS = { 1.0, 0.6, 0.35, 0.2, 0.1 }   -- XP factor for the 1st, 2nd, ... repeat on the same entity

K.THROW_UP_BOOST    = 0.0
K.THROW_START_AHEAD = 5.0
K.PUNCH_UP_BOOST    = 16.0
K.PUNCH_CONTROL     = 24      -- INPUT_ATTACK
K.PUNCH_COOLDOWN_MS = 200


K.CARRY_OFFSET_X, K.CARRY_OFFSET_Y, K.CARRY_OFFSET_Z = 0.0, 0.0, 2.0
K.CARRY_ANIM_DICT = "random@mugging3"
K.CARRY_ANIM_CLIP = "handsup_standing_base"
-- NPCs: the player holds the arms pose of the classic "fireman's carry"
-- while the NPC plays the matching pose attached to the player's root.
-- Vehicles/props keep the Hulk pose above.
K.NPC_CARRY_ANIM_DICT = "missfinale_c2mcs_1"
K.NPC_CARRY_ANIM_CLIP = "fin_c2_mcs_1_camman"
K.NPC_BODY_ANIM_DICT  = "nm"
K.NPC_BODY_ANIM_CLIP  = "firemans_carry"
-- x, y, z, rotX, rotY, rotZ relative to the player (living NPC)
K.NPC_ALIVE_OFFSET = { 0.27, 0.15, 0.63, 0.5, 0.5, 0.0 }
-- starting values of the tunable offsets for a DEAD NPC (menu sliders)
K.NPC_DEAD_DEFAULT = { 0.27, 0.15, 0.63, 0.5, 0.5, 0.0 }
K.NPC_DICT_WAIT_MS = 1500   -- max wait for the NPC animation to load

-- Hotkeys are chosen from this list (menu sliders store the index).
K.KEY_CHOICES = {
    { "E", 0x45 }, { "Q", 0x51 }, { "F", 0x46 }, { "R", 0x52 },
    { "G", 0x47 }, { "V", 0x56 }, { "Z", 0x5A }, { "C", 0x43 },
    { "X", 0x58 }, { "B", 0x42 }, { "H", 0x48 }, { "N", 0x4E },
}
K.DEFAULT_GRAB_KEY_INDEX = 1   -- E
K.DEFAULT_DROP_KEY_INDEX = 9   -- X (put down without throwing)


K.ACTION_COOLDOWN_MS = 400
K.CONTROL_TIMEOUT_MS = 1500


K.VEHICLE_SEARCH_FLAGS = { 70, 12294, 16384, 71, 2, 0 }
K.MAX_SEATS_TO_CHECK   = 8     -- seats -1 .. 6

K.RAY_FLAGS     = 511    -- the ray hits everything: scenery, vehicles, peds, objects...
K.RAY_MAX_FAILURES = 5   -- consecutive raycast errors before giving up on rays
K.SAMPLE_STEP   = 2.5    -- fallback: step along the crosshair's axis when sampling (m)
K.SAMPLE_RADIUS = 4.0    -- fallback: search radius at each sample point (m)


K.USE_NATIVE_OUTLINE = false   -- needs the two hashes in K.NATIVE fixed (see there)
K.DEBUG = false   -- verbose console: menu toggle "Verbose Console" (HULK Mode page)

-- Target kinds, used consistently everywhere in this script.
K.KIND_VEHICLE = "vehicle"
K.KIND_OBJECT  = "object"
K.KIND_NPC     = "npc"

-- ---- Rage Mode: the more you smash, the harder you hit ----
K.RAGE_PER_HIT          = 18.0   -- rage gained per landed punch or throw
K.RAGE_DECAY_PER_SEC    = 14.0   -- rage lost per second once idle
K.RAGE_IDLE_DELAY_MS    = 1500   -- time without a hit before rage starts decaying
K.DEFAULT_RAGE_BONUS_PCT = 60.0  -- % extra power at 100 rage (editable from the menu)


-- ---- entity cleanup ----
K.RELEASE_DELAY_MS = 10000       -- release mission-entity flag this long after use

-- ---- target glow ----
K.HIGHLIGHT_INTERVAL_MS = 80     -- how often the glow target is recomputed



-- ============================================================
--  2) NATIVES (double-check against citizenfx/natives if a
--     function doesn't react as expected)
-- ============================================================

K.NATIVE = {
    PLAYER_PED_ID               = 0xD80958FC74E988A6,
    GET_ENTITY_COORDS           = 0x3FEF770D40960D5A,
    SET_ENTITY_VELOCITY         = 0x1C99BB7B6E96D16F,
    DOES_ENTITY_EXIST           = 0x7239B21A38F536BA,
    IS_ENTITY_DEAD              = 0x5F9532F3B5CC2551,
    IS_PED_IN_ANY_VEHICLE       = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN       = 0x9A9112A0FE9A4713,  -- VERIFY
    SET_PED_CAN_RAGDOLL         = 0xB128377056A54E2A,  -- VERIFY
    SET_SUPER_JUMP_THIS_FRAME   = 0x57FFF03E423A26AB,  -- VERIFY (native super jump, must be called every frame)
    SET_BLOCKING_OF_NON_TEMPORARY_EVENTS = 0x9F8AA94D6D97DBF4,  -- VERIFY
    PLAYER_ID                   = 0x4F8644AF03D0E0D6,
    SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER = 0x6DB47AA77FD94E09,  -- VERIFY
    GET_ENTITY_VELOCITY         = 0x4805D2B1D8CF94A9,
    IS_ENTITY_IN_AIR            = 0x886E37EC497200B6,  -- VERIFY
    GET_ENTITY_HEALTH           = 0xEEF059FAD016D209,
    SET_ENTITY_HEALTH           = 0x6B76DC1F3AE6E6A3,
    GET_SCREEN_COORD_FROM_WORLD_COORD = 0x34E82F05DF2974F5,
    PLAY_SOUND_FRONTEND         = 0x67C540AA08E4A6F5,
    IS_PAUSE_MENU_ACTIVE        = 0xB0034A223497FFCB,
    GET_CLOSEST_VEHICLE         = 0xF73EB622C4F1689B,
    GET_PED_IN_VEHICLE_SEAT     = 0xBB40DD2270B65366,
    ATTACH_ENTITY_TO_ENTITY     = 0x6B9BBD38AB0796DF,
    GET_PED_BONE_INDEX          = 0x3F428D08BE5AAE31,
    DETACH_ENTITY               = 0x961AC54BF0613F5D,
    SET_ENTITY_COLLISION        = 0x1A9205C1B9EE827F,
    SET_ENTITY_AS_MISSION_ENTITY = 0xAD738C3085FE7E11,
    IS_ENTITY_A_MISSION_ENTITY  = 0x0A7B270912999B3C,  -- VERIFY
    SET_ENTITY_AS_NO_LONGER_NEEDED = 0xB736A491E64A32CF, -- VERIFY (takes Entity*)
    SHAKE_GAMEPLAY_CAM          = 0xFD55E49555E017CF,
    GET_GAMEPLAY_CAM_ROT        = 0x837765A25378F0BB,
    NETWORK_REQUEST_CONTROL_OF_ENTITY = 0xB69317BF5E782347,
    NETWORK_HAS_CONTROL_OF_ENTITY     = 0x01BF60A500E28887,
    REQUEST_ANIM_DICT           = 0xD3BD40951412FEF6,
    HAS_ANIM_DICT_LOADED        = 0xD031A9162D01088C,
    TASK_PLAY_ANIM              = 0xEA47FE3719165B94,
    STOP_ANIM_TASK              = 0x97FF36A1D40EA00A,
    CLEAR_PED_TASKS             = 0xE1EF3C1216AFF2CD,
    IS_CONTROL_JUST_PRESSED     = 0x580417101DDB492F,
    GET_SELECTED_PED_WEAPON     = 0x0A6DB4965674D243,
    GET_RANDOM_PED_AT_COORD     = 0x876046A8E3A4B71C,
    IS_PED_A_PLAYER             = 0x12534C348C6CB68B,
    SET_PED_TO_RAGDOLL          = 0xAE99FB955581844A,
    SET_ENTITY_COORDS_NO_OFFSET = 0x239A3351AC1DA385,
    GET_GAMEPLAY_CAM_COORD      = 0xA200EB1EE790F448,
    IS_ENTITY_ATTACHED          = 0xB346476EF1A64897,
    SET_ENTITY_DYNAMIC          = 0x1718DE8E3F2823CA,
    CLEAR_PED_TASKS_IMMEDIATELY = 0xAAA34F8A7CB32098,
    ACTIVATE_PHYSICS            = 0x710311ADF0E20730,
    IS_DISABLED_CONTROL_JUST_PRESSED = 0x91AEF906BCA88877,
    GET_ENTITY_TYPE             = 0x8ACD366038D14505,  -- 1 ped, 2 vehicle, 3 object
    FREEZE_ENTITY_POSITION      = 0x428CA6DBD1094446,
    START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE = 0x377906D8A31E5586,
    GET_SHAPE_TEST_RESULT       = 0x3D87450E15D98694,
    -- WRONG HASHES: Cherax answers "Failed to find 0x76180407 / 0xB41A56C2 native's
    -- handler" in the console every time they are called, because they are
    -- 32-bit values, not 64-bit PC native hashes. They are NOT called any more
    -- (see K.USE_NATIVE_OUTLINE); put the real 64-bit hashes here, then set the
    -- flag to true. Until then the green reticle brackets mark the target.
    SET_ENTITY_DRAW_OUTLINE     = 0x76180407,
    SET_ENTITY_DRAW_OUTLINE_COLOR = 0xB41A56C2,
    SET_ENTITY_DRAW_OUTLINE_SHADER = 0xB9EA40907C680580,
    GET_VEHICLE_CLASS           = 0x29439776AAA00A62,  -- VERIFY (used for "Heavy Impact")
    NETWORK_GET_PLAYER_INDEX_FROM_PED = 0x6C0E2E0125610278,  -- VERIFY (Friends Mode)
    GET_PLAYER_NAME             = 0x6D0DE6A7B5DA71F8,  -- VERIFY (Friends Mode)
}


-- ============================================================
--  3) UTILITIES
-- ============================================================

-- Console policy: only important information and errors reach the Cherax
-- console. Everything else is "verbose" and stays hidden unless the
-- "Verbose Console" toggle is on.
--   K.logInfo(msg)   important information (shown after the banner)
--   K.logWarn(msg)   a problem, the script keeps working
--   K.logError(msg)  an error
--   log(msg)         verbose detail (grabs, throws, punches...), debug only
K.LOG_TAG = "[HULK] "
K.bannerShown, K.logQueue = false, {}

function K.logEmit(level, msg)
    if not K.bannerShown and level ~= "error" then
        K.logQueue[#K.logQueue + 1] = { level, msg }   -- printed right after the banner
        return
    end
    local text = K.LOG_TAG .. ((level == "warn") and "WARNING: " or "") .. msg
    pcall(level == "error" and Logger.LogError or Logger.LogInfo, text)
end
function K.logInfo(msg)  K.logEmit("info", msg) end
function K.logWarn(msg)  K.logEmit("warn", msg) end
function K.logError(msg) K.logEmit("error", msg) end

local function log(message)
    if K.DEBUG then
        pcall(Logger.LogInfo, K.LOG_TAG .. "(debug) " .. message)
    end
end

-- Startup banner, printed once when the script starts.
K.BANNER = {
    "██╗  ██╗██╗   ██╗██╗     ██╗  ██╗",
    "██║  ██║██║   ██║██║     ██║ ██╔╝",
    "███████║██║   ██║██║     █████╔╝ ",
    "██╔══██║██║   ██║██║     ██╔═██╗ ",
    "██║  ██║╚██████╔╝███████╗██║  ██╗",
    "╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝",
}
function K.printBanner()
    if K.bannerShown then return end
    pcall(function()
        for _, line in ipairs(K.BANNER) do Logger.LogInfo(line) end
        Logger.LogInfo(K.SUITE_VERSION .. "  |  by " .. K.CREDITS_AUTHOR .. "  |  " .. K.DISCORD_URL)
    end)
    K.bannerShown = true
    for _, e in ipairs(K.logQueue) do K.logEmit(e[1], e[2]) end   -- notes gathered during loading
    K.logQueue = {}
end

local function toast(msg, ms)
    Common.toast("Hulk Mode", msg, ms or 2500)
end

-- Runs a secondary module in its own pcall: an error there can no longer stop
-- the main loop (grab / throw). Each distinct error is logged only once.
function K.guard(name, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local msg = tostring(err)
        if K["gerr_" .. name] ~= msg then
            K["gerr_" .. name] = msg
            K.logError("module '" .. name .. "' failed: " .. msg)
        end
    end
end

function K.rayToast()
    if not K.rayToastShown then
        K.rayToastShown = true
        toast("Raycast indisponible : seuls les véhicules proches sont attrapables.", 5000)
    end
end

local clamp = Common.clamp

local function distSq(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end

local memReadInt   = Common.memReadInt
local memReadFloat = Common.memReadFloat
local memWriteInt  = Common.memWriteInt


-- ============================================================
--  4) MENU
-- ============================================================

local H = {
    toggle  = Utils.Joaat("HulkModeToggle"),
    safe    = Utils.Joaat("HulkModeSafe"),
    charged = Utils.Joaat("HulkModeCharged"),
    punch   = Utils.Joaat("HulkModePunch"),
    shake   = Utils.Joaat("HulkModeShake"),
    cross   = Utils.Joaat("HulkModeCrosshair"),
    speed   = Utils.Joaat("HulkModeThrowSpeed"),
    radius  = Utils.Joaat("HulkModeGrabRadius"),
    pspeed  = Utils.Joaat("HulkModePunchSpeed"),
    prange  = Utils.Joaat("HulkModePunchRange"),
    impact  = Utils.Joaat("HulkModeImpact"),
    pdelay  = Utils.Joaat("HulkModePunchDelay"),
    rage    = Utils.Joaat("HulkModeRage"),
    rageBonus = Utils.Joaat("HulkModeRageBonus"),
    grabNpc = Utils.Joaat("HulkModeGrabNpc"),
    wideAim = Utils.Joaat("HulkModeWideAim"),
    highlight = Utils.Joaat("HulkModeTargetHighlight"),
    cleanup = Utils.Joaat("HulkModeCleanup"),
    trajectory  = Utils.Joaat("HulkModeTrajectory"),
    sounds      = Utils.Joaat("HulkModeSounds"),
    quests      = Utils.Joaat("HulkModeQuests"),
    keyGrab     = Utils.Joaat("HulkModeKeyGrab"),
    keyDrop     = Utils.Joaat("HulkModeKeyDrop"),
    trajChargeOnly = Utils.Joaat("HulkModeTrajChargeOnly"),
    trajGravity    = Utils.Joaat("HulkModeTrajGravity"),
    trajLength     = Utils.Joaat("HulkModeTrajLength"),
    softLock       = Utils.Joaat("HulkModePunchSoftLock"),
    punchSound     = Utils.Joaat("HulkModePunchSound"),
    xp             = Utils.Joaat("HulkModeXP"),
    discord        = Utils.Joaat("HulkModeCopyDiscord"),
    friends        = Utils.Joaat("HulkModeFriends"),
    friendAdd      = Utils.Joaat("HulkModeFriendAdd"),
    friendClear    = Utils.Joaat("HulkModeFriendClear"),
    skillReset     = Utils.Joaat("HulkModeSkillReset"),
    navHulk        = Utils.Joaat("HulkModeNavHulk"),
    navPlay        = Utils.Joaat("HulkModeNavPlayground"),
    companion      = Utils.Joaat("HulkModeCompanion"),
    companionType  = Utils.Joaat("HulkModeCompanionType"),
    petSpeed       = Utils.Joaat("HulkModeCompanionSpeed"),
    petInvincible  = Utils.Joaat("HulkModeCompanionInvincible"),
    petCall        = Utils.Joaat("HulkModeCompanionCall"),
    petRespawn     = Utils.Joaat("HulkModeCompanionRespawn"),
    guard          = Utils.Joaat("HulkModeBodyguard"),
    guardWeapon    = Utils.Joaat("HulkModeGuardWeapon"),
    guardRadius    = Utils.Joaat("HulkModeGuardRadius"),
    guardHolster   = Utils.Joaat("HulkModeGuardHolster"),
    mgX  = Utils.Joaat("HulkModeMonkeyGunX"),   mgY  = Utils.Joaat("HulkModeMonkeyGunY"),
    mgZ  = Utils.Joaat("HulkModeMonkeyGunZ"),   mgRX = Utils.Joaat("HulkModeMonkeyGunRotX"),
    mgRY = Utils.Joaat("HulkModeMonkeyGunRotY"), mgRZ = Utils.Joaat("HulkModeMonkeyGunRotZ"),
    mgBone  = Utils.Joaat("HulkModeMonkeyGunBone"),
    mgReset = Utils.Joaat("HulkModeMonkeyGunReset"),
    debug          = Utils.Joaat("HulkModeVerboseConsole"),
}

K.ui = { page = "hulk" }   -- page shown in the HULK tab ("hulk" or "playground")

K.CREDITS_AUTHOR = "@fuzokz"
K.DISCORD_URL    = "https://discord.gg/7684mS5XJV"

-- Copies text to the clipboard. The exact API varies between Cherax builds
-- (VERIFY), so several variants are tried. Returns true if one did not error.
function K.copyToClipboard(text)
    local attempts = {
        function() ImGui.SetClipboardText(text) end,
        function() Utils.SetClipboardText(text) end,
        function() Clipboard.SetText(text) end,
    }
    for _, fn in ipairs(attempts) do
        if pcall(fn) then return true end
    end
    return false
end

FeatureMgr.AddFeature(H.toggle,  "Hulk Mode", eFeatureType.Toggle, "E: grab / throw a vehicle, NPC, or a scenery object.")
FeatureMgr.AddFeature(H.safe,    "Safe Mode (ignore players)", eFeatureType.Toggle, "Never affects players, or vehicles they're riding in.")
FeatureMgr.AddFeature(H.charged, "Charged Throw", eFeatureType.Toggle, "Hold E to charge, release to throw.")
FeatureMgr.AddFeature(H.grabNpc, "Grab NPCs", eFeatureType.Toggle, "E can also grab a person in the crosshair, not just vehicles/objects. Real players are never affected.")
FeatureMgr.AddFeature(H.cleanup, "Release Entities After Use", eFeatureType.Toggle, "Lets the game clean up things you grabbed (a few seconds after you throw or drop them) instead of keeping them in the world forever.")
FeatureMgr.AddFeature(H.punch,   "Super Punch", eFeatureType.Toggle, "Left click while unarmed: launches a vehicle or an NPC.")
FeatureMgr.AddFeature(H.wideAim, "Wide Aim Assist", eFeatureType.Toggle, "Adds extra outer rays to the super punch's targeting for easier hits.")
FeatureMgr.AddFeature(H.softLock, "Punch Soft-Lock", eFeatureType.Toggle, "If the crosshair misses, the closest vehicle or NPC in front of you (within a few meters) is hit anyway.")
FeatureMgr.AddFeature(H.punchSound, "Punch Sound Style", eFeatureType.SliderInt, "1 = Classic, 2 = Heavy, 3 = Brutal (layered, grows with rage). Needs Sound Effects on.")
FeatureMgr.AddFeature(H.highlight, "Target Glow", eFeatureType.Toggle, "Marks the exact target Hulk Mode would grab with E (reticle brackets).")
FeatureMgr.AddFeature(H.shake,   "Camera Shake", eFeatureType.Toggle, "Shake effects when grabbing and throwing.")
FeatureMgr.AddFeature(H.cross,   "Crosshair", eFeatureType.Toggle, "Small crosshair at the center of the screen.")
FeatureMgr.AddFeature(H.speed,   "Throw Speed", eFeatureType.SliderFloat, "Maximum throw speed.")
FeatureMgr.AddFeature(H.radius,  "Grab Range (m)", eFeatureType.SliderFloat, "Maximum distance to grab a vehicle.")
FeatureMgr.AddFeature(H.pspeed,  "Super Punch Power", eFeatureType.SliderFloat, "Velocity given to the target.")
FeatureMgr.AddFeature(H.prange,  "Super Punch Range (m)", eFeatureType.SliderFloat, "Maximum punch distance, along the crosshair's axis.")
FeatureMgr.AddFeature(H.pdelay,  "Super Punch Delay (ms)", eFeatureType.SliderFloat, "Time between the click and the effect (fist impact).")
FeatureMgr.AddFeature(H.impact,  "Scenery Impact Shake", eFeatureType.Toggle, "Hitting a wall or the ground triggers a strong camera shake (no explosion).")
FeatureMgr.AddFeature(H.rage,    "Rage Mode", eFeatureType.Toggle, "Landing hits builds up rage, which temporarily boosts your power. Decays when you stop smashing things.")
FeatureMgr.AddFeature(H.rageBonus, "Rage Power Bonus (%)", eFeatureType.SliderFloat, "Extra power applied at maximum (100%) rage.")
FeatureMgr.AddFeature(H.trajectory, "Trajectory Preview", eFeatureType.Toggle, "Draws an approximate arc of where the carried object will go when thrown.")
FeatureMgr.AddFeature(H.sounds, "Sound Effects", eFeatureType.Toggle, "Short sounds when grabbing, charging, throwing, dropping and punching.")
FeatureMgr.AddFeature(H.quests, "Quest Popup", eFeatureType.Toggle, "On-screen quest panel (visible even when the menu is closed). Press F8 to hide / show it quickly.")
FeatureMgr.AddFeature(H.xp, "Hulk Progression XP", eFeatureType.Toggle, "Earn XP for what you do (throws, punches, impacts, combos, rampage). It fills the same level bar as the quests.")
FeatureMgr.AddFeature(H.discord, "Copy Discord Link", eFeatureType.Button, "Copies the Discord invite link to your clipboard.", function()
    if K.copyToClipboard(K.DISCORD_URL) then
        Common.toast("Hulk Mode", "Discord link copied to the clipboard!", 3000)
    else
        Common.toast("Hulk Mode", "Could not copy automatically. Link: " .. K.DISCORD_URL, 6000)
    end
end)
FeatureMgr.AddFeature(H.debug, "Verbose Console", eFeatureType.Toggle, "Print every detail (grabs, throws, punches...) in the Cherax console. Off: only important information and errors are shown.")
FeatureMgr.AddFeature(H.navHulk, "HULK Mode", eFeatureType.Button, "Show the HULK Mode page.", function()
    K.ui.page = "hulk"
end)
K.PG = {
    pet = nil, petType = 0, petRetryAt = 0, petFollowAt = 0, petTaskAt = 0,
    petFollowing = false, petLoadSince = 0, petDist = nil, speedUsed = nil,
    callRequested = false, respawnRequested = false, lastErr = nil, PICK = {}, WPICK = {},
    guardTarget = nil, guardScanAt = 0, guardCalmAt = 0, combatAt = 0, drawn = false, loadoutKey = nil,
    lastPlayerHp = nil, lastArmor = nil, hurtSince = 0, scanLogAt = 0,
    nearBroken = false, damageFlagBroken = false, nearBuf = nil, nearStride = 8,
    prop = nil, propKey = nil, propWanted = false, propRetryAt = 0, nextShotAt = 0,
    UNARMED = 0xA2719263,
    -- Bones the chimp's weapon can be attached to: { label, { bone ids tried in order } }.
    -- 6286 = PH_R_Hand (weapon grip), 28422 = SKEL_R_Hand, 18905 = SKEL_L_Hand.
    -- An empty list = the body itself (old behaviour).
    GUN_BONES = { { "Auto (right hand)", { 6286, 28422 } }, { "Right hand grip", { 6286 } },
                  { "Right hand", { 28422 } }, { "Left hand", { 18905 } }, { "Body", {} } },
    boneSel = nil, boneFor = nil, boneIdx = 0,
    -- { name, model, ped type, weapons through the script } : 28 = animal (bites), 4 = human (native weapons)
    PETS = { { "Chop", "a_c_chop", 28 }, { "Husky", "a_c_husky", 28 }, { "Pug", "a_c_pug", 28 },
             { "Retriever", "a_c_retriever", 28 }, { "Chimp", "a_c_chimp", 28, true }, { "Cat", "a_c_cat_01", 28 },
             { "Security Guard", "s_m_m_security_01", 4 }, { "Black Ops", "s_m_y_blackops_01", 4 },
             { "SWAT", "s_m_y_swat_01", 4 } },
    -- { name, weapon hash } : 0 = bare hands
    WEAPONS = { { "Fists", 0 }, { "Pistol", 0x1B06D571 }, { "SMG", 0x2BE6766B },
                { "Shotgun", 0x1D073A89 }, { "Assault Rifle", 0xBFEFFF6D } },
    -- Companions that can't use a weapon natively (the chimp): the weapon is a prop in
    -- its hands and the script fires the bullets. Index = WEAPONS index:
    -- { world model, seconds between shots, damage per bullet }
    GUNS = { [2] = { "w_pi_pistol", 0.38, 26 }, [3] = { "w_sb_smg", 0.10, 22 },
             [4] = { "w_sg_pumpshotgun", 0.95, 45 }, [5] = { "w_ar_assaultrifle", 0.13, 30 } },
}
FeatureMgr.AddFeature(H.navPlay, "Playground", eFeatureType.Button, "Show the Playground page.", function()
    K.ui.page = "playground"
end)
FeatureMgr.AddFeature(H.companion, "Companion", eFeatureType.Toggle, "Your companion (animal or bodyguard) follows you everywhere. It is only visible to you.")
FeatureMgr.AddFeature(H.companionType, "Companion Type", eFeatureType.SliderInt, "Which companion follows you (use the buttons of the Companion category).")
for i, pet in ipairs(K.PG.PETS) do
    K.PG.PICK[i] = Utils.Joaat("HulkModeCompanionPick" .. i)
    FeatureMgr.AddFeature(K.PG.PICK[i], pet[1], eFeatureType.Button, "Choose " .. pet[1] .. " as your companion.", function()
        Common.setInt(H.companionType, i)
    end)
end
FeatureMgr.AddFeature(H.petSpeed, "Follow Speed", eFeatureType.SliderFloat, "How fast your companion moves to keep up with you (1 = walk, 3 = sprint).")
FeatureMgr.AddFeature(H.petInvincible, "Invincible Companion", eFeatureType.Toggle, "Your companion cannot be hurt.")
FeatureMgr.AddFeature(H.petCall, "Call Companion", eFeatureType.Button, "Brings your companion right next to you.", function()
    K.PG.callRequested = true
end)
FeatureMgr.AddFeature(H.petRespawn, "Respawn Companion", eFeatureType.Button, "Removes your companion and creates a new one (use it if it gets stuck).", function()
    K.PG.respawnRequested = true
end)
FeatureMgr.AddFeature(H.guard, "Bodyguard Mode", eFeatureType.Toggle, "Your companion protects you: it fights NPCs that attack you. Real players and the police are never targeted.")
FeatureMgr.AddFeature(H.guardWeapon, "Bodyguard Weapon", eFeatureType.SliderInt, "Which weapon a human companion or the chimp uses (use the buttons of the Bodyguard category).")
for i, w in ipairs(K.PG.WEAPONS) do
    K.PG.WPICK[i] = Utils.Joaat("HulkModeGuardPick" .. i)
    FeatureMgr.AddFeature(K.PG.WPICK[i], w[1], eFeatureType.Button, "Bodyguard weapon: " .. w[1] .. ".", function()
        Common.setInt(H.guardWeapon, i)
    end)
end
FeatureMgr.AddFeature(H.guardRadius, "Guard Radius (m)", eFeatureType.SliderFloat, "How far around you the bodyguard watches for attackers.")
FeatureMgr.AddFeature(H.guardHolster, "Draw Weapon Only In A Fight", eFeatureType.Toggle, "On: the weapon is put away when all is calm and drawn when someone attacks you. Off: it stays in hand.")
for _, mg in ipairs({ { H.mgX, "Monkey Weapon X" }, { H.mgY, "Monkey Weapon Y" }, { H.mgZ, "Monkey Weapon Z" } }) do
    FeatureMgr.AddFeature(mg[1], mg[2], eFeatureType.SliderFloat, "Where the chimp holds its weapon, relative to its body (m). Applied live.")
end
for _, mg in ipairs({ { H.mgRX, "Monkey Weapon Rotation X" }, { H.mgRY, "Monkey Weapon Rotation Y" }, { H.mgRZ, "Monkey Weapon Rotation Z" } }) do
    FeatureMgr.AddFeature(mg[1], mg[2], eFeatureType.SliderFloat, "Rotation of the chimp's weapon (degrees). Applied live.")
end
FeatureMgr.AddFeature(H.mgBone, "Monkey Weapon Bone", eFeatureType.SliderInt, "Which part of the chimp holds its weapon: 1 Auto (right hand), 2 Right hand grip, 3 Right hand, 4 Left hand, 5 Body. Applied live.")
FeatureMgr.AddFeature(H.mgReset, "Reset Monkey Weapon Position", eFeatureType.Button, "Puts the chimp's weapon back in the default hand position.", function()
    for _, hash in ipairs({ H.mgX, H.mgY, H.mgZ, H.mgRX, H.mgRY, H.mgRZ }) do Common.setFloat(hash, 0.0) end
    Common.setInt(H.mgBone, 1)
end)
FeatureMgr.AddFeature(H.friends, "Friends Mode (consenting players)", eFeatureType.Toggle, "Players on your friends list can be grabbed / punched / thrown inside vehicles even with Safe Mode on. Only add friends who agreed. Players on foot are never affected.")
FeatureMgr.AddFeature(H.friendAdd, "Add Player In Crosshair", eFeatureType.Button, "Adds the player you aim at (or the players inside the vehicle you aim at) to the friends list. Only add friends who agreed.", function()
    K.friendAddFromCrosshair()
end)
FeatureMgr.AddFeature(H.friendClear, "Clear Friends List", eFeatureType.Button, "Removes everybody from the friends list.", function()
    K.friendClear()
end)
K.SKILL_HASH = {}
for _, s in ipairs(K.SKILLS) do
    local id = s.id
    K.SKILL_HASH[id] = Utils.Joaat("HulkModeSkill_" .. id)
    FeatureMgr.AddFeature(K.SKILL_HASH[id], "Upgrade " .. s.name, eFeatureType.Button,
        s.per .. " per rank. Costs 1 skill point (1 point per level gained).", function()
            K.upgradeSkill(id)
        end)
end
FeatureMgr.AddFeature(H.skillReset, "Reset Skills", eFeatureType.Button, "Refunds every skill point so you can respec.", function()
    K.resetSkills()
end)
FeatureMgr.AddFeature(H.trajChargeOnly, "Preview Only While Charging", eFeatureType.Toggle, "Show the trajectory only while you hold the throw key.")
FeatureMgr.AddFeature(H.trajGravity, "Preview Gravity", eFeatureType.SliderFloat, "Gravity used by the preview. Raise it if real throws land shorter than the arc, lower it if they land farther.")
FeatureMgr.AddFeature(H.trajLength, "Preview Length (m)", eFeatureType.SliderFloat, "Maximum distance the preview arc is drawn over.")
FeatureMgr.AddFeature(H.keyGrab, "Grab / Throw Key", eFeatureType.SliderInt, "Key used to grab and throw. The key name is shown in the Controls category.")
FeatureMgr.AddFeature(H.keyDrop, "Drop Key", eFeatureType.SliderInt, "Key used to gently put down what you carry.")

-- Slider limits. The VALUES (defaults or the ones saved last time) are applied
-- further down by applySettings(), once the read helpers exist.
Common.configureFloatSlider(H.speed,  20.0, 400.0)
Common.configureFloatSlider(H.radius, 2.0, 30.0)
Common.configureFloatSlider(H.pspeed, 10.0, 300.0)
Common.configureFloatSlider(H.prange, 2.0, 15.0)
Common.configureFloatSlider(H.pdelay, 50.0, 1000.0)
Common.configureFloatSlider(H.rageBonus, 0.0, 200.0)
Common.configureFloatSlider(H.trajGravity, 4.0, 25.0, 0.1, 1.0)
Common.configureFloatSlider(H.trajLength, 50.0, 400.0, 5.0, 25.0)
Common.configureIntSlider(H.keyGrab, 1, #K.KEY_CHOICES)
Common.configureIntSlider(H.keyDrop, 1, #K.KEY_CHOICES)
Common.configureIntSlider(H.punchSound, 1, 3)
Common.configureIntSlider(H.companionType, 1, 9)
Common.configureIntSlider(H.guardWeapon, 1, 5)
Common.configureIntSlider(H.mgBone, 1, #K.PG.GUN_BONES)
Common.configureFloatSlider(H.guardRadius, 8.0, 40.0)
Common.configureFloatSlider(H.petSpeed, 1.0, 3.0, 0.1, 0.5)
for _, hash in ipairs({ H.mgX, H.mgY, H.mgZ }) do Common.configureFloatSlider(hash, -0.6, 0.6, 0.005, 0.05) end
for _, hash in ipairs({ H.mgRX, H.mgRY, H.mgRZ }) do Common.configureFloatSlider(hash, -180.0, 180.0, 1.0, 10.0) end

local function readToggle(hash, default)
    local ok, v = pcall(FeatureMgr.IsFeatureToggled, hash)
    if ok and v ~= nil then return v end
    return default
end

-- allowZero: sliders whose minimum is 0 (a legitimate 0 must not be turned
-- back into the default value).
local function readFloat(hash, default, allowZero)
    local ok, v = pcall(FeatureMgr.GetFeatureFloat, hash)
    if not (ok and type(v) == "number") then
        ok, v = pcall(function() return FeatureMgr.GetFeature(hash):GetFloatValue() end)
    end
    if ok and type(v) == "number" and (v > 0 or (allowZero and v >= 0)) then
        return v
    end
    return default
end

-- Like readFloat, but accepts any value (negative offsets, rotations...).
local function readFloatAny(hash, default)
    local ok, v = pcall(FeatureMgr.GetFeatureFloat, hash)
    if not (ok and type(v) == "number") then
        ok, v = pcall(function() return FeatureMgr.GetFeature(hash):GetFloatValue() end)
    end
    if ok and type(v) == "number" then return v end
    return default
end

local function readInt(hash, default)
    local ok, v = pcall(FeatureMgr.GetFeatureInt, hash)
    if not (ok and type(v) == "number") then
        ok, v = pcall(function() return FeatureMgr.GetFeature(hash):GetIntValue() end)
    end
    if ok and type(v) == "number" then return math.floor(v) end
    return default
end

-- ---------- settings persistence ----------
-- Every setting is saved to a small text file and restored at load, so the
-- script no longer resets your choices each time it starts. If the file API
-- isn't available on this build (VERIFY: FileMgr.*), the defaults are applied
-- at each load, as before.
local saveSettingsIfChanged
do -- nested: persistence
K.SETTINGS = {
    -- { key, hash, kind ("t"oggle / "f"loat / "i"nt), default }
    { "toggle", H.toggle, "t", false },
    { "safe", H.safe, "t", true },           { "charged", H.charged, "t", true },
    { "punch", H.punch, "t", true },         { "shake", H.shake, "t", true },
    { "cross", H.cross, "t", true },         { "impact", H.impact, "t", true },
    { "rage", H.rage, "t", true },           { "grabNpc", H.grabNpc, "t", true },
    { "highlight", H.highlight, "t", true }, { "cleanup", H.cleanup, "t", true },
    { "wideAim", H.wideAim, "t", false },    { "trajectory", H.trajectory, "t", true },
    { "sounds", H.sounds, "t", true },
    { "quests", H.quests, "t", true },
    { "xp", H.xp, "t", true },
    { "debug", H.debug, "t", false },
    { "friends", H.friends, "t", false },
    { "companion", H.companion, "t", false },
    { "companionType", H.companionType, "i", 1 },
    { "petSpeed", H.petSpeed, "f", 3.0 },
    { "petInvincible", H.petInvincible, "t", true },
    { "guard", H.guard, "t", false },
    { "guardWeapon", H.guardWeapon, "i", 2 },
    { "guardRadius", H.guardRadius, "f", 20.0 },
    { "guardHolster", H.guardHolster, "t", true },
    -- v2: offsets are now relative to the hand bone (new key names: the old body-relative values are dropped)
    { "mgHX", H.mgX, "f", 0.0 }, { "mgHY", H.mgY, "f", 0.0 }, { "mgHZ", H.mgZ, "f", 0.0 },
    { "mgHRX", H.mgRX, "f", 0.0 }, { "mgHRY", H.mgRY, "f", 0.0 }, { "mgHRZ", H.mgRZ, "f", 0.0 },
    { "mgBone", H.mgBone, "i", 1 },
    { "speed", H.speed, "f", K.DEFAULTS.throwSpeed },
    { "radius", H.radius, "f", K.DEFAULTS.grabRadius },
    { "pspeed", H.pspeed, "f", K.DEFAULTS.punchSpeed },
    { "prange", H.prange, "f", K.DEFAULTS.punchRange },
    { "pdelay", H.pdelay, "f", K.DEFAULTS.punchDelayMs },
    { "rageBonus", H.rageBonus, "f", K.DEFAULT_RAGE_BONUS_PCT },
    { "trajChargeOnly", H.trajChargeOnly, "t", false },
    { "trajGravity", H.trajGravity, "f", 9.81 },
    { "trajLength", H.trajLength, "f", 200.0 },
    { "softLock", H.softLock, "t", true },
    { "punchSound", H.punchSound, "i", 2 },
    { "keyGrab", H.keyGrab, "i", K.DEFAULT_GRAB_KEY_INDEX },
    { "keyDrop", H.keyDrop, "i", K.DEFAULT_DROP_KEY_INDEX },
}

local settingsPath, persistBroken = nil, false
local lastSavedText, lastSaveCheckMs = nil, 0

local function resolveSettingsPath()
    local ok, root = pcall(function() return FileMgr.GetMenuRootPath() end)
    if ok and type(root) == "string" and root ~= "" then
        return root .. "\\Lua\\HulkMode_settings.cfg"
    end
    return nil
end

local function fileRead(path)
    local okE, exists = pcall(function() return FileMgr.DoesFileExist(path) end)
    if not (okE and exists) then return nil end
    local okR, content = pcall(function() return FileMgr.ReadFileContent(path) end)
    if okR and type(content) == "string" then return content end
    return nil
end

local function fileWrite(path, content)
    if pcall(function() FileMgr.WriteFileContent(path, content, false) end) then return true end
    return (pcall(function() FileMgr.WriteFileContent(path, content) end))
end

local function serializeSettings()
    local lines = {}
    for _, st in ipairs(K.SETTINGS) do
        local key, hash, kind, default = st[1], st[2], st[3], st[4]
        local v
        if kind == "t" then
            v = readToggle(hash, default) and "1" or "0"
        elseif kind == "f" then
            v = string.format("%.4f", readFloatAny(hash, default))
        else
            v = tostring(readInt(hash, default))
        end
        lines[#lines + 1] = key .. "=" .. v
    end
    return table.concat(lines, "\n") .. "\n"
end

local function applySettings()
    settingsPath = resolveSettingsPath()
    local saved = {}
    local content = settingsPath and fileRead(settingsPath) or nil
    if content then
        for line in content:gmatch("[^\r\n]+") do
            local k, v = line:match("^(%w+)=(.+)$")
            if k then saved[k] = v end
        end
        log("settings restored from " .. settingsPath)
    elseif settingsPath == nil then
        persistBroken = true
        K.logWarn("settings persistence unavailable (no FileMgr): defaults are applied at each load")
    end

    for _, st in ipairs(K.SETTINGS) do
        local key, hash, kind, default = st[1], st[2], st[3], st[4]
        local raw = saved[key]
        if kind == "t" then
            local want = default
            if raw ~= nil then want = (raw == "1") end
            Common.setToggle(hash, want)
        elseif kind == "f" then
            local n = tonumber(raw)
            Common.setFloat(hash, n ~= nil and n or default)
        else
            local n = tonumber(raw)
            Common.setInt(hash, n ~= nil and n or default)
        end
    end
    lastSavedText = serializeSettings()
end

function saveSettingsIfChanged(now)
    if persistBroken or settingsPath == nil then return end
    if now - lastSaveCheckMs < 3000 then return end
    lastSaveCheckMs = now
    local text = serializeSettings()
    if text ~= lastSavedText then
        if fileWrite(settingsPath, text) then
            lastSavedText = text
        else
            persistBroken = true
            K.logWarn("could not write the settings file: persistence disabled for this session")
        end
    end
end

applySettings()
end -- nested: persistence

-- All settings are read ONCE per tick into this table; the rest of the
-- script only looks at cfg (much cheaper than querying the menu each time).
local cfg = {
    safe = true, charged = true, punch = true, shake = true, cross = true,
    impact = true, rage = true, grabNpc = true, highlight = true,
    wideAim = false, cleanup = true,
    trajectory = true, sounds = true, quests = true, xp = true, friends = false, debug = false,
    goldTraj = false, chargeMs = K.DEFAULTS.chargeMs, rageGain = 1.0,
    rageDecay = K.RAGE_DECAY_PER_SEC, xpBonus = 1.0,
    trajChargeOnly = false, trajGravity = 9.81, trajLength = 200.0,
    softLock = true, punchSoundStyle = 2,
    grabKey = K.KEY_CHOICES[K.DEFAULT_GRAB_KEY_INDEX][2], grabKeyName = K.KEY_CHOICES[K.DEFAULT_GRAB_KEY_INDEX][1],
    dropKey = K.KEY_CHOICES[K.DEFAULT_DROP_KEY_INDEX][2], dropKeyName = K.KEY_CHOICES[K.DEFAULT_DROP_KEY_INDEX][1],
    throwSpeed = K.DEFAULTS.throwSpeed, grabRadius = K.DEFAULTS.grabRadius,
    punchSpeed = K.DEFAULTS.punchSpeed, punchRange = K.DEFAULTS.punchRange,
    punchDelay = K.DEFAULTS.punchDelayMs, rageBonus = K.DEFAULT_RAGE_BONUS_PCT,
    body = { K.NPC_DEAD_DEFAULT[1], K.NPC_DEAD_DEFAULT[2], K.NPC_DEAD_DEFAULT[3],
             K.NPC_DEAD_DEFAULT[4], K.NPC_DEAD_DEFAULT[5], K.NPC_DEAD_DEFAULT[6] },
}

local function refreshConfig()
    cfg.safe      = readToggle(H.safe, true)
    cfg.charged   = readToggle(H.charged, true)
    cfg.punch     = readToggle(H.punch, true)
    cfg.shake     = readToggle(H.shake, true)
    cfg.cross     = readToggle(H.cross, true)
    cfg.impact    = readToggle(H.impact, true)
    cfg.rage      = readToggle(H.rage, true)
    cfg.grabNpc   = readToggle(H.grabNpc, true)
    cfg.highlight = readToggle(H.highlight, true)
    cfg.wideAim   = readToggle(H.wideAim, false)
    cfg.cleanup   = readToggle(H.cleanup, true)
    cfg.trajectory  = readToggle(H.trajectory, true)
    cfg.sounds      = readToggle(H.sounds, true)
    cfg.quests      = readToggle(H.quests, true)
    cfg.xp          = readToggle(H.xp, true)
    cfg.trajChargeOnly = readToggle(H.trajChargeOnly, false)
    cfg.trajGravity    = readFloat(H.trajGravity, 9.81)
    cfg.trajLength     = readFloat(H.trajLength, 200.0)
    cfg.softLock       = readToggle(H.softLock, true)
    cfg.punchSoundStyle = clamp(readInt(H.punchSound, 2), 1, 3)
    local gi = clamp(readInt(H.keyGrab, K.DEFAULT_GRAB_KEY_INDEX), 1, #K.KEY_CHOICES)
    local di = clamp(readInt(H.keyDrop, K.DEFAULT_DROP_KEY_INDEX), 1, #K.KEY_CHOICES)
    cfg.grabKey, cfg.grabKeyName = K.KEY_CHOICES[gi][2], K.KEY_CHOICES[gi][1]
    cfg.dropKey, cfg.dropKeyName = K.KEY_CHOICES[di][2], K.KEY_CHOICES[di][1]
    cfg.throwSpeed = readFloat(H.speed,  K.DEFAULTS.throwSpeed)
    cfg.grabRadius = readFloat(H.radius, K.DEFAULTS.grabRadius)
    cfg.punchSpeed = readFloat(H.pspeed, K.DEFAULTS.punchSpeed)
    cfg.punchRange = readFloat(H.prange, K.DEFAULTS.punchRange)
    cfg.punchDelay = readFloat(H.pdelay, K.DEFAULTS.punchDelayMs)
    cfg.rageBonus  = readFloat(H.rageBonus, K.DEFAULT_RAGE_BONUS_PCT, true)
    cfg.friends    = readToggle(H.friends, false)
    cfg.debug      = readToggle(H.debug, false)
    K.DEBUG        = cfg.debug   -- verbose console on / off
    cfg.companion     = readToggle(H.companion, false)
    cfg.companionType = clamp(readInt(H.companionType, 1), 1, 9)
    cfg.guard         = readToggle(H.guard, false)
    cfg.guardWeapon   = clamp(readInt(H.guardWeapon, 2), 1, 5)
    cfg.guardRadius   = readFloat(H.guardRadius, 20.0)
    cfg.guardHolster  = readToggle(H.guardHolster, true)
    cfg.petSpeed      = readFloat(H.petSpeed, 3.0)
    cfg.petInvincible = readToggle(H.petInvincible, true)
    cfg.monkeyGun = cfg.monkeyGun or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
    cfg.monkeyBone = clamp(readInt(H.mgBone, 1), 1, #K.PG.GUN_BONES)
    cfg.monkeyGun[1] = readFloatAny(H.mgX, 0.0)
    cfg.monkeyGun[2] = readFloatAny(H.mgY, 0.0)
    cfg.monkeyGun[3] = readFloatAny(H.mgZ, 0.0)
    cfg.monkeyGun[4] = readFloatAny(H.mgRX, 0.0)
    cfg.monkeyGun[5] = readFloatAny(H.mgRY, 0.0)
    cfg.monkeyGun[6] = readFloatAny(H.mgRZ, 0.0)

    -- Skill ranks and level unlocks modify the effective values.
    local lvl, sr = K.playerLevel or 1, K.skillRanks
    cfg.grabRadius = cfg.grabRadius + 1.0 * (sr.grab or 0)
    cfg.throwSpeed = cfg.throwSpeed * (1.0 + 0.04 * (sr.power or 0))
    local chargeMult = 1.0 - 0.08 * (sr.charge or 0)
    if lvl >= 8 then chargeMult = chargeMult * 0.90 end
    if lvl >= 20 then chargeMult = chargeMult * 0.85 end
    cfg.chargeMs   = math.max(300.0, K.DEFAULTS.chargeMs * chargeMult)
    cfg.rageGain   = 1.0 + 0.10 * (sr.rage or 0)
    cfg.rageDecay  = K.RAGE_DECAY_PER_SEC * ((lvl >= 12) and 0.75 or 1.0)
    cfg.xpBonus    = (1.0 + 0.05 * (sr.xp or 0)) * ((lvl >= 16) and 1.10 or 1.0)
    cfg.goldTraj   = lvl >= 20
end


-- ============================================================
--  5) LOGIC
-- ============================================================

-- ---------- sounds ----------
K.SND = {
    grab      = { "PICK_UP",            "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    charge    = { "NAV_UP_DOWN",        "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    chargeMax = { "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET" },
    throw     = { "SELECT",             "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    drop      = { "BACK",               "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    punch     = { "TIMER_STOP",         "HUD_MINI_GAME_SOUNDSET" },
    rageMax   = { "MEDAL_UP",           "HUD_MINI_GAME_SOUNDSET" },
    jump      = { "NAV_UP_DOWN",        "HUD_FRONTEND_DEFAULT_SOUNDSET" },
}
local soundBroken = false
local lastChargeStage = 0
local rageMaxed = false

local function playSound(snd)
    if not cfg.sounds or soundBroken then return end
    local ok, err = pcall(Natives.InvokeVoid, K.NATIVE.PLAY_SOUND_FRONTEND, -1, snd[1], snd[2], true)
    if not ok then
        soundBroken = true
        K.logWarn("sound native failed, sounds disabled: " .. tostring(err))
    end
end

-- Sounds that must start a few milliseconds later (to layer them).
local queueSound, processSounds
do -- nested: sound queue
local soundQueue = {}

function queueSound(snd, delayMs)
    if not cfg.sounds or soundBroken then return end
    if not delayMs or delayMs <= 0 then
        playSound(snd)
        return
    end
    soundQueue[#soundQueue + 1] = { snd = snd, atMs = Time.GetEpocheMs() + delayMs }
end

function processSounds(now)
    for i = #soundQueue, 1, -1 do
        local q = soundQueue[i]
        if now >= q.atMs then
            table.remove(soundQueue, i)
            playSound(q.snd)
        end
    end
end
end -- nested: sound queue

-- ---------- input guard ----------
-- Our hotkeys must not fire while the pause menu is open or while typing in
-- the chat. (Alt-tabbing out of the game can't be detected from here.)
-- The chat-typing native (unverified hash) was removed: a wrong hash could
-- report "typing" forever and silently swallow every key press.
local function inputBlocked()
    return Natives.InvokeBool(K.NATIVE.IS_PAUSE_MENU_ACTIVE) and true or false
end

local carrying, carriedEntity, animPlaying = false, nil, false
local activeCarryAnimDict, activeCarryAnimClip = nil, nil
local pendingEntity, pendingPed, pendingSince = nil, nil, 0
local carriedKind, pendingKind = K.KIND_VEHICLE, K.KIND_VEHICLE
local carriedNpcDead = false   -- was the carried NPC dead when grabbed?
local appliedBodyKey = nil     -- offsets last applied to a carried dead body
local pendingAttach = nil   -- object currently being unhooked: { entity, ped, kind, t0 }
K.UNHOOK_DELAY_MS = 250
local lastPunchMs = 0
local chargeStart = nil    -- timestamp when E was pressed while carrying
local chargeFrac  = 0.0    -- 0..1, read by the crosshair to draw the charge bar

-- Rage Mode state: 0..100, builds on each landed hit, decays when idle.
local rageLevel      = 0.0
local lastRageHitMs  = 0
local lastRageTickMs = 0

-- Forward declaration: throwCarriedEntity (below) reuses the super punch's
-- impulse queue to launch a grabbed NPC, but that queue is only defined
-- further down the file alongside the rest of the punch system.
local startPunchPush

-- Session stats, shown in the menu (reset only by reloading the script).
local stats = {
    vehiclesThrown = 0, objectsThrown = 0, npcsThrown = 0, punchesLanded = 0,
    grabs = 0, fullCharges = 0, sceneryHits = 0, rageMaxes = 0,
    xpEarned = 0, bestRampage = 0, bestCombo = 0,
}

local function addRage(amount)
    if not cfg.rage then return end
    rageLevel = clamp(rageLevel + amount * cfg.rageGain, 0.0, 100.0)
    lastRageHitMs = Time.GetEpocheMs()
    if rageLevel >= 100.0 and not rageMaxed then
        rageMaxed = true
        stats.rageMaxes = stats.rageMaxes + 1
        playSound(K.SND.rageMax)
    end
end

-- Called every tick with the current time; decay is scaled by the real
-- elapsed time so the feel doesn't depend on the frame rate.
local function updateRage(now)
    local dt = 0.0
    if lastRageTickMs > 0 then
        dt = clamp((now - lastRageTickMs) / 1000.0, 0.0, 0.25)
    end
    lastRageTickMs = now
    if rageLevel < 80.0 then rageMaxed = false end

    if rageLevel <= 0.0 then return end
    if now - lastRageHitMs < K.RAGE_IDLE_DELAY_MS then return end
    rageLevel = clamp(rageLevel - cfg.rageDecay * dt, 0.0, 100.0)
end

-- Multiplier applied to punch/throw power: 1.0 with no rage, up to
-- 1 + (bonus% / 100) at full rage.
local function rageMultiplier()
    if not cfg.rage then return 1.0 end
    return 1.0 + (rageLevel / 100.0) * (cfg.rageBonus / 100.0)
end

local function getPed()
    return Natives.InvokeInt(K.NATIVE.PLAYER_PED_ID)
end

local function entityOk(e)
    return e ~= nil and e ~= 0 and Natives.InvokeBool(K.NATIVE.DOES_ENTITY_EXIST, e)
end

local function getCameraDirection()
    local rx, _, rz = Natives.InvokeV3(K.NATIVE.GET_GAMEPLAY_CAM_ROT, 2)
    local radX, radZ = math.rad(rx), math.rad(rz)
    local flat = math.abs(math.cos(radX))
    return { x = -math.sin(radZ) * flat, y = math.cos(radZ) * flat, z = math.sin(radX) }
end

-- ---------- Friends Mode: consenting players ----------
-- Players on this list agreed to be affected. It only unlocks VEHICLES that
-- contain them (when Safe Mode would otherwise block those): a player on foot
-- is never grabbed, punched or targeted. The list is saved to a file.
K.friends, K.friendNames = {}, {}

function K.pedPlayerName(ped)
    local ok, idx = pcall(Natives.InvokeInt, K.NATIVE.NETWORK_GET_PLAYER_INDEX_FROM_PED, ped)
    if not ok or type(idx) ~= "number" or idx < 0 then return nil end
    local ok2, name = pcall(Natives.InvokeString, K.NATIVE.GET_PLAYER_NAME, idx)
    if ok2 and type(name) == "string" and name ~= "" then return name end
    return nil
end

function K.isConsentingPed(ped)
    if not cfg.friends then return false end
    local name = K.pedPlayerName(ped)
    return name ~= nil and K.friends[name:lower()] == true
end

function K.friendsPath()
    local ok, root = pcall(function() return FileMgr.GetMenuRootPath() end)
    if ok and type(root) == "string" and root ~= "" then
        return root .. "\\Lua\\HulkMode_friends.cfg"
    end
    return nil
end

function K.saveFriends()
    local path = K.friendsPath()
    if not path then return end
    local text = table.concat(K.friendNames, "\n") .. "\n"
    if not pcall(function() FileMgr.WriteFileContent(path, text, false) end) then
        pcall(function() FileMgr.WriteFileContent(path, text) end)
    end
end

function K.loadFriends()
    local path = K.friendsPath()
    if not path then return end
    local okE, exists = pcall(function() return FileMgr.DoesFileExist(path) end)
    if not (okE and exists) then return end
    local okR, content = pcall(function() return FileMgr.ReadFileContent(path) end)
    if not (okR and type(content) == "string") then return end
    for line in content:gmatch("[^\r\n]+") do
        local key = line:lower()
        if not K.friends[key] then
            K.friends[key] = true
            K.friendNames[#K.friendNames + 1] = line
        end
    end
end

function K.addFriendName(name)
    local key = name:lower()
    if K.friends[key] then return false end
    K.friends[key] = true
    K.friendNames[#K.friendNames + 1] = name
    K.saveFriends()
    return true
end

function K.friendClear()
    K.friends, K.friendNames = {}, {}
    K.saveFriends()
    Common.toast("Hulk Mode", "Friends list cleared.", 2500)
end

function K.friendsText()
    if #K.friendNames == 0 then return "Friends list: empty" end
    return "Friends list: " .. table.concat(K.friendNames, ", ")
end

K.loadFriends()

-- Returns (hasAnyOccupant, hasPlayer, everyPlayerConsents) for a vehicle.
local function vehicleOccupants(vehicle)
    local any, player, consent = false, false, true
    for seat = -1, K.MAX_SEATS_TO_CHECK - 2 do
        local occupant = Natives.InvokeInt(K.NATIVE.GET_PED_IN_VEHICLE_SEAT, vehicle, seat, false)
        if occupant ~= nil and occupant ~= 0 then
            any = true
            if Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, occupant) then
                player = true
                if not K.isConsentingPed(occupant) then consent = false end
            end
        end
    end
    return any, player, consent
end

local function vehicleAllowed(v, opts)
    local _, hasPlayer, consent = vehicleOccupants(v)
    if not (opts.safe and hasPlayer) then return true end
    return consent == true   -- Friends Mode: every player inside agreed
end

-- If the ped is sitting in a vehicle, returns that vehicle (else nil).
local function vehicleOfPed(npc)
    if Natives.InvokeBool(K.NATIVE.IS_PED_IN_ANY_VEHICLE, npc, false) then
        local v = Natives.InvokeInt(K.NATIVE.GET_VEHICLE_PED_IS_IN, npc, false)
        if v ~= nil and v ~= 0 and entityOk(v) then
            return v
        end
    end
    return nil
end

-- Closest vehicle to the player (any type, occupied or not).
-- opts.safe: ignore vehicles that contain a player.
local function findNearestVehicle(ped, radius, opts)
    opts = opts or {}
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local best, bestD

    for _, flags in ipairs(K.VEHICLE_SEARCH_FLAGS) do
        local v = Natives.InvokeInt(K.NATIVE.GET_CLOSEST_VEHICLE, px, py, pz, radius, 0, flags)
        if entityOk(v) then
            local any, player, consent = vehicleOccupants(v)
            local excluded = (opts.emptyOnly and any) or (opts.safe and player and not consent)
            if not excluded then
                local vx, vy, vz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, v, true)
                local d = distSq(vx, vy, vz, px, py, pz)
                if bestD == nil or d < bestD then
                    best, bestD = v, d
                end
            end
        end
    end
    return best, bestD
end

-- NPCs near the player. GET_RANDOM_PED_AT_COORD returns an arbitrary ped of the
-- area (not necessarily the closest), so it is sampled several times and the
-- closest one is kept (inside the aim cone when `dir` is given).
local function findNpcInRange(ped, radius, dir)
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local best, bestD
    local seen = {}
    for _ = 1, 8 do
        local npc = Natives.InvokeInt(K.NATIVE.GET_RANDOM_PED_AT_COORD, px, py, pz, radius, radius, radius, -1)
        if npc ~= nil and npc ~= 0 and npc ~= ped and npc ~= K.PG.pet and not seen[npc] and entityOk(npc) then
            seen[npc] = true
            if not Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, npc) then
                local nx, ny, nz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, npc, true)
                local d = distSq(nx, ny, nz, px, py, pz)
                if d <= radius * radius then
                    local inFront = true
                    if dir and d > 0.25 then
                        local len = math.sqrt(d)
                        inFront = ((nx - px) * dir.x + (ny - py) * dir.y + (nz - pz) * dir.z) / len > 0.5
                    end
                    if inFront and (bestD == nil or d < bestD) then
                        best, bestD = npc, d
                    end
                end
            end
        end
    end
    return best, bestD
end

-- ---------- aiming (crosshair) ----------

local rayUnsupported = false
local rayFailures = 0
local rayBufs = nil

local function getRayBufs()
    if rayBufs == nil then
        rayBufs = {
            hit = Memory.Alloc(8),
            pos = Memory.Alloc(32),
            nrm = Memory.Alloc(32),
            ent = Memory.Alloc(8),
        }
        local names = {}
        for k, v in pairs(Memory) do
            if type(v) == "function" then names[#names + 1] = tostring(k) end
        end
        table.sort(names)
        log("available Memory functions: " .. table.concat(names, ", "))
    end
    return rayBufs
end

local function getCameraPos()
    return Natives.InvokeV3(K.NATIVE.GET_GAMEPLAY_CAM_COORD)
end

-- Squared distance of a point to the ray's axis, and its position along it.
local function pointToAxis(x, y, z, cx, cy, cz, dir)
    local wx, wy, wz = x - cx, y - cy, z - cz
    local along = wx * dir.x + wy * dir.y + wz * dir.z
    return (wx * wx + wy * wy + wz * wz) - along * along, along
end

-- Ray cast from the camera along the crosshair's exact axis, starting at the
-- player's plane (so it doesn't hit what's behind them), for `length` meters.
-- Returns (result, supported). result = { entity, etype, x, y, z } or nil.
-- GET_SHAPE_TEST_RESULT writes its results into memory regions (Memory.Alloc)
-- that we read back afterwards. If reading is impossible, or fails several
-- times in a row, the script falls back to the non-raycast method.
local function castRay(ped, length, offR, offU)
    if rayUnsupported then
        return nil, false
    end

    local ok, res = pcall(function()
        local cx, cy, cz = getCameraPos()
        local dir = getCameraDirection()
        local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
        local camToPed = math.sqrt(distSq(cx, cy, cz, px, py, pz))
        local t0 = math.max(camToPed - 0.5, 0.0)
        local t1 = camToPed + length

        -- End point: at the end of the crosshair's axis, optionally offset
        -- (offR = to the right, offU = upward, in meters) to widen the
        -- super punch's hit area.
        local ex, ey, ez = cx + dir.x * t1, cy + dir.y * t1, cz + dir.z * t1
        if offR or offU then
            local rx, ry = dir.y, -dir.x
            local rl = math.sqrt(rx * rx + ry * ry)
            if rl > 0.001 then rx, ry = rx / rl, ry / rl end
            local ux, uy, uz = ry * dir.z, -rx * dir.z, rx * dir.y - ry * dir.x
            ex = ex + rx * (offR or 0.0) + ux * (offU or 0.0)
            ey = ey + ry * (offR or 0.0) + uy * (offU or 0.0)
            ez = ez + uz * (offU or 0.0)
        end

        local handle = Natives.InvokeInt(K.NATIVE.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE,
            cx + dir.x * t0, cy + dir.y * t0, cz + dir.z * t0,
            ex, ey, ez,
            K.RAY_FLAGS, ped, 7)

        local b = getRayBufs()
        memWriteInt(b.hit, 0)
        memWriteInt(b.ent, 0)

        Natives.InvokeInt(K.NATIVE.GET_SHAPE_TEST_RESULT, handle, b.hit, b.pos, b.nrm, b.ent)

        local hitVal = memReadInt(b.hit)
        if hitVal == nil then
            return "unsupported"
        end
        if hitVal == 0 then
            return false
        end

        local out = {}
        local ent = memReadInt(b.ent)
        if ent ~= nil and ent ~= 0 and entityOk(ent) then
            out.entity = ent
            out.etype  = Natives.InvokeInt(K.NATIVE.GET_ENTITY_TYPE, ent)
        end

        -- Hit point: a Vector3 can be stored with either 4- or 8-byte gaps
        -- between its floats. The hit point must lie on the ray itself
        -- (within ~2 m of its axis, in front of the camera), so we keep the
        -- layout that satisfies this best instead of trusting the first
        -- "plausible" one.
        local bestPerp
        for _, step in ipairs({ 8, 4 }) do
            local x = memReadFloat(b.pos, 0)
            local y = memReadFloat(b.pos, step)
            local z = memReadFloat(b.pos, step * 2)
            if x and y and z then
                local perpSq, along = pointToAxis(x, y, z, cx, cy, cz, dir)
                if along > 0.0 and perpSq <= 4.0 and (bestPerp == nil or perpSq < bestPerp) then
                    bestPerp = perpSq
                    out.x, out.y, out.z = x, y, z
                end
            end
        end
        return out
    end)

    if ok and res == "unsupported" then
        rayUnsupported = true
        K.rayToast()
        K.logWarn("raycast unavailable (memory read unavailable): falling back to the non-raycast search")
        return nil, false
    end
    if not ok then
        rayFailures = rayFailures + 1
        if rayFailures >= K.RAY_MAX_FAILURES then
            rayUnsupported = true
            K.rayToast()
            K.logWarn("raycast disabled after repeated errors (" .. tostring(res) ..
                "): falling back to the non-raycast search")
        end
        return nil, false
    end

    rayFailures = 0
    if res == false then
        return nil, true
    end
    return res, true
end

-- Closest vehicle to the crosshair, within a `radius` around the player.
-- Occupied vehicles (NPCs included) are accepted; in safe mode, ones with a
-- player inside are ignored.
local function findVehicleNearReticle(ped, radius, opts)
    opts = opts or {}
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)

    -- 1) Exact raycast: if the crosshair points straight at a vehicle, it's
    -- our target.
    local ray = castRay(ped, radius)
    if ray and ray.entity and ray.etype == 2 and vehicleAllowed(ray.entity, opts) then
        local vx, vy, vz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ray.entity, true)
        if distSq(vx, vy, vz, px, py, pz) <= (radius + 3.0) ^ 2 then
            return ray.entity
        end
    end

    -- 2) Sampling along the crosshair: look for vehicles around points
    -- spaced along the camera's axis, and keep whichever one's center is
    -- closest to that axis (= closest to the crosshair).
    local cx, cy, cz = getCameraPos()
    local dir = getCameraDirection()
    local camToPed = math.sqrt(distSq(cx, cy, cz, px, py, pz))

    local best, bestPerp
    local seen = {}
    local t, tMax = math.max(camToPed - 0.5, 0.0), camToPed + radius + 2.0

    while t <= tMax do
        local sx, sy, sz = cx + dir.x * t, cy + dir.y * t, cz + dir.z * t
        for _, flags in ipairs(K.VEHICLE_SEARCH_FLAGS) do
            local v = Natives.InvokeInt(K.NATIVE.GET_CLOSEST_VEHICLE, sx, sy, sz, K.SAMPLE_RADIUS, 0, flags)
            if entityOk(v) and not seen[v] then
                seen[v] = true
                if vehicleAllowed(v, opts) then
                    local vx, vy, vz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, v, true)
                    if distSq(vx, vy, vz, px, py, pz) <= radius * radius then
                        local perpSq, along = pointToAxis(vx, vy, vz, cx, cy, cz, dir)
                        if along > 0.0 and (bestPerp == nil or perpSq < bestPerp) then
                            best, bestPerp = v, perpSq
                        end
                    end
                end
            end
        end
        t = t + K.SAMPLE_STEP
    end
    return best
end

-- Friends list helper: adds the player aimed at (or the players sitting in
-- the aimed vehicle). Only players, never NPCs.
function K.friendAddFromCrosshair()
    local ok, err = pcall(function()
        local ped = getPed()
        local ray = castRay(ped, 60.0)
        local added = {}
        local function consider(p)
            if p ~= nil and p ~= 0 and p ~= ped and Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, p) then
                local name = K.pedPlayerName(p)
                if name and K.addFriendName(name) then added[#added + 1] = name end
            end
        end
        if ray and ray.entity then
            if ray.etype == 1 then
                consider(ray.entity)
            elseif ray.etype == 2 then
                for seat = -1, K.MAX_SEATS_TO_CHECK - 2 do
                    consider(Natives.InvokeInt(K.NATIVE.GET_PED_IN_VEHICLE_SEAT, ray.entity, seat, false))
                end
            end
        end
        if #added > 0 then
            toast("Friend added: " .. table.concat(added, ", "), 3000)
        else
            toast("No new player in the crosshair.", 2500)
        end
    end)
    if not ok then K.logError("friend add failed: " .. tostring(err)) end
end

local highlightedEntity = nil

-- Target of the E key: whatever the crosshair points straight at (a vehicle,
-- an NPC when "Grab NPCs" is on, or a scenery object: trash can, sign,
-- pole...), otherwise the closest vehicle to the crosshair. Aiming at an NPC
-- who is sitting in a vehicle targets the vehicle. Walls and buildings (no
-- entity) can't be grabbed. Real players are never a valid target here,
-- regardless of the "Grab NPCs" setting.
local function findGrabTarget(ped, radius, opts)
    opts = opts or {}
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)

    local ray = castRay(ped, radius)
    if ray and ray.entity then
        local e = ray.entity
        local ex, ey, ez = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, e, true)
        if distSq(ex, ey, ez, px, py, pz) <= (radius + 3.0) ^ 2 then
            if ray.etype == 2 then
                if vehicleAllowed(e, opts) then
                    return e, K.KIND_VEHICLE
                end
            elseif ray.etype == 1 then
                local veh = vehicleOfPed(e)
                if veh ~= nil then
                    if vehicleAllowed(veh, opts) then
                        return veh, K.KIND_VEHICLE
                    end
                elseif opts.grabNpc and e ~= ped and e ~= K.PG.pet
                    and not Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, e)
                    and not Natives.InvokeBool(K.NATIVE.IS_ENTITY_ATTACHED, e) then
                    return e, K.KIND_NPC
                end
            elseif ray.etype == 3 then
                if not Natives.InvokeBool(K.NATIVE.IS_ENTITY_ATTACHED, e) then
                    return e, K.KIND_OBJECT
                end
            end
        end
    end

    local v = findVehicleNearReticle(ped, radius, opts)
    if v ~= nil then
        return v, K.KIND_VEHICLE
    end
    return nil
end

-- ---------- crosshair target glow ----------
-- Reuse findGrabTarget(), the exact selector used by E, so the glow always
-- matches the entity Hulk Mode would actually grab. The targeting is
-- throttled: it is fairly expensive (raycast + vehicle sampling).
local outlineBroken = false

local function setTargetOutline(entity, enabled)
    if not K.USE_NATIVE_OUTLINE or entity == nil or entity == 0 or outlineBroken then return end
    local ok, err = pcall(function()
        -- Configure the game's outline renderer before toggling the entity.
        -- Shader 1 is the standard visible outline shader in GTA V.
        if enabled then
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DRAW_OUTLINE_SHADER, 1)
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DRAW_OUTLINE_COLOR, 45, 235, 255, 255)
        end
        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DRAW_OUTLINE, entity, enabled)
    end)
    if not ok then
        -- Give up on the native outline (logged once); the green reticle
        -- brackets drawn by drawCrosshair() remain as the visual cue.
        outlineBroken = true
        K.logWarn("target outline native failed, using reticle brackets only: " .. tostring(err))
    end
end

local function clearTargetHighlight()
    if highlightedEntity ~= nil then
        setTargetOutline(highlightedEntity, false)
        highlightedEntity = nil
    end
end

local lastHighlightMs = 0

local function updateTargetHighlight(ped, now)
    if not cfg.highlight or carrying then
        clearTargetHighlight()
        return
    end

    if now - lastHighlightMs < K.HIGHLIGHT_INTERVAL_MS then
        if highlightedEntity ~= nil and not entityOk(highlightedEntity) then
            clearTargetHighlight()
        end
        return
    end
    lastHighlightMs = now

    local target = findGrabTarget(ped, cfg.grabRadius, {
        safe = cfg.safe,
        grabNpc = cfg.grabNpc,
    })

    if target ~= highlightedEntity then
        clearTargetHighlight()
        if target ~= nil and entityOk(target) then
            highlightedEntity = target
            setTargetOutline(highlightedEntity, true)
        end
    elseif highlightedEntity ~= nil and not entityOk(highlightedEntity) then
        clearTargetHighlight()
    end
end

-- ---------- animation ----------

local function getCarryAnim()
    if carriedKind == K.KIND_NPC then
        return K.NPC_CARRY_ANIM_DICT, K.NPC_CARRY_ANIM_CLIP
    end
    return K.CARRY_ANIM_DICT, K.CARRY_ANIM_CLIP
end

local function requestCarryAnimDict()
    local dict = getCarryAnim()
    Natives.InvokeVoid(K.NATIVE.REQUEST_ANIM_DICT, dict)
end

local function updateCarryAnim(ped)
    local dict, clip = getCarryAnim()
    if animPlaying and activeCarryAnimDict == dict and activeCarryAnimClip == clip then return end
    if animPlaying and activeCarryAnimDict and activeCarryAnimClip then
        Natives.InvokeVoid(K.NATIVE.STOP_ANIM_TASK, ped, activeCarryAnimDict, activeCarryAnimClip, 2.0)
        animPlaying = false
    end
    -- Request until loaded; Cherax ticks continuously while Hulk Mode is active.
    Natives.InvokeVoid(K.NATIVE.REQUEST_ANIM_DICT, dict)
    if Natives.InvokeBool(K.NATIVE.HAS_ANIM_DICT_LOADED, dict) then
        Natives.InvokeVoid(K.NATIVE.TASK_PLAY_ANIM, ped, dict, clip,
            8.0, 8.0, -1, 49, 1.0, false, false, false)
        activeCarryAnimDict, activeCarryAnimClip = dict, clip
        animPlaying = true
    end
end

local function stopCarryAnim(ped)
    if animPlaying and activeCarryAnimDict and activeCarryAnimClip then
        Natives.InvokeVoid(K.NATIVE.STOP_ANIM_TASK, ped, activeCarryAnimDict, activeCarryAnimClip, 4.0)
    end
    animPlaying = false
    activeCarryAnimDict, activeCarryAnimClip = nil, nil
end

-- ---------- entity cleanup ----------
-- Grabbed entities are flagged as mission entities so the game doesn't
-- despawn them mid-carry. If we are the ones who set that flag (it wasn't
-- set already), we hand them back to the game a few seconds after use so
-- they don't pile up in the world forever.

local ownedEntities = {}   -- [entity] = true: flagged as mission entity by us
local releaseQueue  = {}   -- { entity, atMs }
local releaseBuf    = nil

local function scheduleRelease(entity)
    if not cfg.cleanup or not ownedEntities[entity] then return end
    for _, r in ipairs(releaseQueue) do
        if r.entity == entity then
            r.atMs = Time.GetEpocheMs() + K.RELEASE_DELAY_MS
            return
        end
    end
    releaseQueue[#releaseQueue + 1] = { entity = entity, atMs = Time.GetEpocheMs() + K.RELEASE_DELAY_MS }
end

local function processReleases(now)
    for i = #releaseQueue, 1, -1 do
        local r = releaseQueue[i]
        if not entityOk(r.entity) then
            ownedEntities[r.entity] = nil
            table.remove(releaseQueue, i)
        elseif now >= r.atMs then
            table.remove(releaseQueue, i)
            -- Still being carried (re-grabbed): keep ownership, it will be
            -- rescheduled on the next throw/drop.
            if r.entity ~= carriedEntity and ownedEntities[r.entity] then
                ownedEntities[r.entity] = nil
                releaseBuf = releaseBuf or Memory.Alloc(8)
                if memWriteInt(releaseBuf, r.entity) then
                    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_AS_NO_LONGER_NEEDED, releaseBuf)
                end
            end
        end
    end
end

-- ---------- grabbing ----------

-- Frees an object fixed to the ground (pole, sign, lamppost...): request
-- control of it first (we can't reliably change its physics state without
-- it -- the previous version skipped this and relied on the request already
-- made for the grab itself, which can have lapsed by the time this runs),
-- then unfreeze it, make it dynamic and give it a firm shove, the same way a
-- vehicle crashing into it would knock it loose.
local function unhookObject(e)
    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, e)
    Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, e, false)
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DYNAMIC, e, true)
    Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, e)
    local x, y, z = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, e, true)
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COORDS_NO_OFFSET, e, x, y, z + 0.35, false, false, false)
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_VELOCITY, e, 0.0, 0.0, 2.2)
end

-- Reinforces the unhook every tick while we wait to attach it (see
-- pendingAttach below): a single shove at grab time isn't always enough for
-- a heavier/stubborn prop to actually start simulating physics, so this
-- keeps insisting -- unfreeze, dynamic, physics, network control -- right up
-- until the attach happens.
local function reinforceUnhook(e)
    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, e)
    Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, e, false)
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DYNAMIC, e, true)
    Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, e)
end

-- ---------- physics wake-up (fixes the "object frozen mid-air" bug) ----------
-- A carried object has its collision and physics switched off. After
-- DETACH_ENTITY, physics only resumes the following frame: a velocity set
-- immediately is lost, and the object is left hanging with no gravity. So we
-- re-enable physics (collision, unfreeze, dynamic mode) and re-apply the
-- velocity for a few dozen milliseconds, after which gravity takes over.
-- Ground-fixed scenery objects (lampposts, signs, poles...) are much more
-- stubborn about actually starting to simulate physics than vehicles or
-- small loose props once detached -- they're given a longer, more insistent
-- settle window (see the throw/drop code below).
K.SETTLE_PUSH_MS_OBJECT = 1500
K.SETTLE_WAKE_MS_OBJECT = 1200

local unsettle, settle, processSettling
do -- nested: settle
K.SETTLE_START_MS = 60     -- delay before the first re-activation
K.SETTLE_PUSH_MS  = 320    -- duration the velocity is re-applied for (throw / punch)
K.SETTLE_WAKE_MS  = 400    -- duration of the wake-up-only phase (simple drop)
local settling = {}            -- { entity, vx, vy, vz, startMs, untilMs, nextMs }

function unsettle(entity)
    for i = #settling, 1, -1 do
        if settling[i].entity == entity then
            table.remove(settling, i)
        end
    end
end

-- vx/vy/vz = nil: wake-up only (drop); otherwise the velocity is re-applied.
-- durationMs: optional override (used for ground-fixed objects, which take
-- much more insistence to actually start simulating physics than vehicles
-- or small loose props do).
function settle(entity, vx, vy, vz, durationMs)
    unsettle(entity)
    local now = Time.GetEpocheMs()
    local duration = durationMs or ((vx ~= nil) and K.SETTLE_PUSH_MS or K.SETTLE_WAKE_MS)
    settling[#settling + 1] = {
        entity = entity, vx = vx, vy = vy, vz = vz,
        startMs = now + K.SETTLE_START_MS,
        untilMs = now + K.SETTLE_START_MS + duration,
        nextMs = 0,
    }
end

function processSettling()
    if #settling == 0 then return end
    local now = Time.GetEpocheMs()
    for i = #settling, 1, -1 do
        local s = settling[i]
        if not entityOk(s.entity) or now > s.untilMs then
            table.remove(settling, i)
        elseif now >= s.startMs and now >= s.nextMs then
            s.nextMs = now + 40
            Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, s.entity)
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, s.entity, true, true)
            Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, s.entity, false)
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DYNAMIC, s.entity, true)
            Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, s.entity)
            if s.vx ~= nil then
                Natives.InvokeVoid(K.NATIVE.SET_ENTITY_VELOCITY, s.entity, s.vx, s.vy, s.vz)
            end
        end
    end
end
end -- nested: settle

-- Dead NPC: ragdoll attached to the player's root; the offsets are fixed
-- (K.NPC_DEAD_DEFAULT).
local function attachDeadBody(entity, ped)
    local o = cfg.body
    Natives.InvokeVoid(K.NATIVE.ATTACH_ENTITY_TO_ENTITY,
        entity, ped, 0,
        o[1], o[2], o[3],
        o[4], o[5], o[6],
        false, false, false, false, 2, true)
    appliedBodyKey = table.concat(o, ",")
end

local function attachGrabbed(entity, ped, kind)
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, entity, false, false)

    if kind == K.KIND_NPC then
        local dead = Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, entity, false)
        carriedNpcDead = dead
        appliedBodyKey = nil
        if dead then
            attachDeadBody(entity, ped)
        else
            -- Living NPC: no ragdoll (it ignores the attachment and the NPC
            -- ends up invisible/inside the player). Freeze its AI, forbid
            -- ragdoll, attach it to the player's root and make it play the
            -- carry pose. Everything is restored on throw/drop.
            Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS_IMMEDIATELY, entity)
            Natives.InvokeVoid(K.NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, entity, true)
            Natives.InvokeVoid(K.NATIVE.SET_PED_CAN_RAGDOLL, entity, false)
            local o = K.NPC_ALIVE_OFFSET
            Natives.InvokeVoid(K.NATIVE.ATTACH_ENTITY_TO_ENTITY,
                entity, ped, 0,
                o[1], o[2], o[3],
                o[4], o[5], o[6],
                false, false, false, false, 2, false)
            Natives.InvokeVoid(K.NATIVE.TASK_PLAY_ANIM, entity,
                K.NPC_BODY_ANIM_DICT, K.NPC_BODY_ANIM_CLIP,
                8.0, -8.0, 100000, 33, 0.0, false, false, false)
        end
    else
        local offZ = K.CARRY_OFFSET_Z
        if kind == K.KIND_OBJECT then offZ = 1.6 end
        Natives.InvokeVoid(K.NATIVE.ATTACH_ENTITY_TO_ENTITY,
            entity, ped, -1,
            K.CARRY_OFFSET_X, K.CARRY_OFFSET_Y, offZ,
            0.0, 0.0, 0.0,
            false, false, false, false, 2, true)
    end

    carrying, carriedEntity, carriedKind = true, entity, kind
    stats.grabs = stats.grabs + 1
    chargeStart, chargeFrac = nil, 0.0
    requestCarryAnimDict()

    if cfg.shake then
        Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "HAND_SHAKE", 0.4)
    end
    local label = "Vehicle picked up"
    if kind == K.KIND_OBJECT then label = "Object picked up" end
    if kind == K.KIND_NPC then label = carriedNpcDead and "Body carried" or "NPC carried" end
    playSound(K.SND.grab)
    toast(label .. "! Press " .. cfg.grabKeyName .. " to throw, " .. cfg.dropKeyName .. " to drop.", 3000)
    log(kind .. " " .. tostring(entity) .. " grabbed" .. ((kind == K.KIND_NPC and carriedNpcDead) and " (dead)" or ""))
end

local function finalizeGrab(entity, ped, kind)
    kind = kind or K.KIND_VEHICLE

    if kind == K.KIND_VEHICLE then
        -- Re-check: a player may have gotten in while we were waiting.
        if not vehicleAllowed(entity, { safe = cfg.safe }) then
            toast("A player is inside this vehicle, cancelled.")
            return
        end
    end

    if kind == K.KIND_NPC and Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, entity) then
        -- Extra safety net: never grab a real player, even if the situation
        -- changed between the click and getting network control.
        toast("Cancelled: that's a player.")
        return
    end

    -- Stop the game from despawning it while we're carrying it. If it was
    -- already a mission entity (e.g. the player's own vehicle), leave that
    -- untouched and never release it afterwards.
    if not Natives.InvokeBool(K.NATIVE.IS_ENTITY_A_MISSION_ENTITY, entity) then
        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_AS_MISSION_ENTITY, entity, true, true)
        ownedEntities[entity] = true
    end

    if kind == K.KIND_OBJECT then
        -- First unhook it from the ground, then attach it after a short delay.
        unsettle(entity)
        unhookObject(entity)
        pendingAttach = { entity = entity, ped = ped, kind = kind, t0 = Time.GetEpocheMs() }
        log("object " .. tostring(entity) .. " unhooked from the ground, attaching in " .. K.UNHOOK_DELAY_MS .. " ms")
        return
    end

    if kind == K.KIND_NPC then
        -- Load the NPC's carry animation first (updatePendingAttach attaches).
        Natives.InvokeVoid(K.NATIVE.REQUEST_ANIM_DICT, K.NPC_BODY_ANIM_DICT)
        pendingAttach = { entity = entity, ped = ped, kind = kind, t0 = Time.GetEpocheMs() }
        return
    end

    attachGrabbed(entity, ped, kind)
end

-- Keeps a carried NPC in place: collision off (some peds restore it), and
-- for a dead body, the fixed offsets are applied.
local function updateCarriedNpc()
    if not (carrying and carriedKind == K.KIND_NPC and entityOk(carriedEntity)) then return end
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, carriedEntity, false, false)

    -- The NPC died while we were carrying it: drop the living-NPC state (pose,
    -- blocked AI, no ragdoll) and carry it as a dead body from now on.
    if not carriedNpcDead and Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, carriedEntity, false) then
        carriedNpcDead = true
        appliedBodyKey = nil
        Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS_IMMEDIATELY, carriedEntity)
        Natives.InvokeVoid(K.NATIVE.SET_PED_CAN_RAGDOLL, carriedEntity, true)
        Natives.InvokeVoid(K.NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, carriedEntity, false)
        log("carried NPC died, switching to the dead-body carry")
    end

    if carriedNpcDead and table.concat(cfg.body, ",") ~= appliedBodyKey then
        attachDeadBody(carriedEntity, getPed())
    end
end

local function updatePendingAttach()
    if pendingAttach == nil then return end
    local pa = pendingAttach
    local elapsed = Time.GetEpocheMs() - pa.t0

    if pa.kind == K.KIND_NPC then
        -- A living NPC needs its carry animation loaded before the attach.
        if entityOk(pa.entity) and not Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, pa.entity, false) then
            Natives.InvokeVoid(K.NATIVE.REQUEST_ANIM_DICT, K.NPC_BODY_ANIM_DICT)
            if not Natives.InvokeBool(K.NATIVE.HAS_ANIM_DICT_LOADED, K.NPC_BODY_ANIM_DICT)
                and elapsed < K.NPC_DICT_WAIT_MS then
                return
            end
        end
    elseif pa.kind == K.KIND_OBJECT then
        if entityOk(pa.entity) then reinforceUnhook(pa.entity) end
        if elapsed < K.UNHOOK_DELAY_MS then return end
    elseif elapsed < K.UNHOOK_DELAY_MS then
        return
    end

    pendingAttach = nil
    if entityOk(pa.entity) then
        attachGrabbed(pa.entity, pa.ped, pa.kind)
    end
end

local function grabTarget(ped)
    local entity, kind = findGrabTarget(ped, cfg.grabRadius,
        { safe = cfg.safe, grabNpc = cfg.grabNpc })

    if entity == nil then
        toast("Nothing to grab in the crosshair.")
        return
    end

    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, entity)
    pendingEntity, pendingPed, pendingSince, pendingKind = entity, ped, Time.GetEpocheMs(), kind
    log(kind .. " " .. tostring(entity) .. " found, waiting for network control")
end

local function updatePendingGrab()
    if pendingEntity == nil then return end

    if not entityOk(pendingEntity) then
        pendingEntity = nil
        return
    end

    if Natives.InvokeBool(K.NATIVE.NETWORK_HAS_CONTROL_OF_ENTITY, pendingEntity) then
        local e, p, k = pendingEntity, pendingPed, pendingKind
        pendingEntity, pendingPed = nil, nil
        finalizeGrab(e, p, k)
        return
    end

    -- Re-request control every frame: a single request often fails.
    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, pendingEntity)

    if Time.GetEpocheMs() - pendingSince > K.CONTROL_TIMEOUT_MS then
        toast("Couldn't get control of it, try again.", 3000)
        pendingEntity, pendingPed = nil, nil
    end
end

-- ---------- throw / drop ----------

local function detachEntity(entity)
    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, entity)
    Natives.InvokeVoid(K.NATIVE.DETACH_ENTITY, entity, true, true)
    if carriedKind == K.KIND_OBJECT then
        Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, entity, false)
        Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, entity)
    elseif carriedKind == K.KIND_NPC and not carriedNpcDead then
        -- Stop the carry pose and give the NPC its AI/ragdoll back.
        Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS_IMMEDIATELY, entity)
        Natives.InvokeVoid(K.NATIVE.SET_PED_CAN_RAGDOLL, entity, true)
        Natives.InvokeVoid(K.NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, entity, false)
    end
end

-- Throw direction: toward the point the crosshair is aiming at (corrects the
-- gap between the camera and the hand), falling back to the camera's axis.
K.AIM_RANGE = 120.0

local function getAimDirection(ped, ox, oy, oz)
    local cam = getCameraDirection()
    local ray = castRay(ped, K.AIM_RANGE)
    if ray and ray.x and ray.y and ray.z then
        local dx, dy, dz = ray.x - ox, ray.y - oy, ray.z - oz
        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
        if len > 3.0 then
            local d = { x = dx / len, y = dy / len, z = dz / len }
            -- Safety: ignore an aim point that ends up "behind" us.
            if d.x * cam.x + d.y * cam.y + d.z * cam.z > 0.3 then
                return d
            end
        end
    end
    return cam
end

-- Start point of a throw: in front of the player. If aiming downward, don't
-- place the object below the ground: only the upward component shifts the height.
local function getThrowStart(ped)
    local camDir = getCameraDirection()
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local lift = math.max(camDir.z, 0.0) * K.THROW_START_AHEAD
    return px + camDir.x * K.THROW_START_AHEAD,
           py + camDir.y * K.THROW_START_AHEAD,
           pz + 1.0 + lift
end

-- Power a throw would have right now (charge level included).
local function currentThrowPower()
    if cfg.charged then
        return cfg.throwSpeed * (K.DEFAULTS.throwMinPct + (1.0 - K.DEFAULTS.throwMinPct) * chargeFrac)
    end
    return cfg.throwSpeed
end

-- ---------- trajectory preview ----------
-- Approximate ballistic arc (gravity only, no drag): the real object is driven
-- by the game's physics, so it is an indication, not a guarantee (calibrate it
-- with the "Preview Gravity" slider).
--  * The curve is simulated in small steps for a smooth drawing, but the
--    (expensive) raycasts only run on longer chunks (~25 m of path each) and
--    at most TRAJ_MAX_RAYS per update.
--  * The simulation runs every ~60 ms; the projection to the screen runs on
--    every tick so the arc follows the camera smoothly.
--  * The impact is classified: ground/scenery, entity, or a real player
--    (safety warning).
local traj = {
    world = {}, total = 0.0, hit = nil, hitKind = nil,   -- simulation result
    points = {}, impact = nil,                          -- projected, read by drawCrosshair
    playerInLine = false,
}
local clearTrajectory, updateTrajectory
do -- nested: trajectory
K.TRAJ_SIM_INTERVAL_MS  = 60
K.TRAJ_SUBSTEPS         = 4      -- drawn points per raycast chunk
K.TRAJ_MAX_RAYS         = 10
K.TRAJ_CHUNK_METERS     = 25.0   -- path length covered by one raycast
K.TRAJ_MIN_CHUNK_S, K.TRAJ_MAX_CHUNK_S = 0.08, 0.4
K.TRAJ_WARN_COOLDOWN_MS = 4000
local screenBufs = nil
local lastSimMs, lastWarnMs = 0, 0

-- World point -> screen position (0..1), or nil when it's off screen.
local function worldToScreen(x, y, z)
    screenBufs = screenBufs or { x = Memory.Alloc(8), y = Memory.Alloc(8) }
    local onScreen = Natives.InvokeBool(K.NATIVE.GET_SCREEN_COORD_FROM_WORLD_COORD,
        x, y, z, screenBufs.x, screenBufs.y)
    if not onScreen then return nil end
    local sx, sy = memReadFloat(screenBufs.x), memReadFloat(screenBufs.y)
    if sx and sy then return sx, sy end
    return nil
end

-- First thing hit between two points: { x, y, z, entity?, etype? } or nil.
local function castSegment(ped, x1, y1, z1, x2, y2, z2)
    if rayUnsupported then return nil end
    local ok, res = pcall(function()
        local handle = Natives.InvokeInt(K.NATIVE.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE,
            x1, y1, z1, x2, y2, z2, K.RAY_FLAGS, ped, 7)
        local b = getRayBufs()
        memWriteInt(b.hit, 0)
        memWriteInt(b.ent, 0)
        Natives.InvokeInt(K.NATIVE.GET_SHAPE_TEST_RESULT, handle, b.hit, b.pos, b.nrm, b.ent)
        local hv = memReadInt(b.hit)
        if hv == nil or hv == 0 then return false end

        -- The Vector3 layout may use 4- or 8-byte gaps: keep the one that lies
        -- on the segment.
        local out = nil
        for _, step in ipairs({ 8, 4 }) do
            local x = memReadFloat(b.pos, 0)
            local y = memReadFloat(b.pos, step)
            local z = memReadFloat(b.pos, step * 2)
            if x and y and z
                and x >= math.min(x1, x2) - 1.0 and x <= math.max(x1, x2) + 1.0
                and y >= math.min(y1, y2) - 1.0 and y <= math.max(y1, y2) + 1.0
                and z >= math.min(z1, z2) - 1.0 and z <= math.max(z1, z2) + 1.0 then
                out = { x = x, y = y, z = z }
                break
            end
        end
        if not out then return false end

        local ent = memReadInt(b.ent)
        if ent ~= nil and ent ~= 0 and entityOk(ent) then
            out.entity = ent
            out.etype  = Natives.InvokeInt(K.NATIVE.GET_ENTITY_TYPE, ent)
        end
        return out
    end)
    if ok and res then return res end
    return nil
end

-- "none" | "ground" | "entity" | "player" (real player, or a vehicle with one inside)
local function classifyHit(hit, ped)
    if not hit then return "none" end
    if hit.entity then
        if hit.etype == 1 and hit.entity ~= ped
            and Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, hit.entity) then
            return "player"
        end
        if hit.etype == 2 then
            local _, hasPlayer, consent = vehicleOccupants(hit.entity)
            if hasPlayer and not consent then return "player" end
        end
        if hit.etype == 1 or hit.etype == 2 then return "entity" end
    end
    return "ground"
end

-- Simulates the throw as it would happen right now.
-- Returns world points { x, y, z, distance }, the hit (or nil), and the length.
local function simulate(ped)
    local ox, oy, oz = getThrowStart(ped)
    local dir = getAimDirection(ped, ox, oy, oz)
    local power = currentThrowPower() * rageMultiplier()
    local g = cfg.trajGravity
    local x, y, z = ox, oy, oz
    local vx, vy = dir.x * power, dir.y * power
    local vz
    if carriedKind == K.KIND_NPC then
        -- An NPC is launched from where the player stands, with an extra lift.
        x, y, z = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
        z = z + 1.0
        vz = math.max(0.0, dir.z * power) + K.PUNCH_UP_BOOST
    else
        vz = dir.z * power + K.THROW_UP_BOOST
    end

    -- Fast throws need long chunks (few rays), slow ones short chunks.
    local chunkT = clamp(K.TRAJ_CHUNK_METERS / math.max(power, 1.0), K.TRAJ_MIN_CHUNK_S, K.TRAJ_MAX_CHUNK_S)
    local subT = chunkT / K.TRAJ_SUBSTEPS

    local world = { { x, y, z, 0.0 } }
    local travelled, hit = 0.0, nil

    for _ = 1, K.TRAJ_MAX_RAYS do
        local cx, cy, cz, cvz = x, y, z, vz
        local sub = {}
        for i = 1, K.TRAJ_SUBSTEPS do
            cx = cx + vx * subT
            cy = cy + vy * subT
            cz = cz + cvz * subT - 0.5 * g * subT * subT
            cvz = cvz - g * subT
            sub[i] = { cx, cy, cz }
        end

        local chord = math.sqrt(distSq(x, y, z, cx, cy, cz))
        local h = castSegment(ped, x, y, z, cx, cy, cz)
        if h then
            -- Keep the drawn points that come before the impact, then the impact.
            local hd = math.sqrt(distSq(x, y, z, h.x, h.y, h.z))
            local frac = (chord > 0.001) and (hd / chord) or 1.0
            for i = 1, K.TRAJ_SUBSTEPS - 1 do
                if i / K.TRAJ_SUBSTEPS < frac then
                    local p = sub[i]
                    world[#world + 1] = { p[1], p[2], p[3],
                        travelled + math.sqrt(distSq(x, y, z, p[1], p[2], p[3])) }
                end
            end
            travelled = travelled + hd
            world[#world + 1] = { h.x, h.y, h.z, travelled }
            hit = h
            break
        end

        local px, py, pz = x, y, z
        for i = 1, K.TRAJ_SUBSTEPS do
            local p = sub[i]
            travelled = travelled + math.sqrt(distSq(px, py, pz, p[1], p[2], p[3]))
            world[#world + 1] = { p[1], p[2], p[3], travelled }
            px, py, pz = p[1], p[2], p[3]
        end
        x, y, z, vz = cx, cy, cz, cvz
        if travelled >= cfg.trajLength then break end
    end
    return world, hit, travelled
end

-- World points -> screen points (progress 0..1 along the arc as 3rd value).
local function project()
    local total = math.max(traj.total, 1.0)
    local pts = {}
    for i, p in ipairs(traj.world) do
        local sx, sy = worldToScreen(p[1], p[2], p[3])
        pts[i] = sx and { sx, sy, clamp(p[4] / total, 0.0, 1.0) } or false
    end
    traj.points = pts
    traj.impact = nil
    if traj.hit then
        local sx, sy = worldToScreen(traj.hit.x, traj.hit.y, traj.hit.z)
        if sx then traj.impact = { sx, sy } end
    end
end

function clearTrajectory()
    if #traj.world > 0 or #traj.points > 0 then
        traj.world, traj.points, traj.impact, traj.hit = {}, {}, nil, nil
        traj.hitKind, traj.total, traj.playerInLine = nil, 0.0, false
    end
end

-- Simulation here (main loop), drawing in drawCrosshair (present callback).
function updateTrajectory(ped, now)
    local active = cfg.trajectory and carrying and pendingAttach == nil and entityOk(carriedEntity)
        and (not cfg.trajChargeOnly or chargeStart ~= nil)
    if not active then
        clearTrajectory()
        return
    end

    if now - lastSimMs >= K.TRAJ_SIM_INTERVAL_MS then
        lastSimMs = now
        local world, hit, total = simulate(ped)
        traj.world, traj.hit, traj.total = world, hit, total
        traj.hitKind = classifyHit(hit, ped)

        local wasInLine = traj.playerInLine
        traj.playerInLine = (traj.hitKind == "player")
        if traj.playerInLine and not wasInLine and now - lastWarnMs > K.TRAJ_WARN_COOLDOWN_MS then
            lastWarnMs = now
            toast("Warning: a player is in the line of fire!", 2500)
        end
    end

    -- Re-projected every tick: the arc follows the camera without lag.
    project()
end
end -- nested: trajectory

local function throwCarriedEntity(ped, power)
    local entity = carriedEntity
    local kind = carriedKind
    local wasMaxCharge = chargeStart ~= nil and chargeFrac >= 0.95   -- quest counter
    carrying, carriedEntity = false, nil
    chargeStart, chargeFrac = nil, 0.0
    stopCarryAnim(ped)

    if not entityOk(entity) then
        return
    end

    playSound(K.SND.throw)
    if wasMaxCharge then stats.fullCharges = stats.fullCharges + 1 end
    local ox, oy, oz = getThrowStart(ped)

    -- Aim computed before detaching (collision still disabled).
    local dir = getAimDirection(ped, ox, oy, oz)

    -- Rage Mode: the more you've been smashing, the harder this throw hits.
    power = power * rageMultiplier()

    detachEntity(entity)
    -- Collision was switched off for the carry: turn it back on right away,
    -- whatever the kind (a thrown NPC would otherwise fall through the map).
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, entity, true, true)

    if kind == K.KIND_NPC then
        -- NPCs get the same treatment as a super-punched NPC: ragdoll kept
        -- active while the velocity is re-applied for a short while, which
        -- is what actually makes the throw stick over the network.
        startPunchPush(entity, K.KIND_NPC, dir, power)
        if cfg.shake then
            Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "SMALL_EXPLOSION_SHAKE", 0.6)
        end
        stats.npcsThrown = stats.npcsThrown + 1
        addRage(K.RAGE_PER_HIT)
        K.xpThrow(entity, kind)
        scheduleRelease(entity)
        log(string.format("throw %s v=%.0f dir=(%.2f, %.2f, %.2f)", kind, power, dir.x, dir.y, dir.z))
        return
    end

    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COORDS_NO_OFFSET, entity, ox, oy, oz, false, false, false)

    if kind == K.KIND_OBJECT then
        Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, entity, false)
        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DYNAMIC, entity, true)
        Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, entity)
    end

    local vx, vy, vz = dir.x * power, dir.y * power, dir.z * power + K.THROW_UP_BOOST
    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_VELOCITY, entity, vx, vy, vz)

    -- A freshly detached entity's physics only resumes one frame later (and a
    -- vehicle's network sync can overwrite the velocity), so we re-apply the
    -- velocity for a short moment, for objects and vehicles alike. A
    -- ground-fixed object (lamppost, sign...) needs much more insistence to
    -- actually start simulating physics, so it gets a longer window.
    settle(entity, vx, vy, vz, kind == K.KIND_OBJECT and K.SETTLE_PUSH_MS_OBJECT or nil)
    if kind == K.KIND_OBJECT then
        stats.objectsThrown = stats.objectsThrown + 1
    else
        stats.vehiclesThrown = stats.vehiclesThrown + 1
    end
    addRage(K.RAGE_PER_HIT)
    K.xpThrow(entity, kind)
    scheduleRelease(entity)

    if cfg.shake then
        Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "SMALL_EXPLOSION_SHAKE", 0.6)
    end
    log(string.format("throw %s v=%.0f dir=(%.2f, %.2f, %.2f)", kind, power, dir.x, dir.y, dir.z))
end

-- Puts the carried entity down (toggle off, death, X key...) without throwing it.
local function releaseWithoutThrowing()
    if carriedEntity ~= nil and entityOk(carriedEntity) then
        detachEntity(carriedEntity)
        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, carriedEntity, true, true)
        if carriedKind == K.KIND_OBJECT then
            -- Without waking its physics back up, the object would stay
            -- frozen wherever it's dropped. Ground-fixed props need longer.
            settle(carriedEntity, nil, nil, nil, K.SETTLE_WAKE_MS_OBJECT)
        elseif carriedKind == K.KIND_NPC then
            -- Let them fall down limp rather than teleport-standing; the
            -- game's own AI recovers them back to their feet afterward.
            Natives.InvokeVoid(K.NATIVE.SET_PED_TO_RAGDOLL, carriedEntity, 1500, 1500, 0, false, false, false)
        end
        scheduleRelease(carriedEntity)
    end
    if carrying then
        Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS, getPed())
    end
    animPlaying = false
    activeCarryAnimDict, activeCarryAnimClip = nil, nil
    carrying, carriedEntity = false, nil
    pendingEntity, pendingPed = nil, nil
    pendingAttach = nil
    chargeStart, chargeFrac = nil, 0.0
    clearTargetHighlight()
end

-- ---------- super punch ----------
-- How it works: on CLICK, the target is chosen (whatever the crosshair is
-- aiming at, with a bit of aim assist); after the configured delay (fist
-- impact), it gets the impulse, waiting for network control if needed. If
-- there's nothing in the crosshair, nothing happens (no more "random" punches).

K.PUNCH_CONTROL_WAIT_MS = 1000   -- max wait for network control
K.PUNCH_PUSH_MS         = 450    -- duration the velocity is re-applied for
K.PUNCH_SOFTLOCK_RANGE  = 5.0    -- soft-lock: closest target in front of you (m)

-- Aim-assist fan: offsets (right, up) in meters at the END of the ray. The
-- centre ray is the crosshair; the first ring is always used, the two outer
-- rings only with "Wide Aim Assist".
K.PUNCH_FAN = { { 0.0, 0.0 } }
K.PUNCH_FAN_BASE_COUNT = 0
do
    local function ring(radius, count)
        for k = 0, count - 1 do
            local ang = (k / count) * 2.0 * math.pi
            K.PUNCH_FAN[#K.PUNCH_FAN + 1] = { math.cos(ang) * radius, math.sin(ang) * radius }
        end
    end
    ring(0.5, 6)
    K.PUNCH_FAN_BASE_COUNT = #K.PUNCH_FAN
    ring(1.1, 8)
    ring(1.8, 8)
end

local function isUnarmed(ped)
    local WEAPON_UNARMED_A = 0xA2719263
    local WEAPON_UNARMED_B = -1569615261  -- same hash, signed form
    local w = Natives.InvokeInt(K.NATIVE.GET_SELECTED_PED_WEAPON, ped)
    return w == WEAPON_UNARMED_A or w == WEAPON_UNARMED_B
end

-- Is the target inside the aim cone (~53°)? Avoids punches that land "off to the side".
local function inAimCone(ped, ex, ey, ez, dir)
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local dx, dy, dz = ex - px, ey - py, ez - pz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.5 then return true end
    return (dx * dir.x + dy * dir.y + dz * dir.z) / len > 0.6
end

-- Soft-lock / fallback (no raycast hit, or raycast unavailable): the closest
-- vehicle or NPC in front of the player, within `radius` meters.
local function legacyTarget(ped, safe, dir, radius)
    radius = radius or K.DEFAULTS.punchRadius
    local vehicle, vehD = findNearestVehicle(ped, radius, { safe = safe })
    local npc, npcD     = findNpcInRange(ped, radius, dir)

    if vehicle ~= nil then
        local x, y, z = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, vehicle, true)
        if not inAimCone(ped, x, y, z, dir) then vehicle, vehD = nil, nil end
    end

    local target, kind
    if vehicle ~= nil then target, kind = vehicle, K.KIND_VEHICLE end
    -- An NPC sitting in a vehicle is covered by the vehicle itself.
    if npc ~= nil and vehicleOfPed(npc) == nil and (vehD == nil or npcD < vehD) then
        target, kind = npc, K.KIND_NPC
    end
    return target, kind
end

-- Chooses the punch's target. Returns target, kind, scenery, dir (target and
-- scenery both nil = nothing found). Priority: npc/vehicle > object > scenery,
-- and the closest to the crosshair wins among equals. Players are never targeted.
local function pickPunchTarget(ped, safe)
    local dir = getCameraDirection()
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local best = nil
    local punchRange = cfg.punchRange
    local rayCount = cfg.wideAim and #K.PUNCH_FAN or K.PUNCH_FAN_BASE_COUNT

    for i = 1, rayCount do
        local off = K.PUNCH_FAN[i]
        local ray, rayOk = castRay(ped, punchRange, off[1], off[2])

        if not rayOk then
            -- Raycast unavailable: fall back to searching around the player.
            local t, k = legacyTarget(ped, safe, dir)
            return t, k, nil, dir
        end

        if ray then
            local score, target, kind, scenery = 0, nil, nil, nil
            if ray.entity then
                local ex, ey, ez = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ray.entity, true)
                if distSq(ex, ey, ez, px, py, pz) <= (punchRange + 3.0) ^ 2 then
                    if ray.etype == 1 then
                        local veh = vehicleOfPed(ray.entity)
                        if veh ~= nil then
                            -- NPC sitting in a vehicle: punch the vehicle.
                            if vehicleAllowed(veh, { safe = safe }) then
                                score, target, kind = 3, veh, K.KIND_VEHICLE
                            end
                        elseif ray.entity ~= ped and ray.entity ~= K.PG.pet and not Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, ray.entity) then
                            score, target, kind = 3, ray.entity, K.KIND_NPC
                        end
                    elseif ray.etype == 2 then
                        if vehicleAllowed(ray.entity, { safe = safe }) then
                            score, target, kind = 3, ray.entity, K.KIND_VEHICLE
                        end
                    elseif ray.etype == 3 then
                        if not Natives.InvokeBool(K.NATIVE.IS_ENTITY_ATTACHED, ray.entity) then
                            score, target, kind = 2, ray.entity, K.KIND_OBJECT
                        end
                    end
                end
            elseif ray.x ~= nil and off[1] == 0.0 and off[2] == 0.0 then
                -- Scenery: only the center ray counts.
                score, scenery = 1, { x = ray.x, y = ray.y, z = ray.z }
            end

            if score > 0 and (best == nil or score > best.score) then
                best = { score = score, target = target, kind = kind, scenery = scenery }
            end
        end
    end

    -- Soft-lock: the crosshair missed (or only found scenery / an object): hit
    -- the closest vehicle or NPC right in front of the player instead.
    if cfg.softLock and (best == nil or best.score < 3) then
        local t, k = legacyTarget(ped, safe, dir, K.PUNCH_SOFTLOCK_RANGE)
        if t ~= nil then
            log("super punch: soft-lock on a nearby " .. tostring(k))
            return t, k, nil, dir
        end
    end

    if best == nil then
        return nil, nil, nil, dir
    end
    return best.target, best.kind, best.scenery, dir
end

-- ---------- impulse (waits for network control) ----------

local punches = {}   -- { entity, kind, vx, vy, vz, t0, pushUntil, nextMs, prepared, ragdollMs }

-- (forward-declared above, assigned here)
startPunchPush = function(target, kind, dir, power)
    for i = #punches, 1, -1 do
        if punches[i].entity == target then table.remove(punches, i) end
    end
    if kind == K.KIND_OBJECT then unsettle(target) end

    punches[#punches + 1] = {
        entity = target, kind = kind,
        vx = dir.x * power, vy = dir.y * power,
        vz = math.max(0.0, dir.z * power) + K.PUNCH_UP_BOOST,
        t0 = Time.GetEpocheMs(), pushUntil = nil, nextMs = 0, prepared = false, ragdollMs = 0,
    }
    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, target)
end

-- Step 1: wait for control (re-requested every frame, up to 1 s).
-- Step 2: re-apply the velocity for ~450 ms (an NPC's ragdoll, an object's
-- physics, or a vehicle's network sync would otherwise overwrite it).
-- Frozen / sleeping physics are woken up first: a parked car or a trash can
-- simply ignores a velocity otherwise.
local function processPunches()
    if #punches == 0 then return end
    local now = Time.GetEpocheMs()

    for i = #punches, 1, -1 do
        local p = punches[i]
        if not entityOk(p.entity) then
            table.remove(punches, i)
        else
            if p.pushUntil == nil then
                local hasControl = Natives.InvokeBool(K.NATIVE.NETWORK_HAS_CONTROL_OF_ENTITY, p.entity)
                if hasControl or now - p.t0 > K.PUNCH_CONTROL_WAIT_MS then
                    if not hasControl then
                        log("super punch: no network control after " .. K.PUNCH_CONTROL_WAIT_MS .. " ms, pushing anyway (may not land)")
                    end
                    p.pushUntil = now + K.PUNCH_PUSH_MS
                else
                    Natives.InvokeBool(K.NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY, p.entity)
                end
            end

            if p.pushUntil ~= nil then
                if now > p.pushUntil then
                    table.remove(punches, i)
                elseif now >= p.nextMs then
                    p.nextMs = now + 40
                    if p.kind == K.KIND_NPC then
                        if not p.prepared then
                            p.prepared = true
                            Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS_IMMEDIATELY, p.entity)
                            -- Some peds can't ragdoll, and a thrown NPC may still
                            -- have collision off from the carry.
                            Natives.InvokeVoid(K.NATIVE.SET_PED_CAN_RAGDOLL, p.entity, true)
                            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, p.entity, true, true)
                        end
                        if now - p.ragdollMs >= 250 then
                            p.ragdollMs = now
                            Natives.InvokeVoid(K.NATIVE.SET_PED_TO_RAGDOLL, p.entity, 1500, 1500, 0, false, false, false)
                        end
                    else
                        -- Vehicles AND objects: collision on, unfrozen, awake.
                        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COLLISION, p.entity, true, true)
                        Natives.InvokeVoid(K.NATIVE.FREEZE_ENTITY_POSITION, p.entity, false)
                        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_DYNAMIC, p.entity, true)
                        Natives.InvokeVoid(K.NATIVE.ACTIVATE_PHYSICS, p.entity)
                    end
                    Natives.InvokeVoid(K.NATIVE.SET_ENTITY_VELOCITY, p.entity, p.vx, p.vy, p.vz)
                end
            end
        end
    end
end

-- ---------- punch sound ----------
-- Layers { sound, delay (ms), minimum rage }: the higher styles stack more
-- sounds, and the last ones only join in once the rage meter has built up.
-- A name that doesn't exist on your build is simply silent: try the other styles.
local playPunchSound
do
    local WHIFF = { "Hit_1", "LONG_PLAYER_SWITCH_SOUNDSET" }
    local STYLES = {
        { -- 1: Classic
        },
        { -- 2: Heavy (bass boom + crack + thud)
            { { "ScreenFlash", "WastedSounds" }, 0, 0 },
            { { "Hit_1", "LONG_PLAYER_SWITCH_SOUNDSET" }, 70, 0 },
        },
        { -- 3: Brutal (everything, plus a stinger and a rising tail with rage)
            { { "ScreenFlash", "WastedSounds" }, 0, 0 },
            { { "Hit_1", "LONG_PLAYER_SWITCH_SOUNDSET" }, 60, 0 },
            { { "Pre_Screen_Stinger", "DLC_HEISTS_FINALE_SCREEN_SOUNDS" }, 110, 30 },
            { { "MEDAL_UP", "HUD_MINI_GAME_SOUNDSET" }, 220, 60 },
        },
    }

    function playPunchSound(hitSomething)
        if not cfg.sounds then return end
        if not hitSomething then
            queueSound(WHIFF, 0)          -- scenery: just a light thud
            return
        end
        local style = STYLES[clamp(cfg.punchSoundStyle, 1, #STYLES)]
        for _, layer in ipairs(style) do
            if rageLevel >= layer[3] then
                queueSound(layer[1], layer[2])
            end
        end
    end
end

-- Executes the punch at the moment of impact. The target chosen at the click
-- is checked again; if it vanished, moved out of reach, or nothing had been
-- found at the click, the target is picked again right now.
local function performPunch(ped, p)
    local power = cfg.punchSpeed * rageMultiplier()
    local target, kind, scenery, dir = p.target, p.kind, p.scenery, p.dir

    local function reachable(e)
        if not entityOk(e) then return false end
        local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
        local ex, ey, ez = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, e, true)
        return distSq(ex, ey, ez, px, py, pz) <= (cfg.punchRange + 4.0) ^ 2
    end

    if target ~= nil and not reachable(target) then
        target, kind = nil, nil
    end
    if target == nil then
        local t2, k2, s2, d2 = pickPunchTarget(ped, cfg.safe)
        if t2 ~= nil then
            target, kind, scenery, dir = t2, k2, nil, d2
            log("super punch: target picked again at impact")
        elseif scenery == nil then
            scenery = s2
        end
    end

    if target ~= nil then
        -- Re-checks: a player may have gotten into the vehicle in the meantime.
        if kind == K.KIND_VEHICLE and not vehicleAllowed(target, { safe = cfg.safe }) then
            log("super punch cancelled: a player is in the vehicle")
            return false
        end
        if kind == K.KIND_NPC and Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, target) then
            return false
        end

        startPunchPush(target, kind, dir, power)
        stats.punchesLanded = stats.punchesLanded + 1
        addRage(K.RAGE_PER_HIT)
        K.xpPunch(target, kind)
        playPunchSound(true)
        log("super punch on " .. kind .. " " .. tostring(target) .. " power=" .. string.format("%.0f", power))
        if cfg.shake then
            Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "SMALL_EXPLOSION_SHAKE", 0.8)
        end
        return true
    end

    if scenery ~= nil then
        -- Scenery: just a camera shake, no explosion.
        if cfg.impact then
            Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "SMALL_EXPLOSION_SHAKE", 1.0)
            log("super punch on scenery (shake)")
        end
        playPunchSound(false)
        stats.sceneryHits = stats.sceneryHits + 1
        return true
    end

    log("super punch: nothing to hit at impact")
    return false
end

-- ---------- crosshair + charge bar ----------

local function drawCrosshair()
    local CROSSHAIR_SIZE, CROSSHAIR_GAP, CROSSHAIR_THICKNESS = 12.0, 4.5, 1.6
    local CROSSHAIR_COLOR = { 245, 250, 255, 240 }
    local w, h = ImGui.GetDisplaySize()
    local cx, cy = w / 2.0, h / 2.0
    local hasGrabTarget = highlightedEntity ~= nil and cfg.highlight and not carrying
    local r, g, b, a = CROSSHAIR_COLOR[1], CROSSHAIR_COLOR[2], CROSSHAIR_COLOR[3], CROSSHAIR_COLOR[4]

    -- Line drawn rotated around the reticle centre (cs/sn = cos/sin of the spin angle).
    local cs, sn = 1.0, 0.0
    local function rl(x0, y0, x1, y1, thick, cr, cg, cb, ca)
        ImGui.AddLine(cx + x0 * cs - y0 * sn, cy + x0 * sn + y0 * cs,
                      cx + x1 * cs - y1 * sn, cy + x1 * sn + y1 * cs,
                      cr or r, cg or g, cb or b, ca or a, thick)
    end

    -- Target locked: the reticle turns bright green, gains four corner brackets
    -- and SPINS on itself (same look as the intro logo): the brackets and the
    -- cross rotate, and three arc blades turn around them.
    if hasGrabTarget then
        r, g, b, a = 40, 255, 95, 255
        local spin = ((Time.GetEpocheMs() % 1400) / 1400.0) * 2.0 * math.pi   -- one turn / 1.4 s
        cs, sn = math.cos(spin), math.sin(spin)

        local outer, inner, thick = 22.0, 12.0, 3.0
        rl(-outer, -outer, -inner, -inner, thick)
        rl( outer, -outer,  inner, -inner, thick)
        rl(-outer,  outer, -inner,  inner, thick)
        rl( outer,  outer,  inner,  inner, thick)

        -- Three blades turning the opposite way, like the intro trefoil.
        local R, n = 31.0, 8
        for k = 0, 2 do
            local base = -spin * 1.5 + k * 2.0 * math.pi / 3.0
            local px, py = cx + math.cos(base) * R, cy + math.sin(base) * R
            for j = 1, n do
                local ang = base + (j / n) * (math.pi / 3.0)
                local nx, ny = cx + math.cos(ang) * R, cy + math.sin(ang) * R
                ImGui.AddLine(px, py, nx, ny, r, g, b, 230, 3.0)
                px, py = nx, ny
            end
        end
        -- Faint guide ring.
        local px, py = cx + R, cy
        for j = 1, 24 do
            local ang = (j / 24) * 2.0 * math.pi
            local nx, ny = cx + math.cos(ang) * R, cy + math.sin(ang) * R
            ImGui.AddLine(px, py, nx, ny, r, g, b, 70, 1.5)
            px, py = nx, ny
        end
    end

    if cfg.cross then
        local S, G, T = CROSSHAIR_SIZE, CROSSHAIR_GAP, CROSSHAIR_THICKNESS

        -- Soft dark outline under every stroke so the reticle stays readable
        -- on bright backgrounds (sky, snow, desert) as well as dark ones.
        local function arms(thick, cr, cg, cb, ca)
            rl(-S, 0, -G, 0, thick, cr, cg, cb, ca)
            rl( G, 0,  S, 0, thick, cr, cg, cb, ca)
            rl(0, -S, 0, -G, thick, cr, cg, cb, ca)
            rl(0,  G, 0,  S, thick, cr, cg, cb, ca)
        end
        arms(T + 2.0, 0, 0, 0, 110)

        -- Idle style: four short arc segments on the diagonals around the cross,
        -- plus tiny end ticks on the arms (a clean "tactical" look).
        if not hasGrabTarget then
            local R = 17.0
            for k = 0, 3 do
                local base = math.pi / 4.0 + k * math.pi / 2.0 - math.pi / 9.0
                local n = 6
                local px, py = cx + math.cos(base) * R, cy + math.sin(base) * R
                local sx, sy = px, py
                local segs = {}
                for j = 1, n do
                    local ang = base + (j / n) * (2.0 * math.pi / 9.0)
                    local nx, ny = cx + math.cos(ang) * R, cy + math.sin(ang) * R
                    segs[#segs + 1] = { px, py, nx, ny }
                    px, py = nx, ny
                end
                for _, sg in ipairs(segs) do
                    ImGui.AddLine(sg[1], sg[2], sg[3], sg[4], 0, 0, 0, 100, 3.2)
                end
                for _, sg in ipairs(segs) do
                    ImGui.AddLine(sg[1], sg[2], sg[3], sg[4], r, g, b, 200, 1.5)
                end
            end
            -- end ticks
            rl(-S, -2.5, -S, 2.5, 1.2, r, g, b, 170)
            rl( S, -2.5,  S, 2.5, 1.2, r, g, b, 170)
            rl(-2.5, -S, 2.5, -S, 1.2, r, g, b, 170)
            rl(-2.5,  S, 2.5,  S, 1.2, r, g, b, 170)
        end

        arms(T)
        ImGui.AddCircleFilled(cx, cy, 2.6, 0, 0, 0, 120)
        ImGui.AddCircleFilled(cx, cy, 1.6, r, g, b, a)
    end

    -- Charge bar below the crosshair (green -> red based on power).
    if chargeFrac > 0.0 then
        local barW  = 80.0
        local y     = cy + 28.0
        local x0    = cx - barW / 2.0
        ImGui.AddLine(x0, y, x0 + barW, y, 0, 0, 0, 160, 8.0)
        ImGui.AddLine(x0, y, x0 + barW * chargeFrac, y,
            math.floor(255 * chargeFrac), math.floor(255 * (1.0 - chargeFrac)), 40, 230, 6.0)
    end

    -- Rage bar (orange) just under the charge bar position.
    if cfg.rage and rageLevel > 1.0 then
        local barW  = 80.0
        local y     = cy + 40.0
        local x0    = cx - barW / 2.0
        local frac  = rageLevel / 100.0
        ImGui.AddLine(x0, y, x0 + barW, y, 0, 0, 0, 140, 5.0)
        ImGui.AddLine(x0, y, x0 + barW * frac, y, 255, 140, 20, 230, 3.0)
    end

    -- Trajectory preview (projected to the screen by the main loop).
    if cfg.trajectory and carrying and #traj.points > 1 then
        local prev, lastPt = nil, nil
        for _, pt in ipairs(traj.points) do
            if pt then
                if prev then
                    -- Green near the hand, orange far away; thinner and fainter with distance.
                    local f = pt[3]
                    local la = math.floor(240 - 130 * f)
                    local thick = 3.2 - 1.4 * f
                    local x0, y0, x1, y1 = prev[1] * w, prev[2] * h, pt[1] * w, pt[2] * h
                    ImGui.AddLine(x0, y0, x1, y1, 0, 0, 0, math.floor(la * 0.55), thick + 2.0)
                    local gr, gg, gb = math.floor(70 + 185 * f), math.floor(255 - 90 * f), math.floor(90 * (1.0 - f))
                    if cfg.goldTraj then   -- GOD HULK unlock: golden arc
                        gr, gg, gb = 255, math.floor(225 - 60 * f), math.floor(70 - 60 * f)
                    end
                    ImGui.AddLine(x0, y0, x1, y1, gr, gg, gb, la, thick)
                end
                lastPt = pt
            end
            prev = pt
        end

        local kind = traj.hitKind
        if traj.impact then
            -- Impact marker: amber = ground/scenery, red = entity, magenta + cross = real player.
            local ix, iy = traj.impact[1] * w, traj.impact[2] * h
            local cr, cg, cb, radius = 255, 190, 40, 9.0
            if kind == "entity" then
                cr, cg, cb = 255, 70, 50
            elseif kind == "player" then
                cr, cg, cb, radius = 255, 60, 220, 14.0
            end
            local steps = 14
            local rx0, ry0 = ix + radius, iy
            for k = 1, steps do
                local ang = (k / steps) * 2.0 * math.pi
                local rx1, ry1 = ix + math.cos(ang) * radius, iy + math.sin(ang) * radius
                ImGui.AddLine(rx0, ry0, rx1, ry1, cr, cg, cb, 235, 2.5)
                rx0, ry0 = rx1, ry1
            end
            ImGui.AddCircleFilled(ix, iy, 2.5, cr, cg, cb, 255)
            if kind == "player" then
                local r2 = radius + 7.0
                ImGui.AddLine(ix - r2, iy - r2, ix + r2, iy + r2, cr, cg, cb, 255, 3.0)
                ImGui.AddLine(ix - r2, iy + r2, ix + r2, iy - r2, cr, cg, cb, 255, 3.0)
            end
        elseif lastPt and not traj.hit then
            -- The arc ended without hitting anything (out of range): faint end dot.
            ImGui.AddCircleFilled(lastPt[1] * w, lastPt[2] * h, 3.0, 200, 200, 200, 140)
        end
    end
end


-- ============================================================
--  6) MAIN LOOP
-- ============================================================

-- ============================================================
--  QUEST POPUP: small on-screen panel (visible even when the Cherax menu is
--  closed) showing 3 to 5 quests such as "THROW 5 VEHICLES". Completing one
--  gives points, then it is replaced by a new quest. Progress comes from the
--  Session Stats counters. Points / level / active quests are saved to
--  HulkMode_progress.cfg (see K.saveQuestProgress). Removable: "Quest Popup" toggle in the menu, or
--  F8 to hide / show it quickly. Pure ImGui lines (a tiny stroke font is
--  used for the text), so it needs no text API.
--  Delete this whole block (plus the "quests" entries in the menu / config)
--  to remove the feature.
-- ============================================================
local updateQuests, questSummary   -- (K.saveQuestProgress / K.questLifetimeText: no extra top-level local)
do -- nested: quests

-- ---------- quest catalogue ----------
-- def(stat, target, reward, minLevel, verb, noun). Label = "VERB TARGET NOUN"
-- (keep it under ~22 characters so it fits in the panel). "throws" is a
-- virtual stat = vehicles + NPCs + objects thrown.
local QUEST_DEFS, QUEST_BY_ID = {}, {}
local function def(stat, target, reward, minLevel, verb, noun)
    local d = { id = stat .. "_" .. target, stat = stat, target = target, reward = reward,
                minLevel = minLevel, verb = verb, noun = noun }
    QUEST_DEFS[#QUEST_DEFS + 1] = d
    QUEST_BY_ID[d.id] = d
end

-- Vehicles
def("vehiclesThrown", 2,   40,   1,  "THROW", "VEHICLES")
def("vehiclesThrown", 5,   100,  1,  "THROW", "VEHICLES")
def("vehiclesThrown", 10,  250,  3,  "THROW", "VEHICLES")
def("vehiclesThrown", 20,  500,  6,  "THROW", "VEHICLES")
def("vehiclesThrown", 40,  1100, 10, "THROW", "VEHICLES")
-- NPCs
def("npcsThrown", 3,   75,   1,  "THROW", "NPCS")
def("npcsThrown", 8,   200,  2,  "THROW", "NPCS")
def("npcsThrown", 15,  380,  5,  "THROW", "NPCS")
def("npcsThrown", 30,  800,  9,  "THROW", "NPCS")
-- Objects
def("objectsThrown", 5,   50,   1,  "THROW", "OBJECTS")
def("objectsThrown", 12,  150,  2,  "THROW", "OBJECTS")
def("objectsThrown", 25,  320,  5,  "THROW", "OBJECTS")
def("objectsThrown", 50,  700,  9,  "THROW", "OBJECTS")
-- Punches
def("punchesLanded", 10,  75,   1,  "LAND", "PUNCHES")
def("punchesLanded", 25,  200,  2,  "LAND", "PUNCHES")
def("punchesLanded", 50,  400,  4,  "LAND", "PUNCHES")
def("punchesLanded", 100, 850,  8,  "LAND", "PUNCHES")
-- Any throw
def("throws", 15,  200,  3,  "THROW", "ANYTHING")
def("throws", 30,  450,  6,  "THROW", "ANYTHING")
def("throws", 60,  1000, 10, "THROW", "ANYTHING")
-- Grabs
def("grabs", 5,   40,   1,  "GRAB", "THINGS")
def("grabs", 15,  130,  2,  "GRAB", "THINGS")
def("grabs", 30,  300,  5,  "GRAB", "THINGS")
def("grabs", 60,  650,  9,  "GRAB", "THINGS")
-- Fully charged throws
def("fullCharges", 3,   90,   2,  "MAX-CHARGE", "THROWS")
def("fullCharges", 8,   240,  4,  "MAX-CHARGE", "THROWS")
def("fullCharges", 20,  600,  8,  "MAX-CHARGE", "THROWS")
-- Scenery punches
def("sceneryHits", 5,   60,   2,  "SMASH", "WALLS")
def("sceneryHits", 15,  180,  4,  "SMASH", "WALLS")
def("sceneryHits", 30,  420,  7,  "SMASH", "WALLS")
-- Rage
def("rageMaxes", 1,   120,  3,  "MAX RAGE", "TIME")
def("rageMaxes", 3,   350,  6,  "MAX RAGE", "TIMES")
def("rageMaxes", 6,   800,  10, "MAX RAGE", "TIMES")

local STAT_KEYS = { "vehiclesThrown", "npcsThrown", "objectsThrown", "punchesLanded",
                    "grabs", "fullCharges", "sceneryHits", "rageMaxes", "xpEarned" }

-- ---------- levels ----------
local DONE_SHOW_MS = 2800     -- how long "DONE" stays before the quest is replaced
local HIDE_KEY     = 0x77     -- F8
local MAX_POINTS   = 5000000

local function levelNeed(level) return 400 + 100 * (level - 1) end

-- Returns level, points already earned inside this level, points needed for the next one.
local function levelFromPoints(points)
    local level, left = 1, points
    while left >= levelNeed(level) do
        left = left - levelNeed(level)
        level = level + 1
    end
    return level, left, levelNeed(level)
end

local TITLES = {
    { 1, "BANNER" }, { 3, "ANGRY" }, { 5, "SMASHER" }, { 8, "HULK" },
    { 12, "SAVAGE HULK" }, { 16, "WORLD BREAKER" }, { 20, "GOD HULK" },
}
local function titleForLevel(level)
    local title = TITLES[1][2]
    for _, tt in ipairs(TITLES) do
        if level >= tt[1] then title = tt[2] end
    end
    return title
end

local function slotCountForLevel(level)
    if level >= 20 then return 6 end   -- GOD HULK unlock
    if level >= 8 then return 5 end
    if level >= 4 then return 4 end
    return 3
end

-- ---------- state ----------
local slots = {}                 -- { def, base, prog, doneAt }
local restoredSlots = {}         -- [i] = { id, prog } read from the progress file
local questPoints, questsCompleted = 0, 0
local lifetimeBase = {}          -- all-time counters from previous sessions
local knownLevel = 1
local questHidden, hideKeyWasDown, questPaused = false, false, false
local lastQuestDrawError = nil
local seeded = false

-- State of the XP system and of the daily challenge, in ONE table: a Lua
-- function can only hold 200 local variables and this block is close to it.
-- Fields: feed, summary, proj, launched, farm, rampage, daily, restoredDaily,
-- lastDayMs and the 5 feed colours.
local XS = {
    feed = {}, proj = {}, launched = {}, farm = {}, lastDayMs = 0,
    rampage = { count = 0, lastMs = 0 },
    gold ={ 255, 205, 70 }, red = { 255, 120, 70 }, cyan = { 80, 220, 255 },
    green = { 130, 255, 160 }, orange = { 255, 150, 60 },
}

-- Shared by quests and the XP system: toast + save when a level is gained.
-- Each level gives one skill point and may unlock a perk (K.UNLOCKS).
local function checkLevelUp()
    local newLevel = levelFromPoints(questPoints)
    if newLevel > knownLevel then
        local oldLevel = knownLevel
        knownLevel = newLevel
        K.playerLevel = newLevel
        Common.toast("LEVEL UP", string.format("Level %d  -  %s  +%d skill point",
            newLevel, titleForLevel(newLevel), newLevel - oldLevel), 4500)
        for _, u in ipairs(K.UNLOCKS) do
            if oldLevel < u[1] and newLevel >= u[1] then
                Common.toast("UNLOCKED: " .. u[2], u[3], 5000)
            end
        end
        playSound(K.SND.rageMax)
        K.saveQuestProgress(true)
    end
end

local function statValue(key)
    if key == "throws" then
        return stats.vehiclesThrown + stats.npcsThrown + stats.objectsThrown
    end
    return stats[key] or 0
end

local function lifetime(key)
    return (lifetimeBase[key] or 0) + (stats[key] or 0)
end

local function questLabel(d)
    return string.format("%s %d %s", d.verb, d.target, d.noun)
end

-- ---------- picking ----------
local function usedStatsExcept(skip)
    local used = {}
    for j = 1, #slots do
        if j ~= skip and slots[j] then used[slots[j].def.stat] = true end
    end
    return used
end

-- Weighted random pick among the quests allowed at this level. Quests close
-- to the current level are 3x more likely than much easier ones.
local function pickQuest(used, avoidDef, level)
    local function collect(checkStat, checkRange)
        local pool, total = {}, 0
        for _, d in ipairs(QUEST_DEFS) do
            if d ~= avoidDef and d.minLevel <= level
                and not (checkStat and used[d.stat])
                and not (checkRange and d.minLevel < level - 6) then
                local w = (d.minLevel >= level - 3) and 3 or 1
                pool[#pool + 1] = { d, w }
                total = total + w
            end
        end
        return pool, total
    end
    local pool, total = collect(true, true)
    if #pool == 0 then pool, total = collect(false, true) end
    if #pool == 0 then pool, total = collect(false, false) end
    if #pool == 0 then return QUEST_DEFS[1] end
    local r = math.random() * total
    for _, e in ipairs(pool) do
        r = r - e[2]
        if r <= 0 then return e[1] end
    end
    return pool[#pool][1]
end

local function buildSlot(d, prog)
    prog = prog or 0
    return { def = d, base = statValue(d.stat) - prog, prog = prog, doneAt = nil }
end

-- Creates the missing slots (3 at the start, more with the level) and
-- restores the quests that were active when the script was last unloaded.
local function ensureSlots()
    if not seeded then
        seeded = true
        pcall(function() math.randomseed(Time.GetEpocheMs() % 2147483647) end)
    end
    local level = levelFromPoints(questPoints)
    local want = slotCountForLevel(level)
    for i = 1, want do
        if slots[i] == nil then
            local r = restoredSlots[i]
            restoredSlots[i] = nil
            local d = r and QUEST_BY_ID[r.id] or nil
            if d and r.prog < d.target then
                slots[i] = buildSlot(d, r.prog)
            else
                local nd = pickQuest(usedStatsExcept(i), nil, level)
                slots[i] = buildSlot(nd, 0)
            end
        end
    end
end

-- ---------- progress file ----------
local progressPath, progressBroken, progressFailures = nil, false, 0
local lastSavedText, lastSaveMs = nil, 0

local function resolveProgressPath()
    local ok, root = pcall(function() return FileMgr.GetMenuRootPath() end)
    if ok and type(root) == "string" and root ~= "" then
        return root .. "\\Lua\\HulkMode_progress.cfg"
    end
    return nil
end

local function fileRead(path)
    local okE, exists = pcall(function() return FileMgr.DoesFileExist(path) end)
    if not (okE and exists) then return nil end
    local okR, content = pcall(function() return FileMgr.ReadFileContent(path) end)
    if okR and type(content) == "string" then return content end
    return nil
end

local function fileWrite(path, content)
    if pcall(function() FileMgr.WriteFileContent(path, content, false) end) then return true end
    return (pcall(function() FileMgr.WriteFileContent(path, content) end))
end

local function serializeProgress()
    local lines = {
        "points=" .. tostring(math.floor(questPoints)),
        "completed=" .. tostring(math.floor(questsCompleted)),
    }
    for _, k in ipairs(STAT_KEYS) do
        lines[#lines + 1] = "life_" .. k .. "=" .. tostring(math.floor(lifetime(k)))
    end
    for i = 1, #slots do
        local q = slots[i]
        -- A finished quest (points already counted) is saved as empty so that
        -- it is not completed a second time at the next load.
        if q.doneAt ~= nil then
            lines[#lines + 1] = "slot" .. i .. "=-"
        else
            lines[#lines + 1] = "slot" .. i .. "=" .. q.def.id .. ":" .. tostring(math.floor(q.prog))
        end
    end
    if XS.daily ~= nil then
        lines[#lines + 1] = string.format("daily=%s:%s:%d:%d", XS.daily.day, XS.daily.def.id,
            math.floor(XS.daily.prog), XS.daily.done and 1 or 0)
    end
    for _, s in ipairs(K.SKILLS) do
        lines[#lines + 1] = "skill_" .. s.id .. "=" .. tostring(K.skillRanks[s.id] or 0)
    end
    return table.concat(lines, "\n") .. "\n"
end

local function loadProgress()
    progressPath = resolveProgressPath()
    if progressPath == nil then
        progressBroken = true
        K.logWarn("quest progression cannot be saved (no FileMgr): it starts from zero at each load")
        return
    end
    local content = fileRead(progressPath)
    if content then
        for line in content:gmatch("[^\r\n]+") do
            local k, v = line:match("^([%w_]+)=(.+)$")
            if k then
                local n = tonumber(v)
                if k == "points" and n then
                    questPoints = math.max(0, math.min(MAX_POINTS, math.floor(n)))
                elseif k == "completed" and n then
                    questsCompleted = math.max(0, math.min(1000000, math.floor(n)))
                elseif k:sub(1, 5) == "life_" and n then
                    lifetimeBase[k:sub(6)] = math.max(0, math.min(1000000000, math.floor(n)))
                elseif k:match("^slot%d+$") then
                    local idx = tonumber(k:sub(5))
                    local id, prog = v:match("^(.-):(%d+)$")
                    if idx and id then
                        restoredSlots[idx] = { id = id, prog = tonumber(prog) or 0 }
                    end
                elseif k == "daily" then
                    local day, id, prog, dn = v:match("^(%d+):([%w_]+):(%d+):([01])$")
                    if day then
                        XS.restoredDaily = { day = day, id = id, prog = tonumber(prog) or 0, done = (dn == "1") }
                    end
                elseif k:sub(1, 6) == "skill_" and n then
                    local sdef = K.SKILL_BY_ID[k:sub(7)]
                    if sdef then K.skillRanks[sdef.id] = math.max(0, math.min(sdef.max, math.floor(n))) end
                end
            end
        end
        K.logInfo(string.format("Progression restored: level %d, %d points", levelFromPoints(questPoints), questPoints))
    end
    knownLevel = levelFromPoints(questPoints)
    K.playerLevel = knownLevel
    -- A damaged / edited file can't give more skill ranks than points earned.
    local spent = 0
    for _, s in ipairs(K.SKILLS) do spent = spent + (K.skillRanks[s.id] or 0) end
    if spent > knownLevel - 1 then K.skillRanks = {} end
end

-- force = true : write now (quest completed, script unload).
-- Otherwise: at most one check every 5 s, written only if something changed.
function K.saveQuestProgress(force)
    if progressBroken or progressPath == nil or #slots == 0 then return end
    local now = 0
    pcall(function() now = Time.GetEpocheMs() end)
    if not force and now - lastSaveMs < 5000 then return end
    lastSaveMs = now
    local text = serializeProgress()
    if text == lastSavedText then return end
    if fileWrite(progressPath, text) then
        lastSavedText = text
        progressFailures = 0
    else
        progressFailures = progressFailures + 1
        if progressFailures >= 3 then
            progressBroken = true
            K.logWarn("could not write the quest progress file: saving disabled for this session")
        end
    end
end

function questSummary()
    local level, into, need = levelFromPoints(questPoints)
    return questPoints, level, questsCompleted, into, need, titleForLevel(level)
end

function K.questLifetimeText()
    local throws = lifetime("vehiclesThrown") + lifetime("npcsThrown") + lifetime("objectsThrown")
    return string.format("All-time: %d throws, %d punches, %d grabs, %d XP from actions",
        throws, lifetime("punchesLanded"), lifetime("grabs"), lifetime("xpEarned"))
end

-- ============================================================
--  HULK PROGRESSION SYSTEM (HPS)
--  XP earned by what you do, poured into the SAME points / level bar as the
--  quests. Values are indicative: tune them in K.XP while testing.
--   * Actions : vehicle / NPC / object throw, super punch.
--   * Impacts : a launched entity (thrown or punched) that touches an NPC or a
--     vehicle: Direct Impact, Combo Bonus (vehicle hits NPC), Multi Hit,
--     Chain Reaction, Airborne Hit, Heavy Impact.
--   * Rampage : successful actions chained inside a time window raise an XP
--     multiplier and give a flat bonus at x3 / x5 / x10.
--  Real players (and vehicles with a player inside) never give XP.
-- ============================================================
K.XP = {
    throwVehicle = 25, throwNpc = 15, throwObject = 10,
    superPunch   = 10,
    directImpact = { vehicle = 30, npc = 15, object = 15 },  -- by launched entity kind
    comboBonus   = 20,                  -- thrown vehicle that hits an NPC
    multiHit     = { 15, 25, 35, 50 },  -- 2nd, 3rd, 4th, 5th+ target of one launch
    chainReaction = 25,                 -- further vehicle hit by the same launch
    airborne     = 15,                  -- target was in the air / already launched
    heavy        = 20,                  -- heavy vehicle impact (once per throw)
    rampageWindowMs = 5000,
    -- { actions in a row, flat bonus XP, XP multiplier from then on }
    rampageTiers = { { 3, 30, 1.25 }, { 5, 75, 1.5 }, { 10, 200, 2.0 } },
    heavyClasses = { [10] = true, [11] = true, [19] = true, [20] = true },  -- industrial, utility, military, commercial
    hitSpeed = 10.0,     -- min speed (m/s) for a contact to count as an impact
    trackMs  = 6000,     -- max flight time followed after a launch
    scanMs   = 60,       -- delay between two impact scans of one projectile
    -- contact distance (m) between the launched entity and a ped / vehicle target
    hitRadius = { vehicle = { ped = 3.6, veh = 4.8 }, npc = { ped = 2.2, veh = 3.4 }, object = { ped = 2.4, veh = 3.5 } },
    feedMs = 2600, summaryMs = 3800,
}


-- Anti-farm: repeating the same entity (launching it again, or hitting the
-- same target again) within 90 s pays less each time (K.FARM_STEPS).
-- (state lives in XS.farm: [entity] = { n = repeats, t = last time })
local function farmMult(entity, now)
    local h = XS.farm[entity]
    if h and now - h.t < 90000 then
        h.n = h.n + 1
    else
        h = { n = 1 }
        XS.farm[entity] = h
    end
    h.t = now
    return K.FARM_STEPS[math.min(h.n, #K.FARM_STEPS)]
end

local function rampageMult()
    local m = 1.0
    for _, t in ipairs(K.XP.rampageTiers) do
        if XS.rampage.count >= t[1] then m = t[3] end
    end
    return m
end

-- Adds XP to the shared points pool. flat = true ignores the rampage multiplier.
local function giveXP(action, base, label, color, flat, mult)
    if not cfg.xp or base <= 0 then return 0 end
    mult = mult or 1.0
    local amount
    if flat then
        amount = math.floor(base)
    else
        amount = math.max(1, math.floor(base * rampageMult() * cfg.xpBonus * mult + 0.5))
        if mult < 0.99 then label = label .. " REPEAT" end
    end
    questPoints = math.min(MAX_POINTS, questPoints + amount)
    stats.xpEarned = stats.xpEarned + amount
    XS.feed[#XS.feed + 1] = { text = label, xp = amount, t = Time.GetEpocheMs(), c = color or XS.gold }
    if #XS.feed > 7 then table.remove(XS.feed, 1) end
    if action then
        action.total = action.total + amount
        action.lines = action.lines + 1
    end
    checkLevelUp()
    return amount
end

-- One more successful action in the chain; announces the rampage tiers.
local function rampageStep(now)
    if XS.rampage.count > 0 and now - XS.rampage.lastMs > K.XP.rampageWindowMs then XS.rampage.count = 0 end
    XS.rampage.count = XS.rampage.count + 1
    XS.rampage.lastMs = now
    if XS.rampage.count > stats.bestRampage then stats.bestRampage = XS.rampage.count end
    for _, t in ipairs(K.XP.rampageTiers) do
        if XS.rampage.count == t[1] then
            giveXP(nil, t[2], "RAMPAGE X" .. t[1], XS.orange, true)
            Common.toast("RAMPAGE x" .. t[1], string.format("XP x%.2f  +%d bonus", t[3], t[2]), 2500)
            playSound(K.SND.rageMax)
        end
    end
end

-- When the flight of a launched entity ends, show the summary card if the
-- action produced more than one reward (throw + impact, ...).
local function closeAction(a, now)
    if a.closed then return end
    a.closed = true
    if a.lines >= 2 then
        local combo = 1 + a.impacts
        XS.summary = { total = a.total, combo = combo, t = now }
        if combo > stats.bestCombo then stats.bestCombo = combo end
    end
end

local function trackProjectile(entity, kind, action, now)
    for i = #XS.proj, 1, -1 do
        if XS.proj[i].entity == entity then
            closeAction(XS.proj[i].action, now)
            table.remove(XS.proj, i)
        end
    end
    if #XS.proj >= 8 then
        closeAction(XS.proj[1].action, now)
        table.remove(XS.proj, 1)
    end
    local heavy = false
    if kind == K.KIND_VEHICLE then
        local ok, cls = pcall(Natives.InvokeInt, K.NATIVE.GET_VEHICLE_CLASS, entity)
        heavy = ok and K.XP.heavyClasses[cls] == true
    end
    XS.launched[entity] = now + 4000
    XS.proj[#XS.proj + 1] = {
        entity = entity, kind = kind, action = action, t0 = now, hits = {}, nHits = 0,
        sawFast = false, nextScan = 0, scanN = 0, heavy = heavy, heavyPaid = false,
    }
end

-- The launched entity just touched `target` (tkind = npc / vehicle).
local function registerHit(p, target, tkind, now)
    p.hits[target] = true
    local a, X = p.action, K.XP
    local n = p.nHits
    p.nHits = n + 1
    a.impacts = a.impacts + 1
    local fm = (a.farm or 1.0) * farmMult(-target, now)   -- negative key: "was hit" history, separate from "was launched"
    if fm >= 0.5 then rampageStep(now) end

    if n == 0 then
        giveXP(a, X.directImpact[p.kind] or 15, "DIRECT IMPACT", XS.red, nil, fm)
        if p.kind == K.KIND_VEHICLE and tkind == K.KIND_NPC then
            giveXP(a, X.comboBonus, "COMBO BONUS", XS.cyan, nil, fm)
        end
    elseif tkind == K.KIND_NPC then
        giveXP(a, X.multiHit[math.min(n, #X.multiHit)], "MULTI HIT X" .. (n + 1), XS.cyan, nil, fm)
    else
        giveXP(a, X.chainReaction, "CHAIN REACTION", XS.cyan, nil, fm)
    end

    local airborne = (XS.launched[target] or 0) > now
    if not airborne then
        local ok, inAir = pcall(Natives.InvokeBool, K.NATIVE.IS_ENTITY_IN_AIR, target)
        airborne = ok and inAir == true
    end
    if airborne then giveXP(a, X.airborne, "AIRBORNE HIT", XS.green, nil, fm) end
    if p.heavy and not p.heavyPaid then
        p.heavyPaid = true
        giveXP(a, X.heavy, "HEAVY IMPACT", XS.orange, nil, fm)
    end
end

-- Looks for NPCs / vehicles touching the launched entity right now.
local function scanHits(p, ped, ex, ey, ez, now)
    local R = K.XP.hitRadius[p.kind] or K.XP.hitRadius.object
    p.scanN = p.scanN + 1

    for _ = 1, 3 do
        local box = R.ped + 0.5
        local npc = Natives.InvokeInt(K.NATIVE.GET_RANDOM_PED_AT_COORD, ex, ey, ez, box, box, box, -1)
        if npc ~= nil and npc ~= 0 and npc ~= ped and npc ~= K.PG.pet and npc ~= p.entity and not p.hits[npc] and entityOk(npc)
            and not Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, npc)
            and not Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, npc, false)
            and vehicleOfPed(npc) == nil then
            local nx, ny, nz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, npc, true)
            if distSq(nx, ny, nz, ex, ey, ez) <= R.ped * R.ped then
                registerHit(p, npc, K.KIND_NPC, now)
            end
        end
    end

    -- GET_CLOSEST_VEHICLE can't exclude the projectile itself, so vehicles are
    -- sampled around it (offset points) instead of at its centre.
    if p.scanN % 2 == 0 then
        local flags, off = K.VEHICLE_SEARCH_FLAGS[1], 4.5
        for _, o in ipairs({ { off, 0 }, { -off, 0 }, { 0, off }, { 0, -off } }) do
            local v = Natives.InvokeInt(K.NATIVE.GET_CLOSEST_VEHICLE, ex + o[1], ey + o[2], ez, 3.0, 0, flags)
            if v ~= nil and v ~= 0 and v ~= p.entity and not p.hits[v] and entityOk(v) then
                local _, hasPlayer = vehicleOccupants(v)
                if not hasPlayer then
                    local vx, vy, vz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, v, true)
                    if distSq(vx, vy, vz, ex, ey, ez) <= R.veh * R.veh then
                        registerHit(p, v, K.KIND_VEHICLE, now)
                    end
                end
            end
        end
    end
end

-- Called every tick (from updateQuests): follows the launched entities,
-- expires the rampage and the on-screen feed.
local function updateXp(now)
    if XS.rampage.count > 0 and now - XS.rampage.lastMs > K.XP.rampageWindowMs then XS.rampage.count = 0 end
    for i = #XS.feed, 1, -1 do
        if now - XS.feed[i].t > K.XP.feedMs then table.remove(XS.feed, i) end
    end
    if XS.summary and now - XS.summary.t > K.XP.summaryMs then XS.summary = nil end
    for e, h in pairs(XS.farm) do
        if now - h.t > 90000 then XS.farm[e] = nil end
    end
    for e, untilMs in pairs(XS.launched) do
        if untilMs < now then XS.launched[e] = nil end
    end
    if #XS.proj == 0 then return end

    local ped = getPed()
    for i = #XS.proj, 1, -1 do
        local p = XS.proj[i]
        local age = now - p.t0
        local finished = false
        if not entityOk(p.entity) or age > K.XP.trackMs then
            finished = true
        else
            local vx, vy, vz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_VELOCITY, p.entity)
            local speed = math.sqrt(vx * vx + vy * vy + vz * vz)
            if speed >= K.XP.hitSpeed then p.sawFast = true end
            if p.sawFast and speed < 4.0 and age > 600 then
                finished = true                                  -- landed
            elseif not p.sawFast and age > 1500 then
                finished = true                                  -- never really flew
            elseif speed >= K.XP.hitSpeed and now >= p.nextScan then
                p.nextScan = now + K.XP.scanMs
                local ex, ey, ez = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, p.entity, true)
                scanHits(p, ped, ex, ey, ez, now)
            end
        end
        if finished then
            closeAction(p.action, now)
            table.remove(XS.proj, i)
        end
    end
end

-- Public API, called from the throw / punch code. Errors are contained so the
-- XP layer can never break a throw.
local function xpGuard(name, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok and K.xpLastErr ~= tostring(err) then
            K.xpLastErr = tostring(err)
            K.logError("XP error in " .. name .. ": " .. K.xpLastErr)
        end
    end
end

K.xpThrow = xpGuard("throw", function(entity, kind)
    if not cfg.xp then return end
    local now, X = Time.GetEpocheMs(), K.XP
    local fm = farmMult(entity, now)
    local action = { total = 0, lines = 0, impacts = 0, closed = false, farm = fm }
    if fm >= 0.5 then rampageStep(now) end
    if kind == K.KIND_VEHICLE then
        giveXP(action, X.throwVehicle, "VEHICLE THROW", XS.gold, nil, fm)
    elseif kind == K.KIND_NPC then
        giveXP(action, X.throwNpc, "NPC THROW", XS.gold, nil, fm)
    else
        giveXP(action, X.throwObject, "OBJECT THROW", XS.gold, nil, fm)
    end
    trackProjectile(entity, kind, action, now)
end)

K.xpPunch = xpGuard("punch", function(entity, kind)
    if not cfg.xp then return end
    local now = Time.GetEpocheMs()
    local fm = farmMult(entity, now)
    local action = { total = 0, lines = 0, impacts = 0, closed = false, farm = fm }
    if fm >= 0.5 then rampageStep(now) end
    giveXP(action, K.XP.superPunch, "SUPER PUNCH", XS.green, nil, fm)
    trackProjectile(entity, kind, action, now)
end)

function K.xpStatusText()
    if not cfg.xp then return "XP: off" end
    local now = Time.GetEpocheMs()
    if XS.rampage.count >= 2 and now - XS.rampage.lastMs <= K.XP.rampageWindowMs then
        return string.format("Rampage x%d  (XP x%.2f)", XS.rampage.count, rampageMult())
    end
    return "Rampage: none  (chain actions within 5 s)"
end

-- ---------- skill tree ----------
-- One skill point per level gained (level - 1 in total). Effects are applied
-- in refreshConfig (grab range, charge time, rage gain, throw power, XP).
function K.skillPointsFree()
    local spent = 0
    for _, s in ipairs(K.SKILLS) do spent = spent + (K.skillRanks[s.id] or 0) end
    return levelFromPoints(questPoints) - 1 - spent, spent
end

function K.upgradeSkill(id)
    local sdef = K.SKILL_BY_ID[id]
    if not sdef then return end
    local rank = K.skillRanks[id] or 0
    if rank >= sdef.max then
        Common.toast("Hulk Mode", sdef.name .. " is already at max rank.", 2500)
        return
    end
    if K.skillPointsFree() <= 0 then
        Common.toast("Hulk Mode", "No skill point available: gain a level first.", 2500)
        return
    end
    K.skillRanks[id] = rank + 1
    Common.toast("Skill upgraded", string.format("%s rank %d/%d", sdef.name, rank + 1, sdef.max), 2500)
    playSound(K.SND.grab)
    K.saveQuestProgress(true)
end

function K.resetSkills()
    K.skillRanks = {}
    Common.toast("Hulk Mode", "Skills reset: all points refunded.", 2500)
    K.saveQuestProgress(true)
end

function K.skillLine(id)
    local sdef = K.SKILL_BY_ID[id]
    return string.format("%s: rank %d/%d  (%s per rank)", sdef.name, K.skillRanks[id] or 0, sdef.max, sdef.per)
end

-- ---------- daily challenge ----------
-- One bonus quest per day (double reward), chosen from the quests that fit
-- the current level. It is saved with its progress and replaced at the next day.
local function dayKey()
    local ok, s = pcall(os.date, "%Y%m%d")
    if ok and type(s) == "string" and s:match("^%d+$") then return s end
    return tostring(math.floor(Time.GetEpocheMs() / 86400000))
end

local function pickDaily(level, day)
    local pool = {}
    for _, d in ipairs(QUEST_DEFS) do
        if d.minLevel <= level and d.minLevel >= level - 6 then pool[#pool + 1] = d end
    end
    if #pool == 0 then
        for _, d in ipairs(QUEST_DEFS) do
            if d.minLevel <= level then pool[#pool + 1] = d end
        end
    end
    if #pool == 0 then return QUEST_DEFS[1] end
    return pool[(day * 7919) % #pool + 1]
end

local function ensureDaily(now)
    if XS.daily ~= nil and now - XS.lastDayMs < 20000 then return end
    XS.lastDayMs = now
    local key = dayKey()
    if XS.daily ~= nil and XS.daily.day == key then return end
    local r = XS.restoredDaily
    XS.restoredDaily = nil
    local rd = r and r.day == key and QUEST_BY_ID[r.id] or nil
    if rd then
        XS.daily = { def = rd, day = key, done = r.done, prog = r.prog,
                  base = statValue(rd.stat) - r.prog }
    else
        local d = pickDaily(levelFromPoints(questPoints), tonumber(key) or 0)
        XS.daily = { def = d, day = key, done = false, prog = 0, base = statValue(d.stat) }
    end
end

local function updateDaily(now)
    ensureDaily(now)
    local q = XS.daily
    if q == nil or q.done then return end
    if not cfg.quests then
        q.base = statValue(q.def.stat) - q.prog
        return
    end
    q.prog = math.max(0, statValue(q.def.stat) - q.base)
    if q.prog >= q.def.target then
        q.prog = q.def.target
        q.done = true
        local reward = q.def.reward * 2
        questPoints = math.min(MAX_POINTS, questPoints + reward)
        questsCompleted = questsCompleted + 1
        playSound(K.SND.rageMax)
        Common.toast("Daily challenge complete", string.format("%s  +%d pts (x2)", questLabel(q.def), reward), 4000)
        checkLevelUp()
        K.saveQuestProgress(true)
    end
end

-- ---------- per-tick update ----------
-- Called every tick from the main loop (natives are safe here).
function updateQuests(now)
    ensureSlots()
    K.playerLevel = levelFromPoints(questPoints)
    updateXp(now)
    updateDaily(now)

    -- F8: quick hide / show.
    local down = Utils.IsKeyDown(HIDE_KEY)
    if down and not hideKeyWasDown and not (GUI.IsOpen() or inputBlocked()) then
        questHidden = not questHidden
    end
    hideKeyWasDown = down

    -- Do not draw over the pause menu (checked here: natives are not safe in the render callback).
    local okp, paused = pcall(Natives.InvokeBool, K.NATIVE.IS_PAUSE_MENU_ACTIVE)
    questPaused = okp and paused or false

    for i = 1, #slots do
        local q = slots[i]
        if q.doneAt == nil then
            if not cfg.quests then
                -- Popup removed: freeze the progress so nothing completes in the background.
                q.base = statValue(q.def.stat) - q.prog
            else
                q.prog = math.max(0, statValue(q.def.stat) - q.base)
                if q.prog >= q.def.target then
                    q.prog = q.def.target
                    q.doneAt = now
                    questPoints = math.min(MAX_POINTS, questPoints + q.def.reward)
                    questsCompleted = questsCompleted + 1
                    playSound(K.SND.rageMax)
                    Common.toast("Quest complete", string.format("%s  +%d pts", questLabel(q.def), q.def.reward), 3000)

                    checkLevelUp()
                    K.saveQuestProgress(true)
                end
            end
        elseif now - q.doneAt > DONE_SHOW_MS then
            local level = levelFromPoints(questPoints)
            local nd = pickQuest(usedStatsExcept(i), q.def, level)
            slots[i] = buildSlot(nd, 0)
        end
    end

    K.saveQuestProgress(false)
end

loadProgress()

-- ---------- tiny stroke font: each glyph = list of polylines (flat x,y pairs),
-- on a grid 2 wide x 4 tall. Only the characters used by the panel exist. ----------
local GLYPHS = {
    A = { {0,4,0,1,1,0,2,1,2,4}, {0,2,2,2} },
    B = { {0,4,0,0,1,0,2,1,1,2,0,2}, {1,2,2,3,1,4,0,4} },
    C = { {2,0,0,0,0,4,2,4} },
    D = { {0,0,0,4,1,4,2,3,2,1,1,0,0,0} },
    E = { {2,0,0,0,0,4,2,4}, {0,2,1.5,2} },
    F = { {2,0,0,0,0,4}, {0,2,1.5,2} },
    G = { {2,0,0,0,0,4,2,4,2,2,1,2} },
    H = { {0,0,0,4}, {2,0,2,4}, {0,2,2,2} },
    I = { {0,0,2,0}, {1,0,1,4}, {0,4,2,4} },
    J = { {2,0,2,4,0,4,0,3} },
    K = { {0,0,0,4}, {2,0,0,2,2,4} },
    L = { {0,0,0,4,2,4} },
    M = { {0,4,0,0,1,2,2,0,2,4} },
    N = { {0,4,0,0,2,4,2,0} },
    O = { {0,0,2,0,2,4,0,4,0,0} },
    P = { {0,4,0,0,2,0,2,2,0,2} },
    Q = { {0,0,2,0,2,4,0,4,0,0}, {1,3,2,4} },
    R = { {0,4,0,0,2,0,2,2,0,2}, {1,2,2,4} },
    S = { {2,0,0,0,0,2,2,2,2,4,0,4} },
    T = { {0,0,2,0}, {1,0,1,4} },
    U = { {0,0,0,4,2,4,2,0} },
    V = { {0,0,1,4,2,0} },
    W = { {0,0,0,4,1,2,2,4,2,0} },
    X = { {0,0,2,4}, {2,0,0,4} },
    Y = { {0,0,1,2,2,0}, {1,2,1,4} },
    Z = { {0,0,2,0,0,4,2,4} },
    ["0"] = { {0,0,2,0,2,4,0,4,0,0}, {0,4,2,0} },
    ["1"] = { {0,1,1,0,1,4}, {0,4,2,4} },
    ["2"] = { {0,0,2,0,2,2,0,2,0,4,2,4} },
    ["3"] = { {0,0,2,0,2,4,0,4}, {0,2,2,2} },
    ["4"] = { {0,0,0,2,2,2}, {2,0,2,4} },
    ["5"] = { {2,0,0,0,0,2,2,2,2,4,0,4} },
    ["6"] = { {2,0,0,0,0,4,2,4,2,2,0,2} },
    ["7"] = { {0,0,2,0,1,4} },
    ["8"] = { {0,0,2,0,2,4,0,4,0,0}, {0,2,2,2} },
    ["9"] = { {2,2,0,2,0,0,2,0,2,4,0,4} },
    ["+"] = { {1,1,1,3}, {0,2,2,2} },
    ["-"] = { {0,2,2,2} },
    ["/"] = { {2,0,0,4} },
    [":"] = { {1,0.8,1,1.2}, {1,2.8,1,3.2} },
    ["."] = { {1,3.6,1,4} },
    ["!"] = { {1,0,1,2.4}, {1,3.6,1,4} },
}

local ADVANCE = 3.4   -- horizontal advance per character, in glyph units

local function textWidth(str, sc)
    return #str * ADVANCE * sc - (ADVANCE - 2.0) * sc
end

local function drawText(str, x, y, sc, r, g, b, a, thick)
    str = string.upper(str)
    local cx = x
    for i = 1, #str do
        local gl = GLYPHS[string.sub(str, i, i)]
        if gl then
            for s = 1, #gl do
                local pts = gl[s]
                for k = 1, #pts - 3, 2 do
                    ImGui.AddLine(cx + pts[k] * sc, y + pts[k + 1] * sc,
                                  cx + pts[k + 2] * sc, y + pts[k + 3] * sc, r, g, b, a, thick)
                end
            end
        end
        cx = cx + ADVANCE * sc
    end
end

local function drawQuestPanel()
    local w, h = ImGui.GetDisplaySize()
    local u = h / 1080.0
    local now = Time.GetEpocheMs()

    local x0, y0 = 24 * u, 330 * u
    local pw, pad = 340 * u, 14 * u
    local headH, rowH, footH = 40 * u, 60 * u, 46 * u
    local dailyH = XS.daily and (74 * u) or 0
    local ph = headH + #slots * rowH + dailyH + footH
    local th = math.max(1.2, 1.6 * u)          -- text stroke thickness
    local sc, scSmall = 2.7 * u, 2.1 * u

    -- Background + accent lines.
    ImGui.AddLine(x0, y0 + ph / 2.0, x0 + pw, y0 + ph / 2.0, 6, 14, 9, 175, ph)
    ImGui.AddLine(x0, y0, x0 + pw, y0, 40, 255, 95, 230, 2.0)
    ImGui.AddLine(x0, y0 + ph, x0 + pw, y0 + ph, 40, 255, 95, 120, 1.5)
    ImGui.AddLine(x0, y0, x0, y0 + ph, 40, 255, 95, 230, 3.0)

    -- Header: title + points.
    drawText("HULK QUESTS", x0 + pad, y0 + 12 * u, sc, 130, 255, 160, 255, th)
    local ptsText = string.format("%d PTS", questPoints)
    drawText(ptsText, x0 + pw - pad - textWidth(ptsText, sc), y0 + 12 * u, sc, 255, 205, 70, 255, th)
    ImGui.AddLine(x0 + pad, y0 + headH - 4 * u, x0 + pw - pad, y0 + headH - 4 * u, 40, 255, 95, 90, 1.0)

    -- Quest rows.
    local barX0, barX1 = x0 + pad, x0 + pw - pad - 70 * u
    for i = 1, #slots do
        local q = slots[i]
        local ry = y0 + headH + (i - 1) * rowH
        local done = q.doneAt ~= nil
        local frac = math.min(1.0, q.prog / q.def.target)

        local tr, tg, tb = 235, 242, 238
        if done then tr, tg, tb = 120, 255, 150 end
        drawText(questLabel(q.def), x0 + pad, ry + 6 * u, sc, tr, tg, tb, 255, th)

        -- Reward colour = quest tier (gold / orange / red).
        local rr, rg, rb = 255, 205, 70
        if q.def.minLevel >= 7 then rr, rg, rb = 255, 90, 110
        elseif q.def.minLevel >= 3 then rr, rg, rb = 255, 150, 60 end
        local rewardText = string.format("+%d", q.def.reward)
        drawText(rewardText, x0 + pw - pad - textWidth(rewardText, sc), ry + 6 * u, sc, rr, rg, rb, 255, th)

        local by = ry + 40 * u
        ImGui.AddLine(barX0, by, barX1, by, 0, 0, 0, 170, 8 * u)
        if frac > 0.0 then
            ImGui.AddLine(barX0, by, barX0 + (barX1 - barX0) * frac, by, 40, 255, 95, 235, 5 * u)
        end

        if done then
            local flash = math.floor(170 + 85 * math.sin(now / 110.0))
            local dt = "DONE!"
            drawText(dt, x0 + pw - pad - textWidth(dt, scSmall), by - 5 * u, scSmall, 120, 255, 150, flash, th)
        else
            local cnt = string.format("%d/%d", q.prog, q.def.target)
            drawText(cnt, x0 + pw - pad - textWidth(cnt, scSmall), by - 5 * u, scSmall, 200, 215, 205, 255, th)
        end
    end

    -- Daily challenge row (cyan, double reward).
    if XS.daily then
        local q = XS.daily
        local ry = y0 + headH + #slots * rowH
        local frac = math.min(1.0, q.prog / q.def.target)
        ImGui.AddLine(x0 + pad, ry + 2 * u, x0 + pw - pad, ry + 2 * u, 80, 220, 255, 90, 1.0)
        drawText("DAILY X2", x0 + pad, ry + 8 * u, scSmall, 80, 220, 255, 255, th)
        local rewardText = string.format("+%d", q.def.reward * 2)
        drawText(rewardText, x0 + pw - pad - textWidth(rewardText, scSmall), ry + 8 * u, scSmall, 80, 220, 255, 255, th)
        local lr, lg, lb = 235, 242, 238
        if q.done then lr, lg, lb = 120, 255, 150 end
        drawText(questLabel(q.def), x0 + pad, ry + 24 * u, sc, lr, lg, lb, 255, th)
        local by = ry + 56 * u
        ImGui.AddLine(barX0, by, barX1, by, 0, 0, 0, 170, 8 * u)
        if frac > 0.0 then
            ImGui.AddLine(barX0, by, barX0 + (barX1 - barX0) * frac, by, 80, 220, 255, 235, 5 * u)
        end
        if q.done then
            local dt = "DONE!"
            drawText(dt, x0 + pw - pad - textWidth(dt, scSmall), by - 5 * u, scSmall, 120, 255, 150, 255, th)
        else
            local cnt = string.format("%d/%d", q.prog, q.def.target)
            drawText(cnt, x0 + pw - pad - textWidth(cnt, scSmall), by - 5 * u, scSmall, 200, 215, 205, 255, th)
        end
    end

    -- Footer: level + title + hint, then the progress bar to the next level.
    local _, lvl, _, into, need, title = questSummary()
    local fy = y0 + headH + #slots * rowH + dailyH + 8 * u
    drawText(string.format("LV %d %s", lvl, title), x0 + pad, fy, scSmall, 150, 190, 160, 230, th)
    local hint = "F8 HIDE"
    drawText(hint, x0 + pw - pad - textWidth(hint, scSmall), fy, scSmall, 150, 190, 160, 230, th)
    local lby = fy + 26 * u
    ImGui.AddLine(x0 + pad, lby, x0 + pw - pad, lby, 0, 0, 0, 170, 6 * u)
    local lf = need > 0 and math.max(0.0, math.min(1.0, into / need)) or 0.0
    if lf > 0.0 then
        ImGui.AddLine(x0 + pad, lby, x0 + pad + (pw - 2 * pad) * lf, lby, 255, 205, 70, 235, 4 * u)
    end
    return ph
end

-- Text with a dark offset copy underneath so it stays readable on any background.
local function shadowText(str, x, y, sc, r, g, b, a, th)
    drawText(str, x + 1.2, y + 1.2, sc, 0, 0, 0, math.floor(a * 0.65), th + 1.0)
    drawText(str, x, y, sc, r, g, b, a, th)
end

-- XP feed under the quest panel: rampage header, action summary (total +
-- combo), then the latest XP lines (newest first).
local function drawXpFeed(x0, y, u)
    local now = Time.GetEpocheMs()
    local X = K.XP
    local pw, pad = 340 * u, 14 * u
    local th = math.max(1.2, 1.6 * u)
    local sc = 2.1 * u

    if XS.rampage.count >= 2 and now - XS.rampage.lastMs <= X.rampageWindowMs then
        local frac = 1.0 - (now - XS.rampage.lastMs) / X.rampageWindowMs
        local cr, cg, cb = 220, 230, 225
        if XS.rampage.count >= 10 then cr, cg, cb = 255, 70, 70
        elseif XS.rampage.count >= 5 then cr, cg, cb = 255, 140, 40
        elseif XS.rampage.count >= 3 then cr, cg, cb = 255, 205, 70 end
        local h = 52 * u
        ImGui.AddLine(x0, y + h / 2.0, x0 + pw, y + h / 2.0, 6, 14, 9, 150, h)
        ImGui.AddLine(x0, y, x0, y + h, cr, cg, cb, 230, 3.0)
        shadowText(string.format("RAMPAGE X%d", XS.rampage.count), x0 + pad, y + 8 * u, 2.7 * u, cr, cg, cb, 255, th)
        local mt = string.format("XP X%.2f", rampageMult())
        shadowText(mt, x0 + pw - pad - textWidth(mt, sc), y + 10 * u, sc, 255, 205, 70, 255, th)
        local by = y + h - 10 * u
        ImGui.AddLine(x0 + pad, by, x0 + pw - pad, by, 0, 0, 0, 170, 6 * u)
        ImGui.AddLine(x0 + pad, by, x0 + pad + (pw - 2 * pad) * frac, by, cr, cg, cb, 235, 4 * u)
        y = y + h + 6 * u
    end

    if XS.summary then
        local age = now - XS.summary.t
        local fade = 1.0 - clamp((age - (X.summaryMs - 700)) / 700.0, 0.0, 1.0)
        local a = math.floor(255 * fade)
        local h = 64 * u
        ImGui.AddLine(x0, y + h / 2.0, x0 + pw, y + h / 2.0, 6, 14, 9, math.floor(160 * fade), h)
        ImGui.AddLine(x0, y, x0, y + h, 80, 220, 255, a, 3.0)
        shadowText("ACTION TOTAL", x0 + pad, y + 8 * u, sc, 150, 190, 160, a, th)
        local ct = string.format("COMBO X%d", XS.summary.combo)
        shadowText(ct, x0 + pw - pad - textWidth(ct, sc), y + 8 * u, sc, 80, 220, 255, a, th)
        shadowText(string.format("+%d XP", XS.summary.total), x0 + pad, y + 30 * u, 3.6 * u, 255, 205, 70, a, th * 1.2)
        y = y + h + 6 * u
    end

    for i = #XS.feed, 1, -1 do
        local e = XS.feed[i]
        local age = now - e.t
        local fade = 1.0 - clamp((age - (X.feedMs - 700)) / 700.0, 0.0, 1.0)
        local a = math.floor(255 * fade)
        local slide = (1.0 - clamp(age / 180.0, 0.0, 1.0)) * 24 * u
        shadowText(string.format("+%d", e.xp), x0 + pad - slide, y, sc, e.c[1], e.c[2], e.c[3], a, th)
        shadowText(e.text, x0 + pad + 52 * u - slide, y, sc, 235, 242, 238, a, th)
        y = y + 24 * u
    end
end

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if questPaused then return end
    local panelVisible = cfg.quests and not questHidden and #slots > 0
    if not panelVisible and not cfg.xp then return end
    local ok, err = pcall(function()
        local _, h = ImGui.GetDisplaySize()
        local u = h / 1080.0
        local y = 330 * u
        if panelVisible then
            y = y + (drawQuestPanel() or 0) + 12 * u
        end
        if cfg.xp then drawXpFeed(24 * u, y, u) end
    end)
    if not ok and tostring(err) ~= lastQuestDrawError then
        lastQuestDrawError = tostring(err)
        K.logError("drawing the quest panel: " .. lastQuestDrawError)
    end
end)
end -- nested: quests


-- ============================================================
--  PLAYGROUND : Companion + Bodyguard
--  The companion is created locally (not networked): only you see it.
--  Bodyguard: it fights NPCs that attack you (fists / teeth, or a weapon for
--  human companions). Real players and the police are NEVER targeted.
--  State lives in K.PG (no new top-level locals).
-- ============================================================
-- VERIFY: natives not used elsewhere in the script.
for name, hash in pairs({
    TASK_FOLLOW_TO_OFFSET_OF_ENTITY = 0x304AE42E357B8C7E,
    REQUEST_MODEL                   = 0x963D27A58DF860AC,
    HAS_MODEL_LOADED                = 0x98A4EB5D89A0C952,
    SET_MODEL_AS_NO_LONGER_NEEDED   = 0xE532F5D78798DAAB,
    CREATE_PED                      = 0xD49F9B0955C367DE,
    SET_ENTITY_INVINCIBLE           = 0x3882114BDE571AD4,
    DELETE_ENTITY                   = 0xAE3CBE5BF394C9C9,
    IS_PED_IN_COMBAT                = 0x4859F1FC66A6278E,
    TASK_COMBAT_PED                 = 0xF166E48407BAC484,
    GIVE_WEAPON_TO_PED              = 0xBF0FD6E56C964FCB,
    SET_CURRENT_PED_WEAPON          = 0xADF692B254977C0C,
    REMOVE_ALL_PED_WEAPONS          = 0xF25DF915FA38C5F3,
    SET_PED_COMBAT_ATTRIBUTES       = 0x9F7794730795E019,
    SET_PED_COMBAT_ABILITY          = 0xC7622C0D36B2FDA8,
    SET_PED_ACCURACY                = 0x7AEFB85C1D49DEB6,
    GET_PED_TYPE                    = 0xFF059E1E4C01E63C,
    -- Bodyguard detection (all VERIFY: a wrong hash only logs once and the check is skipped).
    GET_PED_NEARBY_PEDS             = 0x23F8F5FC7E8C4A6B,
    HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY  = 0xC86D67D52A707CF8,
    HAS_ENTITY_BEEN_DAMAGED_BY_ANY_PED = 0x9934E9C42D52D87E,
    CLEAR_ENTITY_LAST_DAMAGE_ENTITY    = 0xA72CD9CA74A5ECBA,
    GET_PED_ARMOUR                  = 0x9483AF821605B1D8,
    GET_MELEE_TARGET_FOR_PED        = 0x18A3E9EE1297FD39,
    IS_PED_SHOOTING                 = 0x34616828CD07F1A1,
    -- Monkey weapons + "never fights the player" (all VERIFY).
    CREATE_OBJECT                   = 0x509D5878EB39E842,
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS = 0x867654CBC7606F2C,
    GET_PED_RELATIONSHIP_GROUP_HASH = 0x7DBDD04862D95F04,
    SET_PED_RELATIONSHIP_GROUP_HASH = 0xC80A74AC829DDD92,
    SET_CAN_ATTACK_FRIENDLY         = 0xB3B1CB349FF9C75D,
}) do
    if K.NATIVE[name] == nil then K.NATIVE[name] = hash end
end

function K.PG.removePet()
    local pet = K.PG.pet
    K.PG.pet, K.PG.petFollowing, K.PG.petDist = nil, false, nil
    K.PG.guardTarget, K.PG.loadoutKey, K.PG.drawn = nil, nil, false
    K.PG.propWanted = false
    K.PG.removeProp()
    if pet ~= nil and entityOk(pet) then
        K.PG.delBuf = K.PG.delBuf or Memory.Alloc(8)
        if memWriteInt(K.PG.delBuf, pet) then
            Natives.InvokeVoid(K.NATIVE.DELETE_ENTITY, K.PG.delBuf)
        end
    end
end

-- Weapon in the hand (draw = true) or put away (draw = false). Humans only.
-- Can this companion hold a weapon? Humans natively; the chimp through the script
-- (a weapon prop in its hands, bullets fired by the script: see GUNS).
function K.PG.canUseWeapon(petType)
    local info = K.PG.PETS[petType]
    return info ~= nil and (info[3] == 4 or info[4] == true)
end

function K.PG.removeProp()
    local pg = K.PG
    local obj = pg.prop
    pg.prop, pg.propKey = nil, nil
    if obj ~= nil and entityOk(obj) then
        pg.delBuf = pg.delBuf or Memory.Alloc(8)
        if memWriteInt(pg.delBuf, obj) then
            Natives.InvokeVoid(K.NATIVE.DELETE_ENTITY, pg.delBuf)
        end
    end
end

-- Resolves the bone index the chimp's weapon is attached to (0 = body).
function K.PG.resolveGunBone(pet, sel)
    local entry = K.PG.GUN_BONES[sel]
    if entry == nil then return 0 end
    for _, boneId in ipairs(entry[2]) do
        local ok, idx = pcall(Natives.InvokeInt, K.NATIVE.GET_PED_BONE_INDEX, pet, boneId)
        if ok and type(idx) == "number" and idx > 0 and idx < 4096 then return idx end
    end
    if #entry[2] > 0 then
        K.logWarn("chimp: bone not found for '" .. entry[1] .. "', the weapon is attached to the body")
    end
    return 0
end

-- Weapon prop of the chimp: created when it draws its weapon, attached to its
-- hand bone (extra position/rotation from the menu sliders, applied live),
-- removed when it puts the weapon away.
function K.PG.updateProp(pet, now)
    local pg = K.PG
    local N = K.NATIVE
    local info = pg.PETS[pg.petType]
    local w = pg.WEAPONS[cfg.guardWeapon]
    local gun = pg.GUNS[cfg.guardWeapon]
    local wanted = info ~= nil and info[3] ~= 4 and info[4] == true
        and cfg.guard and pg.propWanted and w[2] ~= 0 and gun ~= nil
    if not wanted then
        if pg.prop ~= nil then pg.removeProp() end
        return
    end

    if pg.prop ~= nil and not entityOk(pg.prop) then pg.prop, pg.propKey = nil, nil end
    if pg.prop == nil then
        if now < pg.propRetryAt then return end
        local model = Utils.Joaat(gun[1])
        Natives.InvokeVoid(N.REQUEST_MODEL, model)
        if not Natives.InvokeBool(N.HAS_MODEL_LOADED, model) then return end   -- retried next tick
        local x, y, z = Natives.InvokeV3(N.GET_ENTITY_COORDS, pet, true)
        local obj = Natives.InvokeInt(N.CREATE_OBJECT, model, x, y, z + 1.0, false, false, false)
        Natives.InvokeVoid(N.SET_MODEL_AS_NO_LONGER_NEEDED, model)
        if obj == nil or obj == 0 then pg.propRetryAt = now + 3000; return end
        Natives.InvokeVoid(N.SET_ENTITY_COLLISION, obj, false, false)
        pg.prop, pg.propKey = obj, nil
    end

    local o = cfg.monkeyGun
    local sel = clamp(cfg.monkeyBone or 1, 1, #pg.GUN_BONES)
    if pg.boneSel ~= sel or pg.boneFor ~= pet then
        pg.boneSel, pg.boneFor = sel, pet
        pg.boneIdx = pg.resolveGunBone(pet, sel)
        pg.propKey = nil
    end
    local key = tostring(pg.boneIdx) .. ":" .. table.concat(o, ",")
    if pg.propKey ~= key then
        Natives.InvokeVoid(N.ATTACH_ENTITY_TO_ENTITY, pg.prop, pet, pg.boneIdx,
            o[1], o[2], o[3], o[4], o[5], o[6],
            false, false, false, false, 2, true)
        pg.propKey = key
    end
end

-- Squared distance from a point to a segment.
function K.PG.segDistSq(px, py, pz, ax, ay, az, bx, by, bz)
    local abx, aby, abz = bx - ax, by - ay, bz - az
    local len2 = abx * abx + aby * aby + abz * abz
    local t = 0.0
    if len2 > 0.0001 then
        t = clamp(((px - ax) * abx + (py - ay) * aby + (pz - az) * abz) / len2, 0.0, 1.0)
    end
    return distSq(px, py, pz, ax + abx * t, ay + aby * t, az + abz * t)
end

-- The chimp "fires" its weapon: one bullet from the prop toward the target. Never
-- while YOU are anywhere near the line of fire.
function K.PG.monkeyFire(pet, now, px, py, pz)
    local pg = K.PG
    local N = K.NATIVE
    if pg.prop == nil or pg.guardTarget == nil or now < pg.nextShotAt then return end
    local gun, w = pg.GUNS[cfg.guardWeapon], pg.WEAPONS[cfg.guardWeapon]
    if gun == nil or w[2] == 0 or not entityOk(pg.prop) or not entityOk(pg.guardTarget) then return end

    local ox, oy, oz = Natives.InvokeV3(N.GET_ENTITY_COORDS, pg.prop, true)
    local tx, ty, tz = Natives.InvokeV3(N.GET_ENTITY_COORDS, pg.guardTarget, true)
    tz = tz + 0.3
    local dx, dy, dz = tx - ox, ty - oy, tz - oz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    if dist < 1.0 or dist > 45.0 then return end   -- too close / too far: it just keeps running at the target

    -- The bullet starts a little in front of the weapon; the aim isn't perfect.
    local sx, sy, sz = ox + dx / dist * 0.8, oy + dy / dist * 0.8, oz + dz / dist * 0.8
    local spread = 0.10 + dist * 0.012
    local ex = tx + (math.random() - 0.5) * 2.0 * spread
    local ey = ty + (math.random() - 0.5) * 2.0 * spread
    local ez = tz + (math.random() - 0.5) * 2.0 * spread

    if pg.segDistSq(px, py, pz + 0.3, sx, sy, sz, ex, ey, ez) < 2.5 * 2.5 then
        pg.nextShotAt = now + 150   -- you are in the way: wait
        return
    end

    Natives.InvokeVoid(N.SHOOT_SINGLE_BULLET_BETWEEN_COORDS,
        sx, sy, sz, ex, ey, ez, gun[3], true, w[2], pet, true, false, -1.0)
    pg.nextShotAt = now + gun[2] * 1000.0 * (0.85 + math.random() * 0.4)
end

-- Weapon in the hand (draw = true) or put away (draw = false).
function K.PG.drawWeapon(pet, draw)
    local pg = K.PG
    local w = pg.WEAPONS[cfg.guardWeapon]
    if not pg.canUseWeapon(pg.petType) or w[2] == 0 or pg.drawn == draw then return end
    pg.drawn = draw
    if pg.PETS[pg.petType][3] == 4 then
        Natives.InvokeVoid(K.NATIVE.SET_CURRENT_PED_WEAPON, pet, draw and w[2] or pg.UNARMED, true)
    else
        pg.propWanted = draw   -- the chimp: see updateProp()
    end
end

-- Gives / removes the weapon whenever the bodyguard settings change.
function K.PG.applyLoadout(pet)
    local pg = K.PG
    local key = table.concat({ pg.petType, cfg.guard and 1 or 0, cfg.guardWeapon, cfg.guardHolster and 1 or 0 }, ":")
    if pg.loadoutKey == key then return end
    pg.loadoutKey = key
    Natives.InvokeVoid(K.NATIVE.REMOVE_ALL_PED_WEAPONS, pet, true)
    pg.drawn, pg.propWanted = false, false
    pg.removeProp()
    local w = pg.WEAPONS[cfg.guardWeapon]
    if cfg.guard and pg.canUseWeapon(pg.petType) and w[2] ~= 0 then
        if pg.PETS[pg.petType][3] == 4 then
            Natives.InvokeVoid(K.NATIVE.GIVE_WEAPON_TO_PED, pet, w[2], 9999, false, false)
            Natives.InvokeVoid(K.NATIVE.SET_CURRENT_PED_WEAPON, pet, pg.UNARMED, true)
        end
        if not cfg.guardHolster then pg.drawWeapon(pet, true) end
    end
end

function K.PG.updatePet(ped, now)
    local pg = K.PG
    if not cfg.companion or Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, ped, false) then
        if pg.pet ~= nil then pg.removePet() end
        pg.petLoadSince, pg.callRequested, pg.respawnRequested = 0, false, false
        return
    end

    -- Buttons of the menu ("Respawn", "Call") are handled here, on the main loop.
    if pg.respawnRequested then
        pg.respawnRequested = false
        if pg.pet ~= nil then pg.removePet() end
        pg.petRetryAt = 0
    end
    if pg.pet ~= nil and pg.petType ~= cfg.companionType then pg.removePet() end
    if pg.pet ~= nil and (not entityOk(pg.pet) or Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, pg.pet, false)) then
        pg.removePet()
        pg.petRetryAt = now + 3000
    end

    if pg.pet == nil then
        pg.callRequested = false
        if now < pg.petRetryAt then return end
        local info = pg.PETS[cfg.companionType]
        local model = Utils.Joaat(info[2])
        Natives.InvokeVoid(K.NATIVE.REQUEST_MODEL, model)
        if not Natives.InvokeBool(K.NATIVE.HAS_MODEL_LOADED, model) then
            if pg.petLoadSince == 0 then
                pg.petLoadSince = now
            elseif now - pg.petLoadSince > 4000 then
                pg.petLoadSince, pg.petRetryAt = 0, now + 5000
                toast("Companion model could not load.", 3000)
            end
            return
        end
        pg.petLoadSince = 0
        local x, y, z = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
        -- Not networked: only you see it, so it can never bother other players.
        local pet = Natives.InvokeInt(K.NATIVE.CREATE_PED, info[3], model, x + 1.0, y + 1.0, z, 0.0, false, false)
        Natives.InvokeVoid(K.NATIVE.SET_MODEL_AS_NO_LONGER_NEEDED, model)
        if pet == nil or pet == 0 then pg.petRetryAt = now + 5000; return end
        -- Registered first: if one of the setup natives below ever fails, the
        -- companion still exists and is tracked (no orphan ped created on every tick).
        pg.pet, pg.petType, pg.petFollowAt, pg.petFollowing, pg.petTaskAt = pet, cfg.companionType, 0, false, 0
        pg.guardTarget, pg.loadoutKey, pg.drawn = nil, nil, false
        local okSetup, errSetup = pcall(function()
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_AS_MISSION_ENTITY, pet, true, true)
            Natives.InvokeVoid(K.NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, pet, true)
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_INVINCIBLE, pet, cfg.petInvincible)
            -- Fighting skills for the bodyguard mode.
            Natives.InvokeVoid(K.NATIVE.SET_PED_COMBAT_ABILITY, pet, 2)
            Natives.InvokeVoid(K.NATIVE.SET_PED_COMBAT_ATTRIBUTES, pet, 46, true)   -- always fight
            Natives.InvokeVoid(K.NATIVE.SET_PED_COMBAT_ATTRIBUTES, pet, 5, true)    -- fight armed peds when unarmed
            Natives.InvokeVoid(K.NATIVE.SET_PED_ACCURACY, pet, 70)
            -- Never hostile to you: same relationship group as the player, no friendly fire.
            local grp = Natives.InvokeInt(K.NATIVE.GET_PED_RELATIONSHIP_GROUP_HASH, ped)
            Natives.InvokeVoid(K.NATIVE.SET_PED_RELATIONSHIP_GROUP_HASH, pet, grp)
            Natives.InvokeVoid(K.NATIVE.SET_CAN_ATTACK_FRIENDLY, pet, false, false)
        end)
        if not okSetup then log("companion setup native failed: " .. tostring(errSetup)) end
        toast(info[1] .. " joined you!", 2500)
    end

    if now >= pg.petFollowAt then
        pg.petFollowAt = now + 700
        local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
        local qx, qy, qz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, pg.pet, true)
        local d2 = distSq(px, py, pz, qx, qy, qz)
        pg.petDist = math.sqrt(d2)
        Natives.InvokeVoid(K.NATIVE.SET_ENTITY_INVINCIBLE, pg.pet, cfg.petInvincible)
        if pg.callRequested or d2 > 45.0 * 45.0 then   -- "Call" button, or left behind (vehicle...)
            pg.callRequested = false
            Natives.InvokeVoid(K.NATIVE.SET_ENTITY_COORDS_NO_OFFSET, pg.pet, px + 1.0, py + 1.0, pz, false, false, false)
            pg.petFollowing = false
        end
        -- While it is fighting, the combat task has priority over following.
        if pg.guardTarget == nil
            and ((d2 > 16.0 and now >= pg.petTaskAt) or not pg.petFollowing or pg.speedUsed ~= cfg.petSpeed) then
            Natives.InvokeVoid(K.NATIVE.TASK_FOLLOW_TO_OFFSET_OF_ENTITY, pg.pet, ped, -1.0, -1.2, 0.0, cfg.petSpeed, -1, 1.8, true)
            pg.petFollowing, pg.petTaskAt, pg.speedUsed = true, now + 2500, cfg.petSpeed
        end
    end
end

-- Every check a valid bodyguard target must pass, EXCEPT whether it is
-- attacking the player (see K.PG.isAttackingPlayer).
local function isEligibleTarget(npc, ped)
    if npc == nil or npc == 0 or npc == ped or npc == K.PG.pet or npc == carriedEntity then return false end
    if not entityOk(npc) then return false end
    if Natives.InvokeBool(K.NATIVE.IS_PED_A_PLAYER, npc) then return false end
    if Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, npc, false) then return false end
    local okT, pedType = pcall(Natives.InvokeInt, K.NATIVE.GET_PED_TYPE, npc)
    if okT and (pedType == 6 or pedType == 27) then return false end   -- cops / SWAT
    return true
end

-- Is this NPC attacking the player? Several independent signals, because the
-- game's "in combat" flag alone misses a lot of attacks (muggings, melee, ...).
-- Returns true + the reason. Real players and the police never count (see
-- isEligibleTarget).
function K.PG.isAttackingPlayer(npc, ped)
    local N = K.NATIVE
    if Natives.InvokeBool(N.IS_PED_IN_COMBAT, npc, ped) then return true, "in combat with you" end
    local okD, damaged = pcall(Natives.InvokeBool, N.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY, ped, npc, true)
    if okD and damaged then return true, "it damaged you" end
    local okM, meleeTarget = pcall(Natives.InvokeInt, N.GET_MELEE_TARGET_FOR_PED, npc)
    if okM and meleeTarget == ped then return true, "fighting you in melee" end
    return false
end

function K.PG.isThreat(npc, ped)
    if not isEligibleTarget(npc, ped) then return false end
    return (K.PG.isAttackingPlayer(npc, ped))
end

-- Every ped around the player. The previous scan used GET_RANDOM_PED_AT_COORD,
-- which hands back an arbitrary ped: in the logs it found NO candidate at all,
-- scan after scan, so the attacker was simply never looked at. The complete list
-- is read with GET_PED_NEARBY_PEDS instead (array: slot 0 = size, then the peds).
-- Returns a list, or nil when the native can't be used here.
function K.PG.nearbyPeds(ped)
    local pg = K.PG
    local MAXP = 32
    pg.nearBuf = pg.nearBuf or Memory.Alloc(8 * (MAXP + 2))
    local okCall, count = pcall(function()
        memWriteInt(pg.nearBuf, MAXP)
        return Natives.InvokeInt(K.NATIVE.GET_PED_NEARBY_PEDS, ped, pg.nearBuf, -1)
    end)
    if not okCall then return nil end
    count = tonumber(count) or 0
    if count <= 0 then return {} end
    if count > MAXP then count = MAXP end

    for _, stride in ipairs({ pg.nearStride, pg.nearStride == 8 and 4 or 8 }) do
        local list = {}
        for i = 1, count do
            local h = Common.memReadInt(pg.nearBuf, stride * i)
            if h ~= nil and h ~= 0 and entityOk(h) then list[#list + 1] = h end
        end
        if #list > 0 then
            pg.nearStride = stride
            return list
        end
    end
    return nil   -- the native answered but its list can't be read: use the fallback
end

-- Fallback sampling (what the old scan did, with more draws).
function K.PG.randomPeds(ped, r, n)
    local px, py, pz = Natives.InvokeV3(K.NATIVE.GET_ENTITY_COORDS, ped, true)
    local list, seen = {}, {}
    for _ = 1, n do
        local npc = Natives.InvokeInt(K.NATIVE.GET_RANDOM_PED_AT_COORD, px, py, pz, r, r, r, -1)
        if npc ~= nil and npc ~= 0 and not seen[npc] then
            seen[npc] = true
            list[#list + 1] = npc
        end
    end
    return list
end

function K.PG.updateGuard(ped, now)
    local pg = K.PG
    local N = K.NATIVE
    local pet = pg.pet
    if pet == nil then return end
    pg.applyLoadout(pet)
    pg.updateProp(pet, now)

    if not cfg.guard then
        if pg.guardTarget ~= nil then
            pg.guardTarget = nil
            Natives.InvokeVoid(N.CLEAR_PED_TASKS, pet)
            pg.petFollowing = false
        end
        return
    end

    local px, py, pz = Natives.InvokeV3(N.GET_ENTITY_COORDS, ped, true)

    -- 1) Has something just hurt the player? Health alone isn't enough (armor
    -- absorbs hits, and damage resistance / god mode give health back before
    -- this runs), so armor and the game's own "damaged by a ped" flag count too.
    -- A hit opens a 5 s "alert" window: faster scans and looser matching.
    local hp = Natives.InvokeInt(N.GET_ENTITY_HEALTH, ped)
    local okA, armor = pcall(Natives.InvokeInt, N.GET_PED_ARMOUR, ped)
    if not okA then armor = nil end
    local hurt = pg.lastPlayerHp ~= nil and hp > 0 and hp < pg.lastPlayerHp
    if armor ~= nil and pg.lastArmor ~= nil and armor < pg.lastArmor then hurt = true end
    pg.lastPlayerHp, pg.lastArmor = hp, armor
    if pg.hurtSince == 0 and not pg.damageFlagBroken then
        local okD, byPed = pcall(Natives.InvokeBool, N.HAS_ENTITY_BEEN_DAMAGED_BY_ANY_PED, ped)
        if okD and byPed then hurt = true end
    end
    if hurt then
        if pg.hurtSince == 0 then log("bodyguard: you were hit, alert for 5 s") end
        pg.hurtSince = now
        if pg.guardTarget == nil then pg.guardScanAt = 0 end   -- scan right now
    end
    if pg.hurtSince ~= 0 and now - pg.hurtSince > 5000 then
        pg.hurtSince = 0
        -- Reset the game's damage memory, otherwise the flag would stay set forever.
        pcall(Natives.InvokeVoid, N.CLEAR_ENTITY_LAST_DAMAGE_ENTITY, ped)
        local okS, still = pcall(Natives.InvokeBool, N.HAS_ENTITY_BEEN_DAMAGED_BY_ANY_PED, ped)
        if okS and still then
            pg.damageFlagBroken = true
            log("bodyguard: the damage flag can't be cleared on this build, no longer using it")
        end
    end
    local alert = pg.hurtSince ~= 0

    -- 2) Current target still valid?
    local t = pg.guardTarget
    if t ~= nil then
        local keep = entityOk(t) and not Natives.InvokeBool(N.IS_ENTITY_DEAD, t, false)
        if keep then
            local tx, ty, tz = Natives.InvokeV3(N.GET_ENTITY_COORDS, t, true)
            local lim = cfg.guardRadius + 12.0
            keep = distSq(tx, ty, tz, px, py, pz) <= lim * lim
        end
        if not keep then   -- fight over: back to the player
            pg.guardTarget, pg.guardCalmAt, pg.petFollowing = nil, now + 2500, false
            Natives.InvokeVoid(N.CLEAR_PED_TASKS, pet)
        end
    end

    -- The chimp fires through the script (humans use their real weapon).
    if pg.guardTarget ~= nil then pg.monkeyFire(pet, now, px, py, pz) end

    -- 3) Look for an attacker.
    if pg.guardTarget == nil then
        if now >= pg.guardScanAt then
            pg.guardScanAt = now + (alert and 150 or 400)
            local r = cfg.guardRadius

            local list = (not pg.nearBroken) and pg.nearbyPeds(ped) or nil
            local source = "nearby peds"
            if list == nil then
                if not pg.nearBroken then
                    pg.nearBroken = true
                    log("bodyguard: GET_PED_NEARBY_PEDS isn't usable here, falling back to random sampling")
                end
                list = pg.randomPeds(ped, r, alert and 24 or 12)
                source = "random sampling"
            end

            local attacker, attackerD, why          -- explicit "this ped attacks you"
            local shooter, shooterD                 -- alert only: someone shooting nearby
            local nearest, nearestD                 -- alert only: closest eligible ped
            local eligible = 0
            for _, npc in ipairs(list) do
                if isEligibleTarget(npc, ped) then
                    local nx, ny, nz = Natives.InvokeV3(N.GET_ENTITY_COORDS, npc, true)
                    local d = distSq(nx, ny, nz, px, py, pz)
                    if d <= r * r then
                        eligible = eligible + 1
                        if nearest == nil or d < nearestD then nearest, nearestD = npc, d end
                        local attacking, reason = pg.isAttackingPlayer(npc, ped)
                        if attacking and (attacker == nil or d < attackerD) then
                            attacker, attackerD, why = npc, d, reason
                        end
                        if alert then
                            local okS, shooting = pcall(Natives.InvokeBool, N.IS_PED_SHOOTING, npc)
                            if okS and shooting and (shooter == nil or d < shooterD) then
                                shooter, shooterD = npc, d
                            end
                        end
                    end
                end
            end

            local best, how = attacker, why
            if best == nil and alert then
                if shooter ~= nil then
                    best, how = shooter, "it is shooting nearby"
                elseif nearest ~= nil and nearestD <= 12.0 * 12.0 then
                    best, how = nearest, "closest ped (nobody flagged as attacking)"
                end
            end

            -- Quiet log: only during an alert (once a second) or on engagement.
            if best ~= nil or (alert and now - pg.scanLogAt > 1000) then
                pg.scanLogAt = now
                log(string.format("bodyguard scan (%s): %d peds, %d eligible in %d m, target=%s%s",
                    source, #list, eligible, math.floor(r), tostring(best ~= nil),
                    how and (" [" .. how .. "]") or ""))
            end

            if best ~= nil and best ~= ped then   -- never the player
                pg.guardTarget, pg.combatAt = best, now
                pg.drawWeapon(pet, true)
                Natives.InvokeVoid(N.TASK_COMBAT_PED, pet, best, 0, 16)
                toast("Bodyguard engaging!", 1500)
            end
        end
    elseif now - pg.combatAt > 1500 then   -- keep the fight going if the task was dropped
        pg.combatAt = now
        if not Natives.InvokeBool(N.IS_PED_IN_COMBAT, pet, pg.guardTarget) then
            Natives.InvokeVoid(N.TASK_COMBAT_PED, pet, pg.guardTarget, 0, 16)
        end
    end

    if pg.guardTarget == nil and cfg.guardHolster and pg.drawn and now >= pg.guardCalmAt then
        pg.drawWeapon(pet, false)
    end
end

-- Texts for the menu (computed here: natives are not safe in the menu callback).
function K.PG.statusText()
    local pg = K.PG
    if not cfg.companion then return "Status: OFF" end
    if pg.pet == nil then return "Status: calling your companion..." end
    return string.format("Status: %s is with you  (%.1f m away)", pg.PETS[pg.petType][1], pg.petDist or 0.0)
end

function K.PG.guardText()
    local pg = K.PG
    if not cfg.guard then return "Bodyguard: OFF" end
    if pg.pet == nil then return "Bodyguard: waiting for your companion" end
    if pg.guardTarget ~= nil then return "Bodyguard: FIGHTING" end
    return string.format("Bodyguard: on watch  (radius %d m)", math.floor(cfg.guardRadius))
end

function K.PG.cleanup()
    K.PG.removePet()
end

function K.PG.update(now)
    local ok, err = pcall(function()
        local ped = getPed()
        K.PG.updatePet(ped, now)
        K.PG.updateGuard(ped, now)
    end)
    if not ok and tostring(err) ~= K.PG.lastErr then
        K.PG.lastErr = tostring(err)
        K.logError("Playground: " .. K.PG.lastErr)
    end
end

local wasEnabled, keyWasDown, dropWasDown = false, false, false
local mouseWasDown = false
local lastActionMs, lastError = 0, nil
local featureEnabled = false

local pendingPunch = nil   -- { t0 = click timestamp, target, kind, scenery, dir }
local punchBufferedMs = nil   -- a click made while a punch was still landing

-- Waits for the configured delay (the moment of the fist's impact) then
-- executes the punch whose target was chosen on click.
local function processPendingPunch(ped)
    if pendingPunch == nil then
        return
    end

    -- Cancel if the situation changed during the animation.
    if carrying or Natives.InvokeBool(K.NATIVE.IS_PED_IN_ANY_VEHICLE, ped, false)
        or Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, ped, false) then
        pendingPunch = nil
        return
    end

    local elapsed = Time.GetEpocheMs() - pendingPunch.t0
    if elapsed >= cfg.punchDelay then
        log(string.format("impact after %d ms", elapsed))
        local p = pendingPunch
        pendingPunch = nil
        performPunch(ped, p)
    end
end

local function tick()
    local now = Time.GetEpocheMs()
    refreshConfig()

    local enabled = FeatureMgr.IsFeatureToggled(H.toggle)

    if enabled ~= wasEnabled then
        wasEnabled = enabled
        log("option " .. (enabled and "ENABLED" or "disabled"))
        if not enabled then
            releaseWithoutThrowing()
            pendingPunch = nil
            rageLevel = 0.0
        end
    end

    featureEnabled = enabled

    -- These keep running even when the feature is switched off, so that
    -- impulses in progress finish and flagged entities get released.
    processSettling()
    processPunches()
    processReleases(now)
    K.guard("sounds", processSounds, now)
    K.guard("rage", updateRage, now)
    K.guard("quests", updateQuests, now)
    K.guard("settings", saveSettingsIfChanged, now)
    K.PG.update(now)   -- Playground works even when Hulk Mode itself is off

    if not enabled then
        clearTargetHighlight()
        clearTrajectory()
        return
    end

    local ped = getPed()

    -- Safety checks: carried entity disappeared, player died or got into a vehicle.
    if carrying then
        local dead = Natives.InvokeBool(K.NATIVE.IS_ENTITY_DEAD, ped, false)
        local inVeh = Natives.InvokeBool(K.NATIVE.IS_PED_IN_ANY_VEHICLE, ped, false)
        if not entityOk(carriedEntity) then
            log("carried entity disappeared, resetting")
            -- Also stop the carry animation, otherwise the player would stay
            -- stuck with their hands up.
            Natives.InvokeVoid(K.NATIVE.CLEAR_PED_TASKS, ped)
            carrying, carriedEntity, animPlaying = false, nil, false
            activeCarryAnimDict, activeCarryAnimClip = nil, nil
            chargeStart, chargeFrac = nil, 0.0
        elseif dead or inVeh then
            releaseWithoutThrowing()
        end
    end

    K.guard("highlight", updateTargetHighlight, ped, now)

    if carrying then
        updateCarryAnim(ped)
        updateCarriedNpc()
    end
    K.guard("trajectory", updateTrajectory, ped, now)
    updatePendingGrab()
    updatePendingAttach()

    local keyDown = Utils.IsKeyDown(cfg.grabKey)
    -- The menu, the pause menu and the chat all swallow our hotkeys.
    local blockReason = GUI.IsOpen() and "menu Cherax ouvert (ferme-le avec sa touche)"
        or (inputBlocked() and "menu pause ouvert" or nil)
    local menuOpen = blockReason ~= nil
    if keyDown and not keyWasDown and menuOpen and now - (K.lastBlockToastMs or 0) > 2000 then
        K.lastBlockToastMs = now
        toast("Touche ignorée : " .. blockReason)
    end

    -- Gently put it down
    local dropDown = Utils.IsKeyDown(cfg.dropKey)
    if carrying and dropDown and not dropWasDown and not menuOpen then
        releaseWithoutThrowing()
        playSound(K.SND.drop)
        toast("Dropped.")
    end
    dropWasDown = dropDown

    if not menuOpen then
        local pressed  = keyDown and not keyWasDown
        local released = (not keyDown) and keyWasDown

        if carrying then
            if cfg.charged then
                -- Charging starts on press, the throw happens on release.
                if pressed and now - lastActionMs >= K.ACTION_COOLDOWN_MS then
                    chargeStart = now
                    lastChargeStage = 0
                end
                if chargeStart ~= nil and keyDown then
                    chargeFrac = clamp((now - chargeStart) / cfg.chargeMs, 0.0, 1.0)
                    -- One tick per quarter of charge, a different sound at full power.
                    local stage = math.floor(chargeFrac * 4.0)
                    if stage > lastChargeStage then
                        lastChargeStage = stage
                        playSound(stage >= 4 and K.SND.chargeMax or K.SND.charge)
                    end
                end
                if chargeStart ~= nil and released then
                    local power = cfg.throwSpeed * (K.DEFAULTS.throwMinPct + (1.0 - K.DEFAULTS.throwMinPct) * chargeFrac)
                    lastActionMs = now
                    throwCarriedEntity(ped, power)
                end
            elseif pressed and now - lastActionMs >= K.ACTION_COOLDOWN_MS then
                lastActionMs = now
                throwCarriedEntity(ped, cfg.throwSpeed)
            end
        elseif pressed and pendingEntity == nil and pendingAttach == nil and now - lastActionMs >= K.ACTION_COOLDOWN_MS then
            lastActionMs = now
            if Natives.InvokeBool(K.NATIVE.IS_PED_IN_ANY_VEHICLE, ped, false) then
                toast("Get out of your vehicle first.")
            else
                grabTarget(ped)
            end
        end
    end
    keyWasDown = keyDown

    -- Super punch: detect the left click (GTA control, "disabled" control, or
    -- Windows mouse button: we accept all three, since depending on context
    -- one or the other may not fire).
    local mouseDown = Utils.IsKeyDown(0x01)
    local clickEdge = (mouseDown and not mouseWasDown)
        or Natives.InvokeBool(K.NATIVE.IS_CONTROL_JUST_PRESSED, 0, K.PUNCH_CONTROL)
        or Natives.InvokeBool(K.NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED, 0, K.PUNCH_CONTROL)
    mouseWasDown = mouseDown

    processPendingPunch(ped)

    -- A click made while a punch is still landing is remembered for a moment,
    -- so rapid clicking doesn't lose punches.
    if clickEdge and pendingPunch ~= nil then punchBufferedMs = now end
    local wantPunch = clickEdge or (punchBufferedMs ~= nil and now - punchBufferedMs < 300)
    if wantPunch and pendingPunch == nil then punchBufferedMs = nil end

    if wantPunch and cfg.punch and pendingPunch == nil then
        local reasons = {}
        if carrying then reasons[#reasons + 1] = "carrying something" end
        if pendingEntity ~= nil or pendingAttach ~= nil then reasons[#reasons + 1] = "grab in progress" end
        if menuOpen then reasons[#reasons + 1] = "menu open / input blocked" end
        if Natives.InvokeBool(K.NATIVE.IS_PED_IN_ANY_VEHICLE, ped, false) then reasons[#reasons + 1] = "in a vehicle" end
        if not isUnarmed(ped) then
            reasons[#reasons + 1] = "weapon equipped (hash " .. tostring(Natives.InvokeInt(K.NATIVE.GET_SELECTED_PED_WEAPON, ped)) .. ")"
        end
        -- Coexistence note: VehicleGun (which blocks bullets) reserves the left click.

        if #reasons == 0 then
            if now - lastPunchMs < K.PUNCH_COOLDOWN_MS then
                log("click ignored (too soon after the last one)")
            else
                -- A first target is chosen RIGHT NOW (click). It is checked again,
                -- and picked again if needed, at the moment of impact.
                local target, kind, scenery, dir = pickPunchTarget(ped, cfg.safe)
                lastPunchMs = now
                pendingPunch = { t0 = now, target = target, kind = kind, scenery = scenery, dir = dir }
                log("click detected -> target: " .. tostring(kind or (scenery and "scenery") or "none yet")
                    .. ", impact in " .. string.format("%.0f", cfg.punchDelay) .. " ms")
            end
        else
            log("click detected but blocked: " .. table.concat(reasons, ", "))
        end
    end
end

K.printBanner()

Script.RegisterLooped(function()
    local ok, err = pcall(tick)
    if not ok and tostring(err) ~= lastError then
        lastError = tostring(err)
        K.logError("in the main loop: " .. lastError)
        Common.toast("Hulk Mode - ERROR", lastError, 6000)
        -- If the error happened while carrying something, release it so it
        -- doesn't stay frozen in mid-air.
        pcall(releaseWithoutThrowing)
    end
    Script.Yield()
end)

local lastDrawError = nil
EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if not featureEnabled then
        return
    end
    -- Draw the target brackets even if the user's ordinary crosshair toggle is off.
    if not cfg.cross and not (highlightedEntity ~= nil and cfg.highlight)
        and not (cfg.trajectory and #traj.points > 1) then
        return
    end
    local ok, err = pcall(drawCrosshair)
    if not ok and tostring(err) ~= lastDrawError then
        lastDrawError = tostring(err)
        K.logError("drawing the crosshair: " .. lastDrawError)
    end
end)

-- ============================================================
--  INTRO ANIMATION v3 "GAMMA BURST" (played once, when the script loads)
--  CRT turn-on -> gamma trefoil charging up with a rotating charge ring
--  and particles pulled into the core -> SLAM (flash, speed lines,
--  shockwaves, sparks, camera shake) -> glitchy RGB-split "HULK" title
--  drawn stroke by stroke, "MODE" subtitle, segmented loading bar, HUD
--  corners -> glitch-out.
--  Pure ImGui lines/circles (no text API needed). Delete this whole block
--  to remove it, or tweak INTRO_MS / IMPACT_MS below.
-- ============================================================
do
    local INTRO_MS   = 4800
    local IMPACT_MS  = 1700          -- moment of the slam (flash + shake + sound)
    local introStart = Time.GetEpocheMs()
    local introDone  = false
    local introError = nil
    local fired      = {}

    local function easeOut(x)
        x = clamp(x, 0.0, 1.0)
        return 1.0 - (1.0 - x) ^ 3
    end

    local function easeOutBack(x)
        x = clamp(x, 0.0, 1.0)
        local c1, c3 = 1.70158, 2.70158
        return 1.0 + c3 * (x - 1.0) ^ 3 + c1 * (x - 1.0) ^ 2
    end

    -- deterministic pseudo-random number (0..1)
    local function rnd(n)
        local v = math.sin(n * 12.9898) * 43758.5453
        return v - math.floor(v)
    end

    local function arc(cx, cy, radius, startAng, sweep, r, g, b, a, thick)
        local steps = math.max(2, math.ceil(72 * math.abs(sweep) / (2.0 * math.pi)))
        local px, py = cx + math.cos(startAng) * radius, cy + math.sin(startAng) * radius
        for k = 1, steps do
            local ang = startAng + sweep * (k / steps)
            local nx, ny = cx + math.cos(ang) * radius, cy + math.sin(ang) * radius
            ImGui.AddLine(px, py, nx, ny, r, g, b, a, thick)
            px, py = nx, ny
        end
    end

    local function ring(cx, cy, radius, r, g, b, a, thick)
        arc(cx, cy, radius, 0.0, 2.0 * math.pi, r, g, b, a, thick)
    end

    -- Letters drawn as strokes (unit square, y goes down).
    local LETTERS = {
        H = { { {0,0},{0,1} }, { {1,0},{1,1} }, { {0,.5},{1,.5} } },
        U = { { {0,0},{0,.8},{.2,1},{.8,1},{1,.8},{1,0} } },
        L = { { {0,0},{0,1},{1,1} } },
        K = { { {0,0},{0,1} }, { {1,0},{0,.58} }, { {.28,.42},{1,1} } },
        M = { { {0,1},{0,0},{.5,.58},{1,0},{1,1} } },
        O = { { {.25,0},{.75,0},{1,.25},{1,.75},{.75,1},{.25,1},{0,.75},{0,.25},{.25,0} } },
        D = { { {0,1},{0,0},{.6,0},{1,.3},{1,.7},{.6,1},{0,1} } },
        E = { { {1,0},{0,0},{0,1},{1,1} }, { {0,.5},{.75,.5} } },
    }

    -- Polyline drawn up to `progress` (0..1) of its length.
    local function drawPoly(pts, ox, oy, sw, sh, progress, r, g, b, a, thick)
        local total = 0.0
        for i = 2, #pts do
            total = total + math.sqrt(((pts[i][1] - pts[i-1][1]) * sw) ^ 2
                + ((pts[i][2] - pts[i-1][2]) * sh) ^ 2)
        end
        local limit, done = total * progress, 0.0
        for i = 2, #pts do
            if done >= limit then break end
            local x0, y0 = ox + pts[i-1][1] * sw, oy + pts[i-1][2] * sh
            local x1, y1 = ox + pts[i][1] * sw,   oy + pts[i][2] * sh
            local seg = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
            if done + seg > limit then
                local f = (limit - done) / math.max(seg, 0.0001)
                x1, y1 = x0 + (x1 - x0) * f, y0 + (y1 - y0) * f
            end
            ImGui.AddLine(x0, y0, x1, y1, r, g, b, a, thick)
            done = done + seg
        end
    end

    local function wordWidth(n, sh, ratio, gapRatio)
        local sw = sh * ratio
        return n * sw + (n - 1) * sw * gapRatio
    end

    -- Draws a word, letter by letter, each letter revealed stroke-wise.
    local function drawWord(word, cx, cy, sh, ratio, gapRatio, t, tStart, stagger, dur,
                            ox, oy, r, g, b, a, thick)
        local n = #word
        local sw = sh * ratio
        local gap = sw * gapRatio
        local x = cx - wordWidth(n, sh, ratio, gapRatio) / 2.0 + ox
        local y = cy - sh / 2.0 + oy
        for i = 1, n do
            local strokes = LETTERS[word:sub(i, i)]
            local p = easeOut((t - (tStart + (i - 1) * stagger)) / dur)
            if p > 0.0 and strokes then
                for _, s in ipairs(strokes) do
                    drawPoly(s, x, y, sw, sh, p, r, g, b, a, thick)
                end
            end
            x = x + sw + gap
        end
    end

    -- Gamma / radiation trefoil: three blades + core.
    local function trefoil(x, y, R, spin, a)
        for k = 0, 2 do
            local base = spin + k * 2.0 * math.pi / 3.0
            local n = 14
            for j = 0, n do
                local ang = base + (j / n - 0.5) * (math.pi / 3.0)
                local ca, sa = math.cos(ang), math.sin(ang)
                ImGui.AddLine(x + ca * R * 0.30, y + sa * R * 0.30, x + ca * R, y + sa * R,
                    40, 255, 95, a, R * 0.095)
            end
        end
        ImGui.AddCircleFilled(x, y, R * 0.13, 40, 255, 95, a)
        ring(x, y, R * 0.22, 220, 255, 230, math.floor(a * 0.8), 2.0)
        ring(x, y, R * 1.10, 40, 255, 95, math.floor(a * 0.6), 2.0)
    end

    local function drawIntro()
        local t = Time.GetEpocheMs() - introStart
        if t >= INTRO_MS then
            introDone = true
            return
        end

        local w, h = ImGui.GetDisplaySize()
        local cx, cy = w / 2.0, h / 2.0
        local size = math.min(w, h)
        local ti = t - IMPACT_MS

        -- Global fade in (0.25 s) and fade out (last 0.6 s).
        local master = clamp(t / 250.0, 0.0, 1.0)
            * (1.0 - clamp((t - (INTRO_MS - 600)) / 600.0, 0.0, 1.0))
        local function alpha(v) return math.floor(clamp(v * master, 0.0, 255.0)) end

        -- Glitch intensity: burst right after the slam, and ramping up at the end.
        local glitch = 0.0
        if ti > 0 and ti < 450 then glitch = 1.0 - ti / 450.0 end
        if t > INTRO_MS - 900 then
            glitch = math.max(glitch, (t - (INTRO_MS - 900)) / 900.0)
        end

        -- 1) CRT turn-on: a bright line grows, then opens into a dark panel.
        local lineW  = w * easeOut(t / 350.0)
        local panelH = h * 0.62 * easeOut((t - 300.0) / 450.0)
        if panelH > 1.0 then
            ImGui.AddLine(cx - lineW / 2.0, cy, cx + lineW / 2.0, cy, 0, 0, 0, alpha(165), panelH)
            ImGui.AddLine(0.0, cy - panelH / 2.0, w, cy - panelH / 2.0, 40, 255, 95, alpha(210), 2.0)
            ImGui.AddLine(0.0, cy + panelH / 2.0, w, cy + panelH / 2.0, 40, 255, 95, alpha(210), 2.0)
        end
        if t < 800 then
            local fade = 1.0 - easeOut((t - 300.0) / 450.0)
            ImGui.AddLine(cx - lineW / 2.0, cy, cx + lineW / 2.0, cy, 210, 255, 225, alpha(255 * fade), 3.0)
        end

        -- Faint scanlines + a sweeping beam inside the panel.
        if panelH > 20.0 then
            local top  = cy - panelH / 2.0
            local step = 9.0
            local off  = (t * 0.04) % step
            for k = 0, math.floor(panelH / step) - 1 do
                local y = top + k * step + off
                if y < top + panelH then
                    ImGui.AddLine(0.0, y, w, y, 40, 255, 95, alpha(10), 1.0)
                end
            end
            if t < IMPACT_MS + 300 then
                local by = top + panelH * ((t % 1100) / 1100.0)
                ImGui.AddLine(0.0, by, w, by, 40, 255, 95, alpha(16), 28.0)
                ImGui.AddLine(0.0, by, w, by, 120, 255, 150, alpha(50), 2.0)
            end
        end

        -- 2) Gamma trefoil: charges up (accelerating spin) then fades behind the title.
        local Rbase = size * 0.15
        if t > 150 then
            local spin, R, a
            if ti <= 0 then
                local u = t / 1000.0
                spin = u * u * 3.0
                R = Rbase * easeOut(t / 1200.0) * (1.0 + 0.07 * math.sin(t / 85.0) * clamp(t / IMPACT_MS, 0.0, 1.0))
                a = alpha(235)
            else
                local u0 = IMPACT_MS / 1000.0
                spin = u0 * u0 * 3.0 + 2.4 * (1.0 - math.exp(-ti / 700.0))
                R = Rbase * (1.0 + 0.9 * easeOut(ti / 1200.0))
                a = alpha(math.max(38.0, 235.0 - 197.0 * easeOut(ti / 500.0)))
            end
            trefoil(cx, cy - size * 0.02, R, spin, a)

            -- Charge ring: an arc that sweeps around the trefoil until the slam.
            if ti <= 0 then
                local frac = clamp(t / IMPACT_MS, 0.0, 1.0)
                arc(cx, cy - size * 0.02, Rbase * 1.32, -math.pi / 2.0, frac * 2.0 * math.pi,
                    math.floor(255 * frac) , math.floor(255 - 115 * frac), 40, alpha(255), 4.0)
            end
        end

        -- 3) Particles sucked into the core before the slam.
        if t < IMPACT_MS + 150 then
            for i = 1, 52 do
                local ang   = rnd(i) * 2.0 * math.pi
                local delay = rnd(i + 10) * 600.0
                local p = clamp((t - delay) / (IMPACT_MS - delay - 100.0), 0.0, 1.0)
                if p > 0.0 and p < 1.0 then
                    local e    = p * p
                    local dist = size * 0.75 * (1.0 - e) + 8.0
                    local d2   = dist + size * 0.05 * p
                    local ca, sa = math.cos(ang), math.sin(ang)
                    ImGui.AddLine(cx + ca * d2, cy + sa * d2, cx + ca * dist, cy + sa * dist,
                        150, 255, 90, alpha(60 + 195 * p), 2.0)
                end
            end
        end

        -- 4) THE SLAM: flash, speed lines, shockwaves, sparks.
        if ti > 0 then
            local flash = 1.0 - clamp(ti / 300.0, 0.0, 1.0)
            if flash > 0.0 then
                ImGui.AddLine(0.0, cy, w, cy, 210, 255, 225, alpha(200 * flash), h)
            end

            if ti < 700 then
                for i = 1, 40 do
                    local ang = rnd(i + 300) * 2.0 * math.pi
                    local r0  = size * (0.18 + 0.25 * rnd(i + 400))
                    local head = r0 + size * 1.1 * easeOut(ti / 450.0)
                    local tail = r0 + size * 1.1 * easeOut((ti - 120.0) / 450.0)
                    local ca, sa = math.cos(ang), math.sin(ang)
                    ImGui.AddLine(cx + ca * tail, cy + sa * tail, cx + ca * head, cy + sa * head,
                        190, 255, 200, alpha(200 * (1.0 - ti / 700.0)), 1.5 + 2.0 * rnd(i + 500))
                end
            end

            local maxR = size * 0.70
            for i = 0, 3 do
                local p = (ti - i * 170) / 1300.0
                if p > 0.0 and p < 1.0 then
                    ring(cx, cy, 20.0 + maxR * easeOut(p), 60, 255, 100,
                        alpha(240 * (1.0 - p)), 1.5 + 6.0 * (1.0 - p))
                end
            end

            for i = 1, 52 do
                local ang   = rnd(i + 600) * 2.0 * math.pi
                local speed = size * (0.35 + 0.65 * rnd(i + 700))
                local life  = 700.0 + 900.0 * rnd(i + 800)
                if ti < life then
                    local function pos(tt)
                        local s = tt / 1000.0
                        return cx + math.cos(ang) * speed * s,
                               cy + math.sin(ang) * speed * s + 0.45 * size * s * s
                    end
                    local x1, y1 = pos(ti)
                    local x0, y0 = pos(math.max(ti - 45.0, 0.0))
                    local fade = 1.0 - ti / life
                    ImGui.AddLine(x0, y0, x1, y1, 190, 255, 120, alpha(255 * fade), 2.2 * fade + 0.6)
                end
            end
        end

        -- 5) Title "HULK": stroke reveal, slam scale with bounce, RGB split.
        local title0 = IMPACT_MS - 250.0
        local sh0 = size * 0.19
        if t > title0 then
            local settle = easeOutBack((ti + 200.0) / 500.0)
            local scale  = 1.0 + 0.5 * (1.0 - settle)
            local sh     = sh0 * scale
            local ty     = cy - size * 0.05
            if ti > 0 and ti < 350 then
                ty = ty + math.sin(ti / 16.0) * 9.0 * (1.0 - ti / 350.0)
            end
            local d = 2.0 + 16.0 * glitch
            local function layer(ox, oy, r, g, b, a, thick)
                drawWord("HULK", cx, ty, sh, 0.74, 0.34, t, title0, 60.0, 220.0, ox, oy, r, g, b, alpha(a), thick)
            end
            layer(0.0, 0.0, 40, 255, 95, 50, 20.0)         -- glow
            layer(-d, 0.0, 255, 50, 70, 170, 5.0)          -- red split
            layer(d, 0.0, 50, 220, 255, 170, 5.0)          -- cyan split
            layer(0.0, 0.0, 110, 255, 140, 255, 6.0)       -- body
            layer(0.0, 0.0, 235, 255, 240, 255, 2.0)       -- hot core
        end

        -- 6) Subtitle "MODE" with growing side rules.
        local subStart = IMPACT_MS + 200.0
        local sh2 = size * 0.055
        local subY = cy - size * 0.05 + sh0 / 2.0 + size * 0.075
        if t > subStart then
            drawWord("MODE", cx, subY, sh2, 0.8, 1.1, t, subStart, 90.0, 300.0, 0.0, 0.0, 40, 255, 95, alpha(90), 9.0)
            drawWord("MODE", cx, subY, sh2, 0.8, 1.1, t, subStart, 90.0, 300.0, 0.0, 0.0, 235, 255, 240, alpha(255), 3.0)
            local subW = wordWidth(4, sh2, 0.8, 1.1)
            local e = easeOut((t - subStart - 150.0) / 500.0)
            local len = size * 0.18 * e
            if len > 1.0 then
                local lx0, rx0 = cx - subW / 2.0 - 24.0, cx + subW / 2.0 + 24.0
                ImGui.AddLine(lx0, subY, lx0 - len, subY, 40, 255, 95, alpha(255), 2.0)
                ImGui.AddLine(rx0, subY, rx0 + len, subY, 40, 255, 95, alpha(255), 2.0)
                ImGui.AddCircleFilled(lx0 - len, subY, 3.5, 220, 255, 230, alpha(255))
                ImGui.AddCircleFilled(rx0 + len, subY, 3.5, 220, 255, 230, alpha(255))
            end

            -- 7) Segmented loading bar (green -> orange).
            local barW  = wordWidth(4, sh0, 0.74, 0.34)
            local barY  = subY + sh2 / 2.0 + size * 0.06
            local segs  = 24
            local step  = barW / segs
            local frac  = clamp((t - IMPACT_MS - 300.0) / (INTRO_MS - IMPACT_MS - 1200.0), 0.0, 1.0)
            local filled = math.floor(frac * segs)
            local reveal = easeOut((t - subStart - 200.0) / 400.0)
            for k = 0, segs - 1 do
                local x0 = cx - barW / 2.0 + k * step
                if k < filled then
                    local f = k / (segs - 1)
                    ImGui.AddLine(x0, barY, x0 + step * 0.72, barY,
                        math.floor(40 + 215 * f), math.floor(255 - 115 * f), math.floor(95 - 70 * f),
                        alpha(250 * reveal), 7.0)
                else
                    ImGui.AddLine(x0, barY, x0 + step * 0.72, barY, 200, 255, 220, alpha(40 * reveal), 7.0)
                end
            end
        end

        -- 8) HUD corner brackets at the screen corners.
        local ce = easeOut((t - 200.0) / 600.0)
        if ce > 0.0 then
            local m   = size * 0.06
            local arm = size * 0.05 * ce
            for _, sx in ipairs({ 0.0, 1.0 }) do
                for _, sy in ipairs({ 0.0, 1.0 }) do
                    local x = m + sx * (w - 2.0 * m)
                    local y = m + sy * (h - 2.0 * m)
                    local dx = (sx == 0.0) and 1.0 or -1.0
                    local dy = (sy == 0.0) and 1.0 or -1.0
                    ImGui.AddLine(x, y, x + dx * arm, y, 40, 255, 95, alpha(220), 3.0)
                    ImGui.AddLine(x, y, x, y + dy * arm, 40, 255, 95, alpha(220), 3.0)
                    ImGui.AddCircleFilled(x, y, 3.0, 220, 255, 230, alpha(255))
                end
            end
        end

        -- 9) Glitch slices on top of everything.
        if glitch > 0.0 then
            local seed  = math.floor(t / 50.0) * 13
            local count = math.floor(3 + 9 * glitch)
            for k = 1, count do
                local y  = rnd(seed + k) * h
                local hh = 2.0 + rnd(seed + k + 50) * (10.0 + 18.0 * glitch)
                local x0 = rnd(seed + k + 100) * w * 0.8
                local ww = w * (0.08 + 0.35 * rnd(seed + k + 150))
                local r, g, b = 40, 255, 95
                if k % 2 == 0 then r, g, b = 50, 220, 255 end
                if k % 5 == 0 then r, g, b = 255, 50, 200 end
                ImGui.AddLine(x0, y, x0 + ww, y, r, g, b, alpha(25 + 90 * glitch), hh)
            end
        end
    end

    Common.toast("Hulk Mode", K.SUITE_VERSION .. " loaded!", 3000)

    -- Sounds + camera shake on a timeline. Done from a script loop rather than
    -- the render callback, where natives are not safe. They honour the user's
    -- "Sound Effects" and "Camera Shake" settings.
    local TICK = { "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET" }
    local SLAM = { "ScreenFlash", "WastedSounds" }
    local events = {
        { 250, "tick" }, { 550, "tick" }, { 850, "tick" }, { 1150, "tick" }, { 1400, "tick" },
        { IMPACT_MS, "impact" }, { INTRO_MS - 800, "out" },
    }
    Script.RegisterLooped(function()
        if not introDone then
            local t = Time.GetEpocheMs() - introStart
            for i, ev in ipairs(events) do
                if not fired[i] and t >= ev[1] then
                    fired[i] = true
                    pcall(function()
                        if ev[2] == "tick" then
                            playSound(TICK)
                        elseif ev[2] == "impact" then
                            if cfg.shake then
                                Natives.InvokeVoid(K.NATIVE.SHAKE_GAMEPLAY_CAM, "SMALL_EXPLOSION_SHAKE", 0.7)
                            end
                            playSound(SLAM)
                            playSound(K.SND.rageMax)
                        else
                            playSound(K.SND.drop)
                        end
                    end)
                end
            end
        end
        Script.Yield()
    end)

    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        if introDone then
            return
        end
        local ok, err = pcall(drawIntro)
        if not ok then
            introDone = true   -- never let a drawing problem repeat every frame
            if tostring(err) ~= introError then
                introError = tostring(err)
                K.logError("in the intro animation: " .. introError)
            end
        end
    end)
end


-- Cleanup when the script is unloaded/reloaded (if this event exists on the
-- current Cherax build): put down whatever is carried and remove the glow.
if eLuaEvent ~= nil and eLuaEvent.ON_UNLOAD ~= nil then
    pcall(function()
        EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
            pcall(K.saveQuestProgress, true)   -- keep points / level / active quests
            pcall(releaseWithoutThrowing)
            pcall(clearTargetHighlight)
            pcall(K.PG.cleanup)
        end)
    end)
end


-- ============================================================
--  INTERFACE (tab "HULK": page selector, pages "HULK Mode" and "Playground")
-- ============================================================

local function safeText(builder)
    local ok, text = pcall(builder)
    ImGui.Text(ok and tostring(text) or "(unavailable)")
end

local function hulkStatusLine()
    if not featureEnabled then
        return "Status: DISABLED - active le toggle Hulk Mode"
    end
    if pendingEntity ~= nil or pendingAttach ~= nil then
        return "Status: ACTIVE - grabbing..."
    end
    if carrying then
        local info = ""
        if cfg.trajectory and #traj.world > 0 then
            if traj.hit then
                info = string.format(" - impact ~%d m", math.floor(traj.total))
            else
                info = string.format(" - no impact within %d m", math.floor(traj.total))
            end
            if traj.playerInLine then info = info .. " - PLAYER IN THE LINE OF FIRE" end
        end
        if chargeFrac > 0.0 then
            return string.format("Status: ACTIVE - carrying a %s - charging %d pct", carriedKind, math.floor(chargeFrac * 100)) .. info
        end
        return "Status: ACTIVE - carrying a " .. carriedKind .. info
    end
    return "Status: ACTIVE - aim at a vehicle, NPC or object, then press " .. cfg.grabKeyName
end

local function rageLine()
    if not cfg.rage then
        return "Rage: off"
    end
    return string.format("Rage: %d pct  (power x%.2f)", math.floor(rageLevel), rageMultiplier())
end

local function statsLines()
    return string.format("Vehicles thrown: %d", stats.vehiclesThrown),
           string.format("Objects thrown: %d", stats.objectsThrown),
           string.format("NPCs thrown: %d", stats.npcsThrown),
           string.format("Punches landed: %d", stats.punchesLanded),
           string.format("Things grabbed: %d", stats.grabs),
           string.format("Max-charge throws: %d", stats.fullCharges),
           string.format("Walls smashed: %d", stats.sceneryHits),
           string.format("Max rage reached: %d", stats.rageMaxes),
           string.format("XP earned from actions: %d", stats.xpEarned),
           string.format("Best rampage: x%d", stats.bestRampage),
           string.format("Best combo: x%d", stats.bestCombo)
end

-- ---------------------------------------------------------------------
--  MENU ARCHITECTURE
--  One tab, "HULK", with a tab bar at the top. The Cherax API has no native
--  sub-tabs (one ClickGUI.AddTab per tab), so the pages are ImGui tabs
--  (BeginTabBar); if those can't be used, two buttons set K.ui.page. Layout:
--      HULK
--       |- tab "HULK Mode": every feature of the script, in sections
--       |- tab "Playground": fun features (sub-category "Companion")
--  A section = one child window drawn by one small function. To add a
--  category, write a section and add its name to a page list below.
--  Rule: never put a percent sign in text shown by the menu (use "pct").
-- ---------------------------------------------------------------------
local UI = {
    sections = {},    -- [name] = draw function
    pages = {
        {
            id = "hulk", title = "HULK Mode",
            sections = {
                -- core
                "Hulk Mode", "Controls", "Grab & Throw", "Super Punch", "Rage Mode", "Visual Effects",
                -- progression
                "Hulk Progression", "Quests", "Skills", "Level Unlocks", "Session Stats",
                -- safety and info
                "Safety", "Console", "Credits",
            },
        },
        { id = "playground", title = "Playground", sections = { "Companion", "Bodyguard" } },
    },
}

-- Registers a section. A section never breaks the menu: errors inside it are
-- caught (the child window is always closed) and logged once.
local function section(name, body)
    UI.sections[name] = function()
        if ClickGUI.BeginCustomChildWindow(name) then
            local ok, err = pcall(body)
            ClickGUI.EndCustomChildWindow()
            if not ok and UI["err_" .. name] ~= tostring(err) then
                UI["err_" .. name] = tostring(err)
                K.logError("menu section '" .. name .. "' failed: " .. tostring(err))
            end
        end
    end
end

-- ---------- page "HULK Mode" ----------

section("Hulk Mode", function()
    ClickGUI.RenderFeature(H.toggle)
    safeText(hulkStatusLine)
    safeText(rageLine)
end)

section("Controls", function()
    ClickGUI.RenderFeature(H.keyGrab)
    ClickGUI.RenderFeature(H.keyDrop)
    safeText(function() return cfg.grabKeyName .. ": grab / throw (hold = charged throw)" end)
    safeText(function() return cfg.dropKeyName .. ": gently put down" end)
    ImGui.Text("Left click (bare-handed): super punch")
    if cfg.grabKey == cfg.dropKey then
        ImGui.Text("Warning: both actions use the same key!")
    end
end)

section("Grab & Throw", function()
    ClickGUI.RenderFeature(H.charged)
    ClickGUI.RenderFeature(H.grabNpc)
    ClickGUI.RenderFeature(H.speed)
    ClickGUI.RenderFeature(H.radius)
    ClickGUI.RenderFeature(H.cleanup)
end)

section("Super Punch", function()
    ClickGUI.RenderFeature(H.punch)
    ClickGUI.RenderFeature(H.wideAim)
    ClickGUI.RenderFeature(H.softLock)
    ClickGUI.RenderFeature(H.punchSound)
    safeText(function()
        return "Punch sound: " .. ({ "Classic", "Heavy", "Brutal" })[cfg.punchSoundStyle]
    end)
    ClickGUI.RenderFeature(H.pspeed)
    ClickGUI.RenderFeature(H.prange)
    ClickGUI.RenderFeature(H.pdelay)
end)

section("Rage Mode", function()
    ClickGUI.RenderFeature(H.rage)
    ClickGUI.RenderFeature(H.rageBonus)
end)

section("Visual Effects", function()
    ClickGUI.RenderFeature(H.highlight)
    ClickGUI.RenderFeature(H.shake)
    ClickGUI.RenderFeature(H.impact)
    ClickGUI.RenderFeature(H.cross)
    ClickGUI.RenderFeature(H.trajectory)
    ClickGUI.RenderFeature(H.trajChargeOnly)
    ClickGUI.RenderFeature(H.trajGravity)
    ClickGUI.RenderFeature(H.trajLength)
    ClickGUI.RenderFeature(H.sounds)
end)

section("Hulk Progression", function()
    ClickGUI.RenderFeature(H.xp)
    safeText(K.xpStatusText)
    ImGui.Text("Throw: vehicle +25, NPC +15, object +10. Super punch +10")
    ImGui.Text("Direct impact +30, combo bonus +20 (vehicle hits an NPC)")
    ImGui.Text("Multi hit +15 to +50, chain reaction +25")
    ImGui.Text("Airborne hit +15, heavy impact +20")
    ImGui.Text("Rampage x3 / x5 / x10: flat bonus + XP multiplier")
    ImGui.Text("Repeating the same target pays less (anti-farm)")
    ImGui.Text("XP fills the same level bar as the quests")
end)

section("Quests", function()
    ClickGUI.RenderFeature(H.quests)
    safeText(function()
        local _, lvl, _, _, _, title = questSummary()
        return string.format("Level %d  -  %s", lvl, title)
    end)
    safeText(function()
        local pts, _, _, into, need = questSummary()
        return string.format("Points: %d  (%d / %d to next level)", pts, into, need)
    end)
    safeText(function() return string.format("Quests completed: %d", (select(3, questSummary()))) end)
    safeText(K.questLifetimeText)
    ImGui.Text("A daily challenge (double reward) is shown under the quests")
    ImGui.Text("Progress is saved automatically (and when the script is unloaded)")
    ImGui.Text("F8: show / hide the quest panel")
end)

section("Skills", function()
    safeText(function()
        local free, spent = K.skillPointsFree()
        return string.format("Skill points: %d free  (%d spent)", free, spent)
    end)
    for _, s in ipairs(K.SKILLS) do
        local id = s.id
        safeText(function() return K.skillLine(id) end)
        ClickGUI.RenderFeature(K.SKILL_HASH[id])
    end
    ClickGUI.RenderFeature(H.skillReset)
    ImGui.Text("You earn 1 skill point every time you gain a level.")
end)

section("Level Unlocks", function()
    ImGui.Text("LV 4: 4th quest slot.  LV 8: 5th quest slot.")
    for _, u in ipairs(K.UNLOCKS) do
        local lv, name, desc = u[1], u[2], u[3]
        safeText(function()
            return string.format("%s  LV %d %s: %s", (K.playerLevel >= lv) and "[UNLOCKED]" or "[LOCKED]", lv, name, desc)
        end)
    end
end)

section("Session Stats", function()
    for i = 1, 11 do
        safeText(function() return (select(i, statsLines())) end)
    end
end)

section("Safety", function()
    ClickGUI.RenderFeature(H.safe)
    ClickGUI.RenderFeature(H.friends)
    ClickGUI.RenderFeature(H.friendAdd)
    ClickGUI.RenderFeature(H.friendClear)
    safeText(K.friendsText)
    ImGui.Text("Friends Mode only lifts Safe Mode for vehicles holding listed players.")
    ImGui.Text("Only add friends who agreed. Players on foot are never affected.")
end)

section("Console", function()
    ClickGUI.RenderFeature(H.debug)
    ImGui.Text("Off: the console only shows important information and errors.")
    ImGui.Text("On: every grab, throw and punch is also printed (for debugging).")
end)

section("Credits", function()
    ImGui.Text("Hulk Mode script created by " .. K.CREDITS_AUTHOR)
    ImGui.Text("Join the Discord for updates and support:")
    ClickGUI.RenderFeature(H.discord)
    ImGui.Text(K.DISCORD_URL)
end)

-- ---------- page "Playground" ----------

section("Companion", function()
    ClickGUI.RenderFeature(H.companion)
    safeText(K.PG.statusText)
    safeText(function() return "Selected: " .. K.PG.PETS[cfg.companionType][1] end)
    for i = 1, #K.PG.PETS do
        ClickGUI.RenderFeature(K.PG.PICK[i])
    end
    ClickGUI.RenderFeature(H.petSpeed)
    ClickGUI.RenderFeature(H.petInvincible)
    ClickGUI.RenderFeature(H.petCall)
    ClickGUI.RenderFeature(H.petRespawn)
    ImGui.Text("Only you can see your companion.")
end)

section("Bodyguard", function()
    ClickGUI.RenderFeature(H.guard)
    safeText(K.PG.guardText)
    safeText(function() return "Weapon: " .. K.PG.WEAPONS[cfg.guardWeapon][1] end)
    for i = 1, #K.PG.WEAPONS do
        ClickGUI.RenderFeature(K.PG.WPICK[i])
    end
    ClickGUI.RenderFeature(H.guardRadius)
    ClickGUI.RenderFeature(H.guardHolster)
    ImGui.Text("Weapons are used by human companions (Security Guard, Black Ops, SWAT)")
    ImGui.Text("and by the Chimp (a weapon in its hands; the script fires for it).")
    ImGui.Text("Other animals fight with their teeth. Your companion never attacks you;")
    ImGui.Text("players and police are never targeted.")
    ImGui.Text("Chimp weapon: attached to its hand, fine-tune it live while it holds the weapon.")
    safeText(function() return "Weapon bone: " .. K.PG.GUN_BONES[cfg.monkeyBone or 1][1] end)
    ClickGUI.RenderFeature(H.mgBone)
    ClickGUI.RenderFeature(H.mgReset)
    ImGui.Text("Offsets below are relative to the hand (0 = on the grip):")
    for _, hash in ipairs({ H.mgX, H.mgY, H.mgZ, H.mgRX, H.mgRY, H.mgRZ }) do
        ClickGUI.RenderFeature(hash)
    end
end)

-- ---------- navigation + tab ----------
-- Preferred navigation: a real tab bar (ImGui.BeginTabBar / BeginTabItem) with
-- one clickable tab per page. These ImGui calls are not documented with
-- signatures for Cherax, so every call is protected (pcall) and a few argument
-- shapes are tried once; the one that works is remembered. If the tab bar can't
-- be used at all, the menu falls back to the two "page" buttons (section
-- "Navigation") and keeps working. See UI.tabBar (false = fallback).

-- Section "Navigation": the fallback page selector (buttons).
section("Navigation", function()
    ClickGUI.RenderFeature(H.navHulk)
    ClickGUI.RenderFeature(H.navPlay)
    safeText(function()
        for _, p in ipairs(UI.pages) do
            if p.id == K.ui.page then return "Current page: " .. p.title end
        end
        return "Current page: ?"
    end)
end)

local function drawPageSections(page)
    for _, name in ipairs(page.sections) do
        UI.sections[name]()
    end
end

-- Calls ImGui.<fn> with the argument shape that works. Returns ok, result.
-- (ok = false when no shape could be called, i.e. the function is unusable.)
local function callImGui(fn, shapes)
    local f = ImGui[fn]
    if type(f) ~= "function" then return false end
    if UI.shape == nil then UI.shape = {} end
    local known = UI.shape[fn]
    if known then
        local ok, res = pcall(f, table.unpack(shapes[known]))
        if ok then return true, res end
        return false
    end
    for i, args in ipairs(shapes) do
        local ok, res = pcall(f, table.unpack(args))
        if ok then UI.shape[fn] = i; return true, res end
    end
    return false
end

-- Draws the tab bar and the selected page. Returns false if the tab bar API
-- could not be used (the caller then switches to the buttons).
local function drawTabBar()
    local okBar, barOpen = callImGui("BeginTabBar", { { "HulkPages", 0 }, { "HulkPages" } })
    if not okBar then return false end
    local usable = true
    if barOpen then
        for _, page in ipairs(UI.pages) do
            local title = page.title
            local okItem, selected = callImGui("BeginTabItem", { { title }, { title, 0 }, { title, true, 0 } })
            if not okItem then usable = false; break end
            if selected then
                K.ui.page = page.id
                drawPageSections(page)
                pcall(ImGui.EndTabItem)
            end
        end
        pcall(ImGui.EndTabBar)
    end
    return usable
end

ClickGUI.AddTab("HULK", function()
    if UI.tabBar ~= false then
        local ok, usable = pcall(drawTabBar)
        if ok and usable then return end
        UI.tabBar = false
        K.logWarn("tab bar unavailable (" .. tostring(ok and "no usable signature" or usable) .. "), using page buttons")
    end
    -- Fallback: page buttons + the selected page.
    UI.sections["Navigation"]()
    for _, page in ipairs(UI.pages) do
        if page.id == K.ui.page then drawPageSections(page) break end
    end
end)
end -- end HULK MODE v3.7