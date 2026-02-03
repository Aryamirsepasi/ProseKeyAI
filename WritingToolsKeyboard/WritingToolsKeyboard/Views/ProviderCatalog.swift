import SwiftUI

struct ProviderInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let iconType: ProviderIconType
    let color: Color
    let requiresApiKey: Bool
}

enum ProviderIconType: Equatable {
    case system(String)
    case asset(String)
}

enum ProviderCatalog {
    static func providers(includeFoundationModels: Bool) -> [ProviderInfo] {
        var list: [ProviderInfo] = []
        if includeFoundationModels {
            list.append(
                ProviderInfo(
                    id: "foundationmodels",
                    name: "Apple Foundation Models",
                    iconType: .system("apple.intelligence"),
                    color: .blue,
                    requiresApiKey: false
                )
            )
        }

        list.append(contentsOf: [
            ProviderInfo(
                id: "gemini",
                name: "Google Gemini",
                iconType: .asset("google"),
                color: Color(hex: "4285F4"),
                requiresApiKey: true
            ),
            ProviderInfo(
                id: "openai",
                name: "OpenAI",
                iconType: .asset("openai"),
                color: .primary,
                requiresApiKey: true
            ),
            ProviderInfo(
                id: "mistral",
                name: "Mistral AI",
                iconType: .asset("mistralai"),
                color: Color(hex: "FA520F"),
                requiresApiKey: true
            ),
            ProviderInfo(
                id: "anthropic",
                name: "Anthropic",
                iconType: .asset("anthropic"),
                color: Color(hex: "c15f3c"),
                requiresApiKey: true
            ),
            ProviderInfo(
                id: "openrouter",
                name: "OpenRouter",
                iconType: .system("o.circle.fill"),
                color: Color(hex: "7FADF2"),
                requiresApiKey: true
            ),
            ProviderInfo(
                id: "perplexity",
                name: "Perplexity",
                iconType: .asset("perplexity"),
                color: Color(hex: "1FB8CD"),
                requiresApiKey: true
            )
        ])

        return list
    }

    static func info(for id: String) -> ProviderInfo {
        let allProviders = providers(includeFoundationModels: true)
        if let match = allProviders.first(where: { $0.id == id }) {
            return match
        }
        return ProviderInfo(
            id: id,
            name: "Unknown Provider",
            iconType: .system("questionmark"),
            color: .gray,
            requiresApiKey: true
        )
    }
}

struct ProviderIconView: View {
    let info: ProviderInfo
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(info.color.opacity(0.15))
                .frame(width: size, height: size)
            switch info.iconType {
            case .system(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.55, weight: .semibold))
                    .foregroundStyle(info.color)
            case .asset(let name):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.55, height: size * 0.55)
                    .foregroundStyle(info.color)
            }
        }
        .accessibilityHidden(true)
    }
}
