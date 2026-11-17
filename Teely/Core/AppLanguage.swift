import Foundation

enum AppLanguage {
    static let supported = ["en-US", "pt-BR", "es-ES"]

    static func tmdbCode(for identifier: String) -> String {
        let lowered = identifier.lowercased()
        if lowered.hasPrefix("pt") { return "pt-BR" }
        if lowered.hasPrefix("es") { return "es-ES" }
        return "en-US"
    }

    static var current: String {
        tmdbCode(for: Bundle.main.preferredLocalizations.first ?? "en")
    }
}
