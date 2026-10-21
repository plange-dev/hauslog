import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'ids.dart';

part 'datenbank.g.dart';

/// Spalten, die jeder synchronisierte Datensatz braucht.
mixin SyncSpalten on Table {
  TextColumn get id => text()();

  /// Zeitpunkt der letzten Änderung (ms seit 1970). Bei Konflikten gewinnt
  /// der neuere Stand.
  IntColumn get geaendertAm => integer()();

  /// Gelöscht wird nur weich, damit die Löschung auch synchronisiert wird.
  BoolColumn get geloescht => boolean().withDefault(const Constant(false))();

  /// Lokal geändert und noch nicht zum Server übertragen.
  BoolColumn get ungesendet => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Zaehler')
class ZaehlerTabelle extends Table with SyncSpalten {
  @override
  String get tableName => 'zaehler';

  TextColumn get name => text()();
  TextColumn get art => text()();
  TextColumn get einheit => text()();
  TextColumn get zaehlernummer => text().withDefault(const Constant(''))();
  TextColumn get notiz => text().withDefault(const Constant(''))();
}

@DataClassName('Ablesung')
class Ablesungen extends Table with SyncSpalten {
  TextColumn get zaehlerId => text()();

  /// `JJJJ-MM-TT`
  TextColumn get datum => text()();
  RealColumn get stand => real()();
  TextColumn get notiz => text().withDefault(const Constant(''))();
}

/// Schlüssel/Wert-Speicher für den Sync-Stand (z. B. letzter Abrufzeitpunkt).
class SyncStatus extends Table {
  TextColumn get schluessel => text()();
  TextColumn get wert => text()();

  @override
  Set<Column> get primaryKey => {schluessel};
}

@DriftDatabase(tables: [ZaehlerTabelle, Ablesungen, SyncStatus])
class HauslogDatenbank extends _$HauslogDatenbank {
  HauslogDatenbank([QueryExecutor? executor]) : super(executor ?? _oeffnen());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_ablesungen_zaehler ON ablesungen (zaehler_id, datum)',
      );
    },
  );

  static QueryExecutor _oeffnen() => driftDatabase(
    name: 'hauslog',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  static int _jetzt() => DateTime.now().millisecondsSinceEpoch;

  // ── Zähler ────────────────────────────────────────────────────────────────

  Stream<List<Zaehler>> zaehlerBeobachten() =>
      (select(zaehlerTabelle)
            ..where((z) => z.geloescht.not())
            ..orderBy([(z) => OrderingTerm(expression: z.name)]))
          .watch();

  Stream<Zaehler?> einenZaehlerBeobachten(String id) => (select(
    zaehlerTabelle,
  )..where((z) => z.id.equals(id) & z.geloescht.not())).watchSingleOrNull();

  /// Legt einen Zähler an (ohne [id]) oder ändert ihn. Gibt die ID zurück.
  Future<String> zaehlerSpeichern({
    String? id,
    required String name,
    required String art,
    required String einheit,
    String zaehlernummer = '',
    String notiz = '',
  }) async {
    final zeile = ZaehlerTabelleCompanion.insert(
      id: id ?? neueId(),
      name: name,
      art: art,
      einheit: einheit,
      zaehlernummer: Value(zaehlernummer),
      notiz: Value(notiz),
      geaendertAm: _jetzt(),
      ungesendet: const Value(true),
    );
    await into(zaehlerTabelle).insertOnConflictUpdate(zeile);
    return zeile.id.value;
  }

  /// Löscht den Zähler samt seinen Ablesungen.
  Future<void> zaehlerLoeschen(String id) => transaction(() async {
    final aenderung = _loeschMarkierung();
    await (update(zaehlerTabelle)..where((z) => z.id.equals(id))).write(
      ZaehlerTabelleCompanion(
        geloescht: aenderung.geloescht,
        geaendertAm: aenderung.geaendertAm,
        ungesendet: aenderung.ungesendet,
      ),
    );
    await (update(ablesungen)
          ..where((a) => a.zaehlerId.equals(id) & a.geloescht.not()))
        .write(aenderung);
  });

  // ── Ablesungen ────────────────────────────────────────────────────────────

  /// Alle Ablesungen eines Zählers, neueste zuerst.
  Stream<List<Ablesung>> ablesungenBeobachten(String zaehlerId) =>
      (select(ablesungen)
            ..where((a) => a.zaehlerId.equals(zaehlerId) & a.geloescht.not())
            ..orderBy([
              (a) => OrderingTerm.desc(a.datum),
              (a) => OrderingTerm.desc(a.geaendertAm),
            ]))
          .watch();

  /// Alle Ablesungen aller Zähler (für Übersicht und Export).
  Stream<List<Ablesung>> alleAblesungenBeobachten() =>
      (select(ablesungen)
            ..where((a) => a.geloescht.not())
            ..orderBy([(a) => OrderingTerm.desc(a.datum)]))
          .watch();

  Future<List<Ablesung>> alleAblesungen() =>
      (select(ablesungen)
            ..where((a) => a.geloescht.not())
            ..orderBy([(a) => OrderingTerm(expression: a.datum)]))
          .get();

  Future<List<Zaehler>> alleZaehler() =>
      (select(zaehlerTabelle)
            ..where((z) => z.geloescht.not())
            ..orderBy([(z) => OrderingTerm(expression: z.name)]))
          .get();

  Future<String> ablesungSpeichern({
    String? id,
    required String zaehlerId,
    required DateTime datum,
    required double stand,
    String notiz = '',
  }) async {
    final zeile = AblesungenCompanion.insert(
      id: id ?? neueId(),
      zaehlerId: zaehlerId,
      datum: datumText(datum),
      stand: stand,
      notiz: Value(notiz),
      geaendertAm: _jetzt(),
      ungesendet: const Value(true),
    );
    await into(ablesungen).insertOnConflictUpdate(zeile);
    return zeile.id.value;
  }

  Future<void> ablesungLoeschen(String id) => (update(
    ablesungen,
  )..where((a) => a.id.equals(id))).write(_loeschMarkierung());

  AblesungenCompanion _loeschMarkierung() => AblesungenCompanion(
    geloescht: const Value(true),
    geaendertAm: Value(_jetzt()),
    ungesendet: const Value(true),
  );

  // ── Sync ──────────────────────────────────────────────────────────────────

  Future<List<Zaehler>> ungesendeteZaehler() =>
      (select(zaehlerTabelle)..where((z) => z.ungesendet)).get();

  Future<List<Ablesung>> ungesendeteAblesungen() =>
      (select(ablesungen)..where((a) => a.ungesendet)).get();

  Stream<int> anzahlUngesendetBeobachten() => customSelect(
    'SELECT (SELECT COUNT(*) FROM zaehler WHERE ungesendet)'
    ' + (SELECT COUNT(*) FROM ablesungen WHERE ungesendet) AS n',
    readsFrom: {zaehlerTabelle, ablesungen},
  ).watchSingle().map((zeile) => zeile.read<int>('n'));

  /// Markiert einen Datensatz als übertragen – aber nur, wenn er seit dem
  /// Senden nicht erneut geändert wurde.
  Future<void> zaehlerGesendet(String id, int geaendertAm) =>
      (update(zaehlerTabelle)
            ..where((z) => z.id.equals(id) & z.geaendertAm.equals(geaendertAm)))
          .write(const ZaehlerTabelleCompanion(ungesendet: Value(false)));

  Future<void> ablesungGesendet(String id, int geaendertAm) =>
      (update(ablesungen)
            ..where((a) => a.id.equals(id) & a.geaendertAm.equals(geaendertAm)))
          .write(const AblesungenCompanion(ungesendet: Value(false)));

  /// Übernimmt einen Zähler vom Server, sofern lokal nichts Neueres liegt.
  Future<void> zaehlerVomServer(Zaehler entfernt) => transaction(() async {
    final lokal = await (select(
      zaehlerTabelle,
    )..where((z) => z.id.equals(entfernt.id))).getSingleOrNull();
    if (lokal != null &&
        lokal.ungesendet &&
        lokal.geaendertAm > entfernt.geaendertAm) {
      return;
    }
    await into(zaehlerTabelle)
        .insertOnConflictUpdate(entfernt.copyWith(ungesendet: false));
  });

  Future<void> ablesungVomServer(Ablesung entfernt) => transaction(() async {
    final lokal = await (select(
      ablesungen,
    )..where((a) => a.id.equals(entfernt.id))).getSingleOrNull();
    if (lokal != null &&
        lokal.ungesendet &&
        lokal.geaendertAm > entfernt.geaendertAm) {
      return;
    }
    await into(ablesungen)
        .insertOnConflictUpdate(entfernt.copyWith(ungesendet: false));
  });

  Future<String?> syncWert(String schluessel) async => (await (select(
    syncStatus,
  )..where((s) => s.schluessel.equals(schluessel))).getSingleOrNull())?.wert;

  Future<void> syncWertSetzen(String schluessel, String wert) =>
      into(syncStatus).insertOnConflictUpdate(
        SyncStatusCompanion.insert(schluessel: schluessel, wert: wert),
      );

  /// Vergisst den Sync-Stand, z. B. nach Wechsel auf einen anderen Server.
  /// Danach wird beim nächsten Abgleich alles neu geholt und alles gesendet.
  Future<void> syncZuruecksetzen() => transaction(() async {
    await delete(syncStatus).go();
    await update(zaehlerTabelle)
        .write(const ZaehlerTabelleCompanion(ungesendet: Value(true)));
    await update(ablesungen)
        .write(const AblesungenCompanion(ungesendet: Value(true)));
  });
}
