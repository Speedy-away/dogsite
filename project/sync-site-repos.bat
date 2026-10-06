@echo off
REM Double-click to sync this repo with its twin. See SYNC-SITE-REPOS.md.
REM Any arguments are passed through, e.g.  sync-site-repos.bat -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-site-repos.ps1" %*
echo.
pause
