import SwiftUI

struct ProviderSelectionView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        List {
            Section("Providers") {
                ForEach(providers) { provider in
                    NavigationLink {
                        destinationView(for: provider.id)
                    } label: {
                        ProviderListRow(
                            info: provider,
                            statusText: providerStatusText(for: provider.id),
                            isSelected: settings.currentProvider == provider.id
                        )
                    }
                }
            }
        }
        .navigationTitle("Providers")
    }

    private var providers: [ProviderInfo] {
        if #available(iOS 26.0, *) {
            return ProviderCatalog.providers(includeFoundationModels: true)
        }
        return ProviderCatalog.providers(includeFoundationModels: false)
    }

    private func providerStatusText(for provider: String) -> String {
        switch provider {
        case "gemini":
            return settings.geminiApiKey.isEmpty ? "Needs API key" : "API key added"
        case "openai":
            return settings.openAIApiKey.isEmpty ? "Needs API key" : "API key added"
        case "mistral":
            return settings.mistralApiKey.isEmpty ? "Needs API key" : "API key added"
        case "anthropic":
            return settings.anthropicApiKey.isEmpty ? "Needs API key" : "API key added"
        case "openrouter":
            return settings.openRouterApiKey.isEmpty ? "Needs API key" : "API key added"
        case "perplexity":
            return settings.perplexityApiKey.isEmpty ? "Needs API key" : "API key added"
        case "foundationmodels":
            if #available(iOS 26.0, *) {
                return FoundationModelsProvider().isAvailable ? "Available" : "Unavailable"
            }
            return "Requires iOS 26"
        default:
            return ""
        }
    }

    @ViewBuilder
    private func destinationView(for provider: String) -> some View {
        switch provider {
        case "gemini":
            GeminiSettingsView(appState: appState)
        case "openai":
            OpenAISettingsView(appState: appState)
        case "mistral":
            MistralSettingsView(appState: appState)
        case "anthropic":
            AnthropicSettingsView(appState: appState)
        case "openrouter":
            OpenRouterSettingsView(appState: appState)
        case "perplexity":
            PerplexitySettingsView(appState: appState)
        case "foundationmodels":
            if #available(iOS 26.0, *) {
                FoundationModelsSettingsView(appState: appState)
            } else {
                Text("Requires iOS 26.0 or later")
                    .foregroundStyle(.secondary)
            }
        default:
            Text("Unknown provider")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProviderListRow: View {
    let info: ProviderInfo
    let statusText: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ProviderIconView(info: info, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(info.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(info.name)
        .accessibilityValue(statusText)
    }
}
