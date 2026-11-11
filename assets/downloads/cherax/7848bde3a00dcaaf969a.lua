local VERSION = "1.0.0"

local InvokeBool   = Natives.InvokeBool
local InvokeFloat  = Natives.InvokeFloat
local InvokeInt    = Natives.InvokeInt
local InvokeString = Natives.InvokeString
local InvokeVoid   = Natives.InvokeVoid
local InvokeV3     = Natives.InvokeV3

-- Native hashes

local H = {
    PLAYER_PED_ID                       = 0xD80958FC74E988A6,
    GET_ENTITY_COORDS                   = 0x3FEF770D40960D5A,
    GET_ENTITY_HEADING                  = 0xE83D4F9BA2A38914,
    GET_ENTITY_FORWARD_VECTOR           = 0x0A794A5A57F8DF91,
    GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS = 0x1899F328B0E12848,
    DOES_ENTITY_EXIST                   = 0x7239B21A38F536BA,

    GET_VEHICLE_PED_IS_IN               = 0x9A9112A0FE9A4713,
    SET_PED_INTO_VEHICLE                = 0xF75B0D629E1C063D,

    REQUEST_MODEL                       = 0x963D27A58DF860AC,
    HAS_MODEL_LOADED                    = 0x98A4EB5D89A0C952,
    IS_MODEL_IN_CDIMAGE                 = 0x35B9E0803292B641,
    IS_MODEL_A_VEHICLE                  = 0x19AAC8F07BFEC53E,
    SET_MODEL_AS_NO_LONGER_NEEDED       = 0xE532F5D78798DAAB,
    CREATE_VEHICLE                      = 0xAF35D0D2583051B0,

    SET_VEHICLE_MOD_KIT                 = 0x1F2AA07F00B3217A,
    GET_NUM_VEHICLE_MODS                = 0xE38E9162A2500646,
    GET_VEHICLE_MOD                     = 0x772960298DA26FDB,
    SET_VEHICLE_MOD                     = 0x6AF0636DDEDCB6DD,
    TOGGLE_VEHICLE_MOD                  = 0x2A1F4F37F95BAD08,

    SET_VEHICLE_WHEEL_TYPE              = 0x487EB21CC7295BA1,
    GET_VEHICLE_WHEEL_TYPE              = 0xB3ED1BFB4BE636DC,

    SET_VEHICLE_COLOURS                 = 0x4F1D4BE3A7F24601,
    SET_VEHICLE_EXTRA_COLOURS           = 0x2036F561ADD12E33,
    SET_VEHICLE_CUSTOM_PRIMARY_COLOUR   = 0x7141766F91D15BEA,
    SET_VEHICLE_CUSTOM_SECONDARY_COLOUR = 0x36CED73BFED89754,
    CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR = 0x55E1D2758F34E437,
    CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR = 0x5FFBDEEC3E8E2009,

    SET_VEHICLE_TYRE_SMOKE_COLOR        = 0xB5BA80F839791C0F,
    SET_VEHICLE_NEON_COLOUR             = 0x8E0A582209A62695,
    SET_VEHICLE_NEON_ENABLED            = 0x2AA720E4287BF269,
    SET_VEHICLE_WINDOW_TINT             = 0x57C51E6BAD752696,
    SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX = 0x9088EB5A43FFB0A1,
    SET_VEHICLE_NUMBER_PLATE_TEXT       = 0x95A88F0B409CDA47,
    SET_VEHICLE_TYRES_CAN_BURST         = 0xEB9DC3C7D8596C46,

    SET_VEHICLE_INTERIOR_COLOR          = 0xF40DD601A65F7F19,
    SET_VEHICLE_DASHBOARD_COLOR         = 0x6089CDF6A57F326C,

    SET_VEHICLE_FIXED                   = 0x115722B1B9C14C1C,
    SET_VEHICLE_DEFORMATION_FIXED       = 0x953DA1E1B12C0491,
    SET_VEHICLE_DIRT_LEVEL              = 0x79D3B596FE44EE8B,
}

-- Reference dataset

local REFERENCES = {
    {
        name = 'Solar Flare',
        model = 3656405053,
        wheelType = 10,
        wheelSeed = 115,
        primary = 12,
        secondary = 12,
        pearl = 0,
        customP = true,
        customPrimary = {r=255, g=205, b=0},
        customS = true,
        customSecondary = {r=255, g=205, b=0},
        wheelColor = 89,
        interior = 0,
        dash = 0,
        tint = 2,
        smoke = {r=252, g=238, b=0},
        neon = {
            left=true,
            right=true,
            front=false,
            back=true,
            color={r=255, g=205, b=0}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Rose Circuit',
        model = 1492612435,
        wheelType = 8,
        wheelSeed = 122,
        primary = 120,
        secondary = 27,
        pearl = 0,
        customP = true,
        customPrimary = {r=255, g=109, b=155},
        customS = true,
        customSecondary = {r=255, g=109, b=155},
        wheelColor = 135,
        interior = 8,
        dash = 0,
        tint = 1,
        smoke = {r=203, g=54, b=148},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Midnight Formal',
        model = 3640468689,
        wheelType = 8,
        wheelSeed = 122,
        primary = 111,
        secondary = 111,
        pearl = 0,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 55,
        interior = 92,
        dash = 0,
        tint = 1,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 3,
        bulletproof = false,
        drift = false
    },
    {
        name = 'Pearl Voltage',
        model = 386089410,
        wheelType = 8,
        wheelSeed = 108,
        primary = 204,
        secondary = 204,
        pearl = 205,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 204,
        interior = 111,
        dash = 111,
        tint = 2,
        smoke = {r=255, g=255, b=255},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=222, g=222, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Arctic Chrome',
        model = 2174267100,
        wheelType = 8,
        wheelSeed = 78,
        primary = 106,
        secondary = 8,
        pearl = 106,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = true,
        customSecondary = {r=174, g=152, b=128},
        wheelColor = 154,
        interior = 107,
        dash = 89,
        tint = 2,
        smoke = {r=255, g=255, b=255},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=174, g=152, b=128}
        },
        plateIndex = 0,
        bulletproof = false,
        drift = false
    },
    {
        name = 'Crimson Vector',
        model = 956849991,
        wheelType = 10,
        wheelSeed = 127,
        primary = 120,
        secondary = 120,
        pearl = 0,
        customP = true,
        customPrimary = {r=0, g=255, b=214},
        customS = true,
        customSecondary = {r=0, g=255, b=214},
        wheelColor = 208,
        interior = 111,
        dash = 111,
        tint = 1,
        smoke = {r=114, g=204, b=114},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=0, g=255, b=214}
        },
        plateIndex = 3,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Heritage Silver',
        model = 893780296,
        wheelType = 8,
        wheelSeed = 86,
        primary = 111,
        secondary = 111,
        pearl = 0,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 87,
        interior = 111,
        dash = 0,
        tint = 1,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Street Graphite',
        model = 3460613305,
        wheelType = 10,
        wheelSeed = 103,
        primary = 158,
        secondary = 158,
        pearl = 24,
        customP = true,
        customPrimary = {r=255, g=255, b=255},
        customS = true,
        customSecondary = {r=255, g=255, b=255},
        wheelColor = 205,
        interior = 0,
        dash = 0,
        tint = 1,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=255, b=255}
        },
        plateIndex = 1,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Satin Azure',
        model = 1133471123,
        wheelType = 8,
        wheelSeed = 77,
        primary = 162,
        secondary = 0,
        pearl = 161,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 162,
        interior = 0,
        dash = 0,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=44, g=0, b=12}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Neon Ronin',
        model = 409049982,
        wheelType = 8,
        wheelSeed = 78,
        primary = 211,
        secondary = 211,
        pearl = 211,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 211,
        interior = 0,
        dash = 0,
        tint = 1,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Retro Rally',
        model = 4003946083,
        wheelType = 8,
        wheelSeed = 120,
        primary = 203,
        secondary = 203,
        pearl = 206,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 203,
        interior = 111,
        dash = 111,
        tint = 1,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Executive Violet',
        model = 3050505892,
        wheelType = 8,
        wheelSeed = 108,
        primary = 0,
        secondary = 182,
        pearl = 88,
        customP = true,
        customPrimary = {r=20, g=5, b=64},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 182,
        interior = 111,
        dash = 111,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 10,
        bulletproof = true,
        drift = false
    },
    {
        name = 'White Current',
        model = 1939284556,
        wheelType = 10,
        wheelSeed = 73,
        primary = 211,
        secondary = 211,
        pearl = 211,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 211,
        interior = 111,
        dash = 111,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=255, g=255, b=255}
        },
        plateIndex = 5,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Bronze Halo',
        model = 669204833,
        wheelType = 8,
        wheelSeed = 122,
        primary = 193,
        secondary = 193,
        pearl = 135,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 193,
        interior = 111,
        dash = 134,
        tint = 1,
        smoke = {r=180, g=130, b=97},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=180, g=130, b=97}
        },
        plateIndex = 5,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Lavender Rush',
        model = 4129572538,
        wheelType = 8,
        wheelSeed = 55,
        primary = 21,
        secondary = 21,
        pearl = 135,
        customP = true,
        customPrimary = {r=146, g=150, b=255},
        customS = true,
        customSecondary = {r=146, g=150, b=255},
        wheelColor = 206,
        interior = 111,
        dash = 0,
        tint = 3,
        smoke = {r=203, g=54, b=148},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=255, g=50, b=100}
        },
        plateIndex = 10,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Lilac Apex',
        model = 4017955470,
        wheelType = 8,
        wheelSeed = 55,
        primary = 21,
        secondary = 21,
        pearl = 135,
        customP = true,
        customPrimary = {r=146, g=150, b=255},
        customS = true,
        customSecondary = {r=146, g=150, b=255},
        wheelColor = 206,
        interior = 111,
        dash = 0,
        tint = 3,
        smoke = {r=203, g=54, b=148},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=255, g=50, b=100}
        },
        plateIndex = 10,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Indigo Strike',
        model = 3630826055,
        wheelType = 8,
        wheelSeed = 116,
        primary = 107,
        secondary = 120,
        pearl = 135,
        customP = true,
        customPrimary = {r=53, g=5, b=255},
        customS = true,
        customSecondary = {r=53, g=5, b=255},
        wheelColor = 205,
        interior = 111,
        dash = 65,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 0,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Violet Current',
        model = 2439462158,
        wheelType = 9,
        wheelSeed = 88,
        primary = 64,
        secondary = 0,
        pearl = 88,
        customP = true,
        customPrimary = {r=60, g=39, b=207},
        customS = true,
        customSecondary = {r=60, g=39, b=207},
        wheelColor = 37,
        interior = 111,
        dash = 4,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=60, g=39, b=207}
        },
        plateIndex = 8,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Amethyst Touring',
        model = 2568944644,
        wheelType = 9,
        wheelSeed = 62,
        primary = 64,
        secondary = 0,
        pearl = 88,
        customP = true,
        customPrimary = {r=60, g=39, b=207},
        customS = true,
        customSecondary = {r=60, g=39, b=207},
        wheelColor = 0,
        interior = 111,
        dash = 4,
        tint = 2,
        smoke = {r=0, g=0, b=0},
        neon = {
            left=true,
            right=true,
            front=true,
            back=true,
            color={r=60, g=39, b=207}
        },
        plateIndex = 7,
        bulletproof = true,
        drift = false
    },
    {
        name = 'Steel Interceptor',
        model = 2042703219,
        wheelType = 10,
        wheelSeed = 1,
        primary = 170,
        secondary = 170,
        pearl = 160,
        customP = false,
        customPrimary = {r=0, g=0, b=0},
        customS = false,
        customSecondary = {r=0, g=0, b=0},
        wheelColor = 170,
        interior = 111,
        dash = 132,
        tint = 2,
        smoke = {r=255, g=255, b=255},
        neon = {
            left=false,
            right=false,
            front=false,
            back=false,
            color={r=255, g=0, b=255}
        },
        plateIndex = 4,
        bulletproof = false,
        drift = false
    }

}

-- Generator data

local STYLE_NAMES = {
    "Reference Mix",
    "Clean",
    "Street",
    "Track",
    "Show",
    "Luxury",
    "OEM+",
    "Wild"
}

local WHEEL_NAMES = {
    "Auto",
    "Sport",
    "Muscle",
    "Lowrider",
    "SUV",
    "Offroad",
    "Tuner",
    "High End",
    "Benny Original",
    "Benny Bespoke",
    "F1 / Open Wheel",
    "Street",
    "Track"
}

-- wheel type native values
local WHEEL_TYPES = {
    -1, 0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12
}

local PAINT_NAMES = {
    "Reference",
    "Blackout",
    "Whiteout",
    "Monochrome",
    "Pastel",
    "Neon",
    "Luxury",
    "Random RGB"
}

local NEON_NAMES = {
    "Reference",
    "Off",
    "Sides",
    "Full",
    "Match Primary",
    "White"
}

local BODY_NAMES = {
    "Subtle",
    "Balanced",
    "Aggressive",
    "Maximum",
    "Random"
}

local PERFORMANCE_NAMES = {
    "Stock",
    "Street",
    "Sport",
    "Max"
}

-- Common GTA paint IDs used for clean fallback themes.
local CLEAN_BLACKS = {0, 1, 2, 3, 11, 12}
local CLEAN_WHITES = {111, 112, 113, 134}
local CLEAN_SILVERS = {4, 5, 6, 7, 8, 9, 10}
local LUXURY_COLORS = {27, 38, 55, 64, 73, 88, 89, 90, 92, 99, 107, 111}
local PASTELS = {
    {r=255,g=178,b=196},
    {r=170,g=205,b=255},
    {r=184,g=255,b=208},
    {r=229,g=204,b=255},
    {r=255,g=225,b=170},
    {r=224,g=224,b=224}
}
local NEONS = {
    {r=0,g=255,b=214},
    {r=255,g=45,b=140},
    {r=80,g=120,b=255},
    {r=170,g=60,b=255},
    {r=255,g=205,b=0},
    {r=80,g=255,b=80}
}

-- State

math.randomseed(os.time() + (Utils.GetTimeEpocheMs and Utils.GetTimeEpocheMs() or 0))

local ui = {
    page = 1,
    pages = {"Garage", "Build Tool", "Customize", "References"},
    customizeTab = 1,
    buildTab = 1,

    style = 1,
    wheel = 1,
    paint = 1,
    neon = 1,
    body = 2,
    performance = 4,

    lockWheels = false,
    lockPaint = false,
    lockBody = false,
    lockPerformance = false,
    lockDetails = false,

    bodyStrength = 65,
    mutation = 55,
    referenceIndex = 1,

    spawnedVehicle = 0,
    lastGenerated = nil,
    previousGenerated = nil,

    generatedCount = 0
}

local CUSTOMIZE_TABS = {"Wheels", "Paint", "Body", "Details"}
local BUILD_TABS = {"Generator", "Wheels", "Paint", "Body", "Details"}

local FEATURE_CACHE = {}

-- Utility

local function toast(msg, ms)
    GUI.AddToast("VehicleForge", msg, ms or 2500)
end

local function exists(ent)
    return ent ~= nil and ent ~= 0 and InvokeBool(H.DOES_ENTITY_EXIST, ent)
end

local function ped()
    return InvokeInt(H.PLAYER_PED_ID)
end

local function current_vehicle()
    local v = InvokeInt(H.GET_VEHICLE_PED_IS_IN, ped(), false)
    if exists(v) then return v end
    if exists(ui.spawnedVehicle) then return ui.spawnedVehicle end
    return 0
end

local function get_feature(id)
    local f = FEATURE_CACHE[id]
    if f then return f end
    f = FeatureMgr.GetFeature(Utils.Joaat(id))
    if f then FEATURE_CACHE[id] = f end
    return f
end

local function render_feature(id)
    ClickGUI.RenderFeature(Utils.Joaat(id))
end

local function random_choice(t)
    return t[math.random(1, #t)]
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function copy_rgb(c)
    return {r=c.r, g=c.g, b=c.b}
end

local function color_distance(a, b)
    local dr, dg, db = a.r-b.r, a.g-b.g, a.b-b.b
    return math.sqrt(dr*dr + dg*dg + db*db)
end

local function tint_rgb(c, amount)
    return {
        r = clamp(math.floor(c.r + amount), 0, 255),
        g = clamp(math.floor(c.g + amount), 0, 255),
        b = clamp(math.floor(c.b + amount), 0, 255)
    }
end

local function complement(c)
    return {r=255-c.r, g=255-c.g, b=255-c.b}
end

local function muted(c)
    local avg = math.floor((c.r+c.g+c.b)/3)
    return {
        r=math.floor(c.r*0.72 + avg*0.28),
        g=math.floor(c.g*0.72 + avg*0.28),
        b=math.floor(c.b*0.72 + avg*0.28)
    }
end

local function random_rgb(min_brightness)
    min_brightness = min_brightness or 0
    for _=1,30 do
        local c = {r=math.random(0,255),g=math.random(0,255),b=math.random(0,255)}
        if c.r+c.g+c.b >= min_brightness then return c end
    end
    return {r=180,g=180,b=180}
end

local function selector(id, label, values, selected)
    ImGui.TextDisabled(label)
    local width, _ = ImGui.GetContentRegionAvail()
    local arrow = 30
    local middle = math.max(140, width - 72)

    if ImGui.Button("<##" .. id, arrow, 0) then
        selected = selected - 1
        if selected < 1 then selected = #values end
    end

    ImGui.SameLine()
    ImGui.Button((values[selected] or "Select") .. "##" .. id .. "_value", middle, 0)

    ImGui.SameLine()
    if ImGui.Button(">##" .. id, arrow, 0) then
        selected = selected + 1
        if selected > #values then selected = 1 end
    end

    return selected
end

local function nav_button(label, active, width)
    local styled = false
    if active and ImGuiCol and ImGuiCol.Button then
        ImGui.PushStyleColor(ImGuiCol.Button, 0.38, 0.20, 0.66, 1.0)
        styled = true
    end
    local clicked = ImGui.Button(label, width or 100, 0)
    if styled then ImGui.PopStyleColor(1) end
    return clicked
end

local function add_button(id, name, desc, fn)
    FeatureMgr.AddFeature(Utils.Joaat(id), name, eFeatureType.Button, desc or "", function()
        local ok, err = pcall(fn)
        if not ok then toast("Error: " .. tostring(err), 5000) end
    end)
end

local function add_toggle(id, name, desc, default)
    FeatureMgr.AddFeature(Utils.Joaat(id), name, eFeatureType.Toggle, desc or "")
        :SetDefaultValue(default == true)
        :Reset()
end

local function add_slider(id, name, desc, minv, maxv, default)
    FeatureMgr.AddFeature(Utils.Joaat(id), name, eFeatureType.SliderInt, desc or "")
        :SetLimitValues(minv, maxv)
        :SetDefaultValue(default)
        :Reset()
end

-- Build generation

local function selected_reference()
    local i = clamp(ui.referenceIndex, 1, #REFERENCES)
    return REFERENCES[i]
end

local function random_reference()
    return REFERENCES[math.random(1, #REFERENCES)]
end

local function choose_reference()
    if ui.style == 1 and math.random(1,100) <= 60 then
        return selected_reference()
    end
    return random_reference()
end

local function generate_palette(reference)
    local mode = ui.paint
    local p = {
        primary = reference.primary,
        secondary = reference.secondary,
        pearl = reference.pearl,
        customP = reference.customP,
        customPrimary = copy_rgb(reference.customPrimary),
        customS = reference.customS,
        customSecondary = copy_rgb(reference.customSecondary),
        wheelColor = reference.wheelColor,
        interior = reference.interior,
        dash = reference.dash
    }

    if mode == 1 then
        -- Reference
        return p
    elseif mode == 2 then
        -- Blackout
        p.primary = random_choice(CLEAN_BLACKS)
        p.secondary = p.primary
        p.pearl = 0
        p.customP, p.customS = false, false
        p.wheelColor = random_choice(CLEAN_BLACKS)
        p.interior = 0
        p.dash = 0
    elseif mode == 3 then
        -- Whiteout
        p.primary = random_choice(CLEAN_WHITES)
        p.secondary = p.primary
        p.pearl = random_choice(CLEAN_SILVERS)
        p.customP, p.customS = false, false
        p.wheelColor = random_choice(CLEAN_WHITES)
    elseif mode == 4 then
        -- Monochrome
        local c = random_choice({random_choice(CLEAN_BLACKS), random_choice(CLEAN_WHITES), random_choice(CLEAN_SILVERS)})
        p.primary, p.secondary, p.pearl = c, c, c
        p.customP, p.customS = false, false
        p.wheelColor = c
    elseif mode == 5 then
        -- Pastel coordinated RGB
        local c = copy_rgb(random_choice(PASTELS))
        p.customP, p.customS = true, true
        p.customPrimary = c
        p.customSecondary = muted(tint_rgb(c, -20))
        p.primary, p.secondary = 111, 111
        p.pearl = random_choice(CLEAN_WHITES)
        p.wheelColor = random_choice(CLEAN_WHITES)
    elseif mode == 6 then
        -- Neon
        local c = copy_rgb(random_choice(NEONS))
        p.customP, p.customS = true, true
        p.customPrimary = c
        p.customSecondary = tint_rgb(c, -45)
        p.primary, p.secondary = 120, 120
        p.pearl = 0
        p.wheelColor = 0
    elseif mode == 7 then
        -- Luxury
        p.primary = random_choice(LUXURY_COLORS)
        p.secondary = math.random() < 0.6 and p.primary or random_choice(LUXURY_COLORS)
        p.pearl = random_choice(LUXURY_COLORS)
        p.customP, p.customS = false, false
        p.wheelColor = math.random() < 0.5 and 0 or 111
    else
        -- Random RGB, but coordinated, not pure garbage.
        local c = random_rgb(180)
        p.customP, p.customS = true, true
        p.customPrimary = c
        p.customSecondary = math.random() < 0.6 and muted(tint_rgb(c, -35)) or muted(complement(c))
        p.primary, p.secondary = 120, 120
        p.pearl = 0
        p.wheelColor = math.random(0, 160)
    end

    return p
end

local function style_body_probability(slot)
    -- probability that a body slot receives a non-stock option
    local base = ui.bodyStrength / 100.0
    if ui.body == 1 then base = base * 0.35 end
    if ui.body == 2 then base = base * 0.60 end
    if ui.body == 3 then base = base * 0.85 end
    if ui.body == 4 then base = 1.00 end
    if ui.body == 5 then base = math.random(30,100)/100 end

    -- performance slots are handled separately
    if slot >= 11 and slot <= 16 then return 0 end
    -- wheels handled separately
    if slot == 23 or slot == 24 then return 0 end
    return base
end

local function build_mods(vehicle)
    local mods = {}
    InvokeVoid(H.SET_VEHICLE_MOD_KIT, vehicle, 0)

    for slot=0,48 do
        if slot ~= 23 and slot ~= 24 then
            local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, slot)
            if count and count > 0 then
                local p = style_body_probability(slot)
                if math.random() <= p then
                    local idx

                    if ui.style == 2 or ui.style == 7 then
                        -- Clean/OEM+: favor the first third of valid parts
                        local cap = math.max(1, math.floor(count * 0.35))
                        idx = math.random(0, cap-1)
                    elseif ui.style == 4 then
                        -- Track: upper-middle choices
                        local low = math.floor(count * 0.45)
                        idx = math.random(low, count-1)
                    elseif ui.style == 5 or ui.style == 8 then
                        -- Show/Wild: bolder end of range
                        local low = math.floor(count * 0.65)
                        idx = math.random(low, count-1)
                    else
                        idx = math.random(0, count-1)
                    end

                    mods[slot] = idx
                else
                    mods[slot] = -1
                end
            end
        end
    end

    return mods
end

local function performance_level()
    if ui.performance == 1 then return 0 end
    if ui.performance == 2 then return 0.45 end
    if ui.performance == 3 then return 0.75 end
    return 1.0
end

local function build_performance(vehicle, mods)
    local level = performance_level()
    local perfSlots = {11, 12, 13, 15, 16}

    for _,slot in ipairs(perfSlots) do
        local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, slot)
        if count and count > 0 then
            if level == 0 then
                mods[slot] = -1
            else
                local idx = math.floor((count-1) * level)
                mods[slot] = clamp(idx, 0, count-1)
            end
        end
    end
end

local function build_wheels(vehicle, reference)
    local wheelType
    if ui.wheel == 1 then
        -- Auto: use style + references
        if ui.style == 4 then wheelType = 12
        elseif ui.style == 5 or ui.style == 8 then
            wheelType = math.random() < 0.5 and 8 or 10
        elseif ui.style == 2 or ui.style == 7 then
            wheelType = random_choice({0,5,7,11})
        else
            wheelType = reference.wheelType
        end
    else
        wheelType = WHEEL_TYPES[ui.wheel]
    end

    InvokeVoid(H.SET_VEHICLE_WHEEL_TYPE, vehicle, wheelType)

    local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, 23)
    local wheelIndex = -1
    if count and count > 0 then
        local seed = math.abs(reference.wheelSeed or 0)
        local mutation = ui.mutation / 100.0

        if math.random() < mutation then
            wheelIndex = math.random(0, count-1)
        else
            wheelIndex = seed % count
        end
    end

    return wheelType, wheelIndex
end

local function build_details(reference, palette)
    local d = {
        tint = reference.tint,
        plateIndex = reference.plateIndex,
        smoke = copy_rgb(reference.smoke),
        neon = {
            left=reference.neon.left,
            right=reference.neon.right,
            front=reference.neon.front,
            back=reference.neon.back,
            color=copy_rgb(reference.neon.color)
        },
        bulletproof = reference.bulletproof
    }

    if ui.neon == 2 then
        d.neon.left,d.neon.right,d.neon.front,d.neon.back = false,false,false,false
    elseif ui.neon == 3 then
        d.neon.left,d.neon.right,d.neon.front,d.neon.back = true,true,false,false
    elseif ui.neon == 4 then
        d.neon.left,d.neon.right,d.neon.front,d.neon.back = true,true,true,true
    elseif ui.neon == 5 then
        local c = palette.customP and palette.customPrimary or reference.neon.color
        d.neon.left,d.neon.right,d.neon.front,d.neon.back = true,true,true,true
        d.neon.color = copy_rgb(c)
        d.smoke = copy_rgb(c)
    elseif ui.neon == 6 then
        d.neon.left,d.neon.right,d.neon.front,d.neon.back = true,true,true,true
        d.neon.color = {r=255,g=255,b=255}
        d.smoke = {r=255,g=255,b=255}
    end

    return d
end

local function make_build(vehicle)
    local reference = choose_reference()

    local build = {
        refName = reference.name,
        mods = {},
        wheelType = nil,
        wheelIndex = nil,
        palette = nil,
        details = nil,
        generatedAt = os.time()
    }

    if ui.lockBody and ui.lastGenerated then
        for k,v in pairs(ui.lastGenerated.mods or {}) do build.mods[k]=v end
    else
        build.mods = build_mods(vehicle)
    end

    if ui.lockPerformance and ui.lastGenerated then
        for _,slot in ipairs({11,12,13,15,16}) do
            if ui.lastGenerated.mods then build.mods[slot] = ui.lastGenerated.mods[slot] end
        end
    else
        build_performance(vehicle, build.mods)
    end

    if ui.lockWheels and ui.lastGenerated then
        build.wheelType = ui.lastGenerated.wheelType
        build.wheelIndex = ui.lastGenerated.wheelIndex
    else
        build.wheelType, build.wheelIndex = build_wheels(vehicle, reference)
    end

    if ui.lockPaint and ui.lastGenerated then
        build.palette = ui.lastGenerated.palette
    else
        build.palette = generate_palette(reference)
    end

    if ui.lockDetails and ui.lastGenerated then
        build.details = ui.lastGenerated.details
    else
        build.details = build_details(reference, build.palette)
    end

    return build
end

local function apply_build(vehicle, build)
    if not exists(vehicle) then
        toast("No vehicle selected")
        return false
    end

    InvokeVoid(H.SET_VEHICLE_MOD_KIT, vehicle, 0)

    -- Body + performance
    for slot,idx in pairs(build.mods or {}) do
        local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, slot)
        if count and count > 0 then
            local safe = idx
            if safe >= count then safe = count-1 end
            if safe < -1 then safe = -1 end
            InvokeVoid(H.SET_VEHICLE_MOD, vehicle, slot, safe, false)
        end
    end

    -- Common toggle mods: turbo / tire smoke / xenon.
    if ui.performance >= 3 then InvokeVoid(H.TOGGLE_VEHICLE_MOD, vehicle, 18, true) end
    InvokeVoid(H.TOGGLE_VEHICLE_MOD, vehicle, 20, true)
    if ui.style == 5 or ui.style == 8 then InvokeVoid(H.TOGGLE_VEHICLE_MOD, vehicle, 22, true) end

    -- Wheels
    if build.wheelType ~= nil then
        InvokeVoid(H.SET_VEHICLE_WHEEL_TYPE, vehicle, build.wheelType)
        local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, 23)
        if count and count > 0 and build.wheelIndex and build.wheelIndex >= 0 then
            local idx = build.wheelIndex % count
            InvokeVoid(H.SET_VEHICLE_MOD, vehicle, 23, idx, true)
            local rearCount = InvokeInt(H.GET_NUM_VEHICLE_MODS, vehicle, 24)
            if rearCount and rearCount > 0 then
                InvokeVoid(H.SET_VEHICLE_MOD, vehicle, 24, idx % rearCount, true)
            end
        end
    end

    -- Paint
    local p = build.palette
    if p then
        InvokeVoid(H.SET_VEHICLE_COLOURS, vehicle, p.primary, p.secondary)
        InvokeVoid(H.SET_VEHICLE_EXTRA_COLOURS, vehicle, p.pearl, p.wheelColor)

        if p.customP then
            InvokeVoid(H.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR, vehicle, p.customPrimary.r, p.customPrimary.g, p.customPrimary.b)
        else
            InvokeVoid(H.CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR, vehicle)
        end

        if p.customS then
            InvokeVoid(H.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR, vehicle, p.customSecondary.r, p.customSecondary.g, p.customSecondary.b)
        else
            InvokeVoid(H.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR, vehicle)
        end

        InvokeVoid(H.SET_VEHICLE_INTERIOR_COLOR, vehicle, p.interior)
        InvokeVoid(H.SET_VEHICLE_DASHBOARD_COLOR, vehicle, p.dash)
    end

    -- Details
    local d = build.details
    if d then
        InvokeVoid(H.SET_VEHICLE_WINDOW_TINT, vehicle, d.tint)
        InvokeVoid(H.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX, vehicle, d.plateIndex)
        InvokeVoid(H.SET_VEHICLE_TYRE_SMOKE_COLOR, vehicle, d.smoke.r, d.smoke.g, d.smoke.b)
        InvokeVoid(H.SET_VEHICLE_NEON_COLOUR, vehicle, d.neon.color.r, d.neon.color.g, d.neon.color.b)
        InvokeVoid(H.SET_VEHICLE_NEON_ENABLED, vehicle, 0, d.neon.left)
        InvokeVoid(H.SET_VEHICLE_NEON_ENABLED, vehicle, 1, d.neon.right)
        InvokeVoid(H.SET_VEHICLE_NEON_ENABLED, vehicle, 2, d.neon.front)
        InvokeVoid(H.SET_VEHICLE_NEON_ENABLED, vehicle, 3, d.neon.back)
        InvokeVoid(H.SET_VEHICLE_TYRES_CAN_BURST, vehicle, not d.bulletproof)
    end

    InvokeVoid(H.SET_VEHICLE_FIXED, vehicle)
    InvokeVoid(H.SET_VEHICLE_DEFORMATION_FIXED, vehicle)
    InvokeVoid(H.SET_VEHICLE_DIRT_LEVEL, vehicle, 0.0)

    return true
end

local function generate()
    local v = current_vehicle()
    if not exists(v) then
        toast("Get in a vehicle or spawn one first")
        return
    end

    local build = make_build(v)

    -- make_build changes wheel type while evaluating valid wheels;
    -- apply the whole build immediately after.
    if apply_build(v, build) then
        ui.previousGenerated = ui.lastGenerated
        ui.lastGenerated = build
        ui.generatedCount = ui.generatedCount + 1
        toast(("Generated #%d | inspired by %s"):format(ui.generatedCount, build.refName), 3200)
    end
end

local function apply_previous()
    local v = current_vehicle()
    if not exists(v) or not ui.previousGenerated then
        toast("No previous generated build")
        return
    end

    local current = ui.lastGenerated
    if apply_build(v, ui.previousGenerated) then
        ui.lastGenerated, ui.previousGenerated = ui.previousGenerated, current
        toast("Previous build restored")
    end
end

local function max_performance()
    local v = current_vehicle()
    if not exists(v) then toast("No vehicle selected"); return end
    InvokeVoid(H.SET_VEHICLE_MOD_KIT, v, 0)
    for _,slot in ipairs({11,12,13,15,16}) do
        local count = InvokeInt(H.GET_NUM_VEHICLE_MODS, v, slot)
        if count and count > 0 then InvokeVoid(H.SET_VEHICLE_MOD, v, slot, count-1, false) end
    end
    InvokeVoid(H.TOGGLE_VEHICLE_MOD, v, 18, true)
    toast("Performance maxed")
end

-- Spawn / garage

local vehicleModelInput = FeatureMgr.AddFeature(
    Utils.Joaat("VF_MODEL_INPUT"),
    "Vehicle Model",
    eFeatureType.InputText,
    "Enter a GTA vehicle model name. VehicleForge validates it before spawning."
)
vehicleModelInput:SetStringValue("")

local function spawn_input_vehicle()
    local f = get_feature("VF_MODEL_INPUT")
    if not f then toast("Model input unavailable"); return end

    local name = f:GetStringValue()
    if not name or name == "" then
        toast("Enter a vehicle model")
        return
    end

    local hash = Utils.Joaat(name)

    if not InvokeBool(H.IS_MODEL_IN_CDIMAGE, hash) then
        toast("Model does not exist in GTA")
        return
    end

    if not InvokeBool(H.IS_MODEL_A_VEHICLE, hash) then
        toast("That model is not a vehicle")
        return
    end

    -- Prefer Cherax's own vehicle spawning API if available.
    if GTA and GTA.SpawnVehicle then
        local ok, result = pcall(GTA.SpawnVehicle, hash)
        if ok and result then
            local handle = result
            if type(result) ~= "number" and GTA.PointerToHandle then
                handle = GTA.PointerToHandle(result)
            end

            if exists(handle) then
                ui.spawnedVehicle = handle
                InvokeVoid(H.SET_PED_INTO_VEHICLE, ped(), handle, -1)
                toast("Spawned " .. name)
                return
            end
        end
    end

    -- Safer native fallback:
    -- request + short wait + spawn several meters in front of the player.
    InvokeVoid(H.REQUEST_MODEL, hash)

    local loaded = false
    local start_time = Utils.GetTimeEpocheMs and Utils.GetTimeEpocheMs() or 0
    local timeout_ms = 4000

    while true do
        if InvokeBool(H.HAS_MODEL_LOADED, hash) then
            loaded = true
            break
        end

        if Utils.GetTimeEpocheMs then
            if Utils.GetTimeEpocheMs() - start_time > timeout_ms then
                break
            end
        else
            -- No reliable timer available: don't loop forever.
            break
        end

        -- Use Script.Yield if exposed by this Cherax build.
        if Script and Script.Yield then
            Script.Yield(0)
        else
            break
        end
    end

    if not loaded then
        toast("Vehicle model could not be loaded safely")
        InvokeVoid(H.SET_MODEL_AS_NO_LONGER_NEEDED, hash)
        return
    end

    local p = ped()
    if not exists(p) then
        InvokeVoid(H.SET_MODEL_AS_NO_LONGER_NEEDED, hash)
        toast("Player ped unavailable")
        return
    end

    local px, py, pz = InvokeV3(H.GET_ENTITY_COORDS, p, true)
    local fx, fy, fz = InvokeV3(H.GET_ENTITY_FORWARD_VECTOR, p)
    local heading = InvokeFloat(H.GET_ENTITY_HEADING, p)

    local sx = px + (fx * 6.0)
    local sy = py + (fy * 6.0)
    local sz = pz + 0.5

    local v = InvokeInt(H.CREATE_VEHICLE, hash, sx, sy, sz, heading, true, false, false)

    if not exists(v) then
        InvokeVoid(H.SET_MODEL_AS_NO_LONGER_NEEDED, hash)
        toast("Vehicle spawn failed")
        return
    end

    ui.spawnedVehicle = v

    -- Small delay before seating to let the entity initialize.
    if Script and Script.Yield then
        Script.Yield(100)
    end

    if exists(v) then
        InvokeVoid(H.SET_PED_INTO_VEHICLE, p, v, -1)
        InvokeVoid(H.SET_VEHICLE_DIRT_LEVEL, v, 0.0)
    end

    InvokeVoid(H.SET_MODEL_AS_NO_LONGER_NEEDED, hash)
    toast("Spawned " .. name)
end

-- Features

add_button("VF_SPAWN", "Spawn Vehicle", "Spawns the model entered above and puts you in the driver seat.", spawn_input_vehicle)
add_button("VF_GENERATE", "Generate Build", "Generates a complete coordinated build for the current vehicle.", generate)
add_button("VF_REGENERATE", "Regenerate Unlocked", "Generates again while respecting every locked category.", generate)
add_button("VF_PREVIOUS", "Previous Build", "Swaps back to the previous generated build.", apply_previous)
add_button("VF_MAX_PERF", "Max Performance", "Maxes common performance upgrade slots and turbo.", max_performance)

add_slider("VF_BODY_STRENGTH", "Body Strength", "How aggressively body modification slots are used.", 0, 100, 65)
add_slider("VF_MUTATION", "Mutation", "Higher values make generated results vary more from reference seeds.", 0, 100, 55)

add_toggle("VF_LOCK_WHEELS", "Lock Wheels", "Keep the current generated wheel setup while regenerating.", false)
add_toggle("VF_LOCK_PAINT", "Lock Paint", "Keep the current generated paint setup while regenerating.", false)
add_toggle("VF_LOCK_BODY", "Lock Body", "Keep the current generated body setup while regenerating.", false)
add_toggle("VF_LOCK_PERF", "Lock Performance", "Keep generated performance choices while regenerating.", false)
add_toggle("VF_LOCK_DETAILS", "Lock Details", "Keep tint, neons, smoke, plate and detail choices.", false)

-- Sync UI feature state

local function sync_feature_state()
    local f

    f = get_feature("VF_BODY_STRENGTH")
    if f then ui.bodyStrength = f:GetIntValue() end

    f = get_feature("VF_MUTATION")
    if f then ui.mutation = f:GetIntValue() end

    f = get_feature("VF_LOCK_WHEELS")
    if f then ui.lockWheels = f:IsToggled() end

    f = get_feature("VF_LOCK_PAINT")
    if f then ui.lockPaint = f:IsToggled() end

    f = get_feature("VF_LOCK_BODY")
    if f then ui.lockBody = f:IsToggled() end

    f = get_feature("VF_LOCK_PERF")
    if f then ui.lockPerformance = f:IsToggled() end

    f = get_feature("VF_LOCK_DETAILS")
    if f then ui.lockDetails = f:IsToggled() end
end

-- UI

local function render_header()
    ImGui.Text("VEHICLEFORGE")
    ImGui.SameLine()
    ImGui.TextDisabled("PREMIUM")
    ImGui.SameLine()
    ImGui.TextDisabled(VERSION)
    ImGui.Separator()

    -- Primary tabs
    local avail, _ = ImGui.GetContentRegionAvail()
    local widths = {92, 105, 102, 104}
    for i, name in ipairs(ui.pages) do
        if nav_button(name, ui.page == i, widths[i] or 100) then
            ui.page = i
        end
        if i < #ui.pages then ImGui.SameLine() end
    end

    -- Contextual second row, like Silent Night's heist sub-tabs.
    if ui.pages[ui.page] == "Build Tool" then
        ImGui.Separator()
        for i, name in ipairs(BUILD_TABS) do
            if nav_button(name, ui.buildTab == i, 96) then
                ui.buildTab = i
            end
            if i < #BUILD_TABS then ImGui.SameLine() end
        end
    elseif ui.pages[ui.page] == "Customize" then
        ImGui.Separator()
        for i, name in ipairs(CUSTOMIZE_TABS) do
            if nav_button(name, ui.customizeTab == i, 100) then
                ui.customizeTab = i
            end
            if i < #CUSTOMIZE_TABS then ImGui.SameLine() end
        end
    end

    ImGui.Separator()
end

local function render_customize_nav()
    -- kept for compatibility; navigation is now in the header.
end

local function render_customize_nav()
    for i, name in ipairs(CUSTOMIZE_TABS) do
        if nav_button(name, ui.customizeTab == i, 108) then
            ui.customizeTab = i
        end
        if i < #CUSTOMIZE_TABS then ImGui.SameLine() end
    end
    ImGui.Separator()
end

local function render_garage()
    if ClickGUI.BeginCustomChildWindow("Garage Header") then
        ImGui.Text("GARAGE")
        ImGui.SameLine()
        ImGui.TextDisabled("Spawn a vehicle and build from any reference style")
        ImGui.Separator()
        ClickGUI.EndCustomChildWindow()
    end

    if ImGui.BeginTable("VFGarageTop", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Vehicle") then
            ImGui.Text("Vehicle")
            ImGui.Separator()
            ImGui.TextDisabled("Safe spawn checks enabled")
            render_feature("VF_MODEL_INPUT")
            render_feature("VF_SPAWN")

            ImGui.Spacing()
            local v = current_vehicle()
            if exists(v) then
                ImGui.TextDisabled("Status")
                ImGui.SameLine()
                ImGui.Text("Ready")
            else
                ImGui.TextDisabled("Status")
                ImGui.SameLine()
                ImGui.Text("No vehicle selected")
            end
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Quick Build") then
            ImGui.Text("Quick Build")
            ImGui.Separator()
            render_feature("VF_GENERATE")
            render_feature("VF_REGENERATE")
            render_feature("VF_PREVIOUS")
            ImGui.Spacing()
            if ui.lastGenerated then
                ImGui.TextDisabled("Last inspiration")
                ImGui.SameLine()
                ImGui.TextWrapped(tostring(ui.lastGenerated.refName))
            else
                ImGui.TextDisabled("No generated build yet")
            end
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end

    if ClickGUI.BeginCustomChildWindow("Quick Setup") then
        ImGui.Text("Quick Setup")
        ImGui.Separator()

        local refNames = {}
        for _, r in ipairs(REFERENCES) do refNames[#refNames+1] = r.name end

        ui.referenceIndex = selector("vf_ref_garage", "Reference Style", refNames, ui.referenceIndex)
        ui.style = selector("vf_style_garage", "Generation Mode", STYLE_NAMES, ui.style)
        ui.paint = selector("vf_paint_garage", "Paint Theme", PAINT_NAMES, ui.paint)
        ui.performance = selector("vf_perf_garage", "Performance", PERFORMANCE_NAMES, ui.performance)

        ImGui.Spacing()
        ImGui.TextDisabled("Reference behavior")
        ImGui.TextWrapped("Reference Mix uses the selected car as the main style source. Other generation modes still borrow reference data, but prioritize their own style rules.")
        ClickGUI.EndCustomChildWindow()
    end
end

local function render_build()
    if ClickGUI.BeginCustomChildWindow("Build Header") then
        ImGui.Text("BUILD GENERATOR")
        ImGui.SameLine()
        ImGui.TextDisabled("Create a complete coordinated setup")
        ImGui.Separator()
        ClickGUI.EndCustomChildWindow()
    end

    if ImGui.BeginTable("VFGenerator", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Build Profile") then
            ui.style = selector("vf_style", "Style", STYLE_NAMES, ui.style)
            ui.body = selector("vf_body", "Body", BODY_NAMES, ui.body)
            ui.performance = selector("vf_perf", "Performance", PERFORMANCE_NAMES, ui.performance)
            render_feature("VF_BODY_STRENGTH")
            render_feature("VF_MUTATION")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Generation") then
            render_feature("VF_GENERATE")
            render_feature("VF_REGENERATE")
            render_feature("VF_PREVIOUS")
            ImGui.Separator()
            ImGui.TextDisabled("Locks")
            render_feature("VF_LOCK_WHEELS")
            render_feature("VF_LOCK_PAINT")
            render_feature("VF_LOCK_BODY")
            render_feature("VF_LOCK_PERF")
            render_feature("VF_LOCK_DETAILS")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

local function render_wheels()
    if ImGui.BeginTable("VFWheels", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Wheel Family") then
            ui.wheel = selector("vf_wheel", "Wheel Type", WHEEL_NAMES, ui.wheel)
            ImGui.Spacing()
            ImGui.TextWrapped("Auto uses the selected style and your reference pack. Benny and F1 modes force those wheel families before choosing a compatible wheel index.")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Wheel Actions") then
            render_feature("VF_LOCK_WHEELS")
            render_feature("VF_REGENERATE")
            ImGui.Separator()
            local v = current_vehicle()
            if exists(v) then
                ImGui.TextDisabled("Current native wheel type")
                ImGui.Text(tostring(InvokeInt(H.GET_VEHICLE_WHEEL_TYPE, v)))
            end
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

local function render_paint()
    if ImGui.BeginTable("VFPaint", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Palette") then
            ui.paint = selector("vf_paint", "Paint Theme", PAINT_NAMES, ui.paint)
            ui.neon = selector("vf_neon", "Neon Theme", NEON_NAMES, ui.neon)
            ImGui.Spacing()
            ImGui.TextWrapped("Paint generation coordinates primary, secondary, pearlescent, wheel, interior, dashboard, neon and smoke colors instead of randomizing each value independently.")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Paint Actions") then
            render_feature("VF_LOCK_PAINT")
            render_feature("VF_LOCK_DETAILS")
            render_feature("VF_REGENERATE")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

local function render_body()
    if ImGui.BeginTable("VFBody", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Body Generator") then
            ui.body = selector("vf_body2", "Body Style", BODY_NAMES, ui.body)
            render_feature("VF_BODY_STRENGTH")
            render_feature("VF_LOCK_BODY")
            ImGui.Spacing()
            ImGui.TextWrapped("VehicleForge asks GTA how many options each mod slot supports before choosing one, so it does not blindly copy invalid body-part IDs between unrelated cars.")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Performance") then
            ui.performance = selector("vf_perf2", "Performance", PERFORMANCE_NAMES, ui.performance)
            render_feature("VF_LOCK_PERF")
            render_feature("VF_MAX_PERF")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

local function render_details()
    if ImGui.BeginTable("VFDetails", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Lighting & Details") then
            ui.neon = selector("vf_neon2", "Neon", NEON_NAMES, ui.neon)
            render_feature("VF_LOCK_DETAILS")
            ImGui.TextWrapped("Generated details include neon placement/color, tire smoke, window tint, plate style and tire settings.")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Regenerate") then
            render_feature("VF_REGENERATE")
            render_feature("VF_PREVIOUS")
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end

local function render_customize()
    if ClickGUI.BeginCustomChildWindow("Customize Header") then
        ImGui.Text("CUSTOMIZE")
        ImGui.SameLine()
        ImGui.TextDisabled("Fine-tune individual parts of the generated build")
        ImGui.Separator()
        ClickGUI.EndCustomChildWindow()
    end

    local section = CUSTOMIZE_TABS[ui.customizeTab]
    if section == "Wheels" then
        render_wheels()
    elseif section == "Paint" then
        render_paint()
    elseif section == "Body" then
        render_body()
    elseif section == "Details" then
        render_details()
    end
end

local function render_build_tool()
    local tab = BUILD_TABS[ui.buildTab]
    if tab == "Generator" then
        render_build()
    elseif tab == "Wheels" then
        render_wheels()
    elseif tab == "Paint" then
        render_paint()
    elseif tab == "Body" then
        render_body()
    elseif tab == "Details" then
        render_details()
    end
end

local function render_references()
    if ClickGUI.BeginCustomChildWindow("Reference Pack") then
        ImGui.Text("REFERENCE STYLES")
        ImGui.SameLine()
        ImGui.TextDisabled(tostring(#REFERENCES) .. " loaded")
        ImGui.Separator()

        local names = {}
        for _,r in ipairs(REFERENCES) do names[#names+1] = r.name end
        ui.referenceIndex = selector("vf_reference", "Selected Reference Style", names, ui.referenceIndex)

        local r = selected_reference()
        ImGui.Spacing()

        if ImGui.BeginTable("VFRefInfo", 2, ImGuiTableFlags.SizingStretchSame) then
            ImGui.TableNextRow()

            ImGui.TableSetColumnIndex(0)
            ImGui.TextDisabled("Reference")
            ImGui.Text(tostring(r.name))
            ImGui.TextDisabled("Model hash")
            ImGui.Text(tostring(r.model))
            ImGui.TextDisabled("Wheel family")
            ImGui.Text(tostring(r.wheelType))

            ImGui.TableSetColumnIndex(1)
            ImGui.TextDisabled("Wheel seed")
            ImGui.Text(tostring(r.wheelSeed))
            ImGui.TextDisabled("Window tint")
            ImGui.Text(tostring(r.tint))
            ImGui.TextDisabled("Generation mode")
            ImGui.Text(STYLE_NAMES[ui.style])

            ImGui.EndTable()
        end

        ImGui.Separator()
        ImGui.TextWrapped("To strongly copy this reference's style DNA, switch Generation Mode to Reference Mix, then generate. VehicleForge adapts the selected reference to whatever car you are using instead of blindly copying invalid mod indexes.")
        ClickGUI.EndCustomChildWindow()
    end
end

local function render_tab()
    sync_feature_state()
    render_header()

    local page = ui.pages[ui.page]
    if page == "Garage" then
        render_garage()
    elseif page == "Build Tool" then
        render_build_tool()
    elseif page == "Customize" then
        render_customize()
    elseif page == "References" then
        render_references()
    end
end

ClickGUI.AddTab("VehicleForge", render_tab)

toast(("VehicleForge Premium %s loaded | %d references"):format(VERSION, #REFERENCES), 3500)
