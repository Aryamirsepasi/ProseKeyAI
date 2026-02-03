import SwiftUI

struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var modelName: String = ""
    @State private var showSaveConfirmation = false
    @State private var showHelp = false

    private enum SuggestedOpenAI: Hashable {
        case custom
        case model(OpenAIModel)
    }
    @State private var suggested: SuggestedOpenAI = .custom

    var body: some View {
        Form {
            Section {
                HStack {
                    Image("openai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenAI")
                            .font(.headline)
                        Text("Configure your OpenAI API access")
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
                TextField("Base URL", text: $baseURL, prompt: Text("https://api.openai.com"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Model") {
                TextField("Model", text: $modelName, prompt: Text("gpt-5-mini"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChangeCompat(of: modelName) { newValue in
                        if let matched = OpenAIModel(rawValue: newValue) {
                            suggested = .model(matched)
                        } else {
                            suggested = .custom
                        }
                    }

                Picker("Suggested Models", selection: $suggested) {
                    Text("Custom").tag(SuggestedOpenAI.custom)
                    ForEach(OpenAIModel.allCases, id: \.self) { option in
                        Text(option.displayName).tag(SuggestedOpenAI.model(option))
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
                Button("Save Changes") {
                    appState.saveOpenAIConfig(
                        apiKey: apiKey,
                        baseURL: baseURL,
                        model: modelName
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .tint(isFormValid ? Color(hex: "412991") : Color.gray)
                .disabled(!isFormValid)
            }

            Section {
                Button("Set as Current Provider") {
                    settings.currentProvider = "openai"
                    appState.setCurrentProvider("openai")
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(settings.currentProvider == "openai")
            }
        }
        .navigationTitle("OpenAI Settings")
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
            ApiKeyHelpView(provider: "openai")
        }
        .onAppear(perform: syncFromSettings)
        .onChangeCompat(of: settings.openAIApiKey) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.openAIBaseURL) { _ in syncFromSettings() }
        .onChangeCompat(of: settings.openAIModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your OpenAI settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !baseURL.isEmpty && !modelName.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.openAIApiKey
        baseURL = settings.openAIBaseURL
        modelName = settings.openAIModel
        if let match = OpenAIModel(rawValue: settings.openAIModel) {
            suggested = .model(match)
        } else {
            suggested = .custom
        }
    }
}

#Preview("OpenAI Settings") {
    NavigationStack {
        OpenAISettingsView(appState: .shared)
    }
}
