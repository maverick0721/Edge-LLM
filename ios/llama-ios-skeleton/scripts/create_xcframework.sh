#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$HERE/../third_party/llama.cpp"
OUT_DIR="$HERE/build_xcframework"
BUILD_DIR_DEVICE="$HERE/build/ios-device"
BUILD_DIR_SIM="$HERE/build/ios-sim"

if ! command -v cmake >/dev/null 2>&1; then
  echo "Error: cmake not found. Install it with: brew install cmake"
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Error: xcodebuild not found. Install Xcode or Xcode command line tools."
  exit 1
fi

if [ ! -d "$SRC" ]; then
  echo "Error: staged llama.cpp not found at $SRC"
  echo "Run: bash scripts/fetch_build_llama.sh"
  exit 1
fi

echo "Cleaning build dirs..."
rm -rf "$BUILD_DIR_DEVICE" "$BUILD_DIR_SIM" "$OUT_DIR"
mkdir -p "$BUILD_DIR_DEVICE" "$BUILD_DIR_SIM" "$OUT_DIR"

CPU_COUNT=$(sysctl -n hw.ncpu || echo 4)
IOS_DEPLOYMENT_TARGET="15.0"

echo "Configuring device build (iphoneos/arm64)..."
cmake -S "$SRC" -B "$BUILD_DIR_DEVICE" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_COMMON=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DGGML_BUILD_TESTS=OFF \
  -DGGML_USE_OPENMP=OFF \
  -DGGML_USE_ACCELERATE=ON \
  -DGGML_USE_NEON=ON \
  -DOPENSSL_ROOT_DIR=""

cmake --build "$BUILD_DIR_DEVICE" --config Release --target llama -j${CPU_COUNT}

echo "Configuring simulator build (iphonesimulator/x86_64;arm64)..."
cmake -S "$SRC" -B "$BUILD_DIR_SIM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_COMMON=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DGGML_BUILD_TESTS=OFF \
  -DGGML_USE_OPENMP=OFF \
  -DGGML_USE_ACCELERATE=ON \
  -DGGML_USE_NEON=ON \
  -DOPENSSL_ROOT_DIR=""

cmake --build "$BUILD_DIR_SIM" --config Release --target llama -j${CPU_COUNT}

LIB_DEVICE=$(find "$BUILD_DIR_DEVICE" -name "libllama.a" -print -quit || true)
LIB_SIM=$(find "$BUILD_DIR_SIM" -name "libllama.a" -print -quit || true)

COMBINED_LIB_DEVICE="$BUILD_DIR_DEVICE/libllama_combined.a"
COMBINED_LIB_SIM="$BUILD_DIR_SIM/libllama_combined.a"

if [ -n "$LIB_DEVICE" ]; then
  GGML_LIBS_DEVICE=()
  while IFS= read -r lib; do
    GGML_LIBS_DEVICE+=("$lib")
  done < <(find "$BUILD_DIR_DEVICE" -name "libggml*.a" -print | sort)

  if [ "${#GGML_LIBS_DEVICE[@]}" -gt 0 ]; then
    echo "Combining llama + ggml static libs (device) -> $COMBINED_LIB_DEVICE"
    /usr/bin/libtool -static -o "$COMBINED_LIB_DEVICE" "$LIB_DEVICE" "${GGML_LIBS_DEVICE[@]}"
    LIB_DEVICE="$COMBINED_LIB_DEVICE"
  fi
fi

if [ -n "$LIB_SIM" ]; then
  GGML_LIBS_SIM=()
  while IFS= read -r lib; do
    GGML_LIBS_SIM+=("$lib")
  done < <(find "$BUILD_DIR_SIM" -name "libggml*.a" -print | sort)

  if [ "${#GGML_LIBS_SIM[@]}" -gt 0 ]; then
    echo "Combining llama + ggml static libs (simulator) -> $COMBINED_LIB_SIM"
    /usr/bin/libtool -static -o "$COMBINED_LIB_SIM" "$LIB_SIM" "${GGML_LIBS_SIM[@]}"
    LIB_SIM="$COMBINED_LIB_SIM"
  fi
fi

if [ -z "$LIB_DEVICE" ] || [ -z "$LIB_SIM" ]; then
  echo "Error: could not find built libraries. Check build output under $BUILD_DIR_DEVICE and $BUILD_DIR_SIM"
  exit 1
fi

XCFRAMEWORK="$OUT_DIR/LLamaCpp.xcframework"
echo "Creating XCFramework at $XCFRAMEWORK"
xcodebuild -create-xcframework \
  -library "$LIB_DEVICE" -headers "$SRC/include" \
  -library "$LIB_SIM" -headers "$SRC/include" \
  -output "$XCFRAMEWORK"

echo "XCFramework created: $XCFRAMEWORK"
echo "Now add LLamaCpp.xcframework to your SwiftPM package or Xcode app target."
