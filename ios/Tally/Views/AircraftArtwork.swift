import SwiftUI
import UIKit

struct AircraftArtwork: View {
    let encounter: Encounter
    var compact = false

    private var isJumbo: Bool { encounter.aircraft.model.contains("747") }
    private var isWidebody: Bool {
        ["747", "787", "A350", "A330", "A380"].contains { encounter.aircraft.model.contains($0) }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                aircraftShadow(size)
                wing(size)
                    .fill(Color.black.opacity(0.28))
                    .offset(y: size.height * 0.055)
                tailPlane(size)
                    .fill(Color(hex: encounter.palette.secondaryHex))
                tailFin(size)
                    .fill(Color(hex: encounter.palette.secondaryHex))
                    .overlay(alignment: .center) {
                        Text(operatorMark)
                            .font(.system(size: compact ? 5 : 9, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .offset(x: -size.width * 0.39, y: -size.height * 0.16)
                    }
                fuselage(size)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: encounter.palette.primaryHex).mix(with: .white, by: 0.72), Color(hex: encounter.palette.primaryHex).mix(with: .black, by: 0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(fuselage(size).stroke(Color.white.opacity(0.72), lineWidth: compact ? 0.6 : 1.1))
                liveryStripe(size)
                    .stroke(Color(hex: encounter.palette.accentHex), style: StrokeStyle(lineWidth: compact ? 2.2 : 5, lineCap: .round))
                if isJumbo { jumboDeck(size) }
                windows(size)
                engines(size)
                Text(encounter.aircraft.airline.uppercased())
                    .font(.system(size: compact ? 4.5 : 8, weight: .bold, design: .rounded))
                    .tracking(compact ? 0.2 : 0.8)
                    .foregroundStyle(Color(hex: encounter.palette.secondaryHex))
                    .position(x: size.width * 0.57, y: size.height * 0.47)
            }
        }
        .aspectRatio(2.15, contentMode: .fit)
        .accessibilityLabel("Side profile of \(encounter.aircraft.displayModel) in \(encounter.aircraft.livery ?? encounter.aircraft.airline) colors")
    }

    private var operatorMark: String {
        encounter.aircraft.airline.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }

    private func fuselage(_ size: CGSize) -> Path {
        Path { path in
            let w = size.width, h = size.height
            path.move(to: CGPoint(x: w * 0.07, y: h * 0.43))
            path.addCurve(to: CGPoint(x: w * 0.93, y: h * 0.42), control1: CGPoint(x: w * 0.25, y: h * 0.35), control2: CGPoint(x: w * 0.82, y: h * 0.36))
            path.addQuadCurve(to: CGPoint(x: w * 0.985, y: h * 0.50), control: CGPoint(x: w * 0.98, y: h * 0.42))
            path.addQuadCurve(to: CGPoint(x: w * 0.91, y: h * 0.56), control: CGPoint(x: w * 0.97, y: h * 0.56))
            path.addCurve(to: CGPoint(x: w * 0.08, y: h * 0.54), control1: CGPoint(x: w * 0.70, y: h * 0.60), control2: CGPoint(x: w * 0.24, y: h * 0.59))
            path.addQuadCurve(to: CGPoint(x: w * 0.07, y: h * 0.43), control: CGPoint(x: w * 0.025, y: h * 0.49))
            path.closeSubpath()
        }
    }

    private func tailFin(_ size: CGSize) -> Path {
        Path { path in
            let w = size.width, h = size.height
            path.move(to: CGPoint(x: w * 0.09, y: h * 0.45))
            path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.16))
            path.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.43), control: CGPoint(x: w * 0.18, y: h * 0.22))
            path.closeSubpath()
        }
    }

    private func wing(_ size: CGSize) -> Path {
        Path { path in
            let w = size.width, h = size.height
            let root = isWidebody ? 0.51 : 0.48
            path.move(to: CGPoint(x: w * root, y: h * 0.51))
            path.addLine(to: CGPoint(x: w * (root + 0.18), y: h * 0.86))
            path.addLine(to: CGPoint(x: w * (root + 0.25), y: h * 0.84))
            path.addLine(to: CGPoint(x: w * (root + 0.09), y: h * 0.50))
            path.closeSubpath()
        }
    }

    private func tailPlane(_ size: CGSize) -> Path {
        Path { path in
            let w = size.width, h = size.height
            path.move(to: CGPoint(x: w * 0.16, y: h * 0.48))
            path.addLine(to: CGPoint(x: w * 0.29, y: h * 0.65))
            path.addLine(to: CGPoint(x: w * 0.34, y: h * 0.64))
            path.addLine(to: CGPoint(x: w * 0.23, y: h * 0.47))
            path.closeSubpath()
        }
    }

    private func liveryStripe(_ size: CGSize) -> Path {
        Path { path in
            path.move(to: CGPoint(x: size.width * 0.09, y: size.height * 0.52))
            path.addQuadCurve(to: CGPoint(x: size.width * 0.92, y: size.height * 0.50), control: CGPoint(x: size.width * 0.52, y: size.height * 0.59))
        }
    }

    private func windows(_ size: CGSize) -> some View {
        HStack(spacing: compact ? 2.1 : 4.2) {
            ForEach(0..<(isWidebody ? 17 : 14), id: \.self) { _ in
                Capsule().fill(Color(hex: encounter.palette.secondaryHex).opacity(0.88))
                    .frame(width: compact ? 2.8 : 5.5, height: compact ? 1.4 : 2.8)
            }
        }
        .position(x: size.width * 0.58, y: size.height * 0.435)
    }

    @ViewBuilder private func engines(_ size: CGSize) -> some View {
        let engineWidth = size.width * (isWidebody ? 0.095 : 0.078)
        let engineHeight = size.height * (isWidebody ? 0.13 : 0.105)
        ZStack {
            Capsule().fill(Color(hex: encounter.palette.secondaryHex))
                .frame(width: engineWidth, height: engineHeight)
                .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: compact ? 0.5 : 1))
            Circle().fill(Color.black.opacity(0.72)).frame(width: engineHeight * 0.62, height: engineHeight * 0.62).offset(x: engineWidth * 0.34)
        }
        .position(x: size.width * 0.63, y: size.height * 0.66)
    }

    @ViewBuilder private func jumboDeck(_ size: CGSize) -> some View {
        Capsule().fill(Color.white.opacity(0.92))
            .frame(width: size.width * 0.31, height: size.height * 0.075)
            .position(x: size.width * 0.27, y: size.height * 0.39)
        HStack(spacing: compact ? 1.4 : 2.5) {
            ForEach(0..<7, id: \.self) { _ in Circle().fill(Color(hex: encounter.palette.secondaryHex)).frame(width: compact ? 1.6 : 3.2) }
        }
        .position(x: size.width * 0.28, y: size.height * 0.386)
    }

    private func aircraftShadow(_ size: CGSize) -> some View {
        Capsule().fill(Color.black.opacity(0.4))
            .frame(width: size.width * 0.72, height: size.height * 0.08)
            .blur(radius: compact ? 3 : 8)
            .position(x: size.width * 0.52, y: size.height * 0.76)
    }
}

private extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let fraction = CGFloat(min(max(amount, 0), 1))
        let first = UIColor(self), second = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        first.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        second.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: r1 + (r2 - r1) * fraction, green: g1 + (g2 - g1) * fraction, blue: b1 + (b2 - b1) * fraction)
    }
}
