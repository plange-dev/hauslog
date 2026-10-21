// Abgleich gegen einen echten PocketBase-Server.
//
// Läuft nur, wenn PB_URL, PB_ADMIN und PB_ADMIN_PASSWORT gesetzt sind, z. B.:
//   PB_URL=http://127.0.0.1:8090 PB_ADMIN=admin@test.local \
//   PB_ADMIN_PASSWORT=... flutter test test/sync_test.dart
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hauslog/daten/datenbank.dart';
import 'package:hauslog/daten/ids.dart';
import 'package:hauslog/sync/sync_dienst.dart';
import 'package:pocketbase/pocketbase.dart';

final _url = Platform.environment['PB_URL'];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('Sync', skip: _url == null ? 'PB_URL nicht gesetzt' : false, () {
    late PocketBase pbA, pbB;
    late HauslogDatenbank dbA, dbB;
    late SyncDienst a, b;

    setUpAll(() async {
      if (_url == null) return;
      final admin = PocketBase(_url!);
      await admin
          .collection('_superusers')
          .authWithPassword(
            Platform.environment['PB_ADMIN']!,
            Platform.environment['PB_ADMIN_PASSWORT']!,
          );
      final email = 'test-${neueId()}@test.local';
      await admin
          .collection('users')
          .create(
            body: {
              'email': email,
              'password': 'passwort123',
              'passwordConfirm': 'passwort123',
            },
          );
      pbA = PocketBase(_url!);
      pbB = PocketBase(_url!);
      await pbA.collection('users').authWithPassword(email, 'passwort123');
      await pbB.collection('users').authWithPassword(email, 'passwort123');
    });

    setUp(() {
      dbA = HauslogDatenbank(NativeDatabase.memory());
      dbB = HauslogDatenbank(NativeDatabase.memory());
      a = SyncDienst(dbA, pbA);
      b = SyncDienst(dbB, pbB);
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    Future<void> warten() => Future.delayed(const Duration(milliseconds: 5));

    test('Neuer Zähler mit Ablesung kommt auf dem anderen Gerät an', () async {
      final zid = await dbA.zaehlerSpeichern(
        name: 'Strom Haus',
        art: 'strom',
        einheit: 'kWh',
      );
      await dbA.ablesungSpeichern(
        zaehlerId: zid,
        datum: DateTime(2026, 10, 1),
        stand: 1234.5,
      );

      expect((await a.synchronisieren()).gesendet, 2);
      expect(await dbA.ungesendeteAblesungen(), isEmpty);

      await b.synchronisieren();
      final zaehler = await dbB.alleZaehler();
      expect(zaehler.where((z) => z.id == zid).single.name, 'Strom Haus');
      final ablesung = (await dbB.alleAblesungen()).singleWhere(
        (x) => x.zaehlerId == zid,
      );
      expect(ablesung.stand, 1234.5);
      expect(ablesung.datum, '2026-10-01');
      expect(ablesung.ungesendet, isFalse);
    });

    test(
      'Konflikt: die neuere Offline-Änderung gewinnt auf beiden Seiten',
      () async {
        final zid = await dbA.zaehlerSpeichern(
          name: 'Gas',
          art: 'gas',
          einheit: 'm³',
        );
        final aid = await dbA.ablesungSpeichern(
          zaehlerId: zid,
          datum: DateTime(2026, 10, 2),
          stand: 100,
        );
        await a.synchronisieren();
        await b.synchronisieren();

        // Beide ändern offline, B später.
        await dbA.ablesungSpeichern(
          id: aid,
          zaehlerId: zid,
          datum: DateTime(2026, 10, 2),
          stand: 111,
        );
        await warten();
        await dbB.ablesungSpeichern(
          id: aid,
          zaehlerId: zid,
          datum: DateTime(2026, 10, 2),
          stand: 222,
        );

        // B sendet zuerst, dann A (älter → darf B nicht überschreiben).
        await b.synchronisieren();
        await a.synchronisieren();
        await b.synchronisieren();

        double stand(List<Ablesung> l) =>
            l.singleWhere((x) => x.id == aid).stand;
        expect(stand(await dbA.alleAblesungen()), 222);
        expect(stand(await dbB.alleAblesungen()), 222);
        expect(await dbA.ungesendeteAblesungen(), isEmpty);
      },
    );

    test(
      'Konflikt: neuere Änderung gewinnt auch, wenn sie zuletzt sendet',
      () async {
        final zid = await dbA.zaehlerSpeichern(
          name: 'Wasser',
          art: 'wasser',
          einheit: 'm³',
        );
        final aid = await dbA.ablesungSpeichern(
          zaehlerId: zid,
          datum: DateTime(2026, 10, 3),
          stand: 5,
        );
        await a.synchronisieren();
        await b.synchronisieren();

        await dbB.ablesungSpeichern(
          id: aid,
          zaehlerId: zid,
          datum: DateTime(2026, 10, 3),
          stand: 6,
        );
        await warten();
        await dbA.ablesungSpeichern(
          id: aid,
          zaehlerId: zid,
          datum: DateTime(2026, 10, 3),
          stand: 7,
        );

        await b.synchronisieren();
        await a.synchronisieren();
        await b.synchronisieren();

        double stand(List<Ablesung> l) =>
            l.singleWhere((x) => x.id == aid).stand;
        expect(stand(await dbA.alleAblesungen()), 7);
        expect(stand(await dbB.alleAblesungen()), 7);
      },
    );

    test(
      'Löschen eines Zählers entfernt ihn samt Ablesungen überall',
      () async {
        final zid = await dbA.zaehlerSpeichern(
          name: 'Wärme',
          art: 'waerme',
          einheit: 'kWh',
        );
        await dbA.ablesungSpeichern(
          zaehlerId: zid,
          datum: DateTime(2026, 10, 4),
          stand: 42,
        );
        await a.synchronisieren();
        await b.synchronisieren();
        expect((await dbB.alleZaehler()).map((z) => z.id), contains(zid));

        await dbB.zaehlerLoeschen(zid);
        await b.synchronisieren();
        await a.synchronisieren();

        expect(
          (await dbA.alleZaehler()).map((z) => z.id),
          isNot(contains(zid)),
        );
        expect(
          (await dbA.alleAblesungen()).where((x) => x.zaehlerId == zid),
          isEmpty,
        );
      },
    );
  });
}
