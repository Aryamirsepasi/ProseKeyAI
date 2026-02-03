import SwiftUI

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6), in: .rect(cornerRadius: 10))
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .accessibilityLabel(label)
                    .accessibilityHint(placeholder)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6), in: .rect(cornerRadius: 10))
                    .textInputAutocapitalization(.never)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .accessibilityLabel(label)
                    .accessibilityHint(placeholder)
            }
        }
        .padding(.bottom, 8)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(icon.contains("xmark") ? .red : (icon.contains("info") ? .blue : .green))
                .font(.system(size: 14))
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview("Feature Row") {
    VStack(alignment: .leading, spacing: 12) {
        FeatureRow(icon: "checkmark.circle.fill", text: "Feature enabled")
        FeatureRow(icon: "xmark.circle.fill", text: "Feature disabled")
        FeatureRow(icon: "info.circle.fill", text: "Additional information")
    }
    .padding()
}
