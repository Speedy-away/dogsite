-- Bodyguard Script v4.0 — Cherax
--
-- v4.0 changelog:
--   FIXED: TASK_VEHICLE_SHOOT_AT_PED was called but never defined in N (in-vehicle
--          aim-assist driveby silently failed inside pcall since v3.x)
--   FIXED: guard numbering started at #0 (length read before table insert)
--   FIXED: ESP allocated/freed memory twice per guard per frame in ON_PRESENT
--   FIXED: player relationship hash cache invalidated every 100ms (now 5s refresh)
--   FIXED: blipPtr leaked on unload; raw TASK_COMBAT_PED hash routed through N
--   REMOVED: "Never Wanted" toggle (was decorative — state was never read)
--   NEW: animated loading screen (staged init readout + progress bar)
--   NEW: Advanced Tuning — accuracy / health / armor / formation spacing sliders,
--        blip color picker, outfit randomizer, Heal All
--   NEW: ground escorts escort your VEHICLE with convoy slots (Diamond/Rear/Lead),
--        pull up and hold when you're on foot, promote a passenger when the
--        driver dies, throttled re-tasking (no more 500ms task spam), spawn
--        behind your heading, Repair All button
--   NEW: status strip, live roster with HP/distance + per-guard TP/Heal/X,
--        escort status list; configs bumped to v4 (old .cfg files still load)
--   FIXED (field report): COMPANION bond now re-bonded every 5s against
--          your CURRENT rel-group hash - "bodyguards turn on me when I
--          shoot someone" was the old bond going stale on migration
--   NEW: two-tier weapon selector (primary + secondary category/type,
--        give toggles); secondary = the in-vehicle driveby weapon
--   NEW: Explosive Rounds - guard bullets detonate on impact (throttled,
--        5m player-safety bubble, guards blast-proof while enabled)
--   NEW: Spawn Clone of Me (CLONE_PED, full freemode appearance)
--   NEW: rainbow scaleform loading banner (BB Attackers style)
--   NEW: seat lock (turret gunners survive flips) + escort Auto-Flip

local SCRIPT_NAME = "Bodyguards"
local SCRIPT_VERSION = "4.0"
local joaat = Utils.Joaat

pcall(ClickGUI.RemoveTab, SCRIPT_NAME)
pcall(ClickGUI.RemovePlayerTab, SCRIPT_NAME)

-- ═══════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════

local MAX_BODYGUARDS = 7
local FIRING_FULL_AUTO = 0xC6EE6B4C

-- ═══════════════════════════════════════════════════════════════
-- NATIVE HASHES (identical on Enhanced & Legacy)
-- ═══════════════════════════════════════════════════════════════

local N = {
    -- Entity
    GET_ENTITY_COORDS               = 0x3FEF770D40960D5A,
    SET_ENTITY_COORDS               = 0x06843DA7060A026B,
    DOES_ENTITY_EXIST               = 0x7239B21A38F536BA,
    SET_ENTITY_AS_MISSION           = 0xAD738C3085FE7E11,
    DELETE_ENTITY                   = 0xAE3CBE5BF394C9C9,
    SET_ENTITY_INVINCIBLE           = 0x3882114BDE571AD4,
    SET_ENTITY_VISIBLE              = 0xEA1C610A04DB6BBB,
    SET_ENTITY_ALPHA                = 0x44A0870B7E92D7C0,
    SET_ENTITY_HEALTH               = 0x6B76DC1F3AE6E6A3,
    GET_ENTITY_HEALTH               = 0xEEF059FAD016D209,
    GET_ENTITY_MAX_HEALTH           = 0x15D757606D170C3C,
    SET_ENTITY_NO_COLLISION_ENTITY  = 0xA53ED5520C07654A,
    SET_ENTITY_PROOFS               = 0xFAEE099C6F890BB8,
    SET_ENTITY_HEADING              = 0x8E2530AA8ADA980E,
    GET_ENTITY_HEADING              = 0xE83D4F9BA2A38914,
    GET_ENTITY_FORWARD_VECTOR       = 0x0A794A5A57F8DF91,

    -- Model
    REQUEST_MODEL                   = 0x963D27A58DF860AC,
    HAS_MODEL_LOADED                = 0x98A4EB5D89A0C952,
    SET_MODEL_NO_LONGER             = 0xE532F5D78798DAAB,
    IS_MODEL_IN_CDIMAGE             = 0x35B9E0803292B641,

    -- Player
    PLAYER_PED_ID                   = 0xD80958FC74E988A6,
    PLAYER_ID                       = 0x4F8644AF03D0E0D6,
    GET_PLAYER_GROUP                = 0x0D127585F77030AF,
    GET_PLAYER_PED                  = 0x43A66C31C68491C0,

    -- Misc
    GET_GAME_TIMER                  = 0x9CD27B0045628463,
    GET_GROUND_Z_FOR_3D_COORD       = 0xC906A7DAB05C8D2B,

    -- Ped
    SET_PED_AS_GROUP_MEMBER                 = 0x9F3480FE65DB31B5,
    SET_PED_NEVER_LEAVES_GROUP              = 0x3DBFC55D5C9BB447,
    SET_PED_RELATIONSHIP_GROUP_HASH         = 0xC80A74AC829DDD92,
    SET_RELATIONSHIP_BETWEEN_GROUPS         = 0xBF25EB89375A37AD,
    ADD_RELATIONSHIP_GROUP                  = 0xF372BC22FCB88606,
    GET_PED_RELATIONSHIP_GROUP_HASH         = 0x7DBDD04862D95F04,
    SET_PED_COMBAT_ATTRIBUTES               = 0x9F7794730795E019,
    SET_PED_COMBAT_ABILITY                  = 0xC7622C0D36B2FDA8,
    SET_PED_COMBAT_RANGE                    = 0x3C606747B23E497B,
    SET_PED_FIRING_PATTERN                  = 0x9AC577F5A12AD8A9,
    SET_PED_ACCURACY                        = 0x7AEFB85C1D49DEB6,
    SET_PED_ARMOUR                          = 0xCEA04D83135264CC,
    SET_PED_CONFIG_FLAG                     = 0x1913FE4CBF41C463,
    SET_PED_MAX_HEALTH                      = 0xF5F6378C4F3419D3,
    SET_PED_CAN_SWITCH_WEAPON               = 0xED7F7EFE9FABF340,
    SET_PED_RANDOM_COMPONENT_VARIATION      = 0xC8A9481A01E63C28,
    SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE      = 0x7A6535691B477C48,
    CLONE_PED                               = 0xEF29A16337FACADB,
    HAS_PED_GOT_WEAPON                      = 0x8DECB02F88F428BC,
    SET_PED_CAN_RAGDOLL                     = 0xB128377056A54E2A,
    SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP = 0xE22D8FDE858B8119,
    PLAY_PED_AMBIENT_SPEECH                 = 0x8E04FEDD28D42462,
    TASK_GO_TO_ENTITY                       = 0x6A071245EB0D1882,
    TASK_RAPPEL_FROM_HELI                   = 0x09693B0312F91649,
    GIVE_WEAPON_TO_PED                      = 0xBF0FD6E56C964FCB,
    REMOVE_ALL_PED_WEAPONS                  = 0xF25DF915FA38C5F3,
    REMOVE_WEAPON_FROM_PED                  = 0x4899CB088EDF59B8,
    SET_CURRENT_PED_WEAPON                  = 0xADF692B254977C0C,
    SET_PED_INFINITE_AMMO_CLIP              = 0x183DADC6AA953186,
    SET_PED_INFINITE_AMMO                   = 0x3EDCB0505123623B,
    SET_PED_AMMO                            = 0x14E56BC5B5DB6A19,
    GET_AMMO_IN_PED_WEAPON                  = 0x015A522136D7F951,
    GET_SELECTED_PED_WEAPON                 = 0x0A6DB4965674D243,
    SET_PED_KEEP_TASK                       = 0x971D38760FBC02EF,
    IS_PED_DEAD_OR_DYING                    = 0x3317DEDB88C95038,
    IS_PED_SHOOTING                         = 0x34616828CD07F1A1,
    GET_PED_LAST_WEAPON_IMPACT              = 0x6C4D0409BA1A2BC2,
    CLEAR_PED_TASKS                         = 0xE1EF3C1216AFF2CD,
    CLEAR_PED_TASKS_IMMEDIATELY             = 0xAAA34F8A7CB32098,
    RESURRECT_PED                           = 0x71BC8E838B9C6035,
    TASK_COMBAT_HATED_TARGETS               = 0x7BF835BB9E2698C8,
    TASK_COMBAT_PED                         = 0xF166E48407BAC484,
    TASK_SHOOT_AT_ENTITY                    = 0x08DA95E8298AE772,
    TASK_VEHICLE_SHOOT_AT_PED               = 0x10AB107B887214D8,
    REGISTER_TARGET                         = 0x2F25D9AEFA34FBA2,
    REGISTER_HATED_TARGETS_AROUND_PED       = 0x9222F300BF8354FE,
    IS_PED_IN_COMBAT                        = 0x4859F1FC66A6278E,
    GET_ENTITY_PLAYER_IS_FREE_AIMING_AT     = 0x2975C866E6713290,
    IS_PLAYER_FREE_AIMING                   = 0x2E397FD2ECD37C87,
    SET_CAN_ATTACK_FRIENDLY                 = 0xB3B1CB349FF9C75D,
    SET_PED_CAN_BE_TARGETTED                = 0x63F58F7C80513AAD,
    SET_PED_CAN_BE_TARGETTED_BY_PLAYER      = 0x66B57B72E0836A76,
    SET_PED_CAN_BE_TARGETTED_BY_TEAM        = 0xBF1CA77833E58F2C,
    SET_BLOCKING_OF_NON_TEMPORARY_EVENTS    = 0x9F8AA94D6D97DBF4,
    SET_PED_DIES_WHEN_INJURED               = 0x5BA7919BED300023,
    SET_PED_SUFFERS_CRITICAL_HITS           = 0xEBD76F2359F190AC,
    IS_PED_IN_ANY_VEHICLE                   = 0x997ABD671D25CA0B,

    -- Vehicle entry/exit
    GET_VEHICLE_PED_IS_IN                   = 0x9A9112A0FE9A4713,
    TASK_ENTER_VEHICLE                      = 0xC20E50AA46D09CA8,
    GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS    = 0xA7C4F2C6E744A550,
    IS_VEHICLE_SEAT_FREE                    = 0x22AC59A870E6A669,
    SET_PED_INTO_VEHICLE                    = 0xF75B0D629E1C063D,
    TASK_LEAVE_VEHICLE                      = 0xD3DBCE61A490BE02,

    -- Animal
    SET_ANIMAL_MOOD                         = 0xCC97B29285B1DC3B,
    SET_PED_COMBAT_MOVEMENT                 = 0x4D9CA1009AFBD057,

    -- Escort system
    TASK_VEHICLE_ESCORT                     = 0x0FA6E4B75F302400,
    TASK_VEHICLE_HELI_PROTECT               = 0x1E09C32048FEFD1C,
    TASK_HELI_MISSION                       = 0xDAD029E187A2BEB4,
    TASK_VEHICLE_TEMP_ACTION                = 0xC429DCEEB339E129,
    SET_DRIVER_ABILITY                      = 0xB195FFA8042FC5C3,
    SET_DRIVER_AGGRESSIVENESS               = 0xA731F608CA104E3C,
    SET_VEHICLE_ENGINE_ON                   = 0x2497C4717C8B881E,
    SET_VEHICLE_WINDOW_TINT                 = 0x57C51E6BAD752696,
    SET_HELI_BLADES_FULL_SPEED              = 0xA178472EBB8AE60D,
    SET_VEHICLE_MOD_KIT                     = 0x1F2AA07F00B3217A,
    SET_VEHICLE_STRONG                      = 0x3E8C8727991A8A0B,
    SET_VEHICLE_FIXED                       = 0x115722B1B9C14C1C,
    IS_VEHICLE_STUCK_ON_ROOF                = 0xB497F06B288DCFDF,
    SET_VEHICLE_ON_GROUND_PROPERLY          = 0x49733E92263139D1,
    SET_VEHICLE_SEARCHLIGHT                 = 0x14E85C5EE7A4D542,
    CREATE_OBJECT                           = 0x509D5878EB39E842,
    ATTACH_ENTITY_TO_ENTITY                 = 0x6B9BBD38AB0796DF,

    -- Group
    SET_GROUP_FORMATION                     = 0xCE2F5FC3AF7E8C1E,
    SET_GROUP_FORMATION_SPACING             = 0x1D9D45004C28C916,

    -- Blip
    ADD_BLIP_FOR_ENTITY                     = 0x5CDE92C702A8FCE7,
    SET_BLIP_COLOUR                         = 0x03D7FB09E75D6B7E,
    SET_BLIP_SCALE                          = 0xD38744167B2FA257,
    REMOVE_BLIP                             = 0x86A652570E5F25DD,

    -- Drawing / ESP
    GET_SCREEN_FROM_WORLD                   = 0x34E82F05DF2974F5,
    GET_GAMEPLAY_CAM_COORD                  = 0x14D6F5678D8F1B37,

    -- Explosion
    ADD_EXPLOSION                           = 0xE3AD2BDBAEE269AC,
    ADD_OWNED_EXPLOSION                     = 0x172AA1B624FA1013,

    -- Cleanup helpers
    FREEZE_ENTITY                           = 0x428CA6DBD1094446,
    SET_PED_AS_NO_LONGER_NEEDED             = 0x2595DD4236549CE3,
}

-- ═══════════════════════════════════════════════════════════════
-- WEAPON DATABASE — categorized (v4.0 two-tier selector)
-- ═══════════════════════════════════════════════════════════════

local WEAPON_CATS = {
    {n = "Pistols", list = {
        {n = "Pistol",            h = 0x1B06D571},
        {n = "Combat Pistol",     h = 0x5EF9FEC4},
        {n = "AP Pistol",         h = 0x22D8FE39},
        {n = "Heavy Pistol",      h = 0xD205520E},
        {n = "Pistol .50",        h = 0x99AEEB3B},
        {n = "SNS Pistol",        h = 0xBFD21232},
        {n = "Heavy Revolver",    h = 0xC1B3C3D1},
    }},
    {n = "SMGs", list = {
        {n = "Micro SMG",         h = 0x13532244},
        {n = "SMG",               h = 0x2BE6766B},
        {n = "Assault SMG",       h = 0xEFE7E2DF},
        {n = "Combat PDW",        h = 0x0A3D4D34},
        {n = "Mini SMG",          h = 0xBD248B55},
    }},
    {n = "Shotguns", list = {
        {n = "Pump Shotgun",      h = 0x1D073A89},
        {n = "Assault Shotgun",   h = 0xE284C527},
        {n = "Combat Shotgun",    h = 0x5A96BA4},
        {n = "Heavy Shotgun",     h = 0x3AABBBAA},
    }},
    {n = "Assault Rifles", list = {
        {n = "Assault Rifle",     h = 0xBFEFFF6D},
        {n = "Carbine Rifle",     h = 0x83BF0278},
        {n = "Advanced Rifle",    h = 0xAF113F99},
        {n = "Special Carbine",   h = 0xC0A3098D},
        {n = "Bullpup Rifle",     h = 0x7F229F94},
        {n = "Military Rifle",    h = 0x9D1F17E6},
    }},
    {n = "LMGs", list = {
        {n = "MG",                h = 0x9D07F764},
        {n = "Combat MG",         h = 0x7FD62962},
        {n = "Gusenberg Sweeper", h = 0x61012683},
    }},
    {n = "Snipers", list = {
        {n = "Sniper Rifle",      h = 0x05FC3C11},
        {n = "Heavy Sniper",      h = 0x0C472FE2},
        {n = "Marksman Rifle",    h = 0xC734385A},
    }},
    {n = "Heavy", list = {
        {n = "RPG",               h = 0xB1CA77B1},
        {n = "Minigun",           h = 0x42BF8A85},
        {n = "Grenade Launcher",  h = 0xA284510B},
    }},
    {n = "Melee", list = {
        {n = "Knife",             h = 0x99B507EA},
        {n = "Bat",               h = 0x958A4A8F},
        {n = "Machete",           h = 0xDD5DF8D9},
        {n = "Battle Axe",        h = 0xCD274149},
    }},
}

local WCAT_NAMES, WNAMES = {}, {}
for ci, cat in ipairs(WEAPON_CATS) do
    WCAT_NAMES[#WCAT_NAMES + 1] = cat.n
    WNAMES[ci] = {}
    for _, w in ipairs(cat.list) do
        WNAMES[ci][#WNAMES[ci] + 1] = w.n
    end
end

-- Secondary selector only offers driveby-capable classes
local SEC_CAT_NAMES = {WEAPON_CATS[1].n, WEAPON_CATS[2].n}

-- Driveby-capable hashes (pistols + SMGs)
local DRIVEBY_OK = {}
for ci = 1, 2 do
    for _, w in ipairs(WEAPON_CATS[ci].list) do DRIVEBY_OK[w.h] = true end
end

-- Old flat weaponIdx (v3 configs) -> categorized position, for migration
local FLAT_MAP = {}
for ci, cat in ipairs(WEAPON_CATS) do
    for wi = 1, #cat.list do
        FLAT_MAP[#FLAT_MAP + 1] = {c = ci - 1, i = wi - 1}
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MODEL DATABASE
-- ═══════════════════════════════════════════════════════════════

local CATEGORIES = {
    "Animals", "Civilians", "Law Enforcement",
    "Military", "Gang Members", "Story Characters",
    "GTA Online"
}

local MODELS = {
    -- [1] Animals
    {
        {n = "Cat",            h = "a_c_cat_01"},
        {n = "Chimp",          h = "a_c_chimp_02"},
        {n = "Chop",           h = "a_c_chop"},
        {n = "Boar",           h = "a_c_boar"},
        {n = "Cow",            h = "a_c_cow"},
        {n = "Coyote",         h = "a_c_coyote"},
        {n = "Crow",           h = "a_c_crow"},
        {n = "Deer",           h = "a_c_deer"},
        {n = "Hen",            h = "a_c_hen"},
        {n = "Husky",          h = "a_c_husky"},
        {n = "Mountain Lion",  h = "a_c_mtlion"},
        {n = "Pig",            h = "a_c_pig"},
        {n = "Pigeon",         h = "a_c_pigeon"},
        {n = "Poodle",         h = "a_c_poodle"},
        {n = "Pug",            h = "a_c_pug"},
        {n = "Rabbit",         h = "a_c_rabbit_01"},
        {n = "Rat",            h = "a_c_rat"},
        {n = "Retriever",      h = "a_c_retriever"},
        {n = "Rottweiler",     h = "a_c_rottweiler"},
        {n = "Shepherd",       h = "a_c_shepherd"},
        {n = "Westie",         h = "a_c_westy"},
    },
    -- [2] Civilians
    {
        {n = "Business Man",    h = "a_m_y_business_01"},
        {n = "Business Woman",  h = "a_f_y_business_01"},
        {n = "Beach Bro",       h = "a_m_y_beach_01"},
        {n = "Beach Girl",      h = "a_f_y_beach_01"},
        {n = "Hipster",         h = "a_m_y_hipster_01"},
        {n = "Hipster Girl",    h = "a_f_y_hipster_01"},
        {n = "Fitness Girl",    h = "a_f_y_fitness_01"},
        {n = "Skater",          h = "a_m_y_skater_01"},
        {n = "Runner",          h = "a_m_y_runner_01"},
        {n = "Muscle Beach",    h = "a_m_y_musclbeac_01"},
        {n = "Tourist",         h = "a_m_m_tourist_01"},
        {n = "Construction",    h = "s_m_y_construct_01"},
        {n = "Farmer",          h = "a_m_m_farmer_01"},
        {n = "Bouncer",         h = "s_m_m_bouncer_01"},
    },
    -- [3] Law Enforcement
    {
        {n = "LSPD Male",       h = "s_m_y_cop_01"},
        {n = "LSPD Female",     h = "s_f_y_cop_01"},
        {n = "Sheriff",         h = "s_m_y_sheriff_01"},
        {n = "Highway Patrol",  h = "s_m_y_hwaycop_01"},
        {n = "NOOSE/SWAT",      h = "s_m_y_swat_01"},
        {n = "Ranger",          h = "s_m_y_ranger_01"},
        {n = "Prison Guard",    h = "s_m_y_prisguard_01"},
        {n = "Security",        h = "s_m_m_security_01"},
        {n = "FIB Agent",       h = "s_m_m_fiboffice_01"},
        {n = "FIB Agent 2",     h = "s_m_m_fiboffice_02"},
    },
    -- [4] Military
    {
        {n = "Marine 1",        h = "s_m_y_marine_01"},
        {n = "Marine 2",        h = "s_m_y_marine_02"},
        {n = "Marine 3",        h = "s_m_y_marine_03"},
        {n = "Marine Officer",  h = "s_m_m_marine_01"},
        {n = "Army Mechanic",   h = "s_m_y_armymech_01"},
        {n = "Pilot",           h = "s_m_y_pilot_01"},
        {n = "Blackops 1",      h = "s_m_y_blackops_01"},
        {n = "Blackops 2",      h = "s_m_y_blackops_02"},
        {n = "Blackops 3",      h = "s_m_y_blackops_03"},
    },
    -- [5] Gang Members
    {
        {n = "Ballas",          h = "g_m_y_ballasout_01"},
        {n = "Ballas Girl",     h = "g_f_y_ballas_01"},
        {n = "Families",        h = "g_m_y_famfor_01"},
        {n = "Families DNF",    h = "g_m_y_famdnf_01"},
        {n = "Lost MC 1",       h = "g_m_y_lost_01"},
        {n = "Lost MC 2",       h = "g_m_y_lost_02"},
        {n = "Lost MC 3",       h = "g_m_y_lost_03"},
        {n = "Vagos",           h = "g_m_y_mexgang_01"},
        {n = "Korean",          h = "g_m_y_korean_01"},
        {n = "Marabunta",       h = "g_m_y_salvaboss_01"},
    },
    -- [6] Story Characters
    {
        {n = "Michael",         h = "player_zero"},
        {n = "Franklin",        h = "player_one"},
        {n = "Trevor",          h = "player_two"},
        {n = "Lamar",           h = "ig_lamardavis"},
        {n = "Jimmy",           h = "ig_jimmydisanto"},
        {n = "Amanda",          h = "ig_amanda"},
        {n = "Wade",            h = "ig_wade"},
        {n = "Ron",             h = "ig_ron"},
        {n = "Lester",          h = "ig_lestercrest"},
    },
    -- [7] GTA Online (freemode — components randomize properly)
    {
        {n = "Online Male",     h = "mp_m_freemode_01"},
        {n = "Online Female",   h = "mp_f_freemode_01"},
    },
}

-- Pre-build name lists for Combo dropdowns
local MODEL_NAMES = {}
for catIdx, cat in ipairs(MODELS) do
    MODEL_NAMES[catIdx] = {}
    for _, m in ipairs(cat) do
        MODEL_NAMES[catIdx][#MODEL_NAMES[catIdx] + 1] = m.n
    end
end

local CATEGORY_NAMES = {}
for _, c in ipairs(CATEGORIES) do
    CATEGORY_NAMES[#CATEGORY_NAMES + 1] = c
end

-- ═══════════════════════════════════════════════════════════════
-- FORMATION / BEHAVIOUR / COSMETICS / CONVOY
-- ═══════════════════════════════════════════════════════════════

local FORMATIONS = {
    {n = "Default",      v = 0},
    {n = "Circle",       v = 1},
    {n = "Line Abreast", v = 3},
    {n = "Arrow",        v = 4},
}
local FORMATION_NAMES = {}
for _, f in ipairs(FORMATIONS) do FORMATION_NAMES[#FORMATION_NAMES + 1] = f.n end

local BEHAVIOURS = {
    {n = "Defensive",  range = 30.0},
    {n = "Offensive",  range = 200.0},
    {n = "Passive",    range = 0},
}
local BEHAVIOUR_NAMES = {}
for _, b in ipairs(BEHAVIOURS) do BEHAVIOUR_NAMES[#BEHAVIOUR_NAMES + 1] = b.n end

local BLIP_COLORS = {
    {n = "Default", v = 57},
    {n = "Red",     v = 1},
    {n = "Green",   v = 2},
    {n = "Blue",    v = 3},
    {n = "White",   v = 4},
    {n = "Yellow",  v = 5},
    {n = "Orange",  v = 17},
    {n = "Purple",  v = 27},
}
local BLIP_COLOR_NAMES = {}
for _, b in ipairs(BLIP_COLORS) do BLIP_COLOR_NAMES[#BLIP_COLOR_NAMES + 1] = b.n end

-- Explosion tags for Explosive Rounds (eExplosionTag not bound; raw ints)
local EXPLOSION_TYPES = {
    {n = "Grenade",  v = 0},
    {n = "Molotov",  v = 3},
    {n = "Rocket",   v = 4},
    {n = "Firework", v = 35},
}
local EXPLOSION_TYPE_NAMES = {}
for _, e in ipairs(EXPLOSION_TYPES) do EXPLOSION_TYPE_NAMES[#EXPLOSION_TYPE_NAMES + 1] = e.n end

-- Weapons that already explode on impact — no double-boom
local EXP_WEAPON_SKIP = {
    [0xB1CA77B1] = true,  -- RPG
    [0xA284510B] = true,  -- Grenade Launcher
}

-- Convoy positioning styles (TASK_VEHICLE_ESCORT mode per slot:
-- -1 = closest/auto, 0 = rear, 1 = lead, 2 = left flank, 3 = right flank)
local CONVOY_STYLES = {
    {n = "Auto (closest)"},
    {n = "Diamond (lead/rear/flank)", modes = {1, 0, 2}},
    {n = "Rear Guard",                modes = {0, 0, 0}},
    {n = "Lead Convoy",               modes = {1, 1, 1}},
}
local CONVOY_STYLE_NAMES = {}
for _, s in ipairs(CONVOY_STYLES) do CONVOY_STYLE_NAMES[#CONVOY_STYLE_NAMES + 1] = s.n end

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════

local bodyguards = {}   -- { {handle, model, name, blip, isAnimal, enteringVeh} }
local escorts = {}      -- { {veh, driver, passengers={}, blip, type, slot, nextTask, stopped, lastTarget} }
local isShuttingDown = false
local bgGroupHash = nil
local playerRelHash = nil
local lastPlayerVeh = 0
local lastRelRefresh = 0
local sicTarget = nil       -- ped handle guards are sicced on (player tab)
local attackers = {}        -- attack-squad peds (player tab)
local medicDuty = {}        -- guards currently on a rescue run (skip combat re-task)
local shadowGuards = {}     -- rappelled troops converted to unlisted bodyguards

local state = {
    pedCount      = 1,
    catIdx        = 0,    -- 0-indexed for Combo
    modelIdx      = 0,
    priCatIdx     = 3,    -- Assault Rifles
    priIdx        = 1,    -- Carbine Rifle
    secCatIdx     = 0,    -- Pistols
    secIdx        = 2,    -- AP Pistol
    givePrimary   = true,
    giveSecondary = true,
    formIdx       = 0,
    behavIdx      = 0,
    godMode       = false,
    noRagdoll     = false,
    invisible     = false,
    localVisible  = false,
    autoTeleport  = false,
    espName       = false,
    espHealth     = false,
    espDistance   = false,
    espTracer     = false,
    customModel   = "",
    configName    = "",
    -- v4.0 Advanced Tuning
    accuracy      = 100,
    health        = 2000,
    armor         = 300,
    spacing       = 2,
    blipColorIdx  = 0,
    randomOutfit  = false,
    autoRevive    = false,
    reviveDelay   = 8,
    medicRush     = false,
    callouts      = false,
    explosiveBullets = false,
    expTypeIdx    = 0,
}

-- Forward-declared so the config system can serialize convoy style
local escortState = {
    groundVehIdx = 0,
    airVehIdx    = 0,
    groundCount  = 1,
    airCount     = 1,
    godMode      = false,
    styleIdx     = 0,
    autoFlip     = false,
    airAlt       = 40,
    searchlight  = false,
}

local feat = {}

-- Weapons where FULL_AUTO firing pattern breaks AI (single-shot / melee)
local NO_FULL_AUTO = {
    [0xB1CA77B1] = true,  -- RPG
    [0x42BF8A85] = true,  -- Minigun
    [0xA284510B] = true,  -- Grenade Launcher
    [0x05FC3C11] = true,  -- Sniper Rifle
    [0x0C472FE2] = true,  -- Heavy Sniper
    [0xC734385A] = true,  -- Marksman Rifle
    [0x99B507EA] = true,  -- Knife
    [0x958A4A8F] = true,  -- Bat
    [0xDD5DF8D9] = true,  -- Machete
    [0xCD274149] = true,  -- Battle Axe
}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local function toast(msg)
    pcall(GUI.AddToast, SCRIPT_NAME, tostring(msg), 2500, eToastPos.TopRight)
end

local function log(msg)
    print("[" .. SCRIPT_NAME .. "] " .. tostring(msg))
end

local function entityExists(e)
    if not e or e == 0 then return false end
    local ok, r = pcall(Natives.InvokeBool, N.DOES_ENTITY_EXIST, e)
    return ok and r
end

local function requestModel(hash)
    Natives.InvokeVoid(N.REQUEST_MODEL, hash)
    for i = 1, 100 do
        if Natives.InvokeBool(N.HAS_MODEL_LOADED, hash) then return true end
        Script.Yield(10)
    end
    return false
end

-- Game timer in ms (safe: returns 0 if the native binding fails)
local function nowMs()
    local ok, t = pcall(Natives.InvokeInt, N.GET_GAME_TIMER)
    if ok and t then return t end
    return 0
end

-- Pre-allocated memory pointers (reuse instead of alloc/free per call)
local aimEntPtr = Memory.AllocInt()
local deletePtr = Memory.AllocInt()   -- reusable for DELETE_ENTITY
local blipPtr   = Memory.AllocInt()   -- reusable for REMOVE_BLIP
local espXPtr   = Memory.Alloc(4)     -- reusable for GET_SCREEN_FROM_WORLD
local espYPtr   = Memory.Alloc(4)

-- ImGui capability check (per-row roster buttons degrade to text-only
-- if this Cherax build doesn't bind Button/SameLine)
local HAS_BTN, HAS_SAMELINE = false, false
pcall(function()
    HAS_BTN = type(ImGui.Button) == "function"
    HAS_SAMELINE = type(ImGui.SameLine) == "function"
end)

local function removeBlipSafe(blip)
    if not blip or blip == 0 then return end
    pcall(function()
        Memory.WriteInt(blipPtr, blip)
        Natives.InvokeVoid(N.REMOVE_BLIP, blipPtr)
    end)
end

local function deleteEntity(e)
    if not entityExists(e) then return end
    pcall(Memory.WriteInt, deletePtr, e)
    pcall(Natives.InvokeVoid, N.SET_ENTITY_AS_MISSION, e, true, true)
    pcall(Natives.InvokeVoid, N.DELETE_ENTITY, deletePtr)
end

local function myPed()
    return Natives.InvokeInt(N.PLAYER_PED_ID)
end

local function myId()
    return Natives.InvokeInt(N.PLAYER_ID)
end

local function myCoords()
    return Natives.InvokeV3(N.GET_ENTITY_COORDS, myPed(), true)
end

-- Player's forward XY direction (unit-ish); falls back to north
local function playerForward()
    local fx, fy = 0.0, 1.0
    pcall(function()
        local x, y, z = Natives.InvokeV3(N.GET_ENTITY_FORWARD_VECTOR, myPed())
        if x then fx, fy = x, y end
    end)
    return fx, fy
end

-- Currently selected primary / secondary weapon entries (v4.0)
local function primaryWeapon()
    local cat = WEAPON_CATS[state.priCatIdx + 1]
    return cat and cat.list[state.priIdx + 1] or nil
end

local function secondaryWeapon()
    local cat = WEAPON_CATS[state.secCatIdx + 1]   -- selector only lists cats 1-2
    return cat and cat.list[state.secIdx + 1] or nil
end

-- Reusable 24-byte out-buffer for GET_PED_LAST_WEAPON_IMPACT
-- (vector floats at +0/+8/+16; Memory.Alloc returns a plain int address)
local impactPtr = Memory.Alloc(24)

-- Get player's ACTUAL relationship group hash (dynamic, works in Online)
local function getPlayerRelHash()
    if playerRelHash then return playerRelHash end
    -- Cherax's GET_PED_RELATIONSHIP_GROUP_HASH returns Int directly (not via pointer)
    local ok, hash = pcall(Natives.InvokeInt, N.GET_PED_RELATIONSHIP_GROUP_HASH, myPed())
    if ok and hash and hash ~= 0 then
        playerRelHash = hash
    else
        playerRelHash = joaat("PLAYER")
    end
    return playerRelHash
end

-- ═══════════════════════════════════════════════════════════════
-- LOADING BANNER — verbatim port of the BB Attackers v9 scaleform
-- intro (K-Script pattern), lines 5354-5391 of the source. Title
-- swapped to BODYGUARDS. The pieces my reconstruction was missing:
-- the 4th ADD_PARAM_BOOL, END_..._RETURN_VALUE to close the method,
-- per-frame scaleform re-request, and fullscreen draw with alpha 0.
-- ═══════════════════════════════════════════════════════════════

local SF = {
    REQUEST_SCALEFORM_MOVIE      = 0x11FE353CF9733E6F,
    HAS_SCALEFORM_MOVIE_LOADED   = 0x85F01B8D5B90570E,
    DRAW_SCALEFORM_FULLSCREEN    = 0x0DF606929C105BE1,
    BEGIN_SCALEFORM_METHOD       = 0xF6E48914C7A8694E,
    ADD_PARAM_INT                = 0xC3D0841A0CC546A6,
    ADD_PARAM_FLOAT              = 0xD69736AAE04DB51A,
    ADD_PARAM_STRING             = 0xBA7148484BD90365,   -- ..._ADD_PARAM_TEXTURE_NAME_STRING
    ADD_PARAM_BOOL               = 0xC58424BA936EB458,
    END_SCALEFORM_METHOD         = 0xC6796A8FFA375E53,
    END_SCALEFORM_METHOD_RET     = 0xC50AA39A577AF886,   -- ..._RETURN_VALUE
    IS_LOADING_SCREEN_ACTIVE     = 0x10D0A8F259E93EC9,
    IS_INITIAL_LOADING_ACTIVE    = 0xC4637A6D03C24CC3,
}

local bannerShown = false

local function showLoadingBanner()
    if bannerShown then return end
    bannerShown = true
    Script.QueueJob(function()
        -- Wait until loading screens are done (both must clear)
        while true do
            local ok, loading = pcall(Natives.InvokeBool, SF.IS_LOADING_SCREEN_ACTIVE)
            local ok2, initial = pcall(Natives.InvokeBool, SF.IS_INITIAL_LOADING_ACTIVE)
            if ok and ok2 and not loading and not initial then break end
            if isShuttingDown then return end
            Script.Yield(500)
        end
        Script.Yield(500) -- small extra delay for game to settle

        local colors = {"~r~", "~o~", "~y~", "~g~", "~b~", "~p~", "~c~", "~w~"}
        local message = "V" .. SCRIPT_VERSION .. " LOADED | BY WUMPUS | 65 FEATURES"
        local duration = 300
        local startPos = 0.0
        local targetPos = 0.55

        -- Glitch-decode title: random glyphs resolve left-to-right into
        -- the word over ~80 frames, then each letter runs its own inline
        -- rainbow token (a wave through the word) with occasional 4-frame
        -- corruption bursts flickering letters back into red glyphs.
        local TITLE = "BODYGUARDS"
        local GLYPHS = {"#", "$", "%", "&", "?", "*", "+", "=", "/", "!", "0", "1", "X", "Z"}
        local burstLeft = 0
        local burstPos = {}

        local function buildTitle(i)
            local resolved = math.floor(i / 8)
            if resolved >= #TITLE then
                if burstLeft > 0 then
                    burstLeft = burstLeft - 1
                elseif math.random(100) <= 3 then
                    burstLeft = 4
                    burstPos = {math.random(#TITLE), math.random(#TITLE)}
                end
            end
            local out = {}
            for j = 1, #TITLE do
                local corrupted = j > resolved
                if not corrupted and burstLeft > 0 then
                    for _, bp in ipairs(burstPos) do
                        if bp == j then corrupted = true break end
                    end
                end
                if corrupted then
                    out[#out + 1] = "~r~" .. GLYPHS[math.random(#GLYPHS)]
                else
                    local ci = ((math.floor(i / 5) + j) % #colors) + 1
                    out[#out + 1] = colors[ci] .. TITLE:sub(j, j)
                end
            end
            return table.concat(out)
        end

        for i = 0, duration do
            if isShuttingDown then break end
            pcall(function()
                local sf = Natives.InvokeInt(SF.REQUEST_SCALEFORM_MOVIE, "MP_BIG_MESSAGE_FREEMODE")
                local ok, loaded = pcall(Natives.InvokeBool, SF.HAS_SCALEFORM_MOVIE_LOADED, sf)
                if not ok or not loaded then return end

                Natives.InvokeVoid(SF.BEGIN_SCALEFORM_METHOD, sf, "OVERRIDE_Y_POSITION")
                Natives.InvokeVoid(SF.ADD_PARAM_FLOAT, startPos - 0.75)
                Natives.InvokeVoid(SF.END_SCALEFORM_METHOD)
                if startPos < targetPos then startPos = startPos + (targetPos - startPos) / 75.0 end
                if i > duration - 150 then startPos = startPos - startPos / 50.0 end

                -- Glitch-decode -> per-letter rainbow wave
                local title = buildTitle(i)
                Natives.InvokeVoid(SF.BEGIN_SCALEFORM_METHOD, sf, "SHOW_CENTERED_MP_MESSAGE_LARGE")
                Natives.InvokeVoid(SF.ADD_PARAM_STRING, title)
                Natives.InvokeVoid(SF.ADD_PARAM_STRING, message)
                Natives.InvokeVoid(SF.ADD_PARAM_INT, 100)
                Natives.InvokeVoid(SF.ADD_PARAM_BOOL, true)
                Natives.InvokeVoid(SF.END_SCALEFORM_METHOD_RET)
                Natives.InvokeVoid(SF.DRAW_SCALEFORM_FULLSCREEN, sf, 255, 255, 255, 0, 0)
            end)
            Script.Yield(0)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- RELATIONSHIP GROUPS — GRAY CROSSHAIR + NO FRIENDLY FIRE
-- ═══════════════════════════════════════════════════════════════
-- Relationship values:
-- 0 = Companion → gray crosshair, no damage, no auto-aim
-- 1 = Respect
-- 2 = Like
-- 3 = Neutral
-- 5 = Hate (will attack)

local function initRelationships()
    if bgGroupHash then return end

    Script.QueueJob(function()
        -- Create bodyguard relationship group
        local ptr = Memory.AllocInt()
        Memory.WriteInt(ptr, 0)
        pcall(Natives.InvokeBool, N.ADD_RELATIONSHIP_GROUP, "BG_SQUAD_V4", ptr)
        bgGroupHash = Memory.ReadInt(ptr)
        Memory.Free(ptr)

        if not bgGroupHash or bgGroupHash == 0 then
            bgGroupHash = joaat("PLAYER")
            log("WARN: Using PLAYER group fallback")
        end

        -- Get player's actual relationship hash
        local pHash = getPlayerRelHash()
        log("Player rel hash: " .. pHash .. " | BG hash: " .. bgGroupHash)

        -- BG <-> Player: COMPANION (0) both directions
        -- This is what makes the crosshair turn gray
        pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, bgGroupHash, pHash)
        pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, pHash, bgGroupHash)

        -- Also set against generic PLAYER hash in case Online uses it
        local genericPlayer = joaat("PLAYER")
        if genericPlayer ~= pHash then
            pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, bgGroupHash, genericPlayer)
            pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, genericPlayer, bgGroupHash)
        end

        -- BG <-> BG: COMPANION (don't fight each other)
        pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, bgGroupHash, bgGroupHash)

        -- BG <-> hostile groups: HATE (bidirectional so combat triggers properly)
        local hostileGroups = {
            "AMBIENT_GANG_LOST", "AMBIENT_GANG_MEXICAN",
            "AMBIENT_GANG_FAMILY", "AMBIENT_GANG_BALLAS",
            "AMBIENT_GANG_MARABUNTE", "AMBIENT_GANG_CULT",
            "AMBIENT_GANG_SALVA", "AMBIENT_GANG_WEICHENG",
            "AMBIENT_GANG_HILLBILLY", "HATES_PLAYER",
            "COP", "ARMY", "GUARD_DOG", "SECURITY_GUARD",
            "PRISONER", "FIREMAN",
        }
        for _, groupName in ipairs(hostileGroups) do
            pcall(function()
                local gh = joaat(groupName)
                Natives.InvokeVoid(N.SET_RELATIONSHIP_BETWEEN_GROUPS, 5, bgGroupHash, gh) -- BG hates them
                Natives.InvokeVoid(N.SET_RELATIONSHIP_BETWEEN_GROUPS, 5, gh, bgGroupHash) -- They hate BG
            end)
        end

        log("Relationships initialized OK")
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- APPLY SETTINGS TO A SINGLE BODYGUARD
-- ═══════════════════════════════════════════════════════════════

local function applyFriendlyProtection(ped)
    -- === RELATIONSHIP GROUP (makes crosshair gray) ===
    if bgGroupHash then
        pcall(Natives.InvokeVoid, N.SET_PED_RELATIONSHIP_GROUP_HASH, ped, bgGroupHash)
    end

    -- === CANNOT ATTACK FRIENDLIES ===
    pcall(Natives.InvokeVoid, N.SET_CAN_ATTACK_FRIENDLY, ped, sicTarget ~= nil, false)

    -- === CANNOT BE TARGETED BY PLAYER (gray crosshair + no lock-on) ===
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_BE_TARGETTED, ped, false)
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_BE_TARGETTED_BY_PLAYER, ped, myId(), false)
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_BE_TARGETTED_BY_TEAM, ped, myId(), false)

    -- === FRIENDLY-FIRE DAMAGE BLOCK (v4.0 fix) ===
    -- Earlier builds set bulletProof + meleeProof here, which made guards
    -- immune to EVERYONE's attacks — the "god mode by default" report.
    -- Now only YOUR relationship group is blocked from damaging them;
    -- NPCs and enemies hurt guards normally (Auto-Revive matters now).
    pcall(Natives.InvokeVoid, N.SET_ENTITY_PROOFS, ped,
        false,  -- bulletProof
        false,  -- fireProof
        state.explosiveBullets,  -- explosionProof — immune to their own explosive rounds
        false,  -- collisionProof
        false,  -- meleeProof
        false,  -- p6
        false,  -- p7
        false)  -- drownProof
    local ffHash = playerRelHash or getPlayerRelHash()
    if ffHash and ffHash ~= 0 then
        pcall(Natives.InvokeVoid, N.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP, ped, false, ffHash)
    end

    -- === NO COLLISION both directions ===
    pcall(Natives.InvokeVoid, N.SET_ENTITY_NO_COLLISION_ENTITY, ped, myPed(), false)
    pcall(Natives.InvokeVoid, N.SET_ENTITY_NO_COLLISION_ENTITY, myPed(), ped, false)
end

local function applySettings(ped, isAnimalPed)
    if not entityExists(ped) then return end

    -- ============================================
    -- FRIENDLY FIRE PREVENTION
    -- ============================================
    applyFriendlyProtection(ped)

    -- Config flags
    pcall(Natives.InvokeVoid, N.SET_PED_CONFIG_FLAG, ped, 2, true)    -- NoCriticalHits
    pcall(Natives.InvokeVoid, N.SET_PED_CONFIG_FLAG, ped, 52, true)   -- DontInfluenceWantedLevel
    pcall(Natives.InvokeVoid, N.SET_PED_CONFIG_FLAG, ped, 46, true)   -- IgnoreBeingOnFire
    pcall(Natives.InvokeVoid, N.SET_PED_SUFFERS_CRITICAL_HITS, ped, false)

    -- Seat retention (v4.0): don't get ejected when a vehicle flips
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE, ped, 1)   -- KNOCKOFF_NEVER
    pcall(Natives.InvokeVoid, N.SET_PED_CONFIG_FLAG, ped, 32, false)          -- no fly through windscreen

    -- No Ragdoll (v4.0): guards can't be knocked over / bumped around
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_RAGDOLL, ped, not state.noRagdoll)

    -- ============================================
    -- GOD MODE / TUNED SURVIVABILITY
    -- ============================================
    pcall(Natives.InvokeVoid, N.SET_ENTITY_INVINCIBLE, ped, state.godMode)
    if state.godMode then
        pcall(Natives.InvokeVoid, N.SET_PED_MAX_HEALTH, ped, 10000)
        pcall(Natives.InvokeVoid, N.SET_ENTITY_HEALTH, ped, 10000, 0)
        pcall(Natives.InvokeVoid, N.SET_PED_ARMOUR, ped, 500)
    else
        pcall(Natives.InvokeVoid, N.SET_PED_MAX_HEALTH, ped, state.health)
        pcall(Natives.InvokeVoid, N.SET_ENTITY_HEALTH, ped, state.health, 0)
        pcall(Natives.InvokeVoid, N.SET_PED_ARMOUR, ped, state.armor)
    end

    -- ============================================
    -- VISIBILITY
    -- ============================================
    if state.invisible then
        if state.localVisible then
            pcall(Natives.InvokeVoid, N.SET_ENTITY_VISIBLE, ped, true)
            pcall(Natives.InvokeVoid, N.SET_ENTITY_ALPHA, ped, 180, false)
        else
            pcall(Natives.InvokeVoid, N.SET_ENTITY_VISIBLE, ped, false)
        end
    else
        pcall(Natives.InvokeVoid, N.SET_ENTITY_VISIBLE, ped, true)
        pcall(Natives.InvokeVoid, N.SET_ENTITY_ALPHA, ped, 255, false)
    end

    -- ============================================
    -- COMBAT
    -- ============================================
    if not isAnimalPed then
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ABILITY, ped, 2)
        pcall(Natives.InvokeVoid, N.SET_PED_ACCURACY, ped, state.accuracy)
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_RANGE, ped, 1)            -- Medium range (stay near player)

        local pw = state.givePrimary and primaryWeapon() or nil
        local wHash = pw and pw.h
        if not wHash or not NO_FULL_AUTO[wHash] then
            pcall(Natives.InvokeVoid, N.SET_PED_FIRING_PATTERN, ped, FIRING_FULL_AUTO)
        end

        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 0, true)   -- CanUseCover
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 1, true)   -- CanUseVehicles
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 2, true)   -- CanDoDrivebys
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 3, false)  -- CanLeaveVehicle = no
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 5, true)   -- AlwaysFight
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 13, true)  -- AggressivelyEngageOnFoot
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 20, true)  -- CanTauntInVehicle
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 26, true)  -- CanChaseTargetOnFoot
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 42, false) -- AlwaysEquipBestWeapon = OFF
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 46, true)  -- CanFightArmedOnFoot
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 52, true)  -- UseVehicleAttack
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 58, true)  -- DisableFleeFromCombat
    else
        -- Animal: aggression via combat attributes + mood only
        -- NOTE: config flags 292/249 freeze certain animals (chimps), don't use them
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ABILITY, ped, 2)
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_RANGE, ped, 1)
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 5, true)   -- AlwaysFight
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 13, true)  -- Aggressive
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 26, true)  -- ChaseOnFoot
        pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 58, true)  -- DisableFlee
        pcall(Natives.InvokeVoid, N.SET_ANIMAL_MOOD, ped, 2)                   -- Aggressive
    end

    -- NOTE: Do NOT use SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(true) here
    -- It blocks combat assist events from the player group system
    -- Group membership + SET_PED_NEVER_LEAVES_GROUP already prevents wandering

    -- ============================================
    -- BEHAVIOUR — initial combat task
    -- ============================================
    -- NOTE: Do NOT use SET_PED_KEEP_TASK(true) — it locks the ped's task
    -- and prevents the group system from issuing combat assist tasks.
    -- The tick loop periodically refreshes combat via REGISTER_HATED_TARGETS.
    local bIdx = state.behavIdx + 1
    local behav = BEHAVIOURS[bIdx]
    if behav and behav.range > 0 then
        pcall(Natives.InvokeVoid, N.TASK_COMBAT_HATED_TARGETS, ped, behav.range, 0)
        pcall(Natives.InvokeVoid, N.REGISTER_HATED_TARGETS_AROUND_PED, ped, behav.range)
    end
end

local function applySettingsToAll()
    for _, bg in ipairs(bodyguards) do
        pcall(applySettings, bg.handle, bg.isAnimal)
    end
    local playerGroup = Natives.InvokeInt(N.GET_PLAYER_GROUP, myId())
    if playerGroup and playerGroup ~= 0 then
        local fIdx = state.formIdx + 1
        local fv = FORMATIONS[fIdx] and FORMATIONS[fIdx].v or 0
        pcall(Natives.InvokeVoid, N.SET_GROUP_FORMATION, playerGroup, fv)
        pcall(Natives.InvokeVoid, N.SET_GROUP_FORMATION_SPACING, playerGroup, state.spacing + 0.0, -1.0, -1.0)
    end
end

-- Give the selected loadout to a ped (v4.0)
-- PRIMARY ONLY here — the secondary is strictly a vehicle weapon and is
-- provisioned/stripped by the smart-weapon loop on seat transitions, so
-- guard AI can never select it on foot.
local function giveSelectedWeapon(ped, isAnimalPed)
    pcall(Natives.InvokeVoid, N.REMOVE_ALL_PED_WEAPONS, ped, true)

    local pri = state.givePrimary and primaryWeapon() or nil
    if pri then
        pcall(Natives.InvokeVoid, N.GIVE_WEAPON_TO_PED, ped, pri.h, 9999, false, true)
        pcall(Natives.InvokeVoid, N.SET_PED_AMMO, ped, pri.h, 9999, false)
        pcall(Natives.InvokeVoid, N.SET_PED_INFINITE_AMMO, ped, true, pri.h)
        pcall(Natives.InvokeVoid, N.SET_CURRENT_PED_WEAPON, ped, pri.h, true)
    end
    pcall(Natives.InvokeVoid, N.SET_PED_INFINITE_AMMO_CLIP, ped, true)
    pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 42, false)
    pcall(Natives.InvokeVoid, N.SET_PED_CAN_SWITCH_WEAPON, ped, false)
end

-- Re-arm all bodyguards with new weapon
local function rearmAll()
    Script.QueueJob(function()
        for _, bg in ipairs(bodyguards) do
            if entityExists(bg.handle) then
                pcall(giveSelectedWeapon, bg.handle, bg.isAnimal)
                Script.Yield(0)
            end
        end
        local pri = state.givePrimary and primaryWeapon() or nil
        local sec = state.giveSecondary and secondaryWeapon() or nil
        toast("Armed: " .. (pri and pri.n or "none") .. " / " .. (sec and sec.n or "none"))
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- SPAWN BODYGUARD(S)
-- ═══════════════════════════════════════════════════════════════

local function spawnBodyguards(modelHash, modelName, isAnimal)
    -- Hard limit check BEFORE queueing
    if #bodyguards >= MAX_BODYGUARDS then
        toast("Max " .. MAX_BODYGUARDS .. " bodyguards! Delete some first.")
        return
    end

    initRelationships()

    Script.QueueJob(function()
        Script.Yield(200)

        -- Re-check limit INSIDE job (state may have changed during yield)
        if #bodyguards >= MAX_BODYGUARDS then
            toast("Max " .. MAX_BODYGUARDS .. " bodyguards reached!")
            return
        end

        if not requestModel(modelHash) then
            toast("Failed to load: " .. modelName)
            return
        end

        local px, py, pz = myCoords()
        if not px then toast("Position error") return end

        local playerGroup = Natives.InvokeInt(N.GET_PLAYER_GROUP, myId())

        -- Clamp to remaining slots
        local remaining = MAX_BODYGUARDS - #bodyguards
        local count = math.min(state.pedCount, remaining)
        local spawned = 0

        for i = 1, count do
            -- Safety: re-check every iteration
            if #bodyguards >= MAX_BODYGUARDS then break end

            local angle = (i / count) * math.pi * 2
            local ox = math.cos(angle) * 2.5
            local oy = math.sin(angle) * 2.5

            local ped = GTA.CreatePed(modelHash, 26, px + ox, py + oy, pz, 0.0, true, false)
            if ped and ped ~= 0 then
                -- Add to player group
                pcall(Natives.InvokeVoid, N.SET_PED_AS_GROUP_MEMBER, ped, playerGroup)
                pcall(Natives.InvokeVoid, N.SET_PED_NEVER_LEAVES_GROUP, ped, true)

                -- v4.0: random clothing variation. Freemode models are ALWAYS
                -- randomized — their default components are blank/broken, and
                -- uniformed models (military etc.) have too few variations to
                -- visibly change, which is why the toggle "did nothing" there.
                local isFreemode = modelHash == joaat("mp_m_freemode_01")
                    or modelHash == joaat("mp_f_freemode_01")
                if (state.randomOutfit or isFreemode) and not isAnimal then
                    pcall(Natives.InvokeVoid, N.SET_PED_RANDOM_COMPONENT_VARIATION, ped, 0)
                end

                -- Give weapon
                giveSelectedWeapon(ped, isAnimal)

                -- Apply all settings + friendly fire protection
                applySettings(ped, isAnimal)

                -- Blip (v4.0: user-selected color)
                local blip = 0
                pcall(function()
                    blip = Natives.InvokeInt(N.ADD_BLIP_FOR_ENTITY, ped)
                    if blip and blip ~= 0 then
                        local bc = BLIP_COLORS[state.blipColorIdx + 1]
                        Natives.InvokeVoid(N.SET_BLIP_COLOUR, blip, bc and bc.v or 57)
                        Natives.InvokeVoid(N.SET_BLIP_SCALE, blip, 0.7)
                    end
                end)

                -- v4.0 fix: number from 1 (length was read before insert in v3.4)
                bodyguards[#bodyguards + 1] = {
                    handle   = ped,
                    model    = modelName,
                    name     = modelName .. " #" .. (#bodyguards + 1),
                    blip     = blip,
                    isAnimal = isAnimal,
                }
                spawned = spawned + 1
            end
            Script.Yield(0)
        end

        Natives.InvokeVoid(N.SET_MODEL_NO_LONGER, modelHash)

        -- Apply formation + spacing
        if playerGroup and playerGroup ~= 0 then
            local fIdx = state.formIdx + 1
            local fv = FORMATIONS[fIdx] and FORMATIONS[fIdx].v or 0
            pcall(Natives.InvokeVoid, N.SET_GROUP_FORMATION, playerGroup, fv)
            pcall(Natives.InvokeVoid, N.SET_GROUP_FORMATION_SPACING, playerGroup, state.spacing + 0.0, -1.0, -1.0)
        end

        toast("Spawned " .. spawned .. "x " .. modelName .. " (" .. #bodyguards .. "/" .. MAX_BODYGUARDS .. ")")
    end)
end

-- Spawn from dropdown
local function spawnFromDropdown()
    -- Randomize override: chaotic GTA Online peds regardless of selection
    if state.randomOutfit then
        local mdl = (math.random(2) == 1) and "mp_m_freemode_01" or "mp_f_freemode_01"
        spawnBodyguards(joaat(mdl), "Online Random", false)
        return
    end
    local catIdx = state.catIdx + 1
    local modIdx = state.modelIdx + 1
    local cat = MODELS[catIdx]
    if not cat then toast("Invalid category") return end
    local modelInfo = cat[modIdx]
    if not modelInfo then toast("Invalid model") return end
    spawnBodyguards(joaat(modelInfo.h), modelInfo.n, catIdx == 1)
end

-- Spawn from custom InputText
local function spawnFromCustom()
    local txt = state.customModel
    if not txt or txt == "" then toast("Enter a model name first") return end
    txt = txt:match("^%s*(.-)%s*$")
    if txt == "" then toast("Empty model name") return end

    local modelHash = joaat(txt)
    local valid = false
    pcall(function()
        valid = Natives.InvokeBool(N.IS_MODEL_IN_CDIMAGE, modelHash)
    end)
    if not valid then
        toast("Invalid model: " .. txt)
        return
    end

    local isAnimal = txt:sub(1, 4) == "a_c_"
    spawnBodyguards(modelHash, txt, isAnimal)
end

-- Spawn bodyguard clone(s) of the local player — full freemode
-- appearance carried over by CLONE_PED(ped, isNetwork, hostPed, copyHeadBlend)
local function spawnClones()
    if #bodyguards >= MAX_BODYGUARDS then
        toast("Max " .. MAX_BODYGUARDS .. " bodyguards! Delete some first.")
        return
    end
    initRelationships()
    Script.QueueJob(function()
        Script.Yield(200)
        local px, py, pz = myCoords()
        if not px then toast("Position error") return end
        local playerGroup = Natives.InvokeInt(N.GET_PLAYER_GROUP, myId())

        local remaining = MAX_BODYGUARDS - #bodyguards
        local count = math.min(state.pedCount, remaining)
        local spawned = 0

        for i = 1, count do
            if #bodyguards >= MAX_BODYGUARDS then break end

            local clone = 0
            pcall(function()
                clone = Natives.InvokeInt(N.CLONE_PED, myPed(), true, false, true)
            end)

            if clone and clone ~= 0 then
                local angle = (i / count) * math.pi * 2
                pcall(Natives.InvokeVoid, N.SET_ENTITY_COORDS, clone,
                    px + math.cos(angle) * 2.5, py + math.sin(angle) * 2.5, pz,
                    false, false, false, false)

                pcall(Natives.InvokeVoid, N.SET_PED_AS_GROUP_MEMBER, clone, playerGroup)
                pcall(Natives.InvokeVoid, N.SET_PED_NEVER_LEAVES_GROUP, clone, true)

                giveSelectedWeapon(clone, false)
                applySettings(clone, false)

                local blip = 0
                pcall(function()
                    blip = Natives.InvokeInt(N.ADD_BLIP_FOR_ENTITY, clone)
                    if blip and blip ~= 0 then
                        local bc = BLIP_COLORS[state.blipColorIdx + 1]
                        Natives.InvokeVoid(N.SET_BLIP_COLOUR, blip, bc and bc.v or 57)
                        Natives.InvokeVoid(N.SET_BLIP_SCALE, blip, 0.7)
                    end
                end)

                bodyguards[#bodyguards + 1] = {
                    handle   = clone,
                    model    = "Clone",
                    name     = "Clone #" .. (#bodyguards + 1),
                    blip     = blip,
                    isAnimal = false,
                }
                spawned = spawned + 1
            end
            Script.Yield(50)
        end
        toast("Spawned " .. spawned .. " clone(s) of you (" .. #bodyguards .. "/" .. MAX_BODYGUARDS .. ")")
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ACTIONS
-- ═══════════════════════════════════════════════════════════════

local function teleportAllToMe()
    local px, py, pz = myCoords()
    if not px then return end
    local count = 0
    for i, bg in ipairs(bodyguards) do
        if entityExists(bg.handle) then
            local angle = (i / #bodyguards) * math.pi * 2
            pcall(Natives.InvokeVoid, N.SET_ENTITY_COORDS, bg.handle,
                px + math.cos(angle) * 3.0, py + math.sin(angle) * 3.0, pz,
                false, false, false, false)
            count = count + 1
        end
    end
    toast("Teleported " .. count .. " bodyguards")
end

-- Teleport one guard beside the player (roster button)
local function teleportOne(bg, i)
    if not entityExists(bg.handle) then return end
    local px, py, pz = myCoords()
    if not px then return end
    local angle = (i / math.max(#bodyguards, 1)) * math.pi * 2
    pcall(Natives.InvokeVoid, N.SET_ENTITY_COORDS, bg.handle,
        px + math.cos(angle) * 3.0, py + math.sin(angle) * 3.0, pz,
        false, false, false, false)
end

-- Heal one guard to current tuning (roster button)
local function healOne(bg)
    if not entityExists(bg.handle) then return end
    local hp = state.godMode and 10000 or state.health
    local ar = state.godMode and 500 or state.armor
    pcall(Natives.InvokeVoid, N.SET_ENTITY_HEALTH, bg.handle, hp, 0)
    pcall(Natives.InvokeVoid, N.SET_PED_ARMOUR, bg.handle, ar)
end

local function healAll()
    local n = 0
    for _, bg in ipairs(bodyguards) do
        if entityExists(bg.handle) then
            healOne(bg)
            n = n + 1
        end
    end
    toast("Healed " .. n .. " bodyguards")
end

-- Recolor all live blips to the selected color
local function applyBlipColorAll()
    local bc = BLIP_COLORS[state.blipColorIdx + 1]
    if not bc then return end
    for _, bg in ipairs(bodyguards) do
        if bg.blip and bg.blip ~= 0 then
            pcall(Natives.InvokeVoid, N.SET_BLIP_COLOUR, bg.blip, bc.v)
        end
    end
end

local function deleteAll()
    local count = #bodyguards + #shadowGuards
    for i = #bodyguards, 1, -1 do
        local bg = bodyguards[i]
        removeBlipSafe(bg.blip)
        pcall(deleteEntity, bg.handle)
        table.remove(bodyguards, i)
    end
    for i = #shadowGuards, 1, -1 do
        pcall(deleteEntity, shadowGuards[i].handle)
        table.remove(shadowGuards, i)
    end
    toast("Deleted " .. count .. " bodyguards")
end

-- ═══════════════════════════════════════════════════════════════
-- DEAD GUARD HANDLING + AUTO-REVIVE (v4.0)
-- ═══════════════════════════════════════════════════════════════
-- With Auto-Revive ON, a downed guard stays on the ground for
-- reviveDelay seconds, then gets back up. Death strips group
-- membership and drops weapons, so revive does the full pipeline:
-- RESURRECT_PED -> immediate task clear -> re-group -> re-arm ->
-- re-apply settings. With Auto-Revive OFF, v3.4 behavior (cleanup).

local function reviveGuard(bg)
    if not entityExists(bg.handle) then return end
    pcall(Natives.InvokeVoid, N.RESURRECT_PED, bg.handle)
    pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS_IMMEDIATELY, bg.handle)
    local hp = state.godMode and 10000 or state.health
    pcall(Natives.InvokeVoid, N.SET_ENTITY_HEALTH, bg.handle, hp, 0)
    local playerGroup = Natives.InvokeInt(N.GET_PLAYER_GROUP, myId())
    if playerGroup and playerGroup ~= 0 then
        pcall(Natives.InvokeVoid, N.SET_PED_AS_GROUP_MEMBER, bg.handle, playerGroup)
        pcall(Natives.InvokeVoid, N.SET_PED_NEVER_LEAVES_GROUP, bg.handle, true)
    end
    pcall(giveSelectedWeapon, bg.handle, bg.isAnimal)
    pcall(applySettings, bg.handle, bg.isAnimal)
    bg.downedAt = nil
    bg.medicPed = nil
    toast(bg.name .. " is back up")
end

local function cleanupDead()
    local t = nowMs()
    -- Rebuild medic-duty exemptions each pass
    for k in pairs(medicDuty) do medicDuty[k] = nil end
    for i = #bodyguards, 1, -1 do
        local bg = bodyguards[i]
        if not entityExists(bg.handle) then
            removeBlipSafe(bg.blip)
            table.remove(bodyguards, i)
        else
            local ok, d = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, bg.handle, true)
            local dead = ok and d
            if dead and state.autoRevive then
                if not bg.downedAt then
                    bg.downedAt = t
                elseif t - bg.downedAt >= state.reviveDelay * 1000 then
                    reviveGuard(bg)
                elseif state.medicRush then
                    -- MEDIC RUSH: nearest living teammate sprints over;
                    -- contact (<3.5m) = instant revive. Timer above stays
                    -- as the fallback if the medic can't get there.
                    local medic = bg.medicPed
                    local medicOk = medic and entityExists(medic)
                    if medicOk then
                        local ok2, d2 = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, medic, true)
                        if ok2 and d2 then medicOk = false end
                    end
                    if not medicOk then
                        bg.medicPed = nil
                        local bxx, byy, bzz = Natives.InvokeV3(N.GET_ENTITY_COORDS, bg.handle, true)
                        if bxx then
                            local best, bestD = nil, 1e12
                            for _, other in ipairs(bodyguards) do
                                if other ~= bg and entityExists(other.handle) and not other.downedAt then
                                    local ox, oy, oz = Natives.InvokeV3(N.GET_ENTITY_COORDS, other.handle, true)
                                    if ox then
                                        local dx1, dy1, dz1 = ox - bxx, oy - byy, oz - bzz
                                        local dd = dx1 * dx1 + dy1 * dy1 + dz1 * dz1
                                        if dd < bestD then best, bestD = other.handle, dd end
                                    end
                                end
                            end
                            if best then
                                bg.medicPed = best
                                bg.medicTaskAt = t
                                pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS, best)
                                pcall(Natives.InvokeVoid, N.TASK_GO_TO_ENTITY, best, bg.handle, -1, 1.5, 3.0, 4.0, 0)
                            end
                        end
                    else
                        medicDuty[medic] = true
                        -- Keep the rescue task alive (combat AI can shrug it off)
                        if t - (bg.medicTaskAt or 0) > 2000 then
                            bg.medicTaskAt = t
                            pcall(Natives.InvokeVoid, N.TASK_GO_TO_ENTITY, medic, bg.handle, -1, 1.5, 3.0, 4.0, 0)
                        end
                        local bxx, byy, bzz = Natives.InvokeV3(N.GET_ENTITY_COORDS, bg.handle, true)
                        local mx, my, mz = Natives.InvokeV3(N.GET_ENTITY_COORDS, medic, true)
                        if bxx and mx then
                            local dx1, dy1, dz1 = mx - bxx, my - byy, mz - bzz
                            if dx1 * dx1 + dy1 * dy1 + dz1 * dz1 < 12.25 then
                                pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS, medic)
                                reviveGuard(bg)
                            end
                        end
                    end
                end
            elseif dead then
                removeBlipSafe(bg.blip)
                pcall(deleteEntity, bg.handle)
                table.remove(bodyguards, i)
            elseif bg.downedAt then
                bg.downedAt = nil
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PLAYER-LIST SYSTEM (v4.0) — Sic 'Em + Attack Squad
-- ═══════════════════════════════════════════════════════════════
-- Seed of the BB Attackers import: send YOUR squad after a selected
-- player, or drop a hostile blackops squad on them. The full attacker
-- roster ports over once the BB Attackers source is uploaded.

local function getPlayerPed(pid)
    local ok, ped = pcall(Natives.InvokeInt, N.GET_PLAYER_PED, pid)
    if ok and ped and ped ~= 0 then return ped end
    return 0
end

local function sicBodyguards(pid)
    local target = getPlayerPed(pid)
    if target == 0 then toast("Couldn't resolve target") return end
    sicTarget = target
    local n = 0
    for _, bg in ipairs(bodyguards) do
        if entityExists(bg.handle) and not bg.downedAt then
            pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS, bg.handle)
            pcall(Natives.InvokeVoid, N.REGISTER_TARGET, bg.handle, target)
            pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, bg.handle, target, 0, 16)
            n = n + 1
        end
    end
    toast(n > 0 and ("Sicced " .. n .. " bodyguards!") or "No bodyguards to send")
end

local function callOffBodyguards()
    sicTarget = nil
    for _, bg in ipairs(bodyguards) do
        if entityExists(bg.handle) then
            pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS, bg.handle)
        end
    end
    toast("Bodyguards called off")
end

local function spawnAttackSquad(pid)
    local target = getPlayerPed(pid)
    if target == 0 then toast("Couldn't resolve target") return end
    initRelationships()
    Script.QueueJob(function()
        Script.Yield(100)
        if not entityExists(target) then return end
        local tx, ty, tz = Natives.InvokeV3(N.GET_ENTITY_COORDS, target, true)
        if not tx then return end
        local pedHash = joaat("s_m_y_blackops_01")
        if not requestModel(pedHash) then toast("Model failed") return end
        local spawned = 0
        for i = 1, 3 do
            local angle = (i / 3) * math.pi * 2
            local ped = GTA.CreatePed(pedHash, 26,
                tx + math.cos(angle) * 6.0, ty + math.sin(angle) * 6.0, tz, 0.0, true, false)
            if ped and ped ~= 0 then
                pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ABILITY, ped, 2)
                pcall(Natives.InvokeVoid, N.SET_PED_ACCURACY, ped, 60)
                pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 5, true)
                pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 46, true)
                pcall(Natives.InvokeVoid, N.SET_PED_COMBAT_ATTRIBUTES, ped, 58, true)
                pcall(Natives.InvokeVoid, N.GIVE_WEAPON_TO_PED, ped, 0x83BF0278, 9999, false, true)
                pcall(Natives.InvokeVoid, N.SET_PED_INFINITE_AMMO, ped, true, 0x83BF0278)
                pcall(Natives.InvokeVoid, N.REGISTER_TARGET, ped, target)
                pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, ped, target, 0, 16)
                local blip = 0
                pcall(function()
                    blip = Natives.InvokeInt(N.ADD_BLIP_FOR_ENTITY, ped)
                    if blip and blip ~= 0 then
                        Natives.InvokeVoid(N.SET_BLIP_COLOUR, blip, 1)
                        Natives.InvokeVoid(N.SET_BLIP_SCALE, blip, 0.6)
                    end
                end)
                attackers[#attackers + 1] = {handle = ped, blip = blip, target = target}
                spawned = spawned + 1
            end
            Script.Yield(0)
        end
        Natives.InvokeVoid(N.SET_MODEL_NO_LONGER, pedHash)
        toast("Attack squad deployed: " .. spawned)
    end)
end

local function deleteAttackers()
    local n = #attackers
    for i = #attackers, 1, -1 do
        local a = attackers[i]
        removeBlipSafe(a.blip)
        pcall(deleteEntity, a.handle)
        table.remove(attackers, i)
    end
    if n > 0 then toast("Deleted " .. n .. " attackers") end
end

-- Attacker maintenance (1s): cleanup dead + keep pressure on the target
Script.RegisterLooped(function()
    if isShuttingDown or #attackers == 0 then Script.Yield(1000) return end
    for i = #attackers, 1, -1 do
        local a = attackers[i]
        pcall(function()
            local dead = not entityExists(a.handle)
            if not dead then
                local ok, d = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, a.handle, true)
                dead = ok and d
            end
            if dead then
                removeBlipSafe(a.blip)
                pcall(deleteEntity, a.handle)
                table.remove(attackers, i)
            elseif a.target and entityExists(a.target) then
                if not Natives.InvokeBool(N.IS_PED_IN_COMBAT, a.handle, 0) then
                    Natives.InvokeVoid(N.REGISTER_TARGET, a.handle, a.target)
                    Natives.InvokeVoid(N.TASK_COMBAT_PED, a.handle, a.target, 0, 16)
                end
            else
                -- Deployed troops (rappelled crew): free-hunt hostiles
                if not Natives.InvokeBool(N.IS_PED_IN_COMBAT, a.handle, 0) then
                    Natives.InvokeVoid(N.REGISTER_HATED_TARGETS_AROUND_PED, a.handle, 150.0)
                    Natives.InvokeVoid(N.TASK_COMBAT_HATED_TARGETS, a.handle, 150.0, 0)
                end
            end
        end)
    end
    Script.Yield(1000)
end)

-- ═══════════════════════════════════════════════════════════════
-- ESP HELPER (v4.0: pre-allocated pointers — no per-frame alloc/free)
-- ═══════════════════════════════════════════════════════════════

local function worldToScreen(wx, wy, wz)
    local onScreen = false
    pcall(function()
        onScreen = Natives.InvokeBool(N.GET_SCREEN_FROM_WORLD,
            wx, wy, wz, espXPtr, espYPtr)
    end)
    if onScreen then
        local sx = Memory.ReadFloat(espXPtr)
        local sy = Memory.ReadFloat(espYPtr)
        local dw, dh = ImGui.GetDisplaySize()
        return true, sx * dw, sy * dh
    end
    return false, 0, 0
end

-- ═══════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════

-- === SPAWNING ===

FeatureMgr.AddFeature(joaat("BG_PedCount"), "Ped Count",
    eFeatureType.SliderInt, "How many bodyguards to spawn (1-7)", function(f)
    state.pedCount = f:GetIntValue()
end, true)

FeatureMgr.AddFeature(joaat("BG_Category"), "Model Type",
    eFeatureType.Combo, "Select model category", function(f)
    state.catIdx = f:GetListIndex()
    pcall(function()
        local mf = FeatureMgr.GetFeature(joaat("BG_Model"))
        if mf then
            local newCat = state.catIdx + 1
            if MODEL_NAMES[newCat] then
                mf:SetList(MODEL_NAMES[newCat])
                mf:SetListIndex(0)
                state.modelIdx = 0
            end
        end
    end)
end, true)

FeatureMgr.AddFeature(joaat("BG_Model"), "Model",
    eFeatureType.Combo, "Select specific model", function(f)
    state.modelIdx = f:GetListIndex()
end, true)

FeatureMgr.AddFeature(joaat("BG_CustomModel"), "Custom Model",
    eFeatureType.InputText, "Type model name (e.g. a_c_chimp)", function(f)
    state.customModel = f:GetStringValue()
end, true)

FeatureMgr.AddFeature(joaat("BG_Spawn"), "Spawn Bodyguard",
    eFeatureType.Button, "Spawn from selected category/model", function(f)
    spawnFromDropdown()
end, true)

FeatureMgr.AddFeature(joaat("BG_SpawnCustom"), "Spawn Custom Model",
    eFeatureType.Button, "Spawn from the custom model name", function(f)
    spawnFromCustom()
end, true)

FeatureMgr.AddFeature(joaat("BG_SpawnClone"), "Spawn Clone of Me",
    eFeatureType.Button, "Spawn bodyguard clone(s) of your character (uses Ped Count)", function(f)
    spawnClones()
end, true)

-- === WEAPONS (v4.0 two-tier selector) ===

FeatureMgr.AddFeature(joaat("BG_PriCat"), "Primary Category",
    eFeatureType.Combo, "Primary weapon class", function(f)
    state.priCatIdx = f:GetListIndex()
    pcall(function()
        local pf = FeatureMgr.GetFeature(joaat("BG_Pri"))
        if pf and WNAMES[state.priCatIdx + 1] then
            pf:SetList(WNAMES[state.priCatIdx + 1])
            pf:SetListIndex(0)
            state.priIdx = 0
        end
    end)
    rearmAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Pri"), "Primary Weapon",
    eFeatureType.Combo, "Weapon guards use on foot", function(f)
    state.priIdx = f:GetListIndex()
    rearmAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_SecCat"), "Secondary Category",
    eFeatureType.Combo, "Secondary class (driveby-capable only)", function(f)
    state.secCatIdx = f:GetListIndex()
    pcall(function()
        local sf2 = FeatureMgr.GetFeature(joaat("BG_Sec"))
        if sf2 and WNAMES[state.secCatIdx + 1] then
            sf2:SetList(WNAMES[state.secCatIdx + 1])
            sf2:SetListIndex(0)
            state.secIdx = 0
        end
    end)
    rearmAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Sec"), "Secondary Weapon",
    eFeatureType.Combo, "Weapon guards use in vehicles / drivebys", function(f)
    state.secIdx = f:GetListIndex()
    rearmAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_GivePri"), "Give Primary Weapon",
    eFeatureType.Toggle, "Arm guards with the primary weapon", function(f)
    state.givePrimary = f:IsToggled()
    rearmAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_GiveSec"), "Give Secondary Weapon",
    eFeatureType.Toggle, "Arm guards with the secondary (vehicle) weapon", function(f)
    state.giveSecondary = f:IsToggled()
    rearmAll()
end, true)

-- === BODYGUARD SETTINGS ===

FeatureMgr.AddFeature(joaat("BG_GodMode"), "God Mode",
    eFeatureType.Toggle, "Bodyguards are invincible", function(f)
    state.godMode = f:IsToggled()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_NoRagdoll"), "No Ragdoll",
    eFeatureType.Toggle, "Guards can't be knocked over or bumped around", function(f)
    state.noRagdoll = f:IsToggled()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Invisible"), "Invisible",
    eFeatureType.Toggle, "Make bodyguards invisible", function(f)
    state.invisible = f:IsToggled()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_LocalVisible"), "Locally Visible",
    eFeatureType.Toggle, "Visible to you only (when invisible)", function(f)
    state.localVisible = f:IsToggled()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_WarpVehicle"), "Warp Into Vehicle",
    eFeatureType.Button, "Instantly warp bodyguards into your vehicle", function(f)
    Script.QueueJob(function()
        local player = myPed()
        if not Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, player, false) then
            toast("Get in a vehicle first") return
        end
        local veh = Natives.InvokeInt(N.GET_VEHICLE_PED_IS_IN, player, false)
        if not veh or veh == 0 then return end
        local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, veh)
        local warped, nextSeat = 0, 0
        for _, bg in ipairs(bodyguards) do
            if entityExists(bg.handle) and not bg.isAnimal
               and not Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false) then
                while nextSeat < maxSeats do
                    if Natives.InvokeBool(N.IS_VEHICLE_SEAT_FREE, veh, nextSeat) then
                        Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, bg.handle, veh, nextSeat)
                        warped = warped + 1
                        nextSeat = nextSeat + 1
                        break
                    end
                    nextSeat = nextSeat + 1
                end
            end
        end
        toast("Warped " .. warped .. " into vehicle")
    end)
end, true)

FeatureMgr.AddFeature(joaat("BG_Formation"), "Formation",
    eFeatureType.Combo, "Group walking formation", function(f)
    state.formIdx = f:GetListIndex()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Behaviour"), "Behaviour",
    eFeatureType.Combo, "Combat engagement style", function(f)
    state.behavIdx = f:GetListIndex()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Callouts"), "Combat Callouts",
    eFeatureType.Toggle, "Guards shout a war cry when they engage", function(f)
    state.callouts = f:IsToggled()
end, true)

-- === ADVANCED TUNING (v4.0) ===

FeatureMgr.AddFeature(joaat("BG_Accuracy"), "Accuracy",
    eFeatureType.SliderInt, "Bodyguard shooting accuracy (0-100)", function(f)
    state.accuracy = f:GetIntValue()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Health"), "Health",
    eFeatureType.SliderInt, "Max health when God Mode is off", function(f)
    state.health = f:GetIntValue()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Armor"), "Armor",
    eFeatureType.SliderInt, "Armor when God Mode is off", function(f)
    state.armor = f:GetIntValue()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_Spacing"), "Formation Spacing",
    eFeatureType.SliderInt, "Distance between guards in formation (meters)", function(f)
    state.spacing = f:GetIntValue()
    applySettingsToAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_BlipColor"), "Blip Color",
    eFeatureType.Combo, "Map blip color for bodyguards", function(f)
    state.blipColorIdx = f:GetListIndex()
    applyBlipColorAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_RandomOutfit"), "Randomize Outfits",
    eFeatureType.Toggle, "OVERRIDE: spawn chaotic randomized GTA Online peds", function(f)
    state.randomOutfit = f:IsToggled()
end, true)

-- === EXPLOSIVE ROUNDS (v4.0) ===

FeatureMgr.AddFeature(joaat("BG_ExpBullets"), "Explosive Rounds",
    eFeatureType.Toggle, "Guard bullets detonate on impact (guards become blast-proof)", function(f)
    state.explosiveBullets = f:IsToggled()
    applySettingsToAll()   -- refresh proofs immediately
end, true)

FeatureMgr.AddFeature(joaat("BG_ExpType"), "Explosion Type",
    eFeatureType.Combo, "Blast type for explosive rounds", function(f)
    state.expTypeIdx = f:GetListIndex()
end, true)

-- === ACTIONS ===

FeatureMgr.AddFeature(joaat("BG_TeleportAll"), "Teleport All To Me",
    eFeatureType.Button, "Teleport all bodyguards to you", function(f)
    teleportAllToMe()
end, true)

FeatureMgr.AddFeature(joaat("BG_HealAll"), "Heal All",
    eFeatureType.Button, "Restore health + armor on all bodyguards", function(f)
    healAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_DeleteAll"), "Delete All",
    eFeatureType.Button, "Delete all spawned bodyguards", function(f)
    deleteAll()
end, true)

FeatureMgr.AddFeature(joaat("BG_AutoTeleport"), "Auto Teleport All To Me",
    eFeatureType.Toggle, "Auto-teleport when 50m+ away", function(f)
    state.autoTeleport = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("BG_AutoRevive"), "Auto-Revive Downed Guards",
    eFeatureType.Toggle, "Downed guards get back up instead of despawning", function(f)
    state.autoRevive = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("BG_ReviveDelay"), "Revive Delay",
    eFeatureType.SliderInt, "Seconds a guard stays down before reviving", function(f)
    state.reviveDelay = f:GetIntValue()
end, true)

FeatureMgr.AddFeature(joaat("BG_MedicRush"), "Medic Rush",
    eFeatureType.Toggle, "Nearest teammate sprints to a downed guard for a contact revive", function(f)
    state.medicRush = f:IsToggled()
end, true)

-- === ESP ===

FeatureMgr.AddFeature(joaat("BG_ESPName"), "Name",
    eFeatureType.Toggle, "Show bodyguard names on screen", function(f)
    state.espName = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("BG_ESPHealth"), "Health",
    eFeatureType.Toggle, "Show health bars on screen", function(f)
    state.espHealth = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("BG_ESPDistance"), "Distance",
    eFeatureType.Toggle, "Show distance in meters", function(f)
    state.espDistance = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("BG_ESPTracer"), "Tracer",
    eFeatureType.Toggle, "Draw lines from screen center to bodyguards", function(f)
    state.espTracer = f:IsToggled()
end, true)

-- ═══════════════════════════════════════════════════════════════
-- CONFIG SAVE / LOAD SYSTEM (v4 format, v3 files still load)
-- ═══════════════════════════════════════════════════════════════

local CONFIG_DIR = FileMgr.GetMenuRootPath() .. "\\Lua\\BodyguardConfigs\\"
pcall(FileMgr.CreateDir, CONFIG_DIR)

local savedConfigs = {}   -- list of config names (no extension)

local function refreshConfigList()
    savedConfigs = {}
    local ok, files = pcall(FileMgr.FindFiles, CONFIG_DIR, ".cfg", false)
    if ok and files then
        for _, path in ipairs(files) do
            -- Extract filename without extension
            local name = path:match("([^\\]+)%.cfg$") or path:match("([^/]+)%.cfg$")
            if name then
                savedConfigs[#savedConfigs + 1] = name
            end
        end
    end
    table.sort(savedConfigs)

    -- Update combo dropdown
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_ConfigList"))
        if f then
            if #savedConfigs > 0 then
                f:SetList(savedConfigs)
                f:SetListIndex(0)
            else
                f:SetList({"(no configs saved)"})
                f:SetListIndex(0)
            end
        end
    end)
end

local function serializeConfig()
    local lines = {}
    lines[#lines + 1] = "-- Bodyguard Script Config"
    lines[#lines + 1] = "version=4"
    lines[#lines + 1] = "pedCount=" .. state.pedCount
    lines[#lines + 1] = "catIdx=" .. state.catIdx
    lines[#lines + 1] = "modelIdx=" .. state.modelIdx
    lines[#lines + 1] = "priCatIdx=" .. state.priCatIdx
    lines[#lines + 1] = "priIdx=" .. state.priIdx
    lines[#lines + 1] = "secCatIdx=" .. state.secCatIdx
    lines[#lines + 1] = "secIdx=" .. state.secIdx
    lines[#lines + 1] = "givePrimary=" .. tostring(state.givePrimary)
    lines[#lines + 1] = "giveSecondary=" .. tostring(state.giveSecondary)
    lines[#lines + 1] = "formIdx=" .. state.formIdx
    lines[#lines + 1] = "behavIdx=" .. state.behavIdx
    lines[#lines + 1] = "godMode=" .. tostring(state.godMode)
    lines[#lines + 1] = "noRagdoll=" .. tostring(state.noRagdoll)
    lines[#lines + 1] = "invisible=" .. tostring(state.invisible)
    lines[#lines + 1] = "localVisible=" .. tostring(state.localVisible)
    lines[#lines + 1] = "autoTeleport=" .. tostring(state.autoTeleport)
    lines[#lines + 1] = "espName=" .. tostring(state.espName)
    lines[#lines + 1] = "espHealth=" .. tostring(state.espHealth)
    lines[#lines + 1] = "espDistance=" .. tostring(state.espDistance)
    lines[#lines + 1] = "espTracer=" .. tostring(state.espTracer)
    -- v4.0 tuning
    lines[#lines + 1] = "accuracy=" .. state.accuracy
    lines[#lines + 1] = "health=" .. state.health
    lines[#lines + 1] = "armor=" .. state.armor
    lines[#lines + 1] = "spacing=" .. state.spacing
    lines[#lines + 1] = "blipColorIdx=" .. state.blipColorIdx
    lines[#lines + 1] = "randomOutfit=" .. tostring(state.randomOutfit)
    lines[#lines + 1] = "autoRevive=" .. tostring(state.autoRevive)
    lines[#lines + 1] = "reviveDelay=" .. state.reviveDelay
    lines[#lines + 1] = "medicRush=" .. tostring(state.medicRush)
    lines[#lines + 1] = "callouts=" .. tostring(state.callouts)
    lines[#lines + 1] = "explosiveBullets=" .. tostring(state.explosiveBullets)
    lines[#lines + 1] = "expTypeIdx=" .. state.expTypeIdx
    lines[#lines + 1] = "escAutoFlip=" .. tostring(escortState.autoFlip)
    lines[#lines + 1] = "escAirAlt=" .. escortState.airAlt
    lines[#lines + 1] = "escSearchlight=" .. tostring(escortState.searchlight)
    lines[#lines + 1] = "convoyStyleIdx=" .. escortState.styleIdx
    -- Save resolved model name so we can spawn from config
    local catIdx = state.catIdx + 1
    local modIdx = state.modelIdx + 1
    local cat = MODELS[catIdx]
    local modelInfo = cat and cat[modIdx]
    if modelInfo then
        lines[#lines + 1] = "modelName=" .. modelInfo.n
        lines[#lines + 1] = "modelHash=" .. modelInfo.h
        lines[#lines + 1] = "isAnimal=" .. tostring(catIdx == 1)
    end
    return table.concat(lines, "\n")
end

local function deserializeConfig(content)
    local cfg = {}
    for line in content:gmatch("[^\n]+") do
        if not line:match("^%-%-") then
            local key, val = line:match("^(%w+)=(.+)$")
            if key and val then
                cfg[key] = val
            end
        end
    end
    return cfg
end

local function clampInt(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function applyConfig(cfg)
    -- Parse values
    local function toBool(s) return s == "true" end
    local function toInt(s) return tonumber(s) or 0 end

    state.pedCount      = clampInt(toInt(cfg.pedCount or "1"), 1, MAX_BODYGUARDS)
    state.catIdx        = toInt(cfg.catIdx or "0")
    state.modelIdx      = toInt(cfg.modelIdx or "0")
    if cfg.priIdx ~= nil or cfg.priCatIdx ~= nil then
        state.priCatIdx = clampInt(toInt(cfg.priCatIdx or "3"), 0, #WEAPON_CATS - 1)
        state.priIdx    = clampInt(toInt(cfg.priIdx or "1"), 0, #WEAPON_CATS[state.priCatIdx + 1].list - 1)
        state.secCatIdx = clampInt(toInt(cfg.secCatIdx or "0"), 0, 1)
        state.secIdx    = clampInt(toInt(cfg.secIdx or "2"), 0, #WEAPON_CATS[state.secCatIdx + 1].list - 1)
        state.givePrimary   = cfg.givePrimary ~= "false"
        state.giveSecondary = cfg.giveSecondary ~= "false"
    elseif cfg.weaponIdx then
        -- v3 config migration: flat weapon index -> category/type
        local m = FLAT_MAP[toInt(cfg.weaponIdx) + 1]
        if m then state.priCatIdx, state.priIdx = m.c, m.i end
        state.givePrimary, state.giveSecondary = true, true
    end
    state.formIdx       = toInt(cfg.formIdx or "0")
    state.behavIdx      = toInt(cfg.behavIdx or "0")
    state.godMode       = toBool(cfg.godMode)
    state.noRagdoll     = toBool(cfg.noRagdoll)
    state.invisible     = toBool(cfg.invisible)
    state.localVisible  = toBool(cfg.localVisible)
    state.autoTeleport  = toBool(cfg.autoTeleport)
    state.espName       = toBool(cfg.espName)
    state.espHealth     = toBool(cfg.espHealth)
    state.espDistance   = toBool(cfg.espDistance)
    state.espTracer     = toBool(cfg.espTracer)
    -- v4.0 tuning (defaults keep v3 configs valid)
    state.accuracy      = clampInt(toInt(cfg.accuracy or "100"), 0, 100)
    state.health        = clampInt(toInt(cfg.health or "2000"), 200, 10000)
    state.armor         = clampInt(toInt(cfg.armor or "300"), 0, 1000)
    state.spacing       = clampInt(toInt(cfg.spacing or "2"), 1, 10)
    state.blipColorIdx  = clampInt(toInt(cfg.blipColorIdx or "0"), 0, #BLIP_COLORS - 1)
    state.randomOutfit  = toBool(cfg.randomOutfit)
    state.autoRevive    = toBool(cfg.autoRevive)
    state.reviveDelay   = clampInt(toInt(cfg.reviveDelay or "8"), 3, 30)
    state.medicRush     = toBool(cfg.medicRush)
    state.callouts      = toBool(cfg.callouts)
    state.explosiveBullets = toBool(cfg.explosiveBullets)
    state.expTypeIdx    = clampInt(toInt(cfg.expTypeIdx or "0"), 0, #EXPLOSION_TYPES - 1)
    escortState.autoFlip = toBool(cfg.escAutoFlip)
    escortState.airAlt   = clampInt(toInt(cfg.escAirAlt or "40"), 20, 120)
    escortState.searchlight = toBool(cfg.escSearchlight)
    escortState.styleIdx = clampInt(toInt(cfg.convoyStyleIdx or "0"), 0, #CONVOY_STYLES - 1)

    -- Push state to GUI features
    -- Use SetBoolValue for toggles (SetToggled doesn't exist, OnClick double-flips)
    pcall(function()
        local f

        -- Helper: set toggle visual state to match loaded config
        -- SetBoolValue sets the GUI visual without triggering a callback flip
        local function setToggle(hash, val)
            local ft = FeatureMgr.GetFeature(hash)
            if not ft then return end
            -- Try SetBoolValue first (explicitly for bool), fall back to SetValue
            local ok = pcall(function() ft:SetBoolValue(val) end)
            if not ok then
                pcall(function() ft:SetValue(val) end)
            end
        end

        f = FeatureMgr.GetFeature(joaat("BG_PedCount"))
        if f then f:SetValue(state.pedCount) end

        f = FeatureMgr.GetFeature(joaat("BG_Category"))
        if f then
            f:SetListIndex(state.catIdx)
            local mf = FeatureMgr.GetFeature(joaat("BG_Model"))
            if mf and MODEL_NAMES[state.catIdx + 1] then
                mf:SetList(MODEL_NAMES[state.catIdx + 1])
                mf:SetListIndex(state.modelIdx)
            end
        end

        f = FeatureMgr.GetFeature(joaat("BG_PriCat"))
        if f then
            f:SetListIndex(state.priCatIdx)
            local pf = FeatureMgr.GetFeature(joaat("BG_Pri"))
            if pf and WNAMES[state.priCatIdx + 1] then
                pf:SetList(WNAMES[state.priCatIdx + 1])
                pf:SetListIndex(state.priIdx)
            end
        end

        f = FeatureMgr.GetFeature(joaat("BG_SecCat"))
        if f then
            f:SetListIndex(state.secCatIdx)
            local sf2 = FeatureMgr.GetFeature(joaat("BG_Sec"))
            if sf2 and WNAMES[state.secCatIdx + 1] then
                sf2:SetList(WNAMES[state.secCatIdx + 1])
                sf2:SetListIndex(state.secIdx)
            end
        end

        f = FeatureMgr.GetFeature(joaat("BG_Formation"))
        if f then f:SetListIndex(state.formIdx) end

        f = FeatureMgr.GetFeature(joaat("BG_Behaviour"))
        if f then f:SetListIndex(state.behavIdx) end

        -- v4.0 tuning widgets
        f = FeatureMgr.GetFeature(joaat("BG_Accuracy"))
        if f then f:SetValue(state.accuracy) end

        f = FeatureMgr.GetFeature(joaat("BG_Health"))
        if f then f:SetValue(state.health) end

        f = FeatureMgr.GetFeature(joaat("BG_Armor"))
        if f then f:SetValue(state.armor) end

        f = FeatureMgr.GetFeature(joaat("BG_Spacing"))
        if f then f:SetValue(state.spacing) end

        f = FeatureMgr.GetFeature(joaat("BG_BlipColor"))
        if f then f:SetListIndex(state.blipColorIdx) end

        f = FeatureMgr.GetFeature(joaat("BG_ReviveDelay"))
        if f then f:SetValue(state.reviveDelay) end

        f = FeatureMgr.GetFeature(joaat("BG_ExpType"))
        if f then f:SetListIndex(state.expTypeIdx) end

        f = FeatureMgr.GetFeature(joaat("ESC_ConvoyStyle"))
        if f then f:SetListIndex(escortState.styleIdx) end

        f = FeatureMgr.GetFeature(joaat("ESC_AirAlt"))
        if f then f:SetValue(escortState.airAlt) end

        -- Toggle features — state vars already set from deserialization above
        -- SetBoolValue syncs the GUI visual to match
        setToggle(joaat("BG_GodMode"), state.godMode)
        setToggle(joaat("BG_NoRagdoll"), state.noRagdoll)
        setToggle(joaat("BG_Invisible"), state.invisible)
        setToggle(joaat("BG_LocalVisible"), state.localVisible)
        setToggle(joaat("BG_AutoTeleport"), state.autoTeleport)
        setToggle(joaat("BG_RandomOutfit"), state.randomOutfit)
        setToggle(joaat("BG_AutoRevive"), state.autoRevive)
        setToggle(joaat("BG_GivePri"), state.givePrimary)
        setToggle(joaat("BG_GiveSec"), state.giveSecondary)
        setToggle(joaat("BG_ExpBullets"), state.explosiveBullets)
        setToggle(joaat("ESC_AutoFlip"), escortState.autoFlip)
        setToggle(joaat("BG_MedicRush"), state.medicRush)
        setToggle(joaat("BG_Callouts"), state.callouts)
        setToggle(joaat("ESC_Searchlight"), escortState.searchlight)
        setToggle(joaat("BG_ESPName"), state.espName)
        setToggle(joaat("BG_ESPHealth"), state.espHealth)
        setToggle(joaat("BG_ESPDistance"), state.espDistance)
        setToggle(joaat("BG_ESPTracer"), state.espTracer)
    end)

    -- Apply to active bodyguards
    applySettingsToAll()
    applyBlipColorAll()
end

-- === CONFIG FEATURES ===

FeatureMgr.AddFeature(joaat("BG_ConfigName"), "Config Name",
    eFeatureType.InputText, "Enter a name for your config preset", function(f)
    state.configName = f:GetStringValue()
end, true)

FeatureMgr.AddFeature(joaat("BG_ConfigSave"), "Save Config",
    eFeatureType.Button, "Save current settings as a preset", function(f)
    local name = state.configName or ""
    name = name:match("^%s*(.-)%s*$") or ""
    if name == "" then toast("Enter a config name first") return end

    -- Sanitize filename
    name = name:gsub("[^%w%-%_ ]", "")
    if name == "" then toast("Invalid config name") return end

    local path = CONFIG_DIR .. name .. ".cfg"
    local content = serializeConfig()
    local ok = pcall(FileMgr.WriteFileContent, path, content, false)
    if ok then
        toast("Saved: " .. name)
        refreshConfigList()
    else
        toast("Failed to save config")
    end
end, true)

FeatureMgr.AddFeature(joaat("BG_ConfigList"), "Load Preset",
    eFeatureType.Combo, "Select a saved config to load", function(f)
    -- Just selection, actual load on button press
end, true)

FeatureMgr.AddFeature(joaat("BG_ConfigLoad"), "Load Config",
    eFeatureType.Button, "Load selected preset", function(f)
    local listF = FeatureMgr.GetFeature(joaat("BG_ConfigList"))
    if not listF then toast("Error") return end

    local idx = listF:GetListIndex()
    local name = savedConfigs[idx + 1]
    if not name then toast("No config selected") return end

    local path = CONFIG_DIR .. name .. ".cfg"
    local ok, content = pcall(FileMgr.ReadFileContent, path)
    if not ok or not content or content == "" then
        toast("Failed to read: " .. name)
        return
    end

    local cfg = deserializeConfig(content)
    if not cfg.version then
        toast("Invalid config file")
        return
    end

    applyConfig(cfg)
    toast("Loaded: " .. name)
end, true)

FeatureMgr.AddFeature(joaat("BG_ConfigDelete"), "Delete Config",
    eFeatureType.Button, "Delete selected preset", function(f)
    local listF = FeatureMgr.GetFeature(joaat("BG_ConfigList"))
    if not listF then return end

    local idx = listF:GetListIndex()
    local name = savedConfigs[idx + 1]
    if not name then toast("No config selected") return end

    local path = CONFIG_DIR .. name .. ".cfg"
    pcall(FileMgr.DeleteFile, path)
    toast("Deleted: " .. name)
    refreshConfigList()
end, true)

FeatureMgr.AddFeature(joaat("BG_ConfigSpawn"), "Spawn Saved Config",
    eFeatureType.Button, "Load preset and immediately spawn bodyguards", function(f)
    local listF = FeatureMgr.GetFeature(joaat("BG_ConfigList"))
    if not listF then toast("Error") return end

    local idx = listF:GetListIndex()
    local name = savedConfigs[idx + 1]
    if not name then toast("No config selected") return end

    local path = CONFIG_DIR .. name .. ".cfg"
    local ok, content = pcall(FileMgr.ReadFileContent, path)
    if not ok or not content or content == "" then
        toast("Failed to read: " .. name)
        return
    end

    local cfg = deserializeConfig(content)
    if not cfg.version then
        toast("Invalid config file")
        return
    end

    -- Apply all settings + update GUI
    applyConfig(cfg)

    -- Resolve model from saved config
    local catIdx = state.catIdx + 1
    local modIdx = state.modelIdx + 1
    local cat = MODELS[catIdx]
    local modelInfo = cat and cat[modIdx]

    -- Fallback: if saved modelHash exists in config, use it directly
    local modelHash = nil
    local modelName = nil
    local isAnimal = false

    if modelInfo then
        modelHash = joaat(modelInfo.h)
        modelName = modelInfo.n
        isAnimal = (catIdx == 1)
    elseif cfg.modelHash and cfg.modelName then
        -- Use saved model info from config (in case category/model indices shifted)
        modelHash = joaat(cfg.modelHash)
        modelName = cfg.modelName
        isAnimal = (cfg.isAnimal == "true")
    end

    if not modelHash or not modelName then
        toast("Could not resolve model from config")
        return
    end

    toast("Spawning " .. name .. "...")
    spawnBodyguards(modelHash, modelName, isAnimal)
end, true)

-- ═══════════════════════════════════════════════════════════════
-- FEATURE INIT (limits, lists, defaults)
-- ═══════════════════════════════════════════════════════════════

Script.QueueJob(function()
    Script.Yield(100)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_PedCount"))
        if f then f:SetLimitValues(1, MAX_BODYGUARDS); f:SetValue(1) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Category"))
        if f then f:SetList(CATEGORY_NAMES); f:SetListIndex(0) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Model"))
        if f then f:SetList(MODEL_NAMES[1]); f:SetListIndex(0) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_PriCat"))
        if f then f:SetList(WCAT_NAMES); f:SetListIndex(3) end        -- Assault Rifles
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Pri"))
        if f then f:SetList(WNAMES[4]); f:SetListIndex(1) end         -- Carbine Rifle
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_SecCat"))
        if f then f:SetList(SEC_CAT_NAMES); f:SetListIndex(0) end     -- Pistols
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Sec"))
        if f then f:SetList(WNAMES[1]); f:SetListIndex(2) end         -- AP Pistol
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_GivePri"))
        if f then pcall(function() f:SetBoolValue(true) end) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_GiveSec"))
        if f then pcall(function() f:SetBoolValue(true) end) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Formation"))
        if f then f:SetList(FORMATION_NAMES); f:SetListIndex(0) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Behaviour"))
        if f then f:SetList(BEHAVIOUR_NAMES); f:SetListIndex(0) end
    end)

    -- v4.0 Advanced Tuning widgets
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Accuracy"))
        if f then f:SetLimitValues(0, 100); f:SetValue(100) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Health"))
        if f then f:SetLimitValues(200, 10000); f:SetValue(2000) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Armor"))
        if f then f:SetLimitValues(0, 1000); f:SetValue(300) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_Spacing"))
        if f then f:SetLimitValues(1, 10); f:SetValue(2) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_ReviveDelay"))
        if f then f:SetLimitValues(3, 30); f:SetValue(8) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_BlipColor"))
        if f then f:SetList(BLIP_COLOR_NAMES); f:SetListIndex(0) end
    end)

    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("BG_ExpType"))
        if f then f:SetList(EXPLOSION_TYPE_NAMES); f:SetListIndex(0) end
    end)

    -- Load saved config list
    refreshConfigList()

    log("Feature init complete")
end)

-- ═══════════════════════════════════════════════════════════════
-- ESCORT SYSTEM (v4.0 rework)
-- ═══════════════════════════════════════════════════════════════
-- What changed vs v3.4:
--   * Drivers escort your VEHICLE entity when you're driving, with a
--     convoy slot mode (lead / rear / flank) from the Convoy Style combo.
--   * On foot: escorts drive to you, then brake and HOLD within 35m
--     (TASK_VEHICLE_TEMP_ACTION) instead of circling forever.
--   * Re-tasking throttled to 4s / on transitions — v3.4 re-issued
--     TASK_VEHICLE_ESCORT every 500ms, causing the stuttery driving.
--   * Dead driver: a surviving crew member is promoted to the wheel.
--     Full crew wipe: the vehicle cleans itself up.
--   * Spawns behind your heading, facing your direction.

local ESCORT_VEHICLES = {
    {n = "Turreted Limo",  h = joaat("limo2")},
    {n = "Insurgent",      h = joaat("insurgent2")},
    {n = "Nightshark",     h = joaat("nightshark")},
}
local ESCORT_VEH_NAMES = {}
for _, v in ipairs(ESCORT_VEHICLES) do ESCORT_VEH_NAMES[#ESCORT_VEH_NAMES + 1] = v.n end

local AIR_VEHICLES = {
    {n = "Valkyrie",     h = joaat("valkyrie")},
    {n = "Buzzard",      h = joaat("buzzard2")},
    {n = "Savage",       h = joaat("savage")},
    {n = "Annihilator",  h = joaat("annihilator")},
    {n = "Hunter",       h = joaat("hunter")},
    {n = "Akula",        h = joaat("akula")},
}
local AIR_VEH_NAMES = {}
for _, v in ipairs(AIR_VEHICLES) do AIR_VEH_NAMES[#AIR_VEH_NAMES + 1] = v.n end

local DRIVE_AGGRESSIVE = 786468 -- rushed + avoid peds + avoid objects + take shortest path

-- Escort mode + follow distance for a convoy slot under the current style
-- (TASK_VEHICLE_ESCORT modes: -1 closest, 0 rear, 1 lead, 2 left, 3 right)
local function convoyModeFor(slot)
    local style = CONVOY_STYLES[escortState.styleIdx + 1]
    if not style or not style.modes then return -1, 6.0 end
    local m = style.modes[((slot - 1) % #style.modes) + 1]
    local d = 6.0
    if m == 1 then d = 9.0 elseif m == 2 or m == 3 then d = 5.0 end
    return m, d
end

-- Spawn point behind the player's heading, facing the player's direction
local function getSpawnBehind(dist)
    local px, py, pz = myCoords()
    if not px then return nil end
    local fx, fy = playerForward()
    local heading = math.deg(math.atan(-fx, fy))
    return px - fx * dist, py - fy * dist, pz, heading
end

local function spawnEscortPed(x, y, z, heading)
    local pedHash = joaat("s_m_y_blackops_01")
    requestModel(pedHash)
    local ped = GTA.CreatePed(pedHash, 26, x, y, z, heading, true, false)
    if not ped or ped == 0 then return nil end
    Natives.InvokeVoid(N.SET_MODEL_NO_LONGER, pedHash)

    -- Combat setup
    Natives.InvokeVoid(N.SET_PED_COMBAT_ABILITY, ped, 2)
    Natives.InvokeVoid(N.SET_PED_COMBAT_RANGE, ped, 2)
    Natives.InvokeVoid(N.SET_PED_ACCURACY, ped, 100)
    Natives.InvokeVoid(N.SET_PED_FIRING_PATTERN, ped, FIRING_FULL_AUTO)
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 1, true)   -- CanUseVehicles
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 2, true)   -- CanDoDrivebys
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 3, false)  -- CanLeaveVehicle = no
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 5, true)   -- AlwaysFight
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 20, true)  -- CanTauntInVehicle
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 46, true)  -- CanFightArmedOnFoot
    Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, ped, 58, true)  -- DisableFlee

    -- Seat retention: turret gunners stay in when the vehicle flips (v4.0)
    Natives.InvokeVoid(N.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE, ped, 1)
    Natives.InvokeVoid(N.SET_PED_CONFIG_FLAG, ped, 32, false)

    -- Friendly to player
    if bgGroupHash then
        Natives.InvokeVoid(N.SET_PED_RELATIONSHIP_GROUP_HASH, ped, bgGroupHash)
    end
    Natives.InvokeVoid(N.SET_PED_CAN_BE_TARGETTED, ped, false)
    Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, ped, escortState.godMode)

    -- Weapon: always give driveby-capable weapons for escort peds
    local AP_PISTOL = 0x22D8FE39
    local SMG = 0x2BE6766B
    Natives.InvokeVoid(N.GIVE_WEAPON_TO_PED, ped, AP_PISTOL, 9999, false, true)
    Natives.InvokeVoid(N.GIVE_WEAPON_TO_PED, ped, SMG, 9999, false, false)
    Natives.InvokeVoid(N.SET_CURRENT_PED_WEAPON, ped, SMG, true)
    Natives.InvokeVoid(N.SET_PED_INFINITE_AMMO, ped, true, AP_PISTOL)
    Natives.InvokeVoid(N.SET_PED_INFINITE_AMMO, ped, true, SMG)
    Natives.InvokeVoid(N.SET_PED_INFINITE_AMMO_CLIP, ped, true)
    Natives.InvokeVoid(N.SET_PED_FIRING_PATTERN, ped, FIRING_FULL_AUTO)

    return ped
end

local function spawnGroundEscort()
    initRelationships()
    Script.QueueJob(function()
        Script.Yield(200)
        local vehInfo = ESCORT_VEHICLES[escortState.groundVehIdx + 1]
        if not vehInfo then toast("Invalid vehicle") return end

        if not requestModel(vehInfo.h) then toast("Vehicle model failed to load") return end

        local spawned = 0
        for c = 1, escortState.groundCount do
            local sx, sy, sz, heading = getSpawnBehind(10.0 + (c - 1) * 9.0)
            if not sx then break end

            local veh = GTA.SpawnVehicle(vehInfo.h, sx, sy, sz, heading, true, false)
            if not veh or veh == 0 then toast("Vehicle spawn failed") break end

            -- Armor + tint
            Natives.InvokeVoid(N.SET_VEHICLE_MOD_KIT, veh, 0)
            Natives.InvokeVoid(N.SET_VEHICLE_WINDOW_TINT, veh, 1) -- dark tint
            Natives.InvokeVoid(N.SET_VEHICLE_ENGINE_ON, veh, true, true, false)
            Natives.InvokeVoid(N.SET_VEHICLE_STRONG, veh, true)
            Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, veh, escortState.godMode)

            -- Driver (drive-only, no combat)
            local driver = spawnEscortPed(sx, sy, sz, heading)
            if not driver then deleteEntity(veh) break end
            Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, driver, veh, -1)
            Natives.InvokeVoid(N.SET_DRIVER_ABILITY, driver, 1.0)
            Natives.InvokeVoid(N.SET_DRIVER_AGGRESSIVENESS, driver, 1.0)
            Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, driver, true)
            Natives.InvokeVoid(N.REMOVE_ALL_PED_WEAPONS, driver, true)
            Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, driver, 5, false)  -- AlwaysFight OFF for driver
            Natives.InvokeVoid(N.SET_PED_KEEP_TASK, driver, true)

            -- Passengers (fill remaining seats)
            local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, veh)
            local passengers = {}
            for seat = 0, maxSeats - 1 do
                local psg = spawnEscortPed(sx, sy, sz, heading)
                if psg then
                    Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, psg, veh, seat)
                    passengers[#passengers + 1] = psg
                end
            end

            -- Blip
            local blip = Natives.InvokeInt(N.ADD_BLIP_FOR_ENTITY, veh)
            if blip and blip ~= 0 then
                Natives.InvokeVoid(N.SET_BLIP_COLOUR, blip, 38) -- dark blue
                Natives.InvokeVoid(N.SET_BLIP_SCALE, blip, 0.8)
            end

            escorts[#escorts + 1] = {
                veh = veh, driver = driver, passengers = passengers,
                blip = blip, type = "ground",
                slot = c, nextTask = 0, stopped = false, lastTarget = nil,
            }
            spawned = spawned + 1
            Script.Yield(0)
        end
        Natives.InvokeVoid(N.SET_MODEL_NO_LONGER, vehInfo.h)
        if spawned > 0 then
            toast("Escort convoy: " .. spawned .. "x " .. vehInfo.n)
        end
    end)
end

local function spawnAirSupport()
    initRelationships()
    Script.QueueJob(function()
        Script.Yield(200)
        local airInfo = AIR_VEHICLES[escortState.airVehIdx + 1]
        if not airInfo then toast("Invalid aircraft") return end

        if not requestModel(airInfo.h) then toast("Aircraft model failed to load") return end

        local spawned = 0
        for c = 1, escortState.airCount do
            local sx, sy, sz, heading = getSpawnBehind(15.0 + (c - 1) * 14.0)
            if not sx then break end

            local veh = GTA.SpawnVehicle(airInfo.h, sx, sy, sz + 45.0, heading, true, false)
            if not veh or veh == 0 then toast("Aircraft spawn failed") break end

            Natives.InvokeVoid(N.SET_VEHICLE_ENGINE_ON, veh, true, true, false)
            Natives.InvokeVoid(N.SET_HELI_BLADES_FULL_SPEED, veh)
            Natives.InvokeVoid(N.SET_VEHICLE_STRONG, veh, true)
            Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, veh, escortState.godMode)

            -- Pilot (fly-only, no combat — same as ground driver)
            local pilot = spawnEscortPed(sx, sy, sz + 45.0, heading)
            if not pilot then deleteEntity(veh) break end
            Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, pilot, veh, -1)
            Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, pilot, true)
            Natives.InvokeVoid(N.REMOVE_ALL_PED_WEAPONS, pilot, true)
            Natives.InvokeVoid(N.SET_PED_COMBAT_ATTRIBUTES, pilot, 5, false)
            Natives.InvokeVoid(N.SET_PED_KEEP_TASK, pilot, true)

            -- Gunner(s)
            local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, veh)
            local passengers = {}
            for seat = 0, math.min(maxSeats - 1, 2) do
                local gunner = spawnEscortPed(sx, sy, sz + 45.0, heading)
                if gunner then
                    Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, gunner, veh, seat)
                    passengers[#passengers + 1] = gunner
                end
            end

            local blip = Natives.InvokeInt(N.ADD_BLIP_FOR_ENTITY, veh)
            if blip and blip ~= 0 then
                Natives.InvokeVoid(N.SET_BLIP_COLOUR, blip, 3) -- blue
                Natives.InvokeVoid(N.SET_BLIP_SCALE, blip, 0.8)
            end

            escorts[#escorts + 1] = {
                veh = veh, driver = pilot, passengers = passengers,
                blip = blip, type = "air",
                slot = c, nextTask = 0, stopped = false, lastTarget = nil,
            }
            spawned = spawned + 1
            Script.Yield(0)
        end
        Natives.InvokeVoid(N.SET_MODEL_NO_LONGER, airInfo.h)
        if spawned > 0 then
            toast("Air support: " .. spawned .. "x " .. airInfo.n)
        end
    end)
end

local function repairAllEscorts()
    local n = 0
    for _, esc in ipairs(escorts) do
        if entityExists(esc.veh) then
            pcall(Natives.InvokeVoid, N.SET_VEHICLE_FIXED, esc.veh)
            pcall(Natives.InvokeVoid, N.SET_VEHICLE_ENGINE_ON, esc.veh, true, true, false)
            n = n + 1
        end
    end
    toast("Repaired " .. n .. " escort vehicles")
end

-- Deploy air crew down the ropes — staged so the drop actually works:
--   1) freeze this bird's escort AI (no more orbiting mid-deploy)
--   2) descend to ~16m AGL (real ground probe, your Z as fallback) + hold
--   3) staggered rappel with drop protection so nobody dies to gravity
--   4) wait for boots down
--   5) convert troops to UNLISTED bodyguards: your group, your lock-on
--      chain, full friendly-fire protection — but never in the roster
--      or the 7-guard cap
--   6) resume patrol at the configured altitude
local function rappelGunners()
    local any = false
    for _, esc in ipairs(escorts) do
        if esc.type == "air" and entityExists(esc.veh) and #esc.passengers > 0 then
            any = true
            break
        end
    end
    if not any then toast("No air crew to deploy") return end

    Script.QueueJob(function()
        local groundPtr = Memory.Alloc(4)
        local total = 0

        for _, esc in ipairs(escorts) do
            if esc.type == "air" and entityExists(esc.veh) and #esc.passengers > 0 then
                pcall(function()
                    esc.deploying = true

                    local hx, hy, hz = Natives.InvokeV3(N.GET_ENTITY_COORDS, esc.veh, true)
                    if not hx then return end

                    -- Ground under the heli (fallback: your Z)
                    local groundZ = nil
                    pcall(function()
                        if Natives.InvokeBool(N.GET_GROUND_Z_FOR_3D_COORD, hx, hy, hz, groundPtr, false, false) then
                            groundZ = Memory.ReadFloat(groundPtr)
                        end
                    end)
                    if not groundZ then
                        local _, _, pz2 = myCoords()
                        groundZ = pz2 or (hz - 40.0)
                    end
                    local hoverZ = groundZ + 16.0

                    -- Bring her down: go-to-and-hold just above the deck
                    Natives.InvokeVoid(N.CLEAR_PED_TASKS, esc.driver)
                    Natives.InvokeVoid(N.TASK_HELI_MISSION, esc.driver, esc.veh, 0, 0,
                        hx, hy, hoverZ, 4, 12.0, 5.0, -1.0, 20, 10, 25.0, 0)

                    for _ = 1, 50 do  -- max ~10s descent
                        local _, _, cz = Natives.InvokeV3(N.GET_ENTITY_COORDS, esc.veh, true)
                        if cz and cz <= hoverZ + 3.0 then break end
                        Script.Yield(200)
                    end

                    -- Ropes out, staggered, with drop protection
                    local dropped = {}
                    for pi = #esc.passengers, 1, -1 do
                        local p = esc.passengers[pi]
                        table.remove(esc.passengers, pi)  -- off the crew list FIRST
                        if entityExists(p) then
                            pcall(Natives.InvokeVoid, N.SET_ENTITY_INVINCIBLE, p, true)
                            pcall(Natives.InvokeVoid, N.TASK_RAPPEL_FROM_HELI, p, 5.0)
                            dropped[#dropped + 1] = p
                            total = total + 1
                        end
                        Script.Yield(150)
                    end

                    -- Wait for boots on the ground (max ~10s)
                    for _ = 1, 50 do
                        local down = 0
                        for _, p in ipairs(dropped) do
                            local landed = not entityExists(p)
                            if not landed then
                                local _, _, tz = Natives.InvokeV3(N.GET_ENTITY_COORDS, p, true)
                                if tz and tz <= groundZ + 2.5 then landed = true end
                            end
                            if landed then down = down + 1 end
                        end
                        if down >= #dropped then break end
                        Script.Yield(200)
                    end

                    -- Convert to unlisted bodyguards
                    local playerGroup = Natives.InvokeInt(N.GET_PLAYER_GROUP, myId())
                    for _, p in ipairs(dropped) do
                        if entityExists(p) then
                            pcall(Natives.InvokeVoid, N.SET_ENTITY_INVINCIBLE, p, escortState.godMode)
                            pcall(Natives.InvokeVoid, N.CLEAR_PED_TASKS, p)
                            if playerGroup and playerGroup ~= 0 then
                                pcall(Natives.InvokeVoid, N.SET_PED_AS_GROUP_MEMBER, p, playerGroup)
                                pcall(Natives.InvokeVoid, N.SET_PED_NEVER_LEAVES_GROUP, p, true)
                            end
                            pcall(applyFriendlyProtection, p)
                            shadowGuards[#shadowGuards + 1] = {handle = p}
                        end
                    end

                    -- Replenish the bay/turret seats with fresh crew so
                    -- the bird keeps fighting after the drop
                    local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, esc.veh)
                    local rx, ry, rz = Natives.InvokeV3(N.GET_ENTITY_COORDS, esc.veh, true)
                    if rx and maxSeats then
                        for seat = 0, math.min(maxSeats - 1, 2) do
                            if Natives.InvokeBool(N.IS_VEHICLE_SEAT_FREE, esc.veh, seat) then
                                local fresh = spawnEscortPed(rx, ry, rz, 0)
                                if fresh then
                                    Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, fresh, esc.veh, seat)
                                    esc.passengers[#esc.passengers + 1] = fresh
                                end
                            end
                            Script.Yield(0)
                        end
                    end
                end)
                -- Never leave a bird frozen; resume patrol altitude
                esc.deploying = false
                esc.nextTask = 0
            end
        end

        pcall(Memory.Free, groundPtr)
        toast(total > 0 and ("Deployed " .. total .. " troops — bird re-crewed") or "Deployment failed")
    end)
end

local function deleteAllEscorts()
    local count = #escorts
    for i = #escorts, 1, -1 do
        local esc = escorts[i]
        removeBlipSafe(esc.blip)
        for _, p in ipairs(esc.passengers) do deleteEntity(p) end
        deleteEntity(esc.driver)
        deleteEntity(esc.veh)
        table.remove(escorts, i)
    end
    if count > 0 then toast("Deleted " .. count .. " escort vehicles") end
end

-- Escort features
FeatureMgr.AddFeature(joaat("ESC_GroundVeh"), "Escort Vehicle",
    eFeatureType.Combo, "Select escort vehicle type", function(f)
    escortState.groundVehIdx = f:GetListIndex()
end, true)

FeatureMgr.AddFeature(joaat("ESC_GroundCount"), "Convoy Size",
    eFeatureType.SliderInt, "Number of escort vehicles (1-3)", function(f)
    escortState.groundCount = f:GetIntValue()
end, true)

FeatureMgr.AddFeature(joaat("ESC_ConvoyStyle"), "Convoy Style",
    eFeatureType.Combo, "Escort positioning around your vehicle", function(f)
    escortState.styleIdx = f:GetListIndex()
    -- Force re-task on next tick so the new style applies immediately
    for _, esc in ipairs(escorts) do esc.nextTask = 0 end
end, true)

FeatureMgr.AddFeature(joaat("ESC_SpawnGround"), "Spawn Escort",
    eFeatureType.Button, "Spawn armored escort vehicle(s)", function(f)
    spawnGroundEscort()
end, true)

FeatureMgr.AddFeature(joaat("ESC_AirVeh"), "Aircraft Type",
    eFeatureType.Combo, "Select air support aircraft", function(f)
    escortState.airVehIdx = f:GetListIndex()
end, true)

FeatureMgr.AddFeature(joaat("ESC_AirCount"), "Air Support Count",
    eFeatureType.SliderInt, "Number of aircraft (1-3)", function(f)
    escortState.airCount = f:GetIntValue()
end, true)

FeatureMgr.AddFeature(joaat("ESC_AirAlt"), "Air Altitude",
    eFeatureType.SliderInt, "Patrol altitude for air support", function(f)
    escortState.airAlt = f:GetIntValue()
    for _, esc in ipairs(escorts) do esc.nextTask = 0 end   -- apply now
end, true)

FeatureMgr.AddFeature(joaat("ESC_Searchlight"), "Searchlight",
    eFeatureType.Toggle, "Air support searchlight (helis that carry one)", function(f)
    escortState.searchlight = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("ESC_Rappel"), "Rappel Gunners",
    eFeatureType.Button, "Descend and rope the crew down — they join your squad on the ground", function(f)
    rappelGunners()
end, true)

FeatureMgr.AddFeature(joaat("ESC_SpawnAir"), "Spawn Air Support",
    eFeatureType.Button, "Spawn escort helicopter(s)", function(f)
    spawnAirSupport()
end, true)

FeatureMgr.AddFeature(joaat("ESC_RepairAll"), "Repair All Escorts",
    eFeatureType.Button, "Fix body + engine on all escort vehicles", function(f)
    repairAllEscorts()
end, true)

FeatureMgr.AddFeature(joaat("ESC_AutoFlip"), "Auto-Flip Escorts",
    eFeatureType.Toggle, "Automatically right escort vehicles stuck on their roof", function(f)
    escortState.autoFlip = f:IsToggled()
end, true)

FeatureMgr.AddFeature(joaat("ESC_DeleteAll"), "Delete All Escorts",
    eFeatureType.Button, "Remove all escort vehicles", function(f)
    deleteAllEscorts()
end, true)

FeatureMgr.AddFeature(joaat("ESC_GodMode"), "Escort God Mode",
    eFeatureType.Toggle, "Make escort vehicles and peds invincible", function(f)
    escortState.godMode = f:IsToggled()
    for _, esc in ipairs(escorts) do
        if entityExists(esc.veh) then
            Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, esc.veh, escortState.godMode)
        end
        if entityExists(esc.driver) then
            Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, esc.driver, escortState.godMode)
        end
        for _, p in ipairs(esc.passengers) do
            if entityExists(p) then
                Natives.InvokeVoid(N.SET_ENTITY_INVINCIBLE, p, escortState.godMode)
            end
        end
    end
end, true)

FeatureMgr.AddFeature(joaat("BG_DeleteEverything"), "Delete Everything",
    eFeatureType.Button, "Delete all bodyguards + escorts, reset all toggles", function(f)
    -- Delete all entities
    deleteAll()
    deleteAllEscorts()
    deleteAttackers()
    sicTarget = nil
    -- Reset runtime toggles (tuning preferences are kept)
    state.godMode = false
    state.invisible = false
    state.localVisible = false
    state.autoTeleport = false
    state.espName = false
    state.espHealth = false
    state.espDistance = false
    state.espTracer = false
    escortState.godMode = false
    lastPlayerVeh = 0
    -- Reset UI toggles
    pcall(function()
        local toggles = {
            "BG_GodMode", "BG_Invisible", "BG_LocalVisible",
            "BG_AutoTeleport",
            "BG_ESPName", "BG_ESPHealth", "BG_ESPDistance", "BG_ESPTracer",
            "ESC_GodMode",
        }
        for _, name in ipairs(toggles) do
            local ft = FeatureMgr.GetFeature(joaat(name))
            if ft then pcall(function() ft:SetBoolValue(false) end) end
        end
    end)
    toast("Everything deleted & reset")
end, true)

-- Init escort combos
Script.QueueJob(function()
    Script.Yield(300)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_GroundVeh"))
        if f then f:SetList(ESCORT_VEH_NAMES); f:SetListIndex(0) end
    end)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_GroundCount"))
        if f then f:SetLimitValues(1, 3); f:SetValue(1) end
    end)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_ConvoyStyle"))
        if f then f:SetList(CONVOY_STYLE_NAMES); f:SetListIndex(0) end
    end)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_AirVeh"))
        if f then f:SetList(AIR_VEH_NAMES); f:SetListIndex(0) end
    end)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_AirCount"))
        if f then f:SetLimitValues(1, 3); f:SetValue(1) end
    end)
    pcall(function()
        local f = FeatureMgr.GetFeature(joaat("ESC_AirAlt"))
        if f then f:SetLimitValues(20, 120); f:SetValue(40) end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
-- ESCORT TICK (500ms): movement + driver promotion + crew combat
-- ═══════════════════════════════════════════════════════════════

Script.RegisterLooped(function()
    if isShuttingDown or #escorts == 0 then Script.Yield(500) return end

    local t = nowMs()
    local player = myPed()
    local px, py, pz = myCoords()

    -- Player vehicle (0 = on foot)
    local playerVeh = 0
    pcall(function()
        if Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, player, false) then
            playerVeh = Natives.InvokeInt(N.GET_VEHICLE_PED_IS_IN, player, false)
        end
    end)

    -- Detect if player is in combat (shooting or being shot at)
    local playerInCombat = false
    pcall(function()
        playerInCombat = Natives.InvokeBool(N.IS_PED_IN_COMBAT, player, 0)
            or Natives.InvokeBool(N.IS_PED_SHOOTING, player)
    end)

    -- Player's aim target for crew assist
    local escortAimTarget = nil
    pcall(function()
        if Natives.InvokeBool(N.IS_PLAYER_FREE_AIMING, myId()) then
            Memory.WriteInt(aimEntPtr, 0)
            if Natives.InvokeBool(N.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT, myId(), aimEntPtr) then
                local ent = Memory.ReadInt(aimEntPtr)
                if ent and ent ~= 0 then escortAimTarget = ent end
            end
        end
    end)

    for i = #escorts, 1, -1 do
        local esc = escorts[i]
        local removeMe = false
        pcall(function()
            -- Vehicle destroyed → full cleanup
            if not entityExists(esc.veh) then
                removeBlipSafe(esc.blip)
                for _, p in ipairs(esc.passengers) do deleteEntity(p) end
                deleteEntity(esc.driver)
                removeMe = true
                return
            end

            -- Driver down → promote a surviving crew member to the wheel
            local driverGone = not entityExists(esc.driver)
            if not driverGone then
                local ok, d = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, esc.driver, true)
                driverGone = ok and d
            end
            if driverGone then
                local promoted = nil
                for pi = #esc.passengers, 1, -1 do
                    local p = esc.passengers[pi]
                    if entityExists(p) then
                        local ok, d = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, p, true)
                        if not (ok and d) then
                            promoted = p
                            table.remove(esc.passengers, pi)
                            break
                        end
                    end
                end
                if promoted then
                    deleteEntity(esc.driver)
                    Natives.InvokeVoid(N.CLEAR_PED_TASKS_IMMEDIATELY, promoted)
                    Natives.InvokeVoid(N.SET_PED_INTO_VEHICLE, promoted, esc.veh, -1)
                    Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, promoted, true)
                    Natives.InvokeVoid(N.SET_DRIVER_ABILITY, promoted, 1.0)
                    Natives.InvokeVoid(N.SET_DRIVER_AGGRESSIVENESS, promoted, 1.0)
                    Natives.InvokeVoid(N.SET_PED_KEEP_TASK, promoted, true)
                    esc.driver = promoted
                    esc.nextTask = 0
                    esc.stopped = false
                    esc.lastTarget = nil
                    toast("Escort driver down — crew took the wheel")
                else
                    -- Whole crew dead: clean up the derelict
                    removeBlipSafe(esc.blip)
                    for _, p in ipairs(esc.passengers) do deleteEntity(p) end
                    deleteEntity(esc.driver)
                    deleteEntity(esc.veh)
                    removeMe = true
                    toast("Escort lost")
                    return
                end
            end

            -- Auto-flip: right the vehicle if it's stuck on its roof
            if escortState.autoFlip then
                local flipped = false
                pcall(function()
                    flipped = Natives.InvokeBool(N.IS_VEHICLE_STUCK_ON_ROOF, esc.veh)
                end)
                if flipped then
                    pcall(Natives.InvokeVoid, N.SET_VEHICLE_ON_GROUND_PROPERLY, esc.veh, 5.0)
                    esc.nextTask = 0   -- re-task immediately after righting
                end
            end

            -- ============ MOVEMENT ============
            esc.nextTask = esc.nextTask or 0
            if esc.type == "ground" then
                if playerVeh ~= 0 then
                    -- Player driving: escort the player's VEHICLE with a convoy slot
                    if esc.lastTarget ~= playerVeh or esc.stopped or t >= esc.nextTask then
                        local mode, dist = convoyModeFor(esc.slot or 1)
                        if esc.stopped then
                            Natives.InvokeVoid(N.CLEAR_PED_TASKS, esc.driver)
                        end
                        Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, esc.driver, true)
                        Natives.InvokeVoid(N.TASK_VEHICLE_ESCORT, esc.driver, esc.veh,
                            playerVeh, mode, 200.0, DRIVE_AGGRESSIVE, dist, 0, 12.0)
                        esc.lastTarget = playerVeh
                        esc.stopped = false
                        esc.nextTask = t + 4000
                    end
                else
                    -- Player on foot: approach, then pull up and hold
                    local d2 = 0.0
                    local vx, vy, vz = Natives.InvokeV3(N.GET_ENTITY_COORDS, esc.veh, true)
                    if vx and px then
                        local ex, ey = vx - px, vy - py
                        d2 = ex * ex + ey * ey
                    end
                    if d2 > 1225.0 then  -- > 35m: drive to the player
                        if esc.lastTarget ~= player or esc.stopped or t >= esc.nextTask then
                            if esc.stopped then
                                Natives.InvokeVoid(N.CLEAR_PED_TASKS, esc.driver)
                            end
                            Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, esc.driver, true)
                            Natives.InvokeVoid(N.TASK_VEHICLE_ESCORT, esc.driver, esc.veh,
                                player, -1, 200.0, DRIVE_AGGRESSIVE, 12.0, 0, 12.0)
                            esc.lastTarget = player
                            esc.stopped = false
                            esc.nextTask = t + 4000
                        end
                    else
                        -- <= 35m: brake and hold position
                        if not esc.stopped then
                            Natives.InvokeVoid(N.CLEAR_PED_TASKS, esc.driver)
                            esc.stopped = true
                            esc.lastTarget = nil
                        end
                        Natives.InvokeVoid(N.TASK_VEHICLE_TEMP_ACTION, esc.driver, esc.veh, 27, 900)
                    end
                end
            else
                -- Air: heli protect at the configured altitude, throttled
                -- (frozen while a deployment is in progress)
                if not esc.deploying and t >= esc.nextTask then
                    Natives.InvokeVoid(N.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, esc.driver, true)
                    Natives.InvokeVoid(N.TASK_VEHICLE_HELI_PROTECT, esc.driver, esc.veh,
                        player, 60.0, 0, 25.0, escortState.airAlt, 0)
                    esc.nextTask = t + 4000
                end
                -- Searchlight (helis that carry one; no-op on the rest)
                pcall(Natives.InvokeVoid, N.SET_VEHICLE_SEARCHLIGHT, esc.veh, escortState.searchlight, true)
            end

            -- ============ CREW COMBAT ============
            -- Gunners/passengers engage the player's aim target first,
            -- otherwise sweep for hated targets (air only joins when the
            -- player is actually in combat — same rule as v3.4)
            local crewRange = (esc.type == "air") and 200.0 or 100.0
            for _, crew in ipairs(esc.passengers) do
                if entityExists(crew) then
                    local busy = false
                    pcall(function()
                        busy = Natives.InvokeBool(N.IS_PED_IN_COMBAT, crew, 0)
                    end)
                    if escortAimTarget and not busy then
                        Natives.InvokeVoid(N.REGISTER_TARGET, crew, escortAimTarget)
                        Natives.InvokeVoid(N.TASK_COMBAT_PED, crew, escortAimTarget, 0, 16)
                    elseif not busy and (playerInCombat or esc.type == "ground") then
                        Natives.InvokeVoid(N.REGISTER_HATED_TARGETS_AROUND_PED, crew, crewRange)
                        Natives.InvokeVoid(N.TASK_COMBAT_HATED_TARGETS, crew, crewRange, 0)
                    end
                end
            end
        end)
        if removeMe then table.remove(escorts, i) end
    end

    Script.Yield(500)
end)

-- ═══════════════════════════════════════════════════════════════
-- PLAYER TAB (player-list features)
-- ═══════════════════════════════════════════════════════════════

FeatureMgr.AddPlayerFeature(joaat("BGP_Sic"), "Sic Bodyguards",
    eFeatureType.Button, "Send your bodyguards after this player", function(f)
    sicBodyguards(Utils.GetSelectedPlayer())
end, true)

FeatureMgr.AddPlayerFeature(joaat("BGP_CallOff"), "Call Off",
    eFeatureType.Button, "Recall your bodyguards to your side", function(f)
    callOffBodyguards()
end, true)

FeatureMgr.AddPlayerFeature(joaat("BGP_Squad"), "Spawn Attack Squad",
    eFeatureType.Button, "Drop a hostile blackops squad on this player", function(f)
    spawnAttackSquad(Utils.GetSelectedPlayer())
end, true)

FeatureMgr.AddPlayerFeature(joaat("BGP_DelAtk"), "Delete Attackers",
    eFeatureType.Button, "Remove all spawned attackers", function(f)
    deleteAttackers()
end, true)

ClickGUI.AddPlayerTab(SCRIPT_NAME, function()
    local pid = Utils.GetSelectedPlayer()
    if ClickGUI.BeginCustomChildWindow("Sic 'Em") then
        ClickGUI.RenderFeature(joaat("BGP_Sic"), pid)
        ClickGUI.RenderFeature(joaat("BGP_CallOff"), pid)
        ClickGUI.EndCustomChildWindow()
    end
    if ClickGUI.BeginCustomChildWindow("Attack Squad") then
        ClickGUI.RenderFeature(joaat("BGP_Squad"), pid)
        ClickGUI.RenderFeature(joaat("BGP_DelAtk"), pid)
        ImGui.Separator()
        ImGui.Text("Active attackers: " .. #attackers .. (sicTarget and "  |  squad SICCED" or ""))
        ClickGUI.EndCustomChildWindow()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- GUI TAB (status strip + sub-tabs: Bodyguards / Escorts / Settings)
-- ═══════════════════════════════════════════════════════════════

ClickGUI.AddTab(SCRIPT_NAME, function()

    -- Status strip
    pcall(function()
        local pw = state.givePrimary and primaryWeapon() or nil
        local sw = state.giveSecondary and secondaryWeapon() or nil
        local wName = (pw and pw.n) or (sw and sw.n) or "unarmed"
        ImGui.Text(string.format("Squad %d/%d   |   Escorts %d   |   Weapon: %s",
            #bodyguards, MAX_BODYGUARDS, #escorts, wName))
        ImGui.Separator()
    end)

    if ImGui.BeginTabBar("BG_Tabs") then

        -- ===================== TAB 1: BODYGUARDS =====================
        if ImGui.BeginTabItem("Bodyguards") then

            if ClickGUI.BeginCustomChildWindow("Spawning") then
                ClickGUI.RenderFeature(joaat("BG_PedCount"))
                ClickGUI.RenderFeature(joaat("BG_Category"))
                ClickGUI.RenderFeature(joaat("BG_Model"))
                ClickGUI.RenderFeature(joaat("BG_Spawn"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_CustomModel"))
                ClickGUI.RenderFeature(joaat("BG_SpawnCustom"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_SpawnClone"))
                ClickGUI.RenderFeature(joaat("BG_RandomOutfit"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Bodyguard Weapons") then
                ImGui.Text("Primary Weapons")
                ClickGUI.RenderFeature(joaat("BG_PriCat"))
                ClickGUI.RenderFeature(joaat("BG_Pri"))
                ImGui.Separator()
                ImGui.Text("Secondary Weapons")
                ClickGUI.RenderFeature(joaat("BG_SecCat"))
                ClickGUI.RenderFeature(joaat("BG_Sec"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_GivePri"))
                ClickGUI.RenderFeature(joaat("BG_GiveSec"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Explosive Rounds") then
                ClickGUI.RenderFeature(joaat("BG_ExpBullets"))
                ClickGUI.RenderFeature(joaat("BG_ExpType"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Bodyguard Settings") then
                ClickGUI.RenderFeature(joaat("BG_GodMode"))
                ClickGUI.RenderFeature(joaat("BG_NoRagdoll"))
                ClickGUI.RenderFeature(joaat("BG_Invisible"))
                ClickGUI.RenderFeature(joaat("BG_LocalVisible"))
                ClickGUI.RenderFeature(joaat("BG_Formation"))
                ClickGUI.RenderFeature(joaat("BG_Behaviour"))
                ClickGUI.RenderFeature(joaat("BG_Callouts"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Advanced Tuning") then
                ClickGUI.RenderFeature(joaat("BG_Accuracy"))
                ClickGUI.RenderFeature(joaat("BG_Health"))
                ClickGUI.RenderFeature(joaat("BG_Armor"))
                ClickGUI.RenderFeature(joaat("BG_Spacing"))
                ClickGUI.RenderFeature(joaat("BG_BlipColor"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Actions") then
                ClickGUI.RenderFeature(joaat("BG_TeleportAll"))
                ClickGUI.RenderFeature(joaat("BG_HealAll"))
                ClickGUI.RenderFeature(joaat("BG_DeleteAll"))
                ClickGUI.RenderFeature(joaat("BG_WarpVehicle"))
                ClickGUI.RenderFeature(joaat("BG_AutoTeleport"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_AutoRevive"))
                ClickGUI.RenderFeature(joaat("BG_ReviveDelay"))
                ClickGUI.RenderFeature(joaat("BG_MedicRush"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Active (" .. #bodyguards .. "/" .. MAX_BODYGUARDS .. ")") then
                if #bodyguards == 0 then
                    ImGui.Text("No bodyguards spawned")
                else
                    local px, py, pz = nil, nil, nil
                    pcall(function() px, py, pz = myCoords() end)
                    local pendingDelete = nil

                    for i, bg in ipairs(bodyguards) do
                        local line = i .. ". " .. bg.name
                        pcall(function()
                            if not entityExists(bg.handle) then
                                line = line .. "  [GONE]"
                            elseif bg.downedAt and state.autoRevive then
                                local remain = state.reviveDelay - math.floor((nowMs() - bg.downedAt) / 1000)
                                if remain < 0 then remain = 0 end
                                line = line .. "  [DOWN - " .. remain .. "s]"
                            else
                                local hp = Natives.InvokeInt(N.GET_ENTITY_HEALTH, bg.handle) or 0
                                local dtxt = ""
                                if px then
                                    local bx, by, bz = Natives.InvokeV3(N.GET_ENTITY_COORDS, bg.handle, true)
                                    if bx then
                                        local dx, dy, dz2 = bx - px, by - py, bz - pz
                                        dtxt = string.format("  %.0fm", math.sqrt(dx * dx + dy * dy + dz2 * dz2))
                                    end
                                end
                                line = line .. "  [" .. hp .. " HP]" .. dtxt
                            end
                        end)
                        ImGui.Text(line)

                        -- Per-guard actions (degrades to text-only if Button unbound)
                        if HAS_BTN then
                            if HAS_SAMELINE then ImGui.SameLine() end
                            if ImGui.Button("TP##bg" .. i) then
                                pcall(teleportOne, bg, i)
                            end
                            if HAS_SAMELINE then ImGui.SameLine() end
                            if ImGui.Button("Heal##bg" .. i) then
                                -- Heal doubles as instant revive on a downed guard
                                if bg.downedAt and state.autoRevive then
                                    pcall(reviveGuard, bg)
                                else
                                    pcall(healOne, bg)
                                end
                            end
                            if HAS_SAMELINE then ImGui.SameLine() end
                            if ImGui.Button("X##bg" .. i) then
                                pendingDelete = i
                            end
                        end
                    end

                    if pendingDelete then
                        local bg = bodyguards[pendingDelete]
                        table.remove(bodyguards, pendingDelete)
                        Script.QueueJob(function()
                            removeBlipSafe(bg.blip)
                            deleteEntity(bg.handle)
                        end)
                    end
                end
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("ESP") then
                ClickGUI.RenderFeature(joaat("BG_ESPName"))
                ClickGUI.RenderFeature(joaat("BG_ESPHealth"))
                ClickGUI.RenderFeature(joaat("BG_ESPDistance"))
                ClickGUI.RenderFeature(joaat("BG_ESPTracer"))
                ClickGUI.EndCustomChildWindow()
            end

            ImGui.EndTabItem()
        end

        -- ===================== TAB 2: ESCORTS =====================
        if ImGui.BeginTabItem("Escorts") then

            if ClickGUI.BeginCustomChildWindow("Ground Escort") then
                ClickGUI.RenderFeature(joaat("ESC_GroundVeh"))
                ClickGUI.RenderFeature(joaat("ESC_GroundCount"))
                ClickGUI.RenderFeature(joaat("ESC_ConvoyStyle"))
                ClickGUI.RenderFeature(joaat("ESC_SpawnGround"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Air Support") then
                ClickGUI.RenderFeature(joaat("ESC_AirVeh"))
                ClickGUI.RenderFeature(joaat("ESC_AirCount"))
                ClickGUI.RenderFeature(joaat("ESC_AirAlt"))
                ClickGUI.RenderFeature(joaat("ESC_SpawnAir"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("ESC_Searchlight"))
                ClickGUI.RenderFeature(joaat("ESC_Rappel"))
                ImGui.Text("Deployed troops: " .. #shadowGuards)
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Escort Settings") then
                ClickGUI.RenderFeature(joaat("ESC_GodMode"))
                ClickGUI.RenderFeature(joaat("ESC_RepairAll"))
                ClickGUI.RenderFeature(joaat("ESC_AutoFlip"))
                ClickGUI.RenderFeature(joaat("ESC_DeleteAll"))
                ImGui.Separator()
                if #escorts == 0 then
                    ImGui.Text("No escorts active")
                else
                    for i, esc in ipairs(escorts) do
                        local line = i .. ". " .. (esc.type == "air" and "Air" or "Ground")
                        pcall(function()
                            local dOk = entityExists(esc.driver)
                            if dOk then
                                local ok, d = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, esc.driver, true)
                                if ok and d then dOk = false end
                            end
                            local crew = 0
                            for _, p in ipairs(esc.passengers) do
                                if entityExists(p) then crew = crew + 1 end
                            end
                            line = line .. "  |  driver " .. (dOk and "OK" or "DOWN")
                                .. "  |  crew " .. crew
                            if esc.stopped then line = line .. "  |  holding" end
                        end)
                        ImGui.Text(line)
                    end
                end
                ClickGUI.EndCustomChildWindow()
            end

            ImGui.EndTabItem()
        end

        -- ===================== TAB 3: SETTINGS =====================
        if ImGui.BeginTabItem("Settings") then

            if ClickGUI.BeginCustomChildWindow("Master Controls") then
                ClickGUI.RenderFeature(joaat("BG_DeleteEverything"))
                ClickGUI.EndCustomChildWindow()
            end

            if ClickGUI.BeginCustomChildWindow("Config Presets") then
                ClickGUI.RenderFeature(joaat("BG_ConfigName"))
                ClickGUI.RenderFeature(joaat("BG_ConfigSave"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_ConfigList"))
                ClickGUI.RenderFeature(joaat("BG_ConfigLoad"))
                ClickGUI.RenderFeature(joaat("BG_ConfigDelete"))
                ImGui.Separator()
                ClickGUI.RenderFeature(joaat("BG_ConfigSpawn"))
                ClickGUI.EndCustomChildWindow()
            end

            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

-- Loop 1: Cleanup/revive + friendly fire + weapons + vehicle follow +
--         combat assist + auto teleport (100ms)
Script.RegisterLooped(function()
    if isShuttingDown then return end
    cleanupDead()

    -- Drop the sic target if it despawned / left
    if sicTarget and not entityExists(sicTarget) then sicTarget = nil end

    -- Refresh player rel hash every 5s AND re-bond the COMPANION
    -- relationship against it. Field-reported bug ("my bodyguards turn
    -- on me when I shoot someone"): in Online your rel-group hash
    -- changes on ped migration/re-clone, and the bond set at init
    -- points at the OLD hash — guards can then flag you as hostile
    -- the moment combat starts near them.
    local tickMs = nowMs()
    if lastRelRefresh == 0 or tickMs - lastRelRefresh > 5000 then
        lastRelRefresh = tickMs
        playerRelHash = nil
        local pHash = getPlayerRelHash()
        if bgGroupHash and pHash and pHash ~= 0 then
            pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, bgGroupHash, pHash)
            pcall(Natives.InvokeVoid, N.SET_RELATIONSHIP_BETWEEN_GROUPS, 0, pHash, bgGroupHash)
        end
    end

    -- Re-apply friendly fire protection every tick — CRITICAL
    -- Relationship groups can reset on entity migration/clone sync
    for _, bg in ipairs(bodyguards) do
        pcall(function()
            if entityExists(bg.handle) then
                applyFriendlyProtection(bg.handle)
            end
        end)
    end
    for _, sh in ipairs(shadowGuards) do
        pcall(function()
            if entityExists(sh.handle) then
                applyFriendlyProtection(sh.handle)
            end
        end)
    end

    -- Smart weapon management — vehicle-aware (v4.0 two-tier)
    -- On foot: primary. In vehicle: secondary (driveby-capable),
    -- falling back to a driveby-capable primary if no secondary given.
    local pri = state.givePrimary and primaryWeapon() or nil
    local sec = state.giveSecondary and secondaryWeapon() or nil

    if pri or sec then
        for _, bg in ipairs(bodyguards) do
            pcall(function()
                if not entityExists(bg.handle) then return end
                if bg.downedAt then return end   -- skip downed guards

                local inVehicle = Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false)
                local held = Natives.InvokeInt(N.GET_SELECTED_PED_WEAPON, bg.handle)

                if inVehicle then
                    local want = sec
                    if not want and pri and DRIVEBY_OK[pri.h] then want = pri end
                    if want and held ~= want.h then
                        Natives.InvokeVoid(N.GIVE_WEAPON_TO_PED, bg.handle, want.h, 9999, false, false)
                        Natives.InvokeVoid(N.SET_PED_INFINITE_AMMO, bg.handle, true, want.h)
                        Natives.InvokeVoid(N.SET_CURRENT_PED_WEAPON, bg.handle, want.h, true)
                    end
                elseif not bg.isAnimal then
                    -- On foot: STRIP the secondary from inventory so the
                    -- combat AI can never select it, and re-equip primary
                    if sec and (not pri or sec.h ~= pri.h)
                       and Natives.InvokeBool(N.HAS_PED_GOT_WEAPON, bg.handle, sec.h, false) then
                        Natives.InvokeVoid(N.REMOVE_WEAPON_FROM_PED, bg.handle, sec.h)
                    end
                    if pri and held ~= pri.h then
                        Natives.InvokeVoid(N.SET_CURRENT_PED_WEAPON, bg.handle, pri.h, true)
                    end
                end
            end)
        end
    end

    -- ============================================
    -- VEHICLE FOLLOW (runs BEFORE combat so enteringVeh is set first)
    -- ============================================
    if #bodyguards > 0 then
        local player = myPed()
        local playerInVeh = Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, player, false)
        if playerInVeh then
            local veh = Natives.InvokeInt(N.GET_VEHICLE_PED_IS_IN, player, false)
            if veh ~= 0 then
                if veh ~= lastPlayerVeh then
                    -- NEW vehicle — task all bodyguards
                    lastPlayerVeh = veh
                    local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, veh)
                    local nextSeat = 0
                    for _, bg in ipairs(bodyguards) do
                        if entityExists(bg.handle) and not bg.isAnimal
                           and not bg.downedAt
                           and not Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false) then
                            while nextSeat < maxSeats do
                                if Natives.InvokeBool(N.IS_VEHICLE_SEAT_FREE, veh, nextSeat) then
                                    Natives.InvokeVoid(N.CLEAR_PED_TASKS, bg.handle)
                                    Natives.InvokeVoid(N.TASK_ENTER_VEHICLE,
                                        bg.handle, veh, 10000, nextSeat, 2.0, 1, 0)
                                    bg.enteringVeh = true
                                    nextSeat = nextSeat + 1
                                    break
                                end
                                nextSeat = nextSeat + 1
                            end
                        end
                    end
                else
                    -- SAME vehicle — retry for any bodyguard not in car and not entering
                    local maxSeats = Natives.InvokeInt(N.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS, veh)
                    for _, bg in ipairs(bodyguards) do
                        if entityExists(bg.handle) and not bg.isAnimal
                           and not bg.downedAt
                           and not bg.enteringVeh
                           and not Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false) then
                            for seat = 0, maxSeats - 1 do
                                if Natives.InvokeBool(N.IS_VEHICLE_SEAT_FREE, veh, seat) then
                                    Natives.InvokeVoid(N.CLEAR_PED_TASKS, bg.handle)
                                    Natives.InvokeVoid(N.TASK_ENTER_VEHICLE,
                                        bg.handle, veh, 10000, seat, 2.0, 1, 0)
                                    bg.enteringVeh = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        elseif lastPlayerVeh ~= 0 then
            lastPlayerVeh = 0
            for _, bg in ipairs(bodyguards) do
                bg.enteringVeh = false  -- clear stuck flag for everyone
                if entityExists(bg.handle) and not bg.isAnimal and not bg.downedAt
                   and Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false) then
                    Natives.InvokeVoid(N.TASK_LEAVE_VEHICLE, bg.handle,
                        Natives.InvokeInt(N.GET_VEHICLE_PED_IS_IN, bg.handle, false), 0)
                end
            end
        end
    end

    -- ============================================
    -- COMBAT ASSIST — aim target + hated targets
    -- ============================================
    if #bodyguards > 0 then
        pcall(function()
            local aimTarget = nil
            if Natives.InvokeBool(N.IS_PLAYER_FREE_AIMING, myId()) then
                Memory.WriteInt(aimEntPtr, 0)
                if Natives.InvokeBool(N.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT, myId(), aimEntPtr) then
                    local ent = Memory.ReadInt(aimEntPtr)
                    if ent and ent ~= 0 then aimTarget = ent end
                end
            end

            local bIdx = state.behavIdx + 1
            local behav = BEHAVIOURS[bIdx]
            local combatRange = (behav and behav.range > 0) and behav.range or 50.0

            for _, bg in ipairs(bodyguards) do
                if entityExists(bg.handle) and not bg.downedAt then
                    -- Skip if walking to vehicle
                    if bg.enteringVeh then
                        if Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false) then
                            bg.enteringVeh = false
                        end
                    else
                        pcall(Natives.InvokeVoid, N.REGISTER_HATED_TARGETS_AROUND_PED, bg.handle, combatRange)

                        local inCombat = false
                        pcall(function()
                            inCombat = Natives.InvokeBool(N.IS_PED_IN_COMBAT, bg.handle, 0)
                        end)

                        -- Combat callouts: one bark on combat entry
                        if state.callouts and inCombat and not bg.wasInCombat and not bg.isAnimal then
                            pcall(Natives.InvokeVoid, N.PLAY_PED_AMBIENT_SPEECH,
                                bg.handle, "GENERIC_WAR_CRY", "SPEECH_PARAMS_FORCE_SHOUTED", 0)
                        end
                        bg.wasInCombat = inCombat

                        local inVehicle = Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, bg.handle, false)

                        if medicDuty[bg.handle] then
                            -- On medic duty: don't override the rescue run
                        elseif sicTarget and entityExists(sicTarget) then
                            -- Player-tab "Sic 'Em" target takes priority
                            pcall(Natives.InvokeVoid, N.REGISTER_TARGET, bg.handle, sicTarget)
                            if not inCombat then
                                if inVehicle then
                                    pcall(Natives.InvokeVoid, N.TASK_VEHICLE_SHOOT_AT_PED, bg.handle, sicTarget, 60.0)
                                else
                                    pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, bg.handle, sicTarget, 0, 16)
                                end
                            end
                        elseif aimTarget then
                            pcall(Natives.InvokeVoid, N.REGISTER_TARGET, bg.handle, aimTarget)
                            if not inCombat then
                                if inVehicle then
                                    -- Vehicle: driveby shoot task (doesn't override vehicle AI)
                                    -- v4.0 fix: this native was missing from N in v3.x —
                                    -- the call errored inside pcall and silently did nothing
                                    pcall(Natives.InvokeVoid, N.TASK_VEHICLE_SHOOT_AT_PED, bg.handle, aimTarget, 60.0)
                                else
                                    -- On foot: direct combat
                                    pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, bg.handle, aimTarget, 0, 16)
                                end
                            end
                        elseif not inCombat and behav and behav.range > 0 then
                            pcall(Natives.InvokeVoid, N.TASK_COMBAT_HATED_TARGETS, bg.handle, behav.range, 0)
                        end
                    end
                end
            end

            -- Shadow guards (rappelled troops): same lock-on chain,
            -- just never listed. Dead ones self-clean here (no revive —
            -- air crew is expendable by design).
            for si = #shadowGuards, 1, -1 do
                local sh = shadowGuards[si]
                if not entityExists(sh.handle) then
                    table.remove(shadowGuards, si)
                else
                    local shDead = false
                    local okd, dd = pcall(Natives.InvokeBool, N.IS_PED_DEAD_OR_DYING, sh.handle, true)
                    shDead = okd and dd
                    if shDead then
                        pcall(deleteEntity, sh.handle)
                        table.remove(shadowGuards, si)
                    else
                        pcall(Natives.InvokeVoid, N.REGISTER_HATED_TARGETS_AROUND_PED, sh.handle, combatRange)
                        local shBusy = false
                        pcall(function()
                            shBusy = Natives.InvokeBool(N.IS_PED_IN_COMBAT, sh.handle, 0)
                        end)
                        if sicTarget and entityExists(sicTarget) then
                            pcall(Natives.InvokeVoid, N.REGISTER_TARGET, sh.handle, sicTarget)
                            if not shBusy then
                                pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, sh.handle, sicTarget, 0, 16)
                            end
                        elseif aimTarget then
                            pcall(Natives.InvokeVoid, N.REGISTER_TARGET, sh.handle, aimTarget)
                            if not shBusy then
                                pcall(Natives.InvokeVoid, N.TASK_COMBAT_PED, sh.handle, aimTarget, 0, 16)
                            end
                        elseif not shBusy and behav and behav.range > 0 then
                            pcall(Natives.InvokeVoid, N.TASK_COMBAT_HATED_TARGETS, sh.handle, behav.range, 0)
                        end
                    end
                end
            end
        end)
    end

    -- Auto teleport
    if state.autoTeleport and #bodyguards > 0 then
        pcall(function()
            local px, py, pz = myCoords()
            if not px then return end
            for i, bg in ipairs(bodyguards) do
                if entityExists(bg.handle) and not bg.downedAt then
                    local bx, by, bz = Natives.InvokeV3(N.GET_ENTITY_COORDS, bg.handle, true)
                    if bx then
                        local dx, dy = bx - px, by - py
                        if dx * dx + dy * dy > 2500 then
                            local angle = (i / #bodyguards) * math.pi * 2
                            Natives.InvokeVoid(N.SET_ENTITY_COORDS, bg.handle,
                                px + math.cos(angle) * 3, py + math.sin(angle) * 3, pz,
                                false, false, false, false)
                        end
                    end
                end
            end
        end)
    end

    Script.Yield(100)
end)

-- Loop: EXPLOSIVE ROUNDS — per-frame when active
-- Moved out of the 100ms loop: IS_PED_SHOOTING and the impact window
-- are only a few frames wide per shot, so 100ms sampling missed most
-- semi-auto/burst fire entirely. Per-frame polling catches every
-- impact; throttles keep it session-safe:
--   * 200ms per-guard cooldown
--   * 40ms global spacing between ANY two booms (caps the whole
--     squad + shadow army at ~25/sec)
--   * 5m/10m player bubble, RPG/GL skip, coord sanity — unchanged
local lastBoomGlobal = 0

Script.RegisterLooped(function()
    if isShuttingDown then return end
    if not state.explosiveBullets or (#bodyguards == 0 and #shadowGuards == 0) then
        Script.Yield(250)
        return
    end

    pcall(function()
        local px2, py2, pz2 = myCoords()
        local et = EXPLOSION_TYPES[state.expTypeIdx + 1]
        local t2 = nowMs()
        local bubble = 25.0
        if Natives.InvokeBool(N.IS_PED_IN_ANY_VEHICLE, myPed(), false) then
            bubble = 100.0
        end

        local function boomFor(entry)
            if not entityExists(entry.handle) or entry.downedAt then return end
            if entry.nextBoom and t2 < entry.nextBoom then return end
            if t2 - lastBoomGlobal < 40 then return end
            local held = Natives.InvokeInt(N.GET_SELECTED_PED_WEAPON, entry.handle)
            if EXP_WEAPON_SKIP[held] then return end
            if not Natives.InvokeBool(N.IS_PED_SHOOTING, entry.handle) then return end
            if not Natives.InvokeBool(N.GET_PED_LAST_WEAPON_IMPACT, entry.handle, impactPtr) then return end
            local ix = Memory.ReadFloat(impactPtr)
            local iy = Memory.ReadFloat(impactPtr + 8)
            local iz = Memory.ReadFloat(impactPtr + 16)
            if not px2 or (ix == 0.0 and iy == 0.0 and iz == 0.0) then return end
            local gx, gy, gz = Natives.InvokeV3(N.GET_ENTITY_COORDS, entry.handle, true)
            if gx then
                local sdx, sdy, sdz = ix - gx, iy - gy, iz - gz
                if sdx * sdx + sdy * sdy + sdz * sdz > 90000.0 then return end
            end
            local ddx, ddy, ddz = ix - px2, iy - py2, iz - pz2
            if ddx * ddx + ddy * ddy + ddz * ddz <= bubble then return end
            Natives.InvokeVoid(N.ADD_OWNED_EXPLOSION, entry.handle,
                ix, iy, iz, et and et.v or 0, 1.0, true, false, 0.15)
            entry.nextBoom = t2 + 200
            lastBoomGlobal = t2
        end

        for _, bg in ipairs(bodyguards) do
            pcall(boomFor, bg)
        end
        for _, sh in ipairs(shadowGuards) do
            pcall(boomFor, sh)
        end
    end)

    Script.Yield(0)
end)

-- Loop 2: ESP rendering via ON_PRESENT (v4.0 restyle)
-- Name/distance pills with health-tinted accent strip, bordered health
-- bars, bottom-center snaplines colored by health, pulsing DOWN tags.
local espHandler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    if isShuttingDown then return end
    local anyEsp = state.espName or state.espHealth or state.espDistance or state.espTracer
    if not anyEsp or #bodyguards == 0 then return end

    pcall(function()
        local px, py, pz = myCoords()
        if not px then return end

        local dw, dh = ImGui.GetDisplaySize()
        local t = nowMs()

        for _, bg in ipairs(bodyguards) do
            if entityExists(bg.handle) then
                local bx, by, bz = Natives.InvokeV3(N.GET_ENTITY_COORDS, bg.handle, true)
                if not bx then return end

                local ddx, ddy, ddz = bx - px, by - py, bz - pz
                local dist = math.sqrt(ddx * ddx + ddy * ddy + ddz * ddz)

                -- Health ratio drives tracer + accent + bar colors
                local hp, maxHp = 0, 1
                pcall(function()
                    hp = Natives.InvokeInt(N.GET_ENTITY_HEALTH, bg.handle)
                    maxHp = Natives.InvokeInt(N.GET_ENTITY_MAX_HEALTH, bg.handle)
                end)
                if maxHp <= 0 then maxHp = 1 end
                local ratio = math.max(0, math.min(1, hp / maxHp))
                local hr = math.floor((1 - ratio) * 255)
                local hg = math.floor(ratio * 220)

                -- Snapline from bottom-center, health-colored
                if state.espTracer then
                    local ok, sx, sy = worldToScreen(bx, by, bz + 0.2)
                    if ok then
                        ImGui.AddLine(dw * 0.5, dh, sx, sy, hr, hg, 80, 150, 1.5)
                    end
                end

                local ok, sx, sy = worldToScreen(bx, by, bz + 1.05)
                if ok then
                    if bg.downedAt and state.autoRevive then
                        -- Downed: pulsing red pill with revive countdown
                        local remain = state.reviveDelay - math.floor((t - bg.downedAt) / 1000)
                        if remain < 0 then remain = 0 end
                        local label = bg.name .. "  DOWN " .. remain .. "s"
                        local w = #label * 7
                        local pulse = math.floor(150 + 70 * math.sin(t / 150.0))
                        ImGui.AddRectFilled(sx - w * 0.5 - 6, sy - 3, sx + w * 0.5 + 6, sy + 15, 60, 12, 12, pulse, 4.0)
                        ImGui.AddText(sx - w * 0.5, sy, label, 255, 120, 120, 255)
                    else
                        local yOff = 0

                        -- Name / distance pill with health accent strip
                        if state.espName or state.espDistance then
                            local label = ""
                            if state.espName then label = bg.name end
                            if state.espDistance then
                                if #label > 0 then label = label .. "  |  " end
                                label = label .. string.format("%.0fm", dist)
                            end
                            local w = #label * 7
                            ImGui.AddRectFilled(sx - w * 0.5 - 6, sy - 3, sx + w * 0.5 + 6, sy + 15, 12, 14, 20, 190, 4.0)
                            ImGui.AddRectFilled(sx - w * 0.5 - 6, sy - 3, sx + w * 0.5 + 6, sy - 1, hr, hg, 80, 220, 0.0)
                            ImGui.AddText(sx - w * 0.5, sy, label, 235, 240, 250, 255)
                            yOff = yOff + 20
                        end

                        -- Bordered health bar
                        if state.espHealth then
                            local barW, barH = 64, 6
                            local x1 = sx - barW * 0.5
                            local y1 = sy + yOff
                            ImGui.AddRectFilled(x1 - 1, y1 - 1, x1 + barW + 1, y1 + barH + 1, 8, 10, 14, 220, 2.0)
                            ImGui.AddRectFilled(x1, y1, x1 + barW, y1 + barH, 30, 34, 44, 255, 2.0)
                            ImGui.AddRectFilled(x1, y1, x1 + barW * ratio, y1 + barH, hr, hg, 60, 255, 2.0)
                        end
                    end
                end
            end
        end
    end)
end)


-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════

-- Safe entity release for unload — NO Memory.AllocInt, NO DELETE_ENTITY
local function safeRelease(handle)
    if not handle or handle == 0 then return end
    pcall(Natives.InvokeVoid, N.SET_ENTITY_AS_MISSION, handle, false, true)
    pcall(Natives.InvokeVoid, N.SET_PED_AS_NO_LONGER_NEEDED, handle)
end

local cleanupDone = false

local function fullCleanup()
    if cleanupDone then return end
    cleanupDone = true
    isShuttingDown = true

    pcall(Script.Yield, 50)
    pcall(Script.Yield, 50)

    -- Pre-allocate ONE blip pointer before any cleanup (safest)
    local cleanupBlipPtr = nil
    pcall(function() cleanupBlipPtr = Memory.AllocInt() end)

    local function removeBlip(blipId)
        if not blipId or blipId == 0 or not cleanupBlipPtr then return end
        pcall(function()
            Memory.WriteInt(cleanupBlipPtr, blipId)
            Natives.InvokeVoid(N.REMOVE_BLIP, cleanupBlipPtr)
        end)
    end

    -- Release escorts
    for i = #escorts, 1, -1 do
        pcall(function()
            local esc = escorts[i]
            removeBlip(esc.blip)
            for _, p in ipairs(esc.passengers) do safeRelease(p) end
            safeRelease(esc.driver)
            if esc.veh and esc.veh ~= 0 then
                pcall(Natives.InvokeVoid, N.SET_ENTITY_AS_MISSION, esc.veh, false, true)
            end
        end)
    end
    escorts = {}

    -- Release bodyguards
    for i = #bodyguards, 1, -1 do
        pcall(function()
            local bg = bodyguards[i]
            removeBlip(bg.blip)
            safeRelease(bg.handle)
        end)
    end
    bodyguards = {}

    -- Release attackers
    for i = #attackers, 1, -1 do
        pcall(function()
            local a = attackers[i]
            removeBlip(a.blip)
            safeRelease(a.handle)
        end)
    end
    attackers = {}

    -- Release shadow guards (rappelled troops)
    for i = #shadowGuards, 1, -1 do
        pcall(function()
            safeRelease(shadowGuards[i].handle)
        end)
    end
    shadowGuards = {}

    -- Free cleanup blip pointer
    if cleanupBlipPtr then pcall(Memory.Free, cleanupBlipPtr) end

    -- Remove handlers and GUI
    if espHandler then
        pcall(EventMgr.RemoveHandler, espHandler)
        espHandler = nil
    end

    pcall(ClickGUI.RemoveTab, SCRIPT_NAME)
    pcall(ClickGUI.RemovePlayerTab, SCRIPT_NAME)

    -- Free all pre-allocated pointers (v4.0: blipPtr was leaked in v3.4)
    pcall(Memory.Free, aimEntPtr)
    pcall(Memory.Free, deletePtr)
    pcall(Memory.Free, blipPtr)
    pcall(Memory.Free, espXPtr)
    pcall(Memory.Free, espYPtr)
    pcall(Memory.Free, impactPtr)

    log("Cleanup complete")
end

EventMgr.RegisterHandler(eLuaEvent.ON_SCRIPT_STOP, fullCleanup)
pcall(function()
    EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, fullCleanup)
end)

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

initRelationships()
showLoadingBanner()

local totalModels = 0
for _, cat in ipairs(MODELS) do totalModels = totalModels + #cat end
local totalWeapons = 0
for _, cat in ipairs(WEAPON_CATS) do totalWeapons = totalWeapons + #cat.list end

log(SCRIPT_NAME .. " v" .. SCRIPT_VERSION .. " loaded")
log("Categories: " .. #CATEGORIES .. " | Models: " .. totalModels .. " | Weapons: " .. totalWeapons)
toast("Bodyguards v" .. SCRIPT_VERSION .. " loaded!")
