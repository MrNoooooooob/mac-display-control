#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
REPOSITORY='MrNoooooooob/mac-display-control'
TAG='v0.0.2-beta'

for dependency in gh git python3; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    echo "Fehlt: $dependency. GitHub CLI ggf. mit brew install gh installieren." >&2
    exit 1
  fi
done
if ! gh auth status >/dev/null 2>&1; then
  echo 'Zuerst anmelden: gh auth login' >&2
  exit 1
fi
LOGIN="$(gh api user --jq '.login')"
if [[ "$LOGIN" != 'MrNoooooooob' ]]; then
  echo "GitHub-Konto $LOGIN statt MrNoooooooob aktiv. Veröffentlichung abgebrochen." >&2
  exit 1
fi
if gh repo view "$REPOSITORY" >/dev/null 2>&1; then
  echo "Repository $REPOSITORY existiert schon; bestehende Repositories werden nicht überschrieben." >&2
  exit 1
fi
if [[ -e .git ]]; then
  echo 'Bereits ein Git-Repository. Abbruch zum Schutz vorhandener Historie.' >&2
  exit 1
fi
bash -n build.command
python3 tests/test_patch.py
printf 'Neues ÖFFENTLICHES Repository %s erstellen und Tag %s als Beta veröffentlichen? [ja/NEIN] ' "$REPOSITORY" "$TAG"
read -r ANSWER
if [[ "$ANSWER" != 'ja' ]]; then
  echo 'Abgebrochen; keine Änderungen auf GitHub.'
  exit 0
fi

# Nur dieses Projekt; keine Screenshots, privaten Dateien oder Benutzerkonfigurationen.
git init -b main
GH_ID="$(gh api user --jq '.id')"
git config user.name "$LOGIN"
git config user.email "${GH_ID}+${LOGIN}@users.noreply.github.com"
git add -A
git commit -m 'Initial public beta: Mac Display Control 0.0.2'
gh repo create "$REPOSITORY" --public --description 'Mac Display Control: HiDPI, HDR status and 120 Hz stability profiles for macOS' --source=. --remote=origin --push
git tag -a "$TAG" -m 'Mac Display Control 0.0.2 Beta'
git push origin "$TAG"
echo
printf 'Quellcode veröffentlicht: https://github.com/%s\n' "$REPOSITORY"
printf 'Release-Build läuft über GitHub Actions. Status: https://github.com/%s/actions\n' "$REPOSITORY"
printf 'Beta-Release (nach erfolgreichem Build): https://github.com/%s/releases/tag/%s\n' "$REPOSITORY" "$TAG"
