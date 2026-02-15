import CoreLocation
import Foundation

protocol TrafficLightObservationProviding {
    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal?
}

actor TrafficLightObservationEngine: TrafficLightObservationProviding {
    private let profileStore: CycleProfileStoring
    private var currentPhase: SignalPhase = .red
    private var phaseStartAt = Date()
    private var lastCoordinate: CLLocationCoordinate2D?

    init(profileStore: CycleProfileStoring = CycleProfileStore()) {
        self.profileStore = profileStore
    }

    func predictSignal(near coordinate: CLLocationCoordinate2D?) async -> TrafficSignal? {
        guard let coordinate else { return nil }
        lastCoordinate = coordinate

        let intersectionID = intersectionID(for: coordinate)
        var profile = profileStore.profile(for: intersectionID) ?? .defaultProfile(intersectionID: intersectionID)

        maybeAdvancePhase(using: profile)
        profile = updateProfileDurations(profile)
        profileStore.upsert(profile)

        return buildSignal(profile: profile, coordinate: coordinate)
    }

    private func intersectionID(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f_%.4f", coordinate.latitude, coordinate.longitude)
    }

    private func maybeAdvancePhase(using profile: IntersectionCycleProfile) {
        let elapsed = Date().timeIntervalSince(phaseStartAt)
        switch currentPhase {
        case .green where elapsed >= profile.greenDuration:
            currentPhase = .yellow
            phaseStartAt = Date()
        case .yellow where elapsed >= profile.yellowDuration:
            currentPhase = .red
            phaseStartAt = Date()
        case .red where elapsed >= profile.redDuration:
            currentPhase = .green
            phaseStartAt = Date()
        default:
            break
        }
    }

    private func updateProfileDurations(_ profile: IntersectionCycleProfile) -> IntersectionCycleProfile {
        var profile = profile
        let elapsed = max(1, Date().timeIntervalSince(phaseStartAt))
        let smoothing = min(0.15, 1.0 / Double(max(1, profile.sampleCount)))

        switch currentPhase {
        case .red:
            profile.redDuration = (1 - smoothing) * profile.redDuration + smoothing * elapsed
        case .yellow:
            profile.yellowDuration = (1 - smoothing) * profile.yellowDuration + smoothing * elapsed
        case .green:
            profile.greenDuration = (1 - smoothing) * profile.greenDuration + smoothing * elapsed
        case .unknown:
            break
        }

        profile.sampleCount += 1
        profile.lastUpdatedAt = Date()
        return profile
    }

    private func buildSignal(profile: IntersectionCycleProfile, coordinate: CLLocationCoordinate2D) -> TrafficSignal {
        let now = Date()
        let elapsed = now.timeIntervalSince(phaseStartAt)
        let phaseEndsAt: Date
        let nextGreenAt: Date

        switch currentPhase {
        case .green:
            phaseEndsAt = phaseStartAt.addingTimeInterval(profile.greenDuration)
            nextGreenAt = now
        case .yellow:
            phaseEndsAt = phaseStartAt.addingTimeInterval(profile.yellowDuration)
            nextGreenAt = phaseEndsAt.addingTimeInterval(profile.redDuration)
        case .red:
            phaseEndsAt = phaseStartAt.addingTimeInterval(profile.redDuration)
            nextGreenAt = phaseEndsAt
        case .unknown:
            phaseEndsAt = now.addingTimeInterval(1)
            nextGreenAt = now.addingTimeInterval(profile.redDuration)
        }

        let cycleQuality = min(1.0, Double(profile.sampleCount) / 120.0)
        let confidence = max(0.60, min(0.93, 0.60 + 0.33 * cycleQuality - min(0.1, elapsed / 500.0)))

        return TrafficSignal(id: UUID(),
                             intersectionID: profile.intersectionID,
                             intersectionName: "Local Intersection",
                             coordinate: coordinate,
                             phase: currentPhase,
                             nextGreenAt: nextGreenAt,
                             phaseEndsAt: phaseEndsAt,
                             confidence: confidence,
                             source: "on-device-cycle-learning",
                             serverTimestamp: now)
    }
}
