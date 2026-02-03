import SwiftUI

struct PerplexitySettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaveConfirmation = false
    @State private var showHelp = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image("perplexity")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color(hex: "1FB8CD"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Perplexity")
                            .font(.headline)
                        Text("Configure your Perplexity API access")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Credentials") {
                SecureField("API Key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
            }

            Section("Model") {
                TextField("Model", text: $model, prompt: Text(PerplexityConfig.defaultModel))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Save Changes") {
                    appState.savePerplexityConfig(
                        apiKey: apiKey,
                        model: model
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(isFormValid ? Color(hex: "1FB8CD") : Color.gray)
                .disabled(!isFormValid)
            }

            Section {
                Button("Set as Current Provider") {
                    settings.currentProvider = "perplexity"
                    appState.setCurrentProvider("perplexity")
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(settings.currentProvider == "perplexity")
            }
        }
        .navigationTitle("Perplexity Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showHelp = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            ApiKeyHelpView(provider: "perplexity")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.perplexityApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.perplexityModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Perplexity settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !model.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.perplexityApiKey
        model = settings.perplexityModel
    }
}

#Preview("Perplexity Settings") {
    NavigationStack {
        PerplexitySettingsView(appState: .shared)
    }
}
