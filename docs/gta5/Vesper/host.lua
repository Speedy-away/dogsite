-- Game calls run only from the queued script fiber, never from a GUI button.
local H = {};H.__index=H
local function finite(x) return type(x)=="number" and x==x and math.abs(x)<1e8 end
function H.new()
    local self=setmetatable({ready=false,weather_owned=false,last_sample=nil,last_repair=nil},H)
    local ok,err=pcall(function()
        if not PLAYER or not PLAYER.PLAYER_PED_ID then natives.load_natives() end
        assert(PLAYER and ENTITY and VEHICLE and PED and MISC,"Game native API unavailable")
    end)
    self.ready=ok;self.reason=ok and "" or tostring(err)
    return self
end
function H:context(vehicle_required)
    assert(self.ready,self.reason)
    assert(not HUD.IS_PAUSE_MENU_ACTIVE(),"Close the game pause menu first")
    assert(not STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS(),"Wait for the player transition")
    local ped=PLAYER.PLAYER_PED_ID()
    assert(ped~=0 and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped,false),"Local player unavailable")
    local vehicle=PED.GET_VEHICLE_PED_IS_IN(ped,false)
    if vehicle_required then
        assert(vehicle~=0 and ENTITY.DOES_ENTITY_EXIST(vehicle),"Enter a vehicle first")
        assert(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle,-1,false)==ped,"Use the driver's seat")
    end
    return ped,vehicle
end
function H:sample()
    local ped=PLAYER.PLAYER_PED_ID()
    if ped==0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return {available=false,name="Loading",health=0,max_health=100,armour=0,speed=0,players=0,x=0,y=0,z=0,vehicle=0} end
    local pos=ENTITY.GET_ENTITY_COORDS(ped,true)
    local vehicle=PED.GET_VEHICLE_PED_IS_IN(ped,false)
    return {available=true,name=PLAYER.GET_PLAYER_NAME(PLAYER.PLAYER_ID()),health=ENTITY.GET_ENTITY_HEALTH(ped),
        max_health=math.max(1,ENTITY.GET_ENTITY_MAX_HEALTH(ped)),armour=PED.GET_PED_ARMOUR(ped),
        speed=ENTITY.GET_ENTITY_SPEED(vehicle~=0 and vehicle or ped),vehicle=vehicle,
        players=NETWORK.NETWORK_IS_SESSION_STARTED() and NETWORK.NETWORK_GET_NUM_CONNECTED_PLAYERS() or 1,
        x=pos.x,y=pos.y,z=pos.z,online=NETWORK.NETWORK_IS_SESSION_STARTED()}
end
function H:frame(s)
    if not self.ready then return end
    local now=MISC.GET_GAME_TIMER()
    if not self.last_sample or now<self.last_sample or now-self.last_sample>=200 then
        s.snapshot=self:sample();self.last_sample=now
    end
    if s.open and not HUD.IS_PAUSE_MENU_ACTIVE() then PAD.DISABLE_ALL_CONTROL_ACTIONS(0);PAD.DISABLE_ALL_CONTROL_ACTIONS(2) end
    if s.options.hide_hud then HUD.HIDE_HUD_AND_RADAR_THIS_FRAME() end
    if s.options.auto_repair and (not self.last_repair or now<self.last_repair or now-self.last_repair>=1500) then
        self.last_repair=now
        local ok,_,veh=pcall(self.context,self,true)
        if ok then VEHICLE.SET_VEHICLE_FIXED(veh) end
    end
end
function H:action(id,s)
    if id=="save_preferences" then
        local saved={};for _,key in ipairs({"watermark","keybinds","status","speedometer","coordinates","crosshair","mph","controller"}) do saved[key]=s.options[key] end
        config.set("studio.options",saved);config.set("studio.bookmarks",s.bookmarks)
        assert(config.save(),"Could not save preferences; check File Write capability")
        return "Preferences saved"
    end
    if id=="reset_layout" then s.reset_layout=true;return "Panel positions reset" end
    local ped,vehicle=self:context(id:sub(1,4)=="car_")
    if id=="heal" then ENTITY.SET_ENTITY_HEALTH(ped,ENTITY.GET_ENTITY_MAX_HEALTH(ped),0,0)
    elseif id=="armour" then PED.SET_PED_ARMOUR(ped,100)
    elseif id=="clean" then PED.CLEAR_PED_BLOOD_DAMAGE(ped);PED.CLEAR_PED_WETNESS(ped)
    elseif id=="wanted" then PLAYER.CLEAR_PLAYER_WANTED_LEVEL(PLAYER.PLAYER_ID())
    elseif id=="car_repair" then VEHICLE.SET_VEHICLE_FIXED(vehicle);VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    elseif id=="car_wash" then VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle,0)
    elseif id=="car_flip" then
        local heading=ENTITY.GET_ENTITY_HEADING(vehicle)
        ENTITY.SET_ENTITY_ROTATION(vehicle,0,0,heading,2,true);VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(vehicle,5.0)
    elseif id=="car_engine_on" or id=="car_engine_off" then VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle,id=="car_engine_on",true,false)
    elseif id=="car_doors_open" then for door=0,5 do VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle,door,false,false) end
    elseif id=="car_doors_close" then VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle,false)
    elseif id=="car_paint" then
        local rgb={};for i=1,3 do assert(finite(s.paint[i]),"Invalid paint color");rgb[i]=math.floor(math.max(0,math.min(1,s.paint[i]))*255+0.5) end
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle,rgb[1],rgb[2],rgb[3]);VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle,rgb[1],rgb[2],rgb[3])
    elseif id=="car_plate" then
        local plate=s.plate:gsub("[^%w ]", ""):sub(1,8);assert(#plate>0,"Enter a plate label")
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle,plate)
    elseif id=="bookmark_save" then
        local p=ENTITY.GET_ENTITY_COORDS(ped,true);s.bookmarks[tostring(s.slot)]={x=p.x,y=p.y,z=p.z};return "Location saved in slot "..(s.slot+1)
    elseif id=="bookmark_return" then
        local p=s.bookmarks[tostring(s.slot)];assert(type(p)=="table" and finite(p.x) and finite(p.y) and finite(p.z),"Save this location slot first")
        if vehicle~=0 then self:context(true) end
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(vehicle~=0 and vehicle or ped,p.x,p.y,p.z,false,false,false)
    elseif id=="waypoint" then
        if vehicle~=0 then self:context(true) end
        assert(teleport.to_waypoint(),"Place a waypoint on the map first")
    elseif id=="weather" then
        local choices={"EXTRASUNNY","CLEAR","CLOUDS","OVERCAST","RAIN","THUNDER","FOGGY","SNOWLIGHT"}
        local weather=choices[s.weather+1];assert(weather,"Invalid weather preset")
        MISC.SET_WEATHER_TYPE_NOW_PERSIST(weather);self.weather_owned=true
    elseif id=="weather_reset" then self:clear_weather()
    elseif id=="clock" then CLOCK.SET_CLOCK_TIME(math.max(0,math.min(23,math.floor(s.hour))),0,0)
    else error("Unknown action: "..tostring(id)) end
    return "Applied"
end
function H:clear_weather()
    MISC.CLEAR_OVERRIDE_WEATHER();MISC.CLEAR_WEATHER_TYPE_PERSIST();self.weather_owned=false
end
function H:close()
    if self.weather_owned then pcall(self.clear_weather,self) end
end
return H
