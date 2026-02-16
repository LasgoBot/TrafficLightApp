import CoreLocation
import Foundation

protocol TrafficSignalProviding {
    func signalPrediction(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal?
}

actor TrafficSignalService: TrafficSignalProviding {
    private let remoteService: TrafficSignalRemoteServicing
    private let observationService: TrafficLightObservationProviding

    init(remoteService: TrafficSignalRemoteServicing = TrafficSignalAPIClient(),
         observationService: TrafficLightObservationProviding = TrafficLightObservationEngine()) {
        self.remoteService = remoteService
        self.observationService = observationService
    }

    func signalPrediction(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        switch AppConfiguration.predictionMode {
        case .onDevice:
            return await observationService.predictSignal(near: coordinate)
        case .backend:
            return await backendPrediction(near: coordinate) ?? await observationService.predictSignal(near: coordinate)
        case .hybrid:
            let backendSignal = await backendPrediction(near: coordinate)
            let localSignal = await observationService.predictSignal(near: coordinate)
            return pickBestSignal(backend: backendSignal, local: localSignal)
        }
    }

    private func backendPrediction(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        guard let coordinate else { return nil }

        do {
            return try await remoteService.fetchSignal(latitude: coordinate.latitude,
                                                       longitude: coordinate.longitude).toDomain()
        } catch {
            return nil
        }
    }

    private func pickBestSignal(backend: TrafficSignal?, local: TrafficSignal?) -> TrafficSignal? {
        guard let backend else { return local }
        guard let local else { return backend }
        return backend.confidence >= local.confidence ? backend : local
    }
}
