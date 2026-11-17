import Foundation

@MainActor
protocol DetailPresentationLogic: AnyObject {
    func presentLoading()
    func presentContent(_ response: Detail.Response)
    func presentFailure(_ failure: Detail.Failure)
}

@MainActor
protocol DetailDisplayLogic: AnyObject {
    func displayState(_ state: Detail.State)
}

@MainActor
final class DetailPresenter: DetailPresentationLogic {
    private weak var display: DetailDisplayLogic?
    private let localizer: Localizer

    init(display: DetailDisplayLogic?, localizer: Localizer = .main) {
        self.display = display
        self.localizer = localizer
    }

    func presentLoading() {
        display?.displayState(.loading)
    }

    func presentContent(_ response: Detail.Response) {
        let detail = response.detail
        var parts = [localizer.string(detail.kind.localizationKey)]
        if let year = detail.releaseYear {
            parts.append(String(year))
        }
        if let minutes = detail.runtimeMinutes, minutes > 0 {
            parts.append(localizer.string("detail.runtime", minutes))
        }
        if let seasons = detail.seasons, seasons > 0 {
            parts.append(localizer.string(seasons == 1 ? "detail.seasons.one" : "detail.seasons.other", seasons))
        }
        if let episodes = detail.episodes, episodes > 0 {
            parts.append(localizer.string(episodes == 1 ? "detail.episodes.one" : "detail.episodes.other", episodes))
        }
        let overview = detail.overview.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = detail.voteAverage.flatMap { $0 > 0 ? localizer.string("detail.score", String(format: "%.1f", $0)) : nil }
        let status = response.saved?.status
        let facts = makeFacts(detail)
        let viewModel = Detail.ViewModel(
            title: detail.title,
            metadata: parts.joined(separator: " · "),
            tagline: detail.tagline,
            overview: overview.isEmpty ? localizer.string("detail.noOverview") : overview,
            genres: detail.genres.isEmpty ? nil : detail.genres.joined(separator: ", "),
            scoreText: score,
            posterURL: ImageURLBuilder.url(path: detail.posterPath, size: .w500),
            isSaved: response.saved != nil,
            status: status,
            showsRatingControls: status == .watched,
            rating: status == .watched ? response.saved?.rating : nil,
            facts: facts,
            cast: detail.cast,
            officialTrailer: detail.officialTrailer
        )
        display?.displayState(.content(viewModel))
    }

    private func makeFacts(_ detail: MediaDetail) -> [Detail.Fact] {
        var facts: [Detail.Fact] = []
        func add(_ key: String, _ labelKey: String, _ value: String?) {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            facts.append(Detail.Fact(id: key, title: localizer.string(labelKey), value: value))
        }
        func addList(_ key: String, _ labelKey: String, _ values: [String]) {
            let cleanValues = values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            add(key, labelKey, cleanValues.isEmpty ? nil : cleanValues.joined(separator: ", "))
        }
        add("releaseDate", "detail.releaseDate", detail.releaseDate)
        add("originalTitle", "detail.originalTitle", detail.originalTitle)
        add("originalLanguage", "detail.originalLanguage", detail.originalLanguage?.uppercased())
        add("productionStatus", "detail.productionStatus", detail.productionStatus)
        if let inProduction = detail.inProduction { add("inProduction", "detail.inProduction", localizer.string(inProduction ? "common.yes" : "common.no")) }
        add("nextEpisode", "detail.nextEpisode", detail.nextEpisodeName)
        add("nextEpisodeDate", "detail.nextEpisodeDate", detail.nextEpisodeDate)
        if let season = detail.nextSeasonNumber, let episode = detail.nextEpisodeNumber {
            add("nextEpisodeNumber", "detail.nextEpisodeNumber", "S\(season) · E\(episode)")
        }
        if let budget = detail.budget, budget > 0 { add("budget", "detail.budget", currency(budget)) }
        if let revenue = detail.revenue, revenue > 0 { add("revenue", "detail.revenue", currency(revenue)) }
        addList("companies", "detail.productionCompanies", detail.productionCompanies)
        addList("countries", "detail.productionCountries", detail.productionCountries)
        addList("spokenLanguages", "detail.spokenLanguages", detail.spokenLanguages)
        addList("originCountries", "detail.originCountries", detail.originCountries)
        addList("creators", "detail.creators", detail.creators)
        addList("networks", "detail.networks", detail.networks)
        return facts
    }

    private func currency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "USD \(amount)"
    }

    func presentFailure(_ failure: Detail.Failure) {
        let message = failure == .missingToken
            ? localizer.string("error.missingToken.message")
            : localizer.string("detail.error.message")
        display?.displayState(.failure(title: localizer.string("detail.error.title"), message: message))
    }
}
