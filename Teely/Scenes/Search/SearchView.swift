import SwiftUI

@MainActor
struct SearchView: View {
    @State private var scene: SearchScene
    private let query: String

    init(environment: AppEnvironment, navigator: Navigating, query: String) {
        self.query = query
        _scene = State(initialValue: SearchScene(environment: environment, navigator: navigator))
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .neuScreenBackground()
        .navigationTitle("search.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await scene.interactor.search(Search.Perform.Request(query: query))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch scene.store.state {
        case .loading:
            ProgressView("search.loading")
                .font(.manrope(.subheadline))
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
        case .results(let rows):
            LazyVStack(spacing: 16) {
                ForEach(rows) { row in
                    Button {
                        scene.interactor.select(Search.Select.Request(key: row.id))
                    } label: {
                        SearchRowView(row: row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("searchResult_\(row.id)")
                }
            }
            .padding(.horizontal, 4)
        case .empty(let title, let message):
            PlaceholderView(symbol: "magnifyingglass", title: title, message: message)
                .accessibilityIdentifier("searchEmpty")
        case .failure(let title, let message):
            PlaceholderView(symbol: "exclamationmark.triangle", title: title, message: message)
                .accessibilityIdentifier("searchFailure")
        }
    }
}

struct SearchRowView: View {
    let row: SearchRowViewModel

    var body: some View {
        HStack(spacing: 14) {
            PosterView(url: row.posterURL, cornerRadius: 8)
                .frame(width: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: row.title)
                    .font(.manrope(.headline, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.leading)
                Text(verbatim: row.subtitle)
                    .font(.manrope(.caption, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                if !row.overview.isEmpty {
                    Text(verbatim: row.overview)
                        .font(.manrope(.caption))
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .neuRaised(cornerRadius: 22, depth: 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: row.accessibilityLabel))
    }
}
