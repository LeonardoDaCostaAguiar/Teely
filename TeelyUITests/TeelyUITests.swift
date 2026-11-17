import XCTest

final class TeelyUITests: XCTestCase {
    private var app: XCUIApplication!
    private let longTitle = "The Extraordinarily Long Title of a Movie Used to Verify Complete Text Wrapping on Cards"
    private let minimumCardHeight: CGFloat = 248

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(language: String = "en", locale: String = "en_US", trendingError: Bool = false, extendedDetails: Bool = false) {
        app.launchArguments = ["-uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        if trendingError { app.launchArguments.append("-trending-error") }
        if extendedDetails { app.launchArguments.append("-extended-details") }
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func openHome() {
        let tab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func openLibrary() {
        let tab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func search(_ text: String) {
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let clear = app.buttons["clearSearchButton"]
        if clear.exists { clear.tap() }
        field.tap()
        field.typeText("\(text)\n")
    }

    private func openResult(_ key: String) {
        let result = app.buttons["searchResult_\(key)"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
    }

    private func saveTitle(query: String, key: String) {
        openHome()
        search(query)
        openResult(key)
        let save = app.buttons["saveButton"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(app.buttons["watchedButton"].waitForExistence(timeout: 5))
    }

    private func goBackToLibrary() {
        var attempts = 0
        while attempts < 5 && app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 1) {
            app.navigationBars.buttons.firstMatch.tap()
            attempts += 1
        }
        openLibrary()
    }

    func testLogoAndEmptyLibraryAreShown() {
        launch()
        XCTAssertTrue(app.images["teelyLogo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Trending Movies"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Trending TV Shows"].exists)
        XCTAssertTrue(app.staticTexts["Powered by TMDB"].exists)
        XCTAssertFalse(app.staticTexts["This product uses the TMDB API but is not endorsed or certified by TMDB."].exists)
        XCTAssertLessThan(app.images["teelyLogo"].frame.minX, app.textFields["searchField"].frame.minX + 2)
        openLibrary()
        XCTAssertTrue(element("libraryEmpty").waitForExistence(timeout: 5) || element(containing: "Your library is empty").exists)
    }

    func testHomeShowsSeparateTrendingLists() {
        launch()
        XCTAssertTrue(app.buttons["trendingMovies_movie-101"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["trendingShows_tv-202"].exists)
    }

    func testTrendingErrorShowsCenteredMessageAndPoweredByFooter() {
        launch(trendingError: true)
        XCTAssertTrue(element("trendingFailure").waitForExistence(timeout: 5))
        XCTAssertTrue(element(containing: "Trending could not be loaded").exists)
        XCTAssertTrue(app.staticTexts["Powered by TMDB"].exists)
        XCTAssertFalse(app.staticTexts["This product uses the TMDB API but is not endorsed or certified by TMDB."].exists)
    }

    func testSearchShowsResults() {
        launch()
        search("teely")
        XCTAssertTrue(app.buttons["searchResult_movie-101"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["searchResult_tv-202"].exists)
        XCTAssertTrue(app.buttons["searchResult_movie-303"].exists)
    }

    func testSearchWithoutMatchesShowsEmptyState() {
        launch()
        search("zzzz")
        XCTAssertTrue(element(containing: "No results").waitForExistence(timeout: 5))
    }

    func testSaveTitleShowsStatusButtons() {
        launch()
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.buttons["saveButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["watchedButton"].exists)
        app.buttons["saveButton"].tap()
        XCTAssertTrue(app.buttons["watchedButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["wantToWatchButton"].exists)
        XCTAssertFalse(app.buttons["watchedButton"].isSelected)
        XCTAssertFalse(app.buttons["wantToWatchButton"].isSelected)
        XCTAssertFalse(app.buttons["saveButton"].exists)
        XCTAssertFalse(app.buttons["likeButton"].exists)
    }

    func testWatchedShowsRatingAndRatingCanBeChanged() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["watchedButton"].tap()
        XCTAssertTrue(app.buttons["likeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dislikeButton"].exists)
        app.buttons["likeButton"].tap()
        XCTAssertTrue(app.buttons["likeButton"].isSelected)
        app.buttons["dislikeButton"].tap()
        XCTAssertTrue(app.buttons["dislikeButton"].isSelected)
        XCTAssertFalse(app.buttons["likeButton"].isSelected)
    }

    func testWantToWatchHidesRating() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["watchedButton"].tap()
        XCTAssertTrue(app.buttons["likeButton"].waitForExistence(timeout: 5))
        app.buttons["wantToWatchButton"].tap()
        XCTAssertFalse(app.buttons["likeButton"].exists)
        XCTAssertFalse(app.buttons["dislikeButton"].exists)
    }

    func testSavedTitleAppearsInLibraryGridWithKindAndStatus() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["watchedButton"].tap()
        goBackToLibrary()
        let card = app.buttons["libraryCard_movie-101"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Movie"))
        XCTAssertTrue(card.label.contains("Watched"))
    }

    func testUnclassifiedSeriesCardShowsNeutralStatus() {
        launch()
        saveTitle(query: "teely series", key: "tv-202")
        goBackToLibrary()
        let card = app.buttons["libraryCard_tv-202"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Series"))
        XCTAssertTrue(card.label.contains("Saved"))
    }

    func testLibraryCardsMatchHomeCardSize() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        goBackToLibrary()
        saveTitle(query: "teely series", key: "tv-202")
        goBackToLibrary()
        let first = app.buttons["libraryCard_movie-101"]
        let second = app.buttons["libraryCard_tv-202"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        let screenWidth = app.windows.firstMatch.frame.width
        let firstFrame = first.frame
        let secondFrame = second.frame
        openHome()
        let homeCard = app.buttons["trendingMovies_movie-101"]
        XCTAssertTrue(homeCard.waitForExistence(timeout: 5))
        let homeFrame = homeCard.frame
        XCTAssertEqual(firstFrame.minY, secondFrame.minY, accuracy: 1)
        XCTAssertEqual(firstFrame.width, 148, accuracy: 2)
        XCTAssertLessThan(firstFrame.width, screenWidth / 2)
        XCTAssertEqual(firstFrame.width, secondFrame.width, accuracy: 1)
        XCTAssertEqual(homeFrame.width, firstFrame.width, accuracy: 2)
    }

    func testLibraryGridIsHorizontallyCentered() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        goBackToLibrary()
        saveTitle(query: "teely series", key: "tv-202")
        goBackToLibrary()
        let first = app.buttons["libraryCard_movie-101"]
        let second = app.buttons["libraryCard_tv-202"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        let screenWidth = app.windows.firstMatch.frame.width
        let left = min(first.frame.minX, second.frame.minX)
        let right = max(first.frame.maxX, second.frame.maxX)
        XCTAssertEqual((left + right) / 2, screenWidth / 2, accuracy: 2)
        XCTAssertEqual(left, screenWidth - right, accuracy: 2)
    }

    func testSplashShowsNameAndSloganThenOpensHome() {
        app.launchArguments = ["-uitesting", "-show-splash", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let slogan = element("splashSlogan")
        XCTAssertTrue(slogan.waitForExistence(timeout: 5))
        XCTAssertEqual(slogan.label, "Discover. Track. Watch")
        XCTAssertTrue(element("splashName").exists)
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: slogan)
        waitForExpectations(timeout: 8)
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5))
    }

    func testDetailsOfAMovieDoNotShowIMDbIDOrCollection() {
        launch(extendedDetails: true)
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.staticTexts["Release date"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["IMDb ID"].exists)
        XCTAssertFalse(app.staticTexts["Collection"].exists)
    }

    func testHomeCardsShowTheCompleteTitleByWrappingText() {
        launch()
        let longCard = app.buttons["trendingMovies_movie-404"]
        let shortCard = app.buttons["trendingMovies_movie-101"]
        XCTAssertTrue(longCard.waitForExistence(timeout: 5))
        XCTAssertTrue(shortCard.waitForExistence(timeout: 5))
        XCTAssertEqual(longCard.label, longTitle)
        XCTAssertGreaterThan(longCard.frame.height, minimumCardHeight + 20)
        XCTAssertEqual(shortCard.frame.height, longCard.frame.height, accuracy: 1)
    }

    func testLibraryCardsShowTheCompleteTitleByWrappingText() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        goBackToLibrary()
        saveTitle(query: "teely series", key: "tv-202")
        goBackToLibrary()
        saveTitle(query: "extraordinarily", key: "movie-404")
        goBackToLibrary()
        let longCard = app.buttons["libraryCard_movie-404"]
        let sameRowCard = app.buttons["libraryCard_tv-202"]
        let nextRowCard = app.buttons["libraryCard_movie-101"]
        XCTAssertTrue(longCard.waitForExistence(timeout: 5))
        XCTAssertTrue(sameRowCard.exists)
        XCTAssertTrue(nextRowCard.exists)
        XCTAssertTrue(longCard.label.hasPrefix(longTitle))
        XCTAssertEqual(longCard.frame.minY, sameRowCard.frame.minY, accuracy: 1)
        XCTAssertEqual(longCard.frame.height, sameRowCard.frame.height, accuracy: 1)
        XCTAssertGreaterThan(longCard.frame.height, nextRowCard.frame.height + 20)
        XCTAssertEqual(longCard.frame.width, 148, accuracy: 2)
    }

    func testLibraryFiltersByWatchStatus() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["watchedButton"].tap()
        goBackToLibrary()
        saveTitle(query: "teely series", key: "tv-202")
        app.buttons["wantToWatchButton"].tap()
        goBackToLibrary()
        let watchedCard = app.buttons["libraryCard_movie-101"]
        let wantedCard = app.buttons["libraryCard_tv-202"]
        XCTAssertTrue(watchedCard.waitForExistence(timeout: 5))
        XCTAssertTrue(wantedCard.exists)
        XCTAssertTrue(app.buttons["libraryFilter_all"].isSelected)

        app.buttons["libraryFilter_watched"].tap()
        XCTAssertTrue(app.buttons["libraryFilter_watched"].isSelected)
        XCTAssertTrue(watchedCard.waitForExistence(timeout: 5))
        XCTAssertFalse(wantedCard.exists)

        app.buttons["libraryFilter_wantToWatch"].tap()
        XCTAssertTrue(wantedCard.waitForExistence(timeout: 5))
        XCTAssertFalse(watchedCard.exists)

        app.buttons["libraryFilter_all"].tap()
        XCTAssertTrue(watchedCard.waitForExistence(timeout: 5))
        XCTAssertTrue(wantedCard.exists)
    }

    func testLibraryFilterWithoutMatchesShowsEmptyState() {
        launch()
        openLibrary()
        let filter = app.buttons["libraryFilter_watched"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        filter.tap()
        XCTAssertTrue(element(containing: "Nothing here yet").waitForExistence(timeout: 5))
    }

    func testDetailsShowCastProductionDataAndTrailerPlayer() {
        launch(extendedDetails: true)
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.staticTexts["Cast"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(containing: "Actor One").exists)
        XCTAssertTrue(app.staticTexts["Release date"].exists)
        XCTAssertFalse(app.staticTexts["Crew"].exists)
        XCTAssertFalse(app.staticTexts["Last air date"].exists)
        XCTAssertFalse(app.staticTexts["Series type"].exists)
        XCTAssertFalse(app.staticTexts["Website"].exists)
        XCTAssertFalse(app.staticTexts["Popularity"].exists)
        XCTAssertFalse(app.staticTexts["Votes"].exists)
        XCTAssertTrue(element("officialTrailerPlayer").waitForExistence(timeout: 5))
    }

    func testOpeningSavedCardShowsDetailWithSavedState() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        goBackToLibrary()
        app.buttons["libraryCard_movie-101"].tap()
        XCTAssertTrue(app.buttons["watchedButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveButton"].exists)
    }

    func testRemoveReturnsToEmptyLibrary() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["removeButton"].tap()
        let confirmButton = app.alerts.buttons.matching(identifier: "confirmRemoveButton").firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()
        XCTAssertTrue(app.buttons["searchResult_movie-101"].waitForExistence(timeout: 5))
        goBackToLibrary()
        XCTAssertFalse(app.buttons["libraryCard_movie-101"].exists)
    }

    func testCancelRemoveKeepsTitleInLibrary() {
        launch()
        saveTitle(query: "teely movie", key: "movie-101")
        app.buttons["removeButton"].tap()
        let cancelButton = app.alerts.buttons.matching(identifier: "cancelRemoveButton").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()
        XCTAssertTrue(app.buttons["watchedButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["removeButton"].exists)
        XCTAssertFalse(app.buttons["saveButton"].exists)
    }

    func testEnglishInterface() {
        launch(language: "en", locale: "en_US")
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["searchField"].placeholderValue, "Search movies and series")
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.buttons["saveButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["saveButton"].label, "Save to my Library")
        XCTAssertTrue(app.staticTexts["stub-overview-en-US"].exists)
    }

    func testPortugueseInterface() {
        launch(language: "pt-BR", locale: "pt_BR")
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["searchField"].placeholderValue, "Buscar filmes e séries")
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.buttons["saveButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["saveButton"].label, "Salvar em minha Biblioteca")
        XCTAssertTrue(app.staticTexts["stub-overview-pt-BR"].exists)
        app.buttons["saveButton"].tap()
        XCTAssertEqual(app.buttons["watchedButton"].label, "Assistido")
        XCTAssertEqual(app.buttons["wantToWatchButton"].label, "Quero assistir")
    }

    func testSpanishInterface() {
        launch(language: "es", locale: "es_ES")
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["searchField"].placeholderValue, "Buscar películas y series")
        search("teely movie")
        openResult("movie-101")
        XCTAssertTrue(app.buttons["saveButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["saveButton"].label, "Guardar en mi biblioteca")
        XCTAssertTrue(app.staticTexts["stub-overview-es-ES"].exists)
        app.buttons["saveButton"].tap()
        XCTAssertEqual(app.buttons["watchedButton"].label, "Visto")
        XCTAssertEqual(app.buttons["wantToWatchButton"].label, "Quiero ver")
    }

    func testUnclassifiedLibraryCardIsLocalizedInPortuguese() {
        launch(language: "pt-BR", locale: "pt_BR")
        saveTitle(query: "teely series", key: "tv-202")
        goBackToLibrary()
        let card = app.buttons["libraryCard_tv-202"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let localizedLabel = NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Série", "Salvo")
        expectation(for: localizedLabel, evaluatedWith: card)
        waitForExpectations(timeout: 5)
    }

    func testDarkModeLaunches() {
        app.launchArguments = ["-uitesting", "-AppleInterfaceStyle", "Dark"]
        app.launch()
        XCTAssertTrue(app.textFields["searchField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["teelyLogo"].exists)
    }
}
