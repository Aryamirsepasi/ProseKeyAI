import SwiftUI

struct KeyboardView: View {
  weak var viewController: KeyboardViewController?
  @StateObject private var vm: AIToolsViewModel
  
  init(viewController: KeyboardViewController?) {
    self.viewController = viewController
    _vm = StateObject(wrappedValue: AIToolsViewModel(viewController: viewController))
  }

  init(viewController: KeyboardViewController?, vm: AIToolsViewModel) {
    self.viewController = viewController
    _vm = StateObject(wrappedValue: vm)
  }

  var body: some View {
    AIToolsView(vm: vm)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
