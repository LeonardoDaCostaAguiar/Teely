import UIKit
import WebKit
import XCTest
@testable import Teely

final class AppLanguageTests: XCTestCase {
    func testPortugueseMapsToBrazilianPortuguese() {
        XCTAssertEqual(AppLanguage.tmdbCode(for: "pt-BR"), "pt-BR")
        XCTAssertEqual(AppLanguage.tmdbCode(for: "pt"), "pt-BR")
        XCTAssertEqual(AppLanguage.tmdbCode(for: "pt-PT"), "pt-BR")
    }

    func testSpanishMapsToSpain() {
        XCTAssertEqual(AppLanguage.tmdbCode(for: "es"), "es-ES")
        XCTAssertEqual(AppLanguage.tmdbCode(for: "es-MX"), "es-ES")
    }

    func testEnglishAndUnknownMapToUnitedStates() {
        XCTAssertEqual(AppLanguage.tmdbCode(for: "en"), "en-US")
        XCTAssertEqual(AppLanguage.tmdbCode(for: "en-GB"), "en-US")
        XCTAssertEqual(AppLanguage.tmdbCode(for: "fr"), "en-US")
        XCTAssertEqual(AppLanguage.tmdbCode(for: ""), "en-US")
    }

    func testCurrentIsSupported() {
        XCTAssertTrue(AppLanguage.supported.contains(AppLanguage.current))
    }
}

final class PaletteTests: XCTestCase {
    func testLightPalette() {
        XCTAssertEqual(Palette.backgroundLight, 0xEAE9F3)
        XCTAssertEqual(Palette.surfaceLight, 0xF5F3FF)
        XCTAssertEqual(Palette.accentLight, 0x7057C5)
        XCTAssertEqual(Palette.primaryTextLight, 0x20232D)
        XCTAssertEqual(Palette.secondaryTextLight, 0x5F6678)
        XCTAssertEqual(Palette.highlightLight, 0xFFFFFF)
        XCTAssertEqual(Palette.shadeLight, 0xC6C5D4)
    }

    func testDarkPalette() {
        XCTAssertEqual(Palette.backgroundDark, 0x20232D)
        XCTAssertEqual(Palette.surfaceDark, 0x2C3040)
        XCTAssertEqual(Palette.accentDark, 0xB9A5FF)
        XCTAssertEqual(Palette.primaryTextDark, 0xF5F3FF)
        XCTAssertEqual(Palette.secondaryTextDark, 0x9298AA)
        XCTAssertEqual(Palette.highlightDark, 0x383D50)
        XCTAssertEqual(Palette.shadeDark, 0x171A23)
    }

    func testDynamicColorResolvesPerInterfaceStyle() {
        let color = UIColor.dynamic(light: Palette.backgroundLight, dark: Palette.backgroundDark)
        let light = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertEqual(light, UIColor(hex: Palette.backgroundLight))
        XCTAssertEqual(dark, UIColor(hex: Palette.backgroundDark))
    }
}

final class ModelTests: XCTestCase {
    func testMediaKeyCombinesKindAndIdentifier() {
        XCTAssertEqual(MediaKey.make(kind: .movie, id: 5), "movie-5")
        XCTAssertEqual(MediaKey.make(kind: .tv, id: 5), "tv-5")
    }

    func testYearParsing() {
        XCTAssertEqual(DateParsing.year(from: "2021-05-01"), 2021)
        XCTAssertNil(DateParsing.year(from: ""))
        XCTAssertNil(DateParsing.year(from: nil))
        XCTAssertNil(DateParsing.year(from: "abc"))
        XCTAssertNil(DateParsing.year(from: "0001-01-01"))
    }

    func testRatingSymbols() {
        XCTAssertEqual(MediaRating.liked.symbolName, "hand.thumbsup.fill")
        XCTAssertEqual(MediaRating.disliked.symbolName, "hand.thumbsdown.fill")
        XCTAssertEqual(MediaRating.liked.outlineSymbolName, "hand.thumbsup")
        XCTAssertEqual(MediaRating.disliked.outlineSymbolName, "hand.thumbsdown")
    }

    func testLocalizationKeys() {
        XCTAssertEqual(MediaKind.movie.localizationKey, "kind.movie")
        XCTAssertEqual(MediaKind.tv.localizationKey, "kind.tv")
        XCTAssertEqual(WatchStatus.watched.localizationKey, "status.watched")
        XCTAssertEqual(WatchStatus.wantToWatch.localizationKey, "status.wantToWatch")
        XCTAssertEqual(MediaRating.liked.localizationKey, "rating.liked")
        XCTAssertEqual(MediaRating.disliked.localizationKey, "rating.disliked")
    }

    func testSummaryIdentifierUsesKey() {
        let movie = Sample.summary(id: 7, kind: .movie)
        let series = Sample.summary(id: 7, kind: .tv)
        XCTAssertNotEqual(movie.id, series.id)
        XCTAssertEqual(movie.id, "movie-7")
    }

    @MainActor
    func testSavedMediaStartsWithoutWatchStatus() {
        let saved = SavedMedia(detail: Sample.detail())
        XCTAssertNil(saved.status)
        XCTAssertNil(saved.rating)
        XCTAssertEqual(saved.key, "movie-101")
        XCTAssertEqual(saved.kind, .movie)
    }

    @MainActor
    func testRatingOnlyAppliesWhenWatched() {
        let saved = SavedMedia(detail: Sample.detail())
        saved.rating = .liked
        XCTAssertNil(saved.rating)
        saved.status = .watched
        saved.rating = .liked
        XCTAssertEqual(saved.rating, .liked)
    }

    @MainActor
    func testChangingStatusToWantToWatchClearsRating() {
        let saved = SavedMedia(detail: Sample.detail())
        saved.status = .watched
        saved.rating = .disliked
        saved.status = .wantToWatch
        XCTAssertNil(saved.rating)
    }

    @MainActor
    func testSavedItemMirrorsSavedMedia() {
        let saved = SavedMedia(detail: Sample.detail(id: 9, kind: .tv, title: "Series"))
        saved.status = .watched
        saved.rating = .liked
        let item = SavedItem(saved)
        XCTAssertEqual(item.key, "tv-9")
        XCTAssertEqual(item.kind, .tv)
        XCTAssertEqual(item.title, "Series")
        XCTAssertEqual(item.status, .watched)
        XCTAssertEqual(item.rating, .liked)
    }

    func testDetailFromSavedItem() {
        let detail = MediaDetail(saved: Sample.item(id: 3, kind: .tv, title: "Series"))
        XCTAssertEqual(detail.tmdbID, 3)
        XCTAssertEqual(detail.kind, .tv)
        XCTAssertEqual(detail.title, "Series")
    }
}

final class LocalizerTests: XCTestCase {
    func testReturnsKeyWhenMissing() {
        let localizer = Localizer(bundle: languageBundle("en"))
        XCTAssertEqual(localizer.string("does.not.exist"), "does.not.exist")
    }

    func testFormatsArguments() {
        let localizer = Localizer(bundle: languageBundle("en"))
        XCTAssertEqual(localizer.string("detail.runtime", 120), "120 min")
        XCTAssertEqual(localizer.string("detail.score", "7.8"), "TMDB 7.8")
    }
}

final class TrailerPlayerTests: XCTestCase {
    private let origin = URL(string: "https://com.leonardoaguiar.teely")!

    func testYouTubeEmbedPlaysInlineAndCarriesOrigin() throws {
        let trailer = MediaTrailer(key: "abc123", name: "Trailer", site: "YouTube", language: "en")
        let url = try XCTUnwrap(trailer.embedURL(origin: origin))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(components.host, "www.youtube-nocookie.com")
        XCTAssertEqual(components.path, "/embed/abc123")
        XCTAssertEqual(items["playsinline"], "1")
        XCTAssertEqual(items["rel"], "0")
        XCTAssertEqual(items["origin"], origin.absoluteString)
    }

    func testEmbedURLWithoutOriginOmitsOriginParameter() throws {
        let trailer = MediaTrailer(key: "abc123", name: "Trailer", site: "youtube", language: nil)
        let url = try XCTUnwrap(trailer.embedURL)
        XCTAssertFalse(url.absoluteString.contains("origin="))
        XCTAssertTrue(url.absoluteString.contains("playsinline=1"))
    }

    func testVimeoEmbedPlaysInline() throws {
        let trailer = MediaTrailer(key: "98765", name: "Trailer", site: "Vimeo", language: nil)
        let url = try XCTUnwrap(trailer.embedURL(origin: origin))
        XCTAssertEqual(url.host, "player.vimeo.com")
        XCTAssertEqual(url.path, "/video/98765")
        XCTAssertTrue(url.absoluteString.contains("playsinline=1"))
    }

    func testUnsupportedSiteHasNoEmbed() {
        let trailer = MediaTrailer(key: "x", name: "Trailer", site: "Dailymotion", language: nil)
        XCTAssertNil(trailer.embedURL)
        XCTAssertNil(trailer.embedURL(origin: origin))
    }

    func testOriginIsDerivedFromBundleIdentifier() {
        XCTAssertEqual(TrailerPlayerDocument.origin(bundleIdentifier: "com.leonardoaguiar.Teely"), origin)
        XCTAssertEqual(TrailerPlayerDocument.origin(bundleIdentifier: nil).absoluteString, "https://teely.app")
        XCTAssertEqual(TrailerPlayerDocument.origin(bundleIdentifier: "").absoluteString, "https://teely.app")
    }

    func testDocumentEmbedsThePlayerInsideThePage() throws {
        let trailer = MediaTrailer(key: "abc123", name: "Trailer", site: "YouTube", language: "en")
        let url = try XCTUnwrap(trailer.embedURL(origin: origin))
        let html = TrailerPlayerDocument.html(embedURL: url, title: "Official trailer")
        XCTAssertTrue(html.contains("<iframe"))
        XCTAssertTrue(html.contains("allowfullscreen"))
        XCTAssertTrue(html.contains("referrerpolicy=\"strict-origin-when-cross-origin\""))
        XCTAssertTrue(html.contains("src=\"https://www.youtube-nocookie.com/embed/abc123?playsinline=1&amp;rel=0&amp;origin="))
        XCTAssertTrue(html.contains("title=\"Official trailer\""))
    }

    func testDocumentEscapesTitle() throws {
        let url = try XCTUnwrap(URL(string: "https://player.vimeo.com/video/1"))
        let html = TrailerPlayerDocument.html(embedURL: url, title: "A \"quoted\" <title>")
        XCTAssertTrue(html.contains("title=\"A &quot;quoted&quot; &lt;title&gt;\""))
    }

    func testLinkTapsAreCancelledSoPlaybackStaysInTheApp() {
        XCTAssertEqual(TrailerPlayerView.Coordinator.policy(for: .linkActivated), .cancel)
        XCTAssertEqual(TrailerPlayerView.Coordinator.policy(for: .other), .allow)
        XCTAssertEqual(TrailerPlayerView.Coordinator.policy(for: .reload), .allow)
    }
}

final class MediaCardMetricsTests: XCTestCase {
    func testCardIsWideEnoughForPosterAndPadding() {
        XCTAssertEqual(
            MediaCardMetrics.cardWidth,
            MediaCardMetrics.posterWidth + MediaCardMetrics.cardPadding * 2
        )
    }

    func testMinimumHeightFitsPosterAndOneLineOfTitle() {
        let oneLineOfText: CGFloat = 20
        XCTAssertGreaterThanOrEqual(
            MediaCardMetrics.minimumCardHeight,
            MediaCardMetrics.posterHeight + MediaCardMetrics.cardPadding * 2 + oneLineOfText
        )
    }
}

final class SplashTests: XCTestCase {
    func testSloganIsExact() {
        XCTAssertEqual(SplashContent.slogan, "Discover. Track. Watch")
    }

    func testSplashIsBriefAndFades() {
        XCTAssertGreaterThan(SplashTiming.duration, .seconds(0))
        XCTAssertLessThanOrEqual(SplashTiming.duration, .seconds(4))
        XCTAssertGreaterThan(SplashTiming.fade, 0)
    }
}
