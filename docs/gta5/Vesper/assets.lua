-- Original vector assets for Vesper. Coordinates use a 16 px icon grid.
local A={}
function A.icon(d,name,x,y,col)
    local function l(a,b,e,f) d:AddLine(x+a,y+b,x+e,y+f,col,1.4) end
    local function r(a,b,w,h) d:AddRect(x+a,y+b,x+a+w,y+b+h,col,2,0,1.4) end
    local function circle(a,b,radius) d:AddCircle(x+a,y+b,radius,col,16,1.4) end
    if name=='Overlay' then r(1,2,14,10);l(5,15,11,15);l(8,12,8,15)
    elseif name=='World' then circle(8,8,6);l(2,8,14,8);l(8,2,8,14)
    elseif name=='Self' then circle(8,5,3);l(2,15,3,12);l(3,12,8,10);l(8,10,13,12);l(13,12,14,15)
    elseif name=='Vehicle' then l(2,7,4,3);l(4,3,12,3);l(12,3,14,7);r(1,7,14,6);l(4,10,5,10);l(11,10,12,10);l(3,13,3,15);l(13,13,13,15)
    elseif name=='Teleport' then circle(8,6,4);l(4,9,8,15);l(8,15,12,9);circle(8,6,1)
    elseif name=='Settings' then l(1,4,15,4);l(1,12,15,12);circle(5,4,2);circle(11,12,2)
    elseif name=='search' then circle(6,6,4);l(9,9,14,14)
    elseif name=='keys' then r(1,3,14,10);l(4,6,5,6);l(8,6,9,6);l(12,6,12,6);l(5,10,11,10)
    elseif name=='close' then l(4,4,12,12);l(12,4,4,12)
    elseif name=='repair' then l(3,14,11,6);l(9,2,8,6);l(8,6,11,9);l(11,9,15,7)
    elseif name=='paint' then r(2,1,12,7);l(8,8,8,15);l(5,4,11,4)
    elseif name=='save' then r(2,2,12,12);r(5,2,6,4);r(5,10,6,4)
    elseif name=='clean' then l(8,1,8,15);l(1,8,15,8);l(4,4,12,12);l(4,12,12,4)
    elseif name=='check' then l(2,8,6,12);l(6,12,14,4)
    elseif name=='arrow' then l(6,4,10,8);l(10,8,6,12)
    end
end
function A.logo(d,x,y,c)
    -- Original V monogram; geometry scales without external image/font assets.
    d:AddQuadFilled(x,y,x+5,y,x+12,y+17,x+8,y+21,c)
    d:AddQuadFilled(x+17,y,x+23,y,x+12,y+21,x+8,y+17,c)
end
return A
