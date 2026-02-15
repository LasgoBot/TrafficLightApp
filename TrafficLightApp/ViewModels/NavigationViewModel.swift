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
    @Published var searchResults: [String] = []
    @Published var recent: [FavoriteLocation] = []

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
        searchResults = routeManager.searchCompletions(for: searchQuery)
    }

    func setDestination(_ item: MKMapItem) async {
        model.destination = item
        guard let source = locationManager.location?.coordinate else { return }

        do {
            let route = try await routeManager.calculateRoute(from: source, to: item, preference: routePreference)
            self.route = route
            model.eta = Date().addingTimeInterval(route.expectedTravelTime)
            model.remainingDistanceMeters = route.distance
            if let firstStep = route.steps.first(where: { !$0.instructions.isEmpty }) {
                model.nextInstruction = firstStep.instructions
                model.nextInstructionDistanceMeters = firstStep.distance
            }
            speechManager.speak("Route started. \(model.nextInstruction)", enabled: true)
        } catch {
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
            speechManager.speak("Rerouting", enabled: true)
        }
    }
}
