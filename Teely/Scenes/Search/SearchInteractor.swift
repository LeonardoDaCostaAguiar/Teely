import Foundation

@MainActor
protocol SearchBusinessLogic: AnyObject {
    func search(_ request: Search.Perform.Request) async
    func select(_ request: Search.Select.Request)
}

@MainActor
final class SearchInteractor: SearchBusinessLogic {
    private let service: MediaServicing
    private let presenter: SearchPresentationLogic
    private let router: SearchRouting
    private let languageProvider: @Sendable () -> String
    private var results: [MediaSummary] = []

    init(
        service: MediaServicing,
        presenter: SearchPresentationLogic,
        router: SearchRouting,
        languageProvider: @escaping @Sendable () -> String
    ) {
        self.service = service
        self.presenter = presenter
        self.router = router
        self.languageProvider = languageProvider
    }

    func search(_ request: Search.Perform.Request) async {
        presenter.presentLoading()
        do {
            let found = try await service.search(query: request.query, language: languageProvider())
            results = found
            presenter.presentResults(Search.Perform.Response(query: request.query, results: found, failure: nil))
        } catch {
            results = []
            let failure: Search.Perform.Failure = (error as? TMDBError) == .missingToken ? .missingToken : .network
            presenter.presentResults(Search.Perform.Response(query: request.query, results: [], failure: failure))
        }
    }

    func select(_ request: Search.Select.Request) {
        guard let item = results.first(where: { $0.key == request.key }) else { return }
        router.routeToDetail(kind: item.kind, id: item.tmdbID)
    }
}
