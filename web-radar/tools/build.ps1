param([string]$Configuration='Release', [switch]$Clean)
$ErrorActionPreference='Stop'
$siteRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ($Configuration -notin @('Debug','Release')) { throw 'Unsupported configuration' }
$output=Join-Path $siteRoot "project\build\x64\$Configuration\web-radar"
$log=Join-Path $output 'validation.log'
if($Clean) { if(Test-Path -LiteralPath $log){Remove-Item -LiteralPath $log -Force}; exit 0 }
New-Item -ItemType Directory -Path $output -Force | Out-Null
Push-Location $siteRoot
try {
  foreach($file in @('web-radar/relay/server.mjs','web-radar/relay/avatars.mjs','web-radar/app.mjs','web-radar/render.mjs')) {
    & node --check $file
    if($LASTEXITCODE -ne 0){throw "Syntax check failed: $file"}
  }
  & node --test web-radar/relay/server.test.mjs 2>&1 | Tee-Object -FilePath $log
  if($LASTEXITCODE -ne 0){throw 'Web Radar regression failed'}
} finally { Pop-Location }
