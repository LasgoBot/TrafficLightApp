import CoreGraphics
import Foundation

enum DetectionType: String, CaseIterable {
    case lane
    case trafficSign
    case vehicle
    case speedLimit
    case trafficLight
}

struct DetectionResult: Identifiable, Equatable {
    let id = UUID()
    let type: DetectionType
    let confidence: Float
    let boundingBox: CGRect
    let title: String
}

struct DetectionConfiguration: Equatable {
    var isLaneDetectionEnabled = true
    var isSignDetectionEnabled = true
    var isVehicleMonitoringEnabled = true
    var isSpeedLimitDetectionEnabled = true
    var isTrafficLightDetectionEnabled = true
    var alertSensitivity: Float = 0.7
    var maxFPS: Double = 30
    var voiceGuidanceEnabled = true
    var pipEnabled = true
    var preferredUnits: UnitPreference = .mph
    var map3DEnabled = true
    var nightModeEnabled = false
}
