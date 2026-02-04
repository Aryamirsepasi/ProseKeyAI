import SwiftUI

struct KeyboardView: View {
  weak var viewController: KeyboardViewController?
  @ObservedObject private var vm: AIToolsViewModel
  
  /// Initialize with an existing ViewModel instance from the KeyboardViewController.
  /// This ensures a single ViewModel is shared and avoids duplicate instances.
  init(viewController: KeyboardViewController?, vm: AIToolsViewModel) {
    self.viewController = viewController
    self.vm = vm
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
