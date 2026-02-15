import CoreLocation
import Foundation
import MapKit

protocol NavigationServicing {
    func estimateProgress(currentLocation: CLLocation?, destination: MKMapItem?) -> RouteProgress?
}

struct NavigationService: NavigationServicing {
    func estimateProgress(currentLocation: CLLocation?, destination: MKMapItem?) -> RouteProgress? {
        guard let currentLocation, let destination else {
            return nil
        }

        let destinationLocation = CLLocation(latitude: destination.placemark.coordinate.latitude,
                                             longitude: destination.placemark.coordinate.longitude)
        let distance = currentLocation.distance(from: destinationLocation)
        let avgCitySpeedMetersPerSecond = 11.0
        let eta = Date().addingTimeInterval(distance / avgCitySpeedMetersPerSecond)

        return RouteProgress(destinationName: destination.name ?? "Destination",
                             distanceRemainingMeters: distance,
                             eta: eta,
                             currentRoadName: destination.placemark.thoroughfare ?? "Current road",
                             nextManeuver: distance > 200 ? "Continue straight" : "Prepare to arrive")
    }
}
