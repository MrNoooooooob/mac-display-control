# Mac Display Control by MrNoooooooob v0.0.1-beta (Beta)

Eine eigenständige deutschsprachige macOS-Menüleisten-App auf Basis des MIT-lizenzierten **machidpi**-Kerns.

**Neu:** 120-Hz-Stabilitätsprofil, optionale 144/240-Hz-Auswahl, Überprüfung der tatsächlich vom physischen Display angebotenen Modi und Neuaufbau der virtuellen HiDPI-Spiegelung nach einem Frequenzwechsel. Live-Menüleiste mit HiDPI-Faktor, manuell bestätigtem HDR-Schalter (`HDR ✓*`) und aktueller Bildwiederholrate.

**Bekannte Einschränkungen:** Virtuelle HiDPI-Spiegelung unterstützt laut Originalprojekt keine bestätigte HDR-Renderpipeline. Das pinke Flackern bei 240 Hz kann durch 120 Hz vermindert werden, die Ursache ist nicht abschließend geklärt. Bei einem Grafikfehler die App beenden und die native Anzeige wiederherstellen.

**Kompatibilität:** Apple Silicon, macOS 26+, lokale Erstellung bzw. aus dem CI erstelltes ad-hoc-signiertes Paket, nicht Apple-notarisiert.

**Open Source:** MIT für eigene Änderungen, Originalprojekt und Copyright von ac50 ausdrücklich genannt; `LICENSE-machidpi.txt` liegt bei.

**© 2026 MrNoooooooob** für neue App-Oberfläche, Integrationspatches und Dokumentation. Basierend auf machidpi (© 2026 ac50, MIT).
