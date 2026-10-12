#!/usr/bin/env bash
# Copies the app's database from the connected device or emulator to
# scratch/data.db, e.g. to open it with VS Code's SQLite Viewer.
# Debug builds only: run-as needs a debuggable app.
#
#   tools/pull-db.sh [adb-serial]
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
package=$(sed -n 's/^set(APP_ANDROID_PACKAGE "\(.*\)")$/\1/p' "$root/CMakeLists.txt")
[[ -n $package ]] || { echo "APP_ANDROID_PACKAGE not found in CMakeLists.txt" >&2; exit 1; }

adb=$(command -v adb || true)
if [[ -z $adb ]]; then
  sdk=${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}}
  adb="$(cygpath -u "$sdk" 2>/dev/null || echo "$sdk")/platform-tools/adb"
fi

out="$root/scratch/data.db"
part="$out.part"
trap 'rm -f "$part"' EXIT
mkdir -p "$root/scratch"
"$adb" ${1:+-s "$1"} exec-out run-as "$package" cat files/data.db > "$part"

# run-as reports errors on stdout, so they end up in the file.
if [[ $(head -c 15 "$part") != "SQLite format 3" ]]; then
  echo "Not a database: $(head -c 200 "$part")" >&2
  exit 1
fi
mv "$part" "$out"
echo "Copied to $out"
