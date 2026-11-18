// Copyright © 2026 MrNoooooooob, MIT.
import Foundation
@main struct StabilityPolicyTests {
    static func main() {
        assert(DisplayStabilityPolicy.preferredStabilityRate(offered: [60, 120, 240]) == 120)
        assert(DisplayStabilityPolicy.preferredStabilityRate(offered: [60, 240]) == nil)
        assert(DisplayStabilityPolicy.canRequest(120, offered: [120, 240]))
        assert(!DisplayStabilityPolicy.canRequest(144, offered: [120, 240]))
        assert(!DisplayStabilityPolicy.canRequest(75, offered: [75]))
        assert(DisplayStabilityPolicy.isApplied(120, measured: 119.88))
        assert(!DisplayStabilityPolicy.isApplied(120, measured: 240.0))
        assert(DisplayStabilityPolicy.pixelRateGigapixels(width: 6880, height: 2880, hz: 120) > 2.3)
        assert(DisplayStabilityPolicy.pixelRateGigapixels(width: 0, height: 2880, hz: 120) == 0)
        print("PASS: stability policy / preflight / verification / pixel rate")
    }
}
