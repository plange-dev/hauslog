import 'package:pocketbase/pocketbase.dart';

import '../daten/datenbank.dart';

/// Ergebnis eines Abgleichs.
class SyncErgebnis {
  const SyncErgebnis({required this.gesendet, required this.empfangen});

  final int gesendet;
  final int empfangen;
}

/// Gleicht die lokale Datenbank mit PocketBase ab.
///
/// Ablauf:
/// 1. Lokal geänderte Datensätze senden (Zähler vor Ablesungen). Ist der
///    Stand auf dem Server neuer, wird stattdessen dieser übernommen.
/// 2. Alles holen, was sich auf dem Server seit dem letzten Abruf geändert
///    hat. Lokal ungesendete, neuere Änderungen bleiben dabei erhalten.
///
/// Konflikte entscheidet `geaendert_am`: der neuere Stand gewinnt.
class SyncDienst {
  SyncDienst(this.db, this.pb);

  final HauslogDatenbank db;
  final PocketBase pb;

  late final _tabellen = <_SyncTabelle<Object>>[
    _SyncTabelle<Zaehler>(
      sammlung: 'zaehler',
      ungesendet: db.ungesendeteZaehler,
      alsServerDaten: (z) => {
        'name': z.name,
        'art': z.art,
        'einheit': z.einheit,
        'zaehlernummer': z.zaehlernummer,
        'notiz': z.notiz,
        'geaendert_am': z.geaendertAm,
        'geloescht': z.geloescht,
      },
      ausServerDaten: (r) => Zaehler(
        id: r.id,
        name: r.getStringValue('name'),
        art: r.getStringValue('art'),
        einheit: r.getStringValue('einheit'),
        zaehlernummer: r.getStringValue('zaehlernummer'),
        notiz: r.getStringValue('notiz'),
        geaendertAm: r.getIntValue('geaendert_am'),
        geloescht: r.getBoolValue('geloescht'),
        ungesendet: false,
      ),
      idVon: (z) => z.id,
      zeitVon: (z) => z.geaendertAm,
      gesendet: db.zaehlerGesendet,
      uebernehmen: db.zaehlerVomServer,
    ),
    _SyncTabelle<Ablesung>(
      sammlung: 'ablesungen',
      ungesendet: db.ungesendeteAblesungen,
      alsServerDaten: (a) => {
        'zaehler': a.zaehlerId,
        'datum': a.datum,
        'stand': a.stand,
        'notiz': a.notiz,
        'geaendert_am': a.geaendertAm,
        'geloescht': a.geloescht,
      },
      ausServerDaten: (r) => Ablesung(
        id: r.id,
        zaehlerId: r.getStringValue('zaehler'),
        datum: r.getStringValue('datum'),
        stand: r.getDoubleValue('stand'),
        notiz: r.getStringValue('notiz'),
        geaendertAm: r.getIntValue('geaendert_am'),
        geloescht: r.getBoolValue('geloescht'),
        ungesendet: false,
      ),
      idVon: (a) => a.id,
      zeitVon: (a) => a.geaendertAm,
      gesendet: db.ablesungGesendet,
      uebernehmen: db.ablesungVomServer,
    ),
  ];

  Future<SyncErgebnis> synchronisieren() async {
    var gesendet = 0;
    var empfangen = 0;
    for (final t in _tabellen) {
      gesendet += await t.senden(pb);
    }
    for (final t in _tabellen) {
      empfangen += await t.holen(pb, db);
    }
    return SyncErgebnis(gesendet: gesendet, empfangen: empfangen);
  }
}

class _SyncTabelle<T extends Object> {
  _SyncTabelle({
    required this.sammlung,
    required this.ungesendet,
    required this.alsServerDaten,
    required this.ausServerDaten,
    required this.idVon,
    required this.zeitVon,
    required this.gesendet,
    required this.uebernehmen,
  });

  final String sammlung;
  final Future<List<T>> Function() ungesendet;
  final Map<String, dynamic> Function(T) alsServerDaten;
  final T Function(RecordModel) ausServerDaten;
  final String Function(T) idVon;
  final int Function(T) zeitVon;
  final Future<void> Function(String id, int geaendertAm) gesendet;
  final Future<void> Function(T) uebernehmen;

  String get _cursorSchluessel => 'cursor_$sammlung';

  Future<int> senden(PocketBase pb) async {
    final dienst = pb.collection(sammlung);
    var anzahl = 0;
    for (final lokal in await ungesendet()) {
      final id = idVon(lokal);
      final daten = alsServerDaten(lokal);

      RecordModel? entfernt;
      try {
        entfernt = await dienst.getOne(id);
      } on ClientException catch (e) {
        if (e.statusCode != 404) rethrow;
      }

      if (entfernt == null) {
        await dienst.create(body: {...daten, 'id': id});
      } else if (entfernt.getIntValue('geaendert_am') > zeitVon(lokal)) {
        // Auf dem Server liegt eine neuere Änderung – die gewinnt.
        await uebernehmen(ausServerDaten(entfernt));
        continue;
      } else {
        await dienst.update(id, body: daten);
      }
      await gesendet(id, zeitVon(lokal));
      anzahl++;
    }
    return anzahl;
  }

  Future<int> holen(PocketBase pb, HauslogDatenbank db) async {
    final cursor = await db.syncWert(_cursorSchluessel);
    // `>=` statt `>`: mehrere Änderungen können denselben Zeitstempel haben.
    // Doppelt übernommene Datensätze schaden nicht.
    final datensaetze = await pb
        .collection(sammlung)
        .getFullList(
          sort: 'updated',
          filter: cursor == null
              ? null
              : pb.filter('updated >= {:cursor}', {'cursor': cursor}),
        );
    for (final r in datensaetze) {
      await uebernehmen(ausServerDaten(r));
    }
    if (datensaetze.isNotEmpty) {
      await db.syncWertSetzen(
        _cursorSchluessel,
        datensaetze.last.getStringValue('updated'),
      );
    }
    return datensaetze.length;
  }
}
