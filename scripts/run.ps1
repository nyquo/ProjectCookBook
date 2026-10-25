<#
.SYNOPSIS
    Builds the app and runs it on the Android emulator, a phone, or the desktop.

.DESCRIPTION
    For Android targets the build matches the device's CPU ABI (x86_64 for the
    emulator, usually arm64-v8a for phones), then the APK is installed with adb
    and launched.

.EXAMPLE
    .\scripts\run.ps1 emulator
    Boots an AVD if none is running, then builds, installs and launches.

.EXAMPLE
    .\scripts\run.ps1 device -Logs
    Runs on the phone connected over USB or Wi-Fi and streams the app's logs.

.EXAMPLE
    .\scripts\run.ps1 desktop

.EXAMPLE
    .\scripts\run.ps1 emulator -Showcase
    Runs the component showcase instead of the app.
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('emulator', 'device', 'desktop')]
    [string]$Target,

    # adb serial to use when several devices are connected (see "adb devices")
    [string]$Serial,

    # AVD to boot for the emulator target; defaults to the first one
    [string]$Avd,

    # Install and launch the last build without rebuilding
    [switch]$NoBuild,

    # Stream the app's logcat output after launching (Ctrl+C to stop)
    [switch]$Logs,

    # Run the component showcase instead of the app
    [switch]$Showcase
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$root = Split-Path $PSScriptRoot
# The executable's source folder and its desktop file name
$sourceFolder = if ($Showcase) { 'showcase' } else { 'app' }
$exeName = if ($Showcase) { 'showcase.exe' } else { 'appProjectCookbook.exe' }

if ($Target -eq 'desktop') {
    if (-not $NoBuild) { & "$PSScriptRoot\build.ps1" desktop }
    $exe = Join-Path $root "build\desktop\$exeName"
    if (-not (Test-Path $exe)) { throw 'Desktop executable not found. Build it first: .\scripts\build.ps1 desktop' }
    & $exe
    return
}

# --- Pick the Android device -------------------------------------------------
$devices = @(Get-AdbDevices)
if ($Serial) {
    if (-not ($devices | Where-Object { $_.Serial -eq $Serial -and $_.State -eq 'device' })) {
        throw "No ready adb device with serial '$Serial'. Connected: $(($devices | ForEach-Object { "$($_.Serial) ($($_.State))" }) -join ', ')"
    }
} elseif ($Target -eq 'emulator') {
    $Serial = & "$PSScriptRoot\emulator.ps1" -Avd $Avd
} else {
    $phones = @($devices | Where-Object { $_.Serial -notlike 'emulator-*' })
    $ready = @($phones | Where-Object { $_.State -eq 'device' })
    if (-not $ready) {
        if ($phones | Where-Object { $_.State -eq 'unauthorized' }) {
            throw 'Phone found but not authorized: unlock it and accept the "Allow USB debugging?" prompt, then retry.'
        }
        throw 'No phone found. Enable USB debugging and plug it in (or pair over Wi-Fi), then check with: adb devices'
    }
    if ($ready.Count -gt 1) { Write-Warning "Several phones connected; using $($ready[0].Serial). Pass -Serial to choose." }
    $Serial = $ready[0].Serial
}

# --- Build for the device's ABI ------------------------------------------------
$abis = ((adb -s $Serial shell getprop ro.product.cpu.abilist) -join '').Trim() -split ','
$knownPresets = 'android-x86_64', 'android-arm64-v8a', 'android-armeabi-v7a'
$preset = $abis | ForEach-Object { "android-$_" } | Where-Object { $knownPresets -contains $_ } | Select-Object -First 1
if (-not $preset) { throw "No build preset for this device's ABIs ($($abis -join ', '))." }
Write-Host "Device $Serial supports $($abis -join ', '); using preset $preset."

if (-not $NoBuild) { & "$PSScriptRoot\build.ps1" $preset }
$apk = Get-ApkPath $preset $sourceFolder

# --- Install and launch -----------------------------------------------------------
$aapt2 = Get-ChildItem (Join-Path $env:ANDROID_SDK_ROOT 'build-tools') -Directory |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName 'aapt2.exe' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
$package = ((& $aapt2 dump packagename $apk) -join '').Trim()

Write-Host "Installing $package on $Serial..."
adb -s $Serial install -r $apk
if ($LASTEXITCODE) {
    throw "adb install failed. If it reports INSTALL_FAILED_UPDATE_INCOMPATIBLE, remove the old copy first: adb -s $Serial uninstall $package"
}

$activity = (adb -s $Serial shell cmd package resolve-activity --brief $package | Select-Object -Last 1).Trim()
adb -s $Serial shell am start -S -n $activity
if ($LASTEXITCODE) { throw "Could not launch $activity." }

if ($Logs) {
    $appPid = $null
    for ($i = 0; $i -lt 20 -and -not $appPid; $i++) {
        Start-Sleep -Milliseconds 500
        $appPid = ((adb -s $Serial shell pidof -s $package) -join '').Trim()
    }
    if (-not $appPid) { throw "The app is not running. Check the full log with: adb -s $Serial logcat" }
    Write-Host "Streaming logs for $package (pid $appPid). Ctrl+C to stop."
    adb -s $Serial logcat --pid=$appPid
}
