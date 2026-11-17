import Foundation
import SwiftData

@Model
final class SavedMedia {
    @Attribute(.unique) var key: String
    var tmdbID: Int
    var kindRaw: String
    var title: String
    var overview: String
    var posterPath: String?
    var releaseYear: Int?
    var statusRaw: String
    var ratingRaw: String?
    var addedAt: Date
    var statusChangedAt: Date

    init(detail: MediaDetail, status: WatchStatus? = nil, addedAt: Date = .now) {
        self.key = detail.key
        self.tmdbID = detail.tmdbID
        self.kindRaw = detail.kind.rawValue
        self.title = detail.title
        self.overview = detail.overview
        self.posterPath = detail.posterPath
        self.releaseYear = detail.releaseYear
        self.statusRaw = status?.rawValue ?? "saved"
        self.ratingRaw = nil
        self.addedAt = addedAt
        self.statusChangedAt = status == nil ? addedAt : max(.now, addedAt.addingTimeInterval(0.001))
    }

    var kind: MediaKind {
        MediaKind(rawValue: kindRaw) ?? .movie
    }

    var status: WatchStatus? {
        get {
            guard let status = WatchStatus(rawValue: statusRaw) else { return nil }
            if status == .wantToWatch && statusChangedAt <= addedAt { return nil }
            return status
        }
        set {
            statusRaw = newValue?.rawValue ?? "saved"
            statusChangedAt = .now
            if newValue != .watched {
                ratingRaw = nil
            }
        }
    }

    var rating: MediaRating? {
        get { ratingRaw.flatMap(MediaRating.init(rawValue:)) }
        set { ratingRaw = status == .watched ? newValue?.rawValue : nil }
    }
}

struct SavedItem: Identifiable, Hashable, Sendable {
    let key: String
    let tmdbID: Int
    let kind: MediaKind
    let title: String
    let overview: String
    let posterPath: String?
    let releaseYear: Int?
    let status: WatchStatus?
    let rating: MediaRating?
    let addedAt: Date

    var id: String { key }

    init(key: String, tmdbID: Int, kind: MediaKind, title: String, overview: String = "", posterPath: String? = nil, releaseYear: Int? = nil, status: WatchStatus? = nil, rating: MediaRating? = nil, addedAt: Date = .now) {
        self.key = key
        self.tmdbID = tmdbID
        self.kind = kind
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseYear = releaseYear
        self.status = status
        self.rating = rating
        self.addedAt = addedAt
    }

    init(_ saved: SavedMedia) {
        self.init(
            key: saved.key,
            tmdbID: saved.tmdbID,
            kind: saved.kind,
            title: saved.title,
            overview: saved.overview,
            posterPath: saved.posterPath,
            releaseYear: saved.releaseYear,
            status: saved.status,
            rating: saved.rating,
            addedAt: saved.addedAt
        )
    }
}
