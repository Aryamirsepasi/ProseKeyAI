import SwiftUI

struct KeyboardView: View {
    weak var viewController: KeyboardViewController?
    @StateObject private var vm: AIToolsViewModel
    
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = true
    
    init(viewController: KeyboardViewController?) {
        self.viewController = viewController
        _vm = StateObject(wrappedValue: AIToolsViewModel(viewController: viewController))
    }
    
    var body: some View {
        ZStack {
            AIToolsView(vm: vm)
        }
        .ignoresSafeArea(.container, edges: .all)
        .background(Color.clear)
    }
}