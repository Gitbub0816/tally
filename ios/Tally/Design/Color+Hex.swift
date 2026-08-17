import SwiftUI

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        let red, green, blue: UInt64
        switch value.count {
        case 3:
            (red, green, blue) = ((number >> 8) * 17, (number >> 4 & 0xF) * 17, (number & 0xF) * 17)
        default:
            (red, green, blue) = (number >> 16, number >> 8 & 0xFF, number & 0xFF)
        }
        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: 1)
    }
}

