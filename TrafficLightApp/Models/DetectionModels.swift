import CoreGraphics
import Foundation

enum DetectionCategory: String, Codable, CaseIterable {
    case lane
    case trafficSign
    case vehicle
    case speedLimit
}

struct DetectionObservation: Identifiable, Equatable {
    let id = UUID()
    let category: DetectionCategory
    let confidence: Float
    let boundingBox: CGRect
    let label: String
}

struct DriveSafetyState: Equatable {
    var ambientLightScore: Float
    var glareScore: Float
    var obstructionScore: Float

    var isReliable: Bool {
        ambientLightScore > 0.25 && glareScore < 0.55 && obstructionScore < 0.5
    }

    static let unknown = DriveSafetyState(ambientLightScore: 0.5, glareScore: 0.2, obstructionScore: 0.2)
}

struct DetectionPreferences: Codable, Equatable {
    var laneDetectionEnabled = true
    var signDetectionEnabled = true
    var vehicleDistanceEnabled = true
    var speedLimitEnabled = true

    var minimumConfidence: Float = 0.65
    var maxProcessingFPS: Double = 30
    var enableHaptics = true

    static let `default` = DetectionPreferences()
}
