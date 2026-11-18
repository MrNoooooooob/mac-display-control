// Copyright © 2026 MrNoooooooob. MIT licensed.
// Standalone policy module: independent of machidpi / private display APIs.
import Foundation

enum DisplayStabilityPolicy {
    static let supportedChoices = [120, 144, 240]
    static let refreshTolerance: Double = 0.8

    /// Non-destructive preflight: never invent an unsupported refresh mode.
    static func canRequest(_ hz: Int, offered: [Int]) -> Bool {
        supportedChoices.contains(hz) && offered.contains(hz)
    }

    /// The OS acknowledging a mode request is not proof of activation.
    static func isApplied(_ hz: Int, measured: Double) -> Bool {
        measured.isFinite && abs(Double(hz) - measured) < refreshTolerance
    }

    static func preferredStabilityRate(offered: [Int]) -> Int? {
        offered.contains(120) ? 120 : nil
    }

    static func pixelRateGigapixels(width: Int, height: Int, hz: Double) -> Double {
        guard width > 0, height > 0, hz.isFinite, hz > 0 else { return 0 }
        return Double(width) * Double(height) * hz / 1_000_000_000
    }
}
