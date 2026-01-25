import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct FoundationModelsSettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var provider = FoundationModelsProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text("Apple Foundation Models")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("On-device AI powered by Apple Intelligence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // Availability Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Availability Status")
                        .font(.headline)

                    availabilityStatusView
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.headline)

                    FeatureRow(icon: "checkmark.circle.fill", text: "No API key required")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Works completely offline")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Private - all processing on-device")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Fast response times")
                    FeatureRow(icon: "xmark.circle.fill", text: "No image input support")
                    FeatureRow(icon: "info.circle.fill", text: "4,096 token context limit")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Supported Languages
                #if canImport(FoundationModels)
                if #available(iOS 26.0, *) {
                    if provider.isAvailable {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Supported Languages")
                                .font(.headline)

                            let languages = Array(SystemLanguageModel.default.supportedLanguages)
                                .sorted { $0.maximalIdentifier < $1.maximalIdentifier }

                            if !languages.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], alignment: .leading, spacing: 8) {
                                    ForEach(Array(languages.enumerated()), id: \.offset) { _, locale in
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.green)
                                            Text(formattedLanguageName(for: locale))
                                                .font(.footnote)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                Divider()
                                    .padding(.vertical, 4)

                                Text("\(languages.count) languages supported")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Multiple languages supported")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                #endif

                // Help section
                if !provider.isAvailable {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Enable")
                            .font(.headline)

                        #if canImport(FoundationModels)
                        if #available(iOS 26.0, *) {
                            let availability = provider.availability
                            if case .unavailable(.appleIntelligenceNotEnabled) = availability {
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "gear")
                                        Text("Open Settings")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Steps to enable Apple Intelligence:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    HStack(alignment: .top) {
                                        Text("1.")
                                            .foregroundColor(.blue)
                                        Text("Open Settings app")
                                    }

                                    HStack(alignment: .top) {
                                        Text("2.")
                                            .foregroundColor(.blue)
                                        Text("Go to Apple Intelligence & Siri")
                                    }

                                    HStack(alignment: .top) {
                                        Text("3.")
                                            .foregroundColor(.blue)
                                        Text("Enable Apple Intelligence")
                                    }
                                }
                                .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else if case .unavailable(.deviceNotEligible) = availability {
                                Text("Your device does not support Apple Intelligence. Foundation Models requires an iPhone 15 Pro or later, or a recent iPad.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else if case .unavailable(.modelNotReady) = availability {
                                Text("The model is still downloading or initializing. Please wait a few minutes and try again.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        #endif

                        if #unavailable(iOS 26.0) {
                            Text("Foundation Models requires iOS 26.0 or later.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Foundation Models")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var availabilityStatusView: some View {
        if #available(iOS 26.0, *) {
            if provider.isAvailable {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(unavailabilityMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        } else {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Requires iOS 26.0 or later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    private var unavailabilityMessage: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
        #endif
        return "Unavailable"
    }

    private func formattedLanguageName(for language: Locale.Language) -> String {
        let identifier = language.maximalIdentifier
        let components = identifier.split(separator: "-")

        // Get the language name
        if let languageName = Locale.current.localizedString(forLanguageCode: String(components[0])) {
            // Check if there's a region component
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
            .foregroundColor(.secondary)
    }
}
