import CoreLocation
import Foundation

actor TelematicsObservationEngine: TrafficLightObservationProviding {
    // MARK: - Constants
    private let estimatedGreenPhaseFraction: Double = 0.3 // Assume 30% of cycle is green phase
    
    // MARK: - Properties
    private let nodeService: TrafficNodeService
    private let phasePredictor: SignalPhasePredictor
    
    // MARK: - Initialization
    init(nodeService: TrafficNodeService = TrafficNodeService(),
         phasePredictor: SignalPhasePredictor = SignalPhasePredictor()) {
        self.nodeService = nodeService
        self.phasePredictor = phasePredictor
    }
    
    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        guard let coordinate else { return nil }
        
        // Find nearest traffic signal node
        guard let node = try? await nodeService.findNearestTrafficSignal(
            to: coordinate,
            maxDistance: 50
        ) else {
            return nil
        }
        
        // Get prediction from phase predictor
        guard let prediction = await phasePredictor.predictNextGreen(
            nodeID: node.id,
            currentTime: Date()
        ) else {
            return nil
        }
        
        // Convert to TrafficSignal format
        return buildTrafficSignal(from: prediction, node: node, coordinate: coordinate)
    }
    
    private func buildTrafficSignal(
        from prediction: SignalPrediction,
        node: TrafficNode,
        coordinate: CLLocationCoordinate2D
    ) -> TrafficSignal {
        let now = Date()
        let timeToGreen = prediction.nextGreenTime.timeIntervalSince(now)
        
        // Determine current phase based on time to next green
        let phase: SignalPhase
        let phaseEndsAt: Date
        
        if timeToGreen <= 0 {
            // Currently green or just turned green
            phase = .green
            // Estimate green phase duration
            let estimatedGreenDuration = prediction.cycleLength * estimatedGreenPhaseFraction
            phaseEndsAt = now.addingTimeInterval(estimatedGreenDuration)
        } else if timeToGreen <= 5 {
            // About to turn green (yellow from other direction)
            phase = .yellow
            phaseEndsAt = prediction.nextGreenTime
        } else {
            // Currently red
            phase = .red
            phaseEndsAt = prediction.nextGreenTime
        }
        
        return TrafficSignal(
            id: UUID(),
            intersectionID: node.id,
            intersectionName: "OSM Node \(node.osmID)",
            coordinate: coordinate,
            phase: phase,
            nextGreenAt: prediction.nextGreenTime,
            phaseEndsAt: phaseEndsAt,
            confidence: prediction.confidence,
            source: "telematics-v2x",
            serverTimestamp: now
        )
    }
}
