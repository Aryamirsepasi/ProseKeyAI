import SwiftUI
import SwiftData

struct MainChatView: View {
    @StateObject private var appManager = AppManager()
    @StateObject private var appState = AppState.shared
    @State private var llm = LocalLLMProvider()
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var showChats = false
    @State private var currentThread: Thread?
    @FocusState private var isPromptFocused: Bool
    
    @AppStorage("current_provider") private var currentProvider = "local"
    
    var body: some View {
        Group {
            if appManager.userInterfaceIdiom == .pad {
                // iPad
                NavigationSplitView {
                    ChatsListView(currentThread: $currentThread, isPromptFocused: $isPromptFocused)
                } detail: {
                    ChatView(currentThread: $currentThread,
                             isPromptFocused: $isPromptFocused,
                             showChats: $showChats,
                             showSettings: $showSettings)
                }
            } else {
                // iPhone
                ChatView(currentThread: $currentThread,
                         isPromptFocused: $isPromptFocused,
                         showChats: $showChats,
                         showSettings: $showSettings)
            }
        }
        .environmentObject(appManager)
        .environmentObject(appState)
        .environmentObject(llm)
        .task {
            if currentProvider == "local" {
                if appManager.installedModels.isEmpty {
                    showOnboarding.toggle()
                } else {
                    if let modelName = appManager.currentModelName {
                        _ = try? await llm.load(modelName: modelName)
                    }
                }
            }
        }
        .sheet(isPresented: $showChats) {
            ChatsListView(currentThread: $currentThread, isPromptFocused: $isPromptFocused)
                .environmentObject(appManager)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            ModelsSettingsView()
                .environmentObject(appManager)
                .environmentObject(appState)
                .environmentObject(llm)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.medium])
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
