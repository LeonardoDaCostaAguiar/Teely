import Foundation

struct StubMediaService: MediaServicing {
    var trendingFails = false
    var extendedDetails = false

    init(trendingFails: Bool = false, extendedDetails: Bool = false) {
        self.trendingFails = trendingFails
        self.extendedDetails = extendedDetails
    }

    static let catalog: [MediaSummary] = [
        MediaSummary(tmdbID: 101, kind: .movie, title: "Teely Movie", overview: "A movie used by the interface tests.", releaseYear: 2024),
        MediaSummary(tmdbID: 202, kind: .tv, title: "Teely Series", overview: "A series used by the interface tests.", releaseYear: 2023),
        MediaSummary(tmdbID: 303, kind: .movie, title: "Teely Short", overview: "A short film used by the interface tests.", releaseYear: 2022),
        MediaSummary(tmdbID: 404, kind: .movie, title: longTitle, overview: "A movie with a long title used by the interface tests.", releaseYear: 2021)
    ]

    static let longTitle = "The Extraordinarily Long Title of a Movie Used to Verify Complete Text Wrapping on Cards"

    func search(query: String, language: String) async throws -> [MediaSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return Self.catalog.filter { $0.title.lowercased().contains(trimmed) }
    }

    func detail(kind: MediaKind, id: Int, language: String) async throws -> MediaDetail {
        guard let item = Self.catalog.first(where: { $0.tmdbID == id && $0.kind == kind }) else {
            throw TMDBError.notFound
        }
        var detail = MediaDetail(
            tmdbID: item.tmdbID,
            kind: item.kind,
            title: item.title,
            tagline: nil,
            overview: "stub-overview-\(language)",
            releaseYear: item.releaseYear,
            genres: ["Drama", "Comedy"],
            runtimeMinutes: item.kind == .movie ? 120 : nil,
            seasons: item.kind == .tv ? 3 : nil,
            voteAverage: 7.8
        )
        if extendedDetails {
            detail.releaseDate = "2024-04-05"
            detail.productionStatus = "Released"
            detail.productionCompanies = ["Teely Studios"]
            detail.cast = [MediaCastMember(id: 801, name: "Actor One", character: "Lead", profilePath: nil, order: 0)]
            detail.crew = [MediaCrewMember(id: 802, name: "Director One", job: "Director")]
            detail.officialTrailer = MediaTrailer(key: "M7lc1UVf-VE", name: "Official trailer", site: "YouTube", language: "en")
        }
        return detail
    }

    func trending(kind: MediaKind, language: String) async throws -> [MediaSummary] {
        if trendingFails { throw TMDBError.http(500) }
        return Self.catalog.filter { $0.kind == kind }
    }
}
