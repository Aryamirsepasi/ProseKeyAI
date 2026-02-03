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
                Button("Save Changes") {
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
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(isFormValid ? Color(hex: "4285F4") : Color.gray)
                .disabled(!isFormValid)
            }

            Section {
                Button("Set as Current Provider") {
                    settings.currentProvider = "gemini"
                    appState.setCurrentProvider("gemini")
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(settings.currentProvider == "gemini")
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
        .alert("Saved", isPresented: $showSaveConfirmation) {
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
