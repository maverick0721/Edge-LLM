#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$HERE"

echo "Checking prerequisites..."
if ! command -v cmake >/dev/null 2>&1; then
  echo "Error: cmake not found. Install with: brew install cmake"
  exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Error: xcodebuild not found. Install Xcode and Command Line Tools."
  exit 1
fi

echo "Fetching and staging llama.cpp (may take a while)..."
bash scripts/fetch_build_llama.sh

echo "Building host sanity binary (optional, validates model loading)..."
if [ -d "$HERE/tools/host_simple" ]; then
  bash tools/host_simple/build_and_run.sh || echo "Host build failed; continuing to XCFramework step."
fi

echo "Building XCFramework..."
bash scripts/create_xcframework.sh

echo "Copying XCFramework into local binary package..."
bash scripts/copy_xcframework_to_package.sh || true

echo "Preparing SPM sources (symlink staged llama.cpp)..."
bash scripts/prepare_spm_sources.sh || true

echo "Opening package in Xcode..."
bash scripts/open_in_xcode.sh || true

echo "Done. If Xcode did not open, run: bash scripts/open_in_xcode.sh"
