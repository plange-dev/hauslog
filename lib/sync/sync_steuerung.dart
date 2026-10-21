import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../zustand.dart';
import 'sync_dienst.dart';

const _urlSchluessel = 'server_url';
const _anmeldungSchluessel = 'server_anmeldung';

/// Wie oft ohne äußeren Anlass abgeglichen wird.
const _intervall = Duration(minutes: 2);

/// Wartezeit nach einer lokalen Änderung, damit mehrere schnelle Änderungen
/// in einem Abgleich landen.
const _verzoegerung = Duration(seconds: 3);

class SyncZustand {
  const SyncZustand({
    this.serverUrl = '',
    this.benutzer,
    this.laeuft = false,
    this.letzterErfolg,
    this.fehler,
  });

  final String serverUrl;

  /// E-Mail des angemeldeten Benutzers, `null` wenn nicht angemeldet.
  final String? benutzer;
  final bool laeuft;
  final DateTime? letzterErfolg;
  final String? fehler;

  bool get angemeldet => benutzer != null;

  SyncZustand mit({
    String? serverUrl,
    String? Function()? benutzer,
    bool? laeuft,
    DateTime? letzterErfolg,
    String? Function()? fehler,
  }) => SyncZustand(
    serverUrl: serverUrl ?? this.serverUrl,
    benutzer: benutzer != null ? benutzer() : this.benutzer,
    laeuft: laeuft ?? this.laeuft,
    letzterErfolg: letzterErfolg ?? this.letzterErfolg,
    fehler: fehler != null ? fehler() : this.fehler,
  );
}

final syncProvider = NotifierProvider<SyncSteuerung, SyncZustand>(
  SyncSteuerung.new,
);

/// Hält die Verbindung zum Server und stößt Abgleiche an.
///
/// Ohne Anmeldung arbeitet die App rein lokal; nichts geht verloren.
class SyncSteuerung extends Notifier<SyncZustand> {
  PocketBase? _pb;
  Timer? _intervallTimer;
  Timer? _verzoegerungTimer;
  ProviderSubscription<AsyncValue<int>>? _ungesendet;
  final _abmeldungen = <Future<void> Function()>[];
  var _nochmal = false;

  @override
  SyncZustand build() {
    ref.onDispose(_stoppen);
    final prefs = ref.read(einstellungenProvider);
    final url = prefs.getString(_urlSchluessel) ?? '';
    if (url.isEmpty) return const SyncZustand();

    final pb = _pb = _clientErstellen(url);
    if (!pb.authStore.isValid) return SyncZustand(serverUrl: url);

    Future.microtask(_starten);
    return SyncZustand(serverUrl: url, benutzer: _email(pb));
  }

  PocketBase _clientErstellen(String url) {
    final prefs = ref.read(einstellungenProvider);
    return PocketBase(
      url,
      authStore: AsyncAuthStore(
        save: (daten) => prefs.setString(_anmeldungSchluessel, daten),
        clear: () => prefs.remove(_anmeldungSchluessel),
        initial: prefs.getString(_anmeldungSchluessel),
      ),
    );
  }

  static String? _email(PocketBase pb) =>
      pb.authStore.record?.getStringValue('email');

  /// Meldet sich an. Wirft bei falschen Zugangsdaten oder ohne Verbindung.
  Future<void> anmelden({
    required String url,
    required String email,
    required String passwort,
  }) async {
    url = url.trim().replaceFirst(RegExp(r'/+$'), '');
    _stoppen();
    final pb = _clientErstellen(url);
    await pb.collection('users').authWithPassword(email.trim(), passwort);

    final prefs = ref.read(einstellungenProvider);
    if (prefs.getString(_urlSchluessel) != url) {
      // Neuer Server: alles einmal komplett hoch- und herunterladen.
      await ref.read(datenbankProvider).syncZuruecksetzen();
      await prefs.setString(_urlSchluessel, url);
    }
    _pb = pb;
    state = SyncZustand(serverUrl: url, benutzer: _email(pb));
    await _starten();
  }

  void abmelden() {
    _stoppen();
    _pb?.authStore.clear();
    state = SyncZustand(serverUrl: state.serverUrl);
  }

  Future<void> _starten() async {
    final pb = _pb;
    if (pb == null || !pb.authStore.isValid) return;

    _intervallTimer = Timer.periodic(_intervall, (_) => jetztAbgleichen());

    // Lokale Änderungen kurz danach senden.
    _ungesendet = ref.listen(ungesendetProvider, (_, anzahl) {
      if ((anzahl.value ?? 0) > 0) _baldAbgleichen();
    });

    // Änderungen anderer Benutzer sofort holen.
    for (final sammlung in ['zaehler', 'ablesungen']) {
      try {
        _abmeldungen.add(
          await pb
              .collection(sammlung)
              .subscribe('*', (_) => _baldAbgleichen()),
        );
      } on ClientException {
        // Offline – der Intervall-Abgleich übernimmt.
      }
    }

    // Anmeldung verlängern, solange der Server erreichbar ist.
    try {
      await pb.collection('users').authRefresh();
    } on ClientException catch (e) {
      if (e.statusCode == 401) {
        abmelden();
        return;
      }
    }
    await jetztAbgleichen();
  }

  void _stoppen() {
    _intervallTimer?.cancel();
    _verzoegerungTimer?.cancel();
    _ungesendet?.close();
    _ungesendet = null;
    for (final abmelden in _abmeldungen) {
      abmelden().ignore();
    }
    _abmeldungen.clear();
  }

  void _baldAbgleichen() {
    _verzoegerungTimer?.cancel();
    _verzoegerungTimer = Timer(_verzoegerung, jetztAbgleichen);
  }

  Future<void> jetztAbgleichen() async {
    final pb = _pb;
    if (pb == null || !state.angemeldet) return;
    if (state.laeuft) {
      _nochmal = true;
      return;
    }

    state = state.mit(laeuft: true);
    try {
      await SyncDienst(ref.read(datenbankProvider), pb).synchronisieren();
      state = state.mit(
        laeuft: false,
        letzterErfolg: DateTime.now(),
        fehler: () => null,
      );
    } on ClientException catch (e) {
      state = state.mit(laeuft: false, fehler: () => _fehlertext(e));
      if (e.statusCode == 401) abmelden();
    } catch (e) {
      state = state.mit(
        laeuft: false,
        fehler: () => 'Abgleich fehlgeschlagen: $e',
      );
    }

    if (_nochmal) {
      _nochmal = false;
      _baldAbgleichen();
    }
  }

  static String _fehlertext(ClientException e) => switch (e.statusCode) {
    0 => 'Server nicht erreichbar – Änderungen bleiben lokal gespeichert.',
    401 => 'Anmeldung abgelaufen – bitte neu anmelden.',
    403 => 'Keine Berechtigung auf dem Server.',
    _ => 'Serverfehler ${e.statusCode}: ${e.response['message'] ?? e}',
  };
}
