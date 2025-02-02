import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @Binding var currentThread: Thread?
    @EnvironmentObject var llm: LocalLLMProvider
    @Namespace var bottomID
    @State var showModelPicker = false
    @State var prompt = ""
    @FocusState.Binding var isPromptFocused: Bool
    @Binding var showChats: Bool
    @Binding var showSettings: Bool
    
    @State var thinkingTime: TimeInterval?
    @State private var generatingThreadID: UUID?
    
    @AppStorage("current_provider") private var currentProvider = "local"
    @EnvironmentObject var appState: AppState
    
    // state variables for file and photo picking:
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    
    var isPromptEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // The attach button styled similarly to the send button.
    var attachButton: some View {
        Menu {
            Button {
                showFileImporter = true
            } label: {
                Label("Files (Images) OCR", systemImage: "doc")
            }
            Button {
                showPhotoPicker = true
            } label: {
                Label("Photos App OCR", systemImage: "photo")
            }
        } label: {
            Image(systemName: "paperclip.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .help("Attach an image file or photo")
        .padding(.leading, 12)
        .padding(.bottom, 12)
    }
    
    var chatInput: some View {
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 0) {
                    attachButton
                    
                    TextField("Message", text: $prompt, axis: .vertical)
                        .focused($isPromptFocused)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: 48)
                        .onSubmit {
                            isPromptFocused = true
                            generate()
                        }
                    
                    if llm.running {
                        stopButton
                    } else {
                        generateButton
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                
            }
        }
    
    var generateButton: some View {
        Button {
            generate()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(isPromptEmpty)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    var stopButton: some View {
        Button {
            llm.stop()
        } label: {
            Image(systemName: "stop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(llm.cancelled)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if let currentThread = currentThread {
                        ConversationView(thread: currentThread, generatingThreadID: generatingThreadID)
                    } else {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.quaternary)
                        Spacer()
                    }
                    
                    
                    chatInput
                        .padding()
                    
                }
                .navigationTitle(currentThread?.title ?? "Chat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if appManager.userInterfaceIdiom == .phone {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                appManager.playHaptic()
                                showChats.toggle()
                            }) {
                                Image(systemName: "list.bullet")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            appManager.playHaptic()
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isPromptFocused {
                    Button(action: {
                        isPromptFocused = false
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(uiColor: .tertiarySystemBackground))
                    }
                }
            }
            // MARK: - File Importer for Files option
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.png, UTType.jpeg, UTType.tiff, UTType.gif],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        do {
                            let fileData = try Data(contentsOf: url)
                            DispatchQueue.main.async {
                                appState.selectedImages.append(fileData)
                            }
                        } catch {
                            print("Error reading file: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("File import failed: \(error.localizedDescription)")
                }
            }
            // MARK: - Photo Picker for Photos option
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(isPresented: $showPhotoPicker) { imageData in
                    DispatchQueue.main.async {
                        appState.selectedImages.append(imageData)
                    }
                }
            }
        }
    }
    
    private func generate() {
        if !isPromptEmpty {
            if currentThread == nil {
                let newThread = Thread()
                currentThread = newThread
                modelContext.insert(newThread)
                try? modelContext.save()
            }
            
            if let currentThread = currentThread {
                generatingThreadID = currentThread.id
                Task {
                    let message = prompt
                    prompt = ""
                    appManager.playHaptic()
                    sendMessage(Message(role: .user, content: message, thread: currentThread))
                    isPromptFocused = true
                    
                    let output = await ChatMessageHandler.processMessage(
                        content: message,
                        thread: currentThread,
                        appState: appState,
                        llm: llm,
                        appManager: appManager,
                        currentProvider: currentProvider
                    )
                    
                    sendMessage(Message(role: .assistant, content: output, thread: currentThread, generatingTime: llm.isProcessing ? 1.0 : nil))
                    generatingThreadID = nil
                }
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        appManager.playHaptic()
        modelContext.insert(message)
        try? modelContext.save()
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImagePicked: (Data) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed.
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker
        
        init(parent: PhotoPicker) {
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.isPresented = false
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.onImagePicked(data)
            }
        }
    }
}
