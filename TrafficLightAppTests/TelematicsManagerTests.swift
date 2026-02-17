import CoreLocation
import XCTest
@testable import TrafficLightApp

final class TelematicsManagerTests: XCTestCase {
    
    func testVehicleStateStationary() {
        let state = VehicleState(
            location: CLLocation(latitude: 37.7749, longitude: -122.4194),
            speedKPH: 0.5,
            accelerationG: 1.0,
            timestamp: Date()
        )
        
        XCTAssertTrue(state.isStationary)
        XCTAssertFalse(state.isMoving)
    }
    
    func testVehicleStateMoving() {
        let state = VehicleState(
            location: CLLocation(latitude: 37.7749, longitude: -122.4194),
            speedKPH: 30.0,
            accelerationG: 1.0,
            timestamp: Date()
        )
        
        XCTAssertFalse(state.isStationary)
        XCTAssertTrue(state.isMoving)
    }
    
    @MainActor
    func testTelematicsManagerInitialization() {
        let manager = TelematicsManager()
        XCTAssertNil(manager.currentState)
        XCTAssertNil(manager.lastEvent)
    }
}
