import AVFoundation
import Combine
import CoreLocation
import Foundation
import UIKit

@MainActor
final class DriveAssistViewModel: NSObject, ObservableObject {
    @Published var detections: [DetectionObservation] = []
    @Published var preferences: DetectionPreferences = .default
    @Published var safetyState: DriveSafetyState = .unknown
    @Published var permissionMessage: String?
    @Published var showDisclaimer = true

    let locationService = LocationService()
    let permissionManager = PermissionManager()
    let cameraManager = CameraSessionManager()

    private let visionService: VisionDetecting
    private let frameGovernor = FrameRateGovernor()
    private let processingQueue = DispatchQueue(label: "detection.processing.queue", qos: .userInitiated)

    init(visionService: VisionDetecting = VisionDetectionService()) {
        self.visionService = visionService
        super.init()
        cameraManager.videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
    }

    func onAppear() {
        Task {
            await permissionManager.requestAllPermissions(locationService: locationService)
            guard permissionManager.cameraAuthorized else {
                permissionMessage = "Camera access is required for lane/sign/vehicle detection. Enable it in Settings."
                return
            }
            guard permissionManager.locationAuthorized else {
                permissionMessage = "Location access improves road-context and speed-limit predictions."
                return
            }
            permissionMessage = nil
            cameraManager.start()
        }
    }

    func onDisappear() {
        cameraManager.stop()
    }

    func updatePreferences(_ updated: DetectionPreferences) {
        preferences = updated
    }

    private func updateSafetyState(using sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let ambientEstimate = min(1.0, max(0.05, Float(width * height) / 2_000_000.0))
        safetyState = DriveSafetyState(ambientLightScore: ambientEstimate,
                                       glareScore: ambientEstimate > 0.9 ? 0.7 : 0.25,
                                       obstructionScore: detections.isEmpty ? 0.45 : 0.2)
    }

    private func triggerCriticalAlertIfNeeded() {
        let nearbyVehicle = detections.first { $0.category == .vehicle && $0.boundingBox.maxY > 0.65 }
        guard nearbyVehicle != nil, preferences.enableHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

extension DriveAssistViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard frameGovernor.shouldProcessFrame(targetFPS: preferences.maxProcessingFPS) else { return }

            let results = visionService.processFrame(sampleBuffer, preferences: preferences)
            detections = results
            updateSafetyState(using: sampleBuffer)
            triggerCriticalAlertIfNeeded()
        }
    }
}
