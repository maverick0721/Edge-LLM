import SwiftUI
import UniformTypeIdentifiers

@available(macOS 11.0, *)
struct ContentView: View {
    @StateObject private var client = LlamaClient()
    @AppStorage("llama.model.path") private var persistedModelPath: String = ""

    @State private var prompt: String = "Hello from iOS"
    @State private var isGenerating: Bool = false
    @State private var isLoadingModel: Bool = false
    @State private var hasLoadedModel: Bool = false
    @State private var modelPath: String = ""
    @State private var modelStatus: String = "No model loaded"
    @State private var showingModelPicker: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.06), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        modelCard
                        promptCard
                        outputCard
                    }
                    .padding()
                }
            }
            .navigationTitle("LLama Demo")
            .fileImporter(
                isPresented: $showingModelPicker,
                allowedContentTypes: [ggufContentType],
                allowsMultipleSelection: false
            ) { result in
                handlePickedModel(result)
            }
            .onAppear {
                restorePersistedModelIfNeeded()
                if modelPath.isEmpty {
                    selectFirstModelInDocuments(autoLoad: false)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On-device Inference")
                .font(.title2.bold())
            Text("Load a GGUF model, enter a prompt, and stream generated tokens.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text(client.bridgeVersion.isEmpty ? "Bridge: unavailable" : "Bridge: \(client.bridgeVersion)")
                    .font(.footnote.monospaced())
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
    }

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Model")
                    .font(.headline)
                Spacer()
                Button("Use Documents") {
                    selectFirstModelInDocuments(autoLoad: false)
                }
                .buttonStyle(.bordered)

                Button("Pick Model") {
                    showingModelPicker = true
                }
                .buttonStyle(.borderedProminent)
            }

            TextField("GGUF model path", text: $modelPath)
                .textFieldStyle(.roundedBorder)

            HStack {
                Circle()
                    .fill(modelStatusColor)
                    .frame(width: 8, height: 8)
                Text(modelStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Button(isLoadingModel ? "Loading..." : "Load") {
                    loadModel(at: modelPath)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingModel || modelPath.isEmpty)

                Spacer()

                Button("Clear Output") {
                    client.clearOutput()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prompt")
                .font(.headline)

            TextEditor(text: $prompt)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(10)

            Button {
                startGeneration()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isGenerating ? "Generating..." : "Generate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
            .background(hasLoadedModel ? Color.blue : Color.gray)
            .cornerRadius(12)
            .disabled(isGenerating || !hasLoadedModel || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                if isGenerating {
                    Text("Streaming")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }

            ScrollView {
                Text(client.output.isEmpty ? "Generated text will appear here." : client.output)
                    .font(.body.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(minHeight: 180)
            .background(secondaryBackgroundColor)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var modelStatusColor: Color {
        if isLoadingModel {
            return .orange
        }
        if hasLoadedModel {
            return .green
        }
        return .red
    }

    private var ggufContentType: UTType {
        UTType(filenameExtension: "gguf") ?? .data
    }

    private func startGeneration() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return
        }

        isGenerating = true
        client.output += "\n\n> \(trimmedPrompt)\n"
        client.generate(prompt: trimmedPrompt) {
            isGenerating = false
        }
    }

    private func handlePickedModel(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else {
                modelStatus = "No file selected"
                return
            }

            guard let localURL = stageModelForLocalAccess(sourceURL) else {
                modelStatus = "Failed to import model file"
                return
            }

            modelPath = localURL.path
            persistedModelPath = localURL.path
            modelStatus = "Model selected: \(localURL.lastPathComponent)"
            loadModel(at: localURL.path)

        case .failure(let error):
            modelStatus = "Model picker error: \(error.localizedDescription)"
        }
    }

    private func stageModelForLocalAccess(_ sourceURL: URL) -> URL? {
        let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let destinationURL = baseDirectory.appendingPathComponent(sourceURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    private func restorePersistedModelIfNeeded() {
        guard !persistedModelPath.isEmpty else { return }
        guard FileManager.default.fileExists(atPath: persistedModelPath) else {
            persistedModelPath = ""
            return
        }

        modelPath = persistedModelPath
        modelStatus = "Restoring model: \(URL(fileURLWithPath: persistedModelPath).lastPathComponent)"
        loadModel(at: persistedModelPath)
    }

    private func selectFirstModelInDocuments(autoLoad: Bool) {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        guard let docsURL else {
            modelStatus = "Documents folder unavailable"
            return
        }

        guard let files = try? fileManager.contentsOfDirectory(
            at: docsURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            modelStatus = "Failed to list Documents"
            return
        }

        guard let modelURL = files
            .filter({ $0.pathExtension.lowercased() == "gguf" })
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .first
        else {
            modelStatus = "No .gguf file in Documents"
            return
        }

        modelPath = modelURL.path
        persistedModelPath = modelURL.path
        modelStatus = "Model selected: \(modelURL.lastPathComponent)"

        if autoLoad {
            loadModel(at: modelURL.path)
        }
    }

    private func loadModel(at path: String) {
        guard !path.isEmpty else {
            hasLoadedModel = false
            modelStatus = "No model path set"
            return
        }
        guard FileManager.default.fileExists(atPath: path) else {
            hasLoadedModel = false
            modelStatus = "Model file not found"
            return
        }
        guard path.lowercased().hasSuffix(".gguf") else {
            hasLoadedModel = false
            modelStatus = "Only .gguf model files are supported"
            return
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
           let bytes = attrs[.size] as? NSNumber {
            // Reject tiny vocab-only GGUF files that cannot generate normal text.
            if bytes.int64Value < 100 * 1024 * 1024 {
                hasLoadedModel = false
                modelStatus = "GGUF file too small (likely vocab-only, not a chat model)"
                return
            }
        }

        isLoadingModel = true
        modelStatus = "Loading model..."
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = client.reloadModel(modelPath: path)
            DispatchQueue.main.async {
                isLoadingModel = false
                hasLoadedModel = ok
                modelStatus = ok ? "Model loaded: \(URL(fileURLWithPath: path).lastPathComponent)" : "Model load failed"
                client.output += "\nModel load: \(ok ? "success" : "failure") (\(path))\n"
            }
        }
    }
}

@available(macOS 10.15, *)
private var secondaryBackgroundColor: Color {
#if os(iOS)
    return Color(UIColor.secondarySystemBackground)
#else
    return Color.gray.opacity(0.12)
#endif
}
