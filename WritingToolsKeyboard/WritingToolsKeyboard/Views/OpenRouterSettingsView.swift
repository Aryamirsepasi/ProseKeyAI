import SwiftUI

struct OpenRouterSettingsView: View {
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
                    Image(systemName: "o.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "7FADF2"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenRouter")
                            .font(.headline)
                        Text("Configure your OpenRouter API access")
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
                TextField("Model", text: $model, prompt: Text(OpenRouterConfig.defaultModel))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Save Changes") {
                    appState.saveOpenRouterConfig(
                        apiKey: apiKey,
                        model: model
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(isFormValid ? Color(hex: "7FADF2") : Color.gray)
                .disabled(!isFormValid)
            }

            Section {
                Button("Set as Current Provider") {
                    settings.currentProvider = "openrouter"
                    appState.setCurrentProvider("openrouter")
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(settings.currentProvider == "openrouter")
            }
        }
        .navigationTitle("OpenRouter Settings")
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
            ApiKeyHelpView(provider: "openrouter")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.openRouterApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.openRouterModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your OpenRouter settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !model.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.openRouterApiKey
        model = settings.openRouterModel
    }
}

#Preview("OpenRouter Settings") {
    NavigationStack {
        OpenRouterSettingsView(appState: .shared)
    }
}
