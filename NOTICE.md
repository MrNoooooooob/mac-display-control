# Hinweise zu Herkunft, Lizenzen und Funktionen

**Mac Display Control by MrNoooooooob** ist ein eigenständiges Oberflächen-/Funktionsprojekt mit Adaptionen an [machidpi](https://github.com/ac50/machidpi) (© 2026 ac50, MIT). Der machidpi-Kern wird beim Build von einem festen Commit bezogen. Die originale MIT-Lizenz bleibt Bestandteil der Distribution: `LICENSE-machidpi.txt`.

Die zusätzlichen Oberflächen, Hilfstexte, Patches und Buildskripte dieses Repositories werden unter MIT bereitgestellt (siehe `LICENSE`). Das Projekt ist keine offizielle Version von machidpi und nicht mit Apple oder LG verbunden.

macOS kann Displays und HiDPI-Modi anders melden als erwartet. Die App verwendet für die virtuelle HiDPI-Spiegelung private CoreGraphics-Funktionen aus machidpi. **HDR ✓*** bezeichnet ausschließlich einen manuell bestätigten Systemschalter, nicht eine nachgewiesene HDR-Signal-/Renderausgabe. Angezeigte Renderpixel sind nicht die physische Auflösung des LCD/OLED-Panels.

**Sicherheit:** Vor Bildraten- oder Spiegelungswechseln offene Dateien speichern. Nicht jede GPU-/Panelkombination funktioniert bei 120, 144 oder 240 Hz. Es werden weder SIP-Deaktivierung noch Änderungen an System-EDID-Dateien verlangt.

**Urheber eigener Projektbestandteile:** © 2026 MrNoooooooob. Für machidpi gilt unverändert: © 2026 ac50 (MIT). Ein neuer Marken- und Projektname überträgt kein Copyright am Ursprungscode.
