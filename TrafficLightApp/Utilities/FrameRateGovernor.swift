import Foundation

final class FrameRateGovernor {
    private var lastProcessingTime: Date = .distantPast

    func shouldProcessFrame(targetFPS: Double) -> Bool {
        guard targetFPS > 0 else { return false }
        let minimumInterval = 1.0 / targetFPS
        let now = Date()
        guard now.timeIntervalSince(lastProcessingTime) >= minimumInterval else {
            return false
        }
        lastProcessingTime = now
        return true
    }
}
