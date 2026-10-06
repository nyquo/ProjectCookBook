<#
.SYNOPSIS
    Configures (first time only) and builds one CMake preset from CMakePresets.json.

.EXAMPLE
    .\scripts\build.ps1 android-arm64-v8a
    Builds the APK for 64-bit phones and prints its path.

.EXAMPLE
    .\scripts\build.ps1 desktop -Fresh
    Wipes the CMake cache and rebuilds the Windows desktop version.
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('desktop', 'android-x86_64', 'android-arm64-v8a', 'android-armeabi-v7a')]
    [string]$Preset,

    # Re-run CMake configuration from scratch.
    [switch]$Fresh
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$root = Split-Path $PSScriptRoot
Write-Host "==> $Preset  (Qt $(Split-Path -Leaf $env:QT_VERSION_DIR), NDK $(Split-Path -Leaf $env:ANDROID_NDK_ROOT))" -ForegroundColor Cyan

Push-Location $root
try {
    # CMake and Gradle print warnings on stderr. Failures are caught through
    # $LASTEXITCODE below, so don't let Windows PowerShell treat stderr as an error.
    $ErrorActionPreference = 'Continue'

    if ($Fresh -or -not (Test-Path "build\$Preset\CMakeCache.txt")) {
        $configureArgs = @('--preset', $Preset)
        if ($Fresh) { $configureArgs += '--fresh' }
        cmake @configureArgs
        if ($LASTEXITCODE) { throw "CMake configure failed for preset '$Preset'." }
    }

    cmake --build --preset $Preset
    if ($LASTEXITCODE) { throw "Build failed for preset '$Preset'." }
} finally {
    Pop-Location
}

if ($Preset -like 'android-*') {
    Write-Host "APK: $(Get-ApkPath $Preset)" -ForegroundColor Green
}
