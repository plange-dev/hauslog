"""Dialoge zum Anlegen und Bearbeiten von Zählern und Ablesungen."""

from datetime import date

from PySide6.QtCore import QDate
from PySide6.QtWidgets import (
    QComboBox,
    QDateEdit,
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPlainTextEdit,
    QVBoxLayout,
    QWidget,
)

from ..daten import Ablesung, Datenbank, Zaehler
from ..formate import zahl_anzeige, zahl_lesen
from ..zaehler_art import ZaehlerArt


def loeschen_bestaetigen(eltern: QWidget, frage: str) -> bool:
    antwort = QMessageBox.question(
        eltern, "Löschen?", frage,
        QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.Cancel,
        QMessageBox.StandardButton.Cancel,
    )  # fmt: skip
    return antwort == QMessageBox.StandardButton.Yes


def _knoepfe(dialog: QDialog) -> QDialogButtonBox:
    knoepfe = QDialogButtonBox(
        QDialogButtonBox.StandardButton.Save | QDialogButtonBox.StandardButton.Cancel
    )
    knoepfe.button(QDialogButtonBox.StandardButton.Save).setText("Speichern")
    knoepfe.button(QDialogButtonBox.StandardButton.Cancel).setText("Abbrechen")
    knoepfe.accepted.connect(dialog.accept)
    knoepfe.rejected.connect(dialog.reject)
    return knoepfe


class ZaehlerDialog(QDialog):
    """Legt einen Zähler an oder bearbeitet ``zaehler``."""

    def __init__(self, db: Datenbank, eltern: QWidget, zaehler: Zaehler | None = None):
        super().__init__(eltern)
        self._db = db
        self._zaehler = zaehler
        self.zaehler_id: str | None = None
        self.setWindowTitle("Neuer Zähler" if zaehler is None else "Zähler bearbeiten")
        self.setMinimumWidth(420)

        self.art = QComboBox()
        for a in ZaehlerArt:
            self.art.addItem(f"{a.symbol}  {a.label}", a)
        art = ZaehlerArt.aus_schluessel(zaehler.art) if zaehler else ZaehlerArt.STROM
        self.art.setCurrentIndex(list(ZaehlerArt).index(art))
        self._vorige_art = art
        self.art.currentIndexChanged.connect(self._art_gewaehlt)

        self.name = QLineEdit(zaehler.name if zaehler else "")
        self.name.setPlaceholderText("z. B. Strom Hauptzähler")
        self.einheit = QLineEdit(zaehler.einheit if zaehler else art.einheit)
        self.nummer = QLineEdit(zaehler.zaehlernummer if zaehler else "")
        self.notiz = QPlainTextEdit(zaehler.notiz if zaehler else "")
        self.notiz.setPlaceholderText("z. B. Keller, links neben der Tür")
        self.notiz.setFixedHeight(64)

        form = QFormLayout()
        form.addRow("Art", self.art)
        form.addRow("Name", self.name)
        form.addRow("Einheit", self.einheit)
        form.addRow("Zählernummer", self.nummer)
        form.addRow("Notiz", self.notiz)
        layout = QVBoxLayout(self)
        layout.addLayout(form)
        layout.addWidget(_knoepfe(self))

    def _art_gewaehlt(self) -> None:
        art: ZaehlerArt = self.art.currentData()
        # Einheit nur nachziehen, wenn sie noch der Vorlage entspricht.
        if self.einheit.text() == self._vorige_art.einheit:
            self.einheit.setText(art.einheit)
        self._vorige_art = art

    def accept(self) -> None:
        if not self.name.text().strip():
            QMessageBox.warning(self, "Name fehlt", "Bitte einen Namen angeben.")
            return
        self.zaehler_id = self._db.zaehler_speichern(
            id=self._zaehler.id if self._zaehler else None,
            name=self.name.text().strip(),
            art=self.art.currentData().schluessel,
            einheit=self.einheit.text().strip(),
            zaehlernummer=self.nummer.text().strip(),
            notiz=self.notiz.toPlainText().strip(),
        )
        super().accept()


class AblesungDialog(QDialog):
    """Erfasst eine neue Ablesung oder bearbeitet ``ablesung``.

    ``vorheriger`` ist der zuletzt erfasste Stand, als Plausibilitätshinweis.
    """

    def __init__(
        self,
        db: Datenbank,
        eltern: QWidget,
        zaehler: Zaehler,
        ablesung: Ablesung | None = None,
        vorheriger: float | None = None,
    ):
        super().__init__(eltern)
        self._db = db
        self._zaehler = zaehler
        self._ablesung = ablesung
        self._vorheriger = vorheriger
        self.setWindowTitle(
            "Ablesung erfassen" if ablesung is None else "Ablesung bearbeiten"
        )
        self.setMinimumWidth(380)

        self.datum = QDateEdit(calendarPopup=True, displayFormat="dd.MM.yyyy")
        d = date.fromisoformat(ablesung.datum) if ablesung else date.today()
        self.datum.setDate(QDate(d.year, d.month, d.day))
        self.datum.setMaximumDate(QDate.currentDate().addDays(1))

        self.stand = QLineEdit(zahl_anzeige(ablesung.stand) if ablesung else "")
        self.stand.setPlaceholderText(
            f"Zählerstand in {zaehler.einheit}" if zaehler.einheit else "Zählerstand"
        )
        self.stand.textChanged.connect(self._stand_geaendert)
        self.hinweis = QLabel()
        self.hinweis.setStyleSheet("color: #b5651d")
        self.hinweis.setWordWrap(True)
        self.hinweis.hide()
        self.notiz = QLineEdit(ablesung.notiz if ablesung else "")

        titel = QLabel(f"<b>{zaehler.name}</b>")
        form = QFormLayout()
        form.addRow("Datum", self.datum)
        form.addRow(
            f"Stand ({zaehler.einheit})" if zaehler.einheit else "Stand", self.stand
        )
        form.addRow("", self.hinweis)
        form.addRow("Notiz", self.notiz)
        layout = QVBoxLayout(self)
        layout.addWidget(titel)
        layout.addLayout(form)
        layout.addWidget(_knoepfe(self))
        self.stand.setFocus()

    def _stand_geaendert(self, text: str) -> None:
        wert, vorher = zahl_lesen(text), self._vorheriger
        zu_klein = wert is not None and vorher is not None and wert < vorher
        if zu_klein:
            self.hinweis.setText(
                f"Kleiner als die letzte Ablesung ({zahl_anzeige(vorher)}) – "
                "Zähler getauscht?"
            )
        self.hinweis.setVisible(zu_klein)

    def accept(self) -> None:
        wert = zahl_lesen(self.stand.text())
        if wert is None or wert < 0:
            QMessageBox.warning(
                self, "Ungültiger Stand", "Bitte eine Zahl ab 0 eingeben, z. B. 1234,5."
            )
            return
        self._db.ablesung_speichern(
            id=self._ablesung.id if self._ablesung else None,
            zaehler_id=self._zaehler.id,
            datum=self.datum.date().toPython(),
            stand=wert,
            notiz=self.notiz.text().strip(),
        )
        super().accept()
