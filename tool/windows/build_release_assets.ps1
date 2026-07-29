# Builds the public Windows installer and portable ZIP for a GitHub Release.

param(
    [string]$OutputDir,
    [switch]$SkipBuild,
    [switch]$SkipInstaller
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "release_path_guard.ps1")
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$pubspec = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot "pubspec.yaml")
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^\s+]+)')
if (-not $versionMatch.Success) {
    throw "Unable to read version from pubspec.yaml"
}
$version = $versionMatch.Groups[1].Value

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path ([System.IO.Path]::GetTempPath()) "lingbi-release-assets-$version"
}
$buildDir = Resolve-ReleaseAbsolutePath -Path "build/windows/x64/runner/Release" -BasePath $repositoryRoot
$gitDirRaw = (& git -C $repositoryRoot rev-parse --git-dir).Trim()
$gitCommonDirRaw = (& git -C $repositoryRoot rev-parse --git-common-dir).Trim()
$gitDir = Resolve-ReleaseAbsolutePath -Path $gitDirRaw -BasePath $repositoryRoot
$gitCommonDir = Resolve-ReleaseAbsolutePath -Path $gitCommonDirRaw -BasePath $repositoryRoot
$OutputDir = Assert-SafeReleaseOutputPath -OutputDir $OutputDir -BuildDir $buildDir -RepositoryRoot $repositoryRoot -GitDir $gitDir -GitCommonDir $gitCommonDir
$portableDir = Join-Path $OutputDir "portable"
$portableZip = Join-Path $OutputDir "Lingbi-Windows-Portable-$version.zip"
$installerName = "Lingbi-Setup-$version.exe"
$installerPath = Join-Path $OutputDir $installerName

if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Push-Location $repositoryRoot
try {
    if (-not $SkipBuild) {
        flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "Flutter release build failed" }
    }

    & (Join-Path $PSScriptRoot "package_release.ps1") -SkipBuild -OutputDir $portableDir
    if ($LASTEXITCODE -ne 0) { throw "Portable package creation failed" }

    Compress-Archive -Path (Join-Path $portableDir "*") -DestinationPath $portableZip -CompressionLevel Optimal

    if (-not $SkipInstaller) {
        $isccCandidates = @(
            (Get-Command iscc.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
            "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
        $iscc = $isccCandidates | Select-Object -First 1
        if (-not $iscc) {
            throw "Inno Setup 6 was not found. Install it or use -SkipInstaller."
        }
        & $iscc "/DLingbiOutputDir=$OutputDir" (Join-Path $repositoryRoot "installer\lingbi_setup.iss")
        if ($LASTEXITCODE -ne 0) { throw "Installer compilation failed" }
        if (-not (Test-Path -LiteralPath $installerPath)) {
            throw "Expected installer was not produced: $installerPath"
        }
    }

    Copy-Item -LiteralPath (Join-Path $portableDir "PROVENANCE.json") -Destination (Join-Path $OutputDir "PROVENANCE.json")
    Remove-Item -LiteralPath $portableDir -Recurse -Force
    $releaseFiles = Get-ChildItem -LiteralPath $OutputDir -File |
        Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
        Sort-Object Name
    $hashLines = foreach ($file in $releaseFiles) {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        "$hash  $($file.Name)"
    }
    [System.IO.File]::WriteAllLines(
        (Join-Path $OutputDir "SHA256SUMS.txt"),
        [string[]]$hashLines,
        (New-Object System.Text.UTF8Encoding($false))
    )
} finally {
    Pop-Location
}

Write-Host "Release assets ready: $OutputDir" -ForegroundColor Green
Get-ChildItem -LiteralPath $OutputDir -File | Select-Object Name, Length
