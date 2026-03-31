#!/usr/bin/env bash
set -euo pipefail

# One-command runner for the Swift package demo on iOS Simulator.
# Usage:
#   bash scripts/run_ios_sim.sh
#   SIM_ID=<simulator-udid> bash scripts/run_ios_sim.sh

HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"

SCHEME="LLamaDemo"
BUNDLE_ID="com.edge-llm.llama-demo"
DERIVED_DATA_PATH="$HERE/.derivedData"

if [[ -z "${SIM_ID:-}" ]]; then
  SIM_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/{print $2; exit}')"
fi

if [[ -z "${SIM_ID:-}" ]]; then
  # Fallback to first available iPhone simulator UDID.
  SIM_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{print $2; exit}')"
fi

if [[ -z "${SIM_ID:-}" ]]; then
  echo "No available iOS simulator found." >&2
  exit 1
fi

echo "Using simulator: $SIM_ID"

echo "Building..."
xcodebuild \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

BIN_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/$SCHEME"
APP_PATH="/tmp/$SCHEME.app"

if [[ ! -f "$BIN_PATH" ]]; then
  echo "Expected executable not found: $BIN_PATH" >&2
  exit 1
fi

echo "Packaging app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH"
cp "$BIN_PATH" "$APP_PATH/$SCHEME"
cp "$HERE/App/SwiftUIApp/Info-iOS.plist" "$APP_PATH/Info.plist"
chmod +x "$APP_PATH/$SCHEME"

echo "Opening Simulator app..."
open -a Simulator

echo "Booting simulator (if needed)..."
xcrun simctl boot "$SIM_ID" || true
xcrun simctl bootstatus "$SIM_ID" -b

echo "Installing app..."
xcrun simctl install "$SIM_ID" "$APP_PATH"

echo "Launching app..."
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"

echo "Done."
