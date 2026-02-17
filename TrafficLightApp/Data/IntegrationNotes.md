# Integration Notes: Finalizing Production Launch

## What is production-ready now

- Camera/navigation app architecture (MVVM + service boundaries)
- Real MapKit route calculation + search completion plumbing
- Confidence-gated traffic-light countdown UI behavior
- Permission messaging, onboarding disclaimer gate, and settings controls

## What must still be completed before App Store release

1. **Real CoreML models**
   - Traffic light classifier (`red/yellow/green/unknown`)
   - Lane segmentation
   - Sign/speed-limit detector
   - Vehicle detector with distance estimation

2. **Model wiring**
   - Replace proxy logic in `VisionManager` with `VNCoreMLRequest`
   - Keep confidence thresholds >= 0.85 for countdown-critical alerts

3. **Validation & QA**
   - Measure precision/recall across low-light, glare, occlusion
   - Run long-drive thermal/battery tests
   - Tune frame skipping and FPS ceilings by device class

4. **Packaging**
   - Create and configure `.xcodeproj`
   - Add all source/resources/entitlements to correct targets
   - Confirm Info.plist + privacy manifest are bundled

## Backend (optional)

Current implementation works without backend.
If you need infrastructure-grade signal timing, integrate SPaT/MAP and fuse with on-device detections.
