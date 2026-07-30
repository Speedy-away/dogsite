@echo off
REM Double-click to sync this repo with its twin. See SYNC.md.
REM Any arguments are passed through, e.g.  sync.bat -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync.ps1" %*
echo.
pause
