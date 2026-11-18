// Copyright © 2026 MrNoooooooob. MIT licensed.
// Own display profile definitions; no private APIs or machidpi dependency.
import Foundation

enum DisplayProfileKind: String, Codable, CaseIterable, Identifiable {
    case stability120
    case balanced144
    case gaming240

    var id: String { rawValue }
    var hertz: Int {
        switch self {
        case .stability120: return 120
        case .balanced144: return 144
        case .gaming240: return 240
        }
    }
    var title: String {
        switch self {
        case .stability120: return "Stabilität"
        case .balanced144: return "Alltag"
        case .gaming240: return "Gaming"
        }
    }
    var detail: String { "\(hertz) Hz" }
    static func offered(from nativeRates: [Int]) -> [DisplayProfileKind] {
        allCases.filter { nativeRates.contains($0.hertz) }
    }
}

// Stores the user's chosen profile per stable display UUID. Selecting a
// profile NEVER changes hardware until the user explicitly applies it.
enum DisplayProfileStore {
    static let key = "io.github.MrNoooooooob.MacDisplayControl.selectedProfiles.v1"

    static func selected(for displayUUID: String, defaults: UserDefaults = .standard) -> DisplayProfileKind? {
        guard let value = defaults.dictionary(forKey: key)?[displayUUID] as? String else { return nil }
        return DisplayProfileKind(rawValue: value)
    }

    static func save(_ profile: DisplayProfileKind, for displayUUID: String, defaults: UserDefaults = .standard) {
        guard !displayUUID.isEmpty else { return }
        var entries = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        entries[displayUUID] = profile.rawValue
        defaults.set(entries, forKey: key)
    }
}
