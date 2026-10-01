local M={}
local pages={'Overview','Player & horse','Travel','World','Settings'}
local weather={'SUNNY','CLOUDS','OVERCAST','FOG','RAIN','SNOW','THUNDER'}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<1000000 end
local function point(p)
    return type(p)=='table' and finite(p.x) and finite(p.y) and finite(p.z)
end
function M.new()
    local self={open=true,focus=false,ready=false,tab=1,selected=1,pages=pages,
        message='Ready  /  F7 or LB + Down opens Vesper.',
        position={x=0,y=0,z=0},pad={connected=false},bookmarks={},bookmark=1,name='Camp',
        showHud=false,metric=true,hour=12,minute=0,weatherIndex=1,weather=weather,
        weatherOwned=false,timeOwned=false,pending=false,stopped=false}
    function self:load()
        Config.load()
        local saved=Config.get('frontier',{})
        if type(saved)~='table' then return end
        self.showHud=saved.showHud==true
        self.metric=saved.metric~=false
        if type(saved.bookmarks)=='table' then
            for _,p in ipairs(saved.bookmarks) do
                if #self.bookmarks>=30 then break end
                if point(p) and type(p.name)=='string' and #p.name>0 and #p.name<=80 then
                    self.bookmarks[#self.bookmarks+1]={name=p.name,x=p.x,y=p.y,z=p.z}
                end
            end
        end
    end
    function self:save()
        Config.set('frontier',{showHud=self.showHud,metric=self.metric,bookmarks=self.bookmarks})
        if not Config.save() then error('Could not save Vesper settings') end
    end
    function self:player()
        local ped=PLAYER.PLAYER_PED_ID()
        assert(ped~=0 and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped),'Player is unavailable or dead')
        return ped
    end
    function self:snapshot()
        local ped=PLAYER.PLAYER_PED_ID()
        self.ready=ped~=0 and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped)
        self.mount=0;self.vehicle=0;self.carrier='On foot'
        if not self.ready then return end
        self.position=ENTITY.GET_ENTITY_COORDS(ped,true,false)
        self.health=ENTITY.GET_ENTITY_HEALTH(ped)
        self.maxHealth=ENTITY.GET_ENTITY_MAX_HEALTH(ped,false)
        self.speed=ENTITY.GET_ENTITY_SPEED(ped)
        if PED.IS_PED_ON_MOUNT(ped) then
            self.mount=PED.GET_MOUNT(ped);self.carrier='On horseback'
        elseif PED.IS_PED_IN_ANY_VEHICLE(ped,false) then
            self.vehicle=PED.GET_VEHICLE_PED_IS_USING(ped);self.carrier='In a vehicle'
        end
        self.clock=World.getTime()
    end
    function self:travel(p)
        assert(point(p),'Invalid saved coordinates')
        local ped=self:player()
        -- Use only positions recorded in-world; never guess missing waypoint ground.
        if PED.IS_PED_IN_ANY_VEHICLE(ped,false) then
            local vehicle=PED.GET_VEHICLE_PED_IS_USING(ped)
            assert(vehicle~=0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle,-1)==ped,'Take the driver seat before moving a vehicle')
        end
        local before=ENTITY.GET_ENTITY_COORDS(ped,true,false)
        assert(Teleport.toCoords(p.x,p.y,p.z,false),'Travel failed')
        self.returnPoint={name='Previous position',x=before.x,y=before.y,z=before.z}
    end
    function self:cleanup()
        if self.weatherOwned then World.clearWeatherOverride();self.weatherOwned=false end
        if self.timeOwned then NETWORK.NETWORK_CLEAR_CLOCK_TIME_OVERRIDE();self.timeOwned=false end
        self.stopped=true
    end
    function self:actions()
        local out={}
        local function add(label,run,enabled) out[#out+1]={label=label,run=run,enabled=enabled~=false} end
        if self.tab==1 then
            add('Save this location',function() self.tab=3;self.selected=1 end,self.ready)
            add('Toggle compact HUD',function() self.showHud=not self.showHud;self:save() end)
        elseif self.tab==2 then
            add('Refill player health',function() self:player();Self.refillHealth() end,self.ready)
            add('Refill player stamina',function() self:player();Self.refillStamina() end,self.ready)
            add('Clear wanted level',function() self:player();Self.clearWantedLevel() end,self.ready)
            add('Refill horse health',function()
                local ped=self:player();assert(PED.IS_PED_ON_MOUNT(ped),'Mount a horse first');Mount.refillHealth()
            end,self.ready and self.mount~=0)
            add('Refill horse stamina',function()
                local ped=self:player();assert(PED.IS_PED_ON_MOUNT(ped),'Mount a horse first');Mount.refillStamina()
            end,self.ready and self.mount~=0)
        elseif self.tab==3 then
            add('Save current location',function()
                local ped=self:player()
                assert(#self.bookmarks<30,'There are already 30 saved locations')
                local name=self.name:match('^%s*(.-)%s*$')
                assert(#name>0 and #name<=80,'Enter a name of 1-80 bytes')
                local p=ENTITY.GET_ENTITY_COORDS(ped,true,false)
                self.bookmarks[#self.bookmarks+1]={name=name,x=p.x,y=p.y,z=p.z}
                self.bookmark=#self.bookmarks;self:save()
            end,self.ready and #self.bookmarks<30)
            add('Travel to selected location',function()
                assert(self.bookmarks[self.bookmark],'Select a location');self:travel(self.bookmarks[self.bookmark])
            end,self.ready and #self.bookmarks>0)
            add('Return to previous position',function() self:travel(self.returnPoint) end,self.ready and self.returnPoint~=nil)
            add('Select next location',function() self.bookmark=self.bookmark%#self.bookmarks+1 end,#self.bookmarks>0)
            add('Remove selected location',function() table.remove(self.bookmarks,self.bookmark);self.bookmark=1;self:save() end,#self.bookmarks>0)
        elseif self.tab==4 then
            add('Apply selected weather',function() self:player();World.setWeather(weather[self.weatherIndex]);self.weatherOwned=true end,self.ready)
            add('Select next weather',function() self.weatherIndex=self.weatherIndex%#weather+1 end)
            add('Clear weather override',function() World.clearWeatherOverride();self.weatherOwned=false end)
            add('Apply selected time',function() self:player();World.setTime(self.hour,self.minute,0);self.timeOwned=true end,self.ready)
            add('Select next time preset',function() self.hour=(self.hour+6)%24;self.minute=0 end)
            add('Clear time override',function() NETWORK.NETWORK_CLEAR_CLOCK_TIME_OVERRIDE();self.timeOwned=false end)
        else
            add('Toggle compact HUD',function() self.showHud=not self.showHud;self:save() end)
            add('Switch km/h / mph',function() self.metric=not self.metric;self:save() end)
            add('Save settings',function() self:save() end)
            add('Hide window',function() self.open=false end)
        end
        return out
    end
    function self:page(delta) self.tab=(self.tab-1+delta)%#pages+1;self.selected=1;self.scrollSelection=true end
    function self:select(delta) self.selected=(self.selected-1+delta)%#self:actions()+1;self.scrollSelection=true end
    function self:activate(index)
        if self.pending or self.stopped then return end
        local action=self:actions()[index]
        if not action or not action.enabled then return end
        self.pending=true
        script.run_in_fiber(function()
            if not self.stopped then
                local ok,err=pcall(action.run)
                self.message=ok and (action.label..' - done') or tostring(err)
            end
            self.pending=false
        end)
    end
    return self
end
return M
