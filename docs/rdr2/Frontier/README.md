# Vesper for Scooby RDR2

A standalone Lua window with player and horse recovery actions, a live status/HUD, up to 30 named travel locations with a return action, weather/time controls, and saved preferences. It runs inside Scooby RDR2; it is not a separate executable or a GTA script.

## Install

Requires **Scooby Lua API 2.1.0** or a compatible newer 2.x host, using either Lua54 or LuaJIT. Copy the entire **Frontier** folder into `C:\scooby\RDR2\lua\Frontier` so `main.lua` is directly inside that folder. Refresh the Lua manager, then enable Vesper. Refresh preserves running scripts; Reload restarts the selected state.

Open/close with **F7** or **LB/L1 + D-pad Down**. The host's Vesper tab can also reopen the window. The custom charcoal interface has original line icons, rounded teal-outline action buttons, violet selection highlights, pill switches, custom slider rails/thumbs, larger headings, padded cards and separate keybind/player widgets on wide screens. Narrower screens use a single scrolling column. ImGui supplies input and keyboard focus under the custom drawing. It requests the cursor while open and restores the host style after each draw callback.

The script is now named **Vesper**. Keep the existing Frontier installation folder and internal module/config names to retain script-owned bookmarks and preferences. This is the RDR2 edition; the separate GTA V package uses its own game API.

## Controls and features

- Mouse: select a page and click an action.
- Controller: LB/RB or D-pad Left/Right changes pages, Up/Down selects an action, A/Cross runs it, B/Circle closes. Release buttons after opening/reconnecting/refocusing before using them. Close the host menu for Vesper controller navigation.
- Player & horse: refill current player health/stamina, clear wanted level, refill the currently ridden horse's health/stamina.
- Travel: save the current coordinates, select/cycle a location, travel, return, or remove it. Travel includes the current mount or driven vehicle; passenger vehicle travel is refused. Saved coordinates retain their exact height. There is no guessed waypoint ground or built-in location database.
- World: choose weather and clock values; controller actions cycle weather and six-hour presets. Clear either override explicitly. Normal script stop clears overrides set by Vesper. Other scripts and the game share these world settings; Vesper cannot restore another script's hidden override state.
- Settings: compact HUD, km/h or mph, save, hide. Bookmarks/preferences use Scooby's script-owned Config storage; no gameplay action runs automatically on load.

Game calls run in script tasks. Render callbacks read cached snapshots and queue actions. No spawned entities or continuously applied invincibility are left behind. Abrupt game shutdown may prevent native cleanup; that host limitation is described in the runtime guide.

## Validation

The package has contract tests on Lua54 and LuaJIT using the production scheduler, ImGui bindings and native marshaller with fixture game data. Fixture validation does not establish physical controller, game-native, DX12/Vulkan or FPS acceptance. Test those paths with the exact built host before claiming a supported game build.

The source package lives under `RDR2/Lua/Frontier`; `tools/validate-frontier.ps1` in the RDR2 host builds/runs its contract check. Website downloads are generated from this folder.
