# Vesper

Load `Vesper.lua` in Scooby's Lua manager with the `Vesper/` directory alongside it. Requires GUI API 2026.10.1; LuaJIT is already included in Scooby. In-game acceptance on each GTA build remains required.

F6 opens/closes the workspace; F7 toggles the speedometer; F8 toggles keybinds. An XInput controller can use LB + RB + X. Mouse interaction is handled by the standalone window. Gameplay controls are suppressed while it is open; it opens immediately after loading.

Features: health/armour/clean/wanted tools; vehicle repair, wash, upright, engine, doors, automatic repair, primary/secondary RGB paint and plate; three saved locations and map waypoint travel; eight weather presets and time controls; speedometer with KM/H or MPH, coordinates, crosshair, local-player health/armour, keybinds and status badge. Filter controls with the search box. Settings save display preferences and location slots. Gameplay toggles start off.

Vehicle edits require the current driver seat. Buttons queue work to a script fiber and resolve current handles when executed. The script removes callbacks, stops per-frame effects and releases its own weather override on unload. One-shot health, vehicle, location and clock edits persist as normal game actions.

Vesper uses original vector assets, a V monogram, charcoal cards, violet switches and sliders, and rounded buttons with thin green outlines. Dropdowns, RGB sliders, color swatches and HUD bars are drawn by the Lua UI. ImGui supplies input, text editing and the rendering backend. Slider values can be dragged or adjusted with Left/Right when focused. Narrow windows stack the control cards and scroll. Feature concepts were compared with Jackz Vehicles (https://github.com/Jackzmc/stand-lua-scripts), the speedometer/teleport collections in https://github.com/0x2XPx/2Take1-script-Archive, and the local Cherax PaintLabs/Vehicle Forge references. This package is an original Scooby implementation; those menus' scripts are not imported or auto-run.

`model.lua` owns UI state/action queues; `host.lua` contains game access; `ui.lua` renders the interface; `assets.lua` contains the original vector logo and icons. Extend a feature through the queue and keep native work out of render callbacks.

Renamed from Scooby Studio. Replace the old entry and module folder with `Vesper.lua` and `Vesper/`, and unload the old script before loading Vesper. Internal `studio.options` and `studio.bookmarks` keys are retained. Scooby scopes saved config to the script, so the renamed entry may start with fresh saved preferences.
