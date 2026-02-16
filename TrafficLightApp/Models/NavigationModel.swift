import CoreLocation
import Foundation
import MapKit

enum RoutePreference: String, Codable, CaseIterable {
    case fastest
    case shortest
    case avoidHighways
}

enum UnitPreference: String, Codable, CaseIterable {
    case mph
    case kmh
}

struct FavoriteLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let latitude: Double
    let longitude: Double
}

struct NavigationModel {
    var destination: MKMapItem?
    var eta: Date?
    var remainingDistanceMeters: CLLocationDistance = 0
    var nextInstruction: String = ""
    var nextInstructionDistanceMeters: CLLocationDistance = 0
    var speedLimitKPH: Double?
    var currentSpeedKPH: Double?

    var etaDisplay: String {
        guard let eta else { return "--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
}
