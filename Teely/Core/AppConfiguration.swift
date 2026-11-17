import Foundation

enum AppConfiguration {
    static var tmdbAccessToken: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "TMDB_ACCESS_TOKEN") as? String
        return (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
