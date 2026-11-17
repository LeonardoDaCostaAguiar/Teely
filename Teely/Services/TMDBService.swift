import Foundation

enum TMDBError: Error, Equatable {
    case missingToken
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case http(Int)
    case decoding
}

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

protocol MediaServicing: Sendable {
    func search(query: String, language: String) async throws -> [MediaSummary]
    func trending(kind: MediaKind, language: String) async throws -> [MediaSummary]
    func detail(kind: MediaKind, id: Int, language: String) async throws -> MediaDetail
}

struct TMDBService: MediaServicing {
    let client: HTTPClient
    let baseURL: URL
    let accessToken: String

    init(
        client: HTTPClient = URLSession.shared,
        baseURL: URL = URL(string: "https://api.themoviedb.org")!,
        accessToken: String
    ) {
        self.client = client
        self.baseURL = baseURL
        self.accessToken = accessToken
    }

    func search(query: String, language: String) async throws -> [MediaSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let data = try await load(.search(query: trimmed, language: language))
        let response = try decode(SearchResponseDTO.self, from: data)
        return response.results.compactMap { $0.summary() }
    }

    func detail(kind: MediaKind, id: Int, language: String) async throws -> MediaDetail {
        let data = try await load(.detail(kind: kind, id: id, language: language))
        let dto = try decode(DetailDTO.self, from: data)
        return MediaDetail(dto: dto, kind: kind)
    }

    func trending(kind: MediaKind, language: String) async throws -> [MediaSummary] {
        let data = try await load(.trending(kind: kind, language: language))
        let response = try decode(SearchResponseDTO.self, from: data)
        return response.results.compactMap { $0.summary(kind: kind) }
    }

    private func load(_ endpoint: TMDBEndpoint) async throws -> Data {
        guard !accessToken.isEmpty else { throw TMDBError.missingToken }
        guard let url = endpoint.url(baseURL: baseURL) else { throw TMDBError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TMDBError.invalidResponse }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw TMDBError.unauthorized
        case 404: throw TMDBError.notFound
        default: throw TMDBError.http(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDBError.decoding
        }
    }
}
