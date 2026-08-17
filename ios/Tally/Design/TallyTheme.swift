import SwiftUI

enum TallyTheme {
    static let ink = Color(red: 0.055, green: 0.063, blue: 0.061)
    static let panel = Color(red: 0.095, green: 0.105, blue: 0.098)
    static let elevated = Color(red: 0.135, green: 0.145, blue: 0.132)
    static let bone = Color(red: 0.89, green: 0.87, blue: 0.79)
    static let olive = Color(red: 0.36, green: 0.40, blue: 0.29)
    static let brass = Color(red: 0.72, green: 0.59, blue: 0.34)
    static let phosphor = Color(red: 0.61, green: 0.76, blue: 0.46)
    static let signal = Color(red: 0.83, green: 0.31, blue: 0.22)
    static let muted = Color(red: 0.55, green: 0.56, blue: 0.51)

    static let cardGradient = LinearGradient(
        colors: [Color(red: 0.20, green: 0.22, blue: 0.20), panel, ink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

