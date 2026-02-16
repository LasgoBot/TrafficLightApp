import CoreLocation
import XCTest
@testable import TrafficLightApp

private struct MockRemoteService: TrafficSignalRemoteServicing {
    let dto: TrafficSignalDTO

    func fetchSignal(latitude: Double, longitude: Double) async throws -> TrafficSignalDTO {
        dto
    }
}

private actor MockObservationService: TrafficLightObservationProviding {
    let signal: TrafficSignal

    init(signal: TrafficSignal) {
        self.signal = signal
    }

    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        signal
    }
}

final class TrafficSignalServiceTests: XCTestCase {
    func testDTOConversion() {
        let dto = TrafficSignalDTO(intersectionID: "I-1",
                                   intersectionName: "Main & 1st",
                                   latitude: 1.0,
                                   longitude: 2.0,
                                   phase: "red",
                                   nextGreenEpochMs: 2_000,
                                   phaseEndsEpochMs: 1_500,
                                   confidence: 0.92,
                                   source: "spat-map",
                                   serverEpochMs: 1_000)

        let signal = dto.toDomain()
        XCTAssertEqual(signal.intersectionID, "I-1")
        XCTAssertEqual(signal.phase, .red)
        XCTAssertEqual(signal.source, "spat-map")
    }

    func testOnDeviceProviderCanReturnSignal() async {
        let seedSignal = TrafficSignal(id: UUID(),
                                       intersectionID: "local",
                                       intersectionName: "Local",
                                       coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
                                       phase: .green,
                                       nextGreenAt: Date(),
                                       phaseEndsAt: Date().addingTimeInterval(10),
                                       confidence: 0.88,
                                       source: "on-device-cycle-learning",
                                       serverTimestamp: Date())

        let service = TrafficSignalService(remoteService: MockRemoteService(dto: TrafficSignalDTO(intersectionID: "I-1",
                                                                                                   intersectionName: "Main",
                                                                                                   latitude: 1,
                                                                                                   longitude: 2,
                                                                                                   phase: "red",
                                                                                                   nextGreenEpochMs: nil,
                                                                                                   phaseEndsEpochMs: nil,
                                                                                                   confidence: 0.3,
                                                                                                   source: "remote",
                                                                                                   serverEpochMs: 0)),
                                         observationService: MockObservationService(signal: seedSignal))

        let prediction = await service.signalPrediction(near: CLLocationCoordinate2D(latitude: 1, longitude: 2))
        XCTAssertNotNil(prediction)
    }
}
