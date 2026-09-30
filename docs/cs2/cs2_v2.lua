---@meta
-- Editor metadata only. Do not run this file. Implementation: src/scripting.
---@class CS2Vector
---@field x number
---@field y number
---@field z number
local Vector = {}
---@return number
function Vector:length() end
---@return number
function Vector:length_sqr() end
---@return number
function Vector:length2d() end
---@return CS2Vector
function Vector:normalized() end
---@return CS2Vector
function Vector:clone() end
---@return number,number,number
function Vector:unpack() end
---@param other CS2Vector
---@return number
function Vector:dot(other) end
---@param other CS2Vector
---@return CS2Vector
function Vector:cross(other) end
---@param other CS2Vector
---@return number
function Vector:distance(other) end
---@param other CS2Vector
---@param t number
---@return CS2Vector
function Vector:lerp(other,t) end
---@param x? number
---@param y? number
---@param z? number
---@return CS2Vector
function vector(x,y,z) end
---@class CS2Weapon
---@field handle integer
---@field definition_index integer
---@field ammo integer
---@field zoom integer
---@field reloading boolean
---@class CS2Player
---@field index integer
---@field handle integer Full pawn handle, including serial.
---@field name string
---@field health integer
---@field armor integer
---@field team integer
---@field ping integer
---@field flags integer
---@field sample_frame integer
---@field flash_duration number
---@field is_local boolean
---@field enemy boolean
---@field alive boolean
---@field scoped boolean
---@field crouched boolean
---@field defusing boolean
---@field helmet boolean
---@field defuser boolean
---@field immune boolean
---@field origin CS2Vector
---@field eye_position CS2Vector
---@field velocity CS2Vector
---@field weapon CS2Weapon?
local Player={}
---@return CS2Player?
function Player:refresh() end
---@return boolean
function Player:is_valid() end
---@param index integer
---@return CS2Vector?
function Player:get_bone(index) end
---@return CS2Weapon?
function Player:get_weapon() end
---@return CS2Vector
function Player:get_origin() end
---@return CS2Vector
function Player:get_eye_position() end
---@return CS2Vector
function Player:get_velocity() end
---@return number
function Player:get_health() end
---@return number
function Player:get_armor() end
---@return string
function Player:get_name() end
---@return boolean
function Player:is_alive() end
---@return boolean
function Player:is_enemy() end
entity={}
---@return CS2Player?
function entity.get_local_player() end
---@param enemies_only? boolean
---@param alive_only? boolean
---@return CS2Player[]
function entity.get_players(enemies_only,alive_only) end
---@param full_handle integer
---@return CS2Player?
function entity.get(full_handle) end
---@param full_handle integer
---@param bone_index integer
---@return CS2Vector?
function entity.bone(full_handle,bone_index) end
---@param full_handle integer
---@return CS2Weapon?
function entity.weapon(full_handle) end
---@class CS2Setting
---@field id string
---@field name string
---@field type string
---@field tab string
---@field group string
---@field min number
---@field max number
---@field choices string[]
---@field value any
settings={}
---@param filter? string
---@return CS2Setting[]
function settings.list(filter) end
---@param feature_id string
---@return CS2Setting?
function settings.info(feature_id) end
---@param feature_id string
---@return any
function settings.get(feature_id) end
---@param feature_id string
---@param value any
function settings.set(feature_id,value) end
cs2={}
---@return table
function cs2.info() end
---@return boolean
function cs2.connected() end
---@return string
function cs2.map_name() end
---@return CS2Vector?
function cs2.view_angles() end
---@return {curtime:number,tick:integer,interval:number,realtime:number,frame:integer}
function cs2.clock() end
---@alias CS2Event 'update'|'render'|'shutdown'|'session_start'|'session_end'|'player_health_changed'|'player_died'|'player_spawned'|'local_weapon_changed'
events={}
---@param event CS2Event
---@param callback fun(current?:CS2Player,previous?:CS2Player)
---@return integer token
function events.on(event,callback) end
---@param token integer
function events.off(token) end

---@class CS2Vector2
---@field x number
---@field y number
local Vector2={}
---@param x? number
---@param y? number Defaults to x.
---@return CS2Vector2
function vector2(x,y) end
---@class CS2Rect
---@field mins CS2Vector2
---@field maxs CS2Vector2
local Rect={}
---@param x0? number
---@param y0? number
---@param x1? number
---@param y1? number
---@return CS2Rect
function rect(x0,y0,x1,y1) end
---@class CS2Color: number[]
local Color={}
---@param r? number
---@param g? number
---@param b? number
---@param a? number
---@return CS2Color
function color(r,g,b,a) end
---@return CS2Vector2
function Vector2:clone() end
---@return number,number
function Vector2:unpack() end
---@return number
function Vector2:length() end
---@return number
function Vector2:length_sqr() end
---@return CS2Vector2
function Vector2:normalized() end
---@param other CS2Vector2
---@return number
function Vector2:dot(other) end
---@param other CS2Vector2
---@return number
function Vector2:distance(other) end
---@param other CS2Vector2
---@param t number
---@return CS2Vector2
function Vector2:lerp(other,t) end
---@return CS2Vector2
function Vector2:floor() end
---@return CS2Vector2
function Vector2:ceil() end
---@return CS2Vector2
function Vector2:round() end
---@return CS2Rect
function Rect:clone() end
---@return number
function Rect:width() end
---@return number
function Rect:height() end
---@return CS2Vector2
function Rect:size() end
---@return CS2Vector2
function Rect:center() end
---@param point_or_rect CS2Vector2|CS2Rect
---@return boolean
function Rect:contains(point_or_rect) end
---@param other CS2Rect
---@return boolean
function Rect:overlaps(other) end
---@param other CS2Rect
---@return CS2Rect?
function Rect:intersect(other) end
---@param delta CS2Vector2
---@return CS2Rect
function Rect:translate(delta) end
---@param amount number
---@return CS2Rect
function Rect:expand(amount) end
---@param amount number
---@return CS2Rect
function Rect:shrink(amount) end
---@return CS2Color
function Color:clone() end
---@return number,number,number,number
function Color:unpack() end
---@param opacity number
---@return CS2Color
function Color:alpha(opacity) end
---@param other CS2Color
---@param t number
---@return CS2Color
function Color:lerp(other,t) end
---@return string
function Color:to_hex() end
---@return number,number,number,number
function Color:to_hsv() end
colors={}
---@param hex string
---@return CS2Color
function colors.from_hex(hex) end
---@param hue_degrees number
---@param saturation number
---@param value number
---@param alpha? number
---@return CS2Color
function colors.from_hsv(hue_degrees,saturation,value,alpha) end
---@param rgba CS2Color|number[]
---@return number,number,number,number
function colors.to_hsv(rgba) end
render={}
---@return number,number
function render.screen_size() end
---@overload fun(position:CS2Vector):number?,number?
---@param x number
---@param y number
---@param z number
---@return number?,number?
function render.world_to_screen(x,y,z) end
---@param x number
---@param y number
---@param radius number
---@param start_degrees number
---@param end_degrees number
---@param color CS2Color|number[]
---@param thickness? number
---@param segments? integer
function render.arc(x,y,radius,start_degrees,end_degrees,color,thickness,segments) end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param x4 number
---@param y4 number
---@param color CS2Color|number[]
---@param thickness? number
---@param segments? integer
function render.bezier(x1,y1,x2,y2,x3,y3,x4,y4,color,thickness,segments) end
mathx={}
---@param degrees number
---@return number
function mathx.normalize_angle(degrees) end
---@param seconds number
---@return integer
function mathx.seconds_to_ticks(seconds) end
---@param ticks integer
---@return number
function mathx.ticks_to_seconds(ticks) end

-- CS2 host 2.4 / native extension 1.0. Fixed Win64 scalar ABI only.
---@alias CS2NativeType 'void'|'bool'|'i32'|'u32'|'i64'|'u64'|'ptr'|'float'|'double'
---@class CS2NativeSignature
---@field abi? 'win64'
---@field returns CS2NativeType
---@field args CS2NativeType[] 0..16 scalar arguments; void is return-only.
---@class CS2NativeStatus
---@field enabled boolean
---@field removed boolean
---@field calls integer
---@field bypassed integer
---@field errors integer
---@field error string
---@field address integer
---@class CS2NativeHook
local NativeHook={}
---@param enabled boolean
function NativeHook:enable(enabled) end
function NativeHook:remove() end
---@param key string
---@param value nil|boolean|number|string
function NativeHook:set(key,value) end
---@param key string
---@return nil|boolean|number|string
function NativeHook:get(key) end
---@return CS2NativeStatus
function NativeHook:status() end
native={version='1.0'}
---@param module string
---@return {base:integer,size:integer}?,string?
function native.module(module) end
---@param module string
---@param name string
---@return integer?,string?
function native.export(module,name) end
---@param module string
---@param pattern string Space-separated hex and ?/?? bytes, up to 256 bytes.
---@param occurrence? integer 0 requires a unique match; positive values are one-based.
---@return integer?,string?
function native.scan(module,pattern,occurrence) end
---@param address integer
---@param displacement_offset? integer
---@param instruction_length? integer
---@return integer?,string?
function native.relative(address,displacement_offset,instruction_length) end
---@param object_address integer
---@param zero_based_index integer
---@return integer?,string?
function native.vtable(object_address,zero_based_index) end
---@param address integer
---@param type CS2NativeType
---@return boolean|number|nil,string?
function native.read(address,type) end
---@param address integer
---@param length integer 1..4096
---@return string?,string?
function native.read_bytes(address,length) end
---@param address integer
---@param signature CS2NativeSignature
---@return fun(...):any?,string?
function native.bind(address,signature) end
---@param address integer
---@param signature CS2NativeSignature
---@param callback_source string Returns function(original,...); isolated worker, no parent closures/UI.
---@return CS2NativeHook?,string?
function native.hook(address,signature,callback_source) end
-- shared exists only inside native hook workers. Parent scripts use hook:get/set.
shared={}
---@param key string
---@return nil|boolean|number|string
function shared.get(key) end
---@param key string
---@param value nil|boolean|number|string
function shared.set(key,value) end

-- Complete host and shared UI exports (API 2.4).
---Explicit capabilities; false entries are not implemented by this host.
---@return table<string,boolean>
function cs2.capabilities() end
utils={}
---Binary strings supported; at most 65536 input bytes.
---@param bytes string
---@return string
function utils.base64_encode(bytes) end
---Strict alphabet and canonical Base64 padding; output at most 65536 bytes.
---@param text string
---@return string
function utils.base64_decode(text) end
---Binary strings supported; at most 65536 input bytes.
---@param bytes string
---@return string
function utils.hex_encode(bytes) end
---Strict alphabet and canonical Base64 padding; output at most 65536 bytes.
---@param text string
---@return string
function utils.hex_decode(text) end
---@param bytes string
---@return integer[]
function utils.to_bytes(bytes) end
---Dense array of integer bytes 0..255.
---@param bytes integer[]
---@return string
function utils.from_bytes(bytes) end
---FNV-1a 32-bit hash, not cryptographic.
---@param bytes string
---@return integer
function utils.fnv1a(bytes) end
---@return integer
function utils.unix_time() end
---@param current number
---@param target number
---@param max_step number
---@return number
function mathx.approach(current,target,max_step) end
---@param current number
---@param target number
---@param max_degrees number
---@return number
function mathx.approach_angle(current,target,max_degrees) end
---Shortest arc; result normalized to [-180,180).
---@param current number
---@param target number
---@param t number
---@return number
function mathx.lerp_angle(current,target,t) end
---@param value number
---@param in_min number
---@param in_max number
---@param out_min number
---@param out_max number
---@return number
function mathx.remap_clamped(value,in_min,in_max,out_min,out_max) end
---@param t number
---@return number
function mathx.smoothstep(t) end
---@param t number
---@return number
function mathx.smootherstep(t) end
---Exponential damping; rate and dt nonnegative, dt defaults to engine.delta_time().
---@param current number
---@param target number
---@param rate number
---@param dt? number
---@return number
function mathx.damp(current,target,rate,dt) end
---linear, in_quad, out_quad, in_out_quad, in_cubic, out_cubic, in_out_cubic, in_sine, out_sine, in_out_sine.
---@param curve string
---@param t number
---@return number
function mathx.ease(curve,t) end
---Forward/right/up basis; degrees.
---@param pitch number
---@param yaw number
---@param roll? number
---@return CS2Vector, CS2Vector, CS2Vector
function mathx.angle_vectors(pitch,yaw,roll) end
---Pitch/yaw/zero roll; nil for the zero vector.
---@param direction CS2Vector
---@return CS2Vector?
function mathx.vector_angles(direction) end
files={}
---@param name string
---@return boolean
function files.exists(name) end
---@param name string
---@return boolean, string?
function files.delete(name) end
json={}
---Marks array/object intent; rejects foreign metatables and invalid key types.
---@param value? table
---@return table
function json.array(value) end
---Marks array/object intent; rejects foreign metatables and invalid key types.
---@param value? table
---@return table
function json.object(value) end
console={}
---Log only; use error(message) to raise an actual Lua failure.
---@param message string
function console.warn(message) end
---Log only; use error(message) to raise an actual Lua failure.
---@param message string
function console.error(message) end
---Log only; use error(message) to raise an actual Lua failure.
---@param message string
function console.trace(message) end
input={}
---@param vk_code integer
---@return boolean
function input.is_key_down(vk_code) end
---@param vk_code integer
---@return boolean
function input.is_key_pressed(vk_code) end
---@return number, number
function input.mouse_position() end
---@return boolean
function input.menu_open() end
timers={}
---@param seconds number
---@param callback function
---@return integer
function timers.after(seconds,callback) end
---@param seconds number
---@param callback function
---@return integer
function timers.every(seconds,callback) end
---@param id integer
---@return boolean
function timers.cancel(id) end
storage={}
---@param key string
---@param fallback? any
---@param preserve_null? boolean
---@return any
function storage.read(key,fallback,preserve_null) end
---@param key string
---@param value any
function storage.write(key,value) end
---@param key string
function storage.delete(key) end
---@param name string
---@return string?
function files.read(name) end
---Binary-safe, at most 65536 bytes. Simple names only; scoped to this script.
---@param name string
---@param bytes string
function files.write(name,bytes) end
---@return string[]
function files.list() end
---@param value any
---@return string
function json.encode(value) end
---Set preserve_null=true to retain null as json.null; default nil for compatibility.
---@param text string
---@param preserve_null? boolean
---@return any
function json.decode(text,preserve_null) end
---@param text string
---@param size? number
---@return number, number
function render.measure_text(text,size) end
---@param x number
---@param y number
---@param w number
---@param h number
---@param rgba_top CS2Color|number[]
---@param rgba_bottom CS2Color|number[]
function render.gradient(x,y,w,h,rgba_top,rgba_bottom) end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param rgba CS2Color|number[]
---@param filled? boolean
function render.triangle(x1,y1,x2,y2,x3,y3,rgba,filled) end
---@param points number[][]
---@param rgba CS2Color|number[]
---@param thickness? number
---@param closed? boolean
function render.polyline(points,rgba,thickness,closed) end
---@return {accent:CS2Color,text:CS2Color,muted:CS2Color,panel:CS2Color,border:CS2Color}
function render.theme() end
---@return number
function render.scale() end
---Log only; use error(message) to raise an actual Lua failure.
---@param message string
function console.log(message) end
function console.clear() end
script={}
---@return string
function script.name() end
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function mathx.distance(x1,y1,z1,x2,y2,z2) end
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return CS2Vector
function mathx.calc_angle(x1,y1,z1,x2,y2,z2) end
---@param pitch number
---@param yaw number
---@param target_pitch number
---@param target_yaw number
---@return number
function mathx.angle_fov(pitch,yaw,target_pitch,target_yaw) end
---@param value number
---@param min number
---@param max number
---@return number
function mathx.clamp(value,min,max) end
---@param a number
---@param b number
---@param t number
---@return number
function mathx.lerp(a,b,t) end
---@param value number
---@param in_min number
---@param in_max number
---@param out_min number
---@param out_max number
---@return number
function mathx.remap(value,in_min,in_max,out_min,out_max) end
ui={}
---@param english_key string
---@return string
function ui.tr(english_key) end
---Register during script loading. Metadata may be third argument if there is no draw callback.
---@param id string
---@param label string
---@param draw? function|table
---@param metadata? table
---@return string
function ui.tab(id,label,draw,metadata) end
---@param parent string
---@param id string
---@param label string
---@param draw function
---@return string
function ui.subtab(parent,id,label,draw) end
---@param id string
---@param draw function
---@return string
function ui.overlay(id,draw) end
---@param id string
---@param title string
---@param options table
---@param draw function
---@return string
function ui.window(id,title,options,draw) end
---CS2 supports lua/ui and lua/api only.
---@param page string
---@param draw function
---@return string
function ui.override(page,draw) end
---@param options table
function ui.theme(options) end
function ui.reset_theme() end
---@param id string
function ui.feature(id) end
---@param id string
---@param label? string
function ui.keybind(id,label) end
---Returns false in CS2; use settings for CS2 colors.
---@return boolean
function ui.entity_colors() end
---@param id string
---@param visible boolean
function ui.feature_visible(id,visible) end
---@param visible? boolean
---@return boolean
function ui.menu_visible(visible) end
---@param id string
---@param visible? boolean
---@return boolean
function ui.window_visible(id,visible) end
---@param label string
---@param draw function
function ui.group(label,draw) end
---@param count integer
---@param draw function
---@param compact? boolean
function ui.columns(count,draw,compact) end
function ui.next_column() end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function ui.slider(label,value,min,max,options) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function ui.slider_int(label,value,min,max,options) end
---@param label string
---@param value boolean
---@return boolean, boolean
function ui.toggle(label,value) end
---@param label string
---@param width? number
---@param height? number
---@return boolean
function ui.button(label,width,height) end
---@param label string
---@param selected boolean
---@param width? number
---@param height? number
---@return boolean
function ui.selectable(label,selected,width,height) end
---One-based index; 1..128 items.
---@param label string
---@param index integer
---@param items string[]
---@return boolean, integer
function ui.combo(label,index,items) end
---Dense selection array with one entry per item.
---@param label string
---@param selected boolean[]
---@param items string[]
---@return boolean, boolean[]
function ui.multi_combo(label,selected,items) end
widgets={}
---@param label string
---@param width? number
---@param height? number
---@return boolean
function widgets.button(label,width,height) end
---@param label string
---@param value boolean
---@return boolean, boolean
function widgets.toggle(label,value) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function widgets.slider(label,value,min,max,options) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function widgets.slider_int(label,value,min,max,options) end
---One-based index; 1..128 items.
---@param label string
---@param index integer
---@param items string[]
---@return boolean, integer
function widgets.combo(label,index,items) end
---Dense selection array with one entry per item.
---@param label string
---@param selected boolean[]
---@param items string[]
---@return boolean, boolean[]
function widgets.multi_combo(label,selected,items) end
---@param label string
---@param selected boolean
---@param width? number
---@param height? number
---@return boolean
function widgets.selectable(label,selected,width,height) end
---@param label string
---@param draw function
function widgets.group(label,draw) end
---@param count integer
---@param draw function
---@param compact? boolean
function widgets.columns(count,draw,compact) end
function widgets.next_column() end
imgui={}
---@param text string
function imgui.text(text) end
---@param text string
---@param rgba CS2Color|number[]
function imgui.text_colored(text,rgba) end
---@param label string
---@param width? number
---@param height? number
---@return boolean
function imgui.button(label,width,height) end
---@param label string
---@param value boolean
---@return boolean, boolean
function imgui.checkbox(label,value) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function imgui.slider_float(label,value,min,max,options) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param options? {style?:string}
---@return boolean, number
function imgui.slider_int(label,value,min,max,options) end
---Maximum 4095 UTF-8 bytes.
---@param label string
---@param text string
---@return boolean, string
function imgui.input_text(label,text) end
---One-based index; 1..128 items.
---@param label string
---@param index integer
---@param items string[]
---@return boolean, integer
function imgui.combo(label,index,items) end
---@param label string
---@param rgba CS2Color|number[]
---@return boolean, CS2Color
function imgui.color_edit(label,rgba) end
---@param spacing? number
---@param local_x? number
function imgui.same_line(spacing,local_x) end
function imgui.separator() end
---@param height? number
function imgui.spacing(height) end
---@param text string
function imgui.tooltip(text) end
---@param fraction number
function imgui.progress(fraction) end
---@param id string
---@param width number
---@param height number
---@param draw function
---@param options? {border?:boolean,padding?:boolean,horizontal_scroll?:boolean}
function imgui.child(id,width,height,draw,options) end
---@param title string
---@param options table
---@param draw function
function imgui.window(title,options,draw) end
---@param disabled boolean
---@param draw function
function imgui.disabled(disabled,draw) end
---@param colors table<string,CS2Color|number[]>
---@param draw function
function imgui.with_style(colors,draw) end
---@return number, number
function imgui.available() end
---@return number, number
function imgui.cursor() end
---@param x number
---@param y number
function imgui.set_cursor(x,y) end
---@return boolean
function imgui.is_item_hovered() end
---@param label string
---@param selected boolean
---@param width? number
---@param height? number
---@return boolean
function imgui.selectable(label,selected,width,height) end
---@param draw function
function imgui.group(draw) end
---@param id string
---@param draw function
function imgui.with_id(id,draw) end
---@param vars table
---@param draw function
function imgui.with_style_vars(vars,draw) end
---@param width number
function imgui.set_next_item_width(width) end
---@param width number
---@param height number
function imgui.dummy(width,height) end
---@return number, number
function imgui.cursor_local() end
---@param x number
---@param y number
function imgui.set_cursor_screen(x,y) end
---@return number, number, number, number
function imgui.item_rect() end
---@return boolean
function imgui.is_item_active() end
---Mouse button 0..4; default 0.
---@param button? integer
---@return boolean
function imgui.is_item_clicked(button) end
---@return number, number
function imgui.mouse_pos() end
---@return number, number
function imgui.mouse_delta() end
---Mouse button 0..4; default 0.
---@param button? integer
---@return boolean
function imgui.is_mouse_down(button) end
---Mouse button 0..4; default 0.
---@param button? integer
---@return boolean
function imgui.is_mouse_clicked(button) end
---Mouse button 0..4; default 0.
---@param button? integer
---@return boolean
function imgui.is_mouse_released(button) end
---@param text string
---@return number, number
function imgui.text_size(text) end
---@return number, number
function imgui.window_pos() end
---@return number, number
function imgui.window_size() end
---@param id string
---@param width number
---@param height number
---@return boolean
function imgui.invisible_button(id,width,height) end
---@param label string
---@param selected boolean
---@return boolean
function imgui.radio_button(label,selected) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param speed? number
---@return boolean, number
function imgui.drag_float(label,value,min,max,speed) end
---@param label string
---@param value number
---@param min number
---@param max number
---@param speed? number
---@return boolean, number
function imgui.drag_int(label,value,min,max,speed) end
---@param text string
function imgui.text_wrapped(text) end
---One to sixteen columns; layout scope restores after errors.
---@param id string
---@param columns integer
---@param options table
---@param draw function
function imgui.table(id,columns,options,draw) end
---@param height? number
function imgui.table_next_row(height) end
---@return boolean
function imgui.table_next_column() end
---One-based column.
---@param index integer
---@return boolean
function imgui.table_set_column(index) end
---@param label string
---@param width_or_weight? number
---@param fixed? boolean
function imgui.table_setup_column(label,width_or_weight,fixed) end
function imgui.table_headers_row() end
---@param label string
---@param draw function
---@return boolean
function imgui.tab_bar(label,draw) end
---@param label string
---@param draw function
---@return boolean
function imgui.tab_item(label,draw) end
---@param id string
function imgui.open_popup(id) end
---@param label string
---@param draw function
---@return boolean
function imgui.popup(label,draw) end
function imgui.close_popup() end
---@param label string
---@param preview string
---@param draw function
---@return boolean
function imgui.combo_custom(label,preview,draw) end
---@param label string
---@param draw function
---@return boolean
function imgui.tree(label,draw) end
---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@param draw function
function imgui.with_clip_rect(x0,y0,x1,y1,draw) end
---@param size number
---@param draw function
function imgui.with_font_size(size,draw) end
---@param x number
---@param y number
---@param text string
---@param rgba CS2Color|number[]
---@param size? number
function render.text(x,y,text,rgba,size) end
---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@param rgba CS2Color|number[]
---@param thickness? number
function render.line(x0,y0,x1,y1,rgba,thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param rgba CS2Color|number[]
---@param filled? boolean
---@param rounding? number
function render.rect(x,y,width,height,rgba,filled,rounding) end
---@param x number
---@param y number
---@param radius number
---@param rgba CS2Color|number[]
---@param filled? boolean
---@param thickness? number
function render.circle(x,y,radius,rgba,filled,thickness) end
draw={}
---@param x number
---@param y number
---@param text string
---@param rgba CS2Color|number[]
---@param size? number
function draw.text(x,y,text,rgba,size) end
---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@param rgba CS2Color|number[]
---@param thickness? number
function draw.line(x0,y0,x1,y1,rgba,thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param rgba CS2Color|number[]
---@param filled? boolean
---@param rounding? number
function draw.rect(x,y,width,height,rgba,filled,rounding) end
---@param x number
---@param y number
---@param radius number
---@param rgba CS2Color|number[]
---@param filled? boolean
---@param thickness? number
function draw.circle(x,y,radius,rgba,filled,thickness) end
---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param rgba CS2Color|number[]
---@param filled? boolean
---@param thickness? number
function draw.triangle(x0,y0,x1,y1,x2,y2,rgba,filled,thickness) end
engine={}
---@return number
function engine.time() end
---@return number
function engine.delta_time() end
---@return number
function engine.fps() end
---@return number, number
function engine.viewport() end
base={}
---@param id string
---@return boolean?
function base.get(id) end
---@param id string
---@param value boolean
function base.set(id,value) end
---@vararg any
function base.log(...) end
features={}
---@param options {id:string,label:string,description?:string,category?:string,kind?:string,default?:boolean,key?:string,mode?:string,callback?:function}
---@return string
function features.add(options) end
---@param id string
---@return boolean?
function features.get(id) end
---@param id string
---@param value boolean
function features.set(id,value) end
---@param id string
---@return boolean?
function features.active(id) end
---@param id string
function features.trigger(id) end
---@return table[]
function features.list() end
---@param id string
---@param key string
---@param mode? string
function features.bind(id,key,mode) end
---@param id string
---@param r number
---@param g number
---@param b number
---@param a? number
function features.color(id,r,g,b,a) end
esp_colors={}
---Returns false in CS2.
---@return boolean
function esp_colors.available() end
---Unavailable in CS2; use settings.get/set/list for native ESP colors.
---@vararg any
---@return any
function esp_colors.enabled(...) end
---Unavailable in CS2; use settings.get/set/list for native ESP colors.
---@vararg any
---@return any
function esp_colors.get(...) end
---Unavailable in CS2; use settings.get/set/list for native ESP colors.
---@vararg any
---@return any
function esp_colors.set(...) end
---Unavailable in CS2; use settings.get/set/list for native ESP colors.
---@vararg any
---@return any
function esp_colors.reset(...) end
---Unavailable in CS2; use settings.get/set/list for native ESP colors.
---@vararg any
---@return any
function esp_colors.categories(...) end

ui.widgets=widgets
---@type userdata
json.null=nil -- Opaque non-nil sentinel at runtime; valid only as a JSON value.

---@type string
CS2_API_VERSION='2.4'
---@type string
UI_API_VERSION='1.1'
---Writes script-prefixed output to the developer console.
---@vararg any
function print(...) end

---@class LuaPermissions
---@field files_read boolean
---@field files_write boolean
---@field http boolean
---@field modules boolean
---@field commands boolean
---@field native boolean
---@field inventory boolean
---@class HttpOptions
---@field url string
---@field method? 'GET'|'HEAD'|'POST'|'PUT'|'PATCH'|'DELETE'
---@field headers? table<string,string>
---@field body? string
---@field max_bytes? integer
---@class HttpResponse
---@field status integer
---@field body string
---@field ok boolean
---@field url string
---@class ScriptFileEntry
---@field path string
---@field directory boolean
---@field size integer
---@class CommandOptions
---@field enabled? boolean
---@class ScriptCommand
---@field number integer Read-only.
---@field pitch number -89..89 degrees.
---@field yaw number -180..180 degrees.
---@field forward number -1..1.
---@field left number -1..1.
---@field up number -1..1.
---@field buttons integer Unsigned 32-bit input mask.
---@field visible boolean Commit visible camera after successful serialization.
---@class CommandVector
---@field x number
---@field y number
---@field z number
---@class CommandPlayer
---@field index integer
---@field handle integer
---@field health integer
---@field armor integer
---@field team integer
---@field enemy boolean
---@field alive boolean
---@field immune boolean
---@field origin CommandVector?
---@field eye CommandVector?
---@class CommandContext
---@field tick integer
---@field time number
---@field interval number
---@field local_player CommandPlayer
---@field players CommandPlayer[]
---@field recoil CommandVector?
---@field velocity CommandVector?
---@field weapon {handle:integer,definition:integer,ammo:integer,reloading:boolean,can_fire:boolean}
---@class InventoryCosmetics
---@field paint_kit? integer
---@field wear? number
---@field seed? integer
---@field stattrak? integer
---@field custom_name? string
---@field stickers? integer[] Exactly four slots.
---@field sticker_wear? number[] Exactly four slots.
---@field charm? integer
---@field charm_seed? integer
---@field charm_offset? number[] Exactly three slots.
---@class InventoryDraft: InventoryCosmetics
---@field category string
---@field definition integer
---@field auxiliary? integer
---@class InventoryItem: InventoryDraft
---@field id string Decimal 64-bit ID.
---@field teams integer CT=1, T=2, both=3.
---@field name string
---@field resource string
---@field rarity integer
---@class InventoryCatalogEntry
---@field category string
---@field definition integer
---@field auxiliary integer
---@field name string
---@field resource string
---@field rarity integer
---@class InventoryFinish
---@field paint_kit integer
---@field name string
---@field rarity integer
---@field old_model boolean

-- Host framework API 2.4. Permissions are set by the user in Scripts.
fs={}
http={}
commands={}
inventory={}
model_preview={}
---@class HttpRequest
HttpRequest={}
---@class CommandCallback
CommandCallback={}
---@class CommandGame
CommandGame={}
---cs2.permissions() -> table
---@return LuaPermissions
function cs2.permissions() end
---fs.read(path) -> string or nil,error
---@param path string
---@return string?
---@return string? error
function fs.read(path) end
---fs.write(path,bytes) -> true or nil,error
---@param path string
---@param bytes string
---@return boolean?
---@return string? error
function fs.write(path,bytes) end
---fs.mkdir(path) -> true or nil,error
---@param path string
---@return boolean?
---@return string? error
function fs.mkdir(path) end
---fs.exists(path) -> boolean or nil,error
---@param path string
---@return boolean?
---@return string? error
function fs.exists(path) end
---fs.list(path,recursive=false) -> entries or nil,error
---@param path string
---@param recursive boolean?
---@return ScriptFileEntry[]?
---@return string? error
function fs.list(path,recursive) end
---fs.rename(from,to) -> true or nil,error
---@param from string
---@param to string
---@return boolean?
---@return string? error
function fs.rename(from,to) end
---fs.remove(path) -> boolean or nil,error
---@param path string
---@return boolean?
---@return string? error
function fs.remove(path) end
---fs.load(path) -> module_value or nil,error
---@param path string
---@return any
---@return string? error
function fs.load(path) end
---http.request(options) -> HttpRequest or nil,error
---@param options HttpOptions
---@return HttpRequest?
---@return string? error
function http.request(options) end
---commands.available() -> boolean
---@return boolean
function commands.available() end
---commands.engine_status() -> {ready,trace,message}
---@return table
function commands.engine_status() end
---commands.create(source,options?) -> CommandCallback or nil,error
---@param source string
---@param options CommandOptions?
---@return CommandCallback?
---@return string? error
function commands.create(source,options) end
---inventory.categories() -> string[]
---@return string[]
function inventory.categories() end
---inventory.catalog(category,start=1,limit=100) -> entries,total
---@param category string
---@param start integer?
---@param limit integer?
---@return InventoryCatalogEntry[]
---@return integer total
function inventory.catalog(category,start,limit) end
---inventory.finishes(category,definition,start=1,limit=100,all=false) -> entries,total
---@param category string
---@param definition integer
---@param start integer?
---@param limit integer?
---@param all boolean?
---@return InventoryFinish[]?
---@return integer|string total_or_error
function inventory.finishes(category,definition,start,limit,all) end
---inventory.items(start=1,limit=100) -> items,total
---@param start integer?
---@param limit integer?
---@return InventoryItem[]
---@return integer total
function inventory.items(start,limit) end
---inventory.get(id) -> item or nil,error
---@param id string
---@return InventoryItem?
---@return string? error
function inventory.get(id) end
---inventory.add(draft) -> decimal_id or nil,error
---@param draft InventoryDraft
---@return string?
---@return string? error
function inventory.add(draft) end
---inventory.update(id,cosmetics) -> true or nil,error
---@param id string
---@param cosmetics InventoryCosmetics
---@return boolean?
---@return string? error
function inventory.update(id,cosmetics) end
---inventory.remove(id) -> true or nil,error
---@param id string
---@return boolean?
---@return string? error
function inventory.remove(id) end
---inventory.equip(id,teams=3) -> true or nil,error
---@param id string
---@param teams integer?
---@return boolean?
---@return string? error
function inventory.equip(id,teams) end
---inventory.unequip(id,teams=3) -> true or nil,error
---@param id string
---@param teams integer?
---@return boolean?
---@return string? error
function inventory.unequip(id,teams) end
---inventory.status() -> {local,native,apply,revision}
---@return table
function inventory.status() end
---model_preview.draw(label,id_or_draft,width,height,transparent=false) -> {visible,ready,x1,y1,x2,y2} or nil,error
---@param label string
---@param id_or_draft string|InventoryDraft
---@param width number
---@param height number
---@param transparent boolean?
---@return table?
---@return string? error
function model_preview.draw(label,id_or_draft,width,height,transparent) end
---model_preview.status() -> {state,message}
---@return table
function model_preview.status() end
---request:status() -> pending|complete|canceled
---@return string
function HttpRequest:status() end
---request:result() -> {status,body,ok,url} or nil,error
---@return HttpResponse?
---@return string? error
function HttpRequest:result() end
---request:cancel()
---@return nil
function HttpRequest:cancel() end
---callback:enable(boolean)
---@param enabled boolean
---@return nil
function CommandCallback:enable(enabled) end
---callback:remove()
---@return nil
function CommandCallback:remove() end
---callback:get(key) -> scalar or nil
---@param key string
---@return any
function CommandCallback:get(key) end
---callback:set(key,scalar_or_nil)
---@param key string
---@param value nil|boolean|integer|number|string
---@return nil
function CommandCallback:set(key,value) end
---callback:status() -> {enabled,removed,failed,calls,replays,error}
---@return table
function CommandCallback:status() end
---game.trace(start,finish) -> {fraction,start_solid,entity,position,normal} or nil,error
---@param start CommandVector
---@param finish CommandVector
---@return table?
function CommandGame.trace(start,finish) end
---game.bone(handle,index) -> {x,y,z} or nil,error
---@param handle integer
---@param index integer
---@return table?
function CommandGame.bone(handle,index) end
---game.key_down(virtual_key) -> boolean
---@param virtual_key integer
---@return boolean
function CommandGame.key_down(virtual_key) end
