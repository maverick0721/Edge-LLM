import Foundation

@MainActor
final class EdgeLLMOnDeviceChatViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(
            role: .system,
            content: "Edge-LLM is ready for fully local chat on supported iPhone and iPad devices."
        )
    ]
    @Published var statusText = ""
    @Published var isGenerating = false

    private let engine = OnDeviceChatEngine()

    init() {
        statusText = engine.availabilityMessage
    }

    var canSend: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && isGenerating == false
            && engine.isAvailable
    }

    var canReset: Bool {
        isGenerating == false
    }

    func refreshAvailability() {
        statusText = engine.availabilityMessage
    }

    func resetConversation() {
        engine.resetSession()
        messages = [
            ChatMessage(
                role: .system,
                content: "Started a fresh on-device session."
            )
        ]
        refreshAvailability()
    }

    func sendCurrentPrompt() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard prompt.isEmpty == false else {
            return
        }

        inputText = ""
        statusText = engine.availabilityMessage
        isGenerating = true

        messages.append(ChatMessage(role: .user, content: prompt))
        messages.append(ChatMessage(role: .assistant, content: ""))

        let assistantIndex = messages.indices.last ?? 0

        Task {
            do {
                try await engine.streamResponse(to: prompt) { [weak self] partial in
                    guard let self else {
                        return
                    }

                    if self.messages.indices.contains(assistantIndex) {
                        self.messages[assistantIndex].content = partial
                    }
                }

                statusText = "On-device response complete."
            } catch {
                if messages.indices.contains(assistantIndex) {
                    messages[assistantIndex].content = "Unable to answer locally."
                }

                statusText = error.localizedDescription
            }

            isGenerating = false
        }
    }
}
