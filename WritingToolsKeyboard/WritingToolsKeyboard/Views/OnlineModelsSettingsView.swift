import SwiftUI

struct OnlineModelsSettingsView: View {
    @EnvironmentObject var appManager: AppManager
    
    @AppStorage("current_provider") private var currentProvider = "gemini"
    
    var body: some View {
        Form {
            Section(header: Text("AI Provider")) {
                Picker("Provider", selection: $currentProvider) {
                    Text("Gemini AI").tag("gemini")
                    Text("OpenAI").tag("openai")
                    Text("Mistral").tag("mistral")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Online Models")
        .navigationBarTitleDisplayMode(.inline)
    }
}
