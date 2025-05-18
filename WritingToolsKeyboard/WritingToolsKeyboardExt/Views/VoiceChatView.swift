/*import SwiftUI
import Speech

struct VoiceChatView: View {
    let selectedText: String
    let onResult: (_ prompt: String, _ aiResult: String) -> Void
    let onCancel: () -> Void

    @StateObject private var speechVM = SpeechRecognizerViewModel()
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Solid background for clarity
            Color(.systemBackground)
                .opacity(0.97)
                .ignoresSafeArea()
            // Gradient overlay for style
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Text("Speak your prompt about the selected text")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ZStack {
                    Circle()
                        .fill(speechVM.isRecording ? Color.purple.opacity(0.2) : Color.gray.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(speechVM.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut, value: speechVM.isRecording)
                    Image(systemName: speechVM.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                }
                .onTapGesture {
                    if speechVM.isRecording {
                        speechVM.stopRecording()
                    } else {
                        speechVM.startRecording()
                    }
                }
                .accessibilityLabel(speechVM.isRecording ? "Stop recording" : "Start recording")

                // Show recognized text live, or a hint if empty
                if !speechVM.transcribedText.isEmpty {
                    Text(speechVM.transcribedText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.primary)
                        .transition(.opacity)
                } else {
                    Text("Tap the mic and speak your instruction for the AI.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()

                HStack {
                    Button("Cancel") {
                        speechVM.stopRecording()
                        onCancel()
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)

                    Spacer()

                    Button(action: {
                        processAI()
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Send")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(speechVM.transcribedText.isEmpty ? Color.gray : Color.purple)
                        .cornerRadius(10)
                    }
                    .disabled(speechVM.transcribedText.isEmpty || isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }

            if isProcessing {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView("Processing with AI...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
            if !speechVM.debugStatus.isEmpty {
                Text(speechVM.debugStatus)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }

        }
        .onAppear {
            speechVM.requestPermission()
        }
    }

    private func processAI() {
        guard !speechVM.transcribedText.isEmpty else { return }
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: nil,
                    userPrompt: speechVM.transcribedText + "\n\n[Selected text:]\n" + selectedText,
                    images: [],
                    streaming: false
                )
                await MainActor.run {
                    isProcessing = false
                    onResult(speechVM.transcribedText, result)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}*/
