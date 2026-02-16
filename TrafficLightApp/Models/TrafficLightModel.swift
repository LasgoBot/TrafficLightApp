import CoreGraphics
import Foundation

enum TrafficLightState: String, Codable, CaseIterable {
    case red
    case yellow
    case green
    case unknown
}

struct TrafficLightDetection: Identifiable, Equatable {
    let id = UUID()
    let state: TrafficLightState
    let confidence: Float
    let boundingBox: CGRect
    let detectedAt: Date
}

struct TrafficLightCountdown {
    let secondsRemaining: Int
    let showCountdown: Bool
}

struct TrafficLightModel {
    static func countdown(from detection: TrafficLightDetection?, predictedGreenAt: Date?) -> TrafficLightCountdown {
        guard let detection,
              detection.state != .green,
              detection.confidence >= 0.85,
              let predictedGreenAt else {
            return TrafficLightCountdown(secondsRemaining: 0, showCountdown: false)
        }

        let seconds = max(0, Int(predictedGreenAt.timeIntervalSinceNow.rounded(.down)))
        return TrafficLightCountdown(secondsRemaining: seconds, showCountdown: seconds <= 10)
    }
}
