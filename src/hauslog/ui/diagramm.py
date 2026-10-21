"""Balkendiagramm: Verbrauch je Ablesungszeitraum (die letzten 12)."""

import math

from PySide6.QtCore import QRectF, Qt
from PySide6.QtGui import QColor, QMouseEvent, QPainter, QPaintEvent
from PySide6.QtWidgets import QSizePolicy, QToolTip, QWidget

from ..formate import datum_anzeige, mit_einheit, zahl_anzeige
from ..verbrauch import Verbrauchsabschnitt

ANZAHL = 12


def _runde_skala(maximum: float) -> float:
    """Nächster „runder“ Wert ≥ maximum (1, 2, 5, 10, 20, …)."""
    if maximum <= 0:
        return 1
    stufe = 10 ** math.floor(math.log10(maximum))
    return next(f * stufe for f in (1, 2, 5, 10) if f * stufe >= maximum)


class BalkenDiagramm(QWidget):
    def __init__(self):
        super().__init__()
        self.setMinimumHeight(220)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.setMouseTracking(True)
        self._abschnitte: list[Verbrauchsabschnitt] = []
        self._einheit = ""
        self._farbe = QColor("#457B9D")
        self._balken: list[QRectF] = []

    def setzen(
        self, abschnitte: list[Verbrauchsabschnitt], einheit: str, farbe: str
    ) -> None:
        self._abschnitte = abschnitte[-ANZAHL:]
        self._einheit = einheit
        self._farbe = QColor(farbe)
        self.update()

    def paintEvent(self, _: QPaintEvent) -> None:
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        text = self.palette().color(self.foregroundRole())
        linien = QColor(text)
        linien.setAlpha(40)

        links, oben, unten = 56, 8, 24
        flaeche = QRectF(
            links, oben, self.width() - links - 8, self.height() - oben - unten
        )
        skala = _runde_skala(max((a.verbrauch or 0 for a in self._abschnitte), default=0))

        # Gitter und Achsenbeschriftung
        for i in range(5):
            y = flaeche.bottom() - flaeche.height() * i / 4
            p.setPen(linien)
            p.drawLine(int(flaeche.left()), int(y), int(flaeche.right()), int(y))
            p.setPen(text)
            p.drawText(
                QRectF(0, y - 8, links - 6, 16),
                Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter,
                zahl_anzeige(skala * i / 4),
            )

        self._balken = []
        if not self._abschnitte:
            return
        breite = flaeche.width() / len(self._abschnitte)
        for i, a in enumerate(self._abschnitte):
            hoehe = flaeche.height() * (a.verbrauch or 0) / skala
            balken = QRectF(
                flaeche.left() + i * breite + breite * 0.2,
                flaeche.bottom() - hoehe,
                breite * 0.6,
                hoehe,
            )
            self._balken.append(balken)
            p.setPen(Qt.PenStyle.NoPen)
            p.setBrush(self._farbe)
            p.drawRoundedRect(balken, 3, 3)
            p.setPen(text)
            p.drawText(
                QRectF(flaeche.left() + i * breite, flaeche.bottom() + 4, breite, 18),
                Qt.AlignmentFlag.AlignCenter,
                a.bis.strftime("%m/%y"),
            )

    def mouseMoveEvent(self, ereignis: QMouseEvent) -> None:
        punkt = ereignis.position()
        for balken, a in zip(self._balken, self._abschnitte, strict=False):
            spalte = QRectF(balken.left(), 0, balken.width(), self.height())
            if spalte.contains(punkt):
                verbrauch = (
                    "–"
                    if a.verbrauch is None
                    else mit_einheit(a.verbrauch, self._einheit)
                )
                QToolTip.showText(
                    ereignis.globalPosition().toPoint(),
                    f"{datum_anzeige(a.von)} – {datum_anzeige(a.bis)}\n{verbrauch}",
                    self,
                )
                return
        QToolTip.hideText()
