import Foundation

protocol SignalPhasePredicting {
    func recordGreenLaunch(nodeID: String, timestamp: Date) async
    func predictNextGreen(nodeID: String, currentTime: Date) async -> SignalPrediction?
}

actor SignalPhasePredictor: SignalPhasePredicting {
    private let storage: SignalPhaseStorage
    private var patterns: [String: SignalCyclePattern] = [:]
    private var isLoaded = false
    
    private let minimumObservations = 3
    private let maxObservations = 100
    
    init(storage: SignalPhaseStorage = SignalPhaseStorage()) {
        self.storage = storage
    }
    
    // MARK: - Public Methods
    func recordGreenLaunch(nodeID: String, timestamp: Date) async {
        await ensureLoaded()
        
        let observation = SignalPhaseObservation(nodeID: nodeID, greenLaunchTime: timestamp)
        
        var pattern = patterns[nodeID] ?? SignalCyclePattern(nodeID: nodeID)
        pattern.observations.append(observation)
        
        // Keep only recent observations
        if pattern.observations.count > maxObservations {
            pattern.observations.removeFirst()
        }
        
        // Recalculate cycle pattern
        pattern = calculateCyclePattern(for: pattern)
        patterns[nodeID] = pattern
        
        // Persist to storage
        await storage.save(pattern: pattern)
    }
    
    func predictNextGreen(nodeID: String, currentTime: Date = Date()) async -> SignalPrediction? {
        await ensureLoaded()
        
        guard let pattern = patterns[nodeID],
              let cycleLength = pattern.cycleLength,
              let cycleOffset = pattern.cycleOffset,
              pattern.confidence > 0.5 else {
            return nil
        }
        
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: currentTime)
        let secondsSinceMidnight = currentTime.timeIntervalSince(midnight)
        
        // Calculate cycles since offset
        let timeSinceOffset = secondsSinceMidnight - cycleOffset
        let cyclesPassed = floor(timeSinceOffset / cycleLength)
        
        // Next green is at the next cycle boundary
        let nextGreenOffset = cycleOffset + (cyclesPassed + 1) * cycleLength
        let nextGreenTime = midnight.addingTimeInterval(nextGreenOffset)
        
        // If next green is in the past (shouldn't happen), move to next cycle
        if nextGreenTime < currentTime {
            let adjustedNextGreen = midnight.addingTimeInterval(nextGreenOffset + cycleLength)
            return SignalPrediction(
                nodeID: nodeID,
                nextGreenTime: adjustedNextGreen,
                cycleLength: cycleLength,
                confidence: pattern.confidence
            )
        }
        
        return SignalPrediction(
            nodeID: nodeID,
            nextGreenTime: nextGreenTime,
            cycleLength: cycleLength,
            confidence: pattern.confidence
        )
    }
    
    // MARK: - Private Methods
    private func ensureLoaded() async {
        guard !isLoaded else { return }
        await loadPatterns()
        isLoaded = true
    }
    
    private func loadPatterns() async {
        patterns = await storage.loadAllPatterns()
    }
    
    private func calculateCyclePattern(for pattern: SignalCyclePattern) -> SignalCyclePattern {
        var updated = pattern
        updated.lastUpdated = Date()
        
        guard pattern.observations.count >= minimumObservations else {
            updated.confidence = 0.0
            return updated
        }
        
        // Calculate intervals between consecutive observations
        let sortedObservations = pattern.observations.sorted { $0.greenLaunchTime < $1.greenLaunchTime }
        var intervals: [TimeInterval] = []
        
        for i in 1..<sortedObservations.count {
            let interval = sortedObservations[i].greenLaunchTime.timeIntervalSince(
                sortedObservations[i-1].greenLaunchTime
            )
            // Only consider intervals that look like signal cycles (15-180 seconds)
            if interval >= 15 && interval <= 180 {
                intervals.append(interval)
            }
        }
        
        guard !intervals.isEmpty else {
            updated.confidence = 0.0
            return updated
        }
        
        // Find the most common cycle length using clustering
        let cycleLength = findDominantCycle(from: intervals)
        updated.cycleLength = cycleLength
        
        // Calculate offset from midnight
        let offset = calculateCycleOffset(observations: sortedObservations, cycleLength: cycleLength)
        updated.cycleOffset = offset
        
        // Calculate confidence based on consistency
        let consistency = calculateConsistency(observations: sortedObservations, cycleLength: cycleLength, offset: offset)
        updated.confidence = min(1.0, max(0.0, consistency))
        
        return updated
    }
    
    private func findDominantCycle(from intervals: [TimeInterval]) -> TimeInterval {
        guard !intervals.isEmpty else { return 60.0 }
        
        // Use median as it's robust to outliers
        let sorted = intervals.sorted()
        let mid = sorted.count / 2
        
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }
    
    private func calculateCycleOffset(observations: [SignalPhaseObservation], cycleLength: TimeInterval) -> TimeInterval {
        guard !observations.isEmpty else { return 0 }
        
        // Use the time of day from recent observations to calculate offset
        let recentObservations = observations.suffix(10)
        let offsets = recentObservations.map { obs -> TimeInterval in
            let timeOfDay = obs.timeOfDay
            return timeOfDay.truncatingRemainder(dividingBy: cycleLength)
        }
        
        // Average the offsets
        return offsets.reduce(0, +) / Double(offsets.count)
    }
    
    private func calculateConsistency(observations: [SignalPhaseObservation], cycleLength: TimeInterval, offset: TimeInterval) -> Double {
        guard observations.count >= minimumObservations else { return 0.0 }
        
        var deviations: [TimeInterval] = []
        
        for observation in observations {
            let timeOfDay = observation.timeOfDay
            let expectedPhase = (timeOfDay - offset).truncatingRemainder(dividingBy: cycleLength)
            
            // Calculate how far off we are from expected
            let deviation = min(expectedPhase, cycleLength - expectedPhase)
            deviations.append(deviation)
        }
        
        // Calculate average deviation
        let avgDeviation = deviations.reduce(0, +) / Double(deviations.count)
        
        // Convert to confidence (lower deviation = higher confidence)
        // Allow up to 5 seconds deviation for high confidence
        let maxAcceptableDeviation: TimeInterval = 5.0
        let confidence = max(0.0, 1.0 - (avgDeviation / maxAcceptableDeviation))
        
        // Boost confidence with more observations
        let observationBoost = min(1.0, Double(observations.count) / Double(maxObservations))
        
        return confidence * 0.7 + observationBoost * 0.3
    }
}

// MARK: - Storage
actor SignalPhaseStorage {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "signal-phase-"
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func save(pattern: SignalCyclePattern) async {
        guard let data = try? encoder.encode(pattern) else { return }
        defaults.set(data, forKey: keyPrefix + pattern.nodeID)
    }
    
    func load(nodeID: String) async -> SignalCyclePattern? {
        guard let data = defaults.data(forKey: keyPrefix + nodeID) else {
            return nil
        }
        return try? decoder.decode(SignalCyclePattern.self, from: data)
    }
    
    func loadAllPatterns() async -> [String: SignalCyclePattern] {
        var patterns: [String: SignalCyclePattern] = [:]
        
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(keyPrefix) {
            guard let data = defaults.data(forKey: key),
                  let pattern = try? decoder.decode(SignalCyclePattern.self, from: data) else {
                continue
            }
            patterns[pattern.nodeID] = pattern
        }
        
        return patterns
    }
}
