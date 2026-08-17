import Foundation

enum AircraftModelAsset: String, CaseIterable {
    case airbusA220300 = "airbus_a220_300"
    case airbusA320200 = "airbus_a320_200"
    case airbusA380 = "airbus_a380"
    case boeing737800 = "boeing_737_800"
    case boeing757200 = "boeing_757_200"
    case cessna152 = "cessna_152"

    static func resolve(for aircraft: Aircraft) -> AircraftModelAsset? {
        let manufacturer = normalized(aircraft.manufacturer)
        let model = normalized(aircraft.model)

        if manufacturer.contains("airbus") {
            if model.contains("a220300") { return .airbusA220300 }
            if model.contains("a320200") { return .airbusA320200 }
            if model == "a380" || model.hasPrefix("a380") { return .airbusA380 }
        }

        if manufacturer.contains("boeing") {
            if model.contains("737800") || model.contains("737839b") { return .boeing737800 }
            if model.contains("757200") { return .boeing757200 }
        }

        if manufacturer.contains("cessna"), (model == "152" || model.contains("cessna152")) {
            return .cessna152
        }

        return nil
    }

    private static func normalized(_ value: String) -> String {
        String(value.lowercased().filter { $0.isLetter || $0.isNumber })
    }
}
