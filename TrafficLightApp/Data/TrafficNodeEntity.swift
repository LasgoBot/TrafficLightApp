import Foundation
import SwiftData
import CoreLocation

@Model
final class TrafficNodeEntity {
    @Attribute(.unique) var geoID: String
    var latitude: Double
    var longitude: Double
    var cycleDuration: TimeInterval
    var lastGreenTimestamp: Date
    var confidenceScore: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(geoID: String, latitude: Double, longitude: Double, cycleDuration: TimeInterval = 0, lastGreenTimestamp: Date = Date(), confidenceScore: Int = 0) {
        self.geoID = geoID
        self.latitude = latitude
        self.longitude = longitude
        self.cycleDuration = cycleDuration
        self.lastGreenTimestamp = lastGreenTimestamp
        self.confidenceScore = confidenceScore
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func updateCycle(duration: TimeInterval, greenTimestamp: Date) {
        self.cycleDuration = duration
        self.lastGreenTimestamp = greenTimestamp
        self.updatedAt = Date()
        
        // Increase confidence with each update (max 100)
        self.confidenceScore = min(confidenceScore + 1, 100)
    }
}
