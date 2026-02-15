import CoreLocation
import Foundation

struct RouteProgress {
    let destinationName: String
    let distanceRemainingMeters: CLLocationDistance
    let eta: Date
    let currentRoadName: String
    let nextManeuver: String

    var distanceDisplay: String {
        if distanceRemainingMeters >= 1000 {
            return String(format: "%.1f km", distanceRemainingMeters / 1000)
        }
        return "\(Int(distanceRemainingMeters.rounded())) m"
    }

    var etaDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
}
