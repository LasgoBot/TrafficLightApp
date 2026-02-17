# Integration Guide: Telematics with Existing System

## Overview

This guide shows how to integrate the new Telematics-based V2X system with the existing DriveSense app architecture.

## Option 1: Complete Replacement (Telematics-Only)

Replace camera-based detection entirely with telematics:

```swift
// In your app initialization or view model
let telematicsEngine = TelematicsObservationEngine()
let signalService = TrafficSignalService(
    remoteService: TrafficSignalAPIClient(),
    observationService: telematicsEngine
)

// Use as before
let signal = await signalService.signalPrediction(near: currentLocation)
```

## Option 2: Hybrid Mode (Camera + Telematics)

Create a hybrid observation engine that combines both approaches:

```swift
actor HybridObservationEngine: TrafficLightObservationProviding {
    private let cameraEngine: TrafficLightObservationEngine
    private let telematicsEngine: TelematicsObservationEngine
    
    init() {
        self.cameraEngine = TrafficLightObservationEngine()
        self.telematicsEngine = TelematicsObservationEngine()
    }
    
    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        // Try telematics first (faster, no camera needed)
        if let telematicsSignal = await telematicsEngine.predictSignal(near: coordinate),
           telematicsSignal.confidence > 0.75 {
            return telematicsSignal
        }
        
        // Fall back to camera-based detection
        return await cameraEngine.predictSignal(near: coordinate)
    }
}

// Usage
let hybridEngine = HybridObservationEngine()
let signalService = TrafficSignalService(
    remoteService: TrafficSignalAPIClient(),
    observationService: hybridEngine
)
```

## Option 3: Parallel Mode (Best of Both)

Run both systems in parallel and choose the best prediction:

```swift
actor ParallelObservationEngine: TrafficLightObservationProviding {
    private let cameraEngine: TrafficLightObservationEngine
    private let telematicsEngine: TelematicsObservationEngine
    
    init() {
        self.cameraEngine = TrafficLightObservationEngine()
        self.telematicsEngine = TelematicsObservationEngine()
    }
    
    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        // Run both in parallel
        async let cameraSignal = cameraEngine.predictSignal(near: coordinate)
        async let telematicsSignal = telematicsEngine.predictSignal(near: coordinate)
        
        let (camera, telematics) = await (cameraSignal, telematicsSignal)
        
        // Pick the signal with higher confidence
        guard let camera = camera else { return telematics }
        guard let telematics = telematics else { return camera }
        
        return camera.confidence >= telematics.confidence ? camera : telematics
    }
}
```

## Option 4: Background Learning Only

Keep camera for real-time detection, but learn from telematics in background:

```swift
@MainActor
class DriveSenseViewModel: ObservableObject {
    private let cameraService: TrafficSignalService
    private let telematicsService: TelematicsService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Camera-based service for real-time detection
        self.cameraService = TrafficSignalService(
            remoteService: TrafficSignalAPIClient(),
            observationService: TrafficLightObservationEngine()
        )
        
        // Telematics service for background learning
        self.telematicsService = TelematicsService()
        
        setupBackgroundLearning()
    }
    
    func startDriving() {
        // Start both systems
        telematicsService.startMonitoring()
    }
    
    func stopDriving() {
        telematicsService.stopMonitoring()
    }
    
    private func setupBackgroundLearning() {
        // Telematics learns in background
        // Camera provides real-time feedback
        // Over time, telematics predictions improve
        telematicsService.stopWaitLaunchStream
            .sink { [weak self] event in
                self?.handleTelematicsEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleTelematicsEvent(_ event: TelematicsFlowEvent) {
        // Optional: Log learning progress
        switch event {
        case .launchedFromSignal(_, let prediction, _):
            print("Learned signal cycle: \(prediction.cycleLength)s with \(prediction.confidence) confidence")
        default:
            break
        }
    }
}
```

## Recommended Approach

For the best user experience, use **Option 4** during the transition period:

1. **Week 1-2:** Camera-based detection (current system)
2. **Week 2-4:** Camera + Background telematics learning
3. **Week 4+:** Hybrid mode (telematics first, camera fallback)
4. **Long-term:** Pure telematics (no camera needed)

This allows the system to learn patterns before relying on them for predictions.

## App Settings Integration

Add a setting to let users choose their preferred mode:

```swift
enum DetectionMode: String, CaseIterable {
    case camera = "Camera Only"
    case telematics = "Telematics Only"
    case hybrid = "Hybrid (Recommended)"
    case cameraWithLearning = "Camera + Background Learning"
}

struct SettingsView: View {
    @AppStorage("detectionMode") private var detectionMode = DetectionMode.hybrid
    
    var body: some View {
        Form {
            Section("Detection Mode") {
                Picker("Mode", selection: $detectionMode) {
                    ForEach(DetectionMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                
                Text(modeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var modeDescription: String {
        switch detectionMode {
        case .camera:
            return "Uses camera to detect traffic lights. Requires camera access and works best in good lighting."
        case .telematics:
            return "Learns traffic patterns from your driving. Works in pocket, no camera needed. Improves over time."
        case .hybrid:
            return "Automatically uses the best detection method. Recommended for optimal performance."
        case .cameraWithLearning:
            return "Uses camera for real-time detection while learning patterns in background."
        }
    }
}
```

## Testing Integration

Test each mode thoroughly:

```swift
// Test 1: Telematics-only mode
let telematicsOnly = TelematicsObservationEngine()
let signal1 = await telematicsOnly.predictSignal(near: testCoordinate)
XCTAssertNotNil(signal1)

// Test 2: Hybrid mode
let hybrid = HybridObservationEngine()
let signal2 = await hybrid.predictSignal(near: testCoordinate)
XCTAssertNotNil(signal2)

// Test 3: Service integration
let service = TrafficSignalService(
    remoteService: MockRemoteService(),
    observationService: telematicsOnly
)
let signal3 = await service.signalPrediction(near: testCoordinate)
XCTAssertNotNil(signal3)
```

## Performance Monitoring

Track performance of each mode:

```swift
struct DetectionMetrics {
    var telematicsSuccessRate: Double = 0.0
    var cameraSuccessRate: Double = 0.0
    var telematicsConfidence: Double = 0.0
    var cameraConfidence: Double = 0.0
    
    mutating func recordTelematicsDetection(confidence: Double) {
        telematicsConfidence = telematicsConfidence * 0.9 + confidence * 0.1
        telematicsSuccessRate = telematicsSuccessRate * 0.9 + 1.0 * 0.1
    }
    
    mutating func recordCameraDetection(confidence: Double) {
        cameraConfidence = cameraConfidence * 0.9 + confidence * 0.1
        cameraSuccessRate = cameraSuccessRate * 0.9 + 1.0 * 0.1
    }
    
    var recommendedMode: DetectionMode {
        if telematicsConfidence > 0.8 && telematicsSuccessRate > 0.7 {
            return .telematics
        } else if cameraConfidence > 0.8 {
            return .camera
        } else {
            return .hybrid
        }
    }
}
```

## Migration Path

1. **Phase 1 (Current):** Camera-only detection
2. **Phase 2:** Add TelematicsService alongside camera
3. **Phase 3:** Collect metrics on both systems
4. **Phase 4:** Enable hybrid mode for beta users
5. **Phase 5:** Roll out telematics-first to all users
6. **Phase 6:** Make camera optional (privacy win!)

## Benefits of Integration

- **Better Coverage:** Works in tunnels, at night, in poor weather
- **Privacy:** No camera data processing
- **Battery:** More efficient than continuous camera
- **Background:** Learns even when app is backgrounded
- **Offline:** Works without network connection
- **CarPlay:** Works with phone in pocket

## Troubleshooting

If telematics predictions are poor:
1. Check if user has granted "Always" location permission
2. Verify motion data is available
3. Ensure sufficient observations (≥3 per signal)
3. Check cache for nearby traffic nodes
4. Fall back to camera or remote service

## Next Steps

After integration:
1. Monitor prediction accuracy
2. Collect user feedback
3. Tune thresholds based on real-world data
4. Add time-of-day pattern support
5. Implement crowd-sourced validation
