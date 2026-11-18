# Mac Display Control by MrNoooooooob

**© 2026 MrNoooooooob** · Eigene macOS-Menüleisten-App für externe Displays: HiDPI, Bildwiederholrate, HDR-Hinweis und Stabilitätsprofile.  
*Version 0.0.1 Beta · Deutsch · Apple Silicon · macOS 26+*

Das Projekt basiert auf dem Open-Source-Kern [machidpi](https://github.com/ac50/machidpi) von **ac50**, veröffentlicht unter der MIT-Lizenz. Mac Display Control ergänzt eine eigenständige SwiftUI-Oberfläche und Displaydiagnose. Der virtuelle HiDPI-Kern gehört weiterhin machidpi; dies ist **kein offizielles machidpi-Release**.

## Funktionen

- Live-Menüleiste: `HiDPI 2× · HDR ✓* · 120 Hz` (Beispiel)
- Übersicht über **physisches Panel**, logische Desktopfläche und **2×-Renderauflösung**
- **120-Hz-Stabilitätsprofil** für virtuelle HiDPI-Spiegelung; 144/240 Hz sind optional, wenn macOS die Modi nativ anbietet
- Bei Bildratenwechsel: virtuelle Spiegelung nötigenfalls trennen, echten nativen Bildschirmmodus mit CoreGraphics auswählen, Ergebnis überprüfen und HiDPI neu starten
- Fehlgeschlagene Moduswechsel werden nach Möglichkeit zurückgesetzt; nicht unterstützte Bildraten werden **nicht erzwungen**
- Wahl der UI-Skalierung ohne größere Fenster als nötig (3440 × 1440 logische Punkte für das LG UltraGear 34GX90SA-W)
- Monitorerkennung für LG SMARTGAME+ mit korrekten **3440 × 1440 physischen Pixeln**; Filter gegen doppelte virtuelle Displays
- Warnung bei Bildartefakten und ein schneller Wechsel zur nativen Anzeige
- Manuelle HDR-Schalterbestätigung, die bei Moduswechsel zurückgesetzt wird
- Diagnose zum Kopieren; kein Tracking, keine Accounts, kein SIP-Eingriff

## Warum 120 Hz?

Auf dem getesteten **LG UltraGear 34GX90SA-W** am Mac mini M4 Pro kam es bei virtueller HiDPI-Spiegelung mit **240 Hz** gelegentlich zu pinken Flecken/Flackern. Bei **120 Hz** wurde das Problem zunächst nicht mehr beobachtet. Das ist eine gerätespezifische Beobachtung, **keine garantierte Fehlerbehebung**. 240 Hz bleiben als Option erhalten.

## HDR: Was die Anzeige bedeutet

`HDR ✓*` ist eine **manuelle Bestätigung des macOS-HDR-Schalters**, keine Messung der tatsächlichen HDR-Ausgabe. Die virtuelle machidpi-Displaytechnik besitzt laut Originalprojekt **keine vollständige/verifizierte HDR-Pipeline**. Es wäre falsch, echte HDR-Bildausgabe allein anhand des Schalters oder eines EDR-Potenzials zu behaupten. Nach jedem Moduswechsel in macOS **Systemeinstellungen → Displays** kontrollieren.

## Kompatibilität

- Mac mit Apple Silicon, macOS **26 oder neuer**
- Swift/Xcode Command Line Tools, Git, Python 3, Internet beim ersten Build
- Ausgerichtet auf eine vom Nutzer geprüfte Kombination (vollständiger v0.0.1-beta-Build noch nicht getestet): LG UltraGear 34GX90SA-W, 3440 × 1440, per HDMI am Mac mini M4 Pro
- Andere externe Displays: teilweise möglich, jedoch nicht verifiziert
- **Achtung:** Der virtuelle HiDPI-Kern verwendet eine private macOS-Grafikschnittstelle. Ein macOS-Update kann ihn verändern oder deaktivieren.

## Installation (lokal)

1. Andere Instanzen von `machidpi` und `Mac Display Control` beenden. Eine bestehende virtuelle Spiegelung wird dadurch deaktiviert.
2. Dieses Projekt als ZIP entpacken bzw. GitHub-Repository klonen.
3. Im Terminal im Projektordner ausführen:

   ```bash
   bash build.command
   ```

4. Das Skript lädt den MIT-lizenzierten machidpi-Quellcode auf den **festgelegten Commit** `3d105b0f18cc2522e27028bc1a1ee4b6ff1ef7d6` und baut daraus `Mac Display Control.app`.
5. App starten, bei Bedarf HiDPI aktivieren und **120 Hz** als Stabilitätsprofil auswählen. Vor dem ersten Wechsel offene Arbeiten speichern.

Die App wird lokal **ad hoc** signiert, aber nicht Apple-notarisiert. Auf anderen Macs kann Gatekeeper nach einer zusätzlichen Bestätigung fragen. Das Projekt verlangt **keine Deaktivierung von SIP** und schreibt keine neuen Display-Overrides.

## Direkt in der App: 120/144/240 Hz

Die Bildrate wird beim laufenden virtuellen Modus nicht einfach im virtuellen Display verändert. Stattdessen wird die Spiegelung vorübergehend ausgeschaltet, ein **vom physischen Display angebotenes** natives Timing gewählt, seine tatsächliche Aktivierung geprüft und erst dann die virtuelle HiDPI-Spiegelung neu erzeugt. Steht die angeforderte Bildrate nicht zur Verfügung, wird sie nicht erzeugt oder erzwungen. Ein Wechsel kann das Bild vorübergehend schwarz machen und den HDR-Modus beeinflussen.

> Während der ersten Betaversion ist die Wiederherstellung ein Best-Effort-Schutz, kein Garant gegen jeden Black-Screen. Wenn es Probleme gibt, die App beenden und die Anzeige in macOS unter **Displays** wiederherstellen.

## Tests und Nachvollziehbarkeit

```bash
python3 tests/test_patch.py  # Offline-Patch/Swift-Syntax/Script-Smoke-Test
bash -n build.command
```

**Wichtig:** Ein erfolgreicher Swift-Parser-Test außerhalb von macOS ist noch **kein** vollständiger AppKit/SwiftUI-Build. Der GitHub-Actions-Workflow führt den macOS-Build auf `macos-26` aus; der tatsächliche HiDPI/HDR/120-Hz-Test benötigt einen angeschlossenen Monitor.

## Veröffentlichung auf GitHub

Dieses Verzeichnis ist für das neue, eigenständige öffentliche Repository **`MrNoooooooob/mac-display-control`** vorbereitet. Es ist vor der Erstveröffentlichung **noch nicht online**. Der Workflow unter `.github/workflows/build.yml` baut die App bei jedem Push und erstellt beim Push eines Tags wie `v0.0.1-beta` eine **Vorabveröffentlichung** mit ZIP-Datei. Mit `bash publish-github.command` auf deinem Mac das Repository erstellen und den Tag `v0.0.1-beta` veröffentlichen. Dieser Tag löst bei erfolgreichem macOS-CI-Build automatisch einen GitHub-Pre-Release aus. Screenshots können nach Prüfung persönlicher Informationen im Repository ergänzt werden.

## Herkunft / Lizenz

- **Originalprojekt:** [ac50/machidpi](https://github.com/ac50/machidpi), MIT, © 2026 ac50
- **Anpassungen:** Mac Display Control, MIT-Lizenz für zusätzliche Inhalte und Patches
- Original-Lizenz: [`LICENSE-machidpi.txt`](LICENSE-machidpi.txt)
- Hinweise zu Lizenz, privaten APIs und Projektherkunft: [`NOTICE.md`](NOTICE.md)

Nicht offiziell von LG, Apple oder ac50 unterstützt.

## Roadmap

Siehe [`ROADMAP.md`](ROADMAP.md): eigener Modus-/Statuskern, mehr Diagnosen, sichere Umschaltung und schrittweiser Ersatz des von machidpi übernommenen virtuellen Kerns. Das ist ein Entwicklungsziel, kein bereits umgesetzter Ersatz.

**Projektinhaber und Copyright an den eigenen Bestandteilen:** © 2026 MrNoooooooob. Der MIT-lizenzierte machidpi-Ursprungscode bleibt © 2026 ac50.

## GitHub-Veröffentlichung mit GitHub CLI

Wenn GitHub CLI installiert und angemeldet ist (`gh auth login`), kann `bash publish-github.command` das neue öffentliche Repository **MrNoooooooob/mac-display-control** anlegen und die Quellen hochladen. Das Skript prüft das angemeldete Konto, fragt ausdrücklich vor dem öffentlichen Upload und bricht ab, falls das Repository bereits existiert. Das Skript veröffentlicht den Release-Tag; der Download-Build wird anschließend von GitHub Actions erstellt. Es wurde lokal auf Shell-Syntax geprüft, aber nicht auf einem verbundenen Mac ausgeführt.
