import Combine
import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class TelematicsManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentState: VehicleState?
    @Published private(set) var lastEvent: TelematicsEvent?
    
    // MARK: - Event Stream
    let eventPublisher = PassthroughSubject<TelematicsEvent, Never>()
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    private var lastKnownSpeed: Double = 0
    private var lastKnownLocation: CLLocation?
    private var wasMoving = false
    private var stopDetectedAt: Date?
    private var stopLocation: CLLocation?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let hardStopSpeedThreshold: Double = 1.0 // km/h
    private let launchAccelerationThreshold: Double = 0.15 // g-force
    private let launchSpeedThreshold: Double = 5.0 // km/h
    private let minimumStopDuration: TimeInterval = 2.0 // seconds
    
    // MARK: - Initialization
    init() {
        setupLocationManager()
        setupMotionManager()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        locationManager.startUpdatingLocation()
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, error in
                guard let data = data, error == nil else { return }
                Task { @MainActor in
                    self?.processAccelerometerData(data)
                }
            }
        }
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func setupMotionManager() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        guard let location = lastKnownLocation else { return }
        
        let acceleration = sqrt(pow(data.acceleration.x, 2) +
                              pow(data.acceleration.y, 2) +
                              pow(data.acceleration.z, 2))
        
        let state = VehicleState(
            location: location,
            speedKPH: lastKnownSpeed,
            accelerationG: acceleration,
            timestamp: Date()
        )
        
        currentState = state
        processVehicleState(state)
    }
    
    private func processVehicleState(_ state: VehicleState) {
        let now = Date()
        
        // Detect hard stop
        if wasMoving && state.isStationary {
            if stopDetectedAt == nil {
                stopDetectedAt = now
                stopLocation = state.location
            }
            
            // Confirm hard stop after minimum duration
            if let stopTime = stopDetectedAt,
               now.timeIntervalSince(stopTime) >= minimumStopDuration {
                let event = TelematicsEvent.hardStop(
                    location: state.location,
                    timestamp: now
                )
                emitEvent(event)
                wasMoving = false
            }
        }
        
        // Detect green light launch
        if !wasMoving && 
           state.speedKPH >= launchSpeedThreshold &&
           state.accelerationG >= (1.0 + launchAccelerationThreshold) {
            
            let event = TelematicsEvent.greenLightLaunch(
                location: state.location,
                timestamp: now
            )
            emitEvent(event)
            wasMoving = true
            stopDetectedAt = nil
            stopLocation = nil
        }
        
        // Update moving state
        if state.isMoving && !wasMoving {
            wasMoving = true
            stopDetectedAt = nil
        }
        
        // Emit status events
        if state.isStationary {
            emitEvent(.stopped(location: state.location))
        } else if state.isMoving {
            emitEvent(.moving(speedKPH: state.speedKPH))
        }
    }
    
    private func emitEvent(_ event: TelematicsEvent) {
        lastEvent = event
        eventPublisher.send(event)
    }
}

// MARK: - CLLocationManagerDelegate
extension TelematicsManager: NSObject, CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.lastKnownLocation = location
            self.lastKnownSpeed = max(0, location.speed * 3.6) // Convert m/s to km/h
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes if needed
    }
}
