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
  
  // Default keyboard height — sized for 2 command rows
  private var currentKeyboardHeight: CGFloat = KeyboardConstants.keyboardHeight

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
    // Use .defaultHigh priority to avoid Auto Layout conflicts with system constraints.
    if heightConstraint == nil {
      let constraint = NSLayoutConstraint(
        item: view!,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1.0,
        constant: currentKeyboardHeight
      )
      constraint.priority = .defaultHigh
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
    #if DEBUG
    print("Memory warning received in keyboard extension")
    #endif

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
    if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
      return selectedText
    }

    // Fallback: Get context before and after cursor
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    let after = textDocumentProxy.documentContextAfterInput ?? ""
    
    let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
    if !combined.isEmpty && combined.count <= 200 {
      return combined
    }

    return nil
  }
  
  /// Replaces a specific substring in the text field with new text.
  /// Finds the original text in the document, deletes it, and inserts the replacement.
  /// Returns true if the text was found and replaced, false otherwise.
  @discardableResult
  func replaceText(_ originalText: String, with newText: String) -> Bool {
      let proxy = textDocumentProxy

      // Move cursor to end of document so documentContextBeforeInput contains everything
      // adjustTextPosition uses character (grapheme cluster) offsets
      if let after = proxy.documentContextAfterInput, !after.isEmpty {
          proxy.adjustTextPosition(byCharacterOffset: after.count)
      }

      // Read the full document text (now all before cursor)
      guard let fullText = proxy.documentContextBeforeInput, !fullText.isEmpty else {
          return false
      }

      // Find the range of the original text in the document
      guard let range = fullText.range(of: originalText, options: .backwards) else {
          return false
      }

      // Calculate character (grapheme cluster) distances for cursor movement and deletion
      let charsAfterMatch = fullText[range.upperBound...].count
      let matchCharCount = fullText[range].count

      // Move cursor back to right after the matched text
      if charsAfterMatch > 0 {
          proxy.adjustTextPosition(byCharacterOffset: -charsAfterMatch)
      }

      // Delete the matched text — deleteBackward() removes one grapheme cluster per call
      for _ in 0..<matchCharCount {
          proxy.deleteBackward()
      }

      // Insert the replacement
      proxy.insertText(newText)
      return true
  }

  /// Whether the keyboard switcher (globe) button should be displayed
  var showsKeyboardSwitcher: Bool {
    needsInputModeSwitchKey
  }
  
  /// Switches to the next keyboard in the user's enabled keyboards list
  func switchToNextKeyboard() {
    advanceToNextInputMode()
  }
  
  /// Updates the keyboard height with optional animation
  func updateKeyboardHeight(_ height: CGFloat, animated: Bool = true) {
    guard currentKeyboardHeight != height else { return }
    currentKeyboardHeight = height
    
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
        self.heightConstraint?.constant = height
        self.view.layoutIfNeeded()
      }
    } else {
      heightConstraint?.constant = height
    }
  }

  private func showFullAccessBanner() {
    let bannerHeight: CGFloat = 30
    let banner = UIView(
      frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: bannerHeight)
    )
    banner.backgroundColor = .systemRed

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = String(localized: "Please enable Full Access in Settings to use AI features.")
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
