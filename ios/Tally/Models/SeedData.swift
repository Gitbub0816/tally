import Foundation

enum SeedData {
    static let encounters: [Encounter] = [
        encounter("N8620H", "Boeing", "737-800", airline: "Southwest", livery: "Tennessee One", flight: "WN 1846", route: ("BNA", "DAL"), distance: 0.7, altitude: 3_200, rarity: .singular, score: 94, reasons: ["One active aircraft wears this livery", "Locally meaningful Tennessee scheme", "Your first Tennessee One tally"], colors: ("#C8102E", "#0C2340", "#FFFFFF")),
        encounter("N833AN", "Boeing", "787-9", airline: "American Airlines", livery: "Silver Eagle", flight: "AA 51", route: ("LHR", "DFW"), distance: 4.2, altitude: 37_000, rarity: .rare, score: 76, reasons: ["Widebody overflight uncommon locally", "First 787-9 this month"], colors: ("#B9BEC4", "#253C73", "#C9373D")),
        encounter("N508DN", "Airbus", "A350-900", airline: "Delta Air Lines", livery: nil, flight: "DL 295", route: ("ATL", "HND"), distance: 6.8, altitude: 34_000, rarity: .exceptional, score: 84, reasons: ["A350 appears here infrequently", "Long-haul route outside normal corridor"], colors: ("#F1F0EA", "#142B52", "#A51D2D")),
        encounter("N928AN", "Boeing", "737-800", airline: "American Airlines", livery: nil, flight: "AA 2187", route: ("DFW", "BNA"), distance: 1.3, altitude: 4_800, rarity: .frequent, score: 23, reasons: ["Common type and operator at BNA"], colors: ("#C6C9CA", "#263D70", "#C33942")),
        encounter("N226NV", "Airbus", "A320neo", airline: "Spirit Airlines", livery: "Yellow", flight: "NK 1169", route: ("FLL", "BNA"), distance: 2.1, altitude: 6_100, rarity: .notable, score: 42, reasons: ["New registration for your collection"], colors: ("#F4D522", "#171717", "#F4D522")),
        encounter("N110DU", "Airbus", "A220-300", airline: "Delta Air Lines", livery: nil, flight: "DL 1674", route: ("BNA", "LGA"), distance: 0.9, altitude: 2_900, rarity: .notable, score: 48, reasons: ["A220 is less common than local narrowbodies"], colors: ("#F0F0ED", "#18335B", "#A51D2D")),
        encounter("N670US", "Boeing", "747-400", airline: "Atlas Air", livery: nil, flight: "5Y 8174", route: ("HSV", "CVG"), distance: 8.4, altitude: 28_000, rarity: .exceptional, score: 89, reasons: ["747 sightings are declining globally", "Unusual operator and corridor locally"], colors: ("#ECEBE3", "#20477C", "#D9B649")),
        encounter("N921WN", "Boeing", "737-700", airline: "Southwest", livery: "Classic Canyon Blue", flight: "WN 2260", route: ("BNA", "MDW"), distance: 1.6, altitude: 5_500, rarity: .rare, score: 68, reasons: ["Retired heritage color treatment", "Familiar operator, unusual livery"], colors: ("#2860A4", "#C83C34", "#E5B941"))
    ]

    static let frequencies = [
        Frequency(id: UUID(), channel: "122.725", name: "BNA Spotters", memberCount: 418, isPrivate: false),
        Frequency(id: UUID(), channel: "128.425", name: "Caleb’s Flightline", memberCount: 14, isPrivate: true),
        Frequency(id: UUID(), channel: "135.925", name: "Special Liveries", memberCount: 2_804, isPrivate: false)
    ]

    static var transmissions: [Transmission] {
        [
            Transmission(id: UUID(), author: "Mara V.", handle: "@vectorsouth", frequency: "122.725", message: "Tennessee One on the arrival—perfect light over the field.", encounter: encounters[0], reactions: 184, comments: 23, postedAt: .now.addingTimeInterval(-780)),
            Transmission(id: UUID(), author: "Evan Cross", handle: "@heavywake", frequency: "135.925", message: "An unexpected Queen crossing the Nashville corridor.", encounter: encounters[6], reactions: 321, comments: 41, postedAt: .now.addingTimeInterval(-4_200))
        ]
    }

    private static func encounter(_ reg: String, _ maker: String, _ model: String, airline: String, livery: String?, flight: String, route: (String, String), distance: Double, altitude: Int, rarity: RarityTier, score: Int, reasons: [String], colors: (String, String, String)) -> Encounter {
        let stableID = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", score * 100_000 + altitude))!
        return Encounter(id: stableID, aircraft: Aircraft(id: reg, manufacturer: maker, model: model, variant: model, registration: reg, airline: airline, livery: livery, yearBuilt: 2018, engines: "Twin turbofan", cruiseSpeedKnots: 490, rangeNauticalMiles: 3_500, seats: 175), flightNumber: flight, origin: route.0, destination: route.1, capturedAt: .now.addingTimeInterval(Double(-score * 137)), distanceMiles: distance, altitudeFeet: altitude, headingDegrees: (score * 37) % 360, bearingDegrees: (score * 53) % 360, rarity: rarity, rarityScore: score, rarityReasons: reasons, palette: CardPalette(primaryHex: colors.0, secondaryHex: colors.1, accentHex: colors.2), isCollected: reg == "N921WN")
    }
}
