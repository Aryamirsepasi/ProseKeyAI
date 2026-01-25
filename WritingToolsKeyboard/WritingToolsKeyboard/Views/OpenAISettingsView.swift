import SwiftUI

struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var modelName: String = ""
    @State private var showSaveConfirmation = false
    private enum SuggestedOpenAI: Hashable {
        case custom
        case model(OpenAIModel)
    }
    @State private var suggested: SuggestedOpenAI = .custom


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("openai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white)

                    VStack(alignment: .leading) {
                        Text("OpenAI")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Configure your OpenAI API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your OpenAI API key",
                    text: $apiKey,
                    isSecure: true
                )

                LabeledTextField(
                    label: "Base URL",
                    placeholder: "https://api.openai.com",
                    text: $baseURL
                )

                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: "gpt-5-mini",
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = OpenAIModel(rawValue: newValue) {
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
                        Text("Custom").tag(SuggestedOpenAI.custom)
                        ForEach(OpenAIModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(SuggestedOpenAI.model(option))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if case let .model(m) = newValue {
                            modelName = m.rawValue
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Button(action: {
                    appState.saveOpenAIConfig(
                        apiKey: apiKey,
                        baseURL: baseURL,
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
                .tint(isFormValid ? Color(hex: "412991") : Color.gray)
                .disabled(!isFormValid)

                // Help section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting an OpenAI API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "412991"))
                        Text("Go to platform.openai.com")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "412991"))
                        Text("Select API keys from settings")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "412991"))
                        Text("Create a new secret key")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("OpenAI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.openAIApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.openAIBaseURL) { _ in syncFromSettings() }
        .onChange(of: settings.openAIModel) { _ in syncFromSettings() }
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
