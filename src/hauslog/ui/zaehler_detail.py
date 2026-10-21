"""Detailansicht eines Zählers: Kennzahlen, Diagramm, Ablesungen."""

from datetime import date

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QAbstractItemView,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QPushButton,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)

from ..daten import Ablesung, Datenbank, Zaehler
from ..formate import datum_anzeige, mit_einheit, zahl_anzeige
from ..verbrauch import Messpunkt, abschnitte_berechnen, verbrauch_im_jahr
from ..zaehler_art import ZaehlerArt
from .diagramm import BalkenDiagramm
from .dialoge import AblesungDialog, ZaehlerDialog, loeschen_bestaetigen


class Kennzahlen:
    """Abgeleitete Werte eines Zählers für die Anzeige."""

    def __init__(self, ablesungen: list[Ablesung]):
        self.letzte = max(ablesungen, key=lambda a: a.datum, default=None)
        self.abschnitte = abschnitte_berechnen(
            Messpunkt(date.fromisoformat(a.datum), a.stand) for a in ablesungen
        )

    @property
    def pro_tag_zuletzt(self) -> float | None:
        return self.abschnitte[-1].pro_tag if self.abschnitte else None

    def im_jahr(self, jahr: int) -> float | None:
        return verbrauch_im_jahr(self.abschnitte, jahr) if self.abschnitte else None


class _Kachel(QFrame):
    def __init__(self, titel: str):
        super().__init__()
        self.setFrameShape(QFrame.Shape.StyledPanel)
        layout = QVBoxLayout(self)
        klein = QLabel(titel)
        klein.setStyleSheet("color: palette(placeholder-text)")
        self.wert = QLabel("–")
        self.wert.setStyleSheet("font-size: 16pt")
        layout.addWidget(klein)
        layout.addWidget(self.wert)


class ZaehlerDetail(QWidget):
    SPALTEN = ["Datum", "Stand", "Verbrauch", "Tage", "Ø pro Tag", "Notiz"]

    def __init__(self, db: Datenbank):
        super().__init__()
        self._db = db
        self._zaehler: Zaehler | None = None
        self._ablesungen: list[Ablesung] = []

        self.titel = QLabel()
        self.titel.setStyleSheet("font-size: 18pt; font-weight: 600")
        self.untertitel = QLabel()
        self.untertitel.setWordWrap(True)
        bearbeiten = QPushButton("Zähler bearbeiten…")
        bearbeiten.clicked.connect(self._zaehler_bearbeiten)
        loeschen = QPushButton("Zähler löschen")
        loeschen.clicked.connect(self._zaehler_loeschen)
        kopf = QHBoxLayout()
        kopf_text = QVBoxLayout()
        kopf_text.addWidget(self.titel)
        kopf_text.addWidget(self.untertitel)
        kopf.addLayout(kopf_text, 1)
        kopf.addWidget(bearbeiten, alignment=Qt.AlignmentFlag.AlignTop)
        kopf.addWidget(loeschen, alignment=Qt.AlignmentFlag.AlignTop)

        jahr = date.today().year
        self.k_stand = _Kachel("Letzter Stand")
        self.k_jahr = _Kachel(f"Verbrauch {jahr}")
        self.k_vorjahr = _Kachel(f"Verbrauch {jahr - 1}")
        self.k_tag = _Kachel("Ø pro Tag (zuletzt)")
        kacheln = QGridLayout()
        for i, k in enumerate([self.k_stand, self.k_jahr, self.k_vorjahr, self.k_tag]):
            kacheln.addWidget(k, 0, i)

        self.diagramm_titel = QLabel()
        self.diagramm = BalkenDiagramm()

        self.tabelle = QTableWidget(0, len(self.SPALTEN))
        self.tabelle.setHorizontalHeaderLabels(self.SPALTEN)
        self.tabelle.verticalHeader().hide()
        self.tabelle.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.tabelle.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.tabelle.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.tabelle.horizontalHeader().setSectionResizeMode(
            len(self.SPALTEN) - 1, QHeaderView.ResizeMode.Stretch
        )
        self.tabelle.doubleClicked.connect(self._ablesung_bearbeiten)
        self.tabelle.itemSelectionChanged.connect(self._auswahl_geaendert)

        self.neu = QPushButton("Ablesung erfassen…")
        self.neu.setDefault(True)
        self.neu.clicked.connect(self.ablesung_erfassen)
        self.aendern = QPushButton("Bearbeiten…")
        self.aendern.clicked.connect(self._ablesung_bearbeiten)
        self.entfernen = QPushButton("Löschen")
        self.entfernen.clicked.connect(self._ablesung_loeschen)
        knoepfe = QHBoxLayout()
        knoepfe.addWidget(QLabel("<b>Ablesungen</b>"))
        knoepfe.addStretch()
        for k in (self.neu, self.aendern, self.entfernen):
            knoepfe.addWidget(k)

        layout = QVBoxLayout(self)
        layout.addLayout(kopf)
        layout.addLayout(kacheln)
        layout.addWidget(self.diagramm_titel)
        layout.addWidget(self.diagramm)
        layout.addLayout(knoepfe)
        layout.addWidget(self.tabelle, 1)

    def anzeigen(self, zaehler: Zaehler) -> None:
        self._zaehler = zaehler
        self._ablesungen = self._db.ablesungen(zaehler.id)
        art = ZaehlerArt.aus_schluessel(zaehler.art)
        e = zaehler.einheit
        k = Kennzahlen(self._ablesungen)
        jahr = date.today().year

        self.titel.setText(f"{art.symbol} {zaehler.name}")
        self.untertitel.setText(" · ".join(filter(None, [
            art.label,
            f"Zählernummer {zaehler.zaehlernummer}" if zaehler.zaehlernummer else "",
            zaehler.notiz,
        ])))  # fmt: skip

        def text(v: float | None) -> str:
            return "–" if v is None else mit_einheit(v, e)

        self.k_stand.wert.setText(text(k.letzte.stand if k.letzte else None))
        self.k_stand.wert.setStyleSheet(f"font-size: 16pt; color: {art.farbe}")
        self.k_jahr.wert.setText(text(k.im_jahr(jahr)))
        self.k_vorjahr.wert.setText(text(k.im_jahr(jahr - 1)))
        self.k_tag.wert.setText(text(k.pro_tag_zuletzt))

        zeige_diagramm = len(k.abschnitte) >= 2
        self.diagramm_titel.setText(f"<b>Verbrauch je Ablesungszeitraum</b> ({e})")
        self.diagramm_titel.setVisible(zeige_diagramm)
        self.diagramm.setVisible(zeige_diagramm)
        self.diagramm.setzen(k.abschnitte, e, art.farbe)

        self._tabelle_fuellen(e)
        self._auswahl_geaendert()

    def _tabelle_fuellen(self, einheit: str) -> None:
        self.tabelle.setRowCount(len(self._ablesungen))
        # Neueste zuerst; der Verbrauch bezieht sich auf die nächstältere Ablesung.
        for zeile, a in enumerate(self._ablesungen):
            vorher = (
                self._ablesungen[zeile + 1] if zeile + 1 < len(self._ablesungen) else None
            )
            verbrauch = tage = pro_tag = ""
            if vorher:
                (abschnitt,) = abschnitte_berechnen([
                    Messpunkt(date.fromisoformat(vorher.datum), vorher.stand),
                    Messpunkt(date.fromisoformat(a.datum), a.stand),
                ])  # fmt: skip
                tage = str(abschnitt.tage)
                if abschnitt.verbrauch is None:
                    verbrauch = "Stand gefallen (Zählertausch?)"
                else:
                    verbrauch = "+" + mit_einheit(abschnitt.verbrauch, einheit)
                    if abschnitt.pro_tag is not None:
                        pro_tag = zahl_anzeige(abschnitt.pro_tag)
            werte = [datum_anzeige(a.datum), mit_einheit(a.stand, einheit), verbrauch,
                     tage, pro_tag, a.notiz]  # fmt: skip
            for spalte, wert in enumerate(werte):
                zelle = QTableWidgetItem(wert)
                if spalte in (1, 2, 3, 4):
                    zelle.setTextAlignment(
                        Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter
                    )
                self.tabelle.setItem(zeile, spalte, zelle)
        self.tabelle.resizeColumnsToContents()

    def _ausgewaehlt(self) -> tuple[Ablesung, Ablesung | None] | None:
        zeilen = self.tabelle.selectionModel().selectedRows()
        if not zeilen:
            return None
        i = zeilen[0].row()
        vorher = self._ablesungen[i + 1] if i + 1 < len(self._ablesungen) else None
        return self._ablesungen[i], vorher

    def _auswahl_geaendert(self) -> None:
        gewaehlt = self._ausgewaehlt() is not None
        self.aendern.setEnabled(gewaehlt)
        self.entfernen.setEnabled(gewaehlt)

    def ablesung_erfassen(self) -> None:
        if not self._zaehler:
            return
        letzte = self._ablesungen[0].stand if self._ablesungen else None
        if AblesungDialog(self._db, self, self._zaehler, vorheriger=letzte).exec():
            self.anzeigen(self._zaehler)

    def _ablesung_bearbeiten(self) -> None:
        if not (self._zaehler and (auswahl := self._ausgewaehlt())):
            return
        ablesung, vorher = auswahl
        dialog = AblesungDialog(
            self._db, self, self._zaehler, ablesung,
            vorheriger=vorher.stand if vorher else None,
        )  # fmt: skip
        if dialog.exec():
            self.anzeigen(self._zaehler)

    def _ablesung_loeschen(self) -> None:
        if not (self._zaehler and (auswahl := self._ausgewaehlt())):
            return
        ablesung, _ = auswahl
        if loeschen_bestaetigen(
            self, f"Ablesung vom {datum_anzeige(ablesung.datum)} löschen?"
        ):
            self._db.ablesung_loeschen(ablesung.id)
            self.anzeigen(self._zaehler)

    def _zaehler_bearbeiten(self) -> None:
        if self._zaehler and ZaehlerDialog(self._db, self, self._zaehler).exec():
            self.anzeigen(self._db.zaehler(self._zaehler.id))

    def _zaehler_loeschen(self) -> None:
        if not self._zaehler:
            return
        if loeschen_bestaetigen(
            self,
            f"„{self._zaehler.name}“ und alle {len(self._ablesungen)} Ablesungen "
            "löschen? Das gilt für alle Benutzer.",
        ):
            # Das Hauptfenster lädt daraufhin neu und wählt einen anderen Zähler.
            self._db.zaehler_loeschen(self._zaehler.id)
