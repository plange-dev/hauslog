"""Einstiegspunkt."""

import sys

from PySide6.QtCore import QLocale
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication

from . import __version__
from .daten import Datenbank
from .pfade import Einstellungen, daten_ordner
from .sync_steuerung import SyncSteuerung
from .ui.hauptfenster import Hauptfenster


def main() -> int:
    QLocale.setDefault(QLocale(QLocale.Language.German, QLocale.Country.Germany))
    app = QApplication(sys.argv)
    app.setApplicationName("Hauslog")
    app.setApplicationVersion(__version__)
    app.setDesktopFileName("hauslog")
    symbol = QIcon.fromTheme("hauslog")
    if symbol.isNull():
        from importlib.resources import files

        symbol = QIcon(str(files("hauslog") / "hauslog.png"))
    app.setWindowIcon(symbol)

    ordner = daten_ordner()
    db = Datenbank(ordner / "hauslog.db")
    sync = SyncSteuerung(db, Einstellungen(ordner / "einstellungen.json"))
    fenster = Hauptfenster(db, sync)
    fenster.show()
    try:
        return app.exec()
    finally:
        sync.beenden()
        db.schliessen()


if __name__ == "__main__":
    sys.exit(main())
