import SwiftUI

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var suggested: GeminiModel = .custom
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("google")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "4285F4"))

                    VStack(alignment: .leading) {
                        Text("Google Gemini")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Configure your Gemini API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Gemini API key",
                    text: $apiKey,
                    isSecure: true
                )

                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: "e.g. gemini-flash-latest",
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = GeminiModel(rawValue: newValue) {
                        suggested = matched
                    } else {
                        suggested = .custom
                    }
                }

                // Suggested models (picker)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Models")
                        .font(.headline)
                    Picker("Suggested Models", selection: $suggested) {
                        ForEach(GeminiModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if newValue != .custom {
                            modelName = newValue.rawValue
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Button(action: {
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
                }) {
                    Text("Save Changes")
                        .fontWeight(.bold)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFormValid ? Color(hex: "4285F4") : Color.gray)
                .disabled(!isFormValid)

                // Help text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Gemini API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "4285F4"))
                        Text("Visit Google AI Studio (ai.google.dev)")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "4285F4"))
                        Text("Sign in with your Google account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "4285F4"))
                        Text("Go to API → Get API Key")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("Gemini Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.geminiApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.geminiModel) { _ in syncFromSettings() }
        .onChange(of: settings.geminiCustomModel) { _ in syncFromSettings() }
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
