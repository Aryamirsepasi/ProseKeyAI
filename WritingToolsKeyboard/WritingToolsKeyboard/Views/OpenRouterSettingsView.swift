import SwiftUI

struct OpenRouterSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "o.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "7FADF2"))
                    VStack(alignment: .leading) {
                        Text("OpenRouter")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your OpenRouter API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your OpenRouter API key",
                    text: $apiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: OpenRouterConfig.defaultModel,
                    text: $model
                )
                Button(action: {
                    appState.saveOpenRouterConfig(
                        apiKey: apiKey,
                        model: model
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
                .tint(isFormValid ? Color(hex: "7FADF2") : Color.gray)
                .disabled(!isFormValid)

                // Help text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting an OpenRouter API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "7FADF2"))
                        Text("Visit openrouter.ai")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "7FADF2"))
                        Text("Sign up or log in to your account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "7FADF2"))
                        Text("Navigate to Keys and create a new key")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("OpenRouter Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.openRouterApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.openRouterModel) { _ in syncFromSettings() }
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
