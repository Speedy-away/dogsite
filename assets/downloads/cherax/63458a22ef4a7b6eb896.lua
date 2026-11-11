--[[
    ═══════════════════════════════════════════════════════════════════════════════════
    FLYING CARS SA v1.0.1 ALPHA
    ═══════════════════════════════════════════════════════════════════════════════════

    san andreas-inspired flying-car physics for cherax.

    description:
    - turns supported road vehicles into speed-based aircraft
    - keeps gravity enabled so stalls, dives, crashes, and recoveries remain natural
    - supports vehicle-nose and gameplay-camera guidance
    - includes smooth numpad flight controls, gradual takeoff, and soft touchdown control
    - records distance, height, flips, rotation, and cleanly landed top scores
    - saves user keybinds and settings automatically
    - creates no money, rp, transactions, or gta online rewards

    default controls:
    - numpad 2: enable flying cars / nose up while enabled
    - numpad 8: nose down
    - numpad 4 / 6: bank and turn left / right
    - left shift: toggle vehicle-nose / gameplay-camera guidance
    - accelerate: thrust
    - brake: aerodynamic resistance

    storage:
    - cherax\lua\Flying_Cars_SA\config.cfg
    - cherax\lua\Flying_Cars_SA\high_scores.lua
    - cherax\lua\Flying_Cars_SA\high_scores.log

    notes:
    - normal gameplay physics remain untouched while the feature is disabled
    - bad landings are disqualified and never saved to the leaderboard
    - optional logo downloading and corrupt score-file loading are the only protected calls
    - normal runtime paths use direct, guarded calls for lower overhead

    changelog:
    - v1.0.1 alpha - production source cleanup: lower-case section/comment style, snake-case helpers, cached native invokers, direct hot-loop input/render paths, reduced protected calls, simplified persistence, and removed redundant compatibility wrappers.
    - v1.0.0 alpha - initial public alpha with aircraft-style car flight, camera guidance, configurable keybinds, persistent top scores, landing validation, and polished clickgui presentation.

    developed by: Public_Urinal
    project: FlyingCarsSA
    credits: built with assistance from OpenAI ChatGPT.
    total hours developing: ~5

    ═══════════════════════════════════════════════════════════════════════════════════
]]

local script_name = "Flying Cars SA"
local script_version = "1.0.1 Alpha"
local joaat = Utils.Joaat
local invoke_bool = Natives.InvokeBool
local invoke_float = Natives.InvokeFloat
local invoke_int = Natives.InvokeInt
local invoke_v3 = Natives.InvokeV3
local invoke_void = Natives.InvokeVoid

if ClickGUI and ClickGUI.RemoveTab then
    ClickGUI.RemoveTab(script_name)
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- natives
-- ═══════════════════════════════════════════════════════════════════════════════════

local native_hash = {
    PLAYER_PED_ID                         = 0xD80958FC74E988A6,
    IS_PED_IN_ANY_VEHICLE                 = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN                 = 0x9A9112A0FE9A4713,
    GET_PED_IN_VEHICLE_SEAT               = 0xBB40DD2270B65366,
    DOES_ENTITY_EXIST                     = 0x7239B21A38F536BA,
    GET_ENTITY_COORDS                     = 0x3FEF770D40960D5A,
    GET_ENTITY_MODEL                      = 0x9F47B058362C84B5,
    GET_MODEL_DIMENSIONS                  = 0x03E8D3D5F549087A,
    GET_ENTITY_SPEED                      = 0xD5037BA82E12416F,
    GET_ENTITY_SPEED_VECTOR               = 0x9A8D700A51CB7B0D,
    GET_ENTITY_VELOCITY                   = 0x4805D2B1D8CF94A9,
    GET_ENTITY_FORWARD_VECTOR             = 0x0A794A5A57F8DF91,
    SET_ENTITY_VELOCITY                   = 0x1C99BB7B6E96D16F,
    GET_ENTITY_HEADING                    = 0xE83D4F9BA2A38914,
    GET_ENTITY_PITCH                      = 0xD45DC2893621E1FE,
    GET_ENTITY_ROLL                       = 0x831E0242595560DF,
    GET_ENTITY_UPRIGHT_VALUE              = 0x95EED5A694951F9F,
    GET_ENTITY_HEIGHT_ABOVE_GROUND        = 0x1DD55701034110E5,
    IS_ENTITY_IN_AIR                      = 0x886E37EC497200B6,
    IS_ENTITY_UPSIDEDOWN                  = 0x1DBD58820FA61D71,
    HAS_ENTITY_COLLIDED_WITH_ANYTHING     = 0x8BAD02F0368D9E14,
    APPLY_FORCE_TO_ENTITY                 = 0xC5F68BE9613E2D18,
    APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS  = 0x18FF00FC7EFF559E,
    SET_VEHICLE_GRAVITY                   = 0x89F149B6131E57DA,
    IS_VEHICLE_ON_ALL_WHEELS              = 0xB104CD1BABF302E2,
    GET_VEHICLE_CLASS                     = 0x29439776AAA00A62,
    GET_VEHICLE_ESTIMATED_MAX_SPEED       = 0x53AF99BAA671CA47,
    GET_CONTROL_NORMAL                    = 0xEC3C9B8D5327B563,
    IS_CONTROL_PRESSED                    = 0xF3A21BCD95725A4A,
    GET_GAME_TIMER                        = 0x9CD27B0045628463,
    GET_FRAME_TIME                        = 0x15C40837039FFAF7,
    GET_GAMEPLAY_CAM_ROT                  = 0x837765A25378F0BB,
    SHAKE_GAMEPLAY_CAM                    = 0xFD55E49555E017CF,
    IS_GAMEPLAY_CAM_SHAKING               = 0x016C090630DF1F89,
    SET_GAMEPLAY_CAM_SHAKE_AMPLITUDE      = 0xA87E00932DB4D85D,
    STOP_GAMEPLAY_CAM_SHAKING             = 0x0EF93E9F3D08C178,
    SET_TEXT_FONT                         = 0x66E0276CC5F6B9DA,
    SET_TEXT_SCALE                        = 0x07C837F9A01C34C9,
    SET_TEXT_COLOUR                       = 0xBE6B23FFA53FB442,
    SET_TEXT_CENTRE                       = 0xC02F4DBFB51D988B,
    SET_TEXT_OUTLINE                      = 0x2513DFB0FB8400FE,
    BEGIN_TEXT_COMMAND_DISPLAY_TEXT       = 0x25FBB336DF1804CB,
    ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME = 0x6C188BE134E074AA,
    END_TEXT_COMMAND_DISPLAY_TEXT         = 0xCD015E5BB0D96A57,
}

local control_id = {
    VEH_MOVE_LR          = 59,
    VEH_ACCELERATE       = 71,
    VEH_BRAKE            = 72,
    VEH_HANDBRAKE        = 76,
    VEH_FLY_THROTTLE_UP  = 87,
    VEH_FLY_THROTTLE_DN  = 88,
    VEH_FLY_YAW_LEFT     = 89,
    VEH_FLY_YAW_RIGHT    = 90,
    VEH_FLY_ROLL_LR      = 107,
    VEH_FLY_PITCH_UD     = 110,
}

-- default Microsoft virtual-key codes. Every binding can be changed from
-- the ClickGUI and is written immediately to the script's own config file.
local default_keys = {
    activation = 0x62, -- Numpad 2: enables the cheat when currently disabled
    modeToggle = 0xA0, -- Left Shift: vehicle nose <-> gameplay camera
    pitchUp    = 0x62,
    pitchDown  = 0x68,
    turnLeft   = 0x64,
    turnRight  = 0x66,
}

local feature_hash = {
    enabled       = joaat("FlyingCarsSA_Enabled"),
    directionMode = joaat("FlyingCarsSA_DirectionMode"),
    hud           = joaat("FlyingCarsSA_Hud"),
    stuntStats    = joaat("FlyingCarsSA_StuntStats"),
    speedBob      = joaat("FlyingCarsSA_SpeedBob"),
    telemetry     = joaat("FlyingCarsSA_Telemetry"),
    resetBest     = joaat("FlyingCarsSA_ResetBest"),
}

-- ═══════════════════════════════════════════════════════════════════════════════════
-- persistent config
-- ═══════════════════════════════════════════════════════════════════════════════════

local config_dir = FileMgr.GetMenuRootPath() .. "\\Lua\\Flying_Cars_SA\\"
local config_file = config_dir .. "config.cfg"
local high_scores_file = config_dir .. "high_scores.lua"
local high_scores_log = config_dir .. "high_scores.log"
local high_score_limit = 10

local high_scores = {
    records = {},
    loaded = false,
}

local config = {
    directionMode = "vehicle",
    showHud = true,
    showStuntStats = true,
    speedBobbing = true,
    telemetry = false,
    activation = default_keys.activation,
    modeToggle = default_keys.modeToggle,
    pitchUp = default_keys.pitchUp,
    pitchDown = default_keys.pitchDown,
    turnLeft = default_keys.turnLeft,
    turnRight = default_keys.turnRight,
    ready = false,
}

local function bool_text(value)
    return value and "true" or "false"
end

local function parse_bool(value, fallback)
    if value == "true" or value == "1" then return true end
    if value == "false" or value == "0" then return false end
    return fallback
end

local function valid_vk(value, fallback)
    value = math.floor(tonumber(value) or -1)
    if value < 1 or value > 254 then return fallback end
    return value
end

local function file_exists(path)
    local file = io.open(path, "rb")
    if not file then return false end
    file:close()
    return true
end

local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function write_file(path, content, mode)
    FileMgr.CreateDir(config_dir)
    local file = io.open(path, mode or "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

local function save_config()
    if not config.ready then return false end

    local lines = {
        "version=1",
        "directionMode=" .. config.directionMode,
        "showHud=" .. bool_text(config.showHud),
        "showStuntStats=" .. bool_text(config.showStuntStats),
        "speedBobbing=" .. bool_text(config.speedBobbing),
        "telemetry=" .. bool_text(config.telemetry),
        "activation=" .. tostring(config.activation),
        "modeToggle=" .. tostring(config.modeToggle),
        "pitchUp=" .. tostring(config.pitchUp),
        "pitchDown=" .. tostring(config.pitchDown),
        "turnLeft=" .. tostring(config.turnLeft),
        "turnRight=" .. tostring(config.turnRight),
    }

    local saved = write_file(config_file, table.concat(lines, "\n") .. "\n")
    if not saved then Logger.LogError("[FlyingCarsSA] config save failed: " .. config_file) end
    return saved
end

local function load_config()
    FileMgr.CreateDir(config_dir)
    local content = read_file(config_file)
    if not content or content == "" then
        config.ready = true
        save_config()
        return false
    end

    local values = {}
    for line in content:gmatch("[^\r\n]+") do
        local key, value = line:match("^([^=]+)=(.*)$")
        if key then values[key] = value end
    end

    if values.directionMode == "camera" or values.directionMode == "vehicle" then
        config.directionMode = values.directionMode
    end
    config.showHud = parse_bool(values.showHud, config.showHud)
    config.showStuntStats = parse_bool(values.showStuntStats, config.showStuntStats)
    config.speedBobbing = parse_bool(values.speedBobbing, config.speedBobbing)
    config.telemetry = parse_bool(values.telemetry, config.telemetry)
    config.activation = valid_vk(values.activation, default_keys.activation)
    config.modeToggle = valid_vk(values.modeToggle, default_keys.modeToggle)
    config.pitchUp = valid_vk(values.pitchUp, default_keys.pitchUp)
    config.pitchDown = valid_vk(values.pitchDown, default_keys.pitchDown)
    config.turnLeft = valid_vk(values.turnLeft, default_keys.turnLeft)
    config.turnRight = valid_vk(values.turnRight, default_keys.turnRight)
    config.ready = true
    return true
end

load_config()

-- ═══════════════════════════════════════════════════════════════════════════════════
-- tuning
-- ═══════════════════════════════════════════════════════════════════════════════════

-- these values are deliberately centralized. They represent one coherent
-- flight model rather than unrelated boosts scattered through the loop.
local tune = {
    minimumFlightDistance = 18.0,
    teleportRejectMeters  = 45.0,

    -- road launch
    roadNeutralLift       = 0.16,
    roadPullUpLift        = 0.66,
    roadHighSpeedLift     = 0.16,
    roadPitchTorque       = 0.044,
    roadControlSharpness  = 6.8,
    roadLiftRiseSharpness = 2.15,
    roadLiftFallSharpness = 5.50,
    takeoffIntentSharpness = 2.30,
    takeoffIntentReleaseSharpness = 5.00,

    -- airborne energy
    maximumLift           = 1.23,
    groundEffectLift      = 0.10,
    coastThrust           = 0.030,
    maximumThrust         = 0.59,
    forwardDrag           = 0.00155,
    coastExtraDrag        = 0.00038,
    airbrakeDrag          = 0.25,
    airbrakeSpeedDrag     = 0.0125,

    -- nose-direction stability
    sideSlipDrag             = 0.072,
    verticalDirectionDrag    = 0.036,
    directionTurnBoost       = 0.44,
    directionRecoveryThrust  = 0.011,
    maximumDirectionForce    = 0.38,
    maximumDirectionThrust   = 0.13,

    -- momentum alignment
    noseVelocitySharpness    = 4.35,
    noseVelocityMaxBlend     = 0.105,
    noseVelocityTurnBoost    = 0.36,
    noseVelocitySpeedBoost   = 0.45,
    noseVelocityEnergyLoss   = 0.018,

    -- camera guidance
    cameraVectorSharpness      = 7.0,
    cameraModeBlendSharpness   = 3.8,
    cameraVelocityMaxBlend     = 0.082,
    cameraPitchResponse        = 0.46,
    cameraYawResponse          = 0.24,
    cameraRollResponse         = 0.62,
    cameraMaximumPitchRate     = 14.0,
    cameraMaximumYawRate       = 9.5,
    cameraMaximumBank          = 30.0,
    cameraManualOverride       = 0.82,

    -- high-speed stabilization
    highSpeedControlStart    = 1.05,
    highSpeedControlFull     = 2.25,
    highSpeedRollReduction   = 0.40,
    highSpeedYawReduction    = 0.48,
    diveRollReduction        = 0.34,
    diveYawReduction         = 0.42,
    diveControlStartDeg      = 28.0,
    diveControlFullDeg       = 78.0,

    -- visual camera bob
    cameraBobStartSpeed      = 24.0,
    cameraBobFullSpeed       = 68.0,
    cameraBobMaximum         = 0.58,
    cameraBobSharpness       = 6.5,

    -- turn resistance
    rollInputResistance   = 0.14,
    yawInputResistance    = 0.10,
    turnInputDrag         = 0.030,
    bankInducedDrag       = 0.017,

    -- damped aircraft-rate controller
    inputPressSharpness   = 6.5,
    inputReleaseSharpness = 7.8,
    rateFilterSharpness   = 12.8,
    torqueFilterSharpness = 16.0,
    releaseBlendSharpness = 4.8,
    maximumPitchRate      = 22.0, -- degrees per second
    maximumRollRate       = 29.0,
    maximumYawRate        = 12.5,
    pitchRateGain         = 0.0073,
    rollRateGain          = 0.0067,
    yawRateGain           = 0.0050,
    pitchOvershootGain    = 0.0038,
    rollOvershootGain     = 0.0031,
    yawOvershootGain      = 0.0022,
    maximumPitchTorque    = 0.145,
    maximumRollTorque     = 0.165,
    maximumYawTorque      = 0.086,
    pitchTrimStrength     = 0.105,
    rollLevelStrength     = 0.50,
    pitchLevelDeadzone    = 1.25,
    rollLevelDeadzone     = 1.75,
    directTurnYaw         = 0.20,
    bankYawStrength       = 0.62,
    bankYawExponent       = 1.45,
    -- gradual takeoff
    takeoffBlendSharpness = 1.65,
    takeoffInitialBlend   = 0.06,
    takeoffInitialLiftScale = 0.58,
    takeoffInitialThrustScale = 0.88,
    takeoffInitialControlScale = 0.34,
    takeoffInitialRateScale = 0.58,
    stallNoseDrop         = 0.105,

    -- touchdown sensitivity
    landingTouchdownControl = 0.20,
    landingSettledControl = 0.08,
    landingControlFrames  = 7,
    landingCooldownMs     = 1250,
    landingCooldownControl = 0.12,
    landingLiftDelayMs    = 450,

    -- forgiving landing validation
    landingFeedbackMinDistance = 8.0,
    badLandingVerticalSpeed = 11.0,
    badLandingSpeedLoss = 15.0,
    badLandingRoll = 85.0,
    badLandingPitch = 78.0,
    badLandingUpright = 0.22,
    badLandingCombinedVertical = 7.5,
    badLandingCombinedSpeedLoss = 7.0,
    badLandingCombinedUpright = 0.50,
    severeAirImpactSpeedLoss = 12.0,
    severeAirImpactVerticalSpeed = 12.0,
    severeAirImpactFastSpeed = 30.0,
    severeAirImpactFastLoss = 8.0,
    landingBannerLifeMs = 3600,

    -- impact timing
    impactDeadTimeMs      = 230,
    impactRecoveryMs      = 1500,
    impactCooldownMs      = 900,
    landingFrames         = 16,
}

local phase = {
    GROUND   = "ROAD",
    TAKEOFF  = "TAKEOFF",
    FLIGHT   = "FLIGHT",
    STALL    = "STALL",
    FALL     = "FALLING",
    RECOVER  = "RECOVERY",
    IMPACT   = "IMPACT",
    LANDING  = "LANDING",
}

-- ═══════════════════════════════════════════════════════════════════════════════════
-- runtime state
-- ═══════════════════════════════════════════════════════════════════════════════════

local state = {
    enabled = false,
    directionMode = config.directionMode,
    showHud = config.showHud,
    showStuntStats = config.showStuntStats,
    speedBobbing = config.speedBobbing,
    telemetry = config.telemetry,
    cameraShakeActive = false,
    cameraShakeAmplitude = 0.0,

    vehicle = 0,
    activeFlight = false,
    phase = phase.GROUND,
    previousPhase = phase.GROUND,

    runDistance = 0.0,
    bestDistance = 0.0,
    lastResult = "Build road speed, pull back, and take flight.",
    lastX = nil,
    lastY = nil,
    lastZ = nil,

    airFrames = 0,
    groundFrames = 0,
    recoveryFrames = 0,

    previousSpeed = 0.0,
    previousVerticalSpeed = 0.0,
    collidedLastFrame = false,
    impactStartedAt = -100000,
    impactCooldownUntil = 0,

    -- landing validation
    crashDisqualified = false,
    crashReason = "",
    touchdownCaptured = false,
    touchdownVerticalSpeed = 0.0,
    touchdownSpeed = 0.0,
    touchdownSpeedLoss = 0.0,
    touchdownUpright = 1.0,
    touchdownPitch = 0.0,
    touchdownRoll = 0.0,

    -- landing presentation
    landingBannerText = "",
    landingBannerDetail = "",
    landingBannerBad = false,
    landingBannerStartedAt = 0,
    lastGoodLandingPhrase = "",
    lastBadLandingPhrase = "",

    launchSpeed = 20.0,
    stallSpeed = 12.5,
    cruiseSpeed = 28.0,
    vehicleForceScale = 1.0,
    controlRateScale = 1.0,
    controlTorqueScale = 1.0,
    vehicleLength = 4.5,
    vehicleWidth = 1.8,
    vehicleHeight = 1.5,
    flightBlend = 0.0,
    roadLiftCommand = 0.0,
    takeoffIntent = 0.0,
    landingCooldownUntil = 0,
    landingSensitivity = 1.0,
    takeoffControlScale = 1.0,

    -- live telemetry
    speed = 0.0,
    forward_speed = 0.0,
    vertical_speed = 0.0,
    height = 0.0,
    pitch = 0.0,
    roll = 0.0,
    upright = 1.0,
    lift_support = 0.0,
    appliedLift = 0.0,
    control_authority = 0.0,
    impact_multiplier = 1.0,
    direction_alignment = 1.0,
    direction_authority = 0.0,
    nose_velocity_blend = 0.0,
    maneuverScale = 1.0,
    turn_resistance = 0.0,

    -- guidance state
    guidance_blend = 0.0,
    guideReady = false,
    guide_x = 0.0,
    guide_y = 1.0,
    guide_z = 0.0,
    guidanceAlignment = 1.0,
    guidance_pitch_error = 0.0,
    guidance_yaw_error = 0.0,

    -- stunt statistics
    maxHeight = 0.0,
    flipDegrees = 0.0,
    flipCount = 0,
    rotationDegrees = 0.0,

    -- aircraft controller state
    inputPitch = 0.0,
    inputRoll = 0.0,
    inputYaw = 0.0,
    attitudeReady = false,
    previousPitch = 0.0,
    previousRoll = 0.0,
    previousHeading = 0.0,
    pitchRate = 0.0,
    rollRate = 0.0,
    yawRate = 0.0,
    desired_pitch_rate = 0.0,
    desired_roll_rate = 0.0,
    desired_yaw_rate = 0.0,
    commandedPitchTorque = 0.0,
    commandedRollTorque = 0.0,
    commandedYawTorque = 0.0,
    pitchReleaseBlend = 1.0,
    rollReleaseBlend = 1.0,
    roadPitchCommand = 0.0,
    roadRollCommand = 0.0,
}

local messages = {
    { 25,    "A little hop, but every legend starts somewhere." },
    { 40,    "The wheels left Los Santos—briefly." },
    { 55,    "That curb just became a runway." },
    { 70,    "Airborne! The insurance company felt that." },
    { 85,    "The car almost believed it was a plane." },
    { 100,   "Flight confirmed. Landing quality remains classified." },
    { 120,   "You found the unofficial Los Santos air lane." },
    { 140,   "Roads are optional now." },
    { 160,   "That was more flight than accident." },
    { 180,   "Traffic laws do not cover this altitude." },
    { 200,   "A respectable voyage for a vehicle with license plates." },
    { 225,   "The suspension has filed a formal complaint." },
    { 250,   "You flew farther than most cars ever dream." },
    { 275,   "San Andreas physics would be proud." },
    { 300,   "Three hundred meters of pure bad judgment." },
    { 330,   "The highway cannot contain you anymore." },
    { 360,   "Pilot license: still extremely pending." },
    { 390,   "The car is beginning to identify as aviation." },
    { 420,   "You crossed an impressive amount of absolutely nothing." },
    { 450,   "Cloud parking may be available ahead." },
    { 480,   "That landing deserves applause or an investigation." },
    { 520,   "Half a kilometer without needing a road." },
    { 560,   "The Department of Transportation stopped returning calls." },
    { 600,   "Six hundred meters—your mechanic felt a disturbance." },
    { 650,   "This is no longer a shortcut. It is an air route." },
    { 700,   "Seven hundred meters of airborne confidence." },
    { 750,   "The tires were merely decorative." },
    { 800,   "You have officially outgrown ordinary commuting." },
    { 850,   "Radar contact: one deeply confused automobile." },
    { 900,   "The runway was wherever you said it was." },
    { 950,   "Almost a kilometer—the car wants wings next upgrade." },
    { 1000,  "One kilometer flown. Cheat-code energy achieved." },
    { 1100,  "The road trip has become an aviation incident." },
    { 1200,  "Twelve hundred meters and still no in-flight snacks." },
    { 1300,  "You are now commuting above the problem." },
    { 1400,  "The skyline has accepted you as one of its own." },
    { 1500,  "One and a half kilometers of majestic nonsense." },
    { 1650,  "The vehicle manual definitely did not mention this." },
    { 1800,  "You have achieved premium economy by automobile." },
    { 2000,  "Two kilometers flown. Welcome to Los Santos Air Traffic." },
    { 2250,  "The ground has become a distant suggestion." },
    { 2500,  "Two and a half kilometers—this car has a flight history." },
    { 2750,  "You could have driven there, but where is the glory?" },
    { 3000,  "Three kilometers. The cheat-code spirit is fully alive." },
    { 3500,  "You turned a street car into a cross-country aircraft." },
    { 4000,  "Four kilometers—air traffic control has given up." },
    { 5000,  "Five kilometers. This is now a certified flying car." },
    { 6500,  "The laws of physics have left the session." },
    { 8000,  "Even San Andreas would call that excessive." },
    { 10000, "Ten kilometers flown—legendary cheat-code performance." },
}

local great_landing_phrases = {
    "GREAT LANDING!",
    "CLEAN TOUCHDOWN!",
    "SMOOTH LANDING!",
    "NAILED THE LANDING!",
    "PERFECT TOUCHDOWN!",
    "LANDED LIKE A PRO!",
    "SILKY SMOOTH!",
    "WHEELS DOWN!",
    "BEAUTIFUL LANDING!",
    "STUCK THE LANDING!",
}

local bad_landing_phrases = {
    "BAD LANDING!",
    "ROUGH LANDING!",
    "CRASH LANDING!",
    "THAT ONE HURT!",
    "HARD TOUCHDOWN!",
    "LOST IT ON LANDING!",
    "WHEELS NOT DOWN!",
    "ROUGH ARRIVAL!",
    "IMPACT DETECTED!",
    "FLIGHT DISQUALIFIED!",
}

-- ═══════════════════════════════════════════════════════════════════════════════════
-- small helpers
-- ═══════════════════════════════════════════════════════════════════════════════════

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0.0, 1.0)
end

local function smoothstep(edge0, edge1, value)
    if edge0 == edge1 then return value >= edge1 and 1.0 or 0.0 end
    local t = clamp((value - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
end

local function exp_approach(current, target, sharpness, dt)
    local blend = 1.0 - math.exp(-math.max(0.0, sharpness) * dt)
    return current + (target - current) * clamp(blend, 0.0, 1.0)
end

local function angle_delta(current, previous)
    local delta = (current - previous) % 360.0
    if delta > 180.0 then delta = delta - 360.0 end
    return delta
end

local function smooth_pilot_axis(current, target, dt)
    local sharpness = math.abs(target) > math.abs(current)
        and tune.inputPressSharpness
        or tune.inputReleaseSharpness
    return exp_approach(current, target, sharpness, dt)
end

local function magnitude3(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

local function normalize3(x, y, z, fallback_x, fallback_y, fallback_z)
    local length = magnitude3(x, y, z)
    if length < 0.0001 then
        return fallback_x or 0.0, fallback_y or 1.0, fallback_z or 0.0
    end
    return x / length, y / length, z / length
end

local function signed_max(a, b)
    return math.abs(b) > math.abs(a) and b or a
end

local function sign(value)
    if value > 0.0 then return 1.0 end
    if value < 0.0 then return -1.0 end
    return 0.0
end

local function soft_deadzone(value, deadzone)
    local amount = math.abs(value)
    if amount <= deadzone then return 0.0 end
    return sign(value) * (amount - deadzone)
end

local function log(message)
    Logger.LogInfo("[FlyingCarsSA] " .. tostring(message))
end

local function toast(message, duration)
    GUI.AddToast(script_name, message, duration or 3500, eToastPos.TOP_RIGHT)
end

local function exists(entity)
    return entity and entity ~= 0 and invoke_bool(native_hash.DOES_ENTITY_EXIST, entity)
end

local function game_time()
    return invoke_int(native_hash.GET_GAME_TIMER)
end

local function choose_landing_phrase(pool, bad)
    if type(pool) ~= "table" or #pool == 0 then
        return bad and "BAD LANDING!" or "GREAT LANDING!"
    end

    local last = bad and state.lastBadLandingPhrase or state.lastGoodLandingPhrase
    local phrase = pool[math.random(1, #pool)]
    if #pool > 1 and phrase == last then
        for _ = 1, 6 do
            local retry = pool[math.random(1, #pool)]
            if retry ~= last then
                phrase = retry
                break
            end
        end
    end

    if bad then
        state.lastBadLandingPhrase = phrase
    else
        state.lastGoodLandingPhrase = phrase
    end
    return phrase
end

local function show_landing_banner(text, bad, detail)
    state.landingBannerText = tostring(text or (bad and "BAD LANDING!" or "GREAT LANDING!"))
    state.landingBannerDetail = tostring(detail or "")
    state.landingBannerBad = bad == true
    state.landingBannerStartedAt = game_time()
end

local function control_normal(control)
    return invoke_float(native_hash.GET_CONTROL_NORMAL, 0, control)
end

local function key_down(vk)
    return Utils.IsKeyDown(vk) == true
end

local key_names = {
    [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter",
    [0x10] = "Shift", [0x11] = "Ctrl", [0x12] = "Alt",
    [0x14] = "Caps Lock", [0x1B] = "Escape", [0x20] = "Space",
    [0x21] = "Page Up", [0x22] = "Page Down", [0x23] = "End",
    [0x24] = "Home", [0x25] = "Left Arrow", [0x26] = "Up Arrow",
    [0x27] = "Right Arrow", [0x28] = "Down Arrow", [0x2D] = "Insert",
    [0x2E] = "Delete", [0x60] = "Numpad 0", [0x61] = "Numpad 1",
    [0x62] = "Numpad 2", [0x63] = "Numpad 3", [0x64] = "Numpad 4",
    [0x65] = "Numpad 5", [0x66] = "Numpad 6", [0x67] = "Numpad 7",
    [0x68] = "Numpad 8", [0x69] = "Numpad 9", [0x6A] = "Numpad *",
    [0x6B] = "Numpad +", [0x6D] = "Numpad -", [0x6E] = "Numpad .",
    [0x6F] = "Numpad /", [0xA0] = "Left Shift", [0xA1] = "Right Shift",
    [0xA2] = "Left Ctrl", [0xA3] = "Right Ctrl", [0xA4] = "Left Alt",
    [0xA5] = "Right Alt",
}

local function key_name(vk)
    if key_names[vk] then return key_names[vk] end
    if vk >= 0x70 and vk <= 0x87 then return "feature_hash" .. tostring(vk - 0x6F) end
    if vk >= 0x41 and vk <= 0x5A then return string.char(vk) end
    if vk >= 0x30 and vk <= 0x39 then return string.char(vk) end
    return "VK " .. tostring(vk)
end

local function digital_axis(negative_key, positive_key)
    local value = 0.0
    if key_down(negative_key) then value = value - 1.0 end
    if key_down(positive_key) then value = value + 1.0 end
    return value
end

local function format_distance(meters)
    if meters >= 1000.0 then
        return string.format("%.2f km", meters / 1000.0)
    end
    return string.format("%.0f m", meters)
end

local function format_speed(meters_per_second)
    return string.format("%.0f km/h", meters_per_second * 3.6)
end

local function meters_to_feet(meters)
    return math.max(0, math.floor(meters * 3.280839895 + 0.5))
end

local function format_whole_number(value)
    local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    while true do
        local next_text, count = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
        text = next_text
        if count == 0 then break end
    end
    return text
end

local function format_feet(meters)
    return format_whole_number(meters_to_feet(meters)) .. " ft"
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- persistent high scores
-- note: clean top flights are stored as lua data and appended to a readable log.
-- ═══════════════════════════════════════════════════════════════════════════════════

local function normalize_high_score(record)
    if type(record) ~= "table" then return nil end

    local distance = math.max(0.0, tonumber(record.distance or record[1]) or 0.0)
    if distance <= 0.0 then return nil end

    local timestamp = math.floor(tonumber(record.timestamp or record.time or os.time()) or os.time())
    local mode = record.mode == "camera" and "camera" or "vehicle"

    return {
        distance = distance,
        height = math.max(0.0, tonumber(record.height) or 0.0),
        flips = math.max(0, math.floor(tonumber(record.flips) or 0)),
        rotation = math.max(0.0, tonumber(record.rotation) or 0.0),
        mode = mode,
        vehicle_model = math.floor(tonumber(record.vehicle_model or record.vehicleModel) or 0),
        timestamp = timestamp,
        date = tostring(record.date or os.date("%Y-%m-%d %H:%M:%S", timestamp) or timestamp),
    }
end

local function sort_high_scores()
    table.sort(high_scores.records, function(a, b)
        local ad = tonumber(a.distance) or 0.0
        local bd = tonumber(b.distance) or 0.0
        if ad ~= bd then return ad > bd end
        return (tonumber(a.timestamp) or 0) < (tonumber(b.timestamp) or 0)
    end)

    while #high_scores.records > high_score_limit do
        table.remove(high_scores.records)
    end
end

local function save_high_scores()
    sort_high_scores()
    local lines = {"return {\n"}

    for _, score in ipairs(high_scores.records) do
        lines[#lines + 1] = string.format(
            "    { distance = %.6f, height = %.6f, flips = %d, rotation = %.6f, mode = %q, vehicleModel = %d, timestamp = %d, date = %q },\n",
            tonumber(score.distance) or 0.0,
            tonumber(score.height) or 0.0,
            math.floor(tonumber(score.flips) or 0),
            tonumber(score.rotation) or 0.0,
            tostring(score.mode or "vehicle"),
            math.floor(tonumber(score.vehicle_model) or 0),
            math.floor(tonumber(score.timestamp) or os.time()),
            tostring(score.date or "")
        )
    end

    lines[#lines + 1] = "}\n"
    local saved = write_file(high_scores_file, table.concat(lines))
    if not saved then Logger.LogError("[FlyingCarsSA] high-score save failed: " .. high_scores_file) end
    return saved
end

local function load_high_scores(force)
    if high_scores.loaded and not force then return high_scores.records end

    high_scores.records = {}
    local exists = file_exists(high_scores_file)

    if exists then
        local loader, load_error = loadfile(high_scores_file)
        if loader then
            local ok, data = pcall(loader)
            if ok and type(data) == "table" then
                for _, record in ipairs(data) do
                    local normalized = normalize_high_score(record)
                    if normalized then high_scores.records[#high_scores.records + 1] = normalized end
                end
            elseif not ok then
                Logger.LogError("[FlyingCarsSA] high-score load failed: " .. tostring(data))
            end
        else
            Logger.LogError("[FlyingCarsSA] high-score parse failed: " .. tostring(load_error))
        end
    end

    sort_high_scores()
    high_scores.loaded = true
    state.bestDistance = high_scores.records[1] and high_scores.records[1].distance or 0.0

    if not exists then save_high_scores() end
    return high_scores.records
end

local function append_high_score_log(score, rank)
    local line = string.format(
        "[%s] Rank #%d | Distance: %s | Height: %s | Flips: %d | Rotation: %s deg | Direction: %s | Vehicle model: %d\n",
        tostring(score.date or "Unknown"),
        math.floor(tonumber(rank) or 0),
        format_feet(score.distance),
        format_feet(score.height),
        math.floor(tonumber(score.flips) or 0),
        format_whole_number(score.rotation),
        score.mode == "camera" and "Gameplay Camera" or "Vehicle Nose",
        math.floor(tonumber(score.vehicle_model) or 0)
    )

    if not write_file(high_scores_log, line, "a") then
        Logger.LogError("[FlyingCarsSA] high-score log failed: " .. high_scores_log)
    end
end

local function record_high_score(record)
    load_high_scores()
    local score = normalize_high_score(record)
    if not score then return nil, false end

    local previous_best = high_scores.records[1] and high_scores.records[1].distance or 0.0
    local last_score = high_scores.records[#high_scores.records]
    local qualifies = #high_scores.records < high_score_limit
        or not last_score
        or score.distance > (tonumber(last_score.distance) or 0.0)

    if not qualifies then
        state.bestDistance = previous_best
        return nil, false
    end

    high_scores.records[#high_scores.records + 1] = score
    sort_high_scores()

    local rank = nil
    for i, stored in ipairs(high_scores.records) do
        if stored == score then
            rank = i
            break
        end
    end

    if not rank then return nil, false end

    save_high_scores()
    append_high_score_log(score, rank)
    state.bestDistance = high_scores.records[1] and high_scores.records[1].distance or score.distance
    return rank, score.distance > previous_best
end

load_high_scores()

-- ═══════════════════════════════════════════════════════════════════════════════════
-- vehicle selection and adaptation
-- ═══════════════════════════════════════════════════════════════════════════════════

local function get_local_vehicle()
    local ped = invoke_int(native_hash.PLAYER_PED_ID)
    if ped == 0 or not invoke_bool(native_hash.IS_PED_IN_ANY_VEHICLE, ped, false) then
        return 0
    end

    local vehicle = invoke_int(native_hash.GET_VEHICLE_PED_IS_IN, ped, false)
    if vehicle == 0 then return 0 end

    if invoke_int(native_hash.GET_PED_IN_VEHICLE_SEAT, vehicle, -1, false) ~= ped then
        return 0
    end

    local class = invoke_int(native_hash.GET_VEHICLE_CLASS, vehicle)
    if class == 8 or class == 13 or class == 14 or class == 15
        or class == 16 or class == 21 then
        return 0
    end

    return vehicle
end

local function class_force_scale(class)
    if class == 10 or class == 11 or class == 19 or class == 20 then
        return 1.18
    end
    if class == 2 or class == 9 or class == 12 or class == 17 or class == 18 then
        return 1.08
    end
    return 1.0
end

local function get_vehicle_dimensions(vehicle)
    if not Memory or not Memory.Alloc or not Memory.ReadFloat or not Memory.Free then
        return 4.5, 1.8, 1.5
    end

    -- cherax vectors use an 8-byte stride between float components.
    local minimum = Memory.Alloc(24)
    local maximum = Memory.Alloc(24)
    if not minimum or not maximum then
        if minimum then Memory.Free(minimum) end
        if maximum then Memory.Free(maximum) end
        return 4.5, 1.8, 1.5
    end

    local model = invoke_int(native_hash.GET_ENTITY_MODEL, vehicle)
    invoke_void(native_hash.GET_MODEL_DIMENSIONS, model, minimum, maximum)

    local min_x = Memory.ReadFloat(minimum)
    local min_y = Memory.ReadFloat(minimum + 8)
    local min_z = Memory.ReadFloat(minimum + 16)
    local max_x = Memory.ReadFloat(maximum)
    local max_y = Memory.ReadFloat(maximum + 8)
    local max_z = Memory.ReadFloat(maximum + 16)

    Memory.Free(minimum)
    Memory.Free(maximum)

    local length = max_y - min_y
    local width = max_x - min_x
    local height = max_z - min_z
    if length < 1.5 or length > 20.0
        or width < 0.8 or width > 8.0
        or height < 0.5 or height > 8.0 then
        return 4.5, 1.8, 1.5
    end
    return length, width, height
end

local function configure_vehicle_profile(vehicle)
    local estimated_max = invoke_float(native_hash.GET_VEHICLE_ESTIMATED_MAX_SPEED, vehicle)
    if estimated_max < 20.0 or estimated_max > 120.0 then estimated_max = 45.0 end

    local class = invoke_int(native_hash.GET_VEHICLE_CLASS, vehicle)
    local class_scale = class_force_scale(class)
    local length, width, height = get_vehicle_dimensions(vehicle)
    local footprint_ratio = clamp((length * width) / 8.10, 0.55, 3.20)

    state.stallSpeed = clamp(estimated_max * 0.285, 11.0, 16.0)
    state.launchSpeed = clamp(estimated_max * 0.43, 18.0, 25.0)
    state.cruiseSpeed = clamp(estimated_max * 0.59, 25.0, 34.0)
    state.vehicleForceScale = class_scale
    state.vehicleLength = length
    state.vehicleWidth = width
    state.vehicleHeight = height

    state.controlRateScale = clamp(footprint_ratio ^ -0.18, 0.82, 1.12)
    state.controlTorqueScale = clamp(
        (footprint_ratio ^ 0.18) * (class_scale ^ 0.30),
        0.90,
        1.22
    )

    log(string.format(
        "Profile %.2fm x %.2fm x %.2fm | rate %.2f | torque %.2f",
        length, width, height, state.controlRateScale, state.controlTorqueScale
    ))
end

local function restore_vehicle(vehicle)
    if exists(vehicle) then
        -- this script never needs disabled gravity. Reasserting true also
        -- repairs a vehicle left gravityless by the previous alpha.
        invoke_void(native_hash.SET_VEHICLE_GRAVITY, vehicle, true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- flight records
-- ═══════════════════════════════════════════════════════════════════════════════════

local stop_speed_bobbing

local function reset_run()
    if stop_speed_bobbing then stop_speed_bobbing() end
    state.activeFlight = false
    state.phase = phase.GROUND
    state.previousPhase = phase.GROUND
    state.runDistance = 0.0
    state.lastX, state.lastY, state.lastZ = nil, nil, nil
    state.airFrames = 0
    state.groundFrames = 0
    state.recoveryFrames = 0
    state.previousSpeed = 0.0
    state.previousVerticalSpeed = 0.0
    state.collidedLastFrame = false
    state.impactStartedAt = -100000
    state.impactCooldownUntil = 0
    state.crashDisqualified = false
    state.crashReason = ""
    state.touchdownCaptured = false
    state.touchdownVerticalSpeed = 0.0
    state.touchdownSpeed = 0.0
    state.touchdownSpeedLoss = 0.0
    state.touchdownUpright = 1.0
    state.touchdownPitch = 0.0
    state.touchdownRoll = 0.0
    state.lift_support = 0.0
    state.appliedLift = 0.0
    state.control_authority = 0.0
    state.impact_multiplier = 1.0
    state.direction_alignment = 1.0
    state.direction_authority = 0.0
    state.nose_velocity_blend = 0.0
    state.maneuverScale = 1.0
    state.turn_resistance = 0.0
    state.maxHeight = 0.0
    state.flipDegrees = 0.0
    state.flipCount = 0
    state.rotationDegrees = 0.0
    state.inputPitch = 0.0
    state.inputRoll = 0.0
    state.inputYaw = 0.0
    state.attitudeReady = false
    state.pitchRate = 0.0
    state.rollRate = 0.0
    state.yawRate = 0.0
    state.desired_pitch_rate = 0.0
    state.desired_roll_rate = 0.0
    state.desired_yaw_rate = 0.0
    state.commandedPitchTorque = 0.0
    state.commandedRollTorque = 0.0
    state.commandedYawTorque = 0.0
    state.pitchReleaseBlend = 1.0
    state.rollReleaseBlend = 1.0
    state.roadPitchCommand = 0.0
    state.roadRollCommand = 0.0
    state.roadLiftCommand = 0.0
    state.takeoffIntent = 0.0
    state.flightBlend = 0.0
    state.landingSensitivity = 1.0
    state.takeoffControlScale = 1.0
    state.guidance_blend = 0.0
    state.guideReady = false
    state.guidanceAlignment = 1.0
    state.guidance_pitch_error = 0.0
    state.guidance_yaw_error = 0.0
end

local function choose_message(distance)
    local pool = {}
    for _, entry in ipairs(messages) do
        if distance >= entry[1] then pool[#pool + 1] = entry[2] end
    end
    if #pool == 0 then return messages[1][2] end

    local first = math.max(1, #pool - 5)
    return pool[math.random(first, #pool)]
end

local function capture_touchdown(vehicle, speed, vertical_speed)
    if state.touchdownCaptured then return end
    state.touchdownCaptured = true

    local prior_vertical = tonumber(state.previousVerticalSpeed) or tonumber(vertical_speed) or 0.0
    local prior_speed = tonumber(state.previousSpeed) or tonumber(speed) or 0.0
    local current_speed = tonumber(speed) or 0.0
    local upright = invoke_float(native_hash.GET_ENTITY_UPRIGHT_VALUE, vehicle)
    local pitch = invoke_float(native_hash.GET_ENTITY_PITCH, vehicle)
    local roll = invoke_float(native_hash.GET_ENTITY_ROLL, vehicle)
    local upside_down = invoke_bool(native_hash.IS_ENTITY_UPSIDEDOWN, vehicle)
    local speed_loss = math.max(0.0, prior_speed - current_speed)

    state.touchdownVerticalSpeed = prior_vertical
    state.touchdownSpeed = prior_speed
    state.touchdownSpeedLoss = speed_loss
    state.touchdownUpright = upright
    state.touchdownPitch = pitch
    state.touchdownRoll = roll

    local bad_reason = nil
    if upside_down or upright <= tune.badLandingUpright then
        bad_reason = "vehicle landed upside down"
    elseif prior_vertical <= -tune.badLandingVerticalSpeed then
        bad_reason = "excessive downward speed"
    elseif math.abs(roll) >= tune.badLandingRoll then
        bad_reason = "extreme roll angle"
    elseif math.abs(pitch) >= tune.badLandingPitch then
        bad_reason = "extreme pitch angle"
    elseif speed_loss >= tune.badLandingSpeedLoss and prior_speed >= 22.0 then
        bad_reason = "massive impact speed loss"
    elseif prior_vertical <= -tune.badLandingCombinedVertical
        and speed_loss >= tune.badLandingCombinedSpeedLoss then
        bad_reason = "hard combined touchdown"
    elseif prior_vertical <= -tune.badLandingCombinedVertical
        and upright <= tune.badLandingCombinedUpright then
        bad_reason = "hard angled touchdown"
    end

    if bad_reason then
        state.crashDisqualified = true
        state.crashReason = bad_reason
    end
end

local function classify_landing(vehicle)
    if state.crashDisqualified then
        return true, state.crashReason ~= "" and state.crashReason or "severe impact"
    end

    if exists(vehicle) then
        local upside_down = invoke_bool(native_hash.IS_ENTITY_UPSIDEDOWN, vehicle)
        local upright = invoke_float(native_hash.GET_ENTITY_UPRIGHT_VALUE, vehicle)
        if upside_down or upright <= tune.badLandingUpright then
            return true, "vehicle did not settle upright"
        end
    end

    return false, "clean touchdown"
end

local function finish_flight(reason)
    stop_speed_bobbing()
    reason = tostring(reason or "landing")
    local landed_at = game_time()
    local settled_landing = state.groundFrames >= tune.landingFrames
    local distance = state.runDistance

    if reason ~= "landing" then
        if distance >= tune.landingFeedbackMinDistance then
            state.lastResult = "Flight cancelled — score not saved (" .. reason .. ")."
            log(state.lastResult)
        end
        reset_run()
        return
    end

    local bad_landing, bad_reason = classify_landing(state.vehicle)
    local phrase = choose_landing_phrase(
        bad_landing and bad_landing_phrases or great_landing_phrases,
        bad_landing
    )

    if distance < tune.landingFeedbackMinDistance then
        reset_run()
        if settled_landing then
            state.landingCooldownUntil = landed_at + tune.landingCooldownMs
        end
        return
    end

    if bad_landing then
        local detail = "SCORE DISQUALIFIED  •  " .. format_distance(distance)
        state.lastResult = phrase .. " — " .. format_distance(distance)
            .. " — score disqualified: " .. tostring(bad_reason) .. "."
        show_landing_banner(phrase, true, detail)
        toast("Bad landing — flight score was not saved.", 4200)
        log(state.lastResult)
        reset_run()
        if settled_landing then
            state.landingCooldownUntil = landed_at + tune.landingCooldownMs
        end
        return
    end

    if distance < tune.minimumFlightDistance then
        state.lastResult = phrase .. " — " .. format_distance(distance)
            .. " — flight too short for the leaderboard."
        show_landing_banner(phrase, false, "CLEAN TOUCHDOWN  •  " .. format_distance(distance))
        log(state.lastResult)
        reset_run()
        if settled_landing then
            state.landingCooldownUntil = landed_at + tune.landingCooldownMs
        end
        return
    end

    local vehicle_model = 0
    if exists(state.vehicle) then
        vehicle_model = invoke_int(native_hash.GET_ENTITY_MODEL, state.vehicle)
    end

    local rank, new_best = record_high_score({
        distance = distance,
        height = state.maxHeight,
        flips = state.flipCount,
        rotation = state.rotationDegrees,
        mode = state.directionMode,
        vehicle_model = vehicle_model,
        timestamp = os.time(),
    })

    local score_tag = ""
    local banner_detail = "GREAT LANDING  •  " .. format_distance(distance)
    if new_best then
        score_tag = "  NEW ALL-TIME BEST!"
        banner_detail = "NEW ALL-TIME BEST  •  " .. format_distance(distance)
    elseif rank then
        score_tag = "  TOP " .. tostring(rank) .. " HIGH SCORE!"
        banner_detail = "TOP " .. tostring(rank) .. " HIGH SCORE  •  " .. format_distance(distance)
    end

    local message = choose_message(distance)
    state.lastResult = string.format(
        "%s — %s — %s%s",
        format_distance(distance),
        phrase,
        message,
        score_tag
    )
    show_landing_banner(phrase, false, banner_detail)
    toast(state.lastResult, 6500)
    log(state.lastResult)
    reset_run()
    if settled_landing then
        state.landingCooldownUntil = landed_at + tune.landingCooldownMs
    end
end

local function begin_flight(vehicle)
    state.activeFlight = true
    state.phase = phase.TAKEOFF
    state.previousPhase = phase.GROUND
    state.runDistance = 0.0
    state.lastX, state.lastY, state.lastZ = nil, nil, nil
    state.groundFrames = 0
    state.recoveryFrames = 0
    state.collidedLastFrame = invoke_bool(native_hash.HAS_ENTITY_COLLIDED_WITH_ANYTHING, vehicle)
    state.impactCooldownUntil = game_time() + 250
    state.crashDisqualified = false
    state.crashReason = ""
    state.touchdownCaptured = false
    state.touchdownVerticalSpeed = 0.0
    state.touchdownSpeed = 0.0
    state.touchdownSpeedLoss = 0.0
    state.touchdownUpright = 1.0
    state.touchdownPitch = 0.0
    state.touchdownRoll = 0.0
    state.previousSpeed = invoke_float(native_hash.GET_ENTITY_SPEED, vehicle)
    local _, _, vz = invoke_v3(native_hash.GET_ENTITY_VELOCITY, vehicle)
    state.previousVerticalSpeed = vz
    state.flightBlend = tune.takeoffInitialBlend
    state.landingCooldownUntil = 0
    state.maxHeight = math.max(0.0, invoke_float(native_hash.GET_ENTITY_HEIGHT_ABOVE_GROUND, vehicle))
    state.flipDegrees = 0.0
    state.flipCount = 0
    state.rotationDegrees = 0.0
    state.commandedPitchTorque = state.roadPitchCommand * 0.65
    state.commandedRollTorque = state.roadRollCommand * 0.65
    state.commandedYawTorque = 0.0
end

local function update_distance(vehicle)
    local x, y, z = invoke_v3(native_hash.GET_ENTITY_COORDS, vehicle, true)
    if state.lastX then
        local segment = magnitude3(x - state.lastX, y - state.lastY, z - state.lastZ)
        if segment < tune.teleportRejectMeters then
            state.runDistance = state.runDistance + segment
        end
    end
    state.lastX, state.lastY, state.lastZ = x, y, z
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- forces and controls
-- ═══════════════════════════════════════════════════════════════════════════════════

local function apply_relative_force(vehicle, x, y, z)
    invoke_void(
        native_hash.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS,
        vehicle, 1, x, y, z,
        false, true, true, false
    )
end

local function apply_relative_torque(vehicle, pitch, roll, yaw)
    invoke_void(
        native_hash.APPLY_FORCE_TO_ENTITY,
        vehicle, 1,
        0.0, 0.0, 0.0,
        pitch, roll, yaw,
        0, true, true, true, false, true
    )
end

local function get_inputs(dt)
    local throttle = math.max(
        math.max(0.0, control_normal(control_id.VEH_ACCELERATE)),
        math.max(0.0, control_normal(control_id.VEH_FLY_THROTTLE_UP))
    )
    local brake = math.max(
        math.max(0.0, control_normal(control_id.VEH_BRAKE)),
        math.max(0.0, control_normal(control_id.VEH_FLY_THROTTLE_DN))
    )

    local numpad_pitch = digital_axis(config.pitchUp, config.pitchDown)
    local numpad_turn = digital_axis(config.turnLeft, config.turnRight)

    local steer = signed_max(
        signed_max(control_normal(control_id.VEH_MOVE_LR), control_normal(control_id.VEH_FLY_ROLL_LR)),
        numpad_turn
    )
    local pitch = signed_max(control_normal(control_id.VEH_FLY_PITCH_UD), numpad_pitch)

    local yaw_left = math.max(0.0, control_normal(control_id.VEH_FLY_YAW_LEFT))
    local yaw_right = math.max(0.0, control_normal(control_id.VEH_FLY_YAW_RIGHT))
    local yaw = yaw_right - yaw_left

    yaw = clamp(yaw + numpad_turn * tune.directTurnYaw, -1.0, 1.0)

    local handbrake = invoke_bool(native_hash.IS_CONTROL_PRESSED, 0, control_id.VEH_HANDBRAKE)
    if handbrake then yaw = clamp(yaw + steer * 0.72, -1.0, 1.0) end

    state.inputPitch = smooth_pilot_axis(state.inputPitch, pitch, dt)
    state.inputRoll = smooth_pilot_axis(state.inputRoll, steer, dt)
    state.inputYaw = smooth_pilot_axis(state.inputYaw, yaw, dt)

    if math.abs(state.inputPitch) < 0.002 then state.inputPitch = 0.0 end
    if math.abs(state.inputRoll) < 0.002 then state.inputRoll = 0.0 end
    if math.abs(state.inputYaw) < 0.002 then state.inputYaw = 0.0 end

    local pitch_released = math.abs(state.inputPitch) < 0.075
    local roll_released = math.abs(state.inputRoll) < 0.075
    state.pitchReleaseBlend = exp_approach(
        state.pitchReleaseBlend,
        pitch_released and 1.0 or 0.0,
        pitch_released and tune.releaseBlendSharpness or 9.0,
        dt
    )
    state.rollReleaseBlend = exp_approach(
        state.rollReleaseBlend,
        roll_released and 1.0 or 0.0,
        roll_released and tune.releaseBlendSharpness or 9.0,
        dt
    )

    return throttle, brake, state.inputRoll, state.inputPitch, state.inputYaw, handbrake
end


stop_speed_bobbing = function()
    if state.cameraShakeActive then
        invoke_void(native_hash.STOP_GAMEPLAY_CAM_SHAKING, true)
    end
    state.cameraShakeActive = false
    state.cameraShakeAmplitude = 0.0
end

local function update_speed_bobbing(speed, dt)
    if not state.speedBobbing or not state.activeFlight or state.groundFrames > 0 then
        stop_speed_bobbing()
        return
    end

    local speed_ratio = smoothstep(
        tune.cameraBobStartSpeed,
        tune.cameraBobFullSpeed,
        speed
    )
    local pulse = 0.86 + 0.14 * math.sin(game_time() * 0.0115)
    local target = tune.cameraBobMaximum * (speed_ratio ^ 1.35) * pulse
    state.cameraShakeAmplitude = exp_approach(
        state.cameraShakeAmplitude,
        target,
        tune.cameraBobSharpness,
        dt
    )

    if state.cameraShakeAmplitude > 0.008 then
        if not state.cameraShakeActive then
            invoke_void(native_hash.SHAKE_GAMEPLAY_CAM, "SKY_DIVING_SHAKE", 0.01)
            state.cameraShakeActive = true
        end
        invoke_void(
            native_hash.SET_GAMEPLAY_CAM_SHAKE_AMPLITUDE,
            state.cameraShakeAmplitude
        )
    elseif state.cameraShakeActive then
        stop_speed_bobbing()
    end
end

local function get_camera_forward()
    local pitch, _, yaw = invoke_v3(native_hash.GET_GAMEPLAY_CAM_ROT, 2)
    local pitch_rad = math.rad(pitch)
    local yaw_rad = math.rad(yaw)
    local horizontal = math.abs(math.cos(pitch_rad))
    return normalize3(
        -math.sin(yaw_rad) * horizontal,
        math.cos(yaw_rad) * horizontal,
        math.sin(pitch_rad),
        0.0, 1.0, 0.0
    )
end

local function update_guidance_target(vehicle, pitch, heading, dt)
    local fx, fy, fz = invoke_v3(native_hash.GET_ENTITY_FORWARD_VECTOR, vehicle)
    fx, fy, fz = normalize3(fx, fy, fz, 0.0, 1.0, 0.0)

    if not state.guideReady then
        state.guideReady = true
        state.guide_x, state.guide_y, state.guide_z = fx, fy, fz
        state.guidance_blend = 0.0
    end

    local cx, cy, cz = get_camera_forward()
    state.guide_x = exp_approach(state.guide_x, cx, tune.cameraVectorSharpness, dt)
    state.guide_y = exp_approach(state.guide_y, cy, tune.cameraVectorSharpness, dt)
    state.guide_z = exp_approach(state.guide_z, cz, tune.cameraVectorSharpness, dt)
    state.guide_x, state.guide_y, state.guide_z = normalize3(
        state.guide_x, state.guide_y, state.guide_z, fx, fy, fz
    )

    local target_blend = state.directionMode == "camera" and 1.0 or 0.0
    state.guidance_blend = exp_approach(
        state.guidance_blend,
        target_blend,
        tune.cameraModeBlendSharpness,
        dt
    )
    if state.guidance_blend < 0.001 then state.guidance_blend = 0.0 end
    if state.guidance_blend > 0.999 then state.guidance_blend = 1.0 end

    local gx = lerp(fx, state.guide_x, state.guidance_blend)
    local gy = lerp(fy, state.guide_y, state.guidance_blend)
    local gz = lerp(fz, state.guide_z, state.guidance_blend)
    gx, gy, gz = normalize3(gx, gy, gz, fx, fy, fz)

    local target_pitch = math.deg(math.asin(clamp(gz, -1.0, 1.0)))
    local target_heading = math.deg(math.atan(-gx, gy))
    if target_heading < 0.0 then target_heading = target_heading + 360.0 end

    state.guidance_pitch_error = clamp(target_pitch - pitch, -85.0, 85.0)
    state.guidance_yaw_error = clamp(angle_delta(target_heading, heading), -150.0, 150.0)
    state.guidanceAlignment = clamp(fx * gx + fy * gy + fz * gz, -1.0, 1.0)

    return gx, gy, gz
end

local function align_velocity_to_guidance(
    vehicle,
    target_x,
    target_y,
    target_z,
    speed,
    total_speed_support,
    impact_multiplier,
    transition_blend,
    turn_command,
    dt
)
    if speed < 0.75 or impact_multiplier < 0.18 then return 0.0 end

    local vx, vy, vz = invoke_v3(native_hash.GET_ENTITY_VELOCITY, vehicle)
    target_x, target_y, target_z = normalize3(target_x, target_y, target_z, 0.0, 1.0, 0.0)
    local target_dot = clamp(
        (vx * target_x + vy * target_y + vz * target_z) / math.max(speed, 0.001),
        -1.0,
        1.0
    )
    local misalignment = clamp((1.0 - target_dot) * 0.5, 0.0, 1.0)
    local over_cruise = smoothstep(state.cruiseSpeed, state.cruiseSpeed * 2.15, speed)

    local authority = total_speed_support
        * impact_multiplier
        * lerp(0.30, 1.0, transition_blend)
        * (1.0 + turn_command * tune.noseVelocityTurnBoost)
        * (1.0 + over_cruise * tune.noseVelocitySpeedBoost)
    authority = clamp(authority, 0.0, 1.60)

    local blend = 1.0 - math.exp(-tune.noseVelocitySharpness * authority * dt)
    local maximum_blend = lerp(
        tune.noseVelocityMaxBlend,
        tune.cameraVelocityMaxBlend,
        state.guidance_blend
    )
    blend = clamp(blend, 0.0, maximum_blend)

    local retained_speed = speed * (1.0 - misalignment * tune.noseVelocityEnergyLoss)
    local desired_x = target_x * retained_speed
    local desired_y = target_y * retained_speed
    local desired_z = target_z * retained_speed
    local new_x = lerp(vx, desired_x, blend)
    local new_y = lerp(vy, desired_y, blend)
    local new_z = lerp(vz, desired_z, blend)
    invoke_void(native_hash.SET_ENTITY_VELOCITY, vehicle, new_x, new_y, new_z)

    state.direction_alignment = clamp(target_dot, 0.0, 1.0)
    return blend
end

local function update_stunt_stats(height, dt)
    state.maxHeight = math.max(state.maxHeight, math.max(0.0, height))

    local pitch_spin = math.abs(state.pitchRate)
    local roll_spin = math.abs(state.rollRate)
    local flip_rate = math.max(
        pitch_spin >= 16.0 and pitch_spin or 0.0,
        roll_spin >= 24.0 and roll_spin or 0.0
    )
    state.flipDegrees = state.flipDegrees + flip_rate * dt
    state.flipCount = math.floor(state.flipDegrees / 360.0)

    local yaw_spin = math.abs(state.yawRate)
    if yaw_spin >= 1.5 then
        state.rotationDegrees = state.rotationDegrees + yaw_spin * dt
    end
end

local function update_attitude_rates(pitch, roll, heading, dt)
    if not state.attitudeReady then
        state.attitudeReady = true
        state.previousPitch = pitch
        state.previousRoll = roll
        state.previousHeading = heading
        state.pitchRate = 0.0
        state.rollRate = 0.0
        state.yawRate = 0.0
        return
    end

    local raw_pitch_rate = clamp(angle_delta(pitch, state.previousPitch) / dt, -180.0, 180.0)
    local raw_roll_rate = clamp(angle_delta(roll, state.previousRoll) / dt, -220.0, 220.0)
    local raw_yaw_rate = clamp(angle_delta(heading, state.previousHeading) / dt, -180.0, 180.0)

    state.pitchRate = exp_approach(state.pitchRate, raw_pitch_rate, tune.rateFilterSharpness, dt)
    state.rollRate = exp_approach(state.rollRate, raw_roll_rate, tune.rateFilterSharpness, dt)
    state.yawRate = exp_approach(state.yawRate, raw_yaw_rate, tune.rateFilterSharpness, dt)

    state.previousPitch = pitch
    state.previousRoll = roll
    state.previousHeading = heading
end

local function rate_controller_torque(desired_rate, measured_rate, gain, overshoot_gain, maximum_torque)
    local error = desired_rate - measured_rate
    local torque = error * gain

    local same_direction = desired_rate * measured_rate >= 0.0
    local excess_rate = math.abs(measured_rate) - math.abs(desired_rate)
    if same_direction and excess_rate > 0.0 then
        torque = torque - sign(measured_rate) * excess_rate * overshoot_gain
    elseif math.abs(desired_rate) < 0.30 then
        torque = torque - measured_rate * overshoot_gain
    end

    return clamp(torque, -maximum_torque, maximum_torque)
end

local function calculate_aircraft_torques(
    pitch,
    roll,
    pitch_input,
    steer,
    yaw_input,
    control_authority,
    speed,
    transition_blend,
    landing_control_scale,
    guidance_pitch_error,
    guidance_yaw_error,
    guidance_blend,
    dt
)
    local rate_scale = state.controlRateScale
    local torque_scale = state.controlTorqueScale

    local desired_pitch_rate = -pitch_input * tune.maximumPitchRate * rate_scale

    local turn_command = clamp(math.max(math.abs(steer), math.abs(yaw_input)), 0.0, 1.0)
    local roll_rate_resistance = 1.0 - tune.rollInputResistance * turn_command
    local desired_roll_rate = steer * tune.maximumRollRate * rate_scale * roll_rate_resistance

    if math.abs(pitch_input) < 0.075 and math.abs(pitch) < 70.0 then
        local trim_pitch = soft_deadzone(pitch, tune.pitchLevelDeadzone)
        desired_pitch_rate = clamp(
            -trim_pitch * tune.pitchTrimStrength * state.pitchReleaseBlend,
            -4.8 * rate_scale,
            4.8 * rate_scale
        )
    end
    if math.abs(steer) < 0.075 and math.abs(roll) < 100.0 then
        local level_roll = soft_deadzone(roll, tune.rollLevelDeadzone)
        desired_roll_rate = clamp(
            -level_roll * tune.rollLevelStrength * state.rollReleaseBlend,
            -13.0 * rate_scale,
            13.0 * rate_scale
        )
    end

    local bank_ratio = clamp(roll / 46.0, -1.0, 1.0)
    local bank_curve = sign(bank_ratio) * (math.abs(bank_ratio) ^ tune.bankYawExponent)
    local yaw_rate_resistance = 1.0 - tune.yawInputResistance * turn_command
    local desired_yaw_rate = (
        yaw_input * tune.maximumYawRate * rate_scale
        + bank_curve * tune.maximumYawRate * tune.bankYawStrength * rate_scale
    ) * yaw_rate_resistance

    if guidance_blend > 0.001 then
        local pitch_override = clamp(
            1.0 - math.abs(pitch_input) * tune.cameraManualOverride,
            0.18,
            1.0
        )
        local turn_override = clamp(
            1.0 - turn_command * tune.cameraManualOverride,
            0.18,
            1.0
        )
        local pitch_guide = clamp(
            guidance_pitch_error * tune.cameraPitchResponse,
            -tune.cameraMaximumPitchRate,
            tune.cameraMaximumPitchRate
        ) * rate_scale
        local target_bank = clamp(
            guidance_yaw_error * 0.42,
            -tune.cameraMaximumBank,
            tune.cameraMaximumBank
        )
        local roll_guide = clamp(
            (target_bank - roll) * tune.cameraRollResponse,
            -tune.maximumRollRate * 0.78,
            tune.maximumRollRate * 0.78
        ) * rate_scale
        local yaw_guide = clamp(
            guidance_yaw_error * tune.cameraYawResponse,
            -tune.cameraMaximumYawRate,
            tune.cameraMaximumYawRate
        ) * rate_scale
        local phase_guide = guidance_blend * lerp(0.25, 1.0, transition_blend)

        desired_pitch_rate = desired_pitch_rate + pitch_guide * phase_guide * pitch_override
        desired_roll_rate = desired_roll_rate + roll_guide * phase_guide * turn_override
        desired_yaw_rate = desired_yaw_rate + yaw_guide * phase_guide * turn_override
    end

    local high_speed_factor = smoothstep(
        state.cruiseSpeed * tune.highSpeedControlStart,
        state.cruiseSpeed * tune.highSpeedControlFull,
        speed
    )
    local dive_factor = smoothstep(
        tune.diveControlStartDeg,
        tune.diveControlFullDeg,
        math.max(0.0, -pitch)
    )
    local roll_scale = clamp(
        1.0
            - high_speed_factor * tune.highSpeedRollReduction
            - high_speed_factor * dive_factor * tune.diveRollReduction,
        0.26,
        1.0
    )
    local yaw_scale = clamp(
        1.0
            - high_speed_factor * tune.highSpeedYawReduction
            - high_speed_factor * dive_factor * tune.diveYawReduction,
        0.20,
        1.0
    )
    desired_roll_rate = desired_roll_rate * roll_scale
    desired_yaw_rate = desired_yaw_rate * yaw_scale

    local takeoff_rate_scale = lerp(
        tune.takeoffInitialRateScale,
        1.0,
        transition_blend
    )
    local phase_rate_scale = takeoff_rate_scale * landing_control_scale
    desired_pitch_rate = desired_pitch_rate * phase_rate_scale
    desired_roll_rate = desired_roll_rate * phase_rate_scale
    desired_yaw_rate = desired_yaw_rate * phase_rate_scale
    state.maneuverScale = math.min(roll_scale, yaw_scale) * phase_rate_scale
    state.takeoffControlScale = takeoff_rate_scale

    state.desired_pitch_rate = desired_pitch_rate
    state.desired_roll_rate = desired_roll_rate
    state.desired_yaw_rate = desired_yaw_rate

    local max_pitch_torque = tune.maximumPitchTorque * torque_scale
    local max_roll_torque = tune.maximumRollTorque * torque_scale
    local max_yaw_torque = tune.maximumYawTorque * torque_scale

    local pitch_torque_target = rate_controller_torque(
        desired_pitch_rate,
        state.pitchRate,
        tune.pitchRateGain,
        tune.pitchOvershootGain,
        max_pitch_torque
    ) * control_authority
    local roll_torque_target = -rate_controller_torque(
        desired_roll_rate,
        state.rollRate,
        tune.rollRateGain,
        tune.rollOvershootGain,
        max_roll_torque
    ) * control_authority
    local yaw_torque_target = -rate_controller_torque(
        desired_yaw_rate,
        state.yawRate,
        tune.yawRateGain,
        tune.yawOvershootGain,
        max_yaw_torque
    ) * control_authority

    state.commandedPitchTorque = exp_approach(
        state.commandedPitchTorque,
        pitch_torque_target,
        tune.torqueFilterSharpness,
        dt
    )
    state.commandedRollTorque = exp_approach(
        state.commandedRollTorque,
        roll_torque_target,
        tune.torqueFilterSharpness,
        dt
    )
    state.commandedYawTorque = exp_approach(
        state.commandedYawTorque,
        yaw_torque_target,
        tune.torqueFilterSharpness,
        dt
    )

    if landing_control_scale < 0.999 then
        state.commandedPitchTorque = state.commandedPitchTorque * landing_control_scale
        state.commandedRollTorque = state.commandedRollTorque * landing_control_scale
        state.commandedYawTorque = state.commandedYawTorque * landing_control_scale
    end

    return state.commandedPitchTorque,
        state.commandedRollTorque,
        state.commandedYawTorque
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- road phase
-- ═══════════════════════════════════════════════════════════════════════════════════

local function apply_road_flight_effects(vehicle, throttle, steer, pitch_input, dt)
    local _, local_y = invoke_v3(native_hash.GET_ENTITY_SPEED_VECTOR, vehicle, true)
    local forward_speed = math.max(0.0, local_y)
    local speed_factor = smoothstep(
        state.launchSpeed - 2.0,
        state.cruiseSpeed + 6.0,
        forward_speed
    )

    local now = game_time()
    local road_control_scale = 1.0
    local road_lift_scale = 1.0
    if now < state.landingCooldownUntil then
        local elapsed = tune.landingCooldownMs - (state.landingCooldownUntil - now)
        local recovery = smoothstep(0.0, tune.landingCooldownMs, elapsed)
        road_control_scale = lerp(tune.landingCooldownControl, 1.0, recovery)
        road_lift_scale = smoothstep(
            tune.landingLiftDelayMs,
            tune.landingCooldownMs,
            elapsed
        )
    end

    local raw_pull_up = clamp(-pitch_input, 0.0, 1.0)
    local intent_sharpness = raw_pull_up > state.takeoffIntent
        and tune.takeoffIntentSharpness
        or tune.takeoffIntentReleaseSharpness
    state.takeoffIntent = exp_approach(
        state.takeoffIntent,
        raw_pull_up,
        intent_sharpness,
        dt
    )
    local pull_up = state.takeoffIntent

    local neutral_lift = tune.roadNeutralLift * speed_factor * (0.35 + throttle * 0.65)
    local pull_up_lift = tune.roadPullUpLift * speed_factor * (pull_up ^ 1.18)
    local overspeed_lift = tune.roadHighSpeedLift
        * smoothstep(state.cruiseSpeed, state.cruiseSpeed + 10.0, forward_speed)
        * throttle

    local lift_target = (neutral_lift + pull_up_lift + overspeed_lift)
        * state.vehicleForceScale
        * road_lift_scale
    local lift_sharpness = lift_target > state.roadLiftCommand
        and tune.roadLiftRiseSharpness
        or tune.roadLiftFallSharpness
    state.roadLiftCommand = exp_approach(
        state.roadLiftCommand,
        lift_target,
        lift_sharpness,
        dt
    )
    local lift = state.roadLiftCommand
    if lift > 0.01 then apply_relative_force(vehicle, 0.0, 0.0, lift) end

    local neutral_pitch = tune.roadPitchTorque * speed_factor * 0.06
    local pitch_target = clamp(
        neutral_pitch + pull_up * tune.roadPitchTorque * speed_factor,
        -0.050,
        0.058
    ) * road_control_scale
    local roll_target = clamp(-steer * 0.019 * speed_factor, -0.024, 0.024)
        * road_control_scale
    state.roadPitchCommand = exp_approach(
        state.roadPitchCommand,
        pitch_target,
        tune.roadControlSharpness,
        dt
    )
    state.roadRollCommand = exp_approach(
        state.roadRollCommand,
        roll_target,
        tune.roadControlSharpness,
        dt
    )
    apply_relative_torque(vehicle, state.roadPitchCommand, state.roadRollCommand, 0.0)

    state.forward_speed = forward_speed
    state.lift_support = speed_factor
    state.appliedLift = lift
    state.control_authority = speed_factor * road_control_scale
    state.landingSensitivity = road_control_scale
    state.takeoffControlScale = pull_up
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- impact, stall and recovery model
-- ═══════════════════════════════════════════════════════════════════════════════════

local function register_air_impact(vehicle, now, collided, speed, vertical_speed, height)
    local collision_edge = collided and not state.collidedLastFrame
    state.collidedLastFrame = collided

    if not collision_edge or now < state.impactCooldownUntil or height < 0.9 then
        return
    end

    local sudden_loss = state.previousSpeed - speed
    local vertical_impact = math.abs(state.previousVerticalSpeed) >= 4.5
    local meaningful_impact = speed >= 9.0 or sudden_loss >= 3.5 or vertical_impact
    if not meaningful_impact then return end

    local severe_impact = sudden_loss >= tune.severeAirImpactSpeedLoss
        or math.abs(state.previousVerticalSpeed) >= tune.severeAirImpactVerticalSpeed
        or (state.previousSpeed >= tune.severeAirImpactFastSpeed
            and sudden_loss >= tune.severeAirImpactFastLoss)
    if severe_impact then
        state.crashDisqualified = true
        state.crashReason = "severe airborne collision"
    end

    state.impactStartedAt = now
    state.impactCooldownUntil = now + tune.impactCooldownMs
    state.previousPhase = state.phase
    state.phase = phase.IMPACT
end

local function get_impact_multiplier(now)
    local elapsed = now - state.impactStartedAt
    if elapsed < 0 or elapsed >= tune.impactRecoveryMs then return 1.0 end
    if elapsed <= tune.impactDeadTimeMs then return 0.04 end

    local recovery = smoothstep(
        tune.impactDeadTimeMs,
        tune.impactRecoveryMs,
        elapsed
    )
    return lerp(0.10, 1.0, recovery)
end

local function select_flight_phase(speed_support, alignment_support, impact_multiplier, vertical_speed)
    local prior = state.phase

    if state.groundFrames > 0 then
        state.phase = phase.LANDING
        if prior ~= state.phase then state.previousPhase = prior end
        return
    end

    if impact_multiplier < 0.20 then
        state.phase = phase.IMPACT
    elseif state.forward_speed < state.stallSpeed * 0.80 or alignment_support < 0.24 then
        state.phase = vertical_speed < -4.5 and phase.FALL or phase.STALL
    elseif speed_support < 0.42 and vertical_speed < -3.0 then
        state.phase = phase.FALL
    elseif (prior == phase.STALL or prior == phase.FALL or prior == phase.IMPACT)
        and speed_support > 0.52 and alignment_support > 0.58 then
        state.phase = phase.RECOVER
        state.recoveryFrames = 0
    elseif prior == phase.RECOVER and state.recoveryFrames < 55 then
        state.phase = phase.RECOVER
        state.recoveryFrames = state.recoveryFrames + 1
    elseif state.flightBlend < 0.88 then
        state.phase = phase.TAKEOFF
    else
        state.phase = phase.FLIGHT
    end

    if prior ~= state.phase then state.previousPhase = prior end
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- airborne phase
-- ═══════════════════════════════════════════════════════════════════════════════════

local function apply_air_flight_physics(vehicle, throttle, brake, steer, pitch_input, yaw, handbrake, dt)
    local now = game_time()
    state.flightBlend = exp_approach(
        state.flightBlend,
        1.0,
        tune.takeoffBlendSharpness,
        dt
    )
    local transition_blend = smoothstep(0.0, 1.0, state.flightBlend)

    local side_speed, forward_local, vertical_local = invoke_v3(
        native_hash.GET_ENTITY_SPEED_VECTOR,
        vehicle,
        true
    )
    local _, _, vertical_world = invoke_v3(native_hash.GET_ENTITY_VELOCITY, vehicle)
    local speed = invoke_float(native_hash.GET_ENTITY_SPEED, vehicle)
    local height = invoke_float(native_hash.GET_ENTITY_HEIGHT_ABOVE_GROUND, vehicle)
    local pitch = invoke_float(native_hash.GET_ENTITY_PITCH, vehicle)
    local roll = invoke_float(native_hash.GET_ENTITY_ROLL, vehicle)
    local heading = invoke_float(native_hash.GET_ENTITY_HEADING, vehicle)
    local upright = invoke_float(native_hash.GET_ENTITY_UPRIGHT_VALUE, vehicle)
    local upside_down = invoke_bool(native_hash.IS_ENTITY_UPSIDEDOWN, vehicle)
    local collided = invoke_bool(native_hash.HAS_ENTITY_COLLIDED_WITH_ANYTHING, vehicle)
    local guide_x, guide_y, guide_z = update_guidance_target(vehicle, pitch, heading, dt)

    local forward_speed = math.max(0.0, forward_local)
    local raw_direction_alignment = speed > 0.5
        and clamp(forward_local / speed, -1.0, 1.0)
        or 0.0
    local direction_alignment = clamp(raw_direction_alignment, 0.0, 1.0)
    local speed_support = smoothstep(state.stallSpeed - 2.0, state.cruiseSpeed, forward_speed)
    local total_speed_support = smoothstep(state.stallSpeed - 2.0, state.cruiseSpeed, speed)
    local alignment_support = smoothstep(0.22, 0.78, direction_alignment)

    local pitch_penalty = 1.0 - 0.72 * smoothstep(48.0, 82.0, math.abs(pitch))

    register_air_impact(vehicle, now, collided, speed, vertical_world, height)
    local impact_multiplier = get_impact_multiplier(now)

    local lift_support = speed_support * alignment_support * pitch_penalty * impact_multiplier
    if upside_down then
        -- preserve some aerodynamic force while inverted, but never turn an
        -- inverted car into a stable hovering platform.
        lift_support = lift_support * 0.58
    end

    if state.groundFrames > 0 then
        lift_support = lift_support * clamp(1.0 - state.groundFrames / 10.0, 0.0, 1.0)
    end

    local lift = tune.maximumLift * state.vehicleForceScale * lift_support
    local takeoff_lift_scale = lerp(
        tune.takeoffInitialLiftScale,
        1.0,
        transition_blend
    )
    local carried_road_lift = state.roadLiftCommand * (1.0 - transition_blend) * 0.42
    lift = lift * takeoff_lift_scale + carried_road_lift

    if height < 4.5 and vertical_world < 0.5 and lift_support > 0.35 then
        local ground_effect = (1.0 - clamp(height / 4.5, 0.0, 1.0))
        lift = lift + tune.groundEffectLift * ground_effect * lift_support
    end

    local coast_amount = 1.0 - clamp(throttle + brake, 0.0, 1.0)
    local thrust = tune.coastThrust * coast_amount + tune.maximumThrust * throttle
    thrust = thrust * (1.0 - brake)
    thrust = thrust * lerp(tune.takeoffInitialThrustScale, 1.0, transition_blend)
    if handbrake then thrust = thrust * 0.88 end

    local bank_amount = clamp(math.abs(roll) / 55.0, 0.0, 1.0)
    local turn_command = clamp(
        math.max(math.abs(steer), math.abs(yaw), bank_amount),
        0.0,
        1.0
    )
    local direction_authority = total_speed_support * impact_multiplier
        * lerp(0.35, 1.0, transition_blend)
        * (1.0 + turn_command * tune.directionTurnBoost)
    direction_authority = clamp(direction_authority, 0.0, 1.35)

    local side_correction = clamp(
        -side_speed * tune.sideSlipDrag * direction_authority,
        -tune.maximumDirectionForce,
        tune.maximumDirectionForce
    )
    local vertical_correction = clamp(
        -vertical_local * tune.verticalDirectionDrag * direction_authority,
        -tune.maximumDirectionForce,
        tune.maximumDirectionForce
    )

    local off_axis_speed = math.sqrt(side_speed * side_speed + vertical_local * vertical_local)
    local direction_thrust = clamp(
        off_axis_speed * tune.directionRecoveryThrust * direction_authority,
        0.0,
        tune.maximumDirectionThrust
    )

    local forward_resistance = tune.forwardDrag + tune.coastExtraDrag * coast_amount
    local drag_y = -math.max(0.0, forward_local) * forward_resistance
    drag_y = drag_y - brake * (
        tune.airbrakeDrag + math.max(0.0, forward_local) * tune.airbrakeSpeedDrag
    )
    local turn_resistance = (
        tune.turnInputDrag * math.max(math.abs(steer), math.abs(yaw))
        + tune.bankInducedDrag * bank_amount * bank_amount
    ) * speed_support
    drag_y = drag_y - turn_resistance

    apply_relative_force(
        vehicle,
        side_correction,
        thrust + direction_thrust + drag_y,
        lift + vertical_correction
    )

    local nose_velocity_blend = align_velocity_to_guidance(
        vehicle,
        guide_x,
        guide_y,
        guide_z,
        speed,
        total_speed_support,
        impact_multiplier,
        transition_blend,
        turn_command,
        dt
    )

    local landing_control_scale = 1.0
    if state.groundFrames > 0 then
        local settle = smoothstep(
            1.0,
            tune.landingControlFrames,
            state.groundFrames
        )
        landing_control_scale = lerp(
            tune.landingTouchdownControl,
            tune.landingSettledControl,
            settle
        )
    end

    local control_authority = lerp(0.16, 1.0, speed_support)
        * lerp(0.34, 1.0, alignment_support)
        * lerp(0.22, 1.0, impact_multiplier)
        * lerp(tune.takeoffInitialControlScale, 1.0, transition_blend)

    update_attitude_rates(pitch, roll, heading, dt)

    local pitch_torque, roll_torque, yaw_torque = calculate_aircraft_torques(
        pitch,
        roll,
        pitch_input,
        steer,
        yaw,
        control_authority,
        speed,
        transition_blend,
        landing_control_scale,
        state.guidance_pitch_error,
        state.guidance_yaw_error,
        state.guidance_blend,
        dt
    )

    local stall_severity = 1.0 - speed_support * alignment_support
    if height > 1.5 and stall_severity > 0.28 then
        pitch_torque = clamp(
            pitch_torque - tune.stallNoseDrop * stall_severity * control_authority,
            -tune.maximumPitchTorque * state.controlTorqueScale,
            tune.maximumPitchTorque * state.controlTorqueScale
        )
    end

    apply_relative_torque(vehicle, pitch_torque, roll_torque, yaw_torque)
    update_stunt_stats(height, dt)
    update_speed_bobbing(speed, dt)

    state.speed = speed
    state.forward_speed = forward_speed
    state.vertical_speed = vertical_world
    state.height = height
    state.pitch = pitch
    state.roll = roll
    state.upright = upright
    state.lift_support = lift_support
    state.appliedLift = lift
    state.control_authority = control_authority * landing_control_scale
    state.landingSensitivity = landing_control_scale
    state.impact_multiplier = impact_multiplier
    if state.direction_alignment == 1.0 or nose_velocity_blend <= 0.0 then
        state.direction_alignment = direction_alignment
    end
    state.direction_authority = direction_authority
    state.nose_velocity_blend = nose_velocity_blend
    state.turn_resistance = turn_resistance

    select_flight_phase(speed_support, alignment_support, impact_multiplier, vertical_world)

    state.previousSpeed = speed
    state.previousVerticalSpeed = vertical_world
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- complete physics tick
-- ═══════════════════════════════════════════════════════════════════════════════════

local function update_flying_car(vehicle)
    invoke_void(native_hash.SET_VEHICLE_GRAVITY, vehicle, true)

    local dt = clamp(invoke_float(native_hash.GET_FRAME_TIME), 1.0 / 240.0, 0.05)
    local throttle, brake, steer, pitch_input, yaw, handbrake = get_inputs(dt)
    local speed = invoke_float(native_hash.GET_ENTITY_SPEED, vehicle)
    local height = invoke_float(native_hash.GET_ENTITY_HEIGHT_ABOVE_GROUND, vehicle)
    local in_air = invoke_bool(native_hash.IS_ENTITY_IN_AIR, vehicle)
    local all_wheels = invoke_bool(native_hash.IS_VEHICLE_ON_ALL_WHEELS, vehicle)
    local _, forward_local = invoke_v3(native_hash.GET_ENTITY_SPEED_VECTOR, vehicle, true)
    local _, _, vertical_world = invoke_v3(native_hash.GET_ENTITY_VELOCITY, vehicle)

    state.speed = speed
    state.forward_speed = math.max(0.0, forward_local)
    state.vertical_speed = vertical_world
    state.height = height
    state.pitch = invoke_float(native_hash.GET_ENTITY_PITCH, vehicle)
    state.roll = invoke_float(native_hash.GET_ENTITY_ROLL, vehicle)
    state.upright = invoke_float(native_hash.GET_ENTITY_UPRIGHT_VALUE, vehicle)

    local clearly_airborne = in_air or height > 0.72
    if clearly_airborne then
        state.airFrames = state.airFrames + 1
    else
        state.airFrames = 0
    end

    if not state.activeFlight then
        state.phase = phase.GROUND
        apply_road_flight_effects(vehicle, throttle, steer, pitch_input, dt)

        -- A bump, hill crest or deliberate pull-up starts the flight only when
        -- enough forward energy exists. Crawling cars cannot levitate.
        local launch_energy = state.forward_speed >= state.stallSpeed + 1.5
        if state.airFrames >= 3 and launch_energy then begin_flight(vehicle) end
        return
    end

    update_distance(vehicle)

    local settled_on_ground = (all_wheels and height < 0.90)
        or ((not in_air) and height < 1.15 and math.abs(vertical_world) < 2.2)

    if settled_on_ground then
        if state.groundFrames == 0 then
            capture_touchdown(vehicle, speed, vertical_world)
        end
        state.groundFrames = state.groundFrames + 1
        state.phase = phase.LANDING
    else
        state.groundFrames = 0
    end

    apply_air_flight_physics(vehicle, throttle, brake, steer, pitch_input, yaw, handbrake, dt)

    if state.groundFrames >= tune.landingFrames then finish_flight("landing") end
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- direction mode, features and saved settings
-- ═══════════════════════════════════════════════════════════════════════════════════

local enabled_feature
local direction_mode_feature
local syncing_direction_feature = false
local syncing_enabled_feature = false

local function direction_mode_name(mode)
    return mode == "camera" and "Gameplay Camera" or "Vehicle Nose"
end

local function set_direction_mode(mode, announce, sync_feature)
    mode = mode == "camera" and "camera" or "vehicle"
    local changed = state.directionMode ~= mode
    state.directionMode = mode
    config.directionMode = mode

    state.guideReady = false
    state.guidance_blend = 0.0

    if sync_feature and direction_mode_feature then
        local wanted = mode == "camera" and 1 or 0
        if direction_mode_feature:GetListIndex() ~= wanted then
            syncing_direction_feature = true
            direction_mode_feature:SetListIndex(wanted)
            syncing_direction_feature = false
        end
    end

    if changed then
        save_config()
        if announce then
            toast("Direction mode: " .. direction_mode_name(mode), 2600)
        end
    end
end

local function try_toggle_direction_mode()
    if not state.enabled then
        toast("Enable Flying Cars first.", 2200)
        return false
    end
    if get_local_vehicle() == 0 then
        toast("Enter the driver's seat of a supported car first.", 2800)
        return false
    end
    set_direction_mode(
        state.directionMode == "camera" and "vehicle" or "camera",
        true,
        true
    )
    return true
end

local function save_toggle(field, value)
    config[field] = value == true
    save_config()
end

enabled_feature = FeatureMgr.AddFeature(
    feature_hash.enabled,
    "Flying Cars",
    eFeatureType.Toggle,
    "San Andreas-style flying-car physics with vehicle-nose or camera-guided flight.",
    function(feature)
        if syncing_enabled_feature then return end

        local wants_enabled = feature:IsToggled()
        if wants_enabled and get_local_vehicle() == 0 then
            state.enabled = false
            syncing_enabled_feature = true
            feature:SetBoolValue(false)
            syncing_enabled_feature = false
            toast("Enter the driver's seat of a supported car first.", 3000)
            return
        end

        state.enabled = wants_enabled
        if state.enabled then
            math.randomseed(os.time())
            toast(
                "Flying Cars enabled. " .. key_name(config.modeToggle)
                    .. " switches Vehicle Nose / Gameplay Camera.",
                4500
            )
        else
            restore_vehicle(state.vehicle)
            reset_run()
            state.landingCooldownUntil = 0
            state.vehicle = 0
            toast("Flying Cars disabled.", 2500)
        end
    end
)
enabled_feature:SetBoolValue(false)

direction_mode_feature = FeatureMgr.AddFeature(
    feature_hash.directionMode,
    "Direction Mode",
    eFeatureType.Combo,
    "Vehicle Nose follows the car's forward axis. Gameplay Camera smoothly guides the car and its momentum toward the camera.",
    function(feature)
        if syncing_direction_feature then return end
        if not state.enabled or get_local_vehicle() == 0 then
            syncing_direction_feature = true
            feature:SetListIndex(state.directionMode == "camera" and 1 or 0)
            syncing_direction_feature = false
            toast("Enable Flying Cars from a supported driver's seat first.", 2800)
            return
        end
        set_direction_mode(feature:GetListIndex() == 1 and "camera" or "vehicle", false, false)
    end
)
direction_mode_feature:SetList({[0] = "Vehicle Nose", [1] = "Gameplay Camera"})
syncing_direction_feature = true
direction_mode_feature:SetListIndex(config.directionMode == "camera" and 1 or 0)
syncing_direction_feature = false

local hud_feature = FeatureMgr.AddFeature(
    feature_hash.hud,
    "Flight HUD",
    eFeatureType.Toggle,
    "Shows phase, direction mode, live airborne distance, speed and all-time best.",
    function(feature)
        state.showHud = feature:IsToggled()
        save_toggle("showHud", state.showHud)
    end
)
hud_feature:SetBoolValue(config.showHud)

local stunt_stats_feature = FeatureMgr.AddFeature(
    feature_hash.stuntStats,
    "SA Stunt Stats",
    eFeatureType.Toggle,
    "Shows the classic Distance, Height, Flips and Rotation readout at the top of the screen.",
    function(feature)
        state.showStuntStats = feature:IsToggled()
        save_toggle("showStuntStats", state.showStuntStats)
    end
)
stunt_stats_feature:SetBoolValue(config.showStuntStats)

local speed_bob_feature = FeatureMgr.AddFeature(
    feature_hash.speedBob,
    "High-Speed Screen Bobbing",
    eFeatureType.Toggle,
    "Adds speed-scaled San Andreas-style camera vibration without changing vehicle control or physics.",
    function(feature)
        state.speedBobbing = feature:IsToggled()
        save_toggle("speedBobbing", state.speedBobbing)
        if not state.speedBobbing then stop_speed_bobbing() end
    end
)
speed_bob_feature:SetBoolValue(config.speedBobbing)

local telemetry_feature = FeatureMgr.AddFeature(
    feature_hash.telemetry,
    "Physics Telemetry",
    eFeatureType.Toggle,
    "Shows lift, control authority, attitude rates and guidance diagnostics for testing.",
    function(feature)
        state.telemetry = feature:IsToggled()
        save_toggle("telemetry", state.telemetry)
    end
)
telemetry_feature:SetBoolValue(config.telemetry)

FeatureMgr.AddFeature(
    feature_hash.resetBest,
    "Reload High Scores",
    eFeatureType.Button,
    "Reloads the persistent Top 10 leaderboard from disk.",
    function()
        load_high_scores(true)
        state.lastResult = "High scores reloaded."
        toast(state.lastResult, 2500)
    end
)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- configurable keyboard shortcuts
-- ═══════════════════════════════════════════════════════════════════════════════════

local keybind_ui = {
    capturing = nil,
    started_at = 0,
    states = {},
}

local keybind_rows = {
    {field = "activation", label = "Activate Flying Cars", default = default_keys.activation},
    {field = "modeToggle", label = "Toggle Direction Mode", default = default_keys.modeToggle},
    {field = "pitchUp", label = "Nose Up", default = default_keys.pitchUp},
    {field = "pitchDown", label = "Nose Down", default = default_keys.pitchDown},
    {field = "turnLeft", label = "Bank / Turn Left", default = default_keys.turnLeft},
    {field = "turnRight", label = "Bank / Turn Right", default = default_keys.turnRight},
}

local function begin_key_capture(field)
    keybind_ui.capturing = field
    keybind_ui.started_at = game_time()
    keybind_ui.states = {}
    for vk = 8, 254 do
        keybind_ui.states[vk] = key_down(vk)
    end
end

local function process_key_capture()
    if not keybind_ui.capturing then return end
    local can_capture = game_time() - keybind_ui.started_at >= 350

    for vk = 8, 254 do
        local down = key_down(vk)
        local was_down = keybind_ui.states[vk] == true
        keybind_ui.states[vk] = down

        if can_capture and down and not was_down then
            if vk == 0x1B then
                keybind_ui.capturing = nil
                toast("Keybind change cancelled.", 1800)
                return
            end

            local field = keybind_ui.capturing
            config[field] = vk
            keybind_ui.capturing = nil
            save_config()
            toast("Keybind saved: " .. key_name(vk), 2200)
            return
        end
    end
end

local function reset_keybinds()
    for _, row in ipairs(keybind_rows) do
        config[row.field] = row.default
    end
    keybind_ui.capturing = nil
    save_config()
    toast("Flying Cars keybinds restored to defaults.", 2600)
end

local shortcut_previous = {}

local function key_just_pressed(vk)
    local down = key_down(vk)
    local pressed = down and shortcut_previous[vk] ~= true
    shortcut_previous[vk] = down
    return pressed
end

local function update_shortcut_state()
    shortcut_previous[config.activation] = key_down(config.activation)
    shortcut_previous[config.modeToggle] = key_down(config.modeToggle)
end

local function gui_open()
    return GUI.IsOpen() == true
end

-- ═══════════════════════════════════════════════════════════════════════════════════
-- runtime loop
-- note: shortcuts and physics share one vehicle lookup and one zero-delay scheduler.
-- ═══════════════════════════════════════════════════════════════════════════════════

Script.RegisterLooped(function()
    if ShouldUnload() then
        stop_speed_bobbing()
        restore_vehicle(state.vehicle)
        return false
    end

    local input_blocked = keybind_ui.capturing ~= nil or gui_open()
    if input_blocked then update_shortcut_state() end

    local vehicle = get_local_vehicle()
    if not input_blocked then
        local was_enabled = state.enabled
        local activate_pressed = key_just_pressed(config.activation)
        local mode_pressed = key_just_pressed(config.modeToggle)

        if not was_enabled and activate_pressed and enabled_feature then
            if vehicle ~= 0 then
                enabled_feature:Toggle()
            else
                toast("Enter the driver's seat of a supported car first.", 2800)
            end
        elseif was_enabled and mode_pressed then
            if vehicle ~= 0 then
                try_toggle_direction_mode()
            else
                toast("Direction mode only changes while driving a supported car.", 2800)
            end
        end
    end

    if not state.enabled then
        Script.Yield(0)
        return
    end

    if vehicle == 0 then
        if state.vehicle ~= 0 then
            restore_vehicle(state.vehicle)
            if state.activeFlight then finish_flight("driver seat lost") else reset_run() end
        end
        state.vehicle = 0
        Script.Yield(50)
        return
    end

    if state.vehicle ~= vehicle then
        if state.vehicle ~= 0 then
            restore_vehicle(state.vehicle)
            if state.activeFlight then finish_flight("vehicle changed") else reset_run() end
        end
        state.vehicle = vehicle
        state.landingCooldownUntil = 0
        configure_vehicle_profile(vehicle)
    end

    update_flying_car(vehicle)
    Script.Yield(0)
end)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- presentation-synchronized overlay
-- ═══════════════════════════════════════════════════════════════════════════════════

local function centered_overlay_text(text, y, r, g, b, a, display_width)
    local estimated_width = #tostring(text) * 7.0
    local x = display_width * 0.5 - estimated_width * 0.5
    ImGui.BgAddText(x + 1, y + 1, text, 0, 0, 0, math.min(a, 220))
    ImGui.BgAddText(x, y, text, r, g, b, a)
end

local function draw_large_centered_text(text, x, y, scale, r, g, b, a, font)
    text = tostring(text or "")
    if text == "" then return end

    invoke_void(native_hash.SET_TEXT_FONT, font or 7)
    invoke_void(native_hash.SET_TEXT_SCALE, scale, scale)
    invoke_void(native_hash.SET_TEXT_COLOUR, r or 255, g or 255, b or 255, a or 255)
    invoke_void(native_hash.SET_TEXT_CENTRE, true)
    invoke_void(native_hash.SET_TEXT_OUTLINE)
    invoke_void(native_hash.BEGIN_TEXT_COMMAND_DISPLAY_TEXT, "STRING")
    invoke_void(native_hash.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME, text)
    invoke_void(native_hash.END_TEXT_COMMAND_DISPLAY_TEXT, x, y)
end

local function render_landing_banner(display_width, display_height)
    local text = tostring(state.landingBannerText or "")
    local started_at = tonumber(state.landingBannerStartedAt or 0) or 0
    if text == "" or started_at <= 0 then return end

    local elapsed = game_time() - started_at
    local life = tune.landingBannerLifeMs
    if elapsed < 0 or elapsed >= life then
        state.landingBannerText = ""
        state.landingBannerDetail = ""
        state.landingBannerStartedAt = 0
        return
    end

    local t = clamp(elapsed / life, 0.0, 1.0)
    local x
    if t < 0.24 then
        local p = smoothstep(0.0, 0.24, t)
        x = -0.34 + 0.84 * p
    elseif t < 0.68 then
        x = 0.50
    else
        local p = smoothstep(0.68, 1.0, t)
        x = 0.50 + 0.92 * p
    end

    local alpha = 255
    if t > 0.76 then
        alpha = math.max(0, math.floor(255 * (1.0 - ((t - 0.76) / 0.24))))
    end

    local y = 0.405
    if t > 0.62 then y = y + math.sin(t * 34.0) * 0.004 end

    local bad = state.landingBannerBad == true
    local r, g, b = bad and 255 or 90, bad and 70 or 255, bad and 70 or 135
    local detail = tostring(state.landingBannerDetail or "")

    draw_large_centered_text(text, x, y - 0.020, 0.72, r, g, b, alpha, 7)
    if detail ~= "" then
        draw_large_centered_text(detail, x, y + 0.036, 0.46, 255, 255, 255, alpha, 7)
    end
end

local function render_flight_overlay()
    local display_width, display_height = ImGui.GetDisplaySize()
    if not display_width or not display_height then return end

    render_landing_banner(display_width, display_height)
    if not state.enabled then return end

    if state.activeFlight and state.showStuntStats then
        centered_overlay_text(
            string.format(
                "Distance: %dft  Height: %dft  Flips: %d",
                meters_to_feet(state.runDistance),
                meters_to_feet(state.maxHeight),
                state.flipCount
            ),
            22, 205, 218, 209, 255, display_width
        )
        centered_overlay_text(
            string.format("Rotation: %d°", math.floor(state.rotationDegrees + 0.5)),
            40, 205, 218, 209, 255, display_width
        )
    end

    if not state.showHud then return end

    if not state.activeFlight then
        local prompt = string.format(
            "Flying Cars armed — build speed | %s: %s",
            key_name(config.modeToggle),
            direction_mode_name(state.directionMode)
        )
        centered_overlay_text(prompt, display_height - 72, 235, 235, 235, 235, display_width)
        return
    end

    local phase_r, phase_g, phase_b = 255, 210, 65
    if state.phase == phase.STALL or state.phase == phase.FALL then
        phase_r, phase_g, phase_b = 255, 100, 75
    elseif state.phase == phase.IMPACT then
        phase_r, phase_g, phase_b = 255, 65, 65
    elseif state.phase == phase.RECOVER then
        phase_r, phase_g, phase_b = 110, 230, 150
    elseif state.phase == phase.LANDING then
        phase_r, phase_g, phase_b = 130, 205, 255
    end

    local extra_lines = state.telemetry and 3 or 0
    local panel_height = 92 + extra_lines * 18
    local panel_top = display_height - panel_height - 18
    ImGui.BgAddRectFilled(
        display_width * 0.5 - 315,
        panel_top - 8,
        display_width * 0.5 + 315,
        display_height - 15,
        0, 0, 0, 105, 6.0
    )

    local mode_text = state.directionMode == "camera" and "CAMERA GUIDE" or "VEHICLE NOSE"
    centered_overlay_text(
        "FLYING CARS — " .. state.phase .. " — " .. mode_text,
        panel_top,
        phase_r, phase_g, phase_b, 255, display_width
    )
    centered_overlay_text(
        "Distance: " .. format_distance(state.runDistance)
            .. "   |   " .. format_speed(state.speed)
            .. "   |   All-time: " .. format_distance(state.bestDistance),
        panel_top + 20,
        255, 255, 255, 245, display_width
    )
    centered_overlay_text(
        key_name(config.modeToggle) .. " switches direction mode",
        panel_top + 40,
        190, 220, 255, 230, display_width
    )

    local warning = nil
    local warning_r, warning_g, warning_b = 255, 125, 90
    if state.phase == phase.STALL then
        warning = "STALL — point the nose down and rebuild speed"
    elseif state.phase == phase.FALL or state.phase == phase.IMPACT then
        warning = "FALLING — dive for speed, then pull out"
    elseif state.phase == phase.RECOVER then
        warning = "LIFT RETURNING — pull out smoothly"
        warning_r, warning_g, warning_b = 125, 240, 165
    end
    if warning then
        centered_overlay_text(warning, panel_top + 60, warning_r, warning_g, warning_b, 245, display_width)
    end

    if state.telemetry then
        local telemetry_y = panel_top + 78
        centered_overlay_text(
            string.format(
                "FWD %.1f  V/S %.1f  LIFT %.2f/%.2f  CTRL %.2f",
                state.forward_speed,
                state.vertical_speed,
                state.lift_support,
                state.appliedLift,
                state.control_authority
            ),
            telemetry_y, 220, 220, 220, 225, display_width
        )
        centered_overlay_text(
            string.format(
                "PITCH %.1f (%.1f/%.1f)  ROLL %.1f (%.1f/%.1f)",
                state.pitch,
                state.pitchRate,
                state.desired_pitch_rate,
                state.roll,
                state.rollRate,
                state.desired_roll_rate
            ),
            telemetry_y + 18, 210, 210, 210, 215, display_width
        )
        centered_overlay_text(
            string.format(
                "ALIGN %.2f  GUIDE %.2f  ERR P%.1f/Y%.1f  LAND %.2f",
                state.direction_alignment,
                state.guidance_blend,
                state.guidance_pitch_error,
                state.guidance_yaw_error,
                state.landingSensitivity
            ),
            telemetry_y + 36, 200, 200, 200, 205, display_width
        )
    end
end

local overlay_handler = EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, render_flight_overlay)

-- ═══════════════════════════════════════════════════════════════════════════════════
-- clickgui presentation / credits logo
-- ═══════════════════════════════════════════════════════════════════════════════════

local ui_color = {
    purple = {0.72, 0.42, 1.00, 1.00},
    blue = {0.42, 0.82, 1.00, 1.00},
    cyan = {0.35, 0.95, 1.00, 1.00},
    green = {0.36, 1.00, 0.55, 1.00},
    soft_green = {0.70, 0.92, 0.76, 1.00},
    gold = {1.00, 0.78, 0.18, 1.00},
    orange = {1.00, 0.52, 0.16, 1.00},
    red = {1.00, 0.28, 0.28, 1.00},
    white = {0.96, 0.97, 1.00, 1.00},
    soft = {0.72, 0.78, 0.88, 1.00},
    muted = {0.54, 0.60, 0.70, 1.00},
}

local logo_dir = config_dir .. "assets\\"
local logo_path = logo_dir .. "Public_Urinal.png"
local logo_url = "https://raw.githubusercontent.com/xReVoLTiThemeDev/GTAV-Cherax/refs/heads/main/Public_Urinal.png"

local logo_state = {
    texture_id = nil,
    srv = nil,
    path = nil,
    download_started = false,
    download_state = "idle",
    error = nil,
}

local function ui_text(text, color, wrapped)
    color = color or ui_color.white
    if wrapped and ImGui.TextWrapped then
        if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
            ImGui.PushStyleColor(ImGuiCol.Text, color[1], color[2], color[3], color[4])
            ImGui.TextWrapped(tostring(text or ""))
            ImGui.PopStyleColor()
        else
            ImGui.TextWrapped(tostring(text or ""))
        end
        return
    end

    if ImGui.TextColored then
        ImGui.TextColored(color[1], color[2], color[3], color[4], tostring(text or ""))
    else
        ImGui.Text(tostring(text or ""))
    end
end

local function ui_label_value(label, value, label_color, value_color)
    ui_text(label, label_color or ui_color.soft)
    if ImGui.SameLine then ImGui.SameLine() end
    ui_text(value, value_color or ui_color.white)
end

local function ui_separator()
    if ImGui.Separator then ImGui.Separator() end
end

local function ui_spacing()
    if ImGui.Spacing then ImGui.Spacing() end
end

local function ui_push_text(color)
    if ImGui.PushStyleColor and ImGuiCol and ImGuiCol.Text then
        ImGui.PushStyleColor(ImGuiCol.Text, color[1], color[2], color[3], color[4])
        return true
    end
    return false
end

local function ui_pop_text(pushed)
    if pushed and ImGui.PopStyleColor then ImGui.PopStyleColor() end
end

local function ui_render_feature(hash, color)
    local pushed = ui_push_text(color or ui_color.white)
    ClickGUI.RenderFeature(hash)
    ui_pop_text(pushed)
end

local function ui_button(label, palette, width, height)
    palette = palette or {
        normal = {0.28, 0.16, 0.46, 1.00},
        hover = {0.40, 0.24, 0.62, 1.00},
        active = {0.22, 0.11, 0.38, 1.00},
        text = ui_color.white,
    }

    local pushed = 0
    if ImGui.PushStyleColor and ImGuiCol then
        if ImGuiCol.Button then
            ImGui.PushStyleColor(ImGuiCol.Button, palette.normal[1], palette.normal[2], palette.normal[3], palette.normal[4])
            pushed = pushed + 1
        end
        if ImGuiCol.ButtonHovered then
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, palette.hover[1], palette.hover[2], palette.hover[3], palette.hover[4])
            pushed = pushed + 1
        end
        if ImGuiCol.ButtonActive then
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, palette.active[1], palette.active[2], palette.active[3], palette.active[4])
            pushed = pushed + 1
        end
        if ImGuiCol.Text and palette.text then
            ImGui.PushStyleColor(ImGuiCol.Text, palette.text[1], palette.text[2], palette.text[3], palette.text[4])
            pushed = pushed + 1
        end
    end

    local clicked = ImGui.Button(label, width or -1, height or 0)
    if pushed > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(pushed) end
    return clicked == true
end

local button_purple = {
    normal = {0.31, 0.16, 0.50, 1.00},
    hover = {0.44, 0.25, 0.67, 1.00},
    active = {0.24, 0.11, 0.40, 1.00},
    text = ui_color.white,
}

local button_blue = {
    normal = {0.10, 0.34, 0.56, 1.00},
    hover = {0.15, 0.46, 0.72, 1.00},
    active = {0.07, 0.27, 0.47, 1.00},
    text = ui_color.white,
}

local button_green = {
    normal = {0.08, 0.43, 0.22, 1.00},
    hover = {0.12, 0.58, 0.30, 1.00},
    active = {0.06, 0.34, 0.17, 1.00},
    text = ui_color.white,
}

local button_red = {
    normal = {0.48, 0.12, 0.12, 1.00},
    hover = {0.64, 0.18, 0.18, 1.00},
    active = {0.38, 0.08, 0.08, 1.00},
    text = ui_color.white,
}

local button_gold = {
    normal = {0.52, 0.36, 0.05, 1.00},
    hover = {0.68, 0.49, 0.09, 1.00},
    active = {0.42, 0.27, 0.03, 1.00},
    text = ui_color.white,
}

local function ui_dir_name(path)
    return tostring(path or ""):match("^(.*)[/\\][^/\\]+$")
end

local function ui_looks_like_png(body)
    return type(body) == "string"
        and #body >= 100
        and body:byte(1) == 137
        and body:sub(2, 4) == "PNG"
end

local function set_curl_option(curl, name, fallback, value)
    local option = eCurlOption and eCurlOption[name] or fallback
    curl:Setopt(option, value)
end

local function queue_logo_download(path)
    if logo_state.download_started or logo_state.download_state == "loading" then return end
    if not Curl or not Curl.Easy or not Script or not Script.QueueJob then
        logo_state.download_state = "unavailable"
        return
    end

    logo_state.download_started = true
    logo_state.download_state = "loading"

    Script.QueueJob(function()
        local ok, err = pcall(function()
            local curl = Curl.Easy()
            set_curl_option(curl, "CURLOPT_URL", 10002, logo_url)
            set_curl_option(curl, "CURLOPT_USERAGENT", 10018, "Flying-Cars-SA-Cherax")
            curl:Perform()

            local ticks = 0
            while not curl:GetFinished() and ticks < 300 do
                Script.Yield(50)
                ticks = ticks + 1
            end

            if not curl:GetFinished() then
                logo_state.download_state = "timeout"
                return
            end

            local code, body = curl:GetResponse()
            local success = code == true or code == 0
                or (eCurlCode and code == eCurlCode.CURLE_OK)
            if not success or not ui_looks_like_png(body) then
                logo_state.download_state = "failed"
                return
            end

            local directory = ui_dir_name(path)
            if directory and directory ~= "" then FileMgr.CreateDir(directory) end
            local file = io.open(path, "wb")
            if not file then
                logo_state.download_state = "write_failed"
                return
            end
            file:write(body)
            file:close()

            logo_state.texture_id = nil
            logo_state.srv = nil
            logo_state.path = path
            logo_state.error = nil
            logo_state.download_state = "done"
        end)

        if not ok then
            logo_state.download_state = "error"
            logo_state.error = tostring(err)
        end
    end)
end

local function resolve_logo_path()
    if logo_state.path and file_exists(logo_state.path) then return logo_state.path end

    local root = FileMgr.GetMenuRootPath()
    local candidates = {
        logo_path,
        root .. "\\Lua\\DriftGod\\assets\\Public_Urinal.png",
        root .. "\\Lua\\DriftGod\\Public_Urinal.png",
    }

    for _, path in ipairs(candidates) do
        if file_exists(path) then
            logo_state.path = path
            return path
        end
    end

    queue_logo_download(logo_path)
    logo_state.path = logo_path
    return logo_path
end

local function load_logo_texture()
    if logo_state.srv then return logo_state.srv end
    if not Texture or not Texture.LoadTexture or not Texture.GetTexture then
        logo_state.error = "Texture API unavailable"
        return nil
    end

    local path = resolve_logo_path()
    if not path or not file_exists(path) then return nil end

    local texture_id = Texture.LoadTexture(path)
    if not texture_id or tonumber(texture_id) == 0 then
        logo_state.error = "Texture load failed"
        return nil
    end
    if Texture.IsTextureValid and Texture.IsTextureValid(texture_id) ~= true then
        logo_state.error = "Texture validation failed"
        return nil
    end

    local texture = Texture.GetTexture(texture_id)
    local srv = texture and texture:GetCurrent() or nil
    if not srv then
        logo_state.error = "Texture handle failed"
        return nil
    end

    logo_state.texture_id = texture_id
    logo_state.srv = srv
    logo_state.error = nil
    return srv
end

local function draw_public_urinal_logo(size)
    size = tonumber(size) or 148.0
    local srv = load_logo_texture()
    if not srv then
        if logo_state.download_state == "loading" or logo_state.download_state == "idle" then
            ui_text("Public_Urinal.png is loading...", ui_color.soft, true)
        else
            ui_text("Public_Urinal.png could not be loaded.", ui_color.orange, true)
            if logo_state.error then ui_text(logo_state.error, ui_color.muted, true) end
        end
        return false
    end

    local x, y = ImGui.GetCursorScreenPos()
    x, y = tonumber(x) or 0.0, tonumber(y) or 0.0
    if x <= 0 or y <= 0 then return false end

    local pushed = 0
    if ImGui.PushStyleColor and ImGuiCol then
        for _, color in ipairs({ImGuiCol.Button, ImGuiCol.ButtonHovered, ImGuiCol.ButtonActive}) do
            if color then
                ImGui.PushStyleColor(color, 0.04, 0.04, 0.05, 0.00)
                pushed = pushed + 1
            end
        end
    end

    ImGui.Button("##FlyingCarsSA_PublicUrinalLogo", size, size)
    if pushed > 0 and ImGui.PopStyleColor then ImGui.PopStyleColor(pushed) end

    if ImGui.AddImageRounded then
        ImGui.AddImageRounded(srv, x, y, x + size, y + size, 0.0, 0.0, 1.0, 1.0, 0xFFFFFFFF, 10.0)
    elseif ImGui.AddImage then
        ImGui.AddImage(srv, x, y, x + size, y + size)
    else
        return false
    end
    return true
end

local function copy_text(text)
    text = tostring(text or "")
    if Utils.SetClipBoardText then
        Utils.SetClipBoardText(text, "")
        return true
    end
    if Utils.SetClipboardText then
        Utils.SetClipboardText(text)
        return true
    end
    return false
end

local function render_home_tab()
    ui_text("Flying Cars SA", ui_color.purple)
    ui_text("San Andreas-inspired vehicle flight with aircraft-style control.", ui_color.soft, true)
    ui_separator()

    local table_flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_HomeTop", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Flight") then
            ui_text("FLIGHT", ui_color.purple)
            ui_label_value("Status:", state.enabled and "ENABLED" or "DISABLED", ui_color.soft, state.enabled and ui_color.green or ui_color.red)
            ui_label_value("Direction:", direction_mode_name(state.directionMode), ui_color.soft, state.directionMode == "camera" and ui_color.blue or ui_color.gold)
            ui_spacing()

            local toggle_palette = state.enabled and button_red or button_green
            local toggle_label = state.enabled and "Disable Flying Cars" or "Enable Flying Cars"
            if ui_button(toggle_label, toggle_palette, -1, 0) and enabled_feature then
                enabled_feature:Toggle()
            end

            local target_mode = state.directionMode == "camera" and "vehicle" or "camera"
            local direction_label = target_mode == "camera" and "Switch to Gameplay Camera" or "Switch to Vehicle Nose"
            if ui_button(direction_label, button_blue, -1, 0) then
                try_toggle_direction_mode()
            end

            ui_spacing()
            ui_text(key_name(config.activation) .. " activates only from a supported driver's seat.", ui_color.gold, true)
            ui_text(key_name(config.modeToggle) .. " switches guidance only while Flying Cars is enabled in a car.", ui_color.blue, true)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Presentation") then
            ui_text("PRESENTATION", ui_color.cyan)
            ui_render_feature(feature_hash.hud, ui_color.soft_green)
            ui_render_feature(feature_hash.stuntStats, ui_color.gold)
            ui_render_feature(feature_hash.speedBob, ui_color.blue)
            ui_render_feature(feature_hash.telemetry, ui_color.orange)
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    else
        if ClickGUI.BeginCustomChildWindow("Flight") then
            ui_render_feature(feature_hash.enabled, ui_color.green)
            ui_render_feature(feature_hash.directionMode, ui_color.blue)
            ClickGUI.EndCustomChildWindow()
        end
        if ClickGUI.BeginCustomChildWindow("Presentation") then
            ui_render_feature(feature_hash.hud, ui_color.soft_green)
            ui_render_feature(feature_hash.stuntStats, ui_color.gold)
            ui_render_feature(feature_hash.speedBob, ui_color.blue)
            ui_render_feature(feature_hash.telemetry, ui_color.orange)
            ClickGUI.EndCustomChildWindow()
        end
    end

    ui_spacing()
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_HomeBottom", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Live Flight") then
            ui_text("LIVE FLIGHT", ui_color.green)
            ui_label_value("Phase:", state.phase, ui_color.soft, ui_color.white)
            ui_label_value("Current:", format_distance(state.runDistance), ui_color.soft, ui_color.cyan)
            ui_label_value("All-time:", format_distance(state.bestDistance), ui_color.soft, ui_color.gold)
            ui_label_value("Speed:", format_speed(state.speed), ui_color.soft, ui_color.white)
            ui_text("Last result", ui_color.muted)
            ui_text(state.lastResult, ui_color.soft, true)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Quick Guide") then
            ui_text("QUICK GUIDE", ui_color.blue)
            ui_text(key_name(config.pitchUp) .. "  Nose up", ui_color.gold)
            ui_text(key_name(config.pitchDown) .. "  Nose down", ui_color.cyan)
            ui_text(key_name(config.turnLeft) .. " / " .. key_name(config.turnRight) .. "  Bank and turn", ui_color.purple)
            ui_text("Accelerate  Add thrust", ui_color.green)
            ui_text("Brake  Add drag", ui_color.orange)
            ui_text("No input  Preserve a gradually slowing glide", ui_color.soft, true)
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    end
end

local function high_score_rank_color(rank)
    if rank == 1 then return ui_color.gold end
    if rank == 2 then return ui_color.cyan end
    if rank == 3 then return ui_color.orange end
    if rank <= 5 then return ui_color.purple end
    return ui_color.blue
end

local function render_high_score_record(rank, score)
    if not score then
        ui_text("#" .. tostring(rank) .. "  —", ui_color.muted)
        return
    end

    ui_text(
        "#" .. tostring(rank) .. "  " .. format_feet(score.distance),
        high_score_rank_color(rank)
    )
    ui_text(
        format_feet(score.height)
            .. " high  •  " .. tostring(math.floor(tonumber(score.flips) or 0)) .. " flips"
            .. "  •  " .. format_whole_number(score.rotation) .. "° rotation",
        ui_color.soft,
        true
    )
    ui_text(
        tostring(score.date or "Unknown")
            .. "  •  " .. direction_mode_name(score.mode),
        ui_color.muted,
        true
    )
    ui_spacing()
end

local function render_high_scores_tab()
    load_high_scores()
    ui_text("High Scores", ui_color.gold)
    ui_text("The Top 10 cleanly landed flights save automatically across script restarts.", ui_color.soft, true)
    ui_text("Crash landings are disqualified and never written to the leaderboard or score log.", ui_color.red, true)
    ui_separator()

    local table_flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_HighScores", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Top Flights") then
            ui_text("TOP FLIGHTS", ui_color.gold)
            for rank = 1, 5 do
                render_high_score_record(rank, high_scores.records[rank])
            end
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("More Records") then
            ui_text("MORE RECORDS", ui_color.blue)
            for rank = 6, high_score_limit do
                render_high_score_record(rank, high_scores.records[rank])
            end
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    end

    ui_spacing()
    if ClickGUI.BeginCustomChildWindow("High Score Storage") then
        ui_text("AUTOMATIC STORAGE", ui_color.green)
        ui_text("Leaderboard", ui_color.cyan)
        ui_text(high_scores_file, ui_color.muted, true)
        ui_text("Readable score log", ui_color.blue)
        ui_text(high_scores_log, ui_color.muted, true)
        ui_spacing()
        ui_render_feature(feature_hash.resetBest, ui_color.blue)
        ClickGUI.EndCustomChildWindow()
    end
end

local function render_controls_tab()
    ui_text("Controls", ui_color.blue)
    ui_text("The flight controller is intentionally smooth and rate-limited.", ui_color.soft, true)
    ui_separator()

    local table_flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_Controls", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Navigation") then
            ui_text("NAVIGATION", ui_color.purple)
            ui_text(key_name(config.pitchUp) .. "  Pull the nose upward", ui_color.gold)
            ui_text(key_name(config.pitchDown) .. "  Push the nose downward", ui_color.cyan)
            ui_text(key_name(config.turnLeft) .. "  Bank and turn left", ui_color.purple)
            ui_text(key_name(config.turnRight) .. "  Bank and turn right", ui_color.purple)
            ui_spacing()
            ui_text("Vehicle Nose", ui_color.gold)
            ui_text("Momentum follows the front axis of the car.", ui_color.soft, true)
            ui_spacing()
            ui_text("Gameplay Camera", ui_color.blue)
            ui_text("The chassis and momentum ease toward the camera aim.", ui_color.soft, true)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Flight Behavior") then
            ui_text("FLIGHT BEHAVIOR", ui_color.green)
            ui_text("Build road speed before pulling up.", ui_color.soft_green, true)
            ui_text("Takeoff lift grows gradually instead of launching straight upward.", ui_color.soft, true)
            ui_text("Coasting keeps the car flying while speed slowly fades.", ui_color.soft, true)
            ui_text("Braking creates strong aerodynamic resistance.", ui_color.orange, true)
            ui_text("Touchdown sharply lowers sensitivity and suppresses bounce-back lift.", ui_color.gold, true)
            ui_text("Clean landings save scores; clear crashes are disqualified with a red banner.", ui_color.green, true)
            ui_text("A stall or hard impact removes lift until speed and alignment recover.", ui_color.red, true)
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    end
end

local function render_keybind_button(row)
    local capturing = keybind_ui.capturing == row.field
    local label = capturing and ("Press any key...##" .. row.field)
        or (row.label .. ": " .. key_name(config[row.field]) .. "##" .. row.field)
    local palette = capturing and button_gold or button_purple
    if ui_button(label, palette, -1, 0) and not keybind_ui.capturing then
        begin_key_capture(row.field)
    end
end

local function render_keybinds_tab()
    ui_text("Keybinds", ui_color.purple)
    ui_text("Click a binding, then press a keyboard key. Escape cancels. Changes save immediately.", ui_color.soft, true)
    ui_separator()

    local table_flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_Keybinds", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("System") then
            ui_text("SYSTEM", ui_color.blue)
            render_keybind_button(keybind_rows[1])
            render_keybind_button(keybind_rows[2])
            ui_spacing()
            ui_text("Activation only enables the cheat while it is off and you are driving a supported car.", ui_color.muted, true)
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Flight Navigation") then
            ui_text("FLIGHT NAVIGATION", ui_color.gold)
            for i = 3, #keybind_rows do render_keybind_button(keybind_rows[i]) end
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    end

    ui_spacing()
    if ClickGUI.BeginCustomChildWindow("config") then
        ui_text("AUTO-SAVED CONFIG", ui_color.green)
        ui_text(config_file, ui_color.muted, true)
        if ui_button("Restore Default Keybinds", button_red, -1, 0) then reset_keybinds() end
        ClickGUI.EndCustomChildWindow()
    end
end

local function render_credits_tab()
    ui_text("Credits", ui_color.gold)
    ui_text("A minimal tribute to the cheat that inspired this project.", ui_color.soft, true)
    ui_separator()

    local table_flags = ImGuiTableFlags and ImGuiTableFlags.SizingStretchSame or 0
    if ImGui.BeginTable and ImGui.BeginTable("FlyingCarsSA_Credits", 2, table_flags) then
        ImGui.TableNextRow()
        ImGui.TableSetColumnIndex(0)
        if ClickGUI.BeginCustomChildWindow("Project") then
            ui_text("FLYING CARS SA", ui_color.purple)
            ui_label_value("Version:", script_version, ui_color.soft, ui_color.white)
            ui_label_value("Developed by:", "Public_Urinal", ui_color.soft, ui_color.gold)
            ui_label_value("Coding assistance:", "OpenAI ChatGPT", ui_color.soft, ui_color.blue)
            ui_spacing()
            ui_text("Inspired by", ui_color.muted)
            ui_text("Grand Theft Auto: San Andreas — Flying Cars", ui_color.green, true)
            ui_spacing()
            ui_text("Purpose", ui_color.cyan)
            ui_text("Recreate the classic flying-car feeling with modern Cherax controls, persistent keybinds, flight stats, camera effects, and no money rewards.", ui_color.soft, true)
            ui_spacing()
            ui_text("Discord", ui_color.blue)
            ui_text("discord.gg/fCG7tVZZb", ui_color.soft, true)
            if ui_button("Copy Discord Invite", button_blue, -1, 0) then
                if copy_text("https://discord.gg/fCG7tVZZb") then
                    toast("Discord invite copied.", 2200)
                else
                    toast("Clipboard API unavailable.", 2200)
                end
            end
            ClickGUI.EndCustomChildWindow()
        end

        ImGui.TableSetColumnIndex(1)
        if ClickGUI.BeginCustomChildWindow("Public_Urinal") then
            ui_text("PUBLIC_URINAL", ui_color.gold)
            draw_public_urinal_logo(150.0)
            ui_spacing()
            ui_text("Original concept, direction, testing, and handling feedback.", ui_color.soft, true)
            ClickGUI.EndCustomChildWindow()
        end
        ImGui.EndTable()
    end
end

ClickGUI.AddTab(script_name, function()
    process_key_capture()

    if ImGui.BeginTabBar and ImGui.BeginTabBar("FlyingCarsSA_SubTabs") then
        if ImGui.BeginTabItem("Home") then
            render_home_tab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("High Scores") then
            render_high_scores_tab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Controls") then
            render_controls_tab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Keybinds") then
            render_keybinds_tab()
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Credits") then
            render_credits_tab()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    else
        render_home_tab()
    end
end)

-- start the one-time logo cache quietly. Existing DriftGod copies are reused.
resolve_logo_path()


EventMgr.RegisterHandler(eLuaEvent.ON_SCRIPT_STOP, function()
    stop_speed_bobbing()
    restore_vehicle(state.vehicle)
    if overlay_handler then EventMgr.RemoveHandler(overlay_handler) end
end)

log(
    script_name .. " v" .. script_version
        .. " loaded. Saved keybinds, persistent Top 10 scores, camera guidance and presentation-synced ui active."
)
