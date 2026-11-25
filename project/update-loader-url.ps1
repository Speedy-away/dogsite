#!/usr/bin/env pwsh
# Usage: .\update-loader-url.ps1 https://scoobymenu.cc/assets/downloads/ScoobyLoader.exe
# Configures the public file fetched by the signed-in portal download button.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NewUrl
)

$ErrorActionPreference = 'Stop'

$loaderUri = $null
if (-not [Uri]::TryCreate($NewUrl, [UriKind]::Absolute, [ref]$loaderUri) -or
    $loaderUri.Scheme -ne 'https' -or $loaderUri.UserInfo -or $loaderUri.Query -or $loaderUri.Fragment) {
    Write-Error "Provide the HTTPS loader file URL without credentials, a query string, or a fragment."
    exit 1
}

$repo = Split-Path -Parent $PSScriptRoot

$configPath = Join-Path $repo 'portal/loader-download-config.js'
$encodedUrl = ConvertTo-Json -InputObject $loaderUri.AbsoluteUri -Compress
$config = "// Public loader file. Portal sign-in controls the download button.`nwindow.scoobyLoaderDownloadUrl = $encodedUrl;`n"
Set-Content -LiteralPath $configPath -Value $config -NoNewline -Encoding utf8
Write-Host ("Portal loader file URL set to: {0}" -f $loaderUri.AbsoluteUri)
