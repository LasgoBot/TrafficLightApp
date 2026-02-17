import CoreLocation
import Foundation

struct TrafficNode: Codable, Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let osmID: Int64
    let tags: [String: String]
    
    var geohash: String {
        coordinate.geohash(precision: 7)
    }
    
    init(id: String, coordinate: CLLocationCoordinate2D, osmID: Int64, tags: [String: String] = [:]) {
        self.id = id
        self.coordinate = coordinate
        self.osmID = osmID
        self.tags = tags
    }
}

extension CLLocationCoordinate2D {
    func geohash(precision: Int) -> String {
        let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"
        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)
        var hash = ""
        var isEven = true
        var bit = 0
        var ch = 0
        
        while hash.count < precision {
            if isEven {
                let mid = (lonRange.0 + lonRange.1) / 2
                if longitude > mid {
                    ch |= (1 << (4 - bit))
                    lonRange.0 = mid
                } else {
                    lonRange.1 = mid
                }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if latitude > mid {
                    ch |= (1 << (4 - bit))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }
            
            isEven = !isEven
            
            if bit < 4 {
                bit += 1
            } else {
                hash.append(base32[base32.index(base32.startIndex, offsetBy: ch)])
                bit = 0
                ch = 0
            }
        }
        
        return hash
    }
    
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}
