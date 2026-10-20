@echo off
setlocal EnableDelayedExpansion
color 0F
echo ======================================================================
echo  Loader VBS/HVCI check -- mirrors src\state\service\vbs_guard.cpp
echo ======================================================================
echo.

REM --------------------------------------------------------------------
REM  Primary: WMI query of Win32_DeviceGuard (same namespace, same props)
REM --------------------------------------------------------------------
echo [1/2] WMI: ROOT\Microsoft\Windows\DeviceGuard  Win32_DeviceGuard
echo       (VirtualizationBasedSecurityStatus, SecurityServicesRunning,
echo        CodeIntegrityPolicyEnforcementStatus)
echo ----------------------------------------------------------------------

set "WMI_OK=0"
set "VBS_STATUS=?"
set "HVCI_RUNNING=0"
set "CI_POLICY=?"
set "SSR_RAW="

for /f "usebackq tokens=1,* delims==" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try {" ^
  "  $dg = Get-CimInstance -Namespace 'ROOT\Microsoft\Windows\DeviceGuard' -ClassName 'Win32_DeviceGuard' -ErrorAction Stop;" ^
  "  Write-Output ('OK=1');" ^
  "  Write-Output ('VBS=' + [int]$dg.VirtualizationBasedSecurityStatus);" ^
  "  Write-Output ('CI='  + [int]$dg.CodeIntegrityPolicyEnforcementStatus);" ^
  "  $arr = @($dg.SecurityServicesRunning);" ^
  "  Write-Output ('SSR=' + ($arr -join ','));" ^
  "  if ($arr -contains 2) { Write-Output 'HVCI=1' } else { Write-Output 'HVCI=0' };" ^
  "} catch { Write-Output 'OK=0'; Write-Output ('ERR=' + $_.Exception.Message) }" `) do (
    if /I "%%A"=="OK"   set "WMI_OK=%%B"
    if /I "%%A"=="VBS"  set "VBS_STATUS=%%B"
    if /I "%%A"=="CI"   set "CI_POLICY=%%B"
    if /I "%%A"=="SSR"  set "SSR_RAW=%%B"
    if /I "%%A"=="HVCI" set "HVCI_RUNNING=%%B"
    if /I "%%A"=="ERR"  echo    WMI ERROR: %%B
)

if "%WMI_OK%"=="1" (
    echo    VirtualizationBasedSecurityStatus = !VBS_STATUS!    ^(0=off 1=configured-not-running 2=RUNNING^)
    echo    SecurityServicesRunning           = [!SSR_RAW!]      ^(1=CG 2=HVCI 3=SysGuard 4=SMM 5=KHWStk 7=HVPT^)
    echo    CodeIntegrityPolicyEnforcementStatus = !CI_POLICY!    ^(not used for trigger - WDAC signal only^)
) else (
    echo    WMI query failed. Falling back to registry.
)
echo.

REM --------------------------------------------------------------------
REM  Fallback: registry probe (loader uses this only when WMI fails,
REM  but we always show it so you can see configured vs running).
REM --------------------------------------------------------------------
echo [2/2] Registry fallback: HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard
echo ----------------------------------------------------------------------

set "REG_VBS=0"
set "REG_HVCI=0"

for /f "tokens=3" %%V in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity 2^>nul ^| findstr /i "EnableVirtualizationBasedSecurity"') do (
    set "REG_VBS=%%V"
)
for /f "tokens=3" %%V in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul ^| findstr /i "Enabled"') do (
    set "REG_HVCI=%%V"
)
echo    DeviceGuard\EnableVirtualizationBasedSecurity        = !REG_VBS!
echo    DeviceGuard\Scenarios\HVCI\Enabled                    = !REG_HVCI!
echo.

REM --------------------------------------------------------------------
REM  Verdict -- EXACT loader rule from vbs_guard.cpp:
REM    vbs_on  = (VirtualizationBasedSecurityStatus == 2)
REM    hvci_on = (SecurityServicesRunning contains 2) AND vbs_on
REM  Banner "Hypervisor / VBS is running" fires if either is true.
REM --------------------------------------------------------------------
echo ======================================================================
echo  VERDICT
echo ======================================================================

set "VBS_ON=0"
set "HVCI_ON=0"
set "SOURCE=WMI"

if "%WMI_OK%"=="1" (
    if "!VBS_STATUS!"=="2"       set "VBS_ON=1"
    if "!HVCI_RUNNING!"=="1" if "!VBS_ON!"=="1" set "HVCI_ON=1"
) else (
    set "SOURCE=REGISTRY"
    if "!REG_VBS!"=="0x1" set "VBS_ON=1"
    if "!REG_HVCI!"=="0x1" if "!VBS_ON!"=="1" set "HVCI_ON=1"
)

echo    Source of truth : !SOURCE!
echo    VBS running     : !VBS_ON!
echo    HVCI running    : !HVCI_ON!
echo.

if "!VBS_ON!"=="1" (
    echo    [TRIGGER] VBS is running  --^> loader will show the red banner.
    if "%WMI_OK%"=="1" (
        echo              Reason: Win32_DeviceGuard.VirtualizationBasedSecurityStatus = !VBS_STATUS!
    ) else (
        echo              Reason: registry EnableVirtualizationBasedSecurity = !REG_VBS!
    )
)
if "!HVCI_ON!"=="1" (
    echo    [TRIGGER] HVCI is running --^> loader will show the red banner.
    if "%WMI_OK%"=="1" (
        echo              Reason: Win32_DeviceGuard.SecurityServicesRunning contains 2  ^(raw=[!SSR_RAW!]^)
    ) else (
        echo              Reason: registry Scenarios\HVCI\Enabled = !REG_HVCI!  ^(and VBS also on^)
    )
)
if "!VBS_ON!"=="0" if "!HVCI_ON!"=="0" (
    echo    [CLEAN] Neither VBS nor HVCI is running. Loader should NOT block.
)

echo.
echo ======================================================================
echo  Extra context ^(not used by loader, informational^):
echo ======================================================================

echo    bcdedit hypervisorlaunchtype:
for /f "tokens=1,*" %%A in ('bcdedit /enum "{current}" 2^>nul ^| findstr /i "hypervisorlaunchtype"') do (
    echo        %%A %%B
)

echo    Hyper-V feature state:
powershell -NoProfile -Command "try { (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor -ErrorAction Stop).State } catch { 'unknown' }" 2>nul

echo.
pause
endlocal
