import AppKit
import CoreGraphics
import MacHiDPIKit
import ServiceManagement
import SwiftUI

// Mac Display Control visual layer. The existing machidpi VirtualHiDPI
// implementation continues to own the virtual-display and mirror session.
struct DashboardPanel: Identifiable {
    let id: String
    let name: String
    let nativeWidth: Int
    let nativeHeight: Int
    let panelHz: Double
    let supportedRefreshRates: [Int]
    let isEnabled: Bool
    let isExternallyMirrored: Bool
    let isPending: Bool
    let backingScale: Double
    let logicalWidth: Int
    let logicalHeight: Int
    let renderWidth: Int
    let renderHeight: Int
    let rungs: [Rung]
    let activeRung: Rung?
    let errorText: String?
    // User confirmation is session-local; it is NOT a hardware HDR measurement.
    let hdrConfirmedByUser: Bool
}

final class DashboardModel: ObservableObject {
    @Published var panels: [DashboardPanel] = []
    @Published var loginEnabled = false
    @Published var lastNotice = ""
    var setHiDPI: ((String, Bool) -> Void)?
    var setRung: ((String, Rung) -> Void)?
    var setRefreshRate: ((String, Int) -> Void)?
    var setLogin: ((Bool) -> Void)?
    var setHDRConfirmed: ((String, Bool) -> Void)?
    var reload: (() -> Void)?

    func diagnosticText() -> String {
        var lines = ["Mac Display Control 0.0.2 Beta · by MrNoooooooob", "HDR-Schalter: manuell bestätigt oder unbekannt; HDMI-HDR/EDR-Ausgabe nicht automatisch messbar", ""]
        for p in panels {
            lines += [
                "Display: \(p.name)",
                "Physisches Panel: \(p.nativeWidth)×\(p.nativeHeight) · \(String(format: "%.1f", p.panelHz)) Hz",
                "Virtuelle Renderlast: \(String(format: "%.2f", Double(p.renderWidth) * Double(p.renderHeight) * p.panelHz / 1_000_000_000)) Gigapixel/s (grobe Pixelrate, keine GPU-Auslastung)",
                "Nativ angebotene Bildraten (falls ermittelbar): \(p.supportedRefreshRates.map { String($0) }.joined(separator: ", ")) Hz",
                "Stabilitätsprofil: \(Int(p.panelHz.rounded()) == 120 ? "120 Hz aktiv" : "120 Hz empfohlen, falls angeboten")",
                "HiDPI über virtuelle Spiegelung: \(p.isEnabled ? "Von dieser App gesteuert" : (p.isExternallyMirrored ? "Von anderer App gesteuert" : "Aus"))",
                "Aktuell: \(p.logicalWidth)×\(p.logicalHeight) Punkte · \(p.renderWidth)×\(p.renderHeight) Renderpixel · \(String(format: "%.1f", p.backingScale))×",
                "HDR-Schalter: \(p.hdrConfirmedByUser ? "durch Nutzer in macOS als eingeschaltet bestätigt" : "nicht bestätigt")",
                "HDR-Ausgabe: nicht automatisch nachweisbar; virtuelle HiDPI-Spiegelung unterstützt laut machidpi keine verifizierte HDR-Pipeline",
                "Statusleiste: HiDPI \(p.backingScale >= 1.9 ? "2×" : "aus") · \(p.hdrConfirmedByUser ? "HDR ✓*" : "HDR ?") · \(Int(p.panelHz.rounded())) Hz",
                "Spiegelungsquelle: \(p.isExternallyMirrored ? "extern – nicht durch diese App steuerbar" : (p.isEnabled ? "Mac Display Control" : "keine"))",
                "Bildfehler (pinkes Flackern): nicht automatisch messbar; bei virtueller Spiegelung mit 240 Hz testweise 120 Hz im nativen Modus wählen und HiDPI danach neu aktivieren",
                "Fehler: \(p.errorText ?? "keiner")", ""
            ]
        }
        return lines.joined(separator: "\n")
    }
}

final class DashboardWindowController: NSObject, NSWindowDelegate {
    let model = DashboardModel()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let rect = NSRect(x: 0, y: 0, width: 940, height: 700)
            let win = NSWindow(contentRect: rect,
                               styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                               backing: .buffered, defer: false)
            win.title = "Mac Display Control"
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.minSize = NSSize(width: 720, height: 580)
            win.isReleasedWhenClosed = false
            win.center()
            win.contentViewController = NSHostingController(rootView: DashboardView(model: model))
            win.delegate = self
            window = win
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    @State private var selectedUUID: String = ""
    @State private var showHDRWarning = false
    @State private var pendingEnableUUID: String?
    @State private var pendingRefresh: (id: String, hz: Int)?
    @State private var showRefreshWarning = false
    private let cyan = Color(red: 0.40, green: 0.84, blue: 1.00)
    private let panelBackground = Color.white.opacity(0.075)

    private var current: DashboardPanel? {
        model.panels.first(where: { $0.id == selectedUUID }) ?? model.panels.first
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.055, green: 0.09, blue: 0.16),
                                     Color(red: 0.035, green: 0.055, blue: 0.09)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Circle()
                .fill(cyan.opacity(0.13))
                .frame(width: 480, height: 480)
                .blur(radius: 140)
                .offset(x: 340, y: -240)
                .allowsHitTesting(false)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if let panel = current {
                        displaySelector
                        stats(for: panel)
                        statusCard(for: panel)
                        stabilityCard(for: panel)
                        modeCard(for: panel)
                        hdrCard(for: panel)
                    } else {
                        card {
                            Label("Kein externer Monitor erkannt", systemImage: "display.trianglebadge.exclamationmark")
                                .font(.headline)
                            Text("Schließe den LG UltraGear direkt an und klicke auf Aktualisieren.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    footer
                }
                .padding(28)
                .frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedUUID.isEmpty { selectedUUID = model.panels.first?.id ?? "" }
        }
        .alert("Virtuelles HiDPI kann HDR einschränken", isPresented: $showHDRWarning) {
            Button("Abbrechen", role: .cancel) { pendingEnableUUID = nil }
            Button("HiDPI trotzdem einschalten") {
                if let uuid = pendingEnableUUID { model.setHiDPI?(uuid, true) }
                pendingEnableUUID = nil
            }
        } message: {
            Text("machidpi spiegelt einen virtuellen Bildschirm. Der HDR-Schalter am LG bzw. in macOS kann weiter aktiv sein, aber ein vollständiger HDR-Renderpfad über die virtuelle Spiegelung ist nicht nachgewiesen. Nach dem Wechsel HDR erneut prüfen.")
        }
        .alert("Bildrate ändern – kurzzeitiger Bildwechsel", isPresented: $showRefreshWarning) {
            Button("Abbrechen", role: .cancel) { pendingRefresh = nil }
            Button("Bildrate wechseln") {
                if let requested = pendingRefresh {
                    model.setRefreshRate?(requested.id, requested.hz)
                }
                pendingRefresh = nil
            }
        } message: {
            Text("Mac Display Control beendet bei Bedarf die virtuelle Spiegelung, sucht einen nativen Bildschirmmodus mit der gewünschten Bildrate und startet HiDPI anschließend neu. Das Bild kann kurz schwarz werden. HDR muss danach in macOS erneut geprüft werden. Nicht angebotene Bildraten werden nicht erzwungen.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text("DISPLAY CONTROL · MrNoooooooob")
                    .font(.caption.bold())
                    .tracking(2.5)
                    .foregroundStyle(cyan)
                Text("Dein Monitor. Deine Einstellungen.")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                Text("LG UltraGear OLED · HiDPI mit machidpi-Technik")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { model.reload?() } label: {
                Label("Aktualisieren", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 16)
    }

    private var displaySelector: some View {
        HStack(spacing: 12) {
            Image(systemName: "display")
                .font(.title3)
                .foregroundStyle(cyan)
            VStack(alignment: .leading, spacing: 3) {
                Text("Aktiver Monitor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if model.panels.count > 1 {
                    Picker("Monitor", selection: $selectedUUID) {
                        ForEach(model.panels) { panel in
                            Text(panel.name).tag(panel.id)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 320, alignment: .leading)
                } else {
                    Text(current?.name ?? "Kein Display")
                        .font(.headline)
                }
            }
            Spacer()
            Circle()
                .fill((current?.isEnabled == true || current?.isExternallyMirrored == true) ? .green : .gray)
                .frame(width: 8, height: 8)
            Text(current?.isEnabled == true ? "HiDPI von dieser App" :
                 (current?.isExternallyMirrored == true ? "Externe HiDPI-Spiegelung" : "Native Anzeige"))
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(18)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func stats(for panel: DashboardPanel) -> some View {
        HStack(spacing: 12) {
            metric(title: "Monitor", value: "\(panel.nativeWidth) × \(panel.nativeHeight)", icon: "display")
            metric(title: "Bildrate", value: "\(Int(panel.panelHz.rounded())) Hz", icon: "speedometer")
            metric(title: "Skalierung", value: String(format: "%.1f×", panel.backingScale), icon: "square.dashed")
        }
    }

    private func metric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(value)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func statusCard(for panel: DashboardPanel) -> some View {
        card {
            HStack {
                Label("Live-Status in der Menüleiste", systemImage: "menubar.rectangle")
                    .font(.headline)
                Spacer()
                Text("Automatisch aktualisiert")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                statusPill(panel.backingScale >= 1.9 ? "HiDPI 2×" : "HiDPI aus",
                           symbol: "sparkles", good: panel.backingScale >= 1.9)
                statusPill(panel.hdrConfirmedByUser ? "HDR ✓*" : "HDR ?",
                           symbol: "sun.max", good: panel.hdrConfirmedByUser)
                statusPill("\(Int(panel.panelHz.rounded())) Hz",
                           symbol: "gauge", good: panel.panelHz >= 239)
                Spacer(minLength: 0)
            }
            Text("* HDR ✓ bedeutet: Du hast den HDR-Schalter für diesen Modus bestätigt. Die HDR-Ausgabe wird nicht automatisch gemessen; virtuelle Spiegelung kann sie einschränken.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func statusPill(_ title: String, symbol: String, good: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .foregroundStyle(good ? Color.green : Color.secondary)
            .background((good ? Color.green : Color.white).opacity(0.11),
                        in: Capsule())
    }

    // Explicit refresh-rate change. The core switches the physical panel natively
    // and only then recreates the virtual 2x display with the measured frequency.
    private func stabilityCard(for panel: DashboardPanel) -> some View {
        card {
            HStack(alignment: .top) {
                Label("Bildstabilität & Bildrate", systemImage: "waveform.path.ecg.rectangle")
                    .font(.title3.bold())
                Spacer()
                Text(Int(panel.panelHz.rounded()) == 120 ? "120 HZ · TESTPROFIL" : "LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(Int(panel.panelHz.rounded()) == 120 ? .cyan : .orange)
            }
            let rate = DisplayStabilityPolicy.pixelRateGigapixels(width: panel.renderWidth,
                            height: panel.renderHeight, hz: panel.panelHz)
            Text("\(panel.renderWidth) × \(panel.renderHeight) Renderpixel · \(Int(panel.panelHz.rounded())) Hz · ca. \(String(format: "%.2f", rate)) Gigapixel/s")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Bei 240 Hz sind pinke Flecken aufgetreten. 120 Hz waren im bisherigen Test offenbar stabil. Das ist keine Garantie, aber die empfohlene Einstellung für die virtuelle HiDPI-Spiegelung.")
                .font(.subheadline)
            HStack(spacing: 10) {
                ForEach([120, 144, 240], id: \.self) { rate in
                    Button {
                        pendingRefresh = (id: panel.id, hz: rate)
                        showRefreshWarning = true
                    } label: {
                        HStack(spacing: 5) {
                            if Int(panel.panelHz.rounded()) == rate {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("\(rate) Hz")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(rate == 120 ? .cyan : .gray)
                    .disabled(panel.isPending || panel.isExternallyMirrored || Int(panel.panelHz.rounded()) == rate || !panel.supportedRefreshRates.contains(rate))
                    .help("Es werden ausschließlich von macOS tatsächlich bereitgestellte native Displaymodi angewendet")
                }
            }
            Text("Nur nativ angebotene Bildraten sind wählbar. Ist 120 Hz ausgegraut, zuerst HiDPI deaktivieren und den nativen Modus in macOS prüfen. Eine flackerfreie Darstellung ist nicht garantiert.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !panel.supportedRefreshRates.isEmpty {
                Text("Bei der Abfrage aktuell gemeldet: \(panel.supportedRefreshRates.map { "\($0) Hz" }.joined(separator: " · "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button {
                    model.setHiDPI?(panel.id, false)
                    model.lastNotice = "Virtuelle Spiegelung deaktiviert – native Einstellungen können nun geprüft werden."
                } label: {
                    Label("Zur nativen Anzeige", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
                .disabled(!panel.isEnabled || panel.isPending)
                Button("macOS Displays öffnen") { openDisplays() }
                    .buttonStyle(.bordered)
            }
            Label("HDR-Signal wird nicht automatisch gemessen. Nach jedem Wechsel HDR manuell prüfen. Pinke Artefakte kann die App nicht direkt erkennen.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    private func modeCard(for panel: DashboardPanel) -> some View {
        card {
            HStack {
                Label("HiDPI & Darstellung", systemImage: "sparkles.rectangle.stack")
                    .font(.title3.bold())
                Spacer()
                Text(panel.backingScale >= 1.9 ? "RETINA 2×" : (panel.isEnabled ? "HiDPI-START" : "NATIV"))
                    .font(.caption.bold())
                    .foregroundStyle(panel.isEnabled ? cyan : .secondary)
            }

            Text(panel.isEnabled
                 ? "Mac Display Control spiegelt einen virtuellen Retina-Desktop auf deinen Monitor."
                 : (panel.isExternallyMirrored
                    ? "Ein anderes Programm spiegelt bereits einen virtuellen Bildschirm. Um Konflikte zu vermeiden, kann Mac Display Control diese Sitzung nur lesen."
                    : "Für dein OLED bleibt die native Verbindung ohne virtuelle Spiegelung bestehen."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    if panel.isEnabled {
                        model.setHiDPI?(panel.id, false)
                    } else {
                        pendingEnableUUID = panel.id
                        showHDRWarning = true
                    }
                } label: {
                    Label(panel.isEnabled ? "Virtuelles HiDPI deaktivieren" : "Virtuelles HiDPI aktivieren",
                          systemImage: panel.isEnabled ? "power" : "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(panel.isEnabled ? .gray : cyan)
                .disabled(panel.isPending || panel.isExternallyMirrored)

                Button("Displays öffnen") { openDisplays() }
                    .buttonStyle(.bordered)
            }

            if panel.isEnabled {
                HStack {
                    Text("Arbeitsfläche")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        ForEach(panel.rungs, id: \.self) { rung in
                            Button {
                                model.setRung?(panel.id, rung)
                            } label: {
                                let exact = Scaling.isPixelExact(rung,
                                    panelWidth: panel.nativeWidth, panelHeight: panel.nativeHeight)
                                Text("\(rung.label)\(exact ? "  ✦ pixelgenau" : "")")
                            }
                        }
                    } label: {
                        HStack {
                            Text(panel.activeRung?.label ?? "Modus wählen")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    .frame(minWidth: 180, alignment: .trailing)
                }
                HStack(spacing: 14) {
                    Label("Logisch: \(panel.logicalWidth) × \(panel.logicalHeight)", systemImage: "rectangle.dashed")
                    Label("Rendern: \(panel.renderWidth) × \(panel.renderHeight)", systemImage: "square.on.square")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if panel.isExternallyMirrored {
                Label("Die andere machidpi-Instanz vollständig beenden, bevor du hier HiDPI einschaltest.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Standardmäßig wird beim Aktivieren die nahezu unveränderte Desktopgröße gewählt: \(panel.nativeWidth) × \(panel.nativeHeight) Punkte, wenn der Modus verfügbar ist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = panel.errorText {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func hdrCard(for panel: DashboardPanel) -> some View {
        card {
            HStack {
                Label("HDR & OLED", systemImage: "sun.max")
                    .font(.title3.bold())
                Spacer()
                Text(panel.hdrConfirmedByUser ? "MANUELL BESTÄTIGT*" : "NICHT BESTÄTIGT")
                    .font(.caption.bold())
                    .foregroundStyle(panel.hdrConfirmedByUser ? .green : .orange)
            }
            Text(panel.isEnabled || panel.isExternallyMirrored
                 ? "Virtuelles HiDPI ist aktiv. Falls der HDR-Schalter in macOS noch eingeschaltet ist, kannst du das hier bestätigen. Das beweist nicht, dass die virtuelle machidpi-Spiegelung HDR-Pixel mit erweitertem Dynamikumfang ausgibt."
                 : "Natives HDMI-Display. Prüfe unter Systemeinstellungen → Displays, ob Hochkontrastbild eingeschaltet ist, und bestätige den aktuellen Modus hier.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Toggle("HDR-Schalter in macOS ist eingeschaltet (manuell bestätigt)", isOn: Binding(
                get: { panel.hdrConfirmedByUser },
                set: { model.setHDRConfirmed?(panel.id, $0) }
            ))
            .toggleStyle(.switch)
            .font(.subheadline)

            if panel.isEnabled || panel.isExternallyMirrored {
                Label("Hinweis: HDR-Renderpfad bei virtueller Spiegelung nicht verifiziert", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack {
                Label("HDR ✓* = Nutzeraussage, keine Signalmessung", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("HDR-Einstellungen") { openDisplays() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Toggle("Beim Anmelden starten", isOn: Binding(
                    get: { model.loginEnabled },
                    set: { model.setLogin?($0) }
                ))
                .toggleStyle(.switch)
                Spacer()
                Button {
                    let paste = NSPasteboard.general
                    paste.clearContents()
                    paste.setString(model.diagnosticText(), forType: .string)
                    model.lastNotice = "Diagnose kopiert"
                } label: {
                    Label("Diagnose kopieren", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            if !model.lastNotice.isEmpty {
                Text(model.lastNotice).font(.caption).foregroundStyle(cyan)
            }
            Text("v0.0.2-beta · © 2026 MrNoooooooob · Basis: machidpi (MIT, © 2026 ac50). Empfohlen: 120 Hz für stabile virtuelle HiDPI-Spiegelung. Es werden ausschließlich von macOS angebotene Modi gewählt. HDR-Ausgabe wird nicht automatisch verifiziert. Keine EDID-Overrides, kein SIP-Eingriff.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 3)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 17, content: content)
            .padding(21)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panelBackground, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func openDisplays() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
