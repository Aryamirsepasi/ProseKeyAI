import SwiftUI
import MLXLMCommon

struct ModelInstallationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var llm: LocalLLMProvider
    @EnvironmentObject var appManager: AppManager
    @State private var selectedModelName: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Available Models")) {
                    ForEach(ModelConfiguration.availableModels, id: \.name) { model in
                        Button {
                            selectedModelName = model.name
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(appManager.modelDisplayName(model.name))
                                        .foregroundColor(.primary)
                                    Text("Size: \(model.size.formatted()) GB")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: selectedModelName == model.name ? "checkmark.circle.fill" : "circle")
                            }
                        }
                        .disabled(llm.isDownloading || appManager.installedModels.contains(model.name))
                    }
                }
            }
            .navigationTitle("Install Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Download") {
                        downloadSelectedModel()
                    }
                    .disabled(selectedModelName == nil || llm.isDownloading)
                }
            }
            .overlay {
                if llm.isDownloading {
                    downloadOverlay
                }
            }
        }
    }
    
    var downloadOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView(value: llm.progress) {
                    Text(llm.progress < 0.01 ? "Preparing..." :
                            llm.progress >= 0.99 ? "Installing..." :
                            "Downloading model...")
                }
                .progressViewStyle(.linear)
                .padding()
                
                if let error = llm.downloadError {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                } else if llm.progress >= 0.99 {
                    Text("Installing...")
                }
            }
            .frame(width: 250)
            .background(.background)
            .cornerRadius(12)
        }
    }
    
    private func downloadSelectedModel() {
        guard let modelName = selectedModelName else { return }
        
        Task {
            await llm.switchModel(modelName)
            if case .loaded = llm.loadState {
                appManager.currentModelName = modelName
                appManager.addInstalledModel(modelName)
                dismiss()
            }
        }
    }
}
