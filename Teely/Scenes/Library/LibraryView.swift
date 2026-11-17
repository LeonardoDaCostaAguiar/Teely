import SwiftUI

@MainActor
struct LibraryView: View {
    @State private var scene: LibraryScene

    init(environment: AppEnvironment, navigator: Navigating) {
        _scene = State(initialValue: LibraryScene(environment: environment, navigator: navigator))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("TeelyLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 54)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(Text(verbatim: "Teely"))
                    .accessibilityIdentifier("teelyLogo")
                filterBar
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .neuScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            scene.interactor.load(Library.Load.Request())
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(scene.store.viewModel.filters) { option in
                Button {
                    scene.interactor.setFilter(Library.SetFilter.Request(filter: option.filter))
                } label: {
                    Text(verbatim: option.title)
                        .font(.manrope(.footnote, weight: .bold))
                        .foregroundStyle(option.isSelected ? Theme.accent : Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 14, isSelected: option.isSelected))
                .accessibilityAddTraits(option.isSelected ? .isSelected : [])
                .accessibilityIdentifier("libraryFilter_\(option.id)")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var content: some View {
        let viewModel = scene.store.viewModel
        if let message = viewModel.errorMessage {
            Text(verbatim: message)
                .font(.manrope(.subheadline))
                .foregroundStyle(Theme.secondaryText)
        } else if viewModel.cards.isEmpty {
            PlaceholderView(symbol: "film.stack", title: viewModel.emptyTitle, message: viewModel.emptyMessage)
                .accessibilityIdentifier("libraryEmpty")
        } else {
            LazyVStack(alignment: .center, spacing: 12) {
                ForEach(Array(LibraryLayout.rows(viewModel.cards).enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .top, spacing: LibraryLayout.spacing) {
                        ForEach(row) { card in
                            Button {
                                scene.interactor.select(Library.Select.Request(key: card.id))
                            } label: {
                                LibraryCardView(card: card)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("libraryCard_\(card.id)")
                        }
                        if row.count < LibraryLayout.columnCount {
                            Color.clear
                                .frame(width: LibraryLayout.cardWidth)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct LibraryCardView: View {
    let card: LibraryCardViewModel

    var body: some View {
        VStack(spacing: 8) {
            PosterView(url: card.posterURL, cornerRadius: 12)
                .frame(width: MediaCardMetrics.posterWidth, height: MediaCardMetrics.posterHeight)
            VStack(spacing: 4) {
                Text(verbatim: card.title)
                    .font(.manrope(.caption, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: MediaCardMetrics.posterWidth)
                Text(verbatim: card.kindTitle)
                    .font(.manrope(.caption2, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(verbatim: card.statusTitle)
                    .font(.manrope(.caption2))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: card.ratingSymbol ?? "circle")
                    .font(.caption2)
                    .foregroundStyle(Theme.accent)
                    .opacity(card.ratingSymbol == nil ? 0 : 1)
            }
            .frame(width: MediaCardMetrics.posterWidth)
        }
        .padding(MediaCardMetrics.cardPadding)
        .frame(width: MediaCardMetrics.cardWidth, alignment: .top)
        .frame(minHeight: MediaCardMetrics.minimumCardHeight, maxHeight: .infinity, alignment: .top)
        .neuRaised(cornerRadius: 18, depth: 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: card.accessibilityLabel))
    }
}
