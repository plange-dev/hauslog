"""Minimaler PocketBase-Client: Anmeldung, Datensätze, Realtime."""

import json
import threading
import time
from collections.abc import Callable
from typing import Any

import httpx


class ServerFehler(Exception):
    """Fehler vom Server. ``status`` ist 0, wenn er nicht erreichbar war."""

    def __init__(self, status: int, nachricht: str):
        super().__init__(nachricht)
        self.status = status
        self.nachricht = nachricht


class PocketBase:
    def __init__(self, url: str, token: str = "", benutzer: dict | None = None):
        self.url = url.rstrip("/")
        self.token = token
        self.benutzer = benutzer or {}
        self._http = httpx.Client(base_url=self.url, timeout=15)

    def schliessen(self) -> None:
        self._http.close()

    @property
    def angemeldet(self) -> bool:
        return bool(self.token)

    def _anfrage(self, methode: str, pfad: str, **kwargs) -> Any:
        kopf = {"Authorization": self.token} if self.token else {}
        try:
            antwort = self._http.request(methode, pfad, headers=kopf, **kwargs)
        except httpx.HTTPError as e:
            raise ServerFehler(0, f"Server nicht erreichbar: {e}") from e
        if antwort.is_error:
            try:
                nachricht = antwort.json().get("message", antwort.text)
            except ValueError:
                nachricht = antwort.text
            raise ServerFehler(antwort.status_code, nachricht)
        return antwort.json() if antwort.content else None

    # ── Anmeldung ───────────────────────────────────────────────────────────

    def _auth_uebernehmen(self, daten: dict) -> None:
        self.token = daten["token"]
        self.benutzer = daten["record"]

    def anmelden(self, email: str, passwort: str, sammlung: str = "users") -> None:
        self._auth_uebernehmen(self._anfrage(
            "POST", f"/api/collections/{sammlung}/auth-with-password",
            json={"identity": email, "password": passwort},
        ))  # fmt: skip

    def anmeldung_verlaengern(self) -> None:
        self._auth_uebernehmen(
            self._anfrage("POST", "/api/collections/users/auth-refresh")
        )

    def abmelden(self) -> None:
        self.token = ""
        self.benutzer = {}

    # ── Datensätze ──────────────────────────────────────────────────────────

    def lesen(self, sammlung: str, id: str) -> dict | None:
        """Ein Datensatz oder ``None``, wenn es ihn nicht gibt."""
        try:
            return self._anfrage("GET", f"/api/collections/{sammlung}/records/{id}")
        except ServerFehler as e:
            if e.status == 404:
                return None
            raise

    def anlegen(self, sammlung: str, daten: dict) -> dict:
        return self._anfrage("POST", f"/api/collections/{sammlung}/records", json=daten)

    def aendern(self, sammlung: str, id: str, daten: dict) -> dict:
        return self._anfrage(
            "PATCH", f"/api/collections/{sammlung}/records/{id}", json=daten
        )

    def alle(self, sammlung: str, *, filter: str = "", sort: str = "") -> list[dict]:
        """Alle Datensätze (seitenweise geholt)."""
        ergebnis: list[dict] = []
        seite = 1
        while True:
            parameter = {"page": seite, "perPage": 500, "skipTotal": 1}
            if filter:
                parameter["filter"] = filter
            if sort:
                parameter["sort"] = sort
            antwort = self._anfrage(
                "GET", f"/api/collections/{sammlung}/records", params=parameter
            )
            ergebnis += antwort["items"]
            if len(antwort["items"]) < 500:
                return ergebnis
            seite += 1

    # ── Realtime ────────────────────────────────────────────────────────────

    def beobachten(
        self, sammlungen: list[str], bei_aenderung: Callable[[], None]
    ) -> Callable[[], None]:
        """Ruft ``bei_aenderung`` (aus einem Hintergrund-Thread) auf, sobald
        sich in einer der Sammlungen etwas ändert. Verbindet sich nach
        Abbrüchen selbst neu. Gibt eine Funktion zum Beenden zurück."""
        stopp = threading.Event()

        def lauf() -> None:
            wartezeit = 2.0
            while not stopp.is_set():
                try:
                    self._realtime(sammlungen, bei_aenderung, stopp)
                    wartezeit = 2.0
                except (httpx.HTTPError, ServerFehler, ValueError, KeyError):
                    pass
                stopp.wait(wartezeit)
                wartezeit = min(wartezeit * 2, 60)

        threading.Thread(target=lauf, name="pocketbase-realtime", daemon=True).start()
        return stopp.set

    def _realtime(
        self,
        sammlungen: list[str],
        bei_aenderung: Callable[[], None],
        stopp: threading.Event,
    ) -> None:
        zeitlimit = httpx.Timeout(15, read=None)
        with (
            httpx.Client(base_url=self.url, timeout=zeitlimit) as http,
            http.stream("GET", "/api/realtime") as strom,
        ):
            strom.raise_for_status()
            ereignis, daten = "", ""
            for zeile in strom.iter_lines():
                if stopp.is_set():
                    return
                if zeile.startswith("event:"):
                    ereignis = zeile[6:].strip()
                elif zeile.startswith("data:"):
                    daten += zeile[5:].strip()
                elif zeile == "":
                    if ereignis == "PB_CONNECT":
                        client_id = json.loads(daten)["clientId"]
                        http.post(
                            "/api/realtime",
                            headers={"Authorization": self.token},
                            json={"clientId": client_id, "subscriptions": [
                                f"{s}/*" for s in sammlungen]},
                        ).raise_for_status()  # fmt: skip
                    elif ereignis:
                        bei_aenderung()
                    ereignis, daten = "", ""


def filter_text(text: str) -> str:
    """Wert für einen PocketBase-Filter in Anführungszeichen setzen."""
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def jetzt_ms() -> int:
    return time.time_ns() // 1_000_000
