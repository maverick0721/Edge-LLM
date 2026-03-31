#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
XCFRAMEWORK_PATH="$HERE/LLamaCppBinaryPackage/LLamaCpp.xcframework"
PKG_FILE="$HERE/Package.swift"

echo "Syncing Package.swift dependency based on presence of XCFramework..."
if [ -d "$XCFRAMEWORK_PATH" ]; then
  echo "Found XCFramework at $XCFRAMEWORK_PATH — enabling binary package dependency."
  cat > "$PKG_FILE" << 'EOF'
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LLamaIOSSkeleton",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "LLamaCpp", targets: ["LLamaCpp"]),
        .executable(name: "LLamaDemo", targets: ["LLamaDemo"]),
    ],
    dependencies: [
        .package(path: "LLamaCppBinaryPackage"),
    ],
    targets: [
        .target(
            name: "LLamaCpp",
            path: "Framework/LLamaCpp/Source",
            exclude: [
                "llama_cpp/src",
                "llama_cpp/ggml",
                "llama_cpp/benches",
                "llama_cpp/examples",
                "llama_cpp/tools",
                "llama_cpp/pocs",
                "llama_cpp/tests",
                "llama_cpp/vendor",
                "llama_cpp/docs",
                "llama_cpp/scripts",
                "llama_cpp/gguf-py",
                "llama_cpp/pyproject.toml",
                "llama_cpp/CMakeLists.txt",
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
            ],
            cxxSettings: [
                .headerSearchPath("llama_cpp/include"),
                .unsafeFlags(["-std=gnu++17", "-fvisibility=hidden"], .when(platforms: [.iOS]))
            ]
        ),
        .executableTarget(
            name: "LLamaDemo",
            path: "App/SwiftUIApp",
            dependencies: [
                .product(name: "LLamaCppBinary", package: "LLamaCppBinaryPackage"),
            ],
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "LLamaDemoTests",
            dependencies: [
                .product(name: "LLamaCppBinary", package: "LLamaCppBinaryPackage"),
            ],
            path: "Tests/LLamaDemoTests"
        )
    ]
)
EOF
else
  echo "XCFramework not found — using local source target (LLamaCpp) for dependencies."
  cat > "$PKG_FILE" << 'EOF'
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LLamaIOSSkeleton",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "LLamaCpp", targets: ["LLamaCpp"]),
        .executable(name: "LLamaDemo", targets: ["LLamaDemo"]),
    ],
    targets: [
        .target(
            name: "LLamaCpp",
            path: "Framework/LLamaCpp/Source",
            exclude: [
                "llama_cpp/src",
                "llama_cpp/ggml",
                "llama_cpp/benches",
                "llama_cpp/examples",
                "llama_cpp/tools",
                "llama_cpp/pocs",
                "llama_cpp/tests",
                "llama_cpp/vendor",
                "llama_cpp/docs",
                "llama_cpp/scripts",
                "llama_cpp/gguf-py",
                "llama_cpp/pyproject.toml",
                "llama_cpp/CMakeLists.txt",
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
            ],
            cxxSettings: [
                .headerSearchPath("llama_cpp/include"),
                .unsafeFlags(["-std=gnu++17", "-fvisibility=hidden"], .when(platforms: [.iOS]))
            ]
        ),
        .executableTarget(
            name: "LLamaDemo",
            path: "App/SwiftUIApp",
            dependencies: [
                .target(name: "LLamaCpp"),
            ],
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "LLamaDemoTests",
            dependencies: [
                "LLamaCpp",
            ],
            path: "Tests/LLamaDemoTests"
        )
    ]
)
EOF
fi

echo "Package.swift synced. Run 'swift test' or open in Xcode."
