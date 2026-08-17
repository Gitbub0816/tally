import Foundation

enum RarityTier: String, Codable, CaseIterable {
    case frequent, notable, rare, exceptional, singular

    var title: String { rawValue.uppercased() }
}

struct Aircraft: Identifiable, Codable, Hashable {
    let id: String
    let manufacturer: String
    let model: String
    let variant: String
    let registration: String
    let airline: String
    let livery: String?
    let yearBuilt: Int
    let engines: String
    let cruiseSpeedKnots: Int
    let rangeNauticalMiles: Int
    let seats: Int

    var displayModel: String { "\(manufacturer) \(model)" }
}

struct Encounter: Identifiable, Codable, Hashable {
    let id: UUID
    let aircraft: Aircraft
    let flightNumber: String
    let origin: String
    let destination: String
    let capturedAt: Date
    let distanceMiles: Double
    let altitudeFeet: Int
    let headingDegrees: Int
    let rarity: RarityTier
    let rarityScore: Int
    let rarityReasons: [String]
    let palette: CardPalette
    var isCollected: Bool

    var route: String { "\(origin) → \(destination)" }
}

struct CardPalette: Codable, Hashable {
    let primaryHex: String
    let secondaryHex: String
    let accentHex: String
}

struct Frequency: Identifiable, Hashable {
    let id: UUID
    let channel: String
    let name: String
    let memberCount: Int
    let isPrivate: Bool
}

struct Transmission: Identifiable, Hashable {
    let id: UUID
    let author: String
    let handle: String
    let frequency: String
    let message: String
    let encounter: Encounter
    let reactions: Int
    let comments: Int
    let postedAt: Date
}

struct RadarSession: Codable, Hashable {
    let id: UUID
    let startedAt: Date
    let endsAt: Date
    let latitude: Double
    let longitude: Double
    let radiusMiles: Double

    var isActive: Bool { endsAt > .now }
}
