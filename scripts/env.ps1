<#
.SYNOPSIS
    Finds Qt, the Android SDK/NDK and a JDK, and exports them for the CMake presets.

.DESCRIPTION
    Dot-source it to set up the current shell:   . .\scripts\env.ps1
    Add -Persist to also save the variables to your user environment, so IDEs
    that read CMakePresets.json (VS Code, CLion, Qt Creator) can find them.

    Variables that are already set win over auto-detection. For overrides that
    apply only to this checkout, create scripts/local.ps1 (git-ignored), e.g.
        $env:QT_VERSION_DIR = 'D:/Qt/6.12.0'

    The other scripts dot-source this file and use the helpers defined below.
#>
param([switch]$Persist)

function Initialize-ProjectEnv {
    $localOverrides = Join-Path $PSScriptRoot 'local.ps1'
    if (Test-Path $localOverrides) { . $localOverrides }

    # Qt: newest C:\Qt\<version> that has the desktop (host) kit and an Android kit
    if (-not $env:QT_VERSION_DIR) {
        $qt = Get-ChildItem 'C:\Qt' -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '^\d+\.\d+\.\d+$' -and
                (Test-Path (Join-Path $_.FullName 'mingw_64')) -and
                (Get-ChildItem $_.FullName -Directory -Filter 'android_*')
            } |
            Sort-Object { [version]$_.Name } -Descending |
            Select-Object -First 1
        if (-not $qt) { throw 'No Qt with Android kits found under C:\Qt. Set QT_VERSION_DIR (e.g. C:/Qt/6.12.0).' }
        $env:QT_VERSION_DIR = $qt.FullName
    }

    if (-not $env:ANDROID_SDK_ROOT) {
        $env:ANDROID_SDK_ROOT = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    }
    if (-not (Test-Path $env:ANDROID_SDK_ROOT)) { throw "Android SDK not found at $env:ANDROID_SDK_ROOT. Set ANDROID_SDK_ROOT." }

    # NDK: prefer the exact version this Qt was built with
    if (-not $env:ANDROID_NDK_ROOT) {
        $coreJson = Get-ChildItem $env:QT_VERSION_DIR -Directory -Filter 'android_*' |
            ForEach-Object { Join-Path $_.FullName 'modules\Core.json' } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1
        $wanted = $null
        if ($coreJson -and ((Get-Content $coreJson -Raw) -match '"ndk_version":\s*"([^"]+)"')) { $wanted = $Matches[1] }

        $ndkDir = Join-Path $env:ANDROID_SDK_ROOT 'ndk'
        if ($wanted -and (Test-Path (Join-Path $ndkDir $wanted))) {
            $env:ANDROID_NDK_ROOT = Join-Path $ndkDir $wanted
        } else {
            $newest = Get-ChildItem $ndkDir -Directory -ErrorAction SilentlyContinue |
                Sort-Object { [version]$_.Name } -Descending |
                Select-Object -First 1
            if (-not $newest) { throw "No Android NDK installed. Install it with: sdkmanager ""ndk;$wanted""" }
            Write-Warning "Qt was built with NDK $wanted, which is not installed; using $($newest.Name). Install the matching one with: sdkmanager ""ndk;$wanted"""
            $env:ANDROID_NDK_ROOT = $newest.FullName
        }
    }

    if (-not $env:JAVA_HOME) {
        $java = Get-Command java -ErrorAction SilentlyContinue
        $studioJbr = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr'
        if ($java) {
            $env:JAVA_HOME = Split-Path (Split-Path $java.Source)
        } elseif (Test-Path $studioJbr) {
            $env:JAVA_HOME = $studioJbr
        } else {
            throw 'No JDK found. Install JDK 17 or set JAVA_HOME.'
        }
    }

    # CMake and Gradle prefer forward slashes
    foreach ($name in 'QT_VERSION_DIR', 'ANDROID_SDK_ROOT', 'ANDROID_NDK_ROOT', 'JAVA_HOME') {
        Set-Item "env:$name" ((Get-Item "env:$name").Value -replace '\\', '/')
    }

    $qtTools = Join-Path $env:QT_VERSION_DIR '..\Tools'
    $mingw = Get-ChildItem $qtTools -Directory -Filter 'mingw*_64' -ErrorAction SilentlyContinue |
        Sort-Object { [int]($_.Name -replace '\D', '') } -Descending |
        Select-Object -First 1
    $toolPaths = @(
        (Join-Path $qtTools 'Ninja'),
        $(if ($mingw) { Join-Path $mingw.FullName 'bin' }),
        (Join-Path $env:QT_VERSION_DIR 'mingw_64\bin'),          # Qt DLLs for the desktop build
        (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools'),      # adb
        (Join-Path $env:ANDROID_SDK_ROOT 'emulator')
    )
    $pathEntries = $env:PATH -split ';'
    foreach ($dir in $toolPaths) {
        if (-not $dir -or -not (Test-Path $dir)) { continue }
        $dir = (Resolve-Path $dir).Path
        if ($pathEntries -notcontains $dir) { $env:PATH = "$dir;$env:PATH" }
    }
}

# Devices known to adb, with their state ("device" means booted and authorized)
function Get-AdbDevices {
    foreach ($line in (adb devices)) {
        if ($line -match '^(\S+)\t(.+)$') {
            [pscustomobject]@{ Serial = $Matches[1]; State = $Matches[2].Trim() }
        }
    }
}

function Get-ApkPath([string]$Preset) {
    $buildDir = Join-Path (Split-Path $PSScriptRoot) "build\$Preset"
    $apk = Get-ChildItem $buildDir -Recurse -Filter '*.apk' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\outputs\\apk\\' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $apk) { throw "No APK found under $buildDir. Build it first: .\scripts\build.ps1 $Preset" }
    $apk.FullName
}

Initialize-ProjectEnv

# Show what was picked when run by hand (other scripts dot-source this silently)
if ($Persist -or -not $MyInvocation.ScriptName) {
    Write-Host "QT_VERSION_DIR   = $env:QT_VERSION_DIR"
    Write-Host "ANDROID_SDK_ROOT = $env:ANDROID_SDK_ROOT"
    Write-Host "ANDROID_NDK_ROOT = $env:ANDROID_NDK_ROOT"
    Write-Host "JAVA_HOME        = $env:JAVA_HOME"
}

if ($Persist) {
    foreach ($name in 'QT_VERSION_DIR', 'ANDROID_SDK_ROOT', 'ANDROID_NDK_ROOT', 'JAVA_HOME') {
        [Environment]::SetEnvironmentVariable($name, (Get-Item "env:$name").Value, 'User')
    }
    Write-Host 'Saved to your user environment. Restart your IDE and terminals to pick them up.'
}
