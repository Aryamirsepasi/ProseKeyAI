import SwiftUI

struct AnthropicSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image("anthropic")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "c15f3c"))
                    VStack(alignment: .leading) {
                        Text("Anthropic Claude")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your Anthropic API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Anthropic API key",
                    text: $apiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: AnthropicConfig.defaultModel,
                    text: $model
                )
                Button(action: {
                    appState.saveAnthropicConfig(
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
                .tint(isFormValid ? Color(hex: "c15f3c") : Color.gray)
                .disabled(!isFormValid)

                // Help text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting an Anthropic API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "c15f3c"))
                        Text("Visit console.anthropic.com")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "c15f3c"))
                        Text("Sign up or log in to your account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "c15f3c"))
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
        .navigationTitle("Anthropic Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.anthropicApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.anthropicModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
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
