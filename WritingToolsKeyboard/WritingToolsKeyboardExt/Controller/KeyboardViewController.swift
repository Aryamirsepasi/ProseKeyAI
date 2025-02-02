import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var keyboardViewHostingController: UIHostingController<KeyboardView>?
    private var blurEffectView: UIVisualEffectView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the blur effect immediately (this is lightweight)
        setupBlurEffect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Defer creation of the SwiftUI hosting controller until the view appears
        if keyboardViewHostingController == nil {
            // Dispatch asynchronously so that the keyboard UI appears quickly
            DispatchQueue.main.async { [weak self] in
                self?.setupHostingController()
            }
        }
        
        // Show the full-access banner if needed (this check can be done later)
        if !hasFullAccess {
            showFullAccessBanner()
        }
    }
    
    /// Sets up the blur background.
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        view.insertSubview(blurView, at: 0)
        self.blurEffectView = blurView
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    /// Sets up and embeds the SwiftUI hosting controller.
    private func setupHostingController() {
        // Create the SwiftUI keyboard view
        let rootView = KeyboardView(viewController: self)
        let hostingController = UIHostingController(rootView: rootView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Cache the hosting controller so it isn’t recreated unnecessarily.
        self.keyboardViewHostingController = hostingController
        hostingController.view.backgroundColor = .clear
    }
    
    // MARK: - Keyboard Text Methods

    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
    
    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }
    
    func handleReturn() {
        textDocumentProxy.insertText("\n")
    }
    
    func handleSpace() {
        textDocumentProxy.insertText(" ")
    }
    
    func getSelectedText() -> String? {
        guard hasFullAccess else { return nil }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? nil : combined
    }
    
    private func showFullAccessBanner() {
        let bannerHeight: CGFloat = 30
        let banner = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: bannerHeight))
        banner.backgroundColor = .systemRed
        
        let label = UILabel(frame: banner.bounds)
        label.text = "Please enable Full Access in Settings to use AI features."
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        banner.addSubview(label)
        
        view.addSubview(banner)
        
        UIView.animate(withDuration: 0.3, delay: 3.0, options: .curveEaseOut) {
            banner.alpha = 0
        } completion: { _ in
            banner.removeFromSuperview()
        }
    }
}
