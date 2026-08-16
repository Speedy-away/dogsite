@echo off
REM ---------------------------------------------------------------
REM  Local preview server for the Scooby site.
REM
REM  Double-click this file to view the site properly.
REM
REM  Do NOT open the .html files directly - the pages link to each
REM  other with root-relative URLs (/guides, /docs, /assets/...).
REM  Opened as file:// those resolve to the root of your drive, so
REM  every link 404s and the CSS never loads. Served over http://
REM  they resolve correctly, exactly like the live site.
REM ---------------------------------------------------------------
setlocal

REM Serve this script's folder no matter where it was launched from.
cd /d "%~dp0"

REM Find a Python launcher.
set "PY="
where py >nul 2>&1 && set "PY=py"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY where python3 >nul 2>&1 && set "PY=python3"

if not defined PY (
  echo.
  echo   Python was not found.
  echo.
  echo   Install it from https://www.python.org/downloads/
  echo   and tick "Add python.exe to PATH" during setup.
  echo.
  pause
  exit /b 1
)

REM Step past any port that is already in use.
set "PORT=8080"
:findport
netstat -a -n -o | findstr /r /c:"TCP.*:%PORT% .*LISTENING" >nul 2>&1
if not errorlevel 1 (
  set /a PORT+=1
  if %PORT% GEQ 8100 (
    echo   Could not find a free port between 8080 and 8099.
    pause
    exit /b 1
  )
  goto findport
)

REM Give the server a couple of seconds before the browser opens, so the
REM first page load succeeds instead of showing "connection refused".
start "" cmd /c "ping -n 3 127.0.0.1 >nul & start http://localhost:%PORT%/"

echo.
echo   Scooby site - local preview
echo   ---------------------------------------------
echo   Serving : %CD%
echo   URL     : http://localhost:%PORT%/
echo.
echo   Your browser will open in a moment.
echo   Leave this window open while you browse.
echo   Press Ctrl+C (or close this window) to stop.
echo.

%PY% -m http.server %PORT%

echo.
echo   Server stopped.
pause
