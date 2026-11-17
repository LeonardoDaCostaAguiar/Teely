import Foundation

struct MediaSummary: Identifiable, Hashable, Sendable {
    let tmdbID: Int
    let kind: MediaKind
    let title: String
    var overview: String = ""
    var posterPath: String? = nil
    var releaseYear: Int? = nil
    var voteAverage: Double? = nil

    var key: String { MediaKey.make(kind: kind, id: tmdbID) }

    var id: String { key }
}
