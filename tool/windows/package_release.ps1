# LingBi Windows Release Packaging Script
# Produces deterministic release artifacts and checksums.
# Code-signing is BLOCKED_EXTERNAL until a genuine certificate is provided.

param(
    [string]$OutputDir = "build/windows/release-package",
    [string]$BuildDir = "build/windows/x64/runner/Release",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

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
$resolvedBuildDir = $BuildDir
if (-not (Test-Path -LiteralPath $resolvedBuildDir) -and $BuildDir -eq "build/windows/x64/runner/Release") {
    $resolvedBuildDir = "build/windows/runner/Release"
}
if (-not (Test-Path -LiteralPath $resolvedBuildDir)) {
    Write-Error "Release build not found at $resolvedBuildDir"
    exit 1
}

if (Test-Path -LiteralPath $OutputDir) { Remove-Item -Recurse -Force -LiteralPath $OutputDir }
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Get-ChildItem -LiteralPath $resolvedBuildDir | Copy-Item -Destination $OutputDir -Recurse -Force

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
    $sourceRef = (& git branch --show-current).Trim()
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
$provenancePath = Join-Path $OutputDir "PROVENANCE.json"
$provenanceJson = $provenance | ConvertTo-Json
[System.IO.File]::WriteAllText($provenancePath, "$provenanceJson`n", $utf8NoBom)

$resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
$outputUri = New-Object System.Uri(($resolvedOutputDir.TrimEnd('\') + '\'))
$checksumLines = Get-ChildItem -LiteralPath $OutputDir -Recurse -File |
    Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
    ForEach-Object {
        $fileUri = New-Object System.Uri($_.FullName)
        $relativePath = [System.Uri]::UnescapeDataString($outputUri.MakeRelativeUri($fileUri).ToString())
        [pscustomobject]@{
            Path = $relativePath
            Line = "$(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash)  $relativePath"
        }
    } |
    Sort-Object Path |
    Select-Object -ExpandProperty Line
$checksumFile = Join-Path $OutputDir "SHA256SUMS.txt"
[System.IO.File]::WriteAllLines($checksumFile, [string[]]$checksumLines, $utf8NoBom)

# Step 4: Code signing (BLOCKED)
Write-Host "[4/4] Code signing..." -ForegroundColor Yellow
Write-Host "  STATUS: BLOCKED_EXTERNAL" -ForegroundColor Red
Write-Host "  REASON: No code-signing certificate configured." -ForegroundColor Red
Write-Host "  ACTION: Provide a genuine EV/OV certificate to enable signing." -ForegroundColor Red
Write-Host "  WARNING: Unsigned executables will trigger SmartScreen warnings." -ForegroundColor Red

Write-Host ""
Write-Host "=== Package ready at: $OutputDir ===" -ForegroundColor Green
Write-Host "=== Code signing: BLOCKED_EXTERNAL ===" -ForegroundColor Red
