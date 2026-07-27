# LingBi Windows Release Packaging Script
# Produces deterministic release artifacts and checksums.
# Code-signing is BLOCKED_EXTERNAL until a genuine certificate is provided.

param(
    [string]$OutputDir = "build/windows/release-package",
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
$buildDir = "build/windows/x64/runner/Release"
if (-not (Test-Path $buildDir)) {
    $buildDir = "build/windows/runner/Release"
}
if (-not (Test-Path $buildDir)) {
    Write-Error "Release build not found at $buildDir"
    exit 1
}

if (Test-Path $OutputDir) { Remove-Item -Recurse -Force $OutputDir }
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Copy-Item -Recurse "$buildDir/*" $OutputDir

# Step 3: Generate checksums
Write-Host "[3/4] Generating checksums..." -ForegroundColor Yellow
$checksumFile = "$OutputDir/SHA256SUMS.txt"
Get-ChildItem $OutputDir -Recurse -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" } | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    "$hash  $($_.Name)" | Out-File -Append $checksumFile
}

# Step 4: Code signing (BLOCKED)
Write-Host "[4/4] Code signing..." -ForegroundColor Yellow
Write-Host "  STATUS: BLOCKED_EXTERNAL" -ForegroundColor Red
Write-Host "  REASON: No code-signing certificate configured." -ForegroundColor Red
Write-Host "  ACTION: Provide a genuine EV/OV certificate to enable signing." -ForegroundColor Red
Write-Host "  WARNING: Unsigned executables will trigger SmartScreen warnings." -ForegroundColor Red

Write-Host ""
Write-Host "=== Package ready at: $OutputDir ===" -ForegroundColor Green
Write-Host "=== Code signing: BLOCKED_EXTERNAL ===" -ForegroundColor Red
