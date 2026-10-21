"""Verbrauchsberechnung aus Zählerständen.

Ein Zähler zählt nur hoch. Der Verbrauch eines Zeitraums ist deshalb die
Differenz zweier aufeinanderfolgender Ablesungen. Fällt der Stand, wurde sehr
wahrscheinlich der Zähler getauscht – dieser Abschnitt hat dann keinen
sinnvollen Verbrauch.
"""

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from itertools import pairwise


@dataclass(frozen=True)
class Messpunkt:
    datum: date
    stand: float


@dataclass(frozen=True)
class Verbrauchsabschnitt:
    von: date
    bis: date
    verbrauch: float | None
    """``None``, wenn der Stand gefallen ist (Zählertausch o. ä.)."""

    @property
    def tage(self) -> int:
        return (self.bis - self.von).days

    @property
    def pro_tag(self) -> float | None:
        if self.verbrauch is None or self.tage <= 0:
            return None
        return self.verbrauch / self.tage


def abschnitte_berechnen(punkte: Iterable[Messpunkt]) -> list[Verbrauchsabschnitt]:
    """Abschnitte zwischen aufeinanderfolgenden Ablesungen, älteste zuerst."""
    sortiert = sorted(punkte, key=lambda p: p.datum)
    return [
        Verbrauchsabschnitt(
            von=vorher.datum,
            bis=nachher.datum,
            verbrauch=nachher.stand - vorher.stand
            if nachher.stand >= vorher.stand
            else None,
        )
        for vorher, nachher in pairwise(sortiert)
    ]


def verbrauch_im_jahr(abschnitte: Iterable[Verbrauchsabschnitt], jahr: int) -> float:
    """Verbrauch innerhalb eines Kalenderjahres.

    Abschnitte, die über die Jahresgrenze reichen, werden anteilig nach Tagen
    aufgeteilt.
    """
    beginn, ende = date(jahr, 1, 1), date(jahr + 1, 1, 1)
    summe = 0.0
    for a in abschnitte:
        if a.verbrauch is None or a.tage <= 0:
            continue
        tage_im_jahr = (min(a.bis, ende) - max(a.von, beginn)).days
        if tage_im_jahr > 0:
            summe += a.verbrauch * tage_im_jahr / a.tage
    return summe
