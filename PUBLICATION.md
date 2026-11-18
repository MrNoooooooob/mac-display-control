# Veröffentlichung: v0.0.2-beta — MrNoooooooob/mac-display-control

1. `gh auth login` (wenn noch nicht angemeldet) und `gh auth status` prüfen.
2. `python3 tests/test_patch.py` und `bash build.command` auf macOS ausführen.
3. **Wenn das Repo nicht existiert:** `bash publish-github.command`.
4. **Das Repository existiert bereits (Tag `v0.0.1-beta`):** `bash publish-update.command`.
5. GitHub Actions abwarten; nur ein erfolgreicher macOS-Build liefert ein Release-Asset.

Beide Skripte fragen vor dem Push, prüfen den GitHub-Benutzernamen und überschreiben keinen existierenden Release-Tag. Es wird nicht auf bestehende fremde Repositories veröffentlicht.
**Stand dieses Pakets:** noch nicht nachweislich auf GitHub veröffentlicht. Kein macOS-Build in der aktuellen Containerumgebung möglich.
