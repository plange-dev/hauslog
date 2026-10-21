"""Abgleich der lokalen Datenbank mit PocketBase.

Ablauf:

1. Lokal geänderte Datensätze senden (Zähler vor Ablesungen). Ist der Stand
   auf dem Server neuer, wird stattdessen dieser übernommen.
2. Alles holen, was sich auf dem Server seit dem letzten Abruf geändert hat.
   Lokal ungesendete, neuere Änderungen bleiben dabei erhalten.

Konflikte entscheidet ``geaendert_am``: der neuere Stand gewinnt.
Datenformat und Verhalten entsprechen der Flutter-App, beide können
denselben Server nutzen.
"""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from .daten import Ablesung, Datenbank, Zaehler
from .pocketbase import PocketBase, filter_text


@dataclass(frozen=True)
class SyncErgebnis:
    gesendet: int
    empfangen: int


@dataclass(frozen=True)
class _SyncTabelle:
    sammlung: str
    ungesendet: Callable[[Datenbank], list]
    als_server_daten: Callable[[Any], dict]
    aus_server_daten: Callable[[dict], Zaehler | Ablesung]


_TABELLEN = [
    _SyncTabelle(
        sammlung="zaehler",
        ungesendet=Datenbank.ungesendete_zaehler,
        als_server_daten=lambda z: {
            "name": z.name, "art": z.art, "einheit": z.einheit,
            "zaehlernummer": z.zaehlernummer, "notiz": z.notiz,
            "geaendert_am": z.geaendert_am, "geloescht": z.geloescht,
        },
        aus_server_daten=lambda r: Zaehler(
            id=r["id"], name=r.get("name", ""), art=r.get("art", ""),
            einheit=r.get("einheit", ""), zaehlernummer=r.get("zaehlernummer", ""),
            notiz=r.get("notiz", ""), geaendert_am=int(r.get("geaendert_am", 0)),
            geloescht=bool(r.get("geloescht")), ungesendet=False,
        ),
    ),
    _SyncTabelle(
        sammlung="ablesungen",
        ungesendet=Datenbank.ungesendete_ablesungen,
        als_server_daten=lambda a: {
            "zaehler": a.zaehler_id, "datum": a.datum, "stand": a.stand,
            "notiz": a.notiz, "geaendert_am": a.geaendert_am,
            "geloescht": a.geloescht,
        },
        aus_server_daten=lambda r: Ablesung(
            id=r["id"], zaehler_id=r.get("zaehler", ""), datum=r.get("datum", ""),
            stand=float(r.get("stand", 0)), notiz=r.get("notiz", ""),
            geaendert_am=int(r.get("geaendert_am", 0)),
            geloescht=bool(r.get("geloescht")), ungesendet=False,
        ),
    ),
]  # fmt: skip


def synchronisieren(db: Datenbank, pb: PocketBase) -> SyncErgebnis:
    gesendet = sum(_senden(db, pb, t) for t in _TABELLEN)
    empfangen = sum(_holen(db, pb, t) for t in _TABELLEN)
    return SyncErgebnis(gesendet=gesendet, empfangen=empfangen)


def _senden(db: Datenbank, pb: PocketBase, t: _SyncTabelle) -> int:
    anzahl = 0
    for lokal in t.ungesendet(db):
        daten = t.als_server_daten(lokal)
        entfernt = pb.lesen(t.sammlung, lokal.id)
        if entfernt is None:
            pb.anlegen(t.sammlung, {**daten, "id": lokal.id})
        elif int(entfernt.get("geaendert_am", 0)) > lokal.geaendert_am:
            # Auf dem Server liegt eine neuere Änderung – die gewinnt.
            db.vom_server(t.aus_server_daten(entfernt))
            continue
        else:
            pb.aendern(t.sammlung, lokal.id, daten)
        db.gesendet(t.sammlung, lokal.id, lokal.geaendert_am)
        anzahl += 1
    return anzahl


def _holen(db: Datenbank, pb: PocketBase, t: _SyncTabelle) -> int:
    schluessel = f"cursor_{t.sammlung}"
    cursor = db.sync_wert(schluessel)
    # `>=` statt `>`: mehrere Änderungen können denselben Zeitstempel haben.
    # Doppelt übernommene Datensätze schaden nicht.
    datensaetze = pb.alle(
        t.sammlung,
        sort="updated",
        filter=f"updated >= {filter_text(cursor)}" if cursor else "",
    )
    neu = 0
    for r in datensaetze:
        if db.vom_server(t.aus_server_daten(r)) and r["updated"] != cursor:
            neu += 1
    if datensaetze:
        db.sync_wert_setzen(schluessel, datensaetze[-1]["updated"])
    return neu
