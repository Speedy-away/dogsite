--[[
    ELLOSCRIPT v1.1
    Built for Cherax Mod Menu
    Credits: elloeu, Cherax Mod Menu, animusx1337 (Public Urinal)
]]

local InvokeBool   = Natives.InvokeBool
local InvokeFloat  = Natives.InvokeFloat
local InvokeInt    = Natives.InvokeInt
local InvokeString = Natives.InvokeString
local InvokeVoid   = Natives.InvokeVoid

local function InvokeV3(hash, ...)
    local x, y, z = Natives.InvokeV3(hash, ...)
    return V3.New(x, y, z)
end

local PLAYER = {
    PLAYER_ID = function()
        return InvokeInt(0x4F8644AF03D0E0D6)
    end,
    PLAYER_PED_ID = function()
        return InvokeInt(0xD80958FC74E988A6)
    end,
    GET_PLAYER_PED_SCRIPT_INDEX = function(player)
        return InvokeInt(0x50FAC3A3E030A6E1, player)
    end,
    GET_PLAYER_NAME = function(player)
        return InvokeString(0x6D0DE6A7B5DA71F8, player)
    end,
    IS_PLAYER_FREE_AIMING = function(player)
        return InvokeBool(0x2E397FD2ECD37C87, player)
    end,
    SET_PLAYER_INVINCIBLE = function(player, toggle)
        return InvokeVoid(0x239528EACDC3E7DE, player, toggle)
    end,
    CLEAR_PLAYER_WANTED_LEVEL = function(player)
        return InvokeVoid(0xB302540597885499, player)
    end,
    SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER = function(player, multiplier)
        return InvokeVoid(0x6DB47AA77FD94E09, player, multiplier + 0.0)
    end,
    SET_SUPER_JUMP_THIS_FRAME = function(player)
        return InvokeVoid(0x57FFF03E423A4C0B, player)
    end,
    RESTORE_PLAYER_STAMINA = function(player, amount)
        return InvokeVoid(0xA352C1B864CAFD33, player, amount + 0.0)
    end,
}

local ENTITY = {
    DOES_ENTITY_EXIST = function(entity)
        return InvokeBool(0x7239B21A38F536BA, entity)
    end,
    GET_ENTITY_COORDS = function(entity, alive)
        return InvokeV3(0x3FEF770D40960D5A, entity, alive)
    end,
    GET_ENTITY_HEADING = function(entity)
        return InvokeFloat(0xE83D4F9BA2A38914, entity)
    end,
    GET_ENTITY_FORWARD_VECTOR = function(entity)
        return InvokeV3(0x0A794A5A57F8DF91, entity)
    end,
    GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS = function(entity, ox, oy, oz)
        return InvokeV3(
            0x1899F328B0E12848,
            entity,
            ox + 0.0,
            oy + 0.0,
            oz + 0.0
        )
    end,
    SET_ENTITY_INVINCIBLE = function(entity, toggle)
        return InvokeVoid(0x3882114BDE571AD4, entity, toggle)
    end,
    SET_ENTITY_AS_MISSION_ENTITY = function(entity, p1, p2)
        return InvokeVoid(0xAD738C3085FE7E11, entity, p1, p2)
    end,
    SET_ENTITY_HEALTH = function(entity, health, instigator, weapon)
        return InvokeVoid(
            0x6B76DC1F3AE6E6A3,
            entity,
            health,
            instigator,
            weapon
        )
    end,
    APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS = function(
        entity,
        force_type,
        x,
        y,
        z,
        p5,
        direction_relative,
        force_relative,
        p8
    )
        return InvokeVoid(
            0x18FF00FC7EFF559E,
            entity,
            force_type,
            x + 0.0,
            y + 0.0,
            z + 0.0,
            p5,
            direction_relative,
            force_relative,
            p8
        )
    end,
    GET_ENTITY_VELOCITY = function(entity)
        return InvokeV3(0x4805D2B1D8CF94A9, entity)
    end,
    GET_ENTITY_HEALTH = function(entity)
        return InvokeInt(0xEEF059FAD016D209, entity)
    end,
    GET_ENTITY_MAX_HEALTH = function(entity)
        return InvokeInt(0x15D757606D170C3C, entity)
    end,
    IS_ENTITY_DEAD = function(entity, p1)
        return InvokeBool(0x5F9532F3B5CC2551, entity, p1)
    end,
    HAS_ENTITY_CLEAR_LOS_TO_ENTITY = function(entity1, entity2, flags)
        return InvokeBool(
            0xFCDFF7B72D23A1AC,
            entity1,
            entity2,
            flags
        )
    end,
    SET_ENTITY_COORDS_NO_OFFSET = function(entity, x, y, z, xAxis, yAxis, zAxis)
        return InvokeVoid(0x239A3351AC1DA385, entity, x + 0.0, y + 0.0, z + 0.0, xAxis, yAxis, zAxis)
    end,
    SET_ENTITY_HEADING = function(entity, heading)
        return InvokeVoid(0x8E2530AA8ADA980E, entity, heading + 0.0)
    end,
    FREEZE_ENTITY_POSITION = function(entity, toggle)
        return InvokeVoid(
            0x428CA6DBD1094446,
            entity,
            toggle
        )
    end,
    SET_ENTITY_ANGULAR_VELOCITY = function(entity, x, y, z)
        return InvokeVoid(
            0x8339643499D1222E,
            entity,
            x + 0.0,
            y + 0.0,
            z + 0.0
        )
    end,
    SET_ENTITY_ROTATION = function(
        entity,
        pitch,
        roll,
        yaw,
        rotation_order,
        p5
    )
        return InvokeVoid(
            0x8524A8B0171D5E07,
            entity,
            pitch + 0.0,
            roll + 0.0,
            yaw + 0.0,
            rotation_order,
            p5
        )
    end,
    SET_ENTITY_VISIBLE = function(entity, toggle, p2)
        return InvokeVoid(0xEA1C610A04DB6BBB, entity, toggle, p2)
    end,
    GET_ENTITY_MODEL = function(entity)
        return InvokeInt(0x9F47B058362C84B5, entity)
    end,
    GET_ENTITY_SPEED = function(entity)
        return InvokeFloat(0xD5037BA82E12416F, entity)
    end,
    SET_ENTITY_VELOCITY = function(entity, x, y, z)
        return InvokeVoid(
            0x1C99BB7B6E96D16F,
            entity,
            x + 0.0,
            y + 0.0,
            z + 0.0
        )
    end,
}

local PED = {
    IS_PED_A_PLAYER = function(ped)
        return InvokeBool(0x12534C348C6CB68B, ped)
    end,
    IS_PED_IN_VEHICLE = function(ped, vehicle, atGetIn)
        return InvokeBool(0xA3EE4A07279BB9DB, ped, vehicle, atGetIn)
    end,
    SET_PED_INTO_VEHICLE = function(ped, vehicle, seat)
        return InvokeVoid(0xF75B0D629E1C063D, ped, vehicle, seat)
    end,
    GET_VEHICLE_PED_IS_IN = function(ped, includeEntering)
        return InvokeInt(0x9A9112A0FE9A4713, ped, includeEntering)
    end,
    GET_PED_ARMOUR = function(ped)
        return InvokeInt(0x9483AF821605B1D8, ped)
    end,
    GET_PED_BONE_COORDS = function(ped, bone, ox, oy, oz)
        return InvokeV3(0x17C07FC640E86B4E, ped, bone, ox + 0.0, oy + 0.0, oz + 0.0)
    end,
    SET_PED_CAN_RAGDOLL = function(ped, toggle)
        return InvokeVoid(0xB128377056A54E2A, ped, toggle)
    end,
    SET_PED_ARMOUR = function(ped, amount)
        return InvokeVoid(
            0xCEA04D83135264CC,
            ped,
            amount
        )
    end,
    SET_PED_CONFIG_FLAG = function(ped, flag_id, value)
        return InvokeVoid(0x1913FE4CBF41C463, ped, flag_id, value)
    end,
    SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE = function(ped, state)
        return InvokeVoid(0x7A6535691B477C48, ped, state)
    end,
    CLEAR_PED_BLOOD_DAMAGE = function(ped)
        return InvokeVoid(0x8FE22675A5A45817, ped)
    end,
    RESET_PED_VISIBLE_DAMAGE = function(ped)
        return InvokeVoid(0x3AC1F7B898F30C05, ped)
    end,
    CLEAR_PED_WETNESS = function(ped)
        return InvokeVoid(0x9C720776DAA43E7E, ped)
    end,
}

local VEHICLE = {
    GET_VEHICLE_DOOR_LOCK_STATUS = function(vehicle)
        return InvokeInt(0x25BC98A59C2EA962, vehicle)
    end,
    SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER = function(vehicle, player, toggle)
        return InvokeVoid(0x517AAF684BB50CD1, vehicle, player, toggle)
    end,
    SET_VEHICLE_DOORS_LOCKED = function(vehicle, status)
        return InvokeVoid(0xB664292EAECF7FA6, vehicle, status)
    end,
    SET_VEHICLE_ENGINE_ON = function(vehicle, on, instantly, disableAutoStart)
        return InvokeVoid(0x2497C4717C8B881E, vehicle, on, instantly, disableAutoStart)
    end,
    SET_VEHICLE_FIXED = function(vehicle)
        return InvokeVoid(
            0x115722B1B9C14C1C,
            vehicle
        )
    end,
    SET_VEHICLE_DEFORMATION_FIXED = function(vehicle)
        return InvokeVoid(
            0x953DA1E1B12C0491,
            vehicle
        )
    end,
    SET_VEHICLE_DIRT_LEVEL = function(vehicle, dirt_level)
        return InvokeVoid(
            0x79D3B596FE44EE8B,
            vehicle,
            dirt_level + 0.0
        )
    end,
    SET_VEHICLE_TYRE_FIXED = function(vehicle, tyre_index)
        return InvokeVoid(
            0x6E13FC662B882D1D,
            vehicle,
            tyre_index
        )
    end,
    SET_VEHICLE_ON_GROUND_PROPERLY = function(vehicle, p1)
        return InvokeBool(
            0x49733E92263139D1,
            vehicle,
            p1 + 0.0
        )
    end,
    START_VEHICLE_HORN = function(
        vehicle,
        duration,
        mode,
        forever
    )
        return InvokeVoid(
            0x9C8C6504B5B63D2C,
            vehicle,
            duration,
            mode,
            forever
        )
    end,
    SET_VEHICLE_DOOR_OPEN = function(
        vehicle,
        door_id,
        loose,
        open_instantly
    )
        return InvokeVoid(
            0x7C65DAC73C35C862,
            vehicle,
            door_id,
            loose,
            open_instantly
        )
    end,
    SET_VEHICLE_DOORS_SHUT = function(vehicle, instantly)
        return InvokeVoid(
            0x781B3D62BB013EF5,
            vehicle,
            instantly
        )
    end,
    SET_VEHICLE_REDUCE_GRIP = function(vehicle, toggle)
        return InvokeVoid(
            0x222FF6A823D122E2,
            vehicle,
            toggle
        )
    end,
    SET_VEHICLE_REDUCE_GRIP_LEVEL = function(vehicle, level)
        return InvokeVoid(
            0x6DEE944E1EE90CFB,
            vehicle,
            level
        )
    end,
    SET_VEHICLE_UNDRIVEABLE = function(vehicle, toggle)
        return InvokeVoid(
            0x8ABA6AF54B942B95,
            vehicle,
            toggle
        )
    end,
    SET_VEHICLE_ENGINE_HEALTH = function(vehicle, health)
        return InvokeVoid(
            0x45F6D8EEF34ABEF1,
            vehicle,
            health + 0.0
        )
    end,
    SET_VEHICLE_TYRE_BURST = function(
        vehicle,
        tyre_index,
        on_rim,
        damage
    )
        return InvokeVoid(
            0xEC6A202EE4960385,
            vehicle,
            tyre_index,
            on_rim,
            damage + 0.0
        )
    end,
    SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED = function(vehicle, toggle)
        return InvokeVoid(0x4C7028F78FFD3681, vehicle, toggle)
    end,
    SET_VEHICLE_TYRES_CAN_BURST = function(vehicle, toggle)
        return InvokeVoid(0xEB9DC3C7D8596C46, vehicle, toggle)
    end,
    SET_VEHICLE_FORWARD_SPEED = function(vehicle, speed)
        return InvokeVoid(0xAB54A438726D25D5, vehicle, speed + 0.0)
    end,
    SET_VEHICLE_HANDBRAKE = function(vehicle, toggle)
        return InvokeVoid(0x684785568EF26A22, vehicle, toggle)
    end,
    GET_VEHICLE_DOOR_ANGLE_RATIO = function(vehicle, door_id)
        return InvokeFloat(0xFE3F9C29F7B32BD5, vehicle, door_id)
    end,
    GET_IS_VEHICLE_ENGINE_RUNNING = function(vehicle)
        return InvokeBool(0xAE31E7DF9B5B132E, vehicle)
    end,
}

local NETWORK = {
    NETWORK_IS_PLAYER_ACTIVE = function(player)
        return InvokeBool(0xB8DFD30D6973E135, player)
    end,
    NETWORK_REQUEST_CONTROL_OF_ENTITY = function(entity)
        return InvokeBool(0xB69317BF5E782347, entity)
    end,
    NETWORK_HAS_CONTROL_OF_ENTITY = function(entity)
        return InvokeBool(0x01BF60A500E28887, entity)
    end,
    SET_LOCAL_PLAYER_AS_GHOST = function(toggle, p1)
        return InvokeVoid(0x5FFE9B4144F9712F, toggle, p1)
    end,
    SET_NETWORK_VEHICLE_AS_GHOST = function(vehicle, toggle)
        return InvokeVoid(0x6274C4712850841E, vehicle, toggle)
    end,
}

local INTERIOR = {
    GET_INTERIOR_FROM_ENTITY = function(entity)
        return InvokeInt(0x2107BA504071A6BB, entity)
    end,

}

local STREAMING = {
    REQUEST_COLLISION_AT_COORD = function(x, y, z)
        return InvokeVoid(0x07503F7948F491A7, x + 0.0, y + 0.0, z + 0.0)
    end,
    CLEAR_FOCUS = function()
        return InvokeVoid(0x31B73D1EA9F01DA2)
    end,
}

local WEAPON = {
    GET_SELECTED_PED_WEAPON = function(ped)
        return InvokeInt(0x0A6DB4965674D243, ped)
    end,
    GET_CURRENT_PED_WEAPON_ENTITY_INDEX = function(ped)
        return InvokeInt(0x3B390A939AF0B5FC, ped, 0)
    end,
    GET_WEAPON_DAMAGE = function(weapon_hash, component_hash)
        return InvokeFloat(
            0x3133B907D8B32053,
            weapon_hash,
            component_hash or 0
        )
    end,
}

local CAM = {
    DO_SCREEN_FADE_IN = function(duration)
        return InvokeVoid(0xD4E8E24955024033, duration)
    end,

    DO_SCREEN_FADE_OUT = function(duration)
        return InvokeVoid(0x891B5B39AC6302AF, duration)
    end,
}

local GRAPHICS = {
    GET_SCREEN_COORD_FROM_WORLD_COORD = function(x, y, z, screenX, screenY)
        return InvokeBool(
            0x34E82F05DF2974F5,
            x + 0.0, y + 0.0, z + 0.0,
            screenX, screenY
        )
    end,
}

local FIRE = {
    ADD_EXPLOSION = function(
        x,
        y,
        z,
        explosion_type,
        damage_scale,
        audible,
        invisible,
        camera_shake
    )
        return InvokeVoid(
            0xE3AD2BDBAEE269AC,
            x + 0.0,
            y + 0.0,
            z + 0.0,
            explosion_type,
            damage_scale + 0.0,
            audible,
            invisible,
            camera_shake + 0.0
        )
    end,
}

local SCRIPT = "ELLOSCRIPT_"
local MAX_PLAYERS = 32

GUI.AddToast(
    "elloscript",
    "Starting ELLOSCRIPT v1.1...",
    3500
)

local HUD = {
    GET_FIRST_BLIP_INFO_ID = function(sprite)
        return InvokeInt(0x1BEDE233E6CD2A1F, sprite)
    end,
    GET_BLIP_INFO_ID_COORD = function(blip)
        return InvokeV3(0xFA7C7F0AADF25D09, blip)
    end,
    DOES_BLIP_EXIST = function(blip)
        return InvokeBool(0xA6DB27D19ECBB7DA, blip)
    end,
}

local MISC = {
    GET_GROUND_Z_FOR_3D_COORD = function(
        x,
        y,
        z,
        ground_z,
        ignore_water,
        p5
    )
        return InvokeBool(
            0xC906A7DAB05C8D2B,
            x + 0.0,
            y + 0.0,
            z + 0.0,
            ground_z,
            ignore_water,
            p5
        )
    end,
}

local H = {
    skeleton = Utils.Joaat(SCRIPT .. "SkeletonESP"),
    skeleton_color = Utils.Joaat(SCRIPT .. "SkeletonColor"),
    skeleton_thickness = Utils.Joaat(SCRIPT .. "SkeletonThickness"),
    skeleton_head_size = Utils.Joaat(SCRIPT .. "SkeletonHeadSize"),
    skeleton_tracers = Utils.Joaat(SCRIPT .. "SkeletonTracers"),

    box_esp = Utils.Joaat(SCRIPT .. "BoxESP"),
    health_bar_esp = Utils.Joaat(SCRIPT .. "HealthBarESP"),
    offscreen_arrows = Utils.Joaat(SCRIPT .. "OffscreenArrows"),
    selected_highlight = Utils.Joaat(SCRIPT .. "SelectedHighlight"),
    visible_only = Utils.Joaat(SCRIPT .. "VisiblePlayersOnly"),

    aim_part_highlight = Utils.Joaat(SCRIPT .. "AimPartHighlight"),
    armour_bar_esp = Utils.Joaat(SCRIPT .. "ArmourBarESP"),
    facing_direction = Utils.Joaat(SCRIPT .. "FacingDirection"),
    movement_direction = Utils.Joaat(SCRIPT .. "MovementDirection"),
    vehicle_esp = Utils.Joaat(SCRIPT .. "VehicleESP"),
    weapon_esp = Utils.Joaat(SCRIPT .. "WeaponESP"),
    show_dead_esp = Utils.Joaat(SCRIPT .. "ShowDeadESP"),

    nearby_counter = Utils.Joaat(SCRIPT .. "NearbyPlayerCounter"),

    self_skeleton = Utils.Joaat(SCRIPT .. "SelfSkeletonESP"),
    self_color = Utils.Joaat(SCRIPT .. "SelfESPColor"),
    self_thickness = Utils.Joaat(SCRIPT .. "SelfESPThickness"),
    self_head_size = Utils.Joaat(SCRIPT .. "SelfESPHeadSize"),
    self_box = Utils.Joaat(SCRIPT .. "SelfBoxESP"),
    self_health = Utils.Joaat(SCRIPT .. "SelfHealthESP"),
    self_armour = Utils.Joaat(SCRIPT .. "SelfArmourESP"),
    self_facing = Utils.Joaat(SCRIPT .. "SelfFacingESP"),
    self_movement = Utils.Joaat(SCRIPT .. "SelfMovementESP"),
    self_weapon = Utils.Joaat(SCRIPT .. "SelfWeaponESP"),
    self_show_dead = Utils.Joaat(SCRIPT .. "SelfShowDeadESP"),

    npc_skeletons = Utils.Joaat(SCRIPT .. "NPCSkeletons"),
    npc_color = Utils.Joaat(SCRIPT .. "NPCSkeletonColor"),
    npc_tracers = Utils.Joaat(SCRIPT .. "NPCSkeletonTracers"),
    npc_range = Utils.Joaat(SCRIPT .. "NPCSkeletonRange"),
    npc_max_count = Utils.Joaat(SCRIPT .. "NPCSkeletonMaxCount"),
    npc_refresh_ms = Utils.Joaat(SCRIPT .. "NPCSkeletonRefreshMs"),
    npc_thickness = Utils.Joaat(SCRIPT .. "NPCSkeletonThickness"),
    npc_head_size = Utils.Joaat(SCRIPT .. "NPCSkeletonHeadSize"),
    info_all = Utils.Joaat(SCRIPT .. "PlayerInfoAll"),
    save_position = Utils.Joaat(SCRIPT .. "SavePosition"),
    clear_position = Utils.Joaat(SCRIPT .. "ClearPosition"),
    info = Utils.Joaat(SCRIPT .. "PlayerInfoHUD"),
    return_position = Utils.Joaat(SCRIPT .. "ReturnPosition"),

    heal_armour = Utils.Joaat(SCRIPT .. "HealArmour"),
    repair_vehicle = Utils.Joaat(SCRIPT .. "RepairVehicle"),
    flip_vehicle = Utils.Joaat(SCRIPT .. "FlipVehicle"),
    cleanup_actions = Utils.Joaat(SCRIPT .. "CleanupActions"),

    horn_spam = Utils.Joaat(SCRIPT .. "HornSpam"),
    door_chaos = Utils.Joaat(SCRIPT .. "DoorChaos"),
    spin_vehicle = Utils.Joaat(SCRIPT .. "SpinVehicle"),

    engine_kill = Utils.Joaat(SCRIPT .. "EngineKill"),
    burst_tires = Utils.Joaat(SCRIPT .. "BurstTires"),
    freeze_vehicle = Utils.Joaat(SCRIPT .. "FreezeVehicle"),
    slam_vehicle = Utils.Joaat(SCRIPT .. "SlamVehicle"),

    kill_selected = Utils.Joaat(SCRIPT .. "KillSelected"),
    kill_loop = Utils.Joaat(SCRIPT .. "KillLoop"),
    kill_all = Utils.Joaat(SCRIPT .. "KillAll"),
    kill_all_loop = Utils.Joaat(SCRIPT .. "KillAllLoop"),
    orbital_selected = Utils.Joaat(SCRIPT .. "OrbitalSelected"),
    orbital_all = Utils.Joaat(SCRIPT .. "OrbitalAll"),
    explode_vehicle = Utils.Joaat(SCRIPT .. "ExplodeVehicle"),
    explode_all_vehicles =
        Utils.Joaat(SCRIPT .. "ExplodeAllVehicles"),

    god_mode = Utils.Joaat(SCRIPT .. "GodMode"),
    ghost_mode = Utils.Joaat(SCRIPT .. "GhostMode"),
    no_ragdoll = Utils.Joaat(SCRIPT .. "NoRagdoll"),
    never_wanted = Utils.Joaat(SCRIPT .. "NeverWanted"),
    unlimited_stamina = Utils.Joaat(SCRIPT .. "UnlimitedStamina"),
    super_run = Utils.Joaat(SCRIPT .. "SuperRun"),
    super_jump = Utils.Joaat(SCRIPT .. "SuperJump"),
    clean_character = Utils.Joaat(SCRIPT .. "CleanCharacter"),
    vehicle_god_mode = Utils.Joaat(SCRIPT .. "VehicleGodMode"),
    auto_repair = Utils.Joaat(SCRIPT .. "AutoRepair"),
    seatbelt = Utils.Joaat(SCRIPT .. "Seatbelt"),
    full_send = Utils.Joaat(SCRIPT .. "FullSend"),
    instant_stop = Utils.Joaat(SCRIPT .. "InstantStop"),
    vehicle_jump = Utils.Joaat(SCRIPT .. "VehicleJump"),
    barrel_roll = Utils.Joaat(SCRIPT .. "BarrelRoll"),
    moon_launch = Utils.Joaat(SCRIPT .. "MoonLaunch"),
    drift_mode = Utils.Joaat(SCRIPT .. "DriftMode"),
    keep_vehicle_locked = Utils.Joaat(SCRIPT .. "KeepVehicleLocked"),
    door_control = Utils.Joaat(SCRIPT .. "DoorControl"),
    toggle_engine = Utils.Joaat(SCRIPT .. "ToggleEngine"),
    teleport_waypoint = Utils.Joaat(SCRIPT .. "TeleportWaypoint"),
    teleport_player = Utils.Joaat(SCRIPT .. "TeleportPlayer"),

    bullet_reflector = Utils.Joaat(SCRIPT .. "BulletReflector"),
    pvp_ghost = Utils.Joaat(SCRIPT .. "PvPGhost"),
    auto_pvp_ghost = Utils.Joaat(SCRIPT .. "AutoPvPGhost"),

}

local NPC_DEFAULT_MAX_DRAW = 24
local NPC_DEFAULT_DISTANCE = 120.0
local NPC_DEFAULT_REFRESH_MS = 500
local NPC_CACHE_GRACE_MS = 1250

local npc_cache = {}
local npc_last_seen = {}
local next_npc_refresh_at = 0
local npc_scan_reported = false

local LOS_CACHE_MS = 300
local los_cache = {}

local screen_x_ptr = Memory.Alloc(4)
local screen_y_ptr = Memory.Alloc(4)

if screen_x_ptr == nil or screen_x_ptr == 0
    or screen_y_ptr == nil or screen_y_ptr == 0 then

    if screen_x_ptr ~= nil and screen_x_ptr ~= 0 then
        Memory.Free(screen_x_ptr)
    end

    if screen_y_ptr ~= nil and screen_y_ptr ~= 0 then
        Memory.Free(screen_y_ptr)
    end

    error("elloscript could not allocate world-to-screen buffers")
end

local saved = {
    valid = false,
    coords = nil,
    heading = 0.0,
    vehicle = 0,
}

local function recover_visual_state()
    if STREAMING ~= nil
        and type(STREAMING.CLEAR_FOCUS) == "function" then
        STREAMING.CLEAR_FOCUS()
    end

    if CAM ~= nil
        and type(CAM.DO_SCREEN_FADE_IN) == "function" then
        CAM.DO_SCREEN_FADE_IN(0)
    end
end

local function player_ped(player_id)
    if player_id == nil then return 0 end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    if ped == nil or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then
        return 0
    end
    return ped
end

local function local_ped()
    return PLAYER.PLAYER_PED_ID()
end

local function save_current_position()
    local ped = local_ped()
    if ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return false end

    local entity = ped
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if vehicle ~= nil and vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vehicle) then
        entity = vehicle
    else
        vehicle = 0
    end

    saved.coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    saved.heading = ENTITY.GET_ENTITY_HEADING(entity)
    saved.vehicle = vehicle
    saved.valid = saved.coords ~= nil
    return saved.valid
end

local function manually_save_current_position()
    if save_current_position() then
        local message = "Current position saved."

        if saved.vehicle ~= nil and saved.vehicle ~= 0 then
            message = message .. " Vehicle state included."
        end

        GUI.AddToast("elloscript", message, 3500)
    else
        GUI.AddToast(
            "elloscript",
            "Could not save the current position.",
            4000
        )
    end
end

local function clear_saved_position()
    saved.valid = false
    saved.coords = nil
    saved.heading = 0.0
    saved.vehicle = 0

    GUI.AddToast("elloscript", "Saved position cleared.", 3500)
end

local function request_control(entity, timeout_ms)
    if entity == nil or entity == 0 or not ENTITY.DOES_ENTITY_EXIST(entity) then
        return false
    end

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        return true
    end

    local started = Time.GetEpocheMs()
    while Time.GetEpocheMs() - started < (timeout_ms or 1200) do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
            return true
        end
        Script.Yield(0)
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

local function give_local_control(entity)
    if entity == nil
        or entity == 0
        or not ENTITY.DOES_ENTITY_EXIST(entity) then

        return false
    end

    if GTA ~= nil
        and type(GTA.GiveControl) == "function"
        and type(GTA.GetLocalPlayerId) == "function" then

        GTA.GiveControl(
            GTA.GetLocalPlayerId(),
            entity
        )
    end

    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)

    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

local function obtain_vehicle_control(vehicle)
    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then

        return false
    end

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        return true
    end

    give_local_control(vehicle)
    return request_control(vehicle, 1200)
end

local function resolve_selected_vehicle(player_id)
    local ped = player_ped(player_id)

    if ped == 0 then
        return 0, 0, "Selected player is not streamed."
    end

    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)

    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then

        return ped, 0, "Selected player is not in a streamed vehicle."
    end

    return ped, vehicle, nil
end

local extra_troll = {
    horn_spam = {},
    horn_generation = {},
    door_chaos = {},
    door_generation = {},
    door_vehicle = {},
    frozen = {},
    freeze_generation = {},
    frozen_vehicle = {},
}

do
    function extra_troll.set_horn_spam(
        player_id,
        enabled
    )
        extra_troll.horn_spam[player_id] =
            enabled == true

        extra_troll.horn_generation[player_id] =
            (extra_troll.horn_generation[player_id] or 0)
            + 1

        local token =
            extra_troll.horn_generation[player_id]

        if not enabled then
            return
        end

        Script.QueueJob(function()
            while extra_troll.horn_spam[player_id]
                and extra_troll.horn_generation[player_id]
                    == token do

                local _, vehicle =
                    resolve_selected_vehicle(
                        player_id
                    )

                if vehicle ~= 0
                    and obtain_vehicle_control(vehicle) then

                    VEHICLE.START_VEHICLE_HORN(
                        vehicle,
                        750,
                        Utils.Joaat("HELDDOWN"),
                        false
                    )
                end

                Script.Yield(500)
            end
        end)
    end

    local function restore_door_chaos_vehicle(player_id)
        local vehicle = extra_troll.door_vehicle[player_id]

        if vehicle ~= nil
            and vehicle ~= 0
            and ENTITY.DOES_ENTITY_EXIST(vehicle)
            and obtain_vehicle_control(vehicle) then

            VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, true)
        end

        extra_troll.door_vehicle[player_id] = nil
    end

    function extra_troll.set_door_chaos(player_id, enabled)
        extra_troll.door_chaos[player_id] = enabled == true
        extra_troll.door_generation[player_id] =
            (extra_troll.door_generation[player_id] or 0) + 1

        local token = extra_troll.door_generation[player_id]

        if not enabled then
            restore_door_chaos_vehicle(player_id)
            return
        end

        Script.QueueJob(function()
            local doors_open = false

            while extra_troll.door_chaos[player_id]
                and extra_troll.door_generation[player_id] == token do

                local _, vehicle = resolve_selected_vehicle(player_id)
                local previous = extra_troll.door_vehicle[player_id]

                if previous ~= nil
                    and previous ~= 0
                    and previous ~= vehicle
                    and ENTITY.DOES_ENTITY_EXIST(previous)
                    and obtain_vehicle_control(previous) then

                    VEHICLE.SET_VEHICLE_DOORS_SHUT(previous, true)
                end

                if vehicle ~= 0
                    and obtain_vehicle_control(vehicle) then

                    extra_troll.door_vehicle[player_id] = vehicle

                    if doors_open then
                        VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, true)
                    else
                        for door = 0, 7 do
                            VEHICLE.SET_VEHICLE_DOOR_OPEN(
                                vehicle,
                                door,
                                false,
                                true
                            )
                        end
                    end

                    doors_open = not doors_open
                end

                Script.Yield(350)
            end

            restore_door_chaos_vehicle(player_id)
        end)
    end

    function extra_troll.spin_vehicle(player_id)
        Script.QueueJob(function(id)
            local _, vehicle, err = resolve_selected_vehicle(id)

            if vehicle == 0 then
                GUI.AddToast("Spin Vehicle", tostring(err), 4500)
                return
            end

            if not obtain_vehicle_control(vehicle) then
                GUI.AddToast(
                    "Spin Vehicle",
                    "Could not obtain vehicle control.",
                    4500
                )
                return
            end

            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            local expires = Time.GetEpocheMs() + 2500

            while Time.GetEpocheMs() < expires
                and ENTITY.DOES_ENTITY_EXIST(vehicle) do

                local _, current_vehicle = resolve_selected_vehicle(id)

                if current_vehicle ~= vehicle then
                    break
                end

                if not obtain_vehicle_control(vehicle) then
                    break
                end

                heading = (heading + 24.0) % 360.0
                ENTITY.SET_ENTITY_HEADING(vehicle, heading)
                ENTITY.SET_ENTITY_ANGULAR_VELOCITY(
                    vehicle,
                    0.0,
                    0.0,
                    18.0
                )

                Script.Yield(50)
            end

            if ENTITY.DOES_ENTITY_EXIST(vehicle) then
                ENTITY.SET_ENTITY_ANGULAR_VELOCITY(
                    vehicle,
                    0.0,
                    0.0,
                    0.0
                )
            end
        end, player_id)
    end

    function extra_troll.engine_kill(player_id)
        local _, vehicle, err =
            resolve_selected_vehicle(player_id)

        if vehicle == 0 then
            GUI.AddToast(
                "Engine Kill",
                tostring(err),
                4500
            )
            return
        end

        if not obtain_vehicle_control(vehicle) then
            GUI.AddToast(
                "Engine Kill",
                "Could not obtain vehicle control.",
                4500
            )
            return
        end

        VEHICLE.SET_VEHICLE_ENGINE_ON(
            vehicle,
            false,
            true,
            true
        )
        VEHICLE.SET_VEHICLE_UNDRIVEABLE(
            vehicle,
            true
        )
        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(
            vehicle,
            -4000.0
        )

        GUI.AddToast(
            "Engine Kill",
            "Vehicle engine disabled.",
            3500
        )
    end

    function extra_troll.burst_tires(player_id)
        Script.QueueJob(function(id)
            local _, vehicle, err = resolve_selected_vehicle(id)

            if vehicle == 0 then
                GUI.AddToast("Burst Tires", tostring(err), 4500)
                return
            end

            if not obtain_vehicle_control(vehicle) then
                GUI.AddToast(
                    "Burst Tires",
                    "Could not obtain vehicle control.",
                    4500
                )
                return
            end

            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)

            for _, tyre in ipairs({
                0, 1, 2, 3, 4, 5, 45, 47
            }) do
                VEHICLE.SET_VEHICLE_TYRE_BURST(
                    vehicle,
                    tyre,
                    true,
                    1000.0
                )
            end
        end, player_id)
    end

    local function restore_frozen_vehicle(player_id)
        local vehicle =
            extra_troll.frozen_vehicle[player_id]

        if vehicle ~= nil
            and vehicle ~= 0
            and ENTITY.DOES_ENTITY_EXIST(vehicle) then

            obtain_vehicle_control(vehicle)
            ENTITY.FREEZE_ENTITY_POSITION(
                vehicle,
                false
            )
        end

        extra_troll.frozen_vehicle[player_id] =
            nil
    end

    function extra_troll.set_freeze_vehicle(
        player_id,
        enabled
    )
        extra_troll.frozen[player_id] =
            enabled == true

        extra_troll.freeze_generation[player_id] =
            (extra_troll.freeze_generation[player_id] or 0)
            + 1

        local token =
            extra_troll.freeze_generation[player_id]

        if not enabled then
            restore_frozen_vehicle(player_id)
            return
        end

        Script.QueueJob(function()
            while extra_troll.frozen[player_id]
                and extra_troll.freeze_generation[player_id]
                    == token do

                local _, vehicle =
                    resolve_selected_vehicle(player_id)

                local previous =
                    extra_troll.frozen_vehicle[player_id]

                if previous ~= nil
                    and previous ~= vehicle
                    and ENTITY.DOES_ENTITY_EXIST(previous) then

                    ENTITY.FREEZE_ENTITY_POSITION(
                        previous,
                        false
                    )
                end

                if vehicle ~= 0
                    and obtain_vehicle_control(vehicle) then

                    extra_troll.frozen_vehicle[player_id] =
                        vehicle

                    ENTITY.FREEZE_ENTITY_POSITION(
                        vehicle,
                        true
                    )
                end

                Script.Yield(350)
            end

            restore_frozen_vehicle(player_id)
        end)
    end

    function extra_troll.slam_vehicle(player_id)
        local _, vehicle, err =
            resolve_selected_vehicle(player_id)

        if vehicle == 0 then
            GUI.AddToast(
                "Slam Vehicle",
                tostring(err),
                4500
            )
            return
        end

        if not obtain_vehicle_control(vehicle) then
            GUI.AddToast(
                "Slam Vehicle",
                "Could not obtain vehicle control.",
                4500
            )
            return
        end

        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
            vehicle,
            1,
            0.0,
            0.0,
            -110.0,
            false,
            false,
            true,
            false
        )

        GUI.AddToast(
            "Slam Vehicle",
            "Downward force applied.",
            3000
        )
    end

    function extra_troll.cleanup()
        for player_id in pairs(extra_troll.horn_spam) do
            extra_troll.horn_spam[player_id] = false
            extra_troll.horn_generation[player_id] =
                (extra_troll.horn_generation[player_id] or 0) + 1
        end

        for player_id in pairs(extra_troll.door_chaos) do
            extra_troll.door_chaos[player_id] = false
            extra_troll.door_generation[player_id] =
                (extra_troll.door_generation[player_id] or 0) + 1
            restore_door_chaos_vehicle(player_id)
        end

        for player_id in pairs(extra_troll.frozen) do
            extra_troll.frozen[player_id] = false
            extra_troll.freeze_generation[player_id] =
                (extra_troll.freeze_generation[player_id] or 0) + 1
            restore_frozen_vehicle(player_id)
        end
    end
end

local function current_local_vehicle()
    local ped = local_ped()

    if ped == nil
        or ped == 0
        or not ENTITY.DOES_ENTITY_EXIST(ped) then

        return 0
    end

    local vehicle =
        PED.GET_VEHICLE_PED_IS_IN(
            ped,
            false
        )

    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then

        return 0
    end

    return vehicle
end

local function heal_and_armour_self()
    local ped = local_ped()

    if ped == 0 then
        return
    end

    local max_health =
        ENTITY.GET_ENTITY_MAX_HEALTH(ped)

    if max_health == nil or max_health <= 0 then
        max_health = 200
    end

    ENTITY.SET_ENTITY_HEALTH(
        ped,
        max_health,
        0,
        0
    )

    PED.SET_PED_ARMOUR(
        ped,
        100
    )

    GUI.AddToast(
        "Self Recovery",
        "Health and armour restored.",
        3000
    )
end

local function repair_current_vehicle()
    local vehicle =
        current_local_vehicle()

    if vehicle == 0 then
        GUI.AddToast(
            "Vehicle Repair",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    request_control(vehicle, 800)

    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(
        vehicle
    )
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(
        vehicle,
        0.0
    )
    VEHICLE.SET_VEHICLE_UNDRIVEABLE(
        vehicle,
        false
    )
    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(
        vehicle,
        1000.0
    )
    VEHICLE.SET_VEHICLE_ENGINE_ON(
        vehicle,
        true,
        true,
        false
    )

    for _, tyre in ipairs({
        0, 1, 2, 3, 4, 5, 45, 47
    }) do
        VEHICLE.SET_VEHICLE_TYRE_FIXED(
            vehicle,
            tyre
        )
    end

    GUI.AddToast(
        "Vehicle Repair",
        "Vehicle repaired, cleaned and tyres restored.",
        3500
    )
end

local function flip_current_vehicle()
    local vehicle =
        current_local_vehicle()

    if vehicle == 0 then
        GUI.AddToast(
            "Flip Vehicle",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    request_control(vehicle, 800)

    ENTITY.FREEZE_ENTITY_POSITION(
        vehicle,
        false
    )

    ENTITY.SET_ENTITY_ANGULAR_VELOCITY(
        vehicle,
        0.0,
        0.0,
        0.0
    )

    ENTITY.SET_ENTITY_ROTATION(
        vehicle,
        0.0,
        0.0,
        ENTITY.GET_ENTITY_HEADING(vehicle),
        2,
        true
    )

    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(
        vehicle,
        5.0
    )

    GUI.AddToast(
        "Flip Vehicle",
        "Vehicle placed upright.",
        3000
    )
end

local remote_damage = {
    ready = false,
    fn = nil,
    flags = 16 | 4096 | 524288,
    error = nil,
}

do
    local is_ee = false

    if Cherax ~= nil
        and type(Cherax.GetEdition) == "function" then

        local edition = Cherax.GetEdition()
        is_ee = edition == "EE"
    end

    local signature = is_ee
        and "E8 ? ? ? ? 66 90 FF C5"
        or "E8 ? ? ? ? 44 8B 7D 80"

    if Memory == nil
        or type(Memory.Scan) ~= "function" then

        remote_damage.error =
            "Memory.Scan is unavailable"
    else
        local address = Memory.Scan(signature)

        if address ~= nil
            and address ~= 0 then

            if type(Memory.Rip) ~= "function" then
                remote_damage.error =
                    "Memory.Rip is unavailable"
            else
                local fn = Memory.Rip(address + 1)

                if fn ~= nil
                    and fn ~= 0 then

                    remote_damage.fn = fn
                    remote_damage.ready = true
                else
                    remote_damage.error =
                        "Memory.Rip failed"
                end
            end
        else
            remote_damage.error =
                "damage signature not found"
        end
    end

    local zero_vector_argument =
        Natives.InvokeV3(
            0x3FEF770D40960D5A,
            0,
            false
        )

    remote_damage.send = function(
        player_id,
        weapon_name,
        amount
    )
        if not remote_damage.ready
            or remote_damage.fn == nil then

            return false,
                remote_damage.error
                    or "damage function is unavailable"
        end

        if Players == nil
            or type(Players.GetCPed)
                ~= "function" then

            return false,
                "Players.GetCPed is unavailable"
        end

        local target_cped =
            Players.GetCPed(player_id)

        if target_cped == nil then
            return false,
                "target CPed is unavailable"
        end

        local target_address = target_cped:GetAddress()

        if target_address == nil
            or target_address == 0 then

            return false,
                "target CPed address is invalid"
        end

        local local_id =
            PLAYER.PLAYER_ID()

        if GTA ~= nil
            and type(GTA.GetLocalPlayerId)
                == "function" then

            local id = GTA.GetLocalPlayerId()

            if id ~= nil then
                local_id = id
            end
        end

        local local_cped =
            Players.GetCPed(local_id)

        if local_cped == nil then
            return false,
                "local CPed is unavailable"
        end

        local local_address = local_cped:GetAddress()

        if local_address == nil
            or local_address == 0 then

            return false,
                "local CPed address is invalid"
        end

        local weapon_hash

        if type(Utils.sJoaat)
            == "function" then

            weapon_hash =
                Utils.sJoaat(weapon_name)
        else
            weapon_hash =
                Utils.Joaat(weapon_name)
        end

        if Memory == nil
            or type(Memory.LuaCallCFunction)
                ~= "function" then

            return false,
                "Memory.LuaCallCFunction is unavailable"
        end

        Memory.LuaCallCFunction(
            remote_damage.fn,
            local_address,
            target_address,
            target_address + 0x90,
            0,
            1,
            weapon_hash,
            amount or 2500.0,
            0,
            0,
            remote_damage.flags,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            zero_vector_argument
        )

        return true, nil
    end
end

local function kill_player(player_id)
    if player_id == nil
        or not NETWORK.NETWORK_IS_PLAYER_ACTIVE(
            player_id
        ) then

        return false,
            "Target is not active."
    end

    local sent, reason =
        remote_damage.send(
            player_id,
            "weapon_heavysniper_mk2",
            2500.0
        )

    if not sent then
        return false, reason
    end

    Script.Yield(120)

    remote_damage.send(
        player_id,
        "weapon_electric_fence",
        2500.0
    )

    return true, nil
end

local function kill_selected(player_id)
    local sent, reason =
        kill_player(player_id)

    if sent then
        GUI.AddToast(
            "Kill Selected",
            "Health action sent.",
            3500
        )
    else
        GUI.AddToast(
            "Kill Selected",
            tostring(reason),
            5000
        )
    end
end

local kill_loop_state = {
    enabled = {},
    generation = {},
    last_error = {},
}

local function script_should_unload()
    if type(ShouldUnload) ~= "function" then
        return false
    end

    return ShouldUnload() == true
end

local function set_kill_loop(
    player_id,
    enabled
)
    local generation =
        (kill_loop_state.generation[player_id] or 0)
        + 1

    kill_loop_state.generation[player_id] =
        generation

    if not enabled then
        kill_loop_state.enabled[player_id] = nil
        kill_loop_state.last_error[player_id] = nil

        GUI.AddToast(
            "Kill Loop",
            "Stopped.",
            3000
        )
        return
    end

    kill_loop_state.enabled[player_id] = true
    kill_loop_state.last_error[player_id] = nil

    GUI.AddToast(
        "Kill Loop",
        "Started for the selected player.",
        3500
    )

    Script.QueueJob(function()
        while kill_loop_state.enabled[player_id]
            and kill_loop_state.generation[player_id]
                == generation
            and not script_should_unload() do

            if not NETWORK.NETWORK_IS_PLAYER_ACTIVE(
                player_id
            ) then

                kill_loop_state.enabled[player_id] = nil

                GUI.AddToast(
                    "Kill Loop",
                    "Stopped because the player left.",
                    4000
                )
                break
            end

            local sent, reason =
                kill_player(player_id)

            if not sent
                and reason
                    ~= kill_loop_state.last_error[
                        player_id
                    ] then

                kill_loop_state.last_error[player_id] =
                    reason

            end

            Script.Yield(650)
        end
    end)
end

local function stop_all_kill_loops()
    for player_id in pairs(
        kill_loop_state.enabled
    ) do
        kill_loop_state.enabled[player_id] = nil
        kill_loop_state.generation[player_id] =
            (kill_loop_state.generation[player_id] or 0)
            + 1
    end
end

local function kill_all()
    local local_id = PLAYER.PLAYER_ID()
    local sent_count = 0
    local failure_count = 0

    for player_id = 0, MAX_PLAYERS - 1 do
        if player_id ~= local_id
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(
                player_id
            ) then

            local sent =
                kill_player(player_id)

            if sent then
                sent_count = sent_count + 1
            else
                failure_count =
                    failure_count + 1
            end

            Script.Yield(80)
        end
    end

    GUI.AddToast(
        "Kill All",
        "Damage sent to "
            .. tostring(sent_count)
            .. " players; "
            .. tostring(failure_count)
            .. " failed.",
        5000
    )
end

local kill_all_loop_state = {
    enabled = false,
    generation = 0,
    last_error = nil,
}

local function set_kill_all_loop(enabled)
    kill_all_loop_state.generation =
        kill_all_loop_state.generation + 1

    local generation = kill_all_loop_state.generation
    kill_all_loop_state.enabled = enabled == true
    kill_all_loop_state.last_error = nil

    if not kill_all_loop_state.enabled then
        GUI.AddToast(
            "Kill All Loop",
            "Stopped.",
            3000
        )
        return
    end

    GUI.AddToast(
        "Kill All Loop",
        "Started. Uses one throttled worker.",
        3500
    )

    Script.QueueJob(function()
        while kill_all_loop_state.enabled
            and kill_all_loop_state.generation == generation
            and not script_should_unload() do

            local local_id = PLAYER.PLAYER_ID()
            local active_targets = 0

            for player_id = 0, MAX_PLAYERS - 1 do
                if not kill_all_loop_state.enabled
                    or kill_all_loop_state.generation ~= generation
                    or script_should_unload() then
                    break
                end

                if player_id ~= local_id
                    and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

                    active_targets = active_targets + 1
                    local sent, reason = kill_player(player_id)

                    if not sent and reason ~= kill_all_loop_state.last_error then
                        kill_all_loop_state.last_error = reason
                    end

                    Script.Yield(90)
                end
            end

            Script.Yield(active_targets == 0 and 1000 or 500)
        end
    end)
end

local function stop_kill_all_loop_silent()
    kill_all_loop_state.enabled = false
    kill_all_loop_state.generation =
        kill_all_loop_state.generation + 1
    kill_all_loop_state.last_error = nil
end

local function orbital_strike_on_coords(x, y, z)
    FIRE.ADD_EXPLOSION(
        x, y, z,
        38, 10.0,
        true, false, 1.0
    )
    FIRE.ADD_EXPLOSION(
        x, y, z + 2.0,
        29, 8.0,
        true, false, 1.0
    )
    FIRE.ADD_EXPLOSION(
        x, y, z,
        59, 5.0,
        true, false, 0.8
    )
end

local function orbital_selected(player_id)
    local ped = player_ped(player_id)

    if ped == 0 then
        GUI.AddToast(
            "Orbital Cannon",
            "Selected player is not streamed.",
            4000
        )
        return
    end

    local coords =
        ENTITY.GET_ENTITY_COORDS(ped, true)

    if coords == nil then
        return
    end

    orbital_strike_on_coords(
        coords.x,
        coords.y,
        coords.z
    )
    local sent, reason =
        kill_player(player_id)

    GUI.AddToast(
        "Orbital Cannon",
        sent
            and "Strike and damage event delivered."
            or ("Strike effect delivered; damage failed: "
                .. tostring(reason)),
        5000
    )
end

local function orbital_all()
    local local_id = PLAYER.PLAYER_ID()
    local strike_count = 0
    local damage_count = 0

    for player_id = 0, MAX_PLAYERS - 1 do
        if player_id ~= local_id
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(
                player_id
            ) then

            local ped = player_ped(player_id)

            if ped ~= 0 then
                local coords =
                    ENTITY.GET_ENTITY_COORDS(
                        ped,
                        true
                    )

                if coords ~= nil then
                    orbital_strike_on_coords(
                        coords.x,
                        coords.y,
                        coords.z
                    )
                    strike_count =
                        strike_count + 1

                    local sent =
                        kill_player(player_id)

                    if sent then
                        damage_count =
                            damage_count + 1
                    end

                    Script.Yield(100)
                end
            end
        end
    end

    GUI.AddToast(
        "Orbital All",
        "Strikes: "
            .. tostring(strike_count)
            .. " | damage events: "
            .. tostring(damage_count),
        5000
    )
end

local function explode_vehicle_of(player_id)
    local ped = player_ped(player_id)

    if ped == 0 then
        GUI.AddToast(
            "Explode Vehicle",
            "Player not streamed.",
            4000
        )
        return
    end

    local vehicle =
        PED.GET_VEHICLE_PED_IS_IN(ped, false)

    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then

        GUI.AddToast(
            "Explode Vehicle",
            "Player is not in a vehicle.",
            4000
        )
        return
    end

    request_control(vehicle, 1800)

    local coords =
        ENTITY.GET_ENTITY_COORDS(vehicle, true)

    if coords ~= nil then
        FIRE.ADD_EXPLOSION(
            coords.x,
            coords.y,
            coords.z,
            7,
            10.0,
            true,
            false,
            1.0
        )
        FIRE.ADD_EXPLOSION(
            coords.x,
            coords.y,
            coords.z,
            5,
            8.0,
            true,
            false,
            1.0
        )
    end

    GUI.AddToast(
        "Explode Vehicle",
        "Vehicle explosion triggered.",
        3500
    )
end

local function explode_all_vehicles()
    local local_id = PLAYER.PLAYER_ID()
    local count = 0
    local seen = {}

    for player_id = 0, MAX_PLAYERS - 1 do
        if player_id ~= local_id
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

            local ped = player_ped(player_id)

            if ped ~= 0 then
                local vehicle =
                    PED.GET_VEHICLE_PED_IS_IN(
                        ped,
                        false
                    )

                if vehicle ~= nil
                    and vehicle ~= 0
                    and not seen[vehicle]
                    and ENTITY.DOES_ENTITY_EXIST(vehicle) then

                    seen[vehicle] = true
                    request_control(vehicle, 1200)

                    local coords =
                        ENTITY.GET_ENTITY_COORDS(
                            vehicle,
                            true
                        )

                    if coords ~= nil then
                        FIRE.ADD_EXPLOSION(
                            coords.x,
                            coords.y,
                            coords.z,
                            7,
                            10.0,
                            true,
                            false,
                            1.0
                        )
                        count = count + 1
                    end
                end
            end
        end
    end

    GUI.AddToast(
        "Explode All Vehicles",
        "Triggered "
            .. tostring(count)
            .. " unique vehicle explosions.",
        4500
    )
end

local utility_state = {
    unloading = false,
    god_mode = false,
    ghost_mode = false,
    no_ragdoll = false,
    never_wanted = false,
    unlimited_stamina = false,
    super_run = false,
    super_jump = false,
    vehicle_god_mode = false,
    auto_repair = false,
    seatbelt = false,
    drift_mode = false,
    keep_vehicle_locked = false,
    god_vehicle = 0,
    drift_vehicle = 0,
    locked_vehicle = 0,
    locked_vehicle_status = 1,
    next_auto_repair_at = 0,
}

local utility_features = {}

local function valid_entity(entity)
    return entity ~= nil
        and entity ~= 0
        and ENTITY.DOES_ENTITY_EXIST(entity)
end

local function local_travel_entity()
    local vehicle = current_local_vehicle()

    if vehicle ~= 0 then
        return vehicle
    end

    return local_ped()
end

local function restore_player_modes()
    local player = PLAYER.PLAYER_ID()
    local ped = local_ped()

    PLAYER.SET_PLAYER_INVINCIBLE(
        player,
        false
    )
    PLAYER.SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER(
        player,
        1.0
    )

    if valid_entity(ped) then
        ENTITY.SET_ENTITY_INVINCIBLE(
            ped,
            false
        )
        ENTITY.SET_ENTITY_VISIBLE(
            ped,
            true,
            false
        )
        PED.SET_PED_CAN_RAGDOLL(
            ped,
            true
        )
        PED.SET_PED_CONFIG_FLAG(
            ped,
            32,
            true
        )
        PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(
            ped,
            0
        )
    end
end

local function restore_vehicle_god_mode()
    local vehicle =
        utility_state.god_vehicle

    if valid_entity(vehicle) then
        ENTITY.SET_ENTITY_INVINCIBLE(
            vehicle,
            false
        )
        VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(
            vehicle,
            true
        )
        VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(
            vehicle,
            true
        )
    end

    utility_state.god_vehicle = 0
end

local function restore_drift_mode()
    local vehicle =
        utility_state.drift_vehicle

    if valid_entity(vehicle) then
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(
            vehicle,
            false
        )
        VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(
            vehicle,
            0
        )
    end

    utility_state.drift_vehicle = 0
end

local function restore_vehicle_lock()
    local vehicle =
        utility_state.locked_vehicle

    if valid_entity(vehicle) then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(
            vehicle,
            utility_state.locked_vehicle_status
        )

        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(
            vehicle,
            PLAYER.PLAYER_ID(),
            false
        )
    end

    utility_state.locked_vehicle = 0
    utility_state.locked_vehicle_status = 1
end

local function restore_all_utility_effects()
    restore_player_modes()
    restore_vehicle_god_mode()
    restore_drift_mode()
    restore_vehicle_lock()

    utility_state.god_mode = false
    utility_state.ghost_mode = false
    utility_state.no_ragdoll = false
    utility_state.never_wanted = false
    utility_state.unlimited_stamina = false
    utility_state.super_run = false
    utility_state.super_jump = false
    utility_state.vehicle_god_mode = false
    utility_state.auto_repair = false
    utility_state.seatbelt = false
    utility_state.drift_mode = false
    utility_state.keep_vehicle_locked = false
    utility_state.next_auto_repair_at = 0
end

local function disable_all_utility_features()
    for _, feature in pairs(
        utility_features
    ) do
        if feature ~= nil
            and feature:IsToggled() then

            feature:Toggle(false)
        end
    end

    restore_all_utility_effects()
end

local function maintain_player_modes()
    local player = PLAYER.PLAYER_ID()
    local ped = local_ped()

    if not valid_entity(ped) then
        return
    end

    if utility_state.god_mode then
        PLAYER.SET_PLAYER_INVINCIBLE(
            player,
            true
        )
        ENTITY.SET_ENTITY_INVINCIBLE(
            ped,
            true
        )
    end

    if utility_state.ghost_mode then
        ENTITY.SET_ENTITY_VISIBLE(
            ped,
            false,
            false
        )
    end

    if utility_state.no_ragdoll then
        PED.SET_PED_CAN_RAGDOLL(
            ped,
            false
        )
    end

    if utility_state.never_wanted then
        PLAYER.CLEAR_PLAYER_WANTED_LEVEL(
            player
        )
    end

    if utility_state.unlimited_stamina then
        PLAYER.RESTORE_PLAYER_STAMINA(
            player,
            1.0
        )
    end

    if utility_state.super_run then
        PLAYER.SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER(
            player,
            1.49
        )
    end

    if utility_state.seatbelt then
        PED.SET_PED_CONFIG_FLAG(
            ped,
            32,
            false
        )
        PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(
            ped,
            1
        )
    end
end

local function repair_vehicle_handle(vehicle)
    if not valid_entity(vehicle) then
        return false
    end

    request_control(vehicle, 500)

    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, false)
    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)
    VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, false)

    for _, tyre in ipairs({0, 1, 2, 3, 4, 5, 45, 47}) do
        VEHICLE.SET_VEHICLE_TYRE_FIXED(vehicle, tyre)
    end

    return true
end

local function maintain_vehicle_modes(now)
    local vehicle =
        current_local_vehicle()

    if utility_state.vehicle_god_mode then
        if vehicle ~= utility_state.god_vehicle then
            restore_vehicle_god_mode()
            utility_state.god_vehicle =
                vehicle
        end

        if valid_entity(vehicle) then
            ENTITY.SET_ENTITY_INVINCIBLE(
                vehicle,
                true
            )
            VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(
                vehicle,
                false
            )
            VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(
                vehicle,
                false
            )
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(
                vehicle,
                1000.0
            )
        end
    end

    if utility_state.auto_repair
        and valid_entity(vehicle)
        and now >= utility_state.next_auto_repair_at then

        utility_state.next_auto_repair_at =
            now + 1500

        repair_vehicle_handle(vehicle)
    end

    if utility_state.drift_mode then
        if vehicle ~= utility_state.drift_vehicle then
            restore_drift_mode()
            utility_state.drift_vehicle =
                vehicle
        end

        if valid_entity(vehicle) then
            VEHICLE.SET_VEHICLE_REDUCE_GRIP(
                vehicle,
                true
            )
            VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(
                vehicle,
                2
            )
        end
    end

    if utility_state.keep_vehicle_locked then
        if vehicle ~= utility_state.locked_vehicle then
            restore_vehicle_lock()

            if valid_entity(vehicle) then
                utility_state.locked_vehicle =
                    vehicle
                utility_state.locked_vehicle_status =
                    VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(
                        vehicle
                    )
            end
        end

        if valid_entity(vehicle) then
            request_control(vehicle, 250)

            VEHICLE.SET_VEHICLE_DOORS_LOCKED(
                vehicle,
                2
            )

            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(
                vehicle,
                PLAYER.PLAYER_ID(),
                false
            )
        end
    end
end

local function maintain_utility_modes()
    local now = Time.GetEpocheMs()

    maintain_player_modes()
    maintain_vehicle_modes(now)
end

local function clean_character()
    local ped = local_ped()

    if not valid_entity(ped) then
        return
    end

    PED.CLEAR_PED_BLOOD_DAMAGE(ped)
    PED.RESET_PED_VISIBLE_DAMAGE(ped)
    PED.CLEAR_PED_WETNESS(ped)

    toast(
        "Clean Character",
        "Blood, dirt and visible damage cleared.",
        3000
    )
end

local function full_send()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        toast(
            "Full Send",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    local speed =
        ENTITY.GET_ENTITY_SPEED(vehicle)

    local target_speed =
        math.min(
            math.max(speed + 25.0, 45.0),
            90.0
        )

    VEHICLE.SET_VEHICLE_FORWARD_SPEED(
        vehicle,
        target_speed
    )

    toast(
        "Full Send",
        "Speed boost applied.",
        2500
    )
end

local function instant_stop()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        toast(
            "Instant Stop",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    VEHICLE.SET_VEHICLE_HANDBRAKE(
        vehicle,
        true
    )
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(
        vehicle,
        0.0
    )
    ENTITY.SET_ENTITY_VELOCITY(
        vehicle,
        0.0,
        0.0,
        0.0
    )

    Script.QueueJob(function(stopped_vehicle)
        Script.Yield(250)

        if valid_entity(stopped_vehicle) then
            VEHICLE.SET_VEHICLE_HANDBRAKE(
                stopped_vehicle,
                false
            )
        end
    end, vehicle)
end

local function jump_current_vehicle()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        toast(
            "Vehicle Jump",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
        vehicle,
        1,
        0.0,
        0.0,
        18.0,
        false,
        false,
        true,
        false
    )
end

local function barrel_roll_current_vehicle()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        GUI.AddToast("Barrel Roll", "Enter a vehicle first.", 3000)
        return
    end

    ENTITY.SET_ENTITY_ANGULAR_VELOCITY(vehicle, 0.0, 5.5, 0.0)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
        vehicle, 1, 0.0, 0.0, 3.0, true, true, true, true
    )
    GUI.AddToast("Barrel Roll", "Do a barrel roll!", 2500)
end

local function moon_launch_current_vehicle()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        GUI.AddToast("Moon Launch", "Enter a vehicle first.", 3000)
        return
    end

    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
        vehicle, 1, 0.0, 0.0, 28.0, true, true, true, true
    )
    GUI.AddToast("Moon Launch", "Vehicle launched upward.", 2500)
end

local function toggle_current_vehicle_doors()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        toast(
            "Door Control",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    local first_door_open =
        VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(
            vehicle,
            0
        ) > 0.05

    if first_door_open then
        VEHICLE.SET_VEHICLE_DOORS_SHUT(
            vehicle,
            false
        )
        toast(
            "Door Control",
            "Doors closed.",
            2500
        )
        return
    end

    for door = 0, 7 do
        VEHICLE.SET_VEHICLE_DOOR_OPEN(
            vehicle,
            door,
            false,
            false
        )
    end

    toast(
        "Door Control",
        "Available doors opened.",
        2500
    )
end

local function toggle_current_vehicle_engine()
    local vehicle = current_local_vehicle()

    if vehicle == 0 then
        toast(
            "Toggle Engine",
            "You are not in a vehicle.",
            3500
        )
        return
    end

    local running =
        VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(
            vehicle
        )

    VEHICLE.SET_VEHICLE_ENGINE_ON(
        vehicle,
        not running,
        true,
        running
    )

    toast(
        "Toggle Engine",
        running
            and "Engine switched off."
            or "Engine switched on.",
        2500
    )
end

local function teleport_to_waypoint()
    local waypoint =
        HUD.GET_FIRST_BLIP_INFO_ID(8)

    if waypoint == nil
        or waypoint == 0
        or not HUD.DOES_BLIP_EXIST(waypoint) then

        toast(
            "Teleport To Waypoint",
            "Set a waypoint on the map first.",
            4000
        )
        return
    end

    local destination =
        HUD.GET_BLIP_INFO_ID_COORD(
            waypoint
        )

    if destination == nil then
        return
    end

    local entity = local_travel_entity()

    if not valid_entity(entity) then
        return
    end

    save_current_position()
    CAM.DO_SCREEN_FADE_OUT(200)
    Script.Yield(220)

    ENTITY.FREEZE_ENTITY_POSITION(
        entity,
        true
    )

    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
        entity,
        destination.x,
        destination.y,
        1000.0,
        false,
        false,
        false
    )

    local ground_ptr =
        Memory.Alloc(4)

    local ground_found = false
    local ground_z = destination.z

    if ground_ptr ~= nil
        and ground_ptr ~= 0 then

        for probe_z = 1000, 0, -50 do
            STREAMING.REQUEST_COLLISION_AT_COORD(
                destination.x,
                destination.y,
                probe_z
            )

            Script.Yield(45)

            if MISC.GET_GROUND_Z_FOR_3D_COORD(
                destination.x,
                destination.y,
                probe_z,
                ground_ptr,
                false,
                false
            ) then
                ground_z =
                    Memory.ReadFloat(
                        ground_ptr
                    )
                ground_found = true
                break
            end
        end

        Memory.Free(ground_ptr)
    end

    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
        entity,
        destination.x,
        destination.y,
        ground_found
            and ground_z + 1.0
            or destination.z + 1.0,
        false,
        false,
        false
    )

    ENTITY.FREEZE_ENTITY_POSITION(
        entity,
        false
    )

    CAM.DO_SCREEN_FADE_IN(250)

    toast(
        "Teleport To Waypoint",
        ground_found
            and "Arrived at the waypoint."
            or "Arrived; ground height was unavailable.",
        3500
    )
end

local function teleport_to_selected_player(
    player_id
)
    local target =
        player_ped(player_id)

    if target == 0 then
        toast(
            "Teleport To Player",
            "Selected player is not streamed.",
            4000
        )
        return
    end

    local destination =
        ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            target,
            0.0,
            -2.5,
            0.2
        )

    if destination == nil then
        return
    end

    local entity = local_travel_entity()

    if not valid_entity(entity) then
        return
    end

    save_current_position()

    STREAMING.REQUEST_COLLISION_AT_COORD(
        destination.x,
        destination.y,
        destination.z
    )

    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
        entity,
        destination.x,
        destination.y,
        destination.z,
        false,
        false,
        false
    )

    ENTITY.SET_ENTITY_HEADING(
        entity,
        ENTITY.GET_ENTITY_HEADING(
            target
        )
    )

    toast(
        "Teleport To Player",
        "Moved behind the selected player.",
        3000
    )
end

Script.QueueJob(function()
    while not utility_state.unloading do
        maintain_utility_modes()
        Script.Yield(200)
    end
end)

local function return_to_saved()
    if not saved.valid or saved.coords == nil then
        toast("elloscript", "No previous position has been saved.")
        return
    end

    local me = local_ped()
    local entity = me
    local current_vehicle = PED.GET_VEHICLE_PED_IS_IN(me, false)
    if saved.vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(saved.vehicle) then
        entity = saved.vehicle
        if not PED.IS_PED_IN_VEHICLE(me, saved.vehicle, false) then
            PED.SET_PED_INTO_VEHICLE(me, saved.vehicle, -1)
        end
    elseif current_vehicle ~= nil and current_vehicle ~= 0 then
        entity = current_vehicle
    end

    STREAMING.REQUEST_COLLISION_AT_COORD(saved.coords.x, saved.coords.y, saved.coords.z)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
        entity, saved.coords.x, saved.coords.y, saved.coords.z,
        false, false, false
    )
    ENTITY.SET_ENTITY_HEADING(entity, saved.heading)
    toast("elloscript", "Returned to the saved position.")
end

local function world_to_screen(pos)
    if pos == nil then
        return nil
    end

    local visible = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(
        pos.x,
        pos.y,
        pos.z,
        screen_x_ptr,
        screen_y_ptr
    )

    if not visible then
        return nil
    end

    local normalized_x = Memory.ReadFloat(screen_x_ptr)
    local normalized_y = Memory.ReadFloat(screen_y_ptr)
    local width, height = ImGui.GetDisplaySize()

    if width == nil or height == nil then
        return nil
    end

    return {
        x = normalized_x * width,
        y = normalized_y * height
    }
end

local function bone_screen(ped, bone_id)
    local pos = PED.GET_PED_BONE_COORDS(ped, bone_id, 0.0, 0.0, 0.0)
    return world_to_screen(pos)
end

local function skeleton_lod(distance)
    distance = distance or 0.0

    if distance <= 28.0 then
        return 3
    end

    if distance <= 80.0 then
        return 2
    end

    if distance <= 180.0 then
        return 1
    end

    return 0
end

local collect_player_points = (function()
    local points = {}
    local left_fingers = {
        {}, {}, {}, {}, {}
    }
    local right_fingers = {
        {}, {}, {}, {}, {}
    }

    local function sample_finger(target, index, ped, a, b, c)
        local finger = target[index]
        finger[1] = bone_screen(ped, a)
        finger[2] = bone_screen(ped, b)
        finger[3] = bone_screen(ped, c)
    end

    return function(ped, distance, now)
        if ped == nil or ped == 0 then
            return nil
        end

        local lod = skeleton_lod(distance)

        points.head = bone_screen(ped, 31086)
        points.neck = bone_screen(ped, 39317)
        points.pelvis = bone_screen(ped, 11816)
        points.left_shoulder = bone_screen(ped, 45509)
        points.right_shoulder = bone_screen(ped, 40269)
        points.left_hand = bone_screen(ped, 18905)
        points.right_hand = bone_screen(ped, 57005)
        points.left_knee = bone_screen(ped, 63931)
        points.right_knee = bone_screen(ped, 36864)
        points.left_foot = bone_screen(ped, 14201)
        points.right_foot = bone_screen(ped, 52301)
        points.left_toe = bone_screen(ped, 2108)
        points.right_toe = bone_screen(ped, 20781)
        points.lod = lod

        if lod >= 1 then
            points.spine_root = bone_screen(ped, 57597)
            points.spine_upper = bone_screen(ped, 24818)
            points.spine_mid = bone_screen(ped, 24817)
            points.spine_lower = bone_screen(ped, 24816)
            points.left_elbow = bone_screen(ped, 61163)
            points.right_elbow = bone_screen(ped, 28252)
            points.left_hip = bone_screen(ped, 58271)
            points.right_hip = bone_screen(ped, 51826)
        else
            points.spine_root = nil
            points.spine_upper = nil
            points.spine_mid = nil
            points.spine_lower = nil
            points.left_elbow = nil
            points.right_elbow = nil
            points.left_hip = nil
            points.right_hip = nil
        end

        if lod >= 3 then
            sample_finger(left_fingers, 1, ped, 26610, 4089, 4090)
            sample_finger(left_fingers, 2, ped, 26611, 4169, 4170)
            sample_finger(left_fingers, 3, ped, 26612, 4185, 4186)
            sample_finger(left_fingers, 4, ped, 26613, 4137, 4138)
            sample_finger(left_fingers, 5, ped, 26614, 4153, 4154)

            sample_finger(right_fingers, 1, ped, 58866, 64016, 64017)
            sample_finger(right_fingers, 2, ped, 58867, 64096, 64097)
            sample_finger(right_fingers, 3, ped, 58868, 64112, 64113)
            sample_finger(right_fingers, 4, ped, 58869, 64064, 64065)
            sample_finger(right_fingers, 5, ped, 58870, 64080, 64081)

            points.left_fingers = left_fingers
            points.right_fingers = right_fingers
        else
            points.left_fingers = nil
            points.right_fingers = nil
        end

        return points
    end
end)()

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function distance_between(a, b)
    if a == nil or b == nil then
        return 0.0
    end

    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function get_skeleton_style(distance)
    local r, g, b, a = FeatureMgr.GetFeatureColor(H.skeleton_color)
    local base_thickness = FeatureMgr.GetFeatureFloat(H.skeleton_thickness)
    local head_size = FeatureMgr.GetFeatureFloat(H.skeleton_head_size)

    if r == nil then r = 0 end
    if g == nil then g = 255 end
    if b == nil then b = 170 end
    if a == nil then a = 235 end
    if base_thickness == nil or base_thickness <= 0.0 then
        base_thickness = 2.0
    end
    if head_size == nil or head_size <= 0.0 then
        head_size = 0.9
    end

    local distance_scale = clamp(1.10 - ((distance or 0.0) / 260.0), 0.42, 1.0)
    local thickness = math.max(1.0, base_thickness * distance_scale)

    return {
        r = r,
        g = g,
        b = b,
        a = a,
        thickness = thickness,
        head_size = head_size,
        distance_scale = distance_scale
    }
end

local function get_npc_options()
    local range =
        FeatureMgr.GetFeatureFloat(H.npc_range)

    local max_count =
        FeatureMgr.GetFeatureInt(H.npc_max_count)

    local refresh_ms =
        FeatureMgr.GetFeatureInt(H.npc_refresh_ms)

    if range == nil or range < 10.0 then
        range = NPC_DEFAULT_DISTANCE
    end

    if max_count == nil or max_count < 1 then
        max_count = NPC_DEFAULT_MAX_DRAW
    end

    if refresh_ms == nil or refresh_ms < 100 then
        refresh_ms = NPC_DEFAULT_REFRESH_MS
    end

    return range, max_count, refresh_ms
end

local function get_npc_style(distance)
    local r, g, b, a =
        FeatureMgr.GetFeatureColor(H.npc_color)

    local base_thickness =
        FeatureMgr.GetFeatureFloat(H.npc_thickness)

    local head_size =
        FeatureMgr.GetFeatureFloat(H.npc_head_size)

    if r == nil then r = 255 end
    if g == nil then g = 130 end
    if b == nil then b = 30 end
    if a == nil then a = 235 end

    if base_thickness == nil
        or base_thickness <= 0.0 then

        base_thickness = 1.8
    end

    if head_size == nil
        or head_size <= 0.0 then

        head_size = 0.85
    end

    local distance_scale =
        clamp(
            1.10 - ((distance or 0.0) / 300.0),
            0.42,
            1.0
        )

    return {
        r = r,
        g = g,
        b = b,
        a = a,
        thickness =
            math.max(
                1.0,
                base_thickness * distance_scale
            ),
        head_size = head_size,
        distance_scale = distance_scale
    }
end

local function draw_line(a, b, style, multiplier)
    if a == nil or b == nil or style == nil then
        return
    end

    ImGui.AddLine(
        a.x,
        a.y,
        b.x,
        b.y,
        style.r,
        style.g,
        style.b,
        style.a,
        math.max(1.0, style.thickness * (multiplier or 1.0))
    )
end

local function draw_tracer(target_pelvis, local_pelvis, style)
    if target_pelvis == nil or style == nil then
        return
    end

    local start_point = local_pelvis
    if start_point == nil then
        local width, height = ImGui.GetDisplaySize()
        start_point = {
            x = width * 0.5,
            y = height - 4.0
        }
    end

    ImGui.AddLine(
        start_point.x,
        start_point.y,
        target_pelvis.x,
        target_pelvis.y,
        style.r,
        style.g,
        style.b,
        math.min(style.a, 185),
        math.max(1.0, style.thickness * 0.65)
    )
end

local function opposite_style(style)
    return {
        r = 255 - style.r,
        g = 255 - style.g,
        b = 255 - style.b,
        a = style.a,
        thickness = style.thickness,
        head_size = style.head_size,
        distance_scale = style.distance_scale
    }
end

local function point_distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function point_to_segment_distance(px, py, a, b)
    if a == nil or b == nil then
        return math.huge
    end

    local vx = b.x - a.x
    local vy = b.y - a.y
    local length_squared = vx * vx + vy * vy

    if length_squared <= 0.0001 then
        return point_distance(px, py, a.x, a.y)
    end

    local t = (
        ((px - a.x) * vx)
        + ((py - a.y) * vy)
    ) / length_squared

    t = clamp(t, 0.0, 1.0)

    local closest_x = a.x + (vx * t)
    local closest_y = a.y + (vy * t)

    return point_distance(px, py, closest_x, closest_y)
end

local function skeleton_head_radius(points, style, distance)
    if points == nil
        or points.head == nil
        or style == nil then
        return nil
    end

    local scale = style.distance_scale or 1.0
    local requested = style.head_size or 1.0
    return clamp(5.5 * requested * scale, 2.8, 8.5)
end

local function find_aimed_skeleton_part(
    points,
    style,
    distance,
    crosshair_x,
    crosshair_y
)
    if points == nil
        or crosshair_x == nil
        or crosshair_y == nil then
        return nil
    end

    local threshold = math.max(10.0, style.thickness * 4.0)
    local best_part = nil
    local best_distance = threshold

    local radius = skeleton_head_radius(points, style, distance)

    if radius ~= nil then
        local head_distance = point_distance(
            crosshair_x,
            crosshair_y,
            points.head.x,
            points.head.y
        )

        if head_distance <= radius + 4.0 then
            best_part = "head"
            best_distance = head_distance
        end
    end

    local segments = {
        { "shoulders", points.left_shoulder, points.right_shoulder },
        { "left_arm", points.left_shoulder, points.left_hand },
        { "right_arm", points.right_shoulder, points.right_hand },
        { "spine", points.neck, points.pelvis },
        { "left_thigh", points.pelvis, points.left_knee },
        { "left_shin", points.left_knee, points.left_foot },
        { "right_thigh", points.pelvis, points.right_knee },
        { "right_shin", points.right_knee, points.right_foot }
    }

    for _, segment in ipairs(segments) do
        local segment_distance = point_to_segment_distance(
            crosshair_x,
            crosshair_y,
            segment[2],
            segment[3]
        )

        if segment_distance < best_distance then
            best_distance = segment_distance
            best_part = segment[1]
        end
    end

    return best_part
end

local function draw_direction_arrow(start_point, end_point, style)
    if start_point == nil
        or end_point == nil
        or style == nil then
        return
    end

    local dx = end_point.x - start_point.x
    local dy = end_point.y - start_point.y
    local length = math.sqrt(dx * dx + dy * dy)

    if length < 4.0 then
        return
    end

    local dir_x = dx / length
    local dir_y = dy / length
    local perp_x = -dir_y
    local perp_y = dir_x
    local wing_length = 6.0

    local wing_base_x = end_point.x - (dir_x * wing_length)
    local wing_base_y = end_point.y - (dir_y * wing_length)

    local left = {
        x = wing_base_x + (perp_x * 4.0),
        y = wing_base_y + (perp_y * 4.0)
    }

    local right = {
        x = wing_base_x - (perp_x * 4.0),
        y = wing_base_y - (perp_y * 4.0)
    }

    draw_line(start_point, end_point, style, 0.85)
    draw_line(end_point, left, style, 0.85)
    draw_line(end_point, right, style, 0.85)
end

local function draw_facing_direction_indicator(
    ped,
    coords,
    points,
    style
)
    if points == nil or points.head == nil then
        return
    end

    local end_world = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        ped,
        0.0,
        1.75,
        0.95
    )

    if end_world == nil then
        return
    end

    draw_direction_arrow(
        points.head,
        world_to_screen(end_world),
        style
    )
end

local function draw_movement_direction_indicator(
    ped,
    coords,
    points,
    style
)
    if points == nil or points.pelvis == nil then
        return
    end

    local velocity = ENTITY.GET_ENTITY_VELOCITY(ped)

    if velocity == nil then
        return
    end

    local horizontal_speed = math.sqrt(
        velocity.x * velocity.x
        + velocity.y * velocity.y
    )

    if horizontal_speed < 0.45 then
        return
    end

    local length = clamp(1.15 + (horizontal_speed * 0.08), 1.25, 3.25)
    local nx = velocity.x / horizontal_speed
    local ny = velocity.y / horizontal_speed

    local end_world = V3.New(
        coords.x + (nx * length),
        coords.y + (ny * length),
        coords.z + 0.85
    )

    draw_direction_arrow(
        points.pelvis,
        world_to_screen(end_world),
        style
    )
end

local function draw_simple_skeleton(
    points,
    distance,
    local_pelvis,
    style_override,
    tracers_enabled,
    aimed_part
)
    if points == nil then
        return
    end

    local style = style_override or get_skeleton_style(distance)
    local inverse = aimed_part ~= nil and opposite_style(style) or nil

    local function style_for(part_name)
        if inverse ~= nil and aimed_part == part_name then
            return inverse
        end

        return style
    end

    if points.head ~= nil and points.neck ~= nil then
        local radius = skeleton_head_radius(points, style, distance)
        local head_style = style_for("head")

        ImGui.AddCircle(
            points.head.x,
            points.head.y,
            radius,
            head_style.r,
            head_style.g,
            head_style.b,
            head_style.a,
            distance ~= nil and distance > 100.0 and 12 or 20,
            head_style.thickness
        )
    end

    draw_line(
        points.left_shoulder,
        points.right_shoulder,
        style_for("shoulders")
    )

    if points.left_elbow ~= nil then
        draw_line(points.left_shoulder, points.left_elbow, style_for("left_upper_arm"))
        draw_line(points.left_elbow, points.left_hand, style_for("left_forearm"))
    else
        draw_line(points.left_shoulder, points.left_hand, style_for("left_arm"))
    end

    if points.right_elbow ~= nil then
        draw_line(points.right_shoulder, points.right_elbow, style_for("right_upper_arm"))
        draw_line(points.right_elbow, points.right_hand, style_for("right_forearm"))
    else
        draw_line(points.right_shoulder, points.right_hand, style_for("right_arm"))
    end

    local function draw_finger_set(hand, fingers, prefix)
        if hand == nil or fingers == nil then
            return
        end

        for finger_index, chain in ipairs(fingers) do
            local base = chain[1]
            local middle = chain[2]
            local tip = chain[3]
            local part = prefix .. "_finger_" .. tostring(finger_index)

            draw_line(hand, base, style_for(part))
            draw_line(base, middle, style_for(part))
            draw_line(middle, tip, style_for(part))
        end
    end

    draw_finger_set(points.left_hand, points.left_fingers, "left")
    draw_finger_set(points.right_hand, points.right_fingers, "right")

    if points.spine_upper ~= nil
        and points.spine_mid ~= nil
        and points.spine_lower ~= nil then
        draw_line(points.neck, points.spine_upper, style_for("upper_spine"))
        draw_line(points.spine_upper, points.spine_mid, style_for("middle_spine"))
        draw_line(points.spine_mid, points.spine_lower, style_for("lower_spine"))
        if points.spine_root ~= nil then
            draw_line(points.spine_lower, points.spine_root, style_for("spine_root"))
            draw_line(points.spine_root, points.pelvis, style_for("pelvis_spine"))
        else
            draw_line(points.spine_lower, points.pelvis, style_for("pelvis_spine"))
        end
    else
        draw_line(points.neck, points.pelvis, style_for("spine"))
    end

    local left_leg_origin = points.left_hip or points.pelvis
    local right_leg_origin = points.right_hip or points.pelvis

    if points.left_hip ~= nil and points.right_hip ~= nil then
        draw_line(points.left_hip, points.right_hip, style_for("hips"))
        draw_line(points.pelvis, points.left_hip, style_for("left_hip"))
        draw_line(points.pelvis, points.right_hip, style_for("right_hip"))
    end

    draw_line(left_leg_origin, points.left_knee, style_for("left_thigh"))
    draw_line(points.left_knee, points.left_foot, style_for("left_shin"))
    draw_line(right_leg_origin, points.right_knee, style_for("right_thigh"))
    draw_line(points.right_knee, points.right_foot, style_for("right_shin"))

    if points.left_toe ~= nil then
        draw_line(points.left_foot, points.left_toe, style_for("left_foot"), 1.15)
    end
    if points.right_toe ~= nil then
        draw_line(points.right_foot, points.right_toe, style_for("right_foot"), 1.15)
    end

    if (points.lod or 0) >= 1 then
        local joint_radius = math.max(1.5, 2.4 * (style.distance_scale or 1.0))
        local joint_style = style_for("joints")
        local joints = {
            points.left_elbow, points.right_elbow,
            points.left_hand, points.right_hand,
            points.left_knee, points.right_knee,
            points.left_foot, points.right_foot,
            points.left_toe, points.right_toe
        }
        for _, joint in ipairs(joints) do
            if joint ~= nil then
                ImGui.AddCircleFilled(
                    joint.x, joint.y, joint_radius,
                    joint_style.r, joint_style.g, joint_style.b, joint_style.a,
                    8
                )
            end
        end
    end

    if tracers_enabled then
        draw_tracer(points.pelvis, local_pelvis, style)
    end
end

local function clone_style(style)
    return {
        r = style.r,
        g = style.g,
        b = style.b,
        a = style.a,
        thickness = style.thickness,
        head_size = style.head_size,
        distance_scale = style.distance_scale
    }
end

local function highlighted_style(style)
    local highlighted = clone_style(style)

    highlighted.r = 255
    highlighted.g = 205
    highlighted.b = 45
    highlighted.a = 255
    highlighted.thickness = math.max(
        1.5,
        highlighted.thickness * 1.35
    )

    return highlighted
end

local function player_has_clear_los(
    local_ped_handle,
    target_ped,
    player_id
)
    local now = Time.GetEpocheMs()
    local cached = los_cache[player_id]

    if cached ~= nil
        and cached.ped == target_ped
        and now - cached.checked_at < LOS_CACHE_MS then
        return cached.value
    end

    local value =
        ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(
            local_ped_handle,
            target_ped,
            17
        ) == true

    los_cache[player_id] = {
        ped = target_ped,
        checked_at = now,
        value = value
    }

    return value
end

local function get_player_bounds(points)
    if points == nil
        or points.head == nil
        or points.pelvis == nil then
        return nil
    end

    local foot = points.left_foot or points.right_foot

    if foot == nil then
        return nil
    end

    local bottom_y = foot.y

    if points.left_foot ~= nil and points.right_foot ~= nil then
        bottom_y = math.max(
            points.left_foot.y,
            points.right_foot.y
        )
    end

    local top_y = points.head.y - 5.0
    local height = bottom_y - top_y

    if height < 12.0 then
        return nil
    end

    local width = height * 0.40
    local center_x = points.pelvis.x

    return {
        left = center_x - (width * 0.5),
        right = center_x + (width * 0.5),
        top = top_y,
        bottom = bottom_y,
        height = height,
        width = width
    }
end

local function draw_box_esp(bounds, style)
    if bounds == nil or style == nil then
        return
    end

    local top_left = { x = bounds.left, y = bounds.top }
    local top_right = { x = bounds.right, y = bounds.top }
    local bottom_left = { x = bounds.left, y = bounds.bottom }
    local bottom_right = { x = bounds.right, y = bounds.bottom }

    draw_line(top_left, top_right, style, 0.85)
    draw_line(top_right, bottom_right, style, 0.85)
    draw_line(bottom_right, bottom_left, style, 0.85)
    draw_line(bottom_left, top_left, style, 0.85)
end

local function draw_health_bar(bounds, ped)
    if bounds == nil or ped == nil then
        return
    end

    local raw_health = ENTITY.GET_ENTITY_HEALTH(ped)
    local max_health = ENTITY.GET_ENTITY_MAX_HEALTH(ped)

    local health = 0.0

    if max_health ~= nil and max_health > 100 then
        health = clamp(
            (raw_health - 100) / (max_health - 100),
            0.0,
            1.0
        )
    elseif max_health ~= nil and max_health > 0 then
        health = clamp(raw_health / max_health, 0.0, 1.0)
    end

    local x = bounds.left - 7.0
    local top = bounds.top
    local bottom = bounds.bottom
    local filled_top = bottom - (bounds.height * health)

    ImGui.AddLine(
        x,
        top,
        x,
        bottom,
        15,
        15,
        15,
        225,
        5.0
    )

    local r, g, b = 55, 220, 85

    if health <= 0.30 then
        r, g, b = 240, 65, 65
    elseif health <= 0.60 then
        r, g, b = 245, 185, 55
    end

    ImGui.AddLine(
        x,
        bottom,
        x,
        filled_top,
        r,
        g,
        b,
        245,
        3.0
    )
end

local function draw_armour_bar(bounds, ped)
    if bounds == nil or ped == nil then
        return
    end

    local armour = clamp(PED.GET_PED_ARMOUR(ped) / 100.0, 0.0, 1.0)
    local x = bounds.right + 7.0
    local top = bounds.top
    local bottom = bounds.bottom
    local filled_top = bottom - (bounds.height * armour)

    ImGui.AddLine(
        x,
        top,
        x,
        bottom,
        15,
        15,
        15,
        225,
        5.0
    )

    ImGui.AddLine(
        x,
        bottom,
        x,
        filled_top,
        65,
        145,
        255,
        245,
        3.0
    )
end

local function draw_nearby_counter(count)
    ImGui.AddText(
        18,
        88,
        "Nearby players (150m): " .. tostring(count),
        255,
        255,
        255,
        235
    )
end

local function atan2(y, x)
    if math.atan2 ~= nil then
        return math.atan2(y, x)
    end

    return math.atan(y, x)
end

local function normalize_angle(angle)
    while angle > 180.0 do
        angle = angle - 360.0
    end

    while angle < -180.0 do
        angle = angle + 360.0
    end

    return angle
end

local function draw_offscreen_arrow(
    local_coords,
    target_coords,
    local_heading,
    distance,
    style
)
    if local_coords == nil
        or target_coords == nil
        or style == nil then
        return
    end

    local dx = target_coords.x - local_coords.x
    local dy = target_coords.y - local_coords.y

    local bearing = math.deg(atan2(dx, dy))
    local relative = normalize_angle(bearing - local_heading)
    local angle = math.rad(relative)

    local width, height = ImGui.GetDisplaySize()
    if width == nil or height == nil then
        return
    end

    local center_x = width * 0.5
    local center_y = height * 0.5
    local radius_x = math.max(80.0, (width * 0.5) - 55.0)
    local radius_y = math.max(65.0, (height * 0.5) - 55.0)

    local dir_x = math.sin(angle)
    local dir_y = -math.cos(angle)

    local tip = {
        x = center_x + (dir_x * radius_x),
        y = center_y + (dir_y * radius_y)
    }

    local base_center = {
        x = tip.x - (dir_x * 15.0),
        y = tip.y - (dir_y * 15.0)
    }

    local perp_x = -dir_y
    local perp_y = dir_x

    local left = {
        x = base_center.x + (perp_x * 8.0),
        y = base_center.y + (perp_y * 8.0)
    }

    local right = {
        x = base_center.x - (perp_x * 8.0),
        y = base_center.y - (perp_y * 8.0)
    }

    draw_line(tip, left, style, 1.05)
    draw_line(left, right, style, 1.05)
    draw_line(right, tip, style, 1.05)

    ImGui.AddText(
        base_center.x + 9.0,
        base_center.y - 8.0,
        string.format("%.0fm", distance),
        style.r,
        style.g,
        style.b,
        style.a
    )
end

local function refresh_npc_cache(
    local_ped_handle,
    local_coords,
    now,
    max_distance,
    max_draw,
    include_dead
)
    if PoolMgr == nil
        or type(PoolMgr.GetMaxPedCount) ~= "function"
        or type(PoolMgr.GetPed) ~= "function" then

        return #npc_cache
    end

    local max_peds =
        PoolMgr.GetMaxPedCount() or 0

    if max_peds <= 0 then
        return #npc_cache
    end

    local detected = {}

    for index = 0, max_peds - 1 do
        local ped_handle =
            PoolMgr.GetPed(index)

        if ped_handle ~= nil
            and ped_handle ~= 0
            and ped_handle ~= -1
            and ped_handle ~= local_ped_handle
            and ENTITY.DOES_ENTITY_EXIST(ped_handle)
            and not PED.IS_PED_A_PLAYER(ped_handle)
            and (
                include_dead
                or not ENTITY.IS_ENTITY_DEAD(
                    ped_handle,
                    false
                )
            ) then

            local coords =
                ENTITY.GET_ENTITY_COORDS(
                    ped_handle,
                    true
                )

            if coords ~= nil then
                local distance =
                    distance_between(
                        coords,
                        local_coords
                    )

                if distance <= max_distance then
                    detected[#detected + 1] = {
                        ped = ped_handle,
                        distance = distance
                    }

                    npc_last_seen[ped_handle] = now
                end
            end
        end
    end

    table.sort(
        detected,
        function(a, b)
            return a.distance < b.distance
        end
    )

    local new_cache = {}
    local added = {}

    for _, item in ipairs(detected) do
        if #new_cache >= max_draw then
            break
        end

        new_cache[#new_cache + 1] = item.ped
        added[item.ped] = true
    end

    if #new_cache < max_draw then
        for _, ped_handle in ipairs(npc_cache) do
            if #new_cache >= max_draw then
                break
            end

            local last_seen =
                npc_last_seen[ped_handle] or 0

            if not added[ped_handle]
                and now - last_seen <= NPC_CACHE_GRACE_MS
                and ENTITY.DOES_ENTITY_EXIST(ped_handle)
                and (
                    include_dead
                    or not ENTITY.IS_ENTITY_DEAD(
                        ped_handle,
                        false
                    )
                ) then

                local coords =
                    ENTITY.GET_ENTITY_COORDS(
                        ped_handle,
                        true
                    )

                if coords ~= nil
                    and distance_between(
                        coords,
                        local_coords
                    ) <= max_distance then

                    new_cache[#new_cache + 1] =
                        ped_handle

                    added[ped_handle] = true
                end
            end
        end
    end

    npc_cache = new_cache

    for ped_handle, last_seen in pairs(npc_last_seen) do
        if now - last_seen
            > NPC_CACHE_GRACE_MS * 3 then

            npc_last_seen[ped_handle] = nil
        end
    end

    return #npc_cache
end

local player_info_cache = {}
local PLAYER_INFO_CACHE_MS = 175

local function get_cached_player_info(player_id, ped, now)
    local cached = player_info_cache[player_id]

    if cached ~= nil
        and cached.ped == ped
        and now - cached.updated_at < PLAYER_INFO_CACHE_MS then
        return cached
    end

    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)

    cached = {
        ped = ped,
        name = PLAYER.GET_PLAYER_NAME(player_id)
            or ("Player " .. tostring(player_id)),
        health = math.max(0, ENTITY.GET_ENTITY_HEALTH(ped) - 100),
        armour = PED.GET_PED_ARMOUR(ped),
        interior = INTERIOR.GET_INTERIOR_FROM_ENTITY(ped) or 0,
        state = (vehicle ~= nil and vehicle ~= 0)
            and "vehicle"
            or "on foot",
        updated_at = now
    }

    player_info_cache[player_id] = cached
    return cached
end

local function draw_player_info(
    player_id,
    ped,
    head_screen,
    distance,
    style_override,
    now
)
    if head_screen == nil then
        return
    end

    local info = get_cached_player_info(
        player_id,
        ped,
        now or Time.GetEpocheMs()
    )

    local label = string.format(
        "%s  %.0fm  HP %d  AR %d  %s  INT %d",
        info.name,
        distance,
        info.health,
        info.armour,
        info.state,
        info.interior
    )

    local r, g, b, a = 255, 255, 255, 235

    if style_override ~= nil then
        r = style_override.r
        g = style_override.g
        b = style_override.b
        a = style_override.a
    end

    ImGui.AddText(
        head_screen.x + 8.0,
        head_screen.y - 24.0,
        label,
        r,
        g,
        b,
        a
    )
end

local info_enabled_cache = {}
local info_cache_any = false
local next_info_cache_at = 0
local selected_player_cache = -1
local next_selected_cache_at = 0

local function refresh_info_cache(now)
    if now < next_info_cache_at then
        return info_cache_any
    end

    next_info_cache_at = now + 250
    info_cache_any = false

    for player_id = 0, MAX_PLAYERS - 1 do
        local enabled =
            FeatureMgr.IsFeatureEnabled(
                H.info,
                player_id
            )

        info_enabled_cache[player_id] = enabled

        if enabled then
            info_cache_any = true
        end
    end

    return info_cache_any
end

local function get_selected_player_cached(now)
    if now >= next_selected_cache_at then
        next_selected_cache_at = now + 250

        if type(Utils.GetSelectedPlayer) == "function" then
            selected_player_cache =
                Utils.GetSelectedPlayer() or -1
        else
            selected_player_cache = -1
        end
    end

    return selected_player_cache
end

local render_flags = {
    next_refresh_at = 0,
}

local function refresh_render_flags(now)
    if now < render_flags.next_refresh_at then
        return render_flags
    end

    render_flags.next_refresh_at = now + 100
    render_flags.player_skeletons =
        FeatureMgr.IsFeatureEnabled(H.skeleton)
    render_flags.tracers =
        FeatureMgr.IsFeatureEnabled(H.skeleton_tracers)
    render_flags.box =
        FeatureMgr.IsFeatureEnabled(H.box_esp)
    render_flags.health =
        FeatureMgr.IsFeatureEnabled(H.health_bar_esp)
    render_flags.offscreen =
        FeatureMgr.IsFeatureEnabled(H.offscreen_arrows)
    render_flags.highlight =
        FeatureMgr.IsFeatureEnabled(H.selected_highlight)
    render_flags.visible_only =
        FeatureMgr.IsFeatureEnabled(H.visible_only)
    render_flags.aim_part =
        FeatureMgr.IsFeatureEnabled(H.aim_part_highlight)
    render_flags.armour =
        FeatureMgr.IsFeatureEnabled(H.armour_bar_esp)
    render_flags.facing =
        FeatureMgr.IsFeatureEnabled(H.facing_direction)
    render_flags.movement =
        FeatureMgr.IsFeatureEnabled(H.movement_direction)
    render_flags.vehicle_esp =
        FeatureMgr.IsFeatureEnabled(H.vehicle_esp)
    render_flags.weapon_esp =
        FeatureMgr.IsFeatureEnabled(H.weapon_esp)
    render_flags.show_dead_esp =
        FeatureMgr.IsFeatureEnabled(H.show_dead_esp)
    render_flags.nearby =
        FeatureMgr.IsFeatureEnabled(H.nearby_counter)
    render_flags.self_skeleton =
        FeatureMgr.IsFeatureEnabled(H.self_skeleton)
    render_flags.self_box =
        FeatureMgr.IsFeatureEnabled(H.self_box)
    render_flags.self_health =
        FeatureMgr.IsFeatureEnabled(H.self_health)
    render_flags.self_armour =
        FeatureMgr.IsFeatureEnabled(H.self_armour)
    render_flags.self_facing =
        FeatureMgr.IsFeatureEnabled(H.self_facing)
    render_flags.self_movement =
        FeatureMgr.IsFeatureEnabled(H.self_movement)
    render_flags.self_weapon =
        FeatureMgr.IsFeatureEnabled(H.self_weapon)
    render_flags.self_show_dead =
        FeatureMgr.IsFeatureEnabled(H.self_show_dead)
    render_flags.npc =
        FeatureMgr.IsFeatureEnabled(H.npc_skeletons)
    render_flags.info_all =
        FeatureMgr.IsFeatureEnabled(H.info_all)
    render_flags.info_any =
        refresh_info_cache(now)

    return render_flags
end

local startup_splash_started_at = Time.GetEpocheMs()
local startup_splash_finished = false

local function draw_startup_splash(now)
    if startup_splash_finished then
        return
    end

    local elapsed = now - startup_splash_started_at
    local duration = 3800

    if elapsed >= duration then
        startup_splash_finished = true
        return
    end

    local alpha = 255
    if elapsed < 300 then
        alpha = math.floor(255 * (elapsed / 300))
    elseif elapsed > 3000 then
        alpha = math.floor(255 * ((duration - elapsed) / 800))
    end

    alpha = clamp(alpha, 0, 255)

    local display_width, display_height = ImGui.GetDisplaySize()
    local panel_width = math.min(620.0, display_width - 40.0)
    local panel_height = 238.0
    local panel_x = (display_width - panel_width) * 0.5
    local panel_y = (display_height - panel_height) * 0.5
    local panel_right = panel_x + panel_width
    local panel_bottom = panel_y + panel_height
    local progress = clamp(elapsed / 2600.0, 0.0, 1.0)
    local pulse = 0.5 + (0.5 * math.sin(elapsed * 0.008))

    ImGui.AddRectFilled(
        panel_x - 3.0,
        panel_y - 3.0,
        panel_right + 3.0,
        panel_bottom + 3.0,
        35,
        175,
        255,
        math.floor(alpha * 0.72),
        12.0
    )

    ImGui.AddRectFilled(
        panel_x,
        panel_y,
        panel_right,
        panel_bottom,
        7,
        10,
        18,
        math.floor(alpha * 0.96),
        10.0
    )

    local reveal = (panel_width * 0.5) * progress
    local center_x = panel_x + (panel_width * 0.5)

    ImGui.AddLine(
        center_x - reveal,
        panel_y + 2.0,
        center_x + reveal,
        panel_y + 2.0,
        95,
        215,
        255,
        alpha,
        2.0
    )

    ImGui.AddLine(
        center_x - reveal,
        panel_bottom - 2.0,
        center_x + reveal,
        panel_bottom - 2.0,
        170,
        85,
        255,
        alpha,
        2.0
    )

    local logo_x = panel_x + 92.0
    local logo_y = panel_y + 104.0
    local ring_alpha = math.floor(alpha * (0.58 + (0.30 * pulse)))

    ImGui.AddCircle(
        logo_x,
        logo_y,
        54.0 + (2.0 * pulse),
        65,
        195,
        255,
        ring_alpha,
        48,
        2.0
    )

    ImGui.AddCircle(
        logo_x,
        logo_y,
        43.0,
        165,
        85,
        255,
        math.floor(alpha * 0.88),
        40,
        1.5
    )

    local logo_left = logo_x - 16.0
    local logo_top = logo_y - 25.0
    local logo_right = logo_x + 19.0

    ImGui.AddLine(
        logo_left,
        logo_top,
        logo_left,
        logo_y + 25.0,
        245,
        250,
        255,
        alpha,
        4.0
    )
    ImGui.AddLine(
        logo_left,
        logo_top,
        logo_right,
        logo_top,
        245,
        250,
        255,
        alpha,
        4.0
    )
    ImGui.AddLine(
        logo_left,
        logo_y,
        logo_right - 8.0,
        logo_y,
        95,
        215,
        255,
        alpha,
        4.0
    )
    ImGui.AddLine(
        logo_left,
        logo_y + 25.0,
        logo_right,
        logo_y + 25.0,
        170,
        85,
        255,
        alpha,
        4.0
    )

    local title_x = panel_x + 174.0
    local title_y = panel_y + 61.0

    ImGui.AddText(
        title_x + 2.0,
        title_y + 2.0,
        "E L L O S C R I P T",
        0,
        0,
        0,
        math.floor(alpha * 0.85)
    )
    ImGui.AddText(
        title_x,
        title_y,
        "E L L O S C R I P T",
        235,
        248,
        255,
        alpha
    )
    ImGui.AddText(
        title_x,
        title_y + 28.0,
        "v1.1  //  CHERAX EDITION",
        95,
        215,
        255,
        alpha
    )
    ImGui.AddText(
        title_x,
        title_y + 55.0,
        "ESP  //  PvP  //  Utility",
        170,
        175,
        195,
        math.floor(alpha * 0.90)
    )

    local status = "INITIALIZING CORE"
    if elapsed >= 750 then
        status = "LOADING FEATURES"
    end
    if elapsed >= 1500 then
        status = "SYNCING INTERFACE"
    end
    if elapsed >= 2350 then
        status = "READY"
    end

    local bar_x = panel_x + 36.0
    local bar_y = panel_bottom - 42.0
    local bar_width = panel_width - 72.0

    ImGui.AddRectFilled(
        bar_x,
        bar_y,
        bar_x + bar_width,
        bar_y + 6.0,
        20,
        27,
        40,
        math.floor(alpha * 0.95),
        3.0
    )

    ImGui.AddRectFilled(
        bar_x,
        bar_y,
        bar_x + (bar_width * progress),
        bar_y + 6.0,
        70,
        205,
        255,
        alpha,
        3.0
    )

    ImGui.AddCircleFilled(
        bar_x + (bar_width * progress),
        bar_y + 3.0,
        3.5 + pulse,
        185,
        105,
        255,
        alpha,
        12
    )

    ImGui.AddText(
        bar_x,
        bar_y + 13.0,
        status,
        180,
        195,
        215,
        alpha
    )

    local percent = tostring(math.floor(progress * 100.0)) .. "%"
    ImGui.AddText(
        bar_x + bar_width - (#percent * 7.2),
        bar_y + 13.0,
        percent,
        180,
        195,
        215,
        alpha
    )
end

local function unsigned_hash(value)
    value = value or 0

    if value < 0 then
        return value + 4294967296
    end

    return value
end

local function draw_label_at_screen(screen, lines, style)
    if screen == nil or lines == nil or #lines == 0 then
        return
    end

    local line_height = 15.0
    local longest = 0

    for _, line in ipairs(lines) do
        longest = math.max(longest, #tostring(line))
    end

    local width = (longest * 7.0) + 12.0
    local height = (#lines * line_height) + 8.0
    local x = screen.x - (width * 0.5)
    local y = screen.y - height - 8.0

    ImGui.AddRectFilled(
        x, y, x + width, y + height,
        8, 12, 18, 175,
        3.0
    )

    for index, line in ipairs(lines) do
        ImGui.AddText(
            x + 6.0,
            y + 4.0 + ((index - 1) * line_height),
            tostring(line),
            style.r,
            style.g,
            style.b,
            style.a
        )
    end
end

local function draw_vehicle_esp(vehicle, driver_name, distance, style)
    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return
    end

    local coords = ENTITY.GET_ENTITY_COORDS(vehicle, true)
    local screen = world_to_screen(
        V3.New(coords.x, coords.y, coords.z + 1.15)
    )

    if screen == nil then
        return
    end

    local speed_kph = math.floor((ENTITY.GET_ENTITY_SPEED(vehicle) or 0.0) * 3.6 + 0.5)
    local health = ENTITY.GET_ENTITY_HEALTH(vehicle) or 0
    local model = ENTITY.GET_ENTITY_MODEL(vehicle) or 0

    draw_label_at_screen(
        screen,
        {
            "VEHICLE  " .. tostring(driver_name or "occupied"),
            tostring(speed_kph) .. " km/h  HP " .. tostring(health),
            string.format("MODEL 0x%08X  %.0fm", unsigned_hash(model), distance or 0.0)
        },
        style
    )
end

local weapon_esp_cache = {}
local WEAPON_ESP_CACHE_MS = 250

local WEAPON_NAMES = {
    [Utils.Joaat("WEAPON_KNIFE")] = "Knife",
    [Utils.Joaat("WEAPON_NIGHTSTICK")] = "Nightstick",
    [Utils.Joaat("WEAPON_HAMMER")] = "Hammer",
    [Utils.Joaat("WEAPON_BAT")] = "Baseball Bat",
    [Utils.Joaat("WEAPON_CROWBAR")] = "Crowbar",
    [Utils.Joaat("WEAPON_GOLFCLUB")] = "Golf Club",
    [Utils.Joaat("WEAPON_BOTTLE")] = "Bottle",
    [Utils.Joaat("WEAPON_DAGGER")] = "Dagger",
    [Utils.Joaat("WEAPON_HATCHET")] = "Hatchet",
    [Utils.Joaat("WEAPON_MACHETE")] = "Machete",
    [Utils.Joaat("WEAPON_SWITCHBLADE")] = "Switchblade",
    [Utils.Joaat("WEAPON_PISTOL")] = "Pistol",
    [Utils.Joaat("WEAPON_PISTOL_MK2")] = "Pistol Mk II",
    [Utils.Joaat("WEAPON_COMBATPISTOL")] = "Combat Pistol",
    [Utils.Joaat("WEAPON_APPISTOL")] = "AP Pistol",
    [Utils.Joaat("WEAPON_PISTOL50")] = "Pistol .50",
    [Utils.Joaat("WEAPON_SNSPISTOL")] = "SNS Pistol",
    [Utils.Joaat("WEAPON_HEAVYPISTOL")] = "Heavy Pistol",
    [Utils.Joaat("WEAPON_VINTAGEPISTOL")] = "Vintage Pistol",
    [Utils.Joaat("WEAPON_REVOLVER")] = "Heavy Revolver",
    [Utils.Joaat("WEAPON_MICROSMG")] = "Micro SMG",
    [Utils.Joaat("WEAPON_SMG")] = "SMG",
    [Utils.Joaat("WEAPON_SMG_MK2")] = "SMG Mk II",
    [Utils.Joaat("WEAPON_ASSAULTSMG")] = "Assault SMG",
    [Utils.Joaat("WEAPON_COMBATPDW")] = "Combat PDW",
    [Utils.Joaat("WEAPON_MACHINEPISTOL")] = "Machine Pistol",
    [Utils.Joaat("WEAPON_MINISMG")] = "Mini SMG",
    [Utils.Joaat("WEAPON_PUMPSHOTGUN")] = "Pump Shotgun",
    [Utils.Joaat("WEAPON_PUMPSHOTGUN_MK2")] = "Pump Shotgun Mk II",
    [Utils.Joaat("WEAPON_SAWNOFFSHOTGUN")] = "Sawed-Off Shotgun",
    [Utils.Joaat("WEAPON_ASSAULTSHOTGUN")] = "Assault Shotgun",
    [Utils.Joaat("WEAPON_BULLPUPSHOTGUN")] = "Bullpup Shotgun",
    [Utils.Joaat("WEAPON_HEAVYSHOTGUN")] = "Heavy Shotgun",
    [Utils.Joaat("WEAPON_ASSAULTRIFLE")] = "Assault Rifle",
    [Utils.Joaat("WEAPON_ASSAULTRIFLE_MK2")] = "Assault Rifle Mk II",
    [Utils.Joaat("WEAPON_CARBINERIFLE")] = "Carbine Rifle",
    [Utils.Joaat("WEAPON_CARBINERIFLE_MK2")] = "Carbine Rifle Mk II",
    [Utils.Joaat("WEAPON_ADVANCEDRIFLE")] = "Advanced Rifle",
    [Utils.Joaat("WEAPON_SPECIALCARBINE")] = "Special Carbine",
    [Utils.Joaat("WEAPON_BULLPUPRIFLE")] = "Bullpup Rifle",
    [Utils.Joaat("WEAPON_COMPACTRIFLE")] = "Compact Rifle",
    [Utils.Joaat("WEAPON_MG")] = "MG",
    [Utils.Joaat("WEAPON_COMBATMG")] = "Combat MG",
    [Utils.Joaat("WEAPON_GUSENBERG")] = "Gusenberg Sweeper",
    [Utils.Joaat("WEAPON_SNIPERRIFLE")] = "Sniper Rifle",
    [Utils.Joaat("WEAPON_HEAVYSNIPER")] = "Heavy Sniper",
    [Utils.Joaat("WEAPON_HEAVYSNIPER_MK2")] = "Heavy Sniper Mk II",
    [Utils.Joaat("WEAPON_MARKSMANRIFLE")] = "Marksman Rifle",
    [Utils.Joaat("WEAPON_RPG")] = "RPG",
    [Utils.Joaat("WEAPON_GRENADELAUNCHER")] = "Grenade Launcher",
    [Utils.Joaat("WEAPON_MINIGUN")] = "Minigun",
    [Utils.Joaat("WEAPON_RAILGUN")] = "Railgun",
    [Utils.Joaat("WEAPON_HOMINGLAUNCHER")] = "Homing Launcher",
    [Utils.Joaat("WEAPON_GRENADE")] = "Grenade",
    [Utils.Joaat("WEAPON_STICKYBOMB")] = "Sticky Bomb",
    [Utils.Joaat("WEAPON_MOLOTOV")] = "Molotov",
    [Utils.Joaat("WEAPON_PROXMINE")] = "Proximity Mine",
    [Utils.Joaat("WEAPON_PIPEBOMB")] = "Pipe Bomb"
}

local function weapon_name_from_hash(weapon_hash)
    return WEAPON_NAMES[weapon_hash]
        or string.format("Weapon 0x%08X", unsigned_hash(weapon_hash))
end

local function compact_weapon_name(name)
    local replacements = {
        ["Assault Rifle"] = "AR",
        ["Carbine Rifle"] = "Carbine",
        ["Special Carbine"] = "Special Carbine",
        ["Combat Pistol"] = "Combat Pistol",
        ["Heavy Sniper Mk II"] = "Heavy Sniper Mk2",
        ["Pump Shotgun Mk II"] = "Pump Shotgun Mk2"
    }
    return replacements[name] or name
end

local function draw_weapon_esp(ped, points, style, now)
    if ped == nil or ped == 0 or points == nil then
        return
    end

    now = now or Time.GetEpocheMs()
    local cached = weapon_esp_cache[ped]

    if cached == nil or now - cached.updated_at >= WEAPON_ESP_CACHE_MS then
        local weapon_hash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
        local label = nil

        if weapon_hash ~= nil
            and weapon_hash ~= 0
            and weapon_hash ~= Utils.Joaat("WEAPON_UNARMED") then

            label = compact_weapon_name(
                weapon_name_from_hash(weapon_hash)
            )
        end

        cached = {
            label = label,
            updated_at = now
        }
        weapon_esp_cache[ped] = cached
    end

    if cached.label == nil then
        return
    end

    local anchor = points.right_shoulder or points.right_hand or points.head

    if anchor == nil then
        return
    end

    ImGui.AddText(
        anchor.x + 5.0,
        anchor.y - 14.0,
        cached.label,
        style.r,
        style.g,
        style.b,
        math.min(style.a, 220)
    )
end

local function draw_dead_marker(points)
    if points == nil or points.head == nil then
        return
    end

    ImGui.AddText(
        points.head.x - 17.0,
        points.head.y - 42.0,
        "DEAD",
        255,
        75,
        75,
        235
    )
end

H._self_esp = {}

function H._self_esp.get_style()
    local r, g, b, a =
        FeatureMgr.GetFeatureColor(H.self_color)
    local thickness =
        FeatureMgr.GetFeatureFloat(H.self_thickness)
    local head_size =
        FeatureMgr.GetFeatureFloat(H.self_head_size)

    if r == nil then r = 95 end
    if g == nil then g = 190 end
    if b == nil then b = 255 end
    if a == nil then a = 235 end
    if thickness == nil or thickness <= 0.0 then
        thickness = 2.0
    end
    if head_size == nil or head_size <= 0.0 then
        head_size = 0.9
    end

    return {
        r = r,
        g = g,
        b = b,
        a = a,
        thickness = thickness,
        head_size = head_size,
        distance_scale = 1.0,
    }
end

function H._self_esp.render(ped, coords, now, flags)
    if ped == nil or ped == 0 or flags == nil then
        return
    end

    local dead = ENTITY.IS_ENTITY_DEAD(ped, false)

    if dead and not flags.self_show_dead then
        return
    end

    local points = collect_player_points(ped, 0.0, now)

    if points == nil then
        return
    end

    local style = H._self_esp.get_style()

    if dead and flags.self_show_dead then
        draw_dead_marker(points)
    end

    if flags.self_skeleton then
        draw_simple_skeleton(
            points,
            0.0,
            nil,
            style,
            false,
            nil
        )
    end

    local bounds = nil

    if flags.self_box
        or flags.self_health
        or flags.self_armour then
        bounds = get_player_bounds(points)
    end

    if flags.self_box then
        draw_box_esp(bounds, style)
    end

    if flags.self_health then
        draw_health_bar(bounds, ped)
    end

    if flags.self_armour then
        draw_armour_bar(bounds, ped)
    end

    if flags.self_facing then
        draw_facing_direction_indicator(
            ped,
            coords,
            points,
            style
        )
    end

    if flags.self_movement then
        draw_movement_direction_indicator(
            ped,
            coords,
            points,
            style
        )
    end

    if flags.self_weapon then
        draw_weapon_esp(
            ped,
            points,
            style,
            now
        )
    end
end

H._bullet_reflector = {
    active = false,
    next_scan_at = 0,
    next_fire_at = {},
    queued = {},
    last_ammo = {},
    last_weapon = {},
    was_shooting = {},
    last_impact = {},
    impact_ptr = nil,
    last_error = nil,
    scan_interval_ms = 20,
    repeat_interval_ms = 105,
    max_distance = 900.0,
    impact_radius = 4.5,
    reflected_weapon = "weapon_heavysniper_mk2",
}

function H._bullet_reflector.release_impact_ptr()
    if H._bullet_reflector.impact_ptr ~= nil
        and Memory ~= nil
        and type(Memory.Free) == "function" then

        Memory.Free(H._bullet_reflector.impact_ptr)
    end

    H._bullet_reflector.impact_ptr = nil
end

function H._bullet_reflector.reset()
    H._bullet_reflector.active = false
    H._bullet_reflector.next_scan_at = 0
    H._bullet_reflector.next_fire_at = {}
    H._bullet_reflector.queued = {}
    H._bullet_reflector.last_ammo = {}
    H._bullet_reflector.last_weapon = {}
    H._bullet_reflector.was_shooting = {}
    H._bullet_reflector.last_impact = {}
    H._bullet_reflector.last_error = nil
    H._bullet_reflector.release_impact_ptr()
end

function H._bullet_reflector.raw_is_shooting(ped)
    return InvokeBool(0x34616828CD07F1A1, ped)
end

function H._bullet_reflector.raw_get_weapon(ped)
    return InvokeInt(0x0A6DB4965674D243, ped)
end

function H._bullet_reflector.raw_get_ammo(ped, weapon_hash)
    return InvokeInt(0x015A522136D7F951, ped, weapon_hash)
end

function H._bullet_reflector.raw_get_damage_type(weapon_hash)
    return InvokeInt(0x3BE0BB12D25FB305, weapon_hash)
end

function H._bullet_reflector.is_aimed_at_victim(player_id, attacker, victim)
    if InvokeBool(0x7912F7FC4F6264B6, player_id, victim)
        or InvokeBool(0x3C06B5C839B38F7B, player_id, victim) then
        return true
    end

    if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(attacker, victim, 17) then
        return false
    end

    local target = PED.GET_PED_BONE_COORDS(victim, 24818, 0.0, 0.0, 0.0)
    local weapon_entity = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(attacker)
    local origin
    local forward
    local threshold

    if weapon_entity ~= nil
        and weapon_entity ~= 0
        and ENTITY.DOES_ENTITY_EXIST(weapon_entity) then
        origin = ENTITY.GET_ENTITY_COORDS(weapon_entity, true)
        forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(weapon_entity)
        threshold = 0.985
    else
        origin = PED.GET_PED_BONE_COORDS(attacker, 31086, 0.0, 0.0, 0.0)
        forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(attacker)
        threshold = 0.955
    end

    local dx = target.x - origin.x
    local dy = target.y - origin.y
    local dz = target.z - origin.z
    local distance_sq = dx * dx + dy * dy + dz * dz

    if distance_sq <= 0.0001 then
        return false
    end

    local distance = math.sqrt(distance_sq)
    if distance > H._bullet_reflector.max_distance then
        return false
    end

    local inv = 1.0 / distance
    local dot =
        forward.x * dx * inv
        + forward.y * dy * inv
        + forward.z * dz * inv

    return dot >= threshold
end

function H._bullet_reflector.read_impact(attacker)
    if Memory == nil
        or type(Memory.Alloc) ~= "function"
        or type(Memory.ReadFloat) ~= "function" then
        return nil
    end

    if H._bullet_reflector.impact_ptr == nil then
        H._bullet_reflector.impact_ptr = Memory.Alloc(12)
    end

    local ptr = H._bullet_reflector.impact_ptr
    if ptr == nil or ptr == 0 then
        return nil
    end

    if not InvokeBool(0x6C4D0409BA1A2BC2, attacker, ptr) then
        return nil
    end

    return {
        x = Memory.ReadFloat(ptr),
        y = Memory.ReadFloat(ptr + 4),
        z = Memory.ReadFloat(ptr + 8),
    }
end

function H._bullet_reflector.has_fresh_impact_near_victim(
    player_id,
    attacker,
    victim
)
    local impact = H._bullet_reflector.read_impact(attacker)

    if impact == nil then
        return false
    end

    local previous = H._bullet_reflector.last_impact[player_id]
    H._bullet_reflector.last_impact[player_id] = impact

    if previous == nil then
        return false
    end

    local change_x = impact.x - previous.x
    local change_y = impact.y - previous.y
    local change_z = impact.z - previous.z
    local changed_sq =
        change_x * change_x
        + change_y * change_y
        + change_z * change_z

    if changed_sq < 0.0025 then
        return false
    end

    local target = PED.GET_PED_BONE_COORDS(victim, 24818, 0.0, 0.0, 0.0)
    local dx = impact.x - target.x
    local dy = impact.y - target.y
    local dz = impact.z - target.z
    local radius = H._bullet_reflector.impact_radius

    return dx * dx + dy * dy + dz * dz <= radius * radius
end

function H._bullet_reflector.get_damage(weapon_hash)
    local amount = WEAPON.GET_WEAPON_DAMAGE(weapon_hash, 0)

    if amount == nil or amount <= 0.0 then
        amount = 45.0
    end

    return math.max(10.0, math.min(140.0, amount))
end

function H._bullet_reflector.queue_damage(player_id, amount, now)
    if H._bullet_reflector.queued[player_id]
        or now < (H._bullet_reflector.next_fire_at[player_id] or 0) then
        return
    end

    H._bullet_reflector.queued[player_id] = true
    H._bullet_reflector.next_fire_at[player_id] =
        now + H._bullet_reflector.repeat_interval_ms

    Script.QueueJob(function()
        if FeatureMgr.IsFeatureEnabled(H.bullet_reflector)
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

            local sent, reason = remote_damage.send(
                player_id,
                H._bullet_reflector.reflected_weapon,
                amount
            )

            if not sent and reason ~= H._bullet_reflector.last_error then
                H._bullet_reflector.last_error = reason
                GUI.AddToast(
                    "Bullet Reflector",
                    tostring(reason or "Damage delivery failed."),
                    5000
                )
            elseif sent then
                H._bullet_reflector.last_error = nil
            end
        end

        H._bullet_reflector.queued[player_id] = nil
    end)
end

function H._bullet_reflector.tick(now)
    if not FeatureMgr.IsFeatureEnabled(H.bullet_reflector) then
        if H._bullet_reflector.active then
            H._bullet_reflector.reset()
        end
        return
    end

    local victim = local_ped()
    if victim == nil
        or victim == 0
        or not ENTITY.DOES_ENTITY_EXIST(victim)
        or ENTITY.IS_ENTITY_DEAD(victim, false) then
        return
    end

    if not H._bullet_reflector.active then
        H._bullet_reflector.active = true
        H._bullet_reflector.next_scan_at = now
    end

    if now < H._bullet_reflector.next_scan_at then
        return
    end
    H._bullet_reflector.next_scan_at =
        now + H._bullet_reflector.scan_interval_ms

    local local_player = PLAYER.PLAYER_ID()

    for player_id = 0, MAX_PLAYERS - 1 do
        if player_id ~= local_player
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

            local attacker = player_ped(player_id)
            local valid_attacker = attacker ~= nil
                and attacker ~= 0
                and ENTITY.DOES_ENTITY_EXIST(attacker)
                and not ENTITY.IS_ENTITY_DEAD(attacker, false)

            if valid_attacker then
                local weapon_hash =
                    H._bullet_reflector.raw_get_weapon(attacker)
                local ammo =
                    H._bullet_reflector.raw_get_ammo(attacker, weapon_hash)
                local previous_ammo =
                    H._bullet_reflector.last_ammo[player_id]
                local previous_weapon =
                    H._bullet_reflector.last_weapon[player_id]

                local shooting =
                    H._bullet_reflector.raw_is_shooting(attacker)
                local shooting_trigger = shooting
                    and (
                        not H._bullet_reflector.was_shooting[player_id]
                        or now >= (
                            H._bullet_reflector.next_fire_at[player_id] or 0
                        )
                    )

                local ammo_trigger = previous_weapon == weapon_hash
                    and previous_ammo ~= nil
                    and ammo ~= nil
                    and ammo >= 0
                    and ammo < previous_ammo

                local impact_trigger =
                    H._bullet_reflector.has_fresh_impact_near_victim(
                        player_id,
                        attacker,
                        victim
                    )

                local damage_type =
                    H._bullet_reflector.raw_get_damage_type(weapon_hash)
                local bullet_weapon = damage_type == 3 or damage_type == 4
                local aimed = impact_trigger
                    or H._bullet_reflector.is_aimed_at_victim(
                        player_id,
                        attacker,
                        victim
                    )

                if bullet_weapon
                    and aimed
                    and (shooting_trigger or ammo_trigger or impact_trigger) then
                    H._bullet_reflector.queue_damage(
                        player_id,
                        H._bullet_reflector.get_damage(weapon_hash),
                        now
                    )
                end

                H._bullet_reflector.last_ammo[player_id] = ammo
                H._bullet_reflector.last_weapon[player_id] = weapon_hash
                H._bullet_reflector.was_shooting[player_id] = shooting
            else
                H._bullet_reflector.last_ammo[player_id] = nil
                H._bullet_reflector.last_weapon[player_id] = nil
                H._bullet_reflector.was_shooting[player_id] = nil
                H._bullet_reflector.last_impact[player_id] = nil
            end
        else
            H._bullet_reflector.last_ammo[player_id] = nil
            H._bullet_reflector.last_weapon[player_id] = nil
            H._bullet_reflector.was_shooting[player_id] = nil
            H._bullet_reflector.last_impact[player_id] = nil
            H._bullet_reflector.next_fire_at[player_id] = nil
            H._bullet_reflector.queued[player_id] = nil
        end
    end
end

function H._bullet_reflector.shutdown()
    H._bullet_reflector.reset()
end

H._pvp_ghost = {
    effective = false,
    threat_until = 0,
    next_scan_at = 0,
    next_apply_at = 0,
    last_ped = 0,
    last_vehicle = 0,
    scan_interval_ms = 50,
    apply_interval_ms = 200,
    release_hold_ms = 1250,
}

function H._pvp_ghost.is_threatening(player_id, attacker, victim)
    if InvokeBool(0x7912F7FC4F6264B6, player_id, victim)
        or InvokeBool(0x3C06B5C839B38F7B, player_id, victim) then
        return true
    end

    if H._bullet_reflector.raw_is_shooting(attacker) then
        return H._bullet_reflector.is_aimed_at_victim(
            player_id,
            attacker,
            victim
        )
    end

    return false
end

function H._pvp_ghost.scan_for_threat(victim)
    local local_player = PLAYER.PLAYER_ID()

    for player_id = 0, MAX_PLAYERS - 1 do
        if player_id ~= local_player
            and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

            local attacker = player_ped(player_id)

            if attacker ~= nil
                and attacker ~= 0
                and ENTITY.DOES_ENTITY_EXIST(attacker)
                and not ENTITY.IS_ENTITY_DEAD(attacker, false)
                and H._pvp_ghost.is_threatening(
                    player_id,
                    attacker,
                    victim
                ) then
                return true
            end
        end
    end

    return false
end

function H._pvp_ghost.restore_vehicle(vehicle)
    if vehicle == nil
        or vehicle == 0
        or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return
    end

    NETWORK.SET_NETWORK_VEHICLE_AS_GHOST(vehicle, false)
    ENTITY.SET_ENTITY_INVINCIBLE(
        vehicle,
        utility_state.vehicle_god_mode
    )
end

function H._pvp_ghost.apply(active, now, force)
    local ped = local_ped()
    local vehicle = current_local_vehicle()
    local changed = active ~= H._pvp_ghost.effective
        or ped ~= H._pvp_ghost.last_ped
        or vehicle ~= H._pvp_ghost.last_vehicle

    if not force
        and not changed
        and now < H._pvp_ghost.next_apply_at then
        return
    end

    H._pvp_ghost.next_apply_at =
        now + H._pvp_ghost.apply_interval_ms

    if H._pvp_ghost.last_vehicle ~= 0
        and H._pvp_ghost.last_vehicle ~= vehicle then
        H._pvp_ghost.restore_vehicle(
            H._pvp_ghost.last_vehicle
        )
    end

    NETWORK.SET_LOCAL_PLAYER_AS_GHOST(active, false)

    PLAYER.SET_PLAYER_INVINCIBLE(
        PLAYER.PLAYER_ID(),
        active or utility_state.god_mode
    )

    if ped ~= nil
        and ped ~= 0
        and ENTITY.DOES_ENTITY_EXIST(ped) then
        ENTITY.SET_ENTITY_INVINCIBLE(
            ped,
            active or utility_state.god_mode
        )
    end

    if vehicle ~= nil
        and vehicle ~= 0
        and ENTITY.DOES_ENTITY_EXIST(vehicle) then
        NETWORK.SET_NETWORK_VEHICLE_AS_GHOST(
            vehicle,
            active
        )
        ENTITY.SET_ENTITY_INVINCIBLE(
            vehicle,
            active or utility_state.vehicle_god_mode
        )
    end

    H._pvp_ghost.effective = active
    H._pvp_ghost.last_ped = ped or 0
    H._pvp_ghost.last_vehicle = vehicle or 0
end

function H._pvp_ghost.tick(now, force)
    local manual = FeatureMgr.IsFeatureEnabled(H.pvp_ghost)
    local automatic = FeatureMgr.IsFeatureEnabled(H.auto_pvp_ghost)
    local ped = local_ped()

    if automatic
        and ped ~= nil
        and ped ~= 0
        and ENTITY.DOES_ENTITY_EXIST(ped)
        and not ENTITY.IS_ENTITY_DEAD(ped, false)
        and now >= H._pvp_ghost.next_scan_at then

        H._pvp_ghost.next_scan_at =
            now + H._pvp_ghost.scan_interval_ms

        if H._pvp_ghost.scan_for_threat(ped) then
            H._pvp_ghost.threat_until =
                now + H._pvp_ghost.release_hold_ms
        end
    elseif not automatic then
        H._pvp_ghost.threat_until = 0
    end

    local auto_active = automatic
        and now <= H._pvp_ghost.threat_until

    H._pvp_ghost.apply(
        manual or auto_active,
        now,
        force == true
    )
end

function H._pvp_ghost.refresh()
    H._pvp_ghost.tick(Time.GetEpocheMs(), true)
end

function H._pvp_ghost.shutdown()
    H._pvp_ghost.threat_until = 0
    H._pvp_ghost.apply(false, Time.GetEpocheMs(), true)
    H._pvp_ghost.effective = false
    H._pvp_ghost.last_ped = 0
    H._pvp_ghost.last_vehicle = 0
end

local function on_present()
    local now = Time.GetEpocheMs()
    draw_startup_splash(now)
    H._pvp_ghost.tick(now)
    H._bullet_reflector.tick(now)

    if utility_state.super_jump then
        PLAYER.SET_SUPER_JUMP_THIS_FRAME(
            PLAYER.PLAYER_ID()
        )
    end

    local flags = refresh_render_flags(now)

    local player_skeletons_enabled =
        flags.player_skeletons
    local tracers_enabled =
        flags.tracers
    local box_esp_enabled =
        flags.box
    local health_bar_enabled =
        flags.health
    local offscreen_enabled =
        flags.offscreen
    local highlight_selected =
        flags.highlight
    local visible_only =
        flags.visible_only
    local aim_part_highlight_enabled =
        flags.aim_part
    local armour_bar_enabled =
        flags.armour
    local facing_direction_enabled =
        flags.facing
    local movement_direction_enabled =
        flags.movement
    local vehicle_esp_enabled =
        flags.vehicle_esp
    local weapon_esp_enabled =
        flags.weapon_esp
    local show_dead_esp =
        flags.show_dead_esp
    local nearby_counter_enabled =
        flags.nearby
    local npc_skeletons_enabled =
        flags.npc
    local self_render_enabled =
        flags.self_skeleton
        or flags.self_box
        or flags.self_health
        or flags.self_armour
        or flags.self_facing
        or flags.self_movement
        or flags.self_weapon
        or flags.self_show_dead
    local info_all_enabled =
        flags.info_all

    local player_info_enabled =
        info_all_enabled or flags.info_any

    local player_render_enabled =
        player_skeletons_enabled
        or box_esp_enabled
        or health_bar_enabled
        or offscreen_enabled
        or armour_bar_enabled
        or facing_direction_enabled
        or movement_direction_enabled
        or vehicle_esp_enabled
        or weapon_esp_enabled
        or show_dead_esp
        or nearby_counter_enabled
        or player_info_enabled

    if not player_render_enabled
        and not npc_skeletons_enabled
        and not self_render_enabled then
        return
    end

    local local_player = PLAYER.PLAYER_ID()
    local me = local_ped()

    if me == nil or me == 0 or not ENTITY.DOES_ENTITY_EXIST(me) then
        return
    end

    local local_coords = ENTITY.GET_ENTITY_COORDS(me, true)

    if self_render_enabled then
        H._self_esp.render(
            me,
            local_coords,
            now,
            flags
        )
    end

    local local_heading =
        offscreen_enabled and ENTITY.GET_ENTITY_HEADING(me) or 0.0
    local local_pelvis = nil

    if player_skeletons_enabled and tracers_enabled then
        local_pelvis = bone_screen(me, 11816)
    end

    local aim_active =
        player_skeletons_enabled
        and aim_part_highlight_enabled
        and PLAYER.IS_PLAYER_FREE_AIMING(local_player)

    local crosshair_x = nil
    local crosshair_y = nil

    if aim_active then
        local display_width, display_height = ImGui.GetDisplaySize()
        crosshair_x = display_width * 0.5
        crosshair_y = display_height * 0.5
    end

    local nearby_count = 0
    local seen_vehicles = {}
    local selected_player_id = -1

    if highlight_selected then
        selected_player_id =
            get_selected_player_cached(now)
    end

    if player_render_enabled then
        for player_id = 0, MAX_PLAYERS - 1 do
            if player_id ~= local_player
                and NETWORK.NETWORK_IS_PLAYER_ACTIVE(player_id) then

                local ped = player_ped(player_id)

                local is_dead =
                    ped ~= 0
                    and ENTITY.IS_ENTITY_DEAD(ped, false)

                if ped ~= 0
                    and (show_dead_esp or not is_dead) then

                    local coords = ENTITY.GET_ENTITY_COORDS(
                        ped,
                        true
                    )
                    local distance = distance_between(
                        coords,
                        local_coords
                    )

                    if nearby_counter_enabled and distance <= 150.0 then
                        nearby_count = nearby_count + 1
                    end

                    local can_render = true

                    if visible_only then
                        can_render = player_has_clear_los(
                            me,
                            ped,
                            player_id
                        )
                    end

                    if can_render then
                        local style = get_skeleton_style(distance)
                        local is_selected =
                            highlight_selected
                            and player_id == selected_player_id

                        if is_selected then
                            style = highlighted_style(style)
                        end

                        local body_screen = world_to_screen(coords)

                        if offscreen_enabled and body_screen == nil then
                            draw_offscreen_arrow(
                                local_coords,
                                coords,
                                local_heading,
                                distance,
                                style
                            )
                        else
                            local player_info_toggled =
                                info_enabled_cache[player_id]
                                    == true

                            local needs_points =
                                player_skeletons_enabled
                                or box_esp_enabled
                                or health_bar_enabled
                                or armour_bar_enabled
                                or facing_direction_enabled
                                or movement_direction_enabled
                                or weapon_esp_enabled
                                or aim_active

                            local points =
                                needs_points
                                and collect_player_points(ped, distance, now)
                                or nil

                            local aimed_part = nil

                            if aim_active then
                                aimed_part = find_aimed_skeleton_part(
                                    points,
                                    style,
                                    distance,
                                    crosshair_x,
                                    crosshair_y
                                )
                            end

                            if is_dead and show_dead_esp then
                                draw_dead_marker(points)
                            end

                            if player_skeletons_enabled then
                                draw_simple_skeleton(
                                    points,
                                    distance,
                                    local_pelvis,
                                    style,
                                    tracers_enabled,
                                    aimed_part
                                )
                            end

                            local bounds = nil

                            if box_esp_enabled
                                or health_bar_enabled
                                or armour_bar_enabled then
                                bounds = get_player_bounds(points)
                            end

                            if box_esp_enabled then
                                draw_box_esp(bounds, style)
                            end

                            if health_bar_enabled then
                                draw_health_bar(bounds, ped)
                            end

                            if armour_bar_enabled then
                                draw_armour_bar(bounds, ped)
                            end

                            if facing_direction_enabled then
                                draw_facing_direction_indicator(
                                    ped,
                                    coords,
                                    points,
                                    style
                                )
                            end

                            if movement_direction_enabled then
                                draw_movement_direction_indicator(
                                    ped,
                                    coords,
                                    points,
                                    style
                                )
                            end

                            if weapon_esp_enabled then
                                draw_weapon_esp(
                                    ped,
                                    points,
                                    style,
                                    now
                                )
                            end

                            if vehicle_esp_enabled then
                                local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)

                                if vehicle ~= nil
                                    and vehicle ~= 0
                                    and not seen_vehicles[vehicle] then

                                    seen_vehicles[vehicle] = true

                                    draw_vehicle_esp(
                                        vehicle,
                                        PLAYER.GET_PLAYER_NAME(player_id),
                                        distance,
                                        style
                                    )
                                end
                            end

                            if info_all_enabled or player_info_toggled then
                                local live_head =
                                    points ~= nil
                                    and points.head
                                    or bone_screen(ped, 31086)

                                draw_player_info(
                                    player_id,
                                    ped,
                                    live_head,
                                    distance,
                                    is_selected and style or nil,
                                    now
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    if nearby_counter_enabled then
        draw_nearby_counter(nearby_count)
    end

    if npc_skeletons_enabled then
        local npc_range,
            npc_max_count,
            npc_refresh_interval =
                get_npc_options()

        if now >= next_npc_refresh_at
            or #npc_cache == 0 then

            next_npc_refresh_at =
                now + npc_refresh_interval

            local count =
                refresh_npc_cache(
                    me,
                    local_coords,
                    now,
                    npc_range,
                    npc_max_count,
                    show_dead_esp
                )

            if not npc_scan_reported then
                npc_scan_reported = true

                GUI.AddToast(
                    "elloscript NPC scan",
                    "Tracking "
                        .. tostring(count)
                        .. " NPCs within "
                        .. tostring(
                            math.floor(npc_range)
                        )
                        .. "m.",
                    3500
                )
            end
        end

        local npc_tracers_enabled =
            FeatureMgr.IsFeatureEnabled(
                H.npc_tracers
            )

        local npc_tracer_origin = nil

        if npc_tracers_enabled then
            npc_tracer_origin =
                bone_screen(me, 11816)
        end

        for _, npc in ipairs(npc_cache) do
            local npc_is_dead =
                npc ~= nil
                and npc ~= 0
                and ENTITY.DOES_ENTITY_EXIST(npc)
                and ENTITY.IS_ENTITY_DEAD(npc, false)

            if npc ~= nil
                and npc ~= 0
                and ENTITY.DOES_ENTITY_EXIST(npc)
                and (show_dead_esp or not npc_is_dead) then

                local coords =
                    ENTITY.GET_ENTITY_COORDS(
                        npc,
                        true
                    )

                if coords ~= nil then
                    local distance =
                        distance_between(
                            coords,
                            local_coords
                        )

                    if distance <= npc_range then
                        local style =
                            get_npc_style(distance)

                        local npc_points =
                            collect_player_points(npc, distance, now)

                        if npc_is_dead and show_dead_esp then
                            draw_dead_marker(npc_points)
                        end

                        draw_simple_skeleton(
                            npc_points,
                            distance,
                            npc_tracer_origin,
                            style,
                            npc_tracers_enabled,
                            nil
                        )
                    end
                end
            end
        end
    else
        npc_cache = {}
        npc_last_seen = {}
        next_npc_refresh_at = 0
        npc_scan_reported = false
    end
end

FeatureMgr.AddFeature(
    H.skeleton,
    "Skeleton ESP - All Players",
    eFeatureType.Toggle,
    "Draws an adaptive high-detail rig on streamed players. Close targets include segmented spine, hips, elbows, knees, feet, toes and all five fingers with three tracked joints per finger at ultra-close range; distance LOD prevents long-range lag."
):SetSaveable(true)

local skeleton_color_feature = FeatureMgr.AddFeature(
    H.skeleton_color,
    "Skeleton Color",
    eFeatureType.InputColor4,
    "Changes the color and opacity of every skeleton."
)
skeleton_color_feature:SetColor(0, 255, 170, 235)
skeleton_color_feature:SetSaveable(true)

local skeleton_thickness_feature = FeatureMgr.AddFeature(
    H.skeleton_thickness,
    "Line Thickness",
    eFeatureType.SliderFloat,
    "Changes skeleton line thickness."
)
skeleton_thickness_feature:SetLimitValues(1.0, 5.0)
skeleton_thickness_feature:SetDefaultValue(2.0)
skeleton_thickness_feature:SetStepSize(0.1)
skeleton_thickness_feature:SetSaveable(true)
skeleton_thickness_feature:Reset()

local skeleton_head_size_feature = FeatureMgr.AddFeature(
    H.skeleton_head_size,
    "Head Size",
    eFeatureType.SliderFloat,
    "Changes the head-circle scale."
)
skeleton_head_size_feature:SetLimitValues(0.5, 1.8)
skeleton_head_size_feature:SetDefaultValue(0.9)
skeleton_head_size_feature:SetStepSize(0.1)
skeleton_head_size_feature:SetSaveable(true)
skeleton_head_size_feature:Reset()

FeatureMgr.AddFeature(
    H.skeleton_tracers,
    "Tracer Lines To You",
    eFeatureType.Toggle,
    "Draws a line from each visible skeleton back to your own character."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.box_esp,
    "2D Box ESP",
    eFeatureType.Toggle,
    "Draws a simple two-dimensional box around every streamed remote player."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.health_bar_esp,
    "Health Bar ESP",
    eFeatureType.Toggle,
    "Draws a vertical health bar beside every visible player box."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.offscreen_arrows,
    "Off-Screen Player Arrows",
    eFeatureType.Toggle,
    "Shows directional arrows and distance for players outside the current screen."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.selected_highlight,
    "Highlight Selected Player",
    eFeatureType.Toggle,
    "Highlights the currently selected player in gold across skeletons, boxes, arrows and information."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.visible_only,
    "Visible Players Only",
    eFeatureType.Toggle,
    "Hides ESP for players blocked by world geometry. This disables through-wall drawing while enabled."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.aim_part_highlight,
    "Aim-Reactive Skeleton Parts",
    eFeatureType.Toggle,
    "While you are aiming, the skeleton segment under the centre crosshair uses the exact inverse RGB color. It returns to normal immediately when your aim moves away."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.armour_bar_esp,
    "Armour Bar ESP",
    eFeatureType.Toggle,
    "Draws a blue armour bar on the right side of each player."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.facing_direction,
    "Facing-Direction Indicator",
    eFeatureType.Toggle,
    "Draws a short arrow from each player's head showing the direction they are facing."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.movement_direction,
    "Movement-Direction Indicator",
    eFeatureType.Toggle,
    "Draws a stable horizontal velocity arrow from each moving player's pelvis. Jumping and falling no longer distort the direction."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.vehicle_esp,
    "Player Vehicle ESP",
    eFeatureType.Toggle,
    "Shows streamed player vehicles with driver, speed, health, model hash and distance. Each occupied vehicle is drawn once."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.weapon_esp,
    "Equipped Weapon ESP",
    eFeatureType.Toggle,
    "Shows a compact cached weapon name above the player shoulder. No background box or constantly changing ammo label."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.show_dead_esp,
    "Show Dead ESP",
    eFeatureType.Toggle,
    "Keeps player and NPC ESP visible after death and marks dead bodies with a red DEAD label."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.nearby_counter,
    "Nearby-Player Counter",
    eFeatureType.Toggle,
    "Shows the number of streamed remote players within 150 metres."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_skeleton,
    "Self Skeleton",
    eFeatureType.Toggle,
    "Draws the full live skeleton rig on your own character without enabling remote-player ESP."
):SetSaveable(true)

H._self_esp.color_feature = FeatureMgr.AddFeature(
    H.self_color,
    "Self ESP Color",
    eFeatureType.InputColor4,
    "Independent color and opacity used only by Self ESP."
)
H._self_esp.color_feature:SetColor(95, 190, 255, 235)
H._self_esp.color_feature:SetSaveable(true)

H._self_esp.thickness_feature = FeatureMgr.AddFeature(
    H.self_thickness,
    "Self Line Thickness",
    eFeatureType.SliderFloat,
    "Changes the local skeleton, box and direction-line thickness."
)
H._self_esp.thickness_feature:SetLimitValues(1.0, 5.0)
H._self_esp.thickness_feature:SetDefaultValue(2.0)
H._self_esp.thickness_feature:SetStepSize(0.1)
H._self_esp.thickness_feature:SetSaveable(true)
H._self_esp.thickness_feature:Reset()

H._self_esp.head_feature = FeatureMgr.AddFeature(
    H.self_head_size,
    "Self Head Size",
    eFeatureType.SliderFloat,
    "Changes the local head-circle scale."
)
H._self_esp.head_feature:SetLimitValues(0.5, 1.8)
H._self_esp.head_feature:SetDefaultValue(0.9)
H._self_esp.head_feature:SetStepSize(0.1)
H._self_esp.head_feature:SetSaveable(true)
H._self_esp.head_feature:Reset()

FeatureMgr.AddFeature(
    H.self_box,
    "Self 2D Box",
    eFeatureType.Toggle,
    "Draws a two-dimensional box around your own projected character."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_health,
    "Self Health Bar",
    eFeatureType.Toggle,
    "Draws your current health beside the local box bounds."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_armour,
    "Self Armour Bar",
    eFeatureType.Toggle,
    "Draws your current armour beside the local box bounds."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_facing,
    "Self Facing Direction",
    eFeatureType.Toggle,
    "Draws the direction your own character is facing."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_movement,
    "Self Movement Direction",
    eFeatureType.Toggle,
    "Draws your current horizontal movement direction."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_weapon,
    "Self Equipped Weapon",
    eFeatureType.Toggle,
    "Shows your equipped weapon beside your projected shoulder."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.self_show_dead,
    "Show Self ESP While Dead",
    eFeatureType.Toggle,
    "Keeps local ESP visible during the death camera and adds a DEAD marker."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.npc_skeletons,
    "NPC Skeletons",
    eFeatureType.Toggle,
    "Draws detailed stable NPC skeletons with segmented spine, elbows, hips, knees, feet, toes and ultra-close five-finger tracking. Distance LOD reduces long-range bone count while every rendered point is projected live each frame.",
    function(feature)
        if feature:IsToggled() then
            GUI.AddToast(
                "elloscript NPC ESP",
                "NPC Skeletons enabled. Configure range, count, color and tracers below.",
                5000
            )
        end
    end
):SetSaveable(true)

local npc_color_feature =
    FeatureMgr.AddFeature(
        H.npc_color,
        "NPC Skeleton Color",
        eFeatureType.InputColor4,
        "Separate color and opacity used only for NPC skeletons."
    )
npc_color_feature:SetColor(
    255,
    130,
    30,
    235
)
npc_color_feature:SetSaveable(true)

local npc_range_feature =
    FeatureMgr.AddFeature(
        H.npc_range,
        "NPC Loading Range",
        eFeatureType.SliderFloat,
        "Maximum distance in metres for scanning and drawing NPC skeletons."
    )
npc_range_feature:SetLimitValues(
    25.0,
    300.0
)
npc_range_feature:SetDefaultValue(120.0)
npc_range_feature:SetStepSize(5.0)
npc_range_feature:SetSaveable(true)
npc_range_feature:Reset()

local npc_max_count_feature =
    FeatureMgr.AddFeature(
        H.npc_max_count,
        "Maximum NPCs",
        eFeatureType.SliderInt,
        "Maximum number of nearest NPC handles kept by the scanner. Render positions are never cached."
    )
npc_max_count_feature:SetLimitValues(
    4,
    64
)
npc_max_count_feature:SetDefaultValue(24)
npc_max_count_feature:SetStepSize(1)
npc_max_count_feature:SetSaveable(true)
npc_max_count_feature:Reset()

local npc_refresh_feature =
    FeatureMgr.AddFeature(
        H.npc_refresh_ms,
        "NPC Scan Interval",
        eFeatureType.SliderInt,
        "How often the ped pool is rescanned in milliseconds. Drawing still happens every frame."
    )
npc_refresh_feature:SetLimitValues(
    150,
    1500
)
npc_refresh_feature:SetDefaultValue(500)
npc_refresh_feature:SetStepSize(50)
npc_refresh_feature:SetSaveable(true)
npc_refresh_feature:Reset()

local npc_thickness_feature =
    FeatureMgr.AddFeature(
        H.npc_thickness,
        "NPC Line Thickness",
        eFeatureType.SliderFloat,
        "Separate line thickness for NPC skeletons."
    )
npc_thickness_feature:SetLimitValues(
    1.0,
    5.0
)
npc_thickness_feature:SetDefaultValue(1.8)
npc_thickness_feature:SetStepSize(0.1)
npc_thickness_feature:SetSaveable(true)
npc_thickness_feature:Reset()

local npc_head_size_feature =
    FeatureMgr.AddFeature(
        H.npc_head_size,
        "NPC Head Size",
        eFeatureType.SliderFloat,
        "Separate head-circle scale for NPC skeletons."
    )
npc_head_size_feature:SetLimitValues(
    0.5,
    1.8
)
npc_head_size_feature:SetDefaultValue(0.85)
npc_head_size_feature:SetStepSize(0.05)
npc_head_size_feature:SetSaveable(true)
npc_head_size_feature:Reset()

FeatureMgr.AddFeature(
    H.npc_tracers,
    "NPC Tracer Lines",
    eFeatureType.Toggle,
    "Draws a live tracer from your pelvis to every NPC selected by the scanner."
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.bullet_reflector,
    "Bullet Reflector",
    eFeatureType.Toggle,
    "Returns hostile gunfire to the shooter. Detection is based on firing direction, so it also works while God Mode prevents incoming damage.",
    function(feature)
        H._bullet_reflector.reset()

        if feature:IsToggled() and not remote_damage.ready then
            GUI.AddToast(
                "Bullet Reflector",
                tostring(remote_damage.error or "Damage function is unavailable."),
                5000
            )
        end
    end
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.pvp_ghost,
    "Ghost",
    eFeatureType.Toggle,
    "Applies the network ghost state and local invincibility without disabling weapon controls. Bind this normal toggle through Cherax's feature hotkey system.",
    function()
        H._pvp_ghost.refresh()
    end
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.auto_pvp_ghost,
    "Auto Ghost",
    eFeatureType.Toggle,
    "Automatically enables Ghost while another active player is aiming or firing directly at you, then releases shortly after the threat ends.",
    function()
        H._pvp_ghost.refresh()
    end
):SetSaveable(true)

FeatureMgr.AddFeature(
    H.heal_armour,
    "Restore Health & Armour",
    eFeatureType.Button,
    "Restores your health to maximum and armour to 100.",
    function()
        heal_and_armour_self()
    end
)

FeatureMgr.AddFeature(
    H.repair_vehicle,
    "Repair & Clean Current Vehicle",
    eFeatureType.Button,
    "Repairs deformation and engine damage, cleans the vehicle and restores its tyres.",
    function()
        repair_current_vehicle()
    end
)

FeatureMgr.AddFeature(
    H.flip_vehicle,
    "Flip Current Vehicle Upright",
    eFeatureType.Button,
    "Stops angular movement and places your current vehicle upright on the ground.",
    function()
        flip_current_vehicle()
    end
)

utility_features.god_mode = FeatureMgr.AddFeature(
    H.god_mode,
    "God Mode",
    eFeatureType.Toggle,
    "Keeps your player and character invincible.",
    function(feature)
        utility_state.god_mode =
            feature:IsToggled()

        if not utility_state.god_mode then
            PLAYER.SET_PLAYER_INVINCIBLE(
                PLAYER.PLAYER_ID(),
                false
            )
            ENTITY.SET_ENTITY_INVINCIBLE(
                local_ped(),
                false
            )
        end
    end
)
utility_features.god_mode:SetSaveable(true)

utility_features.ghost_mode = FeatureMgr.AddFeature(
    H.ghost_mode,
    "Invisible",
    eFeatureType.Toggle,
    "Makes your character invisible while keeping normal movement.",
    function(feature)
        utility_state.ghost_mode =
            feature:IsToggled()

        if not utility_state.ghost_mode then
            ENTITY.SET_ENTITY_VISIBLE(
                local_ped(),
                true,
                false
            )
        end
    end
)
utility_features.ghost_mode:SetSaveable(true)

utility_features.no_ragdoll = FeatureMgr.AddFeature(
    H.no_ragdoll,
    "No Ragdoll",
    eFeatureType.Toggle,
    "Stops your character from falling into ragdoll.",
    function(feature)
        utility_state.no_ragdoll =
            feature:IsToggled()

        if not utility_state.no_ragdoll then
            PED.SET_PED_CAN_RAGDOLL(
                local_ped(),
                true
            )
        end
    end
)
utility_features.no_ragdoll:SetSaveable(true)

utility_features.never_wanted = FeatureMgr.AddFeature(
    H.never_wanted,
    "Never Wanted",
    eFeatureType.Toggle,
    "Continuously clears your wanted level.",
    function(feature)
        utility_state.never_wanted =
            feature:IsToggled()
    end
)
utility_features.never_wanted:SetSaveable(true)

utility_features.unlimited_stamina = FeatureMgr.AddFeature(
    H.unlimited_stamina,
    "Unlimited Stamina",
    eFeatureType.Toggle,
    "Keeps stamina full while running or swimming.",
    function(feature)
        utility_state.unlimited_stamina =
            feature:IsToggled()
    end
)
utility_features.unlimited_stamina:SetSaveable(true)

utility_features.super_run = FeatureMgr.AddFeature(
    H.super_run,
    "Super Run",
    eFeatureType.Toggle,
    "Increases your running and sprinting speed.",
    function(feature)
        utility_state.super_run =
            feature:IsToggled()

        if not utility_state.super_run then
            PLAYER.SET_RUN_SPRINT_MULTIPLIER_FOR_PLAYER(
                PLAYER.PLAYER_ID(),
                1.0
            )
        end
    end
)
utility_features.super_run:SetSaveable(true)

utility_features.super_jump = FeatureMgr.AddFeature(
    H.super_jump,
    "Super Jump",
    eFeatureType.Toggle,
    "Gives your character a much higher jump.",
    function(feature)
        utility_state.super_jump =
            feature:IsToggled()
    end
)
utility_features.super_jump:SetSaveable(true)

FeatureMgr.AddFeature(
    H.clean_character,
    "Clean Character",
    eFeatureType.Button,
    "Removes blood, wetness and visible character damage.",
    clean_character
)

utility_features.vehicle_god_mode = FeatureMgr.AddFeature(
    H.vehicle_god_mode,
    "Vehicle God Mode",
    eFeatureType.Toggle,
    "Protects your current vehicle and follows you when you switch vehicles.",
    function(feature)
        utility_state.vehicle_god_mode =
            feature:IsToggled()

        if not utility_state.vehicle_god_mode then
            restore_vehicle_god_mode()
        end
    end
)
utility_features.vehicle_god_mode:SetSaveable(true)

utility_features.auto_repair = FeatureMgr.AddFeature(
    H.auto_repair,
    "Auto Repair",
    eFeatureType.Toggle,
    "Quietly repairs your current vehicle every 1.5 seconds.",
    function(feature)
        utility_state.auto_repair =
            feature:IsToggled()
        utility_state.next_auto_repair_at = 0
    end
)
utility_features.auto_repair:SetSaveable(true)

utility_features.seatbelt = FeatureMgr.AddFeature(
    H.seatbelt,
    "Seatbelt",
    eFeatureType.Toggle,
    "Reduces the chance of being thrown from your vehicle.",
    function(feature)
        utility_state.seatbelt =
            feature:IsToggled()

        if not utility_state.seatbelt then
            local ped = local_ped()
            PED.SET_PED_CONFIG_FLAG(
                ped,
                32,
                true
            )
            PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(
                ped,
                0
            )
        end
    end
)
utility_features.seatbelt:SetSaveable(true)

FeatureMgr.AddFeature(
    H.full_send,
    "Full Send",
    eFeatureType.Button,
    "Gives your current vehicle a strong forward speed boost.",
    full_send
)

FeatureMgr.AddFeature(
    H.instant_stop,
    "Instant Stop",
    eFeatureType.Button,
    "Stops your current vehicle immediately.",
    instant_stop
)

FeatureMgr.AddFeature(
    H.vehicle_jump,
    "Vehicle Jump",
    eFeatureType.Button,
    "Launches your current vehicle upward.",
    jump_current_vehicle
)

FeatureMgr.AddFeature(
    H.barrel_roll,
    "Barrel Roll",
    eFeatureType.Button,
    "Launches and rotates your current vehicle into a barrel roll.",
    barrel_roll_current_vehicle
)

FeatureMgr.AddFeature(
    H.moon_launch,
    "Moon Launch",
    eFeatureType.Button,
    "Launches your current vehicle high into the air.",
    moon_launch_current_vehicle
)

utility_features.drift_mode = FeatureMgr.AddFeature(
    H.drift_mode,
    "Drift Mode",
    eFeatureType.Toggle,
    "Reduces grip on your current vehicle for easier drifting.",
    function(feature)
        utility_state.drift_mode =
            feature:IsToggled()

        if not utility_state.drift_mode then
            restore_drift_mode()
        end
    end
)
utility_features.drift_mode:SetSaveable(true)

utility_features.keep_vehicle_locked = FeatureMgr.AddFeature(
    H.keep_vehicle_locked,
    "Keep Vehicle Locked",
    eFeatureType.Toggle,
    "Keeps your current vehicle locked and restores its old lock state when disabled.",
    function(feature)
        utility_state.keep_vehicle_locked =
            feature:IsToggled()

        if not utility_state.keep_vehicle_locked then
            restore_vehicle_lock()
        end
    end
)
utility_features.keep_vehicle_locked:SetSaveable(true)

FeatureMgr.AddFeature(
    H.door_control,
    "Door Control",
    eFeatureType.Button,
    "Opens all available doors, or closes them when already open.",
    toggle_current_vehicle_doors
)

FeatureMgr.AddFeature(
    H.toggle_engine,
    "Toggle Engine",
    eFeatureType.Button,
    "Switches your current vehicle engine on or off.",
    toggle_current_vehicle_engine
)

FeatureMgr.AddFeature(
    H.teleport_waypoint,
    "Teleport To Waypoint",
    eFeatureType.Button,
    "Teleports you or your current vehicle to the map waypoint.",
    function()
        Script.QueueJob(
            teleport_to_waypoint
        )
    end
)

FeatureMgr.AddFeature(
    H.cleanup_actions,
    "Stop Actions & Cleanup Entities",
    eFeatureType.Button,
    "Stops active script toggles, removes spawned props/NPCs/vehicles and clears focus state.",
    function()

        stop_kill_all_loop_silent()
        stop_all_kill_loops()
        disable_all_utility_features()
            recover_visual_state()
        extra_troll.cleanup()

        GUI.AddToast(
            "elloscript",
            "Active actions stopped and script entities cleaned.",
            4000
        )
    end
)

FeatureMgr.AddFeature(
    H.save_position,
    "Save Current Position",
    eFeatureType.Button,
    "Manually saves your current coordinates, heading and vehicle state for Return To Previous Position.",
    function()
        manually_save_current_position()
    end
)

FeatureMgr.AddFeature(
    H.clear_position,
    "Clear Saved Position",
    eFeatureType.Button,
    "Clears the currently saved return point.",
    function()
        clear_saved_position()
    end
)

FeatureMgr.AddFeature(
    H.info_all,
    "Player Information - All Players",
    eFeatureType.Toggle,
    "Shows the information label above every streamed remote player."
):SetSaveable(true)

FeatureMgr.AddPlayerFeature(
    H.info,
    "Player Information HUD",
    eFeatureType.Toggle,
    "Shows name, distance, health, armour, vehicle state and interior ID above the selected player."
)

FeatureMgr.AddPlayerFeature(
    H.teleport_player,
    "Teleport To Player",
    eFeatureType.Button,
    "Moves you or your current vehicle behind the selected player.",
    function(feature)
        teleport_to_selected_player(
            feature:GetPlayerIndex()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.horn_spam,
    "Horn Spam",
    eFeatureType.Toggle,
    "Continuously sounds the selected player's vehicle horn until disabled.",
    function(feature)
        extra_troll.set_horn_spam(
            feature:GetPlayerIndex(),
            feature:IsToggled()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.door_chaos,
    "Door Chaos",
    eFeatureType.Toggle,
    "Continuously opens and closes all available doors on the selected player's vehicle until disabled.",
    function(feature)
        extra_troll.set_door_chaos(
            feature:GetPlayerIndex(),
            feature:IsToggled()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.spin_vehicle,
    "Spin Vehicle",
    eFeatureType.Button,
    "Applies strong angular velocity to the selected player's current vehicle.",
    function(feature)
        extra_troll.spin_vehicle(
            feature:GetPlayerIndex()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.engine_kill,
    "Engine Kill",
    eFeatureType.Button,
    "Turns off the selected player's engine, marks the vehicle undriveable and destroys engine health.",
    function(feature)
        extra_troll.engine_kill(
            feature:GetPlayerIndex()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.burst_tires,
    "Burst All Tires",
    eFeatureType.Button,
    "Attempts to burst every supported tyre index on the selected player's vehicle.",
    function(feature)
        extra_troll.burst_tires(
            feature:GetPlayerIndex()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.freeze_vehicle,
    "Freeze Vehicle",
    eFeatureType.Toggle,
    "Continuously freezes the selected player's current vehicle. Disabling releases it.",
    function(feature)
        extra_troll.set_freeze_vehicle(
            feature:GetPlayerIndex(),
            feature:IsToggled()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.slam_vehicle,
    "Slam Vehicle Down",
    eFeatureType.Button,
    "Applies a strong downward force to the selected player's current vehicle.",
    function(feature)
        extra_troll.slam_vehicle(
            feature:GetPlayerIndex()
        )
    end
)

FeatureMgr.AddPlayerFeature(
    H.kill_selected,
    "Kill Selected",
    eFeatureType.Button,
    "Sets the selected streamed player ped's health to zero.",
    function(feature)
        local player_id = feature:GetPlayerIndex()
        Script.QueueJob(function(id)
            kill_selected(id)
        end, player_id)
    end
)

FeatureMgr.AddPlayerFeature(
    H.kill_loop,
    "Kill Loop",
    eFeatureType.Toggle,
    "Repeatedly sends the selected-player damage event until disabled or the player leaves.",
    function(feature)
        set_kill_loop(
            feature:GetPlayerIndex(),
            feature:IsToggled()
        )
    end
)

FeatureMgr.AddFeature(
    H.kill_all,
    "Kill All Players",
    eFeatureType.Button,
    "Attempts the same health action on every other streamed player.",
    function()
        Script.QueueJob(function()
            kill_all()
        end)
    end
)

FeatureMgr.AddFeature(
    H.kill_all_loop,
    "Kill All Loop",
    eFeatureType.Toggle,
    "Continuously cycles through active players using one throttled worker job.",
    function(feature)
        set_kill_all_loop(feature:IsToggled())
    end
)

FeatureMgr.AddPlayerFeature(
    H.orbital_selected,
    "Orbital Cannon (Selected)",
    eFeatureType.Button,
    "Triggers an orbital-style explosion sequence at the selected player's streamed position.",
    function(feature)
        local player_id = feature:GetPlayerIndex()
        Script.QueueJob(function(id)
            orbital_selected(id)
        end, player_id)
    end
)

FeatureMgr.AddFeature(
    H.orbital_all,
    "Orbital Cannon (All)",
    eFeatureType.Button,
    "Triggers the orbital-style sequence at every other streamed player's position.",
    function()
        Script.QueueJob(function()
            orbital_all()
        end)
    end
)

FeatureMgr.AddPlayerFeature(
    H.explode_vehicle,
    "Explode Vehicle",
    eFeatureType.Button,
    "Triggers explosions at the selected player's streamed vehicle.",
    function(feature)
        local player_id = feature:GetPlayerIndex()
        Script.QueueJob(function(id)
            explode_vehicle_of(id)
        end, player_id)
    end
)

FeatureMgr.AddFeature(
    H.explode_all_vehicles,
    "Explode All Vehicles",
    eFeatureType.Button,
    "Triggers one explosion per unique vehicle occupied by another streamed player.",
    function()
        Script.QueueJob(function()
            explode_all_vehicles()
        end)
    end
)

FeatureMgr.AddPlayerFeature(
    H.return_position,
    "Return To Previous Position",
    eFeatureType.Button,
    "Returns you to the manually saved point or the automatic backup created before vehicle/interior entry.",
    function()
        GUI.AddToast("elloscript", "Return job queued.", 2000)

        Script.QueueJob(function()
            return_to_saved()
        end)
    end
)

local feature_catalogue = {
    {"General", "Heal & Armour", H.heal_armour, false},
    {"General", "Repair & Clean Current Vehicle", H.repair_vehicle, false},
    {"General", "Flip Current Vehicle Upright", H.flip_vehicle, false},
    {"General", "God Mode", H.god_mode, false},
    {"General", "Invisible", H.ghost_mode, false},
    {"General", "No Ragdoll", H.no_ragdoll, false},
    {"General", "Never Wanted", H.never_wanted, false},
    {"General", "Unlimited Stamina", H.unlimited_stamina, false},
    {"General", "Super Run", H.super_run, false},
    {"General", "Super Jump", H.super_jump, false},
    {"General", "Clean Character", H.clean_character, false},
    {"General", "Save Current Position", H.save_position, false},
    {"General", "Clear Saved Position", H.clear_position, false},
    {"General", "Stop Actions & Cleanup Entities", H.cleanup_actions, false},
    {"Vehicle", "Vehicle God Mode", H.vehicle_god_mode, false},
    {"Vehicle", "Auto Repair", H.auto_repair, false},
    {"Vehicle", "Seatbelt", H.seatbelt, false},
    {"Vehicle", "Full Send", H.full_send, false},
    {"Vehicle", "Instant Stop", H.instant_stop, false},
    {"Vehicle", "Vehicle Jump", H.vehicle_jump, false},
    {"Vehicle", "Barrel Roll", H.barrel_roll, false},
    {"Vehicle", "Moon Launch", H.moon_launch, false},
    {"Vehicle", "Drift Mode", H.drift_mode, false},
    {"Vehicle", "Keep Vehicle Locked", H.keep_vehicle_locked, false},
    {"Vehicle", "Door Control", H.door_control, false},
    {"Vehicle", "Toggle Engine", H.toggle_engine, false},
    {"Travel", "Teleport To Waypoint", H.teleport_waypoint, false},
    {"Travel", "Return To Previous Position", H.return_position, false},
    {"ESP", "Player Skeleton ESP", H.skeleton, false},
    {"ESP", "Skeleton Color", H.skeleton_color, false},
    {"ESP", "Skeleton Thickness", H.skeleton_thickness, false},
    {"ESP", "Skeleton Head Size", H.skeleton_head_size, false},
    {"ESP", "Skeleton Tracers", H.skeleton_tracers, false},
    {"ESP", "Aim Part Highlight", H.aim_part_highlight, false},
    {"ESP", "Player Info ESP", H.info_all, false},
    {"ESP", "Nearby Player Counter", H.nearby_counter, false},
    {"ESP", "Box ESP", H.box_esp, false},
    {"ESP", "Health Bar ESP", H.health_bar_esp, false},
    {"ESP", "Armour Bar ESP", H.armour_bar_esp, false},
    {"ESP", "Offscreen Arrows", H.offscreen_arrows, false},
    {"ESP", "Selected Player Highlight", H.selected_highlight, false},
    {"ESP", "Visible Players Only", H.visible_only, false},
    {"ESP", "Facing Direction", H.facing_direction, false},
    {"ESP", "Movement Direction", H.movement_direction, false},
    {"ESP", "Player Vehicle ESP", H.vehicle_esp, false},
    {"ESP", "Equipped Weapon ESP", H.weapon_esp, false},
    {"ESP", "Show Dead ESP", H.show_dead_esp, false},
    {"Self ESP", "Self Skeleton", H.self_skeleton, false},
    {"Self ESP", "Self ESP Color", H.self_color, false},
    {"Self ESP", "Self Line Thickness", H.self_thickness, false},
    {"Self ESP", "Self Head Size", H.self_head_size, false},
    {"Self ESP", "Self 2D Box", H.self_box, false},
    {"Self ESP", "Self Health Bar", H.self_health, false},
    {"Self ESP", "Self Armour Bar", H.self_armour, false},
    {"Self ESP", "Self Facing Direction", H.self_facing, false},
    {"Self ESP", "Self Movement Direction", H.self_movement, false},
    {"Self ESP", "Self Equipped Weapon", H.self_weapon, false},
    {"Self ESP", "Show Self ESP While Dead", H.self_show_dead, false},
    {"Signature ESP", "Advanced NPC Skeleton ESP", H.npc_skeletons, false},
    {"Signature ESP", "NPC Skeleton Color", H.npc_color, false},
    {"Signature ESP", "NPC Loading Range", H.npc_range, false},
    {"Signature ESP", "Maximum NPC Count", H.npc_max_count, false},
    {"Signature ESP", "NPC Refresh Interval", H.npc_refresh_ms, false},
    {"Signature ESP", "NPC Line Thickness", H.npc_thickness, false},
    {"Signature ESP", "NPC Head Size", H.npc_head_size, false},
    {"Signature ESP", "NPC Tracers", H.npc_tracers, false},
    {"PvP", "Bullet Reflector", H.bullet_reflector, false},
    {"PvP", "Ghost", H.pvp_ghost, false},
    {"PvP", "Auto Ghost", H.auto_pvp_ghost, false},
    {"Session", "Kill All Players", H.kill_all, false},
    {"Session", "Kill All Loop", H.kill_all_loop, false},
    {"Session", "Orbital Cannon All", H.orbital_all, false},
    {"Session", "Explode All Vehicles", H.explode_all_vehicles, false},
    {"Player", "Selected Player Info", H.info, true},
    {"Player", "Teleport To Player", H.teleport_player, true},
    {"Player", "Horn Spam", H.horn_spam, true},
    {"Player", "Door Chaos", H.door_chaos, true},
    {"Player", "Spin Vehicle", H.spin_vehicle, true},
    {"Player", "Engine Kill", H.engine_kill, true},
    {"Player", "Burst Tyres", H.burst_tires, true},
    {"Player", "Freeze Vehicle", H.freeze_vehicle, true},
    {"Player", "Slam Vehicle", H.slam_vehicle, true},
    {"Player", "Kill Selected", H.kill_selected, true},
    {"Player", "Kill Loop", H.kill_loop, true},
    {"Player", "Orbital Cannon Selected", H.orbital_selected, true},
    {"Player", "Explode Vehicle", H.explode_vehicle, true},
}

local search_query = ""
local function normalized(text)
    return string.lower(tostring(text or ""))
end

local function render_search_tab()
    ImGui.TextWrapped("Search every elloscript feature. Player actions use the currently selected Cherax player.")
    local a, b = ImGui.InputText("Search##elloscript_search", search_query, 96)
    if type(a) == "string" then
        search_query = a
    elseif type(b) == "string" then
        search_query = b
    end

    local query = normalized(search_query)
    ImGui.Separator()
    if query == "" then
        ImGui.TextWrapped("Type a feature name or category, for example: skeleton, vehicle, teleport, kill, ESP.")
        return
    end

    local selected_player = Utils.GetSelectedPlayer()
    local matches = 0
    for _, item in ipairs(feature_catalogue) do
        local category, name, hash, player_feature = item[1], item[2], item[3], item[4]
        local haystack = normalized(category .. " " .. name)
        if string.find(haystack, query, 1, true) ~= nil then
            matches = matches + 1
            ImGui.Text(category .. " > " .. name)
            if player_feature then
                ClickGUI.RenderFeature(hash, selected_player)
            else
                ClickGUI.RenderFeature(hash)
            end
            ImGui.Separator()
        end
    end
    if matches == 0 then
        ImGui.Text("No matching features.")
    else
        ImGui.Text("Matches: " .. tostring(matches))
    end
end

local function render_info_tab()
    ImGui.Text("ELLOSCRIPT v1.1")
    ImGui.Text("Menu: Cherax Mod Menu")
    ImGui.Text("GTA V Legacy Edition - Verified")
    ImGui.Text("GTA V Enhanced Edition - Supported, not yet verified")
    ImGui.Separator()
    ImGui.Text("SIGNATURE FEATURE")
    ImGui.TextWrapped("Advanced NPC Skeleton ESP: cached handle scanning with live frame-synchronous bone projection, configurable range, count, refresh interval, tracers, colors, thickness and head size.")
    ImGui.Separator()
    ImGui.Text("Complete Feature Index: " .. tostring(#feature_catalogue) .. " entries")
    local current_category = ""
    for _, item in ipairs(feature_catalogue) do
        if item[1] ~= current_category then
            current_category = item[1]
            ImGui.Separator()
            ImGui.Text(current_category)
        end
        ImGui.Text("- " .. item[2])
    end
end

local function render_credits_tab()
    ImGui.Text("ELLOSCRIPT v1.1")
    ImGui.Separator()
    ImGui.Text("Created by elloeu")
    ImGui.Text("Built for Cherax Mod Menu")
    ImGui.TextWrapped("Special thanks: animusx1337 (Public Urinal).")
end

local function render_script_tab()
    if not ImGui.BeginTabBar("elloscript_main_subtabs") then
        return
    end

    if ImGui.BeginTabItem("General##elloscript_main") then
        if ClickGUI.BeginCustomChildWindow("Self Recovery") then
            ClickGUI.RenderFeature(H.heal_armour)
            ClickGUI.RenderFeature(H.repair_vehicle)
            ClickGUI.RenderFeature(H.flip_vehicle)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Player Modes") then
            ClickGUI.RenderFeature(H.god_mode)
            ClickGUI.RenderFeature(H.ghost_mode)
            ClickGUI.RenderFeature(H.no_ragdoll)
            ClickGUI.RenderFeature(H.never_wanted)
            ClickGUI.RenderFeature(H.unlimited_stamina)
            ClickGUI.RenderFeature(H.super_run)
            ClickGUI.RenderFeature(H.super_jump)
            ClickGUI.RenderFeature(H.clean_character)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Position & Cleanup") then
            ClickGUI.RenderFeature(H.save_position)
            ClickGUI.RenderFeature(H.clear_position)
            ClickGUI.RenderFeature(H.cleanup_actions)

            if saved.valid then
                ImGui.Text("Saved return point: READY")
            else
                ImGui.Text("Saved return point: NONE")
            end

            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Vehicle##elloscript_main") then
        if ClickGUI.BeginCustomChildWindow("Protection & Recovery") then
            ClickGUI.RenderFeature(H.vehicle_god_mode)
            ClickGUI.RenderFeature(H.auto_repair)
            ClickGUI.RenderFeature(H.seatbelt)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Driving & Control") then
            ClickGUI.RenderFeature(H.full_send)
            ClickGUI.RenderFeature(H.instant_stop)
            ClickGUI.RenderFeature(H.vehicle_jump)
            ClickGUI.RenderFeature(H.barrel_roll)
            ClickGUI.RenderFeature(H.moon_launch)
            ClickGUI.RenderFeature(H.drift_mode)
            ClickGUI.RenderFeature(H.keep_vehicle_locked)
            ClickGUI.RenderFeature(H.door_control)
            ClickGUI.RenderFeature(H.toggle_engine)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Travel##elloscript_main") then
        if ClickGUI.BeginCustomChildWindow("Teleport & Return") then
            ClickGUI.RenderFeature(H.teleport_waypoint)
            ClickGUI.RenderFeature(H.return_position)

            if saved.valid then
                ImGui.Text("Saved position: READY")
            else
                ImGui.Text("Saved position: NONE")
            end

            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("ESP##elloscript_main") then
        if ImGui.BeginTabBar("elloscript_esp_subtabs") then
            if ImGui.BeginTabItem("Player##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Player Skeleton") then
                    ClickGUI.RenderFeature(H.skeleton)
                    ClickGUI.RenderFeature(H.skeleton_color)
                    ClickGUI.RenderFeature(H.skeleton_thickness)
                    ClickGUI.RenderFeature(H.skeleton_head_size)
                    ClickGUI.RenderFeature(H.skeleton_tracers)
                    ClickGUI.RenderFeature(H.aim_part_highlight)
                    ClickGUI.EndCustomChildWindow()
                end

                if ClickGUI.BeginCustomChildWindow("Player Information") then
                    ClickGUI.RenderFeature(H.info_all)
                    ClickGUI.RenderFeature(H.nearby_counter)
                    ClickGUI.RenderFeature(H.box_esp)
                    ClickGUI.RenderFeature(H.health_bar_esp)
                    ClickGUI.RenderFeature(H.armour_bar_esp)
                    ClickGUI.RenderFeature(H.offscreen_arrows)
                    ClickGUI.RenderFeature(H.selected_highlight)
                    ClickGUI.RenderFeature(H.visible_only)
                    ClickGUI.RenderFeature(H.show_dead_esp)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Self##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Self Skeleton") then
                    ClickGUI.RenderFeature(H.self_skeleton)
                    ClickGUI.RenderFeature(H.self_color)
                    ClickGUI.RenderFeature(H.self_thickness)
                    ClickGUI.RenderFeature(H.self_head_size)
                    ClickGUI.RenderFeature(H.self_show_dead)
                    ClickGUI.EndCustomChildWindow()
                end

                if ClickGUI.BeginCustomChildWindow("Self Information") then
                    ClickGUI.RenderFeature(H.self_box)
                    ClickGUI.RenderFeature(H.self_health)
                    ClickGUI.RenderFeature(H.self_armour)
                    ClickGUI.RenderFeature(H.self_weapon)
                    ClickGUI.EndCustomChildWindow()
                end

                if ClickGUI.BeginCustomChildWindow("Self Direction") then
                    ClickGUI.RenderFeature(H.self_facing)
                    ClickGUI.RenderFeature(H.self_movement)
                    ClickGUI.EndCustomChildWindow()
                end

                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("NPC##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Advanced NPC Skeleton ESP") then
                    ImGui.TextWrapped(
                        "Signature NPC scanner with live frame-synchronous skeleton rendering and distance-based detail."
                    )
                    ClickGUI.RenderFeature(H.npc_skeletons)
                    ClickGUI.RenderFeature(H.npc_color)
                    ClickGUI.RenderFeature(H.npc_range)
                    ClickGUI.RenderFeature(H.npc_max_count)
                    ClickGUI.RenderFeature(H.npc_refresh_ms)
                    ClickGUI.RenderFeature(H.npc_thickness)
                    ClickGUI.RenderFeature(H.npc_head_size)
                    ClickGUI.RenderFeature(H.npc_tracers)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Vehicle##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Vehicle ESP") then
                    ClickGUI.RenderFeature(H.vehicle_esp)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Weapon##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Weapon ESP") then
                    ClickGUI.RenderFeature(H.weapon_esp)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Direction##elloscript_esp") then
                if ClickGUI.BeginCustomChildWindow("Direction Indicators") then
                    ClickGUI.RenderFeature(H.facing_direction)
                    ClickGUI.RenderFeature(H.movement_direction)
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("PvP##elloscript_main") then
        if ClickGUI.BeginCustomChildWindow("Combat Defence") then
            ClickGUI.RenderFeature(H.bullet_reflector)
            ClickGUI.RenderFeature(H.pvp_ghost)
            ClickGUI.RenderFeature(H.auto_pvp_ghost)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Session##elloscript_main") then
        if ClickGUI.BeginCustomChildWindow("Session-Wide Actions") then
            ClickGUI.RenderFeature(H.kill_all)
            ClickGUI.RenderFeature(H.kill_all_loop)
            ClickGUI.RenderFeature(H.orbital_all)
            ClickGUI.RenderFeature(H.explode_all_vehicles)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Search##elloscript_main") then
        render_search_tab()
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Info##elloscript_main") then
        render_info_tab()
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Credits##elloscript_main") then
        render_credits_tab()
        ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
end

local function render_player_tab()
    local player_id = Utils.GetSelectedPlayer()

    if not ImGui.BeginTabBar("elloscript_player_subtabs") then
        return
    end

    if ImGui.BeginTabItem("General##elloscript_player") then
        if ClickGUI.BeginCustomChildWindow("Selected Player") then
            ClickGUI.RenderFeature(H.info, player_id)
            ClickGUI.RenderFeature(H.teleport_player, player_id)
            ClickGUI.RenderFeature(H.return_position, player_id)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Trolling##elloscript_player") then
        if ClickGUI.BeginCustomChildWindow("Vehicle Trolling") then
            ClickGUI.RenderFeature(H.horn_spam, player_id)
            ClickGUI.RenderFeature(H.door_chaos, player_id)
            ClickGUI.RenderFeature(H.spin_vehicle, player_id)
            ClickGUI.EndCustomChildWindow()
        end

        if ClickGUI.BeginCustomChildWindow("Vehicle Sabotage") then
            ClickGUI.RenderFeature(H.engine_kill, player_id)
            ClickGUI.RenderFeature(H.burst_tires, player_id)
            ClickGUI.RenderFeature(H.freeze_vehicle, player_id)
            ClickGUI.RenderFeature(H.slam_vehicle, player_id)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem("Malicious##elloscript_player") then
        if ClickGUI.BeginCustomChildWindow("Direct Actions") then
            ClickGUI.RenderFeature(H.kill_selected, player_id)
            ClickGUI.RenderFeature(H.kill_loop, player_id)
            ClickGUI.RenderFeature(H.orbital_selected, player_id)
            ClickGUI.RenderFeature(H.explode_vehicle, player_id)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
end

local present_handler_id = EventMgr.RegisterHandler(
    eLuaEvent.ON_PRESENT,
    on_present
)

local function on_unload()

    utility_state.unloading = true
    H._pvp_ghost.shutdown()
    H._bullet_reflector.shutdown()
    stop_kill_all_loop_silent()
    stop_all_kill_loops()
    restore_all_utility_effects()

    recover_visual_state()
    if present_handler_id ~= nil then
        EventMgr.RemoveHandler(present_handler_id)
        present_handler_id = nil
    end

    ClickGUI.RemoveTab("elloscript")
    ClickGUI.RemovePlayerTab("elloscript")

    if screen_x_ptr ~= nil and screen_x_ptr ~= 0 then
        Memory.Free(screen_x_ptr)
        screen_x_ptr = 0
    end

    if screen_y_ptr ~= nil and screen_y_ptr ~= 0 then
        Memory.Free(screen_y_ptr)
        screen_y_ptr = 0
    end

    los_cache = {}
    npc_cache = {}

    extra_troll.cleanup()
end

local unload_handler_id =
    EventMgr.RegisterHandler(
        eLuaEvent.ON_UNLOAD,
        on_unload
    )

GUI.AddToast(
    "elloscript",
    "Loading elloscript...",
    1500
)

ClickGUI.AddTab(
    "elloscript",
    render_script_tab
)

ClickGUI.AddPlayerTab(
    "elloscript",
    render_player_tab
)

GUI.AddToast(
    "elloscript",
    "elloscript: Loaded",
    2500
)
