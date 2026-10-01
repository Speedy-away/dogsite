# CS2 exported binding index

Generated from host/shared registration and checked editor signatures. UI widgets require a UI callback; render primitives require a frame callback. Host-specific behavior and limits are in the [host contract](/docs/cs2/game-api.md). `widgets` and `ui.widgets` refer to the same table. Standard Lua libraries are documented by Lua 5.4; native hook handles and value-object methods are covered in the host contract and editor definitions.

## base.get

```lua
base.get(id)
```

`id string`; `Returns: boolean?`

## base.log

```lua
base.log(...)
```

`...: any`

## base.set

```lua
base.set(id,value)
```

`id string`; `value boolean`

## capture_protection.get_feature

```lua
capture_protection.get_feature(feature_id) -> mode, blocked
```

`feature_id string`; `Returns: CaptureProtectionMode mode`; `Returns: boolean blocked`

```lua
local id=features.add{id='hud',capture_protection='compatible'}
local mode,blocked=capture_protection.get_feature(id)
```

## capture_protection.is_enabled

```lua
capture_protection.is_enabled() -> boolean
```

`Returns: boolean enabled`

```lua
if capture_protection.is_enabled() then print('Capture Protection is on') end
```

## capture_protection.set_feature

```lua
capture_protection.set_feature(owned_feature_id, 'compatible'|'disable')
```

`owned_feature_id string`; `mode CaptureProtectionMode`

```lua
local id=features.add{id='effect',capture_protection='disable'}
capture_protection.set_feature(id,'disable')
```

## color

```lua
color(r,g,b,a)
```

`r? number`; `g? number`; `b? number`; `a? number`; `Returns: CS2Color`

## colors.from_hex

```lua
colors.from_hex(hex)
```

`hex string`; `Returns: CS2Color`

## colors.from_hsv

```lua
colors.from_hsv(hue_degrees,saturation,value,alpha)
```

`hue_degrees number`; `saturation number`; `value number`; `alpha? number`; `Returns: CS2Color`

## colors.to_hsv

```lua
colors.to_hsv(rgba)
```

`rgba CS2Color|number[]`; `Returns: number,number,number,number`

## commands.available

```lua
commands.available() -> boolean
```

`Returns: boolean`

```lua
print(commands.available()) -- permission state
```

## commands.create

```lua
commands.create(source,options?) -> CommandCallback or nil,error
```

`source string`; `options CommandOptions?`; `Returns: CommandCallback?`; `Returns: string? error`

```lua
local callback=assert(commands.create([[return function(cmd,ctx)
  if game.key_down(1) then cmd.pitch=math.max(-89,math.min(89,cmd.pitch-ctx.recoil.x*2)) end
end]],{enabled=false}))
```

## commands.engine_status

```lua
commands.engine_status() -> {ready,trace,message}
```

`Returns: table`

```lua
print(commands.engine_status().message)
```

## console.clear

```lua
console.clear()
```

```lua
console.clear()
```

## console.error

```lua
console.error(message)
```

`message string`

Log only; use error(message) to raise an actual Lua failure.

```lua
console.error("Could not load custom preferences")
```

## console.log

```lua
console.log(text)
```

`message string`

Log only; use error(message) to raise an actual Lua failure.

```lua
console.log('Script loaded')
```

## console.trace

```lua
console.trace(message)
```

`message string`

Log only; use error(message) to raise an actual Lua failure.

```lua
console.trace("Reached update handler")
```

## console.warn

```lua
console.warn(message)
```

`message string`

Log only; use error(message) to raise an actual Lua failure.

```lua
console.warn("Optional data is unavailable")
```

## cs2.capabilities

```lua
cs2.capabilities() -> table
```

`Returns: table<string,boolean>`

Explicit capabilities; false entries are not implemented by this host.

```lua
print(json.encode(cs2.capabilities()))
```

## cs2.clock

```lua
cs2.clock() -> {curtime,tick,interval,realtime,frame}
```

`Returns: {curtime:number,tick:integer,interval:number,realtime:number,frame:integer}`

```lua
local tick = cs2.clock().tick
```

## cs2.connected

```lua
cs2.connected() -> boolean
```

`Returns: boolean`

```lua
if cs2.connected() then print(cs2.map_name()) end
```

## cs2.info

```lua
cs2.info() -> table
```

`Returns: table`

```lua
print(json.encode(cs2.info()))
```

## cs2.map_name

```lua
cs2.map_name() -> string
```

`Returns: string`

```lua
print(cs2.map_name())
```

## cs2.permissions

```lua
cs2.permissions() -> table
```

`Returns: LuaPermissions`

```lua
print(cs2.permissions().http)
```

## cs2.view_angles

```lua
cs2.view_angles() -> vector or nil
```

`Returns: CS2Vector?`

```lua
local angles = cs2.view_angles()
```

## draw.circle

```lua
draw.circle(x,y,radius,rgba,filled,thickness)
```

`x number`; `y number`; `radius number`; `rgba CS2Color|number[]`; `filled? boolean`; `thickness? number`

## draw.line

```lua
draw.line(x0,y0,x1,y1,rgba,thickness)
```

`x0 number`; `y0 number`; `x1 number`; `y1 number`; `rgba CS2Color|number[]`; `thickness? number`

## draw.rect

```lua
draw.rect(x,y,width,height,rgba,filled,rounding)
```

`x number`; `y number`; `width number`; `height number`; `rgba CS2Color|number[]`; `filled? boolean`; `rounding? number`

## draw.text

```lua
draw.text(x,y,text,rgba,size)
```

`x number`; `y number`; `text string`; `rgba CS2Color|number[]`; `size? number`

## draw.triangle

```lua
draw.triangle(x0,y0,x1,y1,x2,y2,rgba,filled,thickness)
```

`x0 number`; `y0 number`; `x1 number`; `y1 number`; `x2 number`; `y2 number`; `rgba CS2Color|number[]`; `filled? boolean`; `thickness? number`

## engine.delta_time

```lua
engine.delta_time()
```

`Returns: number`

## engine.fps

```lua
engine.fps()
```

`Returns: number`

## engine.time

```lua
engine.time()
```

`Returns: number`

## engine.viewport

```lua
engine.viewport()
```

`Returns: number, number`

## entity.bone

```lua
entity.bone(full_handle, bone_index) -> vector or nil
```

`full_handle integer`; `bone_index integer`; `Returns: CS2Vector?`

```lua
local head = entity.bone(player.handle,6)
```

## entity.get

```lua
entity.get(full_handle) -> player or nil
```

`full_handle integer`; `Returns: CS2Player?`

```lua
local current = entity.get(saved_handle)
```

## entity.get_local_player

```lua
entity.get_local_player() -> player or nil
```

`Returns: CS2Player?`

```lua
local me = entity.get_local_player()
```

## entity.get_players

```lua
entity.get_players(enemies_only=false, alive_only=false) -> players
```

`enemies_only? boolean`; `alive_only? boolean`; `Returns: CS2Player[]`

```lua
for _,p in ipairs(entity.get_players(true,true)) do print(p.name,p.health) end
```

## entity.weapon

```lua
entity.weapon(full_handle) -> weapon snapshot or nil
```

`full_handle integer`; `Returns: CS2Weapon?`

```lua
local gun = entity.weapon(player.handle)
```

## esp_colors.available

```lua
esp_colors.available()
```

`Returns: boolean`

Availability probe. CS2 uses `settings.get/set/list` for native ESP colors.

Returns false in CS2.

## esp_colors.categories

```lua
esp_colors.categories(...)
```

`...: any`; `Returns: any`

Unavailable. CS2 uses `settings.get/set/list` for native ESP colors.

Unavailable in CS2; use settings.get/set/list for native ESP colors.

## esp_colors.enabled

```lua
esp_colors.enabled(...)
```

`...: any`; `Returns: any`

Unavailable. CS2 uses `settings.get/set/list` for native ESP colors.

Unavailable in CS2; use settings.get/set/list for native ESP colors.

## esp_colors.get

```lua
esp_colors.get(...)
```

`...: any`; `Returns: any`

Unavailable. CS2 uses `settings.get/set/list` for native ESP colors.

Unavailable in CS2; use settings.get/set/list for native ESP colors.

## esp_colors.reset

```lua
esp_colors.reset(...)
```

`...: any`; `Returns: any`

Unavailable. CS2 uses `settings.get/set/list` for native ESP colors.

Unavailable in CS2; use settings.get/set/list for native ESP colors.

## esp_colors.set

```lua
esp_colors.set(...)
```

`...: any`; `Returns: any`

Unavailable. CS2 uses `settings.get/set/list` for native ESP colors.

Unavailable in CS2; use settings.get/set/list for native ESP colors.

## events.off

```lua
events.off(token)
```

`token integer`

## events.on

```lua
events.on(event,callback)
```

`event CS2Event`; `callback fun(current?:CS2Player,previous?:CS2Player)`; `Returns: integer token`

## features.active

```lua
features.active(id)
```

`id string`; `Returns: boolean?`

## features.add

```lua
features.add(options)
```

`options {id:string,label?:string,description?:string,category?:string,kind?:string,default?:boolean,key?:string,on_trigger?:function,capture_protection?:CaptureProtectionMode}`; `Returns: string`

## features.bind

```lua
features.bind(id,key,mode)
```

`id string`; `key string`; `mode? string`

## features.color

```lua
features.color(id,r,g,b,a)
```

`id string`; `r number`; `g number`; `b number`; `a? number`

## features.get

```lua
features.get(id)
```

`id string`; `Returns: boolean?`

## features.list

```lua
features.list()
```

`Returns: table[]`

## features.set

```lua
features.set(id,value)
```

`id string`; `value boolean`

## features.trigger

```lua
features.trigger(id)
```

`id string`

## files.delete

```lua
files.delete(name) -> boolean,error?
```

`name string`; `Returns: boolean, string?`

```lua
local removed,err=files.delete("old notes")
```

## files.exists

```lua
files.exists(name) -> boolean
```

`name string`; `Returns: boolean`

```lua
print(files.exists("notes"))
```

## files.list

```lua
files.list() -> names[]
```

`Returns: string[]`

```lua
for _,name in ipairs(files.list()) do print(name) end
```

## files.read

```lua
files.read(name) -> string or nil
```

`name string`; `Returns: string?`

```lua
local text=files.read('notes')
```

## files.write

```lua
files.write(name, text)
```

`name string`; `bytes string`

Binary-safe, at most 65536 bytes. Simple names only; scoped to this script.

```lua
files.write('notes','hello')
```

## fs.exists

```lua
fs.exists(path) -> boolean or nil,error
```

`path string`; `Returns: boolean?`; `Returns: string? error`

```lua
local exists,err=fs.exists('assets/icons')
```

## fs.list

```lua
fs.list(path,recursive=false) -> entries or nil,error
```

`path string`; `recursive boolean?`; `Returns: ScriptFileEntry[]?`; `Returns: string? error`

```lua
for _,entry in ipairs(assert(fs.list('',true))) do print(entry.path,entry.directory,entry.size) end
```

## fs.load

```lua
fs.load(path) -> module_value or nil,error
```

`path string`; `Returns: any`; `Returns: string? error`

```lua
local module=assert(fs.load('modules/helpers.lua'))
```

## fs.mkdir

```lua
fs.mkdir(path) -> true or nil,error
```

`path string`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(fs.mkdir('assets/icons'))
```

## fs.read

```lua
fs.read(path) -> string or nil,error
```

`path string`; `Returns: string?`; `Returns: string? error`

```lua
local data,err=fs.read('profiles/default.json')
```

## fs.remove

```lua
fs.remove(path) -> boolean or nil,error
```

`path string`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(fs.remove('profiles/unused.json'))
```

## fs.rename

```lua
fs.rename(from,to) -> true or nil,error
```

`from string`; `to string`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(fs.rename('profiles/draft.json','profiles/current.json'))
```

## fs.write

```lua
fs.write(path,bytes) -> true or nil,error
```

`path string`; `bytes string`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(fs.write('profiles/default.json',json.encode({enabled=true})))
```

## http.request

```lua
http.request(options) -> HttpRequest or nil,error
```

`options HttpOptions`; `Returns: HttpRequest?`; `Returns: string? error`

```lua
local request=assert(http.request{url='https://example.com/version.json',max_bytes=65536})
```

## imgui.available

```lua
imgui.available()
```

`Returns: number, number`

## imgui.button

```lua
imgui.button(label,width,height)
```

`label string`; `width? number`; `height? number`; `Returns: boolean`

## imgui.checkbox

```lua
imgui.checkbox(label,value)
```

`label string`; `value boolean`; `Returns: boolean, boolean`

## imgui.child

```lua
imgui.child(id,width,height,draw,options)
```

`id string`; `width number`; `height number`; `draw function`; `options? {border?:boolean,padding?:boolean,horizontal_scroll?:boolean}`

## imgui.close_popup

```lua
imgui.close_popup()
```

## imgui.color_edit

```lua
imgui.color_edit(label,rgba)
```

`label string`; `rgba CS2Color|number[]`; `Returns: boolean, CS2Color`

## imgui.combo

```lua
imgui.combo(label,index,items)
```

`label string`; `index integer`; `items string[]`; `Returns: boolean, integer`

One-based index; 1..128 items.

## imgui.combo_custom

```lua
imgui.combo_custom(label,preview,draw)
```

`label string`; `preview string`; `draw function`; `Returns: boolean`

## imgui.cursor

```lua
imgui.cursor()
```

`Returns: number, number`

## imgui.cursor_local

```lua
imgui.cursor_local()
```

`Returns: number, number`

## imgui.disabled

```lua
imgui.disabled(disabled,draw)
```

`disabled boolean`; `draw function`

## imgui.drag_float

```lua
imgui.drag_float(label,value,min,max,speed)
```

`label string`; `value number`; `min number`; `max number`; `speed? number`; `Returns: boolean, number`

## imgui.drag_int

```lua
imgui.drag_int(label,value,min,max,speed)
```

`label string`; `value number`; `min number`; `max number`; `speed? number`; `Returns: boolean, number`

## imgui.dummy

```lua
imgui.dummy(width,height)
```

`width number`; `height number`

## imgui.group

```lua
imgui.group(draw)
```

`draw function`

## imgui.input_text

```lua
imgui.input_text(label,text)
```

`label string`; `text string`; `Returns: boolean, string`

Maximum 4095 UTF-8 bytes.

## imgui.invisible_button

```lua
imgui.invisible_button(id,width,height)
```

`id string`; `width number`; `height number`; `Returns: boolean`

## imgui.is_item_active

```lua
imgui.is_item_active()
```

`Returns: boolean`

## imgui.is_item_clicked

```lua
imgui.is_item_clicked(button)
```

`button? integer`; `Returns: boolean`

Mouse button 0..4; default 0.

## imgui.is_item_hovered

```lua
imgui.is_item_hovered()
```

`Returns: boolean`

## imgui.is_mouse_clicked

```lua
imgui.is_mouse_clicked(button)
```

`button? integer`; `Returns: boolean`

Mouse button 0..4; default 0.

## imgui.is_mouse_down

```lua
imgui.is_mouse_down(button)
```

`button? integer`; `Returns: boolean`

Mouse button 0..4; default 0.

## imgui.is_mouse_released

```lua
imgui.is_mouse_released(button)
```

`button? integer`; `Returns: boolean`

Mouse button 0..4; default 0.

## imgui.item_rect

```lua
imgui.item_rect()
```

`Returns: number, number, number, number`

## imgui.mouse_delta

```lua
imgui.mouse_delta()
```

`Returns: number, number`

## imgui.mouse_pos

```lua
imgui.mouse_pos()
```

`Returns: number, number`

## imgui.open_popup

```lua
imgui.open_popup(id)
```

`id string`

## imgui.popup

```lua
imgui.popup(label,draw)
```

`label string`; `draw function`; `Returns: boolean`

## imgui.progress

```lua
imgui.progress(fraction)
```

`fraction number`

## imgui.radio_button

```lua
imgui.radio_button(label,selected)
```

`label string`; `selected boolean`; `Returns: boolean`

## imgui.same_line

```lua
imgui.same_line(spacing,local_x)
```

`spacing? number`; `local_x? number`

## imgui.selectable

```lua
imgui.selectable(label,selected,width,height)
```

`label string`; `selected boolean`; `width? number`; `height? number`; `Returns: boolean`

## imgui.separator

```lua
imgui.separator()
```

## imgui.set_cursor

```lua
imgui.set_cursor(x,y)
```

`x number`; `y number`

## imgui.set_cursor_screen

```lua
imgui.set_cursor_screen(x,y)
```

`x number`; `y number`

## imgui.set_next_item_width

```lua
imgui.set_next_item_width(width)
```

`width number`

## imgui.slider_float

```lua
imgui.slider_float(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

## imgui.slider_int

```lua
imgui.slider_int(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

## imgui.spacing

```lua
imgui.spacing(height)
```

`height? number`

## imgui.tab_bar

```lua
imgui.tab_bar(label,draw)
```

`label string`; `draw function`; `Returns: boolean`

## imgui.tab_item

```lua
imgui.tab_item(label,draw)
```

`label string`; `draw function`; `Returns: boolean`

## imgui.table

```lua
imgui.table(id,columns,options,draw)
```

`id string`; `columns integer`; `options table`; `draw function`

One to sixteen columns; layout scope restores after errors.

## imgui.table_headers_row

```lua
imgui.table_headers_row()
```

## imgui.table_next_column

```lua
imgui.table_next_column()
```

`Returns: boolean`

## imgui.table_next_row

```lua
imgui.table_next_row(height)
```

`height? number`

## imgui.table_set_column

```lua
imgui.table_set_column(index)
```

`index integer`; `Returns: boolean`

One-based column.

## imgui.table_setup_column

```lua
imgui.table_setup_column(label,width_or_weight,fixed)
```

`label string`; `width_or_weight? number`; `fixed? boolean`

## imgui.text

```lua
imgui.text(text)
```

`text string`

## imgui.text_colored

```lua
imgui.text_colored(text,rgba)
```

`text string`; `rgba CS2Color|number[]`

## imgui.text_size

```lua
imgui.text_size(text)
```

`text string`; `Returns: number, number`

## imgui.text_wrapped

```lua
imgui.text_wrapped(text)
```

`text string`

## imgui.tooltip

```lua
imgui.tooltip(text)
```

`text string`

## imgui.tree

```lua
imgui.tree(label,draw)
```

`label string`; `draw function`; `Returns: boolean`

## imgui.window

```lua
imgui.window(title,options,draw)
```

`title string`; `options table`; `draw function`

## imgui.window_pos

```lua
imgui.window_pos()
```

`Returns: number, number`

## imgui.window_size

```lua
imgui.window_size()
```

`Returns: number, number`

## imgui.with_clip_rect

```lua
imgui.with_clip_rect(x0,y0,x1,y1,draw)
```

`x0 number`; `y0 number`; `x1 number`; `y1 number`; `draw function`

## imgui.with_font_size

```lua
imgui.with_font_size(size,draw)
```

`size number`; `draw function`

## imgui.with_id

```lua
imgui.with_id(id,draw)
```

`id string`; `draw function`

## imgui.with_style

```lua
imgui.with_style(colors,draw)
```

`colors table<string,CS2Color|number[]>`; `draw function`

## imgui.with_style_vars

```lua
imgui.with_style_vars(vars,draw)
```

`vars table`; `draw function`

## input.is_key_down

```lua
input.is_key_down(vk_code) -> boolean
```

`vk_code integer`; `Returns: boolean`

```lua
local held = input.is_key_down(0x56)
```

## input.is_key_pressed

```lua
input.is_key_pressed(vk_code) -> boolean
```

`vk_code integer`; `Returns: boolean`

```lua
if input.is_key_pressed(0x56) then print('V') end
```

## input.menu_open

```lua
input.menu_open() -> boolean
```

`Returns: boolean`

```lua
local editing=input.menu_open()
```

## input.mouse_position

```lua
input.mouse_position() -> x,y
```

`Returns: number, number`

```lua
local x,y=input.mouse_position()
```

## inventory.add

```lua
inventory.add(draft) -> decimal_id or nil,error
```

`draft InventoryDraft`; `Returns: string?`; `Returns: string? error`

```lua
local id=assert(inventory.add{category='weapon',definition=7,wear=.1,seed=1})
```

## inventory.catalog

```lua
inventory.catalog(category,start=1,limit=100) -> entries,total
```

`category string`; `start integer?`; `limit integer?`; `Returns: InventoryCatalogEntry[]`; `Returns: integer total`

```lua
local entries,total=inventory.catalog('weapon',1,100)
```

## inventory.categories

```lua
inventory.categories() -> string[]
```

`Returns: string[]`

```lua
for _,category in ipairs(inventory.categories()) do print(category) end
```

## inventory.equip

```lua
inventory.equip(id,teams=3) -> true or nil,error
```

`id string`; `teams integer?`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(inventory.equip(saved_id,1)) -- CT=1, T=2, both=3
```

## inventory.finishes

```lua
inventory.finishes(category,definition,start=1,limit=100,all=false) -> entries,total
```

`category string`; `definition integer`; `start integer?`; `limit integer?`; `all boolean?`; `Returns: InventoryFinish[]?`; `Returns: integer|string total_or_error`

```lua
local finishes,total=inventory.finishes('weapon',7,1,100)
```

## inventory.get

```lua
inventory.get(id) -> item or nil,error
```

`id string`; `Returns: InventoryItem?`; `Returns: string? error`

```lua
local item,err=inventory.get(saved_id)
```

## inventory.items

```lua
inventory.items(start=1,limit=100) -> items,total
```

`start integer?`; `limit integer?`; `Returns: InventoryItem[]`; `Returns: integer total`

```lua
local owned,total=inventory.items(1,100)
```

## inventory.remove

```lua
inventory.remove(id) -> true or nil,error
```

`id string`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(inventory.remove(saved_id))
```

## inventory.status

```lua
inventory.status() -> {local,native,apply,revision,sticker_slots}
```

`Returns: table`

```lua
local status=inventory.status();print(status['local'],status.native,status.apply)
```

## inventory.unequip

```lua
inventory.unequip(id,teams=3) -> true or nil,error
```

`id string`; `teams integer?`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(inventory.unequip(saved_id,3))
```

## inventory.update

```lua
inventory.update(id,cosmetics) -> true or nil,error
```

`id string`; `cosmetics InventoryCosmetics`; `Returns: boolean?`; `Returns: string? error`

```lua
assert(inventory.update(saved_id,{wear=.2,custom_name='My item'}))
```

## json.array

```lua
json.array(table={}) -> tagged table
```

`value? table`; `Returns: table`

Marks array/object intent; rejects foreign metatables and invalid key types.

```lua
print(json.encode(json.array()))
```

## json.decode

```lua
json.decode(text, preserve_null=false) -> value
```

`text string`; `preserve_null? boolean`; `Returns: any`

Set preserve_null=true to retain null as json.null; default nil for compatibility.

```lua
local value=json.decode('{"health":100}')
```

## json.encode

```lua
json.encode(value) -> string
```

`value any`; `Returns: string`

```lua
print(json.encode({health=100}))
```

## json.object

```lua
json.object(table={}) -> tagged table
```

`value? table`; `Returns: table`

Marks array/object intent; rejects foreign metatables and invalid key types.

```lua
print(json.encode(json.object()))
```

## mathx.angle_fov

```lua
mathx.angle_fov(pitch,yaw,target_pitch,target_yaw) -> number
```

`pitch number`; `yaw number`; `target_pitch number`; `target_yaw number`; `Returns: number`

```lua
local fov=mathx.angle_fov(0,0,10,20)
```

## mathx.angle_vectors

```lua
mathx.angle_vectors(pitch,yaw,roll=0) -> forward,right,up
```

`pitch number`; `yaw number`; `roll? number`; `Returns: CS2Vector, CS2Vector, CS2Vector`

Forward/right/up basis; degrees.

```lua
local forward,right,up=mathx.angle_vectors(0,90)
```

## mathx.approach

```lua
mathx.approach(current,target,max_step) -> number
```

`current number`; `target number`; `max_step number`; `Returns: number`

```lua
print(mathx.approach(0,10,2))
```

## mathx.approach_angle

```lua
mathx.approach_angle(current,target,max_degrees) -> [-180,180)
```

`current number`; `target number`; `max_degrees number`; `Returns: number`

```lua
print(mathx.approach_angle(170,-170,5))
```

## mathx.calc_angle

```lua
mathx.calc_angle(x1,y1,z1,x2,y2,z2) -> vector
```

`x1 number`; `y1 number`; `z1 number`; `x2 number`; `y2 number`; `z2 number`; `Returns: CS2Vector`

```lua
local angles=mathx.calc_angle(0,0,0,100,100,0)
```

## mathx.clamp

```lua
mathx.clamp(value,min,max) -> number
```

`value number`; `min number`; `max number`; `Returns: number`

```lua
local hp=mathx.clamp(player.health,0,100)
```

## mathx.damp

```lua
mathx.damp(current,target,rate,dt=engine.delta_time()) -> number
```

`current number`; `target number`; `rate number`; `dt? number`; `Returns: number`

Exponential damping; rate and dt nonnegative, dt defaults to engine.delta_time().

```lua
local next_value=mathx.damp(0,1,8,1/60)
```

## mathx.distance

```lua
mathx.distance(x1,y1,z1,x2,y2,z2) -> number
```

`x1 number`; `y1 number`; `z1 number`; `x2 number`; `y2 number`; `z2 number`; `Returns: number`

```lua
local d=mathx.distance(0,0,0,3,4,0)
```

## mathx.ease

```lua
mathx.ease(curve,t) -> [0,1]
```

`curve string`; `t number`; `Returns: number`

linear, in_quad, out_quad, in_out_quad, in_cubic, out_cubic, in_out_cubic, in_sine, out_sine, in_out_sine.

```lua
local progress=mathx.ease("in_out_cubic",.5)
```

## mathx.lerp

```lua
mathx.lerp(a,b,t) -> number
```

`a number`; `b number`; `t number`; `Returns: number`

```lua
local alpha=mathx.lerp(0,1,.5)
```

## mathx.lerp_angle

```lua
mathx.lerp_angle(current,target,t) -> [-180,180)
```

`current number`; `target number`; `t number`; `Returns: number`

Shortest arc; result normalized to [-180,180).

```lua
print(mathx.lerp_angle(170,-170,.5))
```

## mathx.normalize_angle

```lua
mathx.normalize_angle(degrees) -> [-180,180)
```

`degrees number`; `Returns: number`

```lua
print(mathx.normalize_angle(270))
```

## mathx.remap

```lua
mathx.remap(value,in_min,in_max,out_min,out_max) -> number
```

`value number`; `in_min number`; `in_max number`; `out_min number`; `out_max number`; `Returns: number`

```lua
local width=mathx.remap(player.health,0,100,0,160)
```

## mathx.remap_clamped

```lua
mathx.remap_clamped(value,in_min,in_max,out_min,out_max) -> number
```

`value number`; `in_min number`; `in_max number`; `out_min number`; `out_max number`; `Returns: number`

```lua
print(mathx.remap_clamped(150,0,100,0,1))
```

## mathx.seconds_to_ticks

```lua
mathx.seconds_to_ticks(seconds) -> nearest integer tick count
```

`seconds number`; `Returns: integer`

```lua
local ticks=mathx.seconds_to_ticks(.5)
```

## mathx.smootherstep

```lua
mathx.smootherstep(t) -> [0,1]
```

`t number`; `Returns: number`

```lua
print(mathx.smootherstep(.5))
```

## mathx.smoothstep

```lua
mathx.smoothstep(t) -> [0,1]
```

`t number`; `Returns: number`

```lua
print(mathx.smoothstep(.5))
```

## mathx.ticks_to_seconds

```lua
mathx.ticks_to_seconds(integer_ticks) -> seconds
```

`ticks integer`; `Returns: number`

```lua
local seconds=mathx.ticks_to_seconds(32)
```

## mathx.vector_angles

```lua
mathx.vector_angles(direction) -> angles or nil
```

`direction CS2Vector`; `Returns: CS2Vector?`

Pitch/yaw/zero roll; nil for the zero vector.

```lua
local angles=mathx.vector_angles(vector(1,1,0))
```

## model_preview.draw

```lua
model_preview.draw(label,id_or_draft,width,height,transparent=false) -> {visible,ready,x1,y1,x2,y2} or nil,error
```

`label string`; `id_or_draft string|InventoryDraft`; `width number`; `height number`; `transparent boolean?`; `Returns: table?`; `Returns: string? error`

```lua
ui.tab('models','Models',function()
  model_preview.draw('AK preview',{category='weapon',definition=7},320,280)
end)
```

## model_preview.status

```lua
model_preview.status() -> {state,message}
```

`Returns: table`

```lua
print(model_preview.status().message)
```

## native.bind

```lua
native.bind(address,signature)
```

`address integer`; `signature CS2NativeSignature`; `Returns: fun(...):any?,string?`

## native.export

```lua
native.export(module,name)
```

`module string`; `name string`; `Returns: integer?,string?`

## native.hook

```lua
native.hook(address,signature,callback_source)
```

`address integer`; `signature CS2NativeSignature`; `callback_source string Returns function(original,...); isolated worker, no parent closures/UI.`; `Returns: CS2NativeHook?,string?`

## native.module

```lua
native.module(module)
```

`module string`; `Returns: {base:integer,size:integer}?,string?`

## native.read

```lua
native.read(address,type)
```

`address integer`; `type CS2NativeType`; `Returns: boolean|number|nil,string?`

## native.read_bytes

```lua
native.read_bytes(address,length)
```

`address integer`; `length integer 1..4096`; `Returns: string?,string?`

## native.relative

```lua
native.relative(address,displacement_offset,instruction_length)
```

`address integer`; `displacement_offset? integer`; `instruction_length? integer`; `Returns: integer?,string?`

## native.scan

```lua
native.scan(module,pattern,occurrence)
```

`module string`; `pattern string Space-separated hex and ?/?? bytes, up to 256 bytes.`; `occurrence? integer 0 requires a unique match; positive values are one-based.`; `Returns: integer?,string?`

## native.vtable

```lua
native.vtable(object_address,zero_based_index)
```

`object_address integer`; `zero_based_index integer`; `Returns: integer?,string?`

## print

```lua
print(...)
```

`...: any`

## rect

```lua
rect(x0,y0,x1,y1)
```

`x0? number`; `y0? number`; `x1? number`; `y1? number`; `Returns: CS2Rect`

## render.arc

```lua
render.arc(x,y,radius,start_degrees,end_degrees,color,thickness=1,segments=48)
```

`x number`; `y number`; `radius number`; `start_degrees number`; `end_degrees number`; `color CS2Color|number[]`; `thickness? number`; `segments? integer`

```lua
events.on('render',function()
  render.arc(90,90,30,-90,180,color(.2,.7,1),3)
end)
```

## render.bezier

```lua
render.bezier(x1,y1,x2,y2,x3,y3,x4,y4,color,thickness=1,segments=32)
```

`x1 number`; `y1 number`; `x2 number`; `y2 number`; `x3 number`; `y3 number`; `x4 number`; `y4 number`; `color CS2Color|number[]`; `thickness? number`; `segments? integer`

```lua
events.on('render',function()
  render.bezier(20,90,60,10,120,10,160,90,color(1,.5,.2),2)
end)
```

## render.circle

```lua
render.circle(x,y,radius,rgba,filled,thickness)
```

`x number`; `y number`; `radius number`; `rgba CS2Color|number[]`; `filled? boolean`; `thickness? number`

## render.gradient

```lua
render.gradient(x,y,w,h,rgba_top,rgba_bottom)
```

`x number`; `y number`; `w number`; `h number`; `rgba_top CS2Color|number[]`; `rgba_bottom CS2Color|number[]`

```lua
render.gradient(20,20,160,40,{.2,.6,.8,1},{.1,.1,.1,1})
```

## render.line

```lua
render.line(x0,y0,x1,y1,rgba,thickness)
```

`x0 number`; `y0 number`; `x1 number`; `y1 number`; `rgba CS2Color|number[]`; `thickness? number`

## render.measure_text

```lua
render.measure_text(text,size=14) -> width,height
```

`text string`; `size? number`; `Returns: number, number`

```lua
local w,h=render.measure_text('CS2',14)
```

## render.polyline

```lua
render.polyline({{x,y},...},color,thickness=1,closed=false)
```

`points number[][]`; `rgba CS2Color|number[]`; `thickness? number`; `closed? boolean`

```lua
render.polyline({{10,10},{30,30},{50,10}},{1,1,1,1})
```

## render.rect

```lua
render.rect(x,y,width,height,rgba,filled,rounding)
```

`x number`; `y number`; `width number`; `height number`; `rgba CS2Color|number[]`; `filled? boolean`; `rounding? number`

## render.scale

```lua
render.scale() -> number
```

`Returns: number`

```lua
local scale=render.scale()
```

## render.screen_size

```lua
render.screen_size() -> width,height
```

`Returns: number,number`

```lua
local width,height=render.screen_size()
```

## render.text

```lua
render.text(x,y,text,rgba,size)
```

`x number`; `y number`; `text string`; `rgba CS2Color|number[]`; `size? number`

## render.theme

```lua
render.theme() -> {accent,text,muted,panel,border}
```

`Returns: {accent:CS2Color,text:CS2Color,muted:CS2Color,panel:CS2Color,border:CS2Color}`

```lua
local colors=render.theme()
```

## render.triangle

```lua
render.triangle(x1,y1,x2,y2,x3,y3,color,filled=true)
```

`x1 number`; `y1 number`; `x2 number`; `y2 number`; `x3 number`; `y3 number`; `rgba CS2Color|number[]`; `filled? boolean`

```lua
render.triangle(20,20,40,20,30,40,{1,1,1,1})
```

## render.world_to_screen

```lua
render.world_to_screen(x,y,z) or render.world_to_screen(vector) -> x,y or nil
```

`x number`; `y number`; `z number`; `Returns: number?,number?`

```lua
local x,y=render.world_to_screen(p.origin.x,p.origin.y,p.origin.z)
```

## script.name

```lua
script.name() -> string
```

`Returns: string`

```lua
print(script.name())
```

## settings.get

```lua
settings.get(feature_id) -> value
```

`feature_id string`; `Returns: any`

```lua
print(settings.get('espEnabled'))
```

## settings.info

```lua
settings.info(feature_id) -> metadata or nil
```

`feature_id string`; `Returns: CS2Setting?`

```lua
print(json.encode(settings.info('espEnabled')))
```

## settings.list

```lua
settings.list(filter='') -> metadata[]
```

`filter? string`; `Returns: CS2Setting[]`

```lua
for _,f in ipairs(settings.list('esp')) do print(f.id,f.type) end
```

## settings.set

```lua
settings.set(feature_id, value)
```

`feature_id string`; `value any`

```lua
settings.set('espEnabled',true)
```

## storage.delete

```lua
storage.delete(key)
```

`key string`

```lua
storage.delete('preferences')
```

## storage.read

```lua
storage.read(key, fallback=nil, preserve_null=false) -> value
```

`key string`; `fallback? any`; `preserve_null? boolean`; `Returns: any`

```lua
local prefs=storage.read('preferences',{enabled=true})
```

## storage.write

```lua
storage.write(key, JSON-compatible value)
```

`key string`; `value any`

```lua
storage.write('preferences',{enabled=true})
```

## timers.after

```lua
timers.after(seconds, callback) -> id
```

`seconds number`; `callback function`; `Returns: integer`

```lua
timers.after(2,function() print('ready') end)
```

## timers.cancel

```lua
timers.cancel(id) -> boolean
```

`id integer`; `Returns: boolean`

```lua
timers.cancel(timer_id)
```

## timers.every

```lua
timers.every(seconds, callback) -> id
```

`seconds number`; `callback function`; `Returns: integer`

```lua
local id=timers.every(1,function() print(cs2.clock().tick) end)
```

## ui.button

```lua
ui.button(label,width,height)
```

`label string`; `width? number`; `height? number`; `Returns: boolean`

## ui.columns

```lua
ui.columns(count,draw,compact)
```

`count integer`; `draw function`; `compact? boolean`

## ui.combo

```lua
ui.combo(label,index,items)
```

`label string`; `index integer`; `items string[]`; `Returns: boolean, integer`

One-based index; 1..128 items.

## ui.entity_colors

```lua
ui.entity_colors()
```

`Returns: boolean`

Availability probe. CS2 uses `settings.get/set/list` for native ESP colors.

Returns false in CS2; use settings for CS2 colors.

## ui.feature

```lua
ui.feature(id)
```

`id string`

## ui.feature_visible

```lua
ui.feature_visible(id,visible)
```

`id string`; `visible boolean`

## ui.group

```lua
ui.group(label,draw)
```

`label string`; `draw function`

## ui.keybind

```lua
ui.keybind(id,label)
```

`id string`; `label? string`

## ui.menu_visible

```lua
ui.menu_visible(visible)
```

`visible? boolean`; `Returns: boolean`

## ui.multi_combo

```lua
ui.multi_combo(label,selected,items)
```

`label string`; `selected boolean[]`; `items string[]`; `Returns: boolean, boolean[]`

Dense selection array with one entry per item.

## ui.next_column

```lua
ui.next_column()
```

## ui.overlay

```lua
ui.overlay(id,draw)
```

`id string`; `draw function`; `Returns: string`

## ui.override

```lua
ui.override(page,draw)
```

`page string`; `draw function`; `Returns: string`

CS2 supports lua/ui and lua/api only.

## ui.reset_theme

```lua
ui.reset_theme()
```

## ui.selectable

```lua
ui.selectable(label,selected,width,height)
```

`label string`; `selected boolean`; `width? number`; `height? number`; `Returns: boolean`

## ui.slider

```lua
ui.slider(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

## ui.slider_int

```lua
ui.slider_int(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

## ui.subtab

```lua
ui.subtab(parent,id,label,draw)
```

`parent string`; `id string`; `label string`; `draw function`; `Returns: string`

## ui.tab

```lua
ui.tab(id,label,draw,metadata)
```

`id string`; `label string`; `draw? function|table`; `metadata? table`; `Returns: string`

Register during script loading. Metadata may be third argument if there is no draw callback.

## ui.theme

```lua
ui.theme(options)
```

`options table`

## ui.toggle

```lua
ui.toggle(label,value)
```

`label string`; `value boolean`; `Returns: boolean, boolean`

## ui.tr

```lua
ui.tr(english_key)
```

`english_key string`; `Returns: string`

## ui.window

```lua
ui.window(id,title,options,draw)
```

`id string`; `title string`; `options table`; `draw function`; `Returns: string`

## ui.window_visible

```lua
ui.window_visible(id,visible)
```

`id string`; `visible? boolean`; `Returns: boolean`

## utils.base64_decode

```lua
utils.base64_decode(text) -> bytes
```

`text string`; `Returns: string`

Strict alphabet and canonical Base64 padding; output at most 65536 bytes.

```lua
print(utils.base64_decode("aGVsbG8="))
```

## utils.base64_encode

```lua
utils.base64_encode(bytes) -> string
```

`bytes string`; `Returns: string`

Binary strings supported; at most 65536 input bytes.

```lua
print(utils.base64_encode("hello"))
```

## utils.fnv1a

```lua
utils.fnv1a(bytes) -> unsigned 32-bit integer
```

`bytes string`; `Returns: integer`

FNV-1a 32-bit hash, not cryptographic.

```lua
print(utils.fnv1a("hello"))
```

## utils.from_bytes

```lua
utils.from_bytes(byte[]) -> string
```

`bytes integer[]`; `Returns: string`

Dense array of integer bytes 0..255.

```lua
print(utils.from_bytes({72,105,0}))
```

## utils.hex_decode

```lua
utils.hex_decode(hex) -> bytes
```

`text string`; `Returns: string`

Strict alphabet and canonical Base64 padding; output at most 65536 bytes.

```lua
print(utils.hex_decode("68656c6c6f"))
```

## utils.hex_encode

```lua
utils.hex_encode(bytes) -> lowercase hex
```

`bytes string`; `Returns: string`

Binary strings supported; at most 65536 input bytes.

```lua
print(utils.hex_encode("hello"))
```

## utils.to_bytes

```lua
utils.to_bytes(string) -> byte[]
```

`bytes string`; `Returns: integer[]`

```lua
local bytes=utils.to_bytes("hello")
```

## utils.unix_time

```lua
utils.unix_time() -> integer seconds since Unix epoch
```

`Returns: integer`

```lua
print(utils.unix_time())
```

## vector

```lua
vector(x,y,z)
```

`x? number`; `y? number`; `z? number`; `Returns: CS2Vector`

## vector2

```lua
vector2(x,y)
```

`x? number`; `y? number Defaults to x.`; `Returns: CS2Vector2`

## widgets.button

```lua
widgets.button(label,width,height)
```

`label string`; `width? number`; `height? number`; `Returns: boolean`

Alias: `ui.widgets.button`.

## widgets.columns

```lua
widgets.columns(count,draw,compact)
```

`count integer`; `draw function`; `compact? boolean`

Alias: `ui.widgets.columns`.

## widgets.combo

```lua
widgets.combo(label,index,items)
```

`label string`; `index integer`; `items string[]`; `Returns: boolean, integer`

One-based index; 1..128 items.

Alias: `ui.widgets.combo`.

## widgets.group

```lua
widgets.group(label,draw)
```

`label string`; `draw function`

Alias: `ui.widgets.group`.

## widgets.multi_combo

```lua
widgets.multi_combo(label,selected,items)
```

`label string`; `selected boolean[]`; `items string[]`; `Returns: boolean, boolean[]`

Dense selection array with one entry per item.

Alias: `ui.widgets.multi_combo`.

## widgets.next_column

```lua
widgets.next_column()
```

Alias: `ui.widgets.next_column`.

## widgets.selectable

```lua
widgets.selectable(label,selected,width,height)
```

`label string`; `selected boolean`; `width? number`; `height? number`; `Returns: boolean`

Alias: `ui.widgets.selectable`.

## widgets.slider

```lua
widgets.slider(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

Alias: `ui.widgets.slider`.

## widgets.slider_int

```lua
widgets.slider_int(label,value,min,max,options)
```

`label string`; `value number`; `min number`; `max number`; `options? {style?:string}`; `Returns: boolean, number`

Alias: `ui.widgets.slider_int`.

## widgets.toggle

```lua
widgets.toggle(label,value)
```

`label string`; `value boolean`; `Returns: boolean, boolean`

Alias: `ui.widgets.toggle`.
