"""Speicherorte und gespeicherte Einstellungen."""

import json
import os
import sys
from pathlib import Path


def daten_ordner() -> Path:
    """Windows: %LOCALAPPDATA%\\Hauslog, Linux: ~/.local/share/hauslog."""
    if sys.platform == "win32":
        return Path(os.environ["LOCALAPPDATA"]) / "Hauslog"
    basis = os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share"
    return Path(basis) / "hauslog"


class Einstellungen:
    """Kleine JSON-Datei neben der Datenbank (Server-Adresse, Anmeldung)."""

    def __init__(self, pfad: Path):
        self._pfad = pfad
        try:
            self._werte = json.loads(pfad.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            self._werte = {}

    def get(self, schluessel: str, standard=None):
        return self._werte.get(schluessel, standard)

    def setzen(self, **werte) -> None:
        self._werte.update(werte)
        self._pfad.parent.mkdir(parents=True, exist_ok=True)
        self._pfad.write_text(json.dumps(self._werte, indent=2), encoding="utf-8")
