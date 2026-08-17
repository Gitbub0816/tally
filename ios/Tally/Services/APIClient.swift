import Foundation

enum APIClientError: LocalizedError {
    case invalidResponse
    case server(Int)
    var errorDescription: String? {
        switch self { case .invalidResponse: "The server returned an unreadable response."; case .server(let status): "The server returned status \(status)." }
    }
}

struct APIClient {
    let baseURL: URL
    let session: URLSession
    init(baseURL: URL, session: URLSession = .shared) { self.baseURL = baseURL; self.session = session }

    func health() async throws {
        let (_, response) = try await session.data(from: baseURL.appending(path: "v1/health"))
        try validate(response)
    }

    func publish(frequency: String, encounter: Encounter, body: String, authorID: String) async throws {
        var request = request(path: "v1/frequencies/\(frequency)/transmissions")
        request.httpBody = try JSONEncoder().encode(PublishPayload(authorId: authorID, body: body, encounterId: encounter.id.uuidString))
        let (_, response) = try await session.data(for: request); try validate(response)
    }

    func exchangeApple(identityToken: String) async throws -> String {
        var request = request(path: "v1/auth/apple", authenticated: false)
        request.httpBody = try JSONEncoder().encode(ApplePayload(identityToken: identityToken))
        let (data, response) = try await session.data(for: request); try validate(response)
        return try JSONDecoder().decode(SessionPayload.self, from: data).token
    }

    func createRadarSession(_ radar: RadarSession) async throws {
        var request = request(path: "v1/radar-sessions")
        request.httpBody = try JSONEncoder().encode(RadarPayload(latitude: radar.latitude, longitude: radar.longitude, radiusMeters: Int(radar.radiusMiles * 1_609.344), startsAt: ISO8601DateFormatter().string(from: radar.startedAt), endsAt: ISO8601DateFormatter().string(from: radar.endsAt)))
        let (_, response) = try await session.data(for: request); try validate(response)
    }

    func encounters() async throws -> [Encounter] {
        var request = request(path: "v1/encounters"); request.httpMethod = "GET"; request.httpBody = nil
        let (data, response) = try await session.data(for: request); try validate(response)
        return try JSONDecoder().decode(EncounterEnvelope.self, from: data).encounters.map(\.model)
    }

    func collect(encounterID: UUID) async throws {
        let (_, response) = try await session.data(for: request(path: "v1/encounters/\(encounterID.uuidString)/collect")); try validate(response)
    }

    func registerDevice(token: String, environment: String) async throws {
        var value = request(path: "v1/devices")
        value.httpBody = try JSONEncoder().encode(DevicePayload(token: token, environment: environment))
        let (_, response) = try await session.data(for: value); try validate(response)
    }

    private func request(path: String, authenticated: Bool = true) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path)); request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        if authenticated, let token = KeychainStore.sessionToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization") }
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIClientError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw APIClientError.server(http.statusCode) }
    }
}

private struct PublishPayload: Encodable { let authorId: String; let body: String; let encounterId: String }
private struct ApplePayload: Encodable { let identityToken: String }
private struct SessionPayload: Decodable { let token: String }
private struct RadarPayload: Encodable { let latitude: Double; let longitude: Double; let radiusMeters: Int; let startsAt: String; let endsAt: String }
private struct DevicePayload: Encodable { let token: String; let environment: String }
private struct EncounterEnvelope: Decodable { let encounters: [EncounterPayload] }
private struct EncounterPayload: Decodable {
    let id: UUID; let registration: String; let manufacturer: String; let aircraftModel: String
    let operator_name: String?; let flight_number: String?; let origin_iata: String?; let destination_iata: String?
    let observed_at: String; let altitude_feet: Int?; let rarity_score: Int; let rarity: RarityTier; let collected_at: String?

    var model: Encounter {
        let date = ISO8601DateFormatter().date(from: observed_at) ?? .now
        let colors = CardPalette(primaryHex: "#D8D5C8", secondaryHex: "#25384A", accentHex: "#BDA76B")
        return Encounter(id: id, aircraft: Aircraft(id: registration, manufacturer: manufacturer, model: aircraftModel, variant: aircraftModel,
          registration: registration, airline: operator_name ?? "Private", livery: nil, yearBuilt: 0, engines: "Aircraft data pending",
          cruiseSpeedKnots: 0, rangeNauticalMiles: 0, seats: 0), flightNumber: flight_number ?? "—", origin: origin_iata ?? "—",
          destination: destination_iata ?? "—", capturedAt: date, distanceMiles: 0, altitudeFeet: altitude_feet ?? 0,
          headingDegrees: 0, bearingDegrees: 0, rarity: rarity, rarityScore: rarity_score, rarityReasons: ["Scored from current type, operator, and local scarcity"],
          palette: colors, isCollected: collected_at != nil)
    }
    enum CodingKeys: String, CodingKey {
        case id, registration, manufacturer, operator_name, flight_number, origin_iata, destination_iata, observed_at, altitude_feet, rarity_score, rarity, collected_at
        case aircraftModel = "model"
    }
}
