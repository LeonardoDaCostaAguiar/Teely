import Foundation
import SwiftData
@testable import Teely

enum TestError: Error {
    case unexpectedState
}

final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var queue: [Result<(Data, Int), Error>] = []
    private var storedRequests: [URLRequest] = []

    var requests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return storedRequests
    }

    func enqueue(json: String, status: Int = 200) {
        lock.lock()
        queue.append(.success((Data(json.utf8), status)))
        lock.unlock()
    }

    func enqueue(error: Error) {
        lock.lock()
        queue.append(.failure(error))
        lock.unlock()
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lock.lock()
        storedRequests.append(request)
        let next = queue.isEmpty ? nil : queue.removeFirst()
        lock.unlock()
        guard let next else { throw URLError(.badServerResponse) }
        switch next {
        case .success(let (data, status)):
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}

final class MockMediaService: MediaServicing, @unchecked Sendable {
    var searchResult: Result<[MediaSummary], Error> = .success([])
    var detailResult: Result<MediaDetail, Error> = .success(Sample.detail())
    private(set) var searchCalls: [(query: String, language: String)] = []
    var trendingResult: Result<[MediaSummary], Error> = .success([])
    private(set) var detailCalls: [(kind: MediaKind, id: Int, language: String)] = []

    func search(query: String, language: String) async throws -> [MediaSummary] {
        searchCalls.append((query, language))
        return try searchResult.get()
    }

    func detail(kind: MediaKind, id: Int, language: String) async throws -> MediaDetail {
        detailCalls.append((kind, id, language))
        return try detailResult.get()
    }

    func trending(kind: MediaKind, language: String) async throws -> [MediaSummary] {
        try trendingResult.get().filter { $0.kind == kind }
    }
}

@MainActor
final class SpyNavigator: Navigating {
    private(set) var pushed: [Route] = []
    private(set) var popCount = 0
    private(set) var popToRootCount = 0

    func push(_ route: Route) { pushed.append(route) }
    func pop() { popCount += 1 }
    func popToRoot() { popToRootCount += 1 }
}

@MainActor
final class InMemoryLibraryWorker: LibraryWorking {
    var items: [SavedMedia] = []
    var failsOnAll = false

    func all() throws -> [SavedMedia] {
        if failsOnAll { throw LibraryWorkerError.notFound }
        return items
    }

    func find(key: String) throws -> SavedMedia? {
        items.first { $0.key == key }
    }

    func save(_ detail: MediaDetail) throws -> SavedMedia {
        if let existing = try find(key: detail.key) { return existing }
        let saved = SavedMedia(detail: detail)
        items.append(saved)
        return saved
    }

    func setStatus(_ status: WatchStatus, key: String) throws {
        guard let saved = try find(key: key) else { throw LibraryWorkerError.notFound }
        saved.status = status
    }

    func setRating(_ rating: MediaRating?, key: String) throws {
        guard let saved = try find(key: key) else { throw LibraryWorkerError.notFound }
        saved.rating = rating
    }

    func remove(key: String) throws {
        guard items.contains(where: { $0.key == key }) else { throw LibraryWorkerError.notFound }
        items.removeAll { $0.key == key }
    }
}

enum Sample {
    static func detail(id: Int = 101, kind: MediaKind = .movie, title: String = "Teely Movie") -> MediaDetail {
        MediaDetail(
            tmdbID: id,
            kind: kind,
            title: title,
            tagline: "A tagline",
            overview: "An overview",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseYear: 2024,
            genres: ["Drama", "Comedy"],
            runtimeMinutes: kind == .movie ? 120 : nil,
            seasons: kind == .tv ? 3 : nil,
            voteAverage: 7.84
        )
    }

    static func summary(id: Int = 101, kind: MediaKind = .movie, title: String = "Teely Movie") -> MediaSummary {
        MediaSummary(tmdbID: id, kind: kind, title: title, overview: "An overview", posterPath: "/poster.jpg", releaseYear: 2024, voteAverage: 7.5)
    }

    static func item(
        id: Int = 101,
        kind: MediaKind = .movie,
        title: String = "Teely Movie",
        status: WatchStatus? = nil,
        rating: MediaRating? = nil
    ) -> SavedItem {
        SavedItem(
            key: MediaKey.make(kind: kind, id: id),
            tmdbID: id,
            kind: kind,
            title: title,
            posterPath: "/poster.jpg",
            releaseYear: 2024,
            status: status,
            rating: rating
        )
    }

    static let searchJSON = """
    {
      "page": 1,
      "results": [
        {"id": 1, "media_type": "movie", "title": "First Movie", "overview": "Movie overview", "poster_path": "/m.jpg", "release_date": "2021-05-01", "vote_average": 8.1},
        {"id": 2, "media_type": "tv", "name": "First Series", "overview": "Series overview", "poster_path": null, "first_air_date": "2019-09-10", "vote_average": 7.2},
        {"id": 3, "media_type": "person", "name": "Some Person"},
        {"id": 4, "media_type": "movie", "title": "   "}
      ]
    }
    """

    static let movieDetailJSON = """
    {
      "id": 1,
      "title": "First Movie",
      "tagline": "Tagline",
      "overview": "Movie overview",
      "poster_path": "/m.jpg",
      "backdrop_path": "/b.jpg",
      "release_date": "2021-05-01",
      "genres": [{"id": 1, "name": "Drama"}, {"id": 2, "name": "Comedy"}],
      "runtime": 128,
      "vote_average": 8.1
    }
    """

    static let tvDetailJSON = """
    {
      "id": 2,
      "name": "First Series",
      "tagline": "",
      "overview": "",
      "poster_path": null,
      "first_air_date": "2019-09-10",
      "genres": [],
      "episode_run_time": [45, 50],
      "number_of_seasons": 4,
      "number_of_episodes": 40,
      "vote_average": 0
    }
    """
}

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    try ModelContainer(for: SavedMedia.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

func languageBundle(_ code: String) -> Bundle {
    let main = Bundle(for: AppEnvironment.self)
    guard let path = main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else {
        fatalError("Missing localization \(code)")
    }
    return bundle
}
