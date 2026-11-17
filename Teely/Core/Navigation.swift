import Foundation
import Observation

enum Route: Hashable {
    case search(String)
    case detail(kind: MediaKind, id: Int)
}

@MainActor
protocol Navigating: AnyObject {
    func push(_ route: Route)
    func pop()
    func popToRoot()
}

@MainActor
@Observable
final class AppRouter: Navigating {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
