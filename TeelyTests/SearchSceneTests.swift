import XCTest
@testable import Teely

@MainActor
final class SearchPresenterSpy: SearchPresentationLogic {
    private(set) var loadingCount = 0
    private(set) var responses: [Search.Perform.Response] = []

    func presentLoading() { loadingCount += 1 }
    func presentResults(_ response: Search.Perform.Response) { responses.append(response) }
}

@MainActor
final class SearchRouterSpy: SearchRouting {
    private(set) var details: [(kind: MediaKind, id: Int)] = []

    func routeToDetail(kind: MediaKind, id: Int) { details.append((kind, id)) }
}

@MainActor
final class SearchDisplaySpy: SearchDisplayLogic {
    private(set) var states: [Search.State] = []

    func displayState(_ state: Search.State) { states.append(state) }
}

@MainActor
final class SearchInteractorTests: XCTestCase {
    private var service: MockMediaService!
    private var presenter: SearchPresenterSpy!
    private var router: SearchRouterSpy!

    private func makeInteractor(language: String = "en-US") -> SearchInteractor {
        SearchInteractor(service: service, presenter: presenter, router: router, languageProvider: { language })
    }

    override func setUp() {
        service = MockMediaService()
        presenter = SearchPresenterSpy()
        router = SearchRouterSpy()
    }

    func testSearchPresentsLoadingThenResults() async {
        service.searchResult = .success([Sample.summary()])
        await makeInteractor().search(.init(query: "teely"))
        XCTAssertEqual(presenter.loadingCount, 1)
        XCTAssertEqual(presenter.responses.last?.results.count, 1)
        XCTAssertNil(presenter.responses.last?.failure)
    }

    func testSearchUsesTheSelectedLanguage() async {
        for language in AppLanguage.supported {
            service = MockMediaService()
            await makeInteractor(language: language).search(.init(query: "teely"))
            XCTAssertEqual(service.searchCalls.last?.language, language)
            XCTAssertEqual(service.searchCalls.last?.query, "teely")
        }
    }

    func testNetworkFailure() async {
        service.searchResult = .failure(TMDBError.http(500))
        await makeInteractor().search(.init(query: "teely"))
        XCTAssertEqual(presenter.responses.last?.failure, .network)
    }

    func testMissingTokenFailure() async {
        service.searchResult = .failure(TMDBError.missingToken)
        await makeInteractor().search(.init(query: "teely"))
        XCTAssertEqual(presenter.responses.last?.failure, .missingToken)
    }

    func testSelectRoutesToDetail() async {
        service.searchResult = .success([Sample.summary(id: 5, kind: .tv, title: "Series")])
        let interactor = makeInteractor()
        await interactor.search(.init(query: "series"))
        interactor.select(.init(key: "tv-5"))
        XCTAssertEqual(router.details.first?.kind, .tv)
        XCTAssertEqual(router.details.first?.id, 5)
    }

    func testSelectUnknownKeyDoesNothing() async {
        let interactor = makeInteractor()
        await interactor.search(.init(query: "teely"))
        interactor.select(.init(key: "movie-1"))
        XCTAssertTrue(router.details.isEmpty)
    }

    func testFailureClearsPreviousResults() async {
        service.searchResult = .success([Sample.summary(id: 5)])
        let interactor = makeInteractor()
        await interactor.search(.init(query: "a"))
        service.searchResult = .failure(TMDBError.http(500))
        await interactor.search(.init(query: "b"))
        interactor.select(.init(key: "movie-5"))
        XCTAssertTrue(router.details.isEmpty)
    }
}

@MainActor
final class SearchPresenterTests: XCTestCase {
    private func makePresenter(_ code: String, display: SearchDisplaySpy) -> SearchPresenter {
        SearchPresenter(display: display, localizer: Localizer(bundle: languageBundle(code)))
    }

    func testLoadingState() {
        let display = SearchDisplaySpy()
        makePresenter("en", display: display).presentLoading()
        XCTAssertEqual(display.states.last, .loading)
    }

    func testResultsAreFormattedInEveryLanguage() throws {
        let kinds = ["en": "Movie", "pt-BR": "Filme", "es": "Película"]
        for (code, kind) in kinds {
            let display = SearchDisplaySpy()
            makePresenter(code, display: display).presentResults(
                .init(query: "q", results: [Sample.summary(id: 1, title: "Title")], failure: nil)
            )
            guard case .results(let rows) = try XCTUnwrap(display.states.last) else {
                return XCTFail("Expected results")
            }
            XCTAssertEqual(rows.first?.subtitle, "\(kind) · 2024")
            XCTAssertEqual(rows.first?.title, "Title")
            XCTAssertEqual(rows.first?.id, "movie-1")
            XCTAssertEqual(rows.first?.posterURL?.absoluteString, "https://image.tmdb.org/t/p/w185/poster.jpg")
        }
    }

    func testSubtitleWithoutYear() throws {
        let display = SearchDisplaySpy()
        let summary = MediaSummary(tmdbID: 1, kind: .tv, title: "Title")
        makePresenter("en", display: display).presentResults(.init(query: "q", results: [summary], failure: nil))
        guard case .results(let rows) = try XCTUnwrap(display.states.last) else {
            return XCTFail("Expected results")
        }
        XCTAssertEqual(rows.first?.subtitle, "Series")
    }

    func testEmptyResults() {
        let expected = [
            "en": "No results",
            "pt-BR": "Nenhum resultado",
            "es": "Sin resultados"
        ]
        for (code, title) in expected {
            let display = SearchDisplaySpy()
            makePresenter(code, display: display).presentResults(.init(query: "q", results: [], failure: nil))
            guard case .empty(let presented, _) = display.states.last else {
                return XCTFail("Expected empty state")
            }
            XCTAssertEqual(presented, title)
        }
    }

    func testFailureMessages() {
        let display = SearchDisplaySpy()
        let presenter = makePresenter("en", display: display)
        presenter.presentResults(.init(query: "q", results: [], failure: .network))
        presenter.presentResults(.init(query: "q", results: [], failure: .missingToken))
        guard case .failure(_, let network) = display.states[0], case .failure(_, let token) = display.states[1] else {
            return XCTFail("Expected failures")
        }
        XCTAssertEqual(network, "Check your connection and try again.")
        XCTAssertTrue(token.contains("TMDB_ACCESS_TOKEN"))
    }
}

@MainActor
final class SearchRouterTests: XCTestCase {
    func testPushesDetailRoute() {
        let navigator = SpyNavigator()
        SearchRouter(navigator: navigator).routeToDetail(kind: .movie, id: 11)
        XCTAssertEqual(navigator.pushed, [.detail(kind: .movie, id: 11)])
    }
}
