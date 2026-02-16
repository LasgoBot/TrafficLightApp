# DriveSense - Intelligent Navigation & Traffic AI (iOS 15+)

DriveSense is a premium driving-assistance app foundation combining:
- Camera-based lane/sign/vehicle/speed-limit overlays
- Traffic-light state detection with confidence-gated countdown cues
- Turn-by-turn navigation with rerouting and voice guidance
- Camera ↔ map mode switching with optional map picture-in-picture

## What was fixed in this hardening pass

### 1) Navigation quality upgrades
- Replaced mock autocomplete with `MKLocalSearchCompleter`-backed suggestions.
- Added completion resolution (`MKLocalSearch`) to obtain real `MKMapItem` destinations.
- Improved route error handling and persisted recent destinations.

### 2) Safety and UX reliability
- Added explicit camera permission gate before starting capture.
- Added permission error overlays and better accessibility labels on controls.
- Added first-launch mandatory disclaimer acceptance that cannot be dismissed.
- Wired settings voice-guidance toggle into spoken route instructions.

### 3) Product readiness and localization scaffold
- Added base localization setup (`en.lproj/Localizable.strings`).
- Added development region/localization keys in `Info.plist`.
- Expanded Xcode/App Store packaging guidance below.

## Important reality check before App Store

This repo is now a strong production scaffold, but **not final App Store gold** until you complete:
1. Integrate real `.mlmodel` files for traffic lights, lane segmentation, sign/speed-limit, and vehicle distance.
2. Run on-device real-world validation (day/night/rain/glare) with measured precision/recall.
3. Add a proper Xcode project (`.xcodeproj`) and include all target memberships/resources.
4. Complete legal/privacy docs in App Store Connect (privacy policy URL + support URL).

## How to get this into Xcode (first-time Codex user guide)

1. Open Xcode → **File > New > Project > iOS App**.
2. Name: `DriveSense`, Interface: SwiftUI, Language: Swift, iOS target: 15.0+.
3. Copy `TrafficLightApp/` and `TrafficLightAppTests/` into the new project folder.
4. Drag folders into Xcode navigator with:
   - ✅ Copy items if needed
   - ✅ Add to app target and test target as appropriate
5. Set app entry to `TrafficLightApp/TrafficLightAppApp.swift`.
6. In target settings, set Info.plist path to `TrafficLightApp/Resources/Info.plist`.
7. Ensure `PrivacyInfo.xcprivacy` and `en.lproj/Localizable.strings` are in **Copy Bundle Resources**.
8. Build and run on a physical iPhone (camera + motion + navigation quality require device testing).

## App Store compliance implemented

- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSMotionUsageDescription`
- Background modes (`location`, `audio`)
- iOS 17+ privacy manifest scaffold

## Frameworks and dependencies

No third-party libraries currently.
Uses Apple frameworks only: SwiftUI, MapKit, CoreLocation, AVFoundation, Vision, AVFAudio, Combine, UIKit, CoreMotion.

## Suggested App Store listing

- **App Name:** DriveSense - Intelligent Navigation
- **Subtitle:** Never miss a green light with countdown alerts
- **Keywords:** navigation, traffic light, lane assist, speed limit, driver safety, ETA, route planner

## TestFlight checklist (must-do)

- [ ] App icon set complete (including 1024x1024)
- [ ] Permission flows verified on clean installs
- [ ] Accessibility pass (VoiceOver + contrast + Dynamic Type)
- [ ] 30+ minute drive soak test (heat/battery/crashes)
- [ ] Day/night + adverse weather validation
- [ ] App Store Connect privacy metadata + policy URLs completed
- [ ] Screenshots captured for Assist, Countdown, Navigation, and Settings
