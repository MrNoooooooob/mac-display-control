#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
REPO="MrNoooooooob/mac-display-control"
ACTION="${1:-publish}"
VERSION="$(tr -d '\r\n[:space:]' < VERSION)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9][a-zA-Z0-9.-]*)?$ ]] || { echo "Invalid VERSION" >&2; exit 1; }
TAG="v$VERSION"
ZIP="Mac-Display-Control-$TAG-macOS-arm64.zip"
if [[ "$ACTION" == --help ]]; then
  echo 'Usage: bash publish-update.command [--status|--retry-ci|--local-release]'
  exit 0
fi
for c in gh git python3; do command -v "$c" >/dev/null || { echo "Missing $c" >&2; exit 1; }; done
gh auth status >/dev/null 2>&1 || { echo 'Run gh auth login' >&2; exit 1; }
[[ "$(gh api user --jq .login)" == MrNoooooooob ]] || { echo 'Wrong GitHub login' >&2; exit 1; }
gh repo view "$REPO" >/dev/null || exit 1
tag_exists(){ gh api "repos/$REPO/git/ref/tags/$TAG" >/dev/null 2>&1; }
release_exists(){ gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; }
case "$ACTION" in
--status)
  echo "Version $VERSION"; gh run list --repo "$REPO" --workflow build.yml --limit 5 || true
  if release_exists; then gh release view "$TAG" --repo "$REPO" --json url,assets --jq '{url,assets:[.assets[].name]}'; else echo 'No release asset yet'; fi
  exit 0 ;;
--retry-ci)
  tag_exists || { echo "Unknown tag $TAG" >&2; exit 1; }
  gh workflow run build.yml --repo "$REPO" --ref "$TAG"
  exit 0 ;;
--local-release)
  tag_exists || { echo "Unknown tag $TAG" >&2; exit 1; }
  [[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || { echo 'Requires Apple Silicon Mac' >&2; exit 1; }
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  gh repo clone "$REPO" "$TMP/repo" -- --depth 1 --branch "$TAG"
  cd "$TMP/repo"
  [[ "$(tr -d '\r\n[:space:]' < VERSION)" == "$VERSION" ]] || exit 1
  bash build.command
  [[ -x 'Mac Display Control.app/Contents/MacOS/MacDisplayControl' ]] || { echo 'App binary missing' >&2; exit 1; }
  ditto -c -k --keepParent 'Mac Display Control.app' "$ZIP"
  read -r -p "Upload finished app to $TAG? Enter ja: " CONFIRM
  [[ "$CONFIRM" == ja ]] || exit 0
  if release_exists; then
    gh release upload "$TAG" "$ZIP" --repo "$REPO" --clobber
    gh release edit "$TAG" --repo "$REPO" --notes-file RELEASE_NOTES.md
  else
    if [[ "$VERSION" == *-* ]]; then PRE=(--prerelease); else PRE=(); fi
    gh release create "$TAG" "$ZIP" --repo "$REPO" --verify-tag --title "Mac Display Control $VERSION" --notes-file RELEASE_NOTES.md "${PRE[@]}"
  fi
  echo "Release: https://github.com/$REPO/releases/tag/$TAG"
  exit 0 ;;
publish) ;;
*) echo 'Invalid action' >&2; exit 2 ;;
esac
if tag_exists; then echo "$TAG already exists. Use --local-release for a missing app ZIP."; exit 0; fi
python3 tests/test_patch.py
bash -n build.command
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
gh repo clone "$REPO" "$TMP/repo" -- --branch main --single-branch
cd "$TMP/repo"
tar -C "$ROOT" -cf - .github .gitignore Core UI tools tests LICENSE LICENSE-machidpi.txt NOTICE.md PRIVACY.md README.md CHANGELOG.md RELEASE_NOTES.md ROADMAP.md VERSION PUBLICATION.md build.command publish-github.command publish-update.command | tar -xf -
git add -A
git diff --cached --quiet && { echo 'No changes'; exit 0; }
USER_ID="$(gh api user --jq .id)"
git config user.name MrNoooooooob
git config user.email "${USER_ID}+MrNoooooooob@users.noreply.github.com"
git commit -m "Release $TAG"
read -r -p "Publish $TAG to GitHub? Enter ja: " CONFIRM
[[ "$CONFIRM" == ja ]] || exit 0
git push origin main
git tag -a "$TAG" -m "Mac Display Control $VERSION"
git push origin "$TAG"
echo "GitHub builds the app: https://github.com/$REPO/actions"
echo "Release: https://github.com/$REPO/releases/tag/$TAG"
