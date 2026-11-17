import XCTest
@testable import Teely

final class TMDBEndpointTests: XCTestCase {
    private let base = URL(string: "https://api.themoviedb.org")!

    func testSearchEndpointCarriesLanguage() throws {
        for language in AppLanguage.supported {
            let url = try XCTUnwrap(TMDBEndpoint.search(query: "matrix", language: language).url(baseURL: base))
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.host, "api.themoviedb.org")
            XCTAssertEqual(components.path, "/3/search/multi")
            let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(items["query"], "matrix")
            XCTAssertEqual(items["language"], language)
            XCTAssertEqual(items["include_adult"], "false")
            XCTAssertEqual(items["page"], "1")
        }
    }

    func testSearchEndpointEncodesSpecialCharacters() throws {
        let url = try XCTUnwrap(TMDBEndpoint.search(query: "amélie & co", language: "pt-BR").url(baseURL: base))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = components.queryItems?.first { $0.name == "query" }?.value
        XCTAssertEqual(query, "amélie & co")
    }

    func testTrendingEndpointsUseCorrectMediaPathsAndLanguage() throws {
        let movie = try XCTUnwrap(TMDBEndpoint.trending(kind: .movie, language: "pt-BR").url(baseURL: base))
        let tv = try XCTUnwrap(TMDBEndpoint.trending(kind: .tv, language: "es-ES").url(baseURL: base))
        XCTAssertEqual(movie.path, "/3/trending/movie/week")
        XCTAssertEqual(tv.path, "/3/trending/tv/week")
        XCTAssertTrue(movie.absoluteString.contains("language=pt-BR"))
        XCTAssertTrue(tv.absoluteString.contains("language=es-ES"))
    }

    func testDetailEndpointPathsPerKind() throws {
        let movie = try XCTUnwrap(TMDBEndpoint.detail(kind: .movie, id: 12, language: "es-ES").url(baseURL: base))
        let series = try XCTUnwrap(TMDBEndpoint.detail(kind: .tv, id: 34, language: "es-ES").url(baseURL: base))
        XCTAssertEqual(movie.path, "/3/movie/12")
        XCTAssertEqual(series.path, "/3/tv/34")
        XCTAssertTrue(movie.absoluteString.contains("language=es-ES"))
        let movieItems = try XCTUnwrap(URLComponents(url: movie, resolvingAgainstBaseURL: false)?.queryItems)
        let appended = movieItems.first(where: { $0.name == "append_to_response" })?.value
        XCTAssertEqual(appended, "credits,videos")
        let tvItems = try XCTUnwrap(URLComponents(url: series, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(tvItems.first(where: { $0.name == "append_to_response" })?.value, "aggregate_credits,videos")
    }
}

final class ImageURLBuilderTests: XCTestCase {
    func testBuildsURLWithSize() {
        XCTAssertEqual(
            ImageURLBuilder.url(path: "/abc.jpg", size: .w342)?.absoluteString,
            "https://image.tmdb.org/t/p/w342/abc.jpg"
        )
    }

    func testRejectsMissingOrInvalidPaths() {
        XCTAssertNil(ImageURLBuilder.url(path: nil, size: .w185))
        XCTAssertNil(ImageURLBuilder.url(path: "", size: .w185))
        XCTAssertNil(ImageURLBuilder.url(path: "abc.jpg", size: .w185))
    }
}

final class TMDBServiceTests: XCTestCase {
    private func makeService(_ client: StubHTTPClient, token: String = "token") -> TMDBService {
        TMDBService(client: client, accessToken: token)
    }

    func testSearchDecodesMoviesAndSeriesAndSkipsOthers() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: Sample.searchJSON)
        let results = try await makeService(client).search(query: "first", language: "en-US")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].kind, .movie)
        XCTAssertEqual(results[0].title, "First Movie")
        XCTAssertEqual(results[0].releaseYear, 2021)
        XCTAssertEqual(results[0].posterPath, "/m.jpg")
        XCTAssertEqual(results[1].kind, .tv)
        XCTAssertEqual(results[1].title, "First Series")
        XCTAssertEqual(results[1].releaseYear, 2019)
        XCTAssertNil(results[1].posterPath)
    }

    func testSearchSendsAuthorizationAndLanguage() async throws {
        for language in AppLanguage.supported {
            let client = StubHTTPClient()
            client.enqueue(json: "{\"results\": []}")
            _ = try await makeService(client, token: "abc").search(query: "matrix", language: language)
            let request = try XCTUnwrap(client.requests.first)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertTrue(request.url?.absoluteString.contains("language=\(language)") ?? false)
        }
    }

    func testTrendingDecodesKnownMediaType() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: #"{"results":[{"id":12,"title":"Trending Film","release_date":"2025-01-01","poster_path":"/trend.jpg","vote_average":8.2}]}"#)
        let items = try await makeService(client).trending(kind: .movie, language: "en-US")
        XCTAssertEqual(items.map(\.kind), [.movie])
        XCTAssertEqual(items.first?.title, "Trending Film")
        XCTAssertEqual(items.first?.releaseYear, 2025)
        XCTAssertEqual(client.requests.first?.url?.path, "/3/trending/movie/week")
    }

    func testEmptyQueryDoesNotHitTheNetwork() async throws {
        let client = StubHTTPClient()
        let results = try await makeService(client).search(query: "   ", language: "en-US")
        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(client.requests.isEmpty)
    }

    func testMissingTokenThrows() async {
        let client = StubHTTPClient()
        do {
            _ = try await makeService(client, token: "").search(query: "matrix", language: "en-US")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TMDBError, .missingToken)
        }
        XCTAssertTrue(client.requests.isEmpty)
    }

    func testStatusCodesMapToErrors() async {
        let cases: [(Int, TMDBError)] = [(401, .unauthorized), (404, .notFound), (500, .http(500)), (429, .http(429))]
        for (status, expected) in cases {
            let client = StubHTTPClient()
            client.enqueue(json: "{}", status: status)
            do {
                _ = try await makeService(client).search(query: "matrix", language: "en-US")
                XCTFail("Expected an error for \(status)")
            } catch {
                XCTAssertEqual(error as? TMDBError, expected)
            }
        }
    }

    func testInvalidJSONThrowsDecodingError() async {
        let client = StubHTTPClient()
        client.enqueue(json: "not json")
        do {
            _ = try await makeService(client).search(query: "matrix", language: "en-US")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TMDBError, .decoding)
        }
    }

    func testTransportErrorIsPropagated() async {
        let client = StubHTTPClient()
        client.enqueue(error: URLError(.notConnectedToInternet))
        do {
            _ = try await makeService(client).search(query: "matrix", language: "en-US")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testMovieDetailMapping() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: Sample.movieDetailJSON)
        let detail = try await makeService(client).detail(kind: .movie, id: 1, language: "pt-BR")
        XCTAssertEqual(detail.title, "First Movie")
        XCTAssertEqual(detail.tagline, "Tagline")
        XCTAssertEqual(detail.releaseYear, 2021)
        XCTAssertEqual(detail.genres, ["Drama", "Comedy"])
        XCTAssertEqual(detail.runtimeMinutes, 128)
        XCTAssertNil(detail.seasons)
        XCTAssertEqual(detail.voteAverage, 8.1)
        XCTAssertEqual(client.requests.first?.url?.path, "/3/movie/1")
        XCTAssertTrue(client.requests.first?.url?.absoluteString.contains("language=pt-BR") ?? false)
    }

    func testDetailMapsCastProductionFactsAndOnlyOfficialTrailer() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: #"{"id":1,"title":"Film","original_title":"Original Film","imdb_id":"tt1234567","belongs_to_collection":{"name":"Film Collection"},"release_date":"2024-04-05","original_language":"pt","status":"Released","homepage":"https://example.org","budget":1000,"revenue":2000,"vote_count":42,"popularity":9.5,"production_companies":[{"name":"Studio"}],"production_countries":[{"name":"Brazil"}],"spoken_languages":[{"name":"Portuguese","english_name":"Portuguese"}],"credits":{"cast":[{"id":11,"name":"Actor One","character":"Hero","profile_path":"/actor.jpg","order":0}],"crew":[{"id":21,"name":"Director One","job":"Director","department":"Directing"}]},"videos":{"results":[{"key":"fan-cut","name":"Fan cut","site":"YouTube","type":"Trailer","official":false,"iso_639_1":"en"},{"key":"official-key","name":"Official Trailer","site":"YouTube","type":"Trailer","official":true,"iso_639_1":"en","published_at":"2024-01-01T00:00:00.000Z"},{"key":"teaser-key","name":"Official Teaser","site":"YouTube","type":"Teaser","official":true,"iso_639_1":"en"}]}}"#)
        let detail = try await makeService(client).detail(kind: .movie, id: 1, language: "en-US")
        XCTAssertEqual(detail.releaseDate, "2024-04-05")
        XCTAssertEqual(detail.originalTitle, "Original Film")
        XCTAssertEqual(detail.originalLanguage, "pt")
        XCTAssertEqual(detail.budget, 1000)
        XCTAssertEqual(detail.productionCompanies, ["Studio"])
        XCTAssertEqual(detail.cast.first?.name, "Actor One")
        XCTAssertEqual(detail.cast.first?.character, "Hero")
        XCTAssertEqual(detail.crew.first?.job, "Director")
        XCTAssertEqual(detail.officialTrailer?.key, "official-key")
        XCTAssertEqual(detail.officialTrailer?.embedURL?.host, "www.youtube-nocookie.com")
    }

    func testTVDetailMapsAggregateCredits() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: #"{"id":2,"name":"Series","first_air_date":"2022-03-10","aggregate_credits":{"cast":[{"id":33,"name":"Lead Actor","profile_path":"/lead.jpg","order":0,"roles":[{"character":"Detective"}]}],"crew":[{"id":44,"name":"Creator","department":"Writing","jobs":[{"job":"Creator"}]}]}}"#)
        let detail = try await makeService(client).detail(kind: .tv, id: 2, language: "en-US")
        XCTAssertEqual(detail.cast.first?.name, "Lead Actor")
        XCTAssertEqual(detail.cast.first?.character, "Detective")
        XCTAssertEqual(detail.crew.first?.job, "Creator")
    }

    func testSeriesDetailMapping() async throws {
        let client = StubHTTPClient()
        client.enqueue(json: Sample.tvDetailJSON)
        let detail = try await makeService(client).detail(kind: .tv, id: 2, language: "es-ES")
        XCTAssertEqual(detail.title, "First Series")
        XCTAssertNil(detail.tagline)
        XCTAssertEqual(detail.releaseYear, 2019)
        XCTAssertEqual(detail.runtimeMinutes, 45)
        XCTAssertEqual(detail.seasons, 4)
        XCTAssertEqual(detail.episodes, 40)
        XCTAssertEqual(client.requests.first?.url?.path, "/3/tv/2")
    }

    func testDetailNotFound() async {
        let client = StubHTTPClient()
        client.enqueue(json: "{}", status: 404)
        do {
            _ = try await makeService(client).detail(kind: .movie, id: 99, language: "en-US")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TMDBError, .notFound)
        }
    }
}

final class StubMediaServiceTests: XCTestCase {
    func testSearchFiltersByTitle() async throws {
        let service = StubMediaService()
        let all = try await service.search(query: "teely", language: "en-US")
        XCTAssertEqual(all.count, 3)
        let series = try await service.search(query: "series", language: "en-US")
        XCTAssertEqual(series.map(\.tmdbID), [202])
        let none = try await service.search(query: "", language: "en-US")
        XCTAssertTrue(none.isEmpty)
    }

    func testCatalogIncludesATitleLongEnoughToWrap() async throws {
        let service = StubMediaService()
        let results = try await service.search(query: "extraordinarily", language: "en-US")
        XCTAssertEqual(results.map(\.tmdbID), [404])
        XCTAssertEqual(results.first?.title, StubMediaService.longTitle)
        XCTAssertGreaterThan(StubMediaService.longTitle.count, 60)
    }

    func testTrendingMoviesIncludeTheLongTitle() async throws {
        let movies = try await StubMediaService().trending(kind: .movie, language: "en-US")
        XCTAssertEqual(movies.map(\.tmdbID), [101, 303, 404])
    }

    func testDetailEchoesLanguage() async throws {
        let detail = try await StubMediaService().detail(kind: .movie, id: 101, language: "es-ES")
        XCTAssertEqual(detail.overview, "stub-overview-es-ES")
    }

    func testDetailUnknownThrows() async {
        do {
            _ = try await StubMediaService().detail(kind: .movie, id: 999, language: "en-US")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? TMDBError, .notFound)
        }
    }
}
