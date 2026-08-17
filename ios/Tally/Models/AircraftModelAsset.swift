import Foundation

enum AircraftModelAsset: String, CaseIterable {
    case boeing757200 = "boeing_757_200"
    case boeing7879 = "boeing_787_9"

    var presentationYawRadians: Float {
        switch self {
        case .boeing757200, .boeing7879:
            return .pi / 2
        }
    }

    static func resolve(for aircraft: Aircraft) -> AircraftModelAsset? {
        let manufacturer = normalized(aircraft.manufacturer)
        let model = normalized(aircraft.model)

        if manufacturer.contains("boeing") {
            if model.contains("757200") { return .boeing757200 }
            if model.contains("7879") { return .boeing7879 }
        }

        return nil
    }

    private static func normalized(_ value: String) -> String {
        String(value.lowercased().filter { $0.isLetter || $0.isNumber })
    }
}
