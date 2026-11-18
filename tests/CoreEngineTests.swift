// Copyright © 2026 MrNoooooooob
import Foundation
@main struct CoreEngineTests {
    static func main() {
        let m = NativeDisplayMode(logicalWidth: 3440, logicalHeight: 1440,
                                  pixelWidth: 6880, pixelHeight: 2880, hertz: 120)
        let standard = NativeDisplayMode(logicalWidth: 3440, logicalHeight: 1440,
                                  pixelWidth: 3440, pixelHeight: 1440, hertz: 240)
        assert(m.isHiDPI && m.scale == 2)
        assert(!standard.isHiDPI)
        let report = NativeDisplayEngine.report(modes: [m, standard],
                        panelWidth: 3440, panelHeight: 1440, edrPotential: 1)
        assert(report.fullSizeHiDPICandidates.count == 1)
        assert(report.summary.contains("kein HDR-Signalnachweis"))
        assert(NativeDisplayEngine.acceptableRefreshRates([m,standard], width: 3440,height: 1440) == [240])
        assert(ReleaseVersion("v1.0.0") != nil)
        assert(ReleaseVersion("") == nil)
        assert(ReleaseVersion("v1.0.0-beta")! < ReleaseVersion("1.0.0")!)
        assert(ReleaseVersion("1.0.0")! < ReleaseVersion("1.1.0")!)
        let suite = "MDC-CoreEngineTests-2026"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("defaults") }
        defaults.removePersistentDomain(forName:suite)
        assert(!ProfileAutomation.enabled(for: "LG", defaults: defaults))
        ProfileAutomation.setEnabled(true, for: "LG", defaults: defaults)
        assert(ProfileAutomation.enabled(for:"LG", defaults:defaults))
        assert(ProfileAutomation.shouldOfferAutoApply(enabled:true,selected:.stability120,
            offeredRates:[120,240],mirrorOwnedByOtherApp:false,pending:false))
        assert(!ProfileAutomation.shouldOfferAutoApply(enabled:true,selected:.stability120,
            offeredRates:[240],mirrorOwnedByOtherApp:false,pending:false))
        assert(!ProfileAutomation.shouldOfferAutoApply(enabled:true,selected:.stability120,
            offeredRates:[120],mirrorOwnedByOtherApp:true,pending:false))
        let health = DisplayHealthJournal(defaults:defaults)
        let one = DisplayHealthSample(displayID:"LG",logicalWidth:3440,logicalHeight:1440,
            renderWidth:6880,renderHeight:2880,hertz:120,mirrored:true,scale:2)
        health.observe([one])
        assert(health.events.last?.kind == .connected)
        health.observe([one]); assert(health.events.count == 1)
        let two = DisplayHealthSample(displayID:"LG",logicalWidth:3440,logicalHeight:1440,
            renderWidth:6880,renderHeight:2880,hertz:240,mirrored:true,scale:2)
        health.observe([two]); assert(health.events.last?.kind == .modeChanged)
        health.observe([]); assert(health.events.last?.kind == .disconnected)
        assert(!health.exportText().isEmpty)
        health.clear();assert(health.events.isEmpty)
        defaults.removePersistentDomain(forName:suite)
        print("PASS: independent native analysis, opt-in automation, version parsing, display health")
    }
}
