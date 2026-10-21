"""Lokale SQLite-Datenbank.

Jeder synchronisierte Datensatz trägt:

- ``id``: von der App vergeben (PocketBase-Format), damit offline angelegt
  werden kann,
- ``geaendert_am``: ms seit 1970; bei Konflikten gewinnt der neuere Stand,
- ``geloescht``: gelöscht wird nur weich, damit die Löschung synchronisiert wird,
- ``ungesendet``: lokal geändert und noch nicht zum Server übertragen.
"""

import sqlite3
import time
from collections.abc import Callable
from dataclasses import dataclass, replace
from datetime import date
from pathlib import Path

from .ids import datum_text, neue_id

_SCHEMA = """
CREATE TABLE IF NOT EXISTS zaehler (
    id            TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    art           TEXT NOT NULL,
    einheit       TEXT NOT NULL,
    zaehlernummer TEXT NOT NULL DEFAULT '',
    notiz         TEXT NOT NULL DEFAULT '',
    geaendert_am  INTEGER NOT NULL,
    geloescht     INTEGER NOT NULL DEFAULT 0,
    ungesendet    INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS ablesungen (
    id            TEXT PRIMARY KEY,
    zaehler_id    TEXT NOT NULL,
    datum         TEXT NOT NULL,          -- JJJJ-MM-TT
    stand         REAL NOT NULL,
    notiz         TEXT NOT NULL DEFAULT '',
    geaendert_am  INTEGER NOT NULL,
    geloescht     INTEGER NOT NULL DEFAULT 0,
    ungesendet    INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_ablesungen_zaehler ON ablesungen (zaehler_id, datum);
CREATE TABLE IF NOT EXISTS sync_status (
    schluessel TEXT PRIMARY KEY,
    wert       TEXT NOT NULL
);
"""


@dataclass(frozen=True)
class Zaehler:
    id: str
    name: str
    art: str
    einheit: str
    zaehlernummer: str
    notiz: str
    geaendert_am: int
    geloescht: bool
    ungesendet: bool


@dataclass(frozen=True)
class Ablesung:
    id: str
    zaehler_id: str
    datum: str
    stand: float
    notiz: str
    geaendert_am: int
    geloescht: bool
    ungesendet: bool


def _jetzt() -> int:
    return time.time_ns() // 1_000_000


class Datenbank:
    """Zugriff auf die lokale Datenbank.

    Eine Instanz gehört zu genau einem Thread. Der Abgleich im Hintergrund
    öffnet deshalb eine eigene Instanz auf dieselbe Datei.
    """

    def __init__(self, pfad: str | Path = ":memory:"):
        self.pfad = str(pfad)
        if self.pfad != ":memory:":
            Path(self.pfad).parent.mkdir(parents=True, exist_ok=True)
        self._db = sqlite3.connect(self.pfad, timeout=10)
        self._db.row_factory = sqlite3.Row
        self._db.execute("PRAGMA journal_mode=WAL")
        self._db.executescript(_SCHEMA)
        self._beobachter: list[Callable[[], None]] = []

    def schliessen(self) -> None:
        self._db.close()

    def beobachten(self, rueckruf: Callable[[], None]) -> None:
        """``rueckruf`` wird nach jeder Änderung über diese Instanz aufgerufen."""
        self._beobachter.append(rueckruf)

    def nicht_mehr_beobachten(self, rueckruf: Callable[[], None]) -> None:
        self._beobachter.remove(rueckruf)

    def _geaendert(self) -> None:
        for rueckruf in list(self._beobachter):
            rueckruf()

    # ── Zähler ──────────────────────────────────────────────────────────────

    @staticmethod
    def _zaehler(z: sqlite3.Row) -> Zaehler:
        return Zaehler(
            id=z["id"], name=z["name"], art=z["art"], einheit=z["einheit"],
            zaehlernummer=z["zaehlernummer"], notiz=z["notiz"],
            geaendert_am=z["geaendert_am"], geloescht=bool(z["geloescht"]),
            ungesendet=bool(z["ungesendet"]),
        )  # fmt: skip

    def alle_zaehler(self) -> list[Zaehler]:
        zeilen = self._db.execute(
            "SELECT * FROM zaehler WHERE NOT geloescht ORDER BY name COLLATE NOCASE"
        )
        return [self._zaehler(z) for z in zeilen]

    def zaehler(self, zaehler_id: str) -> Zaehler | None:
        z = self._db.execute(
            "SELECT * FROM zaehler WHERE id = ? AND NOT geloescht", (zaehler_id,)
        ).fetchone()
        return self._zaehler(z) if z else None

    def zaehler_speichern(
        self,
        *,
        name: str,
        art: str,
        einheit: str,
        zaehlernummer: str = "",
        notiz: str = "",
        id: str | None = None,
    ) -> str:
        """Legt einen Zähler an (ohne ``id``) oder ändert ihn. Gibt die ID zurück."""
        id = id or neue_id()
        with self._db:
            self._db.execute(
                """INSERT INTO zaehler (id, name, art, einheit, zaehlernummer, notiz,
                                        geaendert_am, geloescht, ungesendet)
                   VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1)
                   ON CONFLICT (id) DO UPDATE SET
                     name = excluded.name, art = excluded.art,
                     einheit = excluded.einheit,
                     zaehlernummer = excluded.zaehlernummer,
                     notiz = excluded.notiz, geaendert_am = excluded.geaendert_am,
                     geloescht = 0, ungesendet = 1""",
                (id, name, art, einheit, zaehlernummer, notiz, _jetzt()),
            )
        self._geaendert()
        return id

    def zaehler_loeschen(self, zaehler_id: str) -> None:
        """Löscht den Zähler samt seinen Ablesungen."""
        jetzt = _jetzt()
        with self._db:
            self._db.execute(
                "UPDATE zaehler SET geloescht = 1, geaendert_am = ?, ungesendet = 1"
                " WHERE id = ?",
                (jetzt, zaehler_id),
            )
            self._db.execute(
                "UPDATE ablesungen SET geloescht = 1, geaendert_am = ?, ungesendet = 1"
                " WHERE zaehler_id = ? AND NOT geloescht",
                (jetzt, zaehler_id),
            )
        self._geaendert()

    # ── Ablesungen ──────────────────────────────────────────────────────────

    @staticmethod
    def _ablesung(a: sqlite3.Row) -> Ablesung:
        return Ablesung(
            id=a["id"], zaehler_id=a["zaehler_id"], datum=a["datum"],
            stand=a["stand"], notiz=a["notiz"], geaendert_am=a["geaendert_am"],
            geloescht=bool(a["geloescht"]), ungesendet=bool(a["ungesendet"]),
        )  # fmt: skip

    def ablesungen(self, zaehler_id: str) -> list[Ablesung]:
        """Alle Ablesungen eines Zählers, neueste zuerst."""
        zeilen = self._db.execute(
            "SELECT * FROM ablesungen WHERE zaehler_id = ? AND NOT geloescht"
            " ORDER BY datum DESC, geaendert_am DESC",
            (zaehler_id,),
        )
        return [self._ablesung(a) for a in zeilen]

    def alle_ablesungen(self) -> list[Ablesung]:
        """Alle Ablesungen aller Zähler, älteste zuerst."""
        zeilen = self._db.execute(
            "SELECT * FROM ablesungen WHERE NOT geloescht ORDER BY datum"
        )
        return [self._ablesung(a) for a in zeilen]

    def ablesung_speichern(
        self,
        *,
        zaehler_id: str,
        datum: date,
        stand: float,
        notiz: str = "",
        id: str | None = None,
    ) -> str:
        id = id or neue_id()
        with self._db:
            self._db.execute(
                """INSERT INTO ablesungen (id, zaehler_id, datum, stand, notiz,
                                           geaendert_am, geloescht, ungesendet)
                   VALUES (?, ?, ?, ?, ?, ?, 0, 1)
                   ON CONFLICT (id) DO UPDATE SET
                     zaehler_id = excluded.zaehler_id, datum = excluded.datum,
                     stand = excluded.stand, notiz = excluded.notiz,
                     geaendert_am = excluded.geaendert_am,
                     geloescht = 0, ungesendet = 1""",
                (id, zaehler_id, datum_text(datum), stand, notiz, _jetzt()),
            )
        self._geaendert()
        return id

    def ablesung_loeschen(self, ablesung_id: str) -> None:
        with self._db:
            self._db.execute(
                "UPDATE ablesungen SET geloescht = 1, geaendert_am = ?, ungesendet = 1"
                " WHERE id = ?",
                (_jetzt(), ablesung_id),
            )
        self._geaendert()

    # ── Sync ────────────────────────────────────────────────────────────────

    def ungesendete_zaehler(self) -> list[Zaehler]:
        return [self._zaehler(z) for z in self._db.execute(
            "SELECT * FROM zaehler WHERE ungesendet")]  # fmt: skip

    def ungesendete_ablesungen(self) -> list[Ablesung]:
        return [self._ablesung(a) for a in self._db.execute(
            "SELECT * FROM ablesungen WHERE ungesendet")]  # fmt: skip

    def anzahl_ungesendet(self) -> int:
        return self._db.execute(
            "SELECT (SELECT COUNT(*) FROM zaehler WHERE ungesendet)"
            " + (SELECT COUNT(*) FROM ablesungen WHERE ungesendet)"
        ).fetchone()[0]

    def gesendet(self, tabelle: str, id: str, geaendert_am: int) -> None:
        """Markiert einen Datensatz als übertragen – aber nur, wenn er seit dem
        Senden nicht erneut geändert wurde."""
        with self._db:
            self._db.execute(
                f"UPDATE {_tabelle(tabelle)} SET ungesendet = 0"
                " WHERE id = ? AND geaendert_am = ?",
                (id, geaendert_am),
            )

    def vom_server(self, datensatz: Zaehler | Ablesung) -> bool:
        """Übernimmt einen Datensatz vom Server, sofern lokal nichts Neueres
        liegt. Gibt zurück, ob etwas geändert wurde."""
        tabelle = "zaehler" if isinstance(datensatz, Zaehler) else "ablesungen"
        with self._db:
            lokal = self._db.execute(
                f"SELECT geaendert_am, ungesendet FROM {tabelle} WHERE id = ?",
                (datensatz.id,),
            ).fetchone()
            if (
                lokal
                and lokal["ungesendet"]
                and lokal["geaendert_am"] > datensatz.geaendert_am
            ):
                return False
            werte = vars(replace(datensatz, ungesendet=False))
            spalten = ", ".join(werte)
            platzhalter = ", ".join(f":{s}" for s in werte)
            self._db.execute(
                f"INSERT OR REPLACE INTO {tabelle} ({spalten}) VALUES ({platzhalter})",
                werte,
            )
        return True

    def sync_wert(self, schluessel: str) -> str | None:
        zeile = self._db.execute(
            "SELECT wert FROM sync_status WHERE schluessel = ?", (schluessel,)
        ).fetchone()
        return zeile["wert"] if zeile else None

    def sync_wert_setzen(self, schluessel: str, wert: str) -> None:
        with self._db:
            self._db.execute(
                "INSERT OR REPLACE INTO sync_status (schluessel, wert) VALUES (?, ?)",
                (schluessel, wert),
            )

    def sync_zuruecksetzen(self) -> None:
        """Vergisst den Sync-Stand, z. B. nach Wechsel auf einen anderen Server.
        Danach wird beim nächsten Abgleich alles neu geholt und alles gesendet."""
        with self._db:
            self._db.execute("DELETE FROM sync_status")
            self._db.execute("UPDATE zaehler SET ungesendet = 1")
            self._db.execute("UPDATE ablesungen SET ungesendet = 1")
        self._geaendert()


def _tabelle(name: str) -> str:
    if name not in ("zaehler", "ablesungen"):
        raise ValueError(f"Unbekannte Tabelle: {name}")
    return name
