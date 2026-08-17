import SwiftUI
import UIKit

enum TallyTheme {
    static let ink = adaptive(dark: (0.055, 0.063, 0.061), light: (0.945, 0.936, 0.895))
    static let panel = adaptive(dark: (0.095, 0.105, 0.098), light: (0.995, 0.988, 0.957))
    static let elevated = adaptive(dark: (0.135, 0.145, 0.132), light: (0.885, 0.875, 0.825))
    static let bone = adaptive(dark: (0.89, 0.87, 0.79), light: (0.075, 0.095, 0.082))
    static let olive = Color(red: 0.36, green: 0.40, blue: 0.29)
    static let brass = Color(red: 0.72, green: 0.59, blue: 0.34)
    static let phosphor = Color(red: 0.61, green: 0.76, blue: 0.46)
    static let signal = Color(red: 0.83, green: 0.31, blue: 0.22)
    static let muted = adaptive(dark: (0.55, 0.56, 0.51), light: (0.34, 0.36, 0.32))

    static let cardGradient = LinearGradient(
        colors: [elevated, panel, ink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func adaptive(dark: (Double, Double, Double), light: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        })
    }
}

struct MicroLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.4)
            .foregroundStyle(TallyTheme.muted)
            .textCase(.uppercase)
    }
}

extension View {
    func microLabel() -> some View { modifier(MicroLabel()) }
}
