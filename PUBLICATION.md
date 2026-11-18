# Mac Display Control – Automatische Beta-Releases

© 2026 MrNoooooooob. Originaler machidpi-Kern © 2026 ac50 (MIT).

## Einmalig auf dem Mac

Apple Silicon / macOS 26+, Xcode Command Line Tools und GitHub CLI installieren, dann `gh auth login` ausführen.

## Neues Release (ab v0.0.3-beta)

1. `VERSION` auf die neue Versionsnummer setzen (z. B. `0.0.3-beta`).
2. `RELEASE_NOTES.md` aktualisieren.
3. `bash publish-update.command` ausführen und mit `ja` bestätigen.

Das Skript committet die Änderungen und pusht einen neuen, unveränderlichen Git-Tag. GitHub Actions baut die fertige Apple-Silicon-App, verpackt sie als `Mac-Display-Control-v<version>-macOS-arm64.zip` und hängt sie zusammen mit `RELEASE_NOTES.md` an den GitHub-Pre-Release. Die automatischen Source-code-Archive bleiben zusätzlich sichtbar.

## Bestehendes Tag v0.0.2-beta

Da der Tag bereits existiert, wird er **nicht überschrieben**. Prüfe den Status mit:
```bash
bash publish-update.command --status
```
Du kannst den GitHub-Workflow erneut anfordern:
```bash
bash publish-update.command --retry-ci
```
Wenn GitHub Actions keinen Runner erhält oder der Build dort fehlschlägt, baue die bestehende Version lokal **aus dem Git-Tag** und lade die fertige App direkt hoch:
```bash
bash publish-update.command --local-release
```
Dabei wird vor dem Upload nach Bestätigung gefragt. Eine vorhandene Release-Datei gleichen Namens wird erst nach Bestätigung ersetzt.

## Hinweise

Die App ist ad-hoc signiert, aber nicht Apple-notarisiert. Beim Start kann Gatekeeper eine Rückfrage zeigen. SIP und Gatekeeper müssen dafür nicht global deaktiviert werden. Ein Release ist erst dann als fertiger App-Download verfügbar, wenn der ZIP-Build erfolgreich war.
