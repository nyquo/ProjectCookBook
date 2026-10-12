<#
.SYNOPSIS
    Configures (first time only) and builds one CMake preset from CMakePresets.json.

.EXAMPLE
    .\scripts\build.ps1 android-arm64-v8a
    Builds the APK for 64-bit phones and prints its path.

.EXAMPLE
    .\scripts\build.ps1 desktop -Fresh
    Wipes the CMake cache and rebuilds the Windows desktop version.

.EXAMPLE
    .\scripts\build.ps1 desktop -Test
    Builds the desktop version and runs the unit tests.

.EXAMPLE
    .\scripts\build.ps1 core-msvc -Test
    Builds and tests only the Qt-free core, with MSVC.
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('desktop', 'android-x86_64', 'android-arm64-v8a', 'android-armeabi-v7a', 'core-msvc')]
    [string]$Preset,

    # Re-run CMake configuration from scratch.
    [switch]$Fresh,

    # Run the unit tests after building (desktop builds only).
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
if ($Test -and $Preset -like 'android-*') { throw 'Tests run on desktop builds only: use -Test with desktop or core-msvc.' }
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

    if ($Test) {
        ctest --preset $Preset
        if ($LASTEXITCODE) { throw "Tests failed for preset '$Preset'." }
    }
} finally {
    Pop-Location
}

if ($Preset -like 'android-*') {
    Write-Host "APK: $(Get-ApkPath $Preset)" -ForegroundColor Green
}
