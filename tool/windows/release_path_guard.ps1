Set-StrictMode -Version Latest

function Resolve-ReleaseAbsolutePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$BasePath = (Get-Location).Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A release path must not be empty.'
    }

    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path $BasePath -ChildPath $Path
    }
    return [System.IO.Path]::GetFullPath($Path)
}

function Normalize-ReleasePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $absolutePath = Resolve-ReleaseAbsolutePath -Path $Path
    $root = [System.IO.Path]::GetPathRoot($absolutePath)
    if ($absolutePath.Length -gt $root.Length) {
        $absolutePath = $absolutePath.TrimEnd([char[]]'\\/')
    }
    return $absolutePath
}

function Test-ReleasePathContains {
    param(
        [Parameter(Mandatory = $true)][string]$Parent,
        [Parameter(Mandatory = $true)][string]$Child
    )

    if ([string]::Equals($Parent, $Child, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    $prefix = $Parent
    if (-not $prefix.EndsWith('\')) {
        $prefix += '\'
    }
    return $Child.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-SafeReleaseOutputPath {
    param(
        [Parameter(Mandatory = $true)][string]$OutputDir,
        [Parameter(Mandatory = $true)][string]$BuildDir,
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$GitDir,
        [Parameter(Mandatory = $true)][string]$GitCommonDir
    )

    try {
        $output = Normalize-ReleasePath -Path $OutputDir
        $protectedPaths = @(
            Normalize-ReleasePath -Path $RepositoryRoot
            Normalize-ReleasePath -Path $GitDir
            Normalize-ReleasePath -Path $GitCommonDir
            Normalize-ReleasePath -Path $BuildDir
        )
    }
    catch {
        throw "Refusing unsafe OutputDir '$OutputDir': $($_.Exception.Message)"
    }

    $driveRoot = [System.IO.Path]::GetPathRoot($output)
    if ([string]::Equals($output, $driveRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing unsafe OutputDir '$output': a drive root must never be removed."
    }

    foreach ($protectedPath in $protectedPaths) {
        if ((Test-ReleasePathContains -Parent $protectedPath -Child $output) -or
            (Test-ReleasePathContains -Parent $output -Child $protectedPath)) {
            throw "Refusing unsafe OutputDir '$output': it overlaps protected path '$protectedPath'."
        }
    }

    return $output
}
