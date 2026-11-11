param([switch]$Extract)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$source = 'project/community-menu-sources'
$stage = "$source/cherax-theme-artwork-downloads"
$downloadIndex = Get-Content -LiteralPath (Join-Path $workspace "$source/cherax-downloads/asset-index.json") -Raw | ConvertFrom-Json -Depth 60
$reviews = @{}
$reviewPath = Join-Path $workspace "$source/cherax-theme-artwork-review.json"
if (Test-Path -LiteralPath $reviewPath) {
    $review = Get-Content -LiteralPath $reviewPath -Raw | ConvertFrom-Json -Depth 20
    foreach ($entry in $review.entries) { $reviews[$entry.assetKey] = $entry }
}
$missing = @{}
foreach ($asset in $downloadIndex.assets) {
    if ($asset.category -eq 'themes' -and $asset.role -eq 'thumbnail' -and !$asset.previewEligible) {
        $missing[$asset.resourceId] = $true
    }
}

function Get-ImageFormat($bytes) {
    if ($bytes.Length -lt 12) { throw 'Truncated artwork image' }
    $prefix = [Convert]::ToHexString($bytes, 0, 12)
    if ($prefix.StartsWith('89504E470D0A1A0A')) { return @('.png', 'PNG', 'image/png') }
    if ($prefix.StartsWith('FFD8FF')) { return @('.jpg', 'JPEG', 'image/jpeg') }
    if ($prefix.StartsWith('474946383761') -or $prefix.StartsWith('474946383961')) { return @('.gif', 'GIF', 'image/gif') }
    if ($prefix.StartsWith('52494646') -and $prefix.EndsWith('57454250')) { return @('.webp', 'WEBP', 'image/webp') }
    throw 'Unknown artwork image signature'
}

$archives = 0
$records = @(
    foreach ($asset in $downloadIndex.assets) {
        if ($asset.role -ne 'payload' -or !$missing.ContainsKey($asset.resourceId)) { continue }
        $archives++
        $archivePath = Join-Path $workspace $asset.localPath
        $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($archiveHash -ne $asset.actual.sha256) { throw "Theme archive checksum changed for $($asset.name)" }
        $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
        try {
            foreach ($member in $archive.Entries) {
                if (!$member.Length -or $member.FullName -notmatch '\.(jpg|jpeg|png|gif|webp)$') { continue }
                $name = $member.FullName.Replace('\','/')
                if ($name -match '^/|:|(?:^|/)\.\.?(/|$)' -or
                    (($member.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000 -or
                    ($member.ExternalAttributes -band 0x400) -or $member.Length -gt 32MB) {
                    throw "Unsafe image member in $($asset.name)"
                }
                $stream = $member.Open()
                $buffer = [byte[]]::new([int]$member.Length)
                try {
                    $stream.ReadExactly($buffer)
                    if ($stream.ReadByte() -ne -1) { throw 'Artwork exceeds its ZIP directory length' }
                } finally { $stream.Dispose() }
                $extension, $magic, $mime = Get-ImageFormat $buffer
                $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($buffer)).ToLowerInvariant()
                $relative = "previews/gta5/menus/cherax/$($hash.Substring(0, 20))$extension"
                $localPath = "$stage/assets/$relative"
                if ($Extract) {
                    $destination = Join-Path $workspace $localPath
                    $folder = [IO.Path]::GetDirectoryName($destination)
                    [void][IO.Directory]::CreateDirectory($folder)
                    $ancestor = Get-Item -LiteralPath $folder
                    while ($ancestor -and $ancestor.FullName -ne $workspace) {
                        if ($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked staging directory rejected' }
                        $ancestor = $ancestor.Parent
                    }
                    if (Test-Path -LiteralPath $destination) {
                        $existing = Get-Item -LiteralPath $destination
                        if (($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
                            (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
                            throw "Artwork staging path collision: $relative"
                        }
                    } else {
                        $outputStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
                        try { $outputStream.Write($buffer) } finally { $outputStream.Dispose() }
                    }
                }
                $assetKey = "theme-artwork:$($asset.sourceId):$name"
                $entry = $reviews[$assetKey]
                $verified = $entry -and $entry.sha256 -eq $hash -and $entry.archiveSha256 -eq $archiveHash
                [ordered]@{
                    assetKey = $assetKey
                    resourceId = $asset.resourceId; sourceId = $asset.sourceId; sourceMenu = 'Cherax'
                    name = $asset.name; category = 'themes'; role = 'thumbnail'; status = 'downloaded'
                    sourceCatalog = $asset.sourceCatalog; sourceURL = $asset.sourceURL
                    originalName = [IO.Path]::GetFileName($name)
                    targetRelativePath = $relative; stagedRelativePath = "assets/$relative"; localPath = $localPath
                    expectedKind = 'image'; publisherThumbnailKind = 'source_theme_artwork'
                    previewEligible = [bool]($verified -and $entry.eligible)
                    visualReview = if ($verified) { $entry.observation } else { $null }
                    actual = [ordered]@{size = $buffer.Length; sha256 = $hash; extension = $extension; magic = $magic; contentType = $mime}
                    provenance = @([ordered]@{archiveSha256 = $archiveHash; archiveMember = $name; sourceURL = $asset.sourceURL})
                }
            }
        } finally { $archive.Dispose() }
    }
)

if ($Extract) {
    $indexPath = Join-Path $workspace "$stage/asset-index.json"
    Set-Content -LiteralPath (Join-Path $workspace "$stage/.gitignore") -Value '*','!.gitignore' -Encoding utf8NoBOM
    [ordered]@{schemaVersion = 1; sourceMenu = 'Cherax'; stageDirectory = $stage; assets = $records} |
        ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $indexPath -Encoding utf8NoBOM
}
[ordered]@{archives = $archives; themesWithArtwork = @($records.resourceId | Sort-Object -Unique).Count; images = $records.Count; staged = [bool]$Extract} |
    ConvertTo-Json -Compress
