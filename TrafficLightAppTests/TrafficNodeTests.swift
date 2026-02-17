import CoreLocation
import XCTest
@testable import TrafficLightApp

final class TrafficNodeTests: XCTestCase {
    
    func testTrafficNodeCreation() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let node = TrafficNode(
            id: "test-1",
            coordinate: coordinate,
            osmID: 123456,
            tags: ["highway": "traffic_signals"]
        )
        
        XCTAssertEqual(node.id, "test-1")
        XCTAssertEqual(node.osmID, 123456)
        XCTAssertEqual(node.coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(node.coordinate.longitude, -122.4194, accuracy: 0.0001)
    }
    
    func testGeohashGeneration() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let geohash = coordinate.geohash(precision: 7)
        
        XCTAssertEqual(geohash.count, 7)
        XCTAssertFalse(geohash.isEmpty)
    }
    
    func testGeohashConsistency() {
        let coordinate1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let coordinate2 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        XCTAssertEqual(coordinate1.geohash(precision: 7), coordinate2.geohash(precision: 7))
    }
    
    func testDistanceCalculation() {
        let coord1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let coord2 = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4194)
        
        let distance = coord1.distance(to: coord2)
        
        // Distance should be approximately 11 meters (1 degree latitude ≈ 111km)
        XCTAssertGreaterThan(distance, 10)
        XCTAssertLessThan(distance, 15)
    }
}
