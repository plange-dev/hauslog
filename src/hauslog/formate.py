"""Deutsche Anzeige von Zahlen und Datum."""

from datetime import date, datetime


def datum_anzeige(d: date | str) -> str:
    if isinstance(d, str):
        d = date.fromisoformat(d)
    return d.strftime("%d.%m.%Y")


def zeit_anzeige(d: datetime) -> str:
    return d.strftime("%d.%m.%Y %H:%M")


def zahl_anzeige(v: float) -> str:
    """Bis zu drei Nachkommastellen, Tausenderpunkt: ``1.234,5``."""
    text = f"{v:,.3f}".rstrip("0").rstrip(".")
    return text.replace(",", "\x00").replace(".", ",").replace("\x00", ".")


def mit_einheit(v: float, einheit: str) -> str:
    return f"{zahl_anzeige(v)} {einheit}" if einheit else zahl_anzeige(v)


def zahl_lesen(text: str) -> float | None:
    """Liest Zahlen wie ``1234,5``, ``1.234,5`` oder ``1234.5``."""
    t = text.strip().replace(" ", "")
    if "," in t:
        t = t.replace(".", "").replace(",", ".")
    try:
        return float(t)
    except ValueError:
        return None
