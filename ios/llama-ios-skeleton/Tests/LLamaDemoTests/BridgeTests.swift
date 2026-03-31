import XCTest

final class BridgeTests: XCTestCase {
    // Declare the C symbol imported from the bridge
    @_silgen_name("llama_bridge_version")
    static func llama_bridge_version() -> UnsafePointer<CChar>?

    func testBridgeVersionIsNonEmpty() {
        guard let ptr = Self.llama_bridge_version() else {
            XCTFail("llama_bridge_version() returned NULL")
            return
        }
        let s = String(cString: ptr)
        XCTAssertFalse(s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "bridge version string should not be empty")
        print("Bridge version: \(s)")
    }
}
