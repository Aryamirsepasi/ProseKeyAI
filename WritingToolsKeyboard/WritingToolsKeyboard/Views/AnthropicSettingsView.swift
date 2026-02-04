import SwiftUI

struct AnthropicSettingsView: View {
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
                    Image("anthropic")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color(hex: "c15f3c"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anthropic Claude")
                            .font(.headline)
                        Text("Configure your Anthropic API access")
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
                TextField("Model", text: $model, prompt: Text(AnthropicConfig.defaultModel))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button {
                    appState.saveAnthropicConfig(
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
                .tint(Color(hex: "c15f3c"))
                .disabled(!isFormValid)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Button {
                    settings.currentProvider = "anthropic"
                    appState.setCurrentProvider("anthropic")
                    dismiss()
                } label: {
                    Text("Set as Current Provider")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(settings.currentProvider == "anthropic")
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if !isFormValid {
                    Text("Enter an API key and model to save.")
                }
            }
        }
        .navigationTitle("Anthropic Settings")
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
            ApiKeyHelpView(provider: "anthropic")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.anthropicApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.anthropicModel) { _ in syncFromSettings() }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Anthropic settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !model.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.anthropicApiKey
        model = settings.anthropicModel
    }
}

#Preview("Anthropic Settings") {
    NavigationStack {
        AnthropicSettingsView(appState: .shared)
    }
}
