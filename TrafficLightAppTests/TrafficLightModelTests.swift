import CoreGraphics
import XCTest
@testable import TrafficLightApp

final class TrafficLightModelTests: XCTestCase {
    func testCountdownShownForHighConfidenceRedLight() {
        let detection = TrafficLightDetection(state: .red,
                                              confidence: 0.9,
                                              boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.1),
                                              detectedAt: Date())
        let countdown = TrafficLightModel.countdown(from: detection,
                                                    predictedGreenAt: Date().addingTimeInterval(3.2))
        XCTAssertTrue(countdown.showCountdown)
        XCTAssertLessThanOrEqual(countdown.secondsRemaining, 3)
    }

    func testCountdownHiddenWhenConfidenceIsLow() {
        let detection = TrafficLightDetection(state: .red,
                                              confidence: 0.6,
                                              boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.1),
                                              detectedAt: Date())
        let countdown = TrafficLightModel.countdown(from: detection,
                                                    predictedGreenAt: Date().addingTimeInterval(3))
        XCTAssertFalse(countdown.showCountdown)
    }
}
