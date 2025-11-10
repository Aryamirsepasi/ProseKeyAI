import SwiftUI

struct KeyboardView: View {
  weak var viewController: KeyboardViewController?
  @ObservedObject var vm: AIToolsViewModel

  @AppStorage(
    "enable_haptics",
    store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
  )
  private var enableHaptics = true
  
  // Mirror controller height (2 command rows visible)
  private let keyboardHeight: CGFloat = 340

  init(viewController: KeyboardViewController?, vm: AIToolsViewModel? = nil) {
    self.viewController = viewController
    if let existingVM = vm {
      self.vm = existingVM
    } else {
      self.vm = AIToolsViewModel(viewController: viewController)
    }
  }

  var body: some View {
    AIToolsView(vm: vm)
      .frame(width: UIScreen.main.bounds.width, height: keyboardHeight)
      .ignoresSafeArea(.all, edges: .all)
      .onAppear {
        vm.checkSelectedText()
        UIAccessibility.post(
          notification: .screenChanged,
          argument: "ProseKey AI Keyboard Ready"
        )
      }
      .accessibilityElement(children: .contain)
  }
}
