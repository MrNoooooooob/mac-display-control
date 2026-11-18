# Changelog · Mac Display Control by MrNoooooooob

## 0.0.1-beta (erste öffentliche Beta)

- 120 Hz als bevorzugte Stabilitätseinstellung für den LG UltraGear OLED ergänzt.
- 120/144/240-Hz-Bedienelemente: nativen Modus beim physischen Display suchen, nicht virtuelle Hz vortäuschen.
- Virtuelle HiDPI-Spiegelung wird für einen Bildratenwechsel bei Bedarf beendet und danach mit der tatsächlich gemessenen nativen Frequenz erneut gestartet.
- Nachkontrolle der nativen Frequenz und Best-Effort-Rückstellung, falls macOS den Modus nicht übernommen hat.
- Vorsichtshinweis vor jedem bewussten Bildratenwechsel; HDR-Bestätigung nach Moduswechsel ungültig.
- Statusleiste bleibt live: HiDPI 2×, HDR ✓* (nur manuell bestätigt), tatsächliche Hz.
- Kompatibilität mit dem festgelegten machidpi-MIT-Quellstand bleibt erhalten.
- GitHub-Repository-Material mit MIT-Hinweisen, Build-Workflow und Release-Vorlage ergänzt.

## 1.3.0

- Physische LG-Panelgröße trotz virtueller Spiegelung 3440 × 1440.
- Bildstabilitätsdiagnose für pinke Flecken/Flackern ergänzt.

## 1.2.0

- Doppelte Displayeinträge und fehlerhafte Panelauflösungen im Dashboard reduziert.

## 1.1.0

- HDR-Schalter kann manuell bestätigt werden, ohne echten HDMI-HDR-Nachweis zu behaupten.
