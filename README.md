# Mac Display Control 1.0 · by MrNoooooooob

**© 2026 MrNoooooooob** · SwiftUI für Apple Silicon (macOS 26+) · MIT

## Funktionen der 1.0-Quellcode-Vorschau

- **Live-Menüleiste:** HiDPI 1×/2×, manuell bestätigter HDR-Schalter (`HDR ✓*`), gemessene Bildrate, kompakter Modus.
- **Bildstabilität:** 120, 144, 240 Hz nur bei nativ angebotenen Modi; vor dem Umbau der Spiegelung erfolgt die Prüfung; nach Wechsel Bestätigung und Rückstellung, sofern die vorige Einstellung ermittelbar bleibt.
- **Displayprofile:** Stabilität, Alltag, Gaming; pro stabiler Display-UUID gespeichert, manuell aktivierbar.
- **Opt-in Automatik:** Wenn ausdrücklich eingeschaltet, Profil nach Appstart oder Wake anwenden, nur bei gemeldeter Zielbildrate, keiner fremden Spiegelung und keinem laufenden Wechsel. Standardmäßig **AUS**.
- **Display Health:** Sleep/Wake, Modi, Spiegelungsänderungen, An-/Abmeldung und manuelle Aktionen; maximal 250 Einträge lokal in UserDefaults; exportierbar und löschbar. Keine automatische Pink-Flacker-Erkennung.
- **Native HDR-/HiDPI-Lab:** Nur lesende Prüfung, welche Modi macOS auflistet. Ein gelisteter Modus muss nicht aktivierbar sein. EDR-Werte sind **kein** Nachweis eines HDR-HDMI-Signals.
- **Liquid-Glass-Dashboard:** SwiftUI mit Material-Karten, Reitern für Übersicht, Profile, Display Health und HDR/HiDPI Lab.
- **Updates:** Manuelle GitHub-Releases-Abfrage, keine stille Installation.
- **Eigenständige Swift-Bausteine:** DisplayStabilityPolicy, DisplayProfiles, NativeDisplayEngine, DisplayHealth, ProfileAutomation, ReleaseVersion. Die **virtuelle Spiegelungs-Engine wird noch von machidpi bereitgestellt**.

## Installation (aus Quellcode)

Auf einem Mac mit Apple Silicon und Xcode Command Line Tools, im ausgepackten Projekt:

```bash
bash build.command
```

Vor dem Build lässt sich der Quellcode mit `bash verify.command` prüfen. Der Build lädt den auf einen bestimmten Commit fixierten Originalcode von machidpi. Die daraus erstellte `Mac Display Control.app` ist ad-hoc signiert, nicht notarisiert. GitHub Actions erstellt nach einem erfolgreichen macOS-Build ZIP- und DMG-Dateien; beide sind ohne eingerichtete Apple-Developer-ID-Signierung **nicht notarisiert**. Alte machidpi-/MDC-Instanzen vor dem Test beenden; ihre aktive Spiegelung wird dadurch unterbrochen. Bei Anzeigeproblemen HiDPI ausschalten und native Auflösung wiederherstellen. Keine Änderung an SIP oder versteckten EDID-Overrides erforderlich.

**Status:** Patch-/Syntax-/Foundation-Modultests wurden außerhalb von macOS geprüft. Vollständiger macOS-App-Build, reale Wake-Tests, HDR-Ausgabe und Stabilität sind noch nicht verifiziert. Deshalb ist 1.0 vorerst eine **Source Preview**, kein als stabil bestätigter Release.

## Grenzen

VirtualHiDPI verwendet das private CoreGraphics-API `CGVirtualDisplay` und eine Spiegelung, die laut machidpi-Projekt keine HDR-Pipeline bietet. Die App darf den HDR-Schalter manuell als aktiv markieren, aber das beweist **nicht** die HDR-Bildausgabe. 6880 × 2880 Renderpixel bei 120/240 Hz können die Hardware belasten. Pinke Artefakte werden nicht automatisch erkannt. Die echte Panelgröße deines LG 34GX90SA-W ist 3440 × 1440.

## GitHub-Version

Bei verifiziertem macOS-Build und nach Test: `bash publish-update.command` veröffentlicht die Versionsnummer aus `VERSION` auf [MrNoooooooob/mac-display-control](https://github.com/MrNoooooooob/mac-display-control). Bitte erst danach Version **1.0.0** als stabil markieren; aktuell empfiehlt sich eine Vorschau/Pre-Release.

## Urheberrecht

Eigene Oberfläche, Policy-Module und Erweiterungen: **© 2026 MrNoooooooob**. Original machidpi MIT-Kern **© 2026 ac50**: Lizenz in `LICENSE-machidpi.txt`, Herkunft in `NOTICE.md`. Die Originalurheberschaft wird nicht entfernt oder umbenannt.
