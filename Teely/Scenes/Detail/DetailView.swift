import SwiftUI

@MainActor
struct DetailView: View {
    @State private var scene: DetailScene

    init(environment: AppEnvironment, navigator: Navigating, kind: MediaKind, id: Int) {
        _scene = State(initialValue: DetailScene(environment: environment, navigator: navigator, kind: kind, id: id))
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .neuScreenBackground()
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await scene.interactor.load(Detail.Load.Request())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch scene.store.state {
        case .loading:
            ProgressView("detail.loading")
                .font(.manrope(.subheadline))
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
        case .content(let viewModel):
            DetailContentView(viewModel: viewModel, interactor: scene.interactor)
        case .failure(let title, let message):
            VStack(spacing: 20) {
                PlaceholderView(symbol: "exclamationmark.triangle", title: title, message: message)
                Button {
                    Task { await scene.interactor.load(Detail.Load.Request()) }
                } label: {
                    Text("common.retry")
                        .font(.manrope(.subheadline, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 16))
                .accessibilityIdentifier("retryButton")
            }
            .accessibilityIdentifier("detailFailure")
        }
    }
}

struct DetailContentView: View {
    let viewModel: Detail.ViewModel
    let interactor: DetailBusinessLogic
    @State private var isShowingRemoveConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            header
            actions
            if viewModel.showsRatingControls {
                ratingSection
            }
            NeuSectionCard(title: "detail.overview.title") {
                Text(verbatim: viewModel.overview)
                    .font(.manrope(.subheadline))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityIdentifier("detailOverview")
            }
            if let genres = viewModel.genres {
                NeuSectionCard(title: "detail.genres.title") {
                    Text(verbatim: genres)
                        .font(.manrope(.subheadline))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            if !viewModel.facts.isEmpty {
                NeuSectionCard(title: "detail.moreInfo.title") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.facts) { fact in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(verbatim: fact.title)
                                    .font(.manrope(.caption, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                                Text(verbatim: fact.value)
                                    .font(.manrope(.subheadline))
                                    .foregroundStyle(Theme.secondaryText)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier("detailMoreInfo")
            }
            if !viewModel.cast.isEmpty {
                NeuSectionCard(title: "detail.cast.title") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(viewModel.cast) { member in
                                VStack(alignment: .leading, spacing: 5) {
                                    PosterView(url: ImageURLBuilder.url(path: member.profilePath, size: .w185), cornerRadius: 8)
                                        .frame(width: 72, height: 104)
                                    Text(verbatim: member.name)
                                        .font(.manrope(.caption, weight: .bold))
                                        .foregroundStyle(Theme.primaryText)
                                        .lineLimit(2)
                                    if let character = member.character, !character.isEmpty {
                                        Text(verbatim: character)
                                            .font(.manrope(.caption2))
                                            .foregroundStyle(Theme.secondaryText)
                                            .lineLimit(2)
                                    }
                                }
                                .frame(width: 84, alignment: .leading)
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .accessibilityIdentifier("detailCast")
                }
            }
            if let trailer = viewModel.officialTrailer, trailer.embedURL != nil {
                NeuSectionCard(title: "detail.trailer.title") {
                    TrailerPlayerView(trailer: trailer)
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityIdentifier("officialTrailerPlayer")
                    Text(verbatim: trailer.name)
                        .font(.manrope(.caption))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .alert(
            "detail.remove.confirm.title",
            isPresented: $isShowingRemoveConfirmation
        ) {
            Button("detail.remove.confirm.action", role: .destructive) {
                interactor.remove(Detail.Remove.Request())
            }
            .accessibilityIdentifier("confirmRemoveButton")

            Button("common.cancel", role: .cancel) { }
                .accessibilityIdentifier("cancelRemoveButton")
        } message: {
            Text("detail.remove.confirm.message")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            PosterView(url: viewModel.posterURL, cornerRadius: 14)
                .frame(width: 120)
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: viewModel.title)
                    .font(.manrope(.title2, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.leading)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("detailTitle")
                Text(verbatim: viewModel.metadata)
                    .font(.manrope(.caption, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                if let tagline = viewModel.tagline {
                    Text(verbatim: tagline)
                        .font(.manrope(.caption))
                        .foregroundStyle(Theme.secondaryText)
                        .italic()
                }
                if let score = viewModel.scoreText {
                    Text(verbatim: score)
                        .font(.manrope(.caption, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .neuRaised(cornerRadius: 24)
    }

    @ViewBuilder
    private var actions: some View {
        if viewModel.isSaved {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    statusButton(title: "detail.watched", status: .watched, identifier: "watchedButton")
                    statusButton(title: "detail.wantToWatch", status: .wantToWatch, identifier: "wantToWatchButton")
                }
                Button {
                    isShowingRemoveConfirmation = true
                } label: {
                    Text("detail.remove")
                        .font(.manrope(.footnote, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .accessibilityIdentifier("removeButton")
            }
        } else {
            Button {
                interactor.save(Detail.Save.Request())
            } label: {
                Text("detail.save")
                    .font(.manrope(.headline, weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(NeuPrimaryButtonStyle())
            .accessibilityIdentifier("saveButton")
        }
    }

    private func statusButton(title: LocalizedStringKey, status: WatchStatus, identifier: String) -> some View {
        let isSelected = viewModel.status == status
        return Button {
            interactor.setStatus(Detail.SetStatus.Request(status: status))
        } label: {
            Text(title)
                .font(.manrope(.subheadline, weight: .bold))
                .foregroundStyle(isSelected ? Theme.accent : Theme.primaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 6)
        }
        .buttonStyle(NeuButtonStyle(cornerRadius: 16, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private var ratingSection: some View {
        NeuSectionCard(title: "detail.rate.title") {
            HStack(spacing: 14) {
                ratingButton(.liked, identifier: "likeButton")
                ratingButton(.disliked, identifier: "dislikeButton")
            }
        }
    }

    private func ratingButton(_ rating: MediaRating, identifier: String) -> some View {
        let isSelected = viewModel.rating == rating
        return Button {
            interactor.setRating(Detail.SetRating.Request(rating: rating))
        } label: {
            Image(systemName: isSelected ? rating.symbolName : rating.outlineSymbolName)
                .font(.title2)
                .foregroundStyle(isSelected ? Theme.accent : Theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(NeuButtonStyle(cornerRadius: 16, isSelected: isSelected))
        .accessibilityLabel(Text(LocalizedStringKey(rating.localizationKey)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

