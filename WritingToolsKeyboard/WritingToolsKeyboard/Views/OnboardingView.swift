import SwiftUI
import Combine
import CoreFoundation

struct OnboardingView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage(
    "hasCompletedOnboarding",
    store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
  ) private var hasCompletedOnboarding: Bool = false
    
  @State private var currentPage: Int = 0

  // Setup status
  @State private var isKeyboardEnabled: Bool = false
  @State private var isFullAccessEnabled: Bool = false
  @State private var hasCheckedSetup: Bool = false

  // Focus and inline keyboard tester
  @FocusState private var keyboardTesterFocused: Bool
  @State private var keyboardTesterText: String = ""
  @State private var pollingCancellable: AnyCancellable?

  // Darwin observer to react instantly when keyboard posts its status
  @State private var darwinObserver: OnboardingDarwinObserver?

  private let totalPages = 6

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
          
          pastePermissionPage
            .tag(3)

          featuresPage
            .tag(4)

          finishPage
            .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)

        // Navigation buttons
        HStack(spacing: 20) {
          if currentPage > 0 {
            Button(action: {
              withAnimation { currentPage -= 1 }
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
      // Initial status read
      checkKeyboardStatus()
      // Start listening to Darwin notifications from the keyboard extension
      darwinObserver = OnboardingDarwinObserver {
        checkKeyboardStatus()
      }
    }
    .onDisappear {
      pollingCancellable?.cancel()
      pollingCancellable = nil
      darwinObserver = nil
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIApplication.didBecomeActiveNotification
      )
    ) { _ in
      // Re-check when returning from Settings
      checkKeyboardStatus()
      // Also poll for a short while in case the user immediately switches to the keyboard
      startShortPolling()
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

      Text("Transform your writing with AI-powered tools")
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

      Text(
        "Let's set up your AI writing keyboard to start enhancing your text"
      )
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
          "Select ProseKey AI Keyboard",
        ],
        isComplete: $isKeyboardEnabled,
        completeText: "Keyboard Enabled"
      )

      Button(action: {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        // When the user returns, we'll poll; also bring up our inline text field
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          keyboardTesterFocused = true
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

      // Inline keyboard tester to force the extension to run once the user switches to it.
      VStack(alignment: .leading, spacing: 8) {
        Text(
          "Tip: Tap below to show the keyboard, then switch to “ProseKey AI” using the globe key. We’ll update your status automatically."
        )
        .font(.footnote)
        .foregroundColor(.secondary)

        TextField("Tap here to show the keyboard…", text: $keyboardTesterText)
          .textFieldStyle(.roundedBorder)
          .focused($keyboardTesterFocused)
          .onAppear {
            // Try to focus automatically to bring up keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              keyboardTesterFocused = true
            }
          }
      }
      .padding(.horizontal, 24)

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

      Text(
        "Full access is required for the keyboard to access AI tools and use copy/paste features"
      )
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
          "Confirm when prompted",
        ],
        isComplete: $isFullAccessEnabled,
        completeText: "Full Access Enabled"
      )

      Button(action: {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          keyboardTesterFocused = true
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

      VStack(alignment: .leading, spacing: 8) {
        Text(
          "Tip: Tap below to show the keyboard, then switch to “ProseKey AI” using the globe key. We’ll detect Full Access automatically."
        )
        .font(.footnote)
        .foregroundColor(.secondary)

        TextField("Tap here to show the keyboard…", text: $keyboardTesterText)
          .textFieldStyle(.roundedBorder)
          .focused($keyboardTesterFocused)
      }
      .padding(.horizontal, 24)

      Spacer()
    }
    .padding(.top, 40)
    .padding(.horizontal, 24)
  }

  private var pastePermissionPage: some View {
    ScrollView {
      VStack(spacing: 20) {
        Image(systemName: "doc.on.clipboard.fill")
          .font(.system(size: 60))
          .foregroundColor(.orange)
          .padding(.bottom, 10)

        Text("Allow Paste Permission")
          .font(.title)
          .bold()
          .multilineTextAlignment(.center)

        Text(
          "ProseKey AI needs paste permission to access copied text for use in writing features."
        )
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal, 32)

        // Important notice about paste notifications
        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
              .font(.title2)
              .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
              Text("Important")
                .font(.headline)
              
              Text("The first time you use paste features, iOS will ask permission. Tap \"Allow Paste\" or \"Paste from [app]\" to enable the feature.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          
          Divider()
            .padding(.vertical, 4)
          
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
              .font(.title2)
              .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
              Text("Stop Repeated Notifications")
                .font(.headline)
              
              Text("Choose \"Allow Paste\" instead of \"Paste\" to avoid seeing this notification every time you use paste features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
        .padding(.horizontal, 24)

        // What paste permission enables
        VStack(alignment: .leading, spacing: 12) {
          Text("What This Enables:")
            .font(.headline)
            .padding(.bottom, 4)

          FeatureBullet(text: "Quick access to copied text")
          FeatureBullet(text: "\"Use Copied Text\" button")
          FeatureBullet(text: "Seamless text operations")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
        .padding(.horizontal, 24)

        Spacer(minLength: 20)
      }
      .padding(.top, 30)
      .padding(.bottom, 20)
    }
  }
  
  private var featuresPage: some View {
    ScrollView {
      VStack(spacing: 20) {
        Image(systemName: "sparkles")
          .font(.system(size: 60))
          .foregroundColor(accentColor)
          .padding(.bottom, 10)

        Text("Powerful Features")
          .font(.title)
          .bold()
          .multilineTextAlignment(.center)

        Text("Discover what makes ProseKey AI special")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 32)

        VStack(spacing: 16) {
          FeatureCard(
            icon: "wand.and.stars",
            title: "AI Writing Tools",
            description: "Transform your text with one tap: proofread, rewrite, summarize, translate, and more powered by your choice of AI provider."
          )
          
          FeatureCard(
            icon: "text.cursor",
            title: "Smart Text Selection",
            description: "Select text automatically (up to 200 characters) or use the \"Use Copied Text\" button for longer passages."
          )
          
          FeatureCard(
            icon: "magnifyingglass",
            title: "Custom Prompts",
            description: "Create your own AI instructions for specialized writing tasks tailored to your needs."
          )
        }
        .padding(.horizontal, 24)

        Spacer(minLength: 20)
      }
      .padding(.top, 30)
      .padding(.bottom, 20)
    }
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
        FeatureCard(
          icon: "arrow.up.and.down.text.horizontal",
          title: "Automatic Text Selection",
          description:
            "Works with text up to 200 characters. Place cursor before or after the text you want to enhance."
        )
        FeatureCard(
          icon: "doc.on.clipboard",
          title: "Use Copied Text",
          description:
            "For longer text, copy it first, then tap \"Use Copied Text\" in the keyboard."
        )
      }
      .padding(.horizontal, 24)

      Spacer()
    }
    .padding(.top, 40)
    .padding(.horizontal, 24)
  }

  private var finishPage: some View {
    ScrollView {
      VStack(spacing: 20) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 80))
          .foregroundColor(.green)
          .padding(.bottom, 10)

        Text("You're All Set!")
          .font(.largeTitle)
          .bold()
          .multilineTextAlignment(.center)

        Text("Start transforming your writing with AI")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 32)

        VStack(alignment: .leading, spacing: 14) {
          Text("Quick Tips:")
            .font(.headline)
            .padding(.bottom, 4)

          FeatureBullet(text: "Use \"Allow Paste\" to avoid repeated notifications")
          FeatureBullet(text: "Select text or tap \"Use Copied Text\"")
          FeatureBullet(text: "Explore AI writing tools and custom prompts")
          FeatureBullet(text: "Configure your AI provider in Settings")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
        .padding(.horizontal, 24)
        
        // Privacy notice
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: "lock.shield.fill")
              .foregroundColor(.blue)
            Text("Your Privacy Matters")
              .font(.headline)
          }
          
          Text("We never send your copied content to our servers.")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 24)

        Spacer(minLength: 20)
      }
      .padding(.top, 40)
      .padding(.bottom, 20)
    }
  }

  // MARK: - Helper Methods

  private func checkKeyboardStatus() {
    // Read status written by the keyboard extension
    let groupDefaults = UserDefaults(
      suiteName: "group.com.aryamirsepasi.writingtools"
    )
    let keyboardUsed = groupDefaults?.bool(forKey: "keyboard_has_been_used") ?? false
    let fullAccess = groupDefaults?.bool(forKey: "hasFullAccess") ?? false

    isKeyboardEnabled = keyboardUsed
    isFullAccessEnabled = keyboardUsed ? fullAccess : false
    hasCheckedSetup = true
  }

  private func startShortPolling() {
    // Poll for up to ~10 seconds after returning from Settings to catch immediate changes
    pollingCancellable?.cancel()
    let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var ticks = 0
    pollingCancellable = ticker.sink { _ in
      ticks += 1
      checkKeyboardStatus()
      if self.isKeyboardEnabled && self.isFullAccessEnabled {
        self.pollingCancellable?.cancel()
        self.pollingCancellable = nil
      } else if ticks >= 20 {
        self.pollingCancellable?.cancel()
        self.pollingCancellable = nil
      }
    }
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
    .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
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

// MARK: - Darwin Notification Observer (Onboarding)

final class OnboardingDarwinObserver {
  private let name = "com.aryamirsepasi.writingtools.keyboardStatusChanged" as CFString

  init(callback: @escaping () -> Void) {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    CFNotificationCenterAddObserver(
      center,
      observer,
      { _, observer, _, _, _ in
        guard let observer = observer else { return }
        let instance = Unmanaged<OnboardingDarwinObserver>
          .fromOpaque(observer)
          .takeUnretainedValue()
        instance._callback()
      },
      name,
      nil,
      .deliverImmediately
    )
    self._callback = {
      DispatchQueue.main.async { callback() }
    }
  }

  deinit {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    CFNotificationCenterRemoveObserver(
      center,
      observer,
      CFNotificationName(name),
      nil
    )
  }

  private var _callback: () -> Void = {}
}

// MARK: - Previews

#Preview("Onboarding Flow") {
  OnboardingView()
}

#Preview("Welcome Page") {
  OnboardingView()
    .onAppear {
      // Preview shows first page by default
    }
}

#Preview("Feature Cards") {
  VStack(spacing: 16) {
    FeatureCard(
      icon: "wand.and.stars",
      title: "AI Writing Tools",
      description: "Transform your text with one tap: proofread, rewrite, summarize, translate, and more powered by your choice of AI provider."
    )
    
    FeatureCard(
      icon: "text.cursor",
      title: "Smart Text Selection",
      description: "Select text automatically (up to 200 characters) or use the \"Use Copied Text\" button for longer passages."
    )
    
    FeatureCard(
      icon: "magnifyingglass",
      title: "Custom Prompts",
      description: "Create your own AI instructions for specialized writing tasks tailored to your needs."
    )
  }
  .padding()
  .background(Color.gray.opacity(0.1))
}
