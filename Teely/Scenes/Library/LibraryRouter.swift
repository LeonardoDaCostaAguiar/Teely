import Foundation

@MainActor
protocol LibraryRouting: AnyObject {
    func routeToSearch(query: String)
    func routeToDetail(kind: MediaKind, id: Int)
}

@MainActor
final class LibraryRouter: LibraryRouting {
    private weak var navigator: Navigating?

    init(navigator: Navigating?) {
        self.navigator = navigator
    }

    func routeToSearch(query: String) {
        navigator?.push(.search(query))
    }

    func routeToDetail(kind: MediaKind, id: Int) {
        navigator?.push(.detail(kind: kind, id: id))
    }
}
