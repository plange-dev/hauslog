# Hauslog

Zählerstände erfassen und auswerten – Strom, Wasser, Gas, Wärme, Heizöl,
PV-Einspeisung und beliebig viele weitere Zähler.

- **Offline zuerst:** Alles wird lokal gespeichert (SQLite über Drift). Die App
  funktioniert ohne Netz.
- **Gemeinsam:** Mit einem Hauslog-Server (PocketBase auf NAS, Raspberry Pi
  oder in der Cloud) sehen alle Benutzer dieselben Daten. Offline erfasste
  Werte werden beim nächsten Kontakt abgeglichen; Änderungen anderer erscheinen
  sofort.
- **Plattformen:** Windows, Linux (AppImage), Web.
- **Auswertung:** Verbrauch je Ablesungszeitraum, Jahresverbrauch (anteilig
  über Jahresgrenzen), Ø pro Tag, Diagramm, Export als CSV und Excel.
- **Umstieg:** Daten des alten Verbrauchsmanagers lassen sich unter
  *Einstellungen → Alte Verbrauchsmanager-Datenbank importieren* übernehmen.

## Aufbau

```
lib/
  daten/       Drift-Tabellen (zaehler, ablesungen) und Abfragen
  logik/       Verbrauchsberechnung (reines Dart, getestet)
  sync/        Abgleich mit PocketBase und automatische Steuerung
  ui/          Oberfläche
  export/      CSV/XLSX
  import/      Übernahme aus dem alten Verbrauchsmanager
  plattform/   Desktop- bzw. Web-spezifisches (Dateien speichern, Import)
server/        PocketBase-Schema (pb_migrations), Docker, systemd
packaging/     AppImage
```

### Wie der Abgleich funktioniert

Jeder Datensatz hat eine von der App vergebene ID, einen Änderungszeitpunkt
`geaendert_am` und ein Lösch-Kennzeichen. Lokale Änderungen werden als
„ungesendet“ markiert. Beim Abgleich:

1. Ungesendete Datensätze werden zum Server geschickt. Liegt dort eine neuere
   Änderung, gewinnt diese.
2. Alles, was sich auf dem Server seit dem letzten Abruf geändert hat, wird
   geholt. Lokal neuere, noch nicht gesendete Änderungen bleiben erhalten.

Bei Konflikten gewinnt also die zuletzt gemachte Änderung. Voraussetzung ist,
dass die Uhren der Geräte ungefähr stimmen.

Abgeglichen wird beim Start, alle 2 Minuten, wenige Sekunden nach jeder
lokalen Änderung und sofort, wenn ein anderer Benutzer etwas ändert.

## Entwicklung

Voraussetzungen: [Flutter](https://docs.flutter.dev/get-started/install)
3.47 oder neuer. Für Windows-Builds zusätzlich Visual Studio 2022 mit
„Desktopentwicklung mit C++“ und der Windows-Entwicklermodus
(`start ms-settings:developers`). Für Linux-Builds:
`clang cmake ninja-build pkg-config libgtk-3-dev`.

```bash
flutter pub get
flutter run -d windows      # oder: -d linux

# Web: einmalig (und nach drift-Updates) die Worker-Dateien laden
bash tool/web_dateien.sh
flutter run -d chrome

# Nach Änderungen an lib/daten/datenbank.dart
dart run build_runner build

# Tests (Sync-Tests laufen nur mit Server, siehe test/sync_test.dart)
flutter test
```

## Server einrichten

Der Server ist [PocketBase](https://pocketbase.io) – ein einzelnes Programm
mit eingebauter Datenbank, Benutzerverwaltung und Admin-Oberfläche. Das
Hauslog-Schema liegt in `server/pb_migrations` und wird beim Start automatisch
angelegt.

### Mit Docker (NAS, Raspberry Pi, Server)

```bash
cd server
docker compose up -d --build
docker compose exec hauslog /pb/pocketbase superuser upsert admin@example.com EIN-SICHERES-PASSWORT --dir=/pb/pb_data
```

### Ohne Docker (z. B. Raspberry Pi OS)

PocketBase für die passende Architektur von
<https://github.com/pocketbase/pocketbase/releases> laden (Pi 3/4/5 mit 64-Bit:
`linux_arm64`), dann:

```bash
sudo useradd --system --home /opt/hauslog hauslog
sudo mkdir -p /opt/hauslog && sudo unzip pocketbase_*_linux_arm64.zip pocketbase -d /opt/hauslog
sudo cp -r server/pb_migrations /opt/hauslog/
sudo chown -R hauslog:hauslog /opt/hauslog
sudo -u hauslog /opt/hauslog/pocketbase superuser upsert admin@example.com EIN-SICHERES-PASSWORT --dir=/opt/hauslog/pb_data
sudo cp server/hauslog-server.service /etc/systemd/system/
sudo systemctl enable --now hauslog-server
```

### Benutzer anlegen

Selbstregistrierung ist gesperrt, weil jeder Benutzer alle Daten sieht.
Benutzer legt der Admin an: `http://<server>:8090/_/` öffnen →
*Collections → users → New record* (E-Mail und Passwort).

In der App: *Einstellungen → Gemeinsame Daten*, Server-Adresse
(z. B. `http://raspberrypi.local:8090`), E-Mail und Passwort eingeben.

### Web-Version

Den Inhalt von `Hauslog-…-web.zip` (oder `build/web`) nach
`server/pb_public` bzw. `/opt/hauslog/pb_public` kopieren. Die Web-Version ist
dann unter `http://<server>:8090/` erreichbar und nutzt automatisch denselben
Server.

### Sicherung

Alles liegt in `pb_data`. Dieses Verzeichnis regelmäßig sichern, oder in der
PocketBase-Oberfläche unter *Settings → Backups* automatische Sicherungen
einrichten.

### Zugriff von unterwegs

Im Heimnetz genügt `http://`. Für Zugriff aus dem Internet einen Reverse-Proxy
mit HTTPS (z. B. Caddy, oder Reverse Proxy des NAS) oder ein VPN wie
Tailscale/WireGuard verwenden. PocketBase **nicht** ohne HTTPS ins Internet
stellen.

## Releases

Ein Tag `v*` (z. B. `git tag v0.2.0 && git push --tags`) baut per GitHub
Actions automatisch:

- `Hauslog-<version>-windows-x64.zip`
- `Hauslog-<version>-x86_64.AppImage`
- `Hauslog-<version>-web.zip`

und hängt sie an ein GitHub-Release. Jeder Push auf `main` und jeder Pull
Request baut und testet ebenfalls; die Dateien liegen dann als Artefakte am
Workflow-Lauf.
