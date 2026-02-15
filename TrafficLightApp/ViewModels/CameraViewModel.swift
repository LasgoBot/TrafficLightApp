import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    @Published var detectionResults: [DetectionResult] = []
    @Published var trafficLightDetection: TrafficLightDetection?
    @Published var countdown: TrafficLightCountdown = .init(secondsRemaining: 0, showCountdown: false)
    @Published var reliabilityMessage: String?

    let cameraManager = CameraManager()

    private let visionManager: VisionManaging
    private let frameGovernor = FrameRateGovernor()
    private let processingQueue = DispatchQueue(label: "camera.viewmodel.processing", qos: .userInitiated)

    var configuration: DetectionConfiguration = DetectionConfiguration()
    var predictedGreenAt: Date?

    init(visionManager: VisionManaging = VisionManager()) {
        self.visionManager = visionManager
        super.init()
        cameraManager.setDelegate(self, queue: processingQueue)
    }

    func start() {
        cameraManager.start()
    }

    func stop() {
        cameraManager.stop()
    }

    private func updateCountdown() {
        countdown = TrafficLightModel.countdown(from: trafficLightDetection, predictedGreenAt: predictedGreenAt)
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard frameGovernor.shouldProcessFrame(targetFPS: configuration.maxFPS) else { return }

            let (results, light) = visionManager.analyze(sampleBuffer: sampleBuffer, configuration: configuration)
            detectionResults = results
            trafficLightDetection = light

            if let light,
               light.state == .red,
               light.confidence >= 0.85 {
                predictedGreenAt = Date().addingTimeInterval(6)
            } else if light?.state == .yellow {
                predictedGreenAt = Date().addingTimeInterval(2)
            } else {
                predictedGreenAt = nil
            }

            updateCountdown()
            reliabilityMessage = (light?.confidence ?? 0) < 0.7 ? "Low confidence due to lighting or obstruction." : nil

            if countdown.showCountdown && countdown.secondsRemaining <= 3 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
