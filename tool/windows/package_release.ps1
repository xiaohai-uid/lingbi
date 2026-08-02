# LingBi Windows Release Packaging Script
# Produces deterministic release artifacts and checksums.
# Code-signing is BLOCKED_EXTERNAL until a genuine certificate is provided.

param(
    [string]$OutputDir,
    [string]$BuildDir = "build/windows/x64/runner/Release",
    [switch]$SkipBuild,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "release_path_guard.ps1")

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\\..")).Path
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path ([System.IO.Path]::GetTempPath()) "lingbi-release-package"
}

function Resolve-GitPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return Resolve-ReleaseAbsolutePath -Path $Path
    }
    return Resolve-ReleaseAbsolutePath -Path $Path -BasePath $repositoryRoot
}

$gitDir = Resolve-GitPath -Path ((& git -C $repositoryRoot rev-parse --git-dir).Trim())
$gitCommonDir = Resolve-GitPath -Path ((& git -C $repositoryRoot rev-parse --git-common-dir).Trim())
$requestedBuildDir = Resolve-ReleaseAbsolutePath -Path $BuildDir -BasePath $repositoryRoot
$resolvedBuildDir = $requestedBuildDir
if (-not (Test-Path -LiteralPath $resolvedBuildDir) -and $BuildDir -eq "build/windows/x64/runner/Release") {
    $resolvedBuildDir = Resolve-ReleaseAbsolutePath -Path "build/windows/runner/Release" -BasePath $repositoryRoot
}
$resolvedOutputDir = Assert-SafeReleaseOutputPath -OutputDir $OutputDir -BuildDir $resolvedBuildDir -RepositoryRoot $repositoryRoot -GitDir $gitDir -GitCommonDir $gitCommonDir

if ($ValidateOnly) {
    Write-Host "Release output path is safe: $resolvedOutputDir"
    exit 0
}

Write-Host "=== LingBi Windows Release Packaging ===" -ForegroundColor Cyan

# Step 1: Build
if (-not $SkipBuild) {
    Write-Host "[1/4] Building release..." -ForegroundColor Yellow
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
}

# Step 2: Collect artifacts
Write-Host "[2/4] Collecting artifacts..." -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath $resolvedBuildDir)) {
    Write-Error "Release build not found at $resolvedBuildDir"
    exit 1
}

if (Test-Path -LiteralPath $resolvedOutputDir) { Remove-Item -Recurse -Force -LiteralPath $resolvedOutputDir }
New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null
Get-ChildItem -LiteralPath $resolvedBuildDir | Copy-Item -Destination $resolvedOutputDir -Recurse -Force

# Step 3: Generate provenance and relative-path checksums
Write-Host "[3/4] Generating provenance and checksums..." -ForegroundColor Yellow
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$pubspec = Get-Content -Raw -LiteralPath "pubspec.yaml"
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^\s]+)')
if (-not $versionMatch.Success) {
    Write-Error "Unable to read version from pubspec.yaml"
    exit 1
}
$sourceCommit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    Write-Error "Unable to resolve source commit"
    exit 1
}
$sourceRef = $env:GITHUB_REF_NAME
if ([string]::IsNullOrWhiteSpace($sourceRef)) {
    # `git branch --show-current` returns nothing on a detached HEAD (e.g. a
    # worktree checkout), so guard against a null result before calling .Trim().
    $branchRaw = (& git branch --show-current | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($branchRaw)) {
        $abbrevRaw = (& git rev-parse --abbrev-ref HEAD | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($abbrevRaw) -or $abbrevRaw -eq 'HEAD') {
            $sourceRef = 'detached'
        } else {
            $sourceRef = $abbrevRaw
        }
    } else {
        $sourceRef = $branchRaw
    }
}
$dirtyOutput = (& git status --porcelain) -join "`n"
$provenance = [ordered]@{
    schema_version = 1
    application = "lingbi"
    version = $versionMatch.Groups[1].Value
    source_commit = $sourceCommit
    source_ref = $sourceRef
    source_dirty = -not [string]::IsNullOrWhiteSpace($dirtyOutput)
    build_configuration = "release"
    platform = "windows-x64"
}
$provenancePath = Join-Path $resolvedOutputDir "PROVENANCE.json"
$provenanceJson = $provenance | ConvertTo-Json
[System.IO.File]::WriteAllText($provenancePath, "$provenanceJson`n", $utf8NoBom)

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '')
    } finally {
        $sha256.Dispose()
    }
}

$outputUri = New-Object System.Uri(($resolvedOutputDir.TrimEnd('\') + '\'))
$checksumLines = Get-ChildItem -LiteralPath $resolvedOutputDir -Recurse -File |
    Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
    ForEach-Object {
        $fileUri = New-Object System.Uri($_.FullName)
        $relativePath = [System.Uri]::UnescapeDataString($outputUri.MakeRelativeUri($fileUri).ToString())
        [pscustomobject]@{
            Path = $relativePath
            Line = "$(Get-Sha256Hex -Path $_.FullName)  $relativePath"
        }
    } |
    Sort-Object Path |
    Select-Object -ExpandProperty Line
$checksumFile = Join-Path $resolvedOutputDir "SHA256SUMS.txt"
[System.IO.File]::WriteAllLines($checksumFile, [string[]]$checksumLines, $utf8NoBom)

# Step 4: Code signing (BLOCKED)
Write-Host "[4/4] Code signing..." -ForegroundColor Yellow
Write-Host "  STATUS: BLOCKED_EXTERNAL" -ForegroundColor Red
Write-Host "  REASON: No code-signing certificate configured." -ForegroundColor Red
Write-Host "  ACTION: Provide a genuine EV/OV certificate to enable signing." -ForegroundColor Red
Write-Host "  WARNING: Unsigned executables will trigger SmartScreen warnings." -ForegroundColor Red

Write-Host ""
Write-Host "=== Package ready at: $resolvedOutputDir ===" -ForegroundColor Green
Write-Host "=== Code signing: BLOCKED_EXTERNAL ===" -ForegroundColor Red
