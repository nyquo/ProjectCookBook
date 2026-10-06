<#
.SYNOPSIS
    Boots an Android Virtual Device (unless one is already running), waits until
    Android has finished booting, and outputs the emulator's adb serial.

.EXAMPLE
    .\scripts\emulator.ps1
    Boots the first AVD listed by "emulator -list-avds".

.EXAMPLE
    .\scripts\emulator.ps1 -Avd Pixel_9_API_36
#>
param(
    # AVD name; defaults to the first one found.
    [string]$Avd,

    [int]$TimeoutMinutes = 5
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

function Get-RunningEmulator {
    Get-AdbDevices | Where-Object { $_.Serial -like 'emulator-*' -and $_.State -eq 'device' } | Select-Object -First 1
}

if (-not (Get-RunningEmulator)) {
    if (-not $Avd) {
        $Avd = emulator -list-avds | Where-Object { $_ -and $_ -notmatch '^(INFO|WARNING|ERROR)\b' } | Select-Object -First 1
        if (-not $Avd) { throw 'No AVD found. Create one in Android Studio > Device Manager, using an x86_64 system image.' }
    }
    Write-Host "Booting emulator '$Avd'..."
    $emulatorExe = Join-Path $env:ANDROID_SDK_ROOT 'emulator\emulator.exe'
    # Hidden only hides the emulator's console; its device window still opens.
    Start-Process -FilePath $emulatorExe -ArgumentList '-avd', $Avd, '-gpu', 'auto' -WindowStyle Hidden
}

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
while ((Get-Date) -lt $deadline) {
    $emu = Get-RunningEmulator
    if ($emu -and ((adb -s $emu.Serial shell getprop sys.boot_completed) -match '1')) {
        Write-Host "Emulator ready: $($emu.Serial)"
        return $emu.Serial
    }
    Start-Sleep -Seconds 2
}
throw "The emulator did not finish booting within $TimeoutMinutes minutes."
