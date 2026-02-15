import Foundation

enum PredictionMode: String {
    case onDevice
    case backend
    case hybrid
}

enum AppConfiguration {
    static let signalPollingInterval: TimeInterval = 1
    static let lowConfidenceThreshold = 0.72

    static var predictionMode: PredictionMode {
        let raw = ProcessInfo.processInfo.environment["TRAFFIC_PREDICTION_MODE"]?.lowercased() ?? "ondevice"
        return PredictionMode(rawValue: raw) ?? .onDevice
    }

    static var backendBaseURL: URL? {
        guard let raw = ProcessInfo.processInfo.environment["TRAFFIC_API_BASE_URL"] else {
            return nil
        }
        return URL(string: raw)
    }
}
