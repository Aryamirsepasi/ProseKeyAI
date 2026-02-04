import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct FoundationModelsSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var provider = FoundationModelsProvider()

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Foundation Models")
                            .font(.headline)
                        Text("On-device AI powered by Apple Intelligence")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Availability Status") {
                availabilityStatusRow
            }
            
            Section {
                Button {
                    settings.currentProvider = "foundationmodels"
                    appState.setCurrentProvider("foundationmodels")
                    dismiss()
                } label: {
                    Text("Set as Current Provider")
                        .padding(5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!provider.isAvailable || settings.currentProvider == "foundationmodels")
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } footer: {
                if !provider.isAvailable {
                    Text("Enable Apple Intelligence in Settings to use this provider.")
                }
            }

            Section("Features") {
                FeatureRow(icon: "checkmark.circle.fill", text: "No API key required")
                FeatureRow(icon: "checkmark.circle.fill", text: "Works completely offline")
                FeatureRow(icon: "checkmark.circle.fill", text: "Private - all processing on-device")
                FeatureRow(icon: "checkmark.circle.fill", text: "Fast response times")
                FeatureRow(icon: "xmark.circle.fill", text: "No image input support")
                FeatureRow(icon: "info.circle.fill", text: "4,096 token context limit")
            }

            if provider.isAvailable {
                Section("Supported Languages") {
                    ForEach(Array(supportedLanguages.enumerated()), id: \.offset) { _, locale in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(formattedLanguageName(for: locale))
                                .font(.subheadline)
                        }
                    }

                    if !supportedLanguages.isEmpty {
                        Text("\(supportedLanguages.count) languages supported")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Multiple languages supported")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !provider.isAvailable {
                Section("How to Enable") {
                    if case .unavailable(.appleIntelligenceNotEnabled) = provider.availability {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }

                        Text("Steps to enable Apple Intelligence:")
                            .font(.subheadline.weight(.semibold))

                        Text("1. Open Settings app")
                        Text("2. Go to Apple Intelligence & Siri")
                        Text("3. Enable Apple Intelligence")
                            .foregroundStyle(.secondary)
                    } else if case .unavailable(.deviceNotEligible) = provider.availability {
                        Text("Your device does not support Apple Intelligence. Foundation Models requires an iPhone 15 Pro or later, or a recent iPad.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if case .unavailable(.modelNotReady) = provider.availability {
                        Text("The model is still downloading or initializing. Please wait a few minutes and try again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Foundation Models is currently unavailable.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

        }
        .navigationTitle("Foundation Models")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var availabilityStatusRow: some View {
        HStack {
            if provider.isAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(unavailabilityMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var supportedLanguages: [Locale.Language] {
        let languages = Array(SystemLanguageModel.default.supportedLanguages)
        return languages.sorted { $0.maximalIdentifier < $1.maximalIdentifier }
    }

    private var unavailabilityMessage: String {
        let availability = provider.availability
        switch availability {
        case .available:
            return "Available"
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence not enabled"
            case .deviceNotEligible:
                return "Device not eligible"
            case .modelNotReady:
                return "Model not ready"
            @unknown default:
                return "Unavailable"
            }
        }
    }

    private func formattedLanguageName(for language: Locale.Language) -> String {
        let identifier = language.maximalIdentifier
        let components = identifier.split(separator: "-")

        if let languageName = Locale.current.localizedString(forLanguageCode: String(components[0])) {
            if components.count > 1, let regionCode = components.last {
                if let regionName = Locale.current.localizedString(forRegionCode: String(regionCode)) {
                    return "\(languageName) (\(regionName))"
                }
            }
            return languageName
        }

        return identifier.capitalized
    }
}

#Preview("Foundation Models Settings") {
    if #available(iOS 26.0, *) {
        NavigationStack {
            FoundationModelsSettingsView(appState: .shared)
        }
    } else {
        Text("Requires iOS 26.0 or later")
            .foregroundStyle(.secondary)
    }
}
