import CoreLocation
import XCTest
@testable import TrafficLightApp

final class TelematicsObservationEngineTests: XCTestCase {
    
    func testPredictSignalWithNoNode() async {
        let engine = TelematicsObservationEngine()
        
        // Test with a location that likely has no traffic signals nearby
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let signal = await engine.predictSignal(near: coordinate)
        
        // Should return nil if no node is found
        XCTAssertNil(signal)
    }
    
    func testPredictSignalWithNilCoordinate() async {
        let engine = TelematicsObservationEngine()
        
        let signal = await engine.predictSignal(near: nil)
        
        XCTAssertNil(signal)
    }
}

final class TelematicsServiceTests: XCTestCase {
    
    @MainActor
    func testTelematicsServiceInitialization() {
        let service = TelematicsService()
        
        XCTAssertFalse(service.isMonitoring)
        XCTAssertNil(service.lastPrediction)
    }
    
    @MainActor
    func testStartStopMonitoring() {
        let service = TelematicsService()
        
        service.startMonitoring()
        XCTAssertTrue(service.isMonitoring)
        
        service.stopMonitoring()
        XCTAssertFalse(service.isMonitoring)
    }
}
