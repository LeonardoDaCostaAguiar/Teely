import Foundation

@MainActor
protocol DetailRouting: AnyObject {
    func routeBack()
}

@MainActor
final class DetailRouter: DetailRouting {
    private weak var navigator: Navigating?

    init(navigator: Navigating?) {
        self.navigator = navigator
    }

    func routeBack() {
        navigator?.pop()
    }
}
