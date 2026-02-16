import CoreLocation
import Foundation
import MapKit

protocol RouteManaging {
    func searchCompletions(for query: String) -> [String]
    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: MKMapItem,
                        preference: RoutePreference) async throws -> MKRoute
}

@MainActor
final class RouteManager: NSObject, RouteManaging {
    private let completer = MKLocalSearchCompleter()
    private var cachedResults: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.resultTypes = [.address, .pointOfInterest, .query]
        completer.delegate = self
    }

    func updateSearchQuery(_ query: String) {
        completer.queryFragment = query
    }

    func latestSearchResults() -> [MKLocalSearchCompletion] {
        cachedResults
    }

    func resolveCompletion(_ completion: MKLocalSearchCompletion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        guard let first = response.mapItems.first else {
            throw NSError(domain: "RouteManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No matching destination found"])
        }
        return first
    }

    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: MKMapItem,
                        preference: RoutePreference) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true

        let response = try await MKDirections(request: request).calculate()
        guard let selected = selectRoute(from: response.routes, preference: preference) else {
            throw NSError(domain: "RouteManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No route available"])
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
            return routes.sorted(by: { $0.advisoryNotices.count < $1.advisoryNotices.count }).first
        }
    }
}

extension RouteManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        cachedResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        cachedResults = []
    }
}
