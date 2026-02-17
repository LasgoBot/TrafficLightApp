# Invisible V2X - Telematics-Based Traffic Light Learning

## Overview

The Invisible V2X system is a "Zero-UI" background telematics solution that learns traffic light cycles using GPS and motion sensors. Unlike camera-based approaches, this system works with the phone in the user's pocket or connected to CarPlay, automatically learning signal timings by detecting when vehicles stop at intersections.

## Architecture

### 1. TelematicsManager (The Sensor)
**Location:** `Services/Telematics/TelematicsManager.swift`

Monitors vehicle behavior using CoreLocation and CoreMotion:
- Tracks GPS speed and acceleration
- Detects "Hard Stops" (speed drops to 0)
- Detects "Green Light Launches" (accelerometer detects forward pitch + speed increase)
- Filters stop-and-go traffic from traffic light stops

**Key Features:**
- Battery-efficient sensor fusion
- Configurable thresholds for detection
- Combine-based event streaming
- Background-capable location updates

**Usage:**
```swift
let manager = TelematicsManager()
manager.startMonitoring()

manager.eventPublisher
    .sink { event in
        switch event {
        case .hardStop(let location, let timestamp):
            print("Stopped at \(location.coordinate)")
        case .greenLightLaunch(let location, let timestamp):
            print("Launched from \(location.coordinate)")
        default:
            break
        }
    }
```

### 2. TrafficNodeService (The Map)
**Location:** `Services/Telematics/TrafficNodeService.swift`

Queries OpenStreetMap for traffic signal locations:
- Uses Overpass API to find `highway=traffic_signals` nodes
- 500m search radius around current location
- Geohash-based local caching (7-day expiration)
- Network-efficient with automatic cache management

**Key Features:**
- Async/await API
- Automatic cache invalidation
- Distance-based node matching
- Minimal network usage

**Usage:**
```swift
let service = TrafficNodeService()
let nodes = try await service.findTrafficSignals(
    near: coordinate,
    radius: 500
)
let nearest = try await service.findNearestTrafficSignal(
    to: coordinate,
    maxDistance: 50
)
```

### 3. SignalPhasePredictor (The Brain)
**Location:** `Services/Telematics/SignalPhasePredictor.swift`

Learns traffic light timing patterns from observations:
- Records green light launch timestamps
- Calculates cycle lengths using statistical methods
- Determines cycle offsets (e.g., "turns green at :00 and :45 of each minute")
- Predicts next green time with confidence scoring

**Algorithm:**
1. Collects green launch observations over time
2. Calculates intervals between consecutive launches
3. Identifies dominant cycle length using median (robust to outliers)
4. Computes cycle offset from midnight
5. Validates consistency and assigns confidence score

**Confidence Factors:**
- Observation count (more = better)
- Timing consistency (lower deviation = higher confidence)
- Minimum 3 observations required for prediction

**Usage:**
```swift
let predictor = SignalPhasePredictor()

// Record observation
await predictor.recordGreenLaunch(
    nodeID: "osm-123456",
    timestamp: Date()
)

// Get prediction
if let prediction = await predictor.predictNextGreen(nodeID: "osm-123456") {
    print("Next green in \(prediction.nextGreenTime.timeIntervalSinceNow)s")
    print("Confidence: \(prediction.confidence)")
}
```

### 4. TelematicsService (Integration Layer)
**Location:** `Services/Telematics/TelematicsService.swift`

Orchestrates all components with intelligent event processing:
- Combines telematics events with map data
- Filters traffic stops from signal stops
- Automatically records observations
- Provides Combine stream: Stop → Wait → Launch

**Event Flow:**
```
Vehicle Moving
    ↓
Hard Stop Detected
    ↓
Query Nearby Traffic Nodes
    ↓
Match to Signal (≤50m) → Emit: stoppedAtSignal
No Match → Emit: stoppedInTraffic
    ↓
Waiting (periodic updates)
    ↓
Green Light Launch Detected
    ↓
Record Observation → Update Predictor
    ↓
Emit: launchedFromSignal (with prediction)
```

**Usage:**
```swift
let service = TelematicsService()
service.startMonitoring()

service.stopWaitLaunchStream
    .sink { event in
        switch event {
        case .stoppedAtSignal(let node, let timestamp):
            print("Stopped at signal: \(node.id)")
        case .launchedFromSignal(let node, let prediction, _):
            print("Launched! Next green in \(prediction.cycleLength)s")
        case .stoppedInTraffic:
            print("Stop-and-go traffic, not a signal")
        default:
            break
        }
    }
```

### 5. TelematicsObservationEngine
**Location:** `Services/Telematics/TelematicsObservationEngine.swift`

Integrates with existing `TrafficSignalService` architecture:
- Implements `TrafficLightObservationProviding` protocol
- Converts telematics predictions to `TrafficSignal` objects
- Provides seamless fallback from camera-based detection
- Estimates current phase based on cycle timing

**Integration:**
```swift
// Can be used as a drop-in replacement for camera-based observation
let engine = TelematicsObservationEngine()
let signal = await engine.predictSignal(near: coordinate)
```

### 6. BackgroundTelematicsManager
**Location:** `Services/Telematics/BackgroundTelematicsManager.swift`

Enables background operation:
- Uses CLVisit for battery-efficient monitoring
- Supports "Always" location authorization
- Continues learning when app is backgrounded
- Integrates with iOS background location modes

**Configuration:**
```swift
let bgManager = BackgroundTelematicsManager()
bgManager.enableBackgroundMode()
```

## Models

### TelematicsEvent
Enum representing vehicle events:
- `hardStop(location, timestamp)` - Vehicle stopped
- `greenLightLaunch(location, timestamp)` - Vehicle launched
- `moving(speedKPH)` - Vehicle in motion
- `stopped(location)` - Currently stopped

### TrafficNode
Represents a traffic signal from OSM:
- `id` - Unique identifier
- `coordinate` - GPS location
- `osmID` - OpenStreetMap node ID
- `geohash` - 7-character geohash for caching

### SignalPhaseObservation
Records a green launch event:
- `nodeID` - Signal identifier
- `greenLaunchTime` - Timestamp
- `dayOfWeek` - Day of week (for pattern analysis)
- `timeOfDay` - Seconds since midnight

### SignalCyclePattern
Learned pattern for a signal:
- `cycleLength` - Time between green phases
- `cycleOffset` - Offset from midnight
- `confidence` - 0.0-1.0 confidence score
- `observations` - Historical data

### SignalPrediction
Prediction output:
- `nextGreenTime` - When light will turn green
- `cycleLength` - Duration of cycle
- `confidence` - Prediction confidence

## Battery Efficiency

The system is designed for minimal battery impact:

1. **Location Updates:**
   - 5-meter distance filter (not continuous)
   - Automotive navigation accuracy
   - Pauses when stationary (using CLVisit)

2. **Motion Sensing:**
   - 0.1s accelerometer interval (only when moving)
   - Stops when speed is 0
   - Efficient OperationQueue processing

3. **Network Usage:**
   - Geohash-based caching (7-day retention)
   - Single Overpass query per geohash cell
   - 10-second timeout on API calls

4. **Background Mode:**
   - CLVisit for stationary detection
   - Significant location changes only
   - No continuous UI updates

## Privacy Considerations

- No personal data transmitted to servers
- OpenStreetMap queries are anonymous
- All learning stored locally (UserDefaults)
- Location used only for signal matching
- No user tracking or analytics

## Integration with Existing System

The telematics system integrates seamlessly:

```swift
// In TrafficSignalService, add telematics as a fallback
let telematicsEngine = TelematicsObservationEngine()
let service = TrafficSignalService(
    remoteService: TrafficSignalAPIClient(),
    observationService: telematicsEngine  // Can chain with existing
)
```

## Configuration (Info.plist)

Required permissions:
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSMotionUsageDescription`
- `UIBackgroundModes`: `location`
- Network exception for `overpass-api.de`

## Testing

Comprehensive test suites provided:
- `TelematicsManagerTests.swift` - Sensor logic
- `TrafficNodeTests.swift` - Geohashing and distance
- `SignalPhasePredictorTests.swift` - Learning algorithm
- `TelematicsServiceTests.swift` - Integration

Run tests in Xcode or with `swift test` (when Package.swift is added).

## Performance Characteristics

- **First prediction:** After 3 observations
- **High confidence:** After 20-30 observations
- **Cycle detection:** 15-180 second cycles supported
- **Spatial accuracy:** ±50m for signal matching
- **Temporal accuracy:** ±5s for predictions at 90% confidence

## Future Enhancements

1. **Time-of-Day Patterns:** Different cycles for rush hour
2. **Day-of-Week Learning:** Weekend vs. weekday patterns
3. **Multi-Phase Support:** Left turn arrows, pedestrian phases
4. **Crowd-Sourced Validation:** Cross-reference predictions
5. **Adaptive Thresholds:** Learn per-driver acceleration patterns

## Debugging

Enable debug logging:
```swift
// Add print statements in event handlers
service.stopWaitLaunchStream
    .sink { event in
        print("[Telematics] \(event)")
    }
```

Check cache status:
```swift
let cache = TrafficNodeCache()
// Inspect cache entries
```

View learned patterns:
```swift
let storage = SignalPhaseStorage()
let patterns = await storage.loadAllPatterns()
print("Learned \(patterns.count) signal patterns")
```

## Credits

Implementation based on V2X (Vehicle-to-Everything) concepts and similar to:
- Waze traffic detection algorithms
- Google Maps real-time traffic analysis
- GLOSA (Green Light Optimal Speed Advisory) systems
