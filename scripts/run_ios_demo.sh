#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios/llama-ios-skeleton"
IOS_RUNNER="$IOS_DIR/scripts/run_ios_sim.sh"

SIM_ID="${SIM_ID:-}"
SIM_NAME="${SIM_NAME:-}"

usage() {
  cat <<EOF
Usage:
  ./scripts/run_ios_demo.sh [--sim-name "<Simulator Name>"] [--sim-id <UDID>]

Examples:
  ./scripts/run_ios_demo.sh
  ./scripts/run_ios_demo.sh --sim-name "iPhone 17 Pro"
  ./scripts/run_ios_demo.sh --sim-id 0DAAA551-21D2-4901-B9BC-C962A8338369
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sim-name)
      if [ "$#" -lt 2 ]; then
        echo "--sim-name requires a value"
        exit 1
      fi
      SIM_NAME="$2"
      shift 2
      ;;
    --sim-id)
      if [ "$#" -lt 2 ]; then
        echo "--sim-id requires a value"
        exit 1
      fi
      SIM_ID="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [ ! -d "$IOS_DIR" ]; then
  echo "iOS directory not found: $IOS_DIR"
  exit 1
fi

if [ ! -f "$IOS_RUNNER" ]; then
  echo "iOS simulator runner not found: $IOS_RUNNER"
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Install Xcode command line tools first."
  exit 1
fi

if [ -n "$SIM_ID" ] && [ -n "$SIM_NAME" ]; then
  echo "Use either --sim-id or --sim-name, not both."
  exit 1
fi

if [ -z "$SIM_ID" ] && [ -n "$SIM_NAME" ]; then
  SIM_ID="$(xcrun simctl list devices available | awk -F '[()]' -v target="$SIM_NAME" '$0 ~ target {print $2; exit}')"
  if [ -z "$SIM_ID" ]; then
    echo "Could not find available simulator named: $SIM_NAME"
    echo "Tip: run 'xcrun simctl list devices available | grep iPhone'"
    exit 1
  fi
fi

if [ -z "$SIM_ID" ]; then
  SIM_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/{print $2; exit}')"
fi

if [ -z "$SIM_ID" ]; then
  SIM_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{print $2; exit}')"
fi

if [ -z "$SIM_ID" ]; then
  echo "No available iPhone simulator found."
  exit 1
fi

echo "Launching iOS demo on simulator: $SIM_ID"
cd "$IOS_DIR"
SIM_ID="$SIM_ID" bash "$IOS_RUNNER"
