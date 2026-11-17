import SwiftUI

struct PlaceholderView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
                .frame(width: 96, height: 96)
                .neuRaised(cornerRadius: 48)
                .accessibilityHidden(true)
            Text(verbatim: title)
                .font(.manrope(.title3, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
            Text(verbatim: message)
                .font(.manrope(.subheadline))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }
}
