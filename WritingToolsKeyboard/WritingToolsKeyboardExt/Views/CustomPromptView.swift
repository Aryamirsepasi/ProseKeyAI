import SwiftUI

struct CustomPromptView: View {
    let selectedText: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @Binding var prompt: String
    @State private var cursorPosition = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - matching ClipboardHistoryView style (44pt + divider)
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Custom Prompt")
                    .font(.headline)
                
                Spacer()
                
                Button("Submit") {
                    let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSubmit(trimmed) }
                }
                .font(.body)
                .foregroundStyle(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 44)
            
            Divider()
            
            Spacer()
            
            // Text preview - compact single row
            ScrollView(.horizontal) {
                Text(selectedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6), in: .rect(cornerRadius: 6))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Spacer()
            
            // Text input field
            TextField("Type your custom instructions for the AI…", text: $prompt)
                .font(.body)
                .frame(height: 32)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple, lineWidth: 1.5)
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .focused($isTextFieldFocused)
            
            
            Spacer()
            
            // Custom Keyboard
            CustomInstructionKeyboardRepresentable(
                text: $prompt,
                cursorPosition: $cursorPosition,
                onReturn: {
                    let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSubmit(trimmed) }
                }
            )
            .frame(height: 190)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}


