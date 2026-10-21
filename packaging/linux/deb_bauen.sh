#!/usr/bin/env bash
# Baut ein .deb-Paket für Ubuntu (22.04 und neuer) aus dem PyInstaller-Ergebnis.
# Voraussetzung: pyinstaller --distpath build/dist packaging/hauslog.spec
# Installation: sudo apt install ./build/hauslog_<version>_amd64.deb
set -euo pipefail
cd "$(dirname "$0")/../.."

version=$(sed -n 's/^__version__ = "\(.*\)"/\1/p' src/hauslog/__init__.py)
paket="build/deb/hauslog_${version}_amd64"

rm -rf "$paket"
mkdir -p "$paket/DEBIAN" "$paket/opt" "$paket/usr/bin" \
  "$paket/usr/share/applications" "$paket/usr/share/icons/hicolor/256x256/apps"
cp -r build/dist/hauslog "$paket/opt/hauslog"
ln -s /opt/hauslog/hauslog "$paket/usr/bin/hauslog"
cp packaging/linux/hauslog.desktop "$paket/usr/share/applications/"
cp src/hauslog/hauslog.png "$paket/usr/share/icons/hicolor/256x256/apps/"

# Qt bringt seine Bibliotheken mit; vom System braucht es Grafik- und
# X11/Wayland-Anbindung.
cat > "$paket/DEBIAN/control" <<EOF
Package: hauslog
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: paddy911 <paddy911@gmx.de>
Installed-Size: $(du -sk "$paket" | cut -f1)
Depends: libc6 (>= 2.35), libegl1, libgl1, libfontconfig1, libfreetype6, libdbus-1-3, libxkbcommon0, libxkbcommon-x11-0, libxcb-cursor0, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-xinerama0, libxcb-xkb1, libwayland-client0, libwayland-cursor0, libwayland-egl1
Homepage: https://github.com/plange-dev/hauslog
Description: Zählerstände erfassen – offline und gemeinsam
 Hauslog erfasst Strom-, Wasser-, Gas- und weitere Zählerstände, berechnet
 den Verbrauch und gleicht die Daten optional über einen eigenen
 Hauslog-Server (PocketBase) zwischen mehreren Benutzern ab.
EOF

dpkg-deb --build --root-owner-group "$paket" "build/hauslog_${version}_amd64.deb"
echo "build/hauslog_${version}_amd64.deb"
