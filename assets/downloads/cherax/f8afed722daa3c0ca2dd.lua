-- im touching the person reading this

print("\27[31m" .. [[

 ▄▄▄▄▄▄▄                                            
███▀▀▀▀▀       ▀▀                                   
███      ████▄ ██  ███▄███▄ ▄█▀▀▀ ▄███▄ ████▄ ▄█▀▀▀ 
███      ██ ▀▀ ██  ██ ██ ██ ▀███▄ ██ ██ ██ ██ ▀███▄ 
▀███████ ██    ██▄ ██ ██ ██ ▄▄▄█▀ ▀███▀ ██ ██ ▄▄▄█▀ 



▄▄▄▄  ▄▄▄▄      ▄▄              ▄▄             
▀███  ███▀      ██    ▀▀        ██             
 ███  ███ ▄█▀█▄ ████▄ ██  ▄████ ██ ▄█▀█▄ ▄█▀▀▀ 
 ███▄▄███ ██▄█▀ ██ ██ ██  ██    ██ ██▄█▀ ▀███▄ 
  ▀████▀  ▀█▄▄▄ ██ ██ ██▄ ▀████ ██ ▀█▄▄▄ ▄▄▄█▀ 


]] .. "\27[0m")


do
    local is_flying = false
    local function safe(fn)
        return function(...)
            local results = {pcall(fn, ...)}
            if results[1] then
                return table.unpack(results, 2)
            end
            return nil
        end
    end

    local n = {
        ped = safe(function(...) return Natives.InvokeInt(0x50FAC3A3E030A6E1,...) end),
        pos = safe(function(e,a) return Natives.InvokeV3(0x3FEF770D40960D5A,e,a) end),
        put = safe(function(...) return Natives.InvokeVoid(0xF75B0D629E1C063D,...) end),
        eng = safe(function(v,a,b,c) return Natives.InvokeVoid(0x2497C4717C8B881E,v,a,b,c) end),
        att = safe(function(...) return Natives.InvokeVoid(0x6B9BBD38AB0796DF,...) end),
        vis = safe(function(e,a,b) return Natives.InvokeVoid(0xEA1C610A04DB6BBB,e,a,b) end),
        col = safe(function(e,a,b) return Natives.InvokeVoid(0x1A9205C1B9EE827F,e,a,b) end),
        ex = safe(function(e) return Natives.InvokeBool(0x7239B21A38F536BA,e) end),
        dveh = safe(function(v) return Natives.InvokeVoid(0xEA386986E786A54F,v) end),
        dobj = safe(function(o) return Natives.InvokeVoid(0x539E0AE3E6634B9F,o) end),
        dent = safe(function(e) return Natives.InvokeVoid(0xAE3CBE5BF394C9C9,e) end),
        kit = safe(function(v,k) return Natives.InvokeVoid(0x1F2AA07F00B3217A,v,k) end),
        mod = safe(function(v,t,i,c) return Natives.InvokeVoid(0x6AF0636DDEDCB6DD,v,t,i,c) end),
        tog = safe(function(v,t,a) return Natives.InvokeVoid(0x2A1F4F8F01F4F990,v,t,a) end),
        xcol = safe(function(v,p,w) return Natives.InvokeVoid(0x2036F561ADD12E33,v,p,w) end),
        prim = safe(function(v,r,g,b) return Natives.InvokeVoid(0x7141766F91D15BEA,v,r,g,b) end),
        sec = safe(function(v,r,g,b) return Natives.InvokeVoid(0x36CED73BFED89754,v,r,g,b) end),
        wheel = safe(function(v,t) return Natives.InvokeVoid(0x487EB21CC7295BA1,v,t) end),
        plate = safe(function(v,t) return Natives.InvokeVoid(0x95A88F0B409CDA47,v,t) end),
        plati = safe(function(v,i) return Natives.InvokeVoid(0x9088EB5A43FFB0A1,v,i) end),
        burst = safe(function(v,t) return Natives.InvokeVoid(0xEB9DC3C7D8596C46,v,t) end),
        tint = safe(function(v,t) return Natives.InvokeVoid(0x57C51E6BAD752696,v,t) end),
        neon = safe(function(v,i,t) return Natives.InvokeVoid(0xF2E1A7133DD356A6,v,i,t) end),
        neonc = safe(function(v,r,g,b) return Natives.InvokeVoid(0x8E0A582209A62695,v,r,g,b) end),
        smoke = safe(function(v,r,g,b) return Natives.InvokeVoid(0xB5BA80F839791C0F,v,r,g,b) end),
        extra = safe(function(v,e,t) return Natives.InvokeVoid(0x7EE3A3C5E4A40CC9,v,e,t) end),
        dirt = safe(function(v,d) return Natives.InvokeVoid(0x79D3B596FE44EE8B,v,d) end),
        pt1 = safe(function(v,a,b,c) return Natives.InvokeVoid(0x43FEB945EE7F85B8,v,a,b,c) end),
        pt2 = safe(function(v,a,b) return Natives.InvokeVoid(0x816562BADFDEC83E,v,a,b) end),
        dash = safe(function(v,c) return Natives.InvokeVoid(0xF40DD601A65F7F19,v,c) end),
        fade = safe(function(v,s) return Natives.InvokeVoid(0x3AFDC536C3D01674,v,s) end),
        bone = safe(function(e,n) return Natives.InvokeInt(0xFB71170B7E76ACBA,e,n) end),
        pveh = safe(function(p,l) return Natives.InvokeInt(0x9A9112A0FE9A4713,p,l) end),
        livery = safe(function(v,l) return Natives.InvokeVoid(0x60BF608F1B8CD1B6,v,l) end),
    }

    local GET_NUM_VEHICLE_MODS = safe(function(v, modType) return Natives.InvokeInt(0xE38E9162A2500646, v, modType) end)

    local function ToHandle(ent)
        if not ent then return 0 end
        if type(ent) == "number" then return ent end
        if GTA and GTA.PointerToHandle then
            local ok,h = pcall(GTA.PointerToHandle,ent)
            if ok and type(h) == "number" then return h end
        end
        return 0
    end

    local function toast(a,b)
        if GUI and GUI.AddToast then GUI.AddToast(a or "Spawner",b,3000) end
    end

    local NAT2 = {
        GET_PLAYER_PED              = 0x50FAC3A3E030A6E1,
        GET_ENTITY_COORDS           = 0x3FEF770D40960D5A,
        ATTACH_ENTITY_TO_ENTITY     = 0x6B9BBD38AB0796DF,
        SET_PED_INTO_VEHICLE        = 0xF75B0D629E1C063D,
        SET_VEHICLE_ENGINE_ON       = 0x2497C4717C8B881E,
        SET_ENTITY_VISIBLE          = 0xEA1C610A04DB6BBB,
        SET_ENTITY_INVINCIBLE       = 0x3882114BDE571AD4,
        SET_ENTITY_PROOFS           = 0xFAEE05F2D6D9678D,
        SET_VEHICLE_ENGINE_HEALTH   = 0x45F81E69F34B4935,
        SET_PLANE_PROPELLER_HEALTH  = 0x69022646393EEB38,
        SET_ENTITY_COLLISION        = 0x1A9205C1B9EE827F,
        DELETE_OBJECT               = 0x539E0AE3E6634B9F,
        DELETE_PED                  = 0x9614299DCB53E54B,
        DELETE_VEHICLE              = 0xEA386986E786A54F,
        DOES_ENTITY_EXIST           = 0x7239B21A38F536BA,
        SET_HELI_BLADES_FULL_SPEED  = 0xA178472EBB8AE60D,
        TASK_VEHICLE_DRIVE_WANDER   = 0x480142959D337D00,
        GET_ENTITY_BONE_INDEX       = 0xFB71170B7E76ACBA,
        NETWORK_REGISTER_ENTITY     = 0x06FAACD625D80CAA,
        SET_VEHICLE_MOD_KIT         = 0x1F2AA07F00B3217A,
        SET_VEHICLE_MOD             = 0x6AF0636DDEDCB6DD,
        SET_VEHICLE_EXTRA_COLOURS   = 0x2036F561ADD12E33,
        SET_VEHICLE_TYRES_CAN_BURST = 0xEB9DC3C7D8596C46,
        SET_VEHICLE_DIRT_LEVEL      = 0x79D3B596FE44EE8B,
        SET_VEHICLE_MOD_COLOR_1     = 0x43FEB945EE7F85B8,
        SET_VEHICLE_MOD_COLOR_2     = 0x816562BADFDEC83E,
        SET_VEHICLE_CUSTOM_PRIMARY_COLOUR   = 0x7141766F91D15BEA,
        SET_VEHICLE_CUSTOM_SECONDARY_COLOUR = 0x36CED73BFED89754,
        SET_VEHICLE_NEON_LIGHTS_COLOUR      = 0x8E0A582209A62695,
        SET_VEHICLE_NEON_LIGHT_ENABLED      = 0xF2E1A7133DD356A6,
        SET_VEHICLE_TYRE_SMOKE_COLOR        = 0xB5BA80F839791C0F,
        SET_PED_CONFIG_FLAG         = 0x1913FE4CBF41C463,
        SET_PED_CAN_BE_DRAGGED_OUT  = 0x7A6535691B477C48,
        SET_BLOCKING_OF_NON_TEMPORARY_EVENTS = 0x9F8AA94D6D97DBF4,
        SET_PED_FLEE_ATTRIBUTES     = 0x70A2D1137C8ED7C9,
        SET_PED_COMBAT_ATTRIBUTES   = 0x9F7794730795E019,
        SET_VEHICLE_DOORS_LOCKED    = 0xB664292EAECF7FA6,
        GIVE_WEAPON_TO_PED          = 0xBF0FD6E56C964FCB,
        SET_CURRENT_PED_WEAPON      = 0xADF692B254977C0C,
        SET_ENTITY_NO_COLLISION_ENTITY = 0xA53ED5A986B2B91D,
    }

    local NI = function(hash, ...) return Natives.InvokeInt(hash, ...) end
    local NV = function(hash, ...) return Natives.InvokeVoid(hash, ...) end
    local NB = function(hash, ...) return Natives.InvokeBool(hash, ...) end
    local N3 = function(hash, ...) return Natives.InvokeV3(hash, ...) end

    local CHROMA_R, CHROMA_G, CHROMA_B = 220, 20, 60
    local spawnedBuilds2 = {}
    local spawnedBuilds = {}

    local function Wait2(ms)
        if script and script.yield then script.yield(ms or 0) end
    end

    local function Notify2(title, msg)
        if GUI and GUI.AddToast then GUI.AddToast(title or "Spawner", msg, 3000) end
    end

    local function GetPlayerPos2()
        local ped = NI(NAT2.GET_PLAYER_PED, GTA.GetLocalPlayerId())
        return N3(NAT2.GET_ENTITY_COORDS, ped, true)
    end

    local function MakeVehicleGodmode(veh)
        if veh == 0 or not NB(NAT2.DOES_ENTITY_EXIST, veh) then return end
        NV(NAT2.SET_ENTITY_INVINCIBLE, veh, true)
        NV(NAT2.SET_ENTITY_PROOFS, veh, true, true, true, true, true, true, true, true)
    end

    local function UpgradeVehicle2(veh, name)
        if veh == 0 or not NB(NAT2.DOES_ENTITY_EXIST, veh) then
            Notify2("Upgrade", name .. " invalid!")
            return
        end

        local ok = pcall(function()
            NV(NAT2.SET_VEHICLE_MOD_KIT, veh, -1)
            Wait2(150)
            NV(NAT2.SET_VEHICLE_MOD_KIT, veh, 0)
            Wait2(150)

            local mods = {
                {11, 3}, {12, 2}, {13, 2}, {14, 1}, {15, 3},
                {16, 4}, {33, 1}, {48, 0}, {42, 1}, {43, 0},
            }
            for _, m in ipairs(mods) do
                NV(NAT2.SET_VEHICLE_MOD, veh, m[1], m[2], false)
                Wait2(80)
            end

            NV(NAT2.SET_VEHICLE_MOD, veh, 23, 0, false)
            NV(NAT2.SET_VEHICLE_MOD, veh, 24, 0, false)
            Wait2(80)

            NV(NAT2.SET_VEHICLE_MOD_COLOR_1, veh, 5, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_MOD_COLOR_2, veh, 5, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR, veh, CHROMA_R, CHROMA_G, CHROMA_B)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR, veh, CHROMA_R, CHROMA_G, CHROMA_B)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_EXTRA_COLOURS, veh, 135, 0)
            Wait2(50)

            NV(NAT2.SET_VEHICLE_NEON_LIGHTS_COLOUR, veh, CHROMA_R, CHROMA_G, CHROMA_B)
            Wait2(50)
            for i = 0, 3 do
                NV(NAT2.SET_VEHICLE_NEON_LIGHT_ENABLED, veh, i, true)
            end
            Wait2(50)

            NV(NAT2.SET_VEHICLE_TYRE_SMOKE_COLOR, veh, CHROMA_R, CHROMA_G, CHROMA_B)
            Wait2(50)

            NV(NAT2.SET_VEHICLE_TYRES_CAN_BURST, veh, false)
            Wait2(80)
            NV(NAT2.SET_VEHICLE_DIRT_LEVEL, veh, 0.0)

            Notify2("Upgrade", name .. " maxed + crimson chrome!")
        end)

        if not ok then
            Notify2("Upgrade", name .. " partial upgrade")
        end
    end

    local function PaintVehicleBlack(veh)
        if veh == 0 or not NB(NAT2.DOES_ENTITY_EXIST, veh) then return end
        pcall(function()
            NV(NAT2.SET_VEHICLE_MOD_KIT, veh, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_MOD_COLOR_1, veh, 0, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_MOD_COLOR_2, veh, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR, veh, 0, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR, veh, 0, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_EXTRA_COLOURS, veh, 0, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_DIRT_LEVEL, veh, 0.0)
        end)
    end

    local function LockPedInVehicle2(ped, veh)
        if ped == 0 then return end
        pcall(function()
            NV(NAT2.SET_PED_CONFIG_FLAG, ped, 32, false)
            NV(NAT2.SET_PED_CONFIG_FLAG, ped, 168, true)
            NV(NAT2.SET_PED_CONFIG_FLAG, ped, 177, true)
            NV(NAT2.SET_PED_CAN_BE_DRAGGED_OUT, ped, false)
            NV(NAT2.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS, ped, true)
            NV(NAT2.SET_PED_FLEE_ATTRIBUTES, ped, 0, false)
            NV(NAT2.SET_PED_COMBAT_ATTRIBUTES, ped, 46, true)
            NV(NAT2.SET_PED_COMBAT_ATTRIBUTES, ped, 52, true)
            if veh ~= 0 then
                NV(NAT2.SET_VEHICLE_DOORS_LOCKED, veh, 4)
            end
        end)
    end

    local function ArmPed(ped)
        if ped == 0 then return end
        pcall(function()
            local minigun = Utils.Joaat("WEAPON_MINIGUN")
            NV(NAT2.GIVE_WEAPON_TO_PED, ped, minigun, 9999, false, true)
            Wait2(50)
            NV(NAT2.SET_CURRENT_PED_WEAPON, ped, minigun, true)
            Wait2(50)
        end)
    end

    
    local function DelSafe(handle, delFunc)
        if handle and handle ~= 0 and NB(NAT2.DOES_ENTITY_EXIST, handle) then
            NV(delFunc, handle)
        end
    end

    local function ClearAll()
        local total = 0
        for _, build in ipairs(spawnedBuilds) do
            if build.items then
                for _, item in ipairs(build.items) do
                    if item.children then
                        for _, c in ipairs(item.children) do
                            if c.type == "ped" then DelSafe(c.handle, NAT2.DELETE_PED)
                            elseif c.type == "object" then DelSafe(c.handle, NAT2.DELETE_OBJECT)
                            elseif c.type == "vehicle" then DelSafe(c.handle, NAT2.DELETE_VEHICLE) end
                            total = total + 1
                        end
                    end
                    if item.type == "vehicle" then DelSafe(item.handle, NAT2.DELETE_VEHICLE)
                    elseif item.type == "object" then DelSafe(item.handle, NAT2.DELETE_OBJECT)
                    elseif item.type == "ped" then DelSafe(item.handle, NAT2.DELETE_PED) end
                    total = total + 1
                end
            end
            DelSafe(build.base, NAT2.DELETE_VEHICLE)
            total = total + 1
        end
        spawnedBuilds = {}
        Notify2("Spawner", "Cleared " .. total .. " entities")
    end

    local function UpgradeVehicleBasic(veh, name)
        if veh == 0 or not NB(NAT2.DOES_ENTITY_EXIST, veh) then
            Notify2("Upgrade", name .. " invalid vehicle")
            return
        end
        local ok = pcall(function()
            NV(NAT2.SET_VEHICLE_MOD_KIT, veh, -1)
            Wait2(150)
            NV(NAT2.SET_VEHICLE_MOD_KIT, veh, 0)
            Wait2(150)
            local mods = {
                {11, 3}, {12, 2}, {13, 2}, {14, 1}, {15, 3},
                {16, 4}, {33, 1}, {48, 0}, {42, 1}, {43, 0},
            }
            for _, m in ipairs(mods) do
                NV(NAT2.SET_VEHICLE_MOD, veh, m[1], m[2], false)
                Wait2(80)
            end
            NV(NAT2.SET_VEHICLE_TYRES_CAN_BURST, veh, false)
            Wait2(80)
            NV(NAT2.SET_VEHICLE_EXTRA_COLOURS, veh, 135, 0)
            Wait2(50)
            NV(NAT2.SET_VEHICLE_DIRT_LEVEL, veh, 0.0)
            Notify2("Upgrade", name .. " upgrade applied")
        end)
        if not ok then
            Notify2("Upgrade", name .. " partial upgrade")
        end
    end

    local CONFIG = {
        base = { model = "bruiser", invincible = true },
        slots = {
            {
                enabled = true, model = "buzzard", type = "vehicle",
                offsetX = -4.0, offsetY = -3.6, offsetZ = 4.0,
                rotX = 40.0, rotY = 90.0, rotZ = 90.0,
                invincible = true, collision = true, visible = true,
                engineOn = true, fullBlades = true,
                spawnPeds = true, pedModel = "s_m_y_blackops_01", pedCount = 2,
                spawnProps = true, propModel = "prop_ld_pipe_single_01",
                propFallback = "prop_ind_pipe_01", propCount = 4, propRadius = 0.7,
                propBone = "main_rotor", propRotX = 90.0, propRotY = 0.0,
                hubs = {
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 0.7, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 2.4, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 3.8, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                },
            },
            {
                enabled = true, model = "buzzard", type = "vehicle",
                offsetX = 4.0, offsetY = -3.6, offsetZ = 4.0,
                rotX = 40.0, rotY = -90.0, rotZ = -90.0,
                invincible = true, collision = true, visible = true,
                engineOn = true, fullBlades = true,
                spawnPeds = true, pedModel = "s_m_y_blackops_01", pedCount = 2,
                spawnProps = true, propModel = "prop_ld_pipe_single_01",
                propFallback = "prop_ind_pipe_01", propCount = 4, propRadius = 0.7,
                propBone = "main_rotor", propRotX = 90.0, propRotY = 0.0,
                hubs = {
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 0.7, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 2.4, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.0, offsetY = -1.4, offsetZ = 3.8, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                },
            },
            { enabled = false }, { enabled = false }, { enabled = false }, { enabled = false },
        }
    }

    local function SpawnSlot(cfg, px, py, pz, baseHandle)
        local item = { handle = 0, type = cfg.type or "object", children = {} }
        local sx, sy, sz = px + (cfg.offsetX or 0), py + (cfg.offsetY or 0), pz + (cfg.offsetZ or 0)
        if cfg.type == "vehicle" then
            local ptr = GTA.SpawnVehicle(cfg.model, sx, sy, sz, 0.0, true, true)
            item.handle = ToHandle(ptr)
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, true)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
            if cfg.engineOn then NV(NAT2.SET_VEHICLE_ENGINE_ON, item.handle, true, true, false) end
            if cfg.fullBlades then NV(NAT2.SET_HELI_BLADES_FULL_SPEED, item.handle) end
            UpgradeVehicleBasic(item.handle, cfg.model)
            Wait2(50)
            if cfg.spawnPeds then
                for p = 1, (cfg.pedCount or 0) do
                    local pp = GTA.CreatePed(cfg.pedModel or "s_m_y_blackops_01", 26, sx, sy, sz + 3.0, 0.0, true, true)
                    local ped = ToHandle(pp)
                    if ped ~= 0 then
                        local seat = (p == 1) and -1 or (p - 2)
                        NV(NAT2.SET_PED_INTO_VEHICLE, ped, item.handle, seat)
                        NV(NAT2.SET_ENTITY_INVINCIBLE, ped, true)
                        LockPedInVehicle2(ped, item.handle)
                        table.insert(item.children, {handle = ped, type = "ped"})
                    end
                end
            end
            Wait2(50)
        elseif cfg.type == "object" then
            local ptr = GTA.CreateObject(cfg.model, sx, sy, sz, true, false)
            item.handle = ToHandle(ptr)
            if item.handle == 0 and cfg.propFallback then
                ptr = GTA.CreateObject(cfg.propFallback, sx, sy, sz, true, false)
                item.handle = ToHandle(ptr)
            end
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, false)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
        elseif cfg.type == "ped" then
            local ptr = GTA.CreatePed(cfg.model, 26, sx, sy, sz, 0.0, true, true)
            item.handle = ToHandle(ptr)
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, true)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
        end
        if item.handle ~= 0 then NV(NAT2.NETWORK_REGISTER_ENTITY, item.handle) end
        if baseHandle ~= 0 and item.handle ~= 0 then
            NV(NAT2.ATTACH_ENTITY_TO_ENTITY, item.handle, baseHandle, 0,
                cfg.offsetX or 0, cfg.offsetY or 0, cfg.offsetZ or 0,
                cfg.rotX or 0, cfg.rotY or 0, cfg.rotZ or 0,
                false, false, cfg.collision ~= false, false, 2, true, 0)
        end
        if cfg.spawnProps and cfg.type == "vehicle" and item.handle ~= 0 then
            local bone = NI(NAT2.GET_ENTITY_BONE_INDEX, item.handle, cfg.propBone or "main_rotor")
            if bone == -1 then bone = 16 end
            for i = 0, (cfg.propCount or 4) - 1 do
                local ang = i * (360.0 / (cfg.propCount or 4))
                local rad = math.rad(ang)
                local ox = math.cos(rad) * (cfg.propRadius or 3.2)
                local oy = math.sin(rad) * (cfg.propRadius or 3.2)
                local op = GTA.CreateObject(cfg.propModel or "prop_ld_pipe_single", 0, 0, 0, true, false)
                local obj = ToHandle(op)
                if obj == 0 and cfg.propFallback then
                    op = GTA.CreateObject(cfg.propFallback, 0, 0, 0, true, false)
                    obj = ToHandle(op)
                end
                if obj ~= 0 then
                    NV(NAT2.NETWORK_REGISTER_ENTITY, obj)
                    NV(NAT2.SET_ENTITY_COLLISION, obj, false, false)
                    NV(NAT2.SET_ENTITY_VISIBLE, obj, true, false)
                    NV(NAT2.ATTACH_ENTITY_TO_ENTITY, obj, item.handle, bone,
                        ox, oy, 0.0, cfg.propRotX or 0, cfg.propRotY or 0, ang,
                        false, false, false, false, 2, true, 0)
                    table.insert(item.children, {handle = obj, type = "object"})
                    Wait2(50)
                end
            end
        end
        if cfg.hubs and cfg.type == "vehicle" and item.handle ~= 0 then
            for _, hub in ipairs(cfg.hubs) do
                if hub.enabled then
                    local hubBone = NI(NAT2.GET_ENTITY_BONE_INDEX, item.handle, hub.bone or "chassis")
                    if hubBone == -1 then hubBone = 0 end
                    local hop = GTA.CreateObject(hub.model, 0, 0, 0, true, false)
                    local hubObj = ToHandle(hop)
                    if hubObj == 0 and hub.fallback then
                        hop = GTA.CreateObject(hub.fallback, 0, 0, 0, true, false)
                        hubObj = ToHandle(hop)
                    end
                    if hubObj ~= 0 then
                        NV(NAT2.NETWORK_REGISTER_ENTITY, hubObj)
                        NV(NAT2.SET_ENTITY_COLLISION, hubObj, false, false)
                        NV(NAT2.SET_ENTITY_VISIBLE, hubObj, true, false)
                        NV(NAT2.ATTACH_ENTITY_TO_ENTITY, hubObj, item.handle, hubBone,
                            hub.offsetX or 0, hub.offsetY or 0, hub.offsetZ or 0,
                            hub.rotX or 0, hub.rotY or 0, hub.rotZ or 0,
                            false, false, false, false, 2, true, 0)
                        table.insert(item.children, {handle = hubObj, type = "object"})
                        Wait2(50)
                    end
                end
            end
        end
        return item
    end

    local function DoSpawn()
        local px, py, pz = GetPlayerPos2()
        local bptr = GTA.SpawnVehicle(CONFIG.base.model, px, py, pz, 0.0, true, true)
        local base = ToHandle(bptr)
        if base == 0 then Notify2("Spawner", "Failed to spawn"); return end
        NV(NAT2.SET_ENTITY_INVINCIBLE, base, CONFIG.base.invincible ~= false)
        UpgradeVehicleBasic(base, "Bruiser")
        Wait2(100)
        NV(NAT2.SET_VEHICLE_ENGINE_ON, base, true, true, false)
        local playerPed = NI(NAT2.GET_PLAYER_PED, GTA.GetLocalPlayerId())
        NV(NAT2.SET_PED_INTO_VEHICLE, playerPed, base, -1)
        local build = { base = base, items = {} }
        for i, slot in ipairs(CONFIG.slots) do
            if slot.enabled then
                local item = SpawnSlot(slot, px, py, pz, base)
                if item then table.insert(build.items, item)
                else Notify2("Spawner", "Slot " .. i .. " failed") end
                Wait2(100)
            end
        end
        table.insert(spawnedBuilds, build)
        Notify2("Spawner", "Build #" .. #spawnedBuilds .. " ready!")
    end

    local FEAT_SPAWN = Utils.Joaat("bruiser_final_spawn")

    FeatureMgr.AddFeature(FEAT_SPAWN, "Spawn Bruiser Modded", eFeatureType.Button, "Spawn a new Minigun Bruiser", function()
        DoSpawn()
    end)

    local CONFIG2 = {
        base = { model = "phantom2", invincible = true },
        slots = {
            {
                enabled = true, model = "avenger", type = "vehicle",
                offsetX = -4.0, offsetY = -4.0, offsetZ = 9.0,
                rotX = -90.0, rotY = 0.0, rotZ = 0.0,
                invincible = true, collision = true, visible = true,
                engineOn = true, fullBlades = true,
                spawnPeds = true, pedModel = "s_m_y_blackops_01", pedCount = 2,
                spawnProps = true, propModel = "prop_ld_pipe_single_01",
                propFallback = "prop_ind_pipe_01", propCount = 6, propRadius = 1.0,
                propBone = "prop_1", propBone2 = "prop_2", propRotX = 90.0, propRotY = 0.0,
                hubs = {
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = -0.8, offsetY = 1.0, offsetZ = 2.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = -0.8, offsetY = 1.0, offsetZ = 4.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = -0.8, offsetY = 1.0, offsetZ = 6.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                },
            },
            {
                enabled = true, model = "avenger", type = "vehicle",
                offsetX = 4.0, offsetY = -4.0, offsetZ = 9.0,
                rotX = -90.0, rotY = 0.0, rotZ = 0.0,
                invincible = true, collision = true, visible = true,
                engineOn = true, fullBlades = true,
                spawnPeds = true, pedModel = "s_m_y_blackops_01", pedCount = 2,
                spawnProps = true, propModel = "prop_ld_pipe_single_01",
                propFallback = "prop_ind_pipe_01", propCount = 6, propRadius = 1.0,
                propBone = "prop_1", propBone2 = "prop_2", propRotX = 90.0, propRotY = 0.0,
                hubs = {
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.8, offsetY = 1.0, offsetZ = 2.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.8, offsetY = 1.0, offsetZ = 4.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                    { enabled = true, model = "vw_prop_vw_luckywheel_01a", fallback = "vw_prop_vw_luckywheel_02a", bone = "chassis",
                      offsetX = 0.8, offsetY = 1.0, offsetZ = 6.9, rotX = -90.0, rotY = 0.0, rotZ = 0.0 },
                },
            },
            { enabled = true, model = "freight", type = "vehicle", offsetX = 2.0, offsetY = -2.0, offsetZ = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0, invincible = true, collision = true, visible = true, engineOn = true, paint = "black" },
            { enabled = true, model = "freight", type = "vehicle", offsetX = -2.0, offsetY = -2.0, offsetZ = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0, invincible = true, collision = true, visible = true, engineOn = true, paint = "black" },
            { enabled = true, model = "freightcont1", type = "vehicle", offsetX = 0.0, offsetY = -2.7, offsetZ = -2.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0, invincible = true, collision = true, visible = true, engineOn = true, paint = "black" },
            { enabled = true, model = "freightcont1", type = "vehicle", offsetX = 0.0, offsetY = -4.2, offsetZ = 4.4, rotX = 0.0, rotY = 0.0, rotZ = 90.0, invincible = true, collision = true, visible = true, engineOn = true, paint = "black" },
            { enabled = true, model = "freightcont1", type = "vehicle", offsetX = 0.0, offsetY = -4.2, offsetZ = 2.1, rotX = 0.0, rotY = 0.0, rotZ = 90.0, invincible = true, collision = true, visible = true, engineOn = true, paint = "black" },
        }
    }

    local function SpawnPropsOnBone(cfg, item, boneName)
        if not boneName or boneName == "" then return end
        local bone = NI(NAT2.GET_ENTITY_BONE_INDEX, item.handle, boneName)
        if bone == -1 then bone = 16 end
        for i = 0, (cfg.propCount or 4) - 1 do
            local ang = i * (360.0 / (cfg.propCount or 4))
            local rad = math.rad(ang)
            local ox = math.cos(rad) * (cfg.propRadius or 3.2)
            local oy = math.sin(rad) * (cfg.propRadius or 3.2)
            local op = GTA.CreateObject(cfg.propModel or "prop_ld_pipe_single", 0, 0, 0, true, false)
            local obj = ToHandle(op)
            if obj == 0 and cfg.propFallback then
                op = GTA.CreateObject(cfg.propFallback, 0, 0, 0, true, false)
                obj = ToHandle(op)
            end
            if obj ~= 0 then
                NV(NAT2.NETWORK_REGISTER_ENTITY, obj)
                NV(NAT2.SET_ENTITY_COLLISION, obj, false, false)
                NV(NAT2.SET_ENTITY_VISIBLE, obj, true, false)
                NV(NAT2.ATTACH_ENTITY_TO_ENTITY, obj, item.handle, bone,
                    ox, oy, 0.0, cfg.propRotX or 0, cfg.propRotY or 0, ang,
                    false, false, false, false, 2, true, 0)
                table.insert(item.children, {handle = obj, type = "object"})
                Wait2(50)
            end
        end
    end

    local function SpawnSlot2(cfg, px, py, pz, baseHandle)
        local item = { handle = 0, type = cfg.type or "object", children = {} }
        local sx, sy, sz = px + (cfg.offsetX or 0), py + (cfg.offsetY or 0), pz + (cfg.offsetZ or 0)
        if cfg.type == "vehicle" then
            local ptr = GTA.SpawnVehicle(cfg.model, sx, sy, sz, 0.0, true, true)
            item.handle = ToHandle(ptr)
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, true)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
            if cfg.engineOn then NV(NAT2.SET_VEHICLE_ENGINE_ON, item.handle, true, true, false) end
            if cfg.fullBlades then NV(NAT2.SET_HELI_BLADES_FULL_SPEED, item.handle) end
            if cfg.paint == "black" then PaintVehicleBlack(item.handle) else UpgradeVehicle2(item.handle, cfg.model) end
            Wait2(50)
            if cfg.spawnPeds then
                for p = 1, (cfg.pedCount or 0) do
                    local pp = GTA.CreatePed(cfg.pedModel or "s_m_y_blackops_01", 26, sx, sy, sz + 3.0, 0.0, true, true)
                    local ped = ToHandle(pp)
                    if ped ~= 0 then
                        local seat = (p == 1) and -1 or (p - 2)
                        NV(NAT2.SET_PED_INTO_VEHICLE, ped, item.handle, seat)
                        NV(NAT2.SET_ENTITY_INVINCIBLE, ped, true)
                        LockPedInVehicle2(ped, item.handle)
                        table.insert(item.children, {handle = ped, type = "ped"})
                    end
                end
            end
            Wait2(50)
        elseif cfg.type == "object" then
            local ptr = GTA.CreateObject(cfg.model, sx, sy, sz, true, false)
            item.handle = ToHandle(ptr)
            if item.handle == 0 and cfg.propFallback then
                ptr = GTA.CreateObject(cfg.propFallback, sx, sy, sz, true, false)
                item.handle = ToHandle(ptr)
            end
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, false)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
        elseif cfg.type == "ped" then
            local ptr = GTA.CreatePed(cfg.model, 26, sx, sy, sz, 0.0, true, true)
            item.handle = ToHandle(ptr)
            if item.handle == 0 then return nil end
            NV(NAT2.SET_ENTITY_INVINCIBLE, item.handle, cfg.invincible ~= false)
            NV(NAT2.SET_ENTITY_COLLISION, item.handle, cfg.collision ~= false, true)
            NV(NAT2.SET_ENTITY_VISIBLE, item.handle, cfg.visible ~= false, false)
        end
        if item.handle ~= 0 then NV(NAT2.NETWORK_REGISTER_ENTITY, item.handle) end
        if baseHandle ~= 0 and item.handle ~= 0 then
            NV(NAT2.ATTACH_ENTITY_TO_ENTITY, item.handle, baseHandle, 0,
                cfg.offsetX or 0, cfg.offsetY or 0, cfg.offsetZ or 0,
                cfg.rotX or 0, cfg.rotY or 0, cfg.rotZ or 0,
                false, false, cfg.collision ~= false, false, 2, true, 0)
        end
        if cfg.spawnProps and cfg.type == "vehicle" and item.handle ~= 0 then
            SpawnPropsOnBone(cfg, item, cfg.propBone)
            if cfg.propBone2 then SpawnPropsOnBone(cfg, item, cfg.propBone2) end
        end
        if cfg.hubs and cfg.type == "vehicle" and item.handle ~= 0 then
            for _, hub in ipairs(cfg.hubs) do
                if hub.enabled then
                    local hubBone = NI(NAT2.GET_ENTITY_BONE_INDEX, item.handle, hub.bone or "chassis")
                    if hubBone == -1 then hubBone = 0 end
                    local hop = GTA.CreateObject(hub.model, 0, 0, 0, true, false)
                    local hubObj = ToHandle(hop)
                    if hubObj == 0 and hub.fallback then
                        hop = GTA.CreateObject(hub.fallback, 0, 0, 0, true, false)
                        hubObj = ToHandle(hop)
                    end
                    if hubObj ~= 0 then
                        NV(NAT2.NETWORK_REGISTER_ENTITY, hubObj)
                        NV(NAT2.SET_ENTITY_COLLISION, hubObj, false, false)
                        NV(NAT2.SET_ENTITY_VISIBLE, hubObj, true, false)
                        NV(NAT2.ATTACH_ENTITY_TO_ENTITY, hubObj, item.handle, hubBone,
                            hub.offsetX or 0, hub.offsetY or 0, hub.offsetZ or 0,
                            hub.rotX or 0, hub.rotY or 0, hub.rotZ or 0,
                            false, false, false, false, 2, true, 0)
                        table.insert(item.children, {handle = hubObj, type = "object"})
                        Wait2(50)
                    end
                end
            end
        end
        return item
    end

    local function DoSpawn2()
        local px, py, pz = GetPlayerPos2()
        local bptr = GTA.SpawnVehicle(CONFIG2.base.model, px, py, pz, 0.0, true, true)
        local base = ToHandle(bptr)
        if base == 0 then Notify2("Spawner", "Failed to spawn"); return end
        NV(NAT2.SET_ENTITY_INVINCIBLE, base, CONFIG2.base.invincible ~= false)
        UpgradeVehicle2(base, "Phantom Wedge")
        Wait2(100)
        NV(NAT2.SET_VEHICLE_ENGINE_ON, base, true, true, false)
        local playerPed = NI(NAT2.GET_PLAYER_PED, GTA.GetLocalPlayerId())
        NV(NAT2.SET_PED_INTO_VEHICLE, playerPed, base, -1)
        local build = { base = base, items = {} }
        for i, slot in ipairs(CONFIG2.slots) do
            if slot.enabled then
                local item = SpawnSlot2(slot, px, py, pz, base)
                if item then table.insert(build.items, item)
                else Notify2("Spawner", "Slot " .. i .. " failed!") end
                Wait2(100)
            end
        end
        table.insert(spawnedBuilds2, build)
        Notify2("Spawner", "Build #" .. #spawnedBuilds2 .. " ready")
    end

    local function ClearAll2()
        local total = 0
        for _, build in ipairs(spawnedBuilds2) do
            if build.items then
                for _, item in ipairs(build.items) do
                    if item.children then
                        for _, c in ipairs(item.children) do
                            if c.type == "ped" then DelSafe(c.handle, NAT2.DELETE_PED)
                            elseif c.type == "object" then DelSafe(c.handle, NAT2.DELETE_OBJECT)
                            elseif c.type == "vehicle" then DelSafe(c.handle, NAT2.DELETE_VEHICLE) end
                            total = total + 1
                        end
                    end
                    if item.type == "vehicle" then DelSafe(item.handle, NAT2.DELETE_VEHICLE)
                    elseif item.type == "object" then DelSafe(item.handle, NAT2.DELETE_OBJECT)
                    elseif item.type == "ped" then DelSafe(item.handle, NAT2.DELETE_PED) end
                    total = total + 1
                end
            end
            DelSafe(build.base, NAT2.DELETE_VEHICLE)
            total = total + 1
        end
        spawnedBuilds2 = {}
        Notify2("Spawner", "Cleared " .. total .. " entities")
    end

    local FEAT_SPAWN2 = Utils.Joaat("phantom_wedge_spawn")

    FeatureMgr.AddFeature(FEAT_SPAWN2, "Spawn Destroyer", eFeatureType.Button, "Spawn a phantom Robot?", function()
        DoSpawn2()
    end)

    local function AttachRotorPipes(vehicle, item)
        if vehicle == 0 then return end
        local bone = NI(NAT2.GET_ENTITY_BONE_INDEX, vehicle, "rotor_main")
        if bone == -1 then bone = 0 end
        local pipeCount = 4
        for i = 1, pipeCount do
            local ang = (i - 1) * (360.0 / pipeCount)
            local rad = math.rad(ang)
            local ox = math.cos(rad) * 2.8
            local oy = math.sin(rad) * 2.8
            local pipe = GTA.CreateObject("prop_ld_pipe_single_01", 0, 0, 0, true, false)
            local pipeHandle = ToHandle(pipe)
            if pipeHandle == 0 then
                pipe = GTA.CreateObject("prop_ind_pipe_01", 0, 0, 0, true, false)
                pipeHandle = ToHandle(pipe)
            end
            if pipeHandle ~= 0 then
                NV(NAT2.NETWORK_REGISTER_ENTITY, pipeHandle)
                NV(NAT2.SET_ENTITY_COLLISION, pipeHandle, false, false)
                NV(NAT2.SET_ENTITY_VISIBLE, pipeHandle, true, false)
                NV(NAT2.ATTACH_ENTITY_TO_ENTITY, pipeHandle, vehicle, bone,
                    ox, oy, 0.0, 90.0, 0.0, ang,
                    false, false, false, false, 2, true, 0)
                table.insert(item.children, {handle = pipeHandle, type = "object"})
            end
            Wait2(30)
        end
    end

    local function DoSpawnBuzzardAntiAir()
        local px, py, pz = GetPlayerPos2()
        local bptr = GTA.SpawnVehicle("buzzard", px, py, pz + 2.0, 0.0, true, true)
        local buzzard = ToHandle(bptr)
        if buzzard == 0 then Notify2("Spawner", "Buzzard spawn failed!"); return end
        MakeVehicleGodmode(buzzard)
        NV(NAT2.SET_ENTITY_COLLISION, buzzard, true, true)
        NV(NAT2.SET_ENTITY_VISIBLE, buzzard, true, false)
        NV(NAT2.SET_VEHICLE_ENGINE_ON, buzzard, true, true, false)
        NV(NAT2.SET_HELI_BLADES_FULL_SPEED, buzzard)
        UpgradeVehicle2(buzzard, "Buzzard")
        Wait2(200)
        local playerPed = NI(NAT2.GET_PLAYER_PED, GTA.GetLocalPlayerId())
        NV(NAT2.SET_PED_INTO_VEHICLE, playerPed, buzzard, -1)
        local build = { base = buzzard, items = {} }
        local rows = {
            { radius = 8.0, height = 0.0, count = 6 },
            { radius = 14.0, height = -3.0, count = 6 },
            { radius = 14.0, height = 3.0, count = 6 },
            { radius = 20.0, height = 0.0, count = 6 },
        }
        for _, row in ipairs(rows) do
            for i = 1, row.count do
                local deg = (i - 1) * (360.0 / row.count)
                local rad = math.rad(deg)
                local ox = math.cos(rad) * row.radius
                local oy = math.sin(rad) * row.radius
                local eptr = GTA.SpawnVehicle("buzzard", px + ox, py + oy, pz + row.height, 0.0, true, true)
                local escort = ToHandle(eptr)
                if escort ~= 0 then
                    MakeVehicleGodmode(escort)
                    NV(NAT2.SET_ENTITY_COLLISION, escort, false, true)
                    NV(NAT2.SET_ENTITY_VISIBLE, escort, true, false)
                    NV(NAT2.SET_VEHICLE_ENGINE_ON, escort, true, true, false)
                    NV(NAT2.SET_HELI_BLADES_FULL_SPEED, escort)
                    PaintVehicleBlack(escort)
                    Wait2(80)
                    NV(NAT2.ATTACH_ENTITY_TO_ENTITY, escort, buzzard, 0,
                        ox, oy, row.height, 0.0, 0.0, deg + 180.0,
                        false, false, false, false, 2, true, 0)
                    local item = { handle = escort, type = "vehicle", children = {} }
                    AttachRotorPipes(escort, item)
                    for p = 1, 2 do
                        local pp = GTA.CreatePed("s_m_y_blackops_01", 26, px + ox, py + oy, pz + row.height + 3.0, 0.0, true, true)
                        local ped = ToHandle(pp)
                        if ped ~= 0 then
                            local seat = (p == 1) and -1 or (p - 2)
                            NV(NAT2.SET_PED_INTO_VEHICLE, ped, escort, seat)
                            NV(NAT2.SET_ENTITY_INVINCIBLE, ped, true)
                            LockPedInVehicle2(ped, escort)
                            ArmPed(ped)
                            table.insert(item.children, {handle = ped, type = "ped"})
                        end
                    end
                    table.insert(build.items, item)
                end
                Wait2(40)
            end
        end
        table.insert(spawnedBuilds2, build)
        Notify2("Spawner", "Buzzard Mod " .. #build.items .. "buzzard support")
    end

    local FEAT_BUZZARD_AA = Utils.Joaat("buzzard_antiair_spawn")

    FeatureMgr.AddFeature(FEAT_BUZZARD_AA, "Buzzard Swarm", eFeatureType.Button, "Spawn Buzzard with 24 escort Buzzards", function()
        DoSpawnBuzzardAntiAir()
    end)
local function AttachAvengerPropBongs(avenger, item, kuruma, playerPed)
        if avenger == 0 or not NB(NAT2.DOES_ENTITY_EXIST, avenger) then return end

        local propHash = Utils.Joaat("prop_pipes_conc_01")
        local px, py, pz = GetPlayerPos2()

        local rotors = {
            { boneName = "prop_1" },
            { boneName = "prop_2" }
        }

        local pipesPerCircle = 6
        local radius = 2.2
        local heightenedZ = 3.5

        for _, rotorInfo in ipairs(rotors) do
            local rotorBone = NI(NAT2.GET_ENTITY_BONE_INDEX, avenger, rotorInfo.boneName)

            for i = 1, pipesPerCircle do
                local angle = (i - 1) * (2 * math.pi / pipesPerCircle)
                local offsetX = math.cos(angle) * radius
                local offsetY = 0.0
                local offsetZ = heightenedZ + math.sin(angle) * radius

                local propPtr = GTA.CreateObject(propHash, px, py, pz + 5.0, true, true)
                local propObj = ToHandle(propPtr)

                if propObj ~= 0 then
                    NV(NAT2.SET_ENTITY_INVINCIBLE, propObj, true)
                    NV(NAT2.SET_ENTITY_PROOFS, propObj, true, true, true, true, true, true, true, true)
                    NV(NAT2.SET_ENTITY_VISIBLE, propObj, true, false)

                    NV(NAT2.SET_ENTITY_COLLISION, propObj, true, true)

                    NV(NAT2.ATTACH_ENTITY_TO_ENTITY, propObj, avenger, rotorBone,
                        offsetX, offsetY, offsetZ,
                        90.0, 0.0, 0.0,
                        false, false, true, false, 2, true, 0)

                    if item and item.children then
                        table.insert(item.children, { handle = propObj, type = "object" })
                    end
                end
            end
        end
    end

    local InvokeBool, InvokeInt, InvokeVoid = Natives.InvokeBool, Natives.InvokeInt, Natives.InvokeVoid
    local InvokeV3 = Natives.InvokeV3

    local PLAYER_PED_ID = function(...) return InvokeInt(0x50FAC3A3E030A6E1, ...) end
    local GET_VEHICLE_PED_IS_IN = function(ped, lastVehicle) return InvokeInt(0x9A9112A0FE9A4713, ped, lastVehicle) end
    local GET_PED_IN_VEHICLE_SEAT = function(vehicle, seatIndex) return InvokeInt(0xBB40DD2270B65366, vehicle, seatIndex) end
    local GET_GAMEPLAY_CAM_ROT = function(rotationOrder) return InvokeV3(0x837765A25378F0BB, rotationOrder) end
    local IS_CONTROL_PRESSED = function(controlGroup, control) return InvokeBool(0xE2587F8CBBD87B1D, controlGroup, control) end
    local SET_ENTITY_VELOCITY = function(entity, x, y, z) return InvokeVoid(0x1C99BB7B6E96D16F, entity, x+.0, y+.0, z+.0) end
    local SET_ENTITY_ROTATION = function(entity, pitch, roll, yaw, rotationOrder, p5) return InvokeVoid(0x8524A8B0171D5E07, entity, pitch+.0, roll+.0, yaw+.0, rotationOrder, p5) end
    local SET_ENTITY_HAS_GRAVITY = function(entity, toggle) return InvokeVoid(0x89F149B6131E57DA, entity, toggle) end
    local SET_ENTITY_COLLISION = function(entity, toggle, keepPhysics) return InvokeVoid(0x1A9205C1B9EE827F, entity, toggle, keepPhysics) end
    local DOES_ENTITY_EXIST = function(entity) return InvokeBool(0x7239B21A38F536BA, entity) end

    local fly_vel = {x=0, y=0, z=0}
    local last_fly_veh = 0

    local function reset_fly_vel()
        fly_vel.x, fly_vel.y, fly_vel.z = 0, 0, 0
    end

    local function do_vehicle_fly()
        local ped = PLAYER_PED_ID(GTA.GetLocalPlayerId())
        local veh = GET_VEHICLE_PED_IS_IN(ped, false)
        if veh == 0 then return end

        if veh ~= last_fly_veh then
            reset_fly_vel()
            last_fly_veh = veh
        end

        local cx, cy, cz = GET_GAMEPLAY_CAM_ROT(2)
        local speed = 1.0

        if IS_CONTROL_PRESSED(0, 22) then
            speed = 3.0
        end

        local radZ = math.rad(cz)
        local radX = math.rad(cx)

        local fx = -math.sin(radZ) * math.cos(radX)
        local fy = math.cos(radZ) * math.cos(radX)
        local fz = math.sin(radX)

        local accel = 0.5 * speed
        local has_input = false

        if IS_CONTROL_PRESSED(0, 71) then
            fly_vel.x = fly_vel.x + fx * accel
            fly_vel.y = fly_vel.y + fy * accel
            fly_vel.z = fly_vel.z + fz * accel
            has_input = true
        end
        if IS_CONTROL_PRESSED(0, 72) then
            fly_vel.x = fly_vel.x - fx * accel
            fly_vel.y = fly_vel.y - fy * accel
            fly_vel.z = fly_vel.z - fz * accel
            has_input = true
        end
        if IS_CONTROL_PRESSED(0, 63) then
            fly_vel.x = fly_vel.x - math.cos(radZ) * accel
            fly_vel.y = fly_vel.y - math.sin(radZ) * accel
            has_input = true
        end
        if IS_CONTROL_PRESSED(0, 64) then
            fly_vel.x = fly_vel.x + math.cos(radZ) * accel
            fly_vel.y = fly_vel.y + math.sin(radZ) * accel
            has_input = true
        end
        if IS_CONTROL_PRESSED(0, 21) then
            fly_vel.z = fly_vel.z + 0.5 * speed
            has_input = true
        end
        if IS_CONTROL_PRESSED(0, 36) then
            fly_vel.z = fly_vel.z - 0.5 * speed
            has_input = true
        end

        if not has_input then
            local drag = 0.92
            fly_vel.x = fly_vel.x * drag
            fly_vel.y = fly_vel.y * drag
            fly_vel.z = fly_vel.z * drag
        end

        local max_speed = 80.0
        local cur_speed = math.sqrt(fly_vel.x^2 + fly_vel.y^2 + fly_vel.z^2)
        if cur_speed > max_speed then
            local scale = max_speed / cur_speed
            fly_vel.x = fly_vel.x * scale
            fly_vel.y = fly_vel.y * scale
            fly_vel.z = fly_vel.z * scale
        end

        SET_ENTITY_VELOCITY(veh, fly_vel.x, fly_vel.y, fly_vel.z)
        SET_ENTITY_ROTATION(veh, cx, 0.0, cz, 2, true)
    end

    local function toggle_vehicle_fly(enable)
        if enable then
            if is_flying then return end

            local ped = PLAYER_PED_ID(GTA.GetLocalPlayerId())
            local veh = GET_VEHICLE_PED_IS_IN(ped, false)
            if veh == 0 then
                if spawnerSettings then
                    spawnerSettings.vehicleFly = false
                end
                return
            end

            is_flying = true
            reset_fly_vel()
            last_fly_veh = veh
            GUI.AddToast("Vehicle Fly", "space =speed shift = up ctrl = down", 8000, 0)

            Script.QueueJob(function()
                local last_veh = 0
                while is_flying do
                    local ped = PLAYER_PED_ID(GTA.GetLocalPlayerId())
                    local current_veh = GET_VEHICLE_PED_IS_IN(ped, false)

                    if current_veh == 0 then
                        is_flying = false
                        reset_fly_vel()
                        last_fly_veh = 0
                        if spawnerSettings then
                            spawnerSettings.vehicleFly = false
                        end
                    else
                        last_veh = current_veh
                        if GET_PED_IN_VEHICLE_SEAT(current_veh, -1) == ped then
                            SET_ENTITY_HAS_GRAVITY(current_veh, false)
                            do_vehicle_fly()
                        else
                            SET_ENTITY_HAS_GRAVITY(current_veh, true)
                            SET_ENTITY_COLLISION(current_veh, true, true)
                        end
                    end
                    Script.Yield(0)
                end

                if last_veh ~= 0 and DOES_ENTITY_EXIST(last_veh) then
                    SET_ENTITY_HAS_GRAVITY(last_veh, true)
                    SET_ENTITY_COLLISION(last_veh, true, true)
                end
                reset_fly_vel()
                last_fly_veh = 0
            end)
        else
            is_flying = false
            reset_fly_vel()
            last_fly_veh = 0
        end
    end

    local function DoSpawnKurumaBuzzard()
        local px, py, pz = GetPlayerPos2()

        local kptr = GTA.SpawnVehicle("kuruma2", px, py, pz, 0.0, true, true)
        local kuruma = ToHandle(kptr)
        if kuruma == 0 then
            Notify2("Spawner", "Kuruma spawn failed!")
            return
        end

        MakeVehicleGodmode(kuruma)
        NV(NAT2.SET_ENTITY_COLLISION, kuruma, true, true)
        NV(NAT2.SET_ENTITY_VISIBLE, kuruma, true, false)
        NV(NAT2.SET_VEHICLE_ENGINE_ON, kuruma, true, true, false)
        UpgradeVehicle2(kuruma, "Kuruma2")
        Wait2(200)

        local playerPed = NI(NAT2.GET_PLAYER_PED, GTA.GetLocalPlayerId())
        NV(NAT2.SET_PED_INTO_VEHICLE, playerPed, kuruma, -1)

        local build = { base = kuruma, items = {} }

        local avengerOffsets = {
            { x = -6.0, y = 9.0, z = -6.9, rx = 0.0, ry = 0.0, rz = 0.0 },
            { x = -3.0, y = 9.0, z = -6.9, rx = 0.0, ry = 0.0, rz = 0.0 },
            { x =  0.0, y = 9.0, z = -6.9, rx = 0.0, ry = 0.0, rz = 0.0 },
            { x =  3.0, y = 9.0, z = -6.9, rx = 0.0, ry = 0.0, rz = 0.0 },
            { x =  6.0, y = 9.0, z = -6.9, rx = 0.0, ry = 0.0, rz = 0.0 },
        }

        for i, off in ipairs(avengerOffsets) do
            local aptr = GTA.SpawnVehicle("avenger", px, py, pz + 5.0, 0.0, true, true)
            local avenger = ToHandle(aptr)

            if avenger ~= 0 then
                MakeVehicleGodmode(avenger)
                NV(NAT2.SET_ENTITY_COLLISION, avenger, true, true)
                NV(NAT2.SET_ENTITY_VISIBLE, avenger, true, false)
                NV(NAT2.SET_VEHICLE_ENGINE_ON, avenger, true, true, false)
                NV(NAT2.SET_HELI_BLADES_FULL_SPEED, avenger)
                PaintVehicleBlack(avenger)
                Wait2(80)

                NV(NAT2.ATTACH_ENTITY_TO_ENTITY, avenger, kuruma, 0,
                    off.x, off.y, off.z,
                    off.rx, off.ry, off.rz,
                    false, false, true, false, 2, true, 0)

                local item = { handle = avenger, type = "vehicle", children = {} }

                AttachAvengerPropBongs(avenger, item, kuruma, playerPed)

                for p = 1, 2 do
                    local pp = GTA.CreatePed("s_m_y_blackops_01", 26, px, py, pz + 5.0, 0.0, true, true)
                    local ped = ToHandle(pp)
                    if ped ~= 0 then
                        local seat = (p == 1) and -1 or (p - 2)
                        NV(NAT2.SET_PED_INTO_VEHICLE, ped, avenger, seat)
                        NV(NAT2.SET_ENTITY_INVINCIBLE, ped, true)
                        NV(NAT2.SET_ENTITY_PROOFS, ped, true, true, true, true, true, true, true, true)
                        NV(NAT2.SET_ENTITY_VISIBLE, ped, true, false)
                        LockPedInVehicle2(ped, avenger)
                        ArmPed(ped)
                        table.insert(item.children, {handle = ped, type = "ped"})
                    end
                end

                table.insert(build.items, item)
            end
            Wait2(50)
        end

        table.insert(spawnedBuilds2, build)
        Notify2("Spawner", "Kuruma Swarm " .. #build.items .. " idk bro lol make cars go weeee")
    end

    local cats = {
        {id="fun", label="Fun", folder="Fun"},
        {id="idk", label="idk", folder="idk"},
        {id="crimson", label="Crimson", folder="Crimson"},
    }

    local files = {}
    local spawned = {}
    local mapFiles = {}
    local mapCats = {
        {id="maps", label="Maps", folder="Maps"},
    }

    local function parse(path)
        local f,err = io.open(path,"r")
        if not f then return nil,err end
        local d = {Vehicle={},VehicleMods={},VehicleToggles={},Objects={},AttachedObjects={}}
        local section,num = nil,nil
        for line in f:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and line:sub(1,1) ~= ";" and line:sub(1,1) ~= "#" then
                local sec = line:match("^%[([^%]]+)%]$")
                if sec then
                    section = sec
                    num = nil
                    local n = tonumber(sec)
                    if n then
                        d.Objects[n] = d.Objects[n] or {}
                        num = n
                    end
                    local an = sec:match("^Attached Object (%d+)$")
                    if an then
                        local x = tonumber(an)
                        d.AttachedObjects[x] = d.AttachedObjects[x] or {}
                        num = x
                    end
                    if sec == "Vehicle Mods" then section = "VehicleMods"
                    elseif sec == "Vehicle Toggles" then section = "VehicleToggles" end
                else
                    local k,v = line:match("^([^=]+)=(.*)$")
                    if k and v then
                        k = k:match("^%s*(.-)%s*$")
                        v = v:match("^%s*(.-)%s*$")
                        local n = tonumber(v)
                        if n ~= nil then v = n end
                        if section == "Vehicle" then
                            d.Vehicle[k] = v
                            local slot = tonumber(k)
                            if slot and ((slot >= 0 and slot <= 16) or (slot >= 23 and slot <= 24) or (slot >= 25 and slot <= 28) or slot == 30 or (slot >= 33 and slot <= 35) or (slot >= 37 and slot <= 39) or slot == 45 or slot == 48) then
                                if v ~= -1 then d.VehicleMods[tostring(slot)] = v end
                            end
                            if k:match("^TOGGLE_%d+") then
                                d.VehicleToggles[k:gsub("TOGGLE_","")] = v
                            end
                        elseif section == "VehicleMods" then d.VehicleMods[k] = v
                        elseif section == "VehicleToggles" then d.VehicleToggles[k] = v
                        elseif num then
                            if tostring(section):find("Attached Object") then
                                d.AttachedObjects[num][k] = v
                            else
                                d.Objects[num][k] = v
                            end
                        end
                    end
                end
            end
        end
        f:close()
        return d
    end

    local function parseJson(path)
        local f, err = io.open(path, "r")
        if not f then return nil, err end
        local str = f:read("*a")
        f:close()

        local pos = 1
        local function skip()
            while pos <= #str do
                local c = str:sub(pos, pos)
                if c == " " or c == "\t" or c == "\n" or c == "\r" then
                    pos = pos + 1
                elseif c == "/" and pos < #str then
                    local n = str:sub(pos+1, pos+1)
                    if n == "/" then
                        pos = pos + 2
                        while pos <= #str and str:sub(pos, pos) ~= "\n" do pos = pos + 1 end
                    elseif n == "*" then
                        pos = pos + 2
                        while pos <= #str do
                            if str:sub(pos, pos) == "*" and str:sub(pos+1, pos+1) == "/" then
                                pos = pos + 2
                                break
                            end
                            pos = pos + 1
                        end
                    else
                        break
                    end
                else
                    break
                end
            end
        end

        local function parseVal()
            skip()
            local c = str:sub(pos, pos)
            if c == "{" then
                pos = pos + 1
                local t = {}
                skip()
                if str:sub(pos, pos) == "}" then pos = pos + 1 return t end
                while true do
                    skip()
                    local key = parseVal()
                    skip()
                    if str:sub(pos, pos) ~= ":" then error("expected : at " .. pos) end
                    pos = pos + 1
                    local val = parseVal()
                    t[key] = val
                    skip()
                    local sep = str:sub(pos, pos)
                    pos = pos + 1
                    if sep == "}" then break end
                    if sep ~= "," then error("expected , or } at " .. pos) end
                end
                return t
            elseif c == "[" then
                pos = pos + 1
                local t = {}
                skip()
                if str:sub(pos, pos) == "]" then pos = pos + 1 return t end
                local idx = 1
                while true do
                    t[idx] = parseVal()
                    idx = idx + 1
                    skip()
                    local sep = str:sub(pos, pos)
                    pos = pos + 1
                    if sep == "]" then break end
                    if sep ~= "," then error("expected , or ] at " .. pos) end
                end
                return t
            elseif c == '"' then
                pos = pos + 1
                local s = ""
                while pos <= #str do
                    local ch = str:sub(pos, pos)
                    if ch == '"' then pos = pos + 1 break end
                    if ch == "\\" then
                        pos = pos + 1
                        local esc = str:sub(pos, pos)
                        if esc == "n" then s = s .. "\n"
                        elseif esc == "t" then s = s .. "\t"
                        elseif esc == "r" then s = s .. "\r"
                        elseif esc == "b" then s = s .. "\b"
                        elseif esc == "f" then s = s .. "\f"
                        elseif esc == "u" then
                            local hex = str:sub(pos+1, pos+4)
                            local cp = tonumber(hex, 16)
                            if cp then
                                if cp < 0x80 then
                                    s = s .. string.char(cp)
                                elseif cp < 0x800 then
                                    s = s .. string.char(0xC0 + math.floor(cp/0x40), 0x80 + cp%0x40)
                                else
                                    s = s .. string.char(0xE0 + math.floor(cp/0x1000), 0x80 + math.floor(cp/0x40)%0x40, 0x80 + cp%0x40)
                                end
                            end
                            pos = pos + 4
                        else
                            s = s .. esc
                        end
                        pos = pos + 1
                    else
                        s = s .. ch
                        pos = pos + 1
                    end
                end
                return s
            elseif c == "t" and str:sub(pos, pos+3) == "true" then
                pos = pos + 4
                return true
            elseif c == "f" and str:sub(pos, pos+4) == "false" then
                pos = pos + 5
                return false
            elseif c == "n" and str:sub(pos, pos+3) == "null" then
                pos = pos + 4
                return nil
            else
                local numStr = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
                if numStr and #numStr > 0 then
                    pos = pos + #numStr
                    return tonumber(numStr)
                end
                error("unexpected char '" .. c .. "' at " .. pos)
            end
        end

        local ok, result = pcall(function()
            local val = parseVal()
            skip()
            return val
        end)
        if ok then return result end
        return nil, tostring(result)
    end

    local function fixHash(h)
        h = tonumber(h) or 0
        if h < 0 then h = h + 4294967296 end
        return h
    end

    local function parseJsonVehicle(path)
        local data, err = parseJson(path)
        if not data then return nil, err end
        local result = {Vehicle = {}, VehicleMods = {}, VehicleToggles = {}, Objects = {}, AttachedObjects = {}}
        result.Vehicle.model = fixHash(data.hash)
        if data.model and result.Vehicle.model == 0 then
            result.Vehicle.model = Utils.Joaat(tostring(data.model))
        end
        local va = data.vehicle_attributes or {}
        if va.mods then
            for k, v in pairs(va.mods) do
                local slot = k:match("^_(%d+)$")
                if slot then result.VehicleMods[slot] = tonumber(v) end
            end
        end
        local paint = va.paint or {}
        if paint.primary then
            if paint.primary.is_custom and paint.primary.custom_color then
                result.Vehicle["custom primary colour"] = 1
                result.Vehicle.PrimaryR = paint.primary.custom_color.r
                result.Vehicle.PrimaryG = paint.primary.custom_color.g
                result.Vehicle.PrimaryB = paint.primary.custom_color.b
            else
                result.Vehicle.PrimaryPaint = paint.primary.color
                result.Vehicle.PrimaryPaintT = paint.primary.paint_type
            end
        end
        if paint.secondary then
            if paint.secondary.is_custom and paint.secondary.custom_color then
                result.Vehicle["custom secondary colour"] = 1
                result.Vehicle.SecondaryR = paint.secondary.custom_color.r
                result.Vehicle.SecondaryG = paint.secondary.custom_color.g
                result.Vehicle.SecondaryB = paint.secondary.custom_color.b
            else
                result.Vehicle.SecondaryPaint = paint.secondary.color
                result.Vehicle.SecondaryPaintT = paint.secondary.paint_type
            end
        end
        if paint.extra_colors then
            result.Vehicle.Pearlescent = paint.extra_colors.pearlescent
            result.Vehicle.WheelsColor = paint.extra_colors.wheel
        end
        if paint.dirt_level then result.Vehicle.DirtLevel = paint.dirt_level end
        if paint.fade then result.Vehicle.PaintFade = paint.fade * 100 end
        if paint.dashboard_color then result.Vehicle.DashColor = paint.dashboard_color end
        if paint.interior_color then result.Vehicle.DashLightColor = paint.interior_color end
        if paint.livery and paint.livery ~= -1 then result.Vehicle.Livery = paint.livery end
        local neon = va.neon or {}
        if neon.color then
            result.Vehicle.NeonR = neon.color.r
            result.Vehicle.NeonG = neon.color.g
            result.Vehicle.NeonB = neon.color.b
        end
        if neon.lights then
            local ne = 0
            if neon.lights.left then ne = ne + 1 end
            if neon.lights.right then ne = ne + 2 end
            if neon.lights.front then ne = ne + 4 end
            if neon.lights.back then ne = ne + 8 end
            result.Vehicle.NeonEnabled = ne
        end
        local wheels = va.wheels or {}
        if wheels.wheel_type then result.Vehicle.WheelsType = wheels.wheel_type end
        if wheels.tire_smoke_color then
            result.Vehicle.SmokeR = wheels.tire_smoke_color.r
            result.Vehicle.SmokeG = wheels.tire_smoke_color.g
            result.Vehicle.SmokeB = wheels.tire_smoke_color.b
        end
        local opts = va.options or {}
        if opts.license_plate_text then result.Vehicle.PlateText = opts.license_plate_text end
        if opts.license_plate_type then result.Vehicle.PlateIndex = opts.license_plate_type end
        if opts.window_tint and opts.window_tint ~= -1 then result.Vehicle.WindowTint = opts.window_tint end
        if opts.bulletproof_tires ~= nil then result.Vehicle.Bulletproof = opts.bulletproof_tires and 1 or 0 end
        local headlights = va.headlights or {}
        if headlights.headlights_type then result.VehicleToggles["22"] = headlights.headlights_type and 1 or 0 end
        if headlights.headlight_color and headlights.headlight_color ~= -1 then result.Vehicle.HeadlightColor = headlights.headlight_color end
        if va.extras then
            for i, v in ipairs(va.extras) do
                result.Vehicle["Extra_" .. i] = v
            end
        end
        if data.children then
            for i, child in ipairs(data.children) do
                if child.type == "OBJECT" or child.type == "PED" then
                    local obj = {}
                    obj.model = fixHash(child.hash)
                    if child.model and obj.model == 0 then
                        obj.model = Utils.Joaat(tostring(child.model))
                    end
                    if child.offset then
                        obj["x offset"] = child.offset.x
                        obj["y offset"] = child.offset.y
                        obj["z offset"] = child.offset.z
                    end
                    if child.rotation then
                        obj.pitch = child.rotation.x
                        obj.roll = child.rotation.y
                        obj.yaw = child.rotation.z
                    elseif child.world_rotation then
                        obj.pitch = child.world_rotation.x
                        obj.roll = child.world_rotation.y
                        obj.yaw = child.world_rotation.z
                    end
                    if child.options then
                        obj.collision = child.options.has_collision ~= false and 1 or 0
                        if child.options.bone_index then obj.bone = tostring(child.options.bone_index) end
                    end
                    if child.type == "PED" then obj.is_ped = true end
                    if obj.model ~= 0 then
                        result.AttachedObjects[i] = obj
                    end
                end
            end
        end
        return result
    end

    local function xml_trim(s)
        if not s then return "" end
        return s:match("^%s*(.-)%s*$") or ""
    end

    local function xml_safe_tonumber(v, default)
        if v == nil then return default end
        local n = tonumber(v)
        if n ~= nil then return n end
        return default
    end

    local function xml_to_boolean(v)
        if v == nil then return nil end
        local s = tostring(v):lower()
        if s == "true" or s == "1" then return true end
        if s == "false" or s == "0" then return false end
        return nil
    end

    local function get_xml_element_content(xml, tag)
        if not xml or not tag then return nil end
        local pattern = "<" .. tag .. ">([^<]*)</" .. tag .. ">"
        local content = xml:match(pattern)
        if content then return xml_trim(content) end
        return nil
    end

    local function get_xml_element(xml, tag)
        if not xml or not tag then return nil end
        local pattern = "<" .. tag .. "[^>]*>(.-)</" .. tag .. ">"
        local content = xml:match(pattern)
        if content then return content end
        return nil
    end

    local function parse_attributes(attrStr)
        local attrs = {}
        if not attrStr then return attrs end
        for key, value in attrStr:gmatch('(%w+)="([^"]*)"') do
            attrs[key] = value
        end
        return attrs
    end

    local function parse_self_closing_tag(xml, tagName)
        if not xml or not tagName then return nil end
        return xml:match("<" .. tagName .. "(.-)/>")
    end

    local function parse_vector_from_tag(xml, tagName)
        local snippet = parse_self_closing_tag(xml, tagName)
        if not snippet then return nil end
        local attrs = parse_attributes(snippet)
        return {
            x = xml_safe_tonumber(attrs.X or attrs.x, 0.0),
            y = xml_safe_tonumber(attrs.Y or attrs.y, 0.0),
            z = xml_safe_tonumber(attrs.Z or attrs.z, 0.0)
        }
    end

    local function parse_xml_vehicle_colors(vprops)
        local colors = {}
        local coloursSection = get_xml_element(vprops, "Colours")
        if not coloursSection then return colors end
        colors.Primary = xml_safe_tonumber(get_xml_element_content(coloursSection, "Primary"), nil)
        colors.Secondary = xml_safe_tonumber(get_xml_element_content(coloursSection, "Secondary"), nil)
        colors.Pearl = xml_safe_tonumber(get_xml_element_content(coloursSection, "Pearl"), nil)
        colors.Rim = xml_safe_tonumber(get_xml_element_content(coloursSection, "Rim"), nil)
        colors.tyreSmoke_R = xml_safe_tonumber(get_xml_element_content(coloursSection, "tyreSmoke_R"), nil)
        colors.tyreSmoke_G = xml_safe_tonumber(get_xml_element_content(coloursSection, "tyreSmoke_G"), nil)
        colors.tyreSmoke_B = xml_safe_tonumber(get_xml_element_content(coloursSection, "tyreSmoke_B"), nil)
        colors.LrDashboard = xml_safe_tonumber(get_xml_element_content(coloursSection, "LrDashboard"), nil)
        colors.LrInterior = xml_safe_tonumber(get_xml_element_content(coloursSection, "LrInterior"), nil)
        colors.IsPrimaryColourCustom = xml_to_boolean(get_xml_element_content(coloursSection, "IsPrimaryColourCustom"))
        colors.Cust1_R = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust1_R"), 0)
        colors.Cust1_G = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust1_G"), 0)
        colors.Cust1_B = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust1_B"), 0)
        colors.IsSecondaryColourCustom = xml_to_boolean(get_xml_element_content(coloursSection, "IsSecondaryColourCustom"))
        colors.Cust2_R = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust2_R"), 0)
        colors.Cust2_G = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust2_G"), 0)
        colors.Cust2_B = xml_safe_tonumber(get_xml_element_content(coloursSection, "Cust2_B"), 0)
        return colors
    end

    local function parse_xml_vehicle_mods(vprops)
        local mods = {}
        local modsSection = get_xml_element(vprops, "Mods")
        if not modsSection then return mods end
        for modId, modValue in modsSection:gmatch("<_([0-9]+)>([^<]+)</_[0-9]+>") do
            local id = xml_safe_tonumber(modId, nil)
            if id then
                local firstNum = modValue:match("^([^,]+)")
                if firstNum then
                    mods[id] = xml_safe_tonumber(firstNum, -1)
                end
            end
        end
        return mods
    end

    local function parse_xml_vehicle_neons(vprops)
        local neons = {}
        local neonsSection = get_xml_element(vprops, "Neons")
        if not neonsSection then return nil end
        neons.Left = xml_to_boolean(get_xml_element_content(neonsSection, "Left"))
        neons.Right = xml_to_boolean(get_xml_element_content(neonsSection, "Right"))
        neons.Front = xml_to_boolean(get_xml_element_content(neonsSection, "Front"))
        neons.Back = xml_to_boolean(get_xml_element_content(neonsSection, "Back"))
        neons.R = xml_safe_tonumber(get_xml_element_content(neonsSection, "R"), nil)
        neons.G = xml_safe_tonumber(get_xml_element_content(neonsSection, "G"), nil)
        neons.B = xml_safe_tonumber(get_xml_element_content(neonsSection, "B"), nil)
        return neons
    end

    local function parse_xml_vehicle_properties(vprops, target)
        local colors = parse_xml_vehicle_colors(vprops)
        if colors.Primary ~= nil then target.Vehicle.PrimaryPaint = colors.Primary end
        if colors.Secondary ~= nil then target.Vehicle.SecondaryPaint = colors.Secondary end
        if colors.Pearl ~= nil then target.Vehicle.Pearlescent = colors.Pearl end
        if colors.Rim ~= nil then target.Vehicle.WheelsColor = colors.Rim end
        if colors.tyreSmoke_R ~= nil then target.Vehicle.SmokeR = colors.tyreSmoke_R end
        if colors.tyreSmoke_G ~= nil then target.Vehicle.SmokeG = colors.tyreSmoke_G end
        if colors.tyreSmoke_B ~= nil then target.Vehicle.SmokeB = colors.tyreSmoke_B end
        if colors.LrDashboard ~= nil then target.Vehicle.DashColor = colors.LrDashboard end
        if colors.LrInterior ~= nil then target.Vehicle.DashLightColor = colors.LrInterior end
        if colors.IsPrimaryColourCustom then
            target.Vehicle["custom primary colour"] = 1
            target.Vehicle.PrimaryR = colors.Cust1_R
            target.Vehicle.PrimaryG = colors.Cust1_G
            target.Vehicle.PrimaryB = colors.Cust1_B
        end
        if colors.IsSecondaryColourCustom then
            target.Vehicle["custom secondary colour"] = 1
            target.Vehicle.SecondaryR = colors.Cust2_R
            target.Vehicle.SecondaryG = colors.Cust2_G
            target.Vehicle.SecondaryB = colors.Cust2_B
        end

        local mods = parse_xml_vehicle_mods(vprops)
        for k, v in pairs(mods) do
            target.VehicleMods[tostring(k)] = v
        end

        local toggles = {17, 18, 19, 20, 21, 22}
        for _, t in ipairs(toggles) do
            local tv = get_xml_element_content(vprops, "_" .. t)
            if tv ~= nil then
                target.VehicleToggles[tostring(t)] = xml_to_boolean(tv) and 1 or 0
            end
        end

        local plate = get_xml_element_content(vprops, "NumberPlateText") or get_xml_element_content(vprops, "PlateText")
        if plate then target.Vehicle.PlateText = plate end
        local plateType = get_xml_element_content(vprops, "NumberPlateIndex") or get_xml_element_content(vprops, "PlateType") or get_xml_element_content(vprops, "PlateIndex")
        if plateType then target.Vehicle.PlateIndex = xml_safe_tonumber(plateType, nil) end

        local wtype = get_xml_element_content(vprops, "WheelType") or get_xml_element_content(vprops, "WheelsType")
        if wtype then target.Vehicle.WheelsType = xml_safe_tonumber(wtype, nil) end

        local bp = get_xml_element_content(vprops, "BulletProofTyres") or get_xml_element_content(vprops, "BulletproofTyres")
        if bp ~= nil then target.Vehicle.Bulletproof = xml_to_boolean(bp) and 1 or 0 end

        local dirt = get_xml_element_content(vprops, "DirtLevel")
        if dirt then target.Vehicle.DirtLevel = xml_safe_tonumber(dirt, nil) end

        local fade = get_xml_element_content(vprops, "PaintFade")
        if fade then target.Vehicle.PaintFade = xml_safe_tonumber(fade, nil) * 100 end

        local neons = parse_xml_vehicle_neons(vprops)
        if neons then
            if neons.R ~= nil then target.Vehicle.NeonR = neons.R end
            if neons.G ~= nil then target.Vehicle.NeonG = neons.G end
            if neons.B ~= nil then target.Vehicle.NeonB = neons.B end
            local ne = 0
            if neons.Left then ne = ne + 1 end
            if neons.Right then ne = ne + 2 end
            if neons.Front then ne = ne + 4 end
            if neons.Back then ne = ne + 8 end
            target.Vehicle.NeonEnabled = ne
        end

        local tint = get_xml_element_content(vprops, "WindowTint")
        if tint and xml_safe_tonumber(tint, -1) ~= -1 then target.Vehicle.WindowTint = xml_safe_tonumber(tint, nil) end

        local livery = get_xml_element_content(vprops, "Livery")
        if livery and xml_safe_tonumber(livery, -1) ~= -1 then target.Vehicle.Livery = xml_safe_tonumber(livery, nil) end

        local roof = get_xml_element_content(vprops, "RoofState")
        if roof ~= nil then target.Vehicle.RoofState = xml_safe_tonumber(roof, nil) end

        local lock = get_xml_element_content(vprops, "LockStatus")
        if lock then target.Vehicle.LockStatus = xml_safe_tonumber(lock, nil) end
    end

    local function parse_xml_attachment(attInner, idx)
        local att = {}
        local ohash = get_xml_element_content(attInner, "ModelHash")
        if ohash then att.model = fixHash(xml_safe_tonumber(ohash, 0)) end
        if not att.model or att.model == 0 then
            local hname = get_xml_element_content(attInner, "HashName")
            if hname and hname ~= "" then
                att.model = Utils.Joaat(hname)
            end
        end

        local attType = get_xml_element_content(attInner, "Type")
        if attType == "2" then att.type = "vehicle"
        elseif attType == "1" then att.type = "ped"
        else att.type = "object" end

        local innerAtt = attInner:match('<Attachment%s+isAttached="true">(.-)</Attachment>')
        if not innerAtt then
            innerAtt = attInner:match('<Attachment>(.-)</Attachment>')
        end

        if innerAtt then
            att["x offset"] = xml_safe_tonumber(get_xml_element_content(innerAtt, "X"), 0)
            att["y offset"] = xml_safe_tonumber(get_xml_element_content(innerAtt, "Y"), 0)
            att["z offset"] = xml_safe_tonumber(get_xml_element_content(innerAtt, "Z"), 0)
            att.pitch = xml_safe_tonumber(get_xml_element_content(innerAtt, "Pitch"), 0)
            att.roll = xml_safe_tonumber(get_xml_element_content(innerAtt, "Roll"), 0)
            att.yaw = xml_safe_tonumber(get_xml_element_content(innerAtt, "Yaw"), 0)
            local innerBone = get_xml_element_content(innerAtt, "BoneIndex")
            if innerBone then att.bone = tostring(innerBone) end
            att.is_attached = true
        else
            local posRot = get_xml_element(attInner, "PositionRotation")
            if posRot then
                att["x offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "X"), 0)
                att["y offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "Y"), 0)
                att["z offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "Z"), 0)
                att.pitch = xml_safe_tonumber(get_xml_element_content(posRot, "Pitch"), 0)
                att.roll = xml_safe_tonumber(get_xml_element_content(posRot, "Roll"), 0)
                att.yaw = xml_safe_tonumber(get_xml_element_content(posRot, "Yaw"), 0)
            else
                att["x offset"] = xml_safe_tonumber(get_xml_element_content(attInner, "X"), 0)
                att["y offset"] = xml_safe_tonumber(get_xml_element_content(attInner, "Y"), 0)
                att["z offset"] = xml_safe_tonumber(get_xml_element_content(attInner, "Z"), 0)
                att.pitch = xml_safe_tonumber(get_xml_element_content(attInner, "Pitch") or get_xml_element_content(attInner, "RotX"), 0)
                att.roll = xml_safe_tonumber(get_xml_element_content(attInner, "Roll") or get_xml_element_content(attInner, "RotY"), 0)
                att.yaw = xml_safe_tonumber(get_xml_element_content(attInner, "Yaw") or get_xml_element_content(attInner, "RotZ"), 0)
            end
            att.is_attached = false
        end

        local attVprops = get_xml_element(attInner, "VehicleProperties")
        if attVprops and att.type == "vehicle" then
            local vdata = {Vehicle = {}, VehicleMods = {}, VehicleToggles = {}, Objects = {}, AttachedObjects = {}}
            local attModel = get_xml_element_content(attInner, "ModelHash")
            if attModel then vdata.Vehicle.model = fixHash(xml_safe_tonumber(attModel, 0)) end
            parse_xml_vehicle_properties(attVprops, vdata)
            att.vehicle_data = vdata
        end

        local collision = get_xml_element_content(attInner, "IsCollisionProof")
        if collision ~= nil then
            att.collision = xml_to_boolean(collision) and 0 or 1
        else
            att.collision = 1
        end

        if att.model and att.model ~= 0 then
            return att
        end
        return nil
    end

    local function parseXml(path)
        local f, err = io.open(path, "r")
        if not f then return nil, err end
        local str = f:read("*a")
        f:close()

        local data = {Vehicle = {}, VehicleMods = {}, VehicleToggles = {}, Objects = {}, AttachedObjects = {}}

        local vehBlock = str:match("<Vehicle[^>]*>(.*)</Vehicle>") or str
        local modelHash = get_xml_element_content(vehBlock, "ModelHash")
        if modelHash then data.Vehicle.model = fixHash(xml_safe_tonumber(modelHash, 0)) end
        if not data.Vehicle.model or data.Vehicle.model == 0 then
            local baseHashName = get_xml_element_content(vehBlock, "HashName")
            if baseHashName and baseHashName ~= "" then
                data.Vehicle.model = Utils.Joaat(baseHashName)
            end
        end

        local vprops = get_xml_element(vehBlock, "VehicleProperties")
        if vprops then
            parse_xml_vehicle_properties(vprops, data)
        end

        local spooner = str:match("<SpoonerAttachments[^>]*>(.-)</SpoonerAttachments>")
        if spooner then
            local idx = 1
            local searchPos = 1
            while true do
                local openStart = spooner:find("<Attachment[^>]*>", searchPos)
                if not openStart then break end
                local closePos = nil
                local depth = 1
                local pos = openStart + 1
                while depth > 0 and pos <= #spooner do
                    local nextOpen = spooner:find("<Attachment[^>]*>", pos)
                    local nextClose = spooner:find("</Attachment>", pos)
                    if not nextClose then break end
                    if nextOpen and nextOpen < nextClose then
                        depth = depth + 1
                        pos = nextOpen + 1
                    else
                        depth = depth - 1
                        if depth == 0 then
                            closePos = nextClose + #"</Attachment>" - 1
                            break
                        end
                        pos = nextClose + 1
                    end
                end
                if closePos then
                    local attInner = spooner:sub(openStart, closePos)
                    local att = parse_xml_attachment(attInner, idx)
                    if att then
                        data.AttachedObjects[idx] = att
                        idx = idx + 1
                    end
                    searchPos = closePos + 1
                else
                    searchPos = openStart + 1
                end
            end
        end

        local mapIdx = 1
        local mapSearchPos = 1
        while true do
            local openStart = str:find("<Placement[^>]*>", mapSearchPos)
            if not openStart then break end
            local closePos = str:find("</Placement>", openStart)
            if not closePos then break end
            local placementInner = str:sub(openStart, closePos + #"</Placement>" - 1)

            local att = {}
            local ohash = get_xml_element_content(placementInner, "ModelHash")
            if ohash then att.model = fixHash(xml_safe_tonumber(ohash, 0)) end

            local pType = get_xml_element_content(placementInner, "Type")
            if pType == "2" then att.type = "vehicle"
            elseif pType == "3" then att.type = "ped"
            else att.type = "object" end

            local posRot = get_xml_element(placementInner, "PositionRotation")
            if posRot then
                att["x offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "X"), 0)
                att["y offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "Y"), 0)
                att["z offset"] = xml_safe_tonumber(get_xml_element_content(posRot, "Z"), 0)
                att.pitch = xml_safe_tonumber(get_xml_element_content(posRot, "Pitch"), 0)
                att.roll = xml_safe_tonumber(get_xml_element_content(posRot, "Roll"), 0)
                att.yaw = xml_safe_tonumber(get_xml_element_content(posRot, "Yaw"), 0)
            end

            local attachment = get_xml_element(placementInner, "Attachment")
            if attachment then
                att.is_attached = attachment:find('isAttached="true"') ~= nil
                if att.is_attached then
                    att["x offset"] = xml_safe_tonumber(get_xml_element_content(attachment, "X"), att["x offset"] or 0)
                    att["y offset"] = xml_safe_tonumber(get_xml_element_content(attachment, "Y"), att["y offset"] or 0)
                    att["z offset"] = xml_safe_tonumber(get_xml_element_content(attachment, "Z"), att["z offset"] or 0)
                    att.pitch = xml_safe_tonumber(get_xml_element_content(attachment, "Pitch"), att.pitch or 0)
                    att.roll = xml_safe_tonumber(get_xml_element_content(attachment, "Roll"), att.roll or 0)
                    att.yaw = xml_safe_tonumber(get_xml_element_content(attachment, "Yaw"), att.yaw or 0)
                    local bone = get_xml_element_content(attachment, "BoneIndex")
                    if bone then att.bone = tostring(bone) end
                end
            end

            local vehProps = get_xml_element(placementInner, "VehicleProperties")
            if vehProps and att.type == "vehicle" then
                local vdata = {Vehicle = {}, VehicleMods = {}, VehicleToggles = {}, Objects = {}, AttachedObjects = {}}
                if ohash then vdata.Vehicle.model = att.model end
                parse_xml_vehicle_properties(vehProps, vdata)
                att.vehicle_data = vdata
            end

            if get_xml_element(placementInner, "PedProperties") then
                att.is_ped = true
            end

            if att.model and att.model ~= 0 then
                data.AttachedObjects[mapIdx] = att
                mapIdx = mapIdx + 1
            end

            mapSearchPos = closePos + #"</Placement>"
        end

        return data
    end

    local function rootDir()
        if FileMgr and FileMgr.GetMenuRootPath then
            local r = FileMgr.GetMenuRootPath()
            if type(r) == "string" then
                r = r:gsub("/","\\")
                if r:sub(-1) ~= "\\" then r = r .. "\\" end
                return r
            end
        end
    end

    local function fexists(path)
        local f = io.open(path,"r")
        if f then f:close(); return true end
        return false
    end

    local function catDir(c)
        local r = rootDir()
        if not r then return end
        return r .. "Crimson\\" .. c.folder .. "\\"
    end

    local function mapDir(c)
        local r = rootDir()
        if not r then return end
        return r .. "Crimson\\" .. c.folder .. "\\"
    end

    local function mapManifest(c)
        local d = mapDir(c)
        if d then return d .. "maps.txt" end
    end

    local function mapBuildPath(c, name)
        local d = mapDir(c)
        if not d then return end
        name = name:match("^%s*(.-)%s*$")
        local low = name:lower()
        if low:match("%.xml$") then
            return d .. "xml\\" .. name
        else
            if not low:match("%.json$") then
                name = name .. ".json"
            end
            return d .. "json\\" .. name
        end
    end

    local function readMapManifest(c)
        local p = mapManifest(c)
        if not p then return {} end
        local f = io.open(p, "r")
        if not f then return {} end
        local t = {}
        for line in f:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and line:sub(1,1) ~= "#" and line:sub(1,1) ~= ";" then
                table.insert(t, line)
            end
        end
        f:close()
        return t
    end

    local function writeMapManifest(c, names)
        local p = mapManifest(c)
        if not p then return end
        local f, err = io.open(p, "w")
        if not f then return end
        f:write("# map list\n")
        for _, n in ipairs(names) do f:write(n .. "\n") end
        f:close()
    end

    local function addMapManifest(c, name)
        name = name:match("^%s*(.-)%s*$"):gsub("%.json$", "")
        if name == "" then return end
        local cur = readMapManifest(c)
        for _, v in ipairs(cur) do
            if v:lower() == name:lower() then return end
        end
        table.insert(cur, name)
        writeMapManifest(c, cur)
    end

    local function manifest(c)
        local d = catDir(c)
        if d then return d .. "builds.txt" end
    end

    local function buildPath(c,name)
        local d = catDir(c)
        if not d then return end
        name = name:match("^%s*(.-)%s*$")
        if name:lower():match("%.ini$") or name:lower():match("%.json$") or name:lower():match("%.xml$") then
            return d .. name
        end
        for _, ext in ipairs({".ini", ".json", ".xml"}) do
            local p = d .. name .. ext
            if fexists(p) then return p end
        end
        return d .. name .. ".ini"
    end

    local function readManifest(c)
        local p = manifest(c)
        if not p then return {} end
        local f = io.open(p,"r")
        if not f then return {} end
        local t = {}
        for line in f:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and line:sub(1,1) ~= "#" and line:sub(1,1) ~= ";" then
                table.insert(t, (line:gsub("%.ini$","")))
            end
        end
        f:close()
        return t
    end

    local function writeManifest(c,names)
        local p = manifest(c)
        if not p then return end
        local f,err = io.open(p,"w")
        if not f then
            print("manifest err: "..tostring(err))
            return
        end
        f:write("# list\n")
        for _,n in ipairs(names) do f:write(n.."\n") end
        f:close()
    end

    local function addManifest(c,name)
        name = name:match("^%s*(.-)%s*$")
        name = name:gsub("%.ini$",""):gsub("%.json$",""):gsub("%.xml$","")
        if name == "" then return end
        local cur = readManifest(c)
        for _,v in ipairs(cur) do
            if v:lower() == name:lower() then return end
        end
        table.insert(cur,name)
        writeManifest(c,cur)
    end

    local function scan(c)
        files[c.id] = {}
        local r = rootDir()
        if not r then return 0 end
        local dir = r .. "Crimson\\" .. c.folder .. "\\"
        if FileMgr and FileMgr.CreateDir then
            pcall(function() FileMgr.CreateDir(dir) end)
        end
        local names = readManifest(c)
        local found = {}
        for _,n in ipairs(names) do
            local p = buildPath(c,n)
            if p and fexists(p) then
                table.insert(found, {name=n, path=p})
            else
                print("missing: "..tostring(p))
            end
        end
        files[c.id] = found
        local list = {}
        for i=1,#found do list[i] = found[i].name end
        if #list == 0 then
            list[1] = "No builds"
            files[c.id][1] = {name="", path=""}
        end
        local feat = FeatureMgr.GetFeature(Utils.Joaat("combo_"..c.id))
        if feat then
            pcall(function()
                feat:SetList(list)
                feat:SetListIndex(1)
            end)
        end
        return #found
    end

    local function scanMaps(c)
        mapFiles[c.id] = {}
        local r = rootDir()
        if not r then return 0 end
        local dir = r .. "Crimson\\" .. c.folder .. "\\"
        if FileMgr and FileMgr.CreateDir then
            pcall(function() FileMgr.CreateDir(dir) end)
            pcall(function() FileMgr.CreateDir(dir .. "json") end)
            pcall(function() FileMgr.CreateDir(dir .. "xml") end)
        end

        local names = readMapManifest(c)
        local found = {}
        local seen = {}

        for _, n in ipairs(names) do
            local p = mapBuildPath(c, n)
            if p and fexists(p) then
                local display = n:gsub("%.[^%.]+$", "")
                seen[display:lower()] = true
                table.insert(found, {name = display, path = p})
            else
                print("missing map: " .. tostring(p))
            end
        end

        local ok, handle = pcall(function()
            return io.popen('dir /b "' .. dir .. 'json\\" 2>nul')
        end)
        if ok and handle then
            for line in handle:lines() do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and line ~= "." and line ~= ".." then
                    local ext = line:lower():match("%.([^%.]+)$")
                    if ext == "json" then
                        local display = line:gsub("%.[^%.]+$", "")
                        local key = display:lower()
                        if not seen[key] then
                            seen[key] = true
                            table.insert(found, {name = display, path = dir .. "json\\" .. line})
                        end
                    end
                end
            end
            handle:close()
        end

        local ok2, handle2 = pcall(function()
            return io.popen('dir /b "' .. dir .. 'xml\\" 2>nul')
        end)
        if ok2 and handle2 then
            for line in handle2:lines() do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and line ~= "." and line ~= ".." then
                    local ext = line:lower():match("%.([^%.]+)$")
                    if ext == "xml" then
                        local display = line:gsub("%.[^%.]+$", "")
                        local key = display:lower() .. "_xml"
                        if not seen[key] then
                            seen[key] = true
                            table.insert(found, {name = display .. " (xml)", path = dir .. "xml\\" .. line})
                        end
                    end
                end
            end
            handle2:close()
        end

        table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)

        mapFiles[c.id] = found
        local list = {}
        for i = 1, #found do list[i] = found[i].name end
        if #list == 0 then
            list[1] = "No maps"
            mapFiles[c.id][1] = {name = "", path = ""}
        end
        local feat = FeatureMgr.GetFeature(Utils.Joaat("map_combo_" .. c.id))
        if feat then
            pcall(function()
                feat:SetList(list)
                feat:SetListIndex(1)
            end)
        end
        return #found
    end

    local function applyVeh(veh, vd, vm, vt)
        if veh == 0 then return end

        NV(NAT2.SET_VEHICLE_MOD_KIT, veh, 0)

        local mods = {}
        if vm then
            for s, v in pairs(vm) do
                mods[s] = v
            end
        end
        for i = 0, 48 do
            local val = vd[tostring(i)]
            if val ~= nil and val ~= -1 then
                mods[tostring(i)] = val
            end
        end

        for s, v in pairs(mods) do
            local sl = tonumber(s)
            local vl = tonumber(v)
            if sl and vl and vl ~= -1 then
                local maxMods = GET_NUM_VEHICLE_MODS(veh, sl)
                if maxMods and maxMods > 0 then
                    if vl < maxMods then
                        NV(NAT2.SET_VEHICLE_MOD, veh, sl, vl, false)
                    else
                        NV(NAT2.SET_VEHICLE_MOD, veh, sl, maxMods - 1, false)
                    end
                end
            end
        end

        local toggles = {}
        if vt then
            for s, v in pairs(vt) do
                toggles[s] = v
            end
        end
        for t = 17, 22 do
            local k = "TOGGLE_"..t
            if vd[k] ~= nil then
                toggles[tostring(t)] = vd[k]
            end
        end
        for s, v in pairs(toggles) do
            local sl = tonumber(s)
            local vl = tonumber(v)
            if sl and vl ~= nil then
                NV(NAT2.SET_VEHICLE_MOD, veh, sl, vl == 1 and 0 or -1, false)
            end
        end

        local pt = tonumber(vd["PrimaryPaintT"])
        local st = tonumber(vd["SecondaryPaintT"])
        if pt then NV(NAT2.SET_VEHICLE_MOD_COLOR_1, veh, pt, tonumber(vd["PrimaryPaint"]) or 0, tonumber(vd["Pearlescent"]) or 0) end
        if st then NV(NAT2.SET_VEHICLE_MOD_COLOR_2, veh, st, tonumber(vd["SecondaryPaint"]) or 0) end

        local fadeVal = tonumber(vd["PaintFade"])
        if fadeVal then pcall(function() NV(0x3AFDC536C3D01674, veh, fadeVal / 100) end) end

        local cp = tonumber(vd["custom primary colour"]) or 0
        if cp == 1 then
            local r = tonumber(vd["primary red"] or vd.PrimaryR) or 255
            local g = tonumber(vd["primary green"] or vd.PrimaryG) or 255
            local b = tonumber(vd["primary blue"] or vd.PrimaryB) or 255
            NV(NAT2.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR, veh, r, g, b)
        elseif vd.PrimaryR ~= nil then
            NV(NAT2.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR, veh, tonumber(vd.PrimaryR), tonumber(vd.PrimaryG), tonumber(vd.PrimaryB))
        end

        local cs = tonumber(vd["custom secondary colour"]) or 0
        if cs == 1 then
            local r = tonumber(vd["secondary red"] or vd.SecondaryR) or 255
            local g = tonumber(vd["secondary green"] or vd.SecondaryG) or 255
            local b = tonumber(vd["secondary blue"] or vd.SecondaryB) or 255
            NV(NAT2.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR, veh, r, g, b)
        elseif vd.SecondaryR ~= nil then
            NV(NAT2.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR, veh, tonumber(vd.SecondaryR), tonumber(vd.SecondaryG), tonumber(vd.SecondaryB))
        end

        local pearl = tonumber(vd["pearlescent colour"] or vd.Pearlescent) or 0
        local wheel = tonumber(vd["wheel colour"] or vd.WheelsColor) or 0
        n.xcol(veh, pearl, wheel)

        local wt = tonumber(vd["wheel type"] or vd.WheelsType) or -1
        if wt ~= -1 then pcall(function() n.wheel(veh, wt) end) end

        local ptex = vd["plate text"] or vd.PlateText
        if ptex then n.plate(veh, tostring(ptex)) end
        local pix = tonumber(vd["plate index"] or vd.PlateIndex)
        if pix then pcall(function() n.plati(veh, pix) end) end

        local tintVal = tonumber(vd["window tint"] or vd.WindowTint)
        if tintVal then pcall(function() n.tint(veh, tintVal) end) end

        local bp = tonumber(vd["bulletproof tyres"] or vd.Bulletproof)
        if bp ~= nil then n.burst(veh, bp == 0) end

        local ct = tonumber(vd["custom tyres"] or vd.CustomTyres)
        if ct ~= nil then NV(0x6AF0636DDEDCB6DD, veh, 20, ct == 1 and 0 or -1, false) end

        local dirtVal = tonumber(vd["dirt level"] or vd.DirtLevel)
        if dirtVal then n.dirt(veh, dirtVal) end

        local nr = tonumber(vd["neon red"] or vd.NeonR)
        local ng = tonumber(vd["neon green"] or vd.NeonG)
        local nb = tonumber(vd["neon blue"] or vd.NeonB)
        if nr and ng and nb then n.neonc(veh, nr, ng, nb) end

        local ne = tonumber(vd.NeonEnabled)
        if ne ~= nil then
            local on = ne ~= 0
            for i = 0, 3 do pcall(function() n.neon(veh, i, on) end) end
        else
            for i = 0, 3 do
                local val = vd["neon "..i]
                if val ~= nil then pcall(function() n.neon(veh, i, tonumber(val) == 1) end) end
            end
        end

        local sr = tonumber(vd["tyre smoke red"] or vd.SmokeR)
        local sg = tonumber(vd["tyre smoke green"] or vd.SmokeG)
        local sb = tonumber(vd["tyre smoke blue"] or vd.SmokeB)
        if sr and sg and sb then n.smoke(veh, sr, sg, sb) end

        for e = 1, 9 do
            local k = "Extra_"..e
            if vd[k] ~= nil then n.extra(veh, e, not (tonumber(vd[k]) == 1)) end
        end

        local liveryVal = tonumber(vd["Livery"] or vd.livery or vd.LIVERY)
        if liveryVal and liveryVal >= 0 then
            n.livery(veh, liveryVal)
        end
    end

    local function doSpawn(path)
        if not path or path == "" then toast("Spawner","no path"); return false end
        if not fexists(path) then toast("Spawner","not found"); return false end
        local data,err
        local low = path:lower()
        if low:match("%.json$") then
            data, err = parseJsonVehicle(path)
        elseif low:match("%.xml$") then
            data, err = parseXml(path)
        else
            data, err = parse(path)
        end
        if not data then toast("Spawner","parse err: "..tostring(err)); return false end

        local attCount = 0
        if data.AttachedObjects then
            for _ in pairs(data.AttachedObjects) do attCount = attCount + 1 end
        end
        toast("Spawner", "Parsed " .. attCount .. " attachments from file")

        local p = n.ped(GTA.GetLocalPlayerId())
        local x,y,z = n.pos(p,true)

        local vd = data.Vehicle or {}
        local vhash = tonumber(vd.model or vd.Model) or 0
        local veh = 0

        if vhash ~= 0 then
            local ptr = GTA.SpawnVehicle(vhash,x,y+5.0,z+0.5,0.0,true,true)
            veh = ToHandle(ptr)

            if veh ~= 0 then
                if script and script.yield then script.yield(100) end
                n.put(p,veh,-1)
                n.eng(veh,true,true,false)
                applyVeh(veh,vd,data.VehicleMods,data.VehicleToggles)
                table.insert(spawned,{h=veh,typ="vehicle"})
            else
                toast("Spawner","spawn failed")
                return false
            end
        end

        if script and script.yield then script.yield(200) end

        local objs = data.AttachedObjects
        if not objs or next(objs) == nil then objs = data.Objects end
        local keys = {}
        for k in pairs(objs) do table.insert(keys,k) end
        table.sort(keys)

        for _,k in ipairs(keys) do
            local ok_spawn, spawn_err = pcall(function()
            local o = objs[k]
            local ohash = tonumber(o.model or o.Model) or 0
            if ohash ~= 0 then
                local ox = tonumber(o["x offset"] or o.x_offset or o.X or o.x or o.PosX or o.posx or 0) or 0
                local oy = tonumber(o["y offset"] or o.y_offset or o.Y or o.y or o.PosY or o.posy or 0) or 0
                local oz = tonumber(o["z offset"] or o.z_offset or o.Z or o.z or o.PosZ or o.posz or 0) or 0
                local rx = tonumber(o.pitch or o.RotX or o.rotx or o.ROTX or o.rot_x or o.rx or 0) or 0
                local ry = tonumber(o.roll  or o.RotY or o.roty or o.ROTY or o.rot_y or o.ry or 0) or 0
                local rz = tonumber(o.yaw   or o.RotZ or o.rotz or o.ROTZ or o.rot_z or o.rz or 0) or 0
                local col = tonumber(o.collision or o.Collision) or 1

                local bname = o["bone"] or o.Bone
                local bidx = 0
                if bname and veh ~= 0 then
                    local ok,idx = pcall(function() return n.bone(veh,bname) end)
                    if ok and idx and idx > 0 then bidx = idx end
                end

                local attType = o.type or "object"
                if attType == "vehicle" or o.is_vehicle then
                    local vptr = GTA.SpawnVehicle(ohash, x, y+5.0, z+2.0, 0.0, true, true)
                    local vobj = ToHandle(vptr)
                    if vobj == 0 then
                        toast("Spawner", "Failed to spawn vehicle hash: " .. tostring(ohash))
                    end
                    if vobj ~= 0 then
                        if script and script.yield then script.yield(100) end
                        NV(NAT2.SET_VEHICLE_ENGINE_ON, vobj, true, true, false)
                        if o.vehicle_data then
                            applyVeh(vobj, o.vehicle_data.Vehicle, o.vehicle_data.VehicleMods, o.vehicle_data.VehicleToggles)
                        end
                        if veh ~= 0 then
                            n.att(vobj, veh, bidx, ox, oy, oz, rx, ry, rz, true, false, true, false, 2, true)
                        end
                        table.insert(spawned, {h=vobj, typ="vehicle"})
                    end
                elseif attType == "ped" or o.is_ped then
                    local pptr = GTA.CreatePed(ohash, 26, x, y+5.0, z+2.0, 0.0, true, true)
                    local ped = ToHandle(pptr)
                    if ped == 0 then
                        toast("Spawner", "Failed to spawn ped hash: " .. tostring(ohash))
                    end
                    if ped ~= 0 then
                        if script and script.yield then script.yield(50) end
                        n.col(ped, col ~= 0, true)
                        n.vis(ped, true, 0)
                        if veh ~= 0 then
                            n.att(ped, veh, bidx, ox, oy, oz, rx, ry, rz, true, false, true, false, 2, true)
                        end
                        table.insert(spawned, {h=ped, typ="ped"})
                    end
                else
                    local ptr = GTA.CreateObject(ohash, x, y+5.0, z+2.0, true, true)
                    local obj = ToHandle(ptr)
                    if obj == 0 then
                        toast("Spawner", "Failed to spawn object hash: " .. tostring(ohash) .. " type: " .. tostring(attType))
                    end
                    if obj ~= 0 then
                        if script and script.yield then script.yield(50) end
                        n.col(obj, col ~= 0, true)
                        n.vis(obj, true, 0)
                        if veh ~= 0 then
                            n.att(obj, veh, bidx, ox, oy, oz, rx, ry, rz, true, false, true, false, 2, true)
                        end
                        table.insert(spawned, {h=obj, typ="object"})
                    end
                end

                if script and script.yield then script.yield(30) end
            end
            end)
            if not ok_spawn and spawn_err then
                toast("Spawner", "Attachment " .. tostring(k) .. " failed: " .. tostring(spawn_err))
            end
        end

        toast("Spawner","spawned "..#spawned.." total entities")
        return true
    end

        local function parseMapFile(path)
        if not path or path == "" then return nil, "no path" end
        local low = path:lower()
        if low:match("%.xml$") then
            local xmlData, xmlErr = parseXml(path)
            if not xmlData then return nil, xmlErr end
            local result = { children = {}, position = { x = 0, y = 0, z = 0 } }
            local objs = xmlData.AttachedObjects or xmlData.Objects or {}
            local first = true
            for _, o in pairs(objs) do
                if o.model and o.model ~= 0 then
                    local px = tonumber(o["x offset"] or o.x_offset or o.X or o.x or 0) or 0
                    local py = tonumber(o["y offset"] or o.y_offset or o.Y or o.y or 0) or 0
                    local pz = tonumber(o["z offset"] or o.z_offset or o.Z or o.z or 0) or 0
                    if first then
                        result.position.x = px
                        result.position.y = py
                        result.position.z = pz
                        first = false
                    end
                    local child = {
                        hash = o.model,
                        position = { x = px, y = py, z = pz },
                        world_rotation = {
                            x = tonumber(o.pitch or o.RotX or o.rotx or 0) or 0,
                            y = tonumber(o.roll  or o.RotY or o.roty or 0) or 0,
                            z = tonumber(o.yaw   or o.RotZ or o.rotz or 0) or 0,
                        },
                        options = {
                            has_collision = (tonumber(o.collision or o.Collision) or 1) ~= 0,
                            is_visible = true,
                            is_attached = o.is_attached == true,
                            alpha = 255,
                            is_frozen = false,
                            is_invincible = false,
                            is_dynamic = true,
                        }
                    }
                    table.insert(result.children, child)
                end
            end
            return result
        else
            return parseJson(path)
        end
    end

local function doSpawnMapExact(path)
        if not path or path == "" then toast("Map Spawner", "no path"); return false end
        if not fexists(path) then toast("Map Spawner", "not found"); return false end
        local data, err = parseMapFile(path)
        if not data then toast("Map Spawner", "parse err: " .. tostring(err)); return false end

        local function SetEntityAlphaSafe(ent, a)
        end
        local function FreezeEntitySafe(ent, t)
        end

        local function spawnObjectRecursive(objData, parentHandle)
            if not objData then return 0 end
            local ohash = fixHash(objData.hash)
            if ohash == 0 and objData.model then
                ohash = Utils.Joaat(tostring(objData.model))
            end
            if ohash == 0 then return 0 end

            local opts = objData.options or {}
            local isAttached = (parentHandle and parentHandle ~= 0) and (opts.is_attached == true)

            local ptr
            local obj = 0

            if isAttached then
                local offX = tonumber(objData.offset and objData.offset.x) or 0
                local offY = tonumber(objData.offset and objData.offset.y) or 0
                local offZ = tonumber(objData.offset and objData.offset.z) or 0
                local rotX = tonumber(objData.rotation and objData.rotation.x) or 0
                local rotY = tonumber(objData.rotation and objData.rotation.y) or 0
                local rotZ = tonumber(objData.rotation and objData.rotation.z) or 0

                ptr = GTA.CreateObject(ohash, 0.0, 0.0, 0.0, true, true)
                obj = ToHandle(ptr)

                if obj ~= 0 then
                    if script and script.yield then script.yield(50) end
                    n.att(obj, parentHandle, 0, offX, offY, offZ, rotX, rotY, rotZ, true, false, true, false, 2, true)
                end
            else
                local posX = tonumber(objData.position and objData.position.x) or 0
                local posY = tonumber(objData.position and objData.position.y) or 0
                local posZ = tonumber(objData.position and objData.position.z) or 0
                local wrX = tonumber(objData.world_rotation and objData.world_rotation.x) or tonumber(objData.rotation and objData.rotation.x) or 0
                local wrY = tonumber(objData.world_rotation and objData.world_rotation.y) or tonumber(objData.rotation and objData.rotation.y) or 0
                local wrZ = tonumber(objData.world_rotation and objData.world_rotation.z) or tonumber(objData.rotation and objData.rotation.z) or 0

                ptr = GTA.CreateObject(ohash, posX, posY, posZ, true, true)
                obj = ToHandle(ptr)

                if obj ~= 0 then
                    if script and script.yield then script.yield(50) end
                    NV(0x8524A8B0171D5E07, obj, wrX + 0.0, wrY + 0.0, wrZ + 0.0, 2, true)
                end
            end

            if obj ~= 0 then
                if opts.has_collision ~= nil then n.col(obj, opts.has_collision, true) end
                if opts.is_visible ~= nil then n.vis(obj, opts.is_visible, 0) end

                local alpha = tonumber(opts.alpha)
                if alpha and alpha >= 0 and alpha <= 255 then
                    SetEntityAlphaSafe(obj, alpha)
                end

                if opts.is_frozen == true or opts.is_dynamic == false then
                    FreezeEntitySafe(obj, true)
                end

                if opts.is_invincible == true then
                    pcall(function() Natives.InvokeVoid(0x3882114BDE571AD4, obj, true) end)
                end

                table.insert(spawned, {h = obj, typ = "object"})

                if objData.children then
                    for _, child in ipairs(objData.children) do
                        spawnObjectRecursive(child, obj)
                    end
                end
            end

            if script and script.yield then script.yield(30) end
            return obj
        end

        if data.children then
            for _, child in ipairs(data.children) do
                spawnObjectRecursive(child, 0)
            end
        end

        toast("Map Spawner", "Spawned EXACT at JSON coords | total: " .. #spawned)
        return true
    end

    local function doSpawnMap(path)
        if not path or path == "" then toast("Map Spawner", "no path"); return false end
        if not fexists(path) then toast("Map Spawner", "not found"); return false end
        local data, err = parseMapFile(path)
        if not data then toast("Map Spawner", "parse err: " .. tostring(err)); return false end

        local p = n.ped(GTA.GetLocalPlayerId())
        local px, py, pz = n.pos(p, true)

        local baseX = tonumber(data.position and data.position.x) or px
        local baseY = tonumber(data.position and data.position.y) or py
        local baseZ = tonumber(data.position and data.position.z) or pz
        local shiftX = px - baseX
        local shiftY = py - baseY
        local shiftZ = pz - baseZ

        local function fixHash(h)
            h = tonumber(h) or 0
            if h < 0 then h = h + 4294967296 end
            return h
        end

        local function spawnObjectRecursive(objData, parentHandle)
            if not objData then return 0 end
            local ohash = fixHash(objData.hash)
            if ohash == 0 and objData.model then
                ohash = Utils.Joaat(tostring(objData.model))
            end
            if ohash == 0 then return 0 end

            local opts = objData.options or {}
            local isAttached = (parentHandle and parentHandle ~= 0) and (opts.is_attached == true)

            local ptr
            local obj = 0

            if isAttached then
                local offX = tonumber(objData.offset and objData.offset.x) or 0
                local offY = tonumber(objData.offset and objData.offset.y) or 0
                local offZ = tonumber(objData.offset and objData.offset.z) or 0
                local rotX = tonumber(objData.rotation and objData.rotation.x) or 0
                local rotY = tonumber(objData.rotation and objData.rotation.y) or 0
                local rotZ = tonumber(objData.rotation and objData.rotation.z) or 0

                ptr = GTA.CreateObject(ohash, px, py, pz + 5.0, true, true)
                obj = ToHandle(ptr)

                if obj ~= 0 then
                    if script and script.yield then script.yield(50) end
                    n.att(obj, parentHandle, 0, offX, offY, offZ, rotX, rotY, rotZ, true, false, true, false, 2, true)
                end
            else
                local posX = tonumber(objData.position and objData.position.x) or baseX
                local posY = tonumber(objData.position and data.position.y) or baseY
                local posZ = tonumber(objData.position and data.position.z) or baseZ
                local wrX = tonumber(objData.world_rotation and objData.world_rotation.x) or tonumber(objData.rotation and objData.rotation.x) or 0
                local wrY = tonumber(objData.world_rotation and objData.world_rotation.y) or tonumber(objData.rotation and objData.rotation.y) or 0
                local wrZ = tonumber(objData.world_rotation and objData.world_rotation.z) or tonumber(objData.rotation and objData.rotation.z) or 0

                ptr = GTA.CreateObject(ohash, posX + shiftX, posY + shiftY, posZ + shiftZ, true, true)
                obj = ToHandle(ptr)

                if obj ~= 0 then
                    if script and script.yield then script.yield(50) end
                    NV(0x8524A8B0171D5E07, obj, wrX + 0.0, wrY + 0.0, wrZ + 0.0, 2, true)
                end
            end

            if obj ~= 0 then
                local col = opts.has_collision
                if col ~= nil then n.col(obj, col, true) end

                local vis = opts.is_visible
                if vis ~= nil then n.vis(obj, vis, 0) end

                local alpha = tonumber(opts.alpha)
                if alpha and alpha >= 0 and alpha <= 255 then
                end

                if opts.is_frozen == true then
                end

                if opts.is_invincible == true then
                    pcall(function() Natives.InvokeVoid(0x3882114BDE571AD4, obj, true) end)
                end

                if opts.is_dynamic == false then
                end

                table.insert(spawned, {h = obj, typ = "object"})

                if objData.children then
                    for _, child in ipairs(objData.children) do
                        spawnObjectRecursive(child, obj)
                    end
                end
            end

            if script and script.yield then script.yield(30) end
            return obj
        end

        if data.children then
            for _, child in ipairs(data.children) do
                spawnObjectRecursive(child, 0)
            end
        end

        toast("Map Spawner", "spawned map with " .. #spawned .. " total entities")
        return true
    end

    for _,c in ipairs(cats) do
        FeatureMgr.AddFeature(Utils.Joaat("combo_"..c.id),c.label.." Builds",eFeatureType.Combo,"Select from Crimson\\"..c.folder.."\\",function() end)
            :SetList({[1]="Click Refresh"})

        FeatureMgr.AddFeature(Utils.Joaat("refresh_"..c.id),"Refresh "..c.label,eFeatureType.Button,"",function()
            local n = scan(c)
            toast("Spawner",c.label..": "..n.." build(s)")
        end)

        FeatureMgr.AddFeature(Utils.Joaat("spawn_"..c.id),"Spawn "..c.label,eFeatureType.Button,"",function()
            local idx = 1
            local feat = FeatureMgr.GetFeature(Utils.Joaat("combo_"..c.id))
            if feat then
                local ok,v = pcall(function() return feat:GetListIndex() end)
                if ok and v then idx = tonumber(v)+1 end
            end
            local list = files[c.id] or {}
            if idx < 1 or idx > #list or not list[idx] or list[idx].name == "" or list[idx].path == "" then
                toast("Spawner","select a build first")
                return
            end
            local ok = doSpawn(list[idx].path)
            if ok then addManifest(c,list[idx].name) end
        end)
    end

    for _, c in ipairs(mapCats) do
        FeatureMgr.AddFeature(Utils.Joaat("map_combo_" .. c.id), c.label .. " Files", eFeatureType.Combo, "Select from Crimson\\" .. c.folder .. "\\", function() end)
            :SetList({[1] = "Click Refresh"})

        FeatureMgr.AddFeature(Utils.Joaat("map_refresh_" .. c.id), "Refresh " .. c.label, eFeatureType.Button, "", function()
            local n = scanMaps(c)
            toast("Map Spawner", c.label .. ": " .. n .. " map(s)")
        end)

        FeatureMgr.AddFeature(Utils.Joaat("map_spawn_" .. c.id), "Spawn " .. c.label, eFeatureType.Button, "", function()
            local idx = 1
            local feat = FeatureMgr.GetFeature(Utils.Joaat("map_combo_" .. c.id))
            if feat then
                local ok, v = pcall(function() return feat:GetListIndex() end)
                if ok and v then idx = tonumber(v) + 1 end
            end
            local list = mapFiles[c.id] or {}
            if idx < 1 or idx > #list or not list[idx] or list[idx].name == "" or list[idx].path == "" then
                toast("Map Spawner", "select a map first")
                return
            end
            local ok = doSpawnMap(list[idx].path)
            if ok then addMapManifest(c, list[idx].name) end
        end)

        FeatureMgr.AddFeature(Utils.Joaat("map_spawn_exact_" .. c.id), "Spawn " .. c.label .. " (Exact)", eFeatureType.Button, "Spawns at exact JSON world coords", function()
            local idx = 1
            local feat = FeatureMgr.GetFeature(Utils.Joaat("map_combo_" .. c.id))
            if feat then
                local ok, v = pcall(function() return feat:GetListIndex() end)
                if ok and v then idx = tonumber(v) + 1 end
            end
            local list = mapFiles[c.id] or {}
            if idx < 1 or idx > #list or not list[idx] or list[idx].name == "" or list[idx].path == "" then
                toast("Map Spawner", "select a map first")
                return
            end
            doSpawnMapExact(list[idx].path)
        end)
    end

    FeatureMgr.AddFeature(Utils.Joaat("toggle_fly"), "Vehicle Fly", eFeatureType.Toggle, "Space = boost | Shift = up | Ctrl = down", function(f)
        toggle_vehicle_fly(f:IsToggled())
    end)

    local DISCORD_LINK = "https://discord.gg/XpFUzyCqfW"

    local function CopyDiscordLink()
        local copied = false
        pcall(function()
            if GUI and GUI.SetClipboardText then
                GUI.SetClipboardText(DISCORD_LINK)
                copied = true
            end
        end)
        if not copied then
            pcall(function()
                if ImGui and ImGui.SetClipboardText then
                    ImGui.SetClipboardText(DISCORD_LINK)
                    copied = true
                end
            end)
        end
        if copied then
            if GUI and GUI.AddToast then
                GUI.AddToast("Discord", "Link copied to clipboard!", 3000)
            end
        else
            if GUI and GUI.AddToast then
                GUI.AddToast("Discord", DISCORD_LINK, 5000)
            end
        end
    end

    FeatureMgr.AddFeature(Utils.Joaat("copy_discord_link"), "Copy Discord Invite Link", eFeatureType.Button, "", function()
        CopyDiscordLink()
    end)

    local FEAT_KURUMA_BUZZARD = Utils.Joaat("kuruma_buzzard_spawn")

    FeatureMgr.AddFeature(FEAT_KURUMA_BUZZARD, "Spawn Kuruma Swarm", eFeatureType.Button, "idk bro lol make cars go weeee", function()
        DoSpawnKurumaBuzzard()
    end)

    function RenderBruiserArsenalTab()
        if ClickGUI.BeginCustomChildWindow("Bruiser") then
            ClickGUI.RenderFeature(FEAT_SPAWN)
        end
        ClickGUI.EndCustomChildWindow()
    end

    function RenderCustomBuildTab()
        if ClickGUI.BeginCustomChildWindow("Vehicle") then
            ClickGUI.RenderFeature(FEAT_SPAWN2)
        end
        ClickGUI.EndCustomChildWindow()
    end

    function RenderBuzzardSwarmTab()
        if ClickGUI.BeginCustomChildWindow("Air Support") then
            ClickGUI.RenderFeature(FEAT_BUZZARD_AA)
        end
        ClickGUI.EndCustomChildWindow()
    end
    local function RenderStripperVehiclesTab() end
    local function RenderCursedRidesTab() end
    local function RenderBadassVehiclesTab() end

    local jsonMapFiles = {}
    local xmlMapFiles  = {}

    local function jsonMapDir()
        local r = rootDir()
        if not r then return end
        return r .. "Crimson\\Maps\\json\\"
    end

    local function xmlMapDir()
        local r = rootDir()
        if not r then return end
        return r .. "Crimson\\Maps\\xml\\"
    end

    local function readFolderManifest(path)
        if not path then return {} end
        local f = io.open(path, "r")
        if not f then return {} end
        local t = {}
        for line in f:lines() do
            line = line:gsub("^\\239\\187\\191", "")
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and line:sub(1,1) ~= "#" and line:sub(1,1) ~= ";" then
                table.insert(t, line)
            end
        end
        f:close()
        return t
    end

    local function writeFolderManifest(path, names)
        if not path then return end
        local f = io.open(path, "w")
        if not f then return end
        f:write("# map list\\n")
        for _, n in ipairs(names) do f:write(n .. "\\n") end
        f:close()
    end

    local function addFolderManifest(path, name)
        name = name:match("^%s*(.-)%s*$"):gsub("%.json$", ""):gsub("%.xml$", "")
        if name == "" then return end
        local cur = readFolderManifest(path)
        for _, v in ipairs(cur) do
            if v:lower() == name:lower() then return end
        end
        table.insert(cur, name)
        writeFolderManifest(path, cur)
    end

    local function scanJsonMaps()
        jsonMapFiles = {}
        local dir = jsonMapDir()
        if not dir then return 0 end
        if FileMgr and FileMgr.CreateDir then
            pcall(function() FileMgr.CreateDir(dir) end)
        end

        local names = readFolderManifest(dir .. "maps.txt")
        local found = {}
        local seen  = {}

        for _, n in ipairs(names) do
            local path = dir .. n .. ".json"
            if fexists(path) then
                if not seen[n:lower()] then
                    seen[n:lower()] = true
                    table.insert(found, {name = n, path = path})
                end
            end
        end

        local ok, handle = pcall(function()
            return io.popen('dir /b "' .. dir .. '" 2>nul')
        end)
        if ok and handle then
            for line in handle:lines() do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and line ~= "." and line ~= ".." then
                    local ext = line:lower():match("%.([^%.]+)$")
                    if ext == "json" then
                        local display = line:gsub("%.[^%.]+$", "")
                        if not seen[display:lower()] then
                            seen[display:lower()] = true
                            table.insert(found, {name = display, path = dir .. line})
                        end
                    end
                end
            end
            handle:close()
        end

        table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
        jsonMapFiles = found
        local list = {}
        for i = 1, #found do list[i] = found[i].name end
        if #list == 0 then
            list[1] = "No JSON maps"
            jsonMapFiles[1] = {name = "", path = ""}
        end
        local feat = FeatureMgr.GetFeature(Utils.Joaat("json_map_combo"))
        if feat then
            pcall(function()
                feat:SetList(list)
                feat:SetListIndex(1)
            end)
        end
        return #found
    end

    local function scanXmlMaps()
        xmlMapFiles = {}
        local dir = xmlMapDir()
        if not dir then return 0 end
        if FileMgr and FileMgr.CreateDir then
            pcall(function() FileMgr.CreateDir(dir) end)
        end

        local names = readFolderManifest(dir .. "maps.txt")
        local found = {}
        local seen  = {}

        for _, n in ipairs(names) do
            local path = dir .. n .. ".xml"
            if fexists(path) then
                if not seen[n:lower()] then
                    seen[n:lower()] = true
                    table.insert(found, {name = n, path = path})
                end
            end
        end

        local ok, handle = pcall(function()
            return io.popen('dir /b "' .. dir .. '" 2>nul')
        end)
        if ok and handle then
            for line in handle:lines() do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and line ~= "." and line ~= ".." then
                    local ext = line:lower():match("%.([^%.]+)$")
                    if ext == "xml" then
                        local display = line:gsub("%.[^%.]+$", "")
                        if not seen[display:lower()] then
                            seen[display:lower()] = true
                            table.insert(found, {name = display, path = dir .. line})
                        end
                    end
                end
            end
            handle:close()
        end

        table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
        xmlMapFiles = found
        local list = {}
        for i = 1, #found do list[i] = found[i].name end
        if #list == 0 then
            list[1] = "No XML maps"
            xmlMapFiles[1] = {name = "", path = ""}
        end
        local feat = FeatureMgr.GetFeature(Utils.Joaat("xml_map_combo"))
        if feat then
            pcall(function()
                feat:SetList(list)
                feat:SetListIndex(1)
            end)
        end
        return #found
    end

    FeatureMgr.AddFeature(Utils.Joaat("json_map_combo"), "JSON Maps", eFeatureType.Combo, "Select from Crimson\\Maps\\json\\", function() end)
        :SetList({[1] = "Click Refresh"})

    FeatureMgr.AddFeature(Utils.Joaat("json_map_refresh"), "Refresh JSON", eFeatureType.Button, "", function()
        local n = scanJsonMaps()
        toast("Map Spawner", "JSON: " .. n .. " map(s)")
    end)

    FeatureMgr.AddFeature(Utils.Joaat("json_map_spawn"), "Spawn JSON", eFeatureType.Button, "", function()
        local idx = 1
        local feat = FeatureMgr.GetFeature(Utils.Joaat("json_map_combo"))
        if feat then
            local ok, v = pcall(function() return feat:GetListIndex() end)
            if ok and v then idx = tonumber(v) + 1 end
        end
        if idx < 1 or idx > #jsonMapFiles or not jsonMapFiles[idx] or jsonMapFiles[idx].name == "" then
            toast("Map Spawner", "select a JSON map first")
            return
        end
        local ok = doSpawnMap(jsonMapFiles[idx].path)
        if ok then addFolderManifest(jsonMapDir() .. "maps.txt", jsonMapFiles[idx].name) end
    end)

    FeatureMgr.AddFeature(Utils.Joaat("json_map_spawn_exact"), "Spawn JSON (Exact)", eFeatureType.Button, "Spawns at exact JSON world coords", function()
        local idx = 1
        local feat = FeatureMgr.GetFeature(Utils.Joaat("json_map_combo"))
        if feat then
            local ok, v = pcall(function() return feat:GetListIndex() end)
            if ok and v then idx = tonumber(v) + 1 end
        end
        if idx < 1 or idx > #jsonMapFiles or not jsonMapFiles[idx] or jsonMapFiles[idx].name == "" then
            toast("Map Spawner", "select a JSON map first")
            return
        end
        local ok = doSpawnMapExact(jsonMapFiles[idx].path)
        if ok then addFolderManifest(jsonMapDir() .. "maps.txt", jsonMapFiles[idx].name) end
    end)

    FeatureMgr.AddFeature(Utils.Joaat("xml_map_combo"), "XML Maps", eFeatureType.Combo, "Select from Crimson\\Maps\\xml\\", function() end)
        :SetList({[1] = "Click Refresh"})

    FeatureMgr.AddFeature(Utils.Joaat("xml_map_refresh"), "Refresh XML", eFeatureType.Button, "", function()
        local n = scanXmlMaps()
        toast("Map Spawner", "XML: " .. n .. " map(s)")
    end)

    FeatureMgr.AddFeature(Utils.Joaat("xml_map_spawn"), "Spawn XML", eFeatureType.Button, "", function()
        local idx = 1
        local feat = FeatureMgr.GetFeature(Utils.Joaat("xml_map_combo"))
        if feat then
            local ok, v = pcall(function() return feat:GetListIndex() end)
            if ok and v then idx = tonumber(v) + 1 end
        end
        if idx < 1 or idx > #xmlMapFiles or not xmlMapFiles[idx] or xmlMapFiles[idx].name == "" then
            toast("Map Spawner", "select an XML map first")
            return
        end
        local ok = doSpawnMap(xmlMapFiles[idx].path)
        if ok then addFolderManifest(xmlMapDir() .. "maps.txt", xmlMapFiles[idx].name) end
    end)

    FeatureMgr.AddFeature(Utils.Joaat("xml_map_spawn_exact"), "Spawn XML (Exact)", eFeatureType.Button, "Spawns at exact XML world coords", function()
        local idx = 1
        local feat = FeatureMgr.GetFeature(Utils.Joaat("xml_map_combo"))
        if feat then
            local ok, v = pcall(function() return feat:GetListIndex() end)
            if ok and v then idx = tonumber(v) + 1 end
        end
        if idx < 1 or idx > #xmlMapFiles or not xmlMapFiles[idx] or xmlMapFiles[idx].name == "" then
            toast("Map Spawner", "select an XML map first")
            return
        end
        local ok = doSpawnMapExact(xmlMapFiles[idx].path)
        if ok then addFolderManifest(xmlMapDir() .. "maps.txt", xmlMapFiles[idx].name) end
    end)

    function RenderMapSpawnerTab()
        ImGui.Columns(2, "map_spawner_cols", false)

        if ClickGUI.BeginCustomChildWindow("JSON Maps") then
            ClickGUI.RenderFeature(Utils.Joaat("json_map_combo"))
            ClickGUI.RenderFeature(Utils.Joaat("json_map_refresh"))
            ClickGUI.RenderFeature(Utils.Joaat("json_map_spawn"))
            ClickGUI.RenderFeature(Utils.Joaat("json_map_spawn_exact"))
        end
        ClickGUI.EndCustomChildWindow()
        ImGui.NextColumn()

        if ClickGUI.BeginCustomChildWindow("XML Maps") then
            ClickGUI.RenderFeature(Utils.Joaat("xml_map_combo"))
            ClickGUI.RenderFeature(Utils.Joaat("xml_map_refresh"))
            ClickGUI.RenderFeature(Utils.Joaat("xml_map_spawn"))
            ClickGUI.RenderFeature(Utils.Joaat("xml_map_spawn_exact"))
        end
        ClickGUI.EndCustomChildWindow()
        ImGui.NextColumn()

        ImGui.Columns(1)
    end

    function RenderKurumaSwarmTab()
        if ClickGUI.BeginCustomChildWindow("the most fun") then
            ClickGUI.RenderFeature(FEAT_KURUMA_BUZZARD)
        end
        ClickGUI.EndCustomChildWindow()
    end

function RenderMegaBuildsTab()
        RenderBruiserArsenalTab()
        RenderCustomBuildTab()
        RenderBuzzardSwarmTab()
        RenderKurumaSwarmTab()
    end

    ClickGUI.AddTab("Vehicle Spawner",function()
        local ok,err = pcall(function()
            ImGui.Text("Supports .ini / .json / .xml vehicle files")
            ImGui.Separator()
            ImGui.Columns(2,"spawner_cols",false)
            for i,c in ipairs(cats) do
                if ClickGUI.BeginCustomChildWindow(c.label) == true then
                    ClickGUI.RenderFeature(Utils.Joaat("combo_"..c.id))
                    ClickGUI.RenderFeature(Utils.Joaat("refresh_"..c.id))
                    ClickGUI.RenderFeature(Utils.Joaat("spawn_"..c.id))
                end
                ClickGUI.EndCustomChildWindow()
                ImGui.NextColumn()
            end

            if ClickGUI.BeginCustomChildWindow("Extras") == true then
                ClickGUI.RenderFeature(Utils.Joaat("toggle_fly"))
                ClickGUI.RenderFeature(Utils.Joaat("copy_discord_link"))
                ImGui.Text("join the discord server")
                ImGui.Text("to download the vehicle files")
                ImGui.Text("and paste them into crimson's vehicles folders")
            end
            ClickGUI.EndCustomChildWindow()

            ImGui.Columns(1)
        end)
        if not ok then print("[Spawner Error] "..tostring(err)) end
    end)

ClickGUI.AddTab("Map Spawner", function()
        local ok, err = pcall(function()
            ImGui.Text("Spawn JSON / XML map constructs")
            ImGui.Separator()
            RenderMapSpawnerTab()
        end)
        if not ok then print("[Map Spawner Error] " .. tostring(err)) end
    end)

ClickGUI.AddTab("Vehicle Arsenal", function()
        local ok, err = pcall(function()
            RenderMegaBuildsTab()
        end)
        if not ok then print("[Vehicle Arsenal Error] " .. tostring(err)) end
    end)

ClickGUI.AddTab("Extras", function()
        local ok, err = pcall(function()
            ImGui.Text("soon")
            ImGui.Separator()
            ImGui.Text("Credits: To the builders of the modded vehicles and others.")
            ImGui.Separator()
            RenderStripperVehiclesTab()
            RenderCursedRidesTab()
            RenderBadassVehiclesTab()
        end)
        if not ok then print("[Extras Tab Error] " .. tostring(err)) end
    end)

    Script.RegisterLooped(function()
        if ShouldUnload() then
            for i = #spawned, 1, -1 do
                local ent = spawned[i]
                if ent and ent.h and ent.h ~= 0 then
                    local ok, exists = pcall(function() return n.ex(ent.h) end)
                    if ok and exists then
                        pcall(function()
                            if ent.typ == "vehicle" then n.dveh(ent.h)
                            elseif ent.typ == "object" then n.dobj(ent.h)
                            elseif ent.typ == "ped" then n.dent(ent.h)
                            else n.dent(ent.h) end
                        end)
                    end
                end
            end
            spawned = {}
            return false
        end
    end)
end