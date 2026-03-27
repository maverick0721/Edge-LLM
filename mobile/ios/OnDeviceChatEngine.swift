import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum OnDeviceChatEngineError: LocalizedError {
    case unsupportedPlatform
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            return "This iPhone/iPad needs iOS or iPadOS 26 or later with Apple Intelligence support for fully local Edge-LLM."
        case let .modelUnavailable(message):
            return message
        }
    }
}

@MainActor
final class OnDeviceChatEngine {
    private let systemPrompt = """
    You are Edge-LLM running fully on-device on iPhone or iPad.
    Be concise, helpful, and clear.
    """

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private var session: LanguageModelSession?
    #endif

    init() {
        resetSession()
    }

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif

        return false
    }

    var availabilityMessage: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            if availability == .available {
                return "Running fully local on Apple Foundation Models."
            }

            return "On-device model unavailable: \(String(describing: availability)). Check Apple Intelligence support and settings."
        }
        #endif

        return "Foundation Models is unavailable in this SDK/runtime. Use an Apple Intelligence-capable iPhone/iPad on iOS or iPadOS 26 or later."
    }

    func resetSession() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            session = LanguageModelSession(instructions: systemPrompt)
        }
        #endif
    }

    func streamResponse(
        to prompt: String,
        onPartial: @escaping (String) -> Void
    ) async throws {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            guard availability == .available else {
                throw OnDeviceChatEngineError.modelUnavailable(
                    "On-device model unavailable: \(String(describing: availability)). Check Apple Intelligence support and settings."
                )
            }

            if session == nil {
                session = LanguageModelSession(instructions: systemPrompt)
            }

            guard let session else {
                throw OnDeviceChatEngineError.modelUnavailable(
                    "Unable to create the on-device model session."
                )
            }

            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                onPartial(partial.content)
            }
            return
        }
        #endif

        throw OnDeviceChatEngineError.unsupportedPlatform
    }
}
