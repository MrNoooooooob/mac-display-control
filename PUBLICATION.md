# GitHub Veröffentlichung – 0.0.1 Beta

**Ziel:** `https://github.com/MrNoooooooob/mac-display-control`  
**Release-Tag:** `v0.0.1-beta`  
**Lizenz:** MIT für eigene Bestandteile, Original-MIT-Lizenz und Urheberhinweis für ac50 bleiben erhalten.

## Einmalig auf dem Mac

1. GitHub CLI installieren: `brew install gh` (falls noch nicht installiert).
2. Einmalig anmelden: `gh auth login` (falls noch nicht angemeldet).
3. Dieses Paket entpacken, Terminal in dem entpackten Ordner öffnen.
4. Veröffentlichen: `bash publish-github.command`
5. Nachfrage mit `ja` bestätigen.

Das Skript prüft dein GitHub-Konto, die Source-Patches und die Skriptsyntax. Erst danach erstellt es **ein neues öffentliches Repository** und pusht den Tag `v0.0.1-beta`. GitHub Actions erstellt anschließend **nach erfolgreichem macOS-Build** die `.app` als ZIP und veröffentlicht sie als GitHub-Pre-Release. Solange der Build nicht erfolgreich war, ist der Release-Download nicht verfügbar.

**Wichtig:** Das Paket ist nicht bereits veröffentlicht, und ein vollständiger Build konnte hier nicht auf macOS getestet werden. Sollten die Tests in GitHub Actions fehlschlagen, überprüfe die Build-Protokolle dort.

Das Skript bricht ab, falls das Repository bereits existiert, statt es zu überschreiben. Das ZIP beinhaltet keinen geheimen Token, keine Nutzerdaten und keinen privaten Schlüssel.
