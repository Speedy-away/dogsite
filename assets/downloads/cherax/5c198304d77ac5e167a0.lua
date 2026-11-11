local Constructor = {
    json = nil,
    SpawnerMode = "Objects",
    ObjectSearchDB = {},
    PedSearchDB = {},
    pedHashes = {},
    ready = false
}
local coordSteps = {1.0, 0.1, 0.01}
local currentCoordStepIndex = 2
local rotSteps = {1.0, 0.1, 0.01}
local currentRotStepIndex = 2
local menuRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Constructor"

function DownloadAndSaveLuaFile(url, savePath)
    local c = Curl.Easy()
    c:Setopt(eCurlOption.CURLOPT_URL, url)
    c:AddHeader("User-Agent: Constructor Lua Downloader")
    c:Perform()

    while not c:GetFinished() do
        Script.Yield()
    end

    local code, data = c:GetResponse()
    if not data or data == "" then
        return false, "HTTP " .. tostring(code)
    end

    if not FileMgr.WriteFileContent(savePath, data) then
        return false, "Write failed: " .. savePath
    end

    return true
end

local menuRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Constructor"
local assetsPath   = menuRootPath .. "\\Assets"
local vehiclesPath = menuRootPath .. "\\Vehicles"

if not FileMgr.DoesFileExist(menuRootPath) then
    FileMgr.CreateDir(menuRootPath)
end
if not FileMgr.DoesFileExist(assetsPath) then
    FileMgr.CreateDir(assetsPath)
end
if not FileMgr.DoesFileExist(vehiclesPath) then
    FileMgr.CreateDir(vehiclesPath)
end

local files = {
    {
        path = assetsPath .. "\\ObjectList.txt",
        url  = "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/Assets/ObjectList.txt",
        type = "text"
    },
    {
        path = assetsPath .. "\\PedList.txt",
        url  = "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/PedList.txt",
        type = "text"
    },
    {
        path = assetsPath .. "\\json.lua",
        url  = "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/Assets/json.lua",
        type = "lua"
    },
    {
        path = menuRootPath .. "\\natives.lua",
        url  = "https://raw.githubusercontent.com/Elfish-beaker/object-list/refs/heads/main/natives.lua",
        type = "lua"
    }
}

function loadObjectsFromFile(path, target)
    local content = FileMgr.ReadFileContent(path)
    if not content then
        return 0
    end

    local count = 0

    for line in content:gmatch("[^\r\n]+") do
        local name, hash = line:match("([%w_]+):%s*(0x[%x]+)")
        if name and hash then
            target[#target + 1] = name
            Constructor.pedHashes[name] = tonumber(hash)
            count = count + 1
        elseif not line:match("^%s*%-%-") then
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                target[#target + 1] = trimmed
                count = count + 1
            end
        end
    end

    return count
end

Script.QueueJob(function()
    for _, f in ipairs(files) do
        if not FileMgr.DoesFileExist(f.path) then
            Logger.LogInfo("Downloading: " .. f.path)
            local ok, err = DownloadAndSaveLuaFile(f.url, f.path)
            if not ok then
                Logger.LogError(err)
                return
            end
        end

        if f.type == "lua" then
            local ok, err = pcall(dofile, f.path)
            if not ok then
                Logger.LogError("Lua load failed: " .. tostring(err))
                return
            end
        end
    end

    if not _G.json then
        Logger.LogError("json.lua loaded but json table missing")
        return
    end

    Constructor.json = _G.json

    local objCount = loadObjectsFromFile(files[1].path, Constructor.ObjectSearchDB)
    local pedCount = loadObjectsFromFile(files[2].path, Constructor.PedSearchDB)

    Logger.LogInfo(string.format(
        "[Constructor] Loaded %d objects, %d peds",
        objCount,
        pedCount
    ))
    Constructor.ready = true 
end)

function WhenConstructorReady(fn)
    Script.QueueJob(function()
        while not Constructor.ready do
            Script.Yield()
        end
        fn()
    end)
end

WhenConstructorReady(function()
    local data = {
        hello = "world",
        number = 42
    }

    local encoded = Constructor.json.encode(data)
    print("JSON:", encoded)

    local decoded = Constructor.json.decode(encoded)
    if decoded then 
        print(decoded.hello, decoded.number)
    end
end) 



function validateRotation(rot)
    if not rot then return {pitch=0, roll=0, yaw=0} end
    rot.pitch = math.max(-180, math.min(180, rot.pitch or 0))
    rot.roll  = math.max(-180, math.min(180, rot.roll or 0))
    rot.yaw   = math.max(-180, math.min(180, rot.yaw or 0))
    return rot
end

function GiveMeControlBitch(entptr)
    if not entptr then return false end
    if entptr.NetObject then 
        local NetObject = entptr.NetObject
        local myPID = GTA.GetLocalPlayerId()
        if NetObject.PlayerId ~= myPID then
            local handle = GTA.PointerToHandle(entptr)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(handle) then 
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(handle)
                local start = os.time()
                while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(handle) do
                    Script.Yield()
                    if os.time() - start > 5 then
                        return false
                    end
                end
            end
            return NetObject.PlayerId == myPID
        else
            return true
        end
    else
        return true
    end
end

function waitUntilPtrValid(handle, maxAttempts)
    maxAttempts = maxAttempts or 100
    local ptr
    local attempts = 0
    while attempts < maxAttempts do
        ptr = GTA.HandleToPointer(handle)
        if ptr and ptr ~= 0 and ptr.Position then
            local p = ptr.Position
            if p.x ~= 0 or p.y ~= 0 or p.z ~= 0 then
                return ptr
            end
        end
        Script.Yield(10)
        attempts = attempts + 1
    end
    return nil
end

function isEntityAVehicle(entptr)
    if entptr:GetType() == "VEHICLE" then
        return true
    end
    return false
end

function DeleteEntity(entptr)
    if not entptr then return false end
    if not GiveMeControlBitch(entptr) then
        return false
    end
    local handle = GTA.PointerToHandle(entptr)
    if not handle or not ENTITY.DOES_ENTITY_EXIST(handle) then return end
    local mem = Memory.AllocInt()
    Memory.WriteInt(mem, handle)
    ENTITY.DELETE_ENTITY(mem)
    Memory.Free(mem)
    if ENTITY.DOES_ENTITY_EXIST(ENTITY) then
        GUI.AddToast("Constructor", "Delete Entity Failed to delete the entity :/")
    end
end

function ForceModelToLoad(hash, modelName, pos)
    if not STREAMING.IS_MODEL_VALID(hash) then 
        Logger.LogError("Invalid model: " .. tostring(modelName))
        return false
    end

    while not STREAMING.HAS_MODEL_LOADED(hash) do
        STREAMING.REQUEST_MODEL(hash)
        Script.Yield()
    end

    if STREAMING.HAS_MODEL_LOADED(hash) then
        return true
    else
        Logger.LogError("Failed to load model: " .. tostring(modelName))
        return false
    end
end

function SpawnLODObject(construct)
    local pos = construct.pos
    local rot = construct.rot
    local model_hash = construct.hash

    if ForceModelToLoad(model_hash, construct.model, pos) then 
        local handle = nil
        local success, result = pcall(function()
            return GTA.CreateWorldObject(model_hash, pos.x, pos.y, pos.z, true, true)
        end)

        if success and result and result ~= 0 and ENTITY.DOES_ENTITY_EXIST(result) then
            handle = result

            Script.QueueJob(function()
                Script.Yield(50)
                ENTITY.SET_ENTITY_COORDS(handle, pos.x, pos.y, pos.z, true, false, false, true)
                ENTITY.SET_ENTITY_ROTATION(handle, rot.pitch, rot.roll, rot.yaw, 2, true)

                ENTITY.SET_ENTITY_DYNAMIC(handle, false)
                ENTITY.FREEZE_ENTITY_POSITION(handle, true)
                ENTITY.FREEZE_ENTITY_COLLISION(handle, true, true)

                local lodDistance = construct.properties and construct.properties.lodDistance or 1000.0
                pcall(function()
                    ENTITY.SET_ENTITY_LOD_DIST(handle, lodDistance)
                end)
            end)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model_hash)
            return handle
        end
        if not success then
           handle = GTA.CreateObject(model_hash, pos.x, pos.y, pos.z, true, true)
           if handle and handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(handle) then
                Script.QueueJob(function()
                    Script.Yield(50)
                                   
                    ENTITY.SET_ENTITY_COORDS(handle, pos.x, pos.y, pos.z, true, false, false, true)
                    ENTITY.SET_ENTITY_ROTATION(handle, rot.pitch, rot.roll, rot.yaw, 2, true)
                    ENTITY.FREEZE_ENTITY_POSITION(handle, true)
                    ENTITY.SET_ENTITY_COLLISION(handle, true, true)
                    
                    local lodDistance = construct.properties and construct.properties.LodDistance or 1000.0
                    pcall(function()
                        ENTITY.SET_ENTITY_LOD_DIST(handle, lodDistance)
                    end)
                end)
           end
        end
    end
end

local function isLODObject(modelName)
    if not modelName then return false end
    local name = modelName:lower()
    return name:find("_lod") or name:find("slod") or name:find("cs1_") or name:find("dt1_") or name:find("terrain")
end

local function parseModelHash(placement)
    local hexHash = placement:match("<ModelHash>(0x%x+)</ModelHash>")
    if hexHash then
        local hash = tonumber(hexHash)
        return hash
    end
    
    local decHash = placement:match("<ModelHash>(%d+)</ModelHash>")
    if decHash then
        local hash = tonumber(decHash)
        return hash
    end
    
    local strHash = placement:match("<ModelHash>(.-)</ModelHash>")
    if strHash and strHash ~= "" then
        local hash = Utils.Joaat(strHash)
        return hash
    end
    
    Logger.LogError("[Constructor] Could not parse ModelHash from placement")
    return nil
end

local function parseObjectProperties(placement)
    local properties = {}
    
    local objPropBlock = placement:match("<ObjectProperties>(.-)</ObjectProperties>")
    if objPropBlock then
        local textureVar = objPropBlock:match("<TextureVariation>(%d+)</TextureVariation>")
        if textureVar then
            properties.TextureVariation = tonumber(textureVar)
        end
    end
    
    properties.Dynamic = placement:match("<Dynamic>true</Dynamic>") ~= nil
    properties.FrozenPos = placement:match("<FrozenPos>true</FrozenPos>") ~= nil
    
    local opacity = placement:match("<OpacityLevel>(%d+)</OpacityLevel>")
    if opacity then
        properties.OpacityLevel = tonumber(opacity)
    else
        properties.OpacityLevel = 255
    end
    
    local lodDistance = placement:match("<LodDistance>([%d.]+)</LodDistance>")
    if lodDistance then
        properties.LodDistance = tonumber(lodDistance)
    else
        properties.LodDistance = 1000.0
    end
    
    properties.IsVisible = placement:match("<IsVisible>false</IsVisible>") == nil
    properties.HasGravity = placement:match("<HasGravity>true</HasGravity>") ~= nil
    properties.IsInvincible = placement:match("<IsInvincible>true</IsInvincible>") ~= nil
    properties.IsBulletProof = placement:match("<IsBulletProof>true</IsBulletProof>") ~= nil
    properties.IsFireProof = placement:match("<IsFireProof>true</IsFireProof>") ~= nil
    
    return properties
end

local function parseXMLPlacement(xmlContent)
    local placements = {}
    Logger.LogInfo("[Constructor] Starting XML parsing...")
    Logger.LogInfo(string.format("[Constructor] [DEBUG] XML content length: %d characters", #xmlContent))

    local placementCount = 0
    for placement in xmlContent:gmatch("<Placement>(.-)</Placement>") do
        placementCount = placementCount + 1
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Processing placement #%d", placementCount))
        
        local construct = {}
        
        -- Parse hash
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Parsing hash for placement #%d", placementCount))
        construct.hash = parseModelHash(placement)
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Parsed hash: %s (type: %s)", 
            tostring(construct.hash), type(construct.hash)))

        -- Parse model name
        local hashName = placement:match("<HashName>(.-)</HashName>")
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Extracted HashName: %s", tostring(hashName)))
        
        if hashName and hashName ~= "" then
            construct.model = hashName
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Model set to: %s", construct.model))
            
            if isLODObject(hashName) then
                construct.type = "LOD_OBJECT"
                Logger.LogInfo("[Constructor] [DEBUG] Detected as LOD_OBJECT")
            else
                local typeNum = tonumber(placement:match("<Type>(%d+)</Type>"))
                Logger.LogInfo(string.format("[Constructor] [DEBUG] Type number: %s", tostring(typeNum)))
                
                if typeNum == 3 then construct.type = "OBJECT"
                elseif typeNum == 2 then construct.type = "VEHICLE"
                elseif typeNum == 1 then construct.type = "PED"
                else construct.type = "OBJECT" end
                
                Logger.LogInfo(string.format("[Constructor] [DEBUG] Type assigned: %s", construct.type))
            end
        else
            Logger.LogInfo("[Constructor] [DEBUG] No HashName found, falling back to Type number")
            local typeNum = tonumber(placement:match("<Type>(%d+)</Type>"))
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Fallback type number: %s", tostring(typeNum)))
            
            if typeNum == 3 then construct.type = "OBJECT"
            elseif typeNum == 2 then construct.type = "VEHICLE"
            elseif typeNum == 1 then construct.type = "PED"
            else construct.type = "OBJECT" end
            
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Fallback type assigned: %s", construct.type))
        end

        -- Position & rotation
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Parsing position and rotation for placement #%d", placementCount))
        local posRot = placement:match("<PositionRotation>(.-)</PositionRotation>")
        construct.pos = {x=0, y=0, z=0}
        construct.rot = {pitch=0, roll=0, yaw=0}
        
        if posRot then
            Logger.LogInfo("[Constructor] [DEBUG] PositionRotation block found")
            construct.pos.x = tonumber(posRot:match("<X>(.-)</X>")) or 0
            construct.pos.y = tonumber(posRot:match("<Y>(.-)</Y>")) or 0
            construct.pos.z = tonumber(posRot:match("<Z>(.-)</Z>")) or 0
            construct.rot.pitch = tonumber(posRot:match("<Pitch>(.-)</Pitch>")) or 0
            construct.rot.roll  = tonumber(posRot:match("<Roll>(.-)</Roll>")) or 0
            construct.rot.yaw   = tonumber(posRot:match("<Yaw>(.-)</Yaw>")) or 0
            
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Position: (%.2f, %.2f, %.2f)", 
                construct.pos.x, construct.pos.y, construct.pos.z))
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Rotation: pitch=%.2f, roll=%.2f, yaw=%.2f", 
                construct.rot.pitch, construct.rot.roll, construct.rot.yaw))
        else
            Logger.LogInfo("[Constructor] [DEBUG] No PositionRotation block found, using defaults")
        end

        -- Properties
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Parsing properties for placement #%d", placementCount))
        construct.properties = parseObjectProperties(placement)
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Properties parsed: %s", tostring(construct.properties)))

        -- Attachment info
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Checking for attachments in placement #%d", placementCount))
        local attachBlock = placement:match("<Attachment>(.-)</Attachment>")
        
        if attachBlock then
            local parentIdx = tonumber(attachBlock:match("<ParentIndex>(%d+)</ParentIndex>"))

            Logger.LogInfo(string.format("[Constructor] [DEBUG] Parent index: %s", tostring(parentIdx)))
            
            construct.attachmentData = {
                parentIndex = parentIdx - 1,
                offset = {
                    x = tonumber(attachBlock:match("<X>(.-)</X>")) or 0,
                    y = tonumber(attachBlock:match("<Y>(.-)</Y>")) or 0,
                    z = tonumber(attachBlock:match("<Z>(.-)</Z>")) or 0
                },
                rotation = {
                    pitch = tonumber(attachBlock:match("<Pitch>(.-)</Pitch>")) or 0,
                    roll  = tonumber(attachBlock:match("<Roll>(.-)</Roll>")) or 0,
                    yaw   = tonumber(attachBlock:match("<Yaw>(.-)</Yaw>")) or 0
                },
                type = attachBlock:match("<Type>(.-)</Type>") or "Static"
            }
            
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Attachment offset: (%.2f, %.2f, %.2f)", 
                construct.attachmentData.offset.x, construct.attachmentData.offset.y, construct.attachmentData.offset.z))
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Attachment rotation: pitch=%.2f, roll=%.2f, yaw=%.2f, type=%s",
                construct.attachmentData.rotation.pitch, construct.attachmentData.rotation.roll, 
                construct.attachmentData.rotation.yaw, construct.attachmentData.type))
        else
            Logger.LogInfo("[Constructor] [DEBUG] No attachment block found")
        end

        table.insert(placements, construct)
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Placement #%d added to results. Total: %d", 
            placementCount, #placements))
    end

    Logger.LogInfo(string.format("[Constructor] [DEBUG] XML parsing complete. Total placements parsed: %d", placementCount))
    if placementCount == 0 then
        Logger.LogError("[Constructor] [DEBUG] WARNING: No placements found in XML!")
    end
    
    return placements
end


local function spawnXMLEntity(construct)
    local model_hash = construct.hash
    if not model_hash then
        Logger.LogError("[Constructor] No valid model hash for construct")
        return nil
    end
        
    local pos = construct.pos
    local rot = construct.rot
    local handle = nil
    
    if construct.type == "LOD_OBJECT" then
        handle = SpawnLODObject(construct)
        
    elseif construct.type == "OBJECT" then
        if not ForceModelToLoad(model_hash, construct.model, pos) then
            Logger.LogError("[Constructor] Failed to load object model: " .. tostring(construct.model))
            return nil
        end

        handle = GTA.CreateObject(model_hash, pos.x, pos.y, pos.z, false, true)

    elseif construct.type == "VEHICLE" then
        if not ForceModelToLoad(model_hash, construct.model, pos) then
            Logger.LogError("[Constructor] Failed to load vehicle model: " .. tostring(construct.model))
            return nil
        end

        handle = GTA.SpawnVehicle(model_hash, pos.x, pos.y, pos.z, rot.yaw, true, true)

    elseif construct.type == "PED" then
        if not ForceModelToLoad(model_hash, construct.model, pos) then
            Logger.LogError("[Constructor] Failed to load ped model: " .. tostring(construct.model))
            return nil
        end

        handle = GTA.CreatePed(model_hash, 4, pos.x, pos.y, pos.z, rot.yaw, true, true)
    end

    if not handle or handle == 0 or not ENTITY.DOES_ENTITY_EXIST(handle) then
        Logger.LogError("[Constructor] Failed to create entity: " .. tostring(construct.model))
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model_hash)
        return nil
    end
    
    Script.QueueJob(function()
        Script.Yield(100)
        
        ENTITY.SET_ENTITY_COORDS(handle, pos.x, pos.y, pos.z, true, false, false, true)
        ENTITY.SET_ENTITY_ROTATION(handle, rot.pitch, rot.roll, rot.yaw, 2, true)
        
        local props = construct.properties
        
        if props then
            if props.FrozenPos then
                ENTITY.FREEZE_ENTITY_POSITION(handle, true)
            end
            
            if not props.Dynamic then
                ENTITY.SET_ENTITY_DYNAMIC(handle, false)
            end
            
            if props.OpacityLevel and props.OpacityLevel < 255 then
                ENTITY.SET_ENTITY_ALPHA(handle, props.OpacityLevel, false)
            end
            
            if not props.IsVisible then
                ENTITY.SET_ENTITY_VISIBLE(handle, false, false)
            end
            
            if not props.HasGravity then
                ENTITY.SET_ENTITY_HAS_GRAVITY(handle, false)
            end
            
            if props.IsInvincible then
                ENTITY.SET_ENTITY_INVINCIBLE(handle, true)
            end
            
            if props.IsBulletProof or props.IsFireProof then
                ENTITY.SET_ENTITY_PROOFS(handle, 
                    props.IsBulletProof or false, 
                    props.IsFireProof or false, 
                    false, false, false, false, false, false)
            end
        end
        
        if construct.type == "LOD_OBJECT" then
            ENTITY.SET_ENTITY_DYNAMIC(handle, false)
            ENTITY.FREEZE_ENTITY_POSITION(handle, true)
            ENTITY.SET_ENTITY_COLLISION(handle, true, true)
            
            local lodDistance = props and props.LodDistance or 1000.0
            pcall(function()
                ENTITY.SET_ENTITY_LOD_DIST(handle, lodDistance)
            end)
        end
    end)
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model_hash)
    
    return handle
end

local ExtendedConstructor = {
    otherSelectedIndex = 0,
    entityList = {},
    selectedIndex = 0,

    attachChildIndex  = 0,
    attachParentIndex = 0,
    attachOffset      = {x=0,y=0,z=0},
    attachRotation    = {pitch=0,roll=0,yaw=0},
    attachType        = "Static",

    objectSearchBuffer  = "",
    objectSearchResults = {},
    lastSearchQuery     = "",

    saveNameBuffer   = "",
    selectedSaveFile = nil,
    saveMessage      = {text="", timer=0},
    player = GTA.GetLocalPed(),
    
    spawnedProjects = {},
    selectedXMLFile = "",
    isSpawning = false
}

function ExtendedConstructor:GetSelected()
    if self.selectedIndex > 0 and self.selectedIndex <= #self.entityList then
        return self.entityList[self.selectedIndex]
    end
    return nil
end


function ExtendedConstructor:ApplyTransform(entry)
    if not entry or not entry.ptr or entry.ptr == 0 then return end
    if entry.attachmentData then
        return
    end
    local controlGranted = GiveMeControlBitch(entry.ptr)
    if not controlGranted then
        Logger.LogError("[Constructor] Cannot apply transform (no control).")
        return
    end
    local handle = GTA.PointerToHandle(entry.ptr)
    if not handle then
        Logger.LogError("[Constructor] Invalid handle for applyTransform.")
        return
    end

    local px, py, pz = entry.pos.x, entry.pos.y, entry.pos.z
    local pitch, roll, yaw = entry.rot.pitch, entry.rot.roll, entry.rot.yaw

    Script.QueueJob(function()
        local s, e = pcall(function()
           ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, px, py, pz, false,false,false)
            ENTITY.SET_ENTITY_ROTATION(handle, pitch, roll, yaw, 2, true)
        end)
        if not s then
            Logger.LogError("[Constructor] applyTransform failed: "..tostring(e))
        end
    end)
end

local function processConstruct(construct, i, projectId, spawnedEntities)
    Logger.LogInfo(string.format("[Constructor] [DEBUG] processConstruct called - index: %d, projectId: %s", i, projectId))
    
    if not construct.hash then
        Logger.LogError(string.format("[Constructor] Invalid construct at index %d - no hash", i))
        Logger.LogInfo(string.format("[Constructor] [DEBUG] construct object: %s", tostring(construct)))
        return false
    end

    Logger.LogInfo(string.format("[Constructor] [DEBUG] Construct #%d - hash: 0x%X, model: %s, type: %s", 
        i, construct.hash, construct.model or "nil", construct.type or "nil"))

    local handle = spawnXMLEntity(construct)
    Logger.LogInfo(string.format("[Constructor] [DEBUG] spawnXMLEntity returned handle: %s", tostring(handle)))
    
    if not handle then
        Logger.LogError(string.format("[Constructor] Failed to spawn entity %d", i))
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Handle is nil or false for entity %d", i))
        return false
    end

    Logger.LogInfo(string.format("[Constructor] [DEBUG] Waiting for valid pointer, handle value: %s", tostring(handle)))
    local ptr = waitUntilPtrValid(handle, 100)
    Logger.LogInfo(string.format("[Constructor] [DEBUG] waitUntilPtrValid returned: %s", tostring(ptr)))
    
    if not ptr or ptr == 0 then
        Logger.LogError(string.format("[Constructor] Failed to get valid pointer for entity %d", i))
        Logger.LogInfo(string.format("[Constructor] [DEBUG] Pointer validation failed - ptr: %s, handle: %s", 
            tostring(ptr), tostring(handle)))
        if ENTITY.DOES_ENTITY_EXIST(handle) then 
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Entity exists, deleting handle %s", tostring(handle)))
            ENTITY.DELETE_ENTITY(handle) 
        else
            Logger.LogInfo(string.format("[Constructor] [DEBUG] Entity does not exist at handle %s", tostring(handle)))
        end
        return false
    end

    Logger.LogInfo(string.format("[Constructor] [DEBUG] Valid pointer obtained: %s", tostring(ptr)))

    local entry = {
        ptr = ptr,
        name = string.format("[%s] %s #%d", projectId, construct.model or ("Hash_" .. tostring(construct.hash)), i),
        modelHash = construct.hash,
        isVehicle = construct.type == "VEHICLE",
        isLODObject = construct.type == "LOD_OBJECT",
        objectType = construct.type,
        pos = {x=construct.pos.x, y=construct.pos.y, z=construct.pos.z},
        rot = {pitch=construct.rot.pitch, roll=construct.rot.roll, yaw=construct.rot.yaw},
        attachmentData = construct.attachmentData,
        noWheels = false,
        isProjectEntity = true,
        projectId = projectId,
        properties = construct.properties
    }

    Logger.LogInfo(string.format("[Constructor] [DEBUG] Entry created - name: %s, pos: (%.2f, %.2f, %.2f)", 
        entry.name, entry.pos.x, entry.pos.y, entry.pos.z))

    table.insert(spawnedEntities, entry)
    Logger.LogInfo(string.format("[Constructor] [DEBUG] Entry inserted into spawnedEntities, total count: %d", 
        #spawnedEntities))

    -- Handle attachment
    if entry.attachmentData then
        local att = entry.attachmentData
        local parentEntry = spawnedEntities[att.parentIndex]

        if parentEntry and parentEntry.ptr then
            local childHandle = GTA.PointerToHandle(entry.ptr)
            local parentHandle = GTA.PointerToHandle(parentEntry.ptr)

            if parentHandle == childHandle then
                Logger.LogError(string.format("[Constructor] Attachment skipped: child is same as parent (index %d)", i))
            else
                local success, err = pcall(function()
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(
                        childHandle,
                        parentHandle,
                        0,
                        att.offset.x,
                        att.offset.y,
                        att.offset.z,
                        att.rotation.pitch,
                        att.rotation.roll,
                        att.rotation.yaw,
                        false,
                        true, false, false, 1, false, 1
                    )
                end)

                if success then
                    Logger.LogInfo(string.format("[Constructor] Attachment successful for entity %d", i))
                else
                    Logger.LogError(string.format("[Constructor] Attachment failed: %s", tostring(err)))
                end
            end
        else
            Logger.LogError(string.format("[Constructor] Parent entry invalid or pointer nil for entity %d", i))
        end
    end

    Logger.LogInfo(string.format("[Constructor] [DEBUG] processConstruct completed successfully for entity %d", i))
    return true
end



local function spawnEntitiesSequentially(placements, callback)
    local projectId = "project_" .. os.time()
    local successCount = 0
    local totalCount = #placements
    local spawnedEntities = {}
    
    
    Script.QueueJob(function()
        for i, construct in ipairs(placements) do
            
            if processConstruct(construct, i, projectId, spawnedEntities) then
                successCount = successCount + 1
            end
            
            local delayTime = 75
            if construct.type == "LOD_OBJECT" then
                delayTime = 100
            elseif construct.type == "VEHICLE" then
                delayTime = 150
            end
            
            Script.Yield(delayTime)
        end
        
        
        if callback then
            callback(spawnedEntities, projectId, successCount, totalCount)
        end
    end)
end

function ExtendedConstructor:LoadXMLProject(fileName)
    if self.isSpawning then
        Logger.LogError("[Constructor] Already spawning project, please wait...")
        return false
    end
    
    local fullPath = menuRootPath .. "\\XML\\" .. fileName
    local xmlContent = FileMgr.ReadFileContent(fullPath)
    
    if not xmlContent or xmlContent == "" then
        Logger.LogError("[Constructor] Failed to read XML file: " .. fullPath)
        return false
    end
    
    -- Logger.LogInfo("[Constructor] Loading XML project: " .. fileName)
    
    local placements = parseXMLPlacement(xmlContent)
    if #placements == 0 then
        Logger.LogError("[Constructor] No valid placements found in XML")
        return false
    end
    
    local centerX, centerY, centerZ = 0, 0, 0
    for _, placement in ipairs(placements) do
        centerX = centerX + placement.pos.x
        centerY = centerY + placement.pos.y
        centerZ = centerZ + placement.pos.z
    end
    centerX = centerX / #placements
    centerY = centerY / #placements
    centerZ = centerZ / #placements
    
    local stats = {
        total = #placements,
        objects = 0,
        lodObjects = 0,
        vehicles = 0,
        peds = 0
    }
    
    for _, placement in ipairs(placements) do
        if placement.type == "OBJECT" then
            stats.objects = stats.objects + 1
        elseif placement.type == "LOD_OBJECT" then
            stats.lodObjects = stats.lodObjects + 1
        elseif placement.type == "VEHICLE" then
            stats.vehicles = stats.vehicles + 1
        elseif placement.type == "PED" then
            stats.peds = stats.peds + 1
        end
    end
    
    -- Logger.LogInfo(string.format("[Constructor] Project analysis: %d total (%d objects, %d LOD, %d vehicles, %d peds)", 
    --     stats.total, stats.objects, stats.lodObjects, stats.vehicles, stats.peds))
    -- Logger.LogInfo(string.format("[Constructor] Project center: %.2f, %.2f, %.2f", centerX, centerY, centerZ))
    
    self.isSpawning = true
    
    spawnEntitiesSequentially(placements, function(spawnedEntities, projectId, successCount, totalCount)
        for _, entity in ipairs(spawnedEntities) do
            table.insert(self.entityList, entity)
        end
        
        local lodSuccessCount = 0
        local realLODCount = 0
        for _, entity in ipairs(spawnedEntities) do
            if entity.isLODObject then
                lodSuccessCount = lodSuccessCount + 1
                if entity.ptr and ENTITY.DOES_ENTITY_EXIST(GTA.PointerToHandle(entity.ptr)) then
                    realLODCount = realLODCount + 1
                end
            end
        end
        
        table.insert(self.spawnedProjects, {
            id = projectId,
            fileName = fileName,
            spawnTime = Time.GetEpocheMs(),
            entityCount = successCount,
            totalEntities = totalCount,
            lodObjectCount = lodSuccessCount,
            realLODCount = realLODCount,
            hasLODObjects = lodSuccessCount > 0,
            centerPos = {x = centerX, y = centerY, z = centerZ},
            stats = stats,
            safeMode = true
        })
        
        self.selectedIndex = #self.entityList
        self.isSpawning = false
        
        -- Logger.LogInfo(string.format("[Constructor] Successfully loaded project: %s (%d/%d entities, %d LOD objects)", 
        --     fileName, successCount, totalCount, lodSuccessCount))
    end)
    
    return true
end

function ExtendedConstructor:RemoveAllProjectEntities()
    local removed = 0
        
    for i = #self.entityList, 1, -1 do
        local entity = self.entityList[i]
        if entity.isProjectEntity then
            entity.ptr = GTA.HandleToPointer(entity)
            DeleteEntity(entity.ptr)
            table.remove(self.entityList, i)
            removed = removed + 1
        end
    end
    
    self.spawnedProjects = {}
    self.selectedIndex = math.max(1, math.min(self.selectedIndex, #self.entityList))
    
    Logger.LogInfo(string.format("[Constructor] Removed %d project entities safely", removed))
    return removed
end


function ExtendedConstructor:RemoveProjectById(projectId)
    local removed = 0
    
    for i = #self.entityList, 1, -1 do
        local entity = self.entityList[i]
        if entity.isProjectEntity and entity.projectId == projectId then
            entity.ptr = GTA.HandleToPointer(entity)
            DeleteEntity(entity.ptr)
            table.remove(self.entityList, i)
            removed = removed + 1
        end
    end
    
    for i = #self.spawnedProjects, 1, -1 do
        if self.spawnedProjects[i].id == projectId then
            table.remove(self.spawnedProjects, i)
            break
        end
    end
    
    self.selectedIndex = math.max(1, math.min(self.selectedIndex, #self.entityList))
    
    return removed
end


local BOOKMARKS_FILE = FileMgr.GetMenuRootPath() .. "\\Constructor\\bookmarks.ini"
local selectedBookmark = ""

local function LoadBookmarks()
    local bookmarks = {}
    if FileMgr.DoesFileExist(BOOKMARKS_FILE) then
        local content = FileMgr.ReadFileContent(BOOKMARKS_FILE)
        for line in content:gmatch("[^\r\n]+") do
            table.insert(bookmarks, line)
        end
    end
    return bookmarks
end

local function SaveBookmarks(bookmarks)
    local content = table.concat(bookmarks, "\n")
    FileMgr.WriteFileContent(BOOKMARKS_FILE, content)
end

local function AddBookmark(entity)
    local bookmarks = LoadBookmarks()
    for _, entry in ipairs(bookmarks) do
        if entry == entity.name then
            print("Bookmark already exists: " .. entity.name)
            return 
        end
    end
    
    table.insert(bookmarks, entity.name)
    SaveBookmarks(bookmarks)
end

local function RemoveBookmarkByName(name)
    local bookmarks = LoadBookmarks()
    for i, entry in ipairs(bookmarks) do
        if entry == name then
            table.remove(bookmarks, i)
            break
        end
    end
    SaveBookmarks(bookmarks)
end

local function ClearBookmarks()
    FileMgr.WriteFileContent(BOOKMARKS_FILE, "")
end

local function isChildOf(parentHandle, childHandle)
    local current = parentHandle
    local checked = {}
    
    while current and current ~= 0 do
        if checked[current] then
            return true
        end
        checked[current] = true
        
        if current == childHandle then
            return true
        end
        
        current = ENTITY.GET_ENTITY_ATTACHED_TO(current)
        if current == parentHandle then
            break
        end
    end
    
    return false
end

function ExtendedConstructor:AttachEntities(childIndex, parentIndex, offset, rotation, attachType)
    if childIndex < 1 or childIndex > #self.entityList 
       or parentIndex < 1 or parentIndex > #self.entityList 
       or childIndex == parentIndex then
        Logger.LogError("[Attach] Invalid indexes.")
        return false
    end

    local child  = self.entityList[childIndex]
    local parent = self.entityList[parentIndex]

    if not child.ptr or child.ptr == 0 or not parent.ptr or parent.ptr == 0 then
        Logger.LogError("[Attach] Invalid entity ptrs.")
        return false
    end

    local chandle = GTA.PointerToHandle(child.ptr)
    local phandle = GTA.PointerToHandle(parent.ptr)

    if not chandle or not phandle or not ENTITY.DOES_ENTITY_EXIST(chandle) or not ENTITY.DOES_ENTITY_EXIST(phandle) then
        Logger.LogError("[Attach] Could not retrieve valid entity handles.")
        return false
    end

    if isChildOf(phandle, chandle) then
        Logger.LogError("[Attach] Cannot attach - would create circular dependency")
        return false
    end

    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(chandle)
        local attempts = 0
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) and attempts < 50 do
            Script.Yield(10)
            attempts = attempts + 1
        end

        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) then
            Logger.LogError("[Attach] Failed to gain control of entity.")
            return false
        end
    end

    ENTITY.DETACH_ENTITY(chandle, true, true)
    
    Script.QueueJob(function()
        Script.Yield(10)
        
        rotation = validateRotation(rotation or {pitch=0, roll=0, yaw=0})
        local chosenType = attachType or self.attachType
        local isParentVehicle = isEntityAVehicle (parent.ptr)

        local function doAttachStatic()
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                chandle, phandle, 0,
                offset.x, offset.y, offset.z,
                rotation.pitch, rotation.roll, rotation.yaw,
                false, true, true, false, 0, true
            )
        end

        local function doAttachDynamic()
            ENTITY.ATTACH_ENTITY_TO_ENTITY(
                chandle, phandle, 0,
                offset.x, offset.y, offset.z,
                rotation.pitch, rotation.roll, rotation.yaw,
                true, false, true, false, 0, false
            )
        end

        local function doAttachRigid()
            ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY_OVERRIDE_INVERSE_MASS(
                chandle, phandle, 0, 0,
                offset.x, offset.y, offset.z,
                0.0, 0.0, 0.0,
                rotation.pitch, rotation.roll, rotation.yaw,
                100000.0, true, true, true, false, 2, 0.1, 0.1
            )
        end

        local success, err = pcall(function()
            if chosenType == "Static" then
                doAttachStatic()
            elseif chosenType == "Dynamic" then
                doAttachDynamic()
            elseif chosenType == "Rigid" then
                doAttachRigid()
            end
            if isParentVehicle then
                ENTITY.PROCESS_ENTITY_ATTACHMENTS(phandle)
            end
        end)

        if not success then
            Logger.LogError("[Attach] Attachment failed: " .. tostring(err))
            return false
        end

        child.attachmentData = {
            parentIndex = parentIndex,
            parentPtr = parent.ptr,
            offset = {x=offset.x, y=offset.y, z=offset.z},
            rotation = {pitch=rotation.pitch, roll=rotation.roll, yaw=rotation.yaw},
            attachmentType = chosenType
        }

        GiveMeControlBitch(child.ptr)
        GiveMeControlBitch(parent.ptr)

        Logger.LogInfo("[Attach] Successfully attached entity.")
    end)
    
    return true
end

function ExtendedConstructor:DetachEntity(childIndex)
    local child = self.entityList[childIndex]
    if not child or not child.ptr then 
        Logger.LogError("[Constructor] No valid entity to detach.")
        return false 
    end

    local chandle = GTA.PointerToHandle(child.ptr)
    if not chandle or not ENTITY.DOES_ENTITY_EXIST(chandle) then
        Logger.LogError("[Constructor] Invalid entity handle.")
        return false
    end

    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(chandle)
        local attempts = 0
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) and attempts < 50 do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(chandle)
            Script.Yield(10)
            attempts = attempts + 1
        end

        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(chandle) then
            Logger.LogError("[Constructor] Failed to gain control of entity before detaching.")
            return false
        end
    end

    ENTITY.DETACH_ENTITY(chandle, true, true)

    ENTITY.SET_ENTITY_DYNAMIC(chandle, true)
    ENTITY.SET_ENTITY_COLLISION(chandle, true, true)    

    local pos = ENTITY.GET_ENTITY_COORDS(chandle, false)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(chandle, pos.x + 0.1, pos.y + 0.1, pos.z + 0.1, false, false, false)

    child.attachmentData = nil

    return true
end

function ExtendedConstructor:DeleteSelected()
    local sel = self:GetSelected()
    if not sel or not sel.ptr or sel.ptr == 0 then
        Logger.LogError("[Constructor] No valid selected entity.")
        return
    end

    local localPed = GTA.GetLocalPed()
    if sel.ptr == localPed then
        GUI.AddToast("Constructor", "You cannot delete your own ped!", 5000, eToastPos.TOP_RIGHT)
        return
    end

    DeleteEntity(sel.ptr)

    for i, entity in ipairs(self.entityList) do
        if entity.ptr == sel.ptr then
            table.remove(self.entityList, i)
            break
        end
    end

    self.selectedIndex = math.max(1, math.min(self.selectedIndex, #self.entityList))
end

local function getEntityModelName(ptr)
    if not ptr or ptr == 0 then return "nil" end
    local mi = ptr.ModelInfo
    if mi and mi.Model then
        local mn = GTA.GetModelNameFromHash(mi.Model)
        if mn and #mn > 0 then return mn end
        return "Model_0x"..string.format("%X", mi.Model)
    end
    return "UnknownEntity"
end

function ExtendedConstructor:AddEntity(ptr, customName)
    if not ptr or ptr == 0 then
        Logger.LogError("[Constructor] AddEntity invalid ptr.")
        return
    end

    local isVeh = isEntityAVehicle(ptr)
    local pos = ptr.Position

    local modelStr = customName or getEntityModelName(ptr)

    local prefix = isVeh and "[Vehicle] " or ""
    local name = prefix .. modelStr 

    local entry = {
        ptr       = ptr,
        name      = name, 
        modelHash = ptr.ModelInfo and ptr.ModelInfo.Model or 0,
        isVehicle = isVeh,
        pos       = {x=pos.x, y=pos.y, z=pos.z},
        rot       = {pitch=0, roll=0, yaw=0},
        attachmentData = nil,
        noWheels  = false,
        isProjectEntity = false
    }
    table.insert(self.entityList, entry)
    self.selectedIndex = #self.entityList
end

function ExtendedConstructor:ImportCurrentVehicle()
    local lv = GTA.GetLocalVehicle()
    if not lv then
        Logger.LogError("[Constructor] You are not in a vehicle.")
        return
    end
    for _, ent in ipairs(self.entityList) do
        if ent.ptr == lv then
            return
        end
    end
    local modelName = getEntityModelName(lv)
    self:AddEntity(lv, "[Vehicle] "..modelName)
end

function ExtendedConstructor:TeleportToMe()
    local sel = self:GetSelected()
    if not sel or not sel.ptr or sel.ptr==0 then
        Logger.LogError("[Constructor] No valid selection to teleport.")
        return
    end
    local plr = GTA.GetLocalPed()
    if not plr then return end
    local ppos = plr.Position
    sel.pos.x = ppos.x
    sel.pos.y = ppos.y
    sel.pos.z = ppos.z
    self:ApplyTransform(sel)
end

function ExtendedConstructor:TeleportMeToObj()
    local sel = self:GetSelected()
    if not sel or not sel.ptr or sel.ptr==0 then
        Logger.LogError("[Constructor] No valid selection to teleport to.")
        return
    end
    local plr = GTA.GetLocalPed()
    if not plr then return end
    local objPos = sel.ptr.Position
    local handle = GTA.PointerToHandle(plr)
    if handle then
        Script.QueueJob(function()
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
                handle,
                objPos.x,
                objPos.y,
                objPos.z,
                false,false,false
            )
        end)
    end
end

function ExtendedConstructor:SpawnVehicle(modelStrOrHash)
    Script.QueueJob(function()
        local lp = GTA.GetLocalPed()
        if not lp then
            Logger.LogError("[Constructor] No local ped.")
            return
        end
        local pos = lp.Position
        local x, y, z = pos.x + 5, pos.y, pos.z

        local hash = (type(modelStrOrHash)=="string") and Utils.Joaat(modelStrOrHash) or modelStrOrHash
        local handle = GTA.SpawnVehicle(hash, x,y,z, 0.0, true,true)
        if handle==0 then
            Logger.LogError("[Constructor] Could not spawn vehicle.")
            return
        end
        local ptr = waitUntilPtrValid(handle)
        if ptr and ptr~=0 then
            self:AddEntity(ptr)
        end
    end)
end

function ExtendedConstructor:SpawnObject(modelStrOrHash)
    Script.QueueJob(function()
        local lp = GTA.GetLocalPed()
        if not lp then
            Logger.LogError("[Constructor] No local ped.")
            return
        end
        local pos = lp.Position
        local x, y, z = pos.x + 2, pos.y, pos.z

        local isString = type(modelStrOrHash) == "string"
        local hash = isString and Utils.Joaat(modelStrOrHash) or modelStrOrHash
        if not hash or hash == 0 then
            Logger.LogError("[Constructor] Invalid model name or hash: " .. tostring(modelStrOrHash))
            return
        end

        if not ForceModelToLoad(hash, modelStrOrHash, {x=x, y=y, z=z}) then
            Logger.LogError("[Constructor] Could not load model: " .. tostring(modelStrOrHash))
            return
        end

        local success, err = pcall(function()
            handle = GTA.CreateObject(hash, x, y, z, true, true)
        end)
        if not success then 
            handle = GTA.CreateWorldObject(hash, x, y, z, true, true)
        end
        if handle == 0 then
            Logger.LogError("[Constructor] Could not create object: " .. tostring(modelStrOrHash) .. "error is " .. err)
            return
        end

        local ptr = waitUntilPtrValid(handle)
        if ptr and ptr ~= 0 then
            local propName = isString and modelStrOrHash or GTA.GetModelNameFromHash(hash)
            self:AddEntity(ptr, propName) 
        end
    end)
end

function ExtendedConstructor:SpawnPed(modelName)
    Script.QueueJob(function()
        local lp = GTA.GetLocalPed()
        if not lp then return end
        local pos = lp.Position
        local x, y, z = pos.x + 2, pos.y, pos.z

        local hash = Constructor.pedHashes[modelName] or Utils.Joaat(modelName)
        local handle = GTA.CreatePed(hash, 0, x,y,z, 0.0, true, true)
        if handle==0 then return end
        local ptr = waitUntilPtrValid(handle)
        if ptr and ptr~=0 then
            self:AddEntity(ptr, "[Ped] " .. modelName)
        end
    end)
end

function ExtendedConstructor:doObjectSearch(str)
    self.objectSearchResults = {}
    local query = str:lower()
    local currentDB = Constructor.SpawnerMode == "Objects" and Constructor.ObjectSearchDB or Constructor.PedSearchDB
    
    if #query == 0 then
        for _,n in ipairs(currentDB) do
            table.insert(self.objectSearchResults, n)
        end
    else
        for _,n in ipairs(currentDB) do
            if n:lower():find(query,1,true) then
                table.insert(self.objectSearchResults, n)
            end
        end
    end
end

function ExtendedConstructor:RenderBookmarkUI()
    ClickGUI.BeginCustomChildWindow("Bookmarks")
    ImGui.Text("Bookmarks:")
    local bookmarks = LoadBookmarks()
    
    if ImGui.Button("Add Selected to Bookmarks") then
        local selected = self:GetSelected()
        if selected then
            AddBookmark(selected)
        end
    end
    
    if ImGui.BeginCombo("Select Bookmark", selectedBookmark ~= "" and selectedBookmark or "Select...") then
        for i, entry in ipairs(bookmarks) do
            local isSelected = (selectedBookmark == entry)
            if ImGui.Selectable(entry, isSelected) then
                selectedBookmark = entry
            end
        end
        ImGui.EndCombo()
    end
    
    if selectedBookmark ~= "" and ImGui.Button("Spawn Selected Bookmark") then
        self:SpawnObject(selectedBookmark)
    end
    
    if selectedBookmark ~= "" and ImGui.Button("Remove Selected Bookmark") then
        RemoveBookmarkByName(selectedBookmark)
        selectedBookmark = ""
    end
    
    if ImGui.Button("Clear All Bookmarks") then
        ClearBookmarks()
    end
    ClickGUI.EndCustomChildWindow()
end


local selectedXMLFile = ""
local dir = menuRootPath .. "\\XML"
FileMgr.CreateDir(dir)

function GetSavedXMLFiles()
    local files = FileMgr.FindFiles(menuRootPath .. "\\XML", ".xml", false)
    local xmlFiles = {}

    if not files or #files == 0 then
        return xmlFiles
    end

    for _, file in ipairs(files) do
        local fileName = file:match("[^\\/]+$") 
        table.insert(xmlFiles, fileName)
    end

    return xmlFiles
end

local customXMLFileName = ""
if not FileMgr.DoesFileExist(dir) then 
    FileMgr.CreateDir(dir)
end

local function SaveEntityToXML(xml, entity, parentIndex)
    local handle = GTA.PointerToHandle(entity.ptr)
    if not handle or not ENTITY.DOES_ENTITY_EXIST(handle) then return end

    local modelHash = ENTITY.GET_ENTITY_MODEL(handle)
    local modelName = STREAMING.IS_MODEL_VALID(modelHash) and GTA.GetModelNameFromHash(modelHash) or ""

    local pos = ENTITY.GET_ENTITY_COORDS(handle, true)
    local rot = ENTITY.GET_ENTITY_ROTATION(handle, 2)

    local visible = ENTITY.IS_ENTITY_VISIBLE(handle)
    local alpha = ENTITY.GET_ENTITY_ALPHA(handle)
    local lodDist = ENTITY.GET_ENTITY_LOD_DIST(handle)

    local typeNum = 3 -- OBJECT
    if ENTITY.IS_ENTITY_A_PED(handle) then typeNum = 1
    elseif ENTITY.IS_ENTITY_A_VEHICLE(handle) then typeNum = 2 end

    xml[#xml + 1] = '  <Placement>'
    xml[#xml + 1] = string.format('    <Type>%d</Type>', typeNum)
    xml[#xml + 1] = string.format('    <ModelHash>0x%X</ModelHash>', modelHash)
    if modelName ~= "" then
        xml[#xml + 1] = string.format('    <HashName>%s</HashName>', modelName)
    end

    xml[#xml + 1] = '    <PositionRotation>'
    xml[#xml + 1] = string.format('      <X>%.6f</X>', pos.x)
    xml[#xml + 1] = string.format('      <Y>%.6f</Y>', pos.y)
    xml[#xml + 1] = string.format('      <Z>%.6f</Z>', pos.z)
    xml[#xml + 1] = string.format('      <Pitch>%.6f</Pitch>', rot.x)
    xml[#xml + 1] = string.format('      <Roll>%.6f</Roll>', rot.y)
    xml[#xml + 1] = string.format('      <Yaw>%.6f</Yaw>', rot.z)
    xml[#xml + 1] = '    </PositionRotation>'

    xml[#xml + 1] = '    <ObjectProperties>'
    xml[#xml + 1] = string.format('      <IsVisible>%s</IsVisible>', visible and "true" or "false")
    xml[#xml + 1] = string.format('      <OpacityLevel>%d</OpacityLevel>', alpha or 255)
    xml[#xml + 1] = string.format('      <LodDistance>%.1f</LodDistance>', lodDist or 1000.0)
    xml[#xml + 1] = '    </ObjectProperties>'

    -- Check attachment
    local attachedHandle = ENTITY.GET_ENTITY_ATTACHED_TO(handle)
    if attachedHandle and attachedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(attachedHandle) then
        -- Compute offset & rotation relative to parent
        local parentPos = ENTITY.GET_ENTITY_COORDS(attachedHandle, true)
        local parentRot = ENTITY.GET_ENTITY_ROTATION(attachedHandle, 2)

        local offset = {x=pos.x - parentPos.x, y=pos.y - parentPos.y, z=pos.z - parentPos.z}
        local rotation = {pitch=rot.x - parentRot.x, roll=rot.y - parentRot.y, yaw=rot.z - parentRot.z}

        xml[#xml + 1] = '    <Attachment>'
        xml[#xml + 1] = string.format('      <ParentIndex>%d</ParentIndex>', parentIndex)
        xml[#xml + 1] = '      <Offset>'
        xml[#xml + 1] = string.format('        <X>%.6f</X>', offset.x)
        xml[#xml + 1] = string.format('        <Y>%.6f</Y>', offset.y)
        xml[#xml + 1] = string.format('        <Z>%.6f</Z>', offset.z)
        xml[#xml + 1] = '      </Offset>'
        xml[#xml + 1] = '      <Rotation>'
        xml[#xml + 1] = string.format('        <Pitch>%.6f</Pitch>', rotation.pitch)
        xml[#xml + 1] = string.format('        <Roll>%.6f</Roll>', rotation.roll)
        xml[#xml + 1] = string.format('        <Yaw>%.6f</Yaw>', rotation.yaw)
        xml[#xml + 1] = '      </Rotation>'
        xml[#xml + 1] = '      <Type>Static</Type>'
        xml[#xml + 1] = '    </Attachment>'
    end

    xml[#xml + 1] = '  </Placement>'
end

local function SaveAllEntitiesToXML()
    local filename = (customXMLFileName ~= "" and customXMLFileName or "entities_" .. os.time()) .. ".xml"
    local fullPath = dir .. "\\" .. filename

    local xml = {}
    xml[#xml + 1] = '<?xml version="1.0" encoding="UTF-8"?>'
    xml[#xml + 1] = '<Entities>'

    for i, entity in ipairs(ExtendedConstructor.entityList) do
        SaveEntityToXML(xml, entity, i)
    end

    xml[#xml + 1] = '</Entities>'
    FileMgr.WriteFileContent(fullPath, table.concat(xml, "\n"))
    Logger.LogInfo("[Constructor] Saved XML with attachments: " .. fullPath)
end

function ExtendedConstructor:RenderXMLSpawnerUI()
    ClickGUI.BeginCustomChildWindow("XML Spawner")

    ImGui.Text("XML Project Loader")

    local newText, selected = ImGui.InputText("Filename", customXMLFileName, ImGuiInputTextFlags.AllowTabInput)
    if selected then
        customXMLFileName = newText
    end

    if ImGui.Button("Save All Entities to XML") then
        if customXMLFileName ~= "" then
            SaveAllEntitiesToXML()
        else
            Logger.LogError("[Constructor] Filename cannot be empty!")
        end
    end

    ImGui.Separator()

    local xmlFiles = GetSavedXMLFiles()
    if #xmlFiles > 0 then
        if ImGui.BeginCombo("Select XML File", self.selectedXMLFile ~= "" and self.selectedXMLFile or "Choose File") then
            for _, file in ipairs(xmlFiles) do
                if ImGui.Selectable(file, file == self.selectedXMLFile) then
                    self.selectedXMLFile = file
                end
            end
            ImGui.EndCombo()
        end
    else
        ImGui.Text("No XML files found.")
    end

    if self.isSpawning then
        ImGui.Text("Loading project, please wait...")
        ImGui.ProgressBar(-1 * Time.GetEpocheMs() / 1000.0)
    else
        if ImGui.Button("Load Selected XML File") and self.selectedXMLFile ~= "" then
            self:LoadXMLProject(self.selectedXMLFile)
        end
    end
    
    ImGui.Separator()
    
    if ImGui.Button("Remove All Project Entities") then
        self:RemoveAllProjectEntities()
    end
    
    if #self.spawnedProjects > 0 then
        ImGui.Text("Loaded Projects:")
        for i, project in ipairs(self.spawnedProjects) do
            ImGui.Text(string.format("• %s", project.fileName))
            
            if project.totalEntities then
                ImGui.Text(string.format("  Entities: %d/%d successful", project.entityCount, project.totalEntities))
                
                local successRate = (project.entityCount / project.totalEntities) * 100
                ImGui.Text(string.format("  Success rate: %.1f%%", successRate))
                
                if project.lodObjectCount and project.lodObjectCount > 0 then
                    local realCount = project.realLODCount or 0
                    ImGui.Text(string.format("  LOD: %d total (%d replaced)", 
                        project.lodObjectCount, realCount))
                end
                
                if project.stats then
                    local s = project.stats
                    ImGui.Text(string.format("  Types: %dO %dL %dV %dP", 
                        s.objects or 0, s.lodObjects or 0, s.vehicles or 0, s.peds or 0))
                end
            end
            
            if ImGui.Button("Remove##" .. i) then
                self:RemoveProjectById(project.id)
            end
            
            ImGui.Spacing()
        end
    end
    
    ImGui.Text("Total Entities: " .. #self.entityList)

    ClickGUI.EndCustomChildWindow()
end

function ExtendedConstructor:RenderObjectSpawner()
    ClickGUI.BeginCustomChildWindow("Spawner")

    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 10, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 6, 6)
    
    ImGui.Text("Object Spawner")
    ImGui.Separator()
    ImGui.Spacing()

    if ImGui.BeginCombo("Spawn Type", Constructor.SpawnerMode) then
        if ImGui.Selectable("Objects", Constructor.SpawnerMode == "Objects") then
            Constructor.SpawnerMode = "Objects"
            self.objectSearchBuffer = ""
            self:doObjectSearch("")
        end

        if ImGui.Selectable("Peds", Constructor.SpawnerMode == "Peds") then
            Constructor.SpawnerMode = "Peds"
            self.objectSearchBuffer = ""
            self:doObjectSearch("")
        end

        ImGui.EndCombo()
    end


    ImGui.Spacing()

    ImGui.Text("Search:")
    ImGui.SameLine()
    self.objectSearchBuffer = self.objectSearchBuffer or ""
    local buffer = self.objectSearchBuffer
    local updated, changed = ImGui.InputTextWithHint("##objsearch", "Type to search...", buffer, 128)

    if changed then
        self.objectSearchBuffer = updated 
        if updated ~= self.lastSearchQuery then
            self:doObjectSearch(updated)
            self.lastSearchQuery = updated
        end
    end

    ImGui.Spacing()
    
    ImGui.BeginChild(
        "SearchResults",
        -1,
        400, 
        true,
        ImGuiWindowFlags.AlwaysVerticalScrollbar | ImGuiWindowFlags.HorizontalScrollbar
    )

    if #self.objectSearchResults > 0 then
        ImGui.Text("Double-click to spawn:")
        ImGui.Spacing()
        ImGui.Separator()
        for i, objName in ipairs(self.objectSearchResults) do
            if i % 2 == 0 then
                ImGui.PushStyleColor(ImGuiCol.Header, 0.25, 0.25, 0.25, 1.0)
            end

            local clicked = ImGui.Selectable(objName, false, ImGuiSelectableFlags.AllowDoubleClick)

            if clicked and ImGui.IsMouseDoubleClicked(0) then
                if Constructor.SpawnerMode == "Objects" then
                    self:SpawnObject(objName)
                else  
                    self:SpawnPed(objName)
                end
            end

            if i % 2 == 0 then
                ImGui.PopStyleColor()
            end

            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.Text("Model: " .. objName)
                ImGui.Text("Double-click to spawn")
                ImGui.EndTooltip()
            end
        end
    else
        ImGui.TextColored(0.8, 0.8, 0.8, 1.0, "No results found...")
    end

    ImGui.EndChild()

    ImGui.PopStyleVar(2)
    ClickGUI.EndCustomChildWindow()
end

function ExtendedConstructor:RenderActiveList()
    ImGui.Text("Active Entities:")
    ImGui.Separator()
    
    for i, ent in ipairs(self.entityList) do
        local label = string.format("%d) %s", i, ent.name or "??")
        if ImGui.Selectable(label, self.selectedIndex == i) then
            self.selectedIndex = i
        end
    end
end

function ExtendedConstructor:RenderSelectedTransform()
    local sel = self:GetSelected()
    if not sel then
        ImGui.Text("No entity selected.")
        return
    end

    ImGui.Text("Editing: " .. (sel.name or "??"))
    ImGui.Separator()

    if ImGui.BeginCombo("Coord Step", tostring(coordSteps[currentCoordStepIndex])) then
        for i, v in ipairs(coordSteps) do
            if ImGui.Selectable(tostring(v), i == currentCoordStepIndex) then
                currentCoordStepIndex = i
            end
        end
        ImGui.EndCombo()
    end
    local cStep = coordSteps[currentCoordStepIndex]

    local function CoordinateControl(axis, value)
        ImGui.Text(axis .. ":")
        ImGui.SameLine()
        local newValue, changed = ImGui.DragFloat("##Coord" .. axis, value, 0.01, -9999999, 9999999, "%.3f")
        if changed then sel.pos[axis:lower()] = newValue; self:ApplyTransform(sel) end
        ImGui.SameLine()
        if ImGui.Button("+##" .. axis) then sel.pos[axis:lower()] = sel.pos[axis:lower()] + cStep; self:ApplyTransform(sel) end
        ImGui.SameLine()
        if ImGui.Button("-##" .. axis) then sel.pos[axis:lower()] = sel.pos[axis:lower()] - cStep; self:ApplyTransform(sel) end
    end

    CoordinateControl("X", sel.pos.x)
    CoordinateControl("Y", sel.pos.y)
    CoordinateControl("Z", sel.pos.z)

    ImGui.Separator()
    ImGui.Text("Rotation (degrees):")

    if ImGui.BeginCombo("Rot Step", tostring(rotSteps[currentRotStepIndex])) then
        for i, v in ipairs(rotSteps) do
            if ImGui.Selectable(tostring(v), i == currentRotStepIndex) then
                currentRotStepIndex = i
            end
        end
        ImGui.EndCombo()
    end
    local rStep = rotSteps[currentRotStepIndex]

    local function RotationControl(axis, value)
        ImGui.Text(axis .. ":")
        ImGui.SameLine()
        local newValue, changed = ImGui.DragFloat("##" .. axis, value, 0.1, -180, 180, "%.2f")
        if changed then sel.rot[axis:lower()] = newValue; self:ApplyTransform(sel) end
        ImGui.SameLine()
        if ImGui.Button("+##" .. axis) then sel.rot[axis:lower()] = sel.rot[axis:lower()] + rStep; self:ApplyTransform(sel) end
        ImGui.SameLine()
        if ImGui.Button("-##" .. axis) then sel.rot[axis:lower()] = sel.rot[axis:lower()] - rStep; self:ApplyTransform(sel) end
    end

    RotationControl("Pitch", sel.rot.pitch)
    RotationControl("Roll", sel.rot.roll)
    RotationControl("Yaw", sel.rot.yaw)
end

function ExtendedConstructor:RenderAttachmentUI()
    ImGui.Text("Attachment Types:")
    local types = { "Static", "Dynamic", "Rigid" }
    for i, tn in ipairs(types) do
        local sel = (self.attachType == tn)
        if ImGui.RadioButton(tn, sel) then
            self.attachType = tn
        end
        if i < #types then ImGui.SameLine() end
    end

    ImGui.Separator()
    ImGui.Text("Attachment:")

    if #self.entityList == 0 then
        ImGui.Text("No entities in the pool.")
        return
    end

    local cidx = self.attachChildIndex
    local pidx = self.attachParentIndex

    local function label(idx)
        if idx > 0 and idx <= #self.entityList then
            return string.format("%d) %s", idx, self.entityList[idx].name or "??")
        end
        return "None"
    end

    if ImGui.BeginCombo("Child Entity", label(self.attachChildIndex or 0)) then
        for i, e in ipairs(self.entityList) do
            if ImGui.Selectable(label(i), self.attachChildIndex == i) then
                self.attachChildIndex = i
            end
        end
        ImGui.EndCombo()
    end
    
    if ImGui.BeginCombo("Parent Entity", label(self.attachParentIndex or 0)) then
        for i, e in ipairs(self.entityList) do
            if ImGui.Selectable(label(i), self.attachParentIndex == i) then
                self.attachParentIndex = i
            end
        end
        ImGui.EndCombo()
    end
    
    ClickGUI.RenderFeature(Utils.Joaat("visibility")) 
    ClickGUI.RenderFeature(Utils.Joaat("collision")) 

    ImGui.Text("Attachment Offset:")
    local o = self.attachOffset
    local changedOffset = false

    for _, axis in ipairs({ "X", "Y", "Z" }) do
        local newValue, changed = ImGui.DragFloat(axis .. "##offset", o[axis:lower()], 0.01, -100, 100, "%.2f")
        if changed then
            o[axis:lower()] = newValue
            changedOffset = true
        end
    end

    if changedOffset then
        self:AttachEntities(cidx, pidx, o, self.attachRotation, self.attachType)
    end

    ImGui.Text("Attachment Rotation:")
    local r = self.attachRotation

    for _, axis in ipairs({ "Pitch", "Roll", "Yaw" }) do
        local newValue, changed = ImGui.DragFloat(axis .. "##rotation", r[axis:lower()], 0.1, -180, 180, "%.2f")
        if changed then
            r[axis:lower()] = newValue
            self:AttachEntities(cidx, pidx, o, r, self.attachType)
        end
    end

    if ImGui.Button("Attach Child->Parent") then
        self:AttachEntities(cidx, pidx, o, r, self.attachType)
    end

    if self.selectedIndex > 0 then
        ImGui.SameLine()
        if ImGui.Button("Detach Selected") then
            self:DetachEntity(self.selectedIndex)
        end
    end
end

function ExtendedConstructor:RenderActiveObjectsWindow()
    if ClickGUI.BeginCustomChildWindow("Entity Pool", -1, 220) then
        self:RenderActiveList()
        ImGui.Separator()
        ImGui.Text("Manage Selected Entity:")
        
        if ImGui.Button("Import Current Vehicle") then
            self:ImportCurrentVehicle()
        end
        ClickGUI.RenderFeature(Utils.Joaat("aim_entity_selector"))
        ClickGUI.RenderFeature(Utils.Joaat("CONSTR_ADD_PLAYER_PED"))
        if self.selectedIndex > 0 then
            if ImGui.Button("Teleport to Me") then
                self:TeleportToMe()
            end
            ImGui.SameLine()
            if ImGui.Button("Teleport Me to Object") then
                self:TeleportMeToObj()
            end
            ImGui.Separator()

            if ImGui.Button("Delete Selected Entity") then
                self:DeleteSelected()
            end
        end
        ClickGUI.EndCustomChildWindow()
    end
end

function RenderMainGUI()
    if ImGui.BeginTabBar("MainTabBar", ImGuiTabBarFlags.None) then
        if ImGui.BeginTabItem("Object Spawner") then
            ImGui.BeginTable("SpawnerTable", 2, ImGuiTableFlags.Resizable)
            ImGui.TableNextColumn()
            ExtendedConstructor:RenderObjectSpawner()
            ImGui.TableNextColumn() 
            ExtendedConstructor:RenderBookmarkUI()
            ExtendedConstructor:RenderActiveObjectsWindow()
            
            ImGui.EndTable()
            ImGui.EndTabItem()
        end
        
        if ImGui.BeginTabItem("Selected Transform") then
            ImGui.BeginTabBar("secondary", ImGuiTabBarFlags.None)
        
            if ImGui.BeginTabItem("Transform") then
                ClickGUI.BeginCustomChildWindow("Transformation")
                ExtendedConstructor:RenderActiveList() 
                ExtendedConstructor:RenderSelectedTransform()
                ClickGUI.EndCustomChildWindow()  
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Attachment") then
                ClickGUI.BeginCustomChildWindow("Attachment")  
                ExtendedConstructor:RenderAttachmentUI()
                ClickGUI.EndCustomChildWindow()  
                ImGui.EndTabItem()
            end
        
            ImGui.EndTabBar() 
            ImGui.EndTabItem()
        end
        
        
        if ImGui.BeginTabItem("Project/Settings") then
            ClickGUI.BeginCustomChildWindow("Management")
            ExtendedConstructor:RenderXMLSpawnerUI()
            if ImGui.Button("Copy Discord Invite Link") then
                ImGui.SetClipboardText("https://discord.gg/vFqXHwpfny")
            end
            ImGui.Separator()
            ClickGUI.EndCustomChildWindow()
            ImGui.EndTabItem()
        end
        
        ImGui.EndTabBar()
    end
end

function RenderPlayerTab()
    if ImGui.BeginTabBar("PlayerTabBar", ImGuiTabBarFlags.None) then
        if ImGui.BeginTabItem("Player Spawner") then
            ClickGUI.BeginCustomChildWindow("Constructor")
                ClickGUI.RenderFeature(Utils.Joaat("CONSTR_ADD_SELECTED_PLAYER_PED")) 
                ClickGUI.RenderFeature(Utils.Joaat("CONSTR_GET_PLAYER_CAR"))
                ImGui.Text("Use this to add the selected player and vehicle to the constructor.")            
            ClickGUI.EndCustomChildWindow()
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end
FeatureMgr.AddFeature(Utils.Joaat("visibility"), "Toggle Invisibility", eFeatureType.Toggle, "Makes the selected entity invisible", function(feat)
        local entity = ExtendedConstructor:GetSelected()
        if entity and ENTITY.DOES_ENTITY_EXIST(GTA.PointerToHandle(entity.ptr)) then
            local handle = GTA.PointerToHandle(entity.ptr)
            local toggle = feat:IsToggled()
            ENTITY.SET_ENTITY_VISIBLE(handle, not toggle, false)
        end
    end
)

FeatureMgr.AddFeature(Utils.Joaat("collision"), "Toggle Collision", eFeatureType.Toggle, "Toggles collision for the selected entity", function(feat)
        local entity = ExtendedConstructor:GetSelected()
        if entity and ENTITY.DOES_ENTITY_EXIST(GTA.PointerToHandle(entity.ptr)) then
            local handle = GTA.PointerToHandle(entity.ptr)
            local toggle = feat:IsToggled()
            ENTITY.SET_ENTITY_COLLISION(handle, toggle, true)
        end
    end
)

FeatureMgr.AddFeature( Utils.Joaat("CONSTR_GET_PLAYER_CAR"), "Get Selected Player Vehicle", eFeatureType.Button, "Get the selected player's vehicle and add it to the entity pool for manipulation.",
    function(feat)
        local playerId = Utils.GetSelectedPlayer()
        if not playerId or not NETWORK.NETWORK_IS_PLAYER_ACTIVE(playerId) then
            Logger.LogError("[Constructor] No valid selected player.")
            return
        end
        local playerPed = PLAYER.GET_PLAYER_PED(playerId)

        local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
        if not vehicle or vehicle == 0 then
            Logger.LogError("[Constructor] Selected player is not in a vehicle.")
            return
        end

        local vehiclePtr = GTA.HandleToPointer(vehicle)

        for _, entity in ipairs(ExtendedConstructor.entityList) do
            if entity.ptr == vehiclePtr then
                Logger.LogInfo("[Constructor] Selected player's vehicle is already in the pool.")
                return
            end
        end

        local vehicleModel = ENTITY.GET_ENTITY_MODEL(vehicle)
        local vehicleName = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(vehicleModel)

        ExtendedConstructor:AddEntity(vehiclePtr, string.format("[Player Vehicle] %s", vehicleName))
        Logger.LogInfo("[Constructor] Selected player's vehicle added to the constructor entity list.")
    end,
    true
)

local lastSelectedEntity = nil 

local function getEntityName(entityHandle)
    local modelHash = ENTITY.GET_ENTITY_MODEL(entityHandle)
    
    if VEHICLE.IS_THIS_MODEL_A_CAR(modelHash) or VEHICLE.IS_THIS_MODEL_A_BIKE(modelHash) then
        return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(modelHash) or "Unknown Vehicle"
    elseif PED.IS_PED_HUMAN(entityHandle) then
        return "Pedestrian"
    elseif OBJECT.IS_OBJECT_ENTITY(entityHandle) then
        return "Object"
    else
        return "Unknown Entity"
    end
end

FeatureMgr.AddFeature(Utils.Joaat("aim_entity_selector"), "Select Entity by Aiming", eFeatureType.Toggle, "Press 'E' while aiming at an entity to select it",
    function(feat)
        Script.QueueJob(function()
            while feat:IsToggled() do
                local player = PLAYER.PLAYER_ID()
                local aimedEntity = Memory.AllocInt()

                if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, aimedEntity) then
                    local entityHandle = Memory.ReadInt(aimedEntity)

                    if entityHandle and ENTITY.DOES_ENTITY_EXIST(entityHandle) then
                        if lastSelectedEntity ~= entityHandle then
                            if ImGui.IsKeyPressed(0x45) then 
                                local entityPtr = GTA.HandleToPointer(entityHandle)
                                if entityPtr and entityPtr ~= 0 then
                                    local entityName = getEntityName(entityHandle)
                                    ExtendedConstructor:AddEntity(entityPtr, entityName)
                                    Logger.LogInfo("[Constructor] Added entity: " .. entityName)
                                    lastSelectedEntity = entityHandle 
                                end
                            end
                        end
                    end
                end

                Memory.Free(aimedEntity)
                Script.Yield(10) 
            end
        end)
    end
)

FeatureMgr.AddFeature( Utils.Joaat("CONSTR_ADD_PLAYER_PED"), "Add Player Ped to Constructor", eFeatureType.Button, "Adds the player's ped to the constructor entity list for manipulation.",
    function(feat)
        local playerPed = GTA.GetLocalPed()
        if not playerPed then
            Logger.LogError("[Constructor] Failed to get the player's ped.")
            return
        end

        for _, entity in ipairs(ExtendedConstructor.entityList) do
            if entity.ptr == playerPed then
                Logger.LogInfo("[Constructor] Player ped is already in the entity pool.")
                return
            end
        end

        ExtendedConstructor:AddEntity(playerPed, "[Player Ped]")
        Logger.LogInfo("[Constructor] Player ped added to the constructor entity list.")
    end,
    true,
    false
)

FeatureMgr.AddFeature(Utils.Joaat("CONSTR_ADD_SELECTED_PLAYER_PED"),"Add Selected Player Ped to Constructor",eFeatureType.Button,"Adds the selected player's ped to the constructor entity list for manipulation.",
    function(feat)
        local selectedPlayerId = Utils.GetSelectedPlayer()
        if not selectedPlayerId or not NETWORK.NETWORK_IS_PLAYER_ACTIVE(selectedPlayerId) then
            Logger.LogError("[Constructor] No valid selected player.")
            return
        end

        local selectedPlayerPed = PLAYER.GET_PLAYER_PED(selectedPlayerId)
        if not selectedPlayerPed or selectedPlayerPed == 0 then
            Logger.LogError("[Constructor] Failed to get the selected player's ped.")
            return
        end

        local pedPtr = GTA.HandleToPointer(selectedPlayerPed)
        if not pedPtr or pedPtr == 0 then
            Logger.LogError("[Constructor] Failed to convert ped handle to a valid pointer.")
            return
        end

        for _, entity in ipairs(ExtendedConstructor.entityList) do
            if entity.ptr == pedPtr then
                Logger.LogInfo("[Constructor] Selected player's ped is already in the pool.")
                return
            end
        end

        local playerName = PLAYER.GET_PLAYER_NAME(selectedPlayerId)
        ExtendedConstructor:AddEntity(pedPtr, string.format("[Player Ped] %s", playerName))
        Logger.LogInfo("[Constructor] Selected player's ped added to the constructor entity list.")
    end,
    true,
    false
)

local pendingVehicles = {}
EventMgr.RegisterHandler(eLuaEvent.ON_VEHICLE_CHANGE, function()
    local cv = GTA.GetLocalVehicle()
    if cv and not pendingVehicles[cv] then
        pendingVehicles[cv] = true
        local alreadyExists = false
        for _, e in ipairs(ExtendedConstructor.entityList) do
            if e.ptr == cv then
                alreadyExists = true
                break
            end
        end
        if not alreadyExists then
            ExtendedConstructor:AddEntity(cv)
            Logger.LogInfo("[Constructor] Detected new vehicle -> added.")
        end
        Script.QueueJob(function()
            Script.Yield(1000)
            pendingVehicles[cv] = nil
        end)
    end
end)

local cachedMode = nil

Script.RegisterLooped(function()
    if not ShouldUnload() then
        if cachedMode ~= GUI.GetMode() then
            if GUI.GetMode() == eGuiMode.ClickGUI then
                ClickGUI.AddTab("Constructor",RenderMainGUI)
                ClickGUI.AddPlayerTab("Constructor", RenderPlayerTab)
                return 
            else
                GUI.AddToast("Constructor", "Constructor does not support ListUI users", 5000, eToastPos.TOP_RIGHT)     
                SetShouldUnload()
                return
            end
            cachedMode = GUI.GetMode()
        end
        Script.Yield(500)
    end
end)

return ExtendedConstructor