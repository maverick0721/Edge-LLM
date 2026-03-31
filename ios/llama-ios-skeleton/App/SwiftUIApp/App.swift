import SwiftUI
#if os(macOS)
import AppKit
#endif

@available(macOS 11.0, *)
@main
struct LLamaSwiftApp: App {
    init() {
#if os(macOS)
        NSWindow.allowsAutomaticWindowTabbing = false
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
