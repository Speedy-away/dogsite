-- Local inventory editor and one native 3D preview. No items added until a button is pressed.
local entries=inventory.catalog('weapon',1,256)
local selection,paint_index=1,1
local draft,finishes=nil,{}
local wear,seed=.1,1
local owned=nil
local function select(index)
    local entry=entries[index];if not entry then return end
    draft={category=entry.category,definition=entry.definition,auxiliary=entry.auxiliary,wear=wear,seed=seed}
    finishes=inventory.finishes(entry.category,entry.definition,1,256) or {}
    paint_index=1
end
select(selection)
local message='Choose a model and finish. Preview does not create an item.'
local function action(fn,...)
    if not cs2.permissions().inventory then message='Enable local inventory changes in Script permissions.';return end
    local ok,result,err=pcall(fn,...)
    if ok and result then message='Saved locally; native application may be pending.';return result end
    message=tostring(ok and err or result)
end
ui.tab('inventory','Inventory studio',function()
    local names={};for _,entry in ipairs(entries) do names[#names+1]=entry.name end
    if #names==0 then imgui.text('Catalog unavailable. Reload after the game schema is ready.');return end
    local changed,index=ui.combo('Weapon',selection,names)
    if changed then selection=index;select(index) end
    local finish_names={'Vanilla'};for _,entry in ipairs(finishes) do finish_names[#finish_names+1]=entry.name end
    changed,paint_index=ui.combo('Finish',paint_index,finish_names)
    draft.paint_kit=paint_index==1 and 0 or finishes[paint_index-1].paint_kit
    changed,wear=ui.slider('Wear',wear,0,1);draft.wear=wear
    changed,seed=ui.slider('Seed',seed,0,1000);draft.seed=math.floor(seed)
    model_preview.draw('Item preview',draft,360,280)
    imgui.text(model_preview.status().message)
    if ui.button('Add local item') then owned=action(inventory.add,draft) or owned end
    if owned then
        if ui.button('Equip CT') then action(inventory.equip,owned,1) end
        imgui.same_line();if ui.button('Equip T') then action(inventory.equip,owned,2) end
        if ui.button('Unequip both') then action(inventory.unequip,owned,3) end
        if ui.button('Remove item') and action(inventory.remove,owned) then owned=nil end
    end
    imgui.text(message)
end)
