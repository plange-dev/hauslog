#!/usr/bin/env bash
# Baut aus dem Flutter-Linux-Build ein AppImage.
# Voraussetzung: `flutter build linux --release` ist gelaufen.
# GTK 3 wird nicht eingepackt; es ist auf praktisch jedem Linux-Desktop
# vorhanden. SQLite liegt bereits im Flutter-Bundle (lib/).
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(awk '/^version:/{split($2, v, "+"); print v[1]}' pubspec.yaml)
bundle=build/linux/x64/release/bundle
appdir=build/AppDir
ziel="Hauslog-$version-x86_64.AppImage"

rm -rf "$appdir"
mkdir -p "$appdir"
cp -r "$bundle"/. "$appdir"/
cp packaging/linux/hauslog.desktop "$appdir"/de.paddy911.hauslog.desktop
cp web/icons/Icon-512.png "$appdir"/hauslog.png
cat > "$appdir"/AppRun <<'EOF'
#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/hauslog" "$@"
EOF
chmod +x "$appdir"/AppRun

if [ ! -x build/appimagetool ]; then
  curl -fsSL -o build/appimagetool \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x build/appimagetool
fi
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 build/appimagetool "$appdir" "build/$ziel"
echo "build/$ziel"
