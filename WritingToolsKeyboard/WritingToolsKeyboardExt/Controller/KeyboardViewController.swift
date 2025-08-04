import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var keyboardViewHostingController: UIHostingController<KeyboardView>?
    private var isHostingControllerAttached = false
    
    private lazy var viewModel: AIToolsViewModel = {
        return AIToolsViewModel(viewController: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Mark that the keyboard has been used
        UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
            .set(true, forKey: "keyboard_has_been_used")
        
        // Also set the standard UserDefaults
        UserDefaults.standard.set(true, forKey: "keyboard_enabled")
        
        // Also check and update full access status
        if hasFullAccess {
            UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
                .set(true, forKey: "hasFullAccess")
        }
        
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
        // Attach the hosting controller here, after the view has its correct size
        if keyboardViewHostingController == nil {
            let rootView = KeyboardView(viewController: self, vm: viewModel)
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.view.backgroundColor = .clear
            keyboardViewHostingController = hostingController
            attachHostingController(hostingController)
        }
        // No need to update frame if using Auto Layout constraints
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Always reload settings and providers
        AppSettings.shared.reload()
        AppState.shared.reloadProviders()
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
    
    
    private func attachHostingController(_ hostingController: UIHostingController<KeyboardView>) {
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
        isHostingControllerAttached = true
    }
    
    func getSelectedText() -> String? {
        guard hasFullAccess else { return nil }
        
        // Try to get selected text first (iOS 16+)
        if #available(iOS 16.0, *) {
            if let selectedText = textDocumentProxy.selectedText,
               !selectedText.isEmpty {
                return selectedText
            }
        }
        
        // Fall back to combining text before/after cursor
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only return combined text if it's not too long (200 chars or less)
        if !combined.isEmpty && combined.count <= 200 {
            return combined
        }
        
        return nil
    }
    
    private func showFullAccessBanner() {
        let bannerHeight: CGFloat = 30
        let banner = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: bannerHeight))
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
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -8)
        ])
        
        view.addSubview(banner)
        
        UIView.animate(withDuration: 0.3, delay: 3.0, options: .curveEaseOut) {
            banner.alpha = 0
        } completion: { _ in
            banner.removeFromSuperview()
        }
    }
}
