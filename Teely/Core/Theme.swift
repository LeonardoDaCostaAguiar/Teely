import SwiftUI
import UIKit

enum Palette {
    static let backgroundLight: UInt32 = 0xEAE9F3
    static let surfaceLight: UInt32 = 0xF5F3FF
    static let accentLight: UInt32 = 0x7057C5
    static let primaryTextLight: UInt32 = 0x20232D
    static let secondaryTextLight: UInt32 = 0x5F6678
    static let highlightLight: UInt32 = 0xFFFFFF
    static let shadeLight: UInt32 = 0xC6C5D4

    static let backgroundDark: UInt32 = 0x20232D
    static let surfaceDark: UInt32 = 0x2C3040
    static let accentDark: UInt32 = 0xB9A5FF
    static let primaryTextDark: UInt32 = 0xF5F3FF
    static let secondaryTextDark: UInt32 = 0x9298AA
    static let highlightDark: UInt32 = 0x383D50
    static let shadeDark: UInt32 = 0x171A23
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: .dynamic(light: light, dark: dark))
    }
}

enum Theme {
    static let background = Color(light: Palette.backgroundLight, dark: Palette.backgroundDark)
    static let surface = Color(light: Palette.surfaceLight, dark: Palette.surfaceDark)
    static let accent = Color(light: Palette.accentLight, dark: Palette.accentDark)
    static let primaryText = Color(light: Palette.primaryTextLight, dark: Palette.primaryTextDark)
    static let secondaryText = Color(light: Palette.secondaryTextLight, dark: Palette.secondaryTextDark)
    static let highlight = Color(light: Palette.highlightLight, dark: Palette.highlightDark)
    static let shade = Color(light: Palette.shadeLight, dark: Palette.shadeDark)
    static let onAccent = Color(light: Palette.surfaceLight, dark: Palette.backgroundDark)
}
