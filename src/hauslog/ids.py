"""IDs und Datumsformat, kompatibel zu PocketBase."""

import secrets
import string
from datetime import date

_ZEICHEN = string.ascii_lowercase + string.digits


def neue_id() -> str:
    """Neue Datensatz-ID im PocketBase-Format (15 Zeichen, a–z und 0–9).

    Die App vergibt IDs selbst, damit Datensätze offline angelegt und später
    ohne Umschlüsseln zum Server übertragen werden können.
    """
    return "".join(secrets.choice(_ZEICHEN) for _ in range(15))


def datum_text(d: date) -> str:
    """Datum als ``JJJJ-MM-TT``, so wie es in Datenbank und Server steht."""
    return d.isoformat()


def datum_aus_text(s: str) -> date:
    return date.fromisoformat(s)
