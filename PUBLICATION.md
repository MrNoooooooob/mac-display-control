# v0.0.4-beta veröffentlichen

1. `gh auth login` als MrNoooooooob.
2. Im Projektordner `bash publish-update.command` ausführen und Veröffentlichung bestätigen.
3. GitHub Actions baut die arm64 `.app` als `Mac-Display-Control-v0.0.4-beta-macOS-arm64.zip` und erstellt einen Pre-Release.
4. Falls Runner/CI nicht funktionieren: `bash publish-update.command --local-release`.

**Nicht manuell vorhandene Tags überschreiben.** Erst v0.0.3, dann v0.0.4-beta veröffentlichen. Ohne tatsächlichen Build darf nicht behauptet werden, dass ein fertiges App-ZIP bereits vorliegt.
