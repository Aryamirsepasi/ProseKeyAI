import SwiftUI

struct KeyboardView: View {
    weak var viewController: KeyboardViewController?
    @ObservedObject var vm: AIToolsViewModel
    
    private let defaultsStore = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
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
            .onAppear {
                // Check for selected text when the view appears
                vm.checkSelectedText()
                UIAccessibility.post(notification: .screenChanged, argument: "ProseKey AI Keyboard Ready")
            }
            .ignoresSafeArea(.container, edges: .all)
            .background(.clear)
            .dynamicTypeSize(.large) // Support dynamic type
            .accessibilityElement(children: .contain)
    }
}
