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
                    Image("openrouter")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
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
                Button {
                    appState.saveOpenRouterConfig(
                        apiKey: apiKey,
                        model: model
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                } label: {
                    Text("Save Changes")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "7FADF2"))
                .disabled(!isFormValid)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Button {
                    settings.currentProvider = "openrouter"
                    appState.setCurrentProvider("openrouter")
                    dismiss()
                } label: {
                    Text("Set as Current Provider")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(settings.currentProvider == "openrouter")
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if !isFormValid {
                    Text("Enter an API key and model to save.")
                }
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
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
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
