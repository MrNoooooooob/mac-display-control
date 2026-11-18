// Copyright © 2026 MrNoooooooob. MIT licensed.
// Independent, read-only display health journal. Never changes display modes.
import Foundation

struct DisplayHealthSample: Codable, Equatable {
    let displayID: String
    let logicalWidth: Int
    let logicalHeight: Int
    let renderWidth: Int
    let renderHeight: Int
    let hertz: Int
    let mirrored: Bool
    let scale: Double
    var fingerprint: String {
        "\(logicalWidth)x\(logicalHeight):\(renderWidth)x\(renderHeight):\(hertz):\(mirrored):\(Int(scale * 100))"
    }
}

enum DisplayHealthKind: String, Codable, CaseIterable {
    case connected, disconnected, modeChanged, mirrorChanged, sleep, wake, warning, note
    var label: String {
        switch self {
        case .connected: return "Display verbunden"
        case .disconnected: return "Display getrennt"
        case .modeChanged: return "Modus geändert"
        case .mirrorChanged: return "Spiegelung geändert"
        case .sleep: return "Ruhezustand"
        case .wake: return "Aufgewacht"
        case .warning: return "Warnung"
        case .note: return "Hinweis"
        }
    }
}

struct DisplayHealthEvent: Codable, Identifiable, Equatable {
    var id: UUID
    var timestamp: Date
    var displayID: String
    var kind: DisplayHealthKind
    var message: String
}

final class DisplayHealthJournal {
    private let defaults: UserDefaults
    private let key = "io.github.MrNoooooooob.mdc.health.v1"
    private(set) var events: [DisplayHealthEvent] = []
    private var latest: [String: DisplayHealthSample] = [:]
    private let maxCount = 250

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let stored = try? JSONDecoder().decode([DisplayHealthEvent].self, from: data) {
            events = Array(stored.suffix(maxCount))
        }
    }
    func record(_ kind: DisplayHealthKind, id: String = "system", message: String, at now: Date = Date()) {
        guard !message.isEmpty else { return }
        events.append(DisplayHealthEvent(id: UUID(), timestamp: now, displayID: id, kind: kind,
                                         message: String(message.prefix(300))))
        if events.count > maxCount { events.removeFirst(events.count - maxCount) }
        if let data = try? JSONEncoder().encode(events) { defaults.set(data, forKey: key) }
    }
    func observe(_ samples: [DisplayHealthSample]) {
        let now = Dictionary(uniqueKeysWithValues: samples.map { ($0.displayID, $0) })
        for (id, sample) in now {
            if let old = latest[id] {
                if old.mirrored != sample.mirrored {
                    record(.mirrorChanged, id: id, message: sample.mirrored ? "Spiegelung aktiv" : "Spiegelung beendet")
                }
                if old.fingerprint != sample.fingerprint {
                    record(.modeChanged, id: id, message: "\(sample.logicalWidth)×\(sample.logicalHeight), \(sample.renderWidth)×\(sample.renderHeight), \(sample.hertz) Hz, \(sample.scale)×")
                }
            } else {
                record(.connected, id: id, message: "Bildschirm erkannt (\(sample.hertz) Hz)")
            }
        }
        for id in latest.keys where now[id] == nil {
            record(.disconnected, id: id, message: "Bildschirm nicht mehr erkannt")
        }
        latest = now
    }
    func exportText() -> String {
        let format = ISO8601DateFormatter()
        return events.suffix(100).map {
            "[\(format.string(from: $0.timestamp))] \($0.displayID) · \($0.kind.label): \($0.message)"
        }.joined(separator: "\n")
    }
    // Explicit user action: clear saved logs, never automatic.
    func clear() {
        events.removeAll()
        defaults.removeObject(forKey: key)
    }
}
