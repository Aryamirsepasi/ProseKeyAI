import SwiftUI

struct ApiKeyHelpView: View {
    @Environment(\.dismiss) private var dismiss
    let provider: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: providerIcon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(providerName)
                                .font(.headline)
                            Text("API key help")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Steps") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(step.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !notes.isEmpty {
                    Section("Notes") {
                        ForEach(notes, id: \.self) { note in
                            Label(note, systemImage: "exclamationmark.circle")
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    if let url = URL(string: apiKeyUrl) {
                        Link(destination: url) {
                            Label("Open \(providerName) API Key Page", systemImage: "arrow.up.right.square")
                        }
                    }
                }
            }
            .navigationTitle("API Key Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var providerIcon: String {
        switch provider {
        case "gemini": return "g.circle.fill"
        case "openai": return "o.circle.fill"
        case "mistral": return "m.circle.fill"
        case "anthropic": return "a.circle.fill"
        case "openrouter": return "r.circle.fill"
        case "perplexity": return "p.circle.fill"
        default: return "questionmark"
        }
    }

    private var providerName: String {
        switch provider {
        case "gemini": return "Google Gemini"
        case "openai": return "OpenAI"
        case "mistral": return "Mistral AI"
        case "anthropic": return "Anthropic"
        case "openrouter": return "OpenRouter"
        case "perplexity": return "Perplexity"
        default: return "Unknown Provider"
        }
    }

    private var apiKeyUrl: String {
        switch provider {
        case "gemini": return "https://ai.google.dev/tutorials/setup"
        case "openai": return "https://platform.openai.com/account/api-keys"
        case "mistral": return "https://console.mistral.ai/api-keys/"
        case "anthropic": return "https://console.anthropic.com/settings/keys"
        case "openrouter": return "https://openrouter.ai/keys"
        case "perplexity": return "https://www.perplexity.ai/settings/api"
        default: return "https://example.com"
        }
    }

    private var steps: [(title: String, description: String)] {
        switch provider {
        case "gemini":
            return [
                ("Open Google AI Studio", "Go to ai.google.dev and sign in."),
                ("Go to API Keys", "Open API settings from the sidebar."),
                ("Create a key", "Generate a new key and copy it.")
            ]
        case "openai":
            return [
                ("Open OpenAI Platform", "Visit platform.openai.com and sign in."),
                ("Go to API Keys", "Open API keys in settings."),
                ("Create a key", "Create a new secret key and copy it.")
            ]
        case "mistral":
            return [
                ("Open Mistral Console", "Visit console.mistral.ai and sign in."),
                ("Go to API Keys", "Open API keys in the dashboard."),
                ("Create a key", "Create a new key and copy it.")
            ]
        case "anthropic":
            return [
                ("Open Anthropic Console", "Visit console.anthropic.com and sign in."),
                ("Go to API Keys", "Open API keys in settings."),
                ("Create a key", "Create a new key and copy it.")
            ]
        case "openrouter":
            return [
                ("Open OpenRouter", "Visit openrouter.ai and sign in."),
                ("Go to Keys", "Open the Keys section in your account."),
                ("Create a key", "Create a new key and copy it.")
            ]
        case "perplexity":
            return [
                ("Open Perplexity", "Visit perplexity.ai and sign in."),
                ("Go to API Keys", "Open your API settings page."),
                ("Create a key", "Create a new key and copy it.")
            ]
        default:
            return []
        }
    }

    private var notes: [String] {
        switch provider {
        case "gemini":
            return ["Some Gemini models require billing enabled."]
        case "openai":
            return ["Never share your secret key."]
        case "mistral":
            return ["Keys can be rotated at any time."]
        case "anthropic":
            return ["Make sure your account is verified."]
        case "openrouter":
            return ["OpenRouter keys can access multiple providers."]
        case "perplexity":
            return ["Perplexity keys can be managed from account settings."]
        default:
            return []
        }
    }
}
