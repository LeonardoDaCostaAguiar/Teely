import Foundation
import Observation

@MainActor
@Observable
final class DetailStore: DetailDisplayLogic {
    var state: Detail.State = .loading

    func displayState(_ state: Detail.State) {
        self.state = state
    }
}

@MainActor
final class DetailScene {
    let store: DetailStore
    let interactor: DetailBusinessLogic
    private let presenter: DetailPresenter
    private let router: DetailRouter

    init(environment: AppEnvironment, navigator: Navigating, kind: MediaKind, id: Int) {
        let store = DetailStore()
        let presenter = DetailPresenter(display: store)
        let router = DetailRouter(navigator: navigator)
        self.store = store
        self.presenter = presenter
        self.router = router
        self.interactor = DetailInteractor(
            kind: kind,
            id: id,
            service: environment.service,
            worker: environment.worker,
            presenter: presenter,
            router: router,
            languageProvider: environment.languageProvider
        )
    }
}
