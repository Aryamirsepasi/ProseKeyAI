import SwiftUI

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var showSaveConfirmation = false
    @State private var showHelp = false

    private enum SuggestedMistral: Hashable {
        case custom
        case model(MistralModel)
    }
    @State private var suggested: SuggestedMistral = .custom

    var body: some View {
        Form {
            Section {
                HStack {
                    Image("mistralai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color(hex: "FA520F"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mistral AI")
                            .font(.headline)
                        Text("Configure your Mistral API access")
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
                TextField("Model", text: $modelName, prompt: Text(MistralConfig.defaultModel))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChangeCompat(of: modelName) { newValue in
                        if let matched = MistralModel(rawValue: newValue) {
                            suggested = .model(matched)
                        } else {
                            suggested = .custom
                        }
                    }

                Picker("Suggested Models", selection: $suggested) {
                    Text("Custom").tag(SuggestedMistral.custom)
                    ForEach(MistralModel.allCases, id: \.self) { option in
                        Text(option.displayName).tag(SuggestedMistral.model(option))
                    }
                }
                .pickerStyle(.menu)
                .onChangeCompat(of: suggested) { newValue in
                    if case let .model(m) = newValue {
                        modelName = m.rawValue
                    }
                }
            }

            Section {
                Button {
                    appState.saveMistralConfig(
                        apiKey: apiKey,
                        model: modelName
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                } label: {
                    Text("Save Changes")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "FA520F"))
                .disabled(!isFormValid)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Button {
                    settings.currentProvider = "mistral"
                    appState.setCurrentProvider("mistral")
                    dismiss()
                } label: {
                    Text("Set as Current Provider")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(settings.currentProvider == "mistral")
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if !isFormValid {
                    Text("Enter an API key and model to save.")
                }
            }
        }
        .navigationTitle("Mistral Settings")
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
            ApiKeyHelpView(provider: "mistral")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.mistralApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.mistralModel) { _ in syncFromSettings() }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Mistral settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !modelName.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.mistralApiKey
        modelName = settings.mistralModel
        if let match = MistralModel(rawValue: settings.mistralModel) {
            suggested = .model(match)
        } else {
            suggested = .custom
        }
    }
}

#Preview("Mistral Settings") {
    NavigationStack {
        MistralSettingsView(appState: .shared)
    }
}
