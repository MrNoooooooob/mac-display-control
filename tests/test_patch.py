#!/usr/bin/env python3
"""Offline integration smoke test for pinned machidpi patch points.

This does not replace a real macOS build or monitor verification.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]

# Minimal shape of pinned upstream, including all specific anchors. The test
# fails when a patch anchor is accidentally removed or the result is invalid.
APP = r'''import AppKit
import CoreGraphics
import MacHiDPIKit
import ServiceManagement
import SwiftUI
final class AppDelegate: NSObject {
    private var reconcileWork: DispatchWorkItem?
    private var statusItem: NSStatusItem!
    private let hidpi = VirtualHiDPI()
    private let store = Store()
    private var lastErrors: [String: String] = [:]
    private var enableRetries = RetryBudget(limit: 3)
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sparkles.tv",
                                           accessibilityDescription: "machidpi")
        reconcile()
    }

    func applicationWillTerminate(_ notification: Notification) { }
    private func reconcile() {
        for display in Displays.external(excluding: hidpi.virtualIDs)
            where hidpi.sessions[display.id] == nil
            && enableRetries.allows(display.uuid)
        { }
    }
    private func enableDisplay(_ display: PhysicalDisplay, rung: Rung?) {
        lastErrors[display.uuid] = nil
        let saved = store.prefs(for: display.uuid)
        _ = saved
    }
    private func rebuildMenu() {
        let menu = NSMenu()
        let externals = Displays.external(excluding: hidpi.virtualIDs)

        if externals.isEmpty { menu.addItem(disabledItem("No external display")) }
        for display in externals {
            let toggle = NSMenuItem(title: "Enable HiDPI", action: nil, keyEquivalent: "")
            toggle.representedObject = DisplayRef(display: display)
            menu.addItem(toggle)
        }
        let login = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
        _ = login
        statusItem.menu = menu
    }
    private func disabledItem(_ name:String) -> NSMenuItem { NSMenuItem(title:name,action:nil,keyEquivalent:"") }
    // MARK: - Actions
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) { }
}
'''
DISPLAYS = r'''import AppKit
import CoreGraphics
public enum Displays {
    static func onlineIDs() -> [CGDirectDisplayID] { [] }
    static func name(for id: CGDirectDisplayID) -> String { "" }
    /// Online displays that are candidates for HiDPI: not built-in and not
    /// in `excluding` (our own virtual displays).
    public static func external(excluding: Set<CGDirectDisplayID>) -> [PhysicalDisplay] {
        return onlineIDs().compactMap { id in
            guard CGDisplayIsBuiltin(id) == 0, !excluding.contains(id),
                  let uuid = uuidString(for: id) else { return nil }
            let panel = panelPixels(for: id)
            guard panel.width > 0 else { return nil }
            let refresh = CGDisplayCopyDisplayMode(id)?.refreshRate ?? 0
            return PhysicalDisplay(id: id, uuid: uuid, name: name(for: id),
                         pixelWidth: panel.width, pixelHeight: panel.height,
                         refreshRate: refresh, vendorID: 0, productID: 0,
                         sizeInMillimeters: .zero)
        }
    }
    static func uuidString(for id: CGDirectDisplayID) -> String? { nil }
    static func modeInfosWithRefs(for id: CGDirectDisplayID) -> (infos: [ModeInfo], refs: [CGDisplayMode]) { ([], []) }
    static func panelPixels(for id: CGDirectDisplayID) -> (width: Int, height: Int) {
        let (infos, _) = modeInfosWithRefs(for: id)
        let best = infos.max { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }
        if let best { return (best.pixelWidth, best.pixelHeight) }
        return (CGDisplayPixelsWide(id), CGDisplayPixelsHigh(id))
    }
}
'''

with tempfile.TemporaryDirectory() as tmp:
    base=pathlib.Path(tmp)
    app=base/'Sources/machidpi/AppDelegate.swift'
    disp=base/'Sources/MacHiDPIKit/Displays.swift'
    app.parent.mkdir(parents=True)
    disp.parent.mkdir(parents=True)
    app.write_text(APP)
    disp.write_text(DISPLAYS)
    patch=subprocess.run([sys.executable,str(ROOT/'tools/patch_machidpi.py'),str(base)],capture_output=True,text=True)
    assert patch.returncode==0,(patch.stdout,patch.stderr)
    a,d=app.read_text(),disp.read_text()
    for marker in [
        'NSStatusItem.variableLength',
        'Stabilitätsprofil · 120 Hz',
        'Schnellprofile',
        'activateProfileFromMenu(_ sender: NSMenuItem)',
        'quick120.isEnabled = DisplayStabilityPolicy.canRequest',
        'if shouldRestoreHiDPI { restoreHiDPISafely',
        'private func modeFingerprint(for display: PhysicalDisplay)',
        'CGDisplayMirrorsDisplay(display.id)',
        'isExternallyMirrored: foreignMirror',
        'let activeID = session?.virtualID',
        'Externe Spiegelung – andere App zuerst beenden',
        'guard CGDisplayMirrorsDisplay(display.id) == kCGNullDirectDisplay else',
        'HDR ✓*',
        'let realWidth = supportedLG ? 3440',
        'nativeWidth: realWidth',
        'nativeHeight: realHeight',
    ]:
        assert marker in a,marker
    for marker in [
        'CGDisplaySerialNumber(id) == 0x4D48_4450',
        '!isMachidpiVirtual(id)',
        'return (3440, 1440)',
        'let panel = panelPixels(for: id)',
    ]:
        assert marker in d,marker
    assert 'panel.supportedRefreshRates.contains(rate)' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    for feature in ['Display Health', 'Native HDR & HiDPI Lab', 'Automatische Profile', '.ultraThinMaterial']:
        assert feature in (ROOT/'UI/DisplayDashboard.swift').read_text(), feature
    for marker in ['DisplayHealthJournal()', 'applyAutomaticProfilesIfAllowed()', 'Kompakte Statusanzeige', 'displayNativeAnalysis(physical)']:
        assert marker in a, marker
    assert 'private func profileCard(for panel: DashboardPanel)' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    assert 'cp "$ROOT/Core/DisplayProfiles.swift"' in (ROOT/'build.command').read_text()
    assert 'Bildstabilität & Bildrate' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    assert 'model.setHiDPI?(panel.id, false)' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    assert 'model.setRefreshRate?(requested.id, requested.hz)' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    assert 'Button("Bildrate wechseln")' in (ROOT/'UI/DisplayDashboard.swift').read_text()
    for m in ['activate120FromMenu(_ sender: NSMenuItem)', 'restoreHiDPISafely(uuid: String, rung: Rung?)', 'DisplayStabilityPolicy.canRequest(hz, offered: offered)', 'dashboardSetRefreshRate(uuid: String, hz: Int)', 'nativeMode(for display: PhysicalDisplay, hz: Int)', 'CGCancelDisplayConfiguration(config)', 'setNativeMode(previous, on: nativeDisplay.id)', 'supportedRefreshRates: nativeRefreshRates(for: physical)', 'ui.model.setRefreshRate =']:
        assert m in a, m
    for path in [app,disp,ROOT/'UI/DisplayDashboard.swift',*list((ROOT/'Core').glob('*.swift'))]:
        result=subprocess.run(['swiftc','-frontend','-parse',str(path)],capture_output=True,text=True)
        assert result.returncode==0,(path,result.stderr)
    # Unsupported rate is rejected BEFORE the virtual display is touched.
    assert a.index('guard DisplayStabilityPolicy.canRequest(hz, offered: offered)') < a.index('if shouldRestoreHiDPI { hidpi.disable(physicalID: display.id)')
    # The install script should never modify system display overrides or SIP.
    build=(ROOT/'build.command').read_text()
    assert '3d105b0f18cc2522e27028bc1a1ee4b6ff1ef7d6' in build
    assert 'CFBundleShortVersionString</key><string>${BASE_VERSION}' in build
    assert 'CFBundleVersion</key><string>${BASE_VERSION}' in build
    assert 'VERSION=' in build
    assert 'csrutil' not in build
    assert 'DisplayVendorID' not in build
    print('PASS: upstream anchors / source patch / live Hz profile / display filtering / Swift parser / safe build script')
