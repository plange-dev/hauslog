#!/usr/bin/env bash
# Lädt sqlite3.wasm und drift_worker.js für die Web-Version nach web/.
# Die Version richtet sich nach dem in pubspec.lock gesperrten drift-Paket.
# Nach jedem drift-Update erneut ausführen.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(awk '/^  drift:/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
basis="https://github.com/simolus3/drift/releases/download/drift-$version"

echo "drift $version"
curl -fsSL -o web/sqlite3.wasm "$basis/sqlite3.wasm"
curl -fsSL -o web/drift_worker.js "$basis/drift_worker.js"
echo "web/sqlite3.wasm und web/drift_worker.js aktualisiert."
