import SwiftUI

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var suggested: GeminiModel = .custom
    @State private var showSaveConfirmation = false
    @State private var showHelp = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image("google")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color(hex: "4285F4"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Google Gemini")
                            .font(.headline)
                        Text("Configure your Gemini API access")
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
                TextField("Model", text: $modelName, prompt: Text("gemini-flash-latest"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChangeCompat(of: modelName) { newValue in
                        if let matched = GeminiModel(rawValue: newValue) {
                            suggested = matched
                        } else {
                            suggested = .custom
                        }
                    }

                Picker("Suggested Models", selection: $suggested) {
                    ForEach(GeminiModel.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .onChangeCompat(of: suggested) { newValue in
                    if newValue != .custom {
                        modelName = newValue.rawValue
                    }
                }
            }

            Section {
                Button {
                    let resolvedModel: GeminiModel
                    let custom: String
                    if let match = GeminiModel(rawValue: modelName) {
                        resolvedModel = match
                        custom = ""
                    } else {
                        resolvedModel = .custom
                        custom = modelName
                    }
                    appState.saveGeminiConfig(
                        apiKey: apiKey,
                        model: resolvedModel,
                        customModelName: custom
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                } label: {
                    Text("Save Changes")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "4285F4"))
                .disabled(!isFormValid)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Button {
                    settings.currentProvider = "gemini"
                    appState.setCurrentProvider("gemini")
                    dismiss()
                } label: {
                    Text("Set as Current Provider")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(settings.currentProvider == "gemini")
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if !isFormValid {
                    Text("Enter an API key and model to save.")
                }
            }
        }
        .navigationTitle("Gemini Settings")
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
            ApiKeyHelpView(provider: "gemini")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.geminiApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.geminiModel) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.geminiCustomModel) { _ in syncFromSettings() }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Gemini settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !modelName.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.geminiApiKey
        let current = settings.geminiModel
        modelName = current == .custom ? settings.geminiCustomModel : current.rawValue
        suggested = current
    }
}

#Preview("Gemini Settings") {
    NavigationStack {
        GeminiSettingsView(appState: .shared)
    }
}
