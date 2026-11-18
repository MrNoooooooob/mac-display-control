#!/usr/bin/env bash
# Mac Display Control by MrNoooooooob – one-command GitHub publication.
# v0.0.2-beta onwards. Tag sources are immutable: never force-push tags.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
REPO='MrNoooooooob/mac-display-control'
MODE="${1:-publish}"
if [[ $# -gt 1 ]]; then echo 'Usage: bash publish-update.command [publish|--status|--retry-ci|--local-release|--help]' >&2; exit 2; fi

usage() {
  cat <<'EOF'
Mac Display Control – Releases von deinem Mac veröffentlichen

  bash publish-update.command                 Neues VERSION-Tag pushen und GitHub-Build starten.
  bash publish-update.command --status         GitHub Actions / Release-Status anzeigen.
  bash publish-update.command --retry-ci       Build für EXISTIERENDEN Tag erneut anfordern.
  bash publish-update.command --local-release  EXISTIERENDES Tag auf Mac bauen, .app zippen und
                                               als GitHub-Pre-Release hochladen (CI-Fallback).

Vor einem NEUEN Release: VERSION und RELEASE_NOTES.md aktualisieren.
Anmeldung: gh auth login; GitHub CLI: brew install gh.
Es werden weder existierende Tags überschrieben noch fremde Repositories geändert.
EOF
}
if [[ "$MODE" == '--help' || "$MODE" == '-h' ]]; then usage; exit 0; fi
case "$MODE" in publish|--status|--retry-ci|--local-release) ;; *) usage >&2; exit 2;; esac

fail(){ echo "FEHLER: $*" >&2; exit 1; }
for tool in gh git python3; do command -v "$tool" >/dev/null 2>&1 || fail "Fehlendes Tool: $tool"; done
[[ -f VERSION && -f RELEASE_NOTES.md ]] || fail 'VERSION oder RELEASE_NOTES.md fehlt.'
VERSION="$(tr -d '\r\n[:space:]' < VERSION)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9][a-zA-Z0-9.-]*)?$ ]] || fail "Ungültige VERSION: $VERSION"
TAG="v$VERSION"
ARCHIVE="Mac-Display-Control-${TAG}-macOS-arm64.zip"
RELEASE_TITLE="Mac Display Control ${VERSION}"
if ! gh auth status >/dev/null 2>&1; then fail 'Nicht bei GitHub angemeldet: gh auth login'; fi
LOGIN="$(gh api user --jq .login)"
[[ "$LOGIN" == 'MrNoooooooob' ]] || fail "Falsches GitHub-Konto: $LOGIN (erwartet MrNoooooooob)"
gh repo view "$REPO" >/dev/null 2>&1 || fail "Repository https://github.com/$REPO nicht erreichbar."
[[ "$(gh repo view "$REPO" --json visibility --jq .visibility)" == PUBLIC ]] || fail 'Repository ist nicht öffentlich; sicherheitshalber abgebrochen.'

tag_exists(){ gh api "repos/$REPO/git/ref/tags/$TAG" >/dev/null 2>&1; }
release_exists(){ gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; }

case "$MODE" in
  --status)
    echo "Repository: https://github.com/$REPO"
    echo "Version: $VERSION | Tag: $TAG"
    if tag_exists; then echo 'Tag vorhanden'; else echo 'Tag fehlt'; fi
    if release_exists; then
      echo "Release: https://github.com/$REPO/releases/tag/$TAG"
      gh release view "$TAG" --repo "$REPO" --json name,isPrerelease,assets,url --jq '{name,isPrerelease,url,assets:[.assets[].name]}'
    else echo 'Release fehlt noch (nur Source code sichtbar).'; fi
    echo 'Letzte GitHub-Builds:'
    gh run list --repo "$REPO" --workflow build.yml --limit 5 || true
    exit 0
    ;;
  --retry-ci)
    tag_exists || fail "Tag $TAG existiert noch nicht. Erst ohne Option veröffentlichen."
    gh workflow run build.yml --repo "$REPO" --ref "$TAG"
    echo "Build für $TAG gestartet: https://github.com/$REPO/actions"
    echo 'Falls macOS-Runner nicht starten, kannst du --local-release ausführen.'
    exit 0
    ;;
  --local-release)
    [[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || fail 'Lokaler Release-Build benötigt einen Apple-Silicon-Mac.'
    for tool in swift ditto codesign; do command -v "$tool" >/dev/null 2>&1 || fail "Fehlendes macOS-Werkzeug: $tool"; done
    tag_exists || fail "Tag $TAG existiert noch nicht. Erst ohne Option veröffentlichen."
    echo "Erstelle fertige App AUS DEM GITHUB-TAG $TAG, nicht aus ungeprüften lokalen Änderungen."
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    gh repo clone "$REPO" "$TMP/repo" -- --branch "$TAG" --depth 1
    cd "$TMP/repo"
    [[ "$(tr -d '\r\n[:space:]' < VERSION)" == "$VERSION" ]] || fail 'VERSION im GitHub-Tag stimmt nicht überein.'
    bash build.command
    [[ -d 'Mac Display Control.app/Contents/MacOS' ]] || fail 'Build hat keine ausführbare .app erzeugt.'
    ditto -c -k --sequesterRsrc --keepParent 'Mac Display Control.app' "$ARCHIVE"
    [[ -s "$ARCHIVE" ]] || fail 'ZIP wurde nicht erstellt.'
    echo "Fertiges Downloadpaket: $ARCHIVE"
    read -r -p "ZIP auf GitHub unter $TAG veröffentlichen/ersetzen? [ja/NEIN] " ANSWER
    [[ "$ANSWER" == ja ]] || { echo 'Abgebrochen, kein Upload.'; exit 0; }
    if release_exists; then
      gh release upload "$TAG" "$ARCHIVE" --repo "$REPO" --clobber
      gh release edit "$TAG" --repo "$REPO" --notes-file RELEASE_NOTES.md
    else
      # --verify-tag: never create an incorrect release from a nonexistent tag.
      if [[ "$VERSION" == *-* ]]; then PRE=(--prerelease); else PRE=(); fi
      gh release create "$TAG" "$ARCHIVE" --repo "$REPO" --verify-tag \
        --title "$RELEASE_TITLE" --notes-file RELEASE_NOTES.md "${PRE[@]}"
    fi
    echo "Download bereit: https://github.com/$REPO/releases/tag/$TAG"
    exit 0
    ;;
esac

# Default: publish NEW source version; existing tags are immutable.
if tag_exists; then
  echo "Tag $TAG existiert bereits. Nichts überschrieben."
  if release_exists; then
    echo "Release: https://github.com/$REPO/releases/tag/$TAG"
  else
    echo 'Es fehlt noch ein Release mit .app. Nutze:'
    echo '  bash publish-update.command --retry-ci'
    echo '  bash publish-update.command --local-release    # lokal bauen + direkt hochladen'
  fi
  exit 0
fi

bash -n build.command
bash -n publish-update.command
python3 tests/test_patch.py
[[ -s RELEASE_NOTES.md ]] || fail 'RELEASE_NOTES.md ist leer.'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
gh repo clone "$REPO" "$TMP/repo" -- --single-branch --branch main
cd "$TMP/repo"
[[ -z "$(git status --porcelain)" ]] || fail 'Remote-Arbeitskopie hat ungesicherte Änderungen.'
# Only known project paths; keep Git history and unrelated files intact.
tar -C "$ROOT" -cf - .github .gitignore Core UI tools tests LICENSE LICENSE-machidpi.txt \
  NOTICE.md PRIVACY.md README.md CHANGELOG.md RELEASE_NOTES.md ROADMAP.md VERSION \
  PUBLICATION.md build.command publish-github.command publish-update.command | tar -xf -

git add -A
if git diff --cached --quiet; then
  echo 'Keine Quellcodeänderungen gegenüber GitHub; kein neuer Tag erstellt.'
  exit 0
fi
USER_ID="$(gh api user --jq .id)"
git config user.name 'MrNoooooooob'
git config user.email "${USER_ID}+MrNoooooooob@users.noreply.github.com"
git commit -m "Release $TAG: Mac Display Control"

echo "GitHub-Änderungen für $REPO / $TAG bereit."
read -r -p "Commit und NEUEN Tag veröffentlichen? [ja/NEIN] " ANSWER
[[ "$ANSWER" == ja ]] || { echo 'Abgebrochen, keine Änderungen auf GitHub.'; exit 0; }
git push origin main
git tag -a "$TAG" -m "Mac Display Control $VERSION"
git push origin "$TAG"
echo "Quellcode: https://github.com/$REPO/tree/$TAG"
echo "GitHub Actions baut automatisch die .app: https://github.com/$REPO/actions"
echo "Release nach erfolgreichem Build: https://github.com/$REPO/releases/tag/$TAG"
echo "Alternative falls Runner hängen: bash publish-update.command --local-release"
