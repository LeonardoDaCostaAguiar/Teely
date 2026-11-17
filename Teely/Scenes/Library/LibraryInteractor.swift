import Foundation

@MainActor
protocol LibraryBusinessLogic: AnyObject {
    func load(_ request: Library.Load.Request)
    func select(_ request: Library.Select.Request)
    func search(_ request: Library.Search.Request)
    func setFilter(_ request: Library.SetFilter.Request)
}

@MainActor
final class LibraryInteractor: LibraryBusinessLogic {
    private let worker: LibraryWorking
    private let presenter: LibraryPresentationLogic
    private let router: LibraryRouting
    private var items: [SavedItem] = []
    private var filter: LibraryFilter = .all
    private var didFail = false

    init(worker: LibraryWorking, presenter: LibraryPresentationLogic, router: LibraryRouting) {
        self.worker = worker
        self.presenter = presenter
        self.router = router
    }

    func load(_ request: Library.Load.Request) {
        do {
            items = try worker.all().map { SavedItem($0) }
            didFail = false
        } catch {
            items = []
            didFail = true
        }
        present()
    }

    func setFilter(_ request: Library.SetFilter.Request) {
        filter = request.filter
        present()
    }

    private func present() {
        let visible = items.filter { filter.matches($0) }
        presenter.presentLibrary(Library.Load.Response(items: visible, didFail: didFail, filter: filter))
    }

    func select(_ request: Library.Select.Request) {
        guard let item = items.first(where: { $0.key == request.key }) else { return }
        router.routeToDetail(kind: item.kind, id: item.tmdbID)
    }

    func search(_ request: Library.Search.Request) {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        router.routeToSearch(query: query)
    }
}
