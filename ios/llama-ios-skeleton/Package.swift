// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LLamaIOSSkeleton",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(name: "LLamaDemo", targets: ["LLamaDemo"])
    ],
    dependencies: [
        .package(path: "LLamaCppBinaryPackage"),
    ],
    targets: [
        .target(
            name: "LlamaBridgeShim",
            path: "Sources/LlamaBridgeShim",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../third_party/llama.cpp/include"),
                .headerSearchPath("../third_party/llama.cpp/ggml/include"),
                .unsafeFlags(["-I../third_party/llama.cpp/include"]),
                .unsafeFlags(["-I../third_party/llama.cpp/ggml/include"]),
                .unsafeFlags(["-I../../../third_party/llama.cpp/include"]),
                .unsafeFlags(["-I../../../third_party/llama.cpp/ggml/include"]),
                .unsafeFlags(["-I../../third_party/llama.cpp/include"]),
                .unsafeFlags(["-I../../third_party/llama.cpp/ggml/include"]),
            ]
        ),
        .executableTarget(
            name: "LLamaDemo",
            dependencies: [
                .product(
                    name: "LLamaCppXC",
                    package: "LLamaCppBinaryPackage",
                    condition: .when(platforms: [.iOS])
                ),
                .target(name: "LlamaBridgeShim"),
            ],
            path: "App/SwiftUIApp",
            exclude: [
                "Info-iOS.plist",
                "Info-macOS.plist",
            ],
            linkerSettings: [
                .linkedFramework("Accelerate", .when(platforms: [.iOS])),
                .unsafeFlags(
                    [
                        "-Wl,-sectcreate,__TEXT,__info_plist,App/SwiftUIApp/Info-iOS.plist"
                    ],
                    .when(platforms: [.iOS])
                ),
            ]
        ),
        .testTarget(
            name: "LLamaDemoTests",
            dependencies: [
                .target(name: "LlamaBridgeShim"),
            ],
            path: "Tests/LLamaDemoTests"
        )
    ]
)
