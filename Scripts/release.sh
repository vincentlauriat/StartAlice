#!/usr/bin/env bash
# Build a Release StartAlice.app, Developer ID sign with Hardened Runtime,
# notarize via Apple, staple the ticket, and package it as a distributable .dmg.
#
# Inspiré de ~/DevApps/MarkdownViewer/Scripts/release.sh, sans Sparkle ni
# extension QuickLook (StartAlice n'a ni auto-update ni appex).
#
# Usage: ./Scripts/release.sh <version>       e.g. ./Scripts/release.sh 0.1.0
#
# Prérequis (one-time, voir ~/DevApps/CLAUDE.md « Apps macOS ») :
#   - Certificat "Developer ID Application: Vincent LAURIAT (KFLACS69T9)" dans le
#     trousseau de connexion.
#   - Profil notarytool partagé "AppliMacVincentGithub" :
#       xcrun notarytool store-credentials "AppliMacVincentGithub" \
#         --apple-id "vincent@lauriat.fr" --team-id "KFLACS69T9"
#
# Overrides :
#   SIGNING_IDENTITY="Developer ID Application: …"  ./Scripts/release.sh 0.1.0
#   NOTARY_PROFILE="AppliMacVincentGithub"          ./Scripts/release.sh 0.1.0
#
# Sort release/StartAlice-<version>.dmg, notarisé. Ne pousse pas sur GitHub —
# affiche la commande `gh release create` suggérée.

set -euo pipefail

VERSION="${1:?Usage: ./Scripts/release.sh <version>  (e.g. 0.1.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1. Sanity : project.yml doit déclarer la même MARKETING_VERSION
if ! grep -q "MARKETING_VERSION: \"$VERSION\"" project.yml; then
  echo "✗ MARKETING_VERSION dans project.yml ≠ $VERSION" >&2
  grep "MARKETING_VERSION" project.yml | sed 's/^/    /' >&2
  echo "  Bump project.yml d'abord, puis relance." >&2
  exit 1
fi

# 2. Icône : régénérer l'iconset si absent
ICONSET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"
if [ ! -f "$ICONSET/icon_512x512@2x.png" ]; then
  echo "→ Iconset absent, génération…"
  swift "$ROOT/Scripts/make-icon.swift" all "$ICONSET"
fi

# 3. Régénérer le xcodeproj
command -v xcodegen >/dev/null 2>&1 || { echo "✗ XcodeGen absent. brew install xcodegen" >&2; exit 1; }
echo "→ xcodegen generate"
xcodegen generate >/dev/null

# 4. Build Release. CODE_SIGNING_ALLOWED=NO contourne l'xattr
# com.apple.provenance de macOS qui casse le codesign en place ; on signe
# manuellement plus bas après un staging propre.
echo "→ xcodebuild Release"
xcodebuild -project StartAlice.xcodeproj \
  -scheme StartAlice \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tail -5

APP="$ROOT/build/Build/Products/Release/StartAlice.app"
[ -d "$APP" ] || { echo "✗ Build n'a pas produit $APP" >&2; exit 1; }

# 5. Staging propre (ditto --noextattr survit aux xattrs), sign Developer ID + Hardened Runtime.
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Vincent LAURIAT (KFLACS69T9)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AppliMacVincentGithub}"

STAGING_DIR="$(mktemp -d)"
STAGING="$STAGING_DIR/StartAlice.app"
echo "→ Staging vers $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

# timestamp.apple.com est parfois flaky → retry.
codesign_ts() {
  local target="$1" attempt
  for attempt in 1 2 3 4 5; do
    if codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target" 2>&1; then
      return 0
    fi
    [ "$attempt" -lt 5 ] && { echo "  ↻ codesign échec ($attempt/5), retry 5s…"; sleep 5; }
  done
  echo "✗ codesign $target échoué après 5 tentatives" >&2; return 1
}

echo "→ Codesign de l'app (Developer ID + Hardened Runtime)"
codesign_ts "$STAGING"
codesign --verify --strict --deep "$STAGING"

RELEASE_DIR="$ROOT/release"
mkdir -p "$RELEASE_DIR"
DMG="$RELEASE_DIR/StartAlice-$VERSION.dmg"
rm -f "$DMG"

# 5b. Layout installeur : app à gauche, alias /Applications à droite, flèche en fond.
DMG_VOLNAME="StartAlice $VERSION"
DMG_LAYOUT_DIR="$STAGING_DIR/dmg-layout"
mkdir -p "$DMG_LAYOUT_DIR/.background"
ditto --norsrc --noextattr --noacl "$STAGING" "$DMG_LAYOUT_DIR/StartAlice.app"
ln -s /Applications "$DMG_LAYOUT_DIR/Applications"
"$ROOT/Scripts/make-dmg-background.swift" "$DMG_LAYOUT_DIR/.background/background.png" >/dev/null

echo "→ DMG inscriptible pour configurer le layout Finder"
RW_DMG="$STAGING_DIR/temp.dmg"
hdiutil create -volname "$DMG_VOLNAME" -srcfolder "$DMG_LAYOUT_DIR" \
  -fs HFS+ -format UDRW -ov "$RW_DMG" >/dev/null

DMG_MOUNT=$(hdiutil attach -nobrowse -noverify -noautoopen "$RW_DMG" \
  | awk -F '\t' 'END {print $NF}')
echo "→ Monté sur $DMG_MOUNT — application du layout Finder"

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$DMG_VOLNAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 100, 740, 480}
        set view_options to the icon view options of container window
        set arrangement of view_options to not arranged
        set icon size of view_options to 128
        set background picture of view_options to file ".background:background.png"
        set position of item "StartAlice.app" of container window to {140, 200}
        set position of item "Applications" of container window to {400, 200}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DMG_MOUNT" -quiet

echo "→ Conversion en DMG compressé read-only $DMG"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null
rm -rf "$STAGING_DIR"

# 6. Notarisation + staple
echo "→ Soumission à Apple (2–5 min)…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "→ Staple du ticket"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

DMG_SIZE=$(ls -lh "$DMG" | awk '{print $5}')
echo ""
echo "✅ Signé, notarisé, staplé : $DMG ($DMG_SIZE)"
echo ""
echo "Vérif indépendante recommandée :"
echo "  spctl -a -t exec -vv \"$APP\""
echo "  xcrun stapler validate \"$DMG\""
echo ""
echo "Publier sur GitHub :"
echo "  gh release create v$VERSION \"$DMG\" --title \"v$VERSION\" --notes \"…\""
