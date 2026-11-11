-- Earplugs.lua
-- Toggles that mutes game sounds, each with one of the game's own audio controls, 
-- kept in place while it's on and put back when it goes off or the script stops.
--
-- Changelog:
-- v1.0.1   fix: Score Music covers flight music
-- v1.0.0   feat: release build: no debug tab, log or Now Playing
-- v0.6.1   fix: scenes kept at full
-- v0.6.0   feat: every switch checked in the game's files; Silenced
-- v0.5.0   feat: more switches (radio, weapons, alarms, others but you)
-- v0.4.2   fix: scenes that end by themselves
-- v0.4.1   fix: Helicopters, Footsteps
-- v0.4.0   feat: more switches, sub-switches under their group, sections in columns
-- v0.3.0   feat: named Earplugs; 16 more switches, unnamed controls by stand-in names, confidence marks; grid layout
-- v0.2.0   feat: more switches (weather, aircraft, places, pain, Online's Arena and Car Meet)
-- v0.1.0   feat: test bench: 17 switches from the game's audio data, what the game reports back, music readouts, log

-- Constants --------------------------------------------------------------

local VERSION = "1.0.1"

local NATIVES = {
    IS_PED_A_PLAYER = 0x12534C348C6CB68B,                 -- (Ped ped) -> bool
    IS_ENTITY_A_MISSION_ENTITY = 0x0A7B270912999B3C,      -- (Entity entity) -> bool
    DOES_ENTITY_EXIST = 0x7239B21A38F536BA,               -- (Entity entity) -> bool
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,           -- (Ped ped, bool includeEntering) -> Vehicle
    START_AUDIO_SCENE = 0x013A80FC08F6E4F2,               -- (const char* scene) -> bool
    STOP_AUDIO_SCENE = 0xDFE8422B3B94E688,                -- (const char* scene)
    IS_AUDIO_SCENE_ACTIVE = 0xB65B60556E2A9225,           -- (const char* scene) -> bool
    SET_AUDIO_SCENE_VARIABLE = 0xEF21A9EF089A2668,        -- (const char* scene, const char* variable, float value)
    ADD_ENTITY_TO_AUDIO_MIX_GROUP = 0x153973AB99FE8980,   -- (Entity entity, const char* groupName, float fade)
    REMOVE_ENTITY_FROM_AUDIO_MIX_GROUP = 0x18EB48CFC41F2EA0, -- (Entity entity, float fade)
    SET_AUDIO_FLAG = 0xB9EFD5C25018725A,                  -- (const char* flagName, bool toggle)
    STOP_PED_SPEAKING = 0x9D64D7405520E3D3,               -- (Ped ped, bool stop)
    DISABLE_PED_PAIN_AUDIO = 0xA9A41C1E940FB0E8,          -- (Ped ped, bool disable)
    SET_PED_FOOTSTEPS_EVENTS_ENABLED = 0x0653B735BFBDFE87, -- (Ped ped, bool toggle)
    SET_HORN_ENABLED = 0x76D683C108594D0E,                -- (Vehicle vehicle, bool toggle)
    SET_VEHICLE_HAS_MUTED_SIRENS = 0xD8050E0EB60CF274,    -- (Vehicle vehicle, bool toggle)
    STOP_ALL_ALARMS = 0x2F794A877ADD4C92,                 -- (bool stop)
    SET_PED_WALLA_DENSITY = 0x149AEE66F0CB3A99,           -- (float density, float weight)
    SET_PED_INTERIOR_WALLA_DENSITY = 0x8BF907833BE275DE,  -- (float density, float weight)
    BLOCK_DEATH_JINGLE = 0xF154B8D1775B2DEC,              -- (bool block)
}

local TIMING = {
    KEEP_MS = 1000,  -- how often each switch that's on is put back in place
    RENEW_MS = 2000, -- how long before a scene that ends by itself would end it's started again (more than KEEP_MS)
    SCAN_MS = 500,   -- how often the peds and vehicles around you are told again (new ones come by)
}
local ERRORS_LOGGED = 50 -- distinct errors written to Cherax's log
-- Between the items of a list in a row: a comma, then a gap the menu's font shows as two spaces.
local LIST_GAP = ",   "
local YELLOW = { 1.0, 0.8, 0.3, 1.0 } -- a switch the game had undone
local SUB_INDENT = 20 -- px a switch is moved right for each level it sits under another

-- The switches, by section; a section with a column is drawn in that column of the grid, one without in the first third beside Silenced. The fields that say how a switch silences:
--         scene: a mix scene kept running; its comment says what it turns down (sound category, dB)
--         lasts: ms its scene runs before ending by itself; it's started again TIMING.RENEW_MS sooner
--         group: a mix group its scene turns down; each ped or vehicle of its list (of) is kept in the group
--          each: a native told to each ped or vehicle of its list (of): value silences, the opposite sets back
--            of: which peds or vehicles around you it acts on (the lists in Scan)
--          flag: an audio flag kept set
--         calls: natives called every TIMING.KEEP_MS while it's on
--          undo: natives called once when it goes off
--         level: 1 or 2 when it silences part of what the switch above it does; drawn moved right
-- A scene named "earplugs_..." stands in for one the game's data only has a hash for: it's made to have that hash, and the game finds scenes by hash.
local SECTIONS = {
    { name = "Music", switches = {
        { key = "Score", label = "Score Music",
          scene = "dlc_ch_badlands_revenge_powerup_active_scene", -- INTERACTIVE_MUSIC -60
          desc = "The game's own music over the action (missions, jobs, freemode events) and while you fly with the radio off, turned down 60 dB. Its short stings and your radio keep playing" },
        { key = "WantedMusic", label = "Wanted Music", flag = "WantedMusicDisabled",
          desc = "The music that plays while you have a wanted level" },
        { key = "Radio", label = "All Radio", scene = "MUTES_RADIO_SCENE", -- RADIO -100
          desc = "Every radio: yours, your phone's, other vehicles', buildings' and clubs', and TVs heard from buildings" },
        { key = "Radios", label = "Radios Around You", level = 1,
          scene = "MP_POSITIONED_RADIO_MUTE_SCENE", -- POSITIONED_RADIO -100
          desc = "Radios and TVs heard from buildings, clubs, gun ranges and other vehicles. Your own vehicle's radio keeps playing" },
        { key = "YourRadio", label = "Your Radio", level = 1,
          scene = "MP_JOB_CHANGE_RADIO_MUTE", -- FRONTEND_RADIO -100
          desc = "The radio of the vehicle you're in and your phone's radio. The station keeps playing, unheard" },
    } },
    { name = "Streets", switches = {
        { key = "Traffic", label = "Background Traffic",
          scene = "GTAO_Mute_Traffic_Ambience_Scene", -- AMBIENCE_GENERAL_TRAFFIC -100, AMBIENCE_ONESHOT_VEHICLES -100
          desc = "The city's background traffic: horns, brakes, skids, ambulance and fire truck sirens, car alarms, reversing beeps, car park doors and locks, train horns, and the distant sounds below. Vehicles near you still make their sounds" },
        { key = "DistantCars", label = "Distant Sounds", level = 1,
          scene = "PS_2A_SHOOTOUT_HELI_ARRIVES", -- AMBIENCE_ONESHOT_VEHICLES -100
          desc = "Sounds far off: cars passing in the city and the countryside, dogs, a wolf, a sasquatch, Mount Gordo's whispers and screams, dockyard and industrial bangs, screams from the pier's rides, revving at the Car Meet. The background horns, brakes and alarms keep sounding" },
        { key = "Horns", label = "Car Horns",
          scene = "DAX_2_5_Inside_CargoPlane_Scene", -- VEHICLES_HORNS -99
          desc = "Every vehicle's horn, yours too, boats' and trains' horns, bicycle bells, sirens' horn blasts and trucks' reversing beeps" },
        { key = "OtherHorns", label = "NPC Horns", level = 1,
          each = "SET_HORN_ENABLED", value = false, of = "npcVehicles",
          desc = "The horn of every NPC's vehicle" },
        { key = "Sirens", label = "Sirens",
          scene = "DLC_BTL_HP_Remix_General_Scene", -- VEHICLES_SIRENS -100
          desc = "Police, ambulance and fire truck sirens, near and far. Their lights keep flashing and their horn blasts keep sounding" },
        { key = "OtherSirens", label = "NPC Sirens", level = 1,
          each = "SET_VEHICLE_HAS_MUTED_SIRENS", value = true, of = "npcVehicles",
          desc = "The siren of every NPC's vehicle. Their lights keep flashing" },
        { key = "Scanner", label = "Police Scanner", flag = "PoliceScannerDisabled",
          desc = "The police radio's reports" },
        { key = "Crashes", label = "Crashes and Impacts",
          scene = "DLC_SM_PD_Flatbed_Container_Delivery_Scene", -- COLLISIONS -100
          desc = "Crashes, bumps, breaking glass and things hitting each other, yours too" },
    } },
    { name = "Vehicles", column = 2, switches = {
        { key = "Vehicles", label = "All Vehicles",
          scene = "dlc_xm_facility_enter_in_vehicle_exterior_engine_off_scene", -- VEHICLES -100
          desc = "Every vehicle sound: engines, horns, sirens, brakes, tyres, doors, helicopters, planes, boats, trains, bicycles, yours too. Crashes still sound" },
        { key = "Engines", label = "Engines", level = 1,
          scene = "dlc_xm_facility_enter_in_vehicle_interior_scene", -- VEHICLES_ENGINES, VEHICLES_HELIS, VEHICLES_PLANES, VEHICLES_EXTRAS_LOUD -100
          desc = "Engines of cars, bikes and trucks with their exhaust pops, turbos and start-ups, yours too, and every sound of helicopters and planes. Boats keep their engines" },
        { key = "Skids", label = "Tyre Skids", level = 1, lasts = 5000,
          scene = "earplugs_z8bba5a", -- #0d03f38c: VEHICLES_WHEELS_SKIDS -100
          desc = "Tyres screeching and skidding, yours too" },
    } },
    { name = "Weapons", column = 3, switches = {
        { key = "Gunshots", label = "Your Gunshots",
          scene = "earplugs_nxzqask", -- #569e694e: your guns' shots and reports, every gun's indoors -100
          desc = "The bang of your guns and their distant reports, and every gun fired indoors. Your echoes keep sounding; other people's guns keep most of their bang" },
        { key = "OthersGunshots", label = "NPC Gunshots",
          group = "SHOOT_THROUGH_DOOR_GROUP", of = "npcs",
          scene = "AH_3B_SHOOTTHROUGHDOOR_SCENE", -- the shots of guns others fire -100 for its group only
          desc = "The bang of the guns NPCs fire. Their distant reports keep sounding" },
        { key = "BulletImpacts", label = "Bullet Impacts",
          scene = "DH2A_CHOPPER_SHOOTING", -- WEAPONS_GUNS_BULLET_IMPACTS -100, rotors breaking -100
          desc = "Bullets hitting things and people, and helicopters' rotors breaking" },
        { key = "Explosions", label = "Explosions",
          scene = "EXILE_1_ROCKETS_FIRED", -- WEAPONS_EXPLOSIONS -100
          desc = "Explosions, fireworks and flares, yours too" },
    } },
    { name = "People", column = 2, switches = {
        { key = "Talking", label = "NPC Talking", each = "STOP_PED_SPEAKING", value = true, of = "street",
          desc = "What NPCs in the street say: greetings, insults, reactions. Mission characters keep talking" },
        { key = "Pain", label = "NPC Pain Sounds", each = "DISABLE_PED_PAIN_AUDIO", value = true, of = "street",
          desc = "NPCs in the street crying out when hurt. Mission characters keep theirs" },
        -- crowds' murmur: density 0 at full weight is silent; weight 0 hands it back to the game
        { key = "Crowd", label = "Crowd Murmur",
          calls = { { "SET_PED_WALLA_DENSITY", 0.0, 1.0 }, { "SET_PED_INTERIOR_WALLA_DENSITY", 0.0, 1.0 } },
          undo = { { "SET_PED_WALLA_DENSITY", 0.0, 0.0 }, { "SET_PED_INTERIOR_WALLA_DENSITY", 1.0, 0.0 } },
          desc = "The murmur of crowds, outside and inside" },
        { key = "BackgroundVoices", label = "Background Voices",
          scene = "earplugs_qpofd0s", -- #12190004: AMBIENCE_SPEECH -100
          desc = "Voices in the background: crowds and their murmur, gang members, people on a night out, announcers at the airport, the prison and Fort Zancudo, workers' shouts, golfers, the casino" },
        { key = "AllVoices", label = "All Voices",
          scene = "earplugs_f8cya7w", -- #f66f2436: SPEECH -100
          desc = "Every voice but the background ones: people in the street, mission characters, phone calls, pain and breathing, your character" },
        { key = "Body", label = "Body Sounds", scene = "GOLF_FLY_CAM", -- PEDS -100
          desc = "Everyone's footsteps, clothes rustling, punches, falls and other body sounds, yours too" },
        { key = "Footsteps", label = "Footsteps", level = 1,
          scene = "FBI_3_TORTURE_ZOOM", -- PEDS_FOOTSTEPS -100
          desc = "Everyone's footsteps, yours too" },
        { key = "YourFootsteps", label = "Your Footsteps", level = 2,
          scene = "MCU_FirstPerson_Seated_Scene", -- PEDS_FOOTSTEPS -100 for the mix group PLAYER_GROUP, which holds you
          desc = "Only your own footsteps" },
        { key = "OthersFootsteps", label = "NPC Footsteps", level = 2,
          each = "SET_PED_FOOTSTEPS_EVENTS_ENABLED", value = false, of = "npcs",
          desc = "Every NPC's footsteps" },
    } },
    { name = "Background", column = 3, switches = {
        { key = "Background", label = "All Background Sounds",
          scene = "FBI_3_MICHAEL_SNIPER_SCOPE_TARGET", -- AMBIENCE -100
          desc = "Every background sound: traffic, birds, insects, animals, voices, music from houses, construction, machinery, the hum inside buildings. Vehicles, people, weapons, weather and water keep sounding" },
        { key = "General", label = "General Background", level = 1,
          scene = "earplugs_af3saqs", -- #ccd98c8a: AMBIENCE_GENERAL -60, AMBIENCE_INDUSTRIAL -60
          desc = "Most background sounds, turned down 60 dB: animals (dogs, cats, coyotes, chickens, frogs, cows, horses), work (construction, the docks, machinery), bells, creaking, coughing, the background traffic, the hum inside buildings" },
        { key = "IndustrialHum", label = "Industrial Sounds", level = 1,
          scene = "earplugs_p8pnazl", -- #b648c5f8: AMBIENCE_INDUSTRIAL -100
          desc = "Industrial background sounds everywhere: machinery hum, oil field pumps, shipyards, the quarry and the sawmill, the cable car, car mod shops" },
    } },
    { name = "Other", column = 3, switches = {
        { key = "Menu", label = "Menu and HUD Sounds",
          scene = "earplugs_mgt2aej", -- #50451415: FRONTEND_MENU -100, HUD -100
          desc = "The pause menu's sounds and music, the HUD's beeps (timers, scoreboards, notifications), your phone's ringtones and text tones, and aircraft stall and damage warnings" },
        { key = "Fire", label = "Fire", scene = "GTAO_Generic_Ducking_Mute_Fire_Scene", -- FIRE -100
          desc = "Fire burning, sparks and thermal charges" },
        { key = "Alarms", label = "Alarms", calls = { { "STOP_ALL_ALARMS", true } },
          desc = "Alarms that jobs and missions sound: bank vaults, the prison, military bases, ships, the jewel store. One stopped stays off until the game sounds it again" },
        { key = "DeathJingle", label = "Death Jingle",
          calls = { { "BLOCK_DEATH_JINGLE", true } }, undo = { { "BLOCK_DEATH_JINGLE", false } },
          desc = "The music sting when you die" },
    } },
}

-- State ------------------------------------------------------------------

-- When the loop next keeps and scans; what Silenced shows, as lines of { text, color or nil }; errors logged.
local S = { keepAt = 0, scanAt = 0, unloading = false, errors = {}, errorCount = 0, silenced = { { "Nothing silenced." } } }

-- Every switch in order. While the script runs each one also holds:
--         hash: its Cherax feature's key
--      feature: its Cherax toggle
--      applied: its control is in place
--   ok, status: false and why when the game had undone it (shown in yellow)
--    startedAt: when its scene was last started (or tried)
--         told: the peds or vehicles it silenced, as keys
local SWITCHES = {}
for _, section in ipairs(SECTIONS) do
    for _, sw in ipairs(section.switches) do
        if sw.flag then sw.calls, sw.undo = { { "SET_AUDIO_FLAG", sw.flag, true } }, { { "SET_AUDIO_FLAG", sw.flag, false } } end
        sw.hash, sw.told, sw.applied, sw.ok, sw.status = Utils.Joaat("Earplugs_" .. sw.key), {}, false, true, ""
        SWITCHES[#SWITCHES + 1] = sw
    end
end

-- The top row's sections (no column) and the grid's three columns, each in SECTIONS' order.
local TOP, GRID = {}, { {}, {}, {} }
for _, section in ipairs(SECTIONS) do table.insert(section.column and GRID[section.column] or TOP, section) end

-- Logic ------------------------------------------------------------------

-- Runs fn with pcall; each distinct error goes to Cherax's log once.
local function Try(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local text = "[Earplugs] " .. where .. ": " .. tostring(err)
        if not S.errors[text] and S.errorCount < ERRORS_LOGGED then
            S.errors[text], S.errorCount = true, S.errorCount + 1
            Logger.LogError(text)
        end
    end
    return ok, err
end

-- Silences one ped or vehicle for a switch, or sets it back.
local function Tell(sw, entity, silence)
    if sw.group and silence then
        Natives.InvokeVoid(NATIVES.ADD_ENTITY_TO_AUDIO_MIX_GROUP, entity, sw.group, 0.0)
    elseif sw.group then
        Natives.InvokeVoid(NATIVES.REMOVE_ENTITY_FROM_AUDIO_MIX_GROUP, entity, 0.0)
    else
        Natives.InvokeVoid(NATIVES[sw.each], entity, silence == sw.value)
    end
end

-- Lists the NPCs and NPCs' vehicles around you; each switch that's on tells its whole list again (a handle can come back as a new ped or vehicle) and sets back the ones that left it, such as a car a player got into.
local function Scan()
    local lists = { street = {}, npcs = {}, npcVehicles = {} }
    local playerIn, npcIn = {}, {} -- the vehicles players, and NPCs, are in or getting into
    for i = 0, PoolMgr.GetMaxPedCount() - 1 do
        local ped = PoolMgr.GetPed(i)
        if ped ~= 0 and Natives.InvokeBool(NATIVES.DOES_ENTITY_EXIST, ped) then
            local vehicle = Natives.InvokeInt(NATIVES.GET_VEHICLE_PED_IS_IN, ped, true)
            if Natives.InvokeBool(NATIVES.IS_PED_A_PLAYER, ped) then
                playerIn[vehicle] = true
            else
                npcIn[vehicle] = true
                lists.npcs[#lists.npcs + 1] = ped
                if not Natives.InvokeBool(NATIVES.IS_ENTITY_A_MISSION_ENTITY, ped) then lists.street[#lists.street + 1] = ped end
            end
        end
    end
    -- an NPC's vehicle: one an NPC is in, or the game's own traffic standing empty; an empty vehicle a script made can be a player's
    for i = 0, PoolMgr.GetMaxVehicleCount() - 1 do
        local vehicle = PoolMgr.GetVehicle(i)
        if vehicle ~= 0 and not playerIn[vehicle] and Natives.InvokeBool(NATIVES.DOES_ENTITY_EXIST, vehicle)
            and (npcIn[vehicle] or not Natives.InvokeBool(NATIVES.IS_ENTITY_A_MISSION_ENTITY, vehicle)) then
            lists.npcVehicles[#lists.npcVehicles + 1] = vehicle
        end
    end
    for _, sw in ipairs(SWITCHES) do
        if sw.of and sw.applied then
            local told = {}
            for _, entity in ipairs(lists[sw.of]) do
                Tell(sw, entity, true)
                told[entity] = true
            end
            for entity in pairs(sw.told) do
                if not told[entity] and Natives.InvokeBool(NATIVES.DOES_ENTITY_EXIST, entity) then Tell(sw, entity, false) end
            end
            sw.told = told
        end
    end
end

-- Puts a switch's control in place: when it's switched on, then every TIMING.KEEP_MS. What the game can be asked about (scenes) is checked, and ok goes false when the game had undone it; the rest is simply set again.
local function Hold(sw, now)
    local first = not sw.applied
    sw.applied, sw.ok, sw.status = true, true, ""
    if sw.scene then
        -- starting a scene that's still running doesn't move its end, so one about to end by itself is stopped first
        local renew = not first and sw.lasts and now - sw.startedAt + TIMING.RENEW_MS >= sw.lasts
        if renew then Natives.InvokeVoid(NATIVES.STOP_AUDIO_SCENE, sw.scene) end
        if first or renew or not Natives.InvokeBool(NATIVES.IS_AUDIO_SCENE_ACTIVE, sw.scene) then
            sw.startedAt = now
            -- yellow when the game refuses the start, or had stopped the scene on its own
            if not Natives.InvokeBool(NATIVES.START_AUDIO_SCENE, sw.scene) or not (first or renew) then
                sw.ok, sw.status = false, "the game isn't running it; starting it again"
            end
        else
            Natives.InvokeVoid(NATIVES.SET_AUDIO_SCENE_VARIABLE, sw.scene, "apply", 1.0) -- jobs can turn a running scene down through "apply" (1: full effect, 0: none)
        end
    end
    for _, call in ipairs(sw.calls or {}) do Natives.InvokeVoid(NATIVES[call[1]], table.unpack(call, 2)) end
    if first and sw.of then S.scanAt = 0 end -- its peds or vehicles are told in this same loop
end

-- Puts back what a switch changed.
local function Release(sw)
    if sw.scene then Natives.InvokeVoid(NATIVES.STOP_AUDIO_SCENE, sw.scene) end
    for _, call in ipairs(sw.undo or {}) do Natives.InvokeVoid(NATIVES[call[1]], table.unpack(call, 2)) end
    for entity in pairs(sw.told) do
        if Natives.InvokeBool(NATIVES.DOES_ENTITY_EXIST, entity) then Tell(sw, entity, false) end
    end
    sw.told, sw.applied, sw.ok, sw.status = {}, false, true, ""
end

-- Each loop: switches follow their toggles at once and are held every KEEP_MS, the peds and vehicles around you are told every SCAN_MS. The tab only draws what's made here: natives can't be called while drawing.
local function Tick()
    local now = Time.GetEpocheMs()
    local keep = now >= S.keepAt
    if keep then S.keepAt = now + TIMING.KEEP_MS end
    local around, changed = false, false
    for _, sw in ipairs(SWITCHES) do
        local on = sw.feature:IsToggled()
        if on and (keep or not sw.applied) then
            Try(sw.label, Hold, sw, now)
            changed = true
        elseif not on and sw.applied then
            Try(sw.label, Release, sw)
            changed = true
        end
        around = around or (sw.applied and sw.of ~= nil)
    end
    if around and now >= S.scanAt then
        S.scanAt = now + TIMING.SCAN_MS
        Scan()
    end
    if changed then
        local kept, lines = {}, {}
        for _, sw in ipairs(SWITCHES) do
            if sw.applied and sw.ok then kept[#kept + 1] = sw.label end
            if sw.applied and not sw.ok then lines[#lines + 1] = { sw.label .. ": " .. sw.status, YELLOW } end
        end
        if #kept > 0 then table.insert(lines, 1, { table.concat(kept, LIST_GAP) }) end
        S.silenced = #lines > 0 and lines or { { "Nothing silenced." } }
    end
end

-- Puts back every switch that's on, once: from the loop or from Cherax's unload event, whichever comes first.
local function Unload()
    if S.unloading then return end
    S.unloading = true
    for _, sw in ipairs(SWITCHES) do
        if sw.applied then Try(sw.label, Release, sw) end
    end
end

-- UI ---------------------------------------------------------------------

-- A section's rows: switches (moved right by their level) or lines of text (wrapped, in their color if they have one). TextUnformatted, since Cherax reads TextWrapped's text as a format.
local function DrawRows(rows)
    for _, row in ipairs(rows) do
        if row.hash then
            if row.level then ImGui.SetCursorPosX(ImGui.GetCursorPosX() + SUB_INDENT * row.level) end
            ClickGUI.RenderFeature(row.hash)
        else
            local color = row[2]
            if color then ImGui.PushStyleColor(ImGuiCol.Text, color[1], color[2], color[3], color[4]) end
            ImGui.PushTextWrapPos(0.0)
            ImGui.TextUnformatted(row[1])
            ImGui.PopTextWrapPos()
            if color then ImGui.PopStyleColor(1) end
        end
    end
end

-- A child window whose End always runs; an error is shown in its place.
local function Section(title, rows)
    if not ClickGUI.BeginCustomChildWindow(title) then return end
    local ok, err = Try(title, DrawRows, rows)
    if not ok then DrawRows({ { "UI error: " .. tostring(err), YELLOW } }) end
    ClickGUI.EndCustomChildWindow()
end

-- TOP's sections in a third beside Silenced, then GRID's three columns, each starting right under what's above it. ImGui's columns can't nest, so the top and the grid are two sets; starting the second ends the first.
local function DrawTab()
    local width = ImGui.GetContentRegionAvail()
    ImGui.Columns(2, "##EarplugsTop", false)
    ImGui.SetColumnWidth(0, width / 3)
    for _, section in ipairs(TOP) do Section(section.name, section.switches) end
    local leftEnd = ImGui.GetCursorPosY()
    ImGui.NextColumn()
    Section("Silenced", S.silenced)
    local rightEnd = ImGui.GetCursorPosY()
    ImGui.Columns(3, "##EarplugsGrid", false)
    ImGui.SetColumnWidth(0, width / 3)
    ImGui.SetColumnWidth(1, width / 3)
    for c, sections in ipairs(GRID) do
        if c > 1 then ImGui.NextColumn() end
        ImGui.SetCursorPosY(c == 1 and leftEnd or rightEnd)
        for _, section in ipairs(sections) do Section(section.name, section.switches) end
    end
    ImGui.Columns(1)
end

-- Registration -----------------------------------------------------------

for _, sw in ipairs(SWITCHES) do
    sw.feature = FeatureMgr.AddFeature(sw.hash, sw.label, eFeatureType.Toggle, sw.desc)
end
ClickGUI.AddTab("Earplugs", function() Try("Tab", DrawTab) end)
Script.RegisterLooped(function()
    Try("Loop", (ShouldUnload() or S.unloading) and Unload or Tick)
    Script.Yield()
end)
EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function() Try("Unload", Unload) end)
Logger.LogInfo("[Earplugs] v" .. VERSION .. " loaded")
