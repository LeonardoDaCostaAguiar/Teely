import SwiftUI

extension Font.TextStyle {
    var baseSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}

extension Font {
    static func manrope(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom("Manrope", size: style.baseSize, relativeTo: style).weight(weight)
    }
}
