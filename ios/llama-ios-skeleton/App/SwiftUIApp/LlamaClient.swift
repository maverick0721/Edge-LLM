import Foundation
import SwiftUI

typealias LlamaTokenCB = @convention(c) (UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Void

@_silgen_name("llama_bridge_init_model")
func llama_bridge_init_model(_ modelPath: UnsafePointer<CChar>?, _ n_ctx: Int32, _ n_threads: Int32) -> Bool

@_silgen_name("llama_bridge_free_model")
func llama_bridge_free_model()

@_silgen_name("llama_bridge_generate")
func llama_bridge_generate(_ prompt: UnsafePointer<CChar>?, _ cb: @convention(c) (UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Void, _ userData: UnsafeMutableRawPointer?)

@_silgen_name("llama_bridge_version")
func llama_bridge_version() -> UnsafePointer<CChar>?

@available(macOS 10.15, *)
final class LlamaClient: ObservableObject {
    @Published var output: String = ""
    @Published var bridgeVersion: String = ""

    init(modelPath: String? = nil) {
        if let m = modelPath {
            _ = m.withCString { llama_bridge_init_model($0, 512, Int32(ProcessInfo.processInfo.processorCount)) }
        } else {
            _ = "".withCString { llama_bridge_init_model($0, 512, Int32(ProcessInfo.processInfo.processorCount)) }
        }

        // Query bridge version and expose it separately for the UI.
        if let verPtr = llama_bridge_version() {
            let ver = String(cString: verPtr)
            DispatchQueue.main.async {
                self.bridgeVersion = ver
                // also prefill the output area with the bridge info
                self.output = "Bridge: \(ver)\n"
            }
        }
    }

    deinit {
        llama_bridge_free_model()
    }

    func generate(prompt: String, completion: (() -> Void)? = nil) {
        let promptSnapshot = prompt
        DispatchQueue.global(qos: .userInitiated).async {
            let cb: LlamaTokenCB = { tokenPtr, userData in
                guard let tokenPtr = tokenPtr, let userData = userData else { return }
                let token = String(cString: tokenPtr)
                let client = Unmanaged<LlamaClient>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    client.output += token
                }
            }

            let user = Unmanaged.passUnretained(self).toOpaque()
            promptSnapshot.withCString { llama_bridge_generate($0, cb, user) }

            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    // Clear the displayed output
    func clearOutput() {
        DispatchQueue.main.async {
            self.output = ""
        }
    }

    // Reload the model (unload then init). Returns true on success.
    @discardableResult
    func reloadModel(modelPath: String? = nil) -> Bool {
        llama_bridge_free_model()
        if let m = modelPath {
            return m.withCString { llama_bridge_init_model($0, 512, Int32(ProcessInfo.processInfo.processorCount)) }
        } else {
            return "".withCString { llama_bridge_init_model($0, 512, Int32(ProcessInfo.processInfo.processorCount)) }
        }
    }
}
