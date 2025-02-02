import SwiftUI
import StoreKit
import SwiftData

struct ChatsListView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.dismiss) var dismiss
    @Binding var currentThread: Thread?
    @FocusState.Binding var isPromptFocused: Bool
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Thread.timestamp, order: .reverse) var threads: [Thread]
    @State var search = ""
    @State var selection: Thread?
    
    @State private var showClearHistoryAlert = false

    // Use ProcessInfo to check if we’re running in an extension.
    private var isExtension: Bool {
        return ProcessInfo.processInfo.environment["NSExtension"] != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List(selection: $selection) {
                    ForEach(filteredThreads, id: \.id) { thread in
                        VStack(alignment: .leading) {
                            ZStack {
                                if let firstMessage = thread.sortedMessages.first {
                                    Text(firstMessage.content)
                                        .lineLimit(1)
                                } else {
                                    Text("untitled")
                                }
                            }
                            .foregroundStyle(.primary)
                            .font(.headline)

                            Text("\(thread.timestamp.formatted())")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        .swipeActions {
                            Button("Delete") {
                                deleteThread(thread)
                            }
                            .tint(.red)
                        }
                        .tag(thread)
                    }
                    .onDelete(perform: deleteThreads)
                }
                .onChange(of: selection) {
                    setCurrentThread(selection)
                }
                .listStyle(.insetGrouped)
                
                if filteredThreads.isEmpty {
                    ContentUnavailableView {
                        Label(threads.isEmpty ? "No chats yet" : "No results", systemImage: "message")
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search")
            .toolbar {
                if appManager.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                    }
                }
                // Group multiple items on the trailing side.
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Plus button to create a new chat.
                    Button(action: {
                        selection = nil
                        setCurrentThread(nil)
                    }) {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("N", modifiers: [.command])
                    
                }
            }
        }
    }

    var filteredThreads: [Thread] {
        threads.filter { thread in
            search.isEmpty || thread.messages.contains { message in
                message.content.localizedCaseInsensitiveContains(search)
            }
        }
    }

    private func deleteThreads(at offsets: IndexSet) {
        for offset in offsets {
            let thread = threads[offset]
            if let currentThread = currentThread, currentThread.id == thread.id {
                setCurrentThread(nil)
            }
            DispatchQueue.main.async {
                modelContext.delete(thread)
            }
        }
    }

    private func deleteThread(_ thread: Thread) {
        if let currentThread = currentThread, currentThread.id == thread.id {
            setCurrentThread(nil)
        }
        modelContext.delete(thread)
    }

    private func setCurrentThread(_ thread: Thread? = nil) {
        currentThread = thread
        isPromptFocused = true
        if appManager.userInterfaceIdiom == .phone {
            dismiss()
        }
        appManager.playHaptic()
    }
    
}
