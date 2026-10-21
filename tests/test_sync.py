"""Abgleich gegen einen echten PocketBase-Server.

Läuft nur, wenn PB_URL, PB_ADMIN und PB_ADMIN_PASSWORT gesetzt sind, z. B.:
    PB_URL=http://127.0.0.1:8090 PB_ADMIN=admin@test.local \\
    PB_ADMIN_PASSWORT=... pytest tests/test_sync.py
"""

import os
import time
from datetime import date

import pytest

from hauslog.daten import Datenbank
from hauslog.ids import neue_id
from hauslog.pocketbase import PocketBase, ServerFehler
from hauslog.sync import synchronisieren

URL = os.environ.get("PB_URL")
pytestmark = pytest.mark.skipif(not URL, reason="PB_URL nicht gesetzt")


@pytest.fixture(scope="module")
def zugang():
    admin = PocketBase(URL)
    admin.anmelden(os.environ["PB_ADMIN"], os.environ["PB_ADMIN_PASSWORT"], "_superusers")
    email = f"test-{neue_id()}@test.local"
    admin.anlegen("users", {
        "email": email, "password": "passwort123", "passwordConfirm": "passwort123",
    })  # fmt: skip
    return email, "passwort123"


@pytest.fixture
def geraete(zugang):
    """Zwei Geräte mit eigener Datenbank, aber demselben Benutzer."""
    ergebnis = []
    for _ in range(2):
        pb = PocketBase(URL)
        pb.anmelden(*zugang)
        ergebnis.append((Datenbank(), pb))
    return ergebnis


def stand(db: Datenbank, id: str) -> float:
    return next(a.stand for a in db.alle_ablesungen() if a.id == id)


def test_neuer_zaehler_kommt_auf_anderem_geraet_an(geraete):
    (db_a, pb_a), (db_b, pb_b) = geraete
    zid = db_a.zaehler_speichern(name="Strom Haus", art="strom", einheit="kWh")
    db_a.ablesung_speichern(zaehler_id=zid, datum=date(2026, 10, 1), stand=1234.5)

    assert synchronisieren(db_a, pb_a).gesendet == 2
    assert db_a.anzahl_ungesendet() == 0

    synchronisieren(db_b, pb_b)
    assert db_b.zaehler(zid).name == "Strom Haus"
    (ablesung,) = [a for a in db_b.alle_ablesungen() if a.zaehler_id == zid]
    assert (ablesung.stand, ablesung.datum, ablesung.ungesendet) == (
        1234.5,
        "2026-10-01",
        False,
    )


@pytest.mark.parametrize("b_sendet_zuerst", [True, False])
def test_neuere_offline_aenderung_gewinnt(geraete, b_sendet_zuerst):
    (db_a, pb_a), (db_b, pb_b) = geraete
    zid = db_a.zaehler_speichern(name="Gas", art="gas", einheit="m³")
    aid = db_a.ablesung_speichern(zaehler_id=zid, datum=date(2026, 10, 2), stand=100)
    synchronisieren(db_a, pb_a)
    synchronisieren(db_b, pb_b)

    # Beide ändern offline, B später.
    db_a.ablesung_speichern(id=aid, zaehler_id=zid, datum=date(2026, 10, 2), stand=111)
    time.sleep(0.01)
    db_b.ablesung_speichern(id=aid, zaehler_id=zid, datum=date(2026, 10, 2), stand=222)

    reihenfolge = [(db_b, pb_b), (db_a, pb_a)]
    if not b_sendet_zuerst:
        reihenfolge.reverse()
    for db, pb in [*reihenfolge, *reihenfolge]:
        synchronisieren(db, pb)

    assert stand(db_a, aid) == 222
    assert stand(db_b, aid) == 222
    assert db_a.anzahl_ungesendet() == db_b.anzahl_ungesendet() == 0


def test_loeschen_kommt_ueberall_an(geraete):
    (db_a, pb_a), (db_b, pb_b) = geraete
    zid = db_a.zaehler_speichern(name="Wärme", art="waerme", einheit="kWh")
    db_a.ablesung_speichern(zaehler_id=zid, datum=date(2026, 10, 4), stand=42)
    synchronisieren(db_a, pb_a)
    synchronisieren(db_b, pb_b)
    assert db_b.zaehler(zid) is not None

    db_b.zaehler_loeschen(zid)
    synchronisieren(db_b, pb_b)
    synchronisieren(db_a, pb_a)

    assert db_a.zaehler(zid) is None
    assert not [a for a in db_a.alle_ablesungen() if a.zaehler_id == zid]


def test_ohne_anmeldung_keine_daten_und_keine_registrierung():
    pb = PocketBase(URL)
    assert pb.alle("zaehler") == []
    with pytest.raises(ServerFehler) as fehler:
        passwort = "passwort123"
        pb.anlegen(
            "users",
            {"email": "x@y.de", "password": passwort, "passwordConfirm": passwort},
        )
    assert fehler.value.status in (400, 403)
