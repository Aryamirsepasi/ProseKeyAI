import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    
    // Keep track of setup status
    @State private var isKeyboardEnabled: Bool = false
    @State private var isFullAccessEnabled: Bool = false
    @State private var hasCheckedSetup: Bool = false
    
    private let totalPages = 5
    
    // Color theme
    private let accentColor = Color.blue
    private let backgroundGradient = LinearGradient(
        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                // Progress indicator
                HStack {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(currentPage >= index ? accentColor : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Skip button (except on last page)
                if currentPage < totalPages - 1 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasCompletedOnboarding = true
                            dismiss()
                        }
                        .padding()
                        .foregroundColor(.secondary)
                    }
                }
                
                // Page content - using TabView for smooth swiping
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    keyboardSetupPage
                        .tag(1)
                    
                    fullAccessPage
                        .tag(2)
                        
                    textSelectionPage
                        .tag(3)
                    
                    finishPage
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            if currentPage == totalPages - 1 {
                                // Complete onboarding
                                hasCompletedOnboarding = true
                                dismiss()
                            } else {
                                currentPage += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            checkKeyboardStatus()
        }
    }
    
    // MARK: - Onboarding Pages
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Image(systemName: "keyboard")
                .font(.system(size: 80))
                .foregroundColor(accentColor)
                .padding(.bottom, 20)
            
            Text("Welcome to ProseKey AI")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Transform your writing with AI tools directly from your keyboard")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }
    
    private var keyboardSetupPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 60))
                .foregroundColor(accentColor)
                .padding(.bottom, 20)
            
            Text("Enable the Keyboard")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Let's set up your AI writing keyboard to start enhancing your text")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            SetupStepsView(
                title: "To enable your keyboard:",
                steps: [
                    "Open Settings",
                    "Go to General → Keyboard",
                    "Tap Keyboards → Add New Keyboard",
                    "Select ProseKey AI Keyboard"
                ],
                isComplete: $isKeyboardEnabled,
                completeText: "Keyboard Enabled"
            )
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                
                // Check keyboard status after a short delay to allow user to switch back
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    checkKeyboardStatus()
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }
    
    private var fullAccessPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 60))
                .foregroundColor(accentColor)
                .padding(.bottom, 20)
            
            Text("Enable Full Access")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Full access is required for the keyboard to access AI tools and use copy/paste features")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            SetupStepsView(
                title: "To enable full access:",
                steps: [
                    "Open Settings → General → Keyboard",
                    "Select ProseKey AI Keyboard",
                    "Toggle on \"Allow Full Access\"",
                    "Confirm when prompted"
                ],
                isComplete: $isFullAccessEnabled,
                completeText: "Full Access Enabled"
            )
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                
                // Check full access status after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    checkKeyboardStatus()
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }
    
    private var textSelectionPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.cursor")
                .font(.system(size: 60))
                .foregroundColor(accentColor)
                .padding(.bottom, 20)
            
            Text("Using Text Selection")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureCard(
                        icon: "arrow.up.and.down.text.horizontal",
                        title: "Automatic Text Selection",
                        description: "Works with text up to 200 characters. Place cursor before or after the text you want to enhance."
                    )
                    .frame(maxWidth: .infinity) // Make each card fill the container width
                    
                    FeatureCard(
                        icon: "doc.on.clipboard",
                        title: "Use Copied Text",
                        description: "For longer text, copy it first, then tap \"Use Copied Text\" in the keyboard."
                    )
                    .frame(maxWidth: .infinity) // Make each card fill the container width
                }
                .frame(width: 300) // Set a fixed width for the container
            }
            .padding(.horizontal, 24)

            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }
    
    private var finishPage: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.bottom, 20)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Enjoy your new AI-powered writing experience")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Tips:")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                FeatureBullet(text: "Select text by placing cursor before/after it")
                FeatureBullet(text: "Use the clipboard for longer passages")
                FeatureBullet(text: "Try different writing styles with a single tap")
                FeatureBullet(text: "Explore all the AI tools available")
            }
            .padding()
            .background(Color.gray.opacity(0.4))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Methods
    
    private func checkKeyboardStatus() {
        
        let keyboardExtensionBundleID = "com.aryamirsepasi.writingtools.WritingToolsKeyboardExt"
        
        // Check if our keyboard extension is enabled in the app container
        let extensionEnabled = Bundle.main.appStoreReceiptURL?
            .lastPathComponent
            .contains(keyboardExtensionBundleID) ?? false
        
        // A more reliable method - check if the keyboard has previously typed anything
        let keyboardUsed = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
            .bool(forKey: "keyboard_has_been_used") ?? false
        
        isKeyboardEnabled = extensionEnabled || keyboardUsed
        
        // For full access detection - check if we can access pasteboard (only possible with full access)
        if isKeyboardEnabled {
            // This code runs when the app is active, so we can test clipboard access
            let testString = "test_full_access_\(Date().timeIntervalSince1970)"
            UIPasteboard.general.string = testString
            isFullAccessEnabled = UIPasteboard.general.string == testString
            
            // Save this status to the shared container
            UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
                .set(isFullAccessEnabled, forKey: "hasFullAccess")
        }
        
        hasCheckedSetup = true
    }
}

// MARK: - Helper Views

struct SetupStepsView: View {
    let title: String
    let steps: [String]
    @Binding var isComplete: Bool
    let completeText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                    Text(steps[index])
                }
                .padding(.leading, 4)
            }
            
            if isComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(completeText)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.4))
        .cornerRadius(16)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .padding()
        .background(Color.gray.opacity(0.4))
        .cornerRadius(16)
    }
}

struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark")
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
        }
    }
}
