import SwiftUI
import Combine
import CoreFoundation

struct OnboardingView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage(
    "has_completed_onboarding",
    store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
  ) private var hasCompletedOnboarding: Bool = false
  @State private var currentPage: Int = 0

  // Setup status
  @State private var isKeyboardEnabled: Bool = false
  @State private var isFullAccessEnabled: Bool = false

  // Focus and inline keyboard tester
  @FocusState private var keyboardTesterFocused: Bool
  @State private var keyboardTesterText: String = ""
  @State private var pollingCancellable: AnyCancellable?

  // Darwin observer to react instantly when keyboard posts its status
  @State private var darwinObserver: OnboardingDarwinObserver?

  private let totalPages = 7

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

      VStack(spacing: 0) {
        // Skip button (except on last page)
        if currentPage < totalPages - 1 {
          HStack {
            Spacer()
            Button("Skip") {
              dismissKeyboard()
              hasCompletedOnboarding = true
              dismiss()
            }
            .font(.body)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Skip onboarding")
            .accessibilityHint("Completes setup and closes onboarding")
          }
          .padding(.horizontal, 20)
          .padding(.top, 12)
        } else {
          Spacer().frame(height: 44)
        }

        // Page content - using TabView for smooth swiping
        TabView(selection: $currentPage) {
          welcomePage
            .tag(0)

          keyboardSetupPage
            .tag(1)

          fullAccessPage
            .tag(2)

          testKeyboardPage
            .tag(3)

          pastePermissionPage
            .tag(4)

          featuresPage
            .tag(5)

          finishPage
            .tag(6)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))

        // Navigation buttons
        HStack {
          if currentPage > 0 {
            Button("Back") {
              dismissKeyboard()
              withAnimation { currentPage -= 1 }
            }
            .font(.body)
            .foregroundStyle(.primary)
            .accessibilityLabel("Go back")
            .accessibilityHint("Returns to the previous onboarding step")
          }

          Spacer()

          Button(action: {
            dismissKeyboard()
            withAnimation {
              if currentPage == totalPages - 1 {
                hasCompletedOnboarding = true
                dismiss()
              } else {
                currentPage += 1
              }
            }
          }) {
            Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
              .fontWeight(.semibold)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
          .controlSize(.large)
          .accessibilityLabel(currentPage == totalPages - 1 ? "Get started" : "Continue")
          .accessibilityHint(currentPage == totalPages - 1 ? "Completes onboarding and opens the app" : "Continues to the next onboarding step")
        }
        .padding(.top, 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)

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
        Spacer()
        
      Image(systemName: "keyboard")
        .font(.largeTitle)
        .foregroundStyle(accentColor)
        .padding(.bottom, 10)

      Text("Welcome to ProseKey AI")
        .font(.largeTitle)
        .bold()
        .multilineTextAlignment(.center)

      Text("Transform your writing with AI-powered tools")
        .font(.title3)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 32)

      Spacer()
    }
    .padding(.horizontal, 24)
  }

  private var keyboardSetupPage: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "keyboard.fill")
        .font(.largeTitle)
        .foregroundStyle(accentColor)
        .padding(.bottom, 10)

      Text("Enable the Keyboard")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text(
        "Let's set up your AI writing keyboard to start enhancing your text"
      )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(.secondary)
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
      }) {
        HStack {
          Image(systemName: "gear")
          Text("Open Settings")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .clipShape(.rect(cornerRadius: 12))
      }

      Spacer()
    }
    .padding(.horizontal, 24)
  }

  private var fullAccessPage: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "lock.open.fill")
        .font(.largeTitle)
        .foregroundStyle(accentColor)
        .padding(.bottom, 10)

      Text("Enable Full Access")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text(
        "Full access is required for the keyboard to access AI tools and use copy/paste features"
      )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(.secondary)
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
      }) {
        HStack {
          Image(systemName: "gear")
          Text("Open Settings")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .clipShape(.rect(cornerRadius: 12))
      }

      Spacer()
    }
    .padding(.horizontal, 24)
  }

  private var testKeyboardPage: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.keyboard")
        .font(.largeTitle)
        .foregroundStyle(accentColor)
        .padding(.bottom, 10)

      Text("Test Your Keyboard")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text(
        "Tap the text field below and switch to ProseKey AI using the globe key"
      )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 32)

      VStack(alignment: .leading, spacing: 12) {
        TextField("Type something here…", text: $keyboardTesterText)
          .textFieldStyle(.roundedBorder)
          .focused($keyboardTesterFocused)
          .padding(.horizontal)

        if isKeyboardEnabled && isFullAccessEnabled {
          HStack {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
            Text("Keyboard is ready to use!")
              .foregroundStyle(.green)
              .font(.subheadline)
          }
          .padding(.horizontal)
        } else {
          HStack {
            Image(systemName: "info.circle.fill")
              .foregroundStyle(.orange)
            Text("Switch to ProseKey AI to verify setup")
              .foregroundStyle(.secondary)
              .font(.subheadline)
          }
          .padding(.horizontal)
        }
      }
      .padding()
      .background(Color.gray.opacity(0.15))
      .clipShape(.rect(cornerRadius: 16))

      Spacer()
    }
    .padding(.horizontal, 24)
  }

  private var pastePermissionPage: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "doc.on.clipboard.fill")
        .font(.largeTitle)
        .foregroundStyle(.orange)
        .padding(.bottom, 10)

      Text("Allow Paste Permission")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)

      Text("iOS will ask for permission when you first use clipboard features")
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 32)

      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "hand.tap.fill")
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("Tap \"Allow Paste\"")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("When the iOS permission dialog appears")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "bell.slash.fill")
            .font(.title2)
            .foregroundStyle(.green)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("Avoid Repeated Prompts")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("Choosing \"Allow Paste\" grants permanent access")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "doc.on.doc.fill")
            .font(.title2)
            .foregroundStyle(.purple)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("Use Copied Text")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("Process longer text by copying it first")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color.gray.opacity(0.15))
      .clipShape(.rect(cornerRadius: 16))

      Spacer()
    }
    .padding(.horizontal, 24)
  }
  
  private var featuresPage: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "sparkles")
        .font(.largeTitle)
        .foregroundStyle(accentColor)
        .padding(.bottom, 10)

      Text("Powerful Features")
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)
        

      Text("Everything you need to enhance your writing")
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 32)
        

      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "wand.and.stars")
            .font(.title2)
            .foregroundStyle(.blue)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("AI Writing Tools")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("Proofread, rewrite, summarize, and translate your text")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "text.cursor")
            .font(.title2)
            .foregroundStyle(.green)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("Smart Text Selection")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("Automatically detect text or use copied content")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "square.and.pencil")
            .font(.title2)
            .foregroundStyle(.purple)
            .frame(width: 28)
          VStack(alignment: .leading, spacing: 4) {
            Text("Custom Prompts")
              .font(.subheadline)
              .fontWeight(.medium)
            Text("Create personalized AI instructions for any task")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color.gray.opacity(0.15))
      .clipShape(.rect(cornerRadius: 16))

      Spacer()
    }
    .padding(.horizontal, 24)
  }

  private var finishPage: some View {
    ScrollView {
      VStack(spacing: 20) {
        Image(systemName: "checkmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.green)
          .padding(.bottom, 10)

        Text("You're All Set!")
          .font(.largeTitle)
          .bold()
          .multilineTextAlignment(.center)

        Text("Start transforming your writing with AI")
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
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
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 24)
        
        // Privacy notice
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: "lock.shield.fill")
              .foregroundStyle(.blue)
            Text("Your Privacy Matters")
              .font(.headline)
          }
          
          Text("We never send your copied content to our servers.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 24)

        Spacer(minLength: 20)
      }
      .padding(.top, 40)
      .padding(.bottom, 20)
    }
  }

  // MARK: - Helper Methods

  private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }

  private func checkKeyboardStatus() {
    // Read status written by the keyboard extension
    let groupDefaults = UserDefaults(
      suiteName: "group.com.aryamirsepasi.writingtools"
    )
    let keyboardUsed = groupDefaults?.bool(forKey: "keyboard_has_been_used") ?? false
    let fullAccess = groupDefaults?.bool(forKey: "hasFullAccess") ?? false

    isKeyboardEnabled = keyboardUsed
    isFullAccessEnabled = keyboardUsed ? fullAccess : false
  }

  private func startShortPolling() {
    // Poll for up to ~10 seconds after returning from Settings to catch immediate changes
    pollingCancellable?.cancel()
    let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var ticks = 0
    pollingCancellable = ticker.sink { _ in
      ticks += 1
      self.checkKeyboardStatus()
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
            .foregroundStyle(.secondary)
          Text(steps[index])
        }
        .padding(.leading, 4)
      }

      if isComplete {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
          Text(completeText)
            .foregroundStyle(.green)
        }
        .padding(.top, 8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color.gray.opacity(0.15))
    .clipShape(.rect(cornerRadius: 16))
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
          .font(.title2)
          .foregroundStyle(.blue)
          .frame(width: 36, height: 36)

        Text(title)
          .font(.headline)
      }

      Text(description)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .lineLimit(nil)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding()
    .background(Color.gray.opacity(0.15))
    .clipShape(.rect(cornerRadius: 16))
  }
}

struct FeatureBullet: View {
  let text: String

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: "checkmark")
        .foregroundStyle(.green)
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
