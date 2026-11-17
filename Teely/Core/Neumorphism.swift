import SwiftUI

struct NeuSurface: View {
    var cornerRadius: CGFloat = 20
    var isInset = false
    var depth: CGFloat = 7

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if isInset {
            shape
                .fill(Theme.background)
                .overlay {
                    shape
                        .stroke(Theme.shade, lineWidth: depth)
                        .blur(radius: depth * 0.6)
                        .offset(x: depth * 0.4, y: depth * 0.4)
                        .mask(shape)
                }
                .overlay {
                    shape
                        .stroke(Theme.highlight, lineWidth: depth)
                        .blur(radius: depth * 0.6)
                        .offset(x: -depth * 0.4, y: -depth * 0.4)
                        .mask(shape)
                }
                .clipShape(shape)
        } else {
            shape
                .fill(Theme.surface)
                .shadow(color: Theme.shade, radius: depth, x: depth, y: depth)
                .shadow(color: Theme.highlight, radius: depth, x: -depth, y: -depth)
        }
    }
}

extension View {
    func neuRaised(cornerRadius: CGFloat = 20, depth: CGFloat = 7) -> some View {
        background(NeuSurface(cornerRadius: cornerRadius, isInset: false, depth: depth))
    }

    func neuInset(cornerRadius: CGFloat = 20, depth: CGFloat = 6) -> some View {
        background(NeuSurface(cornerRadius: cornerRadius, isInset: true, depth: depth))
    }

    func neuScreenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

struct NeuButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        let isInset = configuration.isPressed || isSelected
        return configuration.label
            .background(
                NeuSurface(
                    cornerRadius: cornerRadius,
                    isInset: isInset,
                    depth: isInset ? 5 : 7
                )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NeuPrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.accent)
                    .shadow(
                        color: Theme.shade,
                        radius: configuration.isPressed ? 3 : 7,
                        x: configuration.isPressed ? 2 : 6,
                        y: configuration.isPressed ? 2 : 6
                    )
                    .shadow(
                        color: Theme.highlight,
                        radius: configuration.isPressed ? 3 : 7,
                        x: configuration.isPressed ? -2 : -6,
                        y: configuration.isPressed ? -2 : -6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NeuSectionCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.manrope(.headline, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .neuRaised(cornerRadius: 24)
    }
}
