import CoreLocation
import CoreMotion
import Foundation
import Combine

@MainActor
final class SimulationManager: ObservableObject {
    @Published private(set) var isSimulating = false
    @Published private(set) var currentSimulationStep: String = ""
    @Published private(set) var simulationLog: [String] = []
    
    private let telematicsManager: TelematicsManager
    private var simulationTimer: Timer?
    private var simulationStep = 0
    
    // Simulated location sequence
    private var simulatedLocations: [CLLocation] = []
    private var targetCoordinate: CLLocationCoordinate2D
    
    init(telematicsManager: TelematicsManager = TelematicsManager()) {
        self.telematicsManager = telematicsManager
        // Default target: San Francisco coordinates
        self.targetCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    // MARK: - Public Methods
    
    func simulateDrive(targetCoordinate: CLLocationCoordinate2D? = nil) {
        guard !isSimulating else {
            log("⚠️ Simulation already running")
            return
        }
        
        if let target = targetCoordinate {
            self.targetCoordinate = target
        }
        
        log("🚗 Starting drive simulation...")
        isSimulating = true
        simulationStep = 0
        simulationLog = []
        
        // Generate location sequence
        generateLocationSequence()
        
        // Start simulation
        startSimulation()
    }
    
    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulating = false
        simulationStep = 0
        log("🛑 Simulation stopped")
    }
    
    // MARK: - Private Methods
    
    private func generateLocationSequence() {
        simulatedLocations = []
        
        // Start point: 200 meters away from target
        let startLat = targetCoordinate.latitude - 0.0018 // ~200m south
        let startLon = targetCoordinate.longitude - 0.0018 // ~200m west
        
        // Generate 10 points approaching the target
        for i in 0..<10 {
            let progress = Double(i) / 9.0
            let lat = startLat + (targetCoordinate.latitude - startLat) * progress
            let lon = startLon + (targetCoordinate.longitude - startLon) * progress
            
            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 45, // Northeast direction
                speed: 8.33, // 30 km/h = 8.33 m/s
                timestamp: Date()
            )
            
            simulatedLocations.append(location)
        }
        
        // Add stop location (speed = 0)
        let stopLocation = CLLocation(
            coordinate: targetCoordinate,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 45,
            speed: 0, // Stopped
            timestamp: Date()
        )
        
        simulatedLocations.append(stopLocation)
        
        log("📍 Generated \(simulatedLocations.count) simulation waypoints")
    }
    
    private func startSimulation() {
        // Simulate driving sequence
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.executeSimulationStep()
            }
        }
    }
    
    private func executeSimulationStep() async {
        guard isSimulating else {
            stopSimulation()
            return
        }
        
        switch simulationStep {
        case 0..<10:
            // Driving phase - inject locations with speed
            if simulationStep < simulatedLocations.count - 1 {
                let location = simulatedLocations[simulationStep]
                injectLocation(location)
                log("🚗 Driving: Step \(simulationStep + 1)/10, Speed: \(Int(location.speed * 3.6)) km/h")
                currentSimulationStep = "Driving (\(simulationStep + 1)/10)"
            }
            
        case 10:
            // Arrival at intersection - inject stop location
            let stopLocation = simulatedLocations.last!
            injectLocation(stopLocation)
            log("🛑 Arrived at intersection - STOPPED (Speed: 0 km/h)")
            currentSimulationStep = "Stopped at Signal"
            
            // Simulate hard stop detection
            simulateHardStop(at: stopLocation)
            
        case 11..<31:
            // Waiting at red light (20 steps = 40 seconds)
            let waitTime = (simulationStep - 10) * 2
            log("⏱️ Waiting at red light... (\(waitTime)s)")
            currentSimulationStep = "Waiting (\(waitTime)s)"
            
        case 31:
            // Simulate green light and launch
            log("🟢 Light turned GREEN - Launching!")
            currentSimulationStep = "Launching"
            
            // Simulate accelerometer spike (green light launch)
            simulateGreenLightLaunch(at: simulatedLocations.last!)
            
        case 32:
            // Post-launch - inject moving location
            let launchLocation = CLLocation(
                coordinate: targetCoordinate,
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 45,
                speed: 8.33, // Accelerating
                timestamp: Date()
            )
            injectLocation(launchLocation)
            log("🚗 Accelerating away from intersection")
            currentSimulationStep = "Driving Away"
            
        case 33:
            // Simulation complete
            log("✅ Simulation complete! Check SwiftData for learned cycle.")
            currentSimulationStep = "Complete"
            stopSimulation()
            
            // Print results
            await printSimulationResults()
            
        default:
            break
        }
        
        simulationStep += 1
    }
    
    private func injectLocation(_ location: CLLocation) {
        // Inject location into TelematicsManager
        // This simulates the CLLocationManagerDelegate callback
        // We'll trigger the location update through the manager's internal mechanism
        
        // For simulation, we directly update the lastKnownLocation and speed
        // In a real implementation, this would go through CLLocationManager
        
        telematicsManager.locationManager(
            telematicsManager.locationManager,
            didUpdateLocations: [location]
        )
    }
    
    private func simulateHardStop(at location: CLLocation) {
        // Create and emit hard stop event
        let event = TelematicsEvent.hardStop(location: location, timestamp: Date())
        telematicsManager.eventPublisher.send(event)
        log("📡 Emitted HARD STOP event")
    }
    
    private func simulateGreenLightLaunch(at location: CLLocation) {
        // Create and emit green light launch event
        let event = TelematicsEvent.greenLightLaunch(location: location, timestamp: Date())
        telematicsManager.eventPublisher.send(event)
        log("📡 Emitted GREEN LIGHT LAUNCH event")
    }
    
    private func printSimulationResults() async {
        log("\n" + "="*50)
        log("📊 SIMULATION RESULTS")
        log("="*50)
        
        // Check SwiftData for the learned node
        let dataController = DataController.shared
        let geoID = String(format: "%.6f_%.6f", targetCoordinate.latitude, targetCoordinate.longitude)
        
        if let node = dataController.getNode(geoID: geoID) {
            log("✅ Node saved in SwiftData:")
            log("   GeoID: \(node.geoID)")
            log("   Location: (\(node.latitude), \(node.longitude))")
            log("   Cycle Duration: \(Int(node.cycleDuration))s")
            log("   Confidence: \(node.confidenceScore)")
            log("   Last Green: \(node.lastGreenTimestamp)")
        } else {
            log("⚠️ Node not found in SwiftData")
        }
        
        log("="*50 + "\n")
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        simulationLog.append(logMessage)
    }
}

// String extension for repeating characters
private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
