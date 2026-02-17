import CoreLocation
import Foundation

protocol TrafficNodeProviding {
    func findTrafficSignals(near coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [TrafficNode]
}

actor TrafficNodeService: TrafficNodeProviding {
    private let cache: TrafficNodeCache
    private let overpassClient: OverpassAPIClient
    
    init(cache: TrafficNodeCache = TrafficNodeCache(),
         overpassClient: OverpassAPIClient = OverpassAPIClient()) {
        self.cache = cache
        self.overpassClient = overpassClient
    }
    
    func findTrafficSignals(near coordinate: CLLocationCoordinate2D, radius: Double = 500) async throws -> [TrafficNode] {
        // Check cache first
        if let cachedNodes = await cache.nodes(near: coordinate, radius: radius) {
            return cachedNodes
        }
        
        // Fetch from Overpass API
        let nodes = try await overpassClient.fetchTrafficSignals(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: radius
        )
        
        // Cache the results
        await cache.store(nodes: nodes, near: coordinate)
        
        return nodes
    }
    
    func findNearestTrafficSignal(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 50) async throws -> TrafficNode? {
        let nodes = try await findTrafficSignals(near: coordinate, radius: maxDistance)
        
        return nodes.min(by: { node1, node2 in
            coordinate.distance(to: node1.coordinate) < coordinate.distance(to: node2.coordinate)
        })
    }
}

// MARK: - Overpass API Client
struct OverpassAPIClient {
    private let session: URLSession
    private let baseURL = "https://overpass-api.de/api/interpreter"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchTrafficSignals(latitude: Double, longitude: Double, radius: Double) async throws -> [TrafficNode] {
        let query = buildOverpassQuery(latitude: latitude, longitude: longitude, radius: radius)
        
        guard let url = URL(string: baseURL) else {
            throw TrafficNodeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.timeoutInterval = 10
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TrafficNodeError.networkError
        }
        
        return try parseOverpassResponse(data)
    }
    
    private func buildOverpassQuery(latitude: Double, longitude: Double, radius: Double) -> String {
        """
        [out:json][timeout:10];
        (
          node["highway"="traffic_signals"](around:\(radius),\(latitude),\(longitude));
        );
        out body;
        """
    }
    
    private func parseOverpassResponse(_ data: Data) throws -> [TrafficNode] {
        let response = try JSONDecoder().decode(OverpassResponse.self, from: data)
        
        return response.elements.map { element in
            TrafficNode(
                id: "osm-\(element.id)",
                coordinate: CLLocationCoordinate2D(latitude: element.lat, longitude: element.lon),
                osmID: element.id,
                tags: element.tags ?? [:]
            )
        }
    }
}

// MARK: - Cache
actor TrafficNodeCache {
    private var cache: [String: CachedNodes] = [:]
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    struct CachedNodes {
        let nodes: [TrafficNode]
        let timestamp: Date
        let coordinate: CLLocationCoordinate2D
    }
    
    func nodes(near coordinate: CLLocationCoordinate2D, radius: Double) -> [TrafficNode]? {
        let geohash = coordinate.geohash(precision: 7)
        
        guard let cached = cache[geohash] else {
            return nil
        }
        
        // Check if cache is expired
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: geohash)
            return nil
        }
        
        // Check if cached location is close enough
        if coordinate.distance(to: cached.coordinate) > radius * 0.5 {
            return nil
        }
        
        return cached.nodes
    }
    
    func store(nodes: [TrafficNode], near coordinate: CLLocationCoordinate2D) {
        let geohash = coordinate.geohash(precision: 7)
        cache[geohash] = CachedNodes(
            nodes: nodes,
            timestamp: Date(),
            coordinate: coordinate
        )
    }
    
    func clearExpiredCache() {
        let now = Date()
        cache = cache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheExpiration
        }
    }
}

// MARK: - DTOs
private struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Codable {
    let id: Int64
    let lat: Double
    let lon: Double
    let tags: [String: String]?
}

// MARK: - Errors
enum TrafficNodeError: Error {
    case invalidURL
    case networkError
    case parseError
}
