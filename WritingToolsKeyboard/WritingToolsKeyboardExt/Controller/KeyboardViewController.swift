import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var keyboardViewHostingController: UIHostingController<KeyboardView>?
    private var blurEffectView: UIVisualEffectView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Blur effect view
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(blurView, at: 0)
        self.blurEffectView = blurView

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // SwiftUI keyboard view
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
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        self.keyboardViewHostingController = hostingController
        hostingController.view.backgroundColor = .clear

        // Show a banner if full access is not enabled
        if !hasFullAccess {
            showFullAccessBanner()
        }
    }

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
        guard hasFullAccess else {
            return nil
        }
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
