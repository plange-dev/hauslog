# Hauslog

Zählerstände erfassen und auswerten – Strom, Wasser, Gas, Wärme, Heizöl,
PV-Einspeisung und beliebig viele weitere Zähler. Desktop-App für
**Windows** (Installer) und **Ubuntu** (.deb), geschrieben in Python mit Qt
(PySide6).

- **Offline zuerst:** Alles wird lokal in SQLite gespeichert. Die App
  funktioniert ohne Netz.
- **Gemeinsam:** Mit einem Hauslog-Server (PocketBase auf NAS, Raspberry Pi
  oder in der Cloud) sehen alle Benutzer dieselben Daten. Offline erfasste
  Werte werden beim nächsten Kontakt abgeglichen; Änderungen anderer erscheinen
  sofort.
- **Auswertung:** Verbrauch je Ablesungszeitraum, Jahresverbrauch (anteilig
  über Jahresgrenzen), Ø pro Tag, Diagramm, Export als CSV und Excel.
- **Umstieg:** Daten des alten Verbrauchsmanagers lassen sich unter
  *Einstellungen → Alte Verbrauchsmanager-Datenbank importieren* übernehmen.

## Installation

Die fertigen Pakete hängen an jedem
[Release](https://github.com/plange-dev/hauslog/releases) (und als Artefakte an
jedem Lauf unter *Actions*).

**Windows 10/11:** `Hauslog-<version>-Setup.exe` ausführen. Keine
Administratorrechte nötig; installiert nach
`%LOCALAPPDATA%\Programs\Hauslog`, mit Eintrag im Startmenü.

**Ubuntu 22.04 und neuer:**

```bash
sudo apt install ./hauslog_<version>_amd64.deb
hauslog   # oder über das Anwendungsmenü
```

Daten liegen unter `%LOCALAPPDATA%\Hauslog` (Windows) bzw.
`~/.local/share/hauslog` (Linux) und bleiben beim Deinstallieren erhalten.

## Aufbau

```
src/hauslog/
  daten.py           lokale SQLite-Datenbank (zaehler, ablesungen)
  verbrauch.py       Verbrauchsberechnung
  pocketbase.py      kleiner PocketBase-Client inkl. Realtime
  sync.py            Abgleich (reines Python, getestet gegen echten Server)
  sync_steuerung.py  Abgleich im Hintergrund-Thread, Zeitsteuerung
  export.py          CSV/XLSX
  alt_import.py      Übernahme aus dem alten Verbrauchsmanager
  ui/                Oberfläche (Qt Widgets)
server/              PocketBase-Schema (pb_migrations), Docker, systemd
packaging/           PyInstaller, Windows-Installer (Inno Setup), .deb
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

Python 3.11 oder neuer.

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate    Linux: source .venv/bin/activate
pip install -e ".[dev]"

python -m hauslog          # App starten
pytest                     # Tests (Sync-Tests nur mit Server, siehe tests/test_sync.py)
ruff check src tests && ruff format src tests
```

Pakete lokal bauen:

```bash
pyinstaller --noconfirm --distpath build/dist --workpath build/work packaging/hauslog.spec
# Windows (Inno Setup 6 installiert):
iscc /DAppVersion=0.3.0 packaging\windows\hauslog.iss
# Ubuntu:
bash packaging/linux/deb_bauen.sh
```

Das App-Symbol erzeugt `python tools/symbol_erzeugen.py`.

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

Ein Tag `v*` (z. B. `git tag v0.3.0 && git push --tags`) baut per GitHub
Actions automatisch `Hauslog-<version>-Setup.exe` und
`hauslog_<version>_amd64.deb`, testet beide (installieren und starten) und
hängt sie an ein GitHub-Release. Die Version steht in
`src/hauslog/__init__.py`.
