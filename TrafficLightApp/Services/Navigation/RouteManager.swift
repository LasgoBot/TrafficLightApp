import CoreLocation
import Foundation
import MapKit

protocol RouteManaging {
    func searchCompletions(for query: String) -> [String]
    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: MKMapItem,
                        preference: RoutePreference) async throws -> MKRoute
}

final class RouteManager: RouteManaging {
    private var recentQueries: [String] = []

    func searchCompletions(for query: String) -> [String] {
        guard !query.isEmpty else { return recentQueries }
        let mock = ["Home", "Work", "Airport", "Downtown", "Parking Garage"]
        let filtered = mock.filter { $0.localizedCaseInsensitiveContains(query) }
        if let first = filtered.first, !recentQueries.contains(first) {
            recentQueries.insert(first, at: 0)
            recentQueries = Array(recentQueries.prefix(10))
        }
        return filtered
    }

    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: MKMapItem,
                        preference: RoutePreference) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true

        switch preference {
        case .avoidHighways:
            request.transportType = .automobile
        case .fastest, .shortest:
            break
        }

        let response = try await MKDirections(request: request).calculate()
        guard let selected = selectRoute(from: response.routes, preference: preference) else {
            throw NSError(domain: "RouteManager", code: 404)
        }
        return selected
    }

    private func selectRoute(from routes: [MKRoute], preference: RoutePreference) -> MKRoute? {
        switch preference {
        case .fastest:
            return routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime })
        case .shortest:
            return routes.min(by: { $0.distance < $1.distance })
        case .avoidHighways:
            return routes.first
        }
    }
}
