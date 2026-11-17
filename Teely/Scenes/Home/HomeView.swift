import SwiftUI

@MainActor
struct HomeView: View {
    let environment: AppEnvironment
    let navigator: Navigating
    @State private var query = ""
    @State private var movies: [MediaSummary] = []
    @State private var shows: [MediaSummary] = []
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image("TeelyLogo")
                        .resizable().scaledToFit().frame(height: 54)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(Text(verbatim: "Teely"))
                        .accessibilityIdentifier("teelyLogo")
                    NeuSearchField(text: $query) {
                        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !value.isEmpty { navigator.push(.search(value)) }
                    }
                    if isLoading {
                        ProgressView("home.loading")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: max(300, geometry.size.height - 260), alignment: .center)
                    } else if failed {
                        PlaceholderView(symbol: "wifi.exclamationmark", title: Localizer.main.string("home.error.title"), message: Localizer.main.string("home.error.message"))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: max(300, geometry.size.height - 260), alignment: .center)
                            .accessibilityIdentifier("trendingFailure")
                    } else {
                        trendingSection(title: "home.trendingMovies", items: movies, id: "trendingMovies")
                        trendingSection(title: "home.trendingShows", items: shows, id: "trendingShows")
                    }
                    Text("attribution.poweredBy")
                        .font(.manrope(.caption, weight: .bold)).foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity).padding(.top, 8)
                        .accessibilityIdentifier("tmdbAttribution")
                }
                .frame(minHeight: geometry.size.height, alignment: .top)
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .neuScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadTrending() }
    }

    private func trendingSection(title: LocalizedStringKey, items: [MediaSummary], id: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.manrope(.headline, weight: .bold)).foregroundStyle(Theme.primaryText)
                .accessibilityAddTraits(.isHeader)
            if items.isEmpty {
                Text(verbatim: Localizer.main.string("home.noTrending")).font(.manrope(.subheadline)).foregroundStyle(Theme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(items) { item in
                            Button { navigator.push(.detail(kind: item.kind, id: item.tmdbID)) } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    PosterView(url: ImageURLBuilder.url(path: item.posterPath, size: .w342), cornerRadius: 12)
                                        .frame(width: MediaCardMetrics.posterWidth, height: MediaCardMetrics.posterHeight)
                                    Text(verbatim: item.title)
                                        .font(.manrope(.caption, weight: .bold))
                                        .foregroundStyle(Theme.primaryText)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(width: MediaCardMetrics.posterWidth, alignment: .topLeading)
                                }
                                .padding(MediaCardMetrics.cardPadding)
                                .frame(width: MediaCardMetrics.cardWidth, alignment: .top)
                                .frame(minHeight: MediaCardMetrics.minimumCardHeight, maxHeight: .infinity, alignment: .top)
                                .neuRaised(cornerRadius: 18, depth: 4)
                            }
                            .buttonStyle(.plain).accessibilityIdentifier("\(id)_\(item.key)")
                        }
                    }.padding(.horizontal, 6).padding(.vertical, 6)
                }
            }
        }
        .accessibilityIdentifier(id)
    }

    private func loadTrending() async {
        async let movieResults = environment.service.trending(kind: .movie, language: environment.languageProvider())
        async let showResults = environment.service.trending(kind: .tv, language: environment.languageProvider())
        do {
            let (movieItems, showItems) = try await (movieResults, showResults)
            movies = movieItems
            shows = showItems
        } catch {
            failed = true
        }
        isLoading = false
    }
}
