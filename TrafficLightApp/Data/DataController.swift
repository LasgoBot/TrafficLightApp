import Foundation
import SwiftData
import CoreLocation

@MainActor
final class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        let schema = Schema([
            TrafficNodeEntity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func saveNode(geoID: String, coordinate: CLLocationCoordinate2D) {
        // Check if node already exists
        let descriptor = FetchDescriptor<TrafficNodeEntity>(
            predicate: #Predicate { $0.geoID == geoID }
        )
        
        do {
            let existing = try context.fetch(descriptor)
            if existing.isEmpty {
                let node = TrafficNodeEntity(
                    geoID: geoID,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                context.insert(node)
                try context.save()
                print("✅ Saved new TrafficNode: \(geoID)")
            } else {
                print("ℹ️ TrafficNode already exists: \(geoID)")
            }
        } catch {
            print("❌ Error saving node: \(error)")
        }
    }
    
    func updateCycleDuration(geoID: String, duration: TimeInterval, greenTimestamp: Date) {
        let descriptor = FetchDescriptor<TrafficNodeEntity>(
            predicate: #Predicate { $0.geoID == geoID }
        )
        
        do {
            let nodes = try context.fetch(descriptor)
            if let node = nodes.first {
                node.updateCycle(duration: duration, greenTimestamp: greenTimestamp)
                try context.save()
                print("✅ Updated cycle duration for \(geoID): \(duration)s, confidence: \(node.confidenceScore)")
            } else {
                print("⚠️ Node not found for update: \(geoID)")
            }
        } catch {
            print("❌ Error updating cycle: \(error)")
        }
    }
    
    func getNode(geoID: String) -> TrafficNodeEntity? {
        let descriptor = FetchDescriptor<TrafficNodeEntity>(
            predicate: #Predicate { $0.geoID == geoID }
        )
        
        do {
            let nodes = try context.fetch(descriptor)
            return nodes.first
        } catch {
            print("❌ Error fetching node: \(error)")
            return nil
        }
    }
    
    func getAllNodes() -> [TrafficNodeEntity] {
        let descriptor = FetchDescriptor<TrafficNodeEntity>()
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching all nodes: \(error)")
            return []
        }
    }
    
    func getNodesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double = 100) -> [TrafficNodeEntity] {
        let allNodes = getAllNodes()
        
        return allNodes.filter { node in
            let nodeLocation = CLLocation(latitude: node.latitude, longitude: node.longitude)
            let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return nodeLocation.distance(from: targetLocation) <= radiusMeters
        }
    }
    
    func deleteNode(geoID: String) {
        let descriptor = FetchDescriptor<TrafficNodeEntity>(
            predicate: #Predicate { $0.geoID == geoID }
        )
        
        do {
            let nodes = try context.fetch(descriptor)
            for node in nodes {
                context.delete(node)
            }
            try context.save()
            print("✅ Deleted node: \(geoID)")
        } catch {
            print("❌ Error deleting node: \(error)")
        }
    }
    
    func deleteAllNodes() {
        let descriptor = FetchDescriptor<TrafficNodeEntity>()
        
        do {
            let nodes = try context.fetch(descriptor)
            for node in nodes {
                context.delete(node)
            }
            try context.save()
            print("✅ Deleted all nodes")
        } catch {
            print("❌ Error deleting all nodes: \(error)")
        }
    }
}
