import Foundation

enum Detail {
    enum Load {
        struct Request {}
    }

    enum SetStatus {
        struct Request {
            let status: WatchStatus
        }
    }

    enum SetRating {
        struct Request {
            let rating: MediaRating
        }
    }

    enum Save {
        struct Request {}
    }

    enum Remove {
        struct Request {}
    }

    enum Failure: Equatable {
        case missingToken
        case network
    }

    struct Response {
        let detail: MediaDetail
        let saved: SavedItem?
    }

    struct ViewModel: Equatable {
        let title: String
        let metadata: String
        let tagline: String?
        let overview: String
        let genres: String?
        let scoreText: String?
        let posterURL: URL?
        let isSaved: Bool
        let status: WatchStatus?
        let showsRatingControls: Bool
        let rating: MediaRating?
        let facts: [Fact]
        let cast: [MediaCastMember]
        let officialTrailer: MediaTrailer?
    }

    struct Fact: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
    }

    enum State: Equatable {
        case loading
        case content(ViewModel)
        case failure(title: String, message: String)
    }
}
