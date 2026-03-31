# XCFramework integration guide

This document describes how to build the `LLamaCpp` XCFramework and how to integrate it into an Xcode app or as a binary Swift Package.

Prerequisites
- macOS (Intel or Apple Silicon)
- Xcode + Command Line Tools
- Homebrew + `cmake` (install with `brew install cmake`)

1) Build the XCFramework

```bash
cd ios/llama-ios-skeleton
bash scripts/create_xcframework.sh
```

After success you'll have `build_xcframework/LLamaCpp.xcframework`.

2) Option A — Add the XCFramework directly to your Xcode app

- Open your Xcode app project.
- Drag `build_xcframework/LLamaCpp.xcframework` into the Project navigator (choose "Copy items if needed" = optional).
- Select your app target → **General** → **Frameworks, Libraries, and Embedded Content** and ensure the XCFramework is added there with **Embed & Sign**.
- If your Swift code calls Objective-C APIs via a bridging header, make sure the bridging header includes `LlamaBridge.h` (the existing `Bridging-Header.h` in this package can be used or adapted).
- Header search path: if you need to compile Objective-C++ files that `#include <llama.h>`, add the XCFramework headers path to **Header Search Paths** (recursive) in Build Settings, for example:

```
$(PROJECT_DIR)/ios/llama-ios-skeleton/build_xcframework/LLamaCpp.xcframework/Headers
```

Notes: adding the XCFramework to the project lets Xcode handle linking. If you keep `LlamaBridge.mm` in a Swift package target, ensure that target's header search path points to the XCFramework Headers.

3) Option B — Use a local binary Swift Package (recommended for tidy dependency management)

- We provide a sample local package at `LLamaCppBinaryPackage` inside this folder.
- After creating the XCFramework, copy it into the package folder:

```bash
cd ios/llama-ios-skeleton
bash scripts/copy_xcframework_to_package.sh
```

- The package manifest at `LLamaCppBinaryPackage/Package.swift` expects the XCFramework to be present at `LLamaCppBinaryPackage/LLamaCpp.xcframework`.
- To add the binary package to your app, in Xcode: File → Add Packages... → Add Local... and pick the `LLamaCppBinaryPackage` directory.

4) Example `Package.swift` (binary target)

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LLamaCppBinaryPackage",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "LLamaCppBinary", targets: ["LLamaCppXC"]),
    ],
    targets: [
        .binaryTarget(name: "LLamaCppXC", path: "LLamaCpp.xcframework"),
    ]
)
```

5) Common troubleshooting

- On Apple Silicon, the simulator slice will be arm64; if you need x86_64 simulator slices (for older tooling), build on Intel or via Rosetta, or adjust CMake arch flags.
- If you see undefined-symbol link errors when compiling `LlamaBridge.mm` against the XCFramework, ensure the XCFramework is linked to the target containing `LlamaBridge.mm` (or keep `LlamaBridge.mm` inside the same package that declares the binary dependency so the linker sees the library).
- If header includes fail, double-check Header Search Paths point to the XCFramework `Headers` folder or the staged `third_party/llama.cpp/include` folder if you chose that route.

6) Recommended flow (iterative)

1. Build the XCFramework with `scripts/create_xcframework.sh`.
2. Add the XCFramework (or binary package) to Xcode and build the app target.
3. Run the host `local_llama_simple` (optional) to validate the GGUF model can be loaded on the host first:

```bash
cd ios/llama-ios-skeleton/tools/host_simple
bash build_and_run.sh
./bin/local_llama_simple -m /path/to/model.gguf "Hello"
```

If you hit build or link issues, capture the Xcode build log and I'll advise adjustments.
