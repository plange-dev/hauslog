import os
from datetime import date

import pytest
from PySide6.QtCore import QDate

from hauslog.daten import Datenbank
from hauslog.ids import neue_id
from hauslog.pfade import Einstellungen
from hauslog.pocketbase import PocketBase
from hauslog.sync_steuerung import SyncSteuerung
from hauslog.ui import zaehler_detail
from hauslog.ui.dialoge import AblesungDialog, ZaehlerDialog
from hauslog.ui.einstellungen import EinstellungenDialog
from hauslog.ui.hauptfenster import Hauptfenster


@pytest.fixture
def db(tmp_path):
    datenbank = Datenbank(tmp_path / "hauslog.db")
    yield datenbank
    datenbank.schliessen()


@pytest.fixture
def sync(db, tmp_path):
    steuerung = SyncSteuerung(db, Einstellungen(tmp_path / "einstellungen.json"))
    yield steuerung
    steuerung.beenden()


@pytest.fixture
def fenster(qtbot, db, sync):
    f = Hauptfenster(db, sync)
    qtbot.addWidget(f)
    return f


def strom_mit_zwei_ablesungen(db: Datenbank) -> str:
    zid = db.zaehler_speichern(name="Strom Haus", art="strom", einheit="kWh")
    db.ablesung_speichern(zaehler_id=zid, datum=date(2026, 1, 1), stand=1000)
    db.ablesung_speichern(zaehler_id=zid, datum=date(2026, 2, 1), stand=1124.5)
    return zid


def test_leere_app_zeigt_hinweis_und_offline_status(fenster):
    assert fenster.liste.count() == 0
    assert "Noch keine Zähler" in fenster.leer_text.text()
    assert fenster.sync_knopf.text() == "☁ Nur lokal"
    assert not fenster.ablesung.isEnabled()


def test_zaehler_mit_ablesungen_zeigt_stand_und_verbrauch(fenster, db):
    strom_mit_zwei_ablesungen(db)
    assert fenster.liste.count() == 1
    assert "1.124,5 kWh · 01.02.2026" in fenster.liste.item(0).text()

    detail = fenster.detail
    assert detail.k_stand.wert.text() == "1.124,5 kWh"
    assert detail.tabelle.rowCount() == 2
    assert detail.tabelle.item(0, 2).text() == "+124,5 kWh"
    assert detail.tabelle.item(0, 3).text() == "31"
    assert fenster.ablesung.isEnabled()


def test_zaehler_ueber_dialog_anlegen(fenster, db):
    dialog = ZaehlerDialog(db, fenster)
    dialog.art.setCurrentIndex(3)  # Gas → Einheit wechselt mit
    dialog.name.setText("Gas Keller")
    dialog.accept()

    (z,) = db.alle_zaehler()
    assert (z.name, z.art, z.einheit, z.ungesendet) == ("Gas Keller", "gas", "m³", True)
    assert "Gas Keller" in fenster.liste.item(0).text()


def test_ablesung_dialog_warnt_bei_kleinerem_stand_und_liest_deutsche_zahl(fenster, db):
    zid = strom_mit_zwei_ablesungen(db)
    dialog = AblesungDialog(db, fenster, db.zaehler(zid), vorheriger=1124.5)
    dialog.stand.setText("900")
    assert not dialog.hinweis.isHidden()
    dialog.stand.setText("1.300,5")
    assert dialog.hinweis.isHidden()
    dialog.datum.setDate(QDate(2026, 3, 1))
    dialog.accept()

    neueste = db.ablesungen(zid)[0]
    assert (neueste.datum, neueste.stand) == ("2026-03-01", 1300.5)
    assert fenster.detail.tabelle.item(0, 2).text() == "+176 kWh"


def test_zaehler_loeschen_waehlt_naechsten(fenster, db, monkeypatch):
    strom_mit_zwei_ablesungen(db)
    db.zaehler_speichern(name="Wasser", art="wasser", einheit="m³")
    fenster.liste.setCurrentRow(0)
    monkeypatch.setattr(zaehler_detail, "loeschen_bestaetigen", lambda *_: True)

    fenster.detail._zaehler_loeschen()

    assert fenster.liste.count() == 1
    assert "Wasser" in fenster.detail.titel.text()


def test_einstellungen_loesen_beobachter_beim_schliessen(fenster, db, sync):
    vorher = len(db._beobachter)
    dialog = EinstellungenDialog(db, sync, fenster)
    assert len(db._beobachter) == vorher + 1
    dialog.reject()
    assert len(db._beobachter) == vorher
    db.zaehler_speichern(name="x", art="strom", einheit="kWh")  # darf nicht abstürzen


def test_fenster_bild(fenster, db, tmp_path):
    """Rendert das Fenster einmal komplett (fängt Fehler beim Zeichnen)."""
    strom_mit_zwei_ablesungen(db)
    fenster.show()
    assert not fenster.grab().isNull()


@pytest.mark.skipif(not os.environ.get("PB_URL"), reason="PB_URL nicht gesetzt")
def test_sync_steuerung_meldet_an_und_gleicht_im_hintergrund_ab(qtbot, db, sync):
    admin = PocketBase(os.environ["PB_URL"])
    admin.anmelden(os.environ["PB_ADMIN"], os.environ["PB_ADMIN_PASSWORT"], "_superusers")
    email = f"ui-{neue_id()}@test.local"
    admin.anlegen(
        "users",
        {"email": email, "password": "passwort123", "passwordConfirm": "passwort123"},
    )

    with qtbot.waitSignal(sync.anmeldung_fertig, timeout=10000) as signal:
        sync.anmelden(os.environ["PB_URL"], email, "passwort123")
    assert signal.args == [None]
    assert sync.zustand.benutzer == email

    zid = db.zaehler_speichern(name="Über die Oberfläche", art="strom", einheit="kWh")
    qtbot.waitUntil(lambda: db.anzahl_ungesendet() == 0, timeout=15000)
    assert sync.zustand.fehler is None
    assert admin.lesen("zaehler", zid)["name"] == "Über die Oberfläche"
