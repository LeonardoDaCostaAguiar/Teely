import Foundation
import Observation

@MainActor
@Observable
final class LibraryStore: LibraryDisplayLogic {
    var viewModel = Library.Load.ViewModel(cards: [], emptyTitle: "", emptyMessage: "", errorMessage: nil)

    func displayLibrary(_ viewModel: Library.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

@MainActor
final class LibraryScene {
    let store: LibraryStore
    let interactor: LibraryBusinessLogic
    private let presenter: LibraryPresenter
    private let router: LibraryRouter

    init(environment: AppEnvironment, navigator: Navigating) {
        let store = LibraryStore()
        let presenter = LibraryPresenter(display: store)
        let router = LibraryRouter(navigator: navigator)
        self.store = store
        self.presenter = presenter
        self.router = router
        self.interactor = LibraryInteractor(worker: environment.worker, presenter: presenter, router: router)
    }
}
