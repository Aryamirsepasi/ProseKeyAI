import SwiftUI
import Combine
import CoreFoundation

// MARK: - Color Extension for Hex Support
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

struct SettingsView: View {
  @ObservedObject var appState = AppState.shared
  @ObservedObject var settings = AppSettings.shared

  @AppStorage(
    "keyboard_has_been_used",
    store: UserDefaults(
      suiteName: "group.com.aryamirsepasi.writingtools"
    )
  )
  private var keyboardHasBeenUsed: Bool = false

  @AppStorage(
    "hasFullAccess",
    store: UserDefaults(
      suiteName: "group.com.aryamirsepasi.writingtools"
    )
  )
  private var hasFullAccessEnabled: Bool = false

  @AppStorage(
    "enable_haptics",
    store: UserDefaults(
      suiteName: "group.com.aryamirsepasi.writingtools"
    )
  )
  private var enableHaptics = true

  @AppStorage(
    "has_completed_onboarding",
    store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
  ) private var hasCompletedOnboarding: Bool = false
    
  @State private var showOnboarding: Bool = false

  // Darwin observer + optional polling after returning from Settings
  @State private var darwinObserver: SettingsDarwinObserver?
  @State private var pollingCancellable: AnyCancellable?

  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
              .font(.title2)
              .foregroundStyle(.blue)
              .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
              Text("ProseKey AI")
                .font(.headline)
              Text("Enhance your writing with AI")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }

          HStack(spacing: 12) {
            Label(
              keyboardHasBeenUsed ? "Keyboard enabled" : "Keyboard not enabled",
              systemImage: keyboardHasBeenUsed ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(keyboardHasBeenUsed ? .green : .secondary)

            Label(
              hasFullAccessEnabled ? "Full Access on" : "Full Access off",
              systemImage: hasFullAccessEnabled ? "lock.open.fill" : "lock.fill"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(hasFullAccessEnabled ? .green : .secondary)
          }
        }
        .padding(.vertical, 4)
      }

      Section("Keyboard Setup") {
        KeyboardStatusCard(
          isEnabled: keyboardHasBeenUsed,
          onEnablePressed: openKeyboardSettings
        )
        .listRowInsets(EdgeInsets())
      }

      Section {
        NavigationLink {
          ProviderSelectionView(appState: appState)
        } label: {
          providerSummaryRow
        }
        .onChangeCompat(of: settings.currentProvider) { newProvider in
          guard newProvider != appState.currentProvider else { return }
          appState.setCurrentProvider(newProvider)
        }
      } header: {
        Text("AI Provider")
      } footer: {
        Text(providerDescriptionText(for: settings.currentProvider))
          .font(.footnote)
      }

      Section("Preferences") {
        Toggle("Enable Haptic Feedback", isOn: $enableHaptics)

        Button {
          showOnboarding = true
        } label: {
          Label("Restart Onboarding", systemImage: "arrow.counterclockwise")
        }
      }

      Section("About") {
        AboutLinkRow(
          iconName: "globe.badge.chevron.backward",
          iconColor: .blue,
          title: "View on GitHub",
          subtitle: "Open source repository",
          url: URL(
            string: "https://github.com/Aryamirsepasi/WritingToolsKeyboard"
          )!
        )

        AboutLinkRow(
          iconName: "person.fill",
          iconColor: .blue,
          title: "App Website",
          subtitle: "Arya Mirsepasi",
          url: URL(string: "https://aryamirsepasi.com/prosekey")!
        )

        AboutLinkRow(
          iconName: "questionmark.circle.fill",
          iconColor: .blue,
          title: "Having Issues?",
          subtitle: "Submit a new issue on the support page!",
          url: URL(string: "https://aryamirsepasi.com/support")!
        )

        AboutLinkRow(
          iconName: "lock.shield.fill",
          iconColor: .blue,
          title: "Privacy Policy",
          subtitle: "How your data is handled",
          url: URL(string: "https://aryamirsepasi.com/prosekey/privacy")!
        )
      }
    }
    .navigationTitle("ProseKey AI")
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      checkKeyboardStatus()

      if !hasCompletedOnboarding {
        showOnboarding = true
      }
      // Sync AppState's current provider with AppSettings on appear
      appState.setCurrentProvider(settings.currentProvider)

      // Start Darwin observer
      darwinObserver = SettingsDarwinObserver {
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
      checkKeyboardStatus()
      startShortPolling()
    }
    .fullScreenCover(isPresented: $showOnboarding) {
      OnboardingView()
    }
  }

  private func checkKeyboardStatus() {
    let keyboardUsed = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
      .bool(forKey: "keyboard_has_been_used") ?? false
    let fullAccess = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
      .bool(forKey: "hasFullAccess") ?? false

    keyboardHasBeenUsed = keyboardUsed
    hasFullAccessEnabled = keyboardUsed ? fullAccess : false
  }

  private func openKeyboardSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }

  private func startShortPolling() {
    pollingCancellable?.cancel()
    let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var ticks = 0
    pollingCancellable = ticker.sink { _ in
      ticks += 1
      checkKeyboardStatus()
      if self.keyboardHasBeenUsed || ticks >= 20 {
        self.pollingCancellable?.cancel()
        self.pollingCancellable = nil
      }
    }
  }

  private var providerSummaryRow: some View {
    let info = ProviderCatalog.info(for: settings.currentProvider)
    let status = providerStatusText(for: settings.currentProvider)
    return HStack(spacing: 12) {
      Text("Provider")
      Spacer(minLength: 12)
      HStack(spacing: 8) {
        ProviderIconView(info: info, size: 28)
        VStack(alignment: .trailing, spacing: 2) {
          Text(info.name)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
          Text(status)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .multilineTextAlignment(.trailing)
    }
  }

  private func providerStatusText(for provider: String) -> String {
    switch provider {
    case "gemini":
      return settings.geminiApiKey.isEmpty ? "Needs API key" : "API key added"
    case "openai":
      return settings.openAIApiKey.isEmpty ? "Needs API key" : "API key added"
    case "mistral":
      return settings.mistralApiKey.isEmpty ? "Needs API key" : "API key added"
    case "anthropic":
      return settings.anthropicApiKey.isEmpty ? "Needs API key" : "API key added"
    case "openrouter":
      return settings.openRouterApiKey.isEmpty ? "Needs API key" : "API key added"
    case "perplexity":
      return settings.perplexityApiKey.isEmpty ? "Needs API key" : "API key added"
    case "foundationmodels":
      if #available(iOS 26.0, *) {
        return FoundationModelsProvider().isAvailable ? "Available" : "Unavailable"
      }
      return "Requires iOS 26"
    default:
      return ""
    }
  }
}

// MARK: - Supporting Components

private func providerDescriptionText(for provider: String) -> String {
  switch provider {
  case "gemini":
    return
      "Google Gemini is a versatile AI model optimized for creative writing and text processing tasks. It provides high-quality completions and reformulations."
  case "openai":
    return
      "OpenAI offers powerful language models like GPT-4 that excel at understanding context and generating human-like text for various writing tasks."
  case "mistral":
    return
      "Mistral AI delivers efficient language models that balance performance and speed, great for text transformations and creative writing assistance."
  case "anthropic":
    return
      "Anthropic's Claude models are known for their safety and helpfulness, offering advanced language capabilities for writing and productivity."
  case "openrouter":
    return
      "OpenRouter is a gateway to many top AI models, letting you choose from a variety of providers with a single API key."
  case "perplexity":
    return "Perplexity provides fast, high-quality models like Sonar for search-augmented writing assistance."
  case "foundationmodels":
    return "Apple's on-device Foundation Models powered by Apple Intelligence. No API key required, works offline, and processes everything privately on your device."
  default:
    return ""
  }
}

struct KeyboardStatusCard: View {
  let isEnabled: Bool
  let onEnablePressed: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: isEnabled ? "keyboard.badge.ellipsis" : "keyboard")
          .font(.title3)
          .foregroundStyle(isEnabled ? .green : .orange)

        VStack(alignment: .leading, spacing: 4) {
          Text("Keyboard Status")
            .font(.headline)
          Text(isEnabled ? "Ready to use" : "Setup required")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if isEnabled {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.title3)
        } else {
          Button(action: onEnablePressed) {
            Text("Enable")
              .font(.body.weight(.semibold))
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(Color.blue, in: .rect(cornerRadius: 8))
              .foregroundStyle(.white)
          }
          .buttonStyle(.plain)
        }
      }

      if !isEnabled {
        VStack(alignment: .leading, spacing: 8) {
          SetupStepView(
            number: 1,
            text: "Open Settings",
            isCompleted: false
          )
          SetupStepView(
            number: 2,
            text: "Go to General → Keyboard → Keyboards",
            isCompleted: false
          )
          SetupStepView(
            number: 3,
            text: "Tap Add New Keyboard → Select ProseKey AI",
            isCompleted: false
          )
          SetupStepView(
            number: 4,
            text: "Enable Full Access for AI features",
            isCompleted: false
          )

          Label {
            Text("If you just enabled Full Access, please close and reopen the keyboard, and restart the app, for the change to take effect.")
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
          }
          .font(.footnote)
          .foregroundStyle(.orange)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 12)
        }
        .padding(.top, 8)
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .clipShape(.rect(cornerRadius: 16))
  }
}

struct SetupStepView: View {
  let number: Int
  let text: String
  let isCompleted: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ZStack {
        Circle()
          .fill(isCompleted ? Color.green : Color.blue.opacity(0.2))
          .frame(width: 24, height: 24)

        if isCompleted {
          Image(systemName: "checkmark")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
        } else {
          Text("\(number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.blue)
        }
      }

      Text(text)
        .font(.subheadline)
        .foregroundStyle(isCompleted ? .secondary : .primary)
        .strikethrough(isCompleted)
    }
  }
}

struct AboutLinkRow: View {
  let iconName: String
  let iconColor: Color
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey
  let url: URL

  var body: some View {
    Link(destination: url) {
      HStack(spacing: 10) {
        ZStack {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(iconColor.opacity(0.12))
            .frame(width: 36, height: 36)
          Image(systemName: iconName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(iconColor)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.accentColor)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "arrow.up.right.square")
          .foregroundStyle(.gray)
      }
      .padding(.vertical, 12)
    }
  }
}

// MARK: - Darwin Notification Observer (Settings)

final class SettingsDarwinObserver {
  private let name = "com.aryamirsepasi.writingtools.keyboardStatusChanged" as CFString

  init(callback: @escaping () -> Void) {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    CFNotificationCenterAddObserver(
      center,
      observer,
      { _, observer, _, _, _ in
        guard let observer = observer else { return }
        let instance = Unmanaged<SettingsDarwinObserver>
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
    CFNotificationCenterRemoveObserver(center, observer, CFNotificationName(name), nil)
  }

  private var _callback: () -> Void = {}
}

