import Foundation

enum Search {
    enum Perform {
        struct Request {
            let query: String
        }

        enum Failure: Equatable {
            case missingToken
            case network
        }

        struct Response {
            let query: String
            let results: [MediaSummary]
            let failure: Failure?
        }
    }

    enum Select {
        struct Request {
            let key: String
        }
    }

    enum State: Equatable {
        case loading
        case results([SearchRowViewModel])
        case empty(title: String, message: String)
        case failure(title: String, message: String)
    }
}

struct SearchRowViewModel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let overview: String
    let posterURL: URL?
    let accessibilityLabel: String
}
