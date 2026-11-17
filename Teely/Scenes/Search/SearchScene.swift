import Foundation
import Observation

@MainActor
@Observable
final class SearchStore: SearchDisplayLogic {
    var state: Search.State = .loading

    func displayState(_ state: Search.State) {
        self.state = state
    }
}

@MainActor
final class SearchScene {
    let store: SearchStore
    let interactor: SearchBusinessLogic
    private let presenter: SearchPresenter
    private let router: SearchRouter

    init(environment: AppEnvironment, navigator: Navigating) {
        let store = SearchStore()
        let presenter = SearchPresenter(display: store)
        let router = SearchRouter(navigator: navigator)
        self.store = store
        self.presenter = presenter
        self.router = router
        self.interactor = SearchInteractor(
            service: environment.service,
            presenter: presenter,
            router: router,
            languageProvider: environment.languageProvider
        )
    }
}
