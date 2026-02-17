import XCTest
import CoreLocation
@testable import TrafficLightApp

@MainActor
final class DataControllerTests: XCTestCase {
    var dataController: DataController!
    
    override func setUp() async throws {
        dataController = DataController.shared
        // Clean up before each test
        dataController.deleteAllNodes()
    }
    
    override func tearDown() async throws {
        // Clean up after each test
        dataController.deleteAllNodes()
        dataController = nil
    }
    
    func testSaveNode() {
        let geoID = "test_node_001"
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        
        let node = dataController.getNode(geoID: geoID)
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.geoID, geoID)
        XCTAssertEqual(node?.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(node?.longitude, coordinate.longitude, accuracy: 0.0001)
    }
    
    func testUpdateCycleDuration() {
        let geoID = "test_node_002"
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Save node
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        
        // Update cycle
        let duration: TimeInterval = 45.0
        let timestamp = Date()
        dataController.updateCycleDuration(geoID: geoID, duration: duration, greenTimestamp: timestamp)
        
        let node = dataController.getNode(geoID: geoID)
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.cycleDuration, duration, accuracy: 0.1)
        XCTAssertEqual(node?.confidenceScore, 1) // First update
    }
    
    func testConfidenceIncrement() {
        let geoID = "test_node_003"
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Save node
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        
        // Update multiple times
        for i in 1...5 {
            dataController.updateCycleDuration(
                geoID: geoID,
                duration: 45.0,
                greenTimestamp: Date()
            )
            
            let node = dataController.getNode(geoID: geoID)
            XCTAssertEqual(node?.confidenceScore, i)
        }
    }
    
    func testGetNodesNear() {
        // Save multiple nodes
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Node 1: Close (10m away)
        let coord1 = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4194)
        dataController.saveNode(geoID: "node_1", coordinate: coord1)
        
        // Node 2: Medium (50m away)
        let coord2 = CLLocationCoordinate2D(latitude: 37.7754, longitude: -122.4194)
        dataController.saveNode(geoID: "node_2", coordinate: coord2)
        
        // Node 3: Far (200m away)
        let coord3 = CLLocationCoordinate2D(latitude: 37.7767, longitude: -122.4194)
        dataController.saveNode(geoID: "node_3", coordinate: coord3)
        
        // Query within 100m radius
        let nearbyNodes = dataController.getNodesNear(coordinate: center, radiusMeters: 100)
        
        // Should find nodes 1 and 2, but not 3
        XCTAssertEqual(nearbyNodes.count, 2)
        XCTAssertTrue(nearbyNodes.contains { $0.geoID == "node_1" })
        XCTAssertTrue(nearbyNodes.contains { $0.geoID == "node_2" })
        XCTAssertFalse(nearbyNodes.contains { $0.geoID == "node_3" })
    }
    
    func testDeleteNode() {
        let geoID = "test_node_004"
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Save node
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        XCTAssertNotNil(dataController.getNode(geoID: geoID))
        
        // Delete node
        dataController.deleteNode(geoID: geoID)
        XCTAssertNil(dataController.getNode(geoID: geoID))
    }
    
    func testDeleteAllNodes() {
        // Save multiple nodes
        for i in 1...5 {
            let geoID = "test_node_\(i)"
            let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194 + Double(i) * 0.001)
            dataController.saveNode(geoID: geoID, coordinate: coordinate)
        }
        
        XCTAssertEqual(dataController.getAllNodes().count, 5)
        
        // Delete all
        dataController.deleteAllNodes()
        XCTAssertEqual(dataController.getAllNodes().count, 0)
    }
    
    func testDuplicateSave() {
        let geoID = "test_node_005"
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Save twice
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        dataController.saveNode(geoID: geoID, coordinate: coordinate)
        
        // Should only have one node
        let allNodes = dataController.getAllNodes()
        XCTAssertEqual(allNodes.count, 1)
        XCTAssertEqual(allNodes.first?.geoID, geoID)
    }
}
