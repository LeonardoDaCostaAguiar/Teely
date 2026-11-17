import Foundation

@MainActor
protocol SearchRouting: AnyObject {
    func routeToDetail(kind: MediaKind, id: Int)
}

@MainActor
final class SearchRouter: SearchRouting {
    private weak var navigator: Navigating?

    init(navigator: Navigating?) {
        self.navigator = navigator
    }

    func routeToDetail(kind: MediaKind, id: Int) {
        navigator?.push(.detail(kind: kind, id: id))
    }
}
