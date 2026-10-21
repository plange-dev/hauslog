"""Erzeugt das App-Symbol (PNG für Linux, ICO für Windows).

    python tools/symbol_erzeugen.py
"""

import sys
from pathlib import Path

from PySide6.QtCore import QPointF, QRectF, Qt
from PySide6.QtGui import QColor, QGuiApplication, QImage, QPainter, QPainterPath, QPen

WURZEL = Path(__file__).resolve().parent.parent


def stift(farbe: str, breite: float) -> QPen:
    pen = QPen(QColor(farbe), breite)
    pen.setCapStyle(Qt.PenCapStyle.RoundCap)
    return pen


def zeichnen(groesse: int) -> QImage:
    bild = QImage(groesse, groesse, QImage.Format.Format_ARGB32)
    bild.fill(Qt.GlobalColor.transparent)
    p = QPainter(bild)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    p.scale(groesse / 256, groesse / 256)

    # Hintergrund
    p.setPen(Qt.PenStyle.NoPen)
    p.setBrush(QColor("#1A2744"))
    p.drawRoundedRect(QRectF(8, 8, 240, 240), 52, 52)

    # Haus
    haus = QPainterPath()
    haus.moveTo(128, 46)
    haus.lineTo(212, 116)
    haus.lineTo(194, 116)
    haus.lineTo(194, 206)
    haus.lineTo(62, 206)
    haus.lineTo(62, 116)
    haus.lineTo(44, 116)
    haus.closeSubpath()
    p.setBrush(QColor("#F4F1EA"))
    p.drawPath(haus)

    # Zähler mit Zeiger
    mitte = QPointF(128, 158)
    p.setBrush(QColor("#1A2744"))
    p.drawEllipse(mitte, 40, 40)
    p.setPen(stift("#F4A261", 10))
    p.setBrush(Qt.BrushStyle.NoBrush)
    p.drawArc(QRectF(98, 128, 60, 60), 200 * 16, -220 * 16)
    p.setPen(stift("#F4F1EA", 9))
    p.drawLine(mitte, QPointF(150, 140))
    p.setPen(Qt.PenStyle.NoPen)
    p.setBrush(QColor("#F4F1EA"))
    p.drawEllipse(mitte, 8, 8)
    p.end()
    return bild


def main() -> None:
    QGuiApplication(sys.argv)
    png = WURZEL / "src/hauslog/hauslog.png"
    zeichnen(256).save(str(png))
    ico = WURZEL / "packaging/windows/hauslog.ico"
    ico.parent.mkdir(parents=True, exist_ok=True)
    if not zeichnen(256).save(str(ico), "ICO"):
        sys.exit("ICO konnte nicht geschrieben werden")
    print(png, ico, sep="\n")


if __name__ == "__main__":
    main()
