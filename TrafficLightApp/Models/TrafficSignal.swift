import CoreLocation
import Foundation

enum SignalPhase: String, Codable, CaseIterable {
    case red
    case yellow
    case green
    case unknown

    var title: String {
        switch self {
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .unknown: return "Unknown"
        }
    }
}

struct TrafficSignal: Identifiable, Codable {
    let id: UUID
    let intersectionID: String
    let intersectionName: String
    let coordinate: CLLocationCoordinate2D
    let phase: SignalPhase
    let nextGreenAt: Date?
    let phaseEndsAt: Date?
    let confidence: Double
    let source: String
    let serverTimestamp: Date

    var countdownToGreen: Int? {
        guard let nextGreenAt else { return nil }
        return max(0, Int(nextGreenAt.timeIntervalSinceNow.rounded(.down)))
    }

    var phaseCountdown: Int? {
        guard let phaseEndsAt else { return nil }
        return max(0, Int(phaseEndsAt.timeIntervalSinceNow.rounded(.down)))
    }

    var isProductionGrade: Bool {
        confidence >= 0.85 && source.lowercased() != "heuristic"
    }
}

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
