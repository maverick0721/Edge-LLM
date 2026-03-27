import SwiftUI

struct EdgeLLMOnDeviceChatView: View {
    @StateObject private var viewModel = EdgeLLMOnDeviceChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messages
            Divider()
            composer
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            viewModel.refreshAvailability()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edge-LLM On-Device")
                .font(.title2.weight(.semibold))

            Text(viewModel.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()

                Button("Reset Session") {
                    viewModel.resetConversation()
                }
                .disabled(viewModel.canReset == false)
            }
        }
        .padding()
    }

    private var messages: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(label(for: message.role))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(message.content.isEmpty ? "..." : message.content)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(bubbleColor(for: message.role))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
    }

    private var composer: some View {
        VStack(spacing: 12) {
            TextField("Ask something locally on this iPhone/iPad", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...6)

            HStack {
                Spacer()

                Button(viewModel.isGenerating ? "Thinking..." : "Send") {
                    viewModel.sendCurrentPrompt()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.canSend == false)
            }
        }
        .padding()
    }

    private func label(for role: ChatMessage.Role) -> String {
        switch role {
        case .system:
            return "System"
        case .user:
            return "You"
        case .assistant:
            return "Edge-LLM"
        }
    }

    private func bubbleColor(for role: ChatMessage.Role) -> Color {
        switch role {
        case .system:
            return Color(uiColor: .secondarySystemBackground)
        case .user:
            return Color.blue.opacity(0.12)
        case .assistant:
            return Color.green.opacity(0.12)
        }
    }
}
