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
}
