import Foundation

struct SearchResponseDTO: Decodable {
    let results: [SearchResultDTO]
}

struct SearchResultDTO: Decodable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?

    func summary() -> MediaSummary? {
        guard let mediaType, let kind = MediaKind(rawValue: mediaType) else { return nil }
        let resolvedTitle = (title ?? name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedTitle.isEmpty else { return nil }
        return MediaSummary(
            tmdbID: id,
            kind: kind,
            title: resolvedTitle,
            overview: overview ?? "",
            posterPath: posterPath,
            releaseYear: DateParsing.year(from: kind == .movie ? releaseDate : firstAirDate),
            voteAverage: voteAverage
        )
    }

    func summary(kind: MediaKind) -> MediaSummary? {
        let resolvedTitle = (title ?? name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedTitle.isEmpty else { return nil }
        return MediaSummary(
            tmdbID: id, kind: kind, title: resolvedTitle, overview: overview ?? "",
            posterPath: posterPath,
            releaseYear: DateParsing.year(from: kind == .movie ? releaseDate : firstAirDate),
            voteAverage: voteAverage
        )
    }
}

struct DetailDTO: Decodable {
    struct Genre: Decodable {
        let name: String
    }

    struct NamedValue: Decodable {
        let name: String
    }

    struct SpokenLanguage: Decodable {
        let name: String
        let englishName: String?
    }

    struct Person: Decodable {
        let name: String
    }

    struct Episode: Decodable {
        let name: String?
        let airDate: String?
        let episodeNumber: Int?
        let seasonNumber: Int?
    }

    struct MovieCredits: Decodable {
        let cast: [CastMemberDTO]?
        let crew: [CrewMemberDTO]?
    }

    struct TVAggregateCredits: Decodable {
        let cast: [AggregateCastMemberDTO]?
        let crew: [AggregateCrewMemberDTO]?
    }

    struct Videos: Decodable {
        let results: [VideoDTO]?
    }

    let id: Int
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let tagline: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let genres: [Genre]?
    let runtime: Int?
    let episodeRunTime: [Int]?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let originalLanguage: String?
    let status: String?
    let homepage: String?
    let budget: Int?
    let revenue: Int?
    let productionCompanies: [NamedValue]?
    let productionCountries: [NamedValue]?
    let spokenLanguages: [SpokenLanguage]?
    let originCountry: [String]?
    let createdBy: [Person]?
    let networks: [NamedValue]?
    let lastAirDate: String?
    let inProduction: Bool?
    let type: String?
    let nextEpisodeToAir: Episode?
    let credits: MovieCredits?
    let aggregateCredits: TVAggregateCredits?
    let videos: Videos?
}

struct CastMemberDTO: Decodable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?
}

struct CrewMemberDTO: Decodable {
    let id: Int
    let name: String
    let job: String?
    let department: String?
    let profilePath: String?
}

struct AggregateCastMemberDTO: Decodable {
    struct Role: Decodable {
        let character: String
    }

    let id: Int
    let name: String
    let profilePath: String?
    let order: Int?
    let roles: [Role]?
}

struct AggregateCrewMemberDTO: Decodable {
    struct Job: Decodable {
        let job: String
    }

    let id: Int
    let name: String
    let department: String?
    let profilePath: String?
    let jobs: [Job]?
}

struct VideoDTO: Decodable {
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool
    let iso6391: String?
    let publishedAt: String?
}
