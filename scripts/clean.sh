#!/usr/bin/env bash
# Flutter project cleanup script.
# Removes build artifacts and generated files.
set -euo pipefail

# Must run from git repo root
git rev-parse --show-toplevel >/dev/null 2>&1 || {
  echo "ERROR: Must run from git repo"; exit 1
}
cd "$(git rev-parse --show-toplevel)"

# Safe removal: check each path is not a symlink, not /, not empty
safe_rm() {
  local dir="$1"
  [ -z "$dir" ] && return 0
  [ -e "$dir" ] || return 0
  local real
  real="$(readlink -f "$dir")"
  [ "$real" = "/" ] && { echo "Refusing to rm /"; exit 1; }
  [ -L "$dir" ] && { echo "Skipping symlink $dir"; return 0; }
  rm -rf -- "$dir"
  echo "Removed $dir"
}

echo "Cleaning Flutter build artifacts..."
safe_rm build/
safe_rm .dart_tool/
safe_rm android/.gradle/
safe_rm android/app/debug/
safe_rm android/app/profile/
safe_rm android/app/release/
safe_rm .flutter-plugins
safe_rm .flutter-plugins-dependencies

echo "Running flutter clean..."
flutter clean

echo "Restoring dependencies..."
flutter pub get

echo "Done."
