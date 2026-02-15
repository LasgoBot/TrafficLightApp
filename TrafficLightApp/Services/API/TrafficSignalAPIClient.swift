import CoreLocation
import Foundation

protocol TrafficSignalRemoteServicing {
    func fetchSignal(latitude: Double, longitude: Double) async throws -> TrafficSignalDTO
}

struct TrafficSignalDTO: Codable {
    let intersectionID: String
    let intersectionName: String
    let latitude: Double
    let longitude: Double
    let phase: String
    let nextGreenEpochMs: Int64?
    let phaseEndsEpochMs: Int64?
    let confidence: Double
    let source: String
    let serverEpochMs: Int64

    func toDomain() -> TrafficSignal {
        let mappedPhase = SignalPhase(rawValue: phase.lowercased()) ?? .unknown
        return TrafficSignal(id: UUID(),
                             intersectionID: intersectionID,
                             intersectionName: intersectionName,
                             coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                             phase: mappedPhase,
                             nextGreenAt: nextGreenEpochMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
                             phaseEndsAt: phaseEndsEpochMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
                             confidence: confidence,
                             source: source,
                             serverTimestamp: Date(timeIntervalSince1970: TimeInterval(serverEpochMs) / 1000))
    }
}

enum APIError: Error {
    case missingConfiguration
    case invalidResponse
    case badStatus(Int)
}

struct TrafficSignalAPIClient: TrafficSignalRemoteServicing {
    private let session: URLSession
    private let baseURL: URL?

    init(session: URLSession = .shared,
         baseURL: URL? = AppConfiguration.backendBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchSignal(latitude: Double, longitude: Double) async throws -> TrafficSignalDTO {
        guard let baseURL else { throw APIError.missingConfiguration }

        var components = URLComponents(url: baseURL.appendingPathComponent("v1/signals/next"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude))
        ]

        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.badStatus(response.statusCode)
        }

        return try JSONDecoder().decode(TrafficSignalDTO.self, from: data)
    }
}
