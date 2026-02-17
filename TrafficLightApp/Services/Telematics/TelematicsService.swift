import Combine
import CoreLocation
import Foundation

@MainActor
final class TelematicsService: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isMonitoring = false
    @Published private(set) var lastPrediction: SignalPrediction?
    
    // MARK: - Event Stream
    let stopWaitLaunchStream = PassthroughSubject<TelematicsFlowEvent, Never>()
    
    // MARK: - Private Properties
    private let telematicsManager: TelematicsManager
    private let nodeService: TrafficNodeService
    private let phasePredictor: SignalPhasePredictor
    private let dataController: DataController
    private var liveActivityManager: Any? // Will be LiveActivityManager on iOS 16.2+
    
    private var cancellables = Set<AnyCancellable>()
    private var currentStopNode: TrafficNode?
    private var stopTimestamp: Date?
    
    // MARK: - Initialization
    init(telematicsManager: TelematicsManager = TelematicsManager(),
         nodeService: TrafficNodeService = TrafficNodeService(),
         phasePredictor: SignalPhasePredictor = SignalPhasePredictor(),
         dataController: DataController = DataController.shared) {
        self.telematicsManager = telematicsManager
        self.nodeService = nodeService
        self.phasePredictor = phasePredictor
        self.dataController = dataController
        
        // Initialize Live Activity manager if available
        if #available(iOS 16.2, *) {
            self.liveActivityManager = LiveActivityManager.shared
        }
        
        setupEventStream()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        telematicsManager.requestAlwaysAuthorization()
        telematicsManager.startMonitoring()
        isMonitoring = true
    }
    
    func stopMonitoring() {
        telematicsManager.stopMonitoring()
        isMonitoring = false
    }
    
    func getPrediction(for nodeID: String) async -> SignalPrediction? {
        return await phasePredictor.predictNextGreen(nodeID: nodeID)
    }
    
    // MARK: - Private Methods
    private func setupEventStream() {
        telematicsManager.eventPublisher
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    await self?.handleTelematicsEvent(event)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleTelematicsEvent(_ event: TelematicsEvent) async {
        switch event {
        case .hardStop(let location, let timestamp):
            await handleHardStop(location: location, timestamp: timestamp)
            
        case .greenLightLaunch(let location, let timestamp):
            await handleGreenLightLaunch(location: location, timestamp: timestamp)
            
        case .stopped(let location):
            emitFlowEvent(.waiting(at: location))
            
        case .moving(let speedKPH):
            emitFlowEvent(.moving(speedKPH: speedKPH))
        }
    }
    
    private func handleHardStop(location: CLLocation, timestamp: Date) async {
        // Find nearest traffic signal
        do {
            let node = try await nodeService.findNearestTrafficSignal(
                to: location.coordinate,
                maxDistance: 50
            )
            
            if let node = node {
                currentStopNode = node
                stopTimestamp = timestamp
                
                // Save to SwiftData
                let geoID = String(format: "%.6f_%.6f", location.coordinate.latitude, location.coordinate.longitude)
                dataController.saveNode(geoID: geoID, coordinate: location.coordinate)
                
                // Start Live Activity if available
                if #available(iOS 16.2, *) {
                    if let activityManager = liveActivityManager as? LiveActivityManager {
                        let intersectionName = "Intersection \(geoID.prefix(10))"
                        activityManager.startActivity(
                            intersectionName: intersectionName,
                            geoID: geoID,
                            initialState: .red,
                            countdown: 30,
                            targetSpeed: 30
                        )
                    }
                }
                
                emitFlowEvent(.stoppedAtSignal(node: node, timestamp: timestamp))
            } else {
                // Not at a traffic signal (stop-and-go traffic)
                currentStopNode = nil
                stopTimestamp = nil
                emitFlowEvent(.stoppedInTraffic(location: location.coordinate))
            }
        } catch {
            // Network error or other issue - treat as unknown stop
            currentStopNode = nil
            stopTimestamp = nil
        }
    }
    
    private func handleGreenLightLaunch(location: CLLocation, timestamp: Date) async {
        // If we have a current stop node, record the launch
        if let node = currentStopNode, let stopTime = stopTimestamp {
            await phasePredictor.recordGreenLaunch(nodeID: node.id, timestamp: timestamp)
            
            // Calculate cycle duration (time between stop and launch)
            let cycleDuration = timestamp.timeIntervalSince(stopTime)
            
            // Update SwiftData with cycle information
            let geoID = String(format: "%.6f_%.6f", location.coordinate.latitude, location.coordinate.longitude)
            dataController.updateCycleDuration(geoID: geoID, duration: cycleDuration, greenTimestamp: timestamp)
            
            // Get updated prediction
            if let prediction = await phasePredictor.predictNextGreen(nodeID: node.id) {
                lastPrediction = prediction
                
                // Update Live Activity with prediction
                if #available(iOS 16.2, *) {
                    if let activityManager = liveActivityManager as? LiveActivityManager {
                        activityManager.updateFromPrediction(
                            prediction: prediction,
                            currentSpeed: telematicsManager.currentState?.speedKPH ?? 0
                        )
                    }
                }
                
                emitFlowEvent(.launchedFromSignal(node: node, prediction: prediction, timestamp: timestamp))
            } else {
                emitFlowEvent(.launched(from: location.coordinate, timestamp: timestamp))
            }
            
            // End Live Activity after launch
            if #available(iOS 16.2, *) {
                if let activityManager = liveActivityManager as? LiveActivityManager {
                    // Delay ending activity to show green state briefly
                    Task {
                        do {
                            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                            activityManager.endActivity()
                        } catch {
                            // Task was cancelled (e.g., app backgrounded) - end activity immediately
                            activityManager.endActivity()
                        }
                    }
                }
            }
            
            currentStopNode = nil
            stopTimestamp = nil
        } else {
            // Launch without a known signal stop
            emitFlowEvent(.launched(from: location.coordinate, timestamp: timestamp))
        }
    }
    
    private func emitFlowEvent(_ event: TelematicsFlowEvent) {
        stopWaitLaunchStream.send(event)
    }
}

// MARK: - Flow Events
enum TelematicsFlowEvent {
    case stoppedAtSignal(node: TrafficNode, timestamp: Date)
    case stoppedInTraffic(location: CLLocationCoordinate2D)
    case waiting(at: CLLocation)
    case launchedFromSignal(node: TrafficNode, prediction: SignalPrediction, timestamp: Date)
    case launched(from: CLLocationCoordinate2D, timestamp: Date)
    case moving(speedKPH: Double)
}
