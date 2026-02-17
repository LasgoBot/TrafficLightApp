# Production Modules Documentation

This document describes the three production-ready modules that make DriveSense a shippable product.

## Module 1: SwiftData Persistence Layer

### Overview
Persistent storage for learned traffic signal cycles using SwiftData, Apple's modern data persistence framework.

### Components

#### TrafficNodeEntity
SwiftData model that stores learned traffic signal information:

```swift
@Model
final class TrafficNodeEntity {
    @Attribute(.unique) var geoID: String
    var latitude: Double
    var longitude: Double
    var cycleDuration: TimeInterval
    var lastGreenTimestamp: Date
    var confidenceScore: Int
    var createdAt: Date
    var updatedAt: Date
}
```

**Attributes:**
- `geoID`: Unique identifier (format: "lat_lon")
- `latitude/longitude`: GPS coordinates
- `cycleDuration`: Learned cycle time in seconds
- `lastGreenTimestamp`: When the light last turned green
- `confidenceScore`: Increments with each observation (0-100)
- `createdAt/updatedAt`: Timestamps for data management

#### DataController
Singleton that manages all SwiftData operations:

**Key Methods:**
- `saveNode(geoID:coordinate:)` - Saves a new traffic node
- `updateCycleDuration(geoID:duration:greenTimestamp:)` - Updates learned cycle
- `getNode(geoID:)` - Retrieves a specific node
- `getAllNodes()` - Returns all learned nodes
- `getNodesNear(coordinate:radiusMeters:)` - Spatial queries
- `deleteNode(geoID:)` / `deleteAllNodes()` - Cleanup operations

**Integration:**
Automatically integrates with TelematicsService:
- Saves node on hard stop detection
- Updates cycle duration on green light launch
- Increments confidence score with each observation

### Usage Example

```swift
let dataController = DataController.shared

// Save a node
dataController.saveNode(
    geoID: "37.774900_-122.419400",
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
)

// Update cycle
dataController.updateCycleDuration(
    geoID: "37.774900_-122.419400",
    duration: 45.0,
    greenTimestamp: Date()
)

// Query nearby nodes
let nearby = dataController.getNodesNear(
    coordinate: currentLocation,
    radiusMeters: 100
)
```

### Testing
Run `DataControllerTests` for comprehensive test coverage:
- Node creation and retrieval
- Cycle duration updates
- Confidence score increments
- Spatial queries
- Duplicate prevention
- Deletion operations

---

## Module 2: Dynamic Island & Live Activity

### Overview
Premium user experience using ActivityKit to display traffic signal status in the Dynamic Island and Lock Screen.

### Components

#### TrafficActivityAttributes
Defines the structure of Live Activity data:

```swift
@available(iOS 16.2, *)
struct TrafficActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var trafficLightState: TrafficLightState  // red/yellow/green
        var countdownSeconds: Int                 // Time to next green
        var targetSpeed: Int                      // GLOSA optimal speed (mph)
        var lastUpdate: Date
    }
    
    var intersectionName: String  // Static
    var geoID: String             // Static
}
```

#### TrafficLiveActivity
Widget configuration that renders in Dynamic Island and Lock Screen:

**Dynamic Island Layout:**
- **Compact Leading:** Traffic light emoji (🔴/🟡/🟢)
- **Compact Trailing:** Countdown timer (e.g., "14s")
- **Expanded Center:** GLOSA target speed (e.g., "30 mph")
- **Expanded Bottom:** Intersection name with location icon

**Lock Screen Layout:**
- Full display with signal state, countdown, and target speed
- Dark background with high contrast
- System action buttons

#### LiveActivityManager
Singleton that manages Live Activity lifecycle:

**Key Methods:**
- `startActivity(intersectionName:geoID:...)` - Starts activity at signal stop
- `updateActivity(state:countdown:targetSpeed:)` - Updates in real-time
- `endActivity()` - Ends activity after launch
- `updateFromPrediction(prediction:currentSpeed:)` - Auto-updates from predictor

**GLOSA Speed Calculation:**
Calculates optimal speed to arrive at green light:
- If stopped: Suggests speed based on remaining time
- If moving: Adjusts speed to catch next green cycle
- Range: 25-35 mph (configurable)

### Integration

**Automatic Triggering:**
1. User stops at traffic signal
2. TelematicsService detects hard stop at known node
3. LiveActivityManager automatically starts activity
4. Activity updates countdown in real-time
5. Activity ends 3 seconds after green light launch

**Manual Demo:**
Use `ProductionDemoView` to test Dynamic Island:
```swift
LiveActivityManager.shared.startActivity(
    intersectionName: "Demo Intersection",
    geoID: "demo_001",
    initialState: .red,
    countdown: 15,
    targetSpeed: 30
)
```

### Requirements
- iOS 16.2+ (wrapped in availability checks)
- Live Activities enabled in Settings
- `NSSupportsLiveActivities = true` in Info.plist

### Visual Design

**Compact (Dynamic Island):**
```
🔴  |  14s
```

**Expanded (Dynamic Island):**
```
🔴 Signal        Next Green
   Red           14s

      30 mph
   GLOSA Speed

📍 Main St & 1st Ave
```

**Lock Screen:**
```
┌─────────────────────────┐
│ Main St & 1st Ave   🔴  │
│ Traffic Signal          │
│                         │
│ Next Green    Target    │
│    14s         30 mph   │
└─────────────────────────┘
```

---

## Module 3: Simulation Manager

### Overview
Desk testing system that simulates a complete drive cycle without requiring actual driving.

### Components

#### SimulationManager
Main simulation controller:

**Key Methods:**
- `simulateDrive(targetCoordinate:)` - Runs complete simulation
- `stopSimulation()` - Cancels running simulation

**Simulation Sequence:**
1. **Approach (10 steps, 20 seconds)**
   - Generates 10 waypoints approaching target
   - Simulates speed of 30 km/h (8.33 m/s)
   - Injects location updates every 2 seconds

2. **Stop (20 steps, 40 seconds)**
   - Injects location with speed = 0
   - Emits HARD STOP event
   - Saves node to SwiftData
   - Starts Live Activity (if available)

3. **Launch (1 step)**
   - Emits GREEN LIGHT LAUNCH event
   - Updates SwiftData with cycle duration
   - Updates Live Activity
   - Calculates learned cycle (should be ~40s)

4. **Completion**
   - Prints simulation results
   - Displays learned node in SwiftData
   - Shows confidence score

### Usage

```swift
let simulationManager = SimulationManager()

// Run simulation with default target (San Francisco)
simulationManager.simulateDrive()

// Or specify custom target
simulationManager.simulateDrive(
    targetCoordinate: CLLocationCoordinate2D(
        latitude: 37.7749,
        longitude: -122.4194
    )
)
```

### Validation

After simulation completes, verify:

1. **SwiftData Persistence:**
   - Check DataController for new node
   - Verify cycleDuration ≈ 40 seconds
   - Confirm confidenceScore = 1

2. **Event Flow:**
   - HARD STOP event emitted
   - GREEN LIGHT LAUNCH event emitted
   - TelematicsService received both events

3. **Live Activity (iOS 16.2+):**
   - Activity started on stop
   - Countdown displayed in Dynamic Island
   - Activity ended after launch

### Simulation Log
Real-time log output during simulation:

```
[02:30:15] 🚗 Starting drive simulation...
[02:30:15] 📍 Generated 11 simulation waypoints
[02:30:17] 🚗 Driving: Step 1/10, Speed: 30 km/h
[02:30:19] 🚗 Driving: Step 2/10, Speed: 30 km/h
...
[02:30:35] 🛑 Arrived at intersection - STOPPED (Speed: 0 km/h)
[02:30:35] 📡 Emitted HARD STOP event
[02:30:37] ⏱️ Waiting at red light... (2s)
[02:30:39] ⏱️ Waiting at red light... (4s)
...
[02:31:15] 🟢 Light turned GREEN - Launching!
[02:31:15] 📡 Emitted GREEN LIGHT LAUNCH event
[02:31:17] 🚗 Accelerating away from intersection
[02:31:19] ✅ Simulation complete! Check SwiftData for learned cycle.

==================================================
📊 SIMULATION RESULTS
==================================================
✅ Node saved in SwiftData:
   GeoID: 37.774900_-122.419400
   Location: (37.7749, -122.4194)
   Cycle Duration: 40s
   Confidence: 1
==================================================
```

---

## ProductionDemoView

Comprehensive UI for testing all three modules:

### Features

1. **SwiftData Section:**
   - Shows count of saved nodes
   - "View All Nodes" button → full list with delete
   - Real-time updates

2. **Dynamic Island Section:**
   - Shows activity status
   - "Demo Dynamic Island" button for testing
   - Auto-countdown demonstration

3. **Simulation Section:**
   - "Start Simulation" button
   - Real-time progress indicator
   - Step-by-step log display
   - Automatic validation

4. **Node List View:**
   - Displays all learned nodes
   - Shows location, cycle time, confidence
   - Swipe to delete individual nodes
   - "Clear All" button

### Screenshots

Launch ProductionDemoView to see:
- SwiftData node count
- Dynamic Island demo button
- Simulation controls
- Real-time log output

---

## Configuration

### Info.plist
Required entries:
```xml
<key>NSSupportsLiveActivities</key>
<true/>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Continuous location access enables automatic traffic light learning</string>

<key>NSMotionUsageDescription</key>
<string>Motion data detects vehicle stops and starts</string>
```

### App Entry Point
```swift
@main
struct TrafficLightAppApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataController)
        }
        .modelContainer(dataController.container)
    }
}
```

---

## Testing Checklist

### Unit Tests
- [x] DataController CRUD operations
- [x] Confidence score increments
- [x] Spatial queries (getNodesNear)
- [x] Duplicate prevention

### Integration Tests
1. Run simulation
2. Verify SwiftData save
3. Check Dynamic Island appearance (iOS 16.2+)
4. Validate cycle duration calculation

### Manual Testing
1. Launch ProductionDemoView
2. Run simulation
3. Check node list for new entry
4. Verify confidence = 1, duration ≈ 40s
5. Test Dynamic Island demo
6. Verify countdown updates
7. Confirm activity ends after 15 seconds

---

## Performance Characteristics

### SwiftData
- SQLite-backed persistence
- Automatic save on updates
- Thread-safe actor pattern
- Efficient spatial queries

### Live Activities
- Updates every 1 second
- Minimal battery impact
- Auto-dismissal after completion
- System-managed lifecycle

### Simulation
- 2-second step intervals
- ~70 second total duration
- Mimics real driving behavior
- Validates complete flow

---

## Troubleshooting

### SwiftData not persisting
- Check DataController initialization
- Verify modelContainer attached to WindowGroup
- Check console for SQLite errors

### Live Activity not appearing
- Verify iOS 16.2+ device
- Check Settings → Live Activities enabled
- Ensure NSSupportsLiveActivities in Info.plist
- Test with demo button first

### Simulation not working
- Ensure TelematicsManager is initialized
- Check event publisher subscriptions
- Verify location manager delegate setup
- Review simulation log for errors

---

## Future Enhancements

1. **SwiftData:**
   - CloudKit sync for multi-device
   - Historical cycle data
   - Time-of-day variations

2. **Live Activity:**
   - Push notifications for remote updates
   - Multiple signal tracking
   - Route-based predictions

3. **Simulation:**
   - Multiple intersection scenarios
   - Variable cycle lengths
   - Rush hour patterns
   - Error condition testing

---

## Credits

Production modules implement Apple's latest frameworks:
- SwiftData (iOS 17+)
- ActivityKit (iOS 16.2+)
- Dynamic Island (iPhone 14 Pro+)

All code follows Swift best practices and Apple Human Interface Guidelines.
