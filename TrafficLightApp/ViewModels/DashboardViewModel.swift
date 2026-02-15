import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class DashboardViewModel: ObservableObject {
    enum ViewState {
        case idle
        case ready
        case warning(String)
    }

    @Published var signal: TrafficSignal?
    @Published var routeProgress: RouteProgress?
    @Published var selectedDestination: MKMapItem?
    @Published var state: ViewState = .idle

    let locationService: LocationService
    let predictionModeLabel: String

    private let trafficSignalService: TrafficSignalProviding
    private let navigationService: NavigationServicing
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    init(locationService: LocationService = LocationService(),
         trafficSignalService: TrafficSignalProviding = TrafficSignalService(),
         navigationService: NavigationServicing = NavigationService()) {
        self.locationService = locationService
        self.trafficSignalService = trafficSignalService
        self.navigationService = navigationService
        self.predictionModeLabel = AppConfiguration.predictionMode.rawValue

        bind()
        locationService.requestAccess()
        startTimer()
    }

    deinit {
        timerCancellable?.cancel()
        locationService.stop()
    }

    func setDestination(_ destination: MKMapItem) {
        selectedDestination = destination
        updateRoute()
    }

    func refreshSignal() {
        Task {
            let prediction = await trafficSignalService.signalPrediction(near: locationService.currentLocation?.coordinate)
            signal = prediction

            guard let prediction else {
                state = .idle
                return
            }

            if prediction.confidence < AppConfiguration.lowConfidenceThreshold {
                state = .warning("Confidence too low for trusted countdown. Drive by road signal only.")
            } else {
                state = .ready
            }
            updateRoute()
        }
    }

    private func bind() {
        locationService.$currentLocation
            .sink { [weak self] _ in
                self?.refreshSignal()
            }
            .store(in: &cancellables)
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: AppConfiguration.signalPollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshSignal()
            }
    }

    private func updateRoute() {
        routeProgress = navigationService.estimateProgress(currentLocation: locationService.currentLocation,
                                                           destination: selectedDestination)
    }
}
