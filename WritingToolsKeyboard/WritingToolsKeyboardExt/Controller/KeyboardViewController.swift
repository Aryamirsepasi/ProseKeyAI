import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var keyboardViewHostingController: UIHostingController<KeyboardView>?
    private var blurEffectView: UIVisualEffectView?
    private var isHostingControllerAttached = false
    
    private lazy var viewModel: AIToolsViewModel = {
        return AIToolsViewModel(viewController: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBlurEffect()
        
        let settings = AppSettings.shared
            print("Current provider: \(settings.currentProvider)")
            print("Gemini API key (exists): \(!settings.geminiApiKey.isEmpty)")
            print("OpenAI API key (exists): \(!settings.openAIApiKey.isEmpty)")
            print("Mistral API key (exists): \(!settings.mistralApiKey.isEmpty)")
        
        Task(priority: .userInitiated) {
            await prepareHostingController()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let hostingController = keyboardViewHostingController {
            if !isHostingControllerAttached {
                attachHostingController(hostingController)
            }
            hostingController.view.isHidden = false
        } else {
            setupHostingControllerSynchronously()
        }
        
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
    
    @MainActor
    private func prepareHostingController() async {
        guard keyboardViewHostingController == nil else { return }
        
        await MainActor.run {
            let rootView = KeyboardView(viewController: self, vm: viewModel)
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.view.backgroundColor = .clear
            
            self.keyboardViewHostingController = hostingController
            
            if self.isViewLoaded && self.view.window != nil {
                attachHostingController(hostingController)
            }
        }
    }
    
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
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
    
    private func setupHostingControllerSynchronously() {
        guard keyboardViewHostingController == nil else { return }
        
        let rootView = KeyboardView(viewController: self, vm: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        
        attachHostingController(hostingController)
        
        self.keyboardViewHostingController = hostingController
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
