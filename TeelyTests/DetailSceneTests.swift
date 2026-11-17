import XCTest
@testable import Teely

@MainActor
final class DetailPresenterSpy: DetailPresentationLogic {
    private(set) var loadingCount = 0
    private(set) var responses: [Detail.Response] = []
    private(set) var failures: [Detail.Failure] = []

    func presentLoading() { loadingCount += 1 }
    func presentContent(_ response: Detail.Response) { responses.append(response) }
    func presentFailure(_ failure: Detail.Failure) { failures.append(failure) }
}

@MainActor
final class DetailRouterSpy: DetailRouting {
    private(set) var backCount = 0

    func routeBack() { backCount += 1 }
}

@MainActor
final class DetailDisplaySpy: DetailDisplayLogic {
    private(set) var states: [Detail.State] = []

    func displayState(_ state: Detail.State) { states.append(state) }
}

@MainActor
final class DetailInteractorTests: XCTestCase {
    private var service: MockMediaService!
    private var worker: InMemoryLibraryWorker!
    private var presenter: DetailPresenterSpy!
    private var router: DetailRouterSpy!
    private var interactor: DetailInteractor!

    override func setUp() {
        service = MockMediaService()
        worker = InMemoryLibraryWorker()
        presenter = DetailPresenterSpy()
        router = DetailRouterSpy()
        interactor = DetailInteractor(
            kind: .movie,
            id: 101,
            service: service,
            worker: worker,
            presenter: presenter,
            router: router,
            languageProvider: { "pt-BR" }
        )
    }

    func testLoadPresentsDetailNotSaved() async {
        await interactor.load(.init())
        XCTAssertEqual(presenter.loadingCount, 1)
        XCTAssertNil(presenter.responses.last?.saved)
        XCTAssertEqual(presenter.responses.last?.detail.title, "Teely Movie")
    }

    func testLoadUsesSelectedLanguage() async {
        await interactor.load(.init())
        XCTAssertEqual(service.detailCalls.last?.language, "pt-BR")
        XCTAssertEqual(service.detailCalls.last?.id, 101)
        XCTAssertEqual(service.detailCalls.last?.kind, .movie)
    }

    func testLoadFailureWithoutSavedItemPresentsFailure() async {
        service.detailResult = .failure(TMDBError.http(500))
        await interactor.load(.init())
        XCTAssertEqual(presenter.failures, [.network])
    }

    func testLoadMissingTokenFailure() async {
        service.detailResult = .failure(TMDBError.missingToken)
        await interactor.load(.init())
        XCTAssertEqual(presenter.failures, [.missingToken])
    }

    func testLoadFailureFallsBackToSavedItem() async throws {
        _ = try worker.save(Sample.detail())
        service.detailResult = .failure(TMDBError.http(500))
        await interactor.load(.init())
        XCTAssertTrue(presenter.failures.isEmpty)
        XCTAssertEqual(presenter.responses.last?.detail.title, "Teely Movie")
        XCTAssertNotNil(presenter.responses.last?.saved)
    }

    func testSaveStoresAndPresentsSavedState() async {
        await interactor.load(.init())
        interactor.save(.init())
        XCTAssertEqual(worker.items.count, 1)
        XCTAssertNil(presenter.responses.last?.saved?.status)
    }

    func testSaveBeforeLoadDoesNothing() {
        interactor.save(.init())
        XCTAssertTrue(worker.items.isEmpty)
    }

    func testSetStatusRequiresSavedItem() async {
        await interactor.load(.init())
        interactor.setStatus(.init(status: .watched))
        XCTAssertTrue(worker.items.isEmpty)
        XCTAssertNil(presenter.responses.last?.saved)
    }

    func testSetStatusWatched() async {
        await interactor.load(.init())
        interactor.save(.init())
        interactor.setStatus(.init(status: .watched))
        XCTAssertEqual(presenter.responses.last?.saved?.status, .watched)
    }

    func testRatingRequiresWatchedStatus() async {
        await interactor.load(.init())
        interactor.save(.init())
        interactor.setRating(.init(rating: .liked))
        XCTAssertNil(presenter.responses.last?.saved?.rating)
    }

    func testRatingAndToggle() async {
        await interactor.load(.init())
        interactor.save(.init())
        interactor.setStatus(.init(status: .watched))
        interactor.setRating(.init(rating: .liked))
        XCTAssertEqual(presenter.responses.last?.saved?.rating, .liked)
        interactor.setRating(.init(rating: .disliked))
        XCTAssertEqual(presenter.responses.last?.saved?.rating, .disliked)
        interactor.setRating(.init(rating: .disliked))
        XCTAssertNil(presenter.responses.last?.saved?.rating)
    }

    func testWantToWatchClearsRating() async {
        await interactor.load(.init())
        interactor.save(.init())
        interactor.setStatus(.init(status: .watched))
        interactor.setRating(.init(rating: .liked))
        interactor.setStatus(.init(status: .wantToWatch))
        XCTAssertNil(presenter.responses.last?.saved?.rating)
        XCTAssertEqual(presenter.responses.last?.saved?.status, .wantToWatch)
    }

    func testRemoveDeletesAndRoutesBack() async {
        await interactor.load(.init())
        interactor.save(.init())
        interactor.remove(.init())
        XCTAssertTrue(worker.items.isEmpty)
        XCTAssertEqual(router.backCount, 1)
    }

    func testRemoveWithoutSavedItemDoesNothing() async {
        await interactor.load(.init())
        interactor.remove(.init())
        XCTAssertEqual(router.backCount, 0)
    }

    func testSavedStateIsPresentedOnLoad() async throws {
        let saved = try worker.save(Sample.detail())
        saved.status = .watched
        saved.rating = .liked
        await interactor.load(.init())
        XCTAssertEqual(presenter.responses.last?.saved?.rating, .liked)
    }
}

@MainActor
final class DetailPresenterTests: XCTestCase {
    private func present(
        _ response: Detail.Response,
        language: String = "en"
    ) throws -> Detail.ViewModel {
        let display = DetailDisplaySpy()
        DetailPresenter(display: display, localizer: Localizer(bundle: languageBundle(language))).presentContent(response)
        guard case .content(let viewModel) = try XCTUnwrap(display.states.last) else {
            XCTFail("Expected content")
            throw TestError.unexpectedState
        }
        return viewModel
    }

    func testMovieMetadataInEveryLanguage() throws {
        let expected = [
            "en": "Movie · 2024 · 120 min",
            "pt-BR": "Filme · 2024 · 120 min",
            "es": "Película · 2024 · 120 min"
        ]
        for (code, metadata) in expected {
            let viewModel = try present(.init(detail: Sample.detail(), saved: nil), language: code)
            XCTAssertEqual(viewModel.metadata, metadata)
        }
    }

    func testSeriesMetadataPluralization() throws {
        let many = try present(.init(detail: Sample.detail(id: 2, kind: .tv, title: "S"), saved: nil), language: "pt-BR")
        XCTAssertEqual(many.metadata, "Série · 2024 · 3 temporadas")
        var single = Sample.detail(id: 2, kind: .tv, title: "S")
        single.seasons = 1
        let one = try present(.init(detail: single, saved: nil), language: "es")
        XCTAssertEqual(one.metadata, "Serie · 2024 · 1 temporada")
    }

    func testOverviewFallbackWhenEmpty() throws {
        var detail = Sample.detail()
        detail.overview = "   "
        let expected = [
            "en": "No overview available.",
            "pt-BR": "Nenhuma sinopse disponível.",
            "es": "No hay sinopsis disponible."
        ]
        for (code, message) in expected {
            let viewModel = try present(.init(detail: detail, saved: nil), language: code)
            XCTAssertEqual(viewModel.overview, message)
        }
    }

    func testScoreGenresAndPoster() throws {
        let viewModel = try present(.init(detail: Sample.detail(), saved: nil))
        XCTAssertEqual(viewModel.scoreText, "TMDB 7.8")
        XCTAssertEqual(viewModel.genres, "Drama, Comedy")
        XCTAssertEqual(viewModel.posterURL?.absoluteString, "https://image.tmdb.org/t/p/w500/poster.jpg")
        XCTAssertEqual(viewModel.tagline, "A tagline")
    }

    func testPresenterForwardsExtendedInformationAndOfficialTrailer() throws {
        var detail = Sample.detail()
        detail.releaseDate = "2024-04-05"
        detail.cast = [MediaCastMember(id: 11, name: "Actor One", character: "Hero", profilePath: "/actor.jpg", order: 0)]
        detail.officialTrailer = MediaTrailer(key: "official-key", name: "Official trailer", site: "YouTube", language: "en")
        let viewModel = try present(.init(detail: detail, saved: nil))
        XCTAssertEqual(viewModel.cast.first?.name, "Actor One")
        XCTAssertEqual(viewModel.officialTrailer?.key, "official-key")
        XCTAssertTrue(viewModel.facts.contains { $0.title == "Release date" && $0.value == "2024-04-05" })
    }

    func testPresenterOmitsRemovedMoreInformationFields() throws {
        var detail = Sample.detail()
        detail.lastAirDate = "2024-05-01"
        detail.seriesType = "Scripted"
        detail.homepage = URL(string: "https://example.org")
        detail.popularity = 99
        detail.voteCount = 123
        let viewModel = try present(.init(detail: detail, saved: nil), language: "en")
        let titles = Set(viewModel.facts.map(\.title))
        XCTAssertFalse(titles.contains("Last air date"))
        XCTAssertFalse(titles.contains("Series type"))
        XCTAssertFalse(titles.contains("Website"))
        XCTAssertFalse(titles.contains("Popularity"))
        XCTAssertFalse(titles.contains("Votes"))
    }

    func testPresenterNeverShowsIMDbIDOrCollectionInAnyLanguage() throws {
        for language in ["en", "pt-BR", "es"] {
            let viewModel = try present(.init(detail: Sample.detail(), saved: nil), language: language)
            let ids = Set(viewModel.facts.map(\.id))
            XCTAssertFalse(ids.contains("imdb"))
            XCTAssertFalse(ids.contains("collection"))
        }
    }

    func testMissingScoreAndGenres() throws {
        var detail = Sample.detail()
        detail.voteAverage = 0
        detail.genres = []
        let viewModel = try present(.init(detail: detail, saved: nil))
        XCTAssertNil(viewModel.scoreText)
        XCTAssertNil(viewModel.genres)
    }

    func testUnsavedState() throws {
        let viewModel = try present(.init(detail: Sample.detail(), saved: nil))
        XCTAssertFalse(viewModel.isSaved)
        XCTAssertNil(viewModel.status)
        XCTAssertFalse(viewModel.showsRatingControls)
    }

    func testWantToWatchHidesRatingControls() throws {
        let viewModel = try present(.init(detail: Sample.detail(), saved: Sample.item(status: .wantToWatch)))
        XCTAssertTrue(viewModel.isSaved)
        XCTAssertEqual(viewModel.status, .wantToWatch)
        XCTAssertFalse(viewModel.showsRatingControls)
        XCTAssertNil(viewModel.rating)
    }

    func testWatchedShowsRatingControls() throws {
        let viewModel = try present(.init(detail: Sample.detail(), saved: Sample.item(status: .watched, rating: .liked)))
        XCTAssertTrue(viewModel.showsRatingControls)
        XCTAssertEqual(viewModel.rating, .liked)
    }

    func testLoadingAndFailureStates() {
        let display = DetailDisplaySpy()
        let presenter = DetailPresenter(display: display, localizer: Localizer(bundle: languageBundle("es")))
        presenter.presentLoading()
        presenter.presentFailure(.network)
        presenter.presentFailure(.missingToken)
        XCTAssertEqual(display.states[0], .loading)
        guard case .failure(let title, let network) = display.states[1], case .failure(_, let token) = display.states[2] else {
            return XCTFail("Expected failures")
        }
        XCTAssertEqual(title, "No se pudieron cargar los detalles")
        XCTAssertEqual(network, "Revisa tu conexión e inténtalo de nuevo.")
        XCTAssertTrue(token.contains("TMDB_ACCESS_TOKEN"))
    }
}

@MainActor
final class DetailRouterTests: XCTestCase {
    func testRouteBackPopsNavigation() {
        let navigator = SpyNavigator()
        DetailRouter(navigator: navigator).routeBack()
        XCTAssertEqual(navigator.popCount, 1)
    }
}

@MainActor
final class AppRouterTests: XCTestCase {
    func testPushPopAndPopToRoot() {
        let router = AppRouter()
        router.push(.search("a"))
        router.push(.detail(kind: .movie, id: 1))
        XCTAssertEqual(router.path.count, 2)
        router.pop()
        XCTAssertEqual(router.path, [.search("a")])
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }
}

@MainActor
final class AppEnvironmentTests: XCTestCase {
    func testUITestingEnvironmentUsesStubAndInMemoryStorage() async throws {
        let environment = AppEnvironment.make(arguments: ["-uitesting"])
        XCTAssertTrue(environment.service is StubMediaService)
        XCTAssertTrue(try environment.worker.all().isEmpty)
        let results = try await environment.service.search(query: "teely", language: "en-US")
        XCTAssertEqual(results.count, 3)
    }

    func testSplashIsSkippedInUITestingUnlessRequested() {
        XCTAssertFalse(AppEnvironment.make(arguments: ["-uitesting"]).showsSplash)
        XCTAssertTrue(AppEnvironment.make(arguments: ["-uitesting", "-show-splash"]).showsSplash)
    }

    func testConfigurationTokenIsTrimmed() {
        XCTAssertEqual(AppConfiguration.tmdbAccessToken, AppConfiguration.tmdbAccessToken.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
