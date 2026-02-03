import SwiftUI

extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(of value: Value, _ action: @escaping (Value) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}
