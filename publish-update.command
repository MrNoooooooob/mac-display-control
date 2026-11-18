#!/bin/bash
# Publish v0.0.2-beta to an EXISTING MrNoooooooob/mac-display-control repo.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
OWNER=MrNoooooooob
REPO=mac-display-control
TARGET="$OWNER/$REPO"
TAG=v0.0.2-beta
for tool in gh git python3; do command -v "$tool" >/dev/null || { echo "Fehlendes Tool: $tool" >&2; exit 1; }; done
LOGIN=$(gh api user --jq .login)
[[ "$LOGIN" == "$OWNER" ]] || { echo "GitHub-Konto ist $LOGIN, erwartet $OWNER" >&2; exit 1; }
gh repo view "$TARGET" >/dev/null || { echo "Repository fehlt. Nutze publish-github.command für die Erstveröffentlichung." >&2; exit 1; }
[[ "$(gh repo view "$TARGET" --json visibility --jq .visibility)" == PUBLIC ]] || { echo "Repository ist nicht öffentlich; automatische Veröffentlichung abgebrochen." >&2; exit 1; }
if gh api "repos/$TARGET/git/ref/tags/$TAG" >/dev/null 2>&1; then
   echo "Tag $TAG existiert bereits. Kein Überschreiben." >&2; exit 1
fi
bash -n build.command
python3 tests/test_patch.py
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
gh repo clone "$TARGET" "$TMP/repo" -- --single-branch --branch main
cd "$TMP/repo"
[[ -z "$(git status --porcelain)" ]] || { echo "Unsaubere Kopie" >&2; exit 1; }
# Copy reviewed project sources while protecting the existing Git history.
# No destructive --delete or forced push.
tar -C "$ROOT" -cf - .github .gitignore Core UI tools tests LICENSE LICENSE-machidpi.txt NOTICE.md PRIVACY.md README.md CHANGELOG.md RELEASE_NOTES.md ROADMAP.md VERSION PUBLICATION.md build.command publish-github.command publish-update.command | tar -xf -
git add -A
if git diff --cached --quiet; then echo "Keine Änderungen"; exit 0; fi
GITHUB_ID=$(gh api user --jq .id)
git config user.name "$OWNER"
git config user.email "$GITHUB_ID+$OWNER@users.noreply.github.com"
git commit -m "Beta v0.0.2: 120 Hz safety policy and menu shortcut"
echo "Es wird ein Commit und der Beta-Tag $TAG auf GitHub veröffentlicht: $TARGET"
read -r -p "Zur Veröffentlichung 'ja' eingeben: " ANSWER
[[ "$ANSWER" == ja ]] || { echo "Abbruch"; exit 0; }
git push origin main
git tag -a "$TAG" -m "Mac Display Control v0.0.2-beta"
git push origin "$TAG"
echo "GitHub: https://github.com/$TARGET/releases/tag/$TAG (nach erfolgreichem CI-Build)"
