"""Hält die Verbindung zum Server und stößt Abgleiche an.

Ohne Anmeldung arbeitet die App rein lokal; nichts geht verloren.
Alle Netzwerkzugriffe laufen in einem eigenen Thread mit eigener
Datenbankverbindung, damit die Oberfläche nie blockiert.

Abgeglichen wird beim Start, alle 2 Minuten, kurz nach jeder lokalen
Änderung und sofort, wenn ein anderer Benutzer etwas ändert.
"""

from dataclasses import dataclass, replace
from datetime import datetime

from PySide6.QtCore import QObject, QThread, QTimer, Signal, Slot

from .daten import Datenbank
from .pfade import Einstellungen
from .pocketbase import PocketBase, ServerFehler
from .sync import SyncErgebnis, synchronisieren

INTERVALL_MS = 2 * 60 * 1000
VERZOEGERUNG_MS = 3000


@dataclass(frozen=True)
class SyncZustand:
    server_url: str = ""
    benutzer: str | None = None
    """E-Mail des angemeldeten Benutzers, ``None`` wenn nicht angemeldet."""
    laeuft: bool = False
    letzter_erfolg: datetime | None = None
    fehler: str | None = None

    @property
    def angemeldet(self) -> bool:
        return self.benutzer is not None


def fehlertext(e: Exception) -> str:
    if not isinstance(e, ServerFehler):
        return f"Abgleich fehlgeschlagen: {e}"
    return {
        0: "Server nicht erreichbar – Änderungen bleiben lokal gespeichert.",
        401: "Anmeldung abgelaufen – bitte neu anmelden.",
        403: "Keine Berechtigung auf dem Server.",
    }.get(e.status, f"Serverfehler {e.status}: {e.nachricht}")


class _Arbeiter(QObject):
    """Lebt im Sync-Thread."""

    angemeldet = Signal(object, object)  # (PocketBase | None, Fehler | None)
    abgeglichen = Signal(object, object)  # (SyncErgebnis | None, Fehler | None)
    entfernt_geaendert = Signal()

    def __init__(self, db_pfad: str):
        super().__init__()
        self._db_pfad = db_pfad
        self._db: Datenbank | None = None
        self._pb: PocketBase | None = None
        self._realtime_beenden = None

    def _verbindung_setzen(self, pb: PocketBase | None) -> None:
        if self._realtime_beenden:
            self._realtime_beenden()
            self._realtime_beenden = None
        self._pb = pb
        if pb:
            self._realtime_beenden = pb.beobachten(
                ["zaehler", "ablesungen"], self.entfernt_geaendert.emit
            )

    @Slot(str, str, str)
    def anmelden(self, url: str, email: str, passwort: str) -> None:
        pb = PocketBase(url)
        try:
            pb.anmelden(email, passwort)
        except ServerFehler as e:
            self.angemeldet.emit(None, e)
            return
        self._verbindung_setzen(pb)
        self.angemeldet.emit(pb, None)

    @Slot(str, str, object)
    def verbinden(self, url: str, token: str, benutzer: dict) -> None:
        """Gespeicherte Anmeldung wieder aufnehmen und – wenn erreichbar –
        verlängern. Offline bleibt die alte Anmeldung gültig."""
        pb = PocketBase(url, token, benutzer)
        try:
            pb.anmeldung_verlaengern()
        except ServerFehler as e:
            if e.status in (401, 403):
                self.angemeldet.emit(None, e)
                return
        self._verbindung_setzen(pb)
        self.angemeldet.emit(pb, None)

    @Slot()
    def trennen(self) -> None:
        self._verbindung_setzen(None)

    @Slot()
    def abgleichen(self) -> None:
        if not self._pb:
            return
        if self._db is None:
            self._db = Datenbank(self._db_pfad)
        try:
            self.abgeglichen.emit(synchronisieren(self._db, self._pb), None)
        except Exception as e:  # noqa: BLE001 – jeder Fehler landet in der Anzeige
            self.abgeglichen.emit(None, e)


class SyncSteuerung(QObject):
    zustand_geaendert = Signal(object)  # SyncZustand
    daten_empfangen = Signal()
    anmeldung_fertig = Signal(object)  # Fehlertext oder None

    _anmelden = Signal(str, str, str)
    _verbinden = Signal(str, str, object)
    _trennen = Signal()
    _abgleichen = Signal()

    def __init__(self, db: Datenbank, einstellungen: Einstellungen):
        super().__init__()
        self._db = db
        self._einstellungen = einstellungen
        self._nochmal = False
        self.zustand = SyncZustand(server_url=einstellungen.get("server_url", ""))

        self._thread = QThread()
        self._thread.setObjectName("hauslog-sync")
        self._arbeiter = _Arbeiter(db.pfad)
        self._arbeiter.moveToThread(self._thread)
        self._anmelden.connect(self._arbeiter.anmelden)
        self._verbinden.connect(self._arbeiter.verbinden)
        self._trennen.connect(self._arbeiter.trennen)
        self._abgleichen.connect(self._arbeiter.abgleichen)
        self._arbeiter.angemeldet.connect(self._bei_anmeldung)
        self._arbeiter.abgeglichen.connect(self._bei_abgleich)
        self._arbeiter.entfernt_geaendert.connect(self.bald_abgleichen)
        self._thread.start()

        self._intervall = QTimer(self, interval=INTERVALL_MS)
        self._intervall.timeout.connect(self.jetzt_abgleichen)
        self._verzoegerung = QTimer(self, singleShot=True, interval=VERZOEGERUNG_MS)
        self._verzoegerung.timeout.connect(self.jetzt_abgleichen)

        # Lokale Änderungen kurz danach senden.
        db.beobachten(self.bald_abgleichen)

        auth = einstellungen.get("anmeldung")
        if self.zustand.server_url and auth:
            self._setzen(benutzer=auth["benutzer"].get("email", ""))
            self._verbinden.emit(self.zustand.server_url, auth["token"], auth["benutzer"])

    def beenden(self) -> None:
        self._trennen.emit()
        self._thread.quit()
        self._thread.wait(3000)

    def _setzen(self, **aenderungen) -> None:
        self.zustand = replace(self.zustand, **aenderungen)
        self.zustand_geaendert.emit(self.zustand)

    # ── Anmeldung ───────────────────────────────────────────────────────────

    def anmelden(self, url: str, email: str, passwort: str) -> None:
        """Ergebnis kommt über ``anmeldung_fertig``."""
        url = url.strip().rstrip("/")
        self._neue_url = url
        self._anmelden.emit(url, email.strip(), passwort)

    def abmelden(self) -> None:
        self._trennen.emit()
        self._intervall.stop()
        self._einstellungen.setzen(anmeldung=None)
        self._setzen(benutzer=None, fehler=None)

    @Slot(object, object)
    def _bei_anmeldung(self, pb: PocketBase | None, fehler: ServerFehler | None) -> None:
        neue_url = getattr(self, "_neue_url", None)
        self._neue_url = None
        if pb is None:
            if neue_url is None:
                # Gespeicherte Anmeldung ist abgelaufen.
                self.abmelden()
                self._setzen(fehler=fehlertext(fehler))
            self.anmeldung_fertig.emit(_anmeldefehler(fehler))
            return

        if neue_url is not None and neue_url != self._einstellungen.get("server_url"):
            # Neuer Server: alles einmal komplett hoch- und herunterladen.
            self._db.sync_zuruecksetzen()
        self._einstellungen.setzen(
            server_url=pb.url, anmeldung={"token": pb.token, "benutzer": pb.benutzer}
        )
        self._setzen(
            server_url=pb.url, benutzer=pb.benutzer.get("email", ""), fehler=None
        )
        self._intervall.start()
        self.anmeldung_fertig.emit(None)
        self.jetzt_abgleichen()

    # ── Abgleich ────────────────────────────────────────────────────────────

    @Slot()
    def bald_abgleichen(self) -> None:
        if self.zustand.angemeldet:
            self._verzoegerung.start()

    @Slot()
    def jetzt_abgleichen(self) -> None:
        if not self.zustand.angemeldet:
            return
        if self.zustand.laeuft:
            self._nochmal = True
            return
        self._setzen(laeuft=True)
        self._abgleichen.emit()

    @Slot(object, object)
    def _bei_abgleich(
        self, ergebnis: SyncErgebnis | None, fehler: Exception | None
    ) -> None:
        if fehler is None:
            self._setzen(laeuft=False, letzter_erfolg=datetime.now(), fehler=None)
        else:
            self._setzen(laeuft=False, fehler=fehlertext(fehler))
            if isinstance(fehler, ServerFehler) and fehler.status == 401:
                self.abmelden()
        if ergebnis and (ergebnis.empfangen or ergebnis.gesendet):
            self.daten_empfangen.emit()
        if self._nochmal:
            self._nochmal = False
            self.bald_abgleichen()


def _anmeldefehler(e: ServerFehler | None) -> str | None:
    if e is None:
        return None
    if e.status == 0:
        return "Server nicht erreichbar. Adresse und Netzwerk prüfen."
    if e.status == 400:
        return "E-Mail oder Passwort falsch."
    return f"Anmeldung fehlgeschlagen ({e.status}): {e.nachricht}"
