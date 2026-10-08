#!/usr/bin/env pwsh
# Usage:  .\update-loader-url.ps1 https://filego.at/bucket/<new-id>
# Replaces every occurrence of the current loader URL across the site.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NewUrl
)

$ErrorActionPreference = 'Stop'

if ($NewUrl -notmatch '^https?://') {
    Write-Error "URL must start with http:// or https://"
    exit 1
}

$repo = Split-Path -Parent $PSScriptRoot

$targets = @(
    @{ Path = 'portal/index.html'; Pattern = '(<a class="dashboard-button portal-loader-link" href=")([^"]+)(")'; Build = { param($u) "`${1}$u`${3}" } }
)

$totalReplacements = 0

foreach ($t in $targets) {
    $full = Join-Path $repo $t.Path
    if (-not (Test-Path $full)) {
        Write-Warning "Missing file: $($t.Path)"
        continue
    }

    $content = Get-Content -Raw -LiteralPath $full
    $replacement = & $t.Build $NewUrl
    $new = [regex]::Replace($content, $t.Pattern, $replacement)

    if ($new -ne $content) {
        Set-Content -LiteralPath $full -Value $new -NoNewline -Encoding utf8
        $count = ([regex]::Matches($content, $t.Pattern)).Count
        $totalReplacements += $count
        Write-Host ("Updated {0} ({1} occurrence(s))" -f $t.Path, $count)
    } else {
        Write-Host ("No change in {0}" -f $t.Path)
    }
}

Write-Host ""
Write-Host ("Done. Loader URL set to: {0}" -f $NewUrl)
Write-Host ("Total replacements: {0}" -f $totalReplacements)
