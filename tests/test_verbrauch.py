from datetime import date

import pytest

from hauslog.verbrauch import Messpunkt, abschnitte_berechnen, verbrauch_im_jahr


def p(datum: str, stand: float) -> Messpunkt:
    return Messpunkt(date.fromisoformat(datum), stand)


def test_abschnitte_sind_differenzen_aufeinanderfolgender_staende():
    a = abschnitte_berechnen(
        [p("2026-03-01", 1300), p("2026-01-01", 1000), p("2026-02-01", 1124)]
    )
    assert [x.verbrauch for x in a] == [124, 176]
    assert a[0].tage == 31
    assert a[0].pro_tag == pytest.approx(4)


def test_fallender_stand_ergibt_keinen_verbrauch():
    (a,) = abschnitte_berechnen([p("2026-01-01", 500), p("2026-02-01", 3)])
    assert a.verbrauch is None
    assert a.pro_tag is None


def test_jahresverbrauch_teilt_ueber_jahresgrenze_anteilig():
    a = abschnitte_berechnen([
        p("2025-12-22", 0),
        p("2026-01-11", 200),  # 20 Tage, davon 10 in 2026
        p("2026-02-10", 500),
    ])  # fmt: skip
    assert verbrauch_im_jahr(a, 2026) == pytest.approx(100 + 300)
    assert verbrauch_im_jahr(a, 2025) == pytest.approx(100)
