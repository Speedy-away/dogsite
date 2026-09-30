-- Asynchronous HTTP/HTTPS asset downloads, scoped to this script's lua-data folder.
-- For an updater, download a version manifest, compare versions, then save a chosen payload.
-- fs.load can load a saved Lua module during the next script startup when Modules is allowed.
local url=""
local path="assets/download.bin"
local request=nil
local message="Enter an HTTP/HTTPS URL and a relative destination."
local function start()
    if not cs2.permissions().http then message="Enable HTTP / HTTPS in Script permissions first.";return end
    if not cs2.permissions().files_write then message="Enable writing script files first.";return end
    local ok,value,err=pcall(http.request,{url=url,method="GET",max_bytes=1024*1024})
    if not ok then message=tostring(value);return end
    if not value then message=tostring(err);return end
    request=value;message="Downloading..."
end
ui.tab("downloads","Asset download manager",function()
    local changed,value=imgui.input_text("URL",url);if changed and not request then url=value end
    changed,value=imgui.input_text("Save path",path);if changed and not request then path=value end
    if not request then
        if imgui.button("Download and save") then start() end
    elseif imgui.button("Cancel download") then request:cancel();request=nil;message="Canceled" end
    imgui.text_wrapped(message)
    if imgui.button("List saved files") then
        local ok,files,err=pcall(fs.list,"",true)
        if ok and files then
            message=tostring(#files).." files/folders. Paths were written to Console."
            for _,file in ipairs(files) do console.log(file.path..(file.directory and "/" or "  "..file.size.." bytes")) end
        else message=tostring(ok and err or files) end
    end
end)
events.on("update",function()
    if not request then return end
    local status=request:status()
    if status=="pending" then return end
    if status=="canceled" then request=nil;message="Canceled or HTTP permission was disabled.";return end
    local ok,response,err=pcall(request.result,request);request=nil
    if not ok then message=tostring(response);return end
    if not response then message=tostring(err);return end
    if not response.ok then message="HTTP "..response.status.."; destination was not changed.";return end
    local saved,result,reason=pcall(fs.write,path,response.body)
    message=saved and result and ("Saved "..#response.body.." bytes to "..path) or tostring(saved and reason or result)
end)
events.on("shutdown",function() if request then request:cancel() end end)
