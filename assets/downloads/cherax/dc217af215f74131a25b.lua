
local function Invoke(returnType, hash)
    return function(...)
        return Natives[string.format("Invoke%s", returnType)](hash, ...)
    end
end

local PLAYER_ID = Invoke("Int", 0x4F8644AF03D0E0D6)
local PLAYER_PED_ID = Invoke("Int", 0xD80958FC74E988A6)
local GET_PLAYER_NAME = Invoke("String", 0x6D0DE6A7B5DA71F8)
local DOES_ENTITY_EXIST = Invoke("Bool", 0x7239B21A38F536BA)
local IS_ENTITY_PLAYING_ANIM = Invoke("Bool", 0x1F0B79228E461EC9)
local TASK_PLAY_ANIM = Invoke("Void", 0xEA47FE3719165B94)
local CREATE_OBJECT = Invoke("Int", 0x509D5878EB39E842)
local DELETE_OBJECT = Invoke("Void", 0x539E0AE3E6634B9F)
local SET_ENTITY_INVINCIBLE = Invoke("Void", 0x3882114BDE571AD4)
local GET_PED_BONE_INDEX = Invoke("Int", 0x3F428D08BE5AAE31)
local ATTACH_ENTITY_TO_ENTITY = Invoke("Void", 0x6B9BBD38AB0796DF)
local HAS_ANIM_EVENT_FIRED = Invoke("Bool", 0xEAF4CD9EA3E7E922)
local GET_HASH_KEY = Invoke("Int", 0xD24D37CC275948CC)
local DETACH_ENTITY = Invoke("Void", 0x961AC54BF0613F5D)
local FREEZE_ENTITY_POSITION = Invoke("Void", 0x428CA6DBD1094446)
local SET_ENTITY_COLLISION = Invoke("Void", 0x1A9205C1B9EE827F)
local GET_ENTITY_COORDS = Invoke("V3", 0x3FEF770D40960D5A)
local IS_PED_DEAD_OR_DYING = Invoke("Bool", 0x3317DEDB88C95038)
local IS_PED_RAGDOLL = Invoke("Bool", 0x47E4E977581C5B55)
local IS_PED_RUNNING_RAGDOLL_TASK = Invoke("Bool", 0xE3B6097CC25AA69E)
local IS_PED_IN_MELEE_COMBAT = Invoke("Bool", 0x4E209B2C1EAD5159)
local SET_OBJECT_AS_NO_LONGER_NEEDED = Invoke("Void", 0x3AE22DEB5BA5A3E6)
local ADD_SHOCKING_EVENT_AT_POSITION = Invoke("Int", 0xD9F8455409B525E9)
local USE_PARTICLE_FX_ASSET = Invoke("Void", 0x6C38AF3693A69A91)
local SET_PARTICLE_FX_NON_LOOPED_COLOUR = Invoke("Void", 0x26143A59EF48B262)
local START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD = Invoke("Bool", 0xF56B8137DF10135D)
local SET_ENTITY_VELOCITY = Invoke("Void", 0x1C99BB7B6E96D16F)
local REQUEST_MODEL = Invoke("Void", 0x963D27A58DF860AC)
local REQUEST_ANIM_DICT = Invoke("Void", 0xD3BD40951412FEF6)
local REQUEST_NAMED_PTFX_ASSET = Invoke("Void", 0xB80D8756B4668AB6)
local HAS_MODEL_LOADED = Invoke("Bool", 0x98A4EB5D89A0C952)
local HAS_ANIM_DICT_LOADED = Invoke("Bool", 0xD031A9162D01088C)
local HAS_NAMED_PTFX_ASSET_LOADED = Invoke("Bool", 0x8702416E512EC454)
local SET_MODEL_AS_NO_LONGER_NEEDED = Invoke("Void", 0xE532F5D78798DAAB)
local GET_MODEL_DIMENSIONS = Invoke("V3", 0x03E8D3D5F549087A)
local GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS = Invoke("V3", 0x1899F328B0E12848)
local GET_GROUND_Z_FOR_3D_COORD = Invoke("Bool", 0xC906A7DAB05C8D2B)
local GET_CLOSEST_OBJECT_OF_TYPE = Invoke("Int", 0xE143FA2249364369)
local START_SHAPE_TEST_BOX = Invoke("Int", 0xFE466162C4401D18)
local GET_SHAPE_TEST_RESULT = Invoke("Int", 0x3D87450E15D98694)
local REMOVE_NAMED_PTFX_ASSET = Invoke("Void", 0x5F61EBBE1A00F96D)
local IS_PED_IN_ANY_VEHICLE = Invoke("Bool", 0x997ABD671D25CA0B)
local NETWORK_REQUEST_CONTROL_OF_ENTITY = Invoke("Void", 0xB69317BF5E782347)
local SET_ENTITY_AS_MISSION_ENTITY = Invoke("Void", 0xAD738C3085FE7E11)
local DELETE_ENTITY = Invoke("Void", 0xAE3CBE5BF394C9C9)
local SET_TEXT_FONT = Invoke("Void", 0x66E0276CC5F6B9DA)
local SET_TEXT_SCALE = Invoke("Void", 0x07C837F9A01C34C9)
local SET_TEXT_COLOUR = Invoke("Void", 0xBE6B23FFA53FB442)
local SET_TEXT_JUSTIFICATION = Invoke("Void", 0x4E096588B13FFECA)
local SET_TEXT_WRAP = Invoke("Void", 0x63145D9C883A1A70)
local SET_TEXT_CENTRE = Invoke("Void", 0xC02F4DBFB51D988B)
local SET_TEXT_DROPSHADOW = Invoke("Void", 0x465C84BC39F1C351)
local SET_TEXT_EDGE = Invoke("Void", 0x441603240D202FA6)
local SET_TEXT_LEADING = Invoke("Void", 0xA50ABC31E3CDFAFF)
local BEGIN_TEXT_COMMAND_DISPLAY_TEXT = Invoke("Void", 0x25FBB336DF1804CB)
local ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME = Invoke("Void", 0x6C188BE134E074AA)
local END_TEXT_COMMAND_DISPLAY_TEXT = Invoke("Void", 0xCD015E5BB0D96A57)
local BEGIN_TEXT_COMMAND_GET_WIDTH = Invoke("Void", 0x54CE8AC98E120CAB)
local END_TEXT_COMMAND_GET_WIDTH = Invoke("Float", 0x85F061DA64ED2F67)
local BEGIN_TEXT_COMMAND_DISPLAY_HELP = Invoke("Void", 0x8509B634FBE7DA11)
local END_TEXT_COMMAND_DISPLAY_HELP = Invoke("Void", 0x238FFE5C7B0498A6)
local IS_CONTROL_JUST_PRESSED = Invoke("Bool", 0x580417101DDB492F)
local IS_DISABLED_CONTROL_JUST_PRESSED = Invoke("Bool", 0x91AEF906BCA88877)
local DISABLE_CONTROL_ACTION = Invoke("Void", 0xFE99B66D079CF6BC)
local PLAY_SOUND_FRONTEND = Invoke("Void", 0x67C540AA08E4A6F5)
local DRAW_RECT = Invoke("Void", 0x3A618A217E5154F0)
local DRAW_SPRITE = Invoke("Void", 0xE7FFAE5EBF23D890)
local REQUEST_STREAMED_TEXTURE_DICT = Invoke("Void", 0xDFA2EF8E04127DD5)
local HAS_STREAMED_TEXTURE_DICT_LOADED = Invoke("Bool", 0x0145F696AAAAD2E4)

local INPUT_DETONATE = 47
local INPUT_PHONE = 27
local INPUT_CELLPHONE_UP = 172
local INPUT_CELLPHONE_DOWN = 173
local INPUT_CELLPHONE_LEFT = 174
local INPUT_CELLPHONE_RIGHT = 175
local INPUT_FRONTEND_ACCEPT = 201

local function DELETE_NET_OBJECT(entity)
    NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    SET_ENTITY_AS_MISSION_ENTITY(entity, true, true)

    local ptr = Memory.AllocInt()
    Memory.WriteInt(ptr, entity)
    DELETE_ENTITY(ptr)
    Memory.Free(ptr)
end

local function DRAW_GENERIC_TIMER(iTime, x, y)
    SET_TEXT_FONT(4)
    SET_TEXT_SCALE(0.5, 0.5)
    SET_TEXT_COLOUR(255, 255, 255, 255)
    SET_TEXT_EDGE(2, 0, 0, 0, 255)
    SET_TEXT_WRAP(0.0, 1.0)
    SET_TEXT_CENTRE(true)

    BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(string.format("FIREWORKS  %05.2f", iTime / 1000))
    END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

-- Script value / Vector3 out-param scratch (a script Vector3 is 3 floats on 8-byte strides)
local function AllocScrValue()
    return Memory.Alloc(8)
end

local function AllocScrVector()
    return Memory.Alloc(24)
end

local function ReadScrVector(ptr)
    return Memory.ReadFloat(ptr), Memory.ReadFloat(ptr + 8), Memory.ReadFloat(ptr + 16)
end

-- *****************************************************************************************
-- *****************************************************************************************
--
--		MISSION NAME	:	net_fireworks.sch
--		AUTHOR			:	Martin McMillan
--		DESCRIPTION		:   Firework header for multiplayer
--
-- *****************************************************************************************
-- *****************************************************************************************

-- Script builtins that the header relies on. Lua cannot pass ints by reference,
-- so SET_BIT / CLEAR_BIT return the new value and callers reassign.
local function SET_BIT(iVar, iBit)
    return iVar | (1 << iBit)
end

local function CLEAR_BIT(iVar, iBit)
    return iVar & ~(1 << iBit)
end

local function IS_BIT_SET(iVar, iBit)
    return iVar & (1 << iBit) ~= 0
end

local function VDIST(v1, v2)
    return math.sqrt((v1.x - v2.x) ^ 2 + (v1.y - v2.y) ^ 2 + (v1.z - v2.z) ^ 2)
end

local function IS_VECTOR_ZERO(v)
    return v.x == 0.0 and v.y == 0.0 and v.z == 0.0
end

local function RESET_NET_TIMER(timer)
    timer.Timer = 0
end

local function HAS_NET_TIMER_EXPIRED(timer, iTime)
    if timer.Timer == 0 then
        timer.Timer = Time.GetEpocheMs()
        return false
    end

    return Time.GetEpocheMs() - timer.Timer > iTime
end

local function GET_NET_TIMER_DIFFERENCE_WITH_CURRENT_TIME(timer)
    if timer.Timer == 0 then
        return 0
    end

    return Time.GetEpocheMs() - timer.Timer
end

--//----------------------
--//	CONSTANTS
--//----------------------
local NO_FIREWORK_TYPES = 4
local NO_FIREWORK_COLOURS = 3
local MAX_FIREWORK_TIMER = 60
local MAX_OWNED_FIREWORKS = 10

local ST_INIT = 0
local ST_WAITING_RESULT = 1
local ST_RESULT_READY = 2

--//----------------------
--//	Local Bitset
--//----------------------

--//fireworkVars.iFireworkLocalBitset
local NOT_SAFE_TO_PLACE = 0
local DRAW_LAUNCH_TIMER = 1
local CHECK_CREATE_FIREWORK = 2
local CHECK_DETACH_FIREWORK = 3
local DO_SHOCKING_EVENT = 4

--//fireworkVars.iFireworkBitSet
local biShapeTestResultsDone = 0
local biShapeTestUpperResultsDone = 1
local biShapeTestFailed = 2

-- Character stat inventory backing (fireworks owned per type / colour).
-- The game reads these from the MP character stats; a standalone build cannot
-- touch those, so they are stored locally instead.
local MP_STAT_FIREWORK_TYPE_1_RED = "MP_STAT_FIREWORK_TYPE_1_RED"
local MP_STAT_FIREWORK_TYPE_1_WHITE = "MP_STAT_FIREWORK_TYPE_1_WHITE"
local MP_STAT_FIREWORK_TYPE_1_BLUE = "MP_STAT_FIREWORK_TYPE_1_BLUE"
local MP_STAT_FIREWORK_TYPE_2_RED = "MP_STAT_FIREWORK_TYPE_2_RED"
local MP_STAT_FIREWORK_TYPE_2_WHITE = "MP_STAT_FIREWORK_TYPE_2_WHITE"
local MP_STAT_FIREWORK_TYPE_2_BLUE = "MP_STAT_FIREWORK_TYPE_2_BLUE"
local MP_STAT_FIREWORK_TYPE_3_RED = "MP_STAT_FIREWORK_TYPE_3_RED"
local MP_STAT_FIREWORK_TYPE_3_WHITE = "MP_STAT_FIREWORK_TYPE_3_WHITE"
local MP_STAT_FIREWORK_TYPE_3_BLUE = "MP_STAT_FIREWORK_TYPE_3_BLUE"
local MP_STAT_FIREWORK_TYPE_4_RED = "MP_STAT_FIREWORK_TYPE_4_RED"
local MP_STAT_FIREWORK_TYPE_4_WHITE = "MP_STAT_FIREWORK_TYPE_4_WHITE"
local MP_STAT_FIREWORK_TYPE_4_BLUE = "MP_STAT_FIREWORK_TYPE_4_BLUE"

local g_FireworkStats = {
    [MP_STAT_FIREWORK_TYPE_1_RED] = 9999, [MP_STAT_FIREWORK_TYPE_1_WHITE] = 9999, [MP_STAT_FIREWORK_TYPE_1_BLUE] = 9999,
    [MP_STAT_FIREWORK_TYPE_2_RED] = 9999, [MP_STAT_FIREWORK_TYPE_2_WHITE] = 9999, [MP_STAT_FIREWORK_TYPE_2_BLUE] = 9999,
    [MP_STAT_FIREWORK_TYPE_3_RED] = 9999, [MP_STAT_FIREWORK_TYPE_3_WHITE] = 9999, [MP_STAT_FIREWORK_TYPE_3_BLUE] = 9999,
    [MP_STAT_FIREWORK_TYPE_4_RED] = 9999, [MP_STAT_FIREWORK_TYPE_4_WHITE] = 9999, [MP_STAT_FIREWORK_TYPE_4_BLUE] = 9999
}

local function GET_MP_INT_CHARACTER_STAT(stat)
    return g_FireworkStats[stat]
end

local function DECREMENT_MP_INT_CHARACTER_STAT(stat)
    g_FireworkStats[stat] = g_FireworkStats[stat] - 1
end

--//----------------------
--//	STRUCTS
--//----------------------
--//STRUCT FIREWORK
--//	OBJECT_INDEX obj
--//	INT iType
--//	INT iColour
--//	INT iTimer
--//	BOOL bPlaced
--//	BOOL bDoShapeTest
--//	VECTOR vLocation
--//	VECTOR vRocketStart
--//ENDSTRUCT
local function NEW_FIREWORK()
    return {
        obj = 0,
        iType = 0,
        iColour = 0,
        iTimer = 0,
        bPlaced = false,
        bDoShapeTest = false,
        vLocation = {x = 0.0, y = 0.0, z = 0.0},
        vRocketStart = {x = 0.0, y = 0.0, z = 0.0}
    }
end

local fireworkData = NEW_FIREWORK()

--//STRUCT FIREWORK_VARIABLES
local fireworkVars = {
    iNoPlacedFireworks = 0,

    fireworks = {},

    sti_Firework = 0,
    sti_FireworkUpper = 0,

    iShapeTestStage = ST_INIT,

    launchTimer = {Timer = 0},
    iNextFirework = 0,
    iElapsedTime = 0,

    iShockingEvent = 0,
    vShockingEventPos = {x = 0.0, y = 0.0, z = 0.0},

    iRocketCleanupBitSet = 0,
    iRocketToCheck = 0,

    iNewFirework = 0,

    iFireworkLocalBitset = 0,

    iFireworkBitSet = 0,

    iRocketCleanupTime = {}
}

for i = 0, MAX_OWNED_FIREWORKS - 1 do
    fireworkVars.fireworks[i] = NEW_FIREWORK()
    fireworkVars.iRocketCleanupTime[i] = {Timer = 0}
end

--/// PURPOSE:
--///    Increments the quantity of a given firework type
local function DECREMENT_FIREWORK_TYPE_QUANTITY(iType, iColour)
    if iType == 0 then
        if iColour == 0 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_RED)
        elseif iColour == 1 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_WHITE)
        elseif iColour == 2 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_BLUE)
        end
    elseif iType == 1 then
        if iColour == 0 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_RED)
        elseif iColour == 1 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_WHITE)
        elseif iColour == 2 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_BLUE)
        end
    elseif iType == 2 then
        if iColour == 0 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_RED)
        elseif iColour == 1 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_WHITE)
        elseif iColour == 2 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_BLUE)
        end
    elseif iType == 3 then
        if iColour == 0 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_RED)
        elseif iColour == 1 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_WHITE)
        elseif iColour == 2 then
            DECREMENT_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_BLUE)
        end
    end
end

--///// PURPOSE:
--/////    Gets the number of owned fireworks of a given type
--//FUNC INT GET_NO_OWNED_FIREWORK_TYPE(int iType)
--//	SWITCH(iType)
--//		CASE 0		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_RED)		BREAK
--//		CASE 1		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_WHITE)		BREAK
--//		CASE 2		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_BLUE)		BREAK
--//		CASE 3		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_RED)		BREAK
--//		CASE 4		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_WHITE)		BREAK
--//		CASE 5		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_BLUE)		BREAK
--//		CASE 6		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_RED)		BREAK
--//		CASE 7		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_WHITE)		BREAK
--//		CASE 8		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_BLUE)		BREAK
--//		CASE 9		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_RED)		BREAK
--//		CASE 10		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_WHITE)		BREAK
--//		CASE 11		RETURN GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_BLUE)		BREAK
--//	ENDSWITCH
--//	RETURN 0
--//ENDFUNC

--///// PURPOSE:
--/////    Gets the number of owned fireworks of a given type
local function GET_NO_OWNED_FIREWORK_TYPE_AND_COLOUR(iType, iColour)
    if iType == 0 then
        if iColour == 0 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_RED)
        elseif iColour == 1 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_WHITE)
        elseif iColour == 2 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_BLUE)
        end
    elseif iType == 1 then
        if iColour == 0 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_RED)
        elseif iColour == 1 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_WHITE)
        elseif iColour == 2 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_BLUE)
        end
    elseif iType == 2 then
        if iColour == 0 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_RED)
        elseif iColour == 1 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_WHITE)
        elseif iColour == 2 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_BLUE)
        end
    elseif iType == 3 then
        if iColour == 0 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_RED)
        elseif iColour == 1 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_WHITE)
        elseif iColour == 2 then
            return GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_BLUE)
        end
    end

    return 0
end

--///// PURPOSE:
--/////    Gets the total number of owned fireworks
local function GET_NO_OWNED_FIREWORK_TOTAL()
    local iTotal = 0
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_RED)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_WHITE)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_1_BLUE)

    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_RED)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_WHITE)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_2_BLUE)

    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_RED)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_WHITE)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_3_BLUE)

    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_RED)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_WHITE)
    iTotal = iTotal + GET_MP_INT_CHARACTER_STAT(MP_STAT_FIREWORK_TYPE_4_BLUE)

    return iTotal
end

--/// PURPOSE:
--///    Gets the anim name of a given firework type
local function GET_FIREWORK_TYPE_ANIM_NAME(iType)
    if iType == 0 then
        return "PLACE_FIREWORK_4_CONE"     --//Cone
    elseif iType == 1 then
        return "PLACE_FIREWORK_3_BOX"      --//Box
    elseif iType == 2 then
        return "PLACE_FIREWORK_2_CYLINDER" --//Cylinder
    elseif iType == 3 then
        return "PLACE_FIREWORK_1_ROCKET"   --//Rocket
    end

    return ""
end

--/// PURPOSE:
--///    Gets the model name of a given firework type
local function GET_FIREWORK_TYPE_MODEL_NAME(iType)
    if iType == 0 then
        return Utils.Joaat("ind_prop_firework_04") --//Cone
    elseif iType == 1 then
        return Utils.Joaat("ind_prop_firework_02") --//Box
    elseif iType == 2 then
        return Utils.Joaat("ind_prop_firework_03") --//Cylinder
    elseif iType == 3 then
        return Utils.Joaat("ind_prop_firework_01") --//Rocket
    end

    return Utils.Joaat("ind_prop_firework_01")
end

--/// PURPOSE:
--///    Gets the model name of a given firework type
local function GET_FIREWORK_TYPE_VFX_NAME(iType)
    if iType == 0 then
        return "scr_indep_firework_fountain"   --//Cone
    elseif iType == 1 then
        return "scr_indep_firework_shotburst"  --//Box
    elseif iType == 2 then
        return "scr_indep_firework_starburst"  --//Cylinder
    elseif iType == 3 then
        return "scr_indep_firework_trailburst" --//Rocket
    end

    return "scr_indep_firework_fountain"
end

--/// PURPOSE:
--///    Finds the next empty firework slot
local function FIND_UNALLOCATED_FIREWORK()
    for iTemp = 0, MAX_OWNED_FIREWORKS - 1 do

        if fireworkVars.fireworks[iTemp].bPlaced == false then
            return iTemp
        end
    end

    return -1
end

--/// PURPOSE:
--///    Creates and places a firework on the ground
local function PLAY_FIREWORK_ANIM()
    if GET_NO_OWNED_FIREWORK_TYPE_AND_COLOUR(fireworkData.iType, fireworkData.iColour) > 0 then

        if not IS_ENTITY_PLAYING_ANIM(PLAYER_PED_ID(), "anim@mp_fireworks", GET_FIREWORK_TYPE_ANIM_NAME(fireworkData.iType), 3) then

            if FIND_UNALLOCATED_FIREWORK() ~= -1 then
                TASK_PLAY_ANIM(PLAYER_PED_ID(), "anim@mp_fireworks", GET_FIREWORK_TYPE_ANIM_NAME(fireworkData.iType), 8.0, -8.0, -1, 1048576, 0.0, false, false, false) --//AF_HIDE_WEAPON
                fireworkVars.iFireworkLocalBitset = SET_BIT(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)
                fireworkVars.iFireworkLocalBitset = SET_BIT(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK)
            end
        end
    end
end

local function DESTROY_FIREWORK(fw, bDelete)
    bDelete = bDelete or false

    if DOES_ENTITY_EXIST(fw.obj) then
        if bDelete == false then
            local ptr = Memory.AllocInt()
            Memory.WriteInt(ptr, fw.obj)
            SET_OBJECT_AS_NO_LONGER_NEEDED(ptr)
            Memory.Free(ptr)
        else
            DELETE_NET_OBJECT(fw.obj)
        end
    end

    fireworkVars.vShockingEventPos = fw.vLocation
    fw.iType = 0
    fw.iColour = 0
    fw.iTimer = 0
    fw.bPlaced = false
    fw.vLocation = {x = 0.0, y = 0.0, z = 0.0}
end

local function PLACE_FIREWORK()

    --//Create
    if IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK) then

        if HAS_ANIM_EVENT_FIRED(PLAYER_PED_ID(), GET_HASH_KEY("CREATE_PROP")) then
            fireworkVars.iNewFirework = FIND_UNALLOCATED_FIREWORK()

            if fireworkVars.iNewFirework ~= -1 then
                fireworkVars.fireworks[fireworkVars.iNewFirework].iType = fireworkData.iType
                fireworkVars.fireworks[fireworkVars.iNewFirework].iColour = fireworkData.iColour
                fireworkVars.fireworks[fireworkVars.iNewFirework].iTimer = fireworkData.iTimer
                fireworkVars.fireworks[fireworkVars.iNewFirework].vLocation = fireworkData.vLocation
                fireworkVars.fireworks[fireworkVars.iNewFirework].bPlaced = true

                fireworkVars.fireworks[fireworkVars.iNewFirework].obj = CREATE_OBJECT(GET_FIREWORK_TYPE_MODEL_NAME(fireworkVars.fireworks[fireworkVars.iNewFirework].iType), fireworkData.vLocation.x, fireworkData.vLocation.y, fireworkData.vLocation.z, true, false, true)
                SET_ENTITY_INVINCIBLE(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, true)

                --//ATTACH_ENTITY_TO_ENTITY(..., GET_PED_BONE_INDEX(PLAYER_PED_ID(),BONETAG_R_HAND), vFireworkAttachOffset, vFireworkAttachRot, TRUE, TRUE)
                ATTACH_ENTITY_TO_ENTITY(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, PLAYER_PED_ID(), GET_PED_BONE_INDEX(PLAYER_PED_ID(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 2, true) --//BONETAG_PH_R_HAND

                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)
            else
                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK)
                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)
            end
        end

    --//Detach and Place on Ground
    elseif IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK) then

        if HAS_ANIM_EVENT_FIRED(PLAYER_PED_ID(), GET_HASH_KEY("RELEASE_PROP")) then

            if DOES_ENTITY_EXIST(fireworkVars.fireworks[fireworkVars.iNewFirework].obj) then
                DETACH_ENTITY(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, true, true)
                FREEZE_ENTITY_POSITION(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, true)
                SET_ENTITY_COLLISION(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, false, false)

                local vTempX, vTempY, vTempZ = GET_ENTITY_COORDS(fireworkVars.fireworks[fireworkVars.iNewFirework].obj, false)
                if fireworkVars.fireworks[fireworkVars.iNewFirework].iType == 3 then
                    vTempZ = vTempZ - 0.5
                else
                    vTempZ = vTempZ - 0.08
                end
                fireworkVars.fireworks[fireworkVars.iNewFirework].vLocation = {x = vTempX, y = vTempY, z = vTempZ}
                --//BROADCAST_CREATE_REMOTE_FIREWORK(iNewFirework, iType, vTemp, ALL_PLAYERS(FALSE))

                DECREMENT_FIREWORK_TYPE_QUANTITY(fireworkVars.fireworks[fireworkVars.iNewFirework].iType, fireworkVars.fireworks[fireworkVars.iNewFirework].iColour)
                fireworkVars.iNoPlacedFireworks = fireworkVars.iNoPlacedFireworks + 1

                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK)
            end
        end
    end

    --//Cleanup Firework if player is killed or made ragdoll
    if IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK) then

        if IS_PED_DEAD_OR_DYING(PLAYER_PED_ID(), true)
        or IS_PED_RAGDOLL(PLAYER_PED_ID())
        or IS_PED_RUNNING_RAGDOLL_TASK(PLAYER_PED_ID())
        or IS_PED_IN_MELEE_COMBAT(PLAYER_PED_ID())
        or (not IS_ENTITY_PLAYING_ANIM(PLAYER_PED_ID(), "anim@mp_fireworks", GET_FIREWORK_TYPE_ANIM_NAME(fireworkVars.fireworks[fireworkVars.iNewFirework].iType), 3) and not IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)) then
            DESTROY_FIREWORK(fireworkVars.fireworks[fireworkVars.iNewFirework], true)
            fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK)
            fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)
        end
    end
end

local function SORT_FIREWORKS_BY_TIMER()
    local bSwapped = true

    if fireworkVars.iNoPlacedFireworks > 1 then

        while bSwapped do

            for iCount = 1, fireworkVars.iNoPlacedFireworks - 1 do
                bSwapped = false

                if fireworkVars.fireworks[iCount - 1].bPlaced and fireworkVars.fireworks[iCount].bPlaced then

                    if fireworkVars.fireworks[iCount - 1].iTimer > fireworkVars.fireworks[iCount].iTimer then
                        bSwapped = true
                        local iTemp = fireworkVars.fireworks[iCount]
                        fireworkVars.fireworks[iCount] = fireworkVars.fireworks[iCount - 1]
                        fireworkVars.fireworks[iCount - 1] = iTemp
                    end
                end
            end
        end
    end
end

local function GET_FIREWORK_CLEANUP_TIME(iType)
    if iType == 0 then
        return 8000 --//Cone
    elseif iType == 1 then
        return 3500 --//Box
    elseif iType == 2 then
        return 3000 --//Cylinder
    elseif iType == 3 then
        return 1500 --//Rocket
    end

    return 4000
end

--//PURPOSE: Checks the height of the Rocket and then cleans it up. Safety check of a timer.
local function PROCESS_ROCKET_CLEANUP(fw)
    if fireworkVars.iRocketCleanupBitSet ~= 0 then

        if IS_BIT_SET(fireworkVars.iRocketCleanupBitSet, fireworkVars.iRocketToCheck) then

            if fw[fireworkVars.iRocketToCheck].iType == 3 then
                local x, y, z = GET_ENTITY_COORDS(fw[fireworkVars.iRocketToCheck].obj, false)
                local fDistance = VDIST(fw[fireworkVars.iRocketToCheck].vRocketStart, {x = x, y = y, z = z})

                if fDistance > 21.0
                or HAS_NET_TIMER_EXPIRED(fireworkVars.iRocketCleanupTime[fireworkVars.iRocketToCheck], GET_FIREWORK_CLEANUP_TIME(fw[fireworkVars.iRocketToCheck].iType)) then
                    DESTROY_FIREWORK(fw[fireworkVars.iRocketToCheck], true)
                    fireworkVars.iRocketCleanupBitSet = CLEAR_BIT(fireworkVars.iRocketCleanupBitSet, fireworkVars.iRocketToCheck)
                    RESET_NET_TIMER(fireworkVars.iRocketCleanupTime[fireworkVars.iRocketToCheck])
                end
            else

                if HAS_NET_TIMER_EXPIRED(fireworkVars.iRocketCleanupTime[fireworkVars.iRocketToCheck], GET_FIREWORK_CLEANUP_TIME(fw[fireworkVars.iRocketToCheck].iType)) then
                    DESTROY_FIREWORK(fw[fireworkVars.iRocketToCheck], true)
                    fireworkVars.iRocketCleanupBitSet = CLEAR_BIT(fireworkVars.iRocketCleanupBitSet, fireworkVars.iRocketToCheck)
                    RESET_NET_TIMER(fireworkVars.iRocketCleanupTime[fireworkVars.iRocketToCheck])
                end
            end
        end

        fireworkVars.iRocketToCheck = fireworkVars.iRocketToCheck + 1
        if fireworkVars.iRocketToCheck > MAX_OWNED_FIREWORKS then
            fireworkVars.iRocketToCheck = 0
        end
    end
end

--//PURPOSE: Creates a shocking event when the Fireworks have been triggered
local function PROCESS_SHOCKING_EVENT()
    if IS_BIT_SET(fireworkVars.iFireworkLocalBitset, DO_SHOCKING_EVENT) then

        if fireworkVars.iShockingEvent == 0
        and not IS_VECTOR_ZERO(fireworkVars.vShockingEventPos) then
            fireworkVars.iShockingEvent = ADD_SHOCKING_EVENT_AT_POSITION(93, fireworkVars.vShockingEventPos.x, fireworkVars.vShockingEventPos.y, fireworkVars.vShockingEventPos.z, 60000) --//EVENT_SHOCKING_PARACHUTER_OVERHEAD

            if fireworkVars.iShockingEvent > 0 then
                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, DO_SHOCKING_EVENT)
            end
        end
    end
end

local function DRAW_TIMER()
    if (fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer - GET_NET_TIMER_DIFFERENCE_WITH_CURRENT_TIME(fireworkVars.launchTimer)) >= 0 then
        DRAW_GENERIC_TIMER((fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer - GET_NET_TIMER_DIFFERENCE_WITH_CURRENT_TIME(fireworkVars.launchTimer)), 0.5, 0.85)
    else
        DRAW_GENERIC_TIMER(0, 0.5, 0.85)
    end
end

local function START_FIREWORK_COUNTDOWN()
    SORT_FIREWORKS_BY_TIMER()
    fireworkVars.iNextFirework = 0
    fireworkVars.iElapsedTime = fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer
    fireworkVars.iFireworkLocalBitset = SET_BIT(fireworkVars.iFireworkLocalBitset, DRAW_LAUNCH_TIMER)
    RESET_NET_TIMER(fireworkVars.launchTimer)
    fireworkVars.iShockingEvent = 0
end

local function GET_FIREWORK_COLOUR(iColour)
    if iColour == 0 then
        return 1.0, 0.1, 0.1 --//RED
    elseif iColour == 1 then
        return 1.0, 1.0, 1.0 --//WHITE
    elseif iColour == 2 then
        return 0.1, 0.1, 1.0 --//BLUE
    end

    return 1.0, 1.0, 1.0
end

local function PLAY_FIREWORK(fw, iFirework)
    USE_PARTICLE_FX_ASSET("scr_indep_fireworks")
    local fR, fG, fB = GET_FIREWORK_COLOUR(fw.iColour)
    SET_PARTICLE_FX_NON_LOOPED_COLOUR(fR, fG, fB)
    local x, y, z = GET_ENTITY_COORDS(fw.obj, false)
    START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(GET_FIREWORK_TYPE_VFX_NAME(fw.iType), x, y, z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    fireworkVars.iFireworkLocalBitset = SET_BIT(fireworkVars.iFireworkLocalBitset, DO_SHOCKING_EVENT)

    if fw.iType == 3 then
        fw.vRocketStart = {x = x, y = y, z = z}
        SET_ENTITY_COLLISION(fw.obj, true, true)
        FREEZE_ENTITY_POSITION(fw.obj, false)
        SET_ENTITY_VELOCITY(fw.obj, 0.0, 0.0, 70.0) --//vFireworkAttachOffset

        fireworkVars.iRocketCleanupBitSet = SET_BIT(fireworkVars.iRocketCleanupBitSet, iFirework)
    else
        fireworkVars.iRocketCleanupBitSet = SET_BIT(fireworkVars.iRocketCleanupBitSet, iFirework) --//DESTROY_FIREWORK(fw, TRUE)
    end
end

--/// PURPOSE:
--///    Initialises the fireworks
local function INIT_FIREWORKS()
    REQUEST_MODEL(GET_FIREWORK_TYPE_MODEL_NAME(3)) --//IND_PROP_FIREWORK_01
    REQUEST_MODEL(GET_FIREWORK_TYPE_MODEL_NAME(1)) --//IND_PROP_FIREWORK_02
    REQUEST_MODEL(GET_FIREWORK_TYPE_MODEL_NAME(2)) --//IND_PROP_FIREWORK_03
    REQUEST_MODEL(GET_FIREWORK_TYPE_MODEL_NAME(0)) --//IND_PROP_FIREWORK_04
    REQUEST_ANIM_DICT("anim@mp_fireworks")
    REQUEST_NAMED_PTFX_ASSET("scr_indep_fireworks")

    if not HAS_MODEL_LOADED(GET_FIREWORK_TYPE_MODEL_NAME(3)) then
        return false
    end

    if not HAS_MODEL_LOADED(GET_FIREWORK_TYPE_MODEL_NAME(1)) then
        return false
    end

    if not HAS_MODEL_LOADED(GET_FIREWORK_TYPE_MODEL_NAME(2)) then
        return false
    end

    if not HAS_MODEL_LOADED(GET_FIREWORK_TYPE_MODEL_NAME(0)) then
        return false
    end

    if not HAS_ANIM_DICT_LOADED("anim@mp_fireworks") then
        return false
    end

    if not HAS_NAMED_PTFX_ASSET_LOADED("scr_indep_fireworks") then
        return false
    end

    return true
end

--/// PURPOSE:
--///    Performs some cleanup when menu is closed - does not end script
local function LOCAL_CLEANUP_FIREWORKS()
    SET_MODEL_AS_NO_LONGER_NEEDED(Utils.Joaat("prop_flare_01"))
    SET_MODEL_AS_NO_LONGER_NEEDED(GET_FIREWORK_TYPE_MODEL_NAME(3)) --//IND_PROP_FIREWORK_01
    SET_MODEL_AS_NO_LONGER_NEEDED(GET_FIREWORK_TYPE_MODEL_NAME(1)) --//IND_PROP_FIREWORK_02
    SET_MODEL_AS_NO_LONGER_NEEDED(GET_FIREWORK_TYPE_MODEL_NAME(2)) --//IND_PROP_FIREWORK_03
    SET_MODEL_AS_NO_LONGER_NEEDED(GET_FIREWORK_TYPE_MODEL_NAME(0)) --//IND_PROP_FIREWORK_04
    --//REMOVE_NAMED_PTFX_ASSET("scr_indep_fireworks")
end

local function GET_FIREWORK_DIMENSIONS(iType, bGetUpper)
    bGetUpper = bGetUpper or false

    if bGetUpper == false then
        if iType == 0 then
            return {x = 0.5, y = 0.25, z = 12.0}  --//Cone
        elseif iType == 1 then
            return {x = 0.5, y = 0.5, z = 10.0}   --//Box
        elseif iType == 2 then
            return {x = 0.25, y = 0.25, z = 15.0} --//Cylinder
        elseif iType == 3 then
            return {x = 0.25, y = 0.25, z = 20.0} --//Rocket
        end
    else
        if iType == 0 then
            return {x = 6.0, y = 6.0, z = 14.0}   --//Cone
        elseif iType == 1 then
            return {x = 15.0, y = 15.0, z = 16.0} --//Box
        elseif iType == 2 then
            return {x = 12.0, y = 12.0, z = 22.0} --//Cylinder
        elseif iType == 3 then
            return {x = 15.0, y = 15.0, z = 14.0} --//Rocket
        end
    end

    return {x = 0.25, y = 0.25, z = 15.0}
end

--//PURPOSE: Controls the Creation and Cleanup of Remote Player Firework Props.
local function PROCESS_REMOTE_FIREWORKS()
    --// Managed props created from the BROADCAST_CREATE_REMOTE_FIREWORK script events
    --// (MPGlobalsFW). Only the freemode script can send those, so a standalone build
    --// networks the local props instead and this routine has nothing to process.
    if MPGlobalsFW == nil then
        return
    end
end

--/// PURPOSE:
--///    Maintain the placement and current state of fireworks
local function MAINTAIN_FIREWORKS()

    PLACE_FIREWORK()

    if fireworkData.bDoShapeTest then

        if fireworkVars.iShapeTestStage == ST_INIT then
            local vModelMinPtr = AllocScrVector()
            local vModelMaxPtr = AllocScrVector()
            GET_MODEL_DIMENSIONS(GET_FIREWORK_TYPE_MODEL_NAME(fireworkData.iType), vModelMinPtr, vModelMaxPtr)
            local xMin, yMin, zMin = ReadScrVector(vModelMinPtr)
            local xMax, yMax, zMax = ReadScrVector(vModelMaxPtr)
            Memory.Free(vModelMinPtr)
            Memory.Free(vModelMaxPtr)

            local vDim = {x = xMax - xMin, y = yMax - yMin, z = zMax - zMin}

            local vTypeDim = GET_FIREWORK_DIMENSIONS(fireworkData.iType)
            vDim.x = vDim.x + vTypeDim.x
            vDim.y = vDim.y + vTypeDim.y
            vDim.z = vDim.z + vTypeDim.z
            local vDimUpper = GET_FIREWORK_DIMENSIONS(fireworkData.iType, true)

            local vFireworkLoc = {}
            if fireworkData.iType ~= 3 then
                vFireworkLoc.x, vFireworkLoc.y, vFireworkLoc.z = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER_PED_ID(), 0.0, 0.5, 0.0)
            else
                vFireworkLoc.x, vFireworkLoc.y, vFireworkLoc.z = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER_PED_ID(), -0.08, 0.6, 0.0)
            end

            local fGroundZPtr = AllocScrValue()
            GET_GROUND_Z_FOR_3D_COORD(vFireworkLoc.x, vFireworkLoc.y, vFireworkLoc.z, fGroundZPtr, false, false)
            local fGroundZ = Memory.ReadFloat(fGroundZPtr)
            Memory.Free(fGroundZPtr)

            vFireworkLoc.z = fGroundZ
            fireworkData.vLocation = {x = vFireworkLoc.x, y = vFireworkLoc.y, z = vFireworkLoc.z}
            vFireworkLoc.z = vFireworkLoc.z + (vDim.z / 2.0) + 0.1 --// So shapetest doesn't intersect ground

            local vFireworkUpper = {x = vFireworkLoc.x, y = vFireworkLoc.y, z = fGroundZ + vDim.z}
            vFireworkUpper.z = vFireworkUpper.z + (vDimUpper.z / 2.0)

            --//Check if Fireworks model is already there
            for i = 0, NO_FIREWORK_TYPES - 1 do
                local obTemp = GET_CLOSEST_OBJECT_OF_TYPE(fireworkData.vLocation.x, fireworkData.vLocation.y, fireworkData.vLocation.z, 0.2, GET_FIREWORK_TYPE_MODEL_NAME(i), false, false, true)

                if obTemp ~= 0 then
                    fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
                end
            end

            --//Do Shape Test
            fireworkVars.sti_Firework = START_SHAPE_TEST_BOX(vFireworkLoc.x, vFireworkLoc.y, vFireworkLoc.z, vDim.x, vDim.y, vDim.z, 0.0, 0.0, -0.1, 2, 511, PLAYER_PED_ID(), 4) --//EULER_YXZ, SCRIPT_INCLUDE_ALL
            fireworkVars.sti_FireworkUpper = START_SHAPE_TEST_BOX(vFireworkUpper.x, vFireworkUpper.y, vFireworkUpper.z, vDimUpper.x, vDimUpper.y, vDimUpper.z, 0.0, 0.0, -0.1, 2, 511, PLAYER_PED_ID(), 4)

            fireworkVars.iShapeTestStage = ST_WAITING_RESULT

        elseif fireworkVars.iShapeTestStage == ST_WAITING_RESULT then
            local iHitSomethingPtr = AllocScrValue()
            local vTemp1Ptr = AllocScrVector()
            local vTemp2Ptr = AllocScrVector()
            local hitEntityPtr = AllocScrValue()

            if GET_SHAPE_TEST_RESULT(fireworkVars.sti_Firework, iHitSomethingPtr, vTemp1Ptr, vTemp2Ptr, hitEntityPtr) == 2 then --//SHAPETEST_STATUS_RESULTS_READY
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestResultsDone)
                if Memory.ReadInt(iHitSomethingPtr) ~= 0 then
                    fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
                end
            elseif GET_SHAPE_TEST_RESULT(fireworkVars.sti_Firework, iHitSomethingPtr, vTemp1Ptr, vTemp2Ptr, hitEntityPtr) == 0 then --//SHAPETEST_STATUS_NONEXISTENT guard so the test cannot soft-lock
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestResultsDone)
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
            end

            if GET_SHAPE_TEST_RESULT(fireworkVars.sti_FireworkUpper, iHitSomethingPtr, vTemp1Ptr, vTemp2Ptr, hitEntityPtr) == 2 then --//SHAPETEST_STATUS_RESULTS_READY
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestUpperResultsDone)
                if Memory.ReadInt(iHitSomethingPtr) ~= 0 then
                    fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
                end
            elseif GET_SHAPE_TEST_RESULT(fireworkVars.sti_FireworkUpper, iHitSomethingPtr, vTemp1Ptr, vTemp2Ptr, hitEntityPtr) == 0 then
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestUpperResultsDone)
                fireworkVars.iFireworkBitSet = SET_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
            end

            Memory.Free(iHitSomethingPtr)
            Memory.Free(vTemp1Ptr)
            Memory.Free(vTemp2Ptr)
            Memory.Free(hitEntityPtr)

            if IS_BIT_SET(fireworkVars.iFireworkBitSet, biShapeTestResultsDone)
            and IS_BIT_SET(fireworkVars.iFireworkBitSet, biShapeTestUpperResultsDone) then

                if not IS_BIT_SET(fireworkVars.iFireworkBitSet, biShapeTestFailed) then
                    --//SAFE - PLACING FIREWORK
                    PLAY_FIREWORK_ANIM()
                else
                    --//NOT SAFE - ENDING TEST
                    fireworkVars.iFireworkLocalBitset = SET_BIT(fireworkVars.iFireworkLocalBitset, NOT_SAFE_TO_PLACE)
                    BEGIN_TEXT_COMMAND_DISPLAY_HELP("STRING")
                    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME("You can't place a Firework here.")
                    END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
                end

                fireworkData.bDoShapeTest = false
                fireworkVars.iShapeTestStage = ST_INIT
                fireworkVars.iFireworkBitSet = CLEAR_BIT(fireworkVars.iFireworkBitSet, biShapeTestResultsDone)
                fireworkVars.iFireworkBitSet = CLEAR_BIT(fireworkVars.iFireworkBitSet, biShapeTestUpperResultsDone)
                fireworkVars.iFireworkBitSet = CLEAR_BIT(fireworkVars.iFireworkBitSet, biShapeTestFailed)
            end
        end
    end

    if IS_BIT_SET(fireworkVars.iFireworkLocalBitset, DRAW_LAUNCH_TIMER) then

        if HAS_NET_TIMER_EXPIRED(fireworkVars.launchTimer, fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer) then
            PLAY_FIREWORK(fireworkVars.fireworks[fireworkVars.iNextFirework], fireworkVars.iNextFirework)
            fireworkVars.iNextFirework = fireworkVars.iNextFirework + 1

            if fireworkVars.iNextFirework ~= fireworkVars.iNoPlacedFireworks
            and fireworkVars.iNextFirework < MAX_OWNED_FIREWORKS then
                fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer = fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer - fireworkVars.iElapsedTime
                fireworkVars.iElapsedTime = fireworkVars.iElapsedTime + fireworkVars.fireworks[fireworkVars.iNextFirework].iTimer
                RESET_NET_TIMER(fireworkVars.launchTimer)
            else
                REMOVE_NAMED_PTFX_ASSET("scr_indep_fireworks")
                fireworkVars.iNextFirework = 0
                fireworkVars.iNoPlacedFireworks = 0
                fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, DRAW_LAUNCH_TIMER)
                --//BROADCAST_REMOVE_PLAYERS_REMOTE_FIREWORKS(ALL_PLAYERS(FALSE))
            end
        end

        DRAW_TIMER()
    end

    PROCESS_ROCKET_CLEANUP(fireworkVars.fireworks)
    PROCESS_SHOCKING_EVENT()
    PROCESS_REMOTE_FIREWORKS()
end

------------------------------------------- Interaction Menu -------------------------------------------

local IM_X = 0.05
local IM_Y = 0.05
local IM_W = 0.225
local IM_PIXEL = 0.00138888
local IM_TEXT_SCALE = 0.35
local IM_TEXT_PAD_X = 0.0046875
local IM_TEXT_PAD_Y = 0.00277776
local IM_TITLE_PAD_X = 0.00390625
local IM_TITLE_PAD_Y = 0.00416664
local IM_ROW_H = 0.034722
local IM_SPACER_H = 0.00277776
local IM_BANNER_H = 0.090
local IM_ARROW_W = 0.013
local IM_ARROW_H = 0.023

local imColorBlue = {45, 110, 185}
local imColorWhite = {240, 240, 240}
local imColorBlack = {0, 0, 0}

local function imText(str, x, y, col, alpha, just, wrapStart, wrapEnd, font, scaleX, scaleY, leading)
    SET_TEXT_FONT(font or 0)
    SET_TEXT_SCALE(scaleX or 0.0, scaleY or IM_TEXT_SCALE)
    SET_TEXT_COLOUR(col[1], col[2], col[3], alpha)
    SET_TEXT_JUSTIFICATION(just)
    SET_TEXT_WRAP(wrapStart, wrapEnd)
    SET_TEXT_CENTRE(false)
    SET_TEXT_DROPSHADOW(0, 0, 0, 0, 0)
    SET_TEXT_EDGE(0, 0, 0, 0, 0)

    if leading ~= nil then
        SET_TEXT_LEADING(leading)
    end

    BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str)
    END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

local function imTextWidth(str)
    SET_TEXT_FONT(0)
    SET_TEXT_SCALE(0.0, IM_TEXT_SCALE)
    BEGIN_TEXT_COMMAND_GET_WIDTH("STRING")
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str)
    return END_TEXT_COMMAND_GET_WIDTH(true)
end

local fireworksMenuOpen = false
local menuIndex = 1
local menuType = 3
local menuColour = 0
local menuFuseTime = 3

local menuRows = {"Type", "Colour", "Fuse Time", "Place Firework", "Light Fuses"}
local typeNames = {[0] = "Cone", [1] = "Box", [2] = "Cylinder", [3] = "Rocket"}
local colourNames = {[0] = "Red", [1] = "White", [2] = "Blue"}
local rowDescriptions = {
    {"Choose which firework you will place on the ground.", 2},
    {"Choose the colour of your firework.", 1},
    {"Set how long after lighting the fuses this firework takes to go off.", 2},
    {"Place the firework on the ground in front of you.", 2},
    {"Set off every placed firework. Get to a safe distance!", 2}
}

local function menuAdjust(direction)
    if menuIndex == 1 then
        menuType = (menuType + direction) % NO_FIREWORK_TYPES
    elseif menuIndex == 2 then
        menuColour = (menuColour + direction) % NO_FIREWORK_COLOURS
    elseif menuIndex == 3 then
        menuFuseTime = menuFuseTime + direction
        if menuFuseTime < 1 then
            menuFuseTime = MAX_FIREWORK_TIMER
        elseif menuFuseTime > MAX_FIREWORK_TIMER then
            menuFuseTime = 1
        end
    end
end

local function menuPlaceFirework()
    fireworkVars.iFireworkLocalBitset = CLEAR_BIT(fireworkVars.iFireworkLocalBitset, NOT_SAFE_TO_PLACE)

    if fireworkData.bDoShapeTest
    or IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_CREATE_FIREWORK)
    or IS_BIT_SET(fireworkVars.iFireworkLocalBitset, CHECK_DETACH_FIREWORK)
    or IS_BIT_SET(fireworkVars.iFireworkLocalBitset, DRAW_LAUNCH_TIMER)
    or FIND_UNALLOCATED_FIREWORK() == -1
    or IS_PED_IN_ANY_VEHICLE(PLAYER_PED_ID(), false) then
        return
    end

    INIT_FIREWORKS()

    fireworkData.iType = menuType
    fireworkData.iColour = menuColour
    fireworkData.iTimer = menuFuseTime * 1000
    fireworkData.bDoShapeTest = true
end

local function menuLightFuses()
    if IS_BIT_SET(fireworkVars.iFireworkLocalBitset, DRAW_LAUNCH_TIMER)
    or fireworkVars.iNoPlacedFireworks < 1 then
        return
    end

    START_FIREWORK_COUNTDOWN()
end

local function menuRowValue(row)
    if row == 1 then
        return typeNames[menuType]
    elseif row == 2 then
        return colourNames[menuColour]
    elseif row == 3 then
        return string.format("%ds", menuFuseTime)
    elseif row == 5 then
        return string.format("%d", fireworkVars.iNoPlacedFireworks)
    end

    return nil
end

local function drawInteractionMenu()
    local centreX = IM_X + IM_W / 2
    local rightEdge = IM_X + IM_W - IM_TEXT_PAD_X

    REQUEST_STREAMED_TEXTURE_DICT("CommonMenu", false)
    local txdReady = HAS_STREAMED_TEXTURE_DICT_LOADED("CommonMenu")

    local bannerTop = IM_Y

    if txdReady then
        DRAW_SPRITE("CommonMenu", "Interaction_bgd", centreX, bannerTop + IM_BANNER_H / 2, IM_W + 0.0005, IM_BANNER_H, 0.0, 255, 255, 255, 255, false)
    end
    imText(GET_PLAYER_NAME(PLAYER_ID()), IM_X + IM_TITLE_PAD_X, bannerTop + 0.0203, imColorWhite, 255, 1, IM_X, rightEdge, 4, 0.5, 0.75)

    local titleY = bannerTop + IM_BANNER_H
    DRAW_RECT(centreX, titleY + IM_ROW_H / 2, IM_W, IM_ROW_H, 0, 0, 0, 255, false)
    imText("FIREWORKS", IM_X + IM_TITLE_PAD_X, titleY + IM_TITLE_PAD_Y, imColorBlue, 255, 1, IM_X + IM_TEXT_PAD_X, rightEdge)
    imText(string.format("%d/%d", menuIndex, #menuRows), 0.0, titleY + IM_TITLE_PAD_Y, imColorBlue, 255, 2, IM_X, rightEdge)

    local bodyTop = titleY + IM_ROW_H
    local bodyH = #menuRows * IM_ROW_H

    if txdReady then
        DRAW_SPRITE("CommonMenu", "Gradient_Bgd", centreX, bodyTop + bodyH / 2 - IM_PIXEL, IM_W, bodyH, 0.0, 255, 255, 255, 190, false)
    end

    for row = 1, #menuRows do
        local rowTop = bodyTop + (row - 1) * IM_ROW_H
        local textY = rowTop + IM_TEXT_PAD_Y
        local selected = row == menuIndex

        if selected and txdReady then
            DRAW_SPRITE("CommonMenu", "Gradient_Nav", centreX, rowTop + IM_ROW_H / 2, IM_W, IM_ROW_H, 0.0, 240, 240, 240, 255, false)
        end

        local col = imColorWhite
        local alpha = 255
        if selected then
            col = imColorBlack
            alpha = 204
        end

        imText(menuRows[row], IM_X + IM_TEXT_PAD_X, textY, col, alpha, 1, 0.0, 1.0)

        local value = menuRowValue(row)
        if value ~= nil then
            if selected and row <= 3 then
                local valueW = imTextWidth(value)
                local valueEnd = rightEdge - IM_ARROW_W
                imText(value, 0.0, textY, col, alpha, 2, IM_X, valueEnd)

                if txdReady then
                    DRAW_SPRITE("CommonMenu", "arrowright", rightEdge - IM_ARROW_W * 0.5, rowTop + IM_ROW_H * 0.5, IM_ARROW_W, IM_ARROW_H, 0.0, 0, 0, 0, 204, false)
                    DRAW_SPRITE("CommonMenu", "arrowleft", valueEnd - valueW - IM_ARROW_W * 0.5, rowTop + IM_ROW_H * 0.5, IM_ARROW_W, IM_ARROW_H, 0.0, 0, 0, 0, 204, false)
                end
            else
                imText(value, 0.0, textY, col, alpha, 2, IM_X, rightEdge)
            end
        end
    end

    local footerTop = bodyTop + bodyH
    DRAW_RECT(centreX, footerTop + IM_ROW_H / 2, IM_W, IM_ROW_H, 0, 0, 0, 180, false)

    if txdReady then
        DRAW_SPRITE("CommonMenu", "shop_arrows_upANDdown", centreX, footerTop + IM_ROW_H / 2, 0.024, 0.042, 0.0, 240, 240, 240, 255, false)
    end

    local desc = rowDescriptions[menuIndex]
    local descH = desc[2] * 0.0225 + 18 * IM_PIXEL
    local descTop = footerTop + IM_ROW_H + IM_SPACER_H

    if txdReady then
        DRAW_SPRITE("CommonMenu", "Gradient_Bgd", centreX, descTop + descH / 2, IM_W, descH, 0.0, 255, 255, 255, 230, false)
    end
    imText(desc[1], IM_X + IM_TEXT_PAD_X, descTop + 8 * IM_PIXEL, imColorWhite, 255, 1, IM_X + IM_TEXT_PAD_X, rightEdge, 0, 0.0, IM_TEXT_SCALE, 2)
end

------------------------------------------- Feature -------------------------------------------

local menuFeatureEnabled = false

FeatureMgr.AddFeature(
    Utils.Joaat("OldGenFireworksMenu"),
    "Enable Old Gen Fireworks Menu",
    eFeatureType.Toggle,
    "Bring back the old GTA:O firework menu old gen consoles had. Press G on your keyboard or left d-pad in your controller to open the menu.",
    function(feature)
        menuFeatureEnabled = feature:IsToggled()
    end)

ClickGUI.AddTab("Fireworks Menu", function()
    if ImGui.BeginTable("FireworksTable", 2, ImGuiTableFlags.SizingStretchSame) then
        ImGui.TableNextRow()

        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Fireworks") then
            ClickGUI.RenderFeature(Utils.Joaat("OldGenFireworksMenu"))
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.EndTable()
    end
end)

Script.RegisterLooped(function()

    if not menuFeatureEnabled then
        return
    end

    MAINTAIN_FIREWORKS()

    if not fireworksMenuOpen then

        if IS_CONTROL_JUST_PRESSED(0, INPUT_DETONATE) then
            fireworksMenuOpen = true
            PLAY_SOUND_FRONTEND(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        end

        return
    end

    DISABLE_CONTROL_ACTION(0, INPUT_DETONATE, true)

    if IS_DISABLED_CONTROL_JUST_PRESSED(0, INPUT_DETONATE) then
        fireworksMenuOpen = false
        PLAY_SOUND_FRONTEND(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        return
    end

    DISABLE_CONTROL_ACTION(0, INPUT_PHONE, true)

    if IS_CONTROL_JUST_PRESSED(0, INPUT_CELLPHONE_UP) then
        menuIndex = menuIndex - 1
        if menuIndex < 1 then
            menuIndex = #menuRows
        end
        PLAY_SOUND_FRONTEND(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    if IS_CONTROL_JUST_PRESSED(0, INPUT_CELLPHONE_DOWN) then
        menuIndex = menuIndex + 1
        if menuIndex > #menuRows then
            menuIndex = 1
        end
        PLAY_SOUND_FRONTEND(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    if IS_CONTROL_JUST_PRESSED(0, INPUT_CELLPHONE_LEFT) then
        menuAdjust(-1)
        PLAY_SOUND_FRONTEND(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    if IS_CONTROL_JUST_PRESSED(0, INPUT_CELLPHONE_RIGHT) then
        menuAdjust(1)
        PLAY_SOUND_FRONTEND(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end

    if IS_CONTROL_JUST_PRESSED(0, INPUT_FRONTEND_ACCEPT) then
        if menuIndex == 4 then
            menuPlaceFirework()
            PLAY_SOUND_FRONTEND(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        elseif menuIndex == 5 then
            menuLightFuses()
            PLAY_SOUND_FRONTEND(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        end
    end

    drawInteractionMenu()

end)
