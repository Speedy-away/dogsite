local pluginName = "Spooner"
local menuRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\" .. pluginName
local nativesPath = menuRootPath .. "\\Assets\\natives.lua"
local configPath = menuRootPath .. "\\config.xml"
local libsPath = menuRootPath .. "\\libs\\"

FileMgr.CreateDir(menuRootPath)
FileMgr.CreateDir(menuRootPath .. "\\Assets")
FileMgr.CreateDir(menuRootPath .. "\\libs")

local propListPath = menuRootPath .. "\\Assets\\PropList.xml"
local vehicleListPath = menuRootPath .. "\\Assets\\VehicleList.xml"
local pedListPath = menuRootPath .. "\\Assets\\PedList.xml"
local spoonerSavePath = menuRootPath .. "\\XML"

FileMgr.CreateDir(spoonerSavePath)

-- ============================================================================
-- Inlined Library: Logger
-- ============================================================================
local CustomLogger = {}

function CustomLogger.New(pluginName)
    local self = {}
    self.pluginName = pluginName

    function self.Info(str)
        Logger.Log(eLogColor.WHITE, self.pluginName, str)
    end

    function self.Warn(str)
        Logger.Log(eLogColor.YELLOW, self.pluginName, str)
    end

    function self.Error(str)
        Logger.Log(eLogColor.RED, self.pluginName, str)
    end

    return self
end

-- ============================================================================
-- Inlined Library: XMLParser
-- ============================================================================
local XMLParser = {}

function XMLParser.ParseAttributes(tag)
    local attrs = {}
    for name, value in string.gmatch(tag, '(%w+)="([^"]*)"') do
        attrs[name] = value
    end
    return attrs
end

function XMLParser.Parse(xmlString)
    -- Remove XML declaration and comments
    xmlString = xmlString:gsub("<%?[^?]*%?>", "")
    xmlString = xmlString:gsub("<!%-%-.-%-%->" , "")

    local result = {}
    local stack = {result}
    local current = result

    for closing, tagName, attrs, selfClosing in string.gmatch(xmlString, "<(/?)([%w_]+)(.-)%s*(/?)>") do
        if closing == "/" then
            table.remove(stack)
            current = stack[#stack]
        else
            local node = {
                tag = tagName,
                attributes = XMLParser.ParseAttributes(attrs),
                children = {}
            }

            if not current.children then
                current.children = {}
            end
            table.insert(current.children, node)

            if selfClosing ~= "/" then
                table.insert(stack, node)
                current = node
            end
        end
    end

    return result.children or {}
end

function XMLParser.EscapeAttribute(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    str = str:gsub("&", "&amp;")
    str = str:gsub("<", "&lt;")
    str = str:gsub(">", "&gt;")
    str = str:gsub('"', "&quot;")
    str = str:gsub("'", "&apos;")
    return str
end

function XMLParser.GenerateXML(rootTag, options)
    local lines = {}
    table.insert(lines, '<?xml version="1.0" encoding="UTF-8"?>')
    table.insert(lines, '<' .. rootTag .. '>')

    for key, value in pairs(options) do
        local escapedValue = XMLParser.EscapeAttribute(value)
        table.insert(lines, '    <Option name="' .. key .. '" value="' .. escapedValue .. '" />')
    end

    table.insert(lines, '</' .. rootTag .. '>')
    return table.concat(lines, '\n')
end

function XMLParser.ParseConfig(xmlString)
    local config = {}
    local parsed = XMLParser.Parse(xmlString)

    for _, node in ipairs(parsed) do
        if node.tag == "SpoonerConfig" then
            for _, optionNode in ipairs(node.children or {}) do
                if optionNode.tag == "Option" then
                    local name = optionNode.attributes.name
                    local value = optionNode.attributes.value
                    if name and value then
                        -- Convert string values to appropriate types
                        if value == "true" then
                            config[name] = true
                        elseif value == "false" then
                            config[name] = false
                        elseif tonumber(value) then
                            config[name] = tonumber(value)
                        else
                            config[name] = value
                        end
                    end
                end
            end
        end
    end

    return config
end

-- ============================================================================
-- Menyoo Spooner XML Format Generation
-- ============================================================================

function XMLParser.GenerateSpoonerXML(placements, referenceCoords)
    local lines = {}
    table.insert(lines, '<?xml version="1.0" encoding="ISO-8859-1"?>')
    table.insert(lines, '<SpoonerPlacements>')
    table.insert(lines, '\t<Note />')
    table.insert(lines, '\t<AudioFile volume="400" />')
    table.insert(lines, '\t<ClearDatabase>false</ClearDatabase>')
    table.insert(lines, '\t<ClearWorld>0</ClearWorld>')
    table.insert(lines, '\t<ClearMarkers>false</ClearMarkers>')
    table.insert(lines, '\t<IPLsToLoad load_mp_maps="false" load_sp_maps="false" />')
    table.insert(lines, '\t<IPLsToRemove />')
    table.insert(lines, '\t<InteriorsToEnable />')
    table.insert(lines, '\t<InteriorsToCap />')
    table.insert(lines, '\t<WeatherToSet></WeatherToSet>')
    table.insert(lines, '\t<TimecycleModifier strength="1"></TimecycleModifier>')
    table.insert(lines, '\t<StartTaskSequencesOnLoad>true</StartTaskSequencesOnLoad>')

    -- Reference coordinates
    if referenceCoords then
        table.insert(lines, '\t<ReferenceCoords>')
        table.insert(lines, '\t\t<X>' .. string.format("%.6f", referenceCoords.x) .. '</X>')
        table.insert(lines, '\t\t<Y>' .. string.format("%.6f", referenceCoords.y) .. '</Y>')
        table.insert(lines, '\t\t<Z>' .. string.format("%.6f", referenceCoords.z) .. '</Z>')
        table.insert(lines, '\t</ReferenceCoords>')
    else
        table.insert(lines, '\t<ReferenceCoords>')
        table.insert(lines, '\t\t<X>0</X>')
        table.insert(lines, '\t\t<Y>0</Y>')
        table.insert(lines, '\t\t<Z>0</Z>')
        table.insert(lines, '\t</ReferenceCoords>')
    end

    -- Add all placements
    for _, placement in ipairs(placements) do
        table.insert(lines, XMLParser.GeneratePlacementXML(placement))
    end

    table.insert(lines, '</SpoonerPlacements>')
    return table.concat(lines, '\n')
end

function XMLParser.GeneratePlacementXML(placement)
    local lines = {}
    table.insert(lines, '\t<Placement>')
    table.insert(lines, '\t\t<ModelHash>' .. placement.modelHash .. '</ModelHash>')
    table.insert(lines, '\t\t<Type>' .. placement.type .. '</Type>')
    table.insert(lines, '\t\t<Dynamic>' .. tostring(placement.dynamic or false) .. '</Dynamic>')
    table.insert(lines, '\t\t<FrozenPos>' .. tostring(placement.frozen or false) .. '</FrozenPos>')
    table.insert(lines, '\t\t<HashName>' .. XMLParser.EscapeAttribute(placement.hashName or "") .. '</HashName>')
    table.insert(lines, '\t\t<InitialHandle>' .. (placement.handle or 0) .. '</InitialHandle>')

    -- Vehicle properties if type is vehicle (2)
    if placement.type == 2 and placement.vehicleProperties then
        table.insert(lines, XMLParser.GenerateVehiclePropertiesXML(placement.vehicleProperties))
    end

    -- Ped properties if type is ped (1)
    if placement.type == 1 and placement.pedProperties then
        table.insert(lines, XMLParser.GeneratePedPropertiesXML(placement.pedProperties))
    end

    -- Common entity properties
    table.insert(lines, '\t\t<OpacityLevel>' .. (placement.opacity or 255) .. '</OpacityLevel>')
    table.insert(lines, '\t\t<LodDistance>' .. (placement.lodDistance or 16960) .. '</LodDistance>')
    table.insert(lines, '\t\t<IsVisible>' .. tostring(placement.isVisible ~= false) .. '</IsVisible>')
    table.insert(lines, '\t\t<MaxHealth>' .. (placement.maxHealth or 1000) .. '</MaxHealth>')
    table.insert(lines, '\t\t<Health>' .. (placement.health or 1000) .. '</Health>')
    table.insert(lines, '\t\t<HasGravity>' .. tostring(placement.hasGravity ~= false) .. '</HasGravity>')
    table.insert(lines, '\t\t<IsOnFire>' .. tostring(placement.isOnFire or false) .. '</IsOnFire>')
    table.insert(lines, '\t\t<IsInvincible>' .. tostring(placement.isInvincible or false) .. '</IsInvincible>')
    table.insert(lines, '\t\t<IsBulletProof>' .. tostring(placement.isBulletProof or false) .. '</IsBulletProof>')
    table.insert(lines, '\t\t<IsCollisionProof>' .. tostring(placement.isCollisionProof or false) .. '</IsCollisionProof>')
    table.insert(lines, '\t\t<IsExplosionProof>' .. tostring(placement.isExplosionProof or false) .. '</IsExplosionProof>')
    table.insert(lines, '\t\t<IsFireProof>' .. tostring(placement.isFireProof or false) .. '</IsFireProof>')
    table.insert(lines, '\t\t<IsMeleeProof>' .. tostring(placement.isMeleeProof or false) .. '</IsMeleeProof>')
    table.insert(lines, '\t\t<IsOnlyDamagedByPlayer>' .. tostring(placement.isOnlyDamagedByPlayer or false) .. '</IsOnlyDamagedByPlayer>')

    -- Position and rotation
    table.insert(lines, '\t\t<PositionRotation>')
    table.insert(lines, '\t\t\t<X>' .. string.format("%.6f", placement.position.x) .. '</X>')
    table.insert(lines, '\t\t\t<Y>' .. string.format("%.6f", placement.position.y) .. '</Y>')
    table.insert(lines, '\t\t\t<Z>' .. string.format("%.6f", placement.position.z) .. '</Z>')
    table.insert(lines, '\t\t\t<Pitch>' .. string.format("%.6f", placement.rotation.x) .. '</Pitch>')
    table.insert(lines, '\t\t\t<Roll>' .. string.format("%.6f", placement.rotation.y) .. '</Roll>')
    table.insert(lines, '\t\t\t<Yaw>' .. string.format("%.6f", placement.rotation.z) .. '</Yaw>')
    table.insert(lines, '\t\t</PositionRotation>')

    table.insert(lines, '\t\t<Attachment isAttached="false" />')
    table.insert(lines, '\t</Placement>')

    return table.concat(lines, '\n')
end

function XMLParser.GenerateVehiclePropertiesXML(props)
    local lines = {}
    table.insert(lines, '\t\t<VehicleProperties>')

    -- Colors
    table.insert(lines, '\t\t\t<Colours>')
    table.insert(lines, '\t\t\t\t<Primary>' .. (props.primaryColor or 0) .. '</Primary>')
    table.insert(lines, '\t\t\t\t<Secondary>' .. (props.secondaryColor or 0) .. '</Secondary>')
    table.insert(lines, '\t\t\t\t<Pearl>' .. (props.pearlColor or 0) .. '</Pearl>')
    table.insert(lines, '\t\t\t\t<Rim>' .. (props.rimColor or 0) .. '</Rim>')
    table.insert(lines, '\t\t\t\t<Mod1_a>' .. (props.mod1a or 0) .. '</Mod1_a>')
    table.insert(lines, '\t\t\t\t<Mod1_b>' .. (props.mod1b or -1) .. '</Mod1_b>')
    table.insert(lines, '\t\t\t\t<Mod1_c>' .. (props.mod1c or -1) .. '</Mod1_c>')
    table.insert(lines, '\t\t\t\t<Mod2_a>' .. (props.mod2a or 0) .. '</Mod2_a>')
    table.insert(lines, '\t\t\t\t<Mod2_b>' .. (props.mod2b or -1) .. '</Mod2_b>')
    table.insert(lines, '\t\t\t\t<IsPrimaryColourCustom>' .. tostring(props.isPrimaryCustom or false) .. '</IsPrimaryColourCustom>')
    table.insert(lines, '\t\t\t\t<IsSecondaryColourCustom>' .. tostring(props.isSecondaryCustom or false) .. '</IsSecondaryColourCustom>')
    table.insert(lines, '\t\t\t\t<tyreSmoke_R>' .. (props.tyreSmokeR or 255) .. '</tyreSmoke_R>')
    table.insert(lines, '\t\t\t\t<tyreSmoke_G>' .. (props.tyreSmokeG or 255) .. '</tyreSmoke_G>')
    table.insert(lines, '\t\t\t\t<tyreSmoke_B>' .. (props.tyreSmokeB or 255) .. '</tyreSmoke_B>')
    table.insert(lines, '\t\t\t\t<LrInterior>' .. (props.interiorColor or 0) .. '</LrInterior>')
    table.insert(lines, '\t\t\t\t<LrDashboard>' .. (props.dashboardColor or 0) .. '</LrDashboard>')
    table.insert(lines, '\t\t\t\t<LrXenonHeadlights>' .. (props.xenonColor or 255) .. '</LrXenonHeadlights>')
    table.insert(lines, '\t\t\t</Colours>')

    table.insert(lines, '\t\t\t<Livery>' .. (props.livery or -1) .. '</Livery>')
    table.insert(lines, '\t\t\t<NumberPlateText>' .. XMLParser.EscapeAttribute(props.plateText or "") .. '</NumberPlateText>')
    table.insert(lines, '\t\t\t<NumberPlateIndex>' .. (props.plateIndex or 0) .. '</NumberPlateIndex>')
    table.insert(lines, '\t\t\t<WheelType>' .. (props.wheelType or 0) .. '</WheelType>')
    table.insert(lines, '\t\t\t<WheelsInvisible>' .. tostring(props.wheelsInvisible or false) .. '</WheelsInvisible>')
    table.insert(lines, '\t\t\t<EngineSoundName>' .. XMLParser.EscapeAttribute(props.engineSound or "") .. '</EngineSoundName>')
    table.insert(lines, '\t\t\t<WindowTint>' .. (props.windowTint or 0) .. '</WindowTint>')
    table.insert(lines, '\t\t\t<BulletProofTyres>' .. tostring(props.bulletProofTyres or false) .. '</BulletProofTyres>')
    table.insert(lines, '\t\t\t<DirtLevel>' .. (props.dirtLevel or 0) .. '</DirtLevel>')
    table.insert(lines, '\t\t\t<PaintFade>' .. string.format("%.6f", props.paintFade or 0) .. '</PaintFade>')
    table.insert(lines, '\t\t\t<RoofState>' .. (props.roofState or 0) .. '</RoofState>')
    table.insert(lines, '\t\t\t<SirenActive>' .. tostring(props.sirenActive or false) .. '</SirenActive>')
    table.insert(lines, '\t\t\t<EngineOn>' .. tostring(props.engineOn or false) .. '</EngineOn>')
    table.insert(lines, '\t\t\t<EngineHealth>' .. (props.engineHealth or 1000) .. '</EngineHealth>')
    table.insert(lines, '\t\t\t<LightsOn>' .. tostring(props.lightsOn or false) .. '</LightsOn>')
    table.insert(lines, '\t\t\t<IsRadioLoud>' .. (props.isRadioLoud or 0) .. '</IsRadioLoud>')
    table.insert(lines, '\t\t\t<LockStatus>' .. (props.lockStatus or 1) .. '</LockStatus>')

    -- Neons
    table.insert(lines, '\t\t\t<Neons>')
    table.insert(lines, '\t\t\t\t<Left>' .. tostring(props.neonLeft or false) .. '</Left>')
    table.insert(lines, '\t\t\t\t<Right>' .. tostring(props.neonRight or false) .. '</Right>')
    table.insert(lines, '\t\t\t\t<Front>' .. tostring(props.neonFront or false) .. '</Front>')
    table.insert(lines, '\t\t\t\t<Back>' .. tostring(props.neonBack or false) .. '</Back>')
    table.insert(lines, '\t\t\t\t<R>' .. (props.neonR or 255) .. '</R>')
    table.insert(lines, '\t\t\t\t<G>' .. (props.neonG or 0) .. '</G>')
    table.insert(lines, '\t\t\t\t<B>' .. (props.neonB or 255) .. '</B>')
    table.insert(lines, '\t\t\t</Neons>')

    -- Doors Open
    table.insert(lines, '\t\t\t<DoorsOpen>')
    table.insert(lines, '\t\t\t\t<BackLeftDoor>false</BackLeftDoor>')
    table.insert(lines, '\t\t\t\t<BackRightDoor>false</BackRightDoor>')
    table.insert(lines, '\t\t\t\t<FrontLeftDoor>false</FrontLeftDoor>')
    table.insert(lines, '\t\t\t\t<FrontRightDoor>false</FrontRightDoor>')
    table.insert(lines, '\t\t\t\t<Hood>false</Hood>')
    table.insert(lines, '\t\t\t\t<Trunk>false</Trunk>')
    table.insert(lines, '\t\t\t\t<Trunk2>false</Trunk2>')
    table.insert(lines, '\t\t\t</DoorsOpen>')

    -- Doors Broken
    table.insert(lines, '\t\t\t<DoorsBroken>')
    table.insert(lines, '\t\t\t\t<BackLeftDoor>false</BackLeftDoor>')
    table.insert(lines, '\t\t\t\t<BackRightDoor>false</BackRightDoor>')
    table.insert(lines, '\t\t\t\t<FrontLeftDoor>false</FrontLeftDoor>')
    table.insert(lines, '\t\t\t\t<FrontRightDoor>false</FrontRightDoor>')
    table.insert(lines, '\t\t\t\t<Hood>false</Hood>')
    table.insert(lines, '\t\t\t\t<Trunk>false</Trunk>')
    table.insert(lines, '\t\t\t\t<Trunk2>false</Trunk2>')
    table.insert(lines, '\t\t\t</DoorsBroken>')

    -- Tyres Bursted
    table.insert(lines, '\t\t\t<TyresBursted>')
    table.insert(lines, '\t\t\t\t<FrontLeft>false</FrontLeft>')
    table.insert(lines, '\t\t\t\t<FrontRight>false</FrontRight>')
    table.insert(lines, '\t\t\t\t<_2>false</_2>')
    table.insert(lines, '\t\t\t\t<_3>false</_3>')
    table.insert(lines, '\t\t\t\t<BackLeft>false</BackLeft>')
    table.insert(lines, '\t\t\t\t<BackRight>false</BackRight>')
    table.insert(lines, '\t\t\t\t<_6>false</_6>')
    table.insert(lines, '\t\t\t\t<_7>false</_7>')
    table.insert(lines, '\t\t\t\t<_8>false</_8>')
    table.insert(lines, '\t\t\t</TyresBursted>')

    -- Mod Extras
    table.insert(lines, '\t\t\t<ModExtras>')
    for i = 1, 12 do
        if i ~= 9 and i ~= 10 then
            local value = props.extras and props.extras[i] or true
            table.insert(lines, '\t\t\t\t<_' .. i .. '>' .. tostring(value) .. '</_' .. i .. '>')
        end
    end
    table.insert(lines, '\t\t\t</ModExtras>')

    -- Mods
    table.insert(lines, '\t\t\t<Mods>')
    for i = 0, 48 do
        if i >= 17 and i <= 22 then
            -- Toggle mods (bool)
            local value = props.mods and props.mods[i] or false
            table.insert(lines, '\t\t\t\t<_' .. i .. '>' .. tostring(value) .. '</_' .. i .. '>')
        else
            -- Regular mods (value,variation)
            local modValue = props.mods and props.mods[i] or -1
            local modVariation = props.modVariations and props.modVariations[i] or 0
            table.insert(lines, '\t\t\t\t<_' .. i .. '>' .. modValue .. ',' .. modVariation .. '</_' .. i .. '>')
        end
    end
    table.insert(lines, '\t\t\t</Mods>')

    table.insert(lines, '\t\t</VehicleProperties>')
    return table.concat(lines, '\n')
end

function XMLParser.GeneratePedPropertiesXML(props)
    local lines = {}
    table.insert(lines, '\t\t<PedProperties>')
    table.insert(lines, '\t\t\t<CanRagdoll>' .. tostring(props.canRagdoll ~= false) .. '</CanRagdoll>')
    table.insert(lines, '\t\t\t<Armour>' .. (props.armour or 0) .. '</Armour>')
    table.insert(lines, '\t\t\t<CurrentWeapon>' .. (props.currentWeapon or "0xA2719263") .. '</CurrentWeapon>')
    table.insert(lines, '\t\t</PedProperties>')
    return table.concat(lines, '\n')
end

-- ============================================================================
-- Menyoo Spooner XML Format Parsing (Loading)
-- ============================================================================

-- Helper to get text content between tags
function XMLParser.GetTagContent(xmlString, tagName)
    local pattern = "<" .. tagName .. "[^>]*>([^<]*)</" .. tagName .. ">"
    return xmlString:match(pattern)
end

-- Helper to parse a boolean string
function XMLParser.ParseBool(str)
    if str == nil then return false end
    return str:lower() == "true"
end

-- Helper to parse a number (supports hex format 0x...)
function XMLParser.ParseNumber(str)
    if str == nil then return 0 end
    str = str:match("^%s*(.-)%s*$") -- trim
    if str:sub(1, 2) == "0x" or str:sub(1, 2) == "0X" then
        -- Remove 0x prefix and parse as hex
        local hexStr = str:sub(3)
        return tonumber(hexStr, 16) or 0
    end
    return tonumber(str) or 0
end

-- Parse a single Placement block
function XMLParser.ParsePlacement(placementXml)
    local placement = {}

    placement.modelHash = XMLParser.GetTagContent(placementXml, "ModelHash") or "0"
    placement.type = XMLParser.ParseNumber(XMLParser.GetTagContent(placementXml, "Type"))
    placement.dynamic = XMLParser.ParseBool(XMLParser.GetTagContent(placementXml, "Dynamic"))
    placement.frozen = XMLParser.ParseBool(XMLParser.GetTagContent(placementXml, "FrozenPos"))
    placement.hashName = XMLParser.GetTagContent(placementXml, "HashName") or ""
    placement.opacity = XMLParser.ParseNumber(XMLParser.GetTagContent(placementXml, "OpacityLevel"))
    placement.health = XMLParser.ParseNumber(XMLParser.GetTagContent(placementXml, "Health"))
    placement.maxHealth = XMLParser.ParseNumber(XMLParser.GetTagContent(placementXml, "MaxHealth"))
    placement.isInvincible = XMLParser.ParseBool(XMLParser.GetTagContent(placementXml, "IsInvincible"))
    placement.hasGravity = XMLParser.ParseBool(XMLParser.GetTagContent(placementXml, "HasGravity"))

    -- Parse PositionRotation
    local posRotBlock = placementXml:match("<PositionRotation>(.-)</PositionRotation>")
    if posRotBlock then
        placement.position = {
            x = tonumber(XMLParser.GetTagContent(posRotBlock, "X")) or 0,
            y = tonumber(XMLParser.GetTagContent(posRotBlock, "Y")) or 0,
            z = tonumber(XMLParser.GetTagContent(posRotBlock, "Z")) or 0
        }
        placement.rotation = {
            x = tonumber(XMLParser.GetTagContent(posRotBlock, "Pitch")) or 0,
            y = tonumber(XMLParser.GetTagContent(posRotBlock, "Roll")) or 0,
            z = tonumber(XMLParser.GetTagContent(posRotBlock, "Yaw")) or 0
        }
    else
        placement.position = {x = 0, y = 0, z = 0}
        placement.rotation = {x = 0, y = 0, z = 0}
    end

    -- Parse VehicleProperties if present
    local vehPropsBlock = placementXml:match("<VehicleProperties>(.-)</VehicleProperties>")
    if vehPropsBlock then
        placement.vehicleProperties = XMLParser.ParseVehicleProperties(vehPropsBlock)
    end

    -- Parse PedProperties if present
    local pedPropsBlock = placementXml:match("<PedProperties>(.-)</PedProperties>")
    if pedPropsBlock then
        placement.pedProperties = XMLParser.ParsePedProperties(pedPropsBlock)
    end

    return placement
end

-- Parse VehicleProperties block
function XMLParser.ParseVehicleProperties(vehXml)
    local props = {}

    -- Parse Colours block
    local coloursBlock = vehXml:match("<Colours>(.-)</Colours>")
    if coloursBlock then
        props.primaryColor = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Primary"))
        props.secondaryColor = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Secondary"))
        props.pearlColor = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Pearl"))
        props.rimColor = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Rim"))
        props.mod1a = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Mod1_a"))
        props.mod1b = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Mod1_b"))
        props.mod1c = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Mod1_c"))
        props.mod2a = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Mod2_a"))
        props.mod2b = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "Mod2_b"))
        props.tyreSmokeR = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "tyreSmoke_R"))
        props.tyreSmokeG = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "tyreSmoke_G"))
        props.tyreSmokeB = XMLParser.ParseNumber(XMLParser.GetTagContent(coloursBlock, "tyreSmoke_B"))
    end

    props.livery = XMLParser.ParseNumber(XMLParser.GetTagContent(vehXml, "Livery"))
    props.plateText = XMLParser.GetTagContent(vehXml, "NumberPlateText") or ""
    props.plateIndex = XMLParser.ParseNumber(XMLParser.GetTagContent(vehXml, "NumberPlateIndex"))
    props.wheelType = XMLParser.ParseNumber(XMLParser.GetTagContent(vehXml, "WheelType"))
    props.windowTint = XMLParser.ParseNumber(XMLParser.GetTagContent(vehXml, "WindowTint"))
    props.bulletProofTyres = XMLParser.ParseBool(XMLParser.GetTagContent(vehXml, "BulletProofTyres"))
    props.engineHealth = XMLParser.ParseNumber(XMLParser.GetTagContent(vehXml, "EngineHealth"))

    -- Parse Neons
    local neonsBlock = vehXml:match("<Neons>(.-)</Neons>")
    if neonsBlock then
        props.neonLeft = XMLParser.ParseBool(XMLParser.GetTagContent(neonsBlock, "Left"))
        props.neonRight = XMLParser.ParseBool(XMLParser.GetTagContent(neonsBlock, "Right"))
        props.neonFront = XMLParser.ParseBool(XMLParser.GetTagContent(neonsBlock, "Front"))
        props.neonBack = XMLParser.ParseBool(XMLParser.GetTagContent(neonsBlock, "Back"))
        props.neonR = XMLParser.ParseNumber(XMLParser.GetTagContent(neonsBlock, "R"))
        props.neonG = XMLParser.ParseNumber(XMLParser.GetTagContent(neonsBlock, "G"))
        props.neonB = XMLParser.ParseNumber(XMLParser.GetTagContent(neonsBlock, "B"))
    end

    -- Parse Mods
    local modsBlock = vehXml:match("<Mods>(.-)</Mods>")
    if modsBlock then
        props.mods = {}
        props.modVariations = {}
        for i = 0, 48 do
            local modValue = XMLParser.GetTagContent(modsBlock, "_" .. i)
            if modValue then
                if i >= 17 and i <= 22 then
                    -- Toggle mods (bool)
                    props.mods[i] = XMLParser.ParseBool(modValue)
                else
                    -- Regular mods (value,variation)
                    local val, var = modValue:match("([^,]+),([^,]+)")
                    props.mods[i] = tonumber(val) or -1
                    props.modVariations[i] = tonumber(var) or 0
                end
            end
        end
    end

    return props
end

-- Parse PedProperties block
function XMLParser.ParsePedProperties(pedXml)
    local props = {}
    props.canRagdoll = XMLParser.ParseBool(XMLParser.GetTagContent(pedXml, "CanRagdoll"))
    props.armour = XMLParser.ParseNumber(XMLParser.GetTagContent(pedXml, "Armour"))
    props.currentWeapon = XMLParser.GetTagContent(pedXml, "CurrentWeapon") or "0xA2719263"
    return props
end

-- Parse full SpoonerPlacements XML file
function XMLParser.ParseSpoonerXML(xmlString)
    local result = {
        placements = {},
        referenceCoords = nil
    }

    -- Parse reference coordinates
    local refCoordsBlock = xmlString:match("<ReferenceCoords>(.-)</ReferenceCoords>")
    if refCoordsBlock then
        result.referenceCoords = {
            x = tonumber(XMLParser.GetTagContent(refCoordsBlock, "X")) or 0,
            y = tonumber(XMLParser.GetTagContent(refCoordsBlock, "Y")) or 0,
            z = tonumber(XMLParser.GetTagContent(refCoordsBlock, "Z")) or 0
        }
    end

    -- Parse all Placement blocks
    for placementXml in xmlString:gmatch("<Placement>(.-)</Placement>") do
        local placement = XMLParser.ParsePlacement(placementXml)
        table.insert(result.placements, placement)
    end

    return result
end

-- ============================================================================
-- Inlined Library: EntityLists
-- ============================================================================
local EntityLists = {}

function EntityLists.New(XMLParser, Logger)
    local self = {
        Props = {},      -- { [categoryName] = { {name, hash}, ... } }
        Vehicles = {},   -- { [categoryName] = { {name}, ... } }
        Peds = {},       -- { [categoryName] = { {name, caption}, ... } }
        -- Filter states for each tab
        PropFilter = "",
        VehicleFilter = "",
        PedFilter = "",
        -- Cache for model hash to name lookups
        NameCache = {}   -- { [modelHash] = displayName }
    }

    function self.LoadPropList(filePath)
        if not FileMgr.DoesFileExist(filePath) then
            Logger.Warn("PropList.xml not found at: " .. filePath)
            return false
        end

        local content = FileMgr.ReadFileContent(filePath)
        if not content or content == "" then
            Logger.Error("Failed to read PropList.xml")
            return false
        end

        self.Props = {}
        local parsed = XMLParser.Parse(content)

        for _, node in ipairs(parsed) do
            if node.tag == "PropList" then
                for _, categoryNode in ipairs(node.children or {}) do
                    if categoryNode.tag == "Category" then
                        local categoryName = categoryNode.attributes.name or "Unknown"
                        self.Props[categoryName] = {}

                        for _, propNode in ipairs(categoryNode.children or {}) do
                            if propNode.tag == "Prop" then
                                table.insert(self.Props[categoryName], {
                                    name = propNode.attributes.name or "",
                                    hash = propNode.attributes.hash or ""
                                })
                            end
                        end
                    end
                end
            end
        end

        local categoryCount = 0
        local propCount = 0
        for _, props in pairs(self.Props) do
            categoryCount = categoryCount + 1
            propCount = propCount + #props
        end

        Logger.Info("Loaded PropList: " .. categoryCount .. " categories, " .. propCount .. " props")
        return true
    end

    function self.LoadVehicleList(filePath)
        if not FileMgr.DoesFileExist(filePath) then
            Logger.Warn("VehicleList.xml not found at: " .. filePath)
            return false
        end

        local content = FileMgr.ReadFileContent(filePath)
        if not content or content == "" then
            Logger.Error("Failed to read VehicleList.xml")
            return false
        end

        self.Vehicles = {}
        local parsed = XMLParser.Parse(content)

        for _, node in ipairs(parsed) do
            if node.tag == "VehicleList" then
                for _, categoryNode in ipairs(node.children or {}) do
                    if categoryNode.tag == "Category" then
                        local categoryName = categoryNode.attributes.name or "Unknown"
                        self.Vehicles[categoryName] = {}

                        for _, vehicleNode in ipairs(categoryNode.children or {}) do
                            if vehicleNode.tag == "Vehicle" then
                                table.insert(self.Vehicles[categoryName], {
                                    name = vehicleNode.attributes.name or ""
                                })
                            end
                        end
                    end
                end
            end
        end

        local categoryCount = 0
        local vehicleCount = 0
        for _, vehicles in pairs(self.Vehicles) do
            categoryCount = categoryCount + 1
            vehicleCount = vehicleCount + #vehicles
        end

        Logger.Info("Loaded VehicleList: " .. categoryCount .. " categories, " .. vehicleCount .. " vehicles")
        return true
    end

    function self.LoadPedList(filePath)
        if not FileMgr.DoesFileExist(filePath) then
            Logger.Warn("PedList.xml not found at: " .. filePath)
            return false
        end

        local content = FileMgr.ReadFileContent(filePath)
        if not content or content == "" then
            Logger.Error("Failed to read PedList.xml")
            return false
        end

        self.Peds = {}
        local parsed = XMLParser.Parse(content)

        for _, node in ipairs(parsed) do
            if node.tag == "PedList" then
                for _, categoryNode in ipairs(node.children or {}) do
                    if categoryNode.tag == "Category" then
                        local categoryName = categoryNode.attributes.name or "Unknown"
                        self.Peds[categoryName] = {}

                        for _, pedNode in ipairs(categoryNode.children or {}) do
                            if pedNode.tag == "Ped" then
                                table.insert(self.Peds[categoryName], {
                                    name = pedNode.attributes.name or "",
                                    caption = pedNode.attributes.caption or ""
                                })
                            end
                        end
                    end
                end
            end
        end

        local categoryCount = 0
        local pedCount = 0
        for _, peds in pairs(self.Peds) do
            categoryCount = categoryCount + 1
            pedCount = pedCount + #peds
        end

        Logger.Info("Loaded PedList: " .. categoryCount .. " categories, " .. pedCount .. " peds")
        return true
    end

    function self.BuildNameCache()
        self.NameCache = {}

        -- Cache prop names by hash (use sJoaat for signed hash to match ENTITY.GET_ENTITY_MODEL)
        for _, props in pairs(self.Props) do
            for _, prop in ipairs(props) do
                local hash = Utils.sJoaat(prop.hash)
                self.NameCache[hash] = prop.name
            end
        end

        -- Cache ped names by hash (use sJoaat for signed hash to match ENTITY.GET_ENTITY_MODEL)
        for _, peds in pairs(self.Peds) do
            for _, ped in ipairs(peds) do
                local hash = Utils.sJoaat(ped.name)
                local displayName = (ped.caption and ped.caption ~= "") and ped.caption or ped.name
                self.NameCache[hash] = displayName
            end
        end

        Logger.Info("Built name cache with " .. tostring(#self.NameCache) .. " entries")
    end

    function self.LoadAll(propListPath, vehicleListPath, pedListPath)
        self.LoadPropList(propListPath)
        self.LoadVehicleList(vehicleListPath)
        self.LoadPedList(pedListPath)
        self.BuildNameCache()
    end

    return self
end

-- ============================================================================
-- Inlined Library: NetworkUtils
-- ============================================================================
local eMigrationType = {
    MIGRATE_PROXIMITY = 0x0,
    MIGRATE_OUT_OF_SCOPE = 0x1,
    MIGRATE_SCRIPT = 0x2,
    MIGRATE_FORCED = 0x3,
    MIGRATE_REASSIGNMENT = 0x4,
    MIGRATE_FROZEN_PED = 0x5,
    NUM_MIGRATION_TYPES = 0x6,
}

local NetworkUtils = {}

function NetworkUtils.New(CONSTANTS)
    local self = {}

    function self.IsEntityNetworked(entity)
        return NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(entity)
    end

    function self.GetNetworkIdOf(entity)
        return NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    end

    -- Credits GuseXenvious (Probably sainan too)
    function self.set_can_migrate(entity, canMigrate)
        local Pointer = GTA.HandleToPointer(entity):GetAddress()
        if Pointer ~= 0 then
            Pointer = Memory.ReadLong(Pointer+0xD0)
            if Pointer ~= 0 then
                local Bits = Memory.ReadByte(Pointer+0x4E)
                if not canMigrate and Bits | 1 == 0 then
                    Bits = Bits + 1
                    Memory.WriteByte(Pointer+0x4E, Bits)
                elseif Bits | 1 == 1 then
                    Bits = Bits - 1
                    Memory.WriteByte(Pointer+0x4E, Bits)
                end
            end
        end
    end

    function self.SetEntityAsNetworked(entity, timeout)
        local time = Time.GetEpocheMs() + (timeout or CONSTANTS.NETWORK_TIMEOUT)
        while time > Time.GetEpocheMs() and not self.IsEntityNetworked(entity) do
            NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(entity)
            Script.Yield(0)
        end
        return self.GetNetworkIdOf(entity)
    end

    function self.ConstantizeNetworkId(entity)
        local netId = self.SetEntityAsNetworked(entity, CONSTANTS.NETWORK_TIMEOUT_SHORT)
        NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netId, true)
        NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netId, PLAYER.PLAYER_ID(), true)
        return netId
    end

    -- Save ped task state before mission entity conversion
    function self.SavePedTaskState(ped)
        if not ENTITY.IS_ENTITY_A_PED(ped) then
            return nil
        end

        local state = {
            isWandering = TASK.GET_IS_TASK_ACTIVE(ped, 224),  -- TASK_WANDER
            isWalking = TASK.IS_PED_WALKING(ped),
            isRunning = TASK.IS_PED_RUNNING(ped),
            isSprinting = TASK.IS_PED_SPRINTING(ped),
            isStill = TASK.IS_PED_STILL(ped),
        }

        return state
    end

    -- Restore ped task after mission entity conversion
    function self.RestorePedTaskState(ped, state)
        if not state or not ENTITY.IS_ENTITY_A_PED(ped) then
            return
        end

        -- If ped was moving around, give them wander task
        if state.isWandering or state.isWalking or state.isRunning or state.isSprinting then
            TASK.TASK_WANDER_STANDARD(ped, 10.0, 10)
        end
        -- If they were standing still, mission entity default behavior is fine
    end

    function self.MakeEntityNetworked(entity)
        -- Skip network functions in singleplayer
        local netId = 0
        if NETWORK.NETWORK_IS_SESSION_STARTED() then
            netId = self.ConstantizeNetworkId(entity)
            -- NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, false) #Shitty native
            self.set_can_migrate(entity, false)
        end

        if not DECORATOR.DECOR_EXIST_ON(entity, "PV_Slot") then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, true)
        end

        return netId
    end

    -- Lighter version that just maintains network control without resetting ped tasks
    function self.MaintainNetworkControl(entity)
        -- Skip network functions in singleplayer
        if not NETWORK.NETWORK_IS_SESSION_STARTED() then
            return 0
        end

        if not NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(entity) then
            return self.MakeEntityNetworked(entity)
        end

        local netId = self.GetNetworkIdOf(entity)
        if not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netId) then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netId)
        end
        return netId
    end

    function self.MaintainNetworkControlV2(entity)
        -- Skip network functions in singleplayer
        if not NETWORK.NETWORK_IS_SESSION_STARTED() then
            return 0
        end

        local netId = self.GetNetworkIdOf(entity)
        local cPhysical = GTA.HandleToPointer(entity)
        if not cPhysical or not cPhysical.NetObject then return end
        local playerId = GTA.GetLocalPlayerId()
        if not playerId then return end
        local cNetGamePlayer = Players.GetById(playerId)
        if not cNetGamePlayer then return end
        NetworkObjectMgr.ChangeOwner(cPhysical.NetObject, cNetGamePlayer, eMigrationType.MIGRATE_FORCED)
        return netId
    end

    return self
end

-- ============================================================================
-- Inlined Library: Keybinds
-- ============================================================================
local KeybindsLib = {}

function KeybindsLib.New(PAD)
    local Keybinds = {}

    function Keybinds.GetAsString(key)
        return PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, key, true)
    end

    function Keybinds.CreateKeybind(key, func)
        return {
            key = key,
            string = Keybinds.GetAsString(key),
            IsPressed = function()
                return func(key)
            end
        }
    end

    function Keybinds.IsPressed(key)
        return PAD.IS_DISABLED_CONTROL_PRESSED(0, key)
    end

    function Keybinds.IsJustPressed(key)
        return PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, key)
    end

    function Keybinds.GetControlNormal(key)
        return PAD.GET_DISABLED_CONTROL_NORMAL(0, key)
    end

    -- Controls that should remain enabled while in Spooner mode (passthrough to game)
    -- These allow game features like pause menu and expanded map to work
    Keybinds.PassthroughControls = {
        199,  -- Pause Menu (P)
        200,  -- Pause Menu alternate (Escape)
        20,   -- Big Map (Z key)
    }

    function Keybinds.EnablePassthroughControls()
        for _, control in ipairs(Keybinds.PassthroughControls) do
            PAD.ENABLE_CONTROL_ACTION(0, control, true)
        end
    end

    function Keybinds.SetupDefaultBinds()
        return {
            Grab = Keybinds.CreateKeybind(24, Keybinds.IsPressed),
            AddOrRemoveFromList = Keybinds.CreateKeybind(73, Keybinds.IsJustPressed),
            MoveFaster = Keybinds.CreateKeybind(21, Keybinds.IsPressed),
            RotateLeft = Keybinds.CreateKeybind(44, Keybinds.IsPressed),
            RotateRight = Keybinds.CreateKeybind(38, Keybinds.IsPressed),
            PitchUp = Keybinds.CreateKeybind(172, Keybinds.IsPressed),    -- Arrow Up
            PitchDown = Keybinds.CreateKeybind(173, Keybinds.IsPressed),  -- Arrow Down
            RollLeft = Keybinds.CreateKeybind(174, Keybinds.IsPressed),   -- Arrow Left
            RollRight = Keybinds.CreateKeybind(175, Keybinds.IsPressed),  -- Arrow Right
            PushEntity = Keybinds.CreateKeybind(14, Keybinds.IsPressed),
            PullEntity = Keybinds.CreateKeybind(15, Keybinds.IsPressed),
            MoveUp = Keybinds.CreateKeybind(22, Keybinds.GetControlNormal),
            MoveDown = Keybinds.CreateKeybind(36, Keybinds.GetControlNormal),
            MoveForward = Keybinds.CreateKeybind(32, Keybinds.GetControlNormal),
            MoveBackward = Keybinds.CreateKeybind(33, Keybinds.GetControlNormal),
            MoveLeft = Keybinds.CreateKeybind(34, Keybinds.GetControlNormal),
            MoveRight = Keybinds.CreateKeybind(35, Keybinds.GetControlNormal),
            ConfirmSpawn = Keybinds.CreateKeybind(201, Keybinds.IsJustPressed),  -- Enter key
            CancelSpawn = Keybinds.CreateKeybind(202, Keybinds.IsJustPressed),   -- Backspace key
            SelectForEdit = Keybinds.CreateKeybind(25, Keybinds.IsJustPressed),  -- Right mouse button (select entity for editing)
        }
    end

    return Keybinds
end

-- ============================================================================
-- Inlined Library: CameraUtils
-- ============================================================================
local CameraUtils = {}

function CameraUtils.New(CONSTANTS)
    local self = {}

    function self.GetBasis(cam)
        local rot = CAM.GET_CAM_ROT(cam, 2)
        local radZ = math.rad(rot.z)
        local radX = math.rad(rot.x)

        local fwd = {
            x = -math.sin(radZ) * math.cos(radX),
            y = math.cos(radZ) * math.cos(radX),
            z = math.sin(radX)
        }

        local right = {
            x = math.cos(radZ),
            y = math.sin(radZ),
            z = 0.0
        }

        local up = {
            x = right.y * fwd.z - right.z * fwd.y,
            y = right.z * fwd.x - right.x * fwd.z,
            z = right.x * fwd.y - right.y * fwd.x
        }

        return fwd, right, up, rot
    end

    function self.ClampPitch(pitch)
        if pitch > CONSTANTS.PITCH_CLAMP_MAX then
            return CONSTANTS.PITCH_CLAMP_MAX
        elseif pitch < CONSTANTS.PITCH_CLAMP_MIN then
            return CONSTANTS.PITCH_CLAMP_MIN
        end
        return pitch
    end

    return self
end

-- ============================================================================
-- Inlined Library: MemoryUtils
-- ============================================================================
local MemoryUtils = {}

function MemoryUtils.New()
    local self = {}
    self.cache = {}  -- { [key] = ptr }

    -- Allocate memory with a key, returns cached ptr if already exists
    function self.Alloc(key, size)
        if self.cache[key] then
            return self.cache[key]
        end
        local ptr = Memory.Alloc(size)
        self.cache[key] = ptr
        return ptr
    end

    -- Allocate int with a key, returns cached ptr if already exists
    function self.AllocInt(key)
        if self.cache[key] then
            return self.cache[key]
        end
        local ptr = Memory.AllocInt()
        self.cache[key] = ptr
        return ptr
    end

    -- Alocate V3 with a key, returns cached ptr if already exists
    function self.AllocV3(key)
        if self.cache[key] then
            return self.cache[key]
        end
        local ptr = Memory.Alloc(24)
        self.cache[key] = ptr
        return ptr
    end

    -- Alocate float with a key, returns cached ptr if already exists
    function self.AllocFloat(key)
        return self.AllocV3(key)
    end

    -- Read V3 with float value
    function self.ReadV3(ptr)
        return {x=Memory.ReadFloat(ptr), y=Memory.ReadFloat(ptr + 8), z=Memory.ReadFloat(ptr + 16)}
    end

    -- Get a cached allocation by key
    function self.Get(key)
        return self.cache[key]
    end

    -- Free a specific allocation by key
    function self.Free(key)
        if self.cache[key] then
            Memory.Free(self.cache[key])
            self.cache[key] = nil
            return true
        end
        return false
    end

    -- Free all cached allocations (call on unload)
    function self.FreeAll()
        for key, ptr in pairs(self.cache) do
            Memory.Free(ptr)
        end
        self.cache = {}
    end

    return self
end

-- ============================================================================
-- Inlined Library: Raycast
-- ============================================================================
local RaycastLib = {}

function RaycastLib.New(name, CONSTANTS, CustomLogger, MemoryUtils)
    local Raycast = {}

    -- Active raycast data
    Raycast.data = nil
    Raycast.frameCounter = 0
    Raycast.currentTarget = nil
    Raycast.currentRayHitCoords = {x=0,y=0,z=0}

    -- Allocate persistent memory for raycast results using MemoryUtils
    local hit = MemoryUtils.AllocInt(name .. "raycast_hit")
    local endCoords = MemoryUtils.Alloc(name .. "raycast_endCoords", 24)
    local surfaceNormal = MemoryUtils.Alloc(name .. "raycast_surfaceNormal", 24)
    local entityHit = MemoryUtils.AllocInt(name .. "raycast_entityHit")

    function Raycast.StartProbe(startX, startY, startZ, endX, endY, endZ, flags, ignoreEntity)
        local handle = SHAPETEST.START_SHAPE_TEST_LOS_PROBE(
            startX, startY, startZ,
            endX, endY, endZ,
            flags,
            ignoreEntity or 0,
            7
        )

        Raycast.data = {
            handle = handle,
        }

        Raycast.currentTarget = nil

        return handle
    end

    function Raycast.CheckResult()
        local rayHitCoords = {x=0, y=0, z=0}

        if not Raycast.data then
            return false, nil, rayHitCoords
        end

        local resultReady = SHAPETEST.GET_SHAPE_TEST_RESULT(
            Raycast.data.handle,
            hit,
            endCoords,
            surfaceNormal,
            entityHit
        )

        if resultReady == 2 then
            local hitVal = Memory.ReadInt(hit)
            local entityHitVal = Memory.ReadInt(entityHit)
            rayHitCoords = MemoryUtils.ReadV3(endCoords)

            Raycast.data = nil

            if hitVal == 1 and entityHitVal ~= 0 then
                return true, entityHitVal, rayHitCoords
            else
                return true, nil, rayHitCoords
            end
        end

        return false, nil, rayHitCoords
    end

    function Raycast.PerformCheck(startX, startY, startZ, endX, endY, endZ, flags, ignoreEntity)
        Raycast.frameCounter = Raycast.frameCounter + 1
        local isTargeted = not not Raycast.currentTarget
        local targetedEntity = Raycast.currentTarget
        local rayHitCoords = Raycast.currentRayHitCoords

         -- Check existing raycast result
         if Raycast.data then
            local ready, entity, hitCoords = Raycast.CheckResult()
            -- Logger.LogInfo("Ready: " .. tostring(ready) .. ", entity: " .. tostring(entity))
            rayHitCoords = hitCoords
            Raycast.currentRayHitCoords = hitCoords
            if ready then
                if entity then
                    isTargeted = true
                    targetedEntity = entity
                    Raycast.currentTarget = entity
                else
                    Raycast.currentTarget = nil
                end
            elseif Raycast.frameCounter > 20 then
                Raycast.data = nil
            end
        end

        -- Start new raycast if not grabbing
        if not Raycast.data then
            if Raycast.frameCounter >= CONSTANTS.RAYCAST_INTERVAL then
                Raycast.frameCounter = 0

                Raycast.StartProbe(
                    startX, startY, startZ,
                    endX, endY, endZ,
                    flags,
                    ignoreEntity
                )
            end
        end

        return isTargeted, targetedEntity, rayHitCoords
    end

    function Raycast.PerformCheckForFreecam(freecam)
        local camCoord = CAM.GET_CAM_COORD(freecam)
        local camRot = CAM.GET_CAM_ROT(freecam, 2)

        local radZ = math.rad(camRot.z)
        local radX = math.rad(camRot.x)
        local forwardX = -math.sin(radZ) * math.cos(radX)
        local forwardY = math.cos(radZ) * math.cos(radX)
        local forwardZ = math.sin(radX)

        local endX = camCoord.x + forwardX * CONSTANTS.RAYCAST_MAX_DISTANCE
        local endY = camCoord.y + forwardY * CONSTANTS.RAYCAST_MAX_DISTANCE
        local endZ = camCoord.z + forwardZ * CONSTANTS.RAYCAST_MAX_DISTANCE

        return Raycast.PerformCheck(
            camCoord.x, camCoord.y, camCoord.z,
            endX, endY, endZ,
            CONSTANTS.RAYCAST_FLAGS
        )
    end

    return Raycast
end

-- ============================================================================
-- Inlined Library: SpoonerUtils
-- ============================================================================
local SpoonerUtils = {}

function SpoonerUtils.SplitString(inputStr, separator)
    if separator == nil then
        separator = "%s"
      end
      local t = {}
      for str in string.gmatch(inputStr, "([^"..separator.."]+)") do
        table.insert(t, str)
      end
      return t
end

-- Library aliases
local LoggerLib = CustomLogger
local EntityListsLib = EntityLists
local NetworkUtilsLib = NetworkUtils
local CameraUtilsLib = CameraUtils
local MemoryUtilsLib = MemoryUtils

-- ============================================================================
-- Constants
-- ============================================================================
local CONSTANTS = {
    NATIVES_URL = "https://raw.githubusercontent.com/Alsdrouf/CheraxSpooner/refs/heads/main/Spooner/Assets/natives.lua",
    PED_LIST_URL = "https://raw.githubusercontent.com/Alsdrouf/CheraxSpooner/refs/heads/main/Spooner/Assets/PedList.xml",
    PROP_LIST_URL = "https://raw.githubusercontent.com/Alsdrouf/CheraxSpooner/refs/heads/main/Spooner/Assets/PropList.xml",
    VEHICLE_LIST_URL = "https://raw.githubusercontent.com/Alsdrouf/CheraxSpooner/refs/heads/main/Spooner/Assets/VehicleList.xml",
    NETWORK_TIMEOUT = 1500,
    NETWORK_TIMEOUT_SHORT = 25,
    RAYCAST_MAX_DISTANCE = 1000.0,
    RAYCAST_INTERVAL = 3,
    RAYCAST_FLAGS = 30, -- vehicles + peds + objects + pickups
    MIN_GRAB_DISTANCE = 1.0,
    CAMERA_SPEED = 0.5,
    CAMERA_ROT_SPEED = 20.0,
    CAMERA_SPEED_BOOST = 3.0,
    ROTATION_SPEED = 2.0,
    ROTATION_SPEED_BOOST = 4.0,
    SCROLL_SPEED = 0.5,
    PITCH_CLAMP_MAX = 89.0,
    PITCH_CLAMP_MIN = -89.0,
    VELOCITY_MULTIPLIER = 30.0,
    CLIP_TO_GROUND_DISTANCE = 3, -- Distance from ground to trigger clip
    CLIP_TO_GROUND_RAYCAST_FLAGS = 33, -- Buildings, world geometry
    POSITION_STEP_DEFAULT = 1.0, -- Default step for position sliders
}

-- ============================================================================
-- Initialize Libraries (before natives)
-- ============================================================================
local CustomLogger = LoggerLib.New(pluginName)
local MemoryUtils = MemoryUtilsLib.New()

-- ============================================================================
-- Utilities
-- ============================================================================
local function DownloadAndSaveFile(url, filePath)
    local curlObject = Curl.Easy()
    curlObject:Setopt(eCurlOption.CURLOPT_URL, url)
    curlObject:AddHeader("User-Agent: Lua-Curl-Client")
    curlObject:Perform()

    while not curlObject:GetFinished() do
    end

    local responseCode, responseString = curlObject:GetResponse()

    if responseCode ~= eCurlCode.CURLE_OK then
        Logger.LogError("Error downloading file. Response code: " .. responseCode)
        Logger.LogError("Response message: " .. responseString)
        return false
    end

    if responseString == "404: Not Found" then
        Logger.LogError("File not found on the internet!")
        return false
    end

    if not FileMgr.WriteFileContent(filePath, responseString) then
        Logger.LogError("Error saving file: " .. filePath)
        Logger.LogError("Content: " .. responseString)
        return false
    end

    Logger.LogInfo("Successfully downloaded and saved: " .. filePath)
    return true
end

local function LoadNatives(path)
    if not FileMgr.DoesFileExist(path) then
        Logger.LogInfo("natives.lua not found. Downloading...")
        if not DownloadAndSaveFile(CONSTANTS.NATIVES_URL, path) then
            return false
        end
    end

    local status, err = pcall(dofile, path)
    if not status then
        Logger.LogError("Failed to load natives.lua: " .. err)
        return false
    end

    return true
end

LoadNatives(nativesPath)

local function DownloadAssetLists()
    if not FileMgr.DoesFileExist(pedListPath) then
        Logger.LogInfo("PedList.xml not found. Downloading...")
        DownloadAndSaveFile(CONSTANTS.PED_LIST_URL, pedListPath)
    end

    if not FileMgr.DoesFileExist(propListPath) then
        Logger.LogInfo("PropList.xml not found. Downloading...")
        DownloadAndSaveFile(CONSTANTS.PROP_LIST_URL, propListPath)
    end

    if not FileMgr.DoesFileExist(vehicleListPath) then
        Logger.LogInfo("VehicleList.xml not found. Downloading...")
        DownloadAndSaveFile(CONSTANTS.VEHICLE_LIST_URL, vehicleListPath)
    end
end

DownloadAssetLists()

-- ============================================================================
-- Initialize Libraries (after natives)
-- ============================================================================
local EntityLists = EntityListsLib.New(XMLParser, CustomLogger)
local NetworkUtils = NetworkUtilsLib.New(CONSTANTS)
local KeybindsInstance = KeybindsLib.New(PAD)
local Keybinds = KeybindsInstance.SetupDefaultBinds()
local CameraUtils = CameraUtilsLib.New(CONSTANTS)
local Raycast = RaycastLib.New("CameraHit", CONSTANTS, CustomLogger, MemoryUtils)
local RaycastForClipToGround = RaycastLib.New("ClipToGround", CONSTANTS, CustomLogger, MemoryUtils)

-- ============================================================================
-- Configuration Management
-- ============================================================================
local Config = {
    enableF9Key = false,
    throwableMode = false,
    clipToGround = false,
    lockMovementWhileMenuIsOpen = false,
    lockMovementWhileMenuIsOpenEnhanced = false,
    positionStep = CONSTANTS.POSITION_STEP_DEFAULT,
    spawnUnnetworked = false,
}

local function SaveConfig()
    local xmlContent = XMLParser.GenerateXML("SpoonerConfig", {
        enableF9Key = Config.enableF9Key,
        throwableMode = Config.throwableMode,
        clipToGround = Config.clipToGround,
        lockMovementWhileMenuIsOpen = Config.lockMovementWhileMenuIsOpen,
        lockMovementWhileMenuIsOpenEnhanced = Config.lockMovementWhileMenuIsOpenEnhanced,
        positionStep = Config.positionStep,
        spawnUnnetworked = Config.spawnUnnetworked
    })

    if FileMgr.WriteFileContent(configPath, xmlContent) then
        CustomLogger.Info("Configuration saved to XML")
        return true
    else
        CustomLogger.Error("Failed to save configuration")
        return false
    end
end

local function LoadConfig()
    if not FileMgr.DoesFileExist(configPath) then
        CustomLogger.Info("No config file found, using defaults")
        return
    end

    local configData = FileMgr.ReadFileContent(configPath)
    if not configData or configData == "" then
        CustomLogger.Warn("Config file is empty")
        return
    end

    local loadedConfig = XMLParser.ParseConfig(configData)

    CustomLogger.Info("Configuration loaded from XML")

    return loadedConfig
end

-- ============================================================================
-- Spooner Core
-- ============================================================================
local Spooner = {}
Spooner.inSpoonerMode = false
Spooner.freecam = nil
Spooner.freecamBlip = nil
Spooner.camSpeed = CONSTANTS.CAMERA_SPEED
Spooner.camRotSpeed = CONSTANTS.CAMERA_ROT_SPEED
Spooner.crosshairColor = {r = 255, g = 255, b = 255, a = 255}
Spooner.crosshairSize = 0.01
Spooner.crosshairGap = 0
Spooner.crosshairThickness = 0.001
Spooner.crosshairColorGreen = {r = 0, g = 255, b = 0, a = 255}
Spooner.lastEntityPos = nil
Spooner.grabVelocity = {x = 0, y = 0, z = 0}
Spooner.targetedEntity = nil
Spooner.isEntityTargeted = false
Spooner.grabbedEntity = nil
Spooner.grabOffsets = nil
Spooner.grabbedEntityRotation = nil
Spooner.isGrabbing = false
Spooner.scaleform = nil
---@alias ManagedEntity {entity: integer, networkId: integer, networked: boolean, x: number, y: number, z: number, rotX: number, rotY: number, rotZ: number}
---@type ManagedEntity[]
Spooner.managedEntities = {}
Spooner.selectedEntityIndex = 0
Spooner.selectedEntityBlip = nil
Spooner.throwableVelocityMultiplier = CONSTANTS.VELOCITY_MULTIPLIER
Spooner.throwableMode = false
Spooner.clipToGround = false
Spooner.lockMovementWhileMenuIsOpen = false
Spooner.lockMovementWhileMenuIsOpenEnhanced = false
Spooner.spawnUnnetworked = false
-- Preview spawn system
Spooner.previewEntity = nil
Spooner.previewModelHash = nil
Spooner.previewEntityType = nil  -- "prop", "vehicle", "ped"
Spooner.previewModelName = nil
Spooner.saveFileName = "MyPlacements"  -- Default save file name
Spooner.selectedXMLFile = nil  -- Selected XML file path for loading/deleting
---@alias QuickEditEntity {entity: integer, networkId: integer, networked: boolean}
---@type QuickEditEntity
Spooner.quickEditEntity = nil  -- Entity selected for quick editing (not necessarily in database)
-- Follow player mode
Spooner.followPlayerEnabled = false
Spooner.followPlayerId = nil
Spooner.followOffset = nil  -- Offset from player position when follow started
Spooner.lastFollowPlayerPos = nil  -- Last known player position to track movement

function Spooner.TakeControlOfEntity(entity)
    return NetworkUtils.MaintainNetworkControlV2(entity)
end

function Spooner.IsEntityRestricted(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return true
    end

    if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_A_PLAYER(entity) and entity ~= PLAYER.PLAYER_PED_ID() then
        return true
    end

    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(entity, -1)
        if driver ~= 0 and PED.IS_PED_A_PLAYER(driver) and driver ~= PLAYER.PLAYER_PED_ID() then
            return true
        end
    end

    return false
end

function Spooner.CalculateNewPosition(camPos, fwd, right, up, offsets)
    return {
        x = camPos.x + (right.x * offsets.x) + (fwd.x * offsets.y) + (up.x * offsets.z),
        y = camPos.y + (right.y * offsets.x) + (fwd.y * offsets.y) + (up.y * offsets.z),
        z = camPos.z + (right.z * offsets.x) + (fwd.z * offsets.y) + (up.z * offsets.z)
    }
end

function Spooner.CalculateGrabOffsets(camPos, entityPos, fwd, right, up)
    local vec = {
        x = entityPos.x - camPos.x,
        y = entityPos.y - camPos.y,
        z = entityPos.z - camPos.z
    }

    return {
        x = vec.x * right.x + vec.y * right.y + vec.z * right.z,
        y = vec.x * fwd.x + vec.y * fwd.y + vec.z * fwd.z,
        z = vec.x * up.x + vec.y * up.y + vec.z * up.z
    }
end

function Spooner.ShouldLockMovement()
    return GUI.IsOpen() and (Spooner.lockMovementWhileMenuIsOpen or (Spooner.lockMovementWhileMenuIsOpenEnhanced and (ImGui.IsWindowHovered(ImGuiHoveredFlags.AnyWindow) or ImGui.IsAnyItemHovered() or ImGui.IsAnyItemActive())))
end

function Spooner.StartFollowingPlayer(playerId)
    if not Spooner.freecam then
        return false
    end

    local cPed = Players.GetCPed(playerId)
    if not cPed then
        return false
    end

    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
    local playerPos = cPed.Position

    -- Store the offset from player to camera
    Spooner.followOffset = {
        x = camPos.x - playerPos.x,
        y = camPos.y - playerPos.y,
        z = camPos.z - playerPos.z
    }
    Spooner.lastFollowPlayerPos = {
        x = playerPos.x,
        y = playerPos.y,
        z = playerPos.z
    }
    Spooner.followPlayerId = playerId
    Spooner.followPlayerEnabled = true

    CustomLogger.Info("Now following player: " .. Players.GetName(playerId))
    return true
end

function Spooner.StopFollowingPlayer()
    Spooner.followPlayerEnabled = false
    Spooner.followPlayerId = nil
    Spooner.followOffset = nil
    Spooner.lastFollowPlayerPos = nil
    CustomLogger.Info("Stopped following player")
end

function Spooner.GetFollowPlayerDelta()
    if not Spooner.followPlayerEnabled or not Spooner.followPlayerId then
        return nil
    end

    local cPed = Players.GetCPed(Spooner.followPlayerId)
    if not cPed then
        Spooner.StopFollowingPlayer()
        return nil
    end

    local playerPos = cPed.Position

    -- Calculate how much the player moved since last frame
    local delta = {
        x = playerPos.x - Spooner.lastFollowPlayerPos.x,
        y = playerPos.y - Spooner.lastFollowPlayerPos.y,
        z = playerPos.z - Spooner.lastFollowPlayerPos.z
    }

    -- Update last known position
    Spooner.lastFollowPlayerPos = {
        x = playerPos.x,
        y = playerPos.y,
        z = playerPos.z
    }

    return delta
end

function Spooner.GetGroundZAtPosition(x, y, z, ignoreEntity)
    local isTargeted, entityTarget, rayHitCoords = RaycastForClipToGround.PerformCheck(x, y, z + 4, x, y, z - 100, CONSTANTS.CLIP_TO_GROUND_RAYCAST_FLAGS, ignoreEntity)

    return rayHitCoords.z
end

function Spooner.GetEntityDimensions(entity, memoryName)
    return Spooner.GetModelDimensions(ENTITY.GET_ENTITY_MODEL(entity), memoryName)
end

function Spooner.GetModelDimensions(modelHash, memoryName)
    local min = MemoryUtils.AllocV3(memoryName .. "Min")
    local max = MemoryUtils.AllocV3(memoryName .. "Max")
    MISC.GET_MODEL_DIMENSIONS(modelHash, min, max)
    local minV3 = MemoryUtils.ReadV3(min)
    local maxV3 = MemoryUtils.ReadV3(max)

    return minV3.x, minV3.y, minV3.z, maxV3.x, maxV3.y, maxV3.z
end

function Spooner.ClipEntityToGround(entity, newPos)
    if not Spooner.clipToGround then
        return newPos
    end

    -- Get ground Z at the entity's position (ignore the entity being moved)
    local groundZ = Spooner.GetGroundZAtPosition(newPos.x, newPos.y, newPos.z, entity)

    if groundZ then
        -- Get entity model dimensions
        local minX, minY, minZ, maxX, maxY, maxZ = Spooner.GetEntityDimensions(entity, "clip")

        -- Apply pending rotation first so GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS works correctly
        local rot = Spooner.grabbedEntityRotation or ENTITY.GET_ENTITY_ROTATION(entity, 2)
        ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, rot.z, 2, true)

        -- Define the 8 corners of the bounding box (same as Draw3DBox)
        local corners = {
            {minX, minY, minZ}, {maxX, minY, minZ},
            {maxX, maxY, minZ}, {minX, maxY, minZ},
            {minX, minY, maxZ}, {maxX, minY, maxZ},
            {maxX, maxY, maxZ}, {minX, maxY, maxZ}
        }

        -- Find the lowest world Z using the game's transformation
        local lowestWorldZ = math.huge
        for _, corner in ipairs(corners) do
            local worldPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, corner[1], corner[2], corner[3])
            if worldPos.z < lowestWorldZ then
                lowestWorldZ = worldPos.z
            end
        end

        -- Calculate how far the lowest point is from the entity origin
        local entityZ = ENTITY.GET_ENTITY_COORDS(entity, true).z
        local lowestOffset = lowestWorldZ - entityZ

        -- Calculate distance from lowest point to ground
        local projectedLowestZ = newPos.z + lowestOffset
        local distanceToGround = projectedLowestZ - groundZ

        -- If close enough to ground (above or below), snap to it
        if math.abs(distanceToGround) < CONSTANTS.CLIP_TO_GROUND_DISTANCE then
            newPos.z = groundZ - lowestOffset
        end
    end

    return newPos
end

function Spooner.DeleteEntity(entity)
    Spooner.UpdateSelectedEntityBlip()

    local netId = Spooner.TakeControlOfEntity(entity)

    local ptr = MemoryUtils.AllocInt("deleteEntityPtr")
    Memory.WriteInt(ptr, entity)

    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netId, false)
    NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netId, PLAYER.PLAYER_ID(), false)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, true)
    ENTITY.DELETE_ENTITY(ptr)

    CustomLogger.Info("Network ID: " .. tostring(netId))

    if ENTITY.DOES_ENTITY_EXIST(entity) then
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, 0, 0, 0, false, false, false)
    end
end

function Spooner.StartGrabbing()
    if Spooner.isGrabbing or not Spooner.isEntityTargeted or Spooner.targetedEntity == nil then
        return false
    end

    Spooner.isGrabbing = true
    Spooner.grabbedEntity = Spooner.targetedEntity

    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
    local entityPos = ENTITY.GET_ENTITY_COORDS(Spooner.grabbedEntity, true)
    local fwd, right, up, camRot = CameraUtils.GetBasis(Spooner.freecam)

    Spooner.grabOffsets = Spooner.CalculateGrabOffsets(camPos, entityPos, fwd, right, up)
    Spooner.grabbedEntityRotation = ENTITY.GET_ENTITY_ROTATION(Spooner.grabbedEntity, 2)
    Spooner.TakeControlOfEntity(Spooner.grabbedEntity)

    return true
end

function Spooner.UpdateGrabbedEntity()
    if not Spooner.previewEntity and (not Spooner.isGrabbing or not Spooner.grabbedEntity) then
        return
    end

    local entity = Spooner.grabbedEntity or Spooner.previewEntity

    Spooner.isEntityTargeted = true

    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        Spooner.ReleaseEntity()
        return
    end

    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
    local fwd, right, up, camRot = CameraUtils.GetBasis(Spooner.freecam)

    local speedMultiplier = Keybinds.MoveFaster.IsPressed() and CONSTANTS.ROTATION_SPEED_BOOST or 1.0

    if not Spooner.ShouldLockMovement() then
        local scrollSpeed = CONSTANTS.SCROLL_SPEED * speedMultiplier
        if Keybinds.PushEntity.IsPressed() then
            Spooner.grabOffsets.y = math.max(Spooner.grabOffsets.y - scrollSpeed, CONSTANTS.MIN_GRAB_DISTANCE)
        elseif Keybinds.PullEntity.IsPressed() then
            Spooner.grabOffsets.y = Spooner.grabOffsets.y + scrollSpeed
        end
    end

    local rotationSpeed = CONSTANTS.ROTATION_SPEED * speedMultiplier
    -- Yaw (Z axis) - Q/E keys
    if Keybinds.RotateRight.IsPressed() then
        Spooner.grabbedEntityRotation.z = Spooner.grabbedEntityRotation.z - rotationSpeed
    elseif Keybinds.RotateLeft.IsPressed() then
        Spooner.grabbedEntityRotation.z = Spooner.grabbedEntityRotation.z + rotationSpeed
    end
    -- Pitch (X axis) - Arrow Up/Down
    if Keybinds.PitchUp.IsPressed() then
        Spooner.grabbedEntityRotation.x = Spooner.grabbedEntityRotation.x - rotationSpeed
    elseif Keybinds.PitchDown.IsPressed() then
        Spooner.grabbedEntityRotation.x = Spooner.grabbedEntityRotation.x + rotationSpeed
    end
    -- Clamp pitch to avoid gimbal lock
    Spooner.grabbedEntityRotation.x = math.max(CONSTANTS.PITCH_CLAMP_MIN, math.min(Spooner.grabbedEntityRotation.x, CONSTANTS.PITCH_CLAMP_MAX))
    -- Roll (Y axis) - Arrow Left/Right
    if Keybinds.RollLeft.IsPressed() then
        Spooner.grabbedEntityRotation.y = Spooner.grabbedEntityRotation.y - rotationSpeed
    elseif Keybinds.RollRight.IsPressed() then
        Spooner.grabbedEntityRotation.y = Spooner.grabbedEntityRotation.y + rotationSpeed
    end

    local newPos = Spooner.CalculateNewPosition(camPos, fwd, right, up, Spooner.grabOffsets)

    -- Apply clip to ground if enabled
    newPos = Spooner.ClipEntityToGround(entity, newPos)

    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, newPos.x, newPos.y, newPos.z, false, false, false)

    ENTITY.SET_ENTITY_ROTATION(
        entity,
        Spooner.grabbedEntityRotation.x,
        Spooner.grabbedEntityRotation.y,
        Spooner.grabbedEntityRotation.z,
        2,
        true
    )

    if Spooner.throwableMode then
        if Spooner.lastEntityPos then
            Spooner.grabVelocity = {
                x = (newPos.x - Spooner.lastEntityPos.x) * Spooner.throwableVelocityMultiplier,
                y = (newPos.y - Spooner.lastEntityPos.y) * Spooner.throwableVelocityMultiplier,
                z = (newPos.z - Spooner.lastEntityPos.z) * Spooner.throwableVelocityMultiplier
            }
        end
        Spooner.lastEntityPos = newPos
    end
end

function Spooner.ReleaseEntity()
    if not Spooner.isGrabbing or not Spooner.grabbedEntity then
        return
    end

    if ENTITY.DOES_ENTITY_EXIST(Spooner.grabbedEntity) and Spooner.throwableMode then
        ENTITY.APPLY_FORCE_TO_ENTITY(
            Spooner.grabbedEntity,
            1,
            Spooner.grabVelocity.x,
            Spooner.grabVelocity.y,
            Spooner.grabVelocity.z,
            0.0, 0.0, 0.0,
            0,
            false,
            true,
            true,
            false,
            true
        )
    end

    Spooner.isGrabbing = false
    Spooner.grabbedEntity = nil
    Spooner.lastEntityPos = nil
    Spooner.grabVelocity = {x = 0, y = 0, z = 0}
end

function Spooner.HandleEntityGrabbing()
    if not Spooner.inSpoonerMode or not Spooner.freecam then
        return
    end

    local isRightClickPressed = Keybinds.Grab.IsPressed()

    if not Spooner.previewModelHash and not Spooner.ShouldLockMovement() then
        if isRightClickPressed and (Spooner.isGrabbing or (Spooner.isEntityTargeted and Spooner.targetedEntity)) then
            if not Spooner.isGrabbing then
                Spooner.StartGrabbing()
            end
        else
            Spooner.ReleaseEntity()
        end
    end
    Spooner.UpdateGrabbedEntity()
end

function Spooner.HandleInput()
    if not Spooner.inSpoonerMode then
        return
    end

    -- Handle right-click to select entity for quick editing (only when not grabbing and not in preview mode)
    if not Spooner.previewModelHash and not Spooner.isGrabbing and Keybinds.SelectForEdit.IsPressed() then
        if Spooner.isEntityTargeted and Spooner.targetedEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.targetedEntity) then
            Spooner.SelectEntityForQuickEdit(Spooner.targetedEntity)
        end
    end

    -- Block adding to database while in preview mode
    if not Spooner.previewModelHash and Keybinds.AddOrRemoveFromList.IsPressed() then
        local entityToAdd = nil

        if Spooner.isGrabbing and Spooner.grabbedEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.grabbedEntity) then
            entityToAdd = Spooner.grabbedEntity
        elseif Spooner.isEntityTargeted and Spooner.targetedEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.targetedEntity) then
            entityToAdd = Spooner.targetedEntity
        end

        if entityToAdd then
            Spooner.ToggleEntityInManagedList(entityToAdd)
        end
    end
end

function Spooner.UpdateFreecam()
    if not Spooner.inSpoonerMode or not Spooner.freecam then
        return
    end

    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    KeybindsInstance.EnablePassthroughControls()

    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
    local camRot = CAM.GET_CAM_ROT(Spooner.freecam, 2)

    local rightAxisX = PAD.GET_DISABLED_CONTROL_NORMAL(0, 220)
    local rightAxisY = PAD.GET_DISABLED_CONTROL_NORMAL(0, 221)

    if not Spooner.ShouldLockMovement() then
        camRot.z = camRot.z - (rightAxisX * Spooner.camRotSpeed)
        camRot.x = CameraUtils.ClampPitch(camRot.x - (rightAxisY * Spooner.camRotSpeed))
        camRot.y = 0.0
    end

    local radZ = math.rad(camRot.z)
    local radX = math.rad(camRot.x)

    local forwardX = -math.sin(radZ) * math.cos(radX)
    local forwardY = math.cos(radZ) * math.cos(radX)
    local forwardZ = math.sin(radX)
    local rightX = math.cos(radZ)
    local rightY = math.sin(radZ)

    local moveForward = Keybinds.MoveForward.IsPressed()
    local moveBackward = Keybinds.MoveBackward.IsPressed()
    local moveLeft = Keybinds.MoveLeft.IsPressed()
    local moveRight = Keybinds.MoveRight.IsPressed()
    local moveUp = Keybinds.MoveUp.IsPressed()
    local moveDown = Keybinds.MoveDown.IsPressed()

    local speed = Spooner.camSpeed
    if Keybinds.MoveFaster.IsPressed() then
        speed = speed * CONSTANTS.CAMERA_SPEED_BOOST
    end

    -- Apply follow player movement delta first
    local followDelta = Spooner.GetFollowPlayerDelta()
    if followDelta then
        camPos.x = camPos.x + followDelta.x
        camPos.y = camPos.y + followDelta.y
        camPos.z = camPos.z + followDelta.z
    end

    -- Then apply manual movement on top
    if not Spooner.ShouldLockMovement() then
        camPos.x = camPos.x + (forwardX * (moveForward - moveBackward) * speed)
        camPos.y = camPos.y + (forwardY * (moveForward - moveBackward) * speed)
        camPos.z = camPos.z + (forwardZ * (moveForward - moveBackward) * speed)
        camPos.x = camPos.x + (rightX * (moveRight - moveLeft) * speed)
        camPos.y = camPos.y + (rightY * (moveRight - moveLeft) * speed)
        camPos.z = camPos.z + ((moveUp - moveDown) * speed)
    end

    CAM.SET_CAM_COORD(Spooner.freecam, camPos.x, camPos.y, camPos.z)
    CAM.SET_CAM_ROT(Spooner.freecam, camRot.x, camRot.y, camRot.z, 2)

    STREAMING.SET_FOCUS_POS_AND_VEL(camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0)
    HUD.LOCK_MINIMAP_POSITION(camPos.x, camPos.y)

    -- Update blip position
    if Spooner.freecamBlip then
        HUD.SET_BLIP_COORDS(Spooner.freecamBlip, camPos.x, camPos.y, camPos.z)
    end
end

function Spooner.GetVehicleOfPed(ped)
    if PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
        return PED.GET_VEHICLE_PED_IS_IN(ped, true)
    end
    return nil
end

function Spooner.ToggleSpoonerMode(f)
    if Spooner.inSpoonerMode == f then
        return
    end

    Spooner.inSpoonerMode = f
    if Spooner.inSpoonerMode then
        local camPos = CAM.GET_GAMEPLAY_CAM_COORD()
        local camRot = CAM.GET_GAMEPLAY_CAM_ROT(2)

        Spooner.freecam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
        CAM.SET_CAM_COORD(Spooner.freecam, camPos.x, camPos.y, camPos.z)
        CAM.SET_CAM_ROT(Spooner.freecam, camRot.x, 0.0, camRot.z, 2)
        CAM.SET_CAM_ACTIVE(Spooner.freecam, true)
        CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, false, 0)
        CAM.SET_CAM_CONTROLS_MINI_MAP_HEADING(Spooner.freecam, true)

        -- Freeze player to prevent falling through the world when camera is far
        local playerPed = PLAYER.PLAYER_PED_ID()
        local vehicle = Spooner.GetVehicleOfPed(playerPed)
        Spooner.playerWasFrozen = Spooner.isEntityFrozen(vehicle or playerPed)
        if not Spooner.playerWasFrozen then
            ENTITY.FREEZE_ENTITY_POSITION(vehicle or playerPed, true)
        end

        -- Create blip for camera position
        Spooner.freecamBlip = HUD.ADD_BLIP_FOR_COORD(camPos.x, camPos.y, camPos.z)
        HUD.SET_BLIP_SPRITE(Spooner.freecamBlip, 184)  -- Eye/viewing sprite
        HUD.SET_BLIP_COLOUR(Spooner.freecamBlip, 5)    -- Yellow
        HUD.SET_BLIP_SCALE(Spooner.freecamBlip, 0.8)

        Spooner.UpdateSelectedEntityBlip()

        CustomLogger.Info("Freecam enabled")
    else
        if Spooner.freecam then
            STREAMING.CLEAR_FOCUS()
            HUD.UNLOCK_MINIMAP_POSITION()
            HUD.UNLOCK_MINIMAP_ANGLE()
            CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
            CAM.SET_CAM_ACTIVE(Spooner.freecam, false)
            CAM.DESTROY_CAM(Spooner.freecam, false)
            Spooner.freecam = nil
            Spooner.targetedEntity = nil

            -- Restore player frozen state
            local playerPed = PLAYER.PLAYER_PED_ID()
            local vehicle = Spooner.GetVehicleOfPed(playerPed)
            if not Spooner.playerWasFrozen then
                ENTITY.FREEZE_ENTITY_POSITION(vehicle or playerPed, false)
            end

            -- Remove camera blip
            if Spooner.freecamBlip then
                local ptr = MemoryUtils.AllocInt("blipPtr")
                Memory.WriteInt(ptr, Spooner.freecamBlip)
                HUD.REMOVE_BLIP(ptr)
                Spooner.freecamBlip = nil
            end

            -- Stop following player if active
            if Spooner.followPlayerEnabled then
                Spooner.StopFollowingPlayer()
            end

            -- Remove selected entity blip
            if Spooner.selectedEntityBlip then
                local ptr = MemoryUtils.AllocInt("selectedBlipPtr2")
                Memory.WriteInt(ptr, Spooner.selectedEntityBlip)
                HUD.REMOVE_BLIP(ptr)
                Spooner.selectedEntityBlip = nil
            end

            CustomLogger.Info("Freecam disabled")
        end
    end
end

function Spooner.ToggleEntityInManagedList(entity)
    if not entity then
        return
    end

    for i, managed in ipairs(Spooner.managedEntities) do
        if managed.entity == entity then
            table.remove(Spooner.managedEntities, i)
            CustomLogger.Info("Removed entity from managed list: " .. tostring(entity))
            -- If this was the selected entity, switch to quick edit mode
            if Spooner.selectedEntityIndex == i then
                Spooner.quickEditEntity = managed
                Spooner.selectedEntityIndex = 0
                Spooner.UpdateSelectedEntityBlip()
            elseif Spooner.selectedEntityIndex > i then
                -- Adjust index if removed entity was before selected one
                Spooner.selectedEntityIndex = Spooner.selectedEntityIndex - 1
                Spooner.UpdateSelectedEntityBlip()
            end
            return
        end
    end

    -- Adding entity to database
    local networkId = 0
    local networked = false
    if NetworkUtils.IsEntityNetworked(entity) then
        Spooner.TakeControlOfEntity(entity)
        networkId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
        networked = true
    end
    local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
    local rot = ENTITY.GET_ENTITY_ROTATION(entity, 2)
    ---@type ManagedEntity
    local managedEntry = {
        entity = entity,
        networkId = networkId,
        networked = networked,
        x = pos.x, y = pos.y, z = pos.z,
        rotX = rot.x, rotY = rot.y, rotZ = rot.z
    }
    table.insert(Spooner.managedEntities, managedEntry)
    CustomLogger.Info("Entity added to managed list: " .. tostring(entity) .. " (netId: " .. tostring(networkId) .. ")")

    -- If this entity was the quick edit entity, switch to database selection
    if Spooner.quickEditEntity and Spooner.quickEditEntity.entity == entity then
        Spooner.quickEditEntity = nil
        Spooner.selectedEntityIndex = #Spooner.managedEntities
        Spooner.UpdateSelectedEntityBlip()
    end
end

-- Select an entity for quick editing (works with any entity, not just database ones)
function Spooner.SelectEntityForQuickEdit(entity)
    if not entity or not ENTITY.DOES_ENTITY_EXIST(entity) then
        return false
    end

    -- Check if entity is already in the database
    local foundIndex = nil
    for i, managed in ipairs(Spooner.managedEntities) do
        if managed.entity == entity then
            foundIndex = i
            break
        end
    end

    if foundIndex then
        -- Entity is in database - select it from database
        Spooner.selectedEntityIndex = foundIndex
        Spooner.quickEditEntity = nil  -- Clear quick edit
    else
        -- Entity not in database - use quick edit
        local isNetworked = NetworkUtils.IsEntityNetworked(entity)
        Spooner.quickEditEntity = {entity = entity, networked = isNetworked, networkId = NetworkUtils.GetNetworkIdOf(entity)}
        Spooner.selectedEntityIndex = 0  -- Clear database selection
    end

    -- Update toggles to match entity's current state
    Spooner.UpdateFreezeToggleForEntity(entity)
    Spooner.UpdateDynamicToggleForEntity(entity)
    Spooner.UpdateGodModeToggleForEntity(entity)
    Spooner.UpdateNetworkedToggleForEntity(entity)

    -- Update blip for selected entity
    Spooner.UpdateSelectedEntityBlip()

    -- Open the menu if not already open
    if not GUI.IsOpen() then
        GUI.Toggle()
    end

    GUI.AddToast("Spooner", "Entity selected for editing", 1500)
    return true
end

-- Get the entity currently being edited (either from database or quick edit)
---@return integer|nil entity
---@return boolean isInDatabase
---@return integer networkId
---@return boolean networked
function Spooner.GetEditingEntity()
    -- Priority: database selection > quick edit
    if Spooner.selectedEntityIndex > 0 and Spooner.selectedEntityIndex <= #Spooner.managedEntities then
        local managed = Spooner.managedEntities[Spooner.selectedEntityIndex]
        if ENTITY.DOES_ENTITY_EXIST(managed.entity) then
            return managed.entity, true, managed.networkId, managed.networked  -- entity, isInDatabase, networkId, networked
        end
    end

    -- Fall back to quick edit entity
    if Spooner.quickEditEntity then
        if ENTITY.DOES_ENTITY_EXIST(Spooner.quickEditEntity.entity) then
            return Spooner.quickEditEntity.entity, false, Spooner.quickEditEntity.networkId, Spooner.quickEditEntity.networked  -- entity, isInDatabase, networkId, networked
        else
            Spooner.quickEditEntity = nil
        end
    end

    return nil, false, 0, false
end

-- Update the blip for the selected entity (database or quick edit)
function Spooner.UpdateSelectedEntityBlip()
    -- Remove existing blip if any
    if Spooner.selectedEntityBlip then
        local ptr = MemoryUtils.AllocInt("selectedBlipPtr")
        Memory.WriteInt(ptr, Spooner.selectedEntityBlip)
        HUD.REMOVE_BLIP(ptr)
        Spooner.selectedEntityBlip = nil
    end

    -- Get the entity being edited (database or quick edit)
    local entity = Spooner.GetEditingEntity()
    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        Spooner.selectedEntityBlip = HUD.ADD_BLIP_FOR_ENTITY(entity)
        HUD.SET_BLIP_SPRITE(Spooner.selectedEntityBlip, 1)  -- Standard blip
        HUD.SET_BLIP_COLOUR(Spooner.selectedEntityBlip, 1)  -- Red
        HUD.SET_BLIP_SCALE(Spooner.selectedEntityBlip, 1.0)
    end
end

function Spooner.ManageEntities()
    local entity, isInDatabase = Spooner.GetEditingEntity()
    -- Also maintain control of quick edit entity if set
    if entity and not isInDatabase then
        Spooner.TakeControlOfEntity(Spooner.quickEditEntity.entity)
    end
end

function Spooner.GetVehicleProperties(vehicle)
    local props = {}

    -- Colors
    local primaryColorPtr = MemoryUtils.AllocInt("vehPrimary")
    local secondaryColorPtr = MemoryUtils.AllocInt("vehSecondary")
    VEHICLE.GET_VEHICLE_COLOURS(vehicle, primaryColorPtr, secondaryColorPtr)
    props.primaryColor = Memory.ReadInt(primaryColorPtr)
    props.secondaryColor = Memory.ReadInt(secondaryColorPtr)

    local pearlColorPtr = MemoryUtils.AllocInt("vehPearl")
    local rimColorPtr = MemoryUtils.AllocInt("vehRim")
    VEHICLE.GET_VEHICLE_EXTRA_COLOURS(vehicle, pearlColorPtr, rimColorPtr)
    props.pearlColor = Memory.ReadInt(pearlColorPtr)
    props.rimColor = Memory.ReadInt(rimColorPtr)

    -- Mod colors
    local mod1aPtr = MemoryUtils.AllocInt("vehMod1a")
    local mod1bPtr = MemoryUtils.AllocInt("vehMod1b")
    local mod1cPtr = MemoryUtils.AllocInt("vehMod1c")
    VEHICLE.GET_VEHICLE_MOD_COLOR_1(vehicle, mod1aPtr, mod1bPtr, mod1cPtr)
    props.mod1a = Memory.ReadInt(mod1aPtr)
    props.mod1b = Memory.ReadInt(mod1bPtr)
    props.mod1c = Memory.ReadInt(mod1cPtr)

    local mod2aPtr = MemoryUtils.AllocInt("vehMod2a")
    local mod2bPtr = MemoryUtils.AllocInt("vehMod2b")
    VEHICLE.GET_VEHICLE_MOD_COLOR_2(vehicle, mod2aPtr, mod2bPtr)
    props.mod2a = Memory.ReadInt(mod2aPtr)
    props.mod2b = Memory.ReadInt(mod2bPtr)

    props.isPrimaryCustom = VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(vehicle)
    props.isSecondaryCustom = VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(vehicle)

    -- Tyre smoke color
    local tyreSmokeRPtr = MemoryUtils.AllocInt("vehTyreSmokeR")
    local tyreSmokeGPtr = MemoryUtils.AllocInt("vehTyreSmokeG")
    local tyreSmokeBPtr = MemoryUtils.AllocInt("vehTyreSmokeB")
    VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, tyreSmokeRPtr, tyreSmokeGPtr, tyreSmokeBPtr)
    props.tyreSmokeR = Memory.ReadInt(tyreSmokeRPtr)
    props.tyreSmokeG = Memory.ReadInt(tyreSmokeGPtr)
    props.tyreSmokeB = Memory.ReadInt(tyreSmokeBPtr)

    -- Interior, dashboard and xenon colors - use defaults as these natives may not be available
    props.interiorColor = 0
    props.dashboardColor = 0
    props.xenonColor = 255

    -- Other properties
    props.livery = VEHICLE.GET_VEHICLE_LIVERY(vehicle)
    props.plateText = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)
    props.plateIndex = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle)
    props.wheelType = VEHICLE.GET_VEHICLE_WHEEL_TYPE(vehicle)
    props.windowTint = VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle)
    props.bulletProofTyres = not VEHICLE.GET_VEHICLE_TYRES_CAN_BURST(vehicle)
    props.dirtLevel = VEHICLE.GET_VEHICLE_DIRT_LEVEL(vehicle)
    props.roofState = VEHICLE.GET_CONVERTIBLE_ROOF_STATE(vehicle)
    props.engineHealth = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(vehicle)
    props.engineOn = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(vehicle)
    props.lightsOn = VEHICLE.GET_VEHICLE_LIGHTS_STATE(vehicle, MemoryUtils.AllocInt("vehLightsOn"), MemoryUtils.AllocInt("vehHighBeams"))
    props.lockStatus = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(vehicle)

    -- Neons - use defaults as these natives may not be available
    props.neonLeft = false
    props.neonRight = false
    props.neonFront = false
    props.neonBack = false
    props.neonR = 255
    props.neonG = 0
    props.neonB = 255

    -- Mods
    props.mods = {}
    props.modVariations = {}
    for i = 0, 48 do
        if i >= 17 and i <= 22 then
            props.mods[i] = VEHICLE.IS_TOGGLE_MOD_ON(vehicle, i)
        else
            props.mods[i] = VEHICLE.GET_VEHICLE_MOD(vehicle, i)
            props.modVariations[i] = VEHICLE.GET_VEHICLE_MOD_VARIATION(vehicle, i)
        end
    end

    -- Extras
    props.extras = {}
    for i = 1, 12 do
        if i ~= 9 and i ~= 10 then
            props.extras[i] = VEHICLE.IS_VEHICLE_EXTRA_TURNED_ON(vehicle, i)
        end
    end

    return props
end

function Spooner.GetPedProperties(ped)
    local props = {}
    props.canRagdoll = PED.CAN_PED_RAGDOLL(ped)
    props.armour = PED.GET_PED_ARMOUR(ped)

    local weaponHashPtr = MemoryUtils.AllocInt("pedWeaponHash")
    WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHashPtr, true)
    props.currentWeapon = string.format("0x%X", Memory.ReadInt(weaponHashPtr))

    return props
end

function Spooner.GetEntityPlacementData(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return nil
    end

    local placement = {}
    local modelHash = ENTITY.GET_ENTITY_MODEL(entity)

    -- Format model hash as hex string like Menyoo does
    placement.modelHash = string.format("0x%x", modelHash)
    placement.hashName = GTA.GetModelNameFromHash(modelHash) or ""
    placement.handle = entity

    -- Determine entity type: 1 = ped, 2 = vehicle, 3 = object
    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        placement.type = 2
        placement.vehicleProperties = Spooner.GetVehicleProperties(entity)
    elseif ENTITY.IS_ENTITY_A_PED(entity) then
        placement.type = 1
        placement.pedProperties = Spooner.GetPedProperties(entity)
    else
        placement.type = 3
    end

    -- Position and rotation
    local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
    local rot = ENTITY.GET_ENTITY_ROTATION(entity, 2)
    placement.position = {x = pos.x, y = pos.y, z = pos.z}
    placement.rotation = {x = rot.x, y = rot.y, z = rot.z}

    -- Entity properties
    placement.frozen = Spooner.isEntityFrozen(entity)
    placement.dynamic = not placement.frozen
    placement.health = ENTITY.GET_ENTITY_HEALTH(entity)
    placement.maxHealth = ENTITY.GET_ENTITY_MAX_HEALTH(entity)
    placement.isInvincible = ENTITY.GET_ENTITY_CAN_BE_DAMAGED(entity) == false
    placement.hasGravity = true  -- Default, no easy way to check

    return placement
end

function Spooner.SaveDatabaseToXML(filename)
    if #Spooner.managedEntities == 0 then
        CustomLogger.Warn("No entities in database to save")
        GUI.AddToast("Spooner", "No entities in database to save", 2000)
        return false
    end

    local placements = {}
    local referenceCoords = nil

    for _, managed in ipairs(Spooner.managedEntities) do
        local placementData = Spooner.GetEntityPlacementData(managed.entity)
        if placementData then
            table.insert(placements, placementData)

            -- Use first entity position as reference coords
            if not referenceCoords then
                referenceCoords = placementData.position
            end
        end
    end

    if #placements == 0 then
        CustomLogger.Warn("No valid entities to save")
        GUI.AddToast("Spooner", "No valid entities to save", 2000)
        return false
    end

    local xmlContent = XMLParser.GenerateSpoonerXML(placements, referenceCoords)
    local filePath = spoonerSavePath .. "\\" .. filename .. ".xml"

    local table = SpoonerUtils.SplitString(filename, "/\\")
    local folder = ""
    for i=1, #table - 1 do
        folder = folder .. "\\" .. table[i]
        FileMgr.CreateDir(spoonerSavePath .. folder)
        CustomLogger.Info("Creating dir: " .. spoonerSavePath .. folder)
    end

    if FileMgr.WriteFileContent(filePath, xmlContent) then
        CustomLogger.Info("Saved " .. #placements .. " entities to " .. filePath)
        GUI.AddToast("Spooner", "Saved " .. #placements .. " entities to " .. filename .. ".xml", 3000)
        return true
    else
        CustomLogger.Error("Failed to save database to " .. filePath)
        GUI.AddToast("Spooner", "Failed to save database", 2000)
        return false
    end
end

function Spooner.ApplyVehicleProperties(vehicle, props)
    if not props then return end

    -- Apply colors
    VEHICLE.SET_VEHICLE_COLOURS(vehicle, props.primaryColor or 0, props.secondaryColor or 0)
    VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, props.pearlColor or 0, props.rimColor or 0)

    -- Apply mod colors
    if props.mod1a then
        VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, props.mod1a, props.mod1b or 0, props.mod1c or 0)
    end
    if props.mod2a then
        VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, props.mod2a, props.mod2b or 0)
    end

    -- Apply tyre smoke color
    if props.tyreSmokeR then
        VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, props.tyreSmokeR, props.tyreSmokeG or 255, props.tyreSmokeB or 255)
    end

    -- Apply other properties
    if props.plateText and props.plateText ~= "" then
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, props.plateText)
    end
    if props.plateIndex then
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, props.plateIndex)
    end
    if props.wheelType then
        VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, props.wheelType)
    end
    if props.windowTint then
        VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, props.windowTint)
    end
    if props.bulletProofTyres then
        VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, not props.bulletProofTyres)
    end
    if props.livery and props.livery >= 0 then
        VEHICLE.SET_VEHICLE_LIVERY(vehicle, props.livery)
    end

    -- Apply mods - need to set mod kit first
    VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)

    if props.mods then
        for i = 0, 48 do
            if props.mods[i] then
                if i >= 17 and i <= 22 then
                    -- Toggle mods
                    VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, i, props.mods[i])
                elseif props.mods[i] >= 0 then
                    -- Regular mods
                    local variation = props.modVariations and props.modVariations[i] or false
                    VEHICLE.SET_VEHICLE_MOD(vehicle, i, props.mods[i], variation)
                end
            end
        end
    end
end

function Spooner.ApplyPedProperties(ped, props)
    if not props then return end

    if props.armour then
        PED.SET_PED_ARMOUR(ped, props.armour)
    end

    if props.currentWeapon then
        local weaponHash = XMLParser.ParseNumber(props.currentWeapon)
        if weaponHash ~= 0 then
            WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, 999, false, true)
        end
    end
end

function Spooner.SpawnFromPlacement(placement)
    local modelHash = XMLParser.ParseNumber(placement.modelHash)
    if modelHash == 0 then
        CustomLogger.Error("Invalid model hash: " .. tostring(placement.modelHash))
        return nil
    end

    local pos = placement.position
    local rot = placement.rotation
    local entity = nil

    -- Spawn based on type: 1 = ped, 2 = vehicle, 3 = object
    if placement.type == 2 then
        entity = GTA.SpawnVehicle(modelHash, pos.x, pos.y, pos.z, rot.z, false, false)
        if entity and entity ~= 0 then
            Spooner.ApplyVehicleProperties(entity, placement.vehicleProperties)
        end
    elseif placement.type == 1 then
        entity = GTA.CreatePed(modelHash, 26, pos.x, pos.y, pos.z, rot.z, false, false)
        if entity and entity ~= 0 then
            Spooner.ApplyPedProperties(entity, placement.pedProperties)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
        end
    else
        entity = GTA.CreateWorldObject(modelHash, pos.x, pos.y, pos.z, false, false)
    end

    if entity and entity ~= 0 then
        -- Set exact position from XML (important for objects that may auto-place on ground)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, pos.x, pos.y, pos.z, false, false, false)
        -- Apply rotation
        ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, rot.z, 2, true)

        -- Apply frozen state
        if placement.frozen then
            ENTITY.FREEZE_ENTITY_POSITION(entity, true)
        end

        -- Apply invincible
        if placement.isInvincible then
            ENTITY.SET_ENTITY_INVINCIBLE(entity, true)
        end

        local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
        local rot = ENTITY.GET_ENTITY_ROTATION(entity, 2)
        ---@type ManagedEntity
        local managedEntry = {
            entity = entity,
            networkId = 0,
            networked = false,
            x = pos.x, y = pos.y, z = pos.z,
            rotX = rot.x, rotY = rot.y, rotZ = rot.z
        }
        table.insert(Spooner.managedEntities, managedEntry)

        CustomLogger.Info("Spawned entity: " .. (placement.hashName or placement.modelHash))

        return entity, managedEntry
    end

    return entity, nil
end

function Spooner.LoadDatabaseFromXML(filePath)
    if not FileMgr.DoesFileExist(filePath) then
        CustomLogger.Error("File not found: " .. filePath)
        GUI.AddToast("Spooner", "File not found: " .. filePath, 2000)
        return false
    end

    local xmlContent = FileMgr.ReadFileContent(filePath)
    if not xmlContent or xmlContent == "" then
        CustomLogger.Error("Failed to read file: " .. filePath)
        GUI.AddToast("Spooner", "Failed to read file", 2000)
        return false
    end

    local parsed = XMLParser.ParseSpoonerXML(xmlContent)
    if not parsed or #parsed.placements == 0 then
        CustomLogger.Warn("No placements found in file")
        GUI.AddToast("Spooner", "No placements found in file", 2000)
        return false
    end

    CustomLogger.Info("Loading " .. #parsed.placements .. " placements from " .. filePath)
    GUI.AddToast("Spooner", "Loading " .. #parsed.placements .. " placements...", 2000)

    local spawnedEntities = {}
    for _, placement in ipairs(parsed.placements) do
        local entity, managedEntry = Spooner.SpawnFromPlacement(placement)
        if entity then
            table.insert(spawnedEntities, {entity, managedEntry})
        end
        Script.Yield(0) -- Yield between spawns to prevent freezing
    end

    -- Batch network all spawned entities after loading
    if not Spooner.spawnUnnetworked then
        for _, managedSpawn in ipairs(spawnedEntities) do
            if ENTITY.DOES_ENTITY_EXIST(managedSpawn.entity) then
                local netId = NetworkUtils.MakeEntityNetworked(managedSpawn.entity)
                managedSpawn.managedEntry.networkId = netId
                managedSpawn.managedEntry.networked = true
            end
        end
    end

    CustomLogger.Info("Loaded " .. #spawnedEntities .. " entities from " .. filePath)
    GUI.AddToast("Spooner", "Loaded " .. #spawnedEntities .. " entities", 3000)
    return true
end

function Spooner.GetAvailableXMLFiles()
    local files = {}
    -- Use FileMgr.FindFiles to list XML files in the spooner save directory
    local fileList = FileMgr.FindFiles(spoonerSavePath, ".xml", true)
    if fileList then
        for _, filename in ipairs(fileList) do
            if filename and filename ~= "" then
                table.insert(files, filename)
            end
        end
    end
    return files
end

function Spooner.isEntityFrozen(entity)
    -- Check frozen state via memory (offset 0x2E, bit 1)
    local isFrozen = false
    local pEntity = GTA.HandleToPointer(entity)
    if pEntity and pEntity.IsFixed then
        isFrozen = true
    end
    return isFrozen
end

function Spooner.isEntityDynamic(entity)
    local isDynamic = false
    local pEntity = GTA.HandleToPointer(entity)
    if pEntity and pEntity.IsDynamic and not pEntity.IsFixed then
        isDynamic = true
    end
    return isDynamic
end

-- ============================================================================
-- Spawner
-- ============================================================================
local Spawner = {}
Spawner.isRunningPreviewSpawn = false

function Spawner.LoadModel(modelHash, timeout)
    timeout = timeout or 5000
    local startTime = Time.GetEpocheMs()

    STREAMING.REQUEST_MODEL(modelHash)
    while not STREAMING.HAS_MODEL_LOADED(modelHash) do
        if Time.GetEpocheMs() - startTime > timeout then
            CustomLogger.Error("Failed to load model: " .. tostring(modelHash))
            return false
        end
        Script.Yield(0)
    end
    return true
end

function Spawner.GetModelSize(modelHash)
    -- Load model temporarily to get dimensions
    STREAMING.REQUEST_MODEL(modelHash)
    local timeout = Time.GetEpocheMs() + 1000
    while not STREAMING.HAS_MODEL_LOADED(modelHash) and Time.GetEpocheMs() < timeout do
        Script.Yield(0)
    end

    if not STREAMING.HAS_MODEL_LOADED(modelHash) then
        return 10.0  -- Default distance if model can't load
    end

    local minX, minY, minZ, maxX, maxY, maxZ = Spooner.GetModelDimensions(modelHash, "modelSize")

    -- Calculate the diagonal size of the bounding box
    local sizeX = maxX - minX
    local sizeY = maxY - minY
    local sizeZ = maxZ - minZ
    local diagonalSize = math.sqrt(sizeX * sizeX + sizeY * sizeY + sizeZ * sizeZ)

    return diagonalSize
end

function Spawner.SelectEntity(entityType, modelName, modelHash)
    if Spooner.previewModelHash == modelHash then
        return
    end

    -- Calculate preview distance based on model size
    Script.QueueJob(function()
        -- Clear existing preview if any, but keep the rotation
        Spawner.ClearPreview(true, false)

        local modelSize = Spawner.GetModelSize(modelHash)
        -- Set preview distance to 1.5x the model diagonal size, with min/max bounds
        local previewDistance = math.max(5.0, math.min(modelSize * 1.5, 50.0))
        Spooner.grabOffsets = {x = 0, y = previewDistance, z = 0}

        Spooner.previewEntityType = entityType
        Spooner.previewModelName = modelName
        Spooner.previewModelHash = modelHash
    end)

    CustomLogger.Info("Selected " .. entityType .. ": " .. modelName .. " - Press Enter to spawn, Backspace to cancel")
end

function Spawner.SpawnProp(hashString, propName)
    local hash = Utils.sJoaat(hashString)
    local name = propName or hashString
    Spawner.SelectEntity("prop", name, hash)
end

function Spawner.SpawnVehicle(modelName)
    local hash = Utils.sJoaat(modelName)
    Spawner.SelectEntity("vehicle", modelName, hash)
end

function Spawner.SpawnPed(modelName)
    local hash = Utils.sJoaat(modelName)
    Spawner.SelectEntity("ped", modelName, hash)
end

function Spawner.ClearPreview(keepRotation, keepOffset)
    -- Queue the current preview entity for deletion in the game thread
    if Spooner.previewEntity then
        Spooner.DeleteEntity(Spooner.previewEntity)
    end
    Spooner.previewEntity = nil
    Spooner.previewModelHash = nil
    Spooner.previewEntityType = nil
    Spooner.previewModelName = nil
    if not keepRotation or not Spooner.grabbedEntityRotation then
        Spooner.grabbedEntityRotation = {x = 0, y = 0, z = 0}
    end
    if not keepOffset then
        Spooner.grabOffsets = {x = 0, y = 10.0, z = 0}
    end
end

function Spawner.CreatePreviewEntity(modelHash, entityType, pos)
    if Spawner.isRunningPreviewSpawn then return end
    Spawner.isRunningPreviewSpawn = true
    local entity = nil

    if entityType == "prop" then
        entity = GTA.CreateWorldObject(modelHash, pos.x, pos.y, pos.z, false, false)
    elseif entityType == "vehicle" then
        entity = GTA.SpawnVehicle(modelHash, pos.x, pos.y, pos.z, 0.0, false, false)
    elseif entityType == "ped" then
        entity = GTA.CreatePed(modelHash, 26, pos.x, pos.y, pos.z, 0.0, false, false)
    end

    if entity and entity ~= 0 then
        -- Make it intangible
        ENTITY.SET_ENTITY_COLLISION(entity, false, false)
        ENTITY.SET_ENTITY_INVINCIBLE(entity, true)
        ENTITY.FREEZE_ENTITY_POSITION(entity, true)

        if entityType == "ped" then
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity, true)
            TASK.TASK_STAND_STILL(entity, -1)
        end
    end

    Spawner.isRunningPreviewSpawn = false

    return entity
end

function Spawner.GetCrosshairWorldPosition()
    if not Spooner.freecam then
        return nil, false
    end

    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
    local camRot = CAM.GET_CAM_ROT(Spooner.freecam, 2)

    local radZ = math.rad(camRot.z)
    local radX = math.rad(camRot.x)

    local fwdX = -math.sin(radZ) * math.cos(radX)
    local fwdY = math.cos(radZ) * math.cos(radX)
    local fwdZ = math.sin(radX)

    local defaultSpawnDistance = 10.0
    local maxRaycastDistance = 100.0

    -- Default position: in front of camera at fixed distance
    local defaultPos = {
        x = camPos.x + fwdX * defaultSpawnDistance,
        y = camPos.y + fwdY * defaultSpawnDistance,
        z = camPos.z + fwdZ * defaultSpawnDistance
    }

    -- Raycast to find ground/surface
    local hit = MemoryUtils.AllocInt("crosshairHit")
    local endCoords = MemoryUtils.AllocV3("crosshairEndCoords")
    local surfaceNormal = MemoryUtils.AllocV3("crosshairSurfaceNormal")
    local entityHit = MemoryUtils.AllocInt("crosshairEntityHit")

    local rayHandle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
        camPos.x, camPos.y, camPos.z,
        camPos.x + fwdX * maxRaycastDistance,
        camPos.y + fwdY * maxRaycastDistance,
        camPos.z + fwdZ * maxRaycastDistance,
        -1,
        Spooner.previewEntity or 0,
        7
    )

    local result = SHAPETEST.GET_SHAPE_TEST_RESULT(rayHandle, hit, endCoords, surfaceNormal, entityHit)

    local hitResult = Memory.ReadInt(hit)
    local finalPos = defaultPos
    local didHitGround = false

    if hitResult == 1 then
        local hitV3 = MemoryUtils.ReadV3(endCoords)

        -- Calculate distance to hit point
        local dx = hit.x - camPos.x
        local dy = hit.y - camPos.y
        local dz = hit.z - camPos.z
        local hitDistance = math.sqrt(dx*dx + dy*dy + dz*dz)

        -- If hit is within reasonable distance, use it; otherwise spawn in front
        if hitDistance < maxRaycastDistance then
            finalPos = hitV3
            didHitGround = true
        end
    end

    return finalPos, didHitGround
end

function Spawner.UpdatePreview()
    if not Spooner.inSpoonerMode or not Spooner.previewModelHash then
        if Spooner.previewEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.previewEntity) then
            Spooner.DeleteEntity(Spooner.previewEntity)
            Spooner.previewEntity = nil
        end
        return
    end

    -- Create preview entity if needed
    if not Spooner.previewEntity or not ENTITY.DOES_ENTITY_EXIST(Spooner.previewEntity) then
        Spooner.previewEntity = Spawner.CreatePreviewEntity(Spooner.previewModelHash, Spooner.previewEntityType, {x=0,y=0,z=0})
    end
end

function Spawner.ConfirmSpawn()
    if not Spooner.previewEntity or not ENTITY.DOES_ENTITY_EXIST(Spooner.previewEntity) then
        return
    end

    -- Create actual entity
    Script.QueueJob(function()
        -- Remove status
        ENTITY.SET_ENTITY_COLLISION(Spooner.previewEntity, true, true)
        ENTITY.SET_ENTITY_INVINCIBLE(Spooner.previewEntity, false, false)
        if Spooner.previewEntityType ~= "prop" then
            ENTITY.FREEZE_ENTITY_POSITION(Spooner.previewEntity, false)
            ENTITY.SET_ENTITY_VELOCITY(Spooner.previewEntity, 0, 0 ,-1)
        end
        local networkId = 0
        local isNetworked = false
        if not Spooner.spawnUnnetworked then
            NetworkUtils.MakeEntityNetworked(Spooner.previewEntity)
            networkId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(Spooner.previewEntity)
            isNetworked = NetworkUtils.IsEntityNetworked(Spooner.previewEntity)
        end
        local pos = ENTITY.GET_ENTITY_COORDS(Spooner.previewEntity, true)
        local rot = ENTITY.GET_ENTITY_ROTATION(Spooner.previewEntity, 2)

        ENTITY.SET_ENTITY_COORDS(Spooner.previewEntity, pos.x, pos.y, pos.z, false, false, false, false)
        ENTITY.SET_ENTITY_ROTATION(Spooner.previewEntity, rot.x, rot.y, rot.z, 0, false)

        ---@type ManagedEntity
        local managedEntry = {
            entity = Spooner.previewEntity,
            networkId = networkId,
            networked = isNetworked,
            x = pos.x, y = pos.y, z = pos.z,
            rotX = rot.x, rotY = rot.y, rotZ = rot.z
        }
        table.insert(Spooner.managedEntities, managedEntry)
        CustomLogger.Info("Spawned " .. Spooner.previewEntityType .. ": " .. Spooner.previewModelName .. (isNetworked and " [Networked]" or " [Local]"))
        Spooner.previewEntity = Spawner.CreatePreviewEntity(Spooner.previewModelHash, Spooner.previewEntityType, {x=0,y=0,z=0})
    end)
end

function Spawner.HandleInput()
    if not Spooner.inSpoonerMode or not Spooner.previewModelHash then
        return
    end

    -- Confirm spawn with Enter
    if Keybinds.ConfirmSpawn.IsPressed() then
        Spawner.ConfirmSpawn()
    end

    -- Cancel with Backspace
    if Keybinds.CancelSpawn.IsPressed() then
        Spawner.ClearPreview()
        CustomLogger.Info("Spawn cancelled")
    end
end

-- ============================================================================
-- Draw Manager
-- ============================================================================
local DrawManager = {}

function DrawManager.PerformRaycastCheck()
    if Spooner.isGrabbing then return end

    local isTargeted, targetedEntity = Raycast.PerformCheckForFreecam(
        Spooner.freecam
    )

    if isTargeted and not Spooner.IsEntityRestricted(targetedEntity) then
        Spooner.isEntityTargeted = true
        Spooner.targetedEntity = targetedEntity
    elseif Raycast.data == nil then
        -- Only reset when raycast completed (not while waiting)
        Spooner.isEntityTargeted = false
        Spooner.targetedEntity = nil
    end
end

function DrawManager.DrawCrosshair()
    if not Spooner.inSpoonerMode then
        return
    end

    -- Skip raycast check and entity targeting visuals while in preview mode
    if not Spooner.previewModelHash then
        DrawManager.PerformRaycastCheck()
    end

    -- In preview mode, always use white crosshair (no entity targeting)
    local isTargeting = not Spooner.previewModelHash and Spooner.isEntityTargeted
    local color = isTargeting and Spooner.crosshairColorGreen or Spooner.crosshairColor
    local size = Spooner.crosshairSize
    local gap = Spooner.crosshairGap
    local aspectRatio = GRAPHICS.GET_SCREEN_ASPECT_RATIO()

    local sizeX = size / aspectRatio
    local sizeY = size
    local thicknessX = Spooner.crosshairThickness
    local thicknessY = Spooner.crosshairThickness * aspectRatio

    GRAPHICS.DRAW_RECT(0.5 - gap - sizeX / 2, 0.5, sizeX, thicknessY, color.r, color.g, color.b, color.a, false)
    GRAPHICS.DRAW_RECT(0.5 + gap + sizeX / 2, 0.5, sizeX, thicknessY, color.r, color.g, color.b, color.a, false)
    GRAPHICS.DRAW_RECT(0.5, 0.5 - gap - sizeY / 2, thicknessX, sizeY, color.r, color.g, color.b, color.a, false)
    GRAPHICS.DRAW_RECT(0.5, 0.5 + gap + sizeY / 2, thicknessX, sizeY, color.r, color.g, color.b, color.a, false)
end

function DrawManager.AddInstructionalButton(buttonIndex, keyString, label)
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "SET_DATA_SLOT")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(buttonIndex)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(keyString)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(label)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function DrawManager.AddInstructionalButtonMulti(buttonIndex, keyStrings, label)
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "SET_DATA_SLOT")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(buttonIndex)
    for _, keyString in ipairs(keyStrings) do
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(keyString)
    end
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(label)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

function DrawManager.DrawInstructionalButtons()
    if not Spooner.inSpoonerMode then
        return
    end

    if not Spooner.scaleform then
        Spooner.scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("instructional_buttons")
    end

    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(Spooner.scaleform) then
        return
    end

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "CLEAR_ALL")
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "TOGGLE_MOUSE_BUTTONS")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_BOOL(false)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "SET_CLEAR_SPACE")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(200)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    local buttonIndex = 0

    -- In preview mode
    if Spooner.previewModelHash then
        DrawManager.AddInstructionalButton(buttonIndex, Keybinds.ConfirmSpawn.string, "Spawn Entity")
        buttonIndex = buttonIndex + 1

        DrawManager.AddInstructionalButton(buttonIndex, Keybinds.CancelSpawn.string, "Cancel")
        buttonIndex = buttonIndex + 1
    end

    -- Normal mode keybinds
    if not Spooner.previewEntity then
        local grabLabel = Spooner.isGrabbing and "Release Entity" or "Grab Entity"
        DrawManager.AddInstructionalButton(buttonIndex, Keybinds.Grab.string, grabLabel)
        buttonIndex = buttonIndex + 1
    end

    if Spooner.isGrabbing or Spooner.previewEntity then
        DrawManager.AddInstructionalButtonMulti(
            buttonIndex,
            {Keybinds.RotateLeft.string, Keybinds.RotateRight.string},
            "Yaw"
        )
        buttonIndex = buttonIndex + 1

        DrawManager.AddInstructionalButtonMulti(
            buttonIndex,
            {Keybinds.PitchUp.string, Keybinds.PitchDown.string},
            "Pitch"
        )
        buttonIndex = buttonIndex + 1

        DrawManager.AddInstructionalButtonMulti(
            buttonIndex,
            {Keybinds.RollLeft.string, Keybinds.RollRight.string},
            "Roll"
        )
        buttonIndex = buttonIndex + 1

        DrawManager.AddInstructionalButtonMulti(
            buttonIndex,
            {Keybinds.PushEntity.string, Keybinds.PullEntity.string},
            "Push / Pull Entity"
        )
        buttonIndex = buttonIndex + 1
    end

    local entityToCheck = not Spooner.previewEntity and (Spooner.isGrabbing and Spooner.grabbedEntity or
                            (Spooner.isEntityTargeted and Spooner.targetedEntity or nil))

    if entityToCheck and ENTITY.DOES_ENTITY_EXIST(entityToCheck) then
        local isManaged = false
        for _, managed in ipairs(Spooner.managedEntities) do
            if managed.entity == entityToCheck then
                isManaged = true
                break
            end
        end

        local listLabel = isManaged and "Remove from List" or "Add to List"
        DrawManager.AddInstructionalButton(buttonIndex, Keybinds.AddOrRemoveFromList.string, listLabel)
        buttonIndex = buttonIndex + 1

        -- Quick edit hint
        DrawManager.AddInstructionalButton(buttonIndex, Keybinds.SelectForEdit.string, "Quick Edit")
        buttonIndex = buttonIndex + 1
    end

    DrawManager.AddInstructionalButton(buttonIndex, Keybinds.MoveFaster.string, "Move Faster")
    buttonIndex = buttonIndex + 1

    DrawManager.AddInstructionalButtonMulti(
        buttonIndex,
        {Keybinds.MoveUp.string, Keybinds.MoveDown.string},
        "Up / Down"
    )
    buttonIndex = buttonIndex + 1

    DrawManager.AddInstructionalButtonMulti(
        buttonIndex,
        {Keybinds.MoveRight.string, Keybinds.MoveLeft.string, Keybinds.MoveBackward.string, Keybinds.MoveForward.string},
        "Move Camera"
    )
    buttonIndex = buttonIndex + 1

    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(Spooner.scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(-1)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()

    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(Spooner.scaleform, 255, 255, 255, 255, 0)
end

---@param entity integer
---@param networkId? integer
---@param networked? boolean
---@return string
function DrawManager.GetEntityName(entity, networkId, networked)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return "Invalid Entity"
    end

    local modelHash = ENTITY.GET_ENTITY_MODEL(entity)
    local baseName

    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        -- Get the display name (like "Adder" instead of "adder")
        local displayName = GTA.GetDisplayNameFromHash(modelHash)
        local plate = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(entity)
        if displayName and displayName ~= "" and displayName ~= "NULL" then
            baseName = displayName .. " [" .. plate .. "]"
        else
            baseName = GTA.GetModelNameFromHash(modelHash) .. " [" .. plate .. "]"
        end
    else
        -- Check cache first for peds and props
        local cachedName = EntityLists.NameCache[modelHash]
        if cachedName then
            baseName = cachedName
        else
            -- Fallback to model name
            baseName = GTA.GetModelNameFromHash(modelHash)
        end
    end

    -- Append networkId if provided and non-zero
    if networkId and networkId ~= 0 then
        baseName = baseName .. " (" .. tostring(networkId) .. ")"
    end

    -- Append networked status
    if networked ~= nil then
        baseName = baseName .. (networked and " [N]" or " [L]")
    end

    return baseName
end

function DrawManager.Draw3DBox(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return
    end

    -- Get entity bounding box
    local minX, minY, minZ, maxX, maxY, maxZ = Spooner.GetEntityDimensions(entity, "3DBox")

    -- Calculate the 8 corners of the bounding box
    local corners = {
        {minX, minY, minZ}, -- bottom front left
        {maxX, minY, minZ}, -- bottom front right
        {maxX, maxY, minZ}, -- bottom back right
        {minX, maxY, minZ}, -- bottom back left
        {minX, minY, maxZ}, -- top front left
        {maxX, minY, maxZ}, -- top front right
        {maxX, maxY, maxZ}, -- top back right
        {minX, maxY, maxZ}  -- top back left
    }

    -- Transform corners to world space
    local worldCorners = {}
    for _, corner in ipairs(corners) do
        local worldPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, corner[1], corner[2], corner[3])
        table.insert(worldCorners, worldPos)
    end

    -- Draw bottom edges (RED)
    GRAPHICS.DRAW_LINE(worldCorners[1].x, worldCorners[1].y, worldCorners[1].z,
                       worldCorners[2].x, worldCorners[2].y, worldCorners[2].z, 255, 0, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[2].x, worldCorners[2].y, worldCorners[2].z,
                       worldCorners[3].x, worldCorners[3].y, worldCorners[3].z, 255, 0, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[3].x, worldCorners[3].y, worldCorners[3].z,
                       worldCorners[4].x, worldCorners[4].y, worldCorners[4].z, 255, 0, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[4].x, worldCorners[4].y, worldCorners[4].z,
                       worldCorners[1].x, worldCorners[1].y, worldCorners[1].z, 255, 0, 0, 255)

    -- Draw top edges (BLUE)
    GRAPHICS.DRAW_LINE(worldCorners[5].x, worldCorners[5].y, worldCorners[5].z,
                       worldCorners[6].x, worldCorners[6].y, worldCorners[6].z, 0, 0, 255, 255)
    GRAPHICS.DRAW_LINE(worldCorners[6].x, worldCorners[6].y, worldCorners[6].z,
                       worldCorners[7].x, worldCorners[7].y, worldCorners[7].z, 0, 0, 255, 255)
    GRAPHICS.DRAW_LINE(worldCorners[7].x, worldCorners[7].y, worldCorners[7].z,
                       worldCorners[8].x, worldCorners[8].y, worldCorners[8].z, 0, 0, 255, 255)
    GRAPHICS.DRAW_LINE(worldCorners[8].x, worldCorners[8].y, worldCorners[8].z,
                       worldCorners[5].x, worldCorners[5].y, worldCorners[5].z, 0, 0, 255, 255)

    -- Draw vertical edges connecting bottom to top (GREEN)
    GRAPHICS.DRAW_LINE(worldCorners[1].x, worldCorners[1].y, worldCorners[1].z,
                       worldCorners[5].x, worldCorners[5].y, worldCorners[5].z, 0, 255, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[2].x, worldCorners[2].y, worldCorners[2].z,
                       worldCorners[6].x, worldCorners[6].y, worldCorners[6].z, 0, 255, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[3].x, worldCorners[3].y, worldCorners[3].z,
                       worldCorners[7].x, worldCorners[7].y, worldCorners[7].z, 0, 255, 0, 255)
    GRAPHICS.DRAW_LINE(worldCorners[4].x, worldCorners[4].y, worldCorners[4].z,
                       worldCorners[8].x, worldCorners[8].y, worldCorners[8].z, 0, 255, 0, 255)
end

function DrawManager.DrawTargetedEntityBox()
    if not Spooner.inSpoonerMode then
        return
    end

    -- In preview mode, only draw box on preview entity
    if Spooner.previewModelHash then
        if Spooner.previewEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.previewEntity) then
            DrawManager.Draw3DBox(Spooner.previewEntity)
        end
        return
    end

    -- Draw box on targeted entity
    if Spooner.isEntityTargeted and Spooner.targetedEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.targetedEntity) then
        DrawManager.Draw3DBox(Spooner.targetedEntity)
    end

    -- Draw box on grabbed entity
    if Spooner.isGrabbing and Spooner.grabbedEntity and ENTITY.DOES_ENTITY_EXIST(Spooner.grabbedEntity) then
        DrawManager.Draw3DBox(Spooner.grabbedEntity)
    end
end

function DrawManager.DrawSelectedEntityMarker()
    if not Spooner.inSpoonerMode then
        return
    end

    local entity = Spooner.GetEditingEntity()

    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
        local minX, minY, minZ, maxX, maxY, maxZ = Spooner.GetEntityDimensions(entity, "SelectedMarker")

        -- Draw big arrow pointing down at the entity
        -- Use maxZ since dimensions are relative to entity origin
        GRAPHICS.DRAW_MARKER(
            0,
            pos.x, pos.y, pos.z + maxZ + 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            1.0, 1.0, 1.5,
            255, 0, 0, 150,
            false, false, 2, false, nil, nil, false
        )
    end
end

function DrawManager.ClickGUIInit()
    ClickGUI.AddPlayerTab(pluginName, function()
        ClickGUI.RenderFeature(Utils.Joaat("Spooner_EnableAtPlayer"))
        ClickGUI.RenderFeature(Utils.Joaat("Spooner_FollowPlayer"))
    end)

    ClickGUI.AddTab(pluginName, function()
        -- Main tab bar for Spooner with subtabs
        if ImGui.BeginTabBar("SpoonerMainTabs", 0) then
            -- Main subtab (contains settings)
            if ImGui.BeginTabItem("Main") then
                if ClickGUI.BeginCustomChildWindow("Spooner") then
                    ClickGUI.RenderFeature(Utils.Joaat("ToggleSpoonerMode"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_EnableF9Key"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_EnableThrowableMode"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_EnableClipToGround"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_SpawnUnnetworked"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_LockMovementWhileMenuIsOpen"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_LockMovementWhileMenuIsOpenEnhanced"))
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            -- Database subtab
            if ImGui.BeginTabItem("Database") then
                -- Managed Entities Database Section
                if ClickGUI.BeginCustomChildWindow("Managed Entities") then
                    -- Categorize entities by type
                    local vehicles = {}
                    local peds = {}
                    local props = {}

                    for i, managed in ipairs(Spooner.managedEntities) do
                        if ENTITY.DOES_ENTITY_EXIST(managed.entity) then
                            if ENTITY.IS_ENTITY_A_VEHICLE(managed.entity) then
                                table.insert(vehicles, {index = i, entity = managed.entity, networkId = managed.networkId, networked = managed.networked})
                            elseif ENTITY.IS_ENTITY_A_PED(managed.entity) then
                                table.insert(peds, {index = i, entity = managed.entity, networkId = managed.networkId, networked = managed.networked})
                            else
                                table.insert(props, {index = i, entity = managed.entity, networkId = managed.networkId, networked = managed.networked})
                            end
                        end
                    end

                    if ImGui.BeginTabBar("DatabaseTabs", 0) then
                        -- Vehicles Tab
                        if ImGui.BeginTabItem("Vehicles (" .. #vehicles .. ")###VehiclesTab") then
                            if #vehicles == 0 then
                                ImGui.Text("No vehicles in database")
                            else
                                for _, item in ipairs(vehicles) do
                                    local label = DrawManager.GetEntityName(item.entity, item.networkId, item.networked)
                                    local isSelected = (item.index == Spooner.selectedEntityIndex)
                                    if ImGui.Selectable(label .. "##veh_" .. item.index, isSelected) then
                                        if (not Spooner.quickEditEntity or Spooner.quickEditEntity.entity ~= item.entity) and Spooner.selectedEntityIndex ~= item.index then
                                            Script.QueueJob(function()
                                                Spooner.SelectEntityForQuickEdit(item.entity)
                                            end)
                                        end
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        -- Peds Tab
                        if ImGui.BeginTabItem("Peds (" .. #peds .. ")###PedsTab") then
                            if #peds == 0 then
                                ImGui.Text("No peds in database")
                            else
                                for _, item in ipairs(peds) do
                                    local label = DrawManager.GetEntityName(item.entity, item.networkId, item.networked)
                                    local isSelected = (item.index == Spooner.selectedEntityIndex)
                                    if ImGui.Selectable(label .. "##ped_" .. item.index, isSelected) then
                                        if (not Spooner.quickEditEntity or Spooner.quickEditEntity.entity ~= item.entity) and Spooner.selectedEntityIndex ~= item.index then
                                            Script.QueueJob(function()
                                                Spooner.SelectEntityForQuickEdit(item.entity)
                                            end)
                                        end
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        -- Props Tab
                        if ImGui.BeginTabItem("Props (" .. #props .. ")###PropsTab") then
                            if #props == 0 then
                                ImGui.Text("No props in database")
                            else
                                for _, item in ipairs(props) do
                                    local label = DrawManager.GetEntityName(item.entity, item.networkId, item.networked)
                                    local isSelected = (item.index == Spooner.selectedEntityIndex)
                                    if ImGui.Selectable(label .. "##prop_" .. item.index, isSelected) then
                                        if (not Spooner.quickEditEntity or Spooner.quickEditEntity.entity ~= item.entity) and Spooner.selectedEntityIndex ~= item.index then
                                            Script.QueueJob(function()
                                                Spooner.SelectEntityForQuickEdit(item.entity)
                                            end)
                                        end
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        -- All Tab
                        local totalCount = #Spooner.managedEntities
                        if ImGui.BeginTabItem("All (" .. totalCount .. ")###AllTab") then
                            ImGui.Spacing()
                            ClickGUI.RenderFeature(Utils.Joaat("Spooner_RemoveAll"))
                            ClickGUI.RenderFeature(Utils.Joaat("Spooner_DeleteAll"))
                            ImGui.EndTabItem()
                        end

                        ImGui.EndTabBar()
                    end

                    ImGui.Separator()
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_RemoveEntity"))
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_DeleteEntity"))

                    ImGui.Separator()
                    ImGui.Text("Save")
                    ImGui.Separator()

                    -- File name input for saving
                    local newFileName, fileNameChanged = ImGui.InputText("File Name", Spooner.saveFileName, 256)
                    if fileNameChanged and type(newFileName) == "string" then
                        Spooner.saveFileName = newFileName
                    end

                    -- Save button
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_SaveDatabaseToXML"))

                    ClickGUI.EndCustomChildWindow()
                end

                -- Manual Position/Rotation Control Section
                if ClickGUI.BeginCustomChildWindow("Entity Transform") then
                    local entity, isInDatabase, networkId, networked = Spooner.GetEditingEntity()
                    if entity then
                        local pos = ENTITY.GET_ENTITY_COORDS(entity, true)
                        local rot = ENTITY.GET_ENTITY_ROTATION(entity, 2)

                        -- Show entity info
                        local entityName = DrawManager.GetEntityName(entity, networkId, networked)
                        ImGui.Text("Editing: " .. entityName)
                        if not isInDatabase then
                            ImGui.SameLine()
                            ImGui.TextColored(1.0, 0.7, 0.0, 1.0, "(Quick Edit)")
                        end
                        ImGui.Separator()

                        -- Freeze toggle to prevent physics interference during rotation
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_FreezeSelectedEntity"))
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_DynamicEntity"))
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_GodModeEntity"))
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_NetworkedEntity"))
                        ImGui.Spacing()

                        ImGui.Text("Position")
                        ImGui.Separator()

                        -- Position step slider
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_PositionStep"))

                        -- X Position slider
                        local newX, changedX = ImGui.SliderFloat("X##pos", pos.x, pos.x - Config.positionStep, pos.x + Config.positionStep)
                        if changedX then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, newX, pos.y, pos.z, false, false, false)
                            end)
                        end

                        -- Y Position slider
                        local newY, changedY = ImGui.SliderFloat("Y##pos", pos.y, pos.y - Config.positionStep, pos.y + Config.positionStep)
                        if changedY then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, pos.x, newY, pos.z, false, false, false)
                            end)
                        end

                        -- Z Position slider
                        local newZ, changedZ = ImGui.SliderFloat("Z##pos", pos.z, pos.z - Config.positionStep, pos.z + Config.positionStep)
                        if changedZ then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, pos.x, pos.y, newZ, false, false, false)
                            end)
                        end

                        ImGui.Spacing()
                        ImGui.Text("Rotation")
                        ImGui.Separator()

                        -- Pitch (X rotation) slider - clamped to +/-89 to avoid gimbal lock flip
                        local newPitch, changedPitch = ImGui.SliderFloat("Pitch##rot", rot.x, -89.0, 89.0)
                        if changedPitch then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_ROTATION(entity, newPitch, rot.y, rot.z, 2, true)
                            end)
                        end

                        -- Roll (Y rotation) slider - clamped to +/-89 to avoid gimbal lock flip
                        local newRoll, changedRoll = ImGui.SliderFloat("Roll##rot", rot.y, -89.0, 89.0)
                        if changedRoll then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_ROTATION(entity, rot.x, newRoll, rot.z, 2, true)
                            end)
                        end

                        -- Yaw (Z rotation) slider
                        local newYaw, changedYaw = ImGui.SliderFloat("Yaw##rot", rot.z, -180.0, 180.0)
                        if changedYaw then
                            Script.QueueJob(function()
                                Spooner.TakeControlOfEntity(entity)
                                ENTITY.SET_ENTITY_ROTATION(entity, rot.x, rot.y, newYaw, 2, true)
                            end)
                        end

                        ImGui.Spacing()
                        ImGui.Separator()

                        -- Teleport buttons
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_TeleportToEntity"))
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_TeleportEntityHere"))

                        -- Delete button
                        ImGui.Spacing()
                        ImGui.Separator()
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_DeleteEntity"))

                        -- Add/Remove from database button
                        ImGui.Spacing()
                        if not isInDatabase then
                            ClickGUI.RenderFeature(Utils.Joaat("Spooner_AddToDatabase"))
                        else
                            ClickGUI.RenderFeature(Utils.Joaat("Spooner_RemoveEntity"))
                        end
                    else
                        ImGui.Text("No entity selected")
                        ImGui.Spacing()
                        ImGui.TextWrapped("Select an entity from the database above, or right-click an entity in Spooner mode to edit it.")
                    end
          
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            -- Spawner subtab
            if ImGui.BeginTabItem("Spawner") then
                if ClickGUI.BeginCustomChildWindow("Entity Spawner") then
                    if ImGui.BeginTabBar("SpawnerTabs", 0) then
                        -- Props Tab
                        if ImGui.BeginTabItem("Props") then
                            -- Filter input (InputText returns: newValue, changed)
                            local newPropFilter, propFilterChanged = ImGui.InputText("Prop Filter", EntityLists.PropFilter, 256)
                            if propFilterChanged and type(newPropFilter) == "string" then
                                EntityLists.PropFilter = newPropFilter
                            end

                            local filterLower = (EntityLists.PropFilter or ""):lower()

                            -- Sort categories alphabetically
                            local sortedCategories = {}
                            for categoryName, _ in pairs(EntityLists.Props) do
                                table.insert(sortedCategories, categoryName)
                            end
                            table.sort(sortedCategories)

                            for _, categoryName in ipairs(sortedCategories) do
                                local props = EntityLists.Props[categoryName]
                                -- Filter items within category
                                local filteredProps = {}
                                for _, prop in ipairs(props) do
                                    if filterLower == "" or prop.name:lower():find(filterLower, 1, true) then
                                        table.insert(filteredProps, prop)
                                    end
                                end

                                -- Only show category if it has matching items or filter is empty
                                if #filteredProps > 0 then
                                    -- Auto-expand when filtering (32 = TreeNodeFlags_DefaultOpen)
                                    local flags = (filterLower ~= "") and 32 or 0
                                    if ImGui.TreeNodeEx(categoryName .. "##Props", flags) then
                                        for _, prop in ipairs(filteredProps) do
                                            local displayName = prop.name
                                            if ImGui.Selectable(displayName .. "##prop_" .. prop.hash) then
                                                Spawner.SpawnProp(prop.hash, prop.name)
                                            end
                                        end
                                        ImGui.TreePop()
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        -- Vehicles Tab
                        if ImGui.BeginTabItem("Vehicles") then
                            -- Filter input (InputText returns: newValue, changed)
                            local newVehFilter, vehFilterChanged = ImGui.InputText("Vehicle Filter", EntityLists.VehicleFilter, 256)
                            if vehFilterChanged and type(newVehFilter) == "string" then
                                EntityLists.VehicleFilter = newVehFilter
                            end

                            local filterLower = (EntityLists.VehicleFilter or ""):lower()

                            -- Sort categories alphabetically
                            local sortedCategories = {}
                            for categoryName, _ in pairs(EntityLists.Vehicles) do
                                table.insert(sortedCategories, categoryName)
                            end
                            table.sort(sortedCategories)

                            for _, categoryName in ipairs(sortedCategories) do
                                local vehicles = EntityLists.Vehicles[categoryName]
                                -- Filter items within category
                                local filteredVehicles = {}
                                for _, vehicle in ipairs(vehicles) do
                                    local displayName = GTA.GetDisplayNameFromHash(Utils.Joaat(vehicle.name))
                                    if filterLower == "" or vehicle.name:lower():find(filterLower, 1, true) or displayName:lower():find(filterLower, 1, true) then
                                        table.insert(filteredVehicles, {vehicle = vehicle, displayName = displayName})
                                    end
                                end

                                -- Only show category if it has matching items
                                if #filteredVehicles > 0 then
                                    -- Auto-expand when filtering (32 = TreeNodeFlags_DefaultOpen)
                                    local flags = (filterLower ~= "") and 32 or 0
                                    if ImGui.TreeNodeEx(categoryName .. "##Vehicles", flags) then
                                        for _, item in ipairs(filteredVehicles) do
                                            if ImGui.Selectable(item.displayName .. "##veh_" .. item.vehicle.name) then
                                                Spawner.SpawnVehicle(item.vehicle.name)
                                            end
                                        end
                                        ImGui.TreePop()
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        -- Peds Tab
                        if ImGui.BeginTabItem("Peds") then
                            -- Filter input (InputText returns: newValue, changed)
                            local newPedFilter, pedFilterChanged = ImGui.InputText("Ped Filter", EntityLists.PedFilter, 256)
                            if pedFilterChanged and type(newPedFilter) == "string" then
                                EntityLists.PedFilter = newPedFilter
                            end

                            local filterLower = (EntityLists.PedFilter or ""):lower()

                            -- Sort categories alphabetically
                            local sortedCategories = {}
                            for categoryName, _ in pairs(EntityLists.Peds) do
                                table.insert(sortedCategories, categoryName)
                            end
                            table.sort(sortedCategories)

                            for _, categoryName in ipairs(sortedCategories) do
                                local peds = EntityLists.Peds[categoryName]
                                -- Filter items within category
                                local filteredPeds = {}
                                for _, ped in ipairs(peds) do
                                    local displayName = ped.caption ~= "" and ped.caption or ped.name
                                    if filterLower == "" or ped.name:lower():find(filterLower, 1, true) or displayName:lower():find(filterLower, 1, true) then
                                        table.insert(filteredPeds, {ped = ped, displayName = displayName})
                                    end
                                end

                                -- Only show category if it has matching items
                                if #filteredPeds > 0 then
                                    -- Auto-expand when filtering (32 = TreeNodeFlags_DefaultOpen)
                                    local flags = (filterLower ~= "") and 32 or 0
                                    if ImGui.TreeNodeEx(categoryName .. "##Peds", flags) then
                                        for _, item in ipairs(filteredPeds) do
                                            if ImGui.Selectable(item.displayName .. "##ped_" .. item.ped.name) then
                                                Spawner.SpawnPed(item.ped.name)
                                            end
                                        end
                                        ImGui.TreePop()
                                    end
                                end
                            end
                            ImGui.EndTabItem()
                        end

                        ImGui.EndTabBar()
                    end
                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            -- Load XML subtab
            if ImGui.BeginTabItem("Load XML") then
                if ClickGUI.BeginCustomChildWindow("XML File Browser") then
                    local xmlFiles = Spooner.GetAvailableXMLFiles()

                    -- Validate selected file still exists
                    if Spooner.selectedXMLFile then
                        local fileExists = false
                        for _, f in ipairs(xmlFiles) do
                            if f == Spooner.selectedXMLFile then
                                fileExists = true
                                break
                            end
                        end
                        if not fileExists then
                            Spooner.selectedXMLFile = nil
                        end
                    end

                    if #xmlFiles == 0 then
                        ImGui.Text("No XML files found")
                        ImGui.Text("Save some placements first!")
                    else
                        -- Build a tree structure from file paths
                        local fileTree = {}
                        for _, filename in ipairs(xmlFiles) do
                            local displayName = filename:gsub(spoonerSavePath .. "\\", ""):gsub(".xml$", "")
                            local parts = SpoonerUtils.SplitString(displayName, "\\")
                            if not parts or #parts == 0 then
                                parts = {displayName}
                            end

                            local currentLevel = fileTree
                            for i, part in ipairs(parts) do
                                if i == #parts then
                                    -- This is the file name (leaf node)
                                    if not currentLevel._files then
                                        currentLevel._files = {}
                                    end
                                    table.insert(currentLevel._files, {name = part, fullPath = filename})
                                else
                                    -- This is a folder
                                    if not currentLevel[part] then
                                        currentLevel[part] = {}
                                    end
                                    currentLevel = currentLevel[part]
                                end
                            end
                        end

                        -- Recursive function to render the tree
                        local function renderXMLFileTree(tree, depth)
                            -- First render folders (sorted alphabetically)
                            local folders = {}
                            for key, _ in pairs(tree) do
                                if key ~= "_files" then
                                    table.insert(folders, key)
                                end
                            end
                            table.sort(folders)

                            for _, folderName in ipairs(folders) do
                                if ImGui.TreeNode(folderName .. "##xmlfolder" .. depth .. folderName) then
                                    renderXMLFileTree(tree[folderName], depth + 1)
                                    ImGui.TreePop()
                                end
                            end

                            -- Then render files in this folder as selectables
                            if tree._files then
                                for _, fileInfo in ipairs(tree._files) do
                                    local isSelected = (Spooner.selectedXMLFile == fileInfo.fullPath)
                                    if ImGui.Selectable(fileInfo.name .. "##xml_" .. fileInfo.fullPath, isSelected) then
                                        Spooner.selectedXMLFile = fileInfo.fullPath
                                    end
                                end
                            end
                        end

                        renderXMLFileTree(fileTree, 0)
                    end

                    ImGui.Separator()
                    ImGui.Spacing()

                    -- Show selected file info and action buttons
                    if Spooner.selectedXMLFile then
                        local selectedDisplayName = Spooner.selectedXMLFile:gsub(spoonerSavePath .. "\\", ""):gsub(".xml$", "")
                        ImGui.Text("Selected: " .. selectedDisplayName)

                        -- Load and Delete buttons
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_LoadSelectedXML"))
                        ClickGUI.RenderFeature(Utils.Joaat("Spooner_DeleteSelectedXML"))
                    else
                        ImGui.Text("No file selected")
                    end

                    ImGui.Separator()
                    ImGui.Spacing()

                    -- Show folder path
                    ImGui.Text("XML Folder:")
                    ImGui.TextWrapped(spoonerSavePath)

                    -- Refresh button
                    ClickGUI.RenderFeature(Utils.Joaat("Spooner_RefreshXMLList"))

                    ClickGUI.EndCustomChildWindow()
                end
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end
    end)
end

-- ============================================================================
-- Features
-- ============================================================================
local toggleSpoonerModeFeature = FeatureMgr.AddFeature(
    Utils.Joaat("ToggleSpoonerMode"),
    "Toggle Spooner Mode",
    eFeatureType.Toggle,
    "Toggle Spooner Mode",
    function(f)
        Script.QueueJob(function()
            Spooner.ToggleSpoonerMode(f:IsToggled())
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_RemoveEntity"),
    "Remove from Database",
    eFeatureType.Button,
    "Remove selected entity from database",
    function(f)
        Script.QueueJob(function()
            local entity, isInDatabase = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) and isInDatabase then
                for i, managed in ipairs(Spooner.managedEntities) do
                    if managed.entity == entity then
                        table.remove(Spooner.managedEntities, i)
                        Spooner.quickEditEntity = managed
                        Spooner.selectedEntityIndex = 0
                        break
                    end
                end
                Spooner.UpdateSelectedEntityBlip()
                GUI.AddToast("Spooner", "Entity removed from database", 1500)
            else
                GUI.AddToast("Spooner", "No valid entity in database selected", 2000)
            end
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_RemoveAll"),
    "Remove All",
    eFeatureType.Button,
    "Remove all entities from database (keeps entities in game)",
    function(f)
        Script.QueueJob(function()
            local count = #Spooner.managedEntities
            if count > 0 then
                Spooner.managedEntities = {}
                Spooner.quickEditEntity = nil
                Spooner.selectedEntityIndex = 0
                Spooner.UpdateSelectedEntityBlip()
                GUI.AddToast("Spooner", "Removed " .. count .. " entities from database", 2000)
            else
                GUI.AddToast("Spooner", "Database is empty", 1500)
            end
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_DeleteAll"),
    "Delete All",
    eFeatureType.Button,
    "Delete all entities from database and game",
    function(f)
        Script.QueueJob(function()
            local count = #Spooner.managedEntities
            if count > 0 then
                for _, managed in ipairs(Spooner.managedEntities) do
                    if ENTITY.DOES_ENTITY_EXIST(managed.entity) then
                        Spooner.DeleteEntity(managed.entity)
                    end
                end
                Spooner.managedEntities = {}
                Spooner.quickEditEntity = nil
                Spooner.selectedEntityIndex = 0
                Spooner.UpdateSelectedEntityBlip()
                GUI.AddToast("Spooner", "Deleted " .. count .. " entities", 2000)
            else
                GUI.AddToast("Spooner", "Database is empty", 1500)
            end
        end)
    end
)

local isRunningFreeze = false
local isRunningDynamic = false

local dynamicEntityFeature
local freezeEntityFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_FreezeSelectedEntity"),
    "Freeze Entity",
    eFeatureType.Toggle,
    "Freeze entity position",
    function(f)
        isRunningFreeze = true
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                Spooner.TakeControlOfEntity(entity)
                local frozen = f:IsToggled()
                ENTITY.FREEZE_ENTITY_POSITION(entity, frozen)

                -- When unfreezing, activate physics so entity responds to gravity
                if not frozen then
                    ENTITY.SET_ENTITY_DYNAMIC(entity, true)
                    ENTITY.SET_ENTITY_HAS_GRAVITY(entity, true)
                    -- Apply small downward force to kickstart physics
                    ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, 0.0, 0.0, -0.5, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                end

                if not isRunningDynamic then
                    dynamicEntityFeature:Toggle(not frozen)
                end

                isRunningFreeze = false
            end
        end)
    end
)

-- Helper function to update freeze toggle when selecting a new entity
function Spooner.UpdateFreezeToggleForEntity(entity)
    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        local isFrozen = Spooner.isEntityFrozen(entity)
        local isToggled = freezeEntityFeature:IsToggled()
        if isFrozen ~= isToggled and not isRunningFreeze then
            freezeEntityFeature:Toggle(isFrozen)
        end
    end
end

dynamicEntityFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_DynamicEntity"),
    "Dynamic",
    eFeatureType.Toggle,
    "Toggle entity dynamic state",
    function(f)
        isRunningDynamic = true
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                Spooner.TakeControlOfEntity(entity)
                local dynamic = f:IsToggled()
                ENTITY.SET_ENTITY_DYNAMIC(entity, dynamic)

                if not isRunningFreeze then
                    freezeEntityFeature:Toggle(not dynamic)
                end

                isRunningDynamic = false 
            end
        end)
    end
)

-- Helper function to update dynamic toggle when selecting a new entity
function Spooner.UpdateDynamicToggleForEntity(entity)
    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        local isDynamic = Spooner.isEntityDynamic(entity)
        local isToggled = dynamicEntityFeature:IsToggled()
        if isDynamic ~= isToggled and not isRunningDynamic then
            dynamicEntityFeature:Toggle(isDynamic)
        end
    end
end

local isRunningGodMode = false

local godModeEntityFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_GodModeEntity"),
    "God Mode",
    eFeatureType.Toggle,
    "Make entity invincible",
    function(f)
        isRunningGodMode = true
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                Spooner.TakeControlOfEntity(entity)
                local godMode = f:IsToggled()
                ENTITY.SET_ENTITY_INVINCIBLE(entity, godMode)
                ENTITY.SET_ENTITY_CAN_BE_DAMAGED(entity, not godMode)
                isRunningGodMode = false
            end
        end)
    end
)

-- Helper function to update god mode toggle when selecting a new entity
function Spooner.UpdateGodModeToggleForEntity(entity)
    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        local isInvincible = ENTITY.GET_ENTITY_CAN_BE_DAMAGED(entity) == false
        local isToggled = godModeEntityFeature:IsToggled()
        if isInvincible ~= isToggled and not isRunningGodMode then
            godModeEntityFeature:Toggle(isInvincible)
        end
    end
end

local isRunningNetworked = false

local networkedEntityFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_NetworkedEntity"),
    "Networked",
    eFeatureType.Toggle,
    "Toggle entity networking state",
    function(f)
        isRunningNetworked = true
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                local networkId = 0
                if f:IsToggled() then
                    networkId = NetworkUtils.MakeEntityNetworked(entity)
                    networkId = NetworkUtils.MakeEntityNetworked(entity) -- Why I need to call twice no fucking idea
                else
                    local cPhysical = GTA.HandleToPointer(entity)
                    NetworkObjectMgr.UnregisterNetworkObject(cPhysical.NetObject, 0, true, false)
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, true) -- Fix despawning
                end
                -- Update the managed entity's networked state
                for _, managed in ipairs(Spooner.managedEntities) do
                    if managed.entity == entity then
                        managed.networked = NetworkUtils.IsEntityNetworked(entity)
                        managed.networkId = networkId
                        break
                    end
                end

                if Spooner.quickEditEntity and Spooner.quickEditEntity.entity == entity then
                    Spooner.quickEditEntity.networked = NetworkUtils.IsEntityNetworked(entity)
                    Spooner.quickEditEntity.networkId = networkId
                end

                isRunningNetworked = false
            end
        end)
    end
)

-- Helper function to update networked toggle when selecting a new entity
function Spooner.UpdateNetworkedToggleForEntity(entity)
    if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
        local isNetworked = NetworkUtils.IsEntityNetworked(entity)
        local isToggled = networkedEntityFeature:IsToggled()
        if isNetworked ~= isToggled and not isRunningNetworked then
            networkedEntityFeature:Toggle(isNetworked)
        end
    end
end

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_DeleteEntity"),
    "Delete Entity",
    eFeatureType.Button,
    "Delete selected entity from the game",
    function(f)
        Script.QueueJob(function()
            local entity, isInDatabase = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                CustomLogger.Info("Deleting entity: " .. tostring(entity))

                -- Clear selection BEFORE QueueJob to prevent UI from accessing deleted entity
                if Spooner.quickEditEntity and Spooner.quickEditEntity.entity == entity then
                    Spooner.quickEditEntity = nil
                end
                if isInDatabase then
                    for i, managed in ipairs(Spooner.managedEntities) do
                        if managed.entity == entity then
                            table.remove(Spooner.managedEntities, i)
                            break
                        end
                    end
                end
                Spooner.selectedEntityIndex = 0

                    Spooner.DeleteEntity(entity)

                    CustomLogger.Info("Deleted entity: " .. tostring(entity))
                    GUI.AddToast("Spooner", "Entity deleted", 1500)
            
            else
                GUI.AddToast("Spooner", "No valid entity selected", 2000)
            end
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_SaveDatabaseToXML"),
    "Save Database to XML",
    eFeatureType.Button,
    "Save all entities in database to XML file",
    function(f)
        Script.QueueJob(function()
            Spooner.SaveDatabaseToXML(Spooner.saveFileName)
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_TeleportToEntity"),
    "Teleport to Entity",
    eFeatureType.Button,
    "Teleport to the selected entity",
    function(f)
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                local entityPos = ENTITY.GET_ENTITY_COORDS(entity, true)
                if Spooner.inSpoonerMode and Spooner.freecam then
                    CAM.SET_CAM_COORD(Spooner.freecam, entityPos.x, entityPos.y - 5.0, entityPos.z + 2.0)
                else
                    local playerPed = PLAYER.PLAYER_PED_ID()
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(playerPed, entityPos.x, entityPos.y, entityPos.z + 1.0, false, false, false)
                end
            else
                GUI.AddToast("Spooner", "No valid entity selected", 2000)
            end
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_TeleportEntityHere"),
    "Teleport Entity Here",
    eFeatureType.Button,
    "Teleport the selected entity to camera/player position",
    function(f)
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                Spooner.TakeControlOfEntity(entity)
                local targetPos
                if Spooner.inSpoonerMode and Spooner.freecam then
                    local camPos = CAM.GET_CAM_COORD(Spooner.freecam)
                    local fwd = CameraUtils.GetBasis(Spooner.freecam)
                    targetPos = {
                        x = camPos.x + fwd.x * 5.0,
                        y = camPos.y + fwd.y * 5.0,
                        z = camPos.z + fwd.z * 5.0
                    }
                else
                    local playerPed = PLAYER.PLAYER_PED_ID()
                    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
                    local playerHeading = ENTITY.GET_ENTITY_HEADING(playerPed)
                    local rad = math.rad(playerHeading)
                    targetPos = {
                        x = playerPos.x - math.sin(rad) * 5.0,
                        y = playerPos.y + math.cos(rad) * 5.0,
                        z = playerPos.z
                    }
                end
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, targetPos.x, targetPos.y, targetPos.z, false, false, false)
            else
                GUI.AddToast("Spooner", "No valid entity selected", 2000)
            end
     end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_AddToDatabase"),
    "Add to Database",
    eFeatureType.Button,
    "Add the selected entity to the database",
    function(f)
        Script.QueueJob(function()
            local entity = Spooner.GetEditingEntity()
            if entity and ENTITY.DOES_ENTITY_EXIST(entity) then
                -- Check if already in database
                for _, managed in ipairs(Spooner.managedEntities) do
                    if managed.entity == entity then
                        GUI.AddToast("Spooner", "Entity already in database", 2000)
                        return
                    end
                end
                -- Add to database using same logic as pressing X
                Spooner.ToggleEntityInManagedList(entity)
                GUI.AddToast("Spooner", "Entity added to database", 1500)
            else
                GUI.AddToast("Spooner", "No valid entity selected", 2000)
            end
        end)
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_LoadSelectedXML"),
    "Load XML",
    eFeatureType.Button,
    "Load the selected XML file",
    function(f)
        if Spooner.selectedXMLFile then
            Script.QueueJob(function()
                Spooner.LoadDatabaseFromXML(Spooner.selectedXMLFile)
            end)
        else
            GUI.AddToast("Spooner", "No XML file selected", 2000)
        end
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_DeleteSelectedXML"),
    "Delete XML",
    eFeatureType.Button,
    "Delete the selected XML file",
    function(f)
        if Spooner.selectedXMLFile then
            local selectedDisplayName = Spooner.selectedXMLFile:match("([^\\]+)%.xml$") or Spooner.selectedXMLFile
            Script.QueueJob(function()
                if FileMgr.DeleteFile(Spooner.selectedXMLFile) then
                    GUI.AddToast("Spooner", "Deleted: " .. selectedDisplayName, 2000)
                    Spooner.selectedXMLFile = nil
                else
                    GUI.AddToast("Spooner", "Failed to delete file", 2000)
                end
            end)
        else
            GUI.AddToast("Spooner", "No XML file selected", 2000)
        end
    end
)

FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_RefreshXMLList"),
    "Refresh",
    eFeatureType.Button,
    "Refresh the XML file list",
    function(f)
        GUI.AddToast("Spooner", "File list refreshed", 1000)
    end
)

local enableF9KeyFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_EnableF9Key"),
    "Enable F9 Key",
    eFeatureType.Toggle,
    "Enable F9 key to toggle freecam",
    function(f)
        Config.enableF9Key = f:IsToggled()
        if Config.enableF9Key then
            toggleSpoonerModeFeature:AddHotKey(120)
        else
            toggleSpoonerModeFeature:RemoveHotkey(120, false)
        end
        SaveConfig()
    end
)

local enableThrowableModeFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_EnableThrowableMode"),
    "Enable Throwable Mode",
    eFeatureType.Toggle,
    "Enable Throwable Mode",
    function(f)
        Config.throwableMode = f:IsToggled()
        Spooner.throwableMode = Config.throwableMode
        SaveConfig()
    end
)

local enableClipToGroundFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_EnableClipToGround"),
    "Clip to Ground",
    eFeatureType.Toggle,
    "Snap entities to ground when within " .. CONSTANTS.CLIP_TO_GROUND_DISTANCE .. "m",
    function(f)
        Logger.LogInfo("clipToGround: " .. tostring(f:IsToggled()))
        Config.clipToGround = f:IsToggled()
        Spooner.clipToGround = Config.clipToGround
        SaveConfig()
    end
)

local spawnUnnetworkedFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_SpawnUnnetworked"),
    "Spawn Unnetworked",
    eFeatureType.Toggle,
    "Spawn entities as local (unnetworked) entities",
    function(f)
        Config.spawnUnnetworked = f:IsToggled()
        Spooner.spawnUnnetworked = Config.spawnUnnetworked
        SaveConfig()
    end
)

local lockMovementWhileMenuIsOpenFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_LockMovementWhileMenuIsOpen"),
    "Lock Movement while menu is open",
    eFeatureType.Toggle,
    "Lock cam movement and entity grab while menu is open",
    function (f)
        Config.lockMovementWhileMenuIsOpen = f:IsToggled()
        Spooner.lockMovementWhileMenuIsOpen = Config.lockMovementWhileMenuIsOpen
        SaveConfig()
    end
)

local lockMovementWhileMenuIsOpenEnhancedFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_LockMovementWhileMenuIsOpenEnhanced"),
    "Lock Movement while menu is open and hovering over it",
    eFeatureType.Toggle,
    "Lock cam movement and entity grab while menu is open and hovering over the menu",
    function (f)
        Config.lockMovementWhileMenuIsOpenEnhanced = f:IsToggled()
        Spooner.lockMovementWhileMenuIsOpenEnhanced = Config.lockMovementWhileMenuIsOpenEnhanced
        SaveConfig()
    end
)

local positionStepFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_PositionStep"),
    "Step",
    eFeatureType.SliderFloat,
    "Position adjustment step size",
    function(f)
        Config.positionStep = f:GetFloatValue()
        SaveConfig()
    end
)
positionStepFeature:SetMinValue(0.1)
positionStepFeature:SetMaxValue(5.0)
positionStepFeature:SetFloatValue(Config.positionStep)

FeatureMgr.AddFeature(Utils.Joaat("Spooner_EnableAtPlayer"), "Enable spooner at", eFeatureType.Button, "Enable spooner at the player", function(f)
    if toggleSpoonerModeFeature:IsToggled() == false then
        toggleSpoonerModeFeature:Toggle()
    end

    Script.QueueJob(function()
        local playerId = Utils.GetSelectedPlayer()
        local cPed = Players.GetCPed(playerId)
        CAM.SET_CAM_COORD(Spooner.freecam, cPed.Position.x, cPed.Position.y, cPed.Position.z)
    end)
end)

local followPlayerFeature = FeatureMgr.AddFeature(
    Utils.Joaat("Spooner_FollowPlayer"),
    "Follow player",
    eFeatureType.Toggle,
    "Follow the selected player with an offset. Camera moves when player moves, but you can still move freely.",
    function(f)
        Script.QueueJob(function()
            if f:IsToggled() then
                if not Spooner.inSpoonerMode then
                    toggleSpoonerModeFeature:Toggle()
                end
                local playerId = Utils.GetSelectedPlayer()
                if not Spooner.StartFollowingPlayer(playerId) then
                    f:Toggle() -- Disable if failed
                    GUI.AddToast("Spooner", "Failed to follow player", 2000)
                else
                    GUI.AddToast("Spooner", "Following " .. Players.GetName(playerId), 2000)
                end
            else
                Spooner.StopFollowingPlayer()
                GUI.AddToast("Spooner", "Stopped following player", 2000)
            end
        end)
    end
)

-- ============================================================================
-- Initialization
-- ============================================================================
Script.QueueJob(function()

    -- Load entities
    EntityLists.LoadAll(propListPath, vehicleListPath, pedListPath)

    -- Init gui
    DrawManager.ClickGUIInit()

    -- Load configuration and restore settings
    local loadedConfig = LoadConfig()
    if loadedConfig ~= nil then
        if loadedConfig.enableF9Key ~= nil and loadedConfig.enableF9Key then
            enableF9KeyFeature:Toggle(loadedConfig.enableF9Key)
        end
        if loadedConfig.clipToGround ~= nil and loadedConfig.clipToGround then
            enableClipToGroundFeature:Toggle(loadedConfig.clipToGround)
        end
        if loadedConfig.throwableMode ~= nil and loadedConfig.throwableMode then
            enableThrowableModeFeature:Toggle(loadedConfig.throwableMode)
        end
        if loadedConfig.lockMovementWhileMenuIsOpen ~= nil and loadedConfig.lockMovementWhileMenuIsOpen then
            lockMovementWhileMenuIsOpenFeature:Toggle(loadedConfig.lockMovementWhileMenuIsOpen)
        end
        if loadedConfig.lockMovementWhileMenuIsOpenEnhanced ~= nil and loadedConfig.lockMovementWhileMenuIsOpenEnhanced then
            lockMovementWhileMenuIsOpenEnhancedFeature:Toggle(loadedConfig.lockMovementWhileMenuIsOpenEnhanced)
        end
        if loadedConfig.positionStep ~= nil then
            positionStepFeature:SetFloatValue(loadedConfig.positionStep)
        end
        if loadedConfig.spawnUnnetworked ~= nil and loadedConfig.spawnUnnetworked then
            spawnUnnetworkedFeature:Toggle(loadedConfig.spawnUnnetworked)
        end
    end
end)

-- Thread for movement and action
Script.RegisterLooped(function()
    Script.QueueJob(function()
        Spooner.UpdateFreecam()
        Spooner.HandleInput()
        Spawner.HandleInput()
        Spawner.UpdatePreview()
    end)
end)

-- Thread for on screen display
Script.RegisterLooped(function()
    Script.QueueJob(function()
        DrawManager.DrawCrosshair()
        DrawManager.DrawInstructionalButtons()
        DrawManager.DrawSelectedEntityMarker()
    end)
end)

Script.RegisterLooped(function()
    if Spooner.inSpoonerMode then
        Script.QueueJob(function()
            Spooner.HandleEntityGrabbing()
            DrawManager.DrawTargetedEntityBox()
        end)
    end
end)

Script.RegisterLooped(function()
    if Spooner.grabbedEntity then
        Script.QueueJob(function() 
            Spooner.TakeControlOfEntity(Spooner.targetedEntity)
        end)
    elseif Spooner.targetedEntity then
        Script.QueueJob(function() 
            Spooner.TakeControlOfEntity(Spooner.targetedEntity)
        end)
    end
end)

EventMgr.RegisterHandler(eLuaEvent.ON_UNLOAD, function()
    Script.QueueJob(function()
        if Spooner.inSpoonerMode then
            toggleSpoonerModeFeature:Toggle()
        end
        Spooner.selectedEntityIndex = 0
        Spooner.quickEditEntity = nil
        Spooner.UpdateSelectedEntityBlip()
        -- Free all cached memory allocations
        MemoryUtils.FreeAll()
    end)
end)
