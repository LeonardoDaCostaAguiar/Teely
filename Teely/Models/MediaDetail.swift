import Foundation

struct MediaCastMember: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int
}

struct MediaCrewMember: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let job: String
}

struct MediaTrailer: Hashable, Sendable {
    let key: String
    let name: String
    let site: String
    let language: String?

    var embedURL: URL? {
        embedURL(origin: nil)
    }

    func embedURL(origin: URL?) -> URL? {
        let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        switch site.lowercased() {
        case "youtube":
            var components = URLComponents(string: "https://www.youtube-nocookie.com/embed/\(escapedKey)")
            var items = [
                URLQueryItem(name: "playsinline", value: "1"),
                URLQueryItem(name: "rel", value: "0")
            ]
            if let origin {
                items.append(URLQueryItem(name: "origin", value: origin.absoluteString))
            }
            components?.queryItems = items
            return components?.url
        case "vimeo":
            return URL(string: "https://player.vimeo.com/video/\(escapedKey)?playsinline=1")
        default:
            return nil
        }
    }
}

struct MediaDetail: Hashable, Sendable {
    let tmdbID: Int
    let kind: MediaKind
    let title: String
    var originalTitle: String? = nil
    var tagline: String? = nil
    var overview: String = ""
    var posterPath: String? = nil
    var backdropPath: String? = nil
    var releaseYear: Int? = nil
    var releaseDate: String? = nil
    var lastAirDate: String? = nil
    var inProduction: Bool? = nil
    var seriesType: String? = nil
    var nextEpisodeName: String? = nil
    var nextEpisodeDate: String? = nil
    var nextEpisodeNumber: Int? = nil
    var nextSeasonNumber: Int? = nil
    var genres: [String] = []
    var runtimeMinutes: Int? = nil
    var seasons: Int? = nil
    var episodes: Int? = nil
    var voteAverage: Double? = nil
    var voteCount: Int? = nil
    var popularity: Double? = nil
    var originalLanguage: String? = nil
    var productionStatus: String? = nil
    var homepage: URL? = nil
    var budget: Int? = nil
    var revenue: Int? = nil
    var productionCompanies: [String] = []
    var productionCountries: [String] = []
    var spokenLanguages: [String] = []
    var originCountries: [String] = []
    var creators: [String] = []
    var networks: [String] = []
    var cast: [MediaCastMember] = []
    var crew: [MediaCrewMember] = []
    var officialTrailer: MediaTrailer? = nil

    var key: String { MediaKey.make(kind: kind, id: tmdbID) }
}

extension MediaDetail {
    init(dto: DetailDTO, kind: MediaKind) {
        let cleanTagline = dto.tagline?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cast: [MediaCastMember]
        let crew: [MediaCrewMember]
        if kind == .movie {
            cast = (dto.credits?.cast ?? []).sorted { ($0.order ?? .max) < ($1.order ?? .max) }.map {
                MediaCastMember(id: $0.id, name: $0.name, character: $0.character, profilePath: $0.profilePath, order: $0.order ?? .max)
            }
            crew = (dto.credits?.crew ?? []).map {
                MediaCrewMember(id: $0.id, name: $0.name, job: $0.job ?? $0.department ?? "")
            }
        } else {
            cast = (dto.aggregateCredits?.cast ?? []).sorted { ($0.order ?? .max) < ($1.order ?? .max) }.map {
                MediaCastMember(id: $0.id, name: $0.name, character: $0.roles?.map(\.character).filter { !$0.isEmpty }.joined(separator: ", "), profilePath: $0.profilePath, order: $0.order ?? .max)
            }
            crew = (dto.aggregateCredits?.crew ?? []).map {
                MediaCrewMember(id: $0.id, name: $0.name, job: $0.jobs?.map(\.job).filter { !$0.isEmpty }.joined(separator: ", ") ?? $0.department ?? "")
            }
        }
        self.init(
            tmdbID: dto.id,
            kind: kind,
            title: dto.title ?? dto.name ?? "",
            originalTitle: dto.originalTitle ?? dto.originalName,
            tagline: (cleanTagline?.isEmpty ?? true) ? nil : cleanTagline,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseYear: DateParsing.year(from: kind == .movie ? dto.releaseDate : dto.firstAirDate),
            releaseDate: kind == .movie ? dto.releaseDate : dto.firstAirDate,
            lastAirDate: dto.lastAirDate,
            inProduction: dto.inProduction,
            seriesType: dto.type,
            nextEpisodeName: dto.nextEpisodeToAir?.name,
            nextEpisodeDate: dto.nextEpisodeToAir?.airDate,
            nextEpisodeNumber: dto.nextEpisodeToAir?.episodeNumber,
            nextSeasonNumber: dto.nextEpisodeToAir?.seasonNumber,
            genres: (dto.genres ?? []).map(\.name),
            runtimeMinutes: kind == .movie ? dto.runtime : dto.episodeRunTime?.first,
            seasons: dto.numberOfSeasons,
            episodes: dto.numberOfEpisodes,
            voteAverage: dto.voteAverage,
            voteCount: dto.voteCount,
            popularity: dto.popularity,
            originalLanguage: dto.originalLanguage,
            productionStatus: dto.status,
            homepage: URL(string: dto.homepage ?? ""),
            budget: dto.budget,
            revenue: dto.revenue,
            productionCompanies: (dto.productionCompanies ?? []).map(\.name),
            productionCountries: (dto.productionCountries ?? []).map(\.name),
            spokenLanguages: (dto.spokenLanguages ?? []).map { $0.englishName ?? $0.name },
            originCountries: dto.originCountry ?? [],
            creators: (dto.createdBy ?? []).map(\.name),
            networks: (dto.networks ?? []).map(\.name),
            cast: cast,
            crew: crew,
            officialTrailer: Self.officialTrailer(from: dto.videos?.results ?? [])
        )
    }

    init(saved: SavedItem) {
        self.init(
            tmdbID: saved.tmdbID,
            kind: saved.kind,
            title: saved.title,
            overview: saved.overview,
            posterPath: saved.posterPath,
            releaseYear: saved.releaseYear
        )
    }

    private static func officialTrailer(from videos: [VideoDTO]) -> MediaTrailer? {
        let trailers = videos.filter {
            $0.official && $0.type.caseInsensitiveCompare("Trailer") == .orderedSame &&
                ["youtube", "vimeo"].contains($0.site.lowercased())
        }
        guard let chosen = trailers.sorted(by: {
            if ($0.site.lowercased() == "youtube") != ($1.site.lowercased() == "youtube") {
                return $0.site.lowercased() == "youtube"
            }
            return ($0.publishedAt ?? "") > ($1.publishedAt ?? "")
        }).first else { return nil }
        return MediaTrailer(key: chosen.key, name: chosen.name, site: chosen.site, language: chosen.iso6391)
    }
}
