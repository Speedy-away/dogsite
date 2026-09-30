@echo off
setlocal
cd /d "%~dp0"
set "SOURCE=%~dp0..\Scooby-Op\CS2\v2"
if defined CS2_LUA_SOURCE_ROOT set "SOURCE=%CS2_LUA_SOURCE_ROOT%"
python "%SOURCE%\tools\sync_lua_site.py" --background --site-root "%~dp0."
if errorlevel 1 pause
