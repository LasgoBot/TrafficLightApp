import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct TrafficActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes
        var trafficLightState: TrafficLightState
        var countdownSeconds: Int
        var targetSpeed: Int // mph
        var lastUpdate: Date
    }
    
    // Static data that doesn't change
    var intersectionName: String
    var geoID: String
}

enum TrafficLightState: String, Codable, Hashable {
    case red
    case yellow
    case green
    case unknown
    
    var displayColor: String {
        switch self {
        case .red: return "🔴"
        case .yellow: return "🟡"
        case .green: return "🟢"
        case .unknown: return "⚪️"
        }
    }
}
