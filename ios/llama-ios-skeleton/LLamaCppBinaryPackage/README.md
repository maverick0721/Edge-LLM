LLamaCpp Binary Package
======================

This local package is a small wrapper that exposes the `LLamaCpp.xcframework` as a Swift package binary target.

Usage

1. Build the XCFramework (from project root):

```bash
bash scripts/create_xcframework.sh
```

2. Copy the produced XCFramework into this package:

```bash
bash scripts/copy_xcframework_to_package.sh
```

3. In Xcode: File → Add Packages... → Add Local... and choose this `LLamaCppBinaryPackage` folder.

The package product is `LLamaCppBinary`.
