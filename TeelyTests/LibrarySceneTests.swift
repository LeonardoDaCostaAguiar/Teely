import XCTest
@testable import Teely

@MainActor
final class LibraryPresenterSpy: LibraryPresentationLogic {
    private(set) var responses: [Library.Load.Response] = []

    func presentLibrary(_ response: Library.Load.Response) {
        responses.append(response)
    }
}

@MainActor
final class LibraryRouterSpy: LibraryRouting {
    private(set) var searches: [String] = []
    private(set) var details: [(kind: MediaKind, id: Int)] = []

    func routeToSearch(query: String) { searches.append(query) }
    func routeToDetail(kind: MediaKind, id: Int) { details.append((kind, id)) }
}

@MainActor
final class LibraryDisplaySpy: LibraryDisplayLogic {
    private(set) var viewModels: [Library.Load.ViewModel] = []

    func displayLibrary(_ viewModel: Library.Load.ViewModel) {
        viewModels.append(viewModel)
    }
}

@MainActor
final class LibraryInteractorTests: XCTestCase {
    private var worker: InMemoryLibraryWorker!
    private var presenter: LibraryPresenterSpy!
    private var router: LibraryRouterSpy!
    private var interactor: LibraryInteractor!

    override func setUp() {
        worker = InMemoryLibraryWorker()
        presenter = LibraryPresenterSpy()
        router = LibraryRouterSpy()
        interactor = LibraryInteractor(worker: worker, presenter: presenter, router: router)
    }

    func testLoadPresentsSavedItems() throws {
        _ = try worker.save(Sample.detail(id: 1, title: "One"))
        _ = try worker.save(Sample.detail(id: 2, kind: .tv, title: "Two"))
        interactor.load(.init())
        let response = try XCTUnwrap(presenter.responses.last)
        XCTAssertEqual(response.items.map(\.title), ["One", "Two"])
        XCTAssertFalse(response.didFail)
    }

    func testLoadFailurePresentsEmptyFailedResponse() {
        worker.failsOnAll = true
        interactor.load(.init())
        XCTAssertEqual(presenter.responses.last?.items.count, 0)
        XCTAssertEqual(presenter.responses.last?.didFail, true)
    }

    func testSelectRoutesToDetailOfLoadedItem() throws {
        _ = try worker.save(Sample.detail(id: 7, kind: .tv, title: "Series"))
        interactor.load(.init())
        interactor.select(.init(key: "tv-7"))
        XCTAssertEqual(router.details.count, 1)
        XCTAssertEqual(router.details.first?.kind, .tv)
        XCTAssertEqual(router.details.first?.id, 7)
    }

    func testSelectUnknownKeyDoesNothing() {
        interactor.load(.init())
        interactor.select(.init(key: "movie-1"))
        XCTAssertTrue(router.details.isEmpty)
    }

    func testFilterPresentsOnlyMatchingItems() throws {
        let watched = try worker.save(Sample.detail(id: 1, title: "Watched"))
        watched.status = .watched
        let wanted = try worker.save(Sample.detail(id: 2, title: "Wanted"))
        wanted.status = .wantToWatch
        _ = try worker.save(Sample.detail(id: 3, title: "Unclassified"))
        interactor.load(.init())

        interactor.setFilter(.init(filter: .watched))
        XCTAssertEqual(presenter.responses.last?.items.map(\.title), ["Watched"])
        XCTAssertEqual(presenter.responses.last?.filter, .watched)

        interactor.setFilter(.init(filter: .wantToWatch))
        XCTAssertEqual(presenter.responses.last?.items.map(\.title), ["Wanted"])

        interactor.setFilter(.init(filter: .all))
        XCTAssertEqual(presenter.responses.last?.items.map(\.title), ["Watched", "Wanted", "Unclassified"])
    }

    func testFilterSurvivesReload() throws {
        let watched = try worker.save(Sample.detail(id: 1, title: "Watched"))
        watched.status = .watched
        _ = try worker.save(Sample.detail(id: 2, title: "Unclassified"))
        interactor.load(.init())
        interactor.setFilter(.init(filter: .watched))
        interactor.load(.init())
        XCTAssertEqual(presenter.responses.last?.items.map(\.title), ["Watched"])
        XCTAssertEqual(presenter.responses.last?.filter, .watched)
    }

    func testSelectWorksForItemsHiddenByTheFilter() throws {
        _ = try worker.save(Sample.detail(id: 7, title: "Unclassified"))
        interactor.load(.init())
        interactor.setFilter(.init(filter: .watched))
        interactor.select(.init(key: "movie-7"))
        XCTAssertEqual(router.details.first?.id, 7)
    }

    func testSearchRoutesWithTrimmedQuery() {
        interactor.search(.init(query: "  matrix  "))
        XCTAssertEqual(router.searches, ["matrix"])
    }

    func testBlankSearchDoesNotRoute() {
        interactor.search(.init(query: "   "))
        XCTAssertTrue(router.searches.isEmpty)
    }
}

@MainActor
final class LibraryPresenterTests: XCTestCase {
    func testCardsUseLocalizedKindAndStatusInEveryLanguage() throws {
        let expectations: [(String, String, String, String)] = [
            ("en", "Movie", "Watched", "Series"),
            ("pt-BR", "Filme", "Assistido", "Série"),
            ("es", "Película", "Visto", "Serie")
        ]
        for (code, movie, watched, series) in expectations {
            let display = LibraryDisplaySpy()
            let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle(code)))
            presenter.presentLibrary(
                .init(
                    items: [
                        Sample.item(id: 1, kind: .movie, status: .watched, rating: .liked),
                        Sample.item(id: 2, kind: .tv, status: .wantToWatch)
                    ],
                    didFail: false
                )
            )
            let cards = try XCTUnwrap(display.viewModels.last).cards
            XCTAssertEqual(cards[0].kindTitle, movie)
            XCTAssertEqual(cards[0].statusTitle, watched)
            XCTAssertEqual(cards[1].kindTitle, series)
            XCTAssertEqual(cards[0].ratingSymbol, "hand.thumbsup.fill")
            XCTAssertNil(cards[1].ratingSymbol)
        }
    }

    func testWantToWatchStatusIsLocalized() throws {
        let expected = ["en": "Want to watch", "pt-BR": "Quero assistir", "es": "Quiero ver"]
        for (code, title) in expected {
            let display = LibraryDisplaySpy()
            let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle(code)))
            presenter.presentLibrary(.init(items: [Sample.item(status: .wantToWatch)], didFail: false))
            XCTAssertEqual(display.viewModels.last?.cards.first?.statusTitle, title)
        }
    }

    func testUnclassifiedSavedCardHasNeutralStatus() throws {
        let expected = ["en": "Saved", "pt-BR": "Salvo", "es": "Guardado"]
        for (code, title) in expected {
            let display = LibraryDisplaySpy()
            let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle(code)))
            presenter.presentLibrary(.init(items: [Sample.item()], didFail: false))
            XCTAssertEqual(display.viewModels.last?.cards.first?.statusTitle, title)
        }
    }

    func testCardAccessibilityLabelAndPoster() throws {
        let display = LibraryDisplaySpy()
        let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle("en")))
        presenter.presentLibrary(.init(items: [Sample.item(title: "Title", status: .watched, rating: .disliked)], didFail: false))
        let card = try XCTUnwrap(display.viewModels.last?.cards.first)
        XCTAssertEqual(card.accessibilityLabel, "Title, Movie, Watched, Disliked")
        XCTAssertEqual(card.posterURL?.absoluteString, "https://image.tmdb.org/t/p/w342/poster.jpg")
        XCTAssertEqual(card.id, "movie-101")
    }

    func testFiltersAreLocalizedAndMarkSelection() throws {
        let expected = [
            "en": ["All", "Watched", "Want to watch"],
            "pt-BR": ["Todos", "Assistidos", "Quero assistir"],
            "es": ["Todos", "Vistos", "Quiero ver"]
        ]
        for (code, titles) in expected {
            let display = LibraryDisplaySpy()
            let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle(code)))
            presenter.presentLibrary(.init(items: [], didFail: false, filter: .watched))
            let filters = try XCTUnwrap(display.viewModels.last).filters
            XCTAssertEqual(filters.map(\.title), titles)
            XCTAssertEqual(filters.map(\.filter), [.all, .watched, .wantToWatch])
            XCTAssertEqual(filters.map(\.isSelected), [false, true, false])
        }
    }

    func testFilteredEmptyStateUsesFilterMessage() throws {
        let display = LibraryDisplaySpy()
        let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle("pt-BR")))
        presenter.presentLibrary(.init(items: [], didFail: false, filter: .wantToWatch))
        XCTAssertEqual(display.viewModels.last?.emptyTitle, "Nada por aqui ainda")
        presenter.presentLibrary(.init(items: [], didFail: false, filter: .all))
        XCTAssertEqual(display.viewModels.last?.emptyTitle, "Sua biblioteca está vazia")
    }

    func testFilterMatching() {
        let watched = Sample.item(status: .watched)
        let wanted = Sample.item(status: .wantToWatch)
        let unclassified = Sample.item()
        XCTAssertEqual([watched, wanted, unclassified].filter { LibraryFilter.all.matches($0) }.count, 3)
        XCTAssertEqual([watched, wanted, unclassified].filter { LibraryFilter.watched.matches($0) }, [watched])
        XCTAssertEqual([watched, wanted, unclassified].filter { LibraryFilter.wantToWatch.matches($0) }, [wanted])
    }

    func testEmptyLibraryProvidesLocalizedPlaceholder() throws {
        let display = LibraryDisplaySpy()
        let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle("pt-BR")))
        presenter.presentLibrary(.init(items: [], didFail: false))
        let viewModel = try XCTUnwrap(display.viewModels.last)
        XCTAssertTrue(viewModel.cards.isEmpty)
        XCTAssertEqual(viewModel.emptyTitle, "Sua biblioteca está vazia")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFailureProvidesErrorMessage() {
        let display = LibraryDisplaySpy()
        let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle("es")))
        presenter.presentLibrary(.init(items: [], didFail: true))
        XCTAssertEqual(display.viewModels.last?.errorMessage, "No se pudo cargar tu biblioteca.")
    }

    func testGridUsesHomeCardWidthAndTwoColumns() {
        XCTAssertEqual(LibraryLayout.columnCount, 2)
        XCTAssertEqual(LibraryLayout.cardWidth, MediaCardMetrics.cardWidth)
    }

    func testGridWidthIsTwoCardsAndOneGap() {
        XCTAssertEqual(LibraryLayout.gridWidth, MediaCardMetrics.cardWidth * 2 + LibraryLayout.spacing)
    }

    func testRowsGroupCardsByColumnCount() {
        XCTAssertEqual(LibraryLayout.rows([Int]()), [])
        XCTAssertEqual(LibraryLayout.rows([1]), [[1]])
        XCTAssertEqual(LibraryLayout.rows([1, 2]), [[1, 2]])
        XCTAssertEqual(LibraryLayout.rows([1, 2, 3]), [[1, 2], [3]])
        XCTAssertEqual(LibraryLayout.rows([1, 2, 3, 4, 5]), [[1, 2], [3, 4], [5]])
    }

    func testCardKeepsTheFullTitleForWrapping() throws {
        let display = LibraryDisplaySpy()
        let presenter = LibraryPresenter(display: display, localizer: Localizer(bundle: languageBundle("en")))
        let title = StubMediaService.longTitle
        presenter.presentLibrary(.init(items: [Sample.item(title: title)], didFail: false))
        let card = try XCTUnwrap(display.viewModels.last?.cards.first)
        XCTAssertEqual(card.title, title)
        XCTAssertTrue(card.accessibilityLabel.hasPrefix(title))
    }
}

@MainActor
final class LibraryRouterTests: XCTestCase {
    func testPushesSearchAndDetailRoutes() {
        let navigator = SpyNavigator()
        let router = LibraryRouter(navigator: navigator)
        router.routeToSearch(query: "matrix")
        router.routeToDetail(kind: .tv, id: 4)
        XCTAssertEqual(navigator.pushed, [.search("matrix"), .detail(kind: .tv, id: 4)])
    }
}

@MainActor
final class LibraryStoreTests: XCTestCase {
    func testStoreKeepsLatestViewModel() {
        let store = LibraryStore()
        let viewModel = Library.Load.ViewModel(cards: [], emptyTitle: "A", emptyMessage: "B", errorMessage: nil)
        store.displayLibrary(viewModel)
        XCTAssertEqual(store.viewModel, viewModel)
    }
}
