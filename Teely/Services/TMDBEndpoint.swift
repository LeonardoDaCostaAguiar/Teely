import Foundation

struct TMDBEndpoint: Equatable {
    let path: String
    let queryItems: [URLQueryItem]

    static func search(query: String, language: String, page: Int = 1) -> TMDBEndpoint {
        TMDBEndpoint(
            path: "/3/search/multi",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: String(page))
            ]
        )
    }

    static func trending(kind: MediaKind, language: String, window: String = "week") -> TMDBEndpoint {
        TMDBEndpoint(path: "/3/trending/\(kind.rawValue)/\(window)", queryItems: [
            URLQueryItem(name: "language", value: language)
        ])
    }

    static func detail(kind: MediaKind, id: Int, language: String) -> TMDBEndpoint {
        TMDBEndpoint(
            path: "/3/\(kind.rawValue)/\(id)",
            queryItems: [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "append_to_response", value: kind == .movie ? "credits,videos" : "aggregate_credits,videos")
            ]
        )
    }

    func url(baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}

enum ImageSize: String {
    case w185
    case w342
    case w500
    case w780
}

enum ImageURLBuilder {
    static let baseURL = "https://image.tmdb.org/t/p/"

    static func url(path: String?, size: ImageSize) -> URL? {
        guard let path, !path.isEmpty, path.hasPrefix("/") else { return nil }
        return URL(string: baseURL + size.rawValue + path)
    }
}
