// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LLamaCppBinaryPackage",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "LLamaCppXC",
            targets: ["LLamaCppXC"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "LLamaCppXC",
            path: "LLamaCpp.xcframework"
        )
    ]
)
