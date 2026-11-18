// Copyright © 2026 MrNoooooooob. MIT licensed.
// Independent display-analysis/policy core. No private APIs or mode mutations.
import Foundation

struct NativeDisplayMode: Equatable {
    let logicalWidth: Int
    let logicalHeight: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let hertz: Double
    var isHiDPI: Bool {
        logicalWidth > 0 && logicalHeight > 0 &&
        pixelWidth >= logicalWidth * 2 && pixelHeight >= logicalHeight * 2
    }
    var scale: Double { logicalWidth > 0 ? Double(pixelWidth) / Double(logicalWidth) : 1 }
}

struct NativeDisplayReport {
    let modes: [NativeDisplayMode]
    let panelWidth: Int
    let panelHeight: Int
    let edrPotential: Double?
    var fullSizeHiDPICandidates: [NativeDisplayMode] {
        modes.filter { $0.logicalWidth == panelWidth && $0.logicalHeight == panelHeight && $0.isHiDPI }
    }
    var nearNativeHiDPICandidates: [NativeDisplayMode] {
        modes.filter {
            $0.isHiDPI && $0.logicalWidth >= Int(Double(panelWidth)*0.95) &&
            $0.logicalHeight >= Int(Double(panelHeight)*0.95) && $0.hertz >= 119.2
        }
    }
    var summary: String {
        let exact = fullSizeHiDPICandidates.count
        let near = nearNativeHiDPICandidates.count
        let edr = edrPotential.map { String(format: "%.2f×", $0) } ?? "unbekannt"
        return "Nativ gemeldete Modi: \(modes.count), 2× volle Desktopgröße: \(exact), fast-native 2×: \(near); EDR-Potenzial: \(edr) (kein HDR-Signalnachweis)."
    }
}

enum NativeDisplayEngine {
    static func report(modes: [NativeDisplayMode], panelWidth: Int, panelHeight: Int,
                       edrPotential: Double?) -> NativeDisplayReport {
        NativeDisplayReport(modes: modes, panelWidth: panelWidth, panelHeight: panelHeight,
                            edrPotential: edrPotential)
    }
    // Only supported choices and only when CoreGraphics really enumerates them.
    static func acceptableRefreshRates(_ modes: [NativeDisplayMode], width: Int, height: Int) -> [Int] {
        [120, 144, 240].filter { target in
            modes.contains { $0.logicalWidth == width && $0.logicalHeight == height &&
                $0.pixelWidth == width && $0.pixelHeight == height &&
                abs($0.hertz - Double(target)) < 0.8 }
        }
    }
}
