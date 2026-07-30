#Requires -Version 5.1
<#
    sync.ps1 - Mirror the site between the dogsite and scooby-site repos.

    The two repos hold identical site content but have unrelated git histories,
    so this syncs the WORKING TREE (files), not commits. See SYNC.md.

    Usage:
        .\sync.ps1                 Auto-detect which side changed, sync, commit, push
        .\sync.ps1 -From dog       Force direction: dogsite  -> scooby-site
        .\sync.ps1 -From scooby    Force direction: scooby-site -> dogsite
        .\sync.ps1 -DryRun         Show what would change, touch nothing
        .\sync.ps1 -Pull           git pull --ff-only both repos first
        .\sync.ps1 -NoPush         Commit locally but do not push
        .\sync.ps1 -Force          Skip the "target has uncommitted work" guard
        .\sync.ps1 -Message "..."  Custom commit message
#>
[CmdletBinding()]
param(
    [string]$From = 'auto',
    [string]$Message = '',
    [string]$DogsitePath = '',
    [string]$ScoobyPath = '',
    [switch]$Pull,
    [switch]$DryRun,
    [switch]$NoPush,
    [switch]$Force
)

# Native git writes progress to stderr; keep that from turning into a hard stop.
$ErrorActionPreference = 'Continue'

# Directories that must never cross between the repos.
#   .git    - each repo keeps its own history and its own remote
#   backup/ - local-only backup, gitignored, deliberately not published
$ExcludedDirs = @('.git', 'backup')

# ---------------------------------------------------------------- helpers ---

function Write-Step  { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Note  { param([string]$m) Write-Host "    $m" -ForegroundColor DarkGray }
function Write-Ok    { param([string]$m) Write-Host "    $m" -ForegroundColor Green }
function Write-Warn2 { param([string]$m) Write-Host "!!  $m" -ForegroundColor Yellow }

function Fail {
    param([string]$m)
    Write-Host ""
    Write-Host "ABORTED: $m" -ForegroundColor Red
    Write-Host ""
    exit 1
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string[]]$GitArgs
    )
    $raw = & git -C $Repo @GitArgs 2>&1
    return [pscustomobject]@{
        Code = $LASTEXITCODE
        Out  = ($raw | Out-String).Trim()
    }
}

function Assert-GitRepo {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) { Fail "$Label not found at $Path" }
    $r = Invoke-Git -Repo $Path -GitArgs @('rev-parse', '--is-inside-work-tree')
    if ($r.Code -ne 0 -or $r.Out -ne 'true') { Fail "$Label at $Path is not a git repository" }
}

function Test-Dirty {
    param([string]$Repo)
    $r = Invoke-Git -Repo $Repo -GitArgs @('status', '--porcelain')
    return -not [string]::IsNullOrWhiteSpace($r.Out)
}

function Get-Branch {
    param([string]$Repo)
    return (Invoke-Git -Repo $Repo -GitArgs @('rev-parse', '--abbrev-ref', 'HEAD')).Out
}

function Get-TreeHash {
    param([string]$Repo)
    return (Invoke-Git -Repo $Repo -GitArgs @('rev-parse', 'HEAD^{tree}')).Out
}

function Get-CommitEpoch {
    param([string]$Repo)
    $r = Invoke-Git -Repo $Repo -GitArgs @('log', '-1', '--format=%ct')
    if ($r.Code -ne 0 -or -not ($r.Out -match '^\d+$')) { return 0 }
    return [int64]$r.Out
}

# Newest mtime across the working tree, ignoring .git / backup. Used to break
# the tie when both repos are clean but their commits differ.
function Get-NewestFileTime {
    param([string]$Repo)
    $newest = [datetime]'1900-01-01'
    Get-ChildItem -LiteralPath $Repo -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $rel = $_.FullName.Substring($Repo.Length).TrimStart('\')
            $top = ($rel -split '\\')[0]
            $ExcludedDirs -notcontains $top
        } |
        ForEach-Object {
            if ($_.LastWriteTime -gt $newest) { $newest = $_.LastWriteTime }
        }
    return $newest
}

# Stop if the local repo is behind its remote - pushing on top of that would
# silently drop whatever was committed on GitHub.
function Sync-WithRemote {
    param([string]$Repo, [string]$Label)

    $branch = Get-Branch -Repo $Repo
    Write-Note "$Label`: fetching origin/$branch"
    $f = Invoke-Git -Repo $Repo -GitArgs @('fetch', '--quiet', 'origin')
    if ($f.Code -ne 0) {
        Write-Warn2 "$Label`: fetch failed (offline?). Continuing on local state."
        return
    }

    $verify = Invoke-Git -Repo $Repo -GitArgs @('rev-parse', '--verify', "origin/$branch")
    if ($verify.Code -ne 0) {
        Write-Note "$Label`: no origin/$branch yet, skipping remote check"
        return
    }

    $counts = (Invoke-Git -Repo $Repo -GitArgs @('rev-list', '--left-right', '--count', "origin/$branch...HEAD")).Out
    $parts  = $counts -split '\s+'
    if ($parts.Count -lt 2) { return }
    $behind = [int]$parts[0]
    $ahead  = [int]$parts[1]

    if ($behind -eq 0) {
        if ($ahead -gt 0) { Write-Note "$Label`: $ahead commit(s) ahead of origin" }
        return
    }

    if ($Pull) {
        Write-Note "$Label`: $behind behind, pulling --ff-only"
        $p = Invoke-Git -Repo $Repo -GitArgs @('pull', '--ff-only', 'origin', $branch)
        if ($p.Code -ne 0) {
            Fail "$Label is $behind commit(s) behind origin and --ff-only failed (history diverged). Resolve by hand:`n  git -C `"$Repo`" pull"
        }
        Write-Ok "$Label`: pulled"
    }
    elseif ($Force) {
        Write-Warn2 "$Label is $behind commit(s) behind origin - continuing because -Force was given"
    }
    else {
        Fail "$Label is $behind commit(s) behind origin/$branch. Re-run with -Pull to fetch those commits first."
    }
}

function Save-Repo {
    param([string]$Repo, [string]$Label, [string]$CommitMessage)

    $null = Invoke-Git -Repo $Repo -GitArgs @('add', '-A')
    $staged = Invoke-Git -Repo $Repo -GitArgs @('diff', '--cached', '--quiet')
    if ($staged.Code -eq 0) {
        Write-Note "$Label`: nothing to commit"
        return $false
    }

    $c = Invoke-Git -Repo $Repo -GitArgs @('commit', '-m', $CommitMessage)
    if ($c.Code -ne 0) { Fail "$Label`: commit failed`n$($c.Out)" }
    $short = (Invoke-Git -Repo $Repo -GitArgs @('rev-parse', '--short', 'HEAD')).Out
    Write-Ok "$Label`: committed $short"
    return $true
}

function Push-Repo {
    param([string]$Repo, [string]$Label)

    $branch = Get-Branch -Repo $Repo
    $p = Invoke-Git -Repo $Repo -GitArgs @('push', 'origin', "HEAD:$branch")
    if ($p.Code -ne 0) { Fail "$Label`: push failed`n$($p.Out)" }
    Write-Ok "$Label`: pushed to origin/$branch"
}

# ------------------------------------------------------------ locate repos ---

$scriptDir  = Split-Path -Parent $PSCommandPath
$githubRoot = Split-Path -Parent $scriptDir

if ([string]::IsNullOrWhiteSpace($DogsitePath)) { $DogsitePath = Join-Path $githubRoot 'dogsite' }
if ([string]::IsNullOrWhiteSpace($ScoobyPath))  { $ScoobyPath  = Join-Path $githubRoot 'scooby-site' }

$DogsitePath = (Resolve-Path -LiteralPath $DogsitePath -ErrorAction SilentlyContinue).Path
$ScoobyPath  = (Resolve-Path -LiteralPath $ScoobyPath  -ErrorAction SilentlyContinue).Path

if (-not $DogsitePath) { Fail "dogsite repo not found. Pass -DogsitePath <path>." }
if (-not $ScoobyPath)  { Fail "scooby-site repo not found. Pass -ScoobyPath <path>." }

Assert-GitRepo -Path $DogsitePath -Label 'dogsite'
Assert-GitRepo -Path $ScoobyPath  -Label 'scooby-site'

Write-Host ""
Write-Step "Repos"
Write-Note "dogsite     $DogsitePath"
Write-Note "scooby-site $ScoobyPath"

# --------------------------------------------------------- pick a direction ---

Write-Host ""
Write-Step "Checking remotes"
Sync-WithRemote -Repo $DogsitePath -Label 'dogsite'
Sync-WithRemote -Repo $ScoobyPath  -Label 'scooby-site'

$dogDirty    = Test-Dirty -Repo $DogsitePath
$scoobyDirty = Test-Dirty -Repo $ScoobyPath

$normalized = $From.ToLower()
if ($normalized -like '*dog*') {
    $srcPath = $DogsitePath; $srcName = 'dogsite'
    $dstPath = $ScoobyPath;  $dstName = 'scooby-site'
    $reason  = 'explicit -From'
}
elseif ($normalized -like '*scoob*') {
    $srcPath = $ScoobyPath;  $srcName = 'scooby-site'
    $dstPath = $DogsitePath; $dstName = 'dogsite'
    $reason  = 'explicit -From'
}
elseif ($normalized -ne 'auto' -and $normalized -ne '') {
    Fail "Unrecognised -From value '$From'. Use 'dog', 'scooby', or leave it off for auto."
}
else {
    # Auto-detect.
    if ($dogDirty -and $scoobyDirty) {
        Fail "Both repos have uncommitted changes, so the direction is ambiguous.`nPick one explicitly:  .\sync.ps1 -From dog    (or)    .\sync.ps1 -From scooby"
    }
    elseif ($dogDirty) {
        $srcPath = $DogsitePath; $srcName = 'dogsite'
        $dstPath = $ScoobyPath;  $dstName = 'scooby-site'
        $reason  = 'uncommitted changes in dogsite'
    }
    elseif ($scoobyDirty) {
        $srcPath = $ScoobyPath;  $srcName = 'scooby-site'
        $dstPath = $DogsitePath; $dstName = 'dogsite'
        $reason  = 'uncommitted changes in scooby-site'
    }
    else {
        # Both clean. Identical content means there is nothing to do.
        if ((Get-TreeHash -Repo $DogsitePath) -eq (Get-TreeHash -Repo $ScoobyPath)) {
            Write-Host ""
            Write-Ok "Already in sync - both repos are clean and their content is identical."
            Write-Host ""
            exit 0
        }
        $dogTime    = Get-CommitEpoch -Repo $DogsitePath
        $scoobyTime = Get-CommitEpoch -Repo $ScoobyPath
        if ($dogTime -eq $scoobyTime) {
            # Same commit timestamp but different content - fall back to file mtimes.
            $dogTime    = [int64](Get-NewestFileTime -Repo $DogsitePath).Ticks
            $scoobyTime = [int64](Get-NewestFileTime -Repo $ScoobyPath).Ticks
        }
        if ($dogTime -eq $scoobyTime) {
            Fail "Repo contents differ but neither side looks newer. Pick a direction:`n  .\sync.ps1 -From dog    (or)    .\sync.ps1 -From scooby"
        }
        if ($dogTime -gt $scoobyTime) {
            $srcPath = $DogsitePath; $srcName = 'dogsite'
            $dstPath = $ScoobyPath;  $dstName = 'scooby-site'
        }
        else {
            $srcPath = $ScoobyPath;  $srcName = 'scooby-site'
            $dstPath = $DogsitePath; $dstName = 'dogsite'
        }
        $reason = 'newer commit / newer files'
    }
}

$dstDirty = Test-Dirty -Repo $dstPath

Write-Host ""
Write-Step "Direction"
Write-Host "    $srcName  ->  $dstName" -ForegroundColor White
Write-Note "reason: $reason"

if ($dstDirty -and -not $Force -and -not $DryRun) {
    Fail "$dstName has uncommitted changes that this sync would overwrite.`nCommit or discard them there first, or re-run with -Force to overwrite them."
}
if ($dstDirty -and $Force) {
    Write-Warn2 "$dstName has uncommitted changes - -Force given, they will be overwritten"
}

# ------------------------------------------------------------- commit source ---

if ([string]::IsNullOrWhiteSpace($Message)) {
    $stamp   = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $Message = "sync from $srcName ($stamp)"
}

if (-not $DryRun) {
    Write-Host ""
    Write-Step "Committing source"
    $null = Save-Repo -Repo $srcPath -Label $srcName -CommitMessage $Message
}

# -------------------------------------------------------------- mirror files ---

Write-Host ""
if ($DryRun) { Write-Step "Mirroring files (dry run - nothing is written)" }
else         { Write-Step "Mirroring files" }

$rcArgs = @($srcPath, $dstPath, '/MIR', '/R:2', '/W:1', '/NJH', '/NJS', '/NP')
foreach ($d in $ExcludedDirs) {
    $rcArgs += @('/XD', (Join-Path $srcPath $d), (Join-Path $dstPath $d))
}
if ($DryRun) { $rcArgs += '/L' }
else         { $rcArgs += @('/NFL', '/NDL') }

& robocopy.exe @rcArgs | Out-Host
$rc = $LASTEXITCODE

# Robocopy: 0-7 are success codes, 8+ mean real failures.
if ($rc -ge 8) { Fail "robocopy failed with exit code $rc" }

if ($DryRun) {
    Write-Host ""
    if ($rc -eq 0) { Write-Ok "Dry run complete - the repos already match, nothing would change." }
    else           { Write-Ok "Dry run complete - the files listed above WOULD be synced. Nothing was written." }
    Write-Note "Run .\sync.ps1 without -DryRun to apply."
    Write-Host ""
    exit 0
}

if ($rc -eq 0) { Write-Note "no file differences" }
else           { Write-Ok "files mirrored (robocopy code $rc)" }

# ------------------------------------------------------------- commit target ---

Write-Host ""
Write-Step "Committing target"
$null = Save-Repo -Repo $dstPath -Label $dstName -CommitMessage $Message

# --------------------------------------------------------------------- push ---

if ($NoPush) {
    Write-Host ""
    Write-Warn2 "-NoPush given - commits stay local. Push later with: git -C `"<repo>`" push"
}
else {
    Write-Host ""
    Write-Step "Pushing"
    Push-Repo -Repo $srcPath -Label $srcName
    Push-Repo -Repo $dstPath -Label $dstName
}

# ------------------------------------------------------------------- verify ---

Write-Host ""
Write-Step "Verify"
$dogTree    = Get-TreeHash -Repo $DogsitePath
$scoobyTree = Get-TreeHash -Repo $ScoobyPath

if ($dogTree -eq $scoobyTree) {
    Write-Ok "Both repos now hold identical content (tree $($dogTree.Substring(0,10)))"
}
else {
    Write-Warn2 "Tree hashes still differ - dogsite $($dogTree.Substring(0,10)) vs scooby-site $($scoobyTree.Substring(0,10))"
    Write-Note "Inspect with: git -C `"$DogsitePath`" status"
}

Write-Host ""
Write-Ok "Done."
Write-Host ""
