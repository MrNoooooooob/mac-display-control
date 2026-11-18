#!/usr/bin/env python3
"""Apply minimal GUI additions to a pinned machidpi checkout.

No changes to VirtualHiDPI.swift, mode selection, mirroring or overrides.
"""
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
source = root / 'Sources' / 'machidpi' / 'AppDelegate.swift'
if not source.is_file():
    raise SystemExit('Fehler: AppDelegate.swift nicht gefunden')
text = source.read_text()

# Text status requires a variable-length status item.
old = 'NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)'
new = 'NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)'
if text.count(old) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Menüleisten-Anker fehlt')
text = text.replace(old, new)

# New modern dashboard is a separate file; keep upstream AppDelegate logic.
anchor = '    private var reconcileWork: DispatchWorkItem?\n'
insert = '''    private var dashboard: DashboardWindowController?\n    private var hdrConfirmations: [String: String] = [:]\n    private var seenModeFingerprints: [String: String] = [:]\n    private var barTimer: Timer?\n    private var refreshChangesInProgress: Set<String> = []\n'''
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: reconcileWork-Anker fehlt')
text = text.replace(anchor, anchor + insert)

# Poll only measured display values, no mode changes or HDR probing.
anchor = '        reconcile()\n    }\n\n    func applicationWillTerminate'
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Start-Anker fehlt')
text = text.replace(anchor, '''        reconcile()
        barTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.updateStatusBar()
        }
    }

    func applicationWillTerminate''')

anchor = '        let externals = Displays.external(excluding: hidpi.virtualIDs)\n\n        if externals.isEmpty'
insert = '''        let openDashboard = NSMenuItem(title: "Mac Display Control öffnen",
                                       action: #selector(showDashboard(_:)), keyEquivalent: "d")
        openDashboard.target = self
        menu.addItem(openDashboard)
        let monitor = statusDisplay()
        if let monitor {
            let hdr = NSMenuItem(title: "HDR-Schalter in macOS bestätigt*",
                                 action: #selector(toggleHDRConfirmation(_:)), keyEquivalent: "")
            hdr.target = self
            hdr.state = hdrConfirmed(for: monitor) ? .on : .off
            menu.addItem(hdr)
            if hidpi.sessions[monitor.id] != nil {
                menu.addItem(disabledItem("Virtuelle Spiegelung: HDR-Ausgabe ungeprüft"))
            }
        }
        menu.addItem(.separator())

'''
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Menu-Anker fehlt')
text = text.replace(anchor, '        let externals = Displays.external(excluding: hidpi.virtualIDs)\n\n' + insert + '        if externals.isEmpty')

anchor = '        statusItem.menu = menu\n'
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Menu-Abschluss fehlt')
text = text.replace(anchor, '        statusItem.menu = menu\n        updateStatusBar()\n')

# Clear any manual HDR confirmation before ANY machidpi virtual enable,
# including the original menu's Enable HiDPI path.
anchor = '        lastErrors[display.uuid] = nil\n        let saved = store.prefs(for: display.uuid)'
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: enableDisplay-Anker fehlt')
text = text.replace(anchor, '        lastErrors[display.uuid] = nil\n        hdrConfirmations.removeValue(forKey: display.uuid)\n        let saved = store.prefs(for: display.uuid)')

anchor = '    // MARK: - Actions\n'
addition = r'''    // MARK: - Live menu bar status

    private func statusDisplay() -> PhysicalDisplay? {
        let physical = Displays.external(excluding: hidpi.virtualIDs)
        return physical.first(where: { $0.name.localizedCaseInsensitiveContains("LG") })
            ?? physical.first(where: { CGDisplayIsMain($0.id) != 0 })
            ?? physical.first
    }

    // HDR-Schalter wird nur manuell bestätigt, für den aktuell gemessenen
    // Modus. Virtuelles HiDPI ist kein Beweis für den HDMI-HDR-Ausgang.
    private func modeFingerprint(for display: PhysicalDisplay) -> String? {
        let ownedID = hidpi.sessions[display.id]?.virtualID
        let mirrorID = CGDisplayMirrorsDisplay(display.id)
        let activeID = ownedID ?? (mirrorID != kCGNullDirectDisplay ? mirrorID : display.id)
        guard let displayMode = CGDisplayCopyDisplayMode(activeID),
              let physicalMode = CGDisplayCopyDisplayMode(display.id) else { return nil }
        let kind = ownedID != nil ? "virtual-owned" : (mirrorID != kCGNullDirectDisplay ? "virtual-external" : "native")
        return "\(kind):\(displayMode.width)x\(displayMode.height):\(displayMode.pixelWidth)x\(displayMode.pixelHeight):\(Int((displayMode.refreshRate * 100).rounded())):\(physicalMode.pixelWidth)x\(physicalMode.pixelHeight):\(Int((physicalMode.refreshRate * 100).rounded()))"
    }

    // A mode change invalidates the *previous* manual confirmation.
    // Reconfiguration events with an identical mode leave it intact.
    private func inspectHDRConfirmationModes() {
        let externals = Displays.external(excluding: hidpi.virtualIDs)
        let present = Set(externals.map(\.uuid))
        for monitor in externals {
            guard let fingerprint = modeFingerprint(for: monitor) else { continue }
            if let previous = seenModeFingerprints[monitor.uuid], previous != fingerprint {
                hdrConfirmations.removeValue(forKey: monitor.uuid)
            }
            seenModeFingerprints[monitor.uuid] = fingerprint
        }
        seenModeFingerprints = seenModeFingerprints.filter { present.contains($0.key) }
        hdrConfirmations = hdrConfirmations.filter { present.contains($0.key) }
    }

    private func hdrConfirmed(for monitor: PhysicalDisplay) -> Bool {
        guard let fingerprint = modeFingerprint(for: monitor) else { return false }
        return hdrConfirmations[monitor.uuid] == fingerprint
    }

    @objc private func toggleHDRConfirmation(_ sender: NSMenuItem) {
        guard let display = statusDisplay(),
              let fingerprint = modeFingerprint(for: display) else { return }
        if hdrConfirmations[display.uuid] == fingerprint {
            hdrConfirmations.removeValue(forKey: display.uuid)
        } else {
            hdrConfirmations[display.uuid] = fingerprint
        }
        rebuildMenu()
    }

    private func updateStatusBar() {
        inspectHDRConfirmationModes()
        guard let monitor = statusDisplay() else {
            statusItem.button?.title = "Kein Display"
            statusItem.button?.toolTip = "Kein externer Monitor erkannt"
            updateDashboard()
            return
        }
        let mirrorID = CGDisplayMirrorsDisplay(monitor.id)
        let activeID = hidpi.sessions[monitor.id]?.virtualID
            ?? (mirrorID != kCGNullDirectDisplay ? mirrorID : monitor.id)
        let mode = CGDisplayCopyDisplayMode(activeID)
        let screenScale = NSScreen.screens.first(where: {
            guard let n = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                as? NSNumber else { return false }
            return n.uint32Value == activeID
        }).map { Double($0.backingScaleFactor) }
        let pixelRatio = mode.map { Double($0.pixelWidth) / Double(max(1, $0.width)) } ?? 1.0
        let scale = screenScale ?? pixelRatio
        let retina = scale >= 1.9 && pixelRatio >= 1.9
        let hz = CGDisplayCopyDisplayMode(monitor.id)?.refreshRate ?? monitor.refreshRate
        let hdr = hdrConfirmed(for: monitor) ? "HDR ✓*" : "HDR ?"
        statusItem.button?.title = "HiDPI \(retina ? "2×" : "aus") · \(hdr) · \(Int(hz.rounded())) Hz"
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.toolTip = "\(monitor.name) | HDR ✓*: Schalter für diesen Modus manuell bestätigt (keine Signalmessung). Virtuelle Spiegelung kann HDR begrenzen."
        updateDashboard()
    }

    // MARK: - Mac Display Control window (visual frontend only)

    @objc private func showDashboard(_ sender: NSMenuItem) {
        if dashboard == nil {
            let ui = DashboardWindowController()
            ui.model.setHiDPI = { [weak self] uuid, enabled in
                self?.dashboardSetHiDPI(uuid: uuid, enabled: enabled)
            }
            ui.model.setRung = { [weak self] uuid, rung in
                self?.dashboardSetRung(uuid: uuid, rung: rung)
            }
            ui.model.setRefreshRate = { [weak self] uuid, hz in
                self?.dashboardSetRefreshRate(uuid: uuid, hz: hz)
            }
            ui.model.setLogin = { [weak self] enabled in
                self?.dashboardSetLogin(enabled)
            }
            ui.model.setHDRConfirmed = { [weak self] uuid, enabled in
                self?.dashboardSetHDRConfirmed(uuid: uuid, enabled: enabled)
            }
            ui.model.reload = { [weak self] in
                self?.rebuildMenu()
            }
            dashboard = ui
        }
        updateDashboard()
        dashboard?.show()
    }

    private func dashboardSetHiDPI(uuid: String, enabled: Bool) {
        guard let display = Displays.external(excluding: hidpi.virtualIDs)
            .first(where: { $0.uuid == uuid }) else { return }
        if enabled {
            guard CGDisplayMirrorsDisplay(display.id) == kCGNullDirectDisplay,
                  hidpi.sessions[display.id] == nil,
                  !hidpi.pending.contains(display.id) else {
                lastErrors[uuid] = "Ein anderes Programm steuert bereits die Spiegelung – zuerst dort deaktivieren."
                rebuildMenu()
                return
            }
            enableRetries.reset(uuid)
            hdrConfirmations.removeValue(forKey: uuid)
            // Do not make the UI larger by default: choose 1.0 panel-size rung.
            let chosen = store.prefs(for: uuid)?.rung
                ?? Scaling.ladder(panelWidth: display.pixelWidth,
                                  panelHeight: display.pixelHeight).first
            enableDisplay(display, rung: chosen)
        } else {
            hidpi.disable(physicalID: display.id)
            var prefs = store.prefs(for: uuid)
                ?? DisplayPrefs(enabled: false, rung: nil)
            prefs.enabled = false
            store.set(prefs, for: uuid)
            lastErrors[uuid] = nil
            rebuildMenu()
        }
    }

    private func dashboardSetRung(uuid: String, rung: Rung) {
        guard let display = Displays.external(excluding: hidpi.virtualIDs)
            .first(where: { $0.uuid == uuid }),
              let session = hidpi.sessions[display.id],
              session.ladder.contains(rung) else { return }
        if hidpi.setRung(rung, physicalID: display.id) {
            var prefs = store.prefs(for: uuid)
                ?? DisplayPrefs(enabled: true, rung: nil)
            prefs.enabled = true
            prefs.rung = rung
            store.set(prefs, for: uuid)
            lastErrors[uuid] = nil
        } else {
            lastErrors[uuid] = "macOS hat den gewünschten HiDPI-Modus nicht übernommen"
        }
        rebuildMenu()
    }

    private func dashboardSetHDRConfirmed(uuid: String, enabled: Bool) {
        guard let display = Displays.external(excluding: hidpi.virtualIDs)
            .first(where: { $0.uuid == uuid }),
              let fingerprint = modeFingerprint(for: display) else { return }
        if enabled { hdrConfirmations[uuid] = fingerprint }
        else { hdrConfirmations.removeValue(forKey: uuid) }
        rebuildMenu()
    }

    // Enumerate ONLY real native panel modes; a mirrored virtual display may
    // expose many synthetic 2x modes which are not valid refresh-rate targets.
    private func nativeMode(for display: PhysicalDisplay, hz: Int) -> CGDisplayMode? {
        let options: NSDictionary = [kCGDisplayShowDuplicateLowResolutionModes as NSString: true]
        guard let modes = CGDisplayCopyAllDisplayModes(display.id, options as CFDictionary)
            as? [CGDisplayMode] else { return nil }
        let native = modes.filter {
            $0.width == display.pixelWidth && $0.height == display.pixelHeight
                && $0.pixelWidth == display.pixelWidth && $0.pixelHeight == display.pixelHeight
                && abs($0.refreshRate - Double(hz)) < 0.8
        }
        return native.first
    }

    private func nativeRefreshRates(for display: PhysicalDisplay) -> [Int] {
        let supported = [120, 144, 240]
        return supported.filter { nativeMode(for: display, hz: $0) != nil }
    }

    private func setNativeMode(_ mode: CGDisplayMode, on id: CGDirectDisplayID) -> CGError {
        var config: CGDisplayConfigRef?
        let begin = CGBeginDisplayConfiguration(&config)
        guard begin == .success else { return begin }
        let change = CGConfigureDisplayWithDisplayMode(config, id, mode, nil)
        guard change == .success else {
            CGCancelDisplayConfiguration(config)
            return change
        }
        return CGCompleteDisplayConfiguration(config, .forSession)
    }

    private func dashboardSetRefreshRate(uuid: String, hz: Int) {
        guard [120, 144, 240].contains(hz), !refreshChangesInProgress.contains(uuid),
              let display = Displays.external(excluding: hidpi.virtualIDs)
                .first(where: { $0.uuid == uuid }),
              !hidpi.pending.contains(display.id) else { return }
        if CGDisplayMirrorsDisplay(display.id) != kCGNullDirectDisplay
            && hidpi.sessions[display.id] == nil {
            lastErrors[uuid] = "Fremde Spiegelung aktiv; Bildrate nicht veränderbar"
            rebuildMenu()
            return
        }
        let currentRate = CGDisplayCopyDisplayMode(display.id)?.refreshRate ?? display.refreshRate
        if abs(currentRate - Double(hz)) < 0.8 {
            dashboard?.model.lastNotice = "\(hz) Hz sind bereits aktiv."
            rebuildMenu()
            return
        }

        refreshChangesInProgress.insert(uuid)
        let oldSession = hidpi.sessions[display.id]
        let oldRung = oldSession?.currentRung
        let shouldRestoreHiDPI = oldSession != nil
        // Prevent reconcile() from recreating the old virtual display while
        // we are switching refresh rate on the physical HDMI output.
        var prefs = store.prefs(for: uuid) ?? DisplayPrefs(enabled: false, rung: oldRung)
        prefs.enabled = false
        store.set(prefs, for: uuid)
        hdrConfirmations.removeValue(forKey: uuid)
        if shouldRestoreHiDPI { hidpi.disable(physicalID: display.id) }

        // The physical native modes may only become visible after unmirroring.
        guard let nativeDisplay = Displays.external(excluding: hidpi.virtualIDs)
            .first(where: { $0.uuid == uuid }),
              let previous = CGDisplayCopyDisplayMode(nativeDisplay.id),
              let candidate = nativeMode(for: nativeDisplay, hz: hz) else {
            lastErrors[uuid] = "\(hz) Hz werden nativ nicht angeboten; vorherige Einstellung bleibt."
            if shouldRestoreHiDPI { enableDisplay(display, rung: oldRung) }
            refreshChangesInProgress.remove(uuid)
            rebuildMenu()
            return
        }
        let result = setNativeMode(candidate, on: nativeDisplay.id)
        if result != .success {
            lastErrors[uuid] = "macOS hat \(hz) Hz abgelehnt (CoreGraphics \(result.rawValue))."
            if shouldRestoreHiDPI { enableDisplay(display, rung: oldRung) }
            refreshChangesInProgress.remove(uuid)
            rebuildMenu()
            return
        }
        // Apply is not proof: verify actual physical HDMI mode before mirroring.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            let measured = CGDisplayCopyDisplayMode(nativeDisplay.id)?.refreshRate ?? 0
            if abs(measured - Double(hz)) >= 0.8 {
                _ = self.setNativeMode(previous, on: nativeDisplay.id)
                self.lastErrors[uuid] = "Moduswechsel nicht bestätigt; vorherige Bildrate wiederhergestellt"
                self.dashboard?.model.lastNotice = self.lastErrors[uuid] ?? "Bildratenwechsel fehlgeschlagen"
            } else {
                self.lastErrors[uuid] = nil
                self.dashboard?.model.lastNotice = "\(hz) Hz nativ bestätigt. HDR in macOS neu prüfen."
            }
            if shouldRestoreHiDPI, let updated = Displays.external(excluding: self.hidpi.virtualIDs)
                .first(where: { $0.uuid == uuid }) {
                self.enableDisplay(updated, rung: oldRung)
            }
            self.refreshChangesInProgress.remove(uuid)
            self.rebuildMenu()
        }
    }

    private func dashboardSetLogin(_ enabled: Bool) {
        do {
            if enabled && SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            } else if !enabled && SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            dashboard?.model.lastNotice = error.localizedDescription
        }
        rebuildMenu()
    }

    private func updateDashboard() {
        guard let model = dashboard?.model else { return }
        model.loginEnabled = SMAppService.mainApp.status == .enabled
        model.panels = Displays.external(excluding: hidpi.virtualIDs).map { physical in
            let session = hidpi.sessions[physical.id]
            // A mirror slave may lose the LG name and report synthetic 2x/4x
            // backing modes as physical panel pixels. Prefer the pre-mirror
            // identity captured by machidpi, then apply this model's spec.
            let knownName = session?.physical.name ?? physical.name
            let supportedLG = knownName.localizedCaseInsensitiveContains("LG SMARTGAME+")
                || knownName.localizedCaseInsensitiveContains("34GX90SA")
                || physical.name.localizedCaseInsensitiveContains("LG SMARTGAME+")
                || physical.name.localizedCaseInsensitiveContains("34GX90SA")
            let realWidth = supportedLG ? 3440 : (session?.physical.pixelWidth ?? physical.pixelWidth)
            let realHeight = supportedLG ? 1440 : (session?.physical.pixelHeight ?? physical.pixelHeight)
            let mirrorID = CGDisplayMirrorsDisplay(physical.id)
            let foreignMirror = session == nil && mirrorID != kCGNullDirectDisplay
            let activeID = session?.virtualID
                ?? (mirrorID != kCGNullDirectDisplay ? mirrorID : physical.id)
            let mode = CGDisplayCopyDisplayMode(activeID)
            let screenScale = NSScreen.screens.first(where: {
                guard let number = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                    as? NSNumber else { return false }
                return CGDirectDisplayID(number.uint32Value) == activeID
            }).map { Double($0.backingScaleFactor) }
            let logicalWidth = mode?.width ?? physical.pixelWidth
            let logicalHeight = mode?.height ?? physical.pixelHeight
            let pixelWidth = mode?.pixelWidth ?? physical.pixelWidth
            let pixelHeight = mode?.pixelHeight ?? physical.pixelHeight
            let activeScale = screenScale ?? Double(pixelWidth) / Double(max(1, logicalWidth))
            return DashboardPanel(
                id: physical.uuid,
                name: knownName,
                nativeWidth: realWidth,
                nativeHeight: realHeight,
                panelHz: CGDisplayCopyDisplayMode(physical.id)?.refreshRate ?? physical.refreshRate,
                supportedRefreshRates: nativeRefreshRates(for: physical),
                isEnabled: session != nil,
                isExternallyMirrored: foreignMirror,
                isPending: hidpi.pending.contains(physical.id),
                backingScale: activeScale,
                logicalWidth: logicalWidth,
                logicalHeight: logicalHeight,
                renderWidth: pixelWidth,
                renderHeight: pixelHeight,
                rungs: session?.ladder ?? Scaling.ladder(panelWidth: realWidth,
                                                          panelHeight: realHeight),
                activeRung: session?.currentRung,
                errorText: lastErrors[physical.uuid],
                hdrConfirmedByUser: hdrConfirmed(for: physical)
            )
        }
    }

'''
if text.count(anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Actions-Anker fehlt')
text = text.replace(anchor, addition + anchor)
# Translate the legacy menu without altering its behavior.
for original, localized in [
    ('accessibilityDescription: "machidpi"', 'accessibilityDescription: "Mac Display Control"'),
    ('title: "Enable HiDPI"', 'title: "HiDPI aktivieren"'),
    ('title: "Launch at Login"', 'title: "Beim Anmelden starten"'),
    ('title: "Quit machidpi"', 'title: "Mac Display Control beenden"'),
    ('"No external display"', '"Kein externer Monitor"'),
    ('"Use as Main Display (fixes Spaces swipes)"', '"Als Hauptdisplay (Spaces-Gesten)"'),
]:
    text = text.replace(original, localized)
# Avoid creating a second virtual display if another machidpi instance owns
# the mirror. Use online monitor IDs, not UI-only state, for this interlock.
mirror_menu_anchor = '            toggle.representedObject = DisplayRef(display: display)\n            menu.addItem(toggle)'
if text.count(mirror_menu_anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: toggle-Menüanker fehlt')
text = text.replace(mirror_menu_anchor, '            toggle.representedObject = DisplayRef(display: display)\n            let externalMirror = hidpi.sessions[display.id] == nil\n                && CGDisplayMirrorsDisplay(display.id) != kCGNullDirectDisplay\n            toggle.isEnabled = !externalMirror\n            menu.addItem(toggle)\n            if externalMirror {\n                menu.addItem(disabledItem("Externe Spiegelung – andere App zuerst beenden"))\n            }')
reconcile_anchor = '            && enableRetries.allows(display.uuid)'
if text.count(reconcile_anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Reconcile-Anker fehlt')
text = text.replace(reconcile_anchor,
                    reconcile_anchor + '\n            && CGDisplayMirrorsDisplay(display.id) == kCGNullDirectDisplay')
enable_guard_anchor = '        lastErrors[display.uuid] = nil\n        hdrConfirmations.removeValue(forKey: display.uuid)'
if text.count(enable_guard_anchor) != 1:
    raise SystemExit('AppDelegate nicht kompatibel: Enable-Anker fehlt')
text = text.replace(enable_guard_anchor,
                    '        guard CGDisplayMirrorsDisplay(display.id) == kCGNullDirectDisplay else {\n            lastErrors[display.uuid] = "Externe Spiegelung bereits aktiv"\n            rebuildMenu()\n            return\n        }\n' + enable_guard_anchor)

# Fix wrong panel sizes and duplicate virtual display entries in upstream
# discovery. Preserve the original virtual-display and mode-switching engine.
displays_file = root / 'Sources' / 'MacHiDPIKit' / 'Displays.swift'
if not displays_file.is_file():
    raise SystemExit('Fehler: Displays.swift fehlt')
displays = displays_file.read_text()
display_filter_anchor = 'guard CGDisplayIsBuiltin(id) == 0, !excluding.contains(id),'
if displays.count(display_filter_anchor) != 1:
    raise SystemExit('Displays.swift inkompatibel: Filter-Anker fehlt')
displays = displays.replace(display_filter_anchor,
                            'guard CGDisplayIsBuiltin(id) == 0, !excluding.contains(id),\n                  !isMachidpiVirtual(id),')
panel_anchor = '        let (infos, _) = modeInfosWithRefs(for: id)\n        let best = infos.max { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }'
if displays.count(panel_anchor) != 1:
    raise SystemExit('Displays.swift inkompatibel: Pixel-Anker fehlt')
displays = displays.replace(panel_anchor, '        // The LG 34GX90SA is physically 3440x1440. HiDPI overrides add\n        // synthetic 2x/4x backing-store modes, never physical panel pixels.\n        let label = name(for: id)\n        if label.localizedCaseInsensitiveContains("LG SMARTGAME+")\n            || label.localizedCaseInsensitiveContains("34GX90SA") {\n            return (3440, 1440)\n        }\n' + panel_anchor)
virtual_anchor = '    /// Online displays that are candidates for HiDPI:'
if displays.count(virtual_anchor) != 1:
    raise SystemExit('Displays.swift inkompatibel: Virtual-Anker fehlt')
virtual_code = '    // machidpi creates a virtual display with the fixed "MHDP" serial.\n    // If a separate instance owns one, it must not become another "panel".\n    private static func isMachidpiVirtual(_ id: CGDirectDisplayID) -> Bool {\n        if CGDisplaySerialNumber(id) == 0x4D48_4450 { return true }\n        // Some macOS versions present the external virtual as "Display 1".\n        // Conservative fallback: only hide an anonymous mirror master when\n        // it is mirroring the specifically supported LG hardware.\n        let label = name(for: id)\n        guard label.range(of: "^Display [0-9]+$", options: .regularExpression) != nil\n        else { return false }\n        return onlineIDs().contains { panel in\n            guard panel != id, CGDisplayMirrorsDisplay(panel) == id else { return false }\n            let physicalName = name(for: panel)\n            return physicalName.localizedCaseInsensitiveContains("LG SMARTGAME+")\n                || physicalName.localizedCaseInsensitiveContains("34GX90SA")\n        }\n    }\n\n'
displays = displays.replace(virtual_anchor, virtual_code + virtual_anchor)
displays_file.write_text(displays)
source.write_text(text)

print('Mac Display Control: LG-Panelauflösung, Fremdspiegelung und Dashboard korrigiert')
