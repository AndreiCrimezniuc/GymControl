#!/usr/bin/env bash

set -euo pipefail

DEFAULT_DEVICE_ID="00008120-00046DDC1444201E"
DEVICE_ID="${GYMBOSS_IPHONE_ID:-$DEFAULT_DEVICE_ID}"
CLEAN_BUILD=false

usage() {
  echo "Usage: scripts/install_iphone_release.sh [--clean] [device-id]"
  echo
  echo "Updates local main with a safe fast-forward and installs a release"
  echo "build on the selected iPhone."
  echo
  echo "Options:"
  echo "  --clean      Clear Flutter/Xcode build artifacts before building"
  echo "  -h, --help   Show this help"
}

while (($#)); do
  case "$1" in
    --clean)
      CLEAN_BUILD=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      DEVICE_ID="$1"
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "Refusing to update from a non-main branch." >&2
  echo "Switch to main first, then run this script again." >&2
  exit 1
fi

echo "Fetching the latest GymControl main..."
git fetch origin main

# Fast-forward only: this never overwrites local commits. Git will also stop
# safely if an incoming change conflicts with local iOS signing edits.
git merge --ff-only origin/main

echo "Building commit: $(git log -1 --oneline)"

if [[ "$CLEAN_BUILD" == true ]]; then
  echo "Cleaning previous Flutter/Xcode artifacts..."
  flutter clean
fi

flutter pub get

echo "Installing and launching the release on device $DEVICE_ID..."
echo "After the app opens, press q to stop this command; the app stays installed."
flutter run --release -d "$DEVICE_ID"
