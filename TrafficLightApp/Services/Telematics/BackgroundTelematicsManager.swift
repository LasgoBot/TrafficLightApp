import CoreLocation
import Foundation

@MainActor
final class BackgroundTelematicsManager: NSObject, ObservableObject {
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let telematicsService: TelematicsService
    
    @Published private(set) var isBackgroundEnabled = false
    
    // MARK: - Initialization
    init(telematicsService: TelematicsService = TelematicsService()) {
        self.telematicsService = telematicsService
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    func enableBackgroundMode() {
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startMonitoringVisits()
        locationManager.startUpdatingLocation()
        
        telematicsService.startMonitoring()
        isBackgroundEnabled = true
    }
    
    func disableBackgroundMode() {
        locationManager.stopMonitoringVisits()
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        
        telematicsService.stopMonitoring()
        isBackgroundEnabled = false
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 10
    }
}

// MARK: - CLLocationManagerDelegate
extension BackgroundTelematicsManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // CLVisit provides arrival and departure times for stationary periods
        // This is battery-efficient for background monitoring
        Task { @MainActor in
            print("Visit detected at \(visit.coordinate) - Arrival: \(visit.arrivalDate), Departure: \(visit.departureDate)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates for continuous monitoring
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.isBackgroundEnabled = manager.authorizationStatus == .authorizedAlways
        }
    }
}
