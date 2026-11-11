-- ==============================================================================
-- VARIABLES GLOBALES 
-- ==============================================================================
local SCRIPT_NAME = "PVP Helper"
local SCRIPT_VERSION = "1.1.3"
local scriptHash = Utils.Joaat("PvpHelperFinal")

-- ==============================================================================
-- CONSOLE LOGGING & ASCII ART 
-- ==============================================================================
Logger.Log(eLogColor.CYAN, SCRIPT_NAME, "Loading '" .. SCRIPT_NAME .. "'")
Logger.Log(eLogColor.CYAN, SCRIPT_NAME, "\n" ..
"██████╗ ██╗   ██╗██████╗    ██╗  ██╗███████╗██╗     ██████╗ ███████╗██████╗ \n" ..
"██╔══██╗██║   ██║██╔══██╗   ██║  ██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗\n" ..
"██████╔╝██║   ██║██████╔╝   ███████║█████╗  ██║     ██████╔╝█████╗  ██████╔╝\n" ..
"██╔═══╝ ╚██╗ ██╔╝██╔═══╝    ██╔══██║██╔══╝  ██║     ██╔═══╝ ██╔══╝  ██╔══██╗\n" ..
"██║      ╚████╔╝ ██║        ██║  ██║███████╗███████╗██║     ███████╗██║  ██║\n" ..
"╚═╝       ╚═══╝  ╚═╝        ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝")
Logger.Log(eLogColor.CYAN, SCRIPT_NAME, "Initializing features...")

-- ==============================================================================
-- NATIVE WRAPPERS & ANTI-CRASH
-- ==============================================================================
local InvokeInt = function(hash, ...) local ok, res = pcall(Natives.InvokeInt, hash, ...); return ok and res or 0; end
local InvokeFloat = function(hash, ...) local ok, res = pcall(Natives.InvokeFloat, hash, ...); return ok and res or 0.0; end
local InvokeBool = function(hash, ...) local ok, res = pcall(Natives.InvokeBool, hash, ...); return ok and res or false; end
local InvokeString = function(hash, ...) local ok, res = pcall(Natives.InvokeString, hash, ...); return (ok and type(res) == "string") and res or "Unknown"; end
local InvokeVoid = function(hash, ...) pcall(Natives.InvokeVoid, hash, ...); end
local InvokeV3 = function(hash, ...) local ok, x, y, z = pcall(Natives.InvokeV3, hash, ...); if ok and x then return x, y, z else return 0.0, 0.0, 0.0; end end

local GET_ENTITY_COORDS = function(...) return InvokeV3(0x3FEF770D40960D5A, ...) end;
local GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS = function(...) return InvokeV3(0x1899F328B0E12848, ...) end;
local GET_CURRENT_PED_VEHICLE_WEAPON = function(...) return InvokeBool(0x1017582BCD3832DC, ...) end;
local GET_CURRENT_PED_WEAPON = function(...) return InvokeBool(0x3A87E44BB9A01D54, ...) end;
local IS_CONTROL_PRESSED = function(...) return InvokeInt(0xE2587F8CBBD87B1D, ...) end;
local IS_DISABLED_CONTROL_PRESSED = function(...) return InvokeInt(0xF3A21BCD95725A4A, ...) end;
local PLAYER_ID = function(...) return InvokeInt(0x4F8644AF03D0E0D6, ...) end;
local GET_ACTIVE_SCREEN_RESOLUTION = function(...) return InvokeVoid(0x873C9F3104101DD3, ...) end;
local DRAW_LINE = function(...) return InvokeVoid(0x6B7256074AE34680, ...) end;
local DISABLE_CONTROL_ACTION = function(...) return InvokeVoid(0xFE99B66D079CF6BC, ...) end;
local GET_ENTITY_VELOCITY = function(...) return InvokeV3(0x4805D2B1D8CF94A9, ...) end;
local GET_ENTITY_ROTATION = function(...) return InvokeV3(0xAFBD61CC738D9EB9, ...) end;
local GET_ENTITY_SPEED = function(...) return InvokeFloat(0xD5037BA82E12416F, ...) end;
local SET_ENTITY_ROTATION = function(...) return InvokeVoid(0x8524A8B0171D5E07, ...) end;
local SET_ENTITY_VELOCITY = function(...) return InvokeVoid(0x1C99BB7B6E96D16F, ...) end;
local SET_FORWARD_SPEED = function(...) return InvokeVoid(0xAB54A438726D25D5, ...) end;
local SHOOT_SINGLE_BULLET_BETWEEN_COORDS = function(...) return InvokeVoid(0x867654CBC7606F2C, ...) end;
local GET_VEHICLE_CLASS = function(...) return InvokeInt(0x29439776AAA00A62, ...) end;
local GET_ENTITY_MODEL = function(...) return InvokeInt(0x9F47B058362C84B5, ...) end;

local NETWORK_REQUEST_CONTROL_OF_ENTITY = function(...) return InvokeBool(0xB69317BF5E782347, ...) end
local NETWORK_HAS_CONTROL_OF_ENTITY = function(...) return InvokeBool(0x01BF60A500E28887, ...) end
local SET_NETWORK_ID_CAN_MIGRATE = function(...) return InvokeVoid(0xA670B3669F540A50, ...) end
local NETWORK_GET_NETWORK_ID_FROM_ENTITY = function(...) return InvokeInt(0xA11700682F3AD45C, ...) end
local SET_ENTITY_COORDS = function(...) return InvokeVoid(0x06843DA7060A026B, ...) end
local GET_VEHICLE_PED_IS_IN = function(...) return InvokeInt(0x9A9112A0FE9A4713, ...) end;
local ADD_EXPLOSION = function(...) return InvokeVoid(0xE3AD2BDBAEE269AC, ...) end;
local GET_PLAYER_NAME = function(...) return InvokeString(0x6D0DE6A7B5DA71F8, ...) end;

local BEGIN_TEXT_COMMAND_THEFEED_POST = function(...) return InvokeVoid(0x202709F4C58A0424, ...) end
local ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME = function(...) return InvokeVoid(0x6C188BE134E074AA, ...) end
local END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT = function(...) return InvokeVoid(0x1CCD9A37359072CF, ...) end
local END_TEXT_COMMAND_THEFEED_POST_TICKER = function(...) return InvokeVoid(0x2ED7843F8F801023, ...) end
local PLAY_SOUND_FRONTEND = function(...) return InvokeVoid(0x67C540AA08E4A6F5, ...) end

local GET_SELECTED_PED_WEAPON = function(...) return InvokeInt(0x0A6DB4965674D243, ...) end
local SET_PED_CURRENT_WEAPON_VISIBLE = function(...) return InvokeVoid(0x0725A4CCFDED9A70, ...) end
local GET_IS_TASK_ACTIVE = function(...) return InvokeBool(0xB0760331C7AA4155, ...) end
local FORCE_PED_AI_AND_ANIMATION_UPDATE = function(...) return InvokeVoid(0x2208438012482A1A, ...) end

local SET_ENTITY_INVINCIBLE = function(...) return InvokeVoid(0x3882114BDE571AD4, ...) end
local DELETE_ENTITY = function(handle)
    local ptr = Memory.AllocInt()
    if ptr ~= 0 then
        Memory.WriteInt(ptr, handle)
        pcall(Natives.InvokeVoid, 0xAE3CBE5BF394C9C9, ptr)
        Memory.Free(ptr)
    end
end

local NETWORK_SET_PLAYER_IS_PASSIVE = function(...) return InvokeVoid(0x1B857666604B1A74, ...) end;
local PLAYSTATS_SWITCH_PASSIVE_MODE = function(...) return InvokeVoid(0x35EEC6C2BC821A71, ...) end;

local SET_PED_AMMO = function(...) return InvokeVoid(0x14E56BC5B5DB6A19, ...) end
local HAS_PED_GOT_WEAPON = function(...) return InvokeBool(0x8DECB02F88F428BC, ...) end

-- Natives pour le Kill Logger
local GET_PED_SOURCE_OF_DEATH = function(...) return InvokeInt(0x1E98817B311AE98A, ...) end
local GET_PED_KILLER = function(...) return InvokeInt(0x93C8B64DEB84728C, ...) end
local IS_PED_DEAD_OR_DYING = function(...) return InvokeBool(0x3317DEDB88C95038, ...) end
local GET_ENTITY_TYPE = function(...) return InvokeInt(0x8ACD366038D14505, ...) end
local GET_PED_IN_VEHICLE_SEAT = function(...) return InvokeInt(0x22FD9B2080EFE213, ...) end
local NETWORK_GET_PLAYER_INDEX_FROM_PED = function(...) return InvokeInt(0x6C0E2E0125610278, ...) end

-- Nouvelles natives pour l'Auto-Heal & Line of Sight
local HAS_ENTITY_CLEAR_LOS_TO_ENTITY = function(...) return InvokeBool(0xFCDFF7B72D23A1AC, ...) end
local GET_ENTITY_HEALTH = function(...) return InvokeInt(0xEEF059FAD016D209, ...) end
local GET_PED_MAX_HEALTH = function(...) return InvokeInt(0x15D757606D170C3C, ...) end
local GET_PED_ARMOUR = function(...) return InvokeInt(0x9483AF821605B1D8, ...) end
local SET_PED_ARMOUR = function(...) return InvokeVoid(0x5BA652A0CD14DF2F, ...) end
local SET_ENTITY_HEALTH = function(...) return InvokeVoid(0x6B76DC1F3AE6E6A3, ...) end
local DOES_ENTITY_EXIST = function(...) return InvokeBool(0x7239B21A38F536BA, ...) end

local g_ptr = Memory.AllocInt()
EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
    if g_ptr ~= 0 then Memory.Free(g_ptr); g_ptr = 0 end
end)

-- Table globale pour contenir toutes les options et éviter la limite des 200 variables locales Lua
local F = {}
local lastErrors = {}

local function PrintLog(msg)
    if F.consoleLogToggle and F.consoleLogToggle:GetBoolValue() then 
        Logger.Log(eLogColor.CYAN, SCRIPT_NAME, msg) 
    end
end

local function PrintErrorSafe(msg, err)
    local errStr = tostring(err)
    local currentTime = Time.GetEpocheMs()
    if not lastErrors[errStr] or (currentTime - lastErrors[errStr] > 5000) then
        Logger.Log(eLogColor.RED, SCRIPT_NAME .. " [CRASH PREVENTED]", msg .. " | " .. errStr)
        lastErrors[errStr] = currentTime
    end
end

local function ErrorHandler(err) return debug.traceback(tostring(err), 2) end

local projectileModels = {
    [Utils.Joaat("w_ex_vehiclemissile_1")] = true, [Utils.Joaat("w_ex_vehiclemissile_2")] = true,
    [Utils.Joaat("w_ex_vehiclemissile_3")] = true, [Utils.Joaat("w_ex_vehiclemissile_4")] = true,
    [Utils.Joaat("w_lr_rpg_rocket")] = true, [Utils.Joaat("w_lr_homing_rocket")] = true,
    [Utils.Joaat("w_lr_firework_rocket")] = true, [Utils.Joaat("w_smg_flare")] = true,
    [Utils.Joaat("xm_prop_x17_missile_01a")] = true, [Utils.Joaat("xm_prop_x17_missile_02a")] = true
}

local allWeaponHashes = {
    "weapon_pistol", "weapon_combatpistol", "weapon_appistol", "weapon_pistol50", "weapon_snspistol", "weapon_heavypistol", "weapon_vintagepistol", "weapon_marksmanpistol", "weapon_revolver", "weapon_doubleaction", "weapon_raypistol", "weapon_ceramicpistol", "weapon_navyrevolver", "weapon_gadgetpistol", "weapon_pistol_mk2", "weapon_revolver_mk2",
    "weapon_microsmg", "weapon_smg", "weapon_assaultsmg", "weapon_combatpdw", "weapon_machinepistol", "weapon_minismg", "weapon_raycarbine", "weapon_smg_mk2", "weapon_tecpistol",
    "weapon_pumpshotgun", "weapon_sawnoffshotgun", "weapon_assaultshotgun", "weapon_bullpupshotgun", "weapon_musket", "weapon_heavyshotgun", "weapon_dbshotgun", "weapon_autoshotgun", "weapon_combatshotgun", "weapon_pumpshotgun_mk2",
    "weapon_assaultrifle", "weapon_carbinerifle", "weapon_advancedrifle", "weapon_specialcarbine", "weapon_bullpuprifle", "weapon_compactrifle", "weapon_militaryrifle", "weapon_heavyrifle", "weapon_tacticalrifle", "weapon_assaultrifle_mk2", "weapon_carbinerifle_mk2", "weapon_specialcarbine_mk2", "weapon_bullpuprifle_mk2",
    "weapon_mg", "weapon_combatmg", "weapon_gusenberg", "weapon_combatmg_mk2",
    "weapon_sniperrifle", "weapon_heavysniper", "weapon_marksmanrifle", "weapon_heavysniper_mk2", "weapon_marksmanrifle_mk2", "weapon_precisionrifle",
    "weapon_rpg", "weapon_grenadelauncher", "weapon_hominglauncher", "weapon_minigun", "weapon_firework", "weapon_railgun", "weapon_compactlauncher", "weapon_rayminigun", "weapon_emplauncher",
    "weapon_grenade", "weapon_stickybomb", "weapon_proxmine", "weapon_pipebomb", "weapon_smokegrenade", "weapon_bzgas", "weapon_molotov", "weapon_flare", "weapon_snowball", "weapon_flaregun", "weapon_stungun"
}

local explosiveDb = {
    [0xE2822A29] = { dmg = 250, delay = 130, burst = 0, reload = 0, speed = 1000 },
    [0x84D6FAFD] = { dmg = 250, delay = 50,  burst = 0, reload = 0, speed = 1000 },
    [0xBB1CB914] = { dmg = 250, delay = 130, burst = 0, reload = 0, speed = 1000 },
    [0x38F41EAB] = { dmg = 250, delay = 130, burst = 0, reload = 0, speed = 1000 },
    [0x01198592] = { dmg = 250, delay = 1500, burst = 0, reload = 0, speed = 150  },
    [0x0C472FE2] = { dmg = 230, delay = 330,  burst = 0, reload = 0, speed = 1500 },
    [0x39BC6683] = { dmg = 250, delay = 130,  burst = 7, reload = 3000, speed = 250  }
}

local missileDb = {
    [0x17E07C9A] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0x753A78F1] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0x8BB7C63E] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0x44BE17BD] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0x5E0C2C31] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0xB4F96934] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0x7E1B7CA3] = { dmg = 250, delay = 500,  burst = 2, reload = 2000, speed = 200 },
    [0xA4F8D586] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0x5EE33CCF] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0x504DA665] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0x6299C94F] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 },
    [0x3B955FA6] = { dmg = 250, delay = 1000, burst = 2, reload = 3000, speed = 200 },
    [0xBCE908DB] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0xCA46F87D] = { dmg = 250, delay = 1000, burst = 0, reload = 0,    speed = 200 },
    [0xF8A3939F] = { dmg = 250, delay = 1000, burst = 2, reload = 3000, speed = 200 },
    [0x1EF01D8A] = { dmg = 250, delay = 1000, burst = 2, reload = 3000, speed = 200 },
    [0xCF0896E0] = { dmg = 250, delay = 500,  burst = 2, reload = 2500, speed = 200 }
}

local standardMgDb = {
    [0x46B89C8E] = { dmg = 30,  delay = 50,  burst = 0, reload = 0, speed = 1000 },
    [0x0DCE6112] = { dmg = 23,  delay = 100, burst = 0, reload = 0, speed = 1000 },
    [0x5F1834E2] = { dmg = 100, delay = 80,  burst = 0, reload = 0, speed = 1000 },
    [0x9F03B25E] = { dmg = 35,  delay = 45,  burst = 0, reload = 0, speed = 1000 },
    [0x9AFF6376] = { dmg = 35,  delay = 60,  burst = 0, reload = 0, speed = 1000 },
    [0xD9322EDD] = { dmg = 35,  delay = 70,  burst = 0, reload = 0, speed = 1000 },
    [0x51B8D4E8] = { dmg = 100, delay = 85,  burst = 0, reload = 0, speed = 1000 },
    [0x419D8E15] = { dmg = 100, delay = 80,  burst = 0, reload = 0, speed = 1000 },
    [0xF4077EE7] = { dmg = 60,  delay = 110, burst = 0, reload = 0, speed = 1000 }
}

local function GetWeaponStats(hash) return missileDb[hash] or explosiveDb[hash] or standardMgDb[hash] end
local function IsWeaponMissile(hash) return missileDb[hash] ~= nil end

-- ==============================================================================
-- FEATURES CONFIGURATION (PACKED IN F TABLE)
-- ==============================================================================
F.aimbotToggle = FeatureMgr.AddFeature(scriptHash + 1, "Enable Magic Bullet", eFeatureType.Toggle, "Activates the magic bullet aimbot in vehicles and on foot.")
F.camLockToggle = FeatureMgr.AddFeature(scriptHash + 120, "Camera Lock On", eFeatureType.Toggle, "Locks camera on target when aiming (LT / Right Click).")
F.camLockStrengthSlider = FeatureMgr.AddFeature(scriptHash + 121, "Camera Lock Strength", eFeatureType.SliderInt, "Adjusts the precision and tracking speed of the camera.")
F.camLockStrengthSlider:SetLimitValues(1, 100); F.camLockStrengthSlider:SetIntValue(50)
F.camLockDeadzoneSlider = FeatureMgr.AddFeature(scriptHash + 122, "Camera Deadzone (px)", eFeatureType.SliderInt, "Stops moving camera when target is within this radius.")
F.camLockDeadzoneSlider:SetLimitValues(0, 500); F.camLockDeadzoneSlider:SetIntValue(30)
F.camLockDelaySlider = FeatureMgr.AddFeature(scriptHash + 123, "Camera Correction Delay (ms)", eFeatureType.SliderInt, "Delay between recalculating camera path (0 = instant).")
F.camLockDelaySlider:SetLimitValues(0, 1000); F.camLockDelaySlider:SetStepSize(10); F.camLockDelaySlider:SetIntValue(0)
F.autoFireToggle = FeatureMgr.AddFeature(scriptHash + 14, "Auto-Fire", eFeatureType.Toggle, "Automatically shoots when a valid target is locked.")
F.ghostAimToggle = FeatureMgr.AddFeature(scriptHash + 15, "Ghost Aim", eFeatureType.Toggle, "Disables default vehicle weapons to ONLY fire magic bullets.")
F.ghostAimToggle:SetBoolValue(true)

F.fastWeaponSwitchToggle = FeatureMgr.AddFeature(scriptHash + 87, "Fast Weapon Switch", eFeatureType.Toggle, "Bypasses weapon switch delays for rapid fire (RPG spam).")

F.giveAllAmmoBtn = FeatureMgr.AddFeature(scriptHash + 89, "Give All Ammo", eFeatureType.Button, "Fills up ammo for all weapons in inventory, including special ammo.", function()
    local okPed, localPed = pcall(GTA.GetLocalPed)
    if okPed and localPed and localPed:GetAddress() ~= 0 then
        local pedHandle = GTA.PointerToHandle(localPed)
        if pedHandle ~= 0 then
            for _, wName in ipairs(allWeaponHashes) do
                local hash = Utils.Joaat(wName)
                if HAS_PED_GOT_WEAPON(pedHandle, hash, false) then
                    SET_PED_AMMO(pedHandle, hash, 9999)
                end
            end
            PrintLog("[Inventory] Max Ammo given for all weapons.")
            pcall(function()
                BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
                ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("~g~Max Ammo Given!~s~\nAll weapons & special rounds refilled.")
                END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
            end)
        end
    end
end)

F.vehicleOnlyToggle = FeatureMgr.AddFeature(scriptHash + 16, "Vehicle Only Mode", eFeatureType.Toggle, "Aimbot will automatically disable itself when you are on foot.")
F.vehicleOnlyToggle:SetBoolValue(false)

F.aimModeCombo = FeatureMgr.AddFeature(scriptHash + 26, "Aiming Mode", eFeatureType.Combo, "Select the shape of the detection zone.")
F.aimModeCombo:SetList({[0] = "Camera (2D)", [1] = "Cone (3D)", [2] = "Cylinder Tube (3D)"})

F.allow360CameraToggle = FeatureMgr.AddFeature(scriptHash + 33, "360° Camera Lock (2D Mode)", eFeatureType.Toggle, "Locks targets on-screen even if your vehicle points away from them.")
F.allow360CameraToggle:SetBoolValue(true)

F.guidedMissileToggle = FeatureMgr.AddFeature(scriptHash + 300, "Enable Guided Missile Mode", eFeatureType.Toggle, "WARNING: Disables Magic Bullets. Takes control of real missiles in flight.")
F.hijackMissilesToggle = FeatureMgr.AddFeature(scriptHash + 301, "Hijack Enemy Missiles", eFeatureType.Toggle, "Magnet Mode: Redirects ALL missiles in the area.")
F.guidedMissileSpeed = FeatureMgr.AddFeature(scriptHash + 302, "Guided Missile Speed", eFeatureType.SliderInt, "Flight speed of the guided projectile.")
F.guidedMissileSpeed:SetLimitValues(50, 2000); F.guidedMissileSpeed:SetStepSize(50); F.guidedMissileSpeed:SetIntValue(250)

F.autoFlareToggle = FeatureMgr.AddFeature(scriptHash + 303, "Deploy Flares", eFeatureType.Toggle, "Automatically deploys flares against incoming missiles.")
F.autoPassiveToggle = FeatureMgr.AddFeature(scriptHash + 314, "Auto-Passive (True Passive)", eFeatureType.Toggle, "Activates real GTA Online Passive Mode when a missile is detected.")

F.flareDistSlider = FeatureMgr.AddFeature(scriptHash + 305, "Detection Range (m)", eFeatureType.SliderInt, "Distance to detect incoming missiles.")
F.flareDistSlider:SetLimitValues(50, 500); F.flareDistSlider:SetStepSize(10); F.flareDistSlider:SetIntValue(200)

F.flareCooldownSlider = FeatureMgr.AddFeature(scriptHash + 307, "Reaction Cooldown (ms)", eFeatureType.SliderInt, "Delay between defensive bursts.")
F.flareCooldownSlider:SetLimitValues(500, 5000); F.flareCooldownSlider:SetStepSize(100); F.flareCooldownSlider:SetIntValue(1000)

F.flareUpToggle = FeatureMgr.AddFeature(scriptHash + 308, "Direction: Up", eFeatureType.Toggle, "Spawns flares upwards.")
F.flareUpToggle:SetBoolValue(true)
F.flareDownToggle = FeatureMgr.AddFeature(scriptHash + 309, "Direction: Down", eFeatureType.Toggle, "Spawns flares downwards.")
F.flareForwardToggle = FeatureMgr.AddFeature(scriptHash + 310, "Direction: Forward", eFeatureType.Toggle, "Spawns flares forwards.")
F.flareBackwardToggle = FeatureMgr.AddFeature(scriptHash + 311, "Direction: Backward", eFeatureType.Toggle, "Spawns flares backwards.")
F.flareRightToggle = FeatureMgr.AddFeature(scriptHash + 312, "Direction: Right", eFeatureType.Toggle, "Spawns flares to the right.")
F.flareLeftToggle = FeatureMgr.AddFeature(scriptHash + 313, "Direction: Left", eFeatureType.Toggle, "Spawns flares to the left.")

F.instantRcToggle = FeatureMgr.AddFeature(scriptHash + 405, "Instant RC Explosion", eFeatureType.Toggle, "Press LB (Controller) or A (AZERTY Keyboard) to detonate your RC Bandito.")

F.bstBlockerToggle = FeatureMgr.AddFeature(scriptHash + 400, "Enable BST Blocker", eFeatureType.Toggle, "Automatically detects and destroys ALL nearby Bull Shark Testosterone drops.")
F.bstBlockerRadius = FeatureMgr.AddFeature(scriptHash + 401, "BST Blocker Radius (m)", eFeatureType.SliderInt, "Radius to search and destroy BST.")
F.bstBlockerRadius:SetLimitValues(0, 1000); F.bstBlockerRadius:SetStepSize(10); F.bstBlockerRadius:SetIntValue(100)

-- ==============================================================================
-- AUTO-SURVIVAL
-- ==============================================================================
F.autoHealToggle = FeatureMgr.AddFeature(scriptHash + 130, "Auto-Heal", eFeatureType.Toggle, "Automatically restores health progressively when low.")
F.healThresholdSlider = FeatureMgr.AddFeature(scriptHash + 131, "Auto-Heal Trigger (%)", eFeatureType.SliderInt, "Health % at which to start healing.")
F.healThresholdSlider:SetLimitValues(10, 100); F.healThresholdSlider:SetStepSize(5); F.healThresholdSlider:SetIntValue(50)
F.healStopSlider = FeatureMgr.AddFeature(scriptHash + 138, "Auto-Heal Stop (%)", eFeatureType.SliderInt, "Health % at which to stop healing.")
F.healStopSlider:SetLimitValues(10, 100); F.healStopSlider:SetStepSize(5); F.healStopSlider:SetIntValue(100)
F.healAmountSlider = FeatureMgr.AddFeature(scriptHash + 136, "Heal Amount per Tick", eFeatureType.SliderInt, "How much HP to add per tick.")
F.healAmountSlider:SetLimitValues(1, 100); F.healAmountSlider:SetStepSize(1); F.healAmountSlider:SetIntValue(25)
F.healRateSlider = FeatureMgr.AddFeature(scriptHash + 137, "Heal Tick Rate (ms)", eFeatureType.SliderInt, "Delay between each HP addition.")
F.healRateSlider:SetLimitValues(100, 5000); F.healRateSlider:SetStepSize(100); F.healRateSlider:SetIntValue(1000)

F.autoArmorToggle = FeatureMgr.AddFeature(scriptHash + 132, "Auto-Armor", eFeatureType.Toggle, "Automatically equips armor when depleted.")
F.armorThresholdSlider = FeatureMgr.AddFeature(scriptHash + 133, "Auto-Armor Trigger (%)", eFeatureType.SliderInt, "Armor % at which to re-equip.")
F.armorThresholdSlider:SetLimitValues(0, 90); F.armorThresholdSlider:SetStepSize(5); F.armorThresholdSlider:SetIntValue(20)

F.armorTypeCombo = FeatureMgr.AddFeature(scriptHash + 134, "Armor Type", eFeatureType.Combo, "Type of armor to equip.")
F.armorTypeCombo:SetList({
    [0] = "Super Light (20%)", 
    [1] = "Light (40%)", 
    [2] = "Standard (60%)", 
    [3] = "Heavy (80%)", 
    [4] = "Super Heavy (100%)"
})
F.armorTypeCombo:SetListIndex(4)

F.autoArmorCooldown = FeatureMgr.AddFeature(scriptHash + 135, "Armor Cooldown (ms)", eFeatureType.SliderInt, "Delay between automated armor equips.")
F.autoArmorCooldown:SetLimitValues(500, 5000); F.autoArmorCooldown:SetStepSize(100); F.autoArmorCooldown:SetIntValue(1000)

F.checkLosToggle = FeatureMgr.AddFeature(scriptHash + 53, "Check Line of Sight", eFeatureType.Toggle, "Does not target players hidden behind walls.")
F.checkLosToggle:SetBoolValue(true)

F.autoSwitchToggle = FeatureMgr.AddFeature(scriptHash + 50, "Auto-Switch Target", eFeatureType.Toggle, "Automatically switches to the next target after a kill.")
F.autoSwitchToggle:SetBoolValue(true)
F.switchDelaySlider = FeatureMgr.AddFeature(scriptHash + 51, "Switch Delay (ms)", eFeatureType.SliderInt, "Delay before locking onto the next target after a kill.")
F.switchDelaySlider:SetLimitValues(0, 2000); F.switchDelaySlider:SetStepSize(50); F.switchDelaySlider:SetIntValue(250)

F.predictiveAimToggle = FeatureMgr.AddFeature(scriptHash + 80, "Predictive Aim", eFeatureType.Toggle, "Calculates target velocity and shoots ahead of them.")
F.enforcePhysicalSpeedToggle = FeatureMgr.AddFeature(scriptHash + 85, "Force Hypersonic Speed", eFeatureType.Toggle, "Forces the magic bullet to physically fly at the custom speed.")
F.projectileSpeedSlider = FeatureMgr.AddFeature(scriptHash + 81, "Custom Projectile Speed (m/s)", eFeatureType.SliderInt, "Used if Auto-Detect is off.")
F.projectileSpeedSlider:SetLimitValues(50, 10000); F.projectileSpeedSlider:SetStepSize(50); F.projectileSpeedSlider:SetIntValue(500)

F.pingCompSlider = FeatureMgr.AddFeature(scriptHash + 86, "Ping Compensation (ms)", eFeatureType.SliderInt, "Adds extra lead time to counter network lag.")
F.pingCompSlider:SetLimitValues(0, 500); F.pingCompSlider:SetStepSize(10); F.pingCompSlider:SetIntValue(50)

F.strictBurstToggle = FeatureMgr.AddFeature(scriptHash + 82, "Strict Burst Control", eFeatureType.Toggle, "Syncs native and magic bullet delays to prevent double firing.")
F.strictBurstToggle:SetBoolValue(true)

F.smoothAimToggle = FeatureMgr.AddFeature(scriptHash + 12, "Smooth Aim Assist", eFeatureType.Toggle, "Disable this during stunt flying. (Vehicles only)")
F.smoothSpeedSlider = FeatureMgr.AddFeature(scriptHash + 13, "Smooth Aim Speed", eFeatureType.SliderInt, "Rotation speed. 1 = Slow, 100 = Instant.")
F.smoothSpeedSlider:SetLimitValues(1, 100); F.smoothSpeedSlider:SetIntValue(15)

F.snapVehicleToggle = FeatureMgr.AddFeature(scriptHash + 8, "Vehicle Snap", eFeatureType.Toggle, "Gives a small flick towards the target when shooting. (Vehicles only)")
F.flickDurationSlider = FeatureMgr.AddFeature(scriptHash + 9, "Flick Shot Duration (ms)", eFeatureType.SliderInt, "Duration of the 'Flick'.")
F.flickDurationSlider:SetLimitValues(10, 500); F.flickDurationSlider:SetStepSize(10); F.flickDurationSlider:SetIntValue(50)

F.targetPriorityCombo = FeatureMgr.AddFeature(scriptHash + 32, "Target Priority", eFeatureType.Combo, "Target selection criteria.")
F.targetPriorityCombo:SetList({[0] = "Crosshair / Radar Axis", [1] = "Closest Distance (3D)", [2] = "Lowest Health", [3] = "Highest Health"})

F.targetBoneCombo = FeatureMgr.AddFeature(scriptHash + 29, "Target Bone", eFeatureType.Combo, "Where to aim the magic bullets.")
F.targetBoneCombo:SetList({[0] = "Torso", [1] = "Head", [2] = "Feet (Explosives)"})

F.stickyLockToggle = FeatureMgr.AddFeature(scriptHash + 25, "Sticky Target", eFeatureType.Toggle, "Keeps the target locked even if they leave your FOV.")
F.checkHealthToggle = FeatureMgr.AddFeature(scriptHash + 52, "Strict Health Check", eFeatureType.Toggle, "Instantly stops shooting as soon as the target is dead.")
F.checkHealthToggle:SetBoolValue(true)

F.targetPlayerToggle = FeatureMgr.AddFeature(scriptHash + 23, "Target Players", eFeatureType.Toggle, "Directly targets the bodies of players.")
F.targetPlayerToggle:SetBoolValue(true)

F.excludeFriendsToggle = FeatureMgr.AddFeature(scriptHash + 24, "Exclude Friends", eFeatureType.Toggle, "Prevents the aimbot from locking onto your friends.")
F.excludeFriendsToggle:SetBoolValue(true)

local vehicleBlacklist = {}
local blacklistNames = {}
local lastBlacklistAction = {}
local bstLogged = {} 
local lastBstAction = {}
F.blacklistMasterToggle = FeatureMgr.AddFeature(scriptHash + 199, "Enable Vehicle Blacklist", eFeatureType.Toggle, "Turns the vehicle blacklist on/off.")
F.blacklistExcludeFriendsToggle = FeatureMgr.AddFeature(scriptHash + 201, "Exclude Friends from Blacklist", eFeatureType.Toggle, "Does not punish friends.")
F.blacklistExcludeFriendsToggle:SetBoolValue(true)
F.blacklistListCombo = FeatureMgr.AddFeature(scriptHash + 206, "Blacklisted Vehicles", eFeatureType.Combo, "List of currently blacklisted vehicles.")
F.blacklistListCombo:SetList({[0] = "None"})
local function UpdateBlacklistUI()
    local list = {}
    local i = 0
    for _, name in ipairs(blacklistNames) do list[i] = name; i = i + 1 end
    if i == 0 then list[0] = "None" end
    F.blacklistListCombo:SetList(list)
end
F.blacklistInputText = FeatureMgr.AddFeature(scriptHash + 202, "Vehicle Model Name", eFeatureType.InputText, "Type the model name (e.g. oppressor2)")
F.blAddBtn = FeatureMgr.AddFeature(scriptHash + 203, "Add to Blacklist", eFeatureType.Button, "Adds the name typed above to the list.", function()
    local mdl = F.blacklistInputText:GetStringValue()
    if mdl and mdl ~= "" then
        mdl = string.lower(mdl)
        local hash = Utils.Joaat(mdl)
        if not vehicleBlacklist[hash] then
            vehicleBlacklist[hash] = mdl; vehicleBlacklist[hash % 0x100000000] = mdl
            table.insert(blacklistNames, mdl); UpdateBlacklistUI()
            PrintLog("[Blacklist] Added " .. mdl .. " to blacklist.")
        end
    end
end)
F.blRemBtn = FeatureMgr.AddFeature(scriptHash + 204, "Remove from Blacklist", eFeatureType.Button, "Removes the name.", function()
    local mdl = F.blacklistInputText:GetStringValue()
    if mdl and mdl ~= "" then
        mdl = string.lower(mdl)
        local hash = Utils.Joaat(mdl)
        vehicleBlacklist[hash] = nil; vehicleBlacklist[hash % 0x100000000] = nil
        for i, name in ipairs(blacklistNames) do
            if name == mdl then table.remove(blacklistNames, i); break end
        end
        UpdateBlacklistUI()
    end
end)
F.blClearBtn = FeatureMgr.AddFeature(scriptHash + 205, "Clear Blacklist", eFeatureType.Button, "Clears the entire blacklist.", function()
    vehicleBlacklist = {}; blacklistNames = {}; UpdateBlacklistUI()
end)

F.drawFovToggle = FeatureMgr.AddFeature(scriptHash + 2, "Draw Radar", eFeatureType.Toggle, "Displays the main detection shape.")
F.drawFovToggle:SetBoolValue(true)
F.drawTargetToggle = FeatureMgr.AddFeature(scriptHash + 10, "Show Target Lock HUD", eFeatureType.Toggle, "Displays the lock-on brackets over the target.")
F.drawTargetToggle:SetBoolValue(true)
F.drawSpreadToggle = FeatureMgr.AddFeature(scriptHash + 45, "Draw Bullet Spread", eFeatureType.Toggle, "Displays the bullet spread radius.")
F.drawSpreadToggle:SetBoolValue(true)

F.visualizerLinesSlider = FeatureMgr.AddFeature(scriptHash + 31, "Visualizer Line Density", eFeatureType.SliderInt, "Number of lines (3D Wireframe).")
F.visualizerLinesSlider:SetLimitValues(4, 256); F.visualizerLinesSlider:SetIntValue(16)

F.colorFovCam = FeatureMgr.AddFeature(scriptHash + 40, "Color: Camera FOV (2D)", eFeatureType.InputColor4, ""); F.colorFovCam:SetColor(255, 255, 255, 180)
F.colorCone = FeatureMgr.AddFeature(scriptHash + 41, "Color: Cone (3D)", eFeatureType.InputColor4, ""); F.colorCone:SetColor(255, 255, 255, 180)
F.colorTube = FeatureMgr.AddFeature(scriptHash + 42, "Color: Cylinder (3D)", eFeatureType.InputColor4, ""); F.colorTube:SetColor(255, 0, 0, 180)
F.colorTargetLock = FeatureMgr.AddFeature(scriptHash + 43, "Color: Target Lock", eFeatureType.InputColor4, ""); F.colorTargetLock:SetColor(255, 0, 0, 255)
F.colorSpread = FeatureMgr.AddFeature(scriptHash + 44, "Color: Bullet Spread", eFeatureType.InputColor4, ""); F.colorSpread:SetColor(255, 165, 0, 200)

F.vehFovSlider = FeatureMgr.AddFeature(scriptHash + 27, "Cone Angle (Degrees)", eFeatureType.SliderInt, "Angle of the Cone radar.")
F.vehFovSlider:SetLimitValues(10, 360); F.vehFovSlider:SetStepSize(10); F.vehFovSlider:SetIntValue(90)
F.laserRadiusSlider = FeatureMgr.AddFeature(scriptHash + 28, "Cylinder Radius (m)", eFeatureType.SliderInt, "Radius of the Cylinder radar.")
F.laserRadiusSlider:SetLimitValues(1, 50); F.laserRadiusSlider:SetIntValue(5)
F.fovSlider = FeatureMgr.AddFeature(scriptHash + 3, "Camera FOV (Pixels)", eFeatureType.SliderInt, "Zone size for the 2D Camera radar.")
F.fovSlider:SetLimitValues(10, 1000); F.fovSlider:SetStepSize(10); F.fovSlider:SetIntValue(250)
F.rangeSlider = FeatureMgr.AddFeature(scriptHash + 4, "Max Range (Meters)", eFeatureType.SliderInt, "Maximum distance of the aimbot.")
F.rangeSlider:SetLimitValues(50, 6000); F.rangeSlider:SetStepSize(50); F.rangeSlider:SetIntValue(2000)

F.autoHandlingToggle = FeatureMgr.AddFeature(scriptHash + 71, "Auto-Detect Weapon Stats", eFeatureType.Toggle, "Automatically uses the hardcoded Database.")
F.bulletTypeCombo = FeatureMgr.AddFeature(scriptHash + 70, "Magic Bullet Type", eFeatureType.Combo, "Forces the weapon type. 'None' allows tracking without shooting.")
F.bulletTypeCombo:SetList({ [0] = "None (Lock Only)", [1] = "Current Weapon", [2] = "Lazer/Hydra Cannons", [3] = "Chernobog Missiles", [4] = "Heavy Sniper Mk2" })
F.bulletTypeCombo:SetListIndex(1)
F.bypassModeCombo = FeatureMgr.AddFeature(scriptHash + 110, "Obstacle Bypass Mode", eFeatureType.Combo, "How bullets bypass obstacles.")
F.bypassModeCombo:SetList({ [0] = "Off", [1] = "Front", [2] = "Top-Down", [3] = "Backstab" })
F.bypassDistSlider = FeatureMgr.AddFeature(scriptHash + 111, "Bypass Distance (m)", eFeatureType.SliderInt, "Distance from the target to spawn the bullet.")
F.bypassDistSlider:SetLimitValues(1, 50); F.bypassDistSlider:SetIntValue(1)

F.damageSlider = FeatureMgr.AddFeature(scriptHash + 17, "Bullet Damage", eFeatureType.SliderInt, "Damage dealt by each magic bullet.")
F.damageSlider:SetLimitValues(10, 10000); F.damageSlider:SetStepSize(10); F.damageSlider:SetIntValue(250)
F.spreadSlider = FeatureMgr.AddFeature(scriptHash + 11, "Bullet Spread", eFeatureType.SliderInt, "Bullet spread (0 = Perfect accuracy).")
F.spreadSlider:SetLimitValues(0, 100); F.spreadSlider:SetIntValue(20)
F.fireRateSlider = FeatureMgr.AddFeature(scriptHash + 6, "Guns Fire Rate (ms)", eFeatureType.SliderInt, "Delay between shots (Classic weapons).")
F.fireRateSlider:SetLimitValues(10, 1000); F.fireRateSlider:SetStepSize(10); F.fireRateSlider:SetIntValue(100)
F.missileRateSlider = FeatureMgr.AddFeature(scriptHash + 7, "Missiles Fire Rate (ms)", eFeatureType.SliderInt, "Delay between shots (Missiles).")
F.missileRateSlider:SetLimitValues(500, 5000); F.missileRateSlider:SetStepSize(100); F.missileRateSlider:SetIntValue(1500)
F.burstSizeSlider = FeatureMgr.AddFeature(scriptHash + 18, "Burst Size", eFeatureType.SliderInt, "Number of shots before reloading (0 = infinite).")
F.burstSizeSlider:SetLimitValues(0, 100); F.burstSizeSlider:SetIntValue(0)
F.reloadTimeSlider = FeatureMgr.AddFeature(scriptHash + 19, "Reload Time (ms)", eFeatureType.SliderInt, "Cooldown after a burst finishes.")
F.reloadTimeSlider:SetLimitValues(0, 10000); F.reloadTimeSlider:SetStepSize(100); F.reloadTimeSlider:SetIntValue(0)

F.enableKillLogToggle = FeatureMgr.AddFeature(scriptHash + 600, "Enable Kill Logger", eFeatureType.Toggle, "Logs session kills in format: [P1] 1 - 5 [P2]")
F.killLogMeOnlyToggle = FeatureMgr.AddFeature(scriptHash + 601, "Log Only My Kills", eFeatureType.Toggle, "If enabled, only logs kills involving you.")

F.debugToggle = FeatureMgr.AddFeature(scriptHash + 90, "Enable Debug HUD", eFeatureType.Toggle, "Shows weapon stats on screen.")
F.debugScannerToggle = FeatureMgr.AddFeature(scriptHash + 403, "Enable Entity Scanner", eFeatureType.Toggle, "Scans and logs entity hashes within 2 meters.")
F.consoleLogToggle = FeatureMgr.AddFeature(scriptHash + 91, "Enable Console Logs", eFeatureType.Toggle, "Prints targeting data to the console for debugging.")
F.unloadBtn = FeatureMgr.AddFeature(scriptHash + 100, "Unload Script", eFeatureType.Button, "Safely unloads the script.", function() SetShouldUnload() end)

-- ==============================================================================
-- LOGIC FUNCTIONS
-- ==============================================================================
local lockedPlayerId = -1
local lastFireTime = 0
local lastKillTime = 0
local burstShotsFired = 0
local lastWeaponHash = 0
local renderTargetPos = nil
local renderTargetDist = 0
local g_screenW, g_screenH = 1920, 1080
local friendsCache = {}
local lastFriendUpdate = 0
local activeGuidedMissiles = {}
local lastFlareTime = 0
local lastPassiveTrigger = 0
local lastRcExplosionTime = 0
local killScores = {}
local playerStates = {}
local cachedObjects = {}
local lastObjectCacheTime = 0

local lastHealTime = 0
local lastArmorTime = 0
local isHealingActive = false

local currentCamMoveX = 0.0
local currentCamMoveY = 0.0
local lastCamUpdateTime = 0

local function GetDistance2D(x1, y1, x2, y2) return math.sqrt((x2 - x1)^2 + (y2 - y1)^2) end
local function GetDistSq2D(x1, y1, x2, y2) return (x2 - x1)^2 + (y2 - y1)^2 end
local function GetDistSq(x1,y1,z1, x2,y2,z2) return (x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2 end

local function CalculateHeading(dx, dy)
    if dx == 0.0 and dy == 0.0 then return 0.0 end
    if math.atan2 then
        return math.deg(math.atan2(-dx, dy))
    else
        return math.deg(math.atan(-dx, dy))
    end
end

local function GetSafeVectors(handle)
    if handle == 0 then return 0,1,0, 1,0,0, 0,0,1, 0,0,0 end
    local pX, pY, pZ = GET_ENTITY_COORDS(handle, true)
    local fx, fy, fz = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 0.0, 1.0, 0.0)
    local rx, ry, rz = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 1.0, 0.0, 0.0)
    local ux, uy, uz = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 0.0, 0.0, 1.0)
    local fX, fY, fZ = fx - pX, fy - pY, fz - pZ
    local rX, rY, rZ = rx - pX, ry - pY, rz - pZ
    local uX, uY, uZ = ux - pX, uy - pY, uz - pZ
    local lenF = math.sqrt(fX*fX + fY*fY + fZ*fZ)
    if lenF > 0.001 then fX, fY, fZ = fX/lenF, fY/lenF, fZ/lenF end
    return fX, fY, fZ, rX, rY, rZ, uX, uY, uZ, pX, pY, pZ
end

local function GetCurrentWeaponHash(pedHandle, inVehicle)
    local ptr = Memory.AllocInt()
    local hash = 0
    if ptr ~= 0 then
        local ok, err = pcall(function() 
            if inVehicle then
                if GET_CURRENT_PED_VEHICLE_WEAPON(pedHandle, ptr) then hash = Memory.ReadInt(ptr) end 
            else
                if GET_CURRENT_PED_WEAPON(pedHandle, ptr, true) then hash = Memory.ReadInt(ptr) end 
            end
        end)
        Memory.Free(ptr)
        if not ok then PrintErrorSafe("WeaponHash Memory Error", err) end
    end
    return (hash == 0) and 0x46B89C8E or hash
end

local function GetMagicWeaponHash(pedHandle, inVehicle)
    local mode = F.bulletTypeCombo:GetListIndex()
    if mode == 2 then return 0xE2822A29 end
    if mode == 3 then return 0x01198592 end
    if mode == 4 then return 0x0C472FE2 end
    return GetCurrentWeaponHash(pedHandle, inVehicle)
end

local function IsPhysicalShootPressed(vehHandle)
    local isShooting = false
    local controls = {}
    if vehHandle == 0 then
        controls = {24}
    else
        local vehClass = GET_VEHICLE_CLASS(vehHandle)
        if vehClass == 15 or vehClass == 16 then
            controls = {114, 115}
        else
            controls = {68}
        end
    end
    for _, ctrl in ipairs(controls) do
        local pressed = IS_CONTROL_PRESSED(0, ctrl)
        local disabled = IS_DISABLED_CONTROL_PRESSED(0, ctrl)
        if pressed == 1 or pressed == true or disabled == 1 or disabled == true then return true end
    end
    return false
end

local function UpdateFriendsCache()
    local currentTime = Time.GetEpocheMs()
    if currentTime - lastFriendUpdate < 5000 then return end
    lastFriendUpdate = currentTime
    friendsCache = {}
    local okList, list = pcall(Players.Get, ePlayerListSort and ePlayerListSort.PLAYER_ID or 0)
    if okList and list then
        for _, pid in ipairs(list) do
            pcall(function()
                local netPlayer = Players.GetById(pid)
                if netPlayer and netPlayer:GetAddress() ~= 0 then
                    local pInfo = netPlayer.PlayerInfo
                    if pInfo and pInfo.FriendStatus and type(pInfo.FriendStatus) == "number" and pInfo.FriendStatus > 1 then
                        friendsCache[pid] = true
                    end
                end
            end)
        end
    end
end

local function ScanForBestTarget(lPosX, lPosY, lPosZ, fX, fY, fZ, localPedAddr, screenW, screenH, localHandle)
    if not F.targetPlayerToggle:GetBoolValue() then return -1 end
    local bestId, bestScore = -1, nil
    local localPid = PLAYER_ID()
    local is360Cam = F.allow360CameraToggle:GetBoolValue()
    local okList, list = pcall(Players.Get, ePlayerListSort and ePlayerListSort.PLAYER_ID or 0)
    local enforceLos = F.checkLosToggle:GetBoolValue() and (F.bypassModeCombo:GetListIndex() == 0)
    
    if okList and list then
        for _, pid in ipairs(list) do
            if pid ~= localPid and not (F.excludeFriendsToggle:GetBoolValue() and friendsCache[pid]) then
                local okPed, pPed = pcall(Players.GetCPed, pid)
                if okPed and pPed and pPed:GetAddress() ~= 0 and pPed:GetAddress() ~= localPedAddr then
                    local hp = 0
                    pcall(function() hp = pPed.Health end)
                    if (not F.checkHealthToggle:GetBoolValue()) or (type(hp) == "number" and hp > 0.0) then
                        local okPos, pos = pcall(function() return pPed.Position end)
                        if okPos and pos and (pos.x ~= 0 or pos.y ~= 0) then
                            local dx, dy, dz = pos.x - lPosX, pos.y - lPosY, pos.z - lPosZ
                            local distSq = GetDistSq(lPosX, lPosY, lPosZ, pos.x, pos.y, pos.z)
                            local maxRange = F.rangeSlider:GetIntValue()
                            
                            if distSq > 1.0 and distSq <= (maxRange * maxRange) then
                                local dist3D = math.sqrt(distSq)
                                local inFov, axisDist = false, 0
                                local mode = F.aimModeCombo:GetListIndex()
                                local dot = dx*fX + dy*fY + dz*fZ
                                local isForward = (dot > 0)
                                
                                if mode == 0 and (isForward or is360Cam) then
                                    local okS, sx, sy = pcall(GTA.WorldToScreen, pos.x, pos.y, pos.z)
                                    if okS and sx > 0.0 and sx < 1.0 and sy > 0.0 and sy < 1.0 then
                                        local dist2DSq = GetDistSq2D(screenW/2, screenH/2, sx*screenW, sy*screenH)
                                        local fovVal = F.fovSlider:GetIntValue()
                                        if dist2DSq <= (fovVal * fovVal) then inFov, axisDist = true, math.sqrt(dist2DSq) end
                                    end
                                elseif mode == 1 and isForward then
                                    local cosA = math.max(-1, math.min(1, dot / dist3D))
                                    local ang = math.deg(math.acos(cosA))
                                    if ang <= (F.vehFovSlider:GetIntValue() / 2) then inFov, axisDist = true, ang end
                                elseif mode == 2 and isForward then
                                    local crossX, crossY, crossZ = dy*fZ - dz*fY, dz*fX - dx*fZ, dx*fY - dy*fX
                                    local distAxisSq = crossX*crossX + crossY*crossY + crossZ*crossZ
                                    local radius = F.laserRadiusSlider:GetIntValue()
                                    if distAxisSq <= (radius * radius) then inFov, axisDist = true, math.sqrt(distAxisSq) end
                                end
                                
                                if inFov then
                                    local hasLos = true
                                    if enforceLos and localHandle ~= 0 then
                                        local pPedHandle = GTA.PointerToHandle(pPed)
                                        if pPedHandle ~= 0 then
                                            hasLos = HAS_ENTITY_CLEAR_LOS_TO_ENTITY(localHandle, pPedHandle, 17)
                                        end
                                    end
                                    
                                    if hasLos then
                                        local modeP = F.targetPriorityCombo:GetListIndex()
                                        local score = (modeP == 0 and axisDist) or (modeP == 1 and dist3D) or (modeP == 2 and hp) or (modeP == 3 and -hp) or dist3D
                                        if (bestScore == nil) or (score < bestScore) then bestScore, bestId = score, pid end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestId
end

-- ==============================================================================
-- EVENT HANDLERS
-- ==============================================================================
EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_LEFT, function(pid)
    if type(pid) == "number" then
        if lockedPlayerId == pid then
            lockedPlayerId = -1; renderTargetPos = nil; lastKillTime = Time.GetEpocheMs()
        end
        playerStates[pid] = nil
    end
end)

EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
    local okScreen, screenW, screenH = pcall(ImGui.GetDisplaySize)
    if okScreen and screenW and screenH then g_screenW, g_screenH = screenW, screenH end

    if F.debugToggle:GetBoolValue() then
        local currentWeaponHash = 0
        local okPed, localPed = pcall(GTA.GetLocalPed)
        if okPed and localPed and localPed:GetAddress() ~= 0 then
            local pedHandle = GTA.PointerToHandle(localPed)
            local okVeh, localVeh = pcall(GTA.GetLocalVehicle)
            local inVehicle = okVeh and localVeh and localVeh:GetAddress() ~= 0
            pcall(function() currentWeaponHash = GetCurrentWeaponHash(pedHandle, inVehicle) end)
        end
        local txt = string.format("PVP Helper Debug\nWeapon Hash: 0x%08X\nIs Missile: %s\nBurst Fired: %d\nLocked Target ID: %d\nObj Cache Size: %d", 
                                   currentWeaponHash % 0x100000000, tostring(IsWeaponMissile(currentWeaponHash)), burstShotsFired, lockedPlayerId, #cachedObjects)
        ImGui.BgAddText(20, 20, txt, 0, 255, 0, 255)
    end

    if not F.aimbotToggle:GetBoolValue() and not F.guidedMissileToggle:GetBoolValue() and not F.camLockToggle:GetBoolValue() then return end

    local centerX, centerY = g_screenW / 2, g_screenH / 2
    local aimMode = F.aimModeCombo:GetListIndex()

    if F.drawFovToggle:GetBoolValue() and aimMode == 0 then
        local r, g, b, a = F.colorFovCam:GetColor()
        ImGui.BgAddCircle(centerX, centerY, F.fovSlider:GetIntValue(), r or 255, g or 255, b or 255, a or 180, 100, 2.0)
        
        if F.camLockToggle:GetBoolValue() then
            local dz = F.camLockDeadzoneSlider:GetIntValue()
            if dz > 0 then
                ImGui.BgAddCircle(centerX, centerY, dz, 255, 50, 50, 180, 64, 1.5)
            end
        end
    end

    if renderTargetPos then
        local ok, tX, tY = pcall(GTA.WorldToScreen, renderTargetPos.x, renderTargetPos.y, renderTargetPos.z)
        if ok and tX > 0.0 and tX < 1.0 and tY > 0.0 and tY < 1.0 then
            local px, py = tX * g_screenW, tY * g_screenH
            if F.drawTargetToggle:GetBoolValue() then
                local lr, lg, lb, la = F.colorTargetLock:GetColor()
                lr, lg, lb, la = lr or 255, lg or 0, lb or 0, la or 255
                local size = 15
                ImGui.BgAddLine(px - size, py - size, px - size/2, py - size, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px - size, py - size, px - size, py - size/2, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px + size, py - size, px + size/2, py - size, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px + size, py - size, px + size, py - size/2, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px - size, py + size, px - size/2, py + size, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px - size, py + size, px - size, py - size/2, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px + size, py + size, px + size/2, py + size, lr, lg, lb, la, 2.0)
                ImGui.BgAddLine(px + size, py + size, px + size, py + size/2, lr, lg, lb, la, 2.0)
                ImGui.BgAddText(px - 15, py + size + 5, string.format("%.0fm", renderTargetDist), lr, lg, lb, la)
            end
            if F.drawSpreadToggle:GetBoolValue() and F.aimbotToggle:GetBoolValue() then
                local spreadMeters = F.spreadSlider:GetIntValue() / 10.0
                if spreadMeters > 0 then
                    local okT, topX, topY = pcall(GTA.WorldToScreen, renderTargetPos.x, renderTargetPos.y, renderTargetPos.z + spreadMeters)
                    if okT and topX > 0.0 then
                        local radiusPixels = math.sqrt(GetDistSq2D(topX * g_screenW, topY * g_screenH, px, py))
                        local sr, sg, sb, sa = F.colorSpread:GetColor()
                        ImGui.BgAddCircle(px, py, radiusPixels, sr or 255, sg or 165, sb or 0, sa or 200, 64, 1.5)
                    end
                end
            end
        end
    end
end)

-- ==============================================================================
-- MAIN LOOP
-- ==============================================================================
local isFirstTick = true

Script.RegisterLooped(function()
    local status, err = xpcall(function()
        
        if isFirstTick then
            pcall(function()
                BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
                ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("~y~" .. SCRIPT_NAME .. " v" .. SCRIPT_VERSION .. "~s~\nAll modules loaded successfully.\nHappy Hunting!")
                END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT("CHAR_MP_MERRYWEATHER", "CHAR_MP_MERRYWEATHER", true, 4, SCRIPT_NAME, "~c~System Online")
                END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
                PLAY_SOUND_FRONTEND(-1, "Hack_Success", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
                Logger.Log(eLogColor.CYAN, SCRIPT_NAME, "Successfully loaded '" .. SCRIPT_NAME .. "'")
            end)
            isFirstTick = false
        end

        UpdateFriendsCache()
        local currentTime = Time.GetEpocheMs()
        local useGuidedMissile = F.guidedMissileToggle:GetBoolValue()
        local useMagicBullets = F.aimbotToggle:GetBoolValue() and not useGuidedMissile
        
        if (currentTime - lastObjectCacheTime) > 500 then
            lastObjectCacheTime = currentTime
            cachedObjects = {}
            pcall(function()
                local count = PoolMgr.GetCurrentObjectCount()
                if type(count) == "number" and count > 0 then
                    for i = 0, count - 1 do
                        local ptr = PoolMgr.GetCObject(i)
                        if ptr and ptr:GetAddress() ~= 0 then
                            local h = GTA.PointerToHandle(ptr)
                            if h ~= 0 then table.insert(cachedObjects, h) end
                        end
                    end
                end
                local pCount = PoolMgr.GetCurrentPickupCount()
                if type(pCount) == "number" and pCount > 0 then
                    for i = 0, pCount - 1 do
                        local ptr = PoolMgr.GetCPickup(i)
                        if ptr and ptr:GetAddress() ~= 0 then
                            local h = GTA.PointerToHandle(ptr)
                            if h ~= 0 then table.insert(cachedObjects, h) end
                        end
                    end
                end
            end)
        end

        if F.enableKillLogToggle:GetBoolValue() then
            local okList, list = pcall(Players.Get, ePlayerListSort and ePlayerListSort.PLAYER_ID or 0)
            if okList and list then
                for _, pid in ipairs(list) do
                    local okPed, pPed = pcall(Players.GetCPed, pid)
                    if okPed and pPed and pPed:GetAddress() ~= 0 then
                        local pedHandle = GTA.PointerToHandle(pPed)
                        
                        local hp = InvokeInt(0xEEF059FAD016D209, pedHandle) 
                        local isDead = false
                        
                        pcall(function()
                            if hp <= 0 then isDead = true end
                            if not isDead and type(pPed.Health) == "number" and pPed.Health <= 0.0 and pPed.Position and pPed.Position.x ~= 0.0 then isDead = true end
                        end)
                        
                        if not playerStates[pid] then playerStates[pid] = { isDead = false } end
                        
                        if isDead then
                            if not playerStates[pid].isDead then
                                playerStates[pid].isDead = true
                                
                                local attackerHandle = InvokeInt(0x1E98817B311AE98A, pedHandle)
                                
                                if attackerHandle ~= 0 then
                                    local attackerType = InvokeInt(0x8ACD366038D14505, attackerHandle)
                                    local attackerPed = attackerHandle
                                    
                                    if attackerType == 2 then
                                        attackerPed = InvokeInt(0x22FD9B2080EFE213, attackerHandle, -1)
                                    end
                                    
                                    if attackerPed ~= 0 then
                                        local attackerPid = InvokeInt(0x6C0E2E0125610278, attackerPed)
                                        
                                        if attackerPid == -1 then
                                            for _, otherPid in ipairs(list) do
                                                local okOther, otherPed = pcall(Players.GetCPed, otherPid)
                                                if okOther and otherPed and otherPed:GetAddress() ~= 0 then
                                                    if GTA.PointerToHandle(otherPed) == attackerPed then
                                                        attackerPid = otherPid
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                        
                                        if attackerPid ~= -1 and attackerPid ~= pid then
                                            if not killScores[attackerPid] then killScores[attackerPid] = {} end
                                            if not killScores[pid] then killScores[pid] = {} end
                                            
                                            killScores[attackerPid][pid] = (killScores[attackerPid][pid] or 0) + 1
                                            
                                            local scoreA = killScores[attackerPid][pid]
                                            local scoreB = killScores[pid][attackerPid] or 0
                                            
                                            local attackerName = GET_PLAYER_NAME(attackerPid)
                                            local victimName = GET_PLAYER_NAME(pid)
                                            
                                            local logMsg = string.format("[%s] %d - %d [%s]", attackerName, scoreA, scoreB, victimName)
                                            
                                            local myPid = PLAYER_ID()
                                            local onlyMyKills = F.killLogMeOnlyToggle:GetBoolValue()
                                            
                                            if not onlyMyKills or (attackerPid == myPid or pid == myPid) then
                                                PrintLog("[Kill Log] " .. logMsg)
                                                pcall(function()
                                                    BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
                                                    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("~r~" .. logMsg)
                                                    END_TEXT_COMMAND_THEFEED_POST_TICKER(false, false)
                                                end)
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            playerStates[pid].isDead = false
                        end
                    end
                end
            end
        end

        if F.blacklistMasterToggle:GetBoolValue() then
            local okList, list = pcall(Players.Get, ePlayerListSort and ePlayerListSort.PLAYER_ID or 0)
            if okList and list then
                local localPid = PLAYER_ID()
                for _, pid in ipairs(list) do
                    if pid ~= localPid and not (F.blacklistExcludeFriendsToggle:GetBoolValue() and friendsCache[pid]) then
                        if not lastBlacklistAction[pid] or (currentTime - lastBlacklistAction[pid] > 500) then
                            local okPed, pPed = pcall(Players.GetCPed, pid)
                            if okPed and pPed and pPed:GetAddress() ~= 0 then
                                local pedHandle = GTA.PointerToHandle(pPed)
                                if pedHandle ~= 0 then
                                    local targetVehHandle = GET_VEHICLE_PED_IS_IN(pedHandle, false)
                                    if targetVehHandle ~= 0 then
                                        local vHash = GET_ENTITY_MODEL(targetVehHandle)
                                        local isBlacklisted = vehicleBlacklist[vHash] or vehicleBlacklist[vHash % 0x100000000]
                                        if isBlacklisted then
                                            local vX, vY, vZ = GET_ENTITY_COORDS(targetVehHandle, true)
                                            if vX ~= 0.0 then
                                                pcall(Natives.InvokeVoid, 0xE3AD2BDBAEE269AC, vX, vY, vZ, 2, 99999.0, false, true, 0.0, false)
                                                lastBlacklistAction[pid] = currentTime
                                                PrintLog("[Blacklist] Vehicle destroyed for player: " .. tostring(GET_PLAYER_NAME(pid)))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local okPed, localPed = pcall(GTA.GetLocalPed)
        if not okPed or not localPed or localPed:GetAddress() == 0 then return end
        
        local vehHandle = 0
        local okVeh, localVeh = pcall(GTA.GetLocalVehicle)
        if okVeh and localVeh and localVeh:GetAddress() ~= 0 then vehHandle = GTA.PointerToHandle(localVeh) end
        local pedHandle = GTA.PointerToHandle(localPed)
        
        if (F.autoHealToggle:GetBoolValue() or F.autoArmorToggle:GetBoolValue()) and pedHandle ~= 0 then
            local isDead = IS_PED_DEAD_OR_DYING(pedHandle, true)
            if not isDead then
                
                if F.autoHealToggle:GetBoolValue() then
                    if (currentTime - lastHealTime) > F.healRateSlider:GetIntValue() then
                        local maxHealth = GET_PED_MAX_HEALTH(pedHandle)
                        local currentHealth = GET_ENTITY_HEALTH(pedHandle)
                        
                        if maxHealth > 0 and currentHealth > 0 then
                            local healthPct = (currentHealth / maxHealth) * 100.0
                            local triggerPct = F.healThresholdSlider:GetIntValue()
                            local stopPct = F.healStopSlider:GetIntValue()
                            
                            if stopPct < triggerPct then stopPct = triggerPct end
                            
                            if healthPct <= triggerPct then
                                isHealingActive = true
                            elseif healthPct >= stopPct then
                                isHealingActive = false
                            end
                            
                            if isHealingActive then
                                local healAmount = F.healAmountSlider:GetIntValue()
                                local newHealth = currentHealth + healAmount
                                local targetMaxHealth = (maxHealth * stopPct) / 100.0
                                
                                if newHealth > targetMaxHealth then newHealth = targetMaxHealth end
                                SET_ENTITY_HEALTH(pedHandle, math.floor(newHealth))
                                lastHealTime = currentTime
                            end
                        end
                    end
                else
                    isHealingActive = false
                end
                
                if F.autoArmorToggle:GetBoolValue() then
                    if (currentTime - lastArmorTime) > F.autoArmorCooldown:GetIntValue() then
                        local currentArmor = GET_PED_ARMOUR(pedHandle)
                        local armorType = F.armorTypeCombo:GetListIndex()
                        local targetArmor = 100
                        if armorType == 0 then targetArmor = 20
                        elseif armorType == 1 then targetArmor = 40
                        elseif armorType == 2 then targetArmor = 60
                        elseif armorType == 3 then targetArmor = 80
                        elseif armorType == 4 then targetArmor = 100 end
                        
                        if currentArmor < targetArmor then
                            local armorPct = (currentArmor / targetArmor) * 100.0
                            if armorPct <= F.armorThresholdSlider:GetIntValue() then
                                SET_PED_ARMOUR(pedHandle, targetArmor)
                                lastArmorTime = currentTime
                                PrintLog("[Auto-Survival] Armor Replenished to " .. targetArmor .. ".")
                            end
                        end
                    end
                end
            end
        else
            isHealingActive = false
        end

        if F.instantRcToggle and F.instantRcToggle:GetBoolValue() then
            local checkVeh = vehHandle
            if checkVeh == 0 then pcall(function() checkVeh = GET_VEHICLE_PED_IS_IN(pedHandle, false) end) end
            
            local vModel = 0
            if checkVeh and checkVeh ~= 0 then pcall(function() vModel = GET_ENTITY_MODEL(checkVeh) end) end
            local pModel = 0
            pcall(function() pModel = GET_ENTITY_MODEL(pedHandle) end)
            
            local isRC = false
            local banditoSigned = -286046740
            local banditoUnsigned = 4008920556
            if vModel == Utils.Joaat("rcbandito") or vModel == banditoSigned or vModel == banditoUnsigned or (vModel % 0x100000000) == 0xEEF345EC then isRC = true end
            if pModel == Utils.Joaat("rcbandito") or pModel == banditoSigned or pModel == banditoUnsigned or (pModel % 0x100000000) == 0xEEF345EC then isRC = true end
            
            if isRC then
                local isTriggered = false
                local function IsPressed(ctrl)
                    local p = IS_CONTROL_PRESSED(0, ctrl)
                    local d = IS_DISABLED_CONTROL_PRESSED(0, ctrl)
                    return (p == 1 or p == true or d == 1 or d == true)
                end
                
                local isUsingKB = InvokeBool(0xA571D46727E2B718, 0)
                if not isUsingKB then
                    if IsPressed(68) then isTriggered = true end
                else
                    if IsPressed(44) then isTriggered = true end
                end
                
                if isTriggered and (currentTime - lastRcExplosionTime) > 2000 then
                    local targetToExplode = (checkVeh ~= 0) and checkVeh or pedHandle
                    local vx, vy, vz = GET_ENTITY_COORDS(targetToExplode, true)
                    
                    pcall(Natives.InvokeVoid, 0x6B76DC1F3AE6E6A3, targetToExplode, 0) 
                    pcall(Natives.InvokeVoid, 0x172AA1B624FA1013, pedHandle, vx, vy, vz, 2, 9999.0, 1, 0, 1.0) 
                    pcall(Natives.InvokeVoid, 0xE3AD2BDBAEE269AC, vx, vy, vz, 2, 9999.0, 1, 0, 1.0)
                    
                    lastRcExplosionTime = currentTime
                    PrintLog("[RC Explosion] Detonated RC Bandito!")
                end
            end
        end

        if F.fastWeaponSwitchToggle:GetBoolValue() and pedHandle ~= 0 and GET_IS_TASK_ACTIVE(pedHandle, 56) then FORCE_PED_AI_AND_ANIMATION_UPDATE(pedHandle, false, false) end

        if not useMagicBullets and not useGuidedMissile and not F.autoFlareToggle:GetBoolValue() and not F.autoPassiveToggle:GetBoolValue() and not F.bstBlockerToggle:GetBoolValue() and not F.camLockToggle:GetBoolValue() then
            lockedPlayerId = -1; renderTargetPos = nil
            return
        end
        
        local entHandle = (vehHandle ~= 0) and vehHandle or pedHandle
        local fX, fY, fZ, rX, rY, rZ, uX, uY, uZ, vX, vY, vZ = GetSafeVectors(entHandle)

        -- ==========================================
        -- BST BLOCKER LOGIC (BRUTE-FORCE MEMORY TP)
        -- ==========================================
        if F.bstBlockerToggle:GetBoolValue() then
            local radius = F.bstBlockerRadius:GetIntValue() * 1.0
            local radiusSq = radius * radius
            local isDebug = F.debugToggle:GetBoolValue()
            local isScannerOn = F.debugScannerToggle:GetBoolValue()
            
            local bstHashes = {
                [Utils.Joaat("prop_mp_bull_shark")] = true,
                [Utils.Joaat("prop_mp_bull_shark") % 0x100000000] = true,
                [Utils.Joaat("prop_bull_shark_01")] = true,
                [Utils.Joaat("prop_bull_shark_01") % 0x100000000] = true,
                [Utils.Joaat("prop_bs_test_01")] = true,
                [Utils.Joaat("prop_bs_test_01") % 0x100000000] = true,
                [Utils.Joaat("prop_cs_bs_test_01")] = true,
                [Utils.Joaat("prop_cs_bs_test_01") % 0x100000000] = true,
                [Utils.Joaat("prop_drug_package_02")] = true,
                [Utils.Joaat("prop_drug_package_02") % 0x100000000] = true,
                [0x2C0147B1] = true, 
                [0x1E9A99F8] = true  
            }
            
            for _, objHandle in ipairs(cachedObjects) do
                if DOES_ENTITY_EXIST(objHandle) then
                    local modelHash = InvokeInt(0x9F47B058362C84B5, objHandle)
                    local normHash = modelHash % 0x100000000
                    
                    local mX, mY, mZ = GET_ENTITY_COORDS(objHandle, true)
                    local distSq = GetDistSq(mX, mY, mZ, vX, vY, vZ)
                    
                    if isScannerOn and distSq < 4.0 then
                        if not lastBstAction[objHandle] or (currentTime - lastBstAction[objHandle] > 3000) then
                            PrintLog("[Debug-Scanner] Entite a vos pieds | Handle: " .. tostring(objHandle) .. " | Hash: " .. tostring(modelHash) .. " | NormHash: " .. tostring(normHash))
                            lastBstAction[objHandle] = currentTime
                        end
                    end
                    
                    if bstHashes[modelHash] or bstHashes[normHash] then
                        if distSq <= radiusSq then
                            
                            -- FIX: Téléportation RAM instantanée (N'attend pas la permission réseau)
                            local ptr = nil
                            pcall(function() ptr = GTA.HandleToPointer(objHandle) end)
                            if ptr and ptr:GetAddress() ~= 0 then
                                pcall(function() 
                                    ptr.Position = V3.New(0.0, 0.0, -10000.0) 
                                    ptr.IsVisible = false
                                end)
                            end
                            
                            pcall(Natives.InvokeVoid, 0x3288D8ACAECD2AB2, objHandle, false, false) -- Désactive la collision
                            pcall(Natives.InvokeVoid, 0x06843DA7060A026B, objHandle, 0.0, 0.0, -10000.0, 0, 0, 1, 0) -- SET_ENTITY_COORDS natif
                            
                            local hasControl = NETWORK_HAS_CONTROL_OF_ENTITY(objHandle)
                            if not hasControl then
                                local netId = NETWORK_GET_NETWORK_ID_FROM_ENTITY(objHandle)
                                if netId ~= 0 then InvokeVoid(0xA670B3669F540A50, netId, 1) end
                                InvokeBool(0xB69317BF5E782347, objHandle) 
                            else
                                InvokeVoid(0xAD738C3085FE7E11, objHandle, true, true) -- SET_ENTITY_AS_MISSION_ENTITY
                                DELETE_ENTITY(objHandle)
                            end
                            
                            if not bstLogged[objHandle] then
                                if isDebug then
                                    PrintLog("[Debug-BST] BST Blocked (Brute-forced via Memory).")
                                else
                                    PrintLog("[Environment] Blocked nearby BST drop.")
                                end
                                bstLogged[objHandle] = true
                            end
                        end
                    end
                end
            end
        end

        if F.vehicleOnlyToggle:GetBoolValue() and vehHandle == 0 then
            lockedPlayerId = -1; renderTargetPos = nil
            return
        end

        local ptrW, ptrH = Memory.AllocInt(), Memory.AllocInt()
        GET_ACTIVE_SCREEN_RESOLUTION(ptrW, ptrH)
        local screenW, screenH = Memory.ReadInt(ptrW), Memory.ReadInt(ptrH)
        Memory.Free(ptrW); Memory.Free(ptrH)
        if screenW <= 0 or screenH <= 0 then screenW, screenH = 1920, 1080 end

        local hoveredId = ScanForBestTarget(vX, vY, vZ, fX, fY, fZ, localPed:GetAddress(), screenW, screenH, entHandle)

        local aimMode = F.aimModeCombo:GetListIndex()
        if F.drawFovToggle:GetBoolValue() and aimMode > 0 then
            local visualRange = F.rangeSlider:GetIntValue()
            local linesCount = F.visualizerLinesSlider:GetIntValue()
            local angleStep = 360 / linesCount
            local startX, startY, startZ = vX + (fX * 6.0) + (uX * 0.5), vY + (fY * 6.0) + (uY * 0.5), vZ + (fZ * 6.0) + (uZ * 0.5)
            local cx, cy, cz = startX + fX * visualRange, startY + fY * visualRange, startZ + fZ * visualRange

            if aimMode == 1 then
                local cr, cg, cb, ca = F.colorCone:GetColor()
                cr, cg, cb, ca = cr or 255, cg or 255, cb or 255, ca or 180
                DRAW_LINE(startX, startY, startZ, cx, cy, cz, cr, cg, cb, ca)
                local fovAngle = F.vehFovSlider:GetIntValue()
                local baseRadius = math.tan(math.rad(fovAngle / 2)) * visualRange
                local prevPX, prevPY, prevPZ, firstPX, firstPY, firstPZ
                for i = 0, linesCount do
                    local a = math.rad(i * angleStep)
                    local offX = (rX * math.cos(a) + uX * math.sin(a)) * baseRadius
                    local offY = (rY * math.cos(a) + uY * math.sin(a)) * baseRadius
                    local offZ = (rZ * math.cos(a) + uZ * math.sin(a)) * baseRadius
                    local px, py, pz = cx + offX, cy + offY, cz + offZ
                    DRAW_LINE(startX, startY, startZ, px, py, pz, cr, cg, cb, math.floor(ca * 0.4))
                    if prevPX then DRAW_LINE(prevPX, prevPY, prevPZ, px, py, pz, cr, cg, cb, ca) else firstPX, firstPY, firstPZ = px, py, pz end
                    prevPX, prevPY, prevPZ = px, py, pz
                end
                if prevPX and firstPX then DRAW_LINE(prevPX, prevPY, prevPZ, firstPX, firstPY, firstPZ, cr, cg, cb, ca) end
            elseif aimMode == 2 then
                local tr, tg, tb, ta = F.colorTube:GetColor()
                tr, tg, tb, ta = tr or 255, tg or 0, tb or 0, ta or 180
                DRAW_LINE(startX, startY, startZ, cx, cy, cz, tr, tg, tb, ta)
                local laserRadius = F.laserRadiusSlider:GetIntValue()
                local prevSX, prevSY, prevSZ, prevEX, prevEY, prevEZ, firstSX, firstSY, firstSZ, firstEX, firstEY, firstEZ
                for i = 0, linesCount do
                    local a = math.rad(i * angleStep)
                    local offX = (rX * math.cos(a) + uX * math.sin(a)) * laserRadius
                    local offY = (rY * math.cos(a) + uY * math.sin(a)) * laserRadius
                    local offZ = (rZ * math.cos(a) + uZ * math.sin(a)) * laserRadius
                    local sx, sy, sz = startX + offX, startY + offY, startZ + offZ
                    local ex, ey, ez = cx + offX, cy + offY, cz + offZ
                    DRAW_LINE(sx, sy, sz, ex, ey, ez, tr, tg, tb, math.floor(ta * 0.4))
                    if prevSX then
                        DRAW_LINE(prevSX, prevSY, prevSZ, sx, sy, sz, tr, tg, tb, ta)
                        DRAW_LINE(prevEX, prevEY, prevEZ, ex, ey, ez, tr, tg, tb, ta)
                    else
                        firstSX, firstSY, firstSZ, firstEX, firstEY, firstEZ = sx, sy, sz, ex, ey, ez
                    end
                    prevSX, prevSY, prevSZ, prevEX, prevEY, prevEZ = sx, sy, sz, ex, ey, ez
                end
                if prevSX and firstSX then
                    DRAW_LINE(prevSX, prevSY, prevSZ, firstSX, firstSY, firstSZ, tr, tg, tb, ta)
                    DRAW_LINE(prevEX, prevEY, prevEZ, firstEX, firstEY, firstEZ, tr, tg, tb, ta)
                end
            end
        end

        if useMagicBullets and lockedPlayerId ~= -1 and F.ghostAimToggle:GetBoolValue() then
            if vehHandle ~= 0 then
                local vehClass = GET_VEHICLE_CLASS(vehHandle)
                if vehClass == 15 or vehClass == 16 then
                    DISABLE_CONTROL_ACTION(0, 114, true); DISABLE_CONTROL_ACTION(0, 115, true)
                else
                    DISABLE_CONTROL_ACTION(0, 68, true) 
                end
            else
                DISABLE_CONTROL_ACTION(0, 24, true) 
            end
        end

        if lockedPlayerId == -1 and hoveredId ~= -1 then
            if (currentTime - lastKillTime) >= F.switchDelaySlider:GetIntValue() then 
                lockedPlayerId = hoveredId 
                PrintLog("[Aimbot] Target Acquired: " .. tostring(GET_PLAYER_NAME(lockedPlayerId)))
            end
        elseif lockedPlayerId ~= -1 then
            local stillAlive = true
            if F.excludeFriendsToggle:GetBoolValue() and friendsCache[lockedPlayerId] then
                stillAlive = false
            else
                local okPed, pPed = pcall(Players.GetCPed, lockedPlayerId)
                if not okPed or not pPed or pPed:GetAddress() == 0 then
                    stillAlive = false
                else
                    if F.checkHealthToggle:GetBoolValue() then
                        local hp = InvokeInt(0xEEF059FAD016D209, GTA.PointerToHandle(pPed))
                        if type(hp) ~= "number" or hp <= 0.0 then stillAlive = false end
                    end
                    if stillAlive then
                        local okTPos, tPos = pcall(function() return pPed.Position end)
                        if not okTPos or not tPos or (tPos.x == 0 and tPos.y == 0) then
                            stillAlive = false
                        else
                            local dx, dy, dz = tPos.x - vX, tPos.y - vY, tPos.z - vZ
                            local distSq = GetDistSq(tPos.x, tPos.y, tPos.z, vX, vY, vZ)
                            local maxRange = F.rangeSlider:GetIntValue()
                            if distSq > (maxRange * maxRange) then
                                stillAlive = false
                            elseif not F.stickyLockToggle:GetBoolValue() then
                                local dist3D = math.sqrt(distSq)
                                local dotProduct = (dx * fX) + (dy * fY) + (dz * fZ)
                                local is360Cam = F.allow360CameraToggle:GetBoolValue()
                                local inFov = false
                                if dotProduct > 0 or (aimMode == 0 and is360Cam) then
                                    if aimMode == 0 then
                                        local okS, sx, sy = pcall(GTA.WorldToScreen, tPos.x, tPos.y, tPos.z)
                                        if okS and sx > 0.0 and sx < 1.0 and sy > 0.0 and sy < 1.0 then
                                            local dist2DSq = GetDistSq2D(screenW/2, screenH/2, sx*screenW, sy*screenH)
                                            local fovVal = F.fovSlider:GetIntValue()
                                            if dist2DSq <= (fovVal * fovVal) then inFov = true end
                                        end
                                    elseif aimMode == 1 then
                                        local cosA = math.max(-1, math.min(1, dotProduct / dist3D))
                                        if math.deg(math.acos(cosA)) <= (F.vehFovSlider:GetIntValue() / 2) * 1.5 then inFov = true end
                                    elseif aimMode == 2 then
                                        local crossX, crossY, crossZ = dy*fZ - dz*fY, dz*fX - dx*fZ, dx*fY - dy*fX
                                        if math.sqrt(crossX*crossX + crossY*crossY + crossZ*crossZ) <= (F.laserRadiusSlider:GetIntValue() * 1.5) then inFov = true end
                                    end
                                end
                                if not inFov then stillAlive = false end
                            end
                            
                            if stillAlive and F.checkLosToggle:GetBoolValue() and F.bypassModeCombo:GetListIndex() == 0 then
                                local pPedHandle = GTA.PointerToHandle(pPed)
                                if not HAS_ENTITY_CLEAR_LOS_TO_ENTITY(entHandle, pPedHandle, 17) then
                                    stillAlive = false
                                end
                            end
                        end
                    end
                end
            end
            if not stillAlive then
                lockedPlayerId = -1; lastKillTime = currentTime
                PrintLog("[Aimbot] Target Lost/Killed/Hidden.")
            elseif F.autoSwitchToggle:GetBoolValue() and hoveredId ~= -1 and hoveredId ~= lockedPlayerId then
                if (currentTime - lastKillTime) >= F.switchDelaySlider:GetIntValue() then 
                    lockedPlayerId = hoveredId 
                    PrintLog("[Aimbot] Target Switched: " .. tostring(GET_PLAYER_NAME(lockedPlayerId)))
                end
            end
        end

        if lockedPlayerId ~= -1 then
            local okP, pPed = pcall(Players.GetCPed, lockedPlayerId)
            if okP and pPed and pPed:GetAddress() ~= 0 then
                local okPos, pPos = pcall(function() return pPed.Position end)
                if okPos and pPos and pPos.x ~= 0 then
                    local bX, bY, bZ = pPos.x, pPos.y, pPos.z
                    local boneIndex = F.targetBoneCombo:GetListIndex()
                    if boneIndex == 0 then bZ = bZ + 0.2 elseif boneIndex == 1 then bZ = bZ + 0.6 elseif boneIndex == 2 then bZ = bZ - 0.90 end

                    if useMagicBullets and F.predictiveAimToggle:GetBoolValue() then
                        local projSpeed = F.projectileSpeedSlider:GetIntValue()
                        local currentWeaponHash = GetMagicWeaponHash(pedHandle, vehHandle ~= 0)
                        if F.autoHandlingToggle:GetBoolValue() and not F.enforcePhysicalSpeedToggle:GetBoolValue() and not IsWeaponMissile(currentWeaponHash) then
                            local dbStats = GetWeaponStats(currentWeaponHash)
                            if dbStats and dbStats.speed then projSpeed = dbStats.speed end
                        end
                        if projSpeed > 0 then
                            local entToGetVel = 0
                            pcall(function() local pVeh = pPed.Vehicle; entToGetVel = (pVeh and pVeh:GetAddress() ~= 0) and GTA.PointerToHandle(pVeh) or GTA.PointerToHandle(pPed) end)
                            if entToGetVel ~= 0 then
                                local velX, velY, velZ = GET_ENTITY_VELOCITY(entToGetVel)
                                
                                local dx = bX - vX
                                local dy = bY - vY
                                local dz = bZ - vZ
                                
                                local a = (velX*velX + velY*velY + velZ*velZ) - (projSpeed * projSpeed)
                                local b = 2.0 * (dx * velX + dy * velY + dz * velZ)
                                local c = (dx*dx + dy*dy + dz*dz)
                                
                                local t = 0
                                if math.abs(a) < 0.0001 then
                                    if b < 0.0 then t = -c / b end
                                else
                                    local delta = (b * b) - (4.0 * a * c)
                                    if delta >= 0.0 then
                                        local sqrtDelta = math.sqrt(delta)
                                        local t1 = (-b + sqrtDelta) / (2.0 * a)
                                        local t2 = (-b - sqrtDelta) / (2.0 * a)
                                        
                                        if t1 > 0.0 and t2 > 0.0 then t = math.min(t1, t2)
                                        elseif t1 > 0.0 then t = t1
                                        elseif t2 > 0.0 then t = t2 end
                                    end
                                end
                                
                                if t <= 0.0 then t = math.sqrt(c) / projSpeed end
                                t = t + (F.pingCompSlider:GetIntValue() / 1000.0)
                                
                                bX = bX + (velX * t)
                                bY = bY + (velY * t)
                                bZ = bZ + (velZ * t)
                            end
                        end
                    end
                    renderTargetPos = {x = bX, y = bY, z = bZ}
                    renderTargetDist = math.sqrt(GetDistSq(bX, bY, bZ, vX, vY, vZ))
                else
                    renderTargetPos = nil
                end
            end
        else
            renderTargetPos = nil
        end

        if F.camLockToggle:GetBoolValue() and lockedPlayerId ~= -1 and renderTargetPos then
            local isAimPressed = false
            local p = IS_CONTROL_PRESSED(0, 25) 
            local d = IS_DISABLED_CONTROL_PRESSED(0, 25)
            if p == 1 or p == true or d == 1 or d == true then isAimPressed = true end
            
            if isAimPressed then
                if (currentTime - lastCamUpdateTime) >= F.camLockDelaySlider:GetIntValue() then
                    lastCamUpdateTime = currentTime
                    local okS, sX, sY = pcall(GTA.WorldToScreen, renderTargetPos.x, renderTargetPos.y, renderTargetPos.z)
                    
                    if okS and sX > 0.0 and sX < 1.0 and sY > 0.0 and sY < 1.0 then
                        local targetPxX = sX * screenW
                        local targetPxY = sY * screenH
                        local centerPxX = math.max(1.0, screenW / 2.0)
                        local centerPxY = math.max(1.0, screenH / 2.0)
                        
                        local distToCenterSq = GetDistSq2D(centerPxX, centerPxY, targetPxX, targetPxY)
                        local deadzone = F.camLockDeadzoneSlider:GetIntValue()
                        
                        if distToCenterSq > (deadzone * deadzone) then
                            local errorX = (targetPxX - centerPxX) / centerPxX
                            local errorY = (targetPxY - centerPxY) / centerPxY
                            local strength = F.camLockStrengthSlider:GetIntValue() / 25.0 
                            
                            currentCamMoveX = math.max(-1.0, math.min(1.0, errorX * strength))
                            currentCamMoveY = math.max(-1.0, math.min(1.0, errorY * strength))
                        else
                            currentCamMoveX = 0.0
                            currentCamMoveY = 0.0
                        end
                    else
                        currentCamMoveX = 0.0
                        currentCamMoveY = 0.0
                    end
                end
                
                if currentCamMoveX ~= 0.0 or currentCamMoveY ~= 0.0 then
                    pcall(Natives.InvokeVoid, 0xE8A25867FBA3B05E, 0, 1, currentCamMoveX) 
                    pcall(Natives.InvokeVoid, 0xE8A25867FBA3B05E, 0, 2, currentCamMoveY) 
                end
            else
                currentCamMoveX = 0.0
                currentCamMoveY = 0.0
            end
        else
            currentCamMoveX = 0.0
            currentCamMoveY = 0.0
        end

        if useGuidedMissile and lockedPlayerId ~= -1 and renderTargetPos then
            local isHijackActive = F.hijackMissilesToggle:GetBoolValue()
            local localPid = PLAYER_ID()
            local localNetPlayer = nil
            pcall(function() localNetPlayer = Players.GetById(localPid) end)

            for _, objHandle in ipairs(cachedObjects) do
                if DOES_ENTITY_EXIST(objHandle) then
                    local modelHash = InvokeInt(0x9F47B058362C84B5, objHandle)
                    
                    if projectileModels[modelHash] or projectileModels[modelHash % 0x100000000] then
                        local mX, mY, mZ = GET_ENTITY_COORDS(objHandle, true)
                        local velX, velY, velZ = GET_ENTITY_VELOCITY(objHandle)
                        
                        local isMine = false
                        local fromMeX, fromMeY, fromMeZ = mX - vX, mY - vY, mZ - vZ
                        local distSq = GetDistSq(mX, mY, mZ, vX, vY, vZ)
                        
                        local ptr = nil
                        pcall(function() ptr = GTA.HandleToPointer(objHandle) end)
                        local netObj = nil
                        if ptr and ptr:GetAddress() ~= 0 then
                            pcall(function()
                                netObj = ptr.NetObject
                                if netObj and netObj:GetAddress() ~= 0 and netObj.PlayerId == localPid then isMine = true end
                            end)
                        end
                        
                        if not isMine then
                            local dot = (fromMeX * velX) + (fromMeY * velY) + (fromMeZ * velZ)
                            if distSq < 900.0 and dot > -5.0 then
                                isMine = true
                            end
                        end
                        
                        if isMine or isHijackActive then
                            if not isMine then
                                local netId = NETWORK_GET_NETWORK_ID_FROM_ENTITY(objHandle)
                                if netId ~= 0 then InvokeVoid(0xA670B3669F540A50, netId, true) end
                                InvokeBool(0xB69317BF5E782347, objHandle) 
                                if netObj and netObj:GetAddress() ~= 0 and localNetPlayer then
                                    pcall(function() NetworkObjectMgr.ChangeOwner(netObj, localNetPlayer, 3) end)
                                end
                            end

                            if not activeGuidedMissiles[objHandle] then
                                local assignedTarget = 0
                                if lockedPlayerId ~= -1 then
                                    local okP, pPed = pcall(Players.GetCPed, lockedPlayerId)
                                    if okP and pPed and pPed:GetAddress() ~= 0 then assignedTarget = GTA.PointerToHandle(pPed) end
                                end
                                if assignedTarget ~= 0 then activeGuidedMissiles[objHandle] = assignedTarget end
                            end

                            local currentTarget = activeGuidedMissiles[objHandle]
                            if currentTarget and currentTarget ~= 0 then
                                local tX, tY, tZ = GET_ENTITY_COORDS(currentTarget, true)
                                if tX == 0.0 and tY == 0.0 and tZ == 0.0 then
                                    activeGuidedMissiles[objHandle] = nil
                                else
                                    local dirX = renderTargetPos.x - mX
                                    local dirY = renderTargetPos.y - mY
                                    local dirZ = renderTargetPos.z - mZ
                                    local dist = math.sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
                                    
                                    if dist > 0.5 then
                                        local speed = F.guidedMissileSpeed:GetIntValue() * 1.0
                                        local nX, nY, nZ = dirX/dist, dirY/dist, dirZ/dist
                                        SET_ENTITY_VELOCITY(objHandle, nX * speed, nY * speed, nZ * speed)
                                        local targetYaw = CalculateHeading(dirX, dirY)
                                        local targetPitch = 0.0
                                        if math.sqrt(dirX*dirX + dirY*dirY) ~= 0.0 then 
                                            if math.atan2 then targetPitch = math.deg(math.atan2(dirZ, math.sqrt(dirX*dirX + dirY*dirY)))
                                            else targetPitch = math.deg(math.atan(dirZ / math.sqrt(dirX*dirX + dirY*dirY))) end
                                        end
                                        SET_ENTITY_ROTATION(objHandle, targetPitch, 0.0, targetYaw, 2, true)
                                    end

                                    if dist < 4.0 and not isMine then
                                        pcall(Natives.InvokeVoid, 0xE3AD2BDBAEE269AC, renderTargetPos.x, renderTargetPos.y, renderTargetPos.z, 2, 1000.0, true, false, 0.0)
                                        pcall(Natives.InvokeVoid, 0xE3AD2BDBAEE269AC, mX, mY, mZ, 2, 0.0, false, true, 0.0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        local isMissileReactionActive = (F.autoFlareToggle:GetBoolValue() or F.autoPassiveToggle:GetBoolValue())
        if isMissileReactionActive and vehHandle ~= 0 then
            local currentCooldown = F.flareCooldownSlider:GetIntValue()
            local danger = false
            
            for _, objHandle in ipairs(cachedObjects) do
                if DOES_ENTITY_EXIST(objHandle) then
                    local modelHash = InvokeInt(0x9F47B058362C84B5, objHandle)
                    if projectileModels[modelHash] or projectileModels[modelHash % 0x100000000] then
                        local mX, mY, mZ = GET_ENTITY_COORDS(objHandle, true)
                        local velX, velY, velZ = GET_ENTITY_VELOCITY(objHandle)
                        
                        local distSq = GetDistSq(mX, mY, mZ, vX, vY, vZ)
                        local maxRange = F.flareDistSlider:GetIntValue() * 1.0
                        
                        if distSq > 25.0 and distSq < (maxRange * maxRange) then
                            local toMeX, toMeY, toMeZ = vX - mX, vY - mY, vZ - mZ
                            local dot = (toMeX * velX) + (toMeY * velY) + (toMeZ * velZ)
                            if dot > 20.0 then
                                local isMine = false
                                local ptr = nil
                                pcall(function() ptr = GTA.HandleToPointer(objHandle) end)
                                if ptr and ptr:GetAddress() ~= 0 then
                                    pcall(function()
                                        local netObj = ptr.NetObject
                                        if netObj and netObj:GetAddress() ~= 0 and netObj.PlayerId == PLAYER_ID() then isMine = true end
                                    end)
                                end
                                if not isMine then
                                    danger = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            if danger then
                if (currentTime - lastFlareTime) > currentCooldown then
                    if F.autoPassiveToggle:GetBoolValue() then
                        NETWORK_SET_PLAYER_IS_PASSIVE(true)
                        PLAYSTATS_SWITCH_PASSIVE_MODE(true)
                        if lastPassiveTrigger == 0 then PrintLog("[Missile Reaction] Danger Detected! True Passive Mode activated.") end
                        lastPassiveTrigger = currentTime
                    end

                    if F.autoFlareToggle:GetBoolValue() then
                        local flareHash = 0x47757124 
                        pcall(function()
                            for _, objHandle in ipairs(cachedObjects) do
                                if DOES_ENTITY_EXIST(objHandle) then
                                    local modelHash = InvokeInt(0x9F47B058362C84B5, objHandle)
                                    if modelHash == flareHash then
                                        local ptr = nil
                                        pcall(function() ptr = GTA.HandleToPointer(objHandle) end)
                                        if ptr and ptr:GetAddress() ~= 0 then
                                            pcall(function() ptr.Position = V3.New(0.0, 0.0, -1000.0); ptr.IsVisible = false end)
                                        end
                                        InvokeVoid(0x06843DA7060A026B, objHandle, 0.0, 0.0, -1000.0, 0, 0, 1, 0)
                                        DELETE_ENTITY(objHandle)
                                    end
                                end
                            end
                        end)

                        local startX, startY, startZ = vX + (uX * 2.0), vY + (uY * 2.0), vZ + (uZ * 2.0)
                        local activeDirs = {}
                        if F.flareUpToggle:GetBoolValue() then table.insert(activeDirs, {x=uX, y=uY, z=uZ}) end
                        if F.flareDownToggle:GetBoolValue() then table.insert(activeDirs, {x=-uX, y=-uY, z=-uZ}) end
                        if F.flareForwardToggle:GetBoolValue() then table.insert(activeDirs, {x=fX, y=fY, z=fZ}) end
                        if F.flareBackwardToggle:GetBoolValue() then table.insert(activeDirs, {x=-fX, y=-fY, z=-fZ}) end
                        if F.flareRightToggle:GetBoolValue() then table.insert(activeDirs, {x=rX, y=rY, z=rZ}) end
                        if F.flareLeftToggle:GetBoolValue() then table.insert(activeDirs, {x=-rX, y=-rY, z=-rZ}) end
                        if #activeDirs == 0 then table.insert(activeDirs, {x=uX, y=uY, z=uZ}) end
                        
                        local throwForce = 50.0 
                        local flareVelocity = 25.0 
                        pcall(function()
                            for _, dir in ipairs(activeDirs) do
                                local targetX = startX + (dir.x * throwForce)
                                local targetY = startY + (dir.y * throwForce)
                                local targetZ = startZ + (dir.z * throwForce)
                                SHOOT_SINGLE_BULLET_BETWEEN_COORDS(startX, startY, startZ, targetX, targetY, targetZ, 0, true, flareHash, pedHandle, true, false, flareVelocity, false)
                            end
                        end)
                        PrintLog("[Missile Reaction] Fired optimized Omni-Flares.")
                        lastFlareTime = currentTime
                    end
                end
            end
        end

        if lastPassiveTrigger > 0 and (currentTime - lastPassiveTrigger) > 5000 then
            NETWORK_SET_PLAYER_IS_PASSIVE(false)
            PLAYSTATS_SWITCH_PASSIVE_MODE(false)
            lastPassiveTrigger = 0
            PrintLog("[Missile Reaction] Coast is clear. Passive Mode disabled.")
        end

        if useMagicBullets then
            local isInputActive = IsPhysicalShootPressed(vehHandle)
            local currentWeaponHash = GetMagicWeaponHash(pedHandle, vehHandle ~= 0)
            local isMissileActive = IsWeaponMissile(currentWeaponHash)
            local currentDelay = isMissileActive and F.missileRateSlider:GetIntValue() or F.fireRateSlider:GetIntValue()
            local currentDamage = F.damageSlider:GetIntValue()
            local currentBurstMax = F.burstSizeSlider:GetIntValue()
            local currentReloadTime = F.reloadTimeSlider:GetIntValue()
            
            if F.autoHandlingToggle:GetBoolValue() then
                local dbStats = GetWeaponStats(currentWeaponHash)
                if dbStats then
                    currentDamage = dbStats.dmg
                    currentDelay = dbStats.delay
                    currentBurstMax = dbStats.burst or 0
                    currentReloadTime = dbStats.reload or 0
                end
            end

            if currentWeaponHash ~= lastWeaponHash then burstShotsFired, lastWeaponHash = 0, currentWeaponHash end
            local maxWait = (currentReloadTime > 0) and currentReloadTime or currentDelay
            if (currentTime - lastFireTime) > (maxWait + 1000) then burstShotsFired = 0 end

            local isReloading = (currentBurstMax > 0 and burstShotsFired >= currentBurstMax)
            local requiredDelay = isReloading and currentReloadTime or currentDelay
            local wantsToShoot = (F.autoFireToggle:GetBoolValue() and lockedPlayerId ~= -1) or (isInputActive and lockedPlayerId ~= -1)

            if F.strictBurstToggle:GetBoolValue() and isInputActive and lockedPlayerId == -1 then
                if (currentTime - lastFireTime) >= requiredDelay then
                    lastFireTime = currentTime
                    burstShotsFired = isReloading and 1 or (burstShotsFired + 1)
                end
            end

            if wantsToShoot and lockedPlayerId ~= -1 and renderTargetPos then
                if F.smoothAimToggle:GetBoolValue() and vehHandle ~= 0 then
                    pcall(function()
                        local origPitch, origRoll, origYaw = GET_ENTITY_ROTATION(vehHandle, 2)
                        local origSpeed = GET_ENTITY_SPEED(vehHandle)
                        local dx, dy, dz = renderTargetPos.x - vX, renderTargetPos.y - vY, renderTargetPos.z - vZ
                        local targetYaw = CalculateHeading(dx, dy)
                        local targetPitch = 0.0
                        if math.sqrt(dx*dx + dy*dy) ~= 0.0 then 
                            if math.atan2 then targetPitch = math.deg(math.atan2(dz, math.sqrt(dx*dx + dy*dy)))
                            else targetPitch = math.deg(math.atan(dz / math.sqrt(dx*dx + dy*dy))) end
                        end
                        
                        local yawDiff = (targetYaw - origYaw + 180) % 360 - 180
                        local smoothing = F.smoothSpeedSlider:GetIntValue() / 100.0
                        local newYaw = origYaw + (yawDiff * smoothing)
                        local newPitch = origPitch + ((targetPitch - origPitch) * smoothing)
                        SET_ENTITY_ROTATION(vehHandle, newPitch, origRoll, newYaw, 2, true)
                        SET_FORWARD_SPEED(vehHandle, origSpeed)
                    end)
                end
                
                if (currentTime - lastFireTime) >= requiredDelay then
                    lastFireTime = currentTime
                    burstShotsFired = isReloading and 1 or (burstShotsFired + 1)

                    local tX, tY, tZ = renderTargetPos.x, renderTargetPos.y, renderTargetPos.z
                    local spreadRadius = F.spreadSlider:GetIntValue() / 10.0
                    if spreadRadius > 0 then
                        tX = tX + (math.random() * 2 - 1) * spreadRadius
                        tY = tY + (math.random() * 2 - 1) * spreadRadius
                        tZ = tZ + (math.random() * 2 - 1) * spreadRadius
                    end

                    local startX, startY, startZ = 0, 0, 0
                    if vehHandle ~= 0 then
                        startX = vX + (fX * 6.0) + (uX * 0.5); startY = vY + (fY * 6.0) + (uY * 0.5); startZ = vZ + (fZ * 6.0) + (uZ * 0.5)
                    else
                        startX = vX + (fX * 1.0); startY = vY + (fY * 1.0); startZ = vZ + 0.6
                    end

                    local bypassMode = F.bypassModeCombo:GetListIndex()
                    if bypassMode > 0 and vehHandle ~= 0 then
                        local offsetDistance = F.bypassDistSlider:GetIntValue() * 1.0
                        local dirX, dirY, dirZ = tX - startX, tY - startY, tZ - startZ
                        local distance = math.sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
                        if bypassMode == 1 and distance > 0.001 then
                            startX = tX - (dirX/distance * offsetDistance); startY = tY - (dirY/distance * offsetDistance); startZ = tZ - (dirZ/distance * offsetDistance)
                        elseif bypassMode == 2 then
                            startX = tX; startY = tY; startZ = tZ + offsetDistance
                        elseif bypassMode == 3 and distance > 0.001 then
                            startX = tX + (dirX/distance * offsetDistance); startY = tY + (dirY/distance * offsetDistance); startZ = tZ + (dirZ/distance * offsetDistance)
                        end
                    end

                    local finalPhysicsSpeed = F.enforcePhysicalSpeedToggle:GetBoolValue() and (F.projectileSpeedSlider:GetIntValue() * 1.0) or -1.0

                    pcall(function()
                        if F.snapVehicleToggle:GetBoolValue() and vehHandle ~= 0 then
                            local origPitch, origRoll, origYaw = GET_ENTITY_ROTATION(vehHandle, 2)
                            local origSpeed = GET_ENTITY_SPEED(vehHandle)
                            local dx, dy, dz = tX - vX, tY - vY, tZ - vZ
                            
                            local snapYaw = CalculateHeading(dx, dy)
                            local snapPitch = 0.0
                            if math.sqrt(dx*dx + dy*dy) ~= 0.0 then 
                                if math.atan2 then snapPitch = math.deg(math.atan2(dz, math.sqrt(dx*dx + dy*dy)))
                                else snapPitch = math.deg(math.atan(dz / math.sqrt(dx*dx + dy*dy))) end
                            end
                            
                            SET_ENTITY_ROTATION(vehHandle, snapPitch, origRoll, snapYaw, 2, true)
                            SET_FORWARD_SPEED(vehHandle, origSpeed)
                            if F.bulletTypeCombo:GetListIndex() ~= 0 then
                                SHOOT_SINGLE_BULLET_BETWEEN_COORDS(startX, startY, startZ, tX, tY, tZ, currentDamage, true, currentWeaponHash, pedHandle, true, false, finalPhysicsSpeed, false)
                            end
                            Script.Yield(F.flickDurationSlider:GetIntValue())
                            SET_ENTITY_ROTATION(vehHandle, origPitch, origRoll, origYaw, 2, true)
                            SET_FORWARD_SPEED(vehHandle, origSpeed)
                        else
                            if F.bulletTypeCombo:GetListIndex() ~= 0 then
                                SHOOT_SINGLE_BULLET_BETWEEN_COORDS(startX, startY, startZ, tX, tY, tZ, currentDamage, true, currentWeaponHash, pedHandle, true, false, finalPhysicsSpeed, false)
                            end
                        end
                    end)
                end
            end
        end
    end, ErrorHandler)

    if not status then PrintErrorSafe("Main Loop Critical Failure", err) end
end)

local function BeginCustomChildWindow(name, numToggles, numSliders, numCombos, numButtons, numInputs)
    numToggles = numToggles or 0
    numSliders = numSliders or 0
    numCombos = numCombos or 0
    numButtons = numButtons or 0
    numInputs = numInputs or 0
    
    local height = 70 + (numToggles * 42) + (numSliders * 65) + (numCombos * 65) + (numButtons * 45) + (numInputs * 50)
    
    local pushed = false
    if type(ImGui.PushStyleColor) == "function" then
        pcall(function() ImGui.PushStyleColor(3, 0.0, 0.0, 0.0, 0.85); pushed = true end)
    end

    local flags = 24 -- 8 (NoScrollbar) + 16 (NoScrollWithMouse)
    if type(ImGuiWindowFlags) == "table" and ImGuiWindowFlags.NoScrollWithMouse and ImGuiWindowFlags.NoScrollbar then
        flags = ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.NoScrollWithMouse
    end
    pcall(ImGui.BeginChild, name, 0, height, true, flags) 
    
    if pushed then
        pcall(function() ImGui.PopStyleColor(1) end)
    end

    local okY, y = pcall(ImGui.GetCursorPosY)
    if okY and type(y) == "number" then pcall(ImGui.SetCursorPosY, y - 2) end
    
    local okX, x = pcall(ImGui.GetCursorPosX)
    if okX and type(x) == "number" then pcall(ImGui.SetCursorPosX, x + 4) end
    
    if type(ImGui.Text) == "function" then pcall(ImGui.Text, name) end
    if type(ImGui.Separator) == "function" then pcall(ImGui.Separator) end
    
    okY, y = pcall(ImGui.GetCursorPosY)
    if okY and type(y) == "number" then pcall(ImGui.SetCursorPosY, y + 4) end
    
    return true
end

local function EndCustomChildWindow()
    pcall(ImGui.EndChild)
    if type(ImGui.Spacing) == "function" then pcall(ImGui.Spacing) end
end

-- ==============================================================================
-- MENU REGISTRATION
-- ==============================================================================
ClickGUI.AddTab(SCRIPT_NAME, function()
    local success, err = pcall(function()
        if ImGui.BeginTabBar("PvpHelperTabs", 0) then
            
            if ImGui.BeginTabItem("Self") then
                if ImGui.BeginTabBar("SelfSubTabs", 0) then
                    
                    if ImGui.BeginTabItem("Aimbot") then
                        ImGui.Columns(2, "SelfAimbotCols", false)
                        if BeginCustomChildWindow("Magic Bullets & Aimbot", 5, 3, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 1)
                            ClickGUI.RenderFeature(scriptHash + 120)
                            ClickGUI.RenderFeature(scriptHash + 121)
                            ClickGUI.RenderFeature(scriptHash + 122)
                            ClickGUI.RenderFeature(scriptHash + 123)
                            ClickGUI.RenderFeature(scriptHash + 16)
                            ClickGUI.RenderFeature(scriptHash + 14)
                            ClickGUI.RenderFeature(scriptHash + 15)
                            EndCustomChildWindow()
                        end
                        if BeginCustomChildWindow("Target Switch", 2, 1, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 50)
                            ClickGUI.RenderFeature(scriptHash + 51)
                            ClickGUI.RenderFeature(scriptHash + 82)
                            EndCustomChildWindow()
                        end
                        ImGui.NextColumn()
                        if BeginCustomChildWindow("Detection & FOV", 3, 0, 1, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 26)
                            ClickGUI.RenderFeature(scriptHash + 33)
                            ClickGUI.RenderFeature(scriptHash + 25) 
                            ClickGUI.RenderFeature(scriptHash + 53) 
                            EndCustomChildWindow()
                        end
                        if BeginCustomChildWindow("Target Filters", 3, 0, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 52)
                            ClickGUI.RenderFeature(scriptHash + 23)
                            ClickGUI.RenderFeature(scriptHash + 24)
                            EndCustomChildWindow()
                        end
                        if BeginCustomChildWindow("Target Priority", 0, 0, 2, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 32)
                            ClickGUI.RenderFeature(scriptHash + 29)
                            EndCustomChildWindow()
                        end
                        ImGui.Columns(1)
                        ImGui.EndTabItem()
                    end

                    if ImGui.BeginTabItem("Weapons") then
                        ImGui.Columns(2, "SelfWeaponsCols", false)
                        if BeginCustomChildWindow("Weapon Enhancements", 1, 0, 0, 1, 0) then
                            ClickGUI.RenderFeature(scriptHash + 87)
                            ClickGUI.RenderFeature(scriptHash + 89)
                            EndCustomChildWindow()
                        end
                        ImGui.Columns(1)
                        ImGui.EndTabItem()
                    end
                    
                    if ImGui.BeginTabItem("Survival") then
                        ImGui.Columns(2, "SelfSurvCols", false)
                        if BeginCustomChildWindow("Auto-Heal & Armor", 2, 6, 1, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 130)
                            ClickGUI.RenderFeature(scriptHash + 131)
                            ClickGUI.RenderFeature(scriptHash + 138)
                            ClickGUI.RenderFeature(scriptHash + 136) 
                            ClickGUI.RenderFeature(scriptHash + 137) 
                            ClickGUI.RenderFeature(scriptHash + 132)
                            ClickGUI.RenderFeature(scriptHash + 133)
                            ClickGUI.RenderFeature(scriptHash + 134)
                            ClickGUI.RenderFeature(scriptHash + 135)
                            EndCustomChildWindow()
                        end
                        ImGui.Columns(1)
                        ImGui.EndTabItem()
                    end
                    
                    if ImGui.BeginTabItem("Ballistics") then
                        ImGui.Columns(2, "SelfBalCols", false)
                        if BeginCustomChildWindow("Damage & Delays", 1, 6, 1, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 71)
                            ClickGUI.RenderFeature(scriptHash + 70)
                            ClickGUI.RenderFeature(scriptHash + 17)
                            ClickGUI.RenderFeature(scriptHash + 11)
                            ClickGUI.RenderFeature(scriptHash + 6)
                            ClickGUI.RenderFeature(scriptHash + 7)
                            ClickGUI.RenderFeature(scriptHash + 18)
                            ClickGUI.RenderFeature(scriptHash + 19)
                            EndCustomChildWindow()
                        end
                        ImGui.NextColumn()
                        if BeginCustomChildWindow("Advanced Prediction", 2, 2, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 80)
                            ClickGUI.RenderFeature(scriptHash + 85)
                            ClickGUI.RenderFeature(scriptHash + 81)
                            ClickGUI.RenderFeature(scriptHash + 86)
                            EndCustomChildWindow()
                        end
                        if BeginCustomChildWindow("Obstacle Bypass", 0, 1, 1, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 110)
                            ClickGUI.RenderFeature(scriptHash + 111)
                            EndCustomChildWindow()
                        end
                        ImGui.Columns(1)
                        ImGui.EndTabItem()
                    end
                    
                    if ImGui.BeginTabItem("Visuals") then
                        ImGui.Columns(2, "SelfVisCols", false)
                        if BeginCustomChildWindow("Radar Settings", 0, 3, 0, 0, 0) then
                            local mode = F.aimModeCombo:GetListIndex()
                            if mode == 0 then ClickGUI.RenderFeature(scriptHash + 3)
                            elseif mode == 1 then ClickGUI.RenderFeature(scriptHash + 27)
                            elseif mode == 2 then ClickGUI.RenderFeature(scriptHash + 28) end
                            ClickGUI.RenderFeature(scriptHash + 4)
                            ClickGUI.RenderFeature(scriptHash + 31)
                            EndCustomChildWindow()
                        end
                        if BeginCustomChildWindow("HUD Toggles", 3, 0, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 2)
                            ClickGUI.RenderFeature(scriptHash + 10)
                            ClickGUI.RenderFeature(scriptHash + 45)
                            EndCustomChildWindow()
                        end
                        ImGui.NextColumn()
                        if BeginCustomChildWindow("Colors", 5, 0, 0, 0, 0) then
                            ClickGUI.RenderFeature(scriptHash + 40)
                            ClickGUI.RenderFeature(scriptHash + 41)
                            ClickGUI.RenderFeature(scriptHash + 42)
                            ClickGUI.RenderFeature(scriptHash + 43)
                            ClickGUI.RenderFeature(scriptHash + 44)
                            EndCustomChildWindow()
                        end
                        ImGui.Columns(1)
                        ImGui.EndTabItem()
                    end
                    ImGui.EndTabBar()
                end
                ImGui.EndTabItem()
            end
            
            if ImGui.BeginTabItem("Vehicle") then
                ImGui.Columns(2, "VehCols", false)
                if BeginCustomChildWindow("Vehicle Assist", 5, 2, 0, 0, 0) then
                    ClickGUI.RenderFeature(scriptHash + 12)
                    ClickGUI.RenderFeature(scriptHash + 13)
                    ClickGUI.RenderFeature(scriptHash + 8)
                    ClickGUI.RenderFeature(scriptHash + 9)
                    ClickGUI.RenderFeature(scriptHash + 405)
                    EndCustomChildWindow()
                end
                if BeginCustomChildWindow("Guided Missiles Tracker", 2, 1, 0, 0, 0) then
                    ClickGUI.RenderFeature(scriptHash + 300)
                    ClickGUI.RenderFeature(scriptHash + 301)
                    ClickGUI.RenderFeature(scriptHash + 302)
                    EndCustomChildWindow()
                end
                ImGui.NextColumn()
                if BeginCustomChildWindow("Missile Reaction", 8, 2, 0, 0, 0) then
                    ClickGUI.RenderFeature(scriptHash + 314)
                    ClickGUI.RenderFeature(scriptHash + 303)
                    if type(ImGui.Separator) == "function" then pcall(ImGui.Separator) end
                    ClickGUI.RenderFeature(scriptHash + 305)
                    ClickGUI.RenderFeature(scriptHash + 307)
                    if type(ImGui.Separator) == "function" then pcall(ImGui.Separator) end
                    ClickGUI.RenderFeature(scriptHash + 308)
                    ClickGUI.RenderFeature(scriptHash + 309)
                    ClickGUI.RenderFeature(scriptHash + 310)
                    ClickGUI.RenderFeature(scriptHash + 311)
                    ClickGUI.RenderFeature(scriptHash + 312)
                    ClickGUI.RenderFeature(scriptHash + 313)
                    EndCustomChildWindow()
                end
                ImGui.Columns(1)
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Misc") then
                ImGui.Columns(2, "MiscCols", false)
                if BeginCustomChildWindow("Vehicle Blacklist", 2, 0, 1, 3, 1) then
                    ClickGUI.RenderFeature(scriptHash + 199)
                    ClickGUI.RenderFeature(scriptHash + 201)
                    ClickGUI.RenderFeature(scriptHash + 206)
                    ClickGUI.RenderFeature(scriptHash + 202)
                    ClickGUI.RenderFeature(scriptHash + 203)
                    ClickGUI.RenderFeature(scriptHash + 204)
                    ClickGUI.RenderFeature(scriptHash + 205)
                    EndCustomChildWindow()
                end
                ImGui.NextColumn()
                if BeginCustomChildWindow("Environment Control", 1, 1, 0, 0, 0) then
                    ClickGUI.RenderFeature(scriptHash + 400)
                    ClickGUI.RenderFeature(scriptHash + 401)
                    EndCustomChildWindow()
                end
                if BeginCustomChildWindow("Session Logger", 2, 0, 0, 0, 0) then
                    ClickGUI.RenderFeature(scriptHash + 600)
                    ClickGUI.RenderFeature(scriptHash + 601)
                    EndCustomChildWindow()
                end
                if BeginCustomChildWindow("Developer Tools", 3, 0, 0, 1, 0) then
                    ClickGUI.RenderFeature(scriptHash + 90)
                    ClickGUI.RenderFeature(scriptHash + 403)
                    ClickGUI.RenderFeature(scriptHash + 91)
                    ClickGUI.RenderFeature(scriptHash + 100)
                    EndCustomChildWindow()
                end
                ImGui.Columns(1)
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Credit") then
                if BeginCustomChildWindow("Information", 2, 0, 0, 0, 0) then
                    if type(ImGui.Text) == "function" then
                        pcall(ImGui.Text, "Developer: kalimelo")
                        pcall(ImGui.Text, "Discord: https://discord.gg/kWNx2aKyrk")
                    end
                    EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
    end)
    if not success then PrintErrorSafe("Menu UI Render Error", err) end
end)

local rootTab = ListGUI.GetRootTab()
local myTab = rootTab:AddSubTab(SCRIPT_NAME, "Advanced Magic Bullet Options")

local selfTab = myTab:AddSubTab("Self", "Player Settings")
local aimbotSub = selfTab:AddSubTab("Aimbot", "Aimbot & Targeting")
aimbotSub:AddFeature(scriptHash + 1)
aimbotSub:AddFeature(scriptHash + 120)
aimbotSub:AddFeature(scriptHash + 121)
aimbotSub:AddFeature(scriptHash + 122)
aimbotSub:AddFeature(scriptHash + 123)
aimbotSub:AddFeature(scriptHash + 16)
aimbotSub:AddFeature(scriptHash + 14)
aimbotSub:AddFeature(scriptHash + 15)
aimbotSub:AddSeperator("Target Switch")
aimbotSub:AddFeature(scriptHash + 50)
aimbotSub:AddFeature(scriptHash + 51)
aimbotSub:AddFeature(scriptHash + 82)
aimbotSub:AddSeperator("Detection")
aimbotSub:AddFeature(scriptHash + 26)
aimbotSub:AddFeature(scriptHash + 33)
aimbotSub:AddFeature(scriptHash + 25)
aimbotSub:AddFeature(scriptHash + 53)
aimbotSub:AddSeperator("Filters & Priority")
aimbotSub:AddFeature(scriptHash + 32)
aimbotSub:AddFeature(scriptHash + 29)
aimbotSub:AddFeature(scriptHash + 52)
aimbotSub:AddFeature(scriptHash + 23)
aimbotSub:AddFeature(scriptHash + 24)

local wpnSub = selfTab:AddSubTab("Weapons", "Weapon Enhancements")
wpnSub:AddFeature(scriptHash + 87)
wpnSub:AddFeature(scriptHash + 89)

local survSub = selfTab:AddSubTab("Survival", "Auto Heal & Armor")
survSub:AddFeature(scriptHash + 130)
survSub:AddFeature(scriptHash + 131)
survSub:AddFeature(scriptHash + 138)
survSub:AddFeature(scriptHash + 136)
survSub:AddFeature(scriptHash + 137)
survSub:AddFeature(scriptHash + 132)
survSub:AddFeature(scriptHash + 133)
survSub:AddFeature(scriptHash + 134)
survSub:AddFeature(scriptHash + 135)

local balSub = selfTab:AddSubTab("Ballistics", "Damage & Prediction")
balSub:AddFeature(scriptHash + 70)
balSub:AddFeature(scriptHash + 71)
balSub:AddFeature(scriptHash + 4)
balSub:AddFeature(scriptHash + 17)
balSub:AddFeature(scriptHash + 11)
balSub:AddFeature(scriptHash + 6)
balSub:AddFeature(scriptHash + 7)
balSub:AddFeature(scriptHash + 18)
balSub:AddFeature(scriptHash + 19)
balSub:AddSeperator("Prediction")
balSub:AddFeature(scriptHash + 80)
balSub:AddFeature(scriptHash + 85)
balSub:AddFeature(scriptHash + 81)
balSub:AddFeature(scriptHash + 86)
balSub:AddSeperator("Bypass")
balSub:AddFeature(scriptHash + 110)
balSub:AddFeature(scriptHash + 111)

local visSub = selfTab:AddSubTab("Visuals", "Radar & HUD")
visSub:AddFeature(scriptHash + 2)
visSub:AddFeature(scriptHash + 10)
visSub:AddFeature(scriptHash + 45)
visSub:AddFeature(scriptHash + 31)
visSub:AddSeperator("Radar")
visSub:AddFeature(scriptHash + 3)
visSub:AddFeature(scriptHash + 27)
visSub:AddFeature(scriptHash + 28)
visSub:AddSeperator("Colors")
visSub:AddFeature(scriptHash + 40)
visSub:AddFeature(scriptHash + 41)
visSub:AddFeature(scriptHash + 42)
visSub:AddFeature(scriptHash + 43)
visSub:AddFeature(scriptHash + 44)

local vehTab = myTab:AddSubTab("Vehicle", "Vehicle Enhancements")
vehTab:AddFeature(scriptHash + 12)
vehTab:AddFeature(scriptHash + 13)
vehTab:AddFeature(scriptHash + 8)
vehTab:AddFeature(scriptHash + 9)
vehTab:AddFeature(scriptHash + 405)
vehTab:AddSeperator("Missile Reaction")
vehTab:AddFeature(scriptHash + 314)
vehTab:AddFeature(scriptHash + 303)
vehTab:AddFeature(scriptHash + 305)
vehTab:AddFeature(scriptHash + 307)
vehTab:AddSeperator("Flare Directions")
vehTab:AddFeature(scriptHash + 308)
vehTab:AddFeature(scriptHash + 309)
vehTab:AddFeature(scriptHash + 310)
vehTab:AddFeature(scriptHash + 311)
vehTab:AddFeature(scriptHash + 312)
vehTab:AddFeature(scriptHash + 313)
vehTab:AddSeperator("Guided Missiles")
vehTab:AddFeature(scriptHash + 300)
vehTab:AddFeature(scriptHash + 301)
vehTab:AddFeature(scriptHash + 302)

local miscTab = myTab:AddSubTab("Misc", "Blacklist & Tools")
miscTab:AddFeature(scriptHash + 199)
miscTab:AddFeature(scriptHash + 201)
miscTab:AddFeature(scriptHash + 206)
miscTab:AddSeperator("Environment Control")
miscTab:AddFeature(scriptHash + 400)
miscTab:AddFeature(scriptHash + 401)
miscTab:AddSeperator("Session Logger")
miscTab:AddFeature(scriptHash + 600)
miscTab:AddFeature(scriptHash + 601)
miscTab:AddSeperator("Management")
miscTab:AddFeature(scriptHash + 202)
miscTab:AddFeature(scriptHash + 203)
miscTab:AddFeature(scriptHash + 204)
miscTab:AddFeature(scriptHash + 205)
miscTab:AddSeperator("Tools")
miscTab:AddFeature(scriptHash + 90)
miscTab:AddFeature(scriptHash + 403)
miscTab:AddFeature(scriptHash + 91)
miscTab:AddFeature(scriptHash + 100)

local creditTab = myTab:AddSubTab("Credit", "Information")
FeatureMgr.AddFeature(scriptHash + 9999, "Developer: kalimelo", eFeatureType.Button, "Discord: https://discord.gg/kWNx2aKyrk", function() end)
creditTab:AddFeature(scriptHash + 9999)