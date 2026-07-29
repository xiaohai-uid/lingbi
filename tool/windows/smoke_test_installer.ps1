# Verifies that the public installer installs, launches, and uninstalls cleanly.

param(
    [Parameter(Mandatory = $true)][string]$InstallerPath,
    [string]$InstallDir
)

$ErrorActionPreference = "Stop"
$InstallerPath = (Resolve-Path -LiteralPath $InstallerPath).Path
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path ([System.IO.Path]::GetTempPath()) "lingbi-installer-smoke-$([guid]::NewGuid().ToString('N'))"
}
$InstallDir = [System.IO.Path]::GetFullPath($InstallDir)

$install = Start-Process -FilePath $InstallerPath -ArgumentList @(
    '/VERYSILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
    '/CURRENTUSER',
    "/DIR=`"$InstallDir`"",
    '/MERGETASKS=!desktopicon'
) -Wait -PassThru -WindowStyle Hidden
if ($install.ExitCode -ne 0) {
    throw "Installer failed with exit code $($install.ExitCode)"
}

$appPath = Join-Path $InstallDir 'lingbi.exe'
if (-not (Test-Path -LiteralPath $appPath)) {
    throw "Installed application was not found: $appPath"
}

$app = Start-Process -FilePath $appPath -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 5
if ($app.HasExited) {
    throw "Installed application exited during startup with code $($app.ExitCode)"
}
Stop-Process -Id $app.Id -Force
$app.WaitForExit()

$uninstaller = Join-Path $InstallDir 'unins000.exe'
if (-not (Test-Path -LiteralPath $uninstaller)) {
    throw "Uninstaller was not found: $uninstaller"
}
$uninstall = Start-Process -FilePath $uninstaller -ArgumentList @(
    '/VERYSILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART'
) -Wait -PassThru -WindowStyle Hidden
if ($uninstall.ExitCode -ne 0) {
    throw "Uninstaller failed with exit code $($uninstall.ExitCode)"
}

for ($attempt = 0; $attempt -lt 20 -and (Test-Path -LiteralPath $appPath); $attempt++) {
    Start-Sleep -Milliseconds 250
}
if (Test-Path -LiteralPath $appPath) {
    throw "Application binary remained after uninstall: $appPath"
}

Write-Host "Installer smoke test passed." -ForegroundColor Green
