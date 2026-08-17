import XCTest
@testable import Tally

@MainActor
final class TallyStoreTests: XCTestCase {
    func testCollectMovesEncounterIntoCollection() {
        let store = TallyStore(environment: .demo)
        let encounter = store.encounters.first { !$0.isCollected }!
        let priorCount = store.collected.count
        store.collect(encounter)
        XCTAssertEqual(store.collected.count, priorCount + 1)
    }

    func testPriorityContactsRequireScoreOfSixty() {
        let store = TallyStore(environment: .demo)
        XCTAssertTrue(store.priorityContacts.allSatisfy { $0.rarityScore >= 60 })
    }

    func testRadarSessionCanStartAndStop() {
        let store = TallyStore(environment: .demo)
        store.startRadarSession(hours: 2, radiusMiles: 12)
        XCTAssertTrue(store.radarSession?.isActive == true)
        store.stopRadarSession()
        XCTAssertNil(store.radarSession)
    }

    func testAircraftAssetsResolveOnlyApprovedTypes() {
        let boeing737 = aircraft(manufacturer: "Boeing", model: "737-800")
        XCTAssertEqual(AircraftModelAsset.resolve(for: boeing737), .boeing737800)

        let boeing737700 = aircraft(manufacturer: "Boeing", model: "737-700")
        XCTAssertEqual(AircraftModelAsset.resolve(for: boeing737700), .boeing737800)

        let boeing757 = aircraft(manufacturer: "Boeing", model: "757-200")
        XCTAssertEqual(AircraftModelAsset.resolve(for: boeing757), .boeing757200)

        let boeing787 = aircraft(manufacturer: "Boeing", model: "787-9")
        XCTAssertEqual(AircraftModelAsset.resolve(for: boeing787), .boeing7879)

        let unverifiedBoeingVariant = aircraft(manufacturer: "Boeing", model: "737-700")
        XCTAssertNil(AircraftModelAsset.resolve(for: unverifiedBoeingVariant))

        let unavailableAirbus = aircraft(manufacturer: "Airbus", model: "A220-300")
        XCTAssertNil(AircraftModelAsset.resolve(for: unavailableAirbus))

    }

    private func aircraft(manufacturer: String, model: String) -> Aircraft {
        Aircraft(
            id: "TEST", manufacturer: manufacturer, model: model, variant: model,
            registration: "N00000", airline: "Test", livery: nil, yearBuilt: 0,
            engines: "Test", cruiseSpeedKnots: 0, rangeNauticalMiles: 0, seats: 0
        )
    }
}
