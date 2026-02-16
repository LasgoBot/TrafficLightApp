import Foundation

struct IntersectionCycleProfile: Codable {
    let intersectionID: String
    var redDuration: TimeInterval
    var yellowDuration: TimeInterval
    var greenDuration: TimeInterval
    var sampleCount: Int
    var lastUpdatedAt: Date

    static func defaultProfile(intersectionID: String) -> IntersectionCycleProfile {
        IntersectionCycleProfile(intersectionID: intersectionID,
                                 redDuration: 28,
                                 yellowDuration: 4,
                                 greenDuration: 28,
                                 sampleCount: 1,
                                 lastUpdatedAt: Date())
    }

    var cycleDuration: TimeInterval {
        redDuration + yellowDuration + greenDuration
    }
}
