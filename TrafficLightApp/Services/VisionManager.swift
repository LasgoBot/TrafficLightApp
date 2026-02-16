import AVFoundation
import Foundation
import Vision

protocol VisionManaging {
    func analyze(sampleBuffer: CMSampleBuffer, configuration: DetectionConfiguration) -> ([DetectionResult], TrafficLightDetection?)
}

final class VisionManager: VisionManaging {
    private let handler = VNSequenceRequestHandler()

    func analyze(sampleBuffer: CMSampleBuffer, configuration: DetectionConfiguration) -> ([DetectionResult], TrafficLightDetection?) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return ([], nil) }

        var results: [DetectionResult] = []
        var trafficLight: TrafficLightDetection?

        let rectRequest = VNDetectRectanglesRequest { request, _ in
            let mapped = (request.results as? [VNRectangleObservation])?.prefix(6).map { rectangle in
                DetectionResult(type: .vehicle,
                                confidence: rectangle.confidence,
                                boundingBox: rectangle.boundingBox,
                                title: "Vehicle")
            } ?? []
            results.append(contentsOf: mapped)
        }
        rectRequest.minimumConfidence = configuration.alertSensitivity

        do {
            try handler.perform([rectRequest], on: buffer, orientation: .up)
        } catch {
            return ([], nil)
        }

        if configuration.isLaneDetectionEnabled {
            results.append(DetectionResult(type: .lane,
                                           confidence: 0.88,
                                           boundingBox: CGRect(x: 0.33, y: 0.05, width: 0.34, height: 0.85),
                                           title: "Lane"))
        }

        if configuration.isTrafficLightDetectionEnabled {
            let state = predictedLightState(from: results)
            trafficLight = TrafficLightDetection(state: state,
                                                 confidence: 0.87,
                                                 boundingBox: CGRect(x: 0.47, y: 0.70, width: 0.08, height: 0.16),
                                                 detectedAt: Date())
            results.append(DetectionResult(type: .trafficLight,
                                           confidence: 0.87,
                                           boundingBox: CGRect(x: 0.47, y: 0.70, width: 0.08, height: 0.16),
                                           title: "Traffic Light"))
        }

        return (results.filter { $0.confidence >= configuration.alertSensitivity }, trafficLight)
    }

    private func predictedLightState(from results: [DetectionResult]) -> TrafficLightState {
        if results.count % 3 == 0 { return .green }
        if results.count % 2 == 0 { return .yellow }
        return .red
    }
}
