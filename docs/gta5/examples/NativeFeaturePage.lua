-- This page appears in BOTH ClickUI > Lua Content and ListUI > Lua Content.
-- Every row is the existing host command: main UI and hotkeys stay in sync.
local page = assert(features.add_page('My Self Tools', {'godmode'}))

-- Add more exact IDs discovered with features.list(). IDs differ by game.
-- Remove early with features.remove_page(page). Unloading removes it too.
script.on_unload(function() features.remove_page(page) end)
