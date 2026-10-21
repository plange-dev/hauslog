"""Einstellungen: Server-Anmeldung, Export, Import."""

from pathlib import Path

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QDialog,
    QDialogButtonBox,
    QFileDialog,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QStackedWidget,
    QVBoxLayout,
    QWidget,
)

from ..alt_import import alt_daten_importieren, alt_datenbank_lesen, alt_ordner
from ..daten import Datenbank
from ..export import csv_erzeugen, xlsx_erzeugen
from ..formate import zeit_anzeige
from ..sync_steuerung import SyncSteuerung, SyncZustand


class EinstellungenDialog(QDialog):
    def __init__(self, db: Datenbank, sync: SyncSteuerung, eltern: QWidget):
        super().__init__(eltern)
        self._db = db
        self._sync = sync
        self.setWindowTitle("Einstellungen")
        self.setMinimumWidth(560)

        layout = QVBoxLayout(self)
        layout.addWidget(self._server_bereich())
        layout.addWidget(self._daten_bereich())
        schliessen = QDialogButtonBox(QDialogButtonBox.StandardButton.Close)
        schliessen.button(QDialogButtonBox.StandardButton.Close).setText("Schließen")
        schliessen.rejected.connect(self.reject)
        layout.addWidget(schliessen)

        sync.zustand_geaendert.connect(self._zustand_anzeigen)
        sync.anmeldung_fertig.connect(self._anmeldung_fertig)
        db.beobachten(self._db_geaendert)
        self._zustand_anzeigen(sync.zustand)

    def _db_geaendert(self) -> None:
        self._zustand_anzeigen(self._sync.zustand)

    def done(self, ergebnis: int) -> None:
        # Verbindungen lösen, sonst rufen Signale den geschlossenen Dialog auf.
        self._sync.zustand_geaendert.disconnect(self._zustand_anzeigen)
        self._sync.anmeldung_fertig.disconnect(self._anmeldung_fertig)
        self._db.nicht_mehr_beobachten(self._db_geaendert)
        super().done(ergebnis)

    # ── Server ──────────────────────────────────────────────────────────────

    def _server_bereich(self) -> QGroupBox:
        gruppe = QGroupBox("Gemeinsame Daten")
        self._seiten = QStackedWidget()

        # Abgemeldet
        abgemeldet = QWidget()
        hinweis = QLabel(
            "Ohne Anmeldung speichert Hauslog nur auf diesem Gerät. Mit einem "
            "Hauslog-Server (z. B. auf NAS oder Raspberry Pi) teilen alle Benutzer "
            "dieselben Zähler – auch offline erfasste Werte werden später abgeglichen."
        )
        hinweis.setWordWrap(True)
        self.url = QLineEdit(self._sync.zustand.server_url)
        self.url.setPlaceholderText("http://raspberrypi.local:8090")
        self.email = QLineEdit()
        self.passwort = QLineEdit(echoMode=QLineEdit.EchoMode.Password)
        self.passwort.returnPressed.connect(self._anmelden)
        self.anmelden_knopf = QPushButton("Anmelden")
        self.anmelden_knopf.clicked.connect(self._anmelden)
        form = QFormLayout(abgemeldet)
        form.addRow(hinweis)
        form.addRow("Server-Adresse", self.url)
        form.addRow("E-Mail", self.email)
        form.addRow("Passwort", self.passwort)
        form.addRow("", self.anmelden_knopf)

        # Angemeldet
        angemeldet = QWidget()
        self.info = QLabel()
        self.info.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        self.fehler = QLabel()
        self.fehler.setStyleSheet("color: #c0392b")
        self.fehler.setWordWrap(True)
        self.abgleichen_knopf = QPushButton("Jetzt abgleichen")
        self.abgleichen_knopf.clicked.connect(self._sync.jetzt_abgleichen)
        abmelden = QPushButton("Abmelden")
        abmelden.clicked.connect(self._sync.abmelden)
        knoepfe = QHBoxLayout()
        knoepfe.addWidget(self.abgleichen_knopf)
        knoepfe.addWidget(abmelden)
        knoepfe.addStretch()
        spalte = QVBoxLayout(angemeldet)
        spalte.addWidget(self.info)
        spalte.addWidget(self.fehler)
        spalte.addLayout(knoepfe)

        self._seiten.addWidget(abgemeldet)
        self._seiten.addWidget(angemeldet)
        QVBoxLayout(gruppe).addWidget(self._seiten)
        return gruppe

    def _zustand_anzeigen(self, z: SyncZustand) -> None:
        self._seiten.setCurrentIndex(1 if z.angemeldet else 0)
        letzter = zeit_anzeige(z.letzter_erfolg) if z.letzter_erfolg else "–"
        self.info.setText(
            f"<table cellspacing=4>"
            f"<tr><td>Server</td><td>{z.server_url}</td></tr>"
            f"<tr><td>Angemeldet als</td><td>{z.benutzer or ''}</td></tr>"
            f"<tr><td>Letzter Abgleich</td><td>{letzter}</td></tr>"
            f"<tr><td>Noch nicht gesendet</td>"
            f"<td>{self._db.anzahl_ungesendet()} Änderungen</td></tr></table>"
        )
        self.fehler.setText(z.fehler or "")
        self.fehler.setVisible(bool(z.fehler))
        self.abgleichen_knopf.setEnabled(not z.laeuft)

    def _anmelden(self) -> None:
        self.anmelden_knopf.setEnabled(False)
        self.anmelden_knopf.setText("Melde an …")
        self._sync.anmelden(self.url.text(), self.email.text(), self.passwort.text())

    def _anmeldung_fertig(self, fehler: str | None) -> None:
        self.anmelden_knopf.setEnabled(True)
        self.anmelden_knopf.setText("Anmelden")
        if fehler:
            QMessageBox.warning(self, "Anmeldung fehlgeschlagen", fehler)
        else:
            self.passwort.clear()

    # ── Export / Import ─────────────────────────────────────────────────────

    def _daten_bereich(self) -> QGroupBox:
        gruppe = QGroupBox("Daten")
        csv = QPushButton("Als CSV exportieren…")
        csv.clicked.connect(lambda: self._exportieren("csv"))
        xlsx = QPushButton("Als Excel exportieren…")
        xlsx.clicked.connect(lambda: self._exportieren("xlsx"))
        importieren = QPushButton("Alte Verbrauchsmanager-Datenbank importieren…")
        importieren.clicked.connect(self._importieren)
        pfad = QLabel(f"Lokale Daten: {self._db.pfad}")
        pfad.setWordWrap(True)
        pfad.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        pfad.setStyleSheet("color: palette(placeholder-text)")

        zeile = QHBoxLayout()
        zeile.addWidget(csv)
        zeile.addWidget(xlsx)
        zeile.addStretch()
        spalte = QVBoxLayout(gruppe)
        spalte.addLayout(zeile)
        spalte.addWidget(importieren, alignment=Qt.AlignmentFlag.AlignLeft)
        spalte.addWidget(pfad)
        return gruppe

    def _exportieren(self, endung: str) -> None:
        typ = "CSV-Datei (*.csv)" if endung == "csv" else "Excel-Datei (*.xlsx)"
        ziel, _ = QFileDialog.getSaveFileName(
            self, "Exportieren", str(Path.home() / f"hauslog.{endung}"), typ
        )
        if not ziel:
            return
        if not ziel.lower().endswith(f".{endung}"):
            ziel += f".{endung}"
        erzeugen = csv_erzeugen if endung == "csv" else xlsx_erzeugen
        try:
            Path(ziel).write_bytes(
                erzeugen(self._db.alle_zaehler(), self._db.alle_ablesungen())
            )
        except OSError as e:
            QMessageBox.warning(self, "Export fehlgeschlagen", str(e))
            return
        QMessageBox.information(self, "Exportiert", f"Gespeichert unter:\n{ziel}")

    def _importieren(self) -> None:
        start = alt_ordner() or Path.home()
        quelle, _ = QFileDialog.getOpenFileName(
            self, "Alte Datenbank öffnen", str(start), "SQLite-Datenbank (*.db *.sqlite)"
        )
        if not quelle:
            return
        try:
            eintraege = alt_datenbank_lesen(quelle)
        except Exception as e:  # noqa: BLE001 – beschädigte oder fremde Datei
            QMessageBox.warning(self, "Import fehlgeschlagen", str(e))
            return
        if not eintraege:
            QMessageBox.information(
                self,
                "Nichts gefunden",
                "Die Datei enthält keine Verbrauchsmanager-Daten.",
            )
            return
        antwort = QMessageBox.question(
            self,
            "Importieren?",
            f"{len(eintraege)} Einträge werden als Ablesungen übernommen. Dafür werden "
            "neue Zähler „Strom“, „Wasser“ und „Gas“ angelegt.\n\n"
            "Mehrfaches Importieren legt die Daten mehrfach an.",
        )
        if antwort == QMessageBox.StandardButton.Yes:
            anzahl = alt_daten_importieren(self._db, eintraege)
            QMessageBox.information(
                self, "Importiert", f"{anzahl} Ablesungen importiert."
            )
