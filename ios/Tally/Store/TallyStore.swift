import Foundation

@MainActor
final class TallyStore: ObservableObject {
    @Published var encounters: [Encounter]
    @Published var transmissions: [Transmission]
    @Published var frequencies: [Frequency]
    @Published var selectedFrequency = "122.725"
    @Published var radarSession: RadarSession?
    @Published var statusMessage: String?
    @Published var isWorking = false
    @Published var isSignedIn = KeychainStore.sessionToken != nil

    let locationService = LocationService()

    let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        encounters = SeedData.encounters
        transmissions = SeedData.transmissions
        frequencies = SeedData.frequencies
        restoreState()
        if !environment.isDemo && isSignedIn { Task { await refresh() } }
    }

    var collected: [Encounter] { encounters.filter(\.isCollected) }
    var priorityContacts: [Encounter] { encounters.filter { $0.rarityScore >= 60 && !$0.isCollected } }

    func collect(_ encounter: Encounter) {
        guard let index = encounters.firstIndex(where: { $0.id == encounter.id }) else { return }
        encounters[index].isCollected = true
        persistState()
        if let baseURL = environment.apiBaseURL { Task { try? await APIClient(baseURL: baseURL).collect(encounterID: encounter.id) } }
    }

    func pass(_ encounter: Encounter) {
        encounters.removeAll { $0.id == encounter.id }
        persistState()
    }

    func startRadarSession(hours: Double = 2, radiusMiles: Double = 12) {
        locationService.beginUpdates()
        let coordinate = locationService.location?.coordinate
        radarSession = RadarSession(
            id: UUID(), startedAt: .now, endsAt: .now.addingTimeInterval(hours * 3600),
            latitude: coordinate?.latitude ?? 36.1263,
            longitude: coordinate?.longitude ?? -86.6774,
            radiusMiles: radiusMiles
        )
        persistState()
        if let radarSession, !environment.isDemo { Task { await syncRadarSession(radarSession) } }
    }

    func stopRadarSession() {
        radarSession = nil
        locationService.stopUpdates()
        persistState()
    }

    func signIn(identityToken: String) async {
        guard let baseURL = environment.apiBaseURL else { isSignedIn = true; return }
        isWorking = true
        defer { isWorking = false }
        do {
            KeychainStore.sessionToken = try await APIClient(baseURL: baseURL).exchangeApple(identityToken: identityToken)
            isSignedIn = true
            statusMessage = "Signed in"
            await registerDeviceIfAvailable()
            await refresh()
        } catch { statusMessage = error.localizedDescription }
    }

    func signOut() {
        KeychainStore.sessionToken = nil
        isSignedIn = false
    }

    private func syncRadarSession(_ radar: RadarSession) async {
        guard let baseURL = environment.apiBaseURL else { return }
        do { try await APIClient(baseURL: baseURL).createRadarSession(radar) }
        catch { statusMessage = error.localizedDescription }
    }

    func refresh() async {
        guard let baseURL = environment.apiBaseURL, isSignedIn else { return }
        do {
            let live = try await APIClient(baseURL: baseURL).encounters()
            if !live.isEmpty { encounters = live; persistState() }
        } catch { statusMessage = error.localizedDescription }
    }

    func registerDeviceIfAvailable() async {
        guard let baseURL = environment.apiBaseURL,
              let token = UserDefaults.standard.string(forKey: "tally.apns.token"), isSignedIn else { return }
        #if DEBUG
        let apnsEnvironment = "development"
        #else
        let apnsEnvironment = "production"
        #endif
        try? await APIClient(baseURL: baseURL).registerDevice(token: token, environment: apnsEnvironment)
    }

    func transmit(encounter: Encounter, message: String) async {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isWorking = true
        defer { isWorking = false }
        if let baseURL = environment.apiBaseURL {
            do { try await APIClient(baseURL: baseURL).publish(frequency: selectedFrequency, encounter: encounter, body: trimmed, authorID: "local-caleb") }
            catch { statusMessage = error.localizedDescription; return }
        }
        let post = Transmission(id: UUID(), author: "Caleb", handle: "@caleb", frequency: selectedFrequency, message: trimmed, encounter: encounter, reactions: 0, comments: 0, postedAt: .now)
        transmissions.insert(post, at: 0)
        statusMessage = "Transmission sent on \(selectedFrequency)"
    }

    private func persistState() {
        let collectedIDs = encounters.filter(\.isCollected).map(\.id.uuidString)
        UserDefaults.standard.set(collectedIDs, forKey: "tally.collected.ids")
        UserDefaults.standard.set(selectedFrequency, forKey: "tally.selected.frequency")
        if let radarSession, let data = try? JSONEncoder().encode(radarSession) { UserDefaults.standard.set(data, forKey: "tally.radar.session") }
        else { UserDefaults.standard.removeObject(forKey: "tally.radar.session") }
    }

    private func restoreState() {
        let collected = Set(UserDefaults.standard.stringArray(forKey: "tally.collected.ids") ?? [])
        for index in encounters.indices where collected.contains(encounters[index].id.uuidString) { encounters[index].isCollected = true }
        selectedFrequency = UserDefaults.standard.string(forKey: "tally.selected.frequency") ?? selectedFrequency
        if let data = UserDefaults.standard.data(forKey: "tally.radar.session"), let saved = try? JSONDecoder().decode(RadarSession.self, from: data), saved.isActive { radarSession = saved }
    }
}
