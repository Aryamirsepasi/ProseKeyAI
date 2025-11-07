import UIKit
import SwiftUI
import CoreFoundation

class KeyboardViewController: UIInputViewController {
  private var keyboardViewHostingController: UIHostingController<KeyboardView>?
  private var isHostingControllerAttached = false

  private lazy var viewModel: AIToolsViewModel = {
    return AIToolsViewModel(viewController: self)
  }()

  private let appGroupID = "group.com.aryamirsepasi.writingtools"
  private let darwinName =
    "com.aryamirsepasi.writingtools.keyboardStatusChanged" as CFString

  override func viewDidLoad() {
    super.viewDidLoad()

    // Persist keyboard usage and full access status, then notify app
    updateSharedStatusAndNotify()

    AppSettings.shared.reload()
    AppState.shared.reloadProviders()
    
    // Initialize clipboard history manager
    Task { @MainActor in
      _ = ClipboardHistoryManager.shared
    }

    let settings = AppSettings.shared
    print("Current provider: \(settings.currentProvider)")
    print("Gemini API key (exists): \(!settings.geminiApiKey.isEmpty)")
    print("OpenAI API key (exists): \(!settings.openAIApiKey.isEmpty)")
    print("Mistral API key (exists): \(!settings.mistralApiKey.isEmpty)")
    print("Anthropic API key (exists): \(!settings.anthropicApiKey.isEmpty)")
    print("OpenRouter API key (exists): \(!settings.openRouterApiKey.isEmpty)")
    
    // Handle memory warnings
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryWarning),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }
  
  @objc private func handleMemoryWarning() {
    // Clean up resources when memory is low
    print("Memory warning received in keyboard extension")
    viewModel.selectedText = nil
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if keyboardViewHostingController == nil {
      let rootView = KeyboardView(viewController: self, vm: viewModel)
      let hostingController = UIHostingController(rootView: rootView)
      hostingController.view.backgroundColor = .clear
      // Set the input view's background to clear to prevent double-layering
      self.view.backgroundColor = .clear
      keyboardViewHostingController = hostingController
      attachHostingController(hostingController)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Refresh status every time we appear, then notify app
    updateSharedStatusAndNotify()
    keyboardViewHostingController?.view.isHidden = false

    Task { @MainActor in
      if !hasFullAccess {
        showFullAccessBanner()
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    keyboardViewHostingController?.view.isHidden = true
  }

  private func attachHostingController(
    _ hostingController: UIHostingController<KeyboardView>
  ) {
    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    isHostingControllerAttached = true
  }

  private func updateSharedStatusAndNotify() {
    let shared = UserDefaults(suiteName: appGroupID)
    shared?.set(true, forKey: "keyboard_has_been_used")
    shared?.set(self.hasFullAccess, forKey: "hasFullAccess")
    shared?.synchronize()

    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(darwinName),
      nil,
      nil,
      true
    )
  }

  func getSelectedText() -> String? {
    guard hasFullAccess else { return nil }

    // iOS 16+ has direct selectedText API
    if #available(iOS 16.0, *) {
      if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
        return selectedText
      }
    }

    // Fallback: Get context before and after cursor
    // Note: This is a best-effort approach and may not capture all text
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    let after = textDocumentProxy.documentContextAfterInput ?? ""
    
    // Only return combined text if it seems reasonable
    let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Limit to prevent overwhelming the UI with large documents
    if !combined.isEmpty && combined.count <= 1000 {
      return combined
    }

    return nil
  }

  private func showFullAccessBanner() {
    let bannerHeight: CGFloat = 30
    let banner = UIView(
      frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: bannerHeight)
    )
    banner.backgroundColor = .systemRed

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Please enable Full Access in Settings to use AI features."
    label.textColor = .white
    label.font = .systemFont(ofSize: 12)
    label.textAlignment = .center
    banner.addSubview(label)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: banner.topAnchor),
      label.bottomAnchor.constraint(equalTo: banner.bottomAnchor),
      label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 8),
      label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -8),
    ])

    view.addSubview(banner)

    UIView.animate(
      withDuration: 0.3,
      delay: 3.0,
      options: .curveEaseOut
    ) {
      banner.alpha = 0
    } completion: { _ in
      banner.removeFromSuperview()
    }
  }
}
