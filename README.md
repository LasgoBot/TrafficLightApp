# DriveSense - Intelligent Navigation & Traffic AI (iOS 15+)

Premium daily-driving app blending navigation and camera AI assistance:
- Traffic light detection with confidence-gated countdown cues (`3, 2, 1`)
- Lane/sign/vehicle/speed-limit overlays
- Turn-by-turn navigation with rerouting, ETA, route preferences, and voice prompts
- Waze-style map + camera toggle with optional picture-in-picture map

## What was improved in this production pass

- Added requested architecture modules:
  - `Models/DetectionModel.swift`
  - `Models/NavigationModel.swift`
  - `Models/TrafficLightModel.swift`
  - `ViewModels/CameraViewModel.swift`
  - `ViewModels/NavigationViewModel.swift`
  - `ViewModels/MapViewModel.swift`
  - `Services/LocationManager.swift`
  - `Services/CameraManager.swift`
  - `Services/VisionManager.swift`
  - `Services/Navigation/RouteManager.swift`
  - `Services/Navigation/SpeechManager.swift`
- Added mandatory onboarding disclaimer acceptance on first launch.
- Added improved settings for toggles, sensitivity, voice guidance, route preference, units, map mode.
- Added map-first navigation screen with search/autocomplete scaffold, rerouting hooks, and speed vs speed-limit display.

## App Store compliance included

- `Info.plist` keys:
  - `NSCameraUsageDescription`: "Camera access required for real-time traffic detection and safety features"
  - `NSLocationWhenInUseUsageDescription`: "Location access required for navigation and speed limit detection"
  - `NSLocationAlwaysAndWhenInUseUsageDescription`: "Continuous location for turn-by-turn navigation"
  - `NSMotionUsageDescription`: "Motion data helps improve detection accuracy"
- Background modes configured: location + audio.
- Privacy manifest scaffold (`PrivacyInfo.xcprivacy`) for iOS 17+.

## Performance strategy

- Frame skipping (`FrameRateGovernor`) to sustain real-time performance under load.
- Camera output discards late frames for stability.
- Main UI kept responsive while detection runs on background processing queues.
- Reliability message appears when confidence/conditions degrade.

## CoreML status

The code now provides a clear `VisionManager` integration seam for `VNCoreMLRequest`.
Current implementation uses a production-safe proxy detector scaffold in this repo (no binary ML model files committed yet).
To finalize launch-grade recognition, plug in trained `.mlmodel` assets for:
1. Traffic light state classification
2. Lane segmentation
3. Traffic sign + speed-limit detection
4. Vehicle detection and distance estimation

## Suggested App Store listing copy

**App Name:** DriveSense - Intelligent Navigation

**Subtitle:** Never miss a green light with countdown alerts

**Keywords:** navigation, traffic light, lane assist, speed limit, driver safety, ETA, route planner

**Description:**
DriveSense combines smart turn-by-turn navigation with advanced camera-based traffic awareness. Get lane overlays, traffic-sign insights, speed-limit awareness, and confidence-based traffic-light countdown assistance—all in one premium driving app.

## Third-party dependencies

No third-party libraries currently required.
Frameworks used: SwiftUI, MapKit, CoreLocation, AVFoundation, Vision, AVFAudio, Combine, UIKit.

## TestFlight release checklist

- [ ] Include app icons in all required sizes (including 1024x1024 App Store icon)
- [ ] Validate dark mode and accessibility labels (VoiceOver)
- [ ] Validate camera + navigation in real-world day/night + rain
- [ ] Confirm permission flows on fresh install and denied states
- [ ] Verify thermal + battery behavior during 30+ minute sessions
- [ ] Run full UI and unit tests on iPhone 12+ target matrix
- [ ] Upload privacy policy and support URL in App Store Connect
- [ ] Capture screenshots: camera overlay, countdown, navigation, settings
