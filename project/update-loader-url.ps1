#!/usr/bin/env pwsh
# Usage: .\update-loader-url.ps1 https://downloads.example.com/loader
# Configures the authenticated download service; never use a public EXE link.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NewUrl
)

$ErrorActionPreference = 'Stop'

$loaderUri = $null
if (-not [Uri]::TryCreate($NewUrl, [UriKind]::Absolute, [ref]$loaderUri) -or
    $loaderUri.Scheme -ne 'https' -or $loaderUri.UserInfo -or $loaderUri.Query -or $loaderUri.Fragment) {
    Write-Error "Provide the HTTPS download service URL without credentials, a query string, or a fragment."
    exit 1
}

$repo = Split-Path -Parent $PSScriptRoot

$configPath = Join-Path $repo 'portal/loader-download-config.js'
$encodedUrl = ConvertTo-Json -InputObject $loaderUri.AbsoluteUri -Compress
$config = "// Authenticated loader service. This endpoint must validate portal sessions.`nwindow.scoobyLoaderDownloadUrl = $encodedUrl;`n"
Set-Content -LiteralPath $configPath -Value $config -NoNewline -Encoding utf8
Write-Host ("Protected loader service URL set to: {0}" -f $loaderUri.AbsoluteUri)
