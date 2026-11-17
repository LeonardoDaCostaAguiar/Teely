import Foundation

enum Library {
    enum Load {
        struct Request {}

        struct Response {
            let items: [SavedItem]
            let didFail: Bool
            var filter: LibraryFilter = .all
        }

        struct ViewModel: Equatable {
            let cards: [LibraryCardViewModel]
            let emptyTitle: String
            let emptyMessage: String
            let errorMessage: String?
            var filters: [LibraryFilterViewModel] = []
        }
    }

    enum SetFilter {
        struct Request {
            let filter: LibraryFilter
        }
    }

    enum Select {
        struct Request {
            let key: String
        }
    }

    enum Search {
        struct Request {
            let query: String
        }
    }
}

enum LibraryFilter: String, CaseIterable, Hashable, Sendable {
    case all
    case watched
    case wantToWatch

    var localizationKey: String {
        switch self {
        case .all: "library.filter.all"
        case .watched: "library.filter.watched"
        case .wantToWatch: "library.filter.wantToWatch"
        }
    }

    func matches(_ item: SavedItem) -> Bool {
        switch self {
        case .all: true
        case .watched: item.status == .watched
        case .wantToWatch: item.status == .wantToWatch
        }
    }
}

struct LibraryFilterViewModel: Identifiable, Equatable {
    let filter: LibraryFilter
    let title: String
    let isSelected: Bool

    var id: String { filter.rawValue }
}

struct LibraryCardViewModel: Identifiable, Equatable {
    let id: String
    let title: String
    let posterURL: URL?
    let kindTitle: String
    let statusTitle: String
    let ratingSymbol: String?
    let accessibilityLabel: String
}

enum LibraryLayout {
    static let columnCount = 2
    static let cardWidth = MediaCardMetrics.cardWidth
    static let spacing: CGFloat = 10
    static let gridWidth = CGFloat(columnCount) * cardWidth + CGFloat(columnCount - 1) * spacing

    static func rows<Element>(_ items: [Element]) -> [[Element]] {
        stride(from: 0, to: items.count, by: columnCount).map { start in
            Array(items[start..<min(start + columnCount, items.count)])
        }
    }
}
