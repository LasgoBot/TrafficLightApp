import Foundation

struct SignalPhaseObservation: Codable {
    let nodeID: String
    let greenLaunchTime: Date
    let dayOfWeek: Int
    let timeOfDay: TimeInterval // Seconds since midnight
    
    init(nodeID: String, greenLaunchTime: Date) {
        self.nodeID = nodeID
        self.greenLaunchTime = greenLaunchTime
        
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: greenLaunchTime)
        
        let midnight = calendar.startOfDay(for: greenLaunchTime)
        self.timeOfDay = greenLaunchTime.timeIntervalSince(midnight)
    }
}

struct SignalCyclePattern: Codable {
    let nodeID: String
    var observations: [SignalPhaseObservation]
    var cycleLength: TimeInterval?
    var cycleOffset: TimeInterval?
    var confidence: Double
    var lastUpdated: Date
    
    init(nodeID: String) {
        self.nodeID = nodeID
        self.observations = []
        self.cycleLength = nil
        self.cycleOffset = nil
        self.confidence = 0.0
        self.lastUpdated = Date()
    }
}

struct SignalPrediction {
    let nodeID: String
    let nextGreenTime: Date
    let cycleLength: TimeInterval
    let confidence: Double
}
