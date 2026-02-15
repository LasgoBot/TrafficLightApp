import Foundation

protocol CycleProfileStoring {
    func profile(for intersectionID: String) -> IntersectionCycleProfile?
    func upsert(_ profile: IntersectionCycleProfile)
}

final class CycleProfileStore: CycleProfileStoring {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "cycle-profile-"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func profile(for intersectionID: String) -> IntersectionCycleProfile? {
        guard let data = defaults.data(forKey: keyPrefix + intersectionID) else {
            return nil
        }
        return try? decoder.decode(IntersectionCycleProfile.self, from: data)
    }

    func upsert(_ profile: IntersectionCycleProfile) {
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: keyPrefix + profile.intersectionID)
    }
}
