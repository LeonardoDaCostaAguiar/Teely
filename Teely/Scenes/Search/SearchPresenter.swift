import Foundation

@MainActor
protocol SearchPresentationLogic: AnyObject {
    func presentLoading()
    func presentResults(_ response: Search.Perform.Response)
}

@MainActor
protocol SearchDisplayLogic: AnyObject {
    func displayState(_ state: Search.State)
}

@MainActor
final class SearchPresenter: SearchPresentationLogic {
    private weak var display: SearchDisplayLogic?
    private let localizer: Localizer

    init(display: SearchDisplayLogic?, localizer: Localizer = .main) {
        self.display = display
        self.localizer = localizer
    }

    func presentLoading() {
        display?.displayState(.loading)
    }

    func presentResults(_ response: Search.Perform.Response) {
        if let failure = response.failure {
            let message = failure == .missingToken
                ? localizer.string("error.missingToken.message")
                : localizer.string("search.error.message")
            display?.displayState(.failure(title: localizer.string("search.error.title"), message: message))
            return
        }
        guard !response.results.isEmpty else {
            display?.displayState(
                .empty(
                    title: localizer.string("search.noResults.title"),
                    message: localizer.string("search.noResults.message")
                )
            )
            return
        }
        display?.displayState(.results(response.results.map(makeRow)))
    }

    private func makeRow(_ item: MediaSummary) -> SearchRowViewModel {
        let kindTitle = localizer.string(item.kind.localizationKey)
        let subtitle = item.releaseYear.map { "\(kindTitle) · \($0)" } ?? kindTitle
        return SearchRowViewModel(
            id: item.key,
            title: item.title,
            subtitle: subtitle,
            overview: item.overview,
            posterURL: ImageURLBuilder.url(path: item.posterPath, size: .w185),
            accessibilityLabel: "\(item.title), \(subtitle)"
        )
    }
}
