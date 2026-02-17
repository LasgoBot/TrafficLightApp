import ActivityKit
import Foundation
import CoreLocation

@available(iOS 16.2, *)
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published private(set) var currentActivity: Activity<TrafficActivityAttributes>?
    @Published private(set) var isActivityActive = false
    
    private init() {}
    
    // MARK: - Start Activity
    func startActivity(intersectionName: String, geoID: String, initialState: TrafficLightState = .red, countdown: Int = 30, targetSpeed: Int = 30) {
        // Check if Live Activities are supported and enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }
        
        // End existing activity if any
        endActivity()
        
        let attributes = TrafficActivityAttributes(
            intersectionName: intersectionName,
            geoID: geoID
        )
        
        let initialContent = TrafficActivityAttributes.ContentState(
            trafficLightState: initialState,
            countdownSeconds: countdown,
            targetSpeed: targetSpeed,
            lastUpdate: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContent, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            print("✅ Started Live Activity for: \(intersectionName)")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
        }
    }
    
    // MARK: - Update Activity
    func updateActivity(state: TrafficLightState, countdown: Int, targetSpeed: Int) {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }
        
        let updatedContent = TrafficActivityAttributes.ContentState(
            trafficLightState: state,
            countdownSeconds: countdown,
            targetSpeed: targetSpeed,
            lastUpdate: Date()
        )
        
        Task {
            await activity.update(using: updatedContent)
            print("✅ Updated Live Activity: \(state.rawValue), \(countdown)s")
        }
    }
    
    // MARK: - End Activity
    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = currentActivity else {
            return
        }
        
        Task {
            await activity.end(using: nil, dismissalPolicy: dismissalPolicy)
            currentActivity = nil
            isActivityActive = false
            print("✅ Ended Live Activity")
        }
    }
    
    // MARK: - Update from Prediction
    func updateFromPrediction(prediction: SignalPrediction, currentSpeed: Double) {
        let timeToGreen = prediction.nextGreenTime.timeIntervalSinceNow
        let countdown = max(0, Int(timeToGreen.rounded()))
        
        // Determine current state based on time to green
        let state: TrafficLightState
        if timeToGreen <= 0 {
            state = .green
        } else if timeToGreen <= 3 {
            state = .yellow
        } else {
            state = .red
        }
        
        // Calculate GLOSA target speed (optimal speed to arrive at green light)
        // Simple calculation: if we're stopped and light is red, suggest standard speed
        let targetSpeed = calculateGLOSASpeed(
            timeToGreen: timeToGreen,
            currentSpeed: currentSpeed,
            cycleDuration: prediction.cycleLength
        )
        
        updateActivity(state: state, countdown: countdown, targetSpeed: targetSpeed)
    }
    
    // MARK: - GLOSA Speed Calculation
    private func calculateGLOSASpeed(timeToGreen: TimeInterval, currentSpeed: Double, cycleDuration: TimeInterval) -> Int {
        // If we're stopped at a red light
        if currentSpeed < 5 && timeToGreen > 0 {
            // Suggest speed based on time remaining
            if timeToGreen < 15 {
                return 25 // Slow approach
            } else if timeToGreen < 30 {
                return 30 // Medium speed
            } else {
                return 35 // Standard speed
            }
        }
        
        // If we're moving, maintain current speed or suggest adjustment
        let currentSpeedMPH = Int(currentSpeed * 0.621371) // Convert km/h to mph
        
        if timeToGreen < 5 {
            // Speed up to catch green
            return min(currentSpeedMPH + 5, 35)
        } else if timeToGreen > 20 {
            // Slow down to arrive at next green
            return max(currentSpeedMPH - 5, 25)
        }
        
        return currentSpeedMPH
    }
}
