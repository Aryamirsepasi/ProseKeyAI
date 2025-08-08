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

    let settings = AppSettings.shared
    print("Current provider: \(settings.currentProvider)")
    print("Gemini API key (exists): \(!settings.geminiApiKey.isEmpty)")
    print("OpenAI API key (exists): \(!settings.openAIApiKey.isEmpty)")
    print("Mistral API key (exists): \(!settings.mistralApiKey.isEmpty)")
    print("Anthropic API key (exists): \(!settings.anthropicApiKey.isEmpty)")
    print("OpenRouter API key (exists): \(!settings.openRouterApiKey.isEmpty)")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if keyboardViewHostingController == nil {
      let rootView = KeyboardView(viewController: self, vm: viewModel)
      let hostingController = UIHostingController(rootView: rootView)
      hostingController.view.backgroundColor = .clear
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

    if #available(iOS 16.0, *) {
      if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
        return selectedText
      }
    }

    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    let after = textDocumentProxy.documentContextAfterInput ?? ""
    let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)

    if !combined.isEmpty && combined.count <= 200 {
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
