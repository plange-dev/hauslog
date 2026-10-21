"""Übernahme aus dem alten Rust-„Verbrauchsmanager“ (Tabellen strom, wasser, gas)."""

import os
import sqlite3
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from .daten import Datenbank
from .zaehler_art import ZaehlerArt

ALT_TABELLEN = {
    "strom": ZaehlerArt.STROM,
    "wasser": ZaehlerArt.WASSER,
    "gas": ZaehlerArt.GAS,
}


@dataclass(frozen=True)
class AltEintrag:
    tabelle: str
    datum: str
    wert: float
    notiz: str


def alt_ordner() -> Path | None:
    """Ordner, in dem der alte Verbrauchsmanager seine Datenbank anlegte."""
    if sys.platform == "win32":
        basis = Path(os.environ.get("LOCALAPPDATA", ""))
    else:
        basis = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    ordner = basis / "verbrauchsmanager"
    return ordner if ordner.is_dir() else None


def alt_datenbank_lesen(pfad: str | Path) -> list[AltEintrag]:
    db = sqlite3.connect(f"file:{Path(pfad).as_posix()}?mode=ro", uri=True)
    try:
        vorhanden = {
            z[0]
            for z in db.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
        }
        return [
            AltEintrag(tabelle, datum, float(wert), notiz or "")
            for tabelle in ALT_TABELLEN
            if tabelle in vorhanden
            for datum, wert, notiz in db.execute(
                f"SELECT datum, wert, notiz FROM {tabelle} ORDER BY datum"
            )
        ]
    finally:
        db.close()


def alt_daten_importieren(db: Datenbank, eintraege: list[AltEintrag]) -> int:
    """Legt je alter Tabelle einen Zähler an und übernimmt die Werte als
    Zählerstände. Gibt die Anzahl übernommener Ablesungen zurück."""
    zaehler_ids: dict[str, str] = {}
    anzahl = 0
    for e in eintraege:
        art = ALT_TABELLEN.get(e.tabelle)
        try:
            datum = date.fromisoformat(e.datum)
        except ValueError:
            continue
        if art is None:
            continue
        if e.tabelle not in zaehler_ids:
            zaehler_ids[e.tabelle] = db.zaehler_speichern(
                name=art.label,
                art=art.schluessel,
                einheit=art.einheit,
                notiz="Aus dem Verbrauchsmanager importiert",
            )
        db.ablesung_speichern(
            zaehler_id=zaehler_ids[e.tabelle], datum=datum, stand=e.wert, notiz=e.notiz
        )
        anzahl += 1
    return anzahl
