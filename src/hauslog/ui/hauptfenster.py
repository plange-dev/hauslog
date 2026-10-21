"""Hauptfenster: Zählerliste links, Details rechts."""

from datetime import date

from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QAction, QColor, QFont, QIcon, QPainter, QPixmap
from PySide6.QtWidgets import (
    QLabel,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QSizePolicy,
    QSplitter,
    QStackedWidget,
    QToolButton,
    QVBoxLayout,
    QWidget,
)

from ..daten import Ablesung, Datenbank
from ..formate import datum_anzeige, mit_einheit, zeit_anzeige
from ..sync_steuerung import SyncSteuerung, SyncZustand
from ..zaehler_art import ZaehlerArt
from .dialoge import ZaehlerDialog
from .einstellungen import EinstellungenDialog
from .zaehler_detail import Kennzahlen, ZaehlerDetail


def _symbol(art: ZaehlerArt, groesse: int = 36) -> QIcon:
    """Farbiger Kreis mit dem Symbol der Zählerart."""
    bild = QPixmap(groesse, groesse)
    bild.fill(Qt.GlobalColor.transparent)
    p = QPainter(bild)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    farbe = QColor(art.farbe)
    farbe.setAlpha(60)
    p.setBrush(farbe)
    p.setPen(Qt.PenStyle.NoPen)
    p.drawEllipse(0, 0, groesse, groesse)
    schrift = QFont()
    schrift.setPixelSize(groesse // 2)
    p.setFont(schrift)
    p.setPen(QColor(art.farbe))
    p.drawText(bild.rect(), Qt.AlignmentFlag.AlignCenter, art.symbol)
    p.end()
    return QIcon(bild)


class Hauptfenster(QMainWindow):
    def __init__(self, db: Datenbank, sync: SyncSteuerung):
        super().__init__()
        self._db = db
        self._sync = sync
        self.setWindowTitle("Hauslog")
        self.resize(1200, 760)

        # Werkzeugleiste
        leiste = self.addToolBar("Aktionen")
        leiste.setMovable(False)
        leiste.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonTextOnly)
        neuer_zaehler = QAction("＋ Zähler", self)
        neuer_zaehler.setShortcut("Ctrl+N")
        neuer_zaehler.triggered.connect(self.zaehler_anlegen)
        self.ablesung = QAction("＋ Ablesung", self)
        self.ablesung.setShortcut("Ctrl+E")
        self.ablesung.triggered.connect(lambda: self.detail.ablesung_erfassen())
        einstellungen = QAction("Einstellungen", self)
        einstellungen.triggered.connect(self.einstellungen_oeffnen)
        leiste.addAction(neuer_zaehler)
        leiste.addAction(self.ablesung)
        abstand = QWidget()
        abstand.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)
        leiste.addWidget(abstand)
        self.sync_knopf = QToolButton()
        self.sync_knopf.clicked.connect(self._sync_knopf_geklickt)
        leiste.addWidget(self.sync_knopf)
        leiste.addAction(einstellungen)

        # Liste und Details
        self.liste = QListWidget()
        self.liste.setIconSize(QSize(36, 36))
        self.liste.setSpacing(2)
        self.liste.setMinimumWidth(280)
        self.liste.currentItemChanged.connect(self._auswahl_geaendert)

        self.detail = ZaehlerDetail(db)
        leer = QWidget()
        leer_layout = QVBoxLayout(leer)
        self.leer_text = QLabel()
        self.leer_text.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.leer_text.setStyleSheet("color: palette(placeholder-text); font-size: 13pt")
        leer_layout.addWidget(self.leer_text)
        self.rechts = QStackedWidget()
        self.rechts.addWidget(leer)
        self.rechts.addWidget(self.detail)

        teiler = QSplitter()
        teiler.addWidget(self.liste)
        teiler.addWidget(self.rechts)
        teiler.setStretchFactor(1, 1)
        teiler.setSizes([320, 880])
        self.setCentralWidget(teiler)

        self.status = QLabel()
        self.statusBar().addPermanentWidget(self.status)

        db.beobachten(self._lokal_geaendert)
        sync.daten_empfangen.connect(self.neu_laden)
        sync.zustand_geaendert.connect(self._sync_anzeigen)
        self.neu_laden()
        self._sync_anzeigen(sync.zustand)

    # ── Daten ───────────────────────────────────────────────────────────────

    def _lokal_geaendert(self) -> None:
        # Nach dem aktuellen Ereignis neu laden (Dialoge sind dann geschlossen).
        self._sync_anzeigen(self._sync.zustand)
        self.neu_laden()

    def neu_laden(self) -> None:
        gewaehlt = self.liste.currentItem()
        gewaehlt_id = gewaehlt.data(Qt.ItemDataRole.UserRole) if gewaehlt else None

        pro_zaehler: dict[str, list[Ablesung]] = {}
        for a in self._db.alle_ablesungen():
            pro_zaehler.setdefault(a.zaehler_id, []).append(a)

        self.liste.blockSignals(True)
        self.liste.clear()
        jahr = date.today().year
        for z in self._db.alle_zaehler():
            art = ZaehlerArt.aus_schluessel(z.art)
            k = Kennzahlen(pro_zaehler.get(z.id, []))
            if k.letzte:
                stand = mit_einheit(k.letzte.stand, z.einheit)
                zeile2 = f"{stand} · {datum_anzeige(k.letzte.datum)}"
                if k.abschnitte:
                    zeile2 += f"\n{jahr}: {mit_einheit(k.im_jahr(jahr), z.einheit)}"
            else:
                zeile2 = "Noch keine Ablesung"
            eintrag = QListWidgetItem(_symbol(art), f"{z.name}\n{zeile2}")
            eintrag.setData(Qt.ItemDataRole.UserRole, z.id)
            self.liste.addItem(eintrag)
            if z.id == gewaehlt_id:
                self.liste.setCurrentItem(eintrag)
        self.liste.blockSignals(False)

        if self.liste.count() and not self.liste.currentItem():
            self.liste.setCurrentRow(0)
        self._auswahl_geaendert()

    def _auswahl_geaendert(self) -> None:
        eintrag = self.liste.currentItem()
        zaehler = (
            self._db.zaehler(eintrag.data(Qt.ItemDataRole.UserRole)) if eintrag else None
        )
        self.ablesung.setEnabled(zaehler is not None)
        if zaehler is None:
            self.leer_text.setText(
                "Noch keine Zähler angelegt.\n\nMit „＋ Zähler“ (Strg+N) geht es los."
                if self.liste.count() == 0
                else "Zähler links auswählen."
            )
            self.rechts.setCurrentIndex(0)
            return
        self.detail.anzeigen(zaehler)
        self.rechts.setCurrentIndex(1)

    def zaehler_anlegen(self) -> None:
        dialog = ZaehlerDialog(self._db, self)
        if dialog.exec():
            for i in range(self.liste.count()):
                if self.liste.item(i).data(Qt.ItemDataRole.UserRole) == dialog.zaehler_id:
                    self.liste.setCurrentRow(i)

    def einstellungen_oeffnen(self) -> None:
        EinstellungenDialog(self._db, self._sync, self).exec()

    # ── Sync-Anzeige ────────────────────────────────────────────────────────

    def _sync_anzeigen(self, z: SyncZustand) -> None:
        ungesendet = self._db.anzahl_ungesendet()
        if not z.angemeldet:
            text, tipp = (
                "☁ Nur lokal",
                "Nur auf diesem Gerät gespeichert – Server unter Einstellungen",
            )
        elif z.laeuft:
            text, tipp = "⟳ Gleiche ab …", ""
        elif z.fehler:
            text, tipp = "⚠ Offline", z.fehler
        elif ungesendet:
            text, tipp = f"⇡ {ungesendet} ausstehend", "Änderungen warten auf Abgleich"
        elif z.letzter_erfolg:
            text, tipp = "✓ Abgeglichen", f"Zuletzt {zeit_anzeige(z.letzter_erfolg)}"
        else:
            text, tipp = "☁ Verbunden", ""
        self.sync_knopf.setText(text)
        self.sync_knopf.setToolTip(
            tipp + ("\nKlicken zum Abgleichen" if z.angemeldet else "")
        )
        self.status.setText(tipp)

    def _sync_knopf_geklickt(self) -> None:
        if self._sync.zustand.angemeldet:
            self._sync.jetzt_abgleichen()
        else:
            self.einstellungen_oeffnen()
