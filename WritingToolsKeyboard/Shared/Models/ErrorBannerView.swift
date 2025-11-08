import SwiftUI

/// A compact error banner designed for keyboard extensions
/// Following Apple HIG: clear, concise, non-blocking
struct ErrorBannerView: View {
    let error: AIError
    let onDismiss: () -> Void
    
    @State private var isVisible = true
    @State private var offset: CGFloat = -50
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: error.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text(error.shortMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = -50
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(errorBackgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .frame(maxWidth: 280) // Limit width to prevent taking full keyboard width
        .offset(y: offset)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            HapticsManager.shared.error()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = 0
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                guard isVisible else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = -50
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.shortMessage)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to dismiss")
    }
    
    private var errorBackgroundColor: Color {
        switch error {
        case .missingAPIKey, .invalidAPIKey, .unauthorized:
            return Color.orange
        case .networkError, .timeout:
            return Color.purple
        case .rateLimited, .insufficientQuota:
            return Color.orange
        case .emptyClipboard, .invalidSelection:
            return Color.gray
        default:
            return Color.red
        }
    }
}

// MARK: - View Extension for Easy Error Display
extension View {
    /// Displays an error banner at the top of the view
    func errorBanner(error: Binding<AIError?>) -> some View {
        ZStack(alignment: .top) {
            self
            
            if let currentError = error.wrappedValue {
                ErrorBannerView(error: currentError) {
                    error.wrappedValue = nil
                }
                .padding(.top, 4)
                .zIndex(999)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ErrorBannerView(error: .missingAPIKey) {}
        ErrorBannerView(error: .networkError) {}
        ErrorBannerView(error: .rateLimited) {}
        ErrorBannerView(error: .invalidSelection) {}
        ErrorBannerView(error: .serverError(statusCode: 500)) {}
    }
    .padding()
    .background(Color(.systemGray6))
}
