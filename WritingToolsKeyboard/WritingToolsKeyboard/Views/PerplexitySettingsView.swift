import SwiftUI

struct PerplexitySettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @State private var apiKey: String = ""
    @State private var model: String = ""
    @State private var showSaveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("perplexity")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "1FB8CD"))
                    VStack(alignment: .leading) {
                        Text("Perplexity")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your Perplexity API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Perplexity API key",
                    text: $apiKey,
                    isSecure: true
                )

                // Model field
                LabeledTextField(
                    label: "Model",
                    placeholder: PerplexityConfig.defaultModel,
                    text: $model
                )

                Button(action: {
                    appState.savePerplexityConfig(
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
                .tint(isFormValid ? Color(hex: "1FB8CD") : Color.gray)
                .disabled(!isFormValid)

                // Optional help section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Perplexity API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Visit perplexity.ai and create an account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Navigate to your account/API keys page")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Create a new API key and copy it")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("Perplexity Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncFromSettings)
        .onChange(of: settings.perplexityApiKey) { _ in syncFromSettings() }
        .onChange(of: settings.perplexityModel) { _ in syncFromSettings() }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Perplexity settings have been updated.")
        }
    }

    private var isFormValid: Bool {
        !apiKey.isEmpty && !model.isEmpty
    }

    private func syncFromSettings() {
        apiKey = settings.perplexityApiKey
        model = settings.perplexityModel
    }
}

#Preview("Perplexity Settings") {
    NavigationStack {
        PerplexitySettingsView(appState: .shared)
    }
}
