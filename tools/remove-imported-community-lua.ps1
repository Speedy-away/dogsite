$ErrorActionPreference = 'Stop'

# Remove only generated Lua downloads named by the current resource catalog.
# Original game-project files and other download categories are not touched.
$downloadRoot = [IO.Path]::GetFullPath('C:\Users\whatw\Documents\GitHub\cool-repo').TrimEnd('\')
$siteRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$siteManifest = Join-Path $siteRoot 'community\data\library.json'
$repoManifest = Join-Path $downloadRoot 'catalog\library.json'
$catalog = Get-Content -LiteralPath $siteManifest -Raw | ConvertFrom-Json
$repoCatalog = Get-Content -LiteralPath $repoManifest -Raw | ConvertFrom-Json
if (($catalog | ConvertTo-Json -Depth 100 -Compress) -ne ($repoCatalog | ConvertTo-Json -Depth 100 -Compress)) {
    throw 'Site and download catalogs must match before removing imported files.'
}
$removed = @($catalog.items | Where-Object { $_.category -eq 'lua' })
$retained = @($catalog.items | Where-Object { $_.category -ne 'lua' })
$retainedPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($item in $retained) {
    foreach ($file in $item.files) { if ($file.path) { [void]$retainedPaths.Add($file.path) } }
}
$targets = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($item in $removed) {
    foreach ($file in $item.files) {
        if (!$file.path -or $retainedPaths.Contains($file.path)) { continue }
        if ($file.path -notmatch '^downloads/(gta5|rdr2|cs2|fivem|redm|l4d)/lua/[^/\\]+$') {
            throw ('Unexpected Lua download path: ' + $file.path)
        }
        $target = [IO.Path]::GetFullPath((Join-Path $downloadRoot $file.path))
        if (!$target.StartsWith($downloadRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Lua download target escapes the requested repository.'
        }
        if (Test-Path -LiteralPath $target) {
            $entry = Get-Item -LiteralPath $target
            if ($entry.PSIsContainer) { throw 'Expected a generated file, not a directory.' }
            $ancestor = $entry
            while ($ancestor -and $ancestor.FullName.StartsWith($downloadRoot, [StringComparison]::OrdinalIgnoreCase)) {
                if ($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to remove a linked download.' }
                if ($ancestor.FullName -eq $downloadRoot) { break }
                $ancestor = Get-Item -LiteralPath (Split-Path -Parent $ancestor.FullName)
            }
            [void]$targets.Add($target)
        }
    }
}
$catalog.items = $retained
$json = ($catalog | ConvertTo-Json -Depth 100 -Compress) + [Environment]::NewLine
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($repoManifest, $json, $utf8)
[IO.File]::WriteAllText($siteManifest, $json, $utf8)
foreach ($target in $targets) { Remove-Item -LiteralPath $target }
Write-Output ('Removed ' + $removed.Count + ' Lua listings and ' + $targets.Count + ' generated download files.')
