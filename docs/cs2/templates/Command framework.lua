-- CS2 API 2.4. Enable command permission, then reload. Starts disabled.
if not commands.available() then
    ui.tab('framework','Command framework',function()
        imgui.text('Enable custom command callbacks in Script permissions, then reload this script.')
    end)
    return
end
local worker=assert(commands.create([[
    local prior_x,prior_y=0,0
    local function angle(v) return (v+180)%360-180 end
    local function direction(pitch,yaw)
        local p,y=math.rad(pitch),math.rad(yaw)
        return math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p)
    end
    return function(cmd,ctx)
        local eye=ctx.local_player.eye
        if not eye or not ctx.recoil then return end
        local key=game.key_down(0x05) -- mouse side button
        local recoil_x,recoil_y=ctx.recoil.x*2,ctx.recoil.y*2
        local aimed=false
        if key and shared.get('aim') then
            local chosen,best=nil,shared.get('fov') or 4
            for _,p in ipairs(ctx.players) do
                if p.alive and p.enemy and not p.immune and p.eye then
                    local dx,dy,dz=p.eye.x-eye.x,p.eye.y-eye.y,p.eye.z-eye.z
                    local pitch=-math.deg(math.atan(dz,math.sqrt(dx*dx+dy*dy)))
                    local yaw=math.deg(math.atan(dy,dx))
                    local delta=math.sqrt(angle(pitch-cmd.pitch)^2+angle(yaw-cmd.yaw)^2)
                    if delta<best then best=delta;chosen=p end
                end
            end
            if chosen then
                local point=game.bone(chosen.handle,6) or chosen.eye
                local hit=game.trace(eye,point)
                if hit and (hit.entity==chosen.handle or hit.fraction>.99) then
                    local dx,dy,dz=point.x-eye.x,point.y-eye.y,point.z-eye.z
                    local pitch=-math.deg(math.atan(dz,math.sqrt(dx*dx+dy*dy)))
                    local yaw=math.deg(math.atan(dy,dx))
                    if shared.get('rcs') then pitch=pitch-recoil_x;yaw=yaw-recoil_y end
                    local smoothing=shared.get('smoothing') or 6
                    cmd.pitch=math.max(-89,math.min(89,cmd.pitch+angle(pitch-cmd.pitch)/smoothing))
                    cmd.yaw=angle(cmd.yaw+angle(yaw-cmd.yaw)/smoothing)
                    aimed=true
                end
            end
        end
        if not aimed and shared.get('rcs') and (cmd.buttons&1)~=0 then
            cmd.pitch=math.max(-89,math.min(89,cmd.pitch-(recoil_x-prior_x)))
            cmd.yaw=angle(cmd.yaw-(recoil_y-prior_y))
        end
        prior_x,prior_y=recoil_x,recoil_y
        if key and shared.get('trigger') and ctx.weapon.can_fire then
            local x,y,z=direction(cmd.pitch+recoil_x,cmd.yaw+recoil_y)
            local hit=game.trace(eye,{x=eye.x+x*8192,y=eye.y+y*8192,z=eye.z+z*8192})
            if hit then for _,p in ipairs(ctx.players) do
                if p.handle==hit.entity and p.alive and p.enemy and not p.immune then cmd.buttons=cmd.buttons|1;break end
            end end
        end
        shared.set('last_command',cmd.number)
    end
]],{enabled=false}))
worker:set('aim',true);worker:set('rcs',true);worker:set('trigger',false)
worker:set('fov',4);worker:set('smoothing',6)
ui.tab('framework','Command framework',function()
    local status=worker:status()
    if not status.failed then
        local changed,value=ui.toggle('Enable custom framework',status.enabled)
        if changed then worker:enable(value) end
    end
    for _,v in ipairs({{'Custom aim','aim'},{'Custom recoil correction','rcs'},{'Custom trigger','trigger'}}) do
        local changed,value=ui.toggle(v[1],worker:get(v[2]) or false)
        if changed then worker:set(v[2],value) end
    end
    local changed,value=ui.slider('Field of view',worker:get('fov'),1,20)
    if changed then worker:set('fov',value) end
    changed,value=ui.slider('Smoothing',worker:get('smoothing'),1,20)
    if changed then worker:set('smoothing',value) end
    imgui.text('Hold mouse side button for aim / trigger. Enable only one framework at a time.')
    imgui.text(commands.engine_status().message)
    imgui.text('Commands: '..status.calls..' | Replays: '..status.replays)
    if status.error~='' then imgui.text(status.error) end
end)
