#!/usr/bin/env bash
set -euo pipefail

# Clone and build llama.cpp host tools and stage sources for Xcode integration.
# Run from ios/llama-ios-skeleton directory: bash scripts/fetch_build_llama.sh

REPO_URL="https://github.com/ggerganov/llama.cpp.git"
THIRD_PARTY_DIR="$(pwd)/../third_party/llama.cpp"
FRAMEWORK_SRC_DIR="$(pwd)/../Framework/LLamaCpp/Source/llama_cpp"

echo "llama.cpp repo: $REPO_URL"
echo "staging to: $THIRD_PARTY_DIR"

mkdir -p "$(dirname "$THIRD_PARTY_DIR")"
if [ -d "$THIRD_PARTY_DIR" ]; then
  echo "Updating existing llama.cpp..."
  git -C "$THIRD_PARTY_DIR" pull --ff-only || true
else
  echo "Cloning llama.cpp..."
  git clone --depth 1 "$REPO_URL" "$THIRD_PARTY_DIR"
fi

echo "Building host tools (quantize, main)..."
cd "$THIRD_PARTY_DIR"
if [ -f CMakeLists.txt ]; then
  echo "Detected CMake build system. Building with CMake..."
  BUILD_DIR="$THIRD_PARTY_DIR/build"
  mkdir -p "$BUILD_DIR"
  if command -v nproc >/dev/null 2>&1; then
    NPROC=$(nproc)
  else
    NPROC=$(sysctl -n hw.ncpu)
  fi
  cmake -S . -B "$BUILD_DIR"
  cmake --build "$BUILD_DIR" -- -j"$NPROC"
elif [ -f Makefile ]; then
  if command -v nproc >/dev/null 2>&1; then
    NPROC=$(nproc)
  else
    NPROC=$(sysctl -n hw.ncpu)
  fi
  make -j"$NPROC"
else
  echo "No supported build system found in llama.cpp (expected CMake or Makefile)." >&2
  exit 1
fi

echo "Staging sources to framework directory: $FRAMEWORK_SRC_DIR"
mkdir -p "$FRAMEWORK_SRC_DIR"

# Copy a conservative set of files useful for iOS integration; adjust as needed.
rsync -a --exclude 'build' --exclude '.git' --exclude 'models' --exclude 'tests' . "$FRAMEWORK_SRC_DIR/" || true

echo "Done. Next steps:"
echo "  1) In Xcode, add files under Framework/LLamaCpp/Source/llama_cpp to the LLamaCpp framework target."
echo "  2) Add any missing compile flags (C++17, -ObjC++), then build the framework."
echo "  3) Use scripts/create_xcframework.sh to produce an XCFramework."
