import AVFoundation
import Foundation
import Vision

protocol VisionDetecting {
    func processFrame(_ sampleBuffer: CMSampleBuffer, preferences: DetectionPreferences) -> [DetectionObservation]
}

final class VisionDetectionService: VisionDetecting {
    private let sequenceHandler = VNSequenceRequestHandler()

    func processFrame(_ sampleBuffer: CMSampleBuffer, preferences: DetectionPreferences) -> [DetectionObservation] {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return [] }

        var observations = [DetectionObservation]()
        let requests = buildRequests(preferences: preferences) { newObservations in
            observations.append(contentsOf: newObservations)
        }

        do {
            try sequenceHandler.perform(requests, on: pixelBuffer, orientation: .up)
        } catch {
            return []
        }

        return observations.filter { $0.confidence >= preferences.minimumConfidence }
    }

    private func buildRequests(preferences: DetectionPreferences,
                               onResult: @escaping ([DetectionObservation]) -> Void) -> [VNRequest] {
        var requests = [VNRequest]()

        if preferences.vehicleDistanceEnabled || preferences.signDetectionEnabled || preferences.speedLimitEnabled {
            let rectanglesRequest = VNDetectRectanglesRequest { request, _ in
                let mapped = (request.results as? [VNRectangleObservation])?.prefix(5).enumerated().map { index, item in
                    let category: DetectionCategory = index % 2 == 0 ? .vehicle : .trafficSign
                    return DetectionObservation(category: category,
                                                confidence: item.confidence,
                                                boundingBox: item.boundingBox,
                                                label: category == .vehicle ? "vehicle_proxy" : "sign_proxy")
                } ?? []
                onResult(mapped)
            }
            rectanglesRequest.minimumConfidence = preferences.minimumConfidence
            requests.append(rectanglesRequest)
        }

        if preferences.laneDetectionEnabled {
            let laneProxy = DetectionObservation(category: .lane,
                                                 confidence: 0.8,
                                                 boundingBox: CGRect(x: 0.30, y: 0.08, width: 0.40, height: 0.80),
                                                 label: "lane_proxy")
            onResult([laneProxy])
        }

        return requests
    }
}
