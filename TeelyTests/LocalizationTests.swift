import XCTest
@testable import Teely

final class LocalizationTests: XCTestCase {
    private let languages = ["en", "pt-BR", "es"]

    private func strings(for code: String) throws -> [String: String] {
        let bundle = languageBundle(code)
        let path = try XCTUnwrap(bundle.path(forResource: "Localizable", ofType: "strings"))
        let dictionary = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
        return dictionary
    }

    func testAllLanguagesHaveTheSameKeys() throws {
        let reference = Set(try strings(for: "en").keys)
        XCTAssertFalse(reference.isEmpty)
        for code in languages {
            XCTAssertEqual(Set(try strings(for: code).keys), reference, "Keys differ for \(code)")
        }
    }

    func testNoValueIsEmpty() throws {
        for code in languages {
            for (key, value) in try strings(for: code) {
                XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "\(key) is empty in \(code)")
            }
        }
    }

    func testFormatPlaceholdersMatchAcrossLanguages() throws {
        let english = try strings(for: "en")
        for code in languages {
            let other = try strings(for: code)
            for (key, value) in english {
                XCTAssertEqual(placeholders(in: value), placeholders(in: other[key] ?? ""), "\(key) in \(code)")
            }
        }
    }

    func testAppLanguagesAreDeclared() {
        let declared = Bundle(for: AppEnvironment.self).infoDictionary?["CFBundleLocalizations"] as? [String]
        XCTAssertEqual(Set(declared ?? []), Set(languages))
    }

    func testKeyActionLabelsPerLanguage() throws {
        let expectations: [String: [String: String]] = [
            "en": ["detail.save": "Save to my Library", "detail.watched": "Watched", "detail.wantToWatch": "Want to watch"],
            "pt-BR": ["detail.save": "Salvar em minha Biblioteca", "detail.watched": "Assistido", "detail.wantToWatch": "Quero assistir"],
            "es": ["detail.save": "Guardar en mi biblioteca", "detail.watched": "Visto", "detail.wantToWatch": "Quiero ver"]
        ]
        for (code, pairs) in expectations {
            let localizer = Localizer(bundle: languageBundle(code))
            for (key, value) in pairs {
                XCTAssertEqual(localizer.string(key), value)
            }
        }
    }

    func testHomeAndLibraryNavigationLabelsAreLocalized() {
        let expected: [String: [String: String]] = [
            "en": ["tab.home": "Home", "tab.library": "Library", "home.trendingMovies": "Trending Movies", "home.trendingShows": "Trending TV Shows", "attribution.poweredBy": "Powered by TMDB"],
            "pt-BR": ["tab.home": "Início", "tab.library": "Biblioteca", "home.trendingMovies": "Filmes em alta", "home.trendingShows": "Séries em alta", "attribution.poweredBy": "Desenvolvido com TMDB"],
            "es": ["tab.home": "Inicio", "tab.library": "Biblioteca", "home.trendingMovies": "Películas populares", "home.trendingShows": "Series populares", "attribution.poweredBy": "Con tecnología de TMDB"]
        ]
        for (language, entries) in expected {
            let localizer = Localizer(bundle: languageBundle(language))
            for (key, value) in entries { XCTAssertEqual(localizer.string(key), value, "\(key) in \(language)") }
        }
    }

    private func placeholders(in text: String) -> [String] {
        text.split(separator: "%", omittingEmptySubsequences: false)
            .dropFirst()
            .map { String($0.prefix { $0 != " " && $0 != "." }) }
    }
}
