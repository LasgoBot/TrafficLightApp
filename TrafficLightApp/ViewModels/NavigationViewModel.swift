import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class NavigationViewModel: ObservableObject {
    @Published var model = NavigationModel()
    @Published var route: MKRoute?
    @Published var routePreference: RoutePreference = .fastest
    @Published var searchQuery = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var searchError: String?
    @Published var recent: [FavoriteLocation] = []
    @Published var voiceGuidanceEnabled = true

    let locationManager = LocationManager()

    private let routeManager: RouteManaging
    private let speechManager: SpeechManager

    init(routeManager: RouteManaging = RouteManager(),
         speechManager: SpeechManager = SpeechManager()) {
        self.routeManager = routeManager
        self.speechManager = speechManager
    }

    func start() {
        locationManager.requestWhenInUse()
        locationManager.requestAlways()
    }

    func updateSearch() {
        routeManager.updateSearchQuery(searchQuery)
        searchResults = routeManager.latestSearchResults()
    }

    func setDestination(completion: MKLocalSearchCompletion) async {
        do {
            let mapItem = try await routeManager.resolveCompletion(completion)
            await setDestination(mapItem)
        } catch {
            searchError = "Could not resolve destination."
        }
    }

    func setDestination(_ item: MKMapItem) async {
        model.destination = item
        guard let source = locationManager.location?.coordinate else {
            searchError = "Current location unavailable."
            return
        }

        do {
            let route = try await routeManager.calculateRoute(from: source, to: item, preference: routePreference)
            self.route = route
            model.eta = Date().addingTimeInterval(route.expectedTravelTime)
            model.remainingDistanceMeters = route.distance
            if let firstStep = route.steps.first(where: { !$0.instructions.isEmpty }) {
                model.nextInstruction = firstStep.instructions
                model.nextInstructionDistanceMeters = firstStep.distance
            }
            model.speedLimitKPH = inferSpeedLimit(from: route)
            persistRecent(mapItem: item)
            searchError = nil
            speechManager.speak("Route started. \(model.nextInstruction)", enabled: voiceGuidanceEnabled)
        } catch {
            searchError = "Unable to route to selected destination."
            model.nextInstruction = "Unable to route."
        }
    }

    func updateSpeed() {
        model.currentSpeedKPH = locationManager.speedKPH
        if model.speedLimitKPH == nil {
            model.speedLimitKPH = 50
        }
    }

    func rerouteIfNeeded(currentCoordinate: CLLocationCoordinate2D) async {
        guard let route, let destination = model.destination else { return }
        let routeLine = route.polyline.boundingMapRect
        let current = MKMapPoint(currentCoordinate)
        let offRoute = !routeLine.insetBy(dx: -200, dy: -200).contains(current)
        if offRoute {
            await setDestination(destination)
            speechManager.speak("Rerouting", enabled: voiceGuidanceEnabled)
        }
    }

    private func inferSpeedLimit(from route: MKRoute) -> Double {
        if route.distance < 3000 { return 35 }
        if route.distance < 8000 { return 50 }
        return 65
    }

    private func persistRecent(mapItem: MKMapItem) {
        let entry = FavoriteLocation(id: UUID(),
                                     title: mapItem.name ?? "Destination",
                                     latitude: mapItem.placemark.coordinate.latitude,
                                     longitude: mapItem.placemark.coordinate.longitude)
        recent.removeAll(where: { $0.title == entry.title })
        recent.insert(entry, at: 0)
        recent = Array(recent.prefix(8))
    }
}
