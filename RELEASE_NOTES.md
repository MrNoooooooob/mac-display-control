# Mac Display Control 1.0.0 — Source Preview

© 2026 **MrNoooooooob**

Dieses Paket führt die bisher geplanten Funktionen in einer macOS-App zusammen: Anzeige von HiDPI, Hz und manuell bestätigtem HDR-Schalter in der Menüleiste; Stabilitätsprofile für 120/144/240 Hz, gespeicherte und opt-in automatische Profile; Display Health; ein nur lesendes HDR/HiDPI-Lab; Liquid-Glass-Dashboard und manuelle Update-Prüfung.

**Wichtige Einschränkungen:** Der virtuelle HiDPI-Betrieb nutzt weiterhin den MIT-lizenzierten machidpi-Kern von ac50. Dessen Spiegelung hat keine verifizierte HDR-Pipeline. `HDR ✓*` bezieht sich nur auf die manuelle Bestätigung des Schalters. Pinkes Flackern kann nicht automatisch erkannt oder nachweislich beseitigt werden.

**Prüfstand:** Swift-Foundation-Tests, Patch- und Bash-Prüfungen durchgeführt; vollständiger macOS-Build und Gerätevalidierung noch ausstehend. Nicht als stabilen 1.0-GitHub-Release markieren, bevor diese bestanden sind.

**macOS:** Apple Silicon mit macOS 26+. Der Quellcode wird mit `bash build.command` in eine `.app` gebaut. Ad-hoc signiert, nicht notarisiert. Die Original-MIT-Lizenz und Copyright-Hinweise sind beigefügt.
