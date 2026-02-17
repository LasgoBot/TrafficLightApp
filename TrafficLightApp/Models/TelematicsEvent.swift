import CoreLocation
import Foundation

enum TelematicsEvent {
    case hardStop(location: CLLocation, timestamp: Date)
    case greenLightLaunch(location: CLLocation, timestamp: Date)
    case moving(speedKPH: Double)
    case stopped(location: CLLocation)
}

struct VehicleState {
    let location: CLLocation
    let speedKPH: Double
    let accelerationG: Double
    let timestamp: Date
    
    var isStationary: Bool {
        speedKPH < 1.0
    }
    
    var isMoving: Bool {
        speedKPH >= 5.0
    }
}
