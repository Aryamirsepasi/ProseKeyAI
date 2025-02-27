import SwiftUI
import MLXLMCommon

struct ModelsSettingsView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var llm: LocalLLMProvider
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("current_provider") private var currentProvider = "local"
    @State private var showModelInstaller = false
    @State private var isLoadingModel = false
    
    var body: some View {
        NavigationStack {
            List {
                // Provider Selection
                Section {
                    Picker("Provider", selection: $currentProvider) {
                        Text("Local Models").tag("local")
                        Text("Gemini AI").tag("gemini")
                        Text("OpenAI").tag("openai")
                        Text("Mistral").tag("mistral")
                    }
                }
                
                if currentProvider == "local" {
                    // Local Models Section
                    if !appManager.installedModels.isEmpty {
                        Section(header: Text("Installed Models")) {
                            ForEach(appManager.installedModels, id: \.self) { modelName in
                                HStack {
                                    Button {
                                        Task {
                                            await switchModel(modelName)
                                        }
                                    } label: {
                                        Label {
                                            Text(appManager.modelDisplayName(modelName))
                                                .tint(.primary)
                                        } icon: {
                                            if isLoadingModel && appManager.currentModelName != modelName {
                                                ProgressView()
                                                    .frame(width: 16, height: 16)
                                            } else {
                                                Image(systemName: appManager.currentModelName == modelName ? "checkmark.circle.fill" : "circle")
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Delete button
                                    Button(role: .destructive) {
                                        deleteModel(modelName)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .disabled(modelName == appManager.currentModelName)
                                }
                            }
                        }
                    }
                    
                    // Install Button
                    Button {
                        showModelInstaller = true
                    } label: {
                        Label("Install a Model", systemImage: "arrow.down.circle.dotted")
                    }
                } else {
                    // Online Models Section
                    Section {
                        NavigationLink {
                            OnlineModelsSettingsView()
                        } label: {
                            Text("Configure \(currentProvider.capitalized)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showModelInstaller) {
                ModelInstallationView()
            }
            .overlay {
                if isLoadingModel {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func switchModel(_ modelName: String) async {
        if modelName == appManager.currentModelName {
            return // Already selected
        }
        
        isLoadingModel = true
        // Load model in background
        Task.detached(priority: .userInitiated) {
            await llm.switchModel(modelName)
            await MainActor.run {
                appManager.currentModelName = modelName
                appManager.playHaptic()
                isLoadingModel = false
            }
        }
    }
    
    private func deleteModel(_ modelName: String) {
        if modelName == appManager.currentModelName {
            // Don't allow deleting the current model
            return
        }
        
        if let index = appManager.installedModels.firstIndex(of: modelName) {
            appManager.installedModels.remove(at: index)
            // Also reset the model state if this was the last model
            if appManager.installedModels.isEmpty {
                appManager.currentModelName = nil
                llm.loadState = .idle
            }
        }
    }
}
