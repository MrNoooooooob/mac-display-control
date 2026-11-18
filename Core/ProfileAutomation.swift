// Copyright © 2026 MrNoooooooob. MIT licensed.
// Saved opt-in preference; defaults to OFF. The controller performs its
// supported-mode preflight and never forces HDR or unknown display modes.
import Foundation

enum ProfileAutomation {
    private static let key = "io.github.MrNoooooooob.mdc.profileAuto.v1"
    static func enabled(for id: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.dictionary(forKey: key)?[id] as? Bool ?? false
    }
    static func setEnabled(_ enabled: Bool, for id: String, defaults: UserDefaults = .standard) {
        guard !id.isEmpty else { return }
        var values = defaults.dictionary(forKey: key) as? [String: Bool] ?? [:]
        values[id] = enabled
        defaults.set(values, forKey: key)
    }
    static func shouldOfferAutoApply(enabled: Bool, selected: DisplayProfileKind?,
                                     offeredRates: [Int], mirrorOwnedByOtherApp: Bool,
                                     pending: Bool) -> Bool {
        guard enabled, let selected, !mirrorOwnedByOtherApp, !pending else { return false }
        return DisplayStabilityPolicy.canRequest(selected.hertz, offered: offeredRates)
    }
}
