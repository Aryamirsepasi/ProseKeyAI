import UIKit
import SwiftUI
import CoreFoundation

class KeyboardViewController: UIInputViewController {
  private var keyboardViewHostingController: UIHostingController<KeyboardView>?
  private var heightConstraint: NSLayoutConstraint?

  private lazy var viewModel: AIToolsViewModel = {
    return AIToolsViewModel(viewController: self)
  }()

  private let appGroupID = "group.com.aryamirsepasi.writingtools"
  private let darwinName =
    "com.aryamirsepasi.writingtools.keyboardStatusChanged" as CFString
  
  // Fixed keyboard height — now sized for exactly 2 command rows
  private let keyboardHeight: CGFloat = KeyboardConstants.keyboardHeight

  override func viewDidLoad() {
    super.viewDidLoad()

    // Persist keyboard usage and full access status, then notify app
    updateSharedStatusAndNotify()

    // Only reload settings and providers if settings have changed
    if AppSettings.shared.reloadIfNeeded() {
      AppState.shared.reloadProviders()
    }

    // Initialize clipboard history manager lazily
    Task { @MainActor in
      _ = ClipboardHistoryManager.shared
    }

    // Handle memory warnings
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryWarning),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Setup keyboard view on first appearance only
    if keyboardViewHostingController == nil {
      setupKeyboardView()
    }
    
    // Refresh status every time we appear, then notify app
    updateSharedStatusAndNotify()

    Task { @MainActor in
      if !hasFullAccess {
        showFullAccessBanner()
      }
    }
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    // Set height constraint before layout (Apple recommends controlling height via constraint).
    if heightConstraint == nil {
      let constraint = NSLayoutConstraint(
        item: view!,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1.0,
        constant: keyboardHeight
      )
      constraint.priority = .required
      view.addConstraint(constraint)
      heightConstraint = constraint
    }
  }
  
  private func setupKeyboardView() {
    // Create SwiftUI hosting controller
    let rootView = KeyboardView(viewController: self, vm: viewModel)
    let hostingController = UIHostingController(rootView: rootView)
    
    // Prevent SwiftUI from sizing outside our fixed height
    hostingController.sizingOptions = []
    
    // Clear backgrounds
    hostingController.view.backgroundColor = .clear
    self.view.backgroundColor = .clear
    
    keyboardViewHostingController = hostingController
    
    // Add to view hierarchy
    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)
    
    // Pin to edges
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }
  
  @objc private func handleMemoryWarning() {
    print("Memory warning received in keyboard extension")

    // 1. ViewModel cleanup
    viewModel.handleMemoryWarning()

    // 2. Provider cleanup
    AppState.shared.handleMemoryWarning()

    // 3. Clipboard history cleanup
    Task { @MainActor in
      ClipboardHistoryManager.shared.handleMemoryWarning()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func updateSharedStatusAndNotify() {
    let shared = UserDefaults(suiteName: appGroupID)
    shared?.set(true, forKey: "keyboard_has_been_used")
    shared?.set(self.hasFullAccess, forKey: "hasFullAccess")

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
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    let after = textDocumentProxy.documentContextAfterInput ?? ""
    
    let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
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
