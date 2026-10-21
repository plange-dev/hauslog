"""Vorlagen für Zählerarten.

Gespeichert wird nur der Name (z. B. ``strom``); Einheit und Bezeichnung des
Zählers sind frei änderbar.
"""

from enum import Enum


class ZaehlerArt(Enum):
    #          Bezeichnung       Einheit  Symbol  Farbe
    STROM = ("Strom", "kWh", "⚡", "#F4A261")
    WASSER = ("Wasser", "m³", "💧", "#457B9D")
    WARMWASSER = ("Warmwasser", "m³", "♨", "#E76F51")
    GAS = ("Gas", "m³", "🔥", "#52B788")
    WAERME = ("Wärme", "kWh", "🌡", "#D62828")
    HEIZOEL = ("Heizöl", "l", "🛢", "#6D597A")
    EINSPEISUNG = ("PV-Einspeisung", "kWh", "☀", "#E9C46A")
    SONSTIGES = ("Sonstiges", "", "⏲", "#8D99AE")

    def __init__(self, label: str, einheit: str, symbol: str, farbe: str):
        self.label = label
        self.einheit = einheit
        self.symbol = symbol
        self.farbe = farbe

    @property
    def schluessel(self) -> str:
        """Wert, der in Datenbank und Server steht (wie in der Flutter-App)."""
        return self.name.lower()

    @classmethod
    def aus_schluessel(cls, schluessel: str) -> "ZaehlerArt":
        try:
            return cls[schluessel.upper()]
        except KeyError:
            return cls.SONSTIGES
