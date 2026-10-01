local M = {}
function M.new()
    local s = {open=true, page="Overlay", search="", queue={}, stopped=false,
        message="Ready", error=false, snapshot={available=false, name="Local player", health=0, max_health=100, armour=0, speed=0, players=0, x=0,y=0,z=0, vehicle=0},
        options={watermark=true,keybinds=true,status=true,speedometer=true,coordinates=false,crosshair=false,mph=false,controller=true,auto_repair=false,hide_hud=false},
        paint={0.58,0.48,1.0}, plate="VESPER", hour=12, weather=0, slot=0, bookmarks={}, reset_layout=false}
    function s:report(message, is_error) self.message=tostring(message);self.error=not not is_error end
    function s:enqueue(action)
        if self.stopped or #self.queue >= 12 then return false end
        self.queue[#self.queue+1]=action;return true
    end
    function s:process(host)
        local action=table.remove(self.queue,1)
        if not action then return end
        local ok,result=pcall(host.action,host,action,self)
        if ok and result ~= false then self:report(type(result)=="string" and result or "Done")
        else self:report(ok and "Action unavailable in the current game state" or result,true) end
    end
    function s:stop() self.stopped=true;self.queue={};self.options.auto_repair=false;self.options.hide_hud=false end
    return s
end
return M
