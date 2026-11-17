import Foundation

@MainActor
protocol LibraryPresentationLogic: AnyObject {
    func presentLibrary(_ response: Library.Load.Response)
}

@MainActor
protocol LibraryDisplayLogic: AnyObject {
    func displayLibrary(_ viewModel: Library.Load.ViewModel)
}

@MainActor
final class LibraryPresenter: LibraryPresentationLogic {
    private weak var display: LibraryDisplayLogic?
    private let localizer: Localizer

    init(display: LibraryDisplayLogic?, localizer: Localizer = .main) {
        self.display = display
        self.localizer = localizer
    }

    func presentLibrary(_ response: Library.Load.Response) {
        let cards = response.items.map(makeCard)
        let isFiltered = response.filter != .all
        let viewModel = Library.Load.ViewModel(
            cards: cards,
            emptyTitle: localizer.string(isFiltered ? "library.filter.empty.title" : "library.empty.title"),
            emptyMessage: localizer.string(isFiltered ? "library.filter.empty.message" : "library.empty.message"),
            errorMessage: response.didFail ? localizer.string("library.error.message") : nil,
            filters: LibraryFilter.allCases.map {
                LibraryFilterViewModel(filter: $0, title: localizer.string($0.localizationKey), isSelected: $0 == response.filter)
            }
        )
        display?.displayLibrary(viewModel)
    }

    private func makeCard(_ item: SavedItem) -> LibraryCardViewModel {
        let kindTitle = localizer.string(item.kind.localizationKey)
        let statusTitle = item.status.map { localizer.string($0.localizationKey) } ?? localizer.string("status.saved")
        var label = "\(item.title), \(kindTitle), \(statusTitle)"
        if let rating = item.rating {
            label += ", \(localizer.string(rating.localizationKey))"
        }
        return LibraryCardViewModel(
            id: item.key,
            title: item.title,
            posterURL: ImageURLBuilder.url(path: item.posterPath, size: .w342),
            kindTitle: kindTitle,
            statusTitle: statusTitle,
            ratingSymbol: item.rating?.symbolName,
            accessibilityLabel: label
        )
    }
}
