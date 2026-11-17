import SwiftUI

enum MediaCardMetrics {
    static let posterWidth: CGFloat = 132
    static let posterHeight: CGFloat = 190
    static let cardWidth: CGFloat = 148
    static let minimumCardHeight: CGFloat = 248
    static let cardPadding: CGFloat = 8
}

struct PosterView: View {
    let url: URL?
    var cornerRadius: CGFloat = 10

    var body: some View {
        Color.clear
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        default:
                            ProgressView()
                        }
                    }
                } else {
                    placeholder
                }
            }
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: "film")
            .font(.title3)
            .foregroundStyle(Theme.secondaryText)
    }
}
