-- Downloads data only. Change the URL/path, then click Download.
local url,path='', 'assets/example.bin'
local request,message=nil,'Choose an HTTP/HTTPS URL and a relative save path.'
ui.tab('downloads','Download asset',function()
    local changed
    changed,url=imgui.input_text('URL',url)
    changed,path=imgui.input_text('Save path',path)
    if ui.button('Download') and not request then
        if not cs2.permissions().http or not cs2.permissions().files_write then
            message='Enable HTTP and file writing in Script permissions.'
        else
            local ok,value,err=pcall(http.request,{url=url,max_bytes=1024*1024})
            if ok and value then request=value;message='Downloading...'
            else message=tostring(ok and err or value) end
        end
    end
    if request and ui.button('Cancel') then request:cancel();request=nil;message='Canceled.' end
    imgui.text(message)
end)
events.on('update',function()
    if not request then return end
    local status=request:status()
    if status=='pending' then return end
    if status=='canceled' then request=nil;message='Canceled.';return end
    local ok,response,err=pcall(request.result,request);request=nil
    if not ok or not response then message=tostring(ok and err or response);return end
    if not response.ok then message='HTTP '..response.status;return end
    local saved,value,write_error=pcall(fs.write,path,response.body)
    if saved and value then message='Saved '..#response.body..' bytes to '..path
    else message=tostring(saved and write_error or value) end
end)
-- For a modular updater, download a version/manifest and module files to fs storage.
-- Validate your manifest and version, then explicitly load your entry with fs.load
-- during the next script startup. The module-execution toggle is separate from HTTP.
