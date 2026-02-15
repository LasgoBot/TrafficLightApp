# Integration Notes: Detection + Navigation + Traffic Light Countdown

## On-device operation (default)

The app runs without backend setup:
- Camera capture via AVFoundation
- Vision-based proxy detections for lane/sign/vehicle/speed limit/traffic light
- Local predictive countdown logic with confidence gating
- MapKit navigation and ETA

## Navigation stack

- `RouteManager` uses `MKDirections` for route computation.
- `NavigationViewModel` tracks ETA, instruction distance, rerouting, and speed.
- Voice prompts use `AVSpeechSynthesizer`.

## Traffic light countdown logic

- Countdown only displays when detection confidence is >= 85%.
- Red/yellow states can show `3,2,1` countdown near expected green transition.
- In low-confidence situations, countdown is hidden to reduce false alerts.

## CoreML migration plan

Replace proxy Vision requests in `VisionManager` with real `VNCoreMLRequest` pipelines:
1. Traffic light classifier (red/yellow/green + confidence)
2. Lane segmentation model
3. Object detector for vehicles/signs/speed limits

## Optional backend integrations

- SPaT/MAP traffic signal timing feed for high-accuracy countdown.
- Parking availability feed near destination.
- Traffic incident feed for proactive rerouting.

## App Store risk controls

- Mandatory first-launch disclaimer acceptance.
- Permission denial handling with clear user instructions.
- Background location/audio only for navigation continuity.
