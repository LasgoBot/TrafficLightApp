import XCTest
@testable import TrafficLightApp

final class FrameRateGovernorTests: XCTestCase {
    func testFrameGovernorSkipsImmediateFrame() {
        let governor = FrameRateGovernor()
        XCTAssertTrue(governor.shouldProcessFrame(targetFPS: 30))
        XCTAssertFalse(governor.shouldProcessFrame(targetFPS: 30))
    }
}
