import Foundation

enum MediaKind: String, Codable, CaseIterable, Hashable, Sendable {
    case movie
    case tv

    var localizationKey: String {
        switch self {
        case .movie: "kind.movie"
        case .tv: "kind.tv"
        }
    }
}

enum WatchStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case watched
    case wantToWatch

    var localizationKey: String {
        switch self {
        case .watched: "status.watched"
        case .wantToWatch: "status.wantToWatch"
        }
    }
}

enum MediaRating: String, Codable, CaseIterable, Hashable, Sendable {
    case liked
    case disliked

    var localizationKey: String {
        switch self {
        case .liked: "rating.liked"
        case .disliked: "rating.disliked"
        }
    }

    var symbolName: String {
        switch self {
        case .liked: "hand.thumbsup.fill"
        case .disliked: "hand.thumbsdown.fill"
        }
    }

    var outlineSymbolName: String {
        switch self {
        case .liked: "hand.thumbsup"
        case .disliked: "hand.thumbsdown"
        }
    }
}

enum MediaKey {
    static func make(kind: MediaKind, id: Int) -> String {
        "\(kind.rawValue)-\(id)"
    }
}

enum DateParsing {
    static func year(from string: String?) -> Int? {
        guard let string, string.count >= 4, let year = Int(string.prefix(4)), (1800...2999).contains(year) else {
            return nil
        }
        return year
    }
}
