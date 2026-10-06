@echo off
setlocal

set "URL=%~1"
if "%URL%"=="" (
    set /p "URL=Enter new loader URL: "
)

if "%URL%"=="" (
    echo No URL provided.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-loader-url.ps1" "%URL%"
set "RC=%ERRORLEVEL%"

echo.
pause
exit /b %RC%
