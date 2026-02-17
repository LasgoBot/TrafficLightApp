import XCTest
@testable import TrafficLightApp

final class SignalPhasePredictorTests: XCTestCase {
    
    func testSignalPhaseObservationCreation() {
        let timestamp = Date()
        let observation = SignalPhaseObservation(
            nodeID: "test-node-1",
            greenLaunchTime: timestamp
        )
        
        XCTAssertEqual(observation.nodeID, "test-node-1")
        XCTAssertEqual(observation.greenLaunchTime, timestamp)
        
        let calendar = Calendar.current
        let expectedDayOfWeek = calendar.component(.weekday, from: timestamp)
        XCTAssertEqual(observation.dayOfWeek, expectedDayOfWeek)
    }
    
    func testSignalCyclePatternInitialization() {
        let pattern = SignalCyclePattern(nodeID: "test-node-1")
        
        XCTAssertEqual(pattern.nodeID, "test-node-1")
        XCTAssertTrue(pattern.observations.isEmpty)
        XCTAssertNil(pattern.cycleLength)
        XCTAssertNil(pattern.cycleOffset)
        XCTAssertEqual(pattern.confidence, 0.0)
    }
    
    func testRecordGreenLaunch() async {
        let storage = SignalPhaseStorage()
        let predictor = SignalPhasePredictor(storage: storage)
        
        let nodeID = "test-node-1"
        let timestamp = Date()
        
        await predictor.recordGreenLaunch(nodeID: nodeID, timestamp: timestamp)
        
        // After one observation, we shouldn't have a prediction yet
        let prediction = await predictor.predictNextGreen(nodeID: nodeID)
        XCTAssertNil(prediction)
    }
    
    func testPredictionWithMultipleObservations() async {
        let storage = SignalPhaseStorage()
        let predictor = SignalPhasePredictor(storage: storage)
        
        let nodeID = "test-node-1"
        let baseTime = Date()
        let cycleLength: TimeInterval = 60 // 60 seconds
        
        // Record several observations at regular intervals
        for i in 0..<5 {
            let timestamp = baseTime.addingTimeInterval(TimeInterval(i) * cycleLength)
            await predictor.recordGreenLaunch(nodeID: nodeID, timestamp: timestamp)
        }
        
        // Now we should have a prediction
        let prediction = await predictor.predictNextGreen(nodeID: nodeID, currentTime: baseTime.addingTimeInterval(250))
        
        XCTAssertNotNil(prediction)
        if let prediction = prediction {
            XCTAssertEqual(prediction.nodeID, nodeID)
            XCTAssertGreaterThan(prediction.confidence, 0.5)
            XCTAssertGreaterThan(prediction.cycleLength, 50)
            XCTAssertLessThan(prediction.cycleLength, 70)
        }
    }
}
