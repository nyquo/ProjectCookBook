# Project Cookbook

This is a personnal project. The aim is to have a free recipe book that have the features I want.

A Qt6/QML app with C++ underneath, built with CMake. It runs on the Android emulator, on real Android phones, and on the Windows desktop for fast UI iteration.

## Prerequisites

| Tool | Version used | Notes |
| --- | --- | --- |
| Qt | 6.12.0 (6.10+ works) | Install these kits: **Android x86_64** (emulator), **Android ARM64-v8a** (phones), **MinGW 64-bit** (desktop, and the host tools for Android builds) |
| Android SDK | platform-tools, emulator, `platforms;android-36`, `build-tools;36.0.0` | Default location `%LOCALAPPDATA%\Android\Sdk` |
| Android NDK | 27.2.12479018 | Must match the NDK your Qt was built with, listed as `ndk_version` in `<Qt>/android_*/modules/Core.json` |
| JDK | 17 | |
| CMake, Ninja | 3.25+ | Both ship with the Qt installer (`C:\Qt\Tools`) |

The scripts locate these tools in their default install locations. To override one, set `QT_VERSION_DIR`, `ANDROID_SDK_ROOT`, `ANDROID_NDK_ROOT` or `JAVA_HOME`, or put the assignments in `scripts/local.ps1` (git-ignored).

Windows blocks local PowerShell scripts by default. Allow them once with:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Run it

```powershell
.\scripts\run.ps1 emulator    # boots an AVD if none is running, then builds, installs and launches
.\scripts\run.ps1 device      # same on a phone connected over USB or Wi-Fi
.\scripts\run.ps1 desktop     # Windows build, the fastest way to iterate on QML
```

Useful flags:

* `-Logs` streams the app's logcat output after launch (Ctrl+C to stop).
* `-NoBuild` reinstalls the last build without rebuilding.
* `-Serial <id>` picks a device when several are connected.
* `-Avd <name>` picks which emulator to boot.

The script reads the CPU ABI from the device and builds to match: x86_64 for the emulator, arm64-v8a for most phones, armeabi-v7a for older 32-bit phones. The home screen shows the platform and CPU architecture, so you can see which build is running.

### First run on a phone

1. Turn on **Developer options**: *Settings > About phone*, tap *Build number* seven times.
2. In *Developer options*, turn on **USB debugging**.
3. Plug the phone in and accept the **Allow USB debugging?** prompt (tick *Always allow*).
4. `adb devices` should now list the phone as `device`. If it says `unauthorized`, check the prompt on the phone.

Over Wi-Fi (Android 11+, phone and PC on the same network): in *Developer options > Wireless debugging*, choose *Pair device with pairing code*, then run:

```powershell
adb pair <ip>:<pairing-port>     # enter the 6-digit code
adb connect <ip>:<port>          # the port shown on the Wireless debugging screen
```

If Windows doesn't see a USB-connected phone, it may need a driver. Pixels use the *Google USB Driver* from the Android SDK Manager; Samsung and other brands publish their own OEM drivers.

### Emulator notes

Use an AVD with an **x86_64** system image. The scripts boot it with `-gpu auto` because Qt Quick needs OpenGL ES. If the emulator is sluggish, open *Device Manager* in Android Studio and raise the AVD's RAM to at least 2 GB.

## Build without running

```powershell
.\scripts\build.ps1 android-arm64-v8a     # prints the APK path when done
.\scripts\build.ps1 android-x86_64
.\scripts\build.ps1 desktop
.\scripts\build.ps1 desktop -Fresh        # wipe the CMake cache first
```

Output goes to `build/<preset>/`. Under the hood, each script runs `cmake --preset <preset>` followed by `cmake --build --preset <preset>`.

## Using an IDE

**Qt Creator**: open `CMakeLists.txt` and select the *Android Qt 6.12.0* and *Desktop Qt 6.12.0 MinGW* kits. Under *Preferences > SDKs > Android*, point Qt Creator at the SDK above. Its Run button then deploys to the emulator or phone you select.

**VS Code, CLion, or plain `cmake --preset`**: `CMakePresets.json` reads `QT_VERSION_DIR`, `ANDROID_SDK_ROOT` and `ANDROID_NDK_ROOT` from the environment. Save the detected values to your user environment once, then restart the IDE:

```powershell
.\scripts\env.ps1 -Persist
```

To set them for the current terminal only, run `. .\scripts\env.ps1`.

