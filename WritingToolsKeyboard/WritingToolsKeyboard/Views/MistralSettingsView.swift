import SwiftUI

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var showSaveConfirmation = false
    private enum SuggestedMistral: Hashable {
        case custom
        case model(MistralModel)
    }
    @State private var suggested: SuggestedMistral = .custom


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("mistralai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "FA520F"))

                    VStack(alignment: .leading) {
                        Text("Mistral AI")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Configure your Mistral API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Mistral API key",
                    text: $apiKey,
                    isSecure: true
                )

                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: MistralConfig.defaultModel,
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = MistralModel(rawValue: newValue) {
                        suggested = .model(matched)
                    } else {
                        suggested = .custom
                    }
                }

                // Suggested models (picker)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Models")
                        .font(.headline)
                    Picker("Suggested Models", selection: $suggested) {
                        Text("Custom").tag(SuggestedMistral.custom)
                        ForEach(MistralModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(SuggestedMistral.model(option))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if case let .model(m) = newValue {
                            modelName = m.rawValue
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Button(action: {
                    appState.saveMistralConfig(
                        apiKey: apiKey,
                        model: modelName
                    )
                    HapticsManager.shared.success()
                    showSaveConfirmation = true
                }) {
                    Text("Save Changes")
                        .fontWeight(.bold)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFormValid ? Color(hex: "FA520F") : Color.gray)
                .disabled(!isFormValid)

                // Help info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Mistral API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
                        Text("Visit console.mistral.ai")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
                        Text("Sign up or log in to your account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
                        Text("Navigate to API Keys and create a new key")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("Mistral Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.mistralApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.mistralModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
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
