-- bodyguard squad
-- cherax lua script. needs Lua\natives\natives.lua next to it, grab that from
-- SATTY91's Cherax-Lua-API-Documentation repo or nothing in here loads.
--
-- player targeting is OFF by default. only flip it on in a private lobby where
-- everyone has actually said yes.
--
-- notes to self
-- ------------
-- 05/08  found the escort bug. it was squad.ready. one line. the thing that
--        arms every background loop went missing in the gui rewrite, so
--        convoy_tick / ai_tick / settings_tick / flip_tick / the whole lot
--        never ran once. escorts get ALL their orders from those ticks.
--        bodyguards don't (they ride the player ped group) which is exactly
--        why only the convoy looked dead and I kept digging in the wrong file.
--        also why they seemed invincible: settings_tick is what clears the
--        spawn-time god flag, and it wasn't running either.
-- 05/08  players were never targeted either. IS_PED_IN_COMBAT is an npc state
--        flag, a real player never sets it, so find_threats literally could
--        not see them. asks it backwards now, see player_is_hostile.
-- 05/08  ensure_control was locking migration in the branch where we'd just
--        found out we DON'T own the entity. backwards. and it re-checked
--        HAS_CONTROL in the same frame as the request, way too early.
-- 05/08  killable-by-me off made the squad bulletproof to EVERYONE, not just
--        me. rel group is shared by all players. overridden in pvp now.
-- 05/08  friend-safe models, spam protection eats freemode peds
--
-- older stuff that still matters:
--   gunners need a one-handed weapon in a vehicle or every driveby order is a
--   no-op. FULL_AUTO breaks minigun / rpg / snipers. never SET_PED_KEEP_TASK a
--   gunner. never CLEAR_PED_TASKS on a timer. never re-apply mission-entity or
--   the relationship group on a timer, both wipe ai state.
--
-- editing: WEAPON_CATS / MODEL_CATS / VEHICLE_DB near the top are just lists,
-- add rows. new pistols and smgs MUST go in the Pistols or SMGs category, that
-- is what marks them driveby capable.

if PED == nil or STREAMING == nil then
    package.path = package.path .. ";" .. FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua"
    local ok, err = pcall(require, "natives/natives")
    if STREAMING == nil then
        GUI.AddToast("Bodyguard Squad V3", "Missing Lua\\natives\\natives.lua - script disabled.", 6000)
        Logger.LogError("[Bodyguard Squad V3] natives failed to load: " .. tostring(err))
        return
    end
end

-- ==== Tweakables & Configuration Options ====

local MAX_BODYGUARDS = 7          -- Engine limit for group members
local THREAT_RANGE   = 300.0      -- Engagement detection distance
local FULL_AUTO      = 0xC6EE6B4C -- Firing pattern hash (holds trigger down)

-- Weapon menu. Categories 1 and 2 (Pistols / SMGs) are the one-handed ones
-- that actually work for drivebys, that matters, see DRIVEBY_OK below.
local WEAPON_CATS = {
    { n = "Pistols", list = {
        { n = "Pistol",           w = "WEAPON_PISTOL" },
        { n = "Combat Pistol",    w = "WEAPON_COMBATPISTOL" },
        { n = "AP Pistol",        w = "WEAPON_APPISTOL" },
        { n = "Heavy Pistol",     w = "WEAPON_HEAVYPISTOL" },
        { n = "Pistol .50",       w = "WEAPON_PISTOL50" },
        { n = "SNS Pistol",       w = "WEAPON_SNSPISTOL" },
        { n = "Heavy Revolver",   w = "WEAPON_REVOLVER" },
        { n = "Machine Pistol",   w = "WEAPON_MACHINEPISTOL" },
    }},
    { n = "SMGs", list = {
        { n = "Micro SMG",        w = "WEAPON_MICROSMG" },
        { n = "SMG",              w = "WEAPON_SMG" },
        { n = "Assault SMG",      w = "WEAPON_ASSAULTSMG" },
        { n = "Combat PDW",       w = "WEAPON_COMBATPDW" },
        { n = "Mini SMG",         w = "WEAPON_MINISMG" },
    }},
    { n = "Shotguns", list = {
        { n = "Pump Shotgun",     w = "WEAPON_PUMPSHOTGUN" },
        { n = "Assault Shotgun",  w = "WEAPON_ASSAULTSHOTGUN" },
        { n = "Combat Shotgun",   w = "WEAPON_COMBATSHOTGUN" },
        { n = "Heavy Shotgun",    w = "WEAPON_HEAVYSHOTGUN" },
    }},
    { n = "Assault Rifles", list = {
        { n = "Assault Rifle",    w = "WEAPON_ASSAULTRIFLE" },
        { n = "Carbine Rifle",    w = "WEAPON_CARBINERIFLE" },
        { n = "Advanced Rifle",   w = "WEAPON_ADVANCEDRIFLE" },
        { n = "Special Carbine",  w = "WEAPON_SPECIALCARBINE" },
        { n = "Bullpup Rifle",    w = "WEAPON_BULLPUPRIFLE" },
        { n = "Military Rifle",   w = "WEAPON_MILITARYRIFLE" },
    }},
    { n = "LMGs", list = {
        { n = "MG",               w = "WEAPON_MG" },
        { n = "Combat MG",        w = "WEAPON_COMBATMG" },
        { n = "Gusenberg Sweeper",w = "WEAPON_GUSENBERG" },
    }},
    { n = "Snipers", list = {
        { n = "Sniper Rifle",     w = "WEAPON_SNIPERRIFLE" },
        { n = "Heavy Sniper",     w = "WEAPON_HEAVYSNIPER" },
        { n = "Marksman Rifle",   w = "WEAPON_MARKSMANRIFLE" },
    }},
    { n = "Heavy", list = {
        { n = "RPG",              w = "WEAPON_RPG" },
        { n = "Minigun",          w = "WEAPON_MINIGUN" },
        { n = "Grenade Launcher", w = "WEAPON_GRENADELAUNCHER" },
    }},
    { n = "Melee", list = {
        { n = "Knife",            w = "WEAPON_KNIFE" },
        { n = "Bat",              w = "WEAPON_BAT" },
        { n = "Machete",          w = "WEAPON_MACHETE" },
        { n = "Battle Axe",       w = "WEAPON_BATTLEAXE" },
    }},
}

-- pre-hash everything once so we're not calling Joaat every frame
for _, cat in ipairs(WEAPON_CATS) do
    for _, wep in ipairs(cat.list) do wep.h = Utils.Joaat(wep.w) end
end

-- Weapons a ped can actually fire from inside a vehicle. Anything two-handed
-- (rifle, shotgun, LMG...) just makes them sit there doing nothing, which is
-- exactly the bug this fixes. Categories 1-2 = pistols + SMGs.
local DRIVEBY_OK = {}
for ci = 1, 2 do
    for _, wep in ipairs(WEAPON_CATS[ci].list) do DRIVEBY_OK[wep.h] = true end
end

-- FULL_AUTO on these breaks the AI: it queues a burst that never fires, so
-- you get one shot every few seconds (the classic "minigun does nothing").
local NO_FULL_AUTO = {}
for _, name in ipairs({ "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_GRENADELAUNCHER",
                        "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_MARKSMANRIFLE",
                        "WEAPON_KNIFE", "WEAPON_BAT", "WEAPON_MACHETE", "WEAPON_BATTLEAXE" }) do
    NO_FULL_AUTO[Utils.Joaat(name)] = true
end

-- Weapons that already explode - don't double-boom them with Explosive Rounds
local EXP_WEAPON_SKIP = {
    [Utils.Joaat("WEAPON_RPG")] = true,
    [Utils.Joaat("WEAPON_GRENADELAUNCHER")] = true,
}

-- Ped models. "CLONE" and "CUSTOM" are special-cased in spawn_squad_ped.
local MODEL_CATS = {
    { n = "Special", list = {
        { n = "Clone of You",        m = "CLONE" },
        { n = "Custom (text field)", m = "CUSTOM" },
    }},
    { n = "Story Characters", list = {
        { n = "Michael",   m = "player_zero" },
        { n = "Franklin",  m = "player_one" },
        { n = "Trevor",    m = "player_two" },
        { n = "Lamar",     m = "ig_lamardavis" },
        { n = "Jimmy",     m = "ig_jimmydisanto" },
        { n = "Wade",      m = "ig_wade" },
        { n = "Ron",       m = "ig_ron" },
        { n = "Lester",    m = "ig_lestercrest" },
    }},
    { n = "Military", list = {
        { n = "Blackops 1",   m = "s_m_y_blackops_01" },
        { n = "Blackops 2",   m = "s_m_y_blackops_02" },
        { n = "Blackops 3",   m = "s_m_y_blackops_03" },
        { n = "Marine 1",     m = "s_m_y_marine_01" },
        { n = "Marine 2",     m = "s_m_y_marine_02" },
        { n = "Marine 3",     m = "s_m_y_marine_03" },
        { n = "Marine Officer", m = "s_m_m_marine_01" },
        { n = "Juggernaut",   m = "u_m_y_juggernaut_01" },
        { n = "Pilot",        m = "s_m_y_pilot_01" },
    }},
    { n = "Law Enforcement", list = {
        { n = "LSPD Male",      m = "s_m_y_cop_01" },
        { n = "LSPD Female",    m = "s_f_y_cop_01" },
        { n = "Sheriff",        m = "s_m_y_sheriff_01" },
        { n = "Highway Patrol", m = "s_m_y_hwaycop_01" },
        { n = "NOOSE/SWAT",     m = "s_m_y_swat_01" },
        { n = "Ranger",         m = "s_m_y_ranger_01" },
        { n = "Prison Guard",   m = "s_m_y_prisguard_01" },
        { n = "Security",       m = "s_m_m_security_01" },
        { n = "FIB Agent",      m = "s_m_m_fiboffice_01" },
    }},
    { n = "Civilians", list = {
        { n = "Businessman",   m = "a_m_y_business_01" },
        { n = "Business Woman",m = "a_f_y_business_01" },
        { n = "Bouncer",       m = "s_m_m_bouncer_01" },
        { n = "Construction",  m = "s_m_y_construct_01" },
        { n = "Hipster",       m = "a_m_y_hipster_01" },
        { n = "Fitness Girl",  m = "a_f_y_fitness_01" },
        { n = "Beach Bro",     m = "a_m_y_beach_01" },
        { n = "Farmer",        m = "a_m_m_farmer_01" },
    }},
    { n = "Gang Members", list = {
        { n = "Ballas",     m = "g_m_y_ballasout_01" },
        { n = "Families",   m = "g_m_y_famfor_01" },
        { n = "Lost MC",    m = "g_m_y_lost_01" },
        { n = "Vagos",      m = "g_m_y_mexgang_01" },
        { n = "Korean",     m = "g_m_y_korean_01" },
        { n = "Marabunta",  m = "g_m_y_salvaboss_01" },
    }},
    { n = "GTA Online", list = {
        { n = "Online Male",   m = "mp_m_freemode_01" },
        { n = "Online Female", m = "mp_f_freemode_01" },
    }},
    -- animals get no weapons and use mood instead of combat tasks
    { n = "Animals", list = {
        { n = "Rottweiler",    m = "a_c_rottweiler",  animal = true },
        { n = "Chop",          m = "a_c_chop",        animal = true },
        { n = "Husky",         m = "a_c_husky",       animal = true },
        { n = "Shepherd",      m = "a_c_shepherd",    animal = true },
        { n = "Retriever",     m = "a_c_retriever",   animal = true },
        { n = "Mountain Lion", m = "a_c_mtlion",      animal = true },
        { n = "Coyote",        m = "a_c_coyote",      animal = true },
        { n = "Boar",          m = "a_c_boar",        animal = true },
        { n = "Chimp",         m = "a_c_chimp_02",    animal = true },
        { n = "Cow",           m = "a_c_cow",         animal = true },
        { n = "Pig",           m = "a_c_pig",         animal = true },
    }},
}

-- spam protection drops freemode peds (mp_m/f_freemode_01) sent by other
-- players, that model is what the ped spammers use. the block runs on THEIR
-- machine so there's nothing I can flip on mine. guards standing right next to
-- me, invisible on their screens.
-- either they whitelist it, or I spawn something else. this is the something
-- else. clone-of-you is in the list because your online char is a freemode ped.
-- TODO would be nicer to read the whitelist off the friend's menu but there's
-- no api for that
local FRIEND_SAFE_SUBS = {
    ["CLONE"]            = "s_m_y_blackops_01",
    ["mp_m_freemode_01"] = "s_m_y_blackops_01",
    ["mp_f_freemode_01"] = "s_f_y_cop_01",
}

local function model_needs_sub(kind)
    return FRIEND_SAFE_SUBS[kind] ~= nil
end

local FORMATIONS = {
    { "Default", 0 }, { "Circle", 1 }, { "Loose Circle", 2 }, { "Line", 3 },
}

local BEHAVIOURS = {
    { "Defensive", 1 },
    { "Aggressive", 2 },
    { "Frontal Assault", 3 },
}

local ESCORT_MODES = {
    { "Passive",    "PASSIVE" },
    { "Defensive",  "DEFENSIVE" },
    { "Aggressive", "AGGRESSIVE" },
}

local BLIP_COLORS = {
    { "Blue", 3 }, { "Red", 1 }, { "Green", 2 }, { "Yellow", 5 },
    { "Orange", 17 }, { "Purple", 27 }, { "Pink", 8 }, { "White", 0 },
}

local DRIVE_STYLES = {
    { "Normal",   786603  },
    { "Rushed",   786468  },
    { "Reckless", 2883621 },
}

local CHAUFFEUR_STYLES = {
    { "Legal (obeys traffic laws)",      786603  },
    { "Rushed (fast, dodges obstacles)", 786468  },
    { "Reckless (straight through)",     2883621 },
}

-- TASK_VEHICLE_ESCORT modes: -1 auto, 0 rear, 1 lead, 2 left, 3 right
local CONVOY_STYLES = {
    { "Auto (closest)",  { -1 } },
    { "Diamond",         { 1, 0, 2, 3 } },
    { "Rear Guard",      { 0 } },
    { "Lead Convoy",     { 1 } },
    { "Flanking",        { 2, 3 } },
}

local EXPLOSION_TYPES = {
    { "Grenade", 0 }, { "Molotov", 3 }, { "Rocket", 4 }, { "Firework", 35 },
}

-- Master safety setting. Default keeps the squad off real players entirely.
local TARGET_POLICIES = {
    { "NPCs Only (safe)", false },
    { "NPCs + Players",   true  },
}

-- GTA paint IDs. First entry leaves the spawn colour alone.
local ESCORT_COLORS = {
    { "Keep Default", -1 },
    { "Black",        0   }, { "Matte Black",   12  },
    { "Graphite",     2   }, { "Silver",        4   },
    { "White",        111 }, { "Red",           27  },
    { "Matte Red",    39  }, { "Orange",        38  },
    { "Yellow",       88  }, { "Green",         49  },
    { "Army Green",   133 }, { "Blue",          64  },
    { "Light Blue",   70  }, { "Purple",        145 },
    { "Pink",         135 }, { "Gold",          90  },
    { "Chrome",       120 },
}

local VEHICLE_DB = {
    { "Limos & Misc", {
        { "Stretch Limo", "stretch" }, { "Patriot Stretch", "patriot2" },
        { "Turreted Limo", "limo2" },
        { "Romero Hearse", "romero" }, { "Taxi", "taxi" },
        { "Bus", "bus" }, { "Coach", "coach" },
        { "Tour Bus", "tourbus" }, { "Phantom Truck", "phantom" },
        { "Mule Truck", "mule" }, { "Journey RV", "journey" },
    }},
    { "Military & Armed", {
        { "Insurgent (turret)", "insurgent" }, { "Insurgent Custom", "insurgent3" },
        { "Insurgent Pick-Up", "insurgent2" },
        { "Technical (turret)", "technical" }, { "Technical Custom", "technical3" },
        { "Technical Aqua", "technical2" },
        { "Menacer", "menacer" }, { "Nightshark", "nightshark" },
        { "Caracara", "caracara" }, { "Caracara 4x4", "caracara2" },
        { "APC", "apc" }, { "Half-Track", "halftrack" },
        { "Barrage", "barrage" }, { "Rhino Tank", "rhino" },
        { "TM-02 Khanjali", "khanjali" }, { "Vetir", "vetir" },
        { "Armored Kuruma", "kuruma2" }, { "Duke O'Death", "dukes2" },
        { "Chernobog", "chernobog" }, { "Barracks", "barracks" },
        { "Barracks Semi", "barracks2" }, { "Crusader", "crusader" },
        { "Dune FAV", "dune3" }, { "Ramp Buggy", "dune4" },
        { "Scarab", "scarab" }, { "Brickade", "brickade" },
        { "Terrorbyte", "terbyte" }, { "Mobile Op Center", "trailersmall2" },
        { "Nightshark Armored", "nightshark" }, { "Kuruma (armored)", "kuruma2" },
    }},
    { "Anti-Air & Heavy", {
        { "Anti-Aircraft Trailer", "trailersmall2" },
        { "Barrage (AA guns)", "barrage" },
        { "Insurgent (turret)", "insurgent" },
        { "Technical (turret)", "technical" },
        { "Half-Track (twin guns)", "halftrack" },
        { "APC (cannon)", "apc" },
        { "Chernobog (missiles)", "chernobog" },
        { "Khanjali (railgun)", "khanjali" },
        { "Rhino Tank", "rhino" },
        { "Vetir", "vetir" },
        { "Scarab", "scarab" },
    }},
    { "Helicopters", {
        { "Buzzard (armed)", "buzzard" }, { "Buzzard (civilian)", "buzzard2" },
        { "Akula", "akula" }, { "Hunter", "hunter" },
        { "Savage", "savage" }, { "Valkyrie", "valkyrie" },
        { "Valkyrie MOD.0", "valkyrie2" },
        { "Annihilator", "annihilator" }, { "Annihilator Stealth", "annihilator2" },
        { "Maverick", "maverick" }, { "Police Maverick", "polmav" },
        { "SuperVolito", "supervolito" }, { "SuperVolito Carbon", "supervolito2" },
        { "Swift", "swift" }, { "Swift Deluxe", "swift2" },
        { "Volatus", "volatus" }, { "Havok", "havok" },
        { "Frogger", "frogger" }, { "Frogger 2", "frogger2" },
        { "Skylift", "skylift" }, { "Cargobob", "cargobob" },
        { "Sea Sparrow", "seasparrow" }, { "Sparrow", "seasparrow2" },
    }},
    { "Supers", {
        { "Adder", "adder" }, { "Zentorno", "zentorno" },
        { "T20", "t20" }, { "Osiris", "osiris" },
        { "Entity XF", "entityxf" }, { "Entity XXR", "entity2" },
        { "Turismo R", "turismor" }, { "X80 Proto", "prototipo" },
        { "Vagner", "vagner" }, { "Deveste Eight", "deveste" },
        { "Krieger", "krieger" }, { "Emerus", "emerus" },
        { "Furia", "furia" }, { "Nero", "nero" },
        { "Nero Custom", "nero2" }, { "XA-21", "xa21" },
        { "Tezeract", "tezeract" }, { "Infernus", "infernus" },
        { "Cheetah", "cheetah" }, { "Bullet", "bullet" },
        { "Reaper", "pfister811" }, { "Tyrant", "tyrant" },
        { "Autarch", "autarch" }, { "Thrax", "thrax" },
        { "Zorrusso", "zorrusso" }, { "S80RR", "s80" },
        { "Ignus", "ignus" }, { "Virtue", "virtue" },
        { "Vigilante", "vigilante" }, { "Deluxo", "deluxo" },
        { "Scramjet", "scramjet" }, { "Oppressor MK II", "oppressor2" },
    }},
    { "Sports", {
        { "Elegy RH8", "elegy2" }, { "Sultan", "sultan" },
        { "Kuruma", "kuruma" }, { "Jester", "jester" },
        { "Massacro", "massacro" }, { "Carbonizzare", "carbonizzare" },
        { "Comet", "comet2" }, { "9F", "ninef" },
        { "Banshee", "banshee" }, { "Coquette", "coquette" },
        { "Pariah", "pariah" }, { "Itali GTO", "italigto" },
        { "Neon", "neon" }, { "Jugular", "jugular" },
        { "Buffalo S", "buffalo2" },
    }},
    { "Muscle", {
        { "Dominator", "dominator" }, { "Gauntlet", "gauntlet" },
        { "Gauntlet Hellfire", "gauntlet4" }, { "Dukes", "dukes" },
        { "Sabre Turbo", "sabregt" }, { "Phoenix", "phoenix" },
        { "Ruiner", "ruiner" }, { "Vigero", "vigero" },
        { "Buccaneer", "buccaneer" }, { "Nightshade", "nightshade" },
        { "Yosemite", "yosemite" }, { "Vamos", "vamos" },
    }},
    { "Off-Road", {
        { "Sandking XL", "sandking" }, { "Rebel", "rebel2" },
        { "Brawler", "brawler" }, { "Trophy Truck", "trophytruck" },
        { "Kamacho", "kamacho" }, { "Riata", "riata" },
        { "Everon", "everon" }, { "Hellion", "hellion" },
        { "Freecrawler", "freecrawler" }, { "Bifta", "bifta" },
        { "BF Injection", "bfinjection" }, { "Dubsta 6x6", "dubsta3" },
    }},
    { "SUVs", {
        { "Baller", "baller" }, { "Baller LE", "baller2" },
        { "Cavalcade", "cavalcade" }, { "Granger", "granger" },
        { "Huntley S", "huntley" }, { "Landstalker", "landstalker" },
        { "Mesa", "mesa" }, { "Patriot", "patriot" },
        { "XLS", "xls" }, { "Novak", "novak" },
        { "Toros", "toros" }, { "Contender", "contender" },
    }},
    { "Sedans", {
        { "Tailgater", "tailgater" }, { "Schafter", "schafter2" },
        { "Premier", "premier" }, { "Fugitive", "fugitive" },
        { "Stanier", "stanier" }, { "Primo", "primo" },
        { "Asea", "asea" }, { "Glendale", "glendale" },
        { "Stafford", "stafford" }, { "Warrener", "warrener" },
        { "Stratum", "stratum" },
    }},
    { "Motorcycles", {
        { "Bati 801", "bati" }, { "Akuma", "akuma" },
        { "Hakuchou", "hakuchou" }, { "Double-T", "double" },
        { "PCJ 600", "pcj" }, { "Ruffian", "ruffian" },
        { "Sanchez", "sanchez" }, { "Gargoyle", "gargoyle" },
        { "Defiler", "defiler" }, { "Shotaro", "shotaro" },
        { "Daemon", "daemon" },
    }},
    { "Planes", {
        { "Lazer", "lazer" }, { "Hydra", "hydra" },
        { "Strikeforce", "strikeforce" }, { "Rogue", "rogue" },
        { "Pyro", "pyro" }, { "Molotok", "molotok" },
        { "Nokota", "nokota" }, { "Starling", "starling" },
        { "Howard NX-25", "howard" }, { "Seabreeze", "seabreeze" },
        { "Bombushka", "bombushka" }, { "Volatol", "volatol" },
        { "Avenger", "avenger" }, { "Titan", "titan" },
        { "Luxor", "luxor" }, { "Luxor Deluxe", "luxor2" },
        { "Shamal", "shamal" }, { "Vestra", "vestra" },
        { "Velum", "velum" }, { "Velum 5-Seater", "velum2" },
        { "Dodo", "dodo" }, { "Duster", "duster" },
        { "Cuban 800", "cuban800" }, { "Mammatus", "mammatus" },
    }},
    { "Vans & Trucks", {
        { "Burrito", "burrito" }, { "Speedo", "speedo" },
        { "Speedo Custom", "speedo4" }, { "Youga", "youga" },
        { "Youga Classic", "youga2" }, { "Gang Burrito", "gburrito" },
        { "Pony", "pony" }, { "Rumpo", "rumpo" },
        { "Paradise", "paradise" }, { "Bison", "bison" },
        { "Sadler", "sadler" }, { "Bobcat XL", "bobcatxl" },
        { "Packer", "packer" }, { "Hauler", "hauler" },
        { "Benson", "benson" }, { "Stockade", "stockade" },
        { "Boxville", "boxville" }, { "Pounder", "pounder" },
    }},
    { "Boats", {
        { "Dinghy", "dinghy" }, { "Jetmax", "jetmax" },
        { "Speeder", "speeder" }, { "Toro", "toro" },
        { "Marquis", "marquis" }, { "Squalo", "squalo" },
        { "Suntrap", "suntrap" }, { "Tropic", "tropic" },
        { "Predator", "predator" }, { "Longfin", "longfin" },
        { "Patrol Boat", "patrolboat" }, { "Kraken Sub", "submersible2" },
    }},
    { "Emergency", {
        { "Police Cruiser", "police" }, { "Police Cruiser 2", "police2" },
        { "Police Interceptor", "police3" }, { "Sheriff Cruiser", "sheriff" },
        { "Sheriff SUV", "sheriff2" }, { "FIB Buffalo", "fbi" },
        { "FIB Granger", "fbi2" }, { "Riot Van", "riot" },
        { "RCV", "riot2" }, { "Ambulance", "ambulance" },
        { "Fire Truck", "firetruk" }, { "Prison Bus", "pbus" },
        { "Police Transporter", "policet" },
    }},
    { "Custom", {
        { "(type model in the text field below)", "CUSTOM" },
    }},
}

------------------------------------------------------------
-- UI Hashes

local ui = {
    spawn_count   = Utils.Joaat("BGS_SpawnCount"),
    model_cat     = Utils.Joaat("BGS_ModelCat"),
    model_preset  = Utils.Joaat("BGS_ModelPreset"),
    guard_model   = Utils.Joaat("BGS_GuardModel"),
    killable      = Utils.Joaat("BGS_Killable"),
    spawn_guard   = Utils.Joaat("BGS_SpawnGuard"),
    spawn_clone   = Utils.Joaat("BGS_SpawnClone"),
    random_outfit = Utils.Joaat("BGS_RandomOutfit"),
    friend_safe   = Utils.Joaat("BGS_FriendSafeModels"),
    pri_cat       = Utils.Joaat("BGS_PrimaryCat"),
    primary       = Utils.Joaat("BGS_PrimaryWeapon"),
    sec_cat       = Utils.Joaat("BGS_SecondaryCat"),
    secondary     = Utils.Joaat("BGS_SecondaryWeapon"),
    give_primary  = Utils.Joaat("BGS_GivePrimary"),
    give_secondary= Utils.Joaat("BGS_GiveSecondary"),
    apply_loadout = Utils.Joaat("BGS_ApplyLoadout"),
    exp_rounds    = Utils.Joaat("BGS_ExplosiveRounds"),
    exp_type      = Utils.Joaat("BGS_ExplosionType"),
    god           = Utils.Joaat("BGS_Invincible"),
    no_ragdoll    = Utils.Joaat("BGS_NoRagdoll"),
    invisible     = Utils.Joaat("BGS_Invisible"),
    local_visible = Utils.Joaat("BGS_LocallyVisible"),
    auto_respawn  = Utils.Joaat("BGS_AutoRespawn"),
    auto_heal     = Utils.Joaat("BGS_AutoHeal"),
    auto_revive   = Utils.Joaat("BGS_AutoRevive"),
    revive_delay  = Utils.Joaat("BGS_ReviveDelay"),
    callouts      = Utils.Joaat("BGS_Callouts"),
    accuracy      = Utils.Joaat("BGS_Accuracy"),
    health        = Utils.Joaat("BGS_Health"),
    armor         = Utils.Joaat("BGS_Armor"),
    blip_color    = Utils.Joaat("BGS_BlipColor"),
    formation     = Utils.Joaat("BGS_Formation"),
    spacing       = Utils.Joaat("BGS_Spacing"),
    behaviour     = Utils.Joaat("BGS_Behaviour"),
    esp_name      = Utils.Joaat("BGS_EspName"),
    esp_health    = Utils.Joaat("BGS_EspHealth"),
    esp_distance  = Utils.Joaat("BGS_EspDistance"),
    esp_tracer    = Utils.Joaat("BGS_EspTracer"),
    rally         = Utils.Joaat("BGS_RallySquad"),
    auto_tp       = Utils.Joaat("BGS_AutoTeleport"),
    tp_distance   = Utils.Joaat("BGS_AutoTeleportDist"),
    tp_all        = Utils.Joaat("BGS_TeleportAll"),
    heal_all      = Utils.Joaat("BGS_HealAll"),
    warp_in_veh   = Utils.Joaat("BGS_WarpIntoVehicle"),
    steal_cars    = Utils.Joaat("BGS_StealCars"),
    dismiss_all   = Utils.Joaat("BGS_DismissAll"),
    del_guards    = Utils.Joaat("BGS_DeleteGuards"),
    protect_sel   = Utils.Joaat("BGS_ProtectSelected"),
    protect_me    = Utils.Joaat("BGS_ProtectMe"),
    protect_spawn = Utils.Joaat("BGS_ProtectSpawnEscorts"),
    protect_guards= Utils.Joaat("BGS_ProtectSpawnGuards"),
    protect_tp    = Utils.Joaat("BGS_ProtectTeleport"),
    allow_players = Utils.Joaat("BGS_AllowPlayerTargets"),
    hunt_sel      = Utils.Joaat("BGS_HuntSelected"),
    hunt_bg       = Utils.Joaat("BGS_HuntGuards"),
    hunt_esc      = Utils.Joaat("BGS_HuntEscorts"),
    hunt_airsend  = Utils.Joaat("BGS_HuntAirSend"),
    hunt_clear    = Utils.Joaat("BGS_HuntClear"),
    esc_color     = Utils.Joaat("BGS_EscortColor"),
    pursuit       = Utils.Joaat("BGS_PursuitTime"),
    engage_range  = Utils.Joaat("BGS_EngageRange"),
    esc_range     = Utils.Joaat("BGS_EscortEngageRange"),
    esc_despawn   = Utils.Joaat("BGS_EscortDespawn"),
    air_alt       = Utils.Joaat("BGS_AirAltitude"),
    esc_upgrade   = Utils.Joaat("BGS_EscortUpgrade"),
    protect_heal  = Utils.Joaat("BGS_ProtectHeal"),
    protect_air   = Utils.Joaat("BGS_ProtectAirCover"),
    hunt_ambush   = Utils.Joaat("BGS_HuntAmbush"),
    hunt_surround = Utils.Joaat("BGS_HuntSurround"),
    hunt_air      = Utils.Joaat("BGS_HuntAirStrike"),
    jackable      = Utils.Joaat("BGS_EscortJackable"),
    auto_promote  = Utils.Joaat("BGS_EscortAutoPromote"),
    esc_model_cat = Utils.Joaat("BGS_EscortModelCat"),
    esc_model     = Utils.Joaat("BGS_EscortModel"),
    esc_model_txt = Utils.Joaat("BGS_EscortModelText"),
    esc_veh_cat   = Utils.Joaat("BGS_EscortVehCategory"),
    esc_veh_model = Utils.Joaat("BGS_EscortVehModel"),
    esc_veh_text  = Utils.Joaat("BGS_EscortVehicleText"),
    esc_count     = Utils.Joaat("BGS_EscortCount"),
    esc_fill      = Utils.Joaat("BGS_EscortFill"),
    esc_mode      = Utils.Joaat("BGS_EscortMode"),
    esc_style     = Utils.Joaat("BGS_EscortStyle"),
    convoy_style  = Utils.Joaat("BGS_ConvoyStyle"),
    esc_distance  = Utils.Joaat("BGS_EscortDistance"),
    esc_god_veh   = Utils.Joaat("BGS_EscortGodVehicles"),
    esc_tune      = Utils.Joaat("BGS_EscortMaxTune"),
    esc_strong    = Utils.Joaat("BGS_EscortStrong"),
    auto_flip     = Utils.Joaat("BGS_EscortAutoFlip"),
    searchlight   = Utils.Joaat("BGS_EscortSearchlight"),
    sirens        = Utils.Joaat("BGS_EscortSirens"),
    blackout      = Utils.Joaat("BGS_EscortBlackout"),
    heli_land     = Utils.Joaat("BGS_HeliLand"),
    chf_style     = Utils.Joaat("BGS_ChauffeurStyle"),
    chf_speed     = Utils.Joaat("BGS_ChauffeurSpeed"),
    esc_spawn     = Utils.Joaat("BGS_EscortSpawn"),
    esc_tp        = Utils.Joaat("BGS_EscortTeleport"),
    esc_heal      = Utils.Joaat("BGS_EscortHeal"),
    esc_delete    = Utils.Joaat("BGS_EscortDelete"),
}

-- Internal Squad State
--------------------------

local squad = {
    guards          = {},
    escorts         = {},
    guard_info      = {},
    escorts_alive   = 0,
    threat_count    = 0,
    respawn_queue   = {},
    targets         = {},
    gunner_stage    = {},   -- [ped] = which firing method we're trying
    gunner_check    = {},   -- [ped] = when to verify they're actually firing
    gunner_locked   = {},   -- [ped] = true once a working method is found
    gunner_method   = {},   -- [ped] = the method that actually worked
    gunner_shot     = {},   -- [ped] = last time we saw them actually fire
    guard_check     = {},   -- [ped] = next allowed combat re-issue
    veh_armed       = {},   -- [ped] = "gun" / "turret" while seated, nil on foot
    engage_at       = {},   -- [ped] = next refresh for shoot-at-vehicle orders
    flipped_since   = {},   -- [veh] = when it first went over on its side
    protect_id      = nil,  -- player id whose bodyguard duty we're on
    hunt_id         = nil,  -- player id the squad has been sent after
    -- which parts of the force are actually committed to that target
    hunt_groups     = { guards = false, escorts = false, air = false },
    fault           = {},   -- [tick name] = how many times it has errored
    ped_sig         = {},   -- [ped] = settings signature already applied
    last_player_ped = 0,
    vendetta        = {},
    guards_engaged  = false,
    engaged         = false,
    follow_issued   = {},
    convoy_key      = "",
    bg_group        = nil,   -- our own relationship group hash
    rel_refresh_at  = 0,
    next_convoy_at  = 0,
    next_ai_at      = 0,
    next_follow_at  = 0,
    next_status_at  = 0,
    next_apply_at   = 0,
    next_weapon_at  = 0,
    next_revive_at  = 0,
    last_boom       = 0,
    ready           = false,
}

------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------

local function toast(msg) GUI.AddToast("Bodyguard Squad V3", msg, 3000) end
local function feat(id) return FeatureMgr.GetFeature(id) end
local function picked(id, list) return list[feat(id):GetListIndex() + 1] end
local function player_ped() return PLAYER.PLAYER_PED_ID() end

local function load_model(hash)
    if not STREAMING.IS_MODEL_VALID(hash) then return false end
    STREAMING.REQUEST_MODEL(hash)
    local tries = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and tries < 200 do
        Script.Yield(10)
        tries = tries + 1
    end
    return STREAMING.HAS_MODEL_LOADED(hash)
end

local function offset_from(ped, right, forward)
    return ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, right, forward, 0.0)
end

local function offset_from_player(right, forward)
    return offset_from(player_ped(), right, forward)
end

local function alive(ent)
    return ent ~= nil and ent ~= 0 and ENTITY.DOES_ENTITY_EXIST(ent) and not ENTITY.IS_ENTITY_DEAD(ent)
end

-- alive() alone isn't enough for shooting decisions: a ped mid death-animation
-- still reads as alive for a moment, so gunners keep shooting the corpse
local function good_target(ped)
    return alive(ped) and not PED.IS_PED_DEAD_OR_DYING(ped, true)
end

-- DELETE_ENTITY / REMOVE_BLIP want a memory address holding the id, not the id
local function call_with_ptr(native_fn, id)
    local ptr = Memory.AllocInt()
    Memory.WriteInt(ptr, id)
    native_fn(ptr)
    Memory.Free(ptr)
end

local function delete_entity(ent)
    if ent == nil or ent == 0 or not ENTITY.DOES_ENTITY_EXIST(ent) then return end
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, true)
    if ENTITY.IS_ENTITY_A_PED(ent) then
        PED.REMOVE_PED_FROM_GROUP(ent)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ent)
    end
    ENTITY.SET_ENTITY_COLLISION(ent, false, false)
    ENTITY.SET_ENTITY_VISIBLE(ent, false, false)
    ENTITY.FREEZE_ENTITY_POSITION(ent, true)
    call_with_ptr(ENTITY.DELETE_ENTITY, ent)
end

local function remove_blip(blip)
    if blip == nil or blip == 0 then return end
    pcall(function()
        HUD.SET_BLIP_ALPHA(blip, 0)
        HUD.SET_BLIP_DISPLAY(blip, 0)
    end)
    pcall(call_with_ptr, HUD.REMOVE_BLIP, blip)
end

-- stops the game cleaning them up. ONCE per entity only, calling it again
-- re-registers the ped and wipes whatever it was doing.
local mission_marked = {}
local function keep_alive(ent)
    if ent == nil or ent == 0 or mission_marked[ent] then return end
    if not ENTITY.DOES_ENTITY_EXIST(ent) then return end
    mission_marked[ent] = true
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, true)
    pcall(ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG, ent, true, 0)
end

-- online you can only give a networked entity orders if your machine owns it
-- right now. no control, task silently binned, ped just sits there.
--
-- the old version of this had it backwards. it locked migration off
-- (SET_NETWORK_ID_CAN_MIGRATE false) inside the branch where we'd JUST found
-- out we don't own the thing, which pins ownership away from us instead of
-- towards us. on top of that REQUEST_CONTROL is async and it re-checked
-- HAS_CONTROL in the same frame, so it took the bad branch nearly every time.
-- so: ask, wait a tick, and only pin once it's actually ours.
local net_pinned   = {}   -- [ent] = we're holding the migration lock
local net_last_req = {}   -- [ent] = last time we asked

local function net_in_session()
    if NETWORK.NETWORK_IS_SESSION_STARTED == nil then return true end
    local ok, r = pcall(NETWORK.NETWORK_IS_SESSION_STARTED)
    if not ok then return true end
    return r and true or false
end

-- an entity that was never network-registered (story mode, or a local-only
-- spawn) is always ours; don't run any of the ownership dance on it
local function net_is_networked(ent)
    if NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED == nil then return true end
    local ok, r = pcall(NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED, ent)
    if not ok then return true end
    return r and true or false
end

-- nil = the native itself blew up. don't treat that as "mine" or we end up
-- pinning something someone else owns, which is how this broke the first time.
local function net_has_control(ent)
    local ok, r = pcall(NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY, ent)
    if not ok then return nil end
    return r and true or false
end

-- TODO check whether pinning migration is even worth it once everyone's on
-- the same build. works fine as is though so leaving it.
local function net_set_migrate(ent, allowed)
    pcall(function()
        local nid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(ent)
        if nid == nil or nid == 0 then return end
        if allowed == false and NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES ~= nil then
            NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(nid, true)
        end
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(nid, allowed)
    end)
end

local function ensure_control(ent, now)
    if ent == nil or ent == 0 then return false end
    if not ENTITY.DOES_ENTITY_EXIST(ent) then return false end
    if not net_in_session() or not net_is_networked(ent) then return true end

    local mine = net_has_control(ent)
    if mine == nil then return true end -- no idea, leave it alone
    if mine then
        squad.net_owned = (squad.net_owned or 0) + 1
        if not net_pinned[ent] then   -- ours, so pinning keeps it ours
            net_pinned[ent] = true
            net_set_migrate(ent, false)
        end
        return true
    end

    squad.net_lost = (squad.net_lost or 0) + 1
    -- lost it. drop our own lock or it fights the hand-back
    if net_pinned[ent] then
        net_pinned[ent] = nil
        net_set_migrate(ent, true)
    end
    now = now or Time.GetEpocheMs()
    if now - (net_last_req[ent] or 0) > 200 then
        net_last_req[ent] = now
        pcall(NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY, ent)
    end
    return false
end

-- handles get recycled, so wipe our bookkeeping when one dies. otherwise a
-- fresh ped inherits "already pinned" from whoever had that slot before.
local function net_forget(ent)
    if ent == nil or ent == 0 then return end
    net_pinned[ent] = nil
    net_last_req[ent] = nil
    mission_marked[ent] = nil
end

local function dist(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function for_each_squad_ped(fn)
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then fn(guard.ped, guard) end
    end
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.driver) then fn(esc.driver, nil) end
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then fn(pass, nil) end
        end
    end
end

local function squad_members()
    local set, list = { [player_ped()] = true }, {}
    for_each_squad_ped(function(ped)
        set[ped] = true
        list[#list + 1] = ped
    end)
    return set, list
end

-- currently selected primary / secondary from the two-tier pickers.
-- returns nil if the "give" toggle for that slot is off.
local function primary_weapon()
    if not feat(ui.give_primary):IsToggled() then return nil end
    local cat = WEAPON_CATS[feat(ui.pri_cat):GetListIndex() + 1]
    return cat and cat.list[feat(ui.primary):GetListIndex() + 1] or nil
end

local function secondary_weapon()
    if not feat(ui.give_secondary):IsToggled() then return nil end
    local cat = WEAPON_CATS[feat(ui.sec_cat):GetListIndex() + 1]
    return cat and cat.list[feat(ui.secondary):GetListIndex() + 1] or nil
end

local function selected_weapons() return primary_weapon(), secondary_weapon() end

-- Who the squad is guarding. Normally you; if you assigned them to protect
-- someone from the player list, it's that player's ped instead. Falls back
-- to you the moment that player is gone.
local function anchor_ped()
    if squad.protect_id ~= nil then
        local ok, p = pcall(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX, squad.protect_id)
        if ok and p and p ~= 0 and ENTITY.DOES_ENTITY_EXIST(p)
            and not ENTITY.IS_ENTITY_DEAD(p) then
            return p
        end
        squad.protect_id = nil -- they left / died, come back to me
    end
    return player_ped()
end

local function players_allowed()
    return picked(ui.allow_players, TARGET_POLICIES)[2]
end

-- The player the squad has been sent after, if any. Only works when the
-- engagement policy is set to include players.
local function hunt_ped()
    if squad.hunt_id == nil then return 0 end
    if not players_allowed() then return 0 end
    local ok, p = pcall(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX, squad.hunt_id)
    if ok and p and p ~= 0 and ENTITY.DOES_ENTITY_EXIST(p)
        and not ENTITY.IS_ENTITY_DEAD(p) then
        return p
    end
    return 0
end

local function protect_name()
    if squad.protect_id == nil then return nil end
    local ok, n = pcall(PLAYER.GET_PLAYER_NAME, squad.protect_id)
    if ok and n then return n end
    return "player " .. tostring(squad.protect_id)
end

-- On foot the guard carries the primary. The secondary is the in-vehicle
-- weapon and gets handed out / taken away by smart_weapon_tick, so the
-- combat AI can never pick a pistol over the rifle while walking around.
local function give_loadout(ped, is_animal)
    if is_animal then return end
    WEAPON.REMOVE_ALL_PED_WEAPONS(ped, true)
    local prim = primary_weapon()
    if prim then
        WEAPON.GIVE_WEAPON_TO_PED(ped, prim.h, 9999, false, true)
        WEAPON.SET_PED_INFINITE_AMMO(ped, true, prim.h)
        WEAPON.SET_CURRENT_PED_WEAPON(ped, prim.h, true)
    end
    WEAPON.SET_PED_INFINITE_AMMO_CLIP(ped, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 42, false) -- don't auto-swap to "best" weapon
    PED.SET_PED_CAN_SWITCH_WEAPON(ped, false)
end

-- Puts a one-handed weapon in their hands for vehicle use. Called ONCE when
-- a ped gets into a vehicle. Never on a timer, because a forced weapon swap
-- cancels whatever they were aiming at.
local function apply_vehicle_weapon(ped)
    local prim, sec = selected_weapons()
    local want = sec
    if not want and prim and DRIVEBY_OK[prim.h] then want = prim end
    if not want then
        -- nothing one-handed configured: fall back to an AP Pistol so a
        -- driveby seat is never left holding something unusable
        local fallback = Utils.Joaat("WEAPON_APPISTOL")
        WEAPON.GIVE_WEAPON_TO_PED(ped, fallback, 9999, false, false)
        WEAPON.SET_PED_INFINITE_AMMO(ped, true, fallback)
        WEAPON.SET_CURRENT_PED_WEAPON(ped, fallback, true)
        return
    end
    WEAPON.GIVE_WEAPON_TO_PED(ped, want.h, 9999, false, false)
    WEAPON.SET_PED_INFINITE_AMMO(ped, true, want.h)
    WEAPON.SET_CURRENT_PED_WEAPON(ped, want.h, true)
end

local function add_blip(ent, color)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
    HUD.SET_BLIP_COLOUR(blip, color)
    HUD.SET_BLIP_AS_FRIENDLY(blip, true)
    HUD.SET_BLIP_SCALE(blip, 0.75)
    return blip
end

local function heal_ped(ped)
    local hp = feat(ui.health):GetIntValue()
    PED.SET_PED_MAX_HEALTH(ped, hp)
    ENTITY.SET_ENTITY_MAX_HEALTH(ped, hp)
    ENTITY.SET_ENTITY_HEALTH(ped, hp, 0, 0)
    PED.SET_PED_ARMOUR(ped, feat(ui.armor):GetIntValue())
    PED.CLEAR_PED_BLOOD_DAMAGE(ped)
end

----------------------------------------------------------------------
-- Relationship groups - gray crosshair + guards can't be hurt by you
--   0 = Companion, 3 = Neutral, 5 = Hate
------------------------------------------------

local function player_rel_hash()
    local ok, hash = pcall(PED.GET_PED_RELATIONSHIP_GROUP_HASH, player_ped())
    if ok and hash and hash ~= 0 then return hash end
    return Utils.Joaat("PLAYER")
end

local function init_relationships()
    if squad.bg_group then return end
    local ptr = Memory.AllocInt()
    Memory.WriteInt(ptr, 0)
    pcall(PED.ADD_RELATIONSHIP_GROUP, "BGS_SQUAD_V3", ptr)
    squad.bg_group = Memory.ReadInt(ptr)
    Memory.Free(ptr)
    if not squad.bg_group or squad.bg_group == 0 then
        squad.bg_group = Utils.Joaat("PLAYER")
    end
end

-- Re-bonded periodically: your relationship group changes when you migrate
-- sessions, and a stale bond is what makes guards suddenly turn on you.
local function bond_relationships()
    if not squad.bg_group then return end
    local mine = player_rel_hash()
    local generic = Utils.Joaat("PLAYER")

    -- THIS is what stopped the squad shooting players. Every player shares
    -- the same relationship group, so bonding to it as COMPANION (0) marks
    -- ALL players as friends, and a ped will not attack a companion no
    -- matter what task you give it or what the friendly-fire flag says.
    -- With player targets allowed we drop to NEUTRAL (3): they still won't
    -- start on anyone unprompted, but they CAN be ordered onto a player.
    local bond = players_allowed() and 3 or 0

    pcall(PED.SET_RELATIONSHIP_BETWEEN_GROUPS, bond, squad.bg_group, mine)
    pcall(PED.SET_RELATIONSHIP_BETWEEN_GROUPS, bond, mine, squad.bg_group)
    -- squad members are always companions to each other
    pcall(PED.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, squad.bg_group, squad.bg_group)
    if generic ~= mine then
        pcall(PED.SET_RELATIONSHIP_BETWEEN_GROUPS, bond, squad.bg_group, generic)
        pcall(PED.SET_RELATIONSHIP_BETWEEN_GROUPS, bond, generic, squad.bg_group)
    end
    -- friendly fire has to be permitted at the session level too, or damage
    -- from your crew onto another player simply doesn't register
    if players_allowed() then
        pcall(NETWORK.NETWORK_SET_FRIENDLY_FIRE_OPTION, true)
    end
    -- Deliberately NOT declaring war on the ambient gangs here. Marking every
    -- Ballas/Vagos/Lost ped as hated makes the squad open fire on strangers
    -- across the street you never touched. They now only fight peds we hand
    -- them explicitly via REGISTER_TARGET.
end

-- careful with this one. it used to run on every squad ped once a second, and
-- the first line resets the ped's ai state, so crew were losing their task
-- about as fast as they got one. signature check keeps it to real changes.
local prot_sig = {}
local function apply_friendly_protection(ped, force)
    local sig = ("%s|%s|%s|%s"):format(tostring(squad.bg_group),
        tostring(feat(ui.killable):IsToggled()),
        tostring(players_allowed()), tostring(player_rel_hash()))
    if not force and prot_sig[ped] == sig then return end
    prot_sig[ped] = sig

    if squad.bg_group then
        pcall(PED.SET_PED_RELATIONSHIP_GROUP_HASH, ped, squad.bg_group)
    end

    -- Players read as FRIENDLIES to your squad's relationship group, so with
    -- friendly-fire locked they physically cannot shoot one, which is why
    -- aiming at a player did nothing. Unlock it whenever the engagement
    -- policy allows players, not just when a hunt target is set.
    pcall(PED.SET_CAN_ATTACK_FRIENDLY, ped, players_allowed(), false)

    -- "Killable By Me": ON  -> you can lock on and shoot them like any ped
    --                   OFF -> gray crosshair, your bullets pass through them
    local killable = feat(ui.killable):IsToggled()
    -- EVERY player shares one relationship group, and these two natives work
    -- on the group, not on you. So with "Killable By Me" off the squad was
    -- also bulletproof to everyone ELSE in the lobby - your friends emptied
    -- magazines into your bodyguards for nothing. That's fine for NPCs Only,
    -- but it makes consenting PvP a farce, so once players are in play the
    -- squad is always damageable and lockable by other people. "Killable By
    -- Me" then only governs YOUR crosshair, via the per-player native below.
    local pvp = players_allowed()
    pcall(PED.SET_PED_CAN_BE_TARGETTED, ped, killable or pvp)
    pcall(PED.SET_PED_CAN_BE_TARGETTED_BY_PLAYER, ped, PLAYER.PLAYER_ID(), killable)
    pcall(PED.SET_PED_SUFFERS_CRITICAL_HITS, ped, killable or pvp)
    local mine = player_rel_hash()
    if mine and mine ~= 0 then
        pcall(ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP, ped, killable or pvp, mine)
    end
    -- no-collision only while they're protected, otherwise you'd shoot
    -- through a guard standing in front of you
    pcall(ENTITY.SET_ENTITY_NO_COLLISION_ENTITY, ped, player_ped(), not killable)
end

-- ---- Core Spawning Logic

local function setup_combat(ped, stay_in_vehicle, is_animal)
    apply_friendly_protection(ped)
    PED.SET_PED_CONFIG_FLAG(ped, 52, true)   -- don't raise your wanted level
    -- seat lock: turret gunners stay put when the vehicle flips or gets rammed
    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ped, 1)
    PED.SET_PED_CONFIG_FLAG(ped, 32, false)  -- no flying through the windscreen

    if is_animal then
        PED.SET_PED_COMBAT_ABILITY(ped, 2)
        PED.SET_PED_COMBAT_RANGE(ped, 1)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5,  true)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 26, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 58, true)
        pcall(AUDIO.SET_ANIMAL_MOOD, ped, 2) -- aggressive
        PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false)
        return
    end

    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0,  true)  -- use cover
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 1,  true)  -- use vehicles
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 2,  true)  -- drivebys
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 3,  not stay_in_vehicle)
    -- NOTE: attribute 5 (AlwaysFight) and 13 (aggressively engage) are NOT
    -- set here. With a big perception range they make guards pick fights
    -- with strangers a block away on their own. settings_tick turns them on
    -- only when you've asked for aggressive behaviour.
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)  -- can taunt in vehicle
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 42, false) -- no auto "best weapon" swap
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)  -- will fight armed peds back
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 52, true)  -- use vehicle attack
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 53, true)  -- use mounted vehicle guns
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 58, true)  -- never flee combat
    PED.SET_PED_COMBAT_ABILITY(ped, 2)
    PED.SET_PED_COMBAT_RANGE(ped, 2)
    PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false)
    PED.SET_PED_TARGET_LOSS_RESPONSE(ped, 1)
    -- perception is capped to your engage range, not the whole map
    local see = feat(ui.engage_range):GetIntValue() + 0.0
    PED.SET_PED_SEEING_RANGE(ped, see)
    PED.SET_PED_HEARING_RANGE(ped, see)
    PED.SET_PED_ID_RANGE(ped, see)
    PED.SET_PED_ALERTNESS(ped, 1)

    -- FULL_AUTO makes normal guns fire continuously, but it BREAKS miniguns,
    -- RPGs, snipers and melee. Those need their own natural pattern.
    local prim = primary_weapon()
    if not prim or not NO_FULL_AUTO[prim.h] then
        PED.SET_PED_FIRING_PATTERN(ped, FULL_AUTO)
        PED.SET_PED_SHOOT_RATE(ped, 1000)
    else
        PED.SET_PED_SHOOT_RATE(ped, 1000)
    end
end

-- Which dropdowns to read the model from. Bodyguards and escort crews have
-- their own pair so you can run e.g. clones as guards and SWAT as escorts.
local GUARD_SELECTOR  = { cat = ui.model_cat,     item = ui.model_preset, custom = ui.guard_model }
local ESCORT_SELECTOR = { cat = ui.esc_model_cat, item = ui.esc_model,    custom = ui.esc_model_txt }

-- returns ped handle (0 on failure), display name, is_animal
local function spawn_squad_ped(x, y, z, heading, force_clone, sel)
    sel = sel or GUARD_SELECTOR
    local cat   = MODEL_CATS[feat(sel.cat):GetListIndex() + 1]
    local entry = cat and cat.list[feat(sel.item):GetListIndex() + 1] or nil
    local kind  = force_clone and "CLONE" or (entry and entry.m or "CLONE")
    local name  = force_clone and "Clone" or (entry and entry.n or "Clone")
    local is_animal = (not force_clone) and entry and entry.animal or false
    local ped

    -- swap out anything spam protection will bin on their machines, see
    -- FRIEND_SAFE_SUBS. only bothers online, nobody to sync to in story mode.
    if feat(ui.friend_safe):IsToggled() and model_needs_sub(kind)
        and net_in_session() then
        local sub = FRIEND_SAFE_SUBS[kind]
        if not squad.warned_sync then
            squad.warned_sync = true
            toast(("Friend-Safe Models: '%s' won't sync past Spam Protection, using %s instead.")
                :format(name, sub))
        end
        kind, name = sub, sub
        force_clone = false
        is_animal = false
    end

    if kind == "CLONE" then
        name = "Clone"
        is_animal = false
        ped = PED.CLONE_PED(player_ped(), true, false, true)
        if ped ~= nil and ped ~= 0 then
            ENTITY.SET_ENTITY_COORDS(ped, x, y, z, false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(ped, heading)
        end
    else
        local model_name = (kind == "CUSTOM") and feat(sel.custom):GetStringValue() or kind
        if kind == "CUSTOM" then name = model_name end
        local model = Utils.Joaat(model_name)
        if not load_model(model) then
            toast("Invalid ped model: " .. model_name)
            return 0, name, false
        end
        ped = GTA.CreatePed(model, 26, x, y, z, heading, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    end
    if ped == nil or ped == 0 then return 0, name, false end

    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    -- freemode models spawn with blank components, so always randomize those
    local is_freemode = kind == "mp_m_freemode_01" or kind == "mp_f_freemode_01"
    if kind ~= "CLONE" and not is_animal
        and (feat(ui.random_outfit):IsToggled() or is_freemode) then
        PED.SET_PED_RANDOM_COMPONENT_VARIATION(ped, 0)
    end
    setup_combat(ped, false, is_animal)
    if not is_animal then PED.SET_PED_ACCURACY(ped, feat(ui.accuracy):GetIntValue()) end
    heal_ped(ped)
    if feat(ui.god):IsToggled() then ENTITY.SET_ENTITY_INVINCIBLE(ped, true) end
    if feat(ui.no_ragdoll):IsToggled() then PED.SET_PED_CAN_RAGDOLL(ped, false) end
    return ped, name, is_animal
end

-- ==== Bodyguard System ====

local function prune_dead()
    for i = #squad.guards, 1, -1 do
        local guard = squad.guards[i]
        -- downed guards waiting on auto-revive stay in the list
        if not alive(guard.ped) and not guard.downed_at then
            remove_blip(guard.blip)
            net_forget(guard.ped)
            table.remove(squad.guards, i)
            if feat(ui.auto_respawn):IsToggled() then
                squad.respawn_queue[#squad.respawn_queue + 1] = { dueAt = Time.GetEpocheMs() + 5000 }
            end
        end
    end
    for i = #squad.escorts, 1, -1 do
        local esc = squad.escorts[i]
        local any_alive = alive(esc.driver)
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then any_alive = true end
        end
        if not any_alive then
            remove_blip(esc.blip)
            net_forget(esc.veh)
            net_forget(esc.driver)
            for _, pass in ipairs(esc.peds) do net_forget(pass) end
            table.remove(squad.escorts, i)
        end
    end
end

local function spawn_guards(count, force_clone)
    init_relationships()
    bond_relationships()
    prune_dead()
    local spawned = 0
    for _ = 1, count do
        if #squad.guards >= MAX_BODYGUARDS then
            toast("Bodyguard limit reached (7 - group cap).")
            break
        end
        local n = #squad.guards
        local pos = offset_from_player((n % 2 == 0) and 1.5 or -1.5, -1.5 - math.floor(n / 2))
        local ped, name, is_animal = spawn_squad_ped(pos.x, pos.y, pos.z,
            ENTITY.GET_ENTITY_HEADING(player_ped()), force_clone, GUARD_SELECTOR)
        if ped == 0 then break end

        local group = PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
        PED.SET_PED_AS_GROUP_MEMBER(ped, group)
        PED.SET_PED_NEVER_LEAVES_GROUP(ped, true)
        PED.SET_GROUP_SEPARATION_RANGE(group, 9999.0)
        give_loadout(ped, is_animal)
        local blip = add_blip(ped, picked(ui.blip_color, BLIP_COLORS)[2])

        Script.Yield(100)
        if not PED.IS_PED_GROUP_MEMBER(ped, group) then
            PED.SET_PED_AS_GROUP_MEMBER(ped, group)
        end

        ensure_control(ped)
        squad.guards[#squad.guards + 1] =
            { ped = ped, name = name, blip = blip, isAnimal = is_animal }
        spawned = spawned + 1
        Script.Yield(50)
    end
    if spawned > 0 then
        toast(("Spawned %d bodyguard(s), squad %d/7."):format(spawned, #squad.guards))
    end
end

local function btn_spawn_guards() spawn_guards(feat(ui.spawn_count):GetIntValue(), false) end
local function btn_spawn_clone() spawn_guards(1, true) end

local function btn_apply_loadout()
    prune_dead()
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then give_loadout(guard.ped, guard.isAnimal) end
    end
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.driver) then give_loadout(esc.driver, false) end
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then give_loadout(pass, false) end
        end
    end
    local prim, sec = selected_weapons()
    toast("Armed: " .. (prim and prim.n or "none") .. " / " .. (sec and sec.n or "none"))
end

local function btn_tp_guards()
    prune_dead()
    for i, guard in ipairs(squad.guards) do
        local pos = offset_from_player((i % 2 == 0) and 2.0 or -2.0, -1.5 - math.floor(i / 2))
        ENTITY.SET_ENTITY_COORDS(guard.ped, pos.x, pos.y, pos.z, false, false, false, false)
        TASK.CLEAR_PED_TASKS(guard.ped)
        squad.follow_issued[guard.ped] = nil
    end
    toast("Squad teleported to you.")
end

local function btn_heal_guards()
    prune_dead()
    for_each_squad_ped(heal_ped)
    toast("Squad healed.")
end

local function btn_warp_into_vehicle()
    prune_dead()
    local player = player_ped()
    if not PED.IS_PED_IN_ANY_VEHICLE(player, false) then
        toast("Get in a vehicle first.")
        return
    end
    local veh = PED.GET_VEHICLE_PED_IS_IN(player, false)
    local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(veh))
    local seat = 0
    for _, guard in ipairs(squad.guards) do
        while seat <= seats - 2 and not VEHICLE.IS_VEHICLE_SEAT_FREE(veh, seat, false) do
            seat = seat + 1
        end
        if seat > seats - 2 then break end
        PED.SET_PED_INTO_VEHICLE(guard.ped, veh, seat)
        seat = seat + 1
    end
    toast("Squad warped into your vehicle.")
end

local function btn_steal_cars()
    prune_dead()
    local claimed = {}
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) and not PED.IS_PED_IN_ANY_VEHICLE(guard.ped, true) then
            local pos = ENTITY.GET_ENTITY_COORDS(guard.ped, true)
            local veh = VEHICLE.GET_CLOSEST_VEHICLE(pos.x, pos.y, pos.z, 80.0, 0, 71)
            if veh ~= 0 then
                local seat = claimed[veh] and -2 or -1
                TASK.TASK_ENTER_VEHICLE(guard.ped, veh, 20000, seat, 2.0, 8, 0)
                claimed[veh] = true
            end
        end
    end
    toast("Bodyguards commandeering nearby vehicles.")
end

local function btn_dismiss_guards()
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then
            PED.REMOVE_PED_FROM_GROUP(guard.ped)
            ENTITY.SET_ENTITY_INVINCIBLE(guard.ped, false)
            TASK.CLEAR_PED_TASKS(guard.ped)
            TASK.TASK_WANDER_STANDARD(guard.ped, 10.0, 10)
            -- lives in ENTITY, not PED (the old PED.* call was always nil, so
            -- dismissed guards were never actually released to the game)
            if ENTITY.SET_PED_AS_NO_LONGER_NEEDED ~= nil then
                pcall(call_with_ptr, ENTITY.SET_PED_AS_NO_LONGER_NEEDED, guard.ped)
            end
        end
        remove_blip(guard.blip)
    end
    squad.guards = {}
    squad.respawn_queue = {}
    toast("Guards dismissed - walking away.")
end

local function btn_delete_guards()
    for _, guard in ipairs(squad.guards) do
        remove_blip(guard.blip)
        delete_entity(guard.ped)
    end
    squad.guards = {}
    squad.respawn_queue = {}
    toast("All bodyguards removed.")
end

local function remove_one_guard(ped)
    for i, guard in ipairs(squad.guards) do
        if guard.ped == ped then
            remove_blip(guard.blip)
            delete_entity(guard.ped)
            table.remove(squad.guards, i)
            return
        end
    end
end

local function tp_one_guard(ped)
    if alive(ped) then
        local pos = offset_from_player(1.5, -1.5)
        ENTITY.SET_ENTITY_COORDS(ped, pos.x, pos.y, pos.z, false, false, false, false)
        TASK.CLEAR_PED_TASKS(ped)
    end
end

------------------------------------------------------------
-- Escort Convoy System

-- performance only: engine, brakes, transmission, suspension, armour, turbo
local function max_tune(veh)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    for _, mod in ipairs({ 11, 12, 13, 15, 16 }) do
        local top = VEHICLE.GET_NUM_VEHICLE_MODS(veh, mod) - 1
        if top >= 0 then VEHICLE.SET_VEHICLE_MOD(veh, mod, top, false) end
    end
    VEHICLE.TOGGLE_VEHICLE_MOD(veh, 18, true)
end

-- the works: every cosmetic slot maxed, bulletproof tyres, strong axles.
-- mod slots 0-49 covers spoilers, bumpers, skirts, exhausts, roll cage,
-- grille, hood, fenders, roof, plates, trim, horns, wheels and the rest.
local function full_upgrade(veh)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    for mod = 0, 49 do
        local ok, top = pcall(VEHICLE.GET_NUM_VEHICLE_MODS, veh, mod)
        if ok and top ~= nil and top > 0 then
            pcall(VEHICLE.SET_VEHICLE_MOD, veh, mod, top - 1, false)
        end
    end
    -- toggle-style mods (turbo / xenon etc.)
    for _, t in ipairs({ 18, 22 }) do
        pcall(VEHICLE.TOGGLE_VEHICLE_MOD, veh, t, true)
    end
    pcall(VEHICLE.SET_VEHICLE_WHEEL_TYPE, veh, 7)
    pcall(VEHICLE.SET_VEHICLE_TYRES_CAN_BURST, veh, false) -- bulletproof tyres
    pcall(VEHICLE.SET_VEHICLE_HAS_STRONG_AXLES, veh, true)
end

local function escort_model_name()
    local cat = VEHICLE_DB[feat(ui.esc_veh_cat):GetListIndex() + 1]
    local entry = cat[2][feat(ui.esc_veh_model):GetListIndex() + 1] or cat[2][1]
    if entry[2] == "CUSTOM" then
        return feat(ui.esc_veh_text):GetStringValue()
    end
    return entry[2]
end

local function spawn_escort_vehicle(veh_hash, occupants, slot, anchor)
    anchor = anchor or player_ped()
    local is_plane = VEHICLE.IS_THIS_MODEL_A_PLANE(veh_hash)
    local is_air = VEHICLE.IS_THIS_MODEL_A_HELI(veh_hash) or is_plane
    local lane   = (slot % 2 == 0) and 6.0 or -6.0
    local back   = -10.0 - math.floor(slot / 2) * 9.0
    if is_plane then
        -- Planes go straight UP, not sideways. Offsetting them 120m to the
        -- side dropped them into hillsides and buildings, which is why half
        -- were exploding the moment they appeared. Directly overhead is
        -- always clear sky; separation comes from altitude instead.
        lane = (slot % 2 == 0) and 25.0 or -25.0
        back = -40.0
    end
    local pos    = offset_from(anchor, lane, back)
    -- planes need real altitude and airspeed or they stall and nose-dive the
    -- instant they exist; helis are fine much lower
    local air_h  = feat(ui.air_alt):GetIntValue() + 0.0
    local z      = pos.z
    if is_plane then
        -- clear of terrain but near their loiter height, so they aren't
        -- diving hundreds of metres the moment they appear
        z = pos.z + air_h + 120.0 + slot * 60.0
    elseif is_air then
        z = pos.z + air_h + slot * 12.0
    end

    local veh = GTA.SpawnVehicle(veh_hash, pos.x, pos.y, z, ENTITY.GET_ENTITY_HEADING(anchor), true, false)
    if veh == nil or veh == 0 then
        toast("Vehicle spawn failed.")
        return false
    end
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
    VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
    -- never lock your own convoy out of your reach
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 1)
    pcall(VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER, veh, PLAYER.PLAYER_ID(), false)
    if is_plane then
        -- launch at cruise speed with the gear up, otherwise it drops like a
        -- brick before the pilot ever gets control. Planes are also made
        -- collision-proof against the world for the first moments so a bad
        -- spawn can't instantly destroy them.
        pcall(VEHICLE.SET_VEHICLE_FORWARD_SPEED, veh, 55.0)
        pcall(VEHICLE.CONTROL_LANDING_GEAR, veh, 3) -- retract
        pcall(VEHICLE.SET_VEHICLE_STRONG, veh, true)
        pcall(ENTITY.SET_ENTITY_PROOFS, veh, false, false, false, true, false, false, false, false)
    elseif is_air then
        VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
    end
    if feat(ui.esc_upgrade):IsToggled() then
        full_upgrade(veh)
    elseif feat(ui.esc_tune):IsToggled() then
        max_tune(veh)
    end
    if feat(ui.esc_strong):IsToggled() then pcall(VEHICLE.SET_VEHICLE_STRONG, veh, true) end
    local want_col = picked(ui.esc_color, ESCORT_COLORS)[2]
    if want_col >= 0 then
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        VEHICLE.SET_VEHICLE_COLOURS(veh, want_col, want_col)
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, want_col, want_col)
    end
    if feat(ui.esc_god_veh):IsToggled() then ENTITY.SET_ENTITY_INVINCIBLE(veh, true) end

    -- convoy vehicles ignore each other physically. Stops aircraft wiping
    -- each other out and stops ground escorts shunting themselves off the
    -- road in a pile-up.
    for _, other in ipairs(squad.escorts) do
        if alive(other.veh) then
            pcall(ENTITY.SET_ENTITY_NO_COLLISION_ENTITY, veh, other.veh, false)
            pcall(ENTITY.SET_ENTITY_NO_COLLISION_ENTITY, other.veh, veh, false)
        end
    end

    local esc = { veh = veh, driver = 0, peds = {}, seats = {}, isAir = is_air,
                  isPlane = is_plane, slot = slot, commandeered = false, ousted = false }
    local veh_pos = ENTITY.GET_ENTITY_COORDS(veh, true)

    for seat = -1, occupants - 2 do
        local ped = spawn_squad_ped(veh_pos.x, veh_pos.y, veh_pos.z + 1.0, 0.0, false, ESCORT_SELECTOR)
        if ped == 0 then break end
        PED.SET_PED_INTO_VEHICLE(ped, veh, seat)
        -- Trailers and some weapon platforms have no real driver seat, so a
        -- seat -1 placement silently fails and the whole thing sits empty.
        -- Fall back to the first seat that actually takes them.
        if not PED.IS_PED_IN_VEHICLE(ped, veh, false) then
            for alt = 0, 6 do
                if VEHICLE.IS_VEHICLE_SEAT_FREE(veh, alt, false) then
                    PED.SET_PED_INTO_VEHICLE(ped, veh, alt)
                    if PED.IS_PED_IN_VEHICLE(ped, veh, false) then
                        seat = alt
                        break
                    end
                end
            end
        end
        setup_combat(ped, true, false)
        give_loadout(ped, false)
        -- vehicle crew setup, applied ONCE and never touched again. This
        -- matches the working script: always-fight on, can't leave the
        -- vehicle, full-auto, and a one-handed gun in hand from the start.
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 1,  true)  -- can use vehicles
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 2,  true)  -- drivebys
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 3,  false) -- never leave the vehicle
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5,  true)  -- always fight
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 20, true)  -- taunt in vehicle
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 58, true)  -- never flee
        PED.SET_PED_COMBAT_ABILITY(ped, 2)
        PED.SET_PED_COMBAT_RANGE(ped, 2)
        PED.SET_PED_ACCURACY(ped, feat(ui.accuracy):GetIntValue())
        PED.SET_PED_FIRING_PATTERN(ped, FULL_AUTO)
        -- seated crew never ragdoll: stops them flopping about the cabin
        -- when the vehicle rolls or gets rammed
        PED.SET_PED_CAN_RAGDOLL(ped, false)
        WEAPON.SET_PED_INFINITE_AMMO_CLIP(ped, true)
        apply_vehicle_weapon(ped)
        squad.veh_armed[ped] = "crew" -- stops smart_weapon_tick re-arming them
        ensure_control(ped) -- claim it, or none of its orders will register
        -- NOTE: do NOT SET_PED_KEEP_TASK on gunners. It locks whatever task
        -- they have and makes the game ignore every combat order you give
        -- them afterwards. That's why escort turret gunners never fired
        -- while bodyguards dropped into the same seat did.
        if seat == -1 then
            PED.SET_DRIVER_ABILITY(ped, 1.0)
            -- Aircraft need full aggression or they cruise at a fraction of
            -- their top speed and refuse to bank hard - that's the "flies
            -- slow and can't manoeuvre" problem.
            PED.SET_DRIVER_AGGRESSIVENESS(ped, is_air and 1.0 or 0.6)
            -- give aircraft a flight task straight away; an untasked pilot
            -- just lets the thing fall out of the sky
            if is_plane then
                local ap = ENTITY.GET_ENTITY_COORDS(anchor, true)
                -- first waypoint of the manual orbit (mission 4 = go to point)
                pcall(TASK.TASK_PLANE_MISSION, ped, veh, 0, 0,
                    ap.x + 170.0, ap.y, ap.z + air_h + 70.0,
                    4, 20.0, 0.0, 0.0, 1500.0, 40.0, false)
                -- [disabled] PED.SET_PED_KEEP_TASK(ped, true)
            elseif is_air then
                local ap = ENTITY.GET_ENTITY_COORDS(anchor, true)
                pcall(TASK.TASK_HELI_MISSION, ped, veh, 0, 0,
                    ap.x, ap.y, ap.z + air_h, 4, 45.0, 12.0, -1.0, -1, -1, 30.0, 0)
                -- [disabled] PED.SET_PED_KEEP_TASK(ped, true)
            end
            -- only the driver keeps his task (he needs the driving order to
            -- persist); gunners must stay taskable so they can be re-aimed
            -- [disabled] PED.SET_PED_KEEP_TASK(ped, true)
            -- the driver is the one you're allowed to yank out and replace,
            -- so he doesn't get the seat lock the gunners get
            local jackable = feat(ui.jackable):IsToggled()
            pcall(PED.SET_PED_CAN_BE_DRAGGED_OUT, ped, jackable)
            PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ped, jackable and 0 or 1)
            esc.driver = ped
            esc.blip = add_blip(veh, 2)
        else
            esc.peds[#esc.peds + 1] = ped
            esc.seats[ped] = seat -- remembered so we know if it's a turret seat
        end
        Script.Yield(0)
    end

    ensure_control(veh)
    ensure_control(esc.driver)
    squad.escorts[#squad.escorts + 1] = esc
    return true
end

local function btn_spawn_escorts(anchor, override_model, override_count)
    anchor = anchor or player_ped()
    init_relationships()
    bond_relationships()
    local model_name = override_model or escort_model_name()
    local veh_hash   = Utils.Joaat(model_name)
    if not load_model(veh_hash) then
        toast("Invalid vehicle model: " .. model_name)
        return
    end

    local count = override_count or math.max(1, feat(ui.esc_count):GetIntValue())
    local fill  = feat(ui.esc_fill):IsToggled()
    local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(veh_hash)

    if fill and seats > 0 then
        local remaining = count
        while remaining > 0 do
            local this_veh = math.min(remaining, seats)
            if not spawn_escort_vehicle(veh_hash, this_veh, #squad.escorts, anchor) then break end
            remaining = remaining - this_veh
            Script.Yield(50)
        end
    else
        for _ = 1, count do
            if not spawn_escort_vehicle(veh_hash, 1, #squad.escorts, anchor) then break end
            Script.Yield(50)
        end
    end

    squad.convoy_key = ""
    -- a lot of planes and helis carry no guns at all; without this you just
    -- see them fly around and assume the AI is broken
    local armed_ok = true
    if #squad.escorts > 0 then
        local last = squad.escorts[#squad.escorts]
        if last.isAir and alive(last.veh) then
            pcall(function() armed_ok = VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(last.veh) end)
        end
    end
    if not armed_ok then
        toast(("'%s' carries no weapons, it can escort but never attack."):format(model_name))
    end
    toast(("Spawned %d escort(s) using '%s'."):format(count, model_name))
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_hash)
end

local function btn_tp_escorts()
    prune_dead()
    for i, esc in ipairs(squad.escorts) do
        if alive(esc.veh) then
            local slot = i - 1
            local lane = (slot % 2 == 0) and 6.0 or -6.0
            local back = -10.0 - math.floor(slot / 2) * 9.0
            local pos  = offset_from_player(lane, back)
            local z    = esc.isAir and (pos.z + 30.0 + slot * 12.0) or pos.z
            ENTITY.SET_ENTITY_COORDS(esc.veh, pos.x, pos.y, z, false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(esc.veh, ENTITY.GET_ENTITY_HEADING(player_ped()))
        end
    end
    squad.convoy_key = ""
    toast("Escorts teleported to you.")
end

local function btn_heal_escorts()
    prune_dead()
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.driver) then heal_ped(esc.driver) end
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then heal_ped(pass) end
        end
        if alive(esc.veh) then
            VEHICLE.SET_VEHICLE_FIXED(esc.veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(esc.veh, 1000.0)
        end
    end
    toast("Escorts healed & repaired.")
end

local function btn_delete_escorts()
    for _, esc in ipairs(squad.escorts) do
        remove_blip(esc.blip)
        for _, pass in ipairs(esc.peds) do delete_entity(pass) end
        delete_entity(esc.driver)
        delete_entity(esc.veh)
    end
    squad.escorts = {}
    toast("All escorts removed.")
end

local function btn_rally()
    btn_tp_guards()
    btn_tp_escorts()
    btn_heal_guards()
    btn_heal_escorts()
    toast("Squad rallied: Teleported, healed, and repaired.")
end

-- weapon swapping
-- ---------------
-- one-handed weapons only out of a vehicle. hand a gunner a carbine and every
-- driveby order quietly does nothing.
--   in a car -> give them the sidearm and equip it
--   on foot  -> take it back off them so the ai can't wander round with a
--               pistol when it's holding a rifle

-- which seat is this ped in (nil if it's not in that vehicle)
local function seat_of(veh, ped)
    if not alive(veh) then return nil end
    local n = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(veh))
    for s = -1, n - 2 do
        if VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, s, false) == ped then return s end
    end
    return nil
end

-- this used to fire SET_CURRENT_PED_WEAPON every 700ms at anyone in a vehicle.
-- in a turret seat GET_SELECTED_PED_WEAPON hands you back the TURRET's weapon,
-- never matches the pistol, so it swapped forever. every forced swap cancels
-- the fire animation, so the poor sod never finished a single shot.
-- arm once on entry, leave turret seats completely alone, restore the rifle on
-- the way out. that's it.
local function smart_weapon_tick(now)
    if now < squad.next_weapon_at then return end
    squad.next_weapon_at = now + 1000

    local prim, sec = selected_weapons()

    local function handle(ped, is_animal)
        if is_animal or not alive(ped) then return end
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            if squad.veh_armed[ped] ~= nil then return end -- already sorted
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            local seat = seat_of(veh, ped)
            local turret = false
            if seat ~= nil then
                local ok, r = pcall(VEHICLE.IS_TURRET_SEAT, veh, seat)
                turret = ok and r
            end
            if turret then
                -- the vehicle gun IS their weapon; hands off
                squad.veh_armed[ped] = "turret"
            else
                apply_vehicle_weapon(ped)
                squad.veh_armed[ped] = "gun"
            end
        elseif squad.veh_armed[ped] ~= nil then
            -- just got out: take the sidearm back, restore the rifle. one-shot.
            squad.veh_armed[ped] = nil
            if sec and (not prim or sec.h ~= prim.h)
                and WEAPON.HAS_PED_GOT_WEAPON(ped, sec.h, false) then
                WEAPON.REMOVE_WEAPON_FROM_PED(ped, sec.h)
            end
            if prim then WEAPON.SET_CURRENT_PED_WEAPON(ped, prim.h, true) end
        end
    end

    for _, guard in ipairs(squad.guards) do
        if not guard.downed_at then handle(guard.ped, guard.isAnimal) end
    end
    for _, esc in ipairs(squad.escorts) do
        handle(esc.driver, false)
        for _, pass in ipairs(esc.peds) do handle(pass, false) end
    end
end

-- AI Combat Loop
--------------------

-- Whoever you're pointing your gun at. Checks BOTH aim modes: lock-on /
-- assisted aim AND free aim. Only checking free aim (what this used to do)
-- means nothing is ever detected for anyone playing with assisted aim,
-- which is exactly the "I shoot someone and my squad ignores it" problem.
local function aimed_target(squad_set)
    local pid = PLAYER.PLAYER_ID()

    -- only count an aim target while actually aiming or shooting.
    -- GET_PLAYER_TARGET_ENTITY reports whatever the soft lock is grazing even
    -- when you're just walking about with a gun out, and the squad was getting
    -- handed random passers by as targets because of it.
    local engaged_now = false
    pcall(function()
        engaged_now = PLAYER.IS_PLAYER_FREE_AIMING(pid)
            or PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID())
            or PLAYER.IS_PLAYER_TARGETTING_ANYTHING(pid)
    end)
    if not engaged_now then return 0 end

    local ptr = Memory.AllocInt()
    local found = 0

    if PLAYER.GET_PLAYER_TARGET_ENTITY ~= nil then
        Memory.WriteInt(ptr, 0)
        pcall(PLAYER.GET_PLAYER_TARGET_ENTITY, pid, ptr)
        local e = Memory.ReadInt(ptr)
        if e ~= nil and e ~= 0 then found = e end
    end
    if found == 0 and PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT ~= nil then
        Memory.WriteInt(ptr, 0)
        pcall(PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT, pid, ptr)
        local e = Memory.ReadInt(ptr)
        if e ~= nil and e ~= 0 then found = e end
    end
    Memory.Free(ptr)

    if found == 0 then return 0 end
    if not ENTITY.DOES_ENTITY_EXIST(found) then return 0 end
    if not ENTITY.IS_ENTITY_A_PED(found) then return 0 end
    if not good_target(found) or squad_set[found] then return 0 end
    if PED.IS_PED_A_PLAYER(found) and not players_allowed() then return 0 end
    return found
end

-- took me far too long to spot this one. find_threats works out who's hostile
-- with IS_PED_IN_COMBAT, and that's an npc state flag. a real player never
-- sets it no matter what they're doing to you, so other players were simply
-- invisible to the whole targeting layer. the squad only ever went after
-- someone I'd shot myself. nothing downstream was broken at all, guards and
-- gunners and turret crews were fine, they just never got handed anyone.
-- so for players, ask it backwards: have they hurt us? their car counts as
-- them so ramming works, and aiming at you counts too, no free first shot.
-- don't be tempted by IS_PLAYER_TARGETTING_ENTITY here, it reports the soft
-- lock and goes off constantly on aim assist. same trap as aimed_target.
local function player_is_hostile(them, player, guarded, squad_list, my_veh)
    local their_veh = 0
    if PED.IS_PED_IN_ANY_VEHICLE(them, false) then
        their_veh = PED.GET_VEHICLE_PED_IS_IN(them, false)
    end

    local function hurt(victim)
        if victim == nil or victim == 0 then return false end
        if not ENTITY.DOES_ENTITY_EXIST(victim) then return false end
        local hit = ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(victim, them, true)
        if not hit and their_veh ~= 0 then
            hit = ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(victim, their_veh, true)
        end
        -- same sticky-flag problem as everywhere else: clear it or one punch
        -- makes them a target for the rest of the session
        if hit then pcall(ENTITY.CLEAR_ENTITY_LAST_DAMAGE_ENTITY, victim) end
        return hit
    end

    if hurt(player) or hurt(my_veh) or hurt(guarded) then return true end
    for _, member in ipairs(squad_list) do
        if hurt(member) then return true end
    end

    local ok, idx = pcall(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED, them)
    if ok and idx ~= nil and idx >= 0 then
        local aiming = false
        pcall(function()
            aiming = PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(idx, player)
        end)
        if aiming then return true end
    end
    return false
end

local function find_threats(squad_set, squad_list, player, player_pos, include_damaged, now, guarded, allow_players)
    local threats, seen = {}, {}
    local pool_size = PoolMgr.GetMaxPedCount()
    -- scan out to whichever of the two reaches further; each group filters
    -- to its own range when it actually picks targets
    local range = math.max(feat(ui.engage_range):GetIntValue(),
                           feat(ui.esc_range):GetIntValue()) + 0.0
    -- your car counts as you for "did they shoot at us" purposes
    local my_veh = 0
    if PED.IS_PED_IN_ANY_VEHICLE(player, false) then
        my_veh = PED.GET_VEHICLE_PED_IS_IN(player, false)
    end
    for i = 0, pool_size - 1 do
        local ped = PoolMgr.GetPed(i)
        -- validity check FIRST. the pool is mostly empty slots and calling
        -- natives on those throws, which used to take out this whole function
        -- and looked exactly like "they just don't attack".
        if ped ~= nil and ped ~= 0 and ped ~= -1 and not squad_set[ped]
            and good_target(ped) then
            -- players are skipped unless you've allowed player targets, and
            -- whoever we're protecting is never a target
            local is_player = PED.IS_PED_A_PLAYER(ped)
            local ok_kind = (not is_player)
                or (allow_players and ped ~= player and ped ~= guarded)
            local d = dist(player_pos, ENTITY.GET_ENTITY_COORDS(ped, true))
            if ok_kind and d < range then
                local fighting = PED.IS_PED_IN_COMBAT(ped, player)
                -- anyone attacking the person we're assigned to protect
                if not fighting and guarded ~= nil and guarded ~= player then
                    fighting = PED.IS_PED_IN_COMBAT(ped, guarded)
                end
                if not fighting and d < math.min(80.0, range) then
                    for _, member in ipairs(squad_list) do
                        if PED.IS_PED_IN_COMBAT(ped, member) then fighting = true; break end
                    end
                end
                -- players don't have an AI combat state, so they need the
                -- damage-based test instead (see player_is_hostile)
                if is_player and not fighting then
                    fighting = player_is_hostile(ped, player, guarded, squad_list, my_veh)
                end
                local damaged = include_damaged and ENTITY.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(ped, player, true)
                local grudge = squad.vendetta[ped] ~= nil and squad.vendetta[ped] > now
                if damaged then
                    -- The damage flag is STICKY - it stays set forever, so a
                    -- pedestrian you clipped with your car ten minutes ago
                    -- still reads as "you attacked them" and the squad goes
                    -- after them. Clear it so each incident counts once.
                    pcall(ENTITY.CLEAR_ENTITY_LAST_DAMAGE_ENTITY, ped)
                end
                if fighting or damaged or grudge then
                    -- once they've traded fire with us they stay a target for
                    -- the pursuit window, even if we stop shooting
                    if fighting or damaged then
                        squad.vendetta[ped] = now + (feat(ui.pursuit):GetIntValue() * 1000)
                    end
                    -- flag airborne targets so anti-air crews get extra reach
                    local airborne = false
                    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                        local tv = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                        if tv ~= 0 then
                            local m = ENTITY.GET_ENTITY_MODEL(tv)
                            airborne = VEHICLE.IS_THIS_MODEL_A_HELI(m)
                                or VEHICLE.IS_THIS_MODEL_A_PLANE(m)
                        end
                    end
                    seen[ped] = true
                    threats[#threats + 1] = { ped = ped, dist = d, air = airborne,
                        prio = (damaged and 1) or (fighting and 2) or 3 }
                end
            end
        end
    end
    -- Don't trust the ped pool to hand us other players. Sweep the player list
    -- directly, it's 32 slots and it's the only way to be certain every one of
    -- them gets looked at. Costs nothing and it's the difference between the
    -- squad seeing your friends and not.
    local p_seen, p_hostile = 0, 0
    if allow_players then
        local me_id = GTA.GetLocalPlayerId()
        for pid = 0, 31 do
            if pid ~= me_id then
                local ok, them = pcall(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX, pid)
                if ok and them ~= nil and them ~= 0 and them ~= player
                    and them ~= guarded and not squad_set[them] and good_target(them) then
                    p_seen = p_seen + 1
                    local d = dist(player_pos, ENTITY.GET_ENTITY_COORDS(them, true))
                    local grudge = squad.vendetta[them] ~= nil and squad.vendetta[them] > now
                    local hot = grudge
                        or player_is_hostile(them, player, guarded, squad_list, my_veh)
                    if hot and d < range then
                        p_hostile = p_hostile + 1
                        squad.vendetta[them] = now + (feat(ui.pursuit):GetIntValue() * 1000)
                        local air = false
                        if PED.IS_PED_IN_ANY_VEHICLE(them, false) then
                            local tv = PED.GET_VEHICLE_PED_IS_IN(them, false)
                            if tv ~= 0 then
                                local m = ENTITY.GET_ENTITY_MODEL(tv)
                                air = VEHICLE.IS_THIS_MODEL_A_HELI(m)
                                    or VEHICLE.IS_THIS_MODEL_A_PLANE(m)
                            end
                        end
                        if not seen[them] then
                            seen[them] = true
                            threats[#threats + 1] =
                                { ped = them, dist = d, air = air, prio = 2 }
                        end
                    end
                end
            end
        end
    end
    -- for the diagnostics panel, so this stops being guesswork
    squad.pvp_seen, squad.pvp_hostile = p_seen, p_hostile

    for ped, until_t in pairs(squad.vendetta) do
        if until_t <= now or (not seen[ped] and (not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped))) then
            squad.vendetta[ped] = nil
        end
    end
    table.sort(threats, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        return a.dist < b.dist
    end)
    return threats
end

local function stand_down_escorts()
    squad.targets = {}
    squad.gunner_stage = {}
    squad.gunner_check = {}
    squad.gunner_locked = {}
    squad.gunner_method = {}
    for _, esc in ipairs(squad.escorts) do
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then TASK.CLEAR_PED_TASKS(pass) end
        end
        -- armed drivers (tanks/AA) were fighting instead of driving; release
        -- them so the convoy resumes
        if alive(esc.driver) then
            squad.targets[esc.driver] = nil
            TASK.CLEAR_PED_TASKS(esc.driver)
        end
    end
    squad.convoy_key = ""
end

-- Making a vehicle crewman actually open fire is finicky: which task works
-- depends on the seat (turret vs window) and the vehicle. So we try methods
-- in order and check 3s later whether they're really shooting; whatever
-- works gets locked in. Turret seats are tried mounted-gun-first, and we
-- deliberately DON'T force a handheld weapon on them, putting a pistol in
-- a turret gunner's hands is what stops him using the vehicle gun.
-- Why bodyguards shoot from a turret and escort crew didn't: bodyguards are
-- in your PLAYER GROUP, so the game's own combat AI keeps them fighting on
-- its own. Escort crew aren't in any group, so they only ever had the
-- one-shot tasks I handed them - and those expire, which is the "fires for
-- a split second then quits" behaviour.
--
-- Fix: mark the targets as personally HATED by that gunner (REGISTER_TARGET)
-- and give them TASK_COMBAT_HATED_TARGETS_AROUND_PED. That's a standing
-- order covering every hated ped in range, so it doesn't end when one target
-- dies, and the ped picks its own weapon, which is what lets a turret
-- gunner actually use the turret instead of a pistol we forced on him.
-- kept for reference; the crew loop now uses the simple in-combat check
local function unused_apply_gunner_task(ped, targets, stage, is_turret, range)
    local primary = targets[1]
    for _, t in ipairs(targets) do
        pcall(PED.REGISTER_TARGET, ped, t)
    end
    pcall(PED.REGISTER_HATED_TARGETS_AROUND_PED, ped, range)

    -- NOTE: no weapon swapping in here. smart_weapon_tick arms them once on
    -- entry; re-equipping mid-fight cancels their shot animation.
    if stage <= 2 then
        -- standing order: fight everything hated nearby, indefinitely
        pcall(TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED, ped, range, 0)
    elseif stage == 3 then
        pcall(TASK.TASK_VEHICLE_SHOOT_AT_PED, ped, primary, 60.0)
    else
        pcall(TASK.TASK_DRIVE_BY, ped, primary, 0, 0.0, 0.0, 0.0, 400.0, 100, true, FULL_AUTO)
    end
end

-- Point a squad ped at a target.
-- If the target is sitting in a vehicle, a plain combat order mostly gets
-- ignored - the AI won't reliably shoot an occupant through a car. Shooting
-- the VEHICLE itself is what actually works, and it's what lets you hit
-- someone fleeing in a car, a plane or a Deluxo.
-- A proper hunt: close the distance rather than waiting for the target to
-- wander into range. Used when you've explicitly sent someone after a player.
--   far away  -> advance on them, weapon up, firing as they go
--   close     -> normal combat
--   airborne  -> shoot up at the aircraft, since they can't walk to it
local function hunt_engage(ped, target, now)
    if not alive(ped) or not good_target(target) then return end

    local tveh = 0
    if PED.IS_PED_IN_ANY_VEHICLE(target, false) then
        tveh = PED.GET_VEHICLE_PED_IS_IN(target, false)
    end
    local airborne = false
    if tveh ~= 0 then
        local m = ENTITY.GET_ENTITY_MODEL(tveh)
        airborne = VEHICLE.IS_THIS_MODEL_A_HELI(m) or VEHICLE.IS_THIS_MODEL_A_PLANE(m)
    end

    pcall(PED.REGISTER_TARGET, ped, target)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5,  true)  -- always fight
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, true)  -- press the attack
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 26, true)  -- chase on foot
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)

    -- riding in something: fight from the seat, they can't dismount and run
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        pcall(TASK.TASK_COMBAT_PED, ped, target, 0, 16)
        return
    end

    local d = dist(ENTITY.GET_ENTITY_COORDS(ped, true),
                   ENTITY.GET_ENTITY_COORDS(target, true))

    if airborne then
        -- no walking to a helicopter; shoot at the aircraft itself
        if now >= (squad.engage_at[ped] or 0) then
            squad.engage_at[ped] = now + 3000
            pcall(TASK.TASK_SHOOT_AT_ENTITY, ped, tveh, 10000, FULL_AUTO)
        end
        return
    end

    if d > 45.0 then
        -- run them down, gun raised, shooting on the move
        if now >= (squad.engage_at[ped] or 0) then
            squad.engage_at[ped] = now + 3000
            local goto_ent = (tveh ~= 0) and tveh or target
            pcall(TASK.TASK_GO_TO_ENTITY_WHILE_AIMING_AT_ENTITY, ped,
                goto_ent, target, 2.0, true, 12.0, 8.0, true, false, FULL_AUTO)
        end
    else
        squad.engage_at[ped] = 0
        pcall(TASK.TASK_COMBAT_PED, ped, target, 0, 16)
    end
end

local function engage_target(ped, target, now)
    pcall(PED.REGISTER_TARGET, ped, target)

    -- If the SHOOTER is in a vehicle, always use TASK_COMBAT_PED. That is
    -- the one that reliably works from a seat (turret included) and it is
    -- what got the gunners firing in the first place. TASK_SHOOT_AT_ENTITY
    -- is an on-foot task. Handing it to a seated gunner does nothing, which
    -- is exactly how the crews went quiet again.
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        squad.engage_at[ped] = 0
        pcall(TASK.TASK_COMBAT_PED, ped, target, 0, 16)
        return
    end

    -- On foot: if the target is driving off, shoot the car instead - a ped
    -- won't reliably engage someone through a vehicle.
    local tveh = 0
    if PED.IS_PED_IN_ANY_VEHICLE(target, false) then
        tveh = PED.GET_VEHICLE_PED_IS_IN(target, false)
    end
    if tveh ~= 0 and alive(tveh) then
        if now >= (squad.engage_at[ped] or 0) then
            squad.engage_at[ped] = now + 4000
            pcall(TASK.TASK_SHOOT_AT_ENTITY, ped, tveh, 20000, FULL_AUTO)
        end
    else
        squad.engage_at[ped] = 0
        pcall(TASK.TASK_COMBAT_PED, ped, target, 0, 16)
    end
end

-- one bark when a guard enters combat
local function callout(ped)
    pcall(AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE, ped,
        "GENERIC_WAR_CRY", "SPEECH_PARAMS_FORCE_SHOUTED", 0)
end

local function ai_tick(now)
    if now < squad.next_ai_at then return end
    squad.next_ai_at = now + 500 -- same cadence as the script that works

    local have_guards, have_escorts = #squad.guards > 0, #squad.escorts > 0
    if not have_guards and not have_escorts then
        squad.threat_count = 0
        squad.vendetta = {}
        if squad.engaged then squad.engaged = false; squad.targets = {} end
        return
    end

    local esc_mode  = picked(ui.esc_mode, ESCORT_MODES)[2]
    local behaviour = picked(ui.behaviour, BEHAVIOURS)[2]
    local do_callouts = feat(ui.callouts):IsToggled()
    local squad_set, squad_list = squad_members()
    local player     = player_ped()
    local player_pos = ENTITY.GET_ENTITY_COORDS(player, true)

    local guarded = anchor_ped()
    local allow_players = players_allowed()
    local include_damaged = have_guards or esc_mode == "AGGRESSIVE"
    local threats = find_threats(squad_set, squad_list, player, player_pos,
        include_damaged, now, guarded, allow_players)
    -- whatever you're aiming at counts as an order, in any mode but Passive
    local aimed = aimed_target(squad_set)
    if aimed ~= 0 then
        table.insert(threats, 1, { ped = aimed, dist = 0, prio = 0 })
        squad.vendetta[aimed] = now + (feat(ui.pursuit):GetIntValue() * 1000)
    end
    -- An assigned target is only pushed to the groups you actually sent.
    -- Bodyguards, ground escorts and aircraft each have their own order.
    local hunted = hunt_ped()
    local hg = squad.hunt_groups
    local hunt_guards  = (hunted ~= 0 and hg.guards)  and hunted or 0
    local hunt_escorts = (hunted ~= 0 and hg.escorts) and hunted or 0
    local hunt_air     = (hunted ~= 0 and hg.air)     and hunted or 0
    if hunted ~= 0 and (hg.guards or hg.escorts or hg.air) then
        table.insert(threats, 1, { ped = hunted, dist = 0, prio = 0 })
    end
    squad.threat_count = #threats

    if have_guards then
        if #threats == 0 then
            if squad.guards_engaged then
                squad.guards_engaged = false
                for _, guard in ipairs(squad.guards) do
                    squad.targets[guard.ped] = nil
                    squad.follow_issued[guard.ped] = nil
                    guard.was_in_combat = false
                    if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
                end
            end
        else
            local g_range = feat(ui.engage_range):GetIntValue() + 0.0
            local guard_target = nil
            if hunt_guards ~= 0 and good_target(hunt_guards) then
                guard_target = hunt_guards -- explicit order beats everything
            else
                for _, t in ipairs(threats) do
                    -- skip an assigned target the guards weren't sent after
                    if not (t.ped == hunted and hunt_guards == 0) then
                        if (t.prio == 0 or behaviour ~= 1 or t.prio == 2)
                            and (t.prio == 0 or t.dist <= g_range) then
                            guard_target = t.ped
                            break
                        end
                    end
                end
            end
            for _, guard in ipairs(squad.guards) do
                if alive(guard.ped) and not guard.downed_at then
                    local in_combat = PED.IS_PED_IN_COMBAT(guard.ped, 0)
                    if do_callouts and in_combat and not guard.was_in_combat
                        and not guard.isAnimal then
                        callout(guard.ped)
                    end
                    guard.was_in_combat = in_combat

                    local cur = squad.targets[guard.ped]
                    -- target died: drop it immediately and re-pick, rather
                    -- than standing over the body still shooting
                    if cur ~= nil and not good_target(cur) then
                        squad.targets[guard.ped] = nil
                        squad.follow_issued[guard.ped] = nil
                        squad.guard_check[guard.ped] = nil
                        TASK.CLEAR_PED_TASKS(guard.ped)
                        cur = nil
                        in_combat = false
                    end
                    if hunt_guards ~= 0 and guard_target == hunt_guards then
                        -- ordered hunt. shove them at the target again every
                        -- two seconds so they actually cross the map to reach
                        -- them, rather than holding position and only firing
                        -- once the target happens to come close.
                        squad.guards_engaged = true
                        squad.targets[guard.ped] = guard_target
                        if now >= (squad.guard_check[guard.ped] or 0) then
                            squad.guard_check[guard.ped] = now + 2000
                            hunt_engage(guard.ped, guard_target, now)
                        end
                    else
                        -- re-issue if they've drifted out of the fight while
                        -- the target is still up, otherwise they disengage
                        -- after one burst and just stand there
                        local stale = cur ~= nil and not in_combat
                            and now >= (squad.guard_check[guard.ped] or 0)
                        if guard_target ~= nil and (cur == nil or stale) and not in_combat then
                            squad.guards_engaged = true
                            squad.targets[guard.ped] = guard_target
                            squad.guard_check[guard.ped] = now + 2000
                            pcall(PED.REGISTER_TARGET, guard.ped, guard_target)
                            engage_target(guard.ped, guard_target, now)
                        end
                    end
                end
            end
        end
    end

    if not have_escorts then return end

    local e_range = feat(ui.esc_range):GetIntValue() + 0.0
    local pool, in_pool = {}, {}
    for _, t in ipairs(threats) do
        -- aircraft get double the reach: they sit high up, so straight-line
        -- distance eats the whole budget on altitude alone and the crew would
        -- never engage a chopper directly overhead
        local reach = t.air and (e_range * 2.0) or e_range
        if (t.prio == 0 or esc_mode == "AGGRESSIVE" or t.prio == 2)
            and (t.prio == 0 or t.dist <= reach) then
            pool[#pool + 1] = t.ped
            in_pool[t.ped] = true
            if #pool >= 3 then break end
        end
    end

    -- Don't stand down the instant the pool blinks empty. Threat flags flicker
    -- constantly, and tearing the crew's tasks down on every blip is what made
    -- them start and stop over and over. Require a few seconds of real quiet.
    if (esc_mode == "PASSIVE" and hunt_escorts == 0 and hunt_air == 0) or #pool == 0 then
        if squad.engaged then
            squad.quiet_since = squad.quiet_since or now
            if now - squad.quiet_since > 1500 then
                squad.engaged = false
                squad.quiet_since = nil
                stand_down_escorts()
            end
        end
        return
    end
    squad.quiet_since = nil
    squad.engaged = true

    -- crew combat. deliberately dumb, that's the point.
    -- plain TASK_COMBAT_PED, not the vehicle shoot/driveby tasks. the crew
    -- can't leave the vehicle (attr 3 is off) so an ordinary combat order has
    -- them fight from the seat with whatever's there, turret included.
    -- only order someone who isn't already fighting. every clever re-issue
    -- ladder I tried just interrupted them mid-burst. weapons stay untouched.
    local range = feat(ui.engage_range):GetIntValue() + 0.0
    -- ground crews and aircraft take separate orders
    local focus = 0
    if hunt_escorts ~= 0 and good_target(hunt_escorts) then focus = hunt_escorts
    elseif aimed ~= 0 and good_target(aimed) then focus = aimed
    elseif #pool > 0 and not (pool[1] == hunted and hunt_escorts == 0) then
        focus = pool[1]
    end

    local air_focus = 0
    if hunt_air ~= 0 and good_target(hunt_air) then air_focus = hunt_air
    elseif aimed ~= 0 and good_target(aimed) then air_focus = aimed
    elseif #pool > 0 and not (pool[1] == hunted and hunt_air == 0) then
        air_focus = pool[1]
    end

    for _, esc in ipairs(squad.escorts) do
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then
                ensure_control(pass, now) -- no control, no orders
                local cur = squad.targets[pass]
                -- target's down: drop it this instant, don't keep pounding
                -- the corpse until the stand-down timer catches up
                if cur ~= nil and not good_target(cur) then
                    squad.targets[pass] = nil
                    squad.engage_at[pass] = 0
                    TASK.CLEAR_PED_TASKS(pass)
                    cur = nil
                end
                if focus ~= 0 then
                    -- only order them onto a target they aren't already on.
                    -- NO "sweep for hated targets" fallback, that's what had
                    -- them shooting random pedestrians they'd never met.
                    -- back to the exact condition that worked: only order them
                    -- when the target changed or they're idle. Re-tasking a
                    -- gunner every tick is what silences them.
                    -- "in combat" but silent for six seconds means the order
                    -- took and the shot never came, which is what happens when
                    -- the target is sitting inside a vehicle. Nudge it once,
                    -- on a timer, not every tick.
                    local mute = cur == focus
                        and now - (squad.gunner_shot[pass] or 0) > 6000
                        and now >= (squad.gunner_check[pass] or 0)
                    if mute then squad.gunner_check[pass] = now + 6000 end
                    if cur ~= focus or mute or not PED.IS_PED_IN_COMBAT(pass, 0) then
                        squad.targets[pass] = focus
                        if hunt_escorts ~= 0 and focus == hunt_escorts then
                            hunt_engage(pass, focus, now) -- handles aircraft too
                        else
                            engage_target(pass, focus, now)
                        end
                    end
                elseif cur ~= nil then
                    -- target's dead and nothing else is live: pack it in
                    squad.targets[pass] = nil
                    TASK.CLEAR_PED_TASKS(pass)
                end
            end
        end
        -- rhino / khanjali / barrage / the aa trailer work their gun from the
        -- driver seat. this loop only ever tasked passengers so those just sat
        -- there. armed, and either no living gunner or the driver seat IS the
        -- turret, means the driver fights instead of drives.
        if not esc.isAir and alive(esc.driver) and alive(esc.veh)
            and focus ~= 0 and not esc.commandeered then
            local gunners = 0
            for _, p in ipairs(esc.peds) do
                if alive(p) then gunners = gunners + 1 end
            end
            local armed = false
            pcall(function() armed = VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(esc.veh) end)
            local driver_turret = false
            pcall(function() driver_turret = VEHICLE.IS_TURRET_SEAT(esc.veh, -1) end)
            if armed and (gunners == 0 or driver_turret) then
                if squad.targets[esc.driver] ~= focus
                    or not PED.IS_PED_IN_COMBAT(esc.driver, 0) then
                    squad.targets[esc.driver] = focus
                    pcall(PED.REGISTER_TARGET, esc.driver, focus)
                    pcall(TASK.TASK_COMBAT_PED, esc.driver, focus, 0, 16)
                end
            end
        end

        -- planes and helis want completely different mission natives, and
        -- planes were getting handed a heli one. they just ignore it. that's
        -- the whole reason they never shot at anything.
        if esc.isAir and alive(esc.driver) and alive(esc.veh) and air_focus ~= 0 then
            local target = squad.targets[esc.driver]
            if target ~= air_focus or now >= (squad.engage_at[esc.driver] or 0) then
                squad.targets[esc.driver] = air_focus
                squad.engage_at[esc.driver] = now + 6000
                local tveh = 0
                if PED.IS_PED_IN_ANY_VEHICLE(air_focus, false) then
                    tveh = PED.GET_VEHICLE_PED_IS_IN(air_focus, false)
                end
                if esc.isPlane then
                    -- TASK_PLANE_CHASE is the game's OWN military intercept
                    -- behaviour - the same routine the wanted-level jets use
                    -- to hunt you down. It handles gun runs, overshoots and
                    -- re-approaches by itself, which no hand-built mission
                    -- was ever going to do properly.
                    local chase = (tveh ~= 0) and tveh or air_focus
                    TASK.CLEAR_PED_TASKS(esc.driver)
                    pcall(TASK.TASK_PLANE_CHASE, esc.driver, chase, 0.0, 0.0, 0.0)
                    -- NOT SET_PED_KEEP_TASK here: pinning the task is what
                    -- leaves a pilot flying off on a stale heading instead of
                    -- following the chase.
                    PED.SET_DRIVER_AGGRESSIVENESS(esc.driver, 1.0)
                else
                    -- heli mission 6 = attack
                    pcall(TASK.TASK_HELI_MISSION, esc.driver, esc.veh,
                        tveh, (tveh == 0) and air_focus or 0,
                        0.0, 0.0, 0.0, 6, 80.0, 25.0, -1.0, 80, 15, 100.0, 0)
                    -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
                end
            end
        end
    end
end

--------------------------------------------------------------
-- Convoy & Chauffeur Mechanics Loop
------------------------------------------------------------------

local function convoy_tick(now)
    if #squad.escorts == 0 then return end
    if now < squad.next_convoy_at then return end
    squad.next_convoy_at = now + 2000

    local style       = picked(ui.esc_style, DRIVE_STYLES)[2]
    local follow_dist = feat(ui.esc_distance):GetIntValue()
    local convoy      = picked(ui.convoy_style, CONVOY_STYLES)[2]

    local me         = player_ped()
    local player     = anchor_ped()  -- convoy escorts whoever we're guarding
    local in_veh     = PED.IS_PED_IN_ANY_VEHICLE(player, false)
    local player_veh = in_veh and PED.GET_VEHICLE_PED_IS_IN(player, false) or 0
    local my_veh     = PED.IS_PED_IN_ANY_VEHICLE(me, false)
        and PED.GET_VEHICLE_PED_IS_IN(me, false) or 0

    local wp_active = HUD.IS_WAYPOINT_ACTIVE()
    local wp = nil
    if wp_active then
        local wp_blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        if wp_blip ~= 0 then wp = HUD.GET_BLIP_INFO_ID_COORD(wp_blip) else wp_active = false end
    end
    local wp_key = wp_active and ("%d_%d"):format(math.floor(wp.x / 10), math.floor(wp.y / 10)) or "none"

    -- If the convoy has been sent after someone, the DRIVERS have to actually
    -- drive there. Previously only the gunners got the order, so the vehicle
    -- sat next to you shooting at nothing while the target drove off, that's
    -- the "they just stand still" behaviour.
    local chase_ent = 0
    if squad.hunt_groups.escorts then
        local hp = hunt_ped()
        if hp ~= 0 and good_target(hp) then
            if PED.IS_PED_IN_ANY_VEHICLE(hp, false) then
                chase_ent = PED.GET_VEHICLE_PED_IS_IN(hp, false)
            else
                chase_ent = hp
            end
        end
    end

    local chf_style  = picked(ui.chf_style, CHAUFFEUR_STYLES)[2]
    local chf_speed  = feat(ui.chf_speed):GetIntValue() + 0.0
    local player_pos = ENTITY.GET_ENTITY_COORDS(player, true)
    local landing    = feat(ui.heli_land):IsToggled()
    local do_flip    = feat(ui.auto_flip):IsToggled()
    local light      = feat(ui.searchlight):IsToggled()

    -- Entity-follow heli missions (8 / 23) are unreliable - they quietly end
    -- and the heli cruises off forever. Instead we fly them to a MOVING point
    -- above and behind you (mission 4 = go to coords), refreshed constantly.
    -- Deterministic, and it can't wander off.
    local function heli_follow(esc)
        local slot = esc.slot or 0
        local side = ((slot % 2 == 0) and 14.0 or -14.0) + (math.floor(slot / 2) * 6.0)
        local spot = offset_from(player, side, -18.0)
        local alt = feat(ui.air_alt):GetIntValue() + 0.0
        if esc.isPlane then
            -- manual orbit.
            -- The game's own circle task (mission 9) needs turning room: while
            -- you were moving it read as "fly toward him" and looked fine, but
            -- the moment you stood still it had nowhere to go and climbed.
            -- So we fly the orbit ourselves, hand the pilot a plain GoTo
            -- waypoint that walks around a ring centred on you. It's always
            -- chasing a point at a FIXED height, so it can never spiral up.
            esc.orbit = (esc.orbit or (slot * 2.1)) + 0.55
            local radius = 170.0 + slot * 45.0
            local ox = player_pos.x + math.cos(esc.orbit) * radius
            local oy = player_pos.y + math.sin(esc.orbit) * radius
            local oz = player_pos.z + alt + 70.0 + (slot * 25.0)
            pcall(TASK.TASK_PLANE_MISSION, esc.driver, esc.veh, 0, 0,
                ox, oy, oz, 4, 20.0, 0.0, 0.0, 1500.0, 40.0, false)
        else
            local z = spot.z + alt + (slot * 6.0)
            TASK.TASK_HELI_MISSION(esc.driver, esc.veh, 0, 0,
                spot.x, spot.y, z, 4, 45.0, 12.0, -1.0, -1, -1, 30.0, 0)
        end
        -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
    end

    local function heli_land(esc, slot)
        local spot = offset_from(me, 12.0 + slot * 16.0, 8.0) -- land next to YOU
        local ground = GTA.GetGroundZ(spot.x, spot.y)
        if ground == nil or ground == 0.0 then ground = spot.z end
        -- landing = mission type 4 (go to) with behaviour flag 32, per the
        -- native's own docs. Mission 20 was not a landing order at all.
        TASK.TASK_HELI_MISSION(esc.driver, esc.veh, 0, 0, spot.x, spot.y, ground,
            4, 25.0, 10.0, -1.0, 5, 0, 20.0, 32)
        -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
    end

    -- per-tick housekeeping: driver promotion, flipped cars, searchlights,
    -- and the heli babysitter that stops them wandering off
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.veh) then
            -- Are YOU sitting in the driver seat of this escort? Then it's
            -- yours - the crew must not fight you for the wheel.
            local at_wheel = VEHICLE.GET_PED_IN_VEHICLE_SEAT(esc.veh, -1, false)
            local mine_now = (at_wheel == me)
            if mine_now ~= esc.commandeered then
                esc.commandeered = mine_now
                squad.convoy_key = "" -- other escorts re-task around the change
            end

            if esc.commandeered then
                -- handled once per takeover, not every tick
                if not esc.ousted then
                    esc.ousted = true
                    if alive(esc.driver) and PED.GET_VEHICLE_PED_IS_IN(esc.driver, false) ~= esc.veh then
                        local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(esc.veh))
                        local free = nil
                        for seat = 0, seats - 2 do
                            if VEHICLE.IS_VEHICLE_SEAT_FREE(esc.veh, seat, false) then free = seat; break end
                        end
                        if free ~= nil then
                            -- room in the back: he becomes another gunner
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(esc.driver)
                            PED.SET_PED_INTO_VEHICLE(esc.driver, esc.veh, free)
                            setup_combat(esc.driver, true, false)
                            esc.peds[#esc.peds + 1] = esc.driver
                            esc.seats[esc.driver] = free
                            esc.driver = 0
                        end
                        -- no free seat: he stays on file as the driver and
                        -- just waits outside; when you get out he climbs
                        -- back in and drives again
                        toast("You took the wheel. Crew is riding with you.")
                    end
                end
            else
                -- not yours: driver dead, or you got out again -> crew drives
                esc.ousted = false
                if not good_target(esc.driver)
                    and not feat(ui.auto_promote):IsToggled() then
                    -- takeover disabled: clear the dead driver out of the seat
                    -- so the car is just sitting there for you to take, and
                    -- nobody slides over to replace him
                    if esc.driver ~= 0 then
                        delete_entity(esc.driver)
                        esc.driver = 0
                        squad.convoy_key = ""
                        toast("Driver down - car is yours, crew stays aboard.")
                    end
                elseif not good_target(esc.driver) then
                    local promoted = nil
                    for pi = #esc.peds, 1, -1 do
                        if good_target(esc.peds[pi]) then
                            promoted = esc.peds[pi]
                            table.remove(esc.peds, pi)
                            break
                        end
                    end
                    if promoted then
                        delete_entity(esc.driver)
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(promoted)
                        PED.SET_PED_INTO_VEHICLE(promoted, esc.veh, -1)
                        PED.SET_DRIVER_ABILITY(promoted, 1.0)
                        PED.SET_DRIVER_AGGRESSIVENESS(promoted, 0.6)
                        -- [disabled] PED.SET_PED_KEEP_TASK(promoted, true)
                        local jackable = feat(ui.jackable):IsToggled()
                        pcall(PED.SET_PED_CAN_BE_DRAGGED_OUT, promoted, jackable)
                        PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(promoted, jackable and 0 or 1)
                        esc.driver = promoted
                        squad.targets[promoted] = nil
                        squad.convoy_key = ""
                        toast("Escort driver down, crew took the wheel.")
                    end
                end
            end
            -- (flip righting now runs in the fast loop - see flip_tick)
            if esc.isAir then
                pcall(VEHICLE.SET_VEHICLE_SEARCHLIGHT, esc.veh, light, true)
            end
        end
    end

    -- helis get a fresh destination every convoy tick so they track you
    -- properly instead of drifting; recalled outright if they get lost
    if not landing then
        for _, esc in ipairs(squad.escorts) do
            if esc.isAir and alive(esc.driver) and alive(esc.veh)
                and player_veh ~= esc.veh and not esc.commandeered
                and not (squad.engaged and good_target(squad.targets[esc.driver])) then
                local d = dist(ENTITY.GET_ENTITY_COORDS(esc.veh, true), player_pos)
                -- planes range much wider by nature; only recall them if they
                -- genuinely get lost
                local leash = esc.isPlane and 900.0 or 350.0
                if d > leash then
                    local pos = offset_from_player(0.0, -15.0)
                    local up = esc.isPlane and 140.0 or 45.0
                    ENTITY.SET_ENTITY_COORDS(esc.veh, pos.x, pos.y, pos.z + up, false, false, false, false)
                    if not esc.isPlane then VEHICLE.SET_HELI_BLADES_FULL_SPEED(esc.veh) end
                end
                heli_follow(esc)
            end
        end
    end

    local key = ("%d|%d|%s|%d|%d|%s|%d|%d|%s|%s|%s|%d"):format(player_veh, my_veh,
        tostring(in_veh), style, follow_dist, wp_key, chf_style, chf_speed,
        tostring(landing), tostring(feat(ui.convoy_style):GetListIndex()),
        tostring(squad.protect_id), chase_ent)
    -- Orders used to be issued ONLY when this key changed. If a driver's task
    -- got cleared by anything else, nothing ever re-issued it and the vehicle
    -- sat there doing nothing forever. Now the key just forces an immediate
    -- refresh, and every driver is topped up at least every 8 seconds anyway.
    local force = false
    if key ~= squad.convoy_key then
        squad.convoy_key = key
        force = true
    end

    local air_slot, ground_slot = 0, 0
    for _, esc in ipairs(squad.escorts) do
        -- skip any vehicle you're driving yourself, no AI orders on it
        local due = alive(esc.driver) and alive(esc.veh) and not esc.commandeered
            and (force or esc.await_control or now - (esc.last_order or 0) > 8000)
        -- We must own BOTH the vehicle and its driver or every order below is
        -- silently discarded and the car just sits there. Control arrives a
        -- few frames after it's requested, so while we're still waiting we
        -- leave last_order alone and retry next tick rather than burning the
        -- 8-second refresh slot on an order nobody will ever receive.
        if due then
            local owned = ensure_control(esc.veh, now)
            if not ensure_control(esc.driver, now) then owned = false end
            esc.await_control = not owned
            due = owned
        end
        if due then
            esc.last_order = now
            -- taxi mode = YOU are riding in it while their driver still drives
            local is_taxi = my_veh == esc.veh and me ~= esc.driver
                and PED.GET_VEHICLE_PED_IS_IN(esc.driver, false) == esc.veh
            -- Only let a combat target suppress driving while that target is
            -- actually nearby. A stale one used to park the vehicle forever.
            local attacking = false
            if squad.engaged then
                local tgt = squad.targets[esc.driver]
                if good_target(tgt) then
                    attacking = dist(ENTITY.GET_ENTITY_COORDS(esc.veh, true),
                        ENTITY.GET_ENTITY_COORDS(tgt, true)) < 200.0
                end
            end

            if is_taxi then
                if wp_active then
                    if esc.isAir then
                        TASK.TASK_HELI_MISSION(esc.driver, esc.veh, 0, 0, wp.x, wp.y, wp.z + 40.0, 4, chf_speed + 25.0, 30.0, -1.0, 80, 30, 100.0, 0)
                    else
                        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(esc.driver, esc.veh, wp.x, wp.y, wp.z, chf_speed, chf_style, 8.0)
                    end
                elseif not esc.isAir then
                    TASK.TASK_VEHICLE_TEMP_ACTION(esc.driver, esc.veh, 27, 2500)
                end
                -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
            elseif chase_ent ~= 0 and not esc.isAir then
                -- run the target down. TASK_VEHICLE_CHASE is the game's own
                -- pursuit driving, the same behaviour cop cars use.
                TASK.CLEAR_PED_TASKS(esc.driver)
                pcall(TASK.TASK_VEHICLE_CHASE, esc.driver, chase_ent)
                PED.SET_DRIVER_AGGRESSIVENESS(esc.driver, 1.0)
                -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
            elseif not attacking and not PED.IS_PED_IN_COMBAT(esc.driver, 0) then
                if esc.isAir then
                    -- planes can't land on command usefully, so they just
                    -- keep circling regardless of the landing toggle
                    if landing and not esc.isPlane then
                        heli_land(esc, air_slot)
                        air_slot = air_slot + 1
                    else
                        heli_follow(esc)
                    end
                elseif in_veh then
                    -- convoy slot decides where this car rides relative to you
                    local mode = convoy[(ground_slot % #convoy) + 1]
                    ground_slot = ground_slot + 1
                    TASK.TASK_VEHICLE_ESCORT(esc.driver, esc.veh, player_veh, mode, 200.0, style, follow_dist + 0.0, 0, 15.0)
                else
                    TASK.TASK_VEHICLE_FOLLOW(esc.driver, esc.veh, player, 200.0, style, follow_dist)
                end
                -- [disabled] PED.SET_PED_KEEP_TASK(esc.driver, true)
            end
        end
    end
end

-- ---- Formation and Following Dynamics

local function follow_tick(now)
    if now < squad.next_follow_at then return end
    squad.next_follow_at = now + 2500
    if #squad.guards == 0 then return end

    -- guards follow whoever we're protecting (you by default)
    local player     = anchor_ped()
    local player_pos = ENTITY.GET_ENTITY_COORDS(player, true)
    local in_veh     = PED.IS_PED_IN_ANY_VEHICLE(player, false)
    local player_veh = in_veh and PED.GET_VEHICLE_PED_IS_IN(player, false) or 0
    local spacing    = feat(ui.spacing):GetIntValue() + 0.0

    -- guards sent after someone shouldn't be pulled back into formation
    if squad.hunt_groups.guards and hunt_ped() ~= 0 then return end

    for i, guard in ipairs(squad.guards) do
        local ped = guard.ped
        if alive(ped) and not guard.downed_at
            and squad.targets[ped] == nil and not PED.IS_PED_IN_COMBAT(ped, 0) then
            local ped_in_veh = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
            local ped_veh    = ped_in_veh and PED.GET_VEHICLE_PED_IS_IN(ped, false) or 0
            local d          = dist(player_pos, ENTITY.GET_ENTITY_COORDS(ped, true))

            if in_veh then
                -- you're driving: get them into a free seat, and keep
                -- retrying if the attempt got interrupted (they used to just
                -- give up and be left standing in the road)
                if ped_veh ~= player_veh and not guard.isAnimal then
                    if ped_in_veh then
                        TASK.TASK_LEAVE_VEHICLE(ped, ped_veh, 0)
                        guard.entering = false
                    elseif not guard.entering or now - (guard.entering_at or 0) > 8000 then
                        local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(player_veh))
                        local free = nil
                        for seat = 0, seats - 2 do
                            if VEHICLE.IS_VEHICLE_SEAT_FREE(player_veh, seat, false) then free = seat; break end
                        end
                        if free ~= nil then
                            TASK.CLEAR_PED_TASKS(ped)
                            TASK.TASK_ENTER_VEHICLE(ped, player_veh, 10000, free, 2.0, 1, 0)
                            guard.entering = true
                            guard.entering_at = now
                        end
                    end
                    squad.follow_issued[ped] = nil
                else
                    guard.entering = false
                end
            else
                guard.entering = false
                if ped_in_veh then
                    TASK.TASK_LEAVE_VEHICLE(ped, ped_veh, 0)
                    squad.follow_issued[ped] = nil
                else
                    local last = squad.follow_issued[ped]
                    if last == nil or now - last > 8000 then
                        squad.follow_issued[ped] = now
                        local right = ((i % 2 == 0) and 1.0 or -1.0) * (spacing * (0.6 + math.floor(i / 2) * 0.4))
                        local back  = -spacing - math.floor(i / 2) * spacing * 0.8
                        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(ped, player, right, back, 0.0, 2.0, -1, spacing, true)
                    end
                end
            end
        end
    end
end

-- ==== Auto-revive: downed guards get picked back up instead of just dying ====

local function revive_tick(now)
    if now < squad.next_revive_at then return end
    squad.next_revive_at = now + 500
    if not feat(ui.auto_revive):IsToggled() then
        for _, guard in ipairs(squad.guards) do guard.downed_at = nil end
        return
    end

    local delay = feat(ui.revive_delay):GetIntValue() * 1000
    for _, guard in ipairs(squad.guards) do
        local dead = (not ENTITY.DOES_ENTITY_EXIST(guard.ped))
            or ENTITY.IS_ENTITY_DEAD(guard.ped)
            or PED.IS_PED_DEAD_OR_DYING(guard.ped, true)
        if dead and ENTITY.DOES_ENTITY_EXIST(guard.ped) then
            if not guard.downed_at then
                guard.downed_at = now
            elseif now - guard.downed_at >= delay then
                pcall(PED.RESURRECT_PED, guard.ped)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(guard.ped)
                heal_ped(guard.ped)
                setup_combat(guard.ped, false, guard.isAnimal)
                give_loadout(guard.ped, guard.isAnimal)
                local group = PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
                PED.SET_PED_AS_GROUP_MEMBER(guard.ped, group)
                PED.SET_PED_NEVER_LEAVES_GROUP(guard.ped, true)
                guard.downed_at = nil
                squad.follow_issued[guard.ped] = nil
                toast(guard.name .. " is back up.")
            end
        elseif guard.downed_at then
            guard.downed_at = nil
        end
    end
end

------------------------------------------------------
-- Explosive rounds: guard bullets detonate where they land.
-- Throttled, and there's a safety bubble around you so you don't eat it.
----------------------------------------------------------------------

local impact_ptr = Memory.Alloc(24)

local function explosive_tick()
    if not feat(ui.exp_rounds):IsToggled() then return end
    if #squad.guards == 0 and #squad.escorts == 0 then return end

    local now = Time.GetEpocheMs()
    if now - squad.last_boom < 40 then return end
    local etype = picked(ui.exp_type, EXPLOSION_TYPES)[2]
    local ppos = ENTITY.GET_ENTITY_COORDS(player_ped(), true)
    -- bigger no-boom radius when you're driving, you're moving into it
    local bubble = PED.IS_PED_IN_ANY_VEHICLE(player_ped(), false) and 100.0 or 25.0

    local function boom_for(entry_ped, entry)
        if not alive(entry_ped) then return end
        if entry.next_boom and now < entry.next_boom then return end
        local held = WEAPON.GET_SELECTED_PED_WEAPON(entry_ped)
        if EXP_WEAPON_SKIP[held] then return end
        if not PED.IS_PED_SHOOTING(entry_ped) then return end
        if not WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(entry_ped, impact_ptr) then return end
        local ix = Memory.ReadFloat(impact_ptr)
        local iy = Memory.ReadFloat(impact_ptr + 8)
        local iz = Memory.ReadFloat(impact_ptr + 16)
        if ix == 0.0 and iy == 0.0 and iz == 0.0 then return end
        local dx, dy, dz = ix - ppos.x, iy - ppos.y, iz - ppos.z
        if dx * dx + dy * dy + dz * dz <= bubble then return end
        FIRE.ADD_OWNED_EXPLOSION(entry_ped, ix, iy, iz, etype, 1.0, true, false, 0.15)
        entry.next_boom = now + 200
        squad.last_boom = now
    end

    for _, guard in ipairs(squad.guards) do
        if not guard.downed_at then pcall(boom_for, guard.ped, guard) end
    end
    for _, esc in ipairs(squad.escorts) do
        for _, pass in ipairs(esc.peds) do
            esc.boom_slots = esc.boom_slots or {}
            esc.boom_slots[pass] = esc.boom_slots[pass] or {}
            pcall(boom_for, pass, esc.boom_slots[pass])
        end
    end
end

------------------------------------------------------------
-- Settings Enforcement Loop

local function settings_tick(now)
    if now < squad.next_apply_at then return end
    squad.next_apply_at = now + 1000

    -- re-bond every 5s: your relationship group changes on session migration
    -- and a stale bond is what makes guards suddenly turn on you
    if now >= squad.rel_refresh_at then
        squad.rel_refresh_at = now + 5000
        bond_relationships()
    end

    local god       = feat(ui.god):IsToggled()
    local no_rag    = feat(ui.no_ragdoll):IsToggled()
    local auto_heal = feat(ui.auto_heal):IsToggled()
    local invis     = feat(ui.invisible):IsToggled()
    local loc_vis   = feat(ui.local_visible):IsToggled()
    local exp_on    = feat(ui.exp_rounds):IsToggled()
    local accuracy  = feat(ui.accuracy):GetIntValue()
    local max_hp    = feat(ui.health):GetIntValue()
    local move      = picked(ui.behaviour, BEHAVIOURS)[2]
    local defensive = move == 1
    local see_range = feat(ui.engage_range):GetIntValue() + 0.0
    local esc_see   = feat(ui.esc_range):GetIntValue() + 0.0

    -- Same principle for the rest: writing combat attributes, ranges and
    -- movement onto every ped once a second keeps interrupting their AI.
    -- Only push when a setting actually changed, or the ped is new.
    local set_sig = ("%s|%s|%s|%s|%s|%d|%d|%d|%.0f|%.0f"):format(
        tostring(god), tostring(no_rag), tostring(invis), tostring(loc_vis),
        tostring(exp_on), accuracy, max_hp, move, see_range, esc_see)

    for_each_squad_ped(function(ped, guard)
        apply_friendly_protection(ped)
        -- auto-heal must be evaluated continuously
        if auto_heal and ENTITY.GET_ENTITY_HEALTH(ped) < max_hp * 0.5 then
            heal_ped(ped)
        end
        if squad.ped_sig[ped] == set_sig then return end
        squad.ped_sig[ped] = set_sig

        ENTITY.SET_ENTITY_INVINCIBLE(ped, god)
        -- anyone seated in a vehicle stays ragdoll-locked regardless of the
        -- toggle, otherwise they flail around the cabin when it rolls
        local seated = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
        PED.SET_PED_CAN_RAGDOLL(ped, (not no_rag) and not seated)
        -- THE bodyguard-in-a-vehicle bug: guards are allowed to leave a
        -- vehicle (attribute 3), so when told to fight they climb OUT instead
        -- of using the car's guns. Escort crew have it off, which is exactly
        -- why they work. Lock it while seated, restore it on foot.
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 3, not seated)
        ENTITY.SET_ENTITY_MAX_HEALTH(ped, max_hp)
        -- explosion-proof only while their own rounds explode
        pcall(ENTITY.SET_ENTITY_PROOFS, ped, false, false, exp_on, false, false, false, false, false)
        if not (guard and guard.isAnimal) then
            PED.SET_PED_ACCURACY(ped, accuracy)
            -- The Behaviour setting is a BODYGUARD setting. It was also being
            -- applied to escort crews, so with the default (Defensive) their
            -- always-fight flag was switched off and gunners refused to
            -- engage. Vehicle crews always keep it on - they can't leave the
            -- vehicle anyway, so they can't run off and start trouble.
            local is_guard = guard ~= nil
            local hold_fire = is_guard and defensive or false
            if is_guard then PED.SET_PED_COMBAT_MOVEMENT(ped, move) end
            PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5,  not hold_fire)
            PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, not hold_fire)
            PED.SET_PED_COMBAT_ATTRIBUTES(ped, 26, not hold_fire)
            PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
            if not is_guard then
                -- keep the crew's vehicle-combat flags pinned on
                PED.SET_PED_COMBAT_ATTRIBUTES(ped, 2,  true)  -- drivebys
                PED.SET_PED_COMBAT_ATTRIBUTES(ped, 3,  false) -- stay in vehicle
                PED.SET_PED_COMBAT_ATTRIBUTES(ped, 52, true)  -- vehicle attack
                PED.SET_PED_COMBAT_ATTRIBUTES(ped, 53, true)  -- mounted guns
            end
            -- crews get their own (usually much longer) reach so they can
            -- act as anti-air; combat range 2 = "far" so they'll take shots
            local r = is_guard and see_range or esc_see
            PED.SET_PED_SEEING_RANGE(ped, r)
            PED.SET_PED_HEARING_RANGE(ped, r)
            PED.SET_PED_ID_RANGE(ped, r)
            PED.SET_PED_COMBAT_RANGE(ped, r > 120.0 and 2 or 1)
        end
        if invis then
            if loc_vis then
                ENTITY.SET_ENTITY_VISIBLE(ped, true, false)
                pcall(ENTITY.SET_ENTITY_ALPHA, ped, 180, false)
            else
                ENTITY.SET_ENTITY_VISIBLE(ped, false, false)
            end
        else
            ENTITY.SET_ENTITY_VISIBLE(ped, true, false)
            pcall(ENTITY.SET_ENTITY_ALPHA, ped, 255, false)
        end
    end)

    local god_veh  = feat(ui.esc_god_veh):IsToggled()
    local sirens   = feat(ui.sirens):IsToggled()
    local blackout = feat(ui.blackout):IsToggled()
    local jackable = feat(ui.jackable):IsToggled()
    local esc_col  = picked(ui.esc_color, ESCORT_COLORS)[2]
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.veh) then
            ENTITY.SET_ENTITY_INVINCIBLE(esc.veh, god_veh)
            VEHICLE.SET_VEHICLE_SIREN(esc.veh, sirens)
            -- Persistence. SET_ENTITY_AS_MISSION_ENTITY must only ever be
            -- called ONCE per entity. Calling it repeatedly re-registers the
            -- ped every second and wipes its AI state, which froze the whole
            -- crew solid for as long as the script was running. They only
            -- came back to life when the script was switched off.
            if not feat(ui.esc_despawn):IsToggled() then
                keep_alive(esc.veh)
                keep_alive(esc.driver)
                for _, pass in ipairs(esc.peds) do keep_alive(pass) end
            end
            -- keep the doors open to you and the driver pullable-out
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(esc.veh, 1)
            pcall(VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER, esc.veh, PLAYER.PLAYER_ID(), false)
            if alive(esc.driver) then
                pcall(PED.SET_PED_CAN_BE_DRAGGED_OUT, esc.driver, jackable)
                PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(esc.driver, jackable and 0 or 1)
            end
            if blackout then
                VEHICLE.SET_VEHICLE_COLOURS(esc.veh, 12, 12)
                VEHICLE.SET_VEHICLE_EXTRA_COLOURS(esc.veh, 12, 12)
                VEHICLE.SET_VEHICLE_WINDOW_TINT(esc.veh, 1)
            elseif esc_col >= 0 then
                VEHICLE.SET_VEHICLE_COLOURS(esc.veh, esc_col, esc_col)
                VEHICLE.SET_VEHICLE_EXTRA_COLOURS(esc.veh, esc_col, esc_col)
            end
        end
    end

    local blip_col = picked(ui.blip_color, BLIP_COLORS)[2]
    for _, guard in ipairs(squad.guards) do
        if guard.blip ~= nil and guard.blip ~= 0 then
            pcall(HUD.SET_BLIP_COLOUR, guard.blip, blip_col)
        end
    end

    if #squad.guards > 0 then
        local group = PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
        PED.SET_GROUP_FORMATION(group, picked(ui.formation, FORMATIONS)[2])
        PED.SET_GROUP_FORMATION_SPACING(group, feat(ui.spacing):GetIntValue() + 0.0, -1.0, -1.0)
        local keep = not feat(ui.esc_despawn):IsToggled()
        for _, guard in ipairs(squad.guards) do
            if alive(guard.ped) then
                if not PED.IS_PED_GROUP_MEMBER(guard.ped, group) then
                    PED.SET_PED_AS_GROUP_MEMBER(guard.ped, group)
                    PED.SET_PED_NEVER_LEAVES_GROUP(guard.ped, true)
                end
                -- stop the game culling guards you've left behind
                if keep then keep_alive(guard.ped) end
            end
        end
    end
end

-- UI Status Tracking & Respawn Loop
---------------------------------------

local function status_tick(now)
    if now < squad.next_status_at then return end
    squad.next_status_at = now + 600

    prune_dead()

    local player_pos = ENTITY.GET_ENTITY_COORDS(player_ped(), true)
    local info = {}
    for _, guard in ipairs(squad.guards) do
        if ENTITY.DOES_ENTITY_EXIST(guard.ped) then
            info[#info + 1] = {
                ped     = guard.ped,
                name    = guard.name,
                hp      = ENTITY.GET_ENTITY_HEALTH(guard.ped),
                maxhp   = ENTITY.GET_ENTITY_MAX_HEALTH(guard.ped),
                dist    = math.floor(dist(player_pos, ENTITY.GET_ENTITY_COORDS(guard.ped, true))),
                downed  = guard.downed_at ~= nil,
            }
        end
    end
    squad.guard_info = info

    local count = 0
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.driver) then count = count + 1 end
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then count = count + 1 end
        end
    end
    squad.escorts_alive = count

    -- Live readout for the Convoy > Diagnostics panel.
    -- "The escorts do nothing" has half a dozen possible causes that all look
    -- identical from the driver's seat - no network control, a dead driver, no
    -- target, tasks being cleared. Rather than guess again, sample the whole
    -- chain here (the render thread must not call natives itself) so the panel
    -- can show which link is actually broken.
    local rows = {}
    for i, esc in ipairs(squad.escorts) do
        local row = { idx = i, air = esc.isAir, plane = esc.isPlane }
        if alive(esc.veh) then
            row.veh_net  = net_is_networked(esc.veh)
            row.veh_ctrl = net_has_control(esc.veh)
            row.dist     = math.floor(dist(player_pos, ENTITY.GET_ENTITY_COORDS(esc.veh, true)))
            pcall(function() row.speed = ENTITY.GET_ENTITY_SPEED(esc.veh) end)
            pcall(function() row.veh_hp = math.floor(VEHICLE.GET_VEHICLE_ENGINE_HEALTH(esc.veh)) end)
        end
        if alive(esc.driver) then
            row.drv       = true
            row.drv_ctrl  = net_has_control(esc.driver)
            row.drv_hp    = ENTITY.GET_ENTITY_HEALTH(esc.driver)
            row.drv_seat  = PED.IS_PED_IN_VEHICLE(esc.driver, esc.veh, false)
        end
        local crew, ctrl, fighting, shooting = 0, 0, 0, 0
        for _, pass in ipairs(esc.peds) do
            if alive(pass) then
                crew = crew + 1
                if net_has_control(pass) then ctrl = ctrl + 1 end
                if PED.IS_PED_IN_COMBAT(pass, 0) then fighting = fighting + 1 end
                if now - (squad.gunner_shot[pass] or 0) < 3000 then shooting = shooting + 1 end
            end
        end
        row.crew, row.crew_ctrl  = crew, ctrl
        row.fighting, row.shooting = fighting, shooting
        row.waiting   = esc.await_control and true or false
        row.order_age = math.floor((now - (esc.last_order or now)) / 1000)
        rows[#rows + 1] = row
    end
    squad.diag = {
        session  = net_in_session(),
        owned    = squad.net_owned or 0,
        lost     = squad.net_lost or 0,
        pvp      = players_allowed(),
        p_seen   = squad.pvp_seen or 0,
        p_hot    = squad.pvp_hostile or 0,
        threats  = squad.threat_count or 0,
        hunt     = squad.hunt_id,
        bond     = squad.bg_group and true or false,
        rows     = rows,
    }

    for i = #squad.respawn_queue, 1, -1 do
        if now >= squad.respawn_queue[i].dueAt then
            table.remove(squad.respawn_queue, i)
            if #squad.guards < MAX_BODYGUARDS then
                spawn_guards(1, false)
            end
        end
    end
end

-- Catch-up teleport. The single most reliable cure for "they stopped
-- following me", whatever went wrong with their pathing, group state or
-- tasks, a guard that falls too far behind is simply put back at your side.
local function catchup_tick(now)
    if #squad.guards == 0 then return end
    if not feat(ui.auto_tp):IsToggled() then return end
    if now < (squad.next_catchup or 0) then return end
    squad.next_catchup = now + 1000

    -- don't drag guards home while they're on their way to a target you sent
    -- them after - that's what kept cancelling the hunt
    if squad.hunt_groups.guards and hunt_ped() ~= 0 then return end

    local anchor = anchor_ped()
    local apos = ENTITY.GET_ENTITY_COORDS(anchor, true)
    local limit = feat(ui.tp_distance):GetIntValue() + 0.0
    local in_veh = PED.IS_PED_IN_ANY_VEHICLE(anchor, false)

    for i, guard in ipairs(squad.guards) do
        local ped = guard.ped
        if alive(ped) and not guard.downed_at then
            -- don't yank someone mid-fight or mid-boarding
            if not PED.IS_PED_IN_COMBAT(ped, 0) and not guard.entering then
                local d = dist(apos, ENTITY.GET_ENTITY_COORDS(ped, true))
                if d > limit then
                    if in_veh then
                        -- you're driving: put them straight in a seat if
                        -- there's one, otherwise drop them alongside
                        local veh = PED.GET_VEHICLE_PED_IS_IN(anchor, false)
                        local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(veh))
                        local free = nil
                        for s = 0, seats - 2 do
                            if VEHICLE.IS_VEHICLE_SEAT_FREE(veh, s, false) then free = s; break end
                        end
                        if free ~= nil and not guard.isAnimal then
                            PED.SET_PED_INTO_VEHICLE(ped, veh, free)
                        else
                            local a = (i / math.max(1, #squad.guards)) * math.pi * 2
                            ENTITY.SET_ENTITY_COORDS(ped, apos.x + math.cos(a) * 4.0,
                                apos.y + math.sin(a) * 4.0, apos.z, false, false, false, false)
                        end
                    else
                        local a = (i / math.max(1, #squad.guards)) * math.pi * 2
                        ENTITY.SET_ENTITY_COORDS(ped, apos.x + math.cos(a) * 3.0,
                            apos.y + math.sin(a) * 3.0, apos.z, false, false, false, false)
                    end
                    TASK.CLEAR_PED_TASKS(ped)
                    squad.follow_issued[ped] = nil
                end
            end
        end
    end
end

-- Righting flipped escort vehicles. This runs on the FAST loop (4x a second)
-- because the crew jitter happens while the car is over on its side, the
-- 2s convoy tick was far too slow to catch it, and IS_VEHICLE_STUCK_ON_ROOF
-- takes several seconds on its own. Crew also get ragdoll disabled while
-- seated so they can't flop around inside the cabin during the roll.
local function flip_tick(now)
    if #squad.escorts == 0 then return end
    if not feat(ui.auto_flip):IsToggled() then return end

    for _, esc in ipairs(squad.escorts) do
        if alive(esc.veh) and not esc.isAir and not esc.commandeered then
            local upright = true
            pcall(function() upright = ENTITY.IS_ENTITY_UPRIGHT(esc.veh, 40.0) end)
            if not upright then
                local since = squad.flipped_since[esc.veh]
                if since == nil then
                    squad.flipped_since[esc.veh] = now
                    -- lock the crew down immediately so they stop thrashing
                    for _, pass in ipairs(esc.peds) do
                        if alive(pass) then pcall(PED.SET_PED_CAN_RAGDOLL, pass, false) end
                    end
                    if alive(esc.driver) then pcall(PED.SET_PED_CAN_RAGDOLL, esc.driver, false) end
                elseif now - since > 700 then
                    squad.flipped_since[esc.veh] = nil
                    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(esc.veh, 5.0)
                    -- re-seat anyone thrown out or left clinging to the shell
                    for _, pass in ipairs(esc.peds) do
                        if alive(pass) and not PED.IS_PED_IN_VEHICLE(pass, esc.veh, false) then
                            local s = esc.seats[pass]
                            if s ~= nil then pcall(PED.SET_PED_INTO_VEHICLE, pass, esc.veh, s) end
                        end
                    end
                    if alive(esc.driver) and not PED.IS_PED_IN_VEHICLE(esc.driver, esc.veh, false) then
                        pcall(PED.SET_PED_INTO_VEHICLE, esc.driver, esc.veh, -1)
                    end
                    squad.convoy_key = ""
                end
            else
                squad.flipped_since[esc.veh] = nil
            end
        end
    end
end

-- Thread Loop Execution
-- Runs one subsystem in isolation and names it if it fails, so a fault in
-- one place can never take the rest of the script down with it.
local function run_tick(name, fn, now)
    local ok, err = pcall(fn, now)
    if ok then return end
    Logger.LogError("[Bodyguard Squad V3] " .. name .. " tick: " .. tostring(err))
    squad.fault[name] = (squad.fault[name] or 0) + 1
    if squad.fault[name] == 1 then
        GUI.AddToast("Bodyguard Squad V3", "'" .. name .. "' failed - see log", 6000)
    end
end

Script.RegisterLooped(function()
    if not squad.ready then
        Script.Yield(250)
        return
    end
    local ok, err = pcall(function()
        local now = Time.GetEpocheMs()

        -- When you die and respawn the game hands you a NEW ped handle, and
        -- the old one gets recycled. Sometimes onto another player. Any task
        -- still holding the old handle then follows THEM. That's the "my
        -- convoy escorted the guy who killed me" bug. Detect the swap and
        -- throw away every cached handle so everything re-targets you.
        local me = player_ped()
        if me ~= squad.last_player_ped then
            squad.last_player_ped = me
            squad.convoy_key    = ""
            squad.targets       = {}
            squad.follow_issued = {}
            squad.gunner_stage  = {}
            squad.gunner_check  = {}
            squad.gunner_locked = {}
            squad.vendetta      = {}
            squad.engaged       = false
            squad.guards_engaged = false
            bond_relationships()
        end

        -- sample gunner fire at loop rate; ai_tick uses this to tell whether
        -- a firing method is actually working
        for _, esc in ipairs(squad.escorts) do
            for _, pass in ipairs(esc.peds) do
                if alive(pass) and PED.IS_PED_SHOOTING(pass) then
                    squad.gunner_shot[pass] = now
                end
            end
        end

        -- Each subsystem gets its OWN pcall. They all used to share one, so a
        -- single failure anywhere killed every system after it - driving,
        -- settings and combat all at once. That is exactly what "the escorts
        -- can't move, can't be hurt and never do anything" looks like: the
        -- driving tick and the settings tick both stop running, so nothing
        -- steers them and nothing ever clears their invincibility.
        run_tick("flip",     flip_tick,     now)
        run_tick("catchup",  catchup_tick,  now)
        run_tick("convoy",   convoy_tick,   now)
        run_tick("ai",       ai_tick,       now)
        run_tick("follow",   follow_tick,   now)
        run_tick("weapons",  smart_weapon_tick, now)
        run_tick("revive",   revive_tick,   now)
        run_tick("settings", settings_tick, now)
        run_tick("status",   status_tick,   now)
    end)
    if not ok then
        Logger.LogError("[Bodyguard Squad V3] outer loop: " .. tostring(err))
        if squad.last_err ~= tostring(err) then
            squad.last_err = tostring(err)
            GUI.AddToast("Bodyguard Squad V3", "Loop error, see log", 5000)
        end
    end
    Script.Yield(250)
end)

-- Explosive rounds needs to run fast to catch the impact, so it's its own loop
Script.RegisterLooped(function()
    if squad.ready then pcall(explosive_tick) end
    Script.Yield(50)
end)

------------------------------------------------
-- ESP overlay (drawn every frame while the game is running)
--------------------------------------------------------------

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if not squad.ready then return end
    local show_name = feat(ui.esp_name):IsToggled()
    local show_hp   = feat(ui.esp_health):IsToggled()
    local show_dist = feat(ui.esp_distance):IsToggled()
    local show_line = feat(ui.esp_tracer):IsToggled()
    if not (show_name or show_hp or show_dist or show_line) then return end
    if #squad.guards == 0 then return end

    pcall(function()
        local ppos = ENTITY.GET_ENTITY_COORDS(player_ped(), true)
        local dw, dh = ImGui.GetDisplaySize()

        for _, guard in ipairs(squad.guards) do
            if ENTITY.DOES_ENTITY_EXIST(guard.ped) then
                local gpos = ENTITY.GET_ENTITY_COORDS(guard.ped, true)
                local d = dist(ppos, gpos)
                local hp = ENTITY.GET_ENTITY_HEALTH(guard.ped)
                local maxhp = ENTITY.GET_ENTITY_MAX_HEALTH(guard.ped)
                if maxhp <= 0 then maxhp = 1 end
                local ratio = math.max(0.0, math.min(1.0, hp / maxhp))
                local red   = math.floor((1 - ratio) * 255)
                local green = math.floor(ratio * 220)

                local sx, sy = GTA.WorldToScreen(gpos.x, gpos.y, gpos.z + 1.0)
                if sx and sy and sx > 0.0 and sy > 0.0 then
                    local px, py = sx * dw, sy * dh
                    if show_line then
                        ImGui.AddLine(dw * 0.5, dh, px, py, red, green, 80, 150, 1.5)
                    end
                    local label = ""
                    if guard.downed_at then
                        label = guard.name .. "  DOWN"
                    else
                        if show_name then label = guard.name end
                        if show_dist then
                            if #label > 0 then label = label .. "  |  " end
                            label = label .. string.format("%.0fm", d)
                        end
                    end
                    local y = py
                    if #label > 0 then
                        local w = #label * 7
                        ImGui.AddRectFilled(px - w * 0.5 - 6, y - 3, px + w * 0.5 + 6, y + 15, 12, 14, 20, 190, 4.0)
                        ImGui.AddText(px - w * 0.5, y, label, 235, 240, 250, 255)
                        y = y + 20
                    end
                    if show_hp then
                        local bw, bh = 64, 6
                        local x1 = px - bw * 0.5
                        ImGui.AddRectFilled(x1 - 1, y - 1, x1 + bw + 1, y + bh + 1, 10, 10, 14, 200, 2.0)
                        ImGui.AddRectFilled(x1, y, x1 + bw * ratio, y + bh, red, green, 70, 235, 2.0)
                    end
                end
            end
        end
    end)
end)

-- ---- UI Menu Construction

local function button(id, label, tip, fn)
    FeatureMgr.AddFeature(id, label, eFeatureType.Button, tip, function()
        Script.QueueJob(function()
            local ok, err = pcall(fn)
            if not ok then
                Logger.LogError("[Bodyguard Squad V3] " .. label .. ": " .. tostring(err))
                GUI.AddToast("Bodyguard Squad V3", label .. " failed - check logs.", 4000)
            end
        end)
    end)
end

local function combo(id, label, tip, list, callback)
    local names = {}
    for _, item in ipairs(list) do names[#names + 1] = item[1] end
    FeatureMgr.AddFeature(id, label, eFeatureType.Combo, tip, callback):SetList(names)
end

-- category combo that repopulates a second combo (used for models + weapons)
local function linked_combo(cat_id, item_id, cat_label, item_label, cat_tip, item_tip, data)
    local cat_names = {}
    for _, c in ipairs(data) do cat_names[#cat_names + 1] = c.n end
    FeatureMgr.AddFeature(cat_id, cat_label, eFeatureType.Combo, cat_tip, function(f)
        local cat = data[f:GetListIndex() + 1]
        if cat then
            local names = {}
            for _, it in ipairs(cat.list) do names[#names + 1] = it.n end
            local child = feat(item_id)
            child:SetList(names)
            child:SetListIndex(0)
        end
    end):SetList(cat_names)

    local first = {}
    for _, it in ipairs(data[1].list) do first[#first + 1] = it.n end
    FeatureMgr.AddFeature(item_id, item_label, eFeatureType.Combo, item_tip):SetList(first)
end

-- Squad Tab
FeatureMgr.AddFeature(ui.spawn_count, "Spawn Count", eFeatureType.SliderInt, "How many bodyguards to spawn."):SetLimitValues(1, 7):SetDefaultValue(1):Reset()
linked_combo(ui.model_cat, ui.model_preset, "Model Category", "Bodyguard Type",
    "Pick a category, then the model below.", "Who to spawn (also used for escort crews).", MODEL_CATS)
FeatureMgr.AddFeature(ui.guard_model, "Custom Model", eFeatureType.InputText, "Used when type is 'Custom'."):SetStringValue("s_m_y_blackops_01")
FeatureMgr.AddFeature(ui.random_outfit, "Randomize Outfits", eFeatureType.Toggle, "Varied clothing component presets.")
FeatureMgr.AddFeature(ui.friend_safe, "Friend-Safe Models (Spam Protection)", eFeatureType.Toggle,
    "Cherax Spam Protection blocks freemode peds sent by other players, so Clone-of-You and the GTA Online models are invisible to your friends. ON: substitutes a model that gets through. OFF: keeps your pick, only useful if your friends have whitelisted the model or turned Spam Protection off for you.")
    :SetDefaultValue(true):Reset()
button(ui.spawn_guard, "Spawn Bodyguard(s)", "Spawn squad members up to max group size.", btn_spawn_guards)
button(ui.spawn_clone, "Spawn Clone of Me", "Spawns a duplicate player ped as a bodyguard.", btn_spawn_clone)

linked_combo(ui.pri_cat, ui.primary, "Primary Category", "Primary Weapon",
    "Weapon class for the main gun.", "Carried on foot.", WEAPON_CATS)
FeatureMgr.AddFeature(ui.give_primary, "Give Primary", eFeatureType.Toggle, "Hand out the primary weapon."):SetDefaultValue(true):Reset()
linked_combo(ui.sec_cat, ui.secondary, "Secondary Category", "Secondary Weapon",
    "Use Pistols or SMGs - those are the only ones usable inside a vehicle.",
    "The in-vehicle / driveby weapon.", WEAPON_CATS)
FeatureMgr.AddFeature(ui.give_secondary, "Give Secondary", eFeatureType.Toggle, "Hand out the vehicle weapon."):SetDefaultValue(true):Reset()
button(ui.apply_loadout, "Apply Loadout To Squad", "Re-equips weapons for all alive squad peds.", btn_apply_loadout)
FeatureMgr.AddFeature(ui.exp_rounds, "Explosive Rounds", eFeatureType.Toggle, "Squad bullets detonate on impact (safe bubble around you).")
combo(ui.exp_type, "Explosion Type", "What their rounds detonate as.", EXPLOSION_TYPES)

FeatureMgr.AddFeature(ui.killable, "Killable By Me", eFeatureType.Toggle,
    "ON: you can lock onto and shoot your own squad. OFF: gray crosshair, your bullets ignore them."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.god, "God Mode", eFeatureType.Toggle, "Squad invincibility toggle.")
FeatureMgr.AddFeature(ui.no_ragdoll, "No Ragdoll", eFeatureType.Toggle, "Prevents knockdown physics.")
FeatureMgr.AddFeature(ui.invisible, "Invisible", eFeatureType.Toggle, "Hides the squad.")
FeatureMgr.AddFeature(ui.local_visible, "Locally Visible", eFeatureType.Toggle, "With Invisible on, you still see them faintly.")
FeatureMgr.AddFeature(ui.auto_respawn, "Auto-Respawn Dead Guards", eFeatureType.Toggle, "Replaces eliminated guards in 5 seconds.")
FeatureMgr.AddFeature(ui.auto_heal, "Auto-Heal Squad", eFeatureType.Toggle, "Heals unit whenever health drops below 50%.")
FeatureMgr.AddFeature(ui.auto_revive, "Auto-Revive Downed", eFeatureType.Toggle, "Brings downed guards back instead of losing them.")
FeatureMgr.AddFeature(ui.revive_delay, "Revive Delay", eFeatureType.SliderInt, "Seconds before a downed guard gets back up."):SetLimitValues(1, 20):SetDefaultValue(8):Reset()
FeatureMgr.AddFeature(ui.callouts, "Combat Callouts", eFeatureType.Toggle, "Guards shout when a fight starts.")
FeatureMgr.AddFeature(ui.accuracy, "Accuracy", eFeatureType.SliderInt, "Squad weapon shooting accuracy."):SetLimitValues(0, 100):SetDefaultValue(85):Reset()
FeatureMgr.AddFeature(ui.health, "Max Health", eFeatureType.SliderInt, "Squad health pool limits."):SetLimitValues(100, 2000):SetDefaultValue(300):Reset()
FeatureMgr.AddFeature(ui.armor, "Armor", eFeatureType.SliderInt, "Squad armor value."):SetLimitValues(0, 300):SetDefaultValue(100):Reset()
combo(ui.blip_color, "Blip Color", "Map marker radar color.", BLIP_COLORS)
combo(ui.formation, "Formation", "Walking formation layout.", FORMATIONS)
FeatureMgr.AddFeature(ui.spacing, "Formation Spacing", eFeatureType.SliderInt, "Slot distance multiplier."):SetLimitValues(1, 10):SetDefaultValue(2):Reset()
combo(ui.behaviour, "Behaviour", "Combat AI aggressive/defensive mode.", BEHAVIOURS)
FeatureMgr.AddFeature(ui.auto_tp, "Auto-Teleport When Left Behind", eFeatureType.Toggle,
    "Snaps guards back to you if they fall too far behind, so they can never get stuck or lost."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.tp_distance, "Catch-Up Distance", eFeatureType.SliderInt,
    "How far a guard may fall behind before being pulled back to you."):SetLimitValues(15, 200):SetDefaultValue(45):Reset()
FeatureMgr.AddFeature(ui.pursuit, "Pursuit Time", eFeatureType.SliderInt,
    "Seconds the squad keeps hunting someone after contact, even if you stop shooting. Lower it if they hold grudges too long."):SetLimitValues(3, 180):SetDefaultValue(15):Reset()
FeatureMgr.AddFeature(ui.engage_range, "Bodyguard Engage Range", eFeatureType.SliderInt,
    "How far your bodyguards look for and take on targets. Keep it low if they pick fights you didn't start."):SetLimitValues(20, 600):SetDefaultValue(90):Reset()
FeatureMgr.AddFeature(ui.esc_range, "Escort Engage Range", eFeatureType.SliderInt,
    "Reach of your vehicle crews. Crank it up to use them as anti-air against planes and Deluxos."):SetLimitValues(20, 600):SetDefaultValue(250):Reset()

FeatureMgr.AddFeature(ui.esp_name, "ESP: Name", eFeatureType.Toggle, "Draw guard names on screen.")
FeatureMgr.AddFeature(ui.esp_health, "ESP: Health Bar", eFeatureType.Toggle, "Draw guard health bars.")
FeatureMgr.AddFeature(ui.esp_distance, "ESP: Distance", eFeatureType.Toggle, "Draw distance to each guard.")
FeatureMgr.AddFeature(ui.esp_tracer, "ESP: Tracers", eFeatureType.Toggle, "Draw snaplines to each guard.")

button(ui.rally, "RALLY SQUAD", "Panic button: Teleport and fully repair/heal entire force.", btn_rally)
button(ui.tp_all, "Teleport All To Me", "Teleports squad members to player coordinates.", btn_tp_guards)
button(ui.heal_all, "Heal All", "Restores max health and armor to all members.", btn_heal_guards)
button(ui.warp_in_veh, "Warp Into My Vehicle", "Fills current player vehicle free seats.", btn_warp_into_vehicle)
button(ui.steal_cars, "Steal Nearby Cars", "Commands foot guards to commandeer closest vehicles.", btn_steal_cars)
button(ui.dismiss_all, "Dismiss All (walk away)", "Releases squad to standard wander tasking.", btn_dismiss_guards)
button(ui.del_guards, "Delete All Bodyguards", "Instantly deletes squad entities.", btn_delete_guards)

-- Escort Convoy Tab
linked_combo(ui.esc_model_cat, ui.esc_model, "Crew Category", "Escort Crew Model",
    "Pick a category, then the model below.", "Who mans the escort vehicles.", MODEL_CATS)
FeatureMgr.AddFeature(ui.esc_model_txt, "Custom Crew Model", eFeatureType.InputText,
    "Used when the escort crew type is 'Custom'."):SetStringValue("s_m_y_blackops_01")

local cat_names = {}
for _, cat in ipairs(VEHICLE_DB) do cat_names[#cat_names + 1] = cat[1] end
FeatureMgr.AddFeature(ui.esc_veh_cat, "Vehicle Category", eFeatureType.Combo, "Select vehicle menu category.", function(f)
    local cat = VEHICLE_DB[f:GetListIndex() + 1]
    if cat ~= nil then
        local names = {}
        for _, v in ipairs(cat[2]) do names[#names + 1] = v[1] end
        local veh_combo = feat(ui.esc_veh_model)
        veh_combo:SetList(names)
        veh_combo:SetListIndex(0)
    end
end):SetList(cat_names)

do
    local names = {}
    for _, v in ipairs(VEHICLE_DB[1][2]) do names[#names + 1] = v[1] end
    FeatureMgr.AddFeature(ui.esc_veh_model, "Vehicle", eFeatureType.Combo, "Select model from category."):SetList(names)
end

FeatureMgr.AddFeature(ui.esc_veh_text, "Custom Vehicle Model", eFeatureType.InputText, "Custom string vehicle model name."):SetStringValue("stretch")
FeatureMgr.AddFeature(ui.esc_count, "Escort Count", eFeatureType.SliderInt, "Amount of escort units to spawn."):SetLimitValues(1, 30):SetDefaultValue(4):Reset()
FeatureMgr.AddFeature(ui.esc_fill, "Fill Vehicle", eFeatureType.Toggle, "Packs crew into multi-seat transport vehicles."):SetDefaultValue(true):Reset()
combo(ui.esc_mode, "Combat Mode", "Convoy combat logic settings.", ESCORT_MODES)
feat(ui.esc_mode):SetListIndex(2)
combo(ui.esc_style, "Driving Style", "Convoy driving behavior flag.", DRIVE_STYLES)
combo(ui.convoy_style, "Convoy Formation", "Where escort cars ride relative to you.", CONVOY_STYLES)
FeatureMgr.AddFeature(ui.esc_distance, "Escort Distance", eFeatureType.SliderInt, "Formation follow distance."):SetLimitValues(5, 40):SetDefaultValue(12):Reset()
FeatureMgr.AddFeature(ui.auto_promote, "Crew Replaces Dead Driver", eFeatureType.Toggle,
    "ON: a passenger slides into the driver seat when the driver dies. OFF: nobody replaces him. Kill the driver and the car is yours to steal."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.jackable, "Let Me Jack Escort Cars", eFeatureType.Toggle,
    "Lets you drag the escort driver out and take the wheel (needs 'Killable By Me' on to aim at him)."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.esc_god_veh, "Invincible Vehicles", eFeatureType.Toggle, "Convoy vehicle god mode toggle.")
FeatureMgr.AddFeature(ui.esc_tune, "Max Tune Vehicles", eFeatureType.Toggle, "Performance mods only: engine, brakes, transmission, suspension, armour, turbo."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.esc_upgrade, "Full Upgrade (everything)", eFeatureType.Toggle,
    "Every mod slot maxed - body kits, spoilers, roll cage, wheels, plus bulletproof tyres and strong axles. Overrides Max Tune.")
FeatureMgr.AddFeature(ui.esc_despawn, "Let Escorts Despawn", eFeatureType.Toggle,
    "OFF (default): your convoy is kept loaded and won't vanish when you travel far. ON: the game cleans them up normally.")
FeatureMgr.AddFeature(ui.esc_strong, "Reinforced Bodies", eFeatureType.Toggle, "Escort vehicles shrug off collision damage."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.auto_flip, "Auto-Flip Escorts", eFeatureType.Toggle, "Rights escort vehicles stuck on their roof."):SetDefaultValue(true):Reset()
FeatureMgr.AddFeature(ui.searchlight, "Heli Searchlight", eFeatureType.Toggle, "Turns on searchlights for helis that have one.")
FeatureMgr.AddFeature(ui.sirens, "Sirens On", eFeatureType.Toggle, "Enables vehicle sirens.")
combo(ui.esc_color, "Escort Colour", "Repaints the whole convoy. 'Blacked-Out' overrides this.", ESCORT_COLORS)
FeatureMgr.AddFeature(ui.blackout, "Blacked-Out Convoy", eFeatureType.Toggle, "Applies dark tint and matte black paints.")
-- flipping this has to re-bond straight away. the squad is bonded COMPANION to
-- the player group while it's off, and a ped will not shoot a companion no
-- matter what task you hand it, so waiting for the 5s refresh means the first
-- few seconds after switching it on do nothing.
combo(ui.allow_players, "Engagement Policy",
    "NPCs Only keeps the squad off real players entirely. Switch to NPCs + Players only in a private lobby where everyone's in on it.",
    TARGET_POLICIES,
    function()
        Script.QueueJob(function()
            init_relationships()
            bond_relationships()
            for_each_squad_ped(function(ped)
                apply_friendly_protection(ped, true)
            end)
            squad.targets = {}
            squad.convoy_key = ""
            toast(players_allowed()
                and "Players can now be targeted."
                or  "Back to NPCs only.")
        end)
    end)
FeatureMgr.AddFeature(ui.air_alt, "Air Escort Altitude", eFeatureType.SliderInt,
    "How high helicopters hold station above you. Planes fly higher than this since they can't hover."):SetLimitValues(20, 300):SetDefaultValue(45):Reset()
FeatureMgr.AddFeature(ui.heli_land, "Land Helis Near Me", eFeatureType.Toggle, "Commands escort helicopters to land for pickup.")
combo(ui.chf_style, "Chauffeur Style", "Taxi mode navigation driving style.", CHAUFFEUR_STYLES)
feat(ui.chf_style):SetListIndex(1)
FeatureMgr.AddFeature(ui.chf_speed, "Chauffeur Speed", eFeatureType.SliderInt, "Cruising speed for waypoints."):SetLimitValues(10, 60):SetDefaultValue(35):Reset()
button(ui.esc_spawn, "Spawn Escorts", "Spawns vehicle escort units.", btn_spawn_escorts)
button(ui.esc_tp, "Teleport Escorts To Me", "Repositions entire convoy near player.", btn_tp_escorts)
button(ui.esc_heal, "Heal Escorts + Repair", "Fixes escort transport vehicles and crew.", btn_heal_escorts)
button(ui.esc_delete, "Delete All Escorts", "Deletes all escort transport vehicles and peds.", btn_delete_escorts)

-- defaults: guards AND escort crew are clones of you, Carbine + AP Pistol.
-- MODEL_CATS[1] is "Special" and its first entry is "Clone of You".
do
    local names = {}
    for _, it in ipairs(MODEL_CATS[1].list) do names[#names + 1] = it.n end
    for _, pair in ipairs({ { ui.model_cat, ui.model_preset }, { ui.esc_model_cat, ui.esc_model } }) do
        feat(pair[1]):SetListIndex(0)
        feat(pair[2]):SetList(names)
        feat(pair[2]):SetListIndex(0)
    end
end
feat(ui.pri_cat):SetListIndex(3)
do
    local names = {}
    for _, it in ipairs(WEAPON_CATS[4].list) do names[#names + 1] = it.n end
    feat(ui.primary):SetList(names)
    feat(ui.primary):SetListIndex(1) -- Carbine Rifle
end
feat(ui.sec_cat):SetListIndex(0)
do
    local names = {}
    for _, it in ipairs(WEAPON_CATS[1].list) do names[#names + 1] = it.n end
    feat(ui.secondary):SetList(names)
    feat(ui.secondary):SetListIndex(2) -- AP Pistol
end

-- ==== GUI Render Functions ====


------------------------------------------------------------------
-- Player list tab: assign your squad as someone else's bodyguards.
-- Purely protective - the squad guards whoever you pick and fights whoever
-- attacks them. There is deliberately no "attack this player" option here.
------------------------------------------------------

local function btn_protect_selected()
    local pid = Utils.GetSelectedPlayer()
    if pid == nil or pid < 0 then
        toast("No player selected.")
        return
    end
    if pid == GTA.GetLocalPlayerId() then
        squad.protect_id = nil
        toast("Squad is guarding you again.")
        return
    end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if ped == nil or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then
        toast("Can't reach that player right now.")
        return
    end
    squad.protect_id = pid
    squad.convoy_key = ""
    squad.follow_issued = {}
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
    end
    toast("Squad now guarding " .. (protect_name() or "that player") .. ".")
end

local function btn_protect_me()
    squad.protect_id = nil
    squad.convoy_key = ""
    squad.follow_issued = {}
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
    end
    toast("Squad is guarding you again.")
end

-- resolves the currently highlighted player to a ped, or 0
local function selected_ped()
    local pid = Utils.GetSelectedPlayer()
    if pid == nil or pid < 0 then return 0, nil end
    local ok, p = pcall(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX, pid)
    if ok and p and p ~= 0 and ENTITY.DOES_ENTITY_EXIST(p) then return p, pid end
    return 0, pid
end

local function btn_spawn_escorts_at_player()
    local ped = selected_ped()
    if ped == 0 then
        toast("Can't reach that player right now.")
        return
    end
    btn_spawn_escorts(ped)
end

local function btn_spawn_guards_at_player()
    local ped, pid = selected_ped()
    if ped == 0 then
        toast("Can't reach that player right now.")
        return
    end
    squad.protect_id = pid          -- guards spawn on them AND guard them
    squad.convoy_key = ""
    spawn_guards(feat(ui.spawn_count):GetIntValue(), false)
end

local function btn_tp_squad_to_player()
    local ped = selected_ped()
    if ped == 0 then
        toast("Can't reach that player right now.")
        return
    end
    for i, guard in ipairs(squad.guards) do
        if alive(guard.ped) then
            local pos = offset_from(ped, (i % 2 == 0) and 2.0 or -2.0, -1.5 - math.floor(i / 2))
            ENTITY.SET_ENTITY_COORDS(guard.ped, pos.x, pos.y, pos.z, false, false, false, false)
            TASK.CLEAR_PED_TASKS(guard.ped)
            squad.follow_issued[guard.ped] = nil
        end
    end
    for i, esc in ipairs(squad.escorts) do
        if alive(esc.veh) then
            local slot = i - 1
            local pos = offset_from(ped, (slot % 2 == 0) and 6.0 or -6.0,
                                    -10.0 - math.floor(slot / 2) * 9.0)
            local z = esc.isAir and (pos.z + 30.0 + slot * 12.0) or pos.z
            ENTITY.SET_ENTITY_COORDS(esc.veh, pos.x, pos.y, z, false, false, false, false)
        end
    end
    squad.convoy_key = ""
    toast("Squad moved to that player.")
end

-- shared by the "send X after them" buttons. groups says which part of the
-- force is committed; everyone else carries on with what they were doing.
local function send_after(groups, what)
    if not players_allowed() then
        toast("Set Engagement Policy to 'NPCs + Players' first.")
        return
    end
    local ped, pid = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    if pid == GTA.GetLocalPlayerId() then toast("That's you.") return end
    if pid == squad.protect_id then squad.protect_id = nil end

    if squad.hunt_id ~= pid then
        squad.hunt_groups = { guards = false, escorts = false, air = false }
    end
    squad.hunt_id = pid
    for k, v in pairs(groups) do squad.hunt_groups[k] = v or squad.hunt_groups[k] end

    squad.targets = {}
    squad.gunner_stage, squad.gunner_check, squad.gunner_locked = {}, {}, {}
    if groups.guards then
        for _, guard in ipairs(squad.guards) do
            if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
        end
    end
    toast(what .. " sent after that player.")
end

local function btn_hunt_guards()
    send_after({ guards = true }, "Bodyguards")
end

local function btn_hunt_escorts()
    send_after({ escorts = true }, "Escort crews")
end

local function btn_hunt_air()
    send_after({ air = true }, "Air support")
end

local function btn_hunt_selected()
    if not players_allowed() then
        toast("Set Engagement Policy to 'NPCs + Players' first.")
        return
    end
    local ped, pid = selected_ped()
    if ped == 0 then
        toast("Can't reach that player right now.")
        return
    end
    if pid == GTA.GetLocalPlayerId() then
        toast("That's you.")
        return
    end
    if pid == squad.protect_id then squad.protect_id = nil end
    squad.hunt_id = pid
    squad.hunt_groups = { guards = true, escorts = true, air = true }
    squad.targets = {}
    squad.gunner_stage, squad.gunner_check, squad.gunner_locked = {}, {}, {}
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
    end
    toast("Everything sent after that player.")
end

local function btn_hunt_clear()
    squad.hunt_id = nil
    squad.hunt_groups = { guards = false, escorts = false, air = false }
    squad.targets = {}
    squad.gunner_stage, squad.gunner_check, squad.gunner_locked = {}, {}, {}
    for _, guard in ipairs(squad.guards) do
        if alive(guard.ped) then TASK.CLEAR_PED_TASKS(guard.ped) end
    end
    toast("Squad stood down.")
end

local function btn_protect_heal()
    local ped = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    for_each_squad_ped(heal_ped)
    for _, esc in ipairs(squad.escorts) do
        if alive(esc.veh) then
            VEHICLE.SET_VEHICLE_FIXED(esc.veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(esc.veh, 1000.0)
        end
    end
    toast("Their detail is patched up.")
end

local function btn_protect_air_cover()
    local ped = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    squad.protect_id = select(2, selected_ped())
    btn_spawn_escorts(ped, "maverick", 2)
    toast("Air cover overhead.")
end

-- offense helpers (private-lobby stuff)
local function btn_hunt_ambush()
    if not players_allowed() then
        toast("Set Engagement Policy to 'NPCs + Players' first.")
        return
    end
    local ped, pid = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    if pid == GTA.GetLocalPlayerId() then toast("That's you.") return end
    -- drop a fresh detail right on top of them, already hostile
    local before = #squad.guards
    for i = 1, math.min(4, MAX_BODYGUARDS - before) do
        local pos = offset_from(ped, (i % 2 == 0) and 4.0 or -4.0, -4.0 - i)
        local g, name, is_animal = spawn_squad_ped(pos.x, pos.y, pos.z,
            ENTITY.GET_ENTITY_HEADING(ped), false, GUARD_SELECTOR)
        if g == 0 then break end
        local group = PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
        PED.SET_PED_AS_GROUP_MEMBER(g, group)
        PED.SET_PED_NEVER_LEAVES_GROUP(g, true)
        give_loadout(g, is_animal)
        squad.guards[#squad.guards + 1] =
            { ped = g, name = name, blip = add_blip(g, picked(ui.blip_color, BLIP_COLORS)[2]),
              isAnimal = is_animal }
        Script.Yield(40)
    end
    squad.hunt_id = pid
    squad.hunt_groups = { guards = true, escorts = false, air = false }
    squad.targets = {}
    toast("Ambush dropped on them.")
end

local function btn_hunt_surround()
    if not players_allowed() then
        toast("Set Engagement Policy to 'NPCs + Players' first.")
        return
    end
    local ped, pid = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    local n = #squad.guards
    if n == 0 then toast("No bodyguards to send.") return end
    -- ring them at even angles
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    for i, guard in ipairs(squad.guards) do
        if alive(guard.ped) then
            local a = (i / n) * math.pi * 2
            ENTITY.SET_ENTITY_COORDS(guard.ped,
                pos.x + math.cos(a) * 7.0, pos.y + math.sin(a) * 7.0, pos.z,
                false, false, false, false)
            TASK.CLEAR_PED_TASKS(guard.ped)
            squad.follow_issued[guard.ped] = nil
        end
    end
    squad.hunt_id = pid
    squad.hunt_groups = { guards = true, escorts = false, air = false }
    squad.targets = {}
    toast("Squad has them surrounded.")
end

local function btn_hunt_air_strike()
    if not players_allowed() then
        toast("Set Engagement Policy to 'NPCs + Players' first.")
        return
    end
    local ped, pid = selected_ped()
    if ped == 0 then toast("Can't reach that player right now.") return end
    if pid == GTA.GetLocalPlayerId() then toast("That's you.") return end
    btn_spawn_escorts(ped, "buzzard", 2)
    squad.hunt_id = pid
    squad.hunt_groups = { guards = false, escorts = false, air = true }
    squad.targets = {}
    toast("Gunship inbound on them.")
end

button(ui.protect_sel, "Guard This Player",
    "Your bodyguards and convoy follow and defend the selected player.", btn_protect_selected)
button(ui.protect_me, "Guard Me Again",
    "Bring the squad back to protecting you.", btn_protect_me)
button(ui.protect_guards, "Spawn Bodyguards On Them",
    "Spawns guards at that player and assigns them as their detail.", btn_spawn_guards_at_player)
button(ui.protect_spawn, "Spawn Escorts On Them",
    "Spawns an escort convoy at that player's position.", btn_spawn_escorts_at_player)
button(ui.protect_tp, "Move Squad To Them",
    "Teleports your whole squad and convoy to that player.", btn_tp_squad_to_player)
button(ui.protect_heal, "Patch Up Their Detail",
    "Heals the squad and repairs the convoy protecting them.", btn_protect_heal)
button(ui.protect_air, "Air Cover For Them",
    "Puts two crewed helicopters over that player.", btn_protect_air_cover)
button(ui.hunt_bg, "Send Bodyguards",
    "Only your bodyguards go after this player. Escorts and aircraft keep doing their job.", btn_hunt_guards)
button(ui.hunt_esc, "Send Escort Crews",
    "Only the vehicle crews engage this player.", btn_hunt_escorts)
button(ui.hunt_airsend, "Send Air Support",
    "Only helicopters and planes go after this player.", btn_hunt_air)
button(ui.hunt_sel, "Send Everything",
    "Commits the whole force, guards, crews and aircraft.", btn_hunt_selected)
button(ui.hunt_ambush, "Ambush Them",
    "Drops a fresh detail right on top of them, already hostile.", btn_hunt_ambush)
button(ui.hunt_surround, "Surround Them",
    "Rings your existing guards around them and engages.", btn_hunt_surround)
button(ui.hunt_air, "Air Strike On Them",
    "Sends two armed gunships after that player.", btn_hunt_air_strike)
button(ui.hunt_clear, "Stand Down",
    "Clears the assigned player target.", btn_hunt_clear)


----------------------------------------------------------------------
-- menu / interface bits
--
-- One panel per tab. The tabs do the sorting, so there's nothing to expand
-- or collapse just to reach a couple of options.
------------------------------------------------

local MUTED = { 0.55, 0.60, 0.68 }
local CALM  = { 0.62, 0.78, 0.86 }
local ALERT = { 0.90, 0.58, 0.52 }

local function soft(c, s)
    ImGui.TextColored(c[1], c[2], c[3], 1.0, s)
end

-- Tells you, before you spawn anything, whether the model you picked will
-- actually reach your friends' machines past Cherax Spam Protection.
-- tells you BEFORE you spawn 7 of something nobody else can see
local function sync_warning(cat_id, item_id)
    local cat   = MODEL_CATS[feat(cat_id):GetListIndex() + 1]
    local entry = cat and cat.list[feat(item_id):GetListIndex() + 1]
    if not entry or not model_needs_sub(entry.m) then return end
    if feat(ui.friend_safe):IsToggled() then
        soft(MUTED, ("Spam Protection: spawning %s instead so friends can see them.")
            :format(FRIEND_SAFE_SUBS[entry.m]))
    else
        soft(ALERT, "Spam Protection hides this model from other players.")
    end
end

local function render_all(ids)
    for _, id in ipairs(ids) do ClickGUI.RenderFeature(id) end
end

-- a quiet divider with a label, used to break a panel into readable runs
-- without turning each run into its own collapsible box
local function rule(label)
    ImGui.Dummy(1, 5)
    soft(MUTED, label)
    ImGui.Separator()
end

local function status_line(parts)
    soft(MUTED, table.concat(parts, "    "))
    -- if any subsystem is erroring, say so plainly instead of leaving you to
    -- guess why the squad has gone inert
    local faults = {}
    for name, n in pairs(squad.fault) do
        faults[#faults + 1] = ("%s x%d"):format(name, n)
    end
    if #faults > 0 then
        soft(ALERT, "Faults: " .. table.concat(faults, ", ") .. "  (see Cherax log)")
    end
    ImGui.Separator()
    ImGui.Dummy(1, 3)
end

-- one tab, one panel
local function tab(label, title, build)
    if ImGui.BeginTabItem(label) then
        if ClickGUI.BeginCustomChildWindow(title) then
            build()
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTabItem()
    end
end

------------------------------------------------------------
-- bodyguard tab

local function render_bodyguard_tab()
    local guarding = protect_name()
    status_line({
        ("Squad %d/%d"):format(#squad.guard_info, MAX_BODYGUARDS),
        ("Crew %d"):format(squad.escorts_alive),
        ("Threats %d"):format(squad.threat_count),
        ("Guarding %s"):format(guarding or "you"),
    })

    if ImGui.BeginTabBar("bgs_tabs") then

        tab("Squad", "Squad", function()
            render_all({ ui.model_cat, ui.model_preset, ui.guard_model,
                         ui.random_outfit, ui.friend_safe })
            sync_warning(ui.model_cat, ui.model_preset)
            rule("Deploy")
            render_all({ ui.spawn_count, ui.spawn_guard, ui.spawn_clone })
            rule("Orders")
            render_all({ ui.rally, ui.tp_all, ui.heal_all, ui.warp_in_veh,
                         ui.steal_cars, ui.dismiss_all, ui.del_guards })
        end)

        tab("Weapons", "Loadout", function()
            render_all({ ui.pri_cat, ui.primary, ui.give_primary })
            rule("Sidearm - used inside vehicles")
            render_all({ ui.sec_cat, ui.secondary, ui.give_secondary })
            rule("Ammunition")
            render_all({ ui.exp_rounds, ui.exp_type })
            ImGui.Dummy(1, 4)
            render_all({ ui.apply_loadout })
        end)

        tab("Survival", "Survival", function()
            render_all({ ui.killable, ui.god, ui.no_ragdoll, ui.invisible, ui.local_visible })
            rule("Recovery")
            render_all({ ui.auto_heal, ui.auto_respawn, ui.auto_revive, ui.revive_delay })
            rule("Stats")
            render_all({ ui.health, ui.armor, ui.accuracy })
        end)

        tab("Behaviour", "Behaviour", function()
            render_all({ ui.allow_players, ui.behaviour, ui.engage_range, ui.pursuit })
            rule("Formation")
            render_all({ ui.formation, ui.spacing, ui.auto_tp, ui.tp_distance })
            rule("Display")
            render_all({ ui.blip_color, ui.callouts, ui.esp_name, ui.esp_health,
                         ui.esp_distance, ui.esp_tracer })
        end)


        if ImGui.BeginTabItem("Roster") then
            if ClickGUI.BeginCustomChildWindow("Active Squad") then
                if #squad.guard_info == 0 then
                    soft(MUTED, "No bodyguards deployed.")
                end
                for i, info in ipairs(squad.guard_info) do
                    ImGui.PushID(i)
                    local frac = 0.0
                    if info.maxhp and info.maxhp > 0 then
                        frac = math.max(0.0, math.min(1.0, info.hp / info.maxhp))
                    end
                    if info.downed then
                        soft(ALERT, ("%d. %s. Down"):format(i, info.name))
                    else
                        soft(CALM, ("%d. %s"):format(i, info.name))
                        ImGui.SameLine()
                        soft(MUTED, ("%dm"):format(info.dist))
                        ImGui.ProgressBar(frac, 150.0, 8.0,
                            ("%d / %d"):format(info.hp, info.maxhp))
                    end
                    if ImGui.SmallButton("Recall") then
                        local ped = info.ped
                        Script.QueueJob(function() tp_one_guard(ped) end)
                    end
                    ImGui.SameLine()
                    if ImGui.SmallButton("Heal") then
                        local ped = info.ped
                        Script.QueueJob(function() if alive(ped) then heal_ped(ped) end end)
                    end
                    ImGui.SameLine()
                    if ImGui.SmallButton("Remove") then
                        local ped = info.ped
                        Script.QueueJob(function() remove_one_guard(ped) end)
                    end
                    ImGui.Dummy(1, 4)
                    ImGui.PopID()
                end
                ClickGUI.EndCustomChildWindow()
            end
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
end

-- convoy tab
-------------

local function render_escort_tab()
    status_line({
        ("Vehicles %d"):format(#squad.escorts),
        ("Crew %d"):format(squad.escorts_alive),
        ("Threats %d"):format(squad.threat_count),
        ("Mode %s"):format(picked(ui.esc_mode, ESCORT_MODES)[1]),
    })

    if ImGui.BeginTabBar("esc_tabs") then

        tab("Convoy", "Convoy", function()
            render_all({ ui.esc_veh_cat, ui.esc_veh_model, ui.esc_veh_text })
            rule("Crew")
            render_all({ ui.esc_model_cat, ui.esc_model, ui.esc_model_txt })
            sync_warning(ui.esc_model_cat, ui.esc_model)
            rule("Deploy")
            render_all({ ui.esc_count, ui.esc_fill, ui.esc_spawn })
            rule("Orders")
            render_all({ ui.esc_tp, ui.esc_heal, ui.esc_delete })
        end)

        tab("Driving", "Driving", function()
            render_all({ ui.convoy_style, ui.esc_distance, ui.esc_style })
            rule("Combat")
            render_all({ ui.esc_mode, ui.esc_range })
            rule("Recovery")
            render_all({ ui.auto_flip, ui.auto_promote, ui.jackable, ui.esc_despawn })
        end)

        tab("Vehicles", "Vehicles", function()
            render_all({ ui.esc_tune, ui.esc_upgrade, ui.esc_strong, ui.esc_god_veh })
            rule("Appearance")
            render_all({ ui.esc_color, ui.blackout, ui.sirens, ui.searchlight })
        end)

        tab("Air & Rides", "Air & Rides", function()
            render_all({ ui.air_alt, ui.heli_land })
            rule("Chauffeur - ride along and set a waypoint")
            render_all({ ui.chf_style, ui.chf_speed })
        end)

        -- Read this when the convoy misbehaves instead of guessing. Each row
        -- walks the chain an order has to survive: do we own the vehicle, do
        -- we own the driver, is he in his seat, is the thing moving, do we own
        -- the gunners, are they in combat, are they actually firing. The first
        -- "no" is the fault.
        tab("Diagnostics", "Diagnostics", function()
            local d = squad.diag
            if d == nil then
                soft(MUTED, "No data yet.")
                return
            end
            soft(MUTED, ("Session %s    Control ok %d / lost %d    Threats %d")
                :format(d.session and "online" or "story", d.owned, d.lost, d.threats))
            if d.lost > 0 and d.owned == 0 then
                soft(ALERT, "Never gained network control, orders are being discarded.")
            end

            -- the pvp chain, in the order it has to succeed
            if not d.pvp then
                soft(ALERT, "Engagement Policy is NPCs Only.")
                soft(MUTED, "Squad is bonded COMPANION to the player group and")
                soft(MUTED, "will not shoot a player whatever you order. Switch it")
                soft(MUTED, "on under Bodyguards > Behaviour, or Detail > Offense.")
            else
                soft(CALM, ("Players: %d in range, %d hostile%s")
                    :format(d.p_seen, d.p_hot,
                            d.hunt and ("   hunting #" .. tostring(d.hunt)) or ""))
                if d.p_seen == 0 then
                    soft(ALERT, "No other players visible to the script at all.")
                elseif d.p_hot == 0 then
                    soft(MUTED, "Nobody has shot at you yet, so nobody is a target.")
                    soft(MUTED, "Shoot one, get shot, or use Detail > Offense > Send.")
                end
            end
            ImGui.Separator()
            if #d.rows == 0 then
                soft(MUTED, "No convoy deployed.")
                return
            end
            -- control reads back as nil when the native itself failed, which
            -- is a different thing from "someone else owns it"
            local function own(v)
                if v == nil then return "unknown" end
                return v and "owned" or "NOT OWNED"
            end
            for _, r in ipairs(d.rows) do
                local kind = r.plane and "plane" or (r.air and "heli" or "car")
                soft(CALM, ("#%d  %s  %dm"):format(r.idx, kind, r.dist or -1))
                local veh = ("veh: %s%s   %.1f m/s   eng %d")
                    :format(own(r.veh_ctrl),
                            r.veh_net and "" or " (local)",
                            r.speed or 0.0, r.veh_hp or 0)
                soft((r.veh_ctrl == false) and ALERT or MUTED, veh)
                if r.drv then
                    soft((r.drv_ctrl == false) and ALERT or MUTED,
                        ("drv: %s   %s   %d hp   last order %ds ago%s")
                        :format(own(r.drv_ctrl),
                                r.drv_seat and "seated" or "OUT OF SEAT",
                                r.drv_hp or 0, r.order_age or 0,
                                r.waiting and "   waiting on control" or ""))
                else
                    soft(ALERT, "drv: none")
                end
                soft((r.crew == r.crew_ctrl) and MUTED or ALERT,
                    ("crew: %d   owned %d   fighting %d   firing %d")
                    :format(r.crew, r.crew_ctrl, r.fighting, r.shooting))
                ImGui.Dummy(1, 4)
            end
        end)

        ImGui.EndTabBar()
    end
end

--------------------------------------------------------------
-- player list tab
------------------------------------------------------------------

local function render_player_tab()
    local who = protect_name()
    local target = ""
    if squad.hunt_id ~= nil then
        local ok, n = pcall(PLAYER.GET_PLAYER_NAME, squad.hunt_id)
        target = ("    Target %s"):format((ok and n) or tostring(squad.hunt_id))
    end
    status_line({
        ("Guarding %s"):format(who or "you"),
        ("Squad %d/%d"):format(#squad.guard_info, MAX_BODYGUARDS),
        ("Crew %d%s"):format(squad.escorts_alive, target),
    })

    if ImGui.BeginTabBar("bgs_ptabs") then

        tab("Protect", "Protect", function()
            render_all({ ui.protect_sel, ui.protect_me })
            rule("Deploy on them")
            render_all({ ui.protect_guards, ui.protect_spawn, ui.protect_air })
            rule("Support")
            render_all({ ui.protect_tp, ui.protect_heal })
        end)

        tab("Offense", "Offense", function()
            render_all({ ui.allow_players })
            rule("Send after them")
            render_all({ ui.hunt_bg, ui.hunt_esc, ui.hunt_airsend, ui.hunt_sel })
            rule("Manoeuvres")
            render_all({ ui.hunt_ambush, ui.hunt_surround, ui.hunt_air })
            rule("Recall")
            render_all({ ui.hunt_clear })
        end)

        ImGui.EndTabBar()
    end
end

ClickGUI.AddTab("Bodyguards", render_bodyguard_tab)
ClickGUI.AddTab("Convoy", render_escort_tab)
ClickGUI.AddPlayerTab("Detail", render_player_tab)

-- DO NOT DELETE THIS. every tick loop in here is gated on squad.ready and it
-- starts false so nothing runs while the file is still loading. this is what
-- switches them on. it went missing once in the gui rewrite and nothing ran
-- for weeks, and it looked for all the world like a netcode problem.
-- if the squad ever goes totally dead again, look here first.
squad.ready = true
toast("Bodyguard Squad loaded.")