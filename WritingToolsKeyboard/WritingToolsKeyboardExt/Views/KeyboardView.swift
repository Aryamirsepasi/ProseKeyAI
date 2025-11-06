import SwiftUI

struct KeyboardView: View {
  weak var viewController: KeyboardViewController?
  @ObservedObject var vm: AIToolsViewModel

  @AppStorage(
    "enable_haptics",
    store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
  )
  private var enableHaptics = true

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
      .ignoresSafeArea(.container, edges: .all)
      .dynamicTypeSize(.large)
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

