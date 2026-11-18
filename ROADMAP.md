# Mac Display Control – After 1.0 source preview

Die bisherige Funktions-Roadmap wurde in den Quellcode integriert, soweit mit öffentlicher macOS-Diagnose und dem bestehenden machidpi-Kern umsetzbar.

1. macOS-Build auf Apple Silicon erfolgreich nachweisen, echte Sleep/Wake-, 120/144/240-Hz- und Mehrmonitor-Tests.
2. Langzeittest: pinke Artefakte, Ruhemodus, Bildschirm-Hotplug, HDMI-Farbmodus, VRR und HDR-Schalter.
3. Kompletter Ersatz der privat-API-basierten virtuellen Spiegelung durch eigene, nachweislich funktionierende Engine (derzeit Forschungsziel, nicht enthalten).
4. Native HiDPI + echte HDMI-HDR-Ausgabe bei gleichem Desktopformat verifizieren, bevor es als Feature beworben wird.
5. Apple Developer ID Signierung, Notarisierung und Gatekeeper-kompatibler Installer nach Einrichtung der nötigen Konten/Secrets.
