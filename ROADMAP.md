# Roadmap – Mac Display Control by MrNoooooooob

© 2026 MrNoooooooob. Offene Planung, keine zugesicherte Funktion.

## v1.4: umgesetzt im Quellcode (Beta)

- Eigenständige deutschsprachige SwiftUI-Oberfläche, Menüleistenstatus und Anzeige nativ vs. virtuell
- 120/144/240-Hz-Auswahl mit Prüfung gemeldeter nativer Timings; keine unkontrollierte Erzeugung zusätzlicher Bildraten
- Sicherheitsversuch: ursprünglichen nativen Modus wiederherstellen und virtuelle Spiegelung neu aufbauen
- Korrekte LG-Panelgröße unabhängig von synthetischen HiDPI-Rendergrößen
- Transparente Kennzeichnung von HDR als *manuell bestätigt*, nicht als HDMI-Signalmessung
- BSD-/MIT-konforme Weiterverwendung von machidpi und korrekte Urhebervermerke

## v1.5: Stabilität und Qualität

- Simulierbare Moduswechsel-Tests, Belastungstests über längere Sitzungen
- Ereignisprotokoll: WindowServer-Neuordnung, Monitor ab/angesteckt, Wiederherstellungsfehler
- Optionaler 90/100/120/144-Hz-Bildratentest nur bei sicher erkannten Modi
- Rollback-Watchdog außerhalb der GUI für verlässlicheren Schutz bei Absturz (nur nach Sicherheitsreview)
- App-Icon, Mehrsprachigkeit und barrierearme Anzeige

## v2.0: Eigenständiger Display-Kern (Forschung)

- Öffentliche CoreGraphics-/AppKit-Schicht für Erkennung, Geräteidentität und Moduswahl
- Separater pluggbarer HiDPI-Backend-Typ: nativ (HDR-Potenzial) vs. virtuell (HDR unsicher)
- Neue eigene Implementierung des virtuellen HiDPI-Backends mit Tests; bestehende machidpi-Teile werden nach und nach ersetzt
- Vollständige Trennung der eigenen Implementierung von fremden Copyright-Bestandteilen
- Signierung/Notarisierung für direkte Downloads, soweit private APIs kompatibel bleiben

**Wichtig:** Virtuelles HiDPI kann HDR verhindern. 2×-Rendering allein erhöht die physischen Pixel des Panels nicht. Für die genaue Kombination 3440×1440 + HiDPI + HDR + 120/240 Hz gibt es noch keine verifizierte vollständige Lösung.
